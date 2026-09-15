;
; ------------------------------------------------------------
;  Ajuda -> asMSX...: janela navegavel/pesquisavel com o manual oficial do
;  asMSX (asmsx/doc/asmsx.md, github.com/Fubukimaru/asMSX), montada sobre a
;  base de dados de AsmsxHelpData.pbi (XIncludeFile'd antes deste arquivo,
;  gerada por convert_asmsx.py - descartavel/nao versionado, mesmo espirito
;  de convert_redbook.py/convert_th2handbook.py).
;
;  Ao contrario de RedBookHelpGui.pbi/Th2HandbookHelpGui.pbi (que precisaram
;  de renderer/anchor-map proprios pros ~2900/~1400 links internos desses
;  livros), o manual do asMSX e Markdown real sem nenhum link interno (so um
;  link externo solto, ver AsmsxHelp_Topics()) - por isso esta janela
;  reaproveita GenMdHelp_RenderMarkdown()/GenMdHelp_SetupStyles()
;  (GenericMdHelpGui.pbi, XIncludeFile'd antes deste arquivo) direto, so
;  trocando "ler o topico de um arquivo .md em disco" (uso normal de
;  GenMdHelp_OpenWindow(), conteudo baixado em tempo de execucao) por "ja
;  esta em memoria" (conteudo baked no .exe em tempo de compilacao, como
;  RedBook/Th2Handbook) - layout de busca+arvore+conteudo e navegacao com
;  historico (Alt+Esquerda) identicos a NestorBasicHelpGui.pbi.
; ------------------------------------------------------------
;

#AsmsxHelpGui_ShortcutBack = 3001 ; numero distinto dos outros #...ShortcutBack

Global AsmsxHelpGui_WinID.i = -1

Procedure AsmsxHelpGui_PopulateTree(Tree)
  ClearGadgetItems(Tree)
  Protected Idx = -1
  Protected LastGroup.s = Chr(1) ; sentinela, nunca bate com um Grupo real

  ForEach AsmsxHelp_Topics()
    Idx + 1
    If AsmsxHelp_Topics()\Grupo <> "" And AsmsxHelp_Topics()\Grupo <> LastGroup
      AddGadgetItem(Tree, -1, AsmsxHelp_Topics()\Grupo, 0, 0)
      LastGroup = AsmsxHelp_Topics()\Grupo
    EndIf
    Protected SubLevel = 0
    If AsmsxHelp_Topics()\Grupo <> "" : SubLevel = 1 : EndIf
    AddGadgetItem(Tree, -1, AsmsxHelp_Topics()\Titulo, 0, SubLevel)
    SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, Idx)
  Next
EndProcedure

Procedure AsmsxHelpGui_FilterTree(Tree, SearchText.s)
  Protected Needle.s = LCase(Trim(SearchText))
  If Needle = ""
    AsmsxHelpGui_PopulateTree(Tree)
    ProcedureReturn
  EndIf

  ClearGadgetItems(Tree)
  Protected Idx = -1
  ForEach AsmsxHelp_Topics()
    Idx + 1
    If FindString(LCase(AsmsxHelp_Topics()\Titulo + " " + AsmsxHelp_Topics()\Grupo), Needle) > 0
      Protected Label.s = AsmsxHelp_Topics()\Titulo
      If AsmsxHelp_Topics()\Grupo <> ""
        Label + " (" + AsmsxHelp_Topics()\Grupo + ")"
      EndIf
      AddGadgetItem(Tree, -1, Label, 0, 0)
      SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, Idx)
    EndIf
  Next
EndProcedure

Procedure AsmsxHelp_OpenWindow(ParentWindow)
  If AsmsxHelpGui_WinID <> -1 And IsWindow(AsmsxHelpGui_WinID)
    SetActiveWindow(AsmsxHelpGui_WinID)
    ProcedureReturn
  EndIf

  AsmsxHelp_BuildData()

  Protected WinW = 940, WinH = 620
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Ajuda - asMSX",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #False)
  If Not Win
    ProcedureReturn
  EndIf
  AsmsxHelpGui_WinID = Win

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

  AsmsxHelpGui_PopulateTree(G_Tree)
  AddKeyboardShortcut(Win, #PB_Shortcut_Alt | #PB_Shortcut_Left, #AsmsxHelpGui_ShortcutBack)

  NewList History.i()
  Protected CurrentTopic.i = -1
  Protected BackIdx.i, TreeScanIdx.i

  ; Macro (nao Procedure) de proposito, mesmo motivo de NBHelpGui_DoGoBack em
  ; NestorBasicHelpGui.pbi: precisa acessar direto as locais desta janela.
  Macro AsmsxHelpGui_DoGoBack
    If ListSize(History()) > 0
      LastElement(History())
      BackIdx = History()
      DeleteElement(History())
      If BackIdx >= 0 And SelectElement(AsmsxHelp_Topics(), BackIdx)
        GenMdHelp_RenderMarkdown(G_Content, AsmsxHelp_Topics()\Corpo)
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

  If SelectElement(AsmsxHelp_Topics(), 0)
    GenMdHelp_RenderMarkdown(G_Content, AsmsxHelp_Topics()\Corpo)
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
                  If SelectElement(AsmsxHelp_Topics(), TopicIdx)
                    GenMdHelp_RenderMarkdown(G_Content, AsmsxHelp_Topics()\Corpo)
                    CurrentTopic = TopicIdx
                  EndIf
                EndIf
              EndIf
            EndIf

          Case G_Search
            If EventType() = #PB_EventType_Change
              AsmsxHelpGui_FilterTree(G_Tree, GetGadgetText(G_Search))
              If Trim(GetGadgetText(G_Search)) <> ""
                SetGadgetText(G_Status, Str(CountGadgetItems(G_Tree)) + " resultado(s)")
              Else
                SetGadgetText(G_Status, "")
              EndIf
            EndIf

          Case G_ClearSearch
            SetGadgetText(G_Search, "")
            AsmsxHelpGui_FilterTree(G_Tree, "")
            SetGadgetText(G_Status, "")

          Case G_Back
            AsmsxHelpGui_DoGoBack

          Case G_Close
            Quit = #True

        EndSelect

      Case #PB_Event_Menu
        If EventMenu() = #AsmsxHelpGui_ShortcutBack
          AsmsxHelpGui_DoGoBack
        EndIf

      Case #PB_Event_CloseWindow
        Quit = #True

    EndSelect
  Until Quit

  AsmsxHelpGui_WinID = -1
  CloseModelessChildWindow(ParentWindow, Win, #False)
EndProcedure
