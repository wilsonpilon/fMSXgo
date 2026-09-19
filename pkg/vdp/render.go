package vdp

// RenderScanline refreshes a single scanline (0..261 NTSC or 0..312 PAL) into the FrameBuffer.
// In fMSXgo, the display buffer is 512x212 (native high-resolution) so that SCREEN 0 (80 cols),
// SCREEN 6, and SCREEN 7 render with pixel-perfect fidelity without dropping character columns.
func (v *VDP) RenderScanline(scanline int) {
	if len(v.VRAM) == 0 {
		return
	}

	maxVisLines := 192
	firstLine := 18 + v.VAdjust()
	if v.ScanLines212() {
		maxVisLines = 212
		firstLine = 8 + v.VAdjust()
	}

	bgCol := v.Palette.Colors[v.BGColor&0x0F]
	if !v.ScreenON() {
		// When screen is off, entire line is background color
		v.fillLineColor(scanline, bgCol)
		return
	}

	// In 192-line mode, clear top border (lines 0..9) and bottom border (lines 202..211)
	if scanline == 0 && !v.ScanLines212() {
		for l := 0; l < 10; l++ {
			v.fillDisplayLine(l, bgCol)
			v.fillDisplayLine(202+l, bgCol)
		}
	}

	// If outside active vertical display range, skip
	if scanline < firstLine || scanline >= firstLine+maxVisLines {
		return
	}

	y := scanline - firstLine
	if y < 0 || y >= maxVisLines {
		return
	}

	destY := y
	if !v.ScanLines212() {
		destY = y + 10 // Center 192 lines within 212 display height
	}
	if destY < 0 || destY >= DisplayHeight {
		return
	}

	// 512-dot scanline buffer storing color indices (0..15) or RGB 3:3:2 (for SCR 8)
	var lineBuf [ScreenWidth]uint8
	for i := range lineBuf {
		lineBuf[i] = v.BGColor & 0x0F
	}

	var customRGB [ScreenWidth]RGBA
	hasCustomRGB := false
	isScreen8 := false

	// Render based on active screen mode
	switch v.ScrMode {
	case 0:
		v.renderLine0(y, &lineBuf)
	case 1:
		v.renderLine1(y, &lineBuf)
		v.RenderSpritesMode1(y, &lineBuf)
	case 2:
		v.renderLine2(y, &lineBuf)
		v.RenderSpritesMode1(y, &lineBuf)
	case 3:
		v.renderLine3(y, &lineBuf)
		v.RenderSpritesMode1(y, &lineBuf)
	case 4:
		v.renderLine2(y, &lineBuf) // Screen 4 uses same pattern layout as Screen 2
		v.RenderSpritesMode2(y, &lineBuf)
	case 5:
		v.renderLine5(y, &lineBuf)
		v.RenderSpritesMode2(y, &lineBuf)
	case 6:
		v.renderLine6(y, &lineBuf)
		v.RenderSpritesMode2(y, &lineBuf)
	case 7:
		if v.ModeYJK() {
			hasCustomRGB = true
			if v.ModeYAE() {
				v.renderLineYAE(y, &customRGB)
			} else {
				v.renderLineYJK(y, &customRGB)
			}
		} else {
			v.renderLine7(y, &lineBuf)
		}
		v.RenderSpritesMode2(y, &lineBuf)
	case 8:
		if v.ModeYJK() {
			hasCustomRGB = true
			if v.ModeYAE() {
				v.renderLineYAE(y, &customRGB)
			} else {
				v.renderLineYJK(y, &customRGB)
			}
		} else {
			isScreen8 = true
			v.renderLine8(y, &lineBuf)
		}
	case 13: // TEXT 80
		v.renderLineTx80(y, &lineBuf)
	default:
		// Solid background
	}

	destRowStart := destY * DisplayWidth * 4

	for x := 0; x < ScreenWidth; x++ {
		idx := destRowStart + (x * 4)

		var pixCol RGBA
		if hasCustomRGB {
			pixCol = customRGB[x]
		} else if isScreen8 {
			pixCol = v.Palette.BPalTable[lineBuf[x]]
		} else {
			pixCol = v.Palette.Colors[lineBuf[x]&0x0F]
		}

		v.FrameBuffer[idx] = pixCol.R
		v.FrameBuffer[idx+1] = pixCol.G
		v.FrameBuffer[idx+2] = pixCol.B
		v.FrameBuffer[idx+3] = 255
	}
}

func (v *VDP) fillLineColor(scanline int, c RGBA) {
	if scanline < 0 || scanline >= DisplayHeight {
		return
	}
	v.fillDisplayLine(scanline, c)
}

