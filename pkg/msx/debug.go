package msx

import (
	"fmt"
	"strings"
	"sync"

	"fmsxgo/pkg/cpu/z80"
)

// BreakpointType identifies the trigger source of a breakpoint or watchpoint.
type BreakpointType int

const (
	BPTypePC BreakpointType = iota
	BPTypeMemRead
	BPTypeMemWrite
	BPTypeIOIn
	BPTypeIOOut
	BPTypeScanline
)

func (t BreakpointType) String() string {
	switch t {
	case BPTypePC:
		return "PC"
	case BPTypeMemRead:
		return "MEM_READ"
	case BPTypeMemWrite:
		return "MEM_WRITE"
	case BPTypeIOIn:
		return "IO_IN"
	case BPTypeIOOut:
		return "IO_OUT"
	case BPTypeScanline:
		return "SCANLINE"
	default:
		return "UNKNOWN"
	}
}

// Breakpoint represents an active monitoring condition.
type Breakpoint struct {
	ID        int
	Type      BreakpointType
	Addr      uint16
	EndAddr   uint16 // For address range watchpoints (EndAddr >= Addr)
	Condition string // Optional expression, e.g., "A == 0x42" or "HL > 8000h"
	HitCount  int
	Enabled   bool
}

func (bp *Breakpoint) Description() string {
	switch bp.Type {
	case BPTypePC:
		if bp.Condition != "" {
			return fmt.Sprintf("PC at %04Xh if %s", bp.Addr, bp.Condition)
		}
		return fmt.Sprintf("PC at %04Xh", bp.Addr)
	case BPTypeMemRead:
		if bp.EndAddr > bp.Addr {
			return fmt.Sprintf("Read [%04Xh..%04Xh]", bp.Addr, bp.EndAddr)
		}
		return fmt.Sprintf("Read [%04Xh]", bp.Addr)
	case BPTypeMemWrite:
		if bp.EndAddr > bp.Addr {
			return fmt.Sprintf("Write [%04Xh..%04Xh]", bp.Addr, bp.EndAddr)
		}
		return fmt.Sprintf("Write [%04Xh]", bp.Addr)
	case BPTypeIOIn:
		return fmt.Sprintf("Port IN %02Xh", bp.Addr)
	case BPTypeIOOut:
		return fmt.Sprintf("Port OUT %02Xh", bp.Addr)
	case BPTypeScanline:
		return fmt.Sprintf("Scanline %d", bp.Addr)
	default:
		return "Unknown breakpoint"
	}
}

// Debugger manages execution breakpoints, memory/IO watchpoints, and condition checks.
type Debugger struct {
	mu          sync.RWMutex
	Breakpoints map[int]*Breakpoint
	nextID      int
	HasPC       bool // True if any PC breakpoint is active
	HasWatch    bool // True if any memory or I/O watchpoint is active
	HasScanline bool // True if any scanline breakpoint is active
	Symbols     *SymbolTable
	LastHit     *Breakpoint
}

// NewDebugger creates a new Debugger instance.
func NewDebugger(symbols *SymbolTable) *Debugger {
	if symbols == nil {
		symbols = NewSymbolTable()
	}
	return &Debugger{
		Breakpoints: make(map[int]*Breakpoint),
		nextID:      1,
		Symbols:     symbols,
	}
}

func (d *Debugger) updateFlagsLocked() {
	d.HasPC = false
	d.HasWatch = false
	d.HasScanline = false
	for _, bp := range d.Breakpoints {
		if !bp.Enabled {
			continue
		}
		switch bp.Type {
		case BPTypePC:
			d.HasPC = true
		case BPTypeMemRead, BPTypeMemWrite, BPTypeIOIn, BPTypeIOOut:
			d.HasWatch = true
		case BPTypeScanline:
			d.HasScanline = true
		}
	}
}

// AddPC registers a PC breakpoint.
func (d *Debugger) AddPC(addr uint16, condition string) int {
	d.mu.Lock()
	defer d.mu.Unlock()

	id := d.nextID
	d.nextID++
	d.Breakpoints[id] = &Breakpoint{
		ID:        id,
		Type:      BPTypePC,
		Addr:      addr,
		EndAddr:   addr,
		Condition: strings.TrimSpace(condition),
		Enabled:   true,
	}
	d.updateFlagsLocked()
	return id
}

