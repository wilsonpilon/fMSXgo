# Referência: módulo clássico MSX (badig_msx.py + tools_msx.py)

> Complementa `docs/reference/dignified-core.md`. Este arquivo documenta a parte do código
> **específica do dialeto MSX-BASIC clássico** — o que teria que ser reimplementado/adaptado se um
> dia se quisesse suportar outro sistema, mas que aqui pode ser tratado como parte fixa do port
> (esta IDE é MSX-only).

## Gramática clássica (`badig_msx.py:1-225`, classe `Description`)

Listas completas de vocabulário reservado (usar como fonte única da verdade — evita ter que
re-levantar isso do zero; comparar com a tabela `TOKENS` de `msxbatoken.py` documentada em
`docs/SPEC.md` módulo 11, que é o mesmo vocabulário visto do lado do tokenizador):

- `c_instrc` (linha 27): instruções — inclui `?` como alias de `PRINT` e `DEFUSR(\d)?` (regex,
  `DEFUSR0`..`DEFUSR9`) como caso especial.
- `c_funcdl` (linha 41): funções que terminam em `$` (`ATTR$ BIN$ CHR$ DSKO$ HEX$ INKEY$ INPUT$
  LEFT$ MID$ MKD$ MKI$ MKS$ OCT$ RIGHT$ SPACE$ SPRITE$ STR$ STRING$`).
- `c_funcnm` (linha 47): funções normais, incluindo `USR(\d)?` (regex, `USR0`..`USR9` — relevante
  para o módulo NestorBASIC do `docs/SPEC.md`, que usa exatamente `USR`/`USR0`).
- `c_jumpin` (linha 55): instruções de desvio (`RESTORE AUTO RENUM DELETE RESUME ERL ELSE RUN LIST
  LLIST GOTO RETURN THEN GOSUB`) — mesma lista que `JUMPS` em `msxbatoken.py`, confirmando
  consistência entre os dois componentes originais.
- `c_operat` (linha 59): `AND MOD NOT OR XOR`.
- `c_symbol` (linha 62): símbolos de operador/pontuação.
- **Tabelas de tradução Unicode→ASCII MSX** (linha 66-85): `c_replacements` (31 símbolos gráficos tipo
  CP437 — carinhas/naipes de baralho/linhas de caixa, código `1-31` do MSX) e o par `c_original`/
  `c_translat` (mapeamento posicional completo dos 128 caracteres pra faixa alta `0x80-0xFF` da ASCII
  MSX — é a tabela citada em `BASIC_DIGNIFIED.md` seção *"Classic Basic ASCII characters"*, 159
  caracteres suportados no total). Usada por `trans_char()` (linha 560) via `str.maketrans`.
  **Para o port**: essa é uma tabela de dados pura, portável 1:1 para um array/tabela em PureBasic — mas
  **atenção ao valor de `c_replacements`, não só a chave**: cada entrada NÃO mapeia pra uma letra pura
  (ex. `☺`→`A`) como pareceria numa leitura rápida do dict — o valor real é `'\x01A'` (`Chr(1)` +
  letra), confirmado byte a byte (o `\x01` é um caractere de controle invisível, some ao ler o arquivo
  num visualizador de texto normal, só aparece inspecionando os bytes crus). `Chr(1)` é o prefixo de
  escape que o driver de tela do MSX usa pra imprimir um dos 31 gráficos especiais sem colidir com os
  códigos de controle de verdade (posicionar cursor etc.) que ocupam a mesma faixa `1-31` — a letra que
  segue seleciona qual dos 31. **Isso já mordeu o port uma vez** (2026-08-04): a primeira versão de
  `Dig_TransReplacement`/`DignifiedPreprocessor.pbi` só copiou a letra, sem o `Chr(1)`, fazendo `-tr`
  gerar `"A"` em vez do gráfico de verdade pra esses 31 caracteres — corrigido comparando a saída real
  do `badig.py` de referência (presente no repo em `basic-dignified/`) byte a byte, não só lendo o
  código-fonte. Ver `docs/SPEC.md`, módulo 3h, item 3, para o detalhe completo da correção.

## Variáveis: nomes longos → curtos (`process_variable`, linha 516)

