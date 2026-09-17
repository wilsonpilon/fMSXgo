# User & Developer Manual - fMSXgo

**fMSXgo** is a faithful and modern port of the acclaimed **fMSX** emulator (originally authored in C by **Marat Fayzullin**) to pure **Go (64-bit)**, natively supporting **Windows and Linux**.

![fMSXgo Graphical User Interface & Workstation Overview](images/fmsxgo-00.png)

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
  * `Configuration...`: Opens the comprehensive **Configuration & Preferences** modal dialog:
    * **Language Selection**: Switch dynamically between **English** (default), **Português**, **Español**, **Nederlands**, and **Français**.
    * **Color Theme Selection**: Choose from 11 modern, editor-inspired themes with instant visual preview:
      * **Auto (System OS)**: Automatically tracks your operating system's light or dark mode.
      * **GitHub Dark** & **GitHub Light**: Clean official GitHub palettes.
      * **Modern Dark**: **VS Code Dark+**, **Dracula**, **Monokai Pro**, **One Dark Pro**.
      * **Modern Light**: **Solarized Light**, **One Light**.
      * **Simple Fallbacks**: **Simple Dark**, **Simple Light**.
    * Selections are applied immediately to all menus, windows, and dialogs, and persisted automatically to SQLite (`fmsxgo.db`).
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

## 2. Command-Line Options & fMSX Mirror Fidelity

fMSXgo achieves **100% parameter and behavior parity** with Marat Fayzullin's original fMSX emulator in C, while providing modern workstation extensions:

![fMSXgo Command-Line Options](images/fmsxgo-02.png)

### Positional Arguments
```text
fmsxgo [options] [filename1] [filename2]
```
* `[filename1]`: Cartridge ROM to insert into **Slot 1** (Cartridge A).
* `[filename2]`: Cartridge ROM to insert into **Slot 2** (Cartridge B).

### Emulation & Hardware Options (Official fMSX Mirror)
| Option | Description | Default |
| :--- | :--- | :--- |
| `-verbose <level>` | Debugging verbosity: `0` (Silent), `1` (Startup), `2` (V9938), `4` (Disk/Tape), `8` (Memory), `16` (Illegal Z80), `32` (I/O). | `1` |
| `-skip <percent>` | Percentage of frames to skip during rendering (`0`..`99`). | `25` |
| `-pal` / `-ntsc` | Select European PAL (50Hz) or Japanese/US NTSC (60Hz) video timing. | `-ntsc` |
| `-msx1` / `-msx2` / `-msx2+` | Select MSX model (TMS9918, V9938, or V9958 VDP architecture). | `-msx2` |
| `-ram <pages>` | Number of 16KB RAM pages (`4` for MSX1 = 64KB, `8` for MSX2/2+ = 128KB). | `8` |
| `-vram <pages>` | Number of 16KB/64KB VRAM pages (`2` for MSX1 = 32KB, `8` for MSX2/2+ = 128KB). | `2` (MSX1) / `8` (MSX2) |
| `-rom <type\|file>` | MegaROM mapper type (`0`: Generic 8kB, `1`: Generic 16kB, `2`: Konami5, `3`: Konami4, `4`: ASCII 8kB, `5`: ASCII 16kB, `6`: GameMaster2, `7`: FMPAC, `>7`: Guess). If given a filename, loads cartridge in Slot 1 or Slot 2. | Guess (`>7`) |
| `-carta <file>` | Explicitly insert cartridge into Slot 1. | `none` |
| `-cartb <file>` | Explicitly insert cartridge into Slot 2. | `none` |
| `-diska` / `-fda <file>` | Insert floppy disk image (`.DSK`, `.IMG`) into virtual Drive A:. | `none` |
| `-diskb` / `-fdb <file>` | Insert floppy disk image (`.DSK`, `.IMG`) into virtual Drive B:. | `none` |
| `-tape` / `-cas <file>` | Insert cassette tape image file (`.CAS`). | `none` |
| `-font` / `-fnt <file>` | Load fixed font bitmap for text display modes. | Default |
| `-logsnd <file>` | Record audio playback and PSG/OPLL soundtrack to MIDI file (`LOG.MID`). | `none` |
| `-state` / `-sta <file>` | Load or save emulation state snapshot file. | Automatic |
| `-auto` / `-noauto` | Enable or disable autofire on `[SPACE]` key. | `-noauto` |
| `-joy <type>` | Set joystick port type: `0` (None), `1` (Normal Joystick), `2` (Mouse/Joy), `3` (Mouse). Accepted up to twice for Ports 1 and 2. | `0, 0` |
| `-home` / `-romdir <dir>` | Directory to locate system ROM files (`MSX.ROM`, `MSX2.ROM`, etc.). | Current / DB |
| `-simbdos` | Simulate DiskROM disk access calls via `PatchZ80` system hooks. | Enabled |
| `-wd1793` | Emulate Western Digital WD1793 hardware floppy disk controller directly. | Optional |
| `-sound [<quality>]` | Sound emulation sampling rate in Hz (e.g. `44100`, `22050`). | `44100` |
| `-nosound` | Disable audio synthesis completely (`-sound 0`). | Enabled |
| `-printer` / `-prn <file>`| Redirect printer output to specified file. | `stdout` |
| `-serial` / `-com <file>` | Redirect serial RS-232 I/O to a file or stream. | `stdin/stdout` |
| `-trap <addr\|now>` | Trap execution when PC reaches hex address (or `now` for immediate trace). | `FFFFh` |
| `-sync <freq>` / `-nosync`| Synchronize display updates to vertical frequency or disable sync. | `60` |
| `-scale <factor>` | Integer video display scaling factor (`1`x, `2`x, `3`x, `4`x). | `2` |
| `-help`, `--help`, `-h`, `/?` | Print full command-line help page. | — |

