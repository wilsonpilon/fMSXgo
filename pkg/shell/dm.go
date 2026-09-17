package shell

import (
	"fmt"
	"os"
	"strconv"
	"strings"

	"fmsxgo/pkg/cpu/z80"
	"golang.org/x/term"
)

// cmdDM implements the classic MegaAssembler DM command:
// DM <addr>[[,<desloc>],<bytes>]] or DM<addr>,<desloc>,<bytes>
//
// Displays memory in hex + ASCII with an optional displacement offset and byte count.
// Bytes are rounded to the nearest multiple of 128 (e.g. 128, 256, 512, 768, 1024...).
// Displays all requested bytes simultaneously on the screen (e.g. 128 = 8 rows, 256 = 16 rows, 512 = 32 rows).
// In interactive terminal mode, allows navigating with arrow keys (scrolling line by line),
// paging with PgUp/PgDn/TAB (by totalBytes), entering numbers, confirming with ENTER, and exiting with ESC.
func (sh *Shell) cmdDM(args []string) {
	addr := sh.LastDump
	desloc := 0
	totalBytes := 128

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
				fmt.Fprintf(sh.Out, "Invalid address: %s\n", parts[0])
				return
			}
			addr = uint16(v)
		}

		if len(parts) == 2 && parts[1] != "" {
			// If 2 parameters are provided (e.g. DM C000, 100 or DM C000 100 or DM C000, d256):
			// check if parts[1] is a byte count (>= 128 and multiple of 128)
			isByteCount := false
			if v, err := z80.ParseNumber(parts[1]); err == nil {
				if v >= 128 && v%128 == 0 {
					isByteCount = true
				}
			}

			if isByteCount {
				tb, err := parseDMBytes(parts[1])
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
				tb, err := parseDMBytes(parts[2])
				if err != nil {
					fmt.Fprintf(sh.Out, "Invalid byte count: %s\n", parts[2])
					return
				}
				totalBytes = tb
			}
		}
	}

	baseAddr := addr & 0xFFF0
	maxBaseAddr := uint16(0)
	if totalBytes < 65536 {
		maxBaseAddr = uint16(65536 - totalBytes)
	}
	if baseAddr > maxBaseAddr {
		baseAddr = maxBaseAddr
	}
	sh.LastDump = baseAddr + uint16(totalBytes)

	file, ok := sh.In.(*os.File)
	isTerminal := ok && term.IsTerminal(int(file.Fd()))

	if !isTerminal {
		// Non-interactive / batch / pipe / unit-test mode -> dumps all totalBytes
		fmt.Fprint(sh.Out, formatDMView(sh, baseAddr, totalBytes, desloc, -1, "", false))
		return
	}

	// Interactive terminal mode with arrow navigation, hex editing, ENTER, and ESC
	oldState, err := term.MakeRaw(int(file.Fd()))
	if err != nil {
		fmt.Fprint(sh.Out, formatDMView(sh, baseAddr, totalBytes, desloc, -1, "", false))
		return
	}
	defer func() {
		_ = term.Restore(int(file.Fd()), oldState)
		fmt.Fprint(sh.Out, "\033[?25h\n") // Restore cursor visibility and newline
	}()

	fmt.Fprint(sh.Out, "\033[?25l") // Hide terminal cursor during TTY redraw

	viewAddr := baseAddr
	cursorPos := 0
	inputNibble := ""

	redraw := func() {
		fmt.Fprint(sh.Out, "\033[H\033[2J"+formatDMView(sh, viewAddr, totalBytes, desloc, cursorPos, inputNibble, true))
	}

	redraw()

	buf := make([]byte, 16)
	for {
		n, err := file.Read(buf)
		if err != nil || n == 0 {
			break
		}

		if handleDMKey(sh, buf, n, &viewAddr, &cursorPos, &inputNibble, desloc, totalBytes) {
			break
		}
		redraw()
	}
	if viewAddr+uint16(totalBytes) > sh.LastDump {
		sh.LastDump = viewAddr + uint16(totalBytes)
	}
}

func parseDMBytes(s string) (int, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return 128, nil
	}

	rawVal, err := z80.ParseNumber(s)
	if err != nil {
		return 128, err
	}

	b := int(rawVal)
	// Nearest multiple of 128
	n := (b + 64) / 128
	if n < 1 {
		n = 1
	}
	res := n * 128
	if res > 65536 {
		res = 65536
	}
	return res, nil
}

func parseDMDesloc(s string) (int, error) {
	s = strings.TrimSpace(s)
	neg := false
	if strings.HasPrefix(s, "-") {
		neg = true
		s = s[1:]
	} else if strings.HasPrefix(s, "+") {
		s = s[1:]
	}
	v, err := z80.ParseNumber(s)
	if err != nil {
		return 0, err
	}
	if neg {
		return -int(v), nil
	}
	return int(v), nil
}

