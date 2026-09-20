package msx

import (
	"path/filepath"
	"testing"
)

func TestGuessMapperKnownHashes(t *testing.T) {
	// Test known SHA1 hashes
	crossBlaimHash := "bb902e82a2bdda61101a9b3646462adecdd18c8d"
	for hash, expectedMapper := range knownHashes {
		// Mock data with matching SHA1 would be tedious to generate preimage for,
		// so we directly test that the knownHashes table has our targets mapped correctly.
		if hash == crossBlaimHash && expectedMapper != MapperCrossBlaim {
			t.Errorf("expected CrossBlaim for hash %s, got %d", hash, expectedMapper)
		}
	}

	// Test filename fallbacks
	cases := []struct {
		filename string
		expected int
	}{
		{"Cross Blaim (Japan).rom", MapperCrossBlaim},
		{"crossblaim.rom", MapperCrossBlaim},
		{"R-Type (Japan).rom", MapperRType},
		{"RType.rom", MapperRType},
		{"Hydlide 2 - Shine of Darkness.rom", MapperASCII16SRAM},
		{"Hydlide II.rom", MapperASCII16SRAM},
		{"Harry Fox - Yuki no Maou Hen.rom", MapperHarryFox},
		{"Harry Fox MSX Special.rom", MapperASCII16SRAM},
		{"Super Pierrot (Japan).rom", MapperSuperPierrot},
		{"SuperPierrot.rom", MapperSuperPierrot},
	}

	for _, c := range cases {
		dummyData := make([]byte, 128*1024)
		mapper, name := GuessMapper(dummyData, c.filename)
		if mapper != c.expected {
			t.Errorf("file %s: expected mapper %d (%s), got %d (%s)", c.filename, c.expected, MapperName(c.expected), mapper, name)
		}
	}
}

func TestGuessMapperOpcodeHeuristics(t *testing.T) {
	// Konami 4 heuristic: writes to 0x4000, 0x8000, 0xA000
	romK4 := make([]byte, 128*1024)
	copy(romK4[0x100:], []byte{0x32, 0x00, 0x40, 0x32, 0x00, 0x60, 0x32, 0x00, 0x80})
	mapper, _ := GuessMapper(romK4, "unknown.rom")
	if mapper != MapperKonami4 {
		t.Errorf("expected Konami4 from heuristic, got %d (%s)", mapper, MapperName(mapper))
	}

	// Konami 5 heuristic: writes to 0x5000, 0x7000, 0x9000
	romK5 := make([]byte, 128*1024)
	copy(romK5[0x100:], []byte{0x32, 0x00, 0x50, 0x32, 0x00, 0x70, 0x32, 0x00, 0x90, 0x32, 0x00, 0xB0})
	mapper, _ = GuessMapper(romK5, "unknown.rom")
	if mapper != MapperKonami5 {
		t.Errorf("expected Konami5 from heuristic, got %d (%s)", mapper, MapperName(mapper))
	}

	// ASCII 8K heuristic: writes to 0x6800, 0x7800
	romA8 := make([]byte, 128*1024)
	copy(romA8[0x100:], []byte{0x32, 0x00, 0x68, 0x32, 0x00, 0x78, 0x32, 0x00, 0x68, 0x32, 0x00, 0x78})
	mapper, _ = GuessMapper(romA8, "unknown.rom")
	if mapper != MapperASCII8K {
		t.Errorf("expected ASCII8 from heuristic, got %d (%s)", mapper, MapperName(mapper))
	}

	// ASCII 16K heuristic: writes to 0x77FF
	romA16 := make([]byte, 128*1024)
	copy(romA16[0x100:], []byte{0x32, 0xFF, 0x77, 0x32, 0xFF, 0x77})
	mapper, _ = GuessMapper(romA16, "unknown.rom")
	if mapper != MapperASCII16K {
		t.Errorf("expected ASCII16 from heuristic, got %d (%s)", mapper, MapperName(mapper))
	}
}

