package msx

import (
	"os"
	"strings"
	"testing"
	"time"

	"fmsxgo/pkg/cpu/z80"
	"fmsxgo/pkg/msxdisk"
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

	// Map Page 1 to Slot 3 Subslot 1 (DiskROM) and Page 2/3 to Slot 3 Subslot 2 (RAM)
	m.Bus.Out(0xA8, 0xFC)
	m.Bus.Write(0xFFFF, 0xA4)

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

	// Verify FIRREC (offset 0x0B: first data sector): 1 + 2*3 + (32*112/512) = 1 + 6 + 7 = 14
	firRecLow := m.Bus.Read(0xC00C)
	firRecHigh := m.Bus.Read(0xC00D)
	firRec := (uint16(firRecHigh) << 8) | uint16(firRecLow)
	if firRec != 14 {
		t.Fatalf("Expected FIRREC = 14 in DPB, got %d", firRec)
	}

	// Verify FIRDIR (offset 0x10: first directory sector): 1 + 2*3 = 7
	firDirLow := m.Bus.Read(0xC011)
	firDirHigh := m.Bus.Read(0xC012)
	firDir := (uint16(firDirHigh) << 8) | uint16(firDirLow)
	if firDir != 7 {
		t.Fatalf("Expected FIRDIR = 7 (start of root directory) in DPB, got %d", firDir)
	}

	// Test DSKCHG (0x4013): must fall through to GETDPB and update DPB
	m.CPU.A = 0
	m.CPU.SetHL(0xD000)
	m.CPU.PC = 0x4013
	m.CPU.Step(m.Bus)
	if (m.CPU.F & 0x01) != 0 || m.CPU.B != 0 {
		t.Fatalf("Expected DSKCHG to succeed with Carry clear and B=0, got F=%02X B=%02X", m.CPU.F, m.CPU.B)
	}
	dskchgDir := (uint16(m.Bus.Read(0xD012)) << 8) | uint16(m.Bus.Read(0xD011))
	if dskchgDir != 7 {
		t.Fatalf("Expected DSKCHG fallthrough to populate FIRDIR=7 in DPB, got %d", dskchgDir)
	}

	// Test PHYDIO Read (0x4010) into Page 1 (0x4000..0x7FFF)
	m.CPU.A = 0 // Drive A:
	m.CPU.B = 1 // 1 sector
	m.CPU.C = 0xF9
	m.CPU.SetDE(0)      // Sector 0
	m.CPU.SetHL(0x5000) // Destination in Page 1 (4000h..7FFFh)
	m.CPU.F = 0         // Carry = 0: Read
	m.CPU.PC = 0x4010
	m.CPU.Step(m.Bus)

	// Switch Page 1 to Slot 3 Subslot 2 (RAM) to read back the sector written into RAM
	m.Bus.Write(0xFFFF, 0xA8)
	if m.Bus.Read(0x5000) != 0xEB {
		t.Fatalf("Expected first byte at 5000h in RAM to be 0xEB, got %02Xh", m.Bus.Read(0x5000))
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

func TestBootToPrompt(t *testing.T) {
	cfg := DefaultConfig()
	cfg.Model = ModelMSX2
	m, err := NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	for f := 0; f < 180; f++ {
		m.StepFrame()
	}

	// Press Enter key (Row 7, Bit 7) to submit date
	m.Bus.KeyMatrix[7] &^= 0x80
	for f := 0; f < 30; f++ {
		m.StepFrame()
	}
	m.Bus.KeyMatrix[7] |= 0x80 // Release Enter
	for f := 0; f < 60; f++ {
		m.StepFrame()
	}

	t.Logf("After pressing Enter: PC=%04Xh, ScrMode=%d, ScreenON=%t",
		m.CPU.PC, m.VDP.ScrMode, m.VDP.ScreenON())

	// Check if any character table has text written
	charCount := 0
	for i := 0; i < 40*24; i++ {
		ch := m.VDP.VRAM[(m.VDP.ChrTab+i)%len(m.VDP.VRAM)]
		if ch != 0 && ch != 0x20 {
			charCount++
		}
	}
	t.Logf("Non-space characters in ChrTab: %d", charCount)

	// Dump lines of 32 characters
	for row := 0; row < 24; row++ {
		lineBytes := make([]byte, 32)
		for col := 0; col < 32; col++ {
			ch := m.VDP.VRAM[(m.VDP.ChrTab+(row*32)+col)%len(m.VDP.VRAM)]
			if ch >= 32 && ch < 127 {
				lineBytes[col] = ch
			} else {
				lineBytes[col] = '.'
			}
		}
		str := string(lineBytes)
		if strings.Trim(str, ".") != "" {
			t.Logf("Row %2d: %s", row, str)
		}
	}
}

func TestBootWithDisk(t *testing.T) {
	cfg := DefaultConfig()
	cfg.Model = ModelMSX2
	cfg.SimulateBDOS = true
	m, err := NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	m.FDD[0].Data = make([]byte, 720*1024)
	copy(m.FDD[0].Data, BootBlock)
	m.FDD[0].Sectors = 1440
	m.FDD[0].SecSize = 512
	m.Config.DiskAPath = "test.dsk"
	if m.FDC != nil {
		m.FDC.Disk[0] = m.FDD[0]
	}

	t.Logf("MemMap[3][1][2][:16]: % X", m.Slots.MemMap[3][1][2][:16])

	patchCount := 0
	origHook := m.CPU.PatchHook
	m.CPU.PatchHook = func(z *z80.Z80, b z80.Bus) {
		patchCount++
		t.Logf("PatchHook called at PC=%04X (A=%02X, B=%02X, C=%02X, DE=%04X, HL=%04X)",
			z.PC-2, z.A, z.B, z.C, z.DE(), z.HL())
		origHook(z, b)
	}

	for f := 0; f < 300; f++ {
		if f == 180 {
			// Press Enter to bypass date prompt if it appears
			m.Bus.KeyMatrix[7] &^= 0x80
		} else if f == 200 {
			m.Bus.KeyMatrix[7] |= 0x80
		}
		m.StepFrame()
	}

	pcBefore := m.CPU.PC
	for f := 0; f < 60; f++ {
		m.StepFrame()
	}
	t.Logf("PC before extra 60 frames: %04X, after: %04X (cycles=%d)", pcBefore, m.CPU.PC, m.CPU.Cycles)
	t.Logf("After 360 frames: PC=%04X, PSL=%02X, SSL3=%02X, total patches called=%d",
		m.CPU.PC, m.Slots.PSLReg, m.Slots.SSLReg[3], patchCount)
	codeBytes := make([]byte, 16)
	for i := 0; i < 16; i++ {
		codeBytes[i] = m.Bus.Read(m.CPU.PC + uint16(i))
	}
	t.Logf("Bytes at PC (%04X): % X", m.CPU.PC, codeBytes)
}

func TestMSXDiskDirectoryReading(t *testing.T) {
	d, err := msxdisk.CreateMemory(msxdisk.Format720K, nil)
	if err != nil {
		t.Fatalf("Failed to create disk: %v", err)
	}
	_ = d.AddFileData("HELLO.BAS", []byte("10 PRINT \"HELLO\"\r\n"), time.Now())
	_ = d.AddFileData("TEST.TXT", []byte("SAMPLE TEXT\r\n"), time.Now())

	cfg := DefaultConfig()
	cfg.Model = ModelMSX2
	cfg.SimulateBDOS = true
	m, err := NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	m.FDD[0].Data = d.Data
	m.FDD[0].Sectors = len(d.Data) / 512
	m.FDD[0].SecSize = 512
	m.Config.DiskAPath = "test.dsk"
	if m.FDC != nil {
		m.FDC.Disk[0] = m.FDD[0]
	}

	// Read DPB via GETDPB (0x4016)
	m.Bus.Out(0xA8, 0xFC)
	m.Bus.Write(0xFFFF, 0xA4)
	m.CPU.A = 0
	m.CPU.SetHL(0xC000)
	m.CPU.PC = 0x4016
	m.CPU.Step(m.Bus)

	firDir := (uint16(m.Bus.Read(0xC012)) << 8) | uint16(m.Bus.Read(0xC011))
	if firDir != 7 {
		t.Fatalf("Expected FIRDIR = 7, got %d", firDir)
	}

	// Read Directory Sector 7 via PHYDIO (0x4010) into Page 3 (0xD000)
	m.CPU.A = 0
	m.CPU.B = 1
	m.CPU.C = 0xF9
	m.CPU.SetDE(firDir) // Read FIRDIR!
	m.CPU.SetHL(0xD000)
	m.CPU.F = 0
	m.CPU.PC = 0x4010
	m.CPU.Step(m.Bus)

	if (m.CPU.F & 0x01) != 0 {
		t.Fatalf("PHYDIO read of directory failed: A=%02X", m.CPU.A)
	}

	// Verify the first directory entry in RAM at 0xD000 is "HELLO   BAS"
	entry1 := string(m.Bus.Slots.RAM[6][0x1000 : 0x1000+11]) // 0xD000 is offset 0x1000 in Page 8k 6
	if entry1 != "HELLO   BAS" {
		t.Fatalf("Expected first dir entry in RAM to be 'HELLO   BAS', got %q", entry1)
	}
	entry2 := string(m.Bus.Slots.RAM[6][0x1020 : 0x1020+11])
	if entry2 != "TEST    TXT" {
		t.Fatalf("Expected second dir entry in RAM to be 'TEST    TXT', got %q", entry2)
	}
	t.Logf("Directory reading verified successfully: Entry1=%s, Entry2=%s", entry1, entry2)
}

func TestMSX1BootAndROMs(t *testing.T) {
	cfg := DefaultConfig()
	cfg.Model = ModelMSX1
	cfg.RAMPages = 4
	cfg.VRAMPages = 2

	m, err := NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create MSX1 machine: %v", err)
	}

	if m.Config.Model != ModelMSX1 {
		t.Fatalf("Expected Model = ModelMSX1, got %d", m.Config.Model)
	}
	if m.ModelName() != "MSX 1" {
		t.Fatalf("Expected ModelName = 'MSX 1', got %s", m.ModelName())
	}
	if m.VDPChipName() != "TMS9918" {
		t.Fatalf("Expected VDPChipName = 'TMS9918', got %s", m.VDPChipName())
	}

	// Verify MSX1 BIOS signature at 0000h is DI (0xF3)
	if m.Bus.Read(0x0000) != 0xF3 {
		t.Fatalf("Expected byte at 0000h to be 0xF3, got %02X", m.Bus.Read(0x0000))
	}

	// Step a few frames
	for f := 0; f < 10; f++ {
		m.StepFrame()
	}

	if m.CPU.PC == 0x0000 {
		t.Fatalf("CPU did not execute instructions in MSX1")
	}
	t.Logf("MSX1 booted successfully with MSX.ROM! PC=%04Xh", m.CPU.PC)
}

func TestMSX2PBootAndROMs(t *testing.T) {
	cfg := DefaultConfig()
	cfg.Model = ModelMSX2P
	cfg.RAMPages = 8
	cfg.VRAMPages = 8

	m, err := NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create MSX2+ machine: %v", err)
	}

	if m.Config.Model != ModelMSX2P {
		t.Fatalf("Expected Model = ModelMSX2P, got %d", m.Config.Model)
	}
	if m.ModelName() != "MSX 2+" {
		t.Fatalf("Expected ModelName = 'MSX 2+', got %s", m.ModelName())
	}
	if m.VDPChipName() != "V9958" {
		t.Fatalf("Expected VDPChipName = 'V9958', got %s", m.VDPChipName())
	}

	// Verify V9958 status register 1 ID bit (bit 2 is set, 0x04)
	m.VDP.Regs[15] = 1
	status1 := m.VDP.ReadStatus()
	if (status1 & 0x04) == 0 {
		t.Fatalf("Expected bit 2 in Status 1 to be set for V9958 (MSX2+), got %02Xh", status1)
	}

	// Step a few frames
	for f := 0; f < 10; f++ {
		m.StepFrame()
	}

	if m.CPU.PC == 0x0000 {
		t.Fatalf("CPU did not execute instructions in MSX2+")
	}
	t.Logf("MSX2+ booted successfully with MSX2P.ROM + MSX2PEXT.ROM! PC=%04Xh, Status1=%02Xh", m.CPU.PC, status1)
}

