package msx

import (
	"encoding/binary"
	"fmt"
	"os"

	"fmsxgo/pkg/vdp"
)

const (
	// STAMagic identifies fMSX state files: "STE\032\003"
	STAMagic = "STE\x1A\x03"
	// STAHeaderSize is 16 bytes
	STAHeaderSize = 16
)

// ComputeStateID calculates the 16-bit checksum used by fMSX to identify .STA files.
// Faithful 1:1 match to fMSX MSX.c StateID().
func (m *Machine) ComputeStateID() uint16 {
	var id uint16

	// 1. Cartridge ROMs
	if m.Bus.CartA != nil && len(m.Bus.CartA.Data) > 0 {
		for j, b := range m.Bus.CartA.Data {
			id += uint16(0 ^ b) + uint16(j&0)
		}
	}
	if m.Bus.CartB != nil && len(m.Bus.CartB.Data) > 0 {
		for j, b := range m.Bus.CartB.Data {
			id += uint16(1 ^ b) + uint16(j&0)
		}
	}

	// 2. Main BIOS & BASIC (Slot 0, Subslot 0, 32KB: Pages 0 & 1)
	for p := 0; p < 4; p++ {
		pageSlice := m.Slots.MemMap[0][0][p]
		if pageSlice != nil && len(pageSlice) == PageSize8K {
			for _, b := range pageSlice {
				id += uint16(b)
			}
		}
	}

	// 3. SubROM (Slot 3, Subslot 1, 16KB: Page 0 / 8KB pages 0 & 1)
	for p := 0; p < 2; p++ {
		subSlice := m.Slots.MemMap[3][1][p]
		if subSlice != nil && len(subSlice) == PageSize8K {
			for _, b := range subSlice {
				id += uint16(b)
			}
		}
	}

	// 4. DiskROM (Slot 3, Subslot 1, 16KB: Page 1 / 8KB pages 2 & 3)
	for p := 2; p < 4; p++ {
		diskSlice := m.Slots.MemMap[3][1][p]
		if diskSlice != nil && len(diskSlice) == PageSize8K {
			for _, b := range diskSlice {
				id += uint16(b)
			}
		}
	}

	return id
}

