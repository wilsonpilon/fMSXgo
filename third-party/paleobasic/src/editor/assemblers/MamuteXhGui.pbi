;
; ------------------------------------------------------------
;  Comando XH do Mamute Assembler - porta do comando H do monitor SUPER-X
;  (docs/SPEC.md modulo 45/45f, others/superx/SUPER-X.DOC.pdf) - o editor de
;  caracteres/sprites do SUPER-X, o UNICO placeholder que faltava na "cruz de
;  modos" (Dump/Ascii/Char/Multi/Disasm - ver comentario no topo de
;  MamuteXdGui.pbi) desde que ela foi introduzida. Batizado XH (nao H) pelo
;  mesmo motivo do XD/XA/XI/XM - decisao explicita do usuario.
;
;  Edita 4 caracteres/sprites CONSECUTIVOS de uma vez (32 bytes: BaseAddr a
;  BaseAddr+31, 8 bytes cada, formato padrao MSX de gerador de caracteres OU
;  padrao de sprite 8x8 - os dois usam exatamente o mesmo layout de bytes,
;  entao esta tela serve pros dois sem distincao nenhuma) - layout pedido
;  explicito do usuario:
;
;  - Grade de 16 linhas x 16 colunas de PIXELS (nao bytes) - cada linha da
;    grade e' UMA linha de pixel de DOIS caracteres lado a lado (colunas 0-7 =
;    caractere da esquerda, colunas 8-15 = caractere da direita), com um
;    cabecalho "0123456789ABCDEF" no topo servindo de regua de coluna. As
;    primeiras 8 linhas (0-7) mostram os caracteres 1 e 2; as ultimas 8
;    linhas (8-15) mostram os caracteres 3 e 4 - "2 em cima 2 em baixo"
;    (MamuteXh_CharIndex() abaixo: (linha/8)*2 + (coluna/8) = indice 0-3).
;    Pixel aceso = "0" (formando visualmente uma silhueta escura no meio dos
;    tracos), apagado = "-" - pedido explicito do usuario.
;  - Cada linha termina com "XXXX : YY:ZZ N" onde XXXX e' o endereco do byte
;    do caractere DA ESQUERDA nessa linha (YY = valor dele), ZZ = valor do
;    byte do caractere DA DIREITA na MESMA linha de pixel, N = indice da
;    linha DENTRO do caractere (0-7, repete depois da linha 7->8).
;  - Miniatura no canto (MamuteXh_DrawPreview()) - os 4 caracteres montados
;    lado a lado/em cima um do outro, exatamente como ficam de verdade numa
;    tela MSX (2x2, 16x16 pixels no total).
;  - Edicao: [ESPACO] inverte o bit sob o cursor (setas movem, sem digitacao
;    hexa/ascii - "a edicao e simples" foi pedido explicito). Quatro botoes
;    de acao (pedido explicito): INVERTER/LIMPAR/PREENCHER operam sobre o
;    caractere onde o CURSOR esta agora (MamuteXh_CursorCharBase()); LIMPAR
;    BLOCO zera os 4 de uma vez (unico que afeta a grade inteira).
;
;  Enderecamento estendido do SUPER-X (Mamute_ParseSxAddr()/Mamute_SxReadByte()/
;  Mamute_SxWriteByte(), MamuteSupport.pbi) - mesma regra do XD/XA/XI/XM: o
;  endereco de abertura aceita "#<slot>[-<subslot>]"/"#V"/"#4"/"#S"/"#5" e a
;  sessao inteira fica presa nesse alvo. PgUp/PgDn (e os botoes "<<"/">>")
;  pulam +-32 bytes (um bloco de 4 caracteres inteiro) em vez de +-128 (XD) -
;  faz mais sentido pra andar caractere-a-caractere pela fonte/sprite table.
;
;  Cruz de modos - aqui **Char** e' o modo ativo; **Dump**/**Ascii**/**Multi**/
;  **Disasm** ligam de volta pro XD/XA/XM/XI (todos ja prontos). As cruzes dos
;  quatro arquivos irmaos foram atualizadas nesta mesma sessao pra ligar o
;  botao Char delas pra ca em vez do placeholder "AINDA NAO IMPLEMENTADO".
; ------------------------------------------------------------
;