func TestRuntimeModelSwitching(t *testing.T) {
	cfg := DefaultConfig()
	cfg.Model = ModelMSX2
	m, err := NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create MSX2 machine: %v", err)
	}

	// 1. Initial state is MSX2
	if m.ModelName() != "MSX 2" || m.VDPChipName() != "V9938" {
		t.Fatalf("Expected MSX2, got %s / %s", m.ModelName(), m.VDPChipName())
	}

	// 2. Switch to MSX1
	if err := m.SwitchModel(ModelMSX1); err != nil {
		t.Fatalf("Failed to switch to MSX1: %v", err)
	}
	if m.ModelName() != "MSX 1" || m.VDPChipName() != "TMS9918" {
		t.Fatalf("Expected MSX1, got %s / %s", m.ModelName(), m.VDPChipName())
	}
	if m.CPU.PC != 0x0000 {
		t.Fatalf("Expected PC=0000h after switch, got %04Xh", m.CPU.PC)
	}

	// 3. Switch to MSX2+
	if err := m.SwitchModel(ModelMSX2P); err != nil {
		t.Fatalf("Failed to switch to MSX2+: %v", err)
	}
	if m.ModelName() != "MSX 2+" || m.VDPChipName() != "V9958" {
		t.Fatalf("Expected MSX2+, got %s / %s", m.ModelName(), m.VDPChipName())
	}
	// Verify V9958 ID bit
	m.VDP.Regs[15] = 1
	if (m.VDP.ReadStatus() & 0x04) == 0 {
		t.Fatalf("Expected bit 2 set in Status 1 for V9958")
	}

	// 4. Switch back to MSX2
	if err := m.SwitchModel(ModelMSX2); err != nil {
		t.Fatalf("Failed to switch back to MSX2: %v", err)
	}
	if m.ModelName() != "MSX 2" || m.VDPChipName() != "V9938" {
		t.Fatalf("Expected MSX2, got %s / %s", m.ModelName(), m.VDPChipName())
	}
	t.Logf("Runtime model switching passed seamlessly across MSX2 -> MSX1 -> MSX2+ -> MSX2!")
}

