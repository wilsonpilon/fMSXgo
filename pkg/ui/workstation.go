package ui

import (
	"fmt"
	"image/color"
	"strings"

	"github.com/hajimehoshi/ebiten/v2"

	"fmsxgo/pkg/cpu/z80"
	"fmsxgo/pkg/ui/font"
	"fmsxgo/pkg/ui/theme"
)

// drawWorkstationModal renders the full-featured Hacker / Developer Workstation overlay.
func (u *UI) drawWorkstationModal(screen *ebiten.Image) {
	eff := theme.GetEffective()
	diagW := 620
	diagH := 440
	diagX := (screen.Bounds().Dx() - diagW) / 2
	diagY := (screen.Bounds().Dy() - diagH) / 2

	if diagX < 5 {
		diagX = 5
	}
	if diagY < 5 {
		diagY = 5
	}

	// 1. Dialog background
	op := &ebiten.DrawImageOptions{}
	op.GeoM.Translate(float64(diagX), float64(diagY))
	screen.DrawImage(u.workstationDlgBg, op)

	// 2. Title & Status Header
	font.DrawBold(screen, "=== HACKER / DEVELOPER WORKSTATION ===", float64(diagX+20), float64(diagY+14), 14, eff.DialogHeader)

	statusStr := "RUNNING"
	statusCol := color.RGBA{R: 50, G: 200, B: 50, A: 255}
	if u.EmulationPaused {
		statusStr = "PAUSED (F5)"
		statusCol = color.RGBA{R: 255, G: 180, B: 50, A: 255}
	}
	font.DrawBold(screen, fmt.Sprintf("[%s]", statusStr), float64(diagX+diagW-130), float64(diagY+14), 12, statusCol)

	// 3. Tab Bar
	tabNames := []string{
		"1: Disasm & Regs",
		"2: Memory & Slots",
		"3: VRAM & Tiles",
		"4: Trace Buffer",
		"5: Hex Editor",
	}

	tabStartX := diagX + 20
	tabY := diagY + 40
	for i, name := range tabNames {
		tx := tabStartX + (i * 118)
		tCol := eff.DialogText
		if i == u.HackerTab {
			tCol = eff.AccentColor
			font.DrawBold(screen, "["+name+"]", float64(tx), float64(tabY), 11, tCol)
		} else {
			font.Draw(screen, " "+name+" ", float64(tx), float64(tabY), 11, tCol)
		}
	}

	// Separator line below tabs
	font.Draw(screen, "--------------------------------------------------------------------------------",
		float64(diagX+15), float64(tabY+18), 11, eff.StatusLabel)

	// 4. Tab Body Content
	contentY := tabY + 28
	contentH := diagH - 95

	switch u.HackerTab {
	case 0:
		u.drawWorkstationDisasm(screen, diagX+20, contentY, diagW-40, contentH)
	case 1:
		u.drawWorkstationSlots(screen, diagX+20, contentY, diagW-40, contentH)
	case 2:
		u.drawWorkstationVRAM(screen, diagX+20, contentY, diagW-40, contentH)
	case 3:
		u.drawWorkstationTrace(screen, diagX+20, contentY, diagW-40, contentH)
	case 4:
		u.drawWorkstationHex(screen, diagX+20, contentY, diagW-40, contentH)
	}

	// 5. Footer Shortcuts
	footerY := diagY + diagH - 20
	footer := "[F10: Step]  [F5: Run/Pause]  [1..5: Switch Tab]  [Esc/F9: Close Workstation]"
	font.DrawCode(screen, footer, float64(diagX+20), float64(footerY), 11, eff.AccentColor)
}

