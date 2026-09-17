# fMSXgo - MSX Emulator & Developer Workstation (64-bit)

[![Language](https://img.shields.io/badge/Language-Go%201.27-blue.svg)](https://golang.org)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%2064--bit-darkgreen.svg)]()
[![Status](https://img.shields.io/badge/Status-Active%20Development-orange.svg)]()
[![License](https://img.shields.io/badge/License-Non--Commercial-red.svg)](LICENSE)

**fMSXgo** is a faithful and modern port of the acclaimed **fMSX** emulator (originally authored in C by **Marat Fayzullin**) to pure **Go (64-bit)**, targeting **Windows and Linux**.

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
* **Dual Operating Modes**:
  * **Graphical Window (Ebitengine)**: Clean 640x480 interface with top menu bar (`File -> Reset / Exit`, `Setup -> Configuration...`, `Help -> About`) and live CPU/machine status.
  * **Headless Developer CLI Monitor (`--no-window`)**: Terminal REPL ("Developer OS") with register inspection, hexdump, raw byte editing, instruction stepping (`step-in`, `step-over`), breakpoints, slot visualizer, and I/O port testing.
* **Automated Build & Packaging (`build.ps1`)**: Dependency resolution, unit tests, automatic build increment, and self-contained `dist/` creation.

---

## Versioning & Creative Horror / Heavy Metal Codenames

fMSXgo follows strict **`V X.Y.Z`** semantic versioning with creative codenames inspired by classic horror cinema, MSX lore, and heavy metal masterpieces:

* **`Z` (Build)**: Auto-incremented on each compilation by `build.ps1`.
* **`Y` (Feature)**: Incremented upon completing and integrating a functional subsystem.
* **`X` (Major)**: Incremented upon closing a major architectural milestone (e.g. Z80 certification = V 1.0.0).

Current Version: **V 0.1.3 ("Phantasm")**

For complete phase tracking and immediate next steps, see [SPEC.md](SPEC.md).

---

## Quick Start

### 1. Build and Package the Distribution
Run the automated build script in PowerShell:
```powershell
.\build.ps1
```
This downloads dependencies, executes all unit tests, compiles the 64-bit binary, seeds `fmsxgo.db` with BIOS ROMs, and packages a ready-to-run `dist/` folder.

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

### 4. Configuration & Preferences (Language & Themes)
* **Graphical Mode**: Click `Setup -> Configuration...` to open the modal dialog. Click any of the 5 languages or 11 themes for an instant live preview, then click `[ Save & Close ]`.
* **CLI Monitor Mode**:
  * Type `lang` or `lang <code>` (`en`, `pt`, `es`, `nl`, `fr`).
  * Type `theme` or `theme <id>` (`system`, `github-dark`, `dracula`, `solarized-light`, etc.).
* **Startup Flags**:
  * Pass `--lang pt` to start in Portuguese.
  * Pass `--theme dracula` to start with the Dracula theme.

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