func TestMSX2BootAndLogoToBASIC(t *testing.T) {
	cfg := DefaultConfig()
	cfg.Model = ModelMSX2
	cfg.RAMPages = 8
	cfg.VRAMPages = 8

	m, err := NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create MSX2 machine: %v", err)
	}

	// Step 200 frames (MSX2 Boot Logo)
	for f := 0; f < 200; f++ {
		m.StepFrame()
	}

	fb := m.GetFrameBuffer()
	nonZeroPixels := 0
	for _, b := range fb {
		if b != 0 {
			nonZeroPixels++
		}
	}

	t.Logf("MSX2 at 200 frames (Logo): PC=%04Xh, SP=%04Xh, ScrMode=%d, ScreenON=%v, nonZeroPixels=%d",
		m.CPU.PC, m.CPU.SP, m.VDP.ScrMode, m.VDP.ScreenON(), nonZeroPixels)

	if nonZeroPixels == 0 {
		t.Fatalf("MSX2 boot logo was not rendered! nonZeroPixels is 0")
	}

	// Step another 250 frames (450 frames total) for logo timeout to MSX-BASIC
	for f := 200; f < 450; f++ {
		m.StepFrame()
	}

	t.Logf("MSX2 at 450 frames (BASIC): PC=%04Xh, SP=%04Xh, PSL=%02Xh, ScrMode=%d, ScreenON=%v",
		m.CPU.PC, m.CPU.SP, m.Slots.PSLReg, m.VDP.ScrMode, m.VDP.ScreenON())
}

