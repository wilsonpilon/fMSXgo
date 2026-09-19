package tui

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"

	"golang.org/x/term"
)

// Hardware models
const (
	ModelMSX1  = 0
	ModelMSX2  = 1
	ModelMSX2P = 2
)

// ModelPickerOptions configures the interactive TUI MSX machine model selector.
type ModelPickerOptions struct {
	CurrentModel int       // Initially highlighted/selected model (0: MSX1, 1: MSX2, 2: MSX2+)
	In           io.Reader // Input stream (defaults to os.Stdin)
	Out          io.Writer // Output stream (defaults to os.Stdout)
}

// ModelEntry contains specifications and metadata for an MSX generation.
type ModelEntry struct {
	ID          int
	Name        string
	VDP         string
	VRAM        string
	RAM         string
	ROMs        string
	Description string
}

// ModelEntries defines the three standard MSX models faithful to fMSX.
var ModelEntries = []ModelEntry{
	{
		ID:          ModelMSX1,
		Name:        "MSX 1",
		VDP:         "TMS9918A",
		VRAM:        "16 KB (2 pages)",
		RAM:         "64 KB (4 pages)",
		ROMs:        "MSX.ROM (32 KB)",
		Description: "Standard 1983 1st-Gen MSX. Screen 0-3, 16 colors.",
	},
	{
		ID:          ModelMSX2,
		Name:        "MSX 2",
		VDP:         "Yamaha V9938",
		VRAM:        "128 KB (8 pages)",
		RAM:         "128 KB (8 pages)",
		ROMs:        "MSX2.ROM + MSX2EXT.ROM + DISK.ROM (64 KB)",
		Description: "1985 2nd-Gen MSX. Screen 0-8, 512 colors, VDP blitter.",
	},
	{
		ID:          ModelMSX2P,
		Name:        "MSX 2+",
		VDP:         "Yamaha V9958",
		VRAM:        "128 KB (8 pages)",
		RAM:         "128 KB (8 pages)",
		ROMs:        "MSX2P.ROM + MSX2PEXT.ROM + DISK.ROM (64 KB)",
		Description: "1988 Enhanced MSX. Screen 10-12 (19,268 YJK colors).",
	},
}

// SelectMachineModel launches an interactive TUI model selector.
// Supports arrow keys, 1-3 keys, Enter to confirm, and ESC/q to cancel.
// Falls back to line-based input when stdin is not a raw terminal.
func SelectMachineModel(opts ModelPickerOptions) (int, error) {
	in := opts.In
	if in == nil {
		in = os.Stdin
	}
	out := opts.Out
	if out == nil {
		out = os.Stdout
	}

	selected := opts.CurrentModel
	if selected < 0 || selected >= len(ModelEntries) {
		selected = ModelMSX2
	}

	file, ok := in.(*os.File)
	if !ok || !term.IsTerminal(int(file.Fd())) {
		return selectModelFallback(in, out, selected)
	}

	// Put terminal into raw mode
	oldState, err := term.MakeRaw(int(file.Fd()))
	if err != nil {
		return selectModelFallback(in, out, selected)
	}
	defer func() {
		_ = term.Restore(int(file.Fd()), oldState)
		fmt.Fprint(out, "\033[?25h\r\n") // Restore cursor visibility
	}()

	// Hide cursor during navigation
	fmt.Fprint(out, "\033[?25l")

	reader := bufio.NewReader(file)

	for {
		renderModelPicker(out, selected, opts.CurrentModel)

		b, err := reader.ReadByte()
		if err != nil {
			return selected, err
		}

		switch b {
		case 3, 27: // Ctrl+C or ESC
			// Check if part of ANSI escape sequence (arrow keys)
			if b == 27 && reader.Buffered() >= 2 {
				b1, _ := reader.ReadByte()
				b2, _ := reader.ReadByte()
				if b1 == '[' || b1 == 'O' {
					switch b2 {
					case 'A': // Up
						selected--
						if selected < 0 {
							selected = len(ModelEntries) - 1
						}
					case 'B': // Down
						selected++
						if selected >= len(ModelEntries) {
							selected = 0
						}
					}
				}
				continue
			}
			return opts.CurrentModel, ErrCancelled

		case 'q', 'Q':
			return opts.CurrentModel, ErrCancelled

		case '\r', '\n', ' ':
			// Confirm selection
			return selected, nil

		case '1':
			return ModelMSX1, nil
		case '2':
			return ModelMSX2, nil
		case '3':
			return ModelMSX2P, nil

		case 'k', 'K', 'w', 'W':
			selected--
			if selected < 0 {
				selected = len(ModelEntries) - 1
			}

		case 'j', 'J', 's', 'S', '\t':
			selected++
			if selected >= len(ModelEntries) {
				selected = 0
			}
		}
	}
}