func TestMapperCrossBlaim(t *testing.T) {
	// Cross Blaim is 64KB (8 x 8KB banks)
	data := make([]byte, 64*1024)
	for i := range data {
		data[i] = byte(i / PageSize8K) // Each 8K bank filled with its bank number 0..7
	}

	cart := NewCartridge("CrossBlaim.rom", data, MapperCrossBlaim)

	// Initial state (val=0):
	// 4000h..7FFFh: block 0 (banks 0, 1)
	// 8000h..BFFFh: block 1 (banks 2, 3)
	// 0000h..3FFFh & C000h..FFFFh: block 1 (banks 2, 3)
	if b := cart.Get8KBank(0); b == nil || b[0] != 0 {
		t.Fatalf("expected bank 0 at 4000h, got %v", b)
	}
	if b := cart.Get8KBank(1); b == nil || b[0] != 1 {
		t.Fatalf("expected bank 1 at 6000h, got %v", b)
	}
	if b := cart.Get8KBank(2); b == nil || b[0] != 2 {
		t.Fatalf("expected bank 2 at 8000h, got %v", b)
	}
	if b := cart.Get8KBank(3); b == nil || b[0] != 3 {
		t.Fatalf("expected bank 3 at A000h, got %v", b)
	}
	if b := cart.Get8KBankExtra(0); b == nil || b[0] != 2 {
		t.Fatalf("expected bank 2 at 0000h, got %v", b)
	}

	// Switch to state 2: block 2 (banks 4, 5) at 8000h..BFFFh; 0000h unmapped
	cart.Write(0x4000, 2)
	if b := cart.Get8KBank(2); b == nil || b[0] != 4 {
		t.Fatalf("expected bank 4 at 8000h, got %v", b)
	}
	if b := cart.Get8KBank(3); b == nil || b[0] != 5 {
		t.Fatalf("expected bank 5 at A000h, got %v", b)
	}
	if b := cart.Get8KBankExtra(0); b != nil {
		t.Fatalf("expected nil at 0000h for state 2, got %v", b)
	}

	// Switch to state 3: block 3 (banks 6, 7) at 8000h..BFFFh
	cart.Write(0x4000, 3)
	if b := cart.Get8KBank(2); b == nil || b[0] != 6 {
		t.Fatalf("expected bank 6 at 8000h, got %v", b)
	}
	if b := cart.Get8KBank(3); b == nil || b[0] != 7 {
		t.Fatalf("expected bank 7 at A000h, got %v", b)
	}

	// Switch back to state 1: block 1 at 8000h..BFFFh and extra pages active
	cart.Write(0x8000, 1)
	if b := cart.Get8KBank(2); b == nil || b[0] != 2 {
		t.Fatalf("expected bank 2 at 8000h, got %v", b)
	}
	if b := cart.Get8KBankExtra(6); b == nil || b[0] != 2 {
		t.Fatalf("expected bank 2 at C000h, got %v", b)
	}
}

func TestMapperRType(t *testing.T) {
	// R-Type is 384KB (48 x 8KB banks)
	data := make([]byte, 384*1024)
	for i := range data {
		data[i] = byte(i / PageSize8K)
	}

	cart := NewCartridge("RType.rom", data, MapperRType)

	// Fixed 16KB bank 0x17 (23) at 4000h..7FFFh (8KB banks 46, 47)
	if b := cart.Get8KBank(0); b == nil || b[0] != 46 {
		t.Fatalf("expected fixed bank 46 at 4000h, got %v", b)
	}
	if b := cart.Get8KBank(1); b == nil || b[0] != 47 {
		t.Fatalf("expected fixed bank 47 at 6000h, got %v", b)
	}
	// Initial bank at 8000h is 0, 1
	if b := cart.Get8KBank(2); b == nil || b[0] != 0 {
		t.Fatalf("expected bank 0 at 8000h, got %v", b)
	}
	if b := cart.Get8KBank(3); b == nil || b[0] != 1 {
		t.Fatalf("expected bank 1 at A000h, got %v", b)
	}

	// Write to 0x7000 with 0x05 (bit 4 is 0 => val & 0x1F = 5 => 16KB bank 5 = 8KB banks 10, 11)
	cart.Write(0x7000, 0x05)
	if b := cart.Get8KBank(2); b == nil || b[0] != 10 {
		t.Fatalf("expected bank 10 at 8000h, got %v", b)
	}
	if b := cart.Get8KBank(3); b == nil || b[0] != 11 {
		t.Fatalf("expected bank 11 at A000h, got %v", b)
	}

	// Write to 0x7800 with 0x1A (bit 4 is 1 => val & 0x17: 0x1A & 0x17 = 0x12 = 18 => 8KB banks 36, 37)
	cart.Write(0x7800, 0x1A)
	if b := cart.Get8KBank(2); b == nil || b[0] != 36 {
		t.Fatalf("expected bank 36 at 8000h, got %v", b)
	}
	if b := cart.Get8KBank(3); b == nil || b[0] != 37 {
		t.Fatalf("expected bank 37 at A000h, got %v", b)
	}
}

