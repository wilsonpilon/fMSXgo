# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

A native **PureBasic** IDE for MSX BASIC (the "Basic Dignified" dialect — labels instead of line
numbers, includes, macros, proto-functions) and Z80 assembly. It grew from a simple text editor and is
meant to become a self-contained `.exe` (no Python/other runtime dependencies) covering the whole MSX
dev workflow: editing, preprocessing/tokenizing, assembling, disk image management, and running/
debugging in the openMSX emulator.

**Codename (2026-08-13): "Paleobasic"** — `#App_Title` in `src/editor/BadigEditor.pb` (window title/About
dialog). Cosmetic only, no files or procedures were renamed. Internal modules also got prehistoric-theme
nicknames used in header comments/conversation (Raptor = preprocessor, Compsognato = tokenizer, Diplodoco
= disk manager, Pixelossauro = SCREEN 0/1/2 pixel editors, Pteranodonte = openMSX bridge, Mamute =
Z80 assembler, pre-existing). Full table in `README.md`. Do not confuse this with "Basic Dignified",
which stays the actual name of the input *dialect* (ported from the original Python project) — that one
is not being renamed.

**`docs/SPEC.md` is the source of truth for architecture and scope decisions** — read it before
proposing structural changes. `README.md` has a quick "what already exists" summary; the running,
session-by-session changelog lives in `CHANGELOG.md` (split out 2026-08-19, README had grown past 3000
lines). `docs/MANUAL.md` is the end-user guide (editor keybindings, disk manager, config screens).

## Commands

Primary development is on **Windows via PowerShell**; a **Linux build script (`build.sh`)** also exists,
meant to be run inside **WSL** against the same checkout, using the Linux `pbcompiler` binary (not
`pbcompiler.exe`) — same spirit as `build.ps1`, own gitignored `build.config.linux.json` for the
compiler path (kept separate from Windows' `build.config.json` on purpose). Its command-line flags are
**not** the same as Windows' `/FLAG` style — Linux `pbcompiler` uses hyphenated flags (`-o`/`--output`,
`-q`/`--quiet`, `-cl`/`--console`, `-co`/`--constant Name=Value`), confirmed 2026-07-29 by running
`pbcompiler -h` for real inside WSL. No `/ICON` embedding either way (PE-only resource, no Linux
equivalent). `editor/BadigEditor.pb` likely still has Windows-only API calls (WinAPI `gdi32`/icon
extraction, etc.) that would need `CompilerIf #PB_Compiler_OS` guards before a Linux build succeeds
fully end-to-end — not yet audited.

**Real cross-platform bugs found while getting `build.sh` to actually compile (2026-07-29)**:
- `XIncludeFile` deduplication by resolved file path (documented in module 2b of `docs/SPEC.md` as an
  established, relied-upon behavior on Windows) is **not guaranteed on the Linux `pbcompiler`** —
  `editor/BadigEditor.pb` includes `PsgSynth.pbi` directly *and* `editor/MmlSynth.pbi` (also pulled in
  by `BadigEditor.pb`) includes `PsgSynth.pbi` again; Windows silently deduped this, Linux raised
  `Structure already declared: PsgStepData`. Fixed at the source with an explicit include-guard idiom in
  `editor/PsgSynth.pbi` (`CompilerIf Not Defined(PSGSYNTH_PBI_INCLUDED, #PB_Constant)` wrapping the whole
  file body) instead of relying on implicit compiler dedup — safe regardless of platform/compiler
  version. If a similar "file A included both directly by `BadigEditor.pb` and indirectly through file
  B" pattern shows up elsewhere, apply the same guard rather than assuming Windows' dedup behavior
  holds.
