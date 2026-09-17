package shell

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"fmsxgo/pkg/msx"
	"fmsxgo/pkg/storage"
)

func TestShellCommands(t *testing.T) {
	cfg := msx.DefaultConfig()
	machine, err := msx.NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	var inBuf bytes.Buffer
	var outBuf bytes.Buffer

	sh := New(machine, &inBuf, &outBuf)

	// Test single-line assemble
	sh.ExecuteCommand("a C000 LD A, 2Ah")
	sh.ExecuteCommand("a C002 HALT")

	// Set PC to C000h
	sh.ExecuteCommand("r pc C000")
	if machine.CPU.PC != 0xC000 {
		t.Fatalf("Expected PC = 0xC000, got %04X", machine.CPU.PC)
	}

	// Step instruction
	sh.ExecuteCommand("t 1")
	if machine.CPU.A != 0x2A {
		t.Fatalf("Expected A = 0x2A, got %02X", machine.CPU.A)
	}

	// Test slots command
	outBuf.Reset()
	sh.ExecuteCommand("slots")
	slotsOutput := outBuf.String()
	if !strings.Contains(slotsOutput, "Primary Slot Reg") {
		t.Fatalf("Expected slots output to contain 'Primary Slot Reg', got:\n%s", slotsOutput)
	}

	// Test mapper command
	outBuf.Reset()
	sh.ExecuteCommand("mapper")
	mapperOutput := outBuf.String()
	if !strings.Contains(mapperOutput, "RAM Mapper Total Pages") {
		t.Fatalf("Expected mapper output to contain 'RAM Mapper Total Pages', got:\n%s", mapperOutput)
	}

	// Test IO Out and In
	sh.ExecuteCommand("out 90 42")
	outBuf.Reset()
	sh.ExecuteCommand("in 90")
	inOutput := outBuf.String()
	if !strings.Contains(inOutput, "IN(90h)") {
		t.Fatalf("Expected in output, got:\n%s", inOutput)
	}

	// Test Language command
	outBuf.Reset()
	sh.ExecuteCommand("lang")
	if !strings.Contains(outBuf.String(), "Current UI language") {
		t.Fatalf("Expected language info, got:\n%s", outBuf.String())
	}

	outBuf.Reset()
	sh.ExecuteCommand("lang pt")
	if !strings.Contains(outBuf.String(), "Português") {
		t.Fatalf("Expected Portuguese language change confirmation, got:\n%s", outBuf.String())
	}

	outBuf.Reset()
	sh.ExecuteCommand("help")
	if !strings.Contains(outBuf.String(), "Controles Principais") {
		t.Fatalf("Expected Portuguese help output, got:\n%s", outBuf.String())
	}

	// Switch back to English
	sh.ExecuteCommand("lang en")

	// Test Theme command
	outBuf.Reset()
	sh.ExecuteCommand("theme")
	if !strings.Contains(outBuf.String(), "Available themes") {
		t.Fatalf("Expected available themes, got:\n%s", outBuf.String())
	}

	outBuf.Reset()
	sh.ExecuteCommand("theme dracula")
	if !strings.Contains(outBuf.String(), "dracula") {
		t.Fatalf("Expected dracula theme change, got:\n%s", outBuf.String())
	}

	// Test Font command
	outBuf.Reset()
	sh.ExecuteCommand("font")
	if !strings.Contains(outBuf.String(), "Available font families") {
		t.Fatalf("Expected font families list, got:\n%s", outBuf.String())
	}

	outBuf.Reset()
	sh.ExecuteCommand("font sourcecodepro")
	if !strings.Contains(outBuf.String(), "sourcecodepro") {
		t.Fatalf("Expected font change confirmation, got:\n%s", outBuf.String())
	}

	// Switch back to default Ubuntu
	sh.ExecuteCommand("font ubuntu")

	outBuf.Reset()
	sh.ExecuteCommand("theme github-dark")
	if !strings.Contains(outBuf.String(), "github-dark") {
		t.Fatalf("Expected github-dark theme change, got:\n%s", outBuf.String())
	}

	// Reset theme to system
	sh.ExecuteCommand("theme system")
}

