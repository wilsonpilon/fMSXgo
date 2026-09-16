package msx

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
	MapperGeneric8K  = 0
	MapperGeneric16K = 1
	MapperKonami5    = 2 // Konami with SCC (banks at 5000h, 7000h, 9000h, B000h)
	MapperKonami4    = 3 // Konami without SCC (banks at 4000h, 6000h, 8000h, A000h)
	MapperASCII8K    = 4 // ASCII 8K (banks at 6000h, 6800h, 7000h, 7800h)
	MapperASCII16K   = 5 // ASCII 16K (banks at 6000h, 7000h)
)

// Cartridge represents an MSX ROM cartridge.
type Cartridge struct {
	Name       string
	Data       []byte
	Size       int
	MapperType int
	Banks      [4]int // Currently selected 8KB banks
	BankCount  int
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

	// Default banks
	cart.Banks[0] = 0
	cart.Banks[1] = 1 % bankCount
	cart.Banks[2] = 2 % bankCount
	cart.Banks[3] = 3 % bankCount

	return cart
}

// Write intercepts writes to MegaROM banking addresses
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
	}

	return false
}

// Get8KBank returns an 8KB slice of the cartridge for bank index (0..3)
func (c *Cartridge) Get8KBank(bankIdx int) []byte {
	if bankIdx < 0 || bankIdx >= 4 || len(c.Data) == 0 {
		return nil
	}
	actualBank := c.Banks[bankIdx]
	offset := actualBank * PageSize8K
	if offset+PageSize8K <= len(c.Data) {
		return c.Data[offset : offset+PageSize8K]
	}
	return nil
}
