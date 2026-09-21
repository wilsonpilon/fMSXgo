package ui

import (
	"fmt"
	"image/color"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/inpututil"

	"fmsxgo/pkg/i18n"
	"fmsxgo/pkg/msx"
	"fmsxgo/pkg/shell"
	"fmsxgo/pkg/sound"
	"fmsxgo/pkg/ui/font"
	"fmsxgo/pkg/ui/theme"
	"fmsxgo/pkg/vdp"
)

const (
	WindowWidth  = 640
	WindowHeight = 480
	MenuBarH     = 24

	PickerDriveA     = 0
	PickerDriveB     = 1
	PickerCart1      = 2
	PickerCart2      = 3
	PickerTape       = 4
	PickerSaveState  = 5
	PickerLoadState  = 6
)

// PickerItem represents a file or directory inside the File Picker modal.
type PickerItem struct {
	Name  string
	IsDir bool
	Size  int64
}

// UI represents the graphical interface for fMSXgo.
type UI struct {
	Machine     *msx.Machine
	AudioDevice *sound.AudioDevice

	// Live MSX Video & Display Mode
	msxScreenImg    *ebiten.Image
	DisplayMode     int  // 0 = MSX Video Display (default), 1 = Debug Status Overlay
	EmulationPaused bool // Pause CPU/frame execution

	// Video scaling and aspect ratio settings
	VideoScale     int  // 1 = 1:1 (256x212), 2 = 2:1 (512x424), 3 = 3:1 (768x636), 4 = 4:1 (1024x848)
	AspectRatio43  bool // true = force 4:3 CRT TV aspect ratio, false = 1:1 pixel aspect
	BilinearFilter bool // true = smooth linear interpolation, false = sharp nearest neighbor

	// CRT Shader & Phosphor settings
	CRTScanlines int // 0 = Off, 1 = Light, 2 = Medium
	PhosphorMode int // 0 = Color RGB, 1 = Green CRT (P1), 2 = Amber CRT
	scanlineImg  *ebiten.Image

	// Controller Configuration state
	ShowControllerConfig bool
	ControllerConfig     ControllerConfig

	// Modal and menu state
	ActiveMenu  string // "File", "Hardware", "Video", "Media", "Setup", "Help", or ""
	ShowAbout   bool
	ShowConfig  bool
	ShowCatalog bool
	ShouldExit  bool

	// Media File Picker Modal state
	ShowPicker     bool
	PickerTarget   int
	PickerDir      string
	PickerFiles    []PickerItem
	PickerSelected int
	PickerScroll   int

	// Developer / Hacker Workstation state
	ShowHackerWorkstation  bool
	HackerTab              int
	WorkstationHexAddr     uint16
	WorkstationHexVRAM     bool
	WorkstationTraceScroll int

	// Drawing buffers (re-skinned dynamically when theme changes)
	barImg           *ebiten.Image
	menuBg           *ebiten.Image
	fileMenuBg       *ebiten.Image
	hardwareMenuBg   *ebiten.Image
	videoMenuBg      *ebiten.Image
	mediaMenuBg      *ebiten.Image
	debugMenuBg      *ebiten.Image
	dialogBg         *ebiten.Image
	configDlgBg      *ebiten.Image
	catalogDlgBg     *ebiten.Image
	pickerDlgBg      *ebiten.Image
	workstationDlgBg *ebiten.Image
	buttonBg         *ebiten.Image
	screenBg         *ebiten.Image
	selectedRowBg    *ebiten.Image

	// Current window geometry
	currWinW int
	currWinH int

	// Interactive CLI goroutine management
	cliRunning bool
	cliMutex   sync.Mutex

	// Audio glitch diagnostics (see sound.Mixer.Stats). Only printed when
	// FMSXGO_AUDIO_DEBUG is set in the environment (see audioDebugEnabled).
	audioDebugEnabled    bool
	audioStatsFrameCount int
	audioStatsLastReport time.Time
	audioStatsLastGen    int64

	// Tracks the TPS ebiten is currently driven at, so it can be kept in
	// sync with the VDP's actual detected video field rate (see syncTPSToVDP).
	currentTPS int
}

// New creates a new UI instance.
func New(machine *msx.Machine) *UI {
	scale := 2
	aspect43 := false
	smooth := false
	crtScanlines := 0
	phosphorMode := 0

	ctrlCfg := DefaultControllerConfig()

	if machine != nil && machine.DB != nil {
		if s := machine.DB.GetConfig("video_scale", ""); s != "" {
			if v, err := strconv.Atoi(s); err == nil && v >= 1 && v <= 4 {
				scale = v
			}
		}
		if a := machine.DB.GetConfig("aspect_ratio_43", ""); a != "" {
			aspect43 = (a == "true" || a == "1")
		}
		if b := machine.DB.GetConfig("bilinear_filter", ""); b != "" {
			smooth = (b == "true" || b == "1")
		}
		if cs := machine.DB.GetConfig("crt_scanlines", ""); cs != "" {
			if v, err := strconv.Atoi(cs); err == nil && v >= 0 && v <= 2 {
				crtScanlines = v
			}
		}
		if pm := machine.DB.GetConfig("phosphor_mode", ""); pm != "" {
			if v, err := strconv.Atoi(pm); err == nil && v >= 0 && v <= 2 {
				phosphorMode = v
			}
		}
		ctrlCfg.Load(machine.DB)
	}

	var audioDev *sound.AudioDevice
	if machine != nil && machine.Mixer != nil {
		audioDev, _ = sound.InitAudioDevice(machine.Mixer)
	}

	ui := &UI{
		Machine:           machine,
		AudioDevice:       audioDev,
		msxScreenImg:      ebiten.NewImage(vdp.DisplayWidth, vdp.DisplayHeight),
		DisplayMode:       0,
		VideoScale:        scale,
		AspectRatio43:     aspect43,
		BilinearFilter:    smooth,
		CRTScanlines:      crtScanlines,
		PhosphorMode:      phosphorMode,
		ControllerConfig:  ctrlCfg,
		audioDebugEnabled: os.Getenv("FMSXGO_AUDIO_DEBUG") != "",
	}

	ui.ApplyTheme()
	ui.updateScanlines()
	return ui
}

// ApplyTheme re-skins all UI buffers using the currently active theme.
func (u *UI) ApplyTheme() {
	eff := theme.GetEffective()

	// 1. Top menu bar (wide buffer to cover high-res windows)
	if u.barImg == nil {
		u.barImg = ebiten.NewImage(2048, MenuBarH)
	}
	u.barImg.Fill(eff.MenuBarBg)

	// 2. Dropdown menu background (Setup: Config, Controllers, Catalog)
	if u.menuBg == nil {
		u.menuBg = ebiten.NewImage(260, 95)
	}
	u.menuBg.Fill(eff.MenuDropdownBg)

	// 2b. File dropdown menu background (Save, Load, Reset, CLI, Exit)
	if u.fileMenuBg == nil {
		u.fileMenuBg = ebiten.NewImage(230, 155)
	}
	u.fileMenuBg.Fill(eff.MenuDropdownBg)

	// 2c. Hardware dropdown menu background (MSX1, MSX2, MSX2+, sep, NTSC, PAL, reset)
	if u.hardwareMenuBg == nil {
		u.hardwareMenuBg = ebiten.NewImage(230, 160)
	}
	u.hardwareMenuBg.Fill(eff.MenuDropdownBg)

	// 2d. Video dropdown menu background (Scales, Aspect, Bilinear, Scanlines, Phosphor)
	if u.videoMenuBg == nil {
		u.videoMenuBg = ebiten.NewImage(270, 360)
	}
	u.videoMenuBg.Fill(eff.MenuDropdownBg)

	// 2e. Media dropdown menu background (Drives A/B, Carts 1/2, Tape)
	if u.mediaMenuBg == nil {
		u.mediaMenuBg = ebiten.NewImage(290, 315)
	}
	u.mediaMenuBg.Fill(eff.MenuDropdownBg)

	// 2f. Debug dropdown menu background (260 x 160)
	if u.debugMenuBg == nil {
		u.debugMenuBg = ebiten.NewImage(260, 160)
	}
	u.debugMenuBg.Fill(eff.MenuDropdownBg)

	// 3. Screen background
	if u.screenBg == nil {
		u.screenBg = ebiten.NewImage(2048, 2048)
	}
	u.screenBg.Fill(eff.ScreenBg)

	// 4. About Dialog background
	if u.dialogBg == nil {
		u.dialogBg = ebiten.NewImage(440, 230)
	}
	u.dialogBg.Fill(eff.DialogBg)

	// 5. Configuration Dialog background (600 x 420 for 3 columns: Lang, Theme, Font)
	if u.configDlgBg == nil {
		u.configDlgBg = ebiten.NewImage(600, 420)
	}
	u.configDlgBg.Fill(eff.DialogBg)

	// 5b. Catalog Dialog background (620 x 440)
	if u.catalogDlgBg == nil {
		u.catalogDlgBg = ebiten.NewImage(620, 440)
	}
	u.catalogDlgBg.Fill(eff.DialogBg)

	// 5c. File Picker Dialog background (620 x 440)
	if u.pickerDlgBg == nil {
		u.pickerDlgBg = ebiten.NewImage(620, 440)
	}
	u.pickerDlgBg.Fill(eff.DialogBg)

	// 5d. Workstation Dialog background (620 x 440)
	if u.workstationDlgBg == nil {
		u.workstationDlgBg = ebiten.NewImage(620, 440)
	}
	u.workstationDlgBg.Fill(eff.DialogBg)

	// 6. Action button
	if u.buttonBg == nil {
		u.buttonBg = ebiten.NewImage(180, 28)
	}
	u.buttonBg.Fill(eff.ButtonBg)

	// 7. Selected row highlight pill
	if u.selectedRowBg == nil {
		u.selectedRowBg = ebiten.NewImage(260, 22)
	}
	u.selectedRowBg.Fill(eff.SelectedBg)
}

// SetScale changes the display scale (1=1:1, 2=2:1, 3=3:1, 4=4:1) and adjusts the window.
func (u *UI) SetScale(scale int) {
	if scale < 1 {
		scale = 1
	}
	if scale > 4 {
		scale = 4
	}
	u.VideoScale = scale
	u.applyWindowResize()
	if u.Machine != nil && u.Machine.DB != nil {
		_ = u.Machine.DB.SetConfig("video_scale", strconv.Itoa(scale))
	}
}

// SetAspectRatio43 enables or disables the forced 4:3 CRT TV aspect ratio.
func (u *UI) SetAspectRatio43(force43 bool) {
	u.AspectRatio43 = force43
	u.applyWindowResize()
	if u.Machine != nil && u.Machine.DB != nil {
		_ = u.Machine.DB.SetConfig("aspect_ratio_43", strconv.FormatBool(force43))
	}
}

// SetBilinearFilter toggles smooth linear interpolation.
func (u *UI) SetBilinearFilter(smooth bool) {
	u.BilinearFilter = smooth
	if u.Machine != nil && u.Machine.DB != nil {
		_ = u.Machine.DB.SetConfig("bilinear_filter", strconv.FormatBool(smooth))
	}
}

// updateScanlines regenerates the CRT scanlines overlay texture.
func (u *UI) updateScanlines() {
	if u.scanlineImg == nil || u.scanlineImg.Bounds().Dx() != vdp.DisplayWidth || u.scanlineImg.Bounds().Dy() != vdp.DisplayHeight {
		u.scanlineImg = ebiten.NewImage(vdp.DisplayWidth, vdp.DisplayHeight)
	}
	u.scanlineImg.Clear()
	if u.CRTScanlines == 0 {
		return
	}
	alpha := uint8(75) // Light
	if u.CRTScanlines == 2 {
		alpha = 140 // Medium
	}
	lineBytes := make([]byte, vdp.DisplayWidth*4)
	for x := 0; x < vdp.DisplayWidth; x++ {
		lineBytes[x*4+3] = alpha // Black pixel with alpha
	}
	pix := make([]byte, vdp.DisplayWidth*vdp.DisplayHeight*4)
	for y := 0; y < vdp.DisplayHeight; y++ {
		if y%2 == 1 {
			copy(pix[y*vdp.DisplayWidth*4:(y+1)*vdp.DisplayWidth*4], lineBytes)
		}
	}
	u.scanlineImg.WritePixels(pix)
}

