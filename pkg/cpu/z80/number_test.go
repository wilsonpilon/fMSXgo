package z80

import (
	"bytes"
	"testing"
)

func TestParseNumberStandard(t *testing.T) {
	tests := []struct {
		input    string
		expected uint64
	}{
		// 1. Default Hexadecimal (no prefix/suffix)
		{"0", 0},
		{"10", 0x10},
		{"20", 0x20},
		{"FF", 0xFF},
		{"ff", 0xFF},
		{"C000", 0xC000},
		{"c000", 0xC000},
		{"B000", 0xB000},
		{"D000", 0xD000},
		{"DE00", 0xDE00},
		{"BC00", 0xBC00},

		// 2. Binary prefix 'b' / 'B'
		{"b0", 0},
		{"b1", 1},
		{"b10", 2},
		{"b1010", 10},
		{"B1010", 10},
		{"b11110000", 0xF0},
		{"%1010", 10},
		{"0b1010", 10},
		{"1010b", 10},
		{"1010B", 10},

		// 3. Decimal prefix 'd' / 'D'
		{"d0", 0},
		{"d10", 10},
		{"D10", 10},
		{"d20", 20},
		{"d255", 255},
		{"d1000", 1000},
		{"D65535", 65535},
		{"#10", 10},
		{"10d", 10},
		{"255D", 255},

		// 4. Hexadecimal prefix 'h' / 'H'
		{"h0", 0},
		{"h10", 0x10},
		{"H10", 0x10},
		{"hC000", 0xC000},
		{"HC000", 0xC000},
		{"$C000", 0xC000},
		{"0xC000", 0xC000},
		{"10h", 0x10},
		{"C000H", 0xC000},

		// 5. Octal prefix 'o' / 'O'
		{"o0", 0},
		{"o12", 10},
		{"O12", 10},
		{"o77", 63},
		{"O77", 63},
		{"0o77", 63},
		{"@77", 63},
		{"77o", 63},
		{"77q", 63},
		{"77Q", 63},
	}

	for _, tc := range tests {
		val, err := ParseNumber(tc.input)
		if err != nil {
			t.Errorf("ParseNumber(%q) error: %v", tc.input, err)
			continue
		}
		if val != tc.expected {
			t.Errorf("ParseNumber(%q) = %d (0x%X), expected %d (0x%X)",
				tc.input, val, val, tc.expected, tc.expected)
		}
	}
}

func TestMiniAssemblerBasePrefixes(t *testing.T) {
	// Test that the mini-assembler correctly adheres to:
	// - Default hex (e.g. 10 -> 0x10)
	// - b -> binary (e.g. b1010 -> 0x0A)
	// - d -> decimal (e.g. d10 -> 0x0A)
	// - o -> octal (e.g. o12 -> 0x0A)
	// - h -> hex (e.g. h10 -> 0x10)
	pc := uint16(0x0100)

	// 1. Default hex immediate
	b1, err := AssembleLine(pc, "LD A, 10")
	if err != nil || !bytes.Equal(b1, []byte{0x3E, 0x10}) {
		t.Fatalf("Expected LD A, 10 to assemble to [3E 10], got %X (err: %v)", b1, err)
	}

	// 2. Decimal prefix 'd'
	b2, err := AssembleLine(pc, "LD A, d10")
	if err != nil || !bytes.Equal(b2, []byte{0x3E, 0x0A}) {
		t.Fatalf("Expected LD A, d10 to assemble to [3E 0A], got %X (err: %v)", b2, err)
	}

	// 3. Binary prefix 'b'
	b3, err := AssembleLine(pc, "LD A, b1010")
	if err != nil || !bytes.Equal(b3, []byte{0x3E, 0x0A}) {
		t.Fatalf("Expected LD A, b1010 to assemble to [3E 0A], got %X (err: %v)", b3, err)
	}

	// 4. Octal prefix 'o'
	b4, err := AssembleLine(pc, "LD A, o12")
	if err != nil || !bytes.Equal(b4, []byte{0x3E, 0x0A}) {
		t.Fatalf("Expected LD A, o12 to assemble to [3E 0A], got %X (err: %v)", b4, err)
	}

	// 5. Hex prefix 'h'
	b5, err := AssembleLine(pc, "LD A, h10")
	if err != nil || !bytes.Equal(b5, []byte{0x3E, 0x10}) {
		t.Fatalf("Expected LD A, h10 to assemble to [3E 10], got %X (err: %v)", b5, err)
	}

	// 6. 16-bit register load with decimal vs hex
	b6, err := AssembleLine(pc, "LD BC, d1000")
	if err != nil || !bytes.Equal(b6, []byte{0x01, 0xE8, 0x03}) {
		t.Fatalf("Expected LD BC, d1000 to assemble to [01 E8 03], got %X (err: %v)", b6, err)
	}

	b7, err := AssembleLine(pc, "LD BC, 1000")
	if err != nil || !bytes.Equal(b7, []byte{0x01, 0x00, 0x10}) {
		t.Fatalf("Expected LD BC, 1000 to assemble to [01 00 10], got %X (err: %v)", b7, err)
	}

	// 7. DB directive with mixed bases
	b8, err := AssembleLine(pc, "DB 10, d10, b1010, o12, h10")
	if err != nil || !bytes.Equal(b8, []byte{0x10, 0x0A, 0x0A, 0x0A, 0x10}) {
		t.Fatalf("Expected DB with mixed bases to assemble to [10 0A 0A 0A 10], got %X (err: %v)", b8, err)
	}
}
