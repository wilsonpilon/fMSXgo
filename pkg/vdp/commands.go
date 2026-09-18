package vdp

// V9938 Command codes
const (
	CmdStop  = 0x0
	CmdPoint = 0x4
	CmdPset  = 0x5
	CmdSrch  = 0x6
	CmdLine  = 0x7
	CmdLMMV  = 0x8
	CmdLMMM  = 0x9
	CmdLMCM  = 0xA
	CmdLMMC  = 0xB
	CmdHMMV  = 0xC
	CmdHMMM  = 0xD
	CmdYMMM  = 0xE
	CmdHMMC  = 0xF
)

// CommandEngine implements V9938 blitter / graphics coprocessor operations.
type CommandEngine struct {
	vdp *VDP

	// Parameters parsed from R#32..R#46
	SX, SY uint16
	DX, DY uint16
	NX, NY uint16
	Color  uint8
	Arg    uint8
	Op     uint8

	ActiveOp uint8
	Busy     bool
	CE       bool // Command executing bit in Status 2
	TR       bool // Transfer ready bit in Status 2

	ReadBuf uint8
}

// NewCommandEngine creates a command engine attached to a VDP instance.
func NewCommandEngine(v *VDP) *CommandEngine {
	return &CommandEngine{
		vdp: v,
	}
}

// Write receives data for commands expecting CPU stream input (Port 0x98 / R#44).
func (c *CommandEngine) Write(val uint8) {
	// Transfer CPU byte to VRAM during LMMC / HMMC
	if c.ActiveOp == CmdHMMC || c.ActiveOp == CmdLMMC {
		c.executePoint(c.DX, c.DY, val)
		c.advanceDest()
	}
}

// Read returns data from commands generating CPU stream output (Port 0x99 S#7 / R#44).
func (c *CommandEngine) Read() uint8 {
	val := c.ReadBuf
	if c.ActiveOp == CmdLMCM {
		c.ReadBuf = c.readPoint(c.SX, c.SY)
		c.advanceSource()
	}
	return val
}

// Draw parses command registers (R#32..R#46) and starts command execution.
func (c *CommandEngine) Draw(op uint8) uint8 {
	c.SX = uint16(c.vdp.Regs[32]) | (uint16(c.vdp.Regs[33]&0x01) << 8)
	c.SY = uint16(c.vdp.Regs[34]) | (uint16(c.vdp.Regs[35]&0x03) << 8)
	c.DX = uint16(c.vdp.Regs[36]) | (uint16(c.vdp.Regs[37]&0x01) << 8)
	c.DY = uint16(c.vdp.Regs[38]) | (uint16(c.vdp.Regs[39]&0x03) << 8)
	c.NX = uint16(c.vdp.Regs[40]) | (uint16(c.vdp.Regs[41]&0x01) << 8)
	c.NY = uint16(c.vdp.Regs[42]) | (uint16(c.vdp.Regs[43]&0x03) << 8)
	c.Color = c.vdp.Regs[44]
	c.Arg = c.vdp.Regs[45]
	c.Op = op & 0x0F
	c.ActiveOp = (op >> 4) & 0x0F

	c.Execute()
	return 1
}

