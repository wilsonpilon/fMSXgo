package msx

import (
	"os"
	"path/filepath"
	"testing"
)

func TestSymbolTableDefaultsAndLookup(t *testing.T) {
	st := NewSymbolTable()

	// Verify standard BIOS symbol CHPUT is present at 0x00A2
	name, ok := st.Lookup(0x00A2)
	if !ok || name != "CHPUT" {
		t.Fatalf("expected CHPUT at 00A2h, got %s, ok=%v", name, ok)
	}

	addr, ok := st.Find("chput")
	if !ok || addr != 0x00A2 {
		t.Fatalf("expected 00A2h for 'chput', got %04X, ok=%v", addr, ok)
	}

	annot := st.FormatAnnotation(0x00A2)
	if annot != " <CHPUT>" {
		t.Fatalf("expected ' <CHPUT>', got '%s'", annot)
	}
}

func TestSymbolTableParsingFormats(t *testing.T) {
	lines := []string{
		"PLAYER_X: EQU 0xC000",
		"PLAYER_Y EQU $C001",
		"ENEMIES: defl C002h ; enemy counter",
		"0xC010 SCORE",
		"LIVES 0xC012 // player lives",
	}

	st := NewSymbolTable()
	for _, l := range lines {
		name, addr, ok := ParseSymbolLine(l)
		if !ok {
			t.Fatalf("failed to parse line: %s", l)
		}
		st.Add(name, addr)
	}

	check := map[string]uint16{
		"PLAYER_X": 0xC000,
		"PLAYER_Y": 0xC001,
		"ENEMIES":  0xC002,
		"SCORE":    0xC010,
		"LIVES":    0xC012,
	}

	for n, expected := range check {
		a, ok := st.Find(n)
		if !ok || a != expected {
			t.Fatalf("symbol %s expected %04X, got %04X (ok=%v)", n, expected, a, ok)
		}
	}
}

func TestSymbolTableLoadFile(t *testing.T) {
	tmpDir := t.TempDir()
	symPath := filepath.Join(tmpDir, "test.sym")
	content := `
; Test MSX symbols
INIT_GAME: EQU 4000h
LOOP_GAME: EQU 4010h
DATA_TBL   EQU 8000h
`
	if err := os.WriteFile(symPath, []byte(content), 0644); err != nil {
		t.Fatal(err)
	}

	st := NewSymbolTable()
	count, err := st.LoadFile(symPath)
	if err != nil {
		t.Fatalf("load file failed: %v", err)
	}
	if count != 3 {
		t.Fatalf("expected 3 symbols loaded, got %d", count)
	}

	list := st.List("GAME")
	if len(list) != 2 {
		t.Fatalf("expected 2 symbols matching 'GAME', got %d", len(list))
	}
}
