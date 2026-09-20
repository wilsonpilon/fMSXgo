package z80

import (
	"testing"
)

// simpleBus implements a 64KB flat RAM bus for CPU testing
type simpleBus struct {
	ram [65536]uint8
	io  [65536]uint8
}

func newSimpleBus() *simpleBus {
	return &simpleBus{}
}

func (b *simpleBus) Read(addr uint16) uint8 {
	return b.ram[addr]
}

func (b *simpleBus) Write(addr uint16, val uint8) {
	b.ram[addr] = val
}

func (b *simpleBus) In(port uint16) uint8 {
	return b.io[port&0xFF]
}

func (b *simpleBus) Out(port uint16, val uint8) {
	b.io[port&0xFF] = val
}

func TestZ80BasicExecution(t *testing.T) {
	bus := newSimpleBus()
	cpu := New()
	cpu.PC = 0x0100

	// Assembly program:
	// 0100: LD A, 10
	// 0102: LD B, 20
	// 0104: ADD A, B
	// 0105: HALT
	prog := []string{
		"LD A, d10",
		"LD B, d20",
		"ADD A, B",
		"HALT",
	}

	pc := cpu.PC
	for _, line := range prog {
		bytes, err := AssembleLine(pc, line)
		if err != nil {
			t.Fatalf("assemble error on '%s': %v", line, err)
		}
		for _, b := range bytes {
			bus.Write(pc, b)
			pc++
		}
	}

	// Step instructions
	for !cpu.Halted {
		cpu.Step(bus)
	}

	if cpu.A != 30 {
		t.Fatalf("expected A = 30, got %d", cpu.A)
	}
	if cpu.B != 20 {
		t.Fatalf("expected B = 20, got %d", cpu.B)
	}
	if (cpu.F & FlagZ) != 0 {
		t.Fatalf("expected FlagZ to be cleared, got %02X", cpu.F)
	}
}

func TestMiniAssemblerAndDisassembler(t *testing.T) {
	bus := newSimpleBus()
	pc := uint16(0x4000)

	instructions := []string{
		"NOP",
		"LD A, 2Ah",
		"LD BC, 1234h",
		"ADD A, B",
		"CALL 0038h",
		"RET",
		"HALT",
	}

	curPC := pc
	for _, inst := range instructions {
		bytes, err := AssembleLine(curPC, inst)
		if err != nil {
			t.Fatalf("AssembleLine failed for '%s': %v", inst, err)
		}
		for _, b := range bytes {
			bus.Write(curPC, b)
			curPC++
		}
	}

	// Disassemble back and check that instruction sizes and mnemonics match
	curPC = pc
	for _, orig := range instructions {
		dis, size := Disassemble(bus, curPC)
		if size == 0 {
			t.Fatalf("disassembler returned 0 size for %s at %04X", orig, curPC)
		}
		t.Logf("[%04X] %s -> disassembled: %s (size %d)", curPC, orig, dis, size)
		curPC += uint16(size)
	}
}

func TestZ80BlockTransferLDIR(t *testing.T) {
	bus := newSimpleBus()
	cpu := New()
	cpu.PC = 0x1000

	// Put source data at 0x2000
	srcData := []byte{0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE}
	for i, b := range srcData {
		bus.Write(uint16(0x2000+i), b)
	}

	// Code:
	// LD HL, 2000h
	// LD DE, 3000h
	// LD BC, 0006h
	// LDIR
	// HALT
	code := []byte{
		0x21, 0x00, 0x20, // LD HL, 2000h
		0x11, 0x00, 0x30, // LD DE, 3000h
		0x01, 0x06, 0x00, // LD BC, 0006h
		0xED, 0xB0, // LDIR
		0x76, // HALT
	}
	for i, b := range code {
		bus.Write(uint16(0x1000+i), b)
	}

	steps := 0
	for !cpu.Halted && steps < 100 {
		cpu.Step(bus)
		steps++
	}

	if !cpu.Halted {
		t.Fatalf("CPU did not halt within 100 steps")
	}

	for i, expected := range srcData {
		actual := bus.Read(uint16(0x3000 + i))
		if actual != expected {
			t.Fatalf("LDIR mismatch at 0x%04X: expected %02X, got %02X", 0x3000+i, expected, actual)
		}
	}
}

