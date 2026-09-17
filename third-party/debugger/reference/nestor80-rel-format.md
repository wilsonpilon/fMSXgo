# Referência: formato `.REL` (Linkstor80/LK80) — Fase B do assembler Z80

> Documentação técnica extraída de `nestor80/docs/RelocatableFileFormat.md` e
> `nestor80/docs/WritingRelocatableCode.md`, para servir de especificação ao gerador `.REL` nativo em
> PureBasic (**módulo 2b** do `docs/SPEC.md`). Complementa `docs/reference/nestor80-language.md` (que
> cobre só a Fase A, saída absoluta) e `docs/resumo-asm.md` (estado da implementação). Convenção de
> citação: `RFF:<assunto>` = `RelocatableFileFormat.md`, `WRC:<assunto>` = `WritingRelocatableCode.md`.
>
> `nestor80/` é clone raso gitignored (mesmo tratamento de `badig/`): referência de leitura, não
> dependência de runtime. `LK80.exe`/`LB80.exe` (compilados localmente a partir do clone, mesma receita
> do `N80.exe` já documentada em `docs/resumo-asm.md`) servem de **oráculo de teste** pro linker e pro
> gerenciador de biblioteca nativos, gerando `.REL`/`.BIN`/`.LIB` reais pra comparar byte a byte.

## Modelo geral: um arquivo `.REL` é um bit-stream, não um formato byte-alinhado

Ao contrário de quase todo formato binário deste projeto (`.dsk`, `.bmx`), um `.REL` é lido/escrito
**bit a bit**, não byte a byte — bits dentro de um byte são consumidos na ordem, e um "item" pode
terminar no meio de um byte, com o próximo item continuando dali. Isso muda a estrutura de dados
interna: não dá pra usar `PeekB`/`PokeB` puro, precisa de um leitor/escritor de bit-stream próprio
(acumula bits num buffer, extrai byte quando junta 8).

Três tipos de item, cada um com um prefixo de bits que os distingue:

| Prefixo | Tipo | Conteúdo |
|---|---|---|
| `0` | Byte absoluto | + 8 bits do valor |
| `1` | Valor relocável | + 2 bits de segmento + 16 bits do valor (little-endian) |
| `100` | Item de link | + 4 bits de tipo (0-15) + campos opcionais (endereço/símbolo) conforme o tipo |

Segmento (2 bits, usado tanto no item "valor relocável" quanto nos link items que carregam endereço):
`01`=código (CSEG), `10`=dados (DSEG), `11`=COMMON.

## Os 16 tipos de link item (`100` + 4 bits de tipo)

Cada tipo declara se carrega um campo de **endereço relocável** (2 bits segmento + 16 bits valor) e/ou
um campo de **símbolo** (3 bits de tamanho + N bytes — ver "Campo de símbolo estendido" abaixo pro
formato Nestor80 estendido).

| Tipo | Nome | Campos | Semântica |
|---|---|---|---|
| 0 | Declarar símbolo | símbolo | Emitido no início do arquivo para cada símbolo público/externo usado depois |
| 1 | Selecionar bloco COMMON | símbolo | Itens seguintes pertencem ao bloco COMMON nomeado |
| 2 | Nome do programa | símbolo | De `NAME`/`TITLE` |
| 3 | Pedido de busca em biblioteca | símbolo | De `.REQUEST` |
| 4 | Item de extensão | símbolo (1º byte = subtipo, ver abaixo) | Escape — expressões com externos, ver "Itens de extensão" |
| 5 | Definir tamanho de bloco COMMON | endereço | Valor = último endereço usado no bloco + 1 |
| 6 | Cadeia de externo (chain) | endereço + símbolo | Endereço = cabeça de uma lista encadeada de posições a corrigir; símbolo = nome do externo. Cada posição guarda o "próximo" (16 bits), terminada por byte absoluto `0` |
| 7 | Definir símbolo público | endereço + símbolo | Nome+valor; o linker casa isso contra os externos |
| 8 | Externo menos deslocamento | símbolo | Nunca gerado pelo MACRO-80 nem pelo Nestor80 |
| 9 | Externo mais deslocamento | endereço + símbolo | Pra expressões `simbolo+valor`/`simbolo-valor` (valor em complemento de 2 quando negativo) |
| 10 | Definir tamanho do segmento de dados | endereço | Último endereço DSEG usado + 1 |
| 11 | Trocar contador de localização | endereço | `ASEG`/`CSEG`/`DSEG`/`COMMON` geram isso — trocar pra ASEG/CSEG/DSEG retoma do último-usado+1 daquele segmento; COMMON sempre reseta pra 0 |
| 12 | Cadeia de endereço | endereço + símbolo | Como o 6, mas pra endereço relocável; nunca gerado de verdade |
| 13 | Definir tamanho do segmento de código | endereço | Último endereço CSEG usado + 1 |
| 14 | Fim de programa | endereço (valor = operando do `END`, ou 0 absoluto) | De `END`. **Força alinhamento de byte** (descarta bits parciais restantes) |
| 15 | Fim de arquivo | nenhum | Bits fixos `100 1111`, sem valor/símbolo. Resto do arquivo é ignorado |

