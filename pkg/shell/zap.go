package shell

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"fmsxgo/pkg/cpu/z80"
	"fmsxgo/pkg/msx"
	"golang.org/x/term"
)

// cmdZAP implements the classic MSX disk sector editor:
// ZAP <setor>[[,<deslocamento>[,<bytes>]] or ZAP<setor>,<desloc>,<bytes>
//
// Edits disk sectors directly in host memory.
// - All numeric arguments are hexadecimal by default (use 'd' prefix for decimal, e.g. d10, d256).
// - Sector bounds and disk geometries are automatically detected (180KB, 360KB, 720KB, 640KB, 5 1/4", 3 1/2", SS/DS, SD/DD).
// - Maximum bytes per sector is fdd.SecSize (typically 512 bytes). Default is 512 bytes.
// - Supports displacement (Caesar offset) just like DM.
// - In interactive mode, allows navigating with arrow keys, editing raw hex,
//   jumping between sectors with PgUp/PgDn/TAB, and exiting with ESC.
func (sh *Shell) cmdZAP(args []string) {
	drive := sh.LastDiskDrive
	if drive < 0 || drive >= 2 {
		drive = 0
	}

	if !sh.Machine.DiskPresent(drive) {
		// If Drive 0 is empty, check if Drive 1 is loaded
		if sh.Machine.DiskPresent(1) {
			drive = 1
			sh.LastDiskDrive = 1
		} else {
			fmt.Fprintln(sh.Out, "Error: No disk loaded in memory. Use 'loaddsk' to mount a disk image first.")
			return
		}
	}

	fdd := sh.Machine.FDD[drive]
	sector := int(sh.LastSector)
	if sector >= fdd.Sectors {
		sector = 0
	}
	desloc := 0
	totalBytes := fdd.SecSize
	if totalBytes <= 0 {
		totalBytes = 512
	}

	raw := strings.TrimSpace(strings.Join(args, " "))
	if raw != "" {
		var parts []string
		if strings.Contains(raw, ",") {
			rawParts := strings.Split(raw, ",")
			for _, p := range rawParts {
				parts = append(parts, strings.TrimSpace(p))
			}
		} else {
			parts = strings.Fields(raw)
		}

		if len(parts) >= 1 && parts[0] != "" {
			v, err := z80.ParseNumber(parts[0])
			if err != nil {
				fmt.Fprintf(sh.Out, "Invalid sector number: %s\n", parts[0])
				return
			}
			sector = int(v)
		}

		if len(parts) == 2 && parts[1] != "" {
			// If 2 parameters provided (e.g. ZAP 0, 100 or ZAP 0, d256):
			// check if parts[1] is a byte count (>= 128 and multiple of 128)
			isByteCount := false
			if v, err := z80.ParseNumber(parts[1]); err == nil {
				if v >= 128 && v%128 == 0 {
					isByteCount = true
				}
			}

			if isByteCount {
				tb, err := parseZAPBytes(parts[1], fdd.SecSize)
				if err != nil {
					fmt.Fprintf(sh.Out, "Invalid byte count: %s\n", parts[1])
					return
				}
				totalBytes = tb
			} else {
				d, err := parseDMDesloc(parts[1])
				if err != nil {
					fmt.Fprintf(sh.Out, "Invalid displacement: %s\n", parts[1])
					return
				}
				desloc = d
			}
		} else {
			if len(parts) >= 2 && parts[1] != "" {
				d, err := parseDMDesloc(parts[1])
				if err != nil {
					fmt.Fprintf(sh.Out, "Invalid displacement: %s\n", parts[1])
					return
				}
				desloc = d
			}

			if len(parts) >= 3 && parts[2] != "" {
				tb, err := parseZAPBytes(parts[2], fdd.SecSize)
				if err != nil {
					fmt.Fprintf(sh.Out, "Invalid byte count: %s\n", parts[2])
					return
				}
				totalBytes = tb
			}
		}
	}

	// Validate sector bounds against loaded disk geometry
	if sector < 0 || sector >= fdd.Sectors {
		fmt.Fprintf(sh.Out, "Error: Invalid sector %d (0x%X). Valid range is 0..%d (0000h..%04Xh) for %s\n",
			sector, sector, fdd.Sectors-1, fdd.Sectors-1, fdd.DiskType)
		return
	}

	if totalBytes <= 0 || totalBytes > fdd.SecSize {
		totalBytes = fdd.SecSize
	}

	sh.LastSector = sector

	file, ok := sh.In.(*os.File)
	isTerminal := ok && term.IsTerminal(int(file.Fd()))

	if !isTerminal {
		// Non-interactive / batch / pipe / test mode
		fmt.Fprint(sh.Out, formatZAPView(sh, fdd, sector, 0, totalBytes, desloc, -1, "", false))
		return
	}

	// Interactive terminal mode
	oldState, err := term.MakeRaw(int(file.Fd()))
	if err != nil {
		fmt.Fprint(sh.Out, formatZAPView(sh, fdd, sector, 0, totalBytes, desloc, -1, "", false))
		return
	}
	defer func() {
		_ = term.Restore(int(file.Fd()), oldState)
		fmt.Fprint(sh.Out, "\033[?25h\n") // Restore cursor and newline
	}()

	fmt.Fprint(sh.Out, "\033[?25l") // Hide cursor

	offsetInSector := 0
	cursorPos := 0
	inputNibble := ""

	redraw := func() {
		fmt.Fprint(sh.Out, "\033[H\033[2J"+formatZAPView(sh, fdd, sector, offsetInSector, totalBytes, desloc, cursorPos, inputNibble, true))
	}

	redraw()

	buf := make([]byte, 16)
	for {
		n, err := file.Read(buf)
		if err != nil || n == 0 {
			break
		}

		if handleZAPKey(sh, fdd, buf, n, &sector, &offsetInSector, totalBytes, &cursorPos, &inputNibble, desloc) {
			break
		}
		redraw()
	}

	sh.LastSector = sector
}

