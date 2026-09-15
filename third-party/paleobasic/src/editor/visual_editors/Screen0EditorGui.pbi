;
; ------------------------------------------------------------
;  Apelido interno: Pixelossauro (tema pre-historico do projeto, ver README.md)
;  Screen0EditorGui.pbi - Criar -> Screen 0...: editor de tela de texto MSX
;  SCREEN 0, no espirito dos classicos editores de tela ANSI da era BBS
;  (TheDraw/AcidDraw/DarkDraw), mas fiel ao hardware MSX real: uma grade
;  fixa Width x 24 de CARACTERES (nao pixels), com UMA cor de tinta e UMA de
;  fundo pra tela INTEIRA (equivalente a COLOR fg,bg do MSX-BASIC) - SCREEN 0
;  real do MSX1 nao tem cor por celula, diferente de um editor ANSI de PC.
;  Cada tela grava sua propria largura (40 ou 80 colunas, WIDTH 40/80,
;  escolhida ao criar) e, opcionalmente, uma fonte customizada do banco de
;  alfabetos do projeto (Criar -> Alfabeto Graphos III...) - "fonte padrao"
;  usa o alfabeto embutido (ProjectDB::FetchDefaultAlphabet, ver
;  DefaultCharsetMsx.pbi).
;
;  Em telas de 80 colunas (WIDTH 80, modo T2 do VDP, MSX2+) o hardware real
;  tem um recurso a mais que 40 colunas nao tem: cada caractere pode usar um
;  SEGUNDO par de cor (Cor 2 - Ink2/Paper2), que pisca alternando com a cor
;  normal num ritmo configuravel ou fica travado permanentemente na cor 2
;  (zerando a duracao "normal") - mesmo mecanismo de hardware, so o tempo
;  "normal" chegando a zero. Confirmado contra o MSX2 Technical Handbook
;  (Konamiman) e a MSX Wiki, nao e suposicao: VDP R#12 = cor2 (BASIC:
;  VDP(13)=tinta2*16+fundo2), R#13 = duracoes (BASIC: VDP(14)=
;  duracaoNormal*16+duracaoCor2, cada unidade ~1/6s, 0-15 cada), tabela de
;  "pisca" (reaproveita o mecanismo da Color Table) 1 bit/caractere, 240
;  bytes, endereco padrao &H0800 no modo WIDTH 80 - ver Scr0Ed_BuildCode.
;  Ferramenta "Atributo" marca/desmarca quais celulas usam esse mecanismo.
;
;  Cada celula do grid guarda o CARACTERE UNICODE digitado/estampado (nao um
;  byte MSX cru) - ver Structure de armazenamento em ProjectDB::StoreScreen0/
;  FetchScreen0. Isso porque 31 dos 159 caracteres especiais que o pipeline
;  Dignified traduz (Dig_TransReplacementOrder em DignifiedPreprocessor.pbi -
;  box-drawing/naipes) precisam do escape de impressao CHR$(1)+CHR$(n), nao
;  cabem num unico byte 0-255 como os outros 128 (Dig_TransOriginal, byte
;  MSX = $80+indice). "Gerar codigo"/Injetar/Copiar emitem PRINT com os
;  glifos Unicode literais e deixam a traducao -tr (ja validada, mesmo
;  mecanismo que justifica CharMapGui.pbi) resolver pro byte/escape nativo
;  MSX na hora de tokenizar - sem precisar calcular endereco de VRAM nenhum
;  pro texto em si. So o CARREGADOR DE FONTE customizada (quando uma
;  nao-padrao e escolhida) e o mecanismo de Cor 2 acima precisam de
;  enderecos de verdade - a Pattern Generator Table do SCREEN 0 fica em
;  &H0800 no modo de 40 colunas mas em &H1000 no modo de 80 colunas (a
;  tabela de "pisca" ocupa o &H0800 nesse modo) - enderecos de hardware
;  padrao do MSX, nao documentados neste repo antes desta feature (ver
;  docs/SPEC.md).
;
;  Renderizacao no canvas: caracteres ASCII normais (32-126) e os 128 de
;  Dig_TransOriginal usam o bitmap 8x8 de verdade da fonte ativa (igual ao
;  Graphos III/Aquarela) - pixel a pixel, fiel ao que apareceria no MSX real.
;  Os 31 de Dig_TransReplacementOrder (sem byte de fonte proprio neste
;  codebase - ver acima) sao desenhados com a fonte do sistema (mesma
;  tecnica do preview do CharMapGui.pbi) - aproximacao visual; o codigo
;  gerado continua exato porque so depende do glifo Unicode, nao do bitmap.
;  Celulas marcadas com o atributo de Cor 2 sao desenhadas com Ink2/Paper2
;  (previa estatica de "como ficaria a cor 2" - o editor nao anima o
;  pisca-pisca de verdade, ver comentario em Scr0Ed_RedrawCanvas).
;
;  Ferramentas (uma aba por ferramenta, mesmo espirito de Screen2EditorGui.pbi):
;  Texto (clique posiciona uma string horizontal), Caractere (escolhe um
;  glifo na grade da coluna direita - ver abaixo - e estampa por clique/
;  arraste), Quadro (2 cliques desenham uma moldura com juncoes automaticas
;  via bitmask de 4 direcoes), Sombra (2 cliques estampam uma faixa ▒
;  deslocada), Bloco (2 cliques preenchem um retangulo com o caractere
;  atual), Borracha (clique/arraste apaga) e Atributo (clique/arraste liga,
;  botao direito desliga o uso da Cor 2 numa celula - so em 80 colunas). O
;  painel de abas fica pequeno de proposito (so texto explicativo, nenhuma
;  aba tem um controle grande) - a grade de escolha de caractere (159
;  simbolos, mesma fonte de dados de CharMapGui.pbi mas desenhada num
;  tamanho de celula proprio, menor, pra caber na coluna direita) fica
;  sempre visivel ali, abaixo da paleta/Cor 2, nao dentro de uma aba -
;  pedido explicito do usuario apos ver a primeira versao do layout (painel
;  de abas grande demais, saindo da tela).
;  Mesma barra de projeto/paleta dos demais editores (numero/tag/navegacao/
;  Novo/Registrar, paleta MSX1 reaproveitando
;  SpriteEd_FillPalette/Scr2Ed_RedrawMiniPalette).
; ------------------------------------------------------------
;

#Scr0Ed_Rows      = 24
#Scr0Ed_MaxWidth  = 80
#Scr0Ed_MaxCells  = #Scr0Ed_MaxWidth * #Scr0Ed_Rows   ; 1920

; Painel de ferramentas: so texto explicativo (nenhuma aba tem um controle
; grande - a grade de caractere fica na coluna direita, ver
; Scr0Ed_DrawCharPicker abaixo), entao pode ser bem mais baixo/estreito do
; que quando a grade ficava embutida numa aba.
#Scr0Ed_ToolPanelW = 480
#Scr0Ed_ToolPanelH = 160

; Grade de escolha de caractere da coluna direita - mesma fonte de dados de
; CharMapGui.pbi (CharMap_CharAt, 159 simbolos), mas com celula proprio
; MENOR (20px, nao os 34px do CharMapGui.pbi original) pra caber numa
; coluna de largura fixa ao lado do canvas, sem alargar a janela.
#Scr0Ed_CharPickCellPx = 20
#Scr0Ed_CharPickCols   = 16
#Scr0Ed_CharPickRows   = 10
#Scr0Ed_CharPickW      = #Scr0Ed_CharPickCols * #Scr0Ed_CharPickCellPx   ; 320
#Scr0Ed_CharPickH      = #Scr0Ed_CharPickRows * #Scr0Ed_CharPickCellPx   ; 200

Enumeration
  #Scr0Ed_Tool_Text
  #Scr0Ed_Tool_Char
  #Scr0Ed_Tool_Box
  #Scr0Ed_Tool_Shadow
  #Scr0Ed_Tool_Fill
  #Scr0Ed_Tool_Erase
  #Scr0Ed_Tool_Attr
EndEnumeration

Global Scr0Ed_FallbackFont.i = 0

