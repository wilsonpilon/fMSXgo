package msx

import (
	"bytes"
	"fmt"
	"os"

	"fmsxgo/pkg/cpu/z80"
)

// Places in BIOS to be patched with ED FE C9 (identical to fMSX MSX.c)
var BIOSPatches = []uint16{
	0x00E1, // TAPION: Open for read tape and read header
	0x00E4, // TAPIN:  Read byte from tape
	0x00E7, // TAPIOF: Stop tape read
	0x00EA, // TAPOON: Open for write tape and write header
	0x00ED, // TAPOUT: Write byte to tape
	0x00F0, // TAPOOF: Stop tape write
	0x00F3, // STMOTR: Set tape motor on/off
}

// Places in DiskROM to be patched with ED FE C9 (identical to fMSX MSX.c)
var DiskPatches = []uint16{
	0x4010, // PHYDIO: Read/write sectors to disk
	0x4013, // DSKCHG: Check if disk was changed
	0x4016, // GETDPB: Get Drive Parameter Block
	0x401C, // DSKFMT: Disk format
	0x401F, // DRVOFF: Stop drive motor
}

// FloppyDrive represents a virtual MSX floppy disk drive (A: or B:)
type FloppyDrive struct {
	ID          int
	Path        string
	Data        []byte
	SecSize     int
	Sectors     int
	Modified    bool
	Tracks      int
	Sides       int
	SecPerTrack int
	MediaID     uint8
	FormatDesc  string
	DiskType    string
}

// TapeDrive represents a virtual cassette tape drive
type TapeDrive struct {
	Path string
	Data []byte
	Pos  int
}

// Standard disk format info matching fMSX Info[8]
type DiskFormatInfo struct {
	Sectors    int
	Heads      uint8
	Names      uint8
	PerTrack   uint8
	PerFAT     uint8
	PerCluster uint8
}

var DiskFormats = [8]DiskFormatInfo{
	{Sectors: 720, Heads: 1, Names: 112, PerTrack: 9, PerFAT: 2, PerCluster: 2},  // 360KB single-sided
	{Sectors: 1440, Heads: 2, Names: 112, PerTrack: 9, PerFAT: 3, PerCluster: 2}, // 720KB double-sided
	{Sectors: 640, Heads: 1, Names: 112, PerTrack: 8, PerFAT: 1, PerCluster: 2},
	{Sectors: 1280, Heads: 2, Names: 112, PerTrack: 8, PerFAT: 2, PerCluster: 2},
	{Sectors: 360, Heads: 1, Names: 64, PerTrack: 9, PerFAT: 2, PerCluster: 1},
	{Sectors: 720, Heads: 2, Names: 112, PerTrack: 9, PerFAT: 2, PerCluster: 2},
	{Sectors: 320, Heads: 1, Names: 64, PerTrack: 8, PerFAT: 1, PerCluster: 1},
	{Sectors: 640, Heads: 2, Names: 112, PerTrack: 8, PerFAT: 1, PerCluster: 2},
}

// TapeHeader sequence matching fMSX TapeHeader[8]
var TapeHeader = []byte{0x1F, 0xA6, 0xDE, 0xBA, 0xCC, 0x13, 0x7D, 0x74}