// Execute performs the command.
func (c *CommandEngine) Execute() {
	cmd := c.ActiveOp

	switch cmd {
	case CmdStop:
		c.CE = false
		c.TR = false
		c.vdp.Status[2] &^= 0x01

	case CmdPoint:
		// Read pixel at (SX, SY) into R#44 / S#7
		col := c.readPoint(c.SX, c.SY)
		c.vdp.Regs[44] = col
		c.vdp.Status[7] = col
		c.CE = false
		c.vdp.Status[2] &^= 0x01

	case CmdPset:
		// Write pixel at (DX, DY) with color R#44
		c.executePoint(c.DX, c.DY, c.Color)
		c.CE = false
		c.vdp.Status[2] &^= 0x01

	case CmdLine:
		// Line drawing using Bresenham
		c.drawLine()
		c.CE = false
		c.vdp.Status[2] &^= 0x01

	case CmdHMMV, CmdLMMV:
		// Fill rectangle DX, DY with size NX, NY
		nx := c.NX
		if nx == 0 {
			nx = 512
		}
		ny := c.NY
		if ny == 0 {
			ny = 1024
		}

		for y := uint16(0); y < ny; y++ {
			py := (c.DY + y) & 1023
			for x := uint16(0); x < nx; x++ {
				px := (c.DX + x) & 511
				c.executePoint(px, py, c.Color)
			}
		}
		c.CE = false
		c.vdp.Status[2] &^= 0x01

	case CmdHMMM, CmdLMMM:
		// Copy rectangle from (SX, SY) to (DX, DY)
		nx := c.NX
		if nx == 0 {
			nx = 512
		}
		ny := c.NY
		if ny == 0 {
			ny = 1024
		}

		for y := uint16(0); y < ny; y++ {
			sy := (c.SY + y) & 1023
			dy := (c.DY + y) & 1023
			for x := uint16(0); x < nx; x++ {
				sx := (c.SX + x) & 511
				dx := (c.DX + x) & 511
				col := c.readPoint(sx, sy)
				c.executePoint(dx, dy, col)
			}
		}
		c.CE = false
		c.vdp.Status[2] &^= 0x01

	case CmdYMMM:
		// Copy horizontal bands using SY to DY with DX matching SX
		nx := c.NX
		if nx == 0 {
			nx = 512
		}
		ny := c.NY
		if ny == 0 {
			ny = 1024
		}

		for y := uint16(0); y < ny; y++ {
			sy := (c.SY + y) & 1023
			dy := (c.DY + y) & 1023
			for x := uint16(0); x < nx; x++ {
				px := (c.DX + x) & 511
				col := c.readPoint(px, sy)
				c.executePoint(px, dy, col)
			}
		}
		c.CE = false
		c.vdp.Status[2] &^= 0x01

	case CmdHMMC, CmdLMMC:
		c.CE = true
		c.TR = true
		c.vdp.Status[2] |= 0x81 // CE and TR bits set

	case CmdLMCM:
		c.CE = true
		c.TR = true
		c.vdp.Status[2] |= 0x81
		c.ReadBuf = c.readPoint(c.SX, c.SY)
	}
}

func (c *CommandEngine) advanceDest() {
	c.DX++
	if c.DX >= c.NX {
		c.DX = 0
		c.DY++
		if c.DY >= c.NY {
			c.CE = false
			c.TR = false
			c.vdp.Status[2] &^= 0x81
		}
	}
}

func (c *CommandEngine) advanceSource() {
	c.SX++
	if c.SX >= c.NX {
		c.SX = 0
		c.SY++
		if c.SY >= c.NY {
			c.CE = false
			c.TR = false
			c.vdp.Status[2] &^= 0x81
		}
	}
}

func (c *CommandEngine) drawLine() {
	dx := int(c.NX)
	dy := int(c.NY)
	x := int(c.DX)
	y := int(c.DY)

	stepX := 1
	if (c.Arg & 0x04) != 0 {
		stepX = -1
	}
	stepY := 1
	if (c.Arg & 0x08) != 0 {
		stepY = -1
	}

	majX := (c.Arg & 0x01) == 0

	if majX {
		err := dx / 2
		for count := 0; count <= dx; count++ {
			c.executePoint(uint16(x&511), uint16(y&1023), c.Color)
			x += stepX
			err -= dy
			if err < 0 {
				y += stepY
				err += dx
			}
		}
	} else {
		err := dy / 2
		for count := 0; count <= dy; count++ {
			c.executePoint(uint16(x&511), uint16(y&1023), c.Color)
			y += stepY
			err -= dx
			if err < 0 {
				x += stepX
				err += dy
			}
		}
	}
}

