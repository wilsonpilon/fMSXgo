package shell

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"

	"fmsxgo/pkg/cpu/z80"
	"fmsxgo/pkg/msx"
)

// Shell provides an interactive CLI monitor ("Developer OS") for fMSXgo.
type Shell struct {
	Machine     *msx.Machine
	Breakpoints map[uint16]bool
	LastDump    uint16
	LastDasm    uint16
	In          io.Reader
	Out         io.Writer
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

	switch cmd {
	case "exit", "quit", "q":
		fmt.Fprintln(sh.Out, "Exiting fMSXgo...")
		return true

	case "help", "?":
		sh.cmdHelp()

	case "r", "reg", "regs":
		if len(args) == 0 {
			sh.cmdRegs()
		} else if len(args) >= 2 {
			sh.cmdSetReg(args[0], args[1])
		} else {
			fmt.Fprintln(sh.Out, "Usage: r (view registers) or r <reg> <val> (set register)")
		}

	case "d", "dump":
		sh.cmdDump(args)

	case "e", "enter":
		sh.cmdEnter(args)

	case "u", "dasm":
		sh.cmdDasm(args)

	case "a", "asm":
		sh.cmdAsm(args)

	case "t", "step":
		sh.cmdStep(args)

	case "p", "next":
		sh.cmdNext()

	case "g", "run":
		sh.cmdRun(args)

	case "bp", "break":
		sh.cmdBreakpoint(args)

	case "slots":
		sh.cmdSlots()

	case "mapper":
		sh.cmdMapper()

	case "in":
		sh.cmdIn(args)

	case "out":
		sh.cmdOut(args)

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
	fmt.Fprintln(sh.Out, "       fMSXgo - MSX Emulator & Developer / Hacker Console       ")
	fmt.Fprintln(sh.Out, "       (C) Marat Fayzullin (fMSX core) | Go Port: Wilson Pilon  ")
	fmt.Fprintln(sh.Out, "================================================================")
	fmt.Fprintf(sh.Out, "Model: %s | Video: %s | RAM: %d KB | CPU PC: %04Xh\n",
		sh.modelName(), sh.videoName(), sh.Machine.Config.RAMPages*16, sh.Machine.CPU.PC)
	fmt.Fprintln(sh.Out, "Type 'help' for commands, 'a' for mini-assembler, 't' to step.")
	fmt.Fprintln(sh.Out, "----------------------------------------------------------------")
}

func (sh *Shell) modelName() string {
	switch sh.Machine.Config.Model {
	case msx.ModelMSX1:
		return "MSX 1"
	case msx.ModelMSX2:
		return "MSX 2"
	case msx.ModelMSX2P:
		return "MSX 2+"
	default:
		return "Unknown"
	}
}

func (sh *Shell) videoName() string {
	if sh.Machine.Config.Video == msx.VideoPAL {
		return "PAL (50Hz)"
	}
	return "NTSC (60Hz)"
}

func (sh *Shell) cmdHelp() {
	helpText := `
fMSXgo CLI Commands:
-----------------------------------------------------------------
Main Controls:
  HELP                      Display this command summary and help
  QUIT / EXIT               Exit fMSXgo

Registers & CPU:
  r                         View all registers, flags, and instruction at PC
  r <reg> <val>             Set register value (e.g. 'r a 0xFF', 'r pc 0xC000')

Memory Inspection & Editing:
  d [addr] [len]            Hexdump and ASCII memory display (default 64 bytes)
  e <addr> <b0> [b1...]     Enter raw hex bytes into memory (e.g. 'e C000 3E 42')

Disassembly & Assembly:
  u [addr] [count]          Disassemble instructions (default 10)
  a <addr>                  Enter interactive line-by-line mini-assembler mode
  a <addr> <instruction>    Assemble a single instruction into memory

Execution & Debugging:
  t [n]                     Trace / step n instructions (default 1)
  p                         Step over (CALL/RST/DJNZ)
  g [addr]                  Run execution until breakpoint or halt
  bp                        List active breakpoints
  bp add <addr>             Add breakpoint at address
  bp del <addr>             Delete breakpoint at address
  bp clear                  Remove all breakpoints

MSX Hardware & Slots:
  slots                     Inspect primary/secondary slot allocations & pages
  mapper                    Inspect RAM mapper state & bank allocations
  in <port>                 Read byte from I/O port (hex)
  out <port> <val>          Write byte to I/O port (hex)
  info                      Display machine hardware configuration
  reset                     Reset CPU and MSX hardware
  cls                       Clear console screen
  quit / exit               Exit fMSXgo
`
	fmt.Fprint(sh.Out, helpText)
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
		fmt.Fprintf(sh.Out, "%s %04X:  %s  %s\n", prefix, addr, byteDump, dis)
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
	if len(args) == 0 {
		if len(sh.Breakpoints) == 0 {
			fmt.Fprintln(sh.Out, "No active breakpoints.")
			return
		}
		fmt.Fprintln(sh.Out, "Active Breakpoints:")
		for bp := range sh.Breakpoints {
			fmt.Fprintf(sh.Out, "  - %04Xh\n", bp)
		}
		return
	}

	sub := strings.ToLower(args[0])
	switch sub {
	case "add":
		if len(args) < 2 {
			fmt.Fprintln(sh.Out, "Usage: bp add <addr>")
			return
		}
		v, err := parseHex(args[1])
		if err != nil {
			fmt.Fprintf(sh.Out, "Invalid address: %s\n", args[1])
			return
		}
		sh.Breakpoints[uint16(v)] = true
		fmt.Fprintf(sh.Out, "Breakpoint added at %04Xh\n", uint16(v))

	case "del", "delete", "rm":
		if len(args) < 2 {
			fmt.Fprintln(sh.Out, "Usage: bp del <addr>")
			return
		}
		v, err := parseHex(args[1])
		if err != nil {
			fmt.Fprintf(sh.Out, "Invalid address: %s\n", args[1])
			return
		}
		delete(sh.Breakpoints, uint16(v))
		fmt.Fprintf(sh.Out, "Breakpoint removed at %04Xh\n", uint16(v))

	case "clear":
		sh.Breakpoints = make(map[uint16]bool)
		fmt.Fprintln(sh.Out, "All breakpoints cleared.")
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

func parseHex(s string) (uint64, error) {
	s = strings.TrimSpace(s)
	if strings.HasPrefix(s, "$") {
		return strconv.ParseUint(s[1:], 16, 64)
	}
	if strings.HasPrefix(strings.ToLower(s), "0x") {
		return strconv.ParseUint(s[2:], 16, 64)
	}
	if strings.HasSuffix(strings.ToLower(s), "h") {
		return strconv.ParseUint(s[:len(s)-1], 16, 64)
	}
	if len(s) > 1 && (strings.HasSuffix(s, "d") || strings.HasSuffix(s, "D")) {
		pre := s[:len(s)-1]
		if isDigits(pre) {
			return strconv.ParseUint(pre, 10, 64)
		}
	}
	if strings.HasPrefix(s, "#") {
		return strconv.ParseUint(s[1:], 10, 64)
	}
	// In low-level MSX debuggers and monitors, default number base is hex
	return strconv.ParseUint(s, 16, 64)
}

func isDigits(s string) bool {
	for _, c := range s {
		if c < '0' || c > '9' {
			return false
		}
	}
	return len(s) > 0
}
