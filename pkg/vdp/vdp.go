package vdp

// Dimensions for the rendered display buffer including MSX overscan borders (576x240).
const (
	LeftBorder   = 32
	RightBorder  = 32
	TopBorder    = 14
	BottomBorder = 14

	ScreenWidth     = 512
	ScreenHeight    = 192
	ScreenHeight212 = 212

	DisplayWidth  = LeftBorder + ScreenWidth + RightBorder  // 576
	DisplayHeight = TopBorder + ScreenHeight212 + BottomBorder // 240

	MaxScreen = 12
)

// Hardware models
const (
	ModelMSX1  = 0
	ModelMSX2  = 1
	ModelMSX2P = 2
)

// Mask structure matching fMSX MSK table for VDP table address masking
type AddressMask struct {
	R2, R3, R4, R5 uint8
	M2, M3, M4, M5 uint8
}

var ModeMasks = [MaxScreen + 2]AddressMask{
	{0x7F, 0x00, 0x3F, 0x00, 0x00, 0x00, 0x00, 0x00}, // SCR 0:  TEXT 40x24
	{0x7F, 0xFF, 0x3F, 0xFF, 0x00, 0x00, 0x00, 0x00}, // SCR 1:  TEXT 32x24
	{0x7F, 0x80, 0x3C, 0xFF, 0x00, 0x7F, 0x03, 0x00}, // SCR 2:  BLK 256x192
	{0x7F, 0x00, 0x3F, 0xFF, 0x00, 0x00, 0x00, 0x00}, // SCR 3:  64x48x16
	{0x7F, 0x80, 0x3C, 0xFC, 0x00, 0x7F, 0x03, 0x03}, // SCR 4:  BLK 256x192
	{0x60, 0x00, 0x00, 0xFC, 0x1F, 0x00, 0x00, 0x03}, // SCR 5:  256x192x16
	{0x60, 0x00, 0x00, 0xFC, 0x1F, 0x00, 0x00, 0x03}, // SCR 6:  512x192x4
	{0x20, 0x00, 0x00, 0xFC, 0x1F, 0x00, 0x00, 0x03}, // SCR 7:  512x192x16
	{0x20, 0x00, 0x00, 0xFC, 0x1F, 0x00, 0x00, 0x03}, // SCR 8:  256x192x256
	{0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, // SCR 9:  NONE
	{0x20, 0x00, 0x00, 0xFC, 0x1F, 0x00, 0x00, 0x03}, // SCR 10: YAE 256x192
	{0x20, 0x00, 0x00, 0xFC, 0x1F, 0x00, 0x00, 0x03}, // SCR 11: YAE 256x192
	{0x20, 0x00, 0x00, 0xFC, 0x1F, 0x00, 0x00, 0x03}, // SCR 12: YJK 256x192
	{0x7C, 0xF8, 0x3F, 0x00, 0x03, 0x07, 0x00, 0x00}, // SCR 0:  TEXT 80x24 (index 13)
}

// VDP encapsulates the Video Display Processor state (TMS9918 / V9938 / V9958).
type VDP struct {
	Model     int
	VRAMPages int
	VRAM      []byte

	Regs   [64]uint8
	Status [16]uint8

	Palette *Palette

	// Address sequencer and latches
	VAddr       uint16
	VKey        bool
	PKey        bool
	ALatch      uint8
	PLatch      uint8
	DataBuffer  uint8
	VPageOffset int

	// Current screen mode & colors
	ScrMode  uint8
	FGColor  uint8
	BGColor  uint8
	XFGColor uint8 // Alternative foreground color for TEXT80 (VDP[12] / fMSX)
	XBGColor uint8 // Alternative background color for TEXT80 (VDP[12] / fMSX)
	BCount   uint8 // Blinking counter for TEXT80
	BFlag    bool  // Blinking phase flag

	// Table addresses and masks into VRAM
	ChrTab  int
	ChrGen  int
	ColTab  int
	SprTab  int
	SprGen  int
	ChrTabM int
	ChrGenM int
	ColTabM int
	SprTabM int

	// Scanline and timing
	ScanLine     int
	TotalLines   int // 262 (NTSC) or 313 (PAL)
	Drawing      bool
	IRQPending   uint8 // bit 0: IE0 (VBlank), bit 1: IE1 (Line)
	VBlankLine   int

	// Command engine
	Cmd *CommandEngine

	// Frame buffer (RGBA 32-bit: DisplayWidth * DisplayHeight * 4 bytes)
	FrameBuffer [DisplayWidth * DisplayHeight * 4]byte
}

// New creates and initializes a VDP instance with given model and VRAM pages.
func New(model int, vramPages int) *VDP {
	if vramPages < 2 {
		vramPages = 2
	}
	if vramPages > 8 {
		vramPages = 8
	}

	v := &VDP{
		Model:      model,
		VRAMPages:  vramPages,
		VRAM:       make([]byte, vramPages*16384),
		Palette:    NewPalette(),
		TotalLines: 262, // Default NTSC
	}

	v.Cmd = NewCommandEngine(v)
	v.Reset()
	return v
}

// Reset restores the VDP to power-on default state.
func (v *VDP) Reset() {
	for i := range v.Regs {
		v.Regs[i] = 0
	}
	for i := range v.Status {
		v.Status[i] = 0
	}

	v.Palette.Reset()

	v.VAddr = 0
	v.VKey = false
	v.PKey = false
	v.ALatch = 0
	v.PLatch = 0
	v.DataBuffer = 0
	v.VPageOffset = 0

	v.FGColor = 15 // White
	v.BGColor = 4  // Dark Blue
	v.XFGColor = v.FGColor
	v.XBGColor = v.BGColor
	v.BCount = 0
	v.BFlag = false
	v.Regs[7] = (v.FGColor << 4) | v.BGColor

	v.ScanLine = 0
	v.Drawing = false
	v.IRQPending = 0

	if v.PALVideo() {
		v.TotalLines = 313
	} else {
		v.TotalLines = 262
	}

	// On MSX2+ (V9958), Status register 1 bit 2 is set (ID = 2)
	// Identical to fMSX MSX.c: if(MODEL(MSX_MSX2P)) VDPStatus[1]|=0x04;
	if v.Model == ModelMSX2P {
		v.Status[1] |= 0x04
	}

	v.SetScreen()
	v.ClearScreen()
}

// SetModel reconfigures the VDP hardware model and VRAM pages.
func (v *VDP) SetModel(model int, vramPages int) {
	if vramPages < 2 {
		vramPages = 2
	}
	if vramPages > 8 {
		vramPages = 8
	}
	v.Model = model
	v.VRAMPages = vramPages
	v.VRAM = make([]byte, vramPages*16384)
	v.Reset()
}

// BackdropColor returns the RGBA color of the screen backdrop / border.
// On MSX2/V9938, when TP=0 (SolidColor0 is false) and BGColor is 0,
// the transparent backdrop defaults to black unless an external video mode is active.
func (v *VDP) BackdropColor() RGBA {
	bg := v.BGColor & 0x0F
	if bg == 0 && !v.SolidColor0() {
		return RGBA{R: 0, G: 0, B: 0, A: 255}
	}
	return v.Palette.Colors[bg]
}

// ClearScreen fills the frame buffer with border background color.
func (v *VDP) ClearScreen() {
	bg := v.BackdropColor()
	for i := 0; i < len(v.FrameBuffer); i += 4 {
		v.FrameBuffer[i] = bg.R
		v.FrameBuffer[i+1] = bg.G
		v.FrameBuffer[i+2] = bg.B
		v.FrameBuffer[i+3] = 255
	}
}

// ReadData reads from Port 0x98 (VRAM data).
func (v *VDP) ReadData() uint8 {
	val := v.DataBuffer
	v.VKey = false

	// Prefetch next byte from VRAM
	addr := (v.VPageOffset + int(v.VAddr)) % len(v.VRAM)
	v.DataBuffer = v.VRAM[addr]

	// Auto-increment address
	v.VAddr = (v.VAddr + 1) & 0x3FFF
	if v.VAddr == 0 && v.ScrMode > 3 {
		v.Regs[14] = (v.Regs[14] + 1) & uint8(v.VRAMPages-1)
		v.VPageOffset = int(v.Regs[14]) << 14
	}

	return val
}

// WriteData writes to Port 0x98 (VRAM data).
func (v *VDP) WriteData(val uint8) {
	v.VKey = false
	v.DataBuffer = val

	addr := (v.VPageOffset + int(v.VAddr)) % len(v.VRAM)
	v.VRAM[addr] = val

	// Auto-increment address
	v.VAddr = (v.VAddr + 1) & 0x3FFF
	if v.VAddr == 0 && v.ScrMode > 3 {
		v.Regs[14] = (v.Regs[14] + 1) & uint8(v.VRAMPages-1)
		v.VPageOffset = int(v.Regs[14]) << 14
	}
}

// ReadStatus reads from Port 0x99 (VDP status registers).
func (v *VDP) ReadStatus() uint8 {
	reg := v.Regs[15] & 0x0F
	// On TMS9918 (MSX1), only Status Register 0 exists.
	if v.Model == ModelMSX1 {
		reg = 0
	}
	val := v.Status[reg]

	switch reg {
	case 0:
		// Reading S#0 clears VBlank flag (bit 7) and IE0 interrupt
		v.Status[0] &^= 0x80
		v.IRQPending &^= 0x01
	case 1:
		// Reading S#1 clears Line coincidence flag (bit 0) and IE1 interrupt
		v.Status[1] &^= 0x01
		v.IRQPending &^= 0x02
	case 7:
		// Status register 7 is color data read from VDP engine
		if v.Cmd != nil {
			v.Status[7] = v.Cmd.Read()
			val = v.Status[7]
		}
	}

	return val
}

// WriteControl writes to Port 0x99 (Control / Latch / Register setup).
func (v *VDP) WriteControl(val uint8) {
	if !v.VKey {
		v.ALatch = val
		v.VKey = true
	} else {
		v.VKey = false
		switch val & 0xC0 {
		case 0x80:
			// Register write
			reg := val & 0x3F
			v.VDPOut(reg, v.ALatch)
		case 0x00, 0x40:
			// Set VRAM read/write address
			v.VAddr = ((uint16(val&0x3F) << 8) | uint16(v.ALatch)) & 0x3FFF
			if (val & 0x40) == 0 {
				// Reading setup: prefetch first data byte
				addr := (v.VPageOffset + int(v.VAddr)) % len(v.VRAM)
				v.DataBuffer = v.VRAM[addr]
				v.VAddr = (v.VAddr + 1) & 0x3FFF
				if v.VAddr == 0 && v.ScrMode > 3 {
					v.Regs[14] = (v.Regs[14] + 1) & uint8(v.VRAMPages-1)
					v.VPageOffset = int(v.Regs[14]) << 14
				}
			}
		}
	}
}

// WritePalette writes to Port 0x9A (Palette Latch).
func (v *VDP) WritePalette(val uint8) {
	if !v.PKey {
		v.PLatch = val
		v.PKey = true
	} else {
		v.PKey = false
		idx := int(v.Regs[16] & 0x0F)

		r := (v.PLatch >> 4) & 0x07
		b := v.PLatch & 0x07
		g := val & 0x07

		v.Palette.SetColor3Bit(idx, r, g, b)
		// Advance to next palette register
		v.Regs[16] = uint8((idx + 1) & 0x0F)
	}
}

// WriteRegisterDirect writes to Port 0x9B (Indirect register access).
func (v *VDP) WriteRegisterDirect(val uint8) {
	reg := v.Regs[17] & 0x3F
	if reg != 17 {
		v.VDPOut(reg, val)
	}
	if (v.Regs[17] & 0x80) == 0 {
		v.Regs[17] = (reg + 1) & 0x3F
	}
}

// VDPOut writes a value into a specific control register and updates table pointers.
func (v *VDP) VDPOut(reg uint8, val uint8) {
	switch reg {
	case 0:
		// Reset HBlank interrupt if disabled
		if (v.Status[1]&0x01) != 0 && (val&0x10) == 0 {
			v.Status[1] &^= 0x01
			v.IRQPending &^= 0x02
		}
		if v.Regs[0] != val {
			v.Regs[0] = val
			v.SetScreen()
		}
	case 1:
		// Enable or disable VBlank interrupt
		if (v.Status[0] & 0x80) != 0 {
			if (val & 0x20) != 0 {
				v.IRQPending |= 0x01
			} else {
				v.IRQPending &^= 0x01
			}
		}
		if v.Regs[1] != val {
			v.Regs[1] = val
			v.SetScreen()
		}
	case 2:
		v.Regs[2] = val
		shift := 10
		if v.ScrMode > 6 && v.ScrMode != 13 {
			shift = 11
		}
		mask := ModeMasks[v.ScrMode]
		v.ChrTab = (int(val&mask.R2) << shift) % len(v.VRAM)
		v.ChrTabM = ((int(val|uint8(^mask.M2)) << shift) | ((1 << shift) - 1))
	case 3:
		v.Regs[3] = val
		mask := ModeMasks[v.ScrMode]
		v.ColTab = ((int(val&mask.R3) << 6) + (int(v.Regs[10]) << 14)) % len(v.VRAM)
		v.ColTabM = ((int(val|uint8(^mask.M3)) << 6) | 0x1C03F)
	case 4:
		v.Regs[4] = val
		mask := ModeMasks[v.ScrMode]
		v.ChrGen = (int(val&mask.R4) << 11) % len(v.VRAM)
		v.ChrGenM = ((int(val|uint8(^mask.M4)) << 11) | 0x007FF)
	case 5:
		v.Regs[5] = val
		mask := ModeMasks[v.ScrMode]
		v.SprTab = ((int(val&mask.R5) << 7) + (int(v.Regs[11]) << 15)) % len(v.VRAM)
		v.SprTabM = ((int(val|uint8(^mask.M5)) << 7) | 0x1807F)
	case 6:
		val &= 0x3F
		v.Regs[6] = val
		v.SprGen = (int(val) << 11) % len(v.VRAM)
	case 7:
		v.FGColor = val >> 4
		v.BGColor = val & 0x0F
	case 9:
		v.Regs[9] = val
		if (val & 0x02) != 0 {
			v.TotalLines = 313 // PAL
		} else {
			v.TotalLines = 262 // NTSC
		}
	case 10:
		val &= 0x07
		v.Regs[10] = val
		mask := ModeMasks[v.ScrMode]
		v.ColTab = ((int(v.Regs[3]&mask.R3) << 6) + (int(val) << 14)) % len(v.VRAM)
	case 11:
		val &= 0x03
		v.Regs[11] = val
		mask := ModeMasks[v.ScrMode]
		v.SprTab = ((int(v.Regs[5]&mask.R5) << 7) + (int(val) << 15)) % len(v.VRAM)
	case 14:
		val &= uint8(v.VRAMPages - 1)
		v.Regs[14] = val
		v.VPageOffset = int(val) << 14
	case 15:
		val &= 0x0F
	case 16:
		val &= 0x0F
		v.PKey = false
	case 17:
		val &= 0xBF
	case 25:
		v.Regs[25] = val
		v.SetScreen()
	case 44:
		if v.Cmd != nil {
			v.Cmd.Write(val)
		}
	case 46:
		if v.Cmd != nil {
			v.Cmd.Draw(val)
		}
	}

	v.Regs[reg] = val
}

// SetScreen recalculates screen mode and table base addresses from VDP control registers.
func (v *VDP) SetScreen() uint8 {
	var mode uint8
	switch ((v.Regs[0] & 0x0E) >> 1) | (v.Regs[1] & 0x18) {
	case 0x10:
		mode = 0 // TEXT 40
	case 0x00:
		mode = 1 // TEXT 32
	case 0x01:
		mode = 2 // GRAPHIC 1 (BLK 256x192)
	case 0x08:
		mode = 3 // MULTICOLOR
	case 0x02:
		mode = 4 // GRAPHIC 2 (BLK 256x192)
	case 0x03:
		mode = 5 // SCREEN 5 (256x192x16)
	case 0x04:
		mode = 6 // SCREEN 6 (512x192x4)
	case 0x05:
		mode = 7 // SCREEN 7 (512x192x16)
	case 0x07:
		mode = 8 // SCREEN 8 (256x192x256)
	case 0x12:
		mode = 13 // TEXT 80
	default:
		mode = v.ScrMode
	}

	v.ScrMode = mode
	mask := ModeMasks[mode]

	shift := 10
	if mode > 6 && mode != 13 {
		shift = 11
	}

	v.ChrTab = (int(v.Regs[2]&mask.R2) << shift) % len(v.VRAM)
	v.ChrGen = (int(v.Regs[4]&mask.R4) << 11) % len(v.VRAM)
	v.ColTab = ((int(v.Regs[3]&mask.R3) << 6) + (int(v.Regs[10]) << 14)) % len(v.VRAM)
	v.SprTab = ((int(v.Regs[5]&mask.R5) << 7) + (int(v.Regs[11]) << 15)) % len(v.VRAM)
	v.SprGen = (int(v.Regs[6]&0x3F) << 11) % len(v.VRAM)

	v.ChrTabM = (int(v.Regs[2]|uint8(^mask.M2)) << shift) | ((1 << shift) - 1)
	v.ChrGenM = (int(v.Regs[4]|uint8(^mask.M4)) << 11) | 0x007FF
	v.ColTabM = (int(v.Regs[3]|uint8(^mask.M3)) << 6) | 0x1C03F
	v.SprTabM = (int(v.Regs[5]|uint8(^mask.M5)) << 7) | 0x1807F

	return mode
}

// Convenient helper properties
func (v *VDP) ScreenON() bool      { return (v.Regs[1] & 0x40) != 0 }
func (v *VDP) SpritesOFF() bool    { return (v.Regs[8] & 0x02) != 0 }
func (v *VDP) Sprites16x16() bool  { return (v.Regs[1] & 0x02) != 0 }
func (v *VDP) BigSprites() bool    { return (v.Regs[1] & 0x01) != 0 }
func (v *VDP) ScanLines212() bool  { return (v.Regs[9] & 0x80) != 0 }
func (v *VDP) PALVideo() bool      { return (v.Regs[9] & 0x02) != 0 }
func (v *VDP) SolidColor0() bool   { return (v.Regs[8] & 0x20) != 0 }
func (v *VDP) ModeYJK() bool       { return (v.Regs[25] & 0x08) != 0 }
func (v *VDP) ModeYAE() bool       { return (v.Regs[25] & 0x10) != 0 }
func (v *VDP) MaskLeft() bool       { return (v.Regs[25] & 0x02) != 0 }
func (v *VDP) HScroll512() bool    { return (v.Regs[25] & 0x01) != 0 }
func (v *VDP) VScroll() uint8      { return v.Regs[23] }
func (v *VDP) HScroll() int        { return int(v.Regs[27]&0x07) | (int(v.Regs[26]&0x3F) << 3) }
func (v *VDP) VAdjust() int        { return int(int8(v.Regs[18]) >> 4) }
func (v *VDP) HAdjust() int        { return int(int8(v.Regs[18]<<4) >> 4) }
func (v *VDP) InterruptPending() bool { return v.IRQPending != 0 }

// UpdateBlink updates the blinking state for TEXT80 mode once per frame.
// Directly mirrors fMSX MSX.c lines 2061-2076:
//
//	if(BCount) BCount--;
//	else {
//	    BFlag = !BFlag;
//	    if(!VDP[13]) { XFGColor = FGColor; XBGColor = BGColor; }
//	    else {
//	        BCount = (BFlag ? VDP[13]&0x0F : VDP[13]>>4) * 10;
//	        if(BCount) {
//	            if(BFlag) { XFGColor = FGColor; XBGColor = BGColor; }
//	            else      { XFGColor = VDP[12]>>4; XBGColor = VDP[12]&0x0F; }
//	        }
//	    }
//	}
func (v *VDP) UpdateBlink() {
	if v.BCount > 0 {
		v.BCount--
	} else {
		v.BFlag = !v.BFlag
		if v.Regs[13] == 0 {
			v.XFGColor = v.FGColor
			v.XBGColor = v.BGColor
		} else {
			if v.BFlag {
				v.BCount = (v.Regs[13] & 0x0F) * 10
			} else {
				v.BCount = (v.Regs[13] >> 4) * 10
			}
			if v.BCount > 0 {
				if v.BFlag {
					v.XFGColor = v.FGColor
					v.XBGColor = v.BGColor
				} else {
					v.XFGColor = v.Regs[12] >> 4
					v.XBGColor = v.Regs[12] & 0x0F
				}
			}
		}
	}
}
