;
; ------------------------------------------------------------
;  BadigOutputGui.pbi - janela generica de saida com rolagem, somente
;  leitura, para mostrar o log de verbosidade e os relatorios do Basic
;  Dignified (ver BadigLog.pbi, DignifiedPreprocessor.pbi, MsxTokenizer.pbi).
;  Mesmo formato de janela "mostrar um texto pronto uma vez" ja usado pelo
;  projeto em Z80Out_ShowListing (assemblers/Z80OutputGui.pbi), com a cor do
;  tema real do editor (Color_EditorBg/Color_TextActive, mesmo padrao de
;  HexEditorGui.pbi - NAO as cores fixas MSX do log do Mamute Assembler, que
;  ignoram o tema escolhido pelo usuario).
; ------------------------------------------------------------
;

EnableExplicit

Procedure BadigOutput_Show(ParentWindow.i, Title.s, BodyText.s)
  Protected WinW = 720, WinH = 480
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, Title,
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_SizeGadget)
  If Not Win
    ProcedureReturn
  EndIf

  Protected G_Text = EditorGadget(#PB_Any, 24, 24, WinW - 48, WinH - 88, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
  SetGadgetColor(G_Text, #PB_Gadget_BackColor, Color_EditorBg)
  SetGadgetColor(G_Text, #PB_Gadget_FrontColor, Color_TextActive)

  Protected DisplayText.s = BodyText
  If DisplayText = ""
    DisplayText = "(sem mensagens neste nivel de verbosidade)"
  EndIf
  SetGadgetText(G_Text, DisplayText)

  Protected G_Copy = ThemedButton(24, WinH - 56, 110, 32, "Copiar", Chr(#Icon_Copy))
  GadgetToolTip(G_Copy, "Copiar para a area de transferencia")
  Protected G_Close = ThemedButton(WinW - 134, WinH - 56, 110, 32, "Fechar", Chr(#Icon_Close))

  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_Copy
            SetClipboardText(GetGadgetText(G_Text))
          Case G_Close
            Quit = #True
        EndSelect
      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