// BootBlock template matching fMSX Boot.h (512-byte MSX boot sector)
var BootBlock = []byte{
	0xEB, 0xFE, 0x90, 0x56, 0x46, 0x42, 0x2D, 0x31, 0x39, 0x38, 0x39, 0x00, 0x02, 0x02, 0x01, 0x00,
	0x02, 0x70, 0x00, 0xA0, 0x05, 0xF9, 0x03, 0x00, 0x09, 0x00, 0x02, 0x00, 0x00, 0x00, 0xD0, 0xED,
	0x53, 0x58, 0xC0, 0x32, 0xC2, 0xC0, 0x36, 0x55, 0x23, 0x36, 0xC0, 0x31, 0x1F, 0xF5, 0x11, 0x9D,
	0xC0, 0x0E, 0x0F, 0xCD, 0x7D, 0xF3, 0x3C, 0x28, 0x28, 0x11, 0x00, 0x01, 0x0E, 0x1A, 0xCD, 0x7D,
	0xF3, 0x21, 0x01, 0x00, 0x22, 0xAB, 0xC0, 0x21, 0x00, 0x3F, 0x11, 0x9D, 0xC0, 0x0E, 0x27, 0xCD,
	0x7D, 0xF3, 0xC3, 0x00, 0x01, 0x57, 0xC0, 0xCD, 0x00, 0x00, 0x79, 0xE6, 0xFE, 0xFE, 0x02, 0x20,
	0x07, 0x3A, 0xC2, 0xC0, 0xA7, 0xCA, 0x22, 0x40, 0x11, 0x77, 0xC0, 0x0E, 0x09, 0xCD, 0x7D, 0xF3,
	0x0E, 0x07, 0xCD, 0x7D, 0xF3, 0x18, 0xB4, 0x42, 0x6F, 0x6F, 0x74, 0x20, 0x65, 0x72, 0x72, 0x6F,
	0x72, 0x0D, 0x0A, 0x50, 0x72, 0x65, 0x73, 0x73, 0x20, 0x61, 0x6E, 0x79, 0x20, 0x6B, 0x65, 0x79,
	0x20, 0x66, 0x6F, 0x72, 0x20, 0x72, 0x65, 0x74, 0x72, 0x79, 0x0D, 0x0A, 0x24, 0x00, 0x4D, 0x53,
	0x58, 0x44, 0x4F, 0x53, 0x20, 0x20, 0x53, 0x59, 0x53, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF3, 0x2A,
	0x51, 0xF3, 0x11, 0x00, 0x01, 0x19, 0x01, 0x00, 0x01, 0x11, 0x00, 0xC1, 0xED, 0xB0, 0x3A, 0xEE,
	0xC0, 0x47, 0x11, 0xEF, 0xC0, 0x21, 0x00, 0x00, 0xCD, 0x51, 0x52, 0xF3, 0x76, 0xC9, 0x18, 0x64,
	0x3A, 0xAF, 0x80,0xF9, 0xCA, 0x6D, 0x48, 0xD3, 0xA5, 0x0C, 0x8C, 0x2F, 0x9C, 0xCB, 0xE9, 0x89,
	0xD2, 0x00, 0x32, 0x26, 0x40, 0x94, 0x61, 0x19, 0x20, 0xE6, 0x80, 0x6D, 0x8A, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
}

// ApplyBIOSPatches installs ED FE C9 into the BIOS image at official hook vectors.
func ApplyBIOSPatches(bios []byte) []byte {
	out := make([]byte, len(bios))
	copy(out, bios)
	for _, addr := range BIOSPatches {
		if int(addr)+3 <= len(out) {
			out[addr] = 0xED
			out[addr+1] = 0xFE
			out[addr+2] = 0xC9
		}
	}
	return out
}

// ApplyDiskPatches installs ED FE C9 into the DiskROM image at official BDOS hook vectors.
func ApplyDiskPatches(diskROM []byte) []byte {
	out := make([]byte, len(diskROM))
	copy(out, diskROM)
	for _, addr := range DiskPatches {
		offset := int(addr) - 0x4000
		if offset >= 0 && offset+3 <= len(out) {
			out[offset] = 0xED
			out[offset+1] = 0xFE
			out[offset+2] = 0xC9
		}
	}
	return out
}

// DiskPresent returns true if a valid disk image is mounted in drive id (0=A:, 1=B:)
func (m *Machine) DiskPresent(id int) bool {
	return id >= 0 && id < 2 && m.FDD[id] != nil && len(m.FDD[id].Data) > 0
}

// DiskRead reads a 512-byte sector from the specified floppy drive.
func (m *Machine) DiskRead(id int, sector int) ([]byte, error) {
	if !m.DiskPresent(id) {
		return nil, fmt.Errorf("drive %d not ready", id)
	}
	secSize := m.FDD[id].SecSize
	if secSize <= 0 {
		secSize = 512
	}
	offset := sector * secSize
	if offset < 0 || offset+secSize > len(m.FDD[id].Data) {
		return nil, fmt.Errorf("sector %d out of bounds", sector)
	}
	return m.FDD[id].Data[offset : offset+secSize], nil
}

