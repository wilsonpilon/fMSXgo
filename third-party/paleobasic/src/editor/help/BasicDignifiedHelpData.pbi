;
; ------------------------------------------------------------
;  Ajuda -> Basic Dignified...: base de dados dos topicos de ajuda,
;  compilada a partir da documentacao original do Basic Dignified Suite
;  (basic-dignified/documentation/*.md, baixada via Configurar -> Basic
;  Dignified... -> Baixar Basic Dignified Suite..., ver BadigSettings.pbi)
;  cruzada com o codigo real desta IDE (DignifiedPreprocessor.pbi,
;  BadigSettings.pbi, BadigEditor.pb) para dizer exatamente o que esta
;  implementado e o que e so a spec original.
;
;  Cobre dois assuntos, em grupos separados:
;  - A SINTAXE do dialeto Dignified em si (labels, defines, variaveis
;    longas, proto-funcoes, etc.) - o que voce escreve no editor.
;  - As CONFIGURACOES desta IDE (Configurar -> Basic Dignified...) e
;    quais delas realmente afetam a conversao hoje - varios campos da
;    tela existem so por compatibilidade com o .ini do Python original
;    e nao tem consumidor no pipeline nativo (DignifiedPreprocessor.pbi/
;    MsxTokenizer.pbi/RunOnOpenMSX()); isso e dito explicitamente em
;    cada topico, nao escondido.
;
;  Corpo.s usa a mesma marcacao minima de NestorBasicHelpData.pbi: linhas
;  "## " (subtitulo), "**negrito**" e "`codigo`" inline - renderizada por
;  NBHelpGui_RenderMarkdown (NestorBasicHelpGui.pbi, XIncluded antes
;  deste arquivo). Exemplos de codigo BASIC sao mostrados linha a linha
;  entre crases (estilo `codigo`) por falta de um bloco de codigo de
;  verdade no mini-Markdown.
; ------------------------------------------------------------
;

Structure BDHelpTopic
  Titulo.s
  Grupo.s
  Corpo.s
EndStructure

Global NewList BDHelp_Topics.BDHelpTopic()
Global BDHelp_DataBuilt.b = #False

Procedure BDHelp_Add(Titulo.s, Grupo.s, Corpo.s)
  AddElement(BDHelp_Topics())
  BDHelp_Topics()\Titulo = Titulo
  BDHelp_Topics()\Grupo = Grupo
  BDHelp_Topics()\Corpo = Corpo
EndProcedure

Declare BDHelp_BuildIntroducao()
Declare BDHelp_BuildSintaxe()
Declare BDHelp_BuildConfiguracoes()
Declare BDHelp_BuildRemtags()
Declare BDHelp_BuildSobre()

Procedure BDHelp_BuildData()
  If BDHelp_DataBuilt
    ProcedureReturn
  EndIf
  BDHelp_DataBuilt = #True

  BDHelp_BuildIntroducao()
  BDHelp_BuildSintaxe()
  BDHelp_BuildConfiguracoes()
  BDHelp_BuildRemtags()
  BDHelp_BuildSobre()
EndProcedure

; ================================================================
; Grupo: Introducao
; ================================================================
Procedure BDHelp_BuildIntroducao()
  BDHelp_Add("O que e o Basic Dignified", "Introducao",
    "**Basic Dignified** e um dialeto/pre-processador que le um arquivo de texto com codigo " +
    "" + MSXQ + "Dignified" + MSXQ + " e escreve de volta BASIC classico (com numeros de linha) em ASCII " +
    "e/ou binario tokenizado. A ideia e trazer conveniencias de linguagens modernas - rotulos em vez " +
    "de numeros de linha, includes, macros, proto-funcoes - para um BASIC de linha numerada sem mudar " +
    "o que roda de fato na maquina." + #CRLF$ + #CRLF$ +
    "Nesta IDE o pipeline e **nativo**, escrito do zero em PureBasic (`editor/DignifiedPreprocessor.pbi` " +
    "+ `editor/MsxTokenizer.pbi`), cobrindo 100% do escopo do `badig.py` original - nao ha chamada a " +
    "Python em nenhum menu. Os tres formatos, na ordem do pipeline:" + #CRLF$ +
    "- `.dmx` - codigo **Dignified** (o que voce escreve no editor)." + #CRLF$ +
    "- `.amx` - BASIC **classico** em **ASCII** (numeros de linha, sem rotulos)." + #CRLF$ +
    "- `.bmx` - BASIC classico **tokenizado** (binario que o MSX carrega de verdade)." + #CRLF$ + #CRLF$ +
    "**Regras gerais do formato:**" + #CRLF$ +
    "- Ao contrario do BASIC classico, instrucoes/funcoes/variaveis devem ficar **separadas por " +
    "espaco** de caracteres alfanumericos - o realce de sintaxe do editor reflete isso." + #CRLF$ +
    "- Indentacao e incentivada para legibilidade (TABS ou ESPACOS - espacos sao recomendados; com " +
    "TABS, o campo **Tamanho do TAB** da tela de configuracao ajusta o calculo de coluna nos erros)." + #CRLF$ +
    "- Linhas em branco sao removidas, exceto dentro de comentarios de **bloco** `''`. Espacos no " +
    "inicio/fim de linha sao sempre removidos." + #CRLF$ +
    "- Para evitar ambiguidade acidental, `x` e `or` adjacentes sao mantidos separados (nao formam " +
    "`xor` por engano), e numeros hexadecimais seguidos de palavras iniciando em `a`-`f` tambem ficam " +
    "separados." + #CRLF$ +
    "- Dois-pontos (`:`) duplicados sao removidos na conversao.")
EndProcedure

; ================================================================
; Grupo: Sintaxe Dignified
; ================================================================
Procedure BDHelp_BuildSintaxe()

  BDHelp_Add("Labels e loop labels", "Sintaxe Dignified",
    "Como o codigo Dignified nao tem numero de linha, **rotulos** (`{como_este}`) direcionam o fluxo. " +
    "Podem ficar **sozinhos** numa linha (recebem o fluxo) ou dentro de uma instrucao de desvio " +
    "(`goto`/`gosub`/`then`) apontando para o rotulo correspondente. So aceitam **letras**, " +
    "**numeros** e **underscore**, e nao podem ser so numeros nem comecar por numero. `{@}` e um " +
    "rotulo especial que aponta pra **propria linha** (util em `if ... then goto {@}` pra travar " +
    "esperando uma condicao)." + #CRLF$ + #CRLF$ +
    "**Loop label**: `nome{` abre, `}` fecha e manda o fluxo de volta pro `nome{` de abertura - um " +
    "jeito conciso de escrever um laco fechado. Pode ser **aninhado**. O comando `exit` sai do loop " +
    "label mais interno, mandando o fluxo pra linha **seguinte** ao fechamento `}`." + #CRLF$ + #CRLF$ +
    "Rotulos com nome invalido, duplicados, apontando pra rotulo inexistente ou loop label nao " +
    "fechado geram **erro** e param a conversao." + #CRLF$ + #CRLF$ +
    "## Exemplo" + #CRLF$ +
    "`{start}`" + #CRLF$ +
    "`print " + MSXQ + "press A to toggle" + MSXQ + "`" + #CRLF$ +
    "`if inkey$ <> " + MSXQ + "A" + MSXQ + " then goto {@}`" + #CRLF$ +
    "`loop{`" + #CRLF$ +
    "`    a$ = inkey$`" + #CRLF$ +
    "`    if a$ = " + MSXQ + "A" + MSXQ + " then goto {start}`" + #CRLF$ +
    "`    if a$ = " + MSXQ + "B" + MSXQ + " then exit`" + #CRLF$ +
    "`}`" + #CRLF$ +
    "`end`")

  BDHelp_Add("Defines (aliases de codigo)", "Sintaxe Dignified",
    "`define [nome][conteudo]` cria um **alias** substituido em todo lugar que `[nome]` aparecer no " +
    "codigo. Varios podem ser definidos na mesma linha, separados por virgula: " +
    "`define [n1][c1],[n2][c2]`. O nome so aceita letras/numeros/underscore, nao pode ser so numero " +
    "nem comecar por numero - e **precisa vir antes do uso** no codigo." + #CRLF$ + #CRLF$ +
    "**Define com variavel**: usando `[]` dentro do conteudo, o define vira parametrizavel - o " +
    "argumento vai entre **parenteses** `()` depois do `[nome]` usado no codigo. Conteudo dentro dos " +
    "colchetes vira **valor padrao** se nenhum argumento for passado." + #CRLF$ + #CRLF$ +
    "Esta IDE (dialeto MSX) traz embutido o define `[?](x,y)`, que vira `LOCATE x,y:PRINT` (sem " +
    "`(x,y)`, usa `0,0`)." + #CRLF$ + #CRLF$ +
    "## Exemplo" + #CRLF$ +
    "`define [pk][poke 100,[10]]`" + #CRLF$ +
    "`[pk](30)` -> `poke 100,30`" + #CRLF$ +
    "`[pk]` sozinho -> `poke 100,10` (usa o valor padrao)")

  BDHelp_Add("Variaveis com nomes longos e DECLARE", "Sintaxe Dignified",
    "Variaveis com **nome longo** (letras/numeros/underscore, minimo 3 caracteres, case " +
    "**insensitive**) podem ser usadas livremente no codigo Dignified. Na conversao, cada nome " +
    "diferente vira uma variavel curta de 2 letras, atribuida em ordem **decrescente** de `ZZ` ate " +
    "`AA` (variaveis de 1 letra ou letra+numero nunca sao usadas automaticamente). O mesmo nome " +
    "longo sempre vira a mesma curta independente do tipo - `variavel1` e `variavel1$` viram `XX` e " +
    "`XX$`." + #CRLF$ + #CRLF$ +
    "`declare nome:curta` **forca** uma atribuicao especifica (ex.: `declare pontos:pt`). Varios " +
    "podem ser declarados na mesma linha, separados por virgula. `declare zz,xv` **reserva** nomes " +
    "curtos, impedindo que sejam usados automaticamente (nao da pra reservar variavel de 1 letra, " +
    "mas tambem nao precisa)." + #CRLF$ + #CRLF$ +
    "Um `~` **antes** do nome (`~pontos`) mantem o nome **longo** na saida (alguns BASIC aceitam " +
    "nomes longos, truncando depois do segundo caractere) - so precisa aparecer na primeira " +
    "ocorrencia da variavel." + #CRLF$ + #CRLF$ +
    "## Exemplo" + #CRLF$ +
    "`declare food:fd, drink:dk`" + #CRLF$ +
    "`if food$ = " + MSXQ + "cake" + MSXQ + " and drink = 3 then end`" + #CRLF$ +
    "`result$ = " + MSXQ + "belly full" + MSXQ + "`   ' vira ZZ$ (proxima curta disponivel)")

  BDHelp_Add("Proto-funcoes (FUNC / RET)", "Sintaxe Dignified",
    "`func .nome(arg1, arg2)` ... `ret [valor1, valor2]` emula definicao e chamada de funcao. O " +
    "nome so aceita letras/numeros/underscore. Argumentos podem ter **valor padrao** " +
    "(`func .fn(arg$=" + MSXQ + "teste" + MSXQ + ")`). Chamadas usam `.nome(args)`, podem ser " +
    "**atribuidas** (`v1, v2 = .nome(args)`) e aparecer depois de `THEN`/`ELSE`. Uma chamada pode " +
    "usar **menos** argumentos/retornos que a definicao (o excesso e ignorado), mas **nunca mais**." + #CRLF$ + #CRLF$ +
    "So pode haver **um** `ret` por funcao - ele marca o **fim** da definicao. Um `RETURN` normal " +
    "(sem variaveis) pode ser usado dentro da funcao pra retornar de um ponto diferente." + #CRLF$ + #CRLF$ +
    "**IMPORTANTE - achado real usando esta IDE**: uma definicao `func`/`ret` **nao desvia** o " +
    "fluxo por si so (e um `GOSUB` disfarcado, nao um `IF`/pulo automatico). Colocar `func...ret` " +
    "**antes** do `end` do fluxo principal faz o programa **cair dentro** da funcao e executa-la " +
    "sem ter sido chamada - e um `ret`/`RETURN` sem `GOSUB` correspondente quebra com erro em tempo " +
    "de execucao. **Sempre coloque as definicoes de funcao depois do `end` do fluxo principal.**" + #CRLF$ + #CRLF$ +
    "## Exemplo" + #CRLF$ +
    "`letter$ = .upper(" + MSXQ + "a" + MSXQ + ")`" + #CRLF$ +
    "`print letter$`" + #CRLF$ +
    "`end`" + #CRLF$ +
    "`func .upper(up$)`" + #CRLF$ +
    "`    ch = asc(up$) - 32`" + #CRLF$ +
    "`ret chr$(ch)`")

  BDHelp_Add("Separacao e juncao de linhas ( : e _ )", "Sintaxe Dignified",
    "`:` no **fim** de uma linha junta com a **proxima**; `:` no **inicio** junta com a " +
    "**anterior** - e mantido no codigo convertido (mesma funcao de separador de instrucoes do " +
    "BASIC classico)." + #CRLF$ + #CRLF$ +
    "`_` no **fim** de uma linha tambem junta com a proxima, mas e **removido** na conversao - util " +
    "pra quebrar `IF ... THEN ... ELSE` ou qualquer comando que precise virar uma unica linha sem " +
    "sobrar `:`. Precisa ficar **separado** por espaco do ultimo caractere se ele for alfanumerico, " +
    "e nao funciona no fim de comentarios ou aspas abertas." + #CRLF$ + #CRLF$ +
    "**Aspas** podem ser **concatenadas** simplesmente colocando-as em sequencia, mesmo em linhas " +
    "diferentes: `PRINT " + MSXQ + "Hello " + MSXQ + " " + MSXQ + "word" + MSXQ + "`." + #CRLF$ + #CRLF$ +
    "`endif` marca visualmente o fim de um `IF` multi-linha mas e **cosmetico** - removido sem " +
    "processamento nenhum na conversao (o bloco `IF` de fato e definido pela indentacao, no " +
    "espirito Python).")

  BDHelp_Add("Comentarios exclusivos e toggles (## e #nome)", "Sintaxe Dignified",
    "## Comentarios" + #CRLF$ +
    "`##` marca um comentario **exclusivo Dignified**, removido na conversao. `REM` e `'` sao " +
    "comentarios **normais** e sao **mantidos**. Blocos sao abertos/fechados com `''` (mantido) ou " +
    "`###` (removido)." + #CRLF$ + #CRLF$ +
    "## Toggles de linha" + #CRLF$ +
    "`#nome` marca trechos de codigo pra **remover sob demanda** na conversao. So aceita " +
    "letras/numeros/underscore, nao pode ser so numero nem comecar por numero. `keep #a #b` numa " +
    "linha **antes** deles mantem os toggles nomeados na saida (pode listar nenhum, um ou varios, " +
    "separados por espaco). Dois toggles especiais: `#all` mantem tudo, `#none` remove tudo - se " +
    "os dois forem usados, `#none` tem precedencia." + #CRLF$ + #CRLF$ +
    "Um toggle no **inicio** de uma linha afeta so aquela linha (`#a print ...`); **sozinho** numa " +
    "linha, marca **inicio/fim de bloco** (igual comentario de bloco). Toggles de bloco podem ser " +
    "**aninhados** mas nao **interpolados**. Um toggle nao fechado gera aviso." + #CRLF$ + #CRLF$ +
    "## Exemplo" + #CRLF$ +
    "`keep #b`" + #CRLF$ +
    "`#a print " + MSXQ + "nao converte" + MSXQ + "`" + #CRLF$ +
    "`#b print " + MSXQ + "converte" + MSXQ + "`   ' fica, porque #b esta em keep")

  BDHelp_Add("Caracteres ASCII especiais e traducao Unicode", "Sintaxe Dignified",
    "O charset classico do MSX (acentos, box-drawing, letras gregas) nao existe direto no " +
    "Unicode/UTF-8 que o editor usa pra salvar arquivos. Escrevendo os caracteres Unicode " +
    "**parecidos** (ex.: `┌──┐` pra bordas de caixa), a opcao **Traduzir caracteres Unicode " +
    "especiais** (aba Basic Dignified da tela de configuracao, ligada por padrao nesta IDE) " +
    "converte cada um pro byte real do charset MSX na hora de gerar o `.amx`/`.bmx`." + #CRLF$ + #CRLF$ +
    "Sem essa traducao, uma string com caracteres especiais fica com bytes incorretos no `.bmx` " +
    "gerado - por isso o padrao aqui e **ligado**, diferente do `badig.py` original (que vem " +
    "desligado por padrao, `-tr` precisa ser passado explicitamente)." + #CRLF$ + #CRLF$ +
    "## Exemplo" + #CRLF$ +
    "`print " + MSXQ + "┌──────┐" + MSXQ + "`" + #CRLF$ +
    "`print " + MSXQ + "│SAVING│" + MSXQ + "`" + #CRLF$ +
    "`print " + MSXQ + "└──────┘" + MSXQ + "`" + #CRLF$ +
    "vira (com traducao ligada) as bordas reais do charset MSX, prontas pra aparecer corretas na " +
    "tela do MSX/openMSX.")

  BDHelp_Add("INCLUDE (arquivos externos)", "Sintaxe Dignified",
    "`include " + MSXQ + "arquivo.dmx" + MSXQ + "` insere o **conteudo** do arquivo exatamente onde " +
    "o `include` esta - pode ate ter as linhas **unidas** ao codigo principal usando `:` ou `_` " +
    "antes/depois." + #CRLF$ + #CRLF$ +
    "Cada arquivo incluido tem **namespace separado**: toggles, funcoes, rotulos e defines podem " +
    "repetir nome entre arquivos **sem conflito**. Variaveis de **nome longo** tambem recebem " +
    "nomes curtos **diferentes** por arquivo, mas nao podem ter a **mesma declaracao** " +
    "(`declare`) entre includes. Como o BASIC classico nao tem namespace de verdade, ha risco de " +
    "conflito entre variaveis **curtas hardcoded** usadas diretamente (1-2 letras) - a IDE avisa " +
    "quando isso acontece." + #CRLF$ + #CRLF$ +
    "Esta e exatamente a implementacao usada por `Arquivo -> Novo` e pelo pre-processador nativo " +
    "desta IDE (`editor/DignifiedPreprocessor.pbi`), com paridade completa em relacao ao original.")

  BDHelp_Add("TRUE / FALSE e operadores compostos", "Sintaxe Dignified",
    "`true` e `false` podem ser usados com variaveis **numericas** - viram `-1` e `0` na conversao, " +
    "e a variavel pode ser tratada como booleana de verdade em `IF`s e com `NOT`." + #CRLF$ + #CRLF$ +
    "Operadores **abreviados**/**compostos** `++`, `--`, `+=`, `-=`, `*=`, `/=`, `^=` sao " +
    "convertidos pras operacoes normais do BASIC classico." + #CRLF$ + #CRLF$ +
    "## Exemplo" + #CRLF$ +
    "`var_bool = true`      ->  `ZZ=-1`" + #CRLF$ +
    "`var1++ : var2--`      ->  `ZY=ZY+1:ZX=ZX-1`" + #CRLF$ +
    "`var3 += 20`           ->  `ZW=ZW+20`")
