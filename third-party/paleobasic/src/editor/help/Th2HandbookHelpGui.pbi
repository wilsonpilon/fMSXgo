;
; ------------------------------------------------------------
;  Ajuda -> MSX2 Technical Handbook...: janela navegavel/pesquisavel com o
;  MSX2 Technical Handbook (ASCII Corporation, 1987), a partir da edicao
;  Markdown mantida por Konamiman/Nestor Soriano (ja creditado no README
;  pelo Nestor80) - github.com/Konamiman/MSX2-Technical-Handbook - base de
;  dados em Th2HandbookHelpData.pbi (XIncludeFile'd antes deste arquivo).
;
;  Irmã de RedBookHelpGui.pbi (codigo praticamente identico, so os nomes
;  trocados) - mesma necessidade de links clicaveis de verdade (aqui os
;  anchors sao qualificados por arquivo, "Chapter1#slug-github", porque
;  cada capitulo era uma pagina .md separada no original e os links so
;  existem dentro do mesmo arquivo, nunca entre capitulos - ver comentario
;  em convert_th2handbook.py). 1356 topicos em 15 grupos (7 capitulos + 6
;  apendices + apendices 8/10 combinados + o manual do compilador BASIC-KUN
;  de brinde), particionados automaticamente por heading Markdown real
;  (## a ######) em vez do marcador ad-hoc "ENDERECO <B>NOME</B>" que
;  BiosCallsHelpData.pbi precisou (esta edicao ja e' Markdown de verdade,
;  nao HTML reconstruido de CHM).
;
;  TAMBEM tem figuras de verdade (84 PNGs baixados de pics/ no repositorio,
;  editor/th2handbook_images/) - mesmo mecanismo de popup clicavel
;  ("[[["+"[Ver Figura: X]"+"|||"+"img:x"+"]]]") que RedBookHelpGui.pbi ja
;  usa pras 53 figuras do Livro Vermelho.
;
;  Codificacao de Th2HandbookHelp_Topics()\Corpo (gerada por
;  convert_th2handbook.py, descartavel/nao versionado) - PROPRIA deste
;  arquivo, nao e' o "mini-Markdown" comum (NBHelpGui_RenderMarkdown so
;  entende "##"/"**"/"`", sem link nem bloco de codigo multi-linha):
;    - linha comecando com "@@@"   -> linha inteira em estilo codigo/mono
;    - linha comecando com "## "   -> subtitulo (resto da linha, sem parse inline)
;    - em qualquer outra linha: "**negrito**", "`codigo`" e
;      "[[["+TEXTO+"|||"+anchor+"]]]" para um link clicavel (mostra TEXTO,
;      guarda anchor pra resolver no clique via
;      Th2HandbookHelp_AnchorMap())
; ------------------------------------------------------------
;

#Th2HandbookHelpGui_Event_HotspotClick = #PB_Event_FirstCustomValue + 61

#Th2HandbookHelpGui_Row_Group = 1
#Th2HandbookHelpGui_Row_Topic = 2

#Th2HandbookHelpGui_Style_Default = 0
#Th2HandbookHelpGui_Style_Title   = 1
#Th2HandbookHelpGui_Style_H2      = 2
#Th2HandbookHelpGui_Style_Bold    = 3
#Th2HandbookHelpGui_Style_Code    = 4
#Th2HandbookHelpGui_Style_Link    = 5

#Th2HandbookHelpGui_ShortcutBack = 9

Global Th2HandbookHelpGui_WinID.i = -1
Global Th2HandbookHelpGui_ContentGadget.i = -1
Global Th2HandbookHelpGui_PendingHotspotPos.i = -1

Structure Th2HandbookHelpRow
  Kind.i
  RefIndex.i    ; indice em Th2HandbookHelp_Topics() (Kind=Topic); -1 em grupos
  Label.s
  SearchKey.s
  SubLevel.i
EndStructure

Global NewList Th2HandbookHelpGui_Rows.Th2HandbookHelpRow()
Global Th2HandbookHelpGui_RowsBuilt.b = #False
Global NewMap Th2HandbookHelpGui_TopicToRow.i() ; chave = Str(TopicIdx), valor = RowIdx na arvore

Structure Th2HandbookLinkRun
  StartPos.i    ; posicao em bytes (UTF-8) no documento Scintilla atual
  EndPos.i
  Anchor.s
EndStructure
Global NewList Th2HandbookHelpGui_LinkRuns.Th2HandbookLinkRun()

Procedure Th2HandbookHelpGui_AddRow(Kind.i, RefIndex.i, Label.s, SearchKey.s, SubLevel.i)
  AddElement(Th2HandbookHelpGui_Rows())
  Th2HandbookHelpGui_Rows()\Kind = Kind
  Th2HandbookHelpGui_Rows()\RefIndex = RefIndex
  Th2HandbookHelpGui_Rows()\Label = Label
  Th2HandbookHelpGui_Rows()\SearchKey = SearchKey
  Th2HandbookHelpGui_Rows()\SubLevel = SubLevel
EndProcedure

Procedure Th2HandbookHelpGui_BuildRows()
  If Th2HandbookHelpGui_RowsBuilt
    ProcedureReturn
  EndIf
  Th2HandbookHelpGui_RowsBuilt = #True

  Th2HandbookHelp_BuildData()

  Protected Idx.i = -1, RowIdx.i = -1, CurrentGrupo.s = ""
  ForEach Th2HandbookHelp_Topics()
    Idx + 1
    If Th2HandbookHelp_Topics()\Grupo <> CurrentGrupo
      CurrentGrupo = Th2HandbookHelp_Topics()\Grupo
      Th2HandbookHelpGui_AddRow(#Th2HandbookHelpGui_Row_Group, -1, CurrentGrupo, "", 0)
      RowIdx + 1
    EndIf
    Th2HandbookHelpGui_AddRow(#Th2HandbookHelpGui_Row_Topic, Idx,
                           Th2HandbookHelp_Topics()\Titulo,
                           LCase(Th2HandbookHelp_Topics()\Titulo + " " + Th2HandbookHelp_Topics()\Grupo), 1)
    RowIdx + 1
    Th2HandbookHelpGui_TopicToRow(Str(Idx)) = RowIdx
  Next
EndProcedure

Procedure Th2HandbookHelpGui_PopulateTree(Tree)
  ClearGadgetItems(Tree)
  Protected RowIdx = -1
  ForEach Th2HandbookHelpGui_Rows()
    RowIdx + 1
    AddGadgetItem(Tree, -1, Th2HandbookHelpGui_Rows()\Label, 0, Th2HandbookHelpGui_Rows()\SubLevel)
    SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, RowIdx)
  Next
EndProcedure

Procedure Th2HandbookHelpGui_FilterTree(Tree, SearchText.s)
  Protected Needle.s = LCase(Trim(SearchText))
  If Needle = ""
    Th2HandbookHelpGui_PopulateTree(Tree)
    ProcedureReturn
  EndIf

  ClearGadgetItems(Tree)
  Protected RowIdx = -1
  ForEach Th2HandbookHelpGui_Rows()
    RowIdx + 1
    If Th2HandbookHelpGui_Rows()\Kind <> #Th2HandbookHelpGui_Row_Group And FindString(Th2HandbookHelpGui_Rows()\SearchKey, Needle) > 0
      AddGadgetItem(Tree, -1, Th2HandbookHelpGui_Rows()\Label, 0, 0)
      SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, RowIdx)
    EndIf
  Next
