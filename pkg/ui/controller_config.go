package ui

import (
	"fmt"
	"image/color"
	"strconv"

	"fmsxgo/pkg/i18n"
	"fmsxgo/pkg/storage"
	"fmsxgo/pkg/ui/font"
	"fmsxgo/pkg/ui/theme"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/vector"
)

// ControllerConfig stores user-calibrated deadzones and button mappings for MSX joysticks.
type ControllerConfig struct {
	Deadzone   [2]float64 // 0.05 to 0.70 (default: 0.35)
	SwapAB     [2]bool    // Swap Button A and Button B
	ActivePort int        // 0 = Port 1, 1 = Port 2
}

// DefaultControllerConfig creates default calibration settings.
func DefaultControllerConfig() ControllerConfig {
	return ControllerConfig{
		Deadzone:   [2]float64{0.35, 0.35},
		SwapAB:     [2]bool{false, false},
		ActivePort: 0,
	}
}

// Load loads controller calibration from SQLite config table.
func (cfg *ControllerConfig) Load(db *storage.DB) {
	if db == nil {
		return
	}
	for p := 0; p < 2; p++ {
		dzKey := fmt.Sprintf("joy%d_deadzone", p+1)
		if val := db.GetConfig(dzKey, ""); val != "" {
			if dz, err := strconv.ParseFloat(val, 64); err == nil && dz >= 0.05 && dz <= 0.75 {
				cfg.Deadzone[p] = dz
			}
		}
		swapKey := fmt.Sprintf("joy%d_swap_ab", p+1)
		if val := db.GetConfig(swapKey, ""); val != "" {
			cfg.SwapAB[p] = (val == "true" || val == "1")
		}
	}
}

// Save persists controller calibration to SQLite config table.
func (cfg *ControllerConfig) Save(db *storage.DB) {
	if db == nil {
		return
	}
	for p := 0; p < 2; p++ {
		dzKey := fmt.Sprintf("joy%d_deadzone", p+1)
		_ = db.SetConfig(dzKey, fmt.Sprintf("%.2f", cfg.Deadzone[p]))
		swapKey := fmt.Sprintf("joy%d_swap_ab", p+1)
		_ = db.SetConfig(swapKey, fmt.Sprintf("%t", cfg.SwapAB[p]))
	}
}