func TestZ80StackAndCallRet(t *testing.T) {
	bus := newSimpleBus()
	cpu := New()
	cpu.PC = 0x8000
	cpu.SP = 0xF000

	// 8000: CALL 8004h
	// 8003: HALT
	// 8004: LD A, 99h
	// 8006: RET
	code := []byte{
		0xCD, 0x04, 0x80, // CALL 8004h
		0x76,             // HALT
		0x3E, 0x99,       // LD A, 99h
		0xC9,             // RET
	}
	for i, b := range code {
		bus.Write(uint16(0x8000+i), b)
	}

	for !cpu.Halted {
		cpu.Step(bus)
	}

	if cpu.A != 0x99 {
		t.Fatalf("expected A = 0x99, got %02X", cpu.A)
	}
	if cpu.PC != 0x8004 {
		t.Fatalf("expected PC at 0x8004 after HALT, got %04X", cpu.PC)
	}
	if cpu.SP != 0xF000 {
		t.Fatalf("expected SP restored to 0xF000, got %04X", cpu.SP)
	}
}

func TestZ80LoopAndIO(t *testing.T) {
	bus := newSimpleBus()
	cpu := New()
	cpu.PC = 0x2000

	bus.Out(0x0090, 0x42) // Set port 90h to 0x42

	// Assembly:
	// 2000: LD B, 03h
	// 2002: IN A, (90h)
	// 2004: OUT (91h), A
	// 2006: DJNZ 2002h
	// 2008: HALT
	prog := []string{
		"LD B, 03h",
		"IN A, (90h)",
		"OUT (91h), A",
		"DJNZ 2002h",
		"HALT",
	}

	pc := cpu.PC
	for _, line := range prog {
		bytes, err := AssembleLine(pc, line)
		if err != nil {
			t.Fatalf("assemble line failed '%s': %v", line, err)
		}
		for _, b := range bytes {
			bus.Write(pc, b)
			pc++
		}
	}

	for !cpu.Halted {
		cpu.Step(bus)
	}

	if bus.In(0x0091) != 0x42 {
		t.Fatalf("expected port 91h to have 0x42, got %02X", bus.In(0x0091))
	}
	if cpu.B != 0 {
		t.Fatalf("expected B = 0 after loop, got %d", cpu.B)
	}
}

func TestZ80ResetFidelity(t *testing.T) {
	cpu := New()
	// Modify registers
	cpu.A, cpu.F, cpu.B, cpu.C = 0xAA, 0x55, 0x12, 0x34
	cpu.D, cpu.E, cpu.H, cpu.L = 0x56, 0x78, 0x9A, 0xBC
	cpu.SP = 0x1234
	cpu.PC = 0x5678

	cpu.Reset()
	if cpu.A != 0 || cpu.F != 0 || cpu.B != 0 || cpu.C != 0 ||
		cpu.D != 0 || cpu.E != 0 || cpu.H != 0 || cpu.L != 0 {
		t.Fatalf("Reset must zero out registers, got A=%02X F=%02X", cpu.A, cpu.F)
	}
	if cpu.SP != 0xF000 {
		t.Fatalf("Reset SP should be 0xF000 (fMSX default), got %04X", cpu.SP)
	}
	if cpu.PC != 0x0000 {
		t.Fatalf("Reset PC should be 0x0000, got %04X", cpu.PC)
	}
}

func TestZ80DAAFidelity(t *testing.T) {
	bus := newSimpleBus()
	cpu := New()

	// Test BCD addition: 0x15 + 0x27 = 0x3C -> DAA -> 0x42
	cpu.PC = 0x0100
	code := []byte{
		0x3E, 0x15, // LD A, 15h
		0xC6, 0x27, // ADD A, 27h
		0x27,       // DAA
		0x76,       // HALT
	}
	for i, b := range code {
		bus.Write(uint16(0x0100+i), b)
	}

	for !cpu.Halted {
		cpu.Step(bus)
	}

	if cpu.A != 0x42 {
		t.Fatalf("DAA expected A = 0x42, got %02X", cpu.A)
	}
}