// SetCRTScanlines sets the scanline overlay intensity (0: Off, 1: Light, 2: Medium).
func (u *UI) SetCRTScanlines(mode int) {
	u.CRTScanlines = mode
	u.updateScanlines()
	if u.Machine != nil && u.Machine.DB != nil {
		_ = u.Machine.DB.SetConfig("crt_scanlines", strconv.Itoa(mode))
	}
}

// SetPhosphorMode sets the CRT monitor phosphor simulation (0: Color, 1: Green, 2: Amber).
func (u *UI) SetPhosphorMode(mode int) {
	u.PhosphorMode = mode
	if u.Machine != nil && u.Machine.DB != nil {
		_ = u.Machine.DB.SetConfig("phosphor_mode", strconv.Itoa(mode))
	}
}

func (u *UI) applyWindowResize() {
	targetH := u.VideoScale * 212
	var targetW int
	if u.AspectRatio43 {
		targetW = (targetH * 4) / 3
	} else {
		targetW = u.VideoScale * 256
	}
	winW := targetW
	if winW < 640 {
		winW = 640
	}
	winH := targetH + MenuBarH
	if winH < 480 {
		winH = 480
	}
	ebiten.SetWindowSize(winW, winH)
}

// Run launches the Ebitengine graphical window.
func (u *UI) Run() error {
	u.applyWindowResize()
	ebiten.SetWindowTitle("fMSXgo - MSX Emulator & Developer Workstation (64-bit)")
	ebiten.SetWindowResizingMode(ebiten.WindowResizingModeEnabled)

	targetTPS := 60
	if u.Machine != nil && u.Machine.Config.Video == msx.VideoPAL {
		targetTPS = 50
	}
	ebiten.SetTPS(targetTPS)
	u.currentTPS = targetTPS

	return ebiten.RunGame(u)
}

// syncTPSToVDP keeps Ebitengine's logical tick rate (which paces how often
// StepFrame() actually runs in real time) aligned with the video field rate
// the VDP is really running at.
//
// Config.Video only reflects the user's menu selection / boot config; the
// VDP's actual PAL/NTSC state (VDP.Regs[9] bit 1, mirrored in TotalLines) is
// set independently by the BIOS ROM at boot and can disagree with it (e.g. a
// PAL-region BIOS will put the VDP in 313-line/50Hz mode even when Config.Video
// requested NTSC). machine.go's own audio pacing already accounts for this
// (see the "totalLines > 280" check in StepScanline), generating exactly
// 1/50s of PCM per StepFrame() call in that case. But if ebiten keeps calling
// StepFrame() 60 times/sec regardless, that's 60 * (1/50s) = 1.2x too much
// audio generated per real second, which the mixer's ring buffer can't
// absorb once it fills — it has to continuously drop samples to keep up.
// That mismatch (not GC, not the scanline batching itself) is what was
// making PLAY sound clipped/rushed: video and audio were both being stepped
// 20% faster than the wall clock the mixer/audio driver actually plays at.
func (u *UI) syncTPSToVDP() {
	if u.Machine == nil || u.Machine.VDP == nil {
		return
	}
	want := 60
	if u.Machine.Config.Video == msx.VideoPAL || u.Machine.VDP.TotalLines > 280 {
		want = 50
	}
	if want != u.currentTPS {
		ebiten.SetTPS(want)
		u.currentTPS = want
	}
}

// Update handles frame logic and input.
func (u *UI) Update() error {
	if u.ShouldExit {
		return ebiten.Termination
	}

	// F11 toggles Display Mode between MSX Screen (0) and Debug Status Overlay (1)
	if inpututil.IsKeyJustPressed(ebiten.KeyF11) {
		u.DisplayMode = 1 - u.DisplayMode
		return nil
	}

	// F9: Toggle Developer / Hacker Workstation
	if inpututil.IsKeyJustPressed(ebiten.KeyF9) {
		u.ShowHackerWorkstation = !u.ShowHackerWorkstation
		if u.ShowHackerWorkstation {
			u.EmulationPaused = true
		}
		return nil
	}

	// F10: Single Step CPU instruction
	if inpututil.IsKeyJustPressed(ebiten.KeyF10) {
		if u.Machine != nil {
			u.EmulationPaused = true
			u.Machine.Step()
			fb := u.Machine.GetFrameBuffer()
			if fb != nil && u.msxScreenImg != nil {
				u.msxScreenImg.WritePixels(fb)
			}
		}
		return nil
	}

	// F5: Toggle Emulation Pause / Run
	if inpututil.IsKeyJustPressed(ebiten.KeyF5) {
		u.EmulationPaused = !u.EmulationPaused
		return nil
	}

	// Developer Workstation keys when modal is open
	if u.ShowHackerWorkstation {
		if inpututil.IsKeyJustPressed(ebiten.KeyDigit1) {
			u.HackerTab = 0
		} else if inpututil.IsKeyJustPressed(ebiten.KeyDigit2) {
			u.HackerTab = 1
		} else if inpututil.IsKeyJustPressed(ebiten.KeyDigit3) {
			u.HackerTab = 2
		} else if inpututil.IsKeyJustPressed(ebiten.KeyDigit4) {
			u.HackerTab = 3
		} else if inpututil.IsKeyJustPressed(ebiten.KeyDigit5) {
			u.HackerTab = 4
		} else if inpututil.IsKeyJustPressed(ebiten.KeyUp) {
			if u.WorkstationHexAddr >= 16 {
				u.WorkstationHexAddr -= 16
			}
		} else if inpututil.IsKeyJustPressed(ebiten.KeyDown) {
			u.WorkstationHexAddr += 16
		} else if inpututil.IsKeyJustPressed(ebiten.KeyPageUp) {
			if u.WorkstationHexAddr >= 128 {
				u.WorkstationHexAddr -= 128
			}
		} else if inpututil.IsKeyJustPressed(ebiten.KeyPageDown) {
			u.WorkstationHexAddr += 128
		} else if inpututil.IsKeyJustPressed(ebiten.KeyV) {
			u.WorkstationHexVRAM = !u.WorkstationHexVRAM
		} else if inpututil.IsKeyJustPressed(ebiten.KeyC) {
			if u.Machine != nil && u.Machine.CPU != nil {
				u.Machine.CPU.ClearHistory()
			}
		}
	}

	// F7: Quick Save State (compatible with fMSX .sta)
	if inpututil.IsKeyJustPressed(ebiten.KeyF7) {
		if u.Machine != nil {
			if err := u.Machine.SaveSTA("fmsxgo_quick.sta"); err != nil {
				fmt.Printf("[fMSXgo] Quick Save State error: %v\n", err)
			} else {
				fmt.Println("[fMSXgo] Emulation state saved to 'fmsxgo_quick.sta' (F7)")
			}
		}
		return nil
	}

	// F8: Quick Load State (compatible with fMSX .sta)
	if inpututil.IsKeyJustPressed(ebiten.KeyF8) {
		if u.Machine != nil {
			if err := u.Machine.LoadSTA("fmsxgo_quick.sta"); err != nil {
				fmt.Printf("[fMSXgo] Quick Load State error: %v\n", err)
			} else {
				fmt.Println("[fMSXgo] Emulation state restored from 'fmsxgo_quick.sta' (F8)")
			}
		}
		return nil
	}

	// Escape key handling
	if inpututil.IsKeyJustPressed(ebiten.KeyEscape) {
		if u.ShowHackerWorkstation {
			u.ShowHackerWorkstation = false
			return nil
		}
		if u.ShowPicker {
			u.ShowPicker = false
			return nil
		}
		if u.ShowCatalog {
			u.ShowCatalog = false
			return nil
		}
		if u.ShowConfig {
			u.ShowConfig = false
			return nil
		}
		if u.ShowControllerConfig {
			u.ShowControllerConfig = false
			return nil
		}
		if u.ShowAbout {
			u.ShowAbout = false
			return nil
		}
		if u.ActiveMenu != "" {
			u.ActiveMenu = ""
			return nil
		}
		return ebiten.Termination
	}

	// Mouse wheel handling for File Picker modal
	if u.ShowPicker {
		_, wy := ebiten.Wheel()
		if wy > 0 && u.PickerScroll > 0 {
			u.PickerScroll--
		} else if wy < 0 && u.PickerScroll+9 < len(u.PickerFiles) {
			u.PickerScroll++
		}
	}

	// Handle mouse clicks
	if inpututil.IsMouseButtonJustPressed(ebiten.MouseButtonLeft) {
		mx, my := ebiten.CursorPosition()
		u.handleClick(mx, my)
	}

	// Advance MSX emulation frame if not paused
	if u.Machine != nil && !u.EmulationPaused {
		u.syncTPSToVDP()
		u.updateKeyboard()
		u.updateJoysticksAndMouse()
		u.Machine.StepFrame()
		fb := u.Machine.GetFrameBuffer()
		if fb != nil && u.msxScreenImg != nil {
			u.msxScreenImg.WritePixels(fb)
		}

		// DEBUG: audio/timing diagnostics, printed once/sec of WALL-CLOCK time
		// (not assumed frame count). Underruns mean production fell behind
		// real-time playback (buffer ran dry); overruns mean production ran
		// ahead and had to drop old samples. Off by default; enable by
		// setting FMSXGO_AUDIO_DEBUG in the environment.
		if u.audioDebugEnabled {
			u.audioStatsFrameCount++
			if u.audioStatsLastReport.IsZero() {
				u.audioStatsLastReport = time.Now()
				if u.Machine.Mixer != nil {
					u.audioStatsLastGen = u.Machine.Mixer.TotalGenerated()
				}
			}
			if elapsed := time.Since(u.audioStatsLastReport); elapsed >= time.Second {
				vdpInfo := "no-vdp"
				if u.Machine.VDP != nil {
					vdpInfo = fmt.Sprintf("VDP.TotalLines=%d PAL=%v", u.Machine.VDP.TotalLines, u.Machine.VDP.PALVideo())
				}
				realFPS := float64(u.audioStatsFrameCount) / elapsed.Seconds()
				if u.Machine.Mixer != nil {
					underEv, underBytes, over := u.Machine.Mixer.Stats()
					gen := u.Machine.Mixer.TotalGenerated()
					genRate := float64(gen-u.audioStatsLastGen) / elapsed.Seconds()
					genCalls, genMaxSamples, readCalls, readMinLen, readMaxLen := u.Machine.Mixer.CallStats()
					fmt.Printf("[fMSXgo][audio] elapsed=%v StepFrame_calls=%d realFPS=%.2f currentTPS=%d %s sampleRate_target=%d actual_gen_rate=%.1fHz underruns=%d(%dB) overruns=%d buffered=%dB | genCalls=%d genMaxSamples=%d readCalls=%d readLen=[%d..%d]\n",
						elapsed, u.audioStatsFrameCount, realFPS, u.currentTPS, vdpInfo,
						u.Machine.Mixer.SampleRate, genRate, underEv, underBytes, over, u.Machine.Mixer.Available(),
						genCalls, genMaxSamples, readCalls, readMinLen, readMaxLen)
					u.Machine.Mixer.ResetStats()
					u.Machine.Mixer.ResetCallStats()
					u.audioStatsLastGen = gen
				}
				u.audioStatsFrameCount = 0
				u.audioStatsLastReport = time.Now()
			}
		}
	}

	return nil
}

