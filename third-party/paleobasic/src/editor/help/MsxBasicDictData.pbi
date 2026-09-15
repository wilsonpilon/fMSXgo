;
; ------------------------------------------------------------
;  Ajuda -> MSX BASIC...: base de dados do "Dicionario das Palavras
;  Reservadas" (Parte II) do livro "Linguagem BASIC MSX" (Denise Santoro
;  Cruz, Editora Aleph/Gradiente, 4a edicao 1986), digitalizado em
;  docs/Linguagem_Basic_MSX.pdf. Mesma ideia de NestorBasicHelpData.pbi:
;  fonte unica pra uma futura janela de ajuda navegavel/pesquisavel e pra
;  exportacao em Markdown.
;
;  Convencoes do proprio livro (pagina 25, "CONVENCOES USADAS NO
;  DICIONARIO"), preservadas nos campos abaixo:
;  - (F) antes/depois do nome = palavra reservada e uma FUNCAO (devolve
;    valor); quando ausente, e uma instrucao/comando -> campo EhFuncao.b
;  - "*" junto ao nome = uso mais avancado/experiente (o livro remete a um
;    volume complementar, "Aprofundando-se no MSX") -> campo Avancado.b
;  - "expressao completa em ingles" de onde a palavra reservada foi tirada
;    (ex.: "(absolute)", "(binary dollar)") -> campo Origem.s
;  - FORMATO/EXEMPLO/FUNCAO/PROGRAMA EXEMPLO = 4 secoes fixas de cada
;    verbete, sempre nesta ordem -> campos Formato.s/ExemploFormato.s/
;    Funcao.s/ProgramaExemplo.s
;
;  PaginaLivro.i guarda o numero de pagina IMPRESSO no livro (nao o indice
;  do PDF) - util pra conferencia/retrabalho. Offset descoberto entre
;  pagina do PDF e pagina impressa, valido a partir da Parte II em diante:
;  pagina_impressa = pagina_pdf + 3 (ex.: ABS esta impresso na pagina 26,
;  que e a pagina 23 do arquivo PDF).
;
;  COMPLETO: as 140 palavras reservadas do dicionario (ABS a WIDTH),
;  transcritas letra a letra do livro. Nao ha letra J (o livro pula de
;  INTERVAL ON/OFF/STOP direto para KEY) nem letra Q (pula de PUT SPRITE
;  direto para READ) - o "143" estimado no inicio do trabalho, antes da
;  transcricao pagina a pagina, era uma contagem aproximada da tabela de
;  conteudo; o total real, apos transcrever todas as paginas 26-176, e
;  140.
; ------------------------------------------------------------
;

Global MSXQ.s = Chr(34) ; atalho pra aspas literais dentro dos listings BASIC (que sao cheios delas)

Structure MSXBasicKeyword
  Titulo.s            ; palavra reservada, ex "ABS", "BIN$"
  EhFuncao.b          ; #True = (F), funcao que devolve valor; #False = instrucao/comando
  Avancado.b          ; #True = marcado com "*" no livro (uso mais avancado/experiente)
  Origem.s            ; expressao completa em ingles de onde a palavra foi tirada
  Resumo.s            ; explicacao resumida (cabecalho do verbete)
  Formato.s           ; sintaxe (FORMATO:)
  ExemploFormato.s    ; exemplo de sintaxe (EXEMPLO:)
  Funcao.s            ; explicacao detalhada (FUNCAO:)
  ProgramaExemplo.s   ; listagem BASIC completa (PROGRAMA EXEMPLO:)
  PaginaLivro.i       ; numero de pagina IMPRESSO no livro/manual original
  Sistema.s           ; "MSX1" (livro Gradiente) ou "MSX2+" (manual ACVS MSX2+/FM)
EndStructure

Global NewList MSXDict_Keywords.MSXBasicKeyword()

Procedure MSXDict_Add(Titulo.s, EhFuncao.b, Avancado.b, Origem.s, Resumo.s, Formato.s, ExemploFormato.s, Funcao.s, ProgramaExemplo.s, PaginaLivro.i)
  AddElement(MSXDict_Keywords())
  MSXDict_Keywords()\Titulo = Titulo
  MSXDict_Keywords()\EhFuncao = EhFuncao
  MSXDict_Keywords()\Avancado = Avancado
  MSXDict_Keywords()\Origem = Origem
  MSXDict_Keywords()\Resumo = Resumo
  MSXDict_Keywords()\Formato = Formato
  MSXDict_Keywords()\ExemploFormato = ExemploFormato
  MSXDict_Keywords()\Funcao = Funcao
  MSXDict_Keywords()\ProgramaExemplo = ProgramaExemplo
  MSXDict_Keywords()\PaginaLivro = PaginaLivro
  MSXDict_Keywords()\Sistema = "MSX1"
EndProcedure

; Texto usado pra filtrar (busca por nome ou pela origem em ingles) - tudo
; em minusculas, um campo so por palavra.
Procedure.s MSXDict_SearchKey(*Kw.MSXBasicKeyword)
  ProcedureReturn LCase(*Kw\Titulo + " " + *Kw\Origem)
EndProcedure

Declare MSXDict_BuildLetterA()
Declare MSXDict_BuildLetterB()
Declare MSXDict_BuildLetterC()
Declare MSXDict_BuildLetterD()
Declare MSXDict_BuildLetterE()
Declare MSXDict_BuildLetterF()
Declare MSXDict_BuildLetterG()
Declare MSXDict_BuildLetterH()
Declare MSXDict_BuildLetterI()
Declare MSXDict_BuildLetterK()
Declare MSXDict_BuildLetterL()
Declare MSXDict_BuildLetterM()
Declare MSXDict_BuildLetterN()
Declare MSXDict_BuildLetterO()
Declare MSXDict_BuildLetterP()
Declare MSXDict_BuildLetterR()
Declare MSXDict_BuildLetterS()
Declare MSXDict_BuildLetterT()
Declare MSXDict_BuildLetterU()
Declare MSXDict_BuildLetterV()
Declare MSXDict_BuildLetterW()
Declare MSXDict_BuildMSX2Plus() ; definido em MsxBasic2PlusDictData.pbi (XIncluded depois deste arquivo)

Procedure MSXDict_BuildData()
  If ListSize(MSXDict_Keywords()) > 0
    ProcedureReturn ; ja construido - so monta uma vez por sessao
  EndIf

  MSXDict_BuildLetterA()
  MSXDict_BuildLetterB()
  MSXDict_BuildLetterC()
  MSXDict_BuildLetterD()
  MSXDict_BuildLetterE()
  MSXDict_BuildLetterF()
  MSXDict_BuildLetterG()
  MSXDict_BuildLetterH()
  MSXDict_BuildLetterI()
  MSXDict_BuildLetterK()
  MSXDict_BuildLetterL()
  MSXDict_BuildLetterM()
  MSXDict_BuildLetterN()
  MSXDict_BuildLetterO()
  MSXDict_BuildLetterP()
  MSXDict_BuildLetterR()
  MSXDict_BuildLetterS()
  MSXDict_BuildLetterT()
  MSXDict_BuildLetterU()
  MSXDict_BuildLetterV()
  MSXDict_BuildLetterW()
  MSXDict_BuildMSX2Plus()
EndProcedure

; --- Letra A (pagina 26-29 do livro = pagina 23-26 do PDF) ---
Procedure MSXDict_BuildLetterA()
  MSXDict_Add("ABS", #True, #False, "(absolute)",
    "Fornece o valor absoluto de um numero.",
    "ABS (argumento)",
    "B=ABS(-2)",
    "Fornece o valor absoluto do argumento, ou da expressao X." + #CRLF$ +
    "ABS (X) = X   para todo X maior ou igual a zero." + #CRLF$ +
    "ABS (X) = -X  para todo X menor que zero.",
    "10 REM PROGRAMA ABS" + #CRLF$ +
    "20 FOR F=1 TO 20" + #CRLF$ +
    "30 A=100-INT(RND(-TIME)*200)" + #CRLF$ +
    "40 PRINT A;" + MSXQ + "......" + MSXQ + ";ABS(A)" + #CRLF$ +
    "50 NEXT F",
    26)

  MSXDict_Add("ASC", #True, #False, "(ascii)",
    "Fornece o codigo ASCII do primeiro caractere de uma dada string.",
    "ASC (string)",
    "A=ASC(" + MSXQ + "A" + MSXQ + ")",
    "Fornece o codigo ASCII (American Standard Code for Interchange Information) do primeiro " +
    "caractere de uma string especificada. A string ou variavel string deve ser colocada entre " +
    "parenteses, nao podendo ser nula. Caso contrario, ocasionara uma mensagem de erro.",
    "10 REM PROGRAMA ASC" + #CRLF$ +
    "20 A$=INKEY$" + #CRLF$ +
    "30 IF A$=" + MSXQ + MSXQ + " THEN 20" + #CRLF$ +
    "40 PRINT" + MSXQ + "ASC(" + MSXQ + ";A$;" + MSXQ + ")=" + MSXQ + ";ASC(A$)," + #CRLF$ +
    "50 GOTO 20",
    27)

  MSXDict_Add("ATN", #True, #False, "(arc tangent)",
    "Fornece o valor do arco, em radianos, cuja tangente trigonometrica e igual ao argumento.",
    "ATN (argumento)",
    "A=ATN(1)",
    "A funcao ATN fornece o arco-tangente (em radianos) do argumento, isto e, o angulo cuja " +
    "tangente e igual ao valor do argumento. O limite deste resultado esta entre -pi/2 e pi/2. A " +
    "expressao do argumento pode ser qualquer numero, mas o calculo de ATN sempre sera realizado " +
    "em modo de precisao dupla.",
    "10 REM PROGRAMA ATN" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 SCREEN 2" + #CRLF$ +
    "40 FOR F=-128 TO 127" + #CRLF$ +
    "50 PSET(F+128,80-70*ATN((F)*6.2832/255))" + #CRLF$ +
    "60 NEXT F",
    28)

  MSXDict_Add("AUTO", #False, #False, "(auto)",
    "Gera, automaticamente, numeros de linhas a partir de um valor inicial especificado, com " +
    "incremento tambem especificado.",
    "AUTO [numero inicial da linha] [,incremento]",
    "AUTO 100,5",
    "Este comando liga uma funcao automatica de numeracao de linha, para entrada de programas. " +
    "Tudo o que voce tem a fazer e introduzir as instrucoes reais do programa. Voce pode " +
    "especificar um numero de linha inicial e um incremento para ser usado entre os numeros de " +
    "linha ou entao, simplesmente digitar AUTO e pressionar RETURN. Neste caso, a numeracao de " +
    "linha iniciara na 10 e usara incremento 10. Cada vez que voce pressionar RETURN, o " +
    "computador avancara para o numero seguinte de linha." + #CRLF$ + #CRLF$ +
    "Por exemplo:" + #CRLF$ +
    "COMANDO         NUMERACAO DAS LINHAS DO PROGRAMA" + #CRLF$ +
    "AUTO            10, 20, 30 ..." + #CRLF$ +
    "AUTO 5,5        5, 10, 15..." + #CRLF$ +
    "AUTO 100        100, 110, 120..." + #CRLF$ +
    "AUTO 100,25     100, 125, 150..." + #CRLF$ +
    "AUTO 0          0, 10, 20..." + #CRLF$ +
    "AUTO 10         10, 20, 30..." + #CRLF$ + #CRLF$ +
    "Para desligar a funcao AUTO, pressione CTRL + C ou CTRL + STOP. Nao sera considerada a linha " +
    "em que for teclado o CTRL + C. Quando o comando AUTO traz com o numero da linha um asterisco " +
    "(*), significa que a linha ja esta sendo usada. Se voce nao deseja reprogramar a linha, " +
    "devera pressionar CTRL + STOP para desligar a funcao.",
    "10 REM PROGRAMA AUTO" + #CRLF$ +
    "20 PRINT" + MSXQ + "VOCE QUER ALTERAR O PROGRAMA A PARTIR DA LINHA 100? (S/N)?" + MSXQ + #CRLF$ +
    "30 A$=INKEY$" + #CRLF$ +
    "40 IF A$=" + MSXQ + "S" + MSXQ + " THEN 90" + #CRLF$ +
    "50 IF A$=" + MSXQ + "N" + MSXQ + " THEN 100" + #CRLF$ +
    "60 GOTO 30" + #CRLF$ +
    "90 AUTO 100,10" + #CRLF$ +
    "100 PRINT" + MSXQ + "VOCE NAO ME ALTEROU." + MSXQ,
    29)
EndProcedure

; --- Letra B (pagina 30-34 do livro = pagina 27-31 do PDF) ---
Procedure MSXDict_BuildLetterB()
  MSXDict_Add("BASE", #False, #True, "(base)",
    "Permite o acesso ao endereco inicial das tabelas utilizadas pelo processador de video.",
    "BASE (numero)" + #CRLF$ +
    "BASE (numero) = expressao",
    "BASE(10)",
    "O comando BASE permite que o usuario leia e reescreva na memoria o endereco inicial das " +
    "tabelas utilizadas pelo VDP (Video Display Processor). Estas tabelas sao utilizadas pelo " +
    "processador de video conforme o modo em que se esta trabalhando. A expressao deve ser um " +
    "valor inteiro entre 0 e 65535 e o numero deve estar entre 0 e 19 (nao se utilizando os " +
    "valores 1, 3, 4 e 16). As tabelas, cujos enderecos iniciais sao especificados por BASE, " +
    "estao relacionadas a seguir:" + #CRLF$ + #CRLF$ +
    "SCREEN 0:" + #CRLF$ +
    "- 2 - Tabela do gerador de padroes utilizados no modo texto de 40 caracteres x 24 linhas" + #CRLF$ + #CRLF$ +
    "SCREEN 1:" + #CRLF$ +
    "- 5 - Tabela dos nomes utilizados no modo texto de 32 caracteres x 24 linhas" + #CRLF$ +
    "- 6 - Tabela de cores utilizadas no modo texto de 32 caracteres x 24 linhas" + #CRLF$ +
    "- 7 - Tabela do gerador de padroes utilizados no modo texto de 32 caracteres x 24 linhas" + #CRLF$ +
    "- 8 - Tabela dos atributos de sprites utilizados no modo texto de 32 caracteres x 24 linhas" + #CRLF$ +
    "- 9 - Tabela dos padroes de sprites utilizados no modo texto de 32 caracteres x 24 linhas" + #CRLF$ + #CRLF$ +
    "SCREEN 2:" + #CRLF$ +
    "- 10 - Tabela dos nomes utilizados no modo grafico em alta-resolucao" + #CRLF$ +
    "- 11 - Tabela de cores utilizadas no modo grafico em alta-resolucao" + #CRLF$ +
    "- 12 - Tabela do gerador de padroes utilizados no modo grafico em alta-resolucao" + #CRLF$ +
    "- 13 - Tabela dos atributos de sprites utilizados no modo grafico em alta-resolucao" + #CRLF$ +
    "- 14 - Tabela dos padroes de sprites utilizados no modo grafico em alta-resolucao" + #CRLF$ + #CRLF$ +
    "SCREEN 3:" + #CRLF$ +
    "- 15 - Tabela dos nomes utilizados no modo policromatico" + #CRLF$ +
    "- 17 - Tabela do gerador de padroes utilizados no modo policromatico" + #CRLF$ +
    "- 18 - Tabela dos atributos de sprites utilizados no modo policromatico" + #CRLF$ +
    "- 19 - Tabela dos padroes de sprites utilizados no modo policromatico",
    "10 REM PROGRAMA BASE" + #CRLF$ +
    "20 FOR F=1 TO 15:PRINT BASE(F):NEXT F",
    30)

  MSXDict_Add("BEEP", #False, #False, "(beep)",
    "Provoca um beep (sinal sonoro).",
    "BEEP",
    "BEEP",
    "Utilizado para gerar um sinal sonoro. Produz o mesmo efeito que o CHR$(7).",
    "0 REM programa BEEP" + #CRLF$ +
    "10 FOR I = 0 TO 19" + #CRLF$ +
    "20 BEEP" + #CRLF$ +
    "30 NEXT I",
    31)

  MSXDict_Add("BIN$", #True, #False, "(binary dollar)",
    "Transforma um dado numerico em uma expressao binaria na forma de uma string.",
    "BIN$ (X)",
    "LPRINT BIN$(A)",
    "O comando BIN$ transforma um dado numerico (constante, variavel numerica ou variavel de " +
    "matriz numerica) em uma expressao binaria na forma de uma string. Caso o numero seja " +
    "negativo, primeiro calcula-se o valor (em decimal) subtraindo-se de 65536, e a partir do " +
    "resultado desta operacao, faz-se a conversao para binario e a transforma posteriormente " +
    "numa string." + #CRLF$ +
    "PRINT BIN$(115)" + #CRLF$ +
    "1110011" + #CRLF$ +
    "PRINT BIN$(-19)" + #CRLF$ +
    "1111111111101101   ( 65536-19=65517 )",
    "10 REM PROGRAMA BIN$" + #CRLF$ +
    "20 FOR F=0 TO 20" + #CRLF$ +
    "30 PRINT F;" + MSXQ + "........" + MSXQ + ";BIN$(F)" + #CRLF$ +
    "40 NEXT F",
    32)

  MSXDict_Add("BLOAD", #False, #True, "(binary load)",
    "Carrega um programa em linguagem de maquina e o executa (caso esta opcao esteja ativada).",
    "BLOAD " + MSXQ + "nome do dispositivo [nome do arquivo]" + MSXQ + " [R] [,deslocamento]",
    "BLOAD" + MSXQ + "CAS:EXEMPL" + MSXQ + ",R",
    "Carrega um programa em linguagem de maquina do dispositivo especificado, em geral " + MSXQ + "CAS:" + MSXQ + " " +
    "(cassete). O nome do arquivo deve ter no maximo 6 caracteres (os excedentes serao " +
    "desprezados). Se o nome do arquivo for omitido, o primeiro programa, em linguagem de " +
    "maquina, que for encontrado, sera carregado. Se R for especificado no comando, depois de " +
    "carregado o programa, a execucao comecara automaticamente no endereco que havia sido " +
    "indicado em BSAVE por ocasiao da gravacao. O programa sera armazenado no trecho de memoria " +
    "especificado tambem em BSAVE pelos enderecos inicial e final. Se o deslocamento esta " +
    "especificado, todos estes enderecos sao deslocados. O deslocamento deve ser um numero " +
    "inteiro entre -32768 e 65535.",
    "10 BLOAD " + MSXQ + "CAS:ALEPH" + MSXQ + #CRLF$ +
    "20 CLS:FOR I=0 TO 41" + #CRLF$ +
    "30 PRINT HEX$(PEEK(60000!+I));" + MSXQ + " " + MSXQ + ";" + #CRLF$ +
    "40 FOR T=1 TO 90:NEXT T" + #CRLF$ +
    "50 NEXT I" + #CRLF$ +
    "60 FOR T=1 TO 500:NEXT T" + #CRLF$ +
    "70 DEFUSR=60006!" + #CRLF$ +
    "80 X=USR(0):GOTO 80" + #CRLF$ +
    "90 REM" + #CRLF$ +
    "100 REM USAR EM CONJUNTO COM O PROGRAMA BSAVE",
    33)

  MSXDict_Add("BSAVE", #False, #True, "(binary save)",
    "Grava programas em codigo de maquina extraidos de uma area especifica da memoria.",
    "BSAVE " + MSXQ + "nome do dispositivo [nome do arquivo]" + MSXQ + ", endereco inicial," + #CRLF$ +
    "endereco final, [endereco do inicio de execucao]",
    "BSAVE" + MSXQ + "CAS:DEMO" + MSXQ + ",&HA100,&HA2EF",
    "Este comando e utilizado para gravar o conteudo de uma area da memoria em um dispositivo " +
    "(em geral, " + MSXQ + "CAS:" + MSXQ + ", onde CAS = cassete). O nome do arquivo deve ter no maximo 6 " +
    "caracteres (os excedentes serao ignorados). O nome do arquivo pode ser tambem uma string " +
    "nula. Os enderecos, inicial e final, indicam a area da memoria que deve ser gravada. Devem " +
    "ser numeros inteiros entre -32768 e 65535. O endereco do inicio de execucao indica o " +
    "endereco no qual o programa devera iniciar a execucao quando for carregado de volta ao " +
    "computador pelo comando BLOAD com a opcao R ativada. Tambem deve ser um numero inteiro " +
    "entre -32768 e 65535.",
    "10 DATA 41,4C,45,50,48,FF,11,60,EA,1A" + #CRLF$ +
    "20 DATA FE,FF,C8,21,00,00,CD,4D,00,23" + #CRLF$ +
    "30 DATA E5,D5,11,BF,03,ED,52,D1,E1,38" + #CRLF$ +
    "40 DATA F1,21,FF,FF,2B,7C,B5,28,FB,13" + #CRLF$ +
    "50 DATA 18,DF" + #CRLF$ +
    "60 FOR I=0 TO 41" + #CRLF$ +
    "70 READ A$" + #CRLF$ +
    "80 POKE 60000!+I,VAL(" + MSXQ + "&H" + MSXQ + "+A$)" + #CRLF$ +
    "90 NEXT I" + #CRLF$ +
    "100 DEFUSR=60006!" + #CRLF$ +
    "110 SCREEN 0" + #CRLF$ +
    "120 X=USR(0)" + #CRLF$ +
    "130 FOR T=1 TO 1000:NEXT T:CLS" + #CRLF$ +
    "140 BSAVE " + MSXQ + "CAS:ALEPH" + MSXQ + ",60000!,60042!,60006!",
    34)
EndProcedure

; --- Letra C (pagina 35-49 do livro = pagina 32-46 do PDF) ---
Procedure MSXDict_BuildLetterC()
  MSXDict_Add("CALL", #False, #True, "(call)",
    "Executa um comando contido num cartucho ROM.",
    "CALL nome do comando [, (argumentos)]",
    "CALL START",
    "Serve para chamar um comando de uma memoria auxiliar em cartucho. Do mesmo modo que o " +
    "comando PRINT pode ser substituido por ? e o comando REM pode ser substituido pelo ' , o " +
    "comando CALL pode ser substituido pelo sinal - .",
    "10 ' CALL" + #CRLF$ +
    "20 PRINT" + MSXQ + "Voce quer formatar seu diskette (s/n)?" + MSXQ + #CRLF$ +
    "30 Z$=INPUT$(1)" + #CRLF$ +
    "40 IF Z$=" + MSXQ + "s" + MSXQ + " THEN CALL FORMAT" + #CRLF$ +
    "50 IF Z$<>" + MSXQ + "n" + MSXQ + " THEN 30",
    35)

  MSXDict_Add("CDBL", #True, #False, "(change double)",
    "Converte um dado numerico no formato " + MSXQ + "precisao simples" + MSXQ + " em um dado no formato de " + MSXQ + "precisao dupla" + MSXQ + ".",
    "CDBL (argumento)",
    "A#=CDBL(B!/2)",
    "Esta funcao converte o argumento para o formato em precisao dupla. O valor resultante " +
    "apresenta um formato com 17 digitos. CDBL pode ser util, quando se quer forcar uma operacao " +
    "a ser efetuada em precisao dupla, mesmo que os operandos sejam de precisao simples ou " +
    "inteiros.",
    "10 REM PROGRAMA CDBL" + #CRLF$ +
    "20 A!=20" + #CRLF$ +
    "30 B=3.141592#" + #CRLF$ +
    "40 C=CDBL(A!/B)" + #CRLF$ +
    "50 PRINT A!,B,C",
    36)

  MSXDict_Add("CHR$", #True, #False, "(character dollar)",
    "Fornece o caractere correspondente ao codigo especificado.",
    "CHR$ (argumento)",
    "A$=CHR$(65)",
    "Realiza o inverso da funcao ASC, isto e, fornece o caractere correspondente ao codigo ASCII " +
    "especificado. O argumento pode ser qualquer numero de 0 a 255, ou qualquer expressao " +
    "variavel com um valor nesta faixa. O argumento ou expressao deve estar entre parenteses.",
    "10 ' TABLE DE CARACTERES" + #CRLF$ +
    "20 DATA 0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F" + #CRLF$ +
    "30 SCREEN 2,,,,1" + #CRLF$ +
    "40 OPEN" + MSXQ + "GRP:" + MSXQ + "FOR OUTPUT AS 1" + #CRLF$ +
    "50 FOR F=0 TO 255" + #CRLF$ +
    "60 L=F\16:C=4+F-16*L" + #CRLF$ +
    "70 PSET (11*C,13+11*L),1" + #CRLF$ +
    "80 IF F<32 THEN PRINT #1,CHR$(1)+CHR$(64+F)" + #CRLF$ +
    "90 IF F>31 THEN PRINT #1,CHR$(F)" + #CRLF$ +
    "100 NEXTF" + #CRLF$ +
    "110 FOR F=0 TO 187 STEP 11" + #CRLF$ +
    "120 LINE(31,F)-(218,F)" + #CRLF$ +
    "130 NEXT F" + #CRLF$ +
    "140 FOR F=31 TO 218 STEP 11" + #CRLF$ +
    "150 LINE(F,0)-(F,187)" + #CRLF$ +
    "160 NEXT F" + #CRLF$ +
    "170 FOR F=45 TO 217 STEP 11" + #CRLF$ +
    "180 C=C+1:READ A$" + #CRLF$ +
    "190 PSET(F+1,2),1:PRINT#1,A$" + #CRLF$ +
    "200 PSET(F+1,3),1:PRINT#1,A$" + #CRLF$ +
    "210 PSET(F,2),1:PRINT#1,A$" + #CRLF$ +
    "220 PSET(F,3),1:PRINT#1,A$" + #CRLF$ +
    "230 PSET(35,F-32),1:PRINT#1,A$" + #CRLF$ +
    "240 PSET(35,F-31),1:PRINT#1,A$" + #CRLF$ +
    "250 PSET(34,F-32),1:PRINT#1,A$" + #CRLF$ +
    "260 PSET(34,F-31),1:PRINT#1,A$" + #CRLF$ +
    "270 NEXT F" + #CRLF$ +
    "280 GOTO 280",
    37)

  MSXDict_Add("CINT", #True, #False, "(convert to interger)",
    "Converte dados numericos em numeros inteiros.",
    "CINT (argumento)",
    "A%=CINT(B#*2)",
    "A funcao CINT (X) fornece o maior numero inteiro possivel menor que o valor do argumento " +
    "especificado. Por exemplo:" + #CRLF$ +
    "CINT (1.5) resulta em 1" + #CRLF$ +
    "CINT (-1.5) resulta em -2." + #CRLF$ +
    "Para a funcao CINT, o argumento deve estar entre os limites de -32768 e +32767, caso " +
    "contrario, ocasionara um erro de overflow. CINT pode ser utilizado para acelerar operacoes " +
    "envolvendo operandos de precisao simples e dupla.",
    "10 REM PROGRAMA CINT" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 FOR F=1 TO 20" + #CRLF$ +
    "40 A=500-RND(-TIME)*1000" + #CRLF$ +
    "50 PRINT A;" + MSXQ + "............" + MSXQ + ";CINT(A)" + #CRLF$ +
    "60 NEXT F",
    38)

  MSXDict_Add("CIRCLE", #False, #False, "(circle)",
    "Traca, no modo grafico, um circulo, uma elipse, uma parte de um arco circular (ou um setor).",
    "CIRCLE [STEP](X,Y), raio [,cor] [,angulo inicial] [,angulo final] [,proporcao]" + #CRLF$ + #CRLF$ +
    "(X,Y): Especifica as coordenadas que determinam o centro do circulo na tela. Podem ser " +
    "constantes, variaveis ou variaveis indexadas, com valor entre -32768 e 32767. Se o STEP for " +
    "especificado antes, a origem do sistema de coordenadas da tela (0,0) sera transferida do " +
    "canto superior esquerdo para a posicao do ultimo ponto plotado." + #CRLF$ +
    "RAIO: Pode ser uma constante, variavel ou uma variavel indexada com valor entre -32768 a " +
    "32767, indicando o raio da figura a ser tracada." + #CRLF$ +
    "COR: Indica qual a cor com que a elipse sera desenhada. Deve ser um inteiro entre 0 e 15." + #CRLF$ +
    "Os parametros [angulo inicial] e [angulo final], sao medidos em radianos entre 0 e 2 PI (2pi)," + #CRLF$ +
    "PROPORCAO: E a proporcao entre o eixo horizontal e vertical da elipse. Os dados podem ser: " +
    "constantes, variaveis indexadas, numeros positivos ou suas expressoes. Se omitido, sera " +
    "assumido o valor 1",
    "CIRCLE (128,86),70,10,0,3,4",
    "Este comando e utilizado para desenhar um circulo com a especificacao do raio e com seu " +
    "centro nas coordenadas tambem especificadas. Quando se especificam os angulos (inicial e " +
    "final), somente sera tracado uma parte do arco circular. O arco podera ser tracado colocando " +
    "o sinal de menos (" + MSXQ + "-" + MSXQ + ") para o valor dos angulos inicial e final. Uma elipse podera ser " +
    "tracada especificando a " + MSXQ + "proporcao" + MSXQ + " (relacao altura/largura), isto e, o numero de vezes " +
    "que o eixo horizontal esta contido na vertical.",
    "10 REM PROGRAMA ESFERA" + #CRLF$ +
    "20 SCREEN2" + #CRLF$ +
    "30 FOR B=80 TO 1 STEP -10" + #CRLF$ +
    "40 E1=80/B" + #CRLF$ +
    "50 E2=B/80" + #CRLF$ +
    "60 CIRCLE (128,80),80,5,,,E1" + #CRLF$ +
    "70 CIRCLE (128,80),80,5,,,E2" + #CRLF$ +
    "80 NEXT B" + #CRLF$ +
    "90 COLOR 5,1" + #CRLF$ +
    "100 LINE (128,160)-(128,0)" + #CRLF$ +
    "110 LINE (48,80)-(208,80)" + #CRLF$ +
    "120 GOTO 100",
    39)

  MSXDict_Add("CLEAR", #False, #False, "(clear)",
    "Inicializa todas as variaveis e estabelece o tamanho da area de caracteres e o ultimo " +
    "endereco de memoria utilizada pelo BASIC. Tambem fecha todos os arquivos abertos.",
    "CLEAR (tamanho da area de caracteres)[, (endereco da RAMTOP)]" + #CRLF$ + #CRLF$ +
    "TAMANHO DA AREA DE CARACTERES: Espaco para variavel string." + #CRLF$ + #CRLF$ +
    "ENDERECO DA RAMTOP: Especifica a area de memoria disponivel para ser usado pelo BASIC. Exemplo:",
    "CLEAR 400,55296",
    "Com esta instrucao, inicializa-se todas as variaveis e estabelece (quando especificado) o " +
    "ultimo endereco da area de programacao BASIC, ou seja, o valor da RAMTOP.",
    "10 REM Programa CLEAR" + #CRLF$ +
    "20 CLEAR 200" + #CRLF$ +
    "30 ON ERROR GOTO 90" + #CRLF$ +
    "40 FOR F=1 TO 25" + #CRLF$ +
    "50 A$=A$+" + MSXQ + "##########" + MSXQ + #CRLF$ +
    "60 PRINT" + MSXQ + "A$ esta com" + MSXQ + ";10*F;" + MSXQ + "caracteres." + MSXQ + #CRLF$ +
    "70 NEXT F" + #CRLF$ +
    "80 END" + #CRLF$ +
    "90 PRINT" + MSXQ + "Com" + MSXQ + ";10*F;" + MSXQ + "caracteres em A$, o micro nao" + MSXQ + #CRLF$ +
    "100 PRINT" + MSXQ + "consegue trabalhar e ocorre um erro:" + MSXQ + #CRLF$ +
    "110 PRINT CHR$(34);" + MSXQ + "Out of string space" + MSXQ + ";CHR$(34)" + #CRLF$ +
    "120 PRINT:PRINT" + MSXQ + "Agora sera executado um comando CLEAR  e o programa recomecara!" + MSXQ + #CRLF$ +
    "130 CLEAR 10000" + #CRLF$ +
    "140 FOR G=1 TO 3000 : NEXT G" + #CRLF$ +
    "150 GOTO 40",
    40)

  MSXDict_Add("CLOAD/CLOAD?", #False, #True, "(cassete load)",
    "Carrega um programa em BASIC MSX de um cassete para a memoria do MSX.",
    "CLOAD [" + MSXQ + "nome do arquivo" + MSXQ + "]" + #CRLF$ +
    "CLOAD? [" + MSXQ + "nome do arquivo" + MSXQ + "]",
    "CLOAD" + MSXQ + "DEMO" + MSXQ + #CRLF$ +
    "CLOAD?" + MSXQ + "DEMO" + MSXQ,
    "O comando CLOAD possibilita a carga de um programa armazenado em fita cassete (colocando o " +
    "gravador no modo PLAY). Certifique-se de que as ligacoes foram feitas corretamente e de que " +
    "a fita foi rebobinada ate a posicao correta. O nome de arquivo pode ter no maximo 6 " +
    "caracteres entre aspas. Se ele possuir mais do que 6 caracteres, os excedentes serao " +
    "desprezados. No nome de arquivo podem ser utilizados quaisquer caracteres, exceto as " +
    "proprias aspas. O BASIC permite especificar o nome de arquivo desejado, por exemplo, CLOAD " +
    MSXQ + "EXPERT" + MSXQ + ". Isso fara com que o computador ignore qualquer programa, ate que ele " +
    "encontre o programa rotulado " + MSXQ + "EXPERT" + MSXQ + ". Enquanto o computador estiver procurando o " +
    "arquivo " + MSXQ + "EXPERT" + MSXQ + ", os nomes dos outros programas encontrados aparecerao da seguinte " +
    "forma:" + #CRLF$ + #CRLF$ +
    "Skip:GRADIE" + #CRLF$ +
    "Skip:ALEPH" + #CRLF$ +
    "Skip:MSX" + #CRLF$ + #CRLF$ +
    "e, quando o arquivo " + MSXQ + "EXPERT" + MSXQ + " for encontrado aparecera:" + #CRLF$ + #CRLF$ +
    "Found:EXPERT" + #CRLF$ + #CRLF$ +
    "isto significa que " + MSXQ + "EXPERT" + MSXQ + " foi encontrado e esta sendo carregado. Se o nome do " +
    "arquivo nao for especificado, o primeiro programa encontrado pelo computador sera carregado " +
    "na memoria. CLOAD? permite a comparacao de um programa armazenado em fita cassete, com um " +
    "programa na memoria do computador. Isto e util quando, apos gravar programas na fita (usando " +
    "CSAVE), se deseja verificar se a transferencia foi bem sucedida. Durante o CLOAD? o programa " +
    "na fita e o programa na memoria, sao comparados byte por byte. Se houver alguma " +
    "irregularidade (indicando uma gravacao mal feita) o computador mandara a seguinte mensagem:" + #CRLF$ + #CRLF$ +
    "Verify error" + #CRLF$ + #CRLF$ +
    "Neste caso, voce devera gravar o programa novamente.",
    "",
    41)

  MSXDict_Add("CLOSE", #False, #False, "(close)",
    "Fecha um arquivo que foi aberto por um comando OPEN.",
    "CLOSE [#] [numero do arquivo]" + #CRLF$ + "[, numero do arquivo]",
    "CLOSE#1",
    "Tem a funcao de fechar o acesso a um arquivo, atraves de um ou mais buffers especificados, " +
    "liberando-o(s). Se o numero do arquivo nao for especificado, todos os canais abertos pelo " +
    "comando OPEN serao fechados.",
    "10 REM PROGRAMA CLOSE" + #CRLF$ +
    "20 MAXFILES=1" + #CRLF$ +
    "30 CLS" + #CRLF$ +
    "40 OPEN " + MSXQ + "GRP:" + MSXQ + " FOR OUTPUT AS #1" + #CRLF$ +
    "50 SCREEN 2" + #CRLF$ +
    "55 LINE(0,0)-(255,191),5,BF" + #CRLF$ +
    "56 CIRCLE(120,120),50" + #CRLF$ +
    "60 PRINT #1," + MSXQ + "EXPERT" + MSXQ + #CRLF$ +
    "70 FOR I=1 TO 1000:NEXT" + #CRLF$ +
    "80 CLOSE 1" + #CRLF$ +
    "90 SCREEN 0" + #CRLF$ +
    "100 LIST",
    42)

  MSXDict_Add("CLS", #False, #False, "(clear screen)",
    "Apaga tudo o que esta visualizado na tela.",
    "CLS",
    "CLS",
    "Esse comando tem a funcao de " + MSXQ + "limpar a tela" + MSXQ + ". Desativa todos seus pontos graficos " +
    "e move o cursor para o canto superior esquerdo. Muito util quando se deseja uma boa " +
    "apresentacao visual. No modo grafico o comando COLOR sera executado apos um comando CLS.",
    "10 REM PROGRAMA CLS" + #CRLF$ +
    "20 INPUT" + MSXQ + "VOCE QUER LIMPAR A TELA (S/N)" + MSXQ + ";R$" + #CRLF$ +
    "30 IF R$=" + MSXQ + "N" + MSXQ + " THEN 50" + #CRLF$ +
    "40 CLS" + #CRLF$ +
    "50 END",
    43)

  MSXDict_Add("COLOR", #False, #False, "(color)",
    "Especifica as cores do primeiro plano, fundo e area das bordas.",
    "COLOR [cor do 1o plano], [cor do fundo], [cor da borda]",
    "COLOR 15,7,7",
    "Tem a funcao de definir a cor da tela que esta dividida em: borda, fundo, 1o plano." + #CRLF$ + #CRLF$ +
    "Para definir a cor, o argumento deve estar entre 0 a 15. As cores correspondentes a cada " +
    "valor estao na tabela abaixo:" + #CRLF$ + #CRLF$ +
    "- 0 - transparente" + #CRLF$ +
    "- 1 - negro" + #CRLF$ +
    "- 2 - verde" + #CRLF$ +
    "- 3 - verde claro" + #CRLF$ +
    "- 4 - azul escuro" + #CRLF$ +
    "- 5 - azul claro" + #CRLF$ +
    "- 6 - vermelho escuro" + #CRLF$ +
    "- 7 - azul celeste" + #CRLF$ +
    "- 8 - vermelho" + #CRLF$ +
    "- 9 - vermelho claro" + #CRLF$ +
    "- 10 - amarelo escuro" + #CRLF$ +
    "- 11 - amarelo claro" + #CRLF$ +
    "- 12 - verde escuro" + #CRLF$ +
    "- 13 - magenta" + #CRLF$ +
    "- 14 - cinza" + #CRLF$ +
    "- 15 - branco" + #CRLF$ + #CRLF$ +
    "Exemplo:" + #CRLF$ + #CRLF$ +
    "COLOR 6           somente colocara a cor do primeiro plano" + #CRLF$ + #CRLF$ +
    "COLOR ,2          somente colocara a cor do fundo" + #CRLF$ + #CRLF$ +
    "COLOR ,,11        somente colocara a cor da area das bordas" + #CRLF$ + #CRLF$ +
    "COLOR 15,1,1      cores de inicializacao",
    "10 REM PROGRAMA COLOR" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 FOR F=1 TO 14" + #CRLF$ +
    "40 FOR G=0 TO150" + #CRLF$ +
    "50 NEXT G" + #CRLF$ +
    "60 PRINT" + MSXQ + "XXXXXXXX ALEPH  &  GRADIENTE XXXXXXXX" + MSXQ + #CRLF$ +
    "70 COLORF,F-1,F+1" + #CRLF$ +
    "80 NEXTF" + #CRLF$ +
    "90 COLOR 15,1,1",
    44)

  MSXDict_Add("CONT", #False, #False, "(continue)",
    "Continua a execucao de um programa interrompido.",
    "CONT",
    "CONT",
    "Continua a execucao de um programa interrompido por uma instrucao END, STOP, ou mediante a " +
    "digitacao de CONTROL + STOP. O comando CONT reinicia a execucao a partir da instrucao " +
    "seguinte aquela que foi interrompida, a nao ser que a interrupcao tenha ocorrido durante uma " +
    "instrucao INPUT. Nesse caso, CONT faz com que o INPUT seja executado desde o comeco.",
    "10 ' CONT" + #CRLF$ +
    "20 FOR F=1 TO 20" + #CRLF$ +
    "30 PRINT TAB(F);F" + #CRLF$ +
    "40 NEXT F" + #CRLF$ +
    "50 PRINT" + MSXQ + "A execucao do programa foi interrompida por STOP." + MSXQ + #CRLF$ +
    "60 PRINT" + MSXQ + "Digite CONT+RETURN para continuar!!!" + MSXQ + #CRLF$ +
    "70 STOP" + #CRLF$ +
    "80 CLS" + #CRLF$ +
    "90 PRINT:PRINT" + MSXQ + "A execucao esta continuando!" + MSXQ + #CRLF$ +
    "100 FOR R=333 TO 0 STEP-1" + #CRLF$ +
    "110 LOCATE 13,10" + #CRLF$ +
    "120 PRINTUSING" + MSXQ + "###" + MSXQ + ";R" + #CRLF$ +
    "130 NEXT R" + #CRLF$ +
    "140 PRINT TAB(13);" + MSXQ + "FIM!!!" + MSXQ + #CRLF$ +
    "150 END",
    45)

  ; CONFERIR: os dois digitos longos abaixo (EXEMPLO e linha 50 do PROGRAMA
  ; EXEMPLO) nao batem exatamente com PI/2*PI - risco de erro de
  ; transcricao da imagem escaneada, conferir contra a pagina 46 do livro.
  MSXDict_Add("COS", #True, #False, "(cosine)",
    "Fornece o valor do cosseno de um arco em radianos.",
    "COS (argumento)",
    "C=COS(3.14159265535898/2)",
    "A funcao COS (X) tem por finalidade fornecer o cosseno do argumento especificado que deve " +
    "estar em radianos. A funcao COS e calculada em precisao dupla.",
    "10 REM PROGRAMA COS" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 SCREEN 2" + #CRLF$ +
    "40 FOR F=0 TO 255 STEP .5" + #CRLF$ +
    "50 PSET(F,80-70*COS(F*6.141592#/255))" + #CRLF$ +
    "60 NEXT F" + #CRLF$ +
    "70 GOTO 70",
    46)

  MSXDict_Add("CSAVE", #False, #True, "(cassete save)",
    "Armazena, num cassete, um programa em BASIC MSX.",
    "CSAVE " + MSXQ + "(nome do arquivo)" + MSXQ + " [, velocidade de transmissao em bauds]" + #CRLF$ + #CRLF$ +
    "NOME DO ARQUIVO: Adota no maximo 6 caracteres, sendo que o primeiro deve obrigatoriamente " +
    "ser um caractere alfabetico. Se forem especificados 7 ou mais caracteres, o setimo e os " +
    "demais serao ignorados." + #CRLF$ + #CRLF$ +
    "VELOCIDADE DA TRANSMISSAO EM BAUDS: Especifica a velocidade de gravacao, adotando o " +
    "seguinte criterio: 1 para 1200 bauds e 2 para 2400 bauds. Se a velocidade for omitida, sera " +
    "adotada a velocidade 1 (=1200 bauds).",
    "CSAVE" + MSXQ + "PROG1" + MSXQ,
    "Gravar arquivos em fita cassete. A gravacao e feita no formato binario condensado, de modo " +
    "que nao se pode usar o comando MERGE (ele so funciona para arquivos gravados em ASCII). A " +
    "velocidade de transmissao de dados para o cassete tambem pode ser definida numa instrucao " +
    "SCREEN.",
    "10 CLS" + #CRLF$ +
    "20 PRINT" + MSXQ + "ESTE PROGRAMA SE AUTO-COPIA" + MSXQ + #CRLF$ +
    "30 PRINT" + MSXQ + "APERTE (RETURN) PARA GRAVAR" + MSXQ + #CRLF$ +
    "40 INPUT B$" + #CRLF$ +
    "50 CSAVE" + MSXQ + "ALEPH" + MSXQ + #CRLF$ +
    "60 INPUT" + MSXQ + "OUTRA GRAVACAO " + MSXQ + ";A$" + #CRLF$ +
    "70 IF A$=" + MSXQ + "S" + MSXQ + " OR A$=" + MSXQ + "s" + MSXQ + " THEN 10" + #CRLF$ +
    "80 END",
    47)

  MSXDict_Add("CSNG", #True, #False, "(convert to single)",
    "Converte um dado numerico para precisao simples.",
    "CSNG (argumento)",
    "A!=CSNG(B#)",
    "Fornece uma representacao em precisao simples do argumento. Quando o argumento for um " +
    "valor de precisao dupla, esta funcao fornecera um valor com seis digitos significativos e " +
    "um arredondamento de 4/5 no digito menos significativo. Assim, temos:" + #CRLF$ + #CRLF$ +
    "CSNG(0.666666666666667)     resulta em .666667" + #CRLF$ +
    "e" + #CRLF$ +
    "CSNG(0.333333333333333)     resulta em .333333",
    "10 REM PROGRAMA CSNG" + #CRLF$ +
    "20 A=12.15456723#" + #CRLF$ +
    "30 PRINT A,CSNG(A)",
    48)

  ; A pagina nao mostra "(F)" no cabecalho desta palavra (unico caso ate
  ; agora), mas o proprio texto da FUNCAO chama CSRLIN de "a funcao" -
  ; mantido EhFuncao=#True por essa referencia textual.
  MSXDict_Add("CSRLIN", #True, #False, "(cursor line)",
    "Fornece a linha em que se encontra o cursor.",
    "CSRLIN",
    "Y=CSRLIN",
    "A funcao CSRLIN fornece o numero da linha em que se encontra o cursor.",
    "10 REM PROGRAMA CSRLIN" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 FOR F=1 TO 20" + #CRLF$ +
    "40 A$=A$+" + MSXQ + "#" + MSXQ + #CRLF$ +
    "50 PRINT A$;CSRLIN" + #CRLF$ +
    "60 NEXT F",
    49)
EndProcedure

; --- Letra D (pagina 50-58 do livro = pagina 47-55 do PDF) ---
Procedure MSXDict_BuildLetterD()
  MSXDict_Add("DATA", #False, #False, "(data)",
    "Fornece os dados que serao lidos pelo comando READ.",
    "DATA constante [, constantes]",
    "DATA 123,ABC,456",
    "A instrucao DATA e utilizada para armazenar as constantes numericas e as strings que serao " +
    "acessadas pelo programa atraves da instrucao READ. O comando DATA nao e executavel, ou seja, " +
    "quando um programa que esta sendo executado encontra-o, a instrucao e desprezada e passa-se " +
    "a execucao da proxima instrucao. Assim, um comando DATA pode ser colocado em qualquer parte " +
    "do programa. Pode conter numeros e strings separados por uma virgula. Um programa pode " +
    "conter tantas instrucoes DATAs quantas forem necessarias. A instrucao READ acessara os dados " +
    "contidos nas instrucoes DATA na ordem em que foram definidas (por ordem do numero da linha e " +
    "pela sequencia dentro de uma instrucao). As strings que possuam uma virgula (,), dois-pontos " +
    "(:) ou um espaco no comeco ou no final, devem estar entre aspas (" + MSXQ + " " + MSXQ + "). As constantes " +
    "contidas nas instrucoes DATA devem estar de acordo com a variavel que a requisitara. O " +
    "comando DATA pode ser lido novamente desde o comeco ou a partir da linha especificada com o " +
    "uso do comando RESTORE.",
    "10 REM PROGRAMA DATA" + #CRLF$ +
    "20 DATA 0,1,3,5" + #CRLF$ +
    "30 DATA 3,4,1,0" + #CRLF$ +
    "40 DATA 4,6,0,9" + #CRLF$ +
    "50 FOR F= 1 TO 12" + #CRLF$ +
    "60 READ A" + #CRLF$ +
    "70 PRINT A" + #CRLF$ +
    "80 NEXT F",
    50)

  MSXDict_Add("DEF FN", #False, #False, "(define function)",
    "Define e atribui um nome a uma funcao escrita pelo usuario.",
    "DEF FN nome da funcao [(lista de parametros)] = (expressao da funcao definida)",
    "DEF FN ARCCOTH(X) = LOG((X+1)/(X-1))/2",
    "A instrucao DEF FN e utilizada para definir uma funcao que sera usada num programa. Nao " +
    "pode ser utilizada como um comando direto. O nome da funcao a ser definida deve ser " +
    "precedido pelo FN. A lista de parametros representa as variaveis que serao utilizadas pela " +
    "funcao. Por exemplo:" + #CRLF$ +
    "10 DEF FNE(X,Y,Z)=X+7*Y/Z" + #CRLF$ + #CRLF$ +
    "Quando a funcao for chamada, cada parametro assumira o valor que lhe for passado. Por " +
    "exemplo, em:" + #CRLF$ +
    "20 A=FNE(4,16,8)" + #CRLF$ + #CRLF$ +
    "X = 4, Y = 16 e Z = 8 e a funcao FNE e executada e retornara com o valor em A igual a 18. A " +
    "lista de parametros podera conter no maximo 9 deles. A expressao da funcao a ser definida " +
    "deve utilizar os parametros definidos. As variaveis do programa que contenham o mesmo nome " +
    "dos parametros utilizados pela funcao nao sao afetadas. Porem pode-se utilizar na expressao " +
    "da funcao uma variavel que nao foi definida na lista de parametros. Neste caso, quando a " +
    "funcao for chamada, ela assumira seu valor atual. Os valores passados para a funcao devem " +
    "ser do mesmo tipo dos que foram especificadas na funcao. Se eles nao coincidirem, uma " +
    "mensagem de erro sera enviada, indicando que o valor que foi passado para a funcao nao esta " +
    "de acordo com o tipo definido na funcao. A expressao da funcao deve ser apenas uma linha. A " +
    "funcao deve ser definida antes de ser chamada. Caso contrario, sera enviada uma mensagem de " +
    "erro.",
    "10 REM PROGRAMA DEF FN" + #CRLF$ +
    "20 PRINT" + MSXQ + " FORMULA DO DELTA" + MSXQ + #CRLF$ +
    "30 DEF FN D(A)=B*B-4*A*C" + #CRLF$ +
    "40 INPUT" + MSXQ + "A=" + MSXQ + ";A" + #CRLF$ +
    "50 INPUT" + MSXQ + "B=" + MSXQ + ";B" + #CRLF$ +
    "60 INPUT" + MSXQ + "C=" + MSXQ + ";C" + #CRLF$ +
    "70 PRINT" + MSXQ + "DELTA=" + MSXQ + ";FN D(A)",
    51)

  MSXDict_Add("DEFINT/DEFSNG/DEFDBL/DEFSTR", #False, #False,
    "(define integer) (define single) (define double) (define string)",
    "Define a correspondencia entre o primeiro caractere de uma variavel e o tipo de numero que " +
    "ela armazena.",
    "DEFINT caractere [-caractere] [, caractere]" + #CRLF$ +
    "DEFSNG caractere [-caractere] [, caractere]" + #CRLF$ +
    "DEFDBL caractere [-caractere] [, caractere]" + #CRLF$ +
    "DEFSTR caractere [-caractere] [, caractere]",
    "DEFINT A,I-K",
    "Este tipo de comando estabelece que os nomes das variaveis que comecam com as letras " +
    "especificadas deverao corresponder a um tipo especifico de variavel, ou seja:" + #CRLF$ + #CRLF$ +
    "- DEFINT - define que as variaveis armazenarao numeros inteiros" + #CRLF$ + #CRLF$ +
    "- DEFSNG - define que as variaveis armazenarao numeros de precisao simples" + #CRLF$ + #CRLF$ +
    "- DEFDBL - define que as variaveis armazenarao numeros de precisao dupla" + #CRLF$ + #CRLF$ +
    "- DEFSTR - define que as variaveis serao do tipo string." + #CRLF$ + #CRLF$ +
    "O tipo de variavel pode ser alterado durante um programa, desde que a prioridade quanto ao " +
    "tipo de variavel seja respeitada. A prioridade utilizada pelo MSX, e a seguinte:" + #CRLF$ +
    "- $ - variavel string" + #CRLF$ +
    "- # - variavel de precisao dupla" + #CRLF$ +
    "- ! - variavel de precisao simples" + #CRLF$ +
    "- % - variavel inteira" + #CRLF$ + #CRLF$ +
    "Por exemplo, uma variavel definida como inteira pode ser alterada para uma variavel de " +
    "precisao simples ou dupla ou para uma variavel string, mas uma variavel string nao pode ser " +
    "alterada.",
    "10 REM PROGRAMA DEFINT" + #CRLF$ +
    "20 DEFINT A,B,C" + #CRLF$ +
    "30 A=3.141592#" + #CRLF$ +
    "40 B=2.718281#" + #CRLF$ +
    "50 C=22.45525#" + #CRLF$ +
    "60 PRINT A,B,C",
    52)

  MSXDict_Add("DEFUSR", #False, #False, "(define user)",
    "Define um endereco para iniciar a execucao de uma sub-rotina em linguagem de maquina que " +
    "sera chamada pelo comando USR.",
    "DEFUSR [digito] = endereco para inicio de execucao",
    "DEFUSR1=&HE00A",
    "Este comando especifica o endereco inicial para a execucao de uma sub-rotina em linguagem " +
    "de maquina. A sub-rotina iniciara a execucao quando ela for chamada pela instrucao USR. O " +
    "digito a ser especificado deve ser um numero inteiro entre 0 e 9 e corresponde ao numero da " +
    "rotina USR a ser executada. Se o valor do digito for omitido, sera assumido o valor 0. O " +
    "endereco de inicio da rotina deve ser um numero entre 0 a 65535. O endereco de inicio de " +
    "sub-rotina pode ser redefinido posteriormente, ou seja, uma funcao DEF USR pode assumir " +
    "valores diferentes durante a execucao de um programa.",
    "10 DATA 3E,41,21,00,00,CD,4D,00,23,E5,D5,11,BF,03,ED,52,D1,E1,38,F1,C9" + #CRLF$ +
    "20 FOR I=0 TO 20" + #CRLF$ +
    "30 READ A$:POKE 60000!+I,VAL(" + MSXQ + "&H" + MSXQ + "+A$)" + #CRLF$ +
    "40 NEXT I" + #CRLF$ +
    "50 SCREEN 0:CLS:PRINT " + MSXQ + "APERTE <RETURN> PARA EXECUTAR" + MSXQ + #CRLF$ +
    "60 INPUT B$" + #CRLF$ +
    "70 DEF USR0=60000!" + #CRLF$ +
    "80 X=USR0 (0)" + #CRLF$ +
    "90 FOR T=1 TO 1000:NEXT T:CLS:END",
    53)

  MSXDict_Add("DELETE", #False, #False, "(delete)",
    "Apaga as linhas de um programa.",
    "DELETE [numero da linha A] [-numero da linha B]",
    "DELETE 10-230" + #CRLF$ + "DELETE 23" + #CRLF$ + "DELETE -120",
    "Este comando tem a funcao de apagar as linhas de um programa que esta na memoria. Pode-se " +
    "especificar uma linha individual ou uma sequencia de linhas." + #CRLF$ + #CRLF$ +
    "DELETE (linha A) - (linha B): apaga todas as linhas de programa comecando pela linha A e " +
    "terminando na linha B (inclusive)." + #CRLF$ + #CRLF$ +
    "DELETE (linha A): Apaga apenas a linha especificada." + #CRLF$ + #CRLF$ +
    "DELETE -(linha B): Apaga desde a primeira linha do programa ate a linha B (inclusive)." + #CRLF$ + #CRLF$ +
    "Voce pode apagar a linha que acabou de introduzir, ou que acaba de ser evidenciada por uma " +
    "mensagem de erro, digitando:" + #CRLF$ +
    "DELETE ." + #CRLF$ +
    "ou seja, ao inves de digitar um numero de linha, digitar ponto (.).",
    "10 REM PROGRAMA DELETE" + #CRLF$ +
    "20 FOR F=0 TO 500" + #CRLF$ +
    "30 PRINT" + MSXQ + "ESTE PROGRAMA SE AUTO DESTROI" + MSXQ + #CRLF$ +
    "40 NEXT F" + #CRLF$ +
    "50 DELETE -50",
    54)

  MSXDict_Add("DIM", #False, #False, "(dimension)",
    "Definicao de uma ou mais variaveis do tipo matriz, especificando o tipo de matriz e a sua " +
    "dimensao.",
    "DIM nome da variavel (valor maximo de um sub-indice, ...)" + #CRLF$ +
    "[,nome da variavel ...]",
    "DIM Y(15,20)" + #CRLF$ + "DIM A$(2,3),C(4,8)",
    "Utilizada para declarar variaveis do tipo matriz, bem como o tipo de matriz que a variavel " +
    "sera, alem da sua dimensao. Se durante a execucao de um programa for acessado um sub-indice " +
    "maior do que o assumido, uma mensagem de erro sera apresentada:" + #CRLF$ + #CRLF$ +
    "Subscript out of range" + #CRLF$ + #CRLF$ +
    "Numa sentenca DIM podem ser declaradas mais de uma matriz, desde que separadas por virgula." + #CRLF$ + #CRLF$ +
    "VARIAVEIS DE MATRIZ MULTIDIMENSIONAIS: As variaveis de matriz multidimensionais sao geradas " +
    "especificando-se dois ou mais valores maximos para o sub-indice. Por exemplo:" + #CRLF$ +
    "DIM A(3,4,5)" + #CRLF$ + #CRLF$ +
    "OMISSAO DA SENTENCA DIM: Quando se utilizar uma variavel do tipo matriz sem ter declarado " +
    "uma sentenca DIM, o valor maximo do sub-indice sera assumido como 10.",
    "10 REM PROGRAMA DIM" + #CRLF$ +
    "20 DIM I(12)" + #CRLF$ +
    "30 CLS:IA=1" + #CRLF$ +
    "40 FOR F= 1 TO 12" + #CRLF$ +
    "50 PRINT" + MSXQ + "INFLACAO DO MES" + MSXQ + ";F;" + MSXQ + ":" + MSXQ + #CRLF$ +
    "60 INPUT I(F)" + #CRLF$ +
    "70 IA=IA*(I(F)+100)/100" + #CRLF$ +
    "80 NEXT F" + #CRLF$ +
    "90 CLS" + #CRLF$ +
    "100 PRINT" + MSXQ + "INFLACAO ANUAL:" + MSXQ + ";IA*100-100",
    55)

  ; DRAW ocupa 3 paginas no livro (56-58), so com FORMATO/FUNCAO (sub-
  ; comandos S/A/C/M/U/D/R/L/E/F/G/H/B/N) - nao tem PROGRAMA EXEMPLO.
  MSXDict_Add("DRAW", #False, #False, "(draw)",
    "Desenha figuras na tela grafica (SCREEN 2 ou 3), de acordo com o sub-comando especificado.",
    "DRAW " + MSXQ + "sub-comandos" + MSXQ,
    "DRAW " + MSXQ + "U20D10L30R40" + MSXQ,
    "A instrucao DRAW desenha na tela de modo grafico a figura especificada pelo sub-comando. " +
    "Sao eles:" + #CRLF$ + #CRLF$ +
    "- Sn (n entre 0 e 255): Define a escala em que sera tracada uma reta, ou seja, (1/4 pontos " +
    "para n = 1). O valor inicial e S4." + #CRLF$ + #CRLF$ +
    "- An (n entre 0 e 3): Gira o sistema de coordenadas de 90 em 90 graus, sendo que o valor " +
    "inicial e A0." + #CRLF$ + #CRLF$ +
    "- Cn (n entre 0 e 15): Define a cor da linha que sera tracada. Se omitido, assumira C15 " +
    "(15 = branco)." + #CRLF$ +
    "  - 0 - transparente" + #CRLF$ +
    "  - 1 - negro" + #CRLF$ +
    "  - 2 - verde" + #CRLF$ +
    "  - 3 - verde claro" + #CRLF$ +
    "  - 4 - azul escuro" + #CRLF$ +
    "  - 5 - azul claro" + #CRLF$ +
    "  - 6 - vermelho escuro" + #CRLF$ +
    "  - 7 - azul celeste" + #CRLF$ +
    "  - 8 - vermelho" + #CRLF$ +
    "  - 9 - vermelho claro" + #CRLF$ +
    "  - 10 - amarelo escuro" + #CRLF$ +
    "  - 11 - amarelo claro" + #CRLF$ +
    "  - 12 - verde escuro" + #CRLF$ +
    "  - 13 - magenta" + #CRLF$ +
    "  - 14 - cinza" + #CRLF$ +
    "  - 15 - branco" + #CRLF$ + #CRLF$ +
    "- M x,y (x entre 0 e 255; y entre 0 e 191): Traca uma linha desde o ultimo ponto plotado " +
    "(posicao atual) ate a posicao definida por x e y." + #CRLF$ + #CRLF$ +
    "- M +-dx, +-dy (dx entre 0 e 255; dy entre 0 e 191): Traca uma linha desde a posicao atual " +
    "ate a posicao em que a coordenada x e x atual +-dx e a coordenada y e y atual +-dy." + #CRLF$ + #CRLF$ +
    "- Un: Traca uma linha vertical para cima desde a posicao atual ate uma distancia n, onde n " +
    "e o numero de pontos definido pelo sub-comando S. Quando omitido assume o valor 1." + #CRLF$ + #CRLF$ +
    "- Dn: Traca uma linha vertical para baixo desde a posicao atual ate uma distancia n, onde n " +
    "e o numero de pontos definido pelo sub-comando S. Quando omitido assume o valor 1." + #CRLF$ + #CRLF$ +
    "- Rn: Traca uma linha horizontal da esquerda para a direita desde a posicao atual ate uma " +
    "distancia n, onde n e o numero de pontos definido pelo sub-comando S. Quando omitido assume " +
    "o valor 1." + #CRLF$ + #CRLF$ +
    "- Ln: Traca uma linha horizontal da direita para a esquerda desde a posicao atual ate uma " +
    "distancia n, onde n e o numero de pontos definido pelo sub-comando S. Quando omitido assume " +
    "o valor 1." + #CRLF$ + #CRLF$ +
    "- En: E uma composicao dos sub-comandos U e R, ou seja, traca uma reta desde a posicao " +
    "atual ate a posicao em que no eixo X a distancia varie da esquerda para a direita de n " +
    "posicoes e no eixo Y a distancia varie de baixo para cima de n posicoes, onde n e o valor " +
    "definido pelo sub-comando S. Quando omitido assume o valor 1." + #CRLF$ + #CRLF$ +
    "- Fn: E uma composicao dos sub-comandos D e R, ou seja, traca uma reta desde a posicao " +
    "atual ate a posicao em que no eixo X a distancia varie da esquerda para a direita de n " +
    "posicoes e no eixo Y a distancia varie de cima para baixo de n posicoes, onde n e o valor " +
    "definido pelo sub-comando S. Quando omitido assume o valor 1." + #CRLF$ + #CRLF$ +
    "- Gn: E uma composicao dos sub-comandos D e L, ou seja, traca uma reta desde a posicao " +
    "atual ate a posicao em que no eixo X a distancia varie da direita para a esquerda de n " +
    "posicoes e no eixo Y a distancia varie de cima para baixo de n posicoes, onde n e o valor " +
    "definido pelo sub-comando S. Quando omitido assume o valor 1." + #CRLF$ + #CRLF$ +
    "- Hn: E uma composicao dos sub-comandos U e L, ou seja, traca uma reta desde a posicao " +
    "atual ate a posicao em que no eixo X a distancia varie da direita para a esquerda de n " +
    "posicoes e no eixo Y a distancia varie de baixo para cima de n posicoes, onde n e o valor " +
    "definido pelo sub-comando S. Quando omitido assume o valor 1." + #CRLF$ + #CRLF$ +
    "A posicao atual e armazenada apos um dos sub-comandos exceto S, A e C. Antes dos " +
    "sub-comandos que alteram o valor da posicao atual pode-se utilizar os comandos:" + #CRLF$ + #CRLF$ +
    "- B: Posiciona o cursor na coordenada especificada sem que a reta seja tracada. Por exemplo:" + #CRLF$ +
    "  BM 120,50" + #CRLF$ +
    "  posiciona o cursor na posicao de coordenadas (120,50)." + #CRLF$ + #CRLF$ +
    "- N: Traca a reta sem modificar o valor da posicao atual. Por exemplo:" + #CRLF$ +
    "  NU30" + #CRLF$ +
    "  traca a reta, porem a posicao do cursor nao se modifica." + #CRLF$ + #CRLF$ +
    "O comando DRAW traca graficos utilizando os sub-comandos citados anteriormente. Pode-se " +
    "utilizar varios sub-comandos dentro de um mesmo comando DRAW, sendo que eles serao " +
    "executados na ordem em que foram definidos. Por exemplo:" + #CRLF$ +
    "DRAW " + MSXQ + "BM20,40NU56R12" + MSXQ + #CRLF$ + #CRLF$ +
    "Os sub-comandos podem tambem ser definidos em uma variavel string. Por exemplo:" + #CRLF$ +
    "S$ = " + MSXQ + "BM0,50NG34F34" + MSXQ + #CRLF$ +
    "e podera ser executado especificando-se, depois do comando DRAW, a variavel string. Por " +
    "exemplo:" + #CRLF$ +
    "DRAW S$" + #CRLF$ + #CRLF$ +
    "Porem quando a variavel string for utilizada juntamente com outros sub-comandos do comando " +
    "DRAW, ou seja, entre as aspas (" + MSXQ + " " + MSXQ + ") ela devera aparecer entre um X e um ponto e virgula " +
    "(;). Por exemplo:" + #CRLF$ +
    "DRAW " + MSXQ + "S6XS$;" + MSXQ + #CRLF$ + #CRLF$ +
    "Quando uma variavel numerica for utilizada dentro de um comando DRAW para expressar o valor " +
    "do angulo, a cor ou a distancia, ela devera ser precedida pelo sinal de igual (=) e sucedida " +
    "por um ponto e virgula (;). Por exemplo:" + #CRLF$ +
    "N=3" + #CRLF$ +
    "DRAW " + MSXQ + "BM45,60U=N;" + MSXQ + #CRLF$ + #CRLF$ +
    "Observacao: Antes do comando DRAW, deve-se executar a instrucao:" + #CRLF$ +
    "SCREEN 2 ou SCREEN 3" + #CRLF$ +
    "que correspondem as telas graficas.",
    "",
    56)
EndProcedure

; --- Letra E (pagina 59-64 do livro = pagina 56-61 do PDF) ---
Procedure MSXDict_BuildLetterE()
  MSXDict_Add("END", #False, #False, "(end)",
    "Termina a execucao de um programa, fecha todos os arquivos e retorna ao estado de espera " +
    "de um comando direto.",
    "END",
    "END",
    "Tem a funcao de finalizar a execucao de um programa, fechando os arquivos abertos durante o " +
    "programa e retornando ao estado de espera de um comando direto. E um comando diferente do " +
    "comando STOP, pois o comando END nao ocasiona uma mensagem de BREAK na tela. Quando as " +
    "sub-rotinas sao escritas logo abaixo do programa principal, costuma-se colocar um comando END " +
    "como sendo a ultima linha do programa principal. Desta forma, evita-se que as sub-rotinas " +
    "sejam executadas ao final da execucao do programa principal. O comando END pode ser colocado " +
    "em qualquer parte do programa e quantas vezes forem necessarias. Por exemplo, quando uma " +
    "condicao causa uma ramificacao, pode-se colocar um comando END ao final de cada ramificacao. " +
    "O comando END no final de programa e opcional. Para continuar a execucao de um programa que " +
    "foi parado por um comando END, deve-se digitar RUN ou GOTO pois, com o comando CONT, nao sera " +
    "possivel o retorno a execucao.",
    "10 ' END" + #CRLF$ +
    "20 CLS:PRINT" + MSXQ + "Agora, o programa principal esta sendo executado." + MSXQ + #CRLF$ +
    "30 FOR F=333 TO 0 STEP -1" + #CRLF$ +
    "40 LOCATE 10,7:PRINT USING" + MSXQ + "###" + MSXQ + ";F" + #CRLF$ +
    "50 NEXT F:CLS" + #CRLF$ +
    "60 GOSUB 90" + #CRLF$ +
    "70 PRINT" + MSXQ + "O comando END termina o programa, evitando que a sub-rotina da linha 90 seja executada novamente." + MSXQ + #CRLF$ +
    "80 END" + #CRLF$ +
    "90 PRINT" + MSXQ + "Agora, a sub-rotina da linha 90 esta sendo executada." + MSXQ + #CRLF$ +
    "100 FOR F=0 TO 333" + #CRLF$ +
    "110 LOCATE 10,7:PRINT USING " + MSXQ + "###" + MSXQ + ";F" + #CRLF$ +
    "120 NEXT F" + #CRLF$ +
    "130 RETURN",
    59)

  MSXDict_Add("EOF", #True, #False, "(end of file)",
    "Utilizado para testar o fim de um arquivo.",
    "EOF (numero do arquivo)",
    "IF EOF(1) THEN CLOSE#1:END",
    "EOF e utilizado como uma variavel para o controle de fim de arquivo. Quando um comando READ " +
    "e executado e um registro foi lido do arquivo, EOF resulta em 0. Mas se o arquivo nao " +
    "possuia mais nenhum registro, EOF resulta em -1. EOF tambem e utilizado para testar o final " +
    "de um arquivo e impedir erros do tipo:" + #CRLF$ +
    "Input past end" + #CRLF$ +
    "ou seja, entrada depois de um fim de arquivo.",
    "10 REM PROGRAMA EOF" + #CRLF$ +
    "20 OPEN" + MSXQ + "cas:II" + MSXQ + " FOR INPUT AS #1" + #CRLF$ +
    "30 IF EOF(1) THEN 70" + #CRLF$ +
    "40 INPUT #1,A$" + #CRLF$ +
    "50 GOTO 30" + #CRLF$ +
    "60 CLOSE #1",
    60)

  MSXDict_Add("ERASE", #False, #False, "(erase)",
    "Apaga, da memoria, as variaveis do tipo matriz especificadas na instrucao.",
    "ERASE nome da variavel [, nome da variavel ...]",
    "ERASE C,D",
    "Libera a memoria apenas na area utilizada pelas variaveis do tipo matriz especificadas na " +
    "instrucao ERASE. A area liberada pode ser utilizada para outros propositos, ou entao para um " +
    "novo redimensionamento das variaveis apagadas. Se for feita uma tentativa de " +
    "redimensionamento de uma variavel que nao foi apagada da memoria, ocorrera um erro do tipo:" + #CRLF$ +
    "Redimensioned array",
    "10 DIM I(9)" + #CRLF$ +
    "20 FOR F=1 TO 9" + #CRLF$ +
    "30 READ I(F)" + #CRLF$ +
    "40 PRINT I(F)" + #CRLF$ +
    "50 NEXT F" + #CRLF$ +
    "60 ERASE I" + #CRLF$ +
    "70 FOR F=1 TO 9" + #CRLF$ +
    "80 PRINT I(F)" + #CRLF$ +
    "90 NEXT F" + #CRLF$ +
    "100 DATA 1,2,3,4,5,6,7,8,9",
    61)

  MSXDict_Add("ERL/ERR", #True, #False, "(error line/error)",
    "Fornece o numero da linha em que ocorreu um erro e o numero do erro respectivamente.",
    "ERL" + #CRLF$ + "ERR",
    "L=ERL" + #CRLF$ + "E=ERR",
    "As variaveis ERL e ERR sao geralmente utilizadas nas rotinas de erros de um programa com a " +
    "instrucao IF...THEN. Quando um erro e manuseado por um programa, a variavel ERR fornece o " +
    "codigo referente ao erro ocorrido, enquanto que a variavel ERL fornece o numero da linha em " +
    "que o erro foi encontrado. Se usado como um comando direto, ERL contera 65535. Para testar se " +
    "o erro ocorreu por um comando direto, digite:" + #CRLF$ +
    "IF 65535=ERL THEN ..." + #CRLF$ +
    "Caso contrario, comande:" + #CRLF$ +
    "IF ERL=(numero da linha) THEN ..." + #CRLF$ +
    "IF ERR=(codigo de erro) THEN ...",
    "10 REM PROGRAMA ERR/ERL" + #CRLF$ +
    "20 ON ERROR GOTO 80" + #CRLF$ +
    "30 CLS" + #CRLF$ +
    "40 INPUT" + MSXQ + "DIGITE UM NUMERO NEGATIVO" + MSXQ + ";A" + #CRLF$ +
    "50 PRINT SQR(A)" + #CRLF$ +
    "60 FOR F=1 TO 500: NEXT F" + #CRLF$ +
    "70 GOTO 30" + #CRLF$ +
    "80 PRINT" + MSXQ + "OCORREU O ERRO" + MSXQ + ";ERR;" + MSXQ + "NA LINHA" + MSXQ + ";ERL" + #CRLF$ +
    "90 PRINT" + MSXQ + "POIS NAO EXISTE RAIZ DE NUMERO NEGATIVO" + MSXQ + #CRLF$ +
    "100 FOR F=1 TO 1000:NEXT F" + #CRLF$ +
    "110 RUN 20",
    62)

  MSXDict_Add("ERROR", #False, #False, "(error)",
    "Simula a ocorrencia de um erro e permite que o usuario defina um codigo de erro " +
    "correspondente.",
    "ERROR numero do erro",
    "ERROR 200",
    "O comando ERROR simulara a ocorrencia de um erro expondo a mensagem correspondente se o " +
    "numero do erro coincidir com um dos erros utilizados pelo BASIC MSX. Para definir seu " +
    "proprio codigo de erro, utilize um valor maior do que qualquer valor usado pelo BASIC. Veja " +
    "no apendice a lista de erros e suas respectivas mensagens. O numero do erro deve estar entre " +
    "0 e 255, sendo que o BASIC MSX utiliza os codigos de 0 a 59. Estes codigos podem depois ser " +
    "convenientemente manuseados em uma rotina de erro. Por exemplo:" + #CRLF$ +
    "10 ON ERROR GOTO 1000" + #CRLF$ +
    "120 IF A$=" + MSXQ + "S" + MSXQ + " THEN ERROR 250" + #CRLF$ +
    "1000 IF ERR=250 THEN PRINT " + MSXQ + "DESCULPE-ME" + MSXQ + #CRLF$ + #CRLF$ +
    "Se um termo ERROR especificando um codigo nao possuir uma mensagem definida, o BASIC " +
    "respondera com uma mensagem do tipo:" + #CRLF$ +
    "Unprintable error" + #CRLF$ +
    "que sera exposta na tela e suspendera a execucao do programa.",
    "10 REM PROGRAMA ERROR" + #CRLF$ +
    "20 ON ERROR GOTO 80" + #CRLF$ +
    "30 PRINT" + MSXQ + "Digite a tecla A ." + MSXQ + #CRLF$ +
    "40 A$=INKEY$" + #CRLF$ +
    "50 IF A$=" + MSXQ + MSXQ + " THEN 40" + #CRLF$ +
    "60 IF A$<>" + MSXQ + "A" + MSXQ + " AND A$<>" + MSXQ + "a" + MSXQ + " THEN ERROR 230" + #CRLF$ +
    "70 END" + #CRLF$ +
    "80 PRINT " + MSXQ + "A tecla A!!! (por favor)" + MSXQ + #CRLF$ +
    "90 FOR F=1 TO 500:NEXT F" + #CRLF$ +
    "100 RUN",
    63)

  MSXDict_Add("EXP", #True, #False, "(exponential)",
    "Fornece o valor de e elevado a X, ou seja, da funcao exponencial natural de X.",
    "EXP (argumento)",
    "E=EXP(1)",
    "Fornece o valor da exponencial natural do argumento especificado (e elevado a X, onde " +
    "e=2.7182818284). O valor do argumento pode ser menor ou igual a 145,06286085862. Se o valor " +
    "do argumento for maior, uma mensagem do tipo:" + #CRLF$ +
    "Overflow" + #CRLF$ +
    "aparecera na tela.",
    "10 REM PROGRAMA EXP" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 SCREEN 2" + #CRLF$ +
    "40 FOR F=0 TO 255 STEP .5" + #CRLF$ +
    "50 PSET(F,191-290*EXP(-F/30))" + #CRLF$ +
    "60 NEXT F" + #CRLF$ +
    "70 GOTO 70",
    64)
EndProcedure

; --- Letra F (pagina 65-68 do livro = pagina 62-65 do PDF) ---
Procedure MSXDict_BuildLetterF()
  MSXDict_Add("FIX", #True, #False, "(fix)",
    "Fornece apenas a parte inteira de um dado numerico.",
    "FIX (argumento)",
    "F=FIX(B/3)",
    "A funcao FIX fornece apenas a parte inteira do argumento especificado, ou seja, fornece uma " +
    "representacao truncada de um dado numerico, sendo que todos os digitos a direita do ponto " +
    "decimal sao desprezados. O argumento pode ser uma constante, uma variavel numerica, uma " +
    "variavel numerica do tipo matriz ou entao uma expressao matematica. A grande diferenca entre " +
    "as funcoes INT e FIX e que a funcao INT retorna com o maior inteiro possivel, enquanto que a " +
    "funcao FIX retorna com a parte inteira do argumento truncado, desprezando as casas decimais. " +
    "Portanto, equivale a:" + #CRLF$ +
    "SGN(X)*INT(ABS(X))" + #CRLF$ +
    "pois esta diferenca existe apenas para os numeros negativos.",
    "10 REM PROGRAMA FIX" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 FOR F=1 TO 20" + #CRLF$ +
    "40 A=500-RND(-TIME)*1000" + #CRLF$ +
    "50 PRINT A;" + MSXQ + "............." + MSXQ + ";FIX(A)" + #CRLF$ +
    "60 NEXT F",
    65)

  ; FOR-NEXT ocupa 3 paginas (66-68) com dois exemplos intermediarios (a
  ; tabela F/G do programa STEP e o triangulo de asteriscos dos lacos
  ; multiplos) alem do PROGRAMA EXEMPLO final - todos preservados na FUNCAO.
  MSXDict_Add("FOR-NEXT", #False, #False, "(for-next)",
    "Repete a execucao de um bloco de instrucoes entre um comando FOR e o seu correspondente " +
    "NEXT.",
    "FOR variavel = valor inicial TO valor final [STEP incremento]" + #CRLF$ +
    "NEXT [variavel]",
    "FOR J=0 TO 100 STEP 2" + #CRLF$ + "NEXT J",
    "O comando FOR-NEXT executa, repetidamente, um bloco de instrucoes contido entre as " +
    "instrucoes FOR e NEXT correspondentes. A variavel que controla o laco FOR-NEXT varia desde " +
    "valor inicial ate o valor final sendo acrescida pelo valor do incremento todas as vezes que " +
    "o comando NEXT correspondente for executado. Quando o incremento nao e definido, e adotado o " +
    "valor 1. Por exemplo:" + #CRLF$ +
    "10 REM PROGRAMA FOR...NEXT...STEP..." + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 FOR F=1 TO 40 STEP 2" + #CRLF$ +
    "40 G=G+F" + #CRLF$ +
    "50 PRINT F,G" + #CRLF$ +
    "60 NEXT F" + #CRLF$ + #CRLF$ +
    "apresentando na tela:" + #CRLF$ +
    "1  1" + #CRLF$ + "3  4" + #CRLF$ + "5  9" + #CRLF$ + "7  16" + #CRLF$ + "9  25" + #CRLF$ +
    "11  36" + #CRLF$ + "13  49" + #CRLF$ + "15  64" + #CRLF$ + "17  81" + #CRLF$ + "19  100" + #CRLF$ +
    "21  121" + #CRLF$ + "23  144" + #CRLF$ + "25  169" + #CRLF$ + "27  196" + #CRLF$ + "29  225" + #CRLF$ +
    "31  256" + #CRLF$ + "33  289" + #CRLF$ + "35  324" + #CRLF$ + "37  361" + #CRLF$ + "39  400" + #CRLF$ + #CRLF$ +
    "LACOS MULTIPLOS: Um loop FOR-NEXT pode ser colocado dentro de outro do mesmo tipo. Em tal " +
    "caso, o laco interior devera estar completamente incluido no laco exterior e para cada laco " +
    "devera se utilizar variaveis diferentes. Por exemplo:" + #CRLF$ +
    "10 FOR I=1 TO 5" + #CRLF$ +
    "20 FOR J=1 TO I" + #CRLF$ +
    "30 PRINT" + MSXQ + "*" + MSXQ + ";" + #CRLF$ +
    "40 NEXT J" + #CRLF$ +
    "50 PRINT" + #CRLF$ +
    "60 NEXT I" + #CRLF$ + #CRLF$ +
    "apresentando na tela:" + #CRLF$ +
    "*" + #CRLF$ + "**" + #CRLF$ + "***" + #CRLF$ + "****" + #CRLF$ + "*****" + #CRLF$ + #CRLF$ +
    "Com uma instrucao NEXT pode-se terminar varias instrucoes FOR. Porem, nao se pode omitir o " +
    "nome das variaveis, que devem estar dispostos sequencialmente, sendo que o laco mais interno " +
    "deve estar em primeiro lugar e as variaveis devem estar separadas por virgula. Por exemplo:" + #CRLF$ +
    "10 FOR I=0 TO 10" + #CRLF$ +
    "20 FOR J=0 TO 5" + #CRLF$ +
    "." + #CRLF$ + "." + #CRLF$ + "." + #CRLF$ +
    "10010 NEXT J,I",
    "10 REM PROGRAMA FOR...NEXT" + #CRLF$ +
    "20 FOR F=1 TO 20" + #CRLF$ +
    "30 G=G+F" + #CRLF$ +
    "40 PRINT F,G" + #CRLF$ +
    "50 NEXT F",
    66)

  MSXDict_Add("FRE", #True, #False, "(free)",
    "Fornece o numero de bytes livres na RAM de uma area de memoria nao utilizada pelo BASIC " +
    "MSX.",
    "FRE (X)" + #CRLF$ + "FRE (" + MSXQ + MSXQ + ")",
    "FRE(0)" + #CRLF$ + "FRE(" + MSXQ + MSXQ + ")",
    "FRE (X) fornece o numero de bytes na memoria que podem ser usados por um programa BASIC, " +
    "arquivos de texto, arquivos de um programa em linguagem de maquina, etc., ou seja, a area " +
    "livre na memoria. O valor de X pode ser um valor numerico qualquer." + #CRLF$ + #CRLF$ +
    "FRE (" + MSXQ + MSXQ + ") fornece o numero de bytes livre na area da memoria utilizada pelas " +
    "variaveis strings.",
    "10 REM PROGRAMA FRE" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 PRINT" + MSXQ + "Existem" + MSXQ + ";FRE(1);" + MSXQ + "bytes livres e" + MSXQ + #CRLF$ +
    "40 PRINTFRE(" + MSXQ + MSXQ + ");" + MSXQ + "bytes para strings." + MSXQ,
    68)
EndProcedure

; --- Letra G (pagina 69-70 do livro = pagina 66-67 do PDF) ---
Procedure MSXDict_BuildLetterG()
  MSXDict_Add("GOSUB-RETURN", #False, #False, "(go to subroutine - return)",
    "Transfere a execucao do programa para a sub-rotina especificada e indica o ponto de retorno " +
    "ao programa principal.",
    "GOSUB numero da linha A" + #CRLF$ + "RETURN [numero da linha B]",
    "GOSUB 1000",
    "O comando GOSUB transfere a execucao do programa para a sub-rotina que comeca na linha A, " +
    "enquanto que o comando RETURN indica o fim da sub-rotina e o retorno a linha B do programa " +
    "principal. Quando o numero de linha B e omitido, o retorno ao programa principal se da na " +
    "linha imediatamente seguinte a que contem o correspondente GOSUB. O numero das linhas A e B " +
    "devem estar entre 0 e 65535. Uma sub-rotina pode ser chamada quantas vezes forem " +
    "necessarias. Por exemplo (com os diagramas de fluxo do livro representados aqui apenas pelo " +
    "codigo, sem as setas graficas):" + #CRLF$ + #CRLF$ +
    "10 GOSUB 1000" + #CRLF$ + #CRLF$ +
    "20 GOSUB 1000" + #CRLF$ + #CRLF$ +
    "1000 (sub rotina)" + #CRLF$ + #CRLF$ +
    "2000 RETURN" + #CRLF$ + #CRLF$ +
    "Uma sub-rotina pode chamar outra sub-rotina, porem o comportamento da multi-execucao " +
    "dependera da capacidade da memoria existente." + #CRLF$ + #CRLF$ +
    "10 GOSUB 100" + #CRLF$ + #CRLF$ +
    "100 (sub rotina)" + #CRLF$ + #CRLF$ +
    "110 GOSUB 1000" + #CRLF$ +
    "200 RETURN" + #CRLF$ +
    "1000 (sub rotina)" + #CRLF$ + #CRLF$ +
    "2000 RETURN",
    "10 REM GOSUB ... RETURN" + #CRLF$ +
    "20 GOSUB 1000" + #CRLF$ +
    "30 GOSUB 2000" + #CRLF$ +
    "40 PRINT" + MSXQ + "ESTA ROTINA FAZ O MINIMO POSSIVEL" + MSXQ + #CRLF$ +
    "50 FOR F=1 TO 1000:NEXT F:PRINT" + #CRLF$ +
    "60 RUN" + #CRLF$ +
    "1000 PRINT" + MSXQ + "ESTA SUB-ROTINA SO IMPRIME" + MSXQ + #CRLF$ +
    "1010 RETURN" + #CRLF$ +
    "2000 PRINT" + MSXQ + "ESTA SUB-ROTINA SO IMPRIME" + MSXQ + #CRLF$ +
    "2010 RETURN",
    69)

  MSXDict_Add("GOTO", #False, #False, "(goto)",
    "Desvia incondicionalmente a sequencia normal do programa para uma linha especificada.",
    "GOTO numero da linha",
    "GOTO 390",
    "A execucao do programa e transferida para a linha especificada pelo comando GOTO. Se esta " +
    "contiver uma instrucao valida, sera executada e, depois dela, as linhas seguintes. Se a " +
    "linha indicada, porem, contiver uma instrucao nao executavel (REM ou DATA), o micro a " +
    "pulara passando para a primeira linha que contiver um comando valido, a partir da indicada " +
    "pelo comando GOTO. Se a linha indicada pelo comando GOTO, contiver uma instrucao mal-escrita, " +
    "a tela exibira a mensagem de erro:" + #CRLF$ +
    "Syntax error in (linha que contem o GOTO)" + #CRLF$ +
    "Se o numero da linha indicada pelo GOTO nao existir, sera ativada a mensagem de erro:" + #CRLF$ +
    "Undefined line number in (linha com GOTO)" + #CRLF$ +
    "GOTO pode ser executado com comando direto.",
    "10 ' GOTO" + #CRLF$ +
    "20 PRINT" + MSXQ + "Linha 20" + MSXQ + ":GOTO 50" + #CRLF$ +
    "30 PRINT" + MSXQ + "Linha 30" + MSXQ + #CRLF$ +
    "40 PRINT" + MSXQ + "Linha 40" + MSXQ + ":GOTO 60" + #CRLF$ +
    "50 PRINT" + MSXQ + "Linha 50" + MSXQ + ":GOTO 30" + #CRLF$ +
    "60 PRINT" + MSXQ + "Linha 60" + MSXQ + #CRLF$ +
    "70 PRINT" + MSXQ + "Linha 70" + MSXQ + ":GOTO 90" + #CRLF$ +
    "80 PRINT" + MSXQ + "Linha 80" + MSXQ + ":GOTO 70" + #CRLF$ +
    "90 PRINT" + MSXQ + " F I M" + MSXQ,
    70)
EndProcedure

; --- Letra H (pagina 71 do livro = pagina 68 do PDF) ---
Procedure MSXDict_BuildLetterH()
  MSXDict_Add("HEX$", #True, #False, "(hexadecimal dollar)",
    "Transforma um numero em uma expressao hexadecimal na forma de uma string.",
    "HEX$ (X)",
    "PRINT HEX$(13)",
    "A funcao HEX$ transforma um dado numerico em uma expressao hexadecimal na forma de uma " +
    "string. X pode assumir um valor entre -32768 e 65535. Para X negativo, antes e calculado seu " +
    "complemento (65536 - X) e a partir do resultado desta operacao e feita a transformacao, ou " +
    "seja:" + #CRLF$ +
    "HEX$ (-X) = HEX$ (65536-X)",
    "10 REM HEX$" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 PRINT" + MSXQ + " HEXADECIMAL ***** ALEPH PUBLICACOES" + MSXQ + #CRLF$ +
    "40 PRINT" + #CRLF$ +
    "50 INPUT" + MSXQ + " QUANTOS NUMEROS" + MSXQ + ";NS" + #CRLF$ +
    "60 PRINT :DIM H(NS)" + #CRLF$ +
    "70 CLS" + #CRLF$ +
    "80 PRINT" + MSXQ + " HEXADECIMAL ***** ALEPH PUBLICACOES" + MSXQ + #CRLF$ +
    "90 FOR F=1 TO NS" + #CRLF$ +
    "100 INPUT" + MSXQ + "NUMERO" + MSXQ + ";H(F)" + #CRLF$ +
    "110 NEXT F" + #CRLF$ +
    "120 CLS" + #CRLF$ +
    "130 PRINT" + MSXQ + " HEXADECIMAL ***** ALEPH PUBLICACOES" + MSXQ + #CRLF$ +
    "140 FOR F=1 TO NS" + #CRLF$ +
    "150 PRINT" + MSXQ + "DECIMAL" + MSXQ + "," + MSXQ + "HEXADECIMAL" + MSXQ + #CRLF$ +
    "160 PRINT H(F),HEX$(H(F))" + #CRLF$ +
    "170 NEXT F",
    71)
EndProcedure

; --- Letra I (pagina 72-80 do livro = pagina 69-77 do PDF) ---
; Nao ha letra J no dicionario - o livro pula de INTERVAL ON/OFF/STOP (80)
; direto para KEY (81).
Procedure MSXDict_BuildLetterI()
  MSXDict_Add("IF-THEN-ELSE", #False, #False, "(if-then-else)",
    "Permite a bifurcacao na execucao do programa em funcao do cumprimento de uma condicao.",
    "IF condicao THEN comando se condicao verdadeira" + #CRLF$ +
    "[ELSE comando se condicao falsa]",
    "IF A$=" + MSXQ + "MSX" + MSXQ + " THEN GOTO 200 ELSE 300",
    "Se a condicao for verdadeira, sera executado o comando apos o termo THEN. Caso contrario, ou " +
    "seja, se a condicao for falsa, o comando apos o termo THEN e ignorado e sera executado o " +
    "comando apos o termo ELSE. Por exemplo:" + #CRLF$ +
    "X = 3 e Y = 8   IF X < Y ... (verdadeiro)" + #CRLF$ +
    "X = 9 e Y = 8   IF X < Y ... (falso)" + #CRLF$ +
    "O comando apos o termo THEN pode inclusive ser um comando nulo, ou seja, nao possuir nenhum " +
    "comando. Se a condicao for uma expressao entre parenteses, assumira o valor -1 se verdadeira, " +
    "e 0 se falsa. Por exemplo, na instrucao:" + #CRLF$ +
    "IF (A$=" + MSXQ + "MSX" + MSXQ + ")=-1 THEN PRINT " + MSXQ + "OK" + MSXQ + #CRLF$ +
    "sera impresso um " + MSXQ + "OK" + MSXQ + ", se a condicao for verdadeira. No formato " +
    "IF-THEN-GOTO pode-se omitir o termo THEN ou o termo GOTO. Por exemplo, se digitarmos:" + #CRLF$ +
    "IF A$=" + MSXQ + "MSX" + MSXQ + " THEN 30   ou" + #CRLF$ +
    "IF A$=" + MSXQ + "MSX" + MSXQ + " GOTO 30" + #CRLF$ +
    "obteremos o mesmo resultado, pois as duas expressoes tem o mesmo significado. Porem, no " +
    "formato IF-THEN-ELSE-GOTO, o termo ELSE pode ser seguido do comando GOTO numero da linha ou " +
    "simplesmente do numero da linha (GOTO pode ser omitido, e mesmo assim, a execucao sera " +
    "desviada, conforme o resultado da condicao para o numero da linha indicada). Depois do termo " +
    "THEN e do termo ELSE, podem ser escritas varias sentencas. Elas serao executadas " +
    "sequencialmente, comecando pela esquerda. Estas sentencas devem ser separadas por " +
    MSXQ + "dois pontos" + MSXQ + " (:)." + #CRLF$ + #CRLF$ +
    "COMANDO IF-THEN-ELSE ENCADEADOS: Depois de um termo THEN ou de um termo ELSE, pode ser " +
    "tambem comandada uma nova condicao. A este tipo de sentenca da-se o nome de comando " +
    "encadeado.",
    "10 REM IF ... THEN ... ELSE" + #CRLF$ +
    "20 CLS : A=INT(10*RND(-TIME)) : PRINT" + #CRLF$ +
    "30 INPUT " + MSXQ + "Adivinhe o numero que pensei (0-9)." + MSXQ + ";N : BEEP" + #CRLF$ +
    "40 IF N<>A THEN GOTO 80 ELSE 50" + #CRLF$ +
    "50 PRINT " + MSXQ + "Muito bem, voce acertou !!!" + MSXQ + #CRLF$ +
    "60 FOR F=1 TO 1000 : NEXT F" + #CRLF$ +
    "70 GOTO 20" + #CRLF$ +
    "80 PRINT " + MSXQ + "Voce errou! Tente outra vez!" + MSXQ + #CRLF$ +
    "90 GOTO 30",
    72)

  MSXDict_Add("INKEY$", #True, #False, "(inkey dollar)",
    "Obtem o caractere da tecla pressionada.",
    "INKEY$",
    "C$=INKEY$",
    "A funcao INKEY$ obtem o caractere da tecla (exceto CTRL + STOP, SHIFT e CTRL) que esta sendo " +
    "pressionada. Se nenhuma tecla estiver pressionada, o resultado sera um caractere nulo.",
    "10 REM INKEY$" + #CRLF$ +
    "20 X=128" + #CRLF$ +
    "30 Y=96" + #CRLF$ +
    "40 SCREEN 2" + #CRLF$ +
    "50 PSET(128,96),10" + #CRLF$ +
    "60 DRAW" + MSXQ + "E2F2G2H2" + MSXQ + #CRLF$ +
    "70 X=X-(INKEY$=" + MSXQ + "D" + MSXQ + ")+(INKEY$=" + MSXQ + "A" + MSXQ + ")" + #CRLF$ +
    "80 Y=Y-(INKEY$=" + MSXQ + "X" + MSXQ + ")+(INKEY$=" + MSXQ + "W" + MSXQ + ")" + #CRLF$ +
    "90 PSET(X,Y),10" + #CRLF$ +
    "100 GOTO 60",
    73)

  MSXDict_Add("INP", #True, #True, "(input)",
    "Le os dados da via de acesso especificada.",
    "INP (numero da via de acesso)",
    "A=INP(15)",
    "Este comando le dados atraves da via de acesso especificada pelo numero entre parenteses. " +
    "Este numero pode ser fornecido atraves de uma constante, uma variavel numerica, uma variavel " +
    "do tipo matriz ou uma expressao matematica e o seu valor deve estar compreendido entre 0 e " +
    "255.",
    "10 CLS:PRINT" + MSXQ + "EXPERIMENTE APERTAR <CAPS LOCK> !" + MSXQ + #CRLF$ +
    "20 LOCATE 10,10:X=INP(170):IF X=26 THEN PRINT" + MSXQ + "MAIUSCULAS" + MSXQ + " ELSE PRINT" + MSXQ + "minusculas" + MSXQ + #CRLF$ +
    "30 GOTO 20",
    74)

  MSXDict_Add("INPUT", #False, #False, "(input)",
    "Introduz o valor de uma variavel atraves do teclado.",
    "INPUT [" + MSXQ + "mensagem" + MSXQ + ";] variavel" + #CRLF$ +
    "[, variavel] ...",
    "INPUT" + MSXQ + "QUAL O SEU NOME" + MSXQ + ";N$",
    "Quando um comando INPUT e encontrado no programa, um ponto de interrogacao e colocado na " +
    "tela e a execucao do programa e interrompida a espera de que um dado seja fornecido pelo " +
    "usuario via teclado. Quando a mensagem e especificada, ela e impressa na tela, seguida do " +
    "ponto de interrogacao. Deve-se digitar o dado requisitado que sera transferido para a " +
    "variavel ou variaveis na ordem em que foram fornecidos ao MSX. O numero de dados a serem " +
    "introduzidos deve ser igual ao numero de variaveis, sendo que cada dado deve ser separado " +
    "por uma virgula. Se for digitado um numero maior do que o necessario, aparecera na tela uma " +
    "mensagem do tipo:" + #CRLF$ +
    "Extra ignored" + #CRLF$ +
    "indicando que os dados excedentes foram ignorados e se passa a execucao do proximo comando. " +
    "Porem, se o numero de dados introduzidos for menor do que o requisitado, aparecerao na tela " +
    "dois pontos de interrogacao (??) indicando que o MSX esta a espera de mais dados. O tipo de " +
    "dado introduzido deve estar de acordo com o tipo de variavel especificado, caso contrario, " +
    "uma mensagem do tipo:" + #CRLF$ +
    "Redo from start" + #CRLF$ +
    "aparecera na tela, e o comando INPUT sera executado novamente. Digitando CTRL + STOP ou " +
    "CTRL + C, o MSX retorna ao nivel de comando direto mandando uma mensagem do tipo:" + #CRLF$ +
    "Break in (numero da linha do comando INPUT)" + #CRLF$ +
    "Para continuar a execucao, basta comandar CONT e o programa retornara a execucao do comando " +
    "INPUT.",
    "10 REM PROGRAMA INPUT" + #CRLF$ +
    "20 PRINT" + MSXQ + "TUDO O QUE FOR ESCRITO DEPOIS DO PONTO DE INTERROGACAO, SERA ESCRITO NA TELA!" + MSXQ + #CRLF$ +
    "30 INPUT" + MSXQ + "QUAL O SEU NOME" + MSXQ + ";A$" + #CRLF$ +
    "40 PRINT A$" + #CRLF$ +
    "50 END",
    75)

  MSXDict_Add("INPUT#", #False, #False, "(input number)",
    "Le dados de um arquivo aberto, associando-os as variaveis de um programa.",
    "INPUT # numero do arquivo, lista de variaveis",
    "INPUT#1,A,B$",
    "A instrucao INPUT# le dados de um arquivo que foi aberto por uma instrucao OPEN e associa " +
    "os dados as variaveis listadas. O numero do arquivo deve ser um numero maior do que zero e " +
    "menor ou igual ao numero de arquivos especificado em MAXFILES. A lista de variaveis inclui " +
    "as variaveis numericas, alfanumericas (strings) e as indexadas.",
    "10 REM PROGRAMA INPUT#" + #CRLF$ +
    "20 OPEN " + MSXQ + "CAS:II" + MSXQ + " FOR INPUT AS #1" + #CRLF$ +
    "30 IF EOF(1)=-1 THEN 70" + #CRLF$ +
    "40 INPUT #1,A$" + #CRLF$ +
    "50 PRINT A$:BEEP" + #CRLF$ +
    "60 GOTO 30" + #CRLF$ +
    "70 CLOSE #1",
    76)

  MSXDict_Add("INPUT$", #True, #False, "(input dollar)",
    "Le um numero especificado de caracteres introduzidos pelo teclado ou atraves de um arquivo.",
    "INPUT$ (numero de caracteres)" + #CRLF$ +
    "INPUT$ (numero de caracteres, [, # numero do arquivo])",
    "X$=INPUT$(6)" + #CRLF$ + "W$=INPUT$(3,#1)",
    "O formato INPUT$ (numero de caracteres) le, do teclado, o numero especificado de caracteres " +
    "e os fornece na forma de uma string. O formato INPUT$ (numero de caracteres, # numero do " +
    "arquivo) le, de um arquivo que esta aberto, o numero de caracteres especificado, e os " +
    "fornece na forma de uma string. O numero de caracteres pode ser fornecido por uma constante, " +
    "uma variavel numerica ou entao por uma variavel numerica indexada. O valor do numero de " +
    "caracteres deve estar entre 1 e 255 (se for maior do que 200, a instrucao CLEAR deve ser " +
    "executada antes).",
    "10 REM PROGRAMA INPUT$" + #CRLF$ +
    "20 A$=INPUT$(8)" + #CRLF$ +
    "30 PRINT A$",
    77)

  MSXDict_Add("INSTR", #True, #False, "(in string)",
    "Localiza a posicao de uma string dentro de uma outra string.",
    "INSTR ([N,] string de pesquisa, string procurada)",
    "INSTR(" + MSXQ + "SOU O MSX" + MSXQ + "," + MSXQ + "O" + MSXQ + ")",
    "A funcao INSTR fornece a localizacao do primeiro caractere da string procurada dentro da " +
    "string de pesquisa, sendo que esta contagem comeca-se a partir do n-esimo caractere da " +
    "string de pesquisa. N pode ser fornecido atraves de uma constante, uma variavel numerica ou " +
    "uma variavel numerica indexada, sendo que seu valor deve estar entre 1 e 255. As strings de " +
    "pesquisa e de procura podem ser fornecidas por uma constante, variavel alfanumerica ou uma " +
    "variavel alfanumerica indexada. Se o valor N for maior do que o comprimento da string de " +
    "pesquisa, ou se a string de pesquisa for uma string nula, ou se a string procurada nao for " +
    "encontrada na string de pesquisa, o resultado sera zero (0).",
    "10 REM PROGRAMA INSTR" + #CRLF$ +
    "20 A$=" + MSXQ + "GRADIENTE&ALEPH-HPELA&ETNEIDARG" + MSXQ + #CRLF$ +
    "30 INPUT" + MSXQ + "ENTRE UMA SEQUENCIA DE ATE 10 CARACTERES" + MSXQ + ";B$" + #CRLF$ +
    "40 C=INSTR(A$,B$)" + #CRLF$ +
    "50 IF C=0 THEN GOTO 80" + #CRLF$ +
    "60 PRINT" + MSXQ + "ESSA SEQUENCIA COMECA NA POSICAO" + MSXQ + ";C" + #CRLF$ +
    "70 END" + #CRLF$ +
    "80 PRINT" + MSXQ + "NAO EXISTE ESSA SEQUENCIA EM A$" + MSXQ + #CRLF$ +
    "90 END",
    78)

  MSXDict_Add("INT", #True, #False, "(integer)",
    "Fornece o valor do maior inteiro possivel, menor do que o argumento.",
    "INT (argumento)",
    "PRINT INT(1.12345)",
    "A funcao INT fornece o valor do maior inteiro possivel que nao seja maior do que o valor do " +
    "argumento. Por exemplo:" + #CRLF$ +
    "INT(2.5653)=2" + #CRLF$ +
    "INT(-2.5653)=-3" + #CRLF$ +
    "INT(1000101.23)=1000101" + #CRLF$ + #CRLF$ +
    "O argumento pode ser fornecido por uma constante, uma variavel numerica ou uma variavel " +
    "numerica indexada.",
    "10 REM PROGRAMA INT" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 FOR F=1 TO 20" + #CRLF$ +
    "40 A=500-RND(-TIME)*1000" + #CRLF$ +
    "50 PRINT A;" + MSXQ + "............." + MSXQ + ";INT(A)" + #CRLF$ +
    "60 NEXT F",
    79)

  MSXDict_Add("INTERVAL ON/OFF/STOP", #False, #False, "(interval on/off/stop)",
    "Cada uma destas tres funcoes respectivamente, habilita, desabilita e adia uma interrupcao " +
    "feita pelo temporizador.",
    "INTERVAL ON" + #CRLF$ + "INTERVAL OFF" + #CRLF$ + "INTERVAL STOP",
    "INTERVAL ON" + #CRLF$ + "INTERVAL OFF" + #CRLF$ + "INTERVAL STOP",
    "A instrucao INTERVAL ON habilita uma interrupcao causada pelo temporizador, caso exista uma " +
    "instrucao ON INTERVAL GOSUB no programa. A instrucao INTERVAL OFF desabilita (ou desliga) a " +
    "instrucao INTERVAL ON. A instrucao INTERVAL STOP adia a interrupcao ate que seja encontrada " +
    "a instrucao INTERVAL ON.",
    "10 REM PROGRAMA INTERVAL ON" + #CRLF$ +
    "20 INTERVAL ON" + #CRLF$ +
    "30 ON INTERVAL=50 GOSUB 50" + #CRLF$ +
    "40 GOTO 40" + #CRLF$ +
    "50 C=C+1" + #CRLF$ +
    "60 PRINT C" + #CRLF$ +
    "70 RETURN",
    80)
EndProcedure

; --- Letra K (pagina 81-84 do livro = pagina 78-81 do PDF) ---
Procedure MSXDict_BuildLetterK()
  MSXDict_Add("KEY", #False, #False, "(key)",
    "Associa uma string (cadeia de caracteres) a uma tecla de funcao (F1 a F10).",
    "KEY numero da tecla de funcao, string",
    "KEY 1," + MSXQ + "LOAD" + MSXQ,
    "A funcao KEY associa uma string a uma tecla de funcao, localizada na parte superior esquerda " +
    "do teclado. O numero da tecla de funcao deve estar entre 1 e 10 (as teclas F6 a F10 sao " +
    "obtidas mantendo-se a tecla SHIFT pressionada) e a string deve ter, no maximo, 15 " +
    "caracteres. Esta associacao sera desfeita se o computador for desligado. Podemos tambem " +
    "utilizar a funcao CHR$ na formacao da cadeia de caracteres (por exemplo, o caractere de " +
    "retorno, que nao possui um correspondente alfanumerico, entra como codigo 13). Exemplos:" + #CRLF$ + #CRLF$ +
    "KEY 1," + MSXQ + "gradiente" + MSXQ + "+" + MSXQ + "aleph" + MSXQ + #CRLF$ + #CRLF$ +
    "KEY 2," + MSXQ + "LIST" + MSXQ + "+CHR$(13)" + #CRLF$ + #CRLF$ +
    "KEY 7," + MSXQ + "FOR I=" + MSXQ + #CRLF$ + #CRLF$ +
    "KEY 8," + MSXQ + "NEXT I" + MSXQ,
    "10 ' KEY" + #CRLF$ +
    "20 KEY 1," + MSXQ + "CLS:LIST" + MSXQ + "+CHR$(13)" + #CRLF$ +
    "30 INPUT" + MSXQ + "Voce quer definir alguma outra tecla" + MSXQ + ";R$" + #CRLF$ +
    "35 IF R$=" + MSXQ + "n" + MSXQ + " THEN END" + #CRLF$ +
    "40 INPUT" + MSXQ + "Qual a tecla (1-10)" + MSXQ + ";T" + #CRLF$ +
    "50 INPUT" + MSXQ + "Qual a funcao" + MSXQ + ";F$" + #CRLF$ +
    "60 KEY T,F$" + #CRLF$ +
    "70 GOTO 30",
    81)

  MSXDict_Add("KEY LIST", #False, #False, "(key list)",
    "Visualiza o conteudo das teclas de funcao.",
    "KEY LIST",
    "KEY LIST",
    "O comando KEY LIST, permite a visualizacao do conjunto de caracteres associado as teclas de " +
    "funcao. O estado inicial (default) que o computador oferece e o seguinte:" + #CRLF$ + #CRLF$ +
    "F1 ................." + MSXQ + "color" + MSXQ + " + CHR$ (32)" + #CRLF$ +
    "F2 ................." + MSXQ + "auto" + MSXQ + " + CHR$ (32)" + #CRLF$ +
    "F3 ................." + MSXQ + "goto" + MSXQ + " + CHR$ (32)" + #CRLF$ +
    "F4 ................." + MSXQ + "list" + MSXQ + " + CHR$ (32)" + #CRLF$ +
    "F5 ................." + MSXQ + "run" + MSXQ + " + CHR$ (13)" + #CRLF$ +
    "F6 (F1 + SHIFT) ......." + MSXQ + "color" + MSXQ + " + CHR$ (32) +" + #CRLF$ +
    "                " + MSXQ + "15,1,1" + MSXQ + " + CHR$ (13)" + #CRLF$ +
    "F7 (F2 + SHIFT) ........" + MSXQ + "cload" + MSXQ + " + CHR$ (34)" + #CRLF$ +
    "F8 (F3 + SHIFT) ........" + MSXQ + "cont" + MSXQ + " + CHR$ (13)" + #CRLF$ +
    "F9 (F4 + SHIFT) ........" + MSXQ + "list" + MSXQ + " + CHR$ (13)" + #CRLF$ +
    "F10 (F5 + SHIFT) ......." + MSXQ + "run" + MSXQ + " + CHR$ (13)" + #CRLF$ + #CRLF$ +
    "Observacao: CHR$ (13) = RETURN" + #CRLF$ +
    "            CHR$ (32) = ESPACO" + #CRLF$ +
    "            CHR$ (34) = ASPAS (" + MSXQ + ")",
    "10 REM PROGRAMA KEY LIST" + #CRLF$ +
    "20 INPUT" + MSXQ + "VOCE QUER VERIFICAR AS TECLAS FUNCIONAIS (S/N)" + MSXQ + ";R$" + #CRLF$ +
    "30 IF R$=" + MSXQ + "N" + MSXQ + " THEN 50" + #CRLF$ +
    "40 KEY LIST" + #CRLF$ +
    "50 END",
    82)

  MSXDict_Add("KEY ON/OFF", #False, #False, "(key on/off)",
    "Ativa ou desativa a visualizacao, na parte inferior da tela, dos caracteres associados as " +
    "teclas de funcao.",
    "KEY ON" + #CRLF$ + "KEY OFF",
    "KEY ON" + #CRLF$ + "KEY OFF",
    "O comando KEY ON ativa a visualizacao na parte inferior da tela da cadeia de caracteres " +
    "associada a cada tecla de funcao. O comando KEY OFF desativa esta visualizacao.",
    "10 REM PROGRAMA KEY ON/OFF" + #CRLF$ +
    "20 INPUT" + MSXQ + "VOCE QUER AS TECLAS FUNCIONAIS NA TELA (S/N)" + MSXQ + ";R$" + #CRLF$ +
    "30 IF R$=" + MSXQ + "N" + MSXQ + " THEN KEY OFF ELSE KEY ON" + #CRLF$ +
    "40 END",
    83)

  MSXDict_Add("KEY (n) ON/OFF/STOP", #False, #False, "(key (n) on/off/stop)",
    "Cada uma destas tres funcoes respectivamente, habilita, desabilita e adia uma interrupcao " +
    "atraves das teclas de funcao.",
    "KEY (n) ON" + #CRLF$ + "KEY (n) OFF" + #CRLF$ + "KEY (n) STOP",
    "KEY(1) ON" + #CRLF$ + "KEY(2) OFF" + #CRLF$ + "KEY(3) STOP",
    "A instrucao KEY (n) ON habilita uma interrupcao causada caso seja pressionada uma das teclas " +
    "de funcao, quando existir a instrucao ON KEY GOSUB no programa. A instrucao KEY (n) OFF " +
    "desabilita (ou desliga) a funcao KEY (n) ON. A instrucao KEY (n) STOP adia a interrupcao ate " +
    "que seja encontrada a instrucao KEY (n) ON.",
    "10 REM PROGRAMA KEY(n) ON" + #CRLF$ +
    "20 KEY(1) ON" + #CRLF$ +
    "30 ON KEY GOSUB 100" + #CRLF$ +
    "40 GOTO 30" + #CRLF$ +
    "100 PRINT" + MSXQ + "VOCE PRESSIONOU A TECLA F1." + MSXQ + #CRLF$ +
    "110 RETURN",
    84)
EndProcedure

; --- Letra L (pagina 85-97 do livro = pagina 82-94 do PDF) ---
Procedure MSXDict_BuildLetterL()
  MSXDict_Add("LEFT$", #True, #False, "(left dollar)",
    "Fornece na forma de string os n-primeiros caracteres de uma cadeia.",
    "LEFT$ (string, quantidade de caracteres)",
    "LEFT$(" + MSXQ + "GRADIENTE-ALEPH" + MSXQ + ",5)",
    "A funcao LEFT$ fornece os n-primeiros caracteres de uma string, sendo o primeiro caractere o " +
    "mais a esquerda da string.",
    "10 REM PROGRAMA LEFT$" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 INPUT " + MSXQ + " ESCREVA UMA PALAVRA" + MSXQ + ";W$: PRINT" + #CRLF$ +
    "40 PRINT " + MSXQ + "A PRIMEIRA LETRA E'..." + MSXQ + ";LEFT$(W$,1): PRINT",
    85)

  MSXDict_Add("LEN", #True, #False, "(lenght)",
    "Fornece a quantidade de caracteres de uma string.",
    "LEN (string)",
    "LEN(" + MSXQ + "COMPUTADOR" + MSXQ + ")",
    "A funcao LEN fornece a quantidade de caracteres de uma string, ou seja, o seu comprimento.",
    "10 REM PROGRAMA LEN" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 INPUT" + MSXQ + "ESCREVA UMA SENTENCA QUE NAO ULTRAPASSE 10 PALAVRAS." + MSXQ + ";S$: PRINT" + #CRLF$ +
    "40 PRINT " + MSXQ + " O NUMERO DE CARACTERES QUE ESTA FRASE POSSUI E':" + MSXQ + #CRLF$ +
    "50 PRINT LEN(S$)",
    86)

  MSXDict_Add("LET", #False, #False, "(let)",
    "Realiza a associacao de um dado a uma variavel.",
    "[LET] variavel = expressao",
    "LET A=10" + #CRLF$ + "LET A=" + MSXQ + "ABC" + MSXQ + "+" + MSXQ + "DEF" + MSXQ,
    "A instrucao LET faz a associacao de um dado (numerico ou alfanumerico) com uma variavel (do " +
    "mesmo tipo do dado), sendo que as variaveis alfanumericas devem estar entre aspas (" + MSXQ + " " + MSXQ + "), " +
    "caso contrario, uma mensagem do tipo:" + #CRLF$ +
    "Type mismatch" + #CRLF$ +
    "aparecera na tela. A palavra LET pode ser omitida neste tipo de instrucao.",
    "10 REM PROGRAMA LET" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 LET A=10:PRINT" + MSXQ + "A=" + MSXQ + ";A" + #CRLF$ +
    "40 LET B=20:PRINT" + MSXQ + "B=" + MSXQ + ";B" + #CRLF$ +
    "50 LET C=A+B" + #CRLF$ +
    "60 PRINT " + MSXQ + "A+B=" + MSXQ + ";C" + #CRLF$ +
    "70 END",
    87)

  MSXDict_Add("LINE", #False, #False, "(line)",
    "Traca, no modo grafico, uma linha ou um quadrado, dependendo da sintaxe da instrucao.",
    "LINE [[STEP] (X1,Y1)] -" + #CRLF$ +
    "[STEP] (X2, Y2)" + #CRLF$ +
    "[cor] [,B] [,BF]",
    "LINE(100,100)-(135,145),3,B",
    "O comando LINE traca uma linha reta entre os pontos de coordenadas (X1,Y1) e (X2,Y2). Esta " +
    "reta podera ser colorida, se o item cor for especificado. Quando a letra B (box) e " +
    "especificada, sera tracado um retangulo que ligara " + MSXQ + "diagonalmente" + MSXQ + " os dois pontos " +
    "especificados. Se BF (box full) for especificado, sera tracado um retangulo com a parte " +
    "interna pintada pela cor especificada. Quando a cor nao for especificada, sera usada a cor " +
    "do primeiro plano definida pela ultima instrucao COLOR." + #CRLF$ +
    "Por exemplo:" + #CRLF$ + #CRLF$ +
    "LINE(100,130)-(120,150),,B" + #CRLF$ + #CRLF$ +
    "Para desenhar um quadrado, a diferenca entre X1 e X2 deve ser 1,25 vezes menor do que a " +
    "diferenca entre Y1 e Y2. Isto porque a relacao entre os caracteres horizontais e verticais e " +
    "de 8:10. Por exemplo, em:" + #CRLF$ +
    "LINE(50,50)-(130,150)" + #CRLF$ + #CRLF$ +
    "X1-X2=-80, Y1-Y2=-100 e (Y1-Y2)/(X1-X2)=1.25" + #CRLF$ +
    "Se esta relacao entre o eixo X e o eixo Y nao for obedecida, sera desenhado um retangulo. " +
    "Por exemplo:" + #CRLF$ +
    "LINE(10,70)-(40,80),3,B" + #CRLF$ + #CRLF$ +
    "Observacao: Antes de uma instrucao LINE, deve existir um comando SCREEN 2 ou SCREEN 3, que " +
    "muda para a pagina grafica.",
    "10 REM PROGRAMA LINE" + #CRLF$ +
    "20 SCREEN2" + #CRLF$ +
    "30 FOR F=0 TO 125 STEP 10" + #CRLF$ +
    "40 G=80-F*80/125" + #CRLF$ +
    "50 LINE (F,80)-(125,G)" + #CRLF$ +
    "60 LINE (125,G)-(250-F,80)" + #CRLF$ +
    "70 LINE (F,80)-(125,160-G)" + #CRLF$ +
    "80 LINE (125,160-G)-(250-F,80)" + #CRLF$ +
    "90 NEXT F" + #CRLF$ +
    "100 GOTO 100",
    88)

  MSXDict_Add("LINE INPUT", #False, #False, "(line input)",
    "Associa um dado introduzido pelo teclado, a uma variavel string.",
    "LINE INPUT [" + MSXQ + "mensagem" + MSXQ + ";] variavel",
    "LINE INPUT" + MSXQ + "Entre com um nome:" + MSXQ + ";A$",
    "A instrucao LINE INPUT executa a leitura do teclado e associa os caracteres pressionados a " +
    "uma variavel string. E uma instrucao semelhante ao INPUT, com a diferenca de que o LINE " +
    "INPUT nao coloca o ponto de interrogacao na tela e associa os caracteres digitados a apenas " +
    "uma variavel. A mensagem e opcional e, quando especificada, sera mostrada na tela.",
    "10 ' LINE INPUT" + #CRLF$ +
    "20 LINE INPUT" + MSXQ + "Introduza o seu primeiro nome e digite RETURN.   " + MSXQ + ";N$" + #CRLF$ +
    "25 CLS:N$=N$+" + MSXQ + " " + MSXQ + #CRLF$ +
    "30 N$=RIGHT$(N$,LEN(N$)-1)+LEFT$(N$,1):LOCATE 10,10" + #CRLF$ +
    "40 PRINT N$:FOR F=1 TO 30:NEXT F" + #CRLF$ +
    "50 GOTO 30",
    89)

  MSXDict_Add("LINE INPUT#", #False, #True, "(line input number)",
    "Le uma sequencia de ate 254 caracteres de um arquivo e a atribui a uma variavel string.",
    "LINE INPUT # numero do arquivo,nome da variavel",
    "LINE INPUT#2,A$",
    "O comando LINE INPUT # obtem uma string de um arquivo e a armazena numa variavel. O arquivo " +
    "e definido por um numero entre 1 e o numero especificado por MAXFILES, e a variavel pode ser " +
    "simples ou indexada.",
    "10 REM PROGRAMA LINE INPUT" + #CRLF$ +
    "20 OPEN " + MSXQ + "CAS:II" + MSXQ + " FOR INPUT AS#1" + #CRLF$ +
    "30 IF EOF=-1 THEN 70" + #CRLF$ +
    "40 LINE INPUT#1,A$" + #CRLF$ +
    "50 PRINT A$:BEEP" + #CRLF$ +
    "60 GOTO 30" + #CRLF$ +
    "70 CLOSE#1",
    90)

  MSXDict_Add("LIST/LLIST", #False, #False, "(list out/line printer list out)",
    "Lista o programa ou parte dele na tela ou na impressora.",
    "LIST [numero da linha inicial]" + #CRLF$ +
    "[-numero da linha final]" + #CRLF$ + #CRLF$ +
    "LLIST [numero da linha inicial]" + #CRLF$ +
    "[-numero da linha final]",
    "LIST-900" + #CRLF$ + "LIST 30-70",
    "Os dois comandos (LIST e LLIST) listam todo ou parte de um programa sendo que com o comando " +
    "LIST a listagem do programa e visualizada na tela, enquanto que o comando LLIST e executado " +
    "na impressora. Os numeros das linhas inicial e final sao opcionais e, portanto, podem ser " +
    "omitidos. Se for feito um comando LIST sem os numeros de linhas, todo o programa sera " +
    "listado. Se for feito um comando com apenas um numero de linha, sera listada apenas a linha " +
    "especificada. Por exemplo:" + #CRLF$ +
    "LIST 50" + #CRLF$ + #CRLF$ +
    "Outra opcao seria um comando com um hifen antes do numero da linha. Neste caso, o programa " +
    "sera listado do inicio ate a linha especificada. Por exemplo:" + #CRLF$ +
    "LIST-900",
    "10 REM PROGRAMA LIST/LLIST" + #CRLF$ +
    "20 INPUT" + MSXQ + "VOCE QUER LISTAR O PROGRAMA NA TELA (T)OU NA IMPRESSORA (I)" + MSXQ + ";R$" + #CRLF$ +
    "30 IF R$=" + MSXQ + "T" + MSXQ + " THEN LIST" + #CRLF$ +
    "40 IF R$=" + MSXQ + "I" + MSXQ + " THEN LLIST" + #CRLF$ +
    "50 END",
    91)

  MSXDict_Add("LOAD", #False, #True, "(load)",
    "Carrega um arquivo de um dispositivo especificado para a memoria do micro.",
    "LOAD" + MSXQ + "[nome do dispositivo] [nome do arquivo]" + MSXQ + " [,R]",
    "LOAD" + MSXQ + "CAS:MARRE" + MSXQ + ",R",
    "Carregar, para a memoria do computador, um arquivo em BASIC gravado no dispositivo " +
    "especificado. Se a letra R for colocado apos a ultima aspas o programa sera executado assim " +
    "que a transferencia para a RAM for completada.",
    "",
    92)

  MSXDict_Add("LOCATE", #False, #False, "(locate)",
    "Move o cursor para posicao especificada pelas coordenadas x e y.",
    "LOCATE [coordenada x] [, coordenada y]" + #CRLF$ +
    "[, interruptor do cursor]",
    "LOCATE 10,10,1",
    "A instrucao LOCATE move o cursor para uma posicao especificada pelas coordenadas X e Y." + #CRLF$ + #CRLF$ +
    "Coordenada X: constantes, variaveis indexadas ou numericas, podendo assumir valores entre 0 " +
    "e 39. Se omitida, o computador assumira o valor 0." + #CRLF$ + #CRLF$ +
    "Coordenada Y: constantes, variaveis indexadas ou numericas, podendo assumir valores entre 0 " +
    "e 23. Se omitida, o computador assumira o valor 0." + #CRLF$ + #CRLF$ +
    "Interruptor do Cursor: se for 0 o cursor nao sera visivel. Se for 1, o cursor aparecera. Se " +
    "omitido, o computador assumira o valor 1.",
    "10 REM PROGRAMA LOCATE" + #CRLF$ +
    "20 INPUT" + MSXQ + "INTRODUZA UMA PALAVRA" + MSXQ + ";P$" + #CRLF$ +
    "30 INPUT" + MSXQ + "EM QUE COLUNA VOCE QUER IMPRIMI-LA" + MSXQ + ";CO" + #CRLF$ +
    "40 INPUT" + MSXQ + "E EM QUE LINHA" + MSXQ + ";LI" + #CRLF$ +
    "50 CLS" + #CRLF$ +
    "60 LOCATE CO,LI" + #CRLF$ +
    "70 PRINT P$",
    93)

  ; O livro mostra "A" como subscrito antes do "B" (notacao LOG_A B para
  ; logaritmo de B na base A) - representado aqui como "LOGA B" por
  ; limitacao de texto puro, sem subscrito real.
  MSXDict_Add("LOG", #True, #False, "(logaritmo natural)",
    "Determina o logaritmo natural de um numero.",
    "LOG (X)",
    "LOG(10)",
    "A funcao LOG determina o logaritmo natural cuja base e .......... (2.7182818284588...). Para " +
    "determinar o valor de um logaritmo em outra base (A):" + #CRLF$ +
    "LOGA B" + #CRLF$ +
    "sendo B>0 e A (A = base) um numero positivo diferente de zero, utiliza-se a formula:" + #CRLF$ +
    "LOG (B)/LOG (A)" + #CRLF$ + #CRLF$ +
    "Observacao: o valor de X sempre devera ser maior que zero.",
    "10 REM PROGRAMA LOG" + #CRLF$ +
    "20 INPUT" + MSXQ + "INTRODUZA UM NUMERO POSITIVO:" + MSXQ + ";N" + #CRLF$ +
    "30 PRINT" + MSXQ + "O LOGARITMO NATURAL DESSE NUMERO E:" + MSXQ + ";LOG(N)," + MSXQ + "E SEU LOGARITMO DECIMAL E:" + MSXQ + ";LOG(N)/LOG(10)" + #CRLF$ +
    "40 PRINT" + #CRLF$ +
    "50 RUN",
    94)

  MSXDict_Add("LPOS", #True, #False, "(line printer position)",
    "Fornece a posicao do cabecote da impressora.",
    "LPOS (X)",
    "LPOS(0)",
    "Fornece a posicao no buffer de memoria da impressora, do caractere que esta sendo impresso " +
    "(posicao inicial = 0). O valor de X pode ser um numero arbitrario qualquer e o valor obtido " +
    "e um numero inteiro.",
    "10 REM PROGRAMA LPOS" + #CRLF$ +
    "20 A$=" + MSXQ + MSXQ + #CRLF$ +
    "30 FOR F=1 TO 60" + #CRLF$ +
    "40 LPRINT A$;LPOS(1)" + #CRLF$ +
    "50 A$=A$+" + MSXQ + ">" + MSXQ + #CRLF$ +
    "60 NEXT F",
    95)

  MSXDict_Add("LPRINT", #False, #False, "(line print)",
    "Escreve na impressora o valor de uma expressao.",
    "LPRINT expressao [expressao...]",
    "LPRINT A$,B;" + MSXQ + "ALEPH" + MSXQ + ",D+2",
    "Escrever dados na impressora, da mesma forma que o comando PRINT os escreve na tela. As " +
    "expressoes podem ser: constantes, qualquer tipo de variavel ou expressoes algebricas. Entre " +
    "as expressoes podem ser utilizados os simbolos " + MSXQ + "," + MSXQ + " ou " + MSXQ + ";" + MSXQ + ". O comando LPRINT " +
    "desacompanhado de qualquer expressao ou simbolo causa o avanco de uma linha. Para maiores " +
    "detalhes consulte PRINT.",
    "10 REM PROGRAMA LPRINT" + #CRLF$ +
    "20 FOR F=1 TO 50" + #CRLF$ +
    "30 LPRINT" + #CRLF$ +
    "40 LPRINT" + #CRLF$ +
    "50 LPRINT" + #CRLF$ +
    "60 FOR G=1 TO 60" + #CRLF$ +
    "70 LPRINT" + MSXQ + "_________________________________________________________________" + MSXQ + #CRLF$ +
    "80 NEXT G" + #CRLF$ +
    "90 LPRINT" + #CRLF$ +
    "100 LPRINT" + #CRLF$ +
    "110 LPRINT TAB 70;F" + #CRLF$ +
    "120 NEXT F",
    96)

  MSXDict_Add("LPRINT USING", #False, #False, "(line print using)",
    "Escreve na impressora, com o formato especificado, o valor de uma expressao.",
    "LPRINT USING " + MSXQ + "simbolo de formato" + MSXQ + " [expressao]",
    "LPRINT USING" + MSXQ + "####.##" + MSXQ + ";A$;B",
    "Escreve dados na impressora, com formato determinado, da mesma forma que o comando PRINT " +
    "USING os escreve na tela. As expressoes podem ser: constantes, qualquer tipo de variavel ou " +
    "expressoes algebricas. Entre as expressoes podem ser utilizados os simbolos " + MSXQ + "," + MSXQ + " ou " +
    MSXQ + ";" + MSXQ + ". Para maiores detalhes consulte PRINT USING.",
    "10 REM PROGRAMA LPRINT USING" + #CRLF$ +
    "20 INPUT A" + #CRLF$ +
    "30 LPRINT USING" + MSXQ + "$$######.##-" + MSXQ + ";A" + #CRLF$ +
    "40 GOTO 20",
    97)
EndProcedure

; --- Letra M (pagina 98-102 do livro = pagina 95-99 do PDF) ---
Procedure MSXDict_BuildLetterM()
  MSXDict_Add("MAXFILES", #False, #True, "(maxfiles)",
    "Determina o numero de arquivos que podem ser abertos ao mesmo tempo em um programa.",
    "MAXFILES = numero de arquivos",
    "MAXFILES=5",
    "Declara o numero de arquivos que podem ser abertos ao mesmo tempo em um programa. O numero " +
    "de arquivos pode assumir valores entre 0 e 15. Se o numero de arquivos nao for especificado " +
    "atraves de MAXFILES, somente um pode ser aberto. Nao se deve superdimensionar o valor de " +
    "MAXFILES (quanto maior for, menor a area de memoria restante para o usuario). O numero de " +
    "arquivos pode ser constituido de constantes, variaveis numericas, variaveis indexadas, ou " +
    "suas expressoes.",
    "10 REM PROGRAMA MAXFILES" + #CRLF$ +
    "20 MAXFILES=2" + #CRLF$ +
    "30 OPEN" + MSXQ + "GRP:" + MSXQ + "FOR OUTPUT AS #1" + #CRLF$ +
    "40 OPEN" + MSXQ + "CRT:" + MSXQ + "FOR OUTPUT AS #2" + #CRLF$ +
    "50 SCREEN 2" + #CRLF$ +
    "60 LINE(20,20)-(235,171),7,BF" + #CRLF$ +
    "70 LINE(50,50)-(205,141),4,BF" + #CRLF$ +
    "80 CIRCLE(128,80),30,6" + #CRLF$ +
    "90 PSET(107,70)" + #CRLF$ +
    "100 PRINT#1," + MSXQ + "EXPERT" + MSXQ + #CRLF$ +
    "110 CIRCLE(128,100),20,6" + #CRLF$ +
    "120 PSET(119,94)" + #CRLF$ +
    "130 PRINT#1," + MSXQ + "MSX" + MSXQ + #CRLF$ +
    "140 CLOSE 1" + #CRLF$ +
    "150 FOR F=1 TO 3000:NEXT F" + #CRLF$ +
    "160 SCREEN 0" + #CRLF$ +
    "170 PRINT#2," + MSXQ + "EXPERT" + MSXQ + #CRLF$ +
    "180 PRINT#2," + MSXQ + "MSX" + MSXQ + #CRLF$ +
    "190 CLOSE 2",
    98)

  MSXDict_Add("MERGE", #False, #True, "(merge)",
    "Carrega um programa armazenado em codigo ASCII e o une com o programa que esta na memoria " +
    "do computador.",
    "MERGE " + MSXQ + "nome do dispositivo, nome do arquivo" + MSXQ,
    "MERGE" + MSXQ + "CAS:TESTE" + MSXQ,
    "Une um programa que esteja armazenado em codigo ASCII (em um dispositivo externo) com um " +
    "programa que esteja na memoria do computador." + #CRLF$ + #CRLF$ +
    "Importante: as linhas do programa que se encontram no dispositivo externo serao simplesmente " +
    "inseridas no programa residente, em sequencia. Se os numeros das linhas do programa externo " +
    "coincidirem com os numeros das linhas do programa residente, as linhas deste serao " +
    "substituidas pelas linhas do programa externo.",
    "10 'Programa da RAM" + #CRLF$ +
    "20 PRINT" + MSXQ + "RAM .... 20" + MSXQ + #CRLF$ +
    "30 PRINT" + MSXQ + "RAM .... 30" + MSXQ + #CRLF$ +
    "40 PRINT" + MSXQ + "RAM .... 40" + MSXQ + #CRLF$ +
    "50 PRINT" + MSXQ + "RAM .... 50" + MSXQ + #CRLF$ +
    "60 PRINT" + MSXQ + "RAM .... 60" + MSXQ + #CRLF$ +
    "70 PRINT" + MSXQ + "RAM .... 70" + MSXQ + #CRLF$ + #CRLF$ +
    "5 'Programa da FITA" + #CRLF$ +
    "15 PRINT" + MSXQ + "fita _ 15" + MSXQ + #CRLF$ +
    "25 PRINT" + MSXQ + "fita _ 25" + MSXQ + #CRLF$ +
    "35 PRINT" + MSXQ + "fita _ 35" + MSXQ + #CRLF$ +
    "45 PRINT" + MSXQ + "fita _ 45" + MSXQ + #CRLF$ +
    "55 PRINT" + MSXQ + "fita _ 55" + MSXQ + #CRLF$ +
    "65 PRINT" + MSXQ + "fita _ 65" + MSXQ + #CRLF$ +
    "75 PRINT" + MSXQ + "fita _ 75" + MSXQ + #CRLF$ +
    "80 PRINT" + MSXQ + "fita _ 80 *" + MSXQ + #CRLF$ + #CRLF$ +
    "MERGE" + MSXQ + "CAS:FITA" + MSXQ + #CRLF$ + #CRLF$ +
    "Resultado (programa unido):" + #CRLF$ +
    "5 'Programa da FITA" + #CRLF$ +
    "10 'Programa da RAM" + #CRLF$ +
    "15 PRINT" + MSXQ + "fita _ 15" + MSXQ + #CRLF$ +
    "20 PRINT" + MSXQ + "RAM .... 20" + MSXQ + #CRLF$ +
    "25 PRINT" + MSXQ + "fita _ 25" + MSXQ + #CRLF$ +
    "30 PRINT" + MSXQ + "RAM .... 30" + MSXQ + #CRLF$ +
    "35 PRINT" + MSXQ + "fita _ 35" + MSXQ + #CRLF$ +
    "40 PRINT" + MSXQ + "RAM .... 40" + MSXQ + #CRLF$ +
    "45 PRINT" + MSXQ + "fita _ 45" + MSXQ + #CRLF$ +
    "50 PRINT" + MSXQ + "RAM .... 50" + MSXQ + #CRLF$ +
    "55 PRINT" + MSXQ + "fita _ 55" + MSXQ + #CRLF$ +
    "60 PRINT" + MSXQ + "RAM .... 60" + MSXQ + #CRLF$ +
    "65 PRINT" + MSXQ + "fita _ 65" + MSXQ + #CRLF$ +
    "70 PRINT" + MSXQ + "RAM .... 70" + MSXQ + #CRLF$ +
    "75 PRINT" + MSXQ + "fita _ 75" + MSXQ + #CRLF$ +
    "80 PRINT" + MSXQ + "fita _ 80 *" + MSXQ,
    99)

  MSXDict_Add("MID$", #True, #False, "(middle dollar)",
    "Seleciona parte de strings (cadeias alfanumericas).",
    "MID$(A$,m,[,n])",
    "A$=MID$(" + MSXQ + "GOEDELESCHERBACH" + MSXQ + ",7,6)",
    "Seleciona um subconjunto de caracteres de A$ (substring), com um comprimento n e comecando " +
    "na posicao m. Os valores de m e n devem estar entre 0 e 255. Se n nao for inteiro somente " +
    "sua parte inteira sera considerada. Se m for maior que o comprimento da string ou se n for " +
    "zero, a string resultante sera vazia. Se n for omitido, a string resultante sera formada " +
    "pelos caracteres de A$ a partir da posicao m.",
    "10 REM PROGRAMA MID$" + #CRLF$ +
    "20 A$=" + MSXQ + "GOEDELESCHERBACH   " + MSXQ + ":CLS" + #CRLF$ +
    "30 FOR F=1 TO LEN(A$)-3" + #CRLF$ +
    "40 LOCATE 16,10:FOR D=1 TO 100:NEXT D" + #CRLF$ +
    "50 PRINT MID$(A$,F,3)" + #CRLF$ +
    "60 NEXT F" + #CRLF$ +
    "70 GOTO 30",
    100)

  MSXDict_Add("MID$=", #False, #False, "(middle dollar)",
    "Substitui uma parte de uma string (cadeia alfanumerica) por elementos de outra string.",
    "MID$(A$,m,[,n])=B$",
    "MID$(A$,3,4)=B$",
    "Enxerta em A$, a partir do m-esimo caractere, n caracteres de B$. Os valores de m e n devem " +
    "estar entre 0 e 255. Se n for omitido o m-esimo caractere e os seguintes serao substituidos." + #CRLF$ +
    "Importante: o comprimento de A$ nao e alterado e a substituicao para quando o ultimo " +
    "caractere de A$ for substituido.",
    "10 REM PROGRAMA MID$=" + #CRLF$ +
    "20 A$=" + MSXQ + "GOEDELESCHERBACH GOEDELESCHERBACH" + MSXQ + ":CLS" + #CRLF$ +
    "30 C=INT(1+LEN(A$)*RND(1))" + #CRLF$ +
    "40 D=INT(1+LEN(A$)*RND(1))" + #CRLF$ +
    "50 MID$(A$,C,1)=MID$(A$,D,1)" + #CRLF$ +
    "60 LOCATE 3,10:FOR D=1 TO 100:NEXT D" + #CRLF$ +
    "70 PRINT A$" + #CRLF$ +
    "80 GOTO 30",
    101)

  MSXDict_Add("MOTOR", #False, #False, "(motor)",
    "Liga ou desliga o gravador.",
    "MOTOR [ON]" + #CRLF$ + "MOTOR [OFF]",
    "MOTOR" + #CRLF$ + "MOTOR ON",
    "A instrucao MOTOR ON liga o gravador e a MOTOR OFF desliga. Se for somente digitado MOTOR o " +
    "computador desligara o gravador que estiver ligado e ligara se estiver desligado.",
    "10 REM PROGRAMA MOTOR" + #CRLF$ +
    "20 INPUT " + MSXQ + " QUANTOS SEGUNDOS O GRAVADOR DEVE FICAR LIGADO" + MSXQ + ";T" + #CRLF$ +
    "30 MOTOR ON" + #CRLF$ +
    "40 TIME=0" + #CRLF$ +
    "50 IF TIME<T*60 THEN 50" + #CRLF$ +
    "60 MOTOR OFF",
    102)
EndProcedure

; --- Letra N (pagina 103 do livro = pagina 100 do PDF) ---
Procedure MSXDict_BuildLetterN()
  MSXDict_Add("NEW", #False, #False, "(new)",
    "Apaga o programa da memoria.",
    "NEW",
    "NEW",
    "O comando NEW apaga o programa em BASIC e suas variaveis da memoria. Ele e usado quando se " +
    "quer digitar um novo programa. Se existir um programa em linguagem de maquina na memoria do " +
    "computador ele nao sera apagado com o comando NEW.",
    "10 REM PROGRAMA NEW" + #CRLF$ +
    "20 PRINT" + MSXQ + "ESTE PROGRAMA SE AUTO-DESTRUIRA EM 10 SEGUNDOS." + MSXQ + #CRLF$ +
    "30 TIME=0" + #CRLF$ +
    "40 IF TIME=600 THEN NEW" + #CRLF$ +
    "50 GOTO 40",
    103)
EndProcedure

; --- Letra O (pagina 104-114 do livro = pagina 101-111 do PDF) ---
Procedure MSXDict_BuildLetterO()
  ; O cabecalho da pagina 104 mostra "OTC$" (erro de grafia do livro) mas o
  ; nome usado em todo o resto da pagina (FORMATO/EXEMPLO/FUNCAO) e OCT$.
  MSXDict_Add("OCT$", #True, #False, "(octonary dollar)",
    "Transforma um dado numerico em uma string na forma octal.",
    "OCT$ (argumento)",
    "A$=OCT$(56)",
    "A funcao OCT$ transforma um dado numerico para a forma octal armazenando-o no formato de " +
    "uma string. O valor do argumento deve estar entre -32768 e 65535 e pode ser expresso atraves " +
    "de uma constante, uma variavel numerica, ou uma variavel indexada. Se o argumento for um " +
    "numero negativo, primeiramente calcula-se o valor do argumento subtraido de 65536 e depois e " +
    "feita a transformacao para a forma octal.",
    "10 REM PROGRAMA OCT$" + #CRLF$ +
    "20 FOR F=0 TO 20" + #CRLF$ +
    "30 PRINT F;" + MSXQ + "......." + MSXQ + ";OCT$(F)" + #CRLF$ +
    "40 NEXT F",
    104)

  ; CONFERIR: o EXEMPLO desta pagina lista 5 numeros de linha separados por
  ; virgula (100,200,300,400,500) para um ON ERROR GOTO, o que nao bate com
  ; a sintaxe descrita no proprio FORMATO (aceita apenas 1 linha) - possivel
  ; erro do livro ou da digitalizacao, preservado como impresso.
  MSXDict_Add("ON ERROR GOTO", #False, #False, "(on error goto)",
    "Desvia o programa para uma determinada linha quando ocorre um erro na execucao ou na " +
    "entrada de dados.",
    "ON ERROR GOTO numero da linha",
    "ON ERROR GOTO 100,200,300,400,500",
    "A instrucao ON ERROR GOTO desvia o programa para uma certa linha definida pelo usuario, em " +
    "caso de erro na execucao do programa ou na entrada de dados. Esta instrucao e muito util " +
    "para evitar paradas inuteis nos programas.",
    "10 REM PROGRAMA ON ERROR" + #CRLF$ +
    "20 PRINT" + #CRLF$ +
    "30 ON ERROR GOTO 90" + #CRLF$ +
    "40 PRINT" + MSXQ + "DIGITE UM NUMERO NEGATIVO." + MSXQ + #CRLF$ +
    "50 INPUT A" + #CRLF$ +
    "60 PRINT SQR(A)" + #CRLF$ +
    "70 FOR F=1 TO 300: NEXT F" + #CRLF$ +
    "80 RUN" + #CRLF$ +
    "90 PRINT" + MSXQ + "NAO EXISTE RAIZ REAL." + MSXQ + #CRLF$ +
    "100 RUN",
    105)

  MSXDict_Add("ON-GOSUB", #False, #False, "(on-goto subroutine)",
    "Desvia o programa para uma sub-rotina condicionada pelo valor de uma variavel.",
    "ON variavel GOSUB numero da linha [,numero da linha, ...]",
    "ON B GOSUB 10,20,30",
    "A instrucao ON-GOSUB funciona analogamente ao ON-GOTO, so que desta vez o programa sera " +
    "desviado para uma sub-rotina. ON-GOSUB tambem e uma condensacao de comandos condicionados e " +
    "pode ser substituido por:" + #CRLF$ +
    "IF B=1 THEN GOSUB 10" + #CRLF$ +
    "IF B=2 THEN GOSUB 20" + #CRLF$ +
    "IF B=3 THEN GOSUB 30",
    "10 REM PROGRAMA ON ... GOSUB" + #CRLF$ +
    "20 INPUT" + MSXQ + "ENTRE COM UM NUMERO ENTRE 1 E 3" + MSXQ + ";A" + #CRLF$ +
    "30 IF A<1 OR A>3 THEN 20" + #CRLF$ +
    "40 ON A GOSUB 100,200,300" + #CRLF$ +
    "50 RUN" + #CRLF$ +
    "100 PRINT" + MSXQ + "SUB-ROTINA 1" + MSXQ + #CRLF$ +
    "110 RETURN" + #CRLF$ +
    "200 PRINT" + MSXQ + "SUB-ROTINA 2" + MSXQ + #CRLF$ +
    "210 RETURN" + #CRLF$ +
    "300 PRINT" + MSXQ + "SUB-ROTINA 3" + MSXQ + #CRLF$ +
    "310 RETURN",
    106)

  MSXDict_Add("ON-GOTO", #False, #False, "(on-goto)",
    "Desvio condicionado por uma variavel.",
    "ON variavel GOTO numero da linha [, numero da linha, ...]",
    "ON A GOTO 10,20,30",
    "A instrucao ON-GOTO desvia para uma certa linha do programa dependendo do valor de uma " +
    "variavel. O valor da variavel que condicionara o desvio deve ser um numero inteiro entre 0 e " +
    "255. Se o numero nao for inteiro, as casas decimais serao desprezadas. No exemplo acima " +
    "ocorre o seguinte: se o valor de A for 1, entao o programa desvia para a linha 10, se for 2 " +
    "para a linha 20, e se 3 para a linha 30. A instrucao ON-GOTO pode ser encarada como a " +
    "condensacao dos comandos:" + #CRLF$ +
    "IF A=1 THEN GOTO 10" + #CRLF$ +
    "IF A=2 THEN GOTO 20" + #CRLF$ +
    "IF A=3 THEN GOTO 30",
    "10 REM PROGRAMA ON GOTO" + #CRLF$ +
    "20 B=INT(RND(1)*3)+1" + #CRLF$ +
    "30 FOR F=1 TO 400:NEXT F" + #CRLF$ +
    "40 ON B GOTO 60,80,100" + #CRLF$ +
    "50 GOTO 20" + #CRLF$ +
    "60 PRINT" + MSXQ + "Desvio    1" + MSXQ + #CRLF$ +
    "70 GOTO 20" + #CRLF$ +
    "80 PRINT" + MSXQ + "Desvio    2" + MSXQ + #CRLF$ +
    "90 GOTO 20" + #CRLF$ +
    "100 PRINT" + MSXQ + "Desvio    3" + MSXQ + #CRLF$ +
    "110 GOTO 20",
    107)

  MSXDict_Add("ON INTERVAL-GOSUB", #False, #False, "(on interval go to subroutine)",
    "Desvia a execucao do programa para uma sub-rotina em um intervalo de tempo periodico.",
    "ON INTERVAL = intervalo GOSUB numero da linha",
    "ON INTERVAL=60 GOSUB 100",
    "A instrucao ON INTERVAL GOSUB desvia o programa para uma sub-rotina. No MSX existe um " +
    "temporizador que causa uma interrupcao a cada 1/60 de segundo. O intervalo apontado no " +
    "formato e exatamente o numero de interrupcoes que serao feitas para que o programa seja " +
    "desviado. No exemplo anterior acontece o seguinte: o computador espera que sejam feitas 60 " +
    "interrupcoes pelo temporizador para executar a sub-rotina da linha 100.",
    "10 REM PROGRAMA ON INTERVAL" + #CRLF$ +
    "20 ON INTERVAL=50 GOSUB 50" + #CRLF$ +
    "30 INTERVAL ON" + #CRLF$ +
    "40 GOTO 40" + #CRLF$ +
    "50 C=C+1" + #CRLF$ +
    "60 PRINT C" + #CRLF$ +
    "70 RETURN",
    108)

  MSXDict_Add("ON KEY GOSUB", #False, #False, "(on key go to subroutine)",
    "Desvia o programa para uma certa sub-rotina, dependendo da tecla de funcao que for " +
    "pressionada.",
    "ON KEY GOSUB numero da linha [,numero da linha] [,numero da linha]...",
    "ON KEY GOSUB 10,20,30",
    "A instrucao ON KEY GOSUB e utilizada para o desvio do programa para uma sub-rotina quando se " +
    "pressiona uma das teclas de funcoes. No exemplo dado acima, caso se pressione a tecla de " +
    "funcoes 1, o programa vai para a sub-rotina da linha 10, se for pressionada a segunda tecla " +
    "de funcoes o programa vai para a sub-rotina da linha 20, e finalmente, se for pressionada a " +
    "tecla de funcoes 3 o programa salta para a sub-rotina da linha 30.",
    "10 REM PROGRAMA ON KEY" + #CRLF$ +
    "20 ON KEY GOSUB 60,80,100,120,140" + #CRLF$ +
    "30 KEY(5) ON:KEY(4) ON:KEY(3) ON:KEY(2) ON:KEY(1) ON" + #CRLF$ +
    "40 CLS:PRINT" + MSXQ + "Pressione uma tecla funcional." + MSXQ + #CRLF$ +
    "50 GOTO 50" + #CRLF$ +
    "60 PRINT" + MSXQ + "Tecla 1 pressionada." + MSXQ + #CRLF$ +
    "70 RETURN" + #CRLF$ +
    "80 PRINT" + MSXQ + "Tecla 2 pressionada." + MSXQ + #CRLF$ +
    "90 RETURN" + #CRLF$ +
    "100 PRINT" + MSXQ + "Tecla 3 pressionada." + MSXQ + #CRLF$ +
    "110 RETURN" + #CRLF$ +
    "120 PRINT" + MSXQ + "Tecla 4 pressionada." + MSXQ + #CRLF$ +
    "130 RETURN" + #CRLF$ +
    "140 PRINT" + MSXQ + "Tecla 5 pressionada." + MSXQ + #CRLF$ +
    "150 RETURN",
    109)

  MSXDict_Add("ON SPRITE GOSUB", #False, #False, "(on sprite go to subroutine)",
    "Desvia o programa para uma sub-rotina caso duas figuras moveis na tela se sobreponham.",
    "ON SPRITE GOSUB [numero de linha]",
    "ON SPRITE GOSUB 500",
    "A instrucao ON SPRITE GOSUB indica em que linha se inicia a sub-rotina caso exista a " +
    "sobreposicao de duas figuras. Esta instrucao e muito util na confeccao de jogos de acao.",
    "10 REM PROGRAMA ON SPRITE" + #CRLF$ +
    "20 SCREEN 2,1" + #CRLF$ +
    "30 SPRITE$(0)=CHR$(&H3C)+CHR$(&H7E)+CHR$(&H81)+CHR$(&H81)+CHR$(&HFF)+CHR$(&H7E)+CHR$(&H24)+CHR$(&H42)" + #CRLF$ +
    "40 ON SPRITE GOSUB 110" + #CRLF$ +
    "50 SPRITE ON" + #CRLF$ +
    "60 FOR X=0 TO 255" + #CRLF$ +
    "70 PUT SPRITE 0,(X,100),15,0" + #CRLF$ +
    "80 PUT SPRITE 1,(255-X,100),10,0" + #CRLF$ +
    "90 NEXT X" + #CRLF$ +
    "100 RUN" + #CRLF$ +
    "110 SPRITE OFF" + #CRLF$ +
    "120 BEEP" + #CRLF$ +
    "130 SPRITE ON" + #CRLF$ +
    "140 RETURN",
    110)

  MSXDict_Add("ON STOP GOSUB", #False, #False, "(on stop gosub)",
    "Instrucao que indica para que sub-rotina o programa deve ser desviado caso se pressione " +
    "CONTROL + STOP.",
    "ON STOP GOSUB numero de linha",
    "ON STOP GOSUB 100",
    "A instrucao ON STOP GOSUB desvia o programa para a sub-rotina indicada pelo numero da linha " +
    "apos o GOSUB, quando se pressionam as teclas CONTROL e STOP simultaneamente.",
    "10 REM Programa ON STOP" + #CRLF$ +
    "20 ON STOP GOSUB 70" + #CRLF$ +
    "30 STOP ON" + #CRLF$ +
    "40 SCREEN 0" + #CRLF$ +
    "50 PRINT" + MSXQ + "Pressione: CONTROL + STOP" + MSXQ + #CRLF$ +
    "60 GOTO 60" + #CRLF$ +
    "70 PRINT" + MSXQ + "As teclas CONTROL e STOP foram" + MSXQ + #CRLF$ +
    "80 PRINT" + MSXQ + "pressionadas!" + MSXQ + #CRLF$ +
    "90 PRINT" + MSXQ + "Para parar o programa, digite" + MSXQ + #CRLF$ +
    "100 PRINT" + MSXQ + "a barra de espacos!" + MSXQ + #CRLF$ +
    "110 IF STRIG(0)=0 THEN 110 ELSE END" + #CRLF$ +
    "120 RETURN",
    111)

  ; CONFERIR: o EXEMPLO no livro mostra "400b," como o penultimo numero de
  ; linha, o que nao e sintaxe BASIC valida - preservado aqui como
  ; "400,500" por ser a leitura mais provavel (a FUNCAO enumera exatamente
  ; 5 sub-rotinas), mas vale conferir contra a pagina 112 original.
  MSXDict_Add("ON STRIG GOSUB", #False, #False, "(on stick trigger go to subroutine)",
    "Desvia para uma sub-rotina caso a barra de espacos ou os botoes do joystick sejam " +
    "pressionados.",
    "ON STRIG GOSUB numero de linha [,numero de linha ...]",
    "ON STRIG GOSUB 100,200,300,400,500",
    "A instrucao ON STRIG GOSUB tem como funcao desviar para uma sub-rotina caso a barra de " +
    "espacos ou algum dos botoes dos joysticks sejam pressionados. Depois do GOSUB devem vir os " +
    "numeros das linhas onde se iniciam as sub-rotinas, na seguinte ordem:" + #CRLF$ + #CRLF$ +
    "1. - numero da linha que indica que a barra foi pressionada." + #CRLF$ +
    "2. - numero da linha que indica que o botao 1 do joystick A foi pressionado." + #CRLF$ +
    "3. - numero da linha que indica que o botao 1 do joystick B foi pressionado." + #CRLF$ +
    "4. - numero da linha que indica que o botao 2 do joystick A foi pressionado." + #CRLF$ +
    "5. - numero da linha que indica que o botao 2 do joystick B foi pressionado.",
    "10 REM PROGRAMA ON STRIG" + #CRLF$ +
    "20 ON STRIG GOSUB 90,110,130,150,170" + #CRLF$ +
    "30 FOR F=0 TO 4" + #CRLF$ +
    "40 STRIG(F) ON" + #CRLF$ +
    "50 NEXT F" + #CRLF$ +
    "60 CLS" + #CRLF$ +
    "70 PRINT" + MSXQ + "Pressione a barra de espacos ou um dos botoes dos joysticks." + MSXQ + #CRLF$ +
    "80 GOTO 80" + #CRLF$ +
    "90 PRINT" + MSXQ + "Barra de espacos pressionada." + MSXQ + #CRLF$ +
    "100 RETURN" + #CRLF$ +
    "110 PRINT" + MSXQ + "Botao 1 pressionado (joystick A)" + MSXQ + #CRLF$ +
    "120 RETURN" + #CRLF$ +
    "130 PRINT" + MSXQ + "Botao 1 pressionado (joystick B)" + MSXQ + #CRLF$ +
    "140 RETURN" + #CRLF$ +
    "150 PRINT" + MSXQ + "Botao 2 pressionado (joystick A)" + MSXQ + #CRLF$ +
    "160 RETURN" + #CRLF$ +
    "170 PRINT" + MSXQ + "Botao 2 pressionado (joystick B)" + MSXQ + #CRLF$ +
    "180 RETURN",
    112)

  MSXDict_Add("OPEN", #False, #False, "(open)",
    "Abre um arquivo e especifica modo leitura/escrita.",
    "OPEN " + MSXQ + "nome do dispositivo [nome do arquivo]" + MSXQ + #CRLF$ +
    "FOR modo AS [#] numero do arquivo",
    "OPEN" + MSXQ + "CAS:MICRO" + MSXQ + " FOR INPUT AS # 4",
    "Abrir arquivo com um numero especificado e realizar operacoes de entrada/saida para um " +
    "dispositivo especificado. Os dispositivos sao:" + #CRLF$ + #CRLF$ +
    "Cassete .......................CAS:" + #CRLF$ +
    "Tela no modo de texto..........CRT:" + #CRLF$ +
    "Tela no modo grafico...........GRP:" + #CRLF$ +
    "Impressora......................LPT:" + #CRLF$ + #CRLF$ +
    "O nome do arquivo pode ser formado por ate seis caracteres (os excedentes sao ignorados). O " +
    "modo pode ser OUTPUT (para escrita) e INPUT (para leitura). O numero de arquivo deve estar " +
    "entre 1 e o numero especificado por MAXFILES." + #CRLF$ + #CRLF$ +
    "NOTA: CTR:, GRP: e LPT: estao destinados a escrita. Neste caso, portanto, o modo so podera " +
    "ser especificado como OUTPUT.",
    "10 REM PROGRAMA OPEN" + #CRLF$ +
    "20 MAXFILES=1" + #CRLF$ +
    "30 CLS" + #CRLF$ +
    "40 OPEN " + MSXQ + "GRP:" + MSXQ + " FOR OUTPUT AS #1" + #CRLF$ +
    "50 SCREEN 2" + #CRLF$ +
    "55 LINE(0,0)-(255,191),5,BF" + #CRLF$ +
    "56 CIRCLE(120,120),50" + #CRLF$ +
    "60 PRINT #1," + MSXQ + "EXPERT" + MSXQ + #CRLF$ +
    "70 FOR I=1 TO 1000:NEXT" + #CRLF$ +
    "80 CLOSE 1" + #CRLF$ +
    "90 SCREEN 0" + #CRLF$ +
    "100 LIST",
    113)

  MSXDict_Add("OUT", #False, #True, "(out)",
    "Coloca um byte na porta especificada.",
    "OUT numero da porta, expressao",
    "OUT 13,240",
    "Enviar dados diretamente a uma porta especificada.",
    "10 SCREEN 0:OUT 153,0:OUT 153,0" + #CRLF$ +
    "20 FOR I=0 TO 959" + #CRLF$ +
    "30 OUT 152,65" + #CRLF$ +
    "40 NEXT I",
    114)
EndProcedure

; --- Letra P (pagina 115-131 do livro = pagina 112-128 do PDF) ---
Procedure MSXDict_BuildLetterP()
  MSXDict_Add("PAD", #True, #False, "(pad)",
    "Verifica o estado do touch pad.",
    "PAD (n)",
    "PAD(2)",
    "Mostrar o estado do touch pad. Se n estiver entre 0 e 3, PAD(n) mostrara o estado do touch " +
    "pad ligado ao terminal A. Entre 4 e 7, o valor obtido correspondera ao terminal B." + #CRLF$ + #CRLF$ +
    "Valor de n (terminal A / terminal B) e significado de PAD(n):" + #CRLF$ +
    "- 0 / 4 - 0 tocado; -1 nao tocado" + #CRLF$ +
    "- 1 / 5 - coordenada x do lugar tocado" + #CRLF$ +
    "- 2 / 6 - coordenada y do lugar tocado" + #CRLF$ +
    "- 3 / 7 - 0 interruptor pressionado; -1 interruptor nao pressionado",
    "10 REM PROGRAMA PAD" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 C=0" + #CRLF$ +
    "40 COLOR,C,C" + #CRLF$ +
    "50 IF PAD(3)=0 THEN GOTO 40" + #CRLF$ +
    "60 C=C+1:IF C=15 THEN C=0" + #CRLF$ +
    "70 GOTO 40",
    115)

  MSXDict_Add("PAINT", #False, #False, "(paint)",
    "Preenche uma certa area com uma cor especificada pelo usuario.",
    "PAINT [STEP] (X,Y) [, cor da pintura]" + #CRLF$ +
    "[,cor do limite da area]",
    "PAINT(70,70),10,10",
    "A instrucao PAINT colore com a cor especificada pelo usuario uma area pre-definida. O valor " +
    "da coordenada X pode variar de 0 ate 255 enquanto a coordenada Y pode variar de 0 ate 191. No " +
    "modo de alta resolucao (SCREEN 2) a cor da linha que limita a area deve ser igual a cor que " +
    "preenchera a area. Isto nao acontece no modo de menor resolucao (SCREEN 3). Para maiores " +
    "detalhes sobre o STEP veja o comando PSET.",
    "10 REM PROGRAMA PAINT" + #CRLF$ +
    "20 SCREEN 2" + #CRLF$ +
    "30 FOR F=1 TO 90" + #CRLF$ +
    "40 X=RND(1)*256" + #CRLF$ +
    "50 Y=RND(1)*192" + #CRLF$ +
    "60 C=RND(1)*14+2" + #CRLF$ +
    "70 R=RND(1)*30" + #CRLF$ +
    "80 CIRCLE (X,Y),R,C" + #CRLF$ +
    "90 PAINT (X,Y),C,C" + #CRLF$ +
    "100 NEXT F",
    116)

  MSXDict_Add("PDL", #True, #False, "(paddle)",
    "Apresenta o valor determinado pelo paddle.",
    "PDL (n)",
    "PDL(3)",
    "Transforma em dados numericos as posicoes de um paddle. Se n for um numero impar os dados " +
    "obtidos serao correspondentes ao paddle conectado ao terminal A. Se n for par os dados serao " +
    "provenientes do terminal B. O valor de n pode estar entre 0 e 12 e os valores obtidos estarao " +
    "entre 0 e 255.",
    "10 REM PROGRAMA PDL" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 C=0" + #CRLF$ +
    "40 COLOR,C,C" + #CRLF$ +
    "50 IF PDL(1)=0 THEN GOTO 40" + #CRLF$ +
    "60 C=C+1:IF C=15 THEN C=0" + #CRLF$ +
    "70 GOTO 40",
    117)

  ; O livro tem PEEK marcada com "*" (avancado) e um FORMATO onde falta um
  ; ";" antes de PEEK(F) na linha 30 do programa - preservado como impresso.
  MSXDict_Add("PEEK", #True, #True, "(peek)",
    "Apresenta o valor armazenado em um endereco da memoria.",
    "PEEK (endereco)",
    "PEEK(1020)",
    "Determina o valor do byte armazenado em um determinado endereco da memoria. Este endereco " +
    "pode ser uma constante, variavel numerica, variavel indexada ou expressoes.",
    "10 REM PROGRAMA PEEK" + #CRLF$ +
    "20 FOR F=0 TO 8191" + #CRLF$ +
    "30 PRINT F;" + MSXQ + "......." + MSXQ + "PEEK(F)" + #CRLF$ +
    "40 FOR G=1 TO 200:NEXT G" + #CRLF$ +
    "50 NEXT F",
    118)

  ; PLAY ocupa 3 paginas (119-121), a maior parte tabelas de subcomandos
  ; (com notacao musical grafica no livro, aqui descrita em texto) -
  ; representadas como lista dentro da FUNCAO.
  MSXDict_Add("PLAY", #False, #False, "(play)",
    "Toca sequencias de notas e/ou acordes musicais compostos de uma a tres notas " +
    "simultaneamente, com tempo, oitava, duracao, tom e volume programavel.",
    "PLAY subcomandos",
    "PLAY" + MSXQ + "s0m5000v15cdefgab" + MSXQ,
    "Gerar, utilizando o Gerador Programavel de Som (PSG), sequencias musicais compostas de ate " +
    "tres notas simultaneas, especificadas por subcomandos. Esses subcomandos podem ser " +
    "representados por strings dentro de " + MSXQ + " " + MSXQ + " ou por variaveis string. Por exemplo:" + #CRLF$ + #CRLF$ +
    "10 PLAY" + MSXQ + "C" + MSXQ + #CRLF$ +
    "20 GOTO 10" + #CRLF$ +
    "-> toca uma nota repetidamente" + #CRLF$ + #CRLF$ +
    "10 PLAY" + MSXQ + "G" + MSXQ + "," + MSXQ + "E" + MSXQ + "," + MSXQ + "B" + MSXQ + #CRLF$ +
    "20 GOTO 10" + #CRLF$ +
    "-> toca um acorde com tres notas" + #CRLF$ + #CRLF$ +
    "10 M$=" + MSXQ + "GEB" + MSXQ + #CRLF$ +
    "20 N$=" + MSXQ + "EGB" + MSXQ + #CRLF$ +
    "30 O$=" + MSXQ + "BEG" + MSXQ + #CRLF$ +
    "-> atribui a string uma sequencia de notas musicais" + #CRLF$ + #CRLF$ +
    "40 PLAY M$,N$,O$" + #CRLF$ +
    "-> toca as sequencias utilizando simultaneamente os tres canais de som" + #CRLF$ + #CRLF$ +
    "50 M$=" + MSXQ + "GEB" + MSXQ + #CRLF$ +
    "60 PLAY M$," + MSXQ + "02EGB" + MSXQ + "," + MSXQ + "06BEG" + MSXQ + #CRLF$ +
    "-> tres canais de som em diferentes oitavas" + #CRLF$ + #CRLF$ +
    "SUBCOMANDOS DA FUNCAO PLAY:" + #CRLF$ + #CRLF$ +
    "- Tn (tempo): valores permitidos de 32 a 255. Determina o andamento da musica. O valor " +
    "inicial e T120." + #CRLF$ + #CRLF$ +
    "- On (oitava): valores permitidos de 1 a 8. Determina uma das 8 oitavas do MSX. O valor " +
    "inicial e 04." + #CRLF$ + #CRLF$ +
    "- Ln (duracao): valores permitidos de 1 a 64 (L1, L2, L4, L8, L16, L32, L64 - da semibreve " +
    "ate a semifusa). Determina a duracao da nota. O valor inicial e L4." + #CRLF$ + #CRLF$ +
    "- Nn (nota): valores permitidos de 0 a 96. Especifica uma nota musical (N0 e uma pausa; " +
    "quando n aumenta de uma unidade a nota sobe meio tom)." + #CRLF$ + #CRLF$ +
    "- A-G / An-Gn: valores permitidos de 1 a 64. Especifica a nota musical dentro de uma oitava " +
    "pre-determinada. O sinal " + MSXQ + "#" + MSXQ + " (ou " + MSXQ + "+" + MSXQ + ") colocado ao lado da nota especifica um " +
    "sustenido. O sinal " + MSXQ + "-" + MSXQ + " determina um bemol. Por exemplo:" + #CRLF$ +
    "  PLAY" + MSXQ + "C-" + MSXQ + "    tres notas" + #CRLF$ +
    "  PLAY" + MSXQ + "C" + MSXQ + "     separadas" + #CRLF$ +
    "  PLAY" + MSXQ + "C#" + MSXQ + "    por meio tom" + #CRLF$ +
    "  A duracao da nota pode ser fixada atraves de n. (D4 e o mesmo que L4D). Quando omitido, a " +
    "duracao sera a determinada por Ln." + #CRLF$ + #CRLF$ +
    "- Rn (pausa): valores permitidos de 1 a 64 (R1, R2, R4, R8, R16, R32, R64). Determina uma " +
    "pausa." + #CRLF$ + #CRLF$ +
    "- . (ponto): aumenta a duracao de uma nota ou de uma pausa em 50%." + #CRLF$ + #CRLF$ +
    "- Vn (volume): valores permitidos de 0 a 15. Determina o volume. O volume aumenta com o " +
    "valor de n. O valor inicial e V8." + #CRLF$ + #CRLF$ +
    "- Mn (periodo do envelope): valores permitidos de 0 a 65535. Determina o periodo da " +
    "variacao de volume durante a execucao da nota. Veja a funcao SOUND, nota (i) para mais " +
    "informacoes." + #CRLF$ + #CRLF$ +
    "- Sn (forma do envelope): valores permitidos de 0 a 15. Determina o formato do envelope. " +
    "Para maiores detalhes veja a funcao SOUND (tabela de envelopes e nota (j)).",
    "10 REM PROGRAMA PLAY" + #CRLF$ +
    "20 PLAY" + MSXQ + "S0M10000V15T180" + MSXQ + #CRLF$ +
    "30 PLAY" + MSXQ + "L403GFL8EDEC02BABG" + MSXQ + #CRLF$ +
    "40 PLAY" + MSXQ + "03L4CEAGB04L3C03" + MSXQ + #CRLF$ +
    "50 PLAY" + MSXQ + "L8AGFEL3EL4DGB04C" + MSXQ + #CRLF$ +
    "60 PLAY" + MSXQ + "L6CEL4DL6DFL4ECFEDE" + MSXQ + #CRLF$ +
    "70 PLAY" + MSXQ + "L6FEDCL4C03B" + MSXQ + #CRLF$ +
    "80 PLAY" + MSXQ + "04L4CC#L3DL6DFL4E" + MSXQ + #CRLF$ +
    "90 PLAY" + MSXQ + "L6EGL4FD03GB04C" + MSXQ,
    119)

  MSXDict_Add("POINT", #True, #False, "(point)",
    "Obtem o codigo de cor de um ponto especificado na tela.",
    "POINT(coluna,linha)",
    "POINT(143,77)",
    "A funcao POINT obtem o codigo de cor de um dado ponto da tela. Os valores da coluna e da " +
    "linha devem ser uma constante, uma variavel ou uma expressao que resulte um numero entre " +
    "-32767 e 32767. Se esse valor estiver fora da faixa correspondente a tela, o valor obtido " +
    "por POINT sera -1.",
    "10 REM PROGRAMA POINT" + #CRLF$ +
    "20 SCREEN 3" + #CRLF$ +
    "30 FOR I=1 TO 25" + #CRLF$ +
    "40 X=INT(RND(1)*255)" + #CRLF$ +
    "50 Y=INT(RND(1)*191)" + #CRLF$ +
    "60 PSET(X,Y),8" + #CRLF$ +
    "70 NEXT I" + #CRLF$ +
    "80 FOR X=1 TO 250 STEP 4" + #CRLF$ +
    "90 FOR Y=1 TO 191 STEP 4" + #CRLF$ +
    "100 C=POINT(X,Y)" + #CRLF$ +
    "110 IF C=8 THEN PSET(X,Y),14" + #CRLF$ +
    "120 NEXT Y,X" + #CRLF$ +
    "130 FOR B=1 TO 500:NEXT B",
    122)

  MSXDict_Add("POKE", #False, #False, "(poke)",
    "Escreve um dado numerico em um certo endereco da memoria.",
    "POKE endereco, expressao",
    "POKE &HE111,201",
    "A instrucao POKE escreve dados numericos em um certo endereco da memoria. Tanto a memoria " +
    "como o dado podem ser escritos em decimal ou hexadecimal. Caso voce use numeros " +
    "hexadecimais, lembre-se de precede-los por &H. O valor do endereco pode variar de -32768 " +
    "(decimal) a 65535 (decimal) e o valor do dado de 0 (decimal) a 255 (decimal).",
    "10 REM PROGRAMA ESPELHO" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 POKE 40001!,ASC(" + MSXQ + "E" + MSXQ + ")" + #CRLF$ +
    "40 POKE 40002!,ASC(" + MSXQ + "T" + MSXQ + ")" + #CRLF$ +
    "50 POKE 40003!,ASC(" + MSXQ + "N" + MSXQ + ")" + #CRLF$ +
    "60 POKE 40004!,ASC(" + MSXQ + "E" + MSXQ + ")" + #CRLF$ +
    "70 POKE 40005!,ASC(" + MSXQ + "I" + MSXQ + ")" + #CRLF$ +
    "80 POKE 40006!,ASC(" + MSXQ + "D" + MSXQ + ")" + #CRLF$ +
    "90 POKE 40007!,ASC(" + MSXQ + "A" + MSXQ + ")" + #CRLF$ +
    "100 POKE 40008!,ASC(" + MSXQ + "R" + MSXQ + ")" + #CRLF$ +
    "110 POKE 40009!,ASC(" + MSXQ + "G" + MSXQ + ")" + #CRLF$ +
    "120 FOR I=40009! TO 40001! STEP-1!" + #CRLF$ +
    "130 PRINT I, " + MSXQ + "....." + MSXQ + "CHR$(PEEK(I))" + #CRLF$ +
    "140 NEXT I" + #CRLF$ +
    "150 END",
    123)

  MSXDict_Add("POS", #True, #False, "(position)",
    "Indica a abcissa X que o cursor ocupa.",
    "POS (X)",
    "PRINT POS(0)",
    "A funcao POS indica a abcissa que o cursor ocupa, sendo que o valor de X entre parenteses " +
    "nao tem significado algum (argumento ficticio).",
    "10 REM PROGRAMA POS" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 INPUT A$" + #CRLF$ +
    "40 PRINT A$;" + MSXQ + " " + MSXQ + ";" + #CRLF$ +
    "50 X=POS(5)" + #CRLF$ +
    "60 PRINT" + MSXQ + "POS=" + MSXQ + ";X" + #CRLF$ +
    "70 GOTO 30",
    124)

  MSXDict_Add("PRESET", #False, #False, "(point reset)",
    "Acende ou apaga um ponto nas telas graficas.",
    "PRESET [STEP] (X,Y) [,cor]",
    "PRESET(7,10)",
    "Se for escolhida uma cor diferente da cor do fundo a instrucao PRESET funciona exatamente " +
    "como a PSET. Se nenhuma cor for especificada, porem, sera plotado um ponto de cor igual a do " +
    "fundo, dando a impressao de que o ponto foi apagado.",
    "10 REM PROGRAMA PRESET" + #CRLF$ +
    "20 SCREEN 3" + #CRLF$ +
    "30 FOR X=0 TO 255" + #CRLF$ +
    "40 PSET (X,25),11" + #CRLF$ +
    "50 PRESET (X,25)" + #CRLF$ +
    "60 NEXT X" + #CRLF$ +
    "70 GOTO 30",
    125)

  MSXDict_Add("PRINT", #False, #False, "(print)",
    "Apresenta dados na tela.",
    "PRINT expressao[separador expressao separador]",
    "PRINT " + MSXQ + "Isto aparecera' na tela" + MSXQ,
    "O comando PRINT apresenta na tela os dados definidos pelas expressoes. Uma expressao pode " +
    "ser uma constante, uma variavel (numericas ou strings). Se a expressao for numerica, basta " +
    "escreve-la normalmente, mas se ela for uma string deve estar entre aspas. O separador pode " +
    "ser uma virgula (,) ou um ponto e virgula (;). A virgula faz com que a expressao a sua " +
    "frente seja apresentada a partir da coluna 0 ou da coluna 14. O ponto e virgula faz com que " +
    "a apresentacao seja feita logo a seguir o ultimo dado apresentado.",
    "10 REM PROGRAMA PRINT" + #CRLF$ +
    "20 PRINT " + MSXQ + "GRADIENTE & ALEPH" + MSXQ + #CRLF$ +
    "30 GOTO 20",
    126)

  ; Tabela de simbolos de formato do PRINT USING, representada como lista
  ; dentro da FUNCAO (mesma convencao ja usada em BASE/COLOR/DRAW).
  MSXDict_Add("PRINT USING", #False, #False, "(print using)",
    "Apresenta dados com um formato especifico na tela.",
    "PRINT USING formato;expressao separador ...",
    "PRINT USING" + MSXQ + "!" + MSXQ + ";" + MSXQ + "GRADIENTE" + MSXQ + "," + MSXQ + "ALEPH" + MSXQ,
    "O comando PRINT USING apresenta dados na tela com um formato definido por um dos simbolos " +
    "da tabela a seguir:" + #CRLF$ + #CRLF$ +
    "- " + MSXQ + "!" + MSXQ + " : Apresenta apenas o primeiro caractere de uma string. Exemplo: " +
    "PRINT USING" + MSXQ + "!" + MSXQ + ";A$;B$;C$" + #CRLF$ + #CRLF$ +
    "- " + MSXQ + "\n-espaco\" + MSXQ + " : Apresenta n+2 caracteres de uma string. Exemplo: " +
    "PRINT USING" + MSXQ + "\  \" + MSXQ + ";A$;B$;C$" + #CRLF$ + #CRLF$ +
    "- " + MSXQ + "&" + MSXQ + " : Apresenta todos os caracteres de uma string. Exemplo: " +
    "PRINT USING" + MSXQ + "&" + MSXQ + ";A$;B$;C$" + #CRLF$ + #CRLF$ +
    "- " + MSXQ + "#" + MSXQ + " : Especifica o formato e o numero de digitos apresentados de " +
    "um dado numerico. Exemplo: PRINT USING" + MSXQ + "### #.##" + MSXQ + ";455.43557" + #CRLF$ + #CRLF$ +
    "- " + MSXQ + "+" + MSXQ + " : Acrescenta o sinal + ou - antes ou apos dados numericos " +
    "conforme eles sejam positivos, nulos ou negativos. Exemplo: PRINT USING" + MSXQ + "+ ###" + MSXQ + ";-233,3434,675,-13435.232" + #CRLF$ + #CRLF$ +
    "- " + MSXQ + "-" + MSXQ + " : Acrescenta o sinal - apos numeros negativos. Exemplo: " +
    "PRINT USING" + MSXQ + "-" + MSXQ + ";-12312;-13;122" + #CRLF$ + #CRLF$ +
    "- " + MSXQ + "**" + MSXQ + " : Preenche com asteriscos os espacos ocupados por um dado " +
    "numerico. Exemplo: PRINT USING" + MSXQ + "**.##" + MSXQ + ";1.2367" + #CRLF$ + #CRLF$ +
    "- " + MSXQ + "$$" + MSXQ + " : Acrescenta o simbolo $ antes de dados numericos. Exemplo: " +
    "PRINT USING" + MSXQ + "$$ ###" + MSXQ + ";233,3434,675,13435.232" + #CRLF$ + #CRLF$ +
    "- " + MSXQ + "**$" + MSXQ + " : Acrescenta o simbolo $ antes de dados numericos e preenche " +
    "com asteriscos os espacos nao ocupados. Exemplo: PRINT USING" + MSXQ + "** $ ###" + MSXQ + ";233,3434,675,13435,232" + #CRLF$ + #CRLF$ +
    "- " + MSXQ + "," + MSXQ + " : Acrescenta uma virgula a cada tres digitos a esquerda do " +
    "ponto decimal. Exemplo: PRINT USING" + MSXQ + "####,. ##" + MSXQ + ";1235.122,1133.11378" + #CRLF$ + #CRLF$ +
    "- " + MSXQ + "^^^^" + MSXQ + " : Apresenta dados numericos com ponto flutuante. Exemplo: " +
    "PRINT USING" + MSXQ + "### ##^^^^" + MSXQ + ";1235,122,1133,11378",
    "",
    127)

  MSXDict_Add("PRINT#", #False, #False, "(print number)",
    "Escreve dados em arquivo aberto por OPEN.",
    "PRINT# numero de arquivo, expressao",
    "PRINT #2," + MSXQ + "ACROS" + MSXQ,
    "Introduzir dados em arquivo aberto por OPEN. O numero de arquivos deve estar entre 1 e o " +
    "especificado por MAXFILES. A expressao pode ser constituida de constantes, variaveis " +
    "numericas, variaveis indexadas, alfanumericas ou suas expressoes.",
    "10 REM PROGRAMA PRINT #" + #CRLF$ +
    "20 MAXFILES=2" + #CRLF$ +
    "30 OPEN " + MSXQ + "GRP:" + MSXQ + " FOR OUTPUT AS #1" + #CRLF$ +
    "40 OPEN " + MSXQ + "CRT:" + MSXQ + " FOR OUTPUT AS #2" + #CRLF$ +
    "50 SCREEN 2" + #CRLF$ +
    "60 LINE(10,10)-(240,190),9,BF" + #CRLF$ +
    "70 CIRCLE(128,80),60,8" + #CRLF$ +
    "71 PSET(110,70),6" + #CRLF$ +
    "80 PRINT #1," + MSXQ + "EXPERT" + MSXQ + #CRLF$ +
    "90 CIRCLE(128,100),18,8" + #CRLF$ +
    "91 PSET(119,100),3" + #CRLF$ +
    "100 PRINT #1," + MSXQ + "MSX" + MSXQ + #CRLF$ +
    "110 FOR I=1 TO 3000:NEXT" + #CRLF$ +
    "120 CLOSE 1" + #CRLF$ +
    "130 SCREEN 0" + #CRLF$ +
    "140 LIST",
    128)

  MSXDict_Add("PRINT# USING", #False, #False, "(print number using)",
    "Escreve dados com o formato desejado em um arquivo aberto pelo comando OPEN.",
    "PRINT # numero de arquivo USING simbolo de formato, expressao",
    "PRINT#2,USING" + MSXQ + "###.####" + MSXQ + ";A",
    "Esta instrucao e usada para introduzir dados em um arquivo, com formato especificado. O " +
    "numero do arquivo deve estar entre 1 e o numero de arquivos definido em MAXFILES. A " +
    "expressao pode ser formada de variaveis numericas, constantes, variaveis indexadas ou suas " +
    "expressoes.",
    "10 REM PROGRAMA PRINT # USING" + #CRLF$ +
    "20 MAXFILES=1" + #CRLF$ +
    "30 OPEN " + MSXQ + "GRP:" + MSXQ + " FOR OUTPUT AS #1" + #CRLF$ +
    "50 SCREEN 2" + #CRLF$ +
    "60 LINE(60,14)-(196,154),9,BF" + #CRLF$ +
    "70 CIRCLE(128,80),60,12" + #CRLF$ +
    "71 PSET(106,65),9" + #CRLF$ +
    "80 PRINT #1," + MSXQ + "EXPERT" + MSXQ + #CRLF$ +
    "90 CIRCLE(128,100),26,13" + #CRLF$ +
    "91 PSET(110,100),9" + #CRLF$ +
    "100 PRINT #1,USING" + MSXQ + "##.##" + MSXQ + ";14.11" + #CRLF$ +
    "110 FOR I=1 TO 4000:NEXT" + #CRLF$ +
    "120 CLOSE 1",
    129)

  MSXDict_Add("PSET", #False, #False, "(point set)",
    "Desenha um ponto na tela de modo grafico.",
    "PSET [STEP] (coordenada x,coordenada y) [,cor]",
    "PSET(129,73),3",
    "Desenha um ponto na tela de modo grafico, determinado pelas coordenadas x e y. Se as " +
    "coordenadas forem precedidas pelo STEP (opcional), a origem do sistema de eixos sera " +
    "deslocada do canto superior esquerdo para o ultimo ponto plotado antes da execucao. A cor " +
    "deve ser indicada por um inteiro entre 0 e 15. Se for omitida, permanece a cor de fundo " +
    "atual. As coordenadas x e y podem ser constantes, variaveis numericas, variaveis indexadas " +
    "ou suas expressoes.",
    "10 REM PROGRAMA PSET" + #CRLF$ +
    "20 SCREEN 3" + #CRLF$ +
    "30 FOR C=2 TO 8" + #CRLF$ +
    "40 PSET (70,50),C" + #CRLF$ +
    "50 PSET (66,54),C+1" + #CRLF$ +
    "60 PSET (74,54),C+2" + #CRLF$ +
    "70 PSET (62,58),C+3" + #CRLF$ +
    "80 PSET (78,58),C+4" + #CRLF$ +
    "90 PSET (66,62),C+5" + #CRLF$ +
    "100 PSET (74,62),C+6" + #CRLF$ +
    "110 PSET (70,66),C+7" + #CRLF$ +
    "120 FOR F=1 TO 500:NEXT F" + #CRLF$ +
    "130 NEXT C" + #CRLF$ +
    "140 GOTO 30" + #CRLF$ +
    "150 END",
    130)

  MSXDict_Add("PUT SPRITE", #False, #False, "(put sprite)",
    "Torna visivel o sprite especificado em um endereco determinado do plano de sprites.",
    "PUT SPRITE numero da camada" + #CRLF$ +
    "[[STEP] (coordenada x, coordenada y)]," + #CRLF$ +
    "[cor], [numero do sprite]",
    "PUT SPRITE 9,(111,25),4,2",
    "Coloca na tela um sprite especificado nas coordenadas desejadas de uma camada tambem " +
    "especificada. O numero da camada pode variar entre 0 e 31. A coordenada x deve estar entre " +
    "-32 e 255. A coordenada y deve estar entre -32 e 191. Tanto x quanto y podem ser constantes, " +
    "variaveis indexadas, variaveis numericas ou suas expressoes. A cor deve ser determinada por " +
    "inteiros de zero a 15. Se omitida permanece a cor de fundo atual. Se STEP (coordenada " +
    "x,coordenada y) for omitido fica a posicao anteriormente determinada pela ultima instrucao " +
    "de graficos. O numero do sprite depende do numero de pontos, ou seja, para 8x8 pontos deve " +
    "ser um numero entre 0 e 255 e para 16x16 pontos, de 0 a 63. Se for omitido sera igual ao " +
    "numero da camada a que ele pertence.",
    "10 REM PROGRAMA PUT SPRITE" + #CRLF$ +
    "20 SCREEN 2,1" + #CRLF$ +
    "30 FOR T=1 TO 8" + #CRLF$ +
    "40 READ A$" + #CRLF$ +
    "50 S$=S$+CHR$(VAL(" + MSXQ + "&B" + MSXQ + "+A$))" + #CRLF$ +
    "60 NEXT T" + #CRLF$ +
    "70 SPRITE$(1) = S$" + #CRLF$ +
    "80 PUT SPRITE 0,(128,96),8,1: GOTO 80" + #CRLF$ +
    "90 DATA    11000111" + #CRLF$ +
    "100 DATA    11100011" + #CRLF$ +
    "110 DATA    01110011" + #CRLF$ +
    "120 DATA    00111011" + #CRLF$ +
    "130 DATA    11011100" + #CRLF$ +
    "140 DATA    11001110" + #CRLF$ +
    "150 DATA    11000111" + #CRLF$ +
    "160 DATA    11000011" + #CRLF$ +
    "170 GOTO 170",
    131)
EndProcedure

; --- Letra R (pagina 132-139 do livro = pagina 129-136 do PDF) ---
; Nao ha letra Q no dicionario - o livro pula de PUT SPRITE direto para READ.
Procedure MSXDict_BuildLetterR()
  MSXDict_Add("READ", #False, #False, "(read)",
    "Le os dados que foram armazenados em uma instrucao DATA.",
    "READ variavel [,variavel ...]",
    "READ A,A$,B",
    "A instrucao READ le os dados armazenados na instrucao DATA. Os dados podem ser numericos ou " +
    "alfanumericos, desde que o tipo da variavel coincida com o tipo de dado. O READ normalmente " +
    "comeca a ler os dados a partir da linha DATA de numero mais baixo.",
    "5 REM PROGRAMA READ" + #CRLF$ +
    "10 CLS" + #CRLF$ +
    "20 DIM A$(5), B(5)" + #CRLF$ +
    "30 FOR I=1 TO 5" + #CRLF$ +
    "40 READ A$(I), B(I)" + #CRLF$ +
    "50 NEXT I" + #CRLF$ +
    "60 PRINT " + MSXQ + "NOME" + MSXQ + ", " + MSXQ + " NOTA" + MSXQ + ": PRINT" + #CRLF$ +
    "70 FOR K=1 TO 5" + #CRLF$ +
    "80 PRINT A$(K), B(K)" + #CRLF$ +
    "90 NEXT K" + #CRLF$ +
    "100 DATA ALDO, 2.75, ROSANA, 3.17, NANCY, 3.65, VANIA, 3.96, ANA, 2.98",
    132)

  MSXDict_Add("REM", #False, #False, "(remark)",
    "Introducao de comentarios ou observacoes na listagem do programa.",
    "REM comentario",
    "REM programa exemplo",
    "A instrucao REM tem como funcao facilitar o entendimento de um programa atraves da leitura " +
    "de sua listagem. A instrucao REM pode ser substituida pelo apostrofo ('), que tem a mesma " +
    "funcao. A instrucao REM nao interferira na execucao do programa, pois e ignorada pelo " +
    "computador.",
    "10 REM PROGRAMA REM" + #CRLF$ +
    "20 REM ESTE PROGRAMA NAO FAZ" + #CRLF$ +
    "30 REM ABSOLUTAMENTE NADA!" + #CRLF$ +
    "40 '   ESTE SIMBOLO PODE SER USADO NO" + #CRLF$ +
    "50 '   LUGAR DO REM!",
    133)

  MSXDict_Add("RENUM", #False, #False, "(renumber)",
    "Renumera as linhas do programa.",
    "RENUM [novo numero da 1a linha] [, a partir de que linha sera renumerado]" + #CRLF$ +
    "[, incremento]",
    "RENUM",
    "O comando RENUM e muito util para ser usado no final da confeccao de um programa para " +
    "deixa-lo esteticamente melhor. O RENUM renumera as linhas de 10 em 10 a partir da primeira " +
    "linha, se for digitado sozinho, ou entao renumera como voce preferir, utilizando os recursos " +
    "mostrados no formato. O RENUM tambem renumera as instrucoes GOTO e GOSUB.",
    "10 REM PROGRAMA RENUM" + #CRLF$ +
    "20 PRINT 1" + #CRLF$ +
    "30 PRINT 2" + #CRLF$ +
    "40 PRINT 3" + #CRLF$ +
    "50 PRINT 4" + #CRLF$ +
    "60 PRINT 5" + #CRLF$ +
    "70 RENUM 50,10,20",
    134)

  MSXDict_Add("RESTORE", #False, #False, "(restore)",
    "Indica a partir de qual linha a instrucao READ deve ler os dados contidos na instrucao DATA.",
    "RESTORE [numero de linha]",
    "RESTORE 100",
    "Normalmente os dados lidos pela instrucao READ comecam a partir da linha de numero mais " +
    "baixo que contenha a instrucao DATA, porem esta ordem pode ser alterada com a instrucao " +
    "RESTORE que indica a partir de que linha vao ser lidos os dados. A instrucao RESTORE tambem " +
    "e usada para a releitura dos dados.",
    "10 REM PROGRAMA RESTORE" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 FOR A=1 TO 2" + #CRLF$ +
    "40 READ A,A$:PRINT A,A$" + #CRLF$ +
    "50 NEXT A" + #CRLF$ +
    "60 RESTORE 100" + #CRLF$ +
    "70 FOR A=1 TO 2" + #CRLF$ +
    "80 READ A,A$:PRINT A,A$" + #CRLF$ +
    "90 NEXT A" + #CRLF$ +
    "100 DATA 123,ABC,456,DEF",
    135)

  ; CONFERIR: o RESUMO desta pagina diz "apos a execucao da rotina de
  ; zero", o que nao bate com a FUNCAO (fala em "rotina de erro" e
  ; ON ERROR GOTO) - preservado aqui como "erro" por ser a leitura
  ; coerente com o resto do texto, mas vale conferir contra a pagina 136
  ; original. O livro tambem repete a mesma listagem de PROGRAMA EXEMPLO
  ; duas vezes seguidas (aparente duplicacao de grafica) - transcrita uma
  ; unica vez aqui.
  MSXDict_Add("RESUME", #False, #False, "(resume)",
    "Indica a linha de retorno da rotina principal, apos a execucao da rotina de erro.",
    "RESUME [0]" + #CRLF$ +
    "RESUME numero de linha" + #CRLF$ +
    "RESUME NEXT",
    "RESUME 89",
    "A instrucao RESUME indica a linha de retorno a rotina principal apos a execucao de um " +
    "processo de erros comandado por ON ERROR GOTO. O numero da linha deve ser um inteiro entre " +
    "0 e 65529 e pode ser expresso por uma constante, uma variavel numerica ou uma variavel " +
    "numerica indexada. Se um numero de linha for especificado, a execucao do programa retornara " +
    "para a linha indicada. Se for especificado 0, o programa retornara para a linha em que " +
    "ocorreu o erro e se o NEXT for especificado, retornara para a linha seguinte aquela em que " +
    "ocorreu o erro.",
    "10 REM PROGRAMA RESUME" + #CRLF$ +
    "20 ON ERROR GOTO 70" + #CRLF$ +
    "30 CLS" + #CRLF$ +
    "40 INPUT" + MSXQ + "Digite um numero negativo." + MSXQ + ";A" + #CRLF$ +
    "50 PRINT SQR(A):FOR B=1 TO 500:NEXT B" + #CRLF$ +
    "60 GOTO 30" + #CRLF$ +
    "70 PRINT" + MSXQ + "Nao existe raiz real de numero negativo" + MSXQ + #CRLF$ +
    "80 FOR B=1 TO 1000:NEXT B" + #CRLF$ +
    "90 RESUME 30",
    136)

  MSXDict_Add("RIGHT$", #True, #False, "(right dollar)",
    "Separa um pedaco de uma string, comecando pela direita.",
    "RIGHT$ (string, numero de caracteres que serao destacados)",
    "PRINT RIGHT$(" + MSXQ + "AGUARDENTE" + MSXQ + ",7)",
    "A funcao RIGHT$ destaca um certo numero de caracteres de uma string. No exemplo acima, o " +
    "resultado sera a palavra ARDENTE, pois ela e formada pelos sete ultimos caracteres de " +
    "AGUARDENTE.",
    "10 REM PROGRAMA RIGHT$" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 INPUT " + MSXQ + " ESCREVA UMA PALAVRA" + MSXQ + ";W$: PRINT" + #CRLF$ +
    "40 PRINT " + MSXQ + "A ULTIMA LETRA E'..." + MSXQ + ";RIGHT$(W$,1): PRINT",
    137)

  MSXDict_Add("RND", #True, #False, "(random)",
    "Escolhe um valor aleatorio entre 0 e 1.",
    "RND (X)",
    "PRINT RND(1)",
    "A funcao RND tem como finalidade gerar um numero pseudo-aleatorio entre 0 e 1. O valor de X " +
    "varia da seguinte maneira: se X e positivo retorna um valor diferente cada vez que e usado; " +
    "se X e negativo o valor retornado e sempre o mesmo para cada X negativo; se X e igual a 0 " +
    "retornara o ultimo numero aleatorio gerado. Para que esta funcao gere um numero realmente " +
    "aleatorio, deve-se usar (-TIME) como argumento.",
    "10 REM PROGRAMA RND" + #CRLF$ +
    "20 SCREEN 2" + #CRLF$ +
    "30 FOR F=0 TO 100" + #CRLF$ +
    "40 X=256*RND(1):Y=192*RND(2)" + #CRLF$ +
    "50 CIRCLE(X,Y),1" + #CRLF$ +
    "60 NEXT F" + #CRLF$ +
    "70 GOTO 70",
    138)

  MSXDict_Add("RUN", #False, #False, "(run)",
    "Inicia a execucao de um programa a partir de uma linha especificada.",
    "RUN [numero de linha]",
    "RUN 500",
    "O comando RUN zera todas as variaveis e da inicio a execucao do programa que esta na " +
    "memoria. O numero de linha pode ser qualquer inteiro entre 0 e 65529 e, se for omitido, o " +
    "programa comecara a ser executado a partir da primeira linha existente. Para parar a " +
    "execucao tecle STOP. Para continuar tecle STOP novamente. Para interromper definitivamente a " +
    "execucao tecle CTRL + STOP. Por exemplo:" + #CRLF$ + #CRLF$ +
    "RUN" + #CRLF$ + #CRLF$ +
    "inicia a execucao a partir da primeira linha do programa e" + #CRLF$ + #CRLF$ +
    "RUN 30" + #CRLF$ + #CRLF$ +
    "inicia a execucao a partir da linha 30 do programa.",
    "10 ' RUN" + #CRLF$ +
    "20 A%=7*RND(-TIME):B%=7*RND(-TIME)" + #CRLF$ +
    "30 CLS:LOCATE6,10" + #CRLF$ +
    "40 PRINT" + MSXQ + "Digite a barra de espacos." + MSXQ + #CRLF$ +
    "50 IFSTRIG(0)=0THENLOCATE5,5:GOTO20" + #CRLF$ +
    "60 PRINT:PRINT:PRINT" + MSXQ + "Dado 1:" + MSXQ + ";A%" + #CRLF$ +
    "70 PRINT" + MSXQ + "Dado 2:" + MSXQ + ";B%:PRINT:PRINT" + #CRLF$ +
    "80 PRINT" + MSXQ + "Digite RETURN para novo lancamento." + MSXQ + #CRLF$ +
    "90 LINE INPUT O$" + #CRLF$ +
    "100 RUN",
    139)
