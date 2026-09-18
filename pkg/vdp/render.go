package vdp

// RenderScanline refreshes a single scanline (0..261 NTSC or 0..312 PAL) into the FrameBuffer.
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

	// Border color
	bgCol := v.Palette.Colors[v.BGColor&0x0F]
	if !v.ScreenON() {
		// When screen is off, entire line is background color
		v.fillLineColor(scanline, bgCol)
		return
	}

	// If outside active vertical display range, render border line
	if scanline < firstLine || scanline >= firstLine+maxVisLines {
		if scanline < DisplayHeight {
			v.fillLineColor(scanline, bgCol)
		}
		return
	}

	y := scanline - firstLine
	if y < 0 || y >= maxVisLines {
		return
	}

	// 256-pixel scanline buffer storing color indices (0..15) or RGB 3:3:2 (for SCR 8)
	var lineBuf [ScreenWidth]uint8
	for i := range lineBuf {
		lineBuf[i] = v.BGColor & 0x0F
	}

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
		v.renderLine7(y, &lineBuf)
		v.RenderSpritesMode2(y, &lineBuf)
	case 8:
		isScreen8 = true
		v.renderLine8(y, &lineBuf)
	case 13: // TEXT 80
		v.renderLineTx80(y, &lineBuf)
	default:
		// Fallback to solid background
	}

	// Transfer lineBuf to FrameBuffer with left/right borders and HAdjust
	leftBorder := (DisplayWidth - ScreenWidth) / 2 + v.HAdjust()
	rightBorder := leftBorder + ScreenWidth

	destY := scanline
	if destY >= DisplayHeight {
		return
	}

	destRowStart := destY * DisplayWidth * 4

	// 1. Left border
	for x := 0; x < leftBorder && x < DisplayWidth; x++ {
		idx := destRowStart + (x * 4)
		v.FrameBuffer[idx] = bgCol.R
		v.FrameBuffer[idx+1] = bgCol.G
		v.FrameBuffer[idx+2] = bgCol.B
		v.FrameBuffer[idx+3] = 255
	}

	// 2. Active 256 pixels
	for x := 0; x < ScreenWidth; x++ {
		destX := leftBorder + x
		if destX < 0 || destX >= DisplayWidth {
			continue
		}
		idx := destRowStart + (destX * 4)

		var pixCol RGBA
		if isScreen8 {
			pixCol = v.Palette.BPalTable[lineBuf[x]]
		} else {
			pixCol = v.Palette.Colors[lineBuf[x]&0x0F]
		}

		v.FrameBuffer[idx] = pixCol.R
		v.FrameBuffer[idx+1] = pixCol.G
		v.FrameBuffer[idx+2] = pixCol.B
		v.FrameBuffer[idx+3] = 255
	}

	// 3. Right border
	for x := rightBorder; x < DisplayWidth; x++ {
		if x < 0 {
			continue
		}
		idx := destRowStart + (x * 4)
		v.FrameBuffer[idx] = bgCol.R
		v.FrameBuffer[idx+1] = bgCol.G
		v.FrameBuffer[idx+2] = bgCol.B
		v.FrameBuffer[idx+3] = 255
	}
}

func (v *VDP) fillLineColor(scanline int, c RGBA) {
	if scanline < 0 || scanline >= DisplayHeight {
		return
	}
	start := scanline * DisplayWidth * 4
	for x := 0; x < DisplayWidth; x++ {
		idx := start + (x * 4)
		v.FrameBuffer[idx] = c.R
		v.FrameBuffer[idx+1] = c.G
		v.FrameBuffer[idx+2] = c.B
		v.FrameBuffer[idx+3] = 255
	}
}

// renderLine0 renders SCREEN 0 (TEXT 40x24: 40 cols x 6 pixels = 240 pixels + 8 left/right pad).
func (v *VDP) renderLine0(y int, lineBuf *[ScreenWidth]uint8) {
	fc := v.FGColor & 0x0F
	bc := v.BGColor & 0x0F

	row := y >> 3
	subLine := (y + int(v.VScroll())) & 0x07

	// Center 240 pixels within 256 width (8 pixels padding on each side)
	tOffset := (v.ChrTab + (40 * row)) % len(v.VRAM)
	pX := 8

	for col := 0; col < 40; col++ {
		charIdx := int(v.VRAM[(tOffset+col)%len(v.VRAM)])
		patAddr := (v.ChrGen + (charIdx << 3) + subLine) % len(v.VRAM)
		patByte := v.VRAM[patAddr]

		// 6 pixels per character in 40-column mode (bits 7..2)
		mask := uint8(0x80)
		for bit := 0; bit < 6; bit++ {
			if (patByte & mask) != 0 {
				lineBuf[pX] = fc
			} else {
				lineBuf[pX] = bc
			}
			mask >>= 1
			pX++
		}
	}
}