func (u *UI) handleClick(x, y int) {
	// -3. If Controller Configuration dialog is open, handle its interactions
	if u.ShowControllerConfig {
		u.handleControllerClick(x, y)
		return
	}

	// -2. If Hacker Workstation is open, handle its interactions
	if u.ShowHackerWorkstation {
		u.handleWorkstationClick(x, y)
		return
	}

	// -1. If File Picker dialog is open, handle its interactions
	if u.ShowPicker {
		u.handlePickerClick(x, y)
		return
	}

	// 0. If Catalog dialog is open, handle its interactions
	if u.ShowCatalog {
		u.handleCatalogClick(x, y)
		return
	}

	// 1. If Configuration dialog is open, handle its interactions
	if u.ShowConfig {
		u.handleConfigClick(x, y)
		return
	}

	// 2. If About dialog is open, click anywhere closes it
	if u.ShowAbout {
		u.ShowAbout = false
		return
	}

	winW := u.currWinW
	if winW < 640 {
		winW = 640
	}

	// 3. Click on top menu bar
	if y < MenuBarH {
		if x >= 10 && x < 65 {
			if u.ActiveMenu == "File" {
				u.ActiveMenu = ""
			} else {
				u.ActiveMenu = "File"
			}
			return
		} else if x >= 65 && x < 145 {
			if u.ActiveMenu == "Hardware" {
				u.ActiveMenu = ""
			} else {
				u.ActiveMenu = "Hardware"
			}
			return
		} else if x >= 145 && x < 205 {
			if u.ActiveMenu == "Video" {
				u.ActiveMenu = ""
			} else {
				u.ActiveMenu = "Video"
			}
			return
		} else if x >= 205 && x < 265 {
			if u.ActiveMenu == "Media" {
				u.ActiveMenu = ""
			} else {
				u.ActiveMenu = "Media"
			}
			return
		} else if x >= 265 && x < 325 {
			if u.ActiveMenu == "Debug" {
				u.ActiveMenu = ""
			} else {
				u.ActiveMenu = "Debug"
			}
			return
		} else if x >= 325 && x < 390 {
			if u.ActiveMenu == "Setup" {
				u.ActiveMenu = ""
			} else {
				u.ActiveMenu = "Setup"
			}
			return
		} else if x >= 390 && x < 450 {
			if u.ActiveMenu == "Help" {
				u.ActiveMenu = ""
			} else {
				u.ActiveMenu = "Help"
			}
			return
		} else if x >= winW-315 && x < winW-150 {
			u.ShowHackerWorkstation = !u.ShowHackerWorkstation
			if u.ShowHackerWorkstation {
				u.EmulationPaused = true
			}
			u.ActiveMenu = ""
			return
		} else if x >= winW-150 && x <= winW-10 {
			u.DisplayMode = 1 - u.DisplayMode
			u.ActiveMenu = ""
			return
		} else {
			u.ActiveMenu = ""
		}
	}

	// 4. Click on File dropdown
	if u.ActiveMenu == "File" {
		if x >= 10 && x <= 240 {
			if y >= MenuBarH+2 && y < MenuBarH+26 {
				// Save State...
				u.ActiveMenu = ""
				u.OpenFilePicker(PickerSaveState)
				return
			} else if y >= MenuBarH+26 && y < MenuBarH+50 {
				// Load State...
				u.ActiveMenu = ""
				u.OpenFilePicker(PickerLoadState)
				return
			} else if y >= MenuBarH+58 && y < MenuBarH+84 {
				// Reset Machine
				u.ActiveMenu = ""
				u.Machine.Reset()
				return
			} else if y >= MenuBarH+84 && y < MenuBarH+114 {
				// Launch / Activate CLI
				u.ActiveMenu = ""
				u.ActivateCLI()
				return
			} else if y >= MenuBarH+114 && y < MenuBarH+150 {
				// Exit
				u.ShouldExit = true
				return
			}
		}
		u.ActiveMenu = ""
		return
	}

	// 4b. Click on Hardware dropdown
	if u.ActiveMenu == "Hardware" {
		if x >= 70 && x <= 300 {
			if y >= MenuBarH+2 && y < MenuBarH+28 {
				// Switch to MSX 1
				u.ActiveMenu = ""
				_ = u.Machine.SwitchModel(msx.ModelMSX1)
				return
			} else if y >= MenuBarH+28 && y < MenuBarH+54 {
				// Switch to MSX 2
				u.ActiveMenu = ""
				_ = u.Machine.SwitchModel(msx.ModelMSX2)
				return
			} else if y >= MenuBarH+54 && y < MenuBarH+80 {
				// Switch to MSX 2+
				u.ActiveMenu = ""
				_ = u.Machine.SwitchModel(msx.ModelMSX2P)
				return
			} else if y >= MenuBarH+85 && y < MenuBarH+110 {
				// NTSC (60Hz)
				u.ActiveMenu = ""
				u.Machine.Config.Video = msx.VideoNTSC
				ebiten.SetTPS(60)
				u.currentTPS = 60
				u.Machine.Reset()
				return
			} else if y >= MenuBarH+110 && y < MenuBarH+136 {
				// PAL (50Hz)
				u.ActiveMenu = ""
				u.Machine.Config.Video = msx.VideoPAL
				ebiten.SetTPS(50)
				u.currentTPS = 50
				u.Machine.Reset()
				return
			} else if y >= MenuBarH+136 && y < MenuBarH+160 {
				// Reset Machine
				u.ActiveMenu = ""
				u.Machine.Reset()
				return
			}
		}
		u.ActiveMenu = ""
		return
	}

	// 4c. Click on Video dropdown
	if u.ActiveMenu == "Video" {
		if x >= 160 && x <= 420 {
			if y >= MenuBarH+2 && y < MenuBarH+26 {
				u.ActiveMenu = ""
				u.SetScale(1)
				return
			} else if y >= MenuBarH+26 && y < MenuBarH+50 {
				u.ActiveMenu = ""
				u.SetScale(2)
				return
			} else if y >= MenuBarH+50 && y < MenuBarH+74 {
				u.ActiveMenu = ""
				u.SetScale(3)
				return
			} else if y >= MenuBarH+74 && y < MenuBarH+98 {
				u.ActiveMenu = ""
				u.SetScale(4)
				return
			} else if y >= MenuBarH+108 && y < MenuBarH+132 {
				u.ActiveMenu = ""
				u.SetAspectRatio43(false)
				return
			} else if y >= MenuBarH+132 && y < MenuBarH+156 {
				u.ActiveMenu = ""
				u.SetAspectRatio43(true)
				return
			} else if y >= MenuBarH+166 && y < MenuBarH+192 {
				u.ActiveMenu = ""
				u.SetBilinearFilter(!u.BilinearFilter)
				return
			} else if y >= MenuBarH+200 && y < MenuBarH+222 {
				u.ActiveMenu = ""
				u.SetCRTScanlines(0) // Scanlines Off
				return
			} else if y >= MenuBarH+222 && y < MenuBarH+244 {
				u.ActiveMenu = ""
				u.SetCRTScanlines(1) // Scanlines Light
				return
			} else if y >= MenuBarH+244 && y < MenuBarH+266 {
				u.ActiveMenu = ""
				u.SetCRTScanlines(2) // Scanlines Medium
				return
			} else if y >= MenuBarH+276 && y < MenuBarH+298 {
				u.ActiveMenu = ""
				u.SetPhosphorMode(0) // Color RGB
				return
			} else if y >= MenuBarH+298 && y < MenuBarH+320 {
				u.ActiveMenu = ""
				u.SetPhosphorMode(1) // Green CRT
				return
			} else if y >= MenuBarH+320 && y < MenuBarH+345 {
				u.ActiveMenu = ""
				u.SetPhosphorMode(2) // Amber CRT
				return
			}
		}
		u.ActiveMenu = ""
		return
	}

	// 4d. Click on Media dropdown
	if u.ActiveMenu == "Media" {
		if x >= 205 && x <= 495 {
			if y >= MenuBarH+22 && y < MenuBarH+42 {
				// Insert Disk A (.dsk)
				u.ActiveMenu = ""
				u.OpenFilePicker(PickerDriveA)
				return
			} else if y >= MenuBarH+42 && y < MenuBarH+60 {
				// Eject Disk A
				u.ActiveMenu = ""
				u.Machine.EjectDisk(0)
				return
			} else if y >= MenuBarH+78 && y < MenuBarH+98 {
				// Insert Disk B (.dsk)
				u.ActiveMenu = ""
				u.OpenFilePicker(PickerDriveB)
				return
			} else if y >= MenuBarH+98 && y < MenuBarH+116 {
				// Eject Disk B
				u.ActiveMenu = ""
				u.Machine.EjectDisk(1)
				return
			} else if y >= MenuBarH+144 && y < MenuBarH+164 {
				// Insert Cartridge 1 (.rom)
				u.ActiveMenu = ""
				u.OpenFilePicker(PickerCart1)
				return
			} else if y >= MenuBarH+164 && y < MenuBarH+182 {
				// Eject Cartridge 1
				u.ActiveMenu = ""
				u.Machine.EjectCartridge(1)
				return
			} else if y >= MenuBarH+200 && y < MenuBarH+220 {
				// Insert Cartridge 2 (.rom)
				u.ActiveMenu = ""
				u.OpenFilePicker(PickerCart2)
				return
			} else if y >= MenuBarH+220 && y < MenuBarH+238 {
				// Eject Cartridge 2
				u.ActiveMenu = ""
				u.Machine.EjectCartridge(2)
				return
			} else if y >= MenuBarH+266 && y < MenuBarH+286 {
				// Insert Tape (.cas)
				u.ActiveMenu = ""
				u.OpenFilePicker(PickerTape)
				return
			} else if y >= MenuBarH+286 && y < MenuBarH+312 {
				u.ActiveMenu = ""
				if x < 350 {
					// Eject Tape
					u.Machine.EjectTape()
				} else {
					// Rewind Tape
					u.Machine.RewindTape()
				}
				return
			}
		}
		u.ActiveMenu = ""
		return
	}

	// 4e. Click on Debug dropdown
	if u.ActiveMenu == "Debug" {
		if x >= 265 && x <= 525 {
			if y >= MenuBarH+6 && y < MenuBarH+30 {
				u.ActiveMenu = ""
				u.ShowHackerWorkstation = true
				u.EmulationPaused = true
				return
			} else if y >= MenuBarH+30 && y < MenuBarH+54 {
				u.ActiveMenu = ""
				u.EmulationPaused = true
				u.Machine.Step()
				fb := u.Machine.GetFrameBuffer()
				if fb != nil && u.msxScreenImg != nil {
					u.msxScreenImg.WritePixels(fb)
				}
				return
			} else if y >= MenuBarH+54 && y < MenuBarH+78 {
				u.ActiveMenu = ""
				u.EmulationPaused = !u.EmulationPaused
				return
			} else if y >= MenuBarH+86 && y < MenuBarH+110 {
				u.ActiveMenu = ""
				if u.Machine.Debugger != nil {
					u.Machine.Debugger.Clear()
				}
				return
			} else if y >= MenuBarH+110 && y < MenuBarH+134 {
				u.ActiveMenu = ""
				if u.Machine.CPU != nil {
					u.Machine.CPU.ClearHistory()
				}
				return
			}
		}
		u.ActiveMenu = ""
		return
	}

	// 5. Click on Setup dropdown
	if u.ActiveMenu == "Setup" {
		if x >= 265 && x <= 535 {
			if y >= MenuBarH && y < MenuBarH+28 {
				// Open Configuration (Language, Theme, Font)
				u.ActiveMenu = ""
				u.ShowConfig = true
				return
			} else if y >= MenuBarH+28 && y < MenuBarH+56 {
				// Open Controllers & Joystick Calibration Modal
				u.ActiveMenu = ""
				u.ShowControllerConfig = true
				return
			} else if y >= MenuBarH+56 && y < MenuBarH+90 {
				// Open ROM & Hardware Catalog Modal
				u.ActiveMenu = ""
				u.ShowCatalog = true
				return
			}
		}
		u.ActiveMenu = ""
		return
	}

	// 6. Click on Help dropdown
	if u.ActiveMenu == "Help" {
		if x >= 360 && x <= 590 && y >= MenuBarH && y < MenuBarH+35 {
			u.ActiveMenu = ""
			u.ShowAbout = true
			return
		}
		u.ActiveMenu = ""
		return
	}

	u.ActiveMenu = ""
}

