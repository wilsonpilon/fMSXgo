package ui

import (
	"fmt"
	"image/color"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/ebitenutil"
	"github.com/hajimehoshi/ebiten/v2/inpututil"

	"fmsxgo/pkg/i18n"
	"fmsxgo/pkg/msx"
	"fmsxgo/pkg/ui/theme"
)

const (
	WindowWidth  = 640
	WindowHeight = 480
	MenuBarH     = 24
)

// UI represents the graphical interface for fMSXgo.
type UI struct {
	Machine *msx.Machine

	// Modal and menu state
	ActiveMenu string // "File", "Setup", "Help", or ""
	ShowAbout  bool
	ShowConfig bool
	ShouldExit bool

	// Drawing buffers (re-skinned dynamically when theme changes)
	barImg        *ebiten.Image
	menuBg        *ebiten.Image
	dialogBg      *ebiten.Image
	configDlgBg   *ebiten.Image
	buttonBg      *ebiten.Image
	screenBg      *ebiten.Image
	selectedRowBg *ebiten.Image
}

// New creates a new UI instance.
func New(machine *msx.Machine) *UI {
	ui := &UI{
		Machine: machine,
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
		u.menuBg = ebiten.NewImage(180, 65)
	}
	u.menuBg.Fill(eff.MenuDropdownBg)

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

	// 5. Configuration Dialog background (580 x 420)
	if u.configDlgBg == nil {
		u.configDlgBg = ebiten.NewImage(580, 420)
	}
	u.configDlgBg.Fill(eff.DialogBg)

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

	// Escape key handling
	if inpututil.IsKeyJustPressed(ebiten.KeyEscape) {
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

	return nil
}

func (u *UI) handleClick(x, y int) {
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
		} else {
			u.ActiveMenu = ""
		}
	}

	// 4. Click on File dropdown
	if u.ActiveMenu == "File" {
		if x >= 10 && x <= 190 && y >= MenuBarH && y <= MenuBarH+65 {
			relY := y - MenuBarH
			if relY < 32 {
				u.Machine.Reset()
				u.ActiveMenu = ""
			} else {
				u.ShouldExit = true
			}
			return
		}
	}

	// 5. Click on Setup dropdown
	if u.ActiveMenu == "Setup" {
		if x >= 70 && x <= 250 && y >= MenuBarH && y <= MenuBarH+65 {
			relY := y - MenuBarH
			if relY < 35 {
				u.ShowConfig = true
				u.ActiveMenu = ""
			}
			return
		}
	}

	// 6. Click on Help dropdown
	if u.ActiveMenu == "Help" {
		if x >= 150 && x <= 330 && y >= MenuBarH && y <= MenuBarH+40 {
			u.ShowAbout = true
			u.ActiveMenu = ""
			return
		}
	}

	u.ActiveMenu = ""
}

