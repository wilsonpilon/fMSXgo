# Changelog - fMSXgo

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and version numbers follow the **`V X.Y.Z`** scheme with creative release codenames inspired by **Horror Cinema, MSX Classics, and Heavy Metal**.

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