func (u *UI) handleConfigClick(x, y int) {
	winW := u.currWinW
	if winW < 620 {
		winW = 620
	}
	winH := u.currWinH
	if winH < 450 {
		winH = 450
	}
	diagX := (winW - 600) / 2
	diagY := (winH - 420) / 2

	// Click outside modal closes it
	if x < diagX || x > diagX+600 || y < diagY || y > diagY+420 {
		u.ShowConfig = false
		return
	}

	// Click on Save & Close Button (center)
	if x >= diagX+210 && x <= diagX+390 && y >= diagY+380 && y <= diagY+410 {
		u.ShowConfig = false
		return
	}

	// Column 1: Language items (x: diagX+10 .. diagX+175)
	if x >= diagX+10 && x <= diagX+175 {
		startY := diagY + 75
		for i, l := range i18n.SupportedLanguages {
			itemY := startY + (i * 26)
			if y >= itemY && y < itemY+24 {
				i18n.SetLanguage(l.Code)
				if u.Machine != nil && u.Machine.DB != nil {
					_ = u.Machine.DB.SetConfig("language", l.Code)
				}
				return
			}
		}
	}

	// Column 2: Theme items (x: diagX+180 .. diagX+390)
	if x >= diagX+180 && x <= diagX+390 {
		startY := diagY + 75
		themes := theme.List()
		for i, th := range themes {
			itemY := startY + (i * 25)
			if y >= itemY && y < itemY+24 {
				theme.SetCurrent(th.ID)
				u.ApplyTheme()
				if u.Machine != nil && u.Machine.DB != nil {
					_ = u.Machine.DB.SetConfig("theme", th.ID)
				}
				return
			}
		}
	}

	// Column 3: Font items (x: diagX+395 .. diagX+590)
	if x >= diagX+395 && x <= diagX+590 {
		startY := diagY + 75
		fonts := font.ListFamilies()
		for i, f := range fonts {
			if i >= 11 {
				break
			}
			itemY := startY + (i * 25)
			if y >= itemY && y < itemY+24 {
				font.SetCurrent(f.ID)
				if u.Machine != nil && u.Machine.DB != nil {
					_ = u.Machine.DB.SetConfig("font", f.ID)
				}
				return
			}
		}
	}
}

// Draw renders the full GUI window.
func (u *UI) Draw(screen *ebiten.Image) {
	eff := theme.GetEffective()
	bounds := screen.Bounds()
	winW := bounds.Dx()
	winH := bounds.Dy()

	// 1. Draw Screen Background (workstation monitor area)
	screenOp := &ebiten.DrawImageOptions{}
	screenOp.GeoM.Translate(0, MenuBarH)
	screen.DrawImage(u.screenBg, screenOp)

	if u.DisplayMode == 0 && u.msxScreenImg != nil {
		availW := winW
		availH := winH - MenuBarH

		targetH := u.VideoScale * vdp.DisplayHeight
		var targetW int
		if u.AspectRatio43 {
			targetW = (targetH * 4) / 3
		} else {
			targetW = (targetH * vdp.DisplayWidth) / vdp.DisplayHeight
		}

		// Scale down to fit if window was manually shrunk smaller than preset
		if targetW > availW || targetH > availH {
			aspect := float64(targetW) / float64(targetH)
			if float64(availW)/float64(availH) > aspect {
				targetH = availH
				targetW = int(float64(targetH) * aspect)
			} else {
				targetW = availW
				targetH = int(float64(targetW) / aspect)
			}
		}

		destX := (availW - targetW) / 2
		destY := MenuBarH + (availH - targetH) / 2

		msxOp := &ebiten.DrawImageOptions{}
		scaleX := float64(targetW) / float64(vdp.DisplayWidth)
		scaleY := float64(targetH) / float64(vdp.DisplayHeight)
		msxOp.GeoM.Scale(scaleX, scaleY)
		msxOp.GeoM.Translate(float64(destX), float64(destY))
		if u.BilinearFilter || u.AspectRatio43 || scaleX != float64(int(scaleX)) {
			msxOp.Filter = ebiten.FilterLinear
		}

		// Phosphor color simulation (P1 Green or Amber CRT)
		if u.PhosphorMode == 1 {
			var cm ebiten.ColorM
			cm.ChangeHSV(0, 0, 1)
			cm.Scale(0.25, 1.0, 0.25, 1.0)
			msxOp.ColorM = cm
		} else if u.PhosphorMode == 2 {
			var cm ebiten.ColorM
			cm.ChangeHSV(0, 0, 1)
			cm.Scale(1.0, 0.72, 0.15, 1.0)
			msxOp.ColorM = cm
		}

		screen.DrawImage(u.msxScreenImg, msxOp)

		// CRT Scanlines overlay
		if u.CRTScanlines > 0 && u.scanlineImg != nil {
			scanOp := &ebiten.DrawImageOptions{}
			scanOp.GeoM = msxOp.GeoM
			screen.DrawImage(u.scanlineImg, scanOp)
		}
	} else {
		// Draw Machine Status / Developer Debug Overlay
		u.drawStatus(screen)
	}

	// 2. Draw Top Menu Bar
	barOp := &ebiten.DrawImageOptions{}
	screen.DrawImage(u.barImg, barOp)

	// Draw Menu text labels (antialiased TrueType)
	font.DrawBold(screen, i18n.T("menu_file"), 14, 5, 13, eff.MenuBarText)
	font.DrawBold(screen, i18n.T("menu_hardware"), 70, 5, 13, eff.MenuBarText)
	font.DrawBold(screen, i18n.T("menu_video"), 150, 5, 13, eff.MenuBarText)
	font.DrawBold(screen, i18n.T("menu_media"), 205, 5, 13, eff.MenuBarText)
	font.DrawBold(screen, "Debug", 265, 5, 13, eff.MenuBarText)
	font.DrawBold(screen, i18n.T("menu_setup"), 325, 5, 13, eff.MenuBarText)
	font.DrawBold(screen, i18n.T("menu_help"), 390, 5, 13, eff.MenuBarText)

	// Display mode badges on the right
	font.DrawCode(screen, "[ F9: Workstation ]", float64(winW-310), 5, 12, eff.MenuBarText)

	badgeText := "[ F11: Screen ]"
	if u.DisplayMode == 1 {
		badgeText = "[ F11: Debug ]"
	}
	font.DrawCode(screen, badgeText, float64(winW-145), 5, 12, eff.AccentColor)

	// 3. Draw Active Dropdown Menu
	if u.ActiveMenu == "File" {
		dropOp := &ebiten.DrawImageOptions{}
		dropOp.GeoM.Translate(10, MenuBarH)
		screen.DrawImage(u.fileMenuBg, dropOp)
		font.Draw(screen, i18n.T("menu_save_state"), 18, MenuBarH+6, 12, eff.MenuDropdownText)
		font.Draw(screen, i18n.T("menu_load_state"), 18, MenuBarH+30, 12, eff.MenuDropdownText)
		font.Draw(screen, "--------------------------", 18, MenuBarH+46, 10, eff.StatusLabel)
		font.Draw(screen, i18n.T("menu_reset"), 18, MenuBarH+62, 12, eff.MenuDropdownText)
		font.Draw(screen, i18n.T("menu_cli"), 18, MenuBarH+90, 12, eff.MenuDropdownText)
		font.Draw(screen, i18n.T("menu_exit"), 18, MenuBarH+120, 12, eff.MenuDropdownText)
	} else if u.ActiveMenu == "Hardware" {
		dropOp := &ebiten.DrawImageOptions{}
		dropOp.GeoM.Translate(70, MenuBarH)
		screen.DrawImage(u.hardwareMenuBg, dropOp)

		chk1 := "   "
		if u.Machine.Config.Model == msx.ModelMSX1 {
			chk1 = "✓ "
		}
		chk2 := "   "
		if u.Machine.Config.Model == msx.ModelMSX2 {
			chk2 = "✓ "
		}
		chk2p := "   "
		if u.Machine.Config.Model == msx.ModelMSX2P {
			chk2p = "✓ "
		}
		chkNtsc := "   "
		if u.Machine.Config.Video == msx.VideoNTSC {
			chkNtsc = "✓ "
		}
		chkPal := "   "
		if u.Machine.Config.Video == msx.VideoPAL {
			chkPal = "✓ "
		}

		font.Draw(screen, chk1+i18n.T("lbl_msx1"), 78, MenuBarH+6, 13, eff.MenuDropdownText)
		font.Draw(screen, chk2+i18n.T("lbl_msx2"), 78, MenuBarH+32, 13, eff.MenuDropdownText)
		font.Draw(screen, chk2p+i18n.T("lbl_msx2p"), 78, MenuBarH+58, 13, eff.MenuDropdownText)

		// Separator line
		font.Draw(screen, "--------------------------", 78, MenuBarH+76, 10, eff.StatusLabel)

		font.Draw(screen, chkNtsc+i18n.T("lbl_ntsc"), 78, MenuBarH+92, 13, eff.MenuDropdownText)
		font.Draw(screen, chkPal+i18n.T("lbl_pal"), 78, MenuBarH+118, 13, eff.MenuDropdownText)
		font.Draw(screen, "   "+i18n.T("menu_reset")+" (F12)", 78, MenuBarH+140, 12, eff.AccentColor)
	} else if u.ActiveMenu == "Video" {
		dropOp := &ebiten.DrawImageOptions{}
		dropOp.GeoM.Translate(160, MenuBarH)
		screen.DrawImage(u.videoMenuBg, dropOp)

		chkS1 := "   "
		if u.VideoScale == 1 {
			chkS1 = "✓ "
		}
		chkS2 := "   "
		if u.VideoScale == 2 {
			chkS2 = "✓ "
		}
		chkS3 := "   "
		if u.VideoScale == 3 {
			chkS3 = "✓ "
		}
		chkS4 := "   "
		if u.VideoScale == 4 {
			chkS4 = "✓ "
		}

		chkAsp11 := "   "
		if !u.AspectRatio43 {
			chkAsp11 = "✓ "
		}
		chkAsp43 := "   "
		if u.AspectRatio43 {
			chkAsp43 = "✓ "
		}

		chkSmooth := "   "
		if u.BilinearFilter {
			chkSmooth = "✓ "
		}

		font.Draw(screen, chkS1+i18n.T("video_scale_1"), 168, MenuBarH+6, 13, eff.MenuDropdownText)
		font.Draw(screen, chkS2+i18n.T("video_scale_2"), 168, MenuBarH+30, 13, eff.MenuDropdownText)
		font.Draw(screen, chkS3+i18n.T("video_scale_3"), 168, MenuBarH+54, 13, eff.MenuDropdownText)
		font.Draw(screen, chkS4+i18n.T("video_scale_4"), 168, MenuBarH+78, 13, eff.MenuDropdownText)

		// Separator line
		font.Draw(screen, "------------------------------", 168, MenuBarH+96, 10, eff.StatusLabel)

		font.Draw(screen, chkAsp11+i18n.T("video_aspect_11"), 168, MenuBarH+112, 13, eff.MenuDropdownText)
		font.Draw(screen, chkAsp43+i18n.T("video_aspect_43"), 168, MenuBarH+136, 13, eff.MenuDropdownText)

		// Separator line
		font.Draw(screen, "------------------------------", 168, MenuBarH+154, 10, eff.StatusLabel)

		font.Draw(screen, chkSmooth+i18n.T("video_filter_smooth"), 168, MenuBarH+170, 13, eff.MenuDropdownText)

		// Separator line
		font.Draw(screen, "------------------------------", 168, MenuBarH+186, 10, eff.StatusLabel)

		chkScan0 := "   "
		if u.CRTScanlines == 0 {
			chkScan0 = "✓ "
		}
		chkScan1 := "   "
		if u.CRTScanlines == 1 {
			chkScan1 = "✓ "
		}
		chkScan2 := "   "
		if u.CRTScanlines == 2 {
			chkScan2 = "✓ "
		}

		font.Draw(screen, chkScan0+i18n.T("video_scanlines_off"), 168, MenuBarH+200, 12, eff.MenuDropdownText)
		font.Draw(screen, chkScan1+i18n.T("video_scanlines_low"), 168, MenuBarH+222, 12, eff.MenuDropdownText)
		font.Draw(screen, chkScan2+i18n.T("video_scanlines_med"), 168, MenuBarH+244, 12, eff.MenuDropdownText)

		// Separator line
		font.Draw(screen, "------------------------------", 168, MenuBarH+262, 10, eff.StatusLabel)

		chkPhos0 := "   "
		if u.PhosphorMode == 0 {
			chkPhos0 = "✓ "
		}
		chkPhos1 := "   "
		if u.PhosphorMode == 1 {
			chkPhos1 = "✓ "
		}
		chkPhos2 := "   "
		if u.PhosphorMode == 2 {
			chkPhos2 = "✓ "
		}

		font.Draw(screen, chkPhos0+i18n.T("video_phosphor_rgb"), 168, MenuBarH+276, 12, eff.MenuDropdownText)
		font.Draw(screen, chkPhos1+i18n.T("video_phosphor_grn"), 168, MenuBarH+298, 12, eff.MenuDropdownText)
		font.Draw(screen, chkPhos2+i18n.T("video_phosphor_amb"), 168, MenuBarH+320, 12, eff.MenuDropdownText)
	} else if u.ActiveMenu == "Media" {
		dropOp := &ebiten.DrawImageOptions{}
		dropOp.GeoM.Translate(205, MenuBarH)
		screen.DrawImage(u.mediaMenuBg, dropOp)

		dA := mediaBasename(u.Machine.Config.DiskAPath)
		dB := mediaBasename(u.Machine.Config.DiskBPath)
		c1 := mediaBasename(u.Machine.Config.CartAPath)
		c2 := mediaBasename(u.Machine.Config.CartBPath)
		tp := mediaBasename(u.Machine.Config.TapePath)

		// Drive A
		font.DrawBold(screen, fmt.Sprintf("%s [%s]", i18n.T("media_drive_a"), dA), 212, MenuBarH+6, 12, eff.AccentColor)
		font.Draw(screen, "   "+i18n.T("media_insert_dsk"), 212, MenuBarH+24, 12, eff.MenuDropdownText)
		font.Draw(screen, "   "+i18n.T("media_eject_dsk"), 212, MenuBarH+42, 12, eff.MenuDropdownText)

		// Drive B
		font.DrawBold(screen, fmt.Sprintf("%s [%s]", i18n.T("media_drive_b"), dB), 212, MenuBarH+62, 12, eff.AccentColor)
		font.Draw(screen, "   "+i18n.T("media_insert_dsk"), 212, MenuBarH+80, 12, eff.MenuDropdownText)
		font.Draw(screen, "   "+i18n.T("media_eject_dsk"), 212, MenuBarH+98, 12, eff.MenuDropdownText)

		// Separator
		font.Draw(screen, "-----------------------------------", 212, MenuBarH+114, 10, eff.StatusLabel)

		// Cartridge Slot 1
		font.DrawBold(screen, fmt.Sprintf("%s [%s]", i18n.T("media_cart_1"), c1), 212, MenuBarH+128, 12, eff.AccentColor)
		font.Draw(screen, "   "+i18n.T("media_insert_rom"), 212, MenuBarH+146, 12, eff.MenuDropdownText)
		font.Draw(screen, "   "+i18n.T("media_eject_rom"), 212, MenuBarH+164, 12, eff.MenuDropdownText)

		// Cartridge Slot 2
		font.DrawBold(screen, fmt.Sprintf("%s [%s]", i18n.T("media_cart_2"), c2), 212, MenuBarH+184, 12, eff.AccentColor)
		font.Draw(screen, "   "+i18n.T("media_insert_rom"), 212, MenuBarH+202, 12, eff.MenuDropdownText)
		font.Draw(screen, "   "+i18n.T("media_eject_rom"), 212, MenuBarH+220, 12, eff.MenuDropdownText)

		// Separator
		font.Draw(screen, "-----------------------------------", 212, MenuBarH+236, 10, eff.StatusLabel)

		// Cassette Tape
		font.DrawBold(screen, fmt.Sprintf("%s [%s]", i18n.T("media_tape"), tp), 212, MenuBarH+250, 12, eff.AccentColor)
		font.Draw(screen, "   "+i18n.T("media_insert_cas"), 212, MenuBarH+268, 12, eff.MenuDropdownText)
		font.Draw(screen, "   "+i18n.T("media_eject_cas")+"  |  "+i18n.T("media_rewind_cas"), 212, MenuBarH+288, 12, eff.MenuDropdownText)
	} else if u.ActiveMenu == "Debug" {
		dropOp := &ebiten.DrawImageOptions{}
		dropOp.GeoM.Translate(265, MenuBarH)
		screen.DrawImage(u.debugMenuBg, dropOp)
		font.Draw(screen, "Hacker Workstation (F9)", 273, MenuBarH+8, 12, eff.AccentColor)
		font.Draw(screen, "Single Step CPU (F10)", 273, MenuBarH+32, 12, eff.MenuDropdownText)
		font.Draw(screen, "Toggle Run / Pause (F5)", 273, MenuBarH+56, 12, eff.MenuDropdownText)
		font.Draw(screen, "--------------------------", 273, MenuBarH+72, 10, eff.StatusLabel)
		font.Draw(screen, "Reset Breakpoints", 273, MenuBarH+88, 12, eff.MenuDropdownText)
		font.Draw(screen, "Clear Execution Trace (C)", 273, MenuBarH+112, 12, eff.MenuDropdownText)
	} else if u.ActiveMenu == "Setup" {
		dropOp := &ebiten.DrawImageOptions{}
		dropOp.GeoM.Translate(325, MenuBarH)
		screen.DrawImage(u.menuBg, dropOp)
		font.Draw(screen, i18n.T("menu_config"), 333, MenuBarH+6, 12, eff.MenuDropdownText)
		font.Draw(screen, i18n.T("menu_controllers"), 333, MenuBarH+32, 12, eff.MenuDropdownText)
		font.Draw(screen, i18n.T("menu_catalog"), 333, MenuBarH+58, 12, eff.MenuDropdownText)
	} else if u.ActiveMenu == "Help" {
		dropOp := &ebiten.DrawImageOptions{}
		dropOp.GeoM.Translate(390, MenuBarH)
		screen.DrawImage(u.menuBg, dropOp)
		font.Draw(screen, i18n.T("menu_about"), 398, MenuBarH+8, 13, eff.MenuDropdownText)
	}

	// 4. Draw About Modal Dialog
	if u.ShowAbout {
		u.drawAboutModal(screen)
	}

	// 5. Draw Configuration Modal Dialog
	if u.ShowConfig {
		u.drawConfigModal(screen)
	}

	// 5b. Draw Controller Calibration Modal Dialog
	if u.ShowControllerConfig {
		u.drawControllerModal(screen)
	}

	// 6. Draw ROM Catalog Modal Dialog
	if u.ShowCatalog {
		u.drawCatalogModal(screen)
	}

	// 7. Draw Media File Picker Modal Dialog
	if u.ShowPicker {
		u.drawPickerModal(screen)
	}

	// 8. Draw Developer / Hacker Workstation Modal Dialog
	if u.ShowHackerWorkstation {
		u.drawWorkstationModal(screen)
	}
}