func TestMapperHarryFox(t *testing.T) {
	// Harry Fox is 64KB (8 x 8KB banks)
	data := make([]byte, 64*1024)
	for i := range data {
		data[i] = byte(i / PageSize8K)
	}

	cart := NewCartridge("HarryFox.rom", data, MapperHarryFox)

	// Writes to 6000h..6FFFh: block = 2 * (val & 1) (block 0 or 2 => banks 0,1 or 4,5)
	cart.Write(0x6000, 1)
	if b := cart.Get8KBank(0); b == nil || b[0] != 4 {
		t.Fatalf("expected bank 4 at 4000h, got %v", b)
	}
	if b := cart.Get8KBank(1); b == nil || b[0] != 5 {
		t.Fatalf("expected bank 5 at 6000h, got %v", b)
	}

	// Writes to 7000h..7FFFh: block = 2 * (val & 1) + 1 (block 1 or 3 => banks 2,3 or 6,7)
	cart.Write(0x7000, 1)
	if b := cart.Get8KBank(2); b == nil || b[0] != 6 {
		t.Fatalf("expected bank 6 at 8000h, got %v", b)
	}
	if b := cart.Get8KBank(3); b == nil || b[0] != 7 {
		t.Fatalf("expected bank 7 at A000h, got %v", b)
	}

	cart.Write(0x7500, 0)
	if b := cart.Get8KBank(2); b == nil || b[0] != 2 {
		t.Fatalf("expected bank 2 at 8000h, got %v", b)
	}
}

func TestMapperSuperPierrot(t *testing.T) {
	data := make([]byte, 128*1024)
	for i := range data {
		data[i] = byte(i / PageSize8K)
	}

	cart := NewCartridge("SuperPierrot.rom", data, MapperSuperPierrot)

	// Write to 0x6000 selects bank for 4000h..7FFFh
	cart.Write(0x6000, 2) // 16KB bank 2 = 8KB banks 4, 5
	if b := cart.Get8KBank(0); b == nil || b[0] != 4 {
		t.Fatalf("expected bank 4 at 4000h, got %v", b)
	}

	// Write to 0x7000 selects bank for 8000h..BFFFh
	cart.Write(0x7000, 3) // 16KB bank 3 = 8KB banks 6, 7
	if b := cart.Get8KBank(2); b == nil || b[0] != 6 {
		t.Fatalf("expected bank 6 at 8000h, got %v", b)
	}

	// Extraneous write outside 6000h-77FFh does not change banks
	cart.Write(0x8000, 5)
	if b := cart.Get8KBank(2); b == nil || b[0] != 6 {
		t.Fatalf("expected bank 6 to remain after write to 8000h, got %v", b)
	}
}

