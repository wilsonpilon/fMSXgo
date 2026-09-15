;
; ------------------------------------------------------------
;  Apelido interno: Pixelossauro (tema pre-historico do projeto, ver README.md)
;  Criar -> Draw Screen 2...: editor grafico SCREEN 2 (modulo 5) - desenha
;  direto numa tela 256x192 (zoom 2x = 512x384 no canvas) via PSET/PRESET/
;  LINE/CIRCLE/PAINT/DRAW/TEXTO, com paleta MSX1 e simulacao real do color
;  clash (ver editor/Screen2Synth.pbi, o motor sem GUI por tras desta
;  janela - PatternBit/RowFG/RowBG, Scr2_SetPixel/DrawLine/DrawCircle/
;  FloodFill/ExecuteDraw). A janela mantem uma LISTA DE COMANDOS (nao o
;  framebuffer como fonte de verdade) e reconstroi a tela do zero a cada
;  mudanca via Scr2Ed_ReplayAllWithText() - mesmo espirito "replay" das
;  listas de passos/linhas do editor de som PSG/musica MML
;  (PsgEditorGui.pbi/MmlEditorGui.pbi), que tambem inspiraram a barra de
;  projeto e os botoes Adicionar/Remover/Mover daqui.
;
;  TEXTO usa um alfabeto do banco do projeto (Criar -> Alfabeto Graphos
;  III...), escolhido por terco da tela (0/1/2 = Pattern/Color Table de
;  2048 bytes cada) - o glifo de cada caractere e blitado pixel a pixel
;  (mesma faixa/clash de qualquer outro desenho) pra previa no canvas, e
;  "Gerar codigo" emite o carregador de verdade (DATA + VPOKE na Pattern/
;  Color Table do terco + LOCATE/PRINT) - ver Scr2Ed_GenAlphabetLoader.
; ------------------------------------------------------------
;

#Scr2Ed_Zoom     = 2
#Scr2Ed_CanvasW  = #Scr2_Width * #Scr2Ed_Zoom   ; 512
#Scr2Ed_CanvasH  = #Scr2_Height * #Scr2Ed_Zoom  ; 384

#Scr2Ed_PaletteSwatch = 18
#Scr2Ed_PaletteCols   = 4
#Scr2Ed_PaletteRows   = 4
#Scr2Ed_PaletteSize   = #Scr2Ed_PaletteSwatch * #Scr2Ed_PaletteCols ; 72

