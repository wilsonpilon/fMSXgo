package msx

import (
	"testing"
)

func TestMSXMachineCreationAndBIOS(t *testing.T) {
	cfg := DefaultConfig()
	cfg.Model = ModelMSX2

	m, err := NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create MSX machine: %v", err)
	}

	// Verify PC starts at 0x0000
	if m.CPU.PC != 0x0000 {
		t.Fatalf("Expected PC = 0x0000, got %04X", m.CPU.PC)
	}

	// Verify byte at 0x0000 is MSX BIOS first instruction: F3h (DI)
	firstByte := m.Bus.Read(0x0000)
	if firstByte != 0xF3 {
		t.Fatalf("Expected MSX BIOS byte at 0x0000 to be 0xF3 (DI), got %02Xh", firstByte)
	}
	t.Logf("MSX2 BIOS loaded successfully! Byte at 0000h: %02Xh (DI)", firstByte)
}

func TestSlotSwitchingAndRAM(t *testing.T) {
	cfg := DefaultConfig()
	m, err := NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	// By default in NewMachine, PSL is 0xF0:
	// Page 0, 1 -> Slot 0 (ROM)
	// Page 2, 3 -> Slot 3 (RAM)

	// Writing to Page 0 (0x0000) should be ignored because it's ROM
	origVal := m.Bus.Read(0x0000)
	m.Bus.Write(0x0000, 0x55)
	if m.Bus.Read(0x0000) != origVal {
		t.Fatalf("ROM area was modified! Expected %02X, got %02X", origVal, m.Bus.Read(0x0000))
	}

	// Writing to Page 3 (0xC000) should succeed because it's RAM
	m.Bus.Write(0xC000, 0x77)
	if m.Bus.Read(0xC000) != 0x77 {
		t.Fatalf("RAM write failed at 0xC000: expected 0x77, got %02X", m.Bus.Read(0xC000))
	}

	// Switch Page 0 to Slot 3 (RAM) via Port A8h:
	// Let's set PSL = 0xFF (all pages to slot 3 = RAM)
	m.Bus.Out(0xA8, 0xFF)
	m.Bus.Write(0x0000, 0xAA)
	if m.Bus.Read(0x0000) != 0xAA {
		t.Fatalf("Failed to write to Page 0 after mapping RAM: expected 0xAA, got %02X", m.Bus.Read(0x0000))
	}
}

func TestRAMMapperPorts(t *testing.T) {
	cfg := DefaultConfig()
	cfg.RAMPages = 8 // 128KB = 8 pages of 16KB
	m, err := NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	// Write bank 2 to CPU Page 2 (Port FEh)
	m.Bus.Out(0xFE, 0x02)
	readBack := m.Bus.In(0xFE) & m.Mapper.Mask
	if readBack != 0x02 {
		t.Fatalf("RAM mapper port FEh readback failed: expected 0x02, got %02X", readBack)
	}

	// Write to 0x8000 (Page 2)
	m.Bus.Write(0x8000, 0x99)
	if m.Bus.Read(0x8000) != 0x99 {
		t.Fatalf("RAM write to mapped bank failed")
	}

	// Switch Port FEh to bank 3
	m.Bus.Out(0xFE, 0x03)
	// Now 0x8000 should see bank 3, not bank 2 (initially 0x00 or unwritten)
	m.Bus.Write(0x8000, 0x33)
	if m.Bus.Read(0x8000) != 0x33 {
		t.Fatalf("RAM write to bank 3 failed")
	}

	// Switch back to bank 2
	m.Bus.Out(0xFE, 0x02)
	if m.Bus.Read(0x8000) != 0x99 {
		t.Fatalf("Bank 2 did not retain value 0x99! Got %02X", m.Bus.Read(0x8000))
	}
}
