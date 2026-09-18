package vdp_test

import (
	"testing"

	"fmsxgo/pkg/vdp"
)

func TestVDPPortsAndVRAM(t *testing.T) {
	v := vdp.New(vdp.ModelMSX2, 8)

	// Set address to 0x1234 for writing (bit 6 = 1, bit 7 = 0 in second byte)
	v.WriteControl(0x34) // LSB
	v.WriteControl(0x40 | 0x12) // MSB with write flag

	if v.VAddr != 0x1234 {
		t.Fatalf("expected VAddr 0x1234, got %04X", v.VAddr)
	}

	// Write 4 bytes
	v.WriteData(0xAA)
	v.WriteData(0xBB)
	v.WriteData(0xCC)
	v.WriteData(0xDD)

	if v.VAddr != 0x1238 {
		t.Fatalf("expected VAddr 0x1238 after writes, got %04X", v.VAddr)
	}

	// Set address to 0x1234 for reading (bit 6 = 0, bit 7 = 0)
	v.WriteControl(0x34)
	v.WriteControl(0x12)

	// First ReadData returns prefetched byte (0xAA)
	d0 := v.ReadData()
	if d0 != 0xAA {
		t.Errorf("expected read byte 0xAA, got %02X", d0)
	}

	d1 := v.ReadData()
	if d1 != 0xBB {
		t.Errorf("expected read byte 0xBB, got %02X", d1)
	}

	d2 := v.ReadData()
	if d2 != 0xCC {
		t.Errorf("expected read byte 0xCC, got %02X", d2)
	}

	d3 := v.ReadData()
	if d3 != 0xDD {
		t.Errorf("expected read byte 0xDD, got %02X", d3)
	}
}

func TestVDPRegisterAndPalette(t *testing.T) {
	v := vdp.New(vdp.ModelMSX2, 8)

	// Set R#7 (Colors) via Port 0x99: val, 0x80 | 7
	v.WriteControl(0x14) // FG=1 (black), BG=4 (dark blue)
	v.WriteControl(0x80 | 7)

	if v.FGColor != 1 || v.BGColor != 4 {
		t.Errorf("expected FG=1 BG=4, got FG=%d BG=%d", v.FGColor, v.BGColor)
	}

	// Set palette entry 2 via Port 0x9A:
	// First set R#16 to 2
	v.WriteControl(2)
	v.WriteControl(0x80 | 16)

	// Write R=7, B=0, G=7 (Yellow)
	// Byte 1: (R << 4) | B = (7 << 4) | 0 = 0x70
	// Byte 2: G = 7 = 0x07
	v.WritePalette(0x70)
	v.WritePalette(0x07)

	col := v.Palette.Colors[2]
	if col.R != 255 || col.G != 255 || col.B != 0 {
		t.Errorf("expected RGB (255, 255, 0), got (%d, %d, %d)", col.R, col.G, col.B)
	}
}

func TestVDPScreenModeSwitch(t *testing.T) {
	v := vdp.New(vdp.ModelMSX2, 8)

	// Set SCREEN 2: VDP[0] bit 1 = 1 (0x02), VDP[1] bit 4 = 0 (0x00) -> code 0x01
	v.VDPOut(0, 0x02)
	v.VDPOut(1, 0x00)

	if v.ScrMode != 2 {
		t.Errorf("expected Screen Mode 2, got %d", v.ScrMode)
	}

	// Set SCREEN 0: VDP[0] = 0, VDP[1] = 0x10 -> code 0x10
	v.VDPOut(0, 0x00)
	v.VDPOut(1, 0x10)

	if v.ScrMode != 0 {
		t.Errorf("expected Screen Mode 0, got %d", v.ScrMode)
	}
}

func TestVDPRenderScanline(t *testing.T) {
	v := vdp.New(vdp.ModelMSX2, 8)
	v.VDPOut(1, 0x40) // Screen ON
	v.VDPOut(7, 0xF4) // FG=15 (white), BG=4 (blue)

	// Render scanlines across visible display
	for line := 0; line < vdp.DisplayHeight; line++ {
		v.RenderScanline(line)
	}

	// Verify that the frame buffer has non-zero bytes (blue background or white)
	hasNonZero := false
	for _, b := range v.FrameBuffer {
		if b > 0 {
			hasNonZero = true
			break
		}
	}

	if !hasNonZero {
		t.Fatal("expected FrameBuffer to contain rendered pixels, but was all zero")
	}
}

func TestVDPSpritesCollision(t *testing.T) {
	v := vdp.New(vdp.ModelMSX1, 2)
	v.VDPOut(1, 0x40) // Screen ON
	v.VDPOut(0, 0x02) // Screen 2

	// Setup 2 sprites at identical (X, Y) = (50, 50)
	// Sprite 0
	v.VRAM[v.SprTab+0] = 50
	v.VRAM[v.SprTab+1] = 50
	v.VRAM[v.SprTab+2] = 0
	v.VRAM[v.SprTab+3] = 15

	// Sprite 1
	v.VRAM[v.SprTab+4] = 50
	v.VRAM[v.SprTab+5] = 50
	v.VRAM[v.SprTab+6] = 1
	v.VRAM[v.SprTab+7] = 15

	// Terminator at sprite 2
	v.VRAM[v.SprTab+8] = 208

	// Check collision
	collided := v.CheckSprites()
	if !collided {
		t.Errorf("expected sprite collision between sprite 0 and sprite 1 at same coordinates")
	}
}