Procedure Scr0Ed_EnsureFonts()
  If Not Scr0Ed_FallbackFont
    Scr0Ed_FallbackFont = LoadFont(#PB_Any, "Segoe UI", 10)
  EndIf
EndProcedure

; Zoom 4 (celula 32x32) pra telas de 40 colunas ou menos, zoom 2 (16x16) pra
; 80 colunas - mantem a largura do canvas praticamente constante (~1280px)
; independente da largura escolhida, e combina com o proprio hardware real
; (MSX2+ usa fonte fisicamente menor em WIDTH>40 - ver "X ... se 41-80,
; caracteres pequenos" em MsxBasic2PlusDictData.pbi, verbete WIDTH). Dobrado
; (era zoom 2/1) a pedido do usuario - a area de edicao ficava pequena com
; os controles todos concentrados na coluna direita (ver layout novo em
; Screen0Editor_OpenWindow: ferramentas/botoes migraram pra baixo do canvas,
; a coluna direita agora so tem paletas/campos curtos).
Procedure.i Scr0Ed_ZoomForWidth(Width.i)
  If Width <= 40
    ProcedureReturn 4
  EndIf
  ProcedureReturn 2
EndProcedure

; --- bitmask (bit0=Cima,bit1=Baixo,bit2=Esquerda,bit3=Direita) <-> caractere
; de moldura - usado pela ferramenta Quadro pra unir automaticamente com
; quadros ja existentes que uma nova borda encoste (formando T/+). So cobre
; as 11 combinacoes de >=2 direcoes que o conjunto de caracteres de
; DignifiedPreprocessor.pbi (Dig_TransReplacementOrder) realmente tem.
Procedure.s Scr0Ed_BoxMaskToChar(Mask.i)
  Select Mask
    Case 3  : ProcedureReturn Chr($2502)  ; up+down          -> vertical
    Case 12 : ProcedureReturn Chr($2500)  ; left+right        -> horizontal
    Case 10 : ProcedureReturn Chr($250C)  ; down+right        -> canto sup-esq
    Case 6  : ProcedureReturn Chr($2510)  ; down+left         -> canto sup-dir
    Case 9  : ProcedureReturn Chr($2514)  ; up+right          -> canto inf-esq
    Case 5  : ProcedureReturn Chr($2518)  ; up+left           -> canto inf-dir
    Case 11 : ProcedureReturn Chr($251C)  ; up+down+right     -> T pra direita
    Case 7  : ProcedureReturn Chr($2524)  ; up+down+left      -> T pra esquerda
    Case 14 : ProcedureReturn Chr($252C)  ; down+left+right   -> T pra baixo
    Case 13 : ProcedureReturn Chr($2534)  ; up+left+right     -> T pra cima
    Case 15 : ProcedureReturn Chr($253C)  ; as 4              -> cruz
  EndSelect
  ProcedureReturn ""
EndProcedure

Procedure.i Scr0Ed_BoxCharToMask(Ch.s)
  Select Ch
    Case Chr($2502) : ProcedureReturn 3
    Case Chr($2500) : ProcedureReturn 12
    Case Chr($250C) : ProcedureReturn 10
    Case Chr($2510) : ProcedureReturn 6
    Case Chr($2514) : ProcedureReturn 9
    Case Chr($2518) : ProcedureReturn 5
    Case Chr($251C) : ProcedureReturn 11
    Case Chr($2524) : ProcedureReturn 7
    Case Chr($252C) : ProcedureReturn 14
    Case Chr($2534) : ProcedureReturn 13
    Case Chr($253C) : ProcedureReturn 15
  EndSelect
  ProcedureReturn 0
EndProcedure

; Combina o mascara NewMask com o que ja estiver na celula (se for tambem um
; caractere de moldura, junta formando T/+; senao so sobrescreve).
Procedure Scr0Ed_StampBoxEdge(Array GridCodes.u(1), Width.i, Col.i, Row.i, NewMask.i)
  If Col < 0 Or Col >= Width Or Row < 0 Or Row >= #Scr0Ed_Rows
    ProcedureReturn
  EndIf
  Protected Idx = Row * Width + Col
  Protected ExistingMask = Scr0Ed_BoxCharToMask(Chr(GridCodes(Idx)))
  Protected NewCh.s = Scr0Ed_BoxMaskToChar(ExistingMask | NewMask)
  If NewCh = ""
    NewCh = Scr0Ed_BoxMaskToChar(NewMask)
  EndIf
  GridCodes(Idx) = Asc(NewCh)
EndProcedure

; Desenha a moldura do retangulo (X1,Y1)-(X2,Y2) - linha simples pros lados,
; cantos combinados via mascara. Retangulo de largura ou altura 1 vira so
; uma linha reta (sem cantos, nao faz sentido).
Procedure Scr0Ed_DrawBox(Array GridCodes.u(1), Width.i, X1.i, Y1.i, X2.i, Y2.i)
  Protected Xa = X1, Xb = X2, Ya = Y1, Yb = Y2, Col, Row
  If Xa > Xb : Swap Xa, Xb : EndIf
  If Ya > Yb : Swap Ya, Yb : EndIf

  If Ya = Yb
    For Col = Xa To Xb
      Scr0Ed_StampBoxEdge(GridCodes(), Width, Col, Ya, 12)
    Next
    ProcedureReturn
  EndIf
  If Xa = Xb
    For Row = Ya To Yb
      Scr0Ed_StampBoxEdge(GridCodes(), Width, Xa, Row, 3)
    Next
    ProcedureReturn
  EndIf

  Scr0Ed_StampBoxEdge(GridCodes(), Width, Xa, Ya, 10)  ; canto sup-esq
  Scr0Ed_StampBoxEdge(GridCodes(), Width, Xb, Ya, 6)   ; canto sup-dir
  Scr0Ed_StampBoxEdge(GridCodes(), Width, Xa, Yb, 9)   ; canto inf-esq
  Scr0Ed_StampBoxEdge(GridCodes(), Width, Xb, Yb, 5)   ; canto inf-dir
  For Col = Xa + 1 To Xb - 1
    Scr0Ed_StampBoxEdge(GridCodes(), Width, Col, Ya, 12)
    Scr0Ed_StampBoxEdge(GridCodes(), Width, Col, Yb, 12)
  Next
  For Row = Ya + 1 To Yb - 1
    Scr0Ed_StampBoxEdge(GridCodes(), Width, Xa, Row, 3)
    Scr0Ed_StampBoxEdge(GridCodes(), Width, Xb, Row, 3)
  Next
EndProcedure

; Sombra classica de editor ANSI: faixa de 1 celula com o bloco de sombra
; medio (▒), deslocada uma celula pra baixo/direita ao longo das bordas
; direita e inferior do retangulo marcado.
Procedure Scr0Ed_ApplyShadow(Array GridCodes.u(1), Width.i, X1.i, Y1.i, X2.i, Y2.i)
  Protected Xa = X1, Xb = X2, Ya = Y1, Yb = Y2, Col, Row
  If Xa > Xb : Swap Xa, Xb : EndIf
  If Ya > Yb : Swap Ya, Yb : EndIf
  Protected ShadowCode = $2592  ; ▒

  Col = Xb + 1
  If Col < Width
    For Row = Ya + 1 To Yb + 1
      If Row < #Scr0Ed_Rows
        GridCodes(Row * Width + Col) = ShadowCode
      EndIf
    Next
  EndIf

  Row = Yb + 1
  If Row < #Scr0Ed_Rows
    For Col = Xa + 1 To Xb + 1
      If Col < Width
        GridCodes(Row * Width + Col) = ShadowCode
      EndIf
    Next
  EndIf
EndProcedure

Procedure Scr0Ed_FillRect(Array GridCodes.u(1), Width.i, X1.i, Y1.i, X2.i, Y2.i, Ch.s)
  Protected Xa = X1, Xb = X2, Ya = Y1, Yb = Y2, Col, Row
  If Xa > Xb : Swap Xa, Xb : EndIf
  If Ya > Yb : Swap Ya, Yb : EndIf
  Protected Code = Asc(Ch)
  For Row = Ya To Yb
    For Col = Xa To Xb
      GridCodes(Row * Width + Col) = Code
    Next
  Next
EndProcedure

; Estampa Text horizontalmente a partir de (StartCol,Row), cortando no fim
; da linha (sem quebra automatica - texto que nao cabe so e truncado).
Procedure Scr0Ed_StampText(Array GridCodes.u(1), Width.i, StartCol.i, Row.i, Text.s)
  Protected i, Col
  For i = 1 To Len(Text)
    Col = StartCol + i - 1
    If Col >= Width
      Break
    EndIf
    GridCodes(Row * Width + Col) = Asc(Mid(Text, i, 1))
  Next
EndProcedure

; Devolve o byte MSX (0-255) do bitmap de fonte pra Ch, ou -1 se Ch nao tem
; bitmap disponivel neste codebase (os 31 "graficos" de
; Dig_TransReplacementOrder - ver comentario grande no topo do arquivo).
Procedure.i Scr0Ed_GlyphByteFor(Ch.s)
  Protected Code = Asc(Ch)
  If Code >= 32 And Code <= 126
    ProcedureReturn Code
  EndIf
  Protected Idx = FindString(Dig_TransOriginal, Ch)
  If Idx > 0
    ProcedureReturn $80 + Idx - 1
  EndIf
  ProcedureReturn -1
EndProcedure

; Desenha o glifo bitmap 8x8 (real, pixel a pixel) de ByteCode em (X,Y),
; escalado por Zoom, tinta InkRGB sobre fundo PaperRGB. Chamada de dentro de
; um StartDrawing/StopDrawing ja aberto pelo chamador (nao abre o proprio).
Procedure Scr0Ed_DrawGlyphBitmap(Array CharsetBytes.a(2), ByteCode.i, X.i, Y.i, Zoom.i, InkRGB.l, PaperRGB.l)
  Box(X, Y, 8 * Zoom, 8 * Zoom, PaperRGB)
  ; Funde pixels de tinta adjacentes na mesma linha num Box() so (mesma
  ; tecnica de Scr2Ed_RedrawCanvas, Screen2EditorGui.pbi) em vez de um
  ; Box() por pixel - chamada por celula num redesenho de tela inteira
  ; (ate #Scr0Ed_MaxCells celulas), entao o numero de Box() por glifo
  ; importa no total.
  Protected PxRow, PxCol, ByteVal.a, RunStart, InRun.b
  For PxRow = 0 To 7
    ByteVal = CharsetBytes(ByteCode, PxRow)
    InRun = #False
    For PxCol = 0 To 7
      If ByteVal & (1 << (7 - PxCol))
        If Not InRun
          RunStart = PxCol
          InRun = #True
        EndIf
      ElseIf InRun
        Box(X + RunStart * Zoom, Y + PxRow * Zoom, (PxCol - RunStart) * Zoom, Zoom, InkRGB)
        InRun = #False
      EndIf
    Next
    If InRun
      Box(X + RunStart * Zoom, Y + PxRow * Zoom, (8 - RunStart) * Zoom, Zoom, InkRGB)
    EndIf
  Next
EndProcedure

; Aproximacao visual (fonte do sistema) pros 31 caracteres sem bitmap MSX
; disponivel - ver comentario grande no topo do arquivo.
Procedure Scr0Ed_DrawGlyphFallback(Ch.s, X.i, Y.i, CellPx.i, InkRGB.l, PaperRGB.l)
  Box(X, Y, CellPx, CellPx, PaperRGB)
  DrawingMode(#PB_2DDrawing_Transparent)
  FrontColor(InkRGB)
  DrawingFont(FontID(Scr0Ed_FallbackFont))
  Protected TW = TextWidth(Ch), TH = TextHeight(Ch)
  DrawText(X + (CellPx - TW) / 2, Y + (CellPx - TH) / 2, Ch)
  DrawingMode(#PB_2DDrawing_Default)
EndProcedure

; Grade de escolha de caractere da coluna direita (159 simbolos, mesma
; fonte de dados de CharMap_CharAt em CharMapGui.pbi) - versao com celula
; menor (ver #Scr0Ed_CharPickCellPx) que a grade original do CharMapGui.pbi,
; desenhada aqui em vez de reaproveitar CharMap_Redraw() porque esse usa um
; tamanho de celula fixo (34px) grande demais pra coluna direita deste editor.
Procedure Scr0Ed_DrawCharPicker(Canvas, Selected.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Box(0, 0, #Scr0Ed_CharPickW, #Scr0Ed_CharPickH, RGB(255, 255, 255))
  DrawingFont(FontID(Scr0Ed_FallbackFont))

  Protected i, Row, Col, X, Y, Ch.s, TW, TH
  For i = 0 To #Scr0Ed_CharPickCols * #Scr0Ed_CharPickRows - 1
    Row = i / #Scr0Ed_CharPickCols
    Col = i % #Scr0Ed_CharPickCols
    X = Col * #Scr0Ed_CharPickCellPx
    Y = Row * #Scr0Ed_CharPickCellPx

    DrawingMode(#PB_2DDrawing_Outlined)
    Box(X, Y, #Scr0Ed_CharPickCellPx, #Scr0Ed_CharPickCellPx, RGB(210, 210, 210))

    Ch = CharMap_CharAt(i)
    DrawingMode(#PB_2DDrawing_Transparent)
    FrontColor(RGB(0, 0, 0))
    TW = TextWidth(Ch)
    TH = TextHeight(Ch)
    DrawText(X + (#Scr0Ed_CharPickCellPx - TW) / 2, Y + (#Scr0Ed_CharPickCellPx - TH) / 2, Ch)

    If i = Selected
      DrawingMode(#PB_2DDrawing_Outlined)
      Box(X + 1, Y + 1, #Scr0Ed_CharPickCellPx - 2, #Scr0Ed_CharPickCellPx - 2, RGB(205, 40, 40))
    EndIf
  Next

  DrawingMode(#PB_2DDrawing_Default)
  StopDrawing()
EndProcedure

; Redesenha a tela inteira. Celulas com GridAttrs(idx)=1 usam Ink2RGB/
; Paper2RGB em vez de InkRGB/PaperRGB - previa ESTATICA de "como ficaria a
; Cor 2" (o editor nao anima o pisca-pisca de verdade; a duracao configurada
; so afeta o codigo gerado, nao a previa ao vivo - incremento futuro se for
; preciso). MarkCol/MarkRow (-1 = nenhum) destacam o primeiro clique
; pendente de uma ferramenta de 2 cliques (Quadro/Sombra/Bloco).
Procedure Scr0Ed_RedrawCanvas(Canvas, Array GridCodes.u(1), Array GridAttrs.a(1), Width.i, Array CharsetBytes.a(2),
                              Zoom.i, InkRGB.l, PaperRGB.l, Ink2RGB.l, Paper2RGB.l, MarkCol.i = -1, MarkRow.i = -1)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected CellPx = 8 * Zoom
  Protected Row, Col, Idx, Ch.s, ByteCode, CellInk.l, CellPaper.l
  For Row = 0 To #Scr0Ed_Rows - 1
    For Col = 0 To Width - 1
      Idx = Row * Width + Col
      Ch = Chr(GridCodes(Idx))
      If GridAttrs(Idx)
        CellInk = Ink2RGB : CellPaper = Paper2RGB
      Else
        CellInk = InkRGB : CellPaper = PaperRGB
      EndIf
      ByteCode = Scr0Ed_GlyphByteFor(Ch)
      If ByteCode >= 0
        Scr0Ed_DrawGlyphBitmap(CharsetBytes(), ByteCode, Col * CellPx, Row * CellPx, Zoom, CellInk, CellPaper)
      Else
        Scr0Ed_DrawGlyphFallback(Ch, Col * CellPx, Row * CellPx, CellPx, CellInk, CellPaper)
      EndIf
    Next
  Next

  If MarkCol >= 0 And MarkRow >= 0
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(MarkCol * CellPx, MarkRow * CellPx, CellPx, CellPx, RGB(255, 220, 0))
    Box(MarkCol * CellPx + 1, MarkRow * CellPx + 1, CellPx - 2, CellPx - 2, RGB(255, 220, 0))
    DrawingMode(#PB_2DDrawing_Default)
  EndIf

  StopDrawing()
EndProcedure

; --- Geracao de codigo: PRINT com os glifos Unicode literais (a traducao
; -tr do pipeline Dignified resolve pro byte/escape MSX na hora de
; tokenizar) mais, se preciso, o carregador de fonte customizada e o bloco
; de Cor 2/pisca-pisca (WIDTH 80 com pelo menos uma celula marcada). Ordem:
; SCREEN 0/WIDTH/COLOR primeiro (o VDP so reseta os enderecos padrao das
; tabelas - Pattern Generator, tabela de pisca - pro modo escolhido quando
; esses comandos rodam), so DEPOIS os VPOKE/VDP nas tabelas, por ultimo o
; texto em si.
Procedure.s Scr0Ed_BuildCode(Array GridCodes.u(1), Array GridAttrs.a(1), Width.i, Ink.i, Paper.i, AlphabetNumber.i,
                             Ink2.i, Paper2.i, BlinkOn.i, BlinkOff.i, Array CharsetBytes.a(2))
  Protected Result.s = ""

  Result + "SCREEN 0" + #CRLF$
  Result + "WIDTH " + Str(Width) + #CRLF$
  Result + "COLOR " + Str(Ink) + "," + Str(Paper) + #CRLF$

  ; Pattern Generator Table: &H0800 (2048) no modo de 40 colunas, &H1000
  ; (4096) no modo de 80 colunas - o &H0800 fica ocupado pela tabela de
  ; pisca nesse modo (ver bloco de Cor 2 abaixo). Enderecos de hardware
  ; padrao do MSX, nao documentados neste repo antes desta feature.
  Protected PgtAddr = 2048
  If Width > 40
    PgtAddr = 4096
  EndIf

  If AlphabetNumber <> -1
    Result + "' Carrega a fonte customizada #" + Str(AlphabetNumber) + " na PGT do SCREEN 0 (&H" + Hex(PgtAddr) + ")" + #CRLF$
    Result + "FOR SI=0 TO 2047:READ SD:VPOKE " + Str(PgtAddr) + "+SI,SD:NEXT SI" + #CRLF$
    Protected FRow, FCol, LineVals.s, Count
    Count = 0 : LineVals = ""
    For FRow = 0 To 255
      For FCol = 0 To 7
        If Count > 0 And Count % 16 = 0
          Result + "DATA " + LineVals + #CRLF$
          LineVals = ""
        EndIf
        If LineVals <> ""
          LineVals + ","
        EndIf
        LineVals + "&H" + RSet(Hex(CharsetBytes(FRow, FCol)), 2, "0")
        Count + 1
      Next
    Next
    If LineVals <> ""
      Result + "DATA " + LineVals + #CRLF$
    EndIf
  EndIf

  Protected HasAttr.b = #False
  Protected AttrIdx
  If Width = 80
    For AttrIdx = 0 To Width * #Scr0Ed_Rows - 1
      If GridAttrs(AttrIdx)
        HasAttr = #True
        Break
      EndIf
    Next
  EndIf

  If HasAttr
    Result + "' Cor 2 (Ink2/Paper2) e duracao do pisca-pisca (0 em 'normal' trava na Cor 2)" + #CRLF$
    Result + "VDP(13)=" + Str(Ink2 * 16 + Paper2) + #CRLF$
    Result + "VDP(14)=" + Str(BlinkOn * 16 + BlinkOff) + #CRLF$
    Result + "' Tabela de pisca (1 bit/caractere, 240 bytes, &H0800 no modo de 80 colunas)" + #CRLF$
    Result + "FOR SI=0 TO 239:READ SD:VPOKE 2048+SI,SD:NEXT SI" + #CRLF$

    Protected PackIdx, BitIdx, ByteVal.a, AttrLineVals.s, AttrCount
    AttrCount = 0 : AttrLineVals = ""
    For PackIdx = 0 To 239
      ByteVal = 0
      For BitIdx = 0 To 7
        AttrIdx = PackIdx * 8 + BitIdx
        If AttrIdx < Width * #Scr0Ed_Rows And GridAttrs(AttrIdx)
          ByteVal | (1 << (7 - BitIdx))
        EndIf
      Next
      If AttrCount > 0 And AttrCount % 16 = 0
        Result + "DATA " + AttrLineVals + #CRLF$
        AttrLineVals = ""
      EndIf
      If AttrLineVals <> ""
        AttrLineVals + ","
      EndIf
      AttrLineVals + "&H" + RSet(Hex(ByteVal), 2, "0")
      AttrCount + 1
    Next
    If AttrLineVals <> ""
      Result + "DATA " + AttrLineVals + #CRLF$
    EndIf
  EndIf

  Protected Row, Col, LineText.s, Q.s = Chr(34)
  For Row = 0 To #Scr0Ed_Rows - 1
    LineText = ""
    For Col = 0 To Width - 1
      LineText + Chr(GridCodes(Row * Width + Col))
    Next
    LineText = RTrim(LineText)
    If LineText <> ""
      Result + "LOCATE 0," + Str(Row) + ":PRINT " + Q + LineText + Q + ";" + #CRLF$
    EndIf
  Next

  ProcedureReturn Result
EndProcedure

Procedure.b Scr0Ed_ConfirmDiscard()
  ProcedureReturn Bool(MessageRequester("Tela nao registrada",
                        "As alteracoes desta tela ainda nao foram registradas no projeto." + Chr(10) +
                        "Descartar mesmo assim?",
                        #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
EndProcedure

; Janelinha de escolha 40/80 colunas, perguntada em "Novo" (a largura so e
; escolhida na criacao - trocar a largura de uma tela ja em edicao exigiria
; decidir o que fazer com o conteudo excedente, deixado de fora deste v1).
Procedure.i Scr0Ed_AskWidth(ParentWindow)
  Protected WinW = 380, WinH = 180
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Nova tela SCREEN 0",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn 0
  EndIf

  TextGadget(#PB_Any, 24, 24, WinW - 48, 40,
    "Escolha a largura da tela (WIDTH). 40 colunas e o padrao MSX1; 80 colunas precisa de MSX2+.")
  Protected G_W40 = OptionGadget(#PB_Any, 24, 76, 150, 22, "40 colunas (MSX1)")
  Protected G_W80 = OptionGadget(#PB_Any, 190, 76, 150, 22, "80 colunas (MSX2+)")
  SetGadgetState(G_W40, #True)

  Protected G_Ok = ThemedButton(WinW - 24 - 234, WinH - 56, 110, 32, "OK", "")
  Protected G_Cancel = ThemedButton(WinW - 24 - 110, WinH - 56, 110, 32, "Cancelar", "")

  Protected Event, Quit = #False, Result = 0
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_Ok
            If GetGadgetState(G_W80)
              Result = 80
            Else
              Result = 40
            EndIf
            Quit = #True
          Case G_Cancel
            Quit = #True
        EndSelect
      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
  ProcedureReturn Result
EndProcedure

; Reflete o estado atual na UI inteira - chamada apos carregar/criar/trocar
; de tela e apos trocar a fonte. Redimensiona o canvas conforme o zoom da
; largura atual (ver Scr0Ed_ZoomForWidth) e habilita/desabilita os controles
; de Cor 2 (so fazem sentido em telas de 80 colunas).
Procedure Scr0Ed_RefreshUI(G_Canvas, G_ScreenNumberText, G_Tag, G_WidthText, G_FontCombo, G_PaletteInk, G_PalettePaper,
                           G_PaletteInk2, G_PalettePaper2, G_BlinkOnField, G_BlinkOffField,
                           ScreenNumber.i, Tag.s, Width.i, Ink.i, Paper.i, AlphabetNumber.i, Ink2.i, Paper2.i, BlinkOn.i, BlinkOff.i,
                           Array GridCodes.u(1), Array GridAttrs.a(1), Array CharsetBytes.a(2), Array Palette.l(1))
  SetGadgetText(G_ScreenNumberText, "#" + Str(ScreenNumber))
  SetGadgetText(G_Tag, Tag)
  SetGadgetText(G_WidthText, "Largura: " + Str(Width) + " colunas")
  SetGadgetText(G_BlinkOnField, Str(BlinkOn))
  SetGadgetText(G_BlinkOffField, Str(BlinkOff))

  If AlphabetNumber = -1
    SetGadgetState(G_FontCombo, 0)
    ProjectDB::FetchDefaultAlphabet(0, CharsetBytes())
  Else
    Protected i, Found = 0
    For i = 1 To CountGadgetItems(G_FontCombo) - 1
      If Val(Mid(GetGadgetItemText(G_FontCombo, i), 2)) = AlphabetNumber
        Found = i
        Break
      EndIf
    Next
    SetGadgetState(G_FontCombo, Found)
    ProjectDB::FetchAlphabet(AlphabetNumber, CharsetBytes())
  EndIf

  Protected Zoom = Scr0Ed_ZoomForWidth(Width)
  ResizeGadget(G_Canvas, #PB_Ignore, #PB_Ignore, Width * 8 * Zoom, #Scr0Ed_Rows * 8 * Zoom)

  Protected Is80.b = Bool(Width = 80)
  DisableGadget(G_PaletteInk2, Bool(Not Is80))
  DisableGadget(G_PalettePaper2, Bool(Not Is80))
  DisableGadget(G_BlinkOnField, Bool(Not Is80))
  DisableGadget(G_BlinkOffField, Bool(Not Is80))

  Scr2Ed_RedrawMiniPalette(G_PaletteInk, Ink, Palette())
  Scr2Ed_RedrawMiniPalette(G_PalettePaper, Paper, Palette())
  Scr2Ed_RedrawMiniPalette(G_PaletteInk2, Ink2, Palette())
  Scr2Ed_RedrawMiniPalette(G_PalettePaper2, Paper2, Palette())
  Scr0Ed_RedrawCanvas(G_Canvas, GridCodes(), GridAttrs(), Width, CharsetBytes(), Zoom, Palette(Ink), Palette(Paper), Palette(Ink2), Palette(Paper2))
EndProcedure

Procedure Screen0Editor_OpenWindow(ParentWindow)
  Scr0Ed_EnsureFonts()

  ; Layout (revisado 3x a pedido do usuario - ver ondas anteriores no
  ; historico do arquivo): a segunda revisao ainda quase nao cabia em
  ; 1920x1080 (resolucao minima aceita) - terceira revisao ganha mais altura
  ; de dois jeitos: a barra de projeto (numero/navegacao/tag/Novo/Registrar)
  ; que ficava acima do canvas migrou pra baixo da grade de caractere, na
  ; coluna direita (2 linhas compactas, a coluna e estreita); os botoes
  ; Injetar no cursor/Copiar/Fechar que ficavam abaixo do painel de abas
  ; migraram pro LADO dele (empilhados verticalmente a direita, mesma altura
  ; do painel) - juntas, as duas mudancas tiram um pedaco bom da altura total.
  Protected LeftX = 24
  Protected CanvasY = 24
  Protected CanvasWRef = 1280, CanvasHMax = #Scr0Ed_Rows * 32   ; 768 (zoom 4, o maior caso - 40 colunas)

  Protected RightX = LeftX + CanvasWRef + 24
  Protected RightColW = 340   ; coluna direita: paletas/campos curtos + grade de caractere + barra de projeto

  ; --- Coluna direita (largura/fonte, caractere atual, paletas, Cor 2,
  ; grade de escolha de caractere, barra de projeto), de cima pra baixo -
  ; ver criacao dos gadgets abaixo pros mesmos calculos ---
  Protected InfoY = CanvasY
  Protected FontRowY = InfoY + 26
  Protected CharFieldLabelY = InfoY + 66
  Protected CharFieldY = CharFieldLabelY + 46
  Protected PaletteLabelY = CharFieldY + 24 + 16
  Protected Palette2LabelY = PaletteLabelY + 20 + #Scr2Ed_PaletteSize + 16
  Protected BlinkLabelY = Palette2LabelY + 20 + #Scr2Ed_PaletteSize + 16
  Protected BlinkFieldY = BlinkLabelY + 34
  Protected BlinkCaptionY = BlinkFieldY + 24 + 8
  Protected CharPickLabelY = BlinkCaptionY + 60 + 12
  Protected CharPickGridY = CharPickLabelY + 18 + 6
  Protected ProjBarY = CharPickGridY + #Scr0Ed_CharPickH + 12
  Protected ProjBarRow2Y = ProjBarY + #CharEd_IconBtnH + 6

  ; --- Ferramentas, abaixo do canvas (nao mais da coluna direita); botoes
  ; de acao ao lado do painel, nao mais abaixo dele ---
  Protected ToolPanelY = CanvasY + CanvasHMax + 24

  Protected WinW = RightX + RightColW + 24
  Protected WinH = ToolPanelY + #Scr0Ed_ToolPanelH + 20

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Tela MSX (SCREEN 0)",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  ; --- Canvas (largura fixa na tela, zoom se ajusta - ver Scr0Ed_ZoomForWidth) ---
  Protected G_Canvas = CanvasGadget(#PB_Any, LeftX, CanvasY, CanvasWRef, CanvasHMax)

  ; --- Coluna direita: largura/fonte, caractere atual, paletas, Cor 2 ---
  Protected G_WidthText = TextGadget(#PB_Any, RightX, InfoY, RightColW, 20, "Largura: 40 colunas")
  TextGadget(#PB_Any, RightX, FontRowY + 3, 45, 20, "Fonte:")
  Protected G_FontCombo = ComboBoxGadget(#PB_Any, RightX + 50, FontRowY, 220, 24)
  AddGadgetItem(G_FontCombo, -1, "Padrao")

  TextGadget(#PB_Any, RightX, CharFieldLabelY, RightColW, 40, "Caractere atual (estampar - Bloco/Borracha usam este tambem):")
  Protected G_AsciiChar = StringGadget(#PB_Any, RightX, CharFieldY, 60, 24, " ")

  TextGadget(#PB_Any, RightX, PaletteLabelY, 90, 18, "Tinta:")
  Protected G_PaletteInk = CanvasGadget(#PB_Any, RightX, PaletteLabelY + 20, #Scr2Ed_PaletteSize, #Scr2Ed_PaletteSize)
  TextGadget(#PB_Any, RightX + #Scr2Ed_PaletteSize + 16, PaletteLabelY, 90, 18, "Fundo:")
  Protected G_PalettePaper = CanvasGadget(#PB_Any, RightX + #Scr2Ed_PaletteSize + 16, PaletteLabelY + 20, #Scr2Ed_PaletteSize, #Scr2Ed_PaletteSize)

  TextGadget(#PB_Any, RightX, Palette2LabelY, 250, 18, "Cor 2 - Tinta2:")
  Protected G_PaletteInk2 = CanvasGadget(#PB_Any, RightX, Palette2LabelY + 20, #Scr2Ed_PaletteSize, #Scr2Ed_PaletteSize)
  GadgetToolTip(G_PaletteInk2, "So tem efeito em telas de 80 colunas - o hardware do MSX nao tem cor 2 em 40 colunas")
  TextGadget(#PB_Any, RightX + #Scr2Ed_PaletteSize + 16, Palette2LabelY, 90, 18, "Fundo2:")
  Protected G_PalettePaper2 = CanvasGadget(#PB_Any, RightX + #Scr2Ed_PaletteSize + 16, Palette2LabelY + 20, #Scr2Ed_PaletteSize, #Scr2Ed_PaletteSize)
  GadgetToolTip(G_PalettePaper2, "So tem efeito em telas de 80 colunas - o hardware do MSX nao tem cor 2 em 40 colunas")

  TextGadget(#PB_Any, RightX, BlinkLabelY, 500, 20, "Pisca-pisca (Cor 2, so telas de 80 colunas):")
  TextGadget(#PB_Any, RightX, BlinkFieldY + 3, 60, 20, "Normal:")
  Protected G_BlinkOnField = StringGadget(#PB_Any, RightX + 64, BlinkFieldY, 40, 24, "8")
  TextGadget(#PB_Any, RightX + 120, BlinkFieldY + 3, 50, 20, "Cor 2:")
  Protected G_BlinkOffField = StringGadget(#PB_Any, RightX + 176, BlinkFieldY, 40, 24, "8")
  TextGadget(#PB_Any, RightX, BlinkCaptionY, RightColW, 60,
    "Cada unidade = 1/6s (ate 2.5s por fase). 'Normal' = 0 trava a celula marcada permanentemente na Cor 2, sem piscar.")

  TextGadget(#PB_Any, RightX, CharPickLabelY, RightColW, 18, "Caractere (aba Caractere estampa este):")
  Protected G_CharPicker = CanvasGadget(#PB_Any, RightX, CharPickGridY, #Scr0Ed_CharPickW, #Scr0Ed_CharPickH)

  ; --- Barra de projeto (mesmo padrao numero/tag/navegacao/Novo/Registrar
  ; dos demais editores - icones reaproveitados de CharsetEditorGui.pbi),
  ; 2 linhas compactas pra caber na largura estreita da coluna direita ---
  Protected Cx = RightX
  TextGadget(#PB_Any, Cx, ProjBarY + 5, 40, 20, "Tela:")
  Cx + 40 + 4
  Protected G_ScreenNumberText = TextGadget(#PB_Any, Cx, ProjBarY + 5, 40, 20, "#1")
  Cx + 40 + 10

  Protected FirstIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 0, #True)
  Protected G_First = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(FirstIcon))
  GadgetToolTip(G_First, "Primeira tela")
  Cx + #CharEd_IconBtnW + 2
  Protected PrevIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 0, #False)
  Protected G_Prev = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(PrevIcon))
  GadgetToolTip(G_Prev, "Tela anterior")
  Cx + #CharEd_IconBtnW + 2
  Protected NextIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 1, #False)
  Protected G_Next = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(NextIcon))
  GadgetToolTip(G_Next, "Proxima tela")
  Cx + #CharEd_IconBtnW + 2
  Protected LastIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 1, #True)
  Protected G_Last = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(LastIcon))
  GadgetToolTip(G_Last, "Ultima tela")

  Cx = RightX
  TextGadget(#PB_Any, Cx, ProjBarRow2Y + 3, 32, 20, "Tag:")
  Cx + 32 + 4
  Protected G_Tag = StringGadget(#PB_Any, Cx, ProjBarRow2Y + 1, 150, 22, "")
  GadgetToolTip(G_Tag, "Nome curto pra identificar a tela (ate 16 caracteres)")
  Cx + 150 + 16

  Protected NewIcon = CharEd_CreateNewIcon(#CharEd_IconSize)
  Protected G_New = ButtonImageGadget(#PB_Any, Cx, ProjBarRow2Y, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(NewIcon))
  GadgetToolTip(G_New, "Nova tela (pergunta a largura, numera automaticamente, comeca em branco)")
  Cx + #CharEd_IconBtnW + 2
  Protected RegisterIcon = CharEd_CreateRegisterIcon(#CharEd_IconSize)
  Protected G_Register = ButtonImageGadget(#PB_Any, Cx, ProjBarRow2Y, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(RegisterIcon))
  GadgetToolTip(G_Register, "Registrar: grava esta tela no projeto")

  Protected G_Panel = PanelGadget(#PB_Any, LeftX, ToolPanelY, #Scr0Ed_ToolPanelW, #Scr0Ed_ToolPanelH)
  Protected ToolContentW = #Scr0Ed_ToolPanelW - 20

  AddGadgetItem(G_Panel, -1, "Texto")
    TextGadget(#PB_Any, 10, 10, ToolContentW, 40,
      "Digite o texto e clique no canvas pra posicionar (horizontal, a partir da celula clicada; corta se passar do fim da linha).")
    Protected G_TextInput = StringGadget(#PB_Any, 10, 56, ToolContentW, 24, "")

  AddGadgetItem(G_Panel, -1, "Caractere")
    TextGadget(#PB_Any, 10, 10, ToolContentW, 60,
      "Escolha o caractere na grade da coluna direita (abaixo da paleta/Cor 2), depois clique ou arraste no canvas pra estampar.")

  AddGadgetItem(G_Panel, -1, "Quadro")
    TextGadget(#PB_Any, 10, 10, ToolContentW, 80,
      "Dois cliques no canvas: primeiro marca um canto, segundo marca o canto oposto - desenha a moldura com linhas simples, unindo automaticamente com quadros ja existentes que encostarem (formando T/cruz na juncao)." + Chr(10) + Chr(10) +
      "Botao direito cancela a marcacao pendente.")

  AddGadgetItem(G_Panel, -1, "Sombra")
    TextGadget(#PB_Any, 10, 10, ToolContentW, 80,
      "Dois cliques (cantos opostos de um retangulo, tipicamente o mesmo de um quadro ja desenhado) - estampa uma faixa de sombra deslocada uma celula pra baixo e pra direita, ao longo das bordas direita e inferior.")

  AddGadgetItem(G_Panel, -1, "Bloco")
    TextGadget(#PB_Any, 10, 10, ToolContentW, 90,
      "Dois cliques (cantos opostos) - preenche o retangulo inteiro com o caractere atual (campo acima, ou escolhido na aba Caractere). Util pra texturas, fundos ou apagar uma area maior de uma vez.")

  AddGadgetItem(G_Panel, -1, "Borracha")
    TextGadget(#PB_Any, 10, 10, ToolContentW, 40, "Clique ou arraste no canvas pra apagar (estampa espaco).")

  AddGadgetItem(G_Panel, -1, "Atributo")
    TextGadget(#PB_Any, 10, 10, ToolContentW, 90,
      "Marca (clique/arraste) ou desmarca (botao direito/arraste) celulas pra usarem a Cor 2 (paletas e duracao do pisca-pisca acima) - so tem efeito em telas de 80 colunas, o hardware do MSX nao tem esse recurso em 40 colunas.")

  CloseGadgetList()

  ; Botoes de acao ao lado do painel de abas (nao mais abaixo dele),
  ; empilhados verticalmente na mesma faixa de altura do painel.
  Protected ButtonsX = LeftX + #Scr0Ed_ToolPanelW + 24
  Protected G_Inject = ThemedButton(ButtonsX, ToolPanelY, 180, 32, "Injetar no cursor", Chr(#Icon_Insert))
  Protected G_Copy = ThemedButton(ButtonsX, ToolPanelY + 40, 180, 32, "Copiar", Chr(#Icon_Copy))
  Protected G_Close = ThemedButton(ButtonsX, ToolPanelY + 80, 180, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")
  GadgetToolTip(G_Inject, "Gera o codigo BASIC (SCREEN 0/WIDTH/COLOR/LOCATE+PRINT, mais os carregadores de fonte/Cor 2 se houver) e injeta na aba de texto ativa")
  GadgetToolTip(G_Copy, "Gera o mesmo codigo e copia pra area de transferencia")

  ; --- Estado ---
  Dim GridCodes.u(#Scr0Ed_MaxCells - 1)
  Dim GridAttrs.a(#Scr0Ed_MaxCells - 1)
  Dim CharsetBytes.a(255, 7)
  Dim Palette.l(15)
  Dim PaletteNames.s(15)
  SpriteEd_FillPalette(Palette(), PaletteNames())

  Protected NewList AlphaNums.i()
  ProjectDB::ListAlphabetNumbers(AlphaNums())
  ForEach AlphaNums()
    AddGadgetItem(G_FontCombo, -1, "#" + Str(AlphaNums()))
  Next

  Protected ScreenNumber.i = 1
  Protected ScreenTag.s = ""
  Protected Width.i = 40
  Protected Ink.i = 15, Paper.i = 1
  Protected Ink2.i = 15, Paper2.i = 1, BlinkOn.i = 8, BlinkOff.i = 8
  Protected AlphabetNumber.i = -1
  Protected Dirty.b = #False

  Protected ClearIdx
  For ClearIdx = 0 To #Scr0Ed_MaxCells - 1
    GridCodes(ClearIdx) = 32
    GridAttrs(ClearIdx) = 0
  Next

  Protected NewList Nav.i()
  ProjectDB::ListScreen0Numbers(Nav())
  If ListSize(Nav()) > 0
    FirstElement(Nav())
    ScreenNumber = Nav()
    ProjectDB::FetchScreen0(ScreenNumber, GridCodes(), GridAttrs())
    Width = ProjectDB::LastScreen0Width()
    Ink = ProjectDB::LastScreen0Ink()
    Paper = ProjectDB::LastScreen0Paper()
    AlphabetNumber = ProjectDB::LastScreen0AlphabetNumber()
    Ink2 = ProjectDB::LastScreen0Ink2()
    Paper2 = ProjectDB::LastScreen0Paper2()
    BlinkOn = ProjectDB::LastScreen0BlinkOn()
    BlinkOff = ProjectDB::LastScreen0BlinkOff()
    ScreenTag = ProjectDB::LastScreen0Tag()
  EndIf

  Scr0Ed_DrawCharPicker(G_CharPicker, -1)
  Scr0Ed_RefreshUI(G_Canvas, G_ScreenNumberText, G_Tag, G_WidthText, G_FontCombo, G_PaletteInk, G_PalettePaper,
                   G_PaletteInk2, G_PalettePaper2, G_BlinkOnField, G_BlinkOffField,
                   ScreenNumber, ScreenTag, Width, Ink, Paper, AlphabetNumber, Ink2, Paper2, BlinkOn, BlinkOff,
                   GridCodes(), GridAttrs(), CharsetBytes(), Palette())

  Protected Event, Quit = #False, MouseX, MouseY, Col, Row, NavTarget
  Protected MarkCol = -1, MarkRow = -1
  Protected LastPaintCol = -1, LastPaintRow = -1
  Protected CurrentStampChar.s = " "
  Protected SelectedCharIndex = -1
  Protected Zoom, ActiveTab

  Repeat
    Event = WaitWindowEvent()

    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()

          Case G_Tag
            If EventType() = #PB_EventType_Change
              If Len(GetGadgetText(G_Tag)) > 16
                SetGadgetText(G_Tag, Left(GetGadgetText(G_Tag), 16))
              EndIf
              Dirty = #True
            EndIf

          Case G_AsciiChar
            If EventType() = #PB_EventType_Change
              Protected AsciiTxt.s = GetGadgetText(G_AsciiChar)
              If Len(AsciiTxt) > 1
                AsciiTxt = Left(AsciiTxt, 1)
                SetGadgetText(G_AsciiChar, AsciiTxt)
              EndIf
              If AsciiTxt <> ""
                CurrentStampChar = AsciiTxt
              EndIf
            EndIf

          Case G_BlinkOnField
            If EventType() = #PB_EventType_Change
              BlinkOn = Val(GetGadgetText(G_BlinkOnField))
              If BlinkOn < 0 : BlinkOn = 0 : ElseIf BlinkOn > 15 : BlinkOn = 15 : EndIf
              Dirty = #True
            EndIf

          Case G_BlinkOffField
            If EventType() = #PB_EventType_Change
              BlinkOff = Val(GetGadgetText(G_BlinkOffField))
              If BlinkOff < 0 : BlinkOff = 0 : ElseIf BlinkOff > 15 : BlinkOff = 15 : EndIf
              Dirty = #True
            EndIf

          Case G_FontCombo
            If EventType() = #PB_EventType_Change
              Protected FontSel.s = GetGadgetText(G_FontCombo)
              If FontSel = "Padrao"
                AlphabetNumber = -1
                ProjectDB::FetchDefaultAlphabet(0, CharsetBytes())
              Else
                AlphabetNumber = Val(Mid(FontSel, 2))
                ProjectDB::FetchAlphabet(AlphabetNumber, CharsetBytes())
              EndIf
              Dirty = #True
              Zoom = Scr0Ed_ZoomForWidth(Width)
              Scr0Ed_RedrawCanvas(G_Canvas, GridCodes(), GridAttrs(), Width, CharsetBytes(), Zoom, Palette(Ink), Palette(Paper), Palette(Ink2), Palette(Paper2))
            EndIf

          Case G_PaletteInk
            If EventType() = #PB_EventType_LeftButtonDown
              MouseX = GetGadgetAttribute(G_PaletteInk, #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(G_PaletteInk, #PB_Canvas_MouseY)
              Protected InkIdx = Scr2Ed_PaletteHitTest(MouseX, MouseY)
              If InkIdx >= 0
                Ink = InkIdx
                Dirty = #True
                Scr2Ed_RedrawMiniPalette(G_PaletteInk, Ink, Palette())
                Zoom = Scr0Ed_ZoomForWidth(Width)
                Scr0Ed_RedrawCanvas(G_Canvas, GridCodes(), GridAttrs(), Width, CharsetBytes(), Zoom, Palette(Ink), Palette(Paper), Palette(Ink2), Palette(Paper2))
              EndIf
            EndIf

          Case G_PalettePaper
            If EventType() = #PB_EventType_LeftButtonDown
              MouseX = GetGadgetAttribute(G_PalettePaper, #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(G_PalettePaper, #PB_Canvas_MouseY)
              Protected PaperIdx = Scr2Ed_PaletteHitTest(MouseX, MouseY)
              If PaperIdx >= 0
                Paper = PaperIdx
                Dirty = #True
                Scr2Ed_RedrawMiniPalette(G_PalettePaper, Paper, Palette())
                Zoom = Scr0Ed_ZoomForWidth(Width)
                Scr0Ed_RedrawCanvas(G_Canvas, GridCodes(), GridAttrs(), Width, CharsetBytes(), Zoom, Palette(Ink), Palette(Paper), Palette(Ink2), Palette(Paper2))
              EndIf
            EndIf

          Case G_PaletteInk2
            If EventType() = #PB_EventType_LeftButtonDown And Width = 80
              MouseX = GetGadgetAttribute(G_PaletteInk2, #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(G_PaletteInk2, #PB_Canvas_MouseY)
              Protected Ink2Idx = Scr2Ed_PaletteHitTest(MouseX, MouseY)
              If Ink2Idx >= 0
                Ink2 = Ink2Idx
                Dirty = #True
                Scr2Ed_RedrawMiniPalette(G_PaletteInk2, Ink2, Palette())
                Zoom = Scr0Ed_ZoomForWidth(Width)
                Scr0Ed_RedrawCanvas(G_Canvas, GridCodes(), GridAttrs(), Width, CharsetBytes(), Zoom, Palette(Ink), Palette(Paper), Palette(Ink2), Palette(Paper2))
              EndIf
            EndIf

          Case G_PalettePaper2
            If EventType() = #PB_EventType_LeftButtonDown And Width = 80
              MouseX = GetGadgetAttribute(G_PalettePaper2, #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(G_PalettePaper2, #PB_Canvas_MouseY)
              Protected Paper2Idx = Scr2Ed_PaletteHitTest(MouseX, MouseY)
              If Paper2Idx >= 0
                Paper2 = Paper2Idx
                Dirty = #True
                Scr2Ed_RedrawMiniPalette(G_PalettePaper2, Paper2, Palette())
                Zoom = Scr0Ed_ZoomForWidth(Width)
                Scr0Ed_RedrawCanvas(G_Canvas, GridCodes(), GridAttrs(), Width, CharsetBytes(), Zoom, Palette(Ink), Palette(Paper), Palette(Ink2), Palette(Paper2))
              EndIf
            EndIf

          Case G_CharPicker
            If EventType() = #PB_EventType_LeftButtonDown Or EventType() = #PB_EventType_LeftDoubleClick
              MouseX = GetGadgetAttribute(G_CharPicker, #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(G_CharPicker, #PB_Canvas_MouseY)
              If MouseX >= 0 And MouseY >= 0
                Protected PickCol = MouseX / #Scr0Ed_CharPickCellPx, PickRow = MouseY / #Scr0Ed_CharPickCellPx
                Protected PickIdx = PickRow * #Scr0Ed_CharPickCols + PickCol
                If PickIdx >= 0 And PickIdx < #CharMap_TotalChars
                  SelectedCharIndex = PickIdx
                  CurrentStampChar = CharMap_CharAt(PickIdx)
                  SetGadgetText(G_AsciiChar, CurrentStampChar)
                  Scr0Ed_DrawCharPicker(G_CharPicker, SelectedCharIndex)
                EndIf
              EndIf
            EndIf

          Case G_Canvas
            Zoom = Scr0Ed_ZoomForWidth(Width)
            ActiveTab = GetGadgetState(G_Panel)

            Select EventType()
              Case #PB_EventType_LeftButtonDown
                MouseX = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseX)
                MouseY = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseY)
                If MouseX >= 0 And MouseY >= 0
                  Col = MouseX / (8 * Zoom)
                  Row = MouseY / (8 * Zoom)
                  If Col >= 0 And Col < Width And Row >= 0 And Row < #Scr0Ed_Rows
                    Select ActiveTab
                      Case #Scr0Ed_Tool_Text
                        Scr0Ed_StampText(GridCodes(), Width, Col, Row, GetGadgetText(G_TextInput))
                        Dirty = #True

                      Case #Scr0Ed_Tool_Char
                        GridCodes(Row * Width + Col) = Asc(CurrentStampChar)
                        LastPaintCol = Col : LastPaintRow = Row
                        Dirty = #True

                      Case #Scr0Ed_Tool_Box
                        If MarkCol = -1
                          MarkCol = Col : MarkRow = Row
                        Else
                          Scr0Ed_DrawBox(GridCodes(), Width, MarkCol, MarkRow, Col, Row)
                          MarkCol = -1 : MarkRow = -1
                          Dirty = #True
                        EndIf

                      Case #Scr0Ed_Tool_Shadow
                        If MarkCol = -1
                          MarkCol = Col : MarkRow = Row
                        Else
                          Scr0Ed_ApplyShadow(GridCodes(), Width, MarkCol, MarkRow, Col, Row)
                          MarkCol = -1 : MarkRow = -1
                          Dirty = #True
                        EndIf

                      Case #Scr0Ed_Tool_Fill
                        If MarkCol = -1
                          MarkCol = Col : MarkRow = Row
                        Else
                          Scr0Ed_FillRect(GridCodes(), Width, MarkCol, MarkRow, Col, Row, CurrentStampChar)
                          MarkCol = -1 : MarkRow = -1
                          Dirty = #True
                        EndIf

                      Case #Scr0Ed_Tool_Erase
                        GridCodes(Row * Width + Col) = 32
                        LastPaintCol = Col : LastPaintRow = Row
                        Dirty = #True

                      Case #Scr0Ed_Tool_Attr
                        If Width = 80
                          GridAttrs(Row * Width + Col) = 1
                          LastPaintCol = Col : LastPaintRow = Row
                          Dirty = #True
                        EndIf
                    EndSelect
                    Scr0Ed_RedrawCanvas(G_Canvas, GridCodes(), GridAttrs(), Width, CharsetBytes(), Zoom, Palette(Ink), Palette(Paper), Palette(Ink2), Palette(Paper2), MarkCol, MarkRow)
                  EndIf
                EndIf

              Case #PB_EventType_RightButtonDown
                If ActiveTab = #Scr0Ed_Tool_Attr
                  If Width = 80
                    MouseX = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseX)
                    MouseY = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseY)
                    If MouseX >= 0 And MouseY >= 0
                      Col = MouseX / (8 * Zoom)
                      Row = MouseY / (8 * Zoom)
                      If Col >= 0 And Col < Width And Row >= 0 And Row < #Scr0Ed_Rows
                        GridAttrs(Row * Width + Col) = 0
                        LastPaintCol = Col : LastPaintRow = Row
                        Dirty = #True
                        Scr0Ed_RedrawCanvas(G_Canvas, GridCodes(), GridAttrs(), Width, CharsetBytes(), Zoom, Palette(Ink), Palette(Paper), Palette(Ink2), Palette(Paper2))
                      EndIf
                    EndIf
                  EndIf
                ElseIf MarkCol <> -1
                  MarkCol = -1 : MarkRow = -1
                  Scr0Ed_RedrawCanvas(G_Canvas, GridCodes(), GridAttrs(), Width, CharsetBytes(), Zoom, Palette(Ink), Palette(Paper), Palette(Ink2), Palette(Paper2))
                EndIf

              Case #PB_EventType_MouseMove
                If (ActiveTab = #Scr0Ed_Tool_Char Or ActiveTab = #Scr0Ed_Tool_Erase) And
                   (GetGadgetAttribute(G_Canvas, #PB_Canvas_Buttons) & #PB_Canvas_LeftButton)
                  MouseX = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseX)
                  MouseY = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseY)
                  Col = MouseX / (8 * Zoom)
                  Row = MouseY / (8 * Zoom)
                  If Col >= 0 And Col < Width And Row >= 0 And Row < #Scr0Ed_Rows And (Col <> LastPaintCol Or Row <> LastPaintRow)
                    If ActiveTab = #Scr0Ed_Tool_Char
                      GridCodes(Row * Width + Col) = Asc(CurrentStampChar)
                    Else
                      GridCodes(Row * Width + Col) = 32
                    EndIf
                    LastPaintCol = Col : LastPaintRow = Row
                    Dirty = #True
                    Scr0Ed_RedrawCanvas(G_Canvas, GridCodes(), GridAttrs(), Width, CharsetBytes(), Zoom, Palette(Ink), Palette(Paper), Palette(Ink2), Palette(Paper2))
                  EndIf
                ElseIf ActiveTab = #Scr0Ed_Tool_Attr And Width = 80
                  Protected CanvasButtons = GetGadgetAttribute(G_Canvas, #PB_Canvas_Buttons)
                  If CanvasButtons & (#PB_Canvas_LeftButton | #PB_Canvas_RightButton)
                    MouseX = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseX)
                    MouseY = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseY)
                    Col = MouseX / (8 * Zoom)
                    Row = MouseY / (8 * Zoom)
                    If Col >= 0 And Col < Width And Row >= 0 And Row < #Scr0Ed_Rows And (Col <> LastPaintCol Or Row <> LastPaintRow)
                      If CanvasButtons & #PB_Canvas_LeftButton
                        GridAttrs(Row * Width + Col) = 1
                      Else
                        GridAttrs(Row * Width + Col) = 0
                      EndIf
                      LastPaintCol = Col : LastPaintRow = Row
                      Dirty = #True
                      Scr0Ed_RedrawCanvas(G_Canvas, GridCodes(), GridAttrs(), Width, CharsetBytes(), Zoom, Palette(Ink), Palette(Paper), Palette(Ink2), Palette(Paper2))
                    EndIf
                  EndIf
                EndIf
            EndSelect

          Case G_New
            If Not Dirty Or Scr0Ed_ConfirmDiscard()
              Protected NewWidth = Scr0Ed_AskWidth(Win)
              If NewWidth = 40 Or NewWidth = 80
                ProjectDB::ListScreen0Numbers(Nav())
                If ListSize(Nav()) > 0
                  LastElement(Nav())
                  ScreenNumber = Nav() + 1
                Else
                  ScreenNumber = 1
                EndIf
                Width = NewWidth
                Ink = 15 : Paper = 1 : AlphabetNumber = -1
                Ink2 = 15 : Paper2 = 1 : BlinkOn = 8 : BlinkOff = 8
                For ClearIdx = 0 To #Scr0Ed_MaxCells - 1
                  GridCodes(ClearIdx) = 32
                  GridAttrs(ClearIdx) = 0
                Next
                MarkCol = -1 : MarkRow = -1
                Dirty = #False
                Scr0Ed_RefreshUI(G_Canvas, G_ScreenNumberText, G_Tag, G_WidthText, G_FontCombo, G_PaletteInk, G_PalettePaper,
                                 G_PaletteInk2, G_PalettePaper2, G_BlinkOnField, G_BlinkOffField,
                                 ScreenNumber, "", Width, Ink, Paper, AlphabetNumber, Ink2, Paper2, BlinkOn, BlinkOff,
                                 GridCodes(), GridAttrs(), CharsetBytes(), Palette())
              EndIf
            EndIf

          Case G_Register
            ProjectDB::StoreScreen0(ScreenNumber, GetGadgetText(G_Tag), Width, Ink, Paper, AlphabetNumber,
                                    Ink2, Paper2, BlinkOn, BlinkOff, GridCodes(), GridAttrs())
            Dirty = #False

          Case G_First, G_Prev, G_Next, G_Last
            If Not Dirty Or Scr0Ed_ConfirmDiscard()
              ProjectDB::ListScreen0Numbers(Nav())
              Select EventGadget()
                Case G_First : NavTarget = SpriteEd_FindNavTarget(Nav(), 0, ScreenNumber)
                Case G_Prev  : NavTarget = SpriteEd_FindNavTarget(Nav(), 1, ScreenNumber)
                Case G_Next  : NavTarget = SpriteEd_FindNavTarget(Nav(), 2, ScreenNumber)
                Case G_Last  : NavTarget = SpriteEd_FindNavTarget(Nav(), 3, ScreenNumber)
              EndSelect
              If NavTarget >= 0
                ScreenNumber = NavTarget
                ProjectDB::FetchScreen0(ScreenNumber, GridCodes(), GridAttrs())
                Width = ProjectDB::LastScreen0Width() : Ink = ProjectDB::LastScreen0Ink() : Paper = ProjectDB::LastScreen0Paper()
                AlphabetNumber = ProjectDB::LastScreen0AlphabetNumber()
                Ink2 = ProjectDB::LastScreen0Ink2() : Paper2 = ProjectDB::LastScreen0Paper2()
                BlinkOn = ProjectDB::LastScreen0BlinkOn() : BlinkOff = ProjectDB::LastScreen0BlinkOff()
                MarkCol = -1 : MarkRow = -1 : Dirty = #False
                Scr0Ed_RefreshUI(G_Canvas, G_ScreenNumberText, G_Tag, G_WidthText, G_FontCombo, G_PaletteInk, G_PalettePaper,
                                 G_PaletteInk2, G_PalettePaper2, G_BlinkOnField, G_BlinkOffField,
                                 ScreenNumber, ProjectDB::LastScreen0Tag(), Width, Ink, Paper, AlphabetNumber, Ink2, Paper2, BlinkOn, BlinkOff,
                                 GridCodes(), GridAttrs(), CharsetBytes(), Palette())
              EndIf
            EndIf

          Case G_Inject
            If Not InjectTextAtCursor(Scr0Ed_BuildCode(GridCodes(), GridAttrs(), Width, Ink, Paper, AlphabetNumber, Ink2, Paper2, BlinkOn, BlinkOff, CharsetBytes()))
              MessageRequester("Erro", "Nenhuma aba de texto ativa para injetar o codigo.",
                               #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
            EndIf

          Case G_Copy
            SetClipboardText(Scr0Ed_BuildCode(GridCodes(), GridAttrs(), Width, Ink, Paper, AlphabetNumber, Ink2, Paper2, BlinkOn, BlinkOff, CharsetBytes()))

          Case G_Close
            Quit = #True

        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
