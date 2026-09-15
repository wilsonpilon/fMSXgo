;
; ------------------------------------------------------------
;  Motor generico de Ajuda orientado a pasta: renderiza uma pasta de arquivos
;  .md (baixados em tempo de execucao por MsxBas2RomSupport.pbi/N80Support.pbi
;  via "Configurar -> ... -> Baixar", ver _index.json) numa janela com o
;  MESMO layout de busca+arvore+conteudo de NestorBasicHelpGui.pbi, mas sem
;  depender de conteudo compilado em *HelpData.pbi - o conteudo vive em disco
;  e atualiza sozinho a cada novo "Baixar", sem precisar de uma nova versao
;  do .exe.
;
;  Renderizador de markdown "melhor esforco" (GenMdHelp_RenderMarkdown), mais
;  rico que o mini-renderer de NestorBasicHelpGui.pbi (## / **bold** / `code`):
;  titulos "# "/"## "/"### ", blocos ``` (estilo monoespacado, sem processar
;  ** / ` por dentro - senao colide com o crase do fence) e [texto](url) como
;  link clicavel de verdade. Link clicavel usa SCI_STYLESETHOTSPOT: cada link
;  ganha um numero de estilo dedicado (10..254, reciclado a cada troca de
;  topico) mapeado pra URL em GenMdHelp_LinkUrls(), chave "gadget_estilo" (tem
;  que ser por gadget porque o MESMO numero de estilo significa URLs
;  diferentes em janelas de Ajuda diferentes abertas ao mesmo tempo); no
;  clique (SCN_HOTSPOTCLICK, capturado no callback do proprio gadget, mesmo
;  padrao de ScintillaCallBack() em BadigEditor.pb), pega o estilo no byte
;  clicado com SCI_GETSTYLEAT e resolve a URL nesse mapa.
;
;  Tabelas/listas markdown ficam como texto corrido (sem parser dedicado -
;  fora do escopo do "melhor esforco" pedido: title/bold/code/link/blocos de
;  codigo cobrem a maior parte do conteudo real baixado das wikis/manuais).
; ------------------------------------------------------------
;

#GenMdHelp_Style_Default  = 0
#GenMdHelp_Style_H1       = 1
#GenMdHelp_Style_H2       = 2
#GenMdHelp_Style_H3       = 3
#GenMdHelp_Style_Bold     = 4
#GenMdHelp_Style_Code     = 5
#GenMdHelp_Style_LinkBase = 10 ; 10..254, reciclado a cada RenderMarkdown()
#GenMdHelp_Style_LinkMax  = 254

#GenMdHelp_ShortcutBack = 2001 ; numero distinto de #NBHelpGui_ShortcutBack (=1)

; Chave "NumeroDoGadget_NumeroDoEstilo" -> URL. Reaproveitado/sobrescrito a
; cada RenderMarkdown() - nao precisa limpar entradas velhas explicitamente,
; elas so deixam de ser referenciadas por nenhum byte do documento atual.
Global NewMap GenMdHelp_LinkUrls.s()

Structure GenMdHelp_TopicItem
  File.s
  Title.s
  Group.s
EndStructure

; Um por janela de Ajuda aberta - so vive na pilha de GenMdHelp_OpenWindow()
; (passado por ponteiro pras procedures auxiliares), nao precisa de registro
; global: o unico estado global entre callback e janela e GenMdHelp_LinkUrls
; (URL por gadget+estilo), que e tudo que o clique em hotspot precisa.
Structure GenMdHelp_WindowState
  FolderPath.s
  List Topics.GenMdHelp_TopicItem()
EndStructure