// drawWorkstationDisasm renders disassembly around PC, registers, and stack.
func (u *UI) drawWorkstationDisasm(screen *ebiten.Image, x, y, w, h int) {
	eff := theme.GetEffective()
	if u.Machine == nil || u.Machine.CPU == nil {
		return
	}
	cpu := u.Machine.CPU

	// Left column: Disassembly (340px)
	font.DrawBold(screen, "DISASSEMBLY", float64(x), float64(y), 12, eff.AccentColor)

	dasmAddr := cpu.PC
	for i := 0; i < 11; i++ {
		dis, size := z80.Disassemble(u.Machine.Bus, dasmAddr)
		var byteStrs []string
		for b := uint16(0); b < uint16(size); b++ {
			byteStrs = append(byteStrs, fmt.Sprintf("%02X", u.Machine.Bus.Read(dasmAddr+b)))
		}
		byteDump := fmt.Sprintf("%-8s", strings.Join(byteStrs, " "))

		prefix := "  "
		lineCol := eff.DialogText
		if dasmAddr == cpu.PC {
			prefix = "=>"
			lineCol = eff.AccentColor
		}

		annot := ""
		if u.Machine.Symbols != nil {
			annot = u.Machine.Symbols.FormatAnnotation(dasmAddr)
		}

		rowText := fmt.Sprintf("%s %04X: %s %-16s%s", prefix, dasmAddr, byteDump, dis, annot)
		font.DrawCode(screen, rowText, float64(x), float64(y+22+(i*22)), 11, lineCol)
		dasmAddr += uint16(size)
	}

	// Right column: CPU Registers & Stack (x + 360)
	rx := x + 360
	font.DrawBold(screen, "REGISTERS & CPU", float64(rx), float64(y), 12, eff.AccentColor)

	font.DrawCode(screen, fmt.Sprintf("AF: %04Xh  (A=%02X F=%02X)", cpu.AF(), cpu.A, cpu.F), float64(rx), float64(y+22), 11, eff.DialogText)
	font.DrawCode(screen, fmt.Sprintf("BC: %04Xh  (B=%02X C=%02X)", cpu.BC(), cpu.B, cpu.C), float64(rx), float64(y+42), 11, eff.DialogText)
	font.DrawCode(screen, fmt.Sprintf("DE: %04Xh  (D=%02X E=%02X)", cpu.DE(), cpu.D, cpu.E), float64(rx), float64(y+62), 11, eff.DialogText)
	font.DrawCode(screen, fmt.Sprintf("HL: %04Xh  (H=%02X L=%02X)", cpu.HL(), cpu.H, cpu.L), float64(rx), float64(y+82), 11, eff.DialogText)
	font.DrawCode(screen, fmt.Sprintf("IX: %04Xh   IY: %04Xh", cpu.IX, cpu.IY), float64(rx), float64(y+104), 11, eff.DialogText)
	font.DrawCode(screen, fmt.Sprintf("SP: %04Xh   PC: %04Xh", cpu.SP, cpu.PC), float64(rx), float64(y+124), 11, eff.DialogText)

	// Flags
	f := cpu.F
	flags := fmt.Sprintf("[%c%c%c%c%c%c%c%c]",
		flagChar(f, z80.FlagS, 'S'),
		flagChar(f, z80.FlagZ, 'Z'),
		flagChar(f, z80.Flag5, '5'),
		flagChar(f, z80.FlagH, 'H'),
		flagChar(f, z80.Flag3, '3'),
		flagChar(f, z80.FlagV, 'P'),
		flagChar(f, z80.FlagN, 'N'),
		flagChar(f, z80.FlagC, 'C'))
	font.DrawCode(screen, fmt.Sprintf("Flags: %s", flags), float64(rx), float64(y+146), 11, eff.AccentColor)
	font.DrawCode(screen, fmt.Sprintf("IM: %d   IFF1: %t  IFF2: %t", cpu.IM, cpu.IFF1, cpu.IFF2), float64(rx), float64(y+166), 11, eff.DialogText)
	font.DrawCode(screen, fmt.Sprintf("Cycles: %d", cpu.Cycles), float64(rx), float64(y+186), 11, eff.StatusLabel)

	// Stack View
	font.DrawBold(screen, "STACK PREVIEW (SP)", float64(rx), float64(y+214), 12, eff.AccentColor)
	for s := 0; s < 4; s++ {
		spAddr := cpu.SP + uint16(s*2)
		low := uint16(u.Machine.Bus.Read(spAddr))
		high := uint16(u.Machine.Bus.Read(spAddr + 1))
		word := (high << 8) | low
		font.DrawCode(screen, fmt.Sprintf("SP+%02X [%04Xh]: %04Xh", s*2, spAddr, word), float64(rx), float64(y+234+(s*18)), 11, eff.DialogText)
	}
}

