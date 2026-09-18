package ui

import (
	"fmt"
	"image/color"
	"os"
	"sync"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/inpututil"

	"fmsxgo/pkg/i18n"
	"fmsxgo/pkg/msx"
	"fmsxgo/pkg/shell"
	"fmsxgo/pkg/ui/font"
	"fmsxgo/pkg/ui/theme"
	"fmsxgo/pkg/vdp"
)

const (
	WindowWidth  = 640
	WindowHeight = 480
	MenuBarH     = 24
)

// UI represents the graphical interface for fMSXgo.
type UI struct {
	Machine *msx.Machine

	// Live MSX Video & Display Mode
	msxScreenImg    *ebiten.Image
	DisplayMode     int  // 0 = MSX Video Display (default), 1 = Debug Status Overlay
	EmulationPaused bool // Pause CPU/frame execution

	// Modal and menu state
	ActiveMenu  string // "File", "Setup", "Help", or ""
	ShowAbout   bool
	ShowConfig  bool
	ShowCatalog bool
	ShouldExit  bool

	// Drawing buffers (re-skinned dynamically when theme changes)
	barImg        *ebiten.Image
	menuBg        *ebiten.Image
	fileMenuBg    *ebiten.Image
	dialogBg      *ebiten.Image
	configDlgBg   *ebiten.Image
	catalogDlgBg  *ebiten.Image
	buttonBg      *ebiten.Image
	screenBg      *ebiten.Image
	selectedRowBg *ebiten.Image

	// Interactive CLI goroutine management
	cliRunning bool
	cliMutex   sync.Mutex
}

// New creates a new UI instance.
func New(machine *msx.Machine) *UI {
	ui := &UI{
		Machine:      machine,
		msxScreenImg: ebiten.NewImage(vdp.DisplayWidth, vdp.DisplayHeight),
		DisplayMode:  0,
	}

	ui.ApplyTheme()
	return ui
}

