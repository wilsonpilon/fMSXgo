package msx

import "sync"

// Joystick types matching fMSX JOY_* constants
const (
	JoyNone   = 0 // No device connected
	JoyNormal = 1 // Standard 2-button MSX Joystick / Gamepad
	JoyMouse  = 2 // MSX Mouse
)

// JoystickPort represents the state of an MSX joystick port (Port 1 or Port 2).
type JoystickPort struct {
	Type int // JoyNone, JoyNormal, or JoyMouse

	// Joystick button state (active low: 0 = pressed, 1 = released)
	// Bit 0: Up
	// Bit 1: Down
	// Bit 2: Left
	// Bit 3: Right
	// Bit 4: Trigger A (Fire 1)
	// Bit 5: Trigger B (Fire 2)
	State uint8

	// Mouse state
	MCount    uint8 // 0 = idle / joystick, 1..4 = mouse nibbles
	MouseDX   int   // Relative horizontal displacement (-127..127)
	MouseDY   int   // Relative vertical displacement (-127..127)
	LastRawX  int   // Previous absolute cursor X
	LastRawY  int   // Previous absolute cursor Y
	MouseInit bool  // True once initial mouse position has been received
}

// JoystickManager manages both MSX joystick ports and coordinates with PSG registers 14 and 15.
// Directly mirrors fMSX MSX.c:1154-1210 and 1344-1355.
type JoystickManager struct {
	mu    sync.Mutex
	Ports [2]JoystickPort
}

// NewJoystickManager creates a new JoystickManager with Port 1 as JoyNormal and Port 2 as JoyNormal.
func NewJoystickManager() *JoystickManager {
	jm := &JoystickManager{}
	jm.Reset()
	return jm
}

// Reset resets joystick and mouse states.
func (jm *JoystickManager) Reset() {
	jm.mu.Lock()
	defer jm.mu.Unlock()

	jm.Ports[0].Type = JoyNormal
	jm.Ports[0].State = 0x3F // All buttons released (active low)
	jm.Ports[0].MCount = 0
	jm.Ports[0].MouseDX = 0
	jm.Ports[0].MouseDY = 0
	jm.Ports[0].MouseInit = false

	jm.Ports[1].Type = JoyNormal
	jm.Ports[1].State = 0x3F // All buttons released (active low)
	jm.Ports[1].MCount = 0
	jm.Ports[1].MouseDX = 0
	jm.Ports[1].MouseDY = 0
	jm.Ports[1].MouseInit = false
}

// SetPortType sets the connected device type for port 0 (Joy 1) or port 1 (Joy 2).
func (jm *JoystickManager) SetPortType(port int, joyType int) {
	jm.mu.Lock()
	defer jm.mu.Unlock()
	if port >= 0 && port < 2 {
		jm.Ports[port].Type = joyType
		jm.Ports[port].MCount = 0
	}
}

// UpdateButtons updates the directional and button inputs for a port.
func (jm *JoystickManager) UpdateButtons(port int, up, down, left, right, btnA, btnB bool) {
	if port < 0 || port >= 2 {
		return
	}

	jm.mu.Lock()
	defer jm.mu.Unlock()

	// Default 0x3F = all released
	var s uint8 = 0x3F
	if up {
		s &^= 0x01
	}
	if down {
		s &^= 0x02
	}
	if left {
		s &^= 0x04
	}
	if right {
		s &^= 0x08
	}
	if btnA {
		s &^= 0x10
	}
	if btnB {
		s &^= 0x20
	}
	jm.Ports[port].State = s
}

// UpdateMouse updates mouse cursor position and button clicks for a port.
func (jm *JoystickManager) UpdateMouse(port int, rawX, rawY int, btnLeft, btnRight bool, isHighRes bool) {
	if port < 0 || port >= 2 {
		return
	}

	jm.mu.Lock()
	defer jm.mu.Unlock()

	p := &jm.Ports[port]
	if !p.MouseInit {
		p.LastRawX = rawX
		p.LastRawY = rawY
		p.MouseInit = true
		return
	}

	dx := rawX - p.LastRawX
	dy := rawY - p.LastRawY
	p.LastRawX = rawX
	p.LastRawY = rawY

	if isHighRes {
		dx <<= 1
	}

	// Clamp offsets to -127..127
	if dx > 127 {
		dx = 127
	} else if dx < -127 {
		dx = -127
	}
	if dy > 127 {
		dy = 127
	} else if dy < -127 {
		dy = -127
	}

	p.MouseDX = dx
	p.MouseDY = dy

	// Update mouse buttons (active low on bits 4 and 5)
	var s uint8 = 0x30
	if btnLeft {
		s &^= 0x10 // Trigger A
	}
	if btnRight {
		s &^= 0x20 // Trigger B
	}
	p.State = (p.State & 0x0F) | s
}

// OnWriteReg15 handles writes to PSG register 15, advancing or resetting mouse nibble phases.
// Directly mirrors fMSX MSX.c:1344-1355.
func (jm *JoystickManager) OnWriteReg15(val uint8, oldReg15 uint8) {
	jm.mu.Lock()
	defer jm.mu.Unlock()

	// Port 1 (Joy 2) strobe is on bits 2..3 / 5
	if (val & 0x0C) == 0x0C {
		jm.Ports[1].MCount = 0
	} else if jm.Ports[1].Type == JoyMouse && ((val^oldReg15)&0x20) != 0 {
		if jm.Ports[1].MCount == 4 {
			jm.Ports[1].MCount = 1
		} else {
			jm.Ports[1].MCount++
		}
	}

	// Port 0 (Joy 1) strobe is on bits 0..1 / 4
	if (val & 0x03) == 0x03 {
		jm.Ports[0].MCount = 0
	} else if jm.Ports[0].Type == JoyMouse && ((val^oldReg15)&0x10) != 0 {
		if jm.Ports[0].MCount == 4 {
			jm.Ports[0].MCount = 1
		} else {
			jm.Ports[0].MCount++
		}
	}
}

// ReadPort returns the 8-bit value for PSG register 14 (Port 0xA2 read).
// Directly mirrors fMSX MSX.c:1154-1198.
func (jm *JoystickManager) ReadPort(reg15 uint8) uint8 {
	jm.mu.Lock()
	defer jm.mu.Unlock()

	// Bit 6 selects port: 0 = Port 1, 1 = Port 2
	portIdx := int((reg15 & 0x40) >> 6)
	p := &jm.Ports[portIdx]

	if p.Type == JoyNone {
		return 0x7F
	}

	j := p.State & 0x3F
	var out uint8

	switch p.MCount {
	case 0:
		// Normal Joystick reading
		// Check pulse strobe line: if pulse bit is high, return idle 0x3F, else button state
		pulseBit := uint8(0x10 << portIdx)
		if (reg15 & pulseBit) != 0 {
			out = 0x3F
		} else {
			out = j
		}
	case 1:
		// Mouse: High nibble of X offset + buttons
		out = (uint8(p.MouseDX>>4) & 0x0F) | (j & 0x30)
	case 2:
		// Mouse: Low nibble of X offset + buttons
		out = (uint8(p.MouseDX) & 0x0F) | (j & 0x30)
	case 3:
		// Mouse: High nibble of Y offset + buttons
		out = (uint8(p.MouseDY>>4) & 0x0F) | (j & 0x30)
	case 4:
		// Mouse: Low nibble of Y offset + buttons
		out = (uint8(p.MouseDY) & 0x0F) | (j & 0x30)
	default:
		out = j
	}

	// Bit 6 is always 1 in PSG register 14
	return (out & 0x3F) | 0x40
}
