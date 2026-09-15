# Changelog

Todas as mudanças notáveis do msxIDE são registradas aqui. Formato livre, em português, por versão.

## [0.5.0] — "MAMUTE.MAP" — 2026-09-11

O mamute aprende a abreviar: o Basic Dignified ganha a conversão de variáveis de nome longo pra nome
curto (a peça que faltava do dialeto — o compilador nativo simplesmente não tinha nada disso até hoje),
mais um bom punhado de acertos no editor de texto e no próprio compilador. Nome da versão é um trocadilho
duplo: `.MAP` é o arquivo clássico que relaciona símbolo com endereço num compilador/linker de verdade —
exatamente o que a tabela nome-longo→nome-curto faz — e também é o nome do aplicativo Character Map do
Windows, a inspiração direta da nova grade de caracteres especiais MSX.

### Adicionado

- **Variáveis de nome longo → curto no Basic Dignified**: portada a funcionalidade mais complexa do
  dialeto (`BASIC_DIGNIFIED.md`, "Long named variables"), até então 100% ausente do compilador nativo.
  Nomes com 3+ letras/números/underscore (case-insensitive) são automaticamente trocados por um par de
  letras, atribuído em ordem **descendente de `ZZ` até `AA`** (nunca uma letra só nem letra+número) — o
  mesmo nome longo sempre vira o mesmo curto independente do sufixo de tipo (`variable1` e `variable1$`
  viram `zz` e `zz$`). `DECLARE nome:curto` força um mapeamento na mão; `DECLARE nome1,nome2` reserva
  (um curto direto se tiver 1-2 letras, ou "nunca encurtar esse nome" se tiver 3+); `~nome` mantém o
  nome por extenso em **todas** as ocorrências do arquivo, não só na marcada; variáveis de 1-2 letras
  usadas direto no código nunca são tocadas. Tokenizer novo que varre cada linha reconhecendo
  identificadores mas nunca entra dentro de string literal nem depois de `REM`/`'`/`DATA` (senão um
  comentário em inglês virava sopa de variáveis trocadas). Namespace por arquivo, reaproveitando o
  mesmo mecanismo que os labels `{nome}` já usavam para `INCLUDE`s.
