;
; ------------------------------------------------------------
;  Ajuda -> Manuais MSX...: janela navegavel/pesquisavel com os documentos
;  tecnicos originais extraidos de help/MANUALS.CHM (RuMSX, Lex Lechz -
;  lexlechz.at), base de dados em MsxManualsHelpData.pbi (XIncludeFile'd
;  antes deste arquivo).
;
;  Mesmo layout/navegacao (busca/historico/arvore) das outras janelas de
;  Ajuda (MsxBasicHelpGui.pbi/NestorBasicHelpGui.pbi/etc.), MAS o painel de
;  conteudo NAO usa o "mini-Markdown" comum (NBHelpGui_RenderMarkdown) -
;  esses documentos sao manuais tecnicos antigos inteiros em texto
;  monoespacado pre-formatado (tabelas/diagramas em ASCII art, alinhados por
;  espaco), reproduzidos como no original: reformatar em prosa com quebra de
;  linha automatica destruiria o alinhamento. Por isso ManualsHelpGui_
;  SetupStyles() usa uma unica fonte monoespacada, #SC_WRAP_NONE (sem
;  quebra automatica, rolagem horizontal) em vez do #SC_WRAP_WORD que as
;  outras janelas de Ajuda usam para prosa.
; ------------------------------------------------------------
;

#ManualsHelpGui_Row_Group = 1
#ManualsHelpGui_Row_Topic = 2

#ManualsHelpGui_Style_Title = 1
#ManualsHelpGui_Style_Body  = 2

#ManualsHelpGui_ShortcutBack = 3

Global ManualsHelpGui_WinID.i = -1

Structure ManualsHelpRow
  Kind.i        ; #ManualsHelpGui_Row_*
  RefIndex.i    ; indice em ManualsHelp_Topics() (Kind=Topic); -1 em grupos
  Label.s
  SearchKey.s   ; minusculo, vazio para linhas de grupo (nunca batem em busca)
  SubLevel.i    ; 0 (grupo) ou 1 (topico), repassado direto pro AddGadgetItem()
EndStructure

Global NewList ManualsHelpGui_Rows.ManualsHelpRow()
Global ManualsHelpGui_RowsBuilt.b = #False

Procedure ManualsHelpGui_AddRow(Kind.i, RefIndex.i, Label.s, SearchKey.s, SubLevel.i)
  AddElement(ManualsHelpGui_Rows())
  ManualsHelpGui_Rows()\Kind = Kind
  ManualsHelpGui_Rows()\RefIndex = RefIndex
  ManualsHelpGui_Rows()\Label = Label
  ManualsHelpGui_Rows()\SearchKey = SearchKey
  ManualsHelpGui_Rows()\SubLevel = SubLevel
EndProcedure

; Lista achatada de grupos+topicos, montada uma vez, na mesma ordem em que
; os topicos foram adicionados em ManualsHelp_BuildData() (MsxManualsHelpData.pbi)
; - um novo grupo comeca sempre que o campo Grupo muda.
Procedure ManualsHelpGui_BuildRows()
  If ManualsHelpGui_RowsBuilt
    ProcedureReturn
  EndIf
  ManualsHelpGui_RowsBuilt = #True

  ManualsHelp_BuildData()

  Protected Idx.i = -1, CurrentGrupo.s = ""
  ForEach ManualsHelp_Topics()
    Idx + 1
    If ManualsHelp_Topics()\Grupo <> CurrentGrupo
      CurrentGrupo = ManualsHelp_Topics()\Grupo
      ManualsHelpGui_AddRow(#ManualsHelpGui_Row_Group, -1, CurrentGrupo, "", 0)
    EndIf
    ManualsHelpGui_AddRow(#ManualsHelpGui_Row_Topic, Idx,
                           ManualsHelp_Topics()\Titulo,
                           LCase(ManualsHelp_Topics()\Titulo + " " + ManualsHelp_Topics()\Grupo), 1)
  Next
EndProcedure

Procedure ManualsHelpGui_PopulateTree(Tree)
  ClearGadgetItems(Tree)
  Protected RowIdx = -1
  ForEach ManualsHelpGui_Rows()
    RowIdx + 1
    AddGadgetItem(Tree, -1, ManualsHelpGui_Rows()\Label, 0, ManualsHelpGui_Rows()\SubLevel)
    SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, RowIdx)
  Next
EndProcedure

