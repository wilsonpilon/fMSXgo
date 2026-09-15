; V9938 VDP Graphics Processor Emulation for fossauro
; Derived from fMSX V9938.c by Marat Fayzullin

EnableExplicit

; Globals representing the VDP state
Global *VRAM                      ; Video RAM buffer (128KB)
Global *VPAGE                     ; Active 16KB VRAM page pointer
Global VDPKey.a = 1               ; Write phase indicator
Global VDPALatch.a = 0            ; Address latch register
Global VDPAddr.u = 0              ; VRAM access address (14-bit)
Global VDPData.a = 0              ; VRAM read-ahead buffer

Global Dim VDP.a(63)              ; VDP Control Registers
Global Dim VDPStatus.a(15)        ; VDP Status Registers

Global ScrMode.a = 0              ; Screen Mode index
Global ScanLine.l = 0             ; Current rendering scanline
Global FGColor.a = 15             ; Foreground color
Global BGColor.a = 1              ; Background color

Global Dim Palette.l(15)          ; 32-bit RGBA Palette
Global PKey.a = 1                 ; Palette write sequencer
Global PLatch.a = 0               ; Palette register latch

; Core pointers to VRAM tables
Global ChrTab.i = 0
Global ChrGen.i = 0
Global ColTab.i = 0
Global SprTab.i = 0
Global SprGen.i = 0

Global ChrTabM.l = 0
Global ChrGenM.l = 0
Global ColTabM.l = 0
Global SprTabM.l = 0

; Crash diagnostic: ChrTab/ColTab/ChrGen (+ masks) are computed from VDP registers in
; SetScreen() and combined with per-mode masks (ChrTabM/ColTabM/ChrGenM) in RefreshLine() -
; if a mode/mask combination is wrong, the resulting pointer can land outside the 128KB
; *VRAM buffer, and a raw PeekA on it is a real access violation (observed: fossauro.exe
; crashes with 0xC0000005 shortly after a cartridge ROM is detected and the BIOS/game
; switches screen mode). This wrapper turns that into one logged line + a safe return
; instead of a silent crash, so the offending mode/registers can be read straight from
; fossauro.log instead of guessed at.
Global VRAMBoundsLogged.b = 0
Procedure.a SafePeekVRAM(*Addr, Context.s)
  If *Addr < *VRAM Or *Addr >= *VRAM + (VRAMPages * $4000)
    If Not VRAMBoundsLogged
      VRAMBoundsLogged = 1
      LogVDP("CRITICAL: VRAM pointer out of bounds in " + Context + " *Addr=$" + Hex(*Addr) +
             " *VRAM=$" + Hex(*VRAM) + " offset=" + Str(*Addr - *VRAM) +
             " ScrMode=" + Str(ScrMode) + " VDP(0..7)=" +
             Str(VDP(0)) + "," + Str(VDP(1)) + "," + Str(VDP(2)) + "," + Str(VDP(3)) + "," +
             Str(VDP(4)) + "," + Str(VDP(5)) + "," + Str(VDP(6)) + "," + Str(VDP(7)) +
             " VDP(10,11)=" + Str(VDP(10)) + "," + Str(VDP(11)) +
             " ChrTab=$" + Hex(ChrTab) + " ColTab=$" + Hex(ColTab) + " ChrGen=$" + Hex(ChrGen) +
             " ChrTabM=$" + Hex(ChrTabM) + " ColTabM=$" + Hex(ColTabM) + " ChrGenM=$" + Hex(ChrGenM))
    EndIf
    ProcedureReturn 0
  EndIf
  ProcedureReturn PeekA(*Addr)
EndProcedure

; V9938 MMC structure for CPU-VRAM transfer commands
Structure VDPCommandState
  SX.l : SY.l
  DX.l : DY.l
  TX.l : TY.l
  NX.l : NY.l
  ASX.l : ADX.l
  CL.a : LO.a : CM.a
  Active.l
EndStructure

Global MMC.VDPCommandState

; VDP register masks
Structure VDPRegMasks
  R2.a : R3.a : R4.a : R5.a
  M2.a : M3.a : M4.a : M5.a
EndStructure

Global Dim MSK.VDPRegMasks(13)

