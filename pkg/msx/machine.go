package msx

import (
	"fmt"
	"os"

	"fmsxgo/pkg/cpu/z80"
	"fmsxgo/pkg/storage"
	"fmsxgo/pkg/vdp"
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
// Contains 100% faithful fMSX options matching Help.h and MSX.h.
type Config struct {
	Model     int
	Video     int
	RAMPages  int // 16KB pages (4 for MSX1 = 64KB, 8 for MSX2 = 128KB, etc.)
	VRAMPages int // 16KB VRAM pages (2 for MSX1 = 32KB, 8 for MSX2 = 128KB)
	ROMDir    string
	DB        *storage.DB

	// fMSX faithful options
	Verbose      int    // Debug verbose level (0..32, default: 1)
	FrameSkip    int    // Percentage of frames to skip (default: 25)
	AutoFire     bool   // Autofire on SPACE (default: false)
	SimulateBDOS bool   // Patch DiskROM BDOS routines with ED FE (default: true)
	PatchBIOS    bool   // Patch BIOS tape/disk routines with ED FE (default: true)
	PrinterPath  string // Redirect printer output to file
	SerialPath   string // Redirect serial I/O to file
	TapePath     string // Tape image path (.CAS)
	FontPath     string // Fixed font file for text modes
	LogSndPath   string // Soundtrack log file (.MID)
	StatePath    string // Emulation state save file (.STA)
	JoyType      [2]int // Joystick types (0: none, 1: normal, 2: mouse/joy, 3: mouse/real)
	ROMType      [2]int // MegaROM mapper types (0..7, >7 = auto-guess)
	SoundQuality int    // Sound emulation quality (Hz, default: 44100)
	Trap         uint16 // Execution trap address (0xFFFF = off)

	CartAPath string
	CartBPath string
	DiskAPath string
	DiskBPath string
}

// DefaultConfig returns standard MSX2 configuration with fMSX defaults.
func DefaultConfig() Config {
	return Config{
		Model:        ModelMSX2,
		Video:        VideoNTSC,
		RAMPages:     8, // 128KB RAM
		VRAMPages:    8, // 128KB VRAM (8 x 16KB)
		Verbose:      1, // Startup messages
		FrameSkip:    25,
		SimulateBDOS: true, // Simulate DiskROM calls (fMSX default)
		PatchBIOS:    true, // Patch BIOS tape/disk hooks (fMSX default)
		SoundQuality: 44100,
		ROMType:      [2]int{8, 8}, // auto-guess mapper
		Trap:         0xFFFF,
	}
}

// Machine represents the complete MSX computer system.
type Machine struct {
	Config Config
	CPU    *z80.Z80
	Slots  *SlotBus
	Mapper *RAMMapper
	Bus    *MSXBus
	VDP    *vdp.VDP
	ROMs   *ROMManager
	DB     *storage.DB

	// Hardware Peripherals matching fMSX
	FDD  [2]*FloppyDrive
	Tape *TapeDrive

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
	vdpInst := vdp.New(cfg.Model, cfg.VRAMPages)
	bus := NewMSXBus(slots, mapper, vdpInst)
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
		VDP:    vdpInst,
		ROMs:   romMgr,
		DB:     cfg.DB,
		FDD: [2]*FloppyDrive{
			{ID: 0, SecSize: 512},
			{ID: 1, SecSize: 512},
		},
		Tape: &TapeDrive{},
	}

	// Connect CPU BIOS/BDOS patch hook to faithful PatchZ80 implementation
	cpu.PatchHook = m.PatchZ80

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
	var modelStr string
	var defaultMain, defaultSub string
	switch m.Config.Model {
	case ModelMSX1:
		modelStr = "MSX1"
		defaultMain = "MSX.ROM"
	case ModelMSX2:
		modelStr = "MSX2"
		defaultMain = "MSX2.ROM"
		defaultSub = "MSX2EXT.ROM"
	case ModelMSX2P:
		modelStr = "MSX2+"
		defaultMain = "MSX2P.ROM"
		defaultSub = "MSX2PEXT.ROM"
	}

	// Load Main BIOS (32KB: Pages 0 and 1) into Slot 0, Subslot 0
	mainBios, mainName, err := m.ROMs.LoadDefaultROM("bios", modelStr)
	if err != nil {
		mainBios, err = m.ROMs.LoadROM(defaultMain)
		mainName = defaultMain
	}
	if err == nil {
		// Apply BIOS patches (ED FE C9) if enabled (fMSX default)
		if m.Config.PatchBIOS {
			mainBios = ApplyBIOSPatches(mainBios)
		}

		if len(mainBios) >= PageSize16K*2 {
			m.Slots.Map16K(0, 0, 0, mainBios[:PageSize16K], false)
			m.Slots.Map16K(0, 0, 1, mainBios[PageSize16K:PageSize16K*2], false)
		} else if len(mainBios) >= PageSize16K {
			m.Slots.Map16K(0, 0, 0, mainBios[:PageSize16K], false)
		}
	} else {
		return fmt.Errorf("could not load main MSX BIOS (%s): %w", mainName, err)
	}

	// Load SubROM (MSX2/MSX2+ Extended BIOS, 16KB: Page 1) into Slot 3, Subslot 1
	if defaultSub != "" {
		subBios, _, err := m.ROMs.LoadDefaultROM("subrom", modelStr)
		if err != nil {
			subBios, err = m.ROMs.LoadROM(defaultSub)
		}
		if err == nil && len(subBios) >= PageSize16K {
			m.Slots.Map16K(3, 1, 1, subBios[:PageSize16K], false)
		}
	}

	// Load DiskROM if available (16KB: Page 1) into Slot 3, Subslot 2
	diskROM, _, err := m.ROMs.LoadDefaultROM("disk", "ALL")
	if err != nil {
		diskROM, err = m.ROMs.LoadROM("DISK.ROM")
	}
	if err == nil && len(diskROM) >= PageSize16K {
		// Apply BDOS patches (ED FE C9) if SimulateBDOS is enabled (fMSX default)
		if m.Config.SimulateBDOS {
			diskROM = ApplyDiskPatches(diskROM)
		}
		m.Slots.Map16K(3, 2, 1, diskROM[:PageSize16K], false)
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

	// 5. Mount Floppy Disk A if specified
	if m.Config.DiskAPath != "" {
		_ = m.LoadDisk(0, m.Config.DiskAPath)
	}

	// 6. Mount Floppy Disk B if specified
	if m.Config.DiskBPath != "" {
		_ = m.LoadDisk(1, m.Config.DiskBPath)
	}

	// 7. Mount Tape image if specified
	if m.Config.TapePath != "" {
		_ = m.LoadTape(m.Config.TapePath)
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
	if m.VDP != nil {
		m.VDP.Reset()
	}
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

// StepScanline executes ~228 CPU cycles corresponding to one scanline,
// renders the line in VDP, and dispatches VDP interrupts (IE0/IE1).
func (m *Machine) StepScanline() int {
	const cyclesPerLine = 228
	elapsed := 0

	for elapsed < cyclesPerLine {
		if m.CPU.Halted {
			// When halted, CPU waits for interrupt, consume 4 cycles per tick
			elapsed += 4
		} else {
			c := m.CPU.Step(m.Bus)
			elapsed += c
		}
	}

	if m.VDP == nil {
		return elapsed
	}

	// 1. Advance scanline
	line := m.VDP.ScanLine
	m.VDP.RenderScanline(line)

	// 2. Line coincidence check (IE1)
	if line == int(m.VDP.Regs[19]) {
		m.VDP.Status[1] |= 0x01
		if (m.VDP.Regs[0] & 0x10) != 0 {
			m.VDP.IRQPending |= 0x02
		}
	}

	// 3. VBlank check (IE0) at end of visible screen
	visLines := 192
	firstLine := 18 + m.VDP.VAdjust()
	if m.VDP.ScanLines212() {
		visLines = 212
		firstLine = 8 + m.VDP.VAdjust()
	}
	vblankLine := firstLine + visLines

	if line == vblankLine {
		m.VDP.Status[0] |= 0x80
		if (m.VDP.Regs[1] & 0x20) != 0 {
			m.VDP.IRQPending |= 0x01
		}
		if m.VDP.CheckSprites() {
			m.VDP.Status[0] |= 0x20
		}
	}

	// 4. Dispatch interrupt if pending
	if m.VDP.InterruptPending() {
		m.CPU.Interrupt(m.Bus, 0x0038)
	}

	// Advance to next line
	m.VDP.ScanLine++
	if m.VDP.ScanLine >= m.VDP.TotalLines {
		m.VDP.ScanLine = 0
	}

	return elapsed
}

// StepFrame executes all scanlines of a video frame (262 lines NTSC / 313 lines PAL).
func (m *Machine) StepFrame() int {
	totalLines := 262
	if m.VDP != nil && m.VDP.TotalLines > 0 {
		totalLines = m.VDP.TotalLines
	}

	cycles := 0
	for i := 0; i < totalLines; i++ {
		cycles += m.StepScanline()
	}
	return cycles
}

// GetFrameBuffer returns the 32-bit RGBA pixel slice of the rendered MSX screen.
func (m *Machine) GetFrameBuffer() []byte {
	if m.VDP == nil {
		return nil
	}
	return m.VDP.FrameBuffer[:]
}