func (v *VDP) fillDisplayLine(line int, c RGBA) {
	if line < 0 || line >= DisplayHeight {
		return
	}
	start := line * DisplayWidth * 4
	for x := 0; x < DisplayWidth; x++ {
		idx := start + (x * 4)
		v.FrameBuffer[idx] = c.R
		v.FrameBuffer[idx+1] = c.G
		v.FrameBuffer[idx+2] = c.B
		v.FrameBuffer[idx+3] = 255
	}
}

// renderLine0 renders SCREEN 0 (TEXT 40x24: 18 left margin + 40 cols x 12 dots + 14 right margin = 512).
// Directly mirrors fMSX Common.h:455-483 scaled to 512 dots.
func (v *VDP) renderLine0(y int, lineBuf *[ScreenWidth]uint8) {
	fc := v.FGColor & 0x0F
	bc := v.BGColor & 0x0F

	row := y >> 3
	subLine := (y + int(v.VScroll())) & 0x07
	tOffset := (v.ChrTab + (40 * row)) % len(v.VRAM)

	for x := 0; x < 18; x++ {
		lineBuf[x] = bc
	}

	pX := 18
	for col := 0; col < 40; col++ {
		charIdx := int(v.VRAM[(tOffset+col)%len(v.VRAM)])
		patAddr := (v.ChrGen + (charIdx << 3) + subLine) % len(v.VRAM)
		patByte := v.VRAM[patAddr]

		// 6 pixels per character, doubled to 12 dots horizontally (bits 7..2)
		mask := uint8(0x80)
		for bit := 0; bit < 6; bit++ {
			c := bc
			if (patByte & mask) != 0 {
				c = fc
			}
			lineBuf[pX] = c
			lineBuf[pX+1] = c
			mask >>= 1
			pX += 2
		}
	}

	for x := pX; x < ScreenWidth; x++ {
		lineBuf[x] = bc
	}
}

// renderLineTx80 renders SCREEN 0 in 80 columns (TEXT 80x24: 18 left margin + 80 cols x 6 dots + 14 right margin = 512).
// Implements full fMSX Wide.h:140-177 logic including ColTab color blink attributes.
func (v *VDP) renderLineTx80(y int, lineBuf *[ScreenWidth]uint8) {
	bc := v.BGColor & 0x0F

	row := y >> 3
	subLine := y & 0x07
	tOffset := (v.ChrTab + (80 * row)) & v.ChrTabM
	cOffset := (v.ColTab + (10 * row)) & v.ColTabM

	for x := 0; x < 18; x++ {
		lineBuf[x] = bc
	}

	pX := 18
	var m uint8
	cIdx := 0
	for col := 0; col < 80; col++ {
		if (col & 0x07) == 0 {
			m = v.VRAM[(cOffset+cIdx)%len(v.VRAM)]
			cIdx++
		}

		charFC := v.FGColor & 0x0F
		charBC := bc
		if (m & 0x80) != 0 {
			charFC = v.XFGColor & 0x0F
			charBC = v.XBGColor & 0x0F
		}
		m <<= 1

		charIdx := int(v.VRAM[(tOffset+col)%len(v.VRAM)])
		patAddr := (v.ChrGen + (charIdx << 3) + subLine) % len(v.VRAM)
		patByte := v.VRAM[patAddr]

		// 6 pixels per character (bits 7..2)
		mask := uint8(0x80)
		for bit := 0; bit < 6; bit++ {
			if (patByte & mask) != 0 {
				lineBuf[pX] = charFC
			} else {
				lineBuf[pX] = charBC
			}
			mask >>= 1
			pX++
		}
	}

	for x := pX; x < ScreenWidth; x++ {
		lineBuf[x] = bc
	}
}

// renderLine1 renders SCREEN 1 (TEXT 32x24, 256 pixels doubled horizontally to 512).
func (v *VDP) renderLine1(y int, lineBuf *[ScreenWidth]uint8) {
	yScroll := (y + int(v.VScroll())) & 0xFF
	row := yScroll >> 3
	subLine := yScroll & 0x07

	tOffset := (v.ChrTab + (row << 5)) % len(v.VRAM)

	pX := 0
	for col := 0; col < 32; col++ {
		charIdx := int(v.VRAM[(tOffset+col)%len(v.VRAM)])
		colEntry := v.VRAM[(v.ColTab+(charIdx>>3))%len(v.VRAM)]
		fc := colEntry >> 4
		bc := colEntry & 0x0F

		patAddr := (v.ChrGen + (charIdx << 3) + subLine) % len(v.VRAM)
		patByte := v.VRAM[patAddr]

		mask := uint8(0x80)
		for bit := 0; bit < 8; bit++ {
			c := bc
			if (patByte & mask) != 0 {
				c = fc
			}
			lineBuf[pX] = c
			lineBuf[pX+1] = c
			mask >>= 1
			pX += 2
		}
	}
}