EndProcedure

; ================================================================
; Grupo: Configurar -> Basic Dignified...
; ================================================================
Procedure BDHelp_BuildConfiguracoes()

  BDHelp_Add("Aba Basic Dignified: numeracao e formatacao", "Configurar -> Basic Dignified...",
    "Estes campos da **primeira aba** (" + MSXQ + "Basic Dignified" + MSXQ + ") afetam de verdade a saida - todos passam por " +
    "`Dig_SyncConfigFromBadigCfg()` direto pro pre-processador nativo (`DignifiedPreprocessor.pbi`) " +
    "toda vez que voce roda **Dignified -> ASCII/tokenizado nativo** ou **Executar -> BASIC/Nestor " +
    "Basic**." + #CRLF$ + #CRLF$ +
    "- **Linha inicial** - numero da primeira linha do BASIC classico gerado (padrao `10`)." + #CRLF$ +
    "- **Passo de linha** - incremento entre linhas (padrao `10`)." + #CRLF$ +
    "- **Tamanho do TAB** - quantos espacos vale um TAB no seu editor, usado so pra calcular a " +
    "coluna certa em mensagens de erro quando voce indenta com TAB (padrao `4`)." + #CRLF$ +
    "- **Incluir cabecalho REM** - adiciona duas linhas de comentario no topo do BASIC gerado " +
    "citando o Basic Dignified (padrao **ligado**)." + #CRLF$ +
    "- **Remover todos os espacos** - tira espacos nao essenciais ao redor de instrucoes/variaveis " +
    "(padrao **desligado** - mantem espacos pra legibilidade)." + #CRLF$ +
    "- **Converter tudo para maiusculas** - capitaliza tudo que nao for texto literal (padrao " +
    "**desligado**)." + #CRLF$ +
    "- **Traduzir caracteres Unicode especiais para nativos MSX** - ver o topico dedicado no grupo " +
    "Sintaxe Dignified (padrao **ligado** nesta IDE, diferente do original)." + #CRLF$ + #CRLF$ +
    "**Verbosidade (0-4)** tambem esta nesta aba mas **nao tem efeito** no pipeline nativo hoje - " +
    "controlava o nivel de log do `badig.py` no terminal; esta IDE nao gera log de console " +
    "equivalente.")

  BDHelp_Add("Aba Basic Dignified: relatorios (sem efeito nesta IDE)", "Configurar -> Basic Dignified...",
    "O bloco **" + MSXQ + "Relatorios (salvar/exibir)" + MSXQ + "** da primeira aba tem 6 opcoes: " +
    "**Exibir relatorios em vez de salvar**, **Rotulos como REM no codigo convertido**, " +
    "**Correspondencia de linhas**, **Substituicao de variaveis**, **Saida do lexer (tokens)** e " +
    "**Saida do parser (tokens)**." + #CRLF$ + #CRLF$ +
    "No `badig.py` original, essas opcoes geram arquivos de relatorio extra (ou log no console) " +
    "detalhando o fluxo do programa (`-lbr`), a correspondencia de linhas Dignified/classico " +
    "(`-lnr`), a tabela de variaveis longas/curtas (`-var`) e os tokens gerados pelo lexer/parser " +
    "internos (`-lex`/`-par`)." + #CRLF$ + #CRLF$ +
    "**Nesta IDE, nenhuma dessas opcoes tem consumidor** - os campos existem na tela e sao " +
    "persistidos no `badig_settings.json`, mas `DignifiedPreprocessor.pbi` nao os le (confirmado " +
    "por auditoria do codigo, 2026-07-28). Ficam guardados por compatibilidade com o formato do " +
    "toolchain original, caso um dia esses relatorios sejam portados; por enquanto, marcar ou " +
    "desmarcar essas caixas **nao muda** o BASIC gerado.")

  BDHelp_Add("Aba MSX: PRINT/? e THEN/GOTO", "Configurar -> Basic Dignified...",
    "Estes dois campos do topo da **segunda aba** (" + MSXQ + "MSX" + MSXQ + ") sao **especificos do modulo MSX** (nao existem no Basic Dignified " +
    "generico) e afetam de verdade a conversao:" + #CRLF$ + #CRLF$ +
    "- **Converter ? / PRINT** - `? -> PRINT` expande todo `?` pra `PRINT`; `PRINT -> ?` faz o " +
    "inverso, abreviando todo `PRINT` pra `?` (padrao: nao converter, mantem como esta escrito)." + #CRLF$ +
    "- **Remover THEN/ELSE ou GOTO** - quando `THEN`/`ELSE` e `GOTO` estao adjacentes " +
    "(`THEN GOTO 100`), alguns BASIC dispensam um dos dois. **THEN/ELSE (apos IF)** remove o " +
    "`THEN`/`ELSE` quando possivel; **GOTO (apos THEN/ELSE)** remove o `GOTO` quando possivel " +
    "(padrao: nao remover nenhum)." + #CRLF$ + #CRLF$ +
    "Ambos sao aplicados pelo mesmo `Dig_SyncConfigFromBadigCfg()` da aba anterior, sincronizados " +
    "com `Dig_ConvertPrintCfg`/`Dig_StripThenGotoCfg` no pre-processador nativo.")

  BDHelp_Add("Aba MSX: opcoes do tokenizador (sem efeito nesta IDE)", "Configurar -> Basic Dignified...",
    "O bloco **" + MSXQ + "Tokenizador (msxbatoken)" + MSXQ + "** da aba MSX tem 4 campos: " +
    "**Gerar arquivo de listagem** (+ **Colunas**), **Apagar o ASCII apos tokenizar** e " +
    "**Verbosidade do tokenizador**." + #CRLF$ + #CRLF$ +
    "No MSX Basic Tokenizer original (`msxbatoken.py`), esses campos controlam a exportacao de um " +
    "arquivo `.lmx` (listagem estilo assembler, bytes + linha ASCII lado a lado - ver o topico " +
    "**Formato tokenizado (.bmx)** no grupo Sobre a suite original) e se o `.amx` intermediario e " +
    "apagado depois de gerar o `.bmx`." + #CRLF$ + #CRLF$ +
    "**Nesta IDE, `editor/MsxTokenizer.pbi` nao implementa nenhum dos dois** - nao exporta listagem " +
    "`.lmx` nem apaga o ASCII automaticamente (o `.amx` sempre fica, e voce decide se apaga). Os " +
    "campos existem na tela/JSON por paridade com o `.ini` original mas nao mudam o comportamento " +
    "de **Dignified -> tokenizado nativo (.bmx)...**.")

  BDHelp_Add("Aba Emulador: rodar no openMSX", "Configurar -> Basic Dignified...",
    "A **terceira aba** (" + MSXQ + "Emulador" + MSXQ + ") controla o que acontece quando voce usa " +
    "**Executar -> BASIC** ou **Executar -> Nestor Basic** (`RunOnOpenMSX()` em " +
    "`editor/BadigEditor.pb`)." + #CRLF$ + #CRLF$ +
    "**Campos com efeito real:**" + #CRLF$ +
    "- **Abrir o openMSX e rodar o codigo apos gerar** - liga o fluxo completo: monta um `.dsk` " +
    "com o programa gerado + `AUTOEXEC.BAS` de autorun e abre o openMSX ja rodando nele." + #CRLF$ +
    "- **Maquina (machine)** - passado como `-machine <nome>` pro openMSX, com botao " +
    MSXQ + "..." + MSXQ + " que lista os `.xml` de `share/machines/` do openMSX configurado." + #CRLF$ +
    "- **Extensao de disco (extension)** - passado como `-ext<slot> <nome>` (formato " +
    "`Nome:slot`, ex.: `Nome:exta` - o slot vira parte do nome da flag, replicando a regra real do " +
    "openMSX), com o mesmo tipo de botao de busca." + #CRLF$ +
    "- **Caminho do executavel do openMSX** - unico campo que tambem e gravado de volta no " +
    "`emulator_interface.ini` da instalacao Python (se houver), porque o `badig.py` original nao " +
    "tem flag de linha de comando equivalente pra ele." + #CRLF$ + #CRLF$ +
    "**Campos sem consumidor hoje** (persistidos, mas `RunOnOpenMSX()` nao os le): **Monitorar " +
    "execucao**, **Rodar sem limitador de velocidade**, **Arquivo de configuracao (setting)** e " +
    "**Verbosidade do emulador**. No original, `Monitorar` habilitava deteccao de erro em tempo " +
    "real via `-control stdio` do openMSX (so funcionava em Mac/Linux); portar isso pro Windows " +
    "nesta IDE ainda esta em aberto (ver `docs/SPEC.md`, lacunas conhecidas).")

  BDHelp_Add("Diretorio de instalacao e download do Basic Dignified Suite", "Configurar -> Basic Dignified...",
    "No topo da primeira aba, **Diretorio de instalacao do Basic Dignified Suite** + botao " +
    MSXQ + "..." + MSXQ + " apontam pra onde uma copia do toolchain Python original ficaria " +
    "instalada, e o botao **Baixar Basic Dignified Suite...** clona (via `git clone --depth 1`) ou " +
    "baixa um `.zip` direto de `github.com/farique1/basic-dignified.git` pra essa pasta." + #CRLF$ + #CRLF$ +
    "**Isso e totalmente opcional.** Esta IDE tem pre-processador e tokenizador **nativos** " +
    "(`DignifiedPreprocessor.pbi`/`MsxTokenizer.pbi`, XIncluded direto no `.exe`) que cobrem 100% " +
    "do escopo do `badig.py` original - nenhum menu desta IDE chama Python ou depende dessa pasta " +
    "pra funcionar (confirmado por auditoria de codigo, 2026-07-28). So baixe/instale se voce " +
    "quiser **rodar o Basic Dignified Suite original em Python separadamente** (por exemplo, pra " +
    "usar ferramentas que ainda nao foram portadas pra esta IDE - ver o grupo **Sobre a suite " +
    "original** abaixo)." + #CRLF$ + #CRLF$ +
    "E essa mesma documentacao (`basic-dignified/documentation/*.md`, baixada por esse botao) que " +
    "foi usada pra montar os topicos deste **Ajuda -> Basic Dignified...**.")
