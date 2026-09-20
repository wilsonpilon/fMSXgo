package z80

// Bus defines the interface between the Z80 CPU and the system memory / IO bus.
type Bus interface {
	Read(addr uint16) uint8
	Write(addr uint16, val uint8)
	In(port uint16) uint8
	Out(port uint16, val uint8)
}

// Z80 encapsulates the state of the Zilog Z80 microprocessor.
type Z80 struct {
	// Main registers
	A, F uint8
	B, C uint8
	D, E uint8
	H, L uint8

	// Alternate (shadow) registers
	A1, F1 uint8
	B1, C1 uint8
	D1, E1 uint8
	H1, L1 uint8

	// Index and pointer registers
	IX uint16
	IY uint16
	SP uint16
	PC uint16

	// Interrupt and refresh registers
	I    uint8
	R    uint8
	IFF1 bool
	IFF2 bool
	IM   uint8 // Interrupt Mode: 0, 1, or 2

	// Execution state
	Halted bool
	EIWait bool // Delay interrupt by 1 instruction following EI

	// Cycles elapsed in current step / total
	Cycles int64

	// Traps / Patches
	Trap      uint16
	Trace     bool
	PatchHook func(z *Z80, bus Bus)

	// Execution History Ring Buffer (10,000 steps)
	HistoryRing    [HistoryBufferSize]TraceEntry
	HistoryHead    int
	HistoryCount   int
	HistoryEnabled bool
}

// HistoryBufferSize defines the maximum number of instructions stored in the execution trace ring.
const HistoryBufferSize = 10000

// TraceEntry represents a snapshot of CPU state at the start of an instruction's execution.
type TraceEntry struct {
	PC     uint16
	Opcode [4]byte
	OpLen  uint8
	AF     uint16
	BC     uint16
	DE     uint16
	HL     uint16
	IX     uint16
	IY     uint16
	SP     uint16
	Cycles int64
}

// New creates and initializes a new Z80 CPU instance.
func New() *Z80 {
	z := &Z80{}
	z.Reset()
	return z
}

// Reset initializes the CPU registers to their power-on defaults.
func (z *Z80) Reset() {
	z.A = 0x00
	z.F = 0x00
	z.B = 0x00
	z.C = 0x00
	z.D = 0x00
	z.E = 0x00
	z.H = 0x00
	z.L = 0x00

	z.A1 = 0x00
	z.F1 = 0x00
	z.B1 = 0x00
	z.C1 = 0x00
	z.D1 = 0x00
	z.E1 = 0x00
	z.H1 = 0x00
	z.L1 = 0x00

	z.IX = 0x0000
	z.IY = 0x0000
	z.SP = 0xF000 // typical default stack pointer in fMSX
	z.PC = 0x0000

	z.I = 0x00
	z.R = 0x00
	z.IFF1 = false
	z.IFF2 = false
	z.IM = 0
	z.Halted = false
	z.EIWait = false
	z.Trap = 0xFFFF
	z.Trace = false
	z.HistoryHead = 0
	z.HistoryCount = 0
	z.HistoryEnabled = true
}

// RecordHistory writes an instruction execution snapshot into the circular ring buffer.
func (z *Z80) RecordHistory(entry TraceEntry) {
	z.HistoryRing[z.HistoryHead] = entry
	z.HistoryHead = (z.HistoryHead + 1) % HistoryBufferSize
	if z.HistoryCount < HistoryBufferSize {
		z.HistoryCount++
	}
}

// GetHistory returns up to `count` most recent execution trace entries,
// ordered from oldest to newest (the last element is the most recent instruction).
func (z *Z80) GetHistory(count int) []TraceEntry {
	if count <= 0 || z.HistoryCount == 0 {
		return nil
	}
	if count > z.HistoryCount {
		count = z.HistoryCount
	}

	result := make([]TraceEntry, count)
	start := (z.HistoryHead - count + HistoryBufferSize) % HistoryBufferSize
	for i := 0; i < count; i++ {
		result[i] = z.HistoryRing[(start+i)%HistoryBufferSize]
	}
	return result
}

