;
; ------------------------------------------------------------
;  Ajuda -> BIOS MSX: Hardware...: janela navegavel/pesquisavel com os
;  topicos de hardware extraidos de help/MSXBIOS.CHM (RuMSX, Lex Lechz -
;  lexlechz.at), secao "HARDWARE Topics" (Clockchip/PSG/SCC/MSX-Music/
;  MSX-Audio/MoonSound/V9958/V9990/Keyboard-Matrix/I-O ports/Kanji ROMs/
;  PCM/MIDI/SCSI/Lightpen/Tape I-O), base de dados em HardwareHelpData.pbi
;  (XIncludeFile'd antes deste arquivo).
;
;  33 topicos - a maioria uma pagina inteira por chip/periferico (nem todo
;  HTML original tinha o padrao "ENDERECO <B>NOME</B>" que dava pra dividir
;  automaticamente, ver comentario no topo de HardwareHelpData.pbi), mais
;  as paginas-filha dos hubs (V9990 -> comandos/futuro/portas/registradores,
;  V9958 -> comportamento/screen3/VRAM, Kanji ROM -> acesso/driver, I/O
;  ports -> portas comutadas/timer/PPI/etc.) dentro do mesmo grupo do hub.
;
;  Mesmo renderizador monoespacado/sem quebra automatica de
;  MsxManualsHelpGui.pbi (nao o "mini-Markdown" comum) - conteudo tecnico
;  cheio de diagramas de bits e tabelas Entry/Exit/Modifies alinhadas por
;  espaco, mesmo motivo daquele arquivo.
; ------------------------------------------------------------
;

#HardwareHelpGui_Row_Group = 1
#HardwareHelpGui_Row_Topic = 2

#HardwareHelpGui_Style_Title = 1
#HardwareHelpGui_Style_Body  = 2

#HardwareHelpGui_ShortcutBack = 6

Global HardwareHelpGui_WinID.i = -1

Structure HardwareHelpRow
  Kind.i
  RefIndex.i
  Label.s
  SearchKey.s
  SubLevel.i
EndStructure

Global NewList HardwareHelpGui_Rows.HardwareHelpRow()
Global HardwareHelpGui_RowsBuilt.b = #False

Procedure HardwareHelpGui_AddRow(Kind.i, RefIndex.i, Label.s, SearchKey.s, SubLevel.i)
  AddElement(HardwareHelpGui_Rows())
  HardwareHelpGui_Rows()\Kind = Kind
  HardwareHelpGui_Rows()\RefIndex = RefIndex
  HardwareHelpGui_Rows()\Label = Label
  HardwareHelpGui_Rows()\SearchKey = SearchKey
  HardwareHelpGui_Rows()\SubLevel = SubLevel
EndProcedure

Procedure HardwareHelpGui_BuildRows()
  If HardwareHelpGui_RowsBuilt
    ProcedureReturn
  EndIf
  HardwareHelpGui_RowsBuilt = #True

  HardwareHelp_BuildData()

  Protected Idx.i = -1, CurrentGrupo.s = ""
  ForEach HardwareHelp_Topics()
    Idx + 1
    If HardwareHelp_Topics()\Grupo <> CurrentGrupo
      CurrentGrupo = HardwareHelp_Topics()\Grupo
      HardwareHelpGui_AddRow(#HardwareHelpGui_Row_Group, -1, CurrentGrupo, "", 0)
    EndIf
    HardwareHelpGui_AddRow(#HardwareHelpGui_Row_Topic, Idx,
                             HardwareHelp_Topics()\Titulo,
                             LCase(HardwareHelp_Topics()\Titulo + " " + HardwareHelp_Topics()\Grupo), 1)
  Next
EndProcedure

Procedure HardwareHelpGui_PopulateTree(Tree)
  ClearGadgetItems(Tree)
  Protected RowIdx = -1
  ForEach HardwareHelpGui_Rows()
    RowIdx + 1
    AddGadgetItem(Tree, -1, HardwareHelpGui_Rows()\Label, 0, HardwareHelpGui_Rows()\SubLevel)
    SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, RowIdx)
  Next
EndProcedure

Procedure HardwareHelpGui_FilterTree(Tree, SearchText.s)
  Protected Needle.s = LCase(Trim(SearchText))
  If Needle = ""
    HardwareHelpGui_PopulateTree(Tree)
    ProcedureReturn
  EndIf

  ClearGadgetItems(Tree)
  Protected RowIdx = -1
  ForEach HardwareHelpGui_Rows()
    RowIdx + 1
    If HardwareHelpGui_Rows()\Kind <> #HardwareHelpGui_Row_Group And FindString(HardwareHelpGui_Rows()\SearchKey, Needle) > 0
      AddGadgetItem(Tree, -1, HardwareHelpGui_Rows()\Label, 0, 0)
      SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, RowIdx)
    EndIf
  Next
