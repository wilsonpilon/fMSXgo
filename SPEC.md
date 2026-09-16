# fMSXgo - Especificação Técnica e Roteiro Vivo (SPEC.md)

> **Documento Vivo de Engenharia do fMSXgo**
> Este documento rastreia o status atual do projeto, o histórico das fases, decisões arquiteturais, o que já foi entregue e os próximos passos imediatos.

---

## 1. Esquema de Versionamento & Nomenclatura Criativa

O versionamento segue a regra rigorosa: **`V X.Y.Z`**

* **`X` (Major)**: Incrementado a cada grande bloco/marco de funcionalidade fechado (Ex.: Núcleo Z80 100% estabilizado e certificado = V 1.0.0; VDP completo = V 2.0.0).
* **`Y` (Minor)**: Incrementado a cada nova funcionalidade ou subsistema implementado e colocado em operação (Ex.: SQLite storage, menu gráfico, VDP line renderer, PSG).
* **`Z` (Build/Patch)**: Incrementado a cada compilação/build gerado pelo utilitário de automação (`build.ps1`).

### Codinomes das Versões (Heavy Metal / Horror / MSX Lore)

| Versão Base | Codinome Criativo | Referência / Inspiração |
| :--- | :--- | :--- |
| **V 0.1.x** | **Phantasm (The Tall Man)** | Clássico do terror de Don Coscarelli / atmosfera sombria |
| **V 0.2.x** | **Aleste Nightmare** | Franquia lendária da Compile no MSX + Pesadelo em Elm Street |
| **V 0.3.x** | **Cemetery Gates** | Pantera / Atmosfera gótica e heavy metal pesado |
| **V 0.4.x** | **Evil Dead (Necronomicon)** | Franquia de Sam Raimi / invocação de binários brutos |
| **V 0.5.x** | **Iron Maiden (Powerslave)** | Heavy metal clássico / precisão egípcia de timing Z80 |
| **V 1.0.x** | **Vampire Killer (Dracula's Curse)** | Obra-prima da Konami no MSX / lançamento da versão 1.0 |

*Versão Atual:* **V 0.1.0 ("Phantasm")**

---

## 2. Visão Geral das Fases do Projeto

### Fase 1: Fundação do Sistema & Arquitetura de Dados [EM ANDAMENTO - 90%]
- [x] Inicialização do módulo Go 64-bit (`fmsxgo`).
- [x] Emulação fiel do processador Z80 (instruções Base, CB, ED, DD/FD, DDCB/FDCB, ciclo de clocks e tabelas `ZSTable` e `PZSTable`).
- [x] Suporte ao opcode de hook de BIOS `ED FE` (`PatchZ80`).
- [x] Disassembler de instruções Z80 em tempo real.
- [x] Mini-Assembler interativo integrado (permite montagem direta de mnemônicos na memória).
- [x] Matriz de barramento MSX: 4 Slots Primários (`0xA8`), 4 Subslots Secundários (`0xFFFF`), mapeamento das 4 páginas de 16KB / 8 de 8KB.
- [x] Suporte a RAM Mapper (portas `0xFC` a `0xFF`, de 64KB até 4MB).
- [x] Detecção e proteção contra escrita em páginas de ROM (BIOS/Cartucho) vs RAM.
- [x] Monitor / Shell CLI Interativo ("SO de Desenvolvimento") com comandos: `r`, `d`, `e`, `u`, `a`, `t`, `p`, `g`, `bp`, `slots`, `mapper`, `in`, `out`, `reset`, `help`, `quit`.
- [x] Parâmetros de linha de comando clássicos do fMSX (`-msx1`, `-msx2`, `-msx2+`, `-ram`, `-vram`, `-rom`, `-diska`, `-diskb`, `-pal`, `-ntsc`) e flags avançadas (`--help`, `--no-window`, `-cli`, `-exec`, `-test`).
- [/] **Persistência Centralizada via SQLite (`fmsxgo.db`)**:
  - [ ] Schema do banco: Tabela de Configurações, Máquinas, Manuais/Help e ROMs (armazena arquivos de BIOS, ExtBIOS, DiskROM em BLOB).
  - [ ] Módulo interno de carregamento de ROMs direto do SQLite, reduzindo a distribuição a arquivos únicos.
- [/] **Interface Gráfica Base**:
  - [x] Suporte a Ebitengine para Windows e Linux 64-bit (sem dependência de GCC/CGO no Windows).
  - [ ] Janela gráfica básica exibindo tela do emulador.
  - [ ] Barra de Menus: `File -> Exit` e `Help -> About`.
  - [x] Flag `--no-window` que inicia no modo terminal CLI.
- [/] **Script de Automação de Build e Distribuição (`build.ps1`)**:
  - [ ] Restaura dependências Go.
  - [ ] Incrementa a versão de compilação `Z`.
  - [ ] Popula/atualiza o banco SQLite com as ROMs e documentação.
  - [ ] Compila binário e empacota pasta `dist/` pronta para distribuição ao usuário final.

---

### Fase 2: Processador Gráfico VDP (TMS9918 / V9938 / V9958) [PENDENTE]
- [ ] Registradores de controle VDP (0..63) e registradores de status (0..15).
- [ ] VRAM: 128KB de memória de vídeo e buffers de página.
- [ ] Motor de renderização scanline-by-scanline (`RefreshLine0` a `RefreshLine12`):
  - [ ] Modo SCREEN 0 (Texto 40 e 80 colunas, atributos de cor e piscar).
  - [ ] Modo SCREEN 1 e 2 (Modos gráficos MSX1).
  - [ ] Modo SCREEN 3 (Modo Multicolor).
  - [ ] Modos SCREEN 4, 5, 6, 7, 8 (Modos gráficos MSX2 com paleta RGB).
  - [ ] Modos SCREEN 10, 11, 12 (Modos gráficos YJK e YAE do MSX2+).
- [ ] Sistema de Sprites:
  - [ ] Sprites Modo 1 (TMS9918: 32 sprites, 4 por scanline, detecção de colisão).
  - [ ] Sprites Modo 2 (V9938/V9958: 32 sprites, 8 por scanline, cores por linha, prioridades e atributos CC).
- [ ] Motor de Comandos Acelerados de VDP (em paralelo com CPU):
  - [ ] `HMMC`, `LMMC`, `LINE`, `HMMM`, `YMMM`, `LMMM`, `LMMV`, `HMMV`, `PSET`, `POINT`, `SRCH`.
- [ ] Sincronismo vertical e horizontal: interrupções IE0 (VBlank) e IE1 (Line coincidence).

---

### Fase 3: Subsistema de Áudio [PENDENTE]
- [ ] **AY-3-8910 / YM2149 (PSG)**: 3 canais de onda quadrada, gerador de ruído pseudo-aleatório, envelope analógico e portas de joystick/mouse.
- [ ] **Yamaha YM2413 (OPLL / MSX-MUSIC)**: Sintetizador FM de 9 canais ou 6 melódicos + 5 instrumentos de percussão rítmica.
- [ ] **Konami SCC / SCC+**: Sintetizador de tabela de ondas de 5 canais com registradores de forma de onda.
- [ ] **Mixer de Áudio**: Buffer estéreo PCM 44.1kHz/48kHz de baixa latência transmitido diretamente para o driver de som do Ebitengine.

---

### Fase 4: Controladores de Disco, Fita & I/O [PENDENTE]
- [ ] **Western Digital WD1793**: Emulação completa do controlador de floppy disk.
- [ ] **Suporte a Imagens de Disco**: Leitura e gravação de arquivos `.DSK` (720KB / 360KB) e `.FDI`.
- [ ] **Interface de Disco Brasileira**: Portas I/O `0xD0` a `0xD4` (padrão Gradiente Expert e Sharp HotBit).
- [ ] **Cassete / Fita**: Carga e gravação de arquivos `.CAS` e stream de áudio.
- [ ] **Teclado & Joysticks**: Mapeamento completo do teclado ABNT2/US para a matriz do MSX PPI 8255.

---

### Fase 5: Estação de Trabalho do Desenvolvedor / Hacker [PENDENTE]
- [ ] **Interactive Visual Debugger**:
  - [ ] Breakpoints condicionais (endereço PC, leitura/escrita de RAM, portas I/O, linha de scanline).
  - [ ] Histórico de execução circular (Time-Travel / Trace Buffer das últimas 10.000 instruções).
  - [ ] Importação de tabelas de símbolos e labels (`.sym`, `.map`, pasmo, asMSX, glass).
- [ ] **Editor Hexadecimal & Live Memory Patcher**:
  - [ ] Visualização em grade e edição ao vivo da RAM, VRAM, registradores VDP, PSG e SRAM.
  - [ ] Mecanismo de congelamento de valores (Cheats / Pokes).
- [ ] **Visualizador de Mappers & VDP**:
  - [ ] Painel gráfico mostrando os bancos mapeados em tempo real.
  - [ ] Inspetor de VRAM: visualização das Pattern Tables, Sprite Tables e Paleta de Cores.
- [ ] **Audio Channel Inspector**: Controle individual de mute/solo por canal de som (PSG, FM, SCC).

---

### Fase 6: Ponte de Integração Externa (MSX-IDE & Utilitários) [PENDENTE]
- [ ] Servidor de comunicação IPC / WebSocket / gRPC para depuração remota e injeção de binários compilados a partir de IDEs externas (como o `msxide`).
- [ ] Suporte a gravação de sessão de depuração.

---

## 3. Registro de "Onde Paramos"

* **Última Entrega**: Concluída a implementação e testes do Z80, slots, mini-assembler e monitor interativo CLI.
* **Ação em Execução**:
  1. Integração do banco de dados SQLite (`modernc.org/sqlite`) para unificar configurações, manuais, metadados e arquivos de BIOS/ROMs em um único banco.
  2. Implementação da janela gráfica básica (Ebitengine) com a barra de menus `File -> Exit` e `Help -> About`, mantendo suporte à flag `--no-window`.
  3. Criação do script de automação `build.ps1` com geração do diretório `dist/` e incremento de versão.
  4. Produção dos documentos `MANUAL.md`, `CHANGELOG.md` e atualização do `README.md`.