func (u *UI) drawStatus(screen *ebiten.Image) {
	eff := theme.GetEffective()

	font.DrawBold(screen, i18n.T("lbl_title"), 80, 42, 14, eff.StatusTitle)

	model := "MSX 2 (V9938)"
	if u.Machine.Config.Model == msx.ModelMSX1 {
		model = "MSX 1 (TMS9918)"
	} else if u.Machine.Config.Model == msx.ModelMSX2P {
		model = "MSX 2+ (V9958)"
	}
	video := "NTSC (60Hz)"
	if u.Machine.Config.Video == msx.VideoPAL {
		video = "PAL (50Hz)"
	}

	font.Draw(screen, i18n.T("lbl_model"), 80, 80, 13, eff.StatusLabel)
	font.DrawBold(screen, model, 240, 80, 13, eff.StatusValue)

	font.Draw(screen, i18n.T("lbl_video"), 80, 102, 13, eff.StatusLabel)
	font.DrawBold(screen, video, 240, 102, 13, eff.StatusValue)

	font.Draw(screen, i18n.T("lbl_ram"), 80, 124, 13, eff.StatusLabel)
	font.DrawBold(screen, fmt.Sprintf("%d KB (%d pages)", u.Machine.Config.RAMPages*16, u.Machine.Config.RAMPages), 240, 124, 13, eff.StatusValue)

	font.Draw(screen, i18n.T("lbl_vram"), 80, 146, 13, eff.StatusLabel)
	font.DrawBold(screen, fmt.Sprintf("%d KB (%d pages)", u.Machine.Config.VRAMPages*16, u.Machine.Config.VRAMPages), 240, 146, 13, eff.StatusValue)

	cpu := u.Machine.CPU
	font.DrawBold(screen, i18n.T("lbl_cpu_state"), 80, 180, 13, eff.AccentColor)

	// CPU registers rendered with crisp monospace code font
	font.DrawCode(screen, fmt.Sprintf("PC: %04Xh   SP: %04Xh   AF: %04Xh   BC: %04Xh   DE: %04Xh   HL: %04Xh",
		cpu.PC, cpu.SP, cpu.AF(), cpu.BC(), cpu.DE(), cpu.HL()), 80, 204, 12, eff.StatusValue)
	font.DrawCode(screen, fmt.Sprintf("IX: %04Xh   IY: %04Xh   I: %02Xh    R: %02Xh    IM: %d   Halted: %t",
		cpu.IX, cpu.IY, cpu.I, cpu.R, cpu.IM, cpu.Halted), 80, 224, 12, eff.StatusValue)

	activeFont := font.ActiveFamily()
	fontName := "Ubuntu"
	if activeFont != nil {
		fontName = activeFont.Name
	}
	themeInfo := fmt.Sprintf("Theme: %s [%s] | Language: %s | Font: %s",
		eff.Name, eff.Category, i18n.GetLanguage(), fontName)
	font.Draw(screen, themeInfo, 80, 260, 12, eff.StatusLabel)

	font.DrawBold(screen, i18n.T("lbl_tips"), 80, 305, 13, eff.AccentColor)
	font.Draw(screen, i18n.T("lbl_tip_exit"), 80, 326, 12, eff.StatusLabel)
	font.Draw(screen, i18n.T("lbl_tip_about"), 80, 346, 12, eff.StatusLabel)
	font.Draw(screen, " - Open 'Setup -> Configuration...' to choose Language, Theme & Font.", 80, 366, 12, eff.StatusLabel)
	font.Draw(screen, i18n.T("lbl_tip_cli"), 80, 386, 12, eff.StatusLabel)
	font.DrawBold(screen, " - Press F11 or click top-right badge to toggle Live MSX Screen / Debugger.", 80, 410, 12, eff.AccentColor)
}

