package msx

import (
	"testing"
)

func TestJoystickManagerNormal(t *testing.T) {
	jm := NewJoystickManager()

	// Initially all buttons released -> 0x3F | 0x40 = 0x7F
	val := jm.ReadPort(0x00) // Port 1 (bit 6 = 0)
	if val != 0x7F {
		t.Fatalf("expected idle value 0x7F, got 0x%02X", val)
	}

	// Press Up and Trigger A on Port 1
	jm.UpdateButtons(0, true, false, false, false, true, false)

	// Read Port 1 (reg15 bit 6 = 0)
	val = jm.ReadPort(0x00)
	// Up = bit 0 (0), Trigger A = bit 4 (0) -> 0x3F &^ (1 | 0x10) = 0x2E | 0x40 = 0x6E
	if val != 0x6E {
		t.Fatalf("expected 0x6E for Up + Trigger A on Port 1, got 0x%02X", val)
	}

	// Port 2 should still be idle (reg15 bit 6 = 1 -> 0x40)
	valP2 := jm.ReadPort(0x40)
	if valP2 != 0x7F {
		t.Fatalf("expected 0x7F on Port 2, got 0x%02X", valP2)
	}

	// Press Down + Right + Trigger B on Port 2
	jm.UpdateButtons(1, false, true, false, true, false, true)
	valP2 = jm.ReadPort(0x40)
	// Down = bit 1 (0), Right = bit 3 (0), Trigger B = bit 5 (0)
	// 0x3F &^ (0x02 | 0x08 | 0x20) = 0x15 | 0x40 = 0x55
	if valP2 != 0x55 {
		t.Fatalf("expected 0x55 on Port 2, got 0x%02X", valP2)
	}
}

func TestJoystickManagerMouse(t *testing.T) {
	jm := NewJoystickManager()
	jm.SetPortType(0, JoyMouse)

	// Simulate mouse movement
	jm.UpdateMouse(0, 100, 100, false, false, false) // Init anchor
	jm.UpdateMouse(0, 120, 110, true, false, false)  // DX = +20 (0x14), DY = +10 (0x0A), Left click (Trigger A)

	// Start reading mouse:
	// 1. Initial strobe write to Reg 15 (toggle bit 4)
	jm.OnWriteReg15(0x10, 0x00) // MCount advances to 1 (High nibble of DX)
	val1 := jm.ReadPort(0x00)
	// High nibble of 0x14 is 1. Trigger A is pressed (bit 4 = 0), Trigger B is released (bit 5 = 1) -> buttons = 0x20
	// 1 | 0x20 = 0x21 | 0x40 = 0x61
	if val1 != 0x61 {
		t.Fatalf("expected mouse phase 1 value 0x61, got 0x%02X", val1)
	}

	// 2. Next strobe (toggle bit 4)
	jm.OnWriteReg15(0x00, 0x10) // MCount advances to 2 (Low nibble of DX)
	val2 := jm.ReadPort(0x00)
	// Low nibble of 0x14 is 4. Buttons = 0x20. 4 | 0x20 = 0x24 | 0x40 = 0x64
	if val2 != 0x64 {
		t.Fatalf("expected mouse phase 2 value 0x64, got 0x%02X", val2)
	}

	// 3. Next strobe (toggle bit 4)
	jm.OnWriteReg15(0x10, 0x00) // MCount advances to 3 (High nibble of DY)
	val3 := jm.ReadPort(0x00)
	// High nibble of 0x0A is 0. 0 | 0x20 = 0x20 | 0x40 = 0x60
	if val3 != 0x60 {
		t.Fatalf("expected mouse phase 3 value 0x60, got 0x%02X", val3)
	}

	// 4. Next strobe (toggle bit 4)
	jm.OnWriteReg15(0x00, 0x10) // MCount advances to 4 (Low nibble of DY)
	val4 := jm.ReadPort(0x00)
	// Low nibble of 0x0A is 10 (0x0A). 0x0A | 0x20 = 0x2A | 0x40 = 0x6A
	if val4 != 0x6A {
		t.Fatalf("expected mouse phase 4 value 0x6A, got 0x%02X", val4)
	}

	// 5. Next strobe resets MCount back to 1
	jm.OnWriteReg15(0x10, 0x00)
	if jm.Ports[0].MCount != 1 {
		t.Fatalf("expected MCount to loop back to 1, got %d", jm.Ports[0].MCount)
	}

	// 6. Idle strobe (bits 0..1 = 3) resets MCount to 0
	jm.OnWriteReg15(0x03, 0x10)
	if jm.Ports[0].MCount != 0 {
		t.Fatalf("expected MCount to reset to 0, got %d", jm.Ports[0].MCount)
	}
}

func TestJoystickNone(t *testing.T) {
	jm := NewJoystickManager()
	jm.SetPortType(0, JoyNone)

	val := jm.ReadPort(0x00)
	if val != 0x7F {
		t.Fatalf("expected 0x7F for JoyNone, got 0x%02X", val)
	}
}