func TestMSX2PBootAndLogoToBASIC(t *testing.T) {
	cfg := DefaultConfig()
	cfg.Model = ModelMSX2P
	cfg.RAMPages = 8
	cfg.VRAMPages = 8

	m, err := NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create MSX2+ machine: %v", err)
	}

	// Step 200 frames (MSX2+ Boot Logo)
	for f := 0; f < 200; f++ {
		m.StepFrame()
	}

	fb := m.GetFrameBuffer()
	nonZeroPixels := 0
	for _, b := range fb {
		if b != 0 {
			nonZeroPixels++
		}
	}

	t.Logf("MSX2+ at 200 frames (Logo): PC=%04Xh, SP=%04Xh, ScrMode=%d, ScreenON=%v, nonZeroPixels=%d",
		m.CPU.PC, m.CPU.SP, m.VDP.ScrMode, m.VDP.ScreenON(), nonZeroPixels)

	if nonZeroPixels == 0 {
		t.Fatalf("MSX2+ boot logo was not rendered! nonZeroPixels is 0")
	}

	// Step another 250 frames (450 frames total) for logo timeout to MSX-BASIC
	for f := 200; f < 450; f++ {
		m.StepFrame()
	}

	t.Logf("MSX2+ at 450 frames (BASIC): PC=%04Xh, SP=%04Xh, PSL=%02Xh, ScrMode=%d, ScreenON=%v",
		m.CPU.PC, m.CPU.SP, m.Slots.PSLReg, m.VDP.ScrMode, m.VDP.ScreenON())

	if m.CPU.PC == 0x0000 || m.CPU.PC == 0x03DF {
		t.Fatalf("MSX2+ boot failed or stuck: PC=%04Xh", m.CPU.PC)
	}
}