### Developer & Workstation Options (fMSXgo Extensions)
| Option | Description | Default |
| :--- | :--- | :--- |
| `--no-window`, `-cli` | Disable the graphical window and run in interactive CLI monitor mode. | GUI Mode |
| `--lang <code>` | Set initial UI language (`en`, `pt`, `es`, `nl`, `fr`). Persists to SQLite. | `en` |
| `--theme <id>` | Set initial UI theme (`system`, `github-dark`, `dracula`, etc.). Persists to SQLite. | `system` |
| `--font <id>` | Set initial UI typography/font family (`ubuntu`, `sourcecodepro`, etc.). Persists to SQLite. | `ubuntu` |
| `--db <path>` | Path to SQLite database file. | `fmsxgo.db` |
| `-test` | Run internal self-diagnostics on CPU, memory, and slot mapping. | — |
| `-exec "<commands>"` | Execute semicolon-separated shell commands in batch mode then exit. | — |

### MSX Floppy Disk Manipulation Subcommand (`fmsxgo disk ...`)
fMSXgo includes a standalone, scriptable FAT12 disk manipulation utility ported from the reference C tools and modernized:
* **`fmsxgo disk create <disk.dsk> [format]`**: Creates and formats a new MSX-DOS disk image (`720k` default, `360k`, or `180k`).
* **`fmsxgo disk list <disk.dsk> [-l]`**: Lists all files stored on the disk (`-l` displays detailed file size, timestamps, and cluster count).
* **`fmsxgo disk add <disk.dsk> <file1> [file2 ...]`**: Injects host files into the MSX disk image, supporting wildcards (e.g. `*.BAS`).
* **`fmsxgo disk extract <disk.dsk> [-d out_dir] [mask ...]`**: Extracts files matching optional wildcards into the destination directory.
* **`fmsxgo disk delete <disk.dsk> <filename>`**: Deletes a file from the disk image and reclaims its FAT cluster chain.

---

## 3. High-Fidelity Subsystems (fMSX Mirror)

### BIOS & DiskROM Patches (`PatchZ80`)
Like fMSX in C, fMSXgo includes full support for ROM patching via opcode `0xED, 0xFE, 0xC9` (hook vector):
* **DiskROM BDOS Vectors (`0x4010` .. `0x401F`)**:
  * `0x4010` **PHYDIO**: Physical sector read/write on Drives A: and B: (supporting 360KB, 720KB, 640KB, 1280KB `.DSK` disk images). Automatically turns on RAM across all slots, performs sector data streaming, and restores slot state.
  * `0x4013` **DSKCHG**: Disk change status detection.
  * `0x4016` **GETDPB**: Extracts the Drive Parameter Block (DPB) from sector 0 boot sector.
  * `0x401C` **DSKFMT**: Formats virtual disks using the official MSX-DOS boot sector template (`BootBlock`).
  * `0x401F` **DRVOFF**: Disk motor shutoff.
