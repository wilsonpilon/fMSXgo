package vdp

var sprHeights = [4]int{8, 16, 16, 32}

// RenderSpritesMode1 renders TMS9918 sprites (SCREEN 1..3) onto line buffer.
func (v *VDP) RenderSpritesMode1(y int, lineBuf *[DisplayWidth]uint8) {
	if v.SpritesOFF() || len(v.VRAM) == 0 {
		return
	}

	oh := sprHeights[v.Regs[1]&0x03] // Output height (zoom considered)
	ih := sprHeights[v.Regs[1]&0x02] // Input height (8 or 16)
	yScroll := (y + int(v.VScroll())) & 0xFF

	maxSprites := 4
	var markedSprites [32]bool
	spriteCount := 0
	lastChecked := 31

	// 1. Scan sprite table to find up to 4 sprites on this scanline
	for i := 0; i < 32; i++ {
		entry := (v.SprTab + (i * 4)) % len(v.VRAM)
		k := int(v.VRAM[entry])
		if k == 208 {
			lastChecked = i
			break
		}
		if k > 256-ih {
			k -= 256
		}

		if yScroll > k && yScroll <= k+oh {
			if spriteCount >= maxSprites {
				// 5th sprite detected on line
				v.Status[0] |= 0x40
				lastChecked = i
				break
			}
			markedSprites[i] = true
			spriteCount++
		}
	}

	// Record last checked sprite in S#0 bits 0..4
	v.Status[0] = (v.Status[0] &^ 0x1F) | uint8(lastChecked&0x1F)

	// 2. Draw marked sprites in reverse order (sprite 0 has highest priority)
	for i := 31; i >= 0; i-- {
		if !markedSprites[i] {
			continue
		}

		entry := (v.SprTab + (i * 4)) % len(v.VRAM)
		k := int(v.VRAM[entry])
		if k > 256-ih {
			k -= 256
		}
		x := int(v.VRAM[(entry+1)%len(v.VRAM)])
		pat := int(v.VRAM[(entry+2)%len(v.VRAM)])
		attr := v.VRAM[(entry+3)%len(v.VRAM)]

		if (attr & 0x80) != 0 {
			// Early clock: shift left by 32 pixels
			x -= 32
		}
		col := attr & 0x0F
		if col == 0 {
			// Color 0 is transparent for sprites
			continue
		}

		// Calculate row within sprite
		lineInSpr := yScroll - k - 1
		if oh > ih {
			lineInSpr >>= 1 // Zoomed 2x
		}

		var patAddr int
		if ih > 8 {
			// 16x16 sprite: pat is aligned to 4
			patAddr = (v.SprGen + ((pat & 0xFC) << 3) + lineInSpr) % len(v.VRAM)
		} else {
			// 8x8 sprite
			patAddr = (v.SprGen + (pat << 3) + lineInSpr) % len(v.VRAM)
		}

		b1 := v.VRAM[patAddr]
		var b2 uint8
		if ih > 8 {
			b2 = v.VRAM[(patAddr+16)%len(v.VRAM)]
		}

		// Draw pixels across scanline
		pattern16 := (uint16(b1) << 8) | uint16(b2)
		sprWidth := 8
		if ih > 8 {
			sprWidth = 16
		}
		if oh > ih {
			sprWidth *= 2 // Zoomed
		}

		for px := 0; px < sprWidth; px++ {
			sprX := x + px
			dotX := LeftBorder + (sprX * 2)

			// Check bit in pattern
			srcBit := px
			if oh > ih {
				srcBit >>= 1
			}
			mask := uint16(0x8000) >> srcBit

			if (pattern16 & mask) != 0 {
				if dotX >= LeftBorder && dotX < LeftBorder+ScreenWidth {
					lineBuf[dotX] = col
				}
				if dotX+1 >= LeftBorder && dotX+1 < LeftBorder+ScreenWidth {
					lineBuf[dotX+1] = col
				}
			}
		}
	}
}

