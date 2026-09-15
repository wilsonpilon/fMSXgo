; fossauro_verify - PureBasic MSX Emulator Project
; Main Entry Point & CPU Core Verification

EnableExplicit

Global ThreadExit.l = 0
Global ThreadPaused.l = 0

; Include Z80 Emulator and Motherboard files
XIncludeFile "Z80_Tables.pbi"
XIncludeFile "Z80.pbi"
XIncludeFile "MSX.pbi"

; --- Z80 CPU Callback Implementations ---

Procedure MyPatchZ80(*R.Z80)
  ; Not used
EndProcedure

Procedure.u MyLoopZ80(*R.Z80)
  ; If PC reaches $000A, stop the emulation loop
  If *R\PC\W = $000A
    ProcedureReturn #INT_QUIT
  EndIf
  ProcedureReturn MSXLoopZ80(*R)
EndProcedure

Procedure MyJumpZ80(PC.u)
  ; PrintN("CPU Jumped to PC = " + Hex(PC))
EndProcedure

; --- Verification Program ---

Procedure VerifyZ80()
  OpenConsole("fossauro Z80 Verification")
  PrintN("Initializing Z80 Lookup Tables...")
  InitZ80Tables()
  
  PrintN("Initializing MSX Memory Mapper...")
  InitializeMSXMemory()
  
  ; Set global callback pointers
  RealRdZ80 = @MSXRdZ80()
  WrZ80 = @MSXWrZ80()
  InZ80 = @MSXInZ80()
  OutZ80 = @MSXOutZ80()
  LoopZ80 = @MyLoopZ80()
  JumpZ80 = @MyJumpZ80()
  
  PrintN("Loading MSX BIOS ROM...")
  Protected biosLoaded.l = MSXLoadBIOS("roms/MSX.ROM")
  If biosLoaded
    PrintN("SUCCESS: BIOS ROM loaded successfully (" + Str(32) + "KB)")
    ; Check if first byte of RAM (Slot 0-0 page 0) is $F3 (Z80 DI instruction)
    Protected firstByte.a = PeekA(*RAM(0))
    PrintN("BIOS ROM Header Byte: $" + Hex(firstByte))
    If firstByte = $F3
      PrintN("SUCCESS: BIOS header matched ($F3)!")
    Else
      PrintN("WARNING: BIOS header mismatched (expected $F3, got $" + Hex(firstByte) + ")")
    EndIf
  Else
    PrintN("FAILURE: Could not load MSX.ROM from 'fMSX/MSX.ROM'!")
  EndIf
  
  PrintN("Setting up Z80 verification program...")
  ; Press key 'A' (ASCII 65)
  MSXKeyPress(65)
  
  ; Assembly program to verify PPI / Keyboard (written over BIOS at $0000):
  ; 0000: LD A, $82     ($3E $82)       - PPI Control Word: Port A=Out, Port B=In, Port C=Out
  ; 0002: OUT ($AB), A  ($D3 $AB)       - Write to PPI Control Port
  ; 0004: LD A, 2       ($3E $02)       - Select Row 2
  ; 0006: OUT ($AA), A  ($D3 $AA)       - Write to PPI Port C (Row selector)
  ; 0008: IN A, ($A9)   ($DB $A9)       - Read from PPI Port B (Keyboard Matrix Row)
  ; 000A: JP $0008      ($C3 $08 $00)   - Stop Emulation (loop back to JP address)
  
  ; Write program directly to Slot 0:0 Page 0 (*RAM(0))
  PokeA(*RAM(0) + 0, $3E) : PokeA(*RAM(0) + 1, $82)
  PokeA(*RAM(0) + 2, $D3) : PokeA(*RAM(0) + 3, $AB)
  PokeA(*RAM(0) + 4, $3E) : PokeA(*RAM(0) + 5, 2)
  PokeA(*RAM(0) + 6, $D3) : PokeA(*RAM(0) + 7, $AA)
  PokeA(*RAM(0) + 8, $DB) : PokeA(*RAM(0) + 9, $A9)
  PokeA(*RAM(0) + 10, $C3) : PokeA(*RAM(0) + 11, $0A) : PokeA(*RAM(0) + 12, $00)
  
  CPU\IPeriod = 10 ; period cycles between periodic loop check
  
  PrintN("Resetting CPU...")
  ResetZ80(@CPU)
  
  PrintN("Running CPU...")
  RunZ80(@CPU)
  
  PrintN("Emulation stopped. Verifying results...")
  PrintN("PC : $" + Hex(CPU\PC\W))
  PrintN("A  : $" + Hex(CPU\AF\B\h) + " (Key matrix row read)")
  PrintN("F  : $" + Hex(CPU\AF\B\l))
  
  If CPU\AF\B\h = $BF And biosLoaded And firstByte = $F3
    PrintN("")
    PrintN("---------------------------------------------")
    PrintN(" SUCCESS: BIOS Loader & PPI/Keyboard verified successfully!")
    PrintN("---------------------------------------------")
  Else
    PrintN("")
    PrintN("---------------------------------------------")
    PrintN(" FAILURE: Verification failed!")
    PrintN("---------------------------------------------")
  EndIf
  
  PrintN("Press enter to exit...")
  Input()
  CloseConsole()
EndProcedure

VerifyZ80()