// renderLineTx80 renders SCREEN 0 in 80 columns (TEXT 80x24, compressed to 256 or 4 pixels/char).
func (v *VDP) renderLineTx80(y int, lineBuf *[ScreenWidth]uint8) {
	fc := v.FGColor & 0x0F
	bc := v.BGColor & 0x0F

	row := y >> 3
	subLine := (y + int(v.VScroll())) & 0x07
	tOffset := (v.ChrTab + (80 * row)) % len(v.VRAM)

	pX := 8
	for col := 0; col < 80 && pX < ScreenWidth-8; col++ {
		charIdx := int(v.VRAM[(tOffset+col)%len(v.VRAM)])
		patAddr := (v.ChrGen + (charIdx << 3) + subLine) % len(v.VRAM)
		patByte := v.VRAM[patAddr]

		// In 256 pixel buffer, sample 3 pixels per character
		if (patByte & 0x80) != 0 {
			lineBuf[pX] = fc
		} else {
			lineBuf[pX] = bc
		}
		if (patByte & 0x40) != 0 {
			lineBuf[pX+1] = fc
		} else {
			lineBuf[pX+1] = bc
		}
		if (patByte & 0x20) != 0 {
			lineBuf[pX+2] = fc
		} else {
			lineBuf[pX+2] = bc
		}
		pX += 3
	}
}

// renderLine1 renders SCREEN 1 (TEXT 32x24).
func (v *VDP) renderLine1(y int, lineBuf *[ScreenWidth]uint8) {
	yScroll := (y + int(v.VScroll())) & 0xFF
	row := yScroll >> 3
	subLine := yScroll & 0x07

	tOffset := (v.ChrTab + (row << 5)) % len(v.VRAM)

	pX := 0
	for col := 0; col < 32; col++ {
		charIdx := int(v.VRAM[(tOffset+col)%len(v.VRAM)])
		// Color table in Screen 1 has 32 entries (each byte controls 8 character codes)
		colEntry := v.VRAM[(v.ColTab+(charIdx>>3))%len(v.VRAM)]
		fc := colEntry >> 4
		bc := colEntry & 0x0F

		patAddr := (v.ChrGen + (charIdx << 3) + subLine) % len(v.VRAM)
		patByte := v.VRAM[patAddr]

		mask := uint8(0x80)
		for bit := 0; bit < 8; bit++ {
			if (patByte & mask) != 0 {
				lineBuf[pX] = fc
			} else {
				lineBuf[pX] = bc
			}
			mask >>= 1
			pX++
		}
	}
}

// renderLine2 renders SCREEN 2 (GRAPHIC 1 / 256x192 tile mode).
func (v *VDP) renderLine2(y int, lineBuf *[ScreenWidth]uint8) {
	yScroll := (y + int(v.VScroll())) & 0xFF
	row := yScroll >> 3
	subLine := yScroll & 0x07

	tOffset := (v.ChrTab + (row << 5)) % len(v.VRAM)
	// Base address for pattern generator & color table per 8-row third of the screen
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
			if (patByte & mask) != 0 {
				lineBuf[pX] = fc
			} else {
				lineBuf[pX] = bc
			}
			mask >>= 1
			pX++
		}
	}
}

// renderLine3 renders SCREEN 3 (MULTICOLOR 64x48).
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

		// Left 4 pixels
		lineBuf[pX] = c1
		lineBuf[pX+1] = c1
		lineBuf[pX+2] = c1
		lineBuf[pX+3] = c1
		// Right 4 pixels
		lineBuf[pX+4] = c2
		lineBuf[pX+5] = c2
		lineBuf[pX+6] = c2
		lineBuf[pX+7] = c2
		pX += 8
	}
}

// renderLine5 renders SCREEN 5 (MSX2 256x192 16 colors: 4bpp, 128 bytes/line).
func (v *VDP) renderLine5(y int, lineBuf *[ScreenWidth]uint8) {
	yAddr := (y & 1023) << 7
	pX := 0
	for byteIdx := 0; byteIdx < 128; byteIdx++ {
		addr := (yAddr + byteIdx) % len(v.VRAM)
		b := v.VRAM[addr]
		lineBuf[pX] = b >> 4
		lineBuf[pX+1] = b & 0x0F
		pX += 2
	}
}

// renderLine6 renders SCREEN 6 (MSX2 512x192 4 colors: 2bpp, 128 bytes/line, averaged to 256).
func (v *VDP) renderLine6(y int, lineBuf *[ScreenWidth]uint8) {
	yAddr := (y & 1023) << 7
	pX := 0
	for byteIdx := 0; byteIdx < 128; byteIdx++ {
		addr := (yAddr + byteIdx) % len(v.VRAM)
		b := v.VRAM[addr]
		lineBuf[pX] = (b >> 6) & 0x03
		lineBuf[pX+1] = (b >> 2) & 0x03
		pX += 2
	}
}

// renderLine7 renders SCREEN 7 (MSX2 512x192 16 colors: 4bpp, 256 bytes/line, averaged to 256).
func (v *VDP) renderLine7(y int, lineBuf *[ScreenWidth]uint8) {
	yAddr := (y & 511) << 8
	for x := 0; x < ScreenWidth; x++ {
		addr := (yAddr + x) % len(v.VRAM)
		b := v.VRAM[addr]
		lineBuf[x] = b >> 4
	}
}

// renderLine8 renders SCREEN 8 (MSX2 256x192 256 colors: 8bpp RGB 3:3:2).
func (v *VDP) renderLine8(y int, lineBuf *[ScreenWidth]uint8) {
	yAddr := (y & 511) << 8
	for x := 0; x < ScreenWidth; x++ {
		addr := (yAddr + x) % len(v.VRAM)
		lineBuf[x] = v.VRAM[addr]
	}
}
