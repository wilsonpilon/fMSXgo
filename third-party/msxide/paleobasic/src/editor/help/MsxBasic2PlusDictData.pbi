;
; ------------------------------------------------------------
;  Ajuda -> MSX BASIC...: extensao do dicionario (MsxBasicDictData.pbi)
;  com os comandos do "Manual MSX 2+ FM" (Ademir Carchano / Flavio Monaco,
;  ACVS Eletronica, cartucho MSX2+ FM), digitalizado em
;  docs/manual_msx2fm_acvs.pdf.
;
;  Estrategia (decidida com o usuario): tudo entra na MESMA lista
;  MSXDict_Keywords() do MSX1, nao uma secao separada. Comandos do MSX1
;  que ganham comportamento extra no MSX2+ (SCREEN, COLOR, WIDTH,
;  CIRCLE/DRAW/LINE/PAINT/POINT/PRESET/PSET, PAD, PDL, BASE, VDP, PLAY)
;  viram um segundo verbete "NOME (MSX2+)", inserido logo depois do
;  verbete original (a comparacao alfabetica de string ja garante isso:
;  "SCREEN" < "SCREEN (MSX2+)" < proxima palavra). Comandos totalmente
;  novos (COLOR=, COLORSPRITE, COPY, SETPAGE, CALL MEMINI, os comandos de
;  musica FM tipo CALL MUSIC/CALL VOICE, etc.) sao inseridos na posicao
;  alfabetica correta dentro dessa mesma lista unica, via
;  MSXDict_Add2Plus() (que faz insercao ordenada, ao inves do simples
;  AddElement no fim usado por MSXDict_Add()).
;
;  Campo Sistema.s (adicionado a Structure MSXBasicKeyword em
;  MsxBasicDictData.pbi) marca cada verbete como "MSX1" ou "MSX2+" -
;  MSXDict_Add() grava "MSX1" automaticamente, MSXDict_Add2Plus() grava
;  "MSX2+".
;
;  PaginaLivro.i aqui se refere as paginas do manual ACVS (nao do livro
;  Gradiente) - o titulo do manual/pagina impressa esta em cada comentario
;  de secao abaixo. Offset descoberto: pagina impressa no manual =
;  pagina do PDF - 1 (ex.: capa = PDF 1 sem numero, "Pág. 1" = PDF 2).
;
;  O manual tambem inclui a secao "FM-Music" (sintetizador FM do
;  cartucho) com seus proprios comandos CALL MUSIC/CALL VOICE/etc e uma
;  versao estendida de PLAY - tratados aqui como parte do mesmo
;  dicionario MSX2+, ja que sao instrucoes/funcoes de BASIC de verdade.
;  A prosa dos apendices (programacao de instrumentos, dicas, lista de
;  instrumentos, exemplos de musica) fica em MsxBasicManualData.pbi, nao
;  aqui - ver MSXManual_BuildMSX2Plus().
; ------------------------------------------------------------
;

; Insere um verbete MSX2+ na posicao alfabetica correta dentro da MESMA
; lista MSXDict_Keywords() (nao uma lista separada) - acha o primeiro
; elemento cujo Titulo (maiusculo) e alfabeticamente maior e insere
; ANTES dele (InsertElement cria o novo elemento antes do atual e o
; torna o atual); se nenhum for maior, cai no fim da lista via
; AddElement. Por isso "SCREEN (MSX2+)" cai logo depois de "SCREEN" (a
; string mais curta sempre vem primeiro na comparacao lexicografica).
Procedure MSXDict_Add2Plus(Titulo.s, EhFuncao.b, Avancado.b, Origem.s, Resumo.s, Formato.s, ExemploFormato.s, Funcao.s, ProgramaExemplo.s, PaginaLivro.i)
  Protected Achou.b = #False
  ForEach MSXDict_Keywords()
    If UCase(MSXDict_Keywords()\Titulo) > UCase(Titulo)
      InsertElement(MSXDict_Keywords())
      Achou = #True
      Break
    EndIf
  Next
  If Not Achou
    AddElement(MSXDict_Keywords())
  EndIf
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
  MSXDict_Keywords()\Sistema = "MSX2+"
EndProcedure

Declare MSXDict_BuildMSX2Plus_Screen()
Declare MSXDict_BuildMSX2Plus_Color()
Declare MSXDict_BuildMSX2Plus_Copy()
Declare MSXDict_BuildMSX2Plus_SetPage()
Declare MSXDict_BuildMSX2Plus_Width()
Declare MSXDict_BuildMSX2Plus_Graphics()
Declare MSXDict_BuildMSX2Plus_Clock()
Declare MSXDict_BuildMSX2Plus_Misc()
Declare MSXDict_BuildMSX2Plus_Ramdisk()
Declare MSXDict_BuildMSX2Plus_Input()
Declare MSXDict_BuildMSX2Plus_Vdp()
Declare MSXDict_BuildMSX2Plus_FMBasics()
Declare MSXDict_BuildMSX2Plus_FMControl()

Procedure MSXDict_BuildMSX2Plus()
  MSXDict_BuildMSX2Plus_Screen()
  MSXDict_BuildMSX2Plus_Color()
  MSXDict_BuildMSX2Plus_Copy()
  MSXDict_BuildMSX2Plus_SetPage()
  MSXDict_BuildMSX2Plus_Width()
  MSXDict_BuildMSX2Plus_Graphics()
  MSXDict_BuildMSX2Plus_Clock()
  MSXDict_BuildMSX2Plus_Misc()
  MSXDict_BuildMSX2Plus_Ramdisk()
  MSXDict_BuildMSX2Plus_Input()
  MSXDict_BuildMSX2Plus_Vdp()
  MSXDict_BuildMSX2Plus_FMBasics()
  MSXDict_BuildMSX2Plus_FMControl()
EndProcedure

; --- SCREEN (paginas 7-9 do manual ACVS) ---
Procedure MSXDict_BuildMSX2Plus_Screen()
  MSXDict_Add2Plus("SCREEN (MSX2+)", #False, #False, "(screen)",
    "Define o modo de tela que sera usado, o tamanho dos SPRITES, o chaveamento do CLICK do " +
    "teclado, a velocidade (baud rate) do gravador cassete e o tipo de impressora utilizada - " +
    "versao MSX2+, com os modos de tela 4 a 12 adicionais e sprites multicoloridos.",
    "SCREEN [X [,Y [,Z [,XX [,YY [,ZZ]]]]]]",
    "SCREEN 1,,0,2",
    "X e o modo de tela que sera usado. Podendo ser:" + #CRLF$ +
    "- SCREEN 0 - modo texto 1. Com ate 80 caracteres por linha num maximo de 26.5 linhas. Pode " +
    "assumir ate duas cores, uma para o caractere e outra para a tela de fundo. O numero de " +
    "caracteres e definido pela instrucao WIDTH. As cores sao definidas pelo comando COLOR. Cada " +
    "caractere e montado numa matriz de 6 pontos na horizontal e 8 na vertical." + #CRLF$ + #CRLF$ +
    "- SCREEN 1 - modo texto 2. Com ate 32 caracteres por linha num maximo de 26.5 linhas. " +
    "Trabalha com ate 16 cores de 512 combinacoes e pode ter uma cor para os caracteres, uma " +
    "para o fundo e outra para a borda da tela. A matriz de caracteres e formada por um " +
    "quadrado de 8 por 8 pontos. Usa os SPRITEs no modo 1." + #CRLF$ + #CRLF$ +
    "- SCREEN 2 - modo grafico 1. Com 256 pontos na horizontal por 192 pontos na vertical e 16 " +
    "cores de 512 combinacoes. Podem ser usadas somente duas cores a cada 8 pontos na " +
    "horizontal, na vertical nao ha esta limitacao. Usa os SPRITEs no modo 1." + #CRLF$ + #CRLF$ +
    "- SCREEN 3 - modo grafico 2 - 64 pontos na horizontal por 48 na vertical. Cada ponto e " +
    "formado por um quarto do tamanho normal de um caractere na SCREEN 1. Usa 16 cores de 512 " +
    "combinacoes. Usa os SPRITEs no modo 1." + #CRLF$ + #CRLF$ +
    "- SCREEN 4 - modo grafico 1. Identica a SCREEN 2 so que usa os SPRITEs no modo 2." + #CRLF$ + #CRLF$ +
    "- SCREEN 5 - modo grafico com bit mapeado - resolucao de 256 pontos na horizontal e 212 na " +
    "vertical. Trabalha com 16 cores ponto a ponto de uma paleta de 512 combinacoes. Possui 4 " +
    "paginas graficas e usa os sprites no modo 2." + #CRLF$ + #CRLF$ +
    "- SCREEN 6 - modo grafico com bit mapeado de alta resolucao - 512 pontos na horizontal por " +
    "212 na vertical. Trabalha com 4 cores ponto a ponto de uma paleta de 512 combinacoes. " +
    "Quatro paginas graficas e sprites no modo 2." + #CRLF$ + #CRLF$ +
    "- SCREEN 7 - modo grafico com bit mapeado de alta resolucao - 512 pontos na horizontal por " +
    "212 na vertical. Trabalha com 16 cores ponto a ponto de uma paleta de 512 combinacoes. " +
    "Duas paginas graficas e sprites no modo 2." + #CRLF$ + #CRLF$ +
    "- SCREEN 8 - modo grafico com bit mapeado - resolucao de 256 pontos na horizontal por 212 " +
    "na vertical e 256 cores simultaneas ponto a ponto. Duas paginas graficas e sprites no modo 2." + #CRLF$ + #CRLF$ +
    "- SCREEN 9 - nao existe nos MSX 2+, mesmo nos importados." + #CRLF$ + #CRLF$ +
    "- SCREEN 10 - modo grafico 1 com cores no sistema YJK - 256 pontos na horizontal e 212 na " +
    "vertical. Trabalha com ate 12.499 cores do sistema YJK mais as 16 cores basicas (0 a 15) da " +
    "paleta de 512 combinacoes. Neste tipo de tela os comandos graficos trabalham somente com " +
    "cores usando valores entre 0 e 15. Portanto, pode-se tracar linhas sobre uma tela feita no " +
    "sistema YJK sem ocorrer borroes na tela de fundo. Tem duas paginas graficas e usa os " +
    "sprites no modo 2." + #CRLF$ + #CRLF$ +
    "- SCREEN 11 - modo grafico 1 com cores no sistema YJK - 256 pontos na horizontal por 212 na " +
    "vertical. Trabalha com ate 12.499 cores. O valor das cores nos comandos graficos pode " +
    "variar entre 0 e 255. Dependendo do valor da cor e do tipo de comando grafico podem ocorrer " +
    "borroes entre as cores no limite de quatro em quatro pontos. Tem duas paginas graficas e " +
    "usa sprites no modo 2." + #CRLF$ + #CRLF$ +
    "- SCREEN 12 - modo grafico 2 com cores no sistema YJK - 256 pontos na horizontal por 212 na " +
    "vertical. Trabalha com ate 19.268 cores de 131072 combinacoes. O limite para troca abrupta " +
    "de cores e de quatro em quatro pontos na horizontal. Tem duas paginas graficas e usa os " +
    "sprites no modo 2." + #CRLF$ + #CRLF$ +
    "Tipos de SPRITEs: nos MSX 1 os SPRITES podem ter somente uma cor e no maximo 4 SPRITES " +
    "podem estar na mesma linha horizontal. Nos MSX 2+ os SPRITES podem ser multicoloridos (cada " +
    "linha da figura pode ter uma cor) e ate 8 (oito) SPRITES podem ser colocados na mesma linha " +
    "horizontal. Tambem podem ser formadas figuras mais complexas sobrepondo-se varios SPRITES, " +
    "pois existe a possibilidade de se desativar o sensor de coincidencia de SPRITES (bit que e " +
    "ativado sempre que dois ou mais SPRITES se tocam)." + #CRLF$ + #CRLF$ +
    "A resolucao vertical pode ser dobrada para 424 usando-se o modo entrelacado de exibicao " +
    "(ver item ZZ)." + #CRLF$ + #CRLF$ +
    "Y determina o tamanho dos SPRITES:" + #CRLF$ +
    "- 0 - 8x8 mag. 1 (8x8)" + #CRLF$ +
    "- 1 - 8x8 mag. 2 (16x16)" + #CRLF$ +
    "- 2 - 16x16 mag. 1 (16x16)" + #CRLF$ +
    "- 3 - 16x16 mag. 2 (32x32)" + #CRLF$ + #CRLF$ +
    "Z ativa ou desativa o CLICK do teclado:" + #CRLF$ +
    "- 0 - desativa o CLICK" + #CRLF$ +
    "- 1 - ativa CLICK" + #CRLF$ + #CRLF$ +
    "XX define a velocidade de transmissao dos dados para o gravador cassete (baud rate):" + #CRLF$ +
    "- 1 - 1200 baud" + #CRLF$ +
    "- 2 - 2400 baud" + #CRLF$ + #CRLF$ +
    "YY define o tipo de impressora usada:" + #CRLF$ +
    "- 0 - MSX" + #CRLF$ +
    "- 1 - nao MSX" + #CRLF$ + #CRLF$ +
    "ZZ define o modo de exibicao da tela. Podendo ser:" + #CRLF$ +
    "- 0 - Normal" + #CRLF$ +
    "- 1 - Entrelacado" + #CRLF$ +
    "- 2 - Nao entrelacado, alternando paginas impares e pares" + #CRLF$ +
    "- 3 - Entrelacado, alternando paginas impares e pares" + #CRLF$ + #CRLF$ +
    "Nos modos de exibicao 2 e 3, o numero da pagina de exibicao deve ser impar (ver instrucao " +
    "SETPAGE).",
    "10 COLOR 15,0,0" + #CRLF$ +
    "20 FOR I= 2 TO 8 : SCREEN I" + #CRLF$ +
    "30 FOR N=0 TO 255:LINE (0,0)-(N,211),C" + #CRLF$ +
    "40 IF I=8 THEN C=N ELSE C=C+1:IFC=16THENC=1" + #CRLF$ +
    "50 NEXT" + #CRLF$ +
    "60 FOR T=0 TO 1000:NEXT" + #CRLF$ +
    "70 NEXT" + #CRLF$ + #CRLF$ +
    "10 SCREEN 7,,,,,3" + #CRLF$ +
    "20 LINE(80,80)-(400,200),4,BF" + #CRLF$ +
    "30 SETPAGE1,1:CLS" + #CRLF$ +
    "40 LINE(100,100)-(380,180),4,BF" + #CRLF$ +
    "50 GOTO50",
    7)
