package msx

import (
	"fmt"
	"os"
	"path/filepath"

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

	// 1. Try loading from SQLite database first
	if rm.DB != nil && rm.DB.HasROM(name) {
		data, err := rm.DB.GetROM(name)
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