func parseZAPBytes(s string, maxSecSize int) (int, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return maxSecSize, nil
	}

	rawVal, err := z80.ParseNumber(s)
	if err != nil {
		return maxSecSize, err
	}

	b := int(rawVal)
	// Round to nearest multiple of 128
	n := (b + 64) / 128
	if n < 1 {
		n = 1
	}
	res := n * 128
	if res > maxSecSize {
		res = maxSecSize
	}
	return res, nil
}

// formatZAPView formats the disk sector view with displacement, CHS geometry, and ASCII translation.
func formatZAPView(sh *Shell, fdd *msx.FloppyDrive, sector int, offsetInSector int, totalBytes int, desloc int, cursorPos int, inputNibble string, useAnsi bool) string {
	var sb strings.Builder

	secPerTrack := fdd.SecPerTrack
	if secPerTrack <= 0 {
		secPerTrack = 9
	}
	sides := fdd.Sides
	if sides <= 0 {
		sides = 2
	}
	secPerCylinder := secPerTrack * sides

	track := sector / secPerCylinder
	rem := sector % secPerCylinder
	side := rem / secPerTrack
	secOnTrack := (rem % secPerTrack) + 1

	curOffset := offsetInSector
	if cursorPos >= 0 {
		curOffset = offsetInSector + cursorPos
	}

	driveLetter := 'A' + fdd.ID
	fileName := filepath.Base(fdd.Path)
	if fileName == "" || fileName == "." {
		fileName = "Virtual Floppy"
	}

	sb.WriteString("=== MSX Disk Sector Editor (ZAP) ===\n")
	sb.WriteString(fmt.Sprintf("Drive %c: [%s] | %s\n", driveLetter, fileName, fdd.DiskType))
	sb.WriteString(fmt.Sprintf("Sector: %04Xh / %d (Track: %d, Side: %d, Sec: %d) | Total: %d sectors\n",
		sector, sector, track, side, secOnTrack, fdd.Sectors))
	sb.WriteString(fmt.Sprintf("Bytes: %d (%02Xh) | Displacement: %+d | Offset in Sector: %04Xh\n",
		totalBytes, totalBytes, desloc, curOffset))
	sb.WriteString("[Arrows]: Navigate  [PgUp/PgDn]: ±Sector  [TAB]: Next Sector  [0-9, A-F]: Edit  [ESC]: Exit\n")
	sb.WriteString("-----------------------------------------------------------------\n")

	secBase := sector * fdd.SecSize
	numRows := totalBytes / 16
	if numRows < 1 {
		numRows = 1
	}

	for row := 0; row < numRows; row++ {
		rowOffset := offsetInSector + row*16
		sb.WriteString(fmt.Sprintf("%04X:  ", rowOffset))

		var hexStrs []string
		for col := 0; col < 16; col++ {
			idx := row*16 + col
			byteOffset := secBase + rowOffset + col

			var rawByte byte
			if byteOffset < len(fdd.Data) {
				rawByte = fdd.Data[byteOffset]
			}
			dispByte := byte(int(rawByte) + desloc)

			var bStr string
			if idx == cursorPos && inputNibble != "" {
				if len(inputNibble) == 1 {
					bStr = inputNibble + "_"
				} else {
					bStr = inputNibble
				}
			} else {
				bStr = fmt.Sprintf("%02X", dispByte)
			}

			if idx == cursorPos && useAnsi {
				bStr = "\033[7m" + bStr + "\033[0m"
			}
			hexStrs = append(hexStrs, bStr)
			if col == 7 {
				hexStrs = append(hexStrs, "") // Middle separator space
			}
		}
		sb.WriteString(strings.Join(hexStrs, " "))
		sb.WriteString("  |")

		for col := 0; col < 16; col++ {
			idx := row*16 + col
			byteOffset := secBase + rowOffset + col

			var rawByte byte
			if byteOffset < len(fdd.Data) {
				rawByte = fdd.Data[byteOffset]
			}
			dispByte := byte(int(rawByte) + desloc)

			ch := '.'
			if dispByte >= 32 && dispByte <= 126 {
				ch = rune(dispByte)
			}

			if idx == cursorPos && useAnsi {
				sb.WriteString("\033[7m")
				sb.WriteRune(ch)
				sb.WriteString("\033[0m")
			} else {
				sb.WriteRune(ch)
			}
		}
		sb.WriteString("|\n")
	}

	return sb.String()
}

