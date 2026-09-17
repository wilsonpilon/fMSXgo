# Referência: núcleo do pré-processador Dignified (badig.py + badig_dignified.py)

> Documentação técnica extraída do código-fonte Python original (`badig/`), para servir de
> especificação ao port nativo em PureBasic. Não é um tutorial de uso — para isso ver
> `badig/documentation/BASIC_DIGNIFIED.md` (já bem completo e citado no `docs/SPEC.md`).
> Complementa o módulo 3 ("Basic Dignified reescrito nativo") do `docs/SPEC.md`.

## Arquitetura geral

O motor é **genérico** (independente de sistema alvo): `badig.py` implementa Lexer + Parser +
Generate operando sobre uma gramática **montada dinamicamente** a partir de duas fontes:
- `badig/support/badig_dignified.py` → classe `Description`: só a parte **Dignified** da gramática
  (instruções, operadores, símbolos, delimitadores de define/label/função, toggle rems, remtags).
- `badig/msx/badig_msx.py` → classe `Description`: a parte **clássica MSX** da gramática (instruções,
  funções, operadores, símbolos, números, literais, variáveis).

Em `badig.py`, a classe `Description` (linha 83) herda de **ambas** (`Dignified.Description,
Classic.Description`) e concatena as duas listas de grupos regex num único `re.compile` (linha
127-132): `main_groups | dignified_groups | classic_groups | d_idnttp`. Ou seja: **um único
lexer regex** reconhece token Dignified, token clássico ou identificador, tudo num só passe —
não há troca de "modo" léxico.

**Implicação para o port**: o lexer nativo em PureBasic pode seguir a mesma ideia (uma tabela de
regras léxicas combinando os dois vocabulários), mas como PureBasic não tem regex nativo tão rico
quanto Python, a forma mais direta é reimplementar como scanner por match-mais-longo (maximal
munch) — o `editor/BadigEditor.pb` já faz algo parecido no `HighlightDocument()` para o highlight,
o que é um bom ponto de partida para o lexer real.

## Classes principais (`badig.py`)

| Classe | Linha | Papel |
|---|---|---|
| `Description` | 83 | Gramática combinada (Dignified + clássico), compila o regex único |
| `Token` | 143 | `tok` (tipo), `val` (valor), `pos` (posição); propriedades `uval`/`lval` (upper/lower), `var_name`/`var_type` (para identificadores com sufixo `$%!#`) |
| `Position` | 207 | Linha/coluna/arquivo/texto da linha, com `offset` para indentação (cálculo de coluna do erro) |
| `Lexer` | 247 | Scanner principal — ver "Lexer" abaixo |
| `Parser` | 532 | 5 passes + geração — ver "Parser" abaixo |
| `Main` | 1895 | Orquestração CLI: `classic()` (entrada é ASCII clássico, só roda ferramentas) ou `dignified()` (pipeline completo: load → lex → parse → generate → save → ferramentas) |

## Lexer (`badig.py:247-528`)

Scanner por **maximal munch**: `get_token()` (linha 300) vai concatenando caracteres e testando o
regex combinado a cada passo; quando o match para de bater, usa o último match positivo como o
token. Não há tabela de palavras-chave separada — tudo é resolvido pelo regex único da
`Description`.

Casos especiais tratados fora do laço principal de `lex()` (linha 411):
- **Blocos de comentário** (`get_lit_block`, linha 331): usado tanto para `'' ... ''` (Dignified,
  mantido) quanto `### ... ###` (Dignified, removido) quanto o bloco clássico de REM do módulo MSX.
  Detecta se o token de abertura está **sozinho na linha** (`self.last_tok.tok == 'NEWLINE'`) —
  senão trata como comentário de linha só.
- **Linhas literais** (`get_lit_line`, linha 382): usado para string entre aspas e para REM/`'` de
  linha única — lê até encontrar o delimitador de fechamento ou fim de linha.
