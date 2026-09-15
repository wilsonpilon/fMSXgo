;
; ------------------------------------------------------------
;  Criar -> Sprite...: editor grafico basico de sprites MSX
;  Grade clicavel 8x8 ou 16x16 (os dois tamanhos de sprite suportados pelo
;  VDP do MSX) com ferramentas de desenho (lapis, borracha, pincel grosso,
;  reta, retangulo vazio/cheio, elipse vazia/cheia, balde de preenchimento)
;  usando a palheta original de 16 cores do MSX1 (TMS9918). Um canto mostra
;  a previa do sprite em escala reduzida e outro o seletor de cores. Radios
;  de modo MSX1/MSX2 controlam a regra de cor (sprite inteiro com uma cor,
;  ou uma cor por linha). Alem da montagem visual, os botoes Injetar/Inserir
;  sprite corrente/Gerar DATA do banco exportam o sprite (ou o banco inteiro)
;  como DATA no formato Basic Dignified direto no cursor da aba de texto ativa.
; ------------------------------------------------------------
;

; Area de desenho da grade sempre com o mesmo tamanho em pixels; o tamanho
; de cada bloco e que muda (8x8 = blocos maiores, 16x16 = blocos menores),
; assim a janela nao precisa ser redimensionada ao trocar de tipo.
#SpriteEd_CanvasSize  = 384
#SpriteEd_PreviewSize = 128
#SpriteEd_PaletteSize = 152
#SpriteEd_PaletteCols = 4
#SpriteEd_PaletteRows = 4
#SpriteEd_BlinkTimer     = 1   ; ID do timer que faz piscar o marcador do primeiro ponto
#SpriteEd_CancelShortcut = 1   ; ID do atalho de teclado ESC (cancela a marcacao em andamento)

Enumeration SpriteEdTools
  #SpriteTool_Default        ; nenhuma ferramenta pressionada - clique inverte o ponto
  #SpriteTool_Pencil
  #SpriteTool_Eraser
  #SpriteTool_Brush          ; como o lapis, mas pinta um bloco 2x2 por vez
  #SpriteTool_Line
  #SpriteTool_RectOutline
  #SpriteTool_RectFill
  #SpriteTool_EllipseOutline
  #SpriteTool_EllipseFill
  #SpriteTool_Fill           ; balde: preenche a area conectada com a cor atual
EndEnumeration

Structure SpriteEdPoint
  Row.i
  Col.i
EndStructure

; As 16 cores da palheta original do MSX1 (TMS9918), indice 0 = transparente
; (sem cor propria - mostrada como bloco vazio/hachurado no seletor).
Procedure SpriteEd_FillPalette(Array Palette.l(1), Array Names.s(1))
  Palette(0)  = 0            : Names(0)  = "Transparente"
  Palette(1)  = RGB(0,   0,   0)   : Names(1)  = "Preto"
  Palette(2)  = RGB(62,  184, 73)  : Names(2)  = "Verde medio"
  Palette(3)  = RGB(116, 208, 125) : Names(3)  = "Verde claro"
  Palette(4)  = RGB(89,  85,  224) : Names(4)  = "Azul escuro"
  Palette(5)  = RGB(128, 118, 241) : Names(5)  = "Azul claro"
  Palette(6)  = RGB(185, 94,  81)  : Names(6)  = "Vermelho escuro"
  Palette(7)  = RGB(101, 219, 239) : Names(7)  = "Ciano"
  Palette(8)  = RGB(219, 101, 89)  : Names(8)  = "Vermelho medio"
  Palette(9)  = RGB(255, 137, 125) : Names(9)  = "Vermelho claro"
  Palette(10) = RGB(204, 195, 94)  : Names(10) = "Amarelo escuro"
  Palette(11) = RGB(222, 208, 135) : Names(11) = "Amarelo claro"
  Palette(12) = RGB(58,  162, 65)  : Names(12) = "Verde escuro"
  Palette(13) = RGB(183, 102, 181) : Names(13) = "Magenta"
  Palette(14) = RGB(204, 204, 204) : Names(14) = "Cinza"
  Palette(15) = RGB(255, 255, 255) : Names(15) = "Branco"
EndProcedure

Procedure.s SpriteEd_StatusText(GridSize.i)
  ProcedureReturn "Tamanho: " + Str(GridSize) + " x " + Str(GridSize) +
                  " (" + Str(GridSize * GridSize) + " blocos)"
EndProcedure

Procedure.s SpriteEd_ColorText(ColorIndex.i, Array Names.s(1))
  ProcedureReturn "Cor: " + Str(ColorIndex) + " - " + Names(ColorIndex)
EndProcedure

Procedure SpriteEd_ClearGrid(Array Grid.b(2))
  Protected Row, Col
  For Row = 0 To ArraySize(Grid(), 1)
    For Col = 0 To ArraySize(Grid(), 2)
      Grid(Row, Col) = 0
    Next
  Next
EndProcedure

; Inverte o sprite: blocos vazios (0) passam a usar a cor atual e blocos
; pintados (com qualquer cor) viram vazios.
Procedure SpriteEd_InvertGrid(Array Grid.b(2), GridSize.i, SelectedColor.i)
  Protected Row, Col
  For Row = 0 To GridSize - 1
    For Col = 0 To GridSize - 1
      If Grid(Row, Col) = 0
        Grid(Row, Col) = SelectedColor
      Else
        Grid(Row, Col) = 0
      EndIf
    Next
  Next
EndProcedure

; Aplica a ferramenta atual a um bloco: lapis sempre pinta, borracha sempre
; apaga, pincel pinta um bloco 2x2 (ancorado no bloco clicado), e o padrao
; (nenhuma ferramenta pressionada) inverte o ponto.
Procedure SpriteEd_ApplyTool(Array Grid.b(2), Row.i, Col.i, ToolMode.i, SelectedColor.i, GridSize.i)
  Protected BR, BC
  Select ToolMode
    Case #SpriteTool_Pencil
      Grid(Row, Col) = SelectedColor
    Case #SpriteTool_Eraser
      Grid(Row, Col) = 0
    Case #SpriteTool_Brush
      For BR = Row To Row + 1
        For BC = Col To Col + 1
          If BR >= 0 And BR < GridSize And BC >= 0 And BC < GridSize
            Grid(BR, BC) = SelectedColor
          EndIf
        Next
      Next
    Default  ; padrao - inverte o ponto
      If Grid(Row, Col) = 0
        Grid(Row, Col) = SelectedColor
      Else
        Grid(Row, Col) = 0
      EndIf
  EndSelect
EndProcedure

; Move o conteudo da grade por (DX,DY) blocos (-1/0/1 em cada eixo). Com
; Wrap ligado o conteudo que sai de um lado reaparece do outro (rotacionar);
; sem Wrap o espaco que fica livre vira transparente e o que sai se perde
; (deslocar).
Procedure SpriteEd_TranslateGrid(Array Grid.b(2), GridSize.i, DX.i, DY.i, Wrap.b)
  Protected Row, Col, SrcRow, SrcCol
  Dim Temp.b(15, 15)
  For Row = 0 To GridSize - 1
    For Col = 0 To GridSize - 1
      Temp(Row, Col) = Grid(Row, Col)
    Next
  Next

  For Row = 0 To GridSize - 1
    For Col = 0 To GridSize - 1
      SrcRow = Row - DY
      SrcCol = Col - DX
      If Wrap
        SrcRow = (SrcRow % GridSize + GridSize) % GridSize
        SrcCol = (SrcCol % GridSize + GridSize) % GridSize
        Grid(Row, Col) = Temp(SrcRow, SrcCol)
      ElseIf SrcRow >= 0 And SrcRow < GridSize And SrcCol >= 0 And SrcCol < GridSize
        Grid(Row, Col) = Temp(SrcRow, SrcCol)
      Else
        Grid(Row, Col) = 0
      EndIf
    Next
  Next
EndProcedure

; Recolore todos os blocos ja pintados (nao mexe nos transparentes).
Procedure SpriteEd_RecolorAll(Array Grid.b(2), GridSize.i, ColorIdx.i)
  Protected Row, Col
  For Row = 0 To GridSize - 1
    For Col = 0 To GridSize - 1
      If Grid(Row, Col) > 0
        Grid(Row, Col) = ColorIdx
      EndIf
    Next
  Next
EndProcedure

; Recolore os blocos ja pintados de uma unica linha.
Procedure SpriteEd_RecolorRow(Array Grid.b(2), GridSize.i, TargetRow.i, ColorIdx.i)
  Protected Col
  If TargetRow < 0 Or TargetRow >= GridSize
    ProcedureReturn
  EndIf
  For Col = 0 To GridSize - 1
    If Grid(TargetRow, Col) > 0
      Grid(TargetRow, Col) = ColorIdx
    EndIf
  Next
EndProcedure

; No MSX2 cada linha pode ter sua propria cor, mas dentro da linha e uma cor
; so: qualquer linha que tenha pelo menos um bloco com ColorIdx passa a ter
; TODOS os seus blocos pintados recolorados para ColorIdx. Funciona para
; qualquer operacao (pintar, reta, retangulo, elipse, balde) sem precisar
; saber de antemao quais linhas foram afetadas.
Procedure SpriteEd_EnforceMSX2ForColor(Array Grid.b(2), GridSize.i, ColorIdx.i)
  Protected Row, Col, Found.b
  For Row = 0 To GridSize - 1
    Found = #False
    For Col = 0 To GridSize - 1
      If Grid(Row, Col) = ColorIdx
        Found = #True
        Break
      EndIf
    Next
    If Found
      SpriteEd_RecolorRow(Grid(), GridSize, Row, ColorIdx)
    EndIf
  Next
EndProcedure

; Garante a regra de cor do modo MSX apos uma pintura/forma: no MSX1
; (SpriteMode=1) o sprite inteiro so pode ter uma cor; no MSX2 (SpriteMode=2)
; cada linha pode ter a sua propria cor, mas uma cor so dentro da linha.
Procedure SpriteEd_EnforceColorMode(Array Grid.b(2), GridSize.i, SpriteMode.i, ColorIdx.i)
  If SpriteMode = 1
    SpriteEd_RecolorAll(Grid(), GridSize, ColorIdx)
  Else
    SpriteEd_EnforceMSX2ForColor(Grid(), GridSize, ColorIdx)
  EndIf
EndProcedure

; Traca uma reta (algoritmo de Bresenham) entre dois blocos da grade,
; pintando cada bloco no caminho com a cor indicada.
Procedure SpriteEd_DrawLine(Array Grid.b(2), R0.i, C0.i, R1.i, C1.i, ColorIdx.i, GridSize.i)
  Protected dRow = Abs(R1 - R0), dCol = Abs(C1 - C0)
  Protected sRow, sCol, err, e2
  Protected Row = R0, Col = C0

  If R0 < R1 : sRow = 1 : Else : sRow = -1 : EndIf
  If C0 < C1 : sCol = 1 : Else : sCol = -1 : EndIf
  err = dCol - dRow

  Repeat
    If Row >= 0 And Row < GridSize And Col >= 0 And Col < GridSize
      Grid(Row, Col) = ColorIdx
    EndIf
    If Row = R1 And Col = C1
      Break
    EndIf
    e2 = err * 2
    If e2 > -dRow
      err = err - dRow
      Col = Col + sCol
    EndIf
    If e2 < dCol
      err = err + dCol
      Row = Row + sRow
    EndIf
  ForEver
