package main

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"fmsxgo/pkg/i18n"
	"fmsxgo/pkg/msx"
	"fmsxgo/pkg/shell"
	"fmsxgo/pkg/storage"
	"fmsxgo/pkg/tui"
	"fmsxgo/pkg/ui"
	"fmsxgo/pkg/ui/font"
	"fmsxgo/pkg/ui/theme"
)

var (
	// Version follows V X.Y.Z scheme with creative Heavy Metal / Horror codenames
	Version  = "0.3.0"
	Codename = "Vampire Killer"
)

func printUsage() {
	usage := fmt.Sprintf(`fMSXgo - MSX Emulator & Developer Workstation (64-bit)
Version: %s (%s)
Based on fMSX (C) Marat Fayzullin | Pure Go Port by Wilson Pilon

Usage:
  fmsxgo [options] [filename1] [filename2]
  [filename1] = name of file to load as cartridge A
  [filename2] = name of file to load as cartridge B

Emulation & Hardware Options (fMSX 100%% Faithful Mirror):
  -verbose <level>    Debugging message level [1]
                        0: Silent        1: Startup messages
                        2: V9938 ops     4: Disk/Tape
                        8: Memory       16: Illegal Z80 ops
                       32: I/O
  -skip <percent>     Percentage of frames to skip [25]
  -pal / -ntsc        Set PAL (50Hz) or NTSC (60Hz) video timing [NTSC]
  -msx1 / -msx2 / -msx2+
                      Select MSX model [default: -msx2]
  -m / -model <model> Select MSX model (msx1, msx2, msx2+)
  -select-model       Launch interactive TUI model selector before emulation
  -ram <pages>        Number of 16kB RAM pages [4 for MSX1, 8 for MSX2/2+]
  -vram <pages>       Number of 16kB/64kB VRAM pages [2 for MSX1, 8 for MSX2/2+]
  -rom <type|file>    MegaROM mapper type (0..7, >7: guess) or cartridge file
                        0: Generic 8kB    1: Generic 16kB (MSXDOS2)
                        2: Konami5 8kB    3: Konami4 8kB
                        4: ASCII 8kB      5: ASCII 16kB
                        6: GameMaster2    7: FMPAC
                      (Up to two -rom options accepted for Cart A & B)
  -carta <file>       Insert cartridge in Slot 1 (alias for Cartridge A)
  -cartb <file>       Insert cartridge in Slot 2 (alias for Cartridge B)
  -diska / -fda <file>
                      Set disk image for Drive A: (supports .DSK, .IMG)
  -diskb / -fdb <file>
                      Set disk image for Drive B:
  -tape / -cas <file> Set tape image file (.CAS)
  -font / -fnt <file> Set fixed font for text modes
  -logsnd <file>      Set soundtrack log file [LOG.MID]
  -state / -sta <file>
                      Set emulation state save file
  -auto / -noauto     Use autofire on SPACE [off]
  -joy <type>         Select joystick type (0: None, 1: Normal, 2: Mouse/Joy, 3: Mouse)
                      (Up to two -joy options accepted for Port 1 & 2)
  -home / -romdir <dir>
                      Directory with system ROM files
  -simbdos            Simulate DiskROM disk access calls via PatchZ80 [default]
  -wd1793             Use WD1793 floppy controller emulation
  -sound [<quality>]  Sound emulation quality in Hz [44100]
  -nosound            Disable sound emulation (-sound 0)
  -printer / -prn <file>
                      Redirect printer output to file [stdout]
  -serial / -com <file>
                      Redirect serial I/O to a file [stdin/stdout]
  -trap <addr|now>    Trap execution when PC reaches hex address (or 'now')
  -sync <freq>        Sync screen updates to frequency [60]
  -nosync             Disable screen update syncing
  -scale <factor>     Scale window by factor [2]
  -help, --help, -h, /?
                      Show this help message and exit

fMSXgo Workstation & Developer Extensions:
  --no-window, -cli   Run in interactive CLI developer shell without GUI
  --lang <code>       UI language (en, pt, es, nl, fr; default: en)
  --theme <id>        UI theme (system, github-dark, github-light, etc.)
  --db <path>         SQLite database path (default: fmsxgo.db)
  -exec "<cmds>"      Execute semicolon-separated commands in batch mode and exit
  -test               Run internal self-diagnostics and exit

MSX Floppy Disk Manipulation Utility:
  fmsxgo disk create <disk.dsk> [format]
                      Create a formatted blank MSX disk (720KB, 360KB, 180KB)
  fmsxgo disk list <disk.dsk> [-l]
                      List files on an MSX disk image (-l for detailed view)
  fmsxgo disk add <disk.dsk> <file1> [file2 ...]
                      Add host file(s) into MSX disk image (supports wildcards)
  fmsxgo disk extract <disk.dsk> [-d out_dir] [mask ...]
                      Extract file(s) from MSX disk image (e.g. *.BAS, AUTOEXEC.BAT)
  fmsxgo disk delete <disk.dsk> <filename>
                      Delete a file from MSX disk image

Examples:
  fmsxgo                              (launches graphical emulator with menus)
  fmsxgo game.rom                     (runs cartridge A directly)
  fmsxgo -msx2 -diska disk.dsk        (boots MSX2 with floppy disk A)
  fmsxgo disk create blank.dsk 720k   (creates blank 720KB MSX disk)
  fmsxgo disk list blank.dsk -l       (shows detailed disk directory)
  fmsxgo disk add blank.dsk *.bas     (inserts BASIC files into disk)
  fmsxgo -carta game.rom -cartb scc.rom
  fmsxgo --no-window                  (starts interactive CLI monitor)
  fmsxgo -cli -exec "roms; r pc; q"   (runs batch commands in CLI)
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
	themeFlag := ""
	fontFlag := ""
	modelFlagPassed := false
	selectModelTUI := false
	ramFlagPassed := false
	vramFlagPassed := false
	scaleFlag := 0

	cartCount := 0
	romTypeCount := 0
	joyCount := 0

	args := os.Args[1:]

	// Fast-path: Subcommands (disk, model)
	if len(args) > 0 {
		first := strings.ToLower(args[0])
		if first == "disk" || first == "dsk" || first == "diskutil" {
			runDiskCLI(args[1:])
			return
		}
		if first == "model" || first == "machine" || first == "msx" {
			runModelCLI(args[1:], dbPath)
			return
		}
	}

	for i := 0; i < len(args); i++ {
		arg := args[i]
		lower := strings.ToLower(arg)
		switch lower {
		case "-dsk-create", "--disk-create":
			if i+1 < len(args) {
				subArgs := []string{"create", args[i+1]}
				i++
				if i+1 < len(args) && !strings.HasPrefix(args[i+1], "-") {
					subArgs = append(subArgs, args[i+1])
					i++
				}
				runDiskCLI(subArgs)
				return
			}
		case "-dsk-list", "--disk-list":
			if i+1 < len(args) {
				subArgs := []string{"list", args[i+1]}
				i++
				if i+1 < len(args) && (args[i+1] == "-l" || args[i+1] == "--long") {
					subArgs = append(subArgs, "-l")
					i++
				}
				runDiskCLI(subArgs)
				return
			}
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

		case "--theme", "-theme":
			if i+1 < len(args) {
				i++
				themeFlag = args[i]
			}

		case "--db", "-db":
			if i+1 < len(args) {
				i++
				dbPath = args[i]
			}

		case "-verbose":
			if i+1 < len(args) {
				i++
				if v, err := strconv.Atoi(args[i]); err == nil {
					cfg.Verbose = v
				}
			}

		case "-skip":
			if i+1 < len(args) {
				i++
				if v, err := strconv.Atoi(args[i]); err == nil {
					cfg.FrameSkip = v
				}
			}

		case "-msx1", "--msx1", "/msx1":
			cfg.Model = msx.ModelMSX1
			modelFlagPassed = true
		case "-msx2", "--msx2", "/msx2":
			cfg.Model = msx.ModelMSX2
			modelFlagPassed = true
		case "-msx2+", "--msx2+", "/msx2+", "-msx2p", "--msx2p", "/msx2p":
			cfg.Model = msx.ModelMSX2P
			modelFlagPassed = true
		case "-m", "-model", "--model", "/model", "-machine", "--machine", "/machine":
			if i+1 < len(args) {
				i++
				modelFlagPassed = true
				switch strings.ToLower(args[i]) {
				case "msx1", "1":
					cfg.Model = msx.ModelMSX1
				case "msx2", "2":
					cfg.Model = msx.ModelMSX2
				case "msx2+", "msx2p", "2+", "2p", "3":
					cfg.Model = msx.ModelMSX2P
				case "select", "menu", "tui", "choose":
					selectModelTUI = true
				}
			}
		case "-select-model", "--select-model", "-model-menu", "--model-menu", "-tui-model", "--tui-model":
			selectModelTUI = true
			modelFlagPassed = true

		case "-pal":
			cfg.Video = msx.VideoPAL
		case "-ntsc":
			cfg.Video = msx.VideoNTSC

		case "-auto":
			cfg.AutoFire = true
		case "-noauto":
			cfg.AutoFire = false

		case "-ram":
			if i+1 < len(args) {
				i++
				if v, err := strconv.Atoi(args[i]); err == nil {
					cfg.RAMPages = v
					ramFlagPassed = true
				}
			}
		case "-vram":
			if i+1 < len(args) {
				i++
				if v, err := strconv.Atoi(args[i]); err == nil {
					cfg.VRAMPages = v
					vramFlagPassed = true
				}
			}

		case "-home", "-romdir":
			if i+1 < len(args) {
				i++
				cfg.ROMDir = args[i]
			}

		case "-printer", "-prn":
			if i+1 < len(args) {
				i++
				cfg.PrinterPath = args[i]
			}

		case "-serial", "-com":
			if i+1 < len(args) {
				i++
				cfg.SerialPath = args[i]
			}

		case "-diska", "-fda":
			if i+1 < len(args) {
				i++
				cfg.DiskAPath = args[i]
			}

		case "-diskb", "-fdb":
			if i+1 < len(args) {
				i++
				cfg.DiskBPath = args[i]
			}

		case "-tape", "-cas":
			if i+1 < len(args) {
				i++
				cfg.TapePath = args[i]
			}

		case "--font", "-font", "-fnt":
			if i+1 < len(args) {
				i++
				fontFlag = args[i]
				cfg.FontPath = args[i]
			}

		case "-logsnd":
			if i+1 < len(args) {
				i++
				cfg.LogSndPath = args[i]
			}

		case "-state", "-sta":
			if i+1 < len(args) {
				i++
				cfg.StatePath = args[i]
			}

		case "-carta":
			if i+1 < len(args) {
				i++
				cfg.CartAPath = args[i]
				cartCount = 1
			}

		case "-cartb":
			if i+1 < len(args) {
				i++
				cfg.CartBPath = args[i]
				cartCount = 2
			}

		case "-rom":
			if i+1 < len(args) {
				i++
				val := args[i]
				// Check if it's a numeric mapper type (0..7, or >7 for guess) or a file path
				if t, err := strconv.Atoi(val); err == nil && !strings.Contains(val, ".") {
					if romTypeCount < 2 {
						cfg.ROMType[romTypeCount] = t
						romTypeCount++
					}
				} else {
					if cartCount == 0 {
						cfg.CartAPath = val
						cartCount++
					} else if cartCount == 1 {
						cfg.CartBPath = val
						cartCount++
					}
				}
			}

		case "-joy":
			if i+1 < len(args) {
				i++
				if v, err := strconv.Atoi(args[i]); err == nil {
					if joyCount < 2 {
						cfg.JoyType[joyCount] = v & 0x03
						joyCount++
					}
				}
			}

		case "-simbdos":
			cfg.SimulateBDOS = true
		case "-wd1793":
			cfg.SimulateBDOS = false

		case "-sound":
			if i+1 < len(args) && !strings.HasPrefix(args[i+1], "-") {
				if v, err := strconv.Atoi(args[i+1]); err == nil {
					i++
					cfg.SoundQuality = v
				} else {
					cfg.SoundQuality = 44100
				}
			} else {
				cfg.SoundQuality = 44100
			}
		case "-nosound":
			cfg.SoundQuality = 0

		case "-trap":
			if i+1 < len(args) {
				i++
				val := args[i]
				if strings.ToLower(val) == "now" {
					cfg.Trap = 0x0000
				} else {
					clean := strings.TrimSuffix(strings.TrimPrefix(val, "0x"), "h")
					if addr, err := strconv.ParseUint(clean, 16, 16); err == nil {
						cfg.Trap = uint16(addr)
					}
				}
			}

		case "-sync":
			if i+1 < len(args) {
				i++
			}
		case "-nosync":

		case "-scale":
			if i+1 < len(args) {
				i++
				if v, err := strconv.Atoi(args[i]); err == nil && v >= 1 && v <= 4 {
					scaleFlag = v
				}
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
			// Positional arguments: [filename1] [filename2]
			if !strings.HasPrefix(arg, "-") {
				if cartCount == 0 && cfg.CartAPath == "" {
					cfg.CartAPath = arg
					cartCount++
				} else if cartCount == 1 && cfg.CartBPath == "" {
					cfg.CartBPath = arg
					cartCount++
				} else {
					fmt.Fprintf(os.Stderr, "Excessive filename argument: %s\n", arg)
				}
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

		// Auto-seed ROMs from third-party/fMSX/ROMs or ROMs if catalog is empty
		catalogList, _ := db.ListCatalog("", "")
		if len(catalogList) == 0 {
			seedPaths := []string{
				"ROMs",
				filepath.Join("third-party", "fMSX", "ROMs"),
			}
			for _, p := range seedPaths {
				if fi, err := os.Stat(p); err == nil && fi.IsDir() {
					_, _ = db.SeedFromROMDir(p)
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

		// Initialize UI theme
		if themeFlag != "" {
			if theme.SetCurrent(themeFlag) {
				_ = db.SetConfig("theme", theme.GetCurrent())
			} else {
				fmt.Fprintf(os.Stderr, "Warning: Unsupported theme %q. Defaulting to %s.\n", themeFlag, theme.GetCurrent())
			}
		} else {
			savedTheme := db.GetConfig("theme", "system")
			theme.SetCurrent(savedTheme)
		}

		// Initialize UI font
		if fontFlag != "" {
			if font.SetCurrent(fontFlag) {
				_ = db.SetConfig("font", font.GetCurrent())
			} else {
				fmt.Fprintf(os.Stderr, "Warning: Unsupported font %q. Defaulting to %s.\n", fontFlag, font.GetCurrent())
			}
		} else {
			savedFont := db.GetConfig("font", "ubuntu")
			font.SetCurrent(savedFont)
		}

		// Initialize hardware model from saved config if not overridden by CLI flags
		if !modelFlagPassed {
			savedModel := db.GetConfig("model", "")
			switch strings.ToUpper(savedModel) {
			case "MSX1":
				cfg.Model = msx.ModelMSX1
			case "MSX2":
				cfg.Model = msx.ModelMSX2
			case "MSX2+", "MSX2P":
				cfg.Model = msx.ModelMSX2P
			}
		}
	}

	// Interactive TUI model picker if requested via -select-model / --model select
	if selectModelTUI {
		chosen, err := tui.SelectMachineModel(tui.ModelPickerOptions{
			CurrentModel: cfg.Model,
		})
		if err == nil {
			cfg.Model = chosen
			if db != nil {
				var modelStr string
				switch chosen {
				case msx.ModelMSX1:
					modelStr = "MSX1"
				case msx.ModelMSX2:
					modelStr = "MSX2"
				case msx.ModelMSX2P:
					modelStr = "MSX2+"
				}
				_ = db.SetConfig("model", modelStr)
			}
		}
	}

	// Adjust default RAM and VRAM pages matching selected model
	if cfg.Model == msx.ModelMSX1 {
		if !ramFlagPassed {
			cfg.RAMPages = 4 // 64 KB
		}
		if !vramFlagPassed {
			cfg.VRAMPages = 2 // 16 KB (TMS9918 standard)
		}
	} else {
		if !ramFlagPassed {
			cfg.RAMPages = 8 // 128 KB
		}
		if !vramFlagPassed {
			cfg.VRAMPages = 8 // 128 KB (V9938/V9958 standard)
		}
	}

	// Fallback if DB was not loaded but flags were specified
	if db == nil {
		if langFlag != "" {
			i18n.SetLanguage(langFlag)
		}
		if themeFlag != "" {
			theme.SetCurrent(themeFlag)
		}
		if fontFlag != "" {
			font.SetCurrent(fontFlag)
		}
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
		if sh.SwitchToGUI {
			gui := ui.New(machine)
			if scaleFlag > 0 {
				gui.SetScale(scaleFlag)
			}
			if err := gui.Run(); err != nil {
				fmt.Fprintf(os.Stderr, "GUI Window closed or failed: %v.\n", err)
			}
		}
		return
	}

	// 5. Default mode: Launch Graphical Window with File->Exit, Hardware, Video, Setup, Help
	gui := ui.New(machine)
	if scaleFlag > 0 {
		gui.SetScale(scaleFlag)
	}
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

func runModelCLI(args []string, dbPath string) {
	db, _ := storage.Open(dbPath)
	if db != nil {
		defer db.Close()
	}

	currModelStr := "MSX2"
	if db != nil {
		currModelStr = db.GetConfig("model", "MSX2")
	}
	currModel := msx.ModelMSX2
	switch strings.ToUpper(currModelStr) {
	case "MSX1":
		currModel = msx.ModelMSX1
	case "MSX2":
		currModel = msx.ModelMSX2
	case "MSX2+", "MSX2P":
		currModel = msx.ModelMSX2P
	}

	if len(args) == 0 || args[0] == "select" || args[0] == "menu" || args[0] == "tui" {
		chosen, err := tui.SelectMachineModel(tui.ModelPickerOptions{
			CurrentModel: currModel,
		})
		if err != nil {
			if errors.Is(err, tui.ErrCancelled) {
				fmt.Println("Model selection cancelled.")
				return
			}
			fmt.Fprintf(os.Stderr, "Error in model selection: %v\n", err)
			return
		}
		var modelName string
		switch chosen {
		case msx.ModelMSX1:
			modelName = "MSX1"
		case msx.ModelMSX2:
			modelName = "MSX2"
		case msx.ModelMSX2P:
			modelName = "MSX2+"
		}
		if db != nil {
			_ = db.SetConfig("model", modelName)
		}
		fmt.Printf("Default MSX hardware model set to %s (%s).\n", cfgModelName(chosen), modelName)
		return
	}

	argJoined := strings.ToLower(strings.Join(args, " "))
	target := strings.ToLower(args[0])

	var targetModel int
	var modelName string
	switch {
	case target == "msx1" || target == "1" || argJoined == "msx 1":
		targetModel = msx.ModelMSX1
		modelName = "MSX1"
	case target == "msx2" || target == "2" || argJoined == "msx 2":
		targetModel = msx.ModelMSX2
		modelName = "MSX2"
	case target == "msx2+" || target == "msx2p" || target == "2+" || target == "2p" || target == "3" || argJoined == "msx 2+":
		targetModel = msx.ModelMSX2P
		modelName = "MSX2+"
	case target == "status" || target == "current" || target == "get":
		fmt.Printf("Currently configured MSX model: %s (%s)\n", cfgModelName(currModel), currModelStr)
		return
	default:
		fmt.Fprintf(os.Stderr, "Unknown MSX model %q. Valid options: msx1, msx2, msx2+, or 'fmsxgo model select'\n", strings.Join(args, " "))
		return
	}

	if db != nil {
		_ = db.SetConfig("model", modelName)
	}
	fmt.Printf("Default MSX hardware model set to %s (%s).\n", cfgModelName(targetModel), modelName)
}

