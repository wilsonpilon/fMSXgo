package msx

import (
	"fmt"
	"os"

	"fmsxgo/pkg/cpu/z80"
	"fmsxgo/pkg/storage"
)

// Hardware models
const (
	ModelMSX1  = 0
	ModelMSX2  = 1
	ModelMSX2P = 2
)

// Video standards
const (
	VideoNTSC = 0 // 60Hz
	VideoPAL  = 1 // 50Hz
)

// Config encapsulates the hardware configuration of the emulated MSX machine.
type Config struct {
	Model     int
	Video     int
	RAMPages  int // 16KB pages (default 4 = 64KB, 8 = 128KB, etc.)
	VRAMPages int // 64KB VRAM pages (default 2 = 128KB)
	ROMDir    string
	DB        *storage.DB

	CartAPath string
	CartBPath string
	DiskAPath string
	DiskBPath string
}

// DefaultConfig returns standard MSX2 configuration.
func DefaultConfig() Config {
	return Config{
		Model:     ModelMSX2,
		Video:     VideoNTSC,
		RAMPages:  8, // 128KB RAM
		VRAMPages: 2, // 128KB VRAM
	}
}

// Machine represents the complete MSX computer system.
type Machine struct {
	Config Config
	CPU    *z80.Z80
	Slots  *SlotBus
	Mapper *RAMMapper
	Bus    *MSXBus
	ROMs   *ROMManager
	DB     *storage.DB

	// State
	Running bool
}

// NewMachine creates and configures an MSX computer with the specified configuration.
func NewMachine(cfg Config) (*Machine, error) {
	if cfg.RAMPages < 4 {
		cfg.RAMPages = 4
	}

	slots := NewSlotBus()
	mapper := NewRAMMapper(cfg.RAMPages)
	bus := NewMSXBus(slots, mapper)
	cpu := z80.New()

	extraPaths := []string{}
	if cfg.ROMDir != "" {
		extraPaths = append(extraPaths, cfg.ROMDir)
	}
	romMgr := NewROMManager(cfg.DB, extraPaths...)

	m := &Machine{
		Config: cfg,
		CPU:    cpu,
		Slots:  slots,
		Mapper: mapper,
		Bus:    bus,
		ROMs:   romMgr,
		DB:     cfg.DB,
	}

	// Initialize BIOS and Slot architecture
	if err := m.initHardware(); err != nil {
		return nil, err
	}

	m.Reset()
	return m, nil
}

// initHardware loads BIOS ROMs and maps RAM/ROM into appropriate slots.
func (m *Machine) initHardware() error {
	// 1. Map RAM into Slot 3 (Subslot 0) for all 4 pages
	for page := 0; page < 4; page++ {
		m.Slots.Map16K(3, 0, page, m.Mapper.Get16KPage(page), true)
	}

	// 2. Load and map BIOS ROMs based on selected Model
	var mainBiosName, subBiosName string
	switch m.Config.Model {
	case ModelMSX1:
		mainBiosName = "MSX.ROM"
	case ModelMSX2:
		mainBiosName = "MSX2.ROM"
		subBiosName = "MSX2EXT.ROM"
	case ModelMSX2P:
		mainBiosName = "MSX2P.ROM"
		subBiosName = "MSX2PEXT.ROM"
	}

	// Load Main BIOS (32KB: Pages 0 and 1) into Slot 0, Subslot 0
	if mainBios, err := m.ROMs.LoadROM(mainBiosName); err == nil {
		if len(mainBios) >= PageSize16K*2 {
			m.Slots.Map16K(0, 0, 0, mainBios[:PageSize16K], false)
			m.Slots.Map16K(0, 0, 1, mainBios[PageSize16K:PageSize16K*2], false)
		} else if len(mainBios) >= PageSize16K {
			m.Slots.Map16K(0, 0, 0, mainBios[:PageSize16K], false)
		}
	} else {
		return fmt.Errorf("could not load main MSX BIOS (%s): %w", mainBiosName, err)
	}

	// Load SubROM (MSX2/MSX2+ Extended BIOS, 16KB: Page 1) into Slot 3, Subslot 1
	if subBiosName != "" {
		if subBios, err := m.ROMs.LoadROM(subBiosName); err == nil {
			if len(subBios) >= PageSize16K {
				m.Slots.Map16K(3, 1, 1, subBios[:PageSize16K], false)
			}
		}
	}

	// Load DiskROM if available (16KB: Page 1) into Slot 3, Subslot 2
	if diskROM, err := m.ROMs.LoadROM("DISK.ROM"); err == nil {
		if len(diskROM) >= PageSize16K {
			m.Slots.Map16K(3, 2, 1, diskROM[:PageSize16K], false)
		}
	}

	// 3. Load Cartridge A if specified
	if m.Config.CartAPath != "" {
		if err := m.LoadCartridge(1, m.Config.CartAPath); err != nil {
			return fmt.Errorf("failed to load Cartridge A: %w", err)
		}
	}

	// 4. Load Cartridge B if specified
	if m.Config.CartBPath != "" {
		if err := m.LoadCartridge(2, m.Config.CartBPath); err != nil {
			return fmt.Errorf("failed to load Cartridge B: %w", err)
		}
	}

	return nil
}

// LoadCartridge loads a cartridge into slot 1 or 2
func (m *Machine) LoadCartridge(slot int, path string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}

	mapperType := MapperGeneric16K
	if len(data) > 32*1024 {
		// Default to Konami or ASCII 8k heuristic
		mapperType = MapperKonami4
	}

	cart := NewCartridge(path, data, mapperType)
	if slot == 1 {
		m.Bus.CartA = cart
		m.Bus.RefreshCartridge(1, cart)
	} else if slot == 2 {
		m.Bus.CartB = cart
		m.Bus.RefreshCartridge(2, cart)
	}

	return nil
}

// Reset resets the MSX CPU and hardware registers to power-on state.
func (m *Machine) Reset() {
	m.CPU.Reset()
	// Default MSX slot setup:
	// Page 0 (0000h..3FFFh): Slot 0 (Main BIOS)
	// Page 1 (4000h..7FFFh): Slot 0 (Main BASIC)
	// Page 2 (8000h..BFFFh): Slot 3 (RAM)
	// Page 3 (C000h..FFFFh): Slot 3 (RAM)
	// Port A8h value: (Slot 0 in P0, Slot 0 in P1, Slot 3 in P2, Slot 3 in P3)
	// Binary: 11 11 00 00 = 0xF0
	m.Slots.SetPSL(0xF0)
	m.Slots.SetSSL(0x00)
	m.CPU.PC = 0x0000
}

// Step runs a single Z80 instruction and returns CPU cycles elapsed.
func (m *Machine) Step() int {
	return m.CPU.Step(m.Bus)
}

// Run executes instructions until target cycles are reached.
func (m *Machine) Run(targetCycles int) int {
	elapsed := 0
	for elapsed < targetCycles && !m.CPU.Halted {
		c := m.CPU.Step(m.Bus)
		elapsed += c
	}
	return elapsed
}
