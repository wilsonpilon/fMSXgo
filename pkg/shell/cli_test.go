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

func TestMegaAssemblerAndSuperXCompatibility(t *testing.T) {
	cfg := msx.DefaultConfig()
	machine, err := msx.NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	var inBuf bytes.Buffer
	var outBuf bytes.Buffer
	sh := New(machine, &inBuf, &outBuf)

	// Test exit commands (QUIT, BA, QT, BASIC, EXIT, Q)
	exitCmds := []string{"QUIT", "quit", "BA", "ba", "QT", "qt", "BASIC", "basic", "EXIT", "exit", "q", "Q"}
	for _, cmd := range exitCmds {
		if !sh.ExecuteCommand(cmd) {
			t.Errorf("Expected ExecuteCommand(%q) to return true (exit shell), got false", cmd)
		}
	}

	// Test register inspection aliases: 'x' (MegaAssembler) and 'rg' (Super-X)
	outBuf.Reset()
	sh.ExecuteCommand("x")
	if !strings.Contains(outBuf.String(), "AF:") || !strings.Contains(outBuf.String(), "PC:") {
		t.Errorf("Expected 'x' (MegaAssembler) to display registers, got:\n%s", outBuf.String())
	}

	outBuf.Reset()
	sh.ExecuteCommand("rg")
	if !strings.Contains(outBuf.String(), "AF:") || !strings.Contains(outBuf.String(), "PC:") {
		t.Errorf("Expected 'rg' (Super-X) to display registers, got:\n%s", outBuf.String())
	}

	// Test disassembly aliases: 'l' (MegaAssembler) and 'i' (Super-X)
	machine.CPU.PC = 0xC000
	sh.ExecuteCommand("a C000 NOP")
	sh.ExecuteCommand("a C001 HALT")

	outBuf.Reset()
	sh.ExecuteCommand("l C000 2")
	if !strings.Contains(outBuf.String(), "NOP") || !strings.Contains(outBuf.String(), "HALT") {
		t.Errorf("Expected 'l' (MegaAssembler) to disassemble, got:\n%s", outBuf.String())
	}

	outBuf.Reset()
	sh.ExecuteCommand("i C000 2")
	if !strings.Contains(outBuf.String(), "NOP") || !strings.Contains(outBuf.String(), "HALT") {
		t.Errorf("Expected 'i' (Super-X) to disassemble, got:\n%s", outBuf.String())
	}

	// Test trace alias: 'tr' (Super-X)
	machine.CPU.PC = 0xC000
	sh.ExecuteCommand("tr 1")
	if machine.CPU.PC != 0xC001 {
		t.Errorf("Expected 'tr' (Super-X) to step to 0xC001, got %04X", machine.CPU.PC)
	}

	// Test slots alias: 'page' and 'page?' (MegaAssembler)
	outBuf.Reset()
	sh.ExecuteCommand("page")
	if !strings.Contains(outBuf.String(), "Primary Slot Reg") {
		t.Errorf("Expected 'page' to show slots, got:\n%s", outBuf.String())
	}

	outBuf.Reset()
	sh.ExecuteCommand("page?")
	if !strings.Contains(outBuf.String(), "Primary Slot Reg") {
		t.Errorf("Expected 'page?' to show slots, got:\n%s", outBuf.String())
	}

	// Test I/O aliases: 'pi' and 'po' (Super-X)
	sh.ExecuteCommand("po 90 55")
	outBuf.Reset()
	sh.ExecuteCommand("pi 90")
	if !strings.Contains(outBuf.String(), "IN(90h)") {
		t.Errorf("Expected 'pi' (Super-X) to read port 90h, got:\n%s", outBuf.String())
	}
}

func TestDebuggerNumberBases(t *testing.T) {
	cfg := msx.DefaultConfig()
	machine, err := msx.NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	var inBuf bytes.Buffer
	var outBuf bytes.Buffer
	sh := New(machine, &inBuf, &outBuf)

	// 1. Default hex: 'r a 10' sets A to 0x10 (16)
	sh.ExecuteCommand("r a 10")
	if machine.CPU.A != 0x10 {
		t.Errorf("Expected 'r a 10' to set A=0x10, got %02X", machine.CPU.A)
	}

	// 2. Decimal prefix: 'r a d10' sets A to 10 (0x0A)
	sh.ExecuteCommand("r a d10")
	if machine.CPU.A != 0x0A {
		t.Errorf("Expected 'r a d10' to set A=0x0A, got %02X", machine.CPU.A)
	}

	// 3. Binary prefix: 'r a b1010' sets A to 10 (0x0A)
	sh.ExecuteCommand("r a b1010")
	if machine.CPU.A != 0x0A {
		t.Errorf("Expected 'r a b1010' to set A=0x0A, got %02X", machine.CPU.A)
	}

	// 4. Octal prefix: 'r a o12' sets A to 10 (0x0A)
	sh.ExecuteCommand("r a o12")
	if machine.CPU.A != 0x0A {
		t.Errorf("Expected 'r a o12' to set A=0x0A, got %02X", machine.CPU.A)
	}

	// 5. Hex prefix: 'r a h10' sets A to 0x10
	sh.ExecuteCommand("r a h10")
	if machine.CPU.A != 0x10 {
		t.Errorf("Expected 'r a h10' to set A=0x10, got %02X", machine.CPU.A)
	}

	// 6. Enter command with mixed bases
	sh.ExecuteCommand("e C000 10 d10 b1010 o12 h10")
	expected := []byte{0x10, 0x0A, 0x0A, 0x0A, 0x10}
	for i, exp := range expected {
		actual := machine.Bus.Read(uint16(0xC000 + i))
		if actual != exp {
			t.Errorf("At C00%X: expected %02X, got %02X", i, exp, actual)
		}
	}

	// 7. Mini-assembler command through shell
	sh.ExecuteCommand("a C010 LD A, d25")
	if machine.Bus.Read(0xC010) != 0x3E || machine.Bus.Read(0xC011) != 25 {
		t.Errorf("Expected 'LD A, d25' to assemble [3E 19], got [%02X %02X]",
			machine.Bus.Read(0xC010), machine.Bus.Read(0xC011))
	}
}

