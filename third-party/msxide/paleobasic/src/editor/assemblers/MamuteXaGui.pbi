;
; ------------------------------------------------------------
;  Comando XA do Mamute Assembler - porta do comando A do monitor SUPER-X
;  (docs/SPEC.md modulo 45/45h, others/superx/SUPER-X.DOC.pdf, secao
;  "Listing/editing in ASCII"). Batizado XA (nao A) pelo mesmo motivo do XD/
;  XM - decisao explicita do usuario, pedido nesta mesma sessao: "ele e
;  igual ao XD (e vai ser XA mesmo)".
;
;  Ao contrario do XD (grade hexa+ASCII, bloco ASCII editavel MISTURADO com
;  hexa), o XA e' uma tela nova dedicada, SO' texto ASCII - decisao explicita
;  do usuario via pergunta direta antes de codar ("Construir tela nova so'
;  ASCII", nao reaproveitar a grade do XD). Grade 16x16 = 256 bytes por tela
;  (nao 16x8/128 como o XD) - tamanho escolhido pra bater exatamente com o
;  novo default de "sem <fim>, assume 256 bytes" (docs/SPEC.md modulo 45g/
;  45h) - uma tela cheia do XA = exatamente o range default de um XA/XD sem
;  <fim>.
;
;  Digitacao: QUALQUER caractere imprimivel escreve o byte cru sob o cursor e
;  avanca sozinho - AO CONTRARIO do XD, aqui nao existe um modo de
;  "digitacao ASCII" separado pra entrar/sair (tecla "), porque a tela
;  INTEIRA e' so' ASCII o tempo todo. Por isso tambem NAO existe o atalho "@"
;  (repete byte anterior) do XD - la' ele so' fazia sentido no bloco HEXA
;  (fora do modo de digitacao ASCII); aqui, "@" e' so' mais um caractere
;  digitavel (codigo 64), igual qualquer outro. Sem "Offset" tambem (o XD usa
;  Offset pra reinterpretar a coluna ASCII sem mexer nos bytes - conceito que
;  so' faz sentido ao lado de uma coluna hexa "crua"; o XA mostra o byte cru
;  direto, sem reinterpretacao).
;
;  Duas ou tres enderecos (`XA <endinic>,<endfim>[,<arquivo>]`) - MESMO
;  mecanismo do XD (docs/SPEC.md modulo 45g): sem <arquivo>, despejo de texto
;  PURO ASCII pro log (Mamute_BuildAsciiDumpLines, MamuteSupport.pbi, 64
;  bytes/linha); com <arquivo>, abre a MESMA janela do comando SAVE do MON>
;  com os bytes crus do intervalo. MamuteGui_CmdXa (MamuteAssemblerGui.pbi)
;  implementa isso directly, nao usa nada deste arquivo (que so' cobre a
;  grade interativa de UM endereco).
;
;  Cruz de modos (mesma cruz do XD, docs/SPEC.md modulo 45f/45h) - aqui
;  **Ascii** e' o modo ativo (destaque solido); **Dump**/**Multi**/**Disasm**/
;  **Char** ligam de volta pro XD/XM/XI/XH (MamuteXd_Open/MamuteXm_Open/
;  MamuteXi_Open/MamuteXh_Open) - os quatro modos da cruz ja existem de
;  verdade agora, nenhum placeholder restante.
; ------------------------------------------------------------
;

#MamuteXa_Shortcut_Up       = 9750
#MamuteXa_Shortcut_Down     = 9751
#MamuteXa_Shortcut_Left     = 9752
#MamuteXa_Shortcut_Right    = 9753
#MamuteXa_Shortcut_PageUp   = 9754
#MamuteXa_Shortcut_PageDown = 9755
#MamuteXa_Shortcut_Return   = 9756
#MamuteXa_Shortcut_Escape   = 9757

Structure MamuteXaState
  BaseAddr.i     ; endereco do primeiro byte mostrado (linha 0, coluna 0) - 0-65535 (RAM/slot) ou 0-192KB (VRAM)
  CursorRow.i    ; 0-15
  CursorCol.i    ; 0-15
  Target.MamuteSxTarget ; alvo resolvido (PAGE corrente/slot explicito/sub-slot/VRAM) - ver topo do arquivo
EndStructure

Procedure MamuteXa_ClampCursor(*State.MamuteXaState)
  If *State\CursorRow < 0 : *State\CursorRow = 0 : EndIf
  If *State\CursorRow > 15 : *State\CursorRow = 15 : EndIf
  If *State\CursorCol < 0 : *State\CursorCol = 0 : EndIf
  If *State\CursorCol > 15 : *State\CursorCol = 15 : EndIf
EndProcedure

Procedure.i MamuteXa_CellAddr(*State.MamuteXaState, Row.i, Col.i)
  ProcedureReturn Mamute_SxWrapAddr(*State\BaseAddr + Row * 16 + Col, @*State\Target)
EndProcedure

Procedure.s MamuteXa_DisplayChar(RawByte.a)
  If RawByte >= 32 And RawByte <= 126
    ProcedureReturn Chr(RawByte)
  EndIf
  ProcedureReturn "."
EndProcedure

; Avanca o cursor uma celula (linha a linha, 16 colunas) - mesma ordem/
; comportamento de saturacao no fim da tela que MamuteXd_AdvanceCursor().
Procedure MamuteXa_AdvanceCursor(*State.MamuteXaState)
  *State\CursorCol + 1
  If *State\CursorCol > 15
    *State\CursorCol = 0
    *State\CursorRow + 1
    If *State\CursorRow > 15
      *State\CursorRow = 15
      *State\CursorCol = 15
    EndIf
  EndIf
EndProcedure

Procedure MamuteXa_Repaint(Canvas, *State.MamuteXaState, GridX.i, CharW.i, CharH.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf

  Protected ColBack        = Mamute_CurrentBackColor()
  Protected ColFront       = Mamute_CurrentFrontColor()
  Protected ColDim         = RGB(25, 110, 50)
  Protected ColCursorBack  = Mamute_CurrentFrontColor()
  Protected ColCursorFront = Mamute_CurrentBackColor()

  Box(0, 0, GadgetWidth(Canvas), GadgetHeight(Canvas), ColBack)

  Protected r.i, c.i, RowAddr.i, ByteAddr.i, RawByte.a, cx.i, RowY.i
  Protected AddrDigits.i = 4
  If *State\Target\IsVram : AddrDigits = 5 : EndIf

  For r = 0 To 15
    RowY = r * CharH
    RowAddr = MamuteXa_CellAddr(*State, r, 0)
    DrawText(0, RowY, Mamute_HexPad(RowAddr, AddrDigits) + ":", ColDim, ColBack)

    For c = 0 To 15
      ByteAddr = MamuteXa_CellAddr(*State, r, c)
      RawByte = Mamute_SxReadByte(ByteAddr, @*State\Target)
      cx = GridX + c * CharW
      If r = *State\CursorRow And c = *State\CursorCol
        Box(cx - 1, RowY - 1, CharW + 1, CharH - 1, ColCursorBack)
        DrawText(cx, RowY, MamuteXa_DisplayChar(RawByte), ColCursorFront, ColCursorBack)
      Else
        DrawText(cx, RowY, MamuteXa_DisplayChar(RawByte), ColFront, ColBack)
      EndIf
    Next
  Next

  StopDrawing()
EndProcedure

Procedure.b MamuteXa_HitTest(MouseX.i, MouseY.i, GridX.i, CharW.i, CharH.i, *OutRow.Integer, *OutCol.Integer)
  Protected Row.i = MouseY / CharH
  If Row < 0 Or Row > 15
    ProcedureReturn #False
  EndIf
  Protected c.i, cx.i
  For c = 0 To 15
    cx = GridX + c * CharW
    If MouseX >= cx - 1 And MouseX < cx + CharW
      *OutRow\i = Row : *OutCol\i = c
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

Procedure MamuteXa_UpdateStatus(G_AddrLabel, G_ModeLabel, *State.MamuteXaState)
  Protected AddrDigits.i = 4
  If *State\Target\IsVram : AddrDigits = 5 : EndIf
  SetGadgetText(G_AddrLabel, "Endereco: " + Mamute_HexPad(*State\BaseAddr, AddrDigits) + Mamute_SxTargetSuffixText(@*State\Target))
  SetGadgetText(G_ModeLabel, "Modo: navegacao")
EndProcedure

; Devolve o BaseAddr final (endereco onde a janela ficou ao fechar) - quem
; chama guarda isso pra "sem argumento, continua daqui" (mesmo idioma do
; XD/XM). *StartTarget - alvo ja resolvido (Mamute_ParseSxAddr,
; MamuteAssemblerGui.pbi) - PAGE corrente, slot/sub-slot explicito ou VRAM; a
; sessao inteira da grade fica presa nesse alvo (mesma regra do XD).
Procedure.i MamuteXa_Open(ParentWindow, StartAddr.i, *StartTarget.MamuteSxTarget)
  Protected State.MamuteXaState
  CopyStructure(*StartTarget, @State\Target, MamuteSxTarget)
  State\BaseAddr = Mamute_SxWrapAddr(StartAddr, @State\Target)
  State\CursorRow = 0
  State\CursorCol = 0

  Protected Title.s = "Mamute Assembler - XA (SUPER-X)"
  Protected TargetSuffix.s = Mamute_SxTargetSuffixText(@State\Target)
  If TargetSuffix <> "" : Title + " " + TargetSuffix : EndIf

  Protected MStyle.i = 0
  If MamuteFontBold : MStyle = #PB_Font_Bold : EndIf
  Protected MFont = LoadFont(#PB_Any, MamuteFontName, MamuteFontSize, MStyle)
  If Not MFont
    MFont = LoadFont(#PB_Any, "Consolas", 14, #PB_Font_Bold)
  EndIf

  Protected BtnFont = LoadFont(#PB_Any, "Consolas", 14, #PB_Font_Bold)
  If Not BtnFont : BtnFont = MFont : EndIf

  Protected CharW, CharH, AddrLabelW
  Protected MeasureImg = CreateImage(#PB_Any, 10, 10)
  If MeasureImg And StartDrawing(ImageOutput(MeasureImg))
    DrawingFont(FontID(MFont))
    CharW = TextWidth("0") + 4
    CharH = TextHeight("0") + 4
    AddrLabelW = TextWidth("0000: ")
    StopDrawing()
  EndIf
  If MeasureImg : FreeImage(MeasureImg) : EndIf
  If CharW <= 0 : CharW = 14 : EndIf
  If CharH <= 0 : CharH = 20 : EndIf
  If AddrLabelW <= 0 : AddrLabelW = 60 : EndIf

  Protected GridX = AddrLabelW
  Protected GridW = GridX + 16 * CharW + 16
  Protected GridH = 16 * CharH

  Protected Margin = 16
  Protected BtnH = 40, BtnGap = 8

  ; Cruz de modos (mesma cruz do XD, ver comentario no topo do arquivo) -
  ; aqui Ascii e' o modo ATIVO; Dump/Multi ligam de verdade pro XD/XM;
  ; Char/Disasm continuam placeholder.
  Protected ModeBtnW = 76, ModeBtnH = 34, ModeBtnGap = 6
  Protected ModeGapX = 24
  Protected ModeCrossW = ModeBtnW * 3 + ModeBtnGap * 2
  Protected ModeCrossH = ModeBtnH * 3 + ModeBtnGap * 2
  Protected ModeCrossX = Margin + GridW + ModeGapX
  Protected ModeCrossCol0 = ModeCrossX
  Protected ModeCrossCol1 = ModeCrossX + ModeBtnW + ModeBtnGap
  Protected ModeCrossCol2 = ModeCrossX + (ModeBtnW + ModeBtnGap) * 2

  Protected WinW = GridW + ModeGapX + ModeCrossW + Margin * 2
  Protected RowW = 56 + BtnGap + BtnH + BtnGap + BtnH + BtnGap + BtnH + BtnGap + BtnH + BtnGap + 56 + Margin * 2
  If RowW > WinW
    WinW = RowW
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

  Protected LegendTxt.s = "Setas/PgUp/PgDn: mover  Qualquer caractere: digita direto  RETURN/ESC: sai"
  Protected G_Legend = TextGadget(#PB_Any, Margin, CurY, WinW - Margin * 2, LegendH, LegendTxt)
  SetGadgetColor(G_Legend, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Legend, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Legend, FontID(MFont))
  CurY + LegendH + 8

  Protected GridY = CurY
  Protected G_Grid = CanvasGadget(#PB_Any, Margin, GridY, GridW, GridH, #PB_Canvas_Keyboard)
  CurY + GridH + 12

  Protected ModeCrossY = GridY + (GridH - ModeCrossH) / 2
  Protected ModeRow0 = ModeCrossY
  Protected ModeRow1 = ModeCrossY + ModeBtnH + ModeBtnGap
  Protected ModeRow2 = ModeCrossY + (ModeBtnH + ModeBtnGap) * 2

  Protected G_ModeDump   = CanvasGadget(#PB_Any, ModeCrossCol1, ModeRow0, ModeBtnW, ModeBtnH)
  Protected G_ModeAscii  = CanvasGadget(#PB_Any, ModeCrossCol0, ModeRow1, ModeBtnW, ModeBtnH)
  Protected G_ModeChar   = CanvasGadget(#PB_Any, ModeCrossCol1, ModeRow1, ModeBtnW, ModeBtnH)
  Protected G_ModeMulti  = CanvasGadget(#PB_Any, ModeCrossCol2, ModeRow1, ModeBtnW, ModeBtnH)
  Protected G_ModeDisasm = CanvasGadget(#PB_Any, ModeCrossCol1, ModeRow2, ModeBtnW, ModeBtnH)

  MamuteXd_DrawModeButton(G_ModeDump, "Dump", BtnFont, 0)    ; ja liga com XD de verdade
  MamuteXd_DrawModeButton(G_ModeAscii, "Ascii", BtnFont, 1)  ; ja e' o modo ativo agora
  MamuteXd_DrawModeButton(G_ModeChar, "Char", BtnFont, 0)    ; ja liga com XH de verdade
  MamuteXd_DrawModeButton(G_ModeMulti, "Multi", BtnFont, 0)  ; ja liga com XM de verdade
  MamuteXd_DrawModeButton(G_ModeDisasm, "Disasm", BtnFont, 0) ; ja liga com XI de verdade
  GadgetToolTip(G_ModeDump, "Modo Dump - abre o XD neste mesmo endereco/alvo")
  GadgetToolTip(G_ModeAscii, "Modo Ascii (esta tela) - ja ativo")
  GadgetToolTip(G_ModeChar, "Modo Char - abre o XH neste mesmo endereco/alvo")
  GadgetToolTip(G_ModeMulti, "Modo Multi - abre o XM neste mesmo endereco/alvo")
  GadgetToolTip(G_ModeDisasm, "Modo Disasm - abre o XI neste mesmo endereco/alvo")

  Protected G_AddrLabel = TextGadget(#PB_Any, Margin, CurY, 260, StatusH, "")
  SetGadgetColor(G_AddrLabel, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_AddrLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_AddrLabel, FontID(MFont))
  CurY + StatusH + 4

  Protected G_ModeLabel = TextGadget(#PB_Any, Margin, CurY, 360, StatusH, "")
  SetGadgetColor(G_ModeLabel, #PB_Gadget_FrontColor, RGB(220, 160, 40))
  SetGadgetColor(G_ModeLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_ModeLabel, FontID(MFont))
  CurY + StatusH + 12

  Protected BtnY = CurY
  Protected CurX = Margin
  Protected G_PageLeft = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH)   : CurX + 56 + BtnGap
  Protected G_ArrowLeft = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH)  : CurX + BtnH + BtnGap
  Protected G_ArrowUp = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH)    : CurX + BtnH + BtnGap
  Protected G_ArrowDown = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH)  : CurX + BtnH + BtnGap
  Protected G_ArrowRight = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH) : CurX + BtnH + BtnGap
  Protected G_PageRight = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH)

  MamuteXd_DrawButton(G_PageLeft, "<<", BtnFont)
  MamuteXd_DrawButton(G_ArrowLeft, "<", BtnFont)
  MamuteXd_DrawButton(G_ArrowUp, "^", BtnFont)
  MamuteXd_DrawButton(G_ArrowDown, "v", BtnFont)
  MamuteXd_DrawButton(G_ArrowRight, ">", BtnFont)
  MamuteXd_DrawButton(G_PageRight, ">>", BtnFont)
  GadgetToolTip(G_PageLeft, "-256 bytes")
  GadgetToolTip(G_PageRight, "+256 bytes")

  MamuteXa_UpdateStatus(G_AddrLabel, G_ModeLabel, @State)
  MamuteXa_Repaint(G_Grid, @State, GridX, CharW, CharH)
  SetActiveGadget(G_Grid)

  AddKeyboardShortcut(Win, #PB_Shortcut_Up, #MamuteXa_Shortcut_Up)
  AddKeyboardShortcut(Win, #PB_Shortcut_Down, #MamuteXa_Shortcut_Down)
  AddKeyboardShortcut(Win, #PB_Shortcut_Left, #MamuteXa_Shortcut_Left)
  AddKeyboardShortcut(Win, #PB_Shortcut_Right, #MamuteXa_Shortcut_Right)
  AddKeyboardShortcut(Win, #PB_Shortcut_PageUp, #MamuteXa_Shortcut_PageUp)
  AddKeyboardShortcut(Win, #PB_Shortcut_PageDown, #MamuteXa_Shortcut_PageDown)
  AddKeyboardShortcut(Win, #PB_Shortcut_Up | #PB_Shortcut_Shift, #MamuteXa_Shortcut_PageUp)
  AddKeyboardShortcut(Win, #PB_Shortcut_Down | #PB_Shortcut_Shift, #MamuteXa_Shortcut_PageDown)
  AddKeyboardShortcut(Win, #PB_Shortcut_Return, #MamuteXa_Shortcut_Return)
  AddKeyboardShortcut(Win, #PB_Shortcut_Escape, #MamuteXa_Shortcut_Escape)

  Macro MamuteXa_DoRepaint
    MamuteXa_UpdateStatus(G_AddrLabel, G_ModeLabel, @State)
    MamuteXa_Repaint(G_Grid, @State, GridX, CharW, CharH)
  EndMacro

  Macro MamuteXa_DoMove(DRow, DCol)
    State\CursorRow + (DRow)
    State\CursorCol + (DCol)
    MamuteXa_ClampCursor(@State)
    MamuteXa_DoRepaint
  EndMacro

  Macro MamuteXa_DoPage(Delta)
    State\BaseAddr = Mamute_SxWrapAddr(State\BaseAddr + (Delta), @State\Target)
    MamuteXa_DoRepaint
  EndMacro

  Protected Event, Quit = #False
  Protected AlreadyClosed.b = #False ; #True quando um botao da cruz ja fechou a janela na hora
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_Grid
            Select EventType()
              Case #PB_EventType_LeftButtonDown
                Protected MouseX = GetGadgetAttribute(G_Grid, #PB_Canvas_MouseX)
                Protected MouseY = GetGadgetAttribute(G_Grid, #PB_Canvas_MouseY)
                Protected HitRow.i, HitCol.i
                If MamuteXa_HitTest(MouseX, MouseY, GridX, CharW, CharH, @HitRow, @HitCol)
                  State\CursorRow = HitRow
                  State\CursorCol = HitCol
                  MamuteXa_DoRepaint
                EndIf

              ; Qualquer caractere imprimivel escreve direto e avanca - nao
              ; existe "modo de digitacao" separado aqui (ver comentario no
              ; topo do arquivo), ao contrario do XD.
              Case #PB_EventType_Input
                Protected TypedCode.i = GetGadgetAttribute(G_Grid, #PB_Canvas_Input)
                If TypedCode >= 32 And TypedCode <= 126
                  Mamute_SxWriteByte(MamuteXa_CellAddr(@State, State\CursorRow, State\CursorCol),
                                     TypedCode & $FF, @State\Target)
                  MamuteXa_AdvanceCursor(@State)
                  MamuteXa_DoRepaint
                EndIf
            EndSelect

          Case G_ArrowUp    : If EventType() = #PB_EventType_LeftButtonDown : MamuteXa_DoMove(-1, 0) : EndIf
          Case G_ArrowDown  : If EventType() = #PB_EventType_LeftButtonDown : MamuteXa_DoMove(1, 0) : EndIf
          Case G_ArrowLeft  : If EventType() = #PB_EventType_LeftButtonDown : MamuteXa_DoMove(0, -1) : EndIf
          Case G_ArrowRight : If EventType() = #PB_EventType_LeftButtonDown : MamuteXa_DoMove(0, 1) : EndIf
          Case G_PageLeft   : If EventType() = #PB_EventType_LeftButtonDown : MamuteXa_DoPage(-256) : EndIf
          Case G_PageRight  : If EventType() = #PB_EventType_LeftButtonDown : MamuteXa_DoPage(256) : EndIf

          ; Cruz de modos (ver comentario no topo do arquivo) - Ascii ja e' o
          ; modo ativo (clique nao faz nada); Dump/Multi/Disasm/Char trocam
          ; de verdade pro XD/XM/XI/XH, no MESMO endereco/alvo.
          Case G_ModeAscii
            ; ja e' o modo ativo - nada a fazer

          Case G_ModeDump
            If EventType() = #PB_EventType_LeftButtonDown
              CloseModelessChildWindow(ParentWindow, Win)
              AlreadyClosed = #True
              State\BaseAddr = MamuteXd_Open(ParentWindow, State\BaseAddr, 0, @State\Target)
              Quit = #True
            EndIf

          Case G_ModeMulti
            If EventType() = #PB_EventType_LeftButtonDown
              CloseModelessChildWindow(ParentWindow, Win)
              AlreadyClosed = #True
              State\BaseAddr = MamuteXm_Open(ParentWindow, State\BaseAddr, @State\Target)
              Quit = #True
            EndIf

          Case G_ModeChar
            If EventType() = #PB_EventType_LeftButtonDown
              CloseModelessChildWindow(ParentWindow, Win)
              AlreadyClosed = #True
              State\BaseAddr = MamuteXh_Open(ParentWindow, State\BaseAddr, @State\Target)
              Quit = #True
            EndIf

          Case G_ModeDisasm
            If EventType() = #PB_EventType_LeftButtonDown
              CloseModelessChildWindow(ParentWindow, Win)
              AlreadyClosed = #True
              State\BaseAddr = MamuteXi_Open(ParentWindow, State\BaseAddr, @State\Target)
              Quit = #True
            EndIf
        EndSelect

      Case #PB_Event_Menu
        Select EventMenu()
          Case #MamuteXa_Shortcut_Up     : MamuteXa_DoMove(-1, 0)
          Case #MamuteXa_Shortcut_Down   : MamuteXa_DoMove(1, 0)
          Case #MamuteXa_Shortcut_Left   : MamuteXa_DoMove(0, -1)
          Case #MamuteXa_Shortcut_Right  : MamuteXa_DoMove(0, 1)
          Case #MamuteXa_Shortcut_PageUp   : MamuteXa_DoPage(-256)
          Case #MamuteXa_Shortcut_PageDown : MamuteXa_DoPage(256)
          Case #MamuteXa_Shortcut_Return : Quit = #True
          Case #MamuteXa_Shortcut_Escape : Quit = #True
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  If Not AlreadyClosed
    CloseModelessChildWindow(ParentWindow, Win)
  EndIf
  ProcedureReturn State\BaseAddr
EndProcedure