* **Main BIOS Tape Vectors (`0x00E1` .. `0x00F3`)**:
  * `0x00E1` **TAPION**: Read cassette header and synchronize.
  * `0x00E4` **TAPIN**: Read single byte from `.CAS` tape stream.
  * `0x00E7` **TAPIOF**: Stop cassette reading.
  * `0x00EA` **TAPOON**: Initialize cassette recording.
  * `0x00ED` **TAPOUT**: Write byte to tape stream.
  * `0x00F0` **TAPOOF**: Stop cassette recording.
  * `0x00F3` **STMOTR**: Motor control for cassette tape.

### Z80 CPU Fidelity
* **Power-on State**: All 8-bit registers (`A`, `F`, `B`, `C`, `D`, `E`, `H`, `L`, alternate set) initialize to `0x00`; `SP` initializes to `0xF000` (matching fMSX `ResetZ80()`).
* **Decimal Adjust (DAA)**: Emulated using fMSX's hardware-verified 2048-entry `DAATable` for 100% bit-exact results across all arithmetic flags.
* **Interrupt Flip-Flops & LD A, I/R**: `LD A, I` and `LD A, R` reflect `IFF2` into the P/V flag, preserving the sign and zero flags via `ZSTable`.
* **Block I/O Instructions**: In `OUTI`, `OTIR`, `OUTD`, and `OTDR`, register `B` is decremented *before* the output port address is driven to the bus, exactly matching Zilog Z80 hardware specification.


---

## 4. Interactive Developer Shell & CLI Monitor

When starting with `--no-window`, the shell prompt displays the current CPU Program Counter (`PC`):
```text
fMSXgo [0000h]> 
```

The interactive CLI monitor provides instruction tracing, memory inspection, slot visualization, and an integrated Z80 mini-assembler:

![fMSXgo Interactive Debugger, Disassembler & Mini-Assembler](images/fmsxgo-01.png)

Command names support standard CLI mnemonics as well as 100% compatible commands from **MegaAssembler** and **Super-X**:

### Standardized Number Bases (Default Hexadecimal)
To provide a fast, seamless experience matching classic 8-bit MSX machine monitors (MegaAssembler and Super-X), **all numbers are accepted as HEXADECIMAL by default across all debugger commands and in the mini-assembler**.

When specifying values in other numeric bases, explicit letter prefixes are available:
* **`b`** (or `B`): **Binary** (base 2) — e.g. `b1010`, `B11110000`, `%1010`, `0b1010` (or suffix `1010b`).
* **`d`** (or `D`): **Decimal** (base 10) — e.g. `d10`, `D255`, `d1000`, `#10` (or suffix `10d`).
* **`h`** (or `H`): **Hexadecimal** (base 16) — reinforces hex e.g. `h10`, `hC000`, `$C000`, `0xC000` (or suffix `10h`).
* **`o`** (or `O`): **Octal** (base 8) — e.g. `o77`, `O12`, `0o77`, `@77` (or suffix `77o`, `77q`).
* **Bare numbers** (no prefix): Interpreted as **Hexadecimal** by default (e.g. `10` = `0x10` = 16 decimal; `C000` = `0xC000`).

### Main Control Commands
* **`HELP`** (or `?`): Display the command summary and description in the active language.
* **`QUIT`** (or **`BA`** [MegaAssembler], **`QT`** [Super-X], **`BASIC`**, **`EXIT`**, **`q`**): Exit the interactive debugger monitor and fMSXgo.
* **`windows`** (or **`window`**, **`gui`**): Launch or refocus the graphical window interface (GUI). If fMSXgo was started in CLI mode (`--no-window`), typing `windows` seamlessly boots the graphical window; if launched from the GUI's `File -> Developer CLI`, typing `windows` refocuses the window.
* **`lang`**: Display current language and list supported language codes.
* **`lang <code>`**: Switch UI language to `en`, `pt`, `es`, `nl`, or `fr`. Persists to `fmsxgo.db`.
* **`theme`**: Display current theme and list all 11 available themes.
* **`theme <id>`**: Switch active theme (e.g. `theme dracula`, `theme github-dark`, `theme system`). Persists to `fmsxgo.db`.
* **`font`**: Display current UI font and list all discovered font families.
* **`font <id>`**: Switch active UI typography font (e.g. `font ubuntu`, `font sourcecodepro`). Persists to `fmsxgo.db`.
* **`cls`** (or `clear`): Clear terminal screen.

