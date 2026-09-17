package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"fmsxgo/pkg/i18n"
	"fmsxgo/pkg/msx"
	"fmsxgo/pkg/shell"
	"fmsxgo/pkg/storage"
	"fmsxgo/pkg/ui"
)

var (
	// Version follows V X.Y.Z scheme with creative Heavy Metal / Horror codenames
	Version  = "0.1.0"
	Codename = "Phantasm"
)

func printUsage() {
	usage := fmt.Sprintf(`fMSXgo - MSX Emulator & Developer Workstation (64-bit)
Version: %s (%s)
Based on fMSX (C) Marat Fayzullin | Go Port by Wilson Pilon

Usage:
  fmsxgo [options] [cartridge.rom]

Primary Options:
  --help, -help, -h   Show this help message and exit
  --no-window         Disable graphical window and run in interactive CLI monitor mode
  --lang <code>       Set UI language (en, pt, es, nl, fr, ja; default: en)
  --db <path>         Path to SQLite database file (default: fmsxgo.db)

Hardware Options (fMSX compatible):
  -msx1               Emulate MSX1 (TMS9918 VDP)
  -msx2               Emulate MSX2 (V9938 VDP, default)
  -msx2+              Emulate MSX2+ (V9958 VDP)
  -pal                Use PAL video timing (50Hz)
  -ntsc               Use NTSC video timing (60Hz, default)
  -ram <pages>        RAM size in 16KB pages (default: 8 = 128KB)
  -vram <pages>       VRAM size in 64KB pages (default: 2 = 128KB)
  -rom <file>         Insert cartridge in Slot 1
  -carta <file>       Insert cartridge in Slot 1
  -cartb <file>       Insert cartridge in Slot 2
  -diska <file>       Insert disk image in Drive A:
  -diskb <file>       Insert disk image in Drive B:
  -romdir <dir>       Custom directory to search for BIOS ROMs

Developer & CLI Options:
  -cli                Alias for --no-window (starts developer shell)
  -exec "<cmds>"      Execute semicolon-separated commands in batch mode
  -test               Run internal self-tests

Examples:
  fmsxgo                           (launches graphical interface with File and Help menus)
  fmsxgo --no-window               (launches interactive CLI developer shell)
  fmsxgo -msx2 -rom game.rom
  fmsxgo --no-window -exec "a C000 LD A, 2Ah; a C002 HALT; r pc C000; t 1; r"
`, Version, Codename)
	fmt.Print(usage)
}