// readPoint reads pixel value from VRAM based on current screen mode.
func (c *CommandEngine) readPoint(x, y uint16) uint8 {
	vram := c.vdp.VRAM
	if len(vram) == 0 {
		return 0
	}

	mode := c.vdp.ScrMode
	switch mode {
	case 5: // 256x192x16 (4bpp: 2 pixels per byte, 128 bytes/line)
		addr := (int(y&1023)<<7 + int(x&255)>>1) % len(vram)
		val := vram[addr]
		if (x & 1) == 0 {
			return val >> 4
		}
		return val & 0x0F

	case 6: // 512x192x4 (2bpp: 4 pixels per byte, 128 bytes/line)
		addr := (int(y&1023)<<7 + int(x&511)>>2) % len(vram)
		val := vram[addr]
		shift := 6 - (int(x&3) * 2)
		return (val >> shift) & 0x03

	case 7: // 512x192x16 (4bpp: 2 pixels per byte, 256 bytes/line)
		addr := (int(y&511)<<8 + int(x&511)>>1) % len(vram)
		val := vram[addr]
		if (x & 1) == 0 {
			return val >> 4
		}
		return val & 0x0F

	case 8: // 256x192x256 (8bpp: 1 pixel per byte, 256 bytes/line)
		addr := (int(y&511)<<8 + int(x&255)) % len(vram)
		return vram[addr]

	default:
		return 0
	}
}

// executePoint writes pixel value with logical operation into VRAM.
func (c *CommandEngine) executePoint(x, y uint16, col uint8) {
	vram := c.vdp.VRAM
	if len(vram) == 0 {
		return
	}

	mode := c.vdp.ScrMode
	op := c.Op

	switch mode {
	case 5: // 256x192x16 (4bpp)
		addr := (int(y&1023)<<7 + int(x&255)>>1) % len(vram)
		old := vram[addr]
		var cur uint8
		if (x & 1) == 0 {
			cur = old >> 4
		} else {
			cur = old & 0x0F
		}

		newVal := applyLogicalOp(cur, col&0x0F, op)
		if (x & 1) == 0 {
			vram[addr] = (newVal << 4) | (old & 0x0F)
		} else {
			vram[addr] = (old & 0xF0) | (newVal & 0x0F)
		}

	case 6: // 512x192x4 (2bpp)
		addr := (int(y&1023)<<7 + int(x&511)>>2) % len(vram)
		old := vram[addr]
		shift := 6 - (int(x&3) * 2)
		cur := (old >> shift) & 0x03
		newVal := applyLogicalOp(cur, col&0x03, op)

		mask := ^uint8(0x03 << shift)
		vram[addr] = (old & mask) | (newVal << shift)

	case 7: // 512x192x16 (4bpp)
		addr := (int(y&511)<<8 + int(x&511)>>1) % len(vram)
		old := vram[addr]
		var cur uint8
		if (x & 1) == 0 {
			cur = old >> 4
		} else {
			cur = old & 0x0F
		}

		newVal := applyLogicalOp(cur, col&0x0F, op)
		if (x & 1) == 0 {
			vram[addr] = (newVal << 4) | (old & 0x0F)
		} else {
			vram[addr] = (old & 0xF0) | (newVal & 0x0F)
		}

	case 8: // 256x192x256 (8bpp)
		addr := (int(y&511)<<8 + int(x&255)) % len(vram)
		cur := vram[addr]
		vram[addr] = applyLogicalOp(cur, col, op)
	}
}

// applyLogicalOp implements the 8 V9938 logical operators (IMP, AND, OR, XOR, NOT, etc.).
func applyLogicalOp(dst, src uint8, op uint8) uint8 {
	switch op & 0x07 {
	case 0: // IMP (replace)
		return src
	case 1: // AND
		return dst & src
	case 2: // OR
		return dst | src
	case 3: // XOR
		return dst ^ src
	case 4: // NOT
		return ^dst
	default:
		return src
	}
}
