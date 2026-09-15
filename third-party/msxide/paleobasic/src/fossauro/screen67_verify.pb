; screen67_verify.pb - fossauro SCREEN 6/7 rendering verification harness
;
; Drives V9938.pbi's RefreshLine() directly (the real function fossauro.exe uses every frame) with
; hand-built VRAM test patterns for SCREEN 6 (Graphic 5, 512x212x4) and SCREEN 7 (Graphic 6,
; 512x212x16), plus one sprite, and dumps the resulting FrameBuffer to a plain 24-bit BMP so the
; result can actually be *looked at* (a console harness alone can't verify pixels visually).
;
; Usage: screen67_verify.exe [outdir]

EnableExplicit

Global ThreadExit.l = 0
Global ThreadPaused.l = 0

XIncludeFile "Z80_Tables.pbi"
XIncludeFile "Z80.pbi"
XIncludeFile "MSX.pbi" ; pulls in V9938.pbi (RefreshLine/FrameBuffer/ScrMode/ChrTab/SprTab/...)

Procedure WriteBMP(Path.s, W.l, H.l, *Frame)
  Protected hFile.i = CreateFile(#PB_Any, Path)
  If Not hFile
    ProcedureReturn #False
  EndIf

  Protected rowBytes.l = W * 3 ; 512*3=1536, already 4-byte aligned, no row padding needed
  Protected pixelBytes.l = rowBytes * H

  WriteString(hFile, "BM")
  WriteLong(hFile, 54 + pixelBytes) ; file size
  WriteLong(hFile, 0)               ; reserved
  WriteLong(hFile, 54)              ; pixel data offset

  WriteLong(hFile, 40)              ; BITMAPINFOHEADER size
  WriteLong(hFile, W)
  WriteLong(hFile, H)               ; positive height = bottom-up rows (standard BMP)
  WriteWord(hFile, 1)               ; planes
  WriteWord(hFile, 24)              ; bpp
  WriteLong(hFile, 0)               ; no compression
  WriteLong(hFile, pixelBytes)
  WriteLong(hFile, 2835) : WriteLong(hFile, 2835) ; 72 DPI
  WriteLong(hFile, 0) : WriteLong(hFile, 0)        ; palette colors used/important

  Protected y.l, x.l, c.l
  For y = H - 1 To 0 Step -1
    For x = 0 To W - 1
      c = PeekL(*Frame + (y * W + x) * 4)
      WriteByte(hFile, (c >> 16) & $FF) ; B
      WriteByte(hFile, (c >> 8) & $FF)  ; G
      WriteByte(hFile, c & $FF)         ; R
    Next x
  Next y

  CloseFile(hFile)
  ProcedureReturn #True
EndProcedure

; Builds a VDP/VRAM scene for the given screen mode (6 or 7): vertical color bars covering every
; palette entry the mode supports (0-3 for mode 6, 0-15 for mode 7), plus one solid white 8x8
; sprite near the left edge (logical X=20) to confirm sprite compositing/doubling on the 512-wide
; canvas.
Procedure SetupModeTest(TestMode.l)
  Mode = #MSX_MSX2 | #MSX_NTSC ; SCREEN 6/7 are MSX2-only, need the full 128KB VRAM window
  VRAMPages = 8
  InitializeVDP() ; ReallocateVRAM() + ResetVDP() (also resets VDP registers/palette to defaults)

  VDP(1) = $40 ; screen enabled, sprite size/mag bits = 0 (8x8, unmagnified)
  If TestMode = 6
    VDP(0) = $08 ; modeBits = ((VDP(0)&$0E)>>1)|(VDP(1)&$18) = 4 -> ScrMode 6
  Else
    VDP(0) = $0A ; modeBits = 5 -> ScrMode 7
  EndIf
  ; Real V9938 hardware (and every real MSX BASIC ROM) always sets R#2's low 5 bits ($1F, the
  ; MSK().M2 "don't care" bits for modes 5-8) to 1 - leaving them 0 collapses ChrTabM's computed
  ; wrap window down to ~1KB instead of the full 32KB bitmap plane. Found by this harness leaving
  ; VDP(2)=0 (ResetVDP()'s default) and getting a "staircase" of wrapped garbage instead of clean
  ; color bars - not a fossauro bug, just an invalid register value a real program would never use.
  VDP(2) = $1F
  ; Point the sprite attribute/pattern tables (SprTab/SprGen) well past the bitmap image plane
  ; (which only spans up to ~0x6980 in mode 6 / ~0xD400 in mode 7) - leaving VDP(5)/VDP(6)/VDP(11)
  ; at ResetVDP()'s default 0 makes SprTab/SprGen alias VRAM offset 0, i.e. the SAME bytes as the
  ; color-bar bitmap: RenderSprites() then reads bitmap bytes as if they were 32 sprites' Y/X/
  ; pattern/color attributes, drawing a scatter of bogus sprites - a real MSX BASIC program always
  ; sets these registers to non-overlapping locations, so this was purely a harness setup gap.
  ; Mode 7's bitmap is 256 bytes/row * 212 rows = ~54KB (up to ~$D400) - bigger than mode 6's
  ; ~27KB, so the tables need to clear THAT span, not just mode 6's.
  VDP(5) = $C0 : VDP(11) = 1 ; SprTab = VRAM + ((VDP(5)&$FC)<<7) + (VDP(11)<<15) = $E000
  VDP(6) = $1E               ; SprGen = VRAM + ((VDP(6)&$3F)<<11) = $F000
  SetScreen()

  Protected y.l, i.l, colors.l, barWidth.l
  If TestMode = 6
    colors = 4 : barWidth = 512 / colors
    For y = 0 To 211
      For i = 0 To 127 ; 128 bytes/row, 4 pixels/byte (2bpp)
        Protected p0.l = ((i * 4 + 0) / barWidth) % colors
        Protected p1.l = ((i * 4 + 1) / barWidth) % colors
        Protected p2.l = ((i * 4 + 2) / barWidth) % colors
        Protected p3.l = ((i * 4 + 3) / barWidth) % colors
        PokeA(ChrTab + y * 128 + i, (p0 << 6) | (p1 << 4) | (p2 << 2) | p3)
      Next i
    Next y
  Else
    colors = 16 : barWidth = 512 / colors
    For y = 0 To 211
      For i = 0 To 255 ; 256 bytes/row, 2 pixels/byte (4bpp)
        Protected q0.l = ((i * 2 + 0) / barWidth) % colors
        Protected q1.l = ((i * 2 + 1) / barWidth) % colors
        PokeA(ChrTab + y * 256 + i, (q0 << 4) | q1)
      Next i
    Next y
  EndIf

  ; One solid 8x8 sprite, color 15 (white in PalInit), at logical (X=20,Y=50).
  PokeA(SprTab + 0 + 0, 50) : PokeA(SprTab + 0 + 1, 20)
  PokeA(SprTab + 0 + 2, 0)  : PokeA(SprTab + 0 + 3, 15)
  For i = 0 To 7
    PokeA(SprGen + i, $FF)
  Next i
EndProcedure

Procedure RunTest(TestMode.l, OutPath.s)
  SetupModeTest(TestMode)
  Protected y.l
  For y = 0 To 211
    RefreshLine(y)
  Next y
  If WriteBMP(OutPath, 512, 212, @FrameBuffer())
    PrintN("OK: " + OutPath + " (ScrMode=" + Str(ScrMode) + ", esperado " + Str(TestMode) + ")")
  Else
    PrintN("FALHA ao escrever " + OutPath)
  EndIf
EndProcedure

Procedure Main()
  OpenConsole("fossauro SCREEN 6/7 Verification")
  Protected outDir.s = "."
  If CountProgramParameters() >= 1
    outDir = ProgramParameter(0)
  EndIf

  RunTest(6, outDir + "\screen6_test.bmp")
  RunTest(7, outDir + "\screen7_test.bmp")

  PrintN("Pressione Enter para sair...")
  Input()
  CloseConsole()
EndProcedure

Main()
