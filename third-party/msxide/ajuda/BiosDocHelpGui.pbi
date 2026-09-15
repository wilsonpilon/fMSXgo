;
; ------------------------------------------------------------
;  Ajuda -> BIOS MSX: Documentacao...: janela navegavel/pesquisavel com a
;  secao "Documentation & Concepts" de help/MSXBIOS.CHM (RuMSX, Lex Lechz -
;  lexlechz.at) - Printer ESC sequences e Software-Reset -, base de dados
;  em BiosDocHelpData.pbi (XIncludeFile'd antes deste arquivo). So 2
;  topicos por enquanto (fiel ao CHM original); ver docs/RELEASE_NOTES.md
;  se mais paginas forem incorporadas depois.
;
;  Mesmo renderizador monoespacado/sem quebra automatica de
;  MsxManualsHelpGui.pbi (nao o "mini-Markdown" comum), por consistencia
;  com as outras 2 janelas de MSXBIOS.CHM (BiosCallsHelpGui.pbi/
;  HardwareHelpGui.pbi).
; ------------------------------------------------------------
;

#BiosDocHelpGui_Row_Group = 1
#BiosDocHelpGui_Row_Topic = 2

#BiosDocHelpGui_Style_Title = 1
#BiosDocHelpGui_Style_Body  = 2

#BiosDocHelpGui_ShortcutBack = 7

Global BiosDocHelpGui_WinID.i = -1

Structure BiosDocHelpRow
  Kind.i
  RefIndex.i
  Label.s
  SearchKey.s
  SubLevel.i
EndStructure

Global NewList BiosDocHelpGui_Rows.BiosDocHelpRow()
Global BiosDocHelpGui_RowsBuilt.b = #False

Procedure BiosDocHelpGui_AddRow(Kind.i, RefIndex.i, Label.s, SearchKey.s, SubLevel.i)
  AddElement(BiosDocHelpGui_Rows())
  BiosDocHelpGui_Rows()\Kind = Kind
  BiosDocHelpGui_Rows()\RefIndex = RefIndex
  BiosDocHelpGui_Rows()\Label = Label
  BiosDocHelpGui_Rows()\SearchKey = SearchKey
  BiosDocHelpGui_Rows()\SubLevel = SubLevel
EndProcedure

Procedure BiosDocHelpGui_BuildRows()
  If BiosDocHelpGui_RowsBuilt
    ProcedureReturn
  EndIf
  BiosDocHelpGui_RowsBuilt = #True

  BiosDocHelp_BuildData()

  Protected Idx.i = -1, CurrentGrupo.s = ""
  ForEach BiosDocHelp_Topics()
    Idx + 1
    If BiosDocHelp_Topics()\Grupo <> CurrentGrupo
      CurrentGrupo = BiosDocHelp_Topics()\Grupo
      BiosDocHelpGui_AddRow(#BiosDocHelpGui_Row_Group, -1, CurrentGrupo, "", 0)
    EndIf
    BiosDocHelpGui_AddRow(#BiosDocHelpGui_Row_Topic, Idx,
                             BiosDocHelp_Topics()\Titulo,
                             LCase(BiosDocHelp_Topics()\Titulo + " " + BiosDocHelp_Topics()\Grupo), 1)
  Next
EndProcedure

Procedure BiosDocHelpGui_PopulateTree(Tree)
  ClearGadgetItems(Tree)
  Protected RowIdx = -1
  ForEach BiosDocHelpGui_Rows()
    RowIdx + 1
    AddGadgetItem(Tree, -1, BiosDocHelpGui_Rows()\Label, 0, BiosDocHelpGui_Rows()\SubLevel)
    SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, RowIdx)
  Next
EndProcedure

Procedure BiosDocHelpGui_FilterTree(Tree, SearchText.s)
  Protected Needle.s = LCase(Trim(SearchText))
  If Needle = ""
    BiosDocHelpGui_PopulateTree(Tree)
    ProcedureReturn
  EndIf

  ClearGadgetItems(Tree)
  Protected RowIdx = -1
  ForEach BiosDocHelpGui_Rows()
    RowIdx + 1
    If BiosDocHelpGui_Rows()\Kind <> #BiosDocHelpGui_Row_Group And FindString(BiosDocHelpGui_Rows()\SearchKey, Needle) > 0
      AddGadgetItem(Tree, -1, BiosDocHelpGui_Rows()\Label, 0, 0)
      SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, RowIdx)
    EndIf
  Next
