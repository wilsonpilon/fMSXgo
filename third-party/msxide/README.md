# msxIDE

![msxIDE](images/msxide.png)

**v0.4.0 — "MAMUTE.FNT"** — *o mamute aprendeu a desenhar suas próprias letras, pixel a pixel.*

Um ambiente de desenvolvimento em modo texto (TUI) para MSX BASIC e Z80 Assembly, escrito em
FreeBASIC. Inspirado nas ferramentas clássicas de MS-DOS (EDIT, QuickBasic) e nos monitores/assemblers
interativos da era 8-bit do MSX.

📖 [MANUAL.md](MANUAL.md) — instalação, compilação, atalhos.
📐 [SPEC.md](SPEC.md) — arquitetura, decisões de projeto, o roadmap do Mamute Assembler.
📝 [CHANGELOG.md](CHANGELOG.md) — histórico de versões.

## O que já está implementado

- **Editor de texto em TUI**, multi-documento, janelas MDI (arrastar/redimensionar/maximizar/fechar),
  barras de rolagem, roda do mouse.
- **Editor de Markdown** (`.md`): três modos por `F7` — edição simples, dividido (preview ao vivo lado a
  lado) e somente leitura — reaproveitando o mesmo motor que renderiza toda a Ajuda do msxIDE.
- **Editor de Fontes MSX** (`.alf`/`.fnt`/`.chr`): mapa geral 16x16 e o caractere selecionado ampliado em
  pixels sempre visíveis lado a lado, lê/grava o formato BSAVE real de fonte do MSX (semeado a partir de
  `roms/msx1.alf`), e se integra ao sistema de projetos (vários alfabetos por projeto, listados e
  selecionáveis direto no rodapé do editor).
- **Editor de Sprites MSX** (`.spr`): mesma base visual do editor de Fontes — mapa geral e preview
  ampliado lado a lado — para bancos de sprite 8x8 ou 16x16 (4 padrões por sprite, ordem real de
  quadrantes do VDP), em modo de cor MSX1 (1 cor por sprite) ou MSX2 (1 cor por linha), com uma tela
  dedicada de seleção entre as 16 cores do MSX (tecla `C`) e a mesma integração com projetos (vários
  bancos por projeto, listados no rodapé do editor).
- **Compilação MSX BASIC / Basic Dignified**: gera `.amx`/`.bmx`, monta disco `.dsk` (boot MSX-DOS
  real) e lança o **openMSX** automaticamente.
- **Z80 Assembly via asMSX**: novo documento `.asm` com um "Hello ASM World" pronto; compilar+executar
  monta com o asMSX de verdade e oferece inserir o binário num programa BASIC aberto (`BLOAD` direto,
  loader `DATA`/`POKE`+`DEFUSR`, ou `.inc` reaproveitável).
- **Sistema de projetos** (`.msxproj`): um arquivo SQLite portátil que empacota fontes, binários e
  configuração — abre extraindo pra uma pasta de trabalho, salva reimportando tudo de volta.
- **Ajuda integrada**: Basic Dignified, Dignified, BaToken, asMSX, dicionário MSX BASIC completo
  (verbete contextual com `Shift+F1`), e um guia do próprio editor.
- **Menu Referência**: dez documentos técnicos MSX portados pra dentro do IDE — The MSX Red Book, MSX2
  Technical Handbook, manuais MSX-DOS2/Z80/R800/Turbo-Basic/FM-PAC, BIOS Chamadas/Hardware/
  Documentação, openMSX, Nestor Basic, SEE Tracker, MSXBAS2ROM.