// drawControllerModal renders the controller calibration dialog.
func (u *UI) drawControllerModal(screen *ebiten.Image) {
	eff := theme.GetEffective()
	winW, winH := screen.Bounds().Dx(), screen.Bounds().Dy()

	dlgW, dlgH := 520, 360
	dlgX := (winW - dlgW) / 2
	dlgY := (winH - dlgH) / 2

	white := color.RGBA{255, 255, 255, 255}

	// Modal background
	vector.DrawFilledRect(screen, float32(dlgX), float32(dlgY), float32(dlgW), float32(dlgH), eff.DialogBg, false)
	vector.StrokeRect(screen, float32(dlgX), float32(dlgY), float32(dlgW), float32(dlgH), 2, eff.DialogBorder, false)

	// Header
	font.DrawBold(screen, i18n.T("ctrl_title"), float64(dlgX+16), float64(dlgY+16), 14, eff.AccentColor)

	// Port Tabs
	p := u.ControllerConfig.ActivePort
	tab1Bg := eff.ButtonBg
	tab1Fg := eff.ButtonText
	tab2Bg := eff.ButtonBg
	tab2Fg := eff.ButtonText
	if p == 0 {
		tab1Bg = eff.AccentColor
		tab1Fg = white
	} else {
		tab2Bg = eff.AccentColor
		tab2Fg = white
	}

	tabY := dlgY + 44
	vector.DrawFilledRect(screen, float32(dlgX+16), float32(tabY), 160, 24, tab1Bg, false)
	font.DrawBold(screen, i18n.T("ctrl_port1"), float64(dlgX+26), float64(tabY+5), 12, tab1Fg)

	vector.DrawFilledRect(screen, float32(dlgX+184), float32(tabY), 160, 24, tab2Bg, false)
	font.DrawBold(screen, i18n.T("ctrl_port2"), float64(dlgX+194), float64(tabY+5), 12, tab2Fg)

	// Connected Gamepad status
	gamepadIDs := ebiten.AppendGamepadIDs(nil)
	gpName := i18n.T("ctrl_no_gamepad")
	var activeGP ebiten.GamepadID
	hasGP := false
	if len(gamepadIDs) > p {
		activeGP = gamepadIDs[p]
		name := ebiten.GamepadName(activeGP)
		if name == "" {
			name = fmt.Sprintf("USB Gamepad #%d", p+1)
		}
		gpName = fmt.Sprintf("%s: %s", i18n.T("ctrl_device"), name)
		hasGP = true
	}

	statusY := dlgY + 76
	font.Draw(screen, gpName, float64(dlgX+16), float64(statusY), 11, eff.StatusLabel)

	// 1. Live Analog Stick Visualizer Box (140x140)
	boxX := float32(dlgX + 16)
	boxY := float32(dlgY + 98)
	boxSize := float32(130)
	centerX := boxX + boxSize/2
	centerY := boxY + boxSize/2

	// Outer square
	vector.DrawFilledRect(screen, boxX, boxY, boxSize, boxSize, eff.ScreenBg, false)
	vector.StrokeRect(screen, boxX, boxY, boxSize, boxSize, 1, eff.StatusLabel, false)

	// Deadzone inner square
	dz := float32(u.ControllerConfig.Deadzone[p])
	dzPx := (boxSize / 2) * dz
	vector.StrokeRect(screen, centerX-dzPx, centerY-dzPx, dzPx*2, dzPx*2, 1, color.RGBA{220, 80, 80, 140}, false)

	// Axes center cross
	vector.StrokeLine(screen, boxX, centerY, boxX+boxSize, centerY, 1, color.RGBA{120, 120, 120, 100}, false)
	vector.StrokeLine(screen, centerX, boxY, centerX, boxY+boxSize, 1, color.RGBA{120, 120, 120, 100}, false)

	// Current Analog Stick deflection
	var stickX, stickY float64
	if hasGP {
		stickX = ebiten.StandardGamepadAxisValue(activeGP, ebiten.StandardGamepadAxisLeftStickHorizontal)
		stickY = ebiten.StandardGamepadAxisValue(activeGP, ebiten.StandardGamepadAxisLeftStickVertical)
	}
	dotX := centerX + float32(stickX)*(boxSize/2)
	dotY := centerY + float32(stickY)*(boxSize/2)

	// Draw stick pointer
	isInsideDZ := (stickX >= -float64(dz) && stickX <= float64(dz) && stickY >= -float64(dz) && stickY <= float64(dz))
	dotColor := color.RGBA{50, 220, 100, 255}
	if isInsideDZ {
		dotColor = color.RGBA{220, 100, 100, 255}
	}
	vector.DrawFilledCircle(screen, dotX, dotY, 5, dotColor, false)

	// Stick coordinate text below box
	coordTxt := fmt.Sprintf("X: %+.2f  Y: %+.2f", stickX, stickY)
	font.Draw(screen, coordTxt, float64(int(boxX)+16), float64(int(boxY+boxSize)+6), 11, eff.StatusLabel)

	// 2. Right Side: Deadzone and Button Calibration Controls
	ctrlX := dlgX + 165
	ctrlY := dlgY + 98

	font.DrawBold(screen, i18n.T("ctrl_deadzone"), float64(ctrlX), float64(ctrlY), 12, eff.DialogText)

	// Deadzone adjustment buttons [-] and [+]
	btnMinusX, btnMinusY := ctrlX, ctrlY+20
	vector.DrawFilledRect(screen, float32(btnMinusX), float32(btnMinusY), 28, 24, eff.ButtonBg, false)
	vector.StrokeRect(screen, float32(btnMinusX), float32(btnMinusY), 28, 24, 1, eff.DialogBorder, false)
	font.DrawBold(screen, " - ", float64(btnMinusX+8), float64(btnMinusY+4), 14, eff.ButtonText)

	btnPlusX := ctrlX + 130
	vector.DrawFilledRect(screen, float32(btnPlusX), float32(btnMinusY), 28, 24, eff.ButtonBg, false)
	vector.StrokeRect(screen, float32(btnPlusX), float32(btnMinusY), 28, 24, 1, eff.DialogBorder, false)
	font.DrawBold(screen, " + ", float64(btnPlusX+8), float64(btnMinusY+4), 14, eff.ButtonText)

	// Progress bar between buttons
	barX := float32(btnMinusX + 36)
	barY := float32(btnMinusY + 4)
	barW := float32(86)
	barH := float32(16)
	vector.DrawFilledRect(screen, barX, barY, barW, barH, eff.ScreenBg, false)
	vector.StrokeRect(screen, barX, barY, barW, barH, 1, eff.StatusLabel, false)

	fillW := barW * ((dz - 0.05) / 0.65)
	if fillW < 2 {
		fillW = 2
	}
	vector.DrawFilledRect(screen, barX+1, barY+1, fillW-2, barH-2, eff.AccentColor, false)

	// Percentage text
	pctTxt := fmt.Sprintf("%d%%", int(dz*100+0.5))
	font.DrawBold(screen, pctTxt, float64(ctrlX+170), float64(btnMinusY+4), 12, eff.AccentColor)

	// Button Swap
	swapY := ctrlY + 60
	swapBtnW := float32(230)
	swapBg := eff.ButtonBg
	swapBorder := eff.DialogBorder
	chk := "[   ]"
	if u.ControllerConfig.SwapAB[p] {
		chk = "[ ✓ ]"
		swapBorder = eff.AccentColor
	}
	vector.DrawFilledRect(screen, float32(ctrlX), float32(swapY), swapBtnW, 26, swapBg, false)
	vector.StrokeRect(screen, float32(ctrlX), float32(swapY), swapBtnW, 26, 1, swapBorder, false)
	font.Draw(screen, fmt.Sprintf("%s %s", chk, i18n.T("ctrl_swap_ab")), float64(ctrlX+10), float64(swapY+6), 12, eff.ButtonText)

	// Mapping preview explanation
	mapDescA := "MSX Btn A: South (A) / West (X)"
	mapDescB := "MSX Btn B: East (B) / North (Y)"
	if u.ControllerConfig.SwapAB[p] {
		mapDescA = "MSX Btn A: East (B) / North (Y)"
		mapDescB = "MSX Btn B: South (A) / West (X)"
	}
	font.Draw(screen, mapDescA, float64(ctrlX), float64(swapY+36), 11, eff.StatusLabel)
	font.Draw(screen, mapDescB, float64(ctrlX), float64(swapY+54), 11, eff.StatusLabel)

	// Live Gamepad Button Activity Indicators
	liveY := swapY + 80
	font.DrawBold(screen, "Live Input:", float64(ctrlX), float64(liveY), 11, eff.DialogText)

	drawIndicator := func(label string, x, y int, active bool) {
		bg := eff.ScreenBg
		fg := eff.StatusLabel
		if active {
			bg = eff.AccentColor
			fg = white
		}
		vector.DrawFilledRect(screen, float32(x), float32(y), 24, 18, bg, false)
		vector.StrokeRect(screen, float32(x), float32(y), 24, 18, 1, eff.DialogBorder, false)
		font.DrawBold(screen, label, float64(x+5), float64(y+2), 10, fg)
	}

	btnAActive := false
	btnBActive := false
	dpadU := false
	dpadD := false
	dpadL := false
	dpadR := false
	if hasGP {
		dpadU = ebiten.IsStandardGamepadButtonPressed(activeGP, ebiten.StandardGamepadButtonLeftTop) || stickY < -float64(dz)
		dpadD = ebiten.IsStandardGamepadButtonPressed(activeGP, ebiten.StandardGamepadButtonLeftBottom) || stickY > float64(dz)
		dpadL = ebiten.IsStandardGamepadButtonPressed(activeGP, ebiten.StandardGamepadButtonLeftLeft) || stickX < -float64(dz)
		dpadR = ebiten.IsStandardGamepadButtonPressed(activeGP, ebiten.StandardGamepadButtonLeftRight) || stickX > float64(dz)

		rawA := ebiten.IsStandardGamepadButtonPressed(activeGP, ebiten.StandardGamepadButtonRightBottom) ||
			ebiten.IsStandardGamepadButtonPressed(activeGP, ebiten.StandardGamepadButtonRightLeft)
		rawB := ebiten.IsStandardGamepadButtonPressed(activeGP, ebiten.StandardGamepadButtonRightRight) ||
			ebiten.IsStandardGamepadButtonPressed(activeGP, ebiten.StandardGamepadButtonRightTop)

		if u.ControllerConfig.SwapAB[p] {
			btnAActive = rawB
			btnBActive = rawA
		} else {
			btnAActive = rawA
			btnBActive = rawB
		}
	}

	drawIndicator("U", ctrlX+75, liveY, dpadU)
	drawIndicator("D", ctrlX+105, liveY, dpadD)
	drawIndicator("L", ctrlX+135, liveY, dpadL)
	drawIndicator("R", ctrlX+165, liveY, dpadR)
	drawIndicator("A", ctrlX+205, liveY, btnAActive)
	drawIndicator("B", ctrlX+235, liveY, btnBActive)

	// Bottom Action Buttons: Defaults and Save & Close
	btmY := dlgY + dlgH - 38

	// Reset Defaults button
	defBtnW := float32(140)
	vector.DrawFilledRect(screen, float32(dlgX+16), float32(btmY), defBtnW, 26, eff.ButtonBg, false)
	vector.StrokeRect(screen, float32(dlgX+16), float32(btmY), defBtnW, 26, 1, eff.DialogBorder, false)
	font.Draw(screen, "Reset Defaults", float64(dlgX+32), float64(btmY+6), 12, eff.ButtonText)

	// Save & Close button
	saveBtnW := float32(150)
	saveBtnX := float32(dlgX + dlgW - 166)
	vector.DrawFilledRect(screen, saveBtnX, float32(btmY), saveBtnW, 26, eff.AccentColor, false)
	font.DrawBold(screen, i18n.T("btn_save_close"), float64(int(saveBtnX)+14), float64(btmY+6), 12, white)
}

