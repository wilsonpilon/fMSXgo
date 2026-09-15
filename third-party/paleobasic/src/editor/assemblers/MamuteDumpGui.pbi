;
; ------------------------------------------------------------
;  Comando DM (Despejo de Memoria) do Mamute Assembler - primeiro comando
;  que realmente le/escreve na memoria simulada (MamuteMem(), MamuteSupport.pbi),
;  resolvendo endereco de CPU -> Slot/Pagina/Offset via o mapeamento ATIVO
;  (MamutePageMap(), o que o comando PAGE deixou configurado).
;
;  "DM <endereco>[,<deslocamento>]" (MamuteAssemblerGui.pbi analisa e chama
;  MamuteDump_Open abaixo) abre esta janela mostrando 128 bytes (16 linhas
;  de 8 bytes) em hexa + ASCII. O deslocamento (se informado) so afeta a
;  INTERPRETACAO ASCII exibida/digitada (RawByte + Offset, modulo 256) -
;  "criptografar/descriptografar" texto por deslocamento Cesar simples; o
;  bloco hexa sempre mostra o byte cru da memoria.
;
;  Navegacao: 4 setas pequenas (clicaveis) + teclado (setas/PgUp/PgDn, so
;  quando NAO esta editando) movem o cursor pela grade 16x8; TAB alterna
;  qual bloco o cursor afeta (hex ou texto); RETURN tem 2 estagios -
;  primeiro abre o campo de edicao (G_EditField, normalmente oculto),
;  segundo confirma o valor digitado; ESC cancela a edicao em andamento ou,
;  se nao havia edicao, fecha a janela. Duas setas maiores (<</>>>) pulam
;  +-128 bytes (endereco base). +/- ajustam o deslocamento.
;
;  Clique direto numa celula da grade tambem move o cursor ali (mesma
;  tecnica de hit-test em loop de HexEditorGui.pbi, adaptada pra 8
;  bytes/linha em vez de 16 e sem scroll - DM sempre mostra os 128 bytes
;  inteiros de uma vez).
;
;  Visual: mesmo par preto/verde do resto do Mamute Assembler, reaproveitando
;  a fonte configuravel em "Configurar -> Mamute Assembler..."
;  (MamuteFontName/Size/Bold) em vez de fixar Consolas de novo.
; ------------------------------------------------------------
;

#MamuteDump_Shortcut_Up       = 9201
#MamuteDump_Shortcut_Down     = 9202
#MamuteDump_Shortcut_Left     = 9203
#MamuteDump_Shortcut_Right    = 9204
#MamuteDump_Shortcut_PageUp   = 9205
#MamuteDump_Shortcut_PageDown = 9206
#MamuteDump_Shortcut_Tab      = 9207
#MamuteDump_Shortcut_Return   = 9208
#MamuteDump_Shortcut_Escape   = 9209
#MamuteDump_Shortcut_Add      = 9210
#MamuteDump_Shortcut_Sub      = 9211

#MamuteDump_EditMode_None = 0
#MamuteDump_EditMode_Hex  = 1
#MamuteDump_EditMode_Text = 2

Structure MamuteDumpState
  BaseAddr.i    ; endereco (0-65535) do primeiro byte mostrado (linha 0, coluna 0)
  Offset.i      ; deslocamento ASCII ativo (-7Fh..80h)
  CursorRow.i   ; 0-15
  CursorCol.i   ; 0-7
  CursorBlock.i ; 0=hex, 1=texto
  EditMode.i    ; #MamuteDump_EditMode_*
EndStructure

; Byte cru + deslocamento (mod 256) -> caractere exibido/editavel, "." se
; nao imprimivel - mesmo criterio de HexEd_PaintRow (32-126), so que
; aplicado ao valor JA deslocado, nao ao byte cru.
Procedure.s MamuteDump_DisplayChar(RawByte.a, Offset.i)
  Protected V.i = (RawByte + Offset) & $FF
  If V >= 32 And V <= 126
    ProcedureReturn Chr(V)
  EndIf
  ProcedureReturn "."
EndProcedure

