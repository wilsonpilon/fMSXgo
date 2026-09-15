;
; ------------------------------------------------------------
;  Comandos M e S do Mamute Assembler - "faca um esquema similar ao comando
;  DM com as mesmas teclas inclusive e botoes tambem", pedido explicito do
;  usuario. Mesma grade 16x8 (128 bytes, hexa+ASCII) e mesma navegacao do
;  DM (MamuteDumpGui.pbi): setas/PgUp/PgDn movem o cursor/paginam, TAB
;  alterna qual bloco esta em destaque, +/- ajustam o deslocamento da
;  interpretacao ASCII.
;
;  Diferenca deliberada do DM (decidida com o usuario antes de implementar):
;  a edicao de um byte NAO usa o campo de texto em 2 estagios do DM - cada
;  tecla de valor hexa (0-9/A-F pro M; 16 teclas CONFIGURAVEIS em
;  "Configurar -> Mamute Assembler..." pro S) escreve o nibble DIRETO,
;  sem campo de edicao, avancando o cursor sozinho depois do 2o nibble -
;  o comportamento real descrito no manual original do M/S ("0-F entram
;  com um valor em hexadecimal"). RETURN volta a significar so "sai do
;  comando" (tambem como no manual original) em vez de confirmar edicao.
;  Por causa disso, o bloco de TEXTO (ASCII) fica SOMENTE LEITURA neste
;  comando (TAB ainda alterna o destaque visual, por paridade com o DM,
;  mas nunca abre edicao ali) - decisao deliberada pra nao ter que decidir
;  se um atalho de tecla de letra (ex.: as teclas configuraveis do S, que
;  podem ser QWERASDFZXCV) rouba ou nao o foco de um campo de texto nativo
;  do Windows haveria se o bloco de texto tambem fosse editavel - problema
;  evitado de proposito, nao testado.
;
;  M x S: a UNICA diferenca de verdade e QUAL tabela de 16 teclas
;  MamuteM_Open() usa pra escrever os nibbles - M sempre usa 0-9/A-F fixos;
;  S le MamuteSKeyMap() (MamuteSupport.pbi, configuravel). Mesmo codigo,
;  parametro UseCustomKeys.b decide a fonte da tabela.
;
;  Endereco opcional: "M [<endereco>]"/"S [<endereco>]" - se omitido, usa o
;  ultimo endereco onde a janela do M/S ficou (MamuteGui_CmdM/CmdS,
;  MamuteAssemblerGui.pbi, guardam isso em MamuteGui_State - este arquivo
;  devolve o BaseAddr final via ProcedureReturn, ja que nao pode receber
;  *State.MamuteGui_State diretamente: esse tipo so e declarado mais tarde
;  em MamuteAssemblerGui.pbi, que inclui este arquivo ANTES - mesmo motivo
;  de independencia ja usado por MamuteScr_Open/MamuteSave_Open).
; ------------------------------------------------------------
;

#MamuteM_Shortcut_Up       = 9601
#MamuteM_Shortcut_Down     = 9602
#MamuteM_Shortcut_Left     = 9603
#MamuteM_Shortcut_Right    = 9604
#MamuteM_Shortcut_PageUp   = 9605
#MamuteM_Shortcut_PageDown = 9606
#MamuteM_Shortcut_Tab      = 9607
#MamuteM_Shortcut_Return   = 9608
#MamuteM_Shortcut_Escape   = 9609
#MamuteM_Shortcut_Add      = 9610
#MamuteM_Shortcut_Sub      = 9611
#MamuteM_HexKeyBase        = 9620 ; 9620..9635 = valores de nibble 0-15

Structure MamuteMState
  BaseAddr.i    ; endereco (0-65535) do primeiro byte mostrado (linha 0, coluna 0)
  Offset.i      ; deslocamento ASCII ativo (-7Fh..80h) - so afeta a INTERPRETACAO exibida
  CursorRow.i   ; 0-15
  CursorCol.i   ; 0-7
  CursorBlock.i ; 0=hex (unico editavel), 1=texto (destaque visual so, somente leitura)
  NibbleStage.b ; 0=aguardando nibble alto, 1=alto ja recebido, aguardando o baixo
  PendingHigh.a ; nibble alto pendente, valido so quando NibbleStage=1
EndStructure

Procedure MamuteM_ClampCursor(*State.MamuteMState)
  If *State\CursorRow < 0 : *State\CursorRow = 0 : EndIf
  If *State\CursorRow > 15 : *State\CursorRow = 15 : EndIf
  If *State\CursorCol < 0 : *State\CursorCol = 0 : EndIf
  If *State\CursorCol > 7 : *State\CursorCol = 7 : EndIf
EndProcedure

Procedure.i MamuteM_CellAddr(*State.MamuteMState, Row.i, Col.i)
  ProcedureReturn (*State\BaseAddr + Row * 8 + Col) & $FFFF
EndProcedure

Procedure.s MamuteM_DisplayChar(RawByte.a, Offset.i)
  Protected V.i = (RawByte + Offset) & $FF
  If V >= 32 And V <= 126
    ProcedureReturn Chr(V)
  EndIf
  ProcedureReturn "."
EndProcedure

Procedure MamuteM_Repaint(Canvas, *State.MamuteMState, HexX.i, AsciiX.i, CharW.i, CharH.i, HalfCharW.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf

  Protected ColBack        = Mamute_CurrentBackColor()
  Protected ColFront       = Mamute_CurrentFrontColor()
  Protected ColDim         = RGB(25, 110, 50)
  Protected ColCursorBack  = Mamute_CurrentFrontColor()
  Protected ColCursorFront = Mamute_CurrentBackColor()

  Box(0, 0, GadgetWidth(Canvas), GadgetHeight(Canvas), ColBack)

  Protected r.i, c.i, RowAddr.i, ByteAddr.i, RawByte.a, bx.i, ax.i, RowY.i, HexTxt.s

  For r = 0 To 15
    RowY = r * CharH
    RowAddr = MamuteM_CellAddr(*State, r, 0)
    DrawText(0, RowY, Mamute_Hex4(RowAddr) + ":", ColDim, ColBack)

    For c = 0 To 7
      ByteAddr = MamuteM_CellAddr(*State, r, c)
      RawByte = Mamute_ReadByte(ByteAddr)
      bx = HexX + c * HalfCharW * 3
      If r = *State\CursorRow And c = *State\CursorCol And *State\CursorBlock = 0
        If *State\NibbleStage = 1
          HexTxt = Mid("0123456789ABCDEF", *State\PendingHigh + 1, 1) + "_"
        Else
          HexTxt = Mamute_Hex2(RawByte)
        EndIf
        Box(bx - 2, RowY - 1, CharW + 3, CharH - 1, ColCursorBack)
        DrawText(bx, RowY, HexTxt, ColCursorFront, ColCursorBack)
      Else
        DrawText(bx, RowY, Mamute_Hex2(RawByte), ColFront, ColBack)
      EndIf
    Next

    For c = 0 To 7
      ByteAddr = MamuteM_CellAddr(*State, r, c)
      RawByte = Mamute_ReadByte(ByteAddr)
      ax = AsciiX + c * HalfCharW
      If r = *State\CursorRow And c = *State\CursorCol And *State\CursorBlock = 1
        Box(ax - 1, RowY - 1, HalfCharW + 2, CharH - 1, ColCursorBack)
        DrawText(ax, RowY, MamuteM_DisplayChar(RawByte, *State\Offset), ColCursorFront, ColCursorBack)
      Else
        DrawText(ax, RowY, MamuteM_DisplayChar(RawByte, *State\Offset), ColFront, ColBack)
      EndIf
    Next
  Next

  StopDrawing()
EndProcedure

; Mesma tecnica de hit-test em loop ja usada por MamuteDumpGui.pbi/HexEditorGui.pbi.
Procedure.b MamuteM_HitTest(MouseX.i, MouseY.i, HexX.i, AsciiX.i, CharW.i, CharH.i, HalfCharW.i,
                            *OutRow.Integer, *OutCol.Integer, *OutBlock.Integer)
  Protected Row.i = MouseY / CharH
  If Row < 0 Or Row > 15
    ProcedureReturn #False
  EndIf
  Protected c.i, bx.i, ax.i
  For c = 0 To 7
    bx = HexX + c * HalfCharW * 3
    If MouseX >= bx - 2 And MouseX < bx + CharW
      *OutRow\i = Row : *OutCol\i = c : *OutBlock\i = 0
      ProcedureReturn #True
    EndIf
  Next
  For c = 0 To 7
    ax = AsciiX + c * HalfCharW
    If MouseX >= ax - 1 And MouseX < ax + HalfCharW
      *OutRow\i = Row : *OutCol\i = c : *OutBlock\i = 1
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

Procedure MamuteM_DrawButton(Canvas, Label.s, Font)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected W = GadgetWidth(Canvas), H = GadgetHeight(Canvas)
  Box(0, 0, W, H, Mamute_CurrentBackColor())
  DrawingMode(#PB_2DDrawing_Outlined)
  Box(0, 0, W, H, Mamute_CurrentFrontColor())
  DrawingMode(#PB_2DDrawing_Transparent)
  DrawingFont(FontID(Font))
  Protected TW = TextWidth(Label), TH = TextHeight(Label)
  DrawText((W - TW) / 2, (H - TH) / 2, Label, Mamute_CurrentFrontColor())
  StopDrawing()
EndProcedure

Procedure MamuteM_UpdateStatus(G_AddrLabel, G_OffsetLabel, *State.MamuteMState)
  SetGadgetText(G_AddrLabel, "Endereco: " + Mamute_Hex4(*State\BaseAddr))
  Protected Sign.s = "+"
  Protected AbsOff.i = *State\Offset
  If AbsOff < 0
    Sign = "-"
    AbsOff = -AbsOff
  EndIf
  SetGadgetText(G_OffsetLabel, "Desloc.:  " + Sign + Mamute_Hex2(AbsOff))
EndProcedure

; UseCustomKeys=#False (M): tabela fixa 0-9/A-F. #True (S): MamuteSKeyMap()
; configuravel. Devolve o BaseAddr final (endereco onde a janela ficou ao
; fechar) - quem chama guarda isso pra "sem argumento, continua daqui".
Procedure.i MamuteM_Open(ParentWindow, StartAddr.i, StartOffset.i, UseCustomKeys.b)
  Protected State.MamuteMState
  State\BaseAddr = StartAddr & $FFFF
  State\Offset = StartOffset
  State\CursorRow = 0
  State\CursorCol = 0
  State\CursorBlock = 0
  State\NibbleStage = 0
  State\PendingHigh = 0

  Protected Dim KeyChars.s(15) ; indexado por VALOR do nibble (0-15)
  Protected kv.i
  For kv = 0 To 15
    If UseCustomKeys
      KeyChars(kv) = MamuteSKeyMap(kv)
    Else
      KeyChars(kv) = Mid("0123456789ABCDEF", kv + 1, 1)
    EndIf
  Next

  Protected Title.s = "Mamute Assembler - M"
  If UseCustomKeys : Title = "Mamute Assembler - S" : EndIf

  Protected MStyle.i = 0
  If MamuteFontBold : MStyle = #PB_Font_Bold : EndIf
  Protected MFont = LoadFont(#PB_Any, MamuteFontName, MamuteFontSize, MStyle)
  If Not MFont
    MFont = LoadFont(#PB_Any, "Consolas", 14, #PB_Font_Bold)
  EndIf

  Protected CharW, CharH, AddrLabelW, GapW
  Protected MeasureImg = CreateImage(#PB_Any, 10, 10)
  If MeasureImg And StartDrawing(ImageOutput(MeasureImg))
    DrawingFont(FontID(MFont))
    CharW = TextWidth("00")
    CharH = TextHeight("0") + 4
    AddrLabelW = TextWidth("0000: ")
    GapW = TextWidth("  ")
    StopDrawing()
  EndIf
  If MeasureImg : FreeImage(MeasureImg) : EndIf
  If CharW <= 0 : CharW = 18 : EndIf
  If CharH <= 0 : CharH = 20 : EndIf
  If AddrLabelW <= 0 : AddrLabelW = 60 : EndIf
  If GapW <= 0 : GapW = 16 : EndIf
  Protected HalfCharW = CharW / 2
  If HalfCharW <= 0 : HalfCharW = 8 : EndIf

  Protected HexX = AddrLabelW
  Protected AsciiX = HexX + 8 * HalfCharW * 3 + GapW
  Protected GridW = AsciiX + 8 * HalfCharW + 16
  Protected GridH = 16 * CharH

  Protected Margin = 16
  Protected BtnH = 40, BtnGap = 8
  Protected RowW = 56 + BtnGap + BtnH + BtnGap + BtnH + BtnGap + BtnH + BtnGap + BtnH + BtnGap + 56 + BtnGap * 3 + 36 + BtnGap + 36

  Protected WinW = GridW + Margin * 2
  If RowW + Margin * 2 > WinW
    WinW = RowW + Margin * 2
  EndIf

  Protected LegendH = 20, StatusH = 24
  Protected WinH = Margin + LegendH + 8 + GridH + 12 + StatusH + 4 + StatusH + 12 + BtnH + Margin

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, Title,
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #True, #False)
  If Not Win
    ProcedureReturn StartAddr
  EndIf
  SetWindowColor(Win, Mamute_CurrentBorderColor())

  Protected ColFront = Mamute_CurrentFrontColor(), ColBack = Mamute_CurrentBackColor()
  Protected CurY = Margin

  Protected LegendTxt.s = "Setas/PgUp/PgDn: mover  TAB: hex/texto  0-F: digitar hexa  RETURN/ESC: sai  +/-: desloc."
  If UseCustomKeys : LegendTxt = "Setas/PgUp/PgDn: mover  TAB: hex/texto  teclado configurado: digitar hexa  RETURN/ESC: sai  +/-: desloc." : EndIf
  Protected G_Legend = TextGadget(#PB_Any, Margin, CurY, WinW - Margin * 2, LegendH, LegendTxt)
  SetGadgetColor(G_Legend, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Legend, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Legend, FontID(MFont))
  CurY + LegendH + 8

  Protected GridY = CurY
  Protected G_Grid = CanvasGadget(#PB_Any, Margin, GridY, GridW, GridH, #PB_Canvas_Keyboard)
  CurY + GridH + 12

  Protected G_AddrLabel = TextGadget(#PB_Any, Margin, CurY, 260, StatusH, "")
  SetGadgetColor(G_AddrLabel, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_AddrLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_AddrLabel, FontID(MFont))
  CurY + StatusH + 4

  Protected G_OffsetLabel = TextGadget(#PB_Any, Margin, CurY, 260, StatusH, "")
  SetGadgetColor(G_OffsetLabel, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_OffsetLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_OffsetLabel, FontID(MFont))
  CurY + StatusH + 12

  Protected BtnFont = LoadFont(#PB_Any, "Consolas", 14, #PB_Font_Bold)
  If Not BtnFont : BtnFont = MFont : EndIf

  Protected NewOff.i

  Protected BtnY = CurY
  Protected CurX = Margin
  Protected G_PageLeft = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH)   : CurX + 56 + BtnGap
  Protected G_ArrowLeft = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH)  : CurX + BtnH + BtnGap
  Protected G_ArrowUp = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH)    : CurX + BtnH + BtnGap
  Protected G_ArrowDown = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH)  : CurX + BtnH + BtnGap
  Protected G_ArrowRight = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH) : CurX + BtnH + BtnGap
  Protected G_PageRight = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH)  : CurX + 56 + BtnGap * 3
  Protected G_MinusBtn = CanvasGadget(#PB_Any, CurX, BtnY, 36, BtnH)   : CurX + 36 + BtnGap
  Protected G_PlusBtn = CanvasGadget(#PB_Any, CurX, BtnY, 36, BtnH)

  MamuteM_DrawButton(G_PageLeft, "<<", BtnFont)
  MamuteM_DrawButton(G_ArrowLeft, "<", BtnFont)
  MamuteM_DrawButton(G_ArrowUp, "^", BtnFont)
  MamuteM_DrawButton(G_ArrowDown, "v", BtnFont)
  MamuteM_DrawButton(G_ArrowRight, ">", BtnFont)
  MamuteM_DrawButton(G_PageRight, ">>", BtnFont)
  MamuteM_DrawButton(G_MinusBtn, "-", BtnFont)
  MamuteM_DrawButton(G_PlusBtn, "+", BtnFont)
  GadgetToolTip(G_PageLeft, "-128 bytes")
  GadgetToolTip(G_PageRight, "+128 bytes")
  GadgetToolTip(G_MinusBtn, "Desloc. -1")
  GadgetToolTip(G_PlusBtn, "Desloc. +1")

  MamuteM_UpdateStatus(G_AddrLabel, G_OffsetLabel, @State)
  MamuteM_Repaint(G_Grid, @State, HexX, AsciiX, CharW, CharH, HalfCharW)
  SetActiveGadget(G_Grid)

  AddKeyboardShortcut(Win, #PB_Shortcut_Up, #MamuteM_Shortcut_Up)
  AddKeyboardShortcut(Win, #PB_Shortcut_Down, #MamuteM_Shortcut_Down)
  AddKeyboardShortcut(Win, #PB_Shortcut_Left, #MamuteM_Shortcut_Left)
  AddKeyboardShortcut(Win, #PB_Shortcut_Right, #MamuteM_Shortcut_Right)
  AddKeyboardShortcut(Win, #PB_Shortcut_PageUp, #MamuteM_Shortcut_PageUp)
  AddKeyboardShortcut(Win, #PB_Shortcut_PageDown, #MamuteM_Shortcut_PageDown)
  AddKeyboardShortcut(Win, #PB_Shortcut_Tab, #MamuteM_Shortcut_Tab)
  AddKeyboardShortcut(Win, #PB_Shortcut_Return, #MamuteM_Shortcut_Return)
  AddKeyboardShortcut(Win, #PB_Shortcut_Escape, #MamuteM_Shortcut_Escape)
  AddKeyboardShortcut(Win, #PB_Shortcut_Add, #MamuteM_Shortcut_Add)
  AddKeyboardShortcut(Win, #PB_Shortcut_Subtract, #MamuteM_Shortcut_Sub)

  For kv = 0 To 15
    Protected KeyConst.i = Mamute_KeyCharToShortcut(KeyChars(kv))
    If KeyConst
      AddKeyboardShortcut(Win, KeyConst, #MamuteM_HexKeyBase + kv)
    EndIf
  Next

  Macro MamuteM_DoRepaint
    MamuteM_UpdateStatus(G_AddrLabel, G_OffsetLabel, @State)
    MamuteM_Repaint(G_Grid, @State, HexX, AsciiX, CharW, CharH, HalfCharW)
  EndMacro

  Macro MamuteM_DoMove(DRow, DCol)
    State\CursorRow + (DRow)
    State\CursorCol + (DCol)
    State\NibbleStage = 0
    MamuteM_ClampCursor(@State)
    MamuteM_DoRepaint
  EndMacro

  Macro MamuteM_DoPage(Delta)
    State\BaseAddr = (State\BaseAddr + (Delta)) & $FFFF
    State\NibbleStage = 0
    MamuteM_DoRepaint
  EndMacro

  Macro MamuteM_DoOffset(Delta)
    NewOff = State\Offset + (Delta)
    If NewOff < -$7F : NewOff = -$7F : EndIf
    If NewOff > $80 : NewOff = $80 : EndIf
    State\Offset = NewOff
    MamuteM_DoRepaint
  EndMacro

  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_Grid
            If EventType() = #PB_EventType_LeftButtonDown
              Protected MouseX = GetGadgetAttribute(G_Grid, #PB_Canvas_MouseX)
              Protected MouseY = GetGadgetAttribute(G_Grid, #PB_Canvas_MouseY)
              Protected HitRow.i, HitCol.i, HitBlock.i
              If MamuteM_HitTest(MouseX, MouseY, HexX, AsciiX, CharW, CharH, HalfCharW, @HitRow, @HitCol, @HitBlock)
                State\CursorRow = HitRow
                State\CursorCol = HitCol
                State\CursorBlock = HitBlock
                State\NibbleStage = 0
                MamuteM_DoRepaint
              EndIf
            EndIf

          Case G_ArrowUp    : If EventType() = #PB_EventType_LeftButtonDown : MamuteM_DoMove(-1, 0) : EndIf
          Case G_ArrowDown  : If EventType() = #PB_EventType_LeftButtonDown : MamuteM_DoMove(1, 0) : EndIf
          Case G_ArrowLeft  : If EventType() = #PB_EventType_LeftButtonDown : MamuteM_DoMove(0, -1) : EndIf
          Case G_ArrowRight : If EventType() = #PB_EventType_LeftButtonDown : MamuteM_DoMove(0, 1) : EndIf
          Case G_PageLeft   : If EventType() = #PB_EventType_LeftButtonDown : MamuteM_DoPage(-128) : EndIf
          Case G_PageRight  : If EventType() = #PB_EventType_LeftButtonDown : MamuteM_DoPage(128) : EndIf
          Case G_MinusBtn   : If EventType() = #PB_EventType_LeftButtonDown : MamuteM_DoOffset(-1) : EndIf
          Case G_PlusBtn    : If EventType() = #PB_EventType_LeftButtonDown : MamuteM_DoOffset(1) : EndIf
        EndSelect

      Case #PB_Event_Menu
        Select EventMenu()
          Case #MamuteM_Shortcut_Up     : MamuteM_DoMove(-1, 0)
          Case #MamuteM_Shortcut_Down   : MamuteM_DoMove(1, 0)
          Case #MamuteM_Shortcut_Left   : MamuteM_DoMove(0, -1)
          Case #MamuteM_Shortcut_Right  : MamuteM_DoMove(0, 1)
          Case #MamuteM_Shortcut_PageUp   : MamuteM_DoPage(-128)
          Case #MamuteM_Shortcut_PageDown : MamuteM_DoPage(128)
          Case #MamuteM_Shortcut_Add : MamuteM_DoOffset(1)
          Case #MamuteM_Shortcut_Sub : MamuteM_DoOffset(-1)

          Case #MamuteM_Shortcut_Tab
            If State\CursorBlock = 0 : State\CursorBlock = 1 : Else : State\CursorBlock = 0 : EndIf
            State\NibbleStage = 0
            MamuteM_DoRepaint

          Case #MamuteM_Shortcut_Return
            Quit = #True

          Case #MamuteM_Shortcut_Escape
            If State\NibbleStage = 1
              State\NibbleStage = 0
              MamuteM_DoRepaint
            Else
              Quit = #True
            EndIf

          Case #MamuteM_HexKeyBase To #MamuteM_HexKeyBase + 15
            If State\CursorBlock = 0
              Protected NibbleVal.i = EventMenu() - #MamuteM_HexKeyBase
              If State\NibbleStage = 0
                State\PendingHigh = NibbleVal
                State\NibbleStage = 1
              Else
                Protected NewByte.a = (State\PendingHigh << 4) | NibbleVal
                Mamute_WriteByte(MamuteM_CellAddr(@State, State\CursorRow, State\CursorCol), NewByte)
                State\NibbleStage = 0
                State\CursorCol + 1
                If State\CursorCol > 7
                  State\CursorCol = 0
                  State\CursorRow + 1
                  If State\CursorRow > 15
                    State\CursorRow = 15
                    State\CursorCol = 7
                  EndIf
                EndIf
              EndIf
              MamuteM_DoRepaint
            EndIf
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
  ProcedureReturn State\BaseAddr
EndProcedure