### CPU & Register Commands
* **`r`** (or `regs`, **`x`** [MegaAssembler], **`rg`** [Super-X]): Display all main registers (`AF`, `BC`, `DE`, `HL`), alternate registers (`AF'`, `BC'`, `DE'`, `HL'`), index registers (`IX`, `IY`), stack pointer (`SP`), `PC`, `I`, `R`, interrupt mode (`IM`), individual condition flags (`[SZ5H3PNC]`), and disassembles the pending instruction at `PC`.
* **`r <reg> <val>`** (or **`x <reg> <val>`**, **`rg <reg> <val>`**): Modify a register's value (hexadecimal):
  ```text
  fMSXgo [0000h]> r a 42h
  fMSXgo [0000h]> x pc C000h
  fMSXgo [C000h]> rg sp F000h
  ```

### Memory Inspection & Editing
* **`d [addr] [len]`**: Hexdump and ASCII display of memory. If address is omitted, continues from the last inspected location:
  ```text
  fMSXgo [0000h]> d 0000 20
  0000:  F3 C3 16 04 BF 1B 98 98 C3 83 26 00 C3 F5 01 00  |..........&.....|
  0010:  C3 86 26 00 C3 25 02 00 C3 45 1B 00 C3 17 02 00  |..&..%...E......|
  ```
* **`dm [addr][,[desloc][,bytes]]`** (or compact **`DM<addr>,<desloc>,<bytes>`** [MegaAssembler]): Interactive memory display and editor with scrambled text offset (displacement) and optional byte size:
  - **All numbers are HEXADECIMAL by default**: Consistent with the debugger standard, every parameter (`addr`, `desloc`, `bytes`) is parsed in hexadecimal unless an explicit base prefix is used (e.g. `d` for decimal).
    - `dm c000,41,80`: Everything is hex! Address `C000h`, displacement `41h` (`+65` decimal), length `80h` (`128` bytes).
    - `dm c000,,d512`: Double comma omits displacement (default `0`), `d512` is decimal 512 bytes. (Without `d`, `512` is hex `0x512` = 1298 bytes).
  - **Memory Dump & Length (`bytes`)**: Total bytes to inspect/edit (optional, default: 128 / `80h`). Always rounded to the nearest multiple of 128 bytes (e.g. `80h` = 128, `100h` = 256, `200h` = 512, `d512` = 512, `d1024` = 1024...). In non-interactive/batch mode, outputs the full range; in interactive mode, manages the full session buffer.
  - **Displacement (`desloc`)**: Optional Caesar displacement to decode/encode scrambled text strings in games and ROMs:
    - Positive displacement (e.g. `1` or `+1`, `41`): adds value to each byte on display (`'A'` becomes `'B'`).
    - Negative displacement (e.g. `-1`): subtracts value (`'B'` becomes `'A'`).
  - **Interactive Editing & Seamless Scrolling**:
    - **Arrow Keys**: Navigate memory bytes on screen. When reaching the edges (top row, bottom row, byte 0 or byte 127), the view automatically **scrolls line by line** (16 bytes at a time) continuously through memory.
    - **`PageUp` / `PageDown`** (or **`TAB`**): Roll memory 128 bytes backward or forward at a time.
    - **Hexadecimal digits** (`0`-`9`, `A`-`F`): Edit bytes directly in memory.
    - **`ENTER`**: Confirm byte entry (automatically converting displayed displaced values to underlying memory bytes).
    - **`ESC`**: Exit the interactive editor and return to the shell prompt (updating `LastDump` to where you navigated).
  ```text
  fMSXgo [C000h]> dm c000,41,80
  === Display & Memory Edit (DM) ===
  Range: C000h..C07Fh (128 bytes) | Displacement: +65 | Cursor: C000h
  [Arrows]: Navigate/Scroll  [PgUp/PgDn/TAB]: ±128B  [0-9, A-F]: Edit  [ESC]: Exit
  -----------------------------------------------------------------
  C000:  42 43 44 00 00 00 00 00  00 00 00 00 00 00 00 00  |BCD.............|
  ...
  ```