EndProcedure

; --- Letra S (pagina 140-163 do livro = pagina 137-160 do PDF) ---
Procedure MSXDict_BuildLetterS()
  MSXDict_Add("SAVE", #False, #True, "(save)",
    "Armazena, em um dispositivo especificado, um programa em BASIC.",
    "SAVE" + MSXQ + "[nome do dispositivo] [nome do arquivo]" + MSXQ + " [,A]",
    "SAVE" + MSXQ + "CAS:BROCHE" + MSXQ,
    "Armazena o programa em BASIC que esta na memoria do computador no dispositivo especificado." + #CRLF$ + #CRLF$ +
    "Os dispositivos sao:" + #CRLF$ + #CRLF$ +
    "Impressora .....................LPT:" + #CRLF$ +
    "Cassete ........................CAS:" + #CRLF$ +
    "Tela modo grafico...............GRP:" + #CRLF$ +
    "Tela modo texto.................CRT:" + #CRLF$ + #CRLF$ +
    "Nota: o nome de arquivo nao pode exceder seis caracteres (os excedentes nao serao " +
    "considerados). Por exemplo:" + #CRLF$ + #CRLF$ +
    "SAVE" + MSXQ + "CAS:PROGRA" + MSXQ + #CRLF$ + #CRLF$ +
    "armazena no gravador o programa em BASIC e" + #CRLF$ + #CRLF$ +
    "SAVE" + MSXQ + "CRT:" + MSXQ + #CRLF$ + #CRLF$ +
    "coloca o programa em BASIC na tela de texto.",
    "",
    140)

  ; Tabelas de MODO/TAMANHO DO SPRITE/etc representadas como listas (mesma
  ; convencao ja usada em BASE/COLOR/DRAW).
  MSXDict_Add("SCREEN", #False, #False, "(screen)",
    "Determina: tipo de tela, tamanho do sprite, o " + MSXQ + "liga/desliga" + MSXQ + " do clic " +
    "das teclas, velocidade de transferencia de dados para o cassete e seleciona o tipo de " +
    "impressora.",
    "SCREEN [modo], [tamanho do sprite]," + #CRLF$ +
    "[interruptor de clic das teclas]," + #CRLF$ +
    "[velocidade em bauds], [tipo de impressora]",
    "SCREEN 1,,0,2",
    "Formata a tela, o sprite, o clic das teclas, determina a velocidade de transferencia de " +
    "dados para o cassete e especifica o tipo de impressora." + #CRLF$ + #CRLF$ +
    "MODO:" + #CRLF$ +
    "- *0 - texto, 40 caracteres x 24 linhas" + #CRLF$ +
    "- 1 - texto, 32 caracteres x 24 linhas" + #CRLF$ +
    "- 2 - grafico alta resolucao" + #CRLF$ +
    "- 3 - grafico colorido" + #CRLF$ + #CRLF$ +
    "TAMANHO DO SPRITE:" + #CRLF$ +
    "- *0 - 8 x 8 sem ampliar" + #CRLF$ +
    "- 1 - 8 x 8 ampliado" + #CRLF$ +
    "- 2 - 16 x 16 sem ampliar" + #CRLF$ +
    "- 3 - 16 x 16 ampliado" + #CRLF$ + #CRLF$ +
    "INTERRUPTOR DO CLIC DAS TECLAS:" + #CRLF$ +
    "- 0 - desligado" + #CRLF$ +
    "- *1 ou qualquer outro valor - ligado" + #CRLF$ + #CRLF$ +
    "VELOCIDADE DE TRANSFERENCIA:" + #CRLF$ +
    "- *1 - 1200 Bauds" + #CRLF$ +
    "- 2 - 2400 Bauds" + #CRLF$ + #CRLF$ +
    "IMPRESSORA:" + #CRLF$ +
    "- *0 - Padrao ABNT" + #CRLF$ +
    "- 1 ou qualquer outro valor - outra impressora" + #CRLF$ + #CRLF$ +
    "Nota: Os asteriscos indicam os valores iniciais. Se qualquer uma das opcoes for omitida, " +
    "permanecem os valores atuais." + #CRLF$ + #CRLF$ +
    "No exemplo anterior, a instrucao SCREEN determina modo de 32 caracteres por 24 linhas, clic " +
    "das teclas desligado e velocidade de transferencia de dados para o cassete de 2400 bauds.",
    "20 A$=" + MSXQ + "01234567890123456789012345678901234567890123456789" + MSXQ + #CRLF$ +
    "30 SCREEN 0:PRINT A$" + #CRLF$ +
    "40 FOR F=1 TO 1000 : NEXT F" + #CRLF$ +
    "50 SCREEN 1:PRINT A$" + #CRLF$ +
    "60 FOR F=1 TO 1000 : NEXT F" + #CRLF$ +
    "70 SCREEN 2:LINE(9,9)-(99,99),3,BF" + #CRLF$ +
    "80 FOR F=1 TO 1000 : NEXT F" + #CRLF$ +
    "90 SCREEN 3:LINE(9,9)-(99,99),3,BF" + #CRLF$ +
    "100 FOR F=1 TO 1000 : NEXT F",
    141)

  MSXDict_Add("SGN", #True, #False, "(sign)",
    "Verifica o sinal de um numero ou expressao.",
    "SGN (expressao)",
    "PRINT SGN(-10)",
    "A funcao SGN verifica o sinal de um numero da seguinte maneira: se o numero for positivo o " +
    "valor fornecido por SGN sera igual a 1; se o numero for negativo, -1 e, se for igual a zero, " +
    "retornara o proprio valor zero.",
    "10 REM PROGRAMA SGN" + #CRLF$ +
    "20 A=34" + #CRLF$ +
    "30 B=0" + #CRLF$ +
    "40 C=-345" + #CRLF$ +
    "50 PRINT A,SGN(A)" + #CRLF$ +
    "60 PRINT B,SGN(B)" + #CRLF$ +
    "70 PRINT C,SGN(C)",
    142)

  MSXDict_Add("SIN", #True, #False, "(sinus)",
    "Calcula o valor do seno de um angulo.",
    "SIN (angulo)",
    "PRINT SIN(1.234)",
    "A funcao SIN calcula o seno de um angulo fornecido pelo usuario. E importante lembrar que o " +
    "computador trabalha com o angulo em radianos. Caso voce queira calcular o seno de um angulo " +
    "em graus digite da seguinte maneira:" + #CRLF$ +
    "PRINT SIN(angulo*3.1415927/180)",
    "10 REM PROGRAMA SIN" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 SCREEN 2" + #CRLF$ +
    "40 FOR F=0 TO 255 STEP .5" + #CRLF$ +
    "50 PSET(F,80-70*SIN(F*6.141592#/255))" + #CRLF$ +
    "60 NEXT F" + #CRLF$ +
    "70 GOTO 70",
    143)

  ; SOUND ocupa 7 paginas (144-150): tabela de registros, notas (a)-(j)
  ; com sub-programas, tabela de formas de envelope e um diagrama de
  ; blocos + tabela de bits na pagina 150 (nao reproduzidos aqui, so
  ; descritos onde relevante) - a maior entrada do dicionario ate agora.
  MSXDict_Add("SOUND", #False, #False, "(sound)",
    "Escreve dados diretamente nos registros do PSG (gerador de som programavel).",
    "SOUND numero de registro, expressao",
    "SOUND 7,8",
    "Gerar som programando diretamente os registros do PSG. O PSG dispoe de 3 canais que podem " +
    "gerar tons com a frequencia desejada pelo usuario. E tambem possivel aplicar ruido a todos " +
    "esses canais, controlar os envelopes (variacao de volume durante a geracao de um tom) e a " +
    "duracao de cada nota em cada um dos canais. Em outras palavras, podem ser criados acordes " +
    "triplos e ruido. O PSG possui 16 registros. Veja na tabela as funcoes de cada um (os " +
    "registros 14 e 15 nao sao utilizados para a composicao musical). No comando:" + #CRLF$ +
    "SOUND numero de registro, expressao" + #CRLF$ +
    "o numero de registro deve ser um inteiro entre 0 e 13. As expressoes tambem sao inteiras e " +
    "devem obedecer aos limites estabelecidos na tabela." + #CRLF$ + #CRLF$ +
    "Um registro e um " + MSXQ + "lugar" + MSXQ + " no PSG onde se armazenam temporariamente dados para o " +
    "processamento. Variando o dado em um registro, modifica-se o som produzido." + #CRLF$ + #CRLF$ +
    "TABELA DE REGISTROS:" + #CRLF$ +
    "- 0/1 (0 a 255 / 0 a 15): Determinam a frequencia do canal A (a)" + #CRLF$ +
    "- 2/3 (0 a 255 / 0 a 15): Determinam a frequencia do canal B (b)" + #CRLF$ +
    "- 4/5 (0 a 255 / 0 a 15): Determinam a frequencia do canal C (c)" + #CRLF$ +
    "- 6 (0 a 31): Determina a frequencia do ruido (d)" + #CRLF$ +
    "- 7 (0 a 63): Seleciona um canal para geracao de tons e ruidos (e)" + #CRLF$ +
    "- 8 (0 a 15): Volume do canal A * (f)" + #CRLF$ +
    "- 9 (0 a 15): Volume do canal B * (g)" + #CRLF$ +
    "- 10 (0 a 15): Volume do canal C * (h)" + #CRLF$ +
    "- 11/12 (0 a 255 / 0 a 255): Frequencia do gerador de envelope (i)" + #CRLF$ +
    "- 13 (0 a 14): Selecao da forma do envelope (j)" + #CRLF$ + #CRLF$ +
    "* Nota: So pode haver geracao de envelope se o registro de volume do canal for programado " +
    "com o valor 16." + #CRLF$ + #CRLF$ +
    "NOTAS:" + #CRLF$ + #CRLF$ +
    "(a),(b),(c) - Para determinar os valores dos registros para uma determinada frequencia, use " +
    "este programa:" + #CRLF$ +
    "10 ' Para R0 ate R5" + #CRLF$ +
    "20 INPUT" + MSXQ + "Qual a frequencia" + MSXQ + ";F" + #CRLF$ +
    "30 A=3575611#/8192/F" + #CRLF$ +
    "40 H=INT(A)" + #CRLF$ +
    "50 L=INT(.5+256*(A-H))" + #CRLF$ +
    "60 PRINT" + MSXQ + "Alto (impar)=" + MSXQ + ";H," + MSXQ + "Baixo (par)=" + MSXQ + ";L" + #CRLF$ + #CRLF$ +
    "O valor de H deve ser colocado nos registros impares (1 para o canal A, 3 para o canal B e " +
    "5 para o canal C) e o valor L deve ser colocado nos registros pares (0 para o canal A, 2 " +
    "para o canal B e 4 para o canal C). Por exemplo, imagine que voce quer programar o canal A " +
    "com uma frequencia de 1000 Hz. Rode o programa e introduza o numero 1000." + #CRLF$ + #CRLF$ +
    "RUN" + #CRLF$ +
    "Qual a frequencia? 1000" + #CRLF$ +
    "Alto (impar)= 0" + #CRLF$ +
    "Baixo (par)= 112" + #CRLF$ +
    "Ok" + #CRLF$ + #CRLF$ +
    "Portanto, devemos fazer:" + #CRLF$ +
    "SOUND 0,112" + #CRLF$ +
    "SOUND 1,0" + #CRLF$ + #CRLF$ +
    "(d) - Para programar a frequencia do ruido use o programa:" + #CRLF$ +
    "10 INPUT" + MSXQ + "Qual a frequencia do ruido" + MSXQ + ";F" + #CRLF$ +
    "20 R6=3575611#/32/F" + #CRLF$ +
    "30 PRINT" + MSXQ + "O valor a ser atribuido ao registro" + MSXQ + "," + MSXQ + "6 e':" + MSXQ + ";INT(R6+.5)" + #CRLF$ + #CRLF$ +
    "RUN" + #CRLF$ +
    "Qual a frequencia do ruido? 9600" + #CRLF$ +
    "O valor a ser atribuido ao registro 6 e': 12" + #CRLF$ + #CRLF$ +
    "Portanto fazendo:" + #CRLF$ +
    "SOUND 6,12" + #CRLF$ + #CRLF$ +
    "Teremos um ruido de aproximadamente 9600 Hz." + #CRLF$ + #CRLF$ +
    "(e) - Apenas com as instrucoes anteriores o PSG ainda nao pode produzir som. E preciso " +
    "determinar o volume (veremos a seguir) e habilitar a saida do canal que se esta " +
    "programando. Para especificar o canal utilize a tabela:" + #CRLF$ + #CRLF$ +
    "SOM: canal A=1, canal B=2, canal C=4" + #CRLF$ +
    "RUIDO: canal A=8, canal B=16, canal C=32" + #CRLF$ + #CRLF$ +
    "Para programar o registro 7 deve-se somar os valores correspondentes as saidas desejadas e " +
    "subtrair esse total de 255. Por exemplo: para selecionar so o canal A, o valor e 1. " +
    "Subtraindo temos:" + #CRLF$ +
    "255 - 1 = 254" + #CRLF$ + #CRLF$ +
    "Portanto, para selecionar o canal A fazemos:" + #CRLF$ +
    "SOUND 7,254" + #CRLF$ + #CRLF$ +
    "Se quisessemos selecionar os canais A e B para produzir som e A, B e C para produzir ruido, " +
    "teriamos:" + #CRLF$ +
    "255 - (1+2+8+16+32) = 196" + #CRLF$ + #CRLF$ +
    "Portanto:" + #CRLF$ +
    "SOUND 7,196" + #CRLF$ + #CRLF$ +
    "(f),(g),(h) - Ha 16 niveis de volume (0 a 15). Para programar o volume do canal A, fazemos:" + #CRLF$ +
    "SOUND 8,15    Volume maximo no canal A" + #CRLF$ + #CRLF$ +
    "Para os outros canais o procedimento e semelhante, bastando mudar o numero do registro (9 " +
    "para o canal B, 10 para o canal C). Para utilizar o gerador de envelope (veremos a seguir) " +
    "os registros escolhidos devem ser carregados com o valor 16." + #CRLF$ + #CRLF$ +
    "(i) - Os registros 11 e 12 determinam a frequencia do envelope (variacao de volume durante " +
    "a producao de um tom). Para obter o valor destes registros utilize este programa:" + #CRLF$ +
    "10 ' Para R11 e R12" + #CRLF$ +
    "20 INPUT" + MSXQ + "Qual a frequencia" + MSXQ + ";F" + #CRLF$ +
    "30 A=3575611#/131072!/F" + #CRLF$ +
    "40 H=INT(A)" + #CRLF$ +
    "50 L=INT(.5+256*(A-H))" + #CRLF$ +
    "60 PRINT" + MSXQ + "Alto (12)=" + MSXQ + ";H" + #CRLF$ +
    "70 PRINT" + MSXQ + "Baixo (11)=" + MSXQ + ";L" + #CRLF$ + #CRLF$ +
    "Execute-o, digitando:" + #CRLF$ +
    "RUN" + #CRLF$ + #CRLF$ +
    "Na tela, deverao surgir as mensagens:" + #CRLF$ +
    "RUN" + #CRLF$ +
    "Qual a frequencia? 16" + #CRLF$ +
    "Alto (12)= 1" + #CRLF$ +
    "Baixo (11)= 180" + #CRLF$ +
    "Ok" + #CRLF$ + #CRLF$ +
    "Portanto, para obter uma frequencia de envelope de 16 Hz no canal A devemos fazer:" + #CRLF$ +
    "SOUND 8,16     deixa o canal A sob o controle do gerador de envelope" + #CRLF$ +
    "SOUND 11,180" + #CRLF$ +
    "SOUND 12,1     frequencia do envelope" + #CRLF$ + #CRLF$ +
    "(j) - Varios envelopes podem ser selecionados para modular a(s) nota(s) emitida(s). O valor " +
    "atribuido ao registro 13 seleciona a forma do envelope, entre 8 formatos possiveis " +
    "representados graficamente no livro (mesma tabela e mesmos valores do subcomando Sn da " +
    "funcao PLAY):" + #CRLF$ +
    "- 0, 1, 2, 3 ou 9" + #CRLF$ +
    "- 4, 5, 6, 7 ou 15" + #CRLF$ +
    "- 8" + #CRLF$ +
    "- 10" + #CRLF$ +
    "- 11" + #CRLF$ +
    "- 12" + #CRLF$ +
    "- 13" + #CRLF$ +
    "- 14" + #CRLF$ + #CRLF$ +
    "(As formas exatas de cada envelope sao graficos de linha na pagina 148 do livro, nao " +
    "reproduzidos aqui.)",
    "100 CLS" + #CRLF$ +
    "110 PRINT" + MSXQ + "HISTORIA (INACABADA) DA AVIACAO" + MSXQ + #CRLF$ +
    "120 SOUND 6,12" + #CRLF$ +
    "130 SOUND 7,246" + #CRLF$ +
    "140 SOUND 0,93" + #CRLF$ +
    "150 SOUND 1,4" + #CRLF$ +
    "160 FOR V = 0 TO 16" + #CRLF$ +
    "170 FOR T = 0 TO 250:NEXT T" + #CRLF$ +
    "180 SOUND 8,V" + #CRLF$ +
    "190 NEXT V" + #CRLF$ +
    "200 SOUND 11,180" + #CRLF$ +
    "210 SOUND 12,1" + #CRLF$ +
    "220 SOUND 13,14" + #CRLF$ +
    "230 FOR T = 0 TO 1000:NEXT T" + #CRLF$ +
    "240 SOUND 1,0" + #CRLF$ +
    "250 SOUND 7,254" + #CRLF$ +
    "260 SOUND 8,15" + #CRLF$ +
    "270 FOR X = 255 TO 0 STEP -1" + #CRLF$ +
    "280 SOUND 0,X" + #CRLF$ +
    "290 NEXT X" + #CRLF$ +
    "300 SOUND 0,232" + #CRLF$ +
    "310 SOUND 1,8" + #CRLF$ +
    "320 SOUND 7,246" + #CRLF$ +
    "330 FOR T = 0 TO 50:NEXT T" + #CRLF$ +
    "340 SOUND 8,0",
    144)

  MSXDict_Add("SPACE$", #True, #False, "(space dollar)",
    "Obtem uma string com o numero especificado de espacos.",
    "SPACE$(argumento)",
    "A$=SPACE$(25)",
    "Essa funcao cria uma string com o numero de espacos definidos pelo argumento colocado entre " +
    "parenteses a sua frente. O argumento pode ser uma constante, uma variavel simples ou " +
    "indexada, ou uma expressao matematica, desde que o resultado seja um numero entre 0 e 255. " +
    "Se o resultado for fracionario os digitos a direita da virgula (ponto decimal) sao ignorados.",
    "10 REM PROG. SPACE$" + #CRLF$ +
    "20 FOR F=1 TO 22" + #CRLF$ +
    "30 A$=SPACE$(F)" + #CRLF$ +
    "40 PRINTA$;" + MSXQ + "ALEPH" + MSXQ + #CRLF$ +
    "50 NEXT F",
    151)

  MSXDict_Add("SPC", #True, #False, "(space)",
    "Obtem um certo numero de espacos.",
    "SPC(numero)",
    "SPC(21)",
    "Essa funcao deve ser usada com as instrucoes PRINT ou LPRINT e serve para inserir espacos " +
    "entre expressoes a serem apresentadas.",
    "10 REM PROGRAMA SPC" + #CRLF$ +
    "20 PRINT" + MSXQ + "GRADIENTE" + MSXQ + ";SPC(25);" + MSXQ + "ALEPH" + MSXQ,
    152)

  MSXDict_Add("SPRITE ON/OFF/STOP", #False, #False, "(sprite on/off/stop)",
    "Estas tres funcoes respectivamente, habilitam, desabilitam e adiam um desvio para uma " +
    "interrupcao por sobreposicao.",
    "SPRITE ON" + #CRLF$ + "SPRITE OFF" + #CRLF$ + "SPRITE STOP",
    "SPRITE ON" + #CRLF$ + "SPRITE OFF" + #CRLF$ + "SPRITE STOP",
    "A instrucao SPRITE ON habilita uma interrupcao por sobreposicao de figuras na tela caso " +
    "exista uma instrucao ON SPRITE GOSUB. A instrucao SPRITE OFF desabilita (ou desliga) a " +
    "funcao do SPRITE ON. Finalmente a instrucao SPRITE STOP adia a interrupcao ate que seja " +
    "encontrada uma instrucao SPRITE ON.",
    "10 REM PROGRAMA SPRITE ON/OFF/STOP" + #CRLF$ +
    "20 SCREEN 2,1" + #CRLF$ +
    "30 SPRITE$(0)=CHR$(&H3C)+CHR$(&H7E)+CHR$(&H81)+CHR$(&H81)+CHR$(&HFF)+CHR$(&H7E)+CHR$(&H24)+CHR$(&H42)" + #CRLF$ +
    "40 ON SPRITE GOSUB 110" + #CRLF$ +
    "50 SPRITE ON" + #CRLF$ +
    "60 FOR X=0 TO 255" + #CRLF$ +
    "70 PUT SPRITE 0,(X,100),8,0" + #CRLF$ +
    "80 PUT SPRITE 1,(255-X,100),10,0" + #CRLF$ +
    "90 NEXT X" + #CRLF$ +
    "100 GOTO 40" + #CRLF$ +
    "110 SPRITE OFF" + #CRLF$ +
    "120 BEEP" + #CRLF$ +
    "130 SPRITE ON" + #CRLF$ +
    "140 RETURN",
    153)

  MSXDict_Add("SPRITE$", #False, #False, "(sprite dollar)",
    "Define os dados de um " + MSXQ + "sprite" + MSXQ + ".",
    "SPRITE$ (numero de sprite) = string",
    "SPRITE$(31)=A$",
    "Definir sprites. O numero do sprite pode estar entre 0 e 255 se ele for de 8x8 pontos e de " +
    "0 a 63 se ele for de 16 por 16 pontos. O tamanho do sprite e o tamanho de cada pixel devem " +
    "ser definidos por uma instrucao SCREEN.",
    "10 ' SPRITE's" + #CRLF$ +
    "20 FORE=0TO3:D=E+1:KEYOFF" + #CRLF$ +
    "30 SCREEN 1,E:DIM S$(4)" + #CRLF$ +
    "40 LOCATE 4,2:PRINT" + MSXQ + "SCREEN 1 ," + MSXQ + ";E:LOCATE8,6:PRINT" + MSXQ + "<-SPRITE 5" + MSXQ + #CRLF$ +
    "50 FOR G= 1 TO 4" + #CRLF$ +
    "60 FOR F=1 TO 8" + #CRLF$ +
    "70 READ K$" + #CRLF$ +
    "80 S$(G)=S$(G)+CHR$(VAL(" + MSXQ + "&H" + MSXQ + "+K$))" + #CRLF$ +
    "90 NEXT F" + #CRLF$ +
    "100 NEXT G" + #CRLF$ +
    "110 SPRITE$(1)=S$(1)" + #CRLF$ +
    "120 SPRITE$(2)=S$(2)" + #CRLF$ +
    "130 SPRITE$(3)=S$(3)" + #CRLF$ +
    "140 SPRITE$(4)=S$(4)" + #CRLF$ +
    "150 SPRITE$(5)=S$(1)+S$(2)+S$(3)+S$(4)" + #CRLF$ +
    "160 PUT SPRITE 1,(90,90),3,1" + #CRLF$ +
    "170 PUT SPRITE 2,(90,90+8*D),4,2" + #CRLF$ +
    "180 PUT SPRITE 3,(90+8*D,90),7,3" + #CRLF$ +
    "190 PUT SPRITE 4,(90+8*D,90+8*D),8,4" + #CRLF$ +
    "200 PUT SPRITE 5,(44,44),15,5" + #CRLF$ +
    "205 LOCATE 2,20:PRINT" + MSXQ + "Digite a barra de espacos!" + MSXQ + #CRLF$ +
    "210 IFSTRIG(0)=0THEN210ELSERESTORE:ERASES$" + #CRLF$ +
    "220 NEXTE:RUN" + #CRLF$ +
    "230 DATA FF,89,99,89,89,89,9D,FF" + #CRLF$ +
    "240 DATA FF,99,A5,85,99,A1,BD,FF" + #CRLF$ +
    "250 DATA FF,BD,85,89,85,A5,99,FF" + #CRLF$ +
    "260 DATA FF,A5,A5,A5,BD,85,85,FF",
    154)

  MSXDict_Add("SQR", #True, #False, "(square root)",
    "Fornece o valor da raiz quadrada de um numero dado pelo usuario.",
    "SQR (expressao)",
    "PRINT SQR(16)",
    "A funcao SQR tem por finalidade dar o valor da raiz quadrada do numero entre parenteses. E " +
    "importante salientar que o numero deve ser maior ou igual a zero, caso contrario o " +
    "computador acusara erro.",
    "10 REM PROGRAMA SQR" + #CRLF$ +
    "20 FOR A=1 TO 100" + #CRLF$ +
    "30 PRINT A,SQR(A)" + #CRLF$ +
    "40 NEXT A",
    155)

  MSXDict_Add("STICK", #True, #False, "(stick)",
    "Mostra o estado dos joysticks e das teclas que movem o cursor.",
    "STICK (N)" + #CRLF$ +
    "se N=0 - Teclado" + #CRLF$ +
    "se N=1 - Joystick A" + #CRLF$ +
    "se N=2 - Joystick B",
    "A=STICK(0)",
    "A funcao STICK tem por finalidade mostrar a direcao em que estao se movendo os joysticks e " +
    "as teclas que movem o cursor. A direcao e dada por um esquema numerado de 1 a 8 em torno de " +
    "um centro (0=parado), no sentido horario a partir de cima: 1=cima, 2=cima-direita, " +
    "3=direita, 4=baixo-direita, 5=baixo, 6=baixo-esquerda, 7=esquerda, 8=cima-esquerda.",
    "10 REM PROGRAMA STICK" + #CRLF$ +
    "20 ON ERROR GOTO 30" + #CRLF$ +
    "30 SCREEN 3" + #CRLF$ +
    "40 X=0:Y=0" + #CRLF$ +
    "50 PSET(X,Y),6" + #CRLF$ +
    "60 C=STICK(0)" + #CRLF$ +
    "70 IF C=1THENY=Y-1" + #CRLF$ +
    "80 IF C=2THENY=Y-1:X=X+1" + #CRLF$ +
    "90 IF C=3THENX=X+1" + #CRLF$ +
    "100 IF C=4THENY=Y+1:X=X+1" + #CRLF$ +
    "110 IF C=5THENY=Y+1" + #CRLF$ +
    "120 IF C=6THENY=Y+1:X=X-1" + #CRLF$ +
    "130 IF C=7THENX=X-1" + #CRLF$ +
    "140 IF C=8THENY=Y-1:X=X-1" + #CRLF$ +
    "150 GOTO 50",
    156)

  MSXDict_Add("STOP", #False, #False, "(stop)",
    "Para a execucao do programa.",
    "STOP",
    "STOP",
    "Interrompe a execucao do programa na linha onde se encontra. A execucao do programa pode " +
    "ser continuada digitando-se o comando CONT.",
    "10 REM PROGRAMA STOP" + #CRLF$ +
    "20 WIDTH 40" + #CRLF$ +
    "30 CLS" + #CRLF$ +
    "40 FOR G=1 TO 200" + #CRLF$ +
    "50 CO=RND(1)*40" + #CRLF$ +
    "60 LOCATE CO,23" + #CRLF$ +
    "70 PRINT " + MSXQ + "*" + MSXQ + #CRLF$ +
    "80 FOR F=1 TO 20:NEXT F" + #CRLF$ +
    "90 NEXT G" + #CRLF$ +
    "100 LOCATE 10,23" + #CRLF$ +
    "110 PRINT" + MSXQ + "STOP sera executado" + MSXQ + #CRLF$ +
    "120 FOR F=1 TO 500:NEXT F" + #CRLF$ +
    "130 STOP" + #CRLF$ +
    "140 RUN",
    157)

  MSXDict_Add("STOP ON/OFF/STOP", #False, #False, "(stop on/off/stop)",
    "Permite, proibe ou retem a execucao de uma sub-rotina definida por ON STOP GOSUB mediante a " +
    "digitacao das teclas CONTROL e STOP.",
    "STOP ON" + #CRLF$ + "STOP OFF" + #CRLF$ + "STOP STOP",
    "STOP ON" + #CRLF$ + "STOP OFF" + #CRLF$ + "STOP STOP",
    "Esses comandos permitem, proibem ou retem a execucao de uma sub-rotina especificada por uma " +
    "instrucao ON STOP GOSUB mediante a digitacao simultanea das teclas CONTROL e STOP.",
    "10 REM PROGRAMA STOP" + #CRLF$ +
    "20 STOP ON" + #CRLF$ +
    "30 ON STOP GOSUB 60" + #CRLF$ +
    "40 CLS:PRINT" + MSXQ + "Pressione CTRL + STOP." + MSXQ + #CRLF$ +
    "50 GOTO 50" + #CRLF$ +
    "60 PRINT" + MSXQ + "CTRL + STOP foi pressionado." + MSXQ + #CRLF$ +
    "70 FOR B=1 TO 500:NEXT B" + #CRLF$ +
    "80 C=C+1" + #CRLF$ +
    "90 IF C=5 THEN END" + #CRLF$ +
    "100 RETURN 40",
    158)

  ; CONFERIR: a FUNCAO desta pagina diz "o valor obtido por STICK e 0" -
  ; provavel erro do livro (deveria ser STRIG, ja que e essa a pagina
  ; descrita) - preservado como impresso.
  MSXDict_Add("STRIG", #True, #False, "(stick trigger)",
    "Obtem o estado de toque da barra de espacos e dos disparadores dos joysticks.",
    "STRIG(numero)",
    "STRIG(1)",
    "Essa funcao verifica se a barra de espacos do teclado ou os disparadores dos joysticks " +
    "estao pressionados. O numero que serve como seu argumento pode ser qualquer inteiro entre " +
    "0 e 4 e cada um deles corresponde a um caso especifico." + #CRLF$ + #CRLF$ +
    "0 . . . barra de espacos" + #CRLF$ +
    "1 . . . disparador 1 do joystick 1" + #CRLF$ +
    "2 . . . disparador 1 do joystick 2" + #CRLF$ +
    "3 . . . disparador 2 do joystick 1" + #CRLF$ +
    "4 . . . disparador 2 do joystick 2" + #CRLF$ + #CRLF$ +
    "Se nenhum deles esta pressionado, o valor obtido por STICK e 0, caso contrario o valor " +
    "obtido e -1.",
    "10 REM PROGRAMA STRIG" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 PRINT" + MSXQ + "PRESSIONE A BARRA DE ESPACOS" + MSXQ + #CRLF$ +
    "40 C=0" + #CRLF$ +
    "50 COLOR,C,C" + #CRLF$ +
    "60 IF STRIG(0)=0 THEN GOTO 50" + #CRLF$ +
    "70 C=C+1:IF C=15 THEN C=0" + #CRLF$ +
    "80 GOTO 50",
    159)

  MSXDict_Add("STRIG(n) ON/OFF/STOP", #False, #False, "(strig (n) on/off/stop)",
    "Cada uma dessas tres instrucoes respectivamente habilitam, proibem ou retem uma interrupcao " +
    "mediante o pressionamento da barra de espacos ou de um disparador de um dos joysticks.",
    "STRIG(n) ON" + #CRLF$ + "STRIG(n) OFF" + #CRLF$ + "STRIG(n) STOP",
    "STRIG(0) ON" + #CRLF$ + "STRIG(3) OFF" + #CRLF$ + "STRIG(2) STOP",
    "A instrucao STRIG(n) ON habilita uma interrupcao quando for pressionada a barra de espacos " +
    "ou um dos disparadores dos joysticks; STRIG(n) OFF desabilita a interrupcao e STRIG(n) STOP " +
    "a retem na mesma situacao. A escolha da barra ou de um dos disparadores e feita atraves do " +
    "numero n colocado entre parenteses logo apos STRIG. Esse numero pode estar entre 0 e 4, " +
    "correspondendo em cada caso a um disparador ou a barra de espacos." + #CRLF$ + #CRLF$ +
    "0 . . . barra de espacos" + #CRLF$ +
    "1 . . . disparador 1 do joystick 1" + #CRLF$ +
    "2 . . . disparador 1 do joystick 2" + #CRLF$ +
    "3 . . . disparador 2 do joystick 1" + #CRLF$ +
    "4 . . . disparador 2 do joystick 2",
    "10 REM PROGRAMA STRIG(n) ON/OFF/STOP" + #CRLF$ +
    "20 STRIG(0) ON" + #CRLF$ +
    "30 PRINT" + MSXQ + "DIGITE A BARRA DE ESPACOS" + MSXQ + #CRLF$ +
    "40 ON STRIG GOSUB 80" + #CRLF$ +
    "50 IF C<>6 THEN 40" + #CRLF$ +
    "60 SCREEN 0:PRINT SPC(17);" + MSXQ + "FIM" + MSXQ + ":END" + #CRLF$ +
    "70 GOTO 40" + #CRLF$ +
    "80 SCREEN 2" + #CRLF$ +
    "90 COLOR C+3,C+4,C+5" + #CRLF$ +
    "100 CIRCLE (128,85),50" + #CRLF$ +
    "110 COLOR C+6,C+7,C+8" + #CRLF$ +
    "120 C=C+1:IF C=6 THEN COLOR 15,1,1" + #CRLF$ +
    "130 RETURN",
    160)

  MSXDict_Add("STR$", #True, #False, "(convert to string)",
    "Transforma dados numericos em alfanumericos.",
    "STR$ (expressao numerica)",
    "A$=STR$(X)",
    "A funcao STR$ funciona ao contrario da funcao VAL, ou seja, parte de uma constante ou uma " +
    "variavel numerica e a transforma em alfanumerica (string).",
    "10 REM PROGRAMA STR$" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 A=45" + #CRLF$ +
    "40 B=60" + #CRLF$ +
    "50 A$=STR$(A)" + #CRLF$ +
    "60 B$=STR$(B)" + #CRLF$ +
    "70 PRINT A+B,A$+B$",
    161)

  MSXDict_Add("STRING$", #True, #False, "(string dollar)",
    "Imprime um caractere definido pelo usuario varias vezes.",
    "STRING$ (numero de vezes que o caractere sera repetido, caractere a ser repetido)",
    "PRINT STRING$(30,67)",
    "A funcao STRING$ tem como objetivo imprimir varias vezes um certo caractere. O mesmo pode " +
    "ser impresso ate 255 vezes, ou seja, o primeiro numero entre parenteses pode variar de 0 ate " +
    "255, enquanto o segundo define o codigo do caractere que sera impresso. Para saber o codigo " +
    "do caractere, consulte a tabela de codigos. Pode-se usar STRING$ tambem com uma string ou " +
    "uma variavel alfanumerica, como por exemplo:" + #CRLF$ + #CRLF$ +
    "PRINT STRING$(10," + MSXQ + "A" + MSXQ + ")" + #CRLF$ +
    "PRINT STRING$(19,A$)",
    "10 REM PROGRAMA STRING$" + #CRLF$ +
    "20 A$=" + MSXQ + "###___###" + MSXQ + #CRLF$ +
    "30 B$=" + MSXQ + "GRADIENTE" + MSXQ + #CRLF$ +
    "40 C$=STRING$(25,A$)" + #CRLF$ +
    "50 D$=" + MSXQ + "ALEPH" + MSXQ + #CRLF$ +
    "60 E$=B$+C$+D$" + #CRLF$ +
    "70 PRINT E$",
    162)

  MSXDict_Add("SWAP", #False, #False, "(swap)",
    "Troca o valor de duas variaveis.",
    "SWAP variavel, variavel",
    "SWAP A,B",
    "A instrucao SWAP troca os valores de duas variaveis que podem ser numericas ou " +
    "alfanumericas. E importante notar que so podem ser trocados os valores de variaveis de " +
    "mesmo tipo, ou seja, numerica com numerica e alfanumerica com alfanumerica.",
    "10 REM PROGRAMA SWAP" + #CRLF$ +
    "20 A=12" + #CRLF$ +
    "30 B=24" + #CRLF$ +
    "40 PRINT " + MSXQ + "A=" + MSXQ + ";A," + MSXQ + "B=" + MSXQ + ";B" + #CRLF$ +
    "50 SWAP A,B" + #CRLF$ +
    "60 PRINT " + MSXQ + "A=" + MSXQ + ";A," + MSXQ + "B=" + MSXQ + ";B",
    163)
