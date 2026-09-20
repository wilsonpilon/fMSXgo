package msx

import "os"

// RAMMapper manages the MSX Memory Mapper (standard 16KB banked RAM).
type RAMMapper struct {
	Pages     int       // Number of 16KB RAM pages (e.g. 4 for 64KB, 8 for 128KB, 32 for 512KB)
	Mask      uint8     // Bitmask based on number of pages
	Regs      [4]uint8  // Current 16KB page index for CPU pages 0, 1, 2, 3 (ports FC..FF)
	RAMData   []byte    // Backing store of size Pages * 16KB
	PageSlices [][]byte // Slices of 16KB pages
}

// NewRAMMapper creates a new RAM Mapper with the specified number of 16KB pages.
func NewRAMMapper(pages int) *RAMMapper {
	if pages < 4 {
		pages = 4
	}
	// Round up to power of 2 for mask
	mask := 1
	for mask < pages {
		mask <<= 1
	}
	mask--

	totalBytes := pages * PageSize16K
	data := make([]byte, totalBytes)
	slices := make([][]byte, pages)
	for i := 0; i < pages; i++ {
		slices[i] = data[i*PageSize16K : (i+1)*PageSize16K]
	}

	rm := &RAMMapper{
		Pages:      pages,
		Mask:       uint8(mask),
		RAMData:    data,
		PageSlices: slices,
	}

	// Default MSX mapping: Page 3 = page 0, Page 2 = page 1, Page 1 = page 2, Page 0 = page 3
	rm.Regs[0] = 3
	rm.Regs[1] = 2
	rm.Regs[2] = 1
	rm.Regs[3] = 0

	return rm
}

// WritePort handles writes to I/O ports FC..FF
func (rm *RAMMapper) WritePort(port uint8, val uint8) {
	page := port - 0xFC
	if page < 4 {
		rm.Regs[page] = val & rm.Mask
	}
}

// ReadPort handles reads from I/O ports FC..FF
func (rm *RAMMapper) ReadPort(port uint8) uint8 {
	page := port - 0xFC
	if page < 4 {
		return rm.Regs[page] | (^rm.Mask)
	}
	return 0xFF
}

// Get16KPage returns the currently mapped 16KB RAM slice for CPU page (0..3)
func (rm *RAMMapper) Get16KPage(page int) []byte {
	if page < 0 || page >= 4 {
		return nil
	}
	idx := int(rm.Regs[page]) % rm.Pages
	return rm.PageSlices[idx]
}

// Cartridge Mapper Types
const (
	MapperGeneric8K    = 0
	MapperGeneric16K   = 1
	MapperKonami5      = 2  // Konami with SCC (banks at 5000h, 7000h, 9000h, B000h)
	MapperKonami4      = 3  // Konami without SCC (banks at 4000h, 6000h, 8000h, A000h)
	MapperASCII8K      = 4  // ASCII 8K (banks at 6000h, 6800h, 7000h, 7800h)
	MapperASCII16K     = 5  // ASCII 16K (banks at 6000h, 7000h)
	MapperCrossBlaim   = 6  // Cross Blaim 64KB (all-region write, 4x16KB)
	MapperRType        = 7  // R-Type 384KB (fixed bank 23 at 4000h, bank selection at 8000h)
	MapperHarryFox     = 8  // Harry Fox Yuki no Maoh 64KB (6000h/7000h)
	MapperSuperPierrot = 9  // Super Pierrot 128KB (ASCII16 no-flash)
	MapperASCII16SRAM  = 10 // ASCII 16K with 2KB/8KB persistent SRAM (Hydlide II)
)

// Cartridge represents an MSX ROM cartridge.
type Cartridge struct {
	Name          string
	Data          []byte
	Size          int
	MapperType    int
	Banks         [4]int     // Currently selected 8KB banks for 4000h..BFFFh
	BankCount     int
	SRAM          []byte     // Battery-backed SRAM (e.g. 2048 or 8192 bytes)
	SRAMMirror    [8192]byte // 8KB window mirroring SRAM
	SRAMPage1     bool       // True if Page 1 (4000h..7FFFh) mapped to SRAM
	SRAMPage2     bool       // True if Page 2 (8000h..BFFFh) mapped to SRAM
	SRAMModified  bool       // True if SRAM was written to
	CrossBlaimVal uint8      // Current state of Cross Blaim
	SavePath      string     // Path to .sav file
}

