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
- Reserve the 32 to 127 tiles numbers range in your tileset bank to the ASCII table characters if you want to use `PRINT` statement in tiled mode. Create your own font set at this range or use [`SET FONT`](https://github.com/amaurycarvalho/msxbas2rom/wiki/Extended-Commands#screen-tiled-mode-and-fonts-extended-commands-1) statement;
- Pass text mode coords (0 to 31 range for x and 0 to 23 range for y) when using the `LOCATE` statement with `PRINT` in tiled mode;
- Its almost certain that you will need to compile your program as a MegaROM format, because of the screen sizes envolved. 

---

> 💡 Learn more in [Documentation Overview](https://github.com/amaurycarvalho/msxbas2rom/wiki/Documentation).