func TestCommandDM(t *testing.T) {
	cfg := msx.DefaultConfig()
	machine, err := msx.NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	var inBuf bytes.Buffer
	var outBuf bytes.Buffer
	sh := New(machine, &inBuf, &outBuf)

	// Write 'A' (0x41), 'B' (0x42), 'C' (0x43) at C000h
	sh.ExecuteCommand("e C000 41 42 43")

	// 1. Test standard DM C000 (desloc = 0)
	outBuf.Reset()
	sh.ExecuteCommand("dm C000")
	out := outBuf.String()
	if !strings.Contains(out, "=== Display & Memory Edit (DM) ===") {
		t.Errorf("Expected DM header, got:\n%s", out)
	}
	if !strings.Contains(out, "41 42 43") || !strings.Contains(out, "|ABC") {
		t.Errorf("Expected raw '41 42 43' / 'ABC', got:\n%s", out)
	}
	if sh.LastDump != 0xC000+128 {
		t.Errorf("Expected LastDump = %04X, got %04X", 0xC000+128, sh.LastDump)
	}

	// 2. Test DM C000, 1 (desloc = +1: 'A' -> 'B', 'B' -> 'C', 'C' -> 'D')
	outBuf.Reset()
	sh.ExecuteCommand("dm C000, 1")
	out = outBuf.String()
	if !strings.Contains(out, "Displacement: +1") {
		t.Errorf("Expected Displacement: +1, got:\n%s", out)
	}
	if !strings.Contains(out, "42 43 44") || !strings.Contains(out, "|BCD") {
		t.Errorf("Expected displaced '42 43 44' / 'BCD', got:\n%s", out)
	}

	// 3. Test DM C000, -1 (desloc = -1: 'A' -> '@', 'B' -> 'A', 'C' -> 'B')
	outBuf.Reset()
	sh.ExecuteCommand("dm C000, -1")
	out = outBuf.String()
	if !strings.Contains(out, "Displacement: -1") {
		t.Errorf("Expected Displacement: -1, got:\n%s", out)
	}
	if !strings.Contains(out, "40 41 42") || !strings.Contains(out, "|@AB") {
		t.Errorf("Expected displaced '40 41 42' / '@AB', got:\n%s", out)
	}

	// 4. Test compact format: DMC000,2 ('A' -> 'C', 'B' -> 'D', 'C' -> 'E')
	outBuf.Reset()
	sh.ExecuteCommand("DMC000,2")
	out = outBuf.String()
	if !strings.Contains(out, "Displacement: +2") {
		t.Errorf("Expected Displacement: +2, got:\n%s", out)
	}
	if !strings.Contains(out, "43 44 45") || !strings.Contains(out, "|CDE") {
		t.Errorf("Expected displaced '43 44 45' / 'CDE', got:\n%s", out)
	}

	// 5. Test decimal displacement prefix: DM C000, d1
	outBuf.Reset()
	sh.ExecuteCommand("DM C000, d1")
	out = outBuf.String()
	if !strings.Contains(out, "Displacement: +1") {
		t.Errorf("Expected Displacement: +1, got:\n%s", out)
	}
	if !strings.Contains(out, "42 43 44") || !strings.Contains(out, "|BCD") {
		t.Errorf("Expected displaced '42 43 44' / 'BCD', got:\n%s", out)
	}
}