// NewCartridge creates a cartridge from raw ROM bytes.
func NewCartridge(name string, romData []byte, mapperType int) *Cartridge {
	size := len(romData)
	bankCount := size / PageSize8K
	if bankCount < 1 {
		bankCount = 1
	}

	cart := &Cartridge{
		Name:       name,
		Data:       romData,
		Size:       size,
		MapperType: mapperType,
		BankCount:  bankCount,
	}

	switch mapperType {
	case MapperRType:
		// R-Type: First 16KB (banks 0,1) fixed at bank 0x17 (23) -> 8KB banks 46, 47
		fixed16k := 0x17
		if fixed16k*2+1 < bankCount {
			cart.Banks[0] = fixed16k * 2
			cart.Banks[1] = fixed16k*2 + 1
		} else {
			cart.Banks[0] = 0
			cart.Banks[1] = 1 % bankCount
		}
		cart.Banks[2] = 0
		cart.Banks[3] = 1 % bankCount

	case MapperCrossBlaim:
		// Initial state 00:
		// 0000h..3FFFh: 16KB block 1
		// 4000h..7FFFh: 16KB block 0 (banks 0, 1)
		// 8000h..BFFFh: 16KB block 1 (banks 2, 3)
		// C000h..FFFFh: 16KB block 1
		cart.CrossBlaimVal = 0
		cart.Banks[0] = 0
		cart.Banks[1] = 1 % bankCount
		cart.Banks[2] = 2 % bankCount
		cart.Banks[3] = 3 % bankCount

	case MapperHarryFox:
		// Initial state:
		// 4000h..7FFFh: 16KB block 0 (banks 0, 1)
		// 8000h..BFFFh: 16KB block 1 (banks 2, 3)
		cart.Banks[0] = 0
		cart.Banks[1] = 1 % bankCount
		cart.Banks[2] = 2 % bankCount
		cart.Banks[3] = 3 % bankCount

	case MapperASCII16SRAM:
		cart.InitSRAM(2048)
		cart.Banks[0] = 0
		cart.Banks[1] = 1 % bankCount
		cart.Banks[2] = 0
		cart.Banks[3] = 1 % bankCount

	default:
		// Default banks
		cart.Banks[0] = 0
		cart.Banks[1] = 1 % bankCount
		cart.Banks[2] = 2 % bankCount
		cart.Banks[3] = 3 % bankCount
	}

	return cart
}

// InitSRAM initializes the battery-backed SRAM storage.
func (c *Cartridge) InitSRAM(size int) {
	if size <= 0 {
		size = 2048
	}
	c.SRAM = make([]byte, size)
	for i := range c.SRAM {
		c.SRAM[i] = 0xFF
	}
	c.syncSRAMMirror()
	c.SRAMModified = false
}

// syncSRAMMirror copies the SRAM contents into the 8KB mirrored buffer.
func (c *Cartridge) syncSRAMMirror() {
	if len(c.SRAM) == 0 {
		return
	}
	sramLen := len(c.SRAM)
	for i := 0; i < len(c.SRAMMirror); i++ {
		c.SRAMMirror[i] = c.SRAM[i%sramLen]
	}
}

// WriteSRAM writes a byte into SRAM and updates the mirror.
func (c *Cartridge) WriteSRAM(addr uint16, val uint8) {
	if len(c.SRAM) == 0 {
		c.InitSRAM(2048)
	}
	sramMask := len(c.SRAM) - 1
	offset := int(addr) & sramMask
	c.SRAM[offset] = val
	c.SRAMModified = true

	// Update mirror
	for i := offset; i < len(c.SRAMMirror); i += len(c.SRAM) {
		c.SRAMMirror[i] = val
	}
}

// LoadSRAM loads SRAM state from disk.
func (c *Cartridge) LoadSRAM(path string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	if len(c.SRAM) == 0 {
		c.InitSRAM(len(data))
	}
	copy(c.SRAM, data)
	c.syncSRAMMirror()
	c.SRAMModified = false
	c.SavePath = path
	return nil
}

