;
; ------------------------------------------------------------
;  Ajuda -> Mamute Assembler...: janela navegavel/pesquisavel com os
;  comandos do Mamute Assembler, montada sobre a base de dados de
;  MamuteHelpData.pbi (XIncludeFile'd antes deste arquivo) - mesmo layout de
;  busca+arvore+conteudo+Voltar das outras janelas de Ajuda, reaproveitando
;  GenMdHelp_RenderMarkdown()/GenMdHelp_SetupStyles() (GenericMdHelpGui.pbi)
;  direto, sem renderer proprio - igual AsmsxHelpGui.pbi (o conteudo aqui
;  tambem nao tem links internos).
; ------------------------------------------------------------
;

#MamuteHelpGui_ShortcutBack = 3101 ; numero distinto dos outros #...ShortcutBack

Global MamuteHelpGui_WinID.i = -1

Procedure MamuteHelpGui_PopulateTree(Tree)
  ClearGadgetItems(Tree)
  Protected Idx = -1
  Protected LastGroup.s = Chr(1) ; sentinela, nunca bate com um Grupo real

  ForEach MamuteHelp_Topics()
    Idx + 1
    If MamuteHelp_Topics()\Grupo <> "" And MamuteHelp_Topics()\Grupo <> LastGroup
      AddGadgetItem(Tree, -1, MamuteHelp_Topics()\Grupo, 0, 0)
      LastGroup = MamuteHelp_Topics()\Grupo
    EndIf
    Protected SubLevel = 0
    If MamuteHelp_Topics()\Grupo <> "" : SubLevel = 1 : EndIf
    AddGadgetItem(Tree, -1, MamuteHelp_Topics()\Titulo, 0, SubLevel)
    SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, Idx)
  Next
EndProcedure

Procedure MamuteHelpGui_FilterTree(Tree, SearchText.s)
  Protected Needle.s = LCase(Trim(SearchText))
  If Needle = ""
    MamuteHelpGui_PopulateTree(Tree)
    ProcedureReturn
  EndIf

  ClearGadgetItems(Tree)
  Protected Idx = -1
  ForEach MamuteHelp_Topics()
    Idx + 1
    If FindString(LCase(MamuteHelp_Topics()\Titulo + " " + MamuteHelp_Topics()\Grupo), Needle) > 0
      Protected Label.s = MamuteHelp_Topics()\Titulo
      If MamuteHelp_Topics()\Grupo <> ""
        Label + " (" + MamuteHelp_Topics()\Grupo + ")"
      EndIf
      AddGadgetItem(Tree, -1, Label, 0, 0)
      SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, Idx)
    EndIf
  Next
EndProcedure

