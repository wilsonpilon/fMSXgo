# Referência: algoritmo do linker (Linkstor80/LK80) — Fase B do assembler Z80

> Documentação técnica extraída do código-fonte C# do próprio Nestor80 (`nestor80/Linker/*.cs`,
> `nestor80/LK80/Program*.cs`), já que `LanguageReference.md`/os `.md` de doc não descrevem o
> algoritmo do linker em si (só o formato de arquivo, ver `nestor80-rel-format.md`). Serve de
> especificação ao `editor/Z80Link.pbi` nativo (**módulo 2b** do `docs/SPEC.md`). `LK80.exe`
> (compilado localmente a partir do clone `nestor80/`, mesma receita do `N80.exe` — ver
> `docs/resumo-asm.md`) é o **oráculo de teste** pra validar a saída do linker nativo byte a byte.

## Visão geral

Classe central: `Konamiman.Nestor80.Linker.RelocatableFilesProcessor` (estático). Entrada:
`Link(LinkingConfiguration configuration, Stream outputStream)`. Não há "passes" no sentido do
assembler — o linker processa os arquivos `.REL` **na ordem dada**, mantendo um mapa de memória de
64KB (`resultingMemory`, pré-preenchido com o byte de preenchimento configurado) que vai sendo escrito
conforme cada programa é processado.

## Parsing do `.REL`

`Linker/Parsing/RelocatableFileParser.cs`: `Parse(Stream) → ParsedProgram[]`. Um leitor de bit-stream
(`Linker/Infrastructure/BitStreamReader.cs`) transforma o arquivo numa sequência de "partes"
(`RawBytes`, `RelocatableAddress`, `LinkItem`, `ExtendedRelocatableFileHeader`), agrupadas por
programa (cortando a cada item "Fim de programa", tipo 14 — ver `nestor80-rel-format.md`).

## Sequência de linkagem (argumentos de CLI, ordem importa)

O `LinkingConfiguration` recebe uma lista ordenada de `ILinkingSequenceItem` — a **ordem em que os
argumentos aparecem na linha de comando é significativa**, intercalando arquivos `.REL` com comandos de
posicionamento:

- `RelocatableFileReference` (caminho de um `.REL`) — processa o(s) programa(s) daquele arquivo.
- `SetCodeSegmentAddress`/`SetDataSegmentAddress` (`--code`/`--data`) — endereço-base pro **próximo**
  arquivo. `--data` também troca (irreversivelmente) pro modo "separar código e dados".
- `AlignCodeSegmentAddress`/`AlignDataSegmentAddress` (`--align-code`/`--align-data`) — arredonda o
  próximo endereço pra cima até múltiplo de N, relativo ao fim do programa anterior.
- `SetCodeBeforeDataMode`/`SetDataBeforeCodeMode` (`--code-before-data`/`--data-before-code`) — troca
  o modo de sequenciamento (default: dados antes de código); ignorado com aviso se já estiver no modo
  "separado" (`--data` já foi usado).

## Algoritmo por programa (`ProcessProgram`)

Pra cada programa (um arquivo `.REL` pode ter mais de um "programa" concatenado — bibliotecas):

1. Lê os itens que declaram tamanho (tipo 13 = tamanho do CSEG, tipo 10 = tamanho do DSEG, tipo 5 =
   tamanho de cada bloco COMMON) — sabe o tamanho de cada segmento **antes** de posicionar.
2. Pra cada bloco COMMON visto pela primeira vez, cria um registro (`CommonBlock`) — erro se uma
   aparição posterior do mesmo nome pedir um tamanho **maior** que a primeira (regra: primeira
   definição precisa ser a maior, ver `nestor80-rel-format.md`).
3. **Calcula o endereço-base deste programa**, conforme o modo de sequenciamento atual:
   - **Modo "separado"** (`--data` já usado): base do código = `--code` explícito ou
     fim-do-CSEG-do-programa-anterior + 1; base dos dados/COMMON = `--data` explícito ou
     fim-do-DSEG-do-programa-anterior + 1 (código e dados crescem em duas áreas de memória
     independentes).
   - **Código antes de dados**: uma única base (explícita ou fim-do-maior-segmento-anterior + 1) — CSEG
     começa ali, depois os blocos COMMON, depois o DSEG logo em seguida.
   - **Dados antes de código** (padrão): mesma base única, mas DSEG (+ COMMON) vem primeiro, CSEG
     depois.
4. Ajusta o `startAddress`/`endAddress` global da saída pra cobrir a faixa deste programa.
5. **Percorre os itens do programa em ordem**, mantendo um ponteiro "endereço atual" e o
   segmento/tipo-de-endereço corrente:
   - `RawBytes` → copiado direto pra `resultingMemory` na posição atual (com wraparound de 64K).
   - `RelocatableAddress` → convertido pelo endereço efetivo (ver "Cálculo de endereço efetivo" abaixo)
     e escrito como word little-endian.
   - Tipo 11 (trocar contador de localização) → troca segmento/endereço corrente conforme
     `ASEG`/`CSEG`/`DSEG`/`COMMON nome` do código-fonte original.
   - Tipo 7 (definir símbolo público) → calcula endereço efetivo, checa duplicata (nome de símbolo
     público repetido entre programas diferentes vira erro, coletado pra reportar todos de uma vez no
     final), adiciona ao mapa global `symbols`.
   - Tipo 6 (cadeia de externo) → registra `ExternalReference{Nome, Programa, EnderecoInicioDaCadeia}`
     numa lista `externalsPendingResolution` pra resolver depois (posições cujo endereço é 0/ASEG e só
     usadas dentro de uma expressão são ignoradas aqui).
   - Tipo 3 (`.REQUEST`) → resolve o caminho do arquivo de biblioteca pedido, faz o parse, guarda os
     símbolos públicos dele numa lista `requestedLibFiles` — **não linka ainda**, só registra
     candidato (ver "Resolução de biblioteca" abaixo).
   - Tipos 9/8 (externo mais/menos deslocamento) → guarda um deslocamento com sinal a aplicar quando o
     externo for resolvido (`offsetsForExternals`).
   - Tipo 4 (item de extensão) → junta a sequência contígua de itens de extensão numa expressão RPN
     (`Expression`), enfileirada em `expressionsPendingEvaluation` pra avaliar depois que os símbolos
     que ela referencia já estiverem todos resolvidos.
   - Tipo 1 (selecionar bloco COMMON) → troca o "bloco COMMON atual" pros itens de endereço seguintes.