// SaveState serializes the entire emulation state into a byte buffer matching fMSX State.h.
func (m *Machine) SaveState() ([]byte, error) {
	ramPages := m.Config.RAMPages
	vramPages := m.Config.VRAMPages

	// Structure sizes matching 32-bit fMSX State.h:
	// CPU: 52 bytes
	// PPI: 10 bytes
	// VDP: 64 bytes
	// VDPStatus: 16 bytes
	// Palette: 64 bytes (16 x uint32)
	// PSG: 88 bytes
	// OPLL: 156 bytes
	// SCChip: 304 bytes
	// State: 1024 bytes (256 x uint32)
	// RAM: ramPages * 16384 bytes
	// VRAM: vramPages * 16384 bytes
	payloadSize := 52 + 10 + 64 + 16 + 64 + 88 + 156 + 304 + 1024 + (ramPages * 16384) + (vramPages * 16384)
	buf := make([]byte, payloadSize)
	offset := 0

	// 1. Z80 CPU (52 bytes)
	cpu := m.CPU
	binary.LittleEndian.PutUint16(buf[offset+0:offset+2], cpu.AF())
	binary.LittleEndian.PutUint16(buf[offset+2:offset+4], cpu.BC())
	binary.LittleEndian.PutUint16(buf[offset+4:offset+6], cpu.DE())
	binary.LittleEndian.PutUint16(buf[offset+6:offset+8], cpu.HL())
	binary.LittleEndian.PutUint16(buf[offset+8:offset+10], cpu.IX)
	binary.LittleEndian.PutUint16(buf[offset+10:offset+12], cpu.IY)
	binary.LittleEndian.PutUint16(buf[offset+12:offset+14], cpu.PC)
	binary.LittleEndian.PutUint16(buf[offset+14:offset+16], cpu.SP)

	binary.LittleEndian.PutUint16(buf[offset+16:offset+18], (uint16(cpu.A1)<<8)|uint16(cpu.F1))
	binary.LittleEndian.PutUint16(buf[offset+18:offset+20], (uint16(cpu.B1)<<8)|uint16(cpu.C1))
	binary.LittleEndian.PutUint16(buf[offset+20:offset+22], (uint16(cpu.D1)<<8)|uint16(cpu.E1))
	binary.LittleEndian.PutUint16(buf[offset+22:offset+24], (uint16(cpu.H1)<<8)|uint16(cpu.L1))

	iff := byte(0)
	if cpu.IFF1 {
		iff |= 0x01
	}
	if cpu.IFF2 {
		iff |= 0x08
	}
	if cpu.IM == 1 {
		iff |= 0x02
	} else if cpu.IM == 2 {
		iff |= 0x04
	}
	if cpu.Halted {
		iff |= 0x80
	}
	buf[offset+24] = iff
	buf[offset+25] = cpu.I
	buf[offset+26] = cpu.R
	buf[offset+27] = 0 // padding

	// IPeriod, ICount, IBackup
	binary.LittleEndian.PutUint32(buf[offset+28:offset+32], 0)
	binary.LittleEndian.PutUint32(buf[offset+32:offset+36], 0)
	binary.LittleEndian.PutUint32(buf[offset+36:offset+40], 0)

	// IRequest, IAutoReset, TrapBadOps, Trap, Trace, padding, User
	binary.LittleEndian.PutUint16(buf[offset+40:offset+42], 0)
	buf[offset+42] = 0
	buf[offset+43] = 0
	binary.LittleEndian.PutUint16(buf[offset+44:offset+46], 0xFFFF)
	buf[offset+46] = 0
	buf[offset+47] = 0
	binary.LittleEndian.PutUint32(buf[offset+48:offset+52], 0)
	offset += 52

	// 2. PPI 8255 (10 bytes)
	buf[offset+0] = m.Slots.PSLReg
	buf[offset+1] = 0
	buf[offset+2] = m.Bus.KeyRow
	buf[offset+3] = m.Bus.PPICtrl
	buf[offset+4] = m.Slots.PSLReg
	buf[offset+5] = 0
	buf[offset+6] = m.Bus.KeyRow
	buf[offset+7] = 0xFF
	buf[offset+8] = 0xFF
	buf[offset+9] = 0xFF
	offset += 10

	// 3. VDP Registers (64 bytes)
	if m.VDP != nil {
		copy(buf[offset:offset+64], m.VDP.Regs[:])
	}
	offset += 64

	// 4. VDP Status (16 bytes)
	if m.VDP != nil {
		copy(buf[offset:offset+16], m.VDP.Status[:])
	}
	offset += 16

	// 5. Palette (16 x uint32 = 64 bytes)
	if m.VDP != nil && m.VDP.Palette != nil {
		for i := 0; i < 16; i++ {
			c := m.VDP.Palette.Colors[i]
			// Format in fMSX: 0x00RRGGBB
			rgbVal := (uint32(c.R) << 16) | (uint32(c.G) << 8) | uint32(c.B)
			binary.LittleEndian.PutUint32(buf[offset+(i*4):offset+(i*4)+4], rgbVal)
		}
	}
	offset += 64

	// 6. PSG AY-3-8910 (88 bytes)
	if m.PSG != nil {
		copy(buf[offset:offset+16], m.PSG.Regs[:])
		buf[offset+74] = m.PSG.Latch
	}
	offset += 88

	// 7. OPLL YM2413 (156 bytes)
	if m.OPLL != nil {
		copy(buf[offset:offset+64], m.OPLL.Regs[:])
		for ch := 0; ch < 9; ch++ {
			binary.LittleEndian.PutUint32(buf[offset+64+(ch*4):offset+68+(ch*4)], uint32(m.OPLL.FreqCache[ch]))
			binary.LittleEndian.PutUint32(buf[offset+100+(ch*4):offset+104+(ch*4)], uint32(m.OPLL.VolCache[ch]))
		}
		buf[offset+153] = m.OPLL.Latch
	}
	offset += 156

	// 8. SCC (304 bytes)
	if m.SCC != nil {
		copy(buf[offset:offset+256], m.SCC.Regs[:])
	}
	offset += 304

	// 9. Hardware State[256] array (1024 bytes)
	state := make([]uint32, 256)
	j := 0
	if m.VDP != nil {
		if len(m.VDP.VRAM) > 0 {
			state[j] = uint32(m.VDP.VRAM[int(m.VDP.VAddr)%len(m.VDP.VRAM)])
		}
		j++
		state[j] = uint32(m.VDP.PLatch)
		j++
		state[j] = uint32(m.VDP.ALatch)
		j++
		state[j] = uint32(m.VDP.VAddr)
		j++
		vkey := uint32(0)
		if m.VDP.VKey {
			vkey = 1
		}
		state[j] = vkey
		j++
		pkey := uint32(0)
		if m.VDP.PKey {
			pkey = 1
		}
		state[j] = pkey
		j++
		j++ // was WKey
		state[j] = uint32(m.VDP.IRQPending)
		j++
		state[j] = uint32(m.VDP.ScanLine)
		j++
	} else {
		j += 9
	}

	state[j] = uint32(m.Bus.RTCReg)
	j++
	state[j] = uint32(m.Bus.RTCMode)
	j++
	state[j] = 0 // KanLetter
	j++
	state[j] = 0 // KanCount
	j++
	state[j] = uint32(m.Bus.KeyRow) // IOReg
	j++
	state[j] = uint32(m.Slots.PSLReg) // PSLReg
	j++
	state[j] = 0 // FMPACKey
	j++

	// Memory setup (I=0..3)
	for i := 0; i < 4; i++ {
		state[j] = uint32(m.Slots.SSLReg[i])
		j++
		state[j] = uint32(m.Slots.CurPSL[i])
		j++
		state[j] = uint32(m.Slots.CurSSL[i])
		j++
		enW := uint32(0)
		if m.Slots.IsRAM[m.Slots.CurPSL[i]][m.Slots.CurSSL[i]][i*2] {
			enW = 1
		}
		state[j] = enW
		j++
		state[j] = uint32(m.Mapper.Regs[i])
		j++
	}

	// Cartridge setup (Slots 0..1 in state array)
	if m.Bus.CartA != nil {
		state[j] = uint32(m.Bus.CartA.MapperType)
		j++
		for k := 0; k < 4; k++ {
			state[j] = uint32(m.Bus.CartA.Banks[k])
			j++
		}
	} else {
		j += 5
	}
	if m.Bus.CartB != nil {
		state[j] = uint32(m.Bus.CartB.MapperType)
		j++
		for k := 0; k < 4; k++ {
			state[j] = uint32(m.Bus.CartB.Banks[k])
			j++
		}
	} else {
		j += 5
	}

	for i := 0; i < 256; i++ {
		binary.LittleEndian.PutUint32(buf[offset+(i*4):offset+(i*4)+4], state[i])
	}
	offset += 1024

	// 10. RAM Data (ramPages * 16384 bytes)
	ramBytes := ramPages * 16384
	if len(m.Mapper.RAMData) >= ramBytes {
		copy(buf[offset:offset+ramBytes], m.Mapper.RAMData[:ramBytes])
	}
	offset += ramBytes

	// 11. VRAM (vramPages * 16384 bytes)
	vramBytes := vramPages * 16384
	if m.VDP != nil && len(m.VDP.VRAM) >= vramBytes {
		copy(buf[offset:offset+vramBytes], m.VDP.VRAM[:vramBytes])
	}
	offset += vramBytes

	return buf, nil
}

