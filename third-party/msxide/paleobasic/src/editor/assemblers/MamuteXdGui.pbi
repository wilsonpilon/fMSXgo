;
; ------------------------------------------------------------
;  Comando XD do Mamute Assembler - porta do comando D do monitor SUPER-X
;  (docs/SPEC.md modulo 45, others/superx/SUPER-X.DOC.pdf, secao "HexDump
;  editing / Listing"). Batizado XD (nao D) porque o Mamute ja tem seu
;  proprio D (despejo formatado pro log, herdado do MegaAssembler, modulo
;  31) com significado diferente - decisao explicita do usuario: "assim
;  temos o D e o M na versao do mamute e o XD e XM pra versao do SUPER-X".
;
;  Mesma grade 16x8 (128 bytes, hexa+ASCII) e mesma navegacao/infra de
;  MamuteMGui.pbi (M/S) - copiado e adaptado deliberadamente em vez de
;  acrescentar mais uma flag no arquivo compartilhado M/S, pra nao arriscar
;  regressao num comando ja testado (M/S) por causa de um terceiro modo bem
;  diferente. Diferencas do M/S:
;
;  - **Bloco ASCII tambem e editavel** (no M/S ele e so leitura) - pressionar
;    `"` (aspas) entra em "digitacao ASCII direta": cada tecla impressa
;    depois escreve ((codigo do char) - Offset) & FF no byte sob o cursor
;    (mesma formula ja usada pelo bloco de texto do DM) e avanca sozinho,
;    sem precisar de ENTER a cada caractere - bate com "{"} ASCII entry" da
;    doc do SUPER-X.
;  - **`@` repete o byte anterior** no bloco hexa (le o byte em endereco-1 e
;    grava no cursor, avancando) - "{@} Repeat previous byte" da doc.
;  - `"`/`@` NAO tem constante #PB_Shortcut_* no PureBasic (so 0-9/A-Z/F1-F24/
;    setas/etc, confirmado no help local do compilador,
;    addkeyboardshortcut.html) - capturados via #PB_EventType_Input no
;    CanvasGadget (#PB_Canvas_Keyboard), que devolve o CARACTERE de verdade
;    independente de layout, ao contrario de AddKeyboardShortcut/#PB_Canvas_Key
;    (que so devolve os mesmos #PB_Shortcut_* limitados). 0-9/A-F continuam via
;    AddKeyboardShortcut (mesmo mecanismo do M, ja comprovado).
;  - ESC tem TRES niveis agora (antes eram dois): 1) cancela nibble pendente;
;    2) sai do modo de digitacao ASCII; 3) fecha a janela - primeiro nivel
;    pendente "ganha" a cada ESC, so fecha quando nenhum dos dois estiver ativo.
;
;  Duas enderecos (`XD <endinic>,<endfim>`) = sem grade nenhuma, so' despejo
;  nao-interativo pro log - a doc do SUPER-X descreve exatamente esse
;  comportamento ("Two Addresses: give a non stop list output") como
;  identico ao que o comando `D` do Mamute (modulo 31) ja faz; MamuteGui_CmdXd
;  (MamuteAssemblerGui.pbi) so' delega pra Mamute_BuildDumpLines() nesse caso,
;  sem duplicar nada aqui - esse caminho continua so PAGE-relativo (o
;  sufixo #slot/#V so vale pro modo de UM endereco/grade interativa abaixo -
;  Mamute_BuildDumpLines() e compartilhada com D/P/V, nao vale a pena mudar
;  a assinatura dela so por isso).
;
;  Enderecamento estendido do SUPER-X (docs/SPEC.md modulo 45b,
;  Mamute_ParseSxAddr()/Mamute_SxReadByte()/Mamute_SxWriteByte(),
;  MamuteSupport.pbi) - o UM endereco de abertura pode vir com
;  `#<slot>[-<subslot>]`/`#V`/`#4`/`#S`/`#5` (ex.: `XD C000#3-1`). A sessao
;  INTEIRA da grade (navegacao, edicao, "@") fica presa nesse alvo ate
;  fechar - nao volta pro PAGE corrente sozinha. State\Target guarda o alvo
;  resolvido; toda leitura/escrita passa por Mamute_SxReadByte/WriteByte em
;  vez de Mamute_ReadByte/WriteByte "puros". Endereco de VRAM pode passar de
;  FFFF (ate 192KB) - por isso MamuteXd_CellAddr()/paginacao usam
;  Mamute_SxWrapAddr() (modulo certo pro alvo) em vez de "& $FFFF" cru.
;
;  Cruz de modos (docs/SPEC.md modulo 45f, pedido explicito do usuario -
;  "coloque em cruz como no Super-X original") - o SUPER-X real tem 5 modos
;  de edicao (D/A/H/I/M) compartilhando a mesma "casca" de janela, trocaveis
;  em tempo real via um menu em cruz (Dump no topo, Ascii/Char/Multi na
;  linha do meio, Disasm embaixo - layout exato da doc, secao "Basic
;  commands"). O Mamute ainda NAO tem essa casca compartilhada (cada modo e'
;  seu proprio arquivo/janela) - decisao explicita do usuario (pergunta
;  direta antes de codar): colocar a cruz JA, ligando so' o que ja existe -
;  **Dump** = esta propria grade (ja ativa, botao so' mostra destaque);
;  **Multi**/**Ascii**/**Disasm**/**Char** fecham esta janela e abrem
;  MamuteXm_Open()/MamuteXa_Open()/MamuteXi_Open()/MamuteXh_Open() no MESMO
;  endereco/alvo - os quatro modos da cruz ja existem de verdade agora
;  (Char, o ultimo placeholder restante, virou o comando XH - editor de
;  caracteres/sprites, MamuteXhGui.pbi). Cada ponte precisa de
;  Declare.i MamuteXm_Open(...)/MamuteXa_Open(...)/MamuteXi_Open(...)/
;  MamuteXh_Open(...) antecipados em BadigEditor.pb, ja que os arquivos que
;  fornecem as funcoes reais (MamuteXmGui.pbi/MamuteXaGui.pbi/MamuteXiGui.pbi/
;  MamuteXhGui.pbi) sao incluidos DEPOIS deste. Cada modo novo (quando for
;  construido) vira so' mais um Case aqui, sem mudar o layout da cruz.
; ------------------------------------------------------------
;

#MamuteXd_Shortcut_Up       = 9701
#MamuteXd_Shortcut_Down     = 9702
#MamuteXd_Shortcut_Left     = 9703
#MamuteXd_Shortcut_Right    = 9704
#MamuteXd_Shortcut_PageUp   = 9705
#MamuteXd_Shortcut_PageDown = 9706
#MamuteXd_Shortcut_Tab      = 9707
#MamuteXd_Shortcut_Return   = 9708
#MamuteXd_Shortcut_Escape   = 9709
#MamuteXd_Shortcut_Add      = 9710
#MamuteXd_Shortcut_Sub      = 9711
#MamuteXd_HexKeyBase        = 9720 ; 9720..9735 = valores de nibble 0-15

Structure MamuteXdState
  BaseAddr.i     ; endereco do primeiro byte mostrado (linha 0, coluna 0) - 0-65535 (RAM/slot) ou 0-192KB (VRAM)
  Offset.i       ; deslocamento ASCII ativo (-7Fh..80h) - so afeta a INTERPRETACAO exibida
  CursorRow.i    ; 0-15
  CursorCol.i    ; 0-7
  CursorBlock.i  ; 0=hex, 1=texto - AMBOS editaveis no XD (diferenca do M/S)
  NibbleStage.b  ; 0=aguardando nibble alto, 1=alto ja recebido, aguardando o baixo
  PendingHigh.a  ; nibble alto pendente, valido so quando NibbleStage=1
  AsciiTyping.b  ; #True = digitacao ASCII direta ativa (depois de pressionar ")
  Target.MamuteSxTarget ; alvo resolvido (PAGE corrente/slot explicito/sub-slot/VRAM) - ver topo do arquivo
EndStructure

Procedure MamuteXd_ClampCursor(*State.MamuteXdState)
  If *State\CursorRow < 0 : *State\CursorRow = 0 : EndIf
  If *State\CursorRow > 15 : *State\CursorRow = 15 : EndIf
  If *State\CursorCol < 0 : *State\CursorCol = 0 : EndIf
  If *State\CursorCol > 7 : *State\CursorCol = 7 : EndIf
EndProcedure

Procedure.i MamuteXd_CellAddr(*State.MamuteXdState, Row.i, Col.i)
  ProcedureReturn Mamute_SxWrapAddr(*State\BaseAddr + Row * 8 + Col, @*State\Target)
EndProcedure

Procedure.s MamuteXd_DisplayChar(RawByte.a, Offset.i)
  Protected V.i = (RawByte + Offset) & $FF
  If V >= 32 And V <= 126
    ProcedureReturn Chr(V)
  EndIf
  ProcedureReturn "."
EndProcedure

; Avanca o cursor uma celula (mesma ordem hexa->texto/linha a linha usada por
; ambos os blocos) - reaproveitado pela entrada de nibble, pela digitacao
; ASCII e pelo "@".
Procedure MamuteXd_AdvanceCursor(*State.MamuteXdState)
  *State\CursorCol + 1
  If *State\CursorCol > 7
    *State\CursorCol = 0
    *State\CursorRow + 1
    If *State\CursorRow > 15
      *State\CursorRow = 15
      *State\CursorCol = 7
    EndIf
  EndIf
EndProcedure

Procedure MamuteXd_Repaint(Canvas, *State.MamuteXdState, HexX.i, AsciiX.i, CharW.i, CharH.i, HalfCharW.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf

  Protected ColBack        = Mamute_CurrentBackColor()
  Protected ColFront       = Mamute_CurrentFrontColor()
  Protected ColDim         = RGB(25, 110, 50)
  Protected ColCursorBack  = Mamute_CurrentFrontColor()
  Protected ColCursorFront = Mamute_CurrentBackColor()
  Protected ColTypingBack  = RGB(220, 160, 40) ; laranja - realca visualmente o modo de digitacao ASCII

  Box(0, 0, GadgetWidth(Canvas), GadgetHeight(Canvas), ColBack)

  Protected r.i, c.i, RowAddr.i, ByteAddr.i, RawByte.a, bx.i, ax.i, RowY.i, HexTxt.s
  Protected CursorBack.i = ColCursorBack
  If *State\AsciiTyping : CursorBack = ColTypingBack : EndIf
  Protected AddrDigits.i = 4
  If *State\Target\IsVram : AddrDigits = 5 : EndIf

  For r = 0 To 15
    RowY = r * CharH
    RowAddr = MamuteXd_CellAddr(*State, r, 0)
    DrawText(0, RowY, Mamute_HexPad(RowAddr, AddrDigits) + ":", ColDim, ColBack)

    For c = 0 To 7
      ByteAddr = MamuteXd_CellAddr(*State, r, c)
      RawByte = Mamute_SxReadByte(ByteAddr, @*State\Target)
      bx = HexX + c * HalfCharW * 3
      If r = *State\CursorRow And c = *State\CursorCol And *State\CursorBlock = 0
        If *State\NibbleStage = 1
          HexTxt = Mid("0123456789ABCDEF", *State\PendingHigh + 1, 1) + "_"
        Else
          HexTxt = Mamute_Hex2(RawByte)
        EndIf
        Box(bx - 2, RowY - 1, CharW + 3, CharH - 1, CursorBack)
        DrawText(bx, RowY, HexTxt, ColCursorFront, CursorBack)
      Else
        DrawText(bx, RowY, Mamute_Hex2(RawByte), ColFront, ColBack)
      EndIf
    Next

    For c = 0 To 7
      ByteAddr = MamuteXd_CellAddr(*State, r, c)
      RawByte = Mamute_SxReadByte(ByteAddr, @*State\Target)
      ax = AsciiX + c * HalfCharW
      If r = *State\CursorRow And c = *State\CursorCol And *State\CursorBlock = 1
        Box(ax - 1, RowY - 1, HalfCharW + 2, CharH - 1, CursorBack)
        DrawText(ax, RowY, MamuteXd_DisplayChar(RawByte, *State\Offset), ColCursorFront, CursorBack)
      Else
        DrawText(ax, RowY, MamuteXd_DisplayChar(RawByte, *State\Offset), ColFront, ColBack)
      EndIf
    Next
  Next

  StopDrawing()
EndProcedure

; Mesma tecnica de hit-test em loop ja usada por MamuteDumpGui.pbi/MamuteMGui.pbi.
Procedure.b MamuteXd_HitTest(MouseX.i, MouseY.i, HexX.i, AsciiX.i, CharW.i, CharH.i, HalfCharW.i,
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

Procedure MamuteXd_DrawButton(Canvas, Label.s, Font)
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

; Botao da cruz de modos - 3 estilos visuais: 0=disponivel (contorno verde
; normal, mesmo estilo de MamuteXd_DrawButton), 1=ATIVO agora (fundo verde
; solido, texto preto - mesma paleta de destaque do cursor da grade),
; 2=ainda nao implementado (contorno cinza escuro, texto cinza - clicavel,
; mas deixa claro visualmente que nao faz nada de verdade ainda).
Procedure MamuteXd_DrawModeButton(Canvas, Label.s, Font, Style.b)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected W = GadgetWidth(Canvas), H = GadgetHeight(Canvas)
  Protected ColActive = Mamute_CurrentFrontColor(), ColDim = RGB(70, 70, 70), ColDimText = RGB(120, 120, 120)
  Select Style
    Case 1 ; ativo agora
      Box(0, 0, W, H, ColActive)
      DrawingMode(#PB_2DDrawing_Outlined)
      Box(0, 0, W, H, ColActive)
      DrawingMode(#PB_2DDrawing_Transparent)
      DrawingFont(FontID(Font))
      Protected TW1 = TextWidth(Label), TH1 = TextHeight(Label)
      DrawText((W - TW1) / 2, (H - TH1) / 2, Label, Mamute_CurrentBackColor())
    Case 2 ; ainda nao implementado
      Box(0, 0, W, H, RGB(0, 20, 8))
      DrawingMode(#PB_2DDrawing_Outlined)
      Box(0, 0, W, H, ColDim)
      DrawingMode(#PB_2DDrawing_Transparent)
      DrawingFont(FontID(Font))
      Protected TW2 = TextWidth(Label), TH2 = TextHeight(Label)
      DrawText((W - TW2) / 2, (H - TH2) / 2, Label, ColDimText)
    Default ; disponivel
      Box(0, 0, W, H, Mamute_CurrentBackColor())
      DrawingMode(#PB_2DDrawing_Outlined)
      Box(0, 0, W, H, ColActive)
      DrawingMode(#PB_2DDrawing_Transparent)
      DrawingFont(FontID(Font))
      Protected TW3 = TextWidth(Label), TH3 = TextHeight(Label)
      DrawText((W - TW3) / 2, (H - TH3) / 2, Label, ColActive)
  EndSelect
  StopDrawing()
EndProcedure

Procedure MamuteXd_UpdateStatus(G_AddrLabel, G_OffsetLabel, G_ModeLabel, *State.MamuteXdState)
  Protected AddrDigits.i = 4
  If *State\Target\IsVram : AddrDigits = 5 : EndIf
  SetGadgetText(G_AddrLabel, "Endereco: " + Mamute_HexPad(*State\BaseAddr, AddrDigits) + Mamute_SxTargetSuffixText(@*State\Target))
  Protected Sign.s = "+"
  Protected AbsOff.i = *State\Offset
  If AbsOff < 0
    Sign = "-"
    AbsOff = -AbsOff
  EndIf
  SetGadgetText(G_OffsetLabel, "Desloc.:  " + Sign + Mamute_Hex2(AbsOff))
  If *State\AsciiTyping
    SetGadgetText(G_ModeLabel, "Modo: DIGITANDO ASCII (ESC sai)")
  Else
    SetGadgetText(G_ModeLabel, "Modo: navegacao")
  EndIf
EndProcedure

; Devolve o BaseAddr final (endereco onde a janela ficou ao fechar) - quem
; chama guarda isso pra "sem argumento, continua daqui" (mesmo idioma do M/S).
; *StartTarget - alvo ja resolvido (Mamute_ParseSxAddr, MamuteAssemblerGui.pbi)
; - PAGE corrente, slot/sub-slot explicito ou VRAM; a sessao inteira da grade
; fica presa nesse alvo (ver comentario no topo do arquivo).
Procedure.i MamuteXd_Open(ParentWindow, StartAddr.i, StartOffset.i, *StartTarget.MamuteSxTarget)
  Protected State.MamuteXdState
  CopyStructure(*StartTarget, @State\Target, MamuteSxTarget)
  State\BaseAddr = Mamute_SxWrapAddr(StartAddr, @State\Target)
  State\Offset = StartOffset
  State\CursorRow = 0
  State\CursorCol = 0
  State\CursorBlock = 0
  State\NibbleStage = 0
  State\PendingHigh = 0
  State\AsciiTyping = #False

  Protected Title.s = "Mamute Assembler - XD (SUPER-X)"
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

  ; Cruz de modos (Dump/Ascii/Char/Multi/Disasm, ver comentario no topo do
  ; arquivo) - 3x3 celulas, so as 5 em formato de "+" tem botao de verdade.
  ; Fica a direita da grade, centralizada verticalmente com ela (a grade e'
  ; bem mais alta que a cruz - 16 linhas contra 3 - entao cabe do lado sem
  ; esticar a altura da janela).
  Protected ModeBtnW = 76, ModeBtnH = 34, ModeBtnGap = 6
  Protected ModeGapX = 24
  Protected ModeCrossW = ModeBtnW * 3 + ModeBtnGap * 2
  Protected ModeCrossH = ModeBtnH * 3 + ModeBtnGap * 2
  Protected ModeCrossX = Margin + GridW + ModeGapX
  Protected ModeCrossCol0 = ModeCrossX
  Protected ModeCrossCol1 = ModeCrossX + ModeBtnW + ModeBtnGap
  Protected ModeCrossCol2 = ModeCrossX + (ModeBtnW + ModeBtnGap) * 2

  Protected WinW = GridW + ModeGapX + ModeCrossW + Margin * 2
  If RowW + Margin * 2 > WinW
    WinW = RowW + Margin * 2
  EndIf

  Protected LegendH = 20, StatusH = 24
  Protected WinH = Margin + LegendH + 8 + GridH + 12 + StatusH + 4 + StatusH + 4 + StatusH + 12 + BtnH + Margin

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, Title,
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #True, #False)
  If Not Win
    ProcedureReturn StartAddr
  EndIf
  SetWindowColor(Win, Mamute_CurrentBorderColor())

  Protected ColFront = Mamute_CurrentFrontColor(), ColBack = Mamute_CurrentBackColor()
  Protected CurY = Margin

  Protected LegendTxt.s = "Setas/PgUp/PgDn: mover  TAB: hex/texto  0-F: digitar hexa  " + Chr(34) +
                          ": digitar ASCII  @: repete byte anterior  RETURN/ESC: sai  +/-: desloc."
  Protected G_Legend = TextGadget(#PB_Any, Margin, CurY, WinW - Margin * 2, LegendH, LegendTxt)
  SetGadgetColor(G_Legend, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Legend, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Legend, FontID(MFont))
  CurY + LegendH + 8

  Protected GridY = CurY
  Protected G_Grid = CanvasGadget(#PB_Any, Margin, GridY, GridW, GridH, #PB_Canvas_Keyboard)
  CurY + GridH + 12

  ; Cruz de modos - centralizada verticalmente com a grade (16 linhas, bem
  ; mais alta que os 3 da cruz).
  Protected ModeCrossY = GridY + (GridH - ModeCrossH) / 2
  Protected ModeRow0 = ModeCrossY
  Protected ModeRow1 = ModeCrossY + ModeBtnH + ModeBtnGap
  Protected ModeRow2 = ModeCrossY + (ModeBtnH + ModeBtnGap) * 2

  Protected G_ModeDump   = CanvasGadget(#PB_Any, ModeCrossCol1, ModeRow0, ModeBtnW, ModeBtnH)
  Protected G_ModeAscii  = CanvasGadget(#PB_Any, ModeCrossCol0, ModeRow1, ModeBtnW, ModeBtnH)
  Protected G_ModeChar   = CanvasGadget(#PB_Any, ModeCrossCol1, ModeRow1, ModeBtnW, ModeBtnH)
  Protected G_ModeMulti  = CanvasGadget(#PB_Any, ModeCrossCol2, ModeRow1, ModeBtnW, ModeBtnH)
  Protected G_ModeDisasm = CanvasGadget(#PB_Any, ModeCrossCol1, ModeRow2, ModeBtnW, ModeBtnH)

  MamuteXd_DrawModeButton(G_ModeDump, "Dump", BtnFont, 1)   ; ja e' o modo ativo agora
  MamuteXd_DrawModeButton(G_ModeAscii, "Ascii", BtnFont, 0)  ; ja liga com XA de verdade
  MamuteXd_DrawModeButton(G_ModeChar, "Char", BtnFont, 0)    ; ja liga com XH de verdade
  MamuteXd_DrawModeButton(G_ModeMulti, "Multi", BtnFont, 0)  ; ja liga com XM de verdade
  MamuteXd_DrawModeButton(G_ModeDisasm, "Disasm", BtnFont, 0) ; ja liga com XI de verdade
  GadgetToolTip(G_ModeDump, "Modo Dump (grade hexa+ASCII) - ja ativo")
  GadgetToolTip(G_ModeAscii, "Modo Ascii - abre o XA neste mesmo endereco/alvo")
  GadgetToolTip(G_ModeChar, "Modo Char - abre o XH neste mesmo endereco/alvo")
  GadgetToolTip(G_ModeMulti, "Modo Multi - abre o XM neste mesmo endereco/alvo")
  GadgetToolTip(G_ModeDisasm, "Modo Disasm - abre o XI neste mesmo endereco/alvo")

  Protected G_AddrLabel = TextGadget(#PB_Any, Margin, CurY, 260, StatusH, "")
  SetGadgetColor(G_AddrLabel, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_AddrLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_AddrLabel, FontID(MFont))
  CurY + StatusH + 4

  Protected G_OffsetLabel = TextGadget(#PB_Any, Margin, CurY, 260, StatusH, "")
  SetGadgetColor(G_OffsetLabel, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_OffsetLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_OffsetLabel, FontID(MFont))
  CurY + StatusH + 4

  Protected G_ModeLabel = TextGadget(#PB_Any, Margin, CurY, 360, StatusH, "")
  SetGadgetColor(G_ModeLabel, #PB_Gadget_FrontColor, RGB(220, 160, 40))
  SetGadgetColor(G_ModeLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_ModeLabel, FontID(MFont))
  CurY + StatusH + 12

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

  MamuteXd_DrawButton(G_PageLeft, "<<", BtnFont)
  MamuteXd_DrawButton(G_ArrowLeft, "<", BtnFont)
  MamuteXd_DrawButton(G_ArrowUp, "^", BtnFont)
  MamuteXd_DrawButton(G_ArrowDown, "v", BtnFont)
  MamuteXd_DrawButton(G_ArrowRight, ">", BtnFont)
  MamuteXd_DrawButton(G_PageRight, ">>", BtnFont)
  MamuteXd_DrawButton(G_MinusBtn, "-", BtnFont)
  MamuteXd_DrawButton(G_PlusBtn, "+", BtnFont)
  GadgetToolTip(G_PageLeft, "-128 bytes")
  GadgetToolTip(G_PageRight, "+128 bytes")
  GadgetToolTip(G_MinusBtn, "Desloc. -1")
  GadgetToolTip(G_PlusBtn, "Desloc. +1")

  MamuteXd_UpdateStatus(G_AddrLabel, G_OffsetLabel, G_ModeLabel, @State)
  MamuteXd_Repaint(G_Grid, @State, HexX, AsciiX, CharW, CharH, HalfCharW)
  SetActiveGadget(G_Grid)

  AddKeyboardShortcut(Win, #PB_Shortcut_Up, #MamuteXd_Shortcut_Up)
  AddKeyboardShortcut(Win, #PB_Shortcut_Down, #MamuteXd_Shortcut_Down)
  AddKeyboardShortcut(Win, #PB_Shortcut_Left, #MamuteXd_Shortcut_Left)
  AddKeyboardShortcut(Win, #PB_Shortcut_Right, #MamuteXd_Shortcut_Right)
  AddKeyboardShortcut(Win, #PB_Shortcut_PageUp, #MamuteXd_Shortcut_PageUp)
  AddKeyboardShortcut(Win, #PB_Shortcut_PageDown, #MamuteXd_Shortcut_PageDown)
  AddKeyboardShortcut(Win, #PB_Shortcut_Up | #PB_Shortcut_Shift, #MamuteXd_Shortcut_PageUp)   ; SHIFT+cima/baixo = mesmo atalho do PgUp/PgDn (doc do SUPER-X lista os dois)
  AddKeyboardShortcut(Win, #PB_Shortcut_Down | #PB_Shortcut_Shift, #MamuteXd_Shortcut_PageDown)
  AddKeyboardShortcut(Win, #PB_Shortcut_Tab, #MamuteXd_Shortcut_Tab)
  AddKeyboardShortcut(Win, #PB_Shortcut_Return, #MamuteXd_Shortcut_Return)
  AddKeyboardShortcut(Win, #PB_Shortcut_Escape, #MamuteXd_Shortcut_Escape)
  AddKeyboardShortcut(Win, #PB_Shortcut_Add, #MamuteXd_Shortcut_Add)
  AddKeyboardShortcut(Win, #PB_Shortcut_Subtract, #MamuteXd_Shortcut_Sub)

  Protected kv.i
  For kv = 0 To 15
    Protected KeyConst.i = Mamute_KeyCharToShortcut(Mid("0123456789ABCDEF", kv + 1, 1))
    If KeyConst
      AddKeyboardShortcut(Win, KeyConst, #MamuteXd_HexKeyBase + kv)
    EndIf
  Next

  Macro MamuteXd_DoRepaint
    MamuteXd_UpdateStatus(G_AddrLabel, G_OffsetLabel, G_ModeLabel, @State)
    MamuteXd_Repaint(G_Grid, @State, HexX, AsciiX, CharW, CharH, HalfCharW)
  EndMacro

  Macro MamuteXd_DoMove(DRow, DCol)
    State\CursorRow + (DRow)
    State\CursorCol + (DCol)
    State\NibbleStage = 0
    MamuteXd_ClampCursor(@State)
    MamuteXd_DoRepaint
  EndMacro

  Macro MamuteXd_DoPage(Delta)
    State\BaseAddr = Mamute_SxWrapAddr(State\BaseAddr + (Delta), @State\Target)
    State\NibbleStage = 0
    MamuteXd_DoRepaint
  EndMacro

  Macro MamuteXd_DoOffset(Delta)
    NewOff = State\Offset + (Delta)
    If NewOff < -$7F : NewOff = -$7F : EndIf
    If NewOff > $80 : NewOff = $80 : EndIf
    State\Offset = NewOff
    MamuteXd_DoRepaint
  EndMacro

  Protected Event, Quit = #False
  Protected AlreadyClosed.b = #False ; #True quando o botao "Multi" ja fechou a janela na hora (evita fechar 2x no final)
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
                Protected HitRow.i, HitCol.i, HitBlock.i
                If MamuteXd_HitTest(MouseX, MouseY, HexX, AsciiX, CharW, CharH, HalfCharW, @HitRow, @HitCol, @HitBlock)
                  State\CursorRow = HitRow
                  State\CursorCol = HitCol
                  State\CursorBlock = HitBlock
                  State\NibbleStage = 0
                  MamuteXd_DoRepaint
                EndIf

              ; "/@ nao tem constante #PB_Shortcut_ (so' 0-9/A-Z/F1-F24/setas/etc,
              ; confirmado no help local do compilador) - capturados aqui via
              ; #PB_EventType_Input, que devolve o CARACTERE de verdade
              ; independente de layout de teclado (ao contrario de
              ; #PB_Canvas_Key/AddKeyboardShortcut, limitados aos mesmos
              ; #PB_Shortcut_*). Em digitacao ASCII, QUALQUER caractere
              ; imprimivel (inclusive " e @ literais) vira byte cru - so' sai
              ; do modo com ESC.
              Case #PB_EventType_Input
                Protected TypedCode.i = GetGadgetAttribute(G_Grid, #PB_Canvas_Input)
                If TypedCode > 0
                  Protected TypedChar.s = Chr(TypedCode)
                  If State\AsciiTyping
                    If TypedCode >= 32 And TypedCode <= 126
                      Mamute_SxWriteByte(MamuteXd_CellAddr(@State, State\CursorRow, State\CursorCol),
                                         (TypedCode - State\Offset) & $FF, @State\Target)
                      MamuteXd_AdvanceCursor(@State)
                      MamuteXd_DoRepaint
                    EndIf
                  ElseIf TypedChar = Chr(34)
                    State\CursorBlock = 1
                    State\NibbleStage = 0
                    State\AsciiTyping = #True
                    MamuteXd_DoRepaint
                  ElseIf TypedChar = "@" And State\CursorBlock = 0
                    Protected CurAddr.i = MamuteXd_CellAddr(@State, State\CursorRow, State\CursorCol)
                    Protected PrevByte.a = Mamute_SxReadByte(Mamute_SxWrapAddr(CurAddr - 1, @State\Target), @State\Target)
                    Mamute_SxWriteByte(CurAddr, PrevByte, @State\Target)
                    MamuteXd_AdvanceCursor(@State)
                    MamuteXd_DoRepaint
                  EndIf
                EndIf
            EndSelect

          Case G_ArrowUp    : If EventType() = #PB_EventType_LeftButtonDown : MamuteXd_DoMove(-1, 0) : EndIf
          Case G_ArrowDown  : If EventType() = #PB_EventType_LeftButtonDown : MamuteXd_DoMove(1, 0) : EndIf
          Case G_ArrowLeft  : If EventType() = #PB_EventType_LeftButtonDown : MamuteXd_DoMove(0, -1) : EndIf
          Case G_ArrowRight : If EventType() = #PB_EventType_LeftButtonDown : MamuteXd_DoMove(0, 1) : EndIf
          Case G_PageLeft   : If EventType() = #PB_EventType_LeftButtonDown : MamuteXd_DoPage(-128) : EndIf
          Case G_PageRight  : If EventType() = #PB_EventType_LeftButtonDown : MamuteXd_DoPage(128) : EndIf
          Case G_MinusBtn   : If EventType() = #PB_EventType_LeftButtonDown : MamuteXd_DoOffset(-1) : EndIf
          Case G_PlusBtn    : If EventType() = #PB_EventType_LeftButtonDown : MamuteXd_DoOffset(1) : EndIf

          ; Cruz de modos (ver comentario no topo do arquivo) - Dump ja e' o
          ; modo ativo (clique nao faz nada); Ascii/Multi/Disasm trocam de
          ; verdade pro XA/XM/XI, no MESMO endereco/alvo; Char continua o
          ; unico placeholder.
          Case G_ModeDump
            ; ja e' o modo ativo - nada a fazer

          Case G_ModeMulti
            If EventType() = #PB_EventType_LeftButtonDown
              CloseModelessChildWindow(ParentWindow, Win)
              AlreadyClosed = #True
              State\BaseAddr = MamuteXm_Open(ParentWindow, State\BaseAddr, @State\Target)
              Quit = #True
            EndIf

          Case G_ModeAscii
            If EventType() = #PB_EventType_LeftButtonDown
              CloseModelessChildWindow(ParentWindow, Win)
              AlreadyClosed = #True
              State\BaseAddr = MamuteXa_Open(ParentWindow, State\BaseAddr, @State\Target)
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
          Case #MamuteXd_Shortcut_Up     : MamuteXd_DoMove(-1, 0)
          Case #MamuteXd_Shortcut_Down   : MamuteXd_DoMove(1, 0)
          Case #MamuteXd_Shortcut_Left   : MamuteXd_DoMove(0, -1)
          Case #MamuteXd_Shortcut_Right  : MamuteXd_DoMove(0, 1)
          Case #MamuteXd_Shortcut_PageUp   : MamuteXd_DoPage(-128)
          Case #MamuteXd_Shortcut_PageDown : MamuteXd_DoPage(128)
          Case #MamuteXd_Shortcut_Add : MamuteXd_DoOffset(1)
          Case #MamuteXd_Shortcut_Sub : MamuteXd_DoOffset(-1)

          Case #MamuteXd_Shortcut_Tab
            If State\CursorBlock = 0 : State\CursorBlock = 1 : Else : State\CursorBlock = 0 : EndIf
            State\NibbleStage = 0
            State\AsciiTyping = #False
            MamuteXd_DoRepaint

          Case #MamuteXd_Shortcut_Return
            Quit = #True

          Case #MamuteXd_Shortcut_Escape
            If State\NibbleStage = 1
              State\NibbleStage = 0
              MamuteXd_DoRepaint
            ElseIf State\AsciiTyping
              State\AsciiTyping = #False
              MamuteXd_DoRepaint
            Else
              Quit = #True
            EndIf

          Case #MamuteXd_HexKeyBase To #MamuteXd_HexKeyBase + 15
            If State\CursorBlock = 0 And Not State\AsciiTyping
              Protected NibbleVal.i = EventMenu() - #MamuteXd_HexKeyBase
              If State\NibbleStage = 0
                State\PendingHigh = NibbleVal
                State\NibbleStage = 1
              Else
                Protected NewByte.a = (State\PendingHigh << 4) | NibbleVal
                Mamute_SxWriteByte(MamuteXd_CellAddr(@State, State\CursorRow, State\CursorCol), NewByte, @State\Target)
                State\NibbleStage = 0
                MamuteXd_AdvanceCursor(@State)
              EndIf
              MamuteXd_DoRepaint
            EndIf
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
