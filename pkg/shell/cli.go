package shell

import (
	"bufio"
	"crypto/sha1"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"fmsxgo/pkg/cpu/z80"
	"fmsxgo/pkg/i18n"
	"fmsxgo/pkg/msx"
	"fmsxgo/pkg/storage"
	"fmsxgo/pkg/tui"
	"fmsxgo/pkg/ui/font"
	"fmsxgo/pkg/ui/theme"
)

// Shell provides an interactive CLI monitor ("Developer OS") for fMSXgo.
type Shell struct {
	Machine       *msx.Machine
	Breakpoints   map[uint16]bool
	LastDump      uint16
	LastDasm      uint16
	LastPath      string
	LastDiskDrive int
	LastSector    int
	In            io.Reader
	Out           io.Writer
	SwitchToGUI   bool
}

// New creates a new Shell instance.
func New(machine *msx.Machine, in io.Reader, out io.Writer) *Shell {
	if in == nil {
		in = os.Stdin
	}
	if out == nil {
		out = os.Stdout
	}
	return &Shell{
		Machine:     machine,
		Breakpoints: make(map[uint16]bool),
		In:          in,
		Out:         out,
	}
}

// Run starts the interactive REPL loop.
func (sh *Shell) Run() {
	sh.printBanner()

	scanner := bufio.NewScanner(sh.In)
	for {
		fmt.Fprintf(sh.Out, "fMSXgo [%04Xh]> ", sh.Machine.CPU.PC)
		if !scanner.Scan() {
			break
		}
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}
		if sh.ExecuteCommand(line) {
			break
		}
	}
}

// ExecuteCommand parses and executes a single shell command line.
// Returns true if the shell should exit.
func (sh *Shell) ExecuteCommand(line string) bool {
	parts := strings.Fields(line)
	if len(parts) == 0 {
		return false
	}

	cmd := strings.ToLower(parts[0])
	args := parts[1:]

	if strings.HasPrefix(cmd, "dm") && len(cmd) > 2 {
		rest := parts[0][2:]
		cmd = "dm"
		args = append([]string{rest}, args...)
	}

	if strings.HasPrefix(cmd, "zap") && len(cmd) > 3 {
		rest := parts[0][3:]
		cmd = "zap"
		args = append([]string{rest}, args...)
	}

	if strings.HasPrefix(cmd, "vd") && len(cmd) > 2 && cmd != "vdp" {
		rest := parts[0][2:]
		cmd = "vd"
		args = append([]string{rest}, args...)
	}

	switch cmd {
	case "exit", "quit", "q", "ba", "basic", "qt":
		fmt.Fprintln(sh.Out, "Exiting fMSXgo...")
		return true

	case "windows", "window", "gui":
		fmt.Fprintln(sh.Out, "Switching to Graphical Window (GUI)...")
		sh.SwitchToGUI = true
		return true

	case "help", "?":
		sh.cmdHelp()

	case "lang", "language":
		sh.cmdLang(args)

	case "theme":
		sh.cmdTheme(args)

	case "font", "typeface":
		sh.cmdFont(args)

	case "roms", "catalog":
		sh.cmdRoms(args)

	case "r", "reg", "regs", "x", "rg":
		if len(args) == 0 {
			sh.cmdRegs()
		} else if len(args) >= 2 {
			sh.cmdSetReg(args[0], args[1])
		} else {
			fmt.Fprintln(sh.Out, "Usage: r (view registers) or r <reg> <val> (set register)")
		}

	case "d", "dump":
		sh.cmdDump(args)

	case "dm":
		sh.cmdDM(args)

	case "vd":
		sh.cmdVD(args)

	case "ve":
		sh.cmdVE(args)

	case "e", "enter":
		sh.cmdEnter(args)

	case "u", "dasm", "l", "i":
		sh.cmdDasm(args)

	case "a", "asm":
		sh.cmdAsm(args)

	case "t", "step", "tr":
		sh.cmdStep(args)

	case "p", "next":
		sh.cmdNext()

	case "g", "run", "go":
		sh.cmdRun(args)

	case "hist", "trace", "history", "tracebuf":
		sh.cmdHist(args)

	case "sym", "symbols", "symbol":
		sh.cmdSym(args)

	case "watch", "wp":
		sh.cmdWatch(args)

	case "bp", "break":
		sh.cmdBreakpoint(args)

	case "vdp":
		sh.cmdVDP()

	case "slots", "page", "page?":
		sh.cmdSlots()

	case "mapper":
		sh.cmdMapper()

	case "diskcreate", "createdsk", "newdsk", "mkdsk":
		sh.cmdDiskCreate(args)

	case "loaddsk", "dskload", "dsk", "diska":
		sh.cmdLoadDSK(args)

	case "zap", "superzap", "diskzap", "szap":
		sh.cmdZAP(args)

	case "in", "pi":
		sh.cmdIn(args)

	case "out", "po":
		sh.cmdOut(args)

	case "model", "msx", "machine":
		sh.cmdModel(args)

	case "savesta", "save":
		sh.cmdSaveSTA(args)

	case "loadsta", "load":
		sh.cmdLoadSTA(args)

	case "fdc":
		sh.cmdFDC(args)

	case "reset":
		sh.Machine.Reset()
		fmt.Fprintln(sh.Out, "MSX Machine & CPU reset.")
		sh.cmdRegs()

	case "info":
		sh.cmdInfo()

	case "cls", "clear":
		fmt.Fprint(sh.Out, "\033[H\033[2J")

	default:
		fmt.Fprintf(sh.Out, "Unknown command: %q. Type 'help' for available commands.\n", cmd)
	}

	return false
}

func (sh *Shell) printBanner() {
	fmt.Fprintln(sh.Out, "================================================================")
	fmt.Fprintf(sh.Out, "       %s\n", i18n.T("cli_welcome"))
	fmt.Fprintln(sh.Out, "       (C) Marat Fayzullin (fMSX core) | Go Port: Wilson Pilon  ")
	fmt.Fprintln(sh.Out, "================================================================")
	fmt.Fprintf(sh.Out, "Model: %s | Video: %s | RAM: %d KB | CPU PC: %04Xh\n",
		sh.modelName(), sh.videoName(), sh.Machine.Config.RAMPages*16, sh.Machine.CPU.PC)
	fmt.Fprintf(sh.Out, "%s\n", i18n.T("cli_help_hint"))
	fmt.Fprintln(sh.Out, "----------------------------------------------------------------")
}

func (sh *Shell) modelName() string {
	if sh.Machine != nil {
		return sh.Machine.ModelName()
	}
	return "MSX 2"
}

func (sh *Shell) videoName() string {
	if sh.Machine.Config.Video == msx.VideoPAL {
		return "PAL (50Hz)"
	}
	return "NTSC (60Hz)"
}

func (sh *Shell) cmdLang(args []string) {
	if len(args) == 0 {
		fmt.Fprintf(sh.Out, "Current UI language: %s (%s)\n", i18n.GetLanguage(), i18n.GetLanguageName())
		fmt.Fprintln(sh.Out, "Available: en (English), pt (Português), es (Español), nl (Nederlands), fr (Français)")
		fmt.Fprintln(sh.Out, "Usage: lang <code> (e.g. 'lang pt')")
		return
	}

	target := args[0]
	if i18n.SetLanguage(target) {
		fmt.Fprintf(sh.Out, "%s %s (%s)\n", i18n.T("cli_lang_changed"), i18n.GetLanguage(), i18n.GetLanguageName())
		if sh.Machine != nil && sh.Machine.DB != nil {
			_ = sh.Machine.DB.SetConfig("language", i18n.GetLanguage())
		}
	} else {
		fmt.Fprintf(sh.Out, "Unknown language code: %s. Supported: en, pt, es, nl, fr\n", target)
	}
}

func (sh *Shell) cmdTheme(args []string) {
	if len(args) == 0 {
		eff := theme.GetEffective()
		fmt.Fprintf(sh.Out, "Current UI theme: %s (%s) [effective: %s]\n", theme.GetCurrent(), eff.Name, eff.ID)
		fmt.Fprintln(sh.Out, "Available themes:")
		for _, th := range theme.List() {
			marker := "  "
			if th.ID == theme.GetCurrent() {
				marker = "* "
			}
			fmt.Fprintf(sh.Out, "  %s%-16s - %s [%s]\n", marker, th.ID, th.Name, th.Category)
		}
		fmt.Fprintln(sh.Out, "Usage: theme <id> (e.g. 'theme dracula', 'theme github-dark', 'theme system')")
		return
	}

	target := args[0]
	if theme.SetCurrent(target) {
		th, _ := theme.Get(target)
		fmt.Fprintf(sh.Out, "%s %s (%s)\n", i18n.T("cli_theme_changed"), th.ID, th.Name)
		if sh.Machine != nil && sh.Machine.DB != nil {
			_ = sh.Machine.DB.SetConfig("theme", th.ID)
		}
	} else {
		fmt.Fprintf(sh.Out, "Unknown theme: %q. Type 'theme' to list available themes.\n", target)
	}
}

