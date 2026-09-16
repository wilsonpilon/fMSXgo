package ui

import (
	"fmt"
	"image/color"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/ebitenutil"
	"github.com/hajimehoshi/ebiten/v2/inpututil"

	"fmsxgo/pkg/msx"
)

const (
	WindowWidth  = 640
	WindowHeight = 480
	MenuBarH     = 24
)

// UI represents the graphical interface for fMSXgo.
type UI struct {
	Machine *msx.Machine

	// Menu state
	ActiveMenu  string // "File", "Help", or ""
	ShowAbout   bool
	ShouldExit  bool

	// Drawing buffers
	barImg    *ebiten.Image
	menuBg    *ebiten.Image
	dialogBg  *ebiten.Image
	buttonBg  *ebiten.Image
	screenBg  *ebiten.Image
}

// New creates a new UI instance.
func New(machine *msx.Machine) *UI {
	ui := &UI{
		Machine: machine,
	}

	ui.barImg = ebiten.NewImage(WindowWidth, MenuBarH)
	ui.barImg.Fill(color.RGBA{R: 35, G: 38, B: 46, A: 255})

	ui.menuBg = ebiten.NewImage(140, 60)
	ui.menuBg.Fill(color.RGBA{R: 45, G: 48, B: 58, A: 255})

	ui.dialogBg = ebiten.NewImage(380, 220)
	ui.dialogBg.Fill(color.RGBA{R: 28, G: 30, B: 38, A: 245})

	ui.buttonBg = ebiten.NewImage(80, 24)
	ui.buttonBg.Fill(color.RGBA{R: 65, G: 110, B: 180, A: 255})

	ui.screenBg = ebiten.NewImage(WindowWidth, WindowHeight-MenuBarH)
	ui.screenBg.Fill(color.RGBA{R: 16, G: 18, B: 24, A: 255})

	return ui
}

// Run launches the Ebitengine graphical window.
func (u *UI) Run() error {
	ebiten.SetWindowSize(WindowWidth, WindowHeight)
	ebiten.SetWindowTitle("fMSXgo - MSX Emulator & Developer Workstation (64-bit)")
	ebiten.SetWindowResizingMode(ebiten.WindowResizingModeEnabled)

	return ebiten.RunGame(u)
}