// LoadState deserializes and restores the entire machine state from a buffer.
func (m *Machine) LoadState(buf []byte) error {
	ramPages := m.Config.RAMPages
	vramPages := m.Config.VRAMPages

	minSize := 52 + 10 + 64 + 16 + 64 + 88 + 156 + 304 + 1024 + (ramPages * 16384) + (vramPages * 16384)
	if len(buf) < minSize {
		return fmt.Errorf("state buffer size too small: expected %d, got %d", minSize, len(buf))
	}

	offset := 0

	// 1. Z80 CPU (52 bytes)
	cpu := m.CPU
	cpu.SetAF(binary.LittleEndian.Uint16(buf[offset+0 : offset+2]))
	cpu.SetBC(binary.LittleEndian.Uint16(buf[offset+2 : offset+4]))
	cpu.SetDE(binary.LittleEndian.Uint16(buf[offset+4 : offset+6]))
	cpu.SetHL(binary.LittleEndian.Uint16(buf[offset+6 : offset+8]))
	cpu.IX = binary.LittleEndian.Uint16(buf[offset+8 : offset+10])
	cpu.IY = binary.LittleEndian.Uint16(buf[offset+10 : offset+12])
	cpu.PC = binary.LittleEndian.Uint16(buf[offset+12 : offset+14])
	cpu.SP = binary.LittleEndian.Uint16(buf[offset+14 : offset+16])

	af1 := binary.LittleEndian.Uint16(buf[offset+16 : offset+18])
	cpu.A1 = uint8(af1 >> 8)
	cpu.F1 = uint8(af1)

	bc1 := binary.LittleEndian.Uint16(buf[offset+18 : offset+20])
	cpu.B1 = uint8(bc1 >> 8)
	cpu.C1 = uint8(bc1)

	de1 := binary.LittleEndian.Uint16(buf[offset+20 : offset+22])
	cpu.D1 = uint8(de1 >> 8)
	cpu.E1 = uint8(de1)

	hl1 := binary.LittleEndian.Uint16(buf[offset+22 : offset+24])
	cpu.H1 = uint8(hl1 >> 8)
	cpu.L1 = uint8(hl1)

	iff := buf[offset+24]
	cpu.IFF1 = (iff & 0x01) != 0
	cpu.IFF2 = (iff & 0x08) != 0
	if (iff & 0x04) != 0 {
		cpu.IM = 2
	} else if (iff & 0x02) != 0 {
		cpu.IM = 1
	} else {
		cpu.IM = 0
	}
	cpu.Halted = (iff & 0x80) != 0
	cpu.I = buf[offset+25]
	cpu.R = buf[offset+26]
	offset += 52

	// 2. PPI 8255 (10 bytes)
	m.Bus.KeyRow = buf[offset+2]
	m.Bus.PPICtrl = buf[offset+3]
	offset += 10

	// 3. VDP Registers (64 bytes)
	if m.VDP != nil {
		copy(m.VDP.Regs[:], buf[offset:offset+64])
	}
	offset += 64

	// 4. VDP Status (16 bytes)
	if m.VDP != nil {
		copy(m.VDP.Status[:], buf[offset:offset+16])
	}
	offset += 16

	// 5. Palette (16 x uint32 = 64 bytes)
	if m.VDP != nil && m.VDP.Palette != nil {
		for i := 0; i < 16; i++ {
			rgbVal := binary.LittleEndian.Uint32(buf[offset+(i*4) : offset+(i*4)+4])
			r := uint8((rgbVal >> 16) & 0xFF)
			g := uint8((rgbVal >> 8) & 0xFF)
			b := uint8(rgbVal & 0xFF)
			m.VDP.Palette.Colors[i] = vdp.RGBA{R: r, G: g, B: b, A: 0xFF}
		}
	}
	offset += 64

	// 6. PSG AY-3-8910 (88 bytes)
	if m.PSG != nil {
		for r := uint8(0); r < 16; r++ {
			m.PSG.Write(r, buf[offset+int(r)])
		}
		m.PSG.Latch = buf[offset+74]
	}
	offset += 88

	// 7. OPLL YM2413 (156 bytes)
	if m.OPLL != nil {
		for r := 0; r < 64; r++ {
			m.OPLL.Write(uint8(r), buf[offset+r])
		}
		m.OPLL.WriteAddress(buf[offset+153])
	}
	offset += 156

	// 8. SCC (304 bytes)
	if m.SCC != nil {
		for r := 0; r < 256; r++ {
			m.SCC.Write(uint8(r), buf[offset+r])
		}
	}
	offset += 304

	// 9. Hardware State[256] array (1024 bytes)
	state := make([]uint32, 256)
	for i := 0; i < 256; i++ {
		state[i] = binary.LittleEndian.Uint32(buf[offset+(i*4) : offset+(i*4)+4])
	}
	offset += 1024

	j := 0
	if m.VDP != nil {
		j++ // VDPData
		m.VDP.PLatch = uint8(state[j])
		j++
		m.VDP.ALatch = uint8(state[j])
		j++
		m.VDP.VAddr = uint16(state[j])
		j++
		m.VDP.VKey = (state[j] != 0)
		j++
		m.VDP.PKey = (state[j] != 0)
		j++
		j++ // was WKey
		m.VDP.IRQPending = uint8(state[j])
		j++
		m.VDP.ScanLine = int(state[j])
		j++
	} else {
		j += 9
	}

	m.Bus.RTCReg = uint8(state[j])
	j++
	m.Bus.RTCMode = uint8(state[j])
	j++
	j++ // KanLetter
	j++ // KanCount
	m.Bus.KeyRow = uint8(state[j]) // IOReg
	j++
	pslReg := uint8(state[j]) // PSLReg
	j++
	j++ // FMPACKey

	// Memory setup (I=0..3)
	sslRegs := [4]uint8{}
	psl := [4]uint8{}
	ssl := [4]uint8{}
	for i := 0; i < 4; i++ {
		sslRegs[i] = uint8(state[j])
		j++
		psl[i] = uint8(state[j])
		j++
		ssl[i] = uint8(state[j])
		j++
		j++ // EnWrite
		m.Mapper.Regs[i] = uint8(state[j])
		j++
	}

	// Cartridge setup
	if m.Bus.CartA != nil {
		j++ // ROMType
		for k := 0; k < 4; k++ {
			bank := int(state[j])
			j++
			m.Bus.CartA.Banks[k] = bank
		}
		m.Bus.RefreshCartridge(1, m.Bus.CartA)
	} else {
		j += 5
	}
	if m.Bus.CartB != nil {
		j++ // ROMType
		for k := 0; k < 4; k++ {
			bank := int(state[j])
			j++
			m.Bus.CartB.Banks[k] = bank
		}
		m.Bus.RefreshCartridge(2, m.Bus.CartB)
	} else {
		j += 5
	}

	// Restore PSL, SSL, RAM Mapper
	m.Slots.SetPSL(pslReg)
	for i := 0; i < 4; i++ {
		m.Slots.SSLReg[i] = sslRegs[i]
		m.Slots.CurPSL[i] = psl[i]
		m.Slots.CurSSL[i] = ssl[i]
		m.Slots.Map16K(3, 2, i, m.Mapper.Get16KPage(i), true)
		m.Slots.Map16K(3, 0, i, m.Mapper.Get16KPage(i), true)
	}

	// 10. RAM Data
	ramBytes := ramPages * 16384
	copy(m.Mapper.RAMData[:ramBytes], buf[offset:offset+ramBytes])
	offset += ramBytes

	// 11. VRAM
	vramBytes := vramPages * 16384
	if m.VDP != nil {
		copy(m.VDP.VRAM[:vramBytes], buf[offset:offset+vramBytes])
		m.VDP.SetScreen()
	}
	offset += vramBytes

	return nil
}

