;
; ------------------------------------------------------------
;  Visualizador de arquivos .MD (Executar -> Ver MD/TXT... / Ver MD+TXT...) -
;  duas janelas auxiliares sobre o conteudo da aba ativa quando ela esta em
;  modo "MD" (ver Docs()\Mode, AddDocumentTab() em BadigEditor.pb).
;
;  MdView_OpenSingle: pop-up somente leitura com um alternador TXT/MD -
;  reaproveita o motor de renderizacao de GenericMdHelpGui.pbi
;  (GenMdHelp_SetupStyles/GenMdHelp_RenderMarkdown) para o modo "MD"; o modo
;  "TXT" mostra o texto cru, sem realce. O conteudo e um retrato (snapshot)
;  tirado no momento de abrir - nao acompanha edicoes feitas depois na aba,
;  mesmo padrao das demais janelas auxiliares deste app.
;
;  MdView_OpenSplit: pop-up com dois ScintillaGadget lado a lado - esquerda
;  editavel (mesmo realce de HighlightMarkdownText usado na propria aba),
;  direita somente leitura (GenMdHelp_RenderMarkdown), atualizada a cada
;  tecla. A cada mudanca no painel esquerdo o texto tambem e gravado de volta
;  no ScintillaGadget REAL da aba de origem (Docs()\SciGadget) - e assim que a
;  edicao "ao vivo" persiste no documento (confirmado com o usuario: o painel
;  TXT do modo hibrido edita o documento de verdade, nao uma copia
;  descartavel). Isso e seguro porque esta janela roda seu proprio loop local
;  de WaitWindowEvent() - a janela principal fica bloqueada (nao processa
;  cliques na tab bar) enquanto ela estiver aberta, entao o gadget da aba
;  capturado no Open() continua valido durante toda a edicao. A propria
;  escrita no gadget real dispara SCN_MODIFIED -> #Event_Rehighlight (fila de
;  #MainWindow, ver ScintillaCallBack() em BadigEditor.pb) - quando esta
;  janela fechar e o loop principal retomar, Docs()\Modified e a legenda da
;  aba se atualizam sozinhos, sem nada extra a fazer aqui.
; ------------------------------------------------------------
;

#MdView_Event_Changed = #PB_Event_FirstCustomValue + 50

; So existe uma janela hibrida por vez (o loop proprio dela bloqueia a janela
; principal, entao o menu nao pode reabrir outra por cima) - globais em vez de
; passar contexto extra porque a assinatura do callback do Scintilla e fixa.
Global MdView_HybridWin
Global MdView_HybridTargetSci
Global MdView_SuppressHybridChange.b = #False