// handleControllerClick processes mouse interactions within the controller modal dialog.
func (u *UI) handleControllerClick(x, y int) {
	winW, winH := u.currWinW, u.currWinH
	if winW <= 0 || winH <= 0 {
		winW, winH = 640, 480
	}
	dlgW, dlgH := 520, 360
	dlgX := (winW - dlgW) / 2
	dlgY := (winH - dlgH) / 2

	p := u.ControllerConfig.ActivePort

	// 1. Port Tabs
	tabY := dlgY + 44
	if y >= tabY && y <= tabY+24 {
		if x >= dlgX+16 && x <= dlgX+176 {
			u.ControllerConfig.ActivePort = 0
			return
		}
		if x >= dlgX+184 && x <= dlgX+344 {
			u.ControllerConfig.ActivePort = 1
			return
		}
	}

	// 2. Deadzone Adjustment [-] and [+]
	ctrlX := dlgX + 165
	ctrlY := dlgY + 98
	btnMinusY := ctrlY + 20
	if y >= btnMinusY && y <= btnMinusY+24 {
		// [-] Decrement deadzone by 0.05
		if x >= ctrlX && x <= ctrlX+28 {
			if u.ControllerConfig.Deadzone[p] > 0.051 {
				u.ControllerConfig.Deadzone[p] -= 0.05
			}
			return
		}
		// [+] Increment deadzone by 0.05
		btnPlusX := ctrlX + 130
		if x >= btnPlusX && x <= btnPlusX+28 {
			if u.ControllerConfig.Deadzone[p] < 0.699 {
				u.ControllerConfig.Deadzone[p] += 0.05
			}
			return
		}
	}

	// 3. Swap A/B button toggle
	swapY := ctrlY + 60
	if y >= swapY && y <= swapY+26 && x >= ctrlX && x <= ctrlX+230 {
		u.ControllerConfig.SwapAB[p] = !u.ControllerConfig.SwapAB[p]
		return
	}

	// 4. Bottom Action Buttons
	btmY := dlgY + dlgH - 38
	if y >= btmY && y <= btmY+26 {
		// Reset Defaults
		if x >= dlgX+16 && x <= dlgX+156 {
			u.ControllerConfig.Deadzone[p] = 0.35
			u.ControllerConfig.SwapAB[p] = false
			return
		}
		// Save & Close
		saveBtnX := dlgX + dlgW - 166
		if x >= saveBtnX && x <= saveBtnX+150 {
			if u.Machine != nil && u.Machine.DB != nil {
				u.ControllerConfig.Save(u.Machine.DB)
			}
			u.ShowControllerConfig = false
			return
		}
	}
}