EndProcedure

; --- COLOR e a familia COLOR= (paginas 10-18 do manual ACVS) ---
Procedure MSXDict_BuildMSX2Plus_Color()
  MSXDict_Add2Plus("COLOR (MSX2+)", #False, #False, "(color)",
    "Define as cores que serao utilizadas na tela nos modos texto e grafico - versao MSX2+, com " +
    "paleta de 512 combinacoes e suporte aos sistemas de cor YJK (SCREEN 10/11/12).",
    "COLOR [X] [,Y] [,Z]",
    "COLOR 15,0,0",
    "X define a cor do caractere, Y define a cor do fundo da tela e Z define a cor da borda da " +
    "tela. X, Y e Z devem ser numeros inteiros." + #CRLF$ + #CRLF$ +
    "Nas SCREENs 0, 1, 2, 3, 4, 5 e 7, os numeros X, Y e Z devem estar compreendidos entre 0 e 15." + #CRLF$ + #CRLF$ +
    "Nas SCREENs 5 e 7 cada byte guarda a cor de dois pontos em sequencia." + #CRLF$ + #CRLF$ +
    "A cor correspondente a cada numero na paleta de cores (numero - nome - intensidade " +
    "Verm.,Verde,Azul):" + #CRLF$ +
    "- 0 - transparente - 0,0,0" + #CRLF$ +
    "- 1 - preta - 0,0,0" + #CRLF$ +
    "- 2 - verde media - 1,6,1" + #CRLF$ +
    "- 3 - verde clara - 3,7,3" + #CRLF$ +
    "- 4 - azul escura - 1,1,7" + #CRLF$ +
    "- 5 - azul clara - 2,3,7" + #CRLF$ +
    "- 6 - vermelha escura - 5,1,1" + #CRLF$ +
    "- 7 - ciano - 2,6,7" + #CRLF$ +
    "- 8 - vermelha media - 7,1,1" + #CRLF$ +
    "- 9 - vermelha clara - 7,3,3" + #CRLF$ +
    "- 10 - amarela escura - 6,6,1" + #CRLF$ +
    "- 11 - amarela clara - 6,6,4" + #CRLF$ +
    "- 12 - verde escura - 1,4,1" + #CRLF$ +
    "- 13 - magenta - 6,2,5" + #CRLF$ +
    "- 14 - cinza - 5,5,5" + #CRLF$ +
    "- 15 - branca - 7,7,7" + #CRLF$ + #CRLF$ +
    "A intensidade do vermelho, verde e azul na paleta de cores pode ser alterada com a " +
    "instrucao COLOR=." + #CRLF$ + #CRLF$ +
    "Na SCREEN 6, X, Y e Z devem estar entre 0 e 3. Neste modo grafico, se a cor da borda da " +
    "tela estiver entre 0 e 3, sera respeitada a tabela da paleta de cores. Porem, se a cor " +
    "estiver entre 16 e 31, sera feita uma combinacao das cores (a cor da borda passa a combinar " +
    "duas cores da paleta: 16=cor0+cor0, 17=cor0+cor1, 18=cor0+cor2, 19=cor0+cor3, 20=cor1+cor0, " +
    "21=cor1+cor1, 22=cor1+cor2, 23=cor1+cor3, 24=cor2+cor0, 25=cor2+cor1, 26=cor2+cor2, " +
    "27=cor2+cor3, 28=cor3+cor0, 29=cor3+cor1, 30=cor3+cor2, 31=cor3+cor3)." + #CRLF$ + #CRLF$ +
    "Na SCREEN 8, X, Y e Z devem estar entre 0 e 255. Neste modo grafico cada byte corresponde a " +
    "cor de um ponto. Para saber o numero da cor de acordo com a intensidade de vermelho, verde " +
    "e azul, use a equacao: G*32+R*4+B, onde G, R e B sao respectivamente as intensidades de " +
    "verde, vermelho e azul. O verde e o vermelho podem variar entre 0 e 7. O azul so pode " +
    "variar entre 0 e 3. A formacao do byte da cor na SCREEN 8 e: bit 7654 3210 = cor GGGRRRBB." + #CRLF$ + #CRLF$ +
    "Nas SCREEN 10, 11 e 12 e usado o sistema YJK para mostrar as cores. Neste modo especial, 4 " +
    "(quatro) bytes sao usados para compor as cores de quatro pontos na mesma linha horizontal. " +
    "Os (Y) sao a intensidade da cor (brilho) e podem variar de 0 a 31 (cada valor corresponde a " +
    "8 niveis na escala de intensidade: 0=0, 1=8, 2=16, ..., 31=248). Os (J e K) sao os vetores " +
    "que determinam qual cor sera usada, podendo variar de -32 a 31 (6 bits)." + #CRLF$ + #CRLF$ +
    "A conversao entre sistemas e feita com as equacoes:" + #CRLF$ +
    "De YJK para RGB: R=Y+J, G=Y+K, B=5/4 Y - 1/2 J - 1/4 K" + #CRLF$ +
    "De RGB para YJK: Y=B/2+R/4+G/8, J=R-Y, K=G-Y" + #CRLF$ + #CRLF$ +
    "SCREEN 10 - as cores sao formadas no sistema YJK ou com a paleta normal de 16 cores, " +
    "dependendo do bit 3 (A). Se for 0, as cores sao mostradas no sistema YJK (0 a 240 de " +
    "intensidade), obtendo-se ate 12.499 variacoes possiveis. Se o bit 3 (A) for 1, as cores sao " +
    "as da paleta de cores conforme os bits Y (0 a 15). Neste caso, os bits J e K sao ignorados." + #CRLF$ + #CRLF$ +
    "SCREEN 11 - as cores sao formadas como na SCREEN 10 so que as instrucoes graficas trabalham " +
    "com valores para a cor entre 0 e 255." + #CRLF$ + #CRLF$ +
    "Quando nao for dado nenhum valor a X, Y ou Z, a instrucao COLOR utilizara os ultimos " +
    "valores aplicados as cores dos caracteres, fundo e borda da tela.",
    "Ex1:" + #CRLF$ +
    "10 SCREEN7" + #CRLF$ +
    "20 FORX=0TO511" + #CRLF$ +
    "30 LINE(255,0)-(X,211),C" + #CRLF$ +
    "40 C=C+1:IFC=16THENC=0" + #CRLF$ +
    "50 NEXT" + #CRLF$ +
    "60 GOTO60" + #CRLF$ + #CRLF$ +
    "Ex2:" + #CRLF$ +
    "10 SCREEN8" + #CRLF$ +
    "20 FORX=0TO255" + #CRLF$ +
    "30 LINE(0,0)-(X,211),X" + #CRLF$ +
    "40 LINE(255,211)-(255-X,0),X" + #CRLF$ +
    "50 NEXT" + #CRLF$ +
    "60 GOTO60" + #CRLF$ + #CRLF$ +
    "Ex3:" + #CRLF$ +
    "100 SCREEN12" + #CRLF$ +
    "110 Y=93" + #CRLF$ +
    "120 FOR JH=0 TO 3" + #CRLF$ +
    "130 FOR JL=0 TO 7" + #CRLF$ +
    "140 FOR KH=0 TO 3" + #CRLF$ +
    "150 FOR KL=0 TO 7" + #CRLF$ +
    "160 LINE (X,Y)-(X,Y+2),KL,BF" + #CRLF$ +
    "170 LINE (X+1,Y)-(X+1,Y+2),KH,BF" + #CRLF$ +
    "180 LINE (X+2,Y)-(X+2,Y+2),JL,BF" + #CRLF$ +
    "190 LINE (X+3,Y)-(X+3,Y+2),JH,BF" + #CRLF$ +
    "200 X=X+4 : IFX=128 THEN X=0 : Y=Y-3" + #CRLF$ +
    "210 NEXT KL,KH,JL,JH" + #CRLF$ +
    "220 COPY (0,0)-(127,95) TO (128,0)" + #CRLF$ +
    "230 COPY (0,0)-(255,95) TO (0,96)" + #CRLF$ +
    "240 FOR X=0 TO 127 STEP 4" + #CRLF$ +
    "250 LINE (X+1,0)-(X+1,191),4,,OR" + #CRLF$ +
    "260 NEXT X" + #CRLF$ +
    "270 FOR X=0 TO 255 STEP 4" + #CRLF$ +
    "280 LINE (X+3,96)-(X+3,191),4,,OR" + #CRLF$ +
    "290 NEXT X" + #CRLF$ +
    "300 FOR N=0 TO 31" + #CRLF$ +
    "310 LINE (0,0)-(255,191),7,BF,AND" + #CRLF$ +
    "320 LINE (0,0)-(255,191),CC,BF,OR" + #CRLF$ +
    "330 FOR T=0 TO 300 : NEXT T" + #CRLF$ +
    "340 CC=CC+8" + #CRLF$ +
    "350 NEXT N" + #CRLF$ +
    "360 IF INKEY$=" + MSXQ + MSXQ + " THEN 360",
    10)

  MSXDict_Add2Plus("COLOR=", #False, #False, "(color equal)",
    "Altera as intensidades do vermelho, verde e azul na paleta de cores.",
    "COLOR=( X, R, G, B )",
    "COLOR=(1,7,0,0)",
    "Altera as intensidades do vermelho, verde e azul na paleta de cores. X e o numero da cor na " +
    "paleta de cores e deve estar entre 0 e 15. R e a intensidade do vermelho entre 0 e 7. G e a " +
    "intensidade do verde entre 0 e 7. B e a intensidade do azul e deve estar entre 0 e 7. A " +
    "SCREEN 8 nao usa a paleta de cores.",
    "100 SCREEN5" + #CRLF$ +
    "110 OPEN" + MSXQ + "GRP:" + MSXQ + "AS#1" + #CRLF$ +
    "120 FORN=0TO7" + #CRLF$ +
    "130 PRESET(N*32+6,40):PRINT#1," + MSXQ + "COR" + MSXQ + #CRLF$ +
    "140 PRESET(N*32+6,50)" + #CRLF$ +
    "150 PRINT#1,N+1" + #CRLF$ +
    "160 NEXT" + #CRLF$ +
    "170 FORX=0TO7" + #CRLF$ +
    "180 LINE(X*32,60)-(X*32+32,140),X+1,BF" + #CRLF$ +
    "190 LINE(X*32+32,141)-(X*32+64,211),15-X,BF" + #CRLF$ +
    "200 LINE(X*32+35,211)-(X*32+64,211),10,B" + #CRLF$ +
    "210 NEXT" + #CRLF$ +
    "220 PRESET(0,10)" + #CRLF$ +
    "230 FORN=0TO7" + #CRLF$ +
    "240 PRINT#1," + MSXQ + " RGB" + MSXQ + ";" + #CRLF$ +
    "250 NEXT" + #CRLF$ +
    "260 FORC=0TO7" + #CRLF$ +
    "270 COLOR=(C+1,R,G,B)" + #CRLF$ +
    "280 R$=RIGHT$(STR$(R),1)" + #CRLF$ +
    "290 G$=RIGHT$(STR$(G),1)" + #CRLF$ +
    "300 B$=RIGHT$(STR$(B),1)" + #CRLF$ +
    "310 PRESET(C*32+8,20):PRINT#1,R$;G$;B$" + #CRLF$ +
    "320 B=B+1:IFB=8THENB=0:G=G+1:IFG=8THENG=0:R=R+1:IFR=8 THENR=0" + #CRLF$ +
    "330 NEXT" + #CRLF$ +
    "340 GOTO260",
    14)

  MSXDict_Add2Plus("COLOR=NEW", #False, #False, "(color equal new)",
    "Volta as intensidades de vermelho, verde e azul da paleta de cores aos seus valores " +
    "originais.",
    "COLOR = NEW",
    "COLOR = NEW",
    "Os valores originais de vermelho, verde e azul sao aqueles mostrados na tabela junto a " +
    "instrucao COLOR (MSX2+).",
    "10 SCREEN 5 : COLOR 15,0,0" + #CRLF$ +
    "20 OPEN " + MSXQ + "GRP:" + MSXQ + " AS #1" + #CRLF$ +
    "30 FOR C=2 TO 15" + #CRLF$ +
    "40 COLOR C" + #CRLF$ +
    "50 PRINT#1," + MSXQ + "ALTERACAO DAS CORES DA PALETA" + MSXQ + #CRLF$ +
    "60 NEXT C" + #CRLF$ +
    "70 FOR N=2 TO 15" + #CRLF$ +
    "80 R=INT(RND(1)*7)" + #CRLF$ +
    "90 G=INT(RND(1)*7)" + #CRLF$ +
    "100 B=INT(RND(1)*7)" + #CRLF$ +
    "110 COLOR=(N,R,G,B)" + #CRLF$ +
    "120 NEXT N" + #CRLF$ +
    "130 FOR T=0 TO 1000 : NEXT T : BEEP" + #CRLF$ +
    "140 COLOR = NEW" + #CRLF$ +
    "150 IF INKEY$=" + MSXQ + MSXQ + " THEN 150",
    15)

  ; CONFERIR: a tabela de enderecos de memoria de video desta pagina
  ; mostra, para as SCREENs 5-8, um intervalo onde o fim (&H76A0 ou
  ; &HFAA0) e numericamente MENOR que o inicio (&H76B0 ou &HFAB0) -
  ; provavel erro de OCR/grafia do manual original (o digito B trocado
  ; por 8, ja que &H7680-&H76A0 faria mais sentido como intervalo
  ; crescente) - preservado como impresso.
  MSXDict_Add2Plus("COLOR=RESTORE", #False, #False, "(color equal restore)",
    "Transfere da memoria de video para a paleta de cores os valores das intensidades do " +
    "vermelho, verde e azul.",
    "COLOR=RESTORE",
    "COLOR=RESTORE",
    "Esta instrucao e usada quando os valores das intensidades do vermelho, verde e azul sao " +
    "carregados para a memoria de video com a instrucao BLOAD" + MSXQ + "nome do arquivo" + MSXQ + ",S." + #CRLF$ + #CRLF$ +
    "A tabela da paleta de cores pode ser encontrada nos seguintes enderecos na memoria de " +
    "video:" + #CRLF$ +
    "- SCREEN 0 (40 colunas): &H0400 - &H0420" + #CRLF$ +
    "- SCREEN 0 (80 colunas): &H0F00 - &H0F20" + #CRLF$ +
    "- SCREEN 1: &H2020 - &H2040" + #CRLF$ +
    "- SCREEN 2: &H2020 - &H2040" + #CRLF$ +
    "- SCREEN 3: &H2020 - &H2040" + #CRLF$ +
    "- SCREEN 4: &H2020 - &H2040" + #CRLF$ +
    "- SCREEN 5: &H76B0 - &H76A0" + #CRLF$ +
    "- SCREEN 6: &H76B0 - &H76A0" + #CRLF$ +
    "- SCREEN 7: &HFAB0 - &HFAA0" + #CRLF$ +
    "- SCREEN 8: &HFAB0 - &HFAA0" + #CRLF$ + #CRLF$ +
    "Nas SCREENs 5, 6, 7 e 8 pode-se trabalhar com mais de uma pagina de video (ver instrucao " +
    "SETPAGE). Para descobrir o endereco da tabela da paleta de cores, use o seguinte calculo:" + #CRLF$ +
    "SCREEN 5 e 6 --> numero da pagina * &H08000 + &H76B0" + #CRLF$ +
    "SCREEN 7 e 8 --> numero da pagina * &H10000 + &HFAB0",
    "10 SCREEN 0 : WIDTH 40 : COLOR 15,0,0" + #CRLF$ +
    "20 LOCATE 10,10 : PRINT " + MSXQ + "COR 15 NORMAL" + MSXQ + #CRLF$ +
    "30 FOR T=0 TO 500 : NEXT : BEEP" + #CRLF$ +
    "40 COLOR = (15,3,2,1)" + #CRLF$ +
    "50 LOCATE 10,10 : PRINT " + MSXQ + "COR 15 ALTERADA" + MSXQ + #CRLF$ +
    "60 BSAVE " + MSXQ + "TESTECOR.PIC" + MSXQ + ",&H0400,&H0420,S" + #CRLF$ +
    "70 COLOR=NEW : BLOAD " + MSXQ + "TESTECOR.PIC" + MSXQ + ",S" + #CRLF$ +
    "80 FOR T=0 TO 500 : NEXT : BEEP" + #CRLF$ +
    "90 COLOR=RESTORE",
    15)

  MSXDict_Add2Plus("COLORSPRITE", #False, #False, "(color sprite)",
    "Define a cor e algumas caracteristicas de um SPRITE.",
    "COLORSPRITE (X) = Y",
    "COLORSPRITE(1)=33",
    "Esta instrucao so funciona nos modos graficos de SCREEN 4 em diante. X e o numero do SPRITE " +
    "e deve ser igual ao numero na instrucao SPRITE$ que define as caracteristicas do SPRITE. Y " +
    "deve ser um numero inteiro compreendido entre 0 e 111. Tem o seguinte significado:" + #CRLF$ +
    "- Entre 0 e 15, sao os numeros das cores da paleta de cores." + #CRLF$ +
    "- Somando 32 ao numero da cor escolhida, o SPRITE nao ativa mais o sensor de coincidencia " +
    "de SPRITES. Ou seja, se este SPRITE colidir com outro na tela a instrucao ON SPRITE GOSUB " +
    "nao sera executada." + #CRLF$ +
    "- Somando 64 ao numero da cor escolhida, o SPRITE nao ativa mais o sensor de coincidencia " +
    "de SPRITE e faz uma operacao logica OR com as cores dos SPRITES que estao sobrepostos." + #CRLF$ + #CRLF$ +
    "As cores dos SPRITES podem ser determinadas pelas instrucoes: PUTSPRITE, COLORSPRITE ou " +
    "COLORSPRITE$. A instrucao que for executada por ultimo e que determinara a cor do SPRITE. " +
    "Quando for usar as instrucoes COLORSPRITE ou COLORSPRITE$, nao defina o numero da paleta de " +
    "cores na instrucao PUTSPRITE. Para detalhes da instrucao PUT SPRITE, recorra ao manual do " +
    "MSX1.",
    "100 SCREEN5,1:COLOR15,0,0" + #CRLF$ +
    "110 FORX=0TO15:LINE(X*16,40)-STEP(16,120),15-X,BF:NEXT" + #CRLF$ +
    "120 B$=" + MSXQ + MSXQ + #CRLF$ +
    "130 FORI=1TO8:READA$:B$=B$+CHR$(VAL(" + MSXQ + "&b" + MSXQ + "+A$)):NEXT" + #CRLF$ +
    "140 SPRITE$(0)=B$" + #CRLF$ +
    "150 SPRITE$(1)=B$" + #CRLF$ +
    "160 COLORSPRITE(1)=33 'SOMBRA" + #CRLF$ +
    "170COLORSPRITE$(0)=CHR$(12)+CHR$(10)+CHR$(5)+CHR$(8)+CHR$(3)+CHR$(3)" + #CRLF$ +
    "180 FORI=0TO212" + #CRLF$ +
    "190 PUTSPRITE0,(I,I),,0" + #CRLF$ +
    "200 PUTSPRITE1,(I+B,I+B),,1" + #CRLF$ +
    "210 NEXT" + #CRLF$ +
    "220 GOTO220" + #CRLF$ +
    "230 DATA 10011001" + #CRLF$ +
    "240 DATA 00111100" + #CRLF$ +
    "250 DATA 01111110" + #CRLF$ +
    "260 DATA 11111111" + #CRLF$ +
    "270 DATA 11111111" + #CRLF$ +
    "280 DATA 01111110" + #CRLF$ +
    "290 DATA 01000010" + #CRLF$ +
    "300 DATA 10000001",
    16)

  MSXDict_Add2Plus("COLORSPRITE$", #False, #False, "(color sprite dollar)",
    "Define a cor das linhas de um SPRITE.",
    "COLORSPRITE$ (X) = Y$",
    "COLORSPRITE$(0)=CHR$(12)+CHR$(10)+CHR$(5)+CHR$(8)+CHR$(3)+CHR$(3)",
    "Esta instrucao so funciona nos modos graficos de SCREEN 4 em diante. X e o numero do SPRITE " +
    "e deve ser igual ao numero na instrucao SPRITE$ que define as caracteristicas do SPRITE. Y$ " +
    "deve ser uma expressao com 1 ate 16 caracteres, cada um correspondendo a uma linha do " +
    "SPRITE. O codigo dos caracteres, de acordo com o seu valor, tem o seguinte significado:" + #CRLF$ +
    "- Entre 0 e 15, sao os numeros das cores da paleta de cores." + #CRLF$ +
    "- Somando 32 ao numero da paleta de cores, a linha do SPRITE nao ativa mais o sensor de " +
    "coincidencia de SPRITES. Ou seja, se a linha do SPRITE colidir com outra na tela, a " +
    "instrucao ON SPRITE GOSUB nao sera executada." + #CRLF$ +
    "- Somando 64 ao numero da paleta de cores, a linha do SPRITE nao ativa mais o sensor de " +
    "coincidencia de SPRITES e faz uma operacao logica OR com as cores dos SPRITES que estao " +
    "sobrepostas." + #CRLF$ +
    "- Ao se somar 128 ao numero da paleta de cores, a linha do SPRITE se deslocara 32 pontos " +
    "para a esquerda." + #CRLF$ + #CRLF$ +
    "As cores dos SPRITES podem ser determinadas pelas instrucoes: PUTSPRITE, COLORSPRITE ou " +
    "COLORSPRITE$. A instrucao que for executada por ultimo e que determinara a cor do SPRITE. " +
    "Quando for usar as instrucoes COLORSPRITE ou COLORSPRITE$, nao defina o numero da paleta de " +
    "cores na instrucao PUTSPRITE. Para detalhes da instrucao PUT SPRITE, recorra ao manual do " +
    "MSX 1.0." + #CRLF$ + #CRLF$ +
    "Exemplo: ver exemplo na instrucao COLORSPRITE.",
    "",
    18)