func (u *UI) updateKeyboard() {
	if u.Machine == nil || u.Machine.Bus == nil {
		return
	}
	// Default all rows to 0xFF (no key pressed, active low)
	for r := 0; r < 16; r++ {
		u.Machine.Bus.KeyMatrix[r] = 0xFF
	}

	// Don't capture keys if modal dialogs are open
	if u.ShowConfig || u.ShowCatalog || u.ShowAbout || u.ShowPicker || u.ShowHackerWorkstation {
		return
	}

	press := func(row int, bit int) {
		u.Machine.Bus.KeyMatrix[row] &^= (1 << bit)
	}

	// Row 0: 7, 6, 5, 4, 3, 2, 1, 0
	if ebiten.IsKeyPressed(ebiten.Key0) { press(0, 0) }
	if ebiten.IsKeyPressed(ebiten.Key1) { press(0, 1) }
	if ebiten.IsKeyPressed(ebiten.Key2) { press(0, 2) }
	if ebiten.IsKeyPressed(ebiten.Key3) { press(0, 3) }
	if ebiten.IsKeyPressed(ebiten.Key4) { press(0, 4) }
	if ebiten.IsKeyPressed(ebiten.Key5) { press(0, 5) }
	if ebiten.IsKeyPressed(ebiten.Key6) { press(0, 6) }
	if ebiten.IsKeyPressed(ebiten.Key7) { press(0, 7) }

	// Row 1: ;, ], [, \, =, -, 9, 8
	if ebiten.IsKeyPressed(ebiten.Key8) { press(1, 0) }
	if ebiten.IsKeyPressed(ebiten.Key9) { press(1, 1) }
	if ebiten.IsKeyPressed(ebiten.KeyMinus) { press(1, 2) }
	if ebiten.IsKeyPressed(ebiten.KeyEqual) { press(1, 3) }
	if ebiten.IsKeyPressed(ebiten.KeyBackslash) { press(1, 4) }
	if ebiten.IsKeyPressed(ebiten.KeyBracketLeft) { press(1, 5) }
	if ebiten.IsKeyPressed(ebiten.KeyBracketRight) { press(1, 6) }
	if ebiten.IsKeyPressed(ebiten.KeySemicolon) { press(1, 7) }

	// Row 2: B, A, accent, /, ., ,, `, '
	if ebiten.IsKeyPressed(ebiten.KeyQuote) { press(2, 0) }
	if ebiten.IsKeyPressed(ebiten.KeyBackquote) { press(2, 1) }
	if ebiten.IsKeyPressed(ebiten.KeyComma) { press(2, 2) }
	if ebiten.IsKeyPressed(ebiten.KeyPeriod) { press(2, 3) }
	if ebiten.IsKeyPressed(ebiten.KeySlash) { press(2, 4) }
	if ebiten.IsKeyPressed(ebiten.KeyA) { press(2, 6) }
	if ebiten.IsKeyPressed(ebiten.KeyB) { press(2, 7) }

	// Row 3: J, I, H, G, F, E, D, C
	if ebiten.IsKeyPressed(ebiten.KeyC) { press(3, 0) }
	if ebiten.IsKeyPressed(ebiten.KeyD) { press(3, 1) }
	if ebiten.IsKeyPressed(ebiten.KeyE) { press(3, 2) }
	if ebiten.IsKeyPressed(ebiten.KeyF) { press(3, 3) }
	if ebiten.IsKeyPressed(ebiten.KeyG) { press(3, 4) }
	if ebiten.IsKeyPressed(ebiten.KeyH) { press(3, 5) }
	if ebiten.IsKeyPressed(ebiten.KeyI) { press(3, 6) }
	if ebiten.IsKeyPressed(ebiten.KeyJ) { press(3, 7) }

	// Row 4: R, Q, P, O, N, M, L, K
	if ebiten.IsKeyPressed(ebiten.KeyK) { press(4, 0) }
	if ebiten.IsKeyPressed(ebiten.KeyL) { press(4, 1) }
	if ebiten.IsKeyPressed(ebiten.KeyM) { press(4, 2) }
	if ebiten.IsKeyPressed(ebiten.KeyN) { press(4, 3) }
	if ebiten.IsKeyPressed(ebiten.KeyO) { press(4, 4) }
	if ebiten.IsKeyPressed(ebiten.KeyP) { press(4, 5) }
	if ebiten.IsKeyPressed(ebiten.KeyQ) { press(4, 6) }
	if ebiten.IsKeyPressed(ebiten.KeyR) { press(4, 7) }

	// Row 5: Z, Y, X, W, V, U, T, S
	if ebiten.IsKeyPressed(ebiten.KeyS) { press(5, 0) }
	if ebiten.IsKeyPressed(ebiten.KeyT) { press(5, 1) }
	if ebiten.IsKeyPressed(ebiten.KeyU) { press(5, 2) }
	if ebiten.IsKeyPressed(ebiten.KeyV) { press(5, 3) }
	if ebiten.IsKeyPressed(ebiten.KeyW) { press(5, 4) }
	if ebiten.IsKeyPressed(ebiten.KeyX) { press(5, 5) }
	if ebiten.IsKeyPressed(ebiten.KeyY) { press(5, 6) }
	if ebiten.IsKeyPressed(ebiten.KeyZ) { press(5, 7) }

	// Row 6: F3, F2, F1, CODE, CAPS, GRAPH, CTRL, SHIFT
	if ebiten.IsKeyPressed(ebiten.KeyShiftLeft) || ebiten.IsKeyPressed(ebiten.KeyShiftRight) { press(6, 0) }
	if ebiten.IsKeyPressed(ebiten.KeyControlLeft) || ebiten.IsKeyPressed(ebiten.KeyControlRight) { press(6, 1) }
	if ebiten.IsKeyPressed(ebiten.KeyAltLeft) { press(6, 2) } // GRAPH
	if ebiten.IsKeyPressed(ebiten.KeyCapsLock) { press(6, 3) }
	if ebiten.IsKeyPressed(ebiten.KeyAltRight) { press(6, 4) } // CODE
	if ebiten.IsKeyPressed(ebiten.KeyF1) { press(6, 5) }
	if ebiten.IsKeyPressed(ebiten.KeyF2) { press(6, 6) }
	if ebiten.IsKeyPressed(ebiten.KeyF3) { press(6, 7) }

	// Row 7: RET, SELECT, BS, STOP, TAB, ESC, F5, F4
	if ebiten.IsKeyPressed(ebiten.KeyF4) { press(7, 0) }
	if ebiten.IsKeyPressed(ebiten.KeyF5) { press(7, 1) }
	if ebiten.IsKeyPressed(ebiten.KeyEscape) { press(7, 2) }
	if ebiten.IsKeyPressed(ebiten.KeyTab) { press(7, 3) }
	if ebiten.IsKeyPressed(ebiten.KeyPause) { press(7, 4) } // STOP
	if ebiten.IsKeyPressed(ebiten.KeyBackspace) { press(7, 5) }
	if ebiten.IsKeyPressed(ebiten.KeyPageDown) { press(7, 6) } // SELECT
	if ebiten.IsKeyPressed(ebiten.KeyEnter) || ebiten.IsKeyPressed(ebiten.KeyNumpadEnter) { press(7, 7) }

	// Row 8: RIGHT, DOWN, UP, LEFT, DEL, INS, HOME, SPACE
	if ebiten.IsKeyPressed(ebiten.KeySpace) { press(8, 0) }
	if ebiten.IsKeyPressed(ebiten.KeyHome) { press(8, 1) }
	if ebiten.IsKeyPressed(ebiten.KeyInsert) { press(8, 2) }
	if ebiten.IsKeyPressed(ebiten.KeyDelete) { press(8, 3) }
	if ebiten.IsKeyPressed(ebiten.KeyArrowLeft) { press(8, 4) }
	if ebiten.IsKeyPressed(ebiten.KeyArrowUp) { press(8, 5) }
	if ebiten.IsKeyPressed(ebiten.KeyArrowDown) { press(8, 6) }
	if ebiten.IsKeyPressed(ebiten.KeyArrowRight) { press(8, 7) }
}

func (u *UI) updateJoysticksAndMouse() {
	if u.Machine == nil || u.Machine.Joy == nil {
		return
	}

	// Don't capture gameplay inputs if modal dialogs are open
	if u.ShowConfig || u.ShowCatalog || u.ShowAbout || u.ShowPicker || u.ShowControllerConfig {
		return
	}

	// 1. Joystick 1 (Port 0): Keyboard fallback + Physical Gamepad 1
	up1 := ebiten.IsKeyPressed(ebiten.KeyArrowUp) || ebiten.IsKeyPressed(ebiten.KeyNumpad8)
	down1 := ebiten.IsKeyPressed(ebiten.KeyArrowDown) || ebiten.IsKeyPressed(ebiten.KeyNumpad2)
	left1 := ebiten.IsKeyPressed(ebiten.KeyArrowLeft) || ebiten.IsKeyPressed(ebiten.KeyNumpad4)
	right1 := ebiten.IsKeyPressed(ebiten.KeyArrowRight) || ebiten.IsKeyPressed(ebiten.KeyNumpad6)
	btnA1 := ebiten.IsKeyPressed(ebiten.KeySpace) || ebiten.IsKeyPressed(ebiten.KeyZ)
	btnB1 := ebiten.IsKeyPressed(ebiten.KeyX) || ebiten.IsKeyPressed(ebiten.KeyC) || ebiten.IsKeyPressed(ebiten.KeyControlLeft)

	// Scan connected USB gamepads
	gamepadIDs := ebiten.AppendGamepadIDs(nil)
	if len(gamepadIDs) > 0 {
		gp0 := gamepadIDs[0]
		// D-Pad buttons
		if ebiten.IsStandardGamepadButtonPressed(gp0, ebiten.StandardGamepadButtonLeftTop) {
			up1 = true
		}
		if ebiten.IsStandardGamepadButtonPressed(gp0, ebiten.StandardGamepadButtonLeftBottom) {
			down1 = true
		}
		if ebiten.IsStandardGamepadButtonPressed(gp0, ebiten.StandardGamepadButtonLeftLeft) {
			left1 = true
		}
		if ebiten.IsStandardGamepadButtonPressed(gp0, ebiten.StandardGamepadButtonLeftRight) {
			right1 = true
		}

		// Analog Left Stick axes with user-calibrated deadzone
		dz0 := u.ControllerConfig.Deadzone[0]
		if dz0 < 0.05 {
			dz0 = 0.35
		}
		stickX := ebiten.StandardGamepadAxisValue(gp0, ebiten.StandardGamepadAxisLeftStickHorizontal)
		stickY := ebiten.StandardGamepadAxisValue(gp0, ebiten.StandardGamepadAxisLeftStickVertical)
		if stickY < -dz0 {
			up1 = true
		} else if stickY > dz0 {
			down1 = true
		}
		if stickX < -dz0 {
			left1 = true
		} else if stickX > dz0 {
			right1 = true
		}

		// Action buttons (A, B, X, Y) with optional SwapAB
		rawA := ebiten.IsStandardGamepadButtonPressed(gp0, ebiten.StandardGamepadButtonRightBottom) || // South (A / Cross)
			ebiten.IsStandardGamepadButtonPressed(gp0, ebiten.StandardGamepadButtonRightLeft) // West (X / Square)
		rawB := ebiten.IsStandardGamepadButtonPressed(gp0, ebiten.StandardGamepadButtonRightRight) || // East (B / Circle)
			ebiten.IsStandardGamepadButtonPressed(gp0, ebiten.StandardGamepadButtonRightTop) // North (Y / Triangle)

		if u.ControllerConfig.SwapAB[0] {
			if rawB {
				btnA1 = true
			}
			if rawA {
				btnB1 = true
			}
		} else {
			if rawA {
				btnA1 = true
			}
			if rawB {
				btnB1 = true
			}
		}
	}

	u.Machine.Joy.UpdateButtons(0, up1, down1, left1, right1, btnA1, btnB1)

	// 2. Joystick 2 (Port 1): Physical Gamepad 2 or alternative keys
	up2 := false
	down2 := false
	left2 := false
	right2 := false
	btnA2 := false
	btnB2 := false

	if len(gamepadIDs) > 1 {
		gp1 := gamepadIDs[1]
		if ebiten.IsStandardGamepadButtonPressed(gp1, ebiten.StandardGamepadButtonLeftTop) {
			up2 = true
		}
		if ebiten.IsStandardGamepadButtonPressed(gp1, ebiten.StandardGamepadButtonLeftBottom) {
			down2 = true
		}
		if ebiten.IsStandardGamepadButtonPressed(gp1, ebiten.StandardGamepadButtonLeftLeft) {
			left2 = true
		}
		if ebiten.IsStandardGamepadButtonPressed(gp1, ebiten.StandardGamepadButtonLeftRight) {
			right2 = true
		}

		dz1 := u.ControllerConfig.Deadzone[1]
		if dz1 < 0.05 {
			dz1 = 0.35
		}
		stickX := ebiten.StandardGamepadAxisValue(gp1, ebiten.StandardGamepadAxisLeftStickHorizontal)
		stickY := ebiten.StandardGamepadAxisValue(gp1, ebiten.StandardGamepadAxisLeftStickVertical)
		if stickY < -dz1 {
			up2 = true
		} else if stickY > dz1 {
			down2 = true
		}
		if stickX < -dz1 {
			left2 = true
		} else if stickX > dz1 {
			right2 = true
		}

		rawA2 := ebiten.IsStandardGamepadButtonPressed(gp1, ebiten.StandardGamepadButtonRightBottom) ||
			ebiten.IsStandardGamepadButtonPressed(gp1, ebiten.StandardGamepadButtonRightLeft)
		rawB2 := ebiten.IsStandardGamepadButtonPressed(gp1, ebiten.StandardGamepadButtonRightRight) ||
			ebiten.IsStandardGamepadButtonPressed(gp1, ebiten.StandardGamepadButtonRightTop)

		if u.ControllerConfig.SwapAB[1] {
			if rawB2 {
				btnA2 = true
			}
			if rawA2 {
				btnB2 = true
			}
		} else {
			if rawA2 {
				btnA2 = true
			}
			if rawB2 {
				btnB2 = true
			}
		}
	}

	u.Machine.Joy.UpdateButtons(1, up2, down2, left2, right2, btnA2, btnB2)

	// 3. Mouse Update (Port 0 or Port 1)
	mx, my := ebiten.CursorPosition()
	leftBtn := ebiten.IsMouseButtonPressed(ebiten.MouseButtonLeft)
	rightBtn := ebiten.IsMouseButtonPressed(ebiten.MouseButtonRight)
	isHighRes := false
	if u.Machine.VDP != nil {
		isHighRes = u.Machine.VDP.ScrMode == 6 || u.Machine.VDP.ScrMode == 7 || u.Machine.VDP.ScrMode == 13
	}

	// If mouse is plugged into Port 0 or Port 1, route mouse coordinates
	if u.Machine.Joy.Ports[0].Type == msx.JoyMouse {
		u.Machine.Joy.UpdateMouse(0, mx, my, leftBtn, rightBtn, isHighRes)
	}
	if u.Machine.Joy.Ports[1].Type == msx.JoyMouse {
		u.Machine.Joy.UpdateMouse(1, mx, my, leftBtn, rightBtn, isHighRes)
	}
}