- **Mamute Assembler**: monitor/assembler Z80 interativo completo, réplica de um monitor de MSX
  clássico. Configurador de memória simulada (slots, sub-slots, páginas, RAM/ROM/BIOS/BASIC/EXTBIOS) e
  terminal `MON>` estilo ZX-81 com todos os comandos do monitor (`PAGE`, `DM`, `ZAP`, `SCR`, `SH`, `MS`,
  `LOAD`/`SAVE`, `M`/`S`/`C`/`D`/`P`/`V`, `T`/`F`, `G`/`X`/`R`, `L`/`LP`, `HELP`). O comando `M` abre um
  editor hexadecimal interativo em grade (128 bytes, navegação por setas/PgUp/PgDn); o comando `EDIT`
  abre um editor de linhas de programa-fonte estilo ZX-81 (`NN Label: instrução ;comentário`, com
  `NEW`/`DELETE`/`RENUM`/`CHANGE`/`SEARCH`/`LSEARCH`/`SAVE`/`LOAD`/`MERGE`) que monta o programa de
  verdade com um **assembler Z80 nativo** (compatível M80/Nestor80, todos os modos de endereçamento
  documentados e indocumentados) através do comando `A` (grava na RAM simulada, gera listagem/referência
  cruzada/lista de símbolos, exporta binário `BSAVE`). O Mamute também começou a incorporar o
  **SUPER-X**, o segundo monitor clássico de MSX (endereçamento estendido por slot/sub-slot/VRAM,
  `XCL`/`XD`/`XA`/`XI`/`XF`), e ganhou uma **impressora virtual** de verdade: `P`/`V`/`LP` e qualquer
  comando prefixado com `?` geram um PDF real (papel A4 ou formulário contínuo picotado/zebrado,
  configurável em `Configurar -> Impressora`), que já abre sozinho no visualizador padrão do Windows.
  Detalhes em [SPEC.md](SPEC.md#2-módulo-mamute-assembler).

## Ferramentas usadas neste projeto

- **[Claude Code](https://claude.com/claude-code)** (Anthropic) — pair programming, pesquisa e
  implementação assistida por IA.
- **FreeBASIC** — linguagem/compilador do msxIDE.
- **[newt-freebasic](https://github.com/paul-swan/newt-freebasic)** — biblioteca de terminal usada pelo
  backend de console alternativo (`--Backend newt`).
- **Windows 11** + **Windows Console API** — backend nativo padrão.
- **PowerShell** — build, versionamento e testes (`build.ps1`, `tests/`).
- **SQLite** — persistência de configurações, projetos e métricas.
- **Visual Studio Code** + **GitHub** — desenvolvimento e versionamento.

## Agradecimentos

O msxIDE se apoia em ferramentas e documentação de terceiros — nossa gratidão a quem as criou:

- **[Fred Rique (farique1)](https://github.com/farique1)**, autor da
  **[Basic Dignified Suite](https://github.com/farique1/basic-dignified)**, o compilador/tokenizer de
  MSX BASIC usado neste projeto.
- **Eduardo "pitpan" A. Robsy Petrus**, criador original do **[asMSX](https://www.msx.org/wiki/asMSX)**
  (baseado na liberação GPLv3 de Lucas "cjv99", hoje mantido pelo time asMSX), o cross-assembler Z80
  usado para Z80 Assembly.
- **Cibertron Software**, criadores do **Mega Assembler** (1987), o monitor/assembler/desmontador
  original em cartucho que inspira metade do Mamute Assembler.
- **Romi**, autor original do **SUPER-X** (1994), o monitor/debugger avançado que inspira a outra
  metade do Mamute Assembler — e **NYYRIKKI**, autor da versão estendida (2011), com tradução do
  japonês por **JP Grobler**.

## Módulos do msxIDE (nomes pré-históricos)

Tradição herdada do projeto-irmão `paleobasic/` (onde o próprio Mamute Assembler já nasceu com esse
apelido): cada módulo do msxIDE tem um nome de bicho pré-histórico. Tabela completa e o porquê de cada
um em [SPEC.md](SPEC.md#1-visão-geral-da-arquitetura).

| Arquivo | Apelido |
|---|---|
| `main.bas` | Trilobita |
| `editor.bas` | Tiranossauro |
| `compiler.bas` | Pteranodonte |
| `db.bas` | Arqueloni |
| `project.bas` | Amonite |
| `console.bas` | Ictiossauro |
| `console_win.bas` | Anquilossauro |
| `console_newt.bas` | Salamandra |

## Início rápido

```powershell
.\build.ps1 --Basic C:\dos\freebasic --Compiler fbc64.exe --Backend win
.\msxide.exe
```

Veja [MANUAL.md](MANUAL.md) para instruções completas de instalação, compilação e uso.

## Licença

GPLv3 — ver [LICENSE](LICENSE).