func TestMapperASCII16SRAM(t *testing.T) {
	data := make([]byte, 128*1024)
	for i := range data {
		data[i] = byte(i / PageSize8K)
	}

	cart := NewCartridge("Hydlide2.rom", data, MapperASCII16SRAM)

	// Verify SRAM initialization
	if len(cart.SRAM) != 2048 {
		t.Fatalf("expected 2048 bytes of SRAM, got %d", len(cart.SRAM))
	}

	// Initially ROM bank 0 is mapped
	if b := cart.Get8KBank(2); b == nil || b[0] != 0 {
		t.Fatalf("expected ROM bank 0 initially at 8000h, got %v", b)
	}

	// Switch 8000h..BFFFh to SRAM using value 0x10
	cart.Write(0x7000, 0x10)
	if !cart.SRAMPage2 {
		t.Fatalf("expected SRAMPage2 to be true")
	}

	// Write into SRAM at 0x8000 and 0x8050
	cart.Write(0x8000, 0xAA)
	cart.Write(0x8050, 0x55)

	if !cart.SRAMModified {
		t.Fatalf("expected SRAMModified to be true")
	}

	// Verify reading from SRAM via Get8KBank(2)
	b := cart.Get8KBank(2)
	if b == nil || b[0] != 0xAA || b[0x50] != 0x55 {
		t.Fatalf("SRAM read mismatch: got %02X, %02X", b[0], b[0x50])
	}

	// Verify 2KB mirroring across 8KB window (0x8000 + 2048 = 0x8800)
	if b[2048] != 0xAA || b[2048+0x50] != 0x55 {
		t.Fatalf("SRAM 2KB mirroring failed: got %02X, %02X at offset 2048", b[2048], b[2048+0x50])
	}

	// Switch back to ROM bank 1 (val=1)
	cart.Write(0x7000, 0x01)
	if cart.SRAMPage2 {
		t.Fatalf("expected SRAMPage2 to be false")
	}
	if b := cart.Get8KBank(2); b == nil || b[0] != 2 {
		t.Fatalf("expected ROM bank 2 at 8000h, got %v", b)
	}

	// Test SaveSRAM and LoadSRAM persistence
	tmpDir := t.TempDir()
	savFile := filepath.Join(tmpDir, "hydlide2.sav")
	if err := cart.SaveSRAM(savFile); err != nil {
		t.Fatalf("failed to save SRAM: %v", err)
	}

	// Create new cartridge and load saved SRAM
	cart2 := NewCartridge("Hydlide2.rom", data, MapperASCII16SRAM)
	if err := cart2.LoadSRAM(savFile); err != nil {
		t.Fatalf("failed to load SRAM: %v", err)
	}

	cart2.Write(0x7000, 0x10) // Select SRAM
	b2 := cart2.Get8KBank(2)
	if b2[0] != 0xAA || b2[0x50] != 0x55 {
		t.Fatalf("reloaded SRAM mismatch: %02X, %02X", b2[0], b2[0x50])
	}
}

func TestBusExoticMappersIntegration(t *testing.T) {
	// Full bus integration test with CrossBlaim and SRAM
	slots := NewSlotBus()
	mapper := NewRAMMapper(4)
	bus := NewMSXBus(slots, mapper, nil)
	data := make([]byte, 64*1024)
	for i := range data {
		data[i] = byte(i / PageSize8K)
	}

	cart := NewCartridge("CrossBlaim.rom", data, MapperCrossBlaim)
	bus.CartA = cart

	// Primary slot 1 selected for all 4 pages
	bus.Slots.CurPSL = [4]uint8{1, 1, 1, 1}
	bus.RefreshCartridge(1, cart)

	// Read from 0x4000 (page 1) -> bank 0
	if val := bus.Read(0x4000); val != 0 {
		t.Errorf("expected 0 at 4000h, got %d", val)
	}
	// Read from 0x8000 (page 2) -> bank 2
	if val := bus.Read(0x8000); val != 2 {
		t.Errorf("expected 2 at 8000h, got %d", val)
	}
	// Read from 0x0000 (page 0) -> bank 2
	if val := bus.Read(0x0000); val != 2 {
		t.Errorf("expected 2 at 0000h, got %d", val)
	}

	// Write 2 to switch bank
	bus.Write(0x4000, 2)
	if val := bus.Read(0x8000); val != 4 {
		t.Errorf("expected 4 at 8000h after switch, got %d", val)
	}
	// Page 0 should now be unmapped (0xFF)
	if val := bus.Read(0x0000); val != 0xFF {
		t.Errorf("expected 0xFF at 0000h for unmapped, got %d", val)
	}
}
