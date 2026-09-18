package msx

import (
	"fmsxgo/pkg/cpu/z80"
	"fmsxgo/pkg/vdp"
)

// MSXBus implements the z80.Bus interface for the MSX architecture.
type MSXBus struct {
	Slots     *SlotBus
	Mapper    *RAMMapper
	CartA     *Cartridge
	CartB     *Cartridge
	VDP       *vdp.VDP

	// PPI 8255 state
	KeyMatrix  [16]uint8 // Keyboard matrix rows 0..15
	KeyRow     uint8     // Current row selected via PPI port C (0xAA)
	PPICtrl    uint8     // PPI control register (0xAB)

	// PSG state stub
	PSGLatch uint8
	PSGRegs  [16]uint8

	// RTC state stub
	RTCReg uint8

	// IO Ports debugging/callbacks
	OnIORead  func(port uint16)
	OnIOWrite func(port uint16, val uint8)
}

// Ensure MSXBus implements z80.Bus
var _ z80.Bus = (*MSXBus)(nil)

// NewMSXBus creates an MSXBus wired with SlotBus, RAMMapper, and VDP.
func NewMSXBus(slots *SlotBus, mapper *RAMMapper, vdpInst *vdp.VDP) *MSXBus {
	bus := &MSXBus{
		Slots:  slots,
		Mapper: mapper,
		VDP:    vdpInst,
	}
	// Default all keyboard matrix rows to 0xFF (no key pressed)
	for i := range bus.KeyMatrix {
		bus.KeyMatrix[i] = 0xFF
	}
	return bus
}

// Read reads a byte from the Z80 16-bit address space.
func (b *MSXBus) Read(addr uint16) uint8 {
	// Secondary slot selector register at 0xFFFF (only if slot in page 3 is expanded)
	if addr == 0xFFFF && b.Slots.IsSubslot[b.Slots.CurPSL[3]] {
		return b.Slots.GetSSL()
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
	}
}

// In reads a byte from an MSX I/O port.
func (b *MSXBus) In(port uint16) uint8 {
	p := uint8(port & 0xFF)
	if b.OnIORead != nil {
		b.OnIORead(port)
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
		if b.PSGLatch < 16 {
			return b.PSGRegs[b.PSGLatch]
		}
		return 0xFF

	// RTC
	case 0xB5:
		return 0x00

	// Printer status
	case 0x90:
		return 0xFD // Printer ready

	// Brazilian DiskROM I/O ports (Gradiente / Sharp HotBit)
	case 0xD0, 0xD1, 0xD2, 0xD3, 0xD4:
		return 0x00
	}

	return 0xFF
}

// Out writes a byte to an MSX I/O port.
func (b *MSXBus) Out(port uint16, val uint8) {
	p := uint8(port & 0xFF)
	if b.OnIOWrite != nil {
		b.OnIOWrite(port, val)
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
			// Update the corresponding 16KB page in Slot 3
			b.Slots.Map16K(3, 0, page, b.Mapper.Get16KPage(page), true)
		}

	// PSG
	case 0xA0: // PSG register latch
		b.PSGLatch = val & 0x0F
	case 0xA1: // PSG data write
		if b.PSGLatch < 16 {
			b.PSGRegs[b.PSGLatch] = val
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

	// RTC
	case 0xB4:
		b.RTCReg = val & 0x0F
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
}