func TestCommandDMScrollingAndPaging(t *testing.T) {
	cfg := msx.DefaultConfig()
	machine, err := msx.NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	var inBuf bytes.Buffer
	var outBuf bytes.Buffer
	sh := New(machine, &inBuf, &outBuf)

	baseAddr := uint16(0xC010)
	cursorPos := 5
	inputNibble := ""

	// 1. Up arrow at top row (cursorPos=5) -> scrolls baseAddr down by 1 line (16 bytes)
	upSeq := []byte{0x1B, '[', 'A'}
	exit := handleDMKey(sh, upSeq, len(upSeq), &baseAddr, &cursorPos, &inputNibble, 0, 128)
	if exit {
		t.Errorf("Up arrow should not exit")
	}
	if baseAddr != 0xC000 || cursorPos != 5 {
		t.Errorf("Expected baseAddr=0xC000, cursorPos=5; got baseAddr=%04X, cursorPos=%d", baseAddr, cursorPos)
	}

	// 2. Down arrow within screen (cursorPos=5) -> moves cursorPos to 21
	downSeq := []byte{0x1B, '[', 'B'}
	handleDMKey(sh, downSeq, len(downSeq), &baseAddr, &cursorPos, &inputNibble, 0, 128)
	if baseAddr != 0xC000 || cursorPos != 21 {
		t.Errorf("Expected baseAddr=0xC000, cursorPos=21; got baseAddr=%04X, cursorPos=%d", baseAddr, cursorPos)
	}

	// 3. Down arrow at bottom row (cursorPos=117) -> scrolls baseAddr up by 1 line (16 bytes)
	cursorPos = 117
	handleDMKey(sh, downSeq, len(downSeq), &baseAddr, &cursorPos, &inputNibble, 0, 128)
	if baseAddr != 0xC010 || cursorPos != 117 {
		t.Errorf("Expected baseAddr=0xC010, cursorPos=117; got baseAddr=%04X, cursorPos=%d", baseAddr, cursorPos)
	}

	// 4. Left arrow at start (cursorPos=0) -> scrolls baseAddr down 1 line, cursorPos becomes 15
	cursorPos = 0
	leftSeq := []byte{0x1B, '[', 'D'}
	handleDMKey(sh, leftSeq, len(leftSeq), &baseAddr, &cursorPos, &inputNibble, 0, 128)
	if baseAddr != 0xC000 || cursorPos != 15 {
		t.Errorf("Expected baseAddr=0xC000, cursorPos=15; got baseAddr=%04X, cursorPos=%d", baseAddr, cursorPos)
	}

	// 5. Right arrow at end (cursorPos=127) -> scrolls baseAddr up 1 line, cursorPos becomes 112
	cursorPos = 127
	rightSeq := []byte{0x1B, '[', 'C'}
	handleDMKey(sh, rightSeq, len(rightSeq), &baseAddr, &cursorPos, &inputNibble, 0, 128)
	if baseAddr != 0xC010 || cursorPos != 112 {
		t.Errorf("Expected baseAddr=0xC010, cursorPos=112; got baseAddr=%04X, cursorPos=%d", baseAddr, cursorPos)
	}

	// 6. Page Down (\033[6~) -> advances 128 bytes
	pgDnSeq := []byte{0x1B, '[', '6', '~'}
	handleDMKey(sh, pgDnSeq, len(pgDnSeq), &baseAddr, &cursorPos, &inputNibble, 0, 128)
	if baseAddr != 0xC010+128 {
		t.Errorf("Expected baseAddr=%04X, got %04X", 0xC010+128, baseAddr)
	}

	// 7. Page Up (\033[5~) -> goes back 128 bytes
	pgUpSeq := []byte{0x1B, '[', '5', '~'}
	handleDMKey(sh, pgUpSeq, len(pgUpSeq), &baseAddr, &cursorPos, &inputNibble, 0, 128)
	if baseAddr != 0xC010 {
		t.Errorf("Expected baseAddr=0xC010, got %04X", baseAddr)
	}

	// 8. TAB key -> advances 128 bytes
	tabKey := []byte{0x09}
	handleDMKey(sh, tabKey, len(tabKey), &baseAddr, &cursorPos, &inputNibble, 0, 128)
	if baseAddr != 0xC010+128 {
		t.Errorf("Expected baseAddr=%04X after TAB, got %04X", 0xC010+128, baseAddr)
	}

	// 9. Bare ESC key -> terminates editing
	escKey := []byte{0x1B}
	exit = handleDMKey(sh, escKey, 1, &baseAddr, &cursorPos, &inputNibble, 0, 128)
	if !exit {
		t.Errorf("Expected ESC key to exit session")
	}
}

