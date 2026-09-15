;
; ------------------------------------------------------------
;  Ajuda -> SEE Tracker...: janela navegavel/pesquisavel com os topicos de
;  SeeTrackerHelpData.pbi (XIncluded antes deste arquivo), cobrindo o
;  manual do editor SEE original, o formato de arquivo .SEE e o driver de
;  replay - material de estudo pro futuro tracker de SFX compativel desta
;  IDE (ver grupo "Rumo a um tracker compativel" nos dados).
;
;  Reaproveita a mesma infraestrutura de renderizacao/navegacao ja usada
;  por Ajuda -> Nestor Basic/Basic Dignified (NestorBasicHelpGui.pbi,
;  XIncluded antes deste arquivo): NBHelpGui_SetupStyles/_RenderMarkdown
;  entendem "## " (subtitulo), "**negrito**" e "`codigo`" inline.
;
;  Clone estrutural de BasicDignifiedHelpGui.pbi (arvore agrupada por
;  Grupo, busca por titulo/grupo, historico com Alt+Esquerda) - so troca o
;  prefixo/fonte de dados.
; ------------------------------------------------------------
;

#SeeHelpGui_ShortcutBack = 3

Global SeeHelpGui_WinID.i = -1

Structure SeeHelpRow
  IsGroup.b
  RefIndex.i    ; indice em SeeHelp_Topics(); -1 para linha de grupo
  Label.s
  SearchKey.s   ; minusculo, vazio para linhas de grupo (nunca batem em busca)
EndStructure

Global NewList SeeHelpGui_Rows.SeeHelpRow()
Global SeeHelpGui_RowsBuilt.b = #False

Procedure SeeHelpGui_AddRow(IsGroup.b, RefIndex.i, Label.s, SearchKey.s)
  AddElement(SeeHelpGui_Rows())
  SeeHelpGui_Rows()\IsGroup = IsGroup
  SeeHelpGui_Rows()\RefIndex = RefIndex
  SeeHelpGui_Rows()\Label = Label
  SeeHelpGui_Rows()\SearchKey = SearchKey
EndProcedure

; Monta a lista achatada uma unica vez por sessao: um cabecalho de grupo
; toda vez que o campo Grupo muda, seguido dos topicos daquele grupo.
Procedure SeeHelpGui_BuildRows()
  If SeeHelpGui_RowsBuilt
    ProcedureReturn
  EndIf
  SeeHelpGui_RowsBuilt = #True

  SeeHelp_BuildData()

  Protected Idx.i = -1, CurrentGrupo.s = ""
  ForEach SeeHelp_Topics()
    Idx + 1
    If SeeHelp_Topics()\Grupo <> CurrentGrupo
      CurrentGrupo = SeeHelp_Topics()\Grupo
      SeeHelpGui_AddRow(#True, -1, CurrentGrupo, "")
    EndIf
    SeeHelpGui_AddRow(#False, Idx, SeeHelp_Topics()\Titulo,
                       LCase(SeeHelp_Topics()\Titulo + " " + SeeHelp_Topics()\Grupo))
  Next
EndProcedure

Procedure SeeHelpGui_PopulateTree(Tree)
  ClearGadgetItems(Tree)
  Protected RowIdx = -1
  ForEach SeeHelpGui_Rows()
    RowIdx + 1
    AddGadgetItem(Tree, -1, SeeHelpGui_Rows()\Label, 0, Bool(Not SeeHelpGui_Rows()\IsGroup))
    SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, RowIdx)
  Next
EndProcedure

Procedure SeeHelpGui_FilterTree(Tree, SearchText.s)
  Protected Needle.s = LCase(Trim(SearchText))
  If Needle = ""
    SeeHelpGui_PopulateTree(Tree)
    ProcedureReturn
  EndIf

  ClearGadgetItems(Tree)
  Protected RowIdx = -1
  ForEach SeeHelpGui_Rows()
    RowIdx + 1
    If Not SeeHelpGui_Rows()\IsGroup And FindString(SeeHelpGui_Rows()\SearchKey, Needle) > 0
      AddGadgetItem(Tree, -1, SeeHelpGui_Rows()\Label, 0, 0)
      SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, RowIdx)
    EndIf
  Next
EndProcedure

Procedure.s SeeHelpGui_FullBody(RefIndex.i)
  If Not SelectElement(SeeHelp_Topics(), RefIndex)
    ProcedureReturn ""
  EndIf
  ProcedureReturn "## " + SeeHelp_Topics()\Titulo + #CRLF$ + #CRLF$ +
                  SeeHelp_Topics()\Grupo + #CRLF$ + #CRLF$ +
                  SeeHelp_Topics()\Corpo
EndProcedure

Procedure SeeHelpGui_ShowRow(Sci, RowIdx.i)
  If Not SelectElement(SeeHelpGui_Rows(), RowIdx)
    ProcedureReturn
  EndIf
  If SeeHelpGui_Rows()\IsGroup
    NBHelpGui_RenderMarkdown(Sci, "## " + SeeHelpGui_Rows()\Label + #CRLF$ + #CRLF$ +
                                   "Selecione um topico na lista ao lado.")
  Else
    NBHelpGui_RenderMarkdown(Sci, SeeHelpGui_FullBody(SeeHelpGui_Rows()\RefIndex))
  EndIf