// RenderSpritesMode2 renders V9938 color sprites (SCREEN 4..8) onto line buffer.
func (v *VDP) RenderSpritesMode2(y int, lineBuf *[DisplayWidth]uint8) {
	if v.SpritesOFF() || len(v.VRAM) == 0 {
		return
	}

	oh := sprHeights[v.Regs[1]&0x03]
	ih := sprHeights[v.Regs[1]&0x02]
	yScroll := y

	maxSprites := 8
	var markedSprites [32]bool
	spriteCount := 0
	lastChecked := 31

	// Scan sprite table
	for i := 0; i < 32; i++ {
		entry := (v.SprTab + (i * 4)) % len(v.VRAM)
		k := int(uint8(v.VRAM[entry] - v.VScroll()))
		if k == 216 {
			lastChecked = i
			break
		}
		if k > 256-ih {
			k -= 256
		}

		if yScroll > k && yScroll <= k+oh {
			if spriteCount >= maxSprites {
				// 9th sprite detected
				v.Status[0] |= 0x40
				lastChecked = i
				break
			}
			markedSprites[i] = true
			spriteCount++
		}
	}

	v.Status[0] = (v.Status[0] &^ 0x1F) | uint8(lastChecked&0x1F)

	// Draw sprites in reverse order (0 has priority)
	for i := 31; i >= 0; i-- {
		if !markedSprites[i] {
			continue
		}

		entry := (v.SprTab + (i * 4)) % len(v.VRAM)
		k := int(uint8(v.VRAM[entry] - v.VScroll()))
		if k > 256-ih {
			k -= 256
		}
		x := int(v.VRAM[(entry+1)%len(v.VRAM)])
		pat := int(v.VRAM[(entry+2)%len(v.VRAM)])

		lineInSpr := yScroll - k - 1
		if oh > ih {
			lineInSpr >>= 1
		}

		// Color table for Mode 2 is at SprTab - 512
		colorTableBase := (v.SprTab - 512 + (i * 16)) % len(v.VRAM)
		if colorTableBase < 0 {
			colorTableBase += len(v.VRAM)
		}
		colByte := v.VRAM[(colorTableBase+lineInSpr)%len(v.VRAM)]

		if (colByte & 0x80) != 0 {
			x -= 32
		}
		col := colByte & 0x0F
		if col == 0 {
			continue
		}

		var patAddr int
		if ih > 8 {
			patAddr = (v.SprGen + ((pat & 0xFC) << 3) + lineInSpr) % len(v.VRAM)
		} else {
			patAddr = (v.SprGen + (pat << 3) + lineInSpr) % len(v.VRAM)
		}

		b1 := v.VRAM[patAddr]
		var b2 uint8
		if ih > 8 {
			b2 = v.VRAM[(patAddr+16)%len(v.VRAM)]
		}

		pattern16 := (uint16(b1) << 8) | uint16(b2)
		sprWidth := 8
		if ih > 8 {
			sprWidth = 16
		}
		if oh > ih {
			sprWidth *= 2
		}

		for px := 0; px < sprWidth; px++ {
			sprX := x + px
			dotX := LeftBorder + (sprX * 2)

			srcBit := px
			if oh > ih {
				srcBit >>= 1
			}
			mask := uint16(0x8000) >> srcBit

			if (pattern16 & mask) != 0 {
				if (colByte & 0x40) != 0 {
					// CC bit set: OR color with existing pixel
					if dotX >= LeftBorder && dotX < LeftBorder+ScreenWidth {
						lineBuf[dotX] |= col
					}
					if dotX+1 >= LeftBorder && dotX+1 < LeftBorder+ScreenWidth {
						lineBuf[dotX+1] |= col
					}
				} else {
					if dotX >= LeftBorder && dotX < LeftBorder+ScreenWidth {
						lineBuf[dotX] = col
					}
					if dotX+1 >= LeftBorder && dotX+1 < LeftBorder+ScreenWidth {
						lineBuf[dotX+1] = col
					}
				}
			}
		}
	}
}

// CheckSprites detects collisions between displayed sprites.
func (v *VDP) CheckSprites() bool {
	if v.SpritesOFF() || v.ScrMode == 0 || v.ScrMode > 8 || len(v.VRAM) == 0 {
		return false
	}

	stopY := 208
	if v.ScrMode > 3 {
		stopY = 216
	}

	spr16 := v.Sprites16x16()
	sprSize := 8
	if spr16 {
		sprSize = 16
	}

	type activeSpr struct {
		x, y int
		pat  int
	}
	var list []activeSpr

	for i := 0; i < 32; i++ {
		entry := (v.SprTab + (i * 4)) % len(v.VRAM)
		y := int(v.VRAM[entry])
		if y == stopY {
			break
		}
		if y > 256-sprSize {
			y -= 256
		}
		x := int(v.VRAM[(entry+1)%len(v.VRAM)])
		pat := int(v.VRAM[(entry+2)%len(v.VRAM)])
		attr := v.VRAM[(entry+3)%len(v.VRAM)]
		if (attr & 0x80) != 0 {
			x -= 32
		}
		list = append(list, activeSpr{x: x, y: y, pat: pat})
	}

	// Compare pairs of sprites
	for i := 0; i < len(list); i++ {
		for j := i + 1; j < len(list); j++ {
			s1 := list[i]
			s2 := list[j]

			// Check bounding box overlap
			dx := s1.x - s2.x
			dy := s1.y - s2.y
			if dx < sprSize && dx > -sprSize && dy < sprSize && dy > -sprSize {
				return true
			}
		}
	}

	return false
}