func (u *UI) drawAboutModal(screen *ebiten.Image) {
	eff := theme.GetEffective()
	diagX := float64((screen.Bounds().Dx() - 440) / 2)
	diagY := float64((screen.Bounds().Dy() - 230) / 2)

	op := &ebiten.DrawImageOptions{}
	op.GeoM.Translate(diagX, diagY)
	screen.DrawImage(u.dialogBg, op)

	font.DrawBold(screen, i18n.T("about_title"), diagX+140, diagY+20, 15, eff.DialogHeader)
	font.DrawBold(screen, i18n.T("about_app"), diagX+30, diagY+52, 13, eff.DialogText)
	font.Draw(screen, fmt.Sprintf("%s: 0.3.2 ('Vampire Killer') - 64-bit", i18n.T("about_version")), diagX+30, diagY+74, 12, eff.DialogText)
	font.Draw(screen, i18n.T("about_core"), diagX+30, diagY+98, 12, eff.DialogText)
	font.Draw(screen, i18n.T("about_port"), diagX+30, diagY+118, 12, eff.DialogText)
	font.Draw(screen, i18n.T("about_license"), diagX+30, diagY+138, 12, eff.DialogText)

	btnOp := &ebiten.DrawImageOptions{}
	btnOp.GeoM.Translate(diagX+130, diagY+175)
	screen.DrawImage(u.buttonBg, btnOp)
	font.DrawBold(screen, i18n.T("btn_ok"), diagX+190, diagY+180, 13, eff.ButtonText)
}

func (u *UI) drawConfigModal(screen *ebiten.Image) {
	eff := theme.GetEffective()
	diagX := (screen.Bounds().Dx() - 600) / 2
	diagY := (screen.Bounds().Dy() - 420) / 2

	// 1. Draw dialog background
	op := &ebiten.DrawImageOptions{}
	op.GeoM.Translate(float64(diagX), float64(diagY))
	screen.DrawImage(u.configDlgBg, op)

	// 2. Title
	font.DrawBold(screen, fmt.Sprintf("=== %s ===", i18n.T("dlg_config_title")), float64(diagX+140), float64(diagY+16), 14, eff.DialogHeader)

	// 3. Column 1: Languages (x: diagX+15)
	font.DrawBold(screen, i18n.T("cfg_sec_language"), float64(diagX+15), float64(diagY+50), 13, eff.DialogHeader)
	currentLang := i18n.GetLanguage()
	langStartY := diagY + 75
	for i, l := range i18n.SupportedLanguages {
		yPos := langStartY + (i * 26)
		isSelected := l.Code == currentLang

		prefix := "[ ] "
		if isSelected {
			prefix = "[*] "
			rowOp := &ebiten.DrawImageOptions{}
			rowOp.GeoM.Scale(0.62, 1.0)
			rowOp.GeoM.Translate(float64(diagX+10), float64(yPos-2))
			screen.DrawImage(u.selectedRowBg, rowOp)
		}

		label := fmt.Sprintf("%s%-12s (%s)", prefix, l.NativeName, l.Code)
		textColor := eff.DialogText
		if isSelected {
			textColor = eff.SelectedText
		}
		font.Draw(screen, label, float64(diagX+15), float64(yPos+2), 12, textColor)
	}

	// 4. Column 2: Themes (x: diagX+185)
	font.DrawBold(screen, i18n.T("cfg_sec_theme"), float64(diagX+185), float64(diagY+50), 13, eff.DialogHeader)
	currentTheme := theme.GetCurrent()
	themes := theme.List()
	themeStartY := diagY + 75
	for i, th := range themes {
		yPos := themeStartY + (i * 25)
		isSelected := th.ID == currentTheme

		prefix := "[ ] "
		if isSelected {
			prefix = "[*] "
			rowOp := &ebiten.DrawImageOptions{}
			rowOp.GeoM.Scale(0.78, 1.0)
			rowOp.GeoM.Translate(float64(diagX+180), float64(yPos-2))
			screen.DrawImage(u.selectedRowBg, rowOp)
		}

		label := fmt.Sprintf("%s%-14s [%s]", prefix, th.Name, th.Category)
		textColor := eff.DialogText
		if isSelected {
			textColor = eff.SelectedText
		}
		font.Draw(screen, label, float64(diagX+185), float64(yPos+2), 12, textColor)
	}

	// 5. Column 3: Fonts / Typography (x: diagX+400)
	font.DrawBold(screen, i18n.T("cfg_sec_font"), float64(diagX+400), float64(diagY+50), 13, eff.DialogHeader)
	currentFont := font.GetCurrent()
	fonts := font.ListFamilies()
	fontStartY := diagY + 75
	for i, f := range fonts {
		if i >= 11 {
			break
		}
		yPos := fontStartY + (i * 25)
		isSelected := f.ID == currentFont

		prefix := "[ ] "
		if isSelected {
			prefix = "[*] "
			rowOp := &ebiten.DrawImageOptions{}
			rowOp.GeoM.Scale(0.72, 1.0)
			rowOp.GeoM.Translate(float64(diagX+395), float64(yPos-2))
			screen.DrawImage(u.selectedRowBg, rowOp)
		}

		label := fmt.Sprintf("%s%s", prefix, f.Name)
		textColor := eff.DialogText
		if isSelected {
			textColor = eff.SelectedText
		}
		font.Draw(screen, label, float64(diagX+400), float64(yPos+2), 12, textColor)
	}

	// 6. Save & Close Button (center)
	btnOp := &ebiten.DrawImageOptions{}
	btnOp.GeoM.Translate(float64(diagX+210), float64(diagY+380))
	screen.DrawImage(u.buttonBg, btnOp)
	font.DrawBold(screen, i18n.T("btn_save_close"), float64(diagX+235), float64(diagY+386), 13, eff.ButtonText)
}

func (u *UI) handleCatalogClick(x, y int) {
	winW := u.currWinW
	if winW < 640 {
		winW = 640
	}
	winH := u.currWinH
	if winH < 480 {
		winH = 480
	}
	diagX := (winW - 620) / 2
	diagY := (winH - 440) / 2

	// Click outside closes modal
	if x < diagX || x > diagX+620 || y < diagY || y > diagY+440 {
		u.ShowCatalog = false
		return
	}

	// Click Close Button
	if x >= diagX+220 && x <= diagX+400 && y >= diagY+395 && y <= diagY+425 {
		u.ShowCatalog = false
		return
	}

	// Click row to toggle default
	startY := diagY + 90
	if u.Machine != nil && u.Machine.DB != nil {
		items, err := u.Machine.DB.ListCatalog("", "")
		if err == nil {
			for i, item := range items {
				if i >= 10 {
					break
				}
				rowY := startY + (i * 26)
				if y >= rowY && y < rowY+24 && x >= diagX+15 && x <= diagX+605 {
					_ = u.Machine.DB.SetCatalogDefault(item.Name)
					return
				}
			}
		}
	}
}

func (u *UI) drawCatalogModal(screen *ebiten.Image) {
	eff := theme.GetEffective()
	diagX := (screen.Bounds().Dx() - 620) / 2
	diagY := (screen.Bounds().Dy() - 440) / 2

	// 1. Dialog background
	op := &ebiten.DrawImageOptions{}
	op.GeoM.Translate(float64(diagX), float64(diagY))
	screen.DrawImage(u.catalogDlgBg, op)

	// 2. Title & Help
	font.DrawBold(screen, fmt.Sprintf("=== %s ===", i18n.T("dlg_catalog_title")), float64(diagX+120), float64(diagY+14), 14, eff.DialogHeader)
	font.Draw(screen, i18n.T("cat_sec_actions"), float64(diagX+20), float64(diagY+36), 12, eff.DialogText)

	// Table Header (using monospace code font)
	header := fmt.Sprintf("   %-13s %-8s %-6s %-7s %-10s %s", "NAME", "CAT", "MODEL", "SIZE", "FLAGS", "TITLE")
	font.DrawCode(screen, header, float64(diagX+20), float64(diagY+65), 12, eff.AccentColor)

	// Rows from SQLite
	startY := diagY + 90
	if u.Machine != nil && u.Machine.DB != nil {
		items, err := u.Machine.DB.ListCatalog("", "")
		if err == nil {
			verifiedCount := 0
			for i, item := range items {
				if item.IsVerified {
					verifiedCount++
				}
				if i >= 10 {
					continue
				}
				rowY := startY + (i * 26)
				if item.IsDefault {
					rowOp := &ebiten.DrawImageOptions{}
					rowOp.GeoM.Scale(2.25, 1.0)
					rowOp.GeoM.Translate(float64(diagX+15), float64(rowY-2))
					screen.DrawImage(u.selectedRowBg, rowOp)
				}

				pref := "[ ]"
				if item.IsDefault {
					pref = "[*]"
				}
				flags := ""
				if item.IsDefault {
					flags += "[DEF]"
				} else {
					flags += "     "
				}
				if item.IsVerified {
					flags += "[VER]"
				}

				sizeStr := fmt.Sprintf("%dK", item.Size/1024)
				rowStr := fmt.Sprintf("%s %-13s %-8s %-6s %-7s %-10s %s",
					pref, item.Name, item.Category, item.MachineModel, sizeStr, flags, item.Title)
				if len(rowStr) > 78 {
					rowStr = rowStr[:78]
				}

				textColor := eff.DialogText
				if item.IsDefault {
					textColor = eff.SelectedText
				}
				font.DrawCode(screen, rowStr, float64(diagX+20), float64(rowY+2), 12, textColor)
			}

			// Footer summary
			statusLine := fmt.Sprintf("%s: %d/8 | Total: %d ROMs",
				i18n.T("cat_official_verified"), verifiedCount, len(items))
			font.DrawBold(screen, statusLine, float64(diagX+20), float64(diagY+365), 12, eff.StatusTitle)
		}
	}

	// Close Button
	btnOp := &ebiten.DrawImageOptions{}
	btnOp.GeoM.Translate(float64(diagX+220), float64(diagY+395))
	screen.DrawImage(u.buttonBg, btnOp)
	font.DrawBold(screen, i18n.T("btn_save_close"), float64(diagX+245), float64(diagY+401), 13, eff.ButtonText)
}

// Layout defines the logical window resolution.
func (u *UI) Layout(outsideWidth, outsideHeight int) (int, int) {
	if outsideWidth < 640 {
		outsideWidth = 640
	}
	if outsideHeight < 480 {
		outsideHeight = 480
	}
	u.currWinW = outsideWidth
	u.currWinH = outsideHeight
	return outsideWidth, outsideHeight
}

func mediaBasename(path string) string {
	if path == "" {
		return i18n.T("media_empty")
	}
	b := filepath.Base(path)
	if len(b) > 16 {
		b = b[:13] + "..."
	}
	return b
}

// OpenFilePicker opens the File Picker modal for the given media target.
func (u *UI) OpenFilePicker(target int) {
	u.ShowPicker = true
	u.PickerTarget = target
	u.PickerSelected = -1
	u.PickerScroll = 0
	if u.PickerDir == "" {
		if cwd, err := os.Getwd(); err == nil {
			u.PickerDir = cwd
		} else {
			u.PickerDir = "."
		}
	}
	u.refreshPickerFiles()
}