- **Toggle rems fora do início de linha** (linha 441-456): um `#nome` no meio de uma linha é
  "desmontado" de volta em `#` (símbolo) + identificador, porque `#nome` só é toggle rem válido
  quando está sozinho/no início — nos outros casos vira variável normal prefixada por `#` (usado
  para `INPUT #1` etc., ver `DIFFERENCES.md`: *"input # 1 with separated # works correctly"*).
- **Chamada ao módulo clássico** (`self.clc.lexing()`, linha 514): ponto de extensão onde o módulo
  MSX intercepta tokens (usado para linhas `DATA`, ver `badig_msx.py:340-430`).

## Parser — 5 passes + geração (`badig.py:532-1893`)

O parser roda sobre a **lista de tokens** (não sobre texto), com um `index` que avança/recua
(`next_tok`/`prev_tok`/`peek_ahead`). Cada pass consome `tok_list_in` (saída do pass anterior) e
produz `tok_list_out`. Structure confirmada por `NEW_MODULES.md` e pelo código:

### Pass 1 (`pass_1`, linha 1366) — instruções Dignified e defines
- Remove linhas com **toggle rem** não mantido (`toggle_lines`, linha 1210) — respeita `keep`,
  `#all`, `#none` (precedência de `#none` codificada em `pass_1`/`toggle_lines`).
- Processa instruções Dignified que precisam ler o resto da linha imediatamente: `DEFINE` →
  `get_defines` (linha 594), `DECLARE` → `get_declares` (linha 745), `KEEP` → `get_keeps` (linha
  1193), `FUNC` → `get_func_def` (linha 944), `RET` → `get_func_ret` (linha 993). `EXIT` e
  `INCLUDE` só são "vistos" aqui (`pass`) e resolvidos depois. `ENDIF` é descartado (`continue`)
  sem nenhum processamento — é puramente cosmético, como documentado.
- Substitui usos de `[define]` por seu conteúdo (`replace_define`, linha 679) — resolução
  **recursiva** (defines podem referenciar outros defines) e com suporte a **variável posicional**
  `[nome](arg)` via `D_DEFVAR` placeholder dentro da definição.
- Delega ao módulo clássico (`self.clc.pass_1()`) para conversões específicas do dialeto (no MSX:
  decidir se `_`/`:` é separador de linha Dignified ou vira `CALL` implícito — ver módulo MSX).

### Pass 2 (`pass_2`, linha 1444) — fluxo de código (labels e funções)
- Resolve `.funcName(args)` → `replace_func_calls` (linha 1030): expande para atribuição de
  argumentos + `D_FUNCAL` (placeholder, vira `GOSUB` no Pass 4) + atribuição de retornos.
  Otimização: se o valor do argumento/retorno já é a mesma variável (`compare_func_args`, linha
  1136), **não gera atribuição redundante** (evita `A$=A$`), conforme documentado.
- Resolve labels: `{nome}` sozinho na linha → `D_LBLLIN` (linha de destino, `get_label_lines`,
  linha 847); `{nome}` dentro de instrução de desvio → `D_LBLJMP` (`get_jump_labels`, linha 878);
  `nome{ ... }` (loop label) fecha com `}` → `D_LBLRET` (`get_loop_label_return`, linha 892),
  injeta um `GOTO` de volta ao início do loop automaticamente; `exit` dentro de loop → `D_LBLEXT`
  (`get_labels_exit`, linha 911).
- Pós-pass: erro se sobrou loop label aberto ou função sem `RET`.

### Pass 3 (`pass_3`, linha 1503) — includes e limpeza estrutural
- `INCLUDE "arquivo"` → `include_file` (linha 1240): carrega, lexa e parseia (Pass 1-3 apenas, ver
  `par()` linha 1347) o arquivo incluído **recursivamente**, com **namespace próprio** (variáveis
  curtas hardcoded e declaradas são compartilhadas entre arquivo principal e includes, mas
  labels/defines/funções/toggles não — exatamente como documentado em `BASIC_DIGNIFIED.md`).
  Arquivos incluídos **não passam pelos Pass 4/5** (`is_main_file()`, linha 1341) — só o arquivo
  principal numera linhas e aplica capitalização/tradução.