// drawWorkstationSlots renders the 64KB memory map, primary/secondary slots, and RAM mapper.
func (u *UI) drawWorkstationSlots(screen *ebiten.Image, x, y, w, h int) {
	eff := theme.GetEffective()
	if u.Machine == nil || u.Machine.Slots == nil {
		return
	}
	slots := u.Machine.Slots
	mapper := u.Machine.Mapper

	font.DrawBold(screen, "MSX 64KB MEMORY MAP & SLOT ALLOCATION", float64(x), float64(y), 12, eff.AccentColor)

	pages := []struct {
		Name  string
		Range string
		Page  int
		Desc  string
	}{
		{"Page 0", "0000h..3FFFh (16KB)", 0, "BIOS / SubROM"},
		{"Page 1", "4000h..7FFFh (16KB)", 1, "BASIC / Cartridge A / DiskROM"},
		{"Page 2", "8000h..BFFFh (16KB)", 2, "RAM Mapper / Cartridge B"},
		{"Page 3", "C000h..FFFFh (16KB)", 3, "RAM Mapper System Workarea"},
	}

	for i, p := range pages {
		py := y + 26 + (i * 44)
		psl := slots.CurPSL[p.Page]
		ssl := slots.CurSSL[p.Page]

		slotStr := fmt.Sprintf("Slot %d", psl)
		if slots.IsSubslot[psl] {
			slotStr = fmt.Sprintf("Slot %d-%d", psl, ssl)
		}

		allocDesc := p.Desc
		if p.Page == 0 && psl == 0 {
			allocDesc = "MSX Main BIOS (16KB ROM)"
		} else if p.Page == 1 && psl == 0 {
			allocDesc = "MSX Basic Interpreter (16KB ROM)"
		} else if (p.Page == 2 || p.Page == 3) && psl == 3 && mapper != nil {
			allocDesc = fmt.Sprintf("RAM Mapper Bank #%d (Segment %d)", mapper.Regs[p.Page]&mapper.Mask, p.Page)
		}

		font.DrawBold(screen, fmt.Sprintf("%-7s %s", p.Name, p.Range), float64(x), float64(py), 11, eff.AccentColor)
		font.DrawCode(screen, fmt.Sprintf("  Mapped to: %-12s | %s", slotStr, allocDesc), float64(x), float64(py+18), 11, eff.DialogText)
	}

	// RAM Mapper Summary
	my := y + 210
	font.DrawBold(screen, "HARDWARE REGISTERS & MAPPER ARCHITECTURE", float64(x), float64(my), 12, eff.AccentColor)
	font.DrawCode(screen, fmt.Sprintf("Primary Slot Reg (Port A8h): %02Xh   | Secondary Slot Reg (FFFFh): %02Xh",
		slots.PSLReg, slots.GetSSL()), float64(x), float64(my+22), 11, eff.DialogText)

	if mapper != nil {
		font.DrawCode(screen, fmt.Sprintf("RAM Mapper: %d KB (%d pages x 16KB) | Mask: %02Xh",
			mapper.Pages*16, mapper.Pages, mapper.Mask), float64(x), float64(my+44), 11, eff.DialogText)
		font.DrawCode(screen, fmt.Sprintf("Port FCh (P0): Bank %-2d  | Port FDh (P1): Bank %-2d",
			mapper.Regs[0]&mapper.Mask, mapper.Regs[1]&mapper.Mask), float64(x), float64(my+64), 11, eff.DialogText)
		font.DrawCode(screen, fmt.Sprintf("Port FEh (P2): Bank %-2d  | Port FFh (P3): Bank %-2d",
			mapper.Regs[2]&mapper.Mask, mapper.Regs[3]&mapper.Mask), float64(x), float64(my+84), 11, eff.DialogText)
	}
}