func (sh *Shell) cmdFont(args []string) {
	if len(args) == 0 {
		active := font.ActiveFamily()
		fontName := "Ubuntu"
		if active != nil {
			fontName = active.Name
		}
		fmt.Fprintf(sh.Out, "Current UI font: %s (%s)\n", font.GetCurrent(), fontName)
		fmt.Fprintln(sh.Out, "Available font families:")
		for _, f := range font.ListFamilies() {
			marker := "  "
			if f.ID == font.GetCurrent() {
				marker = "* "
			}
			monoTag := ""
			if f.IsMonospace {
				monoTag = " [Monospace]"
			}
			fmt.Fprintf(sh.Out, "  %s%-18s - %s (%s)%s\n", marker, f.ID, f.Name, f.Path, monoTag)
		}
		fmt.Fprintln(sh.Out, "Usage: font <id> (e.g. 'font ubuntu', 'font sourcecodepro')")
		return
	}

	target := args[0]
	if font.SetCurrent(target) {
		f := font.GetFamily(target)
		fmt.Fprintf(sh.Out, "UI font changed to: %s (%s)\n", f.ID, f.Name)
		if sh.Machine != nil && sh.Machine.DB != nil {
			_ = sh.Machine.DB.SetConfig("font", f.ID)
		}
	} else {
		fmt.Fprintf(sh.Out, "Unknown font family: %q. Type 'font' to list available fonts.\n", target)
	}
}

func (sh *Shell) cmdHelp() {
	fmt.Fprintln(sh.Out)
	fmt.Fprintf(sh.Out, "=== %s ===\n", i18n.T("cli_welcome"))
	fmt.Fprintln(sh.Out, "-----------------------------------------------------------------")
	fmt.Fprintf(sh.Out, "%s\n", i18n.T("cli_main_ctrls"))
	fmt.Fprintf(sh.Out, "  HELP                      %s\n", i18n.T("cli_help_desc"))
	fmt.Fprintf(sh.Out, "  QUIT / BA / QT / EXIT     %s\n", i18n.T("cli_quit_desc"))
	fmt.Fprintf(sh.Out, "  windows / window / gui    %s\n", i18n.T("cli_windows_desc"))
	fmt.Fprintf(sh.Out, "  lang [code]               %s\n", i18n.T("cli_lang_desc"))
	fmt.Fprintf(sh.Out, "  theme [id]                %s\n", i18n.T("cli_theme_desc"))
	fmt.Fprintf(sh.Out, "  font [id]                 Select active UI font (e.g. ubuntu, sourcecodepro)\n")
	fmt.Fprintf(sh.Out, "  roms [cmd]                %s\n", i18n.T("cli_roms_desc"))
	fmt.Fprintln(sh.Out)
	fmt.Fprintln(sh.Out, "Registers & CPU:")
	fmt.Fprintf(sh.Out, "  r / x / rg                %s\n", i18n.T("cli_regs_desc"))
	fmt.Fprintf(sh.Out, "  r <reg> <val>             %s\n", i18n.T("cli_setreg_desc"))
	fmt.Fprintln(sh.Out)
	fmt.Fprintln(sh.Out, "Memory & VRAM Inspection / Editing:")
	fmt.Fprintf(sh.Out, "  d [addr] [len]            %s\n", i18n.T("cli_dump_desc"))
	fmt.Fprintf(sh.Out, "  dm [addr] [desloc] [len]  %s\n", i18n.T("cli_dm_desc"))
	fmt.Fprintf(sh.Out, "  e <addr> <b0> [b1...]     %s\n", i18n.T("cli_enter_desc"))
	fmt.Fprintf(sh.Out, "  vd [addr] [len]           Dump Video RAM (VRAM) in hex & ASCII\n")
	fmt.Fprintf(sh.Out, "  ve <addr> <b0> [b1...]    Edit bytes in Video RAM (VRAM)\n")
	fmt.Fprintf(sh.Out, "  vdp                       Display VDP registers, status, mode & tables\n")
	fmt.Fprintln(sh.Out)
	fmt.Fprintln(sh.Out, "Disassembly & Assembly:")
	fmt.Fprintf(sh.Out, "  u / l / i [addr] [count]  %s\n", i18n.T("cli_dasm_desc"))
	fmt.Fprintf(sh.Out, "  a <addr>                  %s\n", i18n.T("cli_asm_desc"))
	fmt.Fprintln(sh.Out)
	fmt.Fprintln(sh.Out, "Execution, History & Debugging:")
	fmt.Fprintf(sh.Out, "  t / tr [n]                %s\n", i18n.T("cli_step_desc"))
	fmt.Fprintf(sh.Out, "  p                         %s\n", i18n.T("cli_next_desc"))
	fmt.Fprintf(sh.Out, "  g / go [addr]             %s\n", i18n.T("cli_run_desc"))
	fmt.Fprintf(sh.Out, "  hist [n | clear]          View circular execution trace buffer (last 10,000 steps)\n")
	fmt.Fprintf(sh.Out, "  sym [load|list|find]      Manage assembly symbol table (.sym, .map, Pasmo, asMSX)\n")
	fmt.Fprintf(sh.Out, "  bp [add|del|list|clear]   %s (with optional condition, e.g. A == 42h)\n", i18n.T("cli_bp_desc"))
	fmt.Fprintf(sh.Out, "  watch [r|w|port|line]     Memory read/write, IO port, and scanline watchpoints\n")
	fmt.Fprintln(sh.Out)
	fmt.Fprintln(sh.Out, "MSX Hardware & Slots:")
	fmt.Fprintf(sh.Out, "  model [msx1|msx2|msx2+]   %s\n", i18n.T("cli_model_desc"))
	fmt.Fprintf(sh.Out, "  slots / page              %s\n", i18n.T("cli_slots_desc"))
	fmt.Fprintf(sh.Out, "  mapper                    %s\n", i18n.T("cli_mapper_desc"))
	fmt.Fprintf(sh.Out, "  diskcreate [name] [size]  %s\n", i18n.T("cli_diskcreate_desc"))
	fmt.Fprintf(sh.Out, "  loaddsk [file]            %s\n", i18n.T("cli_loaddsk_desc"))
	fmt.Fprintf(sh.Out, "  zap [sec] [desloc] [len]  %s\n", i18n.T("cli_zap_desc"))
	fmt.Fprintf(sh.Out, "  fdc [bdos|wd1793]         View or switch WD2793 floppy controller mode\n")
	fmt.Fprintf(sh.Out, "  savesta [file.sta]        Save snapshot (fMSX .sta format)\n")
	fmt.Fprintf(sh.Out, "  loadsta [file.sta]        Load snapshot (fMSX .sta format)\n")
	fmt.Fprintf(sh.Out, "  in / pi <port>            %s\n", i18n.T("cli_in_desc"))
	fmt.Fprintf(sh.Out, "  out / po <port> <val>     %s\n", i18n.T("cli_out_desc"))
	fmt.Fprintf(sh.Out, "  info                      %s\n", i18n.T("cli_info_desc"))
	fmt.Fprintf(sh.Out, "  reset                     %s\n", i18n.T("cli_reset_desc"))
	fmt.Fprintf(sh.Out, "  cls                       %s\n", i18n.T("cli_cls_desc"))
	fmt.Fprintln(sh.Out)
}

func (sh *Shell) cmdRegs() {
	cpu := sh.Machine.CPU
	f := cpu.F

	flagStr := fmt.Sprintf("[%c%c%c%c%c%c%c%c]",
		flagChar(f, z80.FlagS, 'S'),
		flagChar(f, z80.FlagZ, 'Z'),
		flagChar(f, z80.Flag5, '5'),
		flagChar(f, z80.FlagH, 'H'),
		flagChar(f, z80.Flag3, '3'),
		flagChar(f, z80.FlagP, 'P'),
		flagChar(f, z80.FlagN, 'N'),
		flagChar(f, z80.FlagC, 'C'),
	)

	fmt.Fprintf(sh.Out, "AF: %04X  BC: %04X  DE: %04X  HL: %04X  Flags: %s\n",
		cpu.AF(), cpu.BC(), cpu.DE(), cpu.HL(), flagStr)
	fmt.Fprintf(sh.Out, "AF':%04X  BC':%04X  DE':%04X  HL':%04X  SP: %04X  PC: %04X\n",
		cpu.AF1(), cpu.BC1(), cpu.DE1(), cpu.HL1(), cpu.SP, cpu.PC)
	fmt.Fprintf(sh.Out, "IX: %04X  IY: %04X  I: %02X  R: %02X  IM: %d  IFF: %t/%t  Halt: %t\n",
		cpu.IX, cpu.IY, cpu.I, cpu.R, cpu.IM, cpu.IFF1, cpu.IFF2, cpu.Halted)

	// Disassemble next instruction at PC
	dis, _ := z80.Disassemble(sh.Machine.Bus, cpu.PC)
	fmt.Fprintf(sh.Out, "=> %04Xh: %s\n", cpu.PC, dis)
}