func TestPSGSoundIntegration(t *testing.T) {
	cfg := DefaultConfig()
	cfg.Model = ModelMSX1
	m, err := NewMachine(cfg)
	if err != nil {
		t.Fatalf("failed to create machine: %v", err)
	}

	if m.PSG == nil || m.Mixer == nil {
		t.Fatal("expected PSG and Mixer to be initialized on machine")
	}

	// Output tone to Channel A via MSX I/O ports 0xA0 and 0xA1
	m.Bus.Out(0xA0, 0)   // R0 = period low (100)
	m.Bus.Out(0xA1, 100)
	m.Bus.Out(0xA0, 1)   // R1 = period high (0)
	m.Bus.Out(0xA1, 0)
	m.Bus.Out(0xA0, 7)   // R7 = enable tone on Channel A
	m.Bus.Out(0xA1, 0x3E)
	m.Bus.Out(0xA0, 8)   // R8 = max volume (15)
	m.Bus.Out(0xA1, 15)

	// Step a whole video frame (~262 scanlines)
	m.StepFrame()

	// Verify mixer has produced sound samples
	buf := make([]byte, 1024)
	n, err := m.Mixer.Read(buf)
	if err != nil {
		t.Fatalf("error reading from mixer: %v", err)
	}
	if n == 0 {
		t.Fatal("expected mixer to yield audio bytes after stepping frames")
	}

	hasAudio := false
	for _, b := range buf[:n] {
		if b != 0 {
			hasAudio = true
			break
		}
	}
	if !hasAudio {
		t.Fatal("expected non-zero audio waveform samples from active PSG channel")
	}
}