// DiskWrite writes a 512-byte sector to the specified floppy drive.
func (m *Machine) DiskWrite(id int, sector int, buf []byte) error {
	if !m.DiskPresent(id) {
		return fmt.Errorf("drive %d not ready", id)
	}
	secSize := m.FDD[id].SecSize
	if secSize <= 0 {
		secSize = 512
	}
	offset := sector * secSize
	if offset < 0 || offset+len(buf) > len(m.FDD[id].Data) {
		return fmt.Errorf("sector %d out of bounds", sector)
	}
	copy(m.FDD[id].Data[offset:], buf)
	m.FDD[id].Modified = true
	return nil
}

// LoadDisk loads a .DSK image from disk into virtual drive 0 (A:) or 1 (B:).
func (m *Machine) LoadDisk(drive int, path string) error {
	if drive < 0 || drive >= 2 {
		return fmt.Errorf("invalid drive ID: %d", drive)
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("failed to read disk image %q: %w", path, err)
	}
	secSize := 512
	sectors := len(data) / secSize
	tracks, sides, secPerTrack, mediaID, formatDesc, diskType := DetectDiskGeometry(data)

	m.FDD[drive] = &FloppyDrive{
		ID:          drive,
		Path:        path,
		Data:        data,
		SecSize:     secSize,
		Sectors:     sectors,
		Tracks:      tracks,
		Sides:       sides,
		SecPerTrack: secPerTrack,
		MediaID:     mediaID,
		FormatDesc:  formatDesc,
		DiskType:    diskType,
	}
	if drive == 0 {
		m.Config.DiskAPath = path
	} else {
		m.Config.DiskBPath = path
	}
	if m.FDC != nil {
		m.FDC.Disk[drive] = m.FDD[drive]
	}
	return nil
}

// EjectDisk removes any loaded disk image from virtual drive 0 (A:) or 1 (B:).
func (m *Machine) EjectDisk(drive int) {
	if drive >= 0 && drive < 2 {
		m.FDD[drive] = &FloppyDrive{ID: drive, SecSize: 512}
		if drive == 0 {
			m.Config.DiskAPath = ""
		} else {
			m.Config.DiskBPath = ""
		}
		if m.FDC != nil {
			m.FDC.Disk[drive] = m.FDD[drive]
		}
	}
}

