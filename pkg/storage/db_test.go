package storage

import (
	"os"
	"path/filepath"
	"testing"
)

func TestStorageDB(t *testing.T) {
	tempDir := t.TempDir()
	dbPath := filepath.Join(tempDir, "test.db")

	db, err := Open(dbPath)
	if err != nil {
		t.Fatalf("Open failed: %v", err)
	}
	defer db.Close()

	// Test storing a ROM
	sampleROM := []byte{0xF3, 0xC3, 0x00, 0x40}
	if err := db.StoreROM("TEST.ROM", "machine_bios", "MSX2", sampleROM); err != nil {
		t.Fatalf("StoreROM failed: %v", err)
	}

	if !db.HasROM("TEST.ROM") {
		t.Fatalf("HasROM returned false")
	}

	retrieved, err := db.GetROM("TEST.ROM")
	if err != nil {
		t.Fatalf("GetROM failed: %v", err)
	}
	if len(retrieved) != len(sampleROM) || retrieved[0] != 0xF3 {
		t.Fatalf("Retrieved data mismatch")
	}

	// Test config
	if err := db.SetConfig("video", "NTSC"); err != nil {
		t.Fatalf("SetConfig failed: %v", err)
	}
	val := db.GetConfig("video", "PAL")
	if val != "NTSC" {
		t.Fatalf("Expected NTSC, got %s", val)
	}

	// Test manual
	if err := db.StoreManual("CLI", "Command Line Help", "Type help for info"); err != nil {
		t.Fatalf("StoreManual failed: %v", err)
	}
	title, content, err := db.GetManual("CLI")
	if err != nil || title != "Command Line Help" || content != "Type help for info" {
		t.Fatalf("GetManual failed")
	}

	// Test seeding from third-party/fMSX/ROMs if available
	romDir := filepath.Join("..", "..", "third-party", "fMSX", "ROMs")
	if _, err := os.Stat(romDir); err == nil {
		count, err := db.SeedFromROMDir(romDir)
		if err != nil {
			t.Fatalf("SeedFromROMDir failed: %v", err)
		}
		t.Logf("Seeded %d ROMs from %s", count, romDir)
		if count < 5 {
			t.Fatalf("Expected at least 5 seeded ROMs, got %d", count)
		}
	}
}
