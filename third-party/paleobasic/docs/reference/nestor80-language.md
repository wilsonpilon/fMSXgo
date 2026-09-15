# Referência: linguagem do assembler Nestor80 (Konamiman)

> Documentação técnica extraída de `nestor80/docs/LanguageReference.md` (2835 linhas) e
> `nestor80/docs/MACRO-80.txt` (2675 linhas, manual original Microsoft MACRO-80 transcrito), para
> servir de especificação ao assembler Z80 nativo em PureBasic (**módulo 2** do `docs/SPEC.md`).
> Complementa `docs/resumo-asm.md` (o "estado da implementação" desta frente — este arquivo aqui é
> só a spec de linguagem, lido uma vez e citado, não atualizado a cada marco). Cobre apenas o que a
> **Fase A** do checklist em `resumo-asm.md` precisa (lexer/tokenizer, avaliador de expressão,
> diretivas de dados/constantes/condicionais/macros básicas, gramática de modos de endereçamento
> Z80). Formato `.REL`/algoritmo de linkagem ficam para `nestor80-rel-format.md` e
> `nestor80-linker.md` (Fase B, ainda não escritos).
>
> `E:\msxbasica\nestor80\` é um clone raso gitignored (mesmo tratamento de `badig/`): referência de
> leitura, não dependência de runtime — o assembler nativo é um port de comportamento, não chama
> `N80.exe`. `N80.exe` (compilado localmente, ver `resumo-asm.md`) serve só como **oráculo de teste**
> para validar bytes gerados pelo motor PureBasic.
>
> Convenção de citação: `LR:<linha>` = `nestor80/docs/LanguageReference.md`, `M80:<linha>` =
> `nestor80/docs/MACRO-80.txt`. Citações para o código-fonte C# do próprio Nestor80 (usado só para
> confirmar comportamento onde a doc é omissa) apontam para `nestor80/Assembler/*.cs`.

## Formato da linha-fonte

Sintaxe de statement (LR:151-177):

```
[label:[:]] [operador] [argumentos] [;comentário]
```

- **Tamanho máximo de linha**: Nestor80 aceita até **1034 caracteres** (LR:151); o MACRO-80
  original aceitava só 132 (M80:305). Não confundir com o limite de 256 caracteres do MSX-BASIC
  clássico (regra de outro pipeline, ver `dignified-core.md`) — aqui não há esse teto.
- Espaços/tabs são equivalentes; espaços à esquerda/direita da linha são removidos antes do
  processamento (LR:151). Qualquer quantidade de espaços/tabs separa os componentes do statement.
- **Label**: símbolo seguido de `:` (privado) ou `::` (público — só relevante para REL, ver spec
  futura) — LR:161, M80:326-335. O valor do label é o location counter (`$`) no momento em que a
  linha é processada.
- **Operador**: mnemônico de CPU (`LD`, `CALL`...) ou instrução do assembler ("pseudo-operador" na
  nomenclatura M80). Resolução de ambiguidade em M80 (M80:337-348, mantida por compatibilidade):
  1. Chamada de macro; 2. Mnemônico/pseudo-op; 3. Expressão "solta" (bare expression — tratada como
     `DEFB` implícito). Nestor80 **desliga bare expressions por padrão** 🚫 (LR:497) — só habilita
     com `--allow-bare-expressions`. **Implicação para o port**: não implementar bare expressions na
     Fase A (não está no checklist); se uma linha não bate com macro/mnemônico/diretiva, é erro.
- **Comentário**: `;` até fim de linha, sem efeito (LR:167). Linha só-comentário começa com `;`.
- **Caracteres de controle** (exceto tab) são removidos da linha antes do processamento; form feed
  (`\f`, 0Ch) é preservado só para paginação de listing (LR:173) — irrelevante para a Fase A (sem
  listing).
- Comparação com M80: linhas com bit alto setado (números de linha injetados por editor) eram
  tratadas como line numbers pelo MACRO-80 (M80:311-313); Nestor80 **não** faz isso 🚫 (LR:177) — não
  precisa reproduzir esse comportamento no port.

### `.COMMENT`

_Sintaxe:_ `.COMMENT <delimitador><texto><delimitador>` (LR:1308-1334).

O primeiro caractere não-espaço após `.COMMENT` vira o delimitador; tudo até a próxima ocorrência
desse caractere é comentário (pode atravessar várias linhas). A linha inteira onde o delimitador de
fechamento aparece é ignorada por completo (mesmo o que vem depois do delimitador de fechamento
nessa linha). Equivalente ao `.COMMENT` do M80 (M80:356, referenciado como seção 2.6.20).

**Implicação para o port**: `.COMMENT` não é um bloco delimitado por token fixo como o `###`/`''`
do Dignified — o delimitador é **dinâmico** (primeiro caractere não-espaço do argumento). O lexer
precisa de um modo especial: ao ver `.COMMENT`, capturar o próximo caractere não-espaço como
delimitador de fechamento e consumir texto bruto (não tokenizado) até reencontrá-lo.

## Símbolos

Regras (LR:180-186, M80:359-371):

- Caracteres válidos: letras (Nestor80 aceita qualquer letra Unicode ✨; M80 original só ASCII),
  dígitos, e `$ . ? @ _`. Primeiro caractere não pode ser dígito.
- **Case-insensitive**: `foo`, `FOO`, `Foo` são o mesmo símbolo (LR:184). Normalizar para
  maiúsculas antes de qualquer lookup em tabela de símbolos — mesma convenção já adotada em
  `resumo-asm.md` para o port.
- Sem limite de tamanho por padrão ✨; só ao gerar REL formato MACRO-80 com
  `--link-80-compatibility` os primeiros 6 caracteres viram significativos (LR:186, M80:361-362) —
  detalhe de REL, fora do escopo desta doc.
- Sufixo **`##`** numa *referência* a símbolo marca external (equivale a `EXTRN` implícito) — LR:190-199,
  M80:370-371, EXTRN em LR:2176-2197. **Nesta fase só precisa reconhecer a sintaxe e não quebrar o
  parser**; a semântica completa de resolução externa é assunto de REL/linker (fora do escopo aqui).
- Sufixo **`::`** numa *definição* de label marca público — equivalente a `PUBLIC` implícito
  (LR:201-212). Mesma observação: reconhecer a sintaxe agora, semântica plena fica para o linker.

**Implicação para o port**: o tokenizador de símbolo precisa aceitar `$ . ? @ _` misturados com
alfanuméricos E tratar `##`/`::` como sufixos especiais reconhecíveis (não como operadores soltos)
— cuidado para não confundir `##` com o prefixo hex `#nnnn` (ver seção de literais numéricos) nem
com o comentário Dignified `##` (não se aplica aqui, é outro pipeline/gramática).

### Constantes nomeadas: `EQU` vs `DEFL`/`ASET`

- **`EQU`** (LR:2135-2149, M80:703-709): `<nome>[:] EQU <expressão>` — constante **fixa**. Os
  dois-pontos após o nome são opcionais no Nestor80 (não permitidos no M80 original). Um segundo
  `EQU` com o mesmo nome e **valor diferente** é erro; com o **mesmo valor** é permitido
  (`FOO equ 34` / `FOO: equ 30+4` são ambos ok, LR:222-224).
- **`DEFL`** (alias **`ASET`**) (LR:1917-1933, M80:788-793 sob o nome `SET` no M80 original —
  atenção, ver nota abaixo): `<nome>[:] DEFL <expressão>` — constante **redefinível**, pode ser
  reatribuída (inclusive em termos de si mesma: `FOO defl FOO+1`).
- `EQU` e `DEFL` **não podem se misturar** para o mesmo nome — usar um depois do outro é erro
  "Symbol already exists" mesmo com o mesmo valor (LR:246-256).
- ⚠ **Pegadinha documentada** (LR:260): o manual M80 lista `SET` como alias de `DEFL`, mas na
  prática o MACRO-80 real nunca implementou isso — `SET` só é reconhecido como o mnemônico Z80
  `SET` (bit set). Nestor80 replica esse comportamento (doc erra, comportamento real não). **Não
  implementar `SET` como alias de `DEFL` no port** — só `DEFL`/`ASET`.

## Modelo de duas passadas

Conceito já resumido em `resumo-asm.md`; aqui os detalhes concretos (LR:36-90):

- **Pass 1**: para cada linha, o assembler determina quantos bytes ela vai gerar e avança o
  location counter (`$`) de acordo, **sem** ainda resolver símbolos/labels que apontam para frente
  — designa aos labels o valor de `$` no momento em que são vistos. Não grava bytes de saída ainda.
- **Pass 2**: com todos os símbolos já resolvidos, gera de fato os bytes (ex.: `CALL PROGRAM` vira
  `CALL 0104h` de verdade).
- **`$`** é o símbolo do location counter corrente — pode ser usado em qualquer expressão (ex.:
  `DEFS $+16` no `.ALIGN`, `ORG $+<size>` no `DEFS` sem valor em código relocável — LR:1959).
- **Overflow do location counter**: se depois de uma instrução que gera saída (não conta `ORG`) o
  valor do location counter ultrapassa `FFFFh`, ele **volta para 0** e um **warning** é emitido
  (LR:40) — não é erro fatal.
- **`IF1`/`IF2`** (LR:70, 774-780, 2243-2254): blocos condicionais que avaliam para verdadeiro
  conforme a passada corrente. Uso típico: emitir mensagens de diagnóstico só uma vez (evitar
  duplicar em pass 1 e pass 2), ou (exemplo avançado do Nextor citado em LR:72-86) gerar um `DEFW 0`
  hardcoded no pass 1 só para manter o location counter consistente entre passadas quando o valor
  real só pode ser resolvido no pass 2.
- ⚠ Nestor80 **pula o pass 2 inteiro se houver erro no pass 1** (mas não se houver só warning) —
  diferente do MACRO-80 original (LR:88). Consequência prática: erros que só existem no pass 2
  "somem" da mensagem de saída até os erros do pass 1 serem corrigidos — comportamento a replicar
  no port por ser mais previsível/rápido que rodar pass 2 sempre.

**Implicação para o port**: o driver de 2 passes (item já no checklist de `resumo-asm.md`) precisa
de um flag global "houve erro no pass 1?" que, se true, **aborta antes de iniciar o pass 2** (mas
continua reportando os erros já coletados do pass 1).

## Literais numéricos

Radix de 2 a 16, padrão 10, alterável em runtime com `.RADIX <valor>` (LR:263-265, 1601-1617; fora
do checklist da Fase A mas barato de reconhecer já que afeta o parsing de literal sem sufixo).
Quando radix > 10, `A`-`F` (case-insensitive) valem os dígitos após 9.

Notação de prefixo/sufixo (prefixos/sufixos case-insensitive) — LR:267-283:

| Notação | Radix |
|---|---|
| `nnnnB` | Binário |
| `nnnnI` 🆕 | Binário |
| `0bnnnn` 🆕 | Binário |
| `nnnnD` | Decimal |
| `nnnnM` 🆕 | Decimal |
| `nnnnO` | Octal |
| `nnnnQ` | Octal |
| `nnnnH` | Hexadecimal |
| `X'nnnn'` | Hexadecimal |
| `0xnnnn` 🆕 | Hexadecimal |
| `#nnnn` 🆕 | Hexadecimal (ver nota abaixo) |

⚠ **`&H` (prefixo hex do MSX-BASIC/Dignified) NÃO é suportado pelo Nestor80** — não existe na
tabela acima nem em nenhuma outra parte da doc. Se o port quiser aceitar `&H` como extensão de
conveniência (para quem vem do BASIC), é uma decisão de produto deliberada, não compatibilidade
M80 — documentar isso explicitamente no código se for feito, para não confundir com "spec".

- `#nnnn` só é hex por padrão; com `--discard-hash-prefix` o `#` é ignorado (número fica no radix
  corrente) — pensado para compatibilizar com o assembler SDAS. Fora de escopo replicar esse flag
  na Fase A, mas **não tratar `#` como erro de sintaxe** — é prefixo hex válido por padrão.
- ⚠ **Pegadinha documentada e preservada** (LR:285-294): os sufixos `B` e `D` ficam inutilizáveis
  quando o radix corrente é ≥12 (B) ou ≥14 (D), porque nesse caso `B`/`D` já são dígitos válidos do
  próprio número — `.radix 16` + `defw 1010b,1234d` lê `010Bh` e `234Dh`, não os literais
  binário/decimal pretendidos. Esse é o motivo dos novos sufixos `I` (binário) e `M` (decimal) do
  Nestor80. **Implicação para o port**: o parser de literal numérico precisa tentar o **maior radix
  possível primeiro** (greedy) e só then checar se sobra um sufixo de radix — a ambiguidade é
  inerente ao formato, não um bug a "corrigir".
- Overflow além de 16 bits é ignorado; resultado é os 16 bits baixos (LR:392, M80:393-394).
- String de até 2 bytes (no encoding corrente) pode ser usada como valor numérico em qualquer
  lugar que espera número — regras completas em LR:298-318 (big-endian em `DEFB`/`DEFW` como
  palavra, string vazia = 0). Baixa prioridade para Fase A (mais relevante para `DEFB`/`DEFW` que
  já cobrem strings diretamente), mas o avaliador de expressão deve aceitar string-literal de 1-2
  chars como operando numérico.

## Strings

Aspas simples ou duplas delimitam string (LR:320-363, M80:420-433):

- Aspas simples: **sem** escapes, exceto `''` para aspas simples literal dentro da string
  (`DEFB 'This ain''t gonna escape much'`).
- Aspas duplas: escapes com `\` habilitados por padrão 🆕 (tabela abaixo). Desligável com
  `--no-string-escapes` ou `.STRESC OFF` em código — nesse modo, `""` também vira o jeito de
  escapar aspas duplas dentro de string dupla (paridade com aspas simples).

| Sequência | Nome | Valor |
|---|---|---|
| `\'` | aspas simples | 27h |
| `\"` | aspas duplas | 22h |
| `\\` | barra invertida | 5Ch |
| `\0` | nulo | 00h |
| `\a` | alert | 07h |
| `\b` | backspace | 08h |
| `\f` | form feed | 0Ch |
| `\n` | nova linha | 0Ah |
| `\r` | carriage return | 0Dh |
| `\t` | tab horizontal | 09h |
| `\v` | tab vertical | 0Bh |
| `\xHH` | escape arbitrário, 2 dígitos hex | ex.: `\x12` = 12h |
| `\uHHHH` | escape arbitrário, 4 dígitos hex (UTF-16) | ex.: `\uABCD` → CDh, ABh |

- String vazia (`''`/`""`) não gera saída em `DEFB` (LR:363).
- `DEFB` converte string inteira byte-a-byte (qualquer tamanho); em contexto de valor numérico, só
  strings de 0-2 bytes são aceitas.

**Implicação para o port**: strings simples e duplas têm **regras de escape diferentes** — não dá
para reaproveitar um único caminho de parsing; o lexer precisa saber qual aspas abriu a string para
decidir se interpreta `\`.

## Expressões

Operadores, em ordem de precedência **decrescente** (10 = mais alta) — LR:394-424:

| Operador | Significado | Precedência |
|---|---|---|
| `NUL` | resto da linha vazio? | 10 |
| `TYPE` | tipo do argumento | 9 |
| `LOW` | byte baixo | 8 |
| `HIGH` | byte alto | 8 |
| `*` | multiplicação | 7 |
| `/` | divisão inteira | 7 |
| `MOD` | resto da divisão inteira | 7 |
| `SHR` | shift à direita | 7 |
| `SHL` | shift à esquerda | 7 |
| `-` (unário) | menos unário | 6 |
| `+` | soma | 5 |
| `-` | subtração | 5 |
| `EQ` / `=` 🆕 | igual | 4 |
| `NE` / `NEQ` 🆕 | diferente | 4 |
| `LT` | menor que | 4 |
| `LE` / `LTE` 🆕 | menor ou igual | 4 |
| `GT` | maior que | 4 |
| `GE` / `GTE` 🆕 | maior ou igual | 4 |
| `NOT` | NOT bit a bit (complemento de um) | 3 |
| `AND` | AND bit a bit | 2 |
| `OR` | OR bit a bit | 1 |
| `XOR` | XOR bit a bit | 1 |

Regras gerais:

- Precedência mais alta é computada primeiro; mesma precedência é aplicada na ordem de aparição
  (esquerda para direita). Parênteses sobrescrevem a ordem padrão. Ex.: `2+3*4` = 14, `(2+3)*4` = 20.
- Operadores de comparação avaliam para `FFFFh` (verdadeiro) ou `0` (falso) e tratam números como
  **sem sinal** — `x LT 0` é sempre falso, não importa `x` (LR:451, M80:454). Ver `IF` (abaixo)
  para o idioma correto de checar "é negativo": `(x AND 8000h) EQ 8000h`.
- `HIGH`/`LOW` extraem byte alto/baixo de um valor 16 bits (`HIGH 1234h` = `12h`, `LOW 1234h` =
  `34h`) — LR:453.
- `NUL`: verdadeiro (`0FFFFh`) se o resto da linha (excluindo comentário) só tem espaços/tabs;
  falso (`0`) caso contrário — pensado para uso dentro de expansão de macro (checar argumento
  vazio); `IFB`/`IFNB` são a alternativa mais legível (LR:429-433).
- `TYPE`: valor fixo conforme o tipo do argumento — `0x20` para constante numérica/símbolo
  absoluto, `0x80` para referência a símbolo externo, `0x21`/`0x22`/`0x23` para símbolo em
  segmento código/dados/COMMON (só relevante em REL — fora de escopo pleno aqui, mas útil reservar
  os valores). ⚠ `TYPE` com expressão complexa (não símbolo isolado) tem comportamento errático
  documentado como incompatibilidade — em Nestor80 lança erro (`TYPE (FOO##+1)`) em vez do
  resultado "estranho" que o M80 dava (LR:447).
- **`$`**: símbolo do location counter corrente, usável em qualquer expressão.
- ⚠ **M80 exige espaço em volta de todo operador exceto `+ - * /`** (M80:469-470) — ou seja, `AND`,
  `MOD`, `SHR`, `EQ` etc. são palavras-chave que precisam de boundary léxico, não símbolos soltos.
  **Implicação para o port**: o lexer de expressão precisa reconhecer esses operadores por
  correspondência de palavra (maximal munch respeitando fronteira de símbolo), não por
  caractere-a-caractere como `+`/`-`/`*`/`/`.

**Implicação para o port — precedência do menos unário**: note que o `-` unário (precedência 6)
fica **entre** o grupo multiplicativo (7) e o aditivo (5), não acima de tudo como é comum em
avaliadores de expressão simples. Um shunting-yard ingênuo que trata unário como "sempre reduz
primeiro" dá resultado errado em casos limite — implementar a precedência exatamente como a tabela,
tratando `-` unário como mais um operador com precedência própria (6) na pilha de operadores, não
como um caso especial resolvido no lexer.

`Expressões bare` (`--allow-bare-expressions`, linha `1,2,3,4` equivalente a `DEFB 1,2,3,4`) —
desligado por padrão em Nestor80, **não implementar na Fase A** (LR:493-497, já mencionado acima).

## Diretivas de dados

### `DEFB` (`DB`, `DEFM`)

_Sintaxe:_ `DEFB <expressão ou string>[,<expressão ou string>[,...]]` (LR:1894-1914, M80:596-620).

Cada item é uma expressão (deve caber em 1 byte — erro de overflow se o byte alto não for `0` nem
`FFh`) ou uma string (convertida byte a byte pelo encoding corrente). Exemplo da doc:

```
FOO equ 10h
DEFB 0FF34h,FOO*2,"ABC\r\n"
;Gera: 34h,20h,41h,42h,43h,0Dh,0Ah
```

### `DEFW` (`DW`)

_Sintaxe:_ `DEFW <expressão ou string>[,...]` (LR:1965-1985). Cada item vira uma **palavra** de 16
bits em little-endian; strings (até 2 bytes no encoding corrente) são gravadas em ordem invertida
em relação a `DEFB` (segundo byte do encoding primeiro, depois o primeiro).

### `DEFS` (`DS`)

_Sintaxe:_ `DEFS <tamanho>[,<valor>]` (LR:1936-1962, M80:635-644). Reserva bloco contíguo de
`<tamanho>` bytes, opcionalmente preenchido com `<valor>` repetido (`DEFS 5,34` ≡
`DEFB 34,34,34,34,34`). Sem `<valor>`:
- build absoluto → equivale a `DEFB <tamanho>,0` (preenche com zero).
- build relocável (fora do escopo pleno aqui) → equivale a `ORG $+<tamanho>` (avança o location
  counter, mas o bloco vira "gap de memória" pro linker — comportamento de preenchimento
  indefinido), a menos que `--initialize-defs` esteja ativo.

Nota M80 (M80:639-644): todos os nomes usados em `<tamanho>` precisam já estar definidos no pass 1
(senão erro `V`/`U` e possível "phase error" porque o `DEFS` não gerou o mesmo tamanho nas duas
passadas) — implicação direta do modelo de 2 passes: `DEFS` **não pode depender de um label que
ainda não apareceu**.

### `DC` (Define Character)

_Sintaxe:_ `DC <string>` — **não documentado em `LanguageReference.md`** (só citado de passagem na
lista de instruções que forçam build absoluto, LR:107); a semântica vem do manual M80 original
(M80:623-632) e foi confirmada lendo a implementação C# do próprio Nestor80
(`Assembler/AssemblySourceProcessor.PseudoOps.cs:151`, comentário `"DC <string>: Define string with
last character having MSB set"`, dispatch em `ProcessDcLine` linha 484).

Grava os caracteres da string com o bit 7 **zerado**, exceto o **último caractere**, que é gravado
com o bit 7 **setado** (`OR 80h`) — técnica clássica de string terminada por "byte marcador" sem
precisar de um byte extra de tamanho/zero. Erro se a string for vazia (M80:632).

### `DEFZ` (`DZ`) 🆕

_Sintaxe:_ `DEFZ <expressão ou string>[,...]` (LR:1988-2009). Equivalente a `DEFB`, mas acrescenta
os bytes que o encoding corrente gera para `\0` no final — atalho para string terminada em zero
(`DEFZ "Hello"` ≡ `DEFB "Hello",0` em ASCII).

## Segmentação / relocação (reconhecer sintaxe, sem semântica plena nesta fase)

Estas diretivas só têm efeito completo ao gerar arquivo relocável MACRO-80 — na Fase A elas
**precisam ser reconhecidas e não quebrar o parser** (avançar o location counter certo dentro de
cada segmento), mas a integração real com o linker é `resumo-asm.md` Fase B / `nestor80-linker.md`.

| Diretiva | Sintaxe | Semântica |
|---|---|---|
| `ASEG` | `ASEG` | Muda para o segmento absoluto; `$` volta ao valor que tinha da última vez que esse segmento foi trocado (ou 0 na primeira vez) — LR:1785-1810 |
| `CSEG` | `CSEG` | Segmento de código; é o padrão no início da montagem, `$` = 0 — LR:1867-1891 |
| `DSEG` | `DSEG` | Segmento de dados — LR:2012-2035 |
| `COMMON` | `COMMON /[<nome>]/` | Bloco COMMON identificado por nome entre `/…/` (case-insensitive, pode ser vazio); ao entrar, `$` **sempre volta a 0** (não preserva o último valor, diferente de ASEG/CSEG/DSEG) — LR:1813-1836 |
| `PUBLIC` (`ENTRY`, `GLOBAL`) | `PUBLIC <símbolo>[,...]` | Marca símbolos como públicos (equivalente a sufixo `::` na definição de label) — LR:2756-2777 |
| `EXTRN` (`EXT`, `EXTERNAL`, `.GLOBL`) | `EXTRN <símbolo>[,...]` | Marca símbolos como externos (equivalente a sufixo `##` na referência) — LR:2176-2197 |

⚠ Não confundir `.GLOBL` (alias de `EXTRN`, para compatibilidade sdasz80) com `GLOBAL` (alias de
`PUBLIC`) — nomes quase idênticos, semântica oposta (LR:2195, LR:2775).

Cada segmento mantém **seu próprio location counter independente**; trocar de segmento restaura o
`$` daquele segmento (exceto COMMON, que zera). **Implicação para o port**: a estrutura de estado
do assembler precisa de um "location counter por segmento ativo" (ao menos ASEG/CSEG/DSEG/COMMON
com nome), não um único `$` global — mesmo que a Fase A só monte para segmento absoluto na prática
(sem `ORG` relocável real ainda).

## `ORG` / `END`

### `ORG`

_Sintaxe:_ `ORG <endereço>` (LR:2664-2741). Muda o location counter corrente. Em código absoluto,
o `ORG` de menor endereço vira a base do arquivo de saída; `ORG`s subsequentes se movem
relativamente a essa base, preenchendo buracos com zero (estratégia "memory map", ver LR:124-146
para a estratégia alternativa "direct output file write", ativada por `--direct-output-write` — não
prioritário na Fase A, mas útil registrar que existe: nesse modo `ORG` vira equivalente a
`.PHASE`).

Exemplo LR:2672-2681 (comportamento memory-map, o único relevante para a Fase A):

```
org 20
db 1,2,3
org 15
db 4,5,6
```

Saída: `4,5,6,0,0,1,2,3` (ORG 15 é a base; ORG 20 escreve 5 bytes à frente dela, preenchendo os 2
bytes entre 18h-19h com zero).

### `END`

_Sintaxe:_ `END [<endereço>]` (LR:2047-2053, M80:666-686). Termina o processamento do arquivo-fonte
imediatamente, ignorando qualquer coisa depois. `<endereço>` opcional só importa para REL (endereço
de start do programa, usado pelo linker) — em build absoluto é ignorado com warning.

## Condicionais

Formato geral (LR:744-772):

```
<instrução IF> [<argumentos>]
  <bloco verdadeiro>
[ELSE
  <bloco falso>]
ENDIF
```

Aninhável. Tabela completa (LR:774-793) — todas fazem parte do checklist da Fase A exceto onde
marcado:

| Instrução | Argumento(s) | Verdadeiro quando... |
|---|---|---|
| `IF` (`IFT`, `COND`) | expressão | expressão ≠ 0 |
| `IFF` (`IFE`) | expressão | expressão = 0 |
| `IF1` | — | montador está no pass 1 |
| `IF2` | — | montador está no pass 2 |
| `IFDEF` | nome de símbolo | símbolo está definido |
| `IFNDEF` | nome de símbolo | símbolo **não** está definido |
| `IFB` | `"<"texto">"` | texto é vazio (comprimento zero) |
| `IFNB` | `"<"texto">"` | texto **não** é vazio |
| `IFIDN` | `"<"t1">","<"t2">"` | t1 idêntico a t2 (case-sensitive, inclusive espaços) |
| `IFDIF` | `"<"t1">","<"t2">"` | t1 diferente de t2 |
| `IFIDNI` 🆕 | `"<"t1">","<"t2">"` | t1 idêntico a t2, case-insensitive |
| `IFDIFI` 🆕 | `"<"t1">","<"t2">"` | t1 diferente de t2, case-insensitive |
| `IFABS` 🆕 | — | build type é absoluto — fora do escopo pleno (REL), citado por completude |
| `IFREL` 🆕 | — | build type é relocável — idem |
| `IFCPU`/`IFNCPU` 🆕 | nome de CPU | CPU corrente é/não é a indicada — fora do escopo (R800/Z280) |
| `ELSE` | — | fecha bloco verdadeiro, abre bloco falso |
| `ENDIF` | — | fecha o bloco condicional |

Detalhes de sintaxe importantes:

- **`IFB`/`IFNB`/`IFIDN`/`IFDIF`/`IFIDNI`/`IFDIFI` exigem `< >` literais** em volta de cada
  argumento de texto (LR:1264, 2266-2290, 2391-2456) — não são delimitadores opcionais, fazem parte
  da sintaxe. Ex.: `IFB <x>`, `IFIDN <x>,<y>`.
- `IF`/`IFF` aceitam qualquer expressão válida (mesma gramática da seção "Expressões" acima,
  incluindo os operadores de comparação que retornam `FFFFh`/`0`).
- ⚠ `IFDEF`/`IFNDEF` são sensíveis à passada corrente exatamente como qualquer símbolo: um símbolo
  definido mais adiante no arquivo (via `EQU`, label etc.) só é "definido" a partir do ponto em que
  o parser passou por ele **naquela passada** — LR:2316-2357 tem um exemplo completo mostrando que
  `IFDEF foo` antes do `foo EQU 1` é falso no pass 1 mas true a partir do pass 2 (porque no pass 2 o
  símbolo já existe globalmente desde o início). **Implicação para o port**: a tabela de símbolos
  precisa mesmo ser populada incrementalmente durante o pass 1 (não pré-varrida) para reproduzir
  esse comportamento exatamente.

## Macros: `MACRO`/`ENDM`/`EXITM`/`LOCAL` (+ `CONTM`)

`REPT`/`IRP`/`IRPC`/`IRPS` (macros de repetição) estão **fora de escopo desta fase** — ver
`resumo-asm.md`. Esta seção cobre só macro **nomeada**.

### Definição e expansão

_Sintaxe:_ `<nome>[:] MACRO [<placeholder1>[,<placeholder2>[,...]]]` ... corpo ... `ENDM` (LR:883-923,
M80:1304-1385). Os dois-pontos após `<nome>` são opcionais no Nestor80 (não permitidos no M80
original). A macro só expande quando `<nome>` aparece como se fosse uma instrução, em qualquer
lugar depois da definição.

```
SUM: macro first,second
ld a,first
add a,second
endm

SUM 1,2        ; expande para: ld a,1 / add a,2
```

- Redefinir uma macro com o mesmo nome **substitui** a anterior (compatível com M80), mas Nestor80
  emite **warning** (LR:909-923) — comportamento a replicar (não é erro fatal).
- **Argumentos a mais são ignorados; argumentos a menos viram string vazia** (LR:939-940,
  M80:1332-1337) — `FOO: MACRO X,Y,Z` chamado como `FOO 1,2` deixa `Z` vazio; chamado como
  `FOO 1,2,3,4,5` ignora `4,5`.
- 🚫 Macros nomeadas **não podem ser aninhadas dentro de outras macros nomeadas** (LR:1069) — MACRO-80
  permitia, Nestor80 não. Macros de repetição (fora de escopo aqui) podem aninhar normalmente dentro
  de nomeadas e de outras de repetição.

### Regras de substituição de placeholder (LR:926-970, M80:1418-1446)

Assumindo um placeholder chamado `foo`:

1. Busca **case-insensitive** (`FOO` também substitui).
2. **Não substitui dentro de comentários** (`db 0 ;foo` não muda).
3. **Não substitui quando colado a caracteres válidos de símbolo** — substitui em `foo+1`, não em
   `foobar` nem `@foo`.
4. **`&`** antes (e depois, se preciso) do nome do placeholder força a substituição mesmo colado:
   argumento `X`, `bar&foo` → `barX`; `the&foo&bar` → `theXbar`.
5. **Não substitui dentro de strings** por padrão — `db "foo"` não muda. `&` resolve isso também:
   argumento `FIZZ`, `db "&foo"` → `db "FIZZ"`.

Exemplo completo (LR:944-970) ilustrando todas as regras:

```
THEMACRO macro foo
foo: ;Substituído!
FOO: ;Substituído!
foobar: ;Colado com char de símbolo? Sem substituição
bar&foo: ;Substituído!
the&foo&bar: ;Substituído!
defb "Oh, the foo! Is this &foo or &foo&bar?"
endm

THEMACRO FIZZ
```

expande para:

```
FIZZ: ;Substituído!
FIZZ: ;Substituído!
foobar: ;Colado com char de símbolo? Sem substituição
barFIZZ: ;Substituído!
theFIZZbar: ;Substituído!
defb "Oh, the foo! Is this FIZZ or FIZZbar?"
```

### Caracteres especiais em expansão de macro (LR:972-1034, M80:1418-1531)

| Caractere | Papel |
|---|---|
| `;;` | comentário que começa com `;;` dentro do corpo da macro **não** aparece na expansão em listing (irrelevante sem listing na Fase A, mas o lexer de macro precisa reconhecer `;;` como variante de comentário) |
| `!` | escape: o caractere seguinte é interpretado literalmente na lista de argumentos, mesmo se for um caractere "reservado" (espaço, vírgula) — `THEMACRO ! ,!,,!!` passa os argumentos `" "`, `","`, `"!"` |
| `%` | na frente de um argumento, força ele a ser **avaliado como expressão numérica** antes de virar o texto substituído (chamada "por valor" em vez de "por referência textual") — `THEMACRO %FOO+30` com `FOO equ 4` passa `34` como texto, não `FOO+30` |

`EXITM` (LR:2152-2173, M80:1394-1400): termina a expansão/repetição corrente imediatamente,
descartando qualquer repetição restante (relevante mesmo sem `REPT` — funciona em `MACRO` também).

`CONTM` 🆕 (LR:1839-1864): parecido com `EXITM` dentro de macro nomeada, mas dentro de macro de
repetição pula pro **início da próxima repetição** em vez de abortar tudo — fora do escopo pleno
(repetição não é Fase A) mas útil registrar a distinção semântica caso `EXITM` seja usado dentro de
uma `MACRO` aninhada em contexto futuro.

### `LOCAL` (LR:1036-1061, 2630-2634, M80:1403-1415)

_Sintaxe:_ `LOCAL <símbolo>[,<símbolo>[,...]]`, deve ser a **primeira instrução dentro do corpo da
macro** (M80:1414-1415). Declara símbolos que, a cada expansão, são substituídos por um símbolo
único no formato `..<número hexadecimal>`, incrementado globalmente (não por macro) a cada uso —
`..0000`, `..0001`, etc. (LR:1040). Resolve o problema de "Symbol already defined" ao expandir a
mesma macro mais de uma vez com um label fixo no corpo.

```
NEVEREND macro
local loop
loop: jp loop
endm

NEVEREND
NEVEREND
NEVEREND

; equivalente a:
..0000: jp ..0000
..0001: jp ..0001
..0002: jp ..0002
```

**Implicação para o port**: o contador de `..NNNN` é **um único contador global do programa
inteiro**, compartilhado entre todas as macros e todas as expansões — não reiniciar por macro nem
por arquivo.

## Sintaxe de instruções de CPU (gramática de modos de endereçamento)

Nem `LanguageReference.md` nem `MACRO-80.txt` documentam os modos de endereçamento Z80 em prosa —
são assumidos como conhecimento prévio do leitor (o M80 só tem uma nota residual, seção "Opcodes as
Operands"/M80:537-558, que é uma peculiaridade **exclusiva do 8080** para usar bytes de opcode como
operando literal, e o próprio manual avisa "Opcodes are not valid operands in Z80 mode" — M80:555-558,
**não se aplica a Z80/Nestor80, fora de escopo**). A gramática abaixo foi confirmada lendo a
implementação (`Assembler/AssemblySourceProcessor.Z80Instructions.cs` e
`Assembler/AssemblySourceProcessor.CpuInstructions.cs`), que é exatamente o "3º nível" (tabela de
opcodes) que o port em PureBasic precisa replicar.

### Formas de operando aceitas

| Forma | Exemplos | Observação |
|---|---|---|
| Registrador de 8 bits | `A B C D E H L` | |
| Registrador de 8 bits (não documentado, sempre suportado) | `IXH IXL IYH IYL` | LR:1361: "Z80 undocumented instructions são sempre suportadas" |
| Registrador de 16 bits | `BC DE HL SP IX IY AF` | `AF'` também aceito como 2º argumento de `EX AF,AF'` |
| Indireto via registrador | `(BC) (DE) (HL) (C)` | `(C)` só em `IN`/`OUT` (porta), não é endereço de memória |
| Indexado com deslocamento | `(IX+d) (IX-d) (IY+d) (IY-d)` | `d` é uma expressão (byte com sinal) |
| Indexado **sem** deslocamento (atalho) | `(IX) (IY)` | equivalente a `(IX+0)`/`(IY+0)` — **não** é um caso especial da expressão, é reconhecido como forma literal própria (ver abaixo) |
| Imediato de 8 bits | `n` | qualquer expressão que caiba em 1 byte |
| Imediato de 16 bits | `nn` | qualquer expressão |
| Endereço direto/estendido | `(nn)` | ex.: `LD (1234h),HL`, `LD A,(FOO)` |
| Porta imediata | `(n)` | só `IN A,(n)` / `OUT (n),A` |
| Código de condição | `NZ Z NC C PO PE P M` | usado em `JP cc,nn` / `CALL cc,nn` / `RET cc` / `JR cc,e` (só `NZ Z NC C` para `JR`) — atenção: `C` é ambíguo entre "condição carry" e "registrador C", desambiguado pela posição/instrução |
| Bit literal | `0`-`7` | argumento de `BIT`/`SET`/`RES` |
| Implícito | (nenhum argumento) | `NOP`, `RET`, `EI`, etc. |

### O atalho `(IX)`/`(IY)` é tratado como forma literal, não como caso-zero da expressão

Confirmado em `AssemblySourceProcessor.Z80Instructions.cs` (ex.: linhas 628-740): existe uma entrada
de tabela **fixa** separada para cada mnemônico com `(IX)`/`(IY)` (ex.: `"LD A,(IX)"` →
`{0xdd,0x7e,0}`) **além** da entrada de tabela **variável** para `(IX+n)` (ex.: `"LD A" +
CpuInstrArgType.IxOffset` → `{0xdd,0x7e,0}`, `AssemblySourceProcessor.CpuInstructions.cs` via a
constante `Z80ldIxyByteInstructions`). O regex que reconhece a forma indexada
(`ixPlusArgumentRegex`, `AssemblySourceProcessor.CpuInstructions.cs:14`) é:

```
^(\(\s*IX\s*[+-].+\))|(.+\(\s*IX\s*\))$
```

ou seja, **exige** um `+`/`-` explícito para cair no caminho "com deslocamento variável"; `(IX)`
sem sinal cai no caminho de string fixa (deslocamento hardcoded em `0` na tabela). Já
`(HL)`/`(DE)`/`(BC)`/`(C)`/`(SP)` como registrador indireto puro batem com
`z80MemPointedByRegisterRegex` (`AssemblySourceProcessor.CpuInstructions.cs:20`):

```
^\(\s*(?<reg>HL|DE|BC|IX|IY|SP|C)\s*\)$
```

**Implicação para o port — mapeia direto pro "3 níveis" já planejado em `resumo-asm.md`**:

1. **Nível fixo** (string normalizada `MNEMÔNICO ARG1,ARG2` → bytes): cobre a maioria das
   combinações registrador-registrador/registrador-indireto, incluindo `(IX)`/`(IY)` sem
   deslocamento (offset fixo `0` embutido no array de bytes).
2. **Nível "1 argumento variável"**: `(IX+n)`/`(IY+n)` com `n` sendo uma expressão a avaliar — a
   posição do byte de offset dentro do array de saída é conhecida estaticamente por instrução (ver
   `Z80ldIxyByteInstructions`, offset sempre no índice 2 do array `{0xdd,0x36,0,0}` etc.), e o valor
   imediato (byte ou palavra) ocupa a posição seguinte.
3. **Nível "seletor"**: instruções `BIT`/`SET`/`RES` (bit 0-7 seleciona linha da tabela de opcode
   dentro do bloco `CB`) e o grupo de rotação/shift `RLC/RRC/RL/RR/SLA/SRA/SRL` sobre `(IX+n)`/`(IY+n)`
   combinam **os dois**: offset variável (posição 2) + opcode final selecionado pelo mnemônico
   (posição 3) — ver `{0xdd,0xcb,0,0x16}` para `RL (IX+n)` como exemplo.

- **Normalização de espaço em volta de parênteses**: o parser remove espaços logo após `(` e antes
  de `)` antes de fazer o lookup na tabela fixa (`RemoveSpacesAroundParenthesis`,
  `AssemblySourceProcessor.CpuInstructions.cs:96-108`) — `( HL )` e `(HL)` são equivalentes.
  **Implicação para o port**: normalizar (trim interno) o texto do operando antes de qualquer
  lookup em tabela de string fixa, senão `LD A,( HL )` falha por não bater a chave exata.
- `IN A,(C)`/`OUT (C),r` usam `(C)` como forma **fixa** (tabela `Z80Instructions.cs:193,398-404`);
  `IN A,(n)`/`OUT (n),A` usam a forma de porta imediata (`CpuInstrArgType.ByteInParenthesis`,
  `CpuInstructions.cs:807`) — duas famílias de sintaxe distintas para `IN`/`OUT`, não confundir.

Não é escopo desta doc listar a tabela de opcodes completa (é implementação, não spec) — o
levantamento acima é o suficiente para o "3º nível" do port saber **quais formas de operando
existem** e como categorizá-las ao construir as próprias tabelas fixo/variável/seletor.

## Fora de escopo desta fase

Citado só para não ser confundido com omissão — ver justificativa completa em `resumo-asm.md`
("Fora de escopo (Fase C)") e nos próprios headers do `LanguageReference.md`:

- `REPT`/`IRP`/`IRPC`/`IRPS` (macros de repetição) — LR:808-882, 2560-2629, 2780-2807.
- `MODULE`/`ENDMOD` e labels locais/relativos (namespacing por módulo, `.RELAB`/`.XRELAB`) —
  LR:505-741, 2644-2650, 2070-2076.
- `R800`/`Z280` (extensões de CPU, `.CPU`, `MULUB`/`MULUW` etc.) — LR:1337-1361 e
  `Z280Support.md` (não lido).
- `AREA`/`.AREA` (formato SDCC) — LR:1736-1783.
- Saída Intel HEX, diretivas de arquivo de listagem (`PAGE`/`TITLE`/`SUBTTL`/`.LIST`/`.XLIST`/
  `.LALL`/`.SALL`/`.XALL`/`.LFCOND`/`.SFCOND`/`.TFCOND`/`MAINPAGE` etc.) — LR:1147-1253 e diversos
  headers individuais.
- Biblioteca/`.REQUEST` (equivalente a LB80) — LR:1627-1635 e M80 seção 5 (Libstor80/LIB-80).
- `AREA`-relativo `ORG` incremental, `NAME`, `.EXTROOT`, `ROOT` — só fazem sentido com REL pleno.
- `.PRINT`/`.PRINT1`/`.PRINT2`/`.PRINTX`/`.WARN`/`.ERROR`/`.FATAL` e interpolação de expressão
  (`{expr:radix}`) — diagnósticos em tempo de montagem, não afetam a saída binária; podem ser
  adiados sem risco (mas são baratos de adicionar depois, considerar para Fase B se sobrar tempo).
- Opcodes-como-operando (peculiaridade 8080, M80:537-558) — não existe em modo Z80, não precisa
  nem de "fora de escopo", é literalmente não-aplicável.

## Pontos de atenção para o port

- **A tabela de símbolos precisa ser populada incrementalmente durante cada passada** (não
  pré-varrida antes do pass 1) para reproduzir corretamente `IFDEF`/`IF1`/`IF2` e o exemplo
  documentado em LR:2316-2357 onde o mesmo `IFDEF foo` dá respostas diferentes dependendo de estar
  antes ou depois do `EQU`, e entre pass 1 e pass 2.
- **Erro no pass 1 cancela o pass 2 inteiro** (não warning) — replicar esse corte, é o
  comportamento real do Nestor80, não um detalhe negligenciável (LR:88).
- **Overflow do location counter (`$` > `FFFFh`) é warning + wraparound para 0, não erro fatal** —
  fácil de esquecer ao portar a lógica de "avançar `$` a cada linha".
- **Precedência do `-` unário (6) fica entre multiplicativo (7) e aditivo (5)** — não é a
  precedência mais alta como em avaliadores de expressão "ingênuos"; ver seção Expressões acima.
  Este é provavelmente o detalhe mais fácil de portar errado sem perceber (os testes com números
  simples não pegam a diferença).
- **`&H` do MSX-BASIC não é sintaxe válida de literal numérico no Nestor80** — se o port decidir
  aceitar mesmo assim (conveniência para quem migra do Dignified), documentar como extensão
  própria, não como "spec Nestor80".
- **`SET` NÃO é alias de `DEFL`** apesar do manual M80 dizer o contrário — é só o mnemônico Z80
  `SET` (bit set). Comportamento real > texto da doc, aqui e em qualquer outra discrepância entre
  `MACRO-80.txt` e o que o `LanguageReference.md`/código-fonte C# realmente implementam (Nestor80
  documenta explicitamente vários desses casos com o ícone ⚠🚫; onde não documenta, e há dúvida, o
  código-fonte C# em `nestor80/Assembler/*.cs` é o desempate — usado aqui para `DC` e para a
  gramática de modos de endereçamento).
- **`(IX)`/`(IY)` sem deslocamento são casos literais na tabela fixa, não `(IX+0)` resolvido pelo
  avaliador de expressão genérico** — importa para como o port organiza os 3 níveis de lookup de
  opcode (ver seção de modos de endereçamento).
- **`DC` não está documentado no `LanguageReference.md` atual** — comportamento confirmado só via
  código-fonte C# (`ProcessDcLine`) e o manual M80 original; se uma versão futura do Nestor80 mudar
  esse comportamento, este arquivo pode ficar desatualizado nesse ponto específico (risco baixo,
  mas registrado).
