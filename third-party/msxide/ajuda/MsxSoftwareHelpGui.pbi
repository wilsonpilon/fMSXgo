;
; ------------------------------------------------------------
;  Ajuda -> MSX-Basic/DOS/CP-M (RuMSX)...: janela navegavel/pesquisavel com
;  os comandos extraidos de help/SOFTWARE.CHM (RuMSX, Lex Lechz -
;  lexlechz.at), base de dados em MsxSoftwareHelpData.pbi (XIncludeFile'd
;  antes deste arquivo).
;
;  Ao contrario de MsxManualsHelpGui.pbi (manuais tecnicos antigos, texto
;  pre-formatado em ASCII art), este conteudo e prosa curta por comando
;  (Sintaxe/Funcao/Exemplo/Veja tambem) - exatamente o formato que o
;  "mini-Markdown" comum ja atende, entao reusa NBHelpGui_SetupStyles()/
;  NBHelpGui_RenderMarkdown() (NestorBasicHelpGui.pbi, XIncluded antes) em
;  vez de escrever um renderizador proprio. Layout/navegacao (busca/
;  historico/arvore) identicos as outras janelas de Ajuda.
;
;  Nota: e' intencionalmente uma SEGUNDA fonte de ajuda de MSX-Basic,
;  paralela a "Ajuda -> MSX BASIC..." (MsxBasicHelpGui.pbi, baseada no
;  livro "Linguagem BASIC MSX") - decisao do usuario, mantidas as duas para
;  comparar qual fica mais completa.
; ------------------------------------------------------------
;

#SoftwareHelpGui_Row_Group = 1
#SoftwareHelpGui_Row_Topic = 2

#SoftwareHelpGui_ShortcutBack = 4

Global SoftwareHelpGui_WinID.i = -1

Structure SoftwareHelpRow
  Kind.i
  RefIndex.i    ; indice em SoftwareHelp_Topics() (Kind=Topic); -1 em grupos
  Label.s
  SearchKey.s
  SubLevel.i
EndStructure

Global NewList SoftwareHelpGui_Rows.SoftwareHelpRow()
Global SoftwareHelpGui_RowsBuilt.b = #False

Procedure SoftwareHelpGui_AddRow(Kind.i, RefIndex.i, Label.s, SearchKey.s, SubLevel.i)
  AddElement(SoftwareHelpGui_Rows())
  SoftwareHelpGui_Rows()\Kind = Kind
  SoftwareHelpGui_Rows()\RefIndex = RefIndex
  SoftwareHelpGui_Rows()\Label = Label
  SoftwareHelpGui_Rows()\SearchKey = SearchKey
  SoftwareHelpGui_Rows()\SubLevel = SubLevel
EndProcedure

Procedure SoftwareHelpGui_BuildRows()
  If SoftwareHelpGui_RowsBuilt
    ProcedureReturn
  EndIf
  SoftwareHelpGui_RowsBuilt = #True

  SoftwareHelp_BuildData()

  Protected Idx.i = -1, CurrentGrupo.s = ""
  ForEach SoftwareHelp_Topics()
    Idx + 1
    If SoftwareHelp_Topics()\Grupo <> CurrentGrupo
      CurrentGrupo = SoftwareHelp_Topics()\Grupo
      SoftwareHelpGui_AddRow(#SoftwareHelpGui_Row_Group, -1, CurrentGrupo, "", 0)
    EndIf
    SoftwareHelpGui_AddRow(#SoftwareHelpGui_Row_Topic, Idx,
                            SoftwareHelp_Topics()\Titulo,
                            LCase(SoftwareHelp_Topics()\Titulo + " " + SoftwareHelp_Topics()\Grupo), 1)
  Next
EndProcedure

Procedure SoftwareHelpGui_PopulateTree(Tree)
  ClearGadgetItems(Tree)
  Protected RowIdx = -1
  ForEach SoftwareHelpGui_Rows()
    RowIdx + 1
    AddGadgetItem(Tree, -1, SoftwareHelpGui_Rows()\Label, 0, SoftwareHelpGui_Rows()\SubLevel)
    SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, RowIdx)
  Next
EndProcedure