## Itens de extensão (tipo 4) — expressões com símbolo externo

Quando uma expressão não pode ser resolvida na hora de montar (envolve um símbolo `##`), ela é
serializada como uma sequência de itens de extensão em **notação polonesa reversa (RPN)**. O campo de
símbolo do item tipo 4 começa com 1 byte de subtipo, resto é o payload:

- **`41h` Operador aritmético** — 2 bytes: `41h` + código do operador. Códigos legados (1-11):
  1=armazenar como byte, 2=armazenar como word, 3=byte alto, 4=byte baixo, 5=NOT, 6=menos unário,
  7=subtração, 8=soma, 9=multiplicação, 10=divisão, 11=módulo. **Formato estendido Nestor80** adiciona
  16-26: `SHR SHL EQ NE LT LE GT GE AND OR XOR`.
- **`42h` Referência a símbolo externo** — `42h` + 1-6 bytes ASCII do nome (formato legado; estendido
  permite mais, ver abaixo).
- **`43h` Valor** — 4 bytes: `43h` + segmento (`00`=absoluto,`01`=código,`10`=dados,`11`=COMMON) + byte
  baixo + byte alto.

Exemplo (`RFF`): `LD A,3+(NOT FOO##)` vira, em RPN: Valor(absoluto 3), RefExterna(FOO),
Operador(NOT), Operador(Soma), Operador(ArmazenarComoByte).

## Formato estendido Nestor80 vs. legado `--link-80-compatibility`

Por padrão o Nestor80 gera um formato **estendido**; `--link-80-compatibility` (equivalente ao que o
port nativo deve reproduzir se quiser interoperar com ferramentas antigas de verdade, mas **não** é
obrigatório pro port — Linkstor80/LK80 nativo só precisa entender o próprio formato que o Z80Asm nativo
gera) força o formato legado. Diferenças do estendido:

1. **Cabeçalho fixo de 16 bytes** no início de cada "programa" (um arquivo `.REL` pode ter vários
   programas concatenados, ver "Bibliotecas" abaixo): `85 D3 13 92 D4 D5 13 D4 A5 00 00 13 8F FF F0 9E`
   — essa sequência é, ela mesma, a codificação bit-stream de `ProgramName "LNKSTOR"` + `DataSegSize 0`
   + `EndOfProgram FFFFh` + `EndOfFile`, escolhida de propósito pra que um LINK-80 antigo que tente ler
   isso veja um programa vazio/inofensivo em vez de dar erro.
2. **Campo de símbolo estendido** (tamanho maior que 255 bytes): campo normal é 2-5 bytes de tamanho +
   os bytes; se o primeiro byte de conteúdo é `FFh`, é reinterpretado como `FFh` + 1-4 bytes de tamanho
   (little-endian, mínimo de bytes necessário) [+ bits de alinhamento de byte se tamanho ≥ 256] + os
   bytes de verdade. Só ativa quando tamanho ≥ 8, ou tamanho 2-7 com primeiro byte `FFh` (um `FFh`
   sozinho continua sendo o formato antigo).
3. **Símbolos UTF-8** (não só ASCII de 7 bits), mas comparados sem diferenciar maiúsculo/minúsculo.
4. **11 códigos de operador aritmético a mais** (16-26, listados acima).