Procedure ManualsHelpGui_FilterTree(Tree, SearchText.s)
  Protected Needle.s = LCase(Trim(SearchText))
  If Needle = ""
    ManualsHelpGui_PopulateTree(Tree)
    ProcedureReturn
  EndIf

  ClearGadgetItems(Tree)
  Protected RowIdx = -1
  ForEach ManualsHelpGui_Rows()
    RowIdx + 1
    If ManualsHelpGui_Rows()\Kind <> #ManualsHelpGui_Row_Group And FindString(ManualsHelpGui_Rows()\SearchKey, Needle) > 0
      AddGadgetItem(Tree, -1, ManualsHelpGui_Rows()\Label, 0, 0)
      SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, RowIdx)
    EndIf
  Next
EndProcedure

; Fonte unica monoespacada + sem quebra automatica (ver comentario no topo
; do arquivo) - Style_Title so muda cor/negrito, continua na mesma fonte
; monoespacada (documento pode ter arte ASCII logo depois do titulo).
Procedure ManualsHelpGui_SetupStyles(Sci)
  Protected *MonoFont = UTF8("Consolas")
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #STYLE_DEFAULT, RGB(30, 30, 30))
  ScintillaSendMessage(Sci, #SCI_STYLESETBACK, #STYLE_DEFAULT, RGB(255, 255, 255))
  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #STYLE_DEFAULT, *MonoFont)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #STYLE_DEFAULT, 10)
  ScintillaSendMessage(Sci, #SCI_STYLECLEARALL)

  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #ManualsHelpGui_Style_Title, *MonoFont)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #ManualsHelpGui_Style_Title, 12)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #ManualsHelpGui_Style_Title, RGB(20, 60, 120))
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #ManualsHelpGui_Style_Title, 1)

  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #ManualsHelpGui_Style_Body, *MonoFont)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #ManualsHelpGui_Style_Body, 10)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #ManualsHelpGui_Style_Body, RGB(30, 30, 30))
  FreeMemory(*MonoFont)

  ScintillaSendMessage(Sci, #SCI_SETCARETFORE, RGB(255, 255, 255)) ; esconde o caret (so leitura)
  ScintillaSendMessage(Sci, #SCI_SETWRAPMODE, #SC_WRAP_NONE)       ; preserva alinhamento das tabelas ASCII
  ScintillaSendMessage(Sci, #SCI_SETSCROLLWIDTHTRACKING, 1)
EndProcedure

Procedure ManualsHelpGui_EmitRun(Sci, Text.s, Style)
  Protected ByteLen = StringByteLength(Text, #PB_UTF8)
  If ByteLen > 0
    ScintillaSendMessage(Sci, #SCI_SETSTYLING, ByteLen, Style)
  EndIf
EndProcedure

; Sem parser nenhum: titulo (Style_Title) + linha em branco + corpo tal como
; extraido do CHM original (Style_Body), byte a byte - nada de negrito/
; codigo inline (o "mini-Markdown" das outras janelas nao se aplica aqui,
; ver comentario no topo do arquivo).
Procedure ManualsHelpGui_RenderTopic(Sci, Titulo.s, Corpo.s)
  Protected TitleLine.s = Titulo + #CRLF$ + #CRLF$
  Protected FullText.s = TitleLine + Corpo
  Protected *Buffer = UTF8(FullText)
  ScintillaSendMessage(Sci, #SCI_SETREADONLY, 0)
  ScintillaSendMessage(Sci, #SCI_SETTEXT, 0, *Buffer)
  FreeMemory(*Buffer)

  ScintillaSendMessage(Sci, #SCI_STARTSTYLING, 0, 0)
  ManualsHelpGui_EmitRun(Sci, TitleLine, #ManualsHelpGui_Style_Title)
  ManualsHelpGui_EmitRun(Sci, Corpo, #ManualsHelpGui_Style_Body)

  ScintillaSendMessage(Sci, #SCI_SETREADONLY, 1)
  ScintillaSendMessage(Sci, #SCI_EMPTYUNDOBUFFER)
  ScintillaSendMessage(Sci, #SCI_GOTOPOS, 0)
EndProcedure

Procedure ManualsHelpGui_ShowRow(Sci, RowIdx.i)
  If Not SelectElement(ManualsHelpGui_Rows(), RowIdx)
    ProcedureReturn
  EndIf
  Select ManualsHelpGui_Rows()\Kind
    Case #ManualsHelpGui_Row_Group
      ManualsHelpGui_RenderTopic(Sci, ManualsHelpGui_Rows()\Label, "Selecione um documento na lista ao lado.")
    Case #ManualsHelpGui_Row_Topic
      If SelectElement(ManualsHelp_Topics(), ManualsHelpGui_Rows()\RefIndex)
        ManualsHelpGui_RenderTopic(Sci, ManualsHelp_Topics()\Titulo, ManualsHelp_Topics()\Corpo)
      EndIf
  EndSelect
EndProcedure

Procedure MsxManualsHelp_OpenWindow(ParentWindow)
  If ManualsHelpGui_WinID <> -1 And IsWindow(ManualsHelpGui_WinID)
    SetActiveWindow(ManualsHelpGui_WinID)
    ProcedureReturn
  EndIf

  ManualsHelpGui_BuildRows()

  Protected WinW = 980, WinH = 640
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Ajuda - Manuais MSX",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #False)
  If Not Win
    ProcedureReturn
  EndIf
  ManualsHelpGui_WinID = Win

  Protected TopY = 24
  TextGadget(#PB_Any, 24, TopY + 4, 55, 20, "Buscar:")
  Protected G_Search = StringGadget(#PB_Any, 87, TopY, 300, 24, "")
  GadgetToolTip(G_Search, "Filtra por nome do documento ou grupo")
  Protected G_ClearSearch = ThemedButton(399, TopY, 80, 24, "Limpar", Chr(#Icon_Clear))
  GadgetToolTip(G_ClearSearch, "Limpar")
  Protected G_Status = TextGadget(#PB_Any, 495, TopY + 4, WinW - 519, 20, "")

  Protected ButtonY = WinH - 56
  Protected TreeY = TopY + 24 + 16
  Protected TreeH = ButtonY - 16 - TreeY
  Protected TreeW = 300
  Protected G_Tree = TreeGadget(#PB_Any, 24, TreeY, TreeW, TreeH)
  Protected G_Content = ScintillaGadget(#PB_Any, 24 + TreeW + 24, TreeY, WinW - TreeW - 72, TreeH, 0)
  ManualsHelpGui_SetupStyles(G_Content)

  Protected G_Back = ThemedButton(24, ButtonY, 180, 32, "<- Voltar (Alt+Esquerda)", Chr(#Icon_ArrowLeft))
  GadgetToolTip(G_Back, "<- Voltar (Alt+Esquerda)")
  Protected G_Close = ThemedButton(WinW - 24 - 110, ButtonY, 110, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  ManualsHelpGui_PopulateTree(G_Tree)
  AddKeyboardShortcut(Win, #PB_Shortcut_Alt | #PB_Shortcut_Left, #ManualsHelpGui_ShortcutBack)

  NewList History.i()
  Protected CurrentRow.i = -1
  Protected BackIdx.i, TreeScanIdx.i

  ; Macro (nao Procedure) de proposito - mesmo motivo de MSXHelpGui_DoGoBack
  ; (MsxBasicHelpGui.pbi): precisa enxergar direto as variaveis locais desta
  ; janela (G_Tree, G_Content, History(), CurrentRow).
  Macro ManualsHelpGui_DoGoBack
    If ListSize(History()) > 0
      LastElement(History())
      BackIdx = History()
      DeleteElement(History())
      If BackIdx >= 0
        ManualsHelpGui_ShowRow(G_Content, BackIdx)
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

  ; Linha 0 e sempre um cabecalho de grupo (MSX-DOS 2); a primeira linha de
  ; conteudo de verdade fica na linha 1.
  If CountGadgetItems(G_Tree) > 1
    ManualsHelpGui_ShowRow(G_Content, 1)
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
                  ManualsHelpGui_ShowRow(G_Content, RowIdx)
                  CurrentRow = RowIdx
                EndIf
              EndIf
            EndIf

          Case G_Search
            If EventType() = #PB_EventType_Change
              ManualsHelpGui_FilterTree(G_Tree, GetGadgetText(G_Search))
              If Trim(GetGadgetText(G_Search)) <> ""
                SetGadgetText(G_Status, Str(CountGadgetItems(G_Tree)) + " resultado(s)")
              Else
                SetGadgetText(G_Status, "")
              EndIf
            EndIf

          Case G_ClearSearch
            SetGadgetText(G_Search, "")
            ManualsHelpGui_FilterTree(G_Tree, "")
            SetGadgetText(G_Status, "")

          Case G_Back
            ManualsHelpGui_DoGoBack

          Case G_Close
            Quit = #True

        EndSelect

      Case #PB_Event_Menu
        If EventMenu() = #ManualsHelpGui_ShortcutBack
          ManualsHelpGui_DoGoBack
        EndIf

      Case #PB_Event_CloseWindow
        Quit = #True

    EndSelect
  Until Quit

  ManualsHelpGui_WinID = -1
  CloseModelessChildWindow(ParentWindow, Win, #False)
EndProcedure
