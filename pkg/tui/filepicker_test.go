package tui

import (
	"bytes"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestMatchesExtension(t *testing.T) {
	exts := []string{".dsk", ".di1", ".img"}

	cases := []struct {
		filename string
		expected bool
	}{
		{"game.dsk", true},
		{"GAME.DSK", true},
		{"disk1.di1", true},
		{"FLOPPY.IMG", true},
		{"game.rom", false},
		{"program.bin", false},
		{"source.bas", false},
	}

	for _, c := range cases {
		got := MatchesExtension(c.filename, exts)
		if got != c.expected {
			t.Errorf("MatchesExtension(%q) = %v; want %v", c.filename, got, c.expected)
		}
	}

	// Empty extension list matches everything
	if !MatchesExtension("anything.xyz", nil) {
		t.Errorf("MatchesExtension with nil exts should match all")
	}
}

func TestFormatFileSize(t *testing.T) {
	if FormatFileSize(512) != "512 B" {
		t.Errorf("Expected '512 B', got %q", FormatFileSize(512))
	}
	if FormatFileSize(737280) != "720 KB" {
		t.Errorf("Expected '720 KB', got %q", FormatFileSize(737280))
	}
	if FormatFileSize(368640) != "360 KB" {
		t.Errorf("Expected '360 KB', got %q", FormatFileSize(368640))
	}
	if FormatFileSize(1024*1024*2) != "2.0 MB" {
		t.Errorf("Expected '2.0 MB', got %q", FormatFileSize(1024*1024*2))
	}
}

func TestLoadDirectoryEntries(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "fmsxgo_tui_test_*")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create test files and directories
	_ = os.Mkdir(filepath.Join(tempDir, "subdir"), 0755)
	_ = os.WriteFile(filepath.Join(tempDir, "game.dsk"), []byte("dummy disk"), 0644)
	_ = os.WriteFile(filepath.Join(tempDir, "aleste.dsk"), []byte("aleste disk"), 0644)
	_ = os.WriteFile(filepath.Join(tempDir, "cart.rom"), []byte("cartridge"), 0644)
	_ = os.WriteFile(filepath.Join(tempDir, "code.bin"), []byte("binary"), 0644)

	// 1. With .dsk filter active
	items, err := LoadDirectoryEntries(tempDir, []string{".dsk"}, true, false)
	if err != nil {
		t.Fatalf("LoadDirectoryEntries error: %v", err)
	}

	names := make(map[string]bool)
	for _, item := range items {
		names[item.Name] = true
	}

	if !names[".."] {
		t.Errorf("Expected '..' entry in items")
	}
	if !names["subdir"] {
		t.Errorf("Expected 'subdir' directory in items")
	}
	if !names["game.dsk"] || !names["aleste.dsk"] {
		t.Errorf("Expected game.dsk and aleste.dsk in filtered items")
	}
	if names["cart.rom"] || names["code.bin"] {
		t.Errorf("cart.rom and code.bin should be filtered out when filterActive=true")
	}

	// 2. With filter deactivated (*.*)
	allitems, err := LoadDirectoryEntries(tempDir, []string{".dsk"}, false, false)
	if err != nil {
		t.Fatalf("LoadDirectoryEntries error: %v", err)
	}

	allNames := make(map[string]bool)
	for _, item := range allitems {
		allNames[item.Name] = true
	}

	if !allNames["cart.rom"] || !allNames["code.bin"] {
		t.Errorf("Expected cart.rom and code.bin when filterActive=false")
	}
}

func TestRenderFilePicker(t *testing.T) {
	opts := FilePickerOptions{
		Title:      "Test Picker",
		Extensions: []string{".dsk"},
	}
	items := []FileItem{
		{Name: "..", IsDir: true},
		{Name: "disks", IsDir: true},
		{Name: "aleste.dsk", IsDir: false, Size: 737280},
	}

	var sb strings.Builder
	RenderFilePicker(&sb, opts, "/tmp", items, 0, 0, 10, true)
	out := sb.String()

	if !strings.Contains(out, "Test Picker") {
		t.Errorf("Expected title in rendered output")
	}
	if !strings.Contains(out, "aleste.dsk") {
		t.Errorf("Expected item aleste.dsk in rendered output")
	}
	if !strings.Contains(out, "720 KB") {
		t.Errorf("Expected 720 KB in rendered output")
	}
	if !strings.Contains(out, "[*.dsk]") {
		t.Errorf("Expected filter in rendered output")
	}
}

func TestOpenFilePickerNonTerminal(t *testing.T) {
	var inBuf bytes.Buffer
	var outBuf bytes.Buffer

	opts := FilePickerOptions{
		Title:      "Select DSK",
		Extensions: []string{".dsk"},
		In:         &inBuf,
		Out:        &outBuf,
	}

	_, err := OpenFilePicker(opts)
	if !errors.Is(err, ErrNonInteractive) {
		t.Errorf("Expected ErrNonInteractive when In is not a terminal, got %v", err)
	}
}

func TestRenderSavePicker(t *testing.T) {
	opts := SavePickerOptions{
		Title:       "Create New Disk",
		DefaultName: "testdisk.dsk",
	}
	items := []FileItem{
		{Name: "[+] SAVE HERE as \"testdisk.dsk\"", IsDir: false},
		{Name: "..", IsDir: true},
		{Name: "existing.dsk", IsDir: false, Size: 737280},
	}

	var sb strings.Builder
	RenderSavePicker(&sb, opts, "/tmp", "testdisk.dsk", items, 0, 0, 10, false, "")
	out := sb.String()

	if !strings.Contains(out, "Create New Disk") {
		t.Errorf("Expected title in rendered save picker output")
	}
	if !strings.Contains(out, "testdisk.dsk") {
		t.Errorf("Expected default name in output")
	}
	if !strings.Contains(out, "SAVE HERE") {
		t.Errorf("Expected SAVE HERE action item in output")
	}
}

func TestOpenSavePickerNonTerminal(t *testing.T) {
	var inBuf bytes.Buffer
	var outBuf bytes.Buffer

	opts := SavePickerOptions{
		Title:       "Create New Disk",
		DefaultName: "testdisk.dsk",
		In:          &inBuf,
		Out:         &outBuf,
	}

	_, err := OpenSavePicker(opts)
	if !errors.Is(err, ErrNonInteractive) {
		t.Errorf("Expected ErrNonInteractive when In is not a terminal, got %v", err)
	}
}