EndProcedure

; --- Letra T (pagina 164-168 do livro = pagina 161-165 do PDF) ---
Procedure MSXDict_BuildLetterT()
  MSXDict_Add("TAB", #True, #False, "(tab)",
    "Move o cursor para a direita um certo numero de espacos, definido pelo usuario.",
    "TAB (numero de espacos)",
    "PRINT TAB(10);" + MSXQ + "ALEPH" + MSXQ,
    "A finalidade da funcao TAB e tabular o texto que esta sendo impresso tanto na tela quanto na " +
    "impressora. O numero de espacos, que e definido entre parenteses, nao deve exceder 255.",
    "10 REM PROGRAMA TAB" + #CRLF$ +
    "20 FOR A=1 TO 20" + #CRLF$ +
    "30 PRINT TAB(A);A" + #CRLF$ +
    "40 NEXT A",
    164)

  MSXDict_Add("TAN", #True, #False, "(tangent)",
    "Calcula o valor da tangente de um angulo.",
    "TAN (angulo)",
    "PRINT TAN(35)",
    "A funcao TAN calcula a tangente de um angulo fornecido pelo usuario. E importante lembrar " +
    "que o computador trabalha com o angulo em radianos. Caso voce queira calcular a tangente de " +
    "um angulo em graus digite da seguinte maneira:" + #CRLF$ +
    "PRINT TAN(angulo*3.1415927/180)",
    "10 REM PROGRAMA TAN" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 SCREEN 2" + #CRLF$ +
    "40 FOR F=0 TO 255 STEP .5" + #CRLF$ +
    "50 PSET(F,80-70*TAN((F+127)*6.1432#/255))" + #CRLF$ +
    "60 NEXT F" + #CRLF$ +
    "70 GOTO 70",
    165)

  MSXDict_Add("TIME", #False, #False, "(time)",
    "Determina o valor do temporizador interno.",
    "TIME" + #CRLF$ + "TIME = expressao",
    "TIME=0",
    "Enquanto o BASIC estiver acionado, o valor de TIME e incrementado em uma unidade a cada " +
    "1/60 de segundo aproximadamente. Ao atingir 65535, TIME voltara a zero e recomecara a " +
    "contagem. O valor de TIME pode ser modificado a qualquer momento utilizando-se um comando " +
    "LET. A expressao pode ser uma constante, variavel (indexada ou numerica) ou suas " +
    "expressoes." + #CRLF$ + #CRLF$ +
    "NOTA: O temporizador para quando o processador realiza algumas operacoes de entrada/saida. " +
    "Por exemplo, durante a gravacao ou leitura de dados no cassete.",
    "10 ' Relogio" + #CRLF$ +
    "20 INPUT " + MSXQ + "Horas" + MSXQ + ";H" + #CRLF$ +
    "30 INPUT " + MSXQ + "Minutos" + MSXQ + ";M" + #CRLF$ +
    "40 INPUT " + MSXQ + "Segundos" + MSXQ + ";S" + #CRLF$ +
    "50 CLS" + #CRLF$ +
    "60 ON INTERVAL=60 GOSUB 90" + #CRLF$ +
    "70 INTERVAL ON" + #CRLF$ +
    "80 GOTO 80" + #CRLF$ +
    "90 LOCATE 12,10" + #CRLF$ +
    "100 S=S+1" + #CRLF$ +
    "110 IF S=60 THEN M=M+1:S=0" + #CRLF$ +
    "120 IF M=60 THEN H=H+1:M=0" + #CRLF$ +
    "130 IF H=24 THEN H=0" + #CRLF$ +
    "140 PRINT USING" + MSXQ + "##:##:##" + MSXQ + ";H;M;S" + #CRLF$ +
    "150 RETURN",
    166)

  MSXDict_Add("TROFF", #False, #False, "(trace off)",
    "Desliga o funcionamento do comando TRON.",
    "TROFF",
    "TROFF",
    "Depois de dado o comando TROFF, nao mais aparecerao os numeros das linhas que estao sendo " +
    "executadas, ou seja, e desativado o comando TRON.",
    "10 REM PROGRAMA TROFF" + #CRLF$ +
    "20 TRON" + #CRLF$ +
    "30 FOR F=1 TO 40" + #CRLF$ +
    "40 PRINT" + MSXQ + "............................." + MSXQ + #CRLF$ +
    "50 NEXT F" + #CRLF$ +
    "60 TROFF" + #CRLF$ +
    "70 FOR F=1 TO 40" + #CRLF$ +
    "80 PRINT" + MSXQ + "............................." + MSXQ + #CRLF$ +
    "90 NEXT F" + #CRLF$ +
    "100 GOTO020",
    167)

  MSXDict_Add("TRON", #False, #False, "(trace on)",
    "Permite visualizar na tela o numero da linha que esta sendo executada.",
    "TRON",
    "TRON",
    "O comando TRON faz com que o numero da linha de programa que esta sendo executada apareca " +
    "na tela entre colchetes. O TRON e muito util na correcao de programas. E importante lembrar " +
    "que os numeros das linhas executadas so aparecem no modo de texto. Nas telas graficas eles " +
    "nao aparecerao. O comando TRON e desativado pelo comando TROFF.",
    "10 REM PROGRAMA TRON" + #CRLF$ +
    "20 TRON" + #CRLF$ +
    "30 PRINT" + MSXQ + "LINHA 20" + MSXQ + ";" + #CRLF$ +
    "40 PRINT" + MSXQ + "LINHA 30" + MSXQ + ";" + #CRLF$ +
    "50 FOR F=1 TO 350:NEXT F" + #CRLF$ +
    "60 GOTO 30",
    168)