Procedure InitRegMasks()
  ; SCR 0: TEXT 40x24
  MSK(0)\R2 = $7F : MSK(0)\R3 = $00 : MSK(0)\R4 = $3F : MSK(0)\R5 = $00
  MSK(0)\M2 = $00 : MSK(0)\M3 = $00 : MSK(0)\M4 = $00 : MSK(0)\M5 = $00
  
  ; SCR 1: TEXT 32x24
  MSK(1)\R2 = $7F : MSK(1)\R3 = $FF : MSK(1)\R4 = $3F : MSK(1)\R5 = $FF
  MSK(1)\M2 = $00 : MSK(1)\M3 = $00 : MSK(1)\M4 = $00 : MSK(1)\M5 = $00
  
  ; SCR 2: BLK 256x192
  MSK(2)\R2 = $7F : MSK(2)\R3 = $80 : MSK(2)\R4 = $3C : MSK(2)\R5 = $FF
  MSK(2)\M2 = $00 : MSK(2)\M3 = $7F : MSK(2)\M4 = $03 : MSK(2)\M5 = $00
  
  ; SCR 3: 64x48x16
  MSK(3)\R2 = $7F : MSK(3)\R3 = $00 : MSK(3)\R4 = $3F : MSK(3)\R5 = $FF
  MSK(3)\M2 = $00 : MSK(3)\M3 = $00 : MSK(3)\M4 = $00 : MSK(3)\M5 = $00
  
  ; SCR 4: BLK 256x192 (MSX2)
  MSK(4)\R2 = $7F : MSK(4)\R3 = $80 : MSK(4)\R4 = $3C : MSK(4)\R5 = $FC
  MSK(4)\M2 = $00 : MSK(4)\M3 = $7F : MSK(4)\M4 = $03 : MSK(4)\M5 = $03
  
  ; SCR 5: 256x192x16
  MSK(5)\R2 = $60 : MSK(5)\R3 = $00 : MSK(5)\R4 = $00 : MSK(5)\R5 = $FC
  MSK(5)\M2 = $1F : MSK(5)\M3 = $00 : MSK(5)\M4 = $00 : MSK(5)\M5 = $03
  
  ; SCR 6: 512x192x4
  MSK(6)\R2 = $60 : MSK(6)\R3 = $00 : MSK(6)\R4 = $00 : MSK(6)\R5 = $FC
  MSK(6)\M2 = $1F : MSK(6)\M3 = $00 : MSK(6)\M4 = $00 : MSK(6)\M5 = $03
  
  ; SCR 7: 512x192x16
  MSK(7)\R2 = $20 : MSK(7)\R3 = $00 : MSK(7)\R4 = $00 : MSK(7)\R5 = $FC
  MSK(7)\M2 = $1F : MSK(7)\M3 = $00 : MSK(7)\M4 = $00 : MSK(7)\M5 = $03
  
  ; SCR 8: 256x192x256
  MSK(8)\R2 = $20 : MSK(8)\R3 = $00 : MSK(8)\R4 = $00 : MSK(8)\R5 = $FC
  MSK(8)\M2 = $1F : MSK(8)\M3 = $00 : MSK(8)\M4 = $00 : MSK(8)\M5 = $03
  
  ; SCR 10/11/12
  Protected I.l
  For I = 10 To 12
    MSK(I)\R2 = $20 : MSK(I)\R3 = $00 : MSK(I)\R4 = $00 : MSK(I)\R5 = $FC
    MSK(I)\M2 = $1F : MSK(I)\M3 = $00 : MSK(I)\M4 = $00 : MSK(I)\M5 = $03
  Next I
  
  ; SCR 0: TEXT 80x24
  MSK(13)\R2 = $7C : MSK(13)\R3 = $F8 : MSK(13)\R4 = $3F : MSK(13)\R5 = $00
  MSK(13)\M2 = $03 : MSK(13)\M3 = $07 : MSK(13)\M4 = $00 : MSK(13)\M5 = $00
EndProcedure

InitRegMasks()

Global Dim PalInit.l(15)
PalInit(0)  = RGB($00, $00, $00)
PalInit(1)  = RGB($00, $00, $00)
PalInit(2)  = RGB($20, $C0, $20)
PalInit(3)  = RGB($60, $E0, $60)
PalInit(4)  = RGB($E0, $20, $20)
PalInit(5)  = RGB($E0, $60, $40)
PalInit(6)  = RGB($20, $20, $A0)
PalInit(7)  = RGB($E0, $C0, $40)
PalInit(8)  = RGB($20, $20, $E0)
PalInit(9)  = RGB($60, $60, $E0)
PalInit(10) = RGB($20, $C0, $C0)
PalInit(11) = RGB($80, $C0, $C0)
PalInit(12) = RGB($20, $80, $20)
PalInit(13) = RGB($A0, $40, $C0)
PalInit(14) = RGB($A0, $A0, $A0)
PalInit(15) = RGB($E0, $E0, $E0)

; Forward Declarations
Declare SetScreen()
Declare InitializeVDP()
Declare ResetVDP()
Declare VDPOut(R.a, V.a)
Declare MSXWriteVDP(Port.u, V.a)
Declare.a MSXReadVDP(Port.u)
Declare.u SetIRQ(IRQ.a)
Declare.a ReadVRAMPixel(X.l, Y.l)
Declare WriteVRAMPixel(X.l, Y.l, CL.a, OP.a)
Declare VDPDraw(Op.a)
Declare.a VDPRead()
Declare VDPWrite(V.a)

; Set active VRAM address pointers
Procedure SetScreen()
  Protected OldScrMode.a = ScrMode
  Protected modeBits.a = ((VDP(0) & $0E) >> 1) | (VDP(1) & $18)
  Select modeBits
    Case $10 : ScrMode = 0
    Case $00 : ScrMode = 1
    Case $01 : ScrMode = 2
    Case $08 : ScrMode = 3
    Case $02 : ScrMode = 4
    Case $03 : ScrMode = 5
    Case $04 : ScrMode = 6
    Case $05 : ScrMode = 7
    Case $07 : ScrMode = 8
    Default  : ScrMode = 0
  EndSelect
  
  ; Handle special 80-column text mode flag
  If ScrMode = 0 And (VDP(0) & $04)
    ScrMode = 13
  EndIf
  
  Protected J.l = ScrMode
  Protected I.l = 10
  If J > 6 And J <> 13
    I = 11
  EndIf
  
  ChrTab  = *VRAM + ((VDP(2) & MSK(J)\R2) << I)
  ChrGen  = *VRAM + ((VDP(4) & MSK(J)\R4) << 11)
  ColTab  = *VRAM + ((VDP(3) & MSK(J)\R3) << 6) + (VDP(10) << 14)
  SprTab  = *VRAM + ((VDP(5) & MSK(J)\R5) << 7) + (VDP(11) << 15)
  SprGen  = *VRAM + ((VDP(6) & $3F) << 11)
  
  ChrTabM = ((VDP(2) | ~MSK(J)\M2) << I) | ((1 << I) - 1)
  ChrGenM = ((VDP(4) | ~MSK(J)\M4) << 11) | $7FF
  ColTabM = ((VDP(3) | ~MSK(J)\M3) << 6) | $1C03F
  SprTabM = ((VDP(5) | ~MSK(J)\M5) << 7) | $1807F

  If ScrMode <> OldScrMode
    LogVDP("SetScreen: ScrMode " + Str(OldScrMode) + " -> " + Str(ScrMode) + " VDP(0)=$" + Hex(VDP(0)) +
           " VDP(1)=$" + Hex(VDP(1)) + " VDP(2)=$" + Hex(VDP(2)) + " ChrTab=$" + Hex(ChrTab) +
           " ColTab=$" + Hex(ColTab) + " ChrGen=$" + Hex(ChrGen))
  EndIf
EndProcedure