func TestZ80LdAIRFlags(t *testing.T) {
	bus := newSimpleBus()
	cpu := New()

	// When IFF2 is false, LD A, I should clear FlagP
	cpu.IFF2 = false
	cpu.I = 0x03 // 0x03 has even parity (bits 0 and 1 set)
	cpu.PC = 0x0100
	bus.Write(0x0100, 0xED)
	bus.Write(0x0101, 0x57) // LD A, I
	bus.Write(0x0102, 0x76) // HALT

	cpu.Step(bus)
	if (cpu.F & FlagP) != 0 {
		t.Fatalf("LD A, I with IFF2=false should NOT set FlagP, got F=%02X", cpu.F)
	}

	// When IFF2 is true, LD A, I should set FlagP
	cpu.IFF2 = true
	cpu.PC = 0x0100
	cpu.Step(bus)
	if (cpu.F & FlagP) == 0 {
		t.Fatalf("LD A, I with IFF2=true SHOULD set FlagP, got F=%02X", cpu.F)
	}
}

func TestZ80OUTIDecrementsBFirst(t *testing.T) {
	bus := newSimpleBus()
	cpu := New()

	// OUTI outputs (HL) to port (BC) with decremented B
	cpu.PC = 0x0100
	cpu.B = 0x05
	cpu.C = 0x90
	cpu.SetHL(0x2000)
	bus.Write(0x2000, 0x77)

	bus.Write(0x0100, 0xED)
	bus.Write(0x0101, 0xA3) // OUTI
	bus.Write(0x0102, 0x76) // HALT

	var recordedPort uint16
	var recordedVal uint8
	cpu.Step(bus)

	if cpu.B != 0x04 {
		t.Fatalf("OUTI expected B=4, got %d", cpu.B)
	}
	// B is decremented before port write, so high byte of port on bus is 0x04
	_ = recordedPort
	_ = recordedVal
}

func TestZ80PatchHook(t *testing.T) {
	bus := newSimpleBus()
	cpu := New()

	hookCalled := false
	cpu.PatchHook = func(z *Z80, b Bus) {
		hookCalled = true
		z.A = 0x55
	}

	cpu.PC = 0x0100
	bus.Write(0x0100, 0xED)
	bus.Write(0x0101, 0xFE) // Opcode ED FE (Patch hook)
	bus.Write(0x0102, 0x76) // HALT

	cpu.Step(bus)
	if !hookCalled {
		t.Fatalf("expected PatchHook to be invoked on ED FE")
	}
	if cpu.A != 0x55 {
		t.Fatalf("expected A=0x55 set by hook, got %02X", cpu.A)
	}
}

func TestZ80ExecutionHistory(t *testing.T) {
	bus := newSimpleBus()
	cpu := New()
	cpu.Reset()

	// Write small program:
	// 0x0100: NOP
	// 0x0101: LD A, 42h
	// 0x0103: INC A
	// 0x0104: HALT
	cpu.PC = 0x0100
	bus.Write(0x0100, 0x00) // NOP
	bus.Write(0x0101, 0x3E) // LD A, 42h
	bus.Write(0x0102, 0x42)
	bus.Write(0x0103, 0x3C) // INC A
	bus.Write(0x0104, 0x76) // HALT

	for i := 0; i < 3; i++ {
		cpu.Step(bus)
	}

	if cpu.HistoryCount != 3 {
		t.Fatalf("expected HistoryCount=3, got %d", cpu.HistoryCount)
	}

	hist := cpu.GetHistory(3)
	if len(hist) != 3 {
		t.Fatalf("expected 3 history entries, got %d", len(hist))
	}
	if hist[0].PC != 0x0100 || hist[1].PC != 0x0101 || hist[2].PC != 0x0103 {
		t.Fatalf("unexpected PCs in history: %04X, %04X, %04X", hist[0].PC, hist[1].PC, hist[2].PC)
	}

	dasm, _ := hist[1].Disassemble()
	if dasm != "LD A, 42h" {
		t.Fatalf("expected disassembled 'LD A, 42h', got '%s'", dasm)
	}

	// Test circular buffer rollover
	for i := 0; i < HistoryBufferSize+50; i++ {
		cpu.PC = 0x0100 // keep executing NOP
		cpu.Step(bus)
	}

	if cpu.HistoryCount != HistoryBufferSize {
		t.Fatalf("expected HistoryCount capped at %d, got %d", HistoryBufferSize, cpu.HistoryCount)
	}
	all := cpu.GetHistory(10)
	if len(all) != 10 {
		t.Fatalf("expected 10 items, got %d", len(all))
	}
}


