package msx

import (
	"time"

	"fmsxgo/pkg/cpu/z80"
	"fmsxgo/pkg/sound"
	"fmsxgo/pkg/vdp"
)

// RTCInit represents default CMOS values matching fMSX 6.0
var RTCInit = [4][13]uint8{
	{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	{0, 0, 0, 0, 40, 80, 15, 4, 4, 0, 0, 0, 0},
	{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
}

// MSXBus implements the z80.Bus interface for the MSX architecture.
type MSXBus struct {
	Slots     *SlotBus
	Mapper    *RAMMapper
	CartA     *Cartridge
	CartB     *Cartridge
	VDP       *vdp.VDP
	PSG       *sound.AY8910
	SCC       *sound.SCC
	OPLL      *sound.YM2413
	Joy       *JoystickManager
	FDC       *WD1793

	// PPI 8255 state
	KeyMatrix  [16]uint8 // Keyboard matrix rows 0..15
	KeyRow     uint8     // Current row selected via PPI port C (0xAA)
	PPICtrl    uint8     // PPI control register (0xAB)

	// RTC RP5C01 state (faithful to fMSX)
	RTCReg  uint8
	RTCMode uint8
	RTC     [4][16]uint8

	// IO Ports debugging/callbacks
	OnIORead  func(port uint16)
	OnIOWrite func(port uint16, val uint8)

	// CPU & Debugger hooks
	CPU      *z80.Z80
	Debugger *Debugger
}

// Ensure MSXBus implements z80.Bus
var _ z80.Bus = (*MSXBus)(nil)

// NewMSXBus creates an MSXBus wired with SlotBus, RAMMapper, and VDP.
func NewMSXBus(slots *SlotBus, mapper *RAMMapper, vdpInst *vdp.VDP) *MSXBus {
	bus := &MSXBus{
		Slots:  slots,
		Mapper: mapper,
		VDP:    vdpInst,
		Joy:    NewJoystickManager(),
	}
	// Initialize default RTC CMOS state
	bus.InitRTC()

	// Default all keyboard matrix rows to 0xFF (no key pressed)
	for i := range bus.KeyMatrix {
		bus.KeyMatrix[i] = 0xFF
	}
	return bus
}

// InitRTC initializes RTC registers with fMSX default CMOS values
func (b *MSXBus) InitRTC() {
	b.RTCReg = 0
	b.RTCMode = 0
	for i := 0; i < 4; i++ {
		for j := 0; j < 16; j++ {
			if j < 13 {
				b.RTC[i][j] = RTCInit[i][j]
			} else {
				b.RTC[i][j] = 0
			}
		}
	}
}

// Read reads a byte from the Z80 16-bit address space.
func (b *MSXBus) Read(addr uint16) uint8 {
	if b.Debugger != nil && b.Debugger.HasWatch && b.CPU != nil {
		b.Debugger.CheckMemRead(b.CPU, addr)
	}

	// Secondary slot selector register at 0xFFFF (only if slot in page 3 is expanded)
	if addr == 0xFFFF && b.Slots.IsSubslot[b.Slots.CurPSL[3]] {
		return b.Slots.GetSSL()
	}

	// Konami SCC sound chip memory read at 0x9800..0x98FF
	if (addr & 0xFF00) == 0x9800 && b.SCC != nil {
		page16k := addr >> 14
		psl := b.Slots.CurPSL[page16k]
		if (psl == 1 && b.CartA != nil && b.CartA.MapperType == MapperKonami5 && b.CartA.Banks[2] == 0x3F) ||
			(psl == 2 && b.CartB != nil && b.CartB.MapperType == MapperKonami5 && b.CartB.Banks[2] == 0x3F) {
			return b.SCC.Read(uint8(addr & 0xFF))
		}
	}

	// WD1793/2793 Floppy Disk Controller (FDC) memory-mapped I/O (fMSX MSX.c:1015-1025)
	// Standard: 7FF8h..7FFFh | MSX-DOS: BFF8h..BFFFh | Arabic: 7F80h..7F87h | SV738: 7FB8h..7FBFh
	if b.FDC != nil && (addr&0x3F88) == 0x3F88 {
		page16k := addr >> 14
		if b.Slots.CurPSL[page16k] == 3 && b.Slots.CurSSL[page16k] == 1 {
			switch addr {
			case 0x7FF8, 0xBFF8, 0x7F80, 0x7FB8:
				return b.FDC.Read(WD1793Status)
			case 0x7FF9, 0xBFF9, 0x7F81, 0x7FB9:
				return b.FDC.Read(WD1793Track)
			case 0x7FFA, 0xBFFA, 0x7F82, 0x7FBA:
				return b.FDC.Read(WD1793Sector)
			case 0x7FFB, 0xBFFB, 0x7F83, 0x7FBB:
				return b.FDC.Read(WD1793Data)
			case 0x7FFF, 0xBFFF, 0x7F84, 0x7FBC:
				return b.FDC.Read(WD1793Ready)
			}
		}
	}

	page8k := addr >> 13
	offset := addr & 0x1FFF
	pageSlice := b.Slots.RAM[page8k]
	if pageSlice != nil && int(offset) < len(pageSlice) {
		return pageSlice[offset]
	}
	return 0xFF
}

// Write writes a byte to the Z80 16-bit address space.
func (b *MSXBus) Write(addr uint16, val uint8) {
	if b.Debugger != nil && b.Debugger.HasWatch && b.CPU != nil {
		b.Debugger.CheckMemWrite(b.CPU, addr, val)
	}

	// Secondary slot selector register at 0xFFFF (only if slot in page 3 is expanded)
	if addr == 0xFFFF && b.Slots.IsSubslot[b.Slots.CurPSL[3]] {
		b.Slots.SetSSL(val)
		return
	}

	page16k := addr >> 14
	page8k := addr >> 13
	offset := addr & 0x1FFF
	psl := b.Slots.CurPSL[page16k]
	ssl := b.Slots.CurSSL[page16k]

	// Konami SCC sound chip memory write at 0x9800..0x98FF
	if (addr & 0xFF00) == 0x9800 && b.SCC != nil {
		if (psl == 1 && b.CartA != nil && b.CartA.MapperType == MapperKonami5 && b.CartA.Banks[2] == 0x3F) ||
			(psl == 2 && b.CartB != nil && b.CartB.MapperType == MapperKonami5 && b.CartB.Banks[2] == 0x3F) {
			b.SCC.Write(uint8(addr & 0xFF), val)
			return
		}
	}

	// WD1793/2793 Floppy Disk Controller (FDC) memory-mapped I/O (fMSX MSX.c:1040-1067)
	if b.FDC != nil && (addr&0x3F88) == 0x3F88 {
		if psl == 3 && ssl == 1 {
			switch addr {
			case 0x7FF8, 0xBFF8, 0x7F80, 0x7FB8: // Command
				b.FDC.Write(WD1793Command, val)
				return
			case 0x7FF9, 0xBFF9, 0x7F81, 0x7FB9: // Track
				b.FDC.Write(WD1793Track, val)
				return
			case 0x7FFA, 0xBFFA, 0x7F82, 0x7FBA: // Sector
				b.FDC.Write(WD1793Sector, val)
				return
			case 0x7FFB, 0xBFFB, 0x7F83, 0x7FBB: // Data
				b.FDC.Write(WD1793Data, val)
				return
			case 0x7FFC, 0xBFFC: // Side select: [xxxxxxxS] (1: side 0, 0: side 1)
				sideBit := byte(0)
				if (val & 0x01) == 0 {
					sideBit = SSide
				}
				b.FDC.Write(WD1793System, (b.FDC.Drive&SDrive)|SDensity|sideBit)
				return
			case 0x7FFD, 0xBFFD: // Drive select: [xxxxxxxD]
				sideBit := byte(0)
				if b.FDC.Side != 0 {
					sideBit = 0
				} else {
					sideBit = SSide
				}
				b.FDC.Write(WD1793System, (val&0x01)|SDensity|sideBit)
				return
			case 0x7F84, 0x7FBC: // Arabic/SV738 Side/Drive/Motor: [xxxxMSDD]
				sideBit := byte(0)
				if (val & 0x04) == 0 {
					sideBit = SSide
				}
				b.FDC.Write(WD1793System, (val&0x03)|SDensity|sideBit)
				return
			}
		}
	}

	// If RAM is write-enabled on this 8KB page, write directly to memory
	if b.Slots.IsRAM[psl][ssl][page8k] {
		pageSlice := b.Slots.RAM[page8k]
		if pageSlice != nil && int(offset) < len(pageSlice) {
			pageSlice[offset] = val
			return
		}
	}

	// If ROM area (0x4000 - 0xBFFF), check for cartridge bank switching
	if addr >= 0x4000 && addr < 0xC000 {
		if psl == 1 && b.CartA != nil {
			if b.CartA.Write(addr, val) {
				// Refresh cartridge bank mapping in slot 1
				b.RefreshCartridge(1, b.CartA)
				return
			}
		} else if psl == 2 && b.CartB != nil {
			if b.CartB.Write(addr, val) {
				// Refresh cartridge bank mapping in slot 2
				b.RefreshCartridge(2, b.CartB)
				return
			}
		}
	} else {
		// Also support CrossBlaim all-region writes if cartridge slot is selected
		if psl == 1 && b.CartA != nil && b.CartA.MapperType == MapperCrossBlaim {
			if b.CartA.Write(addr, val) {
				b.RefreshCartridge(1, b.CartA)
				return
			}
		} else if psl == 2 && b.CartB != nil && b.CartB.MapperType == MapperCrossBlaim {
			if b.CartB.Write(addr, val) {
				b.RefreshCartridge(2, b.CartB)
				return
			}
		}
	}
}

// In reads a byte from an MSX I/O port.
func (b *MSXBus) In(port uint16) uint8 {
	p := uint8(port & 0xFF)
	if b.OnIORead != nil {
		b.OnIORead(port)
	}
	if b.Debugger != nil && b.Debugger.HasWatch && b.CPU != nil {
		b.Debugger.CheckIO(b.CPU, port, false)
	}

	switch p {
	// PPI 8255
	case 0xA8: // Primary slot status
		return b.Slots.PSLReg
	case 0xA9: // Keyboard data row
		row := b.KeyRow & 0x0F
		return b.KeyMatrix[row]
	case 0xAA: // PPI port C
		return b.KeyRow
	case 0xAB: // PPI control
		return b.PPICtrl

	// RAM Mapper
	case 0xFC, 0xFD, 0xFE, 0xFF:
		if b.Mapper != nil {
			return b.Mapper.ReadPort(p)
		}
		return 0xFF

	// VDP ports
	case 0x98: // VRAM read
		if b.VDP != nil {
			return b.VDP.ReadData()
		}
		return 0xFF
	case 0x99: // VDP status register
		if b.VDP != nil {
			return b.VDP.ReadStatus()
		}
		return 0xFF

	// PSG
	case 0xA2: // PSG data read
		if b.PSG != nil {
			return b.PSG.ReadData()
		}
		return 0xFF

	// RTC
	case 0xB5:
		return b.ReadRTC()

	// Printer status
	case 0x90:
		return 0xFD // Printer ready

	// Brazilian DiskROM I/O ports (Gradiente / Sharp HotBit)
	case 0xD0, 0xD1, 0xD2, 0xD3, 0xD4:
		return 0x00
	}

	return 0xFF
}

// ReadRTC reads the currently selected RTC register matching fMSX RTCIn
func (b *MSXBus) ReadRTC() uint8 {
	reg := b.RTCReg & 0x0F
	bank := b.RTCMode & 0x03

	if reg > 12 {
		if reg == 13 {
			return b.RTCMode
		}
		return 0xFF
	}

	if bank > 0 {
		return b.RTC[bank][reg]
	}

	// Bank 0: Live Clock Time in BCD digits
	now := time.Now()
	switch reg {
	case 0:
		return uint8(now.Second() % 10)
	case 1:
		return uint8(now.Second() / 10)
	case 2:
		return uint8(now.Minute() % 10)
	case 3:
		return uint8(now.Minute() / 10)
	case 4:
		return uint8(now.Hour() % 10)
	case 5:
		return uint8(now.Hour() / 10)
	case 6:
		return uint8(now.Weekday())
	case 7:
		return uint8(now.Day() % 10)
	case 8:
		return uint8(now.Day() / 10)
	case 9:
		return uint8(int(now.Month()) % 10)
	case 10:
		return uint8(int(now.Month()) / 10)
	case 11:
		return uint8((now.Year() % 100) % 10)
	case 12:
		return uint8(((now.Year() % 100) / 10) % 10)
	}
	return 0
}

// Out writes a byte to an MSX I/O port.
func (b *MSXBus) Out(port uint16, val uint8) {
	p := uint8(port & 0xFF)
	if b.OnIOWrite != nil {
		b.OnIOWrite(port, val)
	}
	if b.Debugger != nil && b.Debugger.HasWatch && b.CPU != nil {
		b.Debugger.CheckIO(b.CPU, port, true)
	}

	switch p {
	// PPI 8255
	case 0xA8: // Primary slot selection
		b.Slots.SetPSL(val)
	case 0xAA: // Keyboard row selection
		b.KeyRow = val
	case 0xAB: // PPI control register
		b.PPICtrl = val
		if (val & 0x80) == 0 {
			// Bit Set/Reset operation on Port C (0xAA)
			bit := (val >> 1) & 0x07
			if (val & 0x01) != 0 {
				b.KeyRow |= (1 << bit)
			} else {
				b.KeyRow &^= (1 << bit)
			}
		}

	// RAM Mapper
	case 0xFC, 0xFD, 0xFE, 0xFF:
		if b.Mapper != nil {
			b.Mapper.WritePort(p, val)
			page := int(p - 0xFC)
			// Update the corresponding 16KB page in Slot 3 Subslot 2 and Subslot 0
			b.Slots.Map16K(3, 2, page, b.Mapper.Get16KPage(page), true)
			b.Slots.Map16K(3, 0, page, b.Mapper.Get16KPage(page), true)
		}

	// OPLL (YM2413 / MSX-MUSIC / FM-PAC)
	case 0x7C: // OPLL register latch
		if b.OPLL != nil {
			b.OPLL.WriteAddress(val)
		}
	case 0x7D: // OPLL data write
		if b.OPLL != nil {
			b.OPLL.WriteData(val)
		}

	// PSG
	case 0xA0: // PSG register latch
		if b.PSG != nil {
			b.PSG.WriteControl(val)
		}
	case 0xA1: // PSG data write
		if b.PSG != nil {
			if b.PSG.Latch == 15 && b.Joy != nil {
				b.Joy.OnWriteReg15(val, b.PSG.Regs[15])
			}
			b.PSG.WriteData(val)
		}

	// VDP ports
	case 0x98: // VRAM data write
		if b.VDP != nil {
			b.VDP.WriteData(val)
		}
	case 0x99: // VDP control register
		if b.VDP != nil {
			b.VDP.WriteControl(val)
		}
	case 0x9A: // VDP palette latch
		if b.VDP != nil {
			b.VDP.WritePalette(val)
		}
	case 0x9B: // VDP indirect register access
		if b.VDP != nil {
			b.VDP.WriteRegisterDirect(val)
		}

	// RTC RP5C01
	case 0xB4:
		b.RTCReg = val & 0x0F
	case 0xB5:
		if b.RTCReg < 13 {
			bank := b.RTCMode & 0x03
			b.RTC[bank][b.RTCReg] = val
		} else if b.RTCReg == 13 {
			b.RTCMode = val
		}
	}
}

// RefreshCartridge re-maps the active 8KB banks for a cartridge in slot 1 or 2
func (b *MSXBus) RefreshCartridge(slot int, c *Cartridge) {
	if c == nil {
		return
	}
	// Bank 0 (4000h..5FFFh) -> Page 2 (8K)
	// Bank 1 (6000h..7FFFh) -> Page 3 (8K)
	// Bank 2 (8000h..9FFFh) -> Page 4 (8K)
	// Bank 3 (A000h..BFFFh) -> Page 5 (8K)
	b.Slots.Map8K(slot, 0, 2, c.Get8KBank(0), false)
	b.Slots.Map8K(slot, 0, 3, c.Get8KBank(1), false)
	b.Slots.Map8K(slot, 0, 4, c.Get8KBank(2), false)
	b.Slots.Map8K(slot, 0, 5, c.Get8KBank(3), false)

	if c.MapperType == MapperCrossBlaim {
		b.Slots.Map8K(slot, 0, 0, c.Get8KBankExtra(0), false)
		b.Slots.Map8K(slot, 0, 1, c.Get8KBankExtra(1), false)
		b.Slots.Map8K(slot, 0, 6, c.Get8KBankExtra(6), false)
		b.Slots.Map8K(slot, 0, 7, c.Get8KBankExtra(7), false)
	}
}