func flagChar(f uint8, mask uint8, ch rune) rune {
	if (f & mask) != 0 {
		return ch
	}
	return '.'
}

func (sh *Shell) cmdSetReg(regName string, valStr string) {
	val64, err := parseHex(valStr)
	if err != nil {
		fmt.Fprintf(sh.Out, "Invalid value: %s\n", valStr)
		return
	}
	val := uint16(val64)
	val8 := uint8(val64)

	cpu := sh.Machine.CPU
	switch strings.ToUpper(regName) {
	case "A":
		cpu.A = val8
	case "F":
		cpu.F = val8
	case "B":
		cpu.B = val8
	case "C":
		cpu.C = val8
	case "D":
		cpu.D = val8
	case "E":
		cpu.E = val8
	case "H":
		cpu.H = val8
	case "L":
		cpu.L = val8
	case "AF":
		cpu.SetAF(val)
	case "BC":
		cpu.SetBC(val)
	case "DE":
		cpu.SetDE(val)
	case "HL":
		cpu.SetHL(val)
	case "SP":
		cpu.SP = val
	case "PC":
		cpu.PC = val
	case "IX":
		cpu.IX = val
	case "IY":
		cpu.IY = val
	default:
		fmt.Fprintf(sh.Out, "Unknown register: %s\n", regName)
		return
	}
	fmt.Fprintf(sh.Out, "Register %s updated to %04Xh\n", strings.ToUpper(regName), val)
}

func (sh *Shell) cmdDump(args []string) {
	addr := sh.LastDump
	length := 64

	if len(args) >= 1 {
		v, err := parseHex(args[0])
		if err == nil {
			addr = uint16(v)
		}
	}
	if len(args) >= 2 {
		v, err := parseHex(args[1])
		if err == nil {
			length = int(v)
		}
	}

	start := addr & 0xFFF0
	end := addr + uint16(length)

	for row := start; row < end; row += 16 {
		var hexParts []string
		var asciiParts []rune
		for col := uint16(0); col < 16; col++ {
			b := sh.Machine.Bus.Read(row + col)
			hexParts = append(hexParts, fmt.Sprintf("%02X", b))
			if b >= 32 && b <= 126 {
				asciiParts = append(asciiParts, rune(b))
			} else {
				asciiParts = append(asciiParts, '.')
			}
		}
		fmt.Fprintf(sh.Out, "%04X:  %s  |%s|\n", row, strings.Join(hexParts, " "), string(asciiParts))
	}
	sh.LastDump = end
}

func (sh *Shell) cmdEnter(args []string) {
	if len(args) < 2 {
		fmt.Fprintln(sh.Out, "Usage: e <addr> <b0> [b1 b2 ...]")
		return
	}
	addr64, err := parseHex(args[0])
	if err != nil {
		fmt.Fprintf(sh.Out, "Invalid address: %s\n", args[0])
		return
	}
	addr := uint16(addr64)

	count := 0
	for _, byteStr := range args[1:] {
		b, err := parseHex(byteStr)
		if err != nil {
			fmt.Fprintf(sh.Out, "Invalid byte: %s\n", byteStr)
			return
		}
		sh.Machine.Bus.Write(addr, uint8(b))
		addr++
		count++
	}
	fmt.Fprintf(sh.Out, "Wrote %d bytes starting at %04Xh\n", count, uint16(addr64))
}

func (sh *Shell) cmdDasm(args []string) {
	addr := sh.Machine.CPU.PC
	count := 10

	if len(args) >= 1 {
		v, err := parseHex(args[0])
		if err == nil {
			addr = uint16(v)
		}
	} else if sh.LastDasm != 0 {
		addr = sh.LastDasm
	}

	if len(args) >= 2 {
		v, err := parseHex(args[1])
		if err == nil {
			count = int(v)
		}
	}

	for i := 0; i < count; i++ {
		dis, size := z80.Disassemble(sh.Machine.Bus, addr)
		var byteStrs []string
		for b := uint16(0); b < uint16(size); b++ {
			byteStrs = append(byteStrs, fmt.Sprintf("%02X", sh.Machine.Bus.Read(addr+b)))
		}
		byteDump := fmt.Sprintf("%-12s", strings.Join(byteStrs, " "))
		prefix := "  "
		if addr == sh.Machine.CPU.PC {
			prefix = "=>"
		}
		annot := ""
		if sh.Machine.Symbols != nil {
			annot = sh.Machine.Symbols.FormatAnnotation(addr)
		}
		fmt.Fprintf(sh.Out, "%s %04X:  %s  %-20s%s\n", prefix, addr, byteDump, dis, annot)
		addr += uint16(size)
	}
	sh.LastDasm = addr
}

func (sh *Shell) cmdAsm(args []string) {
	if len(args) == 0 {
		fmt.Fprintln(sh.Out, "Usage: a <addr> (interactive mode) or a <addr> <instruction>")
		return
	}

	addr64, err := parseHex(args[0])
	if err != nil {
		fmt.Fprintf(sh.Out, "Invalid address: %s\n", args[0])
		return
	}
	addr := uint16(addr64)

	// Single instruction mode: a <addr> <inst...>
	if len(args) > 1 {
		inst := strings.Join(args[1:], " ")
		bytes, err := z80.AssembleLine(addr, inst)
		if err != nil {
			fmt.Fprintf(sh.Out, "Assemble error: %v\n", err)
			return
		}
		for _, b := range bytes {
			sh.Machine.Bus.Write(addr, b)
			addr++
		}
		fmt.Fprintf(sh.Out, "Assembled %d bytes at %04Xh\n", len(bytes), uint16(addr64))
		return
	}

	// Interactive line-by-line mode
	fmt.Fprintf(sh.Out, "Entering Mini-Assembler at %04Xh (press Enter on empty line to exit):\n", addr)
	scanner := bufio.NewScanner(sh.In)
	for {
		fmt.Fprintf(sh.Out, "%04X: ", addr)
		if !scanner.Scan() {
			break
		}
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			break
		}

		bytes, err := z80.AssembleLine(addr, line)
		if err != nil {
			fmt.Fprintf(sh.Out, "  Error: %v\n", err)
			continue
		}
		for _, b := range bytes {
			sh.Machine.Bus.Write(addr, b)
			addr++
		}
	}
	fmt.Fprintln(sh.Out, "Exited Mini-Assembler.")
}

func (sh *Shell) cmdStep(args []string) {
	count := 1
	if len(args) >= 1 {
		v, err := parseHex(args[0])
		if err == nil && v > 0 {
			count = int(v)
		}
	}

	for i := 0; i < count; i++ {
		dis, _ := z80.Disassemble(sh.Machine.Bus, sh.Machine.CPU.PC)
		fmt.Fprintf(sh.Out, "[Step %d] %04Xh: %s\n", i+1, sh.Machine.CPU.PC, dis)
		sh.Machine.Step()
		if sh.Machine.CPU.Halted {
			fmt.Fprintln(sh.Out, "CPU HALTED.")
			break
		}
		if sh.Breakpoints[sh.Machine.CPU.PC] {
			fmt.Fprintf(sh.Out, "Hit breakpoint at %04Xh!\n", sh.Machine.CPU.PC)
			break
		}
	}
	sh.cmdRegs()
}

func (sh *Shell) cmdNext() {
	pc := sh.Machine.CPU.PC
	_, size := z80.Disassemble(sh.Machine.Bus, pc)
	nextPC := pc + uint16(size)

	// Step once
	sh.Machine.Step()

	// If it was a CALL or loop, run until nextPC is reached or breakpoint hit
	if sh.Machine.CPU.PC != nextPC {
		sh.Breakpoints[nextPC] = true
		for !sh.Machine.CPU.Halted && sh.Machine.CPU.PC != nextPC {
			sh.Machine.Step()
			if sh.Breakpoints[sh.Machine.CPU.PC] && sh.Machine.CPU.PC != nextPC {
				fmt.Fprintf(sh.Out, "Hit breakpoint at %04Xh\n", sh.Machine.CPU.PC)
				break
			}
		}
		delete(sh.Breakpoints, nextPC)
	}

	sh.cmdRegs()
}