func TestCommandDMByteCount(t *testing.T) {
	// Everything without prefix is HEXADECIMAL by default in fMSXgo debugger standard:
	testCases := []struct {
		input    string
		expected int
	}{
		{"80", 128},     // hex 0x80 = 128
		{"100", 256},    // hex 0x100 = 256
		{"200", 512},    // hex 0x200 = 512
		{"300", 768},    // hex 0x300 = 768
		{"400", 1024},   // hex 0x400 = 1024
		{"512", 1280},   // hex 0x512 = 1298 -> rounded to 1280 (10 * 128)
		{"d128", 128},   // explicit decimal 128
		{"d256", 256},   // explicit decimal 256
		{"d512", 512},   // explicit decimal 512
		{"d768", 768},   // explicit decimal 768
		{"d1024", 1024}, // explicit decimal 1024
		{"80h", 128},    // explicit hex 0x80
		{"100h", 256},   // explicit hex 0x100
		{"200h", 512},   // explicit hex 0x200
		{"0", 128},      // minimum 128
	}

	for _, tc := range testCases {
		res, err := parseDMBytes(tc.input)
		if err != nil {
			t.Errorf("parseDMBytes(%q) returned unexpected error: %v", tc.input, err)
		}
		if res != tc.expected {
			t.Errorf("parseDMBytes(%q) = %d; expected %d", tc.input, res, tc.expected)
		}
	}

	// Test DM execution with byte counts
	cfg := msx.DefaultConfig()
	machine, err := msx.NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	var inBuf bytes.Buffer
	var outBuf bytes.Buffer
	sh := New(machine, &inBuf, &outBuf)

	// 1. dm c000,41,80 -> addr=C000h, desloc=0x41 (+65), bytes=0x80 (128 bytes)
	outBuf.Reset()
	sh.ExecuteCommand("dm c000,41,80")
	out := outBuf.String()
	if !strings.Contains(out, "Range: C000h..C07Fh (128 bytes)") || !strings.Contains(out, "Displacement: +65") {
		t.Errorf("Expected 'dm c000,41,80' (all hex), got:\n%s", out)
	}

	// 2. DM c000,,d512 -> addr=C000h, desloc=0, bytes=d512 (512 decimal)
	outBuf.Reset()
	sh.ExecuteCommand("DM c000,,d512")
	out = outBuf.String()
	if !strings.Contains(out, "Range: C000h..C1FFh (512 bytes)") || !strings.Contains(out, "Displacement: +0") {
		t.Errorf("Expected 'DM c000,,d512' (512 bytes), got:\n%s", out)
	}
	if !strings.Contains(out, "C1F0: ") {
		t.Errorf("Expected 512 bytes to include row C1F0, got:\n%s", out)
	}

	// 3. DM c000,,512 -> 512 without prefix is hex 0x512 = 1298 -> 1280 bytes
	outBuf.Reset()
	sh.ExecuteCommand("DM c000,,512")
	out = outBuf.String()
	if !strings.Contains(out, "1280 bytes") {
		t.Errorf("Expected 'DM c000,,512' to parse 512 as hex (1280 bytes), got:\n%s", out)
	}

	// 4. Compact format: DMC000,1,100 -> desloc=1, bytes=0x100 (256 bytes)
	outBuf.Reset()
	sh.ExecuteCommand("DMC000,1,100")
	out = outBuf.String()
	if !strings.Contains(out, "Range: C000h..C0FFh (256 bytes)") {
		t.Errorf("Expected 256 bytes range header for 'DMC000,1,100', got:\n%s", out)
	}

	// 5. DM C000, 1, d256 -> explicit decimal 256 bytes
	outBuf.Reset()
	sh.ExecuteCommand("dm C000, 1, d256")
	out = outBuf.String()
	if !strings.Contains(out, "Range: C000h..C0FFh (256 bytes)") {
		t.Errorf("Expected 256 bytes range header for 'dm C000, 1, d256', got:\n%s", out)
	}

	// 6. DM C000, 100 -> 2 parameters where 100 >= 128 is recognized as 256 bytes
	outBuf.Reset()
	sh.ExecuteCommand("DM C000, 100")
	out = outBuf.String()
	if !strings.Contains(out, "Range: C000h..C0FFh (256 bytes)") {
		t.Errorf("Expected 256 bytes range header for 'DM C000, 100', got:\n%s", out)
	}

	// 7. DM C000 100 -> space separated 2 parameters
	outBuf.Reset()
	sh.ExecuteCommand("DM C000 100")
	out = outBuf.String()
	if !strings.Contains(out, "Range: C000h..C0FFh (256 bytes)") {
		t.Errorf("Expected 256 bytes range header for 'DM C000 100', got:\n%s", out)
	}
}