EndProcedure

; --- COPY (paginas 19-20 do manual ACVS) ---
Procedure MSXDict_BuildMSX2Plus_Copy()
  MSXDict_Add2Plus("COPY", #False, #False, "(copy)",
    "Copia dados de uma tela grafica para outro ponto da tela, para outra pagina de tela " +
    "grafica, para uma matriz ou para um arquivo em disquete. Traz dados de uma matriz ou que " +
    "estejam gravados em disquetes para a tela grafica. Copia um arquivo de um disquete para " +
    "outro, ou faz copia do arquivo no mesmo disquete com outro nome.",
    "COPY origem TO destino" + #CRLF$ +
    "COPY(X1,Y1)-[STEP](X2,Y2)[,XX] TO (X3,Y3)[,YY] [,op logico]" + #CRLF$ +
    "COPY (X1,Y1) - [STEP] (X2,Y2) [,XX] TO matriz" + #CRLF$ +
    "COPY(X1,Y1)-[STEP](X2,Y2)[,XX] TO " + MSXQ + "perif: nome arquivo" + MSXQ + #CRLF$ +
    "COPY matriz[,sentido] TO (X3,Y3)[,YY] [,operacao logica]" + #CRLF$ +
    "COPY matriz TO " + MSXQ + "periferico: nome arquivo" + MSXQ + #CRLF$ +
    "COPY" + MSXQ + "perif:nome arq." + MSXQ + "[,sentido]TO (X3,Y3)[,YY]" + #CRLF$ +
    "COPY " + MSXQ + "perif: nome arquivo1" + MSXQ + " TO " + MSXQ + "perif: nome arquivo2" + MSXQ,
    "COPY(0,0)-(127,95) TO (128,0)",
    "Esta instrucao so e valida nas SCREENs 5, 6, 7 e 8." + #CRLF$ + #CRLF$ +
    "X1 e Y1 sao as coordenadas na tela grafica do inicio do bloco que sera copiado." + #CRLF$ + #CRLF$ +
    "X2 e Y2 sao as coordenadas na tela grafica do fim do bloco que sera copiado. Se for usada a " +
    "palavra STEP antes dos numeros (X2,Y2), estes numeros passam a ser a quantidade de pontos " +
    "nos eixos X e Y que serao somados as coordenadas X1 e Y1, respectivamente. Os resultados " +
    "das somas serao as coordenadas finais do bloco." + #CRLF$ + #CRLF$ +
    "X3 e Y3 sao as coordenadas de destino, ou seja, ponto na tela grafica para onde os dados " +
    "comecarao a ser transferidos." + #CRLF$ + #CRLF$ +
    "X1, X2 e X3 sao numeros inteiros e podem variar entre 0 e 255 nas SCREENs 5 e 8, e entre 0 " +
    "e 511 nas SCREENs 6 e 7." + #CRLF$ + #CRLF$ +
    "Y1, Y2 e Y3 podem variar entre 0 e 211 nas SCREENs 5,6,7 ou 8." + #CRLF$ + #CRLF$ +
    "Nas SCREENs 5, 6, 7 e 8 voce pode trabalhar com mais de uma pagina de video (ver instrucao " +
    "SETPAGE). Nestes casos: XX e YY representam o numero da pagina de origem e o numero da " +
    "pagina de destino respectivamente. Se XX e YY nao forem determinados, sera assumida a " +
    "pagina que esta sendo usada." + #CRLF$ + #CRLF$ +
    "[Sentido]: determina o sentido em que os dados serao transferidos. Podem variar entre 0 e 3 " +
    "e tem o seguinte significado:" + #CRLF$ +
    "- 0 - da esquerda superior para a direita inferior." + #CRLF$ +
    "- 1 - da direita superior para a esquerda inferior." + #CRLF$ +
    "- 2 - da esquerda inferior para a direita superior." + #CRLF$ +
    "- 3 - da direita inferior para a esquerda superior." + #CRLF$ + #CRLF$ +
    "Matriz: e o nome da variavel (matriz numerica) que deve ter tamanho suficiente para receber " +
    "os dados da tela grafica. O tamanho da matriz pode ser calculado com a seguinte equacao:" + #CRLF$ +
    "INT ((pixel * (ABS(X2-X1)+1) * (ABS(Y2-Y1)+1) +7)/8)+4" + #CRLF$ +
    "Pixel nas SCREENs 5, 7 e 8 vale quatro e na SCREEN 6 vale dois." + #CRLF$ + #CRLF$ +
    "[Operacao]: e uma operacao logica que pode ser feita entre as cores de origem e as cores de " +
    "destino da area copiada. O resultado da operacao e visto na regiao de destino. As operacoes " +
    "logicas podem ser:" + #CRLF$ +
    "- OR - C2 = C1 + C2" + #CRLF$ +
    "- XOR - C2 = NOT(C1) * C2 + C1 * NOT(C2)" + #CRLF$ +
    "- AND - C2 = C1 * C2" + #CRLF$ +
    "- PSET - C2 = C1" + #CRLF$ +
    "- PRESET - C2 = NOT(C1)" + #CRLF$ + #CRLF$ +
    "TOR, TXOR, TAND, TPSET e TPRESET, executam as mesmas operacoes logicas descritas acima com " +
    "a diferenca de nao afetarem a cor transparente (0)." + #CRLF$ + #CRLF$ +
    "C1 e o numero da cor de origem. C2 e o numero da cor de destino. NOT(cor) significa a " +
    "inversao bit a bit do numero da cor." + #CRLF$ + #CRLF$ +
    "Periferico: (Perif) e a letra que indica qual controlador de disquete sera usado, podendo " +
    "ser: A, B, C, D, E ou F dependendo do numero de interfaces de drives ligadas ao computador." + #CRLF$ + #CRLF$ +
    "Nome arquivo1 e nome arquivo2 sao, respectivamente, os nomes dos arquivos de origem e de " +
    "destino que sao gravados no disquete.",
    "100 SCREEN7,0:COLOR15,0,0" + #CRLF$ +
    "110 X1=0:Y1=0:X2=64:Y2=32" + #CRLF$ +
    "120 TM=INT((4*(ABS(X2-X1)+1)*(ABS(Y2-Y1)+1)+7)/8)+4" + #CRLF$ +
    "130 DIM A(TM)" + #CRLF$ +
    "140 FORX=1TO7" + #CRLF$ +
    "150 CIRCLE(16,16),X*2-1,X:CIRCLE(16,16),X*2,X" + #CRLF$ +
    "160 CIRCLE(48,16),X*2-1,8+X:CIRCLE(48,16),X*2,8+X" + #CRLF$ +
    "170 NEXT" + #CRLF$ +
    "180 FORC=1TO7" + #CRLF$ +
    "190 COLOR=(C,0,0,7-C/2):COLOR=(C+8,7,0,0)" + #CRLF$ +
    "200 NEXT" + #CRLF$ +
    "210 COPY(0,0)-STEP(64,32)TOA" + #CRLF$ +
    "220 FORN=1TO100" + #CRLF$ +
    "230 X=RND(N)*256:Y=RND(N)*200" + #CRLF$ +
    "240 COPYA,0TO(X,Y),,TPSET" + #CRLF$ +
    "250 NEXT" + #CRLF$ +
    "260 COPY(0,0)-(350,211)TO(200,0),,TPSET" + #CRLF$ +
    "270 GOTO270",
    19)