// SaveSRAM writes modified SRAM state to disk.
func (c *Cartridge) SaveSRAM(path string) error {
	if path == "" {
		path = c.SavePath
	}
	if path == "" || len(c.SRAM) == 0 || !c.SRAMModified {
		return nil
	}
	err := os.WriteFile(path, c.SRAM, 0644)
	if err == nil {
		c.SRAMModified = false
		c.SavePath = path
	}
	return err
}

// Write intercepts writes to MegaROM banking addresses or SRAM
func (c *Cartridge) Write(addr uint16, val uint8) bool {
	if c.Size <= 32*1024 && c.MapperType == MapperGeneric16K {
		// Standard 32KB ROMs don't have bank switching
		return false
	}

	bank := int(val) % c.BankCount

	switch c.MapperType {
	case MapperKonami4: // 4000h, 6000h, 8000h, A000h
		switch addr {
		case 0x4000:
			c.Banks[0] = bank
			return true
		case 0x6000:
			c.Banks[1] = bank
			return true
		case 0x8000:
			c.Banks[2] = bank
			return true
		case 0xA000:
			c.Banks[3] = bank
			return true
		}

	case MapperKonami5: // 5000h, 7000h, 9000h, B000h
		switch addr {
		case 0x5000:
			c.Banks[0] = bank
			return true
		case 0x7000:
			c.Banks[1] = bank
			return true
		case 0x9000:
			c.Banks[2] = bank
			return true
		case 0xB000:
			c.Banks[3] = bank
			return true
		}

	case MapperASCII8K:
		if addr >= 0x6000 && addr <= 0x67FF {
			c.Banks[0] = bank
			return true
		} else if addr >= 0x6800 && addr <= 0x6FFF {
			c.Banks[1] = bank
			return true
		} else if addr >= 0x7000 && addr <= 0x77FF {
			c.Banks[2] = bank
			return true
		} else if addr >= 0x7800 && addr <= 0x7FFF {
			c.Banks[3] = bank
			return true
		}

	case MapperASCII16K:
		if addr >= 0x6000 && addr <= 0x67FF {
			c.Banks[0] = (bank * 2) % c.BankCount
			c.Banks[1] = (bank*2 + 1) % c.BankCount
			return true
		} else if addr >= 0x7000 && addr <= 0x77FF {
			c.Banks[2] = (bank * 2) % c.BankCount
			c.Banks[3] = (bank*2 + 1) % c.BankCount
			return true
		}

	case MapperCrossBlaim:
		// Cross Blaim: Lower 2 bits control banking across the entire memory space
		c.CrossBlaimVal = val & 3
		c.Banks[0] = 0 // 16KB block 0 (banks 0, 1) fixed at 4000h..7FFFh
		c.Banks[1] = 1 % c.BankCount
		switch c.CrossBlaimVal {
		case 0, 1:
			c.Banks[2] = 2 % c.BankCount // 16KB block 1
			c.Banks[3] = 3 % c.BankCount
		case 2:
			c.Banks[2] = 4 % c.BankCount // 16KB block 2
			c.Banks[3] = 5 % c.BankCount
		case 3:
			c.Banks[2] = 6 % c.BankCount // 16KB block 3
			c.Banks[3] = 7 % c.BankCount
		}
		return true

	case MapperRType:
		// R-Type: Writes to 4000h..7FFFh switch 8000h..BFFFh
		if addr >= 0x4000 && addr < 0x8000 {
			v := val
			if (v & 0x10) != 0 {
				v &= 0x17
			} else {
				v &= 0x1F
			}
			b := int(v) * 2
			c.Banks[2] = b % c.BankCount
			c.Banks[3] = (b + 1) % c.BankCount
			return true
		}

	case MapperHarryFox:
		// Harry Fox: 6000h..6FFFh switches block 0 or 2 to 4000h..7FFFh
		//            7000h..7FFFh switches block 1 or 3 to 8000h..BFFFh
		if addr >= 0x6000 && addr < 0x7000 {
			block := 2 * int(val&1)
			c.Banks[0] = (block * 2) % c.BankCount
			c.Banks[1] = (block*2 + 1) % c.BankCount
			return true
		} else if addr >= 0x7000 && addr < 0x8000 {
			block := 2*int(val&1) + 1
			c.Banks[2] = (block * 2) % c.BankCount
			c.Banks[3] = (block*2 + 1) % c.BankCount
			return true
		}

	case MapperSuperPierrot:
		// Super Pierrot: Standard ASCII16 banking without FlashROM write side-effects
		if addr >= 0x6000 && addr <= 0x67FF {
			c.Banks[0] = (bank * 2) % c.BankCount
			c.Banks[1] = (bank*2 + 1) % c.BankCount
			return true
		} else if addr >= 0x7000 && addr <= 0x77FF {
			c.Banks[2] = (bank * 2) % c.BankCount
			c.Banks[3] = (bank*2 + 1) % c.BankCount
			return true
		}
		return true // Other writes are ignored without modifying state

	case MapperASCII16SRAM:
		// ASCII 16K with SRAM (Hydlide 2):
		// 6000h..67FFh selects 4000h..7FFFh (bit 4 or >= BankCount/2 selects SRAM, read-only)
		// 7000h..77FFh selects 8000h..BFFFh (bit 4 selects SRAM, read-write)
		if addr >= 0x6000 && addr < 0x7800 && (addr&0x0800) == 0 {
			isSRAM := (val == 0x10) || ((val & 0x10) != 0)
			if addr < 0x7000 {
				if isSRAM {
					c.SRAMPage1 = true
				} else {
					c.SRAMPage1 = false
					c.Banks[0] = (bank * 2) % c.BankCount
					c.Banks[1] = (bank*2 + 1) % c.BankCount
				}
				return true
			} else {
				if isSRAM {
					c.SRAMPage2 = true
				} else {
					c.SRAMPage2 = false
					c.Banks[2] = (bank * 2) % c.BankCount
					c.Banks[3] = (bank*2 + 1) % c.BankCount
				}
				return true
			}
		}

		// Write to SRAM if enabled in Page 2 (8000h..BFFFh)
		if addr >= 0x8000 && addr < 0xC000 && c.SRAMPage2 {
			c.WriteSRAM(addr, val)
			return true
		}
	}

	return false
}

