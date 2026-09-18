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

func TestBIOSAndDiskPatches(t *testing.T) {
	cfg := DefaultConfig()
	cfg.SimulateBDOS = true
	cfg.PatchBIOS = true
	m, err := NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	// Verify BIOS patch vectors (ED FE C9) at 0x00E1 (TAPION)
	tapion1 := m.Bus.Read(0x00E1)
	tapion2 := m.Bus.Read(0x00E2)
	tapion3 := m.Bus.Read(0x00E3)
	if tapion1 != 0xED || tapion2 != 0xFE || tapion3 != 0xC9 {
		t.Fatalf("Expected ED FE C9 at 0x00E1 (TAPION patch), got %02X %02X %02X", tapion1, tapion2, tapion3)
	}

	// Mount a blank 720KB disk with BootBlock in Drive A
	m.FDD[0].Data = make([]byte, 720*1024)
	copy(m.FDD[0].Data, BootBlock)
	m.FDD[0].Sectors = 1440
	m.FDD[0].SecSize = 512
	if !m.DiskPresent(0) {
		t.Fatalf("Expected Drive A to have inserted disk")
	}

	// Map Page 1 to Slot 3 Subslot 2 (DiskROM) and Page 3 to Slot 3 (RAM)
	m.Bus.Out(0xA8, 0xFC)
	m.Bus.Write(0xFFFF, 0x08)

	// Test GETDPB via Step at 0x4016 (where ApplyDiskPatches installed ED FE C9)
	m.CPU.A = 0
	m.CPU.SetHL(0xC000)
	m.CPU.PC = 0x4016 // GETDPB vector (contains ED FE C9)

	m.CPU.Step(m.Bus) // Fetches ED FE and triggers PatchZ80 hook!

	// Check that Carry is clear (success)
	if (m.CPU.F & 0x01) != 0 {
		t.Fatalf("Expected GETDPB to succeed with Carry clear, got F=%02X", m.CPU.F)
	}
	// Verify format ID and sector size in DPB buffer
	formatID := m.Bus.Read(0xC001)
	if formatID != 0xF9 {
		t.Fatalf("Expected format ID 0xF9 in DPB, got %02Xh", formatID)
	}
	secSizeLow := m.Bus.Read(0xC002)
	secSizeHigh := m.Bus.Read(0xC003)
	secSize := (uint16(secSizeHigh) << 8) | uint16(secSizeLow)
	if secSize != 512 {
		t.Fatalf("Expected sector size 512 in DPB, got %d", secSize)
	}
}

func TestSecondarySlotRegister0xFFFF(t *testing.T) {
	cfg := DefaultConfig()
	m, err := NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	// In DefaultConfig, Slot 3 is expanded (IsSubslot[3] = true)
	// Map Page 3 to Slot 3 (PSL = 0xC0 or 0xF0)
	m.Bus.Out(0xA8, 0xF0) // Page 3 is slot 3
	m.Bus.Write(0xFFFF, 0x55)
	val := m.Bus.Read(0xFFFF)
	// Reading 0xFFFF on expanded slot returns inverted value: ^0x55 = 0xAA
	if val != 0xAA {
		t.Fatalf("Expected 0xFFFF to return inverted subslot 0xAA, got %02X", val)
	}

	// Now switch Page 3 to Slot 0 (unexpanded primary slot)
	m.Bus.Out(0xA8, 0x00) // Page 3 is slot 0
	// Writing to 0xFFFF should now write to slot 0 RAM/ROM, NOT change SSL
	m.Bus.Slots.MemMap[0][0][7] = make([]byte, PageSize8K)
	m.Bus.Slots.IsRAM[0][0][7] = true
	m.Bus.Slots.RAM[7] = m.Bus.Slots.MemMap[0][0][7]

	m.Bus.Write(0xFFFF, 0x42)
	readBack := m.Bus.Read(0xFFFF)
	if readBack != 0x42 {
		t.Fatalf("Expected 0xFFFF on unexpanded slot to read normal RAM value 0x42, got %02X", readBack)
	}
}

func TestMachineFrameSteppingAndBoot(t *testing.T) {
	cfg := DefaultConfig()
	m, err := NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	// Step 5 frames
	totalCycles := 0
	for f := 0; f < 5; f++ {
		cycles := m.StepFrame()
		totalCycles += cycles
	}

	if totalCycles < 200000 {
		t.Errorf("Expected at least 200,000 cycles for 5 frames, got %d", totalCycles)
	}

	if m.CPU.PC == 0x0000 {
		t.Errorf("Expected CPU PC to have moved from 0000h after boot frames, got %04Xh", m.CPU.PC)
	}

	fb := m.GetFrameBuffer()
	if len(fb) == 0 {
		t.Fatal("Expected non-empty frame buffer from VDP")
	}

	t.Logf("Executed 5 frames: %d cycles, PC: %04Xh, FrameBuffer bytes: %d", totalCycles, m.CPU.PC, len(fb))
}