// handleDMKey processes a single key or escape sequence in the DM editor.
// Returns true if the editing session should terminate (ESC pressed).
func handleDMKey(sh *Shell, buf []byte, n int, baseAddr *uint16, cursorPos *int, inputNibble *string, desloc int, totalBytes int) bool {
	if n == 0 {
		return false
	}
	key := buf[0]

	bottomRowStart := totalBytes - 16
	lastByteIndex := totalBytes - 1
	maxBaseAddr := uint16(0)
	if totalBytes < 65536 {
		maxBaseAddr = uint16(65536 - totalBytes)
	}

	// ESC key
	if key == 0x1B {
		if n == 1 {
			// Bare ESC key -> Exit editing
			return true
		}
		// Escape sequence (e.g. Arrow keys, Page Up/Down)
		if n >= 3 && (buf[1] == '[' || buf[1] == 'O') {
			switch buf[2] {
			case 'A': // Up
				if *cursorPos >= 16 {
					*cursorPos -= 16
				} else {
					// At top row of totalBytes -> scroll 1 line up
					if *baseAddr >= 16 {
						*baseAddr -= 16
					} else {
						*baseAddr = 0
					}
				}
				*inputNibble = ""

			case 'B': // Down
				if *cursorPos < bottomRowStart {
					*cursorPos += 16
				} else {
					// At bottom row of totalBytes -> scroll 1 line down
					if *baseAddr+16 <= maxBaseAddr {
						*baseAddr += 16
					} else {
						*baseAddr = maxBaseAddr
					}
				}
				*inputNibble = ""

			case 'C': // Right
				if *cursorPos < lastByteIndex {
					*cursorPos++
				} else {
					// At end of totalBytes -> scroll 1 line down, cursor to start of bottom row
					if *baseAddr+16 <= maxBaseAddr {
						*baseAddr += 16
						*cursorPos = bottomRowStart
					} else if *baseAddr < maxBaseAddr {
						*baseAddr = maxBaseAddr
						*cursorPos = bottomRowStart
					}
				}
				*inputNibble = ""

			case 'D': // Left
				if *cursorPos > 0 {
					*cursorPos--
				} else {
					// At start of totalBytes -> scroll 1 line up, cursor to end of top row
					if *baseAddr >= 16 {
						*baseAddr -= 16
						*cursorPos = 15
					} else if *baseAddr > 0 {
						*baseAddr = 0
						*cursorPos = 15
					}
				}
				*inputNibble = ""

			case '5', 'V', 'Z': // Page Up / Shift+Tab (back totalBytes)
				step := uint16(totalBytes)
				if *baseAddr >= step {
					*baseAddr -= step
				} else {
					*baseAddr = 0
				}
				*inputNibble = ""

			case '6', 'U': // Page Down (forward totalBytes)
				step := uint16(totalBytes)
				if *baseAddr+step <= maxBaseAddr {
					*baseAddr += step
				} else {
					*baseAddr = maxBaseAddr
				}
				*inputNibble = ""
			}
		}
		return false
	}

	// TAB key -> advance totalBytes (like MegaAssembler / Page Down)
	if key == 0x09 {
		step := uint16(totalBytes)
		if *baseAddr+step <= maxBaseAddr {
			*baseAddr += step
		} else {
			*baseAddr = maxBaseAddr
		}
		*inputNibble = ""
		return false
	}

	// ENTER key -> confirm byte entry
	if key == '\r' || key == '\n' {
		if *inputNibble != "" {
			newDispVal, err := strconv.ParseUint(*inputNibble, 16, 8)
			if err == nil {
				newRawVal := byte(int(newDispVal) - desloc)
				curAddr := *baseAddr + uint16(*cursorPos)
				sh.Machine.Bus.Write(curAddr, newRawVal)
				if *cursorPos < lastByteIndex {
					*cursorPos++
				} else {
					if *baseAddr+16 <= maxBaseAddr {
						*baseAddr += 16
						*cursorPos = bottomRowStart
					}
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
			} else {
				if *baseAddr >= 16 {
					*baseAddr -= 16
					*cursorPos = 15
				}
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
				curAddr := *baseAddr + uint16(*cursorPos)
				sh.Machine.Bus.Write(curAddr, newRawVal)
				if *cursorPos < lastByteIndex {
					*cursorPos++
				} else {
					if *baseAddr+16 <= maxBaseAddr {
						*baseAddr += 16
						*cursorPos = bottomRowStart
					}
				}
			}
			*inputNibble = ""
		}
		return false
	}

	return false
}

// formatDMView produces memory dump with displacement applied.
// Displays all totalBytes simultaneously on the screen (e.g. 128 = 8 rows, 256 = 16 rows, 512 = 32 rows).
// When cursorPos >= 0 (interactive mode), it highlights the active cursor position.
func formatDMView(sh *Shell, baseAddr uint16, totalBytes int, desloc int, cursorPos int, inputNibble string, useAnsi bool) string {
	var sb strings.Builder

	curAddr := baseAddr
	if cursorPos >= 0 {
		curAddr = baseAddr + uint16(cursorPos)
	}
	endAddr := baseAddr + uint16(totalBytes-1)

	sb.WriteString("=== Display & Memory Edit (DM) ===\n")
	sb.WriteString(fmt.Sprintf("Range: %04Xh..%04Xh (%d bytes) | Displacement: %+d | Cursor: %04Xh\n",
		baseAddr, endAddr, totalBytes, desloc, curAddr))
	sb.WriteString(fmt.Sprintf("[Arrows]: Navigate/Scroll  [PgUp/PgDn/TAB]: ±%dB  [0-9, A-F]: Edit  [ESC]: Exit\n", totalBytes))
	sb.WriteString("-----------------------------------------------------------------\n")

	numRows := totalBytes / 16
	if numRows < 1 {
		numRows = 1
	}

	for row := 0; row < numRows; row++ {
		rowAddr := baseAddr + uint16(row*16)
		sb.WriteString(fmt.Sprintf("%04X:  ", rowAddr))

		var hexStrs []string
		for col := 0; col < 16; col++ {
			idx := row*16 + col
			addr := rowAddr + uint16(col)
			rawByte := sh.Machine.Bus.Read(addr)
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
				hexStrs = append(hexStrs, "") // separator space between 8-byte halves
			}
		}
		sb.WriteString(strings.Join(hexStrs, " "))
		sb.WriteString("  |")

		for col := 0; col < 16; col++ {
			idx := row*16 + col
			addr := rowAddr + uint16(col)
			rawByte := sh.Machine.Bus.Read(addr)
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
