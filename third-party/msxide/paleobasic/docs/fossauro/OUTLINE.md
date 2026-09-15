# OUTLINE.md - AI & Developer Continuation Guide

High-level hand-off document for continuing **fossauro** in a fresh session (different machine, new
Claude conversation, or another developer). Read `SPEC.md` first for full component status and the
prioritized "what's left" list — this file is about *how to work in this codebase efficiently*, not
what's done.

**Update 2026-08-18**: the plain-MSX2 boot freeze (this file's top priority as of 2026-08-17) is
**fixed** — see `SPEC.md` §2 "Fixed 2026-08-18" and `docs/SPEC.md` module 32j for the full investigation.
MSX1/MSX2/MSX2+ all boot to their BASIC prompts now. RAM/VRAM sizing and MegaROM mappers also landed the
same day (`SPEC.md` §2). Audio (`AY8910.pbi`/`StartAudio`/`StopAudio`) was already wired in but unverified
as of the `116752e` commit ("ainda falta audio") — now verified end-to-end via the new `audio_verify.pb`
harness (`SPEC.md`'s PSG entry, `docs/SPEC.md` module 32n). **SCREEN 6/7 rendering** landed the same day
(`SPEC.md`'s V9938 entry, `docs/SPEC.md` module 32o) — found and fixed a real pre-existing bug in the
process (`FillMemory()` calls missing PureBasic's `#PB_Long` size argument, silently corrupting any
non-grayscale border/background fill). **FDC/disk** (`FDC.pbi`, new) got as far as a fully implemented
and verified-in-isolation WD1793 (`fdc_verify.pb`: 4/4 tests pass, byte-exact against a real disk image)
before hitting a real, NOT-yet-fixed regression: mapping `DISK.ROM` into memory breaks MSX2/2+ boot
("Out of memory"/hang depending on whether a disk is mounted) — root cause not isolated, since this
machine has no `fMSX/fMSX/MSX.c` source to check the real memory layout against (only the binary ROMs).
`MSXLoadDiskROM()`'s call site is commented out until this is fixed; boot is confirmed back to normal
without it. See `docs/SPEC.md` module 32p for the full writeup and suggested next step. The single most
useful next action, picking this up fresh: either get real fMSX C source onto this machine and check
`StartMSX()`'s exact disk-ROM `MemMap[3][1][]` placement, or fall back to a PC-exact trace of the
boot-time slot-scan routine that diverges (same methodology as modules 32g/32j) if the C source isn't
available - the FDC layer itself needs no further work either way, only the memory placement does.

---

## 1. Project directory structure

- `E:\paleobasic\fossauro` (this directory):
  - `fossauro.pb` — entry point: window/canvas/menu, CLI parsing, cartridge loading, save-state
    serialization, main event loop.
  - `fossauro_verify.pb`, `basic_verify.pb` — console-based regression harnesses (Z80/BIOS/PPI).
  - `Z80.pbi` — CPU core (structures, `RunZ80()`, flag helpers).
  - `Z80_Tables.pbi`, `Z80_Codes*.pbi` — auto-generated from `fMSX/Z80/*.h` by `translate.py`. **Don't
    hand-edit the generated files for anything `translate.py` could instead be taught to do correctly**
    — re-running the generator keeps future re-translations consistent. Small one-off fixes (like the
    `EX (SP),HL` bug) are the exception, already applied directly and documented in `SPEC.md`.
  - `MSX.pbi` — motherboard: slots, RAM, PPI/keyboard, RTC, PSG/VDP port dispatch, BIOS loading.
  - `V9938.pbi` — VDP: registers, VRAM, rendering, sprites, command engine.
  - `AY8910.pbi` — PSG: per-sample synthesis, Win32 `waveOut` audio streaming thread.
  - `translate.py` — the C→PureBasic opcode translation pipeline (see section 3 below before touching).
  - `fMSX/` — reference material, **not compiled in**:
    - `fMSX/fMSX/*.c`/`*.h` — real fMSX C source. The ground truth for "what should this do".
    - `fMSX/EMULib/*.c`/`*.h` — real fMSX's hardware abstraction layer (Z80 core, AY8910, Sound.h).
    - `fMSX/*.ROM` — the actual BIOS/extended-BIOS files fossauro loads at runtime.
    - `fMSX/fMSX.exe` — **the real, working fMSX 6.0 Windows binary**. Use it constantly as a reference
      — run it side by side with fossauro and screenshot-compare. This caught more than one case of
      "fossauro looks wrong" that was actually real fMSX behavior too.

## 2. Key architecture decisions (read before changing shared state)

- **Callback prefixing**: `MSX.pbi`'s hardware callbacks are named `MSXRdZ80`/`MSXWrZ80`/`MSXInZ80`/
  `MSXOutZ80`/`MSXLoopZ80`/`MSXPatchZ80` to avoid colliding with the Z80 core's own global function-
  pointer variables (`RdZ80`, `WrZ80`, ...). They're wired together at startup/thread-start via
  `RealRdZ80 = @MSXRdZ80()` etc. — see `EmulationThreadProc()` in `fossauro.pb`, which re-asserts these
  on the emulation thread itself (not just the main thread) because a real crash was once traced to them
  being null there specifically.
- **`Z80` struct fields are plain values, no embedded pointers** (confirmed by inspection — this is
  exactly why the save-state feature can `WriteData(@CPU, SizeOf(Z80))` directly; same for `MMC`
  (`VDPCommandState`), `PSG` (`PSGState`), `PPI` (`I8255`)). If you ever add a pointer field to any of
  these structs, the snapshot code in `fossauro.pb` (`SaveSnapshot()`/`LoadSnapshot()`) needs updating
  too, since a raw pointer written to a save file is meaningless on reload.
- **`*MemMap()` pointers are never save/restore-able** — they're live process memory addresses. Anything
  that reconstructs machine state after the fact (save-state load, live model switching) must instead
  restore the *inputs* (`SSLReg()`, `PSLReg`, which ROM/RAM buffers are loaded) and then force `PSlot()`/
  `SSlot()` to recompute the derived pointers, exactly like a normal slot-select write would. See
  `LoadSnapshot()`'s `PSLReg = loadedPSLReg ! $FF` / `PSlot(loadedPSLReg)` trick — assigning `PSLReg`
  directly would skip `PSlot()`'s "did this change" guard and leave stale derived state.
- **PPI Port C row-select convention**: keyboard matrix rows are selected by the lower 4 bits of
  `PPI\Rout[2]`; Port C must be configured for output (`$82` to control port `$AB`) before this updates
  from writes to port `$AA`.
- **64-bit file handles**: `ReadFile(#PB_Any, ...)`'s return value must go in a `.i` variable, not `.l` —
  a real crash was traced to this truncation.
- **Scanline/interrupt timing** (`MSXLoopZ80` in `MSX.pbi`): active-display vs HBlank phases driven by
  CPU cycle counts derived from the MSX's 3.58MHz master clock; VBlank/line-coincidence trigger `SetIRQ`.

## 3. `translate.py` — the opcode-generation pipeline

If you ever need to regenerate `Z80_Codes*.pbi` (e.g. targeting a different fMSX version, or fixing a
class of bug at the source instead of patching generated output):

```bash
python translate.py
```

Constraints that matter, learned the hard way:
1. **Order of operator translation**: `!=` → `<>` and logical `!` → ` Not ` must happen *before* bitwise
   XOR `!` (from C's `^`) is parsed, or the XOR translation gets corrupted by the NOT-mapping step.
2. **`if` parsing is stack-based** (`replace_c_ifs`), not regex — C's nested parens (`if(!(AF & Z_FLAG))`)
   break naive regex group matching.
3. **Line continuation**: C splits long statements across lines; the preprocessor merges lines ending in
   `| & + - = , ( ? :` before translating.
4. **The recurring real-bug pattern**: C postfix `++`/`--` used *as a function-call argument* alongside a
   paired read/write of the same register (e.g. `EX (SP),HL`'s `SP.W++`/`SP.W--`). This was audited
   exhaustively across all four opcode files in a past session and found clean elsewhere, but if a new
   Z80 bug looks like "value read from `(HL)`/`(IX+d)` is stale or duplicated," check this pattern first
   before assuming it's a fresh translation bug.

## 4. Debugging methodology that actually works in this codebase

The MSX2/MSX2+ boot investigation (see `docs/SPEC.md` modules 32d–32i in the main repo for the full,
very long story) converged on a few techniques worth reusing rather than rediscovering:

- **Bounded, PC-exact temporary traces in `RunZ80()`** (`Z80.pbi`), not wide PC *ranges* — a range like
  "$0270-$028B" can span totally unrelated code visited at completely different boot phases, polluting
  the trace with irrelevant hits. Gate on an exact PC, and when needed, also gate on `*R\SP\W` falling in
  a known-good range to filter out incidental early-boot visits to the same address before the stack
  pointer is even meaningfully initialized (this exact mistake wasted real time in this session).
- **Read the return address straight off the stack** the first time a target PC is hit
  (`SafeRdZ80(*R\SP\W)` / `SafeRdZ80(*R\SP\W + 1)`, low/high byte) to find *who called this*, instead of
  guessing from static disassembly. This is how the RTC bug's true call chain
  (`$1F5` → `$353` → `$3A2`/`$270` → `$430` → `$3DF` → `$3E2` → `$F392`) was actually walked, one level
  at a time.
- **Check which ROM is actually mapped before disassembling.** The same 16-bit address can be completely
  different code depending on the current `PSLReg`/`SSLReg()` — a large chunk of one investigation was
  wasted disassembling `MSX2.ROM` at addresses that, at the moment of the real freeze, were actually
  mapped to `MSX2EXT.ROM` (Slot 3, different subslot) instead. Always capture `PSLReg`/`SSLReg(3)`
  alongside `PC` and cross-check which file's raw bytes at that offset actually match what's executing
  before trusting a disassembly.
- **`fMSX/fMSX.exe` is a screenshot away.** For "does real hardware even do this" questions (boot timing,
  visual sequences, whether something is a real bug or expected behavior), run it side by side and
  compare — cheaper than reasoning from first principles or C source alone.
- **`WM_COMMAND` via `SendMessage` to the window handle** is the reliable way to trigger a menu item
  programmatically (works for anything that doesn't pop a modal dialog). For features behind a modal file
  dialog (Open Cartridge, Save/Open Snapshot), add a temporary CLI-triggered headless test path instead
  of trying to automate the dialog — Windows' modern file dialogs are COM-based (`IFileDialog`), not
  simple child-window controls, and not worth fighting.
- **Always clean up temporary trace/test code before finishing a session** — grep the diff for leftover
  `Global ...TraceCount` declarations, stray blank lines from edits, etc. This has bitten a couple of
  passes in this project's history (see `git diff` hygiene notes in `docs/SPEC.md` module 32g).
- **Don't hand-simulate a loop's iteration count from a single static RAM dump — trace the real
  execution instead.** The LMMC feed-loop investigation (module 32j) hand-decoded a `DJNZ`/`PUSH BC`/
  `POP BC` outer-loop structure from one RAM snapshot and got the byte count wrong (concluded 8 bytes
  when the real number needed cross-checking); a targeted per-instruction trace gated on the exact PC
  range and frame window (same "bounded, PC-exact" principle as above, just logging every instruction in
  the range instead of only edge-transitions) settled it in one recompile instead of several more rounds
  of manual arithmetic.
- **When fossauro's synchronous/instant command model disagrees with what a real, hardware-validated ROM
  expects, check the real `fMSX/fMSX/V9938.c`/`MSX.c` source for what real hardware's own state machine
  actually does at that exact step** — don't assume fossauro's simplified model is a faithful shortcut.
  The LMMC "off by one" (module 32j) turned out to be exactly this: real fMSX's `VDPDraw()` calls the
  command engine once immediately at command start (consuming whatever was already latched in VDP
  register 44), so real ROMs correctly send `NX*NY-1` CPU feed bytes, not `NX*NY` — fossauro's model
  required the full `NX*NY` and could never complete. The C source was the fastest way to find this,
  faster than more rounds of guessing from symptoms alone.

## 5. Build & run

```powershell
.\fossauro\build.ps1              # compiles fossauro.pb -> fossauro.exe
.\fossauro\build.ps1 -R           # build then run
fossauro\fossauro.exe -msx1       # or -msx2 / -msx2+
fossauro\fossauro.exe -verbose    # writes fossauro.log (rotates at ~5MB, .log.1/.2/...)
```

No automated test suite beyond the console harnesses (`fossauro_verify.pb`/`basic_verify.pb`) — verify
changes by booting and screenshotting, same as the rest of this session's work.
