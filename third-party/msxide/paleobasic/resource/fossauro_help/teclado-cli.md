# Teclado e linha de comando (referência fMSX original)

Esta é a referência de teclado e linha de comando do **fMSX 6.0** original (Marat Fayzullin), no qual
o Fossauro é baseado. Nem tudo listado aqui está implementado hoje - veja o tópico "Status atual"
nesta mesma ajuda pra saber o que já tem efeito de verdade contra o que ainda é só aceito/ignorado.

## Atribuição de teclado

```
[CONTROL]       - CONTROL (também: botão FIRE-A do joystick)
[SHIFT]         - SHIFT (também: botão FIRE-B do joystick)
[ALT]           - GRAPH (também: troca os joysticks)
[INSERT]        - INSERT
[DELETE]        - DELETE
[HOME]          - HOME/CLS
[END]           - SELECT
[PGUP]          - STOP/BREAK
[PGDOWN]        - COUNTRY
[F6]            - Carregar estado de um arquivo .STA
[F7]            - Salvar estado num arquivo .STA
[F8]            - Retroceder a emulação no tempo
[F9]            - Avançar a emulação rapidamente
[F10]           - Abrir o menu de configuração embutido
[F11]           - Reset do hardware
[F12]           - Sair da emulação
[CONTROL]+[F8]  - Ligar/desligar scanlines
[ALT]+[F8]      - Ligar/desligar suavização de tela
[CONTROL]+[F10] - Ir para o depurador embutido
```

## Opções de linha de comando

```
Uso: fossauro [-opcao1 [-opcao2...]] [arquivo1] [arquivo2]

  [arquivo1] = nome do arquivo a carregar como cartucho A
  [arquivo2] = nome do arquivo a carregar como cartucho B

  [-opcao] =
  -verbose <nivel>    - Nivel de mensagens de depuracao [1]
                        (bitmask propria do fossauro: 1=geral, 2=memoria,
                        4=VDP, 8=PSG, 16=CPU - nao e a mesma numeracao
                        do -verbose <level> do fMSX real)
  -skip <percent>     - Percentual de frames a pular [25]
  -pal/-ntsc          - Define o periodo HBlank/VBlank PAL/NTSC [NTSC]
  -help               - Imprime esta pagina de ajuda
  -home <pasta>       - Pasta com os arquivos de ROM do sistema [off]
  -printer <arquivo>  - Redireciona a saida da impressora pro arquivo [stdout]
  -serial <arquivo>   - Redireciona E/S serial pro arquivo [stdin/stdout]
  -diska <arquivo>    - Imagem de disco pro drive A: [DRIVEA.DSK]
  -diskb <arquivo>    - Imagem de disco pro drive B: [DRIVEB.DSK]
  -tape <arquivo>     - Arquivo de fita cassete [off]
  -font <arquivo>     - Fonte fixa pros modos texto [DEFAULT.FNT]
  -logsnd <arquivo>   - Arquivo de log da trilha sonora [LOG.MID]
  -state <arquivo>    - Arquivo de estado de emulacao [automatico]
  -auto/-noauto       - Autofire no SPACE [off]
  -ram <paginas>      - Numero de paginas de RAM de 16kB [4/8/8]
  -vram <paginas>     - Numero de paginas de VRAM de 16kB [2/8/8]
  -rom <tipo>         - Tipo de mapeador MegaROM [8,8]
                        0 - Generic 8kB   1 - Generic 16kB (MSXDOS2)
                        2 - Konami5 8kB   3 - Konami4 8kB
                        4 - ASCII 8kB     5 - ASCII 16kB
                        6 - GameMaster2   7 - FMPAC
                        >7 - tenta adivinhar o tipo
  -msx1/-msx2/-msx2+  - Seleciona o modelo MSX [-msx2]
  -joy <tipo>         - Tipo de joystick [0,0]
                        0 - Sem joystick
                        1 - Joystick normal
                        2 - Mouse em modo joystick
                        3 - Mouse em modo real
  -simbdos/-wd1793    - Simula chamadas de disco da DiskROM [-wd1793]
  -sound [<qualidade>]- Qualidade de emulacao de som (Hz) [44100]
  -nosound            - Igual a '-sound 0'
  -sync <frequencia>  - Sincroniza a tela com <frequencia> [60]
  -nosync             - Nao sincroniza a tela [-nosync]
  -static/-nostatic   - Usa paleta de cores estatica [-nostatic]
  -tv/-lcd/-raster    - Simula scanlines de TV ou raster de LCD [off]
  -linear             - Escala a tela com interpolacao linear [off]
  -soft/-eagle        - Escala a tela com 2xSaI ou EAGLE [off]
  -epx/-scale2x       - Escala a tela com EPX ou Scale2X [off]
  -cmy/-rgb           - Simula raster de pixel CMY/RGB [off]
  -mono/-sepia        - Simula CRT monocromatico ou sepia [off]
  -green/-amber       - Simula CRT verde ou ambar [off]
  -4x3                - Forca proporcao de tela de TV 4:3 [off]

  Flags proprias do Fossauro (nao existem no fMSX original):
  -vscale <1-4>       - Escala inteira da janela (1:1/2:1/3:1/4:1) - so
                        "1" funciona hoje sem travar, ver "Status atual"
```

## Perguntas frequentes (do fMSX original)

**O que eu faço com arquivos `.BAS`, `.GMB`, `.CRC`, `.LDR`?**
São programas BASIC. Rode a partir do MSX BASIC com `RUN "nomedoarquivo"`.

**O que eu faço com arquivos `.BIN`, `.OBJ`, `.GM`?**
São arquivos binários carregáveis via BLOAD. Rode a partir do MSX BASIC com
`BLOAD "nomedoarquivo",R`.

**O que são os arquivos `.ROM`?**
Imagens binárias de ROM de cartucho carregáveis no Fossauro. Cartuchos "pequenos" são de 8kB, 16kB
ou 32kB; MegaROMs podem ser 128kB, 256kB ou até 512kB.

**Algumas imagens ROM não funcionam no emulador.**
Se a imagem for maior que 32kB, tente `-rom <N>` com valores diferentes de `<N>` (ver a tabela de
opções de linha de comando acima), ou use **Hardware -> Cartridge Slot A/B -> Mapper Type** na
janela do próprio Fossauro.

Para o texto completo original do fMSX (incluindo as perguntas sobre distribuição de ROMs, imagens
de disquete, etc.), veja `fossauro/fossauro.md` no repositório.