; Round Requested up to the nearest power of 2, then clamp/reset to a valid VRAM page count
; for the CURRENT model. MSX2/MSX2+ match real fMSX exactly (MSX.c, ResetMSX()): ONLY exactly 8
; pages (128KB) is accepted - any other value (including "192KB"/12->16 pages) resets to 8; real
; fMSX has no 192KB/V9958-addon concept at all, that menu option always snaps back to 128KB.
; MSX1's minimum is 1 page (16KB) here - a DELIBERATE deviation from real fMSX (which only
; accepts 2/4/8 pages on MSX1, silently resetting a 1-page/16KB request to the 2-page default)
; - chosen 2026-08-18 at the project owner's explicit request, since 16KB was the common real
; MSX1-hardware VRAM size and is now this project's own MSX1 default, even though real fMSX
; itself never actually runs MSX1 with 16KB. If you're trying to match real fMSX behavior
; exactly for some other reason, this is the one place fossauro intentionally diverges.
Procedure.l ClampVRAMPages(Requested.l)
  Protected P.l = 1
  While P < Requested
    P << 1
  Wend
  Protected MinPages.l = 8
  Protected MaxPages.l = 8
  If (Mode & #MSX_MODEL) = #MSX_MSX1
    MinPages = 1
    MaxPages = 8
  EndIf
  If P < MinPages Or P > MaxPages : P = MinPages : EndIf
  ProcedureReturn P
EndProcedure

; (Re)allocate *VRAM at the current VRAMPages size. Unlike RAM, real V9938/fMSX has no bank-
; switch mapper for VRAM to preserve here - it's just a flat buffer, page-selected for CPU
; access via VDP register 14 (already masked to VRAMPages-1 at every use site) and, for the
; V9938 command engine (modes 5-8), addressed with no size-aware masking at all in real fMSX -
; safe there only because non-MSX1 models are always exactly 128KB (see ClampVRAMPages()).
; SafePeekVRAM()'s bounds check (this file, top) is what protects the OTHER read paths
; (ChrTab/ColTab/ChrGen/SprTab table pointers, modes 0-4) against a smaller MSX1 buffer -
; real fMSX has no equivalent guard there either, it just never shrinks VRAM enough to need one.
Procedure ReallocateVRAM()
  If *VRAM : FreeMemory(*VRAM) : EndIf
  VRAMPages = ClampVRAMPages(VRAMPages)
  *VRAM = AllocateMemory(VRAMPages * $4000)
  FillMemory(*VRAM, VRAMPages * $4000, $00)
  *VPAGE = *VRAM
EndProcedure

Procedure InitializeVDP()
  ReallocateVRAM()
  ResetVDP()
EndProcedure

Procedure ResetVDP()
  Protected I.l
  For I = 0 To 63
    VDP(I) = 0
  Next I
  For I = 0 To 15
    VDPStatus(I) = 0
  Next I
  
  VDPKey = 1
  VDPALatch = 0
  VDPAddr = 0
  VDPData = 0
  *VPAGE = *VRAM
  ScrMode = 0
  PKey = 1
  PLatch = 0
  MMC\Active = 0
  
  For I = 0 To 15
    Palette(I) = PalInit(I)
  Next I
  
  SetScreen()
EndProcedure

Procedure VDPOut(R.a, V.a)
  VDP(R) = V
  If R <= 2
    LogVDP("VDPOut R=" + Str(R) + " V=$" + Hex(V) + " (mode-relevant register write)")
  EndIf
  Select R
    Case 0
      If (VDPStatus(1) & $01) And (V & $10) = 0
        VDPStatus(1) = VDPStatus(1) & $FE
        SetIRQ(~#INT_IE1)
      EndIf
      SetScreen()
      
    Case 1
      If VDPStatus(0) & $80
        If V & $20
          SetIRQ(#INT_IE0)
        Else
          SetIRQ(~#INT_IE0)
        EndIf
      EndIf
      SetScreen()
      
    Case 14
      Protected pageIndex.a = V & (VRAMPages - 1)
      *VPAGE = *VRAM + (pageIndex << 14)
      
    Case 15
      VDP(15) = V & $0F
      
    Case 16
      VDP(16) = V & $0F
      PKey = 1 ; Reset palette sequencer
      
    Case 2, 3, 4, 5, 6, 10, 11, 25
      SetScreen()
      
    Case 44
      VDPWrite(V)
      
    Case 46
      VDPDraw(V)
  EndSelect
EndProcedure

; Screen width in pixels, and pixels packed per VRAM byte, for VDP command-engine modes 5-8.
; Matches real fMSX's PPL[]/PPB[] tables (V9938.c) - used by SRCH's wrap boundary and by the
; "high-speed" byte-oriented commands (HMMV/HMMM/YMMM/HMMC), which operate on whole VRAM bytes
; rather than individual pixels.
Procedure.l VDPModeWidth(mode.a)
  Select mode
    Case 6, 7 : ProcedureReturn 512
    Default   : ProcedureReturn 256
  EndSelect
EndProcedure

Procedure.l VDPPixelsPerByte(mode.a)
  Select mode
    Case 6 : ProcedureReturn 4
    Case 8 : ProcedureReturn 1
    Default : ProcedureReturn 2 ; modes 5 and 7
  EndSelect
EndProcedure

Procedure.i GetVRAMAddr(mode.a, X.l, Y.l)
  Protected offset.l = 0
  Select mode
    Case 5
      offset = (Y & 1023) * 128 + (X & 255) / 2
    Case 6
      offset = (Y & 1023) * 128 + (X & 511) / 4
    Case 7
      offset = (Y & 511) * 256 + (X & 511) / 2
    Case 8
      offset = (Y & 511) * 256 + (X & 255)
  EndSelect
  ProcedureReturn *VRAM + offset
EndProcedure

Procedure.a ReadVRAMPixel(X.l, Y.l)
  Protected mode.a = ScrMode
  If mode < 5 : ProcedureReturn 0 : EndIf
  Protected *P.Ascii = GetVRAMAddr(mode, X, Y)
  Select mode
    Case 5
      ProcedureReturn (*P\a >> (((~X) & 1) * 4)) & $0F
    Case 6
      ProcedureReturn (*P\a >> (((~X) & 3) * 2)) & $03
    Case 7
      ProcedureReturn (*P\a >> (((~X) & 1) * 4)) & $0F
    Case 8
      ProcedureReturn *P\a
  EndSelect
  ProcedureReturn 0
EndProcedure

Procedure WriteVRAMPixel(X.l, Y.l, CL.a, OP.a)
  Protected mode.a = ScrMode
  If mode < 5 : ProcedureReturn : EndIf
  Protected *P.Ascii = GetVRAMAddr(mode, X, Y)
  Protected mask.a = $FF
  Protected shift.a = 0
  
  Select mode
    Case 5, 7
      shift = ((~X) & 1) * 4
      mask = ~($0F << shift)
      CL = (CL & $0F) << shift
    Case 6
      shift = ((~X) & 3) * 2
      mask = ~($03 << shift)
      CL = (CL & $03) << shift
    Case 8
      mask = 0
  EndSelect
  
  Protected oldVal.a = *P\a
  Protected newVal.a = oldVal
  
  Select OP & $0F
    Case 0 : newVal = (oldVal & mask) | CL ; IMP
    Case 1 : newVal = oldVal & (CL | mask) ; AND
    Case 2 : newVal = oldVal | CL          ; OR
    Case 3 : newVal = oldVal ! CL          ; XOR
    Case 4 : newVal = (oldVal & mask) | ~(CL | mask) ; NOT
    Case 8 : If CL : newVal = (oldVal & mask) | CL : EndIf
    Case 9 : If CL : newVal = oldVal & (CL | mask) : EndIf
    Case 10 : If CL : newVal = oldVal | CL : EndIf
    Case 11 : If CL : newVal = oldVal ! CL : EndIf
    Case 12 : If CL : newVal = (oldVal & mask) | ~(CL | mask) : EndIf
  EndSelect
  
  *P\a = newVal
EndProcedure

Procedure VDPDraw(Op.a)
  If ScrMode < 5 : ProcedureReturn : EndIf

  Protected CM.a = Op >> 4
  Protected LO.a = Op & $0F

  Protected SX.l = (VDP(32) | (VDP(33) << 8)) & 511
  Protected SY.l = (VDP(34) | (VDP(35) << 8)) & 1023
  Protected DX.l = (VDP(36) | (VDP(37) << 8)) & 511
  Protected DY.l = (VDP(38) | (VDP(39) << 8)) & 1023
  Protected NX.l = (VDP(40) | (VDP(41) << 8)) & 1023
  Protected NY.l = (VDP(42) | (VDP(43) << 8)) & 1023
  Protected CL.a = VDP(44)
  Protected TX.l = 1
  If VDP(45) & $04 : TX = -1 : EndIf
  Protected TY.l = 1
  If VDP(45) & $08 : TY = -1 : EndIf
  
  VDPStatus(2) = VDPStatus(2) & ~$01 ; CE = 0
  VDPStatus(2) = VDPStatus(2) & ~$80 ; TR = 0
  
  Select CM
    Case $00 ; ABRT
      MMC\Active = 0
      
    Case $04 ; POINT
      VDPStatus(7) = ReadVRAMPixel(SX, SY)
      VDP(44) = VDPStatus(7)
      
    Case $05 ; PSET
      WriteVRAMPixel(DX, DY, CL, LO)
      
    Case $06 ; SRCH
      Protected found.l = 0
      Protected border.l = 0
      If VDP(45) & $02 : border = 1 : EndIf
      Protected srchWidth.l = VDPModeWidth(ScrMode)
      Protected x.l = SX
      While x >= 0 And x < srchWidth
        Protected val.a = ReadVRAMPixel(x, SY)
        If (val = CL) = border
          found = 1
          Break
        EndIf
        x + TX
      Wend
      If found
        VDPStatus(2) = VDPStatus(2) | $10
      Else
        VDPStatus(2) = VDPStatus(2) & ~$10
      EndIf
      VDPStatus(8) = x & $FF
      VDPStatus(9) = (x >> 8) | $FE
      
    Case $07 ; LINE
      Protected err.l = (NX - 1) >> 1
      Protected step_count.l = 0
      Protected cur_x.l = DX
      Protected cur_y.l = DY
      If (VDP(45) & $01) = 0
        For step_count = 0 To NX - 1
          WriteVRAMPixel(cur_x, cur_y, CL, LO)
          cur_x + TX
          err - NY
          If err < 0
            err + NX
            cur_y + TY
          EndIf
        Next
      Else
        For step_count = 0 To NX - 1
          WriteVRAMPixel(cur_x, cur_y, CL, LO)
          cur_y + TY
          err - NY
          If err < 0
            err + NX
            cur_x + TX
          EndIf
        Next
      EndIf
      VDP(38) = cur_y & $FF
      VDP(39) = (cur_y >> 8) & $03
      
    Case $08 ; LMMV
      Protected ix.l, iy.l
      For iy = 0 To NY - 1
        For ix = 0 To NX - 1
          WriteVRAMPixel(DX + ix * TX, DY + iy * TY, CL, LO)
        Next ix
      Next iy
      
    Case $09 ; LMMM
      For iy = 0 To NY - 1
        For ix = 0 To NX - 1
          Protected pixel.a = ReadVRAMPixel(SX + ix * TX, SY + iy * TY)
          WriteVRAMPixel(DX + ix * TX, DY + iy * TY, pixel, LO)
        Next ix
      Next iy
      
    Case $0C ; HMMV - "high-speed" commands are byte-oriented on real V9938 hardware: CL is
      ; stored as a raw whole byte (no per-pixel mask/logical-op, no nibble splitting), stepped
      ; by PixelsPerByte(mode) pixels per iteration, not 1 - see VDPPixelsPerByte()/real fMSX's
      ; PPB[]/(MMC.CM & 0x0C)==0x0C in V9938.c. Confirmed 2026-08-17 as a real fidelity gap
      ; against real fMSX (see docs/SPEC.md module 32e): the old per-pixel-masked WriteVRAMPixel
      ; path only produced correct results when CL's sub-pixel fields all matched already.
      Protected ppbH.l = VDPPixelsPerByte(ScrMode)
      Protected txbH.l = ppbH : If VDP(45) & $04 : txbH = -ppbH : EndIf
      Protected nxbH.l = NX / ppbH
      For iy = 0 To NY - 1
        For ix = 0 To nxbH - 1
          Protected *pvH.Ascii = GetVRAMAddr(ScrMode, DX + ix * txbH, DY + iy * TY)
          *pvH\a = CL
        Next ix
      Next iy

    Case $0D ; HMMM - raw whole-byte VRAM->VRAM copy, see Case $0C comment above.
      Protected ppbM.l = VDPPixelsPerByte(ScrMode)
      Protected txbM.l = ppbM : If VDP(45) & $04 : txbM = -ppbM : EndIf
      Protected nxbM.l = NX / ppbM
      For iy = 0 To NY - 1
        For ix = 0 To nxbM - 1
          Protected *spM.Ascii = GetVRAMAddr(ScrMode, SX + ix * txbM, SY + iy * TY)
          Protected *dpM.Ascii = GetVRAMAddr(ScrMode, DX + ix * txbM, DY + iy * TY)
          *dpM\a = *spM\a
        Next ix
      Next iy

    Case $0E ; YMMM - Y-only move: real V9938 hardware copies within the SAME X column (source
      ; and dest X are both DX - the SX/SY registers only supply the source ROW) across the
      ; FULL screen width, ignoring the NX register entirely (see real fMSX's post__xyy macro
      ; in V9938.c, which advances ADX until it wraps the mode's pixel width, never testing
      ; NX). Confirmed 2026-08-17 (docs/SPEC.md module 32e) that the previous port used SX as
      ; an independent source X and bounded the scan by NX - both wrong.
      Protected ppbY.l = VDPPixelsPerByte(ScrMode)
      Protected widthY.l = VDPModeWidth(ScrMode)
      Protected txbY.l = ppbY : If VDP(45) & $04 : txbY = -ppbY : EndIf
      Protected xCurY.l
      For iy = 0 To NY - 1
        xCurY = DX
        While (txbY > 0 And xCurY < widthY) Or (txbY < 0 And xCurY >= 0)
          Protected *spY.Ascii = GetVRAMAddr(ScrMode, xCurY, SY + iy * TY)
          Protected *dpY.Ascii = GetVRAMAddr(ScrMode, xCurY, DY + iy * TY)
          *dpY\a = *spY\a
          xCurY + txbY
        Wend
      Next iy
      
    Case $0B, $0F ; LMMC, HMMC (CPU to VRAM)
      MMC\SX = SX : MMC\SY = SY
      MMC\DX = DX : MMC\DY = DY
      MMC\NX = NX : MMC\NY = NY
      MMC\TX = TX : MMC\TY = TY
      MMC\CL = CL : MMC\LO = LO
      MMC\CM = CM
      MMC\ASX = 0
      MMC\ADX = 0
      MMC\Active = 1
      VDPStatus(2) = VDPStatus(2) | $01 ; CE = 1
      VDPStatus(2) = VDPStatus(2) | $80 ; TR = 1
      ; Real V9938/fMSX consumes one pixel immediately when the command starts, using
      ; whatever value is already latched in VDP register 44 (S#7) - see real fMSX's
      ; VDPDraw() in V9938.c, which calls VdpEngine() once right after setup, before any
      ; CPU feed byte arrives. A real MSX2 BIOS LMMC feed loop (found booting plain MSX2,
      ; docs/SPEC.md module 32j) relies on this and only ever sends NX*NY-1 more bytes -
      ; without this immediate first plot, MMC\ASX/ADX can never reach NX*NY, CE (Command
      ; Executing) never clears, and every later "wait for VDP ready" poll hangs forever.
      VDPWrite(VDP(44))

    Case $0A ; LMCM (VRAM to CPU)
      MMC\SX = SX : MMC\SY = SY
      MMC\DX = DX : MMC\DY = DY
      MMC\NX = NX : MMC\NY = NY
      MMC\TX = TX : MMC\TY = TY
      MMC\CL = CL : MMC\LO = LO
      MMC\CM = CM
      MMC\ASX = 0
      MMC\ADX = 0
      MMC\Active = 1
      VDPStatus(2) = VDPStatus(2) | $01 ; CE = 1
      VDPStatus(2) = VDPStatus(2) | $80 ; TR = 1
  EndSelect
EndProcedure

Procedure VDPWrite(V.a)
  VDPStatus(2) = VDPStatus(2) & ~$80 ; Clear TR
  VDPStatus(7) = V
  VDP(44) = V
  
  If MMC\Active
    If MMC\CM = $0F ; HMMC
      ; HMMC: writes a raw byte containing 1, 2 or 4 pixels depending on Screen
      Protected SM.a = ScrMode
      Select SM
        Case 5, 7
          WriteVRAMPixel(MMC\DX + MMC\ASX * MMC\TX, MMC\DY + MMC\ADX * MMC\TY, V >> 4, 0)
          MMC\ASX + 1
          If MMC\ASX < MMC\NX
            WriteVRAMPixel(MMC\DX + MMC\ASX * MMC\TX, MMC\DY + MMC\ADX * MMC\TY, V & $0F, 0)
            MMC\ASX + 1
          EndIf
        Case 6
          WriteVRAMPixel(MMC\DX + MMC\ASX * MMC\TX, MMC\DY + MMC\ADX * MMC\TY, (V >> 6) & 3, 0)
          MMC\ASX + 1
          If MMC\ASX < MMC\NX
            WriteVRAMPixel(MMC\DX + MMC\ASX * MMC\TX, MMC\DY + MMC\ADX * MMC\TY, (V >> 4) & 3, 0)
            MMC\ASX + 1
          EndIf
          If MMC\ASX < MMC\NX
            WriteVRAMPixel(MMC\DX + MMC\ASX * MMC\TX, MMC\DY + MMC\ADX * MMC\TY, (V >> 2) & 3, 0)
            MMC\ASX + 1
          EndIf
          If MMC\ASX < MMC\NX
            WriteVRAMPixel(MMC\DX + MMC\ASX * MMC\TX, MMC\DY + MMC\ADX * MMC\TY, V & 3, 0)
            MMC\ASX + 1
          EndIf
        Case 8
          WriteVRAMPixel(MMC\DX + MMC\ASX * MMC\TX, MMC\DY + MMC\ADX * MMC\TY, V, 0)
          MMC\ASX + 1
      EndSelect
      
    ElseIf MMC\CM = $0B ; LMMC
      ; LMMC: writes 1 pixel per Register 44 write
      WriteVRAMPixel(MMC\DX + MMC\ASX * MMC\TX, MMC\DY + MMC\ADX * MMC\TY, V, MMC\LO)
      MMC\ASX + 1
    EndIf
    
    If MMC\ASX >= MMC\NX
      MMC\ASX = 0
      MMC\ADX + 1
      If MMC\ADX >= MMC\NY
        MMC\Active = 0
        VDPStatus(2) = VDPStatus(2) & ~$01 ; CE = 0
        VDPStatus(2) = VDPStatus(2) & ~$80 ; TR = 0
        ProcedureReturn
      EndIf
    EndIf
    
    VDPStatus(2) = VDPStatus(2) | $80 ; TR = 1
  EndIf
EndProcedure

Procedure.a VDPRead()
  VDPStatus(2) = VDPStatus(2) & ~$80 ; Clear TR
  
  Protected res.a = 0
  If MMC\Active And MMC\CM = $0A ; LMCM
    res = ReadVRAMPixel(MMC\SX + MMC\ASX * MMC\TX, MMC\SY + MMC\ADX * MMC\TY)
    MMC\ASX + 1
    If MMC\ASX >= MMC\NX
      MMC\ASX = 0
      MMC\ADX + 1
      If MMC\ADX >= MMC\NY
        MMC\Active = 0
        VDPStatus(2) = VDPStatus(2) & ~$01 ; CE = 0
        VDPStatus(2) = VDPStatus(2) & ~$80 ; TR = 0
        ProcedureReturn res
      EndIf
    EndIf
    VDPStatus(2) = VDPStatus(2) | $80 ; TR = 1
  EndIf
  ProcedureReturn res
EndProcedure

Procedure LoopVDP()
  ; Dummy as everything runs instantly
EndProcedure

; Handle port writes ($98-$99) from MSXOutZ80
Procedure MSXWriteVDP(Port.u, V.a)
  Port = Port & $FF
  Select Port
    Case $98
      VDPKey = 1
      PokeA(*VPAGE + VDPAddr, V)
      VDPData = V
      VDPAddr = (VDPAddr + 1) & $3FFF
      If VDPAddr = 0 And ScrMode > 3
        VDP(14) = (VDP(14) + 1) & (VRAMPages - 1)
        *VPAGE = *VRAM + (VDP(14) << 14)
      EndIf
      
    Case $99
      If VDPKey = 1
        VDPALatch = V
        VDPKey = 0
      Else
        VDPKey = 1
        Select V & $C0
          Case $80
            VDPOut(V & $3F, VDPALatch)
          Case $00, $40
            VDPAddr = ((V & $3F) << 8) | VDPALatch
            If (V & $40) = 0
              VDPData = PeekA(*VPAGE + VDPAddr)
              VDPAddr = (VDPAddr + 1) & $3FFF
              If VDPAddr = 0 And ScrMode > 3
                VDP(14) = (VDP(14) + 1) & (VRAMPages - 1)
                *VPAGE = *VRAM + (VDP(14) << 14)
              EndIf
            EndIf
        EndSelect
      EndIf
      
    Case $9A
      If PKey = 1
        PLatch = V
        PKey = 0
      Else
        PKey = 1
        Protected J.a = VDP(16)
        Protected R.a = ((PLatch & $70) * 255) / 112
        Protected G.a = ((V & $07) * 255) / 7
        Protected B.a = ((PLatch & $07) * 255) / 7
        Palette(J) = RGB(B, G, R)
        VDP(16) = (J + 1) & $0F
      EndIf
      
    Case $9B
      Protected reg.a = VDP(17) & $3F
      If reg <> 17
        VDPOut(reg, V)
      EndIf
      If (VDP(17) & $80) = 0
        VDP(17) = (reg + 1) & $3F
      EndIf
  EndSelect
EndProcedure

; Handle port reads ($98-$99) from MSXInZ80
Procedure.a MSXReadVDP(Port.u)
  Port = Port & $FF
  Select Port
    Case $98
      Protected res.a = VDPData
      VDPKey = 1
      VDPData = PeekA(*VPAGE + VDPAddr)
      VDPAddr = (VDPAddr + 1) & $3FFF
      If VDPAddr = 0 And ScrMode > 3
        VDP(14) = (VDP(14) + 1) & (VRAMPages - 1)
        *VPAGE = *VRAM + (VDP(14) << 14)
      EndIf
      ProcedureReturn res
      
    Case $99
      Protected reg.a = VDP(15)
      Protected res_st.a = VDPStatus(reg)

      If reg = 0
        VDPStatus(0) = VDPStatus(0) & $5F
        SetIRQ(~#INT_IE0)
      ElseIf reg = 1
        VDPStatus(1) = VDPStatus(1) & $FE
        SetIRQ(~#INT_IE1)
      ElseIf reg = 7
        VDPStatus(7) = VDPRead()
        VDP(44) = VDPStatus(7)
      EndIf
      
      ProcedureReturn res_st
  EndSelect
  
  ProcedureReturn $FF
EndProcedure

; --- Sprite rendering helpers ---

Procedure RenderSprites(Y.l, *LineBuf)
  ; Bit 1 of VDP(8) disables sprites
  If (VDP(8) & $02) Or ScrMode < 1
    ProcedureReturn
  EndIf
  
  Protected sprite_size.l = 8
  If VDP(1) & $02 : sprite_size = 16 : EndIf
  Protected mag.l = VDP(1) & $01
  Protected actual_size.l = sprite_size * (mag + 1)
  
  ; Draw sprites 31 down to 0, so sprite 0 gets drawn on top
  Protected s.l
  For s = 31 To 0 Step -1
    Protected attr_addr.i = SprTab + s * 4
    Protected spr_y.l = SafePeekVRAM(attr_addr, "RenderSprites SprTab Y")
    
    If spr_y = 208 And ScrMode < 5 : Continue : EndIf
    If spr_y = 216 And ScrMode >= 5 : Continue : EndIf
    
    If spr_y > 224
      spr_y = spr_y - 256
    EndIf
    
    Protected line_offset.l = Y - spr_y
    If line_offset >= 0 And line_offset < actual_size
      Protected spr_x.l = SafePeekVRAM(attr_addr + 1, "RenderSprites SprTab X")
      Protected pattern.l = SafePeekVRAM(attr_addr + 2, "RenderSprites SprTab pattern")
      Protected color_byte.a = SafePeekVRAM(attr_addr + 3, "RenderSprites SprTab color")
      Protected color_idx.a = color_byte & $0F
      
      If color_byte & $80
        spr_x = spr_x - 32
      EndIf
      
      If sprite_size = 16
        pattern = pattern & $FC
      EndIf
      
      Protected pattern_line.l = line_offset / (mag + 1)
      Protected pattern_addr.i = SprGen + pattern * 8 + pattern_line
      
      Protected pat_byte1.a = SafePeekVRAM(pattern_addr, "RenderSprites SprGen pat1")
      Protected pat_byte2.a = 0
      If sprite_size = 16
        pat_byte2 = SafePeekVRAM(pattern_addr + 16, "RenderSprites SprGen pat2")
      EndIf
      
      Protected px.l
      For px = 0 To sprite_size - 1
        Protected active.l = 0
        If px < 8
          active = (pat_byte1 & ($80 >> px))
        Else
          active = (pat_byte2 & ($80 >> (px - 8)))
        EndIf
        
        If active
          Protected dest_x.l = spr_x + px * (mag + 1)
          Protected m.l
          For m = 0 To mag
            Protected final_x.l = dest_x + m
            If final_x >= 0 And final_x < 256
              If color_idx > 0
                PokeL(*LineBuf + final_x * 4, Palette(color_idx))
              EndIf
            EndIf
          Next m
        EndIf
      Next px
    EndIf
  Next s
EndProcedure

; --- Framebuffer rendering procedures ---

Global Dim FrameBuffer.l(512 * 212 - 1)

Procedure.l GetScreen8Color(b.a)
  Protected red_val.l = ((b >> 2) & $07) * 255 / 7
  Protected green_val.l = ((b >> 5) & $07) * 255 / 7
  Protected blue_val.l = (b & $03) * 255 / 3
  ProcedureReturn RGB(red_val, green_val, blue_val)
EndProcedure

Procedure RefreshLine(Y.l)
  If Y < 0 Or Y >= 212 : ProcedureReturn : EndIf
  
  Protected *LineDest = @FrameBuffer(Y * 512)
  Protected bg_color.l = Palette(VDP(7) & $0F)
  
  ; 1. Check if Screen is on
  If (VDP(1) & $40) = 0
    ; FillMemory's Value defaults to a BYTE fill (repeats only the low 8 bits of bg_color across
    ; every byte) unless the Long type is given explicitly - without it, any border color whose
    ; low byte differs from its other channels renders wrong (found 2026-08-18 while adding
    ; SCREEN 6/7 support and tracing a "background renders as a near-black smear instead of the
    ; real palette color" bug back to this exact call). Same fix applied to every other
    ; FillMemory() in this procedure that fills 32-bit Palette()/RGB() values below.
    FillMemory(*LineDest, 512 * 4, bg_color, #PB_Long)
    ProcedureReturn
  EndIf

  ; 2. Render background line according to ScrMode
  Protected mode.a = ScrMode
  Protected col.l, row.l, char_y.l, char_code.l, font_byte.a, color_byte.a, fg.l, bg.l, px.l
  Protected temp_line.i = AllocateMemory(256 * 4)
  FillMemory(temp_line, 256 * 4, bg_color, #PB_Long)

  Select mode
    Case 0 ; Text 40x24 (centered on 512 canvas, no sprite support)
      row = Y / 8
      char_y = Y & 7
      Protected text_bg.l = Palette(VDP(7) & $0F)
      Protected text_fg.l = Palette(VDP(7) >> 4)
      FillMemory(*LineDest, 512 * 4, text_bg, #PB_Long)
      
      ; Center 240px text area scaled 2x to 480px (16px borders)
      If row < 24
        For col = 0 To 39
          char_code = SafePeekVRAM(ChrTab + row * 40 + col, "RefreshLine mode0 ChrTab")
          font_byte = SafePeekVRAM(ChrGen + char_code * 8 + char_y, "RefreshLine mode0 ChrGen")
          For px = 0 To 5
            Protected c_idx.l = text_bg
            If font_byte & ($80 >> px)
              c_idx = text_fg
            EndIf
            PokeL(*LineDest + (16 + col * 12 + px * 2) * 4, c_idx)
            PokeL(*LineDest + (16 + col * 12 + px * 2 + 1) * 4, c_idx)
          Next px
        Next col
      EndIf
      FreeMemory(temp_line)
      ProcedureReturn
      
    Case 1 ; Text 32x24 (256 width, scaled to 512)
      row = Y / 8
      char_y = Y & 7
      If row < 24
        For col = 0 To 31
          char_code = SafePeekVRAM(ChrTab + row * 32 + col, "RefreshLine mode1 ChrTab")
          font_byte = SafePeekVRAM(ChrGen + char_code * 8 + char_y, "RefreshLine mode1 ChrGen")
          color_byte = SafePeekVRAM(ColTab + char_code / 8, "RefreshLine mode1 ColTab")
          fg = Palette((color_byte >> 4) & $0F)
          bg = Palette(color_byte & $0F)
          For px = 0 To 7
            Protected c.l = bg
            If font_byte & ($80 >> px)
              c = fg
            EndIf
            PokeL(temp_line + (col * 8 + px) * 4, c)
          Next px
        Next col
      EndIf
      
    Case 2, 4 ; Graphic 1 and Graphic 2 (256 width, scaled)
      Protected I.l = ((Y & $C0) << 5) + (Y & $07)
      Protected T.i = ChrTab + ((Y & $F8) << 2)
      For col = 0 To 31
        char_code = SafePeekVRAM(T + col, "RefreshLine mode2/4 ChrTab")
        Protected J.l = char_code << 3
        color_byte = SafePeekVRAM(ColTab + ((I + J) & ColTabM), "RefreshLine mode2/4 ColTab")
        font_byte = SafePeekVRAM(ChrGen + ((I + J) & ChrGenM), "RefreshLine mode2/4 ChrGen")
        fg = Palette((color_byte >> 4) & $0F)
        bg = Palette(color_byte & $0F)
        For px = 0 To 7
          Protected c_gr.l = bg
          If font_byte & ($80 >> px)
            c_gr = fg
          EndIf
          PokeL(temp_line + (col * 8 + px) * 4, c_gr)
        Next px
      Next col
      
    Case 3 ; Multicolor 64x48
      Protected G.i = ChrGen + ((Y & $1C) >> 2)
      T = ChrTab + ((Y & $F8) << 2)
      For col = 0 To 31
        char_code = PeekA(T + col)
        Protected K.a = PeekA(G + char_code * 8)
        Protected c1.l = Palette(K >> 4)
        Protected c2.l = Palette(K & $0F)
        For px = 0 To 3
          PokeL(temp_line + (col * 8 + px) * 4, c1)
          PokeL(temp_line + (col * 8 + 4 + px) * 4, c2)
        Next px
      Next col
      
    Case 5 ; Graphic 3 (Bitmap 16 colors)
      Protected VScroll.l = VDP(23)
      T = ChrTab + (((Y + VScroll) << 7) & ChrTabM & $7FFF)
      For col = 0 To 127
        Protected b.a = PeekA(T + col)
        PokeL(temp_line + (col * 2) * 4, Palette((b >> 4) & $0F))
        PokeL(temp_line + (col * 2 + 1) * 4, Palette(b & $0F))
      Next col

    Case 6, 7 ; Graphic 5/6 (Bitmap 4/16 colors, natively 512px wide - no 2x scale needed)
      ; Unlike modes 5/8 (256px logical, doubled to fill the 512px canvas), modes 6/7 already
      ; address the full 512px line directly, so this branch writes *LineDest itself and returns
      ; early, same pattern as Case 0 above. Byte packing/addressing mirrors ReadVRAMPixel()'s
      ; Case 6/7 (VDP command engine, already audited against real V9938.c - see module 32e) - same
      ; bit layout, just walking a whole scanline instead of one command-engine pixel at a time.
      ; Row stride reuses Case 5's `<<7`/`$7FFF` window for mode 6 (2bpp, same 128 bytes/line as
      ; mode 5) and Case 8's `<<8`/`$FFFF` window for mode 7 (4bpp, same 256 bytes/line as mode 8).
      Protected VScroll67.l = VDP(23)
      If mode = 6
        T = ChrTab + (((Y + VScroll67) << 7) & ChrTabM & $7FFF)
        For col = 0 To 127
          Protected b6.a = PeekA(T + col)
          PokeL(*LineDest + (col * 4 + 0) * 4, Palette((b6 >> 6) & $03))
          PokeL(*LineDest + (col * 4 + 1) * 4, Palette((b6 >> 4) & $03))
          PokeL(*LineDest + (col * 4 + 2) * 4, Palette((b6 >> 2) & $03))
          PokeL(*LineDest + (col * 4 + 3) * 4, Palette(b6 & $03))
        Next col
      Else ; mode = 7
        T = ChrTab + (((Y + VScroll67) << 8) & ChrTabM & $FFFF)
        For col = 0 To 255
          Protected b7.a = PeekA(T + col)
          PokeL(*LineDest + (col * 2) * 4, Palette((b7 >> 4) & $0F))
          PokeL(*LineDest + (col * 2 + 1) * 4, Palette(b7 & $0F))
        Next col
      EndIf

      ; Sprites are always positioned in the 256px logical coordinate space on real V9938
      ; hardware, even in 512px-wide modes (RenderSprites() already clips to final_x<256) - so
      ; each logical sprite pixel covers 2 physical pixels here, same doubling Case 5/8 get for
      ; free from the shared scale step below, just done manually since this branch skips it.
      Protected sentinel.l = $FFFFFF01 ; RGB() never sets the top byte, safe "no sprite pixel" marker
      FillMemory(temp_line, 256 * 4, sentinel, #PB_Long)
      RenderSprites(Y, temp_line)
      For col = 0 To 255
        Protected sprPix.l = PeekL(temp_line + col * 4)
        If sprPix <> sentinel
          PokeL(*LineDest + (col * 2) * 4, sprPix)
          PokeL(*LineDest + (col * 2 + 1) * 4, sprPix)
        EndIf
      Next col

      FreeMemory(temp_line)
      ProcedureReturn

    Case 8 ; Graphic 7 (Bitmap 256 colors)
      Protected VScroll8.l = VDP(23)
      T = ChrTab + (((Y + VScroll8) << 8) & ChrTabM & $FFFF)
      For col = 0 To 255
        Protected b8.a = PeekA(T + col)
        PokeL(temp_line + col * 4, GetScreen8Color(b8))
      Next col
      
    Default
      FillMemory(temp_line, 256 * 4, bg_color, #PB_Long)
  EndSelect
  
  ; 3. Render Sprites
  RenderSprites(Y, temp_line)
  
  ; 4. Scale 256x192 to 512x192 line buffer
  For col = 0 To 255
    Protected pix.l = PeekL(temp_line + col * 4)
    PokeL(*LineDest + (col * 2) * 4, pix)
    PokeL(*LineDest + (col * 2 + 1) * 4, pix)
  Next col
  
  FreeMemory(temp_line)
EndProcedure
