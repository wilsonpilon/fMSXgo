# MSXBAS2ROM - referencia de linha de comando (-h)

```
MSXBAS2ROM - MSX-BASIC TO ROM COMPILER
Created by Amaury Carvalho (2020-2026)
Version: 1.2.1.0

Usage: msxbas2rom [options] <filename.bas>

General options:
    -h or --help = help
    -q or --quiet = quiet (no verbose)
    -d or --debug = debug mode (show details)
    -D or --doc = display quick reference guide
    -H or --history = display app history
    -v or --version = display app version

Compile options (optional):
    -c  = plain ROM compile mode (default)
    -a or --auto = auto mode (fallback to ASCII8 when plain ROM overflows)
    -x or -8 or --ascii8 = ASCII8 MegaROM compile mode
    -6 or --ascii16 = ASCII16 MegaROM compile mode
    -7 or --ascii16x = ASCII16-X MegaROM compile mode
    -4 or --konami = Konami MegaROM compile mode
    -k or --scc = Konami SCC MegaROM compile mode

Path options (optional)
    -i  = input path (default=source file path)
    -o  = output path (default=source file path)

Special options:
    -s generate symbols for Z80 debugging (default format: .noi)
    --noi or --noice = generate symbols in .noi format (openMSX)
    --cdb = generate symbols in .cdb format (sdcc)
    --symbol = generate symbols in .symbol format (pasmo)
    --omds = generate symbols in .omds format (openMSX deprecated)
    --lin = write the MSX-BASIC line numbers in the binary code
    --vscode = initialize a VSCode MSX-BASIC project in the current path

Output: <filename.rom>

See more information at:
https://github.com/amaurycarvalho/msxbas2rom/wiki/Usage

Help us to maintain this project, learn how:
https://github.com/amaurycarvalho/msxbas2rom/wiki/Contributing 
```
