;
; ------------------------------------------------------------
;  Ajuda -> MSX BASIC...: janela navegavel/pesquisavel unindo as duas
;  bases de dados montadas a partir do livro "Linguagem BASIC MSX"
;  (Denise Santoro Cruz, Editora Aleph/Gradiente, 1986):
;  - MsxBasicManualData.pbi: topicos de prosa/tabelas (Parte I, Parte III,
;    Apendices).
;  - MsxBasicDictData.pbi: as 140 palavras reservadas (Parte II).
;  Mais uma pagina especial "Cores do MSX" com as 16 cores do VDP
;  renderizadas como faixas coloridas (aproximacao dos lapis da
;  contracapa do livro).
;
;  Reaproveita a infraestrutura de renderizacao ja existente em
;  NestorBasicHelpGui.pbi (XIncludeFile'd antes deste arquivo, mesma
;  unidade de compilacao): NBHelpGui_SetupStyles/_RenderMarkdown/_EmitRun
;  entendem "## " (subtitulo), "**negrito**" e "`codigo`" inline - a
;  mesma marcacao usada aqui. So a pagina de cores usa um renderizador
;  proprio (MSXHelpGui_RenderColors), porque precisa de uma cor de fundo
;  por linha, algo que o mini-Markdown generico nao faz.
;
;  Layout e navegacao (busca/historico/arvore) identicos a Ajuda ->
;  Nestor Basic, por consistencia - so a fonte dos topicos muda: aqui a
;  arvore junta duas listas heterogeneas (MSXManual_Topics() e
;  MSXDict_Keywords()) mais a pagina de cores numa unica lista "achatada"
;  de linhas (MSXHelpGui_Rows()), montada uma vez, guardando o tipo de
;  cada linha (grupo / topico do manual / palavra do dicionario / pagina
;  de cores) e o indice de volta pra lista de origem.
; ------------------------------------------------------------
;

#MSXHelpGui_Row_Group  = 1
#MSXHelpGui_Row_Manual = 2
#MSXHelpGui_Row_Dict   = 3
#MSXHelpGui_Row_Colors = 4

#MSXHelpGui_ShortcutBack = 2

Global MSXHelpGui_WinID.i = -1
Global MSXHelpGui_RowsBuilt.b = #False

Structure MSXHelpRow
  Kind.i        ; #MSXHelpGui_Row_*
  RefIndex.i    ; indice em MSXManual_Topics() (Kind=Manual) ou MSXDict_Keywords() (Kind=Dict); -1 nos demais
  Label.s
  SearchKey.s   ; minusculo, vazio para linhas de grupo (nunca batem em busca)
  SubLevel.i    ; 0 ou 1, repassado direto pro AddGadgetItem()
EndStructure

Global NewList MSXHelpGui_Rows.MSXHelpRow()

Procedure MSXHelpGui_AddRow(Kind.i, RefIndex.i, Label.s, SearchKey.s, SubLevel.i)
  AddElement(MSXHelpGui_Rows())
  MSXHelpGui_Rows()\Kind = Kind
  MSXHelpGui_Rows()\RefIndex = RefIndex
  MSXHelpGui_Rows()\Label = Label
  MSXHelpGui_Rows()\SearchKey = SearchKey
  MSXHelpGui_Rows()\SubLevel = SubLevel
EndProcedure