EndProcedure

; --- SETPAGE e SETSCROLL (paginas 21-22 do manual ACVS) ---
Procedure MSXDict_BuildMSX2Plus_SetPage()
  MSXDict_Add2Plus("SETPAGE", #False, #False, "(set page)",
    "Seleciona a pagina da tela que sera exibida e a pagina que sera ativa (na qual os desenhos " +
    "serao feitos).",
    "SETPAGE X,Y",
    "SETPAGE 0,1",
    "Esta instrucao so e valida nas SCREENs 5 a 12. X determina a pagina que sera exibida e deve " +
    "ser um numero inteiro entre 0 e 3, dependendo da SCREEN que esta sendo utilizada. Y " +
    "determina a pagina que sera ativa e deve ser um numero inteiro entre 0 e 3, dependendo da " +
    "SCREEN que esta sendo utilizada." + #CRLF$ + #CRLF$ +
    "As paginas de cada SCREEN sao:" + #CRLF$ +
    "- SCREEN 5 - 4 paginas (0 a 3)" + #CRLF$ +
    "- SCREEN 6 - 4 paginas (0 a 3)" + #CRLF$ +
    "- SCREEN 7 - 2 paginas (0 e 1)" + #CRLF$ +
    "- SCREEN 8 - 2 paginas (0 e 1)" + #CRLF$ +
    "- SCREEN 10 - 2 paginas (0 e 1)" + #CRLF$ +
    "- SCREEN 11 - 2 paginas (0 e 1)" + #CRLF$ +
    "- SCREEN 12 - 2 paginas (0 e 1)",
    "10 SCREEN 5: COLOR 15,0,0" + #CRLF$ +
    "20 LINE (20,20)-(220,200),4,BF" + #CRLF$ +
    "30 SETPAGE 0,1:CLS" + #CRLF$ +
    "40 LINE (40,40)-(200,180),8,BF" + #CRLF$ +
    "50 SETPAGE 0,2:CLS" + #CRLF$ +
    "60 LINE (60,60)-(180,160),12,BF" + #CRLF$ +
    "70 SETPAGE 0,3:CLS" + #CRLF$ +
    "80 CIRCLE (127,105),80,4" + #CRLF$ +
    "90 PAINT (127,105),10,4" + #CRLF$ +
    "100 FOR P=0 TO 3" + #CRLF$ +
    "110 SETPAGE P,P" + #CRLF$ +
    "120 FOR T=0 TO 300 :NEXT T:BEEP" + #CRLF$ +
    "130 NEXT P" + #CRLF$ +
    "140 GOTO100",
    21)

  MSXDict_Add2Plus("SETSCROLL", #False, #False, "(set scroll)",
    "Determina uma coordenada que sera usada como ponto inicial, a partir do qual a tela sera " +
    "mostrada no video.",
    "SETSCROLL [X] [,Y] [,Z] [,XX]",
    "SETSCROLL X,0,1,1",
    "X e um numero entre 0 e 511 e define a coordenada horizontal. Y e um numero entre 0 e 255 e " +
    "define a coordenada vertical. Z determina se sera feito SCROLL nas 8 colunas da esquerda. " +
    "Podendo ser:" + #CRLF$ +
    "- 0 - as 8 colunas da esquerda da tela sao mostradas." + #CRLF$ +
    "- 1 - as 8 colunas da esquerda da tela nao aparecem." + #CRLF$ + #CRLF$ +
    "XX determina se havera troca de paginas de video ou nao. Podendo ser:" + #CRLF$ +
    "- 0 - somente uma pagina. Neste caso, quando a tela desaparece em uma das laterais do " +
    "video, a mesma tela reaparece no lado oposto." + #CRLF$ +
    "- 1 - duas paginas. Neste caso, quando a primeira pagina desaparece em uma das laterais do " +
    "video, a segunda pagina aparece no lado oposto." + #CRLF$ + #CRLF$ +
    "Para movimentar duas paginas, a pagina ativa deve ser impar. Para isso, use a instrucao " +
    "SETPAGE.",
    "10 SCREEN 8,0" + #CRLF$ +
    "20 COPY (0,0)-(255,80) TO (0,211)" + #CRLF$ +
    "30 FOR X=0 TO 255" + #CRLF$ +
    "40 LINE (255,0)-(X,211),X" + #CRLF$ +
    "50 NEXT" + #CRLF$ +
    "60 SETPAGE 1,1:CLS" + #CRLF$ +
    "70 COPY (0,0)-(255,80) TO (0,211)" + #CRLF$ +
    "80 FOR X=0 TO 255" + #CRLF$ +
    "90 LINE (0,0)-(X,211),X" + #CRLF$ +
    "100 NEXT" + #CRLF$ +
    "110 FOR X=0TO511" + #CRLF$ +
    "120 SETSCROLL X,0,1,1" + #CRLF$ +
    "130 NEXT" + #CRLF$ +
    "140 FOR X=0 TO 511" + #CRLF$ +
    "150 SETSCROLL X,X/2,1,1" + #CRLF$ +
    "160 NEXT" + #CRLF$ +
    "170 GOTO110",
    22)
EndProcedure

; --- WIDTH e a nota geral CIRCLE/DRAW/LINE/PAINT/POINT/PRESET/PSET (paginas 23 do manual ACVS) ---
Procedure MSXDict_BuildMSX2Plus_Width()
  MSXDict_Add2Plus("WIDTH (MSX2+)", #False, #False, "(width)",
    "Determina o numero de caracteres que sera usado por linha - versao MSX2+, com suporte a " +
    "ate 80 colunas.",
    "WIDTH X",
    "WIDTH 80",
    "X e um numero inteiro que pode variar de 1 a 80 na SCREEN 0 e de 1 a 32 na SCREEN 1. Na " +
    "SCREEN 0 se X for menor ou igual a 40, serao utilizados caracteres grandes para texto. Se X " +
    "estiver entre 41 e 80 os caracteres serao pequenos. Os parametros de fabrica, quando o KIT " +
    "2+ e adquirido, sao: SCREEN 0 - 37 colunas, SCREEN 1 - 29 colunas.",
    "10 SCREEN0" + #CRLF$ +
    "20 FOR N=1 TO 80" + #CRLF$ +
    "30 WIDTH N" + #CRLF$ +
    "50 PRINT " + MSXQ + "Esta tela tem " + MSXQ + ";N;" + MSXQ + " colunas." + MSXQ + #CRLF$ +
    "60 FOR T=0 TO 300:NEXT" + #CRLF$ +
    "70 NEXT",
    23)
EndProcedure

Procedure MSXDict_BuildMSX2Plus_Graphics()
  MSXDict_Add2Plus("CIRCLE, DRAW, LINE, PAINT, POINT, PRESET e PSET (MSX2+)", #False, #False,
    "(circle, draw, line, paint, point, preset, pset)",
    "Nota geral do manual MSX2+: todas estas instrucoes passam a trabalhar com os novos valores " +
    "de cores e coordenadas das telas graficas, e o comando PAINT ganha um segundo parametro de " +
    "cor para a borda da figura.",
    "",
    "PAINT C1,C2",
    "Todas estas instrucoes passam a trabalhar com os novos valores das cores e coordenadas das " +
    "telas graficas. Para obter os valores maximos das coordenadas, ver instrucao SCREEN " +
    "(MSX2+). Para saber as cores que podem ser utilizadas veja as instrucoes COLOR (MSX2+) e " +
    "SCREEN (MSX2+)." + #CRLF$ + #CRLF$ +
    "Nas SCREENs de 5 em diante, os desenhos podem ter uma cor para o tracado e serem " +
    "preenchidos com outra diferente. A instrucao PAINT passa a aceitar a seguinte sintaxe:" + #CRLF$ +
    "PAINT C1,C2" + #CRLF$ +
    "onde C1 e a cor que ira pintar a figura e C2, a cor do tracado ou borda da figura.",
    "",
    23)
EndProcedure

; --- Relogio/calendario interno (paginas 24-25 do manual ACVS) ---
Procedure MSXDict_BuildMSX2Plus_Clock()
  MSXDict_Add2Plus("GETDATE", #False, #False, "(get date)",
    "Obtem a data armazenada no relogio/calendario interno.",
    "GETDATE X$",
    "GETDATE A$ : PRINT A$",
    "A data no relogio interno e transferida para a variavel X$. O formato dos dados na " +
    "variavel e o seguinte: DD/MM/AA - onde DD e o dia, MM o mes e AA o ano. A data armazenada " +
    "no relogio/calendario interno e atualizada mesmo com o computador desligado.",
    "GETDATE A$ : PRINT A$",
    24)

  MSXDict_Add2Plus("SETDATE", #False, #False, "(set date)",
    "Acerta a data no relogio interno.",
    "SETDATE X$",
    "SETDATE " + MSXQ + "14/04/61" + MSXQ,
    "X$ e uma expressao alfanumerica com o seguinte formato: DD/MM/AA - onde: DD e o dia (1 a " +
    "31), MM e o mes (1 a 12) e AA e o ano. A data e armazenada no relogio interno e sera " +
    "incrementada mesmo com o computador desligado.",
    "SETDATE " + MSXQ + "14/04/61" + MSXQ + #CRLF$ +
    "GETDATE A$" + #CRLF$ +
    "PRINT A$",
    24)

  MSXDict_Add2Plus("GETTIME", #False, #False, "(get time)",
    "Obtem a hora armazenada no relogio interno.",
    "GETTIME X$ [,A]",
    "GETTIME A$",
    "A hora no relogio interno e transferida para a variavel X$. O formato dos dados na " +
    "variavel e o seguinte: HH/MM/SS - onde HH e a hora, MM o minuto e SS o segundo. A hora do " +
    "relogio e atualizada mesmo com o computador desligado.",
    "10 SCREEN 1" + #CRLF$ +
    "20 GETTIME A$" + #CRLF$ +
    "30 LOCATE 10,10" + #CRLF$ +
    "40 PRINT A$" + #CRLF$ +
    "50 GOTO 20",
    25)

  MSXDict_Add2Plus("SETTIME", #False, #False, "(set time)",
    "Acerta a hora do relogio interno.",
    "SETTIME X$",
    "SETTIME " + MSXQ + "13:30:20" + MSXQ,
    "X$ e uma sequencia de caracteres com o seguinte formato: HH:MM:SS - onde HH e a hora " +
    "(entre 00 e 23), MM o minuto (entre 00 e 59) e SS o segundo (entre 00 e 59). Estes dados " +
    "sao guardados na memoria do relogio interno que e mantido por baterias. Assim, mesmo com o " +
    "computador desligado, eles serao preservados e atualizados.",
    "10 SETTIME " + MSXQ + "13:30:20" + MSXQ + #CRLF$ +
    "20 GETTIME A$" + #CRLF$ +
    "30 LOCATE 10,10" + #CRLF$ +
    "40 PRINT A$" + #CRLF$ +
    "50 GOTO 20",
    25)

  MSXDict_Add2Plus("SETADJUST", #False, #False, "(set adjust)",
    "Ajusta a posicao da tela para se adequar ao televisor ou monitor.",
    "SETADJUST (X,Y)",
    "SETADJUST (X,Y)",
    "X deve ser um numero inteiro entre -7 e 8. Quando negativo, a tela se deslocara para a " +
    "esquerda. Quando for positivo, a tela se deslocara para a direita. Y deve ser um numero " +
    "inteiro entre -7 e 8. Quando negativo, a tela se deslocara para cima e quando positivo, a " +
    "tela se deslocara para baixo. Os valores de X e Y sao armazenados na memoria do relogio. " +
    "Assim, quando o computador for ligado, os parametros armazenados serao usados " +
    "automaticamente.",
    "10 SCREEN1:COLOR 15,4,7" + #CRLF$ +
    "20 PRINT " + MSXQ + "USE AS TECLAS DO CURSOR" + MSXQ + #CRLF$ +
    "30 C=STICK(0)" + #CRLF$ +
    "40 X=X+(C=6 OR C=7 OR C=8)-(C=2 OR C=3 OR C=4)" + #CRLF$ +
    "50 Y=Y+(C=8 OR C=1 OR C=2)-(C=4 OR C=5 OR C=6)" + #CRLF$ +
    "60 IF X=-8 THEN X=-7" + #CRLF$ +
    "70 IF X=9 THEN X=8" + #CRLF$ +
    "80 IF Y=-8 THEN Y=-7" + #CRLF$ +
    "90 IF Y=9 THEN Y=8" + #CRLF$ +
    "100 LOCATE 4,4" + #CRLF$ +
    "110 PRINT " + MSXQ + "X = " + MSXQ + ";X ," + MSXQ + "Y = " + MSXQ + ";Y" + #CRLF$ +
    "120 SETADJUST (X,Y)" + #CRLF$ +
    "130 GOTO 30",
    25)