func TestMediaManagementAndEjection(t *testing.T) {
	cfg := DefaultConfig()
	m, err := NewMachine(cfg)
	if err != nil {
		t.Fatalf("failed to create machine: %v", err)
	}

	// 1. Floppy Drive A & B
	fakeDisk := make([]byte, 720*1024)
	copy(fakeDisk, BootBlock)
	tmpDskA := t.TempDir() + "/gameA.dsk"
	tmpDskB := t.TempDir() + "/gameB.dsk"
	if err := os.WriteFile(tmpDskA, fakeDisk, 0644); err != nil {
		t.Fatalf("failed to write temp disk: %v", err)
	}
	if err := os.WriteFile(tmpDskB, fakeDisk, 0644); err != nil {
		t.Fatalf("failed to write temp disk: %v", err)
	}

	if err := m.LoadDisk(0, tmpDskA); err != nil {
		t.Fatalf("LoadDisk(0) failed: %v", err)
	}
	if !m.DiskPresent(0) || m.Config.DiskAPath != tmpDskA {
		t.Fatalf("Disk A not properly loaded: present=%v, path=%q", m.DiskPresent(0), m.Config.DiskAPath)
	}

	if err := m.LoadDisk(1, tmpDskB); err != nil {
		t.Fatalf("LoadDisk(1) failed: %v", err)
	}
	if !m.DiskPresent(1) || m.Config.DiskBPath != tmpDskB {
		t.Fatalf("Disk B not properly loaded: present=%v, path=%q", m.DiskPresent(1), m.Config.DiskBPath)
	}

	// Eject Disk A & B
	m.EjectDisk(0)
	if m.DiskPresent(0) || m.Config.DiskAPath != "" {
		t.Fatalf("Disk A was not properly ejected: present=%v, path=%q", m.DiskPresent(0), m.Config.DiskAPath)
	}
	m.EjectDisk(1)
	if m.DiskPresent(1) || m.Config.DiskBPath != "" {
		t.Fatalf("Disk B was not properly ejected: present=%v, path=%q", m.DiskPresent(1), m.Config.DiskBPath)
	}

	// 2. Cartridge Slots 1 & 2
	fakeROM := make([]byte, 32*1024)
	fakeROM[0] = 'A'
	fakeROM[1] = 'B'
	tmpCart1 := t.TempDir() + "/game1.rom"
	tmpCart2 := t.TempDir() + "/game2.rom"
	if err := os.WriteFile(tmpCart1, fakeROM, 0644); err != nil {
		t.Fatalf("failed to write temp ROM: %v", err)
	}
	if err := os.WriteFile(tmpCart2, fakeROM, 0644); err != nil {
		t.Fatalf("failed to write temp ROM: %v", err)
	}

	if err := m.LoadCartridge(1, tmpCart1); err != nil {
		t.Fatalf("LoadCartridge(1) failed: %v", err)
	}
	if m.Bus.CartA == nil || m.Config.CartAPath != tmpCart1 {
		t.Fatalf("Cartridge 1 not properly loaded: cartA=%v, path=%q", m.Bus.CartA, m.Config.CartAPath)
	}

	if err := m.LoadCartridge(2, tmpCart2); err != nil {
		t.Fatalf("LoadCartridge(2) failed: %v", err)
	}
	if m.Bus.CartB == nil || m.Config.CartBPath != tmpCart2 {
		t.Fatalf("Cartridge 2 not properly loaded: cartB=%v, path=%q", m.Bus.CartB, m.Config.CartBPath)
	}

	// Eject Cartridges 1 & 2
	m.EjectCartridge(1)
	if m.Bus.CartA != nil || m.Config.CartAPath != "" {
		t.Fatalf("Cartridge 1 was not properly ejected: cartA=%v, path=%q", m.Bus.CartA, m.Config.CartAPath)
	}
	m.EjectCartridge(2)
	if m.Bus.CartB != nil || m.Config.CartBPath != "" {
		t.Fatalf("Cartridge 2 was not properly ejected: cartB=%v, path=%q", m.Bus.CartB, m.Config.CartBPath)
	}

	// 3. Cassette Tape
	fakeTape := []byte{0x1F, 0xA6, 0xDE, 0xBA, 0xCC, 0x13, 0x7D, 0x74}
	tmpTape := t.TempDir() + "/tape.cas"
	if err := os.WriteFile(tmpTape, fakeTape, 0644); err != nil {
		t.Fatalf("failed to write temp tape: %v", err)
	}

	if err := m.LoadTape(tmpTape); err != nil {
		t.Fatalf("LoadTape failed: %v", err)
	}
	if m.Tape == nil || len(m.Tape.Data) != len(fakeTape) || m.Config.TapePath != tmpTape {
		t.Fatalf("Tape not properly loaded: tape=%v, path=%q", m.Tape, m.Config.TapePath)
	}

	// Advance tape position and test RewindTape
	m.Tape.Pos = 5
	// Eject Tape
	m.EjectTape()
	if m.Tape == nil || len(m.Tape.Data) != 0 || m.Config.TapePath != "" {
		t.Fatalf("Tape was not properly ejected: tape=%v, path=%q", m.Tape, m.Config.TapePath)
	}
}