func TestDMInteractiveSimultaneousDisplay(t *testing.T) {
	cfg := msx.DefaultConfig()
	machine, err := msx.NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}
	sh := New(machine, nil, nil)

	// 1. Interactive view for 256 bytes (100h) -> MUST render 16 simultaneous rows on screen
	view256 := formatDMView(sh, 0xC000, 256, 0, 0, "", true)
	if !strings.Contains(view256, "Range: C000h..C0FFh (256 bytes)") {
		t.Errorf("Expected 256-byte header, got:\n%s", view256)
	}
	if !strings.Contains(view256, "C000: ") || !strings.Contains(view256, "C0F0: ") {
		t.Errorf("Expected view to include first row C000 and 16th row C0F0, got:\n%s", view256)
	}
	// Verify exact count of row lines
	rowCount256 := 0
	for _, line := range strings.Split(view256, "\n") {
		if strings.Contains(line, ":  ") {
			rowCount256++
		}
	}
	if rowCount256 != 16 {
		t.Errorf("Expected 16 simultaneous rows for 256 bytes, got %d", rowCount256)
	}

	// 2. Interactive view for 512 bytes (200h) -> MUST render 32 simultaneous rows on screen
	view512 := formatDMView(sh, 0xC000, 512, 0, 0, "", true)
	if !strings.Contains(view512, "Range: C000h..C1FFh (512 bytes)") {
		t.Errorf("Expected 512-byte header, got:\n%s", view512)
	}
	if !strings.Contains(view512, "C1F0: ") {
		t.Errorf("Expected view to include 32nd row C1F0, got:\n%s", view512)
	}
	rowCount512 := 0
	for _, line := range strings.Split(view512, "\n") {
		if strings.Contains(line, ":  ") {
			rowCount512++
		}
	}
	if rowCount512 != 32 {
		t.Errorf("Expected 32 simultaneous rows for 512 bytes, got %d", rowCount512)
	}

	// 3. Test navigation within 256-byte window (totalBytes = 256)
	baseAddr := uint16(0xC000)
	cursorPos := 0
	inputNibble := ""
	downSeq := []byte{0x1B, '[', 'B'}

	// Move down through all 16 rows: row 0 -> row 15 (cursorPos 240)
	for i := 0; i < 15; i++ {
		handleDMKey(sh, downSeq, len(downSeq), &baseAddr, &cursorPos, &inputNibble, 0, 256)
	}
	if cursorPos != 240 || baseAddr != 0xC000 {
		t.Errorf("Expected cursorPos=240, baseAddr=0xC000; got cursorPos=%d, baseAddr=%04X", cursorPos, baseAddr)
	}

	// Down at row 15 scrolls baseAddr by 16
	handleDMKey(sh, downSeq, len(downSeq), &baseAddr, &cursorPos, &inputNibble, 0, 256)
	if baseAddr != 0xC010 || cursorPos != 240 {
		t.Errorf("Expected baseAddr=0xC010 after scroll at bottom row; got baseAddr=%04X, cursorPos=%d", baseAddr, cursorPos)
	}

	// PgDn advances by 256 bytes
	pgDnSeq := []byte{0x1B, '[', '6', '~'}
	handleDMKey(sh, pgDnSeq, len(pgDnSeq), &baseAddr, &cursorPos, &inputNibble, 0, 256)
	if baseAddr != 0xC010+256 {
		t.Errorf("Expected baseAddr=%04X after PgDn (256B step); got baseAddr=%04X", 0xC010+256, baseAddr)
	}
}


func TestShellWindowsCommand(t *testing.T) {
	cfg := msx.DefaultConfig()
	machine, err := msx.NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	var inBuf bytes.Buffer
	var outBuf bytes.Buffer

	sh := New(machine, &inBuf, &outBuf)
	if sh.SwitchToGUI {
		t.Errorf("Expected SwitchToGUI to be false initially")
	}

	exit := sh.ExecuteCommand("windows")
	if !exit {
		t.Errorf("Expected ExecuteCommand('windows') to return true (exit shell to switch)")
	}
	if !sh.SwitchToGUI {
		t.Errorf("Expected sh.SwitchToGUI to be true after 'windows'")
	}
	if !strings.Contains(outBuf.String(), "Switching to Graphical Window (GUI)...") {
		t.Errorf("Unexpected output: %s", outBuf.String())
	}

	// Also test aliases 'window' and 'gui'
	sh.SwitchToGUI = false
	exit = sh.ExecuteCommand("window")
	if !exit || !sh.SwitchToGUI {
		t.Errorf("Expected alias 'window' to set SwitchToGUI=true and return true")
	}

	sh.SwitchToGUI = false
	exit = sh.ExecuteCommand("gui")
	if !exit || !sh.SwitchToGUI {
		t.Errorf("Expected alias 'gui' to set SwitchToGUI=true and return true")
	}
}