* **`e <addr> <b0> [b1 b2 ...]`**: Write raw hexadecimal bytes into memory:
  ```text
  fMSXgo [0000h]> e C000 3E 42 76
  Wrote 3 bytes starting at C000h
  ```

### Disassembly
* **`u [addr] [count]`** (or **`l`** [MegaAssembler], **`i`** [Super-X], `dasm`): Disassemble `count` instructions starting from `addr` (default: 10):
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
* **`t [n]`** (or **`tr`** [Super-X], `step`): Trace / step-in `n` instructions (default: 1). Shows the executed mnemonic and register delta at each step.
* **`p`** (or `next`): Step-over (`CALL`, `RST`, `DJNZ`), treating subroutines as atomic blocks.
* **`g [addr]`** (or **`go`** [Super-X], `run`): Continuous execution from `addr` (or current `PC`) until a breakpoint or `HALT`.
* **`bp`**: Manage breakpoints:
  * `bp`: List all active breakpoints.
  * `bp add <addr>`: Add breakpoint at 16-bit address (e.g. `bp add 0x0038`).
  * `bp del <addr>`: Remove breakpoint.
  * `bp clear`: Clear all breakpoints.

### MSX Hardware, Slots & I/O
* **`slots`** (or **`page`**, **`page?`** [MegaAssembler]): Detailed report of the Primary Slot Register (`A8h`), Secondary Slot Registers (`FFFFh`), and current slot/subslot routing for all four 16KB Z80 pages.
* **`mapper`**: Inspect RAM Mapper allocation registers (`0xFC`..`0xFF`) and active banks.
* **`diskcreate [filename] [format]`** (or **`createdsk`**, **`newdsk`**, **`mkdsk`**): Creates and formats a new MSX FAT12 disk image (`720k` default, `360k`, or `180k`).
  * **Direct Creation**: If the filename is specified (e.g. `diskcreate mydisk.dsk` or `diskcreate blank.dsk 360`), creates the disk directly in the current working directory and automatically mounts it into Drive A:.
  * **Interactive TUI Save Browser**: If invoked without arguments (`diskcreate`), opens a full-screen terminal save dialog allowing directory navigation, Windows drive selection (`C:`, `D:`, etc.), filename editing (`[N]`), and saving (`[S]` or `[ENTER]` on `[+] SAVE HERE`).
  * **Auto-Mount**: Once created, the disk is automatically loaded into virtual floppy Drive A:, immediately ready for `zap`, files, or booting.
* **`loaddsk [file]`** (or **`dskload`**, **`dsk`**, **`diska`**): Mount a `.DSK` disk image into memory (Drive A: or specified drive).
  * **Direct Loading**: If the filename is specified on the command line (e.g. `loaddsk game.dsk` or `loaddsk b game.dsk`), fMSXgo loads it immediately without opening the navigator.
  * **Interactive TUI File Browser**: If invoked without arguments (`loaddsk`), opens a full-screen terminal file picker with directory navigation, extension filtering, size/date inspection, and keyboard shortcuts (`[↑/↓]`: navigate, `[ENTER]`: open/select, `[BKSP]`: parent dir, `[TAB/F]`: toggle filter, `[ESC]`: cancel).
  * **Memory Staging**: The disk sectors are loaded into host RAM / virtual floppy drive memory ready for subsequent sector operations.
