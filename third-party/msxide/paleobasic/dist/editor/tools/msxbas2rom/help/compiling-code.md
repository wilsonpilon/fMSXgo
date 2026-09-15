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

For advanced options, see the [Usage Guide](https://github.com/amaurycarvalho/msxbas2rom/wiki/Usage).

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

📌 See also [Compiler Architecture](https://github.com/amaurycarvalho/msxbas2rom/wiki/Compiler-Architecture), [Resource Directives](https://github.com/amaurycarvalho/msxbas2rom/wiki/Resource-Directives), [Extended Commands](https://github.com/amaurycarvalho/msxbas2rom/wiki/Extended-Commands) and [Extended Functions](https://github.com/amaurycarvalho/msxbas2rom/wiki/Extended-Functions).
