package ui

import (
	"fmt"
	"image/color"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/inpututil"

	"fmsxgo/pkg/i18n"
	"fmsxgo/pkg/msx"
	"fmsxgo/pkg/ui/font"
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
	ActiveMenu  string // "File", "Setup", "Help", or ""
	ShowAbout   bool
	ShowConfig  bool
	ShowCatalog bool
	ShouldExit  bool

	// Drawing buffers (re-skinned dynamically when theme changes)
	barImg        *ebiten.Image
	menuBg        *ebiten.Image
	dialogBg      *ebiten.Image
	configDlgBg   *ebiten.Image
	catalogDlgBg  *ebiten.Image
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
		u.menuBg = ebiten.NewImage(230, 65)
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
		} else {
			u.ActiveMenu = ""
		}
	}

	// 4. Click on File dropdown
	if u.ActiveMenu == "File" {
		if x >= 10 && x <= 240 {
			if y >= MenuBarH && y < MenuBarH+32 {
				// Reset Machine
				u.ActiveMenu = ""
				u.Machine.Reset()
				return
			} else if y >= MenuBarH+32 && y < MenuBarH+65 {
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

	// Draw Machine Status Overlay in screen area
	u.drawStatus(screen)

	// 2. Draw Top Menu Bar
	barOp := &ebiten.DrawImageOptions{}
	screen.DrawImage(u.barImg, barOp)

	// Draw Menu text labels (antialiased TrueType)
	font.DrawBold(screen, i18n.T("menu_file"), 16, 5, 13, eff.MenuBarText)
	font.DrawBold(screen, i18n.T("menu_setup"), 76, 5, 13, eff.MenuBarText)
	font.DrawBold(screen, i18n.T("menu_help"), 156, 5, 13, eff.MenuBarText)

	// 3. Draw Active Dropdown Menu
	if u.ActiveMenu == "File" {
		dropOp := &ebiten.DrawImageOptions{}
		dropOp.GeoM.Translate(10, MenuBarH)
		screen.DrawImage(u.menuBg, dropOp)
		font.Draw(screen, i18n.T("menu_reset"), 18, MenuBarH+6, 13, eff.MenuDropdownText)
		font.Draw(screen, i18n.T("menu_exit"), 18, MenuBarH+34, 13, eff.MenuDropdownText)
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

func init() {
	_ = color.RGBA{}
}