// ApplyTheme re-skins all UI buffers using the currently active theme.
func (u *UI) ApplyTheme() {
	eff := theme.GetEffective()

	// 1. Top menu bar
	if u.barImg == nil {
		u.barImg = ebiten.NewImage(WindowWidth, MenuBarH)
	}
	u.barImg.Fill(eff.MenuBarBg)

	// 2. Dropdown menu background
	if u.menuBg == nil {
		u.menuBg = ebiten.NewImage(230, 65)
	}
	u.menuBg.Fill(eff.MenuDropdownBg)

	// 2b. File dropdown menu background (3 items: Reset, CLI, Exit)
	if u.fileMenuBg == nil {
		u.fileMenuBg = ebiten.NewImage(230, 95)
	}
	u.fileMenuBg.Fill(eff.MenuDropdownBg)

	// 3. Screen background
	if u.screenBg == nil {
		u.screenBg = ebiten.NewImage(WindowWidth, WindowHeight-MenuBarH)
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

// Run launches the Ebitengine graphical window.
func (u *UI) Run() error {
	ebiten.SetWindowSize(WindowWidth, WindowHeight)
	ebiten.SetWindowTitle("fMSXgo - MSX Emulator & Developer Workstation (64-bit)")
	ebiten.SetWindowResizingMode(ebiten.WindowResizingModeEnabled)

	return ebiten.RunGame(u)
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

	// Escape key handling
	if inpututil.IsKeyJustPressed(ebiten.KeyEscape) {
		if u.ShowCatalog {
			u.ShowCatalog = false
			return nil
		}
		if u.ShowConfig {
			u.ShowConfig = false
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

	// Handle mouse clicks
	if inpututil.IsMouseButtonJustPressed(ebiten.MouseButtonLeft) {
		mx, my := ebiten.CursorPosition()
		u.handleClick(mx, my)
	}

	// Advance MSX emulation frame if not paused
	if u.Machine != nil && !u.EmulationPaused {
		u.updateKeyboard()
		u.Machine.StepFrame()
		fb := u.Machine.GetFrameBuffer()
		if fb != nil && u.msxScreenImg != nil {
			u.msxScreenImg.WritePixels(fb)
		}
	}

	return nil
}

func (u *UI) handleClick(x, y int) {
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

	// 3. Click on top menu bar
	if y < MenuBarH {
		if x >= 10 && x <= 65 {
			if u.ActiveMenu == "File" {
				u.ActiveMenu = ""
			} else {
				u.ActiveMenu = "File"
			}
			return
		} else if x >= 70 && x <= 145 {
			if u.ActiveMenu == "Setup" {
				u.ActiveMenu = ""
			} else {
				u.ActiveMenu = "Setup"
			}
			return
		} else if x >= 150 && x <= 210 {
			if u.ActiveMenu == "Help" {
				u.ActiveMenu = ""
			} else {
				u.ActiveMenu = "Help"
			}
			return
		} else if x >= WindowWidth-170 && x <= WindowWidth-10 {
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
			if y >= MenuBarH && y < MenuBarH+30 {
				// Reset Machine
				u.ActiveMenu = ""
				u.Machine.Reset()
				return
			} else if y >= MenuBarH+30 && y < MenuBarH+60 {
				// Launch / Activate CLI
				u.ActiveMenu = ""
				u.ActivateCLI()
				return
			} else if y >= MenuBarH+60 && y < MenuBarH+95 {
				// Exit
				u.ShouldExit = true
				return
			}
		}
		u.ActiveMenu = ""
		return
	}

	// 5. Click on Setup dropdown
	if u.ActiveMenu == "Setup" {
		if x >= 70 && x <= 300 {
			if y >= MenuBarH && y < MenuBarH+32 {
				// Open Configuration (Language, Theme, Font)
				u.ActiveMenu = ""
				u.ShowConfig = true
				return
			} else if y >= MenuBarH+32 && y < MenuBarH+65 {
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
		if x >= 150 && x <= 380 && y >= MenuBarH && y < MenuBarH+35 {
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
	diagX := (WindowWidth - 600) / 2
	diagY := (WindowHeight - 420) / 2

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

	// 1. Draw Screen Background (workstation monitor area)
	screenOp := &ebiten.DrawImageOptions{}
	screenOp.GeoM.Translate(0, MenuBarH)
	screen.DrawImage(u.screenBg, screenOp)

	if u.DisplayMode == 0 && u.msxScreenImg != nil {
		// Draw Live MSX Screen at 2x integer scale centered
		msxOp := &ebiten.DrawImageOptions{}
		msxOp.GeoM.Scale(2, 2)
		msxOp.GeoM.Translate(48, MenuBarH)
		screen.DrawImage(u.msxScreenImg, msxOp)
	} else {
		// Draw Machine Status / Developer Debug Overlay
		u.drawStatus(screen)
	}

	// 2. Draw Top Menu Bar
	barOp := &ebiten.DrawImageOptions{}
	screen.DrawImage(u.barImg, barOp)

	// Draw Menu text labels (antialiased TrueType)
	font.DrawBold(screen, i18n.T("menu_file"), 16, 5, 13, eff.MenuBarText)
	font.DrawBold(screen, i18n.T("menu_setup"), 76, 5, 13, eff.MenuBarText)
	font.DrawBold(screen, i18n.T("menu_help"), 156, 5, 13, eff.MenuBarText)

	// Display mode badge on the right
	badgeText := "[ F11: Screen ]"
	if u.DisplayMode == 1 {
		badgeText = "[ F11: Debug ]"
	}
	font.DrawCode(screen, badgeText, WindowWidth-145, 5, 12, eff.AccentColor)

	// 3. Draw Active Dropdown Menu
	if u.ActiveMenu == "File" {
		dropOp := &ebiten.DrawImageOptions{}
		dropOp.GeoM.Translate(10, MenuBarH)
		screen.DrawImage(u.fileMenuBg, dropOp)
		font.Draw(screen, i18n.T("menu_reset"), 18, MenuBarH+6, 13, eff.MenuDropdownText)
		font.Draw(screen, i18n.T("menu_cli"), 18, MenuBarH+34, 13, eff.MenuDropdownText)
		font.Draw(screen, i18n.T("menu_exit"), 18, MenuBarH+64, 13, eff.MenuDropdownText)
	} else if u.ActiveMenu == "Setup" {
		dropOp := &ebiten.DrawImageOptions{}
		dropOp.GeoM.Translate(70, MenuBarH)
		screen.DrawImage(u.menuBg, dropOp)
		font.Draw(screen, i18n.T("menu_config"), 78, MenuBarH+6, 13, eff.MenuDropdownText)
		font.Draw(screen, i18n.T("menu_catalog"), 78, MenuBarH+34, 13, eff.MenuDropdownText)
	} else if u.ActiveMenu == "Help" {
		dropOp := &ebiten.DrawImageOptions{}
		dropOp.GeoM.Translate(150, MenuBarH)
		screen.DrawImage(u.menuBg, dropOp)
		font.Draw(screen, i18n.T("menu_about"), 158, MenuBarH+8, 13, eff.MenuDropdownText)
	}

	// 4. Draw About Modal Dialog
	if u.ShowAbout {
		u.drawAboutModal(screen)
	}

	// 5. Draw Configuration Modal Dialog
	if u.ShowConfig {
		u.drawConfigModal(screen)
	}

	// 6. Draw ROM Catalog Modal Dialog
	if u.ShowCatalog {
		u.drawCatalogModal(screen)
	}
}

func (u *UI) drawStatus(screen *ebiten.Image) {
	eff := theme.GetEffective()

	font.DrawBold(screen, i18n.T("lbl_title"), 80, 42, 14, eff.StatusTitle)

	model := "MSX 2"
	if u.Machine.Config.Model == msx.ModelMSX1 {
		model = "MSX 1"
	} else if u.Machine.Config.Model == msx.ModelMSX2P {
		model = "MSX 2+"
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
	font.DrawBold(screen, fmt.Sprintf("%d KB", u.Machine.Config.VRAMPages*64), 240, 146, 13, eff.StatusValue)

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
	if u.ShowConfig || u.ShowCatalog || u.ShowAbout {
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

func (u *UI) drawAboutModal(screen *ebiten.Image) {
	eff := theme.GetEffective()
	diagX := float64((WindowWidth - 440) / 2)
	diagY := float64((WindowHeight - 230) / 2)

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
	diagX := (WindowWidth - 600) / 2
	diagY := (WindowHeight - 420) / 2

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
	diagX := (WindowWidth - 620) / 2
	diagY := (WindowHeight - 440) / 2

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
	diagX := (WindowWidth - 620) / 2
	diagY := (WindowHeight - 440) / 2

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
	return WindowWidth, WindowHeight
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
