package msx

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"fmsxgo/pkg/storage"
)

// ROMManager locates and loads BIOS ROM files from SQLite or filesystem.
type ROMManager struct {
	SearchPaths []string
	LoadedROMs  map[string][]byte
	DB          *storage.DB
}

// NewROMManager creates a ROMManager with standard search directories and optional SQLite DB.
func NewROMManager(db *storage.DB, extraPaths ...string) *ROMManager {
	paths := []string{
		"ROMs",
		filepath.Join("third-party", "fMSX", "ROMs"),
		filepath.Join("..", "third-party", "fMSX", "ROMs"),
		filepath.Join("..", "..", "third-party", "fMSX", "ROMs"),
		".",
	}
	paths = append(extraPaths, paths...)

	return &ROMManager{
		SearchPaths: paths,
		LoadedROMs:  make(map[string][]byte),
		DB:          db,
	}
}

// FindROM searches for a ROM file by name across the configured search paths.
func (rm *ROMManager) FindROM(name string) (string, error) {
	for _, p := range rm.SearchPaths {
		candidate := filepath.Join(p, name)
		if fi, err := os.Stat(candidate); err == nil && !fi.IsDir() {
			return candidate, nil
		}
	}
	return "", fmt.Errorf("ROM file %q not found in search paths: %v", name, rm.SearchPaths)
}

// LoadROM loads a ROM file from SQLite or disk, caching in memory.
func (rm *ROMManager) LoadROM(name string) ([]byte, error) {
	if data, ok := rm.LoadedROMs[name]; ok {
		return data, nil
	}

	// 1. Try loading from SQLite database catalog first
	if rm.DB != nil {
		data, err := rm.DB.GetCatalogData(name)
		if err == nil && len(data) > 0 {
			rm.LoadedROMs[name] = data
			return data, nil
		}
	}

	// 2. Fallback to filesystem
	path, err := rm.FindROM(name)
	if err != nil {
		return nil, err
	}

	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read ROM %q at %s: %w", name, path, err)
	}

	// Also auto-save to SQLite if DB is connected
	if rm.DB != nil {
		_ = rm.DB.StoreROM(name, "auto_imported", "ALL", data)
	}

	rm.LoadedROMs[name] = data
	return data, nil
}

// LoadDefaultROM loads the active default ROM from the catalog for a given category and machine model.
func (rm *ROMManager) LoadDefaultROM(category, machineModel string) ([]byte, string, error) {
	if rm.DB != nil {
		item, data, err := rm.DB.GetDefaultROM(category, machineModel)
		if err == nil && len(data) > 0 {
			rm.LoadedROMs[item.Name] = data
			return data, item.Name, nil
		}
	}

	// Fallback to official fMSX default filenames
	var fallbackName string
	catLower := strings.ToLower(category)
	switch catLower {
	case "bios", "basic":
		switch strings.ToUpper(machineModel) {
		case "MSX1":
			fallbackName = "MSX.ROM"
		case "MSX2":
			fallbackName = "MSX2.ROM"
		case "MSX2+", "MSX2P":
			fallbackName = "MSX2P.ROM"
		default:
			fallbackName = "MSX.ROM"
		}
	case "subrom":
		switch strings.ToUpper(machineModel) {
		case "MSX2":
			fallbackName = "MSX2EXT.ROM"
		case "MSX2+", "MSX2P":
			fallbackName = "MSX2PEXT.ROM"
		default:
			fallbackName = "MSX2EXT.ROM"
		}
	case "disk":
		fallbackName = "DISK.ROM"
	case "hardware":
		fallbackName = "FMPAC.ROM"
	case "cartridge":
		fallbackName = "PAINTER.ROM"
	}

	if fallbackName != "" {
		data, err := rm.LoadROM(fallbackName)
		if err == nil {
			return data, fallbackName, nil
		}
	}

	return nil, "", fmt.Errorf("no default ROM found for category %q and model %q", category, machineModel)
}