func (sh *Shell) cmdRun(args []string) {
	if len(args) >= 1 {
		v, err := parseHex(args[0])
		if err == nil {
			sh.Machine.CPU.PC = uint16(v)
		}
	}

	fmt.Fprintf(sh.Out, "Running from %04Xh...\n", sh.Machine.CPU.PC)
	instructions := 0
	for !sh.Machine.CPU.Halted {
		sh.Machine.Step()
		instructions++
		if sh.Breakpoints[sh.Machine.CPU.PC] {
			fmt.Fprintf(sh.Out, "Hit breakpoint at %04Xh after %d instructions!\n", sh.Machine.CPU.PC, instructions)
			break
		}
		if instructions >= 1000000 {
			fmt.Fprintln(sh.Out, "Execution limit reached (1,000,000 instructions). Paused.")
			break
		}
	}

	if sh.Machine.CPU.Halted {
		fmt.Fprintln(sh.Out, "CPU HALTED.")
	}
	sh.cmdRegs()
}

func (sh *Shell) cmdBreakpoint(args []string) {
	dbg := sh.Machine.Debugger
	if len(args) == 0 {
		sh.cmdWatch(nil)
		return
	}

	sub := strings.ToLower(args[0])
	switch sub {
	case "add":
		if len(args) < 2 {
			fmt.Fprintln(sh.Out, "Usage: bp add <addr> [condition]")
			return
		}
		v, err := parseHex(args[1])
		if err != nil {
			fmt.Fprintf(sh.Out, "Invalid address: %s\n", args[1])
			return
		}
		cond := ""
		if len(args) >= 3 {
			cond = strings.Join(args[2:], " ")
		}
		id := 0
		if dbg != nil {
			id = dbg.AddPC(uint16(v), cond)
		}
		sh.Breakpoints[uint16(v)] = true
		if cond != "" {
			fmt.Fprintf(sh.Out, "Breakpoint #%d added at %04Xh (if %s)\n", id, uint16(v), cond)
		} else {
			fmt.Fprintf(sh.Out, "Breakpoint #%d added at %04Xh\n", id, uint16(v))
		}

	case "del", "delete", "rm":
		if len(args) < 2 {
			fmt.Fprintln(sh.Out, "Usage: bp del <addr or id>")
			return
		}
		if id, err := strconv.Atoi(args[1]); err == nil && dbg != nil && dbg.Remove(id) {
			fmt.Fprintf(sh.Out, "Breakpoint #%d removed\n", id)
			return
		}
		v, err := parseHex(args[1])
		if err != nil {
			fmt.Fprintf(sh.Out, "Invalid address or ID: %s\n", args[1])
			return
		}
		delete(sh.Breakpoints, uint16(v))
		if dbg != nil {
			for _, bp := range dbg.List() {
				if bp.Addr == uint16(v) && bp.Type == msx.BPTypePC {
					dbg.Remove(bp.ID)
				}
			}
		}
		fmt.Fprintf(sh.Out, "Breakpoint removed at %04Xh\n", uint16(v))

	case "clear":
		sh.Breakpoints = make(map[uint16]bool)
		if dbg != nil {
			dbg.Clear()
		}
		fmt.Fprintln(sh.Out, "All breakpoints and watchpoints cleared.")

	case "list":
		sh.cmdWatch(nil)

	default:
		// Shorthand: bp <addr> -> bp add <addr>
		if _, err := parseHex(args[0]); err == nil {
			sh.cmdBreakpoint([]string{"add", args[0]})
			return
		}
		fmt.Fprintln(sh.Out, "Usage: bp add <addr> [condition] | bp del <id|addr> | bp list | bp clear")
	}
}

func (sh *Shell) cmdWatch(args []string) {
	dbg := sh.Machine.Debugger
	if dbg == nil {
		fmt.Fprintln(sh.Out, "Debugger not initialized.")
		return
	}
	if len(args) == 0 {
		bps := dbg.List()
		if len(bps) == 0 {
			fmt.Fprintln(sh.Out, "No active breakpoints or watchpoints.")
			return
		}
		fmt.Fprintln(sh.Out, "Active Breakpoints & Watchpoints:")
		for _, bp := range bps {
			fmt.Fprintf(sh.Out, "  [#%d] %-10s %-30s (Hits: %d, Enabled: %v)\n",
				bp.ID, bp.Type, bp.Description(), bp.HitCount, bp.Enabled)
		}
		return
	}

	mode := strings.ToLower(args[0])
	switch mode {
	case "r", "read":
		if len(args) < 2 {
			fmt.Fprintln(sh.Out, "Usage: watch r <addr> [endAddr] [cond]")
			return
		}
		a, err := parseHex(args[1])
		if err != nil {
			fmt.Fprintln(sh.Out, "Invalid address.")
			return
		}
		endA := a
		cond := ""
		if len(args) >= 3 {
			if e, err := parseHex(args[2]); err == nil {
				endA = e
				if len(args) >= 4 {
					cond = strings.Join(args[3:], " ")
				}
			} else {
				cond = strings.Join(args[2:], " ")
			}
		}
		id := dbg.AddMemWatch(uint16(a), uint16(endA), false, cond)
		fmt.Fprintf(sh.Out, "Added Read Watchpoint #%d for %04Xh..%04Xh\n", id, uint16(a), uint16(endA))

	case "w", "write":
		if len(args) < 2 {
			fmt.Fprintln(sh.Out, "Usage: watch w <addr> [endAddr] [cond]")
			return
		}
		a, err := parseHex(args[1])
		if err != nil {
			fmt.Fprintln(sh.Out, "Invalid address.")
			return
		}
		endA := a
		cond := ""
		if len(args) >= 3 {
			if e, err := parseHex(args[2]); err == nil {
				endA = e
				if len(args) >= 4 {
					cond = strings.Join(args[3:], " ")
				}
			} else {
				cond = strings.Join(args[2:], " ")
			}
		}
		id := dbg.AddMemWatch(uint16(a), uint16(endA), true, cond)
		fmt.Fprintf(sh.Out, "Added Write Watchpoint #%d for %04Xh..%04Xh\n", id, uint16(a), uint16(endA))

	case "port", "io":
		if len(args) < 2 {
			fmt.Fprintln(sh.Out, "Usage: watch port <portHex> [in|out] [cond]")
			return
		}
		p, err := parseHex(args[1])
		if err != nil {
			fmt.Fprintln(sh.Out, "Invalid port.")
			return
		}
		isOut := false
		cond := ""
		if len(args) >= 3 {
			if strings.ToLower(args[2]) == "out" {
				isOut = true
			}
			if len(args) >= 4 {
				cond = strings.Join(args[3:], " ")
			}
		}
		id := dbg.AddIOWatch(uint16(p), isOut, cond)
		dir := "IN"
		if isOut {
			dir = "OUT"
		}
		fmt.Fprintf(sh.Out, "Added IO Watchpoint #%d for Port %02Xh (%s)\n", id, uint8(p), dir)

	case "line", "scanline":
		if len(args) < 2 {
			fmt.Fprintln(sh.Out, "Usage: watch line <scanlineNum>")
			return
		}
		l, err := strconv.Atoi(args[1])
		if err != nil {
			fmt.Fprintln(sh.Out, "Invalid line number.")
			return
		}
		id := dbg.AddScanline(l)
		fmt.Fprintf(sh.Out, "Added Scanline Breakpoint #%d on line %d\n", id, l)

	case "del", "rm":
		if len(args) < 2 {
			fmt.Fprintln(sh.Out, "Usage: watch del <id>")
			return
		}
		id, err := strconv.Atoi(args[1])
		if err != nil || !dbg.Remove(id) {
			fmt.Fprintf(sh.Out, "Watchpoint #%s not found.\n", args[1])
			return
		}
		fmt.Fprintf(sh.Out, "Watchpoint #%d removed.\n", id)

	case "clear":
		dbg.Clear()
		fmt.Fprintln(sh.Out, "All watchpoints and breakpoints cleared.")

	default:
		fmt.Fprintln(sh.Out, "Usage: watch r <addr> | watch w <addr> | watch port <port> | watch line <line> | watch del <id> | watch clear")
	}
}