// DetectDiskGeometry analyzes disk image data (boot sector or size) and returns disk geometry:
// tracks, sides (heads), sectors per track, media ID, short description, and full type description.
// Accurately recognizes 180KB, 360KB, 720KB, 640KB, 320KB, 160KB, 5 1/4" and 3 1/2",
// single/double sided (simples/dupla face), and single/double density (simples/dupla densidade).
func DetectDiskGeometry(data []byte) (tracks, sides, secPerTrack int, mediaID uint8, formatDesc, diskType string) {
	if len(data) >= 512 {
		mediaID = data[0x15]
	}

	switch mediaID {
	case 0xF8:
		return 80, 2, 9, 0xF8, "3.5\" DS/DD 80T 9S", "3.5\" 720KB (Dupla Face / Dupla Densidade)"
	case 0xF9:
		return 80, 2, 9, 0xF9, "3.5\" DS/DD 80T 9S", "3.5\" 720KB (Dupla Face / Dupla Densidade)"
	case 0xFA:
		return 80, 1, 8, 0xFA, "3.5\" SS/DD 80T 8S", "3.5\" 320KB (Simples Face / Dupla Densidade)"
	case 0xFB:
		return 80, 2, 8, 0xFB, "3.5\" DS/DD 80T 8S", "3.5\" 640KB (Dupla Face / Dupla Densidade)"
	case 0xFC:
		return 40, 1, 9, 0xFC, "5.25\" SS/DD 40T 9S", "5 1/4\" 180KB (Simples Face / Dupla Densidade)"
	case 0xFD:
		return 40, 2, 9, 0xFD, "5.25\" DS/DD 40T 9S", "5 1/4\" 360KB (Dupla Face / Dupla Densidade)"
	case 0xFE:
		return 40, 1, 8, 0xFE, "5.25\" SS/SD 40T 8S", "5 1/4\" 160KB (Simples Face / Simples Densidade)"
	case 0xFF:
		return 40, 2, 8, 0xFF, "5.25\" DS/SD 40T 8S", "5 1/4\" 320KB (Dupla Face / Simples Densidade)"
	}

	// If media descriptor is 0 or non-standard, infer from total byte length
	sz := len(data)
	switch sz {
	case 737280:
		return 80, 2, 9, 0xF8, "3.5\" DS/DD 80T 9S", "3.5\" 720KB (Dupla Face / Dupla Densidade)"
	case 368640:
		return 40, 2, 9, 0xFD, "5.25\" DS/DD 40T 9S", "5 1/4\" 360KB (Dupla Face / Dupla Densidade)"
	case 184320:
		return 40, 1, 9, 0xFC, "5.25\" SS/DD 40T 9S", "5 1/4\" 180KB (Simples Face / Dupla Densidade)"
	case 655360:
		return 80, 2, 8, 0xFB, "3.5\" DS/DD 80T 8S", "3.5\" 640KB (Dupla Face / Dupla Densidade)"
	case 327680:
		return 40, 2, 8, 0xFF, "5.25\" DS/SD 40T 8S", "5 1/4\" 320KB (Dupla Face / Simples Densidade)"
	case 163840:
		return 40, 1, 8, 0xFE, "5.25\" SS/SD 40T 8S", "5 1/4\" 160KB (Simples Face / Simples Densidade)"
	default:
		sectors := sz / 512
		kb := sz / 1024
		return 80, 2, 9, mediaID, fmt.Sprintf("%d KB", kb), fmt.Sprintf("Custom %d KB (%d setores)", kb, sectors)
	}
}

// LoadTape loads a .CAS tape image into the virtual cassette mechanism.
func (m *Machine) LoadTape(path string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("failed to read tape image %q: %w", path, err)
	}
	m.Tape = &TapeDrive{
		Path: path,
		Data: data,
		Pos:  0,
	}
	m.Config.TapePath = path
	return nil
}

// EjectTape removes any loaded tape image.
func (m *Machine) EjectTape() {
	m.Tape = &TapeDrive{}
	m.Config.TapePath = ""
}

// RewindTape rewinds the loaded tape back to position 0.
func (m *Machine) RewindTape() {
	if m.Tape != nil {
		m.Tape.Pos = 0
	}
}

