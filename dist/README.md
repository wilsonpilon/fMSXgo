# fMSXgo - MSX Emulator & Developer Workstation (64-bit)

[![Language](https://img.shields.io/badge/Language-Go%201.27-blue.svg)](https://golang.org)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%2064--bit-darkgreen.svg)]()
[![Status](https://img.shields.io/badge/Status-Active%20Development-orange.svg)]()
[![License](https://img.shields.io/badge/License-Non--Commercial-red.svg)](LICENSE)

**fMSXgo** is a faithful and modern port of the acclaimed **fMSX** emulator (originally authored in C by **Marat Fayzullin**) to pure **Go (64-bit)**, targeting **Windows and Linux**.

![fMSXgo Workstation Overview](images/fmsxgo-00.png)

In addition to inheriting the time-tested accuracy of fMSX, **fMSXgo** is designed from the ground up to serve as a **high-end workstation for MSX software developers, hackers, and reverse engineers**, featuring:

* **Pure Go 64-bit Z80 CPU Core**: Cycle-accurate execution, precomputed flag tables (`ZSTable`, `PZSTable`), and BIOS patch hook (`ED FE`).
* **Built-in Interactive Mini-Assembler**: Assemble Z80 instructions directly into memory at runtime without external toolchains.
* **Dynamic Disassembler**: Disassemble arbitrary memory regions with parameter and length decoding.
* **Accurate Slot Matrix & Memory Management**: 4 Primary Slots (`0xA8`), 4 Secondary Subslots (`0xFFFF`), and a **RAM Mapper** (`0xFC`..`0xFF`) supporting 64KB up to 4MB of RAM.
* **Unified SQLite Persistence (`fmsxgo.db`)**: BIOS ROMs (`MSX.ROM`, `MSX2.ROM`, `MSX2EXT.ROM`, `DISK.ROM`), configuration settings, machine profiles, and documentation are bundled into a single SQLite database (`BLOB` storage), eliminating loose ROM file folders in distribution.
* **Multi-Language UI (i18n)**: Native UI support for **English (default)**, **Portuguese**, **Spanish**, **Dutch**, and **French**. Command names remain standard English (`HELP`, `QUIT`, `lang`, `theme`, `r`, `d`, `a`, `t`), while menus, status dialogs, hints, and command help dynamically reflect the chosen language.
* **11 Modern Color Themes**: Inspired by modern IDEs and editors:
  * **Auto (System OS)**: Automatically tracks OS Dark or Light mode.
  * **GitHub Dark** & **GitHub Light**.
  * **Modern Dark**: **VS Code Dark+**, **Dracula**, **Monokai Pro**, **One Dark Pro**.
  * **Modern Light**: **Solarized Light**, **One Light**.
  * **Simple Dark** & **Simple Light**.
* **Modern Vector Typography & Dynamic Font Subsystem**:
  * High-DPI anti-aliased TrueType/OpenType vector rendering with theme color contrast.
  * **Ubuntu** (Default UI font) and **Source Code Pro** (Monospace hacker font) embedded directly inside the binary.
  * **Zero OS Installation Required**: Drop any `.ttf` or `.otf` font file into `./fonts` or `dist/fonts` and it becomes immediately available in the UI and CLI without installing it into Windows/Linux system fonts.
* **Dual Operating Modes**:
  * **ROM & Hardware Catalog Subsystem (SQLite CRUD)**: Embedded SQLite database (`rom_catalog`) managing BIOS, BASIC, SubROMs, Disk ROMs, and hardware expansions with SHA-1 verification and execution guarantees.
  * **Guaranteed Execution (Garantia de Execução)**: Official standard fMSX ROMs are pre-seeded, verified, and flagged as active defaults with protection against accidental deletion.
  * **Graphical Window (Ebitengine)**: Clean 640x480 interface with top menu bar (`File`, `Setup -> Configuration...`, `Setup -> ROMs & HW Catalog...`, `Help -> About`) and live CPU/machine status.
  * **Headless Developer CLI Monitor (`--no-window`)**: Terminal REPL ("Developer OS") with register inspection, hexdump, raw byte editing, instruction stepping (`step-in`, `step-over`), breakpoints, slot visualizer, I/O port testing, and the `roms` suite.
* **Automated Build & Packaging (`build.ps1`)**: Dependency resolution, unit tests, automatic build increment, and self-contained `dist/` creation.

---

## Versioning & Creative Horror / Heavy Metal Codenames

fMSXgo follows strict **`V X.Y.Z`** semantic versioning with creative codenames inspired by classic horror cinema, MSX lore, and heavy metal masterpieces:

* **`Z` (Build)**: Auto-incremented on each compilation by `build.ps1`.
* **`Y` (Feature)**: Incremented upon completing and integrating a functional subsystem.
* **`X` (Major)**: Incremented upon closing a major architectural milestone (e.g. Z80 certification = V 1.0.0).

Current Version: **V 0.3.3 ("Vampire Killer")**

For complete phase tracking and immediate next steps, see [SPEC.md](SPEC.md).

---

## Quick Start

### 1. Build and Package the Distribution
Run the automated build script in PowerShell:
```powershell
.\build.ps1
```
This downloads dependencies, executes all unit tests, compiles the 64-bit binary, seeds `fmsxgo.db` with the verified ROM catalog, and packages a ready-to-run `dist/` folder.

### 2. Run in Graphical Mode (Default)
```powershell
.\fmsxgo.exe
```
Launches the graphical window with the top menu bar (`File`, `Setup`, `Help`).

### 3. Run in Terminal / CLI Developer Mode
```powershell
.\fmsxgo.exe --no-window
```
Or with custom hardware options:
```powershell
.\fmsxgo.exe --no-window -msx2 -ram 8
```

The interactive CLI monitor provides instruction tracing, memory inspection, slot visualization, and an integrated Z80 mini-assembler:

![fMSXgo Debugger & Mini-Assembler](images/fmsxgo-01.png)

### Command-Line Options & Flags
fMSXgo provides full command-line parity with the original fMSX, plus modern developer workstation extensions:

![fMSXgo Command-Line Options](images/fmsxgo-02.png)


### 4. ROM & Hardware Catalog (SQLite CRUD)
* **Graphical Mode**: Click `Setup -> ROMs & HW Catalog...` to view all registered ROMs and execution guarantees, and click any ROM to toggle it as the active default.
* **CLI Monitor Mode**:
  * `roms list [category] [model]` - View all catalog ROMs, flags (`[DEF]`, `[VER]`), sizes, and titles.
  * `roms info <name>` - Detailed inspection card with SHA-1 hash and guaranteed execution status.
  * `roms add <file> <cat> <model>` - Import a custom MSX ROM into SQLite.
  * `roms default <name>` - Set active boot default.
  * `roms del <name> [--force]` - Delete custom ROM (system ROMs protected).
  * `roms export <name> <file>` - Export binary BLOB to disk.
  * `roms verify` - Validate SHA-1 checksums and BLOB data integrity.

### 5. Configuration & Preferences (Language, Themes & Typography)
* **Graphical Mode**: Click `Setup -> Configuration...` to open the 3-column modal dialog:
  * **Column 1**: Choose between English, Portuguese, Spanish, Dutch, and French.
  * **Column 2**: Choose from 11 curated modern dark and light color themes.
  * **Column 3**: Choose from embedded typography (**Ubuntu**, **Source Code Pro**) or any custom `.ttf`/`.otf` font dropped into the `fonts/` folder.
  * Live click-to-preview on all elements, then click `[ Save & Close ]`.
* **CLI Monitor Mode**:
  * Type `lang` or `lang <code>` (`en`, `pt`, `es`, `nl`, `fr`).
  * Type `theme` or `theme <id>` (`system`, `github-dark`, `dracula`, `solarized-light`, etc.).
  * Type `font` or `font <id>` (`ubuntu`, `sourcecodepro`, or custom).
* **Startup Flags**:
  * Pass `--lang pt` to start in Portuguese.
  * Pass `--theme dracula` to start with the Dracula theme.
  * Pass `--font ubuntu` or `--font sourcecodepro` to choose typography.

All preferences are automatically persisted in `fmsxgo.db` across sessions.

---

## Project Documentation

* 📖 **[MANUAL.md](MANUAL.md)**: Complete user & developer manual, CLI monitor commands, and Mini-Assembler guide.
* 📋 **[SPEC.md](SPEC.md)**: Living engineering specification, milestone checklists, and progress tracker.
* 📝 **[CHANGELOG.md](CHANGELOG.md)**: Chronological history of releases, features, and fixes.

---

## Credits & Licensing

This project is a Go translation and workstation extension of **fMSX**, originally created by **Marat Fayzullin**.

* **Original fMSX Core & Architecture**: &copy; Marat Fayzullin (1994-2021). Developed with the author's knowledge and blessing.
* **Go Port, Developer Tools & Workstation Interface**: &copy; Wilson "Barney" Pilon.

**Important Notice**: This project is provided **strictly for Non-Commercial use**, inheriting the non-commercial licensing terms of the original fMSX source code. Please review the [LICENSE](LICENSE) file for complete details.