func (sh *Shell) cmdVDP() {
	v := sh.Machine.VDP
	if v == nil {
		fmt.Fprintln(sh.Out, "VDP not initialized.")
		return
	}

	fmt.Fprintln(sh.Out, "=== Video Display Processor (VDP) State ===")
	fmt.Fprintf(sh.Out, "Screen Mode: SCREEN %d (Scanline %d/%d, VR=%v, VBlank=%v)\n",
		v.ScrMode, v.ScanLine, v.TotalLines, (v.Status[2]&0x40) != 0, (v.Status[0]&0x80) != 0)
	fmt.Fprintf(sh.Out, "VRAM Address: %04Xh | VPageOffset: %05Xh | VKey: %v | IRQ: %02Xh\n",
		v.VAddr, v.VPageOffset, v.VKey, v.IRQPending)
	fmt.Fprintf(sh.Out, "Tables: ChrTab=%05Xh (Msk=%05Xh), ChrGen=%05Xh (Msk=%05Xh)\n",
		v.ChrTab, v.ChrTabM, v.ChrGen, v.ChrGenM)
	fmt.Fprintf(sh.Out, "        ColTab=%05Xh (Msk=%05Xh), SprTab=%05Xh, SprGen=%05Xh\n",
		v.ColTab, v.ColTabM, v.SprTab, v.SprGen)
	fmt.Fprintf(sh.Out, "Display: VAdjust: %+d, HAdjust: %+d, Blink: %v\n",
		v.VAdjust(), v.HAdjust(), v.BFlag)

	fmt.Fprintln(sh.Out, "\nControl Registers (R#0..R#23):")
	for i := 0; i < 24; i += 8 {
		var hexStrs []string
		for j := 0; j < 8; j++ {
			hexStrs = append(hexStrs, fmt.Sprintf("R#%02d=%02X", i+j, v.Regs[i+j]))
		}
		fmt.Fprintf(sh.Out, "  %s\n", strings.Join(hexStrs, "  "))
	}

	fmt.Fprintln(sh.Out, "\nStatus Registers (S#0..S#9):")
	for i := 0; i < 10; i += 5 {
		var hexStrs []string
		for j := 0; j < 5 && (i+j) < 16; j++ {
			hexStrs = append(hexStrs, fmt.Sprintf("S#%d=%02X", i+j, v.Status[i+j]))
		}
		fmt.Fprintf(sh.Out, "  %s\n", strings.Join(hexStrs, "  "))
	}
}

func (sh *Shell) cmdVD(args []string) {
	v := sh.Machine.VDP
	if v == nil {
		fmt.Fprintln(sh.Out, "VDP not initialized.")
		return
	}

	addr := uint32(0)
	count := 64
	if len(args) >= 1 {
		val, err := parseHex(args[0])
		if err == nil {
			addr = uint32(val)
		}
	}
	if len(args) >= 2 {
		val, err := parseHex(args[1])
		if err == nil && val > 0 {
			count = int(val)
		}
	}

	vramLen := uint32(len(v.VRAM))
	for count > 0 && addr < vramLen {
		chunk := 16
		if chunk > count {
			chunk = count
		}
		var hexParts []string
		var asciiParts []byte
		for i := 0; i < chunk; i++ {
			b := v.VRAM[(addr+uint32(i))%vramLen]
			hexParts = append(hexParts, fmt.Sprintf("%02X", b))
			if b >= 0x20 && b <= 0x7E {
				asciiParts = append(asciiParts, b)
			} else {
				asciiParts = append(asciiParts, '.')
			}
		}
		hexStr := fmt.Sprintf("%-48s", strings.Join(hexParts, " "))
		fmt.Fprintf(sh.Out, "%05X: %s  |%s|\n", addr, hexStr, string(asciiParts))
		addr += uint32(chunk)
		count -= chunk
	}
}

func (sh *Shell) cmdVE(args []string) {
	v := sh.Machine.VDP
	if v == nil {
		fmt.Fprintln(sh.Out, "VDP not initialized.")
		return
	}
	if len(args) < 2 {
		fmt.Fprintln(sh.Out, "Usage: ve <addr> <b1> [b2...]")
		return
	}
	addr64, err := parseHex(args[0])
	if err != nil {
		fmt.Fprintf(sh.Out, "Invalid address: %s\n", args[0])
		return
	}
	addr := uint32(addr64) % uint32(len(v.VRAM))
	for _, arg := range args[1:] {
		val, err := parseHex(arg)
		if err != nil {
			fmt.Fprintf(sh.Out, "Invalid byte value: %s\n", arg)
			return
		}
		v.VRAM[addr] = uint8(val)
		addr = (addr + 1) % uint32(len(v.VRAM))
	}
	fmt.Fprintf(sh.Out, "Updated %d bytes in VRAM starting at %05Xh\n", len(args)-1, uint32(addr64))
}

func (sh *Shell) cmdHist(args []string) {
	count := 20
	if len(args) >= 1 {
		if args[0] == "clear" {
			sh.Machine.CPU.ClearHistory()
			fmt.Fprintln(sh.Out, "Execution history cleared.")
			return
		}
		v, err := parseHex(args[0])
		if err == nil && v > 0 {
			count = int(v)
		}
	}

	history := sh.Machine.CPU.GetHistory(count)
	if len(history) == 0 {
		fmt.Fprintln(sh.Out, "Execution history is empty.")
		return
	}

	fmt.Fprintf(sh.Out, "=== Last %d Executed Instructions (Total in Buffer: %d) ===\n", len(history), sh.Machine.CPU.HistoryCount)
	for i, entry := range history {
		dasm, _ := entry.Disassemble()
		annot := ""
		if sh.Machine.Symbols != nil {
			annot = sh.Machine.Symbols.FormatAnnotation(entry.PC)
		}
		fmt.Fprintf(sh.Out, "[%3d] %04X: %-18s%-10s AF=%04X BC=%04X DE=%04X HL=%04X SP=%04X\n",
			i+1, entry.PC, dasm, annot, entry.AF, entry.BC, entry.DE, entry.HL, entry.SP)
	}
}

func (sh *Shell) cmdSym(args []string) {
	if len(args) == 0 {
		fmt.Fprintln(sh.Out, "Usage: sym load <file> | sym list [filter] | sym find <name/addr>")
		return
	}
	st := sh.Machine.Symbols
	if st == nil {
		st = msx.NewSymbolTable()
		sh.Machine.Symbols = st
	}

	sub := strings.ToLower(args[0])
	switch sub {
	case "load":
		if len(args) < 2 {
			fmt.Fprintln(sh.Out, "Usage: sym load <filename>")
			return
		}
		path := args[1]
		count, err := st.LoadFile(path)
		if err != nil {
			fmt.Fprintf(sh.Out, "Error loading symbol file '%s': %v\n", path, err)
			return
		}
		fmt.Fprintf(sh.Out, "Successfully loaded %d symbols from %s\n", count, path)

	case "list":
		filter := ""
		if len(args) >= 2 {
			filter = args[1]
		}
		list := st.List(filter)
		fmt.Fprintf(sh.Out, "Symbol Table (%d matching):\n", len(list))
		for _, s := range list {
			fmt.Fprintf(sh.Out, "  %04Xh  %s\n", s.Addr, s.Name)
		}

	case "find":
		if len(args) < 2 {
			fmt.Fprintln(sh.Out, "Usage: sym find <name or hex addr>")
			return
		}
		target := args[1]
		if addr, ok := st.Find(target); ok {
			fmt.Fprintf(sh.Out, "Symbol %s -> %04Xh\n", strings.ToUpper(target), addr)
			return
		}
		if v, err := parseHex(target); err == nil {
			if name, ok := st.Lookup(uint16(v)); ok {
				fmt.Fprintf(sh.Out, "Address %04Xh -> %s\n", uint16(v), name)
				return
			}
		}
		fmt.Fprintf(sh.Out, "No symbol found for '%s'\n", target)
	}
}

func (sh *Shell) cmdSlots() {
	fmt.Fprint(sh.Out, sh.Machine.Slots.FormatSlotState())
}

func (sh *Shell) cmdMapper() {
	m := sh.Machine.Mapper
	fmt.Fprintf(sh.Out, "RAM Mapper Total Pages: %d (Size: %d KB)\n", m.Pages, m.Pages*16)
	fmt.Fprintf(sh.Out, "Port FCh (Page 0): %02Xh (Bank %d)\n", m.Regs[0], m.Regs[0]&m.Mask)
	fmt.Fprintf(sh.Out, "Port FDh (Page 1): %02Xh (Bank %d)\n", m.Regs[1], m.Regs[1]&m.Mask)
	fmt.Fprintf(sh.Out, "Port FEh (Page 2): %02Xh (Bank %d)\n", m.Regs[2], m.Regs[2]&m.Mask)
	fmt.Fprintf(sh.Out, "Port FFh (Page 3): %02Xh (Bank %d)\n", m.Regs[3], m.Regs[3]&m.Mask)
}

func (sh *Shell) cmdIn(args []string) {
	if len(args) < 1 {
		fmt.Fprintln(sh.Out, "Usage: in <port>")
		return
	}
	port64, err := parseHex(args[0])
	if err != nil {
		fmt.Fprintf(sh.Out, "Invalid port: %s\n", args[0])
		return
	}
	val := sh.Machine.Bus.In(uint16(port64))
	fmt.Fprintf(sh.Out, "IN(%02Xh) -> %02Xh (%08b)\n", uint8(port64), val, val)
}

func (sh *Shell) cmdOut(args []string) {
	if len(args) < 2 {
		fmt.Fprintln(sh.Out, "Usage: out <port> <val>")
		return
	}
	port64, err := parseHex(args[0])
	if err != nil {
		fmt.Fprintf(sh.Out, "Invalid port: %s\n", args[0])
		return
	}
	val64, err := parseHex(args[1])
	if err != nil {
		fmt.Fprintf(sh.Out, "Invalid value: %s\n", args[1])
		return
	}
	sh.Machine.Bus.Out(uint16(port64), uint8(val64))
	fmt.Fprintf(sh.Out, "OUT(%02Xh, %02Xh) executed.\n", uint8(port64), uint8(val64))
}