- Limpeza: remove blocos de comentário duplicando cada linha interna como REM/`'` separado, remove
  newlines excedentes, remove `:` duplicado, junta strings adjacentes (mesma linha ou linha
  anterior — suporta `PRINT "a" "b"` e `PRINT "a"\n"b"`).

### Pass 4 (`pass_4`, linha 1612) — numeração de linha e resolução de endereços
- Insere cabeçalho de comentário (`insert_rem_header`) se `rem_header` ativo.
- Percorre o token stream contando `NEWLINE`s para atribuir **número de linha** (`line_start` +
  `line_step` por linha), inserindo um token `C_LINENB` no início de cada linha gerada.
- Registra posição (índice na lista de saída) de cada `D_LBLJMP`/`D_LBLRET`/`D_LBLEXT`/`D_FUNCAL`
  como **placeholder**, e só no **pós-pass** (depois de toda a numeração estar feita) substitui o
  placeholder pelo número de linha real (`label_lines`, `llabels_ret`, `func_defs` — dicionários
  nome→linha). Isso resolve o problema clássico de "referência para frente" (jump para um label
  ainda não visto) sem precisar de duas passadas completas de lexer/parser.
- Constrói `label_report`/`line_report` (para os argumentos `-lbr`/`-lnr`).

### Pass 5 (`pass_5`, linha 1756) — ajustes finais específicos do dialeto clássico
- Quase todo o trabalho é delegado ao módulo clássico (`self.clc.pass_5()`): no MSX isso cobre
  `?`↔`PRINT`, strip de `THEN`/`GOTO` adjacentes, operadores compostos (`+=`, `++` etc. → forma
  clássica), `TRUE`/`FALSE` → `-1`/`0`, tradução Unicode→ASCII (ver módulo MSX).
- Capitalização geral (`capitalise_all`) é aplicada aqui, por último, sobre tudo que não é literal.

### Geração (`generate`, linha 1793)
- Monta a linha final texto a texto, com **regras de espaçamento automático**: adiciona espaço
  antes/depois de palavras-chave reservadas quando o token vizinho não é um símbolo "colante"
  (`c_symb_comp`) — para não gerar `PRINTA` a partir de `PRINT A`. `general_spaces` é `''` se
  `strip_spaces` ativo, senão `' '`.
- Delega ao módulo clássico (`self.clc.generate()`) ajustes finos por caractere (no MSX: separar
  `X`/`OR` para não virar `XOR`, separar hex de letras `A-F` adjacentes).
- **Nota pro port (revisada 2026-08-04)**: o port nativo (`Dig_StripSpaces_Piece`,
  `DignifiedPreprocessor.pbi`) **não** implementa esse algoritmo literalmente (montagem token a token
  com `c_symb_comp` durante a geração) — é uma reinterpretação pragmática que roda como um passo
  separado sobre o texto já montado, removendo espaço entre dois átomos-palavra adjacentes exceto
  quando (a) ambos são numéricos (evita colar `1 2`→`12`) ou (b) colar os dois faz nascer uma
  palavra-chave diferente na fronteira (equivalente prático ao par `X`/`OR` citado acima, mas
  generalizado contra toda a lista de palavras reservadas, não só esse caso específico — ver
  `docs/SPEC.md`, módulo 3h, item 1). `PRINT A`→`PRINTA` é **permitido** pelo port (confirmado seguro:
  o tokenizador nativo casa palavras-chave em qualquer posição, sem exigir fronteira), diferente do que
  a frase "para não gerar `PRINTA`" acima sugere sobre o Python original — não fica claro só pela
  leitura do código Python se essa proteção é estritamente necessária lá também ou só uma cautela
  extra; o port optou por confiar no comportamento real do próprio tokenizador nativo em vez de
  replicar a cautela. Separação de hex de letras `A-F` (mencionada no `generate()` clássico acima)
  **não** foi portada — não verificado a fundo se o tokenizador nativo precisa dela, risco baixo aceito
  por ora.