EndProcedure

; Retangulo entre dois cantos opostos (R0,C0)-(R1,C1); Filled liga/desliga
; preenchimento (senao so o contorno).
Procedure SpriteEd_DrawRect(Array Grid.b(2), R0.i, C0.i, R1.i, C1.i, ColorIdx.i, Filled.b)
  Protected RowMin = R0, RowMax = R1, ColMin = C0, ColMax = C1, Row, Col
  If RowMin > RowMax : Swap RowMin, RowMax : EndIf
  If ColMin > ColMax : Swap ColMin, ColMax : EndIf

  If Filled
    For Row = RowMin To RowMax
      For Col = ColMin To ColMax
        Grid(Row, Col) = ColorIdx
      Next
    Next
  Else
    For Col = ColMin To ColMax
      Grid(RowMin, Col) = ColorIdx
      Grid(RowMax, Col) = ColorIdx
    Next
    For Row = RowMin To RowMax
      Grid(Row, ColMin) = ColorIdx
      Grid(Row, ColMax) = ColorIdx
    Next
  EndIf
EndProcedure

; Elipse/circulo inscrito na caixa delimitadora entre (R0,C0)-(R1,C1);
; Filled liga/desliga preenchimento. Sem preenchimento, so os blocos da
; borda (dentro da elipse mas com pelo menos um vizinho ortogonal fora)
; sao pintados - aproximacao razoavel numa grade tao pequena.
Procedure SpriteEd_DrawEllipse(Array Grid.b(2), R0.i, C0.i, R1.i, C1.i, ColorIdx.i, Filled.b)
  Protected RowMin = R0, RowMax = R1, ColMin = C0, ColMax = C1, Row, Col
  If RowMin > RowMax : Swap RowMin, RowMax : EndIf
  If ColMin > ColMax : Swap ColMin, ColMax : EndIf

  Protected.f CenterRow = (RowMin + RowMax) / 2.0
  Protected.f CenterCol = (ColMin + ColMax) / 2.0
  Protected.f RadiusRow = (RowMax - RowMin) / 2.0
  Protected.f RadiusCol = (ColMax - ColMin) / 2.0
  If RadiusRow < 0.5 : RadiusRow = 0.5 : EndIf
  If RadiusCol < 0.5 : RadiusCol = 0.5 : EndIf

  Protected.f DX, DY
  Dim Inside.b(15, 15)
  For Row = RowMin To RowMax
    For Col = ColMin To ColMax
      DX = (Col - CenterCol) / RadiusCol
      DY = (Row - CenterRow) / RadiusRow
      If DX * DX + DY * DY <= 1.0
        Inside(Row, Col) = #True
      EndIf
    Next
  Next

  Protected IsEdge.b
  For Row = RowMin To RowMax
    For Col = ColMin To ColMax
      If Inside(Row, Col)
        If Filled
          Grid(Row, Col) = ColorIdx
        Else
          If Row = RowMin Or Row = RowMax Or Col = ColMin Or Col = ColMax
            IsEdge = #True
          Else
            IsEdge = Bool(Not Inside(Row - 1, Col) Or Not Inside(Row + 1, Col) Or
                          Not Inside(Row, Col - 1) Or Not Inside(Row, Col + 1))
          EndIf
          If IsEdge
            Grid(Row, Col) = ColorIdx
          EndIf
        EndIf
      EndIf
    Next
  Next
EndProcedure

; Balde de tinta: preenche com ColorIdx toda a area conectada (4 direcoes)
; que comeca com a mesma cor do bloco clicado.
Procedure SpriteEd_FloodFill(Array Grid.b(2), GridSize.i, StartRow.i, StartCol.i, ColorIdx.i)
  Protected TargetColor = Grid(StartRow, StartCol)
  If TargetColor = ColorIdx
    ProcedureReturn
  EndIf

  NewList Stack.SpriteEdPoint()
  AddElement(Stack())
  Stack()\Row = StartRow
  Stack()\Col = StartCol
  Grid(StartRow, StartCol) = ColorIdx

  Protected Row, Col
  While ListSize(Stack()) > 0
    LastElement(Stack())
    Row = Stack()\Row
    Col = Stack()\Col
    DeleteElement(Stack())

    If Row > 0 And Grid(Row - 1, Col) = TargetColor
      Grid(Row - 1, Col) = ColorIdx
      AddElement(Stack()) : Stack()\Row = Row - 1 : Stack()\Col = Col
    EndIf
    If Row < GridSize - 1 And Grid(Row + 1, Col) = TargetColor
      Grid(Row + 1, Col) = ColorIdx
      AddElement(Stack()) : Stack()\Row = Row + 1 : Stack()\Col = Col
    EndIf
    If Col > 0 And Grid(Row, Col - 1) = TargetColor
      Grid(Row, Col - 1) = ColorIdx
      AddElement(Stack()) : Stack()\Row = Row : Stack()\Col = Col - 1
    EndIf
    If Col < GridSize - 1 And Grid(Row, Col + 1) = TargetColor
      Grid(Row, Col + 1) = ColorIdx
      AddElement(Stack()) : Stack()\Row = Row : Stack()\Col = Col + 1
    EndIf
  Wend
EndProcedure