func TestShellRomsCommand(t *testing.T) {
	dbPath := filepath.Join(t.TempDir(), "roms_test.db")
	db, err := storage.Open(dbPath)
	if err != nil {
		t.Fatalf("Failed to open DB: %v", err)
	}
	defer db.Close()

	// Seed catalog using self-contained temp ROM directory
	tempROMDir := t.TempDir()
	os.WriteFile(filepath.Join(tempROMDir, "MSX.ROM"), []byte("DUMMY_MSX1_ROM_DATA_1234567890"), 0644)
	os.WriteFile(filepath.Join(tempROMDir, "MSX2.ROM"), []byte("DUMMY_MSX2_ROM_DATA_1234567890"), 0644)
	os.WriteFile(filepath.Join(tempROMDir, "DISK.ROM"), []byte("DUMMY_DISK_ROM_DATA_1234567890"), 0644)

	seeded, err := db.SeedFromROMDir(tempROMDir)
	if err != nil || seeded != 3 {
		t.Fatalf("Failed to seed ROMs: %v, seeded: %d", err, seeded)
	}

	cfg := msx.DefaultConfig()
	cfg.DB = db
	cfg.ROMDir = tempROMDir
	machine, err := msx.NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	var inBuf bytes.Buffer
	var outBuf bytes.Buffer
	sh := New(machine, &inBuf, &outBuf)

	// 1. Test roms list
	outBuf.Reset()
	sh.ExecuteCommand("roms list")
	listOut := outBuf.String()
	if !strings.Contains(listOut, "MSX2.ROM") || !strings.Contains(listOut, "DEF") || !strings.Contains(listOut, "VER") {
		t.Fatalf("Expected roms list to contain MSX2.ROM with DEF/VER flags, got:\n%s", listOut)
	}

	// 2. Test roms info
	outBuf.Reset()
	sh.ExecuteCommand("roms info MSX2.ROM")
	infoOut := outBuf.String()
	if !strings.Contains(infoOut, "ROM Catalog Record: MSX2.ROM") || !strings.Contains(infoOut, "Guaranteed Execution") {
		t.Fatalf("Expected roms info to contain details and Guaranteed Execution, got:\n%s", infoOut)
	}

	// 3. Test roms verify
	outBuf.Reset()
	sh.ExecuteCommand("roms verify")
	verifyOut := outBuf.String()
	if !strings.Contains(verifyOut, "All catalog ROMs passed SHA-1 and BLOB integrity checks") {
		t.Fatalf("Expected all catalog ROMs to pass integrity check, got:\n%s", verifyOut)
	}

	// 4. Test roms default
	outBuf.Reset()
	sh.ExecuteCommand("roms default MSX.ROM")
	defOut := outBuf.String()
	if !strings.Contains(defOut, "active default") {
		t.Fatalf("Expected active default confirmation, got:\n%s", defOut)
	}

	// 5. Test roms add with a dummy custom ROM file
	tmpROM := filepath.Join(t.TempDir(), "CUSTOM_TEST.ROM")
	testData := []byte("MSX_CUSTOM_TEST_ROM_CONTENT_12345")
	if err := os.WriteFile(tmpROM, testData, 0644); err != nil {
		t.Fatalf("Failed to create temp ROM: %v", err)
	}

	outBuf.Reset()
	sh.ExecuteCommand("roms add " + tmpROM + " cartridge MSX2 CUSTOM_TEST.ROM CustomTestTitle")
	addOut := outBuf.String()
	if !strings.Contains(addOut, "Successfully registered ROM") {
		t.Fatalf("Expected successful registration, got:\n%s", addOut)
	}

	// Verify custom item is in catalog
	item, err := db.GetCatalogItem("CUSTOM_TEST.ROM")
	if err != nil || item.Title != "CustomTestTitle" {
		t.Fatalf("Failed to retrieve custom ROM item: %v, item: %+v", err, item)
	}

	// 6. Test roms export
	exportFile := filepath.Join(t.TempDir(), "EXPORTED.ROM")
	outBuf.Reset()
	sh.ExecuteCommand("roms export CUSTOM_TEST.ROM " + exportFile)
	if !strings.Contains(outBuf.String(), "Exported ROM") {
		t.Fatalf("Expected export success, got:\n%s", outBuf.String())
	}
	exportedData, err := os.ReadFile(exportFile)
	if err != nil || string(exportedData) != string(testData) {
		t.Fatalf("Exported data does not match original: %v, got %q", err, string(exportedData))
	}

	// 7. Test roms del protection on verified official system ROM
	outBuf.Reset()
	sh.ExecuteCommand("roms del MSX2.ROM")
	if !strings.Contains(outBuf.String(), "Cannot delete ROM") {
		t.Fatalf("Expected deletion error on official verified system ROM without force, got:\n%s", outBuf.String())
	}

	// Delete the custom ROM
	outBuf.Reset()
	sh.ExecuteCommand("roms del CUSTOM_TEST.ROM")
	if !strings.Contains(outBuf.String(), "removed from catalog") {
		t.Fatalf("Expected custom ROM deletion, got:\n%s", outBuf.String())
	}
}

