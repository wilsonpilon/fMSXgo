;
; ------------------------------------------------------------
;  Ajuda -> MSX BASIC...: base de dados complementar ao Dicionario das
;  Palavras Reservadas (MsxBasicDictData.pbi), cobrindo o restante do
;  livro "Linguagem BASIC MSX" (Denise Santoro Cruz, Editora Aleph/
;  Gradiente, 4a edicao 1986), digitalizado em docs/Linguagem_Basic_MSX.pdf:
;
;  - PARTE I - A Estrutura do BASIC MSX (paginas 15-22): modos de
;    operacao, conjunto de caracteres, constantes, variaveis, matrizes,
;    ocupacao de memoria, conversao de precisao, operadores (aritmeticos/
;    relacionais/logicos com tabela-verdade) e edicao de programas.
;  - PARTE III - Aplicacoes Especiais (paginas 178-184): interrupcoes,
;    processo de arquivo e sub-rotinas em linguagem de maquina.
;  - PARTE IV - Apendices (paginas 186-207): Apendice A (caracteres
;    ASCII), Apendice C (codigos de erro), Apendice D (mapa da memoria)
;    e Apendice I (funcoes trigonometricas e hiperbolicas). Os demais
;    apendices (B-Impressora, E-Especificacoes Tecnicas, F-Pinagem,
;    G-Teclados, H-Glossario) nao foram pedidos e ficaram de fora.
;  - Cores do MSX: tabela das 16 cores (0-15) com nome oficial "Gradiente"
;    e uma aproximacao de cor RGB (paleta padrao TMS9918, a mesma usada
;    pelo VDP do MSX1) - baseada na pagina final nao numerada do livro
;    ("AS CORES DO EXPERT"), que mostra cada cor como um lapis colorido.
;
;  Estrutura por topico livre (Titulo/Parte/Corpo/PaginaLivro), diferente
;  da estrutura fixa FORMATO/EXEMPLO/FUNCAO/PROGRAMA do dicionario de
;  palavras reservadas, ja que este conteudo e prosa/tabelas, nao
;  verbetes de palavra reservada.
;
;  PaginaLivro.i guarda o numero de pagina IMPRESSO no livro (offset
;  pagina_impressa = pagina_pdf + 3, mesmo usado no dicionario).
; ------------------------------------------------------------
;