Algoritmo de atribuição confirmado por leitura direta (não só pela doc):
- `var_index` começa em `c_var_max = 676` (26×26) e **decresce**.
- Para cada novo nome longo, decompõe `var_index` em base 26 (`idx_h = var_index // 26`,
  `idx_l = var_index % 26`) e monta `c_var_chr[idx_h] + c_var_chr[idx_l]` (duas letras `a`-`z`).
  Como começa em 675 e decresce, a primeira variável atribuída é `ZZ`, depois `ZY`, `ZX`, ... até
  `AB`, `AA` — exatamente "descending order from ZZ to AA" como documentado.
- Pula qualquer combinação já usada como **hardcoded** (`c_hard_short_vars`), já **reservada**
  (`c_hard_long_vars`, primeiros 2 chars) ou já **declarada** (`d_declares`) — daí nunca sobrepor
  variável escrita explicitamente pelo usuário.
- Nomes curtos (≤2 chars, `c_var_valid_chars=2`) e variáveis marcadas com `~` (mantidas longas,
  `get_hard_variable`, linha 463) **não** passam por essa substituição.
- Erro se estourar as 676 combinações (`Info.log(1, 'Too many variables used...')`).

**Para o port**: um contador decrescente + tabela hash (nome longo → curto) é trivial em
PureBasic com `NewMap`; não há nada aqui que dependa de recursos exclusivos do Python.

## `[?](x,y)` — define embutido de LOCATE+PRINT (`initialization`, linha 448)

Confirma exatamente a lógica documentada em `BASIC_DIGNIFIED.md`: no `initialization()` do parser
clássico, o define `?` é **pré-registrado** no dicionário `d_defines` como se o usuário tivesse
escrito `define [?][locate VAR:?]` com variável default `0,0`. Ou seja, **não há lógica especial**
de parsing para `[?](x,y)` — é só um define comum que por acaso expande para `LOCATE x,y:PRINT`.
Isso é elegante e vale preservar no port: implementar `[?]` como um define pré-carregado, não como
caso especial no parser.

## Passes específicas do módulo clássico (`badig_msx.py:569-697`)

Ganchos chamados pelo núcleo genérico em cada pass (`self.clc.pass_N()` em `badig.py`):

- **Pass 1** (linha 570): decide se `_`/`:` no meio de uma linha é separador Dignified ou deve
  virar token de `CALL` implícito (`C_CALINS`) — mecanismo do MSX-BASIC onde `_identificador` no
  início de uma expressão é uma chamada de sub-rotina de máquina.
- **Pass 3** (linha 596): coleta variáveis hardcoded (`get_hard_variable`).
- **Pass 4** (linha 606): aplica a substituição de nome longo→curto (`process_variable`).
- **Pass 5** (linha 617): aqui mora a maior parte da lógica específica —
  - `?`↔`PRINT` conforme `-cp`.
  - Strip de `THEN GOTO` ou `GOTO` após `THEN`/`ELSE` conforme `-tg`.
  - Operadores compostos (`++ -- += -= *= /= ^=`, regex `c_e_symb` linha 93): reescreve para forma
    clássica (`x++` → `x=x+1`, `x+=n` → `x=x+n`).
  - `TRUE`/`FALSE` → `-1`/`0`.
  - Tradução Unicode se `-tr` ativo.
- **Generate** (linha 685): separa `X` de `OR` adjacente (evita `XOR` acidental) e separa números
  hex de letras `A`-`F` adjacentes — mesmas regras citadas em `DIFFERENCES.md` seção "Cleanups".

## `tools_msx.py` — ordem de execução das ferramentas

Arquivo trivial (30 linhas) mas define uma ordem importante: `Interface.run()` chama **primeiro**
`tokenizer_interface.Run.run()`, e só depois `emulator_interface.Run.run()`. Se a tokenização
gerou um `.bmx` (`os.path.isfile(runt.stg.file_bin)`), o caminho do arquivo a rodar no emulador é
**trocado** para o binário tokenizado antes de invocar o emulador — ou seja, o emulador prioriza
carregar o `.bmx` sobre o `.amx` (ASCII) quando ambos existem. Preservar essa ordem no port
(tokenizar antes de decidir o que mandar pro openMSX).

## Referência cruzada

- Tabela de tokens/algoritmo de tokenização binária: ver `docs/SPEC.md` módulo 11 e
  `badig/msx/msxbatoken/msxbatoken.py`.
- Protocolo real de controle do openMSX (comandos XML efetivamente enviados, não só a ideia
  conceitual do chat original): ver `docs/reference/badig-emulator-tokenizer-interfaces.md`.
