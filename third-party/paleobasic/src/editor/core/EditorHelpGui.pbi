;
; ------------------------------------------------------------
;  Ajuda -> Editor: janela estatica com os atalhos de teclado do editor
;  principal (padrao Scintilla/Windows - setas, Ctrl+C/V/X/Z/Y, Home/End
;  etc. - mais os atalhos proprios do app: Buscar/Substituir/Ir para linha,
;  Novo/Abrir/Salvar/Fechar aba, Executar/Montar). Reaproveita o motor de
;  renderizacao markdown de GenericMdHelpGui.pbi (mesmo estilo visual das
;  demais telas de Ajuda), so que com conteudo fixo embutido no .exe em vez
;  de vir de uma pasta baixada em tempo de execucao.
; ------------------------------------------------------------
;

Procedure.s EditorHelp_ShortcutsMarkdown()
  Protected T.s

  T + "# Atalhos do editor" + #CRLF$ + #CRLF$
  T + "O editor segue o teclado padrao do Scintilla/Windows - nao ha mais um modo" + #CRLF$
  T + "de teclas proprio (o antigo teclado estilo WordStar/JOE foi removido)." + #CRLF$ + #CRLF$

  T + "## Cursor e selecao" + #CRLF$ + #CRLF$
  T + "- `Setas` move o cursor - com `Shift` seleciona" + #CRLF$
  T + "- `Ctrl+Seta esquerda/direita` pula palavra - com `Shift` seleciona a palavra" + #CRLF$
  T + "- `Home` / `End` inicio / fim da linha" + #CRLF$
  T + "- `Ctrl+Home` / `Ctrl+End` inicio / fim do arquivo" + #CRLF$
  T + "- `Page Up` / `Page Down` rola uma tela" + #CRLF$
  T + "- `Ctrl+A` seleciona tudo" + #CRLF$ + #CRLF$

  T + "## Editar" + #CRLF$ + #CRLF$
  T + "- `Ctrl+C` / `Ctrl+X` / `Ctrl+V` copiar / recortar / colar" + #CRLF$
  T + "- `Ctrl+Z` / `Ctrl+Y` desfazer / refazer" + #CRLF$
  T + "- `Delete` / `Backspace` apaga caractere - com `Ctrl` apaga a palavra" + #CRLF$
  T + "- `Insert` alterna inserir/sobrescrever" + #CRLF$
  T + "- `Tab` / `Shift+Tab` indenta / remove indentacao da selecao" + #CRLF$ + #CRLF$

  T + "## Buscar" + #CRLF$ + #CRLF$
  T + "- `Ctrl+F` buscar" + #CRLF$
  T + "- `F3` buscar proxima ocorrencia" + #CRLF$
  T + "- `Ctrl+H` substituir" + #CRLF$
  T + "- `Ctrl+G` ir para linha" + #CRLF$ + #CRLF$

  T + "## Arquivo" + #CRLF$ + #CRLF$
  T + "- `Ctrl+N` nova aba - `Ctrl+Shift+N` novo Assembly" + #CRLF$
  T + "- `Ctrl+O` abrir" + #CRLF$
  T + "- `Ctrl+S` salvar - `Ctrl+Shift+S` salvar como - `Ctrl+Alt+S` salvar tudo" + #CRLF$
  T + "- `Ctrl+W` fechar aba" + #CRLF$
  T + "- `Ctrl+Alt+N` novo projeto - `Ctrl+Alt+O` abrir projeto" + #CRLF$ + #CRLF$

  T + "## Executar" + #CRLF$ + #CRLF$
  T + "- `F5` executar BASIC no openMSX - `Shift+F5` executar Nestor Basic" + #CRLF$
  T + "- `F6` renumerar" + #CRLF$
  T + "- `Ctrl+F5` montar Assembly (.bin) - `Ctrl+Shift+F5` montar relocavel (.REL)" + #CRLF$
  T + "- `Ctrl+Alt+F5` linkar (.REL -> binario)" + #CRLF$
  T + "- `F7` editor hexadecimal" + #CRLF$
  T + "- `F8` console de comandos do openMSX" + #CRLF$
  T + "- `F9` ver MD/TXT - `Shift+F9` ver MD+TXT lado a lado" + #CRLF$ + #CRLF$

  T + "## Criar (editores visuais)" + #CRLF$ + #CRLF$
  T + "- `Ctrl+Shift+D` disco" + #CRLF$
  T + "- `Ctrl+Shift+P` sprite" + #CRLF$
  T + "- `Ctrl+Shift+A` alfabeto Graphos III" + #CRLF$
  T + "- `Ctrl+Shift+G` som (PSG)" + #CRLF$
  T + "- `Ctrl+Shift+T` SEE Tracker" + #CRLF$
  T + "- `Ctrl+Shift+M` musica (PLAY/MML)" + #CRLF$
  T + "- `Ctrl+Shift+2` draw Screen 2 - `Ctrl+Shift+0` Screen 0 - `Ctrl+Shift+1` Screen 1" + #CRLF$
  T + "- Alfabeto Aquarela, Graphos III Screen 2, Screen 1+2, Biblioteca Z80 e Assembly Sub" + #CRLF$
  T + "  Project ficam so no menu **Criar** (variantes menos usadas dos itens acima)." + #CRLF$ + #CRLF$

  T + "## Inserir / Configurar / Ajuda" + #CRLF$ + #CRLF$
  T + "- `Ctrl+Alt+I` caractere especial" + #CRLF$
  T + "- `Ctrl+Alt+E` Configurar -> Editor..." + #CRLF$
  T + "- `F1` esta ajuda" + #CRLF$

  ProcedureReturn T
EndProcedure

Procedure EditorHelp_OpenWindow(ParentWindow)
  Protected WinW = 680, WinH = 760
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Ajuda - Editor",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #False)
  If Not Win
    ProcedureReturn
  EndIf

  Protected ButtonY = WinH - 56
  Protected G_Content = ScintillaGadget(#PB_Any, 24, 24, WinW - 48, ButtonY - 40, 0)
  GenMdHelp_SetupStyles(G_Content)

  Protected G_Close = ThemedButton(WinW - 24 - 110, ButtonY, 110, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  GenMdHelp_RenderMarkdown(G_Content, EditorHelp_ShortcutsMarkdown())

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

  CloseModelessChildWindow(ParentWindow, Win, #False)
EndProcedure