EndProcedure

; --- SETBEEP, SETPASSWORD, SETPROMPT, SETSCREEN, SETTITLE (paginas 26-28) ---
Procedure MSXDict_BuildMSX2Plus_Misc()
  MSXDict_Add2Plus("SETBEEP", #False, #False, "(set beep)",
    "Seleciona o tipo e o volume do BEEP.",
    "SETBEEP X,Y",
    "SETBEEP A,B",
    "X e o tipo de BEEP e deve ser um numero inteiro entre 1 e 4. Y e o volume do BEEP e deve " +
    "estar entre 1 e 4. O numero 1 e o volume minimo e o 4 o volume maximo. Os valores de X e Y " +
    "sao armazenados na memoria do relogio interno. Assim, quando o computador for ligado, os " +
    "parametros armazenados serao usados automaticamente. O BEEP tambem pode ser gerado " +
    "pressionando as teclas CONTROL+G.",
    "10 FOR A=1 TO 4" + #CRLF$ +
    "20 FOR B=1 TO 4" + #CRLF$ +
    "30 SETBEEP A,B" + #CRLF$ +
    "40 FOR N=1 TO 10 : BEEP : NEXT" + #CRLF$ +
    "50 FOR T=0 TO 500:NEXT" + #CRLF$ +
    "60 NEXT:NEXT",
    26)

  MSXDict_Add2Plus("SETPASSWORD", #False, #False, "(set password)",
    "Estabelece uma senha ou palavra de acesso ao computador.",
    "SETPASSWORD X$",
    "SETPASSWORD" + MSXQ + "TESTE" + MSXQ,
    "X$ e uma sequencia alfanumerica de ate 255 caracteres. A senha e armazenada na memoria do " +
    "relogio interno que e mantido por baterias. Assim, mesmo com o computador desligado, a " +
    "senha continua armazenada. Ao se ligar o computador, sera apresentada a palavra " +
    MSXQ + "PASSWORD:" + MSXQ + " esperando que seja digitada a senha. Caso a senha digitada nao " +
    "coincida com aquela armazenada, o computador continuara esperando a senha correta." + #CRLF$ + #CRLF$ +
    "Para eliminar a senha, use a instrucao SETTITLE " + MSXQ + MSXQ + "." + #CRLF$ + #CRLF$ +
    "So se pode utilizar uma das instrucoes " + MSXQ + "SETPASSWORD" + MSXQ + ", " + MSXQ + "SETPROMPT" + MSXQ +
    " ou " + MSXQ + "SETTITLE" + MSXQ + " de cada vez. A ultima instrucao executada sera a armazenada pois " +
    "todas utilizam a mesma area na memoria do relogio interno.",
    "SETPASSWORD" + MSXQ + "TESTE" + MSXQ + #CRLF$ +
    "'desligue o computador e ligue-o novamente." + #CRLF$ +
    "'digite TESTE seguido da tecla RETURN",
    27)

  MSXDict_Add2Plus("SETPROMPT", #False, #False, "(set prompt)",
    "Estabelece um PROMPT ou palavra de aviso de espera de um comando.",
    "SETPROMPT X$",
    "SETPROMPT " + MSXQ + "TESTE" + MSXQ,
    "X$ e uma sequencia alfanumerica de ate 6 caracteres. O PROMPT e armazenado na memoria do " +
    "relogio interno que e mantido por baterias. Assim, mesmo com o computador desligado, ele " +
    "sera preservado. O PROMPT normal do computador e " + MSXQ + "Ok" + MSXQ + ". Quando este PROMPT e " +
    "selecionado, a area na memoria de relogio fica livre para ser usada pelas instrucoes " +
    "SETPASSWORD ou SETTITLE." + #CRLF$ + #CRLF$ +
    "So se pode utilizar uma das instrucoes " + MSXQ + "SETPASSWORD" + MSXQ + ", " + MSXQ + "SETPROMPT" + MSXQ +
    " ou " + MSXQ + "SETTITLE" + MSXQ + " de cada vez. A ultima instrucao executada sera a armazenada pois " +
    "elas utilizam a mesma area na memoria do relogio interno.",
    "SETPROMPT " + MSXQ + "TESTE" + MSXQ,
    27)

  MSXDict_Add2Plus("SETSCREEN", #False, #False, "(set screen)",
    "Transfere os parametros da tela e do modo de trabalho do computador para a memoria do " +
    "relogio.",
    "SETSCREEN",
    "SETSCREEN",
    "Os parametros armazenados sao:" + #CRLF$ +
    "- Tipo de SCREEN de texto: 0 ou 1." + #CRLF$ +
    "- Numero de colunas (WIDTH): 1 a 80." + #CRLF$ +
    "- Numero da cor do caractere: 0 a 15." + #CRLF$ +
    "- Numero da cor do fundo do caractere: 0 a 15." + #CRLF$ +
    "- Numero da cor da borda da tela: 0 a 15." + #CRLF$ +
    "- Exibicao das teclas de funcoes: ligada ou desligada." + #CRLF$ +
    "- Click do teclado: ligado ou desligado." + #CRLF$ +
    "- Tipo de impressora: MSX ou nao MSX." + #CRLF$ +
    "- Velocidade dos dados para o gravador cassete: 1200 ou 2400 bauds." + #CRLF$ +
    "- Modo de exibicao da tela: 1 a 4." + #CRLF$ + #CRLF$ +
    "Estes dados sao armazenados na memoria do relogio interno, mantido por baterias. Assim, " +
    "mesmo com o computador desligado, eles serao preservados.",
    "'Para inicializar o computador em 80 colunas automaticamente:" + #CRLF$ +
    "SCREEN0 : WIDTH80 : SETSCREEN" + #CRLF$ +
    "'(desligue o computador e ligue-o novamente)",
    28)

  MSXDict_Add2Plus("SETTITLE", #False, #False, "(set title)",
    "Armazena um nome que sera mostrado na apresentacao quando o computador for ligado.",
    "SETTITLE X$ [,Y]",
    "SETTITLE " + MSXQ + "TESTE " + MSXQ + ",4",
    "X$ e uma sequencia alfanumerica com ate 6 caracteres. Se X$ tiver exatamente 6 caracteres, " +
    "o nome aparecera na apresentacao e o computador ficara esperando que qualquer tecla seja " +
    "pressionada, continuando a inicializacao somente depois. Se tiver ate 5 caracteres, o nome " +
    "permanecera na tela durante alguns segundos e, entao, continuara a inicializacao. Y pode " +
    "variar de 1 a 4 e seleciona qual combinacao de cores sera usada na apresentacao quando o " +
    "computador for ligado." + #CRLF$ + #CRLF$ +
    "Estes dados sao armazenados na memoria do relogio interno que e mantido por baterias. " +
    "Assim, mesmo com o computador desligado, os dados serao preservados." + #CRLF$ + #CRLF$ +
    "So se pode utilizar uma das instrucoes " + MSXQ + "SETPASSWORD" + MSXQ + ", " + MSXQ + "SETPROMPT" + MSXQ +
    " ou " + MSXQ + "SETTITLE" + MSXQ + " de cada vez. A ultima instrucao executada sera a armazenada pois " +
    "todas utilizam a mesma area na memoria do relogio interno." + #CRLF$ + #CRLF$ +
    "SETTITLE " + MSXQ + MSXQ + " e usado para apagar os dados do SET PASSWORD.",
    "SETTITLE " + MSXQ + "TESTE " + MSXQ + ",4" + #CRLF$ +
    "'desligue o computador e ligue-o novamente",
    28)
EndProcedure

; --- RAMDISK: CALL MEMINI/MFILES/MKILL/MNAME (paginas 29-31) ---
Procedure MSXDict_BuildMSX2Plus_Ramdisk()
  MSXDict_Add2Plus("CALL MEMINI", #False, #False, "(mem init)",
    "Prepara uma area da memoria RAM para trabalhar como RAMDISK (disco em memoria).",
    "CALL MEMINI [(X)]",
    "_MEMINI",
    "X e o tamanho do disco em memoria em bytes e tem de ser um numero inteiro entre 1023 e " +
    "32767, ou 0 (zero). CALL MEMINI (0) cancela o modo RAMDISK. Quando se executa a instrucao " +
    "CALL MEMINI, todo o conteudo do disco em memoria sera limpo." + #CRLF$ + #CRLF$ +
    "No lugar da palavra CALL pode-se utilizar o sinal de sublinhado (_). Por exemplo: _MEMINI" + #CRLF$ + #CRLF$ +
    "A instrucao CALL MEMINI deve ser executada antes das instrucoes: CALL MFILES, CALL MNAME " +
    "ou CALL MKILL." + #CRLF$ + #CRLF$ +
    "As seguintes instrucoes podem ser utilizadas apos a instrucao CALL MEMINI para se trabalhar " +
    "com arquivos em RAMDISK: SAVE, LOAD, RUN, MERGE, OPEN, CLOSE, PRINT#, PRINT#USING, INPUT#, " +
    "LINEINPUT#, EOF, LOC, LOF." + #CRLF$ + #CRLF$ +
    "A RAMDISK deve ser tratada como se fosse um disquete normal. O unico detalhe e que o nome " +
    "do dispositivo deve ser MEM:.",
    "_MEMINI" + #CRLF$ +
    "10 PRINT " + MSXQ + "TESTE " + MSXQ + "; : GOTO 10" + #CRLF$ +
    "SAVE " + MSXQ + "MEM:TESTE.BAS" + MSXQ + #CRLF$ +
    "NEW" + #CRLF$ +
    "LIST" + #CRLF$ +
    "LOAD " + MSXQ + "MEM:TESTE.BAS" + MSXQ + #CRLF$ +
    "LIST" + #CRLF$ +
    "RUN",
    29)

  MSXDict_Add2Plus("CALL MFILES", #False, #False, "(mem files)",
    "Lista na tela os nomes dos arquivos armazenados na RAMDISK e quantos bytes ainda estao " +
    "livres para uso.",
    "CALL MFILES",
    "_MFILES",
    "No lugar da palavra CALL pode-se utilizar o sinal de sublinhado (_). Por exemplo: _MFILES. " +
    "Este comando so sera aceito depois da execucao da instrucao CALL MEMINI. Caso a instrucao " +
    "CALL MEMINI nao tenha sido executada ou a RAMDISK tenha sido eliminada pela instrucao CALL " +
    "MEMINI (0), sera emitida a mensagem de erro " + MSXQ + "disk offline" + MSXQ + ".",
    "_MEMINI" + #CRLF$ +
    "10 PRINT " + MSXQ + "TESTE " + MSXQ + "; : GOTO 10" + #CRLF$ +
    "SAVE " + MSXQ + "MEM:TESTE.BAS" + MSXQ + #CRLF$ +
    "NEW" + #CRLF$ +
    "_MFILES" + #CRLF$ +
    "LOAD " + MSXQ + "MEM:TESTE.BAS" + MSXQ + #CRLF$ +
    "LIST" + #CRLF$ +
    "RUN",
    29)

  MSXDict_Add2Plus("CALL MKILL", #False, #False, "(mem kill)",
    "Apaga um arquivo armazenado na RAMDISK.",
    "CALL MKILL (" + MSXQ + "nome do arquivo" + MSXQ + ")",
    "_MKILL " + MSXQ + "TESTE.BAS" + MSXQ,
    "No lugar da palavra CALL pode-se utilizar o sinal de sublinhado (_). Este comando so sera " +
    "aceito depois da execucao da instrucao CALL MEMINI. Caso a instrucao CALL MEMINI nao tenha " +
    "sido executada ou a RAMDISK tenha sido eliminada pela instrucao CALL MEMINI (0), sera " +
    "emitida a mensagem de erro " + MSXQ + "disk offline" + MSXQ + ".",
    "_MEMINI" + #CRLF$ +
    "10 PRINT " + MSXQ + "TESTE " + MSXQ + "; : GOTO 10" + #CRLF$ +
    "SAVE " + MSXQ + "MEM:TESTE.BAS" + MSXQ + #CRLF$ +
    "_MFILES" + #CRLF$ +
    "_MKILL " + MSXQ + "TESTE.BAS" + MSXQ + #CRLF$ +
    "_MFILES",
    30)

  MSXDict_Add2Plus("CALL MNAME", #False, #False, "(mem name)",
    "Troca o nome de um arquivo gravado na RAMDISK.",
    "CALL MNAME(" + MSXQ + "nome arquivo 1" + MSXQ + " as " + MSXQ + "nome arq 2" + MSXQ + ")",
    "_MNAME (" + MSXQ + "TESTE.BAS" + MSXQ + " AS " + MSXQ + "PROG.BAS" + MSXQ + ")",
    "O " + MSXQ + "nome do arquivo 1" + MSXQ + " e o nome ja gravado na RAMDISK e o " + MSXQ + "nome do " +
    "arquivo 2" + MSXQ + " e aquele que substituira o antigo. No lugar da palavra CALL pode-se " +
    "utilizar o sinal de sublinhado (_). Este comando so sera aceito depois da execucao da " +
    "instrucao CALL MEMINI. Caso a instrucao CALL MEMINI nao tenha sido executada ou a RAMDISK " +
    "tenha sido eliminada pela instrucao CALL MEMINI (0), sera emitida a mensagem de erro " +
    MSXQ + "disk offline" + MSXQ + ".",
    "_MEMINI" + #CRLF$ +
    "10 PRINT " + MSXQ + "TESTE " + MSXQ + "; : GOTO 10" + #CRLF$ +
    "SAVE " + MSXQ + "MEM:TESTE.BAS" + MSXQ + #CRLF$ +
    "_MFILES" + #CRLF$ +
    "_MNAME (" + MSXQ + "TESTE.BAS" + MSXQ + " AS " + MSXQ + "PROG.BAS" + MSXQ + ")" + #CRLF$ +
    "_MFILES",
    31)