// AddMemWatch registers a memory read or write watchpoint.
func (d *Debugger) AddMemWatch(addr, endAddr uint16, isWrite bool, condition string) int {
	d.mu.Lock()
	defer d.mu.Unlock()

	if endAddr < addr {
		endAddr = addr
	}

	t := BPTypeMemRead
	if isWrite {
		t = BPTypeMemWrite
	}

	id := d.nextID
	d.nextID++
	d.Breakpoints[id] = &Breakpoint{
		ID:        id,
		Type:      t,
		Addr:      addr,
		EndAddr:   endAddr,
		Condition: strings.TrimSpace(condition),
		Enabled:   true,
	}
	d.updateFlagsLocked()
	return id
}

// AddIOWatch registers an I/O port read or write watchpoint.
func (d *Debugger) AddIOWatch(port uint16, isOut bool, condition string) int {
	d.mu.Lock()
	defer d.mu.Unlock()

	t := BPTypeIOIn
	if isOut {
		t = BPTypeIOOut
	}

	id := d.nextID
	d.nextID++
	d.Breakpoints[id] = &Breakpoint{
		ID:        id,
		Type:      t,
		Addr:      port,
		EndAddr:   port,
		Condition: strings.TrimSpace(condition),
		Enabled:   true,
	}
	d.updateFlagsLocked()
	return id
}

// AddScanline registers a scanline breakpoint.
func (d *Debugger) AddScanline(line int) int {
	d.mu.Lock()
	defer d.mu.Unlock()

	id := d.nextID
	d.nextID++
	d.Breakpoints[id] = &Breakpoint{
		ID:      id,
		Type:    BPTypeScanline,
		Addr:    uint16(line),
		EndAddr: uint16(line),
		Enabled: true,
	}
	d.updateFlagsLocked()
	return id
}

// Remove deletes a breakpoint by ID.
func (d *Debugger) Remove(id int) bool {
	d.mu.Lock()
	defer d.mu.Unlock()

	if _, exists := d.Breakpoints[id]; exists {
		delete(d.Breakpoints, id)
		d.updateFlagsLocked()
		return true
	}
	return false
}

// Clear removes all breakpoints and watchpoints.
func (d *Debugger) Clear() {
	d.mu.Lock()
	defer d.mu.Unlock()

	d.Breakpoints = make(map[int]*Breakpoint)
	d.HasPC = false
	d.HasWatch = false
	d.HasScanline = false
	d.LastHit = nil
}

// List returns a list of all defined breakpoints.
func (d *Debugger) List() []*Breakpoint {
	d.mu.RLock()
	defer d.mu.RUnlock()

	res := make([]*Breakpoint, 0, len(d.Breakpoints))
	for _, bp := range d.Breakpoints {
		res = append(res, bp)
	}
	return res
}

// CheckPC tests if the current CPU PC hits an active breakpoint.
func (d *Debugger) CheckPC(cpu *z80.Z80) (*Breakpoint, bool) {
	if !d.HasPC {
		return nil, false
	}
	d.mu.RLock()
	defer d.mu.RUnlock()

	for _, bp := range d.Breakpoints {
		if !bp.Enabled || bp.Type != BPTypePC {
			continue
		}
		if cpu.PC == bp.Addr {
			if bp.Condition == "" || d.evalCondition(cpu, bp.Condition) {
				bp.HitCount++
				d.LastHit = bp
				return bp, true
			}
		}
	}
	return nil, false
}

// CheckMemRead tests memory read watchpoints.
func (d *Debugger) CheckMemRead(cpu *z80.Z80, addr uint16) (*Breakpoint, bool) {
	if !d.HasWatch {
		return nil, false
	}
	d.mu.RLock()
	defer d.mu.RUnlock()

	for _, bp := range d.Breakpoints {
		if !bp.Enabled || bp.Type != BPTypeMemRead {
			continue
		}
		if addr >= bp.Addr && addr <= bp.EndAddr {
			if bp.Condition == "" || d.evalCondition(cpu, bp.Condition) {
				bp.HitCount++
				d.LastHit = bp
				return bp, true
			}
		}
	}
	return nil, false
}