; Fonte do corpo do texto: Segoe UI num tamanho fixo (Windows), NAO a fonte
; do editor de codigo (EditorCfg\FontName/FontSize) - mesma razao/mesmo fix
; de NBHelpGui_SetupStyles (NestorBasicHelpGui.pbi): fonte monoespacada em
; prosa fica maior/mais larga do que o tamanho configurado sugere e quebra
; de linha (SC_WRAP_WORD, mais abaixo) muito mais frequente - lido pelo
; usuario como "fonte grande, texto desalinhado, quebra em linhas
; desconexas" (2026-08-09), reproduzido abrindo Ajuda -> MSXBas2Rom... (o
; conteudo baixado da wiki tem paragrafos de prosa de verdade, ao contrario
; da maioria dos outros Helps, escritos a mao ja mais compactos).
Procedure GenMdHelp_SetupStyles(Sci)
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
  FreeMemory(*FontName)

  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #GenMdHelp_Style_H1, RGB(15, 45, 100))
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #GenMdHelp_Style_H1, 1)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #GenMdHelp_Style_H1, BodyFontSize + 6)

  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #GenMdHelp_Style_H2, RGB(20, 60, 120))
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #GenMdHelp_Style_H2, 1)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #GenMdHelp_Style_H2, BodyFontSize + 3)

  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #GenMdHelp_Style_H3, RGB(25, 70, 130))
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #GenMdHelp_Style_H3, 1)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #GenMdHelp_Style_H3, BodyFontSize + 1)

  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #GenMdHelp_Style_Bold, 1)

  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #GenMdHelp_Style_Code, RGB(140, 40, 120))
  Protected *MonoFont = UTF8("Consolas")
  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #GenMdHelp_Style_Code, *MonoFont)
  FreeMemory(*MonoFont)

  ScintillaSendMessage(Sci, #SCI_SETCARETFORE, RGB(255, 255, 255)) ; esconde o caret (so leitura)
  ScintillaSendMessage(Sci, #SCI_SETWRAPMODE, #SC_WRAP_WORD)
EndProcedure

Procedure GenMdHelp_EmitRun(Sci, Text.s, Style)
  Protected ByteLen = StringByteLength(Text, #PB_UTF8)
  If ByteLen > 0
    ScintillaSendMessage(Sci, #SCI_SETSTYLING, ByteLen, Style)
  EndIf
EndProcedure

Procedure GenMdHelp_OpenUrl(Url.s)
  If Url = "" : ProcedureReturn : EndIf
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    RunProgram("explorer.exe", Url, "", #PB_Program_Open)
  CompilerElse
    RunProgram("xdg-open", Chr(34) + Url + Chr(34), "", #PB_Program_Open)
  CompilerEndIf
EndProcedure

; Callback do ScintillaGadget de conteudo - so cuida de clique em hotspot
; (link). Mesma tecnica de callback-por-gadget de ScintillaCallBack() em
; BadigEditor.pb, mas RunProgram() nao mexe no proprio Scintilla, entao pode
; ser chamado direto daqui sem risco de reentrancia (ao contrario do que o
; comentario de ScintillaCallBack() evita para SCN_MODIFIED).
Procedure GenMdHelp_ScintillaCallback(Gadget, *scinotify.SCNotification)
  If *scinotify\nmhdr\code = #SCN_HOTSPOTCLICK
    Protected StyleAtPos = ScintillaSendMessage(Gadget, #SCI_GETSTYLEAT, *scinotify\position)
    Protected Key.s = Str(Gadget) + "_" + Str(StyleAtPos)
    If FindMapElement(GenMdHelp_LinkUrls(), Key)
      GenMdHelp_OpenUrl(GenMdHelp_LinkUrls())
    EndIf
  EndIf
EndProcedure

; "Melhor esforco": titulos #/##/###, blocos ``` (linha so com as 3 crases
; abre/fecha, conteudo vira estilo de codigo verbatim), [texto](url) como
; link clicavel, **negrito**/`codigo` inline fora de blocos de codigo. Tudo
; mais (tabelas, listas, citacoes) fica como texto corrido. Monta o texto
; puro (sem os marcadores) e a lista de faixas de estilo juntos, na mesma
; passada, pra nao precisar recalcular deslocamento de bytes depois (mesma
; tecnica de NBHelpGui_RenderMarkdown).
Procedure GenMdHelp_RenderMarkdown(Sci, Markdown.s)
  Protected PlainText.s = ""
  NewList RunStyle.i()
  NewList RunText.s()

  Protected TotalLines = CountString(Markdown, #CRLF$) + 1
  Protected LineIdx, Line.s, FirstLine.b = #True
  Protected InCodeBlock.b = #False
  Protected NextLinkStyle.i = #GenMdHelp_Style_LinkBase

  For LineIdx = 1 To TotalLines
    Line = StringField(Markdown, LineIdx, #CRLF$)
    If Not FirstLine
      AddElement(RunStyle()) : RunStyle() = #GenMdHelp_Style_Default
      AddElement(RunText())  : RunText()  = #CRLF$
      PlainText + #CRLF$
    EndIf
    FirstLine = #False

    If Left(Trim(Line), 3) = "```"
      If InCodeBlock : InCodeBlock = #False : Else : InCodeBlock = #True : EndIf
      Continue ; a linha do fence em si nao aparece no texto renderizado
    EndIf

    If InCodeBlock
      If Line <> ""
        AddElement(RunStyle()) : RunStyle() = #GenMdHelp_Style_Code
        AddElement(RunText())  : RunText()  = Line
        PlainText + Line
      EndIf
      Continue
    EndIf

    Protected IsHeading.b = #False
    Protected HeadingStyle = #GenMdHelp_Style_Default
    Protected Body.s = Line
    If Left(Line, 4) = "### "
      IsHeading = #True : HeadingStyle = #GenMdHelp_Style_H3 : Body = Mid(Line, 5)
    ElseIf Left(Line, 3) = "## "
      IsHeading = #True : HeadingStyle = #GenMdHelp_Style_H2 : Body = Mid(Line, 4)
    ElseIf Left(Line, 2) = "# "
      IsHeading = #True : HeadingStyle = #GenMdHelp_Style_H1 : Body = Mid(Line, 3)
    EndIf

    Protected Pos = 1, BodyLen = Len(Body)
    Protected CurStyle = #GenMdHelp_Style_Default
    If IsHeading : CurStyle = HeadingStyle : EndIf
    Protected Buf.s = "", InBold.b = #False, InCode.b = #False

    While Pos <= BodyLen
      Protected IsLinkStart.b = Bool(Not IsHeading And Mid(Body, Pos, 1) = "[")
      Protected LinkTextEnd.i = 0, LinkUrlStart.i = 0, LinkUrlEnd.i = 0
      If IsLinkStart
        LinkTextEnd = FindString(Body, "]", Pos + 1)
        If LinkTextEnd > 0 And Mid(Body, LinkTextEnd + 1, 1) = "("
          LinkUrlStart = LinkTextEnd + 2
          LinkUrlEnd = FindString(Body, ")", LinkUrlStart)
        EndIf
      EndIf

      If IsLinkStart And LinkTextEnd > 0 And LinkUrlEnd > 0
        If Buf <> ""
          AddElement(RunStyle()) : RunStyle() = CurStyle
          AddElement(RunText())  : RunText()  = Buf
          PlainText + Buf
          Buf = ""
        EndIf
        Protected LinkText.s = Mid(Body, Pos + 1, LinkTextEnd - Pos - 1)
        Protected LinkUrl.s = Mid(Body, LinkUrlStart, LinkUrlEnd - LinkUrlStart)
        Protected LinkStyle
        If NextLinkStyle <= #GenMdHelp_Style_LinkMax And LinkText <> ""
          LinkStyle = NextLinkStyle
          ScintillaSendMessage(Sci, #SCI_STYLESETHOTSPOT, LinkStyle, 1)
          ScintillaSendMessage(Sci, #SCI_STYLESETFORE, LinkStyle, RGB(30, 90, 200))
          ScintillaSendMessage(Sci, #SCI_STYLESETUNDERLINE, LinkStyle, 1)
          GenMdHelp_LinkUrls(Str(Sci) + "_" + Str(LinkStyle)) = LinkUrl
          NextLinkStyle + 1
        Else
          LinkStyle = CurStyle ; estourou o limite de estilos de link - vira texto normal
        EndIf
        If LinkText <> ""
          AddElement(RunStyle()) : RunStyle() = LinkStyle
          AddElement(RunText())  : RunText()  = LinkText
          PlainText + LinkText
        EndIf
        Pos = LinkUrlEnd + 1
        Continue
      EndIf

      If Not IsHeading And Mid(Body, Pos, 2) = "**"
        If Buf <> ""
          AddElement(RunStyle()) : RunStyle() = CurStyle
          AddElement(RunText())  : RunText()  = Buf
          PlainText + Buf
          Buf = ""
        EndIf
        If InBold : InBold = #False : Else : InBold = #True : EndIf
        If InBold : CurStyle = #GenMdHelp_Style_Bold : Else : CurStyle = #GenMdHelp_Style_Default : EndIf
        Pos + 2
      ElseIf Not IsHeading And Mid(Body, Pos, 1) = "`"
        If Buf <> ""
          AddElement(RunStyle()) : RunStyle() = CurStyle
          AddElement(RunText())  : RunText()  = Buf
          PlainText + Buf
          Buf = ""
        EndIf
        If InCode : InCode = #False : Else : InCode = #True : EndIf
        If InCode : CurStyle = #GenMdHelp_Style_Code : Else : CurStyle = #GenMdHelp_Style_Default : EndIf
        Pos + 1
      Else
        Buf + Mid(Body, Pos, 1)
        Pos + 1
      EndIf
    Wend

    If Buf <> ""
      AddElement(RunStyle()) : RunStyle() = CurStyle
      AddElement(RunText())  : RunText()  = Buf
      PlainText + Buf
    EndIf
  Next

  Protected *Buffer = UTF8(PlainText)
  ScintillaSendMessage(Sci, #SCI_SETREADONLY, 0)
  ScintillaSendMessage(Sci, #SCI_SETTEXT, 0, *Buffer)
  FreeMemory(*Buffer)

  ScintillaSendMessage(Sci, #SCI_STARTSTYLING, 0, 0)
  ResetList(RunStyle()) : ResetList(RunText())
  While NextElement(RunStyle()) And NextElement(RunText())
    GenMdHelp_EmitRun(Sci, RunText(), RunStyle())
  Wend

  ScintillaSendMessage(Sci, #SCI_SETREADONLY, 1)
  ScintillaSendMessage(Sci, #SCI_EMPTYUNDOBUFFER)
  ScintillaSendMessage(Sci, #SCI_GOTOPOS, 0)
EndProcedure

; Renderiza texto puro/verbatim (SEM passar pelo parser de markdown) num
; unico estilo monoespacado (#GenMdHelp_Style_Code) - usado pra exemplos de
; codigo de verdade (.bas), que NAO sao markdown: rodar um .bas por
; GenMdHelp_RenderMarkdown() interpretaria "**"/"`"/"[texto](url)" que
; aparecem legitimamente em BASIC (ex.: PRINT "**", A$(I)) como marcacao,
; corrompendo a exibicao. Aqui todo byte vira o mesmo estilo, sem parsing.
Procedure GenMdHelp_RenderPlainCode(Sci, Text.s)
  Protected *Buffer = UTF8(Text)
  ScintillaSendMessage(Sci, #SCI_SETREADONLY, 0)
  ScintillaSendMessage(Sci, #SCI_SETTEXT, 0, *Buffer)
  Protected ByteLen = StringByteLength(Text, #PB_UTF8)
  FreeMemory(*Buffer)

  ScintillaSendMessage(Sci, #SCI_STARTSTYLING, 0, 0)
  If ByteLen > 0
    ScintillaSendMessage(Sci, #SCI_SETSTYLING, ByteLen, #GenMdHelp_Style_Code)
  EndIf

  ScintillaSendMessage(Sci, #SCI_SETREADONLY, 1)
  ScintillaSendMessage(Sci, #SCI_EMPTYUNDOBUFFER)
  ScintillaSendMessage(Sci, #SCI_GOTOPOS, 0)
EndProcedure

; Le FolderPath + "_index.json" (manifesto gravado pelo downloader - array de
; {"file":..., "title":..., "group":...}) para dentro de State\Topics(). Malformado/
; ausente -> lista vazia (chamador decide o que fazer).
Procedure GenMdHelp_LoadIndex(*State.GenMdHelp_WindowState)
  ClearList(*State\Topics())
  Protected IndexPath.s = *State\FolderPath + "_index.json"
  If FileSize(IndexPath) <= 0
    ProcedureReturn
  EndIf

  Protected Json = LoadJSON(#PB_Any, IndexPath)
  If Not Json
    ProcedureReturn
  EndIf

  Protected RootElem = JSONValue(Json)
  Protected N = JSONArraySize(RootElem)
  Protected Idx, Item, M
  For Idx = 0 To N - 1
    Item = GetJSONElement(RootElem, Idx)
    If Item
      AddElement(*State\Topics())
      M = GetJSONMember(Item, "file")  : If M : *State\Topics()\File  = GetJSONString(M) : EndIf
      M = GetJSONMember(Item, "title") : If M : *State\Topics()\Title = GetJSONString(M) : EndIf
      M = GetJSONMember(Item, "group") : If M : *State\Topics()\Group = GetJSONString(M) : EndIf
    EndIf
  Next
  FreeJSON(Json)
EndProcedure

; Contraparte de GenMdHelp_LoadIndex(): grava FolderPath + "_index.json" a
; partir de uma lista de topicos - usado pelos downloaders
; (MsxBas2RomSupport.pbi/N80Support.pbi) depois de salvar cada .md de
; conteudo, pra fechar o manifesto que GenMdHelp_OpenWindow() espera.
Procedure GenMdHelp_SaveIndex(FolderPath.s, List Topics.GenMdHelp_TopicItem())
  Protected Json = CreateJSON(#PB_Any)
  Protected Root = SetJSONArray(JSONValue(Json))
  Protected Elem

  ForEach Topics()
    Elem = AddJSONElement(Root)
    SetJSONObject(Elem)
    SetJSONString(AddJSONMember(Elem, "file"), Topics()\File)
    SetJSONString(AddJSONMember(Elem, "title"), Topics()\Title)
    SetJSONString(AddJSONMember(Elem, "group"), Topics()\Group)
  Next

  SaveJSON(Json, FolderPath + "_index.json", #PB_JSON_PrettyPrint)
  FreeJSON(Json)
EndProcedure

; Combina NewTopics() no _index.json JA existente em FolderPath, sem
; apagar topicos de OUTROS downloads que compartilham a mesma pasta de Ajuda
; (ex.: MSXBas2Rom tem "Atualizar documentacao"/"Baixar exemplos"/"Baixar
; jogos" gravando no mesmo _index.json em passos separados - cada botao so
; deve substituir os topicos que ELE MESMO gera, nao apagar os dos outros).
; "Dono" de um grupo = qualquer grupo que aparece em NewTopics(); todo topico
; JA no index cujo Group bate com um desses e descartado (sera substituido
; pela versao nova), o resto sobrevive intacto.
Procedure GenMdHelp_MergeIndex(FolderPath.s, List NewTopics.GenMdHelp_TopicItem())
  NewList OwnedGroups.s()
  ForEach NewTopics()
    Protected Found.b = #False
    ForEach OwnedGroups()
      If OwnedGroups() = NewTopics()\Group
        Found = #True
        Break
      EndIf
    Next
    If Not Found
      AddElement(OwnedGroups())
      OwnedGroups() = NewTopics()\Group
    EndIf
  Next

  Protected *State.GenMdHelp_WindowState = AllocateStructure(GenMdHelp_WindowState)
  *State\FolderPath = FolderPath
  GenMdHelp_LoadIndex(*State)

  NewList Merged.GenMdHelp_TopicItem()
  ForEach *State\Topics()
    Protected Owned.b = #False
    ForEach OwnedGroups()
      If OwnedGroups() = *State\Topics()\Group
        Owned = #True
        Break
      EndIf
    Next
    If Not Owned
      AddElement(Merged())
      Merged() = *State\Topics()
    EndIf
  Next
  ForEach NewTopics()
    AddElement(Merged())
    Merged() = NewTopics()
  Next

  GenMdHelp_SaveIndex(FolderPath, Merged())
  FreeStructure(*State)
EndProcedure

Procedure GenMdHelp_PopulateTree(Tree, *State.GenMdHelp_WindowState)
  ClearGadgetItems(Tree)
  Protected Idx = -1
  Protected LastGroup.s = Chr(1) ; sentinela, nunca bate com um Group real

  ForEach *State\Topics()
    Idx + 1
    If *State\Topics()\Group <> "" And *State\Topics()\Group <> LastGroup
      AddGadgetItem(Tree, -1, *State\Topics()\Group, 0, 0)
      LastGroup = *State\Topics()\Group
    EndIf
    Protected SubLevel = 0
    If *State\Topics()\Group <> "" : SubLevel = 1 : EndIf
    AddGadgetItem(Tree, -1, *State\Topics()\Title, 0, SubLevel)
    SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, Idx)
  Next
EndProcedure

Procedure GenMdHelp_FilterTree(Tree, *State.GenMdHelp_WindowState, SearchText.s)
  Protected Needle.s = LCase(Trim(SearchText))
  If Needle = ""
    GenMdHelp_PopulateTree(Tree, *State)
    ProcedureReturn
  EndIf

  ClearGadgetItems(Tree)
  Protected Idx = -1
  ForEach *State\Topics()
    Idx + 1
    If FindString(LCase(*State\Topics()\Title + " " + *State\Topics()\Group), Needle) > 0
      Protected Label.s = *State\Topics()\Title
      If *State\Topics()\Group <> ""
        Label + " (" + *State\Topics()\Group + ")"
      EndIf
      AddGadgetItem(Tree, -1, Label, 0, 0)
      SetGadgetItemData(Tree, CountGadgetItems(Tree) - 1, Idx)
    EndIf
  Next
EndProcedure

Procedure.s GenMdHelp_ReadTopicFile(*State.GenMdHelp_WindowState, TopicIdx.i)
  If Not SelectElement(*State\Topics(), TopicIdx)
    ProcedureReturn ""
  EndIf
  Protected Path.s = *State\FolderPath + *State\Topics()\File
  Protected FileNum = ReadFile(#PB_Any, Path, #PB_File_BOM)
  If Not FileNum
    ProcedureReturn "# Arquivo nao encontrado" + #CRLF$ + #CRLF$ + Path
  EndIf
  Protected Text.s = ""
  While Not Eof(FileNum)
    Text + ReadString(FileNum, #PB_File_IgnoreEOL) + #CRLF$
  Wend
  CloseFile(FileNum)
  ProcedureReturn Text
EndProcedure

; Despacha pra GenMdHelp_RenderPlainCode() (codigo-fonte verbatim) ou
; GenMdHelp_RenderMarkdown() (prosa) de acordo com a extensao do arquivo do
; topico - unico ponto de decisao, usado nos 3 lugares que renderizam um
; topico em GenMdHelp_OpenWindow() (abertura inicial, troca de topico na
; arvore, Voltar), pra nao repetir a logica de extensao em cada um.
Procedure GenMdHelp_RenderTopic(Sci, *State.GenMdHelp_WindowState, TopicIdx.i)
  If Not SelectElement(*State\Topics(), TopicIdx)
    ProcedureReturn
  EndIf
  Protected Content.s = GenMdHelp_ReadTopicFile(*State, TopicIdx)
  If LCase(Right(*State\Topics()\File, 4)) = ".bas"
    GenMdHelp_RenderPlainCode(Sci, Content)
  Else
    GenMdHelp_RenderMarkdown(Sci, Content)
  EndIf
EndProcedure

; Janela generica de Ajuda orientada a pasta. Title vai na barra de titulo;
; FolderPath e a pasta (com "\" no final) onde o downloader correspondente
; salvou os .md + _index.json. Se nunca foi baixado (ou _index.json vazio),
; avisa e nao abre janela nenhuma - mais direto que abrir uma arvore vazia.
Procedure GenMdHelp_OpenWindow(ParentWindow, Title.s, FolderPath.s)
  Protected *State.GenMdHelp_WindowState = AllocateStructure(GenMdHelp_WindowState)
  *State\FolderPath = FolderPath
  GenMdHelp_LoadIndex(*State)

  If ListSize(*State\Topics()) = 0
    FreeStructure(*State)
    MessageRequester(Title,
                     "Nada baixado ainda." + Chr(10) +
                     "Use a tela de Configurar correspondente e clique em " + Chr(34) + "Baixar" + Chr(34) + " primeiro.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
    ProcedureReturn
  EndIf

  Protected WinW = 940, WinH = 620
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, Title,
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #False)
  If Not Win
    FreeStructure(*State)
    ProcedureReturn
  EndIf

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
  Protected G_Content = ScintillaGadget(#PB_Any, 24 + TreeW + 24, TreeY, WinW - TreeW - 72, TreeH, @GenMdHelp_ScintillaCallback())
  GenMdHelp_SetupStyles(G_Content)
  ScintillaSendMessage(G_Content, #SCI_SETMOUSEDOWNCAPTURES, 1, 0)

  Protected G_Back = ThemedButton(24, ButtonY, 180, 32, "<- Voltar (Alt+Esquerda)", Chr(#Icon_ArrowLeft))
  GadgetToolTip(G_Back, "<- Voltar (Alt+Esquerda)")
  Protected G_Close = ThemedButton(WinW - 24 - 110, ButtonY, 110, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  GenMdHelp_PopulateTree(G_Tree, *State)
  AddKeyboardShortcut(Win, #PB_Shortcut_Alt | #PB_Shortcut_Left, #GenMdHelp_ShortcutBack)

  NewList History.i()
  Protected CurrentTopic.i = -1
  Protected BackIdx.i, TreeScanIdx.i

  ; Macro (nao Procedure) de proposito, mesmo motivo de NBHelpGui_DoGoBack em
  ; NestorBasicHelpGui.pbi: precisa acessar direto as locais desta janela.
  Macro GenMdHelp_DoGoBack
    If ListSize(History()) > 0
      LastElement(History())
      BackIdx = History()
      DeleteElement(History())
      If BackIdx >= 0
        GenMdHelp_RenderTopic(G_Content, *State, BackIdx)
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

  GenMdHelp_RenderTopic(G_Content, *State, 0)
  CurrentTopic = 0
  SetGadgetState(G_Tree, 0)

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
                  GenMdHelp_RenderTopic(G_Content, *State, TopicIdx)
                  CurrentTopic = TopicIdx
                EndIf
              EndIf
            EndIf

          Case G_Search
            If EventType() = #PB_EventType_Change
              GenMdHelp_FilterTree(G_Tree, *State, GetGadgetText(G_Search))
              If Trim(GetGadgetText(G_Search)) <> ""
                SetGadgetText(G_Status, Str(CountGadgetItems(G_Tree)) + " resultado(s)")
              Else
                SetGadgetText(G_Status, "")
              EndIf
            EndIf

          Case G_ClearSearch
            SetGadgetText(G_Search, "")
            GenMdHelp_FilterTree(G_Tree, *State, "")
            SetGadgetText(G_Status, "")

          Case G_Back
            GenMdHelp_DoGoBack

          Case G_Close
            Quit = #True

        EndSelect

      Case #PB_Event_Menu
        If EventMenu() = #GenMdHelp_ShortcutBack
          GenMdHelp_DoGoBack
        EndIf

      Case #PB_Event_CloseWindow
        Quit = #True

    EndSelect
  Until Quit

  FreeStructure(*State)
  CloseModelessChildWindow(ParentWindow, Win, #False)
EndProcedure