- Verifica tamanho de linha (**limite de 256 caracteres**, erro se exceder — limite real do MSX
  BASIC clássico).
- Anexa relatório de labels no fim da linha como comentário, se `-lbr` ativo.

## Sistema de configuração (`badig_settings.py` + `BASIC_DIGNIFIED.md`)

Confirmado por leitura direta do código (`Settings.init()`, `get_ini()`, `get_arguments()`,
`read_remtags_from_code()` em `badig_settings.py`): hierarquia de prioridade **código-fonte <
`.ini` < linha de comando < remtags** (cada nível sobrescreve o anterior), exatamente como
documentado. Carregamento de módulo é **dinâmico** via `importlib.import_module` baseado em
`system_id` (`badig_settings.py:92-93`) — é assim que `-id msx`/`-id coco` troca de dialeto sem
tocar no núcleo. Um port nativo precisa de um mecanismo equivalente (ex.: um enum/interface de
"módulo de sistema" escolhido em runtime) se quiser preservar a extensibilidade multi-sistema —
mas como o objetivo aqui é **só MSX**, isso pode ser simplificado/removido no port (não há plano
de suportar CoCo nesta IDE).

## Delimitadores e vocabulário Dignified (`badig_dignified.py`)

A classe `Description` desse arquivo é **só dados** (tabelas/regex), sem algoritmo:
- Instruções: `DEFINE DECLARE INCLUDE KEEP ENDIF FUNC RET EXIT`
- Operadores: `TRUE FALSE`
- Símbolos: `[ ] { } @ ~`
- Delimitadores: define `[ ]` (separador `,`, variável `( )`), declare `:` `,`, label `{ }`
  (self-label `@`), função `( )` `,` `=`
- Toggle rem: prefixo `#`, especiais `#ALL`/`#NONE`
- Remtag: regex `^\s*##BB:([a-zA-Z_0-9]+)=(.*)$`, comandos base
  `EXPORT_FILE CONVERT_ONLY TOKENIZE ARGUMENTS`
- Comentário de bloco Dignified: abre/fecha com `###` (exclusivo, removido) ou `''` (mantido)
- Comentário de linha Dignified: `##`
- Separador de linha: `_`

Isso já está bem coberto por `BASIC_DIGNIFIED.md`; a lista acima serve como checklist rápida de
exatamente quais strings/caracteres usar no port, sem precisar reabrir o `.py`.

## Pontos de atenção para o port nativo

- **Preservar exatamente** os bugs/limitações documentados em `documentation/IMPLEMENTATIONS.md`
  ("Known Bugs") só se fizer sentido — ao contrário do tokenizador (onde as discrepâncias com o
  MSX real devem ser preservadas por compatibilidade binária), aqui são bugs do **conversor**, não
  do formato de saída. É uma decisão de produto, não de compatibilidade: dá para corrigi-los no
  port sem quebrar nada externo. Ex.: *"Toggles/labels/declares/funções/variáveis longas começando
  com número não geram erro e convertem para resultado errático"* — provavelmente vale corrigir.
- O limite de **256 caracteres por linha** gerada é uma regra real do MSX-BASIC, não do Dignified
  — preservar.
- O algoritmo de resolução de label em 2 passes (placeholder no Pass 4 + substituição no pós-pass)
  é a peça mais importante a portar corretamente — é o que permite `GOTO` para um label declarado
  mais adiante no arquivo sem precisar rodar o parser duas vezes inteiro.