func TestCommandLoadDSK(t *testing.T) {
	cfg := msx.DefaultConfig()
	machine, err := msx.NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	var inBuf bytes.Buffer
	var outBuf bytes.Buffer
	sh := New(machine, &inBuf, &outBuf)

	// Create temporary 720KB .dsk image
	tempDir, err := os.MkdirTemp("", "fmsxgo_dsk_test_*")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	diskData := make([]byte, 720*1024)
	copy(diskData, msx.BootBlock)
	diskData[0x15] = 0xF8 // 720KB media descriptor

	testDskPath := filepath.Join(tempDir, "test_game.dsk")
	if err := os.WriteFile(testDskPath, diskData, 0644); err != nil {
		t.Fatalf("Failed to write test disk: %v", err)
	}

	// 1. Direct load via command line
	outBuf.Reset()
	sh.ExecuteCommand("loaddsk " + testDskPath)
	out := outBuf.String()

	if !strings.Contains(out, "MSX Floppy Drive A: Mounted Successfully") {
		t.Errorf("Expected success mounting Drive A:, got:\n%s", out)
	}
	if !strings.Contains(out, "test_game.dsk") {
		t.Errorf("Expected file name in output, got:\n%s", out)
	}
	if !strings.Contains(out, "720 KB") || !strings.Contains(out, "1440 sectors") {
		t.Errorf("Expected 720 KB and 1440 sectors in output, got:\n%s", out)
	}
	if !machine.DiskPresent(0) {
		t.Errorf("Expected machine.DiskPresent(0) to be true")
	}
	if machine.FDD[0].Sectors != 1440 {
		t.Errorf("Expected 1440 sectors, got %d", machine.FDD[0].Sectors)
	}

	// Verify sector 0 is readable
	sec0, err := machine.DiskRead(0, 0)
	if err != nil || len(sec0) != 512 {
		t.Errorf("Failed to read sector 0: %v", err)
	}
	if sec0[0x15] != 0xF8 {
		t.Errorf("Expected media descriptor 0xF8, got %02X", sec0[0x15])
	}

	// 2. Direct load specifying Drive B:
	outBuf.Reset()
	sh.ExecuteCommand("loaddsk b " + testDskPath)
	out = outBuf.String()
	if !strings.Contains(out, "MSX Floppy Drive B: Mounted Successfully") {
		t.Errorf("Expected success mounting Drive B:, got:\n%s", out)
	}
	if !machine.DiskPresent(1) {
		t.Errorf("Expected machine.DiskPresent(1) to be true")
	}

	// 3. Attempting to load a non-existent file
	outBuf.Reset()
	sh.ExecuteCommand("loaddsk non_existent_image_12345.dsk")
	out = outBuf.String()
	if !strings.Contains(out, "not found") {
		t.Errorf("Expected 'not found' error message, got:\n%s", out)
	}

	// 4. Invoking loaddsk without arguments in non-terminal mode shows usage
	outBuf.Reset()
	sh.ExecuteCommand("loaddsk")
	out = outBuf.String()
	if !strings.Contains(out, "Usage: loaddsk") {
		t.Errorf("Expected non-terminal usage hint, got:\n%s", out)
	}
}

func TestCommandZAP(t *testing.T) {
	cfg := msx.DefaultConfig()
	machine, err := msx.NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	var inBuf bytes.Buffer
	var outBuf bytes.Buffer
	sh := New(machine, &inBuf, &outBuf)

	// 1. ZAP without loaded disk -> error
	outBuf.Reset()
	sh.ExecuteCommand("zap 0")
	if !strings.Contains(outBuf.String(), "No disk loaded") {
		t.Errorf("Expected error when no disk is loaded, got:\n%s", outBuf.String())
	}

	// 2. Mount 720KB disk
	tempDir, err := os.MkdirTemp("", "fmsxgo_zap_test_*")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	dsk720 := make([]byte, 720*1024)
	copy(dsk720, msx.BootBlock)
	dsk720[0x15] = 0xF8
	copy(dsk720[0x200:0x203], []byte{0xDE, 0xAD, 0xBE}) // Sector 1 marker

	dskPath := filepath.Join(tempDir, "disk720k.dsk")
	_ = os.WriteFile(dskPath, dsk720, 0644)

	sh.ExecuteCommand("loaddsk " + dskPath)

	// 3. Inspect Sector 0
	outBuf.Reset()
	sh.ExecuteCommand("zap 0")
	out := outBuf.String()

	if !strings.Contains(out, "=== MSX Disk Sector Editor (ZAP) ===") {
		t.Errorf("Expected ZAP header, got:\n%s", out)
	}
	if !strings.Contains(out, "Sector: 0000h / 0 (Track: 0, Side: 0, Sec: 1) | Total: 1440 sectors") {
		t.Errorf("Expected CHS Sector 0 info, got:\n%s", out)
	}
	if !strings.Contains(out, "Bytes: 512 (200h)") {
		t.Errorf("Expected 512 bytes for full sector, got:\n%s", out)
	}
	if !strings.Contains(out, "3.5\" 720KB (Dupla Face / Dupla Densidade)") {
		t.Errorf("Expected 720KB DS/DD description, got:\n%s", out)
	}
	if !strings.Contains(out, "01F0: ") {
		t.Errorf("Expected row 01F0 in 512-byte sector display, got:\n%s", out)
	}

	// 4. Inspect Sector 1
	outBuf.Reset()
	sh.ExecuteCommand("zap 1")
	out = outBuf.String()
	if !strings.Contains(out, "Sector: 0001h / 1 (Track: 0, Side: 0, Sec: 2)") {
		t.Errorf("Expected Sector 1 CHS info, got:\n%s", out)
	}
	if !strings.Contains(out, "DE AD BE") {
		t.Errorf("Expected marker bytes in Sector 1, got:\n%s", out)
	}

	// 5. Decimal sector number: ZAP d10
	outBuf.Reset()
	sh.ExecuteCommand("zap d10")
	out = outBuf.String()
	if !strings.Contains(out, "Sector: 000Ah / 10") {
		t.Errorf("Expected decimal sector 10 (000Ah), got:\n%s", out)
	}

	// 6. Sector 0 with custom byte size: ZAP 0,,100 (256 bytes)
	outBuf.Reset()
	sh.ExecuteCommand("zap 0,,100")
	out = outBuf.String()
	if !strings.Contains(out, "Bytes: 256 (100h)") {
		t.Errorf("Expected 256 bytes, got:\n%s", out)
	}
	if !strings.Contains(out, "00F0: ") || strings.Contains(out, "0100: ") {
		t.Errorf("Expected 256 bytes display (0000..00F0), got:\n%s", out)
	}

	// 7. Sector with displacement: ZAP 0, 1, 100
	outBuf.Reset()
	sh.ExecuteCommand("zap 0, 1, 100")
	out = outBuf.String()
	if !strings.Contains(out, "Displacement: +1") {
		t.Errorf("Expected Displacement: +1, got:\n%s", out)
	}

	// 8. Sector out of bounds for 720KB disk: 1440 / 5A0h
	outBuf.Reset()
	sh.ExecuteCommand("zap 5A0") // 5A0h = 1440
	out = outBuf.String()
	if !strings.Contains(out, "Invalid sector") || !strings.Contains(out, "Valid range is 0..1439") {
		t.Errorf("Expected out of bounds error for sector 1440, got:\n%s", out)
	}
}