; Calcula, numa mascara a parte (nunca mexe na grade de verdade), quais
; blocos a forma pendente (reta/retangulo/elipse) ocuparia se o segundo
; ponto fosse (R1,C1) agora - reaproveita as mesmas rotinas que desenham de
; verdade, so que escrevendo na mascara com o marcador 1 em vez da cor.
Procedure SpriteEd_ComputePreviewMask(Array Mask.b(2), GridSize.i, ToolMode.i, R0.i, C0.i, R1.i, C1.i)
  SpriteEd_ClearGrid(Mask())
  Select ToolMode
    Case #SpriteTool_Line
      SpriteEd_DrawLine(Mask(), R0, C0, R1, C1, 1, GridSize)
    Case #SpriteTool_RectOutline
      SpriteEd_DrawRect(Mask(), R0, C0, R1, C1, 1, #False)
    Case #SpriteTool_RectFill
      SpriteEd_DrawRect(Mask(), R0, C0, R1, C1, 1, #True)
    Case #SpriteTool_EllipseOutline
      SpriteEd_DrawEllipse(Mask(), R0, C0, R1, C1, 1, #False)
    Case #SpriteTool_EllipseFill
      SpriteEd_DrawEllipse(Mask(), R0, C0, R1, C1, 1, #True)
  EndSelect
EndProcedure

; Desenha por cima da grade ja renderizada (chamar logo apos SpriteEd_Redraw,
; sem limpar o canvas): um contorno colorido em cada bloco da mascara de
; previa, mais um marcador (circulo preto com aro branco) no ponto inicial,
; que so aparece quando ShowMarker esta ligado - o chamador alterna isso a
; cada estouro do timer de piscar.
Procedure SpriteEd_DrawPreviewOverlay(Canvas, GridSize.i, CellSize.i, Array Mask.b(2), PreviewColor.l, ShowMarker.b, StartRow.i, StartCol.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf

  Protected Row, Col, X, Y
  DrawingMode(#PB_2DDrawing_Outlined)
  For Row = 0 To GridSize - 1
    For Col = 0 To GridSize - 1
      If Mask(Row, Col)
        X = Col * CellSize
        Y = Row * CellSize
        Box(X + 1, Y + 1, CellSize - 1, CellSize - 1, PreviewColor)
        Box(X + 2, Y + 2, CellSize - 3, CellSize - 3, PreviewColor)
      EndIf
    Next
  Next

  If ShowMarker And StartRow >= 0
    X = StartCol * CellSize
    Y = StartRow * CellSize
    DrawingMode(#PB_2DDrawing_Default)
    Circle(X + CellSize / 2, Y + CellSize / 2, CellSize / 4 + 1, RGB(0, 0, 0))
    DrawingMode(#PB_2DDrawing_Outlined)
    Circle(X + CellSize / 2, Y + CellSize / 2, CellSize / 4 + 1, RGB(255, 255, 255))
  EndIf

  StopDrawing()
EndProcedure

; Icone do botao "Inverter": circulo meio preto/meio branco, simbolo classico
; de inversao de cores. Desenhado em memoria (sem depender de arquivo externo).
Procedure SpriteEd_CreateInvertIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected R = Size / 2 - 2
    Circle(Size / 2, Size / 2, R, RGB(15, 15, 15))
    Box(Size / 2, Size / 2 - R, R + 1, R * 2 + 1, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Circle(Size / 2, Size / 2, R, RGB(90, 90, 90))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Limpar": mini-grade de blocos riscada por uma linha
; diagonal vermelha (simbolo de "apagar tudo").
Procedure SpriteEd_CreateClearIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected Cell = (Size - 6) / 2
    Box(2, 2, Cell, Cell, RGB(190, 190, 190))
    Box(Size - 2 - Cell, 2, Cell, Cell, RGB(190, 190, 190))
    Box(2, Size - 2 - Cell, Cell, Cell, RGB(190, 190, 190))
    Box(Size - 2 - Cell, Size - 2 - Cell, Cell, Cell, RGB(190, 190, 190))
    Protected i
    For i = -1 To 1
      LineXY(1 + i, Size - 2, Size - 2, 1 + i, RGB(205, 45, 40))
    Next
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(0, 0, Size, Size, RGB(150, 150, 150))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Lapis": corpo diagonal marrom/laranja com ponta escura de
; grafite num extremo e ponta rosa (borracha) no outro.
Procedure SpriteEd_CreatePencilIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected i
    For i = -1 To 1
      LineXY(4 + i, Size - 4, Size - 6, 4 + i, RGB(224, 150, 60))
    Next
    LineXY(Size - 6, 4, Size - 3, 2, RGB(60, 45, 30))
    LineXY(Size - 5, 5, Size - 2, 3, RGB(60, 45, 30))
    LineXY(Size - 4, 6, Size - 1, 4, RGB(60, 45, 30))
    Box(2, Size - 6, 4, 4, RGB(230, 120, 150))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Borracha": bloco rosa com friso claro no topo, como uma
; borracha escolar vista de frente.
Procedure SpriteEd_CreateEraserIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Box(3, 6, Size - 6, Size - 10, RGB(235, 140, 150))
    Box(3, 6, Size - 6, 4, RGB(250, 205, 210))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(3, 6, Size - 6, Size - 10, RGB(120, 60, 70))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Pincel": cabo curto e uma virola metalica levando a uma
; bolha de tinta azul bem maior que a pontinha do lapis (pincel "grosso").
Procedure SpriteEd_CreateBrushIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected i
    For i = -1 To 1
      LineXY(3 + i, Size - 3, Size - 9, 9 + i, RGB(120, 80, 50))
    Next
    LineXY(Size - 9, 9, Size - 6, 6, RGB(190, 190, 200))
    LineXY(Size - 8, 10, Size - 5, 7, RGB(190, 190, 200))
    Circle(Size - 5, 5, 4, RGB(50, 120, 210))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Reta": dois pontos (circulos) ligados por uma linha
; diagonal, lembrando o gesto de marcar dois pontos para tracar a reta.
Procedure SpriteEd_CreateLineToolIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    LineXY(3, Size - 4, Size - 4, 3, RGB(20, 20, 20))
    Circle(3, Size - 4, 3, RGB(30, 110, 220))
    Circle(Size - 4, 3, 3, RGB(30, 110, 220))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Retangulo vazio": contorno azul.
Procedure SpriteEd_CreateRectOutlineIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(3, 4, Size - 6, Size - 8, RGB(40, 90, 180))
    Box(4, 5, Size - 8, Size - 10, RGB(40, 90, 180))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Retangulo cheio": bloco azul preenchido.
Procedure SpriteEd_CreateRectFillIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Box(3, 4, Size - 6, Size - 8, RGB(70, 130, 210))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(3, 4, Size - 6, Size - 8, RGB(30, 70, 140))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Elipse/circulo vazio": contorno magenta.
Procedure SpriteEd_CreateEllipseOutlineIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Ellipse(Size / 2, Size / 2, Size / 2 - 3, Size / 2 - 4, RGB(180, 60, 120))
    Ellipse(Size / 2, Size / 2, Size / 2 - 4, Size / 2 - 5, RGB(180, 60, 120))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Elipse/circulo cheio": bolha magenta preenchida.
Procedure SpriteEd_CreateEllipseFillIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Ellipse(Size / 2, Size / 2, Size / 2 - 3, Size / 2 - 4, RGB(210, 90, 150))
    DrawingMode(#PB_2DDrawing_Outlined)
    Ellipse(Size / 2, Size / 2, Size / 2 - 3, Size / 2 - 4, RGB(140, 40, 90))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Preencher area": baldinho (trapezio marrom desenhado com
; linhas horizontais decrescentes) pingando tinta azul - clássico icone de
; "balde de tinta".
Procedure SpriteEd_CreateFillIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected y
    Protected.f halfw, frac
    Protected TopY = 3, BottomY = 14
    Protected.f TopHalfW = 3, BottomHalfW = 6
    Protected CenterX = 8
    For y = TopY To BottomY
      frac = (y - TopY) / (BottomY - TopY)
      halfw = TopHalfW + (BottomHalfW - TopHalfW) * frac
      LineXY(CenterX - halfw, y, CenterX + halfw, y, RGB(150, 105, 65))
    Next
    Circle(17, 15, 3, RGB(50, 120, 210))
    Circle(20, 19, 2, RGB(50, 120, 210))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Novo sprite": pagina em branco com um "+" verde no canto.
Procedure SpriteEd_CreateNewSpriteIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(2, 2, Size - 8, Size - 4, RGB(120, 120, 120))
    Box(3, 3, Size - 10, Size - 6, RGB(120, 120, 120))
    DrawingMode(#PB_2DDrawing_Default)
    Box(Size - 9, Size / 2 - 1, 8, 2, RGB(40, 140, 70))
    Box(Size - 6, Size / 2 - 4, 2, 8, RGB(40, 140, 70))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Registrar": ficha/cartao de indice com linhas de campo e
; um marcador vermelho no canto (estilo "gravado").
Procedure SpriteEd_CreateRegisterIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Box(2, 3, Size - 4, Size - 6, RGB(250, 250, 235))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(2, 3, Size - 4, Size - 6, RGB(150, 130, 60))
    DrawingMode(#PB_2DDrawing_Default)
    Box(5, 7, Size - 10, 2, RGB(150, 130, 60))
    Box(5, 11, Size - 10, 2, RGB(150, 130, 60))
    Box(5, 15, Size - 14, 2, RGB(150, 130, 60))
    Circle(Size - 6, Size - 6, 3, RGB(200, 50, 50))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Copiar": duas folhinhas empilhadas (a de tras aparecendo
; atras da da frente), estilo icone classico de copiar.
Procedure SpriteEd_CreateCopyIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(7, 2, Size - 10, Size - 6, RGB(90, 90, 90))
    DrawingMode(#PB_2DDrawing_Default)
    Box(2, 6, Size - 10, Size - 6, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(2, 6, Size - 10, Size - 6, RGB(90, 90, 90))
    DrawingMode(#PB_2DDrawing_Default)
    Line(5, 9, Size - 16, 0, RGB(90, 90, 90))
    Line(5, 13, Size - 16, 0, RGB(90, 90, 90))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Colar": prancheta (clipboard) com grampo no topo e linhas
; de texto, estilo icone classico de colar.
Procedure SpriteEd_CreatePasteIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Box(4, 5, Size - 8, Size - 7, RGB(250, 250, 240))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(4, 5, Size - 8, Size - 7, RGB(90, 90, 90))
    DrawingMode(#PB_2DDrawing_Default)
    Box(Size / 2 - 3, 2, 6, 5, RGB(150, 150, 150))
    Line(7, 10, Size - 14, 0, RGB(90, 90, 90))
    Line(7, 14, Size - 14, 0, RGB(90, 90, 90))
    Line(7, 18, Size - 14, 0, RGB(90, 90, 90))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Injetar": pagina de codigo (retangulo com linhas de texto)
; recebendo uma seta apontando pra baixo - simbolo de "inserir/injetar".
Procedure SpriteEd_CreateInjectIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(2, 11, Size - 4, Size - 13, RGB(90, 90, 90))
    DrawingMode(#PB_2DDrawing_Default)
    Line(5, 15, Size - 10, 0, RGB(150, 150, 150))
    Line(5, 19, Size - 10, 0, RGB(150, 150, 150))
    Protected i
    For i = -1 To 1
      LineXY(Size / 2 + i, 1, Size / 2 + i, 9, RGB(40, 140, 70))
    Next
    LineXY(Size / 2 - 4, 6, Size / 2, 11, RGB(40, 140, 70))
    LineXY(Size / 2 + 4, 6, Size / 2, 11, RGB(40, 140, 70))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Inserir sprite corrente": igual ao de Injetar (pagina de
; codigo recebendo seta reta azul), mais um lacinho laranja (seta circular)
; ao lado, simbolizando o loop de leitura que este botao gera junto do DATA.
Procedure SpriteEd_CreateInsertLoopIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(2, 11, Size - 4, Size - 13, RGB(90, 90, 90))
    DrawingMode(#PB_2DDrawing_Default)
    Line(5, 15, Size - 10, 0, RGB(150, 150, 150))
    Line(5, 19, Size - 10, 0, RGB(150, 150, 150))
    Protected i
    For i = -1 To 1
      LineXY(6 + i, 1, 6 + i, 9, RGB(60, 110, 210))
    Next
    LineXY(2, 6, 6, 11, RGB(60, 110, 210))
    LineXY(10, 6, 6, 11, RGB(60, 110, 210))
    DrawingMode(#PB_2DDrawing_Outlined)
    Circle(Size - 6, 5, 4, RGB(210, 130, 40))
    DrawingMode(#PB_2DDrawing_Default)
    LineXY(Size - 3, 2, Size - 1, 4, RGB(210, 130, 40))
    LineXY(Size - 1, 4, Size - 4, 5, RGB(210, 130, 40))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Gerar DATA do banco": tres paginas empilhadas (todos os
; sprites ja registrados no projeto) com uma seta roxa para baixo.
Procedure SpriteEd_CreateInsertAllIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(1, 10, Size - 8, Size - 13, RGB(150, 150, 150))
    Box(3, 12, Size - 8, Size - 13, RGB(120, 120, 120))
    Box(5, 14, Size - 8, Size - 13, RGB(90, 90, 90))
    DrawingMode(#PB_2DDrawing_Default)
    Protected i
    For i = -1 To 1
      LineXY(Size / 2 + 2 + i, 0, Size / 2 + 2 + i, 8, RGB(130, 80, 190))
    Next
    LineXY(Size / 2 - 2, 5, Size / 2 + 2, 9, RGB(130, 80, 190))
    LineXY(Size / 2 + 6, 5, Size / 2 + 2, 9, RGB(130, 80, 190))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Empacota um bloco 8x8 da grade (comecando em RowOff,ColOff) em 8 bytes hex
; (um por linha, bit 7 = pixel mais a esquerda) - bloco basico tanto do
; sprite 8x8 (um bloco so) quanto de cada quadrante do sprite 16x16.
Procedure.s SpriteEd_PackBlockHex(Array Grid.b(2), RowOff.i, ColOff.i)
  Protected Result.s = "", Row, Col, ByteVal
  For Row = 0 To 7
    ByteVal = 0
    For Col = 0 To 7
      If Grid(RowOff + Row, ColOff + Col) > 0
        ByteVal = ByteVal | (1 << (7 - Col))
      EndIf
    Next
    Result = Result + "&H" + RSet(Hex(ByteVal), 2, "0") + ","
  Next
  ProcedureReturn Result
EndProcedure

; Bytes do padrao (silhueta) do sprite inteiro, em hexadecimal de 2 digitos:
; 8 bytes pra 8x8; pra 16x16 sao 4 blocos de 8 bytes, na ordem de quadrantes
; TL,BL,TR,BR que o MSX-BASIC exige pra sprite grande (SPRITE$).
Procedure.s SpriteEd_PackPatternHex(Array Grid.b(2), GridSize.i)
  Protected Result.s
  If GridSize = 8
    Result = SpriteEd_PackBlockHex(Grid(), 0, 0)
  Else
    Result = SpriteEd_PackBlockHex(Grid(), 0, 0) +
             SpriteEd_PackBlockHex(Grid(), 8, 0) +
             SpriteEd_PackBlockHex(Grid(), 0, 8) +
             SpriteEd_PackBlockHex(Grid(), 8, 8)
  EndIf
  If Right(Result, 1) = ","
    Result = Left(Result, Len(Result) - 1)
  EndIf
  ProcedureReturn Result
EndProcedure

; Cor(es) do sprite em hexadecimal de 2 digitos: um valor so no MSX1 (sprite
; inteiro com uma cor); um valor por linha no MSX2 (a cor do primeiro bloco
; pintado daquela linha, ou 0 se a linha estiver vazia).
Procedure.s SpriteEd_PackColorsHex(Array Grid.b(2), GridSize.i, SpriteMode.i, SelectedColor.i)
  Protected Result.s = ""
  If SpriteMode = 1
    Result = "&H" + RSet(Hex(SelectedColor), 2, "0")
  Else
    Protected Row, Col, RowColor
    For Row = 0 To GridSize - 1
      RowColor = 0
      For Col = 0 To GridSize - 1
        If Grid(Row, Col) > 0
          RowColor = Grid(Row, Col)
          Break
        EndIf
      Next
      Result = Result + "&H" + RSet(Hex(RowColor), 2, "0") + ","
    Next
    If Right(Result, 1) = ","
      Result = Left(Result, Len(Result) - 1)
    EndIf
  EndIf
  ProcedureReturn Result
EndProcedure

; Monta o texto completo (comentario + 3 linhas DATA) que o botao "Injetar"
; cola no cursor - formato lido pela rotina generica de sample/sprite_loader.dmx:
; 1) tamanho da grade + modo, 2) cor(es), 3) bytes do padrao.
Procedure.s SpriteEd_BuildInjectText(Array Grid.b(2), GridSize.i, SpriteMode.i, SelectedColor.i, SpriteNumber.i, SpriteTag.s)
  Protected TagSuffix.s = ""
  If SpriteTag <> ""
    TagSuffix = " (" + SpriteTag + ")"
  EndIf

  Protected Text.s = "' Sprite #" + Str(SpriteNumber) + TagSuffix + " - " + Str(GridSize) + "x" + Str(GridSize) +
                      " MSX" + Str(SpriteMode) + #CRLF$
  Text + "data &H" + RSet(Hex(GridSize), 2, "0") + ",&H" + RSet(Hex(SpriteMode), 2, "0") + #CRLF$
  Text + "data " + SpriteEd_PackColorsHex(Grid(), GridSize, SpriteMode, SelectedColor) + #CRLF$
  Text + "data " + SpriteEd_PackPatternHex(Grid(), GridSize) + #CRLF$
  ProcedureReturn Text
EndProcedure

; Monta o loop FOR/READ que consome o DATA deste sprite e junta os bytes nas
; variaveis temporarias sp<N>_cor$/sp<N>_pat$ - limites do loop fixos de
; acordo com o tamanho (8x8 = 8 bytes, 16x16 = 32 bytes) e o modo (MSX1 = 1
; byte de cor lido direto, MSX2 = 1 byte de cor por linha, GridSize bytes)
; deste sprite especifico, sem precisar reler tamanho/modo do proprio DATA
; feito pela func .CreateSprite generica de sample/sprite_loader.dmx.
; Nomes de variavel longos (3+ caracteres) de proposito: o Basic Dignified
; encurta cada um automaticamente pra uma variavel de 2 letras unica (ver
; docs/BADIG-USER.md), entao o prefixo com o numero do sprite so serve pra
; manter o codigo gerado legivel quando varios sprites forem inseridos em
; sequencia - nao ha risco real de colisao.
Procedure.s SpriteEd_BuildReadLoopText(GridSize.i, SpriteMode.i, SpriteNumber.i)
  Protected Quote.s = Chr(34)
  Protected VarPrefix.s = "sp" + Str(SpriteNumber) + "_"
  Protected PatternBytes.i = 8
  If GridSize = 16
    PatternBytes = 32
  EndIf
  Protected Text.s = ""

  If SpriteMode = 1
    Text + "read " + VarPrefix + "cor" + #CRLF$
  Else
    Text + VarPrefix + "cor$ = " + Quote + Quote + #CRLF$
    Text + "for " + VarPrefix + "i = 1 to " + Str(GridSize) + #CRLF$
    Text + "  read " + VarPrefix + "c" + #CRLF$
    Text + "  " + VarPrefix + "cor$ = " + VarPrefix + "cor$ + chr$(" + VarPrefix + "c)" + #CRLF$
    Text + "next " + VarPrefix + "i" + #CRLF$
  EndIf

  Text + VarPrefix + "pat$ = " + Quote + Quote + #CRLF$
  Text + "for " + VarPrefix + "i = 1 to " + Str(PatternBytes) + #CRLF$
  Text + "  read " + VarPrefix + "b" + #CRLF$
  Text + "  " + VarPrefix + "pat$ = " + VarPrefix + "pat$ + chr$(" + VarPrefix + "b)" + #CRLF$
  Text + "next " + VarPrefix + "i" + #CRLF$

  ProcedureReturn Text
EndProcedure

; Monta o texto completo que o botao "Inserir sprite corrente" cola no
; cursor: {label} + as 3 linhas DATA (mesmo formato de SpriteEd_BuildInjectText)
; + RESTORE pro label + o loop de leitura (SpriteEd_BuildReadLoopText) +
; um comentario-guia parando o cursor no ponto onde falta so atribuir as
; variaveis temporarias a um numero de sprite (0-31).
Procedure.s SpriteEd_BuildInsertLoopText(Array Grid.b(2), GridSize.i, SpriteMode.i, SelectedColor.i, SpriteNumber.i, SpriteTag.s)
  Protected VarPrefix.s = "sp" + Str(SpriteNumber) + "_"
  Protected LabelName.s = "spr" + Str(SpriteNumber)

  Protected Text.s = "{" + LabelName + "}" + #CRLF$
  Text + SpriteEd_BuildInjectText(Grid(), GridSize, SpriteMode, SelectedColor, SpriteNumber, SpriteTag)
  Text + #CRLF$
  Text + "restore {" + LabelName + "}" + #CRLF$
  Text + SpriteEd_BuildReadLoopText(GridSize, SpriteMode, SpriteNumber)
  Text + #CRLF$
  Text + "' Atribua " + VarPrefix + "pat$"
  If SpriteMode = 2
    Text + " e " + VarPrefix + "cor$"
  EndIf
  Text + " a um sprite numerado (0-31), ex.:" + #CRLF$
  Text + "'   sprite$(N) = " + VarPrefix + "pat$" + #CRLF$
  If SpriteMode = 2
    Text + "'   color sprite$(N) = " + VarPrefix + "cor$" + #CRLF$
  EndIf
  Text + #CRLF$

  ProcedureReturn Text
EndProcedure

; Primeira cor nao-transparente encontrada na grade (varredura linha a
; linha) - usada no lugar da SelectedColor "ao vivo" do editor (que so
; acompanha o sprite atualmente aberto na tela, nao cada sprite do banco)
; pra montar corretamente a cor MSX1 de um sprite so lido do ProjectDB.
Procedure.i SpriteEd_FirstColorInGrid(Array Grid.b(2), GridSize.i)
  Protected Row, Col
  For Row = 0 To GridSize - 1
    For Col = 0 To GridSize - 1
      If Grid(Row, Col) > 0
        ProcedureReturn Grid(Row, Col)
      EndIf
    Next
  Next
  ProcedureReturn 0
EndProcedure

; Monta o DATA (comentario + {label} proprio + as 3 linhas DATA) de todos os
; sprites ja registrados no banco do projeto, na ordem crescente de numero -
; usado pelo botao "Gerar DATA do banco". So o DATA (sem loop de leitura):
; cada bloco pode ser consumido depois com "restore {sprN}" + a func generica
; de sample/sprite_loader.dmx, ou com o loop montado por
; SpriteEd_BuildReadLoopText pra cada sprite individualmente.
Procedure.s SpriteEd_BuildAllSpritesDataText()
  Protected Text.s = ""
  Protected Number.i, GridSize.i, SpriteMode.i
  Dim BankGrid.b(15, 15)

  NewList Numbers.i()
  ProjectDB::ListSpriteNumbers(Numbers())

  ForEach Numbers()
    Number = Numbers()
    If ProjectDB::FetchSprite(Number, BankGrid())
      GridSize = ProjectDB::LastGridSize()
      SpriteMode = ProjectDB::LastSpriteMode()
      Text + "{spr" + Str(Number) + "}" + #CRLF$
      Text + SpriteEd_BuildInjectText(BankGrid(), GridSize, SpriteMode, SpriteEd_FirstColorInGrid(BankGrid(), GridSize), Number, ProjectDB::LastTag())
      Text + #CRLF$
    EndIf
  Next

  ProcedureReturn Text
EndProcedure

; Grade principal (editavel): cada bloco pintado usa a cor da palheta
; associada a ele; blocos em 0 (transparente) ficam com o fundo branco.
Procedure SpriteEd_Redraw(Canvas, GridSize.i, CellSize.i, Array Grid.b(2), Array Palette.l(1))
  Protected Row, Col, X, Y, Edge = GridSize * CellSize
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf

  Box(0, 0, #SpriteEd_CanvasSize, #SpriteEd_CanvasSize, RGB(255, 255, 255))

  For Row = 0 To GridSize - 1
    For Col = 0 To GridSize - 1
      If Grid(Row, Col) > 0
        X = Col * CellSize
        Y = Row * CellSize
        Box(X + 1, Y + 1, CellSize - 1, CellSize - 1, Palette(Grid(Row, Col)))
      EndIf
    Next
  Next

  Protected i
  For i = 0 To GridSize
    Line(i * CellSize, 0, 0, Edge, RGB(180, 180, 180))
    Line(0, i * CellSize, Edge, 0, RGB(180, 180, 180))
  Next

  StopDrawing()
EndProcedure

; Previa em escala reduzida (mais perto da proporcao real do sprite no MSX),
; sem linhas de grade, so os blocos coloridos lado a lado.
Procedure SpriteEd_RedrawPreview(Canvas, GridSize.i, Array Grid.b(2), Array Palette.l(1))
  Protected Row, Col, X, Y, CellSize.i = #SpriteEd_PreviewSize / GridSize
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf

  Box(0, 0, #SpriteEd_PreviewSize, #SpriteEd_PreviewSize, RGB(255, 255, 255))

  For Row = 0 To GridSize - 1
    For Col = 0 To GridSize - 1
      If Grid(Row, Col) > 0
        X = Col * CellSize
        Y = Row * CellSize
        Box(X, Y, CellSize, CellSize, Palette(Grid(Row, Col)))
      EndIf
    Next
  Next

  DrawingMode(#PB_2DDrawing_Outlined)
  Box(0, 0, #SpriteEd_PreviewSize, #SpriteEd_PreviewSize, RGB(150, 150, 150))

  StopDrawing()
EndProcedure

; Seletor de cores: 16 blocos (4x4) com as cores da palheta MSX1; o indice 0
; (transparente) e desenhado com um "X" ao inves de preenchimento; a cor
; selecionada ganha uma borda mais grossa.
Procedure SpriteEd_RedrawPalette(Canvas, Selected.i, Array Palette.l(1))
  Protected SwatchSize.i = #SpriteEd_PaletteSize / #SpriteEd_PaletteCols
  Protected Row, Col, Idx, X, Y
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf

  Box(0, 0, #SpriteEd_PaletteSize, #SpriteEd_PaletteSize, RGB(255, 255, 255))

  For Row = 0 To #SpriteEd_PaletteRows - 1
    For Col = 0 To #SpriteEd_PaletteCols - 1
      Idx = Row * #SpriteEd_PaletteCols + Col
      X = Col * SwatchSize
      Y = Row * SwatchSize

      DrawingMode(#PB_2DDrawing_Default)
      If Idx = 0
        Box(X + 2, Y + 2, SwatchSize - 4, SwatchSize - 4, RGB(255, 255, 255))
        Line(X + 4, Y + 4, SwatchSize - 8, SwatchSize - 8, RGB(150, 150, 150))
        Line(X + SwatchSize - 4, Y + 4, -(SwatchSize - 8), SwatchSize - 8, RGB(150, 150, 150))
      Else
        Box(X + 2, Y + 2, SwatchSize - 4, SwatchSize - 4, Palette(Idx))
      EndIf

      DrawingMode(#PB_2DDrawing_Outlined)
      If Idx = Selected
        Box(X + 1, Y + 1, SwatchSize - 2, SwatchSize - 2, RGB(0, 0, 0))
        Box(X + 2, Y + 2, SwatchSize - 4, SwatchSize - 4, RGB(0, 0, 0))
      Else
        Box(X + 1, Y + 1, SwatchSize - 2, SwatchSize - 2, RGB(180, 180, 180))
      EndIf
    Next
  Next

  StopDrawing()
EndProcedure

; Desmarca (SetGadgetState False) todos os botoes de ferramenta exceto
; KeepGadget - usado para manter so uma ferramenta ativa por vez.
Procedure SpriteEd_UnpressOtherTools(Array AllToolGadgets.i(1), KeepGadget.i)
  Protected i
  For i = 0 To ArraySize(AllToolGadgets())
    If AllToolGadgets(i) <> KeepGadget
      SetGadgetState(AllToolGadgets(i), #False)
    EndIf
  Next
EndProcedure

Procedure.b SpriteEd_ConfirmDiscardSprite()
  ProcedureReturn Bool(MessageRequester("Sprite nao registrado",
                        "As alteracoes deste sprite ainda nao foram registradas no projeto." + Chr(10) +
                        "Descartar mesmo assim?",
                        #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
EndProcedure

; Acha o numero de sprite alvo dentro de Nav() (lista ordenada crescente de
; ProjectDB::ListSpriteNumbers) pra cada botao de navegacao; -1 se nao ha
; alvo (ex.: Proximo ja no ultimo). Direction: 0=Primeiro, 1=Anterior,
; 2=Proximo, 3=Ultimo.
Procedure.i SpriteEd_FindNavTarget(List Nav.i(), Direction.i, CurrentNumber.i)
  Protected Target.i = -1
  Select Direction
    Case 0
      If ListSize(Nav()) > 0
        FirstElement(Nav())
        Target = Nav()
      EndIf
    Case 3
      If ListSize(Nav()) > 0
        LastElement(Nav())
        Target = Nav()
      EndIf
    Case 1
      ForEach Nav()
        If Nav() < CurrentNumber And Nav() > Target
          Target = Nav()
        EndIf
      Next
    Case 2
      ForEach Nav()
        If Nav() > CurrentNumber And (Target = -1 Or Nav() < Target)
          Target = Nav()
        EndIf
      Next
  EndSelect
  ProcedureReturn Target
EndProcedure

; Busca o sprite TargetNumber no banco do projeto e atualiza a UI inteira
; (radios de tamanho/modo, campo de tag, numero exibido, grade e previa) -
; nao mexe em SpriteNumber/GridSize/SpriteMode/SpriteTag do chamador; quem
; chama deve ler ProjectDB::LastGridSize()/LastSpriteMode()/LastTag() logo
; em seguida pra manter as proprias variaveis em dia (mesmos valores que
; acabaram de ser lidos do banco, sem precisar de parametro de saida por
; ponteiro pra string).
Procedure.b SpriteEd_LoadSprite(TargetNumber.i, G_Canvas, G_Preview, G_Size8, G_Size16, G_ModeMSX1, G_ModeMSX2, G_Tag, G_SpriteNumberText, G_Status, Array Grid.b(2), Array Palette.l(1))
  If Not ProjectDB::FetchSprite(TargetNumber, Grid())
    ProcedureReturn #False
  EndIf

  Protected GridSize.i = ProjectDB::LastGridSize()
  Protected SpriteMode.i = ProjectDB::LastSpriteMode()

  SetGadgetState(G_Size8, Bool(GridSize = 8))
  SetGadgetState(G_Size16, Bool(GridSize = 16))
  SetGadgetState(G_ModeMSX1, Bool(SpriteMode = 1))
  SetGadgetState(G_ModeMSX2, Bool(SpriteMode = 2))
  SetGadgetText(G_Tag, ProjectDB::LastTag())
  SetGadgetText(G_SpriteNumberText, "#" + Str(TargetNumber))
  SetGadgetText(G_Status, SpriteEd_StatusText(GridSize))
  SpriteEd_Redraw(G_Canvas, GridSize, #SpriteEd_CanvasSize / GridSize, Grid(), Palette())
  SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette())
  ProcedureReturn #True
EndProcedure

Procedure SpriteEditor_OpenWindow(ParentWindow)
  Protected RightW = 170
  Protected WinW = 15 + #SpriteEd_CanvasSize + 20 + RightW + 15 + 45 + 90
  Protected TopOffset = 38   ; altura reservada pra barra de projeto (numero/navegacao/tag/novo/registrar/copiar/colar)
  Protected ToolY = (78 + TopOffset) + #SpriteEd_CanvasSize + 10, ToolH = 28
  Protected ToolY2 = ToolY + ToolH + 8
  Protected CloseY = ToolY2 + ToolH + 14
  Protected WinH = CloseY + 30 + 15
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Criar sprite MSX",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf
  AddKeyboardShortcut(Win, #PB_Shortcut_Escape, #SpriteEd_CancelShortcut)

  ; Barra de projeto: numero do sprite atual, navegacao entre os sprites ja
  ; registrados no projeto, tag (nome curto) e os botoes Novo/Registrar/
  ; Copiar/Colar.
  Protected Cx = 15

  TextGadget(#PB_Any, Cx, 16, 50, 20, "Sprite:")
  Cx + 50 + 4
  Protected G_SpriteNumberText = TextGadget(#PB_Any, Cx, 16, 40, 20, "#1")
  Cx + 40 + 10

  Protected G_First = ThemedButton(Cx, 12, 28, 26, Chr(9198), "")
  GadgetToolTip(G_First, "Primeiro sprite")
  Cx + 28 + 2
  Protected G_Prev = ThemedButton(Cx, 12, 28, 26, Chr(9664), "")
  GadgetToolTip(G_Prev, "Sprite anterior")
  Cx + 28 + 2
  Protected G_Next = ThemedButton(Cx, 12, 28, 26, Chr(9654), "")
  GadgetToolTip(G_Next, "Proximo sprite")
  Cx + 28 + 2
  Protected G_Last = ThemedButton(Cx, 12, 28, 26, Chr(9197), "")
  GadgetToolTip(G_Last, "Ultimo sprite")
  Cx + 28 + 16

  TextGadget(#PB_Any, Cx, 16, 32, 20, "Tag:")
  Cx + 32 + 4
  Protected G_Tag = StringGadget(#PB_Any, Cx, 14, 120, 22, "")
  GadgetToolTip(G_Tag, "Nome curto pra identificar o sprite (ate 16 caracteres)")
  Cx + 120 + 16

  Protected NewSpriteIcon = SpriteEd_CreateNewSpriteIcon(22)
  Protected G_SpriteNew = ButtonImageGadget(#PB_Any, Cx, 12, 34, 26, ImageID(NewSpriteIcon))
  GadgetToolTip(G_SpriteNew, "Novo sprite (numera automaticamente)")
  Cx + 34 + 6

  Protected RegisterIcon = SpriteEd_CreateRegisterIcon(22)
  Protected G_Register = ButtonImageGadget(#PB_Any, Cx, 12, 34, 26, ImageID(RegisterIcon))
  GadgetToolTip(G_Register, "Registrar: grava este sprite no banco do projeto")
  Cx + 34 + 16

  Protected CopyIcon = SpriteEd_CreateCopyIcon(22)
  Protected G_SpriteCopy = ButtonImageGadget(#PB_Any, Cx, 12, 34, 26, ImageID(CopyIcon))
  GadgetToolTip(G_SpriteCopy, "Copiar este sprite")
  Cx + 34 + 6

  Protected PasteIcon = SpriteEd_CreatePasteIcon(22)
  Protected G_SpritePaste = ButtonImageGadget(#PB_Any, Cx, 12, 34, 26, ImageID(PasteIcon))
  GadgetToolTip(G_SpritePaste, "Colar o sprite copiado aqui")
  Cx + 34 + 16

  Protected InjectIcon = SpriteEd_CreateInjectIcon(22)
  Protected G_Inject = ButtonImageGadget(#PB_Any, Cx, 12, 34, 26, ImageID(InjectIcon))
  GadgetToolTip(G_Inject, "Injetar: insere o codigo DATA deste sprite no cursor da aba de texto ativa")
  Cx + 34 + 16

  Protected InsertLoopIcon = SpriteEd_CreateInsertLoopIcon(22)
  Protected G_InsertLoop = ButtonImageGadget(#PB_Any, Cx, 12, 34, 26, ImageID(InsertLoopIcon))
  GadgetToolTip(G_InsertLoop, "Inserir sprite corrente: DATA + loop de leitura deste sprite no cursor da aba de texto ativa, pronto pra atribuir a um sprite numerado")
  Cx + 34 + 6

  Protected InsertAllIcon = SpriteEd_CreateInsertAllIcon(22)
  Protected G_InsertAll = ButtonImageGadget(#PB_Any, Cx, 12, 34, 26, ImageID(InsertAllIcon))
  GadgetToolTip(G_InsertAll, "Gerar DATA do banco: insere o DATA de todos os sprites registrados no projeto no cursor da aba de texto ativa")

  TextGadget(#PB_Any, 15, 18 + TopOffset, 90, 20, "Tipo de sprite:")
  Protected G_Size8  = OptionGadget(#PB_Any, 110, 16 + TopOffset, 70, 22, "8 x 8")
  Protected G_Size16 = OptionGadget(#PB_Any, 185, 16 + TopOffset, 80, 22, "16 x 16")
  SetGadgetState(G_Size16, #True)   ; 16x16 e o tamanho de sprite mais comum no MSX

  ; O TextGadget "Modo:" entre os dois pares de OptionGadget quebra o
  ; agrupamento automatico do PureBasic (senao os 4 radios virariam um unico
  ; grupo mutuamente exclusivo).
  TextGadget(#PB_Any, 280, 18 + TopOffset, 42, 20, "Modo:")
  Protected G_ModeMSX1 = OptionGadget(#PB_Any, 325, 16 + TopOffset, 58, 22, "MSX1")
  Protected G_ModeMSX2 = OptionGadget(#PB_Any, 385, 16 + TopOffset, 58, 22, "MSX2")
  SetGadgetState(G_ModeMSX1, #True)   ; MSX1: o sprite inteiro usa uma unica cor
  GadgetToolTip(G_ModeMSX1, "MSX1: o sprite inteiro usa uma unica cor")
  GadgetToolTip(G_ModeMSX2, "MSX2: cada linha do sprite pode ter sua propria cor")

  Protected ClearIcon = SpriteEd_CreateClearIcon(22)
  Protected G_Clear = ButtonImageGadget(#PB_Any, 455, 12 + TopOffset, 34, 26, ImageID(ClearIcon))
  GadgetToolTip(G_Clear, "Limpar tudo")

  Protected InvertIcon = SpriteEd_CreateInvertIcon(22)
  Protected G_Invert = ButtonImageGadget(#PB_Any, 495, 12 + TopOffset, 34, 26, ImageID(InvertIcon))
  GadgetToolTip(G_Invert, "Inverter todos os pixels")

  Protected G_Status = TextGadget(#PB_Any, 15, 50 + TopOffset, #SpriteEd_CanvasSize, 20, "")

  Protected GridX = 15, GridY = 78 + TopOffset
  Protected G_Canvas = CanvasGadget(#PB_Any, GridX, GridY, #SpriteEd_CanvasSize, #SpriteEd_CanvasSize)

  ; Primeira barra: ferramentas de desenho (todas mutuamente exclusivas -
  ; ver ToolGadgets()/SpriteEd_UnpressOtherTools abaixo).
  Cx = GridX

  Protected PencilIcon = SpriteEd_CreatePencilIcon(22)
  Protected G_Pencil = ButtonImageGadget(#PB_Any, Cx, ToolY, 34, ToolH, ImageID(PencilIcon), #PB_Button_Toggle)
  GadgetToolTip(G_Pencil, "Lapis: enquanto pressionado, o botao esquerdo do mouse sempre pinta")
  Cx + 34 + 6

  Protected EraserIcon = SpriteEd_CreateEraserIcon(22)
  Protected G_Eraser = ButtonImageGadget(#PB_Any, Cx, ToolY, 34, ToolH, ImageID(EraserIcon), #PB_Button_Toggle)
  GadgetToolTip(G_Eraser, "Borracha: enquanto pressionada, o botao esquerdo do mouse sempre apaga")
  Cx + 34 + 6

  Protected BrushIcon = SpriteEd_CreateBrushIcon(22)
  Protected G_Brush = ButtonImageGadget(#PB_Any, Cx, ToolY, 34, ToolH, ImageID(BrushIcon), #PB_Button_Toggle)
  GadgetToolTip(G_Brush, "Pincel: pinta um bloco 2x2 por vez (arrastar risca continuamente)")
  Cx + 34 + 16

  Protected LineToolIcon = SpriteEd_CreateLineToolIcon(22)
  Protected G_LineTool = ButtonImageGadget(#PB_Any, Cx, ToolY, 34, ToolH, ImageID(LineToolIcon), #PB_Button_Toggle)
  GadgetToolTip(G_LineTool, "Reta: marque dois pontos da grade para tracar uma linha")
  Cx + 34 + 6

  Protected RectOutlineIcon = SpriteEd_CreateRectOutlineIcon(22)
  Protected G_RectOutline = ButtonImageGadget(#PB_Any, Cx, ToolY, 34, ToolH, ImageID(RectOutlineIcon), #PB_Button_Toggle)
  GadgetToolTip(G_RectOutline, "Retangulo vazio: marque dois cantos opostos")
  Cx + 34 + 6

  Protected RectFillIcon = SpriteEd_CreateRectFillIcon(22)
  Protected G_RectFill = ButtonImageGadget(#PB_Any, Cx, ToolY, 34, ToolH, ImageID(RectFillIcon), #PB_Button_Toggle)
  GadgetToolTip(G_RectFill, "Retangulo cheio: marque dois cantos opostos")
  Cx + 34 + 6

  Protected EllipseOutlineIcon = SpriteEd_CreateEllipseOutlineIcon(22)
  Protected G_EllipseOutline = ButtonImageGadget(#PB_Any, Cx, ToolY, 34, ToolH, ImageID(EllipseOutlineIcon), #PB_Button_Toggle)
  GadgetToolTip(G_EllipseOutline, "Elipse/circulo vazio: marque dois cantos da caixa delimitadora")
  Cx + 34 + 6

  Protected EllipseFillIcon = SpriteEd_CreateEllipseFillIcon(22)
  Protected G_EllipseFill = ButtonImageGadget(#PB_Any, Cx, ToolY, 34, ToolH, ImageID(EllipseFillIcon), #PB_Button_Toggle)
  GadgetToolTip(G_EllipseFill, "Elipse/circulo cheio: marque dois cantos da caixa delimitadora")
  Cx + 34 + 6

  Protected FillIcon = SpriteEd_CreateFillIcon(22)
  Protected G_Fill = ButtonImageGadget(#PB_Any, Cx, ToolY, 34, ToolH, ImageID(FillIcon), #PB_Button_Toggle)
  GadgetToolTip(G_Fill, "Preencher area: clique dentro de uma area delimitada para pintar tudo com a cor atual")

  Dim ToolGadgets.i(8)
  ToolGadgets(0) = G_Pencil
  ToolGadgets(1) = G_Eraser
  ToolGadgets(2) = G_Brush
  ToolGadgets(3) = G_LineTool
  ToolGadgets(4) = G_RectOutline
  ToolGadgets(5) = G_RectFill
  ToolGadgets(6) = G_EllipseOutline
  ToolGadgets(7) = G_EllipseFill
  ToolGadgets(8) = G_Fill

  ; Segunda barra: rotacionar (com "quebra" nas bordas) e deslocar (sem
  ; quebra - o que sai perde-se e entra transparente do lado oposto) nas
  ; quatro direcoes.
  Cx = GridX

  TextGadget(#PB_Any, Cx, ToolY2 + 6, 14, ToolH, "R")
  Cx + 14

  Protected G_RotUp = ThemedButton(Cx, ToolY2, 30, ToolH, Chr(9650), "")
  GadgetToolTip(G_RotUp, "Rotacionar linhas para cima")
  Cx + 30 + 2

  Protected G_RotDown = ThemedButton(Cx, ToolY2, 30, ToolH, Chr(9660), "")
  GadgetToolTip(G_RotDown, "Rotacionar linhas para baixo")
  Cx + 30 + 2

  Protected G_RotLeft = ThemedButton(Cx, ToolY2, 30, ToolH, Chr(9668), "")
  GadgetToolTip(G_RotLeft, "Rotacionar colunas para a esquerda")
  Cx + 30 + 2

  Protected G_RotRight = ThemedButton(Cx, ToolY2, 30, ToolH, Chr(9658), "")
  GadgetToolTip(G_RotRight, "Rotacionar colunas para a direita")
  Cx + 30 + 16

  TextGadget(#PB_Any, Cx, ToolY2 + 6, 14, ToolH, "D")
  Cx + 14

  Protected G_ShiftUp = ThemedButton(Cx, ToolY2, 30, ToolH, Chr(9650), "")
  GadgetToolTip(G_ShiftUp, "Deslocar para cima (sem rotacionar)")
  Cx + 30 + 2

  Protected G_ShiftDown = ThemedButton(Cx, ToolY2, 30, ToolH, Chr(9660), "")
  GadgetToolTip(G_ShiftDown, "Deslocar para baixo (sem rotacionar)")
  Cx + 30 + 2

  Protected G_ShiftLeft = ThemedButton(Cx, ToolY2, 30, ToolH, Chr(9668), "")
  GadgetToolTip(G_ShiftLeft, "Deslocar para a esquerda (sem rotacionar)")
  Cx + 30 + 2

  Protected G_ShiftRight = ThemedButton(Cx, ToolY2, 30, ToolH, Chr(9658), "")
  GadgetToolTip(G_ShiftRight, "Deslocar para a direita (sem rotacionar)")

  Protected G_Close = ThemedButton(GridX + (#SpriteEd_CanvasSize - 100) / 2, CloseY, 100, 30, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  ; Coluna direita: seletor de cores em cima, previa embaixo.
  Protected RightX = GridX + #SpriteEd_CanvasSize + 20

  TextGadget(#PB_Any, RightX, GridY, RightW, 20, "Cor atual:")
  Protected PaletteX = RightX + (RightW - #SpriteEd_PaletteSize) / 2
  Protected PaletteY = GridY + 24
  Protected G_Palette = CanvasGadget(#PB_Any, PaletteX, PaletteY, #SpriteEd_PaletteSize, #SpriteEd_PaletteSize)

  Protected G_ColorName = TextGadget(#PB_Any, RightX, PaletteY + #SpriteEd_PaletteSize + 8, RightW, 20, "")

  Protected PreviewLabelY = PaletteY + #SpriteEd_PaletteSize + 34
  TextGadget(#PB_Any, RightX, PreviewLabelY, RightW, 20, "Previa:")
  Protected PreviewX = RightX + (RightW - #SpriteEd_PreviewSize) / 2
  Protected PreviewY = PreviewLabelY + 24
  Protected G_Preview = CanvasGadget(#PB_Any, PreviewX, PreviewY, #SpriteEd_PreviewSize, #SpriteEd_PreviewSize)

  Dim Palette.l(15)
  Dim PaletteNames.s(15)
  SpriteEd_FillPalette(Palette(), PaletteNames())

  Dim Grid.b(15, 15)
  Protected GridSize.i = 16
  Protected CellSize.i = #SpriteEd_CanvasSize / GridSize
  Protected SelectedColor.i = 1   ; preto - visivel de cara sobre o fundo branco
  Protected ToolMode.i = #SpriteTool_Default
  Protected SpriteMode.i = 1      ; 1 = MSX1 (sprite inteiro com uma cor), 2 = MSX2 (uma cor por linha)
  Protected LineStartRow.i = -1, LineStartCol.i = -1
  Dim PreviewMask.b(15, 15)
  Protected PreviewRow.i = -1, PreviewCol.i = -1
  Protected BlinkOn.b = #True

  Protected SpriteNumber.i = 1
  Protected SpriteTag.s = ""
  Protected SpriteDirty.b = #False
  Dim ClipboardGrid.b(15, 15)
  Protected ClipboardGridSize.i = 16
  Protected ClipboardSpriteMode.i = 1
  Protected ClipboardValid.b = #False

  ; Abre (ou cria) o projeto implicito e carrega o primeiro sprite ja
  ; registrado, se houver; senao comeca com um sprite novo em branco (#1,
  ; ainda nao registrado).
  ProjectDB::EnsureOpen()
  NewList ExistingSprites.i()
  ProjectDB::ListSpriteNumbers(ExistingSprites())
  If ListSize(ExistingSprites()) > 0
    FirstElement(ExistingSprites())
    SpriteNumber = ExistingSprites()
    SpriteEd_LoadSprite(SpriteNumber, G_Canvas, G_Preview, G_Size8, G_Size16, G_ModeMSX1, G_ModeMSX2, G_Tag, G_SpriteNumberText, G_Status, Grid(), Palette())
    GridSize = ProjectDB::LastGridSize()
    SpriteMode = ProjectDB::LastSpriteMode()
    SpriteTag = ProjectDB::LastTag()
    CellSize = #SpriteEd_CanvasSize / GridSize
  Else
    SetGadgetText(G_SpriteNumberText, "#1")
    SetGadgetText(G_Status, SpriteEd_StatusText(GridSize))
    SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
    SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette())
  EndIf

  SetGadgetText(G_ColorName, SpriteEd_ColorText(SelectedColor, PaletteNames()))
  SpriteEd_RedrawPalette(G_Palette, SelectedColor, Palette())

  Protected Event, Quit = #False, MouseX, MouseY, Row, Col, Idx
  Protected LastPaintRow.i = -1, LastPaintCol.i = -1
  Protected NavTarget.i, NextNumber.i
  NewList Nav.i()

  Repeat
    Event = WaitWindowEvent()
    Select Event

      Case #PB_Event_Gadget
        Select EventGadget()

          Case G_Size8
            If GetGadgetState(G_Size8) And GridSize <> 8
              GridSize = 8
              CellSize = #SpriteEd_CanvasSize / GridSize
              SpriteEd_ClearGrid(Grid())
              RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
            LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
              SetGadgetText(G_Status, SpriteEd_StatusText(GridSize))
              SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
              SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette()) : SpriteDirty = #True
            EndIf

          Case G_Size16
            If GetGadgetState(G_Size16) And GridSize <> 16
              GridSize = 16
              CellSize = #SpriteEd_CanvasSize / GridSize
              SpriteEd_ClearGrid(Grid())
              RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
            LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
              SetGadgetText(G_Status, SpriteEd_StatusText(GridSize))
              SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
              SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette()) : SpriteDirty = #True
            EndIf

          Case G_ModeMSX1
            If GetGadgetState(G_ModeMSX1) And SpriteMode <> 1
              SpriteMode = 1
              SpriteEd_RecolorAll(Grid(), GridSize, SelectedColor)
              SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
              SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette()) : SpriteDirty = #True
            EndIf

          Case G_ModeMSX2
            If GetGadgetState(G_ModeMSX2)
              SpriteMode = 2
            EndIf

          Case G_Clear
            SpriteEd_ClearGrid(Grid())
            RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
            LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
            SetGadgetText(G_Status, SpriteEd_StatusText(GridSize))
            SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
            SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette()) : SpriteDirty = #True

          Case G_Invert
            SpriteEd_InvertGrid(Grid(), GridSize, SelectedColor)
            SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
            SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette()) : SpriteDirty = #True

          Case G_Pencil
            If GetGadgetState(G_Pencil)
              SpriteEd_UnpressOtherTools(ToolGadgets(), G_Pencil)
              ToolMode = #SpriteTool_Pencil
            Else
              ToolMode = #SpriteTool_Default
            EndIf
            RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
            LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
            SetGadgetText(G_Status, SpriteEd_StatusText(GridSize))

          Case G_Eraser
            If GetGadgetState(G_Eraser)
              SpriteEd_UnpressOtherTools(ToolGadgets(), G_Eraser)
              ToolMode = #SpriteTool_Eraser
            Else
              ToolMode = #SpriteTool_Default
            EndIf
            RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
            LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
            SetGadgetText(G_Status, SpriteEd_StatusText(GridSize))

          Case G_Brush
            If GetGadgetState(G_Brush)
              SpriteEd_UnpressOtherTools(ToolGadgets(), G_Brush)
              ToolMode = #SpriteTool_Brush
            Else
              ToolMode = #SpriteTool_Default
            EndIf
            RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
            LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
            SetGadgetText(G_Status, SpriteEd_StatusText(GridSize))

          Case G_LineTool
            If GetGadgetState(G_LineTool)
              SpriteEd_UnpressOtherTools(ToolGadgets(), G_LineTool)
              ToolMode = #SpriteTool_Line
            Else
              ToolMode = #SpriteTool_Default
            EndIf
            RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
            LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
            SetGadgetText(G_Status, SpriteEd_StatusText(GridSize))

          Case G_RectOutline
            If GetGadgetState(G_RectOutline)
              SpriteEd_UnpressOtherTools(ToolGadgets(), G_RectOutline)
              ToolMode = #SpriteTool_RectOutline
            Else
              ToolMode = #SpriteTool_Default
            EndIf
            RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
            LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
            SetGadgetText(G_Status, SpriteEd_StatusText(GridSize))

          Case G_RectFill
            If GetGadgetState(G_RectFill)
              SpriteEd_UnpressOtherTools(ToolGadgets(), G_RectFill)
              ToolMode = #SpriteTool_RectFill
            Else
              ToolMode = #SpriteTool_Default
            EndIf
            RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
            LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
            SetGadgetText(G_Status, SpriteEd_StatusText(GridSize))

          Case G_EllipseOutline
            If GetGadgetState(G_EllipseOutline)
              SpriteEd_UnpressOtherTools(ToolGadgets(), G_EllipseOutline)
              ToolMode = #SpriteTool_EllipseOutline
            Else
              ToolMode = #SpriteTool_Default
            EndIf
            RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
            LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
            SetGadgetText(G_Status, SpriteEd_StatusText(GridSize))

          Case G_EllipseFill
            If GetGadgetState(G_EllipseFill)
              SpriteEd_UnpressOtherTools(ToolGadgets(), G_EllipseFill)
              ToolMode = #SpriteTool_EllipseFill
            Else
              ToolMode = #SpriteTool_Default
            EndIf
            RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
            LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
            SetGadgetText(G_Status, SpriteEd_StatusText(GridSize))

          Case G_Fill
            If GetGadgetState(G_Fill)
              SpriteEd_UnpressOtherTools(ToolGadgets(), G_Fill)
              ToolMode = #SpriteTool_Fill
            Else
              ToolMode = #SpriteTool_Default
            EndIf
            RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
            LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
            SetGadgetText(G_Status, SpriteEd_StatusText(GridSize))

          Case G_RotUp
            SpriteEd_TranslateGrid(Grid(), GridSize, 0, -1, #True)
            SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
            SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette()) : SpriteDirty = #True

          Case G_RotDown
            SpriteEd_TranslateGrid(Grid(), GridSize, 0, 1, #True)
            SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
            SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette()) : SpriteDirty = #True

          Case G_RotLeft
            SpriteEd_TranslateGrid(Grid(), GridSize, -1, 0, #True)
            SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
            SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette()) : SpriteDirty = #True

          Case G_RotRight
            SpriteEd_TranslateGrid(Grid(), GridSize, 1, 0, #True)
            SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
            SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette()) : SpriteDirty = #True

          Case G_ShiftUp
            SpriteEd_TranslateGrid(Grid(), GridSize, 0, -1, #False)
            SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
            SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette()) : SpriteDirty = #True

          Case G_ShiftDown
            SpriteEd_TranslateGrid(Grid(), GridSize, 0, 1, #False)
            SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
            SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette()) : SpriteDirty = #True

          Case G_ShiftLeft
            SpriteEd_TranslateGrid(Grid(), GridSize, -1, 0, #False)
            SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
            SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette()) : SpriteDirty = #True

          Case G_ShiftRight
            SpriteEd_TranslateGrid(Grid(), GridSize, 1, 0, #False)
            SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
            SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette()) : SpriteDirty = #True

          Case G_Canvas
            Select EventType()

              Case #PB_EventType_LeftButtonDown
                MouseX = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseX)
                MouseY = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseY)
                Col = MouseX / CellSize
                Row = MouseY / CellSize
                If Row >= 0 And Row < GridSize And Col >= 0 And Col < GridSize
                  Select ToolMode

                    ; Reta/retangulo/elipse: primeiro clique marca o canto
                    ; inicial (com marcador piscando e previa ao vivo da
                    ; forma), o segundo traca/preenche a forma ate ele e
                    ; volta a aguardar um novo ponto.
                    Case #SpriteTool_Line, #SpriteTool_RectOutline, #SpriteTool_RectFill,
                         #SpriteTool_EllipseOutline, #SpriteTool_EllipseFill
                      If LineStartRow = -1
                        LineStartRow = Row
                        LineStartCol = Col
                        PreviewRow = Row
                        PreviewCol = Col
                        BlinkOn = #True
                        AddWindowTimer(Win, #SpriteEd_BlinkTimer, 500)
                        SetGadgetText(G_Status, "Clique no segundo ponto (botao direito ou ESC cancela)")
                        SpriteEd_ComputePreviewMask(PreviewMask(), GridSize, ToolMode, LineStartRow, LineStartCol, PreviewRow, PreviewCol)
                        SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
                        SpriteEd_DrawPreviewOverlay(G_Canvas, GridSize, CellSize, PreviewMask(), Palette(SelectedColor), BlinkOn, LineStartRow, LineStartCol)
                      Else
                        Select ToolMode
                          Case #SpriteTool_Line
                            SpriteEd_DrawLine(Grid(), LineStartRow, LineStartCol, Row, Col, SelectedColor, GridSize)
                          Case #SpriteTool_RectOutline
                            SpriteEd_DrawRect(Grid(), LineStartRow, LineStartCol, Row, Col, SelectedColor, #False)
                          Case #SpriteTool_RectFill
                            SpriteEd_DrawRect(Grid(), LineStartRow, LineStartCol, Row, Col, SelectedColor, #True)
                          Case #SpriteTool_EllipseOutline
                            SpriteEd_DrawEllipse(Grid(), LineStartRow, LineStartCol, Row, Col, SelectedColor, #False)
                          Case #SpriteTool_EllipseFill
                            SpriteEd_DrawEllipse(Grid(), LineStartRow, LineStartCol, Row, Col, SelectedColor, #True)
                        EndSelect
                        SpriteEd_EnforceColorMode(Grid(), GridSize, SpriteMode, SelectedColor)
                        RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
                        LineStartRow = -1
                        LineStartCol = -1
                        PreviewRow = -1
                        PreviewCol = -1
                        SetGadgetText(G_Status, SpriteEd_StatusText(GridSize))
                        SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
                        SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette()) : SpriteDirty = #True
                      EndIf

                    ; Balde: um clique so, preenche a area conectada.
                    Case #SpriteTool_Fill
                      SpriteEd_FloodFill(Grid(), GridSize, Row, Col, SelectedColor)
                      SpriteEd_EnforceColorMode(Grid(), GridSize, SpriteMode, SelectedColor)
                      SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
                      SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette()) : SpriteDirty = #True

                    ; Padrao/lapis/borracha/pincel: pinta/apaga o(s) bloco(s)
                    ; sob o clique.
                    Default
                      SpriteEd_ApplyTool(Grid(), Row, Col, ToolMode, SelectedColor, GridSize)
                      If Grid(Row, Col) > 0
                        SpriteEd_EnforceColorMode(Grid(), GridSize, SpriteMode, SelectedColor)
                      EndIf
                      SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
                      SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette()) : SpriteDirty = #True
                      LastPaintRow = Row
                      LastPaintCol = Col

                  EndSelect
                EndIf

              ; Botao direito cancela uma marcacao de dois pontos em
              ; andamento (reta/retangulo/elipse) sem tracar nada.
              Case #PB_EventType_RightButtonDown
                If LineStartRow <> -1
                  RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
                  LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
                  SetGadgetText(G_Status, SpriteEd_StatusText(GridSize))
                  SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
                EndIf

              ; Enquanto uma ferramenta de dois pontos aguarda o segundo
              ; clique, o mouse vai tracando a forma ao vivo (previa) sobre
              ; o ponto inicial marcado. Com o lapis, a borracha ou o pincel
              ; ativos, manter o botao esquerdo pressionado enquanto arrasta
              ; risca/apaga/pinta continuamente. As demais ferramentas ficam
              ; so no clique.
              Case #PB_EventType_MouseMove
                If LineStartRow <> -1
                  MouseX = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseX)
                  MouseY = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseY)
                  Col = MouseX / CellSize
                  Row = MouseY / CellSize
                  If Col < 0 : Col = 0 : ElseIf Col >= GridSize : Col = GridSize - 1 : EndIf
                  If Row < 0 : Row = 0 : ElseIf Row >= GridSize : Row = GridSize - 1 : EndIf
                  If Row <> PreviewRow Or Col <> PreviewCol
                    PreviewRow = Row
                    PreviewCol = Col
                    SpriteEd_ComputePreviewMask(PreviewMask(), GridSize, ToolMode, LineStartRow, LineStartCol, PreviewRow, PreviewCol)
                    SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
                    SpriteEd_DrawPreviewOverlay(G_Canvas, GridSize, CellSize, PreviewMask(), Palette(SelectedColor), BlinkOn, LineStartRow, LineStartCol)
                  EndIf
                ElseIf (ToolMode = #SpriteTool_Pencil Or ToolMode = #SpriteTool_Eraser Or ToolMode = #SpriteTool_Brush) And
                       (GetGadgetAttribute(G_Canvas, #PB_Canvas_Buttons) & #PB_Canvas_LeftButton)
                  MouseX = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseX)
                  MouseY = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseY)
                  Col = MouseX / CellSize
                  Row = MouseY / CellSize
                  If Row >= 0 And Row < GridSize And Col >= 0 And Col < GridSize And (Row <> LastPaintRow Or Col <> LastPaintCol)
                    SpriteEd_ApplyTool(Grid(), Row, Col, ToolMode, SelectedColor, GridSize)
                    If Grid(Row, Col) > 0
                      SpriteEd_EnforceColorMode(Grid(), GridSize, SpriteMode, SelectedColor)
                    EndIf
                    SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
                    SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette()) : SpriteDirty = #True
                    LastPaintRow = Row
                    LastPaintCol = Col
                  EndIf
                EndIf

            EndSelect

          Case G_Palette
            If EventType() = #PB_EventType_LeftButtonDown
              MouseX = GetGadgetAttribute(G_Palette, #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(G_Palette, #PB_Canvas_MouseY)
              Protected SwatchSize.i = #SpriteEd_PaletteSize / #SpriteEd_PaletteCols
              Col = MouseX / SwatchSize
              Row = MouseY / SwatchSize
              Idx = Row * #SpriteEd_PaletteCols + Col
              If Row >= 0 And Row < #SpriteEd_PaletteRows And Col >= 0 And Col < #SpriteEd_PaletteCols
                SelectedColor = Idx
                SetGadgetText(G_ColorName, SpriteEd_ColorText(SelectedColor, PaletteNames()))
                SpriteEd_RedrawPalette(G_Palette, SelectedColor, Palette())
                ; MSX1: o sprite inteiro so pode ter uma cor, entao trocar a
                ; cor atual recolore tudo que ja estava pintado na hora.
                If SpriteMode = 1
                  SpriteEd_RecolorAll(Grid(), GridSize, SelectedColor)
                  SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
                  SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette()) : SpriteDirty = #True
                EndIf
              EndIf
            EndIf

          Case G_First
            If Not SpriteDirty Or SpriteEd_ConfirmDiscardSprite()
              ProjectDB::ListSpriteNumbers(Nav())
              NavTarget = SpriteEd_FindNavTarget(Nav(), 0, SpriteNumber)
              If NavTarget >= 0
                SpriteEd_LoadSprite(NavTarget, G_Canvas, G_Preview, G_Size8, G_Size16, G_ModeMSX1, G_ModeMSX2, G_Tag, G_SpriteNumberText, G_Status, Grid(), Palette())
                SpriteNumber = NavTarget
                GridSize = ProjectDB::LastGridSize()
                SpriteMode = ProjectDB::LastSpriteMode()
                SpriteTag = ProjectDB::LastTag()
                CellSize = #SpriteEd_CanvasSize / GridSize
                SpriteDirty = #False
                RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
                LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
              EndIf
            EndIf

          Case G_Prev
            If Not SpriteDirty Or SpriteEd_ConfirmDiscardSprite()
              ProjectDB::ListSpriteNumbers(Nav())
              NavTarget = SpriteEd_FindNavTarget(Nav(), 1, SpriteNumber)
              If NavTarget >= 0
                SpriteEd_LoadSprite(NavTarget, G_Canvas, G_Preview, G_Size8, G_Size16, G_ModeMSX1, G_ModeMSX2, G_Tag, G_SpriteNumberText, G_Status, Grid(), Palette())
                SpriteNumber = NavTarget
                GridSize = ProjectDB::LastGridSize()
                SpriteMode = ProjectDB::LastSpriteMode()
                SpriteTag = ProjectDB::LastTag()
                CellSize = #SpriteEd_CanvasSize / GridSize
                SpriteDirty = #False
                RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
                LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
              EndIf
            EndIf

          Case G_Next
            If Not SpriteDirty Or SpriteEd_ConfirmDiscardSprite()
              ProjectDB::ListSpriteNumbers(Nav())
              NavTarget = SpriteEd_FindNavTarget(Nav(), 2, SpriteNumber)
              If NavTarget >= 0
                SpriteEd_LoadSprite(NavTarget, G_Canvas, G_Preview, G_Size8, G_Size16, G_ModeMSX1, G_ModeMSX2, G_Tag, G_SpriteNumberText, G_Status, Grid(), Palette())
                SpriteNumber = NavTarget
                GridSize = ProjectDB::LastGridSize()
                SpriteMode = ProjectDB::LastSpriteMode()
                SpriteTag = ProjectDB::LastTag()
                CellSize = #SpriteEd_CanvasSize / GridSize
                SpriteDirty = #False
                RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
                LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
              EndIf
            EndIf

          Case G_Last
            If Not SpriteDirty Or SpriteEd_ConfirmDiscardSprite()
              ProjectDB::ListSpriteNumbers(Nav())
              NavTarget = SpriteEd_FindNavTarget(Nav(), 3, SpriteNumber)
              If NavTarget >= 0
                SpriteEd_LoadSprite(NavTarget, G_Canvas, G_Preview, G_Size8, G_Size16, G_ModeMSX1, G_ModeMSX2, G_Tag, G_SpriteNumberText, G_Status, Grid(), Palette())
                SpriteNumber = NavTarget
                GridSize = ProjectDB::LastGridSize()
                SpriteMode = ProjectDB::LastSpriteMode()
                SpriteTag = ProjectDB::LastTag()
                CellSize = #SpriteEd_CanvasSize / GridSize
                SpriteDirty = #False
                RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
                LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
              EndIf
            EndIf

          Case G_SpriteNew
            If Not SpriteDirty Or SpriteEd_ConfirmDiscardSprite()
              ProjectDB::ListSpriteNumbers(Nav())
              NextNumber = 1
              If ListSize(Nav()) > 0
                LastElement(Nav())
                NextNumber = Nav() + 1
              EndIf
              SpriteNumber = NextNumber
              SpriteTag = ""
              GridSize = 16
              SpriteMode = 1
              CellSize = #SpriteEd_CanvasSize / GridSize
              SpriteEd_ClearGrid(Grid())
              SetGadgetState(G_Size8, #False)
              SetGadgetState(G_Size16, #True)
              SetGadgetState(G_ModeMSX1, #True)
              SetGadgetState(G_ModeMSX2, #False)
              SetGadgetText(G_Tag, "")
              SetGadgetText(G_SpriteNumberText, "#" + Str(SpriteNumber))
              SetGadgetText(G_Status, SpriteEd_StatusText(GridSize))
              SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
              SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette())
              SpriteDirty = #False
              RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
              LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
            EndIf

          Case G_Register
            SpriteTag = Left(GetGadgetText(G_Tag), 16)
            SetGadgetText(G_Tag, SpriteTag)
            If ProjectDB::StoreSprite(SpriteNumber, SpriteTag, GridSize, SpriteMode, Grid())
              SpriteDirty = #False
              SetGadgetText(G_Status, "Sprite #" + Str(SpriteNumber) + " registrado.")
            Else
              MessageRequester("Erro ao registrar",
                                "Nao foi possivel gravar o sprite:" + Chr(10) + ProjectDB::GetLastError(),
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
            EndIf

          Case G_Tag
            If EventType() = #PB_EventType_Change
              If Len(GetGadgetText(G_Tag)) > 16
                SetGadgetText(G_Tag, Left(GetGadgetText(G_Tag), 16))
              EndIf
            EndIf

          Case G_SpriteCopy
            CopyArray(Grid(), ClipboardGrid())
            ClipboardGridSize = GridSize
            ClipboardSpriteMode = SpriteMode
            ClipboardValid = #True
            SetGadgetText(G_Status, "Sprite #" + Str(SpriteNumber) + " copiado.")

          Case G_SpritePaste
            If ClipboardValid
              GridSize = ClipboardGridSize
              SpriteMode = ClipboardSpriteMode
              CellSize = #SpriteEd_CanvasSize / GridSize
              CopyArray(ClipboardGrid(), Grid())
              SetGadgetState(G_Size8, Bool(GridSize = 8))
              SetGadgetState(G_Size16, Bool(GridSize = 16))
              SetGadgetState(G_ModeMSX1, Bool(SpriteMode = 1))
              SetGadgetState(G_ModeMSX2, Bool(SpriteMode = 2))
              SetGadgetText(G_Status, SpriteEd_StatusText(GridSize))
              SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
              SpriteEd_RedrawPreview(G_Preview, GridSize, Grid(), Palette())
              SpriteDirty = #True
              RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
              LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
            Else
              MessageRequester("Nada copiado", "Copie um sprite primeiro (botao Copiar).", #PB_MessageRequester_Ok)
            EndIf

          Case G_Inject
            Protected InjectText.s = SpriteEd_BuildInjectText(Grid(), GridSize, SpriteMode, SelectedColor, SpriteNumber, SpriteTag)
            If InjectTextAtCursor(InjectText)
              SetGadgetText(G_Status, "Codigo do sprite #" + Str(SpriteNumber) + " injetado no cursor.")
            Else
              MessageRequester("Nao foi possivel injetar",
                                "Nenhuma aba de texto ativa no editor pra receber o codigo.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
            EndIf

          Case G_InsertLoop
            Protected InsertLoopText.s = SpriteEd_BuildInsertLoopText(Grid(), GridSize, SpriteMode, SelectedColor, SpriteNumber, SpriteTag)
            If InjectTextAtCursor(InsertLoopText)
              SetGadgetText(G_Status, "Sprite #" + Str(SpriteNumber) + " inserido: DATA + loop de leitura no cursor.")
            Else
              MessageRequester("Nao foi possivel inserir",
                                "Nenhuma aba de texto ativa no editor pra receber o codigo.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
            EndIf

          Case G_InsertAll
            Protected AllSpritesText.s = SpriteEd_BuildAllSpritesDataText()
            If AllSpritesText = ""
              MessageRequester("Banco vazio", "Nenhum sprite registrado no projeto ainda (use o botao Registrar).", #PB_MessageRequester_Ok)
            ElseIf InjectTextAtCursor(AllSpritesText)
              SetGadgetText(G_Status, "DATA de todos os sprites do banco inserido no cursor.")
            Else
              MessageRequester("Nao foi possivel inserir",
                                "Nenhuma aba de texto ativa no editor pra receber o codigo.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
            EndIf

          Case G_Close
            If Not SpriteDirty Or SpriteEd_ConfirmDiscardSprite()
              Quit = #True
            EndIf
        EndSelect

      ; ESC cancela uma marcacao de dois pontos em andamento, igual ao
      ; botao direito do mouse sobre a grade.
      Case #PB_Event_Menu
        If EventMenu() = #SpriteEd_CancelShortcut And LineStartRow <> -1
          RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
          LineStartRow = -1 : LineStartCol = -1 : PreviewRow = -1 : PreviewCol = -1
          SetGadgetText(G_Status, SpriteEd_StatusText(GridSize))
          SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
        EndIf

      ; Faz piscar o marcador do ponto inicial enquanto uma forma de dois
      ; pontos esta aguardando o segundo clique.
      Case #PB_Event_Timer
        If EventTimer() = #SpriteEd_BlinkTimer And LineStartRow <> -1
          BlinkOn = Bool(Not BlinkOn)
          SpriteEd_ComputePreviewMask(PreviewMask(), GridSize, ToolMode, LineStartRow, LineStartCol, PreviewRow, PreviewCol)
          SpriteEd_Redraw(G_Canvas, GridSize, CellSize, Grid(), Palette())
          SpriteEd_DrawPreviewOverlay(G_Canvas, GridSize, CellSize, PreviewMask(), Palette(SelectedColor), BlinkOn, LineStartRow, LineStartCol)
        EndIf

      Case #PB_Event_CloseWindow
        If Not SpriteDirty Or SpriteEd_ConfirmDiscardSprite()
          Quit = #True
        EndIf
    EndSelect
  Until Quit

  RemoveWindowTimer(Win, #SpriteEd_BlinkTimer)
  CloseModelessChildWindow(ParentWindow, Win)
  FreeImage(ClearIcon)
  FreeImage(InvertIcon)
  FreeImage(PencilIcon)
  FreeImage(EraserIcon)
  FreeImage(BrushIcon)
  FreeImage(LineToolIcon)
  FreeImage(RectOutlineIcon)
  FreeImage(RectFillIcon)
  FreeImage(EllipseOutlineIcon)
  FreeImage(EllipseFillIcon)
  FreeImage(FillIcon)
  FreeImage(NewSpriteIcon)
  FreeImage(RegisterIcon)
  FreeImage(CopyIcon)
  FreeImage(PasteIcon)
  FreeImage(InjectIcon)
EndProcedure