// renderLine2 renders SCREEN 2 (GRAPHIC 1 / 256x192 tile mode doubled horizontally to 512).
func (v *VDP) renderLine2(y int, lineBuf *[ScreenWidth]uint8) {
	yScroll := (y + int(v.VScroll())) & 0xFF
	row := yScroll >> 3
	subLine := yScroll & 0x07

	tOffset := (v.ChrTab + (row << 5)) % len(v.VRAM)
	baseThird := ((yScroll & 0xC0) << 5) + subLine

	pX := 0
	for col := 0; col < 32; col++ {
		charIdx := int(v.VRAM[(tOffset+col)%len(v.VRAM)])
		offset := (charIdx << 3) + baseThird

		colAddr := (v.ColTab + (offset & v.ColTabM)) % len(v.VRAM)
		colByte := v.VRAM[colAddr]
		fc := colByte >> 4
		bc := colByte & 0x0F

		patAddr := (v.ChrGen + (offset & v.ChrGenM)) % len(v.VRAM)
		patByte := v.VRAM[patAddr]

		mask := uint8(0x80)
		for bit := 0; bit < 8; bit++ {
			c := bc
			if (patByte & mask) != 0 {
				c = fc
			}
			lineBuf[pX] = c
			lineBuf[pX+1] = c
			mask >>= 1
			pX += 2
		}
	}
}

// renderLine3 renders SCREEN 3 (MULTICOLOR 64x48 doubled horizontally to 512).
func (v *VDP) renderLine3(y int, lineBuf *[ScreenWidth]uint8) {
	yScroll := (y + int(v.VScroll())) & 0xFF
	row := yScroll >> 3
	subLine := (yScroll & 0x1C) >> 2

	tOffset := (v.ChrTab + (row << 5)) % len(v.VRAM)

	pX := 0
	for col := 0; col < 32; col++ {
		charIdx := int(v.VRAM[(tOffset+col)%len(v.VRAM)])
		patAddr := (v.ChrGen + (charIdx << 3) + subLine) % len(v.VRAM)
		patByte := v.VRAM[patAddr]

		c1 := patByte >> 4
		c2 := patByte & 0x0F

		for k := 0; k < 8; k++ {
			lineBuf[pX+k] = c1
		}
		for k := 0; k < 8; k++ {
			lineBuf[pX+8+k] = c2
		}
		pX += 16
	}
}

// renderLine5 renders SCREEN 5 (MSX2 256x192 16 colors: 4bpp, 128 bytes/line, doubled to 512).
func (v *VDP) renderLine5(y int, lineBuf *[ScreenWidth]uint8) {
	yAddr := (v.ChrTab + (((y + int(v.VScroll())) << 7) & v.ChrTabM & 0x7FFF)) % len(v.VRAM)
	pX := 0
	for byteIdx := 0; byteIdx < 128; byteIdx++ {
		addr := (yAddr + byteIdx) % len(v.VRAM)
		b := v.VRAM[addr]
		c1 := b >> 4
		c2 := b & 0x0F
		lineBuf[pX] = c1
		lineBuf[pX+1] = c1
		lineBuf[pX+2] = c2
		lineBuf[pX+3] = c2
		pX += 4
	}
}

// renderLine6 renders SCREEN 6 (MSX2 512x192 4 colors: 2bpp, 128 bytes/line, 512 pixels).
func (v *VDP) renderLine6(y int, lineBuf *[ScreenWidth]uint8) {
	yAddr := (v.ChrTab + (((y + int(v.VScroll())) << 7) & v.ChrTabM & 0x7FFF)) % len(v.VRAM)
	pX := 0
	for byteIdx := 0; byteIdx < 128; byteIdx++ {
		addr := (yAddr + byteIdx) % len(v.VRAM)
		b := v.VRAM[addr]
		lineBuf[pX] = (b >> 6) & 0x03
		lineBuf[pX+1] = (b >> 4) & 0x03
		lineBuf[pX+2] = (b >> 2) & 0x03
		lineBuf[pX+3] = b & 0x03
		pX += 4
	}
}

// renderLine7 renders SCREEN 7 (MSX2 512x192 16 colors: 4bpp, 256 bytes/line, 512 pixels).
func (v *VDP) renderLine7(y int, lineBuf *[ScreenWidth]uint8) {
	yAddr := (v.ChrTab + (((y + int(v.VScroll())) << 8) & v.ChrTabM & 0xFFFF)) % len(v.VRAM)
	pX := 0
	for byteIdx := 0; byteIdx < 256; byteIdx++ {
		addr := (yAddr + byteIdx) % len(v.VRAM)
		b := v.VRAM[addr]
		lineBuf[pX] = b >> 4
		lineBuf[pX+1] = b & 0x0F
		pX += 2
	}
}