Procedure MamuteDump_ClampCursor(*State.MamuteDumpState)
  If *State\CursorRow < 0 : *State\CursorRow = 0 : EndIf
  If *State\CursorRow > 15 : *State\CursorRow = 15 : EndIf
  If *State\CursorCol < 0 : *State\CursorCol = 0 : EndIf
  If *State\CursorCol > 7 : *State\CursorCol = 7 : EndIf
EndProcedure

; Endereco de CPU (0-65535, com wraparound) do byte na linha/coluna dadas -
; usado tanto pra desenhar quanto pro cursor atual.
Procedure.i MamuteDump_CellAddr(*State.MamuteDumpState, Row.i, Col.i)
  ProcedureReturn (*State\BaseAddr + Row * 8 + Col) & $FFFF
EndProcedure

Procedure MamuteDump_Repaint(Canvas, *State.MamuteDumpState, HexX.i, AsciiX.i, CharW.i, CharH.i, HalfCharW.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf

  Protected ColBack        = Mamute_CurrentBackColor()
  Protected ColFront       = Mamute_CurrentFrontColor()
  Protected ColDim         = RGB(25, 110, 50)
  Protected ColCursorBack  = Mamute_CurrentFrontColor()
  Protected ColCursorFront = Mamute_CurrentBackColor()

  Box(0, 0, GadgetWidth(Canvas), GadgetHeight(Canvas), ColBack)

  Protected r.i, c.i, RowAddr.i, ByteAddr.i, RawByte.a, bx.i, ax.i, RowY.i

  For r = 0 To 15
    RowY = r * CharH
    RowAddr = MamuteDump_CellAddr(*State, r, 0)
    DrawText(0, RowY, Mamute_Hex4(RowAddr) + ":", ColDim, ColBack)

    For c = 0 To 7
      ByteAddr = MamuteDump_CellAddr(*State, r, c)
      RawByte = Mamute_ReadByte(ByteAddr)
      bx = HexX + c * HalfCharW * 3
      If r = *State\CursorRow And c = *State\CursorCol And *State\CursorBlock = 0
        Box(bx - 2, RowY - 1, CharW + 3, CharH - 1, ColCursorBack)
        DrawText(bx, RowY, Mamute_Hex2(RawByte), ColCursorFront, ColCursorBack)
      Else
        DrawText(bx, RowY, Mamute_Hex2(RawByte), ColFront, ColBack)
      EndIf
    Next

    For c = 0 To 7
      ByteAddr = MamuteDump_CellAddr(*State, r, c)
      RawByte = Mamute_ReadByte(ByteAddr)
      ax = AsciiX + c * HalfCharW
      If r = *State\CursorRow And c = *State\CursorCol And *State\CursorBlock = 1
        Box(ax - 1, RowY - 1, HalfCharW + 2, CharH - 1, ColCursorBack)
        DrawText(ax, RowY, MamuteDump_DisplayChar(RawByte, *State\Offset), ColCursorFront, ColCursorBack)
      Else
        DrawText(ax, RowY, MamuteDump_DisplayChar(RawByte, *State\Offset), ColFront, ColBack)
      EndIf
    Next
  Next

  StopDrawing()
EndProcedure

; Mesma tecnica de hit-test em loop de HexEditorGui.pbi (varre as caixas
; conhecidas em vez de resolver a coluna por formula invertida) - adaptada
; pra 8 bytes/linha, sem scroll (BaseAddr fixo, so muda via paginacao).
Procedure.b MamuteDump_HitTest(MouseX.i, MouseY.i, HexX.i, AsciiX.i, CharW.i, CharH.i, HalfCharW.i,
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

Procedure MamuteDump_DrawButton(Canvas, Label.s, Font)
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

Procedure MamuteDump_UpdateStatus(G_AddrLabel, G_OffsetLabel, *State.MamuteDumpState)
  SetGadgetText(G_AddrLabel, "Endereco: " + Mamute_Hex4(*State\BaseAddr))
  Protected Sign.s = "+"
  Protected AbsOff.i = *State\Offset
  If AbsOff < 0
    Sign = "-"
    AbsOff = -AbsOff
  EndIf
  SetGadgetText(G_OffsetLabel, "Desloc.:  " + Sign + Mamute_Hex2(AbsOff))
EndProcedure

Procedure MamuteDump_Open(ParentWindow, StartAddr.i, StartOffset.i)
  Protected State.MamuteDumpState
  State\BaseAddr = StartAddr & $FFFF
  State\Offset = StartOffset
  State\CursorRow = 0
  State\CursorCol = 0
  State\CursorBlock = 0
  State\EditMode = #MamuteDump_EditMode_None

  ; Mesma fonte configurada em "Configurar -> Mamute Assembler..." (nao
  ; fixa Consolas de novo - ver MamuteFontName/Size/Bold, MamuteSupport.pbi).
  Protected DumpStyle.i = 0
  If MamuteFontBold : DumpStyle = #PB_Font_Bold : EndIf
  Protected DumpFont = LoadFont(#PB_Any, MamuteFontName, MamuteFontSize, DumpStyle)
  If Not DumpFont
    DumpFont = LoadFont(#PB_Any, "Consolas", 14, #PB_Font_Bold)
  EndIf

  Protected CharW, CharH, AddrLabelW, GapW
  Protected MeasureImg = CreateImage(#PB_Any, 10, 10)
  If MeasureImg And StartDrawing(ImageOutput(MeasureImg))
    DrawingFont(FontID(DumpFont))
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

  ; Largura da fileira de botoes calculada andando com CurX (mais robusto
  ; que somar uma formula fixa na mao) - decide se a janela precisa ser mais
  ; larga que a grade em si.
  Protected RowW = 56 + BtnGap + BtnH + BtnGap + BtnH + BtnGap + BtnH + BtnGap + BtnH + BtnGap + 56 + BtnGap * 3 + 36 + BtnGap + 36

  Protected WinW = GridW + Margin * 2
  If RowW + Margin * 2 > WinW
    WinW = RowW + Margin * 2
  EndIf

  Protected LegendH = 20, StatusH = 24
  Protected WinH = Margin + LegendH + 8 + GridH + 12 + StatusH + 4 + StatusH + 12 + BtnH + Margin

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Mamute Assembler - DM",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #True, #False)
  If Not Win
    ProcedureReturn
  EndIf
  SetWindowColor(Win, Mamute_CurrentBorderColor())

  Protected ColFront = Mamute_CurrentFrontColor(), ColBack = Mamute_CurrentBackColor()
  Protected CurY = Margin

  Protected G_Legend = TextGadget(#PB_Any, Margin, CurY, WinW - Margin * 2, LegendH,
                                  "Setas/PgUp/PgDn: mover  TAB: hex/texto  RETURN: editar  ESC: sair  +/-: desloc.")
  SetGadgetColor(G_Legend, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Legend, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Legend, FontID(DumpFont))
  CurY + LegendH + 8

  Protected GridY = CurY
  Protected G_Grid = CanvasGadget(#PB_Any, Margin, GridY, GridW, GridH, #PB_Canvas_Keyboard)
  CurY + GridH + 12

  Protected G_AddrLabel = TextGadget(#PB_Any, Margin, CurY, 260, StatusH, "")
  SetGadgetColor(G_AddrLabel, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_AddrLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_AddrLabel, FontID(DumpFont))
  CurY + StatusH + 4

  Protected G_OffsetLabel = TextGadget(#PB_Any, Margin, CurY, 260, StatusH, "")
  SetGadgetColor(G_OffsetLabel, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_OffsetLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_OffsetLabel, FontID(DumpFont))

  Protected G_EditLabel = TextGadget(#PB_Any, 300, CurY, 70, StatusH, "Editar:")
  SetGadgetColor(G_EditLabel, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_EditLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_EditLabel, FontID(DumpFont))
  Protected G_EditField = StringGadget(#PB_Any, 372, CurY - 2, WinW - 372 - Margin, StatusH + 4, "")
  SetGadgetColor(G_EditField, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_EditField, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_EditField, FontID(DumpFont))
  HideGadget(G_EditLabel, #True)
  HideGadget(G_EditField, #True)
  CurY + StatusH + 12

  ; Fonte reduzida pros botoes (o label de 1-2 caracteres nao precisa do
  ; tamanho configurado, que pode ser grande) - Consolas fixa aqui de
  ; proposito, so pro desenho do simbolo dentro do botao, nao pro texto do
  ; monitor em si.
  Protected BtnFont = LoadFont(#PB_Any, "Consolas", 14, #PB_Font_Bold)
  If Not BtnFont : BtnFont = DumpFont : EndIf

  Protected NewOff.i ; usado por MamuteDump_DoOffset abaixo - hoisted pra fora da macro
                      ; de proposito, pra nao redeclarar "Protected" a cada uma das 4
                      ; expansoes dela (botoes +/- e atalhos de teclado +/-)

  Protected BtnY = CurY
  Protected CurX = Margin
  Protected G_PageLeft = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH)  : CurX + 56 + BtnGap
  Protected G_ArrowLeft = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH) : CurX + BtnH + BtnGap
  Protected G_ArrowUp = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH) : CurX + BtnH + BtnGap
  Protected G_ArrowDown = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH) : CurX + BtnH + BtnGap
  Protected G_ArrowRight = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH) : CurX + BtnH + BtnGap
  Protected G_PageRight = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH) : CurX + 56 + BtnGap * 3
  Protected G_MinusBtn = CanvasGadget(#PB_Any, CurX, BtnY, 36, BtnH) : CurX + 36 + BtnGap
  Protected G_PlusBtn = CanvasGadget(#PB_Any, CurX, BtnY, 36, BtnH)

  MamuteDump_DrawButton(G_PageLeft, "<<", BtnFont)
  MamuteDump_DrawButton(G_ArrowLeft, "<", BtnFont)
  MamuteDump_DrawButton(G_ArrowUp, "^", BtnFont)
  MamuteDump_DrawButton(G_ArrowDown, "v", BtnFont)
  MamuteDump_DrawButton(G_ArrowRight, ">", BtnFont)
  MamuteDump_DrawButton(G_PageRight, ">>", BtnFont)
  MamuteDump_DrawButton(G_MinusBtn, "-", BtnFont)
  MamuteDump_DrawButton(G_PlusBtn, "+", BtnFont)
  GadgetToolTip(G_PageLeft, "-128 bytes")
  GadgetToolTip(G_PageRight, "+128 bytes")
  GadgetToolTip(G_MinusBtn, "Desloc. -1")
  GadgetToolTip(G_PlusBtn, "Desloc. +1")

  MamuteDump_UpdateStatus(G_AddrLabel, G_OffsetLabel, @State)
  MamuteDump_Repaint(G_Grid, @State, HexX, AsciiX, CharW, CharH, HalfCharW)
  SetActiveGadget(G_Grid)

  AddKeyboardShortcut(Win, #PB_Shortcut_Up, #MamuteDump_Shortcut_Up)
  AddKeyboardShortcut(Win, #PB_Shortcut_Down, #MamuteDump_Shortcut_Down)
  AddKeyboardShortcut(Win, #PB_Shortcut_Left, #MamuteDump_Shortcut_Left)
  AddKeyboardShortcut(Win, #PB_Shortcut_Right, #MamuteDump_Shortcut_Right)
  AddKeyboardShortcut(Win, #PB_Shortcut_PageUp, #MamuteDump_Shortcut_PageUp)
  AddKeyboardShortcut(Win, #PB_Shortcut_PageDown, #MamuteDump_Shortcut_PageDown)
  AddKeyboardShortcut(Win, #PB_Shortcut_Tab, #MamuteDump_Shortcut_Tab)
  AddKeyboardShortcut(Win, #PB_Shortcut_Return, #MamuteDump_Shortcut_Return)
  AddKeyboardShortcut(Win, #PB_Shortcut_Escape, #MamuteDump_Shortcut_Escape)
  AddKeyboardShortcut(Win, #PB_Shortcut_Add, #MamuteDump_Shortcut_Add)
  AddKeyboardShortcut(Win, #PB_Shortcut_Subtract, #MamuteDump_Shortcut_Sub)

  ; Macros (nao Procedures) de proposito - acessam direto as locais desta
  ; janela (State, gadgets), mesmo idioma de outras janelas do projeto
  ; (ex.: NBHelpGui_DoGoBack).

  Macro MamuteDump_DoRepaint
    MamuteDump_UpdateStatus(G_AddrLabel, G_OffsetLabel, @State)
    MamuteDump_Repaint(G_Grid, @State, HexX, AsciiX, CharW, CharH, HalfCharW)
  EndMacro

  Macro MamuteDump_DoMove(DRow, DCol)
    If State\EditMode = #MamuteDump_EditMode_None
      State\CursorRow + (DRow)
      State\CursorCol + (DCol)
      MamuteDump_ClampCursor(@State)
      MamuteDump_DoRepaint
    EndIf
  EndMacro

  Macro MamuteDump_DoPage(Delta)
    State\BaseAddr = (State\BaseAddr + (Delta)) & $FFFF
    MamuteDump_DoRepaint
  EndMacro

  Macro MamuteDump_DoOffset(Delta)
    NewOff = State\Offset + (Delta)
    If NewOff < -$7F : NewOff = -$7F : EndIf
    If NewOff > $80 : NewOff = $80 : EndIf
    State\Offset = NewOff
    MamuteDump_DoRepaint
  EndMacro

  ; RETURN, estagio 1 (nao editando ainda): abre o campo de edicao pro
  ; bloco ativo (hex ou texto), pre-preenchido com o valor atual da celula
  ; sob o cursor - mesma conveniencia de HexEditorGui.pbi.
  Macro MamuteDump_BeginEdit
    Protected EditAddr.i = MamuteDump_CellAddr(@State, State\CursorRow, State\CursorCol)
    Protected EditRaw.a = Mamute_ReadByte(EditAddr)
    If State\CursorBlock = 0
      State\EditMode = #MamuteDump_EditMode_Hex
      SetGadgetText(G_EditLabel, "Hex:")
      SetGadgetText(G_EditField, Mamute_Hex2(EditRaw))
    Else
      State\EditMode = #MamuteDump_EditMode_Text
      SetGadgetText(G_EditLabel, "Texto:")
      SetGadgetText(G_EditField, MamuteDump_DisplayChar(EditRaw, State\Offset))
    EndIf
    HideGadget(G_EditLabel, #False)
    HideGadget(G_EditField, #False)
    SetActiveGadget(G_EditField)
  EndMacro

  Macro MamuteDump_CancelEdit
    State\EditMode = #MamuteDump_EditMode_None
    HideGadget(G_EditLabel, #True)
    HideGadget(G_EditField, #True)
    SetGadgetText(G_EditField, "")
    SetActiveGadget(G_Grid)
  EndMacro

  ; RETURN, estagio 2 (ja editando): confirma o texto digitado.
  ; Hex: exatamente 1-2 digitos hex, vira 1 byte cru na celula do cursor.
  ; Texto: 1+ caracteres, cada um vira RawByte=(Char-Offset)&FF, escritos em
  ; enderecos sucessivos a partir do cursor (avanca o cursor pelo tanto
  ; digitado, ate o fim da grade). Celulas mapeadas em slot que nao e RAM
  ; (ROM/BASIC/Vazio) sao ignoradas silenciosamente por byte (Mamute_WriteByte
  ; devolve #False) - texto real continua sendo escrito nas posicoes que sao
  ; RAM de verdade.
  Macro MamuteDump_CommitEdit
    Protected Typed.s = GetGadgetText(G_EditField)
    If State\EditMode = #MamuteDump_EditMode_Hex
      If Mamute_IsHexString(Typed, 2)
        Protected HexAddr.i = MamuteDump_CellAddr(@State, State\CursorRow, State\CursorCol)
        Mamute_WriteByte(HexAddr, Val("$" + Typed) & $FF)
        MamuteDump_CancelEdit
        MamuteDump_DoRepaint
      EndIf
    ElseIf State\EditMode = #MamuteDump_EditMode_Text And Typed <> ""
      Protected TIdx.i, TAddr.i, TCell.i = State\CursorRow * 8 + State\CursorCol
      For TIdx = 1 To Len(Typed)
        If TCell > 127 : Break : EndIf
        TAddr = MamuteDump_CellAddr(@State, TCell / 8, TCell % 8)
        Mamute_WriteByte(TAddr, (Asc(Mid(Typed, TIdx, 1)) - State\Offset) & $FF)
        TCell + 1
      Next
      If TCell > 127 : TCell = 127 : EndIf
      State\CursorRow = TCell / 8
      State\CursorCol = TCell % 8
      MamuteDump_CancelEdit
      MamuteDump_DoRepaint
    EndIf
  EndMacro

  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_Grid
            If EventType() = #PB_EventType_LeftButtonDown And State\EditMode = #MamuteDump_EditMode_None
              Protected MouseX = GetGadgetAttribute(G_Grid, #PB_Canvas_MouseX)
              Protected MouseY = GetGadgetAttribute(G_Grid, #PB_Canvas_MouseY)
              Protected HitRow.i, HitCol.i, HitBlock.i
              If MamuteDump_HitTest(MouseX, MouseY, HexX, AsciiX, CharW, CharH, HalfCharW, @HitRow, @HitCol, @HitBlock)
                State\CursorRow = HitRow
                State\CursorCol = HitCol
                State\CursorBlock = HitBlock
                MamuteDump_DoRepaint
              EndIf
            EndIf

          Case G_ArrowUp
            If EventType() = #PB_EventType_LeftButtonDown : MamuteDump_DoMove(-1, 0) : EndIf
          Case G_ArrowDown
            If EventType() = #PB_EventType_LeftButtonDown : MamuteDump_DoMove(1, 0) : EndIf
          Case G_ArrowLeft
            If EventType() = #PB_EventType_LeftButtonDown : MamuteDump_DoMove(0, -1) : EndIf
          Case G_ArrowRight
            If EventType() = #PB_EventType_LeftButtonDown : MamuteDump_DoMove(0, 1) : EndIf
          Case G_PageLeft
            If EventType() = #PB_EventType_LeftButtonDown : MamuteDump_DoPage(-128) : EndIf
          Case G_PageRight
            If EventType() = #PB_EventType_LeftButtonDown : MamuteDump_DoPage(128) : EndIf
          Case G_MinusBtn
            If EventType() = #PB_EventType_LeftButtonDown : MamuteDump_DoOffset(-1) : EndIf
          Case G_PlusBtn
            If EventType() = #PB_EventType_LeftButtonDown : MamuteDump_DoOffset(1) : EndIf
        EndSelect

      Case #PB_Event_Menu
        Select EventMenu()
          Case #MamuteDump_Shortcut_Up     : MamuteDump_DoMove(-1, 0)
          Case #MamuteDump_Shortcut_Down   : MamuteDump_DoMove(1, 0)
          Case #MamuteDump_Shortcut_Left   : MamuteDump_DoMove(0, -1)
          Case #MamuteDump_Shortcut_Right  : MamuteDump_DoMove(0, 1)
          Case #MamuteDump_Shortcut_PageUp   : If State\EditMode = #MamuteDump_EditMode_None : MamuteDump_DoPage(-128) : EndIf
          Case #MamuteDump_Shortcut_PageDown : If State\EditMode = #MamuteDump_EditMode_None : MamuteDump_DoPage(128) : EndIf
          Case #MamuteDump_Shortcut_Add : If State\EditMode = #MamuteDump_EditMode_None : MamuteDump_DoOffset(1) : EndIf
          Case #MamuteDump_Shortcut_Sub : If State\EditMode = #MamuteDump_EditMode_None : MamuteDump_DoOffset(-1) : EndIf

          Case #MamuteDump_Shortcut_Tab
            If State\EditMode = #MamuteDump_EditMode_None
              If State\CursorBlock = 0 : State\CursorBlock = 1 : Else : State\CursorBlock = 0 : EndIf
              MamuteDump_DoRepaint
            EndIf

          Case #MamuteDump_Shortcut_Return
            If State\EditMode = #MamuteDump_EditMode_None
              MamuteDump_BeginEdit
            Else
              MamuteDump_CommitEdit
            EndIf

          Case #MamuteDump_Shortcut_Escape
            If State\EditMode <> #MamuteDump_EditMode_None
              MamuteDump_CancelEdit
            Else
              Quit = #True
            EndIf
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