func TestZAPGeometryAdaptation(t *testing.T) {
	cfg := msx.DefaultConfig()
	machine, err := msx.NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	var inBuf bytes.Buffer
	var outBuf bytes.Buffer
	sh := New(machine, &inBuf, &outBuf)

	tempDir, err := os.MkdirTemp("", "fmsxgo_zap_geom_*")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// 1. Test 360KB Disk (5 1/4" Dupla Face / Dupla Densidade) -> 720 sectors
	dsk360 := make([]byte, 360*1024)
	copy(dsk360, msx.BootBlock)
	dsk360[0x15] = 0xFD
	p360 := filepath.Join(tempDir, "disk360.dsk")
	_ = os.WriteFile(p360, dsk360, 0644)

	sh.ExecuteCommand("loaddsk " + p360)
	fdd := machine.FDD[0]
	if fdd.Sectors != 720 {
		t.Errorf("Expected 720 sectors for 360KB disk, got %d", fdd.Sectors)
	}
	if !strings.Contains(fdd.DiskType, "360KB") || !strings.Contains(fdd.DiskType, "5 1/4") {
		t.Errorf("Expected 5 1/4 360KB description, got %q", fdd.DiskType)
	}

	// Sector 719 is valid
	outBuf.Reset()
	sh.ExecuteCommand("zap 2CF") // 2CFh = 719
	if strings.Contains(outBuf.String(), "Invalid sector") {
		t.Errorf("Sector 719 should be valid for 360KB disk, got:\n%s", outBuf.String())
	}
	// Sector 720 is invalid
	outBuf.Reset()
	sh.ExecuteCommand("zap 2D0") // 2D0h = 720
	if !strings.Contains(outBuf.String(), "Invalid sector") || !strings.Contains(outBuf.String(), "0..719") {
		t.Errorf("Sector 720 should be invalid for 360KB disk, got:\n%s", outBuf.String())
	}

	// 2. Test 180KB Disk (5 1/4" Simples Face / Dupla Densidade) -> 360 sectors
	dsk180 := make([]byte, 180*1024)
	copy(dsk180, msx.BootBlock)
	dsk180[0x15] = 0xFC
	p180 := filepath.Join(tempDir, "disk180.dsk")
	_ = os.WriteFile(p180, dsk180, 0644)

	sh.ExecuteCommand("loaddsk " + p180)
	fdd = machine.FDD[0]
	if fdd.Sectors != 360 {
		t.Errorf("Expected 360 sectors for 180KB disk, got %d", fdd.Sectors)
	}
	if !strings.Contains(fdd.DiskType, "180KB") || !strings.Contains(fdd.DiskType, "Simples Face") {
		t.Errorf("Expected 180KB Simples Face description, got %q", fdd.DiskType)
	}

	// Sector 359 is valid
	outBuf.Reset()
	sh.ExecuteCommand("zap 167") // 167h = 359
	if strings.Contains(outBuf.String(), "Invalid sector") {
		t.Errorf("Sector 359 should be valid for 180KB disk, got:\n%s", outBuf.String())
	}
	// Sector 360 is invalid
	outBuf.Reset()
	sh.ExecuteCommand("zap 168") // 168h = 360
	if !strings.Contains(outBuf.String(), "Invalid sector") || !strings.Contains(outBuf.String(), "0..359") {
		t.Errorf("Sector 360 should be invalid for 180KB disk, got:\n%s", outBuf.String())
	}
}

