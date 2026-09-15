; MSX Board Emulation & Slot Memory Mapper for fossauro
; Derived from fMSX source by Marat Fayzullin

; System hardware constants
#MSX_MODEL  = $03
#MSX_MSX1   = $00
#MSX_MSX2   = $01
#MSX_MSX2P  = $02

#MSX_VIDEO  = $04
#MSX_NTSC   = $00
#MSX_PAL    = $04

; MegaROM bank-switch mapper types - matches real fMSX exactly (MSX.h: MAP_* constants).
#MAP_GEN8     = 0   ; Generic switch, 8kB pages, any address in $4000-$BFFF
#MAP_GEN16    = 1   ; Generic switch, 16kB pages (MSXDOS2-style)
#MAP_KONAMI5  = 2   ; Konami 5000h/7000h/9000h/B000h (SCC games; SCC sound itself not emulated)
#MAP_KONAMI4  = 3   ; Konami 4000h/6000h/8000h/A000h (plain, no SCC)
#MAP_ASCII8   = 4   ; ASCII 6000h-7FFFh, 8kB pages, SRAM-capable
#MAP_ASCII16  = 5   ; ASCII 6000h/7000h, 16kB pages, SRAM-capable
#MAP_GMASTER2 = 6   ; Konami GameMaster2, SRAM-capable
#MAP_FMPAC    = 7   ; Panasonic FMPAC, SRAM-capable (FM/OPLL sound itself not emulated)
#MAP_GUESS    = 8   ; Auto-detect from ROM content (GuessROMType())

; CPU Cycles per scanline phase
#CPU_HPERIOD = 228                ; 1368 VDP cycles / 6
#CPU_H240    = 160                ; 960 VDP cycles / 6
#CPU_H256    = 170                ; 1024 VDP cycles / 6

; Interrupt request bitmasks in IRQPending
#INT_IE0     = $01                ; VBlank Interrupt flag (IE0)
#INT_IE1     = $02                ; Line Coincidence Interrupt flag (IE1)

Global CPU.Z80                    ; Global Z80 CPU state
Global IRQPending.a = 0           ; Bitmask of currently pending interrupts
Global FramePending.i = 0         ; Frame event synchronization flag

; Global memory mapping arrays
Global Dim *RAM(7)              ; Active Z80 address space (8 x 8KB pages)
Global Dim *MemMap(3, 3, 7)     ; Slot memory layout mapping [PrimarySlot][SecondarySlot][8KBPage]
Global Dim EnWrite.a(3)           ; 1 if write-enabled for each of the 4 16KB pages
Global Dim PSL.a(3)               ; Primary slot selection list for the 4 pages
Global Dim SSL.a(3)               ; Secondary slot selection list for the 4 pages

; Intel 8255 PPI Structure
Structure I8255
  R.a[4]         ; Registers
  Rout.a[3]      ; Output ports
  Rin.a[3]       ; Input ports
EndStructure

Global PPI.I8255                  ; Main Intel 8255 PPI instance

; Slot Registers
Global PSLReg.a                   ; Primary slot register state (PPI port $A8)
Global Dim SSLReg.a(3)            ; Secondary slot registers state (each slot has one at $FFFF)

; MSX2/2+ Real-Time Clock (RP-5C01-style, ports $B4=register select / $B5=data), matches real
; fMSX's RTCIn()/RTCReg/RTCMode/RTC[4][13] (MSX.c). Found missing entirely 2026-08-17 while
; chasing the MSX2/2+ boot freeze (docs/SPEC.md module 32d/32g): the extended BIOS's clock-init
; routine polls port $B5 in a loop with NO timeout, waiting for a BCD digit pair in a plausible
; range - fossauro had no handler for $B4/$B5 at all, so reads fell through to the default $FF,
; which never satisfied the check, hanging forever. MSX1 never hits this code path (no extended
; BIOS), which is why the freeze only showed up once MSX2/2+ BIOS loading was implemented.
Global RTCReg.a = 0                ; Selected RTC sub-register (0-15, only 0-13 meaningful)
Global RTCMode.a = 0                ; RTC[13] doubles as the register-bank select (bits 0-1)
Global Dim RTC.a(3, 12)            ; 4 banks x 13 registers (banks 1-3 are battery-backed free RAM)

; fossauro.log is the ONE definitive log for this emulator - every subsystem (General/
; Memory/VDP/PSG/CPU) writes here through LogMsg(), gated only by Verbose. Each category
; also has its own on/off switch (LogCategories bitmask below) so a future settings
; screen/CLI flag can show just "VDP only" or "Memory only" without touching the file
; format or the rotation logic - it's all still the same fossauro.log/.1/.2/... stream,
; just tagged per line ("[VDP] ...", "[MEM] ...", etc.) and filterable at the source.
Global LogFileHandle.i = 0        ; Kept open across calls, never Close'd per line (that
                                   ; was a real perf bug - PSlot/SSlot fire dozens-hundreds
                                   ; of times during a real MSX BIOS cartridge slot scan;
                                   ; Open+Write+Close per call made that look like a hang).

; Log rotation (Linux logrotate style): once fossauro.log reaches #LogMaxBytes, it's
; renamed fossauro.log.1 (bumping any existing .1..#LogMaxBackups-1 up by one, oldest
; dropped) and a fresh empty fossauro.log is started. Checked cheaply via Lof() after
; each write - no manual byte counting to keep in sync.
#LogMaxBytes = 5 * 1024 * 1024     ; ~5MB per generation
#LogMaxBackups = 5                 ; fossauro.log.1 .. fossauro.log.5

; Granular log categories - bitmask, so any combination can be on at once. Defaults to
; #LogCat_All (current behavior: everything logs). A future UI/CLI flag just needs to
; set LogCategories to whichever bits it wants; LogGeneral()/LogMemory()/LogVDP()/
; LogPSG()/LogCPU() below are the only call sites that need to change - nothing about
; LogMsg(), rotation, or Verbose changes.
#LogCat_General = 1  ; startup/shutdown, ROM/BIOS loading, CLI args
#LogCat_Memory  = 2  ; PSlot/SSlot, MSXRdZ80/MSXWrZ80 (slots, RAM/ROM dispatch)
#LogCat_VDP     = 4  ; V9938 (SetScreen, VRAM bounds, ports $98-$9B)
#LogCat_PSG     = 8  ; AY8910 (not wired into any LogMsg call yet - ready for when it is)
#LogCat_CPU     = 16 ; Z80 core: FRAME snapshots, instruction TRACE, null-callback guards
#LogCat_All     = 31 ; General|Memory|VDP|PSG|CPU

Global LogCategories.l = #LogCat_All

; Temporary crash-diagnostic aid: cheap (no I/O) rolling trackers of the last address
; touched by MSXRdZ80/MSXWrZ80, surfaced in the already-frequent PSlot/SSlot log lines
; instead of logging every single memory access (which would be too much volume).
Global LastRdAddr.u = 0
Global LastWrAddr.u = 0

