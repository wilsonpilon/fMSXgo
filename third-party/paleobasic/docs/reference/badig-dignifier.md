# Referência: MSX Basic DignifieR (msxbader.py)

> Conversor **clássico ASCII → Dignified** (sentido inverso do pré-processador principal). Uso
> completo de todas as opções já está documentado em `badig/documentation/DIGNIFIER.md` — este
> arquivo cobre só a arquitetura interna, para o port nativo.

## Diferença de abordagem em relação ao motor principal

Ao contrário de `badig.py` (lexer de tokens + parser multi-pass sobre lista de tokens),
`msxbader.py` é **orientado a linha**: processa o arquivo clássico linha a linha, sem lexer
formal — usa regex diretamente em `do_lines()` (linha 337-588, a função mais longa do arquivo).

Fluxo (`dignify()`, linha 589):
1. Para cada linha do BASIC clássico: extrai o número de linha (regex `match_elements`), valida
   ordem crescente (erro `Line_number_out_of_order` se não crescente — igual ao tokenizador).
2. `do_lines(lnumber, line)` (linha 337) converte o conteúdo da linha e retorna:
   - `dig_list`: lista de **sub-linhas** Dignified (uma linha clássica pode virar várias linhas
     Dignified formatadas, ex. quando quebra em `THEN`/`:`).
   - `branch_l`: labels que essa linha referencia (para `check_labels` depois).
   - `rem_line`: se a linha era um REM isolado (tratamento especial de formatação).
3. Numeração fracionária: cada sub-linha gerada recebe chave `lnumber + n/100` em
   `dignified_dict` — truque para manter a ordem original **sem** precisar renumerar tudo a cada
   split, e permite que `assemble_dignified()` (linha 310) monte o arquivo final ordenando pelas
   chaves fracionárias.
4. `check_labels()` (linha 296): valida que todo label referenciado em `branch_l` existe de fato
   como linha de destino.

## Opções de formatação (regras, não algoritmo)

Todas as opções (`-fl` formato de label, `-fr` formato de REM, `-ut` unravel THEN/ELSE, `-uc`
unravel colons, e as regexes de espaçamento `-rb/-ra/-jb/-ja/-sb/-sa/-ft`) já estão descritas com
exatidão em `DIGNIFIER.md` — a leitura do código confirma que são exatamente isso: **conjuntos de
regex configuráveis** aplicados linha a linha, sem lógica extra escondida. Não há necessidade de
reler `do_lines()` linha a linha para o port; a doc humana já é a especificação.

## Prioridade para o port

O `docs/SPEC.md` já lista o `msxbas2rom`/DignifieR como funcionalidades de prioridade baixa/média.
O DignifieR especificamente **não** foi mencionado como prioridade no scope fechado com o usuário
(módulos 1-12 do SPEC) — ele é uma ferramenta de conveniência para migrar código clássico
existente, útil mas não bloqueante. Recomendação: portar depois do pré-processador principal
(Dignified → clássico) e do editor estarem sólidos, não antes.