EndProcedure

Procedure BiosDocHelpGui_SetupStyles(Sci)
  Protected *MonoFont = UTF8("Consolas")
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #STYLE_DEFAULT, RGB(30, 30, 30))
  ScintillaSendMessage(Sci, #SCI_STYLESETBACK, #STYLE_DEFAULT, RGB(255, 255, 255))
  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #STYLE_DEFAULT, *MonoFont)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #STYLE_DEFAULT, 10)
  ScintillaSendMessage(Sci, #SCI_STYLECLEARALL)

  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #BiosDocHelpGui_Style_Title, *MonoFont)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #BiosDocHelpGui_Style_Title, 12)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #BiosDocHelpGui_Style_Title, RGB(20, 60, 120))
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #BiosDocHelpGui_Style_Title, 1)

  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #BiosDocHelpGui_Style_Body, *MonoFont)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #BiosDocHelpGui_Style_Body, 10)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #BiosDocHelpGui_Style_Body, RGB(30, 30, 30))
  FreeMemory(*MonoFont)

  ScintillaSendMessage(Sci, #SCI_SETCARETFORE, RGB(255, 255, 255))
  ScintillaSendMessage(Sci, #SCI_SETWRAPMODE, #SC_WRAP_NONE)
  ScintillaSendMessage(Sci, #SCI_SETSCROLLWIDTHTRACKING, 1)
EndProcedure

Procedure BiosDocHelpGui_EmitRun(Sci, Text.s, Style)
  Protected ByteLen = StringByteLength(Text, #PB_UTF8)
  If ByteLen > 0
    ScintillaSendMessage(Sci, #SCI_SETSTYLING, ByteLen, Style)
  EndIf
EndProcedure

Procedure BiosDocHelpGui_RenderTopic(Sci, Titulo.s, Corpo.s)
  Protected TitleLine.s = Titulo + #CRLF$ + #CRLF$
  Protected FullText.s = TitleLine + Corpo
  Protected *Buffer = UTF8(FullText)
  ScintillaSendMessage(Sci, #SCI_SETREADONLY, 0)
  ScintillaSendMessage(Sci, #SCI_SETTEXT, 0, *Buffer)
  FreeMemory(*Buffer)

  ScintillaSendMessage(Sci, #SCI_STARTSTYLING, 0, 0)
  BiosDocHelpGui_EmitRun(Sci, TitleLine, #BiosDocHelpGui_Style_Title)
  BiosDocHelpGui_EmitRun(Sci, Corpo, #BiosDocHelpGui_Style_Body)

  ScintillaSendMessage(Sci, #SCI_SETREADONLY, 1)
  ScintillaSendMessage(Sci, #SCI_EMPTYUNDOBUFFER)
  ScintillaSendMessage(Sci, #SCI_GOTOPOS, 0)
EndProcedure

Procedure BiosDocHelpGui_ShowRow(Sci, RowIdx.i)
  If Not SelectElement(BiosDocHelpGui_Rows(), RowIdx)
    ProcedureReturn
  EndIf
  Select BiosDocHelpGui_Rows()\Kind
    Case #BiosDocHelpGui_Row_Group
      BiosDocHelpGui_RenderTopic(Sci, BiosDocHelpGui_Rows()\Label, "Selecione um documento na lista ao lado.")
    Case #BiosDocHelpGui_Row_Topic
      If SelectElement(BiosDocHelp_Topics(), BiosDocHelpGui_Rows()\RefIndex)
        BiosDocHelpGui_RenderTopic(Sci, BiosDocHelp_Topics()\Titulo, BiosDocHelp_Topics()\Corpo)
      EndIf
  EndSelect
EndProcedure

Procedure BiosDocHelp_OpenWindow(ParentWindow)
  If BiosDocHelpGui_WinID <> -1 And IsWindow(BiosDocHelpGui_WinID)
    SetActiveWindow(BiosDocHelpGui_WinID)
    ProcedureReturn
  EndIf

  BiosDocHelpGui_BuildRows()

  Protected WinW = 980, WinH = 640
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Ajuda - BIOS MSX: Documentacao",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #False)
  If Not Win
    ProcedureReturn
  EndIf
  BiosDocHelpGui_WinID = Win

  Protected TopY = 24
  TextGadget(#PB_Any, 24, TopY + 4, 55, 20, "Buscar:")
  Protected G_Search = StringGadget(#PB_Any, 87, TopY, 300, 24, "")
  GadgetToolTip(G_Search, "Filtra por titulo")
  Protected G_ClearSearch = ThemedButton(399, TopY, 80, 24, "Limpar", Chr(#Icon_Clear))
  GadgetToolTip(G_ClearSearch, "Limpar")
  Protected G_Status = TextGadget(#PB_Any, 495, TopY + 4, WinW - 519, 20, "")

  Protected ButtonY = WinH - 56
  Protected TreeY = TopY + 24 + 16
  Protected TreeH = ButtonY - 16 - TreeY
  Protected TreeW = 300
  Protected G_Tree = TreeGadget(#PB_Any, 24, TreeY, TreeW, TreeH)
  Protected G_Content = ScintillaGadget(#PB_Any, 24 + TreeW + 24, TreeY, WinW - TreeW - 72, TreeH, 0)
  BiosDocHelpGui_SetupStyles(G_Content)

  Protected G_Back = ThemedButton(24, ButtonY, 180, 32, "<- Voltar (Alt+Esquerda)", Chr(#Icon_ArrowLeft))
  GadgetToolTip(G_Back, "<- Voltar (Alt+Esquerda)")
  Protected G_Close = ThemedButton(WinW - 24 - 110, ButtonY, 110, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  BiosDocHelpGui_PopulateTree(G_Tree)
  AddKeyboardShortcut(Win, #PB_Shortcut_Alt | #PB_Shortcut_Left, #BiosDocHelpGui_ShortcutBack)

  NewList History.i()
  Protected CurrentRow.i = -1
  Protected BackIdx.i, TreeScanIdx.i

  Macro BiosDocHelpGui_DoGoBack
    If ListSize(History()) > 0
      LastElement(History())
      BackIdx = History()
      DeleteElement(History())
      If BackIdx >= 0
        BiosDocHelpGui_ShowRow(G_Content, BackIdx)
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
    BiosDocHelpGui_ShowRow(G_Content, 1)
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
                  BiosDocHelpGui_ShowRow(G_Content, RowIdx)
                  CurrentRow = RowIdx
                EndIf
              EndIf
            EndIf

          Case G_Search
            If EventType() = #PB_EventType_Change
              BiosDocHelpGui_FilterTree(G_Tree, GetGadgetText(G_Search))
              If Trim(GetGadgetText(G_Search)) <> ""
                SetGadgetText(G_Status, Str(CountGadgetItems(G_Tree)) + " resultado(s)")
              Else
                SetGadgetText(G_Status, "")
              EndIf
            EndIf

          Case G_ClearSearch
            SetGadgetText(G_Search, "")
            BiosDocHelpGui_FilterTree(G_Tree, "")
            SetGadgetText(G_Status, "")

          Case G_Back
            BiosDocHelpGui_DoGoBack

          Case G_Close
            Quit = #True

        EndSelect

      Case #PB_Event_Menu
        If EventMenu() = #BiosDocHelpGui_ShortcutBack
          BiosDocHelpGui_DoGoBack
        EndIf

      Case #PB_Event_CloseWindow
        Quit = #True

    EndSelect
  Until Quit

  BiosDocHelpGui_WinID = -1
  CloseModelessChildWindow(ParentWindow, Win, #False)
EndProcedure
