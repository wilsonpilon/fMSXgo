package ui

import (
	"path/filepath"
	"testing"

	"fmsxgo/pkg/storage"
)

func TestControllerConfigDefaultAndPersistence(t *testing.T) {
	cfg := DefaultControllerConfig()
	if cfg.Deadzone[0] != 0.35 || cfg.Deadzone[1] != 0.35 {
		t.Fatalf("Expected default deadzones of 0.35, got %.2f and %.2f", cfg.Deadzone[0], cfg.Deadzone[1])
	}
	if cfg.SwapAB[0] != false || cfg.SwapAB[1] != false {
		t.Fatalf("Expected default SwapAB to be false")
	}

	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "test_ctrl.db")
	db, err := storage.Open(dbPath)
	if err != nil {
		t.Fatalf("Failed to open test db: %v", err)
	}
	defer db.Close()

	// Modify settings
	cfg.Deadzone[0] = 0.20
	cfg.Deadzone[1] = 0.45
	cfg.SwapAB[0] = true
	cfg.SwapAB[1] = false

	cfg.Save(db)

	// Load into fresh config
	loaded := DefaultControllerConfig()
	loaded.Load(db)

	if loaded.Deadzone[0] < 0.19 || loaded.Deadzone[0] > 0.21 {
		t.Errorf("Expected joy1 deadzone 0.20, got %.2f", loaded.Deadzone[0])
	}
	if loaded.Deadzone[1] < 0.44 || loaded.Deadzone[1] > 0.46 {
		t.Errorf("Expected joy2 deadzone 0.45, got %.2f", loaded.Deadzone[1])
	}
	if loaded.SwapAB[0] != true {
		t.Errorf("Expected joy1 SwapAB true, got %v", loaded.SwapAB[0])
	}
	if loaded.SwapAB[1] != false {
		t.Errorf("Expected joy2 SwapAB false, got %v", loaded.SwapAB[1])
	}
}