EndProcedure

; Fonte proporcional pro corpo (igual NBHelpGui_SetupStyles, NestorBasicHelpGui.pbi)
; - livro em prosa, nao texto pre-formatado tipo MsxManualsHelpGui/
; BiosCallsHelpGui - so os blocos de codigo (Style_Code) usam Consolas.
; Style_Link vira hotspot de verdade (SCI_STYLESETHOTSPOT) - unica janela
; de Ajuda com isso, ver comentario no topo do arquivo.
Procedure Th2HandbookHelpGui_SetupStyles(Sci)
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Protected *FontName = UTF8("Segoe UI")
    Protected BodyFontSize = 10
  CompilerElse
    Protected *FontName = UTF8(EditorCfg\FontName)
    Protected BodyFontSize = EditorCfg\FontSize
  CompilerEndIf
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #STYLE_DEFAULT, RGB(30, 30, 30))
  ScintillaSendMessage(Sci, #SCI_STYLESETBACK, #STYLE_DEFAULT, RGB(255, 255, 255))
  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #STYLE_DEFAULT, *FontName)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #STYLE_DEFAULT, BodyFontSize)
  ScintillaSendMessage(Sci, #SCI_STYLECLEARALL)

  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #Th2HandbookHelpGui_Style_Title, *FontName)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #Th2HandbookHelpGui_Style_Title, BodyFontSize + 5)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #Th2HandbookHelpGui_Style_Title, RGB(150, 20, 20))
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #Th2HandbookHelpGui_Style_Title, 1)

  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #Th2HandbookHelpGui_Style_H2, *FontName)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #Th2HandbookHelpGui_Style_H2, BodyFontSize + 2)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #Th2HandbookHelpGui_Style_H2, RGB(20, 60, 120))
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #Th2HandbookHelpGui_Style_H2, 1)

  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #Th2HandbookHelpGui_Style_Bold, *FontName)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #Th2HandbookHelpGui_Style_Bold, BodyFontSize)
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #Th2HandbookHelpGui_Style_Bold, 1)

  Protected *MonoFont = UTF8("Consolas")
  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #Th2HandbookHelpGui_Style_Code, *MonoFont)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #Th2HandbookHelpGui_Style_Code, BodyFontSize)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #Th2HandbookHelpGui_Style_Code, RGB(140, 40, 120))
  FreeMemory(*MonoFont)

  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #Th2HandbookHelpGui_Style_Link, *FontName)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #Th2HandbookHelpGui_Style_Link, BodyFontSize)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #Th2HandbookHelpGui_Style_Link, RGB(30, 90, 200))
  ScintillaSendMessage(Sci, #SCI_STYLESETUNDERLINE, #Th2HandbookHelpGui_Style_Link, 1)
  ScintillaSendMessage(Sci, #SCI_STYLESETHOTSPOT, #Th2HandbookHelpGui_Style_Link, 1)
  ScintillaSendMessage(Sci, #SCI_SETHOTSPOTACTIVEFORE, 1, RGB(200, 40, 40))
  ScintillaSendMessage(Sci, #SCI_SETHOTSPOTACTIVEUNDERLINE, 1)

  FreeMemory(*FontName)

  ScintillaSendMessage(Sci, #SCI_SETCARETFORE, RGB(255, 255, 255)) ; esconde o caret (so leitura)
  ScintillaSendMessage(Sci, #SCI_SETWRAPMODE, #SC_WRAP_WORD)
EndProcedure

Procedure Th2HandbookHelpGui_EmitRun(Sci, Text.s, Style)
  Protected ByteLen = StringByteLength(Text, #PB_UTF8)
  If ByteLen > 0
    ScintillaSendMessage(Sci, #SCI_SETSTYLING, ByteLen, Style)
  EndIf
EndProcedure

; Emite Buf (se nao vazio) como uma faixa de estilo CurStyle, atualizando
; PlainText/BytePos juntos - fatorado pra fora de
; Th2HandbookHelpGui_ParseInlineLine() porque PureBasic nao aceita Procedure
; aninhada dentro de outra Procedure.
Procedure Th2HandbookHelpGui_FlushBuf(Buf.s, CurStyle, List RunStyle.i(), List RunText.s(), *PlainText.String, *BytePos.Integer)
  If Buf <> ""
    AddElement(RunStyle()) : RunStyle() = CurStyle
    AddElement(RunText())  : RunText()  = Buf
    *PlainText\s + Buf
    *BytePos\i + StringByteLength(Buf, #PB_UTF8)
  EndIf
EndProcedure

; Parser de uma linha ja identificada como "prosa" (nao "@@@"/codigo, nao
; "## "/subtitulo) - entende "**negrito**", "`codigo`" e
; "[[["+TEXTO+"|||"+anchor+"]]]" (link) - sentinelas ASCII imprimivel de 3
; chars (nao bytes de controle crus: pbcompiler rejeita esses dentro de
; literais de string, "Literal string not terminated", confirmado ao
; tentar Chr(1)/Chr(4)). *BytePos e' avancado byte a byte (UTF-8) conforme
; cada pedaco e' emitido, pra Th2HandbookHelpGui_LinkRuns() guardar a posicao
; real no documento Scintilla (usada no clique).
Procedure Th2HandbookHelpGui_ParseInlineLine(Line.s, List RunStyle.i(), List RunText.s(), *PlainText.String, *BytePos.Integer)
  Protected Pos = 1, LineLen = Len(Line)
  Protected CurStyle = #Th2HandbookHelpGui_Style_Default
  Protected Buf.s = "", InBold.b = #False, InCode.b = #False
  Protected LinkText.s, LinkAnchor.s, LinkStartByte.i

  While Pos <= LineLen
    Protected Ch.s = Mid(Line, Pos, 1)

    If Mid(Line, Pos, 3) = "[[["
      Th2HandbookHelpGui_FlushBuf(Buf, CurStyle, RunStyle(), RunText(), *PlainText, *BytePos) : Buf = ""
      Protected CloseAt = FindString(Line, "|||", Pos + 3)
      Protected EndAt   = FindString(Line, "]]]", Pos + 3)
      If CloseAt > 0 And EndAt > CloseAt
        LinkText = Mid(Line, Pos + 3, CloseAt - Pos - 3)
        LinkAnchor = Mid(Line, CloseAt + 3, EndAt - CloseAt - 3)
        LinkStartByte = *BytePos\i
        Th2HandbookHelpGui_FlushBuf(LinkText, #Th2HandbookHelpGui_Style_Link, RunStyle(), RunText(), *PlainText, *BytePos)
        AddElement(Th2HandbookHelpGui_LinkRuns())
        Th2HandbookHelpGui_LinkRuns()\StartPos = LinkStartByte
        Th2HandbookHelpGui_LinkRuns()\EndPos = *BytePos\i
        Th2HandbookHelpGui_LinkRuns()\Anchor = LinkAnchor
        Pos = EndAt + 3
        Continue
      Else
        Pos + 1 ; sentinela quebrada (nao deveria acontecer) - ignora o char
        Continue
      EndIf
    ElseIf Mid(Line, Pos, 2) = "**"
      Th2HandbookHelpGui_FlushBuf(Buf, CurStyle, RunStyle(), RunText(), *PlainText, *BytePos) : Buf = ""
      InBold = Bool(Not InBold)
      CurStyle = Bool(InBold) * #Th2HandbookHelpGui_Style_Bold
      Pos + 2
      Continue
    ElseIf Ch = "`"
      Th2HandbookHelpGui_FlushBuf(Buf, CurStyle, RunStyle(), RunText(), *PlainText, *BytePos) : Buf = ""
      InCode = Bool(Not InCode)
      CurStyle = Bool(InCode) * #Th2HandbookHelpGui_Style_Code
      Pos + 1
      Continue
    Else
      Buf + Ch
      Pos + 1
    EndIf
  Wend
  Th2HandbookHelpGui_FlushBuf(Buf, CurStyle, RunStyle(), RunText(), *PlainText, *BytePos)
EndProcedure

; Titulo (Style_Title) + linha em branco + corpo (parser acima linha a
; linha) - reconstroi Th2HandbookHelpGui_LinkRuns() do zero a cada topico
; mostrado (so valem pro topico atual na tela).
Procedure Th2HandbookHelpGui_RenderTopic(Sci, Titulo.s, Corpo.s)
  ClearList(Th2HandbookHelpGui_LinkRuns())

  NewList RunStyle.i()
  NewList RunText.s()
  Protected PlainText.String
  Protected BytePos.Integer

  Protected TitleLine.s = Titulo + #CRLF$ + #CRLF$
  AddElement(RunStyle()) : RunStyle() = #Th2HandbookHelpGui_Style_Title
  AddElement(RunText())  : RunText()  = TitleLine
  PlainText\s = TitleLine
  BytePos\i = StringByteLength(TitleLine, #PB_UTF8)

  Protected TotalLines = CountString(Corpo, #CRLF$) + 1
  Protected LineIdx, Line.s
  For LineIdx = 1 To TotalLines
    Line = StringField(Corpo, LineIdx, #CRLF$)

    If LineIdx > 1
      AddElement(RunStyle()) : RunStyle() = #Th2HandbookHelpGui_Style_Default
      AddElement(RunText())  : RunText()  = #CRLF$
      PlainText\s + #CRLF$
      BytePos\i + 1
    EndIf

    If Left(Line, 3) = "@@@"
      Protected CodeText.s = Mid(Line, 4)
      AddElement(RunStyle()) : RunStyle() = #Th2HandbookHelpGui_Style_Code
      AddElement(RunText())  : RunText()  = CodeText
      PlainText\s + CodeText
      BytePos\i + StringByteLength(CodeText, #PB_UTF8)
    ElseIf Left(Line, 3) = "## "
      Protected H2Text.s = Mid(Line, 4)
      AddElement(RunStyle()) : RunStyle() = #Th2HandbookHelpGui_Style_H2
      AddElement(RunText())  : RunText()  = H2Text
      PlainText\s + H2Text
      BytePos\i + StringByteLength(H2Text, #PB_UTF8)
    Else
      Th2HandbookHelpGui_ParseInlineLine(Line, RunStyle(), RunText(), @PlainText, @BytePos)
    EndIf
  Next

  Protected *Buffer = UTF8(PlainText\s)
  ScintillaSendMessage(Sci, #SCI_SETREADONLY, 0)
  ScintillaSendMessage(Sci, #SCI_SETTEXT, 0, *Buffer)
  FreeMemory(*Buffer)

  ScintillaSendMessage(Sci, #SCI_STARTSTYLING, 0, 0)
  ResetList(RunStyle()) : ResetList(RunText())
  While NextElement(RunStyle()) And NextElement(RunText())
    Th2HandbookHelpGui_EmitRun(Sci, RunText(), RunStyle())
  Wend

  ScintillaSendMessage(Sci, #SCI_SETREADONLY, 1)
  ScintillaSendMessage(Sci, #SCI_EMPTYUNDOBUFFER)
  ScintillaSendMessage(Sci, #SCI_GOTOPOS, 0)
EndProcedure

Procedure Th2HandbookHelpGui_ShowRow(Sci, RowIdx.i)
  If Not SelectElement(Th2HandbookHelpGui_Rows(), RowIdx)
    ProcedureReturn
  EndIf
  Select Th2HandbookHelpGui_Rows()\Kind
    Case #Th2HandbookHelpGui_Row_Group
      Th2HandbookHelpGui_RenderTopic(Sci, Th2HandbookHelpGui_Rows()\Label, "Selecione um topico na lista ao lado.")
    Case #Th2HandbookHelpGui_Row_Topic
      If SelectElement(Th2HandbookHelp_Topics(), Th2HandbookHelpGui_Rows()\RefIndex)
        Th2HandbookHelpGui_RenderTopic(Sci, Th2HandbookHelp_Topics()\Titulo, Th2HandbookHelp_Topics()\Corpo)
      EndIf
  EndSelect
EndProcedure

; So captura a posicao do clique e adia a navegacao pro loop principal via
; PostEvent - mesma razao de ScintillaCallBack() em BadigEditor.pb (a
; notificacao ainda esta em andamento dentro do SendMessage que a disparou,
; mexer no Scintilla aqui dentro seria reentrancia).
Procedure Th2HandbookHelpGui_ScintillaCallback(Gadget, *scinotify.SCNotification)
  If *scinotify\nmhdr\code = #SCN_HOTSPOTCLICK
    Th2HandbookHelpGui_PendingHotspotPos = *scinotify\position
    PostEvent(#Th2HandbookHelpGui_Event_HotspotClick, Th2HandbookHelpGui_WinID, Gadget, 0, 0)
  EndIf
EndProcedure

; Popup pra uma figura do manual (editor/th2handbook_images/<Label>.png -
; PNG ja original do repositorio, sem conversao de formato nenhuma dessa
; vez). Scintilla nao mostra imagem embutida no texto, entao cada figura
; vira um link clicavel ("[[[[Ver Figura: X]|||img:x]]]", ver
; convert_th2handbook.py) que abre esta janela em vez de navegar na arvore
; (Th2HandbookHelpGui_Event_HotspotClick reconhece o prefixo "img:"). Modal
; em relacao a janela do Handbook (mesmo padrao de OpenModelessChildWindow
; usado em todo dialogo secundario do app) - fecha e volta pro manual antes
; de poder clicar noutra figura.
Procedure Th2HandbookHelpGui_ShowFigure(ParentWin, Label.s)
  Protected ImgPath.s = GetPathPart(ProgramFilename()) + "editor\th2handbook_images\" + Label + ".png"
  Protected Img = LoadImage(#PB_Any, ImgPath)
  If Not Img
    MessageRequester("MSX2 Technical Handbook", "Nao foi possivel carregar a figura:" + #CRLF$ + ImgPath)
    ProcedureReturn
  EndIf

  Protected ImgW = ImageWidth(Img), ImgH = ImageHeight(Img)
  Protected WinW = ImgW + 48, WinH = ImgH + 96
  If WinW < 260 : WinW = 260 : EndIf

  Protected Win = OpenModelessChildWindow(ParentWin, 0, 0, WinW, WinH, "Figura - " + UCase(Label),
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    FreeImage(Img)
    ProcedureReturn
  EndIf

  ImageGadget(#PB_Any, 24, 24, ImgW, ImgH, ImageID(Img))
  Protected G_Close = ThemedButton((WinW - 110) / 2, WinH - 56, 110, 32, "Fechar", Chr(#Icon_Close))

  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        If EventGadget() = G_Close
          Quit = #True
        EndIf
      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWin, Win)
  FreeImage(Img)
EndProcedure

Procedure Th2HandbookHelp_OpenWindow(ParentWindow)
  If Th2HandbookHelpGui_WinID <> -1 And IsWindow(Th2HandbookHelpGui_WinID)
    SetActiveWindow(Th2HandbookHelpGui_WinID)
    ProcedureReturn
  EndIf

  Th2HandbookHelpGui_BuildRows()

  Protected WinW = 1020, WinH = 660
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Ajuda - MSX2 Technical Handbook",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #False)
  If Not Win
    ProcedureReturn
  EndIf
  Th2HandbookHelpGui_WinID = Win

  Protected TopY = 24
  TextGadget(#PB_Any, 24, TopY + 4, 55, 20, "Buscar:")
  Protected G_Search = StringGadget(#PB_Any, 87, TopY, 300, 24, "")
  GadgetToolTip(G_Search, "Filtra por titulo ou capitulo")
  Protected G_ClearSearch = ThemedButton(399, TopY, 80, 24, "Limpar", Chr(#Icon_Clear))
  GadgetToolTip(G_ClearSearch, "Limpar")
  Protected G_Status = TextGadget(#PB_Any, 495, TopY + 4, WinW - 519, 20, "")

  Protected ButtonY = WinH - 56
  Protected TreeY = TopY + 24 + 16
  Protected TreeH = ButtonY - 16 - TreeY
  Protected TreeW = 320
  Protected G_Tree = TreeGadget(#PB_Any, 24, TreeY, TreeW, TreeH)
  Protected G_Content = ScintillaGadget(#PB_Any, 24 + TreeW + 24, TreeY, WinW - TreeW - 72, TreeH, @Th2HandbookHelpGui_ScintillaCallback())
  Th2HandbookHelpGui_ContentGadget = G_Content
  Th2HandbookHelpGui_SetupStyles(G_Content)

  Protected G_Back = ThemedButton(24, ButtonY, 180, 32, "<- Voltar (Alt+Esquerda)", Chr(#Icon_ArrowLeft))
  GadgetToolTip(G_Back, "<- Voltar (Alt+Esquerda)")
  Protected G_Close = ThemedButton(WinW - 24 - 110, ButtonY, 110, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  Th2HandbookHelpGui_PopulateTree(G_Tree)
  AddKeyboardShortcut(Win, #PB_Shortcut_Alt | #PB_Shortcut_Left, #Th2HandbookHelpGui_ShortcutBack)

  NewList History.i()
  Protected CurrentRow.i = -1
  Protected BackIdx.i, TreeScanIdx.i

  ; Macro (nao Procedure) de proposito - mesmo motivo das outras janelas de
  ; Ajuda: precisa enxergar direto G_Tree/G_Content/History()/CurrentRow.
  Macro Th2HandbookHelpGui_DoGoBack
    If ListSize(History()) > 0
      LastElement(History())
      BackIdx = History()
      DeleteElement(History())
      If BackIdx >= 0
        Th2HandbookHelpGui_ShowRow(G_Content, BackIdx)
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

  Macro Th2HandbookHelpGui_NavigateToRow(TargetRowIdx)
    If TargetRowIdx <> CurrentRow
      AddElement(History()) : History() = CurrentRow
      Th2HandbookHelpGui_ShowRow(G_Content, TargetRowIdx)
      CurrentRow = TargetRowIdx
      For TreeScanIdx = 0 To CountGadgetItems(G_Tree) - 1
        If GetGadgetItemData(G_Tree, TreeScanIdx) = TargetRowIdx
          SetGadgetState(G_Tree, TreeScanIdx)
          Break
        EndIf
      Next
    EndIf
  EndMacro

  If CountGadgetItems(G_Tree) > 1
    Th2HandbookHelpGui_ShowRow(G_Content, 1)
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
                Th2HandbookHelpGui_NavigateToRow(RowIdx)
              EndIf
            EndIf

          Case G_Search
            If EventType() = #PB_EventType_Change
              Th2HandbookHelpGui_FilterTree(G_Tree, GetGadgetText(G_Search))
              If Trim(GetGadgetText(G_Search)) <> ""
                SetGadgetText(G_Status, Str(CountGadgetItems(G_Tree)) + " resultado(s)")
              Else
                SetGadgetText(G_Status, "")
              EndIf
            EndIf

          Case G_ClearSearch
            SetGadgetText(G_Search, "")
            Th2HandbookHelpGui_FilterTree(G_Tree, "")
            SetGadgetText(G_Status, "")

          Case G_Back
            Th2HandbookHelpGui_DoGoBack

          Case G_Close
            Quit = #True

        EndSelect

      Case #Th2HandbookHelpGui_Event_HotspotClick
        ; resolve a posicao do clique (Th2HandbookHelpGui_PendingHotspotPos,
        ; capturada no callback) contra Th2HandbookHelpGui_LinkRuns() do topico
        ; atual, acha o anchor, resolve TopicIdx (Th2HandbookHelp_AnchorMap) ->
        ; RowIdx (Th2HandbookHelpGui_TopicToRow) e navega, igual um clique na arvore.
        Protected ClickPos = Th2HandbookHelpGui_PendingHotspotPos
        Protected FoundAnchor.s = ""
        ForEach Th2HandbookHelpGui_LinkRuns()
          If ClickPos >= Th2HandbookHelpGui_LinkRuns()\StartPos And ClickPos < Th2HandbookHelpGui_LinkRuns()\EndPos
            FoundAnchor = Th2HandbookHelpGui_LinkRuns()\Anchor
            Break
          EndIf
        Next
        If Left(FoundAnchor, 4) = "img:"
          Th2HandbookHelpGui_ShowFigure(Win, Mid(FoundAnchor, 5))
        ElseIf FoundAnchor <> ""
          If FindMapElement(Th2HandbookHelp_AnchorMap(), FoundAnchor)
            Protected TargetTopicIdx = Th2HandbookHelp_AnchorMap()
            If FindMapElement(Th2HandbookHelpGui_TopicToRow(), Str(TargetTopicIdx))
              Protected TargetRowIdx = Th2HandbookHelpGui_TopicToRow()
              Th2HandbookHelpGui_NavigateToRow(TargetRowIdx)
            EndIf
          EndIf
        EndIf

      Case #PB_Event_Menu
        If EventMenu() = #Th2HandbookHelpGui_ShortcutBack
          Th2HandbookHelpGui_DoGoBack
        EndIf

      Case #PB_Event_CloseWindow
        Quit = #True

    EndSelect
  Until Quit

  Th2HandbookHelpGui_WinID = -1
  Th2HandbookHelpGui_ContentGadget = -1
  CloseModelessChildWindow(ParentWindow, Win, #False)
EndProcedure
