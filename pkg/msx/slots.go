package msx

import (
	"fmt"
)

// Slot constants
const (
	MaxSlots    = 4
	MaxSubslots = 4
	PageSize8K  = 0x2000
	PageSize16K = 0x4000
)

// SlotBus manages primary and secondary slot memory mappings for the MSX system.
type SlotBus struct {
	// MemMap[pslot][sslot][page8k] points to the 8KB slice of data
	MemMap [MaxSlots][MaxSubslots][8][]byte

	// IsRAM tracks whether an 8KB bank is RAM (writable) or ROM
	IsRAM [MaxSlots][MaxSubslots][8]bool

	// Active 8KB pages mapped into the Z80 64KB address space
	RAM [8][]byte

	// EnWrite indicates whether writing to a 16KB page is enabled (i.e. currently mapped to RAM)
	EnWrite [4]bool

	// Slot state registers
	PSLReg    uint8    // Primary slot select register (I/O 0xA8)
	SSLReg    [4]uint8 // Secondary slot select registers (per primary slot, read/written at 0xFFFF)
	IsSubslot [4]bool  // True if primary slot has expanded secondary slots

	// Current primary and secondary slot active in each 16KB page
	CurPSL [4]uint8
	CurSSL [4]uint8

	// Empty page for unmapped areas (returns 0xFF)
	EmptyPage []byte
}

// NewSlotBus initializes an empty slot bus.
func NewSlotBus() *SlotBus {
	sb := &SlotBus{
		EmptyPage: make([]byte, PageSize8K),
	}
	for i := range sb.EmptyPage {
		sb.EmptyPage[i] = 0xFF
	}

	// Initialize all slot pages to EmptyPage
	for p := 0; p < MaxSlots; p++ {
		for s := 0; s < MaxSubslots; s++ {
			for page := 0; page < 8; page++ {
				sb.MemMap[p][s][page] = sb.EmptyPage
				sb.IsRAM[p][s][page] = false
			}
		}
	}

	// By default, expand slot 3 (standard MSX expanded slot)
	sb.IsSubslot[3] = true

	// Default primary and secondary slot registers
	sb.SetPSL(0x00) // All pages to slot 0 initially
	return sb
}

// SetPSL updates the primary slot register (I/O 0xA8)
func (sb *SlotBus) SetPSL(val uint8) {
	sb.PSLReg = val
	for page := 0; page < 4; page++ {
		slot := (val >> (page * 2)) & 0x03
		sb.CurPSL[page] = slot
		if sb.IsSubslot[slot] {
			subslot := (sb.SSLReg[slot] >> (page * 2)) & 0x03
			sb.CurSSL[page] = subslot
		} else {
			sb.CurSSL[page] = 0
		}
	}
	sb.updateActiveRAM()
}

// SetSSL updates the secondary slot register for the current primary slot in Page 3 (Memory 0xFFFF)
func (sb *SlotBus) SetSSL(val uint8) {
	psl := sb.CurPSL[3]
	if !sb.IsSubslot[psl] {
		return
	}
	sb.SSLReg[psl] = val
	for page := 0; page < 4; page++ {
		if sb.CurPSL[page] == psl {
			subslot := (val >> (page * 2)) & 0x03
			sb.CurSSL[page] = subslot
		}
	}
	sb.updateActiveRAM()
}

// GetSSL reads the secondary slot register for the current primary slot in Page 3
func (sb *SlotBus) GetSSL() uint8 {
	psl := sb.CurPSL[3]
	if !sb.IsSubslot[psl] {
		return 0xFF
	}
	// MSX standard: reading from 0xFFFF returns inverted subslot register
	return ^sb.SSLReg[psl]
}

// Map8K maps an 8KB memory slice into a specific slot, subslot, and 8KB page (0..7)
func (sb *SlotBus) Map8K(slot, subslot, page int, data []byte, isRAM bool) {
	if slot < 0 || slot >= MaxSlots || subslot < 0 || subslot >= MaxSubslots || page < 0 || page >= 8 {
		return
	}
	if data == nil {
		data = sb.EmptyPage
		isRAM = false
	}
	sb.MemMap[slot][subslot][page] = data
	sb.IsRAM[slot][subslot][page] = isRAM
	sb.updateActiveRAM()
}

// Map16K maps a 16KB memory slice into a specific slot, subslot, and 16KB page (0..3)
func (sb *SlotBus) Map16K(slot, subslot, page16 int, data []byte, isRAM bool) {
	if len(data) < PageSize16K {
		return
	}
	sb.Map8K(slot, subslot, page16*2, data[:PageSize8K], isRAM)
	sb.Map8K(slot, subslot, page16*2+1, data[PageSize8K:PageSize16K], isRAM)
}

// updateActiveRAM updates the 8 active pointers pointing to the Z80 address space
func (sb *SlotBus) updateActiveRAM() {
	for page16 := 0; page16 < 4; page16++ {
		psl := sb.CurPSL[page16]
		ssl := sb.CurSSL[page16]

		p8_1 := page16 * 2
		p8_2 := page16*2 + 1

		sb.RAM[p8_1] = sb.MemMap[psl][ssl][p8_1]
		sb.RAM[p8_2] = sb.MemMap[psl][ssl][p8_2]
		sb.EnWrite[page16] = sb.IsRAM[psl][ssl][p8_1] || sb.IsRAM[psl][ssl][p8_2]
	}
}

// FormatSlotState returns a human-readable description of current slot allocations
func (sb *SlotBus) FormatSlotState() string {
	var s string
	s += fmt.Sprintf("Primary Slot Reg (A8h): %02Xh\n", sb.PSLReg)
	for i := 0; i < 4; i++ {
		if sb.IsSubslot[i] {
			s += fmt.Sprintf("Slot %d (Expanded): SSLReg = %02Xh\n", i, sb.SSLReg[i])
		} else {
			s += fmt.Sprintf("Slot %d: Standard\n", i)
		}
	}
	s += "\n--- Active Page Mapping in CPU Address Space ---\n"
	for p16 := 0; p16 < 4; p16++ {
		start := p16 * 0x4000
		end := start + 0x3FFF
		psl := sb.CurPSL[p16]
		ssl := sb.CurSSL[p16]
		writeStr := "ROM (Read-only)"
		if sb.EnWrite[p16] {
			writeStr = "RAM (Read/Write)"
		}
		s += fmt.Sprintf("Page %d [%04Xh - %04Xh]: Slot %d-%d | %s\n", p16, start, end, psl, ssl, writeStr)
	}
	return s
}