func main() {
	cfg := msx.DefaultConfig()
	noWindow := false
	execBatch := ""
	runTests := false
	dbPath := "fmsxgo.db"
	langFlag := ""

	args := os.Args[1:]
	for i := 0; i < len(args); i++ {
		arg := args[i]
		switch strings.ToLower(arg) {
		case "--help", "-help", "-h", "/?":
			printUsage()
			return

		case "--no-window", "-no-window", "--cli", "-cli":
			noWindow = true

		case "--lang", "-lang":
			if i+1 < len(args) {
				i++
				langFlag = args[i]
			}

		case "--db", "-db":
			if i+1 < len(args) {
				i++
				dbPath = args[i]
			}

		case "-msx1":
			cfg.Model = msx.ModelMSX1
		case "-msx2":
			cfg.Model = msx.ModelMSX2
		case "-msx2+":
			cfg.Model = msx.ModelMSX2P

		case "-pal":
			cfg.Video = msx.VideoPAL
		case "-ntsc":
			cfg.Video = msx.VideoNTSC

		case "-ram":
			if i+1 < len(args) {
				i++
				if v, err := strconv.Atoi(args[i]); err == nil {
					cfg.RAMPages = v
				}
			}
		case "-vram":
			if i+1 < len(args) {
				i++
				if v, err := strconv.Atoi(args[i]); err == nil {
					cfg.VRAMPages = v
				}
			}

		case "-rom", "-carta":
			if i+1 < len(args) {
				i++
				cfg.CartAPath = args[i]
			}
		case "-cartb":
			if i+1 < len(args) {
				i++
				cfg.CartBPath = args[i]
			}
		case "-diska":
			if i+1 < len(args) {
				i++
				cfg.DiskAPath = args[i]
			}
		case "-diskb":
			if i+1 < len(args) {
				i++
				cfg.DiskBPath = args[i]
			}
		case "-romdir":
			if i+1 < len(args) {
				i++
				cfg.ROMDir = args[i]
			}

		case "-exec":
			if i+1 < len(args) {
				i++
				execBatch = args[i]
				noWindow = true
			}
		case "-test":
			runTests = true

		default:
			// If not a flag, treat as ROM path
			if !strings.HasPrefix(arg, "-") && cfg.CartAPath == "" {
				cfg.CartAPath = arg
			} else {
				fmt.Fprintf(os.Stderr, "Unknown option: %s (type --help for help)\n", arg)
			}
		}
	}

	// 1. Initialize SQLite Database (stores configs, manuals, and ROMs in BLOBs)
	db, err := storage.Open(dbPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Warning: Could not open SQLite database at %s: %v\n", dbPath, err)
	} else {
		defer db.Close()
		cfg.DB = db

		// Auto-seed ROMs from third-party/fMSX/ROMs or ROMs if DB is empty
		if !db.HasROM("MSX2.ROM") {
			seedPaths := []string{
				"ROMs",
				filepath.Join("third-party", "fMSX", "ROMs"),
			}
			for _, p := range seedPaths {
				if fi, err := os.Stat(p); err == nil && fi.IsDir() {
					db.SeedFromROMDir(p)
				}
			}
		}

		// Store version into config
		_ = db.SetConfig("version", Version)
		_ = db.SetConfig("codename", Codename)

		// Initialize UI language
		if langFlag != "" {
			if i18n.SetLanguage(langFlag) {
				_ = db.SetConfig("language", i18n.GetLanguage())
			} else {
				fmt.Fprintf(os.Stderr, "Warning: Unsupported language code %q. Defaulting to %s.\n", langFlag, i18n.GetLanguage())
			}
		} else {
			savedLang := db.GetConfig("language", "en")
			i18n.SetLanguage(savedLang)
		}
	}

	// Fallback if DB was not loaded but --lang was specified
	if db == nil && langFlag != "" {
		i18n.SetLanguage(langFlag)
	}

	if runTests {
		fmt.Println("Running fMSXgo self-diagnostics...")
		machine, err := msx.NewMachine(cfg)
		if err != nil {
			fmt.Printf("Self-test FAILED: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Self-test PASSED: Machine %s initialized. PC=%04Xh\n",
			cfgModelName(machine.Config.Model), machine.CPU.PC)
		return
	}

	// 2. Initialize the MSX Machine
	machine, err := msx.NewMachine(cfg)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error initializing MSX machine: %v\n", err)
		fmt.Fprintf(os.Stderr, "Hint: Verify that fmsxgo.db exists or ROMs are in 'third-party/fMSX/ROMs/'.\n")
		os.Exit(1)
	}

	// 3. Batch execution mode
	if execBatch != "" {
		sh := shell.New(machine, os.Stdin, os.Stdout)
		commands := strings.Split(execBatch, ";")
		for _, cmd := range commands {
			cmd = strings.TrimSpace(cmd)
			if cmd != "" {
				fmt.Printf("fMSXgo [Batch]> %s\n", cmd)
				if sh.ExecuteCommand(cmd) {
					break
				}
			}
		}
		return
	}

	// 4. CLI mode if --no-window was specified
	if noWindow {
		sh := shell.New(machine, os.Stdin, os.Stdout)
		sh.Run()
		return
	}

	// 5. Default mode: Launch Graphical Window with File->Exit and Help->About menus
	gui := ui.New(machine)
	if err := gui.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "GUI Window closed or failed: %v. Falling back to CLI mode.\n", err)
		sh := shell.New(machine, os.Stdin, os.Stdout)
		sh.Run()
	}
}

func cfgModelName(model int) string {
	switch model {
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
