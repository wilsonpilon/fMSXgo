package vdp

import "image/color"

// RGBA represents a 32-bit RGBA color.
type RGBA struct {
	R, G, B, A uint8
}

// TMS9918DefaultPalette contains standard MSX1 16-color palette.
var TMS9918DefaultPalette = [16]RGBA{
	{0, 0, 0, 0},         // 0: Transparent
	{0, 0, 0, 255},       // 1: Black
	{33, 200, 66, 255},   // 2: Medium Green
	{94, 220, 120, 255},  // 3: Light Green
	{84, 85, 237, 255},   // 4: Dark Blue
	{125, 118, 252, 255}, // 5: Light Blue
	{212, 82, 77, 255},   // 6: Dark Red
	{66, 235, 245, 255},  // 7: Cyan
	{252, 85, 84, 255},   // 8: Medium Red
	{255, 121, 120, 255}, // 9: Light Red
	{212, 193, 84, 255},  // 10: Dark Yellow
	{230, 206, 128, 255}, // 11: Light Yellow
	{33, 176, 59, 255},   // 12: Dark Green
	{201, 91, 186, 255},  // 13: Magenta
	{204, 204, 204, 255}, // 14: Gray
	{255, 255, 255, 255}, // 15: White
}

// V9938DefaultPaletteRaw contains the default power-on 3-bit RGB values for V9938 (R:3, G:3, B:3).
var V9938DefaultPaletteRaw = [16][3]uint8{
	{0, 0, 0}, // 0: Transparent
	{0, 0, 0}, // 1: Black
	{1, 6, 1}, // 2: Medium Green
	{3, 7, 3}, // 3: Light Green
	{1, 1, 7}, // 4: Dark Blue
	{2, 3, 7}, // 5: Light Blue
	{5, 1, 1}, // 6: Dark Red
	{2, 6, 7}, // 7: Cyan
	{7, 1, 1}, // 8: Medium Red
	{7, 3, 3}, // 9: Light Red
	{6, 6, 1}, // 10: Dark Yellow
	{6, 6, 4}, // 11: Light Yellow
	{1, 4, 1}, // 12: Dark Green
	{6, 2, 5}, // 13: Magenta
	{5, 5, 5}, // 14: Gray
	{7, 7, 7}, // 15: White
}

// Palette manages 16 colors for VDP display rendering.
type Palette struct {
	Colors    [16]RGBA
	RawRGB    [16][3]uint8 // 3-bit values (0..7)
	BPalTable [256]RGBA    // Fast lookup for SCREEN 8 (RGB 3:3:2)
}

// NewPalette initializes a palette with standard MSX defaults.
func NewPalette() *Palette {
	p := &Palette{}
	p.Reset()
	return p
}

// Reset restores palette to initial MSX values.
func (p *Palette) Reset() {
	for i := 0; i < 16; i++ {
		raw := V9938DefaultPaletteRaw[i]
		p.SetColor3Bit(i, raw[0], raw[1], raw[2])
	}
	// Init SCREEN 8 (256 color RGB 3:3:2) lookup table
	for c := 0; c < 256; c++ {
		r3 := (uint8(c) >> 5) & 0x07
		g3 := (uint8(c) >> 2) & 0x07
		b2 := uint8(c) & 0x03

		p.BPalTable[c] = RGBA{
			R: uint8((int(r3) * 255) / 7),
			G: uint8((int(g3) * 255) / 7),
			B: uint8((int(b2) * 255) / 3),
			A: 255,
		}
	}
}

// SetColor3Bit sets palette entry with 3-bit values (0..7).
func (p *Palette) SetColor3Bit(idx int, r, g, b uint8) {
	if idx < 0 || idx >= 16 {
		return
	}
	r &= 0x07
	g &= 0x07
	b &= 0x07
	p.RawRGB[idx] = [3]uint8{r, g, b}

	r8 := uint8((int(r) * 255) / 7)
	g8 := uint8((int(g) * 255) / 7)
	b8 := uint8((int(b) * 255) / 7)

	alpha := uint8(255)
	if idx == 0 {
		alpha = 0 // Transparent by default, can be forced solid via SolidColor0
	}

	p.Colors[idx] = RGBA{R: r8, G: g8, B: b8, A: alpha}
}

// GetColor returns color.RGBA for drawing.
func (p *Palette) GetColor(idx int) color.RGBA {
	c := p.Colors[idx&0x0F]
	return color.RGBA{R: c.R, G: c.G, B: c.B, A: c.A}
}