EndProcedure

; --- Letra U (pagina 169 do livro = pagina 166 do PDF) ---
Procedure MSXDict_BuildLetterU()
  MSXDict_Add("USR", #True, #True, "(user)",
    "Fornece o resultado obtido pela execucao de uma rotina em linguagem de maquina, que comeca " +
    "no endereco definido em DEFUSR.",
    "USR [numero da rotina]" + #CRLF$ +
    "(valor a ser transferido)",
    "M=USR1(34)",
    "A funcao USR fornece o resultado obtido apos a execucao de uma rotina em linguagem de " +
    "maquina. Os enderecos de inicio das rotinas sao definidos por DEFUSR. O numero da rotina " +
    "deve ser um inteiro entre 0 e 9 e, quando omitido, assumira o valor 0. O valor a ser " +
    "transferido para a sub-rotina, pode ser expressado por uma constante, uma variavel numerica " +
    "ou entao, por uma variavel numerica indexada. Veja o item SUB-ROTINAS EM LINGUAGEM DE " +
    "MAQUINA na parte 3 deste livro.",
    "10 DATA 3E,41,21,00,00,CD,4D,00,23,E5,D5,11,BF,03,ED,52,D1,E1,38,F1,C9" + #CRLF$ +
    "20 FOR I=0 TO 20" + #CRLF$ +
    "30 READ A$:POKE 60000!+I,VAL(" + MSXQ + "&H" + MSXQ + "+A$)" + #CRLF$ +
    "40 NEXT I" + #CRLF$ +
    "50 SCREEN 0:CLS:PRINT " + MSXQ + "APERTE <RETURN> PARA EXECUTAR" + MSXQ + #CRLF$ +
    "60 INPUT B$" + #CRLF$ +
    "70 DEF USR0=60000!" + #CRLF$ +
    "80 X=USR0 (0)" + #CRLF$ +
    "90 FOR T=1 TO 1000:NEXT T:CLS:END",
    169)