func TestSaveAndLoadSTA(t *testing.T) {
	cfg := DefaultConfig()
	cfg.Model = ModelMSX2
	m, err := NewMachine(cfg)
	if err != nil {
		t.Fatalf("failed to create machine: %v", err)
	}

	// Run 10 frames to advance CPU, memory, and VDP
	for f := 0; f < 10; f++ {
		m.StepFrame()
	}

	// Record original states
	origPC := m.CPU.PC
	origSP := m.CPU.SP
	origAF := m.CPU.AF()
	origBC := m.CPU.BC()
	origDE := m.CPU.DE()
	origHL := m.CPU.HL()
	origPSL := m.Slots.PSLReg

	// Write signature into RAM and VRAM
	m.Mapper.RAMData[0x1234] = 0x5A
	m.VDP.VRAM[0x0800] = 0xC3

	tmpSTA := t.TempDir() + "/test_snapshot.sta"
	if err := m.SaveSTA(tmpSTA); err != nil {
		t.Fatalf("SaveSTA failed: %v", err)
	}

	// Verify file was written and check header
	data, err := os.ReadFile(tmpSTA)
	if err != nil {
		t.Fatalf("failed to read written STA file: %v", err)
	}
	if len(data) < STAHeaderSize {
		t.Fatalf("STA file too small: %d bytes", len(data))
	}
	if string(data[:5]) != STAMagic {
		t.Fatalf("invalid STA magic: %q", string(data[:5]))
	}
	if int(data[5]) != m.Config.RAMPages || int(data[6]) != m.Config.VRAMPages {
		t.Fatalf("header pages mismatch: RAM=%d, VRAM=%d", data[5], data[6])
	}
	t.Logf("STA snapshot file size: %d bytes (Magic: %s, RAMPages: %d, VRAMPages: %d)",
		len(data), string(data[:5]), data[5], data[6])

	// Corrupt states in memory
	m.CPU.PC = 0xDEAD
	m.CPU.SP = 0xBEEF
	m.CPU.SetAF(0x1234)
	m.Slots.SetPSL(0x00)
	m.Mapper.RAMData[0x1234] = 0x00
	m.VDP.VRAM[0x0800] = 0x00

	// Restore from STA
	if err := m.LoadSTA(tmpSTA); err != nil {
		t.Fatalf("LoadSTA failed: %v", err)
	}

	// Verify restored state matches original exactly
	if m.CPU.PC != origPC {
		t.Fatalf("PC not restored: expected %04Xh, got %04Xh", origPC, m.CPU.PC)
	}
	if m.CPU.SP != origSP {
		t.Fatalf("SP not restored: expected %04Xh, got %04Xh", origSP, m.CPU.SP)
	}
	if m.CPU.AF() != origAF {
		t.Fatalf("AF not restored: expected %04Xh, got %04Xh", origAF, m.CPU.AF())
	}
	if m.CPU.BC() != origBC {
		t.Fatalf("BC not restored: expected %04Xh, got %04Xh", origBC, m.CPU.BC())
	}
	if m.CPU.DE() != origDE {
		t.Fatalf("DE not restored: expected %04Xh, got %04Xh", origDE, m.CPU.DE())
	}
	if m.CPU.HL() != origHL {
		t.Fatalf("HL not restored: expected %04Xh, got %04Xh", origHL, m.CPU.HL())
	}
	if m.Slots.PSLReg != origPSL {
		t.Fatalf("PSL not restored: expected %02Xh, got %02Xh", origPSL, m.Slots.PSLReg)
	}
	if m.Mapper.RAMData[0x1234] != 0x5A {
		t.Fatalf("RAM data not restored: expected 5Ah, got %02Xh", m.Mapper.RAMData[0x1234])
	}
	if m.VDP.VRAM[0x0800] != 0xC3 {
		t.Fatalf("VRAM data not restored: expected C3h, got %02Xh", m.VDP.VRAM[0x0800])
	}

	t.Logf("State snapshot successfully restored all CPU registers, memory and VRAM!")
}