EndProcedure

Procedure SeeTrackerHelp_OpenWindow(ParentWindow)
  If SeeHelpGui_WinID <> -1 And IsWindow(SeeHelpGui_WinID)
    SetActiveWindow(SeeHelpGui_WinID)
    ProcedureReturn
  EndIf

  SeeHelpGui_BuildRows()

  Protected WinW = 940, WinH = 620
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Ajuda - SEE Tracker",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #False)
  If Not Win
    ProcedureReturn
  EndIf
  SeeHelpGui_WinID = Win

  Protected TopY = 24
  TextGadget(#PB_Any, 24, TopY + 4, 55, 20, "Buscar:")
  Protected G_Search = StringGadget(#PB_Any, 87, TopY, 300, 24, "")
  GadgetToolTip(G_Search, "Filtra por titulo ou grupo")
  Protected G_ClearSearch = ThemedButton(399, TopY, 80, 24, "Limpar", Chr(#Icon_Clear))
  GadgetToolTip(G_ClearSearch, "Limpar")
  Protected G_Status = TextGadget(#PB_Any, 495, TopY + 4, WinW - 519, 20, "")

  Protected ButtonY = WinH - 56
  Protected TreeY = TopY + 24 + 16
  Protected TreeH = ButtonY - 16 - TreeY
  Protected TreeW = 300
  Protected G_Tree = TreeGadget(#PB_Any, 24, TreeY, TreeW, TreeH)
  Protected G_Content = ScintillaGadget(#PB_Any, 24 + TreeW + 24, TreeY, WinW - TreeW - 72, TreeH, 0)
  NBHelpGui_SetupStyles(G_Content)

  Protected G_Back = ThemedButton(24, ButtonY, 180, 32, "<- Voltar (Alt+Esquerda)", Chr(#Icon_ArrowLeft))
  GadgetToolTip(G_Back, "<- Voltar (Alt+Esquerda)")
  Protected G_Close = ThemedButton(WinW - 24 - 110, ButtonY, 110, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  SeeHelpGui_PopulateTree(G_Tree)
  AddKeyboardShortcut(Win, #PB_Shortcut_Alt | #PB_Shortcut_Left, #SeeHelpGui_ShortcutBack)

  NewList History.i()
  Protected CurrentRow.i = -1
  Protected BackIdx.i, TreeScanIdx.i

  ; Macro (nao Procedure) de proposito, mesma razao dos outros Ajuda -> ...:
  ; precisa enxergar direto as variaveis locais desta janela (G_Tree,
  ; G_Content, History(), CurrentRow).
  Macro SeeHelpGui_DoGoBack
    If ListSize(History()) > 0
      LastElement(History())
      BackIdx = History()
      DeleteElement(History())
      If BackIdx >= 0
        SeeHelpGui_ShowRow(G_Content, BackIdx)
        CurrentRow = BackIdx
        For TreeScanIdx = 0 To CountGadgetItems(G_Tree) - 1
          If GetGadgetItemData(G_Tree, TreeScanIdx) = BackIdx
            SetGadgetState(G_Tree, TreeScanIdx)
            Break
          EndIf
        Next
      EndIf
    EndIf
  EndMacro

  ; Linha 0 e sempre um cabecalho de grupo (Introducao); a primeira linha
  ; de conteudo de verdade fica na linha 1.
  If CountGadgetItems(G_Tree) > 1
    SeeHelpGui_ShowRow(G_Content, 1)
    CurrentRow = 1
    SetGadgetState(G_Tree, 1)
  EndIf

  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event

      Case #PB_Event_Gadget
        Select EventGadget()

          Case G_Tree
            If EventType() = #PB_EventType_Change
              Protected Sel = GetGadgetState(G_Tree)
              If Sel >= 0
                Protected RowIdx = GetGadgetItemData(G_Tree, Sel)
                If RowIdx <> CurrentRow
                  AddElement(History()) : History() = CurrentRow
                  SeeHelpGui_ShowRow(G_Content, RowIdx)
                  CurrentRow = RowIdx
                EndIf
              EndIf
            EndIf

          Case G_Search
            If EventType() = #PB_EventType_Change
              SeeHelpGui_FilterTree(G_Tree, GetGadgetText(G_Search))
              If Trim(GetGadgetText(G_Search)) <> ""
                SetGadgetText(G_Status, Str(CountGadgetItems(G_Tree)) + " resultado(s)")
              Else
                SetGadgetText(G_Status, "")
              EndIf
            EndIf

          Case G_ClearSearch
            SetGadgetText(G_Search, "")
            SeeHelpGui_FilterTree(G_Tree, "")
            SetGadgetText(G_Status, "")

          Case G_Back
            SeeHelpGui_DoGoBack

          Case G_Close
            Quit = #True

        EndSelect

      Case #PB_Event_Menu
        If EventMenu() = #SeeHelpGui_ShortcutBack
          SeeHelpGui_DoGoBack
        EndIf

      Case #PB_Event_CloseWindow
        Quit = #True

    EndSelect
  Until Quit

  SeeHelpGui_WinID = -1
  CloseModelessChildWindow(ParentWindow, Win, #False)
EndProcedure