EndProcedure

; ================================================================
; Grupo: Remtags (diretivas no codigo)
; ================================================================
Procedure BDHelp_BuildRemtags()

  BDHelp_Add("O que sao remtags", "Remtags (diretivas no codigo)",
    "**Remtags** sao linhas de comentario exclusivo especiais (`##BB:comando=valor`) que alteram o " +
    "comportamento da conversao **de dentro do proprio codigo** Dignified, sem precisar mudar a " +
    "tela de configuracao. Sao lidas **so no arquivo principal** (nao em arquivos `include`d), " +
    "tipicamente colocadas no topo do arquivo." + #CRLF$ + #CRLF$ +
    "Cada configuracao pode vir de 4 lugares, em ordem **crescente de prioridade**: os valores " +
    "padrao do codigo, a tela de configuracao (`badig_settings.json` nesta IDE), argumentos de " +
    "linha de comando (so relevante pro `badig.py` externo) e por ultimo os **remtags**, que " +
    "sempre **vencem** sobre a tela de configuracao para aquela conversao especifica." + #CRLF$ + #CRLF$ +
    "**Truque util**: pra desativar um remtag sem apagar a linha, basta colocar um **espaco** " +
    "entre `##` e `BB` (`## BB:arguments=...`) - vira um comentario exclusivo comum, ignorado " +
    "pelo parser de remtags." + #CRLF$ + #CRLF$ +
    "## Exemplo" + #CRLF$ +
    "`##BB:export_file=`" + #CRLF$ +
    "`##BB:arguments=-ss -ca`" + #CRLF$ +
    "`## BB:help=True`   ' desativado pelo espaco antes de BB")

  BDHelp_Add("##BB:arguments= (flags equivalentes)", "Remtags (diretivas no codigo)",
    "`##BB:arguments=` aceita uma lista de **flags no mesmo formato da linha de comando** do " +
    "`badig.py` original, aplicadas so pra aquela conversao. Esta IDE reconhece e **aplica de " +
    "verdade** este subconjunto (`Dig_ApplyArgumentsRemtag()` em `DignifiedPreprocessor.pbi`):" + #CRLF$ +
    "- `-tl <#>` - tamanho do TAB." + #CRLF$ +
    "- `-ls <#>` - linha inicial." + #CRLF$ +
    "- `-lp <#>` - passo de linha." + #CRLF$ +
    "- `-rh` - **desliga** o cabecalho REM (presenca da flag inverte o padrao, igual no original)." + #CRLF$ +
    "- `-ss` - remove espacos nao essenciais." + #CRLF$ +
    "- `-ca` - capitaliza tudo." + #CRLF$ +
    "- `-tr` - liga traducao Unicode." + #CRLF$ +
    "- `-cp <p|?>` - converte PRINT/`?`." + #CRLF$ +
    "- `-tg <t|g>` - remove THEN/ELSE (`t`) ou GOTO (`g`) adjacentes." + #CRLF$ + #CRLF$ +
    "As demais flags do `badig.py`/`badig_msx.py` original (`-id`, `-vb`, `-prr`, `-lbr`, `-lnr`, " +
    "`-var`, `-lex`, `-par`, `-asc`, `-ini`, `-rtg`) sao **aceitas e ignoradas** silenciosamente - " +
    "consumindo o valor quando a flag original recebe um, so pra nao desalinhar o parsing das " +
    "flags seguintes na mesma linha. Uma flag desconhecida tambem e ignorada sem erro.")

  BDHelp_Add("##BB:export_file= e ##BB:help=", "Remtags (diretivas no codigo)",
    "`##BB:export_file=[caminho]` troca o **destino sugerido** ao salvar a saida (ASCII ou " +
    "tokenizado) - util pra testar variacoes do codigo sem sobrescrever o arquivo de destino " +
    "padrao. Se vazio, o remtag e ignorado e o nome/caminho normal (baseado no arquivo fonte) e " +
    "usado. Caminho relativo e resolvido a partir da pasta do arquivo fonte; caminho absoluto " +
    "(com `:` ou comecando com `\\`/`/`) e usado como esta." + #CRLF$ + #CRLF$ +
    "Nesta IDE, o valor resolvido (`Dig_ExportFileOverride`) so **preenche a sugestao** no dialogo " +
    "de **Salvar como** - voce ainda confirma ou troca o caminho antes de gravar." + #CRLF$ + #CRLF$ +
    "`##BB:help=[True|False]` no original listava, no console, todos os remtags disponiveis " +
    "(incluindo os expostos pelos modulos de linguagem/tokenizador/emulador). Esta IDE **reconhece " +
    "a sintaxe** (guarda a flag em `Dig_RemtagHelpRequested`) mas **nao tem saida de console** " +
    "equivalente pra imprimir essa lista - o remtag e parseado sem erro, mas nao produz efeito " +
    "visivel hoje.")
