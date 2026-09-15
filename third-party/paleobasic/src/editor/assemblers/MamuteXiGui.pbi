;
; ------------------------------------------------------------
;  Comando XI do Mamute Assembler - porta do comando I do monitor SUPER-X
;  (docs/SPEC.md modulo 45/45i, others/superx/SUPER-X.DOC.pdf, secao
;  "Disassembly editing"). Batizado XI (nao I) pelo mesmo motivo do XD/XA/
;  XM - decisao explicita do usuario, pedido nesta mesma sessao: "vai ser
;  XI que lista o disassembly do endereco inicial, ate o final (opcional)
;  ou salva com nome (opcional) igual aos outros comandos acima".
;
;  Ao contrario do "I" original do SUPER-X (disassembly EDITAVEL, com pilha
;  de jump/call navegavel via </>), o XI aqui e' SO' VISUALIZACAO - decisao
;  explicita do usuario via pergunta direta antes de codar ("Janela
;  interativa nova (visualizacao)", sem pilha de jump/call, que fica pra
;  uma sessao futura). Reusa o MESMO motor de disassembly do L/LP (modulo
;  31, Mamute_DisasmOne()/Mamute_DisasmBuildLines(), MamuteSupport.pbi) -
;  nao decodifica nada sozinho.
;
;  Enderecamento estendido (docs/SPEC.md modulo 45i) - Mamute_DisasmOne()/
;  Mamute_DisasmBuildLines() ganharam um parametro NOVO opcional
;  "*T.MamuteSxTarget = 0" nesta mesma sessao (junto com um Mamute_DisasmRb()
;  auxiliar) - quando omitido (0, o padrao), o comportamento e' IDENTICO a
;  antes desta mudanca (cai pro Mamute_ReadByte()+"&$FFFF" classico), entao
;  os consumidores PRE-EXISTENTES (L/LP, o disassembler ao vivo do debugger
;  em MamuteDebuggerGui.pbi, o log de step em MamuteZ80Cpu.pbi) continuam
;  100% inalterados sem precisar tocar em nenhum deles - so' o XI passa um
;  alvo de verdade, pra honrar #slot[-subslot]/#V/#S igual ao XD/XA/XM.
;
;  Sem grade/cursor - so' um EditorGadget somente-leitura (mesmo widget/
;  paleta verde-sobre-preto do proprio log MON>, MamuteAssembler_OpenWindow())
;  mostrando um "bloco" de instrucoes a partir de BaseAddr. Paginacao:
;  - Seta baixo/cima: "nudge" de +-1 byte no BaseAddr - reencontrar o
;    alinhamento certo de instrucao manualmente e' uma tecnica real de
;    visualizador de disassembly (pular pro meio dos bytes de uma instrucao
;    anterior desalinha a decodificacao seguinte ate ressincronizar sozinha -
;    comportamento inerente de qualquer disassembler em fluxo, nao e' bug).
;  - PgDn: EXATO - usa o proprio NextAddr que a ultima passada de
;    Mamute_DisasmBuildLines() ja devolveu (o fim de verdade do bloco
;    mostrado agora), sem heuristica nenhuma.
;  - PgUp: heuristica - volta pela MESMA largura em bytes que o bloco atual
;    ocupou (NextAddr-BaseAddr), ja que nao da' pra decodificar Z80 "pra
;    tras" de forma confiavel (limite conhecido/aceito de qualquer
;    disassembler em fluxo, nao so' deste).
;
;  Cruz de modos (modulo 45f/45h) - aqui **Disasm** e' o modo ativo; **Dump**/
;  **Ascii**/**Multi**/**Char** ligam de verdade pro XD/XA/XM/XH - os quatro
;  modos da cruz ja existem, nenhum placeholder restante (Char foi o
;  ultimo, virou o comando XH - editor de caracteres/sprites,
;  MamuteXhGui.pbi).
; ------------------------------------------------------------
;

#MamuteXi_Shortcut_Up       = 9760
#MamuteXi_Shortcut_Down     = 9761
#MamuteXi_Shortcut_PageUp   = 9762
#MamuteXi_Shortcut_PageDown = 9763
#MamuteXi_Shortcut_Return   = 9764
#MamuteXi_Shortcut_Escape   = 9765

#MamuteXi_VisibleLines = 30 ; quantas instrucoes tenta mostrar de cada vez (Mamute_DisasmBuildLines "sem fim" e' limitado a 10/chamada, chamado em lote)

Structure MamuteXiState
  BaseAddr.i             ; endereco da PRIMEIRA instrucao mostrada agora
  NextAddr.i             ; endereco logo apos a ULTIMA instrucao mostrada agora (PgDn usa isso direto)
  Target.MamuteSxTarget  ; alvo resolvido (PAGE corrente/slot explicito/sub-slot/VRAM)
EndStructure

; Decodifica ate #MamuteXi_VisibleLines instrucoes a partir de BaseAddr,
; encadeando varias chamadas de Mamute_DisasmBuildLines() (cada uma decodifica
; ate 10 instrucoes no modo "sem fim") - preenche Lines() e State\NextAddr.
; Para cedo se o alvo estourar o teto (Mamute_SxMaxAddr) no meio do lote.
Procedure MamuteXi_Fill(List Lines.s(), *State.MamuteXiState)
  ClearList(Lines())
  Protected CurAddr.i = *State\BaseAddr
  Protected MaxAddr.i = Mamute_SxMaxAddr(@*State\Target)
  Protected NewList Batch.s()
  Protected NextA.i = CurAddr

  While ListSize(Lines()) < #MamuteXi_VisibleLines And CurAddr <= MaxAddr
    Mamute_DisasmBuildLines(Batch(), CurAddr, #False, 0, @NextA, @*State\Target)
    If ListSize(Batch()) = 0 : Break : EndIf
    ForEach Batch()
      AddElement(Lines())
      Lines() = Batch()
    Next
    If NextA = CurAddr : Break : EndIf ; guarda defensiva - nunca deveria acontecer, evita loop infinito
    CurAddr = NextA
  Wend

  *State\NextAddr = NextA
EndProcedure

Procedure MamuteXi_Repaint(G_View, G_AddrLabel, *State.MamuteXiState)
  Protected NewList Lines.s()
  MamuteXi_Fill(Lines(), *State)

  Protected Text.s = ""
  ForEach Lines()
    If Text <> "" : Text + Chr(13) + Chr(10) : EndIf
    Text + Lines()
  Next
  SetGadgetText(G_View, Text)

  Protected AddrDigits.i = 4
  If *State\Target\IsVram : AddrDigits = 5 : EndIf
  SetGadgetText(G_AddrLabel, "Endereco: " + Mamute_HexPad(*State\BaseAddr, AddrDigits) + Mamute_SxTargetSuffixText(@*State\Target))
EndProcedure

; Devolve o BaseAddr final (endereco onde a janela ficou ao fechar) - quem
; chama guarda isso pra "sem argumento, continua daqui" (mesmo idioma do
; XD/XA/XM). *StartTarget - alvo ja resolvido (Mamute_ParseSxAddr,
; MamuteAssemblerGui.pbi).
Procedure.i MamuteXi_Open(ParentWindow, StartAddr.i, *StartTarget.MamuteSxTarget)
  Protected State.MamuteXiState
  CopyStructure(*StartTarget, @State\Target, MamuteSxTarget)
  State\BaseAddr = Mamute_SxWrapAddr(StartAddr, @State\Target)
  State\NextAddr = State\BaseAddr

  Protected Title.s = "Mamute Assembler - XI (SUPER-X)"
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

  Protected ColFront = Mamute_CurrentFrontColor(), ColBack = Mamute_CurrentBackColor(), ColBorder = Mamute_CurrentBorderColor()

  Protected Margin = 16
  Protected ViewW = 620, ViewH = 560
  Protected ModeBtnW = 76, ModeBtnH = 34, ModeBtnGap = 6
  Protected ModeGapX = 24
  Protected ModeCrossW = ModeBtnW * 3 + ModeBtnGap * 2
  Protected ModeCrossH = ModeBtnH * 3 + ModeBtnGap * 2
  Protected ModeCrossX = Margin + ViewW + ModeGapX
  Protected ModeCrossCol0 = ModeCrossX
  Protected ModeCrossCol1 = ModeCrossX + ModeBtnW + ModeBtnGap
  Protected ModeCrossCol2 = ModeCrossX + (ModeBtnW + ModeBtnGap) * 2

  Protected WinW = ViewW + ModeGapX + ModeCrossW + Margin * 2
  Protected BtnH = 40, BtnGap = 8
  Protected RowW = 56 + BtnGap + BtnH + BtnGap + BtnH + BtnGap + 56 + Margin * 2
  If RowW > WinW : WinW = RowW : EndIf

  Protected LegendH = 20, StatusH = 24
  Protected WinH = Margin + LegendH + 8 + ViewH + 12 + StatusH + 12 + BtnH + Margin

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, Title,
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #True, #False)
  If Not Win
    ProcedureReturn StartAddr
  EndIf
  SetWindowColor(Win, ColBorder)

  Protected CurY = Margin

  Protected LegendTxt.s = "Setas: +-1 byte (ressincroniza)  PgUp/PgDn: bloco  RETURN/ESC: sai"
  Protected G_Legend = TextGadget(#PB_Any, Margin, CurY, WinW - Margin * 2, LegendH, LegendTxt)
  SetGadgetColor(G_Legend, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Legend, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Legend, FontID(MFont))
  CurY + LegendH + 8

  Protected ViewY = CurY
  Protected G_View = EditorGadget(#PB_Any, Margin, ViewY, ViewW, ViewH, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
  SetGadgetColor(G_View, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_View, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_View, FontID(MFont))
  CurY + ViewH + 12

  Protected ModeCrossY = ViewY + (ViewH - ModeCrossH) / 2
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
  MamuteXd_DrawModeButton(G_ModeChar, "Char", BtnFont, 0)    ; ja liga com XH de verdade
  MamuteXd_DrawModeButton(G_ModeMulti, "Multi", BtnFont, 0)  ; ja liga com XM de verdade
  MamuteXd_DrawModeButton(G_ModeDisasm, "Disasm", BtnFont, 1) ; ja e' o modo ativo agora
  GadgetToolTip(G_ModeDump, "Modo Dump - abre o XD neste mesmo endereco/alvo")
  GadgetToolTip(G_ModeAscii, "Modo Ascii - abre o XA neste mesmo endereco/alvo")
  GadgetToolTip(G_ModeChar, "Modo Char - abre o XH neste mesmo endereco/alvo")
  GadgetToolTip(G_ModeMulti, "Modo Multi - abre o XM neste mesmo endereco/alvo")
  GadgetToolTip(G_ModeDisasm, "Modo Disasm (esta tela) - ja ativo")

  Protected G_AddrLabel = TextGadget(#PB_Any, Margin, CurY, 320, StatusH, "")
  SetGadgetColor(G_AddrLabel, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_AddrLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_AddrLabel, FontID(MFont))
  CurY + StatusH + 12

  Protected BtnY = CurY
  Protected CurX = Margin
  Protected G_PageUp = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH)   : CurX + 56 + BtnGap
  Protected G_ArrowUp = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH)    : CurX + BtnH + BtnGap
  Protected G_ArrowDown = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH)  : CurX + BtnH + BtnGap
  Protected G_PageDown = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH)

  MamuteXd_DrawButton(G_PageUp, "<<", BtnFont)
  MamuteXd_DrawButton(G_ArrowUp, "^", BtnFont)
  MamuteXd_DrawButton(G_ArrowDown, "v", BtnFont)
  MamuteXd_DrawButton(G_PageDown, ">>", BtnFont)
  GadgetToolTip(G_PageUp, "Bloco anterior (heuristica)")
  GadgetToolTip(G_PageDown, "Proximo bloco (exato)")

  MamuteXi_Repaint(G_View, G_AddrLabel, @State)

  AddKeyboardShortcut(Win, #PB_Shortcut_Up, #MamuteXi_Shortcut_Up)
  AddKeyboardShortcut(Win, #PB_Shortcut_Down, #MamuteXi_Shortcut_Down)
  AddKeyboardShortcut(Win, #PB_Shortcut_PageUp, #MamuteXi_Shortcut_PageUp)
  AddKeyboardShortcut(Win, #PB_Shortcut_PageDown, #MamuteXi_Shortcut_PageDown)
  AddKeyboardShortcut(Win, #PB_Shortcut_Return, #MamuteXi_Shortcut_Return)
  AddKeyboardShortcut(Win, #PB_Shortcut_Escape, #MamuteXi_Shortcut_Escape)

  Macro MamuteXi_DoNudge(Delta)
    State\BaseAddr = Mamute_SxWrapAddr(State\BaseAddr + (Delta), @State\Target)
    MamuteXi_Repaint(G_View, G_AddrLabel, @State)
  EndMacro

  Macro MamuteXi_DoPageDown
    State\BaseAddr = State\NextAddr
    MamuteXi_Repaint(G_View, G_AddrLabel, @State)
  EndMacro

  Protected PageUpSpan.i
  Macro MamuteXi_DoPageUp
    PageUpSpan = State\NextAddr - State\BaseAddr
    If PageUpSpan < 1 : PageUpSpan = #MamuteXi_VisibleLines : EndIf ; guarda defensiva (bloco vazio no topo do alvo)
    State\BaseAddr = Mamute_SxWrapAddr(State\BaseAddr - PageUpSpan, @State\Target)
    MamuteXi_Repaint(G_View, G_AddrLabel, @State)
  EndMacro

  Protected Event, Quit = #False
  Protected AlreadyClosed.b = #False ; #True quando um botao da cruz ja fechou a janela na hora
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_ArrowUp    : If EventType() = #PB_EventType_LeftButtonDown : MamuteXi_DoNudge(-1) : EndIf
          Case G_ArrowDown  : If EventType() = #PB_EventType_LeftButtonDown : MamuteXi_DoNudge(1) : EndIf
          Case G_PageUp     : If EventType() = #PB_EventType_LeftButtonDown : MamuteXi_DoPageUp : EndIf
          Case G_PageDown   : If EventType() = #PB_EventType_LeftButtonDown : MamuteXi_DoPageDown : EndIf

          ; Cruz de modos (ver comentario no topo do arquivo) - Disasm ja e'
          ; o modo ativo (clique nao faz nada); Dump/Ascii/Multi/Char trocam
          ; de verdade pro XD/XA/XM/XH, no MESMO endereco/alvo.
          Case G_ModeDisasm
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

          Case G_ModeChar
            If EventType() = #PB_EventType_LeftButtonDown
              CloseModelessChildWindow(ParentWindow, Win)
              AlreadyClosed = #True
              State\BaseAddr = MamuteXh_Open(ParentWindow, State\BaseAddr, @State\Target)
              Quit = #True
            EndIf
        EndSelect

      Case #PB_Event_Menu
        Select EventMenu()
          Case #MamuteXi_Shortcut_Up     : MamuteXi_DoNudge(-1)
          Case #MamuteXi_Shortcut_Down   : MamuteXi_DoNudge(1)
          Case #MamuteXi_Shortcut_PageUp   : MamuteXi_DoPageUp
          Case #MamuteXi_Shortcut_PageDown : MamuteXi_DoPageDown
          Case #MamuteXi_Shortcut_Return : Quit = #True
          Case #MamuteXi_Shortcut_Escape : Quit = #True
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