func (sh *Shell) cmdInfo() {
	cfg := sh.Machine.Config
	fmt.Fprintf(sh.Out, "Hardware Model: %s\n", sh.modelName())
	fmt.Fprintf(sh.Out, "Video Standard: %s\n", sh.videoName())
	fmt.Fprintf(sh.Out, "RAM Pages: %d (%d KB)\n", cfg.RAMPages, cfg.RAMPages*16)
	fmt.Fprintf(sh.Out, "VRAM Pages: %d (%d KB)\n", cfg.VRAMPages, cfg.VRAMPages*64)
	if cfg.CartAPath != "" {
		fmt.Fprintf(sh.Out, "Cartridge A: %s\n", cfg.CartAPath)
	}
	if cfg.CartBPath != "" {
		fmt.Fprintf(sh.Out, "Cartridge B: %s\n", cfg.CartBPath)
	}
}

// parseHex parses numeric literals according to the fMSXgo standard via z80.ParseNumber:
// default hex, with b/d/h/o prefixes and standard suffixes.
func parseHex(s string) (uint64, error) {
	return z80.ParseNumber(s)
}

// ---------------------------------------------------------------------
// ROM & Hardware Catalog CLI Subsystem (SQLite CRUD)
// ---------------------------------------------------------------------

func (sh *Shell) cmdRoms(args []string) {
	if sh.Machine == nil || sh.Machine.DB == nil {
		fmt.Fprintln(sh.Out, "Error: SQLite database is not connected.")
		return
	}

	if len(args) == 0 || strings.ToLower(args[0]) == "list" {
		catFilter := ""
		modelFilter := ""
		if len(args) > 1 && strings.ToLower(args[0]) == "list" {
			catFilter = args[1]
			if len(args) > 2 {
				modelFilter = args[2]
			}
		} else if len(args) == 1 && strings.ToLower(args[0]) != "list" {
			catFilter = args[0]
		}
		sh.cmdRomsList(catFilter, modelFilter)
		return
	}

	sub := strings.ToLower(args[0])
	subArgs := args[1:]

	switch sub {
	case "info":
		sh.cmdRomsInfo(subArgs)
	case "add":
		sh.cmdRomsAdd(subArgs)
	case "default", "def", "select":
		sh.cmdRomsDefault(subArgs)
	case "del", "delete", "rm":
		sh.cmdRomsDelete(subArgs)
	case "export":
		sh.cmdRomsExport(subArgs)
	case "verify":
		sh.cmdRomsVerify()
	default:
		fmt.Fprintf(sh.Out, "Unknown roms subcommand: %q.\n", sub)
		fmt.Fprintln(sh.Out, "Usage:")
		fmt.Fprintln(sh.Out, "  roms [list] [category] [model]       - List catalog ROMs")
		fmt.Fprintln(sh.Out, "  roms info <name>                     - Show detailed ROM metadata")
		fmt.Fprintln(sh.Out, "  roms add <file> <cat> <model> [name] - Register new ROM into SQLite catalog")
		fmt.Fprintln(sh.Out, "  roms default <name>                  - Set active default for category/model")
		fmt.Fprintln(sh.Out, "  roms del <name> [--force]            - Remove ROM from catalog")
		fmt.Fprintln(sh.Out, "  roms export <name> <destpath>        - Export ROM binary to file")
		fmt.Fprintln(sh.Out, "  roms verify                          - Verify SHA-1 & BLOB integrity")
	}
}

func (sh *Shell) cmdRomsList(catFilter, modelFilter string) {
	list, err := sh.Machine.DB.ListCatalog(catFilter, modelFilter)
	if err != nil {
		fmt.Fprintf(sh.Out, "Error querying catalog: %v\n", err)
		return
	}
	if len(list) == 0 {
		fmt.Fprintln(sh.Out, "No ROMs found in catalog matching filters.")
		return
	}

	fmt.Fprintln(sh.Out, "=========================================================================================")
	fmt.Fprintln(sh.Out, "  NAME            CAT        MODEL   SIZE (KB)   FLAGS       TITLE")
	fmt.Fprintln(sh.Out, "=========================================================================================")
	verifiedCount := 0
	for _, item := range list {
		defStr := "   "
		if item.IsDefault {
			defStr = "DEF"
		}
		verStr := "   "
		if item.IsVerified {
			verStr = "VER"
			verifiedCount++
		}
		flags := fmt.Sprintf("[%s][%s]", defStr, verStr)

		marker := "  "
		if item.IsDefault {
			marker = "* "
		}
		sizeKB := fmt.Sprintf("%d KB", item.Size/1024)
		if item.Size < 1024 {
			sizeKB = fmt.Sprintf("%d B", item.Size)
		}
		fmt.Fprintf(sh.Out, "%s%-15s %-10s %-7s %-11s %-11s %s\n",
			marker, item.Name, item.Category, item.MachineModel, sizeKB, flags, item.Title)
	}
	fmt.Fprintln(sh.Out, "-----------------------------------------------------------------------------------------")
	fmt.Fprintln(sh.Out, "Flags: [DEF] Active Default | [VER] Guaranteed Execution (Garantida de Execucao)")
	fmt.Fprintf(sh.Out, "Total: %d ROM(s) | Official fMSX Verified: %d\n", len(list), verifiedCount)
}

func (sh *Shell) cmdRomsInfo(args []string) {
	if len(args) == 0 {
		fmt.Fprintln(sh.Out, "Usage: roms info <name>")
		return
	}
	name := args[0]
	item, err := sh.Machine.DB.GetCatalogItem(name)
	if err != nil {
		fmt.Fprintf(sh.Out, "ROM %q not found in catalog: %v\n", name, err)
		return
	}

	fmt.Fprintln(sh.Out)
	fmt.Fprintf(sh.Out, "ROM Catalog Record: %s\n", item.Name)
	fmt.Fprintln(sh.Out, "-----------------------------------------------------------------")
	fmt.Fprintf(sh.Out, "Title        : %s\n", item.Title)
	fmt.Fprintf(sh.Out, "Category     : %s\n", item.Category)
	fmt.Fprintf(sh.Out, "Model Target : %s\n", item.MachineModel)
	fmt.Fprintf(sh.Out, "File Size    : %d bytes (%d KB)\n", item.Size, item.Size/1024)
	fmt.Fprintf(sh.Out, "SHA-1 Hash   : %s\n", item.SHA1)
	status := ""
	if item.IsDefault {
		status += "[DEF] Active Default  "
	}
	if item.IsVerified {
		status += "[VER] Guaranteed Execution (fMSX Official)"
	}
	if status == "" {
		status = "User Custom ROM"
	}
	fmt.Fprintf(sh.Out, "Status       : %s\n", status)
	if item.Description != "" {
		fmt.Fprintf(sh.Out, "Description  : %s\n", item.Description)
	}
	if item.CreatedAt != "" {
		fmt.Fprintf(sh.Out, "Registered   : %s\n", item.CreatedAt)
	}
	fmt.Fprintln(sh.Out)
}

func (sh *Shell) cmdRomsAdd(args []string) {
	if len(args) < 3 {
		fmt.Fprintln(sh.Out, "Usage: roms add <file_path> <category> <model> [name] [title] [description]")
		fmt.Fprintln(sh.Out, "Categories: bios, basic, subrom, disk, hardware, cartridge")
		fmt.Fprintln(sh.Out, "Models    : MSX1, MSX2, MSX2+, ALL")
		return
	}

	filePath := args[0]
	cat := strings.ToLower(args[1])
	model := strings.ToUpper(args[2])

	data, err := os.ReadFile(filePath)
	if err != nil {
		fmt.Fprintf(sh.Out, "Failed to read file %q: %v\n", filePath, err)
		return
	}

	name := filepath.Base(filePath)
	if len(args) >= 4 && strings.TrimSpace(args[3]) != "" {
		name = args[3]
	}

	title := name
	if len(args) >= 5 && strings.TrimSpace(args[4]) != "" {
		title = args[4]
	}

	desc := ""
	if len(args) >= 6 {
		desc = strings.Join(args[5:], " ")
	}

	h := sha1.Sum(data)
	sha1Str := fmt.Sprintf("%x", h)

	item := storage.ROMCatalogItem{
		Name:         name,
		Title:        title,
		Category:     cat,
		MachineModel: model,
		Size:         len(data),
		SHA1:         sha1Str,
		Description:  desc,
		IsDefault:    false,
		IsVerified:   false,
	}

	if err := sh.Machine.DB.StoreCatalogROM(item, data); err != nil {
		fmt.Fprintf(sh.Out, "Failed to store ROM in catalog: %v\n", err)
		return
	}

	fmt.Fprintf(sh.Out, "Successfully registered ROM %q into SQLite catalog!\n", name)
	fmt.Fprintf(sh.Out, "  Category: %s | Model: %s | Size: %d bytes | SHA1: %s\n", cat, model, len(data), sha1Str)
	fmt.Fprintf(sh.Out, "  Use 'roms default %s' to activate as default for this category/model.\n", name)
}