// CheckMemWrite tests memory write watchpoints.
func (d *Debugger) CheckMemWrite(cpu *z80.Z80, addr uint16, val uint8) (*Breakpoint, bool) {
	if !d.HasWatch {
		return nil, false
	}
	d.mu.RLock()
	defer d.mu.RUnlock()

	for _, bp := range d.Breakpoints {
		if !bp.Enabled || bp.Type != BPTypeMemWrite {
			continue
		}
		if addr >= bp.Addr && addr <= bp.EndAddr {
			if bp.Condition == "" || d.evalCondition(cpu, bp.Condition) {
				bp.HitCount++
				d.LastHit = bp
				return bp, true
			}
		}
	}
	return nil, false
}

// CheckIO tests I/O port watchpoints.
func (d *Debugger) CheckIO(cpu *z80.Z80, port uint16, isOut bool) (*Breakpoint, bool) {
	if !d.HasWatch {
		return nil, false
	}
	d.mu.RLock()
	defer d.mu.RUnlock()

	targetType := BPTypeIOIn
	if isOut {
		targetType = BPTypeIOOut
	}

	for _, bp := range d.Breakpoints {
		if !bp.Enabled || bp.Type != targetType {
			continue
		}
		if (port & 0xFF) == (bp.Addr & 0xFF) {
			if bp.Condition == "" || d.evalCondition(cpu, bp.Condition) {
				bp.HitCount++
				d.LastHit = bp
				return bp, true
			}
		}
	}
	return nil, false
}

// CheckScanline tests scanline coincidence breakpoints.
func (d *Debugger) CheckScanline(line int) (*Breakpoint, bool) {
	if !d.HasScanline {
		return nil, false
	}
	d.mu.RLock()
	defer d.mu.RUnlock()

	for _, bp := range d.Breakpoints {
		if !bp.Enabled || bp.Type != BPTypeScanline {
			continue
		}
		if int(bp.Addr) == line {
			bp.HitCount++
			d.LastHit = bp
			return bp, true
		}
	}
	return nil, false
}

// evalCondition evaluates simple conditional expressions like "A == 0x42" or "HL > 8000h".
func (d *Debugger) evalCondition(cpu *z80.Z80, expr string) bool {
	expr = strings.TrimSpace(expr)
	if expr == "" {
		return true
	}

	var op string
	var parts []string
	operators := []string{"==", "!=", ">=", "<=", ">", "<"}
	for _, o := range operators {
		if strings.Contains(expr, o) {
			op = o
			parts = strings.SplitN(expr, o, 2)
			break
		}
	}

	if len(parts) != 2 {
		return true
	}

	regName := strings.ToUpper(strings.TrimSpace(parts[0]))
	valStr := strings.TrimSpace(parts[1])
	targetVal, err := parseHexOrDec(valStr)
	if err != nil {
		return true
	}

	var regVal uint32
	switch regName {
	case "A":
		regVal = uint32(cpu.A)
	case "F":
		regVal = uint32(cpu.F)
	case "B":
		regVal = uint32(cpu.B)
	case "C":
		regVal = uint32(cpu.C)
	case "D":
		regVal = uint32(cpu.D)
	case "E":
		regVal = uint32(cpu.E)
	case "H":
		regVal = uint32(cpu.H)
	case "L":
		regVal = uint32(cpu.L)
	case "AF":
		regVal = uint32(cpu.AF())
	case "BC":
		regVal = uint32(cpu.BC())
	case "DE":
		regVal = uint32(cpu.DE())
	case "HL":
		regVal = uint32(cpu.HL())
	case "IX":
		regVal = uint32(cpu.IX)
	case "IY":
		regVal = uint32(cpu.IY)
	case "SP":
		regVal = uint32(cpu.SP)
	case "PC":
		regVal = uint32(cpu.PC)
	default:
		return true
	}

	switch op {
	case "==":
		return regVal == targetVal
	case "!=":
		return regVal != targetVal
	case ">":
		return regVal > targetVal
	case "<":
		return regVal < targetVal
	case ">=":
		return regVal >= targetVal
	case "<=":
		return regVal <= targetVal
	}
	return true
}