// ClearHistory resets the execution history buffer.
func (z *Z80) ClearHistory() {
	z.HistoryHead = 0
	z.HistoryCount = 0
}

// SetHistoryEnabled toggles execution history recording.
func (z *Z80) SetHistoryEnabled(enable bool) {
	z.HistoryEnabled = enable
}

// 16-bit register accessors
func (z *Z80) AF() uint16        { return (uint16(z.A) << 8) | uint16(z.F) }
func (z *Z80) SetAF(val uint16)  { z.A = uint8(val >> 8); z.F = uint8(val) }
func (z *Z80) BC() uint16        { return (uint16(z.B) << 8) | uint16(z.C) }
func (z *Z80) SetBC(val uint16)  { z.B = uint8(val >> 8); z.C = uint8(val) }
func (z *Z80) DE() uint16        { return (uint16(z.D) << 8) | uint16(z.E) }
func (z *Z80) SetDE(val uint16)  { z.D = uint8(val >> 8); z.E = uint8(val) }
func (z *Z80) HL() uint16        { return (uint16(z.H) << 8) | uint16(z.L) }
func (z *Z80) SetHL(val uint16)  { z.H = uint8(val >> 8); z.L = uint8(val) }

func (z *Z80) AF1() uint16       { return (uint16(z.A1) << 8) | uint16(z.F1) }
func (z *Z80) SetAF1(val uint16) { z.A1 = uint8(val >> 8); z.F1 = uint8(val) }
func (z *Z80) BC1() uint16       { return (uint16(z.B1) << 8) | uint16(z.C1) }
func (z *Z80) SetBC1(val uint16) { z.B1 = uint8(val >> 8); z.C1 = uint8(val) }
func (z *Z80) DE1() uint16       { return (uint16(z.D1) << 8) | uint16(z.E1) }
func (z *Z80) SetDE1(val uint16) { z.D1 = uint8(val >> 8); z.E1 = uint8(val) }
func (z *Z80) HL1() uint16       { return (uint16(z.H1) << 8) | uint16(z.L1) }
func (z *Z80) SetHL1(val uint16) { z.H1 = uint8(val >> 8); z.L1 = uint8(val) }

// PushWord pushes a 16-bit value onto the stack.
func (z *Z80) PushWord(bus Bus, val uint16) {
	z.SP--
	bus.Write(z.SP, uint8(val>>8))
	z.SP--
	bus.Write(z.SP, uint8(val))
}

// PopWord pops a 16-bit value from the stack.
func (z *Z80) PopWord(bus Bus) uint16 {
	low := bus.Read(z.SP)
	z.SP++
	high := bus.Read(z.SP)
	z.SP++
	return (uint16(high) << 8) | uint16(low)
}

// Interrupt triggers a maskable interrupt (INT).
// vector is typically 0x38 (RST 38h) for IM 1.
func (z *Z80) Interrupt(bus Bus, vector uint16) bool {
	if !z.IFF1 || z.EIWait {
		return false
	}
	z.Halted = false
	z.IFF1 = false
	z.IFF2 = false

	switch z.IM {
	case 0:
		// Mode 0: execute opcode placed on data bus (default RST 38h)
		z.PushWord(bus, z.PC)
		z.PC = vector
	case 1:
		// Mode 1: always restarts to 0x0038
		z.PushWord(bus, z.PC)
		z.PC = 0x0038
	case 2:
		// Mode 2: vectored via (I << 8) | vector
		addr := (uint16(z.I) << 8) | (vector & 0xFF)
		z.PushWord(bus, z.PC)
		low := bus.Read(addr)
		high := bus.Read(addr + 1)
		z.PC = (uint16(high) << 8) | uint16(low)
	}
	return true
}

// NMI triggers a non-maskable interrupt.
func (z *Z80) NMI(bus Bus) {
	z.Halted = false
	z.IFF1 = false
	z.PushWord(bus, z.PC)
	z.PC = 0x0066
}
