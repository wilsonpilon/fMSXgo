;
; ------------------------------------------------------------
;  Comando ZAP (editor de Setores de disco) do Mamute Assembler - "muito
;  parecido com o DM" (MamuteDumpGui.pbi, mesma grade/cursor/mouse/teclado),
;  pedido explicito do usuario, so que em vez de mostrar/editar a memoria
;  simulada do MSX (MamuteMem()), abre uma IMAGEM DE DISCO (.dsk) e mostra/
;  edita os bytes crus dela, setor a setor (512 bytes/setor, FAT12 - 720KB
;  e a prioridade, mas 360KB/180KB tambem funcionam, qualquer combinacao de
;  face simples/dupla e densidade simples/dupla de 5 1/4 ou 3 1/2 polegadas,
;  ja que o ZAP nao interpreta a estrutura FAT12 nenhuma - so le/escreve
;  bytes crus por posicao, igual um editor de setor de disco de verdade da
;  epoca).
;
;  "ZAP <setor inicial>[,<deslocamento>]" (MamuteAssemblerGui.pbi analisa e
;  chama MamuteZap_Open abaixo) pede um arquivo .DSK primeiro (OpenFileRequester),
;  carrega ele inteiro num buffer em memoria (MamuteZapDisk()) e abre a
;  grade no setor pedido (setor * 512 = deslocamento inicial). Cada tela
;  mostra 128 bytes (16 linhas de 8) - como um setor inteiro (512 bytes) e
;  multiplo exato de 128, uma tela nunca atravessa dois setores ao mesmo
;  tempo (paginar +-128 sempre anda dentro do MESMO setor ou pula pro
;  proximo/anterior de forma alinhada).
;
;  DIFERENCA CHAVE em relacao ao DM: edicoes aqui ficam so no buffer em
;  memoria ate o usuario apertar Ctrl+S (ou o botao "Salvar Setor", pedido
;  explicito do usuario) - so ENTAO os 512 bytes do setor onde o CURSOR
;  esta agora sao gravados de volta no arquivo .dsk de verdade (gravacao
;  cirurgica, so aquele setor, nao o disco inteiro). O titulo da janela
;  ganha um "*" enquanto ha alteracoes nao salvas em qualquer setor; fechar
;  a janela nesse estado pede confirmacao.
; ------------------------------------------------------------
;

#MamuteZap_SectorSize = 512

#MamuteZap_Shortcut_Up       = 9301
#MamuteZap_Shortcut_Down     = 9302
#MamuteZap_Shortcut_Left     = 9303
#MamuteZap_Shortcut_Right    = 9304
#MamuteZap_Shortcut_PageUp   = 9305
#MamuteZap_Shortcut_PageDown = 9306
#MamuteZap_Shortcut_Tab      = 9307
#MamuteZap_Shortcut_Return   = 9308
#MamuteZap_Shortcut_Escape   = 9309
#MamuteZap_Shortcut_Add      = 9310
#MamuteZap_Shortcut_Sub      = 9311
#MamuteZap_Shortcut_Save     = 9312

#MamuteZap_EditMode_None = 0
#MamuteZap_EditMode_Hex  = 1
#MamuteZap_EditMode_Text = 2

; Buffer com o conteudo inteiro do .dsk carregado agora (ate 720KB nos
; formatos MSX padrao, mas nao trava em outros tamanhos - ver
; MamuteZap_LoadDisk). Global (nao Protected local) de proposito - so uma
; janela de ZAP por vez faz sentido, igual MamuteGui_Font/MamutePageMap.
Global Dim MamuteZapDisk.a(0)
Global MamuteZapDiskSize.i = 0
Global MamuteZapDiskPath.s = ""

Procedure.s MamuteZap_SizeLabel(Sz.i)
  Select Sz
    Case 184320 : ProcedureReturn "180KB"
    Case 368640 : ProcedureReturn "360KB"
    Case 737280 : ProcedureReturn "720KB"
  EndSelect
  ProcedureReturn "tamanho nao-padrao"
EndProcedure

; Le o arquivo inteiro pro buffer, arredondando pra cima pro proximo setor
; completo (ReDim zera os bytes novos - a "sobra" alem do fim real do
; arquivo, se o tamanho nao for multiplo exato de 512, fica como zero).
Procedure.b MamuteZap_LoadDisk(Path.s)
  Protected Sz.i = FileSize(Path)
  If Sz <= 0
    ProcedureReturn #False
  EndIf
  Protected TotalSectors.i = (Sz + #MamuteZap_SectorSize - 1) / #MamuteZap_SectorSize
  Protected BufSize.i = TotalSectors * #MamuteZap_SectorSize

  Protected FNum = ReadFile(#PB_Any, Path)
  If Not FNum
    ProcedureReturn #False
  EndIf
  ReDim MamuteZapDisk.a(BufSize - 1)
  ReadData(FNum, @MamuteZapDisk(0), Sz)
  CloseFile(FNum)

  MamuteZapDiskSize = BufSize
  MamuteZapDiskPath = Path
  ProcedureReturn #True
EndProcedure

Procedure.a MamuteZap_ReadByte(Offset.i)
  If Offset < 0 Or Offset >= MamuteZapDiskSize
    ProcedureReturn 0
  EndIf
  ProcedureReturn MamuteZapDisk(Offset)
EndProcedure

Procedure MamuteZap_WriteByte(Offset.i, Value.a)
  If Offset < 0 Or Offset >= MamuteZapDiskSize
    ProcedureReturn
  EndIf
  MamuteZapDisk(Offset) = Value
EndProcedure

; Grava os #MamuteZap_SectorSize bytes a partir de SectorStart (deve ja vir
; alinhado a um setor - ver chamador) de volta no ARQUIVO DE VERDADE -
; unico ponto que toca o .dsk em disco, tudo o mais so mexe no buffer.
Procedure.b MamuteZap_SaveSector(SectorStart.i)
  If MamuteZapDiskPath = "" Or SectorStart < 0 Or SectorStart + #MamuteZap_SectorSize > MamuteZapDiskSize
    ProcedureReturn #False
  EndIf
  Protected FNum = OpenFile(#PB_Any, MamuteZapDiskPath)
  If Not FNum
    ProcedureReturn #False
  EndIf
  FileSeek(FNum, SectorStart)
  WriteData(FNum, @MamuteZapDisk(SectorStart), #MamuteZap_SectorSize)
  CloseFile(FNum)
  ProcedureReturn #True
EndProcedure

Procedure.s MamuteZap_DisplayChar(RawByte.a, Offset.i)
  Protected V.i = (RawByte + Offset) & $FF
  If V >= 32 And V <= 126
    ProcedureReturn Chr(V)
  EndIf
  ProcedureReturn "."
EndProcedure

Structure MamuteZapState
  BaseOffset.i  ; deslocamento linear (0..DiskSize-1) do primeiro byte mostrado
  Offset.i      ; deslocamento ASCII ativo (-7Fh..80h)
  CursorRow.i
  CursorCol.i
  CursorBlock.i ; 0=hex, 1=texto
  EditMode.i    ; #MamuteZap_EditMode_*
  Dirty.b       ; #True se ha alteracao em algum setor ainda nao gravada no arquivo
EndStructure

Procedure MamuteZap_ClampCursor(*State.MamuteZapState)
  If *State\CursorRow < 0 : *State\CursorRow = 0 : EndIf
  If *State\CursorRow > 15 : *State\CursorRow = 15 : EndIf
  If *State\CursorCol < 0 : *State\CursorCol = 0 : EndIf
  If *State\CursorCol > 7 : *State\CursorCol = 7 : EndIf
EndProcedure

Procedure.i MamuteZap_CellOffset(*State.MamuteZapState, Row.i, Col.i)
  ProcedureReturn *State\BaseOffset + Row * 8 + Col
EndProcedure

; Maior BaseOffset valido (ultima tela de 128 bytes que ainda cabe inteira
; no disco) - paginacao/abertura ficam sempre dentro disso, ao contrario do
; DM (que envolve o endereco de CPU em 64KB, aqui o disco tem tamanho
; finito de verdade, entao trava nas pontas em vez de dar a volta).
Procedure.i MamuteZap_MaxBaseOffset()
  Protected M.i = MamuteZapDiskSize - 128
  If M < 0 : M = 0 : EndIf
  ProcedureReturn M
EndProcedure

Procedure MamuteZap_Repaint(Canvas, *State.MamuteZapState, HexX.i, AsciiX.i, CharW.i, CharH.i, HalfCharW.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf

  Protected ColBack        = Mamute_CurrentBackColor()
  Protected ColFront       = Mamute_CurrentFrontColor()
  Protected ColDim         = RGB(25, 110, 50)
  Protected ColCursorBack  = Mamute_CurrentFrontColor()
  Protected ColCursorFront = Mamute_CurrentBackColor()

  Box(0, 0, GadgetWidth(Canvas), GadgetHeight(Canvas), ColBack)

  Protected r.i, c.i, RowStart.i, CellOff.i, RawByte.a, bx.i, ax.i, RowY.i

  For r = 0 To 15
    RowY = r * CharH
    RowStart = MamuteZap_CellOffset(*State, r, 0)
    DrawText(0, RowY, RSet(Hex(RowStart % #MamuteZap_SectorSize), 3, "0") + ":", ColDim, ColBack)

    For c = 0 To 7
      CellOff = MamuteZap_CellOffset(*State, r, c)
      RawByte = MamuteZap_ReadByte(CellOff)
      bx = HexX + c * HalfCharW * 3
      If r = *State\CursorRow And c = *State\CursorCol And *State\CursorBlock = 0
        Box(bx - 2, RowY - 1, CharW + 3, CharH - 1, ColCursorBack)
        DrawText(bx, RowY, RSet(Hex(RawByte & $FF), 2, "0"), ColCursorFront, ColCursorBack)
      Else
        DrawText(bx, RowY, RSet(Hex(RawByte & $FF), 2, "0"), ColFront, ColBack)
      EndIf
    Next

    For c = 0 To 7
      CellOff = MamuteZap_CellOffset(*State, r, c)
      RawByte = MamuteZap_ReadByte(CellOff)
      ax = AsciiX + c * HalfCharW
      If r = *State\CursorRow And c = *State\CursorCol And *State\CursorBlock = 1
        Box(ax - 1, RowY - 1, HalfCharW + 2, CharH - 1, ColCursorBack)
        DrawText(ax, RowY, MamuteZap_DisplayChar(RawByte, *State\Offset), ColCursorFront, ColCursorBack)
      Else
        DrawText(ax, RowY, MamuteZap_DisplayChar(RawByte, *State\Offset), ColFront, ColBack)
      EndIf
    Next
  Next

  StopDrawing()
EndProcedure

; Mesma tecnica de hit-test em loop de MamuteDumpGui.pbi/HexEditorGui.pbi.
Procedure.b MamuteZap_HitTest(MouseX.i, MouseY.i, HexX.i, AsciiX.i, CharW.i, CharH.i, HalfCharW.i,
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

Procedure MamuteZap_DrawButton(Canvas, Label.s, Font, AccentColor.l = -1)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected W = GadgetWidth(Canvas), H = GadgetHeight(Canvas)
  Protected Fg = Mamute_CurrentFrontColor()
  If AccentColor <> -1 : Fg = AccentColor : EndIf
  Box(0, 0, W, H, Mamute_CurrentBackColor())
  DrawingMode(#PB_2DDrawing_Outlined)
  Box(0, 0, W, H, Fg)
  DrawingMode(#PB_2DDrawing_Transparent)
  DrawingFont(FontID(Font))
  Protected TW = TextWidth(Label), TH = TextHeight(Label)
  DrawText((W - TW) / 2, (H - TH) / 2, Label, Fg)
  StopDrawing()
EndProcedure

Procedure MamuteZap_UpdateStatus(G_SectorLabel, G_OffsetLabel, *State.MamuteZapState)
  SetGadgetText(G_SectorLabel, "Setor: " + RSet(Hex(*State\BaseOffset / #MamuteZap_SectorSize), 4, "0") +
                               "  Byte: " + RSet(Hex(*State\BaseOffset), 6, "0"))
  Protected Sign.s = "+"
  Protected AbsOff.i = *State\Offset
  If AbsOff < 0
    Sign = "-"
    AbsOff = -AbsOff
  EndIf
  SetGadgetText(G_OffsetLabel, "Desloc.:  " + Sign + RSet(Hex(AbsOff & $FF), 2, "0"))
EndProcedure

Procedure MamuteZap_UpdateTitle(Win, *State.MamuteZapState)
  Protected Title.s = "Mamute Assembler - ZAP - " + GetFilePart(MamuteZapDiskPath) +
                      " (" + MamuteZap_SizeLabel(MamuteZapDiskSize) + ")"
  If *State\Dirty
    Title + " *"
  EndIf
  SetWindowTitle(Win, Title)
EndProcedure

; ParentWindow: janela do monitor MON> que pediu o ZAP. StartSector/StartOffset
; ja validados (hexa, StartOffset em -7Fh..80h) por MamuteGui_CmdZap.
Procedure MamuteZap_Open(ParentWindow, StartSector.i, StartOffset.i)
  Protected PickedPath.s = OpenFileRequester("Selecione a imagem de disco (DSK) para o ZAP", "", #File_Pattern_Disk, 0)
  If PickedPath = ""
    ProcedureReturn
  EndIf
  If Not MamuteZap_LoadDisk(PickedPath)
    MessageRequester("ZAP", "Nao foi possivel abrir o arquivo:" + Chr(10) + PickedPath,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  Protected State.MamuteZapState
  State\BaseOffset = StartSector * #MamuteZap_SectorSize
  Protected MaxBase.i = MamuteZap_MaxBaseOffset()
  If State\BaseOffset > MaxBase : State\BaseOffset = MaxBase : EndIf
  If State\BaseOffset < 0 : State\BaseOffset = 0 : EndIf
  State\Offset = StartOffset
  State\CursorRow = 0
  State\CursorCol = 0
  State\CursorBlock = 0
  State\EditMode = #MamuteZap_EditMode_None
  State\Dirty = #False

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
    AddrLabelW = TextWidth("000: ")
    GapW = TextWidth("  ")
    StopDrawing()
  EndIf
  If MeasureImg : FreeImage(MeasureImg) : EndIf
  If CharW <= 0 : CharW = 18 : EndIf
  If CharH <= 0 : CharH = 20 : EndIf
  If AddrLabelW <= 0 : AddrLabelW = 54 : EndIf
  If GapW <= 0 : GapW = 16 : EndIf
  Protected HalfCharW = CharW / 2
  If HalfCharW <= 0 : HalfCharW = 8 : EndIf

  Protected HexX = AddrLabelW
  Protected AsciiX = HexX + 8 * HalfCharW * 3 + GapW
  Protected GridW = AsciiX + 8 * HalfCharW + 16
  Protected GridH = 16 * CharH

  Protected Margin = 16
  Protected BtnH = 40, BtnGap = 8
  Protected SaveBtnW = 150

  Protected RowW = 56 + BtnGap + BtnH + BtnGap + BtnH + BtnGap + BtnH + BtnGap + BtnH + BtnGap + 56 + BtnGap * 3 +
                   36 + BtnGap + 36 + BtnGap * 3 + SaveBtnW

  Protected WinW = GridW + Margin * 2
  If RowW + Margin * 2 > WinW
    WinW = RowW + Margin * 2
  EndIf

  Protected LegendH = 20, StatusH = 24
  Protected WinH = Margin + LegendH + 8 + GridH + 12 + StatusH + 4 + StatusH + 12 + BtnH + Margin

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Mamute Assembler - ZAP",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #True, #False)
  If Not Win
    ProcedureReturn
  EndIf
  SetWindowColor(Win, Mamute_CurrentBorderColor())

  Protected ColFront = Mamute_CurrentFrontColor(), ColBack = Mamute_CurrentBackColor()
  Protected CurY = Margin

  Protected G_Legend = TextGadget(#PB_Any, Margin, CurY, WinW - Margin * 2, LegendH,
                                  "Setas/PgUp/PgDn: mover  TAB: hex/texto  RETURN: editar  ESC: sair  +/-: desloc.  Ctrl+S: salvar setor")
  SetGadgetColor(G_Legend, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Legend, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Legend, FontID(DumpFont))
  CurY + LegendH + 8

  Protected GridY = CurY
  Protected G_Grid = CanvasGadget(#PB_Any, Margin, GridY, GridW, GridH, #PB_Canvas_Keyboard)
  CurY + GridH + 12

  Protected G_SectorLabel = TextGadget(#PB_Any, Margin, CurY, 300, StatusH, "")
  SetGadgetColor(G_SectorLabel, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_SectorLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_SectorLabel, FontID(DumpFont))
  CurY + StatusH + 4

  Protected G_OffsetLabel = TextGadget(#PB_Any, Margin, CurY, 260, StatusH, "")
  SetGadgetColor(G_OffsetLabel, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_OffsetLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_OffsetLabel, FontID(DumpFont))

  Protected G_EditLabel = TextGadget(#PB_Any, 340, CurY, 70, StatusH, "Editar:")
  SetGadgetColor(G_EditLabel, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_EditLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_EditLabel, FontID(DumpFont))
  Protected G_EditField = StringGadget(#PB_Any, 412, CurY - 2, WinW - 412 - Margin, StatusH + 4, "")
  SetGadgetColor(G_EditField, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_EditField, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_EditField, FontID(DumpFont))
  HideGadget(G_EditLabel, #True)
  HideGadget(G_EditField, #True)
  CurY + StatusH + 12

  Protected BtnFont = LoadFont(#PB_Any, "Consolas", 14, #PB_Font_Bold)
  If Not BtnFont : BtnFont = DumpFont : EndIf

  Protected BtnY = CurY
  Protected CurX = Margin
  Protected G_PageLeft = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH)  : CurX + 56 + BtnGap
  Protected G_ArrowLeft = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH) : CurX + BtnH + BtnGap
  Protected G_ArrowUp = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH) : CurX + BtnH + BtnGap
  Protected G_ArrowDown = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH) : CurX + BtnH + BtnGap
  Protected G_ArrowRight = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH) : CurX + BtnH + BtnGap
  Protected G_PageRight = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH) : CurX + 56 + BtnGap * 3
  Protected G_MinusBtn = CanvasGadget(#PB_Any, CurX, BtnY, 36, BtnH) : CurX + 36 + BtnGap
  Protected G_PlusBtn = CanvasGadget(#PB_Any, CurX, BtnY, 36, BtnH) : CurX + 36 + BtnGap * 3
  Protected G_SaveBtn = CanvasGadget(#PB_Any, CurX, BtnY, SaveBtnW, BtnH)

  MamuteZap_DrawButton(G_PageLeft, "<<", BtnFont)
  MamuteZap_DrawButton(G_ArrowLeft, "<", BtnFont)
  MamuteZap_DrawButton(G_ArrowUp, "^", BtnFont)
  MamuteZap_DrawButton(G_ArrowDown, "v", BtnFont)
  MamuteZap_DrawButton(G_ArrowRight, ">", BtnFont)
  MamuteZap_DrawButton(G_PageRight, ">>", BtnFont)
  MamuteZap_DrawButton(G_MinusBtn, "-", BtnFont)
  MamuteZap_DrawButton(G_PlusBtn, "+", BtnFont)
  ; Cor propria (amarelo) pro botao de salvar - se destaca dos demais
  ; (todos verdes), pedido explicito do usuario ("crie o botao salvar
  ; setor tambem").
  MamuteZap_DrawButton(G_SaveBtn, "SALVAR SETOR", BtnFont, RGB(230, 200, 40))
  GadgetToolTip(G_PageLeft, "-128 bytes")
  GadgetToolTip(G_PageRight, "+128 bytes")
  GadgetToolTip(G_MinusBtn, "Desloc. -1")
  GadgetToolTip(G_PlusBtn, "Desloc. +1")
  GadgetToolTip(G_SaveBtn, "Salvar o setor sob o cursor no arquivo .dsk (Ctrl+S)")

  MamuteZap_UpdateStatus(G_SectorLabel, G_OffsetLabel, @State)
  MamuteZap_UpdateTitle(Win, @State)
  MamuteZap_Repaint(G_Grid, @State, HexX, AsciiX, CharW, CharH, HalfCharW)
  SetActiveGadget(G_Grid)

  AddKeyboardShortcut(Win, #PB_Shortcut_Up, #MamuteZap_Shortcut_Up)
  AddKeyboardShortcut(Win, #PB_Shortcut_Down, #MamuteZap_Shortcut_Down)
  AddKeyboardShortcut(Win, #PB_Shortcut_Left, #MamuteZap_Shortcut_Left)
  AddKeyboardShortcut(Win, #PB_Shortcut_Right, #MamuteZap_Shortcut_Right)
  AddKeyboardShortcut(Win, #PB_Shortcut_PageUp, #MamuteZap_Shortcut_PageUp)
  AddKeyboardShortcut(Win, #PB_Shortcut_PageDown, #MamuteZap_Shortcut_PageDown)
  AddKeyboardShortcut(Win, #PB_Shortcut_Tab, #MamuteZap_Shortcut_Tab)
  AddKeyboardShortcut(Win, #PB_Shortcut_Return, #MamuteZap_Shortcut_Return)
  AddKeyboardShortcut(Win, #PB_Shortcut_Escape, #MamuteZap_Shortcut_Escape)
  AddKeyboardShortcut(Win, #PB_Shortcut_Add, #MamuteZap_Shortcut_Add)
  AddKeyboardShortcut(Win, #PB_Shortcut_Subtract, #MamuteZap_Shortcut_Sub)
  AddKeyboardShortcut(Win, #PB_Shortcut_Control | #PB_Shortcut_S, #MamuteZap_Shortcut_Save)

  ; Hoisted pra fora das macros correspondentes de proposito - cada uma e
  ; expandida em MAIS DE UM ponto deste Procedure (botao + atalho de
  ; teclado), e uma Macro nao pode ter "Protected" proprio quando expandida
  ; mais de uma vez no mesmo Procedure (duplica a declaracao - ver nota em
  ; MamuteDumpGui.pbi, mesmo achado de sintaxe do PureBasic).
  Protected NewOff.i    ; MamuteZap_DoOffset
  Protected NewBase.i   ; MamuteZap_DoPage
  Protected CursorOff.i ; MamuteZap_DoSave
  Protected SectorStart.i ; MamuteZap_DoSave

  Macro MamuteZap_DoRepaint
    MamuteZap_UpdateStatus(G_SectorLabel, G_OffsetLabel, @State)
    MamuteZap_UpdateTitle(Win, @State)
    MamuteZap_Repaint(G_Grid, @State, HexX, AsciiX, CharW, CharH, HalfCharW)
  EndMacro

  Macro MamuteZap_DoMove(DRow, DCol)
    If State\EditMode = #MamuteZap_EditMode_None
      State\CursorRow + (DRow)
      State\CursorCol + (DCol)
      MamuteZap_ClampCursor(@State)
      MamuteZap_DoRepaint
    EndIf
  EndMacro

  Macro MamuteZap_DoPage(Delta)
    NewBase = State\BaseOffset + (Delta)
    If NewBase < 0 : NewBase = 0 : EndIf
    If NewBase > MamuteZap_MaxBaseOffset() : NewBase = MamuteZap_MaxBaseOffset() : EndIf
    State\BaseOffset = NewBase
    MamuteZap_DoRepaint
  EndMacro

  Macro MamuteZap_DoOffset(Delta)
    NewOff = State\Offset + (Delta)
    If NewOff < -$7F : NewOff = -$7F : EndIf
    If NewOff > $80 : NewOff = $80 : EndIf
    State\Offset = NewOff
    MamuteZap_DoRepaint
  EndMacro

  Macro MamuteZap_BeginEdit
    Protected EditOff.i = MamuteZap_CellOffset(@State, State\CursorRow, State\CursorCol)
    Protected EditRaw.a = MamuteZap_ReadByte(EditOff)
    If State\CursorBlock = 0
      State\EditMode = #MamuteZap_EditMode_Hex
      SetGadgetText(G_EditLabel, "Hex:")
      SetGadgetText(G_EditField, RSet(Hex(EditRaw & $FF), 2, "0"))
    Else
      State\EditMode = #MamuteZap_EditMode_Text
      SetGadgetText(G_EditLabel, "Texto:")
      SetGadgetText(G_EditField, MamuteZap_DisplayChar(EditRaw, State\Offset))
    EndIf
    HideGadget(G_EditLabel, #False)
    HideGadget(G_EditField, #False)
    SetActiveGadget(G_EditField)
  EndMacro

  Macro MamuteZap_CancelEdit
    State\EditMode = #MamuteZap_EditMode_None
    HideGadget(G_EditLabel, #True)
    HideGadget(G_EditField, #True)
    SetGadgetText(G_EditField, "")
    SetActiveGadget(G_Grid)
  EndMacro

  Macro MamuteZap_CommitEdit
    Protected Typed.s = GetGadgetText(G_EditField)
    If State\EditMode = #MamuteZap_EditMode_Hex
      If Mamute_IsHexString(Typed, 2)
        Protected HexOff.i = MamuteZap_CellOffset(@State, State\CursorRow, State\CursorCol)
        MamuteZap_WriteByte(HexOff, Val("$" + Typed) & $FF)
        State\Dirty = #True
        MamuteZap_CancelEdit
        MamuteZap_DoRepaint
      EndIf
    ElseIf State\EditMode = #MamuteZap_EditMode_Text And Typed <> ""
      Protected TIdx.i, TOff.i, TCell.i = State\CursorRow * 8 + State\CursorCol
      For TIdx = 1 To Len(Typed)
        If TCell > 127 : Break : EndIf
        TOff = MamuteZap_CellOffset(@State, TCell / 8, TCell % 8)
        MamuteZap_WriteByte(TOff, (Asc(Mid(Typed, TIdx, 1)) - State\Offset) & $FF)
        TCell + 1
      Next
      State\Dirty = #True
      If TCell > 127 : TCell = 127 : EndIf
      State\CursorRow = TCell / 8
      State\CursorCol = TCell % 8
      MamuteZap_CancelEdit
      MamuteZap_DoRepaint
    EndIf
  EndMacro

  ; Grava os 512 bytes do setor onde o CURSOR esta agora (nao necessariamente
  ; o inicio da tela) de volta no .dsk de verdade.
  Macro MamuteZap_DoSave
    CursorOff = MamuteZap_CellOffset(@State, State\CursorRow, State\CursorCol)
    SectorStart = (CursorOff / #MamuteZap_SectorSize) * #MamuteZap_SectorSize
    If MamuteZap_SaveSector(SectorStart)
      State\Dirty = #False
      MamuteZap_DoRepaint
    Else
      MessageRequester("ZAP", "Nao foi possivel gravar o setor no arquivo.",
                       #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    EndIf
  EndMacro

  ; #True = pode fechar (sem alteracoes pendentes, ou usuario confirmou
  ; descartar); #False = usuario cancelou o fechamento.
  Macro MamuteZap_ConfirmClose
    (Bool(Not State\Dirty) Or MessageRequester("ZAP",
      "Ha alteracoes nao salvas neste disco (algum setor editado sem" + Chr(10) +
      "apertar Ctrl+S / " + Chr(34) + "Salvar Setor" + Chr(34) + "). Fechar mesmo assim, descartando?",
      #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
  EndMacro

  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_Grid
            If EventType() = #PB_EventType_LeftButtonDown And State\EditMode = #MamuteZap_EditMode_None
              Protected MouseX = GetGadgetAttribute(G_Grid, #PB_Canvas_MouseX)
              Protected MouseY = GetGadgetAttribute(G_Grid, #PB_Canvas_MouseY)
              Protected HitRow.i, HitCol.i, HitBlock.i
              If MamuteZap_HitTest(MouseX, MouseY, HexX, AsciiX, CharW, CharH, HalfCharW, @HitRow, @HitCol, @HitBlock)
                State\CursorRow = HitRow
                State\CursorCol = HitCol
                State\CursorBlock = HitBlock
                MamuteZap_DoRepaint
              EndIf
            EndIf

          Case G_ArrowUp
            If EventType() = #PB_EventType_LeftButtonDown : MamuteZap_DoMove(-1, 0) : EndIf
          Case G_ArrowDown
            If EventType() = #PB_EventType_LeftButtonDown : MamuteZap_DoMove(1, 0) : EndIf
          Case G_ArrowLeft
            If EventType() = #PB_EventType_LeftButtonDown : MamuteZap_DoMove(0, -1) : EndIf
          Case G_ArrowRight
            If EventType() = #PB_EventType_LeftButtonDown : MamuteZap_DoMove(0, 1) : EndIf
          Case G_PageLeft
            If EventType() = #PB_EventType_LeftButtonDown : MamuteZap_DoPage(-128) : EndIf
          Case G_PageRight
            If EventType() = #PB_EventType_LeftButtonDown : MamuteZap_DoPage(128) : EndIf
          Case G_MinusBtn
            If EventType() = #PB_EventType_LeftButtonDown : MamuteZap_DoOffset(-1) : EndIf
          Case G_PlusBtn
            If EventType() = #PB_EventType_LeftButtonDown : MamuteZap_DoOffset(1) : EndIf
          Case G_SaveBtn
            If EventType() = #PB_EventType_LeftButtonDown : MamuteZap_DoSave : EndIf
        EndSelect

      Case #PB_Event_Menu
        Select EventMenu()
          Case #MamuteZap_Shortcut_Up     : MamuteZap_DoMove(-1, 0)
          Case #MamuteZap_Shortcut_Down   : MamuteZap_DoMove(1, 0)
          Case #MamuteZap_Shortcut_Left   : MamuteZap_DoMove(0, -1)
          Case #MamuteZap_Shortcut_Right  : MamuteZap_DoMove(0, 1)
          Case #MamuteZap_Shortcut_PageUp   : If State\EditMode = #MamuteZap_EditMode_None : MamuteZap_DoPage(-128) : EndIf
          Case #MamuteZap_Shortcut_PageDown : If State\EditMode = #MamuteZap_EditMode_None : MamuteZap_DoPage(128) : EndIf
          Case #MamuteZap_Shortcut_Add : If State\EditMode = #MamuteZap_EditMode_None : MamuteZap_DoOffset(1) : EndIf
          Case #MamuteZap_Shortcut_Sub : If State\EditMode = #MamuteZap_EditMode_None : MamuteZap_DoOffset(-1) : EndIf
          Case #MamuteZap_Shortcut_Save : If State\EditMode = #MamuteZap_EditMode_None : MamuteZap_DoSave : EndIf

          Case #MamuteZap_Shortcut_Tab
            If State\EditMode = #MamuteZap_EditMode_None
              If State\CursorBlock = 0 : State\CursorBlock = 1 : Else : State\CursorBlock = 0 : EndIf
              MamuteZap_DoRepaint
            EndIf

          Case #MamuteZap_Shortcut_Return
            If State\EditMode = #MamuteZap_EditMode_None
              MamuteZap_BeginEdit
            Else
              MamuteZap_CommitEdit
            EndIf

          Case #MamuteZap_Shortcut_Escape
            If State\EditMode <> #MamuteZap_EditMode_None
              MamuteZap_CancelEdit
            ElseIf MamuteZap_ConfirmClose
              Quit = #True
            EndIf
        EndSelect

      Case #PB_Event_CloseWindow
        If MamuteZap_ConfirmClose
          Quit = #True
        EndIf
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
