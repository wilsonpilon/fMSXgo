;
; ------------------------------------------------------------
;  Inserir -> Caractere Especial: janela parecida com o "Mapa de Caracteres"
;  do Windows, para os 159 caracteres especiais que o Basic Dignified Suite
;  traduz para ASCII nativo MSX (opcao -tr) - ver Dig_TransOriginal/
;  Dig_TransReplacementOrder/Dig_TransChar em DignifiedPreprocessor.pbi. A
;  grade reaproveita essas duas strings diretamente (fonte unica da verdade,
;  ja validada byte a byte contra o badig.py de referencia - ver comentario
;  em Dig_TransReplacement) em vez de retranscrever a lista aqui e arriscar
;  um erro de transcricao:
;   - indices 0..127: os 128 caracteres de Dig_TransOriginal (acentos/gregas/
;     graficos), traduzidos para um unico byte 0x80-0xFF.
;   - indices 128..158: os 31 simbolos de Dig_TransReplacementOrder
;     (carinhas/naipes/linhas tipo CP437), traduzidos para DOIS bytes
;     (Chr(1) + letra - "grafico" MSX, ver Dig_TransReplacement).
;  16 colunas x 10 linhas = 160 celulas, a ultima fica vazia (159 chars).
; ------------------------------------------------------------
;

#CharMap_CellPx = 34
#CharMap_Cols = 16
#CharMap_Rows = 10
#CharMap_GridW = #CharMap_Cols * #CharMap_CellPx
#CharMap_GridH = #CharMap_Rows * #CharMap_CellPx
#CharMap_MaxChars = 80
#CharMap_TotalChars = 159

Global CharMap_GridFont.i = 0
Global CharMap_PreviewFont.i = 0