; Monta a lista achatada uma unica vez por sessao: grupos de
; MSXManual_Topics() (na ordem em que o campo Parte muda), depois o
; dicionario inteiro (Parte II) num grupo so, depois a pagina de cores.
Procedure MSXHelpGui_BuildRows()
  If MSXHelpGui_RowsBuilt
    ProcedureReturn
  EndIf
  MSXHelpGui_RowsBuilt = #True

  MSXManual_BuildData()
  MSXDict_BuildData()

  Protected Idx.i, CurrentParte.s = ""

  ForEach MSXManual_Topics()
    Idx + 1
    If MSXManual_Topics()\Parte <> CurrentParte
      CurrentParte = MSXManual_Topics()\Parte
      MSXHelpGui_AddRow(#MSXHelpGui_Row_Group, -1, CurrentParte, "", 0)
    EndIf
    MSXHelpGui_AddRow(#MSXHelpGui_Row_Manual, Idx - 1,
                       MSXManual_Topics()\Titulo,
                       LCase(MSXManual_Topics()\Titulo + " " + MSXManual_Topics()\Parte), 1)
  Next

  MSXHelpGui_AddRow(#MSXHelpGui_Row_Group, -1, "Parte II - Dicionario das Palavras Reservadas", "", 0)
  Idx = 0
  ForEach MSXDict_Keywords()
    MSXHelpGui_AddRow(#MSXHelpGui_Row_Dict, Idx,
                       MSXDict_Keywords()\Titulo,
                       LCase(MSXDict_Keywords()\Titulo + " " + MSXDict_Keywords()\Origem), 1)
    Idx + 1
  Next

  MSXHelpGui_AddRow(#MSXHelpGui_Row_Colors, -1, "Cores do MSX",
                     "cores do msx cor color paleta lapis", 0)
EndProcedure

Procedure MSXHelpGui_PopulateTree(Tree)
  ClearGadgetItems(Tree)
  Protected RowIdx = -1
  ForEach MSXHelpGui_Rows()
    RowIdx + 1
    AddGadgetItem(Tree, -1, MSXHelpGui_Rows()\Label, 0, MSXHelpGui_Rows()\SubLevel)
    SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, RowIdx)
  Next
EndProcedure

Procedure MSXHelpGui_FilterTree(Tree, SearchText.s)
  Protected Needle.s = LCase(Trim(SearchText))
  If Needle = ""
    MSXHelpGui_PopulateTree(Tree)
    ProcedureReturn
  EndIf

  ClearGadgetItems(Tree)
  Protected RowIdx = -1
  ForEach MSXHelpGui_Rows()
    RowIdx + 1
    If MSXHelpGui_Rows()\Kind <> #MSXHelpGui_Row_Group And FindString(MSXHelpGui_Rows()\SearchKey, Needle) > 0
      AddGadgetItem(Tree, -1, MSXHelpGui_Rows()\Label, 0, 0)
      SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, RowIdx)
    EndIf
  Next
EndProcedure

Procedure.s MSXHelpGui_ManualFullBody(RefIndex.i)
  If Not SelectElement(MSXManual_Topics(), RefIndex)
    ProcedureReturn ""
  EndIf
  ProcedureReturn "## " + MSXManual_Topics()\Titulo + #CRLF$ + #CRLF$ +
                  MSXManual_Topics()\Parte + " - pagina " + Str(MSXManual_Topics()\PaginaLivro) + " do livro" + #CRLF$ + #CRLF$ +
                  MSXManual_Topics()\Corpo
EndProcedure

Procedure.s MSXHelpGui_DictFullBody(RefIndex.i)
  If Not SelectElement(MSXDict_Keywords(), RefIndex)
    ProcedureReturn ""
  EndIf
  Protected Tag.s = ""
  If MSXDict_Keywords()\EhFuncao : Tag = "  (F)" : EndIf
  If MSXDict_Keywords()\Avancado : Tag = Tag + "  *" : EndIf

  Protected Body.s = "## " + MSXDict_Keywords()\Titulo + Tag + #CRLF$ + #CRLF$
  Body + MSXDict_Keywords()\Origem + #CRLF$ + #CRLF$
  Body + MSXDict_Keywords()\Resumo + #CRLF$ + #CRLF$
  Body + "**FORMATO:**" + #CRLF$ + MSXDict_Keywords()\Formato + #CRLF$ + #CRLF$
  Body + "**EXEMPLO:**" + #CRLF$ + MSXDict_Keywords()\ExemploFormato + #CRLF$ + #CRLF$
  Body + "**FUNCAO:**" + #CRLF$ + MSXDict_Keywords()\Funcao
  If MSXDict_Keywords()\ProgramaExemplo <> ""
    Body + #CRLF$ + #CRLF$ + "**PROGRAMA EXEMPLO:**" + #CRLF$ + MSXDict_Keywords()\ProgramaExemplo
  EndIf
  Body + #CRLF$ + #CRLF$ + "(pagina " + Str(MSXDict_Keywords()\PaginaLivro) + " do livro)"
  ProcedureReturn Body
EndProcedure