EndProcedure

Procedure HardwareHelpGui_SetupStyles(Sci)
  Protected *MonoFont = UTF8("Consolas")
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #STYLE_DEFAULT, RGB(30, 30, 30))
  ScintillaSendMessage(Sci, #SCI_STYLESETBACK, #STYLE_DEFAULT, RGB(255, 255, 255))
  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #STYLE_DEFAULT, *MonoFont)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #STYLE_DEFAULT, 10)
  ScintillaSendMessage(Sci, #SCI_STYLECLEARALL)

  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #HardwareHelpGui_Style_Title, *MonoFont)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #HardwareHelpGui_Style_Title, 12)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #HardwareHelpGui_Style_Title, RGB(20, 60, 120))
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #HardwareHelpGui_Style_Title, 1)

  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #HardwareHelpGui_Style_Body, *MonoFont)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #HardwareHelpGui_Style_Body, 10)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #HardwareHelpGui_Style_Body, RGB(30, 30, 30))
  FreeMemory(*MonoFont)

  ScintillaSendMessage(Sci, #SCI_SETCARETFORE, RGB(255, 255, 255))
  ScintillaSendMessage(Sci, #SCI_SETWRAPMODE, #SC_WRAP_NONE)
  ScintillaSendMessage(Sci, #SCI_SETSCROLLWIDTHTRACKING, 1)
EndProcedure

Procedure HardwareHelpGui_EmitRun(Sci, Text.s, Style)
  Protected ByteLen = StringByteLength(Text, #PB_UTF8)
  If ByteLen > 0
    ScintillaSendMessage(Sci, #SCI_SETSTYLING, ByteLen, Style)
  EndIf
EndProcedure

Procedure HardwareHelpGui_RenderTopic(Sci, Titulo.s, Corpo.s)
  Protected TitleLine.s = Titulo + #CRLF$ + #CRLF$
  Protected FullText.s = TitleLine + Corpo
  Protected *Buffer = UTF8(FullText)
  ScintillaSendMessage(Sci, #SCI_SETREADONLY, 0)
  ScintillaSendMessage(Sci, #SCI_SETTEXT, 0, *Buffer)
  FreeMemory(*Buffer)

  ScintillaSendMessage(Sci, #SCI_STARTSTYLING, 0, 0)
  HardwareHelpGui_EmitRun(Sci, TitleLine, #HardwareHelpGui_Style_Title)
  HardwareHelpGui_EmitRun(Sci, Corpo, #HardwareHelpGui_Style_Body)

  ScintillaSendMessage(Sci, #SCI_SETREADONLY, 1)
  ScintillaSendMessage(Sci, #SCI_EMPTYUNDOBUFFER)
  ScintillaSendMessage(Sci, #SCI_GOTOPOS, 0)
EndProcedure

Procedure HardwareHelpGui_ShowRow(Sci, RowIdx.i)
  If Not SelectElement(HardwareHelpGui_Rows(), RowIdx)
    ProcedureReturn
  EndIf
  Select HardwareHelpGui_Rows()\Kind
    Case #HardwareHelpGui_Row_Group
      HardwareHelpGui_RenderTopic(Sci, HardwareHelpGui_Rows()\Label, "Selecione um topico de hardware na lista ao lado.")
    Case #HardwareHelpGui_Row_Topic
      If SelectElement(HardwareHelp_Topics(), HardwareHelpGui_Rows()\RefIndex)
        HardwareHelpGui_RenderTopic(Sci, HardwareHelp_Topics()\Titulo, HardwareHelp_Topics()\Corpo)
      EndIf
  EndSelect
EndProcedure

Procedure HardwareHelp_OpenWindow(ParentWindow)
  If HardwareHelpGui_WinID <> -1 And IsWindow(HardwareHelpGui_WinID)
    SetActiveWindow(HardwareHelpGui_WinID)
    ProcedureReturn
  EndIf

  HardwareHelpGui_BuildRows()

  Protected WinW = 980, WinH = 640
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Ajuda - BIOS MSX: Hardware",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #False)
  If Not Win
    ProcedureReturn
  EndIf
  HardwareHelpGui_WinID = Win

  Protected TopY = 24
  TextGadget(#PB_Any, 24, TopY + 4, 55, 20, "Buscar:")
  Protected G_Search = StringGadget(#PB_Any, 87, TopY, 300, 24, "")
  GadgetToolTip(G_Search, "Filtra por nome do topico de hardware ou grupo")
  Protected G_ClearSearch = ThemedButton(399, TopY, 80, 24, "Limpar", Chr(#Icon_Clear))
  GadgetToolTip(G_ClearSearch, "Limpar")
  Protected G_Status = TextGadget(#PB_Any, 495, TopY + 4, WinW - 519, 20, "")

  Protected ButtonY = WinH - 56
  Protected TreeY = TopY + 24 + 16
  Protected TreeH = ButtonY - 16 - TreeY
  Protected TreeW = 300
  Protected G_Tree = TreeGadget(#PB_Any, 24, TreeY, TreeW, TreeH)
  Protected G_Content = ScintillaGadget(#PB_Any, 24 + TreeW + 24, TreeY, WinW - TreeW - 72, TreeH, 0)
  HardwareHelpGui_SetupStyles(G_Content)

  Protected G_Back = ThemedButton(24, ButtonY, 180, 32, "<- Voltar (Alt+Esquerda)", Chr(#Icon_ArrowLeft))
  GadgetToolTip(G_Back, "<- Voltar (Alt+Esquerda)")
  Protected G_Close = ThemedButton(WinW - 24 - 110, ButtonY, 110, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  HardwareHelpGui_PopulateTree(G_Tree)
  AddKeyboardShortcut(Win, #PB_Shortcut_Alt | #PB_Shortcut_Left, #HardwareHelpGui_ShortcutBack)

  NewList History.i()
  Protected CurrentRow.i = -1
  Protected BackIdx.i, TreeScanIdx.i

  Macro HardwareHelpGui_DoGoBack
    If ListSize(History()) > 0
      LastElement(History())
      BackIdx = History()
      DeleteElement(History())
      If BackIdx >= 0
        HardwareHelpGui_ShowRow(G_Content, BackIdx)
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
    HardwareHelpGui_ShowRow(G_Content, 1)
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
                  HardwareHelpGui_ShowRow(G_Content, RowIdx)
                  CurrentRow = RowIdx
                EndIf
              EndIf
            EndIf

          Case G_Search
            If EventType() = #PB_EventType_Change
              HardwareHelpGui_FilterTree(G_Tree, GetGadgetText(G_Search))
              If Trim(GetGadgetText(G_Search)) <> ""
                SetGadgetText(G_Status, Str(CountGadgetItems(G_Tree)) + " resultado(s)")
              Else
                SetGadgetText(G_Status, "")
              EndIf
            EndIf

          Case G_ClearSearch
            SetGadgetText(G_Search, "")
            HardwareHelpGui_FilterTree(G_Tree, "")
            SetGadgetText(G_Status, "")

          Case G_Back
            HardwareHelpGui_DoGoBack

          Case G_Close
            Quit = #True

        EndSelect

      Case #PB_Event_Menu
        If EventMenu() = #HardwareHelpGui_ShortcutBack
          HardwareHelpGui_DoGoBack
        EndIf

      Case #PB_Event_CloseWindow
        Quit = #True

    EndSelect
  Until Quit

  HardwareHelpGui_WinID = -1
  CloseModelessChildWindow(ParentWindow, Win, #False)
EndProcedure
