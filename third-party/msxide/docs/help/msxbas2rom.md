> Snapshot congelado da wiki oficial (github.com/amaurycarvalho/msxbas2rom/wiki), capturado em 2026-09-02.
> Pode ficar desatualizado com o tempo - para a versao mais recente, consulte a wiki diretamente.

# MSXBAS2ROM — MSX BASIC to ROM Compiler

> **Compile your MSX BASIC programs into ROMs with ease — for use in emulators or real MSX hardware.**  
> Fast, flexible, and open source.

---

## 🚀 Project Highlights

- **Latest release:** see the project [Releases](https://github.com/amaurycarvalho/msxbas2rom/releases) page;
- **Platforms:** Windows (32/64-bit), Linux, macOS;
- **Compilation modes:**
  - **Binary compiled** — the program will run faster but there's some compatibility limitations;
  - **P-code** — listable, highly compatible, but the program will run slower.
- **Integration:** Works with emulators like WebMSX, OpenMSX, and real hardware via SofaRUN, ODO, etc;
- **Open Source:** GPL-licensed, contributions welcome.

---

## 📚 Quick Reference

| Section                                                                  | Description |
|--------------------------------------------------------------------------|-------------|
| [Installation](Install) | OS-specific setup for Windows, Linux, and macOS |
| [Getting Started](Gettingstarted) | Install, write your first program, compile, and run |
| [Usage](Usage)         | Command line options, compilation modes |
| [Reference Guide](Documentation) | Detailed reference guide for MSXBAS2ROM |
| [Examples](Examples) | Ready-to-run code samples and complete games  |
| [Games published](Games) | Games made with MSXBAS2ROM |
| [Contributing](Contributing)         | How to help the project grow |
| [Branding & Credits](Branding) | Ways to acknowledge MSXBAS2ROM in your project |

---

## 🎮 How it Works

- 📹 [How MSXBAS2ROM compiles an MSX BASIC program](https://www.youtube.com/watch?v=MZtFPC9xleI) — *Overview of the compilation process* (Brazilian Portuguese);
- 📹 [Creating a game from scratch with MSXBAS2ROM – Part 1](https://www.youtube.com/watch?v=pig0B2hFZhk) — *Step-by-step game development* (Brazilian Portuguese).

More in the [**Demonstrations page**](Demonstration).

---

## 🕹️ Games Made with MSXBAS2ROM

Visit the [**Games page**](Games) to explore:

- **[MSX Adventure](https://sites.google.com/view/adventureparamsx/)** — Atari 2600 remake game;
- **[K-Jo Chases the Cheese](https://www.redbuttongames.com.br/index.php/games/kjo-msx)** — maze game;
- **[The 4 masters of melody Ex](https://www.clubemsx.com.br/product/the-4-masters-of-melody-ex/)** — memory game;
- **[PickinX](https://amaurycarvalho.itch.io/pickinx)** — arcade adaptation.

---

## 💡 Why Use MSXBAS2ROM?

- **Cross-platform**: build ROMs from any supported OS;
- **4 compilation modes**: flexibility between speed and compatibility;
- **ROM-ready output**: run in seconds on emulator or cartridge loader;
- **Developer-friendly**: open source, active maintenance.

---

## 📈 Project Status

> MSXBAS2ROM is an **active, evolving tool** — expect updates, new features, and community input.

---

## ❤️ Support the Project

If you enjoy MSXBAS2ROM, consider helping sustain its development:

- [ITCH.IO](https://amaurycarvalho.itch.io/) (games developed with MSXBAS2ROM!!!);
- [PATREON](https://www.patreon.com/msxbas2rom);
- [PAYPAL](https://www.paypal.com/donate?business=X793ZKW56SRBY&item_name=MSXBAS2ROM+compiler+project&currency_code=BRL);
- [CATARSE.ME](https://www.catarse.me/msxbas2rom_msx_basic_compiler_21ec);
- **Brazilian PIX**: contact me by email for more information.

Follow me on [LinkedIn](https://www.linkedin.com/comm/mynetwork/discovery-see-all?usecase=PEOPLE_FOLLOWS&followMember=amaurycarvalho).

---

## 📜 License

Released under the [GPL License](https://github.com/amaurycarvalho/msxbas2rom/blob/main/LICENSE).

---

> *MSXBAS2ROM — Bringing MSX BASIC into the ROM era.*


# Getting Help & References

Need support while working with MSXBAS2ROM? Here are your options:

---

## Built-in Documentation
```bash
msxbas2rom --version
msxbas2rom --doc
msxbas2rom --history
```

---

## Online Resources
- [Official Wiki Home](Home);
- [Getting Started Guide](Gettingstarted);
- [Usage Guide](Usage).

---

## Community
- Open issues on the [GitHub repository](https://github.com/amaurycarvalho/msxbas2rom/issues);  
  Use following prefixes on the issue description:
  - **[Feature]**: Request for a new feature;
  - **[Bug]**: Problem report;
  - **[Improvement]**: Enhancement of existing behavior;
  - **[Question]** or **[Discussion]**: Clarification or open-ended talk;
  - **[Asset]**: For new assets to be added to the project (ex: images, demos, games);
  - **[Task]**: General to-do or implementation detail.
- Contribute fixes or docs via [Contributing](Contributing).

# Getting Started with MSXBAS2ROM

> This guide will walk you through installing MSXBAS2ROM, creating a simple MSX BASIC program, compiling it into a ROM, and running it on an emulator or real MSX hardware.

---

## 📥 1. Install MSXBAS2ROM

Before starting, make sure you have MSXBAS2ROM installed on your system.

- **Windows** and **Linux** installation steps are detailed here: [Installation Guide](Install)

Once installed, you can verify the tool is available by running:

```bash
msxbas2rom -v
```

If the command displays a version number, you’re ready to continue.

---

## 📝 2. Create Your First MSX BASIC Program

Open your favorite text editor and create a plain text file named **hello.bas** with the following content:

```basic
10 PRINT "HELLO WORLD!"
20 END
```

Save the file in a working folder.

---

## ⚙️ 3. Compile the Program

MSXBAS2ROM supports **4 compilation modes**:

1. **Plain ROM compiled mode** *(default)* — generates a binary compiled Z80 code plain ROM for better performance (32K or 48K);
   - ExecROM is not compatible with 48K Plain ROM mode, so use SofaRUN or [ODO](http://msxbanzai.tni.nl/dev/software.html) loaders.
2. **ASCII8 MegaROM compiled mode** — generates a binary compiled Z80 code [MegaROM in ASCII8 format](https://www.msx.org/wiki/MegaROM_Mappers#ASCII_8K) (+128K, with a 2048K size limit);
3. **Konami SCC MegaROM compiled mode** — generates a binary compiled Z80 code [MegaROM in Konami SCC format](https://www.msx.org/wiki/MegaROM_Mappers#Konami_MegaROMs_with_SCC) (+128K, with a 2048K size limit);
4. **P-code mode** (DEPRECATED) — generates a p-coded MSX-BASIC ROM: program remains editable and listable in MSX BASIC interpreter but it will run slower (32K or 48K).

### Plain ROM compiled mode (default)
```bash
msxbas2rom hello.bas
```

### ASCII8 MegaROM compiled mode
```bash
msxbas2rom -x hello.bas
```

### Konami SCC MegaROM compiled mode
```bash
msxbas2rom -x --scc hello.bas
```

### P-code mode (deprecated)
```bash
msxbas2rom -p hello.bas
```

After running the command, you will get a file named **hello.rom** in the same folder.

---

## ▶️ 4. Run Your ROM

### Using an Emulator

You can quickly run your ROM in popular emulators:

- **[WebMSX](https://webmsx.org)** — just drag and drop the ROM file into emulator screen;
- **[OpenMSX](https://openmsx.org/)**:
```bash
openmsx hello.rom
```

### On Real Hardware

Copy the ROM file to an SD card or storage device supported by your MSX setup and use a loaders such as **[SofaRUN](https://www.louthrax.net/mgr/sofarun.html)** or **[ODO](http://msxbanzai.tni.nl/dev/ODOV04.LZH)**.

---

## 🧠 5. Tips & Notes

- **File names**: Keep your file names MSX-compatible (8.3 format) to ensure proper loading on all systems;
- **Testing**: Run your ROM on both emulator and real hardware for compatibility;
- **Compilation mode choice**:
  - Use **Plain ROM compiled mode** for small or medium projects;
  - Use **ASCII8 MegaROM compiled mode** for larger projects;
  - Use **Konami SCC MegaROM compiled mode** for projects that need native SCC support.

See [Compiler Architecture](Compiler-Architecture) for more information.

---

## 📚 Next Steps

- Learn more commands and options in the [Usage Guide](Usage);
- Read the [Reference Guide](Documentation) for more detailed information; 
- Explore the [Examples](Examples) page for code examples;
- Check out [Games published](Games) to see what’s possible.

---

> *MSXBAS2ROM — Bringing MSX BASIC into the ROM era.*

# Installation Guide — MSXBAS2ROM

> Get MSXBAS2ROM up and running on your system—whether through package managers or manual downloads.

---

## 📦 Available Installation Methods

### 1. Linux via PPA (recommended)

For Ubuntu and derivatives, install directly from the official PPA:

```bash
sudo add-apt-repository ppa:amaurycarvalho/msxbas2rom
sudo apt-get update
sudo apt-get install msxbas2rom
```

This ensures MSXBAS2ROM will receive updates automatically.

---

### 2. Linux via .DEB or .RPM packages

For most Linux distributions you can install it using Debian or RPM packages downloaded from [Releases Page](https://github.com/amaurycarvalho/msxbas2rom/releases).

1. Debian package:

```bash
sudo dpkg -i msxbas2rom.deb
```

2. RPM package:

```bash
sudo rpm -ivh msxbas2rom.rpm
```

---

### 3. Windows, Linux & macOS via Pre-built Releases

Pre-built binaries are available on the GitHub [Releases Page](https://github.com/amaurycarvalho/msxbas2rom/releases).

1. Navigate to the "Assets" section of the latest release;
2. Download the appropriate `msxbas2rom` executable for your platform;
3. (Optional) Extract the archive if needed;
4. Place the executable in your system’s PATH—for example:
   - **Linux/macOS:** `/usr/bin/`
   - **Windows:** `%USERPROFILE%\msxbas2rom\` (then add to PATH)


---

## ✅ Verification

After installation, confirm everything is working:

```bash
msxbas2rom -v
```

For parameters help:

```bash
msxbas2rom -h
```

You can also view all available command-line documentation via:

```bash
msxbas2rom --doc
```

These commands verify that the tool is properly installed.

---

## 🍏 macOS / Source Build Instructions

If no pre-built binaries are available for your system—or you prefer building from source—follow these steps:

1. [Clone the repository](https://github.com/amaurycarvalho/msxbas2rom.git) and ensure development dependencies are installed;
2. On **macOS**, remove or wrap out deprecated includes like `malloc.h` to avoid build errors;
3. Run the following:

```bash
make all
```

4. Upon success, find the binary under the `bin/Release/` directory.

---

## 📊 Summary Table

| Method                     | Platforms          | Notes                                       |
|----------------------------|-------------------|---------------------------------------------|
| PPA (apt)                  | Ubuntu/Linux      | Auto-updates, simplest for Linux users      |
| DEB or RPM                 | Linux      | Easy way for Linux users      |
| Pre-built Release          | Windows/Linux/macOS     | Manual download, flexible placement         |
| Build from Source (macOS)  | macOS (+ others)  | Recommended if no binaries are available    |

---

## 📚 What’s Next?

Proceed to the [Getting Started](Gettingstarted) guide to write, compile, and run your first MSX BASIC program using MSXBAS2ROM.

---

> *MSXBAS2ROM — Bridging MSX BASIC and ROM development with ease.*


# Usage Guide — MSXBAS2ROM

> Learn how to compile MSX BASIC programs into ROM files.

---

## 🖥 Basic Syntax

The simplest way to use **MSXBAS2ROM** is via the command line:

```bash
msxbas2rom program.bas
```

This will convert `program.bas` into `program.rom` using default settings.

When compiling, ensure that:

- **Source file** is in plain text MSX BASIC format (`.BAS`);
- **Assets** (images, sprites, sounds) are in accessible paths if referenced;
- **Output path** is writable.

---

## ⚙️ Syntax and Options

```bash
msxbas2rom [options] <filename.bas>
```

- **General options**:

| Option          | Description                                                                 |
|-----------------|----------------------------------------------------------------------------|
| -h or --help | help |
| -q or --quiet | quiet (no verbose) |
| -d or --debug | debug mode (show details) |
| -D or --doc | display quick reference guide |
| -H or --history | display app history |
| -v or --version | display app version |

- **Compile options** (optional):

| Option          | Description                                                                 |
|-----------------|----------------------------------------------------------------------------|
| -c | plain ROM compile mode (DEFAULT) |
| -a or --auto | auto mode (fallback to ASCII8 when plain ROM overflows) |
| -x or -8 or --ascii8 | [ASCII8](https://www.msx.org/wiki/MegaROM_Mappers#ASCII_8K) MegaROM mapper |
| -6 or --ascii16 | [ASCII16](https://www.msx.org/wiki/MegaROM_Mappers#ASCII_16K) MegaROM mapper (limited support) |
| -7 or --ascii16x | [ASCII16-X](https://www.grauw.nl/projects/ascii-x/ascii16-x/) MegaROM mapper (limited support) |
| -4 or --konami | [Konami](https://www.msx.org/wiki/MegaROM_Mappers#Konami_MegaROMs_without_SCC) MegaROM mapper |
| -k or --scc | [Konami SCC MegaROM](https://www.msx.org/wiki/MegaROM_Mappers#Konami_MegaROMs_with_SCC) MegaROM mapper |

- **Path options** (optional):

| Option          | Description                                                                 |
|-----------------|----------------------------------------------------------------------------|
| -i | input path (default=source file path) |
| -o | output path (default=source file path) |

- **Special options** (optional):

| Option          | Description                                                                 |
|-----------------|----------------------------------------------------------------------------|
| -s | generate [symbols](Usage#7-compile-and-generate-symbols-for-openmsx-debugger) for Z80 debugging (default format: .noi) |
| --noi or --noice | generate symbols in .noi format ([OpenMSX](https://openmsx.org/)) |
| --cdb | generate symbols in .cdb format (sdcc) |
| --symbol | generate symbols in .symbol format (pasmo) |
| --omds | generate symbols in .omds format (openMSX deprecated) |
| --lin | write the MSX-BASIC line numbers in the binary code |
| --vscode | initialize a VSCode MSX-BASIC project in the current path |

- **P-code options** (DEPRECATED):

| Option          | Description                                                                 |
|-----------------|----------------------------------------------------------------------------|
| -p | tokenized p-code mode |
| -t | turbo mode (or use CALL TURBO instructions) |
| --nsr | no strip remark lines (tokenized/turbo mode) |

Output:

`<filename.rom>`

You can combine multiple options in a single command.

---

## 🚀 Examples

### 1. Show help

```bash
msxbas2rom -h
```

### 2. Show version

```bash
msxbas2rom -v
```

### 3. Show documentation

```bash
msxbas2rom --doc
```

### 4. Compile with Default Settings

```bash
msxbas2rom program.bas
```

It's equivalent to code below:

```bash
msxbas2rom -c program.bas
```

Also, you can send the ROM output to a target folder:

```bash
msxbas2rom -o /target_folder/subfolder program.bas
```

### 5. Compile to ASCII8 MegaROM

```bash
msxbas2rom -x program.bas
```

### 6. Compile to Konami SCC MegaROM

```bash
msxbas2rom -x --scc program.bas
```

### 7. Compile and generate symbols for OpenMSX debugger

Command lines below will generate the following symbols files:

- **.symbol**: [pasmo assembler](https://pasmo.speccy.org/) symbol format;
- **.omds**: xml format for use with the [old OpenMSX standalone debugger](https://github.com/openMSX/debugger) or import it in another tools;
- **.noi**: NoICE format for use with the [new OpenMSX integrated debugger](https://openmsx.org/).

```bash
msxbas2rom -s program.bas
msxbas2rom -x -s program.bas
msxbas2rom -x -s --scc program.bas
```

Learn more about debugging your MSX-BASIC program [here](Debugging_with_OpenMSX).

---

## 📚 Next Steps

- Read the [Reference Guide](Documentation) for more detailed information; 
- Explore the [Examples](Examples) page for code examples;
- Check out [Games published](Games) to see what’s possible.

---

> *MSXBAS2ROM — From BASIC to ROM in a single command.*

# Compiling Code

This section explains how to compile MSX BASIC programs into ROMs using **MSXBAS2ROM**.

---

## Basic Compilation
```bash
msxbas2rom [options] <filename.bas>
```

- Generates `<filename.rom>` as output.
- Default mode is **compile** (`-c`) generating a 32k or 48k ROM file.

## Examples
```bash
msxbas2rom mygame.bas
msxbas2rom -c mydemo.bas
```

For advanced options, see the [Usage Guide](Usage).

---

## Statements supported:

```text
     DEFDBL, DEFINT, DEFSNG, DEFSTR, DIM,
     REM, END, CLS, BEEP, PRINT, INPUT, LINE INPUT,
     GOTO, GOSUB, RETURN, SOUND, PLAY,
     RANDOMIZE, LET, FOR/NEXT, DATA, READ, RESTORE,
     IF/THEN/ELSE, IF/GOTO/ELSE, IF/GOSUB/ELSE,
     LOCATE, COLOR, SCREEN, WIDTH, PSET, PRESET,
     LINE, CIRCLE, PAINT, DRAW, OUT, POKE, VPOKE
     SPRITE$, PUT SPRITE, ON...GOSUB, ON...GOTO,
     SWAP, WAIT, ON INTERVAL GOSUB, INTERVAL ON/OFF,
     ON KEY GOSUB, KEY ON/OFF, KEY() ON/OFF,
     ON STRIG GOSUB, STRIG() ON/OFF,
     ON SPRITE GOSUB, SPRITE ON/OFF,
     SET SCROLL, SET PAGE, PUT TILE,
     SET TILE COLOR, SET TILE PATTERN,
     DEF USR, PRINT USING
```

---

## Statements supported partially only:

```text
     STOP, STOP ON/OFF, ON STOP GOSUB, 
     COPY, OPEN, CLOSE, MAXFILES, BLOAD,
     SET VIDEO, COPY SCREEN,
     CLEAR
```

---

## Functions supported:

```text
     INT, FIX, RND, SIN, COS, TAN, ATN, EXP,
     LOG, SQR, VAL, TIME, SGN, ABS, ASC, INKEY,
     LEN, CSNG, CDBL, CINT, CHR$, INKEY$, INPUT$,
     SPACE$, SPC, TAB, STRING$, STR$, LEFT$, RIGHT$, MID$,
     INSTR, OCT$, HEX$, BIN$, PEEK, VPEEK, INP, POS, LPOS,
     CSRLIN, STRIG, STICK, PDL, PAD, BASE, VARPTR,
     PLAY, VDP, POINT, COLLISION, FRE, HEAP, TILE,
     RESOURCE, USR, PSG, MSX, NTSC, TURBO, MAKER,
     USING$, PLYSTATUS

     TIME and MID$ assignments
     VDP assignment
```

---

## Data types, operators and operations supported:

```text
     Integer, Float, String, Fixed Bidimensional Arrays
     Math expressions and basic operators (+-*/^)
     OR, AND, XOR, EQV, IMP, NOT, MOD, SHL, SHR
     &h0000, &o0000, &b00000000
```

### Internal Data Types

| BASIC Type | Example | Internal Representation | Range | Notes |
|-------------|----------|--------------------------|-------|-------|
| **Integer** (`%`) | `A% = 42` | 16-bit signed integer | `-32768` to `+32767` | Fastest type; ideal for counters, indexes, logic control |
| **Single** (`!`) | `A! = 3.1415` | 24-bit IEEE-like real | about 4.5 digits | Used for precise math operations; slower |
| **Double** (`#`) | `A# = 3.1415` | — | — | Same as Single; Double precision is not available. |
| **String** (`$`) | `A$ = "HELLO"` | 1 byte length + 255 bytes data | 0-255 characters | Sequences of ASCII characters (pascal style); flexible but heavier |
| **Array** | `DIM A(10)` or `DIM B$(5)` | Linear contiguous memory structures | RAM available space | Supports both numeric and string arrays; 2 dimension only |

📝 Notes:

- **Integers** are 16-bit signed values stored in little-endian order (`LSB + MSB`). This type is optimized for speed and memory efficiency, being the default choice for most arithmetic and control structures;
- **Single** and **Double** are floating numbers in a [special format 3-byte value](https://www.msx.org/wiki/Category:X-BASIC#Floating_points). It's accuracy is about 4.5 digits. Double precision is not available. Slower than integers due to floating-point math library calls. Prefer integer arithmetic for loops and counters when possible;
- **Strings** store sequences of ASCII characters (pascal style). Use short, fixed-length strings when possible. Avoid heavy concatenations inside loops;
- **Arrays** are linear contiguous memory structures, with each element represented by the base type (integer, float, or string).

---

## Limitations and differences:

Some tradeoffs and differences from MSX BASIC's behavior were necessary to improve the fast execution of compiled code. One of these was the imposition of a [strong type system](https://en.wikipedia.org/wiki/Strong_and_weak_typing).

See other important points below.

```text
     - Minimum hardware requirements for compiled programs:
       * MSX1 machine (with ROM BIOS and ROM BASIC);
       * 16K of RAM for running as Cartridge without resources;
       * 32K of RAM for running as Cartridge with resources;
       * 64K of RAM for running with ExecROM (for 32K ROMs) or ODO
         (for 48K ROMs) via disk driver or Caslink3/CASDuino/MSX2CAS
         via cassete;
       * 64K Memory Mapper and/or MegaRAM for running with SofaRun;
       * MegaROM compiled mode needs a Memory Mapper and/or MegaRAM with
         at least the same size as the final ROM for running it in memory
         with ExecROM (note: not required for running as ASCII8 or Konami SCC
         Cartridge in emulators);
     - Partial file support (OPEN "GRP:", PRINT #...);
     - No dynamic arrays (REDIM);
     - No variant data type (only string, integer and single);
     - All variables has an unique data type (dont change in runtime);
     - Variables are not initialized at startup (do it yourself);
     - Default data type is single (use DEFINT A-Z to modify it to integer);
     - Singles cannot be used with boolean operations;
     - Printing numerical decimal values above 9999 will result in
       scientific notation;
     - Printing will not wrap the full numeric data on the next line, 
       instead it will just wrap the characters that don't fit.
     - CIRCLE tracing and aspect parameters not supported;
     - STOP works like END;
     - CLEAR works without parameters;
     - LOCATE/PRINT works in graphical mode (screen 2+) without use of
       OPEN 'GRP:'. When in screen 2 tiled mode, it works similar as text
       mode coords (faster output);
     - COPY works only with graphical parameters (no files support) just
       like: COPY (x0,y0)-(x1,y1) TO (x2,y2);
       COPY ... TO <ram address> / COPY <ram address> TO ... is accepted
       instead of COPY <array>... (try HEAP() as <ram address>);
       When in screen 2 tiled mode, it works with text mode coords;
     - BLOAD works only to load standard screen files (.SCn) and TinySprite
       compatible files (.SPR). You need to inform a file name as literal (no
       via variables) because it will be loaded into ROM (it will activate
       MegaROM mode). Ex: BLOAD "file.sc5", S;
     - DATA statements allocate space in resources page and will be compiled to
       a 48K ROM when Plain ROM mode;
     - PRINT USING support only numerical formatting symbols (#+-.*$,^0) and
       works the same way as USING$() function. For exponential display,
       include more # in the format string until the correct value is
       displayed. Use 0 char symbol to fill the value with left zeros;
     - SET/GET DATE and SET/GET TIME adopts a customized syntax;
     - F1..F10 function keys return ASCII codes 246 to 255 respectively;
     - Spaces on your line code, REMs and blank lines not affect compiled code
       size, but if your include it on your program it can help the compilation
       process (not need for strip spaces from your code anymore);
     - Compiled code on Plain ROM mode is limited to a maximum of 16K. There's no 
       specific limitation on MegaROM mode;
     - Resources total size on Plain ROM mode are limited to 16K (for FILE directive), and
       when compiled generates 48K ROMs thats can run as cartridge or in RAM
       with SofaRUN or ODO loaders (ExecROM do not support this ROM size). On MegaROM mode, 
       where the ROM size limit is 2048K, the theorical limitation is around to 3200 resources 
       (v0.3.3.2 and above).
```

---

## Statements not supported:

```text
     AUTO, BLOAD, BSAVE, CALL, CLOAD,
     CONT, CSAVE, DEF FN, DELETE, EOF, ERASE,
     ERL, ERR, ERROR, FILES, FN, FPOS, FIELD,
     GET, GET DATE, GET TIME, IPL, LIST, LLIST,
     LOAD, LOC, LSET, LPRINT, MERGE, RSET,
     MOTOR, NEW, PUT, PUT KANJI, RENUM, RUN, SAVE,
     SET ADJUST, SET BEEP, SET DATE, SET PASSWORD,
     SET PROMPT, SET SCREEN, SET TIME,
     SET TITLE, TROFF, TRON,
     RESUME, ON ERROR GOTO
```

---

📌 See also [Compiler Architecture](Compiler-Architecture), [Resource Directives](Resource-Directives), [Extended Commands](Extended-Commands) and [Extended Functions](Extended-Functions).


# Extended Commands

MSXBAS2ROM extends MSX BASIC with **new commands**.

---

## Why Use Extended Commands?
- Performance optimizations;
- Features unavailable in classic BASIC;
- Better integration with modern tools.

---

## Examples

### General Extended Commands

```basic
10 CMD TURBO 1
20 IF TURBO() THEN PRINT "TURBO MODE IS ON" : END
30 PRINT "CANNOT START TURBO MODE (IS IT A TURBO R OR PANASONIC MACHINE?)"
```

### Memory Extended Commands

```basic
10 SCREEN 1
20 BA% = BASE(5)                           ' screen 1 name table vram address
30 M$ = "HELLO WORLD"
40 S% = LEN(S$)
50 MA% = VARPTR(M$) + 1                    ' message address in RAM 
60 CMD RAMTORAM MA%, HEAP(), S%            ' copy message to next free memory in RAM
70 CMD RAMTOVRAM HEAP(), BA%, S%           ' copy message to screen
80 END
```

### Screen Extended Commands

```basic
FILE "SCREEN.SC2"   ' resource 0
FILE "SCREEN.SC5"   ' resource 1
10 SCREEN 2
20 SCREEN OFF
30 SCREEN LOAD 0
40 SCREEN ON
50 A$ = INPUT$(1)
60 SCREEN 5
70 SCREEN OFF
80 SCREEN LOAD 1
90 SCREEN ON
100 A$ = INPUT$(1)    
```

### Screen Tiled Mode and Fonts Extended Commands

```basic
10 SCREEN 2
20 SET FONT 1
30 PRINT "HELLO WORLD"
40 A$ = INPUT$(1)
50 END
```

### Sprite Extended Commands

```basic
FILE "SPRITE.SPR"
10 SCREEN 2
20 SPRITE LOAD 0
30 PUT SPRITE 0,(100,100),15,0
40 IF INKEY = 0 THEN 40
50 END
```

### Data Commands

#### Reading plain text files

```basic
FILE "TEXT.TXT"
10 CMD RESTORE 0
20 READ L$ : PRINT L$
30 READ L$ : PRINT L$
40 RESTORE 0   ' reposition to first line of file
50 READ L$ : PRINT L$
```

#### Reading CSV files

```basic
FILE "DATA.CSV"
10 CMD RESTORE 0
20 READ S$
30 IF S$="*" THEN END
40 PRINT S$
50 GOTO 20
```

#### Reading binary files as integers

```basic
FILE "data1.bin"
FILE "data2.bin"
FILE "data3.bin"
10 CMD RESTORE 0  ' 1st file resource
15 IRESTORE 0     ' reposition to file start (byte %0)
20 IREAD A%, B% 
30 PRINT A%, B%
40 CMD RESTORE 1  ' 2nd file resource
45 IRESTORE 2     ' reposition to byte #2 
50 IREAD A%, B% 
60 PRINT A%, B%
70 CMD RESTORE 2  ' 3rd file resource
75 IRESTORE 4     ' reposition to byte #4
80 IREAD A%, B% 
90 PRINT A%, B%
```

---

## Complete List

### General Extended Commands

```text
  Turn off keyboard clicks alternative

    CMD KEYCLKOFF

  Clear keyboard buffer and reset joysticks ports

    CMD CLRKEY

  Activate cpu turbo mode (R800 or 5.37mhz)

    CMD TURBO <0=off | 1=on>

    Note: works only with TurboR or MSX2 Panasonic machines.

  Exec a binary uncompressed resource as an assembly code

    CMD RUNASM <resource number>

    - There is a limit of 256k for the Assembly code;
    - All jumping instructions must be relative (JRs instead of JPs);
    - No CALLs to addresses inside the program are allowed.

  Exec a text resource as a plain text basic code (must start with ':')

    CMD RUNBAS <resource number>

  Play a text resource with Basic

    CMD PLAY <resource number>[, <channel C: 0=off|1=on>]

    note: channel C will be disabled to use with SOUND command

  Mute the PSG (for PLAY use)

    CMD MUTE

  Draw a text resource with Basic 

    CMD DRAW <resource number>

  SET/GET DATE/TIME customized syntax

     SET DATE iYear%, iMonth%, iDay%
     SET TIME iHour%, iMinute%, iSecond%
     GET DATE iYear%, iMonth%, iDay% [, iWeekDay% [, iDateFormat%]]
     GET TIME iHour%, iMinute%, iSecond%

     Code Date Format
     0    YY/MM/DD
     1    MM/DD/YY
     2    DD/MM/YY

     Week day: 0=Sunday
```

### Memory Extended Commands

```text
  Write RAM to VRAM address

    CMD RAMTOVRAM <RAM address>, <VRAM address>, <size>

  Write VRAM to RAM address

    CMD VRAMTORAM <VRAM address>, <RAM address>, <size>

  Write RAM to RAM address

    CMD RAMTORAM <RAM source address>, <RAM dest address>, <size>

  Write RESOURCE to RAM address

    CMD RSCTORAM <resource>, <dest address> [, <pletter? 0=no, 1=yes>]

```

### Screen Extended Commands

```text
  Inhibits the screen display

    SCREEN OFF
        
    Also: CMD DISSCR

  Display the screen

    SCREEN ON
        
    Also: CMD ENASCR

  Enable/disable a page alternating effect on screen mode 5 and above via VDP R#1 (Cadari Bit) and R#13. Pass 0 to stop the effect.

    CMD PAGE <mode: 0=swap, 1=wave>, <delay #1: 0-15, 0=stop> [, <delay #2: 0-15, default=same as delay #1>]

  Load and display a screen resource

    SCREEN LOAD <resource>
    
```

### Screen Tiled Mode and Fonts Extended Commands

```text
  Fill screen 2 with spaces to use with SETFNT/PRINT

    CMD CLRSCR

  Load internal FONTs to VRAM font pattern table (screen mode >= 1)

    SET FONT <style number>[, <bank:0-2|empty=all>]
      0 = BIOS default font
      1 = Compile Zanac Style
      2 = Konami Gradius Style 1
      3 = Konami Gradius Style 2

    Also: CMD SETFNT <style number>[, <bank:0-2|empty=all>]

  Update tiled font color with current fore/background COLOR

    CMD UPDFNTCLR

  Set clipping on and off (screen modes 5 through 8, and same as '#C of xbasic)

    CMD CLIP <0=off | 1=on>

  Put a tile character into screen position (for tiled mode, screens 0-2)

    PUT TILE <n>, (<x>,<y>)

  Set/Get tile color (for tiled mode, screens 1, 2 and 4)

    SET TILE COLOR <n>, <forecolor>, <backcolor> [, <bank:0-2, default=3=all>]

    SET TILE COLOR <n>, (<fc0>,...,<fc7>) [, (<bc0>,...,<bc7>) [, <bank:0-2, default=3=all>]]

    SET TILE COLOR <n>, <4 integers color buffer array source> [, <bank:0-2, default=3=all>]

    GET TILE COLOR <n>, <4 integers color buffer array dest> [, <bank:0-2, default=0>]

  Set/Get tile pattern (for tiled mode, screens 0, 1, 2 and 4)

    SET TILE PATTERN <n>, (<l0>,...,<l7>) [, <bank:0-2, default=3=all>]

    SET TILE PATTERN <n>, <4 integers pattern buffer array source> [, <bank:0-2, default=3=all>]

    GET TILE PATTERN <n>, <4 integers pattern buffer array dest> [, <bank:0-2, default=0>]

  Flip a tile pattern

    SET TILE FLIP <n>, <dir: 0=horizontal, 1=vertical, 2=both> [, <bank:0-2, default=3=all>]

  Rotate a tile pattern

    SET TILE ROTATE <n>, <dir: 0=left, 1=right, 2=180 degrees> [, <bank:0-2, default=3=all>]

  Enable/Disable tiled mode (screens 2 and 4, for use with PRINT)

    SET TILE <ON|OFF>

  Copy screen to array (only for modes 1, 2 and 4)

    SCREEN COPY TO <array> [SCROLL <direction>]

    *direction = same as STRIG
  
  Copy array to screen (only for modes 1, 2, and 4)

    SCREEN PASTE FROM <array>
  
  Do a screen scroll (only for modes 1, 2 and 4)

    SCREEN SCROLL <direction>

    *direction = same as STRIG
    
```

### Sprite Extended Commands
> See a more detailed example for SET/GET SPRITE [here](https://github.com/amaurycarvalho/msxbas2rom/blob/master/test/integration/GRAPH/test94.bas) and [here](https://github.com/amaurycarvalho/msxbas2rom/blob/master/test/integration/GRAPH/test96.bas).

```text
  Load a TinySprite (msx.jannone.org) compatible resource (.SPR)

    SPRITE LOAD <resource>

    - Export your sprites as a Backup and save it as .SPR text file;
    - Use with sprite parameter size 2 or 3 on SCREEN statement;
    - You can use, alternatively: BLOAD "file.spr",S

  Set/Get sprite color 

    SET SPRITE COLOR <n>, <8 integers color buffer array>
    GET SPRITE COLOR <n>, <8 integers color buffer array>
      Example: 
        10 DIM CB%(7)
        20 GET SPRITE COLOR 0, CB%
        30 SET SPRITE COLOR 1, CB%
        
  Set/Get sprite pattern

    SET SPRITE PATTERN <n>, <16 integers pattern buffer array>
    GET SPRITE PATTERN <n>, <16 integers pattern buffer array>
      Example: 
        10 DIM PB%(3,3)
        20 GET SPRITE PATTERN 0, PB%
        30 SET SPRITE PATTERN 1, PB%

  Flip a sprite pattern

    SET SPRITE FLIP <n>, <dir: 0=horizontal, 1=vertical, 2=both>

  Rotate a sprite pattern

    SET SPRITE ROTATE <n>, <dir: 0=left, 1=right, 2=180 degrees>

```


### Data Commands

```text
  Set READ statement to get lines from a text resource file (*.TXT or*.CSV) informed on FILE directive

    CMD RESTORE <resource number>

    - Use normal RESTORE <line number> and READ statements to read any specific line from the resource text;
    --- Line number zero is the first line on the resource text;
    --- Each line on TXT files will be treated like an unique string;
    --- Each line on CSV files will be treated like a DATA content;
    - Use IRESTORE <byte number> and IREAD to read binary resources.

```

### Additional Extended Commands

```text
  Write a compressed resource (pletter) to VRAM address

    CMD WRTVRAM <rsn>, <VRAM address>

  Write a compressed .ALF resource (pletter) to VRAM font pattern table

    CMD WRTFNT <rsn>

  Write a compressed resource (pletter) to VRAM tile pattern table

    CMD WRTCHR <rsn>

  Write a compressed resource (pletter) to VRAM tile color table

    CMD WRTCLR <rsn>

  Write a compressed resource (pletter) to VRAM screen table

    CMD WRTSCR <rsn>

  Write a TinySprite (msx.jannone.org) compatible resource (.SPR) to VRAM sprite pattern and color tables

    CMD WRTSPR <rsn>
    
    - Export your sprites as a Backup and save it as .SPR text file;
    - Use with sprite parameter size 2 or 3 on SCREEN statement;
    - You can use, alternativally: BLOAD "file.spr",S

  Write a compressed resource (pletter) to VRAM sprite pattern table

    CMD WRTSPRPAT <rsn>

  Write a compressed resource (pletter) to VRAM sprite color table

    CMD WRTSPRCLR <rsn>

  Write a compressed resource (pletter) to VRAM sprite attribute table

    CMD WRTSPRATR <rsn>
```

---

## Notes

```text
     - LOCATE/PRINT works in graphical mode (screen 2+) without use of
       OPEN 'GRP:'. When in screen 2 tiled mode, it works similar as text
       mode coords (faster output);
     - CMD WRTSCR/CMD WRTCHR activate the tiled mode in screen 2, forcing text
       mode coords;
     - PUT TILE <char>, (x,y) - for tiled mode used with screens 0-2;
     - RANDOMIZE statement (without parameters) works like a RND(-TIME)
       function;
     - COPY works only with graphical parameters (no files support) just
       like: COPY (x0,y0)-(x1,y1) TO (x2,y2);
       COPY ... TO <ram address> / COPY <ram address> TO ... is accepted
       instead of COPY <array>... (try HEAP() as <ram address>);
       When in screen 2 tiled mode, it works with text mode coords;
     - BLOAD works only to load standard screen files (.SCn) and TinySprite
       compatible files (.SPR). You need to inform a file name as literal (no
       via variables) because it will be loaded into ROM (it will activate
       MegaROM mode). Ex: BLOAD "file.sc5", S;
     - IDATA (integer data) and IREAD (integer read) works similar as DATA/READ
       but use less ROM memory and its faster. Use IRESTORE <position> to
       change the pointer position on binary files resources;
     - DATA statements allocate space in resources page and will be compiled to
       a 48kb ROM;
     - PRINT USING support only numerical formatting symbols (#+-.*$,^0) and
       works the same way as USING$() function. For exponential display,
       include more # in the format string until the correct value is
       displayed. Use 0 char symbol to fill the value with left zeros;
     - F1..F10 function keys return ASCII codes 246 to 255 respectively;
     - Resources total size are limited to 16kb (for FILE directive), and
       when compiled generates 48kb ROMs thats can run as cartridge or in RAM
       with SofaRUN or ODO loaders (ExecROM do not support this ROM size);
```

---

See also: [Extended Functions](Extended-Functions) and [Arkos Tracker Support Music](Music-Support).

# Extended Functions

Functions provide powerful ways to retrieve information or extend MSX BASIC behavior.

---

## Why Use Extended Functions?
- Simplify complex routines;
- Provide compiler-optimized alternatives.

---

## Examples
- `HEAP()` — return the RAM free area start address;
- `MSX()` — return the machine MSX version;
- `COLLISION(s1,s2)` — sprite collision helper.

---

## Complete List

### **General Functions**

```text
    - FRE() return free RAM size only (doesnt accept parameters);
    - HEAP() return first free RAM address;
    - TILE(x,y) return character from position (screens mode 0-2, text coords);
    - MSX() return current machine version (0: MSX1, 1: MSX2,
      2: MSX2+, 3: MSXturboR);
    - NTSC() return true to a NTSC (or PAL-M) machine and false to a PAL one;
    - TURBO() return true to cpu turbo mode (R800 or 5.37mhz) or false
      to standard mode (Z80/3.57mhz). Use with CMD TURBO...
    - VDP() without parameters return VDP version (0: TMS9918A, 1: V9938,
      2: V9958, x: VDP ID);
    - MAKER() return the manufacturer ID [1:ASCII/Microsoft, 2:Canon, 3:Casio,
      4:Fujitsu, 5:General, 6:Hitachi, 7:Kyocera, 8:Matsushita (Panasonic),
      9:Mitsubishi, 10:NEC, 11:Nippon Gakki (Yamaha), 12:JVC, 13:Philips,
      14:Pioneer, 15:Sanyo, 16:Sharp, 17:SONY, 18:Spectravideo, 19:Toshiba,
      20:Mitsumi, 21:Telematica, 22:Gradiente, 23:Sharp Brazil,
      24:GoldStar(LG), 25:Daewoo, 26:Samsung,
      212:1chipMSX/Zemmix Neo(KdL firmware)];
      Works only in some MSX2 machines;
```

### **Data Functions**

```text
    - INKEY() is an alternative to INKEY$, but returning an integer instead;
    - IPEEK()/IPOKE is similar to PEEK()/POKE, but applied for integer data; 
    - USING$(format$, number) works just like PRINT USING statement;
```

### **Music Functions**

```text
    AKM PLAYER STATUS (bit 7 = end of song reached, bit 0 = loop status)

       <STATUS> = PLYSTATUS()

    Read PSG register

       n = PSG( <register number> )
```

### **Sprite Collision Detection Functions**

```text
    - COLLISION() return if any sprite collided with another sprite, else
      return -1;
    - COLLISION(<n>) return if a sprite <n> collided with another sprite,
      else return -1;
    - COLLISION(<n1>,<n2>) return n2 if sprite n1 collided with n2, else
      return -1;

    <-1=no collision|collided sprite number> = COLLISION( <-1=any sprite | sprite1> [, <sprite2> ] )
```

Examples

```text
       Beep if any sprite collided with each other:
          SN# = COLLISION(-1)
          IF SN# >= 0 THEN BEEP
       Beep if any sprite collided with sprite 2:
          SN# = COLLISION(2)
          IF SN# >= 0 THEN BEEP
       Beep if sprite 4 collided with sprite 5:
          SN# = COLLISION(5)
          IF SN# = 4 THEN BEEP
       Beep if sprite 5 collided with sprite 4 (direct test):
          SN# = COLLISION( 5, 4 )
          IF SN# >= 0 THEN BEEP
       Beep if sprite 0 collided with sprite 1 (direct test):
          SN# = COLLISION( 0, 1 )
          IF SN# >= 0 THEN BEEP
```

Notes

- Sprites with same X and Y position are considered the same object, thus there's no collision in this case.

### **Resource Functions**

```text
    Get resource data address

       <address> = RESOURCE(<rsn>)
       - RESOURCE(number) return resource start address (use with COPY);

    Get resource data size

      <size> = RESOURCESIZE(<rsn>)
```

### **Deprecated Functions (for tokenized mode)**

```text
    Resource number

       <address> = USR0(<rsn>)

    Resource size

       <size> = USR1(<rsn>)

    PLAY() function alternative

       <0=false> = USR2(0)

    INKEY$ function alternative (for tokenized mode)

       <ASC> = USR2(1)

    INPUT$(1) function alternative (for tokenized mode)

       <ASC> = USR2(2)

    Sprite collision

       <-1=no collision|collided sprite number> = USR3( <-1=any sprite | sprite1 | &h1122> )

    Arkos Tracker Status

       <STATUS> = USR2(3)

```

---

See also [Arkos Tracker Music Support](Music-Support).



# Resource Directives

MSXBAS2ROM allows embedding and managing **external resources** in your project.

---

## What Are Resources?
Resources are assets bundled into the ROM:
- Data files (*.txt, *.csv);
- Screen files (*.SC2, *.SC5, *.SCn...);
- Screen palettes, tilesets and maps (*.SC4Pal, *.SC4Tiles, *.SC4Map);
- Sprites (*.spr);
- Packed tilesets (*.chr.plet5, *.clr.plet5, *.scr.plet5);
- Music and sound effects (*.akm, *.akx);
- Binary data (*.bin).

---

## Usage

Syntax:
```text
TEXT <text string>
FILE <resource file name>
INCLUDE <source file name>
```

Example:
```basic
FILE "SCREEN.SC1"  ' item 0 on resource list
FILE "TEXT.TXT"    ' item 1 on resource list
10 SCREEN 1
20 SCREEN LOAD 0   ' display a screen from resource 0
30 CMD RESTORE 1   ' load text data from resource 1
40 READ MSG$       ' read the first text line from resource 1
50 PRINT MSG$      ' print the line
```

---

## Notes
- Resources are stored in ROM and accessible at runtime;
- Resources total size on Plain ROM mode are limited to 16K (for FILE directive), and when compiled generates 48K ROMs thats can run as cartridge or in RAM with SofaRUN or [ODO](http://msxbanzai.tni.nl/dev/software.html) loaders (ExecROM do not support this ROM size);
- On MegaROM mode, where the ROM size limit is 2048K, the theoretical limitation is around to 3273 resources (v0.3.3.2 and above);
- Check [Extended Functions](Extended-Functions) for functions that interact with resources.

### Files types
#### MSX BASIC program sources
- All .BAS files are in plain text format, so they can be opened by any text editor.
#### Screen resources
- .SCn are MSX BASIC "BSAVE,S" native binary format;
  - Screen files can be created and exported to .SCn using [nMSXTiles](https://launchpad.net/nmsxtiles);
  - Also, image files can be converted and exported to .SCn using [MSX Screen Converter](https://msx.jannone.org/conv/).
- .SC4Pal files are palette data created with [MSX Tile Forge](https://github.com/DamnedAngel/msx-tile-forge);
- .SC4Tiles files are tileset data created with MSX Tile Forge;
- .SC4Map files are screen maps created with MSX Tile Forge.
#### Sprite resources
- .SPR files are in plain text format and can be opened by any text editor and edited with [Tiny Sprite](https://msx.jannone.org/tinysprite/tinysprite.html) as well.
#### Sound resources
- .AKS files are [Arkos Tracker 3](https://www.julien-nevo.com/arkostracker/) projects;
- .AKM files are songs exported by Arkos Tracker 3 in minimalist format;
- .AKX files are sound effects exported by Arkos Tracker 3.

---

## Recommended Resources Stack

* [MSXBAS2ROM](https://github.com/amaurycarvalho/msxbas2rom/);
* [Arkos Tracker 3](https://www.julien-nevo.com/arkostracker/);
* [MSX Tile Forge](https://github.com/DamnedAngel/msx-tile-forge);
* [MSX Tiny Sprite](https://msx.jannone.org/tinysprite/tinysprite.html).

### Additional tools recommended:

* [MSX Screen Converter](https://msx.jannone.org/conv/);
* [nMSXTiles for Linux](https://launchpad.net/nmsxtiles);
* [nMSXTiles for Windows and macOS](https://github.com/pipagerardo/nMSXtiles).

---

## Learn more:

- [MSX Tile Forge Support](MTF-Support)  
  Design screen maps with MTF and use it in your program.

- [Tiny Sprite Support](TS-Support)  
  Design sprites easily with Tiny Sprite tool.

- [Arkos Tracker Music Support](Music-Support)  
  Integrate AT music with commands like `CMD PLYLOAD`, `CMD PLYPLAY`, and customize playback.

- [Compiler Architecture](Compiler-Architecture)



# Arkos Tracker Music Support

MSXBAS2ROM integrates **[Arkos Tracker music](https://www.julien-nevo.com/arkostracker/)** directly into compiled ROMs.

---

## Some Supported Commands
- `CMD PLYLOAD <music resource number>, <sound effects resource number>`
- `CMD PLYSONG <song number>`
- `CMD PLYPLAY`
- `CMD PLYMUTE`

---

## Example
```basic
FILE "music.akm"           ' resource 0
FILE "sound_effects.akx"   ' resource 1
10 CMD PLYLOAD 0, 1
10 CMD PLYSONG 0
20 CMD PLYPLAY
30 A$ = INPUT$(1)
40 CMD PLYMUTE
50 END
```

### More examples

More downloadable code examples can be found [here](https://github.com/amaurycarvalho/msxbas2rom/tree/master/test/integration/ARKTRK).

---

## Complete List

```text
  Load an AKM (songs) and AKX (effects) uncompressed files resources in memory setting up the first song to play

    CMD PLYLOAD <AKM resource number:0-n> [, <AKX resource number:0-n>]

  Initialize a song from the previous AKM resource loaded

    CMD PLYSONG [<subsong number:0-n>]

  Play/continue a song in memory

    CMD PLYPLAY

  Mute/pause a song in memory

    CMD PLYMUTE

  Play a sound effect from the previous AKX resource loaded

    CMD PLYSOUND <sound effect number:1-n> [, <channel number:0-2> [, <volume:0-16>] ]

  Set the song loop status

    CMD PLYLOOP <0=off | 1=on>

  Restart a song in memory (after stopped by loop turned off)

    CMD PLYREPLAY
```

---

## Notes

- Arkos Tracker player use the minimalist binary file (AKM and AKX), with songs composed to play at 50hz, exported at 0100 address, and must be included as the first resource in the list (AKM as 1st and AKX as 2nd);
- PT3 player support is now deprecated, dont use it. Also, it cannot be used in concurrence with Arkos Tracker 2 player too.

---

> 🎵 Learn more in [Extended Commands](Extended-Commands).

# MSX Tile Forge Support

MSXBAS2ROM integrates **[MSX Tile Forge](https://github.com/DamnedAngel/msx-tile-forge?tab=readme-ov-file#msx-tile-forge)** screen maps directly into compiled ROMs.

---

## Command syntax

```text
MTF - Map Transfer

Loads palette/tileset resources into VRAM or copies map data to the screen.

Syntax

  MTF <resource>
  MTF <resource>,<operation>[,<parameters>]

Operations

  0 (Palette/Tileset) - Load resource into VRAM

      Loads a palette or tileset resource into VRAM.

      MTF <resource>[, 0, 0, 0, 0, 0, 0, 0, <page>]

      page            Destination screen page (default=0, for screen 4 only).

  0 (Map) - Full map copy using relative screen coordinates (default)

      Copies a full screen from the map using screen-based coordinates.

      MTF <resource>
      MTF <resource>, 0, <horizontal_col>, <vertical_row>[, 0, 0, 0, 0, <page>]

      horizontal_col  Horizontal screen position in the map (default=0).
      vertical_row    Vertical screen position in the map (default=0).
      page            Destination screen page (default=0, for screen 4 only).

  1 (Map) - Full map copy using absolute tile coordinates

      Copies a full screen from the map starting at an absolute map position.

      MTF <resource>, 1, <map_x>, <map_y>[, 0, 0, 0, 0, <page>]

      map_x           Absolute X coordinate in the map (default=0).
      map_y           Absolute Y coordinate in the map (default=0).
      page            Destination screen page (default=0, for screen 4 only).

  2 (Map) - Partial map copy (window)

      Copies a rectangular area from the map to a screen position.

      MTF <resource>,2,
          <map_x>,<map_y>,
          <width>,<height>,
          <screen_x>,<screen_y>
          [,<page>]

      map_x           Source X coordinate in the map.
      map_y           Source Y coordinate in the map.
      width           Window width in tiles.
      height          Window height in tiles.
      screen_x        Destination X coordinate on screen.
      screen_y        Destination Y coordinate on screen.
      page            Destination screen page (default=0, for screen 4 only).

Notes

  - For palette and tileset resources, MTF loads data into VRAM.
  - For map resources, MTF copies map data to the screen.
  - Operation 0 is the default for map resources.
  - Relative coordinates (operation 0) are screen-based and ideal for
    fixed-screen games.
  - Absolute coordinates (operations 1 and 2) are tile-based and ideal
    for scrolling maps and partial screen updates.
```

---

## Examples

### Loading a palette

```basic
FILE "mtf.SC4Pal"           ' 0

10 SCREEN 2
20 CMD MTF 0                ' load a palette from resource 0
```

### Loading a tileset

```basic
FILE "mtf.SC4Tiles"         ' 0

10 SCREEN 2
21 CMD MTF 0                ' load a tileset from resource 0
```

### Full map copy using relative coordinates (default)

Use `operation=0` (horizontal x vertical full screens relative coords) parameter when your program implement fixed screens.

```basic
CMD MTF <resource number>, 0, <horizontal_col>, <vertical_row>
```

The screens relative coords into the map works like this:

<img width="400px" alt="mtf_sample" src="https://github.com/user-attachments/assets/3982abb2-8c46-4f2c-bf1a-c476c6b2d6de" />


Code example:

```basic
FILE "mtf.SC4Pal"           ' 0
FILE "mtf.SC4Tiles"         ' 1
FILE "mtf.SC4Map"           ' 2 (.SC4Super it's also included automatically)

10 SCREEN 2

20 CMD MTF 0                ' load palette from resource 0
21 CMD MTF 1                ' load tileset from resource 1

30 CMD MTF 2                ' load from resource 2 the first screen from the map {0,0} (operation=0)
31 A$ = INPUT$(1)

40 CMD MTF 2, 0, 1          ' load the second screen from the map {1,0} (operation=0)
41 A$ = INPUT$(1)

50 CMD MTF 2, 0, 2          ' load screen {2,0} from the map (operation=0)
51 A$ = INPUT$(1)

60 CMD MTF 2, 0, 0, 1       ' load screen {0,1} (operation=0)
61 A$ = INPUT$(1)

70 CMD MTF 2, 0, 2, 1       ' load screen {2,1} (operation=0)
71 A$ = INPUT$(1)

80 CMD MTF 2, 0, 1, 2       ' load screen {1,2} from the map
81 A$ = INPUT$(1)
```

### Full map copy using absolute coordinates

Use `operation=1` (absolute coords) parameter when your program needs to implement screen scrolls.

```basic
CMD MTF <resource number>, 1, <x>, <y>
```

The screens absolute coords into the map works like this:

<img width="400px" alt="mtf_sample2" src="https://github.com/user-attachments/assets/3819703c-1fa2-4372-8e6f-96d61cac0ceb" />


Code example:

```basic
FILE "mtf.SC4Pal"           ' 0
FILE "mtf.SC4Tiles"         ' 1
FILE "mtf.SC4Map"           ' 2 (.SC4Super it's also included automatically)

10 SCREEN 2, 2, 0
20 CMD MTF 0                ' load palettes
30 CMD MTF 1                ' load tileset

40 X% = 0 : Y% = 0

50 CMD MTF 2, 1, X%, Y%     ' load from resource 2 the screen started at x,y from the map (operation=1)

60 K% = STICK(0) OR STICK(1)
61 IF INKEY = 27 THEN END
62 IF K% = 0 THEN 60

70 IF K% = 1 OR K% = 2 OR K% = 8 THEN Y% = Y% - 1 
71 IF K% = 4 OR K% = 5 OR K% = 6 THEN Y% = Y% + 1
72 IF K% = 6 OR K% = 7 OR K% = 8 THEN X% = X% - 1
73 IF K% = 2 OR K% = 3 OR K% = 4 THEN X% = X% + 1
74 GOTO 50
```

### Copying a partial map window

Use `operation=2` (partial map copy) when your program needs to update only a portion of the screen, such as scrolling areas, status panels, minimaps, or animated map regions.

```basic
CMD MTF <resource number>, 2, <map_x>, <map_y>, <width>, <height>, <screen_x>, <screen_y>
```

The command copies a rectangular window from the map starting at absolute coordinates `{map_x,map_y}` and transfers it to the screen position `{screen_x,screen_y}`.

In the example below, a `10 x 6` tile window is copied from map position `{20,12}` and displayed on the screen at position `{5,8}`.

<img width="400px" alt="mtf_sample2" src="https://github.com/user-attachments/assets/3819703c-1fa2-4372-8e6f-96d61cac0ceb" />

Code example:

```basic
FILE "mtf.SC4Pal"           ' 0
FILE "mtf.SC4Tiles"         ' 1
FILE "mtf.SC4Map"           ' 2

10 SCREEN 2

20 CMD MTF 0                ' load palette from resource 0
21 CMD MTF 1                ' load tileset from resource 1

30 CMD MTF 2                ' load first screen from the map
31 A$ = INPUT$(1)

40 ' Copy a 10x6 tile window from map position {20,12}
41 ' to screen position {5,8}
42 CMD MTF 2, 2, 20, 12, 10, 6, 5, 8
43 A$ = INPUT$(1)

50 ' Copy an 8x4 tile window from map position {40,20}
51 ' to screen position {0,0}
52 CMD MTF 2, 2, 40, 20, 8, 4, 0, 0
53 A$ = INPUT$(1)

60 ' Copy a 16x10 tile window from map position {0,32}
61 ' to screen position {8,4}
62 CMD MTF 2, 2, 0, 32, 16, 10, 8, 4
63 A$ = INPUT$(1)
```

Unlike operations `0` and `1`, which redraw an entire screen, operation `2` transfers only the specified rectangular area, making it useful for partial screen updates and optimized scrolling effects.

### More examples

More downloadable code examples can be found [here](https://github.com/amaurycarvalho/msxbas2rom/tree/master/tests/integration/MTF).

---

## Notes

- MTF support works only with MSX BASIC screen modes 2 and 4, with full screen size of 32 columns x 24 lines;
- If you are only using MSX1 machines in screen mode 2, you don't need to include the .SC4Pal resource in your program. But don't worry, if you include it anyway and call `CMD MTF`, it will be ignored when running on MSX1 machines;
- You only need to include .SC4Map file into your program as a resource, because .SC4Super will be included automatically with it;
- The compiler will convert the .SC4Map+.SC4Super files into an internal format to maximize loading speed at runtime. For this reason, the map resource will spend more ROM space than its source original files sizes combined;
- The theoretical maximum map size is around 510 full horizontal screens x 227 full vertical screens (totaling ~115 thousand screens), but MegaROM format (2048K max size) limits this to around 2600 full screens;
- Reserve the 32 to 127 tiles numbers range in your tileset bank to the ASCII table characters if you want to use `PRINT` statement. Create your own font set at this range or use [`SET FONT`](Extended-Commands#screen-tiled-mode-and-fonts-extended-commands-1) statement;
- Pass text mode coords (0 to 31 range for x and 0 to 23 range for y) when using the `LOCATE` statement with `PRINT`;
- Its almost certain that you will need to compile your program as a MegaROM format, because of the map sizes envolved. 

---

> 💡 Learn more in [Documentation Overview](Documentation).

# nMSXTile Support

MSXBAS2ROM integrates **[nMSXTiles](https://launchpad.net/nmsxtiles)** screens directly into compiled ROMs.

---

## Command syntax

### Screen Commands

```text
  Inhibits the screen display

    SCREEN OFF

  Display the screen

    SCREEN ON

  Load and display a screen resource

    SCREEN LOAD <resource>
```

### Screen Tiled Mode and Fonts Commands

```text
  Enable/Disable tiled mode (screens 2 and 4, for enable tiled PRINT)

    SET TILE <ON|OFF>

  Load internal FONTs to VRAM font pattern table (screen mode >= 1)

    SET FONT <style number>[, <bank:0-2|empty=all>]
      0 = BIOS default font
      1 = Compile Zanac Style
      2 = Konami Gradius Style 1
      3 = Konami Gradius Style 2

  Put a tile character into screen position (for tiled mode, screens 0-2)

    PUT TILE <n>, (<x>,<y>)
```

See more commands [here](https://github.com/amaurycarvalho/msxbas2rom/wiki/Extended-Commands#screen-tiled-mode-and-fonts-extended-commands-1).

---

## Examples

### Loading Screens

```basic
FILE "SCREEN.SC2"   ' resource 0 - for screen 2
FILE "SCREEN.SC5"   ' resource 1 - for screen 5
10 SCREEN 2
20 SCREEN OFF
30 SCREEN LOAD 0
40 SCREEN ON
50 A$ = INPUT$(1)
60 SCREEN 5
70 SCREEN OFF
80 SCREEN LOAD 1
90 SCREEN ON
100 A$ = INPUT$(1)    
```

### Enabling Screen Tiled Mode and Loading Built-in Fonts

```basic
10 SCREEN 2
20 SET TILE ON
30 SET FONT 1
40 LOCATE 8, 10
50 PRINT "HELLO WORLD"
60 A$ = INPUT$(1)
70 END
```

### More examples

More downloadable code examples can be found [here](https://github.com/amaurycarvalho/msxbas2rom/tree/master/demo/Tesouro%20Perdido).

---

## Importing and Exporting Screens

Use `Project > New` to create a new screen file and `Screen > Import Screen SC2` menu options to load an existing one.

After, use `Screen > Export Screen SC2` to save your changes. 

Also, image files can be converted and exported to `.SCn` format using [MSX Screen Converter](https://msx.jannone.org/conv/).

<img width="571" height="491" alt="image" style="border: 8px solid black;" src="https://github.com/user-attachments/assets/136a048f-5ed6-4eb7-99f9-381c2a1d0b63"  />


## Using it in your code

Screen files can be loaded into your ROM using `FILE` directive. They are identified by the compiler via its file extension (*.SC2, *.SC5, *.SCn...) and the compiler will pack it automatically using pletter compression format.

Use `SCREEN LOAD` statement to show the screen resource into the machine screen at runtime.

---

## Notes

- nMSXTiles support works only with MSX BASIC screen modes 2 and 4, with full screen size of 32 columns x 24 lines;
- Reserve the 32 to 127 tiles numbers range in your tileset bank to the ASCII table characters if you want to use `PRINT` statement in tiled mode. Create your own font set at this range or use [`SET FONT`](Extended-Commands#screen-tiled-mode-and-fonts-extended-commands-1) statement;
- Pass text mode coords (0 to 31 range for x and 0 to 23 range for y) when using the `LOCATE` statement with `PRINT` in tiled mode;
- Its almost certain that you will need to compile your program as a MegaROM format, because of the screen sizes envolved. 

---

> 💡 Learn more in [Documentation Overview](Documentation).

# Tiny Sprite Support

MSXBAS2ROM integrates **[Tiny Sprite](https://msx.jannone.org/tinysprite/tinysprite.html)** sprites sets directly into compiled ROMs.

---

## Command syntax

```basic
SPRITE LOAD <resource number>
```

---

## Examples

### MSX1 sprite set exported by Tiny Sprite

```text
!type
msx1
#Slot 0
................
................
.....FFFF.......
....FFFFFFF.....
...FF.....FFF...
...F.2..2...F...
...F........F...
...FF.......F...
....F.1..1..F...
....FF.111..F...
.....FF.....F...
......FFFFFFF...
................
................
................
................
#Slot 1
................
................
......FFFF......
....FFFFFFFF....
...FF......FF...
...FF.4..4.FF...
...FF......FF...
...FF......FF...
....F.1..1.F....
....F.1111.F....
....FF....FF....
.....FFFFFF.....
................
................
................
................
```

### MSX2 sprite set exported by Tiny Sprite

```text
!type
msx2
#Slot 0
................
................
.....FFFF.......
....FFFFFFF.....
...FF.....FFF...
...F.2..2...F...
...F........F...
...FF.......F...
....F.1..1..F...
....FF.111..F...
.....FF.....F...
......FFFFFFF...
................
................
................
................
#Slot 1
................
................
......FFFF......
....FFFFFFFF....
...FF......FF...
...FF.4..4.FF...
...FF......FF...
...FF......FF...
....F.1..1.F....
....F.1111.F....
....FF....FF....
.....FFFFFF.....
................
................
................
................
```

### Loading a sprite set

```basic
FILE "sprite1.spr"   ' resource 0: msx1 sprite set
FILE "sprite2.spr"   ' resource 1: msx2 sprite set

10 SCREEN 2, 2, 0    ' screen mode 2 (msx1)
20 SPRITE LOAD 0     ' load resource 0 (msx1 sprite set)
30 GOSUB 100         ' show sprite on screen

50 SCREEN 7, 2, 0    ' screen mode 7 (msx2)
60 SPRITE LOAD 1     ' load resource 1 (msx2 sprite set)
70 GOSUB 100         ' show sprite on screen

90 SCREEN 0          
91 END

100 COLOR 15,4,0
101 CLS
102 PUT SPRITE 0, (100,100)
103 PUT SPRITE 1, (100,100)
104 PUT SPRITE 2, (100,100)
105 A$ = INPUT$(1)
106 RETURN
```

### Sprite related extended commands and functions

More sprite related extended commands can be found [here](Extended-Commands#sprite-extended-commands-1) and special functions [here](Extended-Functions#sprite-collision-detection-functions).

### More examples

More downloadable code examples can be found [here](https://github.com/amaurycarvalho/msxbas2rom/tree/master/test/integration/TS).

---

## Notes

- .SPR files are in plain text format and can be opened by any text editor or edited by [Tiny Sprite](https://msx.jannone.org/tinysprite/tinysprite.html);
- Use *Export Sprites* > *Export As Backup* button at Tiny Sprite tool to generate the sprite set in plain text format. Copy and paste it at your favorite plain text editor and save it using .SPR extension;
- Use *Load Backup* button at Tiny Sprite tool to load an existing sprite set;
- The main difference between msx1 and msx2 sprite sets are in the header after *!type* clause. So, its easy to modify it using a text editor.

---

> 💡 Learn more in [Documentation Overview](Documentation).

# Examples

> Discover how MSXBAS2ROM transforms MSX BASIC code into playable games and demos. Explore source files, compile examples, and learn compilation tips.

---

## 📥 [MSX BASIC Projects Repository](https://github.com/amaurycarvalho/msxbasic)

Browse a selection of "**Work in Progress**" [MSX BASIC projects](https://github.com/amaurycarvalho/msxbasic) compiled with MSXBAS2ROM.

---

### 🎮 Game demonstration 1 (compiled as a 48kb ROM cartridge)

If you want to know how to develop a game with MSXBAS2ROM, give a try to the example below.

Download the game source code [here](https://github.com/amaurycarvalho/msxbas2rom/tree/master/demo/Game%20Demo%201), compile and test it.

`msxbas2rom gd1.bas`

You can watch a more detailed explanation [here](https://www.youtube.com/watch?v=oPPuFsp1CvU) (brazilian portuguese video).

---

### 🎮 Game demonstration 2 (compiled as a MegaROM cartridge)

Download the game source code [here](https://github.com/amaurycarvalho/msxbas2rom/tree/master/demo/Game%20Demo%202), compile and test it.

`msxbas2rom -x gd2.bas`

Note: to run this MegaROM compiled game on WebMSX emulator you will need to set the ROM format as ASCII8 (or KonamiSCC) after load it on the cartridge slot.

### 🎮 Tesouro Perdido (compiled as a MegaROM cartridge)

Download the game source code [here](https://github.com/amaurycarvalho/msxbas2rom/tree/master/demo/Tesouro%20Perdido), compile and test it.

`msxbas2rom -x tesperd.bas`

Note: to run this MegaROM compiled game on WebMSX emulator you will need to set the ROM format as ASCII8 (or KonamiSCC) after load it on the cartridge slot.

### 🎮 Scroll on tiled screen modes 1, 2 and 4

Repeat the process in the same way as in the previous examples.

- [Demo 1](https://github.com/amaurycarvalho/msxbas2rom/tree/master/demo/scroll1): all directions scroll (screen mode 1, text);
- [Demo 2](https://github.com/amaurycarvalho/msxbas2rom/tree/master/demo/scroll2): horizontal scroll with sprite (screen mode 2);
- [Demo 3](https://github.com/amaurycarvalho/msxbas2rom/tree/master/demo/scroll3): changing background during horizontal scroll action (screen mode 4);
- [Demo 4](https://github.com/amaurycarvalho/msxbas2rom/tree/master/demo/scroll4): all directions scroll (screen mode 2).

### 🎮 Scroll on graphical screen modes 8 and 12

Here you must use the parameters "-c -x" to compile these ones:

- [Demo 5](https://github.com/amaurycarvalho/msxbas2rom/tree/master/demo/scroll5): horizontal scroll.

---

##  How to Compile and Run

See [Getting Started](Gettingstarted) page for more information.

---

## 📝 Want to Share Your Demo?

Submit your details via a [GitHub issue](https://github.com/amaurycarvalho/msxbas2rom/issues) (prefix: **[Asset]**) or [pull request](https://github.com/amaurycarvalho/msxbas2rom/wiki/Contributing#-developer-quick-start-guide), and we'll add your project to this list.

- **Title** and **Brief Description**;
- **Screenshot or demo video**;
- **ROM download link**, if available.

We'll happily feature it on this page!

---

> *MSXBAS2ROM — turning your BASIC games into ROM adventures.*

# 🕹️ Games Developed with MSXBAS2ROM

> Explore a curated list of games and demos crafted using the MSXBAS2ROM compiler. Each entry showcases the creative potential unlocked by this tool.

---

## 🎮 2026 Releases

- **[Calebe Adventure](https://www.msxdev.org/2026/03/16/msxdev25-42-calebe-adventure/)**  
  In Calebe adventure, Baron Buuu-hahaha stole Paulo’s MSX collection and hid it in his castle. Paulo needs your help to recover it!  
  [<img src="https://www.msxdev.org/wp-content/uploads/2026/03/MSXdev25_CalebeAdventure_v1.2_000.png" width="400px"/>](https://www.msxdev.org/2026/03/16/msxdev25-42-calebe-adventure/)

- **[Toxic Tubes](https://www.msxdev.org/2026/03/15/msxdev25-41-toxic-tubes/)**  
  Chemicals are fascinating – combine them and a reaction is bound to happen, for better or worse.  
  [<img src="https://www.msxdev.org/wp-content/uploads/2026/03/msxdev25_toxictubes_v1.0-0000.png" width="400px"/>](https://www.msxdev.org/2026/03/15/msxdev25-41-toxic-tubes/)

- **[Master Mind](https://www.msxdev.org/2026/01/05/msxdev25-22-master-mind/)**  
  We might not had Wordle on the 80s, but we did had Master Mind, and it was quite popular. It is only logical that we get a MSX version of it.  
  [<img src="https://www.msxdev.org/wp-content/uploads/2026/01/MSXdev25_MasterMind_v1.0_000.png" width="400px"/>](https://www.msxdev.org/2026/01/05/msxdev25-22-master-mind/)

## 🎮 2025 Releases

- **[Flappy Patastrato](https://www.msxdev.org/2025/11/01/msxdev25-16-flappy-patastrato/)**  
  Navigate the quirky Patastrato creature through challenging obstacles. It’s straightforward and fun, much like the creature itself.  
  [<img src="https://www.msxdev.org/wp-content/uploads/2025/10/MSXdev25_FlappyPatastrato_v1.0_0000.png" width="400px"/>](https://www.msxdev.org/2025/11/01/msxdev25-16-flappy-patastrato/)

- **[Bobby is Still Going Home](https://www.msxdev.org/2025/09/18/msxdev25-01-bobby-is-still-going-home/)**  
  A remake for MSX systems based on the original platform game released for the Atari 2600 console.  
  [<img src="https://www.msxdev.org/wp-content/uploads/2025/09/MSXdev25_Bobbyisstillgoinghome_v1.2_001.png" width="400px"/>](https://www.msxdev.org/2025/09/18/msxdev25-01-bobby-is-still-going-home/)

## 🎮 2024 Releases

- **[I-LOGIC](http://www.plattysoft.com/msx/i-logic/)**  
  A strategic puzzle game that challenges your logic skills.  
  [<img src="https://github.com/user-attachments/assets/55c44ce5-594e-4d92-a516-c399394a18c9" width="400px"/>](http://www.plattysoft.com/msx/i-logic/)

- **[Harker's Escape](https://www.msxdev.org/2024/08/02/msxdev24-10-harkers-escape/)**  
  An atmospheric adventure game with immersive storytelling.  
  [<img src="https://www.msxdev.org/wp-content/uploads/2024/07/MSXdev24_HarkersEscape_v1.0_0000.png" width="400px"/>](https://www.msxdev.org/2024/08/02/msxdev24-10-harkers-escape/)

---

## 🎮 2023 Releases

- **[Double Rainbow](https://www.msxdev.org/2023/10/12/msxdev23-23-double-rainbow/)**  
  A vibrant platformer with dynamic levels and engaging gameplay.  
  [<img src="https://www.msxdev.org/wp-content/uploads/2023/10/MSXdev23_DoubleRainbow_v1.0_0001.png" width="400px"/>](https://www.msxdev.org/2023/10/12/msxdev23-23-double-rainbow/)

- **[Last Escape](https://www.msx.org/news/challenges/en/msxdev23-21-last-escape)**  
  A thrilling action game that keeps you on the edge of your seat.  
  [<img src="https://www.msx.org/sites/default/files/news/2023/10/MSXdev23_LastEscape_v1.0_00.png" width="400px"/>](https://www.msx.org/news/challenges/en/msxdev23-21-last-escape)

- **[Shyre](http://www.plattysoft.com/msx/shyre/)**  
  A beautifully crafted RPG with deep lore and expansive world-building.  
  [<img src="https://www.msx.org/sites/default/files/imagecache/newspost/news/2023/09/shyre.jpg" width="400px"/>](http://www.plattysoft.com/msx/shyre/)

- **[Global Ordnance](https://www.msxdev.org/2023/08/21/msxdev23-14-global-ordnance/)**  
  A bite-sized retro experience with seamless execution and timeless appeal.  
  [<img src="https://www.msxdev.org/wp-content/uploads/2023/08/MSXdev23_GlobalOrdnance_v1.0_000.png" width="400px"/>](https://www.msxdev.org/2023/08/21/msxdev23-14-global-ordnance/)

- **[MSX Adventure](https://sites.google.com/view/adventureparamsx/)**  
  A pixel-perfect MSX adventure crafted using MSXBAS2ROM, offering fast execution, polished mechanics, and the spirit of vintage gaming.  
  [<img src="https://github.com/amaurycarvalho/msxbas2rom/blob/master/demo/Games%20Published/msx%20adventure%20screenshot.png" width="400px"/>](https://sites.google.com/view/adventureparamsx/)

- **[Mine Command](https://www.msxdev.org/2023/07/08/msxdev23-11-mine-command/)**  
  A nostalgic puzzle adventure compiled for lightning-fast execution.  
  [<img src="https://www.msxdev.org/wp-content/uploads/2023/06/MSXdev23_MineCommand_v1.0_0000.png" width="400px"/>](https://www.msxdev.org/2023/07/08/msxdev23-11-mine-command/)

- **[Flubber in The Upside Down World](https://www.msxdev.org/2023/06/07/msxdev23-08-flubber-in-the-upside-down-world/)**  
  A high-speed retro challenge that pushes MSX action to its limits.  
  [<img src="https://www.msxdev.org/wp-content/uploads/2023/06/MSXdev23_Flubberintheupsidedownworld_v1.1_000.png" width="400px"/>](https://www.msxdev.org/2023/06/07/msxdev23-08-flubber-in-the-upside-down-world/)

- **[Cadari's Fair](https://amaurycarvalho.itch.io/cadaris-fair)**  
  A retro-inspired 8-bit game built with MSXBAS2ROM, combining smooth performance, optimized code, and classic MSX charm for fast, fun, and timeless gameplay.  
  [<img src="https://img.itch.zone/aW1hZ2UvMjEwNDI4NS8xMjM4NjA0OS5wbmc=/347x500/aFXH1R.png" width="400px"/>](https://amaurycarvalho.itch.io/cadaris-fair)

- **[The 4 Masters of Melody Ex](https://www.clubemsx.com.br/product/the-4-masters-of-melody-ex/)**  
  A fast-paced retro adventure built with the MSXBAS2ROM compiler.  
  [<img src="https://www.clubemsx.com.br/wp-content/uploads/2023/07/the-4-masters-of-melody-ex-01.png" width="400px"/>](https://www.clubemsx.com.br/product/the-4-masters-of-melody-ex/)

---

## 🎮 2022 Releases

- **[K-Jo Chases the Cheese](https://www.redbuttongames.com.br/index.php/games/kjo-msx)**  
  Built with MSXBAS2ROM, this game blends classic 8-bit visuals, smooth controls, and efficient code for a pure MSX nostalgia trip.  
  [<img src="https://www.redbuttongames.com.br/images/kjo-msx/k-jo_000.png" width="400px"/>](https://www.redbuttongames.com.br/index.php/games/kjo-msx)

- **[Balloon Buster](https://www.msxdev.org/2022/10/03/msxdev22-27-balloon-buster/)**  
  Classic MSX gameplay reborn with optimized code and modern tools.  
  [<img src="https://www.msxdev.org/wp-content/uploads/2022/09/MSXdev22_BalloonBuster_v1.0_0000-1024x768.png" width="400px"/>](https://www.msxdev.org/2022/10/03/msxdev22-27-balloon-buster/)

- **[My Sacred Place](https://www.msxdev.org/2022/10/02/msxdev22-25-my-sacred-place/)**  
  A fantasy quest brought to life with crisp visuals and fluid gameplay.  
  [<img src="https://www.msxdev.org/wp-content/uploads/2022/09/MSXdev22_SacredPlace_v1.0_000.png" width="400px"/>](https://www.msxdev.org/2022/10/02/msxdev22-25-my-sacred-place/)

- **[Cryptogram – Anagrams Crosswords](https://www.msxdev.org/2022/03/24/msxdev22-06-cryptogram-anagrams-crosswords/)**  
  A nostalgic puzzle game compiled for lightning-fast execution.  
  [<img src="https://www.msxdev.org/wp-content/uploads/2022/04/MSXdev22_Cryptogram-AnagramsCrosswords_v1.1_000.png" width="400px"/>](https://www.msxdev.org/2022/03/24/msxdev22-06-cryptogram-anagrams-crosswords/)

- **[Fish Life](https://www.clubemsx.com.br/produto/gold-disk-5/)**  
  Fast-paced fun that loads quickly and plays even faster.   
  [<img src="https://github.com/amaurycarvalho/msxbas2rom/blob/master/demo/Games%20Published/fishlife.png" width="400px"/>](https://www.clubemsx.com.br/produto/gold-disk-5/)

- **[Cave of the Monsters](https://www.clubemsx.com.br/2022/12/gold-disk-5-ja-disponivel-em-nossa-loja-virtual/)**  
  A bite-sized retro experience with seamless execution and timeless appeal.  
  [<img src="https://www.clubemsx.com.br/wp-content/uploads/2022/12/tela-gd5-04.png" width="400px"/>](https://www.clubemsx.com.br/2022/12/gold-disk-5-ja-disponivel-em-nossa-loja-virtual/)

---

## 🎮 2021 Releases

- **[Open Wide!](https://www.msxdev.org/2021/09/02/msxdev21-31-open-wide/)**  
  An engaging MSX classic-style experience powered by MSXBAS2ROM, delivering swift gameplay, optimized performance, and authentic retro charm.  
  [<img src="https://www.msxdev.org/wp-content/uploads/2021/08/MSXdev21_OpenWide_v1.0-0001.png" width="400px"/>](https://www.msxdev.org/2021/09/02/msxdev21-31-open-wide/)

- **[Monster On The Run](https://www.msxdev.org/2021/08/16/msxdev21-23-monster-on-the-run/)**  
  Built with MSXBAS2ROM, this game blends classic 8-bit visuals, smooth controls, and efficient code for a pure MSX nostalgia trip.  
  [<img src="https://www.msxdev.org/wp-content/uploads/2021/08/MSXdev21_MonsterOnTheRun_v1.0-0001.png" width="400px"/>](https://www.msxdev.org/2021/08/16/msxdev21-23-monster-on-the-run/)

- **[PickinX](https://amaurycarvalho.itch.io/pickinx)**  
  A colorful arcade throwback built for maximum MSX enjoyment.  
  [<img src="https://img.itch.zone/aW1hZ2UvMTIzNjY5Mi83MjA5ODc5LnBuZw==/347x500/7lrnXT.png" width="400px"/>](https://amaurycarvalho.itch.io/pickinx)

- **[Logic Remastered](https://www.msxdev.org/2021/07/20/msxdev21-20-logic-remastered/)**  
  A strategic puzzle game that challenges your logic skills.    
  [<img src="https://www.msxdev.org/wp-content/uploads/2021/07/MSXdev21_LogicRemastered_v1.2_000.png" width="400px"/>](https://www.msxdev.org/2021/07/20/msxdev21-20-logic-remastered/)

- **[Market Master](https://www.msxdev.org/2021/05/01/msxdev21-8-market-master/)**  
  Fast-paced fun that loads quickly and plays even faster.  
  [<img src="https://www.msxdev.org/wp-content/uploads/2021/04/MSXdev21_MarketMaster_v1.0-3.png" width="400px"/>](https://www.msxdev.org/2021/05/01/msxdev21-8-market-master/)

- **[Amadeus Classical Beats](https://amaurycarvalho.itch.io/amadeus-classical-beats)**  
  A MSX game crafted using MSXBAS2ROM, offering fast execution, polished mechanics, and the spirit of vintage gaming.  
  [<img src="https://img.itch.zone/aW1hZ2UvMTIyNjI4MS83MTUwNjM4LnBuZw==/347x500/0ePriZ.png" width="400px"/>](https://amaurycarvalho.itch.io/amadeus-classical-beats)

- **[Bomber Battle](https://amaurycarvalho.itch.io/bomber-battle)**  
  A colorful arcade throwback built for maximum MSX enjoyment.  
  [<img src="https://img.itch.zone/aW1hZ2UvMTIyNjI3Ny83MTUwNTkyLnBuZw==/347x500/KZhCRx.png" width="400px"/>](https://amaurycarvalho.itch.io/bomber-battle)

- **[Indian Night](https://www.clubemsx.com.br/2021/11/revista-clube-msx-14-inicia-pre-venda-online-com-edicoes-em-portugues-e-ingles/)**  
  An old-school platformer with pixel-perfect controls and smooth performance.  
  [<img src="https://github.com/amaurycarvalho/msxbas2rom/blob/master/demo/Games%20Published/indian%20night.png" width="400px"/>](https://www.clubemsx.com.br/2021/11/revista-clube-msx-14-inicia-pre-venda-online-com-edicoes-em-portugues-e-ingles/)

- **[5Shots](https://www.clubemsx.com.br/2021/11/5shots-veja-teaser-de-um-dos-jogos-que-estarao-na-gold-disk-4/)**  
  Classic MSX gameplay reborn with optimized code and modern tools.  
  [<img src="https://www.clubemsx.com.br/wp-content/uploads/2021/11/dest-teaser-5shots.jpg" width="400px"/>](https://www.clubemsx.com.br/2021/11/5shots-veja-teaser-de-um-dos-jogos-que-estarao-na-gold-disk-4/)

---

## 🎮 2020 Releases

- **[Entombed](https://amaurycarvalho.itch.io/entombed)**  
  A high-speed retro challenge that pushes MSX action to its limits.  
  [<img src="https://img.itch.zone/aW1hZ2UvMTA0NTY5NC81OTc2MjE1LnBuZw==/347x500/DQ5atG.png" width="400px"/>](https://amaurycarvalho.itch.io/entombed)

- **[CatsPots](https://amaurycarvalho.itch.io/catspots)**  
  Fast-paced fun that loads quickly and plays even faster.  
  [<img src="https://img.itch.zone/aW1hZ2UvMTA0NTYwOS81OTc1ODY3LnBuZw==/347x500/BfXEjj.png" width="400px"/>](https://amaurycarvalho.itch.io/catspots)

- **[Corona's Spree](https://amaurycarvalho.itch.io/coronas-spree)**  
  Classic MSX gameplay reborn with optimized code and modern tools.  
  [<img src="https://img.itch.zone/aW1hZ2UvMTA0NjA5NC81OTc4OTEwLnBuZw==/347x500/uwFdq2.png" width="400px"/>](https://amaurycarvalho.itch.io/coronas-spree)

- **[War from Beyond](https://www.clubemsx.com.br/2020/12/war-from-beyond-video-promocional-no-canal-da-clube-msx/)**  
  An 8-bit gem where simplicity meets speed for pure gameplay joy.  
  [<img src="https://www.clubemsx.com.br/wp-content/uploads/2020/12/dest-wfb-promo-video.jpg" width="400px"/>](https://www.clubemsx.com.br/2020/12/war-from-beyond-video-promocional-no-canal-da-clube-msx/)

---

## 📝 How to Add Your Game

If you've developed a game or demo using MSXBAS2ROM, we'd love to showcase it here! Please provide:

- **Game Title**;
- **Release Year**;
- **Brief Description**;
- **Playable Link** (if possible);
- **Screenshot or Banner Image**.

Submit your details via a GitHub issue (prefix: **[Asset]**) or pull request, and we'll add your project to this list.

---

## 🚀 Inspiration from the Community

- **[MSX BASIC Games Compiled with MSXBAS2ROM](https://github.com/amaurycarvalho/msxbasic)**;
  A collection of demonstration games compiled using MSXBAS2ROM, showcasing various features and capabilities.

- **[MSXDev.org](https://www.msxdev.org)**  
  An active community hosting MSX game development competitions and showcasing new releases.

---

> *From code to console — celebrate the creativity powered by MSXBAS2ROM.*

# Debugging with OpenMSX Debugger

Debugging your MSX BASIC program compiled with **MSXBAS2ROM** is possible using the **[OpenMSX](https://openmsx.org/) integrated debugger** ([release 20.0+](https://github.com/openMSX/openMSX/releases)).

> 📄 Although you cannot debug the BASIC source directly, you can debug the **generated assembly binary code** — allowing you to track execution, inspect variables, and set breakpoints with symbolic information.

---

## 🧩 Overview

When compiling a program with MSXBAS2ROM, the compiler can generate a **.NOI file** that contains symbolic information about your BASIC lines and variables.  

This file allows the OpenMSX debugger to show human-readable symbols like:

- **Lines** (e.g., `LIN_10`, `LIN_20`)  
- **Variables** (e.g., `VAR_A$`, `VAR_B%`)  

These symbols can then be used to set breakpoints, inspect memory, and step through your compiled code as it runs on the MSX emulator.

---

## ⚙️ Compiling with Symbol Support

To generate the `.NOI` symbol file, compile your BASIC program using the **`-s`** parameter:

```bash
msxbas2rom -s myprogram.bas
```

This will create both the `.ROM` binary and a corresponding `.NOI` file with symbol definitions.

> 📘 Reference: [Usage → Compile and Generate Symbols for OpenMSX Debugger](https://github.com/amaurycarvalho/msxbas2rom/wiki/Usage#7-compile-and-generate-symbols-for-openmsx-debugger)

---

## 🧠 Example

### 👉 MSX BASIC Source

```basic
10 CLS
20 A$ = "HELLO WORLD!"
30 B% = 2025
40 PRINT A$
50 PRINT "HELLO FROM YEAR "; B%
60 END
```

### 👉 Generated `.NOI` File

```text
def LOADER 4010H  ; jump
def VAR_CURSEGM C023H  ; variable
def MR_CALL 41C8H  ; jump
def MR_CALL_TRAP 41CBH  ; jump
def MR_CHANGE_SGM 41CEH  ; jump
def MR_GET_BYTE 41D1H  ; jump
def MR_GET_DATA 41D4H  ; jump
def MR_JUMP 41D7H  ; jump
def END_STMT 8063H  ; jump
def START_PGM 8070H  ; jump
def LIN_10 8089H  ; jump
def LIN_20 808CH  ; jump
def LIN_30 8098H  ; jump
def LIN_40 809EH  ; jump
def LIN_50 80A7H  ; jump
def LIN_60 80B6H  ; jump
def END_PGM 80B9H  ; jump
def LIT_0 80BCH  ; jump
def LIT_1 80C9H  ; jump
def VAR_A$ C038H  ; variable
def VAR_B% C138H  ; variable
```

### 👉 Summary of Symbol Types and Debug Uses

Symbol Type | Example | Typical Use
-- | -- | --
LIN_* | LIN_20 | Line-level breakpoints
VAR_* | VAR_B% | Variable read/write watch
LIT_* | LIT_0 | Constant literal inspection
START_PGM | — | Start of the program checkpoint
END_PGM | — | End of the program checkpoint
END_STMT | — | END statement checkpoint
VAR_CURSEGM | — | Current MegaROM segment number inspection
MR_* | MR_GET_DATA | MegaROM control routines
LOADER | — | ROM initialization checkpoint

---

## 🧭 Opening the Debugger in OpenMSX

1. Launch **OpenMSX** and load your compiled ROM:
   ```bash
   openmsx -cart myprogram.rom
   ```

2. Open the **OpenMSX integrated debugger** (available since release 20.0+):
   - Menu → *Debugger* → toggle the following options: *Tool bar*, *Disassembly*, *Slots*, *CPU registers*, *CPU flags*, *Stack*, *Memory* and *Symbol Manager*;
   - On the *Symbol Manager* box, select *Load symbol file...*
   - Select the `.NOI` file generated by MSXBAS2ROM. Now, you can see your program symbols on the "All symbols" option. 

3. Once loaded, you’ll see symbols like `LIN_10`, `LIN_20`, and `VAR_A$` displayed in the debugger.  
   The screen will look like the one below:  
   <img width="970" height="569" alt="OpenMSX integrated debugger screen" src="https://github.com/user-attachments/assets/ccf2872d-2e11-4f03-ba5b-b3008a08f0cd" />


> 📄 See release notes for more about the integrated debugger:  
> - [OpenMSX 21.0 Release Notes](https://raw.githubusercontent.com/openMSX/openMSX/RELEASE_21_0/doc/release-notes.txt)

---

## 🧰 Debugging Workflow

### 👉 Setting Breakpoints

You can place breakpoints on **line symbols** using *Set breakpoint* menu option:

<img width="295" height="173" alt="Set breakpoint option" src="https://github.com/user-attachments/assets/407964ec-9dfa-4550-90de-4f22b744a10a" />  

A red marker will be placed next to the line number symbol:

<img width="333" height="238" alt="Breakpoint's red marker" src="https://github.com/user-attachments/assets/61d4be0f-ddfe-4344-aec0-e7d24ea27564" />

Also, you can set breakpoints on **variable memory addresses** using the *Debugger* → *Breakpoints* → *Editor* option:

<img width="449" height="172" alt="Breakpoints editor" src="https://github.com/user-attachments/assets/82ec0d71-3ff7-47a0-a9f5-106fbe62066d" />

This allows you to stop execution when the code reaches a certain BASIC line or when a variable is read/written.

### 👉 Inspecting Memory and Variables

The **Memory Inspector** in OpenMSX debugger can show variable contents.  

Use the `.NOI` symbols to locate the variable addresses (e.g., `VAR_A$` or `VAR_B%`) and inspect them directly in the **Hex Memory View**.

<img width="488" height="206" alt="Memory inspector" src="https://github.com/user-attachments/assets/ccd13c8f-c71e-4eb9-9f9a-3c7288dfee8f" />

> 📄 See [Internal Data Types](https://github.com/amaurycarvalho/msxbas2rom/wiki/Compiling-Code#internal-data-types) for more information about how to understand variables binary data.

---

## 🧩 Common debugging strategies

### 👉 Symbol-Based Breakpoint Strategy

Instead of using raw memory addresses, use the symbolic names generated by MSXBAS2ROM to map line flow and follow jump tracing.

For example, putting a breakpoint on LIN_30 symbol will stop execution exactly when BASIC line 30 begins — even though you’re debugging compiled Z80 code. You can then step through the generated instructions to understand how your BASIC logic translates to assembly.

> 💡 Use LIN_* symbols as logical checkpoints — they’re the closest equivalent to “breakpoints per BASIC line.”

### 👉 Variable Watch & Memory Inspection

Since every BASIC variable has a symbol like VAR_A$ or VAR_B%, you can monitor reads and writes directly. Then, in the Memory Inspector, you can:

- View variable contents in hexadecimal or ASCII form;
- Track changes across function calls or loops;
- Identify overwrites or unintended data corruption.



> 💡 This is especially useful for debugging string concatenations, numeric overflow, or array index errors.  
> 📄 See [Internal Data Types](https://github.com/amaurycarvalho/msxbas2rom/wiki/Compiling-Code#internal-data-types) for more information about how to understand variables binary data.

### 👉 Timing & Performance Checkpoints

OpenMSX’s debugger allows cycle-level stepping by tracking the machine internal time (*Settings* → *GUI* → *Status bar* → *Show*) or the screen frame counter (*Tools* → *Toys* → *frame counter*). So, you can:

- Measure the performance of specific routines;
- Compare execution time before and after optimizations;
- Identify “heavy” BASIC lines that produce large instruction blocks.

> 💡 Document useful symbol patterns in your game’s internal wiki (e.g. where main loop starts, where player state lives), so it will be easier to track them.

---

📌 See also: [Reference Guide](Documentation)

---

## 🪶 Footer

> 🧩 *“Empower your MSX creativity — compile fast and debug smart with MSXBAS2ROM.”*


# Compiler Architecture

> MSXBAS2ROM was designed to transform MSX BASIC programs into optimized
Z80 machine code while maintaining strong compatibility with the MSX
BASIC environment and ecosystem.

This document describes the **internal architecture** of the
**MSXBAS2ROM** compiler and the structure of the ROM images it
produces.

The goal is to provide a clear overview of how a BASIC source file is
transformed into a bootable MSX ROM cartridge and how the generated
program is organized in memory.

------------------------------------------------------------------------

# Compilation Flow

The compiler follows a traditional multi‑phase compilation pipeline
adapted for MSX BASIC semantics and the constraints of the Z80
architecture.

The main phases are:

1.  **Lexical Analysis**
2.  **Syntactic Analysis**
3.  **Semantic Analysis and Code Generation**
4.  **Binary Building and ROM Packaging**

Each phase progressively transforms the source program into a
lower-level representation until it becomes a valid MSX ROM image.

------------------------------------------------------------------------

## 1. Lexical Analysis

During lexical analysis, the source code is scanned and divided into
**atomic elements called lexemes**.

Examples of lexemes include:

-   Keywords (`IF`, `FOR`, `GOTO`, `PRINT`)
-   Identifiers (variable names)
-   Operators (`+`, `-`, `*`, `/`, `AND`, `OR`)
-   Literals (numbers and strings)
-   Delimiters (`(` `)` `,` `:`)

The lexical analyzer converts the text source into a **token stream**,
which simplifies further processing by removing formatting concerns such
as whitespace or comments.

Key responsibilities:

-   Token identification
-   Numeric literal parsing
-   String literal handling
-   BASIC keyword recognition
-   Error detection for invalid tokens

The result of this phase is a **sequence of tokens** used by the parser.

------------------------------------------------------------------------

## 2. Syntactic Analysis

The syntactic analysis phase interprets the token stream and validates
it against the **grammar rules of MSX BASIC**.

During this phase the compiler builds an **Abstract Syntax Tree (AST)**
representing the structure of the program.

Typical constructs represented in the AST include:

-   Expressions
-   Statements
-   Control flow structures
-   Function calls
-   Variable references

Example BASIC statement:

    IF A > 10 THEN PRINT "HELLO"

This becomes a tree describing:

-   A conditional expression (`A > 10`)
-   A conditional branch
-   A PRINT command with a string literal

The AST becomes the **central intermediate representation** used in the
rest of the compilation pipeline.

------------------------------------------------------------------------

## 3. Semantic Analysis and Code Generation

Once the AST is built, the compiler performs **semantic analysis** to
ensure the program is logically correct and to prepare for code
generation.

Major tasks in this phase include:

### Symbol Table Construction

The compiler builds a **symbol table** containing information about:

-   Variables
-   Arrays
-   Labels
-   Functions
-   Constants

This table allows the compiler to resolve identifiers and allocate
memory locations.

### Type and Context Validation

Although MSX BASIC is loosely typed, the compiler must still verify:

-   Valid function usage
-   Correct parameter counts
-   Valid variable contexts
-   Control flow correctness

### Z80 Code Generation

After semantic validation, the compiler generates **Z80 assembly
instructions**.

These instructions are emitted using an internal code builder that:

-   Translates BASIC statements to Z80 routines
-   Calls runtime support functions
-   Handles expression evaluation
-   Manages stack usage

The output of this stage is a **relocatable code representation** ready
to be assembled into the final ROM image.

------------------------------------------------------------------------

## 4. Binary Building and ROM Packaging

In the final stage the compiler produces a **complete MSX ROM image**.

This stage includes:

-   Translating generated code into binary form
-   Linking runtime modules
-   Linking resources (maps, data, assets)
-   Resolving symbol references
-   Organizing memory segments
-   Producing the final ROM file

The final result is a **ROM cartridge binary** that can run on:

-   Real MSX hardware
-   MSX emulators
-   Flash cartridges

------------------------------------------------------------------------

# Design Goals

The MSXBAS2ROM compiler was designed around several key principles.

## MSX BASIC Compatibility

The compiler aims to maintain strong compatibility with **MSX BASIC
syntax and semantics**, enabling existing programs to be ported with
minimal changes.

## Cross‑Platform Tooling

The compiler is implemented as a **command line tool** compatible with:

-   Linux
-   Windows
-   macOS

This allows integration into modern development workflows and build
pipelines.

## Expandability

The architecture supports extensibility through:

-   New compiler directives
-   Extended BASIC commands
-   Additional runtime modules
-   External resource integration

## Performance

One of the main goals of MSXBAS2ROM is to generate **fast Z80 machine
code**, significantly outperforming interpreted BASIC execution.

------------------------------------------------------------------------

# ROM Memory Scheme

Programs compiled with MSXBAS2ROM are packaged into a ROM image that
follows the **MSX cartridge memory model**.

The MSX memory space is divided into **four pages of 16 KB each**,
totaling 64 KB of addressable memory.

Different ROM formats may organize these pages differently depending on
the cartridge type.

------------------------------------------------------------------------

# Plain ROM Memory Scheme

Plain ROM cartridges are typically **48 KB** in size.

They occupy three ROM pages while the last page is RAM used during
execution.

## Overview

    +----------------------------------------------------+
    | PAGE 0 (16K)                                       |
    |----------------------------------------------------|
    | MSX ROM BIOS                                       |
    |----------------------------------------------------|
    | USER RESOURCES                                     |
    |   ├─ MAP                                           |
    |   └─ DATA                                          |
    +----------------------------------------------------+

    +----------------------------------------------------+
    | PAGE 1 (16K)                                       |
    |----------------------------------------------------|
    | MSX ROM BASIC                                      |
    |----------------------------------------------------|
    | COMPILER RUNTIME KERNEL                            |
    |   ├─ MSX Boot Loader                               |
    |   ├─ General Support Routines                      |
    |   ├─ Tiny Sprite Support                           |
    |   ├─ MSX Tile Forge Support                        |
    |   ├─ Arkos Tracker Support                         |
    |   └─ Floating Point Math Pack                      |
    +----------------------------------------------------+

    +----------------------------------------------------+
    | PAGE 2 (16K)                                       |
    |----------------------------------------------------|
    | BASIC Boot Loader                                  |
    | USER CODE                                          |
    +----------------------------------------------------+

    +----------------------------------------------------+
    | PAGE 3 (16K)                                       |
    |----------------------------------------------------|
    | MSX RAM                                            |
    |   ├─ Kernel Workspace (flags)                      |
    |   ├─ User Workspace (variables)                    |
    |   ├─ Code Stack                                    |
    |   └─ MSX BIOS Workspace and routines               |
    +----------------------------------------------------+

### Description

- **Page 0**: Contains system BIOS and optional user resources such as tile maps or
game data;
- **Page 1**: Contains the runtime kernel required for executing compiled BASIC
programs;
- **Page 2**: Stores the compiled program code and boot loader responsible for
starting the application;
- **Page 3**: Represents RAM used for runtime execution including variables and stack.

------------------------------------------------------------------------

# MegaROM Memory Scheme (Konami SCC / ASCII8)

Large programs and games often require ROM sizes larger than 48 KB.

For this reason the compiler also supports **MegaROM cartridges**,
typically ranging from:

**128 KB up to 2048 KB**.

These cartridges use **bank switching** to dynamically map ROM segments
into the address space.

## Overview

    +----------------------------------------------------+
    | PAGE 0 (16K)                                       |
    |----------------------------------------------------|
    | MSX ROM BIOS                                       |
    +----------------------------------------------------+

    +----------------------------------------------------+
    | PAGE 1 (16K)                                       |
    |----------------------------------------------------|
    | MSX ROM BASIC                                      |
    |----------------------------------------------------|
    | Segments 0 (8K) and 1 (8K)                         |
    |                                                    |
    | COMPILER RUNTIME KERNEL                            |
    |   ├─ MSX Boot Loader                               |
    |   ├─ General Support Routines                      |
    |   ├─ Tiny Sprite Support                           |
    |   ├─ MSX Tile Forge Support                        |
    |   ├─ Arkos Tracker Support                         |
    |   └─ Floating Point Math Pack                      |
    +----------------------------------------------------+

    +----------------------------------------------------+
    | PAGE 2 (16K)                                       |
    |----------------------------------------------------|
    | Segments 2..N                                      |
    |                                                    |
    | BASIC Boot Loader                                  |
    | USER CODE                                          |
    | Additional code banks                              |
    +----------------------------------------------------+

    +----------------------------------------------------+
    | PAGE 2 (continued after code segments)             |
    |----------------------------------------------------|
    | USER RESOURCES                                     |
    |   ├─ MAP segments                                  |
    |   └─ DATA segments                                 |
    +----------------------------------------------------+

    +----------------------------------------------------+
    | PAGE 3 (16K)                                       |
    |----------------------------------------------------|
    | MSX RAM                                            |
    |   ├─ Kernel Workspace (flags)                      |
    |   ├─ User Workspace (variables)                    |
    |   ├─ Code Stack                                    |
    |   └─ MSX BIOS Workspace                            |
    +----------------------------------------------------+

### Bank Switching

MegaROM cartridges use mapper hardware such as:

-   **Konami SCC**
-   **ASCII8**

These allow different **8 KB segments** of the ROM to be dynamically
mapped into memory during program execution.

This enables:

-   Very large games
-   Streaming of assets
-   Large maps and resources
-   Music and sound data banks

------------------------------------------------------------------------

# Additional Resources

See [compiler process flow model](https://github.com/amaurycarvalho/msxbas2rom/blob/master/doc/Architectural%20model.pdf) for more detailed information.

------------------------------------------------------------------------

📌 See also [Resource Directives](Resource-Directives), [Extended Commands](Extended-Commands) and [Extended Functions](Extended-Functions).


# Documentation Overview

Welcome to the **MSXBAS2ROM Reference Guide**. This section gathers all the essential documentation to help you **understand, explore, and master** the compiler’s features. 

Use the links below to dive into specific topics:

---

## 📖 Documentation Sections

- [Coding Limitations and Differences](Compiling-Code)  
  Learn how to compile BASIC programs into ROMs, supported statements, data types, and hardware requirements.

- [Resource Directives](Resource-Directives)  
  Understand how to include external files, handle assets, and manage project resources.

- [MSX Tile Forge Support](MTF-Support)  
  Design screen maps with MTF and use it in your program.

- [nMSXTiles Support](nMT-Support)  
  Design screens with nMSXTiles and use it in your program.

- [Tiny Sprite Support](TS-Support)  
  Design sprites easily with Tiny Sprite tool.

- [Arkos Tracker Music Support](Music-Support)  
  Integrate AT music with commands like `CMD PLYLOAD`, `CMD PLYPLAY`, and customize playback.

- [Extended Commands](Extended-Commands)  
  Discover compiler-specific commands (`SCREEN LOAD`, `CMD RESTORE`, etc.) that expand the original MSX BASIC capabilities.

- [Extended Functions](Extended-Functions)  
  Explore powerful functions such as `HEAP()`, `MSX()`, collision helpers, and more.

- [VSCode integration](VSCode_integration)  
  Brings a modern development workflow to your MSX BASIC project.

- [Debugging with OpenMSX Debugger](Debugging_with_OpenMSX)  
  Debugging your MSX BASIC program compiled with MSXBAS2ROM.

- [Compiler Architecture](Compiler-Architecture)  
  A deeper look at the compiler’s internal flow and design principles.

- [Getting Help & References](Getting-Help)  
  How to use built-in docs, find references, and get support.

---

## ✨ Notes
- This documentation is constantly evolving;
- If you spot mistakes or have suggestions, feel free to [contribute](Contributing).  

---

> *MSXBAS2ROM – powering your creativity, one line of BASIC at a time.*