// drawWorkstationVRAM renders VDP table pointers and live 128-tile pattern grid preview.
func (u *UI) drawWorkstationVRAM(screen *ebiten.Image, x, y, w, h int) {
	eff := theme.GetEffective()
	if u.Machine == nil || u.Machine.VDP == nil {
		return
	}
	v := u.Machine.VDP

	font.DrawBold(screen, "VDP VIDEO PROCESSOR & PATTERN GENERATOR VIEWER", float64(x), float64(y), 12, eff.AccentColor)

	// Left: Table Pointers & Status
	font.DrawCode(screen, fmt.Sprintf("Mode: SCREEN %d  | Scanline: %d/%d  | VRAM Addr: %04Xh",
		v.ScrMode, v.ScanLine, v.TotalLines, v.VAddr), float64(x), float64(y+22), 11, eff.DialogText)
	font.DrawCode(screen, fmt.Sprintf("ChrTab: %05Xh (Msk %04Xh) | ChrGen: %05Xh",
		v.ChrTab, v.ChrTabM, v.ChrGen), float64(x), float64(y+42), 11, eff.DialogText)
	font.DrawCode(screen, fmt.Sprintf("ColTab: %05Xh (Msk %04Xh) | SprTab: %05Xh | SprGen: %05Xh",
		v.ColTab, v.ColTabM, v.SprTab, v.SprGen), float64(x), float64(y+62), 11, eff.DialogText)

	// Render 128 Character Tiles (16 cols x 8 rows) from VRAM ChrGen
	font.DrawBold(screen, "VRAM PATTERN TABLE (128 Tiles x 8x8)", float64(x), float64(y+92), 11, eff.AccentColor)

	tileGridW := 128
	tileGridH := 64
	tilePixels := make([]byte, tileGridW*tileGridH*4)
	chrGen := v.ChrGen
	vramLen := len(v.VRAM)

	if vramLen > 0 {
		for tile := 0; tile < 128; tile++ {
			tileX := (tile % 16) * 8
			tileY := (tile / 16) * 8
			for row := 0; row < 8; row++ {
				b := v.VRAM[(chrGen+tile*8+row)%vramLen]
				for col := 0; col < 8; col++ {
					px := tileX + col
					py := tileY + row
					idx := (py*tileGridW + px) * 4
					if (b & (0x80 >> col)) != 0 {
						tilePixels[idx] = 255
						tilePixels[idx+1] = 255
						tilePixels[idx+2] = 255
						tilePixels[idx+3] = 255
					} else {
						tilePixels[idx] = 25
						tilePixels[idx+1] = 30
						tilePixels[idx+2] = 45
						tilePixels[idx+3] = 255
					}
				}
			}
		}

		tileImg := ebiten.NewImage(tileGridW, tileGridH)
		tileImg.WritePixels(tilePixels)

		top := &ebiten.DrawImageOptions{}
		top.GeoM.Scale(2.0, 2.0)
		top.GeoM.Translate(float64(x), float64(y+112))
		screen.DrawImage(tileImg, top)
	}

	// Right: Sprite attributes preview (Sprites 0..5)
	sx := x + 280
	font.DrawBold(screen, "ACTIVE SPRITE ATTRIBUTES", float64(sx), float64(y+92), 11, eff.AccentColor)
	sprTab := v.SprTab
	for s := 0; s < 6; s++ {
		offset := (sprTab + s*4) % vramLen
		sy := v.VRAM[offset]
		sxVal := v.VRAM[(offset+1)%vramLen]
		pat := v.VRAM[(offset+2)%vramLen]
		col := v.VRAM[(offset+3)%vramLen] & 0x0F
		font.DrawCode(screen, fmt.Sprintf("Spr#%d: Y=%-3d X=%-3d Pat=%02Xh Col=%d",
			s, sy, sxVal, pat, col), float64(sx), float64(y+115+(s*20)), 11, eff.DialogText)
	}
}

// drawWorkstationTrace renders the last executed instructions from the execution history ring.
func (u *UI) drawWorkstationTrace(screen *ebiten.Image, x, y, w, h int) {
	eff := theme.GetEffective()
	if u.Machine == nil || u.Machine.CPU == nil {
		return
	}
	cpu := u.Machine.CPU

	font.DrawBold(screen, fmt.Sprintf("CIRCULAR EXECUTION TRACE (Buffer Capacity: 10,000 steps | In Buffer: %d)",
		cpu.HistoryCount), float64(x), float64(y), 12, eff.AccentColor)

	header := fmt.Sprintf("  %-3s %-6s %-16s %-8s %-6s %-6s %-6s %-6s %s",
		"#", "PC", "INSTRUCTION", "SYMBOL", "AF", "BC", "DE", "HL", "SP")
	font.DrawCode(screen, header, float64(x), float64(y+24), 11, eff.AccentColor)

	history := cpu.GetHistory(12)
	if len(history) == 0 {
		font.Draw(screen, "Execution trace buffer is empty. Advance execution to populate.", float64(x), float64(y+60), 12, eff.StatusLabel)
		return
	}

	for i, entry := range history {
		dasm, _ := entry.Disassemble()
		annot := ""
		if u.Machine.Symbols != nil {
			annot = u.Machine.Symbols.FormatAnnotation(entry.PC)
		}
		if len(annot) > 8 {
			annot = annot[:8]
		}

		row := fmt.Sprintf("[%2d] %04X: %-16s %-8s %04X   %04X   %04X   %04X   %04X",
			i+1, entry.PC, dasm, annot, entry.AF, entry.BC, entry.DE, entry.HL, entry.SP)
		font.DrawCode(screen, row, float64(x), float64(y+46+(i*22)), 11, eff.DialogText)
	}

	font.Draw(screen, "Tip: Press 'C' to clear execution trace buffer.", float64(x), float64(y+h-15), 11, eff.StatusLabel)
}

