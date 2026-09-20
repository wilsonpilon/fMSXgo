package vdp

import (
	"testing"
)

func TestHScrollScreen5(t *testing.T) {
	v := New(2, 2)
	v.ScrMode = 5 // SCREEN 5 (256x192 16-color bitmap)

	// Fill line 0 of VRAM with known nibbles:
	// byte 0 has high nibble 1, low nibble 2 -> pixels 0, 1
	// byte 1 has high nibble 3, low nibble 4 -> pixels 2, 3
	// byte 2 has high nibble 5, low nibble 6 -> pixels 4, 5
	v.VRAM[0] = 0x12
	v.VRAM[1] = 0x34
	v.VRAM[2] = 0x56

	var lineBuf [ScreenWidth]uint8

	// 1. Without scroll (HScroll = 0)
	v.Regs[26] = 0
	v.Regs[27] = 0
	v.renderLine5(0, &lineBuf)

	// Pixels doubled: lineBuf[0,1] = 1, lineBuf[2,3] = 2, lineBuf[4,5] = 3, lineBuf[6,7] = 4
	if lineBuf[0] != 1 || lineBuf[1] != 1 {
		t.Fatalf("Expected pixel 0 to be 1, got %d", lineBuf[0])
	}
	if lineBuf[2] != 2 || lineBuf[3] != 2 {
		t.Fatalf("Expected pixel 1 to be 2, got %d", lineBuf[2])
	}

	// 2. Fine horizontal scroll: scroll by 1 pixel (R#27 = 1)
	v.Regs[27] = 1
	v.renderLine5(0, &lineBuf)

	// When scrolled by 1, display pixel 0 shows source pixel 1 (which is nibble 2)
	// display pixel 1 shows source pixel 2 (which is nibble 3)
	if lineBuf[0] != 2 || lineBuf[1] != 2 {
		t.Fatalf("Expected pixel 0 after fine scroll by 1 to be 2, got %d", lineBuf[0])
	}
	if lineBuf[2] != 3 || lineBuf[3] != 3 {
		t.Fatalf("Expected pixel 1 after fine scroll by 1 to be 3, got %d", lineBuf[2])
	}

	// 3. Coarse scroll: scroll by 8 pixels (R#26 = 1, R#27 = 0)
	v.Regs[26] = 1
	v.Regs[27] = 0
	// Fill byte 4 (source pixel 8, 9) with 0x78
	v.VRAM[4] = 0x78
	v.renderLine5(0, &lineBuf)

	if lineBuf[0] != 7 || lineBuf[1] != 7 {
		t.Fatalf("Expected pixel 0 after coarse scroll by 8 to be 7, got %d", lineBuf[0])
	}

	// 4. Test Left Mask (R#25 bit 1 = 1)
	v.Regs[25] = 0x02 // MSK
	v.Regs[7] = 0x09  // Border color 9
	v.renderLine5(0, &lineBuf)

	// First 16 buffer pixels (8 screen dots) should be masked to border color 9
	for i := 0; i < 16; i++ {
		if lineBuf[i] != 9 {
			t.Fatalf("Expected masked pixel %d to be border color 9, got %d", i, lineBuf[i])
		}
	}
}

func TestHScrollScreen8(t *testing.T) {
	v := New(2, 2)
	v.ScrMode = 8 // SCREEN 8 (256x192 256 colors)

	v.VRAM[0] = 42
	v.VRAM[1] = 43
	v.VRAM[2] = 44

	var lineBuf [ScreenWidth]uint8

	// Normal
	v.Regs[26] = 0
	v.Regs[27] = 0
	v.renderLine8(0, &lineBuf)
	if lineBuf[0] != 42 || lineBuf[2] != 43 {
		t.Fatalf("SCREEN 8 without scroll: got %d, %d", lineBuf[0], lineBuf[2])
	}

	// Scroll by 2 pixels
	v.Regs[27] = 2
	v.renderLine8(0, &lineBuf)
	if lineBuf[0] != 44 {
		t.Fatalf("SCREEN 8 scrolled by 2: expected 44, got %d", lineBuf[0])
	}
}

func TestHScrollScreen7(t *testing.T) {
	v := New(2, 2)
	v.ScrMode = 7 // SCREEN 7 (512x192 16 colors)

	v.VRAM[0] = 0xAB // pixel 0 = A, pixel 1 = B
	v.VRAM[1] = 0xCD // pixel 2 = C, pixel 3 = D

	var lineBuf [ScreenWidth]uint8

	v.Regs[26] = 0
	v.Regs[27] = 0
	v.renderLine7(0, &lineBuf)
	if lineBuf[0] != 0x0A || lineBuf[1] != 0x0B {
		t.Fatalf("SCREEN 7 without scroll: got %X, %X", lineBuf[0], lineBuf[1])
	}

	// Scroll by 1
	v.Regs[27] = 1
	v.renderLine7(0, &lineBuf)
	if lineBuf[0] != 0x0B || lineBuf[1] != 0x0C {
		t.Fatalf("SCREEN 7 scrolled by 1: got %X, %X", lineBuf[0], lineBuf[1])
	}
}