EndProcedure

; --- PAD e PDL estendidos (paginas 31-33 do manual ACVS) ---
Procedure MSXDict_BuildMSX2Plus_Input()
  MSXDict_Add2Plus("PAD (MSX2+)", #True, #False, "(pad)",
    "Retorna o estado da TOUCHPAD, LIGHTPEN, MOUSE ou TRACKBALL que estejam ligados as entradas " +
    "de JOYSTICK - versao MSX2+.",
    "PAD X",
    "PRINT PAD(3)",
    "X deve ser um numero inteiro entre 0 e 19 e tem o seguinte significado:" + #CRLF$ +
    "- Se X estiver entre 0 e 3 presume-se que ha uma TOUCHPAD ligada na tomada do JOYSTICK 1." + #CRLF$ +
    "- Se X estiver entre 4 e 7 presume-se que ha uma TOUCHPAD ligada na tomada do JOYSTICK 2." + #CRLF$ +
    "- Se X estiver entre 8 e 11 presume-se que tenha uma LIGHTPEN ligada na tomada do JOYSTICK." + #CRLF$ +
    "- Se X estiver entre 12 e 15 presume-se que tenha um MOUSE ou TRACKBALL ligado na tomada do " +
    "JOYSTICK 1." + #CRLF$ +
    "- Se X estiver entre 16 e 19 presume-se que tenha um MOUSE ou TRACKBALL ligado na tomada do " +
    "JOYSTICK 2." + #CRLF$ + #CRLF$ +
    "Nos casos acima se X for igual a:" + #CRLF$ +
    "- 0 ou 4 - retorna o estado da mesa da TOUCHPAD: 0 se nao foi tocada ou -1 se foi tocada." + #CRLF$ +
    "- 1 ou 5 - retorna a coordenada X do ponto onde a mesa foi tocada." + #CRLF$ +
    "- 2 ou 6 - retorna a coordenada Y do ponto onde a mesa foi tocada." + #CRLF$ +
    "- 3 ou 7 - retorna o estado do botao da TOUCHPAD. O resultado sera: 0 (botao nao " +
    "pressionado) ou -1 (botao pressionado)." + #CRLF$ +
    "- 8 - retorna o estado da LIGHTPEN: 0 se as coordenadas nao estiverem prontas ou -1 se as " +
    "coordenadas estiverem prontas." + #CRLF$ +
    "- 9 - retorna a coordenada X da posicao da LIGHTPEN." + #CRLF$ +
    "- 10 - retorna a coordenada Y da posicao da LIGHTPEN." + #CRLF$ +
    "- 11 - retorna o estado do botao da LIGHTPEN: 0 (botao nao pressionado) ou -1 (botao " +
    "pressionado)." + #CRLF$ +
    "- 12 ou 16 - retorna o estado do MOUSE ou TRACKBALL: e sempre -1." + #CRLF$ +
    "- 13 ou 17 - retorna a coordenada X do MOUSE ou TRACKBALL." + #CRLF$ +
    "- 14 ou 18 - retorna a coordenada Y do MOUSE ou TRACKBALL." + #CRLF$ +
    "- 15 ou 19 - retorna sempre 0." + #CRLF$ + #CRLF$ +
    "A leitura do estado dos botoes do MOUSE ou TRACKBALL e feita com a instrucao STRIG." + #CRLF$ + #CRLF$ +
    "Antes de ler as coordenadas do MOUSE ou TRACKBALL e obrigatoria a execucao da funcao PAD " +
    "(12) ou PAD (16) dependendo da tomada onde o MOUSE ou TRACKBALL estejam ligados." + #CRLF$ + #CRLF$ +
    "Antes de ler as coordenadas da LIGHTPEN, verifique se a funcao PAD(8) retorna o valor -1." + #CRLF$ + #CRLF$ +
    "A funcao PAD so tera validade se algum dos acessorios (TOUCHPAD, LIGHTPEN, MOUSE ou " +
    "TRACKBALL) estiver ligado ao computador." + #CRLF$ + #CRLF$ +
    "- TOUCHPAD e uma pequena prancheta usada para desenhos com sensores em toda a sua extensao " +
    "que, ao serem tocados, transmitem ao computador as coordenadas X,Y. Para acompanhar os " +
    "tracos do desenho e usada uma caneta com dois botoes: um como nos JOYSTICKS e outro que e " +
    "acionado quando a caneta toca a superficie da prancheta." + #CRLF$ +
    "- LIGHTPEN e uma caneta com um sensor de luz na ponta que, quando encostada na tela do " +
    "monitor ou televisor, transmite ao computador a sua posicao em coordenadas X,Y. A Lightpen " +
    "possui dois botoes: um como nos JOYSTICKS e outro que e o sensor quando cruza com um raio " +
    "luminoso na tela." + #CRLF$ +
    "- MOUSE e um controlador manual com uma esfera na sua parte inferior e dois botoes como nos " +
    "JOYSTICKS. A movimentacao do MOUSE sobre qualquer superficie faz com que a esfera movimente " +
    "duas rodas perfuradas, uma para o eixo X e outra para o eixo Y. Estas rodas geram uma " +
    "sequencia de pulsos que sao transformados em coordenadas pelo computador." + #CRLF$ +
    "- TRACKBALL e semelhante ao MOUSE, porem, a esfera fica na parte superior do controlador. " +
    "Ao contrario do Mouse, sua esfera e controlada pela mao do operador que a faz girar para o " +
    "lado desejado.",
    "",
    31)

  MSXDict_Add2Plus("PDL (MSX2+)", #True, #False, "(paddle)",
    "Retorna o estado de PADDLES ligados ao computador - versao MSX2+, com ate 12 paddles.",
    "PDL (X)",
    "PRINT PDL(1) : GOTO 10",
    "Ate 12 (doze) PADDLES podem ser ligados as entradas de JOYSTICK (6 na entrada A e 6 na B). " +
    "Se X for 1, 3, 5, 7, 9 ou 11 presume-se que os PADDLES estejam ligados na entrada do " +
    "JOYSTICK-1 (A). Se for 2, 4, 6, 8, 10 ou 12 presume-se que estejam ligados na entrada do " +
    "JOYSTICK-2 (B). Esta funcao retorna um valor entre 0 e 255. PADDLEs sao controles rotativos " +
    "utilizados em jogos ou programas que tem movimentos em duas direcoes (direita e esquerda " +
    "por exemplo). A funcao PDL(X) so e valida com um ou mais PADDLES ligados ao micro.",
    "10 PRINT PDL(1) : GOTO10",
    33)
EndProcedure

; --- BASE e VDP estendidos (paginas 34-35 do manual ACVS) ---
Procedure MSXDict_BuildMSX2Plus_Vdp()
  MSXDict_Add2Plus("BASE (MSX2+)", #True, #False, "(base)",
    "Mostra o endereco do primeiro byte das tabelas do processador de video (VDP) ou escreve um " +
    "endereco inicial nos registradores das tabelas do VDP - versao MSX2+, com mais registros de " +
    "tabela (0 a 44) para as SCREENs 0 a 8.",
    "BASE (X) ou BASE (X) = Y",
    "PRINT BASE(0)",
    "(X) deve ser sempre uma expressao de numeros inteiros entre 0 e 44 que, dependendo da " +
    "SCREEN utilizada, tem o significado dado pela tabela a seguir (SCREEN 0 a 8):" + #CRLF$ +
    "- Tabela Nomes: SCREEN 0=0, 1=5, 2=10, 3=15, 4=20, 5=25, 6=30, 7=35, 8=40" + #CRLF$ +
    "- Tabela Cores: SCREEN 1=6, 2=11, 3=16, 4=21, 5=26, 6=31, 7=36, 8=41" + #CRLF$ +
    "- Tabela Caracteres: SCREEN 0=2, 1=7, 2=12, 3=17, 4=22, 5=27, 6=32, 7=37, 8=42" + #CRLF$ +
    "- Tabela Atrib Sprites: SCREEN 1=8, 2=13, 3=18, 4=23, 5=28, 6=33, 7=38, 8=43" + #CRLF$ +
    "- Tabela Formato Sprites: SCREEN 1=9, 2=14, 3=19, 4=24, 5=29, 6=34, 7=39, 8=44" + #CRLF$ + #CRLF$ +
    "Quando se le um endereco com a funcao BASE (X), o valor de X pode variar entre 0 e 44. Para " +
    "se escrever um valor nos registradores do VDP com a funcao BASE (X) = Y, o valor de X so " +
    "pode variar entre 0 e 19, ou seja, somente as SCREENs 0, 1, 2 e 3 sao afetadas. Quando se " +
    "troca um endereco na SCREEN 3, os enderecos das SCREENs 4, 5, 6, 7 e 8 tambem sao alterados. " +
    "Os dados da SCREEN 8 valem tambem para as SCREENs 10, 11 e 12." + #CRLF$ + #CRLF$ +
    "OBS: Use esta funcao ou instrucao somente quando estiver bem familiarizado com o modo de " +
    "trabalho do processador de video (VDP).",
    "100 'Enche duas telas" + #CRLF$ +
    "110 SCREEN0:WIDTH40:KEYOFF" + #CRLF$ +
    "140 FORA=0TO959:PRINT" + MSXQ + "-" + MSXQ + ";:NEXT" + #CRLF$ +
    "150 BASE(0)=1024:SCREEN0" + #CRLF$ +
    "160 FORA=0TO959:PRINT" + MSXQ + "+" + MSXQ + ";:NEXT" + #CRLF$ +
    "180 'Alterna as paginas de texto" + #CRLF$ +
    "200 BASE(0)=0" + #CRLF$ +
    "210 FORT=0TO100:NEXT" + #CRLF$ +
    "220 BASE(0)=1024" + #CRLF$ +
    "230 FORT=0TO100:NEXT" + #CRLF$ +
    "240 GOTO200" + #CRLF$ + #CRLF$ +
    "Outro exemplo: PRINT BASE(0)",
    34)

  MSXDict_Add2Plus("VDP (MSX2+)", #True, #False, "(video display processor)",
    "Verifica ou altera o conteudo dos registradores do processador de video (VDP) - versao " +
    "MSX2+, com registros extras (status -9 a -1, e 9 a 47).",
    "VDP (X) ou VDP (X) = Y",
    "A=VDP(0)",
    "X e um numero inteiro e pode variar entre:" + #CRLF$ +
    "- -9 e -1 - registradores de STATUS 1 a 9." + #CRLF$ +
    "- 0 e 8 - mesmos do MSX1." + #CRLF$ +
    "- 9 e 24 - registradores de 8 a 23." + #CRLF$ +
    "- 33 e 47 - registradores de 32 a 46." + #CRLF$ + #CRLF$ +
    "Esta instrucao so deve ser utilizada quando se estiver bem familiarizado com o " +
    "funcionamento do processador de video (VDP).",
    "10 FOR R=-9 TO 8" + #CRLF$ +
    "20 A=VDP(R)" + #CRLF$ +
    "30 PRINT " + MSXQ + "Registro:" + MSXQ + ";R;" + MSXQ + " = " + MSXQ + ";RIGHT$(" + MSXQ + "0000000" + MSXQ + "+BIN$(A),8)" + #CRLF$ +
    "40 NEXT",
    35)
EndProcedure