- `editor/Screen2EditorGui.pbi` had one isolated `GetKeyState_(#VK_CONTROL)` (WinAPI, Windows-only) used
  during Screen2 TEXTO tool mouse-move to detect Ctrl-held-for-pixel-snap — replaced with
  `ExamineKeyboard()`/`KeyboardPushed(#PB_Key_LeftControl) Or KeyboardPushed(#PB_Key_RightControl)`
  (PureBasic's own cross-platform Keyboard library). Compiles clean on Windows; not yet confirmed on
  Linux.
**Real bugs found on Windows with the currently-installed `pbcompiler.exe` (PureBasic 6.40, 2026-08-04)**
— neither is cross-platform, both are worth knowing before assuming a fresh compile "just works":
- **`CopyMap()` crashes (access violation) when the source map is empty and its element type is
  byte/word-sized (`.b()`/`.w()`)** — confirmed with an isolated repro outside this project; `.i()`/
  `.s()` maps don't have the problem even empty. `Dig_Keeps()` (toggle-rem tracking,
  `DignifiedPreprocessor.pbi`) is exactly such a map and starts empty on the common path (any file with
  no `#toggle` marker), so this crashed `editor/tools/DigTestCli.exe` and would have crashed
  `RunOnOpenMSX()` on almost any real conversion — found only because `DigTestCli.exe` was actually
  recompiled and run this session, not just read; the version already committed in the repo predates
  this regression (built with a different PureBasic version/install, presumably). Fix in
  `Dig_ProcessSource`: only call `CopyMap()` when the source map's `MapSize()` is nonzero; `ClearMap()`
  on the destination already produces the same result an empty-source `CopyMap()` should. If you hit a
  mysterious access violation touching `CopyMap()` anywhere else in this codebase, check for the same
  empty-small-element-map shape before assuming it's a logic bug.
- **`pbcompiler.exe` decodes an `XIncludeFile`'d `.pbi` as Latin-1/CP1252 instead of UTF-8 if that
  specific file has no UTF-8 BOM** — confirmed the encoding is detected **per included file**, not once
  for the whole compilation unit: `editor/BadigEditor.pb` (the root file passed to the compiler) has a
  BOM, but that alone did **not** protect a BOM-less `XIncludeFile`'d `.pbi` from corruption. Any
  non-ASCII string *literal* (not comments — those get discarded either way, harmless) in a BOM-less
  `.pbi` gets mis-decoded: e.g. `Ç` (UTF-8 bytes `C3 87`) turns into two garbage characters (`Ã` +
  something), silently, with no compiler error. This had already corrupted real content before anyone
  noticed: 121 `→` navigation arrows across `OpenMsxHelpData.pbi`'s prose (openMSX help text) and
  box-drawing examples in `BasicDignifiedHelpData.pbi`, plus `Dig_TransOriginal`
  (`DignifiedPreprocessor.pbi`, the 128-char `-tr` translation table) itself. Fixed by prepending the
  3-byte UTF-8 BOM (`EF BB BF`) to every affected file — pure metadata, doesn't change content. **Any
  new `.pbi` file that gets a non-ASCII string literal needs a UTF-8 BOM** (most text editors add one
  automatically when you explicitly save as "UTF-8 with BOM"/"UTF-8 with signature" — plain "UTF-8"
  often does not); files with only ASCII content are unaffected either way, so adding a BOM defensively
  never hurts.

**Real bug found during a general bug/cohesion/performance review (2026-08-09, v7.33.1)** — the app's
native Windows dark-mode subsystem (`App_ApplyWindowIcon`/`App_DarkModeWindowProc`, `BadigEditor.pb`)
was silently dead on every theme since the 7-theme system replaced the old binary Dark/Light model
(`7.31.2`): `EditorCfg_Load()` migrates any legacy `"Dark"`/`"Light"` value away on load, but 8 call
sites (`BadigEditor.pb` + `SeeTrackerEditorGui.pbi`) still compared `EditorCfg\Theme = "Dark"` literally
— a value that could never occur again post-migration. Effect: `DWMWA_USE_IMMERSIVE_DARK_MODE` (dark
title bar), `SetWindowTheme_` "DarkMode_Explorer", and `WM_CTLCOLOREDIT`/`WM_CTLCOLORLISTBOX` field
coloring never activated on any of the 5 dark themes. Fixed with `EditorCfg_ThemeIsDark(ThemeId.s)`
(`EditorSettings.pbi`) instead of the string-literal comparison — **if you ever add a check against a
specific theme name, grep for `EditorCfg_ThemeIsDark` or the theme's exact string first**, since a
typo'd/stale literal like this fails silently (no compile error, no crash, just permanently-wrong
behavior that only shows up in a screenshot, not in code review). Also fixed a second, related bug the
code itself had marked as "abandoned": dialog labels (`TextGadget`) never got dark-mode text/background
colors because the attempted fix (`SetGadgetColor()` after looking up the gadget via
`GetDlgCtrlID_(hWnd)` in the `EnumChildWindows_` callback) doesn't work — `GetDlgCtrlID_` does not
return the PureBasic gadget number in that context, it returns something else entirely (internal struct
addresses, from the look of it). The actual fix needs no gadget number at all: handle `#WM_CTLCOLORSTATIC`
in the same window-proc subclass that already handles `#WM_CTLCOLOREDIT`/`#WM_CTLCOLORLISTBOX`
(`App_DarkModeWindowProc`) — standard Win32 technique, resolves at the message level, covers every
label in every dialog automatically. Both fixes verified with a real screenshot of the running `.exe`
(`PrintWindow` via a throwaway PowerShell P/Invoke driver — no project automation skill existed for
this native Win32 GUI, so one-off scripting was necessary), not just code inspection — this class of bug
does not show up from reading the source, per the project's own `7.31.4` history.

