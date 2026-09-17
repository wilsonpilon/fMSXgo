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
- Check [Extended Functions](https://github.com/amaurycarvalho/msxbas2rom/wiki/Extended-Functions) for functions that interact with resources.

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

- [MSX Tile Forge Support](https://github.com/amaurycarvalho/msxbas2rom/wiki/MTF-Support)  
  Design screen maps with MTF and use it in your program.

- [Tiny Sprite Support](https://github.com/amaurycarvalho/msxbas2rom/wiki/TS-Support)  
  Design sprites easily with Tiny Sprite tool.

- [Arkos Tracker Music Support](https://github.com/amaurycarvalho/msxbas2rom/wiki/Music-Support)  
  Integrate AT music with commands like `CMD PLYLOAD`, `CMD PLYPLAY`, and customize playback.

- [Compiler Architecture](https://github.com/amaurycarvalho/msxbas2rom/wiki/Compiler-Architecture)