EndProcedure

; --- Letra V (pagina 170-174 do livro = pagina 167-171 do PDF) ---
Procedure MSXDict_BuildLetterV()
  MSXDict_Add("VAL", #True, #False, "(value)",
    "Transforma dados alfanumericos em numericos.",
    "VAL (string ou variavel alfanumerica)",
    "PRINT VAL(" + MSXQ + "10" + MSXQ + ")",
    "A funcao VAL tem por finalidade transformar dados alfanumericos em numericos, sendo que os " +
    "dados alfanumericos podem ser uma string ou mesmo uma variavel alfanumerica. Essa funcao " +
    "ignora caracteres que nao sejam de algarismos.",
    "10 REM PROGRAMA VAL" + #CRLF$ +
    "20 A$=" + MSXQ + "10" + MSXQ + #CRLF$ +
    "30 B$=" + MSXQ + "A55" + MSXQ + #CRLF$ +
    "40 C$=" + MSXQ + "55A" + MSXQ + #CRLF$ +
    "50 PRINT A$,VAL(A$)" + #CRLF$ +
    "60 PRINT B$,VAL(B$)" + #CRLF$ +
    "70 PRINT C$,VAL(C$)",
    170)

  MSXDict_Add("VARPTR", #True, #False, "(variable pointer)",
    "Obtem o endereco do byte a partir do qual esta armazenado o conteudo de uma variavel.",
    "VARPTR(variavel)",
    "VARPTR(A$)",
    "Essa funcao obtem o endereco do primeiro byte a partir do qual esta armazenado o conteudo " +
    "de uma variavel, que pode ser numerica, string ou indexada. O valor obtido pode estar entre " +
    "-32768 e 32767. Se o valor e negativo deve-se acrescentar 65536 a ele para obter o endereco.",
    "10 REM PROGRAMA VARPTR" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 PRINT" + MSXQ + "ESTE PROGRAMA MOSTRA COMO A VARIAVEL YX ESTA ARMAZENADA NA MEMORIA DO EXPERT." + MSXQ + #CRLF$ +
    "40 YX=124" + #CRLF$ +
    "50 C=VARPTR(YX)" + #CRLF$ +
    "60 FOR F=C-3 TO C+7" + #CRLF$ +
    "70 PRINT F;" + MSXQ + "..." + MSXQ + ";PEEK(F);" + MSXQ + "..." + MSXQ + ";CHR$(PEEK(F));" + MSXQ + "..." + MSXQ + #CRLF$ +
    "80 NEXT F",
    171)

  MSXDict_Add("VDP", #False, #True, "(video display processor)",
    "Le e insere dados diretamente nos registros do VDP.",
    "VDP(registro)" + #CRLF$ + "VDP(registro)=expressao",
    "VDP(7)=123",
    "Esse comando le ou escreve dados nos registros do VDP, responsavel pelo gerenciamento da " +
    "tela do MSX. O registro e especificado por um numero inteiro entre 0 e 8 e a expressao pode " +
    "ser uma constante, uma variavel simples ou indexada que resulte um numero inteiro entre 0 e " +
    "255.",
    "10 SCREEN0:LOCATE7,10:PRINT" + MSXQ + "Pressione a barra de espaco" + MSXQ + #CRLF$ +
    "20 FOR I=0 TO 255" + #CRLF$ +
    "30 IF STRIG(0)=0 THEN 30" + #CRLF$ +
    "40 VDP(7)=I" + #CRLF$ +
    "50 NEXT I" + #CRLF$ +
    "60 RUN",
    172)

  MSXDict_Add("VPEEK", #False, #True, "(video ram peek)",
    "Le o byte armazenado no endereco especificado na RAM de video.",
    "VPEEK (endereco)",
    "PRINT VPEEK(1234)",
    "Obter o valor do byte armazenado em determinado endereco da RAM de video. Esse endereco " +
    "deve ser indicado por inteiros entre 0 e 16383. O endereco de cada tabela pode ser " +
    "encontrado com a funcao BASE.",
    "10 REM PROGRAMA VPEEK" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 PRINT" + MSXQ + "ABBCCCDDDDEEEEEFFFFFFGGGGGGGHHHHHHHHIIIIIIIIIJJJJJJJJJJ" + MSXQ + #CRLF$ +
    "40 FOR F=1 TO 55" + #CRLF$ +
    "50 PRINT VPEEK(F);" + MSXQ + "..." + MSXQ + ";" + #CRLF$ +
    "60 NEXT F",
    173)

  MSXDict_Add("VPOKE", #False, #True, "(video RAM poke)",
    "Insere dados num dado byte da VRAM (RAM de video).",
    "VPOKE endereco,dado",
    "VPOKE 929,255",
    "Esse comando insere um dado num byte da VRAM, controlada pelo VDP. O endereco pode estar " +
    "entre 0 e 16383 e o dado pode estar entre 0 e 255.",
    "10 REM PROGRAMA VPOKE" + #CRLF$ +
    "20 CLS" + #CRLF$ +
    "30 FOR F=0 TO 255" + #CRLF$ +
    "40 VPOKE F,F" + #CRLF$ +
    "50 NEXT F" + #CRLF$ +
    "60 FOR F=1 TO 1000:NEXT F" + #CRLF$ +
    "70 CLS" + #CRLF$ +
    "80 LIST",
    174)
