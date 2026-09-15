;
; ------------------------------------------------------------
;  Comando XTP do Mamute Assembler - porta do comando TP do monitor SUPER-X
;  (docs/SPEC.md modulo 45/45r, inventario: "Exibe arquivo de texto
;  (paginado, ENTER/ESPACO/ESC)"). Pedido explicito do usuario: "XTP
;  <arquivo> Mostra o conteudo de um arquivo na tela, crie um read simples,
;  com botoes para rolar a tela para os lados, linha a linha, pagina a
;  pagina, como outros visualizadores do programa".
;
;  ACHADO REAL / correcao pos-implementacao (2026-08-26, ainda na mesma
;  sessao): a primeira versao deste comando lia <arquivo> como um caminho
;  do sistema de arquivos do HOST (Windows) - errado. O usuario reportou:
;  "abro um disco com XFS, ele mostra os arquivos, ai tento carregar um
;  arquivo mas ele mostra Arquivo Invalido" - <arquivo> e' um nome de
;  arquivo DENTRO do disco corrente (mesmo "disco corrente" do XFS/XCI,
;  modulos 45p/45q), nao um caminho do host - faz sentido, TP esta
;  agrupado na mesma familia de comandos de disco do SUPER-X (FS/CI/CD/BL/
;  SV/LD, inventario do modulo 45), nao um visualizador generico de
;  arquivo qualquer. Corrigido: MamuteGui_CmdXtp() (MamuteAssemblerGui.pbi)
;  agora usa MamuteGui_EnsureCurrentDisk() + MSXDisk::ExtractFile() pra um
;  arquivo temporario (GetTemporaryDirectory()), le DAQUELE arquivo
;  temporario, apaga na sequencia - MamuteXtp_Open() (aqui) nunca soube a
;  diferenca, so' ganhou um segundo parametro (DisplayName) pra mostrar o
;  nome de VERDADE (dentro do disco) no titulo da janela, nao o caminho
;  temporario.
;
;  SEGUNDO ACHADO REAL (bug de leitura de linhas, #PB_File_IgnoreEOL usado
;  errado) documentado em Mamute_ReadTextLines() abaixo, ja corrigido.
;
;  Visualizador SIMPLES e AUTOCONTIDO - nao tem nada a ver com memoria/
;  endereco/PAGE (diferente de XD/XA/XI/XM/XH), entao NAO tem cruz de modos
;  nenhuma. Le o arquivo INTEIRO pra uma lista de linhas na abertura
;  (Mamute_ReadTextLines() abaixo) e so' controla uma "janela" de
;  TopLine/LeftCol sobre essa lista - mesma tecnica ja usada pelo XI
;  (MamuteXiGui.pbi: mudar BaseAddr e chamar Repaint(), nunca depender do
;  scroll nativo do EditorGadget) - aqui aplicada nos DOIS eixos (vertical
;  E horizontal, porque texto de verdade pode ter linhas mais compridas que
;  a tela, ao contrario de uma linha de disassembly). EditorGadget somente-
;  leitura SEM #PB_Editor_WordWrap de proposito - cada linha mostrada ja
;  vem PRE-CORTADA na largura visivel certa (Mid() de LeftCol+1 por
;  #MamuteXtp_VisibleCols), entao nunca precisa de scroll nativo nenhum.
;
;  8 botoes de navegacao (ampliado de 6 pra 8 nesta sessao, pedido
;  explicito do usuario: "mais opcoes para rolar o texto como ir ao
;  inicio, ou ao fim") - MESMOS glifos "<<"/"<"/"^"/"v"/">"/">>" do XH
;  (MamuteXhGui.pbi) pra pagina/coluna/linha, mais "|<"/">| " novos nas
;  pontas pra inicio/fim do arquivo: "<<"/">>" = pagina inteira (vertical),
;  "<"/">" = rolagem lateral (horizontal, por #MamuteXtp_HScrollStep
;  colunas), "^"/"v" = linha a linha (vertical), "|<"/">|" = inicio/fim do
;  arquivo inteiro. Atalhos de teclado: setas nos 4 sentidos + PgUp/PgDn +
;  Home/End + Return/Esc (fecha) - mesma convencao do XI, mais Home/End
;  novos.
;
;  ACHADO REAL de contraste, corrigido nesta sessao ANTES do campo de
;  busca: o usuario reportou "os botoes ficaram muito escuros" depois de
;  escolher um tema claro (`XCO 1,15,15` = frente Preto, fundo/borda
;  Branco) - MamuteXd_DrawButton() (MamuteXdGui.pbi, reaproveitada por
;  TODAS as janelas com botao do Mamute) pintava o FUNDO do botao com um
;  verde escuro HARDCODED (RGB(0,45,18)), nunca migrado pro tema durante a
;  sessao do XCO (modulo 45n) - so' o contorno/texto usavam
;  Mamute_CurrentFrontColor(). Com frente=Preto, contorno/texto ficavam
;  pretos EM CIMA de um fundo verde-escuro quase preto tambem = baixissimo
;  contraste. Fix: fundo do botao agora e' Mamute_CurrentBackColor() (a
;  MESMA tecnica de "fundo=Back, contorno/texto=Front" que qualquer
;  combinacao de tema ja garante em todo o resto da UI) - corrigido em
;  TODAS as 7 copias dessa mesma funcao espalhadas pelo Mamute (XD/Dump/M/
;  Debugger/Scr/Zap - achado ao procurar o mesmo literal em outros
;  arquivos), nao so' aqui no XTP.
;
;  Campo de busca (pedido explicito do usuario: "coloque um campo de
;  busca, busca com Case ou sem Case, com e sem expressoes regulares") -
;  StringGadget + 2 CheckBoxGadget nativos (Case/Regex) + botao "Buscar"
;  (mesmo MamuteXd_DrawButton dos outros). Busca a partir de LOGO DEPOIS
;  da posicao atual (TopLine/LeftCol), com wraparound pro inicio se nao
;  achar ate o fim - MamuteXtp_DoSearch() abaixo. RETURN com o campo de
;  busca em foco aciona a busca em vez de fechar a janela (GetActiveGadget()
;  decide - mesmo raciocinio pras outras teclas de navegacao, que ficam
;  desligadas enquanto o campo de busca esta em foco, pra nao competir com
;  edicao de texto normal nele).
; ------------------------------------------------------------
;

#MamuteXtp_Shortcut_Up       = 9820
#MamuteXtp_Shortcut_Down     = 9821
#MamuteXtp_Shortcut_Left     = 9822
#MamuteXtp_Shortcut_Right    = 9823
#MamuteXtp_Shortcut_PageUp   = 9824
#MamuteXtp_Shortcut_PageDown = 9825
#MamuteXtp_Shortcut_Return   = 9826
#MamuteXtp_Shortcut_Escape   = 9827
#MamuteXtp_Shortcut_Home     = 9828
#MamuteXtp_Shortcut_End      = 9829

#MamuteXtp_VisibleRows  = 30  ; linhas mostradas de cada vez (aprox. - EditorGadget nao mede exato, mesma tolerancia do XI)
#MamuteXtp_VisibleCols  = 100 ; colunas mostradas de cada vez - alem disso, precisa rolar com "<"/">"
#MamuteXtp_HScrollStep  = 10  ; quantas colunas cada clique em "<"/">" anda

Structure MamuteXtpState
  TopLine.i  ; indice (0-based) da PRIMEIRA linha mostrada agora
  LeftCol.i  ; indice (0-based) da PRIMEIRA coluna mostrada agora
  LineCount.i
  ; Posicao do ULTIMO match de busca (independente de TopLine/LeftCol, que
  ; sao so' pra ENQUADRAR o match na tela) - "Buscar" de novo sempre
  ; continua a partir de LOGO DEPOIS do fim do match anterior, mesmo que o
  ; usuario tenha rolado a tela manualmente nesse meio tempo (mesmo
  ; comportamento de "Localizar proxima" de qualquer editor de texto de
  ; verdade). HasLastMatch=#False depois de uma busca SEM sucesso (o
  ; wraparound completo ja rodou, nao ha "proximo" de verdade pra
  ; continuar) - a busca seguinte recomeca da posicao de tela atual.
  HasLastMatch.b
  LastMatchLine.i
  LastMatchEnd.i ; posicao (1-based) logo APOS o ultimo caractere do match
EndStructure

; Le o arquivo INTEIRO pra Lines() (uma linha de texto por elemento) - uma
; chamada de ReadString() por linha, SEM #PB_File_IgnoreEOL. #True se
; conseguiu abrir.
;
; ACHADO REAL / bug corrigido (2026-08-26, ainda na mesma sessao): a
; primeira versao passava #PB_File_IgnoreEOL pra ReadString() - copiado
; por engano de GenMdHelp_LoadRaw() (GenericMdHelpGui.pbi), que usa essa
; flag porque so' quer o arquivo INTEIRO como uma string so (nao se
; importa em dividir por linha). Esse flag faz EXATAMENTE o oposto do que
; o nome sugere pra quem espera deteccao de EOL normal: ele faz
; ReadString() IGNORAR toda quebra de linha (CR/LF) e devolver o RESTO
; INTEIRO do arquivo numa unica chamada - com essa flag, o `While Not
; Eof()` abaixo rodava UMA UNICA VEZ (o arquivo inteiro virava "a linha
; 1"), entao TopLine/LeftCol (MamuteXtp_Repaint) so' tinham 1 elemento pra
; navegar. Usuario reportou o sintoma exato: "mostra 2 linhas e
; interrompe... mostra a linha 10 e a 20 do arquivo e parou" - o
; EditorGadget mostrava esse UNICO elemento gigante (com CRLFs
; embutidos como caracteres literais dentro da mesma string), mas cortado
; pelo Mid(LeftCol+1, #MamuteXtp_VisibleCols) do MESMO jeito que cortaria
; uma linha comum - so' que essa "linha" tinha o arquivo INTEIRO, entao
; so' os primeiros ~100 caracteres (que por coincidencia incluiam as
; linhas 10/20 do programa BASIC, ainda dentro da largura de corte)
; apareciam, e a "proxima linha" (elemento 2) nunca existia. Confirmado
; isolando Mamute_ReadTextLines() num .pb de teste separado, rodando
; contra o arquivo real extraido do disco do usuario (Count=1 com a flag,
; Count=589 sem ela). Fix: tirar a flag - ReadString() sozinho ja detecta
; CRLF/LF normalmente.
Procedure.b Mamute_ReadTextLines(FilePath.s, List Lines.s())
  ClearList(Lines())
  Protected FileNum = ReadFile(#PB_Any, FilePath, #PB_File_BOM)
  If Not FileNum
    ProcedureReturn #False
  EndIf
  While Not Eof(FileNum)
    AddElement(Lines())
    Lines() = ReadString(FileNum)
  Wend
  CloseFile(FileNum)
  ProcedureReturn #True
EndProcedure

; MaxTop = LineCount - VisibleRows (nunca deixa TopLine passar do ponto em
; que a ULTIMA pagina cheia ainda cabe na tela) - evita rolar pra baixo e
; sobrar so' 1 linha real com o resto da tela em branco; tambem e' o que
; faz "ir ao FIM" (MamuteXtp_DoEnd) mostrar a ultima pagina CHEIA em vez
; de so' a ultima linha isolada no topo.
Procedure MamuteXtp_ClampTop(*State.MamuteXtpState)
  Protected MaxTop.i = *State\LineCount - #MamuteXtp_VisibleRows
  If MaxTop < 0 : MaxTop = 0 : EndIf
  If *State\TopLine < 0 : *State\TopLine = 0 : EndIf
  If *State\TopLine > MaxTop : *State\TopLine = MaxTop : EndIf
  If *State\LeftCol < 0 : *State\LeftCol = 0 : EndIf
EndProcedure

; Recorta #MamuteXtp_VisibleRows linhas a partir de TopLine, cada uma so'
; com as #MamuteXtp_VisibleCols colunas a partir de LeftCol, e joga no
; EditorGadget de uma vez (SetGadgetText) - mesma tecnica do
; MamuteXi_Repaint() (nunca depende de scroll nativo).
Procedure MamuteXtp_Repaint(G_View, G_Status, List Lines.s(), *State.MamuteXtpState)
  MamuteXtp_ClampTop(*State)

  Protected Text.s = "", i.i, LineText.s
  Protected LastLine.i = *State\TopLine + #MamuteXtp_VisibleRows - 1
  If LastLine > *State\LineCount - 1 : LastLine = *State\LineCount - 1 : EndIf

  For i = *State\TopLine To LastLine
    SelectElement(Lines(), i)
    LineText = Lines()
    If *State\LeftCol < Len(LineText)
      LineText = Mid(LineText, *State\LeftCol + 1, #MamuteXtp_VisibleCols)
    Else
      LineText = ""
    EndIf
    If Text <> "" : Text + Chr(13) + Chr(10) : EndIf
    Text + LineText
  Next
  SetGadgetText(G_View, Text)

  SetGadgetText(G_Status, "LINHA " + Str(*State\TopLine + 1) + "-" + Str(LastLine + 1) + "/" +
                          Str(*State\LineCount) + "   COLUNA " + Str(*State\LeftCol + 1))
EndProcedure

; Busca SearchText a partir de logo depois da posicao atual (TopLine/
; LeftCol), com wraparound pro inicio do arquivo se nao achar ate o fim
; (2 passadas: TopLine-ate-o-fim, depois 0-ate-TopLine). CaseSensitive/
; UseRegex - pedido explicito do usuario ("busca com Case ou sem Case, com
; e sem expressoes regulares"). Regex compilada UMA VEZ so' (nao por
; linha) - CreateRegularExpression()/ExamineRegularExpression()/
; NextRegularExpressionMatch()/RegularExpressionMatchPosition(), API nativa
; do PureBasic. #True + tela repintada no match (SetGadgetText do status
; ja mostra a posicao nova); #False + status mostra "NAO ENCONTRADO" ou
; "?EXPRESSAO REGULAR INVALIDA" sem mexer em TopLine/LeftCol.
Procedure.b MamuteXtp_DoSearch(G_View, G_Status, List Lines.s(), *State.MamuteXtpState, SearchText.s, CaseSensitive.b, UseRegex.b)
  If SearchText = ""
    ProcedureReturn #False
  EndIf

  Protected RegexId.i = 0
  If UseRegex
    Protected RxFlags.i = 0
    If Not CaseSensitive : RxFlags = #PB_RegularExpression_NoCase : EndIf
    RegexId = CreateRegularExpression(#PB_Any, SearchText, RxFlags)
    If Not RegexId
      SetGadgetText(G_Status, "?EXPRESSAO REGULAR INVALIDA")
      ProcedureReturn #False
    EndIf
  EndIf

  Protected StrMode.i = #PB_String_CaseSensitive
  If Not CaseSensitive : StrMode = #PB_String_NoCase : EndIf

  ; Continua de logo depois do FIM do ultimo match de verdade (nao de
  ; TopLine/LeftCol, que so' enquadram a tela) - ACHADO REAL, corrigido
  ; antes de qualquer release: a 1a versao usava "LeftCol + 2" como ponto
  ; de partida, mas LeftCol e' so' "onde a tela foi rolada pra mostrar o
  ; match com contexto a esquerda" (FoundCol - 10) - isolado num .pb de
  ; teste separado, "Buscar" de novo achava o MESMO match de novo em vez
  ; de avancar (LeftCol+2 podia cair ANTES do inicio do match de verdade).
  Protected StartLine.i, StartCol.i
  If *State\HasLastMatch
    StartLine = *State\LastMatchLine
    StartCol = *State\LastMatchEnd
  Else
    StartLine = *State\TopLine
    StartCol = 1
  EndIf

  Protected LineIdx.i, Pass.i, FromLine.i, ToLine.i, FoundCol.i, SearchFrom.i, LineText.s, MatchLen.i

  For Pass = 0 To 1
    If Pass = 0
      FromLine = StartLine : ToLine = *State\LineCount - 1
    Else
      FromLine = 0 : ToLine = StartLine
    EndIf

    For LineIdx = FromLine To ToLine
      SelectElement(Lines(), LineIdx)
      LineText = Lines()
      SearchFrom = 1
      If Pass = 0 And LineIdx = StartLine : SearchFrom = StartCol : EndIf

      FoundCol = 0 : MatchLen = Len(SearchText)
      If UseRegex
        If SearchFrom <= Len(LineText)
          If ExamineRegularExpression(RegexId, Mid(LineText, SearchFrom))
            If NextRegularExpressionMatch(RegexId)
              FoundCol = SearchFrom + RegularExpressionMatchPosition(RegexId) - 1
              MatchLen = RegularExpressionMatchLength(RegexId)
            EndIf
          EndIf
        EndIf
      Else
        FoundCol = FindString(LineText, SearchText, SearchFrom, StrMode)
      EndIf

      If FoundCol > 0
        If UseRegex : FreeRegularExpression(RegexId) : EndIf
        *State\TopLine = LineIdx
        *State\LeftCol = FoundCol - 10
        If *State\LeftCol < 0 : *State\LeftCol = 0 : EndIf
        *State\HasLastMatch = #True
        *State\LastMatchLine = LineIdx
        *State\LastMatchEnd = FoundCol + MatchLen
        MamuteXtp_Repaint(G_View, G_Status, Lines(), *State)
        ProcedureReturn #True
      EndIf
    Next
  Next

  If UseRegex : FreeRegularExpression(RegexId) : EndIf
  *State\HasLastMatch = #False
  SetGadgetText(G_Status, "NAO ENCONTRADO: " + SearchText)
  ProcedureReturn #False
EndProcedure

; FilePath - de onde LER de verdade (pode ser um arquivo temporario extraido
; do disco corrente, ver MamuteGui_CmdXtp); DisplayName - o que aparece no
; TITULO da janela (o nome de verdade dentro do disco, ex. "AUTOEXEC.BAS",
; nao o caminho temporario). Devolve "" se abriu e fechou normalmente, ou
; uma mensagem de erro ("?ARQUIVO INVALIDO") se nao conseguiu ler o arquivo
; - MamuteGui_CmdXtp() (MamuteAssemblerGui.pbi) decide o que logar.
Procedure.s MamuteXtp_Open(ParentWindow, FilePath.s, DisplayName.s)
  Protected NewList Lines.s()
  If Not Mamute_ReadTextLines(FilePath, Lines())
    ProcedureReturn "?ARQUIVO INVALIDO"
  EndIf

  Protected State.MamuteXtpState
  State\TopLine = 0
  State\LeftCol = 0
  State\LineCount = ListSize(Lines())

  Protected Title.s = "Mamute Assembler - XTP - " + DisplayName

  Protected MStyle.i = 0
  If MamuteFontBold : MStyle = #PB_Font_Bold : EndIf
  Protected MFont = LoadFont(#PB_Any, MamuteFontName, MamuteFontSize, MStyle)
  If Not MFont
    MFont = LoadFont(#PB_Any, "Consolas", 14, #PB_Font_Bold)
  EndIf

  Protected BtnFont = LoadFont(#PB_Any, "Consolas", 14, #PB_Font_Bold)
  If Not BtnFont : BtnFont = MFont : EndIf

  Protected ColFront = Mamute_CurrentFrontColor(), ColBack = Mamute_CurrentBackColor(), ColBorder = Mamute_CurrentBorderColor()

  Protected Margin = 16
  Protected ViewW = 900, ViewH = 540
  Protected WinW = ViewW + Margin * 2
  Protected BtnH = 40, BtnGap = 8
  Protected RowW = 56 * 4 + BtnH * 4 + BtnGap * 7 + Margin * 2
  If RowW > WinW : WinW = RowW : EndIf

  Protected LegendH = 20, StatusH = 24, SearchRowH = 28
  Protected WinH = Margin + LegendH + 8 + ViewH + 12 + StatusH + 12 + BtnH + 12 + SearchRowH + Margin

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, Title,
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #True, #False)
  If Not Win
    ProcedureReturn ""
  EndIf
  SetWindowColor(Win, ColBorder)

  Protected CurY = Margin

  Protected LegendTxt.s = "Setas: linha/coluna  PgUp/PgDn: pagina  Home/End: inicio/fim  RETURN: fecha (ou busca)  ESC: sai"
  Protected G_Legend = TextGadget(#PB_Any, Margin, CurY, WinW - Margin * 2, LegendH, LegendTxt)
  SetGadgetColor(G_Legend, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Legend, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Legend, FontID(MFont))
  CurY + LegendH + 8

  Protected G_View = EditorGadget(#PB_Any, Margin, CurY, ViewW, ViewH, #PB_Editor_ReadOnly)
  SetGadgetColor(G_View, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_View, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_View, FontID(MFont))
  CurY + ViewH + 12

  Protected G_Status = TextGadget(#PB_Any, Margin, CurY, WinW - Margin * 2, StatusH, "")
  SetGadgetColor(G_Status, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Status, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Status, FontID(MFont))
  CurY + StatusH + 12

  ; 8 botoes de navegacao - inicio/fim nas pontas, pagina em seguida,
  ; rolagem lateral/linha no meio (ver comentario no topo do arquivo).
  Protected BtnY = CurY
  Protected CurX = Margin
  Protected G_Home     = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH)   : CurX + 56 + BtnGap
  Protected G_PageUp   = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH)   : CurX + 56 + BtnGap
  Protected G_ArrowLeft = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH) : CurX + BtnH + BtnGap
  Protected G_ArrowUp   = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH) : CurX + BtnH + BtnGap
  Protected G_ArrowDown = CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH) : CurX + BtnH + BtnGap
  Protected G_ArrowRight= CanvasGadget(#PB_Any, CurX, BtnY, BtnH, BtnH) : CurX + BtnH + BtnGap
  Protected G_PageDown  = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH)  : CurX + 56 + BtnGap
  Protected G_End       = CanvasGadget(#PB_Any, CurX, BtnY, 56, BtnH)

  MamuteXd_DrawButton(G_Home, "|<", BtnFont)
  MamuteXd_DrawButton(G_PageUp, "<<", BtnFont)
  MamuteXd_DrawButton(G_ArrowLeft, "<", BtnFont)
  MamuteXd_DrawButton(G_ArrowUp, "^", BtnFont)
  MamuteXd_DrawButton(G_ArrowDown, "v", BtnFont)
  MamuteXd_DrawButton(G_ArrowRight, ">", BtnFont)
  MamuteXd_DrawButton(G_PageDown, ">>", BtnFont)
  MamuteXd_DrawButton(G_End, ">|", BtnFont)
  GadgetToolTip(G_Home, "Inicio do arquivo")
  GadgetToolTip(G_PageUp, "Pagina anterior")
  GadgetToolTip(G_ArrowLeft, "Rola pra esquerda")
  GadgetToolTip(G_ArrowUp, "Linha anterior")
  GadgetToolTip(G_ArrowDown, "Proxima linha")
  GadgetToolTip(G_ArrowRight, "Rola pra direita")
  GadgetToolTip(G_PageDown, "Proxima pagina")
  GadgetToolTip(G_End, "Fim do arquivo")
  CurY + BtnH + 12

  ; Campo de busca - StringGadget + Case/Regex (CheckBoxGadget nativos) +
  ; botao "Buscar" (mesmo MamuteXd_DrawButton dos outros).
  Protected SearchY = CurY
  CurX = Margin
  Protected G_SearchLabel = TextGadget(#PB_Any, CurX, SearchY + 4, 62, SearchRowH, "Buscar:") : CurX + 62 + BtnGap
  SetGadgetColor(G_SearchLabel, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_SearchLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_SearchLabel, FontID(MFont))

  Protected G_SearchField = StringGadget(#PB_Any, CurX, SearchY, 320, SearchRowH, "") : CurX + 320 + BtnGap
  SetGadgetColor(G_SearchField, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_SearchField, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_SearchField, FontID(MFont))

  Protected G_CaseCheck = CheckBoxGadget(#PB_Any, CurX, SearchY + 4, 80, SearchRowH, "Case") : CurX + 80 + BtnGap
  SetGadgetColor(G_CaseCheck, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_CaseCheck, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_CaseCheck, FontID(MFont))

  Protected G_RegexCheck = CheckBoxGadget(#PB_Any, CurX, SearchY + 4, 90, SearchRowH, "Regex") : CurX + 90 + BtnGap
  SetGadgetColor(G_RegexCheck, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_RegexCheck, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_RegexCheck, FontID(MFont))

  Protected G_SearchBtn = CanvasGadget(#PB_Any, CurX, SearchY, 90, SearchRowH)
  MamuteXd_DrawButton(G_SearchBtn, "BUSCAR", BtnFont)
  GadgetToolTip(G_CaseCheck, "Marcado = diferencia maiusculas/minusculas")
  GadgetToolTip(G_RegexCheck, "Marcado = o texto buscado e' uma expressao regular")
  GadgetToolTip(G_SearchBtn, "Busca a proxima ocorrencia (com wraparound)")

  MamuteXtp_Repaint(G_View, G_Status, Lines(), @State)

  AddKeyboardShortcut(Win, #PB_Shortcut_Up, #MamuteXtp_Shortcut_Up)
  AddKeyboardShortcut(Win, #PB_Shortcut_Down, #MamuteXtp_Shortcut_Down)
  AddKeyboardShortcut(Win, #PB_Shortcut_Left, #MamuteXtp_Shortcut_Left)
  AddKeyboardShortcut(Win, #PB_Shortcut_Right, #MamuteXtp_Shortcut_Right)
  AddKeyboardShortcut(Win, #PB_Shortcut_PageUp, #MamuteXtp_Shortcut_PageUp)
  AddKeyboardShortcut(Win, #PB_Shortcut_PageDown, #MamuteXtp_Shortcut_PageDown)
  AddKeyboardShortcut(Win, #PB_Shortcut_Home, #MamuteXtp_Shortcut_Home)
  AddKeyboardShortcut(Win, #PB_Shortcut_End, #MamuteXtp_Shortcut_End)
  AddKeyboardShortcut(Win, #PB_Shortcut_Return, #MamuteXtp_Shortcut_Return)
  AddKeyboardShortcut(Win, #PB_Shortcut_Escape, #MamuteXtp_Shortcut_Escape)

  Macro MamuteXtp_DoLine(Delta)
    State\TopLine + (Delta)
    MamuteXtp_Repaint(G_View, G_Status, Lines(), @State)
  EndMacro

  Macro MamuteXtp_DoPage(Delta)
    State\TopLine + (Delta) * #MamuteXtp_VisibleRows
    MamuteXtp_Repaint(G_View, G_Status, Lines(), @State)
  EndMacro

  Macro MamuteXtp_DoCol(Delta)
    State\LeftCol + (Delta)
    MamuteXtp_Repaint(G_View, G_Status, Lines(), @State)
  EndMacro

  Macro MamuteXtp_DoHome
    State\TopLine = 0
    State\LeftCol = 0
    MamuteXtp_Repaint(G_View, G_Status, Lines(), @State)
  EndMacro

  Macro MamuteXtp_DoEnd
    State\TopLine = State\LineCount
    State\LeftCol = 0
    MamuteXtp_Repaint(G_View, G_Status, Lines(), @State)
  EndMacro

  Macro MamuteXtp_DoSearchNow
    MamuteXtp_DoSearch(G_View, G_Status, Lines(), @State, GetGadgetText(G_SearchField),
                        GetGadgetState(G_CaseCheck), GetGadgetState(G_RegexCheck))
  EndMacro

  Protected Event, Quit = #False, SearchFocused.b
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_ArrowUp    : If EventType() = #PB_EventType_LeftButtonDown : MamuteXtp_DoLine(-1) : EndIf
          Case G_ArrowDown  : If EventType() = #PB_EventType_LeftButtonDown : MamuteXtp_DoLine(1) : EndIf
          Case G_ArrowLeft  : If EventType() = #PB_EventType_LeftButtonDown : MamuteXtp_DoCol(-#MamuteXtp_HScrollStep) : EndIf
          Case G_ArrowRight : If EventType() = #PB_EventType_LeftButtonDown : MamuteXtp_DoCol(#MamuteXtp_HScrollStep) : EndIf
          Case G_PageUp     : If EventType() = #PB_EventType_LeftButtonDown : MamuteXtp_DoPage(-1) : EndIf
          Case G_PageDown   : If EventType() = #PB_EventType_LeftButtonDown : MamuteXtp_DoPage(1) : EndIf
          Case G_Home       : If EventType() = #PB_EventType_LeftButtonDown : MamuteXtp_DoHome : EndIf
          Case G_End        : If EventType() = #PB_EventType_LeftButtonDown : MamuteXtp_DoEnd : EndIf
          Case G_SearchBtn  : If EventType() = #PB_EventType_LeftButtonDown : MamuteXtp_DoSearchNow : EndIf
        EndSelect

      Case #PB_Event_Menu
        SearchFocused = Bool(GetActiveGadget() = G_SearchField)
        Select EventMenu()
          Case #MamuteXtp_Shortcut_Up     : If Not SearchFocused : MamuteXtp_DoLine(-1) : EndIf
          Case #MamuteXtp_Shortcut_Down   : If Not SearchFocused : MamuteXtp_DoLine(1) : EndIf
          Case #MamuteXtp_Shortcut_Left   : If Not SearchFocused : MamuteXtp_DoCol(-#MamuteXtp_HScrollStep) : EndIf
          Case #MamuteXtp_Shortcut_Right  : If Not SearchFocused : MamuteXtp_DoCol(#MamuteXtp_HScrollStep) : EndIf
          Case #MamuteXtp_Shortcut_PageUp   : If Not SearchFocused : MamuteXtp_DoPage(-1) : EndIf
          Case #MamuteXtp_Shortcut_PageDown : If Not SearchFocused : MamuteXtp_DoPage(1) : EndIf
          Case #MamuteXtp_Shortcut_Home : If Not SearchFocused : MamuteXtp_DoHome : EndIf
          Case #MamuteXtp_Shortcut_End  : If Not SearchFocused : MamuteXtp_DoEnd : EndIf
          Case #MamuteXtp_Shortcut_Return
            If SearchFocused
              MamuteXtp_DoSearchNow
            Else
              Quit = #True
            EndIf
          Case #MamuteXtp_Shortcut_Escape
            Quit = #True
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
  ProcedureReturn ""
EndProcedure
