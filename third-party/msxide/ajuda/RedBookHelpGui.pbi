;
; ------------------------------------------------------------
;  Ajuda -> Livro Vermelho...: janela navegavel/pesquisavel com "The MSX Red
;  Book" (Avalon Software / Kuma Computers, 1985), a partir da versao
;  Markdown mantida por Gustavo Seidler (github.com/gseidler/
;  The-MSX-Red-Book/blob/master/the_msx_red_book.md) - base de dados em
;  RedBookHelpData.pbi (XIncludeFile'd antes deste arquivo).
;
;  973 topicos (1 por endereco/rotina/secao, mesma ideia de particionamento
;  automatico de BiosCallsHelpData.pbi) em 9 grupos (Contents/Introduction/
;  7 capitulos). DIFERENTE de toda janela de Ajuda anterior: o livro tem
;  ~1740 referencias cruzadas internas (links tipo "veja DAC", "veja
;  4134H") que o usuario pediu pra manter navegaveis de verdade - por isso
;  esta e' a UNICA janela com LINKS CLICAVEIS de verdade dentro do corpo
;  (hotspot do Scintilla, ver RedBookHelpGui_ScintillaCallback), as outras
;  so navegam via arvore/busca.
;
;  Codificacao de RedBookHelp_Topics()\Corpo (gerada por convert_redbook.py,
;  descartavel/nao versionado) - PROPRIA deste arquivo, nao e' o
;  "mini-Markdown" comum (NBHelpGui_RenderMarkdown so entende "##"/"**"/"`",
;  sem link nem bloco de codigo multi-linha):
;    - linha comecando com "@@@"   -> linha inteira em estilo codigo/mono
;    - linha comecando com "## "   -> subtitulo (resto da linha, sem parse inline)
;    - em qualquer outra linha: "**negrito**", "`codigo`" e
;      "[[["+TEXTO+"|||"+anchor+"]]]" para um link clicavel (mostra TEXTO,
;      guarda anchor pra resolver no clique via
;      RedBookHelp_AnchorMap())
; ------------------------------------------------------------
;

#RedBookHelpGui_Event_HotspotClick = #PB_Event_FirstCustomValue + 60

#RedBookHelpGui_Row_Group = 1
#RedBookHelpGui_Row_Topic = 2

#RedBookHelpGui_Style_Default = 0
#RedBookHelpGui_Style_Title   = 1
#RedBookHelpGui_Style_H2      = 2
#RedBookHelpGui_Style_Bold    = 3
#RedBookHelpGui_Style_Code    = 4
#RedBookHelpGui_Style_Link    = 5

#RedBookHelpGui_ShortcutBack = 8

Global RedBookHelpGui_WinID.i = -1
Global RedBookHelpGui_ContentGadget.i = -1
Global RedBookHelpGui_PendingHotspotPos.i = -1

Structure RedBookHelpRow
  Kind.i
  RefIndex.i    ; indice em RedBookHelp_Topics() (Kind=Topic); -1 em grupos
  Label.s
  SearchKey.s
  SubLevel.i
EndStructure

Global NewList RedBookHelpGui_Rows.RedBookHelpRow()
Global RedBookHelpGui_RowsBuilt.b = #False
Global NewMap RedBookHelpGui_TopicToRow.i() ; chave = Str(TopicIdx), valor = RowIdx na arvore

Structure RedBookLinkRun
  StartPos.i    ; posicao em bytes (UTF-8) no documento Scintilla atual
  EndPos.i
  Anchor.s
EndStructure
Global NewList RedBookHelpGui_LinkRuns.RedBookLinkRun()

Procedure RedBookHelpGui_AddRow(Kind.i, RefIndex.i, Label.s, SearchKey.s, SubLevel.i)
  AddElement(RedBookHelpGui_Rows())
  RedBookHelpGui_Rows()\Kind = Kind
  RedBookHelpGui_Rows()\RefIndex = RefIndex
  RedBookHelpGui_Rows()\Label = Label
  RedBookHelpGui_Rows()\SearchKey = SearchKey
  RedBookHelpGui_Rows()\SubLevel = SubLevel
EndProcedure

Procedure RedBookHelpGui_BuildRows()
  If RedBookHelpGui_RowsBuilt
    ProcedureReturn
  EndIf
  RedBookHelpGui_RowsBuilt = #True

  RedBookHelp_BuildData()

  Protected Idx.i = -1, RowIdx.i = -1, CurrentGrupo.s = ""
  ForEach RedBookHelp_Topics()
    Idx + 1
    If RedBookHelp_Topics()\Grupo <> CurrentGrupo
      CurrentGrupo = RedBookHelp_Topics()\Grupo
      RedBookHelpGui_AddRow(#RedBookHelpGui_Row_Group, -1, CurrentGrupo, "", 0)
      RowIdx + 1
    EndIf
    RedBookHelpGui_AddRow(#RedBookHelpGui_Row_Topic, Idx,
                           RedBookHelp_Topics()\Titulo,
                           LCase(RedBookHelp_Topics()\Titulo + " " + RedBookHelp_Topics()\Grupo), 1)
    RowIdx + 1
    RedBookHelpGui_TopicToRow(Str(Idx)) = RowIdx
  Next
EndProcedure

Procedure RedBookHelpGui_PopulateTree(Tree)
  ClearGadgetItems(Tree)
  Protected RowIdx = -1
  ForEach RedBookHelpGui_Rows()
    RowIdx + 1
    AddGadgetItem(Tree, -1, RedBookHelpGui_Rows()\Label, 0, RedBookHelpGui_Rows()\SubLevel)
    SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, RowIdx)
  Next
EndProcedure

Procedure RedBookHelpGui_FilterTree(Tree, SearchText.s)
  Protected Needle.s = LCase(Trim(SearchText))
  If Needle = ""
    RedBookHelpGui_PopulateTree(Tree)
    ProcedureReturn
  EndIf

  ClearGadgetItems(Tree)
  Protected RowIdx = -1
  ForEach RedBookHelpGui_Rows()
    RowIdx + 1
    If RedBookHelpGui_Rows()\Kind <> #RedBookHelpGui_Row_Group And FindString(RedBookHelpGui_Rows()\SearchKey, Needle) > 0
      AddGadgetItem(Tree, -1, RedBookHelpGui_Rows()\Label, 0, 0)
      SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, RowIdx)
    EndIf
  Next
EndProcedure

; Fonte proporcional pro corpo (igual NBHelpGui_SetupStyles, NestorBasicHelpGui.pbi)
; - livro em prosa, nao texto pre-formatado tipo MsxManualsHelpGui/
; BiosCallsHelpGui - so os blocos de codigo (Style_Code) usam Consolas.
; Style_Link vira hotspot de verdade (SCI_STYLESETHOTSPOT) - unica janela
; de Ajuda com isso, ver comentario no topo do arquivo.
Procedure RedBookHelpGui_SetupStyles(Sci)
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

  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #RedBookHelpGui_Style_Title, *FontName)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #RedBookHelpGui_Style_Title, BodyFontSize + 5)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #RedBookHelpGui_Style_Title, RGB(150, 20, 20))
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #RedBookHelpGui_Style_Title, 1)

  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #RedBookHelpGui_Style_H2, *FontName)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #RedBookHelpGui_Style_H2, BodyFontSize + 2)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #RedBookHelpGui_Style_H2, RGB(20, 60, 120))
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #RedBookHelpGui_Style_H2, 1)

  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #RedBookHelpGui_Style_Bold, *FontName)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #RedBookHelpGui_Style_Bold, BodyFontSize)
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #RedBookHelpGui_Style_Bold, 1)

  Protected *MonoFont = UTF8("Consolas")
  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #RedBookHelpGui_Style_Code, *MonoFont)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #RedBookHelpGui_Style_Code, BodyFontSize)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #RedBookHelpGui_Style_Code, RGB(140, 40, 120))
  FreeMemory(*MonoFont)

  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #RedBookHelpGui_Style_Link, *FontName)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #RedBookHelpGui_Style_Link, BodyFontSize)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #RedBookHelpGui_Style_Link, RGB(30, 90, 200))
  ScintillaSendMessage(Sci, #SCI_STYLESETUNDERLINE, #RedBookHelpGui_Style_Link, 1)
  ScintillaSendMessage(Sci, #SCI_STYLESETHOTSPOT, #RedBookHelpGui_Style_Link, 1)
  ScintillaSendMessage(Sci, #SCI_SETHOTSPOTACTIVEFORE, 1, RGB(200, 40, 40))
  ScintillaSendMessage(Sci, #SCI_SETHOTSPOTACTIVEUNDERLINE, 1)

  FreeMemory(*FontName)

  ScintillaSendMessage(Sci, #SCI_SETCARETFORE, RGB(255, 255, 255)) ; esconde o caret (so leitura)
  ScintillaSendMessage(Sci, #SCI_SETWRAPMODE, #SC_WRAP_WORD)
EndProcedure

Procedure RedBookHelpGui_EmitRun(Sci, Text.s, Style)
  Protected ByteLen = StringByteLength(Text, #PB_UTF8)
  If ByteLen > 0
    ScintillaSendMessage(Sci, #SCI_SETSTYLING, ByteLen, Style)
  EndIf
EndProcedure

; Emite Buf (se nao vazio) como uma faixa de estilo CurStyle, atualizando
; PlainText/BytePos juntos - fatorado pra fora de
; RedBookHelpGui_ParseInlineLine() porque PureBasic nao aceita Procedure
; aninhada dentro de outra Procedure.
Procedure RedBookHelpGui_FlushBuf(Buf.s, CurStyle, List RunStyle.i(), List RunText.s(), *PlainText.String, *BytePos.Integer)
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
; cada pedaco e' emitido, pra RedBookHelpGui_LinkRuns() guardar a posicao
; real no documento Scintilla (usada no clique).
Procedure RedBookHelpGui_ParseInlineLine(Line.s, List RunStyle.i(), List RunText.s(), *PlainText.String, *BytePos.Integer)
  Protected Pos = 1, LineLen = Len(Line)
  Protected CurStyle = #RedBookHelpGui_Style_Default
  Protected Buf.s = "", InBold.b = #False, InCode.b = #False
  Protected LinkText.s, LinkAnchor.s, LinkStartByte.i

  While Pos <= LineLen
    Protected Ch.s = Mid(Line, Pos, 1)

    If Mid(Line, Pos, 3) = "[[["
      RedBookHelpGui_FlushBuf(Buf, CurStyle, RunStyle(), RunText(), *PlainText, *BytePos) : Buf = ""
      Protected CloseAt = FindString(Line, "|||", Pos + 3)
      Protected EndAt   = FindString(Line, "]]]", Pos + 3)
      If CloseAt > 0 And EndAt > CloseAt
        LinkText = Mid(Line, Pos + 3, CloseAt - Pos - 3)
        LinkAnchor = Mid(Line, CloseAt + 3, EndAt - CloseAt - 3)
        LinkStartByte = *BytePos\i
        RedBookHelpGui_FlushBuf(LinkText, #RedBookHelpGui_Style_Link, RunStyle(), RunText(), *PlainText, *BytePos)
        AddElement(RedBookHelpGui_LinkRuns())
        RedBookHelpGui_LinkRuns()\StartPos = LinkStartByte
        RedBookHelpGui_LinkRuns()\EndPos = *BytePos\i
        RedBookHelpGui_LinkRuns()\Anchor = LinkAnchor
        Pos = EndAt + 3
        Continue
      Else
        Pos + 1 ; sentinela quebrada (nao deveria acontecer) - ignora o char
        Continue
      EndIf
    ElseIf Mid(Line, Pos, 2) = "**"
      RedBookHelpGui_FlushBuf(Buf, CurStyle, RunStyle(), RunText(), *PlainText, *BytePos) : Buf = ""
      InBold = Bool(Not InBold)
      CurStyle = Bool(InBold) * #RedBookHelpGui_Style_Bold
      Pos + 2
      Continue
    ElseIf Ch = "`"
      RedBookHelpGui_FlushBuf(Buf, CurStyle, RunStyle(), RunText(), *PlainText, *BytePos) : Buf = ""
      InCode = Bool(Not InCode)
      CurStyle = Bool(InCode) * #RedBookHelpGui_Style_Code
      Pos + 1
      Continue
    Else
      Buf + Ch
      Pos + 1
    EndIf
  Wend
  RedBookHelpGui_FlushBuf(Buf, CurStyle, RunStyle(), RunText(), *PlainText, *BytePos)
EndProcedure

; Titulo (Style_Title) + linha em branco + corpo (parser acima linha a
; linha) - reconstroi RedBookHelpGui_LinkRuns() do zero a cada topico
; mostrado (so valem pro topico atual na tela).
Procedure RedBookHelpGui_RenderTopic(Sci, Titulo.s, Corpo.s)
  ClearList(RedBookHelpGui_LinkRuns())

  NewList RunStyle.i()
  NewList RunText.s()
  Protected PlainText.String
  Protected BytePos.Integer

  Protected TitleLine.s = Titulo + #CRLF$ + #CRLF$
  AddElement(RunStyle()) : RunStyle() = #RedBookHelpGui_Style_Title
  AddElement(RunText())  : RunText()  = TitleLine
  PlainText\s = TitleLine
  BytePos\i = StringByteLength(TitleLine, #PB_UTF8)

  Protected TotalLines = CountString(Corpo, #CRLF$) + 1
  Protected LineIdx, Line.s
  For LineIdx = 1 To TotalLines
    Line = StringField(Corpo, LineIdx, #CRLF$)

    If LineIdx > 1
      AddElement(RunStyle()) : RunStyle() = #RedBookHelpGui_Style_Default
      AddElement(RunText())  : RunText()  = #CRLF$
      PlainText\s + #CRLF$
      BytePos\i + 1
    EndIf

    If Left(Line, 3) = "@@@"
      Protected CodeText.s = Mid(Line, 4)
      AddElement(RunStyle()) : RunStyle() = #RedBookHelpGui_Style_Code
      AddElement(RunText())  : RunText()  = CodeText
      PlainText\s + CodeText
      BytePos\i + StringByteLength(CodeText, #PB_UTF8)
    ElseIf Left(Line, 3) = "## "
      Protected H2Text.s = Mid(Line, 4)
      AddElement(RunStyle()) : RunStyle() = #RedBookHelpGui_Style_H2
      AddElement(RunText())  : RunText()  = H2Text
      PlainText\s + H2Text
      BytePos\i + StringByteLength(H2Text, #PB_UTF8)
    Else
      RedBookHelpGui_ParseInlineLine(Line, RunStyle(), RunText(), @PlainText, @BytePos)
    EndIf
  Next

  Protected *Buffer = UTF8(PlainText\s)
  ScintillaSendMessage(Sci, #SCI_SETREADONLY, 0)
  ScintillaSendMessage(Sci, #SCI_SETTEXT, 0, *Buffer)
  FreeMemory(*Buffer)

  ScintillaSendMessage(Sci, #SCI_STARTSTYLING, 0, 0)
  ResetList(RunStyle()) : ResetList(RunText())
  While NextElement(RunStyle()) And NextElement(RunText())
    RedBookHelpGui_EmitRun(Sci, RunText(), RunStyle())
  Wend

  ScintillaSendMessage(Sci, #SCI_SETREADONLY, 1)
  ScintillaSendMessage(Sci, #SCI_EMPTYUNDOBUFFER)
  ScintillaSendMessage(Sci, #SCI_GOTOPOS, 0)
EndProcedure

Procedure RedBookHelpGui_ShowRow(Sci, RowIdx.i)
  If Not SelectElement(RedBookHelpGui_Rows(), RowIdx)
    ProcedureReturn
  EndIf
  Select RedBookHelpGui_Rows()\Kind
    Case #RedBookHelpGui_Row_Group
      RedBookHelpGui_RenderTopic(Sci, RedBookHelpGui_Rows()\Label, "Selecione um topico na lista ao lado.")
    Case #RedBookHelpGui_Row_Topic
      If SelectElement(RedBookHelp_Topics(), RedBookHelpGui_Rows()\RefIndex)
        RedBookHelpGui_RenderTopic(Sci, RedBookHelp_Topics()\Titulo, RedBookHelp_Topics()\Corpo)
      EndIf
  EndSelect
EndProcedure

; So captura a posicao do clique e adia a navegacao pro loop principal via
; PostEvent - mesma razao de ScintillaCallBack() em BadigEditor.pb (a
; notificacao ainda esta em andamento dentro do SendMessage que a disparou,
; mexer no Scintilla aqui dentro seria reentrancia).
Procedure RedBookHelpGui_ScintillaCallback(Gadget, *scinotify.SCNotification)
  If *scinotify\nmhdr\code = #SCN_HOTSPOTCLICK
    RedBookHelpGui_PendingHotspotPos = *scinotify\position
    PostEvent(#RedBookHelpGui_Event_HotspotClick, RedBookHelpGui_WinID, Gadget, 0, 0)
  EndIf
EndProcedure

; Popup pra uma figura do livro (editor/redbook_images/<Label>.png, PNG
; convertido a partir do SVG original do repositorio - Scintilla nao mostra
; imagem embutida no texto, entao cada figura vira um link clicavel
; ("[[[[Ver Figura: X]|||img:x]]]", ver convert_redbook.py) que abre esta
; janela em vez de navegar na arvore (RedBookHelpGui_Event_HotspotClick
; reconhece o prefixo "img:"). Modal em relacao a janela do Livro Vermelho
; (mesmo padrao de OpenModelessChildWindow usado em todo dialogo secundario
; do app) - fecha e volta pro livro antes de poder clicar noutra figura.
Procedure RedBookHelpGui_ShowFigure(ParentWin, Label.s)
  Protected ImgPath.s = GetPathPart(ProgramFilename()) + "editor\redbook_images\" + UCase(Label) + ".png"
  Protected Img = LoadImage(#PB_Any, ImgPath)
  If Not Img
    MessageRequester("Livro Vermelho", "Nao foi possivel carregar a figura:" + #CRLF$ + ImgPath)
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

Procedure RedBookHelp_OpenWindow(ParentWindow)
  If RedBookHelpGui_WinID <> -1 And IsWindow(RedBookHelpGui_WinID)
    SetActiveWindow(RedBookHelpGui_WinID)
    ProcedureReturn
  EndIf

  RedBookHelpGui_BuildRows()

  Protected WinW = 1020, WinH = 660
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Ajuda - Livro Vermelho do MSX",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #False)
  If Not Win
    ProcedureReturn
  EndIf
  RedBookHelpGui_WinID = Win

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
  Protected G_Content = ScintillaGadget(#PB_Any, 24 + TreeW + 24, TreeY, WinW - TreeW - 72, TreeH, @RedBookHelpGui_ScintillaCallback())
  RedBookHelpGui_ContentGadget = G_Content
  RedBookHelpGui_SetupStyles(G_Content)

  Protected G_Back = ThemedButton(24, ButtonY, 180, 32, "<- Voltar (Alt+Esquerda)", Chr(#Icon_ArrowLeft))
  GadgetToolTip(G_Back, "<- Voltar (Alt+Esquerda)")
  Protected G_Close = ThemedButton(WinW - 24 - 110, ButtonY, 110, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  RedBookHelpGui_PopulateTree(G_Tree)
  AddKeyboardShortcut(Win, #PB_Shortcut_Alt | #PB_Shortcut_Left, #RedBookHelpGui_ShortcutBack)

  NewList History.i()
  Protected CurrentRow.i = -1
  Protected BackIdx.i, TreeScanIdx.i

  ; Macro (nao Procedure) de proposito - mesmo motivo das outras janelas de
  ; Ajuda: precisa enxergar direto G_Tree/G_Content/History()/CurrentRow.
  Macro RedBookHelpGui_DoGoBack
    If ListSize(History()) > 0
      LastElement(History())
      BackIdx = History()
      DeleteElement(History())
      If BackIdx >= 0
        RedBookHelpGui_ShowRow(G_Content, BackIdx)
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

  Macro RedBookHelpGui_NavigateToRow(TargetRowIdx)
    If TargetRowIdx <> CurrentRow
      AddElement(History()) : History() = CurrentRow
      RedBookHelpGui_ShowRow(G_Content, TargetRowIdx)
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
    RedBookHelpGui_ShowRow(G_Content, 1)
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
                RedBookHelpGui_NavigateToRow(RowIdx)
              EndIf
            EndIf

          Case G_Search
            If EventType() = #PB_EventType_Change
              RedBookHelpGui_FilterTree(G_Tree, GetGadgetText(G_Search))
              If Trim(GetGadgetText(G_Search)) <> ""
                SetGadgetText(G_Status, Str(CountGadgetItems(G_Tree)) + " resultado(s)")
              Else
                SetGadgetText(G_Status, "")
              EndIf
            EndIf

          Case G_ClearSearch
            SetGadgetText(G_Search, "")
            RedBookHelpGui_FilterTree(G_Tree, "")
            SetGadgetText(G_Status, "")

          Case G_Back
            RedBookHelpGui_DoGoBack

          Case G_Close
            Quit = #True

        EndSelect

      Case #RedBookHelpGui_Event_HotspotClick
        ; resolve a posicao do clique (RedBookHelpGui_PendingHotspotPos,
        ; capturada no callback) contra RedBookHelpGui_LinkRuns() do topico
        ; atual, acha o anchor, resolve TopicIdx (RedBookHelp_AnchorMap) ->
        ; RowIdx (RedBookHelpGui_TopicToRow) e navega, igual um clique na arvore.
        Protected ClickPos = RedBookHelpGui_PendingHotspotPos
        Protected FoundAnchor.s = ""
        ForEach RedBookHelpGui_LinkRuns()
          If ClickPos >= RedBookHelpGui_LinkRuns()\StartPos And ClickPos < RedBookHelpGui_LinkRuns()\EndPos
            FoundAnchor = RedBookHelpGui_LinkRuns()\Anchor
            Break
          EndIf
        Next
        If Left(FoundAnchor, 4) = "img:"
          RedBookHelpGui_ShowFigure(Win, Mid(FoundAnchor, 5))
        ElseIf FoundAnchor <> ""
          If FindMapElement(RedBookHelp_AnchorMap(), FoundAnchor)
            Protected TargetTopicIdx = RedBookHelp_AnchorMap()
            If FindMapElement(RedBookHelpGui_TopicToRow(), Str(TargetTopicIdx))
              Protected TargetRowIdx = RedBookHelpGui_TopicToRow()
              RedBookHelpGui_NavigateToRow(TargetRowIdx)
            EndIf
          EndIf
        EndIf

      Case #PB_Event_Menu
        If EventMenu() = #RedBookHelpGui_ShortcutBack
          RedBookHelpGui_DoGoBack
        EndIf

      Case #PB_Event_CloseWindow
        Quit = #True

    EndSelect
  Until Quit

  RedBookHelpGui_WinID = -1
  RedBookHelpGui_ContentGadget = -1
  CloseModelessChildWindow(ParentWindow, Win, #False)
EndProcedure
