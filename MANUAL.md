# User & Developer Manual - fMSXgo

**fMSXgo** is a faithful and modern port of the acclaimed **fMSX** emulator (originally authored in C by **Marat Fayzullin**) to pure **Go (64-bit)**, natively supporting **Windows and Linux**.

Beyond preserving cycle-accurate MSX emulation, fMSXgo was conceived from day one as a **complete workstation for developers, reverse engineers, and retro-computing hackers**, offering an interactive monitor, built-in mini-assembler, dynamic disassembler, live memory and slot inspector, unified **SQLite** database storage, and multi-language interface support.

---

## 1. Getting Started & Operating Modes

fMSXgo offers two primary execution modes:

### Graphical Mode (Default)
Running the program without arguments:
```powershell
.\fmsxgo.exe
```
The emulator opens a 640x480 graphical window featuring a top menu bar:
* **`File` Menu**:
  * `Reset Machine`: Resets the CPU, slot bus, and VDP to initial power-on state.
  * `Exit`: Gracefully shuts down the emulator (shortcut: `[ESC]`).
* **`Setup` Menu**:
  * `Language`: Opens a language selector allowing you to switch between:
    * **English** (default)
    * **Português** (Portuguese)
    * **Español** (Spanish)
    * **Nederlands** (Dutch)
    * **Français** (French)
    * **Nihongo** (Japanese)
    * The active language is indicated with an asterisk `[*]`, and your selection is immediately saved to `fmsxgo.db` for future sessions.
* **`Help` Menu**:
  * `About fMSXgo`: Displays an interactive dialog with the version, codename, Marat Fayzullin & Wilson Pilon credits, and non-commercial license notice.

### Developer CLI Monitor Mode (`--no-window`)
For rapid debugging, automated regression testing, scripting, or headless CI servers:
```powershell
.\fmsxgo.exe --no-window
```
Or using the `-cli` shorthand:
```powershell
.\fmsxgo.exe -cli
```
This drops you directly into the **fMSXgo Shell**, an interactive REPL acting as a developer operating system and machine monitor.

---

## 2. Command-Line Options

fMSXgo supports both modern double-dash (`--`) flags and classic single-dash (`-`) fMSX parameters:

### Primary Options
| Option | Description |
| :--- | :--- |
| `--help`, `-help`, `-h` | Display full command-line help and usage instructions. |
| `--no-window`, `-cli` | Disable the graphical window and run in interactive CLI monitor mode. |
| `--lang <code>` | Set initial UI language (`en`, `pt`, `es`, `nl`, `fr`, `ja`). Persists to SQLite. |
| `--db <path>` | Path to SQLite database file (default: `fmsxgo.db`). |
| `-test` | Run internal self-diagnostics on CPU, memory, and slot mapping. |
| `-exec "<commands>"` | Execute semicolon-separated shell commands in batch mode then exit. |

### MSX Hardware Configuration (fMSX Compatible)
| Option | Description |
| :--- | :--- |
| `-msx1` | Emulate standard MSX 1 computer (TMS9918 VDP). |
| `-msx2` | Emulate standard MSX 2 computer (V9938 VDP, default). |
| `-msx2+` | Emulate standard MSX 2+ computer (V9958 VDP). |
| `-pal` | Set video timing to European PAL standard (50Hz). |
| `-ntsc` | Set video timing to NTSC standard (60Hz, default). |
| `-ram <pages>` | Main RAM size in 16KB pages (default: `8` = 128KB). |
| `-vram <pages>` | VRAM size in 64KB pages (default: `2` = 128KB). |
| `-rom <file>`, `-carta` | Insert cartridge ROM into Slot 1. |
| `-cartb <file>` | Insert cartridge ROM into Slot 2. |
| `-diska <file>` | Insert `.DSK` disk image into virtual Drive A:. |
| `-diskb <file>` | Insert `.DSK` disk image into virtual Drive B:. |
| `-romdir <dir>` | Directory to search for external BIOS ROMs if seeding database. |

---

## 3. Interactive Developer Shell / CLI Monitor

When starting with `--no-window`, the shell prompt displays the current CPU Program Counter (`PC`):
```text
fMSXgo [0000h]> 
```

Command names are always standard English (`HELP`, `QUIT`, `lang`, `r`, `d`, `a`, `t`, etc.), while descriptions and prompts adapt to the active UI language.

### Main Control Commands
* **`HELP`** (or `?`): Display the command summary and description in the active language.
* **`QUIT`** (or `EXIT`, `q`): Exit fMSXgo.
* **`lang`**: Display current language and list supported language codes.
* **`lang <code>`**: Switch UI language to `en`, `pt`, `es`, `nl`, `fr`, or `ja`. Persists to `fmsxgo.db`.
* **`cls`** (or `clear`): Clear terminal screen.

