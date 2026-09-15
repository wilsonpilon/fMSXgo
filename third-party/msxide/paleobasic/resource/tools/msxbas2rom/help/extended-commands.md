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

See also: [Extended Functions](https://github.com/amaurycarvalho/msxbas2rom/wiki/Extended-Functions) and [Arkos Tracker Support Music](https://github.com/amaurycarvalho/msxbas2rom/wiki/Music-Support).