EndProcedure

; ================================================================
; Grupo: Sobre a suite original (Python)
; ================================================================
Procedure BDHelp_BuildSobre()

  BDHelp_Add("Ferramentas nao incorporadas a este editor", "Sobre a suite original (Python)",
    "O Basic Dignified Suite original (`github.com/farique1/basic-dignified`) traz algumas " +
    "ferramentas que **nao foram portadas** pra esta IDE porque nao fazem sentido no contexto de " +
    "um editor nativo MSX-only, ou ainda nao foram priorizadas:" + #CRLF$ + #CRLF$ +
    "- **MSX Basic DignifieR** (`msxbader.py`) - faz a conversao **inversa**: BASIC classico com " +
    "numero de linha vira Dignified (remove numeros, cria rotulos, adiciona espacos, etc.), util " +
    "pra importar programas antigos. Esta IDE **nao tem** essa ferramenta hoje - so converte " +
    "Dignified -> classico, nunca o caminho inverso." + #CRLF$ +
    "- **Integracao com Sublime Text/VSCode** (build system, syntax highlight, temas, snippets) - " +
    "irrelevante aqui, ja que esta IDE tem seu **proprio** editor com highlight, menus e atalhos " +
    "nativos (nao precisa de outro editor de texto por fora)." + #CRLF$ +
    "- **Suporte a Tandy Color Computer (CoCo)** (modulo `coco`, ferramenta `cocotocas.py`) - fora " +
    "de escopo, esta IDE e **MSX-only**." + #CRLF$ +
    "- **Criacao de novos modulos de sistema** (arquitetura de extensao do `badig.py` pra outros " +
    "computadores alem de MSX/CoCo) - nao se aplica; o pipeline nativo desta IDE ja e MSX " +
    "diretamente, sem essa camada de abstracao.")

  BDHelp_Add("Formato tokenizado (.bmx) - referencia", "Sobre a suite original (Python)",
    "Referencia rapida do formato binario que `editor/MsxTokenizer.pbi` gera (mesmo formato que " +
    "`SAVE` sem `,A` grava no MSX de verdade), baseada no MSX Basic Tokenizer original. Cada linha " +
    "tokenizada tem 4 partes:" + #CRLF$ +
    "- **Bytes 1-2** - endereco de memoria da linha." + #CRLF$ +
    "- **Bytes 3-6** - os 4 bytes seguintes: ponteiro pra proxima linha (2 bytes) + numero da " +
    "linha (2 bytes)." + #CRLF$ +
    "- **Bytes 7 em diante** - a linha **tokenizada** (cada palavra-chave vira 1 byte, ou 2 bytes " +
    "com prefixo `0xFF` pras funcoes/comandos estendidos menos comuns)." + #CRLF$ +
    "- Terminador `0x00` no fim de cada linha; fim de programa marcado com `0x00 0x00 0x00`. O " +
    "primeiro byte do arquivo `0xFF` sinaliza " + MSXQ + "arquivo tokenizado" + MSXQ + "." + #CRLF$ + #CRLF$ +
    "A tabela completa de tokens (comando -> byte hexadecimal) usada pelo port nativo desta IDE " +
    "esta documentada em `docs/reference/` - veja tambem `docs/BATOKEN-USER.md` se quiser o " +
    "detalhe linha a linha do processo de tokenizacao byte a byte.")
EndProcedure