**Recomendação pro port nativo**: gerar e ler **só o formato estendido** (mais simples de implementar
corretamente, já que os limites de tamanho legado — 6 caracteres de símbolo, campo de tamanho pequeno —
não importam pra um par assembler/linker que só precisa se entender). O modo `--link-80-compatibility`
fica documentado aqui mas não precisa ser implementado nesta fase — só relevante se algum dia for
preciso interoperar com um LINK-80/MACRO-80 de verdade rodando fora deste projeto.

## Bibliotecas — concatenação de programas

Um arquivo de biblioteca `.LIB` (gerenciado pelo Libstor80/LB80) é simplesmente **vários "programas"
`.REL` concatenados**, cada um terminando com o item "Fim de programa" (tipo 14), que força alinhamento
de byte — é exatamente esse alinhamento forçado que permite concatenar programas sem precisar
reanalisar tudo pra achar onde um termina e o outro começa. No formato estendido, o cabeçalho fixo de
16 bytes aparece **por programa**, não uma vez só no início do arquivo.

## `WritingRelocatableCode.md` — modelo do programador

- **Segmentos**: `ASEG` (absoluto, ignora relocação — endereço fixo de verdade), `CSEG` (código),
  `DSEG` (dados), e blocos `COMMON` nomeados. Um segmento fica "ativo" por vez (`CSEG` no início por
  padrão); `ASEG`/`CSEG`/`DSEG`/`COMMON nome` trocam qual está ativo. No momento de linkar, todo `CSEG`
  de todos os módulos é concatenado, o mesmo pra `DSEG`, e cada bloco `COMMON` (por nome) é
  compartilhado entre programas.
- **`PUBLIC simbolo`** expõe o valor (relativo ou absoluto) do símbolo pra outros módulos; `EXTRN
  simbolo` declara uma referência externa a resolver pelo linker. O linker casa `PUBLIC` de um módulo
  contra `EXTRN` de outro pelo nome.
- **Sufixo `##`**: `FOO##` numa expressão é atalho pra declarar `EXTRN FOO` e usar `FOO` — já
  reconhecido sintaticamente desde a Fase A (`docs/reference/nestor80-language.md`), sem efeito
  completo até este módulo existir.
- **Endereçamento relativo**: dentro de um `.REL`, endereços em CSEG/DSEG/COMMON são guardados
  **relativos ao início daquele segmento** (0 = primeiro byte do CSEG do módulo, por exemplo) — o
  linker soma o endereço-base final de cada segmento (calculado na hora de linkar, não fixo) a cada
  referência relocável.
- **Blocos COMMON**: a primeira aparição de um bloco com dado nome, entre todos os programas
  processados, fixa seu endereço (colocado logo antes do segmento de dados daquele programa);
  aparições seguintes do mesmo nome reusam esse endereço fixo (então conteúdo sobreposto exige `ORG`
  manual dentro do bloco). A primeira definição de um bloco COMMON precisa ser a **maior** — senão é
  erro.
- Endereço de código padrão se não especificado: **0103h** (convenção LINK-80/CP/M — deixa espaço pra
  um `JP` em 0100h, o ponto de entrada do CP/M).
- Bibliotecas (`.REQUEST`, construídas via Libstor80/LB80) são incluídas **por inteiro** quando
  qualquer um dos símbolos públicos delas é necessário — não há eliminação de código morto dentro de
  um programa de biblioteca (todo o programa entra, não só o símbolo pedido), mas programas da
  biblioteca que **nenhum** símbolo pendente referencia não entram — isso é exatamente a "linkagem
  estática seletiva" pedida pelo usuário (ver `docs/resumo-asm.md`, item 4 das decisões de escopo).

## `ParseRel` (não usar como referência)

O clone do Nestor80 tem uma pasta `ParseRel/` (dumper de `.REL` humano-legível) mas ela está **quebrada
neste checkout** — depende de `../Shared/BitStreamReader.cs`/`RelFileParser.cs` que não existem no
repositório, e não está referenciada em `Nestor80.sln`. Não perder tempo tentando compilar/usar. A
lógica equivalente, funcional e mantida de verdade, mora em `Linker/Parsing/RelocatableFileParser.cs`
(usada pelo próprio LK80) — é essa que serve de referência de implementação, junto com o algoritmo do
linker documentado em `docs/reference/nestor80-linker.md`.
