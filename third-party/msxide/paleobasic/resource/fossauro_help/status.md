# Status atual do Fossauro

**Fossauro** é um port nativo em PureBasic do emulador **fMSX** de Marat Fayzullin - projeto irmão
dentro deste repositório, com licença própria (não-comercial). Roda como executável separado
(`fossauro/fossauro.exe`), nunca linkado nem distribuído junto com o Paleobasic.

## O que já funciona hoje

- **Boot completo dos três modelos**: MSX1 ("MSX BASIC version 1.0"), MSX2 ("MSX BASIC version 2.1")
  e MSX2+ ("MSX BASIC version 3.0"), carregando a BIOS certa por modelo.
- **Menu File**: Open Cartridge..., Save Snapshot.../Open Snapshot... (estado completo da máquina em
  arquivo `.fss`), Quit. Open Disk... aceita o arquivo mas ainda não faz nada com ele (sem
  controlador de disquete ligado ao boot ainda).
- **Menu Hardware**: troca de Model (MSX1/MSX2/MSX2+), RAM Size (64-1024KB), VRAM Size (16-192KB) e
  Cartridge Slot A/B (com detecção de mapper MegaROM) - todos com reset completo, todos também
  setáveis por linha de comando.
- **Menu Video**: `Scale -> 1:1` e `Force 4:3 screen ratio` funcionam. **2:1/3:1/4:1 mostram um aviso
  em vez de aplicar** - bug real de travamento confirmado nesta máquina em qualquer janela maior que
  512x384 (não é sobre redimensionar em si - até um processo novo já nasce travado com `-vscale 2`).
- **Menu Emulation**: Reset, Pause, Resume.
- **Áudio**: PSG AY-3-8910 com síntese real por amostra (não um esqueleto), verificado tocando de
  ponta a ponta.

## O que ainda não funciona

- **Disco (FDC)**: o controlador WD1793 existe e foi verificado isoladamente (registradores, leitura/
  escrita de setor batendo byte-a-byte contra uma imagem `.dsk` real), mas ligar o `DISK.ROM` no mapa
  de memória trava o boot - ainda não conectado por causa disso.
- **Fita cassete (.CAS)** e **cheats (.CHT)**: seletores de arquivo existem, sem lógica por trás.
- **Escala de vídeo 2:1/3:1/4:1**: ver acima.
- Joystick/mouse, impressora, porta serial, Kanji ROM.

## Linha de comando

`fossauro.exe` aceita a linha de comando do fMSX original - `fossauro -help` imprime a lista
completa e é a referência viva. As flags com efeito real hoje: `-msx1`/`-msx2`/`-msx2+`, `-pal`/
`-ntsc`, `-ram <páginas>`, `-vram <páginas>`, `-verbose [<máscara>]`, `-vscale <1-4>` (só `1` sem o
bug de travamento), `-4x3`, cartucho posicional (`[arquivo1] [arquivo2]`). O resto (disco, fita, som,
joystick, filtros de vídeo, etc.) é aceito mas ainda sem efeito.

Para a referência completa de teclado e todas as opções de linha de comando (incluindo as ainda sem
efeito), veja o tópico "Teclado e linha de comando" nesta mesma ajuda.