// SaveSTA saves the complete emulation state into a .STA file compatible with fMSX.
func (m *Machine) SaveSTA(filename string) error {
	data, err := m.SaveState()
	if err != nil {
		return fmt.Errorf("failed to serialize state: %w", err)
	}

	header := make([]byte, STAHeaderSize)
	copy(header[:5], STAMagic)
	header[5] = byte(m.Config.RAMPages)
	header[6] = byte(m.Config.VRAMPages)

	stateID := m.ComputeStateID()
	binary.LittleEndian.PutUint16(header[7:9], stateID)

	fileData := append(header, data...)
	if err := os.WriteFile(filename, fileData, 0644); err != nil {
		return fmt.Errorf("failed to write state file %q: %w", filename, err)
	}

	return nil
}

// LoadSTA loads and restores emulation state from a .STA file compatible with fMSX.
func (m *Machine) LoadSTA(filename string) error {
	fileData, err := os.ReadFile(filename)
	if err != nil {
		return fmt.Errorf("failed to read state file %q: %w", filename, err)
	}

	if len(fileData) < STAHeaderSize {
		return fmt.Errorf("state file %q is too short (header missing)", filename)
	}

	if string(fileData[:5]) != STAMagic {
		return fmt.Errorf("file %q is not a valid fMSX state snapshot (invalid magic)", filename)
	}

	fileRAMPages := int(fileData[5])
	fileVRAMPages := int(fileData[6])
	if fileRAMPages != m.Config.RAMPages || fileVRAMPages != m.Config.VRAMPages {
		return fmt.Errorf("hardware configuration mismatch: file requires %d RAM/%d VRAM pages, current machine has %d/%d",
			fileRAMPages, fileVRAMPages, m.Config.RAMPages, m.Config.VRAMPages)
	}

	return m.LoadState(fileData[STAHeaderSize:])
}
