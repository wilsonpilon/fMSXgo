# fossauro — referência do fMSX original

**fossauro** é baseado na **versão 6.0 do fMSX**, o emulador de MSX/MSX2/MSX2+ escrito em C por
**Marat Fayzullin** (<http://fms.komkon.org/>).

Este documento é a conversão para Markdown das partes da documentação original do fMSX
(`fMSX.html`, incluída na distribuição do código-fonte C) que ainda servem de referência de
comportamento para o port — mesma lógica de `docs/reference/*.md` do Basic Dignified original (ver
`CLAUDE.md` na raiz do repositório): espec a portar, não dependência de runtime. Partes do HTML
original que não se aplicam mais foram removidas: "New in This Version", "Introduction", "fMSX Ports"
(listagem de versões para Android/Windows/Linux/Unix), "Registered Users", "History" e "Thanks to...",
além das perguntas do FAQ específicas de compilação em Unix/Linux.

Nem tudo listado abaixo já está implementado em fossauro hoje — ver `docs/MANUAL.md`, seção Fossauro,
pro que já funciona de verdade (hoje só `-rom <arquivo>` e `-verbose`) contra o que é a interface
completa do fMSX original.

---

## Atribuição de teclado (fMSX original)

```
[CONTROL]       - CONTROL (also: joystick FIRE-A button)
[SHIFT]         - SHIFT (also: joystick FIRE-B button)
[ALT]           - GRAPH (also: swap joysticks)
[INSERT]        - INSERT
[DELETE]        - DELETE
[HOME]          - HOME/CLS
[END]           - SELECT
[PGUP]          - STOP/BREAK
[PGDOWN]        - COUNTRY
[F6]            - Load emulation state from .STA file
[F7]            - Save emulation state to .STA file
[F8]            - Rewind emulation back in time
[F9]            - Fast-forward emulation
[F10]           - Invoke built-in configuration menu
[F11]           - Reset hardware
[F12]           - Quit emulation
[CONTROL]+[F8]  - Toggle scanlines on/off
[ALT]+[F8]      - Toggle screen softening on/off
[CONTROL]+[F10] - Go to the built-in debugger
```

## Opções de linha de comando (fMSX original)

```
Usage: fmsx [-option1 [-option2...]] [filename1] [filename2]

  [filename1] = name of file to load as cartridge A
  [filename2] = name of file to load as cartridge B

  When compiled with #define ZLIB, fMSX will transparently
  uncompress singular GZIPped and PKZIPped files.

  [-option] =
  -verbose <level>    - Select debugging messages [1]
                        0 - Silent       1 - Startup messages
                        2 - V9938 ops    4 - Disk/Tape
                        8 - Memory      16 - Illegal Z80 ops
  -skip <percent>     - Percentage of frames to skip [25]
  -pal/-ntsc          - Set PAL/NTSC HBlank/VBlank periods [NTSC]
  -help               - Print this help page
  -home <dirname>     - Set directory with system ROM files [off]
  -printer <filename> - Redirect printer output to file [stdout]
  -serial <filename>  - Redirect serial I/O to a file [stdin/stdout]
  -diska <filename>   - Set disk image used for drive A: [DRIVEA.DSK]
                        (multiple -diska options accepted)
  -diskb <filename>   - Set disk image used for drive B: [DRIVEB.DSK]
                        (multiple -diskb options accepted)
  -tape <filename>    - Set tape image file [off]
  -font <filename>    - Set fixed font for text modes [DEFAULT.FNT]
  -logsnd <filename>  - Set soundtrack log file [LOG.MID]
  -state <filename>   - Set emulation state save file [automatic]
  -auto/-noauto       - Use autofire on SPACE [off]
  -ram <pages>        - Number of 16kB RAM pages [4/8/8]
  -vram <pages>       - Number of 16kB VRAM pages [2/8/8]
  -rom <type>         - Select MegaROM mapper types [8,8]
                        (two -rom options accepted)
                        0 - Generic 8kB   1 - Generic 16kB (MSXDOS2)
                        2 - Konami5 8kB   3 - Konami4 8kB
                        4 - ASCII 8kB     5 - ASCII 16kB
                        6 - GameMaster2   7 - FMPAC
                        >7 - try guessing mapper type
  -msx1/-msx2/-msx2+  - Select MSX model [-msx2]
  -joy <type>         - Select joystick types [0,0]
                        (two -joy options accepted)
                        0 - No joystick
                        1 - Normal joystick
                        2 - Mouse in joystick mode
                        3 - Mouse in real mode
  -simbdos/-wd1793    - Simulate DiskROM disk access calls [-wd1793]
  -sound [<quality>]  - Sound emulation quality (Hz) [44100]
  -nosound            - Same as '-sound 0'
  -sync <frequency>   - Sync screen updates to <frequency> [60]
  -nosync             - Do not sync screen updates [-nosync]
  -static/-nostatic   - Use static color palette [-nostatic]
  -tv/-lcd/-raster    - Simulate TV scanlines or LCD raster [off]
  -linear             - Scale display with linear interpolation [off]
  -soft/-eagle        - Scale display with 2xSaI or EAGLE [off]
  -epx/-scale2x       - Scale display with EPX or Scale2X [off]
  -cmy/-rgb           - Simulate CMY/RGB pixel raster [off]
  -mono/-sepia        - Simulate monochrome or sepia CRT [off]
  -green/-amber       - Simulate green or amber CRT [off]
  -4x3                - Force 4:3 television screen ratio [off]

  With #define DEBUG:
  -trap <address>     - Trap execution when PC reaches address [FFFFh]
                        (when keyword 'now' is used in place of the
                        <address>, execution will trap immediately)
```

## Perguntas frequentes (FAQ, fMSX original)

**Onde eu consigo software MSX?**
Veja <http://fms.komkon.org/MSX/> e siga os links de lá.

**O que eu faço com arquivos `.BAS`, `.GMB`, `.CRC`, `.LDR`?**
São programas BASIC. Rode a partir do MSX BASIC com `RUN "filename"`.

**O que eu faço com arquivos `.BIN`, `.OBJ`, `.GM`?**
São arquivos binários BLOADable. Rode a partir do MSX BASIC com `BLOAD "filename",R`.

**O que eu faço com arquivos `.COM`?**
São arquivos de comando do MSXDOS. Rode a partir do MSXDOS digitando o nome sem a extensão `.COM`.

**O que são os arquivos `.ROM`?**
Imagens binárias de ROMs de cartucho carregáveis no fMSX/fossauro. Cartuchos "pequenos" são de 8kB,
16kB ou 32kB; MegaROMs podem ser 128kB, 256kB ou até 512kB.

**O que são os arquivos `.ROM` incluídos com o fMSX?** (mesmos nomes usados em `fossauro/`)

```
MSX.ROM      - Standard MSX BIOS and BASIC code
MSX2.ROM     - MSX2 BIOS and BASIC code
MSX2EXT.ROM  - MSX2 ExtROM containing system extensions
MSX2P.ROM    - MSX2+ BIOS and BASIC code
MSX2PEXT.ROM - MSX2+ ExtROM containing system extensions
DISK.ROM     - MSX DiskROM containing BDOS and Disk BASIC (optional)
RS232.ROM    - RS232 BIOS and BASIC extensions (optional)
FMPAC.ROM    - FM-PAC BIOS and BASIC extensions (optional)
MSXDOS2.ROM  - MSXDOS2 system core (optional)
PAINTER.ROM  - Yamaha Painter, graphical editor found in Russian MSX
               machines from Yamaha (optional)
GMASTER.ROM  - Konami GameMaster, a game cheating tool (optional).
GMASTER2.ROM - Konami GameMaster2, a game cheating tool (optional).
KANJI.ROM    - ROM with Kanji character images (optional)
CMOS.ROM     - Non-volatile memory used in MSX2 and MSX2+. This file gets
               overwritten on exit if non-volatile memory has been changed.
```

Nem todos esses arquivos necessariamente acompanham uma cópia do fMSX/fossauro.

**Como eu uso disquetes com o fMSX?**
Tenha o arquivo `DISK.ROM` (MSX DiskROM) no diretório atual. Crie imagens de disco a partir de um MSX
real com uma ferramenta como `DCOPY.EXE` (MSDOS) ou `cp /dev/rfd0 <filename>.DSK` (Unix) — são só
arquivos raw com todos os blocos do disco em sequência. Depois rode com
`fmsx -diska <filename1>.DSK -diskb <filename2>.DSK`, ou use os nomes padrão `DRIVEA.DSK`/`DRIVEB.DSK`
no diretório atual.

**Tem um jeito mais fácil de trabalhar com imagens de disco?**
Os programas `wrdsk`/`rddsk` que acompanham o fMSX: `wrdsk <filename>.DSK <file> <file> ...` cria uma
imagem e adiciona arquivos; `rddsk <filename>.DSK [-d <dir>] [<file> <file> ...]` lê arquivos de uma
imagem existente. (fossauro tem seu próprio gerenciador de disco nativo no IDE Paleobasic — ver
`docs/MANUAL.md`, seção "Gerenciador de disco MSX" — que cobre o mesmo caso de uso pro `.dsk` do
Paleobasic, não do fMSX/fossauro diretamente.)

**Alguns programas BASIC não funcionam no emulador.**
Muitos loaders esperam uma máquina com só um drive de disquete e usam a memória dedicada ao segundo
drive. Dois "passes mágicos" costumam resolver: `[CTRL]+[DEL]` no boot pra desligar o segundo drive, e
`POKE &hFFFF,&hAA` antes de rodar o loader pra configurar o gerenciador de memória do jeito que a
maioria dos loaders espera.

**Algumas imagens ROM não funcionam no emulador.**
Se a imagem for maior que 32kB, tente `-rom <N>` com valores diferentes de `<N>` (ver a tabela de
opções de linha de comando acima).

**É legal distribuir ROMs de cartucho?**
Não. Ninguém parece se importar muito, principalmente porque não há mais lucro a se fazer com software
MSX — mas distribuir software comercial que você não comprou é, tecnicamente, pirataria.
