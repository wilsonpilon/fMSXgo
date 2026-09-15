# SPEC — msxIDE

Este documento é a referência de arquitetura e decisões de projeto do msxIDE. A seção principal
(Mamute Assembler) registra tudo o que foi levantado e decidido sobre a réplica do monitor/assembler
Z80 interativo — a fonte de verdade para continuar esse trabalho em sessões futuras, comando por
comando, sem precisar re-pesquisar o que já foi resolvido.

Para o guia de instalação/uso, veja [MANUAL.md](MANUAL.md). Para o histórico de versões, veja
[CHANGELOG.md](CHANGELOG.md).

## Índice

1. [Visão geral da arquitetura](#1-visão-geral-da-arquitetura)
2. [Módulo: Mamute Assembler](#2-módulo-mamute-assembler)
3. [Sistema de ajuda / referência](#3-sistema-de-ajuda--referência)
4. [Sistema de projetos (.msxproj)](#4-sistema-de-projetos-msxproj)

---

## 1. Visão geral da arquitetura

O msxIDE é um único binário FreeBASIC (`msxide.exe`), compilado a partir de seis unidades de
compilação (`src/main.bas src/editor.bas src/compiler.bas src/db.bas src/project.bas src/console.bas`,
ver `build.ps1`). `console_win.bas`/`console_newt.bas` são puxados por `#Include Once` dentro de
`console.bas`, escolhidos em tempo de compilação via `-d MSX_CONSOLE_WIN` ou `-d MSX_CONSOLE_NEWT`.

Cada módulo tem um apelido pré-histórico — mesma tradição do projeto-irmão `paleobasic/` (onde o
próprio Mamute Assembler já nasceu com esse nome), aplicada aqui aos módulos do msxIDE:

| Arquivo | Apelido | Por quê |
|---|---|---|
| `src/main.bas` | **Trilobita** | O primeiro fóssil — inicializa banco, console e o loop principal. |
| `src/editor.bas` | **Tiranossauro** | O módulo dominante: janelas, menus, ajuda, e agora o Mamute. |
| `src/compiler.bas` | **Pteranodonte** | Voa o programa pronto até o disco e o openMSX. |
| `src/db.bas` | **Arqueloni** | A tartaruga gigante da persistência — memória de longo prazo em SQLite. |
| `src/project.bas` | **Amonite** | A concha que empacota tudo (fontes, config, binários) num `.msxproj` portátil. |
| `src/console.bas` | **Ictiossauro** | Nada entre dois mundos — escolhe o backend nativo do Windows ou o newt. |
| `src/console_win.bas` | **Anquilossauro** | Blindado e pesado — 100% nativo da Windows Console API. |
| `src/console_newt.bas` | **Salamandra** | O backend newt — já nasceu com nome de anfíbio de verdade. |

Persistência: `msxide.db` (SQLite, carregado via `sqlite3.dll` em runtime, binding manual em `db.bas`).
Chaves de configuração prefixadas com `cfg.` são automaticamente espelhadas para o projeto ativo
(`.msxproj`) quando houver um aberto — ver seção 4.

### 1.1. O que o msxIDE lê em runtime (manifesto de distribuição)

Além de `msxide.exe` + `sqlite3.dll`, o programa lê estes caminhos relativos ao seu próprio diretório
de trabalho — é exatamente isso que `build-distribute.ps1` empacota em `distribute/`:

| Caminho | Usado por |
|---|---|
| `ajuda\*.pbi` | Menu `Referência` (Red Book, Handbook, BIOS, manuais, openMSX) e o dicionário MSX BASIC (`Ajuda -> MSX BASIC Dictionary`) — lidos diretamente em runtime, ver seção 3. |
| `docs\help\*.md` | `Ajuda -> Editor`/`Ajuda -> Markdown`, e os itens `Referência` que são markdown simples (Nestor Basic, SEE Tracker, MSXBAS2ROM). |
| `roms\msx1.alf` | Fonte MSX1 padrão que semeia todo `Arquivo -> Novo Editor de Fontes` (`EditorCreateFontUntitled`, `editor.bas`) — dump BSAVE de 256 caracteres 8x8. Os demais `roms\*.ROM` (BIOS/BASIC/DISK) não são empacotados aqui — apontados manualmente pelo usuário em `Configurar -> Mamute`. |
| `basic-dignified\documentation\*.md` | `Ajuda -> Basic Dignified/Dignified/BaToken`. |
| `basic-dignified\support\*.ini`, `basic-dignified\msx\*.ini`, `basic-dignified\msx\msxbatoken\*.ini` | Valores padrão semeados no banco no primeiro uso (`SeedConfigFromIni`, `db.bas`) — opcional, se ausente o msxIDE usa os defaults embutidos no código. |
| `basic-dignified\msx\openmsx_output.tcl` | Ponte de monitoramento de saída do openMSX (`Compilar + Executar`). |
| `asMSX\asmsx.exe`, `asMSX\doc\asmsx.md` | Compilação de Z80 Assembly e `Ajuda -> asMSX`. |
| `openmsx.exe` (externo, não empacotado) | `Compilar + Executar no emulador` — caminho configurado em `Configurar -> Emulador`. |

Instalador nativo (`installer/installer.bas` → `installer.exe`, aceita `instalador.exe <pasta>` pra
instalação silenciosa): copia `distribute\` pra pasta escolhida, cria atalho no Menu Iniciar e
**tenta** registrar entrada de desinstalação em "Aplicativos e recursos" (`HKCU\...\Uninstall\msxIDE`,
via um `.bat` gerado com `reg add` linha a linha — não um `.reg` importado por `regedit /s`, que se
mostrou pouco confiável nos testes: às vezes criava a chave mas deixava os valores vazios, sem erro
nenhum). Esse registro é **best-effort**: o instalador confere depois (`reg query .../v DisplayName`)
se realmente colou e avisa com uma mensagem honesta em vez de fingir sucesso — em algumas máquinas
(confirmado nesta sessão) um antivírus/EDR bloqueia silenciosamente (`Access is denied`) escrita nesse
ramo específico do registro vinda de um `.exe` recém-compilado e não assinado. O core da instalação
(copiar arquivos + criar atalho) nunca depende desse registro — se ele falhar, o msxIDE funciona
normalmente do mesmo jeito, só não some da lista de "Aplicativos e recursos" (o `desinstalar.bat`
dentro da pasta instalada continua removendo tudo manualmente).

O script de desinstalação gerado **não** usa o truque clássico de "copiar pra `%TEMP%` e re-executar"
pra apagar a própria pasta — esse padrão de auto-cópia+auto-deleção também foi flagrado pelo Windows
Defender como suspeito durante os testes desta sessão (colocou o `.bat` em quarentena, bloqueando até
leitura). Em vez disso, o script só troca o diretório de trabalho pra `%TEMP%` antes do `rmdir /s /q`
— suficiente no NTFS, sem acionar heurística nenhuma.

---

## 2. Módulo: Mamute Assembler

### 2.1. O que é

O **Mamute Assembler** é a réplica, dentro do msxIDE, de uma ferramenta homônima do projeto-irmão
`paleobasic/` — que por sua vez é uma mistura de dois monitores/assemblers Z80 interativos clássicos
de MSX:

- **Mega Assembler** (Cibertron Software, 1987) — cartucho de 16K com editor/assembler/desassembler/
  monitor, comandos de letra única (`DM`, `PAGE`, `L`/`LP`, `X`, `G`/`R`, `CL`, `SH`, `T`/`F`, `SCR`,
  `ZAP`) e um sub-editor de fonte numerado (`EDIT`) estilo ZX-81.
- **Super-X** (Romi, 1994; versão estendida/traduzida por NYYRIKKI, 2011, com tradução do japonês por
  JP Grobler) — monitor/debugger mais avançado, portado ao Mamute como uma segunda família de ~36
  comandos com prefixo `X` (`XD`/`XA`/`XI`/`XH`/`XM` como a "cruz" de modos, `XRG`/`XGO`/`XTR` para
  registradores/execução/trace, família `XFS`/`XSV`/`XLD`/`XDK`/etc. para disco, `XIR` para notas por
  endereço).

No paleobasic, o Mamute cresceu ao longo de dezenas de sessões (~25.000 linhas em ~25 arquivos
PureBasic), sempre **um comando de cada vez**, cada um implementado e validado contra o manual
original/screenshots reais antes do próximo. Essa é a estratégia que o msxIDE também segue.

### 2.2. Levantamento do original (paleobasic)

Investigação completa feita antes de começar o port (três frentes de leitura em paralelo, cobrindo os
~25 arquivos). Resumo do que existe lá, por relevância decrescente pro roadmap do msxIDE:

**Núcleo do assembler (`Z80Asm.pbi`, 4298 linhas)** — motor de 2 passes autocontido, sem nenhuma
dependência de UI, compatível com o dialeto M80/Nestor80 (validado byte a byte contra o `N80.exe`
real). Cobre todo o Z80 documentado + indocumentado (`SLL` incluso), diretivas `EQU/DEFL/ASET/ORG/
DEFB/DEFM/DEFW/DEFS/INCBIN/PUBLIC/EXTRN/IF*/MACRO/ENDM/REPT/PHASE/RADIX/...`, macros com renomeio
automático de símbolo local, avaliador de expressão RPN próprio, e até formato relocável `.REL`
completo (bit-stream, cabeçalho estendido de 16 bytes, `CSEG/DSEG/COMMON`). Listing e xref já vêm
prontos do próprio motor. **É a peça de maior alavancagem pra portar primeiro** — lógica pura, já
provada correta.

**Editor `EDIT` (`MamuteEditGui.pbi`, 1363 linhas)** — fonte numerado estilo ZX-81 (`NN Label: instrução
;comentário`), comandos imediatos sem número de linha (`LIST/NEW/DELETE/RENUM/CHANGE/SAVE/LOAD/MERGE/
SEARCH/QUIT/MAP`), e o comando `A`/`A O` que invoca `Z80Asm::Assemble()` de verdade, com 9 flags
combináveis (`O` grava RAM, `N` esconde nº de linha, `P` manda pra PDF, `I` salva binário, `R/S/D`
anexam xref/lista de símbolos, `/<offset>` remonta com `ORG` deslocado).

**Comandos clássicos do Mega Assembler** (letra única, ver `MamuteHelpData.pbi` para a doc completa):
`BA`/`QUIT` (sai), `PAGE` (mapa slot→página ativo), `DM`/`M`/`S` (dump/edição de memória em grade
hex+ASCII), `ZAP` (edição de setor de disco cru), `SCR` (tela gráfica 256×192 pixel-a-pixel — único
comando do Mamute que desenha pixel de verdade, não texto/grade), `SH` (busca de bytes/texto), `MS`
(grava string), `LOAD`/`SAVE`, `T`/`F` (copia/preenche bloco), `G`/`X`/`R` (registradores/execução —
`G`/`R` só validam sintaxe no original, nunca chegaram a executar), `L`/`LP` (disassembler completo),
`CL` (calculadora hex/bin/dec com precedência de operador).

**Emulador de CPU Z80 (`MamuteZ80Cpu.pbi`, 1267 linhas)** — núcleo Z80 puro (decisão explícita:
"começar por um simulador de Z80 puro, sem tentar simular o MSX inteiro — VDP/PSG/FDC/mapeador"),
100% desacoplado de UI (testado por harness `/CONSOLE`), rodando contra uma memória simulada de 4
slots × 4 páginas × 16KB. Instruções de bloco (`LDIR`/`OTIR`/etc.) executam passo a passo de verdade,
igual ao hardware real. **Sem conexão nenhuma com o openMSX real** — é simulação própria. Interrupções
são aceitas na sintaxe mas nunca disparadas (sem fonte de interrupção real).

**Debugger visual (`MamuteDebuggerGui.pbi`, 1024 linhas)** — janela dedicada com disassembly ao vivo
(PC destacado), registradores/pilha editáveis, minimapa de memória 16×16 clicável, `Step Into/Over/
Out/Run` com breakpoints. 100% GUI (mouse-driven) — não porta 1:1 pra uma TUI.

**Família de comandos `X??` (Super-X)** — 36 comandos, cada um com um card em `MamuteHelpData.pbi`
(ver tabela completa na seção 2.5). Todos reaproveitam a mesma infraestrutura de memória/disco/símbolos
já existente — nenhum reinventa a roda.

**Ferramentas auxiliares**: sistema de notas por endereço (`XIR`, 471 notas reais da BIOS/work area já
traduzidas japonês→português), painel de I/O simulado (`XPP`/`XPI`/`XPO`), exportação em PDF (feita à
mão, sem lib externa — mas sem valor numa TUI, o equivalente natural é só abrir a listagem como texto).

### 2.3. Decisões de design para o port no msxIDE

- **Linha de comando fixa embaixo + scrollback rolável em cima**, estilo ZX-81 — preferência explícita
  do usuário, e também a opção de menor esforço: reaproveita o modelo de `Document`/janela MDI já
  existente, em vez do estilo "editar em qualquer ponto da tela" do Mega Assembler/`EDIT` original
  (que exigiria distinguir linha de saída de linha de entrada em qualquer lugar do documento).
- **Modelo de memória simulada com slots × sub-slots × páginas** (4×4×4), indo além do original (que só
  tinha 4×4, sem sub-slots — o comando `PP`/mapeador de segmentos nunca foi portado no paleobasic).
  Cada página guarda tipo (nenhum/RAM/ROM), caminho de arquivo e offset. Ver seção 2.6 para o schema.
- **Terminal como um novo tipo de `Document`** (`isMamuteTerm`), não um diálogo modal — o usuário volta
  a ele repetidamente ao longo da sessão de trabalho.
- **Priorizar o núcleo de execução em texto puro sobre o debugger visual**: dado que o msxIDE já lança
  o openMSX real (`Compilar -> Compilar + Executar no emulador`), uma decisão em aberto pra quando a
  Fase 3 (execução/CPU) começar é: reimplementar um emulador Z80 do zero (fiel ao Mamute original,
  funciona offline) **ou** depurar contra o openMSX real via o protocolo de debug dele (mais integração,
  comportamento 100% real de MSX de brinde). Ainda não decidido — avaliar nessa fase.

### 2.4. Estado atual (Fase 1 e 2 — concluídas)

**Fase 1 — configurador de memória e casca do terminal:**

- **Configurador de memória** (`Configurar -> Mamute (Memória)`): tela em grade, linhas = Slot 0-3
  (expansível em `Slot N.0`-`N.3` quando sub-slots ligados via tecla `T`), colunas = Página 0-3.
  `Espaço`/`Enter` cicla Vazio→RAM→ROM→BIOS→BASIC→EXTBIOS (pedindo arquivo+offset quando não é
  RAM/Vazio). Tecla `L` = "Carregar ROM", que preenche automaticamente a página atual + a seguinte a
  partir de um único arquivo maior que 16KB (BIOS+BASIC combinados, offset 0/16384). `F2` salva, `Esc`
  avisa se há mudanças pendentes. Tamanho de VRAM simulada selecionável (16/32/64/128/192KB).
- **Terminal** (`Mamute -> Abrir Mamute Assembler`): janela MDI com scrollback + linha `MON>` fixa
  embaixo, rolagem automática (nunca esconde saída nova mesmo com a tela cheia).

**Fase 2 — monitor completo + editor de fonte + assembler nativo:**

- **Todos os comandos clássicos do monitor**: `CLS`, `PAGE` (mapa de slots ativo, aceita forma
  posicional `PAGE X[,Y][,Z][,K]` com campos opcionais), `DM` (dump hex+ASCII), `ZAP` (edição de setor
  de disco cru), `SCR` (visualização reduzida de tela gráfica em ASCII), `SH` (busca de bytes/texto),
  `MS` (grava string), `LOAD`/`SAVE`, `C`/`D`/`P`/`V` (modo de exibição + dump formatado, memória e
  VRAM), `T`/`F` (copia/preenche bloco), `G`/`X`/`R` (registradores/execução — `G`/`R` só validam
  sintaxe, igual ao original), `L`/`LP` (disassembler Z80 completo, documentado + indocumentado),
  `HELP`, `BA`/`QUIT`. Escrita numa página que não é RAM agora mostra aviso explícito em vez de falhar
  silenciosamente (divergência deliberada do hardware real, justificada por ser uma ferramenta de
  depuração).
- **Comando `M`**: editor hexadecimal interativo em grade (128 bytes, 16×8), navegação por
  setas/PgUp/PgDn, edição por dígito hexadecimal com avanço automático de cursor, rolagem contínua ao
  passar do fim da tela, `ENTER` avança sem gravar, `ESC` sai da edição sem fechar a janela.
- **Comando `EDIT`**: editor de linhas do programa-fonte Z80 estilo ZX-81/ZX Spectrum, janela própria —
  listagem com cursor `>`, campo `ASM>` reservado embaixo. Sintaxe `NN Label: instrução operando
  ;comentário` (`NN` decimal, números no operando hexadecimal por padrão). `ENTER` com campo vazio puxa
  a linha do cursor pra editar; com campo preenchido grava (mesmo `NN` substitui). Comandos de
  gerenciamento: `LIST`, `NEW`, `DELETE`, `RENUM`, `CHANGE`, `SEARCH`/`FIND`/`LSEARCH`, `SAVE`/`LOAD`/
  `MERGE` (formato ASCII próprio `.mza`), `QUIT` (fecha sem apagar o programa).
- **Assembler Z80 nativo** (motor próprio em FreeBASIC, compatível M80/Nestor80, escopo absoluto — sem
  macros/condicionais/segmentos relocáveis, já que a gramática do `EDIT` nunca produz isso): tokenizador
  de expressão completo, avaliador RPN (shunting-yard), tabela de símbolos com 2 passes, e o codificador
  cobrindo toda a tabela de opcodes Z80 documentados + indocumentados (`IXH`/`IXL`/`IYH`/`IYL`,
  `(IX+d)`/`(IY+d)`). Acionado pelo comando `A [<opções>][/<offset>]` dentro do `EDIT`: `A` sozinho
  valida e mostra a listagem clássica (NN/endereço/hexa/conteúdo); opções combináveis `O` (grava na RAM
  simulada, resolvido pelo `PAGE` ativo), `N` (esconde nº de linha), `P` (grava listagem em `.txt`), `I`
  (grava código-objeto em disco no formato `BSAVE`/`BLOAD` real do MSX), `R` (referência cruzada de
  símbolos), `S`/`D` (lista de símbolos alfabética/por ordem de aparição), `H` (lista de símbolos em
  arquivo `.txt` separado), `/<offset>` (remonta com `ORG` deslocado). Comando `MAP` mostra o intervalo
  da última montagem bem-sucedida. Erro de montagem posiciona o cursor `>` direto na linha problemática.
- Implementado em `src/editor.bas` (Tiranossauro) — sem necessidade de schema novo no banco (reusa
  `DbGetSetting`/`DbSetSetting` já existentes, chaves `cfg.mamute.mem.*`).
- Verificação: `msxide.exe --smoke-mamute` cobre o round-trip completo do mapa de memória, todos os
  comandos do monitor, o disassembler, a grade do `M`, o `EDIT` fim-a-fim (incluindo o comando `A`
  montando um programa real, gravando na RAM simulada e mapeando um erro semântico pra linha certa) —
  tudo via `EditorHandleKey`/teclas reais, não chamadas isoladas às funções internas.

### 2.5. Roadmap (fora de escopo por enquanto)

1. **Execução de verdade** (`G`/`R`/`XGO`/`XTR`/`XRG`) — decidir entre emulador Z80 próprio vs. debug
   contra openMSX real (ver 2.3). Debugger, se feito, começa em texto puro (registradores + disassembly
   ao vivo + breakpoints), não a versão visual com minimapa clicável.
2. **Família `X??` do Super-X** (~36 comandos com prefixo `X` além dos já portados `G`/`X`/`R` básicos)
   — `XD`/`XA`/`XI`/`XH`/`XM`, `XRG`/`XGO`/`XTR`, família de disco `XFS`/`XSV`/`XLD`/`XDK`/etc.
3. **Sistema de notas** (`XIM`/`XIC`/`XIL`/`XIS`/`XIR`) — barato, é só parsing de arquivo texto; boa
   janela pra também trazer as 471 notas da BIOS já traduzidas no paleobasic.
4. **`SCR`/`XH` com pixel de verdade** (hoje `SCR` é uma visualização reduzida em ASCII) e editor de
   sprite/fonte 16×16 — exigem a técnica de pixel em meio-bloco (▀/▄) cogitada pros editores de sprite/
   fonte discutidos separadamente.
5. **Fora de escopo definitivo nesta leva**: macros/assembly condicional/segmentos relocáveis no motor
   Z80 (a gramática do `EDIT` nunca os produz); exportação em PDF (sem valor numa TUI, `P`/`H` já usam
   `.txt`); debugger visual com minimapa clicável (GUI-nativo, sem porte direto); `KR`/`KT`/`KL` (fonte
   japonesa, nicho); `CU` (troca Z80/R800 — sem R800 simulado); `PP` (mapeador de RAM/segmentos
   completo — o msxIDE já foi além do original com sub-slots, mas MegaRAM paginável fica pra quando
   fizer falta na prática).

### 2.6. Modelo de dados (memória simulada)

Chaves em `cfg.mamute.mem.*` (tabela `settings` do `msxide.db`, ou espelhadas no `.msxproj` ativo):

```
cfg.mamute.mem.slot<N>.subslots              (bool, N=0-3)
cfg.mamute.mem.slot<N>.sub<M>.page<P>.type      (none|ram|rom, N=0-3, M=0-3, P=0-3)
cfg.mamute.mem.slot<N>.sub<M>.page<P>.rompath   (path, so relevante se type=rom)
cfg.mamute.mem.slot<N>.sub<M>.page<P>.romoffset (int, offset em bytes dentro do arquivo)
```

Quando `subslots=false` para um slot, só `sub0` é usado e representa o slot inteiro (sem sub-divisão).

Funções: `LoadMamuteMemConfig()`/`SaveMamuteMemConfig()` (`src/editor.bas`), operando sobre
`MamuteMemGrid(0 To 3, 0 To 3, 0 To 3) As MamuteMemCell` e `MamuteMemSubOn(0 To 3) As Integer`.

---

## 3. Sistema de ajuda / referência

`Ajuda` cobre a documentação do msxIDE e dos dialetos suportados (Basic Dignified, Dignified, BaToken,
asMSX, MSX BASIC Dictionary, Editor). `Referência` (menu separado) cobre documentação técnica MSX de
terceiros: The MSX Red Book, MSX2 Technical Handbook, manuais MSX-DOS2/Z80/R800/Turbo-Basic/FM-PAC,
BIOS Chamadas/Hardware/Documentação, openMSX, Nestor Basic, SEE Tracker, MSXBAS2ROM.

Dois mecanismos:
- **`dbhelp:`** — documentos markdown simples, cacheados no banco a partir de um arquivo fallback
  (`DbGetHelpDoc`, `src/db.bas`). Índice clicável gerado automaticamente por cabeçalho
  (`BuildMarkdownHelpBuffer`, `src/editor.bas`).
- **`refdict:`** — dicionários de referência grandes (Red Book, manuais, BIOS), lidos **diretamente**
  dos `.pbi` do PureBasic em `ajuda/` (repositório já versionado do msxIDE) em tempo de execução,
  reaproveitando um parser de chamadas PureBasic (`ExtractPbCallTextFromSource`/`SplitMsxDictArgs`/
  `EvalPbStringExpr`) que já existia para o MSX BASIC Dictionary. Índice + tópico individual, no
  mesmo espírito do `msxdict:` já existente — evita o limite de `MAX_LINES` que um documento único e
  gigante estouraria.

## 4. Sistema de projetos (.msxproj)

Um `.msxproj` é um segundo arquivo SQLite (fonte de verdade, tratado como um "zip"): abrir extrai os
arquivos pra uma pasta de trabalho; salvar rele a pasta e reimporta pro banco. Sem sincronização
contínua. Tabelas: `project_meta`, `project_config`, `project_files`. Chaves `cfg.*` em
`DbGetSetting`/`DbSetSetting` são espelhadas automaticamente pro projeto ativo quando há um aberto —
por isso a config de memória do Mamute (seção 2.6) já é "por projeto" de graça, sem código extra.