EndProcedure

; --- Letra W (pagina 175-176 do livro = pagina 172-173 do PDF) - ultima
; letra do dicionario (verbete final: WIDTH). ---
Procedure MSXDict_BuildLetterW()
  MSXDict_Add("WAIT", #False, #True, "(wait)",
    "Espera ate que um certo valor surja na porta de entrada/saida.",
    "WAIT numero da porta de E/S," + #CRLF$ +
    "expressao1, [expressao 2]",
    "WAIT 21,127",
    "Um XOR (ou exclusivo) e executado entre os dados da porta de E/S especificada e o valor da " +
    "expressao 2. Um AND (e) e executado entre o resultado desta operacao e o valor da expressao " +
    "1. Se o resultado final for 0, os dados procedentes da porta de entrada/saida serao " +
    "introduzidos continuamente. As expressoes podem assumir qualquer valor entre 0 e 255. Se a " +
    "expressao 2 for omitida, assumira o valor 0.",
    "",
    175)

  MSXDict_Add("WIDTH", #False, #False, "(width)",
    "Determina o numero de caracteres por linha no modo texto (SCREEN 0 ou 1).",
    "WIDTH (numero de caracteres)",
    "",
    "Pode-se determinar o numero de caracteres por linha na tela do modo texto. No modo texto " +
    "SCREEN 0, o numero de caracteres deve ser um numero inteiro entre 0 e 40. No modo texto " +
    "SCREEN 1, o numero de caracteres deve estar entre 1 e 32. Ao ser ligado, o computador coloca " +
    "40 colunas no SCREEN 0 (29 no SCREEN 1).",
    "10 REM PROGRAMA WIDTH" + #CRLF$ +
    "20 INPUT" + MSXQ + "ESTE PROGRAMA SERA LISTADO ASSIM QUE FOR EXECUTADO. QUANTAS COLUNAS A TELA DEVERA TER" + MSXQ + ";N" + #CRLF$ +
    "30 WIDTH(N)" + #CRLF$ +
    "40 LIST",
    176)
EndProcedure
