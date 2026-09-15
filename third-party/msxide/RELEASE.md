# msxIDE v0.5.0 — "MAMUTE.MAP"

*2026-09-11*

O nome é um trocadilho duplo: `.MAP` é o arquivo clássico que relaciona símbolo com endereço num
compilador/linker de verdade — exatamente o que a nova tabela nome-longo→nome-curto do Basic Dignified
faz — e também é o nome do aplicativo Character Map do Windows, a inspiração direta da nova grade de
caracteres especiais MSX.

## Tema da versão

O Basic Dignified fica bem mais fiel à especificação, e o editor de texto ganha ergonomia de verdade:

1. **Variáveis de nome longo → curto** — a funcionalidade mais complexa do dialeto, documentada há tempos
   mas 100% ausente do compilador nativo até esta versão.
2. **Caracteres especiais MSX** — uma grade de inserção pros acentos/gráficos e símbolos especiais do
   conjunto MSX, direto do editor.
3. Um conjunto de acertos pontuais no Basic Dignified (`Strip Spaces`, continuidade de linha com `:`) e
   no editor (`Tab` configurável, atalhos de recortar/copiar/colar clássicos do MS-DOS).

## Novidades

### Variáveis de nome longo → curto (Basic Dignified)

- Nomes com **3 ou mais letras/números/underscore** (case-insensitive, não pode começar com número nem
  ser só número) são automaticamente trocados por um par de letras. Atribuídos em ordem **descendente de
  `ZZ` até `AA`** — nunca uma letra só, nunca letra+número. O mesmo nome longo sempre vira o mesmo curto
  **independente do sufixo de tipo**: `variable1` e `variable1$` viram `zz` e `zz$`.
- **`DECLARE nome:curto`** força um mapeamento explícito na mão. Vários numa linha só, separados por
  vírgula: `declare comida:cd, bebida:bb`.
- **`DECLARE nome1,nome2`** reserva sem mapear — um nome curto (1-2 letras) fica indisponível pro
  auto-assign; um nome de 3+ letras nunca é encurtado em lugar nenhum do arquivo.
- **`~nome`** mantém o nome por extenso em **todas** as ocorrências do arquivo, não só na marcada com
  `~` — o `~` em si nunca aparece na saída.
- Variáveis de **1-2 letras usadas direto** no código nunca são tocadas, e reservam automaticamente esse
  par de letras (o auto-assign nunca gera um curto que colidiria com uma delas).
- Um tokenizer novo varre cada linha reconhecendo identificadores, mas **nunca entra dentro de string
  literal** nem **depois de `REM`/`'`/`DATA`** — sem isso, um comentário em português qualquer viraria
  sopa de variáveis trocadas.
- Cada arquivo (namespace de `INCLUDE`) tem sua própria tabela de nomes — o mesmo nome longo pode virar
  um curto diferente em cada include, exatamente como a documentação sempre descreveu.

### `Inserir -> Caracteres Especiais MSX`

- Novo item na barra de menus (`Alt+I`, depois `C`) abre uma grade navegável por setas com os caracteres
  especiais do conjunto MSX — o mesmo conjunto que o "Translate" do Basic Dignified Suite reconhece
  (`badig_msx.py`, `Parser.trans_char`).
- **Acentos e gráficos (códigos 128-255)**: o byte escolhido é inserido direto no cursor e sai idêntico
  no `.amx` gerado — sem nenhuma tradução do lado do compilador, porque o pipeline inteiro (editor,
  arquivo em disco, `PreprocessDignified`) já é byte a byte, nunca passa por UTF-8.
- **Símbolos especiais (`CHR$(1)` a `CHR$(31)`** — carinha, naipes, blocos): esses códigos baixos não são
  imprimíveis de forma confiável via `PRINT`/string literal no MSX BASIC clássico, então a grade insere a
  **letra equivalente** (`A`-`Z`, `[`, `]`, `\`, `^`, `_`) em vez do byte cru — o mesmo fallback de
  segurança que o Basic Dignified Suite usa.
- `Enter` insere sem fechar o diálogo (dá pra inserir vários caracteres seguidos), `Esc` fecha.

### Editor de texto

- **`Tab` configurável**: insere a quantidade de espaços definida em `Configurar -> Editor -> Indent
  Size` (padrão 4, novo item no menu Configurar) em vez de não fazer nada.
- **`Shift+Delete`/`Shift+Insert`/`Ctrl+Insert`**: o trio clássico de recortar/colar/copiar dos editores
  MS-DOS de antes do `Ctrl+X`/`Ctrl+V`/`Ctrl+C` (QEdit, Norton Editor, Brief...) — mapeados pro mesmo
  código interno dos atalhos modernos.
- **`Alt+C` agora abre Compilar e `Alt+O` abre Configurar** (antes `Alt+P` e `Alt+C`, respectivamente).

### Basic Dignified: continuidade de linha com `:`

- Recurso já documentado (`BASIC_DIGNIFIED.md`, "Line separation") mas nunca implementado — uma linha
  terminada em `:` agora se junta com a próxima (e uma linha começada em `:` se junta com a anterior)
  antes de virar uma linha numerada. `SCREEN 0:` seguido de `WIDTH 40` vira `10 SCREEN 0:WIDTH 40`, uma
  linha só, em vez de duas.

## Corrigido

- **`Strip Spaces` só colapsava espaços duplicados**, nunca removia de fato — agora remove *todos* os
  espaços fora de string literal (inclusive colados no `:`), como a própria documentação sempre disse
  ("all non essential spaces from the code can be removed").
- **Ordem do pipeline de formatação do Basic Dignified**: `Strip Spaces` rodava *antes* da conversão de
  `PRINT`/`?` e `THEN`/`GOTO` (que dependem de espaço ao redor da palavra-chave pra reconhecê-la com
  segurança) — com as duas opções ligadas ao mesmo tempo, o strip quebrava silenciosamente as outras
  duas. Ordem agora é Convert PRINT → Strip THEN GOTO → Strip Spaces → Capitalize.

## Bastidores

- Todo o trabalho novo foi verificado com testes headless novos e expandidos: `--smoke-badig` ganhou um
  cenário dedicado à conversão de variáveis (auto-atribuição descendente, independência de tipo, string
  literal e `REM`/`DATA` protegidos da varredura, `declare` explícito e de reserva, `~` consistente em
  todas as ocorrências, variável curta usada direto nunca é tocada) e outro pra continuidade de linha
  por `:`; `--smoke-editor` ganhou cobertura pro `Tab` configurável, pro item novo do menu Configurar e
  pro menu Inserir; `--smoke-keys` ganhou os atalhos clássicos de recortar/copiar/colar.
- Simplificação assumida na conversão de variáveis: o sistema de avisos/erros de conflito do Basic
  Dignified original (declaração duplicada, curto já usado por outra variável, etc.) não foi portado —
  são heurísticas de QA que não afetam a correção do programa gerado. O relatório de variáveis
  (`cfg.badig.var_report`) também não foi implementado nesta versão.

## Créditos

Ver a seção "Agradecimentos" em [README.md](README.md#agradecimentos).