Procedure CharMap_EnsureFonts()
  If Not CharMap_GridFont
    CharMap_GridFont = LoadFont(#PB_Any, "Segoe UI", 16)
  EndIf
  If Not CharMap_PreviewFont
    CharMap_PreviewFont = LoadFont(#PB_Any, "Segoe UI", 36)
  EndIf
EndProcedure

; Indices 0..127 -> Dig_TransOriginal; 128..158 -> Dig_TransReplacementOrder
; (ver comentario no topo do arquivo); fora da faixa (a 160a celula vazia da
; grade 16x10) devolve "".
Procedure.s CharMap_CharAt(Index.i)
  If Index < 0 Or Index >= #CharMap_TotalChars
    ProcedureReturn ""
  ElseIf Index < 128
    ProcedureReturn Mid(Dig_TransOriginal, Index + 1, 1)
  Else
    ProcedureReturn Mid(Dig_TransReplacementOrder, Index - 128 + 1, 1)
  EndIf
EndProcedure

; Descricao da traducao MSX do caractere de indice Index, pro painel de
; info - um unico byte 0x80-0xFF pros 128 primeiros (mesma formula de
; Dig_TransChar, Chr($7F + p)), ou o escape de 2 bytes CHR$(1);CHR$(n) pros
; 31 seguintes (chama Dig_TransReplacement de verdade em vez de recalcular,
; pra nunca dessincronizar da traducao real).
Procedure.s CharMap_MsxDesc(Index.i)
  If Index < 128
    ProcedureReturn "Codigo MSX: " + RSet(Hex($80 + Index), 2, "0") + "h"
  Else
    Protected Ch.s = CharMap_CharAt(Index)
    Protected Esc.s = Dig_TransReplacement(Ch)
    ProcedureReturn "Grafico MSX: CHR$(1);CHR$(" + Str(Asc(Mid(Esc, 2, 1))) + ")"
  EndIf
EndProcedure

Procedure CharMap_Redraw(Canvas, Selected.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf

  Box(0, 0, #CharMap_GridW, #CharMap_GridH, RGB(255, 255, 255))
  DrawingFont(FontID(CharMap_GridFont))

  Protected i, Row, Col, X, Y, Ch.s, TW, TH
  For i = 0 To #CharMap_Cols * #CharMap_Rows - 1
    Row = i / #CharMap_Cols
    Col = i % #CharMap_Cols
    X = Col * #CharMap_CellPx
    Y = Row * #CharMap_CellPx

    DrawingMode(#PB_2DDrawing_Outlined)
    Box(X, Y, #CharMap_CellPx, #CharMap_CellPx, RGB(210, 210, 210))

    Ch = CharMap_CharAt(i)
    DrawingMode(#PB_2DDrawing_Transparent)
    FrontColor(RGB(0, 0, 0))
    TW = TextWidth(Ch)
    TH = TextHeight(Ch)
    DrawText(X + (#CharMap_CellPx - TW) / 2, Y + (#CharMap_CellPx - TH) / 2, Ch)

    If i = Selected
      DrawingMode(#PB_2DDrawing_Outlined)
      Box(X + 1, Y + 1, #CharMap_CellPx - 2, #CharMap_CellPx - 2, RGB(205, 40, 40))
      Box(X + 2, Y + 2, #CharMap_CellPx - 4, #CharMap_CellPx - 4, RGB(205, 40, 40))
    EndIf
  Next

  DrawingMode(#PB_2DDrawing_Default)
  StopDrawing()
EndProcedure

; Desenhada num CanvasGadget proprio (nao um TextGadget nativo) de proposito:
; App_StyleChildCallback (BadigEditor.pb, tema/fonte automatica dos dialogos)
; forca Segoe UI 9pt via WM_SETFONT em TODO controle nativo filho da janela,
; o que anularia uma fonte grande escolhida a mao num TextGadget comum -
; desenho via StartDrawing/DrawingFont e imune a isso (mesmo motivo da grade
; principal usar CanvasGadget em vez de uma tabela de controles nativos).
Procedure CharMap_RedrawPreview(Canvas, Selected.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf

  Protected W = GadgetWidth(Canvas), H = GadgetHeight(Canvas)
  Box(0, 0, W, H, RGB(255, 255, 255))
  DrawingMode(#PB_2DDrawing_Outlined)
  Box(0, 0, W, H, RGB(210, 210, 210))

  DrawingMode(#PB_2DDrawing_Transparent)
  DrawingFont(FontID(CharMap_PreviewFont))
  FrontColor(RGB(0, 0, 0))
  Protected Ch.s = CharMap_CharAt(Selected)
  Protected TW = TextWidth(Ch), TH = TextHeight(Ch)
  DrawText((W - TW) / 2, (H - TH) / 2, Ch)

  DrawingMode(#PB_2DDrawing_Default)
  StopDrawing()
EndProcedure

Procedure CharMap_UpdatePreview(G_Preview, G_Info, Selected.i)
  CharMap_RedrawPreview(G_Preview, Selected)
  Protected Ch.s = CharMap_CharAt(Selected)
  If Ch = ""
    SetGadgetText(G_Info, "")
    ProcedureReturn
  EndIf
  SetGadgetText(G_Info, "Caractere " + Str(Selected + 1) + "/" + Str(#CharMap_TotalChars) + Chr(10) +
                        CharMap_MsxDesc(Selected) + Chr(10) +
                        "Unicode: U+" + RSet(Hex(Asc(Ch)), 4, "0"))
EndProcedure

Procedure.s CharMap_AppendChar(Current.s, Ch.s)
  If Len(Current) >= #CharMap_MaxChars
    ProcedureReturn Current
  EndIf
  ProcedureReturn Current + Ch
EndProcedure

Procedure CharMap_OpenWindow(ParentWindow)
  CharMap_EnsureFonts()

  Protected WinW = 780, WinH = 536
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Inserir Caractere Especial",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  TextGadget(#PB_Any, 24, 24, WinW - 48, 20,
    "Clique para selecionar um caractere, duplo clique (ou 'Adicionar') para colocar no campo abaixo.")

  Protected G_Grid = CanvasGadget(#PB_Any, 24, 60, #CharMap_GridW, #CharMap_GridH)

  Protected PreviewX = 24 + #CharMap_GridW + 24
  Protected PreviewW = WinW - PreviewX - 24
  Protected G_Preview = CanvasGadget(#PB_Any, PreviewX, 60, PreviewW, 150)
  Protected G_Info = TextGadget(#PB_Any, PreviewX, 226, PreviewW, 70, "", #PB_Text_Center)

  TextGadget(#PB_Any, 24, 60 + #CharMap_GridH + 16, 400, 20, "Caracteres a inserir (max " + Str(#CharMap_MaxChars) + "):")
  Protected FieldY = 60 + #CharMap_GridH + 44
  Protected G_Field = StringGadget(#PB_Any, 24, FieldY, WinW - 48, 24, "")

  Protected BtnY = FieldY + 40
  Protected G_Add = ThemedButton(24, BtnY, 110, 28, "Adicionar", Chr(#Icon_Add))
  GadgetToolTip(G_Add, "Adicionar")
  Protected G_RemoveLast = ThemedButton(146, BtnY, 130, 28, "Remover ultimo", Chr(#Icon_Remove))
  GadgetToolTip(G_RemoveLast, "Remover ultimo")
  Protected G_Clear = ThemedButton(288, BtnY, 90, 28, "Limpar", Chr(#Icon_Clear))
  GadgetToolTip(G_Clear, "Limpar")
  Protected G_Insert = ThemedButton(WinW - 24 - 90 - 12 - 100, BtnY, 100, 28, "Inserir", Chr(#Icon_Insert))
  GadgetToolTip(G_Insert, "Inserir")
  Protected G_Close = ThemedButton(WinW - 24 - 90, BtnY, 90, 28, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  Protected Selected.i = 0
  CharMap_Redraw(G_Grid, Selected)
  CharMap_UpdatePreview(G_Preview, G_Info, Selected)

  Protected Event, Quit = #False, MouseX, MouseY, Col, Row, NewSel, Cur.s

  Repeat
    Event = WaitWindowEvent()

    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_Grid
            Select EventType()
              Case #PB_EventType_LeftButtonDown, #PB_EventType_LeftDoubleClick
                MouseX = GetGadgetAttribute(G_Grid, #PB_Canvas_MouseX)
                MouseY = GetGadgetAttribute(G_Grid, #PB_Canvas_MouseY)
                If MouseX >= 0 And MouseY >= 0
                  Col = MouseX / #CharMap_CellPx
                  Row = MouseY / #CharMap_CellPx
                  If Col >= 0 And Col < #CharMap_Cols And Row >= 0 And Row < #CharMap_Rows
                    NewSel = Row * #CharMap_Cols + Col
                    If NewSel < #CharMap_TotalChars
                      If NewSel <> Selected
                        Selected = NewSel
                        CharMap_Redraw(G_Grid, Selected)
                        CharMap_UpdatePreview(G_Preview, G_Info, Selected)
                      EndIf
                      If EventType() = #PB_EventType_LeftDoubleClick
                        SetGadgetText(G_Field, CharMap_AppendChar(GetGadgetText(G_Field), CharMap_CharAt(Selected)))
                      EndIf
                    EndIf
                  EndIf
                EndIf
            EndSelect

          Case G_Add
            SetGadgetText(G_Field, CharMap_AppendChar(GetGadgetText(G_Field), CharMap_CharAt(Selected)))

          Case G_RemoveLast
            Cur = GetGadgetText(G_Field)
            If Len(Cur) > 0
              SetGadgetText(G_Field, Left(Cur, Len(Cur) - 1))
            EndIf

          Case G_Clear
            SetGadgetText(G_Field, "")

          Case G_Insert
            If GetGadgetText(G_Field) <> ""
              InjectTextAtCursor(GetGadgetText(G_Field))
            EndIf
            Quit = #True

          Case G_Close
            Quit = #True
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
