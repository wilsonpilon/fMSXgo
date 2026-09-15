;
; ------------------------------------------------------------
;  Ajuda -> Basic Dignified...: janela navegavel/pesquisavel com os
;  topicos de BasicDignifiedHelpData.pbi (XIncluded antes deste arquivo),
;  cobrindo tanto a sintaxe do dialeto Dignified quanto as configuracoes
;  desta IDE (Configurar -> Basic Dignified...).
;
;  Reaproveita a mesma infraestrutura de renderizacao/navegacao ja usada
;  por Ajuda -> Nestor Basic (NestorBasicHelpGui.pbi, XIncluded antes
;  deste arquivo tambem): NBHelpGui_SetupStyles/_RenderMarkdown entendem
;  "## " (subtitulo), "**negrito**" e "`codigo`" inline - a mesma
;  marcacao usada em BasicDignifiedHelpData.pbi.
;
;  Mais simples que MsxBasicHelpGui.pbi (so uma fonte de topicos, sem
;  dicionario nem pagina de cores): a arvore agrupa BDHelp_Topics() pelo
;  campo Grupo (na ordem em que aparece), igual ao agrupamento por Parte
;  usado na Ajuda MSX BASIC.
; ------------------------------------------------------------
;

#BDHelpGui_ShortcutBack = 3

Global BDHelpGui_WinID.i = -1

Structure BDHelpRow
  IsGroup.b
  RefIndex.i    ; indice em BDHelp_Topics(); -1 para linha de grupo
  Label.s
  SearchKey.s   ; minusculo, vazio para linhas de grupo (nunca batem em busca)
EndStructure

Global NewList BDHelpGui_Rows.BDHelpRow()
Global BDHelpGui_RowsBuilt.b = #False

Procedure BDHelpGui_AddRow(IsGroup.b, RefIndex.i, Label.s, SearchKey.s)
  AddElement(BDHelpGui_Rows())
  BDHelpGui_Rows()\IsGroup = IsGroup
  BDHelpGui_Rows()\RefIndex = RefIndex
  BDHelpGui_Rows()\Label = Label
  BDHelpGui_Rows()\SearchKey = SearchKey
EndProcedure

; Monta a lista achatada uma unica vez por sessao: um cabecalho de grupo
; toda vez que o campo Grupo muda, seguido dos topicos daquele grupo.
Procedure BDHelpGui_BuildRows()
  If BDHelpGui_RowsBuilt
    ProcedureReturn
  EndIf
  BDHelpGui_RowsBuilt = #True

  BDHelp_BuildData()

  Protected Idx.i = -1, CurrentGrupo.s = ""
  ForEach BDHelp_Topics()
    Idx + 1
    If BDHelp_Topics()\Grupo <> CurrentGrupo
      CurrentGrupo = BDHelp_Topics()\Grupo
      BDHelpGui_AddRow(#True, -1, CurrentGrupo, "")
    EndIf
    BDHelpGui_AddRow(#False, Idx, BDHelp_Topics()\Titulo,
                      LCase(BDHelp_Topics()\Titulo + " " + BDHelp_Topics()\Grupo))
  Next
EndProcedure

Procedure BDHelpGui_PopulateTree(Tree)
  ClearGadgetItems(Tree)
  Protected RowIdx = -1
  ForEach BDHelpGui_Rows()
    RowIdx + 1
    AddGadgetItem(Tree, -1, BDHelpGui_Rows()\Label, 0, Bool(Not BDHelpGui_Rows()\IsGroup))
    SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, RowIdx)
  Next
EndProcedure

Procedure BDHelpGui_FilterTree(Tree, SearchText.s)
  Protected Needle.s = LCase(Trim(SearchText))
  If Needle = ""
    BDHelpGui_PopulateTree(Tree)
    ProcedureReturn
  EndIf

  ClearGadgetItems(Tree)
  Protected RowIdx = -1
  ForEach BDHelpGui_Rows()
    RowIdx + 1
    If Not BDHelpGui_Rows()\IsGroup And FindString(BDHelpGui_Rows()\SearchKey, Needle) > 0
      AddGadgetItem(Tree, -1, BDHelpGui_Rows()\Label, 0, 0)
      SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, RowIdx)
    EndIf
  Next