Procedure MamuteHelp_OpenWindow(ParentWindow)
  If MamuteHelpGui_WinID <> -1 And IsWindow(MamuteHelpGui_WinID)
    SetActiveWindow(MamuteHelpGui_WinID)
    ProcedureReturn
  EndIf

  MamuteHelp_BuildData()
  MamuteHelp_BuildSuperXNotes()

  Protected WinW = 940, WinH = 620
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Ajuda - Mamute Assembler",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #False)
  If Not Win
    ProcedureReturn
  EndIf
  MamuteHelpGui_WinID = Win

  Protected TopY = 24
  TextGadget(#PB_Any, 24, TopY + 4, 55, 20, "Buscar:")
  Protected G_Search = StringGadget(#PB_Any, 87, TopY, 300, 24, "")
  GadgetToolTip(G_Search, "Filtra por titulo ou secao")
  Protected G_ClearSearch = ThemedButton(399, TopY, 80, 24, "Limpar", Chr(#Icon_Clear))
  GadgetToolTip(G_ClearSearch, "Limpar")
  Protected G_Status = TextGadget(#PB_Any, 495, TopY + 4, WinW - 519, 20, "")

  Protected ButtonY = WinH - 56
  Protected TreeY = TopY + 24 + 16
  Protected TreeH = ButtonY - 16 - TreeY
  Protected TreeW = 300
  Protected G_Tree = TreeGadget(#PB_Any, 24, TreeY, TreeW, TreeH)
  Protected G_Content = ScintillaGadget(#PB_Any, 24 + TreeW + 24, TreeY, WinW - TreeW - 72, TreeH, @GenMdHelp_ScintillaCallback())
  GenMdHelp_SetupStyles(G_Content)
  ScintillaSendMessage(G_Content, #SCI_SETMOUSEDOWNCAPTURES, 1, 0)

  Protected G_Back = ThemedButton(24, ButtonY, 180, 32, "<- Voltar (Alt+Esquerda)", Chr(#Icon_ArrowLeft))
  GadgetToolTip(G_Back, "<- Voltar (Alt+Esquerda)")
  Protected G_Close = ThemedButton(WinW - 24 - 110, ButtonY, 110, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  MamuteHelpGui_PopulateTree(G_Tree)
  AddKeyboardShortcut(Win, #PB_Shortcut_Alt | #PB_Shortcut_Left, #MamuteHelpGui_ShortcutBack)

  NewList History.i()
  Protected CurrentTopic.i = -1
  Protected BackIdx.i, TreeScanIdx.i

  ; Macro (nao Procedure) de proposito, mesmo motivo de NBHelpGui_DoGoBack em
  ; NestorBasicHelpGui.pbi: precisa acessar direto as locais desta janela.
  Macro MamuteHelpGui_DoGoBack
    If ListSize(History()) > 0
      LastElement(History())
      BackIdx = History()
      DeleteElement(History())
      If BackIdx >= 0 And SelectElement(MamuteHelp_Topics(), BackIdx)
        GenMdHelp_RenderMarkdown(G_Content, MamuteHelp_Topics()\Corpo)
        CurrentTopic = BackIdx
        For TreeScanIdx = 0 To CountGadgetItems(G_Tree) - 1
          If GetGadgetItemData(G_Tree, TreeScanIdx) = BackIdx
            SetGadgetState(G_Tree, TreeScanIdx)
            Break
          EndIf
        Next
      EndIf
    EndIf
  EndMacro

  If SelectElement(MamuteHelp_Topics(), 0)
    GenMdHelp_RenderMarkdown(G_Content, MamuteHelp_Topics()\Corpo)
    CurrentTopic = 0
    SetGadgetState(G_Tree, 0)
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
                Protected TopicIdx = GetGadgetItemData(G_Tree, Sel)
                If TopicIdx <> CurrentTopic
                  AddElement(History()) : History() = CurrentTopic
                  If SelectElement(MamuteHelp_Topics(), TopicIdx)
                    GenMdHelp_RenderMarkdown(G_Content, MamuteHelp_Topics()\Corpo)
                    CurrentTopic = TopicIdx
                  EndIf
                EndIf
              EndIf
            EndIf

          Case G_Search
            If EventType() = #PB_EventType_Change
              MamuteHelpGui_FilterTree(G_Tree, GetGadgetText(G_Search))
              If Trim(GetGadgetText(G_Search)) <> ""
                SetGadgetText(G_Status, Str(CountGadgetItems(G_Tree)) + " resultado(s)")
              Else
                SetGadgetText(G_Status, "")
              EndIf
            EndIf

          Case G_ClearSearch
            SetGadgetText(G_Search, "")
            MamuteHelpGui_FilterTree(G_Tree, "")
            SetGadgetText(G_Status, "")

          Case G_Back
            MamuteHelpGui_DoGoBack

          Case G_Close
            Quit = #True

        EndSelect

      Case #PB_Event_Menu
        If EventMenu() = #MamuteHelpGui_ShortcutBack
          MamuteHelpGui_DoGoBack
        EndIf

      Case #PB_Event_CloseWindow
        Quit = #True

    EndSelect
  Until Quit

  MamuteHelpGui_WinID = -1
  CloseModelessChildWindow(ParentWindow, Win, #False)
EndProcedure