; Instruction trace globals (TraceActive/TraceWasInCart/TraceInstrInVisit/
; #TraceMaxInstrPerVisit) live in Z80.pbi instead, near the top - Z80.pbi is
; XIncludeFile'd BEFORE this file, and RunZ80's loop (Z80.pbi) is what reads/writes
; them, so they need to be declared before that point in compile order.

Declare LogMsg(Msg.s)
Declare CloseLogFile()
Declare RotateLog()
Declare LogGeneral(Msg.s)
Declare LogMemory(Msg.s)
Declare LogVDP(Msg.s)
Declare LogPSG(Msg.s)
Declare LogCPU(Msg.s)

; Key Matrix state (16 rows)
Global Dim KeyMatrix.a(15)        ; MSX keyboard row state matrix
Global Dim KeysRow.a(129)         ; Keyboard matrix row for each code
Global Dim KeysMask.a(129)        ; Keyboard matrix mask for each code

; Emulator control variables
; Off by default: LogMsg() (and every LogGeneral/LogMemory/LogCPU/... call built on it)
; is a synchronous disk write gated by this flag. The per-instruction CPU trace/DIAG
; checkpoints in Z80.pbi's RunZ80() fire for every instruction executed anywhere in
; $4000-$7FFF - which is not just "the cartridge", it's also the MSX1 BASIC ROM's own
; address range, hit on every single cold boot with or without a cartridge inserted.
; With Verbose defaulting to 1, that turned a boot-time delay loop that should finish in
; milliseconds into one that takes ~30-60+ real seconds of synchronous log writes,
; which is what looked like "não boota mais" (frozen blue screen) - confirmed by timing
; a rebuilt run: stuck at PC=$7D0D for 45s of wall-clock time while Verbose=1, but the
; CPU/memory logic itself was fine (HL was decrementing correctly the whole time; letting
; it run long enough, it did get past $7D0D and into the normal per-frame loop). Pass
; -verbose on the command line to turn this back on for diagnostics.
Global Verbose.a = 0
Global Mode.l = #MSX_MSX1 | #MSX_NTSC  ; Default MSX1 NTSC (project owner's choice, 2026-08-18)
; RAM mapper state (ports $FC-$FF), matching real fMSX (MSX.c: RAMPages/RAMMask/RAMMapper[],
; ResetMSX()) - see docs/SPEC.md for the full writeup. fMSX does NOT model MSX1 RAM expansion
; as separate cartridges in extra slots; it uses this SAME bank-switched mapper (hardwired to
; Primary Slot 3, Secondary Slot 2) for every model alike, only the minimum page count differs
; (MSX1 min 4 pages/64KB, MSX2/2+ min 8 pages/128KB - real MSX1 machines rarely had a mapper at
; all, but fMSX's emulation always implements one underneath; MSX1 software that never touches
; $FC-$FF just sees a flat, correctly-ordered 64KB and never notices).
Global RAMPages.l = 4              ; Number of 16KB RAM pages (4=64KB ... 64=1024KB); see ClampRAMPages()
Global RAMMask.a = 0               ; RAMPages-1, masks mapper port reads/writes to valid pages
Global Dim RAMMapper.a(3)          ; Current 16KB segment selected for each of the 4 CPU pages
Global VRAMPages.l = 1            ; 1 x 16KB = 16KB VRAM (MSX1 default; see ClampVRAMPages() in
                                   ; V9938.pbi for why MSX1 accepts this at all - a deliberate
                                   ; deviation from real fMSX, project owner's choice 2026-08-18)
Global UPeriod.a = 75             ; % of frames to draw (defaults to 75)

; Include V9938 VDP Graphics Processor Emulation
XIncludeFile "V9938.pbi"
XIncludeFile "AY8910.pbi"
XIncludeFile "FDC.pbi"

; Memory blocks
Global *EmptyRAM                  ; Pointer to dummy 8KB block initialized to $FF
Global *RAMData                   ; Main RAM buffer
Global *BIOSData                  ; Main MSX BIOS+BASIC ROM buffer (32KB) - slot 0-0
Global *BIOSExtData                ; MSX2/MSX2+ extended BIOS ROM buffer (16KB) - slot 3-1.
                                    ; MSX1 has no extended BIOS; that subslot stays *EmptyRAM,
                                    ; matching real fMSX's MemMap[3][1][0/1]=EmptyRAM for MSX1
                                    ; (MSX.c, StartMSX(), MSX_MSX1 case).
Global *BIOSDiskData               ; DiskROM buffer (16KB) - slot 3-1 pages 2-3 ($4000-$7FFF when
                                    ; that subslot is paged in), same slot as the ExtBIOS above but
                                    ; the other half - loaded for every model alike (real MSX1
                                    ; machines with a disk drive carry DISK.ROM too, not just MSX2+).
Global Dim *ROMData(5)            ; Cartridge/System ROM data pointers
; MegaROM mapper state, one entry per cartridge slot - fossauro only ever uses indices 0 (Cart
; A / Primary Slot 1) and 1 (Cart B / Primary Slot 2), unlike real fMSX's MAXSLOTS=6 (which also
; covers system carts like MSXDOS2/FMPAC/GameMaster2 loaded at boot - fossauro doesn't load
; those). Matches real fMSX's ROMMask[]/ROMType[]/ROMMapper[][4] (MSX.c) - see MapROM() below.
Global Dim ROMMask.a(5)           ; (pages-1) AND-mask for bank-select values; 0 = not a MegaROM
Global Dim ROMType.a(5)           ; one of #MAP_* above
Global Dim ROMMapper.a(5, 3)      ; current 8KB-page index for each of the 4 CPU windows
                                   ; ($4000/$6000/$8000/$A000), or $FF = SRAM selected for that window
Global Dim *SRAMData(5)           ; battery-backed SRAM (ASCII8/ASCII16/GameMaster2/FMPAC only,
                                   ; allocated on first use) - session-only, never saved to a
                                   ; .sav file (no persistence support yet, same as real fMSX
                                   ; needs an explicit "-sram"-equivalent to persist across runs)
Global Dim FMPACKey.u(5)          ; FMPAC's $5FFE/$5FFF SRAM-unlock latch state, per slot

; Intel 8255 PPI Helper Procedures
Procedure Reset8255(*D.I8255)
  *D\R[0] = 0 : *D\Rout[0] = 0 : *D\Rin[0] = 0
  *D\R[1] = 0 : *D\Rout[1] = 0 : *D\Rin[1] = 0
  *D\R[2] = 0 : *D\Rout[2] = 0 : *D\Rin[2] = 0
  *D\R[3] = $9B
EndProcedure

Procedure.a Write8255(*D.I8255, A.a, V.a)
  Select A
    Case 0, 1, 2
      *D\R[A] = V
    Case 3
      If V & $80
        *D\R[3] = V
      Else
        Protected bit.a = 1 << ((V & $0E) >> 1)
        If V & $01
          *D\R[2] = *D\R[2] | bit
        Else
          *D\R[2] = *D\R[2] & ~bit
        EndIf
      EndIf
    Default
      ProcedureReturn 0
  EndSelect
  
  Protected ctrl.a = *D\R[3]
  If ctrl & $10 : *D\Rout[0] = $00 : Else : *D\Rout[0] = *D\R[0] : EndIf
  If ctrl & $02 : *D\Rout[1] = $00 : Else : *D\Rout[1] = *D\R[1] : EndIf
  
  Protected rout2.a = 0
  If (ctrl & $01) = 0 : rout2 | (*D\R[2] & $0F) : EndIf
  If (ctrl & $08) = 0 : rout2 | (*D\R[2] & $F0) : EndIf
  *D\Rout[2] = rout2
  
  ProcedureReturn 1
EndProcedure

Procedure.a Read8255(*D.I8255, A.a)
  Select A
    Case 0
      If *D\R[3] & $10 : ProcedureReturn *D\Rin[0] : Else : ProcedureReturn *D\R[0] : EndIf
    Case 1
      If *D\R[3] & $02 : ProcedureReturn *D\Rin[1] : Else : ProcedureReturn *D\R[1] : EndIf
    Case 2
      Protected val2.a = 0
      If *D\R[3] & $01 : val2 | (*D\Rin[2] & $0F) : Else : val2 | (*D\R[2] & $0F) : EndIf
      If *D\R[3] & $08 : val2 | (*D\Rin[2] & $F0) : Else : val2 | (*D\R[2] & $F0) : EndIf
      ProcedureReturn val2
    Case 3
      ProcedureReturn *D\R[3]
  EndSelect
  ProcedureReturn $00
EndProcedure

; Read a Real-Time Clock sub-register (port $B5 IN). Matches real fMSX's RTCIn() (MSX.c) - bank
; 0 always reflects the live system clock (BCD digits split across registers 0-12: sec/min/hour/
; weekday/day/month/year-since-1980), banks 1-3 are battery-backed free RAM (just RTC() storage,
; no live meaning). The four upper bits are always set on real hardware, so every read is OR'd
; with $F0 regardless of which branch produced the value.
Procedure.a RTCIn(R.a)
  Protected J.a
  R = R & $0F
  Protected bank.a = RTCMode & $03

  If R > 12
    If R = 13
      J = RTCMode
    Else
      J = $0F
    EndIf
  ElseIf bank
    J = RTC(bank, R)
  Else
    Protected d.i = Date()
    Select R
      Case 0  : J = Second(d) % 10
      Case 1  : J = Second(d) / 10
      Case 2  : J = Minute(d) % 10
      Case 3  : J = Minute(d) / 10
      Case 4  : J = Hour(d) % 10
      Case 5  : J = Hour(d) / 10
      Case 6  : J = DayOfWeek(d)
      Case 7  : J = Day(d) % 10
      Case 8  : J = Day(d) / 10
      Case 9  : J = Month(d) % 10
      Case 10 : J = Month(d) / 10
      Case 11 : J = (Year(d) - 1980) % 10
      Case 12 : J = ((Year(d) - 1980) / 10) % 10
    EndSelect
  EndIf

  ProcedureReturn J | $F0
EndProcedure

; Round Requested up to the nearest power of 2, then clamp to a valid RAM page count for the
; CURRENT model - matches real fMSX exactly (MSX.c, ResetMSX()): MSX1 minimum 4 pages (64KB),
; MSX2/MSX2+ minimum 8 pages (128KB), maximum 256 pages (4096KB) either way. Out-of-range values
; snap straight to the model's minimum (not clamp down to 256) - a real fMSX quirk, kept as-is
; for parity: requesting more than 4096KB resets to the model's smallest valid size, it doesn't
; cap at the largest.
Procedure.l ClampRAMPages(Requested.l)
  Protected P.l = 1
  While P < Requested
    P << 1
  Wend
  Protected MinPages.l = 8
  If (Mode & #MSX_MODEL) = #MSX_MSX1 : MinPages = 4 : EndIf
  If P < MinPages Or P > 256 : P = MinPages : EndIf
  ProcedureReturn P
EndProcedure

; (Re)allocate *RAMData at the current RAMPages size and rebuild the RAM-mapper's default
; power-on mapping - matches real fMSX's ResetMSX() (MSX.c): segment (3-J) at CPU page J, i.e.
; RAMMapper[]=3:2:1:0, so segment 0 ends up visible at $C000 by the same reset convention real
; MSX2-mapper hardware uses. Only the first 4 segments (64KB) are reachable this way without
; software writing the $FC-$FF mapper ports itself - exactly like real hardware/fMSX, any RAM
; beyond that is present in *RAMData but only reachable via the mapper ports.
Procedure ReallocateRAM()
  If *RAMData : FreeMemory(*RAMData) : EndIf
  RAMPages = ClampRAMPages(RAMPages)
  RAMMask = RAMPages - 1
  *RAMData = AllocateMemory(RAMPages * $4000)
  FillMemory(*RAMData, RAMPages * $4000, $FF) ; uninitialized RAM reads as $FF, matching real fMSX/hardware
  Protected J.l
  For J = 0 To 3
    RAMMapper(J) = 3 - J
    *MemMap(3, 2, J * 2)     = *RAMData + (3 - J) * $4000
    *MemMap(3, 2, J * 2 + 1) = *MemMap(3, 2, J * 2) + $2000
  Next J
EndProcedure

; Force primary/secondary slots back to their power-on state (both pointing at Slot 0-0, the
; BIOS ROM) and re-derive the CPU-visible *RAM()/EnWrite() pointers from scratch - shared by
; InitializeMSXMemory() (first-ever startup) and ApplyRAMSize() (RAM size changed mid-session,
; which - like a real -ram change or Hardware->Model switch - implies a full cold reset).
Procedure ResetSlotsToStartup()
  Protected J.l
  PSLReg = $00
  For J = 0 To 3
    PSL(J) = 0
    SSL(J) = 0
    SSLReg(J) = $00
    *RAM(J * 2)     = *MemMap(0, 0, J * 2)
    *RAM(J * 2 + 1) = *MemMap(0, 0, J * 2 + 1)
    EnWrite(J) = 0
  Next J
EndProcedure

; Initialize Z80-mapped slot memories and hardware registers
Procedure InitializeMSXMemory()
  Protected I.l, J.l, K.l

  ; Allocate empty RAM region (filled with $FF)
  *EmptyRAM = AllocateMemory($2000)
  FillMemory(*EmptyRAM, $2000, $FF)

  ; Allocate main BIOS ROM memory (32KB default)
  *BIOSData = AllocateMemory($8000)
  FillMemory(*BIOSData, $8000, $FF)

  ; Initialize all Slot memory mappings to EmptyRAM
  For I = 0 To 3
    For J = 0 To 3
      For K = 0 To 7
        *MemMap(I, J, K) = *EmptyRAM
      Next K
    Next J
  Next I

  ; Allocate main system RAM and wire up the mapper's default power-on mapping
  ReallocateRAM()

  ; Set initial primary and secondary slots
  ResetSlotsToStartup()

  ; Load Keyboard matrix configuration from DataSection
  Restore KeyboardData
  For I = 0 To 129
    Read.b KeysRow(I)
    Read.b KeysMask(I)
  Next I
  
  ; Clear Keyboard Matrix (all keys released, active low)
  For I = 0 To 15
    KeyMatrix(I) = $FF
  Next I
  
  ; Reset PPI chip state
  Reset8255(@PPI)
  
  ; Initialize VDP chip state
  InitializeVDP()
EndProcedure

; Load BIOS file from disk and map it to Slot 0-0
Procedure.l MSXLoadBIOS(FileName.s)
  LogGeneral("MSXLoadBIOS called for: " + FileName)
  Protected FileNum.i = ReadFile(#PB_Any, FileName)
  If FileNum = 0
    LogGeneral("MSXLoadBIOS ERROR: Could not open " + FileName)
    ProcedureReturn 0 ; failed to open
  EndIf

  Protected Length.q = Lof(FileNum)
  LogGeneral("MSXLoadBIOS: File size = " + Str(Length) + " bytes")
  If Length > $8000
    Length = $8000
  EndIf
  
  ReadData(FileNum, *BIOSData, Length)
  CloseFile(FileNum)
  
  ; Map BIOS to Slot 0-0 pages 0, 1, 2, 3 (each is 8KB, total 32KB)
  Protected I.l
  For I = 0 To 3
    *MemMap(0, 0, I) = *BIOSData + I * $2000
  Next I
  
  ; Update active memory pages if Slot 0-0 is mapped
  For I = 0 To 3
    If PSL(I) = 0 And SSL(I) = 0
      *RAM(I * 2)     = *MemMap(0, 0, I * 2)
      *RAM(I * 2 + 1) = *MemMap(0, 0, I * 2 + 1)
    EndIf
  Next I

  ProcedureReturn 1 ; success
EndProcedure

; Load the MSX2/MSX2+ extended BIOS ROM (16KB) and map it to Slot 3-1 - real MSX2/MSX2+
; hardware convention (fMSX/fMSX/MSX.c, StartMSX(): MemMap[3][1][0/1]=P2 for MSX_MSX2/MSX_MSX2P).
; MSX1 has no extended BIOS; that subslot is left as *EmptyRAM (set once in
; InitializeMSXMemory()'s blanket fill, never overwritten for MSX1 - matches fMSX exactly).
Procedure.l MSXLoadExtBIOS(FileName.s)
  LogGeneral("MSXLoadExtBIOS called for: " + FileName)
  Protected FileNum.i = ReadFile(#PB_Any, FileName)
  If FileNum = 0
    LogGeneral("MSXLoadExtBIOS ERROR: Could not open " + FileName)
    ProcedureReturn 0
  EndIf

  Protected Length.q = Lof(FileNum)
  LogGeneral("MSXLoadExtBIOS: File size = " + Str(Length) + " bytes")
  If Length > $4000
    Length = $4000
  EndIf

  If Not *BIOSExtData
    *BIOSExtData = AllocateMemory($4000)
  EndIf
  FillMemory(*BIOSExtData, $4000, $00)
  ReadData(FileNum, *BIOSExtData, Length)
  CloseFile(FileNum)

  ; Map ExtBIOS to Slot 3-1 pages 0, 1 (each 8KB, total 16KB)
  *MemMap(3, 1, 0) = *BIOSExtData
  *MemMap(3, 1, 1) = *BIOSExtData + $2000

  ; Update active memory pages if Slot 3-1 is currently mapped anywhere
  Protected I.l
  For I = 0 To 3
    If PSL(I) = 3 And SSL(I) = 1
      *RAM(I * 2)     = *MemMap(3, 1, I * 2)
      *RAM(I * 2 + 1) = *MemMap(3, 1, I * 2 + 1)
    EndIf
  Next I

  ProcedureReturn 1
EndProcedure

; Load DISK.ROM (16KB) and map it to Slot 3-1 pages 2-3 ($4000-$7FFF within that subslot) - same
; slot as MSXLoadExtBIOS() above, adjacent pages, so MSX2/MSX2+'s ExtBIOS (pages 0-1) and DiskROM
; (pages 2-3) coexist in the same 32KB subslot exactly like real hardware. Loaded for every model
; alike, including MSX1 (a real MSX1 machine with a disk drive has DISK.ROM too - this project's own
; MSX1 default just happens to not ship a MegaROM/expansion by default, disk support is independent
; of that). Optional: a machine with no disk drive at all is a legitimate real configuration, so a
; missing/unreadable roms/DISK.ROM is logged and left as *EmptyRAM rather than treated as fatal
; (unlike MSXLoadBIOS()'s main BIOS, which the machine cannot function without at all).
Procedure.l MSXLoadDiskROM()
  Protected FileNum.i = ReadFile(#PB_Any, "roms/DISK.ROM")
  If FileNum = 0
    LogGeneral("MSXLoadDiskROM: roms/DISK.ROM not found - disk drive not available this session")
    ProcedureReturn 0
  EndIf

  Protected Length.q = Lof(FileNum)
  If Length > $4000
    Length = $4000
  EndIf

  If Not *BIOSDiskData
    *BIOSDiskData = AllocateMemory($4000)
  EndIf
  FillMemory(*BIOSDiskData, $4000, $00)
  ReadData(FileNum, *BIOSDiskData, Length)
  CloseFile(FileNum)

  ; Map DiskROM to Slot 3-1 pages 2, 3 (each 8KB, total 16KB) - the SECOND half of the same subslot
  ; ExtBIOS occupies pages 0-1 of (see MSXLoadExtBIOS() above).
  *MemMap(3, 1, 2) = *BIOSDiskData
  *MemMap(3, 1, 3) = *BIOSDiskData + $2000

  Protected I.l
  For I = 0 To 3
    If PSL(I) = 3 And SSL(I) = 1
      *RAM(I * 2)     = *MemMap(3, 1, I * 2)
      *RAM(I * 2 + 1) = *MemMap(3, 1, I * 2 + 1)
    EndIf
  Next I

  LogGeneral("MSXLoadDiskROM: DISK.ROM loaded (" + Str(Length) + " bytes) into Slot 3-1 pages 2-3")
  ProcedureReturn 1
EndProcedure

; Patch the cassette I/O BIOS entry points with "ED FE C9" (undefined opcode $ED $FE, which
; Z80_CodesED.pbi routes to PatchZ80(), followed by RET) - exact same addresses and mechanism
; as real fMSX (fMSX/fMSX/MSX.c: BIOSPatches[], ResetMSX()). Without this, calling these BIOS
; routines runs the REAL Z80 cassette-port bit-banging code, which fossauro has no cassette
; hardware to answer - the call would hang/misbehave instead of cleanly failing "no tape".
; DiskPatches (fMSX/fMSX/MSX.c) is NOT replicated here: real fMSX only needs them for its
; "-simbdos" simplified BDOS-trap disk mode, which this project deliberately does not use (see
; FDC.pbi) - fossauro's DISK.ROM talks to a real emulated WD1793 instead, no BIOS patch needed.
Procedure ApplyBIOSPatches()
  Protected Dim patchAddr.u(6)
  patchAddr(0) = $00E1 : patchAddr(1) = $00E4 : patchAddr(2) = $00E7 : patchAddr(3) = $00EA
  patchAddr(4) = $00ED : patchAddr(5) = $00F0 : patchAddr(6) = $00F3
  Protected I.l
  For I = 0 To 6
    PokeA(*BIOSData + patchAddr(I), $ED)
    PokeA(*BIOSData + patchAddr(I) + 1, $FE)
    PokeA(*BIOSData + patchAddr(I) + 2, $C9)
  Next I
  LogGeneral("ApplyBIOSPatches: patched 7 cassette BIOS entry points with ED FE C9")
EndProcedure

; Load the model-appropriate BIOS (MSX1/MSX2/MSX2+, per the Mode global's #MSX_MODEL bits)
; and apply the cassette BIOS patches - the actual boot entry point RunEmulator() should call,
; replacing the old hardcoded MSXLoadBIOS("roms/MSX.ROM") call. Also safe to call again on an
; already-running machine (Hardware->Model menu, live switching) - MSX1 has no extended BIOS,
; so switching TO it explicitly clears Slot 3-1 back to *EmptyRAM instead of leaving a stale
; MSX2/MSX2+ extended BIOS mapped there from a previous model selection.
Procedure.l MSXLoadBIOSForModel()
  Protected ok.l = 0
  Select Mode & #MSX_MODEL
    Case #MSX_MSX2
      ok = MSXLoadBIOS("roms/MSX2.ROM")
      If ok : MSXLoadExtBIOS("roms/MSX2EXT.ROM") : EndIf
    Case #MSX_MSX2P
      ok = MSXLoadBIOS("roms/MSX2P.ROM")
      If ok : MSXLoadExtBIOS("roms/MSX2PEXT.ROM") : EndIf
    Default ; #MSX_MSX1
      ok = MSXLoadBIOS("roms/MSX.ROM")
      If ok
        *MemMap(3, 1, 0) = *EmptyRAM
        *MemMap(3, 1, 1) = *EmptyRAM
        Protected I.l
        For I = 0 To 3
          If PSL(I) = 3 And SSL(I) = 1
            *RAM(I * 2)     = *MemMap(3, 1, I * 2)
            *RAM(I * 2 + 1) = *MemMap(3, 1, I * 2 + 1)
          EndIf
        Next I
      EndIf
  EndSelect
  If ok
    ApplyBIOSPatches()
    ; MSXLoadDiskROM() is NOT called here yet - real regression found 2026-08-18 (docs/SPEC.md
    ; module 32p): mapping DISK.ROM to Slot 3-1 pages 2-3 causes MSX2/2+ boot to hang (disk
    ; mounted) or corrupt BASIC's memory-size detection ("Out of memory in 0", no disk mounted -
    ; so this isn't specific to FDC command handling, since that case never issues a single FDC
    ; command). FDC.pbi's WD1793 register emulation itself is implemented and verified correct in
    ; isolation (fdc_verify.pb: 4/4 tests pass, byte-exact against a real disk image) - the bug is
    ; in the MEMORY PLACEMENT of DISK.ROM, not the FDC logic. Root cause not yet isolated - do NOT
    ; re-enable this call until it's understood, since it currently breaks the default boot path.
  EndIf
  ProcedureReturn ok
EndProcedure

; Native handler for the "ED FE C9" cassette BIOS traps (see ApplyBIOSPatches()) - called via
; Z80_CodesED.pbi's Case $FE. Mirrors real fMSX's Patch.c PatchZ80() behavior for the
; "no cassette mounted" case (fossauro has no .cas tape file support yet - see docs/SPEC.md
; module 32c); TAPION/TAPIN/TAPOON/TAPOUT fail (CARRY set), TAPIOF/TAPOOF/STMOTR succeed as
; no-ops (CARRY clear) - exactly what real fMSX does when its CasStream is NULL.
Procedure MSXPatchZ80(*R.Z80)
  Protected patchPC.u = (*R\PC\W - 2) & $FFFF
  Select patchPC
    Case $00E1 ; TAPION
      *R\AF\B\l = *R\AF\B\l | #C_FLAG
    Case $00E4 ; TAPIN
      *R\AF\B\l = *R\AF\B\l | #C_FLAG
    Case $00E7 ; TAPIOF
      *R\AF\B\l = *R\AF\B\l & ~#C_FLAG
    Case $00EA ; TAPOON
      *R\AF\B\l = *R\AF\B\l | #C_FLAG
    Case $00ED ; TAPOUT
      *R\AF\B\l = *R\AF\B\l | #C_FLAG
    Case $00F0 ; TAPOOF
      *R\AF\B\l = *R\AF\B\l & ~#C_FLAG
    Case $00F3 ; STMOTR
      *R\AF\B\l = *R\AF\B\l & ~#C_FLAG
    Default
      LogGeneral("MSXPatchZ80: unknown BIOS trap called at PC=$" + Hex(patchPC))
  EndSelect
EndProcedure

; Gated by Verbose and keeps the file open across calls (see LogFileHandle above) -
; PSlot/SSlot/MSXRdZ80 call this dozens-hundreds of times during a real BIOS cartridge
; scan; Open+Write+Close per call was the actual bottleneck, not emulation logic.
Procedure LogMsg(Msg.s)
  If Not Verbose
    ProcedureReturn
  EndIf
  If Not LogFileHandle
    LogFileHandle = OpenFile(#PB_Any, "fossauro.log", #PB_File_Append)
    If Not LogFileHandle
      ProcedureReturn
    EndIf
  EndIf
  WriteStringN(LogFileHandle, FormatDate("[%YYYY-%MM-%DD %HH:%II:%SS] ", Date()) + Msg)
  If Lof(LogFileHandle) >= #LogMaxBytes
    RotateLog()
  EndIf
EndProcedure

; Linux logrotate-style roll: fossauro.log -> fossauro.log.1 -> fossauro.log.2 -> ...,
; oldest generation (#LogMaxBackups) dropped. Called from LogMsg() once the current file
; crosses #LogMaxBytes. The next LogMsg() call transparently reopens a fresh empty
; fossauro.log (LogFileHandle is left at 0 here on purpose).
Procedure RotateLog()
  If LogFileHandle
    CloseFile(LogFileHandle)
    LogFileHandle = 0
  EndIf

  Protected OldestPath.s = "fossauro.log." + Str(#LogMaxBackups)
  If FileSize(OldestPath) >= 0
    DeleteFile(OldestPath)
  EndIf

  Protected i.i
  For i = #LogMaxBackups - 1 To 1 Step -1
    Protected Src.s = "fossauro.log." + Str(i)
    Protected Dst.s = "fossauro.log." + Str(i + 1)
    If FileSize(Src) >= 0
      RenameFile(Src, Dst)
    EndIf
  Next i

  If FileSize("fossauro.log") >= 0
    RenameFile("fossauro.log", "fossauro.log.1")
  EndIf
EndProcedure

; Per-category log wrappers - thin gate + tag around LogMsg(). Flip bits in
; LogCategories (see #LogCat_* above) to silence/enable a category without touching
; call sites or the underlying file/rotation plumbing.
Procedure LogGeneral(Msg.s)
  If LogCategories & #LogCat_General : LogMsg("[GEN] " + Msg) : EndIf
EndProcedure

Procedure LogMemory(Msg.s)
  If LogCategories & #LogCat_Memory : LogMsg("[MEM] " + Msg) : EndIf
EndProcedure

Procedure LogVDP(Msg.s)
  If LogCategories & #LogCat_VDP : LogMsg("[VDP] " + Msg) : EndIf
EndProcedure

Procedure LogPSG(Msg.s)
  If LogCategories & #LogCat_PSG : LogMsg("[PSG] " + Msg) : EndIf
EndProcedure

Procedure LogCPU(Msg.s)
  If LogCategories & #LogCat_CPU : LogMsg("[CPU] " + Msg) : EndIf
EndProcedure

; Flush and release the persistent log handle - call once at shutdown.
Procedure CloseLogFile()
  If LogFileHandle
    CloseFile(LogFileHandle)
    LogFileHandle = 0
  EndIf
EndProcedure

; Switch primary memory slots (Port $A8 write)
Procedure PSlot(V.a)
  Protected J.a, I.a
  
  If PSLReg <> V
    LogMemory("PSlot change: $" + Hex(PSLReg) + " -> $" + Hex(V) + " [lastRd=$" + Hex(LastRdAddr) + " lastWr=$" + Hex(LastWrAddr) + "]")
    PSLReg = V
    For J = 0 To 3
      I = J << 1
      PSL(J) = (V >> I) & 3
      SSL(J) = (SSLReg(PSL(J)) >> I) & 3
      *RAM(I)   = *MemMap(PSL(J), SSL(J), I)
      *RAM(I+1) = *MemMap(PSL(J), SSL(J), I+1)
      
      If PSL(J) = 3 And SSL(J) = 2 And *MemMap(3, 2, I) <> *EmptyRAM
        EnWrite(J) = 1
      Else
        EnWrite(J) = 0
      EndIf
    Next J
  EndIf
EndProcedure

; Switch secondary memory slots (Memory address $FFFF write)
Procedure SSlot(V.a)
  Protected J.a, I.a, logFile.i
  
  ; Cartridge slots do not have subslots, fix them at 0:0:0:0
  If PSL(3) = 1 Or PSL(3) = 2
    V = $00
  EndIf
  
  ; In MSX1, slot 0 does not have subslots
  If PSL(3) = 0 And (Mode & #MSX_MODEL) = #MSX_MSX1
    V = $00
  EndIf
  
  If SSLReg(PSL(3)) <> V
    LogMemory("SSlot change on Primary Slot " + Str(PSL(3)) + ": $" + Hex(SSLReg(PSL(3))) + " -> $" + Hex(V) + " [lastRd=$" + Hex(LastRdAddr) + " lastWr=$" + Hex(LastWrAddr) + " PC=$" + Hex(CPU\PC\W) + " A=$" + Hex(CPU\AF\B\h) + " HL=$" + Hex(CPU\HL\W) + " BC=$" + Hex(CPU\BC\W) + " PSLReg=$" + Hex(PSLReg) + "]")
    SSLReg(PSL(3)) = V
    For J = 0 To 3
      If PSL(J) = PSL(3)
        I = J << 1
        SSL(J) = (V >> I) & 3
        *RAM(I)   = *MemMap(PSL(J), SSL(J), I)
        *RAM(I+1) = *MemMap(PSL(J), SSL(J), I+1)
        
        If PSL(J) = 3 And SSL(J) = 2 And *MemMap(3, 2, I) <> *EmptyRAM
          EnWrite(J) = 1
        Else
          EnWrite(J) = 0
        EndIf
      EndIf
    Next J
  EndIf
EndProcedure

; Memory reading callback
Procedure.a MSXRdZ80(A.u)
  Protected V.a
  Protected *PagePtr
  ; Filter out everything but [xx11 1111 1xxx 1xxx] for FDC/special registers
  If (A & $3F88) <> $3F88
    *PagePtr = *RAM(A >> 13)
    If *PagePtr = 0
      LogMemory("CRITICAL: MSXRdZ80 null page pointer! A=$" + Hex(A) + " Page8K=" + Str(A >> 13) +
             " PSLReg=$" + Hex(PSLReg) + " PSL(0..3)=" + Str(PSL(0)) + "," + Str(PSL(1)) + "," + Str(PSL(2)) + "," + Str(PSL(3)) +
             " SSL(0..3)=" + Str(SSL(0)) + "," + Str(SSL(1)) + "," + Str(SSL(2)) + "," + Str(SSL(3)))
      ProcedureReturn $FF
    EndIf
    V = PeekA(*PagePtr + (A & $1FFF))
    LastRdAddr = A
    ProcedureReturn V
  EndIf

  ; Secondary slot selector at $FFFF
  If A = $FFFF
    ProcedureReturn ~SSLReg(PSL(3))
  EndIf

  ; Floppy disk controller registers - CPU page 1 ($4000-$7FFF) is where Slot 3-1 lands when
  ; selected (see MSXLoadDiskROM()), so PSL(1)/SSL(1) (not PSL(3)) is the right gate here even
  ; though the slot itself is numbered 3 - confirmed against DISK.ROM's own access pattern (FDC.pbi
  ; header comment has the full port map derivation).
  If PSL(1) = 3 And SSL(1) = 1
    ProcedureReturn FDC_ReadReg(A)
  EndIf

  *PagePtr = *RAM(A >> 13)
  If *PagePtr = 0
    LogMemory("CRITICAL: MSXRdZ80(FDC path) null page pointer! A=$" + Hex(A) + " Page8K=" + Str(A >> 13))
    ProcedureReturn $FF
  EndIf
  V = PeekA(*PagePtr + (A & $1FFF))
  LastRdAddr = A
  ProcedureReturn V
EndProcedure

; Auto-detect a MegaROM's bank-switch mapper type by scanning its content for characteristic
; "LD (nnnn),A" ($32,lo,hi) bank-select writes - matches real fMSX's GuessROM() (MSX.c) content
; heuristic (the CRC/SHA1 known-ROM database part of the real function is not ported - fossauro
; ships no such database - only the byte-scanning heuristic, which is the fallback path anyway).
Procedure.a GuessROMType(*Data, Length.l)
  Protected Dim ROMCount.l(7)
  Protected i.l
  For i = 0 To 7 : ROMCount(i) = 1 : Next i
  ROMCount(#MAP_GEN8) + 1
  ROMCount(#MAP_ASCII8) - 1

  Protected addr.l, target.l
  For addr = 0 To Length - 3
    If PeekA(*Data + addr) = $32
      target = PeekA(*Data + addr + 1) | (PeekA(*Data + addr + 2) << 8)
      Select target
        Case $5000, $9000, $B000
          ROMCount(#MAP_KONAMI5) + 1
        Case $4000, $8000, $A000
          ROMCount(#MAP_KONAMI4) + 1
        Case $6800, $7800
          ROMCount(#MAP_ASCII8) + 1
        Case $6000
          ROMCount(#MAP_KONAMI4) + 1
          ROMCount(#MAP_ASCII8) + 1
          ROMCount(#MAP_ASCII16) + 1
        Case $7000
          ROMCount(#MAP_KONAMI5) + 1
          ROMCount(#MAP_ASCII8) + 1
          ROMCount(#MAP_ASCII16) + 1
        Case $77FF
          ROMCount(#MAP_ASCII16) + 1
      EndSelect
    EndIf
  Next addr

  Protected best.a = #MAP_GEN8, bestCount.l = ROMCount(#MAP_GEN8)
  For i = 1 To 7
    If ROMCount(i) > bestCount
      bestCount = ROMCount(i)
      best = i
    EndIf
  Next i
  ProcedureReturn best
EndProcedure

Procedure.s ROMTypeName(T.a)
  Select T
    Case #MAP_GEN8     : ProcedureReturn "Generic/8kB"
    Case #MAP_GEN16    : ProcedureReturn "Generic/16kB"
    Case #MAP_KONAMI5  : ProcedureReturn "Konami5000h/SCC"
    Case #MAP_KONAMI4  : ProcedureReturn "Konami4000h"
    Case #MAP_ASCII8   : ProcedureReturn "ASCII8kB"
    Case #MAP_ASCII16  : ProcedureReturn "ASCII16kB"
    Case #MAP_GMASTER2 : ProcedureReturn "GameMaster2"
    Case #MAP_FMPAC    : ProcedureReturn "FMPAC"
    Default             : ProcedureReturn "Unknown"
  EndSelect
EndProcedure

; Re-derive the live *RAM()/EnWrite() cache for one 8KB CPU half-page (Win 0-3, i.e. *MemMap
; index Win+2) if that primary slot's page is currently actually selected - same pattern as
; PSlot()/SSlot()/the RAM-mapper port write handler elsewhere in this file. Cartridge slots
; never have subslots (SSlot() already enforces SSL=0 for them), so only PSL/SSL=0 need checking.
Procedure RefreshMegaROMPage(PrimarySlot.l, Win.l)
  Protected J.l = (Win + 2) >> 1        ; which of the 4 CPU quarter-pages (0-3) this 8KB half belongs to
  Protected sub.l = (Win + 2) & 1       ; 0 = low 8KB half, 1 = high 8KB half of that quarter-page
  If PSL(J) = PrimarySlot And SSL(J) = 0
    *RAM(J * 2 + sub) = *MemMap(PrimarySlot, 0, Win + 2)
    EnWrite(J) = 0 ; cartridge ROM windows are never plain-writable RAM, even when SRAM-backed
                    ; (SRAM writes go through MapROM() below, not the generic EnWrite() path)
  EndIf
EndProcedure

; Allocate a slot's SRAM buffer on first use (ASCII8/ASCII16/GameMaster2/FMPAC only).
Procedure EnsureSRAM(SlotIdx.l, Size.l)
  If Not *SRAMData(SlotIdx)
    *SRAMData(SlotIdx) = AllocateMemory(Size)
    FillMemory(*SRAMData(SlotIdx), Size, $FF)
  EndIf
EndProcedure

; Preset a MegaROM's initial bank state at load time - matches real fMSX's SetMegaROM() (MSX.c),
; always in 8KB-page units regardless of the mapper's native bank granularity.
Procedure ApplyMegaROMPage(SlotIdx.l, PrimarySlot.l, Win.l, Page.a)
  Page = Page & ROMMask(SlotIdx)
  ROMMapper(SlotIdx, Win) = Page
  *MemMap(PrimarySlot, 0, Win + 2) = *ROMData(SlotIdx) + (Page << 13)
  RefreshMegaROMPage(PrimarySlot, Win)
EndProcedure

; MegaROM bank-switch write trap - matches real fMSX's MapROM() (MSX.c) for every mapper type
; except the SCC (Konami5)/OPLL (FMPAC) sound-chip registers, which aren't ported since fossauro
; doesn't emulate those chips - ROM/SRAM banking itself works identically without them (see
; docs/SPEC.md for the per-mapper address/semantics table this was ported from).
Procedure MapROM(A.u, V.a)
  Protected J.l = A >> 14
  Protected SlotIdx.l, PrimarySlot.l = PSL(J)
  If PrimarySlot = 1
    SlotIdx = 0
  ElseIf PrimarySlot = 2
    SlotIdx = 1
  Else
    ProcedureReturn ; no cartridge mapped to this CPU page
  EndIf

  If ROMMask(SlotIdx) = 0 : ProcedureReturn : EndIf ; plain ROM, not a MegaROM - nothing to switch

  Protected mask.a = ROMMask(SlotIdx)
  Protected Win.l, sramBit.a, page.a

  Select ROMType(SlotIdx)
    Case #MAP_GEN8
      If A >= $4000 And A < $C000
        Win = (A - $4000) >> 13
        ApplyMegaROMPage(SlotIdx, PrimarySlot, Win, V & mask)
      EndIf

    Case #MAP_GEN16
      If A >= $4000 And A < $C000
        Win = (A & $8000) >> 14 ; 0 (for $4000-$7FFF) or 2 (for $8000-$BFFF)
        page = (V << 1) & mask
        ApplyMegaROMPage(SlotIdx, PrimarySlot, Win, page)
        ApplyMegaROMPage(SlotIdx, PrimarySlot, Win + 1, page | 1)
      EndIf

    Case #MAP_KONAMI5 ; SCC - sound chip registers ($9800-$99FF etc.) not implemented
      If (A = $5000 Or A = $7000 Or A = $9000 Or A = $B000)
        Win = (A - $5000) >> 13
        ApplyMegaROMPage(SlotIdx, PrimarySlot, Win, V & mask)
      EndIf

    Case #MAP_KONAMI4 ; plain Konami, no SCC - $4000 window is fixed, never switched
      If (A = $6000 Or A = $8000 Or A = $A000)
        Win = (A - $4000) >> 13
        ApplyMegaROMPage(SlotIdx, PrimarySlot, Win, V & mask)
      EndIf

    Case #MAP_ASCII8
      sramBit = mask + 1
      If A >= $6000 And A < $8000
        Win = (A >> 11) & 3
        If V & sramBit
          EnsureSRAM(SlotIdx, $2000)
          ROMMapper(SlotIdx, Win) = $FF
          *MemMap(PrimarySlot, 0, Win + 2) = *SRAMData(SlotIdx)
          RefreshMegaROMPage(PrimarySlot, Win)
        Else
          ApplyMegaROMPage(SlotIdx, PrimarySlot, Win, V & mask)
        EndIf
      ElseIf A >= $8000 And A < $C000
        Win = (A - $4000) >> 13
        If ROMMapper(SlotIdx, Win) = $FF
          PokeA(*SRAMData(SlotIdx) + (A & $1FFF), V)
        EndIf
      EndIf

    Case #MAP_ASCII16
      sramBit = mask + 1
      If A >= $6000 And A < $8000 And (V <= mask + 1 Or (A & $0FFF) = 0)
        ; Guard against garbage writes some real carts make into $7xxx - only honored if V is a
        ; plausible page/SRAM-select number, or the address is exactly $6000/$7000-aligned
        ; (matches real fMSX's Vauxall/Darwin/Androgynus compatibility comments, MSX.c).
        Win = (A & $1000) >> 11 ; 0 (for $6000) or 2 (for $7000)
        If V & sramBit
          EnsureSRAM(SlotIdx, $800)
          ROMMapper(SlotIdx, Win) = $FF
          ROMMapper(SlotIdx, Win + 1) = $FF
          *MemMap(PrimarySlot, 0, Win + 2) = *SRAMData(SlotIdx)
          *MemMap(PrimarySlot, 0, Win + 3) = *SRAMData(SlotIdx)
          RefreshMegaROMPage(PrimarySlot, Win)
          RefreshMegaROMPage(PrimarySlot, Win + 1)
        Else
          page = (V << 1) & mask
          ApplyMegaROMPage(SlotIdx, PrimarySlot, Win, page)
          ApplyMegaROMPage(SlotIdx, PrimarySlot, Win + 1, page | 1)
        EndIf
      ElseIf A >= $8000 And A < $C000
        Win = (A - $4000) >> 13
        If ROMMapper(SlotIdx, Win) = $FF
          ; 2kB SRAM chip mirrored 8x across the 16kB window - matches real fMSX (MSX.c).
          PokeA(*SRAMData(SlotIdx) + (A & $07FF), V)
        EndIf
      EndIf

    Case #MAP_GMASTER2
      If (A = $6000 Or A = $8000 Or A = $A000)
        Win = (A - $4000) >> 13
        If V & $10
          EnsureSRAM(SlotIdx, $2000)
          ROMMapper(SlotIdx, Win) = $FF
          *MemMap(PrimarySlot, 0, Win + 2) = *SRAMData(SlotIdx) + Bool(V & $20) * $1000
          RefreshMegaROMPage(PrimarySlot, Win)
        Else
          ApplyMegaROMPage(SlotIdx, PrimarySlot, Win, V & mask)
        EndIf
      ElseIf A >= $B000 And A < $C000
        Win = 3
        If ROMMapper(SlotIdx, Win) = $FF
          PokeA(*SRAMData(SlotIdx) + (A & $0FFF), V)
        EndIf
      EndIf

    Case #MAP_FMPAC ; OPLL/FM sound register ($7FF6) not implemented - ROM/SRAM banking only
      Select A
        Case $5FFE
          FMPACKey(SlotIdx) = (FMPACKey(SlotIdx) & $FF00) | V
        Case $5FFF
          FMPACKey(SlotIdx) = (FMPACKey(SlotIdx) & $00FF) | (V << 8)
          If FMPACKey(SlotIdx) = $694D ; FMPAC_MAGIC - unlock sequence complete
            EnsureSRAM(SlotIdx, $2000)
            ROMMapper(SlotIdx, 0) = $FF
            ROMMapper(SlotIdx, 1) = $FF
            *MemMap(PrimarySlot, 0, 2) = *SRAMData(SlotIdx)
            *MemMap(PrimarySlot, 0, 3) = *SRAMData(SlotIdx) + $2000
            RefreshMegaROMPage(PrimarySlot, 0)
            RefreshMegaROMPage(PrimarySlot, 1)
          EndIf
        Case $7FF7
          page = (V << 1) & mask
          ApplyMegaROMPage(SlotIdx, PrimarySlot, 0, page)
          ApplyMegaROMPage(SlotIdx, PrimarySlot, 1, page | 1)
          FMPACKey(SlotIdx) = 0 ; any ROM-page select re-locks SRAM, matches real fMSX
      EndSelect
      If A >= $4000 And A < $5FFE And ROMMapper(SlotIdx, 0) = $FF
        PokeA(*SRAMData(SlotIdx) + (A & $1FFF), V)
      EndIf
  EndSelect
EndProcedure

; Memory writing callback
Procedure MSXWrZ80(A.u, V.a)
  If Not RealRdZ80
    LogMemory("CRITICAL: RdZ80 pointer went NULL! Caught in MSXWrZ80 A=$" + Hex(A) + " V=$" + Hex(V) +
           " lastRd=$" + Hex(LastRdAddr) + " lastWr=$" + Hex(LastWrAddr) + " RealRdZ80=$" + Hex(RealRdZ80))
    End
  EndIf
  LastWrAddr = A

  ; Secondary slot selector at $FFFF
  If A = $FFFF
    SSlot(V)
    ProcedureReturn
  EndIf

  ; Floppy disk controller registers - see the matching check in MSXRdZ80 above for why PSL(1)/
  ; SSL(1) is correct here (CPU page 1, not "slot 3" itself). Needs the address mask too (unlike
  ; the read side, nothing upstream has already filtered this down to the $7FF8-$7FFF range).
  If (A & $3F88) = $3F88 And PSL(1) = 3 And SSL(1) = 1
    FDC_WriteReg(A, V)
    ProcedureReturn
  EndIf

  ; Write to RAM if enabled
  If EnWrite(A >> 14)
    Protected *WPagePtr = *RAM(A >> 13)
    If *WPagePtr = 0
      LogMemory("CRITICAL: MSXWrZ80 null page pointer! A=$" + Hex(A) + " V=$" + Hex(V) + " Page8K=" + Str(A >> 13))
      ProcedureReturn
    EndIf
    PokeA(*WPagePtr + (A & $1FFF), V)
    ProcedureReturn
  EndIf

  If A >= $4000 And A < $C000
    MapROM(A, V)
  EndIf
EndProcedure

; Input port reading callback
Procedure.a MSXInZ80(Port.u)
  Port = Port & $FF
  Select Port
    Case $98, $99, $9A, $9B
      ProcedureReturn MSXReadVDP(Port)
      
    Case $A0, $A1, $A2
      If Port = $A2
        Protected reg_idx.a = PSG\Latch
        If reg_idx = 14
          ProcedureReturn $7F ; Joystick/mouse idle state
        ElseIf reg_idx = 15
          ProcedureReturn PSG\R[15] & $F0
        Else
          ProcedureReturn PSG\R[reg_idx]
        EndIf
      Else
        ProcedureReturn $FF
      EndIf
      
    Case $A8, $A9, $AA, $AB
      ; Before reading PPI, update register C input (KeyMatrix row selected by Port C output lower nibble)
      Protected row.a = PPI\Rout[2] & $0F
      PPI\Rin[1] = KeyMatrix(row)
      ProcedureReturn Read8255(@PPI, Port - $A8)

    Case $B5 ; RTC data (MSX2/2+ only, but harmless to expose on any model)
      ProcedureReturn RTCIn(RTCReg)

    Case $FC, $FD, $FE, $FF ; RAM mapper page select ($FC=page@0000h ... $FF=page@C000h)
      ; Unimplemented high bits read back as 1, matching real mapper hardware (MSX.c: InZ80()).
      ProcedureReturn RAMMapper(Port - $FC) | ~RAMMask

    Default:
      ProcedureReturn $FF
  EndSelect
EndProcedure

; Output port writing callback
Procedure MSXOutZ80(Port.u, V.a)
  Port = Port & $FF
  Select Port
    Case $98, $99, $9A, $9B
      MSXWriteVDP(Port, V)
      
    Case $A0
      PSG\Latch = V & $0F
    Case $A1
      ; Real AY-3-8910 masks unused bits at write time (Write8910() in AY8910.c), so a
      ; register readback (port $A2) reflects the masked value, not whatever garbage the
      ; program wrote to the unused high bits. PSG_Render()/MSXInZ80() already mask these
      ; registers again at use time, so this had no audible effect - only readback fidelity.
      Protected out_reg.a = PSG\Latch
      Select out_reg
        Case 1, 3, 5, 13
          V = V & $0F
        Case 6, 8, 9, 10
          V = V & $1F
      EndSelect
      PSG\R[out_reg] = V
      If out_reg = 13
        ResetPSGEnvelope()
      EndIf
      
    Case $A8, $A9, $AA, $AB
      Protected oldRout0.a = PPI\Rout[0]
      Protected oldRout2.a = PPI\Rout[2]
      
      Write8255(@PPI, Port - $A8, V)
      
      ; If primary slot state has changed...
      If PPI\Rout[0] <> oldRout0
        PSlot(PPI\Rout[0])
      EndIf
      
      ; If I/O control register has changed...
      If PPI\Rout[2] <> oldRout2
        ; Drum/sound click placeholder
      EndIf

    Case $B4 ; RTC register select
      RTCReg = V & $0F
    Case $B5 ; RTC data write
      If RTCReg < 13
        RTC(RTCMode & $03, RTCReg) = V
      ElseIf RTCReg = 13
        RTCMode = V
      EndIf

    Case $FC, $FD, $FE, $FF ; RAM mapper page select - matches real fMSX (MSX.c: OutZ80())
      Protected mapperJ.a = Port - $FC
      V = V & RAMMask
      If RAMMapper(mapperJ) <> V
        Protected mapperI.a = mapperJ << 1
        RAMMapper(mapperJ) = V
        *MemMap(3, 2, mapperI)     = *RAMData + (V << 14)
        *MemMap(3, 2, mapperI + 1) = *MemMap(3, 2, mapperI) + $2000
        ; Only refresh the live *RAM()/EnWrite() pointers if this CPU page is currently
        ; actually viewing Slot 3-2 - otherwise just update MemMap(3,2,...) for whenever
        ; PSlot()/SSlot() next selects that mapping (same as real fMSX's OutZ80()).
        If PSL(mapperJ) = 3 And SSL(mapperJ) = 2
          EnWrite(mapperJ) = 1
          *RAM(mapperI)     = *MemMap(3, 2, mapperI)
          *RAM(mapperI + 1) = *MemMap(3, 2, mapperI + 1)
        EndIf
      EndIf
  EndSelect
EndProcedure

; Set key pressed (active low)
Procedure MSXKeyPress(K.a)
  If K <= 129
    KeyMatrix(KeysRow(K)) = KeyMatrix(KeysRow(K)) & ~KeysMask(K)
  EndIf
EndProcedure

; Set key released (active low)
Procedure MSXKeyRelease(K.a)
  If K <= 129
    KeyMatrix(KeysRow(K)) = KeyMatrix(KeysRow(K)) | KeysMask(K)
  EndIf
EndProcedure

Procedure ResetKeyboard()
  Protected I.l
  For I = 0 To 15
    KeyMatrix(I) = $FF
  Next I
EndProcedure

DataSection
  KeyboardData:
  ; Row, Mask pairs for Keys[130][2]
  Data.b 0,$00, 8,$10, 8,$20, 8,$80 ; None,LEFT,UP,RIGHT
  Data.b 8,$40, 6,$01, 6,$02, 6,$04 ; DOWN,SHIFT,CONTROL,GRAPH
  Data.b 7,$20, 7,$08, 6,$08, 7,$40 ; BS,TAB,CAPSLOCK,SELECT
  Data.b 8,$02, 7,$80, 8,$08, 8,$04 ; HOME,ENTER,DELETE,INSERT
  Data.b 6,$10, 7,$10, 6,$20, 6,$40 ; COUNTRY,STOP,F1,F2
  Data.b 6,$80, 7,$01, 7,$02, 9,$08 ; F3,F4,F5,PAD0
  Data.b 9,$10, 9,$20, 9,$40, 7,$04 ; PAD1,PAD2,PAD3,ESCAPE
  Data.b 9,$80, 10,$01, 10,$02, 10,$04 ; PAD4,PAD5,PAD6,PAD7
  Data.b 8,$01, 0,$02, 2,$01, 0,$08 ; SPACE,[!],["],[#]
  Data.b 0,$10, 0,$20, 0,$80, 2,$01 ; [$],[%],[&],[']
  Data.b 1,$02, 0,$01, 1,$01, 1,$08 ; [(],[)],[*],[=]
  Data.b 2,$04, 1,$04, 2,$08, 2,$10 ; [,],[-],[.],[/]
  Data.b 0,$01, 0,$02, 0,$04, 0,$08 ; 0,1,2,3
  Data.b 0,$10, 0,$20, 0,$40, 0,$80 ; 4,5,6,7
  Data.b 1,$01, 1,$02, 1,$80, 1,$80 ; 8,9,[:],[;]
  Data.b 2,$04, 1,$08, 2,$08, 2,$10 ; [<],[=],[>],[?]
  Data.b 0,$04, 2,$40, 2,$80, 3,$01 ; [@],A,B,C
  Data.b 3,$02, 3,$04, 3,$08, 3,$10 ; D,E,F,G
  Data.b 3,$20, 3,$40, 3,$80, 4,$01 ; H,I,J,K
  Data.b 4,$02, 4,$04, 4,$08, 4,$10 ; L,M,N,O
  Data.b 4,$20, 4,$40, 4,$80, 5,$01 ; P,Q,R,S
  Data.b 5,$02, 5,$04, 5,$08, 5,$10 ; T,U,V,W
  Data.b 5,$20, 5,$40, 5,$80, 1,$20 ; X,Y,Z,[[]
  Data.b 1,$10, 1,$40, 0,$40, 1,$04 ; [\],[]],[^],[_]
  Data.b 2,$02, 2,$40, 2,$80, 3,$01 ; [`],a,b,c
  Data.b 3,$02, 3,$04, 3,$08, 3,$10 ; d,e,f,g
  Data.b 3,$20, 3,$40, 3,$80, 4,$01 ; h,i,j,k
  Data.b 4,$02, 4,$04, 4,$08, 4,$10 ; l,m,n,o
  Data.b 4,$20, 4,$40, 4,$80, 5,$01 ; p,q,r,s
  Data.b 5,$02, 5,$04, 5,$08, 5,$10 ; t,u,v,w
  Data.b 5,$20, 5,$40, 5,$80, 1,$20 ; x,y,z,[{]
  Data.b 1,$10, 1,$40, 2,$02, 8,$08 ; [|],[}],[~],DEL
  Data.b 10,$08, 10,$10             ; PAD8,PAD9
EndDataSection

; Set or reset an interrupt request
Procedure.u SetIRQ(IRQ.a)
  If IRQ & $80
    IRQPending = IRQPending & IRQ
  Else
    IRQPending = IRQPending | IRQ
  EndIf

  If IRQPending
    CPU\IRequest = #INT_IRQ
  Else
    CPU\IRequest = #INT_NONE
  EndIf

  ProcedureReturn CPU\IRequest
EndProcedure

; MSX main execution timer loop callback (called at each interrupt cycle)
Procedure.u MSXLoopZ80(*R.Z80)
  If ThreadExit
    ProcedureReturn #INT_QUIT
  EndIf
  While ThreadPaused
    Delay(10)
    If ThreadExit
      ProcedureReturn #INT_QUIT
    EndIf
  Wend
  Static BFlag.a = 0
  Static BCount.a = 0
  Static UCount.l = 0
  Static ACount.a = 0
  Static Drawing.a = 0
  Static FrameCounter.l = 0
  Protected J.l, displayEndLine.l

  ; Flip HRefresh status bit (VDPStatus[2] bit 5)
  VDPStatus(2) = VDPStatus(2) ! $20
  
  ; Active drawing phase of scanline
  If (VDPStatus(2) & $20) = 0
    If ScrMode = 0
      *R\IPeriod = #CPU_H240
    Else
      *R\IPeriod = #CPU_H256
    EndIf
    
    Protected palVideo.a = 0
    If (Mode & #MSX_PAL) : palVideo = 1 : EndIf
    
    Protected maxLine.l = 261
    If palVideo : maxLine = 312 : EndIf
    
    If ScanLine < maxLine
      ScanLine + 1
    Else
      ScanLine = 0
    EndIf
    
    displayEndLine = 192
    If VDP(9) & $80 : displayEndLine = 212 : EndIf
    
    If ScanLine = 0
      Drawing = 1
      VDPStatus(2) = VDPStatus(2) & $BF ; Clear VRefresh status bit
      UCount + UPeriod
    EndIf
    
    If Drawing And ScanLine < displayEndLine
      RefreshLine(ScanLine)
    EndIf
    
    Protected coinLine.l = 235
    If palVideo
      coinLine = 256
    ElseIf VDP(9) & $80
      coinLine = 245
    EndIf
    
    If ScanLine = coinLine
      VDPStatus(1) = VDPStatus(1) & $FE ; Clear line coincidence flag
      SetIRQ(~#INT_IE1)
    EndIf
    
    If ScanLine < coinLine
      ; Line coincidence check (using register 19)
      J = (((ScanLine + VDP(23)) & $FF) - VDP(19)) & $FF
      If J = 2
        VDPStatus(1) = VDPStatus(1) | $01 ; Set coincidence flag
        If VDP(0) & $10
          SetIRQ(#INT_IE1)
        EndIf
      Else
        If (VDP(0) & $10) = 0
          VDPStatus(1) = VDPStatus(1) & $FE
        EndIf
      EndIf
    EndIf
    
    *R\IRequest = SetIRQ($FF)
    ProcedureReturn *R\IRequest
  EndIf
  
  ; HBlank Phase of scanline
  Protected activePeriod.l
  If ScrMode = 0
    activePeriod = #CPU_H240
  Else
    activePeriod = #CPU_H256
  EndIf
  *R\IPeriod = #CPU_HPERIOD - activePeriod
  
  displayEndLine = 192
  If VDP(9) & $80
    displayEndLine = 212
  EndIf
  If ScanLine = displayEndLine
    Drawing = 0
  EndIf
  
  Protected vblankStartLine.l = 192 + 28
  If VDP(9) & $80
    If (Mode & #MSX_PAL)
      vblankStartLine = 212 + 42
    Else
      vblankStartLine = 212 + 18
    EndIf
  Else
    If (Mode & #MSX_PAL)
      vblankStartLine = 192 + 52
    EndIf
  EndIf
  
  If Drawing = 0 And ScanLine = vblankStartLine
    VDPStatus(0) = VDPStatus(0) | $80 ; Set VBlank status bit
    VDPStatus(2) = VDPStatus(2) | $40 ; Set VRefresh status bit
    
    If VDP(1) & $20
      SetIRQ(#INT_IE0)
    EndIf
    
    FrameCounter = FrameCounter + 1
    If FrameCounter % 60 = 0 Or FrameCounter < 5
      LogCPU("FRAME=" + Str(FrameCounter) + " PC=" + Hex(*R\PC\W) + " SP=" + Hex(*R\SP\W) + " VDP(0)=" + Hex(VDP(0)) +
             " VDP(1)=" + Hex(VDP(1)) + " ScrMode=" + Str(ScrMode) + " PSLReg=" + Hex(PSLReg) + " SSLReg(3)=" + Hex(SSLReg(3)))
    EndIf

    ; Signal Main GUI Thread that frame is ready (if previous frame was processed)
    If FramePending = 0
      FramePending = 1
      PostEvent(#PB_Event_FirstCustomValue + 1)
    EndIf
    
    ; Throttle frame rate (60 fps)
    Delay(16)
  EndIf
  
  *R\IRequest = SetIRQ($FF)
  ProcedureReturn *R\IRequest
EndProcedure
