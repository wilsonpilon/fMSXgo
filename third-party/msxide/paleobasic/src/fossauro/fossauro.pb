; fossauro - PureBasic MSX Emulator
; Main Entry Point & Graphical User Interface

EnableExplicit

CompilerIf Not Defined(App_Version, #PB_Constant)
  #App_Version = "8.1.3"
CompilerEndIf

; Windows constant + import for AttachConsole()/FreeConsole() - not part of PureBasic's
; automatic "_"-suffixed WinAPI passthrough, needs an explicit Import. Used by -help so its
; output can reach a real terminal instead of going nowhere - see RunEmulator() below.
#ATTACH_PARENT_PROCESS = -1
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  Import "Kernel32.lib"
    AttachConsole(dwProcessId.l)
    FreeConsole()
  EndImport
CompilerEndIf

; Folga de pilha (em bytes) reservada abaixo do SP herdado pelo comando RUN do pipe antes de
; empurrar o retorno sintetico - ver Case "RUN" abaixo pro raciocinio completo. Precisa ser
; generosa o bastante pra aguentar aninhamento real de chamadas de BIOS (CHPUT/BREAKX e
; afins ja usam algumas dezenas de bytes so nelas) sem que o codigo injetado pise no trap.
#FossauroRunStackSlack = 1024

; --- Emulation Control Globals ---
Global ThreadExit.l = 0
Global ThreadPaused.l = 0
Global EmulationThread.i = 0
Global Dim PCKeyStates.b(512)

; Paths of the currently-loaded cartridges (if any), kept up to date by LoadCartridge() -
; needed so File->Save Snapshot... knows what to reference on restore (snapshots don't embed
; cartridge ROM data, just the path - see SaveSnapshot()/LoadSnapshot() below).
Global CurCartAPath.s = ""
Global CurCartBPath.s = ""

; Same idea for mounted disk images - unlike cartridges, mounted disks do NOT need re-mounting
; after a model switch/RAM/VRAM change (FDCDrive() in FDC.pbi is a standalone buffer, untouched by
; ReallocateRAM()/ReallocateVRAM()/ResetSlotsToStartup()), so these are only tracked for the
; snapshot/menu-checkmark bookkeeping, not for any re-load-on-reset logic.
Global CurDiskAPath.s = ""
Global CurDiskBPath.s = ""

; Video -> window/canvas scale, purely a display setting (does not touch FrameBuffer(), which
; always stays 512x212 - see V9938.pbi - only how many physical pixels each of those gets drawn
; into). VideoScale is the integer multiple (1/2/3/4) of the base size; Force4x3 picks the base
; size itself: 512x384 (correct 4:3 TV aspect, matches fMSX real's "-4x3" flag and this project's
; own default/only behavior before this menu existed) when set, or 512x212 (native FrameBuffer
; pixels, no vertical stretch) when not. Default VideoScale=1/Force4x3=true reproduces the exact
; 512x384 window this project always had, so nothing changes for anyone who never opens this menu.
Global VideoScale.l = 1
Global Force4x3.b = #True

; Include Z80 Emulator, Motherboard, Video, and Audio files
XIncludeFile "Z80_Tables.pbi"
XIncludeFile "Z80.pbi"
XIncludeFile "MSX.pbi"

; Emulation Background Thread
Procedure EmulationThreadProc(*Param)
  ; Re-assert the Z80 core callback pointers HERE, on the thread that actually calls
  ; RunZ80/uses them, instead of trusting the assignment done earlier on the main
  ; thread in RunEmulator() to be visible. Confirmed via crash dump analysis
  ; (0xC0000005, RIP=0x0) that RdZ80 was null at the exact moment the CPU reached the
  ; cartridge's entry point ($406C) - the call-site target address matched RdZ80's
  ; storage address exactly. Cheap and harmless if it was already set correctly.
  RealRdZ80 = @MSXRdZ80()
  WrZ80 = @MSXWrZ80()
  InZ80 = @MSXInZ80()
  OutZ80 = @MSXOutZ80()
  LoopZ80 = @MSXLoopZ80()
  PatchZ80 = @MSXPatchZ80()
  LogGeneral("EmulationThreadProc: callback pointers re-asserted on emu thread. RealRdZ80=$" + Hex(RealRdZ80))

  CPU\IPeriod = 228 ; Cycles per scanline phase
  RunZ80(@CPU)
EndProcedure

; --- Named Pipe Control Protocol (2026-08-18) ------------------------------------------------
; Minimal custom protocol over a Windows named pipe - deliberately NOT the openMSX control
; protocol (Tcl commands wrapped in XML, built for a full Tcl interpreter on the other end,
; way more surface than anything here needs). One ASCII header line (LF or CRLF terminated)
; per command, raw binary payload immediately after for LOAD. Single well-known pipe name/one
; client session at a time - the server loop just waits for the next connection once a client
; disconnects, so Paleobasic can connect, send a few commands and disconnect per compile/run
; cycle without fossauro needing to be relaunched.
;
; Commands (request -> reply, reply is always one LF-terminated ASCII line):
;   PING                     -> PONG
;   LOAD <addr> <len>\n<len raw bytes>
;                            -> OK | ERR <msg>   writes raw bytes into MSX RAM starting at Z80
;                                                 address <addr> (decimal, 0-65535) via
;                                                 MSXWrZ80 - caller's job to pick a mapped RAM
;                                                 address, this does no slot/page validation
;   POKE <addr> <value>      -> OK | ERR <msg>   single-byte convenience form of LOAD
;   PEEK <addr>              -> VAL <value> | ERR <msg>
;   RUN <addr>               -> OK | ERR <msg>   sets the Z80 PC register directly (a raw
;                                                 jump) - NOT "type RUN and press Enter"; a real
;                                                 MSX BASIC RUN needs TXTTAB/line-pointer
;                                                 bookkeeping on top of this, not implemented
;                                                 yet - see docs/SPEC.md module 32u
;   REGS                     -> REGS PC=.. SP=.. AF=.. BC=.. DE=.. HL=.. IX=.. IY=..
;                                                 diagnostic-only, added live to investigate a
;                                                 real hang report - see docs/SPEC.md module 32w
;   (anything else)          -> ERR unknown command
;
; Every write (LOAD/POKE/RUN) briefly sets ThreadPaused around the memory/register touch -
; same pattern already used by SwitchModel()/ApplyRAMSize()/ApplyVRAMSize() above: the emu
; thread's MSXLoopZ80() spins on ThreadPaused every scanline (MSX.pbi), so the actual pause
; lands within roughly one scanline's worth of real time, not instantly - accepted small race,
; consistent with how the rest of this codebase already touches shared emulator state from the
; main thread while the emu thread is nominally "paused".
#PipeName = "\\.\pipe\fossauro"
#Pipe_BufSize = 65536
Global PipeThread.i = 0

Procedure.s PipeReadLine(hPipe.i)
  Protected Line.s = ""
  Protected Ch.a
  Protected BytesRead.l
  Repeat
    If Not ReadFile_(hPipe, @Ch, 1, @BytesRead, 0) Or BytesRead = 0
      ProcedureReturn "" ; client disconnected mid-line
    EndIf
    If Ch = 10 ; LF
      ProcedureReturn RTrim(Line, Chr(13)) ; drop a trailing CR if the client sent CRLF
    EndIf
    Line + Chr(Ch)
    If Len(Line) > 4096 ; runaway header guard - nothing legitimate needs a header this long
      ProcedureReturn ""
    EndIf
  ForEver
EndProcedure

Procedure.b PipeReadBytes(hPipe.i, *Buffer, Length.l)
  Protected Got.l = 0, BytesRead.l
  While Got < Length
    If Not ReadFile_(hPipe, *Buffer + Got, Length - Got, @BytesRead, 0) Or BytesRead = 0
      ProcedureReturn #False
    EndIf
    Got + BytesRead
  Wend
  ProcedureReturn #True
EndProcedure

Procedure PipeWriteLine(hPipe.i, Text.s)
  Protected Line.s = Text + Chr(10)
  Protected ByteLen.l = Len(Line) ; protocol replies are plain ASCII, 1 byte/char
  Protected *Buf = AllocateMemory(ByteLen)
  Protected Written.l
  PokeS(*Buf, Line, ByteLen, #PB_Ascii | #PB_String_NoZero)
  WriteFile_(hPipe, *Buf, ByteLen, @Written, 0)
  FreeMemory(*Buf)
EndProcedure

Procedure PipeHandleClient(hPipe.i)
  Protected Line.s, Cmd.s, Rest.s, SpacePos.l
  Repeat
    Line = PipeReadLine(hPipe)
    If Line = "" : Break : EndIf ; client disconnected

    SpacePos = FindString(Line, " ")
    If SpacePos
      Cmd = UCase(Left(Line, SpacePos - 1))
      Rest = Mid(Line, SpacePos + 1)
    Else
      Cmd = UCase(Line)
      Rest = ""
    EndIf

    Select Cmd
      Case "PING"
        PipeWriteLine(hPipe, "PONG")

      Case "LOAD"
        Protected AddrStr.s = StringField(Rest, 1, " ")
        Protected LenStr.s = StringField(Rest, 2, " ")
        Protected Addr.l = Val(AddrStr)
        Protected PayloadLen.l = Val(LenStr)
        If AddrStr = "" Or LenStr = "" Or Addr < 0 Or Addr > 65535 Or PayloadLen <= 0 Or PayloadLen > 65536
          PipeWriteLine(hPipe, "ERR bad LOAD arguments")
        Else
          Protected *Payload = AllocateMemory(PayloadLen)
          If PipeReadBytes(hPipe, *Payload, PayloadLen)
            ThreadPaused = 1
            Protected I.l
            For I = 0 To PayloadLen - 1
              MSXWrZ80((Addr + I) & $FFFF, PeekA(*Payload + I))
            Next I
            ThreadPaused = 0
            PipeWriteLine(hPipe, "OK")
          Else
            PipeWriteLine(hPipe, "ERR short payload")
          EndIf
          FreeMemory(*Payload)
        EndIf

      Case "POKE"
        Protected PAddrStr.s = StringField(Rest, 1, " ")
        Protected PValStr.s = StringField(Rest, 2, " ")
        If PAddrStr = "" Or PValStr = ""
          PipeWriteLine(hPipe, "ERR bad POKE arguments")
        Else
          ThreadPaused = 1
          MSXWrZ80(Val(PAddrStr) & $FFFF, Val(PValStr) & $FF)
          ThreadPaused = 0
          PipeWriteLine(hPipe, "OK")
        EndIf

      Case "PEEK"
        If Rest = ""
          PipeWriteLine(hPipe, "ERR bad PEEK arguments")
        Else
          PipeWriteLine(hPipe, "VAL " + Str(SafeRdZ80(Val(Rest) & $FFFF)))
        EndIf

      Case "TYPE"
        ; Simula digitacao real no buffer de teclado do MSX (ver docs/SPEC.md modulo 32y) - em
        ; vez de sequestrar PC/SP como o RUN cru faz (ver o comentario do Case "RUN" logo
        ; abaixo), escreve os bytes recebidos direto no keyboard ring buffer real da BIOS
        ; (KEYBUF, $FBF0, 40 bytes - confirmado em editor/BiosCallsHelpData.pbi/
        ; MsxManualsHelpData.pbi, os mesmos enderecos $F3F8/PUTPNT e $F3FA/GETPNT que apareceram
        ; no diagnostico do modulo 32x) e avanca PUTPNT ($F3F8) do mesmo jeito que a rotina de
        ; interrupcao de teclado faria a cada tecla - o texto aparece pro BASIC exatamente como
        ; se tivesse sido digitado de verdade (um CR/Chr(13) no payload "pressiona Enter" e
        ; submete a linha), sem tocar em PC/SP/nada do contexto de execucao que ja esta rodando.
        ; Limite de 39 bytes (nao 40) de proposito: um buffer circular convencional (sem um
        ; contador de ocupacao separado) nao consegue distinguir "cheio" de "vazio" quando
        ; PUTPNT alcança GETPNT por tras - deixar 1 posicao sempre livre evita essa ambiguidade,
        ; mesma tecnica que a BIOS real usa antes de gravar uma tecla nova.
        If Rest = ""
          PipeWriteLine(hPipe, "ERR bad TYPE arguments")
        Else
          Protected TypeLen.l = Val(Rest)
          If TypeLen <= 0 Or TypeLen > 39
            PipeWriteLine(hPipe, "ERR bad TYPE length (max 39)")
          Else
            Protected *TypePayload = AllocateMemory(TypeLen)
            If PipeReadBytes(hPipe, *TypePayload, TypeLen)
              ThreadPaused = 1
              Protected PutPnt.u = SafeRdZ80($F3F8) | (SafeRdZ80($F3F9) << 8)
              Protected T.l
              For T = 0 To TypeLen - 1
                MSXWrZ80(PutPnt, PeekA(*TypePayload + T))
                PutPnt = $FBF0 + ((PutPnt - $FBF0 + 1) % 40)
              Next T
              MSXWrZ80($F3F8, PutPnt & $FF)
              MSXWrZ80($F3F9, (PutPnt >> 8) & $FF)
              ThreadPaused = 0
              PipeWriteLine(hPipe, "OK")
            Else
              PipeWriteLine(hPipe, "ERR short payload")
            EndIf
            FreeMemory(*TypePayload)
          EndIf
        EndIf

      Case "RUN"
        If Rest = ""
          PipeWriteLine(hPipe, "ERR bad RUN arguments")
        Else
          ThreadPaused = 1
          ; Ver docs/SPEC.md modulo 32w/32x - RUN cru so trocava PC, deixando o SP herdado de
          ; qualquer coisa que a sessao MSX estivesse fazendo quando o comando chegou. Assim
          ; que o codigo injetado desse um RET (direto, ou indireto via alguma call de BIOS
          ; mal-balanceada), a execucao "voltava" pra dentro daquele call-chain alheio de
          ; forma imprevisivel - confirmado ao vivo reproduzindo o MESMO programa (print via
          ; CHPUT) em dois momentos de boot diferentes e vendo o travamento em duas regioes de
          ; PC totalmente diferentes ($0D6A/BREAKX numa vez, $0864/$FFBB na outra - essa com
          ; HL ja apontando pro fim da string, ou seja, o RET veio DEPOIS do print terminar).
          ; Fix: empurra um endereco de retorno sintetico apontando pra um trap de 2 bytes
          ; (JR $, loop infinito inofensivo) numa folga abaixo do SP atual, generosa o
          ; bastante pra aguentar chamadas de BIOS aninhadas de verdade sem a folga colidir
          ; com o trap em si. Se o codigo injetado retornar (de proposito ou por
          ; desbalanceamento), cai nesse loop conhecido - detectavel via REGS (PC = TrapAddr)
          ; - em vez de invadir codigo alheio.
          Protected RunTrapAddr.u = (CPU\SP\W - #FossauroRunStackSlack) & $FFFF
          MSXWrZ80(RunTrapAddr, $18)                          ; JR
          MSXWrZ80((RunTrapAddr + 1) & $FFFF, $FE)            ; -2 (loop pro proprio JR)
          CPU\SP\W = (RunTrapAddr - 2) & $FFFF
          MSXWrZ80(CPU\SP\W, RunTrapAddr & $FF)               ; retorno sintetico: byte baixo
          MSXWrZ80((CPU\SP\W + 1) & $FFFF, (RunTrapAddr >> 8) & $FF) ; byte alto
          CPU\PC\W = Val(Rest) & $FFFF
          ThreadPaused = 0
          PipeWriteLine(hPipe, "OK")
        EndIf

      Case "REGS"
        ; Diagnostico - nao faz parte do protocolo "de producao" documentado no docs/SPEC.md
        ; modulo 32u (ainda), adicionado ao vivo pra investigar um travamento real reportado
        ; pelo usuario (Z80 preso num busy-wait dentro de uma rotina de BIOS de verdade,
        ; ver docs/SPEC.md modulo 32w). MSXLoopZ80() (MSX.pbi) checa ThreadPaused a cada
        ; #IPeriod ciclos (228 T-states) - um laco apertado de poucas instrucoes ainda cruza
        ; essa fronteira com frequencia, entao ThreadPaused=1 consegue pausar mesmo com a
        ; emulacao presa num loop.
        ThreadPaused = 1
        PipeWriteLine(hPipe, "REGS PC=" + Hex(CPU\PC\W, #PB_Word) +
                              " SP=" + Hex(CPU\SP\W, #PB_Word) +
                              " AF=" + Hex(CPU\AF\W, #PB_Word) +
                              " BC=" + Hex(CPU\BC\W, #PB_Word) +
                              " DE=" + Hex(CPU\DE\W, #PB_Word) +
                              " HL=" + Hex(CPU\HL\W, #PB_Word) +
                              " IX=" + Hex(CPU\IX\W, #PB_Word) +
                              " IY=" + Hex(CPU\IY\W, #PB_Word))
        ThreadPaused = 0

      Default
        PipeWriteLine(hPipe, "ERR unknown command")
    EndSelect
  ForEver
EndProcedure

Procedure PipeServerThreadProc(*Param)
  Protected hPipe.i, Connected.l
  Repeat
    hPipe = CreateNamedPipe_(#PipeName, #PIPE_ACCESS_DUPLEX,
                              #PIPE_TYPE_BYTE | #PIPE_READMODE_BYTE | #PIPE_WAIT,
                              #PIPE_UNLIMITED_INSTANCES, #Pipe_BufSize, #Pipe_BufSize, 0, 0)
    If hPipe = #INVALID_HANDLE_VALUE
      LogGeneral("PipeServerThreadProc: CreateNamedPipe failed, GetLastError=" + Str(GetLastError_()))
      ProcedureReturn
    EndIf

    Connected = ConnectNamedPipe_(hPipe, 0)
    If Connected Or GetLastError_() = #ERROR_PIPE_CONNECTED
      LogGeneral("PipeServerThreadProc: client connected")
      PipeHandleClient(hPipe)
      LogGeneral("PipeServerThreadProc: client disconnected")
    EndIf

    DisconnectNamedPipe_(hPipe)
    CloseHandle_(hPipe)
  Until ThreadExit
EndProcedure

; Map PC Key Codes to MSX Keyboard Matrix Codes
Procedure.l MapCanvasKey(PBKey.l)
  Select PBKey
    Case #PB_Shortcut_Up : ProcedureReturn 2
    Case #PB_Shortcut_Down : ProcedureReturn 4
    Case #PB_Shortcut_Left : ProcedureReturn 1
    Case #PB_Shortcut_Right : ProcedureReturn 3
    Case #PB_Shortcut_Space : ProcedureReturn 32
    Case #PB_Shortcut_Return : ProcedureReturn 13
    Case 16 : ProcedureReturn 5   ; Shift
    Case 17 : ProcedureReturn 6   ; Control
    Case 18 : ProcedureReturn 7   ; Graph (Alt)
    Case #PB_Shortcut_Escape : ProcedureReturn 27
    Case #PB_Shortcut_Back : ProcedureReturn 8
    Case #PB_Shortcut_Tab : ProcedureReturn 9
    Case 20 : ProcedureReturn 10  ; CapsLock
    ; MSX specific special keys
    Case #PB_Shortcut_End : ProcedureReturn 11      ; SELECT
    Case #PB_Shortcut_Home : ProcedureReturn 12     ; HOME
    Case #PB_Shortcut_Insert : ProcedureReturn 15   ; INSERT
    Case #PB_Shortcut_Delete : ProcedureReturn 14   ; DELETE
    Case #PB_Shortcut_PageUp : ProcedureReturn 17   ; STOP
    Case #PB_Shortcut_PageDown : ProcedureReturn 16 ; COUNTRY
    ; Function keys
    Case #PB_Shortcut_F1 : ProcedureReturn 18
    Case #PB_Shortcut_F2 : ProcedureReturn 19
    Case #PB_Shortcut_F3 : ProcedureReturn 20
    Case #PB_Shortcut_F4 : ProcedureReturn 21
    Case #PB_Shortcut_F5 : ProcedureReturn 22
    ; Punctuation mappings (Windows OEM virtual-key codes -> ASCII-indexed slot in the
    ; KeyboardData table, MSX.pbi - see the table comments there for the full 0-129 layout).
    ; Shifted variants (? " { } | ~) aren't mapped separately - the MSX matrix combines the
    ; physical key with SHIFT (case 16, above) the same way real MSX keyboard hardware does.
    Case 186 : ProcedureReturn 59 ; VK_OEM_1     ; :
    Case 187 : ProcedureReturn 43 ; VK_OEM_PLUS  = +
    Case 188 : ProcedureReturn 44 ; VK_OEM_COMMA , <
    Case 189 : ProcedureReturn 45 ; VK_OEM_MINUS - _
    Case 190 : ProcedureReturn 46 ; VK_OEM_PERIOD . >
    Case 191 : ProcedureReturn 47 ; VK_OEM_2     / ?
    Case 192 : ProcedureReturn 96 ; VK_OEM_3     ` ~
    Case 219 : ProcedureReturn 91 ; VK_OEM_4     [ {
    Case 220 : ProcedureReturn 92 ; VK_OEM_5     \ |
    Case 221 : ProcedureReturn 93 ; VK_OEM_6     ] }
    Case 222 : ProcedureReturn 39 ; VK_OEM_7     ' "
    Case 226 : ProcedureReturn 92 ; VK_OEM_102 (extra ISO key on some layouts, usually \ |)
    Default
      ; Map numbers
      If PBKey >= '0' And PBKey <= '9'
        ProcedureReturn PBKey
      EndIf
      ; Map letters (canvas returns uppercase/lowercase)
      If PBKey >= 'A' And PBKey <= 'Z'
        ProcedureReturn PBKey
      ElseIf PBKey >= 'a' And PBKey <= 'z'
        ProcedureReturn PBKey - 32
      EndIf
  EndSelect
  ProcedureReturn 0
EndProcedure

; Load 16K/32K standard ROM cartridge. Slot=1 (default, backward-compatible) mirrors the
; ROM into BOTH primary slots 1 and 2 (fossauro's original single-cartridge convenience
; behavior - File menu, legacy -rom <file> shorthand). Slot=2 maps ONLY into primary slot 2
; (using a second ROM buffer, *ROMData(1)) and leaves slot 1 alone, for real fMSX-style dual
; cartridge use (positional [filename1] [filename2] - see RunEmulator's CLI parsing).
; Remembered mapper-type selection per slot (Hardware->Cartridge Slot A/B->Mapper Type), so a
; cartridge reload triggered by a RAM/VRAM size change or model switch keeps using the same
; mapper instead of silently re-guessing. Declared here (after the XIncludeFile block above)
; since #MAP_GUESS is defined in MSX.pbi.
Global CurCartAMapper.a = #MAP_GUESS
Global CurCartBMapper.a = #MAP_GUESS

; Loads FileName into cartridge Slot (1=Cart A/Primary Slot 1, 2=Cart B/Primary Slot 2), each
; slot fully independent now (a real bug in the old code had Cart A mirror into BOTH primary
; slots "for legacy single-cartridge support", which meant loading Cart A after Cart B silently
; stole Cart B's slot - fixed as part of adding proper independent Slot A/B menus). ROMs up to
; 32KB (4 x 8KB pages) load flat/mirrored with no mapper, exactly like before; larger ones are
; real MegaROMs, rounded up to the next power-of-2 page count and switched via MapROM()
; (MSX.pbi) using MapperType (or auto-detected via GuessROMType() if MapperType=#MAP_GUESS).
Procedure.l LoadCartridge(FileName.s, Slot.l = 1, MapperType.a = #MAP_GUESS)
  LogGeneral("LoadCartridge called for: " + FileName + " (slot " + Str(Slot) + ")")
  Protected FileNum.i = ReadFile(#PB_Any, FileName)
  If FileNum = 0
    LogGeneral("LoadCartridge ERROR: Could not open file " + FileName)
    ProcedureReturn 0
  EndIf

  Protected Length.q = Lof(FileNum)
  LogGeneral("LoadCartridge: File size = " + Str(Length) + " bytes")

  Protected BufIdx.l = Slot - 1 ; Slot 1 -> index 0 (Cart A), Slot 2 -> index 1 (Cart B)
  Protected PrimarySlot.l = Slot ; Cart A -> Primary Slot 1, Cart B -> Primary Slot 2 (fixed 1:1)

  ; Round up to a whole number of 8KB pages, next power of 2 (matches real fMSX's ROM
  ; allocation rounding) - bank-select values (0..Pages-1) then always address real, allocated
  ; data even for odd-sized dumps (e.g. a 24KB dump rounds up to 32KB/4 pages).
  Protected Pages.l = 1
  Protected NeededPages.l = (Length + $1FFF) / $2000
  While Pages < NeededPages : Pages << 1 : Wend
  Protected AllocSize.l = Pages * $2000

  If *ROMData(BufIdx) : FreeMemory(*ROMData(BufIdx)) : EndIf
  *ROMData(BufIdx) = AllocateMemory(AllocSize)
  FillMemory(*ROMData(BufIdx), AllocSize, $FF)
  Protected ReadLen.q = Length
  If ReadLen > AllocSize : ReadLen = AllocSize : EndIf
  ReadData(FileNum, *ROMData(BufIdx), ReadLen)
  CloseFile(FileNum)

  ; Mirror the image to fill the rest of the rounded-up allocation - matches real hardware
  ; address decoding wrapping within the cartridge's actual (smaller) address space.
  If ReadLen < AllocSize And ReadLen > 0
    Protected mirrorOfs.q = ReadLen, chunk.q
    While mirrorOfs < AllocSize
      chunk = ReadLen
      If mirrorOfs + chunk > AllocSize : chunk = AllocSize - mirrorOfs : EndIf
      CopyMemory(*ROMData(BufIdx), *ROMData(BufIdx) + mirrorOfs, chunk)
      mirrorOfs + chunk
    Wend
  EndIf

  Protected header.s = Chr(PeekA(*ROMData(BufIdx))) + Chr(PeekA(*ROMData(BufIdx)+1))
  LogGeneral("LoadCartridge: ROM Header Bytes = $" + Hex(PeekA(*ROMData(BufIdx))) + " $" + Hex(PeekA(*ROMData(BufIdx)+1)) + " ('" + header + "')")

  ; Clear this slot's OWN primary-slot pages first - independent per-cartridge-slot state.
  Protected J.l
  For J = 2 To 5
    *MemMap(PrimarySlot, 0, J) = *EmptyRAM
  Next J
  ROMMask(BufIdx) = 0
  ROMType(BufIdx) = #MAP_GEN8
  If *SRAMData(BufIdx) : FreeMemory(*SRAMData(BufIdx)) : *SRAMData(BufIdx) = 0 : EndIf
  ROMMapper(BufIdx, 0) = 0 : ROMMapper(BufIdx, 1) = 0 : ROMMapper(BufIdx, 2) = 0 : ROMMapper(BufIdx, 3) = 0

  If Pages <= 4
    ; Plain <=32KB ROM - no mapper needed, flat/mirrored mapping exactly like before.
    For J = 2 To 5
      *MemMap(PrimarySlot, 0, J) = *ROMData(BufIdx) + ((J - 2) % Pages) * $2000
    Next J
    LogGeneral("LoadCartridge: " + Str(Length) + " byte ROM, flat-mapped (no MegaROM mapper) to Primary Slot " + Str(PrimarySlot))
  Else
    ; MegaROM - guess or use the requested mapper type, wire up MapROM() bank-switching.
    ROMMask(BufIdx) = Pages - 1
    If MapperType >= #MAP_GUESS
      ROMType(BufIdx) = GuessROMType(*ROMData(BufIdx), Length)
    Else
      ROMType(BufIdx) = MapperType
    EndIf
    ; Preset initial paging: page 0 at $4000, page 1 at $6000, second-to-last/last page at
    ; $8000/$A000 - matches real fMSX's SetMegaROM() call for GEN16-style carts (MSX.c); a
    ; reasonable default for the others too, since most MegaROMs boot fine as long as page 0
    ; is at $4000 (the machine's reset vector reads from there first).
    ApplyMegaROMPage(BufIdx, PrimarySlot, 0, 0)
    ApplyMegaROMPage(BufIdx, PrimarySlot, 1, 1)
    ApplyMegaROMPage(BufIdx, PrimarySlot, 2, ROMMask(BufIdx) - 1)
    ApplyMegaROMPage(BufIdx, PrimarySlot, 3, ROMMask(BufIdx))
    LogGeneral("LoadCartridge: " + Str(Length) + " byte MegaROM, mapper type " + Str(ROMType(BufIdx)) +
               " (" + ROMTypeName(ROMType(BufIdx)) + "), " + Str(Pages) + " x 8KB pages, mapped to Primary Slot " + Str(PrimarySlot))
  EndIf

  If Slot = 1
    CurCartAPath = FileName
    CurCartAMapper = MapperType
  Else
    CurCartBPath = FileName
    CurCartBMapper = MapperType
  EndIf

  ; Reset hardware state
  ResetZ80(@CPU)
  ResetVDP()
  ResetPSG()
  FDC_Reset()

  LogGeneral("LoadCartridge: Cartridge loaded successfully and hardware reset.")
  ProcedureReturn 1
EndProcedure

; Removes whatever cartridge is in Slot (1 or 2), freeing its ROM/SRAM buffers and leaving the
; primary slot's pages back at *EmptyRAM - real MSX hardware equivalent of physically pulling
; the cartridge out. Does a full reset, same as Load - a real MSX doesn't hot-swap cartridges
; either (usually crashes or hangs if you try on real hardware without powering off first).
Procedure EjectCartridge(Slot.l)
  Protected BufIdx.l = Slot - 1
  Protected PrimarySlot.l = Slot
  Protected J.l
  For J = 2 To 5
    *MemMap(PrimarySlot, 0, J) = *EmptyRAM
  Next J
  If *ROMData(BufIdx) : FreeMemory(*ROMData(BufIdx)) : *ROMData(BufIdx) = 0 : EndIf
  If *SRAMData(BufIdx) : FreeMemory(*SRAMData(BufIdx)) : *SRAMData(BufIdx) = 0 : EndIf
  ROMMask(BufIdx) = 0
  ROMType(BufIdx) = #MAP_GEN8
  If Slot = 1
    CurCartAPath = ""
  Else
    CurCartBPath = ""
  EndIf
  ResetZ80(@CPU)
  ResetVDP()
  ResetPSG()
  FDC_Reset()
  LogGeneral("EjectCartridge: Slot " + Str(Slot) + " ejected, hardware reset.")
EndProcedure

; Forward-declared here since LoadSnapshot() (right below) needs to call them and they're
; defined further down in this file (near SwitchModel()/ApplyRAMSize(), their main callers).
Declare UpdateModelMenuCheck()
Declare UpdateRAMSizeMenuCheck()
Declare UpdateVRAMSizeMenuCheck()
Declare UpdateCartMapperMenuCheck()
Declare UpdateVideoMenuCheck()

; --- Snapshot save/load ---
; Custom binary format, not cross-version/cross-build stable (structs are dumped raw via
; WriteData/ReadData - fine since a snapshot is only ever meant to be reloaded by the same
; fossauro.exe build that wrote it, same spirit as most simple emulator save-states). Does NOT
; embed cartridge ROM data - only the file path - so the original ROM file must still exist at
; that path when restoring; BIOS/extended BIOS are never saved either, since MSXLoadBIOSForModel()
; deterministically reloads the right ones from Mode alone. RAM/VRAM/CPU/VDP/PSG/PPI/RTC/slot
; state are all included, which is everything MemMap() pointers themselves are NOT (raw addresses
; only valid for this process run) - the slot mapping is rebuilt on load by forcing PSlot() to
; recompute from the restored SSLReg()/PSLReg values, the same derivation the emulator itself
; uses on every real slot-select write. RAM size is variable (RAMPages, ports $FC-$FF) since
; the Hardware->RAM Size feature was added - RAMPages/RAMMapper() are saved alongside the RAM
; contents itself so a snapshot taken with e.g. 1024KB restores at 1024KB, not the default.
#SnapshotMagic = "FSNP"
#SnapshotVersion = 3 ; v2: RAM size is now variable (RAMPages/RAMMapper()); v3: VRAM size too
                      ; (VRAMPages) - see docs/SPEC.md

Procedure.l SaveSnapshot(FileName.s)
  Protected FileNum.i = CreateFile(#PB_Any, FileName)
  If FileNum = 0
    LogGeneral("SaveSnapshot ERROR: Could not create " + FileName)
    ProcedureReturn 0
  EndIf

  WriteString(FileNum, #SnapshotMagic, #PB_Ascii)
  WriteLong(FileNum, #SnapshotVersion)
  WriteLong(FileNum, Mode)
  WriteStringN(FileNum, CurCartAPath, #PB_UTF8)
  WriteStringN(FileNum, CurCartBPath, #PB_UTF8)
  WriteByte(FileNum, CurCartAMapper)
  WriteByte(FileNum, CurCartBMapper)

  WriteLong(FileNum, RAMPages)
  Protected mI.l
  For mI = 0 To 3 : WriteByte(FileNum, RAMMapper(mI)) : Next mI
  WriteData(FileNum, *RAMData, RAMPages * $4000)
  WriteLong(FileNum, VRAMPages)
  WriteData(FileNum, *VRAM, VRAMPages * $4000)
  WriteData(FileNum, @CPU, SizeOf(Z80))

  Protected I.l
  For I = 0 To 63 : WriteByte(FileNum, VDP(I)) : Next I
  For I = 0 To 15 : WriteByte(FileNum, VDPStatus(I)) : Next I
  WriteByte(FileNum, VDPKey)
  WriteByte(FileNum, VDPALatch)
  WriteWord(FileNum, VDPAddr)
  WriteByte(FileNum, VDPData)

  WriteData(FileNum, @MMC, SizeOf(VDPCommandState))
  WriteData(FileNum, @PSG, SizeOf(PSGState))
  WriteData(FileNum, @PPI, SizeOf(I8255))

  WriteByte(FileNum, RTCReg)
  WriteByte(FileNum, RTCMode)
  Protected bank.l, reg.l
  For bank = 0 To 3
    For reg = 0 To 12
      WriteByte(FileNum, RTC(bank, reg))
    Next reg
  Next bank

  WriteByte(FileNum, PSLReg)
  For I = 0 To 3 : WriteByte(FileNum, SSLReg(I)) : Next I

  CloseFile(FileNum)
  LogGeneral("SaveSnapshot: wrote " + FileName)
  ProcedureReturn 1
EndProcedure

Procedure.l LoadSnapshot(FileName.s)
  Protected FileNum.i = ReadFile(#PB_Any, FileName)
  If FileNum = 0
    LogGeneral("LoadSnapshot ERROR: Could not open " + FileName)
    ProcedureReturn 0
  EndIf

  Protected magic.s = ReadString(FileNum, #PB_Ascii, 4)
  If magic <> #SnapshotMagic
    LogGeneral("LoadSnapshot ERROR: bad magic in " + FileName)
    CloseFile(FileNum)
    ProcedureReturn 0
  EndIf
  Protected version.l = ReadLong(FileNum)
  If version <> #SnapshotVersion
    LogGeneral("LoadSnapshot ERROR: unsupported snapshot version " + Str(version))
    CloseFile(FileNum)
    ProcedureReturn 0
  EndIf

  Protected loadedMode.l = ReadLong(FileNum)
  Protected loadedCartA.s = ReadString(FileNum, #PB_UTF8)
  Protected loadedCartB.s = ReadString(FileNum, #PB_UTF8)
  Protected loadedCartAMapper.a = ReadByte(FileNum)
  Protected loadedCartBMapper.a = ReadByte(FileNum)

  Mode = loadedMode
  If Not MSXLoadBIOSForModel()
    LogGeneral("LoadSnapshot ERROR: could not load BIOS for restored model")
    CloseFile(FileNum)
    ProcedureReturn 0
  EndIf
  If loadedCartA <> "" : LoadCartridge(loadedCartA, 1, loadedCartAMapper) : EndIf
  If loadedCartB <> "" : LoadCartridge(loadedCartB, 2, loadedCartBMapper) : EndIf

  ; RAMPages is whatever was live when the snapshot was saved - already a valid clamped size
  ; for the model it was saved under, and Mode is restored above before this runs, so
  ; ReallocateRAM()'s ClampRAMPages() call is a no-op here in practice (kept anyway, since
  ; asserting the invariant is cheap and it's the same call path RAM-size changes always go
  ; through). The mapper's default reversed-segment mapping ReallocateRAM() sets up gets
  ; immediately overwritten below by the actual saved RAMMapper() values.
  RAMPages = ReadLong(FileNum)
  ReallocateRAM()
  Protected mI.l, mV.a
  For mI = 0 To 3
    mV = ReadByte(FileNum)
    RAMMapper(mI) = mV
    *MemMap(3, 2, mI * 2)     = *RAMData + (mV << 14)
    *MemMap(3, 2, mI * 2 + 1) = *MemMap(3, 2, mI * 2) + $2000
  Next mI
  ReadData(FileNum, *RAMData, RAMPages * $4000)
  VRAMPages = ReadLong(FileNum)
  ReallocateVRAM()
  ReadData(FileNum, *VRAM, VRAMPages * $4000)
  ReadData(FileNum, @CPU, SizeOf(Z80))

  Protected I.l
  For I = 0 To 63 : VDP(I) = ReadByte(FileNum) : Next I
  For I = 0 To 15 : VDPStatus(I) = ReadByte(FileNum) : Next I
  VDPKey = ReadByte(FileNum)
  VDPALatch = ReadByte(FileNum)
  VDPAddr = ReadWord(FileNum)
  VDPData = ReadByte(FileNum)

  ReadData(FileNum, @MMC, SizeOf(VDPCommandState))
  ReadData(FileNum, @PSG, SizeOf(PSGState))
  ReadData(FileNum, @PPI, SizeOf(I8255))

  RTCReg = ReadByte(FileNum)
  RTCMode = ReadByte(FileNum)
  Protected bank.l, reg.l
  For bank = 0 To 3
    For reg = 0 To 12
      RTC(bank, reg) = ReadByte(FileNum)
    Next reg
  Next bank

  Protected loadedPSLReg.a = ReadByte(FileNum)
  For I = 0 To 3 : SSLReg(I) = ReadByte(FileNum) : Next I

  CloseFile(FileNum)

  ; Force PSlot() to recompute PSL()/SSL()/*RAM()/EnWrite() for all 4 pages from the just-
  ; restored SSLReg() array, instead of assigning PSLReg directly (which would skip that
  ; derivation - see PSlot()'s "If PSLReg <> V" change-detection guard in MSX.pbi).
  PSLReg = loadedPSLReg ! $FF
  PSlot(loadedPSLReg)
  SetScreen()
  UpdateModelMenuCheck()
  UpdateRAMSizeMenuCheck()
  UpdateVRAMSizeMenuCheck()

  LogGeneral("LoadSnapshot: restored " + FileName)
  ProcedureReturn 1
EndProcedure

; True if S is a plain (optionally signed) decimal integer - used to tell "-rom <type>"
; (a small number, real fMSX MegaROM mapper selector) apart from fossauro's own legacy
; "-rom <file>" shorthand, and to peek at "-sound [<quality>]"'s optional argument.
Procedure.b LooksNumeric(S.s)
  If S = "" : ProcedureReturn #False : EndIf
  Protected I.l, Start.l = 1
  If Mid(S, 1, 1) = "-" Or Mid(S, 1, 1) = "+" : Start = 2 : EndIf
  If Start > Len(S) : ProcedureReturn #False : EndIf
  For I = Start To Len(S)
    If Mid(S, I, 1) < "0" Or Mid(S, I, 1) > "9"
      ProcedureReturn #False
    EndIf
  Next I
  ProcedureReturn #True
EndProcedure

; fMSX-compatible command-line reference (see fossauro/fossauro.md for the full original
; text this is adapted from). Returned by -help as one block of text; also the ground truth
; for which flags RunEmulator()'s parser below recognizes. Not every flag has real effect
; yet - each line says so where that's the case, instead of silently pretending it works.
; Built as one string (not printed line-by-line) so the same text can go either to a
; console (PrintN) or a MessageRequester dialog, depending on how fossauro was launched -
; see the "-help" case in RunEmulator() below for why both paths exist.
Procedure.s GetFmsxHelpText()
  Protected T.s
  T = "fossauro " + #App_Version + " - PureBasic MSX Emulator" + #CRLF$
  T + "Usage: fossauro [-option1 [-option2...]] [filename1] [filename2]" + #CRLF$ + #CRLF$
  T + "  [filename1] = cartridge ROM to load in slot A" + #CRLF$
  T + "  [filename2] = cartridge ROM to load in slot B" + #CRLF$ + #CRLF$
  T + "  -help               - Print this help page and exit" + #CRLF$
  T + "  -verbose [<mask>]   - Turn on the log file (fossauro.log), off by default." + #CRLF$
  T + "                        <mask> is fossauro's own category bitmask (1=general," + #CRLF$
  T + "                        2=memory, 4=VDP, 8=PSG, 16=CPU) - NOT the same bit" + #CRLF$
  T + "                        meanings as real fMSX's -verbose. Omit <mask> for all." + #CRLF$
  T + "  -msx1/-msx2/-msx2+  - Select MSX model [-msx2]. Loads the matching BIOS" + #CRLF$
  T + "                        (MSX.ROM / MSX2.ROM+MSX2EXT.ROM / MSX2P.ROM+MSX2PEXT.ROM)" + #CRLF$
  T + "                        and applies the same cassette BIOS patches real fMSX" + #CRLF$
  T + "                        does." + #CRLF$
  T + "  -pal/-ntsc          - Set PAL/NTSC HBlank/VBlank periods [NTSC]" + #CRLF$
  T + "  -rom <type>         - Select MegaROM mapper type [8,8] (0-7, see fMSX docs)." + #CRLF$
  T + "                        Accepted and stored, mapper switching isn't" + #CRLF$
  T + "                        implemented yet, so it has no effect on emulation." + #CRLF$
  T + "                        A non-numeric argument here is treated as a legacy" + #CRLF$
  T + "                        fossauro cartridge-file shorthand instead." + #CRLF$
  T + "  -home <dirname>     - Accepted, not yet implemented (system ROM directory)." + #CRLF$
  T + "  -printer <filename> - Accepted, not yet implemented." + #CRLF$
  T + "  -serial <filename>  - Accepted, not yet implemented." + #CRLF$
  T + "  -diska <filename>   - Accepted, not yet implemented (disk drive A:)." + #CRLF$
  T + "  -diskb <filename>   - Accepted, not yet implemented (disk drive B:)." + #CRLF$
  T + "  -tape <filename>    - Accepted, not yet implemented." + #CRLF$
  T + "  -font <filename>    - Accepted, not yet implemented." + #CRLF$
  T + "  -logsnd <filename>  - Accepted, not yet implemented (no PSG audio yet)." + #CRLF$
  T + "  -state <filename>   - Accepted, not yet implemented (no save-state yet)." + #CRLF$
  T + "  -auto/-noauto       - Accepted, not yet implemented (autofire on SPACE)." + #CRLF$
  T + "  -ram <pages>        - Number of 16KB RAM mapper pages [4/8/8]. Rounded to a power" + #CRLF$
  T + "                        of 2 and clamped per model (MSX1 min 4, MSX2/2+ min 8, max" + #CRLF$
  T + "                        256) - same as real fMSX. Also settable live via" + #CRLF$
  T + "                        Hardware -> RAM Size." + #CRLF$
  T + "  -vram <pages>       - Number of 16KB VRAM pages [2/8/8]. Rounded to a power of 2;" + #CRLF$
  T + "                        MSX1 only accepts 2/4/8 (else resets to 2), MSX2/2+ only" + #CRLF$
  T + "                        accept exactly 8 (else resets to 8) - same as real fMSX," + #CRLF$
  T + "                        which has no 16KB-on-MSX1 or 192KB case at all. Also" + #CRLF$
  T + "                        settable live via Hardware -> VRAM Size." + #CRLF$
  T + "  -joy <type>         - Accepted, not yet implemented (no joystick input yet)." + #CRLF$
  T + "  -simbdos/-wd1793    - Accepted, not yet implemented (no disk controller yet)." + #CRLF$
  T + "  -sound [<quality>]  - Accepted, not yet implemented (no PSG audio yet)." + #CRLF$
  T + "  -nosound            - Accepted (no-op - there's no sound to disable yet)." + #CRLF$
  T + "  -skip <percent>     - Accepted, not yet implemented (frame skip)." + #CRLF$
  T + "  -sync <frequency>   - Accepted, not yet implemented (screen update sync)." + #CRLF$
  T + "  -nosync             - Accepted, not yet implemented." + #CRLF$
  T + "  -static/-nostatic   - Accepted, not yet implemented (palette mode)." + #CRLF$
  T + "  -tv/-lcd/-raster    - Accepted, not yet implemented (scanline/raster fx)." + #CRLF$
  T + "  -linear             - Accepted, not yet implemented (display scaling)." + #CRLF$
  T + "  -soft/-eagle        - Accepted, not yet implemented (display scaling)." + #CRLF$
  T + "  -epx/-scale2x       - Accepted, not yet implemented (display scaling)." + #CRLF$
  T + "  -cmy/-rgb           - Accepted, not yet implemented (pixel raster fx)." + #CRLF$
  T + "  -mono/-sepia        - Accepted, not yet implemented (CRT color fx)." + #CRLF$
  T + "  -green/-amber       - Accepted, not yet implemented (CRT color fx)." + #CRLF$
  T + "  -4x3                - Accepted, not yet implemented (screen ratio)." + #CRLF$
  T + "  -trap <address>     - Accepted, not yet implemented (debugger trap)." + #CRLF$
  T + "  -scale <factor>     - Accepted, not yet implemented (window scale)." + #CRLF$ + #CRLF$
  T + "Full original fMSX option reference: fossauro/fossauro.md"
  ProcedureReturn T
EndProcedure

; Reflect the current Mode's model as a checkmark on Hardware->Model's three radio-style items.
Procedure UpdateModelMenuCheck()
  SetMenuItemState(0, 11, Bool((Mode & #MSX_MODEL) = #MSX_MSX1))
  SetMenuItemState(0, 12, Bool((Mode & #MSX_MODEL) = #MSX_MSX2))
  SetMenuItemState(0, 13, Bool((Mode & #MSX_MODEL) = #MSX_MSX2P))
EndProcedure

; Reflect the ACTUAL current RAMPages (post-ClampRAMPages, may differ from what was clicked -
; see ClampRAMPages()'s docstring) as a checkmark on Hardware->RAM Size's five items.
Procedure UpdateRAMSizeMenuCheck()
  SetMenuItemState(0, 20, Bool(RAMPages = 4))
  SetMenuItemState(0, 21, Bool(RAMPages = 8))
  SetMenuItemState(0, 22, Bool(RAMPages = 16))
  SetMenuItemState(0, 23, Bool(RAMPages = 32))
  SetMenuItemState(0, 24, Bool(RAMPages = 64))
EndProcedure

; Same idea as UpdateRAMSizeMenuCheck(), for Hardware->VRAM Size - post-ClampVRAMPages(), so
; e.g. clicking "192 KB" on any model, or "16 KB" on MSX2/2+, ends up checking a DIFFERENT item
; than the one clicked (real fMSX has no 16KB-survives-on-MSX1 or 192KB/V9958-addon case at all
; - see ClampVRAMPages()'s docstring).
Procedure UpdateVRAMSizeMenuCheck()
  SetMenuItemState(0, 30, Bool(VRAMPages = 1))
  SetMenuItemState(0, 31, Bool(VRAMPages = 2))
  SetMenuItemState(0, 32, Bool(VRAMPages = 4))
  SetMenuItemState(0, 33, Bool(VRAMPages = 8))
  SetMenuItemState(0, 34, Bool(VRAMPages = 12))
EndProcedure

; Reflect CurCartAMapper/CurCartBMapper as checkmarks on each slot's Mapper Type submenu (item
; IDs offset by #MAP_* + 42 for Slot A, + 62 for Slot B - see the menu creation block).
Procedure UpdateCartMapperMenuCheck()
  Protected m.a
  For m = 0 To 8
    SetMenuItemState(0, 42 + m, Bool(CurCartAMapper = m))
    SetMenuItemState(0, 62 + m, Bool(CurCartBMapper = m))
  Next m
EndProcedure

; Reflect VideoScale/Force4x3 as checkmarks on the Video menu - same shape as the other
; Update*MenuCheck() procedures above.
Procedure UpdateVideoMenuCheck()
  SetMenuItemState(0, 80, Bool(VideoScale = 1))
  SetMenuItemState(0, 81, Bool(VideoScale = 2))
  SetMenuItemState(0, 82, Bool(VideoScale = 3))
  SetMenuItemState(0, 83, Bool(VideoScale = 4))
  SetMenuItemState(0, 84, Force4x3)
EndProcedure

; Switch the running machine to a different MSX model: reloads the model-appropriate BIOS and
; does a full hardware reset, same as picking a fresh -msx1/-msx2/-msx2+ at startup would - RAM/
; VRAM content and any loaded cartridge are NOT preserved (a model switch is a cold boot in real
; hardware terms, not a hot-swap).
Procedure SwitchModel(NewModel.l)
  ThreadPaused = 1
  Mode = (Mode & ~#MSX_MODEL) | NewModel
  If Not MSXLoadBIOSForModel()
    MessageRequester("fossauro Error", "Could not load MSX BIOS ROM for the selected model.")
  EndIf
  ; Re-clamp RAMPages against the NEW model's minimum (MSX1 4 pages/64KB, MSX2/2+ 8 pages/128KB
  ; - see ClampRAMPages()) and rebuild the RAM mapper's default mapping, same as real fMSX
  ; re-invoking ResetMSX() with the same RAMPages value against a different model on every
  ; switch. This also re-derives *RAM()/EnWrite() from scratch, since ReallocateRAM() frees and
  ; reallocates *RAMData - the old MemMap(3,2,...) pointers it invalidates would otherwise still
  ; be cached in *RAM() if some CPU page was currently viewing Slot 3-2.
  ReallocateRAM()
  ResetSlotsToStartup()
  ; Same re-clamp idea for VRAM (MSX1 2/4/8 pages, MSX2/2+ locked to exactly 8 - see
  ; ClampVRAMPages()) - a model switch changing e.g. MSX1's 32KB up to MSX2's mandatory 128KB.
  ReallocateVRAM()
  If CurCartAPath <> "" : LoadCartridge(CurCartAPath, 1, CurCartAMapper) : EndIf
  If CurCartBPath <> "" : LoadCartridge(CurCartBPath, 2, CurCartBMapper) : EndIf
  ResetZ80(@CPU)
  ResetVDP()
  ResetPSG()
  FDC_Reset()
  UpdateModelMenuCheck()
  UpdateRAMSizeMenuCheck()
  UpdateVRAMSizeMenuCheck()
  ThreadPaused = 0
  SetActiveGadget(0)
EndProcedure

; Change the amount of RAM (in 16KB pages behind the mapper) and do a full cold reset - same
; shape as real fMSX (MSX.c, Menu.c): changing RAM size always re-runs ResetMSX(), it's not a
; hot-swap. RequestedPages need not already be a valid size - ClampRAMPages() (called inside
; ReallocateRAM()) rounds up to the nearest power of 2 and clamps to the current model's valid
; range, so the actual applied size may silently differ from what was clicked (e.g. clicking
; "64KB" while running MSX2/2+ applies 128KB instead, MSX2's real minimum) - UpdateRAMSizeMenuCheck()
; reflects whatever was actually applied, not the raw click.
Procedure ApplyRAMSize(RequestedPages.l)
  ThreadPaused = 1
  RAMPages = RequestedPages
  ReallocateRAM()
  ResetSlotsToStartup()
  If Not MSXLoadBIOSForModel()
    MessageRequester("fossauro Error", "Could not reload MSX BIOS ROM after changing RAM size.")
  EndIf
  If CurCartAPath <> "" : LoadCartridge(CurCartAPath, 1, CurCartAMapper) : EndIf
  If CurCartBPath <> "" : LoadCartridge(CurCartBPath, 2, CurCartBMapper) : EndIf
  ResetZ80(@CPU)
  ResetVDP()
  ResetPSG()
  FDC_Reset()
  UpdateRAMSizeMenuCheck()
  ThreadPaused = 0
  SetActiveGadget(0)
EndProcedure

; Same idea as ApplyRAMSize(), for VRAM. See ClampVRAMPages()'s docstring for why most of the
; five menu options other than the model's real default silently apply something else instead.
Procedure ApplyVRAMSize(RequestedPages.l)
  ThreadPaused = 1
  VRAMPages = RequestedPages
  ReallocateVRAM()
  If CurCartAPath <> "" : LoadCartridge(CurCartAPath, 1, CurCartAMapper) : EndIf
  If CurCartBPath <> "" : LoadCartridge(CurCartBPath, 2, CurCartBMapper) : EndIf
  ResetZ80(@CPU)
  ResetVDP()
  ResetPSG()
  FDC_Reset()
  UpdateVRAMSizeMenuCheck()
  ThreadPaused = 0
  SetActiveGadget(0)
EndProcedure

; Builds the CLI args to relaunch fossauro.exe as a FRESH process with the current session's model/
; memory/cartridges preserved, plus the current (possibly just-changed) video scale/aspect - see the
; Video menu handlers below for why this is a full process relaunch rather than a live resize.
Procedure.s BuildRelaunchArgs()
  Protected Args.s = ""
  Select Mode & #MSX_MODEL
    Case #MSX_MSX2  : Args + "-msx2 "
    Case #MSX_MSX2P : Args + "-msx2+ "
    Default         : Args + "-msx1 "
  EndSelect
  Args + "-ram " + Str(RAMPages) + " "
  Args + "-vram " + Str(VRAMPages) + " "
  Args + "-vscale " + Str(VideoScale) + " "
  If Force4x3 : Args + "-4x3 " : EndIf
  If CurCartAPath <> "" : Args + Chr(34) + CurCartAPath + Chr(34) + " " : EndIf
  If CurCartBPath <> "" : Args + Chr(34) + CurCartBPath + Chr(34) + " " : EndIf
  ProcedureReturn Trim(Args)
EndProcedure

; Creates the main window (menu + canvas), at the given client size, from scratch - only ever called
; once, at startup. Real bug found live-testing the Video menu (2026-08-18): changing video scale/
; aspect while running needs a NEW window, but doing that in-process (ResizeWindow()/ResizeGadget(),
; or freeing and recreating just the CanvasGadget, or even a full CloseWindow()+reopen against this
; same process) reliably hangs the app a moment later, 100% reproducible across many variations tried
; (delays, draining the message queue, priming with a manual render pass, deferring the work outside
; the menu event dispatch) - never isolated to a specific PureBasic/Windows call, just consistently
; present any time a StartDrawing(CanvasOutput()) happens shortly after this process's window client
; area changes size. The reliable fix: the Video menu handlers below relaunch fossauro.exe as an
; entirely FRESH process (RunProgram(), same executable, args rebuilt from the current session's
; state via BuildRelaunchArgs() plus the new scale/aspect) and cleanly exit this one - a new process
; has no leftover state to be inconsistent, sidestepping the bug instead of fixing its root cause
; (never isolated - see docs/SPEC.md module 32s for the full investigation).
Procedure.b CreateFossauroWindow(w.l, h.l)
  If Not OpenWindow(0, 100, 100, w, h, "fossauro v" + #App_Version + " - PureBasic MSX Emulator", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    ProcedureReturn #False
  EndIf

  ; Create Menus
  If CreateMenu(0, WindowID(0))
    MenuTitle("File")
    MenuItem(1, "Open Cartridge...")
    MenuItem(2, "Open Disk...")
    MenuBar()
    MenuItem(3, "Save Snapshot...")
    MenuItem(4, "Open Snapshot...")
    MenuBar()
    MenuItem(5, "Load .CAS...")
    MenuItem(6, "Load .CHT...")
    MenuBar()
    MenuItem(7, "Quit")

    MenuTitle("Emulation")
    MenuItem(8, "Reset")
    MenuItem(9, "Pause")
    MenuItem(10, "Resume")

    MenuTitle("Hardware")
    OpenSubMenu("Model")
      MenuItem(11, "MSX1")
      MenuItem(12, "MSX2")
      MenuItem(13, "MSX2+")
    CloseSubMenu()
    OpenSubMenu("RAM Size")
      MenuItem(20, "64 KB")
      MenuItem(21, "128 KB")
      MenuItem(22, "256 KB")
      MenuItem(23, "512 KB")
      MenuItem(24, "1024 KB")
    CloseSubMenu()
    OpenSubMenu("VRAM Size")
      MenuItem(30, "16 KB")
      MenuItem(31, "32 KB")
      MenuItem(32, "64 KB")
      MenuItem(33, "128 KB")
      MenuItem(34, "192 KB")
    CloseSubMenu()
    OpenSubMenu("Cartridge Slot A")
      MenuItem(40, "Load...")
      MenuItem(41, "Eject")
      MenuBar()
      OpenSubMenu("Mapper Type")
        MenuItem(42, "Guess MegaROM mapper")
        MenuItem(43, "Generic 8KB")
        MenuItem(44, "Generic 16KB")
        MenuItem(45, "Konami 5000h (SCC)")
        MenuItem(46, "Konami 4000h")
        MenuItem(47, "ASCII 8KB")
        MenuItem(48, "ASCII 16KB")
        MenuItem(49, "Konami GameMaster2")
        MenuItem(50, "Panasonic FMPAC")
      CloseSubMenu()
    CloseSubMenu()
    OpenSubMenu("Cartridge Slot B")
      MenuItem(60, "Load...")
      MenuItem(61, "Eject")
      MenuBar()
      OpenSubMenu("Mapper Type")
        MenuItem(62, "Guess MegaROM mapper")
        MenuItem(63, "Generic 8KB")
        MenuItem(64, "Generic 16KB")
        MenuItem(65, "Konami 5000h (SCC)")
        MenuItem(66, "Konami 4000h")
        MenuItem(67, "ASCII 8KB")
        MenuItem(68, "ASCII 16KB")
        MenuItem(69, "Konami GameMaster2")
        MenuItem(70, "Panasonic FMPAC")
      CloseSubMenu()
    CloseSubMenu()

    MenuTitle("Video")
    OpenSubMenu("Scale")
      MenuItem(80, "1:1")
      MenuItem(81, "2:1")
      MenuItem(82, "3:1")
      MenuItem(83, "4:1")
    CloseSubMenu()
    MenuBar()
    MenuItem(84, "Force 4:3 screen ratio")
  EndIf
  UpdateModelMenuCheck()
  UpdateRAMSizeMenuCheck()
  UpdateVRAMSizeMenuCheck()
  UpdateCartMapperMenuCheck()
  UpdateVideoMenuCheck()

  ; Create Canvas Gadget
  CanvasGadget(0, 0, 0, w, h, #PB_Canvas_Keyboard)
  SetActiveGadget(0)
  ProcedureReturn #True
EndProcedure

; Initialize & Run Emulation
Procedure RunEmulator()
  ; fossauro.log is the definitive, persistent log - NOT wiped on every launch anymore.
  ; It accumulates across runs and rolls over on its own once it crosses #LogMaxBytes
  ; (see RotateLog() in MSX.pbi), Linux logrotate style (fossauro.log.1, .2, ...).
  LogGeneral("=== fossauro Start ===")
  
  ; fMSX-compatible CLI parsing (see GetFmsxHelpText() above and fossauro/fossauro.md for the
  ; full reference this is adapted from). Positional (non "-") arguments are cartridge A/B,
  ; matching real fMSX - "-rom <file>" (fossauro's own earlier shorthand) still works too,
  ; distinguished from real fMSX's "-rom <type>" by whether the argument is numeric.
  Protected CartA.s = "", CartB.s = ""
  Protected DiskA.s = "", DiskB.s = ""
  Protected ParameterCount.l = CountProgramParameters()
  Protected ParamIdx.l = 0

  While ParamIdx < ParameterCount
    Protected Param.s = ProgramParameter(ParamIdx)
    Protected LParam.s = LCase(Param)
    Protected NextArg.s = ""
    Protected HasNextArg.b = Bool(ParamIdx + 1 < ParameterCount)
    If HasNextArg : NextArg = ProgramParameter(ParamIdx + 1) : EndIf

    Select LParam
      Case "-help", "-h", "-?", "/?"
        ; fossauro.exe is a GUI-subsystem app: plain OpenConsole() doesn't reliably attach
        ; to the caller's existing terminal (confirmed - it went nowhere the user could see,
        ; even run directly from a real PowerShell/cmd window, not just redirected).
        ; AttachConsole_(ATTACH_PARENT_PROCESS) is the actual WinAPI call for "reuse the
        ; console of whoever launched me" - if that succeeds, print there. If it fails
        ; (double-clicked, no parent console at all), fall back to a dialog box so the text
        ; is guaranteed visible somewhere either way.
        Protected HelpText.s = GetFmsxHelpText()
        Protected AttachedConsole.b = #False
        CompilerIf #PB_Compiler_OS = #PB_OS_Windows
          If AttachConsole(#ATTACH_PARENT_PROCESS)
            AttachedConsole = #True
          EndIf
        CompilerEndIf
        If AttachedConsole
          OpenConsole()
          PrintN("")
          PrintN(HelpText)
          CloseConsole()
          CompilerIf #PB_Compiler_OS = #PB_OS_Windows
            FreeConsole()
          CompilerEndIf
        Else
          MessageRequester("fossauro " + #App_Version + " - Ajuda / Help", HelpText)
        EndIf
        End

      Case "-verbose"
        If HasNextArg And LooksNumeric(NextArg)
          LogCategories = Val(NextArg)
          ParamIdx + 2
        Else
          LogCategories = #LogCat_All
          ParamIdx + 1
        EndIf
        Verbose = Bool(LogCategories <> 0)

      Case "-rom"
        If HasNextArg
          If LooksNumeric(NextArg) And Val(NextArg) >= 0 And Val(NextArg) <= 7
            LogGeneral("CLI: -rom " + NextArg + " (MegaROM mapper type - accepted, not yet implemented)")
          Else
            CartA = NextArg
          EndIf
          ParamIdx + 2
        Else
          ParamIdx + 1
        EndIf

      Case "-msx1"
        Mode = (Mode & ~#MSX_MODEL) | #MSX_MSX1 : ParamIdx + 1
      Case "-msx2"
        Mode = (Mode & ~#MSX_MODEL) | #MSX_MSX2 : ParamIdx + 1
      Case "-msx2+"
        Mode = (Mode & ~#MSX_MODEL) | #MSX_MSX2P : ParamIdx + 1
      Case "-pal"
        Mode = Mode | #MSX_PAL : ParamIdx + 1
      Case "-ntsc"
        Mode = Mode & ~#MSX_PAL : ParamIdx + 1

      Case "-4x3" ; real fMSX flag, now actually wired (was accepted-but-inert before) - see
                  ; Force4x3's own comment near its Global declaration.
        Force4x3 = #True : ParamIdx + 1

      ; -vscale <1-4> - fossauro's own flag (not part of real fMSX's CLI), integer window scale
      ; multiplier for the Video menu's Scale submenu. Named differently from real fMSX's own
      ; "-scale <percent>" (still accepted-but-inert below) to avoid any ambiguity between the two.
      Case "-vscale"
        If HasNextArg And LooksNumeric(NextArg)
          VideoScale = Val(NextArg)
          If VideoScale < 1 : VideoScale = 1 : EndIf
          If VideoScale > 4 : VideoScale = 4 : EndIf
          ParamIdx + 2
        Else
          ParamIdx + 1
        EndIf

      ; -ram <pages> - number of 16KB RAM mapper pages (real fMSX convention). Just stores the
      ; raw value into RAMPages here, same as real fMSX's own CLI parser (fMSX.c) - the actual
      ; rounding-to-power-of-2/per-model clamping happens later in ClampRAMPages(), called from
      ; InitializeMSXMemory() below via ReallocateRAM().
      Case "-ram"
        If HasNextArg And LooksNumeric(NextArg)
          RAMPages = Val(NextArg)
          ParamIdx + 2
        Else
          ParamIdx + 1
        EndIf

      ; -vram <pages> - same idea as -ram, for VRAMPages/ClampVRAMPages() (called from
      ; InitializeVDP() below via ReallocateVRAM()).
      Case "-vram"
        If HasNextArg And LooksNumeric(NextArg)
          VRAMPages = Val(NextArg)
          ParamIdx + 2
        Else
          ParamIdx + 1
        EndIf

      ; -diska/-diskb <filename> - mounted after the FDC is reset, near the end of startup (same
      ; timing as CartA/CartB below), so this doesn't depend on init order within this loop.
      Case "-diska"
        If HasNextArg
          DiskA = NextArg
          ParamIdx + 2
        Else
          ParamIdx + 1
        EndIf
      Case "-diskb"
        If HasNextArg
          DiskB = NextArg
          ParamIdx + 2
        Else
          ParamIdx + 1
        EndIf

      ; Flags that take a filename/value argument - accepted and logged, not yet wired to
      ; actual behavior (see GetFmsxHelpText() for what each one is supposed to do).
      Case "-home", "-printer", "-serial", "-tape", "-font", "-logsnd",
           "-state", "-joy", "-skip", "-sync", "-scale", "-trap"
        If HasNextArg
          LogGeneral("CLI: " + LParam + " " + NextArg + " (accepted, not yet implemented)")
          ParamIdx + 2
        Else
          ParamIdx + 1
        EndIf

      ; -sound takes an OPTIONAL numeric argument
      Case "-sound"
        If HasNextArg And LooksNumeric(NextArg)
          LogGeneral("CLI: -sound " + NextArg + " (accepted, not yet implemented)")
          ParamIdx + 2
        Else
          LogGeneral("CLI: -sound (accepted, not yet implemented)")
          ParamIdx + 1
        EndIf

      ; Boolean-only flags - accepted and logged, not yet wired to actual behavior.
      Case "-auto", "-noauto", "-simbdos", "-wd1793", "-nosound", "-nosync", "-static",
           "-nostatic", "-tv", "-lcd", "-raster", "-linear", "-soft", "-eagle", "-epx",
           "-scale2x", "-cmy", "-rgb", "-mono", "-sepia", "-green", "-amber",
           "-shm", "-noshm", "-saver", "-nosaver", "-vsync", "-480", "-200"
        LogGeneral("CLI: " + LParam + " (accepted, not yet implemented)")
        ParamIdx + 1

      Default
        If Left(Param, 1) <> "-"
          ; Positional argument: cartridge A, then cartridge B (real fMSX convention)
          If CartA = ""
            CartA = Param
          ElseIf CartB = ""
            CartB = Param
          EndIf
        Else
          LogGeneral("CLI: unrecognized option '" + Param + "' (ignored)")
        EndIf
        ParamIdx + 1
    EndSelect
  Wend

  LogGeneral("CLI Arguments: CartA = '" + CartA + "' CartB = '" + CartB + "' DiskA = '" + DiskA + "' DiskB = '" + DiskB + "'")

  ; 1. Init tables and system state
  InitZ80Tables()
  InitializeMSXMemory()
  
  ; 2. Route CPU callback pointers
  RealRdZ80 = @MSXRdZ80()
  WrZ80 = @MSXWrZ80()
  InZ80 = @MSXInZ80()
  OutZ80 = @MSXOutZ80()
  LoopZ80 = @MSXLoopZ80()
  PatchZ80 = @MSXPatchZ80()

  ; Temporary crash-diagnostic: dump the storage ADDRESS of every Z80 core callback
  ; pointer variable (not its value) so a captured crash-dump's faulting CALL target
  ; address can be matched back to a name.
  LogGeneral("DIAG addr RealRdZ80=$" + Hex(@RealRdZ80) + " WrZ80=$" + Hex(@WrZ80) + " InZ80=$" + Hex(@InZ80) +
         " OutZ80=$" + Hex(@OutZ80) + " LoopZ80=$" + Hex(@LoopZ80) + " PatchZ80=$" + Hex(@PatchZ80) +
         " JumpZ80=$" + Hex(@JumpZ80))
  
  ; 3. Load BIOS (model-aware: MSX.ROM / MSX2.ROM+MSX2EXT.ROM / MSX2P.ROM+MSX2PEXT.ROM,
  ; picked from Mode - set above by -msx1/-msx2/-msx2+ - matching real fMSX's own BIOS
  ; selection in StartMSX(); also applies the cassette BIOS patches, see MSX.pbi)
  If Not MSXLoadBIOSForModel()
    MessageRequester("fossauro Error", "Could not load MSX BIOS ROM for the selected model.")
    End
  EndIf

  ; 4. Create Emulation Frame Buffer Image (512x212)
  If Not CreateImage(0, 512, 212, 32)
    MessageRequester("fossauro Error", "Failed to create back buffer image.")
    End
  EndIf
  
  ; 5. Open Graphical Window
  Protected win_w.l = 512 * VideoScale
  Protected win_h.l
  If Force4x3
    win_h = 384 * VideoScale
  Else
    win_h = 212 * VideoScale
  EndIf
  If CreateFossauroWindow(win_w, win_h)

    ; Load startup cartridge(s) if specified via command line
    If CartA <> ""
      LoadCartridge(CartA, 1)
    EndIf
    If CartB <> ""
      LoadCartridge(CartB, 2)
    EndIf

    ; Mount startup disk image(s) if specified via command line
    FDC_Reset()
    If DiskA <> ""
      If FDC_MountDisk(0, DiskA) : CurDiskAPath = DiskA : EndIf
    EndIf
    If DiskB <> ""
      If FDC_MountDisk(1, DiskB) : CurDiskBPath = DiskB : EndIf
    EndIf

    ; 6. Start audio and emulation threads
    StartAudio()
    ResetZ80(@CPU)
    ResetVDP()

    ThreadExit = 0
    ThreadPaused = 0
    EmulationThread = CreateThread(@EmulationThreadProc(), 0)
    ; PipeThread isn't WaitThread()'d at shutdown below - it's normally blocked in
    ; ConnectNamedPipe_/ReadFile_, which ThreadExit=1 alone can't wake up, and this whole
    ; process is about to End() right after the cleanup block anyway (see the "Shutdown &
    ; cleanup" comment near exit_window), which tears down every thread including this one.
    PipeThread = CreateThread(@PipeServerThreadProc(), 0)

    ; 7. Main Window Event Loop
    Protected event.l, exit_window.l = 0
    Protected PendingVideoResize.b = #False
    Repeat
      event = WaitWindowEvent()
      
      Select event
        Case #PB_Event_Menu
          Select EventMenu()
            Case 1 ; Open Cartridge...
              ThreadPaused = 1
              Protected rom_file.s = OpenFileRequester("Select MSX Cartridge ROM", "", "MSX ROM (*.rom)|*.rom;*.mx1;*.mx2|All files (*.*)|*.*", 0)
              If rom_file <> ""
                LoadCartridge(rom_file)
              EndIf
              ThreadPaused = 0
              SetActiveGadget(0)

            Case 2 ; Open Disk...
              ThreadPaused = 1
              Protected disk_file.s = OpenFileRequester("Select MSX Disk Image", "", "MSX Disk (*.dsk)|*.dsk|All files (*.*)|*.*", 0)
              If disk_file <> ""
                If FDC_MountDisk(0, disk_file) ; drive A
                  CurDiskAPath = disk_file
                  LogGeneral("Open Disk: " + disk_file + " mounted on drive A")
                Else
                  MessageRequester("fossauro Error", "Could not open disk image: " + disk_file)
                EndIf
              EndIf
              ThreadPaused = 0
              SetActiveGadget(0)

            Case 3 ; Save Snapshot...
              ThreadPaused = 1
              Protected save_file.s = SaveFileRequester("Save Snapshot", "", "fossauro Snapshot (*.fss)|*.fss", 0)
              If save_file <> ""
                If LCase(Right(save_file, 4)) <> ".fss" : save_file + ".fss" : EndIf
                If Not SaveSnapshot(save_file)
                  MessageRequester("fossauro Error", "Could not save snapshot to " + save_file)
                EndIf
              EndIf
              ThreadPaused = 0
              SetActiveGadget(0)

            Case 4 ; Open Snapshot...
              ThreadPaused = 1
              Protected load_snap_file.s = OpenFileRequester("Open Snapshot", "", "fossauro Snapshot (*.fss)|*.fss|All files (*.*)|*.*", 0)
              If load_snap_file <> ""
                If Not LoadSnapshot(load_snap_file)
                  MessageRequester("fossauro Error", "Could not load snapshot from " + load_snap_file)
                EndIf
              EndIf
              ThreadPaused = 0
              SetActiveGadget(0)

            Case 5 ; Load .CAS...
              ThreadPaused = 1
              Protected cas_file.s = OpenFileRequester("Select Cassette Tape Image", "", "Cassette Tape (*.cas)|*.cas|All files (*.*)|*.*", 0)
              If cas_file <> ""
                ; Cassette emulation not implemented yet (explicit scope decision - see
                ; docs/SPEC.md) - the picker exists so the menu structure is complete, but
                ; nothing is done with the file yet.
                LogGeneral("Load .CAS: " + cas_file + " (accepted, cassette emulation not yet implemented)")
                MessageRequester("fossauro", "Cassette tape emulation isn't implemented yet." + #CRLF$ + "The file was not loaded.")
              EndIf
              ThreadPaused = 0
              SetActiveGadget(0)

            Case 6 ; Load .CHT...
              ThreadPaused = 1
              Protected cht_file.s = OpenFileRequester("Select Cheat File", "", "Cheat File (*.cht)|*.cht|All files (*.*)|*.*", 0)
              If cht_file <> ""
                ; Cheat support (openMSX/BlueMSX .cht-compatible format) is planned but not
                ; implemented yet - see docs/SPEC.md.
                LogGeneral("Load .CHT: " + cht_file + " (accepted, cheat support not yet implemented)")
                MessageRequester("fossauro", "Cheat file support isn't implemented yet." + #CRLF$ + "The file was not loaded.")
              EndIf
              ThreadPaused = 0
              SetActiveGadget(0)

            Case 7 ; Quit
              exit_window = 1

            Case 8 ; Reset
              ThreadPaused = 1
              ResetZ80(@CPU)
              ResetVDP()
              ResetPSG()
              FDC_Reset()
              ThreadPaused = 0
              SetActiveGadget(0)

            Case 9 ; Pause
              ThreadPaused = 1

            Case 10 ; Resume
              ThreadPaused = 0
              SetActiveGadget(0)

            Case 11 ; Hardware -> Model -> MSX1
              SwitchModel(#MSX_MSX1)

            Case 12 ; Hardware -> Model -> MSX2
              SwitchModel(#MSX_MSX2)

            Case 13 ; Hardware -> Model -> MSX2+
              SwitchModel(#MSX_MSX2P)

            Case 20 ; Hardware -> RAM Size -> 64 KB
              ApplyRAMSize(4)

            Case 21 ; Hardware -> RAM Size -> 128 KB
              ApplyRAMSize(8)

            Case 22 ; Hardware -> RAM Size -> 256 KB
              ApplyRAMSize(16)

            Case 23 ; Hardware -> RAM Size -> 512 KB
              ApplyRAMSize(32)

            Case 24 ; Hardware -> RAM Size -> 1024 KB
              ApplyRAMSize(64)

            Case 30 ; Hardware -> VRAM Size -> 16 KB
              ApplyVRAMSize(1)

            Case 31 ; Hardware -> VRAM Size -> 32 KB
              ApplyVRAMSize(2)

            Case 32 ; Hardware -> VRAM Size -> 64 KB
              ApplyVRAMSize(4)

            Case 33 ; Hardware -> VRAM Size -> 128 KB
              ApplyVRAMSize(8)

            Case 34 ; Hardware -> VRAM Size -> 192 KB
              ApplyVRAMSize(12)

            Case 40 ; Hardware -> Cartridge Slot A -> Load...
              ThreadPaused = 1
              Protected cartA_file.s = OpenFileRequester("Select MSX Cartridge ROM (Slot A)", "", "MSX ROM (*.rom)|*.rom;*.mx1;*.mx2|All files (*.*)|*.*", 0)
              If cartA_file <> ""
                LoadCartridge(cartA_file, 1, CurCartAMapper)
              EndIf
              ThreadPaused = 0
              SetActiveGadget(0)

            Case 41 ; Hardware -> Cartridge Slot A -> Eject
              ThreadPaused = 1
              EjectCartridge(1)
              ThreadPaused = 0
              SetActiveGadget(0)

            Case 42 To 50 ; Hardware -> Cartridge Slot A -> Mapper Type -> ...
              CurCartAMapper = EventMenu() - 42
              If CurCartAPath <> ""
                ThreadPaused = 1
                LoadCartridge(CurCartAPath, 1, CurCartAMapper)
                ThreadPaused = 0
                SetActiveGadget(0)
              EndIf
              UpdateCartMapperMenuCheck()

            Case 60 ; Hardware -> Cartridge Slot B -> Load...
              ThreadPaused = 1
              Protected cartB_file.s = OpenFileRequester("Select MSX Cartridge ROM (Slot B)", "", "MSX ROM (*.rom)|*.rom;*.mx1;*.mx2|All files (*.*)|*.*", 0)
              If cartB_file <> ""
                LoadCartridge(cartB_file, 2, CurCartBMapper)
              EndIf
              ThreadPaused = 0
              SetActiveGadget(0)

            Case 61 ; Hardware -> Cartridge Slot B -> Eject
              ThreadPaused = 1
              EjectCartridge(2)
              ThreadPaused = 0
              SetActiveGadget(0)

            Case 62 To 70 ; Hardware -> Cartridge Slot B -> Mapper Type -> ...
              CurCartBMapper = EventMenu() - 62
              If CurCartBPath <> ""
                ThreadPaused = 1
                LoadCartridge(CurCartBPath, 2, CurCartBMapper)
                ThreadPaused = 0
                SetActiveGadget(0)
              EndIf
              UpdateCartMapperMenuCheck()

            Case 80 To 83 ; Video -> Scale -> 1:1/2:1/3:1/4:1
              ; 2:1/3:1/4:1 are disabled on purpose (2026-08-18) - confirmed via direct testing
              ; that ANY window/canvas size larger than the original 512x384 default reliably
              ; hangs this app (reproduced with a plain, fresh, non-relaunched launch at -vscale 2,
              ; no live resize involved at all - not a resize-mechanics bug, something in the
              ; per-frame DrawImage() stretch itself falls over above the size this project has
              ; always run at). Shipping a menu item that's confirmed to hang isn't acceptable, so
              ; only 1:1 (matching every prior release's fixed size) is wired to actually apply -
              ; see docs/SPEC.md module 32s for the full investigation and what's left to try.
              If EventMenu() = 80
                VideoScale = 1
                PendingVideoResize = #True
              Else
                MessageRequester("fossauro",
                  "Esta escala de video trava o fossauro nesta maquina (bug real, confirmado em teste - " +
                  "ver docs/SPEC.md modulo 32s). Por enquanto so 1:1 esta disponivel." + #CRLF$ +
                  "This video scale hangs fossauro on this machine (real, confirmed bug - see docs/SPEC.md " +
                  "module 32s). Only 1:1 is available for now.",
                  #PB_MessageRequester_Ok | #PB_MessageRequester_Warning)
              EndIf

            Case 84 ; Video -> Force 4:3 screen ratio
              Force4x3 = 1 - Force4x3
              PendingVideoResize = #True
          EndSelect
          
        Case #PB_Event_Gadget
          If EventGadget() = 0
            Protected canvas_type.l = EventType()
            Select canvas_type
              Case #PB_EventType_LeftButtonDown
                SetActiveGadget(0)
              Case #PB_EventType_LostFocus
                ResetKeyboard()
                Dim PCKeyStates.b(512)
              Case #PB_EventType_KeyDown
                Protected key_down.l = GetGadgetAttribute(0, #PB_Canvas_Key)
                If key_down >= 0 And key_down < 512
                  If PCKeyStates(key_down) = 0
                    PCKeyStates(key_down) = 1
                    Protected msx_key_down.l = MapCanvasKey(key_down)
                    If msx_key_down > 0
                      MSXKeyPress(msx_key_down)
                    EndIf
                  EndIf
                EndIf
                
              Case #PB_EventType_KeyUp
                Protected key_up.l = GetGadgetAttribute(0, #PB_Canvas_Key)
                If key_up >= 0 And key_up < 512
                  PCKeyStates(key_up) = 0
                  Protected msx_key_up.l = MapCanvasKey(key_up)
                  If msx_key_up > 0
                    MSXKeyRelease(msx_key_up)
                  EndIf
                EndIf
            EndSelect
          EndIf
          
        Case #PB_Event_FirstCustomValue + 1
          ; Frame Ready - Render to Canvas
          FramePending = 0
          If StartDrawing(ImageOutput(0))
            Protected *Buf = DrawingBuffer()
            Protected pitch.l = DrawingBufferPitch()
            Protected y.l
            For y = 0 To 211
              CopyMemory(@FrameBuffer(y * 512), *Buf + (211 - y) * pitch, 512 * 4)
            Next y
            StopDrawing()
          EndIf
          If StartDrawing(CanvasOutput(0))
            DrawImage(ImageID(0), 0, 0, win_w, win_h)
            StopDrawing()
          EndIf
          
        Case #PB_Event_CloseWindow
          exit_window = 1
      EndSelect

      If PendingVideoResize
        PendingVideoResize = #False
        ; Relaunch as a fresh process instead of resizing/recreating the window in-process - see
        ; BuildRelaunchArgs()/CreateFossauroWindow()'s comments for why. RunProgram() with just
        ; #PB_Program_Open (no Read/Error/Wait) starts the new instance and leaves it running
        ; independently, same fire-and-forget pattern as everywhere else an external/new process
        ; gets started in this codebase - then this instance shuts down cleanly through the normal
        ; exit_window path below (audio/emulation thread teardown, log close), not an abrupt End.
        RunProgram(ProgramFilename(), BuildRelaunchArgs(), GetPathPart(ProgramFilename()), #PB_Program_Open)
        exit_window = 1
      EndIf
    Until exit_window = 1
    
    ; 8. Shutdown & cleanup
    ThreadExit = 1
    If EmulationThread
      WaitThread(EmulationThread, 2000)
      EmulationThread = 0
    EndIf
    StopAudio()
    CloseLogFile()
  EndIf
EndProcedure

RunEmulator()