### CPU & Register Commands
* **`r`** (or `regs`): Display all main registers (`AF`, `BC`, `DE`, `HL`), alternate registers (`AF'`, `BC'`, `DE'`, `HL'`), index registers (`IX`, `IY`), stack pointer (`SP`), `PC`, `I`, `R`, interrupt mode (`IM`), individual condition flags (`[SZ5H3PNC]`), and disassembles the pending instruction at `PC`.
* **`r <reg> <val>`**: Modify a register's value (hexadecimal):
  ```text
  fMSXgo [0000h]> r a 42h
  fMSXgo [0000h]> r pc C000h
  fMSXgo [C000h]> r sp F000h
  ```

### Memory Inspection & Editing
* **`d [addr] [len]`**: Hexdump and ASCII display of memory. If address is omitted, continues from the last inspected location:
  ```text
  fMSXgo [0000h]> d 0000 20
  0000:  F3 C3 16 04 BF 1B 98 98 C3 83 26 00 C3 F5 01 00  |..........&.....|
  0010:  C3 86 26 00 C3 25 02 00 C3 45 1B 00 C3 17 02 00  |..&..%...E......|
  ```
* **`e <addr> <b0> [b1 b2 ...]`**: Write raw hexadecimal bytes into memory:
  ```text
  fMSXgo [0000h]> e C000 3E 42 76
  Wrote 3 bytes starting at C000h
  ```

### Disassembly
* **`u [addr] [count]`**: Disassemble `count` instructions starting from `addr` (default: 10):
  ```text
  fMSXgo [C000h]> u C000 3
  => C000:  3E 42         LD A, 42h
     C002:  76            HALT
     C003:  00            NOP
  ```

### Built-in Interactive Mini-Assembler
fMSXgo includes an integrated Z80 assembler!
* **Interactive Mode**: Type `a <addr>` to enter line-by-line assembly mode. Press `Enter` on an empty line to exit:
  ```text
  fMSXgo [0000h]> a C000
  Entering Mini-Assembler at C000h (press Enter on empty line to exit):
  C000: LD A, 10
  C002: LD B, 20
  C004: ADD A, B
  C005: HALT
  C006: [Enter]
  Exited Mini-Assembler.
  ```
* **Single-Line Mode**: Type `a <addr> <instruction>`:
  ```text
  fMSXgo [0000h]> a C000 LD A, 0xFF
  Assembled 2 bytes at C000h
  ```

### Stepping & Debugging
* **`t [n]`**: Trace / step-in `n` instructions (default: 1). Shows the executed mnemonic and register delta at each step.
* **`p`**: Step-over (`CALL`, `RST`, `DJNZ`), treating subroutines as atomic blocks.
* **`g [addr]`**: Continuous execution from `addr` (or current `PC`) until a breakpoint or `HALT`.
* **`bp`**: Manage breakpoints:
  * `bp`: List all active breakpoints.
  * `bp add <addr>`: Add breakpoint at address.
  * `bp del <addr>`: Delete breakpoint at address.
  * `bp clear`: Clear all breakpoints.

### MSX Hardware, Slots & I/O
* **`slots`**: Detailed report of the Primary Slot Register (`A8h`), Secondary Slot Registers (`FFFFh`), and current slot/subslot routing for all four 16KB Z80 pages.
* **`mapper`**: Inspect RAM Mapper allocation registers (`0xFC`..`0xFF`) and active banks.
* **`in <port>`**: Read a byte from an I/O port (hex).
* **`out <port> <val>`**: Write a byte to an I/O port (hex).
* **`info`**: Display active machine configuration (Model, Video standard, RAM size).
* **`reset`**: Reset the MSX hardware bus and zero the CPU.

---

## 4. Unified SQLite Storage (`fmsxgo.db`)

To eliminate loose ROM folders and scattered configuration files, fMSXgo stores everything in a single, portable **SQLite database (`fmsxgo.db`)**:

* **`roms` Table**: Stores binary images of all BIOS ROMs (`MSX.ROM`, `MSX2.ROM`, `MSX2EXT.ROM`, `DISK.ROM`, etc.) as `BLOB`s with SHA-1 hashes and machine tags.
* **`config` Table**: Stores persistent configuration key-value pairs (e.g., active UI language, video standard, default RAM).
* **`manuals` Table**: Stores embedded help topics and documentation.

When running `build.ps1`, the database is automatically built and populated inside `dist/`, providing a clean, self-contained single-folder distribution.

---

## 5. Automated Build System (`build.ps1`)

To build the project and create the final distribution package:

```powershell
.\build.ps1
```

The script automatically performs:
1. Reads `version.json` and increments the build number (`Z`).
2. Runs `go mod tidy` and downloads all Go dependencies.
3. Executes the full test suite (`go test ./...`).
4. Compiles the optimized 64-bit binary into `dist/`.
5. Initializes and seeds `fmsxgo.db` with BIOS ROMs.
6. Copies documentation and creates convenient batch launchers (`run-gui.bat` and `run-cli.bat`).