#MamuteXh_Shortcut_Up       = 9800
#MamuteXh_Shortcut_Down     = 9801
#MamuteXh_Shortcut_Left     = 9802
#MamuteXh_Shortcut_Right    = 9803
#MamuteXh_Shortcut_PageUp   = 9804
#MamuteXh_Shortcut_PageDown = 9805
#MamuteXh_Shortcut_Space    = 9806
#MamuteXh_Shortcut_Return   = 9807
#MamuteXh_Shortcut_Escape   = 9808

Structure MamuteXhState
  BaseAddr.i             ; endereco do byte 0 do caractere 1 (primeiro dos 4 caracteres/32 bytes)
  CursorRow.i            ; 0-15 - linha de PIXEL na grade (nao byte)
  CursorCol.i            ; 0-15 - coluna de PIXEL na grade
  Target.MamuteSxTarget  ; alvo resolvido (PAGE corrente/slot explicito/sub-slot/VRAM)
EndStructure

Procedure MamuteXh_ClampCursor(*State.MamuteXhState)
  If *State\CursorRow < 0 : *State\CursorRow = 0 : EndIf
  If *State\CursorRow > 15 : *State\CursorRow = 15 : EndIf
  If *State\CursorCol < 0 : *State\CursorCol = 0 : EndIf
  If *State\CursorCol > 15 : *State\CursorCol = 15 : EndIf
EndProcedure

; 0=topo-esquerda, 1=topo-direita, 2=baixo-esquerda, 3=baixo-direita - "2 em
; cima 2 em baixo" pedido explicito do usuario.
Procedure.i MamuteXh_CharIndex(Row.i, Col.i)
  ProcedureReturn (Row / 8) * 2 + (Col / 8)
EndProcedure

Procedure.i MamuteXh_ByteAddr(*State.MamuteXhState, Row.i, Col.i)
  Protected CharIdx.i = MamuteXh_CharIndex(Row, Col)
  Protected RowInChar.i = Row & 7
  ProcedureReturn Mamute_SxWrapAddr(*State\BaseAddr + CharIdx * 8 + RowInChar, @*State\Target)
EndProcedure

; Bit 7 = pixel mais a esquerda de cada caractere (convencao padrao MSX de
; gerador de caracteres/sprite - MSB primeiro).
Procedure.i MamuteXh_BitMask(Col.i)
  ProcedureReturn 1 << (7 - (Col & 7))
EndProcedure

Procedure.b MamuteXh_GetPixel(*State.MamuteXhState, Row.i, Col.i)
  Protected RawByte.a = Mamute_SxReadByte(MamuteXh_ByteAddr(*State, Row, Col), @*State\Target)
  ProcedureReturn Bool((RawByte & MamuteXh_BitMask(Col)) <> 0)
EndProcedure

Procedure MamuteXh_ToggleBit(*State.MamuteXhState, Row.i, Col.i)
  Protected Addr.i = MamuteXh_ByteAddr(*State, Row, Col)
  Protected RawByte.a = Mamute_SxReadByte(Addr, @*State\Target)
  Protected Mask.i = MamuteXh_BitMask(Col)
  If RawByte & Mask
    RawByte = RawByte & (255 - Mask)
  Else
    RawByte = RawByte | Mask
  EndIf
  Mamute_SxWriteByte(Addr, RawByte, @*State\Target)
EndProcedure

; Endereco do byte 0 do caractere onde o CURSOR esta agora (0-3) - base dos
; tres botoes "por caractere" (Inverter/Limpar/Preencher) abaixo.
Procedure.i MamuteXh_CursorCharBase(*State.MamuteXhState)
  Protected CharIdx.i = MamuteXh_CharIndex(*State\CursorRow, *State\CursorCol)
  ProcedureReturn Mamute_SxWrapAddr(*State\BaseAddr + CharIdx * 8, @*State\Target)
EndProcedure

Procedure MamuteXh_InvertChar(*State.MamuteXhState)
  Protected Base.i = MamuteXh_CursorCharBase(*State)
  Protected i.i, Addr.i, RawByte.a
  For i = 0 To 7
    Addr = Mamute_SxWrapAddr(Base + i, @*State\Target)
    RawByte = Mamute_SxReadByte(Addr, @*State\Target)
    Mamute_SxWriteByte(Addr, 255 - RawByte, @*State\Target)
  Next