func renderModelPicker(out io.Writer, selected int, currentModel int) {
	var b strings.Builder

	// Clear screen and move to home position
	b.WriteString("\033[H\033[2J")

	b.WriteString("\r\n")
	b.WriteString("  \033[1;36m┌────────────────────────────────────────────────────────────────────────┐\033[0m\r\n")
	b.WriteString("  \033[1;36m│\033[0m             \033[1;37mfMSXgo - MSX MACHINE MODEL SELECTOR (TUI)\033[0m                  \033[1;36m│\033[0m\r\n")
	b.WriteString("  \033[1;36m├────────────────────────────────────────────────────────────────────────┤\033[0m\r\n")
	b.WriteString("  \033[1;36m│\033[0m  Select the hardware model to emulate with faithful system ROMs:       \033[1;36m│\033[0m\r\n")
	b.WriteString("  \033[1;36m│\033[0m                                                                        \033[1;36m│\033[0m\r\n")

	for i, m := range ModelEntries {
		isSel := i == selected
		isCurr := i == currentModel

		marker := "   "
		if isSel {
			marker = " \033[1;32m>\033[0m "
		}

		badge := "    "
		if isCurr {
			badge = "\033[1;33m[ACT]\033[0m"
		}

		line := fmt.Sprintf("[%d] %-7s │ VDP: %-10s │ RAM: %-6s │ VRAM: %-6s",
			i+1, m.Name, m.VDP, m.RAM, m.VRAM)

		if isSel {
			b.WriteString(fmt.Sprintf("  \033[1;36m│\033[0m%s\033[1;37;44m %-58s \033[0m %s \033[1;36m│\033[0m\r\n", marker, line, badge))
			b.WriteString(fmt.Sprintf("  \033[1;36m│\033[0m     \033[36m└─ ROMs: %-55s\033[0m   \033[1;36m│\033[0m\r\n", m.ROMs))
		} else {
			b.WriteString(fmt.Sprintf("  \033[1;36m│\033[0m%s  %-58s   %s \033[1;36m│\033[0m\r\n", marker, line, badge))
			b.WriteString(fmt.Sprintf("  \033[1;36m│\033[0m     \033[90m└─ ROMs: %-55s\033[0m   \033[1;36m│\033[0m\r\n", m.ROMs))
		}
	}

	activeDesc := ModelEntries[selected].Description
	b.WriteString("  \033[1;36m│\033[0m                                                                        \033[1;36m│\033[0m\r\n")
	b.WriteString(fmt.Sprintf("  \033[1;36m│\033[0m  \033[1;37mDetails:\033[0m \033[33m%-59s\033[0m \033[1;36m│\033[0m\r\n", activeDesc))
	b.WriteString("  \033[1;36m├────────────────────────────────────────────────────────────────────────┤\033[0m\r\n")
	b.WriteString("  \033[1;36m│\033[0m  \033[1;37m[↑/↓/k/j]\033[0m Move  \033[1;37m[1-3]\033[0m Select Model  \033[1;37m[Enter]\033[0m Confirm  \033[1;37m[ESC/q]\033[0m Cancel    \033[1;36m│\033[0m\r\n")
	b.WriteString("  \033[1;36m└────────────────────────────────────────────────────────────────────────┘\033[0m\r\n")

	fmt.Fprint(out, b.String())
}

func selectModelFallback(in io.Reader, out io.Writer, current int) (int, error) {
	fmt.Fprintln(out, "\n=== fMSXgo - MSX Machine Model Selector ===")
	for i, m := range ModelEntries {
		curr := ""
		if i == current {
			curr = " [CURRENT]"
		}
		fmt.Fprintf(out, "  [%d] %s: %s, %s RAM, %s VRAM (ROMs: %s)%s\n",
			i+1, m.Name, m.VDP, m.RAM, m.VRAM, m.ROMs, curr)
	}
	fmt.Fprintf(out, "Choose MSX model [1-3] (default: %d): ", current+1)

	reader := bufio.NewReader(in)
	line, err := reader.ReadString('\n')
	if err != nil && len(line) == 0 {
		return current, err
	}

	trimmed := strings.TrimSpace(line)
	if trimmed == "" {
		return current, nil
	}

	switch strings.ToLower(trimmed) {
	case "1", "msx1":
		return ModelMSX1, nil
	case "2", "msx2":
		return ModelMSX2, nil
	case "3", "msx2+", "msx2p":
		return ModelMSX2P, nil
	default:
		if num, err := strconv.Atoi(trimmed); err == nil && num >= 1 && num <= 3 {
			return num - 1, nil
		}
		fmt.Fprintf(out, "Unknown selection %q, keeping default (%s).\n", trimmed, ModelEntries[current].Name)
		return current, nil
	}
}