6. Monta um `ProgramInfo` com a faixa final de cada segmento, cruza contra os programas já processados
   procurando **sobreposição de faixa de endereço** (qualquer overlap ASEG/CSEG/DSEG/COMMON entre dois
   programas é erro) e adiciona à lista `programInfos`.

**Cálculo de endereço efetivo** (`EffectiveAddressOf`): CSEG → base-do-código-do-programa-atual +
valor; DSEG → base-dos-dados-do-programa-atual + valor; COMMON → endereço-fixo-do-bloco + valor; ASEG →
valor sem alteração (já é absoluto).

## Depois de processar todos os itens da sequência

1. Calcula `unknownExternals` = externos em `externalsPendingResolution` que ainda não estão no mapa
   global `symbols`, somado aos externos referenciados dentro de qualquer biblioteca **pedida mas ainda
   não carregada**.
2. **Resolução de biblioteca**: pra cada externo pendente, procura em `requestedLibFiles` uma
   biblioteca cujos símbolos públicos incluam esse nome (primeiro achado ganha), marca essa biblioteca
   como `MustLoad = #True` — uma vez que um "programa" inteiro da biblioteca é puxado por resolver um
   símbolo, **todo o conteúdo dele entra**, sem eliminação de código morto dentro dele (mas programas
   da mesma biblioteca que nenhum externo pendente referencia nunca entram — essa é a "linkagem
   estática seletiva" que o usuário pediu, ver `docs/resumo-asm.md`).
3. `ProcessProgram` roda de novo pra cada biblioteca marcada `MustLoad`, integrando exatamente como um
   programa normal de entrada (posicionado depois de tudo, conforme o modo de sequenciamento atual).
4. **Resolve as cadeias de externo**: pra cada `ExternalReference` ainda pendente, erro "não consegue
   resolver referência a símbolo externo" se continuar sem dono; senão percorre a lista encadeada de
   posições-a-corrigir (cada uma guarda o endereço da "próxima" posição, terminada por um byte absoluto
   `0`, limite de segurança de 32768 iterações), escrevendo o valor resolvido (+ deslocamento
   registrado, se houver) em cada posição de `resultingMemory`.
5. **Avalia as expressões pendentes**: `Expression.Symbols = symbols` (mapa global já completo), cada
   expressão enfileirada roda sua máquina de pilha RPN (aritmética + busca de externo) e escreve o
   resultado (1 ou 2 bytes) em `resultingMemory` na posição-alvo gravada.
6. Reporta como erro qualquer nome de símbolo público duplicado coletado no passo 5 do algoritmo por
   programa.

## Saída

Se formato binário: escreve `resultingMemory[startAddress..endAddress]` direto no stream de saída. Se
Intel HEX (`--output-format hex`): registros padrão `:LLAAAATT[DD...]CC` em blocos de 32 bytes com
checksum calculado — **fora de escopo desta fase** (ver `docs/resumo-asm.md`, backlog Fase C
"saída Intel HEX"); o port nativo do linker foca só em saída binária primeiro.

## Superfície de linha de comando do LK80 (mínimo viável pro port nativo)

Fontes de argumento combinadas em ordem (`LK80_ARGS` env var → linha de comando → `--args-file`) — o
port nativo não precisa replicar essa cascata, só aceitar os argumentos relevantes direto na linha de
comando. Mínimo pra cobrir o pedido do usuário (gerar biblioteca, linkar seletivamente pro `.COM`):

- Lista ordenada de arquivos `.REL` (posicionais), intercalada com `--code`/`--data`/
  `--code-before-data`/`--data-before-code`/`--align-code`/`--align-data`.
- `--output-file`, `--output-format bin` (só binário nesta fase).
- `--start`/`--end`/`--fill` — força faixa mínima/máxima de saída e byte de preenchimento de lacuna
  (default 0).
- `--library-dir`/`--working-dir` — pasta de busca pros arquivos de `.REQUEST`.
- `--max-errors` — aborta depois de N erros.

Sem prioridade nesta fase (conveniência/paridade, não essencial): saída em Intel HEX, arquivo de
símbolos exportado (`--symbols-file`), cores/banner, `LK80_ARGS`/arquivo de argumentos, filtro por
regex de símbolo.

## Endereço de entrada padrão

**0103h** — mesma convenção CP/M do LINK-80 original (documentada também em
`nestor80-rel-format.md`), usada como base de código quando nenhum `--code` é passado explicitamente.
