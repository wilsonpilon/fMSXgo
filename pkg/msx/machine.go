package msx

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"fmsxgo/pkg/cpu/z80"
	"fmsxgo/pkg/sound"
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

	// Sound chips & synthesis
	PSG   *sound.AY8910
	SCC   *sound.SCC
	OPLL  *sound.YM2413
	Mixer *sound.Mixer
	Joy   *JoystickManager

	// Hardware Peripherals matching fMSX
	FDD  [2]*FloppyDrive
	Tape *TapeDrive
	FDC  *WD1793

	// Developer / Hacker Workstation Debugger & Symbols
	Symbols  *SymbolTable
	Debugger *Debugger

	// State
	Running      bool
	sampleAcc    int
	uSecAcc      int
	audioLineAcc int
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

	psg := sound.NewAY8910(3579545)
	scc := sound.NewSCC(3579545)
	opll := sound.NewYM2413(3579545)
	sampleRate := cfg.SoundQuality
	if sampleRate <= 0 {
		sampleRate = 44100
	}
	mixer := sound.NewMixer(sampleRate, psg, scc, opll)
	bus.PSG = psg
	bus.SCC = scc
	bus.OPLL = opll

	// Wire PSG port A reading (Reg 14) to Joystick/Mouse manager
	psg.ReadPortA = func() uint8 {
		if bus.Joy != nil {
			return bus.Joy.ReadPort(psg.Regs[15])
		}
		return 0x7F
	}

	extraPaths := []string{}
	if cfg.ROMDir != "" {
		extraPaths = append(extraPaths, cfg.ROMDir)
	}
	romMgr := NewROMManager(cfg.DB, extraPaths...)

	fdd0 := &FloppyDrive{ID: 0, SecSize: 512}
	fdd1 := &FloppyDrive{ID: 1, SecSize: 512}
	fdc := NewWD1793(fdd0, fdd1)
	bus.FDC = fdc

	syms := NewSymbolTable()
	dbg := NewDebugger(syms)
	bus.CPU = cpu
	bus.Debugger = dbg

	m := &Machine{
		Config:   cfg,
		CPU:      cpu,
		Slots:    slots,
		Mapper:   mapper,
		Bus:      bus,
		VDP:      vdpInst,
		PSG:      psg,
		SCC:      scc,
		OPLL:     opll,
		Mixer:    mixer,
		Joy:      bus.Joy,
		ROMs:     romMgr,
		DB:       cfg.DB,
		FDD:      [2]*FloppyDrive{fdd0, fdd1},
		Tape:     &TapeDrive{},
		FDC:      fdc,
		Symbols:  syms,
		Debugger: dbg,
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

// initHardware loads BIOS ROMs and maps RAM/ROM into appropriate slots matching fMSX.
func (m *Machine) initHardware() error {
	// 1. Map RAM into Slot 3 (Subslot 2 authentic fMSX, and mirror in Subslot 0) for all 4 pages
	for page := 0; page < 4; page++ {
		m.Slots.Map16K(3, 2, page, m.Mapper.Get16KPage(page), true)
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

	// Load SubROM (MSX2/MSX2+ Extended BIOS, 16KB: Page 0) into Slot 3, Subslot 1
	if defaultSub != "" {
		subBios, _, err := m.ROMs.LoadDefaultROM("subrom", modelStr)
		if err != nil {
			subBios, err = m.ROMs.LoadROM(defaultSub)
		}
		if err == nil && len(subBios) >= PageSize16K {
			m.Slots.Map16K(3, 1, 0, subBios[:PageSize16K], false)
		}
	} else {
		// MSX1: SubROM area is empty
		m.Slots.Map16K(3, 1, 0, m.Slots.EmptyPage, false)
	}

	// Load DiskROM if available (16KB: Page 1) into Slot 3, Subslot 1 (and fallback 3-2)
	diskROM, _, err := m.ROMs.LoadDefaultROM("disk", "ALL")
	if err != nil {
		diskROM, err = m.ROMs.LoadROM("DISK.ROM")
	}
	if err == nil && len(diskROM) >= PageSize16K {
		// Apply BDOS patches (ED FE C9) if SimulateBDOS is enabled (fMSX default)
		if m.Config.SimulateBDOS {
			diskROM = ApplyDiskPatches(diskROM)
		}
		// Authentic fMSX mapping: Slot 3, Subslot 1, Page 1 (4000h..7FFFh)
		m.Slots.Map16K(3, 1, 1, diskROM[:PageSize16K], false)
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

	mapperType, _ := GuessMapper(data, path)
	cart := NewCartridge(path, data, mapperType)

	// If cartridge uses SRAM, load .sav if present
	if mapperType == MapperASCII16SRAM {
		savPath := strings.TrimSuffix(path, filepath.Ext(path)) + ".sav"
		cart.SavePath = savPath
		if _, err := os.Stat(savPath); err == nil {
			_ = cart.LoadSRAM(savPath)
		}
	}

	if slot == 1 {
		// Save old cartridge SRAM if needed
		if m.Bus.CartA != nil && m.Bus.CartA.SRAMModified {
			_ = m.Bus.CartA.SaveSRAM("")
		}
		m.Bus.CartA = cart
		m.Config.CartAPath = path
		m.Bus.RefreshCartridge(1, cart)
	} else if slot == 2 {
		// Save old cartridge SRAM if needed
		if m.Bus.CartB != nil && m.Bus.CartB.SRAMModified {
			_ = m.Bus.CartB.SaveSRAM("")
		}
		m.Bus.CartB = cart
		m.Config.CartBPath = path
		m.Bus.RefreshCartridge(2, cart)
	}

	return nil
}

// EjectCartridge removes any cartridge inserted into slot 1 or 2.
func (m *Machine) EjectCartridge(slot int) {
	if slot == 1 {
		if m.Bus.CartA != nil {
			if m.Bus.CartA.SRAMModified {
				_ = m.Bus.CartA.SaveSRAM("")
			}
			m.Bus.CartA = nil
		}
		m.Config.CartAPath = ""
		for p := 0; p < 8; p++ {
			m.Slots.Map8K(1, 0, p, nil, false)
		}
	} else if slot == 2 {
		if m.Bus.CartB != nil {
			if m.Bus.CartB.SRAMModified {
				_ = m.Bus.CartB.SaveSRAM("")
			}
			m.Bus.CartB = nil
		}
		m.Config.CartBPath = ""
		for p := 0; p < 8; p++ {
			m.Slots.Map8K(2, 0, p, nil, false)
		}
	}
}

// Reset resets the MSX CPU and hardware registers to power-on state.
func (m *Machine) Reset() {
	if m.Bus.CartA != nil && m.Bus.CartA.SRAMModified {
		_ = m.Bus.CartA.SaveSRAM("")
	}
	if m.Bus.CartB != nil && m.Bus.CartB.SRAMModified {
		_ = m.Bus.CartB.SaveSRAM("")
	}
	m.CPU.Reset()
	if m.VDP != nil {
		m.VDP.Reset()
	}
	if m.PSG != nil {
		m.PSG.Reset()
	}

	if m.SCC != nil {
		m.SCC.Reset()
	}
	if m.OPLL != nil {
		m.OPLL.Reset()
	}
	if m.Mixer != nil {
		m.Mixer.Reset()
	}
	if m.Joy != nil {
		m.Joy.Reset()
	}
	if m.FDC != nil {
		m.FDC.Reset(false)
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
	if m.Bus != nil {
		m.Bus.RTCReg = 0
		m.Bus.RTCMode = 0
	}
	m.CPU.PC = 0x0000
	m.Running = true
	if m.Debugger != nil {
		m.Debugger.LastHit = nil
	}
}

// Step runs a single Z80 instruction and returns CPU cycles elapsed.
func (m *Machine) Step() int {
	if m.Debugger != nil {
		if _, hit := m.Debugger.CheckPC(m.CPU); hit {
			m.Running = false
		}
	}
	c := m.CPU.Step(m.Bus)
	if m.Debugger != nil && m.Debugger.LastHit != nil {
		m.Running = false
	}
	return c
}

// Run executes instructions until target cycles are reached.
func (m *Machine) Run(targetCycles int) int {
	elapsed := 0
	for elapsed < targetCycles && !m.CPU.Halted {
		c := m.Step()
		elapsed += c
		if !m.Running {
			break
		}
	}
	return elapsed
}

// StepScanline executes ~228 CPU cycles corresponding to one scanline,
// renders the line in VDP, and dispatches VDP interrupts (IE0/IE1).
func (m *Machine) StepScanline() int {
	const cyclesPerLine = 228
	elapsed := 0

	for elapsed < cyclesPerLine {
		if m.Debugger != nil {
			if _, hit := m.Debugger.CheckPC(m.CPU); hit {
				m.Running = false
				return elapsed
			}
		}
		if m.CPU.Halted {
			// When halted, CPU waits for interrupt, consume 4 cycles per tick
			elapsed += 4
		} else {
			c := m.CPU.Step(m.Bus)
			elapsed += c
			if m.Debugger != nil && m.Debugger.LastHit != nil {
				m.Running = false
				return elapsed
			}
		}
	}

	if m.VDP == nil {
		return elapsed
	}

	// 1. Advance scanline
	line := m.VDP.ScanLine
	m.VDP.RenderScanline(line)

	if m.Debugger != nil && m.Debugger.HasScanline {
		if _, hit := m.Debugger.CheckScanline(line); hit {
			m.Running = false
			return elapsed
		}
	}

	// Sound synthesis step every 8 scanlines with exact microsecond and sample timing.
	// Uses a free-running line accumulator (rather than gating on scanline&7==0) so that
	// the trailing partial group at the end of a frame (e.g. lines 256..261 on NTSC, only
	// 6 lines instead of 8) carries its remainder into the next frame instead of being
	// counted as a full 8-line group. Without this, NTSC counts 264 "lines" of audio per
	// 262-line frame (PAL: 320 vs 313), so the PSG/mixer run ~0.8%-2.2% faster than real
	// time; once the ring buffer fills, the mixer continuously drops the oldest samples to
	// keep up, which is heard as notes being clipped into short bursts with small gaps.
	m.audioLineAcc++
	if m.audioLineAcc >= 8 {
		m.audioLineAcc -= 8
		totalLines := 262
		targetFPS := 60
		if m.VDP != nil && m.VDP.TotalLines > 0 {
			totalLines = m.VDP.TotalLines
		}
		if m.Config.Video == VideoPAL || totalLines > 280 {
			targetFPS = 50
		}
		frameDiv := targetFPS * totalLines
		if frameDiv > 0 {
			// 1. Step PSG envelopes with exact microsecond accumulator (8,000,000 / frameDiv us per 8 lines)
			m.uSecAcc += 8000000
			uSec := m.uSecAcc / frameDiv
			m.uSecAcc %= frameDiv
			if m.PSG != nil && uSec > 0 {
				m.PSG.Step(uSec)
			}

			// 2. Generate exact 44,100 Hz PCM audio samples (SampleRate * 8 / frameDiv per 8 lines)
			if m.Mixer != nil {
				m.sampleAcc += m.Mixer.SampleRate * 8
				samples := m.sampleAcc / frameDiv
				m.sampleAcc %= frameDiv
				if samples > 0 {
					m.Mixer.GenerateSamples(samples)
				}
			}
		}
	}

	// 2. Line coincidence check (IE1)
	if line == int(m.VDP.Regs[19]) {
		m.VDP.Status[1] |= 0x01
		if (m.VDP.Regs[0] & 0x10) != 0 {
			m.VDP.IRQPending |= 0x02
		}
	}

	// Frame start (scanline 0): clear VR bit and update TEXT80 blink state (fMSX MSX.c:2055-2076)
	if line == 0 {
		m.VDP.Status[2] &^= 0x40
		m.VDP.UpdateBlink()
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
		m.VDP.Status[2] |= 0x40 // Set VR (Vertical Retrace) in Status Register 2 (V9938)
		if (m.VDP.Regs[1] & 0x20) != 0 {
			m.VDP.IRQPending |= 0x01
		}
		if m.VDP.CheckSprites() {
			m.VDP.Status[0] |= 0x20
		}
	}

	// 4. Dispatch interrupt if pending
	if m.VDP.InterruptPending() {
		if m.CPU.Interrupt(m.Bus, 0x0038) {
			m.VDP.IRQPending = 0 // Match fMSX Z80.c:707 clearing IRequest on acceptance
		}
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
		if !m.Running {
			break
		}
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

// SwitchModel dynamically changes the MSX hardware model (MSX1, MSX2, MSX2+),
// adjusts RAM/VRAM pages, reloads appropriate system ROMs, and resets the machine.
func (m *Machine) SwitchModel(model int) error {
	if model != ModelMSX1 && model != ModelMSX2 && model != ModelMSX2P {
		return fmt.Errorf("invalid MSX model: %d", model)
	}

	m.Config.Model = model

	// Align RAM and VRAM pages matching fMSX line 864-867
	if model == ModelMSX1 {
		m.Config.RAMPages = 4
		m.Config.VRAMPages = 2
	} else {
		m.Config.RAMPages = 8
		m.Config.VRAMPages = 8
	}

	// Update RAM mapper and VDP
	m.Mapper = NewRAMMapper(m.Config.RAMPages)
	m.Bus.Mapper = m.Mapper
	if m.VDP != nil {
		m.VDP.SetModel(model, m.Config.VRAMPages)
	}

	// Re-initialize hardware slots and ROMs
	if err := m.initHardware(); err != nil {
		return err
	}

	// Reset CPU, slots and peripherals
	m.Reset()

	// Persist model in database if connected
	if m.DB != nil {
		var modelName string
		switch model {
		case ModelMSX1:
			modelName = "MSX1"
		case ModelMSX2:
			modelName = "MSX2"
		case ModelMSX2P:
			modelName = "MSX2+"
		}
		_ = m.DB.SetConfig("model", modelName)
	}

	return nil
}

// ModelName returns the display name of the current machine model.
func (m *Machine) ModelName() string {
	switch m.Config.Model {
	case ModelMSX1:
		return "MSX 1"
	case ModelMSX2:
		return "MSX 2"
	case ModelMSX2P:
		return "MSX 2+"
	default:
		return "Unknown"
	}
}

// VDPChipName returns the exact VDP chip name used in the machine.
func (m *Machine) VDPChipName() string {
	switch m.Config.Model {
	case ModelMSX1:
		return "TMS9918"
	case ModelMSX2:
		return "V9938"
	case ModelMSX2P:
		return "V9958"
	default:
		return "TMS9918"
	}
}

// CurrentROMs returns the list of system ROMs currently mapped for this machine.
func (m *Machine) CurrentROMs() []string {
	switch m.Config.Model {
	case ModelMSX1:
		return []string{"MSX.ROM"}
	case ModelMSX2:
		return []string{"MSX2.ROM", "MSX2EXT.ROM", "DISK.ROM"}
	case ModelMSX2P:
		return []string{"MSX2P.ROM", "MSX2PEXT.ROM", "DISK.ROM"}
	default:
		return []string{"MSX.ROM"}
	}
}

