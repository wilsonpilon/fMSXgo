# fossauro - fMSX Ported to PureBasic

**fossauro** is a native PureBasic port of Marat Fayzullin's **fMSX** emulator — Z80 CPU core, MSX
motherboard/slot logic, V9938 VDP, and AY-3-8910 PSG — compiling to a single dependency-free
`fossauro.exe`. Sibling project to Paleobasic within this repository; own license (non-commercial, see
[`LICENSE-fossauro`](../LICENSE-fossauro) at the repo root and the Licença section of the main
`README.md`).

**For full component-by-component status and the prioritized "what's left" list, see [`SPEC.md`](SPEC.md).**
**For architecture notes and debugging methodology when continuing work, see [`OUTLINE.md`](OUTLINE.md).**

---

## Credits

Directly based on the C source code of **fMSX**, designed and written by **Marat Fayzullin**. Full credit
to his exceptional work in MSX emulation — this project would not exist without it.

---

## Project status

- [x] **Z80 CPU core** — complete, verified. See `SPEC.md` for the two real translation bugs found and
  fixed (`EX (SP),HL`/`IX`/`IY`, `JP (HL)`/`(IX)`/`(IY)` null-pointer crash).
- [x] **MSX motherboard & slots** — complete for what's implemented. Primary/secondary slot paging
  verified byte-for-byte against real fMSX's C source. Per-model BIOS loading (MSX1/MSX2/MSX2+),
  cassette BIOS patches, and Real-Time Clock chip all implemented.
- [x] **MSX1 boot** — boots completely to the BASIC prompt ("MSX BASIC version 1.0").
- [x] **MSX2 boot** — boots completely to the BASIC prompt ("MSX BASIC version 2.1"). Root cause of the
  long-standing freeze found and fixed 2026-08-18 — see `SPEC.md` §2.
