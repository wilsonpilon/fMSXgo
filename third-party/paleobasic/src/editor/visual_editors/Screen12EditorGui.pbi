;
; ------------------------------------------------------------
;  Apelido interno: Pixelossauro (tema pre-historico do projeto, ver README.md)
;  Screen12EditorGui.pbi - Criar -> Screen 1+2...: editor de tela de texto
;  MSX no espirito de Screen1EditorGui.pbi (mesma grade FIXA 32x24 de bytes
;  MSX crus, mesmas ferramentas Texto/Caractere/Quadro/Sombra/Bloco/
;  Borracha, mesmo mecanismo de moldura/estampa), mas gerando **SCREEN 2**
;  (Graphics II) de verdade em vez de SCREEN 1 - o modo mais complexo desta
;  familia porque o hardware do SCREEN 2 tem DOIS recursos que o SCREEN 1
;  nao tem:
;
;  1) A Pattern/Color Table sao divididas em **3 "tercos"** de 2048 bytes
;     cada, selecionados por QUAL TERCO DE LINHAS DE TELA (0-7/8-15/16-23,
;     ou seja Terco = Linha/8) a celula esta - CADA TERCO tem seu proprio
;     alfabeto (endereco Pattern = Terco*2048, Color = &H2000+Terco*2048,
;     confirmado contra a MSX Wiki, mesmo endereco base de screen1_screens
;     pro terco 0). O usuario escolhe um alfabeto (Padrao ou um do banco do
;     projeto) POR TERCO, independentemente - "Fonte Terco 1/2/3" na coluna
;     direita.
;
;  2) A Color Table real do SCREEN 2 guarda 1 par Tinta/Fundo **POR LINHA DE
;     SCANLINE de cada codigo de caractere** (8 linhas por glifo), nao 1 por
;     celula de tela nem 1 por grupo de 8 codigos como o SCREEN 1
;     (screen1_screens/octet_data) - e o "color clash" de verdade do
;     hardware: TODA ocorrencia do mesmo codigo no mesmo terco usa a MESMA
;     cor por linha, nao importa em que coluna/linha de TELA ele aparece.
;     3 tercos x 256 codigos x 8 linhas = 6144 entradas, do tamanho exato
;     da Color Table real (6144 bytes). A "tabela ASCII" da coluna direita
;     mostra 1 terco por vez (seletor "Terco 1/2/3" acima da grade, que
;     acompanha automaticamente qual terco REAL foi tocado por ultimo no
;     canvas - ver Scr12Ed_SyncEditThirdToRow) com cada celula ja desenhada
;     com as 8 cores por linha daquele codigo naquele terco - clicar escolhe
;     o "byte atual"; os botoes **Cores do caractere...**/**Cores em
;     bloco...** abrem um editor ampliado (janela separada) pra pintar linha
;     a linha, o de bloco pedindo o codigo inicial/final por 2 cliques na
;     propria tabela ASCII (marcados com uma moldura ciano enquanto
;     escolhidos, ver BlockPicking no loop de eventos) em vez de digitar
;     numeros; **Copiar cores**/**Colar cores** movem o padrao de 8 cores de
;     um codigo pra outro; **Resetar caractere/bloco/todos** zeram (Tinta
;     15/Fundo 1 = letra branca em fundo preto) o byte atual, um intervalo
;     escolhido do mesmo jeito por 2 cliques, ou os 256 codigos do terco de
;     uma vez.
;
;  Reaproveita DIRETO (sem nenhuma alteracao) de Screen1EditorGui.pbi -
;  mesma grade 32x24, mesma semantica de byte MSX cru por celula:
;  Scr1Ed_GlyphByteFor/ByteToChar, Scr1Ed_StampText/DrawBox/ApplyShadow/
;  FillRect/StampBoxEdge/BoxMaskToByte, Scr1Ed_BuildLineExpr (geracao de
;  texto). So a COR e a RENDERIZACAO sao novas aqui - Scr0Ed_DrawGlyphBitmap
;  assume 1 tinta/1 fundo pro glifo inteiro, nao serve; ver
;  Scr12Ed_DrawGlyphRows abaixo.
;
;  Grade FIXA 32x24 (768 celulas) - mesma constante #Scr1Ed_Cols/#Scr1Ed_Rows
;  de Screen1EditorGui.pbi, nao redefinida aqui.
; ------------------------------------------------------------
;

#Scr12Ed_ToolPanelW = 480
#Scr12Ed_ToolPanelH = 160

#Scr12Ed_CharPickZoom   = 2
#Scr12Ed_CharPickCellPx = 8 * #Scr12Ed_CharPickZoom   ; 16
#Scr12Ed_CharPickCols   = 16
#Scr12Ed_CharPickRows   = 16
#Scr12Ed_CharPickW      = #Scr12Ed_CharPickCols * #Scr12Ed_CharPickCellPx   ; 256
#Scr12Ed_CharPickH      = #Scr12Ed_CharPickRows * #Scr12Ed_CharPickCellPx   ; 256

#Scr12Ed_PreviewZoom = 20
#Scr12Ed_PreviewSize = 8 * #Scr12Ed_PreviewZoom   ; 160