func (u *UI) handleConfigClick(x, y int) {
	diagX := (WindowWidth - 580) / 2
	diagY := (WindowHeight - 420) / 2

	// Click outside modal closes it
	if x < diagX || x > diagX+580 || y < diagY || y > diagY+420 {
		u.ShowConfig = false
		return
	}

	// Click on Save & Close Button
	if x >= diagX+200 && x <= diagX+380 && y >= diagY+380 && y <= diagY+410 {
		u.ShowConfig = false
		return
	}

	// Left Column: Language items (x: diagX+20 .. diagX+220)
	if x >= diagX+20 && x <= diagX+230 {
		startY := diagY + 80
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

	// Right Column: Theme items (x: diagX+260 .. diagX+560)
	if x >= diagX+260 && x <= diagX+560 {
		startY := diagY + 80
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
}

// Draw renders the full GUI window.
func (u *UI) Draw(screen *ebiten.Image) {
	// 1. Draw main screen background
	op := &ebiten.DrawImageOptions{}
	op.GeoM.Translate(0, MenuBarH)
	screen.DrawImage(u.screenBg, op)

	// Draw Machine Status Overlay in screen area
	u.drawStatus(screen)

	// 2. Draw Top Menu Bar
	barOp := &ebiten.DrawImageOptions{}
	screen.DrawImage(u.barImg, barOp)

	// Draw Menu text labels (translated)
	ebitenutil.DebugPrintAt(screen, i18n.T("menu_file"), 16, 5)
	ebitenutil.DebugPrintAt(screen, i18n.T("menu_setup"), 76, 5)
	ebitenutil.DebugPrintAt(screen, i18n.T("menu_help"), 156, 5)

	// 3. Draw Active Dropdown Menu
	if u.ActiveMenu == "File" {
		dropOp := &ebiten.DrawImageOptions{}
		dropOp.GeoM.Translate(10, MenuBarH)
		screen.DrawImage(u.menuBg, dropOp)
		ebitenutil.DebugPrintAt(screen, i18n.T("menu_reset"), 18, MenuBarH+8)
		ebitenutil.DebugPrintAt(screen, i18n.T("menu_exit"), 18, MenuBarH+36)
	} else if u.ActiveMenu == "Setup" {
		dropOp := &ebiten.DrawImageOptions{}
		dropOp.GeoM.Translate(70, MenuBarH)
		screen.DrawImage(u.menuBg, dropOp)
		ebitenutil.DebugPrintAt(screen, i18n.T("menu_config"), 78, MenuBarH+10)
	} else if u.ActiveMenu == "Help" {
		dropOp := &ebiten.DrawImageOptions{}
		dropOp.GeoM.Translate(150, MenuBarH)
		screen.DrawImage(u.menuBg, dropOp)
		ebitenutil.DebugPrintAt(screen, i18n.T("menu_about"), 158, MenuBarH+10)
	}

	// 4. Draw About Modal Dialog
	if u.ShowAbout {
		u.drawAboutModal(screen)
	}

	// 5. Draw Configuration Modal Dialog
	if u.ShowConfig {
		u.drawConfigModal(screen)
	}
}

func (u *UI) drawStatus(screen *ebiten.Image) {
	eff := theme.GetEffective()

	ebitenutil.DebugPrintAt(screen, i18n.T("lbl_title"), 80, 45)

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

	ebitenutil.DebugPrintAt(screen, fmt.Sprintf("%-18s %s", i18n.T("lbl_model"), model), 80, 85)
	ebitenutil.DebugPrintAt(screen, fmt.Sprintf("%-18s %s", i18n.T("lbl_video"), video), 80, 105)
	ebitenutil.DebugPrintAt(screen, fmt.Sprintf("%-18s %d KB (%d pages)", i18n.T("lbl_ram"), u.Machine.Config.RAMPages*16, u.Machine.Config.RAMPages), 80, 125)
	ebitenutil.DebugPrintAt(screen, fmt.Sprintf("%-18s %d KB", i18n.T("lbl_vram"), u.Machine.Config.VRAMPages*64), 80, 145)

	cpu := u.Machine.CPU
	ebitenutil.DebugPrintAt(screen, i18n.T("lbl_cpu_state"), 80, 185)
	ebitenutil.DebugPrintAt(screen, fmt.Sprintf("PC: %04Xh   SP: %04Xh   AF: %04Xh   BC: %04Xh   DE: %04Xh   HL: %04Xh",
		cpu.PC, cpu.SP, cpu.AF(), cpu.BC(), cpu.DE(), cpu.HL()), 80, 205)
	ebitenutil.DebugPrintAt(screen, fmt.Sprintf("IX: %04Xh   IY: %04Xh   I: %02Xh    R: %02Xh    IM: %d   Halted: %t",
		cpu.IX, cpu.IY, cpu.I, cpu.R, cpu.IM, cpu.Halted), 80, 225)

	// Active Theme Indicator
	themeInfo := fmt.Sprintf("Active Theme   : %s (%s)", eff.Name, theme.GetCurrent())
	ebitenutil.DebugPrintAt(screen, themeInfo, 80, 265)

	ebitenutil.DebugPrintAt(screen, i18n.T("lbl_tips"), 80, 310)
	ebitenutil.DebugPrintAt(screen, i18n.T("lbl_tip_exit"), 80, 330)
	ebitenutil.DebugPrintAt(screen, i18n.T("lbl_tip_about"), 80, 350)
	ebitenutil.DebugPrintAt(screen, " - Open 'Setup -> Configuration...' to choose Language & Theme.", 80, 370)
	ebitenutil.DebugPrintAt(screen, i18n.T("lbl_tip_cli"), 80, 390)
}

func (u *UI) drawAboutModal(screen *ebiten.Image) {
	diagX := float64((WindowWidth - 440) / 2)
	diagY := float64((WindowHeight - 230) / 2)

	op := &ebiten.DrawImageOptions{}
	op.GeoM.Translate(diagX, diagY)
	screen.DrawImage(u.dialogBg, op)

	// Text inside about
	ebitenutil.DebugPrintAt(screen, i18n.T("about_title"), int(diagX)+150, int(diagY)+20)
	ebitenutil.DebugPrintAt(screen, i18n.T("about_app"), int(diagX)+30, int(diagY)+50)
	ebitenutil.DebugPrintAt(screen, fmt.Sprintf("%s: 0.1.2 ('Phantasm') - 64-bit", i18n.T("about_version")), int(diagX)+30, int(diagY)+70)
	ebitenutil.DebugPrintAt(screen, i18n.T("about_core"), int(diagX)+30, int(diagY)+95)
	ebitenutil.DebugPrintAt(screen, i18n.T("about_port"), int(diagX)+30, int(diagY)+115)
	ebitenutil.DebugPrintAt(screen, i18n.T("about_license"), int(diagX)+30, int(diagY)+135)

	// Close Button
	btnOp := &ebiten.DrawImageOptions{}
	btnOp.GeoM.Translate(diagX+140, diagY+175)
	screen.DrawImage(u.buttonBg, btnOp)
	ebitenutil.DebugPrintAt(screen, i18n.T("btn_ok"), int(diagX)+190, int(diagY)+181)
}

func (u *UI) drawConfigModal(screen *ebiten.Image) {
	diagX := (WindowWidth - 580) / 2
	diagY := (WindowHeight - 420) / 2

	// 1. Draw dialog background
	op := &ebiten.DrawImageOptions{}
	op.GeoM.Translate(float64(diagX), float64(diagY))
	screen.DrawImage(u.configDlgBg, op)

	// 2. Title
	ebitenutil.DebugPrintAt(screen, fmt.Sprintf("=== %s ===", i18n.T("dlg_config_title")), diagX+130, diagY+16)
	ebitenutil.DebugPrintAt(screen, "------------------------------------------------------------------", diagX+20, diagY+36)

	// 3. Left Column: Languages
	ebitenutil.DebugPrintAt(screen, i18n.T("cfg_sec_language"), diagX+20, diagY+56)
	currentLang := i18n.GetLanguage()
	langStartY := diagY + 80
	for i, l := range i18n.SupportedLanguages {
		yPos := langStartY + (i * 26)
		isSelected := l.Code == currentLang

		prefix := "[ ] "
		if isSelected {
			prefix = "[*] "
			// Draw selection highlight pill
			rowOp := &ebiten.DrawImageOptions{}
			rowOp.GeoM.Scale(0.8, 1.0)
			rowOp.GeoM.Translate(float64(diagX+15), float64(yPos-2))
			screen.DrawImage(u.selectedRowBg, rowOp)
		}

		label := fmt.Sprintf("%s%-14s (%s)", prefix, l.NativeName, l.Code)
		ebitenutil.DebugPrintAt(screen, label, diagX+20, yPos+2)
	}

	// 4. Right Column: Themes
	ebitenutil.DebugPrintAt(screen, i18n.T("cfg_sec_theme"), diagX+260, diagY+56)
	currentTheme := theme.GetCurrent()
	themes := theme.List()
	themeStartY := diagY + 80
	for i, th := range themes {
		yPos := themeStartY + (i * 25)
		isSelected := th.ID == currentTheme

		prefix := "[ ] "
		if isSelected {
			prefix = "[*] "
			// Draw selection highlight pill
			rowOp := &ebiten.DrawImageOptions{}
			rowOp.GeoM.Scale(1.15, 1.0)
			rowOp.GeoM.Translate(float64(diagX+255), float64(yPos-2))
			screen.DrawImage(u.selectedRowBg, rowOp)
		}

		catBadge := fmt.Sprintf("[%s]", th.Category)
		label := fmt.Sprintf("%s%-18s %s", prefix, th.Name, catBadge)
		ebitenutil.DebugPrintAt(screen, label, diagX+260, yPos+2)
	}

	// 5. Save & Close Button
	btnOp := &ebiten.DrawImageOptions{}
	btnOp.GeoM.Translate(float64(diagX+200), float64(diagY+380))
	screen.DrawImage(u.buttonBg, btnOp)
	ebitenutil.DebugPrintAt(screen, i18n.T("btn_save_close"), diagX+225, diagY+386)
}

// Layout defines the logical window resolution.
func (u *UI) Layout(outsideWidth, outsideHeight int) (int, int) {
	return WindowWidth, WindowHeight
}

func init() {
	_ = color.RGBA{}
}