Procedure.b MdView_CheckActiveIsMD(TituloJanela.s)
  Protected Position = ActiveTabPosition
  If Position < 0 Or Not SelectElement(Docs(), Position)
    ProcedureReturn #False
  EndIf
  If Docs()\Mode <> "MD"
    MessageRequester(TituloJanela,
                     "A aba ativa nao e um arquivo .MD." + Chr(10) +
                     "Esta funcao e so para arquivos MD (Arquivo -> Novo MD...).",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
    ProcedureReturn #False
  EndIf
  ProcedureReturn #True
EndProcedure

Procedure MdView_HybridScintillaCallback(Gadget, *scinotify.SCNotification)
  If *scinotify\nmhdr\code = #SCN_MODIFIED
    If (*scinotify\modificationType & (#SC_MOD_INSERTTEXT | #SC_MOD_DELETETEXT)) And Not MdView_SuppressHybridChange
      PostEvent(#MdView_Event_Changed, MdView_HybridWin, Gadget, 0, 0)
    EndIf
  EndIf
EndProcedure

Procedure MdView_OpenSingle(ParentWindow)
  If Not MdView_CheckActiveIsMD("Ver MD/TXT")
    ProcedureReturn
  EndIf
  Protected RawText.s = ReadSciText(Docs()\SciGadget)

  Protected WinW = 800, WinH = 600
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Ver MD/TXT",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #False)
  If Not Win
    ProcedureReturn
  EndIf

  Protected TopY = 24
  Protected G_BtnTxt = ThemedButton(24, TopY, 90, 28, "TXT", "")
  Protected G_BtnMd  = ThemedButton(126, TopY, 90, 28, "MD", "")
  Protected G_Close  = ThemedButton(WinW - 24 - 100, TopY, 100, 28, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  Protected ContentY = TopY + 28 + 16
  Protected G_Content = ScintillaGadget(#PB_Any, 24, ContentY, WinW - 48, WinH - ContentY - 24, 0)
  ScintillaSendMessage(G_Content, #SCI_SETMOUSEDOWNCAPTURES, 1, 0)

  GenMdHelp_SetupStyles(G_Content)
  GenMdHelp_RenderMarkdown(G_Content, RawText)
  Protected ShowingMd.b = #True

  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event

      Case #PB_Event_Gadget
        Select EventGadget()

          Case G_BtnMd
            If Not ShowingMd
              GenMdHelp_SetupStyles(G_Content)
              GenMdHelp_RenderMarkdown(G_Content, RawText)
              ShowingMd = #True
            EndIf

          Case G_BtnTxt
            If ShowingMd
              ScintillaSendMessage(G_Content, #SCI_SETREADONLY, 0)
              ScintillaSendMessage(G_Content, #SCI_STYLECLEARALL)
              ScintillaSendMessage(G_Content, #SCI_STYLESETFORE, #STYLE_DEFAULT, RGB(30, 30, 30))
              ScintillaSendMessage(G_Content, #SCI_STYLESETBACK, #STYLE_DEFAULT, RGB(255, 255, 255))
              WriteSciText(G_Content, RawText)
              ScintillaSendMessage(G_Content, #SCI_SETREADONLY, 1)
              ScintillaSendMessage(G_Content, #SCI_EMPTYUNDOBUFFER)
              ShowingMd = #False
            EndIf

          Case G_Close
            Quit = #True

        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True

    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win, #False)
EndProcedure

Procedure MdView_OpenSplit(ParentWindow)
  If Not MdView_CheckActiveIsMD("Ver MD+TXT")
    ProcedureReturn
  EndIf
  Protected TargetSci = Docs()\SciGadget
  Protected RawText.s = ReadSciText(TargetSci)

  Protected WinW = 1100, WinH = 650
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Ver MD+TXT",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #False)
  If Not Win
    ProcedureReturn
  EndIf

  Protected TopY = 24
  Protected HalfW = (WinW - 72) / 2
  TextGadget(#PB_Any, 24, TopY, HalfW, 20, "TXT (editavel)")
  TextGadget(#PB_Any, 24 + HalfW + 24, TopY, HalfW, 20, "MD (previa)")

  Protected ButtonY = WinH - 56
  Protected ContentY = TopY + 20 + 8
  Protected ContentH = ButtonY - 16 - ContentY
  Protected G_Left  = ScintillaGadget(#PB_Any, 24, ContentY, HalfW, ContentH, @MdView_HybridScintillaCallback())
  Protected G_Right = ScintillaGadget(#PB_Any, 24 + HalfW + 24, ContentY, HalfW, ContentH, 0)
  Protected G_Close = ThemedButton(WinW - 24 - 110, ButtonY, 110, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  MdView_HybridWin = Win
  MdView_HybridTargetSci = TargetSci

  SetupEditorStyles(G_Left)
  MdView_SuppressHybridChange = #True
  WriteSciText(G_Left, RawText)
  ScintillaSendMessage(G_Left, #SCI_EMPTYUNDOBUFFER)
  MdView_SuppressHybridChange = #False
  HighlightMarkdownText(G_Left, RawText)

  GenMdHelp_SetupStyles(G_Right)
  GenMdHelp_RenderMarkdown(G_Right, RawText)

  Protected Event, Quit = #False, ChangedText.s
  Repeat
    Event = WaitWindowEvent()
    Select Event

      Case #MdView_Event_Changed
        ChangedText = ReadSciText(G_Left)
        HighlightMarkdownText(G_Left, ChangedText)
        GenMdHelp_RenderMarkdown(G_Right, ChangedText)
        WriteSciText(MdView_HybridTargetSci, ChangedText)

      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_Close
            Quit = #True
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True

    EndSelect
  Until Quit

  MdView_HybridWin = 0
  MdView_HybridTargetSci = 0
  CloseModelessChildWindow(ParentWindow, Win, #False)
EndProcedure