* **`zap <sector>[[,<desloc>[,<bytes>]]`** (or **`superzap`**, **`diskzap`**): Classic MSX interactive disk sector editor (operates on the disk image loaded in memory):
  * **Automatic Disk Adaptation**: Detects and enforces sector boundaries and physical CHS geometry according to the loaded disk:
    * **720 KB (3.5" DS/DD)**: 1440 sectors (`0..1439` / `0000h..059Fh`), 80 tracks, 2 sides (dupla face), 9 sectors/track (dupla densidade).
    * **640 KB (3.5" DS/DD)**: 1280 sectors (`0..1279` / `0000h..04FFh`), 80 tracks, 2 sides, 8 sectors/track.
    * **360 KB (5 1/4" DS/DD)**: 720 sectors (`0..719` / `0000h..02CFh`), 40 tracks, 2 sides, 9 sectors/track.
    * **180 KB (5 1/4" SS/DD)**: 360 sectors (`0..359` / `0000h..0167h`), 40 tracks, 1 side (simples face), 9 sectors/track.
    * **320 KB / 160 KB**: Automatically configured for single/double sided, single/double density formats.
  * **Sector Size & Limit**: By default displays the full 512 bytes (`200h`) of the sector. Parameter `bytes` can be set to inspect smaller chunks (128, 256, 384, or 512 bytes).
  * **Displacement (`desloc`)**: Caesar offset applied to displayed hex/ASCII to inspect encoded game strings and secret text (e.g. `zap 0, 41, 100`).
  * **Interactive Sector Navigation & In-Memory Editing**:
    * **Arrow Keys**: Move cursor across sector bytes.
    * **`PageUp` / `PageDown`**: Jump directly to the previous or next sector (`sector--` / `sector++`).
    * **`TAB`**: Advance to the next sector (cycles through disk).
    * **Hexadecimal Digits (`0-9`, `A-F`)**: Edit raw bytes directly in virtual floppy disk memory (`fdd.Modified = true`).
    * **`ENTER`**: Confirm byte edit.
    * **`ESC`**: Exit sector editor and return to debugger prompt.
* **`in <port>`** (or **`pi`** [Super-X]): Read a byte from an I/O port (hex).
* **`out <port> <val>`** (or **`po`** [Super-X]): Write a byte to an I/O port (hex).
* **`info`**: Display active machine configuration (Model, Video standard, RAM size).
* **`reset`**: Reset the MSX hardware bus and zero the CPU.

### ROMs & Hardware Catalog (SQLite CRUD)
* **`roms`** or **`roms list [category] [model]`**: Lists all registered ROMs, sizes, active default flags (`[DEF]`), and verified execution flags (`[VER]`).
* **`roms info <name>`**: Shows complete metadata card for a ROM, including SHA-1 hash, category, target model, guaranteed execution status, and registration timestamp.
* **`roms add <file> <category> <model> [name] [title] [desc]`**: Registers a custom MSX ROM into the SQLite catalog.
  * Categories: `bios`, `basic`, `subrom`, `disk`, `hardware`, `cartridge`.
  * Target Models: `MSX1`, `MSX2`, `MSX2+`, `ALL`.
* **`roms default <name>`**: Sets the specified ROM as the active boot default for its category and hardware model.
* **`roms del <name> [--force]`**: Removes a custom ROM from the catalog. Official verified system ROMs are protected and require `--force`.
* **`roms export <name> <output_path>`**: Extracts the raw ROM binary BLOB from SQLite and saves it back to disk.
* **`roms verify`**: Verifies SHA-1 hashes and BLOB integrity for all registered catalog entries.

---

## 5. Unified SQLite Storage & ROM Catalog (`fmsxgo.db`)

To eliminate loose ROM folders and scattered configuration files, fMSXgo stores everything in a single, portable **SQLite database (`fmsxgo.db`)**:

### The `rom_catalog` Table
Stores registered ROMs, hardware expansions, and cartridges with rich metadata:
* `id` (INTEGER PRIMARY KEY)
* `name` (TEXT UNIQUE NOT NULL): Internal filename identifier (e.g. `MSX2.ROM`).
* `title` (TEXT NOT NULL): Friendly display title.
* `category` (TEXT NOT NULL): `bios`, `basic`, `subrom`, `disk`, `hardware`, `cartridge`.
* `machine_model` (TEXT NOT NULL): Target architecture (`MSX1`, `MSX2`, `MSX2+`, `ALL`).
* `size` (INTEGER NOT NULL): File size in bytes.
* `sha1` (TEXT NOT NULL): Cryptographic checksum for integrity checks.
* `description` (TEXT): Extended documentation.
* `is_default` (BOOLEAN): Whether this ROM is the active default for its category/model slot.
* `is_verified` (BOOLEAN): Flag for **Guaranteed Execution (Garantida de Execução)**.
* `data` (BLOB NOT NULL): Raw binary payload.

### Official fMSX Default & Verified ROMs
The following official bundled ROMs are automatically seeded and permanently flagged with **`is_default = 1`** and **`is_verified = 1`** (Guaranteed Execution):
1. **`MSX.ROM`**: MSX 1 Standard BIOS & BASIC (`bios`, `MSX1`)
2. **`MSX2.ROM`**: MSX 2 Main BIOS & BASIC (`bios`, `MSX2`)
3. **`MSX2EXT.ROM`**: MSX 2 SubROM / ExtBIOS (`subrom`, `MSX2`)
4. **`MSX2P.ROM`**: MSX 2+ Main BIOS & BASIC (`bios`, `MSX2+`)
5. **`MSX2PEXT.ROM`**: MSX 2+ SubROM / ExtBIOS (`subrom`, `MSX2+`)
6. **`DISK.ROM`**: Standard MSX-DOS Disk ROM (`disk`, `ALL`)
7. **`FMPAC.ROM`**: FM-PAC (MSX-MUSIC / YM2413) Sound Hardware (`hardware`, `ALL`)
8. **`PAINTER.ROM`**: MSX Painter Graphic Tool Cartridge (`cartridge`, `MSX2`)

### Graphical Catalog Selector
Inside the graphical window, users can click **`Setup -> ROMs & HW Catalog...`** to view all registered ROMs, check the verified status count (8/8), and click on any ROM to toggle it as the active default for the machine.

---

## 6. Modern Typography & Custom Font Subsystem

fMSXgo features a state-of-the-art vector typography rendering engine powered by TrueType / OpenType font parsing (`github.com/hajimehoshi/ebiten/v2/text/v2`):

### Zero OS-Installation Requirement
Fonts do **not** need to be installed into Windows (`C:\Windows\Fonts`) or Linux system folders!
- **Embedded Out-of-the-Box**: **Ubuntu** (Default UI font) and **Source Code Pro** (Monospace hacker/coding font) are embedded directly inside the compiled binary (`//go:embed assets/*.ttf`).
- **Dynamic External Scanning**: At startup, fMSXgo scans the distribution folders (`./fonts`, `dist/fonts`, `third-party/fonts`) for any additional `.ttf` or `.otf` files and automatically registers them into the active font registry.

### Adding New Fonts
To add your own custom fonts:
1. Copy any `.ttf` or `.otf` file into the `fonts/` directory of your fMSXgo distribution.
2. Open fMSXgo or run `font` in the CLI.
3. Your font will automatically appear in the list and can be selected immediately!

### Unified Setup / Configuration Dialog
In the graphical interface, select **`Setup -> Configuration...`**:
- **Column 1 (Language)**: Choose between English, Português, Español, Nederlands, and Français.
- **Column 2 (Themes)**: Select from 11 dark and light themes (System Auto, GitHub Dark/Light, Dracula, Monokai Pro, One Dark/Light, Solarized Light, Simple Dark/Light).
- **Column 3 (Typography / Font)**: Select your preferred UI font (Ubuntu, Source Code Pro, or any custom font).
- The text colors, anti-aliased glyphs, and contrast automatically adapt to the active theme with real-time preview and instant SQLite persistence (`fmsxgo.db`).

---

## 7. Automated Build System (`build.ps1`)

To build the project and create the final distribution package:

```powershell
# Standard build & packaging:
.\build.ps1

# Build and automatically run from dist/ (--no-window by default, returns to current dir on exit):
.\build.ps1 --Run

# Build and run in Graphical Window mode (GUI):
.\build.ps1 --Run --window

# Build and run with custom arguments forwarded to fmsxgo:
.\build.ps1 --Run game.rom
.\build.ps1 --Run -msx2 -diska disk.dsk
```

The script automatically performs:
1. Reads `version.json` and increments the build number (`Z`).
2. Runs `go mod tidy` and downloads all Go dependencies.
3. Executes the full test suite (`go test ./...`).
4. Compiles the optimized 64-bit binary into `dist/`.
5. Initializes and seeds `fmsxgo.db` with the official verified BIOS ROM catalog.
6. Copies TrueType fonts to `dist/fonts/` and screenshots to `dist/images/`.
7. Copies documentation and creates convenient batch launchers (`run-gui.bat` and `run-cli.bat`).
8. If `--Run` (or `-Run`, `-r`) is supplied:
   - Defaults to running with `--no-window` in terminal CLI developer mode.
   - If `--window` (or `-w`, `--gui`) is passed after `--Run`, launches the graphical window GUI.
   - Switches working directory into `dist/`, launches `fmsxgo.exe`, and upon program exit returns seamlessly to the previous directory (`Pop-Location`).