Structure MSXManualTopic
  Titulo.s        ; ex "Conjunto de Caracteres"
  Parte.s         ; ex "Parte I - A Estrutura do BASIC MSX"
  Corpo.s         ; texto completo (mini-markdown: "- " para bullets, #CRLF$ para paragrafos)
  PaginaLivro.i   ; pagina impressa onde comeca o topico
EndStructure

Global NewList MSXManual_Topics.MSXManualTopic()

Procedure MSXManual_Add(Titulo.s, Parte.s, Corpo.s, PaginaLivro.i)
  AddElement(MSXManual_Topics())
  MSXManual_Topics()\Titulo = Titulo
  MSXManual_Topics()\Parte = Parte
  MSXManual_Topics()\Corpo = Corpo
  MSXManual_Topics()\PaginaLivro = PaginaLivro
EndProcedure

Procedure.s MSXManual_SearchKey(*Topico.MSXManualTopic)
  ProcedureReturn LCase(*Topico\Titulo + " " + *Topico\Parte)
EndProcedure

; --- Tabela de cores do MSX (paleta VDP TMS9918, 16 cores fixas 0-15) ---
Structure MSXColorSwatch
  Numero.i       ; 0-15, o valor usado em COLOR/DRAW/CIRCLE/PSET/etc
  Nome.s         ; nome oficial dado na pagina final do livro ("AS CORES DO EXPERT")
  CorHex.s       ; aproximacao RGB (paleta padrao TMS9918), formato "RRGGBB"
EndStructure

Global NewList MSXManual_Colors.MSXColorSwatch()

Procedure MSXColor_Add(Numero.i, Nome.s, CorHex.s)
  AddElement(MSXManual_Colors())
  MSXManual_Colors()\Numero = Numero
  MSXManual_Colors()\Nome = Nome
  MSXManual_Colors()\CorHex = CorHex
EndProcedure

Declare MSXManual_BuildParteI()
Declare MSXManual_BuildParteIII()
Declare MSXManual_BuildApendices()
Declare MSXColor_BuildData()
Declare MSXManual_BuildMSX2Plus() ; definido em MsxBasic2PlusManualData.pbi (XIncluded depois deste arquivo)

Procedure MSXManual_BuildData()
  If ListSize(MSXManual_Topics()) > 0
    ProcedureReturn ; ja construido - so monta uma vez por sessao
  EndIf

  MSXManual_BuildParteI()
  MSXManual_BuildParteIII()
  MSXManual_BuildApendices()
  MSXColor_BuildData()
  MSXManual_BuildMSX2Plus()
EndProcedure

; --- Parte I - A Estrutura do BASIC MSX (paginas 15-22 do livro = 12-19 do PDF) ---
Procedure MSXManual_BuildParteI()
  MSXManual_Add("Modos de Operacao", "Parte I - A Estrutura do BASIC MSX",
    "Quando o computador e ligado, gera uma mensagem na tela:" + #CRLF$ + #CRLF$ +
    "MSX BASIC versao 1.1 Br" + #CRLF$ +
    "Gradiente" + #CRLF$ +
    "28815 bytes livres" + #CRLF$ +
    "Ok" + #CRLF$ + #CRLF$ +
    "Este " + MSXQ + "OK" + MSXQ + " significa que ele esta apto a receber comandos. Eles podem ser " +
    "introduzidos de duas formas:" + #CRLF$ + #CRLF$ +
    "MODO DIRETO: O comando e digitado sem ser precedido por um " + MSXQ + "numero de linha" + MSXQ + ". " +
    "Ao teclarmos RETURN, ele e imediatamente executado. Seu resultado pode permanecer armazenado " +
    "na memoria, mas a instrucao em si e perdida." + #CRLF$ + #CRLF$ +
    "MODO PROGRAMACAO: Neste caso, cada linha contendo instrucoes e precedida por um numero. O " +
    "computador, inicialmente, armazena todas as linhas em sua memoria (portanto, as instrucoes " +
    "nelas contidas nao se perdem apos a execucao) e, quando solicitado, as executa " +
    "sequencialmente." + #CRLF$ + #CRLF$ +
    "As linhas do BASIC, no MSX, tem a seguinte estrutura:" + #CRLF$ +
    "NUMERO DA LINHA   INSTRUCAO   [: INSTRUCAO]   (CR)" + #CRLF$ + #CRLF$ +
    "onde:" + #CRLF$ +
    "- NUMERO DA LINHA: deve ser um numero inteiro entre 0 e 65529." + #CRLF$ +
    "- INSTRUCAO: deve ser uma instrucao do BASIC MSX." + #CRLF$ +
    "- [: INSTRUCAO]: varias instrucoes podem ser digitadas numa mesma linha, desde que o total " +
    "de caracteres nela contidos nao ultrapasse 255. Os colchetes indicam complemento opcional." + #CRLF$ +
    "- (CR): carriage return, ou, simplesmente, return. E obtido pressionando-se a tecla RETURN.",
    15)

  MSXManual_Add("Conjunto de Caracteres", "Parte I - A Estrutura do BASIC MSX",
    "Os caracteres do MSX sao os alfabeticos, os numericos, os especiais, os graficos e os do " +
    "alfabeto europeu (Portugal tambem esta na Europa)." + #CRLF$ + #CRLF$ +
    "- Caracteres alfabeticos: sao as letras de A a Z, maiusculas e minusculas." + #CRLF$ +
    "- Caracteres numericos: sao os algarismos de 0 a 9 (o zero e cortado para evitar confusoes " +
    "com a letra O)." + #CRLF$ +
    "- Caracteres especiais: alem dos caracteres alfabeticos e numericos, os seguintes " +
    "caracteres especiais sao reconhecidos pelo BASIC MSX:" + #CRLF$ + #CRLF$ +
    "CARACTERE -> INTERPRETACAO" + #CRLF$ +
    "- (espaco) -> Branco" + #CRLF$ +
    "- = -> Igual" + #CRLF$ +
    "- + -> Simbolo de adicao" + #CRLF$ +
    "- - -> Simbolo de subtracao" + #CRLF$ +
    "- * -> Simbolo de multiplicacao" + #CRLF$ +
    "- / -> Simbolo de divisao" + #CRLF$ +
    "- \ -> Simbolo de divisao inteira" + #CRLF$ +
    "- ^ -> Exponenciacao" + #CRLF$ +
    "- ( -> Abre parenteses" + #CRLF$ +
    "- ) -> Fecha parenteses" + #CRLF$ +
    "- % -> Porcentagem" + #CRLF$ +
    "- # -> Numero ou escopo" + #CRLF$ +
    "- " + MSXQ + " -> Aspas" + #CRLF$ +
    "- ! -> Ponto de exclamacao" + #CRLF$ +
    "- ; -> Ponto e virgula" + #CRLF$ +
    "- $ -> Dolar ou cifrao" + #CRLF$ +
    "- , -> Virgula" + #CRLF$ +
    "- . -> Ponto" + #CRLF$ +
    "- ' -> Apostrofo" + #CRLF$ +
    "- : -> Dois pontos" + #CRLF$ +
    "- & -> " + MSXQ + "E" + MSXQ + " comercial" + #CRLF$ +
    "- ? -> Ponto de interrogacao" + #CRLF$ +
    "- < -> Menor que" + #CRLF$ +
    "- > -> Maior que" + #CRLF$ +
    "- _ -> Barra inferior" + #CRLF$ +
    "- (BS) -> Back Space (volta o cursor apagando)" + #CRLF$ +
    "- (ESC) -> Escape" + #CRLF$ +
    "- (TAB) -> Tabulador" + #CRLF$ +
    "- (CR) -> Carriage Return" + #CRLF$ +
    "- (LF) -> Line Feed",
    16)

  MSXManual_Add("Constantes", "Parte I - A Estrutura do BASIC MSX",
    "Sao valores usados durante uma execucao e podem ser classificados em dois tipos: alfabeticos " +
    "(strings) e numericos." + #CRLF$ + #CRLF$ +
    "CONSTANTE STRING: Uma constante string e uma sequencia de ate 255 caracteres, digitada entre " +
    "aspas." + #CRLF$ + #CRLF$ +
    "CONSTANTE NUMERICA: As constantes numericas sao de 6 tipos:" + #CRLF$ +
    "- Inteiras: que nao possuem ponto decimal. Seu valor pode estar entre -32768 e 32767." + #CRLF$ +
    "- Ponto-fixo: sao numeros reais positivos ou negativos, que podem conter o ponto decimal." + #CRLF$ +
    "- Ponto-flutuante: sao numeros positivos ou negativos representados na forma exponencial, " +
    "semelhante a notacao cientifica. Uma constante com ponto flutuante consiste em uma constante " +
    "inteira ou de ponto-fixo (com ou sem sinal) seguida de uma letra E ou D e da quantidade de " +
    "posicoes que o ponto decimal deve andar (se o deslocamento for para a esquerda, o numero de " +
    "posicoes e negativo). Por exemplo:" + #CRLF$ +
    "  23.4E3 = 23400" + #CRLF$ +
    "  419E-5 = .00419" + #CRLF$ +
    "  As constantes de ponto flutuante podem assumir valores entre 10^-64 e 10^63." + #CRLF$ +
    "- Hexadecimal: numeros hexadecimais, precedidos por &H." + #CRLF$ +
    "- Octal: numeros octais, precedidos por &O." + #CRLF$ +
    "- Binarios: numeros binarios, precedidos por &B." + #CRLF$ + #CRLF$ +
    "As constantes numericas podem ser processadas com precisao simples (6 algarismos " +
    "significativos) ou dupla (14 algarismos significativos). O computador reconhece uma " +
    "constante com precisao simples quando, no ponto flutuante, e usada a letra E, ou quando ela " +
    "e seguida pelo ponto de exclamacao (!). Por exemplo:" + #CRLF$ +
    "  -5.007E3" + #CRLF$ +
    "  417.31!" + #CRLF$ +
    "Se, na notacao de ponto flutuante, for usada a letra D ao inves do E, ou se a constante for " +
    "seguida de (#), ela e de precisao dupla. Por exemplo:" + #CRLF$ +
    "  2.71838183D-19" + #CRLF$ +
    "  3.141592#" + #CRLF$ +
    "Se nada disso for indicado, o BASIC MSX interpretara a constante como sendo de precisao " +
    "dupla.",
    17)

  MSXManual_Add("Variaveis", "Parte I - A Estrutura do BASIC MSX",
    "Variaveis sao nomes que podem ser atribuidos ou associados a resultados de calculos feitos " +
    "nos programas." + #CRLF$ + #CRLF$ +
    "O nome correspondente a uma variavel podera ser de qualquer tamanho, sendo que so os dois " +
    "primeiros caracteres sao significativos. Este nome pode conter letras e numeros, porem o " +
    "primeiro caractere deve ser sempre alfabetico." + #CRLF$ + #CRLF$ +
    "Uma variavel nao pode ter um nome igual ao de um comando BASIC; isto inclui todos os " +
    "comandos, os termos, os nomes das funcoes e as operacoes." + #CRLF$ + #CRLF$ +
    "TIPOS DE VARIAVEIS: Assim como as constantes, as variaveis tambem podem ser alfanumericas " +
    "(cujo nome deve sempre terminar por $) e numericas." + #CRLF$ + #CRLF$ +
    "As variaveis numericas sao de 3 tipos e tambem podem ser distinguidas pelo ultimo caractere " +
    "do nome:" + #CRLF$ +
    "- Variaveis inteiras (%): sao aquelas que so podem conter valores inteiros. Por exemplo, Z%." + #CRLF$ +
    "- Variaveis de precisao simples (!): sao aquelas que possuem valores com ate 6 digitos " +
    "significativos. Exemplo: PRECO!." + #CRLF$ +
    "- Variaveis de precisao dupla (#): sao variaveis que possuem valores com ate 14 algarismos " +
    "significativos. Exemplo: PI#." + #CRLF$ + #CRLF$ +
    "Quando o nome de variavel nao termina por nenhum destes caracteres especiais ($, %, !, #), o " +
    "BASIC MSX a interpreta como sendo numerica e de precisao dupla.",
    18)

  MSXManual_Add("Matrizes ou Variaveis Indexadas", "Parte I - A Estrutura do BASIC MSX",
    "Uma matriz e um conjunto de valores, todos associados a uma variavel de mesmo nome. Cada " +
    "elemento da matriz e subscrito por indices inteiros (ou representados por expressoes " +
    "inteiras). A quantidade de indices utilizados determina o numero de dimensoes da matriz e " +
    "nao pode superar 255. Por exemplo:" + #CRLF$ +
    "- A(20) - Elemento de uma matriz de uma dimensao" + #CRLF$ +
    "- C(20,3,14) - Elemento de uma matriz de tres dimensoes",
    18)

  MSXManual_Add("Ocupacao de Memoria", "Parte I - A Estrutura do BASIC MSX",
    "Cada string ocupa um numero de bytes igual ao numero de caracteres que ela contem, mais 3. " +
    "As variaveis numericas e cada elemento de matriz ocupam um numero de bytes conforme a lista " +
    "a seguir:" + #CRLF$ +
    "- Inteira: 2 bytes" + #CRLF$ +
    "- Precisao Simples: 4 bytes" + #CRLF$ +
    "- Precisao Dupla: 8 bytes",
    19)

  MSXManual_Add("Conversao de Precisao", "Parte I - A Estrutura do BASIC MSX",
    "Se o valor de uma constante numerica for atribuido a uma variavel string (ou vice-versa) " +
    "sera explicitada uma mensagem de erro " + MSXQ + "Type Mismatch" + MSXQ + "." + #CRLF$ + #CRLF$ +
    "Se o valor de uma constante numerica de um certo tipo for atribuido a variavel numerica de " +
    "tipo diferente, ele sera armazenado na memoria do computador na forma determinada pelo tipo " +
    "de variavel. Por exemplo, o programa:" + #CRLF$ +
    "10 Z%=257.8131#" + #CRLF$ +
    "20 PRINT Z%" + #CRLF$ +
    "dara como resultado:" + #CRLF$ +
    "257" + #CRLF$ +
    "Note que a parte decimal foi truncada sem arredondamento." + #CRLF$ + #CRLF$ +
    "Durante calculos, operandos de tipos diferentes serao todos convertidos para o tipo de maior " +
    "precisao, e nesse tipo sera fornecido o resultado." + #CRLF$ + #CRLF$ +
    "Os operadores logicos convertem seus operandos em inteiros. Se eles cairem fora da faixa " +
    "permitida aos inteiros, ocorrera erro (overflow).",
    19)

  ; Tabelas-verdade dos operadores logicos, representadas linha a linha
  ; (mesma convencao de listas usada no dicionario, ex. BASE/COLOR/DRAW).
  MSXManual_Add("Operadores", "Parte I - A Estrutura do BASIC MSX",
    "Os operadores agem sobre constantes e variaveis contidas numa expressao, de maneira a " +
    "produzir um valor unico como resultado. Eles podem ser divididos em quatro categorias: " +
    "ARITMETICOS, RELACIONAIS, LOGICOS, FUNCIONAIS." + #CRLF$ + #CRLF$ +
    "OPERADORES ARITMETICOS (na ordem de prioridade):" + #CRLF$ +
    "- ^ : Exponenciacao. Exemplo: X ^ Y" + #CRLF$ +
    "- - : Mudanca de sinal. Exemplo: -X" + #CRLF$ +
    "- * , / : Multiplicacao e Divisao. Exemplo: X * Y  /  X / Y" + #CRLF$ +
    "- \ : Divisao Inteira. Exemplo: X \ Y" + #CRLF$ +
    "- MOD : Resto da Divisao. Exemplo: X MOD Y" + #CRLF$ +
    "- + , - : Adicao e Subtracao. Exemplo: X + Y  /  X - Y" + #CRLF$ + #CRLF$ +
    "Para mudar a prioridade, ou seja, a ordem de execucao, devemos usar parenteses." + #CRLF$ +
    "Observacao: Note que \ e MOD transformam seus operandos em inteiros e fornecem resultados " +
    "inteiros, sendo que \ fornece o quociente e MOD o resto da divisao. Note tambem que o sinal " +
    "de adicao (+) pode ser usado para concatenar strings. Por exemplo:" + #CRLF$ +
    MSXQ + "GRADI" + MSXQ + " + " + MSXQ + "ENTE" + MSXQ + " = " + MSXQ + "GRADIENTE" + MSXQ + #CRLF$ + #CRLF$ +
    "OPERADORES RELACIONAIS: Estes operadores permitem comparacoes de valores:" + #CRLF$ +
    "- = : Igual. Exemplo: X = Y" + #CRLF$ +
    "- <> : Diferente. Exemplo: X<>Y" + #CRLF$ +
    "- < : Menor que. Exemplo: X < Y" + #CRLF$ +
    "- > : Maior que. Exemplo: X > Y" + #CRLF$ +
    "- <= : Menor ou igual. Exemplo: X <= Y" + #CRLF$ +
    "- >= : Maior ou igual. Exemplo: X >= Y" + #CRLF$ + #CRLF$ +
    "Observacao: Os operandos relacionados permitem tambem a comparacao de strings. Esta " +
    "comparacao e feita entre os codigos ASCII de seus caracteres." + #CRLF$ + #CRLF$ +
    "OPERADORES LOGICOS: Estes operadores permitem a manipulacao de bits, testes em relacoes " +
    "multiplas e operacoes de algebra booleana. Estao listados a seguir em ordem de prioridade, " +
    "com suas tabelas-verdade (1=verdadeiro, 0=falso):" + #CRLF$ + #CRLF$ +
    "NOT X:" + #CRLF$ +
    "- X=1 -> NOT X=0" + #CRLF$ +
    "- X=0 -> NOT X=1" + #CRLF$ + #CRLF$ +
    "X AND Y:" + #CRLF$ +
    "- X=1,Y=1 -> 1" + #CRLF$ +
    "- X=1,Y=0 -> 0" + #CRLF$ +
    "- X=0,Y=1 -> 0" + #CRLF$ +
    "- X=0,Y=0 -> 0" + #CRLF$ + #CRLF$ +
    "X OR Y:" + #CRLF$ +
    "- X=1,Y=1 -> 1" + #CRLF$ +
    "- X=1,Y=0 -> 1" + #CRLF$ +
    "- X=0,Y=1 -> 1" + #CRLF$ +
    "- X=0,Y=0 -> 0" + #CRLF$ + #CRLF$ +
    "X XOR Y:" + #CRLF$ +
    "- X=1,Y=1 -> 0" + #CRLF$ +
    "- X=1,Y=0 -> 1" + #CRLF$ +
    "- X=0,Y=1 -> 1" + #CRLF$ +
    "- X=0,Y=0 -> 0" + #CRLF$ + #CRLF$ +
    "X EQV Y:" + #CRLF$ +
    "- X=1,Y=1 -> 1" + #CRLF$ +
    "- X=1,Y=0 -> 0" + #CRLF$ +
    "- X=0,Y=1 -> 0" + #CRLF$ +
    "- X=0,Y=0 -> 1" + #CRLF$ + #CRLF$ +
    "X IMP Y:" + #CRLF$ +
    "- X=1,Y=1 -> 1" + #CRLF$ +
    "- X=1,Y=0 -> 0" + #CRLF$ +
    "- X=0,Y=1 -> 1" + #CRLF$ +
    "- X=0,Y=0 -> 1" + #CRLF$ + #CRLF$ +
    "Por exemplo, o resultado da instrucao:" + #CRLF$ +
    "PRINT 60 XOR 240" + #CRLF$ +
    "sera:" + #CRLF$ +
    "204" + #CRLF$ +
    "pois:" + #CRLF$ +
    "60 = &B 00111100" + #CRLF$ +
    "240 = &B 11110000" + #CRLF$ +
    "60 XOR 240 = &B 11001100 = 204" + #CRLF$ + #CRLF$ +
    "FUNCOES: O BASIC MSX tem funcoes residentes, ou seja, funcoes cuja tecnica de processamento " +
    "ja esta gravada no seu sistema operacional, tais como LOG (logaritmo), SIN (seno), CSRLIN " +
    "(cursor line), etc. Alem destas funcoes, o BASIC MSX admite outras concebidas pelo usuario. " +
    "Neste caso ele devera defini-las pela instrucao DEF FN.",
    19)

  ; Tabela de teclas de edicao (pagina 22), com codigo decimal/hex,
  ; combinacao de teclas, funcao e tecla especial correspondente.
  MSXManual_Add("Edicao de Programas", "Parte I - A Estrutura do BASIC MSX",
    "O BASIC MSX dispoe de um editor cuja funcao e escrever, alterar e armazenar as linhas " +
    "numeradas que constituem o programa. Este editor permite mover o cursor por toda a tela, " +
    "reescrever caracteres, apaga-los, inseri-los e armazenar linhas de BASIC na memoria." + #CRLF$ + #CRLF$ +
    "Uma linha de BASIC e aceita e armazenada na memoria se precedida por um numero inteiro " +
    "entre 0 e 65529 e se contiver pelo menos um caractere diferente do espaco. Para que ela seja " +
    "mandada para a memoria, apos terminar sua digitacao, devemos sempre teclar o RETURN." + #CRLF$ + #CRLF$ +
    "Se digitarmos uma nova linha com o numero de uma ja armazenada, ao teclarmos RETURN, a " +
    "segunda substitui a primeira, que e apagada. Isto ocorre tambem quando a nova linha tem so o " +
    "numero. Esta caracteristica pode ser usada para apagar linhas." + #CRLF$ + #CRLF$ +
    "Varias instrucoes podem ser colocadas numa mesma linha, desde que separadas por dois pontos " +
    "(:). O total de caracteres contidos na linha, porem, nao pode exceder 255." + #CRLF$ + #CRLF$ +
    "COMBINACOES DE TECLAS PARA EDICAO (codigo decimal / hex / combinacao / funcao / tecla " +
    "especial correspondente, quando existir):" + #CRLF$ +
    "- 02 / 02 / CONTROL + B: Move o cursor ate o comeco da palavra anterior" + #CRLF$ +
    "- 03 / 03 / CONTROL + C: Da um BREAK na espera do INPUT" + #CRLF$ +
    "- 05 / 05 / CONTROL + E: Apaga do cursor ao fim da linha BASIC" + #CRLF$ +
    "- 06 / 06 / CONTROL + F: Move o cursor ate o comeco da palavra seguinte" + #CRLF$ +
    "- 07 / 07 / CONTROL + G: Da um " + MSXQ + "bip" + MSXQ + #CRLF$ +
    "- 08 / 08 / CONTROL + H: Volta o cursor, apagando (tecla especial: BS)" + #CRLF$ +
    "- 09 / 09 / CONTROL + I: Move o cursor ate a proxima tabulacao (tecla especial: TAB)" + #CRLF$ +
    "- 10 / 0A / CONTROL + J: Coloca o cursor na proxima linha (line feed)" + #CRLF$ +
    "- 11 / 0B / CONTROL + K: Move o cursor ate o canto superior esquerdo (tecla especial: HOME)" + #CRLF$ +
    "- 12 / 0C / CONTROL + L: Limpa a tela colocando o cursor em HOME (tecla especial: CLS)" + #CRLF$ +
    "- 13 / 0D / CONTROL + M: Insere a linha BASIC na memoria (tecla especial: RETURN)" + #CRLF$ +
    "- 14 / 0E / CONTROL + N: Leva o cursor ao fim da linha" + #CRLF$ +
    "- 18 / 12 / CONTROL + R: Poe o cursor no modo insercao (tecla especial: INSERT)" + #CRLF$ +
    "- 21 / 15 / CONTROL + U: Apaga a linha interna (tecla especial: SELECT)" + #CRLF$ +
    "- 24 / 18 / CONTROL + X: (tecla especial: ESC)" + #CRLF$ + #CRLF$ +
    "Pressionando simultaneamente as teclas CONTROL + SHIFT + STOP, obtemos um RESET por " +
    "software, ou seja, o Expert reinicializa as variaveis do sistema, deixando-as no estado em " +
    "que se encontravam ao ligar o micro.",
    21)
EndProcedure

; --- Parte III - Aplicacoes Especiais (paginas 178-184 do livro = 175-181 do PDF) ---
Procedure MSXManual_BuildParteIII()
  MSXManual_Add("Interrupcoes", "Parte III - Aplicacoes Especiais",
    "A interrupcao para a execucao de um programa para executar uma sub-rotina chamada " +
    "normalmente de rotina de interrupcao." + #CRLF$ + #CRLF$ +
    "Quando desenvolvemos um jogo, por exemplo, e normal usarmos o comando ON STRIG GOSUB para " +
    "saber se os botoes do joystick foram pressionados." + #CRLF$ + #CRLF$ +
    "OS COMANDOS DE INTERRUPCAO NO MSX: O MSX dispoe de varios comandos de interrupcao. A tabela " +
    "a seguir mostra um resumo destas instrucoes:" + #CRLF$ +
    "- interrupcao quando se pressiona uma tecla de funcao -> ON KEY GOSUB" + #CRLF$ +
    "- interrupcao quando se pressiona a barra de espacos ou botoes dos joysticks -> ON STRIG GOSUB" + #CRLF$ +
    "- interrupcao quando se pressiona CTRL + STOP -> ON STOP GOSUB" + #CRLF$ + #CRLF$ +
    "Alem dessas instrucoes, que interrompem a execucao caso estas teclas sejam pressionadas, " +
    "existem mais dois comandos de interrupcao: ON SPRITE GOSUB, que interrompe o programa quando " +
    "duas figuras se sobrepoem, e ON INTERVAL GOSUB, que interrompe o programa em espacos " +
    "periodicos de tempo." + #CRLF$ + #CRLF$ +
    "TORNANDO AS INTERRUPCOES HABILITADAS: Para que a interrupcao realmente aconteca e " +
    "necessario que seja dado um comando que habilite (ligue) esta interrupcao. Estes comandos " +
    "sao:" + #CRLF$ +
    "KEY (X) ON" + #CRLF$ +
    "STRIG (X) ON" + #CRLF$ +
    "STOP ON" + #CRLF$ +
    "SPRITE ON" + #CRLF$ +
    "INTERVAL ON" + #CRLF$ + #CRLF$ +
    "EXEMPLIFICANDO ALGUMAS INTERRUPCOES: Digite o programa a seguir:" + #CRLF$ +
    "10 ON KEY GOSUB 100" + #CRLF$ +
    "20 KEY(1)ON" + #CRLF$ +
    "30 SCREEN 2" + #CRLF$ +
    "40 LINE(50,50)-(200,150),,B" + #CRLF$ +
    "50 GOTO 40" + #CRLF$ +
    "100 REM Sub-rotina" + #CRLF$ +
    "110 BEEP:CLS" + #CRLF$ +
    "120 FORI=1 TO 90 STEP 10" + #CRLF$ +
    "130 CIRCLE(120,100),I" + #CRLF$ +
    "140 NEXT I" + #CRLF$ +
    "150 CLS" + #CRLF$ +
    "160 RETURN" + #CRLF$ + #CRLF$ +
    "Este programa depois de rodado desenhara na tela um retangulo. Caso seja pressionada a " +
    "tecla F1 o programa se desviara para a linha 100 devido a sentenca das instrucoes de " +
    "interrupcoes nas linhas 10 e 20. Na sub-rotina que comeca na linha 100 ele desenhara nove " +
    "circulos concentricos, e depois retornara para a linha 40, onde novamente o retangulo sera " +
    "desenhado." + #CRLF$ + #CRLF$ +
    "Agora pressione duas vezes seguidas a tecla F1 e verifique o que aconteceu. Voce notou que " +
    "quando foi pressionada a tecla F1 pela segunda vez, a sub-rotina de interrupcao nao parou, e " +
    "a nova interrupcao so foi feita quando a sub-rotina acabou de ser executada." + #CRLF$ + #CRLF$ +
    "Vejamos duas variacoes deste mesmo programa. Acrescente a linha:" + #CRLF$ +
    "105 KEY(1) OFF" + #CRLF$ +
    "Execute novamente o programa e pressione a tecla F1. Agora pressione-a de novo. Voce " +
    "percebe que a interrupcao so foi executada uma vez. Isto acontece porque quando e causada a " +
    "primeira interrupcao o programa executa a linha 105 que desabilitara as proximas execucoes." + #CRLF$ + #CRLF$ +
    "Como uma segunda variacao acrescente ao programa a linha:" + #CRLF$ +
    "105 KEY(1) ON" + #CRLF$ +
    "Com esta modificacao, toda vez que for pressionada a tecla F1, sera executada a sub-rotina " +
    "de interrupcao. Mesmo que ela ja esteja sendo executada, sera desviada para seu inicio. Isto " +
    "ocorre porque a linha 105, neste caso, reabilita uma nova interrupcao.",
    178)

  MSXManual_Add("Processo de Arquivo", "Parte III - Aplicacoes Especiais",
    "Um arquivo e uma regiao da memoria onde podem ser armazenados dados, que possam ser " +
    "constantemente atualizados." + #CRLF$ + #CRLF$ +
    "Um bom exemplo seria um DIARIO pessoal. Ele e manuseado constantemente e, alem de guardar " +
    "dados do dia, pode ser consultado tambem sobre registros anteriores." + #CRLF$ + #CRLF$ +
    "No MSX existem comandos que fazem exatamente isto. Antes, porem, vejamos o que e necessario " +
    "para montar este sistema." + #CRLF$ + #CRLF$ +
    "Para se escrever no arquivo, serao necessarios os chamados dispositivos de saida (video, " +
    "impressora, gravador) e para consultar um arquivo precisamos dos dispositivos de entrada " +
    "(gravador). O gravador funciona tanto como dispositivo de entrada, como saida, pois nele " +
    "podemos ler e escrever dados. Todas estas entradas e saidas sao controladas pelo " +
    "microprocessador que se encontra dentro das UCP." + #CRLF$ + #CRLF$ +
    "Cada um desses dispositivos tem uma abreviatura que sera usada quando forem dados os " +
    "comandos de leitura e gravacao de dados. Estas abreviaturas sao:" + #CRLF$ +
    "- gravador cassete -> CAS:" + #CRLF$ +
    "- tela modo texto -> CRT:" + #CRLF$ +
    "- tela modo grafico -> GRP:" + #CRLF$ +
    "- impressora -> LPT:" + #CRLF$ + #CRLF$ +
    "Os nomes dos arquivos podem conter, no maximo, 6 caracteres (os excedentes serao " +
    "desprezados)." + #CRLF$ + #CRLF$ +
    "Os comandos para abrir, ler, gravar e fechar um arquivo sao:" + #CRLF$ +
    "- OPEN -> abre um arquivo" + #CRLF$ +
    "- PRINT# -> escreve no arquivo" + #CRLF$ +
    "- PRINT# USING -> escreve no arquivo" + #CRLF$ +
    "- INPUT# -> le um arquivo" + #CRLF$ +
    "- LINE INPUT# -> le um arquivo" + #CRLF$ +
    "- CLOSE -> fecha arquivo" + #CRLF$ + #CRLF$ +
    "GRAVACAO DE DADOS DE UM ARQUIVO: Para gravar dados de um arquivo, deve-se proceder da " +
    "seguinte maneira:" + #CRLF$ +
    "1) Abre-se o arquivo com a instrucao OPEN." + #CRLF$ +
    "2) Escrevem-se os dados com a instrucao PRINT#." + #CRLF$ +
    "3) Fecha-se o arquivo com a instrucao CLOSE." + #CRLF$ + #CRLF$ +
    "O formato da instrucao OPEN para a gravacao de dados e:" + #CRLF$ +
    "OPEN " + MSXQ + "abreviatura do dispositivo nome do arquivo" + MSXQ + " FOR OUTPUT AS [#] numero do arquivo" + #CRLF$ + #CRLF$ +
    "Quando se executa isto, estabelece-se que um arquivo sera gravado no dispositivo indicado. " +
    "Quando o MSX esta lendo ou escrevendo um arquivo, antes de armazena-los, passa os dados para " +
    "uma memoria intermediaria (buffer). O MSX contem 16 buffers. O numero do arquivo determina " +
    "em qual buffer serao armazenados provisoriamente os dados." + #CRLF$ + #CRLF$ +
    "Depois de aberto o arquivo, com a instrucao OPEN, devem-se escrever os dados com a instrucao " +
    "PRINT# que tem o seguinte formato:" + #CRLF$ +
    "PRINT# numero do arquivo, expressao [, expressao ...]" + #CRLF$ + #CRLF$ +
    "O numero do arquivo deve ser o mesmo que consta da instrucao OPEN. Depois de gravados os " +
    "dados, sera automaticamente gravado um codigo de " + MSXQ + "carriage return" + MSXQ + " (&H0D) e um " +
    MSXQ + "line feed" + MSXQ + " (&H0A), para que os dados escritos sejam separados." + #CRLF$ + #CRLF$ +
    "Um exemplo de como usar a instrucao PRINT# pode ser o seguinte:" + #CRLF$ +
    "PRINT#1,A$;" + MSXQ + "," + MSXQ + ";B$" + #CRLF$ + #CRLF$ +
    "A virgula entre aspas indica que a variavel A$ deve ser separada da B$." + #CRLF$ + #CRLF$ +
    "Finalmente, para fechar o arquivo voce deve digitar a instrucao CLOSE da seguinte maneira:" + #CRLF$ +
    "CLOSE [#] numero do arquivo" + #CRLF$ + #CRLF$ +
    "LEITURA DE DADOS DE UM ARQUIVO: Para se ler um arquivo deve-se proceder da seguinte maneira:" + #CRLF$ +
    "1) Abre-se o arquivo com a instrucao OPEN." + #CRLF$ +
    "2) Le-se o arquivo com a instrucao INPUT#." + #CRLF$ +
    "3) Fecha-se o arquivo com a instrucao CLOSE." + #CRLF$ + #CRLF$ +
    "O formato da instrucao OPEN para leitura de dados e o seguinte:" + #CRLF$ +
    "OPEN " + MSXQ + "abreviatura do dispositivo nome do arquivo" + MSXQ + " FOR INPUT AS [#] numero do arquivo" + #CRLF$ + #CRLF$ +
    "Depois de aberto o arquivo com a instrucao OPEN, os dados devem ser lidos com a instrucao " +
    "INPUT#, da seguinte maneira:" + #CRLF$ +
    "INPUT# numero do arquivo, variavel" + #CRLF$ + #CRLF$ +
    "Finalmente, deve-se fechar o arquivo com a instrucao CLOSE.",
    180)

  ; CONFERIR: o bloco DATA (linhas 15-85) foi transcrito diretamente da
  ; pagina 184 (relida uma segunda vez para maior confianca) e tem alto
  ; risco de erro pontual de OCR em digitos numericos isolados - conferir
  ; contra o livro se for realmente executar esta sub-rotina em Z80. A
  ; secao de codigo BASIC entre as linhas 135-195 tambem ficou com uma
  ; provavel inconsistencia (a variavel B$ e usada nas linhas 145-170 sem
  ; uma atribuicao visivel a partir de N$(F) - possivel linha perdida na
  ; digitalizacao/OCR da pagina original).
  MSXManual_Add("Sub-rotinas em Linguagem de Maquina", "Parte III - Aplicacoes Especiais",
    "O microprocessador utilizado pelos micros da linha MSX e o Z-80A, para o qual podemos " +
    "escrever programas em linguagem de maquina. Atraves de instrucoes do BASIC pode-se tambem " +
    "transferir valores para esse programa e iniciar sua execucao. Se for necessario e possivel " +
    "voltar ao BASIC, atraves da instrucao RET (return) do Z-80." + #CRLF$ + #CRLF$ +
    "PREPARANDO UM PROGRAMA EM LINGUAGEM DE MAQUINA:" + #CRLF$ + #CRLF$ +
    "1. Limpe uma area da memoria para colocar seu programa em LM usando o comando:" + #CRLF$ +
    "CLEAR n, endereco" + #CRLF$ +
    "Por exemplo:" + #CRLF$ +
    "10 CLEAR 200,&HDFFF" + #CRLF$ +
    "No exemplo foram reservados 200 bytes de memoria." + #CRLF$ + #CRLF$ +
    "2. Coloque o programa na memoria atraves do comando:" + #CRLF$ +
    "POKE (endereco), byte" + #CRLF$ +
    "Por exemplo:" + #CRLF$ +
    "20 POKE &HDFFF,&HCD" + #CRLF$ +
    "30 POKE &HE000,&HC3" + #CRLF$ +
    "40 POKE &HE001,&H0" + #CRLF$ +
    "50 POKE &HE002,&HC9" + #CRLF$ +
    "No exemplo, o programa e constituido pelas instrucoes CALL (&HCD), pelo endereco &H00C3 " +
    "(&HC3,&H00 - o byte menos significativo vem antes) e por um RETurn (&HC9)." + #CRLF$ + #CRLF$ +
    "3. Defina o ponto de entrada (onde o Z-80 deve iniciar a execucao do programa), utilizando " +
    "o comando:" + #CRLF$ +
    "DEFUSR n = endereco" + #CRLF$ +
    "Por exemplo:" + #CRLF$ +
    "DEFUSR 1 = &HDFFF" + #CRLF$ +
    "O BASIC-MSX permite definir 10 pontos de entrada diferentes, o que significa que podemos " +
    "chamar 10 sub-rotinas diferentes em linguagem de maquina a partir do programa em BASIC. No " +
    "exemplo definiu-se como inicio da sub-rotina 1, o endereco &HDFFF." + #CRLF$ + #CRLF$ +
    "4. Execute a sub-rotina atraves do comando:" + #CRLF$ +
    "X = USRn (I)" + #CRLF$ +
    "Por exemplo:" + #CRLF$ +
    "40 X = USR1(I)" + #CRLF$ +
    "Este programa em BASIC coloca na memoria do computador um programa em LM que chama uma " +
    "sub-rotina da ROM que limpa a tela. Esta sub-rotina esta no endereco &H00C3." + #CRLF$ + #CRLF$ +
    "PASSANDO VALORES PARA A SUB-ROTINA EM LM: Quando for preciso enviar um valor a uma " +
    "sub-rotina em LM utiliza-se a forma:" + #CRLF$ +
    "Variavel=USR n(I)" + #CRLF$ + #CRLF$ +
    "O valor enviado sera I e se houver valor para retornar ao BASIC este sera atribuido a " +
    "variavel. Se fizermos:" + #CRLF$ +
    "X = USR1(I)" + #CRLF$ + #CRLF$ +
    "Os dados que indicam o tipo e o valor da variavel utilizada sao armazenados na memoria de " +
    "acordo com a tabela a seguir, e o endereco do comeco da area de armazenamento e indicada " +
    "pelo registro HL. O dado no registro A tambem e armazenado no endereco &HF663." + #CRLF$ + #CRLF$ +
    "TIPO DE I / REGISTRO A / REGISTROS HL / ENDERECO ONDE E ARMAZENADO O VALOR DE I:" + #CRLF$ +
    "- dupla precisao: A=8, HL=&HF7F6, enderecos &HF7F6-&HF7FD" + #CRLF$ +
    "- precisao simples: A=4, HL=&HF7F6, enderecos &HF7F6-&HF7F9" + #CRLF$ +
    "- inteiro: A=2, HL=&HF7F6, enderecos &HF7F8-&HF7F9" + #CRLF$ + #CRLF$ +
    "Se a variavel for uma string: REGISTRO A=3, REGISTROS DE=endereco do ponteiro da string, " +
    "PONTEIRO DA STRING: 1 byte=comprimento da string, 2 e 3 bytes=endereco onde a variavel esta " +
    "armazenada." + #CRLF$ + #CRLF$ +
    "Terminada a sub-rotina, o valor obtido sera atribuido a variavel X e a memoria, e os " +
    "registros ficarao organizados assim:" + #CRLF$ +
    "TIPO DE RESULTADO / ENDERECO &HF633 / REGISTROS DE / REGISTROS HL / ENDERECO ONDE O " +
    "RESULTADO E ARMAZENADO:" + #CRLF$ +
    "- precisao dupla: 8, (nenhum), &HF7F6, &HF7F6-&HF7FD" + #CRLF$ +
    "- precisao simples: 4, (nenhum), &HF7F6, &HF7F6-&HF7F9" + #CRLF$ +
    "- inteiro: 2, (nenhum), &HF7F6, &HF7F8-&HF7F9" + #CRLF$ +
    "- string: 3, endereco do ponteiro da string, &HF7F6, endereco indicado pelos 2 e 3 bytes do " +
    "ponteiro da string" + #CRLF$ + #CRLF$ +
    "EXEMPLO (ORDENADOR EM LINGUAGEM DE MAQUINA - ordena nomes digitados pelo usuario usando uma " +
    "sub-rotina em linguagem de maquina; ver nota CONFERIR acima sobre risco de erro de " +
    "transcricao neste listing):" + #CRLF$ +
    "5 REM ORDENADOR EM LINGUAGEM DE MAQUINA" + #CRLF$ +
    "10 '                DADOS" + #CRLF$ +
    "15 DATA 035,035,094,035,086,213,221,225" + #CRLF$ +
    "20 DATA 221,094,254,221,006,255,027,221" + #CRLF$ +
    "25 DATA 229,221,070,000,078,003,221" + #CRLF$ +
    "30 DATA 110,004,221,102,005,229,253,225" + #CRLF$ +
    "35 DATA 126,221,110,001,221,102,150" + #CRLF$ +
    "40 DATA 056,014,032,058,005,040,055,013" + #CRLF$ +
    "45 DATA 040,000,035,253,035,253,126,000" + #CRLF$ +
    "50 DATA 024,237,221,043,221,043,043" + #CRLF$ +
    "55 DATA 221,126,006,221,070,003,221,043" + #CRLF$ +
    "60 DATA 006,221,119,003,221,126,004" + #CRLF$ +
    "65 DATA 070,004,221,112,007,221,119,004" + #CRLF$ +
    "70 DATA 221,126,221,119,005,221,043" + #CRLF$ +
    "75 DATA 008,221,007,005,024,171,225,027" + #CRLF$ +
    "80 DATA 221,035,221,035,221,027,225,027,122" + #CRLF$ +
    "85 DATA 179,032,156,201" + #CRLF$ +
    "90 '           INICIO DO PROCESSAMENTO" + #CRLF$ +
    "95 CLEAR 6000,&HF000:DEFINT A-Z" + #CRLF$ +
    "100 DEFUSR=&HF000" + #CRLF$ +
    "105 INPUT" + MSXQ + "Quantos nomes serao inseridos" + MSXQ + ";N:DIM N$(N)" + #CRLF$ +
    "110 '        INSERE OS CODIGOS DAS LINHAS DATA NOS BYTES ESPECIFICADOS" + #CRLF$ +
    "115 FOR F=0 TO &H73" + #CRLF$ +
    "120 READ D:POKE &HF000+F,D" + #CRLF$ +
    "125 NEXT F" + #CRLF$ +
    "130 '        RECEBE OS NOMES A SEREM ORDENADOS ATRAVES DO TECLADO" + #CRLF$ +
    "135 FOR F=1 TO N: F$=STR$(F)" + #CRLF$ +
    "140 PRINT" + MSXQ + "Qual o " + MSXQ + ";F$;CHR$(&HF8);" + MSXQ + ") nome" + MSXQ + ";:INPUT N$(F)" + #CRLF$ +
    "145 FOR G=1 TO LEN(B$)" + #CRLF$ +
    "150 C$=MID$(B$,G,1):C=ASC(C$)" + #CRLF$ +
    "155 IF C<97 THEN C=C+32:C$=CHR$(C)" + #CRLF$ +
    "160 MID$(B$,G,1)=C$" + #CRLF$ +
    "165 NEXT G" + #CRLF$ +
    "170 MID$(B$,1,1)=CHR$(ASC(LEFT$(B$,1))-32):N$(F)=B$" + #CRLF$ +
    "175 NEXT F" + #CRLF$ +
    "180 '        INICIA A ORDENACAO" + #CRLF$ +
    "185 N$(0)=" + MSXQ + " " + MSXQ + "+CHR$(1):E=VARPTR(N$(0))" + #CRLF$ +
    "190 PRINT " + MSXQ + "INICIO !" + MSXQ + ":TIME=0" + #CRLF$ +
    "195 E=USR(E):T=TIME" + #CRLF$ +
    "200 FOR F=1 TO N" + #CRLF$ +
    "205 PRINT F;N$(F)" + #CRLF$ +
    "210 NEXT F" + #CRLF$ +
    "215 PRINT:PRINT:PRINT" + MSXQ + "Tempo de processamento" + MSXQ + #CRLF$ +
    "220 PRINT INT(1000000#*T/60);" + MSXQ + "micro-segundos" + MSXQ + #CRLF$ +
    "225 END",
    182)
EndProcedure

; --- Parte IV - Apendices (paginas 186-207 do livro = 183-204 do PDF) ---
; So os apendices pedidos: A (ASCII), C (codigos de erro), D (mapa da
; memoria) e I (funcoes trigonometricas/hiperbolicas). B-Impressora,
; E-Especificacoes Tecnicas, F-Pinagem, G-Teclados e H-Glossario ficaram
; de fora (nao pedidos).
Procedure MSXManual_BuildApendices()
  ; A tabela da pagina 186 e uma grade grafica de 256 celulas (16
  ; linhas x 16 colunas em hexadecimal); a faixa imprimivel 20-7E bate
  ; com o ASCII padrao e e reproduzida por extenso abaixo. As faixas
  ; 00-1F (simbolos graficos/controle) e 80-FF (caracteres acentuados,
  ; letras gregas e simbolos matematicos, especificos da fonte MSX) sao
  ; descritas de forma resumida em vez de char-a-char, para nao arriscar
  ; erro de transcricao de glifos especiais a partir da imagem escaneada
  ; - ver a pagina 186 do livro para a grade grafica completa.
  MSXManual_Add("Apendice A - Caracteres ASCII", "Parte IV - Apendices",
    "A tabela fornece o codigo hexadecimal dos 256 caracteres armazenados na memoria ROM do " +
    "Expert. Para obter um determinado codigo, le-se primeiro a linha e depois a coluna. Por " +
    "exemplo, o caractere L corresponde ao codigo ASCII 4C (em hexadecimal)." + #CRLF$ + #CRLF$ +
    "FAIXA 00-1F (codigos de controle): no MSX, esta faixa nao mostra caracteres de controle " +
    "invisiveis como no ASCII padrao, e sim simbolos graficos especiais (carinhas, naipes de " +
    "baralho, setas, simbolos de genero, notas musicais, etc.) usados sobretudo em jogos e telas " +
    "decorativas." + #CRLF$ + #CRLF$ +
    "FAIXA 20-7E (caracteres imprimiveis, identica ao ASCII padrao):" + #CRLF$ +
    "20=(espaco) 21=! 22=" + MSXQ + " 23=# 24=$ 25=% 26=& 27=' 28=( 29=) 2A=* 2B=+ 2C=, 2D=- " +
    "2E=. 2F=/" + #CRLF$ +
    "30=0 31=1 32=2 33=3 34=4 35=5 36=6 37=7 38=8 39=9 3A=: 3B=; 3C=< 3D== 3E=> 3F=?" + #CRLF$ +
    "40=@ 41=A 42=B 43=C 44=D 45=E 46=F 47=G 48=H 49=I 4A=J 4B=K 4C=L 4D=M 4E=N 4F=O" + #CRLF$ +
    "50=P 51=Q 52=R 53=S 54=T 55=U 56=V 57=W 58=X 59=Y 5A=Z 5B=[ 5C=\ 5D=] 5E=^ 5F=_" + #CRLF$ +
    "60=` 61=a 62=b 63=c 64=d 65=e 66=f 67=g 68=h 69=i 6A=j 6B=k 6C=l 6D=m 6E=n 6F=o" + #CRLF$ +
    "70=p 71=q 72=r 73=s 74=t 75=u 76=v 77=w 78=x 79=y 7A=z 7B={ 7C=| 7D=} 7E=~" + #CRLF$ + #CRLF$ +
    "FAIXA 7F: caractere grafico especial (nao e DEL/apagar como no ASCII padrao)." + #CRLF$ + #CRLF$ +
    "FAIXA 80-FF (caracteres internacionais e graficos): contem vogais e consoantes acentuadas " +
    "(a exemplo de C-cedilha, U-trema e as vogais com til/acento/circunflexo usadas em portugues), " +
    "fracoes (1/2, 1/4), sinais de pontuacao invertidos (¡, ¿), caracteres de desenho de caixas e " +
    "blocos solidos/sombreados, e letras gregas e simbolos matematicos usados em ciencia " +
    "(alfa, beta, gama, pi, sigma, mi/micro, tau, phi, teta, omega, delta, infinito, raiz " +
    "quadrada, graus, mais-ou-menos, maior-ou-igual, menor-ou-igual, integral). Ver a grade " +
    "grafica completa na pagina 186 para o glifo exato de cada codigo desta faixa.",
    186)

  ; 36 mensagens de erro do BASIC MSX (nome original em ingles, traducao
  ; do livro, e explicacao) - lista completa da pagina 188 a 191.
  MSXManual_Add("Apendice C - Codigos de Erro", "Parte IV - Apendices",
    "Lista completa das mensagens de erro do BASIC MSX (nome original em ingles, como aparece na " +
    "tela, e a explicacao dada pelo livro):" + #CRLF$ + #CRLF$ +
    "- Bad file name (Nome Incorreto para Arquivo): Uma forma ilegal foi usada para o nome do " +
    "arquivo com: LOAD, SAVE, KILL, NAME, etc." + #CRLF$ + #CRLF$ +
    "- Bad file number (Problemas com Numero de Arquivo): Ha um termo, ou comando, referente a um " +
    "numero de arquivo, o qual nao esta aberto (OPEN). Ou entao, ele esta fora do alcance dos " +
    "numeros de arquivo especificados pelo termo MAXFILES." + #CRLF$ + #CRLF$ +
    "- Can't continue (Impossibilidade de Continuar): Foi feita uma tentativa de continuar um " +
    "programa, o qual: 1. Parou devido a um erro; 2. Tenta ser modificado durante uma parada na " +
    "execucao; 3. Ou, simplesmente, nao existe continuacao." + #CRLF$ + #CRLF$ +
    "- Device I/O error (Erro no Dispositivo de I/O): Ocorreu um erro de I/O (Input/Output) no " +
    "cassete, na impressora ou na operacao de CRT; ou seja, ha um erro na entrada ou saida de " +
    "dados. Este erro e fatal e isso significa que o BASIC nao pode encontra-lo." + #CRLF$ + #CRLF$ +
    "- Direct statement in file (Termo no Modo Direto foi Encontrado no Arquivo): Um termo foi " +
    "encontrado carregando um arquivo no formato ASCII. O LOAD foi terminado." + #CRLF$ + #CRLF$ +
    "- Division by zero (Divisao por Zero): Uma divisao por zero foi encontrada em uma " +
    "expressao." + #CRLF$ + #CRLF$ +
    "- FIELD overflow (Overflow em FIELD): Tentativa de inserir um FIELD num espaco muito " +
    "pequeno de bytes." + #CRLF$ + #CRLF$ +
    "- File already open (Arquivo Ja Aberto): Uma saida sequencial, no modo OPEN, foi o resultado " +
    "de arquivo que ja havia sido aberto ou, entao, um termo KILL abrindo o mesmo tipo de " +
    "arquivo." + #CRLF$ + #CRLF$ +
    "- File not found (Arquivo Nao Encontrado): Ha um termo LOAD, KILL ou OPEN referente a um " +
    "arquivo, que nao existe na memoria." + #CRLF$ + #CRLF$ +
    "- File not open (Arquivo Nao Aberto): O arquivo especificado em um termo PRINT#, INPUT#, " +
    "etc, nao havia sido aberto." + #CRLF$ + #CRLF$ +
    "- Illegal direct (Modo Direto Usado Ilegalmente): Um comando que e usado no modo indireto " +
    "foi introduzido no modo direto." + #CRLF$ + #CRLF$ +
    "- Illegal function call (Funcao Ilegal): Tentativa de executar uma operacao usando um " +
    "parametro ilegal." + #CRLF$ + #CRLF$ +
    "- INPUT past end (INPUT Depois do Final): Um termo INPUT foi executado depois de todos os " +
    "dados de um arquivo (ou arquivo nulo) serem lidos. Evita-se este erro usando a funcao EOF " +
    "para encontrar o final do arquivo." + #CRLF$ + #CRLF$ +
    "- Internal error (Erro Interno): Mau funcionamento interno." + #CRLF$ + #CRLF$ +
    "- Line buffer overflow (Linha do Buffer em Overflow): Uma linha introduzida possui " +
    "caracteres demais." + #CRLF$ + #CRLF$ +
    "- Missing operand (Falta de Operando): Tentativa de operacao sem o fornecimento de um dos " +
    "operandos necessarios." + #CRLF$ + #CRLF$ +
    "- NEXT without FOR (NEXT sem FOR): Comando NEXT utilizado sem uma instrucao FOR " +
    "correspondente." + #CRLF$ + #CRLF$ +
    "- No RESUME (Falta RESUME): Um erro encontrado na rotina foi introduzido porem, nao contem " +
    "o termo RESUME." + #CRLF$ + #CRLF$ +
    "- Out of DATA (Insuficiencia de Dados): Uma instrucao READ foi executada sem encontrar " +
    "nenhum dado para ler." + #CRLF$ + #CRLF$ +
    "- Out of memory (Insuficiencia de Memoria): Toda memoria disponivel foi utilizada ou " +
    "reservada." + #CRLF$ + #CRLF$ +
    "- Out of string space (Fora do Espaco para String): O espaco reservado para as variaveis " +
    "strings foi excedido na memoria." + #CRLF$ + #CRLF$ +
    "- Overflow (Sobrecarga): A magnitude de um numero e muito grande para o computador." + #CRLF$ + #CRLF$ +
    "- Redimensioned array (Redimensionamento): Dois termos DIM foram usados para dimensionar a " +
    "mesma matriz." + #CRLF$ + #CRLF$ +
    "- RESUME without error (RESUME sem Erro): Um termo RESUME foi encontrado antes de um erro " +
    "colocado na rotina." + #CRLF$ + #CRLF$ +
    "- RETURN without GOSUB (RETURN sem GOSUB): Uma instrucao RETURN foi encontrada sem que um " +
    "GOSUB fosse executado antes." + #CRLF$ + #CRLF$ +
    "- Sequential I/O only (Somente Entrada/Saida Sequencial): Um termo de acesso randomico esta " +
    "distribuindo o arquivo de forma sequencial." + #CRLF$ + #CRLF$ +
    "- String formula too complex (Formula de String Muito Complexa): Uma expressao string esta " +
    "muito longa ou muito complexa. A expressao deve ser dividida em expressoes menores." + #CRLF$ + #CRLF$ +
    "- String too long (String Muito Longa): Tentativa de criar uma string com mais de 255 " +
    "caracteres." + #CRLF$ + #CRLF$ +
    "- Subscript out of range (Sub-indice Fora de Faixa): Tentativa de usar um indice nao " +
    "definido para uma variavel indexada." + #CRLF$ + #CRLF$ +
    "- Syntax error (Erro de Sintaxe): Ocorre quando uma palavra do vocabulario BASIC e escrita " +
    "de forma incorreta ou quando se faz uso indevido da pontuacao." + #CRLF$ + #CRLF$ +
    "- Type mismatch (Atribuicao Ilegal): Para um nome de uma variavel string foi atribuido um " +
    "valor, ou vice-versa. Para uma funcao, que aguarda um argumento numerico foi dado um " +
    "argumento string, ou vice-versa." + #CRLF$ + #CRLF$ +
    "- Undefined line number (Numero de Linha Nao Definido): Uma linha contendo um GOTO, GOSUB, " +
    "IF...THEN...ELSE, esta se referindo a outra linha que e inexistente." + #CRLF$ + #CRLF$ +
    "- Undefined user function (Uso Indefinido da Funcao): A funcao FN foi chamada antes de ser " +
    "definida pela instrucao DEF FN." + #CRLF$ + #CRLF$ +
    "- Unprintable error (23) (Erro Nao Imprimivel): Nao ha mensagem de erro disponivel para a " +
    "condicao existente. Isto geralmente acontece quando uma mensagem ERROR aparecer, para um " +
    "codigo de erro invalido ou indefinido." + #CRLF$ + #CRLF$ +
    "- Unprintable error (Erros Nao Imprimiveis): Estes codigos nao tem definicao. Devem ser " +
    "reservados para futuras expansoes do BASIC." + #CRLF$ + #CRLF$ +
    "- Unprintable error (60-255) (Erro Nao Imprimivel): Estes codigos nao possuem definicao. " +
    "Costuma-se usa-los para definir codigos pessoais de erro." + #CRLF$ + #CRLF$ +
    "- Verify error (Erro de Verificacao): O programa que esta sendo executado nao esta coerente " +
    "com o programa gravado no cassete.",
    188)

  MSXManual_Add("Apendice D - Mapa da Memoria", "Parte IV - Apendices",
    "O Expert possui 32 Kbytes de memoria ROM (pre-gravada na fabrica, apenas para leitura) e 80 " +
    "Kbytes de memoria RAM (para escrita e leitura). O microprocessador Z80-A pode acessar " +
    "diretamente 64 Kbytes de memoria RAM e e em parte dessa area que o usuario pode trabalhar. " +
    "Outros 16 Kbytes (VRAM) sao acessados pelo microprocessador TMS9128NL, especifico para " +
    "controlar o video." + #CRLF$ + #CRLF$ +
    "Tanto a ROM como a RAM sao divididas em paginas para agilizar o acesso aos seus enderecos. " +
    "Cada pagina de memoria tem 16 Kbytes." + #CRLF$ + #CRLF$ +
    "A numeracao dos enderecos da ROM e sempre a mesma, independentemente de se estar ou nao " +
    "usando expansoes, interfaces ou cartuchos. Ela se sobrepoe a parte da numeracao da RAM e e " +
    "por isso que apenas 28,8 Kbytes desta podem ser acessados diretamente pelo BASIC." + #CRLF$ + #CRLF$ +
    "O MSX possui quatro slots, sendo dois internos (0 e 2) e dois externos (1 e 3). Os dois " +
    "slots internos sao ocupados pela ROM (slot 0) e pela RAM (slot 2). Os slots externos podem " +
    "ser conectados a cartuchos, interfaces, etc." + #CRLF$ + #CRLF$ +
    "O slot 1 tem prioridade sobre o slot 3, isto e, se existir um cartucho ligado em cada um " +
    "deles, prevalecera a operacao do que esta no slot 1. A conexao do slot 1 e a marcada com " +
    "CARTRIDGE A. O slot 3 possui duas conexoes: uma dianteira marcada com CARTRIDGE B e outra " +
    "traseira marcada com BUS EXPANSION. Salvo indicacao em contrario, eles nao devem ser " +
    "utilizados simultaneamente." + #CRLF$ + #CRLF$ +
    "MAPA DA MEMORIA (4 paginas de 16K, slots 0-3):" + #CRLF$ +
    "- pagina 3: slot 0=(vazio), slot 1=(vazio - CARTRIDGE A), slot 2=RAM USUARIO BASIC, " +
    "slot 3=(vazio - BUS EXPANSION)" + #CRLF$ +
    "- pagina 2: slot 0=(vazio), slot 1=(vazio - CARTRIDGE A), slot 2=RAM USUARIO BASIC, " +
    "slot 3=(vazio - BUS EXPANSION)" + #CRLF$ +
    "- pagina 1: slot 0=ROM, slot 1=(vazio - CARTRIDGE A), slot 2=RAM USUARIO, slot 3=(vazio - " +
    "BUS EXPANSION)" + #CRLF$ +
    "- pagina 0: slot 0=ROM, slot 1=(vazio - CARTRIDGE A), slot 2=RAM USUARIO, slot 3=(vazio - " +
    "BUS EXPANSION)" + #CRLF$ + #CRLF$ +
    "A RAM acessivel pelo usuario que programa em BASIC e constituida pelas duas paginas " +
    "superiores do slot 2 (paginas 2 e 3, 32K no total). As duas paginas inferiores podem ser " +
    "acessadas mudando-se o status do PPI (veja APROFUNDANDO-SE NO MSX, da mesma editora, para " +
    "maiores detalhes)." + #CRLF$ + #CRLF$ +
    "DISTRIBUICAO DA RAM (usuario BASIC, slot 2, do endereco alto &HFFFF ao baixo &H8000, total " +
    "28815 bytes livres dentro dos 32K):" + #CRLF$ +
    "- &HFFFF: Area usada pelo sistema" + #CRLF$ +
    "- &HF380: Bloco de controle de arquivo (tamanho determinado por MAXFILES)" + #CRLF$ +
    "- Area de string (tamanho definido pela instrucao CLEAR; se nao houver definicao, sera " +
    "reservada uma area de 200 bytes)" + #CRLF$ +
    "- Area de stack (guarda enderecos de retorno quando executadas as instrucoes FOR-NEXT ou " +
    "GOSUB-RETURN)" + #CRLF$ +
    "- Area livre (a area nao utilizada)" + #CRLF$ +
    "- Area de matrizes" + #CRLF$ +
    "- Area de variaveis (armazena dados numericos e os " + MSXQ + "pointers" + MSXQ + " para os dados " +
    "alfanumericos)" + #CRLF$ +
    "- &H8000: Area do programa em BASIC (onde serao armazenados programas com seus respectivos " +
    "numeros de linha)",
    192)

  MSXManual_Add("Apendice I - Funcoes Trigonometricas e Hiperbolicas", "Parte IV - Apendices",
    "O BASIC MSX permite calcular diretamente as funcoes SIN (seno), COS (cosseno), TAN " +
    "(tangente) e ATN (arco-tangente), onde os angulos sao medidos em radianos." + #CRLF$ + #CRLF$ +
    "Para as outras funcoes trigonometricas e hiperbolicas, o calculo deve ser precedido da " +
    "definicao de funcao. Por exemplo, sabendo-se que a funcao secante e o inverso do cosseno, " +
    "podemos calcula-la para um angulo X qualquer (em radianos) usando o seguinte programa " +
    "exemplo:" + #CRLF$ +
    "10 DEF FN SEC(X) = 1/COS(X)" + #CRLF$ +
    "20 INPUT X" + #CRLF$ +
    "30 PRINT FN SEC(X)" + #CRLF$ + #CRLF$ +
    "A correlacao entre as funcoes a serem definidas e as residentes no BASIC MSX e dada na " +
    "tabela a seguir:" + #CRLF$ +
    "SEC(X)      = 1/COS(X)" + #CRLF$ +
    "CSC(X)      = 1/SIN(X)" + #CRLF$ +
    "COT(X)      = 1/TAN(X)" + #CRLF$ +
    "ARCSIN(X)   = ATN(X/SQR(-X*X+1))" + #CRLF$ +
    "ARCCOS(X)   = -ATN(X/SQR(-X*X+1))+1.5708" + #CRLF$ +
    "ARCSEC(X)   = ATN(SQR(X*X-1))+(SGN(X)-1)*1.5708" + #CRLF$ +
    "ARCCSC(X)   = ATN(1/SQR(X*X-1))+(SGN(X)-1)*1.5708" + #CRLF$ +
    "ARCCOT(X)   = -ATN(X)+1.5708" + #CRLF$ +
    "SINH(X)     = (EXP(X)-EXP(-X))/2" + #CRLF$ +
    "COSH(X)     = (EXP(X)+EXP(-X))/2" + #CRLF$ +
    "TANH(X)     = -EXP(-X)/(EXP(X)+EXP(-X))*2 + 1" + #CRLF$ +
    "SECH(X)     = 2/(EXP(X)+EXP(-X))" + #CRLF$ +
    "CSCH(X)     = 2/(EXP(X)-EXP(-X))" + #CRLF$ +
    "COTH(X)     = EXP(-X)/(EXP(X)-EXP(-X))*2 + 1" + #CRLF$ +
    "ARCSINH(X)  = LOG(X+SQR(X*X+1))" + #CRLF$ +
    "ARCCOSH(X)  = LOG(X+SQR(X*X-1))" + #CRLF$ +
    "ARCTANH(X)  = LOG((1+X)/(1-X))/2" + #CRLF$ +
    "ARCSECH(X)  = LOG((SQR(-X*X+1)+1)/X)" + #CRLF$ +
    "ARCCSCH(X)  = LOG((SGN(X)*SQR(X*X+1)+1)/X)" + #CRLF$ +
    "ARCCOTH(X)  = LOG((X+1)/(X-1))/2",
    207)
EndProcedure

; Nomes oficiais tirados da pagina final nao numerada do livro ("AS CORES
; DO EXPERT" - cada cor ilustrada como um lapis colorido). Os hex sao uma
; aproximacao RGB da paleta padrao do VDP TMS9918 (a mesma do MSX1),
; valores de referencia amplamente documentados para essa paleta fixa de
; 16 cores - "aproximada" porque o TMS9918 gera video analogico (NTSC),
; nao RGB puro.
Procedure MSXColor_BuildData()
  MSXColor_Add(0, "incolor", "000000")
  MSXColor_Add(1, "preto", "000000")
  MSXColor_Add(2, "verde", "3EB849")
  MSXColor_Add(3, "verde claro", "74D07D")
  MSXColor_Add(4, "azul escuro", "5955E0")
  MSXColor_Add(5, "azul claro", "8076F1")
  MSXColor_Add(6, "vermelho escuro", "B95E51")
  MSXColor_Add(7, "ciano", "65DBEF")
  MSXColor_Add(8, "vermelho", "DB6559")
  MSXColor_Add(9, "vermelho claro", "FF897D")
  MSXColor_Add(10, "ouro", "CCC35E")
  MSXColor_Add(11, "amarelo", "DED087")
  MSXColor_Add(12, "verde musgo", "3AA241")
  MSXColor_Add(13, "magenta", "B766C2")
  MSXColor_Add(14, "cinza", "CCCCCC")
  MSXColor_Add(15, "branco", "FFFFFF")
EndProcedure