- **`Inserir -> Caracteres Especiais MSX`** (`Alt+I`, depois `C`): grade navegável por setas com os
  caracteres especiais do conjunto MSX — mesmo conjunto que o "Translate" do Basic Dignified Suite
  reconhece (`badig_msx.py`, `Parser.trans_char`). Acentos/gráficos (códigos 128-255) são inseridos
  como o byte exato, que sai idêntico no `.amx` gerado sem nenhuma tradução no compilador (o pipeline
  inteiro é byte a byte, nunca passa por UTF-8). Símbolos especiais (`CHR$(1)` a `CHR$(31)` — carinha,
  naipes, blocos) não são imprimíveis de forma confiável via `PRINT`/string literal no MSX BASIC
  clássico, então viram a **letra equivalente** (`A`-`Z`, `[`, `]`, `\`, `^`, `_`), o mesmo fallback de
  segurança que o Basic Dignified Suite usa. `Enter` insere sem fechar o diálogo (dá pra inserir vários
  seguidos), `Esc` fecha. Sétimo item na barra de menus.
- **`Tab` configurável**: insere a quantidade de espaços definida em `Configurar -> Editor -> Indent
  Size` (padrão 4, novo item no menu Configurar) em vez de não fazer nada.
- **`Shift+Delete`/`Shift+Insert`/`Ctrl+Insert`**: o trio clássico de recortar/colar/copiar dos editores
  MS-DOS de antes do `Ctrl+X`/`Ctrl+V`/`Ctrl+C` (QEdit, Norton Editor, Brief...) — mapeados pro mesmo
  código interno dos atalhos modernos, então funcionam identicamente sem duplicar lógica nenhuma no
  editor.
- **Basic Dignified: continuidade de linha com `:`**: recurso já documentado (`BASIC_DIGNIFIED.md`,
  "Line separation") mas nunca implementado — uma linha terminada em `:` agora se junta com a próxima
  (e uma linha começada em `:` se junta com a anterior) antes de virar uma linha numerada, exatamente
  como a documentação sempre prometeu. `SCREEN 0:` seguido de `WIDTH 40` agora vira uma linha só
  (`10 SCREEN 0:WIDTH 40`) em vez de duas.

### Corrigido

- **`Strip Spaces` só colapsava espaços duplicados**, nunca removia de fato — agora remove *todos* os
  espaços fora de string literal (inclusive colados no `:`), como a própria documentação sempre disse
  ("all non essential spaces from the code can be removed").
- **Ordem do pipeline de formatação do Basic Dignified**: `Strip Spaces` rodava *antes* da conversão de
  `PRINT`/`?` e `THEN`/`GOTO`, que dependem de espaço ao redor da palavra-chave pra reconhecê-la com
  segurança — com as duas opções ligadas ao mesmo tempo, o strip quebrava silenciosamente as outras
  duas. Ordem agora é Convert PRINT → Strip THEN GOTO → Strip Spaces → Capitalize.
- **`Alt+C` agora abre Compilar e `Alt+O` abre Configurar** (antes `Alt+P` e `Alt+C`, respectivamente).

### Créditos desta versão

Ver a seção "Agradecimentos" em [README.md](README.md#agradecimentos).

---

## [0.4.0] — "MAMUTE.FNT" — 2026-09-08

O mamute aprende a desenhar suas próprias letras: dois editores visuais novos dentro do msxIDE — um
para documentação em Markdown, outro para fontes de caracteres MSX (8x8 pixels) — e o sistema de
projetos ganha registro automático de arquivos binários criados por eles.

### Adicionado

- **Editor de Markdown** (`Arquivo -> Novo Arquivo MD`, ou abrir qualquer `.md`): três modos alternados
  por `F7` — edição simples, dividido (texto à esquerda, preview renderizado ao vivo à direita) e
  somente leitura (preview em tela cheia). Reaproveita o mesmo motor de renderização que já desenha toda
  a Ajuda (`BuildMarkdownBufferFromText`, extraído de `BuildMarkdownHelpBuffer` sem mudar o
  comportamento da Ajuda existente). Arquivos `.md` entram no sistema de projetos (`.msxproj`) junto com
  o código-fonte. Novo tópico de Ajuda `Ajuda -> Markdown` com a referência de formatação.
- **Editor de Fontes MSX** (`Arquivo -> Novo Editor de Fontes`, ou abrir um `.alf`/`.fnt`/`.chr`): mapa
  geral 16x16 dos 256 caracteres e o caractere selecionado ampliado em pixels (8x8, cada pixel = um
  bloco cheio `█` duplicado horizontalmente pra ficar quadrado no console) sempre visíveis lado a lado —
  navegar pelo mapa já atualiza o preview ampliado, sem precisar entrar no modo de edição pra ver o
  desenho. Formato de arquivo real do MSX: cabeçalho BSAVE (`FE` + endereço inicial/final/execução, 2
  bytes cada, little-endian) seguido de 2048 bytes (256 caracteres × 8 bytes). Todo alfabeto novo nasce
  semeado a partir de `roms/msx1.alf` (a fonte MSX1 padrão, incluída no pacote); salvar grava sempre no
  endereço padrão de alfabeto do MSX (`9200H`), pronto pra `BLOAD` de verdade.
  - **Integração com projeto**: com um projeto aberto, cada alfabeto novo nasce dentro da pasta `roms\`
    do próprio projeto e é registrado no banco do projeto assim que é salvo (`F2`) — sem precisar de
    "Salvar Projeto" — permitindo vários alfabetos por projeto. O rodapé do editor lista os alfabetos já
    salvos no projeto ativo (aparece automaticamente no espaço sobrando abaixo do mapa de caracteres);
    `TAB` foca a lista, `Cima`/`Baixo` escolhe, `ENTER` abre o escolhido numa aba nova.
  - Arquitetura pensada pra reuso: o campo `pixelEditKind` no `Document` já reserva espaço pro futuro
    editor de Sprites, que deve compartilhar quase toda a base de edição de pixels deste editor de
    fontes.
- **Sistema de projetos**: `.alf` vira extensão rastreada (`IsTrackedExt`); `Salvar Projeto` também
  varre uma subpasta `roms\` do projeto (mesmo tratamento especial que a subpasta `disk\` já tinha para
  imagens de disquete).
- Testes headless (`--smoke-help`) expandidos com o editor de Markdown, o editor de Fontes (navegação,
  toggle de pixel, round-trip binário com cabeçalho BSAVE real) e um cenário completo de projeto
  (criar projeto, salvar dois alfabetos, navegar/abrir pela lista do rodapé via teclas reais) —
  incluindo verificações A/B (quebra deliberada + confirmação de que o teste detecta, depois restaurado)
  nos trechos mais arriscados: detecção do cabeçalho BSAVE ao carregar, e o endereço fixo de gravação.

### Corrigido

- **`F7` não tinha mapeamento nenhum**: nem no backend nativo do Windows (`console_win.bas`, faltava
  `Case VK_F7`) nem na tabela de fallback ANSI (`NormalizeKey`) — descoberto ao implementar o atalho de
  alternância de modo do editor de Markdown, que dependia dessa tecla.

### Créditos desta versão

Ver a seção "Agradecimentos" em [README.md](README.md#agradecimentos).

---

## [0.3.0] — "MAMUTE.PRN" — 2026-09-06

O mamute começa a incorporar o **SUPER-X**, o segundo monitor/debugger clássico de MSX que inspira a
outra metade do Mamute Assembler, e ganha uma **impressora virtual de verdade** — nome da versão é um
trocadilho com `PRN`, o nome de dispositivo reservado da impressora no MS-DOS clássico.

### Adicionado

- **Endereçamento estendido do SUPER-X**: qualquer endereço pode levar um sufixo
  `#<slot>[-<subslot>]`/`#V`/`#4`/`#S`/`#5` pra mirar um slot/sub-slot físico específico ou a VRAM
  plana (até 192KB, não restrita a 64KB), ignorando o mapeamento `PAGE` ativo — a base que todo comando
  novo do SUPER-X usa daqui pra frente.
- **`XCL`**: calculadora HEX/BIN/DEC/octal com precedência de operadores clássica e parênteses —
  primeiro comando portado do SUPER-X (convenção adotada: todo comando SUPER-X leva o prefixo `X`, pra
  não colidir com os comandos já existentes do MegaAssembler).
- **`XD`**: despejo de memória com o endereçamento estendido completo — `XD <inicial>[,<final>][,SAVE]`.
- **`XF`**: escolhe o formato de exibição do `XD` — `D` (hexa+ASCII clássico), `C` (matriz de pixels
  16x16, porta do modo "Char" do SUPER-X), `A` (só ASCII), `I` (só o mnemônico) ou `M` (endereço+bytes+
  mnemônico completo).
- **`XA`**/**`XI`**: versões dedicadas do despejo ASCII e da listagem disassemblada como comandos
  próprios (mesma sintaxe `<inicial>[,<final>][,SAVE]` do `XD`), independentes do formato atual de `XF`.
- **Impressora virtual com PDF real**: `P`/`V`/`LP` (e, dentro do `EDIT`, `LSEARCH`/`A P`/`A H`) agora
  geram um `.pdf` de verdade — montado à mão, sem biblioteca nenhuma — em vez de texto simples, e o PDF
  já abre sozinho no visualizador padrão do Windows.
  - **Prefixo `?`**: qualquer comando do Mamute que não dependa de mais interação (`PAGE`, `D`, `SH`,
    `XD`, `XCL`, etc. — das duas famílias) aceita `?` na frente pra mandar o resultado direto pro PDF em
    vez da tela.
  - **`Configurar -> Impressora`**: papel **A4** (margem de 1cm nos 4 lados) ou **contínuo** (formulário
    CPD picotado, 9.5x11 polegadas, sempre 66 linhas/formulário), fonte **Normal**/**Condensada**
    (densidade real de impressora matricial, muda quantas colunas cabem por linha), zebrado
    **Verde**/**Azul** linha a linha cobrindo o formulário inteiro, furos redondos nas margens e uma
    linha picotada tracejada simulando a dobra entre formulários a cada 66 linhas.
- Ajuda do Mamute Assembler (`docs/help/mamute.md`) reorganizada em duas famílias claras -
  `## Comandos do MegaAssembler` e `## Comandos do SUPER-X` - com uma seção nova `## Impressora Virtual`
  explicando o prefixo `?` e a configuração de papel.
- Testes headless (`--smoke-mamute`) expandidos com dezenas de novas asserções pra cada peça acima,
  incluindo checagem estrutural do PDF gerado (`%PDF-1.4`, `/MediaBox`, operadores de zebrado/furos) e
  verificação A/B real (quebra deliberada + confirmação de que o teste pega) pros trechos mais
  arriscados (endereçamento por sub-slot, layout do papel contínuo, formatos do `XF`).

### Corrigido

- **Edições em `docs/help/*.md` não apareciam na Ajuda depois da primeira vez que o tópico era aberto**:
  `Ajuda -> Mamute`/Editor/Nestor Basic/SEE Tracker/MSXBAS2ROM carregavam o markdown uma vez e guardavam
  pra sempre no banco local (`DbGetHelpDoc`), nunca relendo o arquivo — agora esses 5 documentos são
  ressemeados do disco a cada abertura do msxIDE, igual os 3 documentos vendorizados do Basic Dignified
  já faziam.

### Créditos desta versão

Ver a seção "Agradecimentos" em [README.md](README.md#agradecimentos).

---

## [0.2.0] — "MAMUTE.COM" — 2026-09-04

O mamute aprendeu a montar sozinho: o Mamute Assembler sai do "início" e vira um monitor Z80 completo,
com editor de fonte estilo ZX-81 e um assembler nativo próprio — sem depender de nenhuma ferramenta
externa pra montar código de verdade.

### Adicionado

- **Todos os comandos clássicos do monitor `MON>`**: `DM`, `ZAP`, `SCR`, `SH`, `MS`, `LOAD`/`SAVE`,
  `C`/`D`/`P`/`V`, `T`/`F`, `G`/`X`/`R`, `L`/`LP`, `HELP` — além dos já existentes `CLS`/`PAGE`/`BA`/
  `QUIT`. Escrita numa página que não é RAM agora avisa explicitamente (`AVISO: pagina nao e RAM
  agora...`) em vez de falhar em silêncio, uma melhoria deliberada sobre o comportamento do hardware
  real numa ferramenta de depuração.
- **Comando `M` virou um editor hexadecimal interativo**: grade de 128 bytes (16×8) ocupando a janela
  inteira, cursor navegável por setas/PgUp/PgDn, edição dígito a dígito em hexadecimal com avanço
  automático, rolagem contínua ao passar do fim da tela, `ENTER` avança sem gravar, `ESC` sai da edição
  sem fechar a janela nem o msxIDE.
- **Comando `EDIT`**: editor de linhas do programa-fonte Z80, estilo ZX-81/ZX Spectrum, em janela
  própria — listagem com cursor `>`, campo `ASM>` reservado embaixo, rolagem automática de meia tela.
  Sintaxe `NN Label: instrução operando ;comentário`. Comandos de gerenciamento completos: `LIST`,
  `NEW`, `DELETE`, `RENUM`, `CHANGE`, `SEARCH`/`FIND`/`LSEARCH`, `SAVE`/`LOAD`/`MERGE` (formato ASCII
  `.mza` próprio), `QUIT`.
- **Assembler Z80 nativo**, escrito do zero em FreeBASIC (compatível M80/Nestor80): tokenizador de
  expressão, avaliador RPN (shunting-yard), tabela de símbolos de 2 passes, e o codificador de
  instrução cobrindo toda a tabela de opcodes Z80 documentados e indocumentados (`IXH`/`IXL`/`IYH`/
  `IYL`, `(IX+d)`/`(IY+d)`). Acionado pelo comando `A` dentro do `EDIT`, com todas as opções do
  original combináveis (`O` grava na RAM simulada resolvida pelo `PAGE` ativo, `N` esconde número de
  linha, `P` grava a listagem em `.txt`, `I` grava código-objeto em disco no formato `BSAVE`/`BLOAD`
  real do MSX, `R`/`S`/`D` anexam referência cruzada/lista de símbolos, `H` manda a lista de símbolos
  pra um arquivo separado, `/<offset>` remonta com o `ORG` deslocado) e pelo comando `MAP`. Erro de
  montagem posiciona o cursor `>` direto na linha problemática.
- **Acentuação correta no console em Windows com locale em inglês**: o texto de ajuda (UTF-8 em disco)
  agora é convertido pra codepage OEM 860 (Português) antes de chegar na tela, em vez de aparecer como
  bytes UTF-8 crus — sem quebrar as bordas de janela (que usam a mesma faixa de caracteres OEM em
  qualquer codepage).
- **`ESC` não fecha mais o msxIDE inteiro** — era um atalho global que conflitava com o uso local de
  `ESC` em telas como a nova grade de edição do `M`. Fechar o programa continua disponível pelo menu
  `Arquivo -> Exit`.
- Testes headless (`msxide.exe --smoke-mamute`) expandidos para cobrir cada um desses comandos fim-a-
  fim através de teclas reais (`EditorHandleKey`), incluindo o comando `A` montando um programa de
  verdade, gravando na RAM simulada e mapeando um erro semântico pra linha certa do `EDIT`.

### Corrigido

- `DM`/`M` mostravam sempre zero mesmo com BIOS configurada: a página BASIC vizinha (segunda metade de
  uma ROM de 32KB) podia ficar sem arquivo próprio associado (configuração antiga/dessincronizada) —
  agora herda o arquivo da BIOS vizinha automaticamente ao carregar a memória física.

### Créditos desta versão

Ver a seção "Agradecimentos" em [README.md](README.md#agradecimentos).

---

## [0.1.1] — "MAMUTE.SYS" — 2026-09-03

Primeira versão com changelog formal — reúne tudo implementado até aqui num único marco.

### Adicionado

- **Editor de texto em TUI** com múltiplos documentos em janelas MDI (arrastar, redimensionar,
  maximizar, fechar), barras de rolagem, e roda do mouse funcionando na edição e nas telas de ajuda.
- **Compilação Basic Dignified/MSX BASIC clássico** (`Compilar`): gera `.amx`/`.bmx`, monta disco
  `.dsk` e lança o **openMSX** automaticamente. Diálogo de compilação pequeno com log rolante e botão
  de fechar `[.]`.
- **Suporte a Z80 Assembly via asMSX**: `Arquivo -> Novo asMSX` cria um "Hello ASM World" pronto pra
  montar; `Compilar + Executar` monta com o **asMSX** real e oferece inserir o binário resultante num
  programa BASIC aberto — como `BLOAD` direto, como rotina `DATA`/`POKE` com `DEFUSR`/`USR()` (tudo em
  hexadecimal, `GOSUB` automático no topo do programa), ou salvar como `.inc` pra reaproveitar em
  outros fontes assembly.
- **Sistema de projetos** (`Arquivo -> Novo/Abrir/Salvar/Fechar Projeto`): um `.msxproj` (SQLite) que
  funciona como um "zip" portátil — todo o projeto (fontes, binários, config) num arquivo só, extraído
  pra uma pasta de trabalho ao abrir e reimportado ao salvar.
- **Sistema de Ajuda** (`Ajuda`): Basic Dignified, Dignified, BaToken, asMSX, MSX BASIC Dictionary
  (dicionário completo MSX1/MSX2+/FM-Music com verbetes contextuais via `Shift+F1`), e um novo guia do
  próprio editor com todos os atalhos.
- **Menu Referência**: dez documentos técnicos MSX portados pra dentro do IDE — The MSX Red Book, MSX2
  Technical Handbook, manuais MSX-DOS2/Z80/R800/Turbo-Basic Compiler/FM-PAC, BIOS Chamadas/Hardware/
  Documentação, openMSX, Nestor Basic, SEE Tracker e MSXBAS2ROM (snapshot congelado da wiki oficial).
- **Início do Mamute Assembler** (`Configurar -> Mamute (Memória)` e `Mamute -> Abrir Mamute
  Assembler`): réplica do monitor/assembler interativo do paleobasic (mistura de Mega Assembler +
  Super-X). Fase 1: configurador de memória simulada (4 slots × sub-slots × 4 páginas, RAM/ROM,
  carregamento de ROM de 32KB dividida em BIOS+MSX-BASIC) e um terminal `MON>` básico estilo ZX-81
  (scrollback em cima, linha de comando fixa embaixo), com os comandos `CLS`/`PAGE`/`BA`/`QUIT`. Ver
  [SPEC.md](SPEC.md#2-módulo-mamute-assembler) para o roadmap completo.
- Correção do boot de disco MSX-DOS (bootstrap real portado do paleobasic — antes o disco gerado não
  passava do boot).
- Testes headless (`msxide.exe --smoke-help`, `--smoke-mamute`) cobrindo o sistema de ajuda e o
  round-trip da configuração de memória do Mamute, sem depender de automação de teclado/mouse.

### Créditos desta versão

Ver a seção "Agradecimentos" em [README.md](README.md#agradecimentos).

---

## [0.0.x] — Desenvolvimento inicial

Marco zero: janela TUI, menu `File -> Exit`, edição de texto básica estilo `EDIT` do MS-DOS,
persistência em SQLite. Sem changelog detalhado por versão nesse período — consulte o histórico do
Git.