Procedure SoftwareHelpGui_FilterTree(Tree, SearchText.s)
  Protected Needle.s = LCase(Trim(SearchText))
  If Needle = ""
    SoftwareHelpGui_PopulateTree(Tree)
    ProcedureReturn
  EndIf

  ClearGadgetItems(Tree)
  Protected RowIdx = -1
  ForEach SoftwareHelpGui_Rows()
    RowIdx + 1
    If SoftwareHelpGui_Rows()\Kind <> #SoftwareHelpGui_Row_Group And FindString(SoftwareHelpGui_Rows()\SearchKey, Needle) > 0
      AddGadgetItem(Tree, -1, SoftwareHelpGui_Rows()\Label, 0, 0)
      SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, RowIdx)
    EndIf
  Next
EndProcedure

Procedure SoftwareHelpGui_ShowRow(Sci, RowIdx.i)
  If Not SelectElement(SoftwareHelpGui_Rows(), RowIdx)
    ProcedureReturn
  EndIf
  Select SoftwareHelpGui_Rows()\Kind
    Case #SoftwareHelpGui_Row_Group
      NBHelpGui_RenderMarkdown(Sci, "## " + SoftwareHelpGui_Rows()\Label + #CRLF$ + #CRLF$ +
                                     "Selecione um comando na lista ao lado.")
    Case #SoftwareHelpGui_Row_Topic
      If SelectElement(SoftwareHelp_Topics(), SoftwareHelpGui_Rows()\RefIndex)
        NBHelpGui_RenderMarkdown(Sci, SoftwareHelp_Topics()\Corpo)
      EndIf
  EndSelect
EndProcedure

Procedure MsxSoftwareHelp_OpenWindow(ParentWindow)
  If SoftwareHelpGui_WinID <> -1 And IsWindow(SoftwareHelpGui_WinID)
    SetActiveWindow(SoftwareHelpGui_WinID)
    ProcedureReturn
  EndIf

  SoftwareHelpGui_BuildRows()

  Protected WinW = 980, WinH = 640
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Ajuda - MSX-Basic/DOS/CP-M (RuMSX)",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #False)
  If Not Win
    ProcedureReturn
  EndIf
  SoftwareHelpGui_WinID = Win

  Protected TopY = 24
  TextGadget(#PB_Any, 24, TopY + 4, 55, 20, "Buscar:")
  Protected G_Search = StringGadget(#PB_Any, 87, TopY, 300, 24, "")
  GadgetToolTip(G_Search, "Filtra por nome do comando ou grupo")
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

  SoftwareHelpGui_PopulateTree(G_Tree)
  AddKeyboardShortcut(Win, #PB_Shortcut_Alt | #PB_Shortcut_Left, #SoftwareHelpGui_ShortcutBack)

  NewList History.i()
  Protected CurrentRow.i = -1
  Protected BackIdx.i, TreeScanIdx.i

  Macro SoftwareHelpGui_DoGoBack
    If ListSize(History()) > 0
      LastElement(History())
      BackIdx = History()
      DeleteElement(History())
      If BackIdx >= 0
        SoftwareHelpGui_ShowRow(G_Content, BackIdx)
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

  If CountGadgetItems(G_Tree) > 1
    SoftwareHelpGui_ShowRow(G_Content, 1)
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
                  SoftwareHelpGui_ShowRow(G_Content, RowIdx)
                  CurrentRow = RowIdx
                EndIf
              EndIf
            EndIf

          Case G_Search
            If EventType() = #PB_EventType_Change
              SoftwareHelpGui_FilterTree(G_Tree, GetGadgetText(G_Search))
              If Trim(GetGadgetText(G_Search)) <> ""
                SetGadgetText(G_Status, Str(CountGadgetItems(G_Tree)) + " resultado(s)")
              Else
                SetGadgetText(G_Status, "")
              EndIf
            EndIf

          Case G_ClearSearch
            SetGadgetText(G_Search, "")
            SoftwareHelpGui_FilterTree(G_Tree, "")
            SetGadgetText(G_Status, "")

          Case G_Back
            SoftwareHelpGui_DoGoBack

          Case G_Close
            Quit = #True

        EndSelect

      Case #PB_Event_Menu
        If EventMenu() = #SoftwareHelpGui_ShortcutBack
          SoftwareHelpGui_DoGoBack
        EndIf

      Case #PB_Event_CloseWindow
        Quit = #True

    EndSelect
  Until Quit

  SoftwareHelpGui_WinID = -1
  CloseModelessChildWindow(ParentWindow, Win, #False)
EndProcedure