func TestWD1793Emulation(t *testing.T) {
	cfg := DefaultConfig()
	m, err := NewMachine(cfg)
	if err != nil {
		t.Fatalf("failed to create machine: %v", err)
	}

	fdc := m.FDC
	if fdc == nil {
		t.Fatal("expected FDC to be initialized on machine")
	}

	// 1. Test RESTORE command (0x00)
	fdc.Track[0] = 12
	fdc.Write(WD1793Command, 0x00)
	if fdc.Track[0] != 0 || (fdc.R[0]&FTrack0) == 0 || (fdc.IRQ&WD1793IRQ) == 0 {
		t.Fatalf("RESTORE failed: track=%d, status=%02Xh, irq=%02Xh", fdc.Track[0], fdc.R[0], fdc.IRQ)
	}

	// 2. Test SEEK command (0x10) to track 5
	fdc.R[3] = 5
	fdc.Write(WD1793Command, 0x10)
	if fdc.Track[0] != 5 || fdc.R[1] != 5 || (fdc.IRQ&WD1793IRQ) == 0 {
		t.Fatalf("SEEK failed: track=%d, R[1]=%d, irq=%02Xh", fdc.Track[0], fdc.R[1], fdc.IRQ)
	}

	// 3. Test STEP-IN (0x40) and STEP-OUT (0x60)
	fdc.Write(WD1793Command, 0x50) // STEP-IN with update (moves head inward: track increments)
	if fdc.Track[0] != 6 || fdc.R[1] != 6 {
		t.Fatalf("STEP-IN failed: track=%d, R[1]=%d", fdc.Track[0], fdc.R[1])
	}

	fdc.Write(WD1793Command, 0x70) // STEP-OUT with update (moves head outward: track decrements)
	if fdc.Track[0] != 5 || fdc.R[1] != 5 {
		t.Fatalf("STEP-OUT failed: track=%d, R[1]=%d", fdc.Track[0], fdc.R[1])
	}

	// 4. Mount a 720KB disk with boot block into drive 0
	diskData := make([]byte, 720*1024)
	copy(diskData, BootBlock)
	tmpDsk := t.TempDir() + "/wd_test.dsk"
	if err := os.WriteFile(tmpDsk, diskData, 0644); err != nil {
		t.Fatalf("failed to write test disk: %v", err)
	}
	if err := m.LoadDisk(0, tmpDsk); err != nil {
		t.Fatalf("LoadDisk failed: %v", err)
	}

	// Select Drive A (0), Side 0
	fdc.Write(WD1793System, 0x00|SDensity|SSide) // Drive 0, Side 0

	// Seek track 0
	fdc.Write(WD1793Command, 0x00) // RESTORE

	// 5. Test READ SECTORS (0x80): read sector 1
	fdc.R[2] = 1 // Sector 1
	fdc.Write(WD1793Command, 0x80)

	if (fdc.R[0] & (FBusy | FDRQ)) == 0 || (fdc.IRQ & WD1793DRQ) == 0 {
		t.Fatalf("READ SECTORS command did not raise DRQ/Busy: status=%02Xh, irq=%02Xh", fdc.R[0], fdc.IRQ)
	}

	// Read 512 bytes sequentially from Data register
	readBuf := make([]byte, 512)
	for i := 0; i < 512; i++ {
		readBuf[i] = fdc.Read(WD1793Data)
	}

	// Verify DRQ and Busy cleared, IRQ generated
	if (fdc.R[0] & FBusy) != 0 || (fdc.IRQ & WD1793IRQ) == 0 {
		t.Fatalf("READ completed state incorrect: status=%02Xh, irq=%02Xh", fdc.R[0], fdc.IRQ)
	}

	// Verify byte 0 is boot block jump instruction 0xEB
	if readBuf[0] != 0xEB {
		t.Fatalf("First byte of boot sector mismatch: expected EBh, got %02Xh", readBuf[0])
	}

	// 6. Test WRITE SECTORS (0xA0): write sector 2
	fdc.R[2] = 2 // Sector 2
	fdc.Write(WD1793Command, 0xA0)

	if (fdc.R[0] & (FBusy | FDRQ)) == 0 || (fdc.IRQ & WD1793DRQ) == 0 {
		t.Fatalf("WRITE SECTORS command did not raise DRQ/Busy: status=%02Xh, irq=%02Xh", fdc.R[0], fdc.IRQ)
	}

	writeBuf := make([]byte, 512)
	for i := 0; i < 512; i++ {
		writeBuf[i] = byte(i ^ 0xAA)
		fdc.Write(WD1793Data, writeBuf[i])
	}

	// Verify sector 2 in diskData buffer was updated
	sec2Offset := 1 * 512 // track 0, side 0, sector 2 (0-indexed sector 1)
	for i := 0; i < 512; i++ {
		if m.FDD[0].Data[sec2Offset+i] != writeBuf[i] {
			t.Fatalf("Written disk byte mismatch at byte %d: expected %02X, got %02X",
				i, writeBuf[i], m.FDD[0].Data[sec2Offset+i])
		}
	}

	t.Logf("WD1793 FDC emulation passed all tests: SEEK, RESTORE, STEP, READ SECTORS & WRITE SECTORS!")
}
