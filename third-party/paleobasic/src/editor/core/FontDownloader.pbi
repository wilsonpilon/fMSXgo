;
; ------------------------------------------------------------
;  Download de fontes Nerd Fonts (https://www.nerdfonts.com/font-downloads)
;  A pagina e estatica (server-side), entao a lista de fontes disponiveis e
;  obtida em tempo real via uma requisicao HTTP simples (ReceiveHTTPMemory) +
;  expressao regular sobre o HTML - sem precisar embutir/manter uma lista fixa
;  de nomes ou a versao do release do GitHub (ex.: v3.4.0) no codigo.
;  GET de pagina/download+extracao de .zip/bombeio de eventos reaproveitam os
;  helpers de ExtTool_* (ExternalToolDownload.pbi, ja usados por
;  MsxBas2RomSupport.pbi/N80Support.pbi) em vez de duplica-los - inclusive a
;  criacao recursiva de pasta de destino (ExtTool_CreateDirectoryRecursive),
;  que a versao antiga daqui nao tinha. Os arquivos das fontes (.ttf/.otf)
;  ficam prontos para uso em "Pasta de fontes customizadas" (ver
;  EditorSettings.pbi).
; ------------------------------------------------------------
;

#NerdFonts_PageUrl = "https://www.nerdfonts.com/font-downloads"

Structure NerdFontEntry
  Name.s
  Url.s
EndStructure

Global NewList NerdFontEntries.NerdFontEntry()

;- ------------------------------------------------------------
;- Lista de fontes disponiveis (obtida da pagina da Nerd Fonts)
;- ------------------------------------------------------------

; Preenche NerdFontEntries() com nomes unicos (ordenados) e a URL do .zip de
; cada fonte, lendo direto da pagina de downloads (sem versao fixa embutida).
Procedure.b FontDownloader_FetchList()
  ClearList(NerdFontEntries())

  Protected Html.s = ExtTool_HttpGetText(#NerdFonts_PageUrl)
  If Html = ""
    ProcedureReturn #False
  EndIf

  Protected Regex = CreateRegularExpression(#PB_Any, "https://github\.com/ryanoasis/nerd-fonts/releases/download/[A-Za-z0-9_.\-/]+\.zip")
  If Not Regex
    ProcedureReturn #False
  EndIf

  Dim Matches.s(0)
  Protected Count = ExtractRegularExpression(Regex, Html, Matches())
  FreeRegularExpression(Regex)

  Protected i, Url.s, Name.s, Found.b
  For i = 0 To Count - 1
    Url = Matches(i)
    Name = GetFilePart(Url)
    If Right(Name, 4) = ".zip"
      Name = Left(Name, Len(Name) - 4)
    EndIf
    If Name = ""
      Continue
    EndIf

    Found = #False
    ForEach NerdFontEntries()
      If NerdFontEntries()\Name = Name
        Found = #True
        Break
      EndIf
    Next
    If Not Found
      AddElement(NerdFontEntries())
      NerdFontEntries()\Name = Name
      NerdFontEntries()\Url = Url
    EndIf
  Next

  SortStructuredList(NerdFontEntries(), #PB_Sort_Ascending, OffsetOf(NerdFontEntry\Name), #PB_String)

  ProcedureReturn Bool(ListSize(NerdFontEntries()) > 0)
EndProcedure

;- ------------------------------------------------------------
;- Janela de download
;- ------------------------------------------------------------

Procedure FontDownloader_PopulateListGadget(ListGadget)
  ClearGadgetItems(ListGadget)
  ForEach NerdFontEntries()
    AddGadgetItem(ListGadget, -1, NerdFontEntries()\Name)
  Next
EndProcedure

Procedure FontDownloader_SetBusy(StatusGadget, ListGadget, Btn1, Btn2, Btn3, Btn4, Btn5, Btn6, Btn7, Busy.b)
  DisableGadget(ListGadget, Busy)
  DisableGadget(Btn1, Busy)
  DisableGadget(Btn2, Busy)
  DisableGadget(Btn3, Busy)
  DisableGadget(Btn4, Busy)
  DisableGadget(Btn5, Busy)
  DisableGadget(Btn6, Busy)
  DisableGadget(Btn7, Busy)
  If Busy
    SetGadgetText(StatusGadget, "Preparando...")
  Else
    SetGadgetText(StatusGadget, "")
  EndIf
  ExtTool_FlushEvents()
EndProcedure

; Baixa as fontes da lista de indices (posicoes em NerdFontEntries(), na mesma
; ordem em que foram inseridas no ListGadget) para TargetDir. Retorna a
; quantidade baixada com sucesso.
Procedure.i FontDownloader_RunDownloads(Win, StatusGadget, List Indexes.i(), TargetDir.s)
  Protected Total = ListSize(Indexes())
  If Total = 0
    ProcedureReturn 0
  EndIf

  Protected Idx, Done = 0, Ok = 0, Fail = 0
  Protected FailNames.s = ""

  ForEach Indexes()
    Idx = Indexes()
    Done + 1
    If SelectElement(NerdFontEntries(), Idx)
      SetGadgetText(StatusGadget, "Baixando " + Str(Done) + "/" + Str(Total) + ": " + NerdFontEntries()\Name + "...")
      ExtTool_FlushEvents()

      If ExtTool_DownloadAndExtractZip(NerdFontEntries()\Url, TargetDir)
        Ok + 1
      Else
        Fail + 1
        FailNames + Chr(10) + " - " + NerdFontEntries()\Name
      EndIf
    EndIf
  Next

  SetGadgetText(StatusGadget, "")

  If Fail = 0
    MessageRequester("Baixar fontes", Str(Ok) + " fonte(s) baixada(s) e extraida(s) em:" + Chr(10) + TargetDir,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
  Else
    MessageRequester("Baixar fontes", Str(Ok) + " fonte(s) baixada(s) com sucesso." + Chr(10) +
                     Str(Fail) + " falha(s) (verifique sua conexao):" + FailNames,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Warning)
  EndIf

  ProcedureReturn Ok
EndProcedure

; Abre a janela de download de fontes. Retorna a pasta de destino usada se ao
; menos uma fonte foi baixada com sucesso (para o chamador poder preencher o
; campo "Pasta de fontes customizadas"), ou "" caso contrario/cancelado.
Procedure.s FontDownloader_OpenWindow(ParentWindow, InitialFolder.s)
  Protected DefaultDir.s = InitialFolder
  If DefaultDir = ""
    ; Cache de fontes baixadas fica direto em dist\ (ao lado do .exe) -
    ; DIFERENTE de dist\editor\fonts\ (fonte padrao embutida, ver
    ; EditorCfg_BundledFontsFolder() acima), que fica DENTRO de editor\.
    DefaultDir = GetPathPart(ProgramFilename()) + "fonts"
  EndIf
  If Right(DefaultDir, 1) = "\" Or Right(DefaultDir, 1) = "/"
    DefaultDir = Left(DefaultDir, Len(DefaultDir) - 1)
  EndIf

  Protected WinW = 600, WinH = 558
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Baixar Fontes (Nerd Fonts)",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn ""
  EndIf

  TextGadget(#PB_Any, 24, 24, WinW - 48, 48,
    "Baixa fontes da colecao Nerd Fonts (nerdfonts.com), extraindo automaticamente" + Chr(10) +
    "os arquivos .ttf/.otf na pasta abaixo. Selecione as fontes desejadas ou use" + Chr(10) +
    "'Baixar todas' para a colecao inteira (atencao: dezenas de arquivos grandes).")

  TextGadget(#PB_Any, 24, 88, 300, 20, "Pasta de destino")
  Protected G_TargetDir = StringGadget(#PB_Any, 24, 116, 464, 24, DefaultDir)
  Protected G_TargetDirBrowse = ThemedButton(496, 116, 80, 24, "...", "")

  Protected G_List = ListIconGadget(#PB_Any, 24, 156, WinW - 48, 250, "Fonte", WinW - 68,
                                     #PB_ListIcon_CheckBoxes | #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect)

  Protected G_Status = TextGadget(#PB_Any, 24, 422, WinW - 48, 20, "Carregando lista de fontes...")

  Protected G_SelectAll = ThemedButton(24, 458, 140, 28, "Selecionar todas", "")
  Protected G_SelectNone = ThemedButton(176, 458, 140, 28, "Limpar selecao", Chr(#Icon_Clear))
  GadgetToolTip(G_SelectNone, "Limpar selecao")
  Protected G_Reload = ThemedButton(328, 458, 110, 28, "Recarregar lista", Chr(#Icon_Refresh))
  GadgetToolTip(G_Reload, "Recarregar lista")

  Protected G_DownloadSelected = ThemedButton(24, 502, 180, 32, "Baixar selecionadas", "")
  Protected G_DownloadAll = ThemedButton(216, 502, 130, 32, "Baixar todas", "")
  Protected G_Close = ThemedButton(WinW - 24 - 100, 502, 100, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  ExtTool_FlushEvents()
  If FontDownloader_FetchList()
    FontDownloader_PopulateListGadget(G_List)
    SetGadgetText(G_Status, Str(ListSize(NerdFontEntries())) + " fonte(s) disponivel(is).")
  Else
    SetGadgetText(G_Status, "Falha ao carregar a lista (verifique sua conexao) - tente 'Recarregar lista'.")
  EndIf

  Protected Event, Quit = #False, DownloadedDir.s = "", TotalOk = 0
  Protected NewList Indexes.i()
  Protected i

  Repeat
    Event = WaitWindowEvent()

    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_TargetDirBrowse
            Protected Pick.s = PathRequester("Selecione a pasta de destino das fontes", GetGadgetText(G_TargetDir))
            If Pick <> ""
              SetGadgetText(G_TargetDir, Pick)
            EndIf

          Case G_SelectAll
            For i = 0 To CountGadgetItems(G_List) - 1
              SetGadgetItemState(G_List, i, #PB_ListIcon_Checked)
            Next

          Case G_SelectNone
            For i = 0 To CountGadgetItems(G_List) - 1
              SetGadgetItemState(G_List, i, 0)
            Next

          Case G_Reload
            SetGadgetText(G_Status, "Recarregando lista de fontes...")
            ExtTool_FlushEvents()
            If FontDownloader_FetchList()
              FontDownloader_PopulateListGadget(G_List)
              SetGadgetText(G_Status, Str(ListSize(NerdFontEntries())) + " fonte(s) disponivel(is).")
            Else
              SetGadgetText(G_Status, "Falha ao carregar a lista (verifique sua conexao).")
            EndIf

          Case G_DownloadSelected
            ClearList(Indexes())
            For i = 0 To CountGadgetItems(G_List) - 1
              If GetGadgetItemState(G_List, i) & #PB_ListIcon_Checked
                AddElement(Indexes()) : Indexes() = i
              EndIf
            Next
            If ListSize(Indexes()) = 0
              MessageRequester("Baixar fontes", "Selecione ao menos uma fonte na lista.", #PB_MessageRequester_Ok)
            ElseIf Trim(GetGadgetText(G_TargetDir)) = ""
              MessageRequester("Baixar fontes", "Informe a pasta de destino.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
            Else
              FontDownloader_SetBusy(G_Status, G_List, G_TargetDirBrowse, G_SelectAll, G_SelectNone, G_Reload, G_DownloadSelected, G_DownloadAll, G_Close, #True)
              TotalOk = FontDownloader_RunDownloads(Win, G_Status, Indexes(), GetGadgetText(G_TargetDir))
              FontDownloader_SetBusy(G_Status, G_List, G_TargetDirBrowse, G_SelectAll, G_SelectNone, G_Reload, G_DownloadSelected, G_DownloadAll, G_Close, #False)
              SetGadgetText(G_Status, Str(ListSize(NerdFontEntries())) + " fonte(s) disponivel(is).")
              If TotalOk > 0
                DownloadedDir = GetGadgetText(G_TargetDir)
              EndIf
            EndIf

          Case G_DownloadAll
            If ListSize(NerdFontEntries()) = 0
              MessageRequester("Baixar fontes", "A lista de fontes ainda nao foi carregada.", #PB_MessageRequester_Ok)
            ElseIf Trim(GetGadgetText(G_TargetDir)) = ""
              MessageRequester("Baixar fontes", "Informe a pasta de destino.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
            Else
              Protected Confirm = MessageRequester("Baixar fontes",
                "Isso ira baixar as " + Str(ListSize(NerdFontEntries())) + " fontes da Nerd Fonts (varios GB, alguns" + Chr(10) +
                "arquivos com centenas de MB) para:" + Chr(10) + GetGadgetText(G_TargetDir) + Chr(10) + Chr(10) +
                "A janela ficara sem responder durante os downloads. Continuar?",
                #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning)
              If Confirm = #PB_MessageRequester_Yes
                ClearList(Indexes())
                For i = 0 To CountGadgetItems(G_List) - 1
                  AddElement(Indexes()) : Indexes() = i
                Next
                FontDownloader_SetBusy(G_Status, G_List, G_TargetDirBrowse, G_SelectAll, G_SelectNone, G_Reload, G_DownloadSelected, G_DownloadAll, G_Close, #True)
                TotalOk = FontDownloader_RunDownloads(Win, G_Status, Indexes(), GetGadgetText(G_TargetDir))
                FontDownloader_SetBusy(G_Status, G_List, G_TargetDirBrowse, G_SelectAll, G_SelectNone, G_Reload, G_DownloadSelected, G_DownloadAll, G_Close, #False)
                SetGadgetText(G_Status, Str(ListSize(NerdFontEntries())) + " fonte(s) disponivel(is).")
                If TotalOk > 0
                  DownloadedDir = GetGadgetText(G_TargetDir)
                EndIf
              EndIf
            EndIf

          Case G_Close
            Quit = #True
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)

  ProcedureReturn DownloadedDir
EndProcedure