// Update updates game logic every frame (60 FPS).
func (u *UI) Update() error {
	if u.ShouldExit || ebiten.IsKeyPressed(ebiten.KeyEscape) {
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
	// If About dialog is open, click anywhere closes it
	if u.ShowAbout {
		u.ShowAbout = false
		return
	}

	// Click on top menu bar
	if y < MenuBarH {
		if x >= 10 && x <= 60 {
			if u.ActiveMenu == "File" {
				u.ActiveMenu = ""
			} else {
				u.ActiveMenu = "File"
			}
			return
		} else if x >= 70 && x <= 120 {
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

	// Click on File dropdown
	if u.ActiveMenu == "File" {
		if x >= 10 && x <= 150 && y >= MenuBarH && y <= MenuBarH+60 {
			relY := y - MenuBarH
			if relY < 30 {
				// Reset
				u.Machine.Reset()
				u.ActiveMenu = ""
			} else {
				// Exit
				u.ShouldExit = true
			}
			return
		}
	}

	// Click on Help dropdown
	if u.ActiveMenu == "Help" {
		if x >= 70 && x <= 210 && y >= MenuBarH && y <= MenuBarH+35 {
			u.ShowAbout = true
			u.ActiveMenu = ""
			return
		}
	}

	u.ActiveMenu = ""
}

// Draw renders the frame.
func (u *UI) Draw(screen *ebiten.Image) {
	// 1. Draw main screen background
	op := &ebiten.DrawImageOptions{}
	op.GeoM.Translate(0, MenuBarH)
	screen.DrawImage(u.screenBg, op)

	// Draw Machine Status Banner in screen area
	u.drawStatus(screen)

	// 2. Draw Top Menu Bar
	barOp := &ebiten.DrawImageOptions{}
	screen.DrawImage(u.barImg, barOp)

	// Draw Menu text labels
	ebitenutil.DebugPrintAt(screen, "File", 16, 5)
	ebitenutil.DebugPrintAt(screen, "Help", 76, 5)

	// 3. Draw Active Dropdown Menu
	if u.ActiveMenu == "File" {
		dropOp := &ebiten.DrawImageOptions{}
		dropOp.GeoM.Translate(10, MenuBarH)
		screen.DrawImage(u.menuBg, dropOp)
		ebitenutil.DebugPrintAt(screen, "Reset Machine", 18, MenuBarH+8)
		ebitenutil.DebugPrintAt(screen, "Exit", 18, MenuBarH+34)
	} else if u.ActiveMenu == "Help" {
		dropOp := &ebiten.DrawImageOptions{}
		dropOp.GeoM.Translate(70, MenuBarH)
		screen.DrawImage(u.menuBg, dropOp)
		ebitenutil.DebugPrintAt(screen, "About fMSXgo", 78, MenuBarH+8)
	}

	// 4. Draw About Modal Dialog
	if u.ShowAbout {
		u.drawAboutModal(screen)
	}
}

func (u *UI) drawStatus(screen *ebiten.Image) {
	ebitenutil.DebugPrintAt(screen, "=== fMSXgo - MSX Emulator & Developer Workstation ===", 120, 50)

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

	ebitenutil.DebugPrintAt(screen, fmt.Sprintf("Hardware Model : %s", model), 80, 100)
	ebitenutil.DebugPrintAt(screen, fmt.Sprintf("Video Standard : %s", video), 80, 120)
	ebitenutil.DebugPrintAt(screen, fmt.Sprintf("Main RAM       : %d KB (%d pages)", u.Machine.Config.RAMPages*16, u.Machine.Config.RAMPages), 80, 140)
	ebitenutil.DebugPrintAt(screen, fmt.Sprintf("VRAM           : %d KB", u.Machine.Config.VRAMPages*64), 80, 160)

	cpu := u.Machine.CPU
	ebitenutil.DebugPrintAt(screen, "--- CPU Z80 Live State ---", 80, 200)
	ebitenutil.DebugPrintAt(screen, fmt.Sprintf("PC: %04Xh   SP: %04Xh   AF: %04Xh   BC: %04Xh   DE: %04Xh   HL: %04Xh",
		cpu.PC, cpu.SP, cpu.AF(), cpu.BC(), cpu.DE(), cpu.HL()), 80, 220)
	ebitenutil.DebugPrintAt(screen, fmt.Sprintf("IX: %04Xh   IY: %04Xh   I: %02Xh    R: %02Xh    IM: %d   Halted: %t",
		cpu.IX, cpu.IY, cpu.I, cpu.R, cpu.IM, cpu.Halted), 80, 240)

	ebitenutil.DebugPrintAt(screen, "Tips:", 80, 320)
	ebitenutil.DebugPrintAt(screen, " - Click 'File -> Exit' or press [ESC] to quit.", 80, 340)
	ebitenutil.DebugPrintAt(screen, " - Click 'Help -> About' for project credits & license.", 80, 360)
	ebitenutil.DebugPrintAt(screen, " - Start with '--no-window' to run the Interactive CLI Developer Shell.", 80, 380)
}

func (u *UI) drawAboutModal(screen *ebiten.Image) {
	diagX := float64((WindowWidth - 380) / 2)
	diagY := float64((WindowHeight - 220) / 2)

	op := &ebiten.DrawImageOptions{}
	op.GeoM.Translate(diagX, diagY)
	screen.DrawImage(u.dialogBg, op)

	// Text inside about
	ebitenutil.DebugPrintAt(screen, "ABOUT fMSXgo", int(diagX)+140, int(diagY)+20)
	ebitenutil.DebugPrintAt(screen, "fMSXgo - MSX Emulator & Dev Workstation", int(diagX)+40, int(diagY)+50)
	ebitenutil.DebugPrintAt(screen, "Version 0.1.0 ('Phantasm') - 64-bit", int(diagX)+40, int(diagY)+70)
	ebitenutil.DebugPrintAt(screen, "Core Logic: (C) Marat Fayzullin (fMSX)", int(diagX)+40, int(diagY)+95)
	ebitenutil.DebugPrintAt(screen, "Go Port & Tools: (C) Wilson Pilon", int(diagX)+40, int(diagY)+115)
	ebitenutil.DebugPrintAt(screen, "Strictly Non-Commercial Use Only", int(diagX)+40, int(diagY)+135)

	// Close Button
	btnOp := &ebiten.DrawImageOptions{}
	btnOp.GeoM.Translate(diagX+150, diagY+170)
	screen.DrawImage(u.buttonBg, btnOp)
	ebitenutil.DebugPrintAt(screen, "  [ OK ]  ", int(diagX)+158, int(diagY)+175)
}

// Layout defines the logical screen size.
func (u *UI) Layout(outsideWidth, outsideHeight int) (int, int) {
	return WindowWidth, WindowHeight
}

// IsNoWindowRequested returns true if headless / cli mode was explicitly requested
func IsNoWindowRequested(args []string) bool {
	for _, a := range args {
		if a == "--no-window" || a == "-no-window" || a == "-cli" || a == "--cli" {
			return true
		}
	}
	return false
}
