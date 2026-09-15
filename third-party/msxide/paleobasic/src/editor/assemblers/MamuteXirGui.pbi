;
; ------------------------------------------------------------
;  Comando XIR do Mamute Assembler - visualizador das notas do SUPER-X
;  carregadas em memoria (MamuteNotes(), MamuteNotesData.pbi - comandos
;  XIM/XIC/XIL/XIS, docs/SPEC.md modulo 45x). Pedido explicito do usuario:
;  "faca um comando XIR que abre uma janela e mostra o conteudo das notas,
;  uma por uma, permite rolar com botoes, e permite busca com case, sem
;  case e expressao regular" (modulo 45z).
;
;  Mesmo espirito do XTP (MamuteXtpGui.pbi) - visualizador SIMPLES e
;  AUTOCONTIDO, sem nada a ver com memoria/endereco/PAGE simulados,
;  reaproveitando a MESMA tecnica de campo de busca (StringGadget + 2
;  CheckBoxGadget nativos Case/Regex + botao "Buscar",
;  CreateRegularExpression()/ExamineRegularExpression()/
;  NextRegularExpressionMatch() da API nativa do PureBasic) - so' que a
;  unidade navegada e' UMA NOTA inteira (endereco+slot+tipo+texto) por
;  vez, nao uma linha de texto crua, entao nao precisa da logica de
;  TopLine/LeftCol/corte-de-coluna do XTP (o texto de uma nota sempre cabe
;  numa tela com WordWrap ligado).
;
;  4 botoes de navegacao ("|<"/"<"/">"/">|" - inicio/anterior/proxima/fim,
;  mesmos glifos do XTP) cobrem o "rolar com botoes" pedido; PageUp/PageDown
;  pulam 10 notas de uma vez (mesmo espirito do "pagina" do XTP, bonus
;  barato de implementar reaproveitando o padrao ja existente).
;
;  Busca (MamuteXir_DoSearch abaixo) roda contra uma string "haystack" por
;  nota = "ENDERECO SLOT TIPO TEXTO" (ex.: "00B4 GERAL BIOS Exibe..."),
;  nao so' o texto - permite buscar por endereco hexa OU por categoria
;  (ex. buscar "PORT" pula so' entre as notas de porta) alem do texto
;  livre. Sempre a partir da PROXIMA nota (nunca a atual), com wraparound
;  completo pela lista inteira - unidade de busca e' "a nota", nao uma
;  posicao de coluna dentro dela (diferente do XTP, onde uma linha pode
;  ter varios matches).
; ------------------------------------------------------------
;

#MamuteXir_Shortcut_Prev     = 9840
#MamuteXir_Shortcut_Next     = 9841
#MamuteXir_Shortcut_PageUp   = 9842
#MamuteXir_Shortcut_PageDown = 9843
#MamuteXir_Shortcut_Home     = 9844
#MamuteXir_Shortcut_End      = 9845
#MamuteXir_Shortcut_Return   = 9846
#MamuteXir_Shortcut_Escape   = 9847

#MamuteXir_PageStep = 10 ; quantas notas cada PgUp/PgDn pula de uma vez

Structure MamuteXirState
  CurrentIndex.i
  NoteCount.i
EndStructure

; Monta a string usada pela busca (MamuteXir_DoSearch) pra nota no indice
; Idx de MamuteNotes() - "" se Idx for invalido. SelectElement() move o
; cursor do NewList global MamuteNotes() pra ali (mesma tecnica usada por
; MamuteXir_Repaint logo abaixo) - seguro porque nenhum outro comando do
; Mamute depende da posicao "atual" de MamuteNotes() sobreviver entre
; chamadas (XIC/XIM/XIL/XIS sempre usam ForEach, que reposiciona sozinho).
Procedure.s MamuteXir_Searchable(Idx.i)
  If Not SelectElement(MamuteNotes(), Idx)
    ProcedureReturn ""
  EndIf
  ProcedureReturn Mamute_Hex4(MamuteNotes()\Addr) + " " + Mamute_NoteSlotName(MamuteNotes()\SlotData) + " " +
                  Mamute_NoteTypeName(MamuteNotes()\TypeData) + " " + MamuteNotes()\Text
EndProcedure

; Redesenha a nota em CurrentIndex (ja' clampada em 0..NoteCount-1) no
; G_View, e a posicao ("NOTA N/TOTAL") no G_Status - mesmo idioma dual-uso
; do G_Status do XTP (posicao normalmente, mensagem de busca quando
; MamuteXir_DoSearch precisa avisar algo).
Procedure MamuteXir_Repaint(G_View, G_Status, *State.MamuteXirState)
  If *State\NoteCount = 0
    SetGadgetText(G_View, "")
    SetGadgetText(G_Status, "NENHUMA NOTA CARREGADA - USE XIL PRA CARREGAR")
    ProcedureReturn
  EndIf

  If *State\CurrentIndex < 0 : *State\CurrentIndex = 0 : EndIf
  If *State\CurrentIndex > *State\NoteCount - 1 : *State\CurrentIndex = *State\NoteCount - 1 : EndIf

  SelectElement(MamuteNotes(), *State\CurrentIndex)
  Protected Text.s = "ENDERECO: " + Mamute_Hex4(MamuteNotes()\Addr) + #CRLF$ +
                      "SLOT: " + Mamute_NoteSlotName(MamuteNotes()\SlotData) + #CRLF$ +
                      "TIPO: " + Mamute_NoteTypeName(MamuteNotes()\TypeData) + #CRLF$ + #CRLF$ +
                      MamuteNotes()\Text
  SetGadgetText(G_View, Text)
  SetGadgetText(G_Status, "NOTA " + Str(*State\CurrentIndex + 1) + "/" + Str(*State\NoteCount))
EndProcedure

; Busca SearchText SEMPRE a partir da PROXIMA nota (nunca a atual), com
; wraparound completo pela lista - CaseSensitive/UseRegex, pedido explicito
; do usuario ("busca com case, sem case e expressao regular"), mesma
; tecnica/API do MamuteXtp_DoSearch (MamuteXtpGui.pbi). #True + tela
; repintada na nota encontrada; #False + status "NAO ENCONTRADO"/
; "?EXPRESSAO REGULAR INVALIDA" sem mexer em CurrentIndex.
Procedure.b MamuteXir_DoSearch(G_View, G_Status, *State.MamuteXirState, SearchText.s, CaseSensitive.b, UseRegex.b)
  If SearchText = "" Or *State\NoteCount = 0
    ProcedureReturn #False
  EndIf

  Protected RegexId.i = 0
  If UseRegex
    Protected RxFlags.i = 0
    If Not CaseSensitive : RxFlags = #PB_RegularExpression_NoCase : EndIf
    RegexId = CreateRegularExpression(#PB_Any, SearchText, RxFlags)
    If Not RegexId
      SetGadgetText(G_Status, "?EXPRESSAO REGULAR INVALIDA")
      ProcedureReturn #False
    EndIf
  EndIf

  Protected StrMode.i = #PB_String_CaseSensitive
  If Not CaseSensitive : StrMode = #PB_String_NoCase : EndIf

  Protected Idx.i = *State\CurrentIndex, Checked.i, Hay.s, Found.b = #False
  For Checked = 1 To *State\NoteCount
    Idx = (Idx + 1) % *State\NoteCount
    Hay = MamuteXir_Searchable(Idx)
    If UseRegex
      If ExamineRegularExpression(RegexId, Hay) And NextRegularExpressionMatch(RegexId)
        Found = #True
      EndIf
    Else
      If FindString(Hay, SearchText, 1, StrMode) > 0
        Found = #True
      EndIf
    EndIf
    If Found : Break : EndIf
  Next

  If UseRegex : FreeRegularExpression(RegexId) : EndIf

  If Found
    *State\CurrentIndex = Idx
    MamuteXir_Repaint(G_View, G_Status, *State)
    ProcedureReturn #True
  EndIf

  SetGadgetText(G_Status, "NAO ENCONTRADO: " + SearchText)
  ProcedureReturn #False
EndProcedure

; InitialAddr - endereco (0-65535) pra' abrir ja' focado na PRIMEIRA nota
; daquele endereco, se existir; -1 = abre na primeira nota da lista (sem
; endereco preferido). Usado por XIR [<endereco>] (MamuteGui_CmdXir,
; MamuteAssemblerGui.pbi).
Procedure MamuteXir_Open(ParentWindow, InitialAddr.i = -1)
  Protected State.MamuteXirState
  State\NoteCount = ListSize(MamuteNotes())
  State\CurrentIndex = 0

  If InitialAddr >= 0 And State\NoteCount > 0
    ForEach MamuteNotes()
      If MamuteNotes()\Addr = InitialAddr
        State\CurrentIndex = ListIndex(MamuteNotes())
        Break
      EndIf
    Next
  EndIf

  Protected Title.s = "Mamute Assembler - XIR - Notas SUPER-X"

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
  Protected ViewW = 760, ViewH = 420
  Protected WinW = ViewW + Margin * 2
  Protected BtnH = 40, BtnGap = 8
  Protected RowW = 56 * 4 + BtnGap * 5 + Margin * 2
  If RowW > WinW : WinW = RowW : EndIf

  Protected LegendH = 20, StatusH = 24, SearchRowH = 28
  Protected WinH = Margin + LegendH + 8 + ViewH + 12 + StatusH + 12 + BtnH + 12 + SearchRowH + Margin

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, Title,
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #True, #False)
  If Not Win
    ProcedureReturn
  EndIf
  SetWindowColor(Win, ColBorder)

  Protected CurY = Margin

  Protected LegendTxt.s = "Setas Cima/Baixo: nota anterior/proxima  PgUp/PgDn: pula " + Str(#MamuteXir_PageStep) +
                          "  Home/End: 1a/ultima  RETURN: fecha (ou busca)  ESC: sai"
  Protected G_Legend = TextGadget(#PB_Any, Margin, CurY, WinW - Margin * 2, LegendH, LegendTxt)
  SetGadgetColor(G_Legend, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Legend, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Legend, FontID(MFont))
  CurY + LegendH + 8

  Protected G_View = EditorGadget(#PB_Any, Margin, CurY, ViewW, ViewH, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
  SetGadgetColor(G_View, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_View, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_View, FontID(MFont))
  CurY + ViewH + 12

  Protected G_Status = TextGadget(#PB_Any, Margin, CurY, WinW - Margin * 2, StatusH, "")
  SetGadgetColor(G_Status, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Status, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Status, FontID(MFont))
  CurY + StatusH + 12

  ; 4 botoes de navegacao - inicio/anterior/proxima/fim (mesmos glifos do
  ; XTP: "|<"/"<"/">"/">|").
  Protected BtnY = CurY
  Protected CurX = Margin
  Protected G_First = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH) : CurX + 56 + BtnGap
  Protected G_Prev  = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH) : CurX + 56 + BtnGap
  Protected G_Next  = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH) : CurX + 56 + BtnGap
  Protected G_Last  = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH)

  MamuteXd_DrawButton(G_First, "|<", BtnFont)
  MamuteXd_DrawButton(G_Prev, "<", BtnFont)
  MamuteXd_DrawButton(G_Next, ">", BtnFont)
  MamuteXd_DrawButton(G_Last, ">|", BtnFont)
  GadgetToolTip(G_First, "Primeira nota")
  GadgetToolTip(G_Prev, "Nota anterior")
  GadgetToolTip(G_Next, "Proxima nota")
  GadgetToolTip(G_Last, "Ultima nota")
  CurY + BtnH + 12

  ; Campo de busca - MESMO layout/idioma do XTP (StringGadget + Case/Regex
  ; + botao "Buscar").
  Protected SearchY = CurY
  CurX = Margin
  Protected G_SearchLabel = TextGadget(#PB_Any, CurX, SearchY + 4, 62, SearchRowH, "Buscar:") : CurX + 62 + BtnGap
  SetGadgetColor(G_SearchLabel, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_SearchLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_SearchLabel, FontID(MFont))

  Protected G_SearchField = StringGadget(#PB_Any, CurX, SearchY, 320, SearchRowH, "") : CurX + 320 + BtnGap
  SetGadgetColor(G_SearchField, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_SearchField, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_SearchField, FontID(MFont))

  Protected G_CaseCheck = CheckBoxGadget(#PB_Any, CurX, SearchY + 4, 80, SearchRowH, "Case") : CurX + 80 + BtnGap
  SetGadgetColor(G_CaseCheck, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_CaseCheck, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_CaseCheck, FontID(MFont))

  Protected G_RegexCheck = CheckBoxGadget(#PB_Any, CurX, SearchY + 4, 90, SearchRowH, "Regex") : CurX + 90 + BtnGap
  SetGadgetColor(G_RegexCheck, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_RegexCheck, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_RegexCheck, FontID(MFont))

  Protected G_SearchBtn = CanvasGadget(#PB_Any, CurX, SearchY, 90, SearchRowH)
  MamuteXd_DrawButton(G_SearchBtn, "BUSCAR", BtnFont)
  GadgetToolTip(G_CaseCheck, "Marcado = diferencia maiusculas/minusculas")
  GadgetToolTip(G_RegexCheck, "Marcado = o texto buscado e' uma expressao regular")
  GadgetToolTip(G_SearchBtn, "Busca a proxima nota (endereco/slot/tipo/texto, com wraparound)")

  MamuteXir_Repaint(G_View, G_Status, @State)

  AddKeyboardShortcut(Win, #PB_Shortcut_Up, #MamuteXir_Shortcut_Prev)
  AddKeyboardShortcut(Win, #PB_Shortcut_Down, #MamuteXir_Shortcut_Next)
  AddKeyboardShortcut(Win, #PB_Shortcut_PageUp, #MamuteXir_Shortcut_PageUp)
  AddKeyboardShortcut(Win, #PB_Shortcut_PageDown, #MamuteXir_Shortcut_PageDown)
  AddKeyboardShortcut(Win, #PB_Shortcut_Home, #MamuteXir_Shortcut_Home)
  AddKeyboardShortcut(Win, #PB_Shortcut_End, #MamuteXir_Shortcut_End)
  AddKeyboardShortcut(Win, #PB_Shortcut_Return, #MamuteXir_Shortcut_Return)
  AddKeyboardShortcut(Win, #PB_Shortcut_Escape, #MamuteXir_Shortcut_Escape)

  Macro MamuteXir_DoStep(Delta)
    State\CurrentIndex + (Delta)
    MamuteXir_Repaint(G_View, G_Status, @State)
  EndMacro

  Macro MamuteXir_DoHome
    State\CurrentIndex = 0
    MamuteXir_Repaint(G_View, G_Status, @State)
  EndMacro

  Macro MamuteXir_DoEnd
    State\CurrentIndex = State\NoteCount - 1
    MamuteXir_Repaint(G_View, G_Status, @State)
  EndMacro

  Macro MamuteXir_DoSearchNow
    MamuteXir_DoSearch(G_View, G_Status, @State, GetGadgetText(G_SearchField),
                        GetGadgetState(G_CaseCheck), GetGadgetState(G_RegexCheck))
  EndMacro

  Protected Event, Quit = #False, SearchFocused.b
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_First : If EventType() = #PB_EventType_LeftButtonDown : MamuteXir_DoHome : EndIf
          Case G_Prev  : If EventType() = #PB_EventType_LeftButtonDown : MamuteXir_DoStep(-1) : EndIf
          Case G_Next  : If EventType() = #PB_EventType_LeftButtonDown : MamuteXir_DoStep(1) : EndIf
          Case G_Last  : If EventType() = #PB_EventType_LeftButtonDown : MamuteXir_DoEnd : EndIf
          Case G_SearchBtn : If EventType() = #PB_EventType_LeftButtonDown : MamuteXir_DoSearchNow : EndIf
        EndSelect

      Case #PB_Event_Menu
        SearchFocused = Bool(GetActiveGadget() = G_SearchField)
        Select EventMenu()
          Case #MamuteXir_Shortcut_Prev     : If Not SearchFocused : MamuteXir_DoStep(-1) : EndIf
          Case #MamuteXir_Shortcut_Next     : If Not SearchFocused : MamuteXir_DoStep(1) : EndIf
          Case #MamuteXir_Shortcut_PageUp   : If Not SearchFocused : MamuteXir_DoStep(-#MamuteXir_PageStep) : EndIf
          Case #MamuteXir_Shortcut_PageDown : If Not SearchFocused : MamuteXir_DoStep(#MamuteXir_PageStep) : EndIf
          Case #MamuteXir_Shortcut_Home : If Not SearchFocused : MamuteXir_DoHome : EndIf
          Case #MamuteXir_Shortcut_End  : If Not SearchFocused : MamuteXir_DoEnd : EndIf
          Case #MamuteXir_Shortcut_Return
            If SearchFocused
              MamuteXir_DoSearchNow
            Else
              Quit = #True
            EndIf
          Case #MamuteXir_Shortcut_Escape
            Quit = #True
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