// PatchZ80 implements faithful emulation of MSX BIOS and DiskROM BDOS system calls.
// Intercepted via opcode ED FE (equivalent to DB FE in fMSX).
func (m *Machine) PatchZ80(z *z80.Z80, bus z80.Bus) {
	trapAddr := z.PC - 2

	switch trapAddr {
	// =========================================================================
	// DiskROM BDOS Routines (0x4010..0x401F)
	// =========================================================================

	case 0x4010:
		// PHYDIO: Read/write physical disk sectors
		// Input:
		//   F: Carry = 1 for Write, 0 for Read
		//   A: Drive number (0 = A:, 1 = B:)
		//   B: Number of sectors
		//   C: Media descriptor (F8h..FFh)
		//   DE: Logical sector number (starts at 0)
		//   HL: Transfer buffer address
		// Output:
		//   F: Carry = 1 on error, 0 on success
		//   A: If error: errorcode (0=Write protected, 2=Not ready, 4=Data error, 8=Record not found, 10=Write fault)
		//   B: Number of sectors remaining
		isWrite := (z.F & z80.FlagC) != 0
		drive := int(z.A)
		count := int(z.B)
		sector := int(z.DE())
		addr := z.HL()

		z.IFF1 = true
		z.IFF2 = true

		if !m.DiskPresent(drive) {
			z.A = 2 // Not ready
			z.F = (z.F &^ z80.FlagZ) | z80.FlagC
			return
		}

		maxSectors := m.FDD[drive].Sectors
		if maxSectors == 0 {
			maxSectors = len(m.FDD[drive].Data) / 512
		}
		if sector+count > maxSectors {
			z.A = 8 // Record not found
			z.F = (z.F &^ z80.FlagZ) | z80.FlagC
			return
		}

		if int(addr)+count*512 > 0x10000 {
			count = (0x10000 - int(addr)) / 512
		}

		// Save slot state
		ps := m.Slots.PSLReg
		ss := m.Slots.SSLReg[3]

		// Switch RAM into all slots for direct memory transfer (matches fMSX)
		m.Slots.SetPSL(0xFF)
		m.Slots.SetSSL(0xAA)

		if isWrite {
			for s := sector; count > 0; count-- {
				buf := make([]byte, 512)
				for j := 0; j < 512; j++ {
					buf[j] = bus.Read(addr)
					addr++
				}
				if err := m.DiskWrite(drive, s, buf); err == nil {
					z.B--
					s++
				} else {
					z.A = 10 // Write fault
					z.F = (z.F &^ z80.FlagZ) | z80.FlagC
					m.Slots.SetSSL(ss)
					m.Slots.SetPSL(ps)
					return
				}
			}
		} else {
			for s := sector; count > 0; count-- {
				data, err := m.DiskRead(drive, s)
				if err == nil && len(data) >= 512 {
					z.B--
					s++
					for j := 0; j < 512; j++ {
						bus.Write(addr, data[j])
						addr++
					}
				} else {
					z.A = 4 // Data error
					z.F = (z.F &^ z80.FlagZ) | z80.FlagC
					m.Slots.SetSSL(ss)
					m.Slots.SetPSL(ps)
					return
				}
			}
		}

		// Restore slot states
		m.Slots.SetSSL(ss)
		m.Slots.SetPSL(ps)

		// Success
		z.F &^= z80.FlagC

	case 0x4013:
		// DSKCHG: Check if disk was changed
		// Input:
		//   A: Drive number (0 = A:, 1 = B:)
		//   B: Media descriptor
		//   C: Media descriptor
		//   HL: Base address of DPB
		// Output:
		//   F: Carry = 1 on error, 0 on success
		//   A: Error code if error
		//   B: 1 = Unchanged, 0 = Unknown, -1 (0xFF) = Changed
		drive := int(z.A)
		z.IFF1 = true
		z.IFF2 = true

		if !m.DiskPresent(drive) {
			z.A = 2 // Not ready
			z.F = (z.F &^ z80.FlagZ) | z80.FlagC
			return
		}
		// In fMSX Patch.c:208:
		// Set B = 0 (unknown) and clear carry, then fall through to GETDPB (0x4016)
		// to read the boot sector and transfer the new DPB into [HL+1]..[HL+18].
		z.B = 0
		z.F &^= z80.FlagC
		fallthrough

	case 0x4016:
		// GETDPB: Extract Drive Parameter Block from boot sector
		drive := int(z.A)
		z.IFF1 = true
		z.IFF2 = true

		if !m.DiskPresent(drive) {
			z.A = 2
			z.F = (z.F &^ z80.FlagZ) | z80.FlagC
			return
		}
		buf, err := m.DiskRead(drive, 0)
		if err != nil || len(buf) < 512 {
			z.A = 12 // Other error
			z.F = (z.F &^ z80.FlagZ) | z80.FlagC
			return
		}

		bytesPerSector := int(buf[0x0C])*256 + int(buf[0x0B])
		if bytesPerSector <= 0 {
			bytesPerSector = 512
		}
		sectorsPerDisk := int(buf[0x14])*256 + int(buf[0x13])
		if sectorsPerDisk <= 0 && m.FDD[drive] != nil {
			sectorsPerDisk = m.FDD[drive].Sectors
		}
		if sectorsPerDisk <= 0 && m.FDD[drive] != nil && len(m.FDD[drive].Data) > 0 {
			sectorsPerDisk = len(m.FDD[drive].Data) / bytesPerSector
		}
		sectorsPerFAT := int(buf[0x17])*256 + int(buf[0x16])
		if sectorsPerFAT <= 0 {
			sectorsPerFAT = int(buf[0x16])
		}
		if sectorsPerFAT <= 0 {
			sectorsPerFAT = 3
		}
		reservedSectors := int(buf[0x0F])*256 + int(buf[0x0E])
		if reservedSectors <= 0 {
			reservedSectors = 1
		}

		addr := z.HL() + 1
		bus.Write(addr, buf[0x15]) // Media format ID [F8h-FFh]
		addr++
		bus.Write(addr, buf[0x0B]) // Sector size low
		addr++
		bus.Write(addr, buf[0x0C]) // Sector size high
		addr++

		j := (bytesPerSector >> 5) - 1
		i := 0
		for (j & (1 << i)) != 0 {
			i++
		}
		bus.Write(addr, uint8(j)) // Directory mask
		addr++
		bus.Write(addr, uint8(i)) // Directory shift
		addr++

		secPerCluster := int(buf[0x0D])
		if secPerCluster <= 0 {
			secPerCluster = 2
		}
		j = secPerCluster - 1
		i = 0
		for (j & (1 << i)) != 0 {
			i++
		}
		bus.Write(addr, uint8(j))   // Cluster mask
		addr++
		bus.Write(addr, uint8(i+1)) // Cluster shift
		addr++

		bus.Write(addr, buf[0x0E]) // Sector # of 1st FAT low
		addr++
		bus.Write(addr, buf[0x0F]) // Sector # of 1st FAT high
		addr++
		numFATs := int(buf[0x10])
		if numFATs <= 0 {
			numFATs = 2
		}
		bus.Write(addr, uint8(numFATs)) // Number of FATs
		addr++
		bus.Write(addr, buf[0x11]) // Number of directory entries
		addr++

		firstData := reservedSectors + numFATs*sectorsPerFAT + 32*int(buf[0x11])/bytesPerSector
		bus.Write(addr, uint8(firstData&0xFF)) // Sector # of data low
		addr++
		bus.Write(addr, uint8((firstData>>8)&0xFF)) // Sector # of data high
		addr++

		numClusters := 0
		if secPerCluster > 0 {
			numClusters = (sectorsPerDisk - firstData) / secPerCluster
		}
		bus.Write(addr, uint8(numClusters&0xFF)) // Number of clusters low
		addr++
		bus.Write(addr, uint8((numClusters>>8)&0xFF)) // Number of clusters high
		addr++

		bus.Write(addr, uint8(sectorsPerFAT&0xFF)) // Sectors per FAT
		addr++

		firstDir := reservedSectors + numFATs*sectorsPerFAT
		bus.Write(addr, uint8(firstDir&0xFF)) // Sector # of directory low
		addr++
		bus.Write(addr, uint8((firstDir>>8)&0xFF)) // Sector # of directory high

		z.F &^= z80.FlagC

	case 0x401C:
		// DSKFMT: Disk format routine
		choice := int(z.A)
		drive := int(z.D)
		z.IFF1 = true
		z.IFF2 = true

		if choice < 1 || choice > 2 {
			z.A = 12 // Bad parameter
			z.F = (z.F &^ z80.FlagZ) | z80.FlagC
			return
		}
		if !m.DiskPresent(drive) {
			z.A = 2 // Not ready
			z.F = (z.F &^ z80.FlagZ) | z80.FlagC
			return
		}

		n := 2 - choice
		info := DiskFormats[n]

		// Format boot sector
		boot := make([]byte, 512)
		copy(boot, BootBlock)
		copy(boot[3:11], []byte("fMSXdisk"))
		boot[13] = info.PerCluster
		boot[17] = info.Names
		boot[18] = 0x00
		boot[19] = uint8(info.Sectors & 0xFF)
		boot[20] = uint8((info.Sectors >> 8) & 0xFF)
		boot[21] = uint8(n + 0xF8)
		boot[22] = info.PerFAT
		boot[23] = 0x00
		boot[24] = info.PerTrack
		boot[25] = 0x00
		boot[26] = info.Heads
		boot[27] = 0x00

		if err := m.DiskWrite(drive, 0, boot); err != nil {
			z.A = 0 // Write protected
			z.F = (z.F &^ z80.FlagZ) | z80.FlagC
			return
		}

		// Initialize FAT sectors
		sector := 1
		for fat := 0; fat < 2; fat++ {
			fatSec := make([]byte, 512)
			fatSec[0] = uint8(n + 0xF8)
			fatSec[1] = 0xFF
			fatSec[2] = 0xFF
			if err := m.DiskWrite(drive, sector, fatSec); err != nil {
				z.A = 10
				z.F = (z.F &^ z80.FlagZ) | z80.FlagC
				return
			}
			sector++

			emptySec := make([]byte, 512)
			for i := int(info.PerFAT); i > 1; i-- {
				if err := m.DiskWrite(drive, sector, emptySec); err != nil {
					z.A = 10
					z.F = (z.F &^ z80.FlagZ) | z80.FlagC
					return
				}
				sector++
			}
		}

		// Clear directory
		dirSectors := int(info.Names) / 16
		zeroSec := make([]byte, 512)
		for j := 0; j < dirSectors; j++ {
			_ = m.DiskWrite(drive, sector, zeroSec)
			sector++
		}

		// Clear remaining data sectors
		fillSec := make([]byte, 512)
		for j := range fillSec {
			fillSec[j] = 0xFF
		}
		dataSectors := info.Sectors - 2*int(info.PerFAT) - dirSectors - 1
		for j := 0; j < dataSectors && sector < info.Sectors; j++ {
			_ = m.DiskWrite(drive, sector, fillSec)
			sector++
		}

		z.F &^= z80.FlagC

	case 0x401F:
		// DRVOFF: Stop drive motors
		return

	// =========================================================================
	// BIOS Tape Routines (0x00E1..0x00F3)
	// =========================================================================

	case 0x00E1:
		// TAPION: Open tape for read & look for tape header
		z.F |= z80.FlagC
		if m.Tape != nil && len(m.Tape.Data) > 0 {
			if m.Tape.Pos < len(m.Tape.Data) {
				idx := bytes.Index(m.Tape.Data[m.Tape.Pos:], TapeHeader)
				if idx >= 0 {
					m.Tape.Pos += idx + len(TapeHeader)
					z.F &^= z80.FlagC
					return
				}
			}
			m.Tape.Pos = 0 // rewind if not found
		}

	case 0x00E4:
		// TAPIN: Read byte from tape into register A
		z.F |= z80.FlagC
		if m.Tape != nil && m.Tape.Pos < len(m.Tape.Data) {
			z.A = m.Tape.Data[m.Tape.Pos]
			m.Tape.Pos++
			z.F &^= z80.FlagC
		}

	case 0x00E7:
		// TAPIOF: Stop tape read
		z.F &^= z80.FlagC

	case 0x00EA:
		// TAPOON: Open tape for write & write tape header
		z.F |= z80.FlagC
		if m.Tape != nil {
			m.Tape.Data = append(m.Tape.Data, TapeHeader...)
			m.Tape.Pos = len(m.Tape.Data)
			z.F &^= z80.FlagC
		}

	case 0x00ED:
		// TAPOUT: Write byte from register A to tape
		z.F |= z80.FlagC
		if m.Tape != nil {
			m.Tape.Data = append(m.Tape.Data, z.A)
			m.Tape.Pos = len(m.Tape.Data)
			z.F &^= z80.FlagC
		}

	case 0x00F0:
		// TAPOOF: Stop tape write
		z.F &^= z80.FlagC

	case 0x00F3:
		// STMOTR: Set cassette motor
		z.F &^= z80.FlagC

	default:
		// Unknown trap
	}
}