func (sh *Shell) cmdRomsDefault(args []string) {
	if len(args) == 0 {
		fmt.Fprintln(sh.Out, "Usage: roms default <name>")
		return
	}
	name := args[0]
	item, err := sh.Machine.DB.GetCatalogItem(name)
	if err != nil {
		fmt.Fprintf(sh.Out, "ROM %q not found in catalog: %v\n", name, err)
		return
	}

	if err := sh.Machine.DB.SetCatalogDefault(name); err != nil {
		fmt.Fprintf(sh.Out, "Failed to set default: %v\n", err)
		return
	}

	fmt.Fprintf(sh.Out, "ROM %q (%s) is now the active default for category %q (Model: %s).\n",
		name, item.Title, item.Category, item.MachineModel)
}

func (sh *Shell) cmdRomsDelete(args []string) {
	if len(args) == 0 {
		fmt.Fprintln(sh.Out, "Usage: roms del <name> [--force]")
		return
	}
	name := args[0]
	force := false
	if len(args) > 1 && (args[1] == "--force" || args[1] == "-f") {
		force = true
	}

	if err := sh.Machine.DB.DeleteCatalogROM(name, force); err != nil {
		fmt.Fprintf(sh.Out, "Cannot delete ROM: %v\n", err)
		return
	}

	fmt.Fprintf(sh.Out, "ROM %q removed from catalog.\n", name)
}

func (sh *Shell) cmdRomsExport(args []string) {
	if len(args) < 2 {
		fmt.Fprintln(sh.Out, "Usage: roms export <name> <output_path>")
		return
	}
	name := args[0]
	destPath := args[1]

	data, err := sh.Machine.DB.GetCatalogData(name)
	if err != nil {
		fmt.Fprintf(sh.Out, "ROM %q not found or has no binary data: %v\n", name, err)
		return
	}

	if err := os.WriteFile(destPath, data, 0644); err != nil {
		fmt.Fprintf(sh.Out, "Failed to write file %q: %v\n", destPath, err)
		return
	}

	fmt.Fprintf(sh.Out, "Exported ROM %q (%d bytes) to %q successfully.\n", name, len(data), destPath)
}

func (sh *Shell) cmdRomsVerify() {
	list, err := sh.Machine.DB.ListCatalog("", "")
	if err != nil {
		fmt.Fprintf(sh.Out, "Catalog query error: %v\n", err)
		return
	}

	fmt.Fprintln(sh.Out, "Verifying SQLite ROM Catalog integrity...")
	fmt.Fprintln(sh.Out, "-----------------------------------------------------------------")
	allOK := true
	for _, item := range list {
		data, err := sh.Machine.DB.GetCatalogData(item.Name)
		if err != nil || len(data) == 0 {
			fmt.Fprintf(sh.Out, "[FAIL] %-14s: Missing or empty BLOB data!\n", item.Name)
			allOK = false
			continue
		}
		h := sha1.Sum(data)
		calcSHA1 := fmt.Sprintf("%x", h)
		if item.SHA1 != "" && calcSHA1 != item.SHA1 {
			fmt.Fprintf(sh.Out, "[FAIL] %-14s: SHA-1 mismatch! (DB: %s, Data: %s)\n", item.Name, item.SHA1, calcSHA1)
			allOK = false
			continue
		}
		verLabel := "CUSTOM"
		if item.IsVerified {
			verLabel = "GUARANTEED (fMSX)"
		}
		defLabel := ""
		if item.IsDefault {
			defLabel = " [DEFAULT]"
		}
		fmt.Fprintf(sh.Out, "[ OK ] %-14s (%6d bytes) -> %s%s\n", item.Name, len(data), verLabel, defLabel)
	}
	fmt.Fprintln(sh.Out, "-----------------------------------------------------------------")
	if allOK {
		fmt.Fprintln(sh.Out, "All catalog ROMs passed SHA-1 and BLOB integrity checks.")
	} else {
		fmt.Fprintln(sh.Out, "Warning: Some catalog entries had integrity issues.")
	}
}

// cmdLoadDSK mounts a .DSK disk image into virtual floppy drive A: (or B:).
// If an argument is provided, attempts to load directly without opening the browser.
// If no argument is provided, launches the interactive TUI file browser.
func (sh *Shell) cmdLoadDSK(args []string) {
	var filePath string
	drive := 0

	// Check if drive ID was specified, e.g. "loaddsk b game.dsk" or "loaddsk 1 game.dsk"
	if len(args) >= 2 && (strings.EqualFold(args[0], "b") || args[0] == "1") {
		drive = 1
		args = args[1:]
	} else if len(args) >= 2 && (strings.EqualFold(args[0], "a") || args[0] == "0") {
		drive = 0
		args = args[1:]
	}

	if len(args) > 0 {
		// 1. Direct path passed on command line -> load directly without opening browser
		filePath = strings.Trim(strings.Join(args, " "), "\"' ")
	} else {
		// 2. No argument given -> open interactive TUI file browser
		opts := tui.FilePickerOptions{
			Title:        "Select MSX Disk Image (.DSK)",
			Extensions:   []string{".dsk", ".di1", ".di2", ".img"},
			StartPath:    sh.LastPath,
			FilterActive: true,
			In:           sh.In,
			Out:          sh.Out,
		}

		selected, err := tui.OpenFilePicker(opts)
		if err != nil {
			if errors.Is(err, tui.ErrCancelled) {
				fmt.Fprintln(sh.Out, "Disk selection cancelled.")
				return
			}
			if errors.Is(err, tui.ErrNonInteractive) {
				fmt.Fprintln(sh.Out, "Usage: loaddsk <path_to_disk.dsk>")
				fmt.Fprintln(sh.Out, "Note: Interactive file browser requires a terminal (TTY).")
				return
			}
			fmt.Fprintf(sh.Out, "Error in file browser: %v\n", err)
			return
		}
		filePath = selected
	}

	if filePath == "" {
		fmt.Fprintln(sh.Out, "No disk file specified.")
		return
	}

	resolvedPath, err := sh.resolveDiskPath(filePath)
	if err != nil {
		fmt.Fprintf(sh.Out, "Error: %v\n", err)
		return
	}

	err = sh.Machine.LoadDisk(drive, resolvedPath)
	if err != nil {
		fmt.Fprintf(sh.Out, "Failed to load disk into Drive %c:: %v\n", 'A'+drive, err)
		return
	}

	sh.LastPath = filepath.Dir(resolvedPath)
	sh.LastDiskDrive = drive
	sh.LastSector = 0

	fdd := sh.Machine.FDD[drive]
	formatDesc := detectDiskFormat(fdd.Data)

	driveLetter := 'A' + drive
	fmt.Fprintln(sh.Out, "-----------------------------------------------------------------")
	fmt.Fprintf(sh.Out, "  MSX Floppy Drive %c: Mounted Successfully\n", driveLetter)
	fmt.Fprintln(sh.Out, "-----------------------------------------------------------------")
	fmt.Fprintf(sh.Out, "  File:         %s\n", filepath.Base(resolvedPath))
	fmt.Fprintf(sh.Out, "  Full Path:    %s\n", resolvedPath)
	fmt.Fprintf(sh.Out, "  Size:         %s (%d bytes)\n", tui.FormatFileSize(int64(len(fdd.Data))), len(fdd.Data))
	fmt.Fprintf(sh.Out, "  Sectors:      %d sectors (%d bytes/sector)\n", fdd.Sectors, fdd.SecSize)
	fmt.Fprintf(sh.Out, "  Format:       %s\n", formatDesc)
	fmt.Fprintf(sh.Out, "  Memory State: Mounted in host RAM / Virtual FDD %d (Drive %c:)\n", drive, driveLetter)
	fmt.Fprintln(sh.Out, "  Ready for sector operations.")
	fmt.Fprintln(sh.Out, "-----------------------------------------------------------------")
}