EndProcedure

Procedure.s BDHelpGui_FullBody(RefIndex.i)
  If Not SelectElement(BDHelp_Topics(), RefIndex)
    ProcedureReturn ""
  EndIf
  ProcedureReturn "## " + BDHelp_Topics()\Titulo + #CRLF$ + #CRLF$ +
                  BDHelp_Topics()\Grupo + #CRLF$ + #CRLF$ +
                  BDHelp_Topics()\Corpo
EndProcedure

Procedure BDHelpGui_ShowRow(Sci, RowIdx.i)
  If Not SelectElement(BDHelpGui_Rows(), RowIdx)
    ProcedureReturn
  EndIf
  If BDHelpGui_Rows()\IsGroup
    NBHelpGui_RenderMarkdown(Sci, "## " + BDHelpGui_Rows()\Label + #CRLF$ + #CRLF$ +
                                   "Selecione um topico na lista ao lado.")
  Else
    NBHelpGui_RenderMarkdown(Sci, BDHelpGui_FullBody(BDHelpGui_Rows()\RefIndex))
  EndIf
EndProcedure

Procedure BasicDignifiedHelp_OpenWindow(ParentWindow)
  If BDHelpGui_WinID <> -1 And IsWindow(BDHelpGui_WinID)
    SetActiveWindow(BDHelpGui_WinID)
    ProcedureReturn
  EndIf

  BDHelpGui_BuildRows()

  Protected WinW = 940, WinH = 620
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Ajuda - Basic Dignified",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #False)
  If Not Win
    ProcedureReturn
  EndIf
  BDHelpGui_WinID = Win

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

  BDHelpGui_PopulateTree(G_Tree)
  AddKeyboardShortcut(Win, #PB_Shortcut_Alt | #PB_Shortcut_Left, #BDHelpGui_ShortcutBack)

  NewList History.i()
  Protected CurrentRow.i = -1
  Protected BackIdx.i, TreeScanIdx.i

  ; Macro (nao Procedure) de proposito, mesma razao dos outros dois Ajuda
  ; -> ...: precisa enxergar direto as variaveis locais desta janela
  ; (G_Tree, G_Content, History(), CurrentRow).
  Macro BDHelpGui_DoGoBack
    If ListSize(History()) > 0
      LastElement(History())
      BackIdx = History()
      DeleteElement(History())
      If BackIdx >= 0
        BDHelpGui_ShowRow(G_Content, BackIdx)
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
    BDHelpGui_ShowRow(G_Content, 1)
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
                  BDHelpGui_ShowRow(G_Content, RowIdx)
                  CurrentRow = RowIdx
                EndIf
              EndIf
            EndIf

          Case G_Search
            If EventType() = #PB_EventType_Change
              BDHelpGui_FilterTree(G_Tree, GetGadgetText(G_Search))
              If Trim(GetGadgetText(G_Search)) <> ""
                SetGadgetText(G_Status, Str(CountGadgetItems(G_Tree)) + " resultado(s)")
              Else
                SetGadgetText(G_Status, "")
              EndIf
            EndIf

          Case G_ClearSearch
            SetGadgetText(G_Search, "")
            BDHelpGui_FilterTree(G_Tree, "")
            SetGadgetText(G_Status, "")

          Case G_Back
            BDHelpGui_DoGoBack

          Case G_Close
            Quit = #True

        EndSelect

      Case #PB_Event_Menu
        If EventMenu() = #BDHelpGui_ShortcutBack
          BDHelpGui_DoGoBack
        EndIf

      Case #PB_Event_CloseWindow
        Quit = #True

    EndSelect
  Until Quit

  BDHelpGui_WinID = -1
  CloseModelessChildWindow(ParentWindow, Win, #False)
EndProcedure