// drawWorkstationHex renders the interactive hex and ASCII memory / VRAM inspector.
func (u *UI) drawWorkstationHex(screen *ebiten.Image, x, y, w, h int) {
	eff := theme.GetEffective()
	if u.Machine == nil {
		return
	}

	memType := "CPU 64KB MEMORY"
	if u.WorkstationHexVRAM {
		memType = "128KB VRAM"
	}

	font.DrawBold(screen, fmt.Sprintf("LIVE MEMORY INSPECTOR: %s (Address: %04Xh)",
		memType, u.WorkstationHexAddr), float64(x), float64(y), 12, eff.AccentColor)

	header := fmt.Sprintf("ADDR    00 01 02 03 04 05 06 07  08 09 0A 0B 0C 0D 0E 0F   ASCII")
	font.DrawCode(screen, header, float64(x), float64(y+24), 11, eff.AccentColor)

	addr := u.WorkstationHexAddr
	vramLen := len(u.Machine.VDP.VRAM)

	for row := 0; row < 10; row++ {
		rowAddr := addr + uint16(row*16)
		var hexParts []string
		var asciiParts []byte

		for col := 0; col < 16; col++ {
			var b byte
			if u.WorkstationHexVRAM && vramLen > 0 {
				b = u.Machine.VDP.VRAM[(uint32(rowAddr)+uint32(col))%uint32(vramLen)]
			} else {
				b = u.Machine.Bus.Read(rowAddr + uint16(col))
			}

			hexParts = append(hexParts, fmt.Sprintf("%02X", b))
			if b >= 0x20 && b <= 0x7E {
				asciiParts = append(asciiParts, b)
			} else {
				asciiParts = append(asciiParts, '.')
			}
		}

		firstHalf := strings.Join(hexParts[:8], " ")
		secondHalf := strings.Join(hexParts[8:], " ")
		rowText := fmt.Sprintf("%04X:   %s  %s   |%s|", rowAddr, firstHalf, secondHalf, string(asciiParts))
		font.DrawCode(screen, rowText, float64(x), float64(y+48+(row*22)), 11, eff.DialogText)
	}

	hint := "[Up/Down]: Scroll +/- 16 B   [PgUp/PgDn]: Scroll +/- 128 B   [V]: Toggle RAM/VRAM"
	font.Draw(screen, hint, float64(x), float64(y+h-15), 11, eff.StatusLabel)
}

// handleWorkstationClick processes clicks within the workstation modal.
func (u *UI) handleWorkstationClick(x, y int) {
	diagW := 620
	diagH := 440
	diagX := (u.currWinW - diagW) / 2
	diagY := (u.currWinH - diagH) / 2

	// Click on Tabs row
	tabY := diagY + 40
	if y >= tabY && y <= tabY+25 {
		tabStartX := diagX + 20
		for i := 0; i < 5; i++ {
			tx := tabStartX + (i * 118)
			if x >= tx && x <= tx+110 {
				u.HackerTab = i
				return
			}
		}
	}

	// Click outside dialog closes it
	if x < diagX || x > diagX+diagW || y < diagY || y > diagY+diagH {
		u.ShowHackerWorkstation = false
	}
}

func flagChar(f uint8, mask uint8, char byte) byte {
	if (f & mask) != 0 {
		return char
	}
	return '-'
}
