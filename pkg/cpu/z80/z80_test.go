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
		"LD A, 10",
		"LD B, 20",
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