// handleZAPKey processes user keyboard input in the interactive ZAP editor.
// Returns true when ESC is pressed to exit.
func handleZAPKey(sh *Shell, fdd *msx.FloppyDrive, buf []byte, n int, sector *int, offsetInSector *int, totalBytes int, cursorPos *int, inputNibble *string, desloc int) bool {
	if n == 0 {
		return false
	}
	key := buf[0]

	bottomRowStart := totalBytes - 16
	lastByteIndex := totalBytes - 1

	// ESC key -> Exit editing
	if key == 0x1B {
		if n == 1 {
			return true
		}
		// Escape sequences (Arrows, PgUp/PgDn, Home, End)
		if n >= 3 && (buf[1] == '[' || buf[1] == 'O') {
			switch buf[2] {
			case 'A': // Up
				if *cursorPos >= 16 {
					*cursorPos -= 16
				} else {
					// Move to previous sector if at top of current sector
					if *sector > 0 {
						*sector--
						*cursorPos = bottomRowStart
					}
				}
				*inputNibble = ""

			case 'B': // Down
				if *cursorPos < bottomRowStart {
					*cursorPos += 16
				} else {
					// Move to next sector if at bottom of current sector
					if *sector < fdd.Sectors-1 {
						*sector++
						*cursorPos = *cursorPos % 16
					}
				}
				*inputNibble = ""

			case 'C': // Right
				if *cursorPos < lastByteIndex {
					*cursorPos++
				} else {
					if *sector < fdd.Sectors-1 {
						*sector++
						*cursorPos = 0
					}
				}
				*inputNibble = ""

			case 'D': // Left
				if *cursorPos > 0 {
					*cursorPos--
				} else {
					if *sector > 0 {
						*sector--
						*cursorPos = lastByteIndex
					}
				}
				*inputNibble = ""

			case '5', 'V', 'Z': // Page Up -> Previous Sector
				if *sector > 0 {
					*sector--
				}
				*inputNibble = ""

			case '6', 'U': // Page Down -> Next Sector
				if *sector < fdd.Sectors-1 {
					*sector++
				}
				*inputNibble = ""
			}
		}
		return false
	}

	// TAB key -> Next Sector (cycling back to 0 at end)
	if key == 0x09 {
		if *sector < fdd.Sectors-1 {
			*sector++
		} else {
			*sector = 0
		}
		*inputNibble = ""
		return false
	}

	// ENTER key -> Confirm byte edit
	if key == '\r' || key == '\n' {
		if *inputNibble != "" {
			newDispVal, err := strconv.ParseUint(*inputNibble, 16, 8)
			if err == nil {
				newRawVal := byte(int(newDispVal) - desloc)
				dataIdx := (*sector)*fdd.SecSize + *offsetInSector + *cursorPos
				if dataIdx < len(fdd.Data) {
					fdd.Data[dataIdx] = newRawVal
					fdd.Modified = true
				}
				if *cursorPos < lastByteIndex {
					*cursorPos++
				} else if *sector < fdd.Sectors-1 {
					*sector++
					*cursorPos = 0
				}
			}
			*inputNibble = ""
		}
		return false
	}

	// Backspace / Delete
	if key == 0x08 || key == 0x7F {
		if *inputNibble != "" {
			*inputNibble = ""
		} else {
			if *cursorPos > 0 {
				*cursorPos--
			} else if *sector > 0 {
				*sector--
				*cursorPos = lastByteIndex
			}
		}
		return false
	}

	// Hex digits: 0-9, a-f, A-F
	if (key >= '0' && key <= '9') || (key >= 'a' && key <= 'f') || (key >= 'A' && key <= 'F') {
		ch := strings.ToUpper(string(key))
		if len(*inputNibble) == 0 {
			*inputNibble = ch
		} else if len(*inputNibble) == 1 {
			*inputNibble += ch
			newDispVal, err := strconv.ParseUint(*inputNibble, 16, 8)
			if err == nil {
				newRawVal := byte(int(newDispVal) - desloc)
				dataIdx := (*sector)*fdd.SecSize + *offsetInSector + *cursorPos
				if dataIdx < len(fdd.Data) {
					fdd.Data[dataIdx] = newRawVal
					fdd.Modified = true
				}
				if *cursorPos < lastByteIndex {
					*cursorPos++
				} else if *sector < fdd.Sectors-1 {
					*sector++
					*cursorPos = 0
				}
			}
			*inputNibble = ""
		}
		return false
	}

	return false
}