func (u *UI) refreshPickerFiles() {
	u.PickerFiles = nil
	u.PickerSelected = -1
	u.PickerScroll = 0

	entries, err := os.ReadDir(u.PickerDir)
	if err != nil {
		return
	}

	var dirs []PickerItem
	var files []PickerItem

	for _, e := range entries {
		name := e.Name()
		if strings.HasPrefix(name, ".") && name != ".." {
			continue
		}
		if e.IsDir() {
			dirs = append(dirs, PickerItem{
				Name:  name,
				IsDir: true,
			})
		} else {
			ext := strings.ToLower(filepath.Ext(name))
			valid := false
			switch u.PickerTarget {
			case PickerDriveA, PickerDriveB:
				valid = (ext == ".dsk" || ext == ".di1" || ext == ".di2" || ext == ".dmk" || ext == ".img")
			case PickerCart1, PickerCart2:
				valid = (ext == ".rom" || ext == ".mx1" || ext == ".mx2" || ext == ".bin")
			case PickerTape:
				valid = (ext == ".cas")
			case PickerSaveState, PickerLoadState:
				valid = (ext == ".sta")
			}
			if valid {
				info, err := e.Info()
				var sz int64
				if err == nil {
					sz = info.Size()
				}
				files = append(files, PickerItem{
					Name:  name,
					IsDir: false,
					Size:  sz,
				})
			}
		}
	}

	sort.Slice(dirs, func(i, j int) bool {
		return strings.ToLower(dirs[i].Name) < strings.ToLower(dirs[j].Name)
	})
	sort.Slice(files, func(i, j int) bool {
		return strings.ToLower(files[i].Name) < strings.ToLower(files[j].Name)
	})

	u.PickerFiles = append(dirs, files...)
}

func (u *UI) mountPickerFile(fullPath string) {
	if u.Machine == nil {
		return
	}
	var err error
	switch u.PickerTarget {
	case PickerDriveA:
		err = u.Machine.LoadDisk(0, fullPath)
	case PickerDriveB:
		err = u.Machine.LoadDisk(1, fullPath)
	case PickerCart1:
		err = u.Machine.LoadCartridge(1, fullPath)
	case PickerCart2:
		err = u.Machine.LoadCartridge(2, fullPath)
	case PickerTape:
		err = u.Machine.LoadTape(fullPath)
	case PickerSaveState:
		err = u.Machine.SaveSTA(fullPath)
		if err == nil {
			fmt.Printf("[fMSXgo] State snapshot saved to: %s\n", fullPath)
		}
	case PickerLoadState:
		err = u.Machine.LoadSTA(fullPath)
		if err == nil {
			fmt.Printf("[fMSXgo] State snapshot restored from: %s\n", fullPath)
		}
	}
	if err != nil {
		fmt.Printf("[fMSXgo] Error loading/saving media: %v\n", err)
	}
}

func (u *UI) drawPickerModal(screen *ebiten.Image) {
	eff := theme.GetEffective()
	diagX := (screen.Bounds().Dx() - 620) / 2
	diagY := (screen.Bounds().Dy() - 440) / 2

	// 1. Dialog background
	op := &ebiten.DrawImageOptions{}
	op.GeoM.Translate(float64(diagX), float64(diagY))
	screen.DrawImage(u.pickerDlgBg, op)

	// 2. Title & Target Subtitle
	font.DrawBold(screen, fmt.Sprintf("=== %s ===", i18n.T("dlg_picker_title")), float64(diagX+140), float64(diagY+14), 14, eff.DialogHeader)

	targetDesc := ""
	switch u.PickerTarget {
	case PickerDriveA:
		targetDesc = fmt.Sprintf("%s (.dsk, .img)", i18n.T("media_drive_a"))
	case PickerDriveB:
		targetDesc = fmt.Sprintf("%s (.dsk, .img)", i18n.T("media_drive_b"))
	case PickerCart1:
		targetDesc = fmt.Sprintf("%s (.rom, .mx1, .mx2)", i18n.T("media_cart_1"))
	case PickerCart2:
		targetDesc = fmt.Sprintf("%s (.rom, .mx1, .mx2)", i18n.T("media_cart_2"))
	case PickerTape:
		targetDesc = fmt.Sprintf("%s (.cas)", i18n.T("media_tape"))
	case PickerSaveState:
		targetDesc = fmt.Sprintf("%s (.sta)", i18n.T("menu_save_state"))
	case PickerLoadState:
		targetDesc = fmt.Sprintf("%s (.sta)", i18n.T("menu_load_state"))
	}
	font.DrawBold(screen, "Target: "+targetDesc, float64(diagX+20), float64(diagY+38), 12, eff.AccentColor)

	displayPath := u.PickerDir
	if len(displayPath) > 65 {
		displayPath = "..." + displayPath[len(displayPath)-62:]
	}
	font.Draw(screen, "Dir: "+displayPath, float64(diagX+20), float64(diagY+58), 12, eff.StatusLabel)

	// 3. Parent Directory item [..]
	font.DrawBold(screen, i18n.T("lbl_parent_dir"), float64(diagX+20), float64(diagY+84), 12, eff.DialogHeader)

	// Scroll buttons indicator on right
	font.DrawBold(screen, "[▲]", float64(diagX+570), float64(diagY+84), 12, eff.AccentColor)
	font.DrawBold(screen, "[▼]", float64(diagX+570), float64(diagY+344), 12, eff.AccentColor)

	// 4. File and Directory list (up to 9 visible items)
	startY := diagY + 110
	for row := 0; row < 9; row++ {
		idx := u.PickerScroll + row
		if idx >= len(u.PickerFiles) {
			break
		}
		item := u.PickerFiles[idx]
		rowY := startY + (row * 26)

		isSelected := (idx == u.PickerSelected)
		if isSelected {
			rowOp := &ebiten.DrawImageOptions{}
			rowOp.GeoM.Scale(2.25, 1.0)
			rowOp.GeoM.Translate(float64(diagX+15), float64(rowY-2))
			screen.DrawImage(u.selectedRowBg, rowOp)
		}

		typePrefix := "[FILE]"
		sizeStr := fmt.Sprintf("%5d KB", (item.Size+1023)/1024)
		if item.IsDir {
			typePrefix = "[DIR] "
			sizeStr = " <DIR> "
		}

		name := item.Name
		if len(name) > 42 {
			name = name[:39] + "..."
		}

		rowStr := fmt.Sprintf(" %-6s %-44s %s", typePrefix, name, sizeStr)
		textColor := eff.DialogText
		if isSelected {
			textColor = eff.SelectedText
		} else if item.IsDir {
			textColor = eff.AccentColor
		}
		font.DrawCode(screen, rowStr, float64(diagX+20), float64(rowY+2), 12, textColor)
	}

	// 5. Scroll / Count indicator
	countStr := fmt.Sprintf("Items: %d", len(u.PickerFiles))
	if len(u.PickerFiles) > 9 {
		endIdx := u.PickerScroll + 9
		if endIdx > len(u.PickerFiles) {
			endIdx = len(u.PickerFiles)
		}
		countStr = fmt.Sprintf("Showing %d-%d of %d items", u.PickerScroll+1, endIdx, len(u.PickerFiles))
	}
	font.Draw(screen, countStr, float64(diagX+20), float64(diagY+355), 11, eff.StatusLabel)

	// 6. Action buttons (Load / Mount, Cancel)
	loadBtnOp := &ebiten.DrawImageOptions{}
	loadBtnOp.GeoM.Translate(float64(diagX+110), float64(diagY+390))
	screen.DrawImage(u.buttonBg, loadBtnOp)
	font.DrawBold(screen, i18n.T("btn_load"), float64(diagX+125), float64(diagY+396), 12, eff.ButtonText)

	cancelBtnOp := &ebiten.DrawImageOptions{}
	cancelBtnOp.GeoM.Translate(float64(diagX+330), float64(diagY+390))
	screen.DrawImage(u.buttonBg, cancelBtnOp)
	font.DrawBold(screen, i18n.T("btn_cancel"), float64(diagX+360), float64(diagY+396), 12, eff.ButtonText)
}

func (u *UI) handlePickerClick(x, y int) {
	winW := u.currWinW
	if winW < 640 {
		winW = 640
	}
	winH := u.currWinH
	if winH < 480 {
		winH = 480
	}
	diagX := (winW - 620) / 2
	diagY := (winH - 440) / 2

	// Click outside modal closes it
	if x < diagX || x > diagX+620 || y < diagY || y > diagY+440 {
		u.ShowPicker = false
		return
	}

	// 1. Parent Directory [..]
	if y >= diagY+80 && y <= diagY+104 && x >= diagX+20 && x <= diagX+350 {
		parent := filepath.Dir(u.PickerDir)
		if parent != u.PickerDir {
			u.PickerDir = parent
			u.refreshPickerFiles()
		}
		return
	}

	// 2. Scroll Up Button [▲]
	if y >= diagY+80 && y <= diagY+104 && x >= diagX+560 && x <= diagX+600 {
		if u.PickerScroll > 0 {
			u.PickerScroll--
		}
		return
	}

	// 3. Scroll Down Button [▼]
	if y >= diagY+340 && y <= diagY+365 && x >= diagX+560 && x <= diagX+600 {
		if u.PickerScroll+9 < len(u.PickerFiles) {
			u.PickerScroll++
		}
		return
	}

	// 4. File/Dir list item click
	startY := diagY + 110
	for row := 0; row < 9; row++ {
		idx := u.PickerScroll + row
		if idx >= len(u.PickerFiles) {
			break
		}
		rowY := startY + (row * 26)
		if y >= rowY && y < rowY+24 && x >= diagX+15 && x <= diagX+560 {
			item := u.PickerFiles[idx]
			if item.IsDir {
				u.PickerDir = filepath.Join(u.PickerDir, item.Name)
				u.refreshPickerFiles()
				return
			}
			// File clicked
			if u.PickerSelected == idx {
				// Second click on already selected file -> load immediately
				u.mountPickerFile(filepath.Join(u.PickerDir, item.Name))
				u.ShowPicker = false
				return
			}
			u.PickerSelected = idx
			return
		}
	}

	// 5. Load / Mount Button
	if x >= diagX+110 && x <= diagX+290 && y >= diagY+390 && y <= diagY+420 {
		if u.PickerSelected >= 0 && u.PickerSelected < len(u.PickerFiles) {
			sel := u.PickerFiles[u.PickerSelected]
			if !sel.IsDir {
				u.mountPickerFile(filepath.Join(u.PickerDir, sel.Name))
				u.ShowPicker = false
			}
		}
		return
	}

	// 6. Cancel Button
	if x >= diagX+330 && x <= diagX+510 && y >= diagY+390 && y <= diagY+420 {
		u.ShowPicker = false
		return
	}
}

// ActivateCLI launches the interactive CLI console in a background goroutine
// if not already running.
func (u *UI) ActivateCLI() {
	u.cliMutex.Lock()
	if u.cliRunning {
		u.cliMutex.Unlock()
		fmt.Println("\n[fMSXgo] Interactive CLI is already active in this terminal. Please use this console.")
		return
	}
	u.cliRunning = true
	u.cliMutex.Unlock()

	go func() {
		defer func() {
			u.cliMutex.Lock()
			u.cliRunning = false
			u.cliMutex.Unlock()
		}()

		fmt.Println()
		fmt.Println("=================================================================")
		fmt.Println("       fMSXgo Developer CLI Shell (Activated from GUI)           ")
		fmt.Println("=================================================================")
		fmt.Println(" Type 'windows', 'window' or 'gui' to refocus the Graphical Window.")
		fmt.Println(" Type 'quit', 'exit' or 'q' to terminate fMSXgo.")
		fmt.Println("-----------------------------------------------------------------")

		sh := shell.New(u.Machine, os.Stdin, os.Stdout)
		sh.Run()

		if sh.SwitchToGUI {
			if ebiten.IsWindowMinimized() {
				ebiten.RestoreWindow()
			}
			fmt.Println("[fMSXgo] Refocusing Graphical Window (GUI)...")
		} else {
			// User exited the shell via quit/exit/q
			u.ShouldExit = true
		}
	}()
}

func init() {
	_ = color.RGBA{}
}
