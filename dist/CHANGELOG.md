# Changelog - fMSXgo

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and version numbers follow the **`V X.Y.Z`** scheme with creative release codenames inspired by **Horror Cinema, MSX Classics, and Heavy Metal**.

## [V 0.3.33] - "Vampire Killer" - 2026-09-17

### Added
- **Complete VDP Video Processor Subsystem (`pkg/vdp`)**:
  - Full TMS9918A (MSX1) and V9938 (MSX2) video processor emulation in pure Go.
  - 128KB Video RAM (VRAM) with 16KB page flipping, address latch sequencing, and automatic address auto-increment.
  - Complete register set: 64 control registers (`VDP[0..63]`) and 16 status registers (`Status[0..15]`).
  - MSX I/O Ports:
    - Port `0x98`: VRAM data access with read-prefetch buffer and auto-increment.
    - Port `0x99`: Two-stage address latching, register programming, and status reading with interrupt acknowledge.
    - Port `0x9A`: Two-stage RGB 3:3:3 palette programming.
    - Port `0x9B`: Indirect register access with auto-increment.
  - **Scanline-by-Scanline Rendering Engine**:
    - `SCREEN 0`: Text 40x24 (6 pixels/char) and Text 80x24.
    - `SCREEN 1`: Text 32x24 with color table attributes.
    - `SCREEN 2`: Graphics 1 (256x192 tile mode with 8-pixel row color attributes).
    - `SCREEN 3`: Multicolor mode (64x48 4x4 blocks).
    - `SCREEN 4`: MSX2 Graphics 2 mode.
    - `SCREEN 5`: 256x192 16-color bitmap (4bpp, 128 bytes/line).
    - `SCREEN 6`: 512x192 4-color bitmap (2bpp).
    - `SCREEN 7`: 512x192 16-color bitmap (4bpp).
    - `SCREEN 8`: 256x192 256-color bitmap (8bpp RGB 3:3:2).
    - Overscan borders with `HAdjust` and `VAdjust` (R#18).
  - **Sprite Generation & Collision Detection**:
    - Mode 1: 32 sprites, 4 per line max, 8x8 and 16x16, zoom magnification, 5th-sprite flag, collision flag in S#0.
    - Mode 2: 32 sprites, 8 per line max, per-line color table, CC (Color Compare) attribute, 9th-sprite flag.
  - **V9938 Hardware Blitter & Commands Engine (`pkg/vdp/commands.go`)**:
    - Implements `HMMC`, `LMMC`, `LINE`, `HMMM`, `YMMM`, `LMMM`, `LMMV`, `HMMV`, `PSET`, `POINT`, and `SRCH` with all 8 logical operators.
  - **Frame Stepping & Synchronized Interrupts**:
    - Scanline cycle execution (~228 cycles/scanline across 262 lines NTSC / 313 lines PAL).
    - VBlank interrupt (INT_IE0) and Line coincidence interrupt (INT_IE1).
  - **Graphical Workstation Live Display & Keyboard Integration (`pkg/ui/gui.go`)**:
    - Direct 2x integer scaled MSX video display in the main workstation window (544x456 centered).
    - Full PC keyboard to MSX matrix mapping (rows 0..8) allowing immediate interactive typing in MSX-BASIC.
    - Hotkey `F11` and top-right menu bar badge (`[ F11: Screen / Debug ]`) to toggle between the live MSX screen and the developer register/status overlay.

---

## [V 0.3.3] - "Vampire Killer" - 2026-09-17

### Added
- **Modern Typography & Dynamic Vector Font Subsystem (`pkg/ui/font`)**:
  - High-DPI anti-aliased TrueType and OpenType vector font rendering engine using `github.com/hajimehoshi/ebiten/v2/text/v2` (`GoTextFace`).
  - **Embedded Zero-Dependency Fonts**:
    - **Ubuntu** (Regular & Bold) set as the default UI typography for exceptional readability on both high-res displays and compact dialogs.
    - **Source Code Pro** (Regular & Bold) for sharp, monospace developer displays.
  - **Zero Host-OS Installation Needed**:
    - Fonts are loaded directly from embedded memory or from distribution directories without requiring administrative rights or installation into `C:\Windows\Fonts`.
  - **Dynamic External Font Discovery**:
    - Automatically scans `./fonts`, `dist/fonts`, and `third-party/fonts` at startup to discover and register any user-supplied `.ttf` or `.otf` font families on the fly.
  - **3-Column Configuration Modal Dialog (`Setup -> Configuration...`)**:
    - Integrated typography selector alongside Language and Theme pickers.
    - Live click-to-preview font switching.
    - Persistent font choice saved in SQLite `fmsxgo.db` (`config` table key `font`).
  - **CLI & Command-Line Support**:
    - `--font <id>` startup flag to specify the active UI font.
    - Interactive CLI monitor command `font` (lists all embedded and discovered fonts with active indicator `*`) and `font <id>` (switches font and saves to DB).
  - **Automated Distribution Packaging**:
    - `build.ps1` now bundles the `fonts/` directory directly into `dist/fonts/` and documentation screenshots into `dist/images/`.
- **Visual Documentation & Screenshots Integration**:
  - Integrated high-resolution screenshots into `README.md`, `MANUAL.md`, and `SPEC.md`:
    - `images/fmsxgo-00.png`: Workstation Overview (graphical window, live MSX2/CPU state, Dracula theme, Ubuntu typography).
    - `images/fmsxgo-01.png`: Interactive Debugger, slot visualizer (`slots`), dynamic disassembler (`u`), and runtime mini-assembler (`a`).
    - `images/fmsxgo-02.png`: Command-Line Options help and mirror fidelity reference.
  - Restructured and renumbered `MANUAL.md` sections for consistency across all 7 operational modules.

### Changed
- Migrated all graphical UI text rendering (`pkg/ui/gui.go`) from debug bitmap prints to `font.Draw`, `font.DrawBold`, and `font.DrawCode`.
- Harmonized all text colors with active themes (`eff.MenuBarText`, `eff.ScreenText`, `eff.DialogText`, `eff.ButtonText`, `eff.SelectedText`, `eff.StatusTitle`, `eff.StatusValue`, `eff.StatusLabel`), ensuring high-contrast rendering on both light (e.g. GitHub Light, Solarized Light, Simple Light) and dark themes.

---

## [V 0.3.1] - "Vampire Killer" - 2026-09-17

### Added
- **100% Faithful fMSX Command-Line Interface Mirror**:
  - Positional argument loading: `fmsxgo [options] [filename1] [filename2]` (Cartridge A and Cartridge B).
  - Complete mirror of official fMSX options from `Help.h` & `fMSX.c`:
    - `-verbose <level>`: 0=silent, 1=startup, 2=V9938, 4=Disk/Tape, 8=Memory, 16=Illegal Z80, 32=I/O.
    - `-skip <percent>`: frame skip rate (0..99%).
    - `-pal` / `-ntsc`: 50Hz / 60Hz timing.
    - `-msx1` / `-msx2` / `-msx2+`: model selection.
    - `-ram <pages>`: 16KB RAM pages (4 for MSX1, 8 for MSX2/2+).
    - `-vram <pages>`: 16KB/64KB VRAM pages (2 for MSX1, 8 for MSX2/2+).
    - `-rom <type|file>`: MegaROM mapper type (0..7, >7: guess) or cartridge file (up to two accepted).
    - `-carta <file>` / `-cartb <file>`: direct slot 1 & 2 insertion.
    - `-diska` / `-fda <file>` & `-diskb` / `-fdb <file>`: floppy disk mounting (.DSK, .IMG).
    - `-tape` / `-cas <file>`: cassette tape mounting (.CAS).
    - `-font` / `-fnt <file>`: fixed text font.
    - `-logsnd <file>`: soundtrack logging to MIDI file.
    - `-state` / `-sta <file>`: emulation state snapshot save/load.
    - `-auto` / `-noauto`: autofire on Space key.
    - `-joy <type>`: joystick port mode (0: none, 1: normal, 2: mouse/joy, 3: mouse).
    - `-home` / `-romdir <dir>`: system ROM directory.
    - `-simbdos` / `-wd1793`: simulated BDOS vs hardware WD1793 controller.
    - `-sound [<quality>]` / `-nosound`: audio sample rate (Hz) or disabled.
    - `-printer` / `-prn <file>`: printer output redirection.
    - `-serial` / `-com <file>`: serial RS-232 I/O redirection.
    - `-trap <addr|now>`: hex breakpoint or immediate trace.
    - `-sync <freq>` / `-nosync`: screen update refresh synchronization.
    - `-scale <factor>`: integer window scale multiplier.
- **BIOS & DiskROM BDOS Patches Subsystem (`PatchZ80`)**:
  - Full pure Go port of Marat Fayzullin's `Patch.c` with opcode `ED FE` (`PatchHook`).
  - DiskROM vectors: `0x4010` (PHYDIO), `0x4013` (DSKCHG), `0x4016` (GETDPB), `0x401C` (DSKFMT), `0x401F` (DRVOFF).
  - Main BIOS vectors: `0x00E1` (TAPION), `0x00E4` (TAPIN), `0x00E7` (TAPIOF), `0x00EA` (TAPOON), `0x00ED` (TAPOUT), `0x00F0` (TAPOOF), `0x00F3` (STMOTR).
  - Virtual Floppy Drives A: and B: (`FloppyDrive`) and virtual Cassette Tape Drive (`TapeDrive`).
  - Embedded 512-byte MSX-DOS standard boot sector template (`BootBlock`).

### Fixed
- **Z80 CPU Core**:
  - `Reset()`: now resets all 8-bit registers (`A`, `F`, `B`, `C`, `D`, `E`, `H`, `L`, alternate set) to `0x00` and `SP` to `0xF000`, matching `ResetZ80()` in fMSX.
  - `DAA`: converted from heuristic math to fMSX's 2048-entry hardware-verified lookup table (`DAATable`), ensuring 100% bit-exact results across all arithmetic flags.
  - `LD A, I` & `LD A, R`: P/V flag now accurately reflects `IFF2` without spurious parity bits from `PZSTable`.
  - `OUTI`, `OTIR`, `OUTD`, `OTDR`: register `B` is now decremented before the output port address is driven to the bus.
- **MSX Bus & Slots**:
  - Memory write protection now checks `IsRAM[psl][ssl][page8k]` per 8KB bank, preventing accidental ROM overwrite in mixed RAM/ROM 16KB slots.
  - Intel 8255 PPI: writes to control port `0xAB` with bit 7 = 0 now perform Bit Set/Reset on Port C (`0xAA` - KeyRow / clicker / CAPS LED / cassette).
  - Secondary Slot Register (`0xFFFF`): accesses to `0xFFFF` now pass through to normal RAM/ROM unless the primary slot in Page 3 is expanded.

---

## [V 0.2.1] - "Aleste Nightmare" - 2026-09-17

### Added
- **ROM & Hardware Catalog Subsystem (SQLite CRUD)**:
  - **Relational Catalog Table (`rom_catalog`)**: Stores ROM metadata and binary data together:
    - Fields: `id`, `name`, `title`, `category`, `machine_model`, `size`, `sha1`, `description`, `is_default`, `is_verified`, `data` (BLOB), `created_at`.
    - Supported categories: `bios`, `basic`, `subrom`, `disk`, `hardware`, `cartridge`.
    - Target machine models: `MSX1`, `MSX2`, `MSX2+`, `ALL`.
  - **Guaranteed Execution (Garantia de Execução) & Official Defaults**:
    - Official standard fMSX bundled ROMs are automatically seeded, validated, and flagged with `is_default = 1` and `is_verified = 1`:
      - `MSX.ROM`: MSX 1 Standard BIOS & BASIC (`bios`, `MSX1`)
      - `MSX2.ROM`: MSX 2 Main BIOS & BASIC (`bios`, `MSX2`)
      - `MSX2EXT.ROM`: MSX 2 SubROM / ExtBIOS (`subrom`, `MSX2`)
      - `MSX2P.ROM`: MSX 2+ Main BIOS & BASIC (`bios`, `MSX2+`)
      - `MSX2PEXT.ROM`: MSX 2+ SubROM / ExtBIOS (`subrom`, `MSX2+`)
      - `DISK.ROM`: Standard MSX-DOS Disk ROM (`disk`, `ALL`)
      - `FMPAC.ROM`: FM-PAC (MSX-MUSIC / YM2413) Sound Hardware (`hardware`, `ALL`)
      - `PAINTER.ROM`: MSX Painter Graphic Tool Cartridge (`cartridge`, `MSX2`)
    - Accidental deletion protection: Official verified default ROMs are protected from deletion unless `--force` is explicitly specified.
    - Single default constraint per category and machine model automatically enforced.
  - **Interactive Developer Shell (`roms` / `catalog` commands)**:
    - `roms` / `roms list [category] [model]`: formatted tabular overview with `[DEF]` and `[VER]` flags.
    - `roms info <name>`: detailed record card (Title, Category, Model, Size, SHA-1, Execution guarantee, Description).
    - `roms add <file> <category> <model> [name] [title]`: registers any custom MSX ROM into SQLite.
    - `roms default <name>`: sets the chosen ROM as the active boot default.
    - `roms del <name> [--force]`: removes a custom ROM from the catalog (with protection on system ROMs).
    - `roms export <name> <path>`: exports raw ROM binary back to disk.
    - `roms verify`: validates SHA-1 hashes and BLOB integrity of all registered catalog entries.
  - **Graphical Interface (GUI) Catalog Modal**:
    - Accessible via **`Setup -> ROMs & HW Catalog...`**.
    - Interactive table displaying ROM names, categories, models, sizes, `[DEF]` / `[VER]` badges, and titles.
    - Clicking any row toggles it as the active default for that machine slot.
    - Real-time catalog summary indicator showing verified fMSX guaranteed execution count (8/8).
  - **Multi-Language Support**:
    - All catalog dialogs and CLI help text localized across 5 languages: English (`en`), Portuguese (`pt`), Spanish (`es`), Dutch (`nl`), French (`fr`).

---

## [V 0.1.5] - "Phantasm (The Tall Man)" - 2026-09-16

### Changed
- **Language Selection**:
  - Temporarily removed Japanese (`ja`) from active supported languages per project requirements. Active languages are: **English (`en`)**, **Portuguese (`pt`)**, **Spanish (`es`)**, **Dutch (`nl`)**, and **French (`fr`)**.

---

## [V 0.1.3] - "Phantasm (The Tall Man)" - 2026-09-16

### Added
- **Configuration Dialog & Modern Themes Subsystem**:
  - **11 Curated Color Themes** (`pkg/ui/theme`):
    - **Auto (System OS)**: Automatically queries Windows Registry (`AppsUseLightTheme`) to match the OS light or dark mode.
    - **GitHub Dark** & **GitHub Light**: Clean official palettes.
    - **Modern Dark**: **VS Code Dark+**, **Dracula**, **Monokai Pro**, and **One Dark Pro**.
    - **Modern Light**: **Solarized Light** and **One Light**.
    - **Simple Fallbacks**: **Simple Dark** and **Simple Light**.
  - **Interactive Configuration Modal Dialog** in GUI:
    - Accessible via **`Setup -> Configuration...`**.
    - Dual-column layout: Language selection on the left, Theme selection on the right.
    - Clicking any language or theme provides **instant live preview** with real-time UI recoloring.
    - `[ Save & Close ]` button with automatic persistence to SQLite `fmsxgo.db`.
  - **Developer CLI Monitor Integration**:
    - Added **`theme`** command (lists active and available themes with categories).
    - Added **`theme <id>`** command (switches theme dynamically in CLI and saves to DB).
    - Added **`--theme <id>`** startup command-line flag.
  - Multi-language translation updates across all 6 languages for all new configuration terms.

---

## [V 0.1.1] - "Phantasm (The Tall Man)" - 2026-09-16

### Added
- **Multi-Language User Interface (i18n)**:
  - Comprehensive internationalization subsystem (`pkg/i18n`) supporting 6 languages:
    - **English (`en`)** (Default on initial run)
    - **Portuguese (`pt`)**
    - **Spanish (`es`)**
    - **Dutch (`nl`)**
    - **French (`fr`)**
    - **Japanese (`ja` / Nihongo)**
  - Graphical Menu: Added **`Setup -> Language`** dropdown menu with real-time switching across all 6 languages, displaying active check indicator `[*]`.
  - Developer CLI Monitor: Added **`lang`** command (shows current language and supported options) and **`lang <code>`** (switches UI language dynamically).
  - Localized Command Descriptions: `HELP` command descriptions and interactive hints adapt to the user's active language while preserving standard English command keywords (`HELP`, `QUIT`, `r`, `d`, `e`, `a`, `t`, etc.).
  - Persistent Configuration: Language choices are automatically saved to `fmsxgo.db` (SQLite `config` table) and restored on subsequent launches.
  - Startup Flag: Added `--lang <code>` CLI argument to start in a specific language.
- **Repository Documentation Standardization**:
  - Converted all primary documentation (`README.md`, `MANUAL.md`, `SPEC.md`, `CHANGELOG.md`) into standard English for the international GitHub community.

---

## [V 0.1.0] - "Phantasm (The Tall Man)" - 2026-09-16

### Added
- **Pure Go 64-bit Z80 CPU Core**:
  - Cycle-accurate execution of the Zilog Z80 microprocessor (Base, CB, ED, DD, FD, DDCB, and FDCB opcode matrices).
  - Precomputed flag tables `ZSTable` and `PZSTable` ported directly from fMSX `Tables.h`.
  - BIOS acceleration patch hook opcode `ED FE` (`PatchZ80`).
  - Unit test suite verifying logical, arithmetic (8-bit and 16-bit), relative/absolute jumps, block transfers (`LDIR`), subroutine calls, and stack operations.
- **Built-in Developer & Hacker Workstation Tools**:
  - **Integrated Mini-Assembler**: Interactive line-by-line assembler capable of translating Z80 mnemonics directly into machine memory at runtime.
  - **Dynamic Disassembler**: Real-time instruction disassembler with operand and length decoding.
- **MSX Slot Bus & Memory Architecture**:
  - 64KB slot matrix supporting 4 Primary Slots (port `0xA8`) and 4 Secondary Subslots (address `0xFFFF`).
  - **RAM Mapper** controller (ports `0xFC`..`0xFF`, supporting 64KB to 4MB of RAM).
  - Dynamic write-protection for ROM pages and write-enable for RAM pages based on active slot mapping.
- **Unified SQLite Persistence (`fmsxgo.db`)**:
  - Replaced loose ROM folders with an embedded SQLite database.
  - BIOS ROMs (`MSX.ROM`, `MSX2.ROM`, `MSX2EXT.ROM`, `DISK.ROM`, etc.) stored as `BLOB` records with SHA-1 hashes and machine tags.
  - Database schema for configurations, manuals, and hardware profiles.
- **Graphical Window & Menus (Ebitengine)**:
  - Cross-platform 640x480 window for Windows & Linux 64-bit with no CGO/GCC toolchain requirement on Windows.
  - Top menu bar with **`File -> Reset / Exit`** and **`Help -> About`**.
  - Interactive modal dialog for credits and non-commercial license notices.
  - Live CPU register and hardware status overlay.
- **Interactive Developer Shell / CLI Monitor**:
  - Headless terminal execution mode via `--no-window` and `-cli`.
  - Commands: `HELP`, `QUIT`, `r` (registers), `d` (hexdump), `e` (byte entry), `u` (disasm), `a` (mini-assembler), `t` (step-in), `p` (step-over), `g` (run), `bp` (breakpoints), `slots` (slot inspector), `mapper`, `in`, `out`, `reset`, `cls`.
- **Automated Build & Packaging Tool (`build.ps1`)**:
  - PowerShell script that resolves dependencies, auto-increments build number `Z`, runs unit tests, compiles the 64-bit binary, and packages the self-contained `dist/` directory.