- [x] **MSX2+ boot** — boots completely to the BASIC prompt ("MSX BASIC version 3.0").
- [x] **V9938 VDP** — text/bitmap rendering for ALL modes 0/1/2/3/4/5/6/7/8, sprites, and the full VDP
  command engine (SRCH/LINE/LMMV/LMMM/LMCM/LMMC/HMMV/HMMM/YMMM/HMMC), all audited against real `V9938.c`.
  SCREEN 6/7 added 2026-08-18 (`screen67_verify.pb` harness confirms correct color bars + sprite
  compositing in both modes) - found and fixed a real pre-existing bug along the way: `FillMemory()`
  calls in `RefreshLine()` were missing PureBasic's `#PB_Long` size argument, silently filling
  border/background colors byte-by-byte instead of as full RGBA values (invisible only because black,
  the default, has all-equal bytes). Missing: VDP command timing (commands complete instantly), MSX2+
  SCREEN 10-12 (YJK modes, real fMSX doesn't support these either).
- [x] **AY-3-8910 PSG** — real per-sample audio synthesis (17-bit LFSR noise, verified envelope state
  machine), Win32 `waveOut` streaming. Verified end-to-end 2026-08-18 (`audio_verify.pb` harness):
  measured tone frequency matches the theoretical formula, noise/envelope/3-channel mixing all produce
  correct non-silent output, and the live `StartAudio()`/`StopAudio()` thread opens the real audio device
  and streams/stops cleanly with no hang or crash. See `SPEC.md` for detail.
- [x] **File menu** — Open Cartridge (works), Save/Open Snapshot (real save-state, not a stub), Quit.
- [x] **Hardware → Model menu** — live MSX1/MSX2/MSX2+ switching.
- [x] **Hardware → RAM Size menu** — 64/128/256/512/1024KB, live (full reset). Real fMSX's bank-switched
  RAM mapper (ports `$FC`-`$FF`, hardwired to Primary Slot 3/Secondary Slot 2) for every model alike -
  fMSX doesn't model MSX1 RAM expansion as separate cartridges, even though that was the common real-
  hardware approach. Also settable via `-ram <pages>`.
- [x] **Hardware → VRAM Size menu** — 16/32/64/128/192KB, live (full reset). MSX2/MSX2+ match real fMSX
  exactly (only ever accept exactly 128KB, any other selection silently snaps back). MSX1 accepts
  16/32/64/128KB (192KB snaps to 16KB) - one deliberate deviation from real fMSX here: real fMSX's MSX1
  minimum is actually 32KB (16KB always resets to it), but 16KB was the project owner's explicit choice
  since it was the common real MSX1-hardware VRAM size and is now fossauro's own MSX1 default. Also
  settable via `-vram <pages>`.
- [x] **Startup defaults**: MSX1, 64KB RAM, 16KB VRAM (no CLI arguments needed) - project owner's explicit
  choice, 2026-08-18.
- [x] **Hardware → Cartridge Slot A/B menus** — independent Load.../Eject per slot (a real bug in the old
  code had Slot A mirror into both primary slots, silently stealing Slot B's cartridge if loaded after
  it - fixed), plus a Mapper Type submenu (Guess/Generic 8kB/Generic 16kB/Konami 5000h-SCC/Konami 4000h/
  ASCII 8kB/ASCII 16kB/GameMaster2/FMPAC) matching real fMSX's `-rom <type>` list. MegaROMs (>32KB) get
  real bank-switch emulation (`MapROM()`, ported from `MSX.c`) including SRAM for ASCII8/ASCII16/
  GameMaster2/FMPAC (session-only, not persisted to a `.sav` file yet); SCC/OPLL sound chip registers are
  trapped but not emulated (ROM/SRAM banking works without them). Auto-detection (`GuessROMType()`) ports
  fMSX's content-scanning heuristic (no CRC/SHA1 known-ROM database, fossauro ships none).
- [x]/[ ] **Video → Scale/Force 4:3 menu** — 1:1 and the 4:3 toggle work, verified live. 2:1/3:1/4:1 show
  a warning instead of applying: confirmed real, 100% reproducible hang any time the window/canvas
  exceeds the original 512x384 default (not a resize-mechanics issue - even a fresh, non-relaunched
  `-vscale 2` launch hangs on its own), root cause not isolated. See `docs/SPEC.md` module 32s.
- [ ] **Disk (FDC) emulation** — WD1793 register/command mechanism implemented and verified in isolation
  (`FDC.pbi`, `fdc_verify.pb`: 4/4 tests pass against a real 720KB image, byte-exact). NOT yet usable
  end-to-end: mapping `DISK.ROM` into memory breaks MSX2/2+ boot (real regression, root cause not
  isolated - no real fMSX C source available on this machine to check the expected memory layout
  against), so `DISK.ROM` loading stays disabled for now. See `SPEC.md`/`docs/SPEC.md` module 32p.
- [ ] **Cassette (.CAS) emulation** — not implemented, explicitly deferred.
- [ ] **Cheat (.CHT) support** — not implemented, explicitly deferred (planned: openMSX/BlueMSX-compatible
  format).
- [ ] Joystick/mouse, printer, serial, Kanji ROM, settings/config UI.
- [x]/[ ] **Remote control protocol** — a small custom named-pipe protocol (`\\.\pipe\fossauro`), NOT
  the openMSX Tcl/XML control protocol on purpose (too much surface for what's needed here):
  `PING`/`LOAD <addr> <len>`/`POKE <addr> <val>`/`PEEK <addr>`/`RUN <addr>` (raw PC jump). Server side
  and a first real Paleobasic client both verified live end-to-end through the Mamute Assembler's new
  `FOSSAURO` MON> command (assemble with `A O`, then `FOSSAURO` loads + runs it for real on fossauro's
  Z80 core). `RUN` still doesn't do real MSX BASIC line-relinking/`TXTTAB` bookkeeping — see
  `docs/SPEC.md` modules 32u/32v.

---

## Tooling & automation

Manual conversion of thousands of lines of Z80 opcodes is error-prone, so this project uses a Python
translation pipeline:

- **`translate.py`** — parses fMSX's macro-heavy C instruction tables (`Codes.h`, `CodesCB.h`, etc.) and
  emits PureBasic `Select`/`Case` blocks. Handles ternary branches, C-array-bracket-to-parenthesis
  conversion, register post-increment/decrement (including as call arguments — a real source of past
  bugs, see `OUTLINE.md` §3), and nesting-aware `if` translation. Re-run with `python translate.py` if you
  change the translation rules or the C sources in `fMSX/fMSX/Z80/`.

---

## How to build & run

### Prerequisites
1. **PureBasic Compiler (`pbcompiler`)** on `PATH` or configured via `build.ps1 -C`.
2. **Python 3.x** — only needed if regenerating opcodes via `translate.py`.

### Build and run the emulator
```powershell
.\build.ps1              # compile fossauro.pb -> fossauro.exe
.\build.ps1 -R           # build then run
.\fossauro.exe -msx1               # boots to MSX1 BASIC
.\fossauro.exe -msx2+              # boots to MSX2+ BASIC
.\fossauro.exe -msx2               # loads the right BIOS but currently hangs before BASIC - see SPEC.md
.\fossauro.exe -verbose [rom.rom]  # writes fossauro.log; optionally load a cartridge
```

`fossauro.exe -help` prints the full fMSX-compatible CLI reference (most flags beyond
`-msx1`/`-msx2`/`-msx2+`/`-verbose`/cartridge loading are still accepted-but-inert placeholders — see the
CLI table in `docs/MANUAL.md`'s Fossauro section in the main repo for exactly which).

### Regenerate opcodes (only if touching `translate.py` or the C sources)
```bash
python translate.py
```

### Run the console regression harnesses
```powershell
pbcompiler fossauro_verify.pb /CONSOLE /OUTPUT fossauro_verify.exe
.\fossauro_verify.exe
```
Successful output loads `MSX.ROM`, validates its header, exercises the PPI/keyboard matrix, and reports
`SUCCESS: BIOS Loader & PPI/Keyboard verified successfully!`.
