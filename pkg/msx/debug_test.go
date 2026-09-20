package msx

import (
	"testing"

	"fmsxgo/pkg/cpu/z80"
)

func TestDebuggerPCBreakpointAndCondition(t *testing.T) {
	dbg := NewDebugger(nil)
	cpu := z80.New()

	bpID := dbg.AddPC(0x4000, "A == 0x42")
	if bpID != 1 {
		t.Fatalf("expected bpID 1, got %d", bpID)
	}

	cpu.PC = 0x4000
	cpu.A = 0x10

	// Condition A == 0x42 not met
	bp, hit := dbg.CheckPC(cpu)
	if hit || bp != nil {
		t.Fatalf("breakpoint should not hit when condition false")
	}

	// Condition A == 0x42 met
	cpu.A = 0x42
	bp, hit = dbg.CheckPC(cpu)
	if !hit || bp == nil || bp.ID != bpID {
		t.Fatalf("breakpoint should hit when condition true, got hit=%v, bp=%v", hit, bp)
	}
	if bp.HitCount != 1 {
		t.Fatalf("expected HitCount=1, got %d", bp.HitCount)
	}
}

func TestDebuggerMemoryAndIOWatchpoints(t *testing.T) {
	dbg := NewDebugger(nil)
	cpu := z80.New()

	// Memory write watchpoint at 0xC000..0xC00F
	memID := dbg.AddMemWatch(0xC000, 0xC00F, true, "")
	// IO Out watchpoint at port 0x98
	ioID := dbg.AddIOWatch(0x98, true, "")

	if !dbg.HasWatch {
		t.Fatalf("expected HasWatch to be true")
	}

	// Outside range
	bp, hit := dbg.CheckMemWrite(cpu, 0xBFFF, 0x00)
	if hit || bp != nil {
		t.Fatalf("should not hit outside range")
	}

	// Inside range
	bp, hit = dbg.CheckMemWrite(cpu, 0xC005, 0x55)
	if !hit || bp == nil || bp.ID != memID {
		t.Fatalf("expected mem write hit on 0xC005")
	}

	// IO Port hit
	bp, hit = dbg.CheckIO(cpu, 0x98, true)
	if !hit || bp == nil || bp.ID != ioID {
		t.Fatalf("expected IO out hit on port 0x98")
	}

	// Remove breakpoint
	if !dbg.Remove(memID) {
		t.Fatalf("failed to remove breakpoint %d", memID)
	}
	bp, hit = dbg.CheckMemWrite(cpu, 0xC005, 0x55)
	if hit {
		t.Fatalf("breakpoint was removed, should not hit")
	}
}

func TestDebuggerScanline(t *testing.T) {
	dbg := NewDebugger(nil)
	lineID := dbg.AddScanline(100)

	if !dbg.HasScanline {
		t.Fatalf("expected HasScanline to be true")
	}

	bp, hit := dbg.CheckScanline(99)
	if hit || bp != nil {
		t.Fatalf("should not hit scanline 99")
	}

	bp, hit = dbg.CheckScanline(100)
	if !hit || bp == nil || bp.ID != lineID {
		t.Fatalf("expected scanline hit on line 100")
	}
}