; Um estilo Scintilla por cor (10 a 25, faixa livre - o mini-Markdown
; generico so usa 0-3), fundo = aproximacao RGB da cor, texto preto ou
; branco conforme a luminancia, pra ficar legivel em cima de qualquer
; das 16 cores (mesma ideia dos lapis coloridos da contracapa do livro).
Procedure MSXHelpGui_SetupColorStyles(Sci)
  Protected R, G, B, Style, Luma.f
  ForEach MSXManual_Colors()
    Style = 10 + MSXManual_Colors()\Numero
    R = Val("$" + Mid(MSXManual_Colors()\CorHex, 1, 2))
    G = Val("$" + Mid(MSXManual_Colors()\CorHex, 3, 2))
    B = Val("$" + Mid(MSXManual_Colors()\CorHex, 5, 2))
    ScintillaSendMessage(Sci, #SCI_STYLESETBACK, Style, RGB(R, G, B))
    ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, Style, 1)
    Luma = 0.299 * R + 0.587 * G + 0.114 * B
    If Luma > 140
      ScintillaSendMessage(Sci, #SCI_STYLESETFORE, Style, RGB(0, 0, 0))
    Else
      ScintillaSendMessage(Sci, #SCI_STYLESETFORE, Style, RGB(255, 255, 255))
    EndIf
  Next
EndProcedure

; Renderizador proprio (nao usa NBHelpGui_RenderMarkdown): cada linha de
; cor usa seu proprio estilo com fundo colorido, montado com a mesma
; tecnica de "texto puro + lista paralela de estilos" do mini-Markdown.
Procedure MSXHelpGui_RenderColors(Sci)
  NewList RunStyle.i()
  NewList RunText.s()
  Protected PlainText.s = ""

  Protected Titulo.s = "CORES DO MSX (0 a 15)" + #CRLF$ + #CRLF$
  AddElement(RunStyle()) : RunStyle() = #NBHelpGui_Style_H2
  AddElement(RunText())  : RunText()  = Titulo
  PlainText + Titulo

  Protected Intro.s = "Paleta fixa de 16 cores do VDP (TMS9918), nomes tirados da contracapa do " +
                      "livro (" + Chr(34) + "AS CORES DO EXPERT" + Chr(34) + "). A cor de fundo de " +
                      "cada linha abaixo e uma aproximacao RGB - o video original e analogico " +
                      "(NTSC), entao a cor exata na TV pode variar um pouco." + #CRLF$ + #CRLF$
  AddElement(RunStyle()) : RunStyle() = #NBHelpGui_Style_Default
  AddElement(RunText())  : RunText()  = Intro
  PlainText + Intro

  Protected Linha.s, Style
  ForEach MSXManual_Colors()
    Linha = " " + RSet(Str(MSXManual_Colors()\Numero), 2) + "  " +
            LSet(MSXManual_Colors()\Nome, 20) + " (aprox. #" + MSXManual_Colors()\CorHex + ") " + #CRLF$
    Style = 10 + MSXManual_Colors()\Numero
    AddElement(RunStyle()) : RunStyle() = Style
    AddElement(RunText())  : RunText()  = Linha
    PlainText + Linha
  Next

  Protected *Buffer = UTF8(PlainText)
  ScintillaSendMessage(Sci, #SCI_SETREADONLY, 0)
  ScintillaSendMessage(Sci, #SCI_SETTEXT, 0, *Buffer)
  FreeMemory(*Buffer)

  ScintillaSendMessage(Sci, #SCI_STARTSTYLING, 0, 0)
  ResetList(RunStyle()) : ResetList(RunText())
  While NextElement(RunStyle()) And NextElement(RunText())
    NBHelpGui_EmitRun(Sci, RunText(), RunStyle())
  Wend

  ScintillaSendMessage(Sci, #SCI_SETREADONLY, 1)
  ScintillaSendMessage(Sci, #SCI_EMPTYUNDOBUFFER)
  ScintillaSendMessage(Sci, #SCI_GOTOPOS, 0)
EndProcedure

Procedure MSXHelpGui_ShowRow(Sci, RowIdx.i)
  If Not SelectElement(MSXHelpGui_Rows(), RowIdx)
    ProcedureReturn
  EndIf
  Select MSXHelpGui_Rows()\Kind
    Case #MSXHelpGui_Row_Group
      NBHelpGui_RenderMarkdown(Sci, "## " + MSXHelpGui_Rows()\Label + #CRLF$ + #CRLF$ +
                                     "Selecione um topico na lista ao lado.")
    Case #MSXHelpGui_Row_Manual
      NBHelpGui_RenderMarkdown(Sci, MSXHelpGui_ManualFullBody(MSXHelpGui_Rows()\RefIndex))
    Case #MSXHelpGui_Row_Dict
      NBHelpGui_RenderMarkdown(Sci, MSXHelpGui_DictFullBody(MSXHelpGui_Rows()\RefIndex))
    Case #MSXHelpGui_Row_Colors
      MSXHelpGui_RenderColors(Sci)
  EndSelect
EndProcedure

Procedure MsxBasicHelp_OpenWindow(ParentWindow)
  If MSXHelpGui_WinID <> -1 And IsWindow(MSXHelpGui_WinID)
    SetActiveWindow(MSXHelpGui_WinID)
    ProcedureReturn
  EndIf

  MSXHelpGui_BuildRows()

  Protected WinW = 940, WinH = 620
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Ajuda - MSX BASIC",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #False)
  If Not Win
    ProcedureReturn
  EndIf
  MSXHelpGui_WinID = Win

  Protected TopY = 24
  TextGadget(#PB_Any, 24, TopY + 4, 55, 20, "Buscar:")
  Protected G_Search = StringGadget(#PB_Any, 87, TopY, 300, 24, "")
  GadgetToolTip(G_Search, "Filtra por nome ou expressao de origem em ingles")
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
  MSXHelpGui_SetupColorStyles(G_Content)

  Protected G_Back = ThemedButton(24, ButtonY, 180, 32, "<- Voltar (Alt+Esquerda)", Chr(#Icon_ArrowLeft))
  GadgetToolTip(G_Back, "<- Voltar (Alt+Esquerda)")
  Protected G_Close = ThemedButton(WinW - 24 - 110, ButtonY, 110, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  MSXHelpGui_PopulateTree(G_Tree)
  AddKeyboardShortcut(Win, #PB_Shortcut_Alt | #PB_Shortcut_Left, #MSXHelpGui_ShortcutBack)

  NewList History.i()
  Protected CurrentRow.i = -1
  Protected BackIdx.i, TreeScanIdx.i

  ; Macro (nao Procedure) de proposito, mesma razao do arquivo espelhado
  ; (NestorBasicHelpGui.pbi): precisa enxergar direto as variaveis locais
  ; desta janela (G_Tree, G_Content, History(), CurrentRow).
  Macro MSXHelpGui_DoGoBack
    If ListSize(History()) > 0
      LastElement(History())
      BackIdx = History()
      DeleteElement(History())
      If BackIdx >= 0
        MSXHelpGui_ShowRow(G_Content, BackIdx)
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

  ; Linha 0 e sempre um cabecalho de grupo (Parte I); a primeira linha de
  ; conteudo de verdade fica na linha 1 ("Modos de Operacao").
  If CountGadgetItems(G_Tree) > 1
    MSXHelpGui_ShowRow(G_Content, 1)
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
                  MSXHelpGui_ShowRow(G_Content, RowIdx)
                  CurrentRow = RowIdx
                EndIf
              EndIf
            EndIf

          Case G_Search
            If EventType() = #PB_EventType_Change
              MSXHelpGui_FilterTree(G_Tree, GetGadgetText(G_Search))
              If Trim(GetGadgetText(G_Search)) <> ""
                SetGadgetText(G_Status, Str(CountGadgetItems(G_Tree)) + " resultado(s)")
              Else
                SetGadgetText(G_Status, "")
              EndIf
            EndIf

          Case G_ClearSearch
            SetGadgetText(G_Search, "")
            MSXHelpGui_FilterTree(G_Tree, "")
            SetGadgetText(G_Status, "")

          Case G_Back
            MSXHelpGui_DoGoBack

          Case G_Close
            Quit = #True

        EndSelect

      Case #PB_Event_Menu
        If EventMenu() = #MSXHelpGui_ShortcutBack
          MSXHelpGui_DoGoBack
        EndIf

      Case #PB_Event_CloseWindow
        Quit = #True

    EndSelect
  Until Quit

  MSXHelpGui_WinID = -1
  CloseModelessChildWindow(ParentWindow, Win, #False)
EndProcedure