// Get8KBank returns an 8KB slice of the cartridge for bank index (0..3)
func (c *Cartridge) Get8KBank(bankIdx int) []byte {
	if bankIdx < 0 || bankIdx >= 4 {
		return nil
	}

	// SRAM handling for MapperASCII16SRAM
	if c.MapperType == MapperASCII16SRAM {
		if (bankIdx == 0 || bankIdx == 1) && c.SRAMPage1 {
			return c.SRAMMirror[:PageSize8K]
		}
		if (bankIdx == 2 || bankIdx == 3) && c.SRAMPage2 {
			return c.SRAMMirror[:PageSize8K]
		}
	}

	if len(c.Data) == 0 {
		return nil
	}

	actualBank := c.Banks[bankIdx]
	offset := actualBank * PageSize8K
	if offset+PageSize8K <= len(c.Data) {
		return c.Data[offset : offset+PageSize8K]
	}
	return nil
}

// Get8KBankExtra returns an 8KB slice for pages 0, 1 (0000h..3FFFh) or 6, 7 (C000h..FFFFh)
// specifically used by full-address mappers such as Cross Blaim.
func (c *Cartridge) Get8KBankExtra(page int) []byte {
	if c.MapperType != MapperCrossBlaim || len(c.Data) == 0 {
		return nil
	}

	// For Cross Blaim:
	// If val == 0 or 1, block 1 (banks 2, 3) is mapped to 0000h..3FFFh and C000h..FFFFh.
	// If val == 2 or 3, those pages are unmapped.
	if c.CrossBlaimVal <= 1 {
		switch page {
		case 0: // 0000h..1FFFh -> bank 2
			return c.Data[2*PageSize8K : 3*PageSize8K]
		case 1: // 2000h..3FFFh -> bank 3
			return c.Data[3*PageSize8K : 4*PageSize8K]
		case 6: // C000h..DFFFh -> bank 2
			return c.Data[2*PageSize8K : 3*PageSize8K]
		case 7: // E000h..FFFFh -> bank 3
			return c.Data[3*PageSize8K : 4*PageSize8K]
		}
	}
	return nil
}