func TestZAPInPlaceEditing(t *testing.T) {
	cfg := msx.DefaultConfig()
	machine, err := msx.NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	var inBuf bytes.Buffer
	var outBuf bytes.Buffer
	sh := New(machine, &inBuf, &outBuf)

	diskData := make([]byte, 720*1024)
	copy(diskData, msx.BootBlock)
	diskData[0x15] = 0xF8

	tempDir, _ := os.MkdirTemp("", "fmsxgo_zap_edit_*")
	defer os.RemoveAll(tempDir)
	p := filepath.Join(tempDir, "test.dsk")
	_ = os.WriteFile(p, diskData, 0644)

	sh.ExecuteCommand("loaddsk " + p)
	fdd := machine.FDD[0]

	sector := 2
	offsetInSector := 0
	cursorPos := 0
	inputNibble := ""

	// Enter byte 0x5A ('5', 'A') into Sector 2, byte 0
	key5 := []byte{'5'}
	handleZAPKey(sh, fdd, key5, 1, &sector, &offsetInSector, 512, &cursorPos, &inputNibble, 0)
	keyA := []byte{'A'}
	handleZAPKey(sh, fdd, keyA, 1, &sector, &offsetInSector, 512, &cursorPos, &inputNibble, 0)

	sec2Data, err := machine.DiskRead(0, 2)
	if err != nil {
		t.Fatalf("DiskRead error: %v", err)
	}
	if sec2Data[0] != 0x5A {
		t.Errorf("Expected modified byte 0x5A in sector 2, got %02X", sec2Data[0])
	}
	if !fdd.Modified {
		t.Errorf("Expected fdd.Modified to be true after editing")
	}

	// Press ESC key -> exits
	escKey := []byte{0x1B}
	exit := handleZAPKey(sh, fdd, escKey, 1, &sector, &offsetInSector, 512, &cursorPos, &inputNibble, 0)
	if !exit {
		t.Errorf("Expected ESC key to return true (exit)")
	}
}

func TestCommandDiskCreate(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "fmsxgo_diskcreate_test_*")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	cfg := msx.DefaultConfig()
	machine, err := msx.NewMachine(cfg)
	if err != nil {
		t.Fatalf("Failed to create machine: %v", err)
	}

	var inBuf bytes.Buffer
	var outBuf bytes.Buffer
	sh := New(machine, &inBuf, &outBuf)
	sh.LastPath = tempDir

	// 1. diskcreate with explicit name (720KB default)
	dsk1 := filepath.Join(tempDir, "disk1.dsk")
	outBuf.Reset()
	sh.ExecuteCommand("diskcreate " + dsk1)
	if !strings.Contains(outBuf.String(), "Created & Formatted Successfully") {
		t.Fatalf("Expected success message, got:\n%s", outBuf.String())
	}
	if !strings.Contains(outBuf.String(), "720KB") {
		t.Errorf("Expected 720KB in output, got:\n%s", outBuf.String())
	}

	// Verify auto-mounted into Drive A:
	fdd := machine.FDD[0]
	if fdd == nil || len(fdd.Data) != 1440*512 {
		t.Fatalf("Expected Drive A: to contain 720KB disk, got len %d", len(fdd.Data))
	}
	if fdd.Data[0x15] != 0xF9 {
		t.Errorf("Expected Media ID 0xF9, got %02X", fdd.Data[0x15])
	}

	// 2. diskcreate with custom size (360KB)
	dsk2 := filepath.Join(tempDir, "disk2.dsk")
	outBuf.Reset()
	sh.ExecuteCommand("diskcreate " + dsk2 + " 360")
	if !strings.Contains(outBuf.String(), "360KB") {
		t.Errorf("Expected 360KB in output, got:\n%s", outBuf.String())
	}
	fdd = machine.FDD[0]
	if fdd == nil || len(fdd.Data) != 720*512 {
		t.Fatalf("Expected Drive A: to contain 360KB disk, got len %d", len(fdd.Data))
	}

	// 3. diskcreate without arguments in non-interactive mode
	origWd, _ := os.Getwd()
	_ = os.Chdir(tempDir)
	defer func() { _ = os.Chdir(origWd) }()

	outBuf.Reset()
	sh.ExecuteCommand("diskcreate")
	if !strings.Contains(outBuf.String(), "Non-interactive shell") || !strings.Contains(outBuf.String(), "newdisk.dsk") {
		t.Errorf("Expected non-interactive fallback to newdisk.dsk, got:\n%s", outBuf.String())
	}
	if _, err := os.Stat("newdisk.dsk"); err != nil {
		t.Errorf("Expected newdisk.dsk to be created in working directory")
	}

	// 4. Test zap on the newly created disk
	outBuf.Reset()
	sh.ExecuteCommand("zap 0")
	if !strings.Contains(outBuf.String(), "Sector: 0000h") || !strings.Contains(outBuf.String(), "VFB-1989") {
		t.Errorf("Expected ZAP sector 0 to show boot sector, got:\n%s", outBuf.String())
	}
}



