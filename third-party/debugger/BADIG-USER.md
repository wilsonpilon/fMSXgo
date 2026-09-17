# BASIC Dignified — Guia do Usuário (módulo MSX)

> Este documento explica como **escrever seus programas** usando a sintaxe "Dignified" dentro da IDE. É uma adaptação, para o nosso projeto em PureBasic, da documentação original do [Basic Dignified](https://github.com/farique1/basic-dignified) de farique1 — mantendo apenas a parte relevante ao **MSX** (o projeto original também suporta CoCo, que não usamos aqui).
>
> Diferente do projeto original (rodado via `python badig.py` no terminal), aqui a conversão, tokenização, execução e depuração acontecem **dentro da própria IDE** — pelos menus, atalhos e painel de configurações do projeto, sem linha de comando.

---

## O que é

**Basic Dignified** é uma forma de escrever MSX BASIC com uma sintaxe mais moderna — sem números de linha, com blocos indentados, rótulos nomeados, funções, variáveis com nomes longos, etc. A IDE lê esse código-fonte ("Dignified") e gera o **BASIC clássico** de volta, em dois formatos possíveis: **ASCII** (texto puro) ou **tokenizado/binário** (pronto para carregar rápido no MSX).

Você escreve no estilo Dignified; a IDE converte para o MSX BASIC de verdade na hora de rodar, tokenizar ou exportar.

### Extensões de arquivo usadas no projeto

| Extensão | Tipo |
|---|---|
| `.dmx` | Código-fonte **Dignified** (o que você escreve) |
| `.amx` | BASIC clássico em **ASCII** (texto) |
| `.bmx` | BASIC clássico **tokenizado/binário** |
| `.lmx` | Formato de **listagem** exportado pelo tokenizador |

> Essas extensões evitam conflito com outros módulos/linguagens que a IDE possa vir a suportar no futuro.

---

## Regras gerais de escrita

- Instruções, funções e variáveis devem ser **separadas por espaços** de caracteres alfanuméricos, como em linguagens modernas (diferente do BASIC clássico, que aceita tudo colado). O destaque de sintaxe do editor reflete isso.
- O código Dignified deve sempre **terminar com uma linha em branco**.
- **Indentação** é incentivada para legibilidade — pode ser feita com TABs ou espaços (espaços são recomendados). Se usar TABs, configure o tamanho do TAB nas opções do projeto, para que os relatórios de erro apontem a coluna certa.
- Linhas em branco são **removidas** na conversão, exceto as que estão dentro de um **comentário de bloco** (`''`). Espaços no início/fim de cada linha também são removidos.
- Alguns BASICs clássicos se confundem com certas concatenações de caracteres — a IDE separa automaticamente casos como `x` e `or` (para não virar `xor` sem querer) e números **hexadecimais** seguidos de palavras começando com `a` a `f`.
- Símbolos `:` duplicados (separador de instrução) são removidos automaticamente.

---

## Estrutura da linguagem

### Rótulos (Labels)

Direcionam o fluxo do código, já que o Dignified não usa números de linha.

- Criados com chaves: `{assim}`.
- Podem ficar **sozinhos** numa linha (recebendo o fluxo) ou dentro de uma instrução de desvio (`goto {assim}`, `gosub {assim}`), direcionando o fluxo para a linha correspondente.
- Só podem ter **letras, números e underscore**; não podem ser só números nem começar com número.
- `{@}` é um rótulo especial que aponta para a **própria linha**.
- **Rótulo de loop**: abre com `nome{` e fecha com `}`, criando um laço fechado conciso. O rótulo de abertura funciona como um rótulo normal; o de fechamento manda o fluxo de volta para a abertura. Loops podem ser **aninhados**. Use `exit` para sair do loop e ir para a linha seguinte ao fechamento.

```
{start}
print "aperte A para alternar"
if inkey$ <> "A" then goto {@}
loop{
    a$ = inkey$
    print "aperte B para sair"
    if a$ = "A" then goto {start}
    if a$ = "B" then exit
}
end
```

Vira:

```
10 PRINT "aperte A para alternar"
20 IF INKEY$<>"A" THEN GOTO 20
30 A$=INKEY$
40 PRINT "aperte B para sair"
50 IF A$="A" THEN GOTO 10
60 IF A$="B" THEN GOTO 80
70 GOTO 30
80 END
```

> A IDE pode gerar um relatório visual do fluxo do programa (setas `<`/`>` comentadas em cada linha) e um resumo da correspondência entre linha Dignified e linha clássica — úteis na hora de depurar. Rótulos com nome inválido, duplicados, apontando para lugar inexistente, ou loops não fechados geram **erro** e interrompem a conversão (destacado no editor).

---

### Defines

Criam **aliases** no código, substituídos na hora da conversão.

- Sintaxe: `define [nome][conteudo]`. Vários na mesma linha, separados por vírgula: `define [nome1][conteudo1],[nome2][conteudo2]`.
- O nome só pode ter **letras, números e underscore**, não pode ser só número nem começar com número.
- Uma **define variável** pode ser criada com `[]` dentro do conteúdo — substituída por um argumento passado entre parênteses `()` ao usar o define. Se houver conteúdo dentro dos colchetes da define variável, ele vira o **valor padrão** quando nenhum argumento é passado.

A IDE já traz embutido o define `[?](x,y)`, que vira `LOCATE x,y:PRINT` (se não passar `(x,y)`, assume `0,0`).

```
define [ifa][if a$ = ],[enter][chr$(13)]
define [pause][if inkey$<>[" "] goto{@}]

[ifa]"1" then print "um"
[ifa]"2" then print "dois"
[?](10,10)"dez por dez"
[pause]([enter])
```

Vira:

```
10 IF A$="1" THEN PRINT "um"
20 IF A$="2" THEN PRINT "dois"
30 LOCATE 10,10:? "dez por dez"
40 IF INKEY$<>CHR$(13)GOTO 40
```

> Defines podem ser usados como variáveis de outros defines. Defines duplicados geram erro.

---

### Variáveis com nomes longos

- Só **letras, números e underscore**; não podem ser só números, começar com número ou ter menos de 3 caracteres. **Não fazem** distinção entre maiúsculas/minúsculas.
- Na conversão, cada nome longo vira uma variável curta de duas letras, atribuída em ordem **decrescente** de `ZZ` até `AA` (nunca usa letra única nem letra+número). O mesmo nome longo sempre gera a mesma letra curta, independente do tipo (`variavel` → `XX`, `variavel$` → `XX$`).
- Você pode **forçar** uma atribuição explícita com `declare`: `declare variavel:va` atribui `VA` a `variavel`. Vários numa linha: `declare v1:aa,v2:ab,v3:ac`.
- `declare` também serve para **reservar** nomes curtos, evitando que sejam usados automaticamente: `declare zz,xv,cd`. Variáveis de uma letra não precisam (e não podem) ser reservadas.
- Como a atribuição é por nome (não por tipo), caracteres de tipo (`$%!#`) não são usados num `declare`.
- Não declare como variável um comando reservado do BASIC — ele pode acabar sendo convertido.
- Variáveis de **uma ou duas letras** usadas diretamente **não são convertidas**.
- Um `~` antes do nome mantém o nome **longo** (útil porque alguns BASICs aceitam nomes longos, mas descartam tudo após o segundo caractere). Não use `~` num nome já curto.

```
declare comida:cm, bebida:bb
if comida$ = "bolo" and bebida = 3 then end
resultado$ = "barriga cheia"
~sono = 10
print resultado$
```

Vira:

```
10 IF CM$="bolo" AND BB=3 THEN END
20 ZZ$="barriga cheia"
30 SONO=10
40 PRINT ZZ$
```

> A IDE pode gerar um relatório com a associação nome longo ↔ nome curto, útil para depurar o código clássico gerado.

---

### Proto-funções

Emulam definição e chamada de função ao estilo moderno.

- Definidas com `func .nomeDaFuncao(arg1, arg2, etc)`, terminando em `ret`. O nome só pode ter letras, números e underscore; não pode ser só número nem começar com número.
- Argumentos podem ter **valor padrão**: `func .funcao(arg$="teste")`.
- `ret` pode devolver variáveis: `ret arg1, arg2`. `ret` deve começar a linha, mas pode ser "colado" à linha anterior com `:` (ver Separação de linha).
- Chamadas: `.nomeDaFuncao(arg1, arg2)`, podendo atribuir a variáveis: `v1, v2 = .nomeDaFuncao(args)`. Pode vir depois de `THEN`/`ELSE`: `if a=1 then .fazAlgo() else .naoFaz()`.
- Uma chamada pode usar **menos** argumentos/retornos que a definição (o excedente é ignorado), mas nunca **mais**.
- Só pode haver **um** `ret` por função (ele marca o fim da definição). Um `RETURN` normal pode ser usado para sair da função em outro ponto, mas sem devolver variáveis.
- Não há variáveis locais no BASIC clássico — simule usando nomes de variável exclusivos dentro da função.
- Como nos rótulos, o fluxo de proto-funções também aparece no relatório visual de fluxo. Diferente de uma função de verdade, a definição **não desvia** o fluxo sozinha — precisa ficar num ponto do código que não seja alcançado por acidente (ex: depois de um `end`).

```
letra$ = .maiuscula("a")
print letra$
end
func .maiuscula(mai$)
    ch = asc(mai$) - 32
ret chr$(ch)
```

Vira:

```
10 MAI$="a":GOSUB 40:ZZ$=CHR$(CH)
20 PRINT ZZ$
30 END
40 CH=ASC(MAI$)-32
50 RETURN
```

> Chamadas de função no MSX BASIC (`GOSUB`) são lentas, principalmente por precisarem varrer o código — evite abusar de proto-funções em loops críticos de performance. Colocá-las no início do código ajuda um pouco.

---

### Separação de linha

Permite quebrar uma instrução em várias linhas no editor, sendo unidas na conversão.

- `:` no **fim** de uma linha junta com a **próxima**; `:` no **início** junta com a **anterior**. É mantido no código convertido (mesma função de separador de instrução do BASIC clássico).
- `_` só funciona no **fim** da linha e é **removido** ao juntar. Útil para quebrar comandos como `IF THEN ELSE` que precisam formar um único comando na saída. Deve estar separado do último caractere (se for parte de palavra) e não funciona no fim de comentários ou aspas abertas.
- Aspas podem ser unidas simplesmente concatenando, mesmo em linhas diferentes: `PRINT "Olá " "mundo"`.
- `endif` pode ser usado para marcar visualmente o fim de um `IF` multi-linha, mas é só **cosmético** — é removido sem processamento. Prefira indentação (estilo Python) para delimitar blocos `IF`.

```
if a$ = "" then _
    for f = 1 to 10:
        [?](1,1) f:
    next
    :[?](1,3) "Tudo "
              "pronto."
    :end
endif
```

Vira:

```
10 IF A$="" THEN FOR F=1 TO 10:LOCATE 1,1:? F:NEXT:LOCATE 1,3:? "Tudo pronto.":END
```

---

### Comentários exclusivos

Comentários **removidos** na conversão — marcados com `##`. Comentários normais `REM` ou `'` são **mantidos**.

Também existem **comentários de bloco**: abertos/fechados com `''` (mantido) ou `###` (removido).

```
## isto será removido
rem isto vai ficar
' isto também vai ficar
###
Isto será removido
###
''
Isto vai ficar
''
```

Vira:

```
10 REM isto vai ficar
20 ' isto também vai ficar
30 'Isto vai ficar
```

---

### Toggles de linha (marcação para depuração)

Marcam trechos de código para serem **removidos sob demanda** na conversão — úteis para testar variações sem ficar comentando/descomentando manualmente.

- Formato: `#nome` (letras, números, underscore; não pode ser só número nem começar com número).
- Um trecho marcado é **mantido** se você colocar `keep #nome1 #nome2` **antes** dele numa linha própria. `keep` aceita nenhum, um ou vários nomes, separados por espaço.
- Dois toggles especiais: `#all` mantém tudo, `#none` remove tudo (se os dois forem usados, `#none` tem prioridade).
- Podem marcar uma **linha única** no início dela (`#a print "teste"`) ou um **bloco inteiro** (sozinhos no início e fim do bloco, como um comentário de bloco). Blocos podem ser **aninhados**, mas não podem se **sobrepor**.

```
keep #b
#a print "isto não será convertido"
#b print "isto será convertido"
print "isto também será convertido"
#c
print "Isto não será convertido"
print "Nem isto"
#c
```

Vira:

```
10 PRINT "isto será convertido"
20 PRINT "isto também será convertido"
```

---

### Caracteres ASCII especiais do MSX

O conjunto de caracteres especiais do MSX (acentos, semigráficos, símbolos) não é digitável diretamente em codificações modernas comuns. Salvando o arquivo `.dmx` em **UTF-8**, você pode usar caracteres unicode parecidos com os originais, e a IDE traduz para o código ASCII correspondente do MSX na conversão.

Conjunto suportado (caracteres MSX ASCII):

```
ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒáíóúñÑªº¿⌐¬½¼¡«»ÃãĨĩÕõŨũĲĳ¾∽◇‰¶§▂▚▆▔◾▇▎▞▊▕▉▨▧▼▲▶◀⧗⧓▘▗▝▖▒Δǂω█▄▌▐▀αβΓπΣσμτΦθΩδ∞φ∈∩≡±≥≤⌠⌡÷≈°∙‐√ⁿ²❚■☺☻♥♦♣♠·◘○◙♂♀♪♬☼┿┴┬┤├┼│─┌┐└┘╳╱╲╂
```

```
print "┌──────┐"
print "│SALVANDO│"
print "└──────┘"
```

Vira (com a opção de tradução ativada):

```
10 PRINT "�X�W�W�W�W�W�W�Y"
20 PRINT "�VSALVANDO�V"
30 PRINT "�Z�W�W�W�W�W�W�["
```

> A IDE inclui uma fonte TrueType que representa esses caracteres visualmente no editor, mapeando o conjunto do MSX.
>
> Ao salvar um programa BASIC como **ASCII** a partir do openMSX (`save"arquivo",a`), a codificação usada é `Western (Windows 1252)` — é essa mesma codificação que a IDE usa para gerar o `.amx`. Se você usa caracteres unicode especiais, salve o `.dmx` em **UTF-8**; a IDE ainda vai gerar o `.amx` corretamente em `Western (Windows 1252)`, com os caracteres especiais já traduzidos para o padrão MSX ASCII.

---

### Include

Insere um arquivo Dignified externo em qualquer ponto do código.

`include "codigo.dmx"` insere o conteúdo de `codigo.dmx` exatamente onde o `include` foi escrito, podendo até ter linhas unidas com o código principal usando `:` ou `_`.

- Arquivos incluídos têm **namespaces separados**: rótulos, funções, defines e toggles podem se repetir entre os arquivos sem conflito.
- Variáveis de **nome longo** recebem nomes curtos diferentes entre includes, mas não podem ter a mesma **declaração explícita** (`declare`) em arquivos diferentes. Variáveis reservadas também são independentes por arquivo.
- Como o BASIC clássico não tem namespaces de verdade, pode haver conflito entre variáveis **hardcoded** (nomes curtos usados diretamente) — a IDE avisa se isso acontecer.

`principal.dmx`:
```
print "Este é o arquivo principal."
'
include "ajuda.dmx"
'
print "De volta ao arquivo principal."
```

`ajuda.dmx`:
```
print "este é um código auxiliar."
print "Salvo em outro arquivo."
```

Vira:

```
10 PRINT "Este é o arquivo principal."
20 '
30 PRINT "este é um código auxiliar."
40 PRINT "Salvo em outro arquivo."
50 '
60 PRINT "De volta ao arquivo principal."
```

---

### Verdadeiro e falso

Podem ser usados com variáveis numéricas — convertidos para `-1` e `0` respectivamente, tratáveis como booleanos de verdade em `IF`s e com `NOT`.

```
var_bool = true
condicao = false
if condicao then var_bool = not var_bool
```

Vira:

```
10 ZZ=-1
20 ZY=0
30 IF ZY THEN ZZ=NOT ZZ
```

---

### Operadores abreviados e compostos

`++`, `--`, `+=`, `-=`, `*=`, `/=`, `^=` são convertidos para as operações equivalentes do BASIC clássico.

```
var1++ :var2--
var3 += 20 :var4 -= 10
```

Vira:

```
10 ZZ=ZZ+1:ZY=ZY-1
20 ZX=ZX+20:ZW=ZW-10
```

---

## Opções de conversão (configurações do projeto na IDE)

No projeto original, essas opções eram configuradas via `.ini`, argumentos de linha de comando ou remtags. Na nossa IDE, elas ficam disponíveis num **painel de configurações do projeto** (persistidas junto ao projeto) e também podem ser sobrescritas **por arquivo**, usando remtags no próprio código-fonte.

| Opção | O que faz | Padrão |
|---|---|---|
| Número da linha inicial | Linha do primeiro comando gerado no BASIC clássico | `10` |
| Incremento de linha | Passo entre números de linha gerados | `10` |
| Cabeçalho informativo | Adiciona comentário no topo do código gerado, citando a ferramenta | Ativado |
| Remover espaços | Remove espaços não essenciais ao redor de instruções/variáveis | Desativado |
| Maiúsculas em tudo | Converte todo texto não-literal para maiúsculo (necessário em alguns BASICs) | Desativado |
| Traduzir ASCII especial | Converte os caracteres unicode especiais para o padrão MSX ASCII | Desativado |
| `PRINT` ou `?` | Converte todos os `PRINT` para `?` ou vice-versa | Nenhum (mantém como escrito) |
| Remover `THEN`/`ELSE` ou `GOTO` adjacentes | Remove `THEN`/`GOTO` quando redundantes (alguns BASICs dispensam) | Nenhum |
| Carregar como BASIC clássico | Interpreta o arquivo carregado como BASIC clássico em vez de Dignified (útil para tokenizar/depurar código já pronto) | Desativado |
| Tamanho do TAB | Quantos espaços equivalem a um TAB, para o relatório de erro apontar a coluna certa | `4` |

### Relatórios de depuração

A IDE pode exibir (em painel próprio, sem precisar gerar arquivo externo):

- **Relatório de fluxo**: mostra, ao lado de cada linha gerada, para onde o fluxo vai (`>rotulo`) ou de onde vem (`<rotulo`); saída de loop marcada com `*`; auto-referência com `>@`.
- **Relatório de linhas**: mapeia cada linha do BASIC clássico gerado de volta à linha correspondente no seu código Dignified (essencial para localizar onde corrigir um erro que o emulador apontou numa linha numerada).
- **Relatório de variáveis**: lista a associação entre cada variável de nome longo e sua letra curta correspondente.
- **Relatório de tokens (lexer/parser)**: mostra os tokens gerados durante a análise do código — útil principalmente para depurar a própria ferramenta, não o seu programa.

### Remtags (diretivas dentro do código)

Remtags são comentários exclusivos especiais que alteram o comportamento da conversão **direto no arquivo `.dmx`**, sobrepondo as configurações do projeto. Úteis para deixar registrado, junto do próprio código, como aquele arquivo específico deve ser convertido.

```
##BB:export_file=
##BB:arguments=-prr -lbr -ca
##BB:help=True

cls
loop{
    print "Olá Mundo ";
}
```

- `export_file`: define um caminho/nome de arquivo alternativo para a saída — útil para testar variações sem sobrescrever a versão anterior. Se vazio, é ignorado e o nome/caminho padrão é usado.
- `arguments`: permite usar as mesmas opções da configuração do projeto direto no código-fonte (equivalente ao que era passado por linha de comando no projeto original).
- `help`: lista todos os remtags disponíveis, incluindo os que módulos futuros (assembly Z80, editores visuais etc.) possam expor.

> Para **desativar** um remtag sem apagá-lo, basta adicionar um espaço entre `##` e `BB` — ele vira um comentário exclusivo comum, sem efeito.

---

## Resumo rápido

| Você escreve | Vira no MSX BASIC |
|---|---|
| `{rotulo}` | linha numerada de destino de `GOTO`/`GOSUB` |
| `nome{ ... }` | laço fechado com `GOTO` de volta ao início |
| `define [x][y]` | substituição de texto na conversão |
| `variavel_longa` | `AA`, `AB`, ... `ZZ` (curta, automática) |
| `func .nome(...) ... ret` | rotina em `GOSUB`/`RETURN` |
| `:` fim/início de linha | junta linhas, mantendo o `:` |
| `_` fim de linha | junta linhas, removendo o `_` |
| `## comentário` | removido na conversão |
| `#tag` / `keep #tag` | remove/mantém trechos sob demanda |
| `true` / `false` | `-1` / `0` |
| `var++`, `var+=n` | `var=var+1`, `var=var+n` |
| `include "arquivo.dmx"` | conteúdo inserido na conversão |

Este guia cobre a **linguagem** que você escreve. O funcionamento interno da IDE (menus, atalhos, tokenizador, integração com o assembler Z80 e com o openMSX) fica documentado à parte, conforme os módulos forem implementados.
