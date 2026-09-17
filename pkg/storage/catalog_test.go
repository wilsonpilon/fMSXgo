package storage

import (
	"os"
	"path/filepath"
	"testing"
)

func TestCatalogCRUD(t *testing.T) {
	tempDB := filepath.Join(t.TempDir(), "test_catalog.db")
	db, err := Open(tempDB)
	if err != nil {
		t.Fatalf("Failed to open test DB: %v", err)
	}
	defer db.Close()

	// 1. Create / Store custom ROM
	romBytes := []byte{0xF3, 0xC3, 0x00, 0xC0, 0x00, 0x00}
	item := ROMCatalogItem{
		Name:         "MY_CUSTOM_BIOS.ROM",
		Title:        "Custom Experimental BIOS",
		Category:     "bios",
		MachineModel: "MSX2",
		Description:  "Custom modified BIOS for testing",
		IsDefault:    false,
		IsVerified:   false,
	}

	if err := db.StoreCatalogROM(item, romBytes); err != nil {
		t.Fatalf("StoreCatalogROM failed: %v", err)
	}

	// 2. Read metadata and data
	fetched, err := db.GetCatalogItem("MY_CUSTOM_BIOS.ROM")
	if err != nil {
		t.Fatalf("GetCatalogItem failed: %v", err)
	}
	if fetched.Title != "Custom Experimental BIOS" {
		t.Fatalf("Expected Title 'Custom Experimental BIOS', got %q", fetched.Title)
	}
	if fetched.Size != len(romBytes) {
		t.Fatalf("Expected size %d, got %d", len(romBytes), fetched.Size)
	}
	if fetched.SHA1 == "" {
		t.Fatalf("Expected calculated SHA1, got empty string")
	}

	data, err := db.GetCatalogData("MY_CUSTOM_BIOS.ROM")
	if err != nil {
		t.Fatalf("GetCatalogData failed: %v", err)
	}
	if len(data) != len(romBytes) {
		t.Fatalf("Data mismatch: expected length %d, got %d", len(romBytes), len(data))
	}

	// 3. Update metadata
	if err := db.UpdateCatalogItem("MY_CUSTOM_BIOS.ROM", "Updated BIOS Title", "New description", "bios", "MSX2"); err != nil {
		t.Fatalf("UpdateCatalogItem failed: %v", err)
	}
	updated, _ := db.GetCatalogItem("MY_CUSTOM_BIOS.ROM")
	if updated.Title != "Updated BIOS Title" {
		t.Fatalf("Expected updated title, got %q", updated.Title)
	}

	// 4. Test Set Default
	if err := db.SetCatalogDefault("MY_CUSTOM_BIOS.ROM"); err != nil {
		t.Fatalf("SetCatalogDefault failed: %v", err)
	}
	updated, _ = db.GetCatalogItem("MY_CUSTOM_BIOS.ROM")
	if !updated.IsDefault {
		t.Fatalf("Expected IsDefault to be true")
	}

	// 5. Test ListCatalog with filters
	list, err := db.ListCatalog("bios", "MSX2")
	if err != nil {
		t.Fatalf("ListCatalog failed: %v", err)
	}
	if len(list) != 1 {
		t.Fatalf("Expected 1 bios item for MSX2, got %d", len(list))
	}

	// 6. Test Delete
	if err := db.DeleteCatalogROM("MY_CUSTOM_BIOS.ROM", false); err != nil {
		t.Fatalf("DeleteCatalogROM failed: %v", err)
	}
	if _, err := db.GetCatalogItem("MY_CUSTOM_BIOS.ROM"); err == nil {
		t.Fatalf("Expected ROM to be deleted")
	}
}

func TestCatalogOfficialSeeding(t *testing.T) {
	tempDB := filepath.Join(t.TempDir(), "test_official.db")
	db, err := Open(tempDB)
	if err != nil {
		t.Fatalf("Failed to open test DB: %v", err)
	}
	defer db.Close()

	// Create dummy ROM directory mimicking third-party/fMSX/ROMs
	tempROMDir := t.TempDir()
	os.WriteFile(filepath.Join(tempROMDir, "MSX2.ROM"), []byte("DUMMY_MSX2_ROM_DATA_1234567890"), 0644)
	os.WriteFile(filepath.Join(tempROMDir, "DISK.ROM"), []byte("DUMMY_DISK_ROM_DATA_1234567890"), 0644)

	seeded, err := db.SeedFromROMDir(tempROMDir)
	if err != nil {
		t.Fatalf("SeedFromROMDir failed: %v", err)
	}
	if seeded != 2 {
		t.Fatalf("Expected 2 ROMs seeded, got %d", seeded)
	}

	// Check MSX2.ROM has default and verified flags set
	item, err := db.GetCatalogItem("MSX2.ROM")
	if err != nil {
		t.Fatalf("GetCatalogItem(MSX2.ROM) failed: %v", err)
	}
	if !item.IsDefault {
		t.Fatalf("Expected MSX2.ROM to be Default")
	}
	if !item.IsVerified {
		t.Fatalf("Expected MSX2.ROM to be Verified (Garantida de Execução)")
	}
	if item.Category != "bios" {
		t.Fatalf("Expected MSX2.ROM category 'bios', got %q", item.Category)
	}

	// Test protection: official verified default cannot be deleted without force
	if err := db.DeleteCatalogROM("MSX2.ROM", false); err == nil {
		t.Fatalf("Expected protection error when deleting verified default ROM without force")
	}

	// Forced deletion works
	if err := db.DeleteCatalogROM("MSX2.ROM", true); err != nil {
		t.Fatalf("Expected forced delete to succeed: %v", err)
	}
}
