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
- Reserve the 32 to 127 tiles numbers range in your tileset bank to the ASCII table characters if you want to use `PRINT` statement. Create your own font set at this range or use [`SET FONT`](https://github.com/amaurycarvalho/msxbas2rom/wiki/Extended-Commands#screen-tiled-mode-and-fonts-extended-commands-1) statement;
- Pass text mode coords (0 to 31 range for x and 0 to 23 range for y) when using the `LOCATE` statement with `PRINT`;
- Its almost certain that you will need to compile your program as a MegaROM format, because of the map sizes envolved. 

---

> 💡 Learn more in [Documentation Overview](https://github.com/amaurycarvalho/msxbas2rom/wiki/Documentation).