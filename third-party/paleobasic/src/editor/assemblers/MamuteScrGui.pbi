;
; ------------------------------------------------------------
;  Comando SCR (display grafico da memoria) do Mamute Assembler - o comando
;  mais complexo ate agora. "SCR <endinic>,<dx>,<dy>[,<modo>]" mostra uma
;  tela FIXA de 256x192 pixels (32x24 caracteres 8x8, exatamente a resolucao
;  de um SCREEN 2/1 real do MSX) preenchida com a memoria a partir de
;  <endinic>. <dx>/<dy> NAO mudam o tamanho da tela (sempre 256x192) - eles
;  definem o "azulejo" (tile) de <dx> x <dy> caracteres usado pra varrer a
;  memoria: a tela inteira e ladrilhada com azulejos de <dx>x<dy> caracteres
;  (esquerda->direita, cima->baixo), e DENTRO de cada azulejo os blocos de 8
;  bytes sao lidos na ordem horizontal (linha por linha, <modo>=0) ou
;  vertical (coluna por coluna, <modo>=1 - a mesma ordem real de
;  armazenamento de sprites do MSX, por isso o manual chama de "formato
;  sprite"). Com <dx>=<dy>=1 cada azulejo e 1 caractere so, entao a tela
;  inteira vira uma leitura sequencial simples - o caso `SCR 1BBF,1,1` do
;  usuario, que mostra a tabela de caracteres da ROM ladrilhando a tela
;  toda, igual ao MegaAssembler original (confirmado contra uma captura de
;  tela real do usuario rodando o produto original no emulador).
;
;  A "moldura 2x2" do manual original e um cursor de EDICAO de tamanho
;  FIXO - sempre 2x2 CARACTERES (16x16 pixels), sempre ancorado no canto
;  superior esquerdo da tela (caracteres de tela (0,0),(1,0),(0,1),(1,1) -
;  "dois de cima, dois de baixo da proxima linha", confirmado pelo usuario
;  contra uma captura real). Nao existe tecla no manual original pra mover
;  essa moldura pela tela - a unica forma de trazer um pedaco diferente da
;  memoria pra dentro dela e rolar o endereco base (setas fora do modo de
;  edicao). `ENTER` amplia exatamente esses 16x16 pixels fixos num painel a
;  parte pra edicao fina.
;
;  Teclas - REMAPEADAS a pedido explicito do usuario em relacao ao manual
;  original (que usava CTRL+STOP/RETURN/ESC/TAB/I/SHIFT+HOME):
;    Navegacao (fora de edicao):
;      Setas esq/dir - BaseAddr -+ 1 byte (ajuste fino de alinhamento)
;      Setas cima/baixo - BaseAddr -+ 1 bloco inteiro (dx*dy*8 bytes)
;      ENTER - entra no modo de edicao (amplia a moldura fixa)
;      TAB - liga/desliga o contorno decorativo da moldura sobre a tela
;      E - mostra/oculta o rotulo com o endereco base atual
;      ESC - encerra o comando (fecha a janela)
;    Edicao (ENTER) - so afeta os 16x16 pixels da moldura:
;      Setas - movem o cursor de pixel dentro da moldura (0-15,0-15)
;      ESPACO - inverte o ponto (pixel) sob o cursor
;      I - inverte (XOR) os 16x16 pixels INTEIROS da moldura de uma vez
;      L - apaga (zera) os 16x16 pixels INTEIROS da moldura de uma vez
;      ENTER - sai do modo de edicao (as alteracoes ja foram escritas)
;      ESC - cancela as alteracoes feitas nesta sessao de edicao (restaura
;            um snapshot tirado ao entrar) e sai do modo de edicao
;  Botoes na tela pra cada uma dessas acoes, mesmo espirito do DM/ZAP -
;  pedido explicito do usuario ("vamos criar botoes como no comando DM e
;  ZAP").
;
;  Se a moldura cair sobre uma celula que NAO seja RAM (ROM/BASIC/Vazio) -
;  pedido explicito do usuario ("as vezes ampliamos pra ver algum detalhe da
;  tela, nao pra editar propriamente dito"): o painel de edicao mostra o
;  conteudo REAL normalmente (nao mais em branco) e todas as teclas de
;  edicao continuam respondendo, MAS Mamute_WriteByte()/Mamute_CanWriteAt()
;  ja recusam a escrita de verdade pra celulas nao-RAM - nada e gravado, o
;  pixel so mostra de novo o mesmo valor real no proximo repaint. Um rotulo
;  amarelo "ROM - somente leitura" avisa quando isso esta acontecendo.
;  Modificar ROM de verdade fica pra uma sessao futura (ideia do usuario,
;  ainda nao pedida).
;
;  Leitura/escrita reaproveita Mamute_ReadByte()/Mamute_WriteByte()/
;  Mamute_CanWriteAt() (MamuteSupport.pbi).
; ------------------------------------------------------------
;

#MamuteScr_Shortcut_Up      = 9401
#MamuteScr_Shortcut_Down    = 9402
#MamuteScr_Shortcut_Left    = 9403
#MamuteScr_Shortcut_Right   = 9404
#MamuteScr_Shortcut_Tab     = 9405
#MamuteScr_Shortcut_Return  = 9406
#MamuteScr_Shortcut_Escape  = 9407
#MamuteScr_Shortcut_Address = 9408
#MamuteScr_Shortcut_Space   = 9409
#MamuteScr_Shortcut_Invert  = 9410
#MamuteScr_Shortcut_Erase   = 9411

#Mamute_ScrCols = 32 ; 256/8 - largura da tela fixa, em caracteres
#Mamute_ScrRows = 24 ; 192/8 - altura da tela fixa, em caracteres
#Mamute_MolduraChars = 2 ; moldura sempre 2x2 caracteres = 16x16 pixels, fixo

Structure MamuteScrState
  BaseAddr.i    ; endereco (0-65535) do primeiro byte do primeiro azulejo
  Dx.i          ; largura do azulejo de leitura, em caracteres
  Dy.i          ; altura do azulejo de leitura, em caracteres
  Modo.i        ; 0 = horizontal (row-major DENTRO do azulejo), 1 = vertical/sprite
  FrameOn.b     ; contorno da moldura visivel sobre a tela (TAB)
  AddrVisible.b ; rotulo de endereco visivel (E)
  EditMode.b    ; dentro do modo de edicao (ENTER)
  CursorPX.i    ; cursor de pixel DENTRO da moldura, 0-15 (so usado em EditMode)
  CursorPY.i    ; cursor de pixel DENTRO da moldura, 0-15
EndStructure

; Indice (0-based) do bloco de 8 bytes que cobre o caractere de TELA
; (ScreenCol,ScreenRow) - decompoe a posicao em qual azulejo dx x dy ela cai
; (TileCol,TileRow), a posicao LOCAL dentro do azulejo, e aplica a ordem de
; varredura (modo) so dentro do azulejo. Azulejos varridos sempre em
; row-major pela tela (esquerda->direita, cima->baixo) - a tela em si nunca
; muda de tamanho, so o agrupamento interno muda com dx/dy/modo.
Procedure.i MamuteScr_BlockIndexForChar(*State.MamuteScrState, ScreenCol.i, ScreenRow.i)
  Protected TilesPerRow.i = #Mamute_ScrCols / *State\Dx
  If TilesPerRow < 1 : TilesPerRow = 1 : EndIf
  Protected TileCol.i = ScreenCol / *State\Dx
  Protected TileRow.i = ScreenRow / *State\Dy
  Protected LocalCol.i = ScreenCol % *State\Dx
  Protected LocalRow.i = ScreenRow % *State\Dy
  Protected TileIndex.i = TileRow * TilesPerRow + TileCol
  Protected WithinTile.i
  If *State\Modo = 1
    WithinTile = LocalCol * *State\Dy + LocalRow ; vertical/sprite
  Else
    WithinTile = LocalRow * *State\Dx + LocalCol ; horizontal
  EndIf
  ProcedureReturn TileIndex * (*State\Dx * *State\Dy) + WithinTile
EndProcedure

; Endereco de CPU (com wraparound 0-FFFF) do byte que contem a linha LocalY
; (0-7) do caractere de TELA (ScreenCol,ScreenRow).
Procedure.i MamuteScr_ByteAddrForChar(*State.MamuteScrState, ScreenCol.i, ScreenRow.i, LocalY.i)
  Protected Blk.i = MamuteScr_BlockIndexForChar(*State, ScreenCol, ScreenRow)
  ProcedureReturn (*State\BaseAddr + Blk * 8 + LocalY) & $FFFF
EndProcedure

; SPX/SPY sao coordenadas de PIXEL absolutas na tela fixa (0..255, 0..191) -
; usado tanto pra desenhar a tela inteira (navegacao) quanto pro painel de
; edicao (que so acessa SPX/SPY 0..15, a moldura). MSB do byte = pixel mais
; a esquerda, mesma convencao da Pattern Generator Table real do MSX.
Procedure.b MamuteScr_GetScreenPixel(*State.MamuteScrState, SPX.i, SPY.i)
  Protected LocalX.i = SPX % 8, LocalY.i = SPY % 8
  Protected Addr.i = MamuteScr_ByteAddrForChar(*State, SPX / 8, SPY / 8, LocalY)
  Protected RawByte.a = Mamute_ReadByte(Addr)
  ProcedureReturn (RawByte >> (7 - LocalX)) & 1
EndProcedure

Procedure MamuteScr_SetScreenPixel(*State.MamuteScrState, SPX.i, SPY.i, Value.b)
  Protected LocalX.i = SPX % 8, LocalY.i = SPY % 8
  Protected Addr.i = MamuteScr_ByteAddrForChar(*State, SPX / 8, SPY / 8, LocalY)
  Protected RawByte.a = Mamute_ReadByte(Addr)
  Protected Mask.a = 1 << (7 - LocalX)
  Protected NewByte.a
  If Value
    NewByte = RawByte | Mask
  Else
    NewByte = RawByte & ($FF ! Mask)
  EndIf
  Mamute_WriteByte(Addr, NewByte)
EndProcedure

; #True so quando os 4 caracteres da moldura (sempre em (0,0)-(1,1)) estao
; TODOS mapeados em RAM agora - checa so o primeiro byte de cada caractere
; (os 8 bytes de um mesmo caractere ficam na mesma pagina fisica, exceto num
; wraparound extremo em 0000/FFFF, caso extremo ignorado de proposito).
Procedure.b MamuteScr_MolduraIsRam(*State.MamuteScrState)
  Protected sc.i, sr.i, Addr.i
  For sr = 0 To #Mamute_MolduraChars - 1
    For sc = 0 To #Mamute_MolduraChars - 1
      Addr = MamuteScr_ByteAddrForChar(*State, sc, sr, 0)
      If Not Mamute_CanWriteAt(Addr)
        ProcedureReturn #False
      EndIf
    Next
  Next
  ProcedureReturn #True
EndProcedure

Procedure MamuteScr_DrawButton(Canvas, Label.s, Font)
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

; Desenha a tela FIXA inteira (256x192 pixels, ampliados PixelSize vezes) +
; contorno da moldura (FrameOn) sobre os 16x16 pixels fixos do canto
; superior esquerdo.
Procedure MamuteScr_RepaintNav(Canvas, *State.MamuteScrState, PixelSize.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf

  Protected ColBack  = Mamute_CurrentBackColor()
  Protected ColFront = Mamute_CurrentFrontColor()
  Protected ColFrame = RGB(60, 140, 230)

  Box(0, 0, GadgetWidth(Canvas), GadgetHeight(Canvas), ColBack)

  Protected spx.i, spy.i
  For spy = 0 To #Mamute_ScrRows * 8 - 1
    For spx = 0 To #Mamute_ScrCols * 8 - 1
      If MamuteScr_GetScreenPixel(*State, spx, spy)
        Box(spx * PixelSize, spy * PixelSize, PixelSize, PixelSize, ColFront)
      EndIf
    Next
  Next

  If *State\FrameOn
    Protected MW.i = #Mamute_MolduraChars * 8 * PixelSize
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(0, 0, MW, MW, ColFrame)
    Box(1, 1, MW - 2, MW - 2, ColFrame)
    DrawingMode(#PB_2DDrawing_Transparent)
  EndIf

  StopDrawing()
EndProcedure

; Painel de edicao - amplia SO os 16x16 pixels fixos da moldura, sempre com
; o conteudo REAL (RAM ou ROM) e o cursor - pedido explicito do usuario:
; "as vezes ampliamos pra ver algum detalhe da tela, nao pra editar
; propriamente dito". Se a moldura nao for RAM agora (ROM/BASIC/Vazio),
; ESPACO/I/L continuam respondendo ao toque, mas Mamute_WriteByte() (via
; Mamute_CanWriteAt()) recusa a escrita de verdade - o pixel simplesmente
; volta a mostrar o mesmo valor real no proximo repaint, "sem registrar a
; modificacao". O aviso "ROM - somente leitura" fica no rotulo de status
; abaixo das telas (MamuteScr_UpdateRomLabel), nao mais escondendo o
; conteudo real aqui.
Procedure MamuteScr_RepaintEdit(Canvas, *State.MamuteScrState, PixelSize.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf

  Protected ColBack   = Mamute_CurrentBackColor()
  Protected ColFront  = Mamute_CurrentFrontColor()
  Protected ColGrid   = RGB(20, 60, 30)
  Protected ColCursor = RGB(230, 60, 60)
  Protected W = #Mamute_MolduraChars * 8 * PixelSize

  Box(0, 0, GadgetWidth(Canvas), GadgetHeight(Canvas), ColBack)

  If *State\EditMode
    Protected px.i, py.i
    For py = 0 To #Mamute_MolduraChars * 8 - 1
      For px = 0 To #Mamute_MolduraChars * 8 - 1
        If MamuteScr_GetScreenPixel(*State, px, py)
          Box(px * PixelSize, py * PixelSize, PixelSize, PixelSize, ColFront)
        EndIf
      Next
    Next

    Protected i.i
    For i = 1 To #Mamute_MolduraChars * 8 - 1
      Line(i * PixelSize, 0, 1, W, ColGrid)
      Line(0, i * PixelSize, W, 1, ColGrid)
    Next

    DrawingMode(#PB_2DDrawing_Outlined)
    Box(*State\CursorPX * PixelSize, *State\CursorPY * PixelSize, PixelSize, PixelSize, ColCursor)
    DrawingMode(#PB_2DDrawing_Transparent)
  EndIf

  StopDrawing()
EndProcedure

Procedure MamuteScr_ClampCursor(*State.MamuteScrState)
  Protected MaxP.i = #Mamute_MolduraChars * 8 - 1
  If *State\CursorPX < 0 : *State\CursorPX = 0 : EndIf
  If *State\CursorPX > MaxP : *State\CursorPX = MaxP : EndIf
  If *State\CursorPY < 0 : *State\CursorPY = 0 : EndIf
  If *State\CursorPY > MaxP : *State\CursorPY = MaxP : EndIf
EndProcedure

Procedure MamuteScr_UpdateAddrLabel(G_AddrLabel, *State.MamuteScrState)
  If *State\AddrVisible
    SetGadgetText(G_AddrLabel, "Endereco: " + Mamute_Hex4(*State\BaseAddr))
  Else
    SetGadgetText(G_AddrLabel, "")
  EndIf
EndProcedure

Procedure MamuteScr_UpdateRomLabel(G_RomLabel, *State.MamuteScrState)
  If *State\EditMode And Not MamuteScr_MolduraIsRam(*State)
    SetGadgetText(G_RomLabel, "ROM - somente leitura (alteracoes nao sao gravadas)")
  Else
    SetGadgetText(G_RomLabel, "")
  EndIf
EndProcedure

Procedure MamuteScr_UpdateLegend(G_Legend, *State.MamuteScrState)
  If *State\EditMode
    SetGadgetText(G_Legend, "Setas: cursor  ESPACO: inverte ponto  I: inverte moldura  L: apaga moldura  ENTER: sai  ESC: cancela")
  Else
    SetGadgetText(G_Legend, "Setas: mover  TAB: moldura  ENTER: editar  E: endereco  ESC: sair")
  EndIf
EndProcedure

; StartAddr/Dx/Dy/Modo ja validados pelo chamador (MamuteGui_CmdScr).
Procedure MamuteScr_Open(ParentWindow, StartAddr.i, Dx.i, Dy.i, Modo.i)
  Protected State.MamuteScrState
  State\BaseAddr = StartAddr & $FFFF
  State\Dx = Dx
  State\Dy = Dy
  State\Modo = Modo
  State\FrameOn = #False
  State\AddrVisible = #False
  State\EditMode = #False
  State\CursorPX = 0
  State\CursorPY = 0

  Protected ScrStyle.i = 0
  If MamuteFontBold : ScrStyle = #PB_Font_Bold : EndIf
  Protected ScrFont = LoadFont(#PB_Any, MamuteFontName, MamuteFontSize, ScrStyle)
  If Not ScrFont
    ScrFont = LoadFont(#PB_Any, "Consolas", 14, #PB_Font_Bold)
  EndIf

  ; Tela fixa 256x192 - PixelSize 2 da uma janela de tamanho razoavel
  ; (512x384) mantendo a proporcao real do SCREEN 2 do MSX.
  Protected NavPixelSize.i = 2
  Protected NavW.i = #Mamute_ScrCols * 8 * NavPixelSize
  Protected NavH.i = #Mamute_ScrRows * 8 * NavPixelSize

  ; Painel de edicao (16x16 pixels fixos da moldura) ampliado pra ocupar a
  ; mesma altura do canvas de navegacao, lado a lado.
  Protected EditPixelSize.i = NavH / (#Mamute_MolduraChars * 8)
  Protected EditW.i = #Mamute_MolduraChars * 8 * EditPixelSize
  Protected EditH.i = EditW

  Protected Margin = 16, Gap = 20
  Protected BtnH = 40, BtnGap = 8

  Protected RowW = (BtnH + BtnGap) * 4 + BtnGap * 2 + 56 + BtnGap + 56 + BtnGap * 2 + 56 + BtnGap + 56
  Protected CanvasRowW = NavW + Gap + EditW

  Protected WinW = CanvasRowW + Margin * 2
  If RowW + Margin * 2 > WinW
    WinW = RowW + Margin * 2
  EndIf

  Protected CanvasRowH = NavH
  If EditH > CanvasRowH : CanvasRowH = EditH : EndIf

  Protected LegendH = 20, StatusH = 24
  Protected WinH = Margin + LegendH + 8 + CanvasRowH + 12 + StatusH + StatusH + 12 + BtnH + Margin

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Mamute Assembler - SCR",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #True, #False)
  If Not Win
    ProcedureReturn
  EndIf
  SetWindowColor(Win, Mamute_CurrentBorderColor())

  Protected ColFront = Mamute_CurrentFrontColor(), ColBack = Mamute_CurrentBackColor()
  Protected CurY = Margin

  Protected G_Legend = TextGadget(#PB_Any, Margin, CurY, WinW - Margin * 2, LegendH, "")
  SetGadgetColor(G_Legend, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Legend, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Legend, FontID(ScrFont))
  CurY + LegendH + 8

  Protected G_Grid = CanvasGadget(#PB_Any, Margin, CurY, NavW, NavH, #PB_Canvas_Keyboard)
  Protected G_EditPanel = CanvasGadget(#PB_Any, Margin + NavW + Gap, CurY, EditW, EditH)
  CurY + CanvasRowH + 12

  Protected G_AddrLabel = TextGadget(#PB_Any, Margin, CurY, WinW - Margin * 2, StatusH, "")
  SetGadgetColor(G_AddrLabel, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_AddrLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_AddrLabel, FontID(ScrFont))
  CurY + StatusH

  ; So aparece em modo de edicao, quando a moldura cai em ROM/BASIC/Vazio -
  ; o painel de edicao (MamuteScr_RepaintEdit) mostra o conteudo real e
  ; aceita cliques normalmente ("as vezes ampliamos pra ver algum detalhe da
  ; tela, nao pra editar"), mas Mamute_WriteByte() ja recusa a escrita de
  ; verdade pra celulas nao-RAM - este rotulo so avisa que isso esta
  ; acontecendo, nao bloqueia nada.
  Protected G_RomLabel = TextGadget(#PB_Any, Margin, CurY, WinW - Margin * 2, StatusH, "")
  SetGadgetColor(G_RomLabel, #PB_Gadget_FrontColor, RGB(230, 200, 40))
  SetGadgetColor(G_RomLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_RomLabel, FontID(ScrFont))
  CurY + StatusH + 12

  Protected BtnFont = LoadFont(#PB_Any, "Consolas", 14, #PB_Font_Bold)
  If Not BtnFont : BtnFont = ScrFont : EndIf

  Protected BtnY = CurY
  Protected CurX = Margin
  Protected G_ArrowLeft = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH)  : CurX + BtnH + BtnGap
  Protected G_ArrowUp = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH)    : CurX + BtnH + BtnGap
  Protected G_ArrowDown = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH)  : CurX + BtnH + BtnGap
  Protected G_ArrowRight = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH) : CurX + BtnH + BtnGap * 3
  Protected G_FrameBtn = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH)     : CurX + 56 + BtnGap
  Protected G_AddrBtn = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH)      : CurX + 56 + BtnGap * 3
  Protected G_InvertBtn = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH)    : CurX + 56 + BtnGap
  Protected G_EraseBtn = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH)

  MamuteScr_DrawButton(G_ArrowLeft, "<", BtnFont)
  MamuteScr_DrawButton(G_ArrowUp, "^", BtnFont)
  MamuteScr_DrawButton(G_ArrowDown, "v", BtnFont)
  MamuteScr_DrawButton(G_ArrowRight, ">", BtnFont)
  MamuteScr_DrawButton(G_FrameBtn, "MOL", BtnFont)
  MamuteScr_DrawButton(G_AddrBtn, "END", BtnFont)
  MamuteScr_DrawButton(G_InvertBtn, "INV", BtnFont)
  MamuteScr_DrawButton(G_EraseBtn, "APG", BtnFont)
  GadgetToolTip(G_ArrowLeft, "-1 byte")
  GadgetToolTip(G_ArrowRight, "+1 byte")
  GadgetToolTip(G_ArrowUp, "-1 bloco")
  GadgetToolTip(G_ArrowDown, "+1 bloco")
  GadgetToolTip(G_FrameBtn, "Moldura (TAB)")
  GadgetToolTip(G_AddrBtn, "Mostrar endereco (E)")
  GadgetToolTip(G_InvertBtn, "Inverte a moldura (I) - so em edicao")
  GadgetToolTip(G_EraseBtn, "Apaga a moldura (L) - so em edicao")

  MamuteScr_UpdateLegend(G_Legend, @State)
  MamuteScr_UpdateAddrLabel(G_AddrLabel, @State)
  MamuteScr_UpdateRomLabel(G_RomLabel, @State)
  MamuteScr_RepaintNav(G_Grid, @State, NavPixelSize)
  MamuteScr_RepaintEdit(G_EditPanel, @State, EditPixelSize)
  SetActiveGadget(G_Grid)

  AddKeyboardShortcut(Win, #PB_Shortcut_Up, #MamuteScr_Shortcut_Up)
  AddKeyboardShortcut(Win, #PB_Shortcut_Down, #MamuteScr_Shortcut_Down)
  AddKeyboardShortcut(Win, #PB_Shortcut_Left, #MamuteScr_Shortcut_Left)
  AddKeyboardShortcut(Win, #PB_Shortcut_Right, #MamuteScr_Shortcut_Right)
  AddKeyboardShortcut(Win, #PB_Shortcut_Tab, #MamuteScr_Shortcut_Tab)
  AddKeyboardShortcut(Win, #PB_Shortcut_Return, #MamuteScr_Shortcut_Return)
  AddKeyboardShortcut(Win, #PB_Shortcut_Escape, #MamuteScr_Shortcut_Escape)
  AddKeyboardShortcut(Win, #PB_Shortcut_E, #MamuteScr_Shortcut_Address)
  AddKeyboardShortcut(Win, #PB_Shortcut_Space, #MamuteScr_Shortcut_Space)
  AddKeyboardShortcut(Win, #PB_Shortcut_I, #MamuteScr_Shortcut_Invert)
  AddKeyboardShortcut(Win, #PB_Shortcut_L, #MamuteScr_Shortcut_Erase)

  ; Macros (nao Procedures) de proposito - acessam direto as locais desta
  ; janela (State, gadgets, tamanhos), mesmo idioma de MamuteDumpGui.pbi/
  ; MamuteZapGui.pbi. Nomes de parametro NUNCA "Dx"/"Dy" (nem variantes de
  ; caixa) - colide com os campos State\Dx/State\Dy (PureBasic e
  ; case-insensitive), achado real da sessao anterior visto no Macro.out do
  ; compilador.

  Macro MamuteScr_DoRepaint
    MamuteScr_UpdateAddrLabel(G_AddrLabel, @State)
    MamuteScr_UpdateRomLabel(G_RomLabel, @State)
    MamuteScr_RepaintNav(G_Grid, @State, NavPixelSize)
    MamuteScr_RepaintEdit(G_EditPanel, @State, EditPixelSize)
  EndMacro

  ; MoveX/MoveY sao "direcao" (-1/0/+1), nao pixels crus - fora de edicao,
  ; MoveX move BaseAddr +-1 byte e MoveY move BaseAddr +-1 azulejo inteiro
  ; (Dx*Dy*8 bytes); em edicao, os dois movem o cursor de pixel dentro da
  ; moldura fixa (0-15,0-15).
  Macro MamuteScr_DoMove(MoveX, MoveY)
    If State\EditMode
      State\CursorPX + (MoveX)
      State\CursorPY + (MoveY)
      MamuteScr_ClampCursor(@State)
    Else
      If (MoveX) <> 0
        State\BaseAddr = (State\BaseAddr + (MoveX)) & $FFFF
      EndIf
      If (MoveY) <> 0
        State\BaseAddr = (State\BaseAddr + (MoveY) * State\Dx * State\Dy * 8) & $FFFF
      EndIf
    EndIf
    MamuteScr_DoRepaint
  EndMacro

  ; Snapshot dos #Mamute_MolduraChars^2 caracteres (8 bytes cada) da moldura,
  ; endereco resolvido igual MamuteScr_ByteAddrForChar - NAO assume que sao
  ; contiguos em memoria (nao sao, em geral, dado o ladrilhamento por dx/dy).
  Protected Dim ScrSnapshot.a(#Mamute_MolduraChars * #Mamute_MolduraChars * 8 - 1)

  Macro MamuteScr_DoEnterEdit
    Protected SnapSc.i, SnapSr.i, SnapY.i, SnapIdx.i = 0
    For SnapSr = 0 To #Mamute_MolduraChars - 1
      For SnapSc = 0 To #Mamute_MolduraChars - 1
        For SnapY = 0 To 7
          ScrSnapshot(SnapIdx) = Mamute_ReadByte(MamuteScr_ByteAddrForChar(@State, SnapSc, SnapSr, SnapY))
          SnapIdx + 1
        Next
      Next
    Next
    State\EditMode = #True
    State\CursorPX = 0
    State\CursorPY = 0
    MamuteScr_UpdateLegend(G_Legend, @State)
    MamuteScr_DoRepaint
  EndMacro

  Macro MamuteScr_DoExitEdit
    State\EditMode = #False
    MamuteScr_UpdateLegend(G_Legend, @State)
    MamuteScr_DoRepaint
  EndMacro

  Macro MamuteScr_DoCancelEdit
    Protected CancelSc.i, CancelSr.i, CancelY.i, CancelIdx.i = 0
    For CancelSr = 0 To #Mamute_MolduraChars - 1
      For CancelSc = 0 To #Mamute_MolduraChars - 1
        For CancelY = 0 To 7
          Mamute_WriteByte(MamuteScr_ByteAddrForChar(@State, CancelSc, CancelSr, CancelY), ScrSnapshot(CancelIdx))
          CancelIdx + 1
        Next
      Next
    Next
    MamuteScr_DoExitEdit
  EndMacro

  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_ArrowLeft  : If EventType() = #PB_EventType_LeftButtonDown : MamuteScr_DoMove(-1, 0) : EndIf
          Case G_ArrowRight : If EventType() = #PB_EventType_LeftButtonDown : MamuteScr_DoMove(1, 0) : EndIf
          Case G_ArrowUp    : If EventType() = #PB_EventType_LeftButtonDown : MamuteScr_DoMove(0, -1) : EndIf
          Case G_ArrowDown  : If EventType() = #PB_EventType_LeftButtonDown : MamuteScr_DoMove(0, 1) : EndIf

          Case G_FrameBtn
            If EventType() = #PB_EventType_LeftButtonDown And Not State\EditMode
              State\FrameOn = Bool(Not State\FrameOn)
              MamuteScr_DoRepaint
            EndIf

          Case G_AddrBtn
            If EventType() = #PB_EventType_LeftButtonDown
              State\AddrVisible = Bool(Not State\AddrVisible)
              MamuteScr_DoRepaint
            EndIf

          Case G_InvertBtn
            If EventType() = #PB_EventType_LeftButtonDown And State\EditMode
              Protected InvBX.i, InvBY.i
              For InvBY = 0 To #Mamute_MolduraChars * 8 - 1
                For InvBX = 0 To #Mamute_MolduraChars * 8 - 1
                  MamuteScr_SetScreenPixel(@State, InvBX, InvBY, 1 - MamuteScr_GetScreenPixel(@State, InvBX, InvBY))
                Next
              Next
              MamuteScr_DoRepaint
            EndIf

          Case G_EraseBtn
            If EventType() = #PB_EventType_LeftButtonDown And State\EditMode
              Protected EraBX.i, EraBY.i
              For EraBY = 0 To #Mamute_MolduraChars * 8 - 1
                For EraBX = 0 To #Mamute_MolduraChars * 8 - 1
                  MamuteScr_SetScreenPixel(@State, EraBX, EraBY, 0)
                Next
              Next
              MamuteScr_DoRepaint
            EndIf
        EndSelect

      Case #PB_Event_Menu
        Select EventMenu()
          Case #MamuteScr_Shortcut_Up    : MamuteScr_DoMove(0, -1)
          Case #MamuteScr_Shortcut_Down  : MamuteScr_DoMove(0, 1)
          Case #MamuteScr_Shortcut_Left  : MamuteScr_DoMove(-1, 0)
          Case #MamuteScr_Shortcut_Right : MamuteScr_DoMove(1, 0)

          Case #MamuteScr_Shortcut_Tab
            If Not State\EditMode
              State\FrameOn = Bool(Not State\FrameOn)
              MamuteScr_DoRepaint
            EndIf

          Case #MamuteScr_Shortcut_Address
            State\AddrVisible = Bool(Not State\AddrVisible)
            MamuteScr_DoRepaint

          Case #MamuteScr_Shortcut_Return
            If State\EditMode
              MamuteScr_DoExitEdit
            Else
              MamuteScr_DoEnterEdit
            EndIf

          Case #MamuteScr_Shortcut_Escape
            If State\EditMode
              MamuteScr_DoCancelEdit
            Else
              Quit = #True
            EndIf

          Case #MamuteScr_Shortcut_Space
            If State\EditMode
              MamuteScr_SetScreenPixel(@State, State\CursorPX, State\CursorPY, 1 - MamuteScr_GetScreenPixel(@State, State\CursorPX, State\CursorPY))
              MamuteScr_DoRepaint
            EndIf

          Case #MamuteScr_Shortcut_Invert
            If State\EditMode
              Protected KeyInvBX.i, KeyInvBY.i
              For KeyInvBY = 0 To #Mamute_MolduraChars * 8 - 1
                For KeyInvBX = 0 To #Mamute_MolduraChars * 8 - 1
                  MamuteScr_SetScreenPixel(@State, KeyInvBX, KeyInvBY, 1 - MamuteScr_GetScreenPixel(@State, KeyInvBX, KeyInvBY))
                Next
              Next
              MamuteScr_DoRepaint
            EndIf

          Case #MamuteScr_Shortcut_Erase
            If State\EditMode
              Protected KeyEraBX.i, KeyEraBY.i
              For KeyEraBY = 0 To #Mamute_MolduraChars * 8 - 1
                For KeyEraBX = 0 To #Mamute_MolduraChars * 8 - 1
                  MamuteScr_SetScreenPixel(@State, KeyEraBX, KeyEraBY, 0)
                Next
              Next
              MamuteScr_DoRepaint
            EndIf
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