func (sh *Shell) resolveDiskPath(path string) (string, error) {
	// 1. Direct absolute or relative path
	abs, err := filepath.Abs(path)
	if err == nil {
		if fi, err := os.Stat(abs); err == nil && !fi.IsDir() {
			return abs, nil
		}
	}

	// 2. Relative to LastPath
	if sh.LastPath != "" {
		cand := filepath.Join(sh.LastPath, path)
		if fi, err := os.Stat(cand); err == nil && !fi.IsDir() {
			return filepath.Abs(cand)
		}
	}

	// 3. In ./media or ./disks subdirectory
	cand := filepath.Join("media", path)
	if fi, err := os.Stat(cand); err == nil && !fi.IsDir() {
		return filepath.Abs(cand)
	}
	cand = filepath.Join("disks", path)
	if fi, err := os.Stat(cand); err == nil && !fi.IsDir() {
		return filepath.Abs(cand)
	}

	// 4. Try appending .dsk if missing
	if !strings.HasSuffix(strings.ToLower(path), ".dsk") {
		return sh.resolveDiskPath(path + ".dsk")
	}

	return "", fmt.Errorf("disk file %q not found", path)
}

func detectDiskFormat(data []byte) string {
	if len(data) < 512 {
		return fmt.Sprintf("%d bytes", len(data))
	}

	media := data[0x15]
	switch media {
	case 0xF8:
		return "3.5\" 720KB (2 sides, 80 tracks, 9 sectors/track)"
	case 0xF9:
		return "3.5\" 720KB (2 sides, 80 tracks, 9 sectors/track, 512B)"
	case 0xFA:
		return "3.5\" 320KB/640KB (8 sectors/track)"
	case 0xFB:
		return "3.5\" 640KB (2 sides, 80 tracks, 8 sectors/track)"
	case 0xFC:
		return "5.25\" 180KB/360KB (1 side, 40 tracks, 9 sectors/track)"
	case 0xFD:
		return "5.25\" 360KB (2 sides, 40 tracks, 9 sectors/track)"
	case 0xFE:
		return "5.25\" 160KB (1 side, 40 tracks, 8 sectors/track)"
	case 0xFF:
		return "5.25\" 320KB (2 sides, 40 tracks, 8 sectors/track)"
	default:
		sectors := len(data) / 512
		kb := len(data) / 1024
		return fmt.Sprintf("Custom %d KB (%d sectors, media ID %02Xh)", kb, sectors, media)
	}
}

func (sh *Shell) cmdModel(args []string) {
	if len(args) == 0 {
		fmt.Fprintf(sh.Out, "Current Model: %s (VDP: %s)\n", sh.modelName(), sh.Machine.VDPChipName())
		fmt.Fprintf(sh.Out, "RAM: %d KB (%d pages) | VRAM: %d KB (%d pages)\n",
			sh.Machine.Config.RAMPages*16, sh.Machine.Config.RAMPages,
			sh.Machine.Config.VRAMPages*16, sh.Machine.Config.VRAMPages)
		fmt.Fprintf(sh.Out, "Mapped ROMs: %s\n", strings.Join(sh.Machine.CurrentROMs(), ", "))
		fmt.Fprintln(sh.Out, "Available models: msx1, msx2, msx2+")
		fmt.Fprintln(sh.Out, "Usage: model <msx1|msx2|msx2+> or 'model select' for interactive TUI menu")
		return
	}

	argJoined := strings.ToLower(strings.Join(args, " "))
	target := strings.ToLower(args[0])

	if target == "select" || target == "menu" || target == "tui" || target == "choose" {
		chosen, err := tui.SelectMachineModel(tui.ModelPickerOptions{
			CurrentModel: sh.Machine.Config.Model,
			In:           sh.In,
			Out:          sh.Out,
		})
		if err != nil {
			if errors.Is(err, tui.ErrCancelled) {
				fmt.Fprintln(sh.Out, "Model selection cancelled.")
				return
			}
			fmt.Fprintf(sh.Out, "TUI selection error: %v\n", err)
			return
		}
		if err := sh.Machine.SwitchModel(chosen); err != nil {
			fmt.Fprintf(sh.Out, "Failed to switch model: %v\n", err)
			return
		}
		fmt.Fprintf(sh.Out, "%s %s (%s). ROMs: %s\n",
			i18n.T("cli_model_changed"), sh.modelName(), sh.Machine.VDPChipName(),
			strings.Join(sh.Machine.CurrentROMs(), ", "))
		return
	}

	var targetModel int
	switch {
	case target == "msx1" || target == "1" || argJoined == "msx 1":
		targetModel = msx.ModelMSX1
	case target == "msx2" || target == "2" || argJoined == "msx 2":
		targetModel = msx.ModelMSX2
	case target == "msx2+" || target == "msx2p" || target == "2+" || target == "2p" || target == "3" || argJoined == "msx 2+":
		targetModel = msx.ModelMSX2P
	default:
		fmt.Fprintf(sh.Out, "Unknown model %q. Valid options: msx1, msx2, msx2+, or 'model select'\n", strings.Join(args, " "))
		return
	}

	if err := sh.Machine.SwitchModel(targetModel); err != nil {
		fmt.Fprintf(sh.Out, "Failed to switch model: %v\n", err)
		return
	}

	fmt.Fprintf(sh.Out, "%s %s (%s). ROMs: %s\n",
		i18n.T("cli_model_changed"), sh.modelName(), sh.Machine.VDPChipName(),
		strings.Join(sh.Machine.CurrentROMs(), ", "))
}

func (sh *Shell) cmdSaveSTA(args []string) {
	filename := "DEFAULT.STA"
	if len(args) > 0 {
		filename = args[0]
	}
	if !strings.HasSuffix(strings.ToUpper(filename), ".STA") {
		filename += ".STA"
	}
	err := sh.Machine.SaveSTA(filename)
	if err != nil {
		fmt.Fprintf(sh.Out, "Error saving state to %s: %v\n", filename, err)
		return
	}
	fmt.Fprintf(sh.Out, "State successfully saved to %s (%s, RAM: %d KB, VRAM: %d KB)\n",
		filename, sh.modelName(), sh.Machine.Config.RAMPages*16, sh.Machine.Config.VRAMPages*16)
}

func (sh *Shell) cmdLoadSTA(args []string) {
	filename := "DEFAULT.STA"
	if len(args) > 0 {
		filename = args[0]
	}
	if !strings.HasSuffix(strings.ToUpper(filename), ".STA") {
		filename += ".STA"
	}
	err := sh.Machine.LoadSTA(filename)
	if err != nil {
		fmt.Fprintf(sh.Out, "Error loading state from %s: %v\n", filename, err)
		return
	}
	fmt.Fprintf(sh.Out, "State successfully loaded from %s (%s, RAM: %d KB, VRAM: %d KB, PC=%04Xh)\n",
		filename, sh.modelName(), sh.Machine.Config.RAMPages*16, sh.Machine.Config.VRAMPages*16, sh.Machine.CPU.PC)
}

func (sh *Shell) cmdFDC(args []string) {
	fdc := sh.Machine.FDC
	if len(args) > 0 {
		sub := strings.ToLower(args[0])
		if sub == "bdos" || sub == "fast" {
			sh.Machine.Config.SimulateBDOS = true
			fmt.Fprintln(sh.Out, "FDC mode: BDOS high-speed simulation enabled (MSX-DOS fast disk).")
			return
		} else if sub == "wd1793" || sub == "wd2793" || sub == "low" || sub == "hw" {
			sh.Machine.Config.SimulateBDOS = false
			fmt.Fprintln(sh.Out, "FDC mode: Low-level WD2793 register emulation enabled (raw floppy).")
			return
		}
	}

	modeStr := "WD2793 Low-Level Register Emulation"
	if sh.Machine.Config.SimulateBDOS {
		modeStr = "BDOS High-Speed BIOS Trap Simulation (WD2793 fallback)"
	}
	fmt.Fprintf(sh.Out, "WD2793 FDC Status [%s]:\n", modeStr)
	if fdc == nil {
		fmt.Fprintln(sh.Out, "  FDC not initialized.")
		return
	}
	fmt.Fprintf(sh.Out, "  Drive: %c: (Drive=%d, Side=%d)\n", 'A'+fdc.Drive, fdc.Drive, fdc.Side)
	fmt.Fprintf(sh.Out, "  Registers: CMD/STATUS=%02Xh TRACK=%02Xh SECTOR=%02Xh DATA=%02Xh\n",
		fdc.R[0], fdc.R[1], fdc.R[2], fdc.R[3])
	fmt.Fprintf(sh.Out, "  Head Track: Drive 0: %d | Drive 1: %d | Drive 2: %d | Drive 3: %d\n",
		fdc.Track[0], fdc.Track[1], fdc.Track[2], fdc.Track[3])
	irqPending := (fdc.IRQ & 0x80) != 0
	drqPending := (fdc.IRQ & 0x40) != 0
	fmt.Fprintf(sh.Out, "  Flags: IRQ=%v DRQ=%v SysReg(R4)=%02Xh LastCmd=%02Xh\n",
		irqPending, drqPending, fdc.R[4], fdc.Cmd)
	fmt.Fprintln(sh.Out, "Usage: fdc [bdos|wd1793] to switch floppy emulation mode.")
}