// renderLine8 renders SCREEN 8 (MSX2 256x192 256 colors: 8bpp RGB 3:3:2, doubled to 512).
func (v *VDP) renderLine8(y int, lineBuf *[ScreenWidth]uint8) {
	yAddr := (v.ChrTab + (((y + int(v.VScroll())) << 8) & v.ChrTabM & 0xFFFF)) % len(v.VRAM)
	pX := 0
	for x := 0; x < 256; x++ {
		addr := (yAddr + x) % len(v.VRAM)
		b := v.VRAM[addr]
		lineBuf[pX] = b
		lineBuf[pX+1] = b
		pX += 2
	}
}

// YJKColor converts MSX2+ YJK components to RGB (identical to fMSX Common.h).
func YJKColor(Y, J, K int) RGBA {
	R := Y + J
	G := Y + K
	B := (5*Y - 2*J - K) / 4

	if R < 0 {
		R = 0
	} else if R > 31 {
		R = 31
	}
	if G < 0 {
		G = 0
	} else if G > 31 {
		G = 31
	}
	if B < 0 {
		B = 0
	} else if B > 31 {
		B = 31
	}

	return RGBA{
		R: uint8((((R & 0x1C) >> 2) * 255) / 7),
		G: uint8((((G & 0x1C) >> 2) * 255) / 7),
		B: uint8(((B >> 3) * 255) / 3),
		A: 255,
	}
}

// renderLineYJK renders SCREEN 12 (MSX2+ 256x192 19268 colors YJK, doubled horizontally to 512).
func (v *VDP) renderLineYJK(y int, customRGB *[ScreenWidth]RGBA) {
	yAddr := (v.ChrTab + (((y + int(v.VScroll())) << 8) & v.ChrTabM & 0xFFFF)) % len(v.VRAM)
	pX := 0
	for x := 0; x < 256; x += 4 {
		b0 := v.VRAM[(yAddr+x)%len(v.VRAM)]
		b1 := v.VRAM[(yAddr+x+1)%len(v.VRAM)]
		b2 := v.VRAM[(yAddr+x+2)%len(v.VRAM)]
		b3 := v.VRAM[(yAddr+x+3)%len(v.VRAM)]

		K := int(b0&0x07) | (int(b1&0x03) << 3)
		if K >= 16 {
			K -= 32
		}
		J := int(b2&0x07) | (int(b3&0x03) << 3)
		if J >= 16 {
			J -= 32
		}

		c0 := YJKColor(int(b0>>3), J, K)
		c1 := YJKColor(int(b1>>3), J, K)
		c2 := YJKColor(int(b2>>3), J, K)
		c3 := YJKColor(int(b3>>3), J, K)

		customRGB[pX] = c0
		customRGB[pX+1] = c0
		customRGB[pX+2] = c1
		customRGB[pX+3] = c1
		customRGB[pX+4] = c2
		customRGB[pX+5] = c2
		customRGB[pX+6] = c3
		customRGB[pX+7] = c3
		pX += 8
	}
}

// renderLineYAE renders SCREEN 10/11 (MSX2+ 256x192 YJK/YAE with 16-color palette attribute, doubled to 512).
func (v *VDP) renderLineYAE(y int, customRGB *[ScreenWidth]RGBA) {
	yAddr := (v.ChrTab + (((y + int(v.VScroll())) << 8) & v.ChrTabM & 0xFFFF)) % len(v.VRAM)
	pX := 0
	for x := 0; x < 256; x += 4 {
		b0 := v.VRAM[(yAddr+x)%len(v.VRAM)]
		b1 := v.VRAM[(yAddr+x+1)%len(v.VRAM)]
		b2 := v.VRAM[(yAddr+x+2)%len(v.VRAM)]
		b3 := v.VRAM[(yAddr+x+3)%len(v.VRAM)]

		K := int(b0&0x07) | (int(b1&0x03) << 3)
		if K >= 16 {
			K -= 32
		}
		J := int(b2&0x07) | (int(b3&0x03) << 3)
		if J >= 16 {
			J -= 32
		}

		bytes := [4]uint8{b0, b1, b2, b3}
		for i := 0; i < 4; i++ {
			bi := bytes[i]
			var c RGBA
			if (bi & 0x08) != 0 {
				palIdx := (bi >> 4) & 0x0F
				c = v.Palette.Colors[palIdx]
			} else {
				Y := int(bi >> 3)
				c = YJKColor(Y, J, K)
			}
			customRGB[pX] = c
			customRGB[pX+1] = c
			pX += 2
		}
	}
}