; Converte coordenadas de mouse (relativas ao canvas de uma mini-paleta
; #Scr2Ed_PaletteRows x #Scr2Ed_PaletteCols) no indice de cor 0-15 clicado,
; ou -1 se fora da grade - usado por todos os editores de tela (Screen0/1/2/
; 12) que tem paleta de tinta/papel, evitando repetir a mesma formula +
; checagem de faixa em cada um.
Procedure.i Scr2Ed_PaletteHitTest(MouseX.i, MouseY.i)
  If MouseX < 0 Or MouseY < 0
    ProcedureReturn -1
  EndIf
  Protected Idx = (MouseY / #Scr2Ed_PaletteSwatch) * #Scr2Ed_PaletteCols + (MouseX / #Scr2Ed_PaletteSwatch)
  If Idx < 0 Or Idx > 15
    ProcedureReturn -1
  EndIf
  ProcedureReturn Idx
EndProcedure

; Cores nomeadas/paleta MSX1 identicas as do editor de sprites - reaproveita
; SpriteEd_FillPalette (editor/SpriteEditorGui.pbi) em vez de duplicar os
; 16 RGB() literais.
Procedure Scr2Ed_RedrawMiniPalette(Canvas, Selected.i, Array Palette.l(1))
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Box(0, 0, #Scr2Ed_PaletteSize, #Scr2Ed_PaletteSize, RGB(255, 255, 255))
  Protected Row, Col, Idx, CellX, CellY
  For Row = 0 To #Scr2Ed_PaletteRows - 1
    For Col = 0 To #Scr2Ed_PaletteCols - 1
      Idx = Row * #Scr2Ed_PaletteCols + Col
      CellX = Col * #Scr2Ed_PaletteSwatch
      CellY = Row * #Scr2Ed_PaletteSwatch
      Box(CellX + 1, CellY + 1, #Scr2Ed_PaletteSwatch - 2, #Scr2Ed_PaletteSwatch - 2, Palette(Idx))
      If Idx = Selected
        DrawingMode(#PB_2DDrawing_Outlined)
        Box(CellX, CellY, #Scr2Ed_PaletteSwatch, #Scr2Ed_PaletteSwatch, RGB(205, 40, 40))
        Box(CellX + 1, CellY + 1, #Scr2Ed_PaletteSwatch - 2, #Scr2Ed_PaletteSwatch - 2, RGB(205, 40, 40))
        DrawingMode(#PB_2DDrawing_Default)
      EndIf
    Next
  Next
  StopDrawing()
EndProcedure

; Redesenha o canvas inteiro a partir do framebuffer (PatternBit/RowFG/
; RowBG) - por faixas horizontais de cor igual (nao pixel a pixel), pra
; nao precisar de milhares de chamadas Box() numa tela 256x192.
Procedure Scr2Ed_RedrawCanvas(Canvas, Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), Array Palette.l(1))
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  ; Le PatternBit/RowFG/RowBG direto (em vez de Scr2_GetPixelColor) - os
  ; limites dos loops abaixo ja garantem X/Y validos, entao a checagem de
  ; fronteira e a chamada de procedure daquela funcao (necessarias pro uso
  ; geral dela, consulta de pixel avulso) sao custo puro aqui: esta e a
  ; chamada mais quente de todo o Graphos/Screen2 (todo mouse-move durante
  ; arraste de ferramenta redesenha a tela inteira via
  ; GraphosScr_RedrawCanvasFull -> aqui).
  Protected Y, X, RunStart, RunColor, C
  For Y = 0 To #Scr2_Height - 1
    RunStart = 0
    If PatternBit(Y, 0) : RunColor = RowFG(Y, 0) : Else : RunColor = RowBG(Y, 0) : EndIf
    For X = 1 To #Scr2_Width - 1
      If PatternBit(Y, X) : C = RowFG(Y, X / 8) : Else : C = RowBG(Y, X / 8) : EndIf
      If C <> RunColor
        Box(RunStart * #Scr2Ed_Zoom, Y * #Scr2Ed_Zoom, (X - RunStart) * #Scr2Ed_Zoom, #Scr2Ed_Zoom, Palette(RunColor))
        RunStart = X
        RunColor = C
      EndIf
    Next
    Box(RunStart * #Scr2Ed_Zoom, Y * #Scr2Ed_Zoom, (#Scr2_Width - RunStart) * #Scr2Ed_Zoom, #Scr2Ed_Zoom, Palette(RunColor))
  Next
  StopDrawing()
EndProcedure

Global Scr2Ed_PreviewColor.l = RGB(255, 255, 0) ; amarelo - contrasta com qualquer cor da paleta MSX1
Global Scr2Ed_AnchorColor.l  = RGB(255, 0, 0)   ; vermelho - marcador do ponto inicial

; "Linha elastica" da ferramenta LINE - desenhada POR CIMA do canvas ja
; redesenhado (Scr2Ed_RedrawCanvas), numa segunda passada de StartDrawing
; separada, sem tocar no framebuffer real (so um guia visual enquanto o
; usuario ainda nao deu o segundo clique) - mesmo espirito de
; SpriteEd_DrawPreviewOverlay (editor/SpriteEditorGui.pbi). BoxMode segue
; o mesmo significado de Scr2_LineStatement (0=reta, 1/2=caixa).
Procedure Scr2Ed_DrawLinePreview(Canvas, AnchorX.i, AnchorY.i, CurX.i, CurY.i, BoxMode.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected SX = AnchorX * #Scr2Ed_Zoom, SY = AnchorY * #Scr2Ed_Zoom
  Protected EX = CurX * #Scr2Ed_Zoom, EY = CurY * #Scr2Ed_Zoom
  If BoxMode = 0
    LineXY(SX, SY, EX, EY, Scr2Ed_PreviewColor)
  Else
    Protected MinX, MaxX, MinY, MaxY
    MinX = SX : MaxX = EX : If MinX > MaxX : Swap MinX, MaxX : EndIf
    MinY = SY : MaxY = EY : If MinY > MaxY : Swap MinY, MaxY : EndIf
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(MinX, MinY, MaxX - MinX + #Scr2Ed_Zoom, MaxY - MinY + #Scr2Ed_Zoom, Scr2Ed_PreviewColor)
    DrawingMode(#PB_2DDrawing_Default)
  EndIf
  DrawingMode(#PB_2DDrawing_Outlined)
  Circle(SX, SY, 5, Scr2Ed_AnchorColor)
  DrawingMode(#PB_2DDrawing_Default)
  StopDrawing()
EndProcedure

; "Linha elastica" da ferramenta CIRCLE - Circulo: circunferencia com raio
; = distancia ate o mouse. Elipse: ajustada ao retangulo entre os dois
; pontos (os "cantos do quadro" citados no texto de ajuda da aba).
Procedure Scr2Ed_DrawCirclePreview(Canvas, AnchorX.i, AnchorY.i, CurX.i, CurY.i, IsEllipse.b)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected SX = AnchorX * #Scr2Ed_Zoom, SY = AnchorY * #Scr2Ed_Zoom
  Protected EX = CurX * #Scr2Ed_Zoom, EY = CurY * #Scr2Ed_Zoom
  DrawingMode(#PB_2DDrawing_Outlined)
  If IsEllipse
    Protected MinX, MaxX, MinY, MaxY
    MinX = SX : MaxX = EX : If MinX > MaxX : Swap MinX, MaxX : EndIf
    MinY = SY : MaxY = EY : If MinY > MaxY : Swap MinY, MaxY : EndIf
    Protected ERx = (MaxX - MinX) / 2, ERy = (MaxY - MinY) / 2
    If ERx < 1 : ERx = 1 : EndIf
    If ERy < 1 : ERy = 1 : EndIf
    Ellipse((MinX + MaxX) / 2, (MinY + MaxY) / 2, ERx, ERy, Scr2Ed_PreviewColor)
  Else
    Protected.f DX = EX - SX, DY = EY - SY
    Protected CR = Sqr(DX * DX + DY * DY)
    If CR < 1 : CR = 1 : EndIf
    Circle(SX, SY, CR, Scr2Ed_PreviewColor)
  EndIf
  Circle(SX, SY, 5, Scr2Ed_AnchorColor)
  DrawingMode(#PB_2DDrawing_Default)
  StopDrawing()
EndProcedure

; "Quadro elastico" da ferramenta TEXTO - ao contrario da previa de
; LINE/CIRCLE (so um contorno), aqui desenha o texto DE VERDADE (os bits
; reais do alfabeto escolhido, nas cores Tinta/Fundo escolhidas) seguindo o
; mouse, mais uma borda pontilhada delimitando o quadro - assim o usuario
; ve exatamente como o texto vai ficar antes de fixar com o clique. Nao
; toca no framebuffer real (mesma logica de Scr2Ed_DrawLinePreview).
Procedure Scr2Ed_DrawTextPreview(Canvas, Array CharsetBytes.a(2), TextStr.s, BaseX.i, BaseY.i, InkColor.l, PaperColor.l)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected i, Code, Row, Col, ByteVal.a, CX, CY
  For i = 1 To Len(TextStr)
    Code = Asc(Mid(TextStr, i, 1))
    If Code >= 0 And Code <= 255
      For Row = 0 To 7
        ByteVal = CharsetBytes(Code, Row)
        For Col = 0 To 7
          CX = (BaseX + (i - 1) * 8 + Col) * #Scr2Ed_Zoom
          CY = (BaseY + Row) * #Scr2Ed_Zoom
          If ByteVal & (1 << (7 - Col))
            Box(CX, CY, #Scr2Ed_Zoom, #Scr2Ed_Zoom, InkColor)
          Else
            Box(CX, CY, #Scr2Ed_Zoom, #Scr2Ed_Zoom, PaperColor)
          EndIf
        Next
      Next
    EndIf
  Next
  Protected TextW = Len(TextStr) * 8 * #Scr2Ed_Zoom, TextH = 8 * #Scr2Ed_Zoom
  DrawingMode(#PB_2DDrawing_Outlined)
  Box(BaseX * #Scr2Ed_Zoom, BaseY * #Scr2Ed_Zoom, TextW, TextH, Scr2Ed_AnchorColor)
  DrawingMode(#PB_2DDrawing_Default)
  StopDrawing()
EndProcedure

; Um resumo de uma linha por comando, pra lista da janela (ListIconGadget)
; - nao o codigo BASIC final (isso e Scr2_GenBasicLines), so uma legenda
; curta pro usuario reconhecer cada item da lista.
Procedure.s Scr2Ed_CommandSummary(*Cmd.Scr2_Command)
  Select *Cmd\CmdType
    Case #Scr2_Cmd_Pset
      ProcedureReturn "PSET " + Scr2_GenPointStr(*Cmd\X1, *Cmd\Y1, *Cmd\StepP1) + " cor " + Str(*Cmd\Color1)
    Case #Scr2_Cmd_Preset
      ProcedureReturn "PRESET " + Scr2_GenPointStr(*Cmd\X1, *Cmd\Y1, *Cmd\StepP1) + " cor " + Str(*Cmd\Color1)
    Case #Scr2_Cmd_Line
      Protected ModeTxt.s = ""
      If *Cmd\BoxMode = 1 : ModeTxt = " [caixa]" : ElseIf *Cmd\BoxMode = 2 : ModeTxt = " [caixa cheia]" : EndIf
      Protected P1Txt.s
      If *Cmd\LineNoStart
        P1Txt = ""
      Else
        P1Txt = Scr2_GenPointStr(*Cmd\X1, *Cmd\Y1, *Cmd\StepP1) + "-"
      EndIf
      ProcedureReturn "LINE " + P1Txt + Scr2_GenPointStr(*Cmd\X2, *Cmd\Y2, *Cmd\StepP2) + " cor " + Str(*Cmd\Color1) + ModeTxt
    Case #Scr2_Cmd_Circle
      ProcedureReturn "CIRCLE " + Scr2_GenPointStr(*Cmd\X1, *Cmd\Y1, *Cmd\StepP1) + " r=" + Str(*Cmd\Radius) + " cor " + Str(*Cmd\Color1)
    Case #Scr2_Cmd_Paint
      ProcedureReturn "PAINT " + Scr2_GenPointStr(*Cmd\X1, *Cmd\Y1, *Cmd\StepP1) + " cor " + Str(*Cmd\Color1)
    Case #Scr2_Cmd_Draw
      ProcedureReturn "DRAW " + Chr(34) + *Cmd\DrawString + Chr(34)
    Case #Scr2_Cmd_Text
      ProcedureReturn "TEXTO (" + Str(*Cmd\X1) + "," + Str(*Cmd\Y1) + ") " + Chr(34) + *Cmd\TextStr + Chr(34)
  EndSelect
  ProcedureReturn "?"
EndProcedure

; Reconstroi a ListIconGadget inteira a partir da lista de comandos -
; chamado toda vez que a lista muda (Adicionar/Remover/Mover/Colar).
Procedure Scr2Ed_RefreshCommandList(ListGadget, List Commands.Scr2_Command(), SelectedIdx.i)
  ClearGadgetItems(ListGadget)
  Protected Idx = 0
  ForEach Commands()
    AddGadgetItem(ListGadget, -1, Scr2Ed_CommandSummary(@Commands()))
    Idx + 1
  Next
  If SelectedIdx >= 0 And SelectedIdx < Idx
    SetGadgetState(ListGadget, SelectedIdx)
  EndIf
EndProcedure

; "Mini buffer" de uma ferramenta - mesma ideia da lista principal, so que
; filtrada por tipo de comando (um por aba PSET/PRESET/LINE/CIRCLE), pra
; nao precisar catar entre todos os comandos da tela pra achar/apagar o
; ultimo clique feito naquela ferramenta. Cada linha guarda, via
; SetGadgetItemData, a posicao REAL do comando na lista principal
; Commands() (0-based) - e o que permite Scr2Ed_RemoveFromMiniList() achar
; e apagar o comando certo mesmo com a lista filtrada.
Procedure Scr2Ed_RefreshMiniList(ListGadget, List Commands.Scr2_Command(), FilterType.i)
  ClearGadgetItems(ListGadget)
  Protected Pos = 0, RowIdx = 0
  ForEach Commands()
    If Commands()\CmdType = FilterType
      AddGadgetItem(ListGadget, -1, Scr2Ed_CommandSummary(@Commands()))
      SetGadgetItemData(ListGadget, RowIdx, Pos)
      RowIdx + 1
    EndIf
    Pos + 1
  Next
EndProcedure

; Apaga, da lista PRINCIPAL Commands(), o comando correspondente a linha
; selecionada num mini buffer - le a posicao real gravada por
; Scr2Ed_RefreshMiniList() acima. Devolve #False se nada estava
; selecionado (chamador decide se mostra aviso ou so ignora).
Procedure.b Scr2Ed_RemoveFromMiniList(ListGadget, List Commands.Scr2_Command())
  Protected Sel = GetGadgetState(ListGadget)
  If Sel < 0
    ProcedureReturn #False
  EndIf
  Protected Pos = GetGadgetItemData(ListGadget, Sel)
  SelectElement(Commands(), Pos)
  DeleteElement(Commands())
  ProcedureReturn #True
EndProcedure

; --------- serializacao pra ProjectDB (um comando por linha, campos "|") ---------
; O motor (Screen2Synth.pbi) nao conhece este formato de texto - so a
; Structure Scr2_Command em memoria. ProjectDB::StoreScreen/FetchScreen
; tratam o texto como blob opaco (ver comentario em ProjectDB.pbi).

Procedure.s Scr2Ed_SerializeCommands(List Commands.Scr2_Command())
  Protected Result.s = ""
  ForEach Commands()
    Select Commands()\CmdType
      Case #Scr2_Cmd_Pset
        Result + "PSET|" + Str(Commands()\X1) + "|" + Str(Commands()\Y1) + "|" + Str(Commands()\Color1) + "|" + Str(Commands()\StepP1)
      Case #Scr2_Cmd_Preset
        Result + "PRESET|" + Str(Commands()\X1) + "|" + Str(Commands()\Y1) + "|" + Str(Commands()\Color1) + "|" + Str(Commands()\StepP1)
      Case #Scr2_Cmd_Line
        Result + "LINE|" + Str(Commands()\X1) + "|" + Str(Commands()\Y1) + "|" + Str(Commands()\X2) + "|" + Str(Commands()\Y2) + "|" + Str(Commands()\Color1) + "|" + Str(Commands()\BoxMode) + "|" +
                 Str(Commands()\StepP1) + "|" + Str(Commands()\StepP2) + "|" + Str(Commands()\LineNoStart)
      Case #Scr2_Cmd_Circle
        Result + "CIRCLE|" + Str(Commands()\X1) + "|" + Str(Commands()\Y1) + "|" + Str(Commands()\Radius) + "|" + Str(Commands()\Color1) + "|" +
                 StrF(Commands()\StartDeg, 2) + "|" + StrF(Commands()\EndDeg, 2) + "|" + StrF(Commands()\Aspect, 4) + "|" +
                 Str(Commands()\PieStart) + "|" + Str(Commands()\PieEnd) + "|" + Str(Commands()\StepP1)
      Case #Scr2_Cmd_Paint
        Result + "PAINT|" + Str(Commands()\X1) + "|" + Str(Commands()\Y1) + "|" + Str(Commands()\Color1) + "|" + Str(Commands()\Color2) + "|" + Str(Commands()\StepP1)
      Case #Scr2_Cmd_Draw
        Result + "DRAW|" + Str(Commands()\X1) + "|" + Str(Commands()\Y1) + "|" + Str(Commands()\Color1) + "|" + Commands()\DrawString
      Case #Scr2_Cmd_Text
        Result + "TEXT|" + Str(Commands()\X1) + "|" + Str(Commands()\Y1) + "|" + Str(Commands()\AlphaNum) + "|" +
                 Str(Commands()\Color1) + "|" + Str(Commands()\Color2) + "|" + Commands()\TextStr
    EndSelect
    Result + Chr(10)
  Next
  ProcedureReturn Result
EndProcedure

Procedure Scr2Ed_DeserializeCommands(Text.s, List Commands.Scr2_Command())
  ClearList(Commands())
  Protected NumLines = CountString(Text, Chr(10)) + 1
  Protected i, LineText.s, CmdName.s
  For i = 1 To NumLines
    LineText = StringField(Text, i, Chr(10))
    If Trim(LineText) <> ""
      CmdName = StringField(LineText, 1, "|")
      AddElement(Commands())
      Select CmdName
        Case "PSET"
          Commands()\CmdType = #Scr2_Cmd_Pset
          Commands()\X1 = Val(StringField(LineText, 2, "|"))
          Commands()\Y1 = Val(StringField(LineText, 3, "|"))
          Commands()\Color1 = Val(StringField(LineText, 4, "|"))
          Commands()\StepP1 = Val(StringField(LineText, 5, "|"))
        Case "PRESET"
          Commands()\CmdType = #Scr2_Cmd_Preset
          Commands()\X1 = Val(StringField(LineText, 2, "|"))
          Commands()\Y1 = Val(StringField(LineText, 3, "|"))
          Commands()\Color1 = Val(StringField(LineText, 4, "|"))
          Commands()\StepP1 = Val(StringField(LineText, 5, "|"))
        Case "LINE"
          Commands()\CmdType = #Scr2_Cmd_Line
          Commands()\X1 = Val(StringField(LineText, 2, "|"))
          Commands()\Y1 = Val(StringField(LineText, 3, "|"))
          Commands()\X2 = Val(StringField(LineText, 4, "|"))
          Commands()\Y2 = Val(StringField(LineText, 5, "|"))
          Commands()\Color1 = Val(StringField(LineText, 6, "|"))
          Commands()\BoxMode = Val(StringField(LineText, 7, "|"))
          Commands()\StepP1 = Val(StringField(LineText, 8, "|"))
          Commands()\StepP2 = Val(StringField(LineText, 9, "|"))
          Commands()\LineNoStart = Val(StringField(LineText, 10, "|"))
        Case "CIRCLE"
          Commands()\CmdType = #Scr2_Cmd_Circle
          Commands()\X1 = Val(StringField(LineText, 2, "|"))
          Commands()\Y1 = Val(StringField(LineText, 3, "|"))
          Commands()\Radius = Val(StringField(LineText, 4, "|"))
          Commands()\Color1 = Val(StringField(LineText, 5, "|"))
          Commands()\StartDeg = ValF(StringField(LineText, 6, "|"))
          Commands()\EndDeg = ValF(StringField(LineText, 7, "|"))
          Commands()\Aspect = ValF(StringField(LineText, 8, "|"))
          Commands()\PieStart = Val(StringField(LineText, 9, "|"))
          Commands()\PieEnd = Val(StringField(LineText, 10, "|"))
          Commands()\StepP1 = Val(StringField(LineText, 11, "|"))
        Case "PAINT"
          Commands()\CmdType = #Scr2_Cmd_Paint
          Commands()\X1 = Val(StringField(LineText, 2, "|"))
          Commands()\Y1 = Val(StringField(LineText, 3, "|"))
          Commands()\Color1 = Val(StringField(LineText, 4, "|"))
          Commands()\Color2 = Val(StringField(LineText, 5, "|"))
          Commands()\StepP1 = Val(StringField(LineText, 6, "|"))
        Case "DRAW"
          Commands()\CmdType = #Scr2_Cmd_Draw
          Commands()\X1 = Val(StringField(LineText, 2, "|"))
          Commands()\Y1 = Val(StringField(LineText, 3, "|"))
          Commands()\Color1 = Val(StringField(LineText, 4, "|"))
          Commands()\DrawString = StringField(LineText, 5, "|")
        Case "TEXT"
          Commands()\CmdType = #Scr2_Cmd_Text
          Commands()\X1 = Val(StringField(LineText, 2, "|"))
          Commands()\Y1 = Val(StringField(LineText, 3, "|"))
          Commands()\AlphaNum = Val(StringField(LineText, 4, "|"))
          Commands()\Color1 = Val(StringField(LineText, 5, "|"))
          Commands()\Color2 = Val(StringField(LineText, 6, "|"))
          Commands()\TextStr = StringField(LineText, 7, "|")
          Commands()\Third = Commands()\Y1 / 64
        Default
          DeleteElement(Commands())
      EndSelect
    EndIf
  Next
EndProcedure

Procedure.b Scr2Ed_ConfirmDiscardScreen()
  ProcedureReturn Bool(MessageRequester("Tela nao registrada",
                        "As alteracoes desta tela ainda nao foram registradas no projeto." + Chr(10) +
                        "Descartar mesmo assim?",
                        #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
EndProcedure

; ------------------------------------------------------------
;  Ferramenta TEXTO: blita o glifo 8x8 de cada caractere de um alfabeto do
;  projeto (ProjectDB::FetchAlphabet) direto no framebuffer, via
;  Scr2_SetPixel - mesma faixa/color clash de qualquer outro desenho (o
;  motor Screen2Synth.pbi nunca precisa saber de alfabetos; so recebe
;  pixels). O motor NAO faz esse blit sozinho (Scr2_ReplayCommand trata
;  #Scr2_Cmd_Text como no-op) porque precisaria depender do ProjectDB -
;  por isso a janela tem sua propria Scr2Ed_ReplayAllWithText(), usada em
;  todos os pontos desta janela no lugar do Scr2_ReplayAll() puro do motor.
; ------------------------------------------------------------

; StartX/StartY sao PIXEL bruto (canto superior esquerdo do 1o caractere),
; nao coluna/linha de celula - cada caractere seguinte desloca 8px pra
; direita a partir dai, alinhado ou nao ao grid de 8px do MSX de verdade
; (ver comentario grande sobre STEP/pixel-burn em Scr2Ed_GenTextPixelBurn).
Procedure Scr2Ed_BlitText(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), Array CharsetBytes.a(2), TextStr.s, StartX.i, StartY.i, InkColor.i, PaperColor.i)
  Protected i, Code, Row, Col, ByteVal.a, BaseX, BaseY
  For i = 1 To Len(TextStr)
    Code = Asc(Mid(TextStr, i, 1))
    If Code >= 0 And Code <= 255
      BaseX = StartX + (i - 1) * 8
      BaseY = StartY
      For Row = 0 To 7
        ByteVal = CharsetBytes(Code, Row)
        For Col = 0 To 7
          If ByteVal & (1 << (7 - Col))
            Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), BaseX + Col, BaseY + Row, InkColor, #True)
          Else
            Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), BaseX + Col, BaseY + Row, PaperColor, #False)
          EndIf
        Next
      Next
    EndIf
  Next
EndProcedure

; Mesmo papel de Scr2_ReplayAll() (motor), mas tambem trata
; #Scr2_Cmd_Text - busca o alfabeto no ProjectDB a cada replay (simples,
; sem cache; o custo so aparece ao adicionar/remover/mover comandos, nao
; a cada frame).
Procedure Scr2Ed_ReplayAllWithText(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), List Commands.Scr2_Command())
  Scr2_ClearFramebuffer(PatternBit(), RowFG(), RowBG())
  Dim TextCharset.a(255, 7)
  ForEach Commands()
    If Commands()\CmdType = #Scr2_Cmd_Text
      If ProjectDB::FetchAlphabet(Commands()\AlphaNum, TextCharset())
        Scr2Ed_BlitText(PatternBit(), RowFG(), RowBG(), TextCharset(), Commands()\TextStr, Commands()\X1, Commands()\Y1, Commands()\Color1, Commands()\Color2)
      EndIf
    Else
      Scr2_ReplayCommand(PatternBit(), RowFG(), RowBG(), @Commands())
    EndIf
  Next
EndProcedure

; Gera o "carregador" de um alfabeto customizado num terco da tela: DATA
; com os 2048 bytes do alfabeto (formato hex, 16 por linha - mesmo estilo
; de PsgGen_RawBytes em PsgSynth.pbi) + um laco VPOKE carregando a Pattern
; Generator Table do terco (endereco &H0000 + 2048*terco) e outro
; preenchendo a Color Table do mesmo terco (&H2000 + 2048*terco) com o
; par tinta/fundo escolhido - enderecos padrao que o MSX-BASIC usa
; automaticamente ao entrar em SCREEN 2. Depois disso, PRINT usa o
; alfabeto customizado normalmente (os codigos de caractere editados no
; alfabeto SAO os mesmos codigos ASCII/MSX usados por PRINT).
Procedure.s Scr2Ed_GenAlphabetLoader(Array CharsetBytes.a(2), Third.i, InkColor.i, PaperColor.i)
  Protected Result.s = ""
  Protected PatternAddr = Third * 2048
  Protected ColorAddr = $2000 + Third * 2048
  Result + "' Carrega o alfabeto no terco " + Str(Third) + " da tela (Pattern + Color Table)" + #CRLF$
  Result + "FOR SI=0 TO 2047:READ SD:VPOKE " + Str(PatternAddr) + "+SI,SD:NEXT SI" + #CRLF$
  Result + "FOR SI=0 TO 2047:VPOKE " + Str(ColorAddr) + "+SI," + Str(InkColor) + "*16+" + Str(PaperColor) + ":NEXT SI" + #CRLF$
  Protected Row, Col, LineVals.s, Count
  Count = 0
  LineVals = ""
  For Row = 0 To 255
    For Col = 0 To 7
      If Count > 0 And Count % 16 = 0
        Result + "DATA " + LineVals + #CRLF$
        LineVals = ""
      EndIf
      If LineVals <> ""
        LineVals + ","
      EndIf
      LineVals + "&H" + RSet(Hex(CharsetBytes(Row, Col)), 2, "0")
      Count + 1
    Next
  Next
  If LineVals <> ""
    Result + "DATA " + LineVals + #CRLF$
  EndIf
  ProcedureReturn Result
EndProcedure

; Fallback pro texto quando o ponto de ancora (BaseX,BaseY) NAO cai no grid
; de 8px (usuario posicionou pixel a pixel com CTRL) - LOCATE so aceita
; coluna/linha de celula inteira, entao um texto fora do grid nao tem como
; virar LOCATE+PRINT de verdade. Em vez disso, "queima" cada pixel do glifo
; direto na tela via PSET (bit 1) / PRESET (bit 0), igual ao que
; Scr2Ed_BlitText ja faz na previa ao vivo - mais verboso, mas funciona em
; qualquer posicao e nao depende de sobrescrever a ROM de caracteres.
Procedure.s Scr2Ed_GenTextPixelBurn(Array CharsetBytes.a(2), TextStr.s, BaseX.i, BaseY.i, InkColor.i, PaperColor.i)
  Protected Result.s = ""
  Protected i, Code, Row, Col, ByteVal.a, CX, CY
  Result + "' Texto pixel a pixel em (" + Str(BaseX) + "," + Str(BaseY) + ") - fora do grid de 8px, sem LOCATE" + #CRLF$
  For i = 1 To Len(TextStr)
    Code = Asc(Mid(TextStr, i, 1))
    If Code >= 0 And Code <= 255
      For Row = 0 To 7
        ByteVal = CharsetBytes(Code, Row)
        CY = BaseY + Row
        For Col = 0 To 7
          CX = BaseX + (i - 1) * 8 + Col
          If ByteVal & (1 << (7 - Col))
            Result + "PSET (" + Str(CX) + "," + Str(CY) + ")," + Str(InkColor) + #CRLF$
          Else
            Result + "PRESET (" + Str(CX) + "," + Str(CY) + ")," + Str(PaperColor) + #CRLF$
          EndIf
        Next
      Next
    EndIf
  Next
  ProcedureReturn Result
EndProcedure

; Mesmo papel de Scr2_GenBasicLines() (motor), mas gera o codigo completo
; pro #Scr2_Cmd_Text em vez do comentario TODO que o motor emite sozinho -
; busca o alfabeto no ProjectDB na hora de gerar o codigo. Dois caminhos,
; conforme o ponto de ancora (X1,Y1) cair ou nao no grid de 8px: alinhado
; usa o carregador VPOKE + LOCATE/PRINT (compacto, o mecanismo real do
; MSX-BASIC); fora do grid usa Scr2Ed_GenTextPixelBurn (ver comentario la).
Procedure.s Scr2Ed_GenBasicLinesWithText(List Commands.Scr2_Command())
  Protected Result.s = ""
  Dim TextCharset2.a(255, 7)
  Protected SafeText.s, AbsRow, ThirdOfY
  ForEach Commands()
    If Commands()\CmdType = #Scr2_Cmd_Text
      If ProjectDB::FetchAlphabet(Commands()\AlphaNum, TextCharset2())
        If Commands()\X1 % 8 = 0 And Commands()\Y1 % 8 = 0
          ThirdOfY = Commands()\Y1 / 64
          Result + Scr2Ed_GenAlphabetLoader(TextCharset2(), ThirdOfY, Commands()\Color1, Commands()\Color2)
          AbsRow = Commands()\Y1 / 8
          SafeText = ReplaceString(Commands()\TextStr, Chr(34), "'")
          Result + "LOCATE " + Str(Commands()\X1 / 8) + "," + Str(AbsRow) + #CRLF$
          Result + "PRINT " + Chr(34) + SafeText + Chr(34) + #CRLF$
        Else
          Result + Scr2Ed_GenTextPixelBurn(TextCharset2(), Commands()\TextStr, Commands()\X1, Commands()\Y1, Commands()\Color1, Commands()\Color2)
        EndIf
      Else
        Result + "' TODO: alfabeto #" + Str(Commands()\AlphaNum) + " nao encontrado no projeto" + #CRLF$
      EndIf
    Else
      ; reaproveita Scr2_GenBasicLines() pra um unico comando, montando
      ; uma lista temporaria de 1 elemento - evita duplicar a formatacao
      ; de PSET/PRESET/LINE/CIRCLE/PAINT/DRAW aqui.
      NewList OneCmd.Scr2_Command()
      AddElement(OneCmd())
      OneCmd() = Commands()
      Result + Scr2_GenBasicLines(OneCmd())
    EndIf
  Next
  ProcedureReturn Result
EndProcedure

; Ponto unico depois de qualquer mudanca em Commands(): reconstroi o
; framebuffer (replay), redesenha o canvas e atualiza a lista principal +
; os 4 mini buffers - substitui a sequencia de 3 linhas repetida em todo
; handler que mexia em Commands() antes dos mini buffers existirem.
Procedure Scr2Ed_CommitChange(G_Canvas, Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), Array Palette.l(1), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, List Commands.Scr2_Command(), SelectedMainIdx.i)
  Scr2Ed_ReplayAllWithText(PatternBit(), RowFG(), RowBG(), Commands())
  Scr2Ed_RedrawCanvas(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette())
  Scr2Ed_RefreshCommandList(G_List, Commands(), SelectedMainIdx)
  Scr2Ed_RefreshMiniList(G_PsetMini, Commands(), #Scr2_Cmd_Pset)
  Scr2Ed_RefreshMiniList(G_PresetMini, Commands(), #Scr2_Cmd_Preset)
  Scr2Ed_RefreshMiniList(G_LineMini, Commands(), #Scr2_Cmd_Line)
  Scr2Ed_RefreshMiniList(G_CircleMini, Commands(), #Scr2_Cmd_Circle)
EndProcedure

Procedure Screen2Editor_OpenWindow(ParentWindow)
  Protected LeftX = 15
  Protected ProjBarY = 15
  Protected CanvasY = ProjBarY + 34
  Protected ListY = CanvasY + #Scr2Ed_CanvasH + 10
  Protected ListH = 110
  Protected ListBtnY = ListY + ListH + 6
  Protected CloseY = ListBtnY + 34

  Protected RightX = LeftX + #Scr2Ed_CanvasW + 20
  Protected PaletteY = CanvasY
  Protected PaletteLabelH = 16
  Protected PanelY = PaletteY + PaletteLabelH + #Scr2Ed_PaletteSize + 14
  Protected PanelW = 400
  Protected PanelH = 380
  Protected AddBtnY = PanelY + PanelH + 8
  Protected RightBottom = AddBtnY + 30

  Protected CodeY
  If RightBottom > CloseY
    CodeY = RightBottom + 15
  Else
    CodeY = CloseY + 15
  EndIf
  Protected CodeBtnH = 26
  Protected CodeOutY = CodeY + CodeBtnH + 6
  Protected CodeOutH = 90

  Protected WinW = RightX + PanelW + 15
  Protected WinH = CodeOutY + CodeOutH + 15

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Criar tela MSX (SCREEN 2)",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  ; --- Barra de projeto (mesmo padrao de numero/tag/navegacao/Registrar/
  ; Novo/Copiar/Colar dos demais editores - icones reaproveitados de
  ; CharsetEditorGui.pbi, ja incluido antes deste arquivo) ---
  Protected Cx = LeftX
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
  Cx + #CharEd_IconBtnW + 16

  TextGadget(#PB_Any, Cx, ProjBarY + 5, 32, 20, "Tag:")
  Cx + 32 + 4
  Protected G_Tag = StringGadget(#PB_Any, Cx, ProjBarY + 3, 110, 22, "")
  GadgetToolTip(G_Tag, "Nome curto pra identificar a tela (ate 16 caracteres)")
  Cx + 110 + 16

  Protected NewIcon = CharEd_CreateNewIcon(#CharEd_IconSize)
  Protected G_New = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(NewIcon))
  GadgetToolTip(G_New, "Nova tela (numera automaticamente, comeca em branco)")
  Cx + #CharEd_IconBtnW + 2
  Protected RegisterIcon = CharEd_CreateRegisterIcon(#CharEd_IconSize)
  Protected G_Register = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(RegisterIcon))
  GadgetToolTip(G_Register, "Registrar: grava a lista de comandos desta tela no projeto")
  Cx + #CharEd_IconBtnW + 16
  Protected CopyIcon = CharEd_CreateCopyIcon(#CharEd_IconSize)
  Protected G_Copy = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(CopyIcon))
  GadgetToolTip(G_Copy, "Copiar: copia a lista de comandos desta tela pra area de transferencia da sessao")
  Cx + #CharEd_IconBtnW + 2
  Protected PasteIcon = CharEd_CreatePasteIcon(#CharEd_IconSize)
  Protected G_Paste = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(PasteIcon))
  GadgetToolTip(G_Paste, "Colar: substitui a lista de comandos desta tela pela copiada")

  ; --- Canvas SCREEN 2 (256x192 a 2x = 512x384) ---
  Protected G_Canvas = CanvasGadget(#PB_Any, LeftX, CanvasY, #Scr2Ed_CanvasW, #Scr2Ed_CanvasH)

  ; --- Lista de comandos + Remover/Mover ---
  TextGadget(#PB_Any, LeftX, ListY - 16, 200, 16, "Comandos:")
  Protected G_List = ListIconGadget(#PB_Any, LeftX, ListY, #Scr2Ed_CanvasW, ListH, "Comando", #Scr2Ed_CanvasW - 24, #PB_ListIcon_AlwaysShowSelection)
  Protected RemoveIcon = SpriteEd_CreateClearIcon(#CharEd_IconSize)
  Protected G_Remove = ButtonImageGadget(#PB_Any, LeftX, ListBtnY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(RemoveIcon))
  GadgetToolTip(G_Remove, "Remover: apaga o comando selecionado na lista")
  Protected UpIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 0, #False)
  Protected G_MoveUp = ButtonImageGadget(#PB_Any, LeftX + #CharEd_IconBtnW + 6, ListBtnY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(UpIcon))
  GadgetToolTip(G_MoveUp, "Mover pra cima: o comando e desenhado mais cedo")
  Protected DownIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 1, #False)
  Protected G_MoveDown = ButtonImageGadget(#PB_Any, LeftX + (#CharEd_IconBtnW + 6) * 2, ListBtnY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(DownIcon))
  GadgetToolTip(G_MoveDown, "Mover pra baixo: o comando e desenhado mais tarde")

  Protected G_Close = ThemedButton(LeftX, CloseY, 100, 30, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  ; --- Paleta (Tinta / Fundo) ---
  TextGadget(#PB_Any, RightX, PaletteY - PaletteLabelH, 90, PaletteLabelH, "Tinta:")
  Protected G_PaletteInk = CanvasGadget(#PB_Any, RightX, PaletteY, #Scr2Ed_PaletteSize, #Scr2Ed_PaletteSize)
  TextGadget(#PB_Any, RightX + #Scr2Ed_PaletteSize + 16, PaletteY - PaletteLabelH, 90, PaletteLabelH, "Fundo:")
  Protected G_PalettePaper = CanvasGadget(#PB_Any, RightX + #Scr2Ed_PaletteSize + 16, PaletteY, #Scr2Ed_PaletteSize, #Scr2Ed_PaletteSize)

  ; --- Painel de ferramentas (uma aba por ferramenta) ---
  Protected G_Panel = PanelGadget(#PB_Any, RightX, PanelY, PanelW, PanelH)

  AddGadgetItem(G_Panel, -1, "PSET")
    TextGadget(#PB_Any, 10, 10, 20, 20, "X:")
    Protected G_PsetX = StringGadget(#PB_Any, 35, 8, 60, 22, "10")
    TextGadget(#PB_Any, 105, 10, 20, 20, "Y:")
    Protected G_PsetY = StringGadget(#PB_Any, 130, 8, 60, 22, "10")
    Protected G_PsetStep = CheckBoxGadget(#PB_Any, 210, 10, 170, 20, "STEP (relativo ao cursor)")
    Protected G_PsetAdd = ThemedButton(10, 40, 160, 26, "Adicionar PSET", "")
    TextGadget(#PB_Any, 10, 75, PanelW - 20, 40, "PSET liga um pixel com a cor de Tinta selecionada. Clique no canvas pra ligar o pixel na hora. STEP: X/Y viram deslocamento a partir do cursor grafico (posicao do ultimo comando).")
    TextGadget(#PB_Any, 10, 120, 200, 16, "Comandos PSET (clique + Remover):")
    Protected G_PsetMini = ListIconGadget(#PB_Any, 10, 136, PanelW - 20, 180, "Comando", PanelW - 44, #PB_ListIcon_AlwaysShowSelection)
    Protected PsetMiniDelIcon = SpriteEd_CreateClearIcon(#CharEd_IconSize)
    Protected G_PsetMiniDel = ButtonImageGadget(#PB_Any, 10, 322, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(PsetMiniDelIcon))
    GadgetToolTip(G_PsetMiniDel, "Remover: apaga o PSET selecionado (some do canvas)")

  AddGadgetItem(G_Panel, -1, "PRESET")
    TextGadget(#PB_Any, 10, 10, 20, 20, "X:")
    Protected G_PresetX = StringGadget(#PB_Any, 35, 8, 60, 22, "10")
    TextGadget(#PB_Any, 105, 10, 20, 20, "Y:")
    Protected G_PresetY = StringGadget(#PB_Any, 130, 8, 60, 22, "10")
    Protected G_PresetStep = CheckBoxGadget(#PB_Any, 210, 10, 170, 20, "STEP (relativo ao cursor)")
    Protected G_PresetAdd = ThemedButton(10, 40, 160, 26, "Adicionar PRESET", "")
    TextGadget(#PB_Any, 10, 75, PanelW - 20, 40, "PRESET apaga um pixel usando a cor de Fundo selecionada. Clique no canvas pra apagar o pixel na hora. STEP: X/Y viram deslocamento a partir do cursor grafico.")
    TextGadget(#PB_Any, 10, 120, 200, 16, "Comandos PRESET (clique + Remover):")
    Protected G_PresetMini = ListIconGadget(#PB_Any, 10, 136, PanelW - 20, 180, "Comando", PanelW - 44, #PB_ListIcon_AlwaysShowSelection)
    Protected PresetMiniDelIcon = SpriteEd_CreateClearIcon(#CharEd_IconSize)
    Protected G_PresetMiniDel = ButtonImageGadget(#PB_Any, 10, 322, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(PresetMiniDelIcon))
    GadgetToolTip(G_PresetMiniDel, "Remover: apaga o PRESET selecionado (some do canvas)")

  AddGadgetItem(G_Panel, -1, "LINE")
    TextGadget(#PB_Any, 10, 10, 20, 20, "X1:")
    Protected G_LineX1 = StringGadget(#PB_Any, 40, 8, 55, 22, "10")
    TextGadget(#PB_Any, 100, 10, 20, 20, "Y1:")
    Protected G_LineY1 = StringGadget(#PB_Any, 130, 8, 55, 22, "10")
    Protected G_LineStep1 = CheckBoxGadget(#PB_Any, 200, 10, 190, 20, "STEP ponto 1 (relativo ao cursor)")
    TextGadget(#PB_Any, 10, 38, 20, 20, "X2:")
    Protected G_LineX2 = StringGadget(#PB_Any, 40, 36, 55, 22, "60")
    TextGadget(#PB_Any, 100, 38, 20, 20, "Y2:")
    Protected G_LineY2 = StringGadget(#PB_Any, 130, 36, 55, 22, "60")
    Protected G_LineStep2 = CheckBoxGadget(#PB_Any, 200, 38, 190, 20, "STEP ponto 2 (relativo ao ponto 1)")
    Protected G_LineModeNormal = OptionGadget(#PB_Any, 10, 66, 90, 20, "Reta")
    Protected G_LineModeBox = OptionGadget(#PB_Any, 100, 66, 90, 20, "Caixa (B)")
    Protected G_LineModeFill = OptionGadget(#PB_Any, 190, 66, 110, 20, "Caixa cheia (BF)")
    SetGadgetState(G_LineModeNormal, #True)
    Protected G_LineNoStart = CheckBoxGadget(#PB_Any, 10, 90, 320, 20, "LINE -(x,y): sem ponto inicial (usa o cursor grafico)")
    Protected G_LineAdd = ThemedButton(10, 120, 160, 26, "Adicionar LINE", "")
    TextGadget(#PB_Any, 10, 154, PanelW - 20, 40, "Clique no canvas: primeiro clique marca o ponto inicial, segundo traca (reta ou caixa, conforme o modo acima). Com 'sem ponto inicial', 1 clique ja completa.")
    TextGadget(#PB_Any, 10, 200, 200, 16, "Comandos LINE (clique + Remover):")
    Protected G_LineMini = ListIconGadget(#PB_Any, 10, 216, PanelW - 20, 116, "Comando", PanelW - 44, #PB_ListIcon_AlwaysShowSelection)
    Protected LineMiniDelIcon = SpriteEd_CreateClearIcon(#CharEd_IconSize)
    Protected G_LineMiniDel = ButtonImageGadget(#PB_Any, 10, 338, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(LineMiniDelIcon))
    GadgetToolTip(G_LineMiniDel, "Remover: apaga a LINE selecionada (some do canvas)")

  AddGadgetItem(G_Panel, -1, "CIRCLE")
    TextGadget(#PB_Any, 10, 10, 20, 20, "X:")
    Protected G_CircleX = StringGadget(#PB_Any, 35, 8, 55, 22, "128")
    TextGadget(#PB_Any, 100, 10, 40, 20, "Y:")
    Protected G_CircleY = StringGadget(#PB_Any, 130, 8, 55, 22, "96")
    TextGadget(#PB_Any, 200, 4, 60, 16, "Formato:")
    Protected G_CircleShapeCircle = OptionGadget(#PB_Any, 200, 20, 90, 20, "Circulo")
    Protected G_CircleShapeEllipse = OptionGadget(#PB_Any, 200, 42, 90, 20, "Elipse")
    SetGadgetState(G_CircleShapeCircle, #True)
    TextGadget(#PB_Any, 10, 38, 60, 20, "Raio:")
    Protected G_CircleRadius = StringGadget(#PB_Any, 60, 36, 55, 22, "30")
    TextGadget(#PB_Any, 10, 66, 90, 20, "Angulo inicial:")
    Protected G_CircleStart = StringGadget(#PB_Any, 100, 64, 55, 22, "0")
    TextGadget(#PB_Any, 165, 66, 30, 20, "fim:")
    Protected G_CircleEnd = StringGadget(#PB_Any, 195, 64, 55, 22, "360")
    TextGadget(#PB_Any, 10, 94, 90, 20, "Aspecto (0=auto):")
    Protected G_CircleAspect = StringGadget(#PB_Any, 130, 92, 55, 22, "0")
    Protected G_CircleStep = CheckBoxGadget(#PB_Any, 200, 94, 180, 20, "STEP centro (relativo)")
    Protected G_CirclePieStart = CheckBoxGadget(#PB_Any, 10, 122, 180, 20, "Fatia de pizza (inicio)")
    Protected G_CirclePieEnd = CheckBoxGadget(#PB_Any, 10, 146, 180, 20, "Fatia de pizza (fim)")
    Protected G_CircleAdd = ThemedButton(10, 176, 160, 26, "Adicionar CIRCLE", "")
    TextGadget(#PB_Any, 10, 210, PanelW - 20, 40, "Clique no canvas: Circulo = 1o ponto centro, 2o ponto raio. Elipse = os 2 pontos sao os cantos do quadro.")
    TextGadget(#PB_Any, 10, 256, 200, 16, "Comandos CIRCLE (clique + Remover):")
    Protected G_CircleMini = ListIconGadget(#PB_Any, 10, 272, PanelW - 20, 80, "Comando", PanelW - 44, #PB_ListIcon_AlwaysShowSelection)
    Protected CircleMiniDelIcon = SpriteEd_CreateClearIcon(#CharEd_IconSize)
    Protected G_CircleMiniDel = ButtonImageGadget(#PB_Any, 10, 358, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(CircleMiniDelIcon))
    GadgetToolTip(G_CircleMiniDel, "Remover: apaga o CIRCLE selecionado (some do canvas)")

  AddGadgetItem(G_Panel, -1, "PAINT")
    TextGadget(#PB_Any, 10, 10, 20, 20, "X:")
    Protected G_PaintX = StringGadget(#PB_Any, 35, 8, 55, 22, "128")
    TextGadget(#PB_Any, 100, 10, 20, 20, "Y:")
    Protected G_PaintY = StringGadget(#PB_Any, 130, 8, 55, 22, "96")
    Protected G_PaintStep = CheckBoxGadget(#PB_Any, 200, 10, 180, 20, "STEP (relativo ao cursor)")
    TextGadget(#PB_Any, 10, 38, 150, 20, "Cor de borda (vazio=nenhuma):")
    Protected G_PaintBorder = StringGadget(#PB_Any, 10, 60, 55, 22, "")
    Protected G_PaintAdd = ThemedButton(10, 92, 160, 26, "Adicionar PAINT", "")
    TextGadget(#PB_Any, 10, 126, PanelW - 20, 50, "Preenche a partir de (X,Y) com a cor de Tinta selecionada. Sem cor de borda, preenche so a regiao da mesma cor de partida. Clique no canvas define X/Y.")

  AddGadgetItem(G_Panel, -1, "DRAW")
    TextGadget(#PB_Any, 10, 8, 60, 20, "Inicio X:")
    Protected G_DrawStartX = StringGadget(#PB_Any, 65, 6, 45, 22, "128")
    TextGadget(#PB_Any, 115, 8, 20, 20, "Y:")
    Protected G_DrawStartY = StringGadget(#PB_Any, 135, 6, 45, 22, "96")
    TextGadget(#PB_Any, 10, 34, 370, 16, "Linha atual:")
    Protected G_DrawLine = StringGadget(#PB_Any, 10, 52, PanelW - 20, 22, "")
    TextGadget(#PB_Any, 10, 80, 45, 20, "Valor:")
    Protected G_DrawValue = StringGadget(#PB_Any, 55, 78, 40, 22, "10")
    Protected G_DrawU = ThemedButton(100, 78, 26, 24, "U", "")
    Protected G_DrawD = ThemedButton(128, 78, 26, 24, "D", "")
    Protected G_DrawL = ThemedButton(156, 78, 26, 24, "L", "")
    Protected G_DrawR = ThemedButton(184, 78, 26, 24, "R", "")
    Protected G_DrawE = ThemedButton(212, 78, 26, 24, "E", "")
    Protected G_DrawF = ThemedButton(240, 78, 26, 24, "F", "")
    Protected G_DrawG = ThemedButton(268, 78, 26, 24, "G", "")
    Protected G_DrawH = ThemedButton(296, 78, 26, 24, "H", "")
    Protected G_DrawB = CheckBoxGadget(#PB_Any, 10, 108, 90, 20, "B (nao traca)")
    Protected G_DrawN = CheckBoxGadget(#PB_Any, 105, 108, 90, 20, "N (volta)")
    Protected G_DrawC = ThemedButton(200, 106, 90, 24, "C (cor=Tinta)", "")
    TextGadget(#PB_Any, 10, 136, 45, 20, "M x,y:")
    Protected G_DrawMX = StringGadget(#PB_Any, 55, 134, 45, 22, "0")
    Protected G_DrawMY = StringGadget(#PB_Any, 105, 134, 45, 22, "0")
    Protected G_DrawM = ThemedButton(155, 134, 26, 24, "M", "")
    TextGadget(#PB_Any, 10, 164, 30, 20, "S:")
    Protected G_DrawScale = StringGadget(#PB_Any, 30, 162, 40, 22, "4")
    Protected G_DrawS = ThemedButton(75, 162, 26, 24, "S", "")
    TextGadget(#PB_Any, 110, 164, 30, 20, "A:")
    Protected G_DrawAngle = StringGadget(#PB_Any, 130, 162, 30, 22, "0")
    Protected G_DrawA = ThemedButton(165, 162, 26, 24, "A", "")
    TextGadget(#PB_Any, 200, 164, 30, 20, "TA:")
    Protected G_DrawTAVal = StringGadget(#PB_Any, 225, 162, 45, 22, "45")
    Protected G_DrawTA = ThemedButton(275, 162, 34, 24, "TA", "")
    Protected G_DrawClear = ThemedButton(10, 192, 100, 24, "Limpar linha", Chr(#Icon_Clear))
    GadgetToolTip(G_DrawClear, "Limpar linha")
    Protected G_DrawAdd = ThemedButton(120, 192, 140, 24, "Adicionar DRAW", "")

  AddGadgetItem(G_Panel, -1, "TEXTO")
    TextGadget(#PB_Any, 10, 10, 200, 20, "Terco (posicao inicial do quadro):")
    Protected G_TextThird0 = OptionGadget(#PB_Any, 10, 30, 70, 20, "Cima (0)")
    Protected G_TextThird1 = OptionGadget(#PB_Any, 85, 30, 90, 20, "Meio (1)")
    Protected G_TextThird2 = OptionGadget(#PB_Any, 180, 30, 90, 20, "Baixo (2)")
    SetGadgetState(G_TextThird0, #True)
    TextGadget(#PB_Any, 10, 58, 60, 20, "Alfabeto:")
    Protected G_TextAlpha = ComboBoxGadget(#PB_Any, 70, 56, 150, 22)
    TextGadget(#PB_Any, 10, 86, 370, 16, "Texto:")
    Protected G_TextStr = StringGadget(#PB_Any, 10, 104, PanelW - 20, 22, "")
    Protected G_TextAdd = ThemedButton(10, 136, 160, 26, "Posicionar TEXTO...", "")
    TextGadget(#PB_Any, 10, 170, PanelW - 20, 90, "Usa um alfabeto ja registrado no projeto (Criar -> Alfabeto Graphos III...). Depois de clicar, um quadro com o texto de verdade segue o mouse no canvas: move de 8 em 8 pixels (grid dos tiles), ou pixel a pixel segurando CTRL. Clique no canvas pra fixar o texto ali; botao direito cancela. Se o ponto final nao cair no grid de 8px, 'Gerar codigo' usa PSET/PRESET pixel a pixel em vez de LOCATE/PRINT.")

  CloseGadgetList()

  ; --- Geracao de codigo ---
  Protected G_GenCode = ThemedButton(RightX, CodeY, 140, CodeBtnH, "Gerar codigo", "")
  Protected G_Inject = ThemedButton(RightX + 146, CodeY, 140, CodeBtnH, "Injetar no cursor", Chr(#Icon_Insert))
  GadgetToolTip(G_Inject, "Injetar no cursor")
  Protected G_CopyCode = ThemedButton(RightX + 292, CodeY, 90, CodeBtnH, "Copiar", Chr(#Icon_Copy))
  GadgetToolTip(G_CopyCode, "Copiar")
  Protected G_CodeOutput = EditorGadget(#PB_Any, RightX, CodeOutY, PanelW, CodeOutH)

  ; --- Estado ---
  Dim PatternBit.a(#Scr2_Height - 1, #Scr2_Width - 1)
  Dim RowFG.a(#Scr2_Height - 1, #Scr2_Cols - 1)
  Dim RowBG.a(#Scr2_Height - 1, #Scr2_Cols - 1)
  Dim Palette.l(15)
  Dim PaletteNames.s(15)
  SpriteEd_FillPalette(Palette(), PaletteNames())

  NewList Commands.Scr2_Command()
  Protected SelectedCmd = -1
  Protected InkColor = 15
  Protected PaperColor = 1
  Protected ScreenDirty.b = #False
  Protected ScreenNumber.i = 1
  Protected ScreenTag.s = ""

  ; Clipboard de sessao (uma tela inteira - lista de comandos)
  NewList ClipCommands.Scr2_Command()
  Protected ClipValid.b = #False

  ; Clique no canvas: PSET/PRESET adicionam na hora; LINE/CIRCLE precisam
  ; de 2 cliques (o 1o so marca o ponto pendente - variaveis abaixo -, o
  ; 2o completa e adiciona o comando).
  Protected LinePendingValid.b = #False
  Protected LinePendingX1.i, LinePendingY1.i
  Protected CirclePendingValid.b = #False
  Protected CirclePendingX1.i, CirclePendingY1.i

  ; De-duplica redesenhos da linha elastica (LINE/CIRCLE) - so redesenha
  ; quando o pixel MSX efetivamente muda, ver Case #PB_EventType_MouseMove.
  Protected LastPreviewX.i = -999, LastPreviewY.i = -999

  ; TEXTO - "quadro elastico": ativado ao clicar em "Posicionar TEXTO...",
  ; segue o mouse (8px por vez, ou pixel a pixel com CTRL) ate o clique
  ; seguinte fixar o texto no canvas. Alfabeto/texto/cores ficam congelados
  ; aqui (capturados no momento do clique no botao), pra nao mudar no meio
  ; do arrasto se o usuario mexer nos campos.
  Protected TextPlacementActive.b = #False
  Protected TextPreviewX.i, TextPreviewY.i
  Protected TextPendingStr.s, TextPendingAlpha.i, TextPendingInk.i, TextPendingPaper.i
  Dim TextPendingCharset.a(255, 7)

  Scr2_ClearFramebuffer(PatternBit(), RowFG(), RowBG())
  Scr2Ed_RedrawCanvas(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette())
  Scr2Ed_RedrawMiniPalette(G_PaletteInk, InkColor, Palette())
  Scr2Ed_RedrawMiniPalette(G_PalettePaper, PaperColor, Palette())
  Scr2Ed_RefreshCommandList(G_List, Commands(), -1)
  Scr2Ed_RefreshMiniList(G_PsetMini, Commands(), #Scr2_Cmd_Pset)
  Scr2Ed_RefreshMiniList(G_PresetMini, Commands(), #Scr2_Cmd_Preset)
  Scr2Ed_RefreshMiniList(G_LineMini, Commands(), #Scr2_Cmd_Line)
  Scr2Ed_RefreshMiniList(G_CircleMini, Commands(), #Scr2_Cmd_Circle)

  ; Popula o combo de alfabetos do projeto pra aba Texto (ProjectDB::FetchAlphabet
  ; e chamado de verdade em G_TextAdd, ao entrar no modo de posicionamento).
  ProjectDB::EnsureOpen()
  NewList AlphaNums.i()
  ProjectDB::ListAlphabetNumbers(AlphaNums())
  ForEach AlphaNums()
    AddGadgetItem(G_TextAlpha, -1, "#" + Str(AlphaNums()))
  Next
  If ListSize(AlphaNums()) > 0
    SetGadgetState(G_TextAlpha, 0)
  EndIf

  NewList ScreenNav.i()
  ProjectDB::ListScreenNumbers(ScreenNav())
  If ListSize(ScreenNav()) > 0
    FirstElement(ScreenNav())
    ScreenNumber = ScreenNav()
    ProjectDB::FetchScreen(ScreenNumber)
    ScreenTag = ProjectDB::LastScreenTag()
    Scr2Ed_DeserializeCommands(ProjectDB::LastScreenCommandsText(), Commands())
    Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), -1)
  EndIf
  SetGadgetText(G_ScreenNumberText, "#" + Str(ScreenNumber))
  SetGadgetText(G_Tag, ScreenTag)

  Protected Event, Quit = #False
  Protected MouseX, MouseY, PX, PY
  Protected NavTarget.i
  NewList Nav.i()

  Repeat
    Event = WaitWindowEvent()
    Select Event

      Case #PB_Event_Gadget
        Select EventGadget()

          Case G_PaletteInk
            If EventType() = #PB_EventType_LeftButtonDown
              MouseX = GetGadgetAttribute(G_PaletteInk, #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(G_PaletteInk, #PB_Canvas_MouseY)
              Protected InkIdx = Scr2Ed_PaletteHitTest(MouseX, MouseY)
              If InkIdx >= 0
                InkColor = InkIdx
                Scr2Ed_RedrawMiniPalette(G_PaletteInk, InkColor, Palette())
              EndIf
            EndIf

          Case G_PalettePaper
            If EventType() = #PB_EventType_LeftButtonDown
              MouseX = GetGadgetAttribute(G_PalettePaper, #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(G_PalettePaper, #PB_Canvas_MouseY)
              Protected PaperIdx = Scr2Ed_PaletteHitTest(MouseX, MouseY)
              If PaperIdx >= 0
                PaperColor = PaperIdx
                Scr2Ed_RedrawMiniPalette(G_PalettePaper, PaperColor, Palette())
              EndIf
            EndIf

          Case G_Canvas
            Select EventType()

              Case #PB_EventType_LeftButtonDown
              MouseX = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseY)
              PX = MouseX / #Scr2Ed_Zoom
              PY = MouseY / #Scr2Ed_Zoom
              If TextPlacementActive
                ; fixa o TEXTO no ultimo ponto do quadro elastico (TextPreviewX/Y,
                ; ja com o snap de 8px/CTRL aplicado no MouseMove abaixo) - X1/Y1
                ; viram a ancora em pixel bruto do comando, igual a qualquer outro.
                AddElement(Commands())
                Commands()\CmdType = #Scr2_Cmd_Text
                Commands()\X1 = TextPreviewX : Commands()\Y1 = TextPreviewY
                Commands()\Third = TextPreviewY / 64
                Commands()\AlphaNum = TextPendingAlpha
                Commands()\Color1 = TextPendingInk
                Commands()\Color2 = TextPendingPaper
                Commands()\TextStr = TextPendingStr
                TextPlacementActive = #False
                ScreenDirty = #True
                Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), ListSize(Commands()) - 1)
              ElseIf PX >= 0 And PX < #Scr2_Width And PY >= 0 And PY < #Scr2_Height
                Select GetGadgetState(G_Panel)

                  Case 0 ; PSET - liga o pixel na hora do clique
                    AddElement(Commands())
                    Commands()\CmdType = #Scr2_Cmd_Pset
                    If GetGadgetState(G_PsetStep)
                      Commands()\X1 = PX - Scr2_CursorX : Commands()\Y1 = PY - Scr2_CursorY : Commands()\StepP1 = #True
                    Else
                      Commands()\X1 = PX : Commands()\Y1 = PY
                    EndIf
                    SetGadgetText(G_PsetX, Str(Commands()\X1)) : SetGadgetText(G_PsetY, Str(Commands()\Y1))
                    Commands()\Color1 = InkColor
                    ScreenDirty = #True
                    Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), ListSize(Commands()) - 1)

                  Case 1 ; PRESET - apaga o pixel na hora do clique
                    AddElement(Commands())
                    Commands()\CmdType = #Scr2_Cmd_Preset
                    If GetGadgetState(G_PresetStep)
                      Commands()\X1 = PX - Scr2_CursorX : Commands()\Y1 = PY - Scr2_CursorY : Commands()\StepP1 = #True
                    Else
                      Commands()\X1 = PX : Commands()\Y1 = PY
                    EndIf
                    SetGadgetText(G_PresetX, Str(Commands()\X1)) : SetGadgetText(G_PresetY, Str(Commands()\Y1))
                    Commands()\Color1 = PaperColor
                    ScreenDirty = #True
                    Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), ListSize(Commands()) - 1)

                  Case 2 ; LINE - 1o clique marca o inicio, 2o traca (reta/caixa conforme o modo); "sem
                          ; ponto inicial" usa o cursor grafico como ponto 1 e completa em 1 clique so.
                    If GetGadgetState(G_LineNoStart)
                      AddElement(Commands())
                      Commands()\CmdType = #Scr2_Cmd_Line
                      Commands()\LineNoStart = #True
                      If GetGadgetState(G_LineStep2)
                        Commands()\X2 = PX - Scr2_CursorX : Commands()\Y2 = PY - Scr2_CursorY : Commands()\StepP2 = #True
                      Else
                        Commands()\X2 = PX : Commands()\Y2 = PY
                      EndIf
                      SetGadgetText(G_LineX2, Str(Commands()\X2)) : SetGadgetText(G_LineY2, Str(Commands()\Y2))
                      Commands()\Color1 = InkColor
                      If GetGadgetState(G_LineModeBox)
                        Commands()\BoxMode = 1
                      ElseIf GetGadgetState(G_LineModeFill)
                        Commands()\BoxMode = 2
                      Else
                        Commands()\BoxMode = 0
                      EndIf
                      LinePendingValid = #False
                      ScreenDirty = #True
                      Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), ListSize(Commands()) - 1)
                    ElseIf Not LinePendingValid
                      LinePendingX1 = PX : LinePendingY1 = PY : LinePendingValid = #True
                      SetGadgetText(G_LineX1, Str(PX)) : SetGadgetText(G_LineY1, Str(PY))
                    Else
                      AddElement(Commands())
                      Commands()\CmdType = #Scr2_Cmd_Line
                      If GetGadgetState(G_LineStep1)
                        Commands()\X1 = LinePendingX1 - Scr2_CursorX : Commands()\Y1 = LinePendingY1 - Scr2_CursorY : Commands()\StepP1 = #True
                      Else
                        Commands()\X1 = LinePendingX1 : Commands()\Y1 = LinePendingY1
                      EndIf
                      If GetGadgetState(G_LineStep2)
                        Commands()\X2 = PX - LinePendingX1 : Commands()\Y2 = PY - LinePendingY1 : Commands()\StepP2 = #True
                      Else
                        Commands()\X2 = PX : Commands()\Y2 = PY
                      EndIf
                      SetGadgetText(G_LineX1, Str(Commands()\X1)) : SetGadgetText(G_LineY1, Str(Commands()\Y1))
                      SetGadgetText(G_LineX2, Str(Commands()\X2)) : SetGadgetText(G_LineY2, Str(Commands()\Y2))
                      Commands()\Color1 = InkColor
                      If GetGadgetState(G_LineModeBox)
                        Commands()\BoxMode = 1
                      ElseIf GetGadgetState(G_LineModeFill)
                        Commands()\BoxMode = 2
                      Else
                        Commands()\BoxMode = 0
                      EndIf
                      LinePendingValid = #False
                      ScreenDirty = #True
                      Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), ListSize(Commands()) - 1)
                    EndIf

                  Case 3 ; CIRCLE - Circulo: 1o=centro,2o=raio. Elipse: os 2 pontos sao os cantos do quadro.
                    If Not CirclePendingValid
                      CirclePendingX1 = PX : CirclePendingY1 = PY : CirclePendingValid = #True
                      SetGadgetText(G_CircleX, Str(PX)) : SetGadgetText(G_CircleY, Str(PY))
                    Else
                      Protected CCenterX.i, CCenterY.i, CRadius.i, CAspect.f, CRx.f, CRy.f
                      If GetGadgetState(G_CircleShapeEllipse)
                        CCenterX = (CirclePendingX1 + PX) / 2
                        CCenterY = (CirclePendingY1 + PY) / 2
                        CRx = Abs(PX - CirclePendingX1) / 2
                        CRy = Abs(PY - CirclePendingY1) / 2
                        If CRx < 1 : CRx = 1 : EndIf
                        CRadius = Scr2_RoundF(CRx)
                        CAspect = CRy / CRx
                      Else
                        CCenterX = CirclePendingX1
                        CCenterY = CirclePendingY1
                        CRx = Sqr(Pow(PX - CirclePendingX1, 2) + Pow(PY - CirclePendingY1, 2))
                        CRadius = Scr2_RoundF(CRx)
                        If CRadius < 1 : CRadius = 1 : EndIf
                        CAspect = 0
                      EndIf
                      AddElement(Commands())
                      Commands()\CmdType = #Scr2_Cmd_Circle
                      If GetGadgetState(G_CircleStep)
                        Commands()\X1 = CCenterX - Scr2_CursorX : Commands()\Y1 = CCenterY - Scr2_CursorY : Commands()\StepP1 = #True
                      Else
                        Commands()\X1 = CCenterX : Commands()\Y1 = CCenterY
                      EndIf
                      Commands()\Radius = CRadius
                      Commands()\Color1 = InkColor
                      Commands()\StartDeg = 0 : Commands()\EndDeg = 360 : Commands()\Aspect = CAspect
                      Commands()\PieStart = #False : Commands()\PieEnd = #False
                      SetGadgetText(G_CircleX, Str(Commands()\X1)) : SetGadgetText(G_CircleY, Str(Commands()\Y1))
                      SetGadgetText(G_CircleRadius, Str(CRadius))
                      SetGadgetText(G_CircleAspect, StrF(CAspect, 4))
                      SetGadgetText(G_CircleStart, "0") : SetGadgetText(G_CircleEnd, "360")
                      CirclePendingValid = #False
                      ScreenDirty = #True
                      Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), ListSize(Commands()) - 1)
                    EndIf

                  Case 4 ; PAINT
                    SetGadgetText(G_PaintX, Str(PX)) : SetGadgetText(G_PaintY, Str(PY))
                  Case 5 ; DRAW
                    SetGadgetText(G_DrawStartX, Str(PX)) : SetGadgetText(G_DrawStartY, Str(PY))
                EndSelect
              EndIf

              Case #PB_EventType_RightButtonDown
                ; botao direito cancela o quadro elastico do TEXTO (unico uso
                ; de botao direito no canvas por enquanto).
                If TextPlacementActive
                  TextPlacementActive = #False
                  Scr2Ed_RedrawCanvas(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette())
                EndIf

              Case #PB_EventType_MouseMove
                ; "Linha elastica" - so redesenha quando o pixel MSX realmente
                ; muda (varios eventos MouseMove cru caem no mesmo pixel, ja
                ; que o canvas esta a 2x de zoom) - evita redesenhar a tela
                ; inteira sem necessidade a cada micro-movimento do mouse.
                MouseX = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseX)
                MouseY = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseY)
                PX = MouseX / #Scr2Ed_Zoom
                PY = MouseY / #Scr2Ed_Zoom
                If TextPlacementActive And PX >= 0 And PX < #Scr2_Width And PY >= 0 And PY < #Scr2_Height
                  ; grid de 8px por padrao (encaixa nos tiles de caractere);
                  ; CTRL segurado = pixel a pixel, pra alinhar fino com outro
                  ; desenho ja feito.
                  ; ExamineKeyboard()/KeyboardPushed() (biblioteca Keyboard,
                  ; cross-platform) em vez de GetKeyState_ (WinAPI, so
                  ; Windows) - achado real compilando no Linux via WSL,
                  ; 2026-07-29, ver CLAUDE.md.
                  ExamineKeyboard()
                  If KeyboardPushed(#PB_Key_LeftControl) Or KeyboardPushed(#PB_Key_RightControl)
                    ; pixel a pixel - PX/PY ja vieram validados no If acima (0..Width/Height-1)
                  Else
                    PX = (PX / 8) * 8 : PY = (PY / 8) * 8
                  EndIf
                  If PX <> TextPreviewX Or PY <> TextPreviewY
                    TextPreviewX = PX : TextPreviewY = PY
                    Scr2Ed_RedrawCanvas(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette())
                    Scr2Ed_DrawTextPreview(G_Canvas, TextPendingCharset(), TextPendingStr, TextPreviewX, TextPreviewY, Palette(TextPendingInk), Palette(TextPendingPaper))
                  EndIf
                ElseIf (PX <> LastPreviewX Or PY <> LastPreviewY) And PX >= 0 And PX < #Scr2_Width And PY >= 0 And PY < #Scr2_Height
                  LastPreviewX = PX : LastPreviewY = PY
                  Select GetGadgetState(G_Panel)
                    Case 2 ; LINE
                      If LinePendingValid Or GetGadgetState(G_LineNoStart)
                        Protected PreviewBoxMode, PreviewAnchorX, PreviewAnchorY
                        If GetGadgetState(G_LineModeBox)
                          PreviewBoxMode = 1
                        ElseIf GetGadgetState(G_LineModeFill)
                          PreviewBoxMode = 2
                        Else
                          PreviewBoxMode = 0
                        EndIf
                        If GetGadgetState(G_LineNoStart)
                          PreviewAnchorX = Scr2_CursorX : PreviewAnchorY = Scr2_CursorY
                        Else
                          PreviewAnchorX = LinePendingX1 : PreviewAnchorY = LinePendingY1
                        EndIf
                        Scr2Ed_RedrawCanvas(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette())
                        Scr2Ed_DrawLinePreview(G_Canvas, PreviewAnchorX, PreviewAnchorY, PX, PY, PreviewBoxMode)
                      EndIf
                    Case 3 ; CIRCLE
                      If CirclePendingValid
                        Scr2Ed_RedrawCanvas(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette())
                        Scr2Ed_DrawCirclePreview(G_Canvas, CirclePendingX1, CirclePendingY1, PX, PY, GetGadgetState(G_CircleShapeEllipse))
                      EndIf
                  EndSelect
                EndIf

            EndSelect

          Case G_PsetAdd
            AddElement(Commands())
            Commands()\CmdType = #Scr2_Cmd_Pset
            Commands()\X1 = Val(GetGadgetText(G_PsetX)) : Commands()\Y1 = Val(GetGadgetText(G_PsetY))
            Commands()\StepP1 = GetGadgetState(G_PsetStep)
            Commands()\Color1 = InkColor
            ScreenDirty = #True
            Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), ListSize(Commands()) - 1)

          Case G_PresetAdd
            AddElement(Commands())
            Commands()\CmdType = #Scr2_Cmd_Preset
            Commands()\X1 = Val(GetGadgetText(G_PresetX)) : Commands()\Y1 = Val(GetGadgetText(G_PresetY))
            Commands()\StepP1 = GetGadgetState(G_PresetStep)
            Commands()\Color1 = PaperColor
            ScreenDirty = #True
            Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), ListSize(Commands()) - 1)

          Case G_LineAdd
            LinePendingValid = #False
            AddElement(Commands())
            Commands()\CmdType = #Scr2_Cmd_Line
            Commands()\X1 = Val(GetGadgetText(G_LineX1)) : Commands()\Y1 = Val(GetGadgetText(G_LineY1))
            Commands()\X2 = Val(GetGadgetText(G_LineX2)) : Commands()\Y2 = Val(GetGadgetText(G_LineY2))
            Commands()\StepP1 = GetGadgetState(G_LineStep1)
            Commands()\StepP2 = GetGadgetState(G_LineStep2)
            Commands()\LineNoStart = GetGadgetState(G_LineNoStart)
            Commands()\Color1 = InkColor
            If GetGadgetState(G_LineModeBox)
              Commands()\BoxMode = 1
            ElseIf GetGadgetState(G_LineModeFill)
              Commands()\BoxMode = 2
            Else
              Commands()\BoxMode = 0
            EndIf
            ScreenDirty = #True
            Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), ListSize(Commands()) - 1)

          Case G_CircleAdd
            CirclePendingValid = #False
            AddElement(Commands())
            Commands()\CmdType = #Scr2_Cmd_Circle
            Commands()\X1 = Val(GetGadgetText(G_CircleX)) : Commands()\Y1 = Val(GetGadgetText(G_CircleY))
            Commands()\StepP1 = GetGadgetState(G_CircleStep)
            Commands()\Radius = Val(GetGadgetText(G_CircleRadius))
            Commands()\Color1 = InkColor
            Commands()\StartDeg = ValF(GetGadgetText(G_CircleStart))
            Commands()\EndDeg = ValF(GetGadgetText(G_CircleEnd))
            Commands()\Aspect = ValF(GetGadgetText(G_CircleAspect))
            Commands()\PieStart = GetGadgetState(G_CirclePieStart)
            Commands()\PieEnd = GetGadgetState(G_CirclePieEnd)
            ScreenDirty = #True
            Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), ListSize(Commands()) - 1)

          Case G_PaintAdd
            AddElement(Commands())
            Commands()\CmdType = #Scr2_Cmd_Paint
            Commands()\X1 = Val(GetGadgetText(G_PaintX)) : Commands()\Y1 = Val(GetGadgetText(G_PaintY))
            Commands()\StepP1 = GetGadgetState(G_PaintStep)
            Commands()\Color1 = InkColor
            If Trim(GetGadgetText(G_PaintBorder)) = ""
              Commands()\Color2 = -1
            Else
              Commands()\Color2 = Val(GetGadgetText(G_PaintBorder))
            EndIf
            ScreenDirty = #True
            Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), ListSize(Commands()) - 1)

          Case G_DrawU : SetGadgetText(G_DrawLine, GetGadgetText(G_DrawLine) + "U" + GetGadgetText(G_DrawValue))
          Case G_DrawD : SetGadgetText(G_DrawLine, GetGadgetText(G_DrawLine) + "D" + GetGadgetText(G_DrawValue))
          Case G_DrawL : SetGadgetText(G_DrawLine, GetGadgetText(G_DrawLine) + "L" + GetGadgetText(G_DrawValue))
          Case G_DrawR : SetGadgetText(G_DrawLine, GetGadgetText(G_DrawLine) + "R" + GetGadgetText(G_DrawValue))
          Case G_DrawE : SetGadgetText(G_DrawLine, GetGadgetText(G_DrawLine) + "E" + GetGadgetText(G_DrawValue))
          Case G_DrawF : SetGadgetText(G_DrawLine, GetGadgetText(G_DrawLine) + "F" + GetGadgetText(G_DrawValue))
          Case G_DrawG : SetGadgetText(G_DrawLine, GetGadgetText(G_DrawLine) + "G" + GetGadgetText(G_DrawValue))
          Case G_DrawH : SetGadgetText(G_DrawLine, GetGadgetText(G_DrawLine) + "H" + GetGadgetText(G_DrawValue))

          Case G_DrawM
            SetGadgetText(G_DrawLine, GetGadgetText(G_DrawLine) + "M" + GetGadgetText(G_DrawMX) + "," + GetGadgetText(G_DrawMY))

          Case G_DrawC
            SetGadgetText(G_DrawLine, GetGadgetText(G_DrawLine) + "C" + Str(InkColor))

          Case G_DrawS
            SetGadgetText(G_DrawLine, GetGadgetText(G_DrawLine) + "S" + GetGadgetText(G_DrawScale))

          Case G_DrawA
            SetGadgetText(G_DrawLine, GetGadgetText(G_DrawLine) + "A" + GetGadgetText(G_DrawAngle))

          Case G_DrawTA
            SetGadgetText(G_DrawLine, GetGadgetText(G_DrawLine) + "TA" + GetGadgetText(G_DrawTAVal))

          Case G_DrawClear
            SetGadgetText(G_DrawLine, "")

          Case G_DrawAdd
            Protected DrawTxt.s = GetGadgetText(G_DrawLine)
            If Trim(DrawTxt) = ""
              MessageRequester("Adicionar DRAW", "A linha DRAW esta vazia - monte a linha com os botoes antes de adicionar.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
            Else
              AddElement(Commands())
              Commands()\CmdType = #Scr2_Cmd_Draw
              Commands()\X1 = Val(GetGadgetText(G_DrawStartX)) : Commands()\Y1 = Val(GetGadgetText(G_DrawStartY))
              Commands()\Color1 = InkColor
              Commands()\DrawString = DrawTxt
              ScreenDirty = #True
              Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), ListSize(Commands()) - 1)
              SetGadgetText(G_DrawLine, "")
            EndIf

          Case G_TextAdd
            If GetGadgetState(G_TextAlpha) < 0
              MessageRequester("Posicionar TEXTO", "Nenhum alfabeto registrado no projeto - use 'Criar -> Alfabeto Graphos III...' primeiro.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
            ElseIf Trim(GetGadgetText(G_TextStr)) = ""
              MessageRequester("Posicionar TEXTO", "Digite um texto antes de posicionar.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
            Else
              TextPendingAlpha = Val(Mid(GetGadgetText(G_TextAlpha), 2))
              If ProjectDB::FetchAlphabet(TextPendingAlpha, TextPendingCharset())
                TextPendingStr = GetGadgetText(G_TextStr)
                TextPendingInk = InkColor
                TextPendingPaper = PaperColor
                TextPreviewX = 0
                If GetGadgetState(G_TextThird1)
                  TextPreviewY = 64
                ElseIf GetGadgetState(G_TextThird2)
                  TextPreviewY = 128
                Else
                  TextPreviewY = 0
                EndIf
                TextPlacementActive = #True
                LastPreviewX = -999 : LastPreviewY = -999
                Scr2Ed_RedrawCanvas(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette())
                Scr2Ed_DrawTextPreview(G_Canvas, TextPendingCharset(), TextPendingStr, TextPreviewX, TextPreviewY, Palette(TextPendingInk), Palette(TextPendingPaper))
              Else
                MessageRequester("Posicionar TEXTO", "Nao foi possivel carregar o alfabeto #" + Str(TextPendingAlpha) + " do projeto.",
                                  #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
              EndIf
            EndIf

          Case G_Remove
            SelectedCmd = GetGadgetState(G_List)
            If SelectedCmd >= 0
              SelectElement(Commands(), SelectedCmd)
              DeleteElement(Commands())
              ScreenDirty = #True
              Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), -1)
            EndIf

          Case G_PsetMiniDel
            If Scr2Ed_RemoveFromMiniList(G_PsetMini, Commands())
              ScreenDirty = #True
              Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), -1)
            EndIf

          Case G_PresetMiniDel
            If Scr2Ed_RemoveFromMiniList(G_PresetMini, Commands())
              ScreenDirty = #True
              Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), -1)
            EndIf

          Case G_LineMiniDel
            If Scr2Ed_RemoveFromMiniList(G_LineMini, Commands())
              ScreenDirty = #True
              Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), -1)
            EndIf

          Case G_CircleMiniDel
            If Scr2Ed_RemoveFromMiniList(G_CircleMini, Commands())
              ScreenDirty = #True
              Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), -1)
            EndIf

          Case G_MoveUp
            SelectedCmd = GetGadgetState(G_List)
            If SelectedCmd > 0
              SelectElement(Commands(), SelectedCmd)
              Protected TmpCmd.Scr2_Command = Commands()
              DeleteElement(Commands())
              SelectElement(Commands(), SelectedCmd - 1)
              InsertElement(Commands())
              Commands() = TmpCmd
              ScreenDirty = #True
              Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), SelectedCmd - 1)
            EndIf

          Case G_MoveDown
            SelectedCmd = GetGadgetState(G_List)
            If SelectedCmd >= 0 And SelectedCmd < ListSize(Commands()) - 1
              SelectElement(Commands(), SelectedCmd)
              Protected TmpCmd2.Scr2_Command = Commands()
              DeleteElement(Commands())
              SelectElement(Commands(), SelectedCmd)
              InsertElement(Commands())
              Commands() = TmpCmd2
              ScreenDirty = #True
              Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), SelectedCmd + 1)
            EndIf

          Case G_Copy
            CopyList(Commands(), ClipCommands())
            ClipValid = #True

          Case G_Paste
            If ClipValid
              If Not ScreenDirty Or Scr2Ed_ConfirmDiscardScreen()
                CopyList(ClipCommands(), Commands())
                ScreenDirty = #True
                Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), -1)
              EndIf
            Else
              MessageRequester("Colar", "Nenhuma tela foi copiada ainda nesta sessao.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
            EndIf

          Case G_New
            If Not ScreenDirty Or Scr2Ed_ConfirmDiscardScreen()
              ProjectDB::ListScreenNumbers(Nav())
              Protected NextScreenNum.i = 1
              If ListSize(Nav()) > 0
                LastElement(Nav())
                NextScreenNum = Nav() + 1
              EndIf
              ScreenNumber = NextScreenNum
              ScreenTag = ""
              ClearList(Commands())
              ScreenDirty = #False
              LinePendingValid = #False
              CirclePendingValid = #False
              Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), -1)
              SetGadgetText(G_ScreenNumberText, "#" + Str(ScreenNumber))
              SetGadgetText(G_Tag, ScreenTag)
            EndIf

          Case G_Register
            ScreenTag = Left(GetGadgetText(G_Tag), 16)
            SetGadgetText(G_Tag, ScreenTag)
            If ProjectDB::StoreScreen(ScreenNumber, ScreenTag, Scr2Ed_SerializeCommands(Commands()))
              ScreenDirty = #False
            Else
              MessageRequester("Erro ao registrar",
                                "Nao foi possivel gravar a tela:" + Chr(10) + ProjectDB::GetLastError(),
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
            EndIf

          Case G_First
            If Not ScreenDirty Or Scr2Ed_ConfirmDiscardScreen()
              ProjectDB::ListScreenNumbers(Nav())
              NavTarget = SpriteEd_FindNavTarget(Nav(), 0, ScreenNumber)
              If NavTarget >= 0
                ScreenNumber = NavTarget
                ProjectDB::FetchScreen(ScreenNumber)
                ScreenTag = ProjectDB::LastScreenTag()
                Scr2Ed_DeserializeCommands(ProjectDB::LastScreenCommandsText(), Commands())
                ScreenDirty = #False
                LinePendingValid = #False
                CirclePendingValid = #False
                Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), -1)
                SetGadgetText(G_ScreenNumberText, "#" + Str(ScreenNumber))
                SetGadgetText(G_Tag, ScreenTag)
              EndIf
            EndIf

          Case G_Prev
            If Not ScreenDirty Or Scr2Ed_ConfirmDiscardScreen()
              ProjectDB::ListScreenNumbers(Nav())
              NavTarget = SpriteEd_FindNavTarget(Nav(), 1, ScreenNumber)
              If NavTarget >= 0
                ScreenNumber = NavTarget
                ProjectDB::FetchScreen(ScreenNumber)
                ScreenTag = ProjectDB::LastScreenTag()
                Scr2Ed_DeserializeCommands(ProjectDB::LastScreenCommandsText(), Commands())
                ScreenDirty = #False
                LinePendingValid = #False
                CirclePendingValid = #False
                Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), -1)
                SetGadgetText(G_ScreenNumberText, "#" + Str(ScreenNumber))
                SetGadgetText(G_Tag, ScreenTag)
              EndIf
            EndIf

          Case G_Next
            If Not ScreenDirty Or Scr2Ed_ConfirmDiscardScreen()
              ProjectDB::ListScreenNumbers(Nav())
              NavTarget = SpriteEd_FindNavTarget(Nav(), 2, ScreenNumber)
              If NavTarget >= 0
                ScreenNumber = NavTarget
                ProjectDB::FetchScreen(ScreenNumber)
                ScreenTag = ProjectDB::LastScreenTag()
                Scr2Ed_DeserializeCommands(ProjectDB::LastScreenCommandsText(), Commands())
                ScreenDirty = #False
                LinePendingValid = #False
                CirclePendingValid = #False
                Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), -1)
                SetGadgetText(G_ScreenNumberText, "#" + Str(ScreenNumber))
                SetGadgetText(G_Tag, ScreenTag)
              EndIf
            EndIf

          Case G_Last
            If Not ScreenDirty Or Scr2Ed_ConfirmDiscardScreen()
              ProjectDB::ListScreenNumbers(Nav())
              NavTarget = SpriteEd_FindNavTarget(Nav(), 3, ScreenNumber)
              If NavTarget >= 0
                ScreenNumber = NavTarget
                ProjectDB::FetchScreen(ScreenNumber)
                ScreenTag = ProjectDB::LastScreenTag()
                Scr2Ed_DeserializeCommands(ProjectDB::LastScreenCommandsText(), Commands())
                ScreenDirty = #False
                LinePendingValid = #False
                CirclePendingValid = #False
                Scr2Ed_CommitChange(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), G_List, G_PsetMini, G_PresetMini, G_LineMini, G_CircleMini, Commands(), -1)
                SetGadgetText(G_ScreenNumberText, "#" + Str(ScreenNumber))
                SetGadgetText(G_Tag, ScreenTag)
              EndIf
            EndIf

          Case G_GenCode
            SetGadgetText(G_CodeOutput, Scr2Ed_GenBasicLinesWithText(Commands()))

          Case G_Inject
            Protected InjectCode.s = GetGadgetText(G_CodeOutput)
            If InjectCode = ""
              MessageRequester("Injetar no cursor", "Nada pra injetar - clique em 'Gerar codigo' primeiro.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
            ElseIf Not InjectTextAtCursor(InjectCode)
              MessageRequester("Injetar no cursor", "Nao foi possivel injetar - nenhuma aba de texto ativa no editor.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
            EndIf

          Case G_CopyCode
            Protected CopyCodeTxt.s = GetGadgetText(G_CodeOutput)
            If CopyCodeTxt <> ""
              SetClipboardText(CopyCodeTxt)
            EndIf

          Case G_Close
            If Not ScreenDirty Or Scr2Ed_ConfirmDiscardScreen()
              Quit = #True
            EndIf

        EndSelect

      Case #PB_Event_CloseWindow
        If Not ScreenDirty Or Scr2Ed_ConfirmDiscardScreen()
          Quit = #True
        EndIf

    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