; Desenha um glifo com cor INDEPENDENTE por linha de scanline (o "color
; clash" de verdade do SCREEN 2) - ColorInk/ColorPaper sao os arrays
; completos (Terco,Codigo,Linha), Third/ByteCode escolhem qual entrada usar
; em cada uma das 8 linhas. Chamada de dentro de um StartDrawing/StopDrawing
; ja aberto pelo chamador (mesmo padrao de Scr0Ed_DrawGlyphBitmap).
Procedure Scr12Ed_DrawGlyphRows(Array CharsetBytes.a(2), ByteCode.i, X.i, Y.i, Zoom.i, Third.i, Array ColorInk.a(3), Array ColorPaper.a(3), Array Palette.l(1))
  ; Funde pixels de tinta adjacentes na mesma linha num Box() so (mesma
  ; tecnica de Scr2Ed_RedrawCanvas, Screen2EditorGui.pbi) em vez de um
  ; Box() por pixel - chamada por celula num redesenho de tela inteira,
  ; entao o numero de Box() por glifo importa no total.
  Protected PxRow, PxCol, ByteVal.a, InkRGB.l, PaperRGB.l, RunStart, InRun.b
  For PxRow = 0 To 7
    InkRGB = Palette(ColorInk(Third, ByteCode, PxRow))
    PaperRGB = Palette(ColorPaper(Third, ByteCode, PxRow))
    Box(X, Y + PxRow * Zoom, 8 * Zoom, Zoom, PaperRGB)
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

; Despacha pro CharsetBytes certo (CB0/CB1/CB2) conforme o terco da CELULA
; (nao o terco "em edicao" da tabela ASCII - a celula sempre usa o alfabeto/
; cor do SEU PROPRIO terco, Linha/8, nao importa o que esta selecionado na
; coluna direita) - usado so por Scr12Ed_RedrawCanvas, onde uma tela pode
; ter celulas dos 3 tercos ao mesmo tempo.
Procedure Scr12Ed_DrawGlyphRowsT(Array CB0.a(2), Array CB1.a(2), Array CB2.a(2), ByteCode.i, X.i, Y.i, Zoom.i, Third.i, Array ColorInk.a(3), Array ColorPaper.a(3), Array Palette.l(1))
  Select Third
    Case 0 : Scr12Ed_DrawGlyphRows(CB0(), ByteCode, X, Y, Zoom, Third, ColorInk(), ColorPaper(), Palette())
    Case 1 : Scr12Ed_DrawGlyphRows(CB1(), ByteCode, X, Y, Zoom, Third, ColorInk(), ColorPaper(), Palette())
    Case 2 : Scr12Ed_DrawGlyphRows(CB2(), ByteCode, X, Y, Zoom, Third, ColorInk(), ColorPaper(), Palette())
  EndSelect
EndProcedure

; Redesenha a tela inteira - Terco de cada celula = Linha/8 (real: qual
; terco de linhas de tela ela esta, nao o terco "em edicao" da tabela ASCII).
Procedure Scr12Ed_RedrawCanvas(Canvas, Array GridBytes.a(1), Array CB0.a(2), Array CB1.a(2), Array CB2.a(2), Array ColorInk.a(3), Array ColorPaper.a(3), Array Palette.l(1), MarkCol.i = -1, MarkRow.i = -1)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected Zoom = Scr0Ed_ZoomForWidth(#Scr1Ed_Cols)
  Protected CellPx = 8 * Zoom
  Protected Row, Col, Idx, ByteCode, Third
  For Row = 0 To #Scr1Ed_Rows - 1
    Third = Row / 8
    For Col = 0 To #Scr1Ed_Cols - 1
      Idx = Row * #Scr1Ed_Cols + Col
      ByteCode = GridBytes(Idx)
      Scr12Ed_DrawGlyphRowsT(CB0(), CB1(), CB2(), ByteCode, Col * CellPx, Row * CellPx, Zoom, Third, ColorInk(), ColorPaper(), Palette())
    Next
  Next

  ; Linhas-guia entre os 3 tercos (linha de tela 8 e 16) - preto+branco lado a
  ; lado pra ficar visivel não importa a cor do fundo desenhado ali - so uma
  ; referencia visual, nao faz parte da arte/codigo gerado.
  DrawingMode(#PB_2DDrawing_Default)
  Protected DividerRow
  For DividerRow = 8 To 16 Step 8
    Line(0, DividerRow * CellPx - 1, #Scr1Ed_Cols * CellPx, 1, RGB(0, 0, 0))
    Line(0, DividerRow * CellPx, #Scr1Ed_Cols * CellPx, 1, RGB(255, 255, 255))
  Next

  If MarkCol >= 0 And MarkRow >= 0
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(MarkCol * CellPx, MarkRow * CellPx, CellPx, CellPx, RGB(255, 220, 0))
    Box(MarkCol * CellPx + 1, MarkRow * CellPx + 1, CellPx - 2, CellPx - 2, RGB(255, 220, 0))
    DrawingMode(#PB_2DDrawing_Default)
  EndIf

  StopDrawing()
EndProcedure

; Grade de 256 celulas do terco EM EDICAO (EditThird, escolhido pelo
; seletor "Terco 1/2/3" da janela principal - independente do terco real de
; cada celula da tela, ver comentario de Scr12Ed_DrawGlyphRowsT) - cada
; celula ja mostra as 8 cores por linha daquele codigo naquele terco.
; RangeLo/RangeHi (opcionais, -1 = nenhum) desenham uma marca sutil (moldura
; ciano por fora da borda cinza normal) nas celulas desse intervalo - usado
; enquanto o usuario esta escolhendo o inicio/fim de um bloco direto na
; tabela (ver BlockPicking no loop de eventos), sem esconder o glifo/cor por
; baixo. ATENCAO: reseta DrawingMode(#PB_2DDrawing_Default) no INICIO de cada
; iteracao antes de desenhar o glifo - bug real ja corrigido em
; Screen1EditorGui.pbi (Scr1Ed_DrawCharPicker) onde o Outlined da borda de
; uma celula vazava pra iteracao seguinte e apagava o preenchimento; ver
; memoria do projeto "screen1-editor".
Procedure Scr12Ed_DrawCharPicker(Canvas, Array CharsetBytes.a(2), Array ColorInk.a(3), Array ColorPaper.a(3), Array Palette.l(1), Third.i, Selected.i, RangeLo.i = -1, RangeHi.i = -1)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected i, Row, Col, X, Y
  For i = 0 To 255
    Row = i / #Scr12Ed_CharPickCols
    Col = i % #Scr12Ed_CharPickCols
    X = Col * #Scr12Ed_CharPickCellPx
    Y = Row * #Scr12Ed_CharPickCellPx

    DrawingMode(#PB_2DDrawing_Default)
    Scr12Ed_DrawGlyphRows(CharsetBytes(), i, X, Y, #Scr12Ed_CharPickZoom, Third, ColorInk(), ColorPaper(), Palette())

    DrawingMode(#PB_2DDrawing_Outlined)
    Box(X, Y, #Scr12Ed_CharPickCellPx, #Scr12Ed_CharPickCellPx, RGB(120, 120, 120))

    If i = Selected
      Box(X + 1, Y + 1, #Scr12Ed_CharPickCellPx - 2, #Scr12Ed_CharPickCellPx - 2, RGB(255, 220, 0))
    EndIf

    If RangeLo >= 0 And i >= RangeLo And i <= RangeHi
      Box(X - 1, Y - 1, #Scr12Ed_CharPickCellPx + 2, #Scr12Ed_CharPickCellPx + 2, RGB(0, 200, 255))
    EndIf
  Next
  DrawingMode(#PB_2DDrawing_Default)
  StopDrawing()
EndProcedure

Procedure.s Scr12Ed_ByteInfoText(Byte.i, Third.i)
  ProcedureReturn "Byte atual: " + Str(Byte) + " (&H" + RSet(Hex(Byte), 2, "0") + ") - Terco " + Str(Third + 1)
EndProcedure

; Redesenha a previa ampliada + as 16 mini-paletas (Tinta/Fundo x 8 linhas)
; do popup de cores - procedure de topo (nao aninhada: PureBasic nao
; permite Procedure dentro de Procedure) chamada tanto no desenho inicial
; quanto apos cada clique numa paleta.
Procedure Scr12Ed_ColorPopupRedraw(G_Preview, Array G_RowInk.i(1), Array G_RowPaper.i(1), Array CharsetBytes.a(2), Array Palette.l(1), Third.i, ByteStart.i, Array ColorInk.a(3), Array ColorPaper.a(3))
  If StartDrawing(CanvasOutput(G_Preview))
    Scr12Ed_DrawGlyphRows(CharsetBytes(), ByteStart, 0, 0, #Scr12Ed_PreviewZoom, Third, ColorInk(), ColorPaper(), Palette())
    StopDrawing()
  EndIf
  Protected R
  For R = 0 To 7
    Scr2Ed_RedrawMiniPalette(G_RowInk(R), ColorInk(Third, ByteStart, R), Palette())
    Scr2Ed_RedrawMiniPalette(G_RowPaper(R), ColorPaper(Third, ByteStart, R), Palette())
  Next
EndProcedure

; --- Editor de cores ampliado (janela separada, compartilhada entre "Cores
; do caractere..." - ByteStart=ByteEnd - e "Cores em bloco..." -
; ByteStart<ByteEnd, aplica o MESMO padrao de 8 linhas a todos os codigos do
; intervalo de uma vez, decisao confirmada com o usuario). Aplica ao vivo a
; cada clique numa paleta - sem botao "Aplicar" separado, mesmo padrao de
; clique-aplica-na-hora das paletas Tinta/Fundo dos outros editores desta
; IDE. Os arrays ColorInk/ColorPaper sao alterados diretamente (passados
; por referencia, padrao PureBasic) - o chamador so precisa redesenhar
; canvas/grade depois que a janela fechar.
Procedure Scr12Ed_ColorEditor_OpenWindow(ParentWindow, Array CharsetBytes.a(2), Array Palette.l(1), Third.i, ByteStart.i, ByteEnd.i, Array ColorInk.a(3), Array ColorPaper.a(3))
  Protected WinW = 640, WinH = 620
  Protected Title.s
  If ByteStart = ByteEnd
    Title = "Cores do caractere #" + Str(ByteStart) + " - Terco " + Str(Third + 1)
  Else
    Title = "Cores em bloco #" + Str(ByteStart) + "-" + Str(ByteEnd) + " - Terco " + Str(Third + 1)
  EndIf

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, Title,
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  Protected PreviewX = (WinW - #Scr12Ed_PreviewSize) / 2
  Protected PreviewY = 40
  Protected G_Preview = CanvasGadget(#PB_Any, PreviewX, PreviewY, #Scr12Ed_PreviewSize, #Scr12Ed_PreviewSize)

  If ByteStart <> ByteEnd
    TextGadget(#PB_Any, 20, PreviewY + #Scr12Ed_PreviewSize + 8, WinW - 40, 20,
      "Previa do codigo #" + Str(ByteStart) + " - as cores escolhidas abaixo se aplicam a TODOS os codigos " + Str(ByteStart) + "-" + Str(ByteEnd) + ".",
      #PB_Text_Center)
  EndIf

  Protected RowsY = PreviewY + #Scr12Ed_PreviewSize + 36
  Protected ColW = 300
  Protected Col0X = 20, Col1X = 20 + ColW
  Protected RowH = 82

  Dim G_RowInk.i(7)
  Dim G_RowPaper.i(7)
  Protected R, RX, RY
  For R = 0 To 7
    If R < 4
      RX = Col0X : RY = RowsY + R * RowH
    Else
      RX = Col1X : RY = RowsY + (R - 4) * RowH
    EndIf
    TextGadget(#PB_Any, RX, RY, 60, 20, "Linha " + Str(R) + ":")
    TextGadget(#PB_Any, RX, RY + 18, 50, 16, "Tinta")
    G_RowInk(R) = CanvasGadget(#PB_Any, RX, RY + 34, #Scr2Ed_PaletteSize, #Scr2Ed_PaletteSize)
    TextGadget(#PB_Any, RX + #Scr2Ed_PaletteSize + 10, RY + 18, 50, 16, "Fundo")
    G_RowPaper(R) = CanvasGadget(#PB_Any, RX + #Scr2Ed_PaletteSize + 10, RY + 34, #Scr2Ed_PaletteSize, #Scr2Ed_PaletteSize)
  Next

  Protected CloseY = RowsY + 4 * RowH + 10
  Protected G_Close = ThemedButton((WinW - 120) / 2, CloseY, 120, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  Scr12Ed_ColorPopupRedraw(G_Preview, G_RowInk(), G_RowPaper(), CharsetBytes(), Palette(), Third, ByteStart, ColorInk(), ColorPaper())

  Protected Event, Quit = #False, MouseX, MouseY, ClickIdx, Cd
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        For R = 0 To 7
          If EventGadget() = G_RowInk(R)
            If EventType() = #PB_EventType_LeftButtonDown
              MouseX = GetGadgetAttribute(G_RowInk(R), #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(G_RowInk(R), #PB_Canvas_MouseY)
              ClickIdx = Scr2Ed_PaletteHitTest(MouseX, MouseY)
              If ClickIdx >= 0
                For Cd = ByteStart To ByteEnd
                  ColorInk(Third, Cd, R) = ClickIdx
                Next
                Scr12Ed_ColorPopupRedraw(G_Preview, G_RowInk(), G_RowPaper(), CharsetBytes(), Palette(), Third, ByteStart, ColorInk(), ColorPaper())
              EndIf
            EndIf
            Break
          EndIf
          If EventGadget() = G_RowPaper(R)
            If EventType() = #PB_EventType_LeftButtonDown
              MouseX = GetGadgetAttribute(G_RowPaper(R), #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(G_RowPaper(R), #PB_Canvas_MouseY)
              ClickIdx = Scr2Ed_PaletteHitTest(MouseX, MouseY)
              If ClickIdx >= 0
                For Cd = ByteStart To ByteEnd
                  ColorPaper(Third, Cd, R) = ClickIdx
                Next
                Scr12Ed_ColorPopupRedraw(G_Preview, G_RowInk(), G_RowPaper(), CharsetBytes(), Palette(), Third, ByteStart, ColorInk(), ColorPaper())
              EndIf
            EndIf
            Break
          EndIf
        Next

        If EventGadget() = G_Close
          Quit = #True
        EndIf

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure

; --- Geracao de codigo: SCREEN 2 + Color Table completa dos 3 tercos
; (sempre emitida, 2048 bytes/terco - endereco &H2000+terco*2048) + Pattern
; Generator Table dos tercos com fonte customizada (endereco terco*2048,
; mesma matematica ja usada por Scr2Ed_GenAlphabetLoader em
; Screen2EditorGui.pbi) + LOCATE/PRINT por linha (reaproveita
; Scr1Ed_BuildLineExpr - mesma semantica de byte cru, nenhuma mudanca
; necessaria).
Procedure.s Scr12Ed_BuildCode(Array GridBytes.a(1), Array AlphaThirds.i(1), Array ColorInk.a(3), Array ColorPaper.a(3), Array CB0.a(2), Array CB1.a(2), Array CB2.a(2))
  Protected Result.s = ""
  Result + "SCREEN 2" + #CRLF$

  Protected Third, Code, Rw, PatternAddr, ColorAddr, LineVals.s, Count
  For Third = 0 To 2
    PatternAddr = Third * 2048
    ColorAddr = 8192 + Third * 2048

    If AlphaThirds(Third) <> -1
      Result + "' Carrega a fonte customizada #" + Str(AlphaThirds(Third)) + " na Pattern Generator Table do terco " + Str(Third) + " (&H" + Hex(PatternAddr) + ")" + #CRLF$
      Result + "FOR SI=0 TO 2047:READ SD:VPOKE " + Str(PatternAddr) + "+SI,SD:NEXT SI" + #CRLF$
      LineVals = "" : Count = 0
      Protected FRow, FCol
      For FRow = 0 To 255
        For FCol = 0 To 7
          If Count > 0 And Count % 16 = 0
            Result + "DATA " + LineVals + #CRLF$
            LineVals = ""
          EndIf
          If LineVals <> ""
            LineVals + ","
          EndIf
          Select Third
            Case 0 : LineVals + "&H" + RSet(Hex(CB0(FRow, FCol)), 2, "0")
            Case 1 : LineVals + "&H" + RSet(Hex(CB1(FRow, FCol)), 2, "0")
            Case 2 : LineVals + "&H" + RSet(Hex(CB2(FRow, FCol)), 2, "0")
          EndSelect
          Count + 1
        Next
      Next
      If LineVals <> ""
        Result + "DATA " + LineVals + #CRLF$
      EndIf
    EndIf

    Result + "' Tabela de cores do terco " + Str(Third) + " (256 codigos x 8 linhas, Color Table padrao &H" + Hex(ColorAddr) + ")" + #CRLF$
    Result + "FOR CI=0 TO 2047:READ CD:VPOKE " + Str(ColorAddr) + "+CI,CD:NEXT CI" + #CRLF$
    LineVals = "" : Count = 0
    For Code = 0 To 255
      For Rw = 0 To 7
        If Count > 0 And Count % 16 = 0
          Result + "DATA " + LineVals + #CRLF$
          LineVals = ""
        EndIf
        If LineVals <> ""
          LineVals + ","
        EndIf
        LineVals + "&H" + RSet(Hex(((ColorInk(Third, Code, Rw) & $F) << 4) | (ColorPaper(Third, Code, Rw) & $F)), 2, "0")
        Count + 1
      Next
    Next
    If LineVals <> ""
      Result + "DATA " + LineVals + #CRLF$
    EndIf
  Next

  Protected Row, Line.s
  For Row = 0 To #Scr1Ed_Rows - 1
    Line = Scr1Ed_BuildLineExpr(GridBytes(), Row)
    If Line <> ""
      Result + "LOCATE 0," + Str(Row) + ":PRINT " + Line + ";" + #CRLF$
    EndIf
  Next

  ProcedureReturn Result
EndProcedure

Procedure.b Scr12Ed_ConfirmDiscard()
  ProcedureReturn Bool(MessageRequester("Tela nao registrada",
                        "As alteracoes desta tela ainda nao foram registradas no projeto." + Chr(10) +
                        "Descartar mesmo assim?",
                        #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
EndProcedure

; Abre o popup de cores (Scr12Ed_ColorEditor_OpenWindow) escolhendo o
; CharsetBytes certo (CB0/CB1/CB2) pro terco EM EDICAO - so existe pra nao
; repetir o Select nos 2 pontos que abrem o popup (caractere unico e bloco).
Procedure Scr12Ed_OpenColorEditorForThird(ParentWindow, Array CB0.a(2), Array CB1.a(2), Array CB2.a(2), Array Palette.l(1), Third.i, ByteStart.i, ByteEnd.i, Array ColorInk.a(3), Array ColorPaper.a(3))
  Select Third
    Case 0 : Scr12Ed_ColorEditor_OpenWindow(ParentWindow, CB0(), Palette(), Third, ByteStart, ByteEnd, ColorInk(), ColorPaper())
    Case 1 : Scr12Ed_ColorEditor_OpenWindow(ParentWindow, CB1(), Palette(), Third, ByteStart, ByteEnd, ColorInk(), ColorPaper())
    Case 2 : Scr12Ed_ColorEditor_OpenWindow(ParentWindow, CB2(), Palette(), Third, ByteStart, ByteEnd, ColorInk(), ColorPaper())
  EndSelect
EndProcedure

; Acha o indice no ComboBox (Padrao + "#N"...) correspondente a um numero
; de alfabeto (-1 = Padrao, indice 0) - usado ao carregar/trocar de tela.
Procedure.i Scr12Ed_ComboIndexFor(Combo, AlphaNumber.i)
  If AlphaNumber = -1
    ProcedureReturn 0
  EndIf
  Protected i
  For i = 1 To CountGadgetItems(Combo) - 1
    If Val(Mid(GetGadgetItemText(Combo, i), 2)) = AlphaNumber
      ProcedureReturn i
    EndIf
  Next
  ProcedureReturn 0
EndProcedure

; Sincroniza o seletor "Terco 1/2/3" (e a tabela ASCII/picker) com o terco
; REAL da linha de tela que acabou de ser tocada no canvas (Linha/8) - existe
; pra nunca deixar o usuario editando/conferindo cores de um terco enquanto
; pinta em outro sem perceber, ja que a cor de fato usada ao imprimir sempre
; vem do terco da LINHA, nunca do seletor (ver comentario de
; Scr12Ed_DrawGlyphRowsT). *EditThird e' ponteiro cru (PureBasic nao aceita
; tipo nativo direto num parametro de ponteiro, so o bruto + PokeI/PeekI),
; chamador passa @EditThird. So faz algo quando o terco realmente muda.
Procedure Scr12Ed_SyncEditThirdToRow(Row.i, *EditThird, G_Third0, G_Third1, G_Third2, G_ByteInfo, G_CharPicker, Array CB0.a(2), Array CB1.a(2), Array CB2.a(2), Array ColorInk.a(3), Array ColorPaper.a(3), Array Palette.l(1), CurrentByte.i)
  Protected NewThird = Row / 8
  If NewThird = PeekI(*EditThird)
    ProcedureReturn
  EndIf
  PokeI(*EditThird, NewThird)
  Select NewThird
    Case 0 : SetGadgetState(G_Third0, #True)
    Case 1 : SetGadgetState(G_Third1, #True)
    Case 2 : SetGadgetState(G_Third2, #True)
  EndSelect
  SetGadgetText(G_ByteInfo, Scr12Ed_ByteInfoText(CurrentByte, NewThird))
  Select NewThird
    Case 0 : Scr12Ed_DrawCharPicker(G_CharPicker, CB0(), ColorInk(), ColorPaper(), Palette(), NewThird, CurrentByte)
    Case 1 : Scr12Ed_DrawCharPicker(G_CharPicker, CB1(), ColorInk(), ColorPaper(), Palette(), NewThird, CurrentByte)
    Case 2 : Scr12Ed_DrawCharPicker(G_CharPicker, CB2(), ColorInk(), ColorPaper(), Palette(), NewThird, CurrentByte)
  EndSelect
EndProcedure

Procedure Screen12Editor_OpenWindow(ParentWindow)
  Protected LeftX = 24
  Protected CanvasY = 24
  Protected Zoom = Scr0Ed_ZoomForWidth(#Scr1Ed_Cols)   ; 4 (32 <= 40)
  Protected CanvasW = #Scr1Ed_Cols * 8 * Zoom            ; 1024
  Protected CanvasH = #Scr1Ed_Rows * 8 * Zoom            ; 768

  Protected RightX = LeftX + CanvasW + 24
  Protected RightColW = 340

  Protected FontRow0Y = CanvasY
  Protected FontRow1Y = FontRow0Y + 30
  Protected FontRow2Y = FontRow1Y + 30
  Protected ByteLabelY = FontRow2Y + 38
  Protected ByteFieldY = ByteLabelY + 22
  Protected ThirdSelLabelY = ByteFieldY + 32
  Protected ThirdSelRowY = ThirdSelLabelY + 20
  Protected PickLabelY = ThirdSelRowY + 30
  Protected PickGridY = PickLabelY + 34
  Protected ButtonsY = PickGridY + #Scr12Ed_CharPickH + 12
  Protected ProjBarY = ButtonsY + 4 * 34 + 12
  Protected ProjBarRow2Y = ProjBarY + #CharEd_IconBtnH + 6

  Protected ToolPanelY = CanvasY + CanvasH + 24

  Protected WinW = RightX + RightColW + 24
  Protected WinH = ToolPanelY + #Scr12Ed_ToolPanelH + 20

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Tela MSX (SCREEN 1+2)",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  Protected G_Canvas = CanvasGadget(#PB_Any, LeftX, CanvasY, CanvasW, CanvasH)

  TextGadget(#PB_Any, RightX, FontRow0Y + 3, 65, 20, "Fonte T1:")
  Protected G_FontCombo0 = ComboBoxGadget(#PB_Any, RightX + 70, FontRow0Y, RightColW - 70, 24)
  TextGadget(#PB_Any, RightX, FontRow1Y + 3, 65, 20, "Fonte T2:")
  Protected G_FontCombo1 = ComboBoxGadget(#PB_Any, RightX + 70, FontRow1Y, RightColW - 70, 24)
  TextGadget(#PB_Any, RightX, FontRow2Y + 3, 65, 20, "Fonte T3:")
  Protected G_FontCombo2 = ComboBoxGadget(#PB_Any, RightX + 70, FontRow2Y, RightColW - 70, 24)
  AddGadgetItem(G_FontCombo0, -1, "Padrao")
  AddGadgetItem(G_FontCombo1, -1, "Padrao")
  AddGadgetItem(G_FontCombo2, -1, "Padrao")

  TextGadget(#PB_Any, RightX, ByteLabelY, RightColW, 20, "Byte atual (digite ASCII ou clique na grade abaixo):")
  Protected G_AsciiChar = StringGadget(#PB_Any, RightX, ByteFieldY, 60, 24, " ")
  Protected G_ByteInfo = TextGadget(#PB_Any, RightX + 70, ByteFieldY + 4, RightColW - 70, 20, "")

  TextGadget(#PB_Any, RightX, ThirdSelLabelY, RightColW, 18, "Tabela ASCII mostrando o terco:")
  Protected G_Third0 = OptionGadget(#PB_Any, RightX, ThirdSelRowY, 110, 22, "Terco 1 (0-7)")
  Protected G_Third1 = OptionGadget(#PB_Any, RightX + 112, ThirdSelRowY, 110, 22, "Terco 2 (8-15)")
  Protected G_Third2 = OptionGadget(#PB_Any, RightX + 224, ThirdSelRowY, 116, 22, "Terco 3 (16-23)")
  SetGadgetState(G_Third0, #True)

  Protected PickHintDefault.s = "Clique escolhe o byte atual (usado por Caractere/Cores). O fundo ja mostra a cor real por linha daquele codigo neste terco. Bloco/Resetar bloco pedem 2 cliques aqui (inicio e fim, marcados em ciano)."
  Protected G_PickHint = TextGadget(#PB_Any, RightX, PickLabelY, RightColW, 34, PickHintDefault)
  Protected G_CharPicker = CanvasGadget(#PB_Any, RightX, PickGridY, #Scr12Ed_CharPickW, #Scr12Ed_CharPickH)

  Protected BtnW = (RightColW - 8) / 2
  Protected G_CharColors = ThemedButton(RightX, ButtonsY, BtnW, 30, "Cores do caractere...", "")
  Protected G_BlockColors = ThemedButton(RightX + BtnW + 8, ButtonsY, BtnW, 30, "Cores em bloco...", "")
  Protected G_CopyColors = ThemedButton(RightX, ButtonsY + 34, BtnW, 30, "Copiar cores", "")
  Protected G_PasteColors = ThemedButton(RightX + BtnW + 8, ButtonsY + 34, BtnW, 30, "Colar cores", "")
  Protected G_ResetChar = ThemedButton(RightX, ButtonsY + 68, BtnW, 30, "Resetar caractere", "")
  Protected G_ResetBlock = ThemedButton(RightX + BtnW + 8, ButtonsY + 68, BtnW, 30, "Resetar bloco...", "")
  Protected G_ResetAll = ThemedButton(RightX, ButtonsY + 102, RightColW, 30, "Resetar TODOS os caracteres do terco", "")
  GadgetToolTip(G_CharColors, "Abre a previa ampliada do byte atual e permite escolher Tinta/Fundo linha a linha (terco selecionado acima)")
  GadgetToolTip(G_BlockColors, "Clique o codigo inicial e final na tabela ASCII abaixo e aplica o MESMO padrao de 8 cores a todos eles de uma vez")
  GadgetToolTip(G_CopyColors, "Copia as 8 cores por linha do byte atual (terco selecionado acima)")
  GadgetToolTip(G_PasteColors, "Cola as 8 cores copiadas no byte atual (terco selecionado acima)")
  GadgetToolTip(G_ResetChar, "Volta o byte atual (terco selecionado acima) para fundo preto / letra branca")
  GadgetToolTip(G_ResetBlock, "Clique o codigo inicial e final na tabela ASCII abaixo e volta todos eles para fundo preto / letra branca")
  GadgetToolTip(G_ResetAll, "Volta os 256 codigos do terco selecionado acima para fundo preto / letra branca")

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
  GadgetToolTip(G_New, "Nova tela (numera automaticamente, comeca em branco)")
  Cx + #CharEd_IconBtnW + 2
  Protected RegisterIcon = CharEd_CreateRegisterIcon(#CharEd_IconSize)
  Protected G_Register = ButtonImageGadget(#PB_Any, Cx, ProjBarRow2Y, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(RegisterIcon))
  GadgetToolTip(G_Register, "Registrar: grava esta tela no projeto")

  Protected G_Panel = PanelGadget(#PB_Any, LeftX, ToolPanelY, #Scr12Ed_ToolPanelW, #Scr12Ed_ToolPanelH)
  Protected ToolContentW = #Scr12Ed_ToolPanelW - 20

  AddGadgetItem(G_Panel, -1, "Texto")
    TextGadget(#PB_Any, 10, 10, ToolContentW, 40,
      "Digite o texto e clique no canvas pra posicionar (horizontal, a partir da celula clicada; corta se passar do fim da linha).")
    Protected G_TextInput = StringGadget(#PB_Any, 10, 56, ToolContentW, 24, "")

  AddGadgetItem(G_Panel, -1, "Caractere")
    TextGadget(#PB_Any, 10, 10, ToolContentW, 70,
      "Escolha o byte na tabela ASCII da coluna direita (ou digite ASCII no campo acima dela), depois clique ou arraste no canvas pra estampar. A cor final vem do terco REAL da linha clicada (0-7/8-15/16-23), nao do terco selecionado na tabela.")

  AddGadgetItem(G_Panel, -1, "Quadro")
    TextGadget(#PB_Any, 10, 10, ToolContentW, 80,
      "Dois cliques no canvas: primeiro marca um canto, segundo marca o canto oposto - desenha a moldura com linhas simples, unindo automaticamente com quadros ja existentes que encostarem (formando T/cruz na juncao)." + Chr(10) + Chr(10) +
      "Botao direito cancela a marcacao pendente.")

  AddGadgetItem(G_Panel, -1, "Sombra")
    TextGadget(#PB_Any, 10, 10, ToolContentW, 80,
      "Dois cliques (cantos opostos de um retangulo, tipicamente o mesmo de um quadro ja desenhado) - estampa uma faixa de sombra deslocada uma celula pra baixo e pra direita, ao longo das bordas direita e inferior.")

  AddGadgetItem(G_Panel, -1, "Bloco")
    TextGadget(#PB_Any, 10, 10, ToolContentW, 90,
      "Dois cliques (cantos opostos) - preenche o retangulo inteiro com o byte atual. Util pra texturas, fundos ou apagar uma area maior de uma vez.")

  AddGadgetItem(G_Panel, -1, "Borracha")
    TextGadget(#PB_Any, 10, 10, ToolContentW, 40, "Clique ou arraste no canvas pra apagar (estampa espaco).")

  CloseGadgetList()

  Protected ButtonsX = LeftX + #Scr12Ed_ToolPanelW + 24
  Protected G_Inject = ThemedButton(ButtonsX, ToolPanelY, 180, 32, "Injetar no cursor", Chr(#Icon_Insert))
  Protected G_Copy = ThemedButton(ButtonsX, ToolPanelY + 40, 180, 32, "Copiar", Chr(#Icon_Copy))
  Protected G_Close = ThemedButton(ButtonsX, ToolPanelY + 80, 180, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")
  GadgetToolTip(G_Inject, "Gera o codigo BASIC (SCREEN 2 + Tabela de Cores dos 3 tercos, mais os carregadores de fonte custom) e injeta na aba de texto ativa")
  GadgetToolTip(G_Copy, "Gera o mesmo codigo e copia pra area de transferencia")

  ; --- Estado ---
  Dim GridBytes.a(#Scr1Ed_MaxCells - 1)
  Dim AlphaThirds.i(2)
  Dim CB0.a(255, 7)
  Dim CB1.a(255, 7)
  Dim CB2.a(255, 7)
  Dim ColorInk.a(2, 255, 7)
  Dim ColorPaper.a(2, 255, 7)
  Dim Palette.l(15)
  Dim PaletteNames.s(15)
  Dim ClipInk.i(7)
  Dim ClipPaper.i(7)
  SpriteEd_FillPalette(Palette(), PaletteNames())

  Protected NewList AlphaNums.i()
  ProjectDB::ListAlphabetNumbers(AlphaNums())
  ForEach AlphaNums()
    AddGadgetItem(G_FontCombo0, -1, "#" + Str(AlphaNums()))
    AddGadgetItem(G_FontCombo1, -1, "#" + Str(AlphaNums()))
    AddGadgetItem(G_FontCombo2, -1, "#" + Str(AlphaNums()))
  Next

  Protected ScreenNumber.i = 1
  Protected ScreenTag.s = ""
  Protected Dirty.b = #False
  Protected CurrentByte.i = 32
  Protected EditThird.i = 0
  Protected ClipValid.b = #False
  Protected BlockPicking.b = #False
  Protected BlockPickStart.i = -1
  Protected BlockPickAction.i = 0   ; 1 = abrir editor de cores (Cores em bloco...), 2 = resetar pra padrao (Resetar bloco...)
  Protected BlockHintStart.s = "Bloco: clique o codigo INICIAL na tabela ASCII abaixo (botao direito cancela)."
  Protected BlockHintEnd.s = "Bloco: clique o codigo FINAL (pode ser o mesmo, pra um so)."
  Protected BLo.i, BHi.i

  Protected ClearIdx, Th, Cd, Rw
  For ClearIdx = 0 To #Scr1Ed_MaxCells - 1
    GridBytes(ClearIdx) = 32
  Next
  For Th = 0 To 2
    AlphaThirds(Th) = -1
    For Cd = 0 To 255
      For Rw = 0 To 7
        ColorInk(Th, Cd, Rw) = 15
        ColorPaper(Th, Cd, Rw) = 1
      Next
    Next
  Next
  ProjectDB::FetchDefaultAlphabet(0, CB0())
  ProjectDB::FetchDefaultAlphabet(0, CB1())
  ProjectDB::FetchDefaultAlphabet(0, CB2())

  Protected NewList Nav.i()
  ProjectDB::ListScreen12Numbers(Nav())
  If ListSize(Nav()) > 0
    FirstElement(Nav())
    ScreenNumber = Nav()
    ProjectDB::FetchScreen12(ScreenNumber, AlphaThirds(), GridBytes(), ColorInk(), ColorPaper())
    ScreenTag = ProjectDB::LastScreen12Tag()
    If AlphaThirds(0) <> -1 : ProjectDB::FetchAlphabet(AlphaThirds(0), CB0()) : EndIf
    If AlphaThirds(1) <> -1 : ProjectDB::FetchAlphabet(AlphaThirds(1), CB1()) : EndIf
    If AlphaThirds(2) <> -1 : ProjectDB::FetchAlphabet(AlphaThirds(2), CB2()) : EndIf
  EndIf

  SetGadgetState(G_FontCombo0, Scr12Ed_ComboIndexFor(G_FontCombo0, AlphaThirds(0)))
  SetGadgetState(G_FontCombo1, Scr12Ed_ComboIndexFor(G_FontCombo1, AlphaThirds(1)))
  SetGadgetState(G_FontCombo2, Scr12Ed_ComboIndexFor(G_FontCombo2, AlphaThirds(2)))
  SetGadgetText(G_ScreenNumberText, "#" + Str(ScreenNumber))
  SetGadgetText(G_Tag, ScreenTag)
  SetGadgetText(G_ByteInfo, Scr12Ed_ByteInfoText(CurrentByte, EditThird))
  Scr12Ed_RedrawCanvas(G_Canvas, GridBytes(), CB0(), CB1(), CB2(), ColorInk(), ColorPaper(), Palette())
  Scr12Ed_DrawCharPicker(G_CharPicker, CB0(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)

  Protected Event, Quit = #False, MouseX, MouseY, Col, Row, NavTarget
  Protected MarkCol = -1, MarkRow = -1
  Protected LastPaintCol = -1, LastPaintRow = -1
  Protected ActiveTab

  Repeat
    Event = WaitWindowEvent()

    Select Event
      Case #PB_Event_Gadget
        ; Qualquer interacao com OUTRO gadget cancela uma escolha de bloco
        ; pendente (Cores em bloco.../Resetar bloco... esperando o 2o clique
        ; na tabela ASCII) - evita ficar com BlockPickStart "orfao" referente
        ; a um terco/byte que o usuario ja deixou pra tras clicando em outra
        ; coisa. G_CharPicker fica de fora pra nao cancelar o proprio clique
        ; que resolve a escolha.
        If BlockPicking And EventGadget() <> G_CharPicker
          BlockPicking = #False
          BlockPickStart = -1
          SetGadgetText(G_PickHint, PickHintDefault)
          Select EditThird
            Case 0 : Scr12Ed_DrawCharPicker(G_CharPicker, CB0(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
            Case 1 : Scr12Ed_DrawCharPicker(G_CharPicker, CB1(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
            Case 2 : Scr12Ed_DrawCharPicker(G_CharPicker, CB2(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
          EndSelect
        EndIf

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
                Protected TypedByte = Scr1Ed_GlyphByteFor(AsciiTxt)
                If TypedByte >= 0
                  CurrentByte = TypedByte
                  SetGadgetText(G_ByteInfo, Scr12Ed_ByteInfoText(CurrentByte, EditThird))
                  Select EditThird
                    Case 0 : Scr12Ed_DrawCharPicker(G_CharPicker, CB0(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                    Case 1 : Scr12Ed_DrawCharPicker(G_CharPicker, CB1(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                    Case 2 : Scr12Ed_DrawCharPicker(G_CharPicker, CB2(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                  EndSelect
                EndIf
              EndIf
            EndIf

          Case G_FontCombo0, G_FontCombo1, G_FontCombo2
            If EventType() = #PB_EventType_Change
              Protected ChangedThird, ComboSel
              Select EventGadget()
                Case G_FontCombo0 : ChangedThird = 0 : ComboSel = G_FontCombo0
                Case G_FontCombo1 : ChangedThird = 1 : ComboSel = G_FontCombo1
                Case G_FontCombo2 : ChangedThird = 2 : ComboSel = G_FontCombo2
              EndSelect
              Protected FontSel.s = GetGadgetText(ComboSel)
              If FontSel = "Padrao"
                AlphaThirds(ChangedThird) = -1
              Else
                AlphaThirds(ChangedThird) = Val(Mid(FontSel, 2))
              EndIf
              Select ChangedThird
                Case 0 : If AlphaThirds(0) = -1 : ProjectDB::FetchDefaultAlphabet(0, CB0()) : Else : ProjectDB::FetchAlphabet(AlphaThirds(0), CB0()) : EndIf
                Case 1 : If AlphaThirds(1) = -1 : ProjectDB::FetchDefaultAlphabet(0, CB1()) : Else : ProjectDB::FetchAlphabet(AlphaThirds(1), CB1()) : EndIf
                Case 2 : If AlphaThirds(2) = -1 : ProjectDB::FetchDefaultAlphabet(0, CB2()) : Else : ProjectDB::FetchAlphabet(AlphaThirds(2), CB2()) : EndIf
              EndSelect
              Dirty = #True
              Scr12Ed_RedrawCanvas(G_Canvas, GridBytes(), CB0(), CB1(), CB2(), ColorInk(), ColorPaper(), Palette())
              If EditThird = ChangedThird
                Select EditThird
                  Case 0 : Scr12Ed_DrawCharPicker(G_CharPicker, CB0(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                  Case 1 : Scr12Ed_DrawCharPicker(G_CharPicker, CB1(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                  Case 2 : Scr12Ed_DrawCharPicker(G_CharPicker, CB2(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                EndSelect
              EndIf
            EndIf

          Case G_Third0, G_Third1, G_Third2
            If EventType() = #PB_EventType_Change
              If GetGadgetState(G_Third0) : EditThird = 0
              ElseIf GetGadgetState(G_Third1) : EditThird = 1
              Else : EditThird = 2
              EndIf
              SetGadgetText(G_ByteInfo, Scr12Ed_ByteInfoText(CurrentByte, EditThird))
              Select EditThird
                Case 0 : Scr12Ed_DrawCharPicker(G_CharPicker, CB0(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                Case 1 : Scr12Ed_DrawCharPicker(G_CharPicker, CB1(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                Case 2 : Scr12Ed_DrawCharPicker(G_CharPicker, CB2(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
              EndSelect
            EndIf

          Case G_CharPicker
            If EventType() = #PB_EventType_LeftButtonDown Or EventType() = #PB_EventType_LeftDoubleClick
              MouseX = GetGadgetAttribute(G_CharPicker, #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(G_CharPicker, #PB_Canvas_MouseY)
              If MouseX >= 0 And MouseY >= 0
                Protected PickCol = MouseX / #Scr12Ed_CharPickCellPx, PickRow = MouseY / #Scr12Ed_CharPickCellPx
                Protected PickByte = PickRow * #Scr12Ed_CharPickCols + PickCol
                If PickByte >= 0 And PickByte <= 255
                  If BlockPicking
                    If BlockPickStart = -1
                      BlockPickStart = PickByte
                      SetGadgetText(G_PickHint, BlockHintEnd)
                      Select EditThird
                        Case 0 : Scr12Ed_DrawCharPicker(G_CharPicker, CB0(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte, BlockPickStart, BlockPickStart)
                        Case 1 : Scr12Ed_DrawCharPicker(G_CharPicker, CB1(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte, BlockPickStart, BlockPickStart)
                        Case 2 : Scr12Ed_DrawCharPicker(G_CharPicker, CB2(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte, BlockPickStart, BlockPickStart)
                      EndSelect
                    Else
                      If PickByte >= BlockPickStart
                        BLo = BlockPickStart : BHi = PickByte
                      Else
                        BLo = PickByte : BHi = BlockPickStart
                      EndIf
                      Select EditThird
                        Case 0 : Scr12Ed_DrawCharPicker(G_CharPicker, CB0(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte, BLo, BHi)
                        Case 1 : Scr12Ed_DrawCharPicker(G_CharPicker, CB1(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte, BLo, BHi)
                        Case 2 : Scr12Ed_DrawCharPicker(G_CharPicker, CB2(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte, BLo, BHi)
                      EndSelect

                      If BlockPickAction = 1
                        Scr12Ed_OpenColorEditorForThird(Win, CB0(), CB1(), CB2(), Palette(), EditThird, BLo, BHi, ColorInk(), ColorPaper())
                      Else
                        For Cd = BLo To BHi
                          For Rw = 0 To 7
                            ColorInk(EditThird, Cd, Rw) = 15
                            ColorPaper(EditThird, Cd, Rw) = 1
                          Next
                        Next
                      EndIf

                      Dirty = #True
                      BlockPicking = #False
                      BlockPickStart = -1
                      SetGadgetText(G_PickHint, PickHintDefault)
                      Scr12Ed_RedrawCanvas(G_Canvas, GridBytes(), CB0(), CB1(), CB2(), ColorInk(), ColorPaper(), Palette())
                      Select EditThird
                        Case 0 : Scr12Ed_DrawCharPicker(G_CharPicker, CB0(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                        Case 1 : Scr12Ed_DrawCharPicker(G_CharPicker, CB1(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                        Case 2 : Scr12Ed_DrawCharPicker(G_CharPicker, CB2(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                      EndSelect
                    EndIf
                  Else
                    CurrentByte = PickByte
                    SetGadgetText(G_AsciiChar, Scr1Ed_ByteToChar(CurrentByte))
                    SetGadgetText(G_ByteInfo, Scr12Ed_ByteInfoText(CurrentByte, EditThird))
                    Select EditThird
                      Case 0 : Scr12Ed_DrawCharPicker(G_CharPicker, CB0(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                      Case 1 : Scr12Ed_DrawCharPicker(G_CharPicker, CB1(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                      Case 2 : Scr12Ed_DrawCharPicker(G_CharPicker, CB2(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                    EndSelect
                  EndIf
                EndIf
              EndIf
            ElseIf EventType() = #PB_EventType_RightButtonDown And BlockPicking
              BlockPicking = #False
              BlockPickStart = -1
              SetGadgetText(G_PickHint, PickHintDefault)
              Select EditThird
                Case 0 : Scr12Ed_DrawCharPicker(G_CharPicker, CB0(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                Case 1 : Scr12Ed_DrawCharPicker(G_CharPicker, CB1(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                Case 2 : Scr12Ed_DrawCharPicker(G_CharPicker, CB2(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
              EndSelect
            EndIf

          Case G_CharColors
            Scr12Ed_OpenColorEditorForThird(Win, CB0(), CB1(), CB2(), Palette(), EditThird, CurrentByte, CurrentByte, ColorInk(), ColorPaper())
            Dirty = #True
            Scr12Ed_RedrawCanvas(G_Canvas, GridBytes(), CB0(), CB1(), CB2(), ColorInk(), ColorPaper(), Palette())
            Select EditThird
              Case 0 : Scr12Ed_DrawCharPicker(G_CharPicker, CB0(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
              Case 1 : Scr12Ed_DrawCharPicker(G_CharPicker, CB1(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
              Case 2 : Scr12Ed_DrawCharPicker(G_CharPicker, CB2(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
            EndSelect

          Case G_BlockColors
            BlockPicking = #True
            BlockPickStart = -1
            BlockPickAction = 1
            SetGadgetText(G_PickHint, BlockHintStart)
            Select EditThird
              Case 0 : Scr12Ed_DrawCharPicker(G_CharPicker, CB0(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
              Case 1 : Scr12Ed_DrawCharPicker(G_CharPicker, CB1(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
              Case 2 : Scr12Ed_DrawCharPicker(G_CharPicker, CB2(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
            EndSelect

          Case G_ResetChar
            For Rw = 0 To 7
              ColorInk(EditThird, CurrentByte, Rw) = 15
              ColorPaper(EditThird, CurrentByte, Rw) = 1
            Next
            Dirty = #True
            Scr12Ed_RedrawCanvas(G_Canvas, GridBytes(), CB0(), CB1(), CB2(), ColorInk(), ColorPaper(), Palette())
            Select EditThird
              Case 0 : Scr12Ed_DrawCharPicker(G_CharPicker, CB0(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
              Case 1 : Scr12Ed_DrawCharPicker(G_CharPicker, CB1(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
              Case 2 : Scr12Ed_DrawCharPicker(G_CharPicker, CB2(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
            EndSelect

          Case G_ResetBlock
            BlockPicking = #True
            BlockPickStart = -1
            BlockPickAction = 2
            SetGadgetText(G_PickHint, BlockHintStart)
            Select EditThird
              Case 0 : Scr12Ed_DrawCharPicker(G_CharPicker, CB0(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
              Case 1 : Scr12Ed_DrawCharPicker(G_CharPicker, CB1(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
              Case 2 : Scr12Ed_DrawCharPicker(G_CharPicker, CB2(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
            EndSelect

          Case G_ResetAll
            If MessageRequester("Resetar cores",
                 "Resetar as cores dos 256 codigos do Terco " + Str(EditThird + 1) + " para fundo preto / letra branca?" + Chr(10) + "Isso nao pode ser desfeito.",
                 #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes
              For Cd = 0 To 255
                For Rw = 0 To 7
                  ColorInk(EditThird, Cd, Rw) = 15
                  ColorPaper(EditThird, Cd, Rw) = 1
                Next
              Next
              Dirty = #True
              Scr12Ed_RedrawCanvas(G_Canvas, GridBytes(), CB0(), CB1(), CB2(), ColorInk(), ColorPaper(), Palette())
              Select EditThird
                Case 0 : Scr12Ed_DrawCharPicker(G_CharPicker, CB0(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                Case 1 : Scr12Ed_DrawCharPicker(G_CharPicker, CB1(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                Case 2 : Scr12Ed_DrawCharPicker(G_CharPicker, CB2(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
              EndSelect
            EndIf

          Case G_CopyColors
            For Rw = 0 To 7
              ClipInk(Rw) = ColorInk(EditThird, CurrentByte, Rw)
              ClipPaper(Rw) = ColorPaper(EditThird, CurrentByte, Rw)
            Next
            ClipValid = #True

          Case G_PasteColors
            If Not ClipValid
              MessageRequester("Nada copiado", "Use 'Copiar cores' num caractere antes de colar.",
                               #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
            Else
              For Rw = 0 To 7
                ColorInk(EditThird, CurrentByte, Rw) = ClipInk(Rw)
                ColorPaper(EditThird, CurrentByte, Rw) = ClipPaper(Rw)
              Next
              Dirty = #True
              Scr12Ed_RedrawCanvas(G_Canvas, GridBytes(), CB0(), CB1(), CB2(), ColorInk(), ColorPaper(), Palette())
              Select EditThird
                Case 0 : Scr12Ed_DrawCharPicker(G_CharPicker, CB0(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                Case 1 : Scr12Ed_DrawCharPicker(G_CharPicker, CB1(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
                Case 2 : Scr12Ed_DrawCharPicker(G_CharPicker, CB2(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
              EndSelect
            EndIf

          Case G_Canvas
            ActiveTab = GetGadgetState(G_Panel)

            Select EventType()
              Case #PB_EventType_LeftButtonDown
                MouseX = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseX)
                MouseY = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseY)
                If MouseX >= 0 And MouseY >= 0
                  Col = MouseX / (8 * Zoom)
                  Row = MouseY / (8 * Zoom)
                  If Col >= 0 And Col < #Scr1Ed_Cols And Row >= 0 And Row < #Scr1Ed_Rows
                    Scr12Ed_SyncEditThirdToRow(Row, @EditThird, G_Third0, G_Third1, G_Third2, G_ByteInfo, G_CharPicker, CB0(), CB1(), CB2(), ColorInk(), ColorPaper(), Palette(), CurrentByte)
                    Select ActiveTab
                      Case #Scr1Ed_Tool_Text
                        Scr1Ed_StampText(GridBytes(), Col, Row, GetGadgetText(G_TextInput))
                        Dirty = #True

                      Case #Scr1Ed_Tool_Char
                        GridBytes(Row * #Scr1Ed_Cols + Col) = CurrentByte
                        LastPaintCol = Col : LastPaintRow = Row
                        Dirty = #True

                      Case #Scr1Ed_Tool_Box
                        If MarkCol = -1
                          MarkCol = Col : MarkRow = Row
                        Else
                          Scr1Ed_DrawBox(GridBytes(), MarkCol, MarkRow, Col, Row)
                          MarkCol = -1 : MarkRow = -1
                          Dirty = #True
                        EndIf

                      Case #Scr1Ed_Tool_Shadow
                        If MarkCol = -1
                          MarkCol = Col : MarkRow = Row
                        Else
                          Scr1Ed_ApplyShadow(GridBytes(), MarkCol, MarkRow, Col, Row)
                          MarkCol = -1 : MarkRow = -1
                          Dirty = #True
                        EndIf

                      Case #Scr1Ed_Tool_Fill
                        If MarkCol = -1
                          MarkCol = Col : MarkRow = Row
                        Else
                          Scr1Ed_FillRect(GridBytes(), MarkCol, MarkRow, Col, Row, CurrentByte)
                          MarkCol = -1 : MarkRow = -1
                          Dirty = #True
                        EndIf

                      Case #Scr1Ed_Tool_Erase
                        GridBytes(Row * #Scr1Ed_Cols + Col) = 32
                        LastPaintCol = Col : LastPaintRow = Row
                        Dirty = #True
                    EndSelect
                    Scr12Ed_RedrawCanvas(G_Canvas, GridBytes(), CB0(), CB1(), CB2(), ColorInk(), ColorPaper(), Palette(), MarkCol, MarkRow)
                  EndIf
                EndIf

              Case #PB_EventType_RightButtonDown
                If MarkCol <> -1
                  MarkCol = -1 : MarkRow = -1
                  Scr12Ed_RedrawCanvas(G_Canvas, GridBytes(), CB0(), CB1(), CB2(), ColorInk(), ColorPaper(), Palette())
                EndIf

              Case #PB_EventType_MouseMove
                If (ActiveTab = #Scr1Ed_Tool_Char Or ActiveTab = #Scr1Ed_Tool_Erase) And
                   (GetGadgetAttribute(G_Canvas, #PB_Canvas_Buttons) & #PB_Canvas_LeftButton)
                  MouseX = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseX)
                  MouseY = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseY)
                  Col = MouseX / (8 * Zoom)
                  Row = MouseY / (8 * Zoom)
                  If Col >= 0 And Col < #Scr1Ed_Cols And Row >= 0 And Row < #Scr1Ed_Rows And (Col <> LastPaintCol Or Row <> LastPaintRow)
                    Scr12Ed_SyncEditThirdToRow(Row, @EditThird, G_Third0, G_Third1, G_Third2, G_ByteInfo, G_CharPicker, CB0(), CB1(), CB2(), ColorInk(), ColorPaper(), Palette(), CurrentByte)
                    If ActiveTab = #Scr1Ed_Tool_Char
                      GridBytes(Row * #Scr1Ed_Cols + Col) = CurrentByte
                    Else
                      GridBytes(Row * #Scr1Ed_Cols + Col) = 32
                    EndIf
                    LastPaintCol = Col : LastPaintRow = Row
                    Dirty = #True
                    Scr12Ed_RedrawCanvas(G_Canvas, GridBytes(), CB0(), CB1(), CB2(), ColorInk(), ColorPaper(), Palette())
                  EndIf
                EndIf
            EndSelect

          Case G_New
            If Not Dirty Or Scr12Ed_ConfirmDiscard()
              ProjectDB::ListScreen12Numbers(Nav())
              If ListSize(Nav()) > 0
                LastElement(Nav())
                ScreenNumber = Nav() + 1
              Else
                ScreenNumber = 1
              EndIf
              CurrentByte = 32
              EditThird = 0
              ClipValid = #False
              For ClearIdx = 0 To #Scr1Ed_MaxCells - 1
                GridBytes(ClearIdx) = 32
              Next
              For Th = 0 To 2
                AlphaThirds(Th) = -1
                For Cd = 0 To 255
                  For Rw = 0 To 7
                    ColorInk(Th, Cd, Rw) = 15
                    ColorPaper(Th, Cd, Rw) = 1
                  Next
                Next
              Next
              ProjectDB::FetchDefaultAlphabet(0, CB0())
              ProjectDB::FetchDefaultAlphabet(0, CB1())
              ProjectDB::FetchDefaultAlphabet(0, CB2())
              SetGadgetState(G_FontCombo0, 0)
              SetGadgetState(G_FontCombo1, 0)
              SetGadgetState(G_FontCombo2, 0)
              SetGadgetState(G_Third0, #True)
              MarkCol = -1 : MarkRow = -1
              Dirty = #False
              SetGadgetText(G_ScreenNumberText, "#" + Str(ScreenNumber))
              SetGadgetText(G_Tag, "")
              SetGadgetText(G_ByteInfo, Scr12Ed_ByteInfoText(CurrentByte, EditThird))
              Scr12Ed_RedrawCanvas(G_Canvas, GridBytes(), CB0(), CB1(), CB2(), ColorInk(), ColorPaper(), Palette())
              Scr12Ed_DrawCharPicker(G_CharPicker, CB0(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
            EndIf

          Case G_Register
            ProjectDB::StoreScreen12(ScreenNumber, GetGadgetText(G_Tag), AlphaThirds(), GridBytes(), ColorInk(), ColorPaper())
            Dirty = #False

          Case G_First, G_Prev, G_Next, G_Last
            If Not Dirty Or Scr12Ed_ConfirmDiscard()
              ProjectDB::ListScreen12Numbers(Nav())
              Select EventGadget()
                Case G_First : NavTarget = SpriteEd_FindNavTarget(Nav(), 0, ScreenNumber)
                Case G_Prev  : NavTarget = SpriteEd_FindNavTarget(Nav(), 1, ScreenNumber)
                Case G_Next  : NavTarget = SpriteEd_FindNavTarget(Nav(), 2, ScreenNumber)
                Case G_Last  : NavTarget = SpriteEd_FindNavTarget(Nav(), 3, ScreenNumber)
              EndSelect
              If NavTarget >= 0
                ScreenNumber = NavTarget
                ProjectDB::FetchScreen12(ScreenNumber, AlphaThirds(), GridBytes(), ColorInk(), ColorPaper())
                If AlphaThirds(0) = -1 : ProjectDB::FetchDefaultAlphabet(0, CB0()) : Else : ProjectDB::FetchAlphabet(AlphaThirds(0), CB0()) : EndIf
                If AlphaThirds(1) = -1 : ProjectDB::FetchDefaultAlphabet(0, CB1()) : Else : ProjectDB::FetchAlphabet(AlphaThirds(1), CB1()) : EndIf
                If AlphaThirds(2) = -1 : ProjectDB::FetchDefaultAlphabet(0, CB2()) : Else : ProjectDB::FetchAlphabet(AlphaThirds(2), CB2()) : EndIf
                SetGadgetState(G_FontCombo0, Scr12Ed_ComboIndexFor(G_FontCombo0, AlphaThirds(0)))
                SetGadgetState(G_FontCombo1, Scr12Ed_ComboIndexFor(G_FontCombo1, AlphaThirds(1)))
                SetGadgetState(G_FontCombo2, Scr12Ed_ComboIndexFor(G_FontCombo2, AlphaThirds(2)))
                CurrentByte = 32
                EditThird = 0
                ClipValid = #False
                SetGadgetState(G_Third0, #True)
                MarkCol = -1 : MarkRow = -1 : Dirty = #False
                SetGadgetText(G_ScreenNumberText, "#" + Str(ScreenNumber))
                SetGadgetText(G_Tag, ProjectDB::LastScreen12Tag())
                SetGadgetText(G_ByteInfo, Scr12Ed_ByteInfoText(CurrentByte, EditThird))
                Scr12Ed_RedrawCanvas(G_Canvas, GridBytes(), CB0(), CB1(), CB2(), ColorInk(), ColorPaper(), Palette())
                Scr12Ed_DrawCharPicker(G_CharPicker, CB0(), ColorInk(), ColorPaper(), Palette(), EditThird, CurrentByte)
              EndIf
            EndIf

          Case G_Inject
            If Not InjectTextAtCursor(Scr12Ed_BuildCode(GridBytes(), AlphaThirds(), ColorInk(), ColorPaper(), CB0(), CB1(), CB2()))
              MessageRequester("Erro", "Nenhuma aba de texto ativa para injetar o codigo.",
                               #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
            EndIf

          Case G_Copy
            SetClipboardText(Scr12Ed_BuildCode(GridBytes(), AlphaThirds(), ColorInk(), ColorPaper(), CB0(), CB1(), CB2()))

          Case G_Close
            Quit = #True

        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