EndProcedure

Procedure MamuteXh_ClearChar(*State.MamuteXhState)
  Protected Base.i = MamuteXh_CursorCharBase(*State)
  Protected i.i
  For i = 0 To 7
    Mamute_SxWriteByte(Mamute_SxWrapAddr(Base + i, @*State\Target), 0, @*State\Target)
  Next
EndProcedure

Procedure MamuteXh_FillChar(*State.MamuteXhState)
  Protected Base.i = MamuteXh_CursorCharBase(*State)
  Protected i.i
  For i = 0 To 7
    Mamute_SxWriteByte(Mamute_SxWrapAddr(Base + i, @*State\Target), 255, @*State\Target)
  Next
EndProcedure

; Unico botao que mexe nos 4 caracteres de uma vez (pedido explicito do
; usuario: "limpar o bloco 16x16") - os outros tres operam so' no caractere
; do cursor.
Procedure MamuteXh_ClearBlock(*State.MamuteXhState)
  Protected i.i
  For i = 0 To 31
    Mamute_SxWriteByte(Mamute_SxWrapAddr(*State\BaseAddr + i, @*State\Target), 0, @*State\Target)
  Next
EndProcedure

; Desenha a grade inteira (cabecalho 0-F + 16 linhas de pixel, endereco a
; esquerda, valores dos 2 bytes + indice da linha a direita).
Procedure MamuteXh_RepaintGrid(Canvas, *State.MamuteXhState, AddrLabelW.i, CharW.i, CharH.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf

  Protected ColBack        = Mamute_CurrentBackColor()
  Protected ColFront       = Mamute_CurrentFrontColor()
  Protected ColDim         = RGB(25, 110, 50)
  Protected ColCursorBack  = Mamute_CurrentFrontColor()
  Protected ColCursorFront = Mamute_CurrentBackColor()

  Box(0, 0, GadgetWidth(Canvas), GadgetHeight(Canvas), ColBack)

  Protected AddrDigits.i = 4
  If *State\Target\IsVram : AddrDigits = 5 : EndIf

  Protected c.i, r.i, PixelX.i
  Protected HexDigits.s = "0123456789ABCDEF"

  ; cabecalho (linha 0 da grade) - regua de coluna 0-F, alinhada com os
  ; mesmos X das colunas de pixel abaixo.
  For c = 0 To 15
    PixelX = AddrLabelW + c * CharW
    DrawText(PixelX, 0, Mid(HexDigits, c + 1, 1), ColDim, ColBack)
  Next

  Protected RowY.i, CharIdxLeft.i, RowInChar.i, LeftAddr.i, RightAddr.i, LeftByte.a, RightByte.a
  Protected Glyph.s, Suffix.s

  For r = 0 To 15
    RowY = (r + 1) * CharH
    CharIdxLeft = MamuteXh_CharIndex(r, 0)
    RowInChar = r & 7
    LeftAddr = Mamute_SxWrapAddr(*State\BaseAddr + CharIdxLeft * 8 + RowInChar, @*State\Target)
    RightAddr = Mamute_SxWrapAddr(*State\BaseAddr + (CharIdxLeft + 1) * 8 + RowInChar, @*State\Target)
    LeftByte = Mamute_SxReadByte(LeftAddr, @*State\Target)
    RightByte = Mamute_SxReadByte(RightAddr, @*State\Target)

    DrawText(0, RowY, Mamute_HexPad(LeftAddr, AddrDigits) + ":", ColDim, ColBack)

    For c = 0 To 15
      PixelX = AddrLabelW + c * CharW
      If MamuteXh_GetPixel(*State, r, c)
        Glyph = "0"
      Else
        Glyph = "-"
      EndIf
      If r = *State\CursorRow And c = *State\CursorCol
        Box(PixelX - 1, RowY - 1, CharW + 1, CharH - 1, ColCursorBack)
        DrawText(PixelX, RowY, Glyph, ColCursorFront, ColCursorBack)
      Else
        DrawText(PixelX, RowY, Glyph, ColFront, ColBack)
      EndIf
    Next

    Suffix = " : " + Mamute_Hex2(LeftByte) + ":" + Mamute_Hex2(RightByte) + " " + Str(RowInChar)
    DrawText(AddrLabelW + 16 * CharW, RowY, Suffix, ColDim, ColBack)
  Next

  StopDrawing()
EndProcedure

; So' testa a area de PIXELS (nao o rotulo de endereco/sufixo) - mesma tecnica
; de MamuteXd_HitTest/MamuteM_HitTest, adaptada pra uma grade 16x16 unica.
Procedure.b MamuteXh_HitTest(MouseX.i, MouseY.i, AddrLabelW.i, CharW.i, CharH.i, *OutRow.Integer, *OutCol.Integer)
  Protected Row.i = MouseY / CharH - 1 ; linha 0 da grade e' o cabecalho
  If Row < 0 Or Row > 15
    ProcedureReturn #False
  EndIf
  If MouseX < AddrLabelW
    ProcedureReturn #False
  EndIf
  Protected Col.i = (MouseX - AddrLabelW) / CharW
  If Col < 0 Or Col > 15
    ProcedureReturn #False
  EndIf
  *OutRow\i = Row : *OutCol\i = Col
  ProcedureReturn #True
EndProcedure

; Miniatura "no canto" - os 4 caracteres/sprites montados 2x2 (16x16 pixels no
; total), exatamente como ficam de verdade numa tela MSX - pedido explicito
; do usuario. Linhas finas no meio so' separam visualmente os 4 quadrantes,
; nao fazem parte do padrao de verdade.
Procedure MamuteXh_DrawPreview(Canvas, *State.MamuteXhState)
  Protected W = GadgetWidth(Canvas), H = GadgetHeight(Canvas)
  Protected PixelSize.i = W / 16
  If PixelSize < 1 : PixelSize = 1 : EndIf
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected ColBack = Mamute_CurrentBackColor(), ColOn = Mamute_CurrentFrontColor(), ColMid = RGB(25, 60, 40)
  Box(0, 0, W, H, ColBack)
  Protected r.i, c.i
  For r = 0 To 15
    For c = 0 To 15
      If MamuteXh_GetPixel(*State, r, c)
        Box(c * PixelSize, r * PixelSize, PixelSize, PixelSize, ColOn)
      EndIf
    Next
  Next
  Box(8 * PixelSize - 1, 0, 1, H, ColMid)
  Box(0, 8 * PixelSize - 1, W, 1, ColMid)
  StopDrawing()
EndProcedure

; Devolve o BaseAddr final (endereco onde a janela ficou ao fechar) - quem
; chama guarda isso pra "sem argumento, continua daqui" (mesmo idioma do
; XD/XA/XI/XM). *StartTarget - alvo ja resolvido (Mamute_ParseSxAddr,
; MamuteAssemblerGui.pbi).
Procedure.i MamuteXh_Open(ParentWindow, StartAddr.i, *StartTarget.MamuteSxTarget)
  Protected State.MamuteXhState
  CopyStructure(*StartTarget, @State\Target, MamuteSxTarget)
  State\BaseAddr = Mamute_SxWrapAddr(StartAddr, @State\Target)
  State\CursorRow = 0
  State\CursorCol = 0

  Protected Title.s = "Mamute Assembler - XH (SUPER-X)"
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

  Protected CharW, CharH, AddrLabelW, SuffixW
  Protected MeasureImg = CreateImage(#PB_Any, 10, 10)
  If MeasureImg And StartDrawing(ImageOutput(MeasureImg))
    DrawingFont(FontID(MFont))
    CharW = TextWidth("0")
    CharH = TextHeight("0") + 4
    AddrLabelW = TextWidth("00000:")
    SuffixW = TextWidth(" : FF:FF 7")
    StopDrawing()
  EndIf
  If MeasureImg : FreeImage(MeasureImg) : EndIf
  If CharW <= 0 : CharW = 12 : EndIf
  If CharH <= 0 : CharH = 20 : EndIf
  If AddrLabelW <= 0 : AddrLabelW = 50 : EndIf
  If SuffixW <= 0 : SuffixW = 90 : EndIf

  Protected GridW = AddrLabelW + 16 * CharW + SuffixW
  Protected GridH = 17 * CharH ; cabecalho + 16 linhas

  Protected Margin = 16

  ; Coluna direita "no canto" - miniatura 16x16 (128x128, 8px por pixel) em
  ; cima, cruz de modos embaixo, o par centralizado verticalmente ao lado da
  ; grade (mesmo espirito de MamuteXdGui.pbi centralizar so' a cruz).
  Protected PreviewSize = 128
  Protected ModeBtnW = 76, ModeBtnH = 34, ModeBtnGap = 6
  Protected ModeCrossW = ModeBtnW * 3 + ModeBtnGap * 2
  Protected ModeCrossH = ModeBtnH * 3 + ModeBtnGap * 2
  Protected GapX = 24, GapY = 16
  Protected RightColW = ModeCrossW
  If PreviewSize > RightColW : RightColW = PreviewSize : EndIf
  Protected RightColH = PreviewSize + GapY + ModeCrossH

  Protected WinW = GridW + GapX + RightColW + Margin * 2

  Protected BtnH = 40, BtnGap = 8
  Protected NavRowW = 56 + BtnGap + BtnH + BtnGap + BtnH + BtnGap + BtnH + BtnGap + BtnH + BtnGap + 56 + Margin * 2
  If NavRowW > WinW : WinW = NavRowW : EndIf
  Protected ActBtnW = 120
  Protected ActRowW = ActBtnW * 4 + BtnGap * 3 + Margin * 2
  If ActRowW > WinW : WinW = ActRowW : EndIf

  Protected LegendH = 20, StatusH = 24
  Protected ContentH = GridH
  If RightColH > ContentH : ContentH = RightColH : EndIf
  Protected WinH = Margin + LegendH + 8 + ContentH + 12 + StatusH + 4 + StatusH + 12 + BtnH + 8 + BtnH + Margin

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, Title,
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #True, #False)
  If Not Win
    ProcedureReturn StartAddr
  EndIf
  SetWindowColor(Win, Mamute_CurrentBorderColor())

  Protected ColFront = Mamute_CurrentFrontColor(), ColBack = Mamute_CurrentBackColor()
  Protected CurY = Margin

  Protected LegendTxt.s = "Setas: mover  ESPACO: inverte o bit  PgUp/PgDn: bloco anterior/proximo (32 bytes)  RETURN/ESC: sai"
  Protected G_Legend = TextGadget(#PB_Any, Margin, CurY, WinW - Margin * 2, LegendH, LegendTxt)
  SetGadgetColor(G_Legend, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Legend, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Legend, FontID(MFont))
  CurY + LegendH + 8

  Protected GridY = CurY
  Protected G_Grid = CanvasGadget(#PB_Any, Margin, GridY, GridW, GridH, #PB_Canvas_Keyboard)

  Protected RightColX = Margin + GridW + GapX
  Protected RightColY = GridY + (ContentH - RightColH) / 2
  Protected G_Preview = CanvasGadget(#PB_Any, RightColX + (RightColW - PreviewSize) / 2, RightColY, PreviewSize, PreviewSize)

  Protected ModeCrossY = RightColY + PreviewSize + GapY
  Protected ModeCrossX = RightColX + (RightColW - ModeCrossW) / 2
  Protected ModeCrossCol0 = ModeCrossX
  Protected ModeCrossCol1 = ModeCrossX + ModeBtnW + ModeBtnGap
  Protected ModeCrossCol2 = ModeCrossX + (ModeBtnW + ModeBtnGap) * 2
  Protected ModeRow0 = ModeCrossY
  Protected ModeRow1 = ModeCrossY + ModeBtnH + ModeBtnGap
  Protected ModeRow2 = ModeCrossY + (ModeBtnH + ModeBtnGap) * 2

  Protected G_ModeDump   = CanvasGadget(#PB_Any, ModeCrossCol1, ModeRow0, ModeBtnW, ModeBtnH)
  Protected G_ModeAscii  = CanvasGadget(#PB_Any, ModeCrossCol0, ModeRow1, ModeBtnW, ModeBtnH)
  Protected G_ModeChar   = CanvasGadget(#PB_Any, ModeCrossCol1, ModeRow1, ModeBtnW, ModeBtnH)
  Protected G_ModeMulti  = CanvasGadget(#PB_Any, ModeCrossCol2, ModeRow1, ModeBtnW, ModeBtnH)
  Protected G_ModeDisasm = CanvasGadget(#PB_Any, ModeCrossCol1, ModeRow2, ModeBtnW, ModeBtnH)

  MamuteXd_DrawModeButton(G_ModeDump, "Dump", BtnFont, 0)    ; ja liga com XD de verdade
  MamuteXd_DrawModeButton(G_ModeAscii, "Ascii", BtnFont, 0)  ; ja liga com XA de verdade
  MamuteXd_DrawModeButton(G_ModeChar, "Char", BtnFont, 1)    ; ja e' o modo ativo agora
  MamuteXd_DrawModeButton(G_ModeMulti, "Multi", BtnFont, 0)  ; ja liga com XM de verdade
  MamuteXd_DrawModeButton(G_ModeDisasm, "Disasm", BtnFont, 0) ; ja liga com XI de verdade
  GadgetToolTip(G_ModeDump, "Modo Dump - abre o XD neste mesmo endereco/alvo")
  GadgetToolTip(G_ModeAscii, "Modo Ascii - abre o XA neste mesmo endereco/alvo")
  GadgetToolTip(G_ModeChar, "Modo Char (esta tela) - ja ativo")
  GadgetToolTip(G_ModeMulti, "Modo Multi - abre o XM neste mesmo endereco/alvo")
  GadgetToolTip(G_ModeDisasm, "Modo Disasm - abre o XI neste mesmo endereco/alvo")

  CurY + ContentH + 12

  Protected G_AddrLabel = TextGadget(#PB_Any, Margin, CurY, 320, StatusH, "")
  SetGadgetColor(G_AddrLabel, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_AddrLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_AddrLabel, FontID(MFont))
  CurY + StatusH + 4

  Protected G_ModeLabel = TextGadget(#PB_Any, Margin, CurY, WinW - Margin * 2, StatusH, "")
  SetGadgetColor(G_ModeLabel, #PB_Gadget_FrontColor, RGB(220, 160, 40))
  SetGadgetColor(G_ModeLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_ModeLabel, FontID(MFont))
  CurY + StatusH + 12

  Protected NavY = CurY
  Protected CurX = Margin
  Protected G_PageLeft = CanvasGadget(#PB_Any, CurX, NavY, 56, BtnH)    : CurX + 56 + BtnGap
  Protected G_ArrowLeft = CanvasGadget(#PB_Any, CurX, NavY, BtnH, BtnH)  : CurX + BtnH + BtnGap
  Protected G_ArrowUp = CanvasGadget(#PB_Any, CurX, NavY, BtnH, BtnH)    : CurX + BtnH + BtnGap
  Protected G_ArrowDown = CanvasGadget(#PB_Any, CurX, NavY, BtnH, BtnH)  : CurX + BtnH + BtnGap
  Protected G_ArrowRight = CanvasGadget(#PB_Any, CurX, NavY, BtnH, BtnH) : CurX + BtnH + BtnGap
  Protected G_PageRight = CanvasGadget(#PB_Any, CurX, NavY, 56, BtnH)

  MamuteXd_DrawButton(G_PageLeft, "<<", BtnFont)
  MamuteXd_DrawButton(G_ArrowLeft, "<", BtnFont)
  MamuteXd_DrawButton(G_ArrowUp, "^", BtnFont)
  MamuteXd_DrawButton(G_ArrowDown, "v", BtnFont)
  MamuteXd_DrawButton(G_ArrowRight, ">", BtnFont)
  MamuteXd_DrawButton(G_PageRight, ">>", BtnFont)
  GadgetToolTip(G_PageLeft, "-32 bytes (bloco anterior)")
  GadgetToolTip(G_PageRight, "+32 bytes (proximo bloco)")

  CurY + BtnH + 8

  ; Segunda linha de botoes - so' os 4 de acao (pedido explicito do usuario:
  ; inverter/limpar/preencher o caractere do cursor, limpar o bloco 16x16
  ; inteiro) - fica numa linha a parte da navegacao pra nao espremer os
  ; rotulos (mais compridos que uma seta) demais.
  Protected ActY = CurY
  CurX = Margin
  Protected G_BtnInvert = CanvasGadget(#PB_Any, CurX, ActY, ActBtnW, BtnH) : CurX + ActBtnW + BtnGap
  Protected G_BtnClear = CanvasGadget(#PB_Any, CurX, ActY, ActBtnW, BtnH) : CurX + ActBtnW + BtnGap
  Protected G_BtnFill = CanvasGadget(#PB_Any, CurX, ActY, ActBtnW, BtnH) : CurX + ActBtnW + BtnGap
  Protected G_BtnClearBlock = CanvasGadget(#PB_Any, CurX, ActY, ActBtnW, BtnH)

  MamuteXd_DrawButton(G_BtnInvert, "INVERTER", BtnFont)
  MamuteXd_DrawButton(G_BtnClear, "LIMPAR", BtnFont)
  MamuteXd_DrawButton(G_BtnFill, "PREENCHER", BtnFont)
  MamuteXd_DrawButton(G_BtnClearBlock, "LIMPAR BLOCO", BtnFont)
  GadgetToolTip(G_BtnInvert, "Inverte todos os bits do caractere sob o cursor")
  GadgetToolTip(G_BtnClear, "Zera o caractere sob o cursor")
  GadgetToolTip(G_BtnFill, "Preenche o caractere sob o cursor (todos os bits em 1)")
  GadgetToolTip(G_BtnClearBlock, "Zera os 4 caracteres (32 bytes inteiros)")

  Protected StatusAddrDigits.i
  Macro MamuteXh_DoRepaint
    StatusAddrDigits = 4
    If State\Target\IsVram : StatusAddrDigits = 5 : EndIf
    SetGadgetText(G_AddrLabel, "Endereco: " + Mamute_HexPad(State\BaseAddr, StatusAddrDigits) + Mamute_SxTargetSuffixText(@State\Target))
    MamuteXh_RepaintGrid(G_Grid, @State, AddrLabelW, CharW, CharH)
    MamuteXh_DrawPreview(G_Preview, @State)
  EndMacro

  MamuteXh_DoRepaint
  SetActiveGadget(G_Grid)

  AddKeyboardShortcut(Win, #PB_Shortcut_Up, #MamuteXh_Shortcut_Up)
  AddKeyboardShortcut(Win, #PB_Shortcut_Down, #MamuteXh_Shortcut_Down)
  AddKeyboardShortcut(Win, #PB_Shortcut_Left, #MamuteXh_Shortcut_Left)
  AddKeyboardShortcut(Win, #PB_Shortcut_Right, #MamuteXh_Shortcut_Right)
  AddKeyboardShortcut(Win, #PB_Shortcut_PageUp, #MamuteXh_Shortcut_PageUp)
  AddKeyboardShortcut(Win, #PB_Shortcut_PageDown, #MamuteXh_Shortcut_PageDown)
  AddKeyboardShortcut(Win, #PB_Shortcut_Up | #PB_Shortcut_Shift, #MamuteXh_Shortcut_PageUp)
  AddKeyboardShortcut(Win, #PB_Shortcut_Down | #PB_Shortcut_Shift, #MamuteXh_Shortcut_PageDown)
  AddKeyboardShortcut(Win, #PB_Shortcut_Space, #MamuteXh_Shortcut_Space)
  AddKeyboardShortcut(Win, #PB_Shortcut_Return, #MamuteXh_Shortcut_Return)
  AddKeyboardShortcut(Win, #PB_Shortcut_Escape, #MamuteXh_Shortcut_Escape)

  Macro MamuteXh_DoMove(DRow, DCol)
    State\CursorRow + (DRow)
    State\CursorCol + (DCol)
    MamuteXh_ClampCursor(@State)
    MamuteXh_DoRepaint
  EndMacro

  Macro MamuteXh_DoPage(Delta)
    State\BaseAddr = Mamute_SxWrapAddr(State\BaseAddr + (Delta), @State\Target)
    MamuteXh_DoRepaint
  EndMacro

  Protected Event, Quit = #False
  Protected AlreadyClosed.b = #False ; #True quando um botao da cruz ja fechou a janela na hora
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_Grid
            If EventType() = #PB_EventType_LeftButtonDown
              Protected MouseX = GetGadgetAttribute(G_Grid, #PB_Canvas_MouseX)
              Protected MouseY = GetGadgetAttribute(G_Grid, #PB_Canvas_MouseY)
              Protected HitRow.i, HitCol.i
              If MamuteXh_HitTest(MouseX, MouseY, AddrLabelW, CharW, CharH, @HitRow, @HitCol)
                State\CursorRow = HitRow
                State\CursorCol = HitCol
                MamuteXh_DoRepaint
              EndIf
            EndIf

          Case G_ArrowUp    : If EventType() = #PB_EventType_LeftButtonDown : MamuteXh_DoMove(-1, 0) : EndIf
          Case G_ArrowDown  : If EventType() = #PB_EventType_LeftButtonDown : MamuteXh_DoMove(1, 0) : EndIf
          Case G_ArrowLeft  : If EventType() = #PB_EventType_LeftButtonDown : MamuteXh_DoMove(0, -1) : EndIf
          Case G_ArrowRight : If EventType() = #PB_EventType_LeftButtonDown : MamuteXh_DoMove(0, 1) : EndIf
          Case G_PageLeft   : If EventType() = #PB_EventType_LeftButtonDown : MamuteXh_DoPage(-32) : EndIf
          Case G_PageRight  : If EventType() = #PB_EventType_LeftButtonDown : MamuteXh_DoPage(32) : EndIf

          Case G_BtnInvert
            If EventType() = #PB_EventType_LeftButtonDown
              MamuteXh_InvertChar(@State)
              MamuteXh_DoRepaint
            EndIf

          Case G_BtnClear
            If EventType() = #PB_EventType_LeftButtonDown
              MamuteXh_ClearChar(@State)
              MamuteXh_DoRepaint
            EndIf

          Case G_BtnFill
            If EventType() = #PB_EventType_LeftButtonDown
              MamuteXh_FillChar(@State)
              MamuteXh_DoRepaint
            EndIf

          Case G_BtnClearBlock
            If EventType() = #PB_EventType_LeftButtonDown
              MamuteXh_ClearBlock(@State)
              MamuteXh_DoRepaint
            EndIf

          ; Cruz de modos (ver comentario no topo do arquivo) - Char ja e' o
          ; modo ativo (clique nao faz nada); Dump/Ascii/Multi/Disasm trocam
          ; de verdade pro XD/XA/XM/XI, no MESMO endereco/alvo.
          Case G_ModeChar
            ; ja e' o modo ativo - nada a fazer

          Case G_ModeDump
            If EventType() = #PB_EventType_LeftButtonDown
              CloseModelessChildWindow(ParentWindow, Win)
              AlreadyClosed = #True
              State\BaseAddr = MamuteXd_Open(ParentWindow, State\BaseAddr, 0, @State\Target)
              Quit = #True
            EndIf

          Case G_ModeAscii
            If EventType() = #PB_EventType_LeftButtonDown
              CloseModelessChildWindow(ParentWindow, Win)
              AlreadyClosed = #True
              State\BaseAddr = MamuteXa_Open(ParentWindow, State\BaseAddr, @State\Target)
              Quit = #True
            EndIf

          Case G_ModeMulti
            If EventType() = #PB_EventType_LeftButtonDown
              CloseModelessChildWindow(ParentWindow, Win)
              AlreadyClosed = #True
              State\BaseAddr = MamuteXm_Open(ParentWindow, State\BaseAddr, @State\Target)
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
          Case #MamuteXh_Shortcut_Up     : MamuteXh_DoMove(-1, 0)
          Case #MamuteXh_Shortcut_Down   : MamuteXh_DoMove(1, 0)
          Case #MamuteXh_Shortcut_Left   : MamuteXh_DoMove(0, -1)
          Case #MamuteXh_Shortcut_Right  : MamuteXh_DoMove(0, 1)
          Case #MamuteXh_Shortcut_PageUp   : MamuteXh_DoPage(-32)
          Case #MamuteXh_Shortcut_PageDown : MamuteXh_DoPage(32)

          Case #MamuteXh_Shortcut_Space
            MamuteXh_ToggleBit(@State, State\CursorRow, State\CursorCol)
            MamuteXh_DoRepaint

          Case #MamuteXh_Shortcut_Return, #MamuteXh_Shortcut_Escape
            Quit = #True
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