; --- FM-Music: CALL MUSIC, CALL VOICE, PLAY estendido (paginas 38-42) ---
Procedure MSXDict_BuildMSX2Plus_FMBasics()
  MSXDict_Add2Plus("CALL MUSIC", #False, #False, "(music)",
    "Define os canais de som que serao utilizados, bem como se sera ou nao usada a bateria " +
    "eletronica.",
    "CALL MUSIC (BT,0,C1,C2,C3,C4,...,[C8],[C9])",
    "CALL MUSIC (1,0,1,1,1,1,1)",
    "Com este comando e possivel tambem a concatenacao de canais, respeitando-se o limite " +
    "disponivel (6 canais com bateria ou 9 canais sem bateria)." + #CRLF$ + #CRLF$ +
    "O primeiro parametro <BT> pode ser 0 ou 1. Se 0, nao sera utilizada a bateria. Se 1, os 3 " +
    "canais de bateria serao ativados." + #CRLF$ + #CRLF$ +
    "O segundo parametro deve ser obrigatoriamente 0. Qualquer valor diferente de 0 gerara uma " +
    "mensagem de erro." + #CRLF$ + #CRLF$ +
    "Os parametros de <C1> a <C9> referem-se ao chaveamento de canais de som. Esses parametros " +
    "devem conter um numero de 1 a 6 (ou de 1 a 9 dependendo da bateria). Esse numero indicara o " +
    "maximo de vozes que sera tocado ou mixado nesse canal." + #CRLF$ + #CRLF$ +
    "Ex: CALL MUSIC (1,0,1,1,1,1,1). Com esse comando sera acionada a bateria e cada um dos 6 " +
    "canais de som disponiveis podera tocar uma voz (instrumento) diferente." + #CRLF$ + #CRLF$ +
    "CALL MUSIC (0,0,2,1,1,1). Neste exemplo, nao sera utilizada a bateria e teremos 3 dos 9 " +
    "canais disponiveis, sendo que o primeiro (que contem o no 2) podera tocar ate dois " +
    "instrumentos mixados." + #CRLF$ + #CRLF$ +
    "E importante observar que a concatenacao de canais (como no exemplo acima) so pode ser " +
    "feita respeitando-se o numero maximo de canais do FM. Sendo assim, a soma dos parametros " +
    "(apenas dos canais) nao devera ultrapassar o limite de 6 (com bateria) ou 9 (sem bateria). " +
    "Nesse caso: CALL MUSIC (1,0,2,2,2,2) Gerara uma mensagem de erro.",
    "",
    38)

  MSXDict_Add2Plus("CALL VOICE", #False, #False, "(voice)",
    "Define os instrumentos que serao utilizados em cada canal.",
    "CALL VOICE (@I1,@I2,@I3,@I4,......,[@I8],[@I9])",
    "CALL VOICE (@00,@03,@43)",
    "Estao disponiveis 64 instrumentos. Os de 0 a 62 sao os instrumentos normais " +
    "(pre-definidos) e o 63 e o instrumento programavel que nao possui som algum. Os labels de " +
    "<I1> a <I9> deverao ser substituidos pelos numeros dos instrumentos. Deverao ser sempre " +
    "precedidos por " + MSXQ + "@" + MSXQ + "." + #CRLF$ + #CRLF$ +
    "Ex: CALL VOICE (@00,@03,@43). Esse comando definiu a utilizacao de PIANO no canal 1, FLAUTA " +
    "no canal 2 e VIOLINO no canal 3." + #CRLF$ + #CRLF$ +
    "CALL VOICE (@02,@16,@01,@01,@01). Nesse exemplo ficou definida a utilizacao de CORDAS no " +
    "canal 1, VIBRAPHONE no canal 2, e PIANO II nos canais 3, 4 e 5." + #CRLF$ + #CRLF$ +
    "LEMBRE-SE que o numero de canais depende da instrucao CALL MUSIC e que, caso seja definido " +
    "algum canal com concatenacao, o comando CALL VOICE devera conter os instrumentos que serao " +
    "usados em cada canal concatenado. Assim, ao se executar: CALL MUSIC (0,0,3):CALL VOICE " +
    "(@00,@36,@02). Voce ira tocar a nota Do (C) com PIANO, FLAUTA e CORDAS mixados, no primeiro " +
    "(e unico) canal." + #CRLF$ + #CRLF$ +
    "OBS: No APENDICE C, ha uma relacao com todos os instrumentos pre-definidos.",
    "",
    39)

  ; A entrada PLAY do dicionario MSX1 ja documenta a sintaxe do PSG puro
  ; (3 canais, sem parametro #n) - este verbete cobre so a extensao FM
  ; (PLAY#n com os canais adicionais de sintese FM e a bateria) descrita
  ; nas paginas 40-42 do manual ACVS.
  MSXDict_Add2Plus("PLAY (MSX2+/FM-Music)", #False, #False, "(play)",
    "Toca a musica de acordo com os parametros nele definidos (nota, volume, duracao, tempo, " +
    "etc.) - versao MSX2+/FM-Music, com canais adicionais de FM alem dos 3 canais do PSG.",
    "PLAY#n,C1,C2,....,C8,C9,PSG1,PSG2,PSG3",
    "PLAY#2,C1,C2,C3,C4,C5,C6,C7,C8,C9,PSG1,PSG2,PSG3",
    "O comando PLAY original do MSX sofreu uma pequena alteracao: recebeu um parametro a mais, " +
    "o #<n>, para indicar que estamos nos reportando ao FM." + #CRLF$ + #CRLF$ +
    "PLAY#<n>,<C1>,<C2>,<C3>,<C4>,<C5>,<C6>,<C7>,<C8>,<C9>,<PSG1>,<PSG2>,<PSG3>" + #CRLF$ + #CRLF$ +
    "Esta primeira sintaxe se refere a utilizacao sem bateria. Nesse caso, teremos 9 canais " +
    "disponiveis, (<C1> a <C9>), mais os 3 canais do PSG, (<PSG1> a <PSG3>)." + #CRLF$ + #CRLF$ +
    "ou" + #CRLF$ + #CRLF$ +
    "PLAY#<n>,<C1>,<C2>,<C3>,<C4>,<C5>,<C6>,<BT>,<PSG1>,<PSG2>,<PSG3>" + #CRLF$ + #CRLF$ +
    "Nesta segunda sintaxe utilizamos a bateria (lembre-se que isso depende do comando CALL " +
    "MUSIC). Nesse caso, teremos 6 canais (<C1> a <C6>), a bateria (<BT>) e os 3 canais do PSG " +
    "(<PSG1> a <PSG3>). Note que a bateria nao faz parte dos canais de musica. Ela sera definida " +
    "sempre depois do ultimo canal musical. Assim, se fizermos: CALL MUSIC (1,0,1,1,1,1,1). " +
    "Teremos que definir a bateria no quinto canal do comando PLAY: PLAY#2,C1,C2,C3,C4,BT." + #CRLF$ + #CRLF$ +
    "O <n> pode ser substituido por 0, 2 ou 3. Se for 2 ou 3, valem as sintaxes acima " +
    "explicadas. Se for 0, indica que estaremos trabalhando apenas com o PSG. Assim, o comando " +
    "PLAY nao podera ultrapassar 3 canais: PLAY0,PSG1,PSG2,PSG3." + #CRLF$ + #CRLF$ +
    "Todos os labels acima mostrados (<C1> a <C9>, <BT>, <PSG1> a <PSG3>) deverao ser " +
    "substituidos por parametros colocados entre " + MSXQ + " " + MSXQ + " (aspas)." + #CRLF$ + #CRLF$ +
    "PARAMETROS PARA SOM:" + #CRLF$ +
    "- @n - Muda o instrumento dentro do PLAY. n pode variar de 0 a 63 (igual ao CALL VOICE). O " +
    "default e 0." + #CRLF$ +
    "- Vn - Altera o volume do som. n pode variar de 0 a 15 e o default e 8." + #CRLF$ +
    "- Tn - Muda o tempo da musica (andamento). n pode ser de 32 a 255, default e 120." + #CRLF$ +
    "- Ln - Altera a duracao de cada nota. n varia de 1 a 64. O default e 4." + #CRLF$ +
    "- On - Define a oitava nota utilizada. n pode variar de 1 a 8 sendo o default 4." + #CRLF$ +
    "- Qn - Muda o " + MSXQ + "decay" + MSXQ + " (finalizacao) das notas. n pode ser de 1 a 64. default e 8." + #CRLF$ +
    "- Nn - Toca uma nota especificada pelo seu numero. n pode ser de 0 a 96." + #CRLF$ +
    "- Rn - Pausa por n tempos. n varia de 1 a 64. O default e 4." + #CRLF$ +
    "- " + MSXQ + "." + MSXQ + " - Quando colocado ao lado da nota, determina que esta sera tocada por mais " +
    "1/2 tempo de seu valor original." + #CRLF$ +
    "- @Vn - Assim como o V, esse comando altera o volume do som mas cobre uma faixa de valores " +
    "maior do que o V. n pode ser de 0 a 127, o default e 127." + #CRLF$ +
    "- @Wn - Prolonga a execucao da ultima nota por n tempos. n pode ser de 1 a 64." + #CRLF$ +
    "- " + MSXQ + "&" + MSXQ + " - Faz a " + MSXQ + "juncao de 2 notas de mesmo valor" + MSXQ + "." + #CRLF$ +
    "- " + MSXQ + ">" + MSXQ + " - Aumenta 1 (uma) oitava." + #CRLF$ +
    "- " + MSXQ + "<" + MSXQ + " - Diminui 1 (uma) oitava." + #CRLF$ +
    "- Sn e Mn - Comandos para geracao de envelopes. So funcionam com o PSG. Para maiores " +
    "detalhes, consulte o manual de BASIC MSX." + #CRLF$ + #CRLF$ +
    "NOTAS MUSICAIS: C (do), D (re), E (mi), F (fa), G (sol), A (la), B (si). As notas podem " +
    "estar acompanhadas de um numero (de 1 a 64) indicando sua duracao. Se nao especificado, e " +
    "assumido o valor do parametro L." + #CRLF$ +
    "- " + MSXQ + "#" + MSXQ + " ou " + MSXQ + "+" + MSXQ + " - Acompanhado da nota, indica que esta sera SUSTENIDA (1/2 tom " +
    "acima)." + #CRLF$ +
    "- " + MSXQ + "-" + MSXQ + " - Indica que a nota sera BEMOL (1/2 tom abaixo)." + #CRLF$ + #CRLF$ +
    "Yn1,n2 - Altera a definicao de alguns instrumentos pre-definidos." + #CRLF$ + #CRLF$ +
    "PARAMETROS PARA BATERIA:" + #CRLF$ +
    "- @An - Indica o volume dos instrumentos tocados em primeiro plano (com enfase). n pode " +
    "ser de 0 a 15, o default e 12." + #CRLF$ +
    "- Vn - Indica o volume dos instrumentos tocados em segundo plano. Identico ao V do SOM." + #CRLF$ +
    "- Tn - Identico ao T do SOM." + #CRLF$ +
    "- @Vn - Define o volume geral (primeiro e segundo planos). Identico ao @V do SOM." + #CRLF$ +
    "- " + MSXQ + "!" + MSXQ + " - Enfase no instrumento (este e tocado no primeiro plano)." + #CRLF$ +
    "- Rn - Identico ao R do SOM." + #CRLF$ +
    "- Yn1,n2 - Permite alterar o som dos instrumentos da bateria (maiores detalhes, consulte o " +
    "comando CALL AUDREG)." + #CRLF$ + #CRLF$ +
    "INSTRUMENTOS DE BATERIA:" + #CRLF$ +
    "- B - Bumbo" + #CRLF$ +
    "- H - Hi-Hat" + #CRLF$ +
    "- C - Chimbau" + #CRLF$ +
    "- S - Caixa" + #CRLF$ +
    "- M - Tom Tom" + #CRLF$ + #CRLF$ +
    "Os instrumentos de bateria devem, obrigatoriamente, vir acompanhados do valor de duracao " +
    "(de 1 a 64). E possivel tocar ate 5 instrumentos ao mesmo tempo, colocando um ao lado do " +
    "outro e, no final, o valor de duracao." + #CRLF$ + #CRLF$ +
    "Ex: CALL MUSIC (1):PLAY#2," + MSXQ + "BC4" + MSXQ + ". Tocara o BUMBO e o CHIMBAU juntos. Quando " +
    "colocados dessa forma, os sons dos instrumentos aparecem em segundo plano. Para tocar um " +
    "instrumento em primeiro plano, deve-se colocar o sinal " + MSXQ + "!" + MSXQ + " logo apos." + #CRLF$ + #CRLF$ +
    "CALL MUSIC (1):PLAY#2," + MSXQ + "B!H4" + MSXQ + ". Tocara o BUMBO em primeiro plano junto com o " +
    "HI-HAT em segundo plano. E importante ressaltar que os instrumentos tocados no primeiro " +
    "plano somente terao enfase se o volume sonoro do segundo plano for menor.",
    "CALL MUSIC (0,0,1,1,1)" + #CRLF$ +
    "PLAY#2," + MSXQ + "V15O4@00C1G1F1" + MSXQ + "," + MSXQ + "V15O4@00E1B1A1" + MSXQ + "," + MSXQ + "V15O4@00G1>D1C1" + MSXQ + #CRLF$ +
    "'Nesse exemplo, serao tocados 3 acordes: DO maior, SOL maior e FA maior com som de PIANO " +
    "(@00)." + #CRLF$ + #CRLF$ +
    "CALL MUSIC (1,0)" + #CRLF$ +
    "PLAY #2," + MSXQ + "@A15V0B!H8H8S!H8B!H8B!H8H8S!H8C!H8" + MSXQ + #CRLF$ +
    "'Aqui e possivel ouvir um ritmo de bateria (ROCK). Note como foi utilizada a juncao de " +
    "instrumentos de bateria." + #CRLF$ + #CRLF$ +
    "CALL MUSIC (0,0,3)" + #CRLF$ +
    "POKE &HFA3C,40:POKE &HFA4C,80" + #CRLF$ +
    "CALL VOICE (@53,@53,@53)" + #CRLF$ +
    "PLAY #2," + MSXQ + "V15O4C1<G1A1F1" + MSXQ + #CRLF$ +
    "'Neste ultimo exemplo, serao tocados algumas notas com o instrumento 53 (HARDROCK) " +
    "apresentando uma leve reverberacao (explicada no APENDICE B).",
    40)
EndProcedure

; --- FM-Music: CALL PITCH/TRANSPOSE/TEMPER/PLAY/STOPM/BGM/AUDREG/VOICECOPY (paginas 43-47) ---
Procedure MSXDict_BuildMSX2Plus_FMControl()
  MSXDict_Add2Plus("CALL PITCH", #False, #False, "(pitch)",
    "Altera a velocidade tonal da musica.",
    "CALL PITCH (n)",
    "CALL PITCH (459)",
    "E util quando se deseja acertar a afinacao dos instrumentos pois atua sobre todos os " +
    "canais. n pode ser um numero de 410 a 459 (410 mais lento, 459 mais rapido). O default e " +
    "440.",
    "CALL MUSIC (0,0,1)" + #CRLF$ +
    "PLAY #2," + MSXQ + "V15C" + MSXQ + #CRLF$ +
    "CALL PITCH (459)" + #CRLF$ +
    "PLAY #2," + MSXQ + "V15C" + MSXQ + #CRLF$ +
    "CALL PITCH (410)" + #CRLF$ +
    "PLAY #2," + MSXQ + "V15C" + MSXQ,
    43)

  MSXDict_Add2Plus("CALL TRANSPOSE", #False, #False, "(transpose)",
    "Semelhante ao PITCH, porem, cobre uma faixa maior de valores.",
    "CALL TRANSPOSE (n)",
    "CALL TRANSPOSE (0)",
    "n pode ser qualquer numero entre -12799 e 12799 sendo a cada 100 valores aumentado (ou " +
    "diminuido) meio tom. O default e 0.",
    "CALL MUSIC (0,0,1)" + #CRLF$ +
    "CALL TRANSPOSE (0)" + #CRLF$ +
    "PLAY #2," + MSXQ + "V15C" + MSXQ + #CRLF$ +
    "CALL TRANSPOSE (-500)" + #CRLF$ +
    "PLAY #2," + MSXQ + "V15C" + MSXQ + #CRLF$ +
    "CALL TRANSPOSE (500)" + #CRLF$ +
    "PLAY #2," + MSXQ + "V15C" + MSXQ + #CRLF$ + #CRLF$ +
    "'Digitando esses comandos voce notara a mudanca entre diferentes valores do TRANSPOSE.",
    43)

  MSXDict_Add2Plus("CALL TEMPER", #False, #False, "(temper)",
    "Serve para afinar os instrumentos.",
    "CALL TEMPER (n)",
    "CALL TEMPER (0)",
    "n deve ser um numero entre 0 e 21.",
    "CALL MUSIC (0,0,1)" + #CRLF$ +
    "CALL TEMPER (0)" + #CRLF$ +
    "PLAY #2," + MSXQ + "@12L8CDEFGAB" + MSXQ + #CRLF$ +
    "CALL TEMPER (21)" + #CRLF$ +
    "PLAY #2," + MSXQ + "@12L8CDEFGAB" + MSXQ + #CRLF$ + #CRLF$ +
    "'Note que o som gerado pelo segundo exemplo esta " + MSXQ + "desafinado" + MSXQ + ".",
    44)

  MSXDict_Add2Plus("CALL PLAY", #False, #False, "(play)",
    "Indica se os canais de FM estao ou nao ativos (tocando).",
    "CALL PLAY (nc,var)",
    "CALL PLAY (3,A):PRINT A",
    "<nc> e o numero do canal que se deseja saber se esta ou nao tocando. Se <nc> for 0 sera " +
    "possivel saber se existe algum canal ativo. Enquanto um deles estiver tocando o valor " +
    "devolvido sera -1, caso contrario, sera 0. Com <nc> de 1 a 9, voce sabera apenas o estado " +
    "(ativo ou nao) do canal escolhido." + #CRLF$ + #CRLF$ +
    "<var> e a variavel numerica onde sera colocado o valor devolvido. Ela contera 0 caso o(s) " +
    "canal(is) nao esteja(m) tocando e, -1 se estiver(em) tocando.",
    "CALL PLAY (3,A):PRINT A" + #CRLF$ +
    "'Le o estado do canal 3 e retorna o resultado para a variavel " + MSXQ + "A" + MSXQ + ". Como nao " +
    "tocamos nota nenhuma, o valor devolvido sera 0." + #CRLF$ + #CRLF$ +
    "CALL MUSIC (0,0,1)" + #CRLF$ +
    "PLAY #2," + MSXQ + "V15C" + MSXQ + ":CALL PLAY (0,A):PRINT A" + #CRLF$ +
    "'Esse exemplo ira tocar uma nota enquanto le o estado do canal 1. Obviamente o valor " +
    "devolvido sera -1.",
    44)

  MSXDict_Add2Plus("CALL STOPM", #False, #False, "(stop music)",
    "Determina uma parada na musica no ponto em que se encontra.",
    "CALL STOPM",
    "CALL STOPM",
    "Como sabemos, o processador Z80 trabalha a uma velocidade maior que o processador de " +
    "audio (PSG) e o FM. Portanto, quando executamos uma ou varias notas, algumas vezes, o " +
    "controle e devolvido para o BASIC antes mesmo de haver terminado a sequencia de notas, o " +
    "que faz com que os proximos comandos (no caso de um programa), apos a instrucao PLAY, " +
    "sejam executados antes do termino da musica.",
    "'EXEMPLO SEM STOPM" + #CRLF$ +
    "10 CLS:LOCATE10,10:PRINT" + MSXQ + "EXEMPLO SEM STOPM" + MSXQ + #CRLF$ +
    "20 CALL MUSIC (0,0,1)" + #CRLF$ +
    "30 PLAY#2," + MSXQ + "V15@4104CDEFGAB>CDEFGAB" + MSXQ + #CRLF$ +
    "40 CLS" + #CRLF$ +
    "'Ao executar esse programa voce notara que a tela sera limpa antes de terminar a musica." + #CRLF$ + #CRLF$ +
    "'EXEMPLO COM STOPM" + #CRLF$ +
    "10 CLS:LOCATE10,10:PRINT" + MSXQ + "EXEMPLO COM STOPM" + MSXQ + #CRLF$ +
    "20 CALL MUSIC (0,0,1)" + #CRLF$ +
    "30 PLAY#2," + MSXQ + "V15@4104CDEFGAB>CDEFGAB" + MSXQ + #CRLF$ +
    "40 CALL STOPM" + #CRLF$ +
    "50 CLS" + #CRLF$ +
    "'Nesse exemplo a tela sera limpa simultaneamente a interrupcao da musica.",
    45)

  MSXDict_Add2Plus("CALL BGM", #False, #False, "(background music)",
    "Sincroniza o processador Z80 com os processadores de audio FM e PSG, evitando que os " +
    "comandos, apos uma instrucao PLAY, sejam executados antes do termino da musica.",
    "CALL BGM (n)",
    "CALL BGM (1)",
    "n pode ser 0 ou 1. Se for 1, o recurso estara desativado. Dessa forma o processador Z80 " +
    "terminara sempre primeiro. Se for 0, o recurso sera ativado e os processadores executarao " +
    "suas tarefas juntos. O default e 1.",
    "'EXEMPLO SEM BGM" + #CRLF$ +
    "10 CLS:LOCATE10,10:PRINT" + MSXQ + "EXEMPLO SEM BGM" + MSXQ + #CRLF$ +
    "20 CALL MUSIC (0,0,1):CALL BGM (1)" + #CRLF$ +
    "30 PLAY#2," + MSXQ + "V15@4104CDEFGAB>CDEFGAB" + MSXQ + ":CLS" + #CRLF$ +
    "'Neste exemplo, a tela sera limpa antes da musica terminar." + #CRLF$ + #CRLF$ +
    "'EXEMPLO COM BGM" + #CRLF$ +
    "10 CLS:LOCATE10,10:PRINT" + MSXQ + "EXEMPLO COM BGM" + MSXQ + #CRLF$ +
    "20 CALL MUSIC (0,0,1):CALL BGM (0)" + #CRLF$ +
    "30 PLAY#2," + MSXQ + "V15@4104CDEFGAB>CDEFGAB" + MSXQ + ":CLS" + #CRLF$ +
    "'Neste outro exemplo, a tela so sera limpa apos todas as notas terem sido executadas.",
    45)

  ; CONFERIR: a string de PLAY# nos dois exemplos abaixo e muito densa
  ; (parametros de bateria concatenados sem separadores visuais) - alto
  ; risco de erro pontual de transcricao; conferir contra a pagina 46 do
  ; manual original se for realmente executar este exemplo.
  MSXDict_Add2Plus("CALL AUDREG", #False, #False, "(audio register)",
    "Altera o som dos instrumentos da bateria.",
    "CALL AUDREG (n1,n2)",
    "CALL AUDREG (24,0)",
    "<n1> devera ser um numero com os valores abaixo:" + #CRLF$ +
    "de 00 a 07;" + #CRLF$ +
    "de 14 a 24;" + #CRLF$ +
    "de 32 a 40;" + #CRLF$ +
    "de 48 a 56." + #CRLF$ + #CRLF$ +
    "Esse numero indicara o registrador a ser alterado. Valores de 8 a 13, de 25 a 31, de 41 a " +
    "47, e acima de 39, geram mensagem de erro. Note que essa numeracao e diferente da " +
    "numeracao normal dos instrumentos." + #CRLF$ + #CRLF$ +
    "<n2> pode ser qualquer numero inteiro, entre 0 e 255, e indicara o valor do atributo para " +
    "o registrador.",
    "CALL MUSIC (1)" + #CRLF$ +
    "PLAY #2," + MSXQ + "@A15V0B!H8H16B!16S!HBB!HBHBB!HBS!HBC!HB" + MSXQ + #CRLF$ +
    "CALL AUDREG (24,00)" + #CRLF$ +
    "PLAY #2," + MSXQ + "@A15V0B!H8H16B!16S!HBB!HBHBB!HBS!HBC!HB" + MSXQ + #CRLF$ +
    "'Com este exemplo, voce notara a mudanca no som do HI-HAT e do CHIMBAU." + #CRLF$ + #CRLF$ +
    "10 CALL MUSIC (1)" + #CRLF$ +
    "20 FOR F=0 TO 255" + #CRLF$ +
    "30 CALL AUDREG (23,F)" + #CRLF$ +
    "40 PLAY #2," + MSXQ + "V15S16" + MSXQ + #CRLF$ +
    "50 NEXT F" + #CRLF$ +
    "'Neste exemplo, e possivel perceber a variacao no som da CAIXA.",
    46)

  MSXDict_Add2Plus("CALL VOICECOPY", #False, #False, "(voice copy)",
    "Copia os valores dos registradores de som (definicao) de cada instrumento para uma " +
    "variavel de precisao dupla. Permite tambem que passemos uma definicao de instrumento (que " +
    "sao as informacoes necessarias para a composicao do som) contida numa variavel para os " +
    "registradores do instrumento 63 (programavel).",
    "CALL VOICECOPY (@ins,var%)",
    "CALL VOICECOPY (@1,A%)",
    "A primeira sintaxe demonstra como colocar a definicao de um instrumento (indicado por " +
    "<ins>, de 0 a 63) numa variavel de precisao dupla (indicada por <var>, seguida do simbolo " +
    "de porcentagem)." + #CRLF$ + #CRLF$ +
    "Alguns instrumentos, por motivos desconhecidos, nao sao visualizados (geram mensagem de " +
    "erro)." + #CRLF$ + #CRLF$ +
    "CALL VOICECOPY (<var>%,@63)" + #CRLF$ + #CRLF$ +
    "Neste outro exemplo, o instrumento 63 recebera os valores contidos na variavel <var>. Os " +
    "valores dos registradores estao divididos em 16 bytes de 16 bits cada, portanto, deverao " +
    "ser tratados em blocos de 16 bytes (isso sera melhor explicado no APENDICE A).",
    "10 CALL MUSIC:Y=0" + #CRLF$ +
    "20 CLEAR 1000:DIM A%(15)" + #CRLF$ +
    "30 CALL VOICECOPY (@1,A%)" + #CRLF$ +
    "40 FOR X=0 TO 3" + #CRLF$ +
    "50 PRINT RIGHT$(" + MSXQ + "0000" + MSXQ + "+HEX$(A%(X+Y)),4)" + MSXQ + " " + MSXQ + ";" + #CRLF$ +
    "60 NEXT X:Y=Y+4:PRINT:IF Y=16 THEN END ELSE 40" + #CRLF$ +
    "'No exemplo acima e possivel ver na tela a definicao hexadecimal do instrumento 1 (PIANO " +
    "II)." + #CRLF$ + #CRLF$ +
    "10 CALL MUSIC (0,0,3)" + #CRLF$ +
    "20 CLEAR 2000:DIMA%(15)" + #CRLF$ +
    "30 FOR I=0 TO 15" + #CRLF$ +
    "40 READ A$:A%(I)=VAL(" + MSXQ + "&H" + MSXQ + "+A$)" + #CRLF$ +
    "50 NEXT I" + #CRLF$ +
    "60 DATA 6847,736F,2074,2020" + #CRLF$ +
    "70 DATA 0000,00FF,0000,0000" + #CRLF$ +
    "80 DATA 1572,01AA,0000,0000" + #CRLF$ +
    "90 DATA 0131,02A0,0000,0000" + #CRLF$ +
    "100 CALL VOICECOPY (A%,@63):POKE &HFA3C,40:POKE &HFA3C,80" + #CRLF$ +
    "110 PLAY#2," + MSXQ + "V15@6303G1D1F1C1" + MSXQ + #CRLF$ +
    "'Neste outro exemplo o instrumento 63 recebeu uma definicao (contida nas linhas DATA), e " +
    "foi acionado (tocado)." + #CRLF$ + #CRLF$ +
    "OBS: Somente o instrumento 63 pode receber uma definicao do usuario. Os outros " +
    "instrumentos, que sao pre-programados, geram uma mensagem de erro.",
    47)
EndProcedure