**Real crash found writing the Z80 disassembler (`L`/`LP` commands, 2026-08-12, `7.33.31`)** — a
`Procedure` with a `*OutText.String` out-parameter (the documented PureBasic idiom for "pass a string
by reference so the callee can write into the caller's variable", used via `*OutText\s = SomeLocalText`)
crashed with a genuine access violation (`0xC0000005`) the very first time it was called, in this
specific ~30,000-line single-compilation-unit `BadigEditor.pb`/`XIncludeFile` context — confirmed with a
step-by-step `WriteStringN`+`FlushFileBuffers` trace (`PrintN`/`Debug` don't reliably surface from this
environment's process launches, same lesson as the `--menuids` finding below) showing execution reaching
right up to `*OutText\s = Text` and dying exactly there, with everything before it (including computing
`Text` correctly, confirmed via the trace printing its final value) working fine. No `Structure`/
`Interface` named `String` exists anywhere in the codebase to explain it as a name collision — the root
cause was never fully isolated (may be specific to this file's size/nesting, or to `/CONSOLE` builds, or
a genuine PureBasic 6.40/6.41 bug with `.String`-typed out-parameters specifically), but the fix is
simple and now the established pattern for this codebase: **return the string as the Procedure's own
value (`Procedure.s Foo(...)`) instead of writing through a `*Ptr.String` out-parameter** — `*Ptr.Integer`/
`*Ptr.Byte`/etc. out-parameters are unaffected (used successfully throughout `MamuteSupport.pbi`, e.g.
`Mamute_ParseHexAddr`) and remain fine to use; it's specifically the `.String` pointer-write pattern that's
suspect here. If a future `Procedure` needs to output MULTIPLE strings at once (where a single return
value isn't enough), reach for a `Structure` return or a `List`/`Array` out-parameter instead of multiple
`*Ptr.String` out-parameters, until this is understood better.

**Real latent bug found in `Z80Asm.pbi`'s core 2-pass driver (2026-08-13, `7.33.34`)** — only surfaced
once the Mamute Assembler's `A` command started feeding it real source, but the bug was already present
in the shared engine (`RunOnePass`/`RunOnePassRel`) and would hit any caller who writes an `EQU`/`DEFL`/
`ASET` line with a colon-terminated label (`"CHPUT: EQU 0A2H"`). Both functions unconditionally define a
*positional* symbol at the current location counter whenever `HasLabel And LabelHasColon` is true,
**before** checking the operator — so a colon-labeled `EQU` line defines its own symbol twice: once
wrongly (at `CurLoc`) and once correctly (via the `EQU` branch immediately after). On pass 1 this
self-overwrites silently and produces the right final value; on pass 2, the wrong positional value
collides with the constant already committed at the end of pass 1 (different values → the "already
defined" guard in `DefineSymbolSeg`/`DefineSymbol` trips), producing a spurious `Simbolo ja definido (EQU
nao pode ser redefinido)` error on a program with a genuinely single, valid `EQU`. Never caught before
because every other consumer of this engine (the IDE's own "Montar Assembly", the whole `Z80AsmTestCli`/
`Z80LinkTestCli` regression suite) follows the classic M80/Nestor80 convention of writing `EQU` labels
**without** a colon (`"CHPUT EQU 0A2H"`, matching the `LabelHasColon` field comment itself) — Mamute's own
`EDIT` grammar is the first caller that always emits the colon form. **Fix**: both functions now skip the
positional-symbol definition when the line's operator is `EQU`/`DEFL`/`ASET`, regardless of colon — the
operator-specific branch already defines the symbol with the correct value either way. Verified with the
existing regression suite (`Z80AsmTestCli.exe`: 67/67; `Z80LinkTestCli.exe`: 7/7) plus a byte-for-byte
re-check of `sample/teste_opcodes.asm` against the real `N80.exe` oracle (identical) — the fix only
changes behavior for the previously-broken colon+constant-opcode combination, nothing already passing.
If you ever see `"Simbolo ja definido"` on what looks like a single valid `EQU`, check whether the label
has a colon before assuming it's a real duplicate.

**Real toolchain bug found generating the 8.1.5 distribution package (2026-08-18)** — a from-scratch
compile of `editor/BadigEditor.pb` on this machine always failed at the **linker** stage with
`error: undefined symbol: GetProcAddress`, even though the only change that session was a one-line
version-string bump; a minimal repro of the suspect code compiled fine standalone, which for a while
made it look like a scale-dependent linker bug in the full ~30,000-line file. Root cause, confirmed by
inspecting the `/COMMENTED` assembly output: `App_GetProcAddressOrdinal()`'s manual
`Import "Kernel32.lib" : ... As "GetProcAddress"` (near line 2818, used for dark-mode ordinal lookups —
see the `7.33.1` dark-mode entry above) emits an **undecorated** external symbol, but this machine's
`pbcompiler.exe` targets **x86 (32-bit)** (`pbcompiler /VERSION`), where the Windows stdcall ABI requires
**decorated** import names (`_Name@ArgBytes`) for anything not one of PureBasic's own built-in WinAPI
declares (those get decorated automatically; a manual `Import ... As "literal string"` does not). On x64
there's no decoration at all, so a plain `"GetProcAddress"` is correct there instead — likely why this was
never caught before, if the already-committed `editor/PaleoBasic.exe` was originally built with an x64
`pbcompiler.exe` on a different machine. **Fix**: wrapped the import name in
`CompilerSelect #PB_Compiler_Processor` (an `Import` block accepts `CompilerIf`/`CompilerSelect` inside
it) — `"_GetProcAddress@8"` (2 pointer-sized stdcall args = 8 bytes) under `#PB_Processor_x86`, the plain
name otherwise. Verified: compiles clean and the resulting `.exe` launches and responds normally
(screenshot-checked). **If any other manual `Import "x.lib" : Name(...) As "RealName"` ever fails to
link with "undefined symbol" specifically on an x86 build, this exact decoration gap is the first thing
to check** — see `docs/SPEC.md` module 32q for the full investigation.

```powershell
# Compiles BOTH executables every time (dist\PaleoBasic.exe from
# src\editor\BadigEditor.pb, and dist\fossauro.exe via src\fossauro\build.ps1 -
# fossauro is part of the project, not a side build, see 2026-08-20 entry
# below) and refreshes the rest of dist\ from resource\ (fonts/help images/
# tools/ROMs) unconditionally - there used to be a separate -D/--distribute
# flag gating that step; removed 2026-08-20, a single build now always
# produces the full package. Finds pbcompiler.exe automatically, or pass -C
# once and it's remembered in build.config.json, gitignored/machine-local.
.\build.ps1
.\build.ps1 -C "C:\Basic\Compilers\pbcompiler.exe"   # first time on a new machine
.\build.ps1 -R                                        # build then run
.\build.ps1 -V "5.4.0" -R                             # stamp a version + run
.\build.ps1 -H                                        # list all flags
```

```bash
# Linux counterpart, run from inside WSL (or any Linux shell) against the same repo checkout
./build.sh
./build.sh -C "/home/user/pb/compilers/pbcompiler"   # first time on a new machine
./build.sh -R                                         # build then run
./build.sh -H                                         # list all flags
```

**First-time WSL/Linux setup**: the PureBasic Linux compiler links against GTK3 (its GUI backend) plus
several libraries unconditionally (OpenGL/X11/OpenSSL) regardless of whether this codebase actually uses
them — a fresh WSL/Ubuntu install is missing all of these dev packages at link time. Found across two
rounds of real linker failures (2026-07-29): first `fontconfig`/`cairo`/`gtk+-3.0` not found via
pkg-config + `-lgmodule-2.0` not found; after installing those, a second round surfaced `-lGLU`/
`-lXxf86vm`/`-lssl`/`-lcrypto` also not found. Install once per machine (both rounds together, to save a
second round-trip next time):
```bash
sudo apt install libgtk-3-dev libcairo2-dev libfontconfig1-dev libglib2.0-dev \
                  libglu1-mesa-dev libxxf86vm-dev libssl-dev
```
Possibly not exhaustive — if another `-l<name>` shows up at link time, it's the same pattern (system dev
package missing, not a source bug); map the library name to its Ubuntu `-dev` package and add it here.

There is no automated test runner — verification happens through small standalone console harnesses in
`src/editor/tools/` (each is its own `.pb`, compiled separately with `/CONSOLE`, exercising one subsystem
without opening the GUI):

```powershell
# Compile a harness (same pbcompiler.exe as above)
& "C:\Basic\Compilers\pbcompiler.exe" src\editor\tools\DigTestCli.pb /EXE src\editor\tools\DigTestCli.exe /CONSOLE

src\editor\tools\DigTestCli.exe dist\sample\teste.dmx <out_prefix> tok   # Dignified -> ASCII (-> tokenized if "tok")
src\editor\tools\MSXDiskTestCli.exe <scratch_dir>                        # round-trips MSXDisk.pbi (create/add/list/extract/delete)
src\editor\tools\RunBasicTestCli.exe <entrada.dmx> <scratch_dir>         # reproduces the "Executar -> BASIC" disk-build pipeline
```

`dist/sample/teste.dmx` (~900 lines, real production code — "Change Graph Kit" by Fred Rique, not a
synthetic fixture) is the regression suite for the preprocessor/tokenizer: **run `DigTestCli` against it
after any change to `DignifiedPreprocessor.pbi` or `MsxTokenizer.pbi`** and diff the byte size / spot-check
output against the previous known-good result.

The disk tooling can also be exercised headlessly through the shipped `.exe` itself, which is often the
fastest way to validate `MSXDisk.pbi` changes:

```powershell
dist\PaleoBasic.exe --diskmanipulator create|list|add|extract|delete disco.dsk ...
```

## Architecture

**Top-level directory layout** (reorganized 2026-08-19, see `docs/SPEC.md` modules 35/36 for the full
rationale/mapping): `src/` (all compiled source — `src/editor/`, `src/fossauro/`), `dist/` (everything
the built app needs to run — `dist/PaleoBasic.exe` and `dist/fossauro.exe` both live at the *root* of
`dist/`, each looking up its own help/config/resources in the matching subfolder, `dist/editor/`/
`dist/fossauro/`; `dist/res/`, `dist/sample/`, `dist/projects/`, `dist/roms/` (Fossauro's system ROMs,
copyright — never tracked) sit alongside — versioned alongside the generated pieces `build.ps1`
refreshes, see Commands above), `resource/` (vendored/non-compiled assets the project owns — bundled
fonts, help-viewer images, external tool bundles, reference-only vendored trees like
`resource/openmsx/`, `resource/nestor/`, `resource/roms/` (canonical source for Fossauro's ROMs, also
never tracked)), `docs/` (all documentation, including `docs/fossauro/`), `others/` (zero-reference
directories kept only as deletion candidates, not part of the live project). Moving a file: compiled
source goes in `src/`, anything the running `.exe` reads goes in (or gets copied by `build.ps1` into)
`dist/`, everything else non-compiled that the project still owns goes in `resource/`. **Every runtime
path is computed relative to `GetPathPart(ProgramFilename())`** (the exe's own directory) — since both
exes sit at `dist/`'s root, editor-specific resources are looked up via an explicit `"editor\"` prefix
and fossauro-specific ones via `"fossauro\"` (see `FossauroDir()`, `FossauroSupport.pbi`), not a bare
filename or a `"..\"` climb like before this second layout pass.

**Single compilation unit.** `src/editor/BadigEditor.pb` is the only file passed to `pbcompiler.exe`;
every `.pbi` file is pulled in via `XIncludeFile` (textual inclusion, not a real module boundary) and
compiles into one `.exe` (`dist/PaleoBasic.exe` — the two exes now live at the root of `dist/`, each
looking up its own help/config in the matching subfolder, `dist/editor/`/`dist/fossauro/`).
`MSXDisk.pbi` is the one file using a real
`DeclareModule`/`Module` (`MSXDisk::`), so its calls are qualified. **`XIncludeFile` paths resolve
relative to the file containing the directive, not relative to the root `.pb`** (confirmed empirically
compiling a throwaway 3-file test case, 2026-08-19, before the directory reorg below) — this matters the
moment a `.pbi` in one `src/editor/<category>/` folder needs to `XIncludeFile` one in another (needs a
`../other_category/File.pbi` relative path; same-folder includes stay a bare filename).

**`EnableExplicit` + textual inclusion means declaration order is load-bearing.** Every `Global`/
`Structure` a later-included file reads must appear textually *before* that file's `XIncludeFile` line —
PureBasic does not hoist them. `BadigEditor.pb` already forward-`Declare`s a handful of procedures at
the very top for exactly this reason (dialog files included early need a procedure only defined much
later in the file). The same rule bit `Structure EditorSettings`/`Global EditorCfg` and the `Global
Color_*` tab/syntax colors (v7.31.4): almost every dialog `.pbi` is included near the top of the file
(before `EditorCfg`/`Color_*` used to be declared), but `ThemedButtons.pbi` (see below) — included right
after them, before any dialog file — needs both. Fix was to move the `Structure`/two `Global` blocks
themselves to the very top of `BadigEditor.pb`, before the first `XIncludeFile`, leaving the rest of
`EditorSettings.pbi`'s logic (defaults, load/save, the font-enum WinAPI code, the settings window) at its
normal include position — same idiom as the procedure `Declare`s already there, just for
`Global`/`Structure` instead of `Procedure`. If a future `.pbi` needs a `Global`/`Structure` that's
currently declared "further down" in `BadigEditor.pb`, this is the pattern: hoist the bare declaration,
not the logic that depends on it.

`src/editor/` is split into subfolders by logical function — `core/` (preprocessor/tokenizer/disk/
project/settings foundation), `assemblers/` (Mamute, Z80Asm engine, N80/Asmsx wrappers, linker),
`basic/` (Nestor Basic, MsxBas2Rom, BASIC-specific options), `emulators/` (openMSX bridge, Fossauro
bridge), `visual_editors/` (sprite/screen/charset/sound editors), `help/` (standalone reference-book
viewers — Red Book, BIOS calls, hardware, MSX manuals; feature-specific help like Mamute's or
NestorBasic's own stays alongside that feature's files instead), plus `tools/` (the console test
harnesses). A handful of representative files:

```
src/editor/BadigEditor.pb                    main window, menus, tab/document management, event loop, all XIncludeFile wiring
src/editor/core/DignifiedPreprocessor.pbi    Dignified source -> classic ASCII pipeline (see below)
src/editor/core/MsxTokenizer.pbi             classic ASCII -> tokenized MSX-BASIC binary (.bmx)
src/editor/core/MSXDisk.pbi                  FAT12 .dsk image read/write (DeclareModule MSXDisk)
src/editor/core/DiskManagerGui.pbi           "Criar -> Disco..." dual-pane disk manager window
src/editor/core/BadigSettings.pbi            "Configurar -> Basic Dignified..." settings + JSON persistence
src/editor/core/EditorSettings.pbi           "Configurar -> Editor..." settings (font/theme/tabs) + JSON persistence
src/editor/core/EditorSearch.pbi             Buscar/Substituir/Ir para linha (Ctrl+F/H/G, F3) - editor keybindings otherwise are plain Scintilla/Windows defaults
src/editor/core/EditorHelpGui.pbi            "Ajuda -> Editor..." static shortcuts reference window
src/editor/core/ThemedButtons.pbi            Macro ThemedButton()/#Icon_* - every dialog's buttons (ButtonGadget is native Win32 chrome, ignores Color_*) render as theme-colored images instead, with an optional real Nerd Font glyph icon
src/editor/core/FontDownloader.pbi           Nerd Fonts download picker
src/editor/assemblers/MamuteAssemblerGui.pbi "Executar -> Mamute Assembler..." monitor, see module 31
src/editor/emulators/OpenMSXBridge.pbi       real openMSX remote-control bridge (Tcl/XML), see module 12
src/editor/emulators/FossauroSupport.pbi     Fossauro (own emulator) launch + named-pipe client
src/editor/tools/*Cli.pb                     standalone console test harnesses, see Commands above
```

**The Dignified pipeline** (the core value of the project) is a from-scratch PureBasic **port** of a
reference Python implementation that lives in `badig/` (gitignored/submodule, downloadable from inside
the app via `Configurar -> Basic Dignified... -> Baixar...`). Treat `badig/` as a **behavior spec to
port, never a runtime dependency to call** — the `.exe` does not shell out to Python anywhere anymore
(that path existed early on and was fully removed once native parity was reached). When in doubt about
what some preprocessor step should do, the ground truth is `badig/`'s Python source and the
already-extracted notes in `docs/reference/*.md` (one file per original module: core engine, MSX
vocabulary, dignifier, emulator/tokenizer interfaces), not guesswork.

Pipeline stages, in order: **Dignified source (`.dmx`)** → `DignifiedPreprocessor.pbi` (labels, loop
labels, `EXIT`, recursive `DEFINE`, `DECLARE` name-shortening, `FUNC`/`RET` proto-functions, `INCLUDE`
with per-file label/variable namespacing, remtags) → **classic ASCII (`.amx`)** → `MsxTokenizer.pbi` →
**tokenized binary (`.bmx`)**, the format MSX-BASIC actually loads. `RunOnOpenMSX()` (in
`BadigEditor.pb`) then wraps the result plus a synthesized `AUTOEXEC.BAS` into a `.dsk` via `MSXDisk.pbi`
and launches openMSX with the configured machine/extension.

**MSXDisk.pbi** originated as a vendored copy of the user's separate `msxDiskUtil` project. As of
2026-07-28, `msxDiskUtil/` was removed from the repo — a runtime/build audit confirmed
`MSXDisk.pbi` is fully self-contained (no `XIncludeFile` reaching outside `src/editor/`) and the app
has zero dependency on the external directory; a Unicode `MatchesFAT11` bugfix that had only been
applied to the vendored copy was ported back into `msxDiskUtil/MSXDisk.pbi` before deletion, so the two
were in sync at removal time. `src/editor/core/MSXDisk.pbi` is now the sole source of truth for disk
format logic. It's exposed three ways: internally by
`RunOnOpenMSX()`, as a headless CLI (`PaleoBasic.exe --diskmanipulator ...`, detected at the very start
of the "Programa principal" section before any window opens), and as the graphical
`DiskMgr_OpenWindow()` (`DiskManagerGui.pbi`). The GUI tool stages all edits on a temp copy
(`GetTemporaryDirectory()`) and only writes the user's chosen `.dsk` on Salvar/Salvar como/Duplicar —
Cancelar discards the temp copy untouched. Left-panel/right-panel transfers in that tool are always
copies, never moves (deliberate: never delete the user's source file as a side effect).

**Settings screens** (`BadigSettings.pbi`, `EditorSettings.pbi`) persist to JSON next to the `.exe`
(`dist/editor/badig_settings.json`, `editor_settings.json`, both gitignored — machine-local) via
PureBasic's native `CreateJSON`/`LoadJSON`/`SaveJSON`, not by editing the reference `.ini` files under
`badig/` (those stay read-only reference material), with one exception: `emulator_path` gets patched
back into `emulator_interface.ini` because the original Python tool has no CLI flag for it.

**Verification approach**: this is a GUI-heavy PureBasic app with no unit test framework, so prefer the
`src/editor/tools/*Cli.pb` console harnesses (or the `--diskmanipulator` CLI) to validate logic changes —
they're fast, deterministic, and don't require driving the actual window. When live GUI verification is
unavoidable, prefer message-based automation targeted at a specific window handle (`WM_COMMAND` to a
menu ID, `BM_CLICK` to a button) over real cursor/keyboard input simulation or cross-process pointer
messages (`LVM_SETITEMSTATE`, `SCI_SETTEXT`) — the latter can hang or crash the target process, and real
input simulation acts on whatever is actually on screen for whoever is using the machine.
