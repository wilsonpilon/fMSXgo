;
; ------------------------------------------------------------
;  SeeTrackerEditorGui.pbi - janela "Criar -> SEE Tracker...": editor de
;  efeitos sonoros (SFX) compativel com o formato .SEE (Sound Effect
;  Editor, Fuzzy Logic 1991/95) - ver Ajuda -> SEE Tracker... e
;  docs/SPEC.md modulo 23. Motor sem GUI em SeeTrackerSynth.pbi/
;  SeeTrackerDriverAsm.pbi (XIncluded antes deste arquivo).
;
;  Um "SFX" e' uma lista ORDENADA de patterns (grade a esquerda, uma linha
;  por pattern, colunas = os canais do formato real); clicar numa linha
;  seleciona o pattern pra edicao no painel a direita (campos de verdade -
;  combo de evento, campos numericos, checkboxes de tuning/wave - mais
;  pratico que tentar editar hex direto nas celulas da grade pros 12 campos
;  heterogeneos de um pattern). "Tocar"/"Parar" reaproveitam PsgSynth.pbi
;  (mesmo mecanismo .wav temporario do editor de Som PSG) depois de expandir
;  os patterns+eventos via SeeSynth_Expand(). "Gerar codigo"/"Injetar no
;  cursor"/"Copiar" montam o driver Z80 nativo (Z80Asm::Assemble sobre
;  SeeDrv_SourceCode()) + o blob binario .SEE do SFX atual via
;  SeeGen_BuildCode().
; ------------------------------------------------------------
;

Global SeeEd_SoundSystemReady.b = #False

#SeeEd_GridHeaderH = 18
#SeeEd_GridRows    = 18
#SeeEd_GridRowH    = 22
#SeeEd_GridColIdx  = 40
#SeeEd_GridColEvt  = 60
#SeeEd_GridColFrq  = 48
#SeeEd_GridColRus  = 24
#SeeEd_GridColVol  = 32
#SeeEd_GridColWav  = 32
#SeeEd_GridColTim  = 48
#SeeEd_GridW = #SeeEd_GridColIdx + #SeeEd_GridColEvt + 3 * #SeeEd_GridColFrq + 3 * #SeeEd_GridColRus + 3 * #SeeEd_GridColVol + #SeeEd_GridColWav + #SeeEd_GridColTim
#SeeEd_GridH = #SeeEd_GridRows * #SeeEd_GridRowH

Procedure.s SeeEd_EventShortText(Array PB.a(1), Idx.i)
  Protected Cmd.a = SeeP_EventCmd(PB(), Idx)
  Protected Val.a = SeeP_EventVal(PB(), Idx)
  Select Cmd
    Case #SeeEvt_None  : ProcedureReturn "--"
    Case #SeeEvt_Halt  : ProcedureReturn "H:" + Str(Val)
    Case #SeeEvt_For   : ProcedureReturn "F:" + Str(Val)
    Case #SeeEvt_Next  : ProcedureReturn "NXT"
    Case #SeeEvt_Start : ProcedureReturn "STR"
    Case #SeeEvt_Rerun : ProcedureReturn "RER"
    Case #SeeEvt_Tempo : ProcedureReturn "T:" + Str(Val)
    Default            : ProcedureReturn "END"
  EndSelect
EndProcedure

; Redesenha a grade de patterns (visao geral, so leitura - a edicao de
; verdade acontece no painel a direita). ScrollTop = indice do primeiro
; pattern visivel (rolagem). Selected = pattern com a linha destacada.
; PlayCursor = indice do pattern sendo tocado NESTE INSTANTE (-1 = nenhum,
; nao esta tocando ou o usuario apertou Parar) - desenhado como uma borda
; extra + faixa colorida na borda esquerda da linha, por cima de tudo mais
; (inclusive por cima do realce de selecao, que pode ser a MESMA linha ou
; nao - sao dois conceitos independentes: Selected e' o que o usuario clicou
; pra editar, PlayCursor e' o que esta soando agora).
Procedure SeeEd_DrawGrid(Canvas, Array PB.a(1), NumPatterns.i, ScrollTop.i, Selected.i, PlayCursor.i = -1)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf

  ; Paleta clara (tema Light) preserva as cores originais - ja tem bom
  ; contraste sobre fundo branco. Tema Dark usa fundo bem menos escuro que o
  ; preto da janela (nao branco puro, pra nao virar um retangulo estourado
  ; no meio de uma janela escura) e cores de letra bem mais claras/vivas -
  ; as cores escuras saturadas originais (ex.: RGB(0,0,150) navy) ficavam
  ; ilegiveis contra qualquer fundo escuro.
  Protected IsDark.b = EditorCfg_ThemeIsDark(EditorCfg\Theme)
  Protected ColBg.l, ColSel.l, ColOutline.l, ColPlay.l
  Protected ColIdx.l, ColEvt.l, ColFreq.l, ColNoiseOn.l, ColNoiseOff.l, ColVol.l, ColEnv.l
  If IsDark
    ColBg        = RGB(48, 51, 60)
    ColSel       = RGB(92, 76, 34)
    ColOutline   = RGB(72, 76, 88)
    ColPlay      = RGB(90, 240, 140)
    ColIdx       = RGB(230, 230, 235)
    ColEvt       = RGB(255, 130, 130)
    ColFreq      = RGB(140, 190, 255)
    ColNoiseOn   = RGB(150, 230, 150)
    ColNoiseOff  = RGB(125, 129, 140)
    ColVol       = RGB(255, 195, 110)
    ColEnv       = RGB(230, 155, 235)
  Else
    ColBg        = RGB(255, 255, 255)
    ColSel       = RGB(255, 230, 150)
    ColOutline   = RGB(200, 200, 200)
    ColPlay      = RGB(20, 150, 60)
    ColIdx       = RGB(0, 0, 0)
    ColEvt       = RGB(120, 0, 0)
    ColFreq      = RGB(0, 0, 150)
    ColNoiseOn   = RGB(0, 110, 0)
    ColNoiseOff  = RGB(180, 180, 180)
    ColVol       = RGB(120, 60, 0)
    ColEnv       = RGB(90, 0, 90)
  EndIf

  Box(0, 0, #SeeEd_GridW, #SeeEd_GridH, ColBg)

  Protected Row, Idx, X, Y
  Protected Ch
  For Row = 0 To #SeeEd_GridRows - 1
    Idx = ScrollTop + Row
    Y = Row * #SeeEd_GridRowH
    If Idx >= NumPatterns
      Continue
    EndIf

    If Idx = Selected
      Box(0, Y, #SeeEd_GridW, #SeeEd_GridRowH, ColSel)
    EndIf

    ; Transparente: sem isso, DrawText() no modo padrao pinta um retangulo
    ; OPACO atras de cada texto usando BackColor() - que nunca foi setada
    ; aqui, entao ficava preta (padrao do PB) atras de TODA celula, mesmo
    ; com o fundo da linha branco/realcado por baixo. Era a causa real do
    ; "fundo preto" reportado: cada valor aparecia dentro de uma caixinha
    ; preta opaca, com a cor do texto (ja escura) por cima - dupla perda de
    ; contraste. So precisa setar uma vez, mantido ate o proximo DrawingMode.
    DrawingMode(#PB_2DDrawing_Transparent)

    X = 0
    DrawText(X + 4, Y + 3, Str(Idx), ColIdx)
    X + #SeeEd_GridColIdx

    DrawText(X + 2, Y + 3, SeeEd_EventShortText(PB(), Idx), ColEvt)
    X + #SeeEd_GridColEvt

    For Ch = 0 To 2
      Protected.u Freq = SeeP_FreqVal(PB(), Idx, Ch)
      Protected FTxt.s = RSet(Hex(Freq), 3, "0")
      If SeeP_FreqTuneUp(PB(), Idx, Ch) : FTxt + "^" : EndIf
      If SeeP_FreqTuneDown(PB(), Idx, Ch) : FTxt + "v" : EndIf
      DrawText(X + 2, Y + 3, FTxt, ColFreq)
      X + #SeeEd_GridColFrq
    Next

    For Ch = 0 To 2
      If SeeP_NoiseOn(PB(), Idx, Ch)
        DrawText(X + 4, Y + 3, "R", ColNoiseOn)
      Else
        DrawText(X + 4, Y + 3, "-", ColNoiseOff)
      EndIf
      X + #SeeEd_GridColRus
    Next

    For Ch = 0 To 2
      Protected VTxt.s = Hex(SeeP_VolVal(PB(), Idx, Ch), #PB_Byte)
      VTxt = Right(VTxt, 1)
      If SeeP_VolWave(PB(), Idx, Ch) : VTxt + "W" : EndIf
      DrawText(X + 2, Y + 3, VTxt, ColVol)
      X + #SeeEd_GridColVol
    Next

    DrawText(X + 2, Y + 3, RSet(Hex(SeeP_EnvShape(PB(), Idx)), 1, "0"), ColEnv)
    X + #SeeEd_GridColWav

    DrawText(X + 2, Y + 3, RSet(Hex(SeeP_EnvPeriod(PB(), Idx)), 4, "0"), ColEnv)

    DrawingMode(#PB_2DDrawing_Outlined)
    Box(0, Y, #SeeEd_GridW, #SeeEd_GridRowH, ColOutline)
    If Idx = PlayCursor
      Box(1, Y + 1, #SeeEd_GridW - 2, #SeeEd_GridRowH - 2, ColPlay)
    EndIf
    DrawingMode(#PB_2DDrawing_Default)
    If Idx = PlayCursor
      Box(0, Y, 4, #SeeEd_GridRowH, ColPlay)
    EndIf
  Next

  StopDrawing()
EndProcedure

; Cabecalho fixo da grade (nomes das colunas) - canvas separado, desenhado
; uma unica vez (nao precisa redesenhar a cada mudanca, ver comentario no
; call site). Usa os MESMOS offsets X por coluna (#SeeEd_GridColXxx) e o
; MESMO preenchimento a esquerda (X+2/X+4) de cada celula em SeeEd_DrawGrid -
; antes disso o cabecalho era um TextGadget com texto alinhado a mao com
; espacos (fonte proporcional, nunca a mesma fonte/metrica da grade abaixo),
; entao os titulos ficavam sistematicamente desalinhados das colunas reais.
; Desenhando com os MESMOS numeros usados pra desenhar a grade, alinhamento
; e' garantido por construcao, nao por coincidencia de espacamento de texto.
Procedure SeeEd_DrawHeader(Canvas)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected IsDark.b = EditorCfg_ThemeIsDark(EditorCfg\Theme)
  Protected ColBg.l, ColText.l
  If IsDark
    ColBg = RGB(38, 40, 48) : ColText = RGB(210, 213, 220)
  Else
    ColBg = RGB(230, 230, 230) : ColText = RGB(30, 30, 30)
  EndIf
  Box(0, 0, #SeeEd_GridW, #SeeEd_GridHeaderH, ColBg)
  DrawingMode(#PB_2DDrawing_Transparent)
  Protected X = 0
  DrawText(X + 4, 2, "#", ColText)    : X + #SeeEd_GridColIdx
  DrawText(X + 2, 2, "Evt", ColText)  : X + #SeeEd_GridColEvt
  DrawText(X + 2, 2, "Snd1", ColText) : X + #SeeEd_GridColFrq
  DrawText(X + 2, 2, "Snd2", ColText) : X + #SeeEd_GridColFrq
  DrawText(X + 2, 2, "Snd3", ColText) : X + #SeeEd_GridColFrq
  DrawText(X + 4, 2, "R1", ColText)   : X + #SeeEd_GridColRus
  DrawText(X + 4, 2, "R2", ColText)   : X + #SeeEd_GridColRus
  DrawText(X + 4, 2, "R3", ColText)   : X + #SeeEd_GridColRus
  DrawText(X + 2, 2, "V1", ColText)   : X + #SeeEd_GridColVol
  DrawText(X + 2, 2, "V2", ColText)   : X + #SeeEd_GridColVol
  DrawText(X + 2, 2, "V3", ColText)   : X + #SeeEd_GridColVol
  DrawText(X + 2, 2, "Wv", ColText)   : X + #SeeEd_GridColWav
  DrawText(X + 2, 2, "Time", ColText)
  DrawingMode(#PB_2DDrawing_Default)
  StopDrawing()
EndProcedure

; Desenha a curva do envelope de hardware do PSG (reg 13, forma 0-15) dentro
; de um retangulo GX,GY,GW,GH de uma superficie de desenho JA aberta
; (StartDrawing chamado pelo chamador - esta procedure so soma linhas nela,
; nao abre/fecha nada). Reaproveita PsgSynth_ApplyEnvShape/PsgSynth_EnvTick
; (PsgSynth.pbi) - o MESMO gerador usado de verdade no motor de sintese -
; entao a curva mostrada e' garantidamente fiel ao som real, nunca uma
; segunda implementacao da tabela de formas que podia divergir. 40 "quadros"
; simulados bastam pra mostrar pelo menos 1 ciclo completo (formas repetidas
; tem ciclo de 16-32 quadros) e o "assentamento" final das formas de tiro
; unico (Continue=0 do reg. 13).
Procedure SeeEd_DrawEnvShapeGraph(Shape.a, GX.i, GY.i, GW.i, GH.i, LineColor.l)
  Protected St.PsgChipState
  PsgSynth_InitState(@St)
  PsgSynth_ApplyEnvShape(@St, Shape & $0F)
  Protected Steps = 40
  Protected PrevX, PrevY, X, Y, i
  For i = 0 To Steps - 1
    X = GX + i * (GW - 1) / (Steps - 1)
    Y = GY + (GH - 1) - (St\EnvLevel * (GH - 1) / 15)
    If i > 0
      LineXY(PrevX, PrevY, X, Y, LineColor)
    EndIf
    PrevX = X : PrevY = Y
    PsgSynth_EnvTick(@St)
  Next
EndProcedure

; Preview compacto (sem rotulo) ao lado do campo "Forma" no painel - some
; toda vez que o pattern selecionado muda ou o campo e' editado, pra dar
; feedback visual imediato de "que forma e' essa numero" sem precisar abrir
; o seletor. GadgetWidth/GadgetHeight em vez de receber W/H por parametro -
; um a menos pra manter sincronizado se o layout mudar.
Procedure SeeEd_DrawEnvShapeIcon(Canvas, Shape.a)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected IsDark.b = EditorCfg_ThemeIsDark(EditorCfg\Theme)
  Protected ColBg.l, ColLine.l, ColOutline.l
  If IsDark
    ColBg = RGB(48, 51, 60) : ColLine = RGB(140, 190, 255) : ColOutline = RGB(72, 76, 88)
  Else
    ColBg = RGB(255, 255, 255) : ColLine = RGB(0, 0, 150) : ColOutline = RGB(200, 200, 200)
  EndIf
  Protected W = GadgetWidth(Canvas), H = GadgetHeight(Canvas)
  Box(0, 0, W, H, ColBg)
  DrawingMode(#PB_2DDrawing_Outlined)
  Box(0, 0, W, H, ColOutline)
  DrawingMode(#PB_2DDrawing_Transparent)
  SeeEd_DrawEnvShapeGraph(Shape, 2, 2, W - 4, H - 4, ColLine)
  DrawingMode(#PB_2DDrawing_Default)
  StopDrawing()
EndProcedure

; Uma celula do seletor modal (SeeEd_PickEnvShape abaixo): rotulo hex (0-F)
; + a mesma curva do preview compacto, maior. IsCurrent realca a celula que
; corresponde ao valor atualmente no campo "Forma", pra o usuario ver de
; cara onde esta antes de escolher outra.
Procedure SeeEd_DrawEnvShapeCell(Canvas, Shape.a, IsCurrent.b)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected IsDark.b = EditorCfg_ThemeIsDark(EditorCfg\Theme)
  Protected ColBg.l, ColLine.l, ColOutline.l, ColSel.l, ColLabel.l
  If IsDark
    ColBg = RGB(48, 51, 60) : ColLine = RGB(140, 190, 255) : ColOutline = RGB(72, 76, 88)
    ColSel = RGB(92, 76, 34) : ColLabel = RGB(230, 230, 235)
  Else
    ColBg = RGB(255, 255, 255) : ColLine = RGB(0, 0, 150) : ColOutline = RGB(200, 200, 200)
    ColSel = RGB(255, 230, 150) : ColLabel = RGB(0, 0, 0)
  EndIf
  Protected W = GadgetWidth(Canvas), H = GadgetHeight(Canvas)
  If IsCurrent
    Box(0, 0, W, H, ColSel)
  Else
    Box(0, 0, W, H, ColBg)
  EndIf
  DrawingMode(#PB_2DDrawing_Transparent)
  DrawText(4, 2, RSet(Hex(Shape), 1, "0"), ColLabel)
  SeeEd_DrawEnvShapeGraph(Shape, 4, 18, W - 8, H - 22, ColLine)
  DrawingMode(#PB_2DDrawing_Outlined)
  Box(0, 0, W, H, ColOutline)
  DrawingMode(#PB_2DDrawing_Default)
  StopDrawing()
EndProcedure

; Janelinha modal com as 16 formas de envelope do PSG (reg 13), cada uma com
; sua curva real desenhada (ver SeeEd_DrawEnvShapeCell) - clicar numa
; celula ja escolhe e fecha (paleta pequena e fixa, mesmo espirito de um
; seletor de cor - nao precisa de OK/confirmar separado). Devolve o numero
; da forma escolhida (0-15) ou -1 se o usuario cancelou/fechou sem escolher.
Procedure.i SeeEd_PickEnvShape(ParentWindow, CurrentShape.a)
  Protected Cols = 4, Rows = 4, CellW = 90, CellH = 68, Pad = 10
  Protected WinW = Pad * 2 + Cols * CellW
  Protected WinH = Pad * 2 + Rows * CellH + 46
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Escolher forma do envelope PSG (reg. 13)",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn -1
  EndIf

  Dim G_Cell.i(15)
  Protected s, CellX, CellY, Col, Row
  For s = 0 To 15
    Col = s % Cols : Row = s / Cols
    CellX = Pad + Col * CellW : CellY = Pad + Row * CellH
    G_Cell(s) = CanvasGadget(#PB_Any, CellX, CellY, CellW - 6, CellH - 6)
    GadgetToolTip(G_Cell(s), "Forma " + Str(s))
    SeeEd_DrawEnvShapeCell(G_Cell(s), s, Bool(s = CurrentShape))
  Next

  Protected G_Cancel = ThemedButton(WinW / 2 - 55, WinH - 36, 110, 28, "Cancelar", "")

  Protected Event, Quit = #False, Result.i = -1
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        If EventGadget() = G_Cancel
          Quit = #True
        Else
          For s = 0 To 15
            If EventGadget() = G_Cell(s) And EventType() = #PB_EventType_LeftButtonDown
              Result = s
              Quit = #True
            EndIf
          Next
        EndIf
      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
  ProcedureReturn Result
EndProcedure

Procedure.i SeeEd_ComboEventIndex(Cmd.a)
  Select Cmd
    Case #SeeEvt_None  : ProcedureReturn 0
    Case #SeeEvt_Halt  : ProcedureReturn 1
    Case #SeeEvt_For   : ProcedureReturn 2
    Case #SeeEvt_Next  : ProcedureReturn 3
    Case #SeeEvt_Start : ProcedureReturn 4
    Case #SeeEvt_Rerun : ProcedureReturn 5
    Case #SeeEvt_Tempo : ProcedureReturn 6
    Default            : ProcedureReturn 7 ; END
  EndSelect
EndProcedure

Procedure.a SeeEd_EventCmdFromComboIndex(Idx.i)
  Select Idx
    Case 0 : ProcedureReturn #SeeEvt_None
    Case 1 : ProcedureReturn #SeeEvt_Halt
    Case 2 : ProcedureReturn #SeeEvt_For
    Case 3 : ProcedureReturn #SeeEvt_Next
    Case 4 : ProcedureReturn #SeeEvt_Start
    Case 5 : ProcedureReturn #SeeEvt_Rerun
    Case 6 : ProcedureReturn #SeeEvt_Tempo
    Default : ProcedureReturn #SeeEvt_End
  EndSelect
EndProcedure

; Estado inicial de um SFX novo/vazio: 2 patterns (0=em branco, editavel na
; hora; 1=END), nao 1 so pattern com END - se fosse so o END, o primeiro
; "Inserir pattern" a partir dele ficaria DEPOIS do END (inalcancavel no
; playback, que sempre comeca no pattern 0 - ver SeeSynth_Expand) ate o
; usuario perceber e reordenar na mao. Devolve o novo NumPatterns (2).
Procedure.i SeeEd_InitBlankSfx(Array PB.a(1))
  SeeP_Clear(PB(), 0)
  SeeP_Clear(PB(), 1)
  SeeP_SetEvent(PB(), 1, #SeeEvt_End, 0)
  ProcedureReturn 2
EndProcedure

Procedure.i SeeEd_ComboIndexFor(Combo, AlphaNumber.i)
  If AlphaNumber = -1
    ProcedureReturn 0
  EndIf
  Protected i
  For i = 1 To CountGadgetItems(Combo) - 1
    If Val(Mid(GetGadgetItemText(Combo, i), 2)) = AlphaNumber
      ProcedureReturn i
    EndIf
  Next
  ProcedureReturn 0
EndProcedure

; Janelinha modal listando os SFX definidos num arquivo .SEE real (ver
; SeeImp_ListDefinedSfx) pra escolher qual importar - mesmo espirito de
; Scr12Ed_AskBlockRange (janela auxiliar simples, devolve via ponteiro cru
; porque PureBasic nao aceita tipo nativo direto num parametro de ponteiro).
; Devolve #True/#False (Cancelar); StartPattern sai via *OutStartPattern.
Procedure.b SeeEd_PickSfxFromFile(ParentWindow, List SfxNums.i(), List StartPats.i(), *OutStartPattern)
  Protected WinW = 360, WinH = 420
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Importar .SEE - escolha o SFX",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn #False
  EndIf

  TextGadget(#PB_Any, 20, 16, WinW - 40, 20, "SFX definidos neste arquivo (" + Str(ListSize(SfxNums())) + "):")
  Protected G_List = ListIconGadget(#PB_Any, 20, 40, WinW - 40, WinH - 96, "SFX", 80, #PB_ListIcon_FullRowSelect)
  AddGadgetColumn(G_List, 1, "Pattern inicial", 150)

  FirstElement(StartPats())
  ForEach SfxNums()
    AddGadgetItem(G_List, -1, "#" + Str(SfxNums()) + Chr(10) + Str(StartPats()))
    NextElement(StartPats())
  Next
  If CountGadgetItems(G_List) > 0
    SetGadgetState(G_List, 0)
  EndIf

  Protected G_Ok = ThemedButton(WinW - 24 - 234, WinH - 44, 110, 32, "Importar", Chr(#Icon_Import))
  GadgetToolTip(G_Ok, "Importar")
  Protected G_Cancel = ThemedButton(WinW - 24 - 110, WinH - 44, 110, 32, "Cancelar", "")

  Protected Event, Quit = #False, Result.b = #False, Sel
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_List
            If EventType() = #PB_EventType_LeftDoubleClick
              Sel = GetGadgetState(G_List)
              If Sel >= 0
                SelectElement(StartPats(), Sel)
                PokeI(*OutStartPattern, StartPats())
                Result = #True
                Quit = #True
              EndIf
            EndIf
          Case G_Ok
            Sel = GetGadgetState(G_List)
            If Sel >= 0
              SelectElement(StartPats(), Sel)
              PokeI(*OutStartPattern, StartPats())
              Result = #True
              Quit = #True
            Else
              MessageRequester("Nada selecionado", "Escolha um SFX na lista antes de Importar.", #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
            EndIf
          Case G_Cancel
            Quit = #True
        EndSelect
      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
  ProcedureReturn Result
EndProcedure

; Janelinha modal simples pra escolher um intervalo [Lo,Hi] de patterns
; (usada por "Limpar bloco") - mesmo padrao de SeeEd_PickSfxFromFile acima
; (DisableWindow do pai, loop de evento proprio, devolve #True/#False,
; valores de saida via ponteiro cru + PokeI porque PureBasic nao aceita tipo
; nativo direto num parametro de ponteiro). Os campos vem com DefaultLo/
; DefaultHi pre-preenchidos (o chamador passa o pattern selecionado nos
; dois, pra "so click Limpar" sem editar nada equivaler a limpar 1 linha so)
; e sao grampeados em 0..MaxIdx - se o usuario digitar De > Ate, inverte em
; vez de travar ou dar erro.
Procedure.b SeeEd_AskPatternRange(ParentWindow, DefaultLo.i, DefaultHi.i, MaxIdx.i, *OutLo, *OutHi)
  Protected WinW = 320, WinH = 150
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Limpar bloco de patterns",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn #False
  EndIf

  TextGadget(#PB_Any, 20, 20, 280, 20, "Patterns de 0 a " + Str(MaxIdx) + " (zera os dados, sem remover as linhas):")
  TextGadget(#PB_Any, 20, 58, 30, 20, "De:")
  Protected G_Lo = StringGadget(#PB_Any, 54, 54, 90, 24, Str(DefaultLo), #PB_String_Numeric)
  TextGadget(#PB_Any, 168, 58, 34, 20, "Ate:")
  Protected G_Hi = StringGadget(#PB_Any, 204, 54, 90, 24, Str(DefaultHi), #PB_String_Numeric)

  Protected G_Ok = ThemedButton(WinW - 24 - 234, WinH - 44, 110, 32, "Limpar", Chr(#Icon_Clear))
  GadgetToolTip(G_Ok, "Limpar")
  Protected G_Cancel = ThemedButton(WinW - 24 - 110, WinH - 44, 110, 32, "Cancelar", "")

  Protected Event, Quit = #False, Result.b = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_Ok
            Protected Lo.i = Val(GetGadgetText(G_Lo))
            Protected Hi.i = Val(GetGadgetText(G_Hi))
            If Lo < 0 : Lo = 0 : EndIf
            If Lo > MaxIdx : Lo = MaxIdx : EndIf
            If Hi < 0 : Hi = 0 : EndIf
            If Hi > MaxIdx : Hi = MaxIdx : EndIf
            If Lo > Hi
              Swap Lo, Hi
            EndIf
            PokeI(*OutLo, Lo)
            PokeI(*OutHi, Hi)
            Result = #True
            Quit = #True
          Case G_Cancel
            Quit = #True
        EndSelect
      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
  ProcedureReturn Result
EndProcedure

; Preenche os campos do painel a partir de PB()/SelPattern (chamado apos
; qualquer selecao/edicao/navegacao) - Loading=#True enquanto roda pra as
; proprias mudancas de campo nao dispararem SeeEd_ApplyPanel() de volta.
; Procedure de topo (nao aninhada dentro de SeeTrackerEditor_OpenWindow -
; PureBasic nao permite Procedure dentro de Procedure), recebe os IDs de
; gadget como parametro - mesmo padrao ja usado por Scr12Ed_DrawCharPicker.
Procedure SeeEd_RefreshPanel(Array PB.a(1), SelPattern.i, NumPatterns.i, G_PatIdxText, G_EvtCombo, G_EvtVal, Array G_FreqVal.i(1), Array G_ToneOn.i(1), Array G_NoiseOn.i(1), Array G_FreqUp.i(1), Array G_FreqDown.i(1), G_RustleVal, G_RustleUp, G_RustleDown, Array G_VolVal.i(1), Array G_VolWave.i(1), Array G_VolUp.i(1), Array G_VolDown.i(1), G_EnvPeriod, G_EnvShape, G_EnvShapeIcon)
  SetGadgetText(G_PatIdxText, Str(SelPattern) + " / " + Str(NumPatterns - 1))
  SetGadgetState(G_EvtCombo, SeeEd_ComboEventIndex(SeeP_EventCmd(PB(), SelPattern)))
  SetGadgetText(G_EvtVal, Str(SeeP_EventVal(PB(), SelPattern)))
  Protected Ch
  For Ch = 0 To 2
    SetGadgetText(G_FreqVal(Ch), Str(SeeP_FreqVal(PB(), SelPattern, Ch)))
    SetGadgetState(G_ToneOn(Ch), Bool(SeeP_ToneOn(PB(), SelPattern, Ch)))
    SetGadgetState(G_NoiseOn(Ch), Bool(SeeP_NoiseOn(PB(), SelPattern, Ch)))
    SetGadgetState(G_FreqUp(Ch), Bool(SeeP_FreqTuneUp(PB(), SelPattern, Ch)))
    SetGadgetState(G_FreqDown(Ch), Bool(SeeP_FreqTuneDown(PB(), SelPattern, Ch)))
    SetGadgetText(G_VolVal(Ch), Str(SeeP_VolVal(PB(), SelPattern, Ch)))
    SetGadgetState(G_VolWave(Ch), Bool(SeeP_VolWave(PB(), SelPattern, Ch)))
    SetGadgetState(G_VolUp(Ch), Bool(SeeP_VolTuneUp(PB(), SelPattern, Ch)))
    SetGadgetState(G_VolDown(Ch), Bool(SeeP_VolTuneDown(PB(), SelPattern, Ch)))
  Next
  SetGadgetText(G_RustleVal, Str(SeeP_RustleVal(PB(), SelPattern)))
  SetGadgetState(G_RustleUp, Bool(SeeP_RustleTuneUp(PB(), SelPattern)))
  SetGadgetState(G_RustleDown, Bool(SeeP_RustleTuneDown(PB(), SelPattern)))
  SetGadgetText(G_EnvPeriod, Str(SeeP_EnvPeriod(PB(), SelPattern)))
  SetGadgetText(G_EnvShape, Str(SeeP_EnvShape(PB(), SelPattern)))
  SeeEd_DrawEnvShapeIcon(G_EnvShapeIcon, SeeP_EnvShape(PB(), SelPattern))
EndProcedure

; Le os campos do painel de volta pra PB()/SelPattern - chamado a cada
; Change de qualquer campo (clique-aplica-na-hora, mesmo padrao do resto
; desta IDE), exceto enquanto Loading=#True (RefreshPanel programatico).
Procedure SeeEd_ApplyPanel(Array PB.a(1), SelPattern.i, G_EvtCombo, G_EvtVal, Array G_FreqVal.i(1), Array G_ToneOn.i(1), Array G_NoiseOn.i(1), Array G_FreqUp.i(1), Array G_FreqDown.i(1), G_RustleVal, G_RustleUp, G_RustleDown, Array G_VolVal.i(1), Array G_VolWave.i(1), Array G_VolUp.i(1), Array G_VolDown.i(1), G_EnvPeriod, G_EnvShape, G_EnvShapeIcon)
  SeeP_SetEvent(PB(), SelPattern, SeeEd_EventCmdFromComboIndex(GetGadgetState(G_EvtCombo)), Val(GetGadgetText(G_EvtVal)))
  Protected Ch
  For Ch = 0 To 2
    SeeP_SetFreq(PB(), SelPattern, Ch, Val(GetGadgetText(G_FreqVal(Ch))), GetGadgetState(G_FreqUp(Ch)), GetGadgetState(G_FreqDown(Ch)))
    SeeP_SetChannelOn(PB(), SelPattern, Ch, GetGadgetState(G_ToneOn(Ch)), GetGadgetState(G_NoiseOn(Ch)))
    SeeP_SetVol(PB(), SelPattern, Ch, Val(GetGadgetText(G_VolVal(Ch))), GetGadgetState(G_VolWave(Ch)), GetGadgetState(G_VolUp(Ch)), GetGadgetState(G_VolDown(Ch)))
  Next
  SeeP_SetRustle(PB(), SelPattern, Val(GetGadgetText(G_RustleVal)), GetGadgetState(G_RustleUp), GetGadgetState(G_RustleDown))
  SeeP_SetEnvPeriod(PB(), SelPattern, Val(GetGadgetText(G_EnvPeriod)))
  SeeP_SetEnvShape(PB(), SelPattern, Val(GetGadgetText(G_EnvShape)))
  SeeEd_DrawEnvShapeIcon(G_EnvShapeIcon, Val(GetGadgetText(G_EnvShape)) & $0F)
EndProcedure

Procedure SeeTrackerEditor_OpenWindow(ParentWindow)
  Protected LeftX = 20, TopY = 20
  Protected GridLabelY = TopY
  Protected GridY = GridLabelY + 20
  Protected G_ScrollY = GridY
  Protected ScrollW = 18

  Protected RightX = LeftX + #SeeEd_GridW + ScrollW + 24
  Protected PanelW = 380

  Protected WinW = RightX + PanelW + 24
  Protected ListBottomY = GridY + #SeeEd_GridH + 8
  Protected BtnRowY = ListBottomY + 4
  Protected ProjBarY = BtnRowY + 5 * 34 + 16
  Protected ProjBarRow2Y = ProjBarY + #CharEd_IconBtnH + 6
  Protected WinH = ProjBarRow2Y + #CharEd_IconBtnH + 40

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "SEE Tracker",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  ; Sem isso, LoadSound() falha (devolve 0) silenciosamente e "Tocar" nao
  ; faz NADA visivel (nem toca, nem erro) - mesmo Global+guard "so uma vez"
  ; ja usado por PsgEditorGui.pbi/MmlEditorGui.pbi (InitSound() e' da
  ; sessao de audio inteira do processo, nao por-janela).
  If Not SeeEd_SoundSystemReady
    InitSound()
    SeeEd_SoundSystemReady = #True
  EndIf

  Protected FixedFont = LoadFont(#PB_Any, "Consolas", 9)
  Protected G_Header = CanvasGadget(#PB_Any, LeftX, GridLabelY, #SeeEd_GridW, #SeeEd_GridHeaderH)
  Protected G_Grid = CanvasGadget(#PB_Any, LeftX, GridY, #SeeEd_GridW, #SeeEd_GridH)
  If FixedFont
    SetGadgetFont(G_Header, FontID(FixedFont))
    SetGadgetFont(G_Grid, FontID(FixedFont))
  EndIf
  SeeEd_DrawHeader(G_Header)
  Protected G_Scroll = ScrollBarGadget(#PB_Any, LeftX + #SeeEd_GridW, GridY, ScrollW, #SeeEd_GridH, 0, 0, #SeeEd_GridRows)

  Protected G_Insert = ThemedButton(LeftX, BtnRowY, 120, 30, "Inserir pattern", Chr(#Icon_Insert))
  GadgetToolTip(G_Insert, "Inserir pattern")
  Protected G_Delete = ThemedButton(LeftX + 124, BtnRowY, 120, 30, "Apagar pattern", "")
  Protected G_MoveUp = ThemedButton(LeftX + 248, BtnRowY, 90, 30, "Mover p/ cima", Chr(#Icon_ArrowUp))
  GadgetToolTip(G_MoveUp, "Mover p/ cima")
  Protected G_MoveDown = ThemedButton(LeftX + 342, BtnRowY, 90, 30, "Mover p/ baixo", Chr(#Icon_ArrowDown))
  GadgetToolTip(G_MoveDown, "Mover p/ baixo")
  Protected G_Copy1 = ThemedButton(LeftX, BtnRowY + 34, 120, 30, "Copiar pattern", "")
  Protected G_Paste1 = ThemedButton(LeftX + 124, BtnRowY + 34, 120, 30, "Colar pattern", "")
  Protected G_Play = ThemedButton(LeftX + 248, BtnRowY + 34, 90, 30, "Tocar", Chr(#Icon_Play))
  GadgetToolTip(G_Play, "Tocar")
  Protected G_Stop = ThemedButton(LeftX + 342, BtnRowY + 34, 90, 30, "Parar", Chr(#Icon_Stop))
  GadgetToolTip(G_Stop, "Parar")
  Protected G_ClearAll = ThemedButton(LeftX, BtnRowY + 68, 140, 30, "Limpar", Chr(#Icon_Clear))
  Protected G_ClearLine = ThemedButton(LeftX + 144, BtnRowY + 68, 140, 30, "Limpar linha", Chr(#Icon_Clear))
  Protected G_ClearBlock = ThemedButton(LeftX + 288, BtnRowY + 68, 144, 30, "Limpar bloco", Chr(#Icon_Clear))
  Protected G_GenCode = ThemedButton(LeftX, BtnRowY + 102, 120, 30, "Gerar codigo", "")
  Protected G_Inject = ThemedButton(LeftX + 124, BtnRowY + 102, 120, 30, "Injetar no cursor", Chr(#Icon_Insert))
  Protected G_CopyCode = ThemedButton(LeftX + 248, BtnRowY + 102, 90, 30, "Copiar", Chr(#Icon_Copy))
  Protected G_Close = ThemedButton(LeftX + 342, BtnRowY + 102, 90, 30, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")
  Protected G_ImportSee = ThemedButton(LeftX, BtnRowY + 136, 432, 30, "Importar .SEE... (arquivo gerado pelo SEE original)", Chr(#Icon_Import))
  GadgetToolTip(G_GenCode, "Monta o driver Z80 nativo + o blob .SEE deste SFX e mostra o codigo BASIC pronto (DATA/POKE/DEFUSR)")
  GadgetToolTip(G_Inject, "Gera o mesmo codigo e injeta na aba de texto ativa")
  GadgetToolTip(G_ImportSee, "Le um arquivo .SEE real (do editor original) e importa um dos SFX dele pros patterns do SFX atual")
  GadgetToolTip(G_CopyCode, "Gera o mesmo codigo e copia pra area de transferencia")
  GadgetToolTip(G_ClearAll, "Limpa TODOS os patterns deste SFX, voltando ao estado inicial (1 em branco + END) - mantem o numero/tag do SFX")
  GadgetToolTip(G_ClearLine, "Limpa o pattern selecionado (zera os dados, mantem a linha e a ordem dos outros patterns)")
  GadgetToolTip(G_ClearBlock, "Limpa um intervalo de patterns (zera os dados de cada um, sem remover nenhuma linha) - pede o pattern inicial e final")

  Protected Cx = LeftX
  TextGadget(#PB_Any, Cx, ProjBarY + 5, 40, 20, "SFX:")
  Cx + 40 + 4
  Protected G_SfxNumberText = TextGadget(#PB_Any, Cx, ProjBarY + 5, 40, 20, "#1")
  Cx + 40 + 10
  Protected FirstIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 0, #True)
  Protected G_First = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(FirstIcon))
  GadgetToolTip(G_First, "Primeiro SFX")
  Cx + #CharEd_IconBtnW + 2
  Protected PrevIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 0, #False)
  Protected G_Prev = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(PrevIcon))
  GadgetToolTip(G_Prev, "SFX anterior")
  Cx + #CharEd_IconBtnW + 2
  Protected NextIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 1, #False)
  Protected G_Next = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(NextIcon))
  GadgetToolTip(G_Next, "Proximo SFX")
  Cx + #CharEd_IconBtnW + 2
  Protected LastIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 1, #True)
  Protected G_Last = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(LastIcon))
  GadgetToolTip(G_Last, "Ultimo SFX")

  Cx = LeftX
  TextGadget(#PB_Any, Cx, ProjBarRow2Y + 3, 32, 20, "Tag:")
  Cx + 32 + 4
  Protected G_Tag = StringGadget(#PB_Any, Cx, ProjBarRow2Y + 1, 150, 22, "")
  GadgetToolTip(G_Tag, "Nome curto pra identificar o SFX (ate 16 caracteres)")
  Cx + 150 + 16
  Protected NewIcon = CharEd_CreateNewIcon(#CharEd_IconSize)
  Protected G_New = ButtonImageGadget(#PB_Any, Cx, ProjBarRow2Y, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(NewIcon))
  GadgetToolTip(G_New, "Novo SFX (numera automaticamente, comeca com 1 pattern END)")
  Cx + #CharEd_IconBtnW + 2
  Protected RegisterIcon = CharEd_CreateRegisterIcon(#CharEd_IconSize)
  Protected G_Register = ButtonImageGadget(#PB_Any, Cx, ProjBarRow2Y, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(RegisterIcon))
  GadgetToolTip(G_Register, "Registrar: grava este SFX no projeto")

  ; --- Painel de edicao do pattern atual (direita) ---
  Protected PY = TopY
  TextGadget(#PB_Any, RightX, PY, PanelW, 20, "Pattern atual:")
  Protected G_PatIdxText = TextGadget(#PB_Any, RightX + 110, PY, PanelW - 110, 20, "0 / 0")
  PY + 26

  TextGadget(#PB_Any, RightX, PY + 4, 60, 20, "Evento:")
  Protected G_EvtCombo = ComboBoxGadget(#PB_Any, RightX + 64, PY, 130, 24)
  AddGadgetItem(G_EvtCombo, -1, "-- (nada)")
  AddGadgetItem(G_EvtCombo, -1, "HALT")
  AddGadgetItem(G_EvtCombo, -1, "FOR")
  AddGadgetItem(G_EvtCombo, -1, "NEXT")
  AddGadgetItem(G_EvtCombo, -1, "START")
  AddGadgetItem(G_EvtCombo, -1, "RERUN")
  AddGadgetItem(G_EvtCombo, -1, "TMP")
  AddGadgetItem(G_EvtCombo, -1, "END")
  TextGadget(#PB_Any, RightX + 200, PY + 4, 40, 20, "Valor:")
  Protected G_EvtVal = StringGadget(#PB_Any, RightX + 244, PY, 50, 24, "0", #PB_String_Numeric)
  GadgetToolTip(G_EvtVal, "0-15 (quadros do HALT, repeticoes do FOR, ou o TMP)")
  PY + 34

  Protected Ch, ChY
  Dim G_FreqVal.i(2)
  Dim G_FreqUp.i(2)
  Dim G_FreqDown.i(2)
  Dim G_ToneOn.i(2)
  Dim G_NoiseOn.i(2)
  Dim G_VolVal.i(2)
  Dim G_VolWave.i(2)
  Dim G_VolUp.i(2)
  Dim G_VolDown.i(2)
  For Ch = 0 To 2
    ChY = PY + Ch * 30
    TextGadget(#PB_Any, RightX, ChY + 4, 60, 20, "Freq " + Str(Ch + 1) + ":")
    G_FreqVal(Ch) = StringGadget(#PB_Any, RightX + 64, ChY, 60, 24, "0", #PB_String_Numeric)
    G_ToneOn(Ch) = CheckBoxGadget(#PB_Any, RightX + 130, ChY + 3, 45, 20, "Som")
    G_NoiseOn(Ch) = CheckBoxGadget(#PB_Any, RightX + 178, ChY + 3, 55, 20, "Rustle")
    G_FreqUp(Ch) = CheckBoxGadget(#PB_Any, RightX + 238, ChY + 3, 30, 20, "Up")
    G_FreqDown(Ch) = CheckBoxGadget(#PB_Any, RightX + 272, ChY + 3, 40, 20, "Down")
    GadgetToolTip(G_FreqVal(Ch), "Frequencia PSG do canal " + Str(Ch+1) + " (0-4095)")
    GadgetToolTip(G_NoiseOn(Ch), "Este canal usa o rustle compartilhado (campo Rustle abaixo)")
  Next
  PY + 3 * 30 + 6

  TextGadget(#PB_Any, RightX, PY + 4, 60, 20, "Rustle:")
  Protected G_RustleVal = StringGadget(#PB_Any, RightX + 64, PY, 60, 24, "0", #PB_String_Numeric)
  Protected G_RustleUp = CheckBoxGadget(#PB_Any, RightX + 238, PY + 3, 30, 20, "Up")
  Protected G_RustleDown = CheckBoxGadget(#PB_Any, RightX + 272, PY + 3, 40, 20, "Down")
  GadgetToolTip(G_RustleVal, "Periodo de ruido compartilhado (0-31) - so soa nos canais com Rustle marcado acima")
  PY + 34

  For Ch = 0 To 2
    ChY = PY + Ch * 30
    TextGadget(#PB_Any, RightX, ChY + 4, 60, 20, "Vol " + Str(Ch + 1) + ":")
    G_VolVal(Ch) = StringGadget(#PB_Any, RightX + 64, ChY, 60, 24, "0", #PB_String_Numeric)
    G_VolWave(Ch) = CheckBoxGadget(#PB_Any, RightX + 130, ChY + 3, 55, 20, "Wave")
    G_VolUp(Ch) = CheckBoxGadget(#PB_Any, RightX + 238, ChY + 3, 30, 20, "Up")
    G_VolDown(Ch) = CheckBoxGadget(#PB_Any, RightX + 272, ChY + 3, 40, 20, "Down")
    GadgetToolTip(G_VolVal(Ch), "Volume 0-15 (ou indice recebe o envelope de hardware se Wave marcado)")
    GadgetToolTip(G_VolWave(Ch), "Usa o envelope de hardware do PSG (regs. Periodo/Forma abaixo) em vez de volume fixo")
  Next
  PY + 3 * 30 + 6

  TextGadget(#PB_Any, RightX, PY + 4, 90, 20, "Periodo envelope:")
  Protected G_EnvPeriod = StringGadget(#PB_Any, RightX + 100, PY, 70, 24, "0", #PB_String_Numeric)
  TextGadget(#PB_Any, RightX + 180, PY + 4, 50, 20, "Forma:")
  Protected G_EnvShape = StringGadget(#PB_Any, RightX + 228, PY, 50, 24, "0", #PB_String_Numeric)
  Protected G_EnvShapePick = ThemedButton(RightX + 282, PY, 26, 24, "...", "")
  Protected G_EnvShapeIcon = CanvasGadget(#PB_Any, RightX + 312, PY, 66, 24)
  GadgetToolTip(G_EnvPeriod, "Periodo do envelope de hardware do PSG (0-65535, regs 11/12)")
  GadgetToolTip(G_EnvShape, "Forma do envelope de hardware do PSG (0-15, reg 13)")
  GadgetToolTip(G_EnvShapePick, "Escolher a forma visualmente (16 formas do PSG, com a curva de cada uma)")
  GadgetToolTip(G_EnvShapeIcon, "Curva da forma atual - clique em '...' pra escolher outra visualmente")
  PY + 34

  Protected G_Status = TextGadget(#PB_Any, RightX, PY + 6, PanelW, 40, "")

  ; --- Estado ---
  #SeeEd_MaxPatterns = 512
  Dim PB.a(#SeeEd_MaxPatterns * #SeeP_Size - 1)
  Protected NumPatterns.i = 1
  Protected SelPattern.i = 0
  Protected ScrollTop.i = 0
  Protected SfxNumber.i = 1
  Protected SfxTag.s = ""
  Protected Dirty.b = #False
  Protected ClipValid.b = #False
  Dim ClipPattern.a(#SeeP_Size - 1)
  Protected SoundHandle.i = 0
  Protected TempWavPath.s = GetTemporaryDirectory() + "badig_see_preview.wav"
  Protected Loading.b = #False ; suprime "Dirty=True"/re-render em cascata enquanto os campos sao preenchidos programaticamente

  ; Cursor de playback (linha da grade tocando NESTE INSTANTE, ver
  ; SeeEd_DrawGrid) - PlayStepStartMs()/PlayPatArr() sao a "linha do tempo"
  ; do efeito atualmente carregado no SoundHandle: PlayStepStartMs(i) = em
  ; que milissegundo (desde o inicio do PlaySound) o step i comeca, e
  ; PlayPatArr(i) = de qual pattern aquele step veio (SeeSynth_Expand ja
  ; devolve isso em paralelo). O timer (#SeeEd_PlayTimerId) so precisa
  ; consultar GetSoundPosition() e achar em qual step aquele tempo cai -
  ; nao precisa reprocessar o efeito nem estimar tempo por conta propria.
  #SeeEd_PlayTimerId = 1
  Protected PlayCursorPattern.i = -1
  Protected PlayStepCountLive.i = 0
  Protected PlayTotalMsLive.d = 0
  Protected Dim PlayStepStartMs.d(0)
  Protected Dim PlayPatArr.i(0)

  NumPatterns = SeeEd_InitBlankSfx(PB())

  Protected NewList SfxNav.i()
  ProjectDB::ListSeeSfxNumbers(SfxNav())
  If ListSize(SfxNav()) > 0
    FirstElement(SfxNav())
    SfxNumber = SfxNav()
    Protected Dim FetchPB.a(1)
    If ProjectDB::FetchSeeSfx(SfxNumber, FetchPB())
      NumPatterns = ProjectDB::LastSeeSfxPatternCount()
      SfxTag = ProjectDB::LastSeeSfxTag()
      Protected fi
      For fi = 0 To NumPatterns * #SeeP_Size - 1
        PB(fi) = FetchPB(fi)
      Next
    EndIf
  EndIf

  Loading = #True
  SeeEd_RefreshPanel(PB(), SelPattern, NumPatterns, G_PatIdxText, G_EvtCombo, G_EvtVal, G_FreqVal(), G_ToneOn(), G_NoiseOn(), G_FreqUp(), G_FreqDown(), G_RustleVal, G_RustleUp, G_RustleDown, G_VolVal(), G_VolWave(), G_VolUp(), G_VolDown(), G_EnvPeriod, G_EnvShape, G_EnvShapeIcon)
  Loading = #False
  SetGadgetText(G_SfxNumberText, "#" + Str(SfxNumber))
  SetGadgetText(G_Tag, SfxTag)
  SetGadgetState(G_Scroll, 0)
  SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)

  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event

      Case #PB_Event_Gadget
        Select EventGadget()

          Case G_Tag
            If EventType() = #PB_EventType_Change
              If Len(GetGadgetText(G_Tag)) > 16
                SetGadgetText(G_Tag, Left(GetGadgetText(G_Tag), 16))
              EndIf
              Dirty = #True
            EndIf

          Case G_Grid
            If EventType() = #PB_EventType_LeftButtonDown
              Protected MouseY = GetGadgetAttribute(G_Grid, #PB_Canvas_MouseY)
              If MouseY >= 0
                Protected ClickIdx = ScrollTop + (MouseY / #SeeEd_GridRowH)
                If ClickIdx >= 0 And ClickIdx < NumPatterns
                  SelPattern = ClickIdx
                  Loading = #True
                  SeeEd_RefreshPanel(PB(), SelPattern, NumPatterns, G_PatIdxText, G_EvtCombo, G_EvtVal, G_FreqVal(), G_ToneOn(), G_NoiseOn(), G_FreqUp(), G_FreqDown(), G_RustleVal, G_RustleUp, G_RustleDown, G_VolVal(), G_VolWave(), G_VolUp(), G_VolDown(), G_EnvPeriod, G_EnvShape, G_EnvShapeIcon)
                  Loading = #False
                  SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)
                EndIf
              EndIf
            EndIf

          Case G_Scroll
            ScrollTop = GetGadgetState(G_Scroll)
            SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)

        EndSelect

        ; Qualquer campo do painel de edicao (evento/freq/vol/rustle/env)
        ; aplica na hora - checagem centralizada em vez de repetir o mesmo
        ; bloco de 4 linhas em ~25 Case separados.
        Protected IsPanelField.b = #False
        Select EventGadget()
          Case G_EvtCombo, G_EvtVal, G_RustleVal, G_RustleUp, G_RustleDown, G_EnvPeriod, G_EnvShape
            IsPanelField = #True
        EndSelect
        If Not IsPanelField
          For Ch = 0 To 2
            If EventGadget() = G_FreqVal(Ch) Or EventGadget() = G_ToneOn(Ch) Or EventGadget() = G_NoiseOn(Ch) Or
               EventGadget() = G_FreqUp(Ch) Or EventGadget() = G_FreqDown(Ch) Or EventGadget() = G_VolVal(Ch) Or
               EventGadget() = G_VolWave(Ch) Or EventGadget() = G_VolUp(Ch) Or EventGadget() = G_VolDown(Ch)
              IsPanelField = #True
            EndIf
          Next
        EndIf
        If IsPanelField And Not Loading
          ; Auto-liga "Som" quando o campo de frequencia/volume que acabou de
          ; mudar virou diferente de zero e o canal ainda estava desligado -
          ; sem isso, o usuario digita uma frequencia/volume e nao ouve nada
          ; porque o bit de mixer (Som) continua OFF por padrao (fiel ao
          ; hardware real, mas o editor SEE original nao exige esse passo
          ; extra - la, digitar um valor ja liga o canal sozinho). NUNCA
          ; desliga sozinho (so o usuario desmarca de proposito).
          For Ch = 0 To 2
            If (EventGadget() = G_FreqVal(Ch) Or EventGadget() = G_VolVal(Ch)) And Not GetGadgetState(G_ToneOn(Ch))
              If Val(GetGadgetText(G_FreqVal(Ch))) > 0 Or Val(GetGadgetText(G_VolVal(Ch))) > 0
                SetGadgetState(G_ToneOn(Ch), 1)
              EndIf
            EndIf
          Next
          SeeEd_ApplyPanel(PB(), SelPattern, G_EvtCombo, G_EvtVal, G_FreqVal(), G_ToneOn(), G_NoiseOn(), G_FreqUp(), G_FreqDown(), G_RustleVal, G_RustleUp, G_RustleDown, G_VolVal(), G_VolWave(), G_VolUp(), G_VolDown(), G_EnvPeriod, G_EnvShape, G_EnvShapeIcon)
          Dirty = #True
          SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)
        EndIf

        Select EventGadget()

          Case G_Insert
            If NumPatterns < #SeeEd_MaxPatterns
              ; Se o pattern selecionado for um END, insere ANTES dele (nao
              ; depois) - inserir depois deixaria o pattern novo depois de um
              ; END, ou seja, NUNCA alcancado no playback (que sempre comeca
              ; no pattern 0 - ver SeeSynth_Expand) ate o usuario perceber e
              ; reordenar na mao. Achado real: motivo de "Tocar" nao tocar
              ; nada mesmo com dados validos num pattern mais adiante.
              Protected InsertAt.i = SelPattern + 1
              If SeeP_EventCmd(PB(), SelPattern) = #SeeEvt_End
                InsertAt = SelPattern
              EndIf
              Protected ii
              For ii = NumPatterns To InsertAt + 1 Step -1
                Protected bb
                For bb = 0 To #SeeP_Size - 1
                  PB(ii * #SeeP_Size + bb) = PB((ii - 1) * #SeeP_Size + bb)
                Next
              Next
              SeeP_Clear(PB(), InsertAt)
              NumPatterns + 1
              SelPattern = InsertAt
              Dirty = #True
              Loading = #True
              SeeEd_RefreshPanel(PB(), SelPattern, NumPatterns, G_PatIdxText, G_EvtCombo, G_EvtVal, G_FreqVal(), G_ToneOn(), G_NoiseOn(), G_FreqUp(), G_FreqDown(), G_RustleVal, G_RustleUp, G_RustleDown, G_VolVal(), G_VolWave(), G_VolUp(), G_VolDown(), G_EnvPeriod, G_EnvShape, G_EnvShapeIcon)
              Loading = #False
              SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)
            EndIf

          Case G_Delete
            If NumPatterns > 1
              Protected di
              For di = SelPattern To NumPatterns - 2
                Protected db
                For db = 0 To #SeeP_Size - 1
                  PB(di * #SeeP_Size + db) = PB((di + 1) * #SeeP_Size + db)
                Next
              Next
              NumPatterns - 1
              If SelPattern >= NumPatterns : SelPattern = NumPatterns - 1 : EndIf
              Dirty = #True
              Loading = #True
              SeeEd_RefreshPanel(PB(), SelPattern, NumPatterns, G_PatIdxText, G_EvtCombo, G_EvtVal, G_FreqVal(), G_ToneOn(), G_NoiseOn(), G_FreqUp(), G_FreqDown(), G_RustleVal, G_RustleUp, G_RustleDown, G_VolVal(), G_VolWave(), G_VolUp(), G_VolDown(), G_EnvPeriod, G_EnvShape, G_EnvShapeIcon)
              Loading = #False
              SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)
            EndIf

          Case G_MoveUp
            If SelPattern > 0
              Protected mb
              For mb = 0 To #SeeP_Size - 1
                Protected Tmp.a = PB(SelPattern * #SeeP_Size + mb)
                PB(SelPattern * #SeeP_Size + mb) = PB((SelPattern - 1) * #SeeP_Size + mb)
                PB((SelPattern - 1) * #SeeP_Size + mb) = Tmp
              Next
              SelPattern - 1
              Dirty = #True
              Loading = #True
              SeeEd_RefreshPanel(PB(), SelPattern, NumPatterns, G_PatIdxText, G_EvtCombo, G_EvtVal, G_FreqVal(), G_ToneOn(), G_NoiseOn(), G_FreqUp(), G_FreqDown(), G_RustleVal, G_RustleUp, G_RustleDown, G_VolVal(), G_VolWave(), G_VolUp(), G_VolDown(), G_EnvPeriod, G_EnvShape, G_EnvShapeIcon)
              Loading = #False
              SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)
            EndIf

          Case G_MoveDown
            If SelPattern < NumPatterns - 1
              Protected mb2
              For mb2 = 0 To #SeeP_Size - 1
                Protected Tmp2.a = PB(SelPattern * #SeeP_Size + mb2)
                PB(SelPattern * #SeeP_Size + mb2) = PB((SelPattern + 1) * #SeeP_Size + mb2)
                PB((SelPattern + 1) * #SeeP_Size + mb2) = Tmp2
              Next
              SelPattern + 1
              Dirty = #True
              Loading = #True
              SeeEd_RefreshPanel(PB(), SelPattern, NumPatterns, G_PatIdxText, G_EvtCombo, G_EvtVal, G_FreqVal(), G_ToneOn(), G_NoiseOn(), G_FreqUp(), G_FreqDown(), G_RustleVal, G_RustleUp, G_RustleDown, G_VolVal(), G_VolWave(), G_VolUp(), G_VolDown(), G_EnvPeriod, G_EnvShape, G_EnvShapeIcon)
              Loading = #False
              SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)
            EndIf

          Case G_Copy1
            Protected cb
            For cb = 0 To #SeeP_Size - 1
              ClipPattern(cb) = PB(SelPattern * #SeeP_Size + cb)
            Next
            ClipValid = #True

          Case G_Paste1
            If Not ClipValid
              MessageRequester("Nada copiado", "Use 'Copiar pattern' antes de colar.", #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
            Else
              Protected pb2
              For pb2 = 0 To #SeeP_Size - 1
                PB(SelPattern * #SeeP_Size + pb2) = ClipPattern(pb2)
              Next
              Dirty = #True
              Loading = #True
              SeeEd_RefreshPanel(PB(), SelPattern, NumPatterns, G_PatIdxText, G_EvtCombo, G_EvtVal, G_FreqVal(), G_ToneOn(), G_NoiseOn(), G_FreqUp(), G_FreqDown(), G_RustleVal, G_RustleUp, G_RustleDown, G_VolVal(), G_VolWave(), G_VolUp(), G_VolDown(), G_EnvPeriod, G_EnvShape, G_EnvShapeIcon)
              Loading = #False
              SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)
            EndIf

          Case G_ClearAll
            ; Mesmo padrao "so pede confirmacao se ha algo pra perder" ja
            ; usado por G_New/G_First/G_Prev/G_Next/G_Last neste arquivo -
            ; volta ao estado inicial de um SFX novo (2 patterns) mas SEM
            ; trocar SfxNumber/Tag (diferente de "Novo": aqui e' o MESMO
            ; slot, so esvaziado).
            If Not Dirty Or Bool(MessageRequester("Limpar tudo",
                 "Isso apaga TODOS os patterns deste SFX (volta ao estado inicial: 1 em branco + END)." + Chr(10) + "Confirma?",
                 #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
              NumPatterns = SeeEd_InitBlankSfx(PB())
              SelPattern = 0
              ScrollTop = 0
              ClipValid = #False
              Dirty = #True
              SetGadgetState(G_Scroll, 0)
              Loading = #True
              SeeEd_RefreshPanel(PB(), SelPattern, NumPatterns, G_PatIdxText, G_EvtCombo, G_EvtVal, G_FreqVal(), G_ToneOn(), G_NoiseOn(), G_FreqUp(), G_FreqDown(), G_RustleVal, G_RustleUp, G_RustleDown, G_VolVal(), G_VolWave(), G_VolUp(), G_VolDown(), G_EnvPeriod, G_EnvShape, G_EnvShapeIcon)
              Loading = #False
              SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)
            EndIf

          Case G_ClearLine
            ; Zera os 15 bytes do pattern selecionado NO LUGAR - diferente de
            ; "Apagar pattern" (que remove a linha e desloca os de baixo pra
            ; cima), aqui a linha continua existindo, so fica em branco.
            SeeP_Clear(PB(), SelPattern)
            Dirty = #True
            Loading = #True
            SeeEd_RefreshPanel(PB(), SelPattern, NumPatterns, G_PatIdxText, G_EvtCombo, G_EvtVal, G_FreqVal(), G_ToneOn(), G_NoiseOn(), G_FreqUp(), G_FreqDown(), G_RustleVal, G_RustleUp, G_RustleDown, G_VolVal(), G_VolWave(), G_VolUp(), G_VolDown(), G_EnvPeriod, G_EnvShape, G_EnvShapeIcon)
            Loading = #False
            SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)

          Case G_ClearBlock
            ; Pede o intervalo numa janelinha (SeeEd_AskPatternRange acima) -
            ; pre-preenchida com o pattern selecionado nos dois campos, entao
            ; so clicar "Limpar" sem editar equivale a limpar 1 linha so.
            Protected BlkLo.i, BlkHi.i
            If SeeEd_AskPatternRange(Win, SelPattern, SelPattern, NumPatterns - 1, @BlkLo, @BlkHi)
              Protected bi
              For bi = BlkLo To BlkHi
                SeeP_Clear(PB(), bi)
              Next
              Dirty = #True
              Loading = #True
              SeeEd_RefreshPanel(PB(), SelPattern, NumPatterns, G_PatIdxText, G_EvtCombo, G_EvtVal, G_FreqVal(), G_ToneOn(), G_NoiseOn(), G_FreqUp(), G_FreqDown(), G_RustleVal, G_RustleUp, G_RustleDown, G_VolVal(), G_VolWave(), G_VolUp(), G_VolDown(), G_EnvPeriod, G_EnvShape, G_EnvShapeIcon)
              Loading = #False
              SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)
            EndIf

          Case G_Play
            ; Qualquer "Tocar" novo comeca zerando o cursor/timer do anterior
            ; (mesmo se este pressionamento acabar falhando mais abaixo) -
            ; sem isso um cursor de uma reproducao anterior podia ficar
            ; "grudado" numa linha errada se o novo Tocar nao tiver dados.
            RemoveWindowTimer(Win, #SeeEd_PlayTimerId)
            PlayCursorPattern = -1
            PlayStepCountLive = 0

            NewList PlaySteps.PsgStepData()
            NewList PlayPatIdxList.i()
            Protected PlayEnded.b = SeeSynth_Expand(PB(), NumPatterns, 0, PlaySteps(), PlayPatIdxList())
            If ListSize(PlaySteps()) > 0
              Protected StepCount = ListSize(PlaySteps())
              Protected Dim PlayArr.PsgStepData(StepCount - 1)
              ReDim PlayPatArr.i(StepCount - 1)
              ReDim PlayStepStartMs.d(StepCount)
              Protected pi = 0
              Protected AccumMs.d = 0
              PlayStepStartMs(0) = 0
              FirstElement(PlayPatIdxList())
              ForEach PlaySteps()
                PlayArr(pi) = PlaySteps()
                PlayPatArr(pi) = PlayPatIdxList()
                AccumMs + PlayArr(pi)\DurationFrames * 1000.0 / 60.0
                PlayStepStartMs(pi + 1) = AccumMs
                NextElement(PlayPatIdxList())
                pi + 1
              Next
              Protected TotalSamp = PsgSynth_TotalSamples(PlayArr(), StepCount, #Psg_SampleRate)
              If TotalSamp > 0
                Protected *Buf = PsgSynth_RenderSequence(PlayArr(), StepCount, #Psg_SampleRate, TotalSamp)
                If *Buf
                  PsgSynth_WriteWav(*Buf, TotalSamp, #Psg_SampleRate, TempWavPath)
                  FreeMemory(*Buf)
                  If SoundHandle
                    StopSound(SoundHandle)
                    FreeSound(SoundHandle)
                  EndIf
                  SoundHandle = LoadSound(#PB_Any, TempWavPath)
                  If SoundHandle
                    PlaySound(SoundHandle)
                    PlayStepCountLive = StepCount
                    PlayTotalMsLive = AccumMs
                    AddWindowTimer(Win, #SeeEd_PlayTimerId, 40)
                    If PlayEnded
                      SetGadgetText(G_Status, "Reproduzindo...")
                    Else
                      SetGadgetText(G_Status, "Reproduzindo (efeito tem RERUN sem fim - preview cortado em " + Str(#SeeSynth_DefaultMaxFrames / 60) + "s)")
                    EndIf
                  Else
                    ; Nao existia antes da correcao de InitSound() (2026-08-06):
                    ; LoadSound() falhando ficava 100% silencioso pro usuario -
                    ; nem tocava nem avisava nada, so "Tocar" nao fazendo nada
                    ; visivel. Mantido como rede de seguranca (driver de audio
                    ; indisponivel, .wav temporario bloqueado por outro
                    ; processo, etc.) - agora sempre da algum feedback.
                    SetGadgetText(G_Status, "Nao foi possivel carregar o audio renderizado (" + TempWavPath + ").")
                  EndIf
                Else
                  SetGadgetText(G_Status, "Erro ao renderizar audio (memoria insuficiente?).")
                EndIf
              Else
                SetGadgetText(G_Status, "Nada pra tocar (duracao total zero).")
              EndIf
            ElseIf SeeP_EventCmd(PB(), 0) = #SeeEvt_End
              SetGadgetText(G_Status, "Nada pra tocar - o pattern 0 tem evento END, que para tudo ANTES de tocar qualquer coisa (nenhum pattern depois dele e alcancado). Mova os dados de som pra antes do END, ou o END pro final com 'Mover p/ baixo'.")
            Else
              SetGadgetText(G_Status, "Nada pra tocar.")
            EndIf
            SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)

          Case G_Stop
            If SoundHandle
              StopSound(SoundHandle)
            EndIf
            RemoveWindowTimer(Win, #SeeEd_PlayTimerId)
            PlayCursorPattern = -1
            SetGadgetText(G_Status, "")
            SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)

          Case G_EnvShapePick
            Protected PickedShape.i = SeeEd_PickEnvShape(Win, Val(GetGadgetText(G_EnvShape)) & $0F)
            If PickedShape >= 0
              SetGadgetText(G_EnvShape, Str(PickedShape))
              SeeEd_ApplyPanel(PB(), SelPattern, G_EvtCombo, G_EvtVal, G_FreqVal(), G_ToneOn(), G_NoiseOn(), G_FreqUp(), G_FreqDown(), G_RustleVal, G_RustleUp, G_RustleDown, G_VolVal(), G_VolWave(), G_VolUp(), G_VolDown(), G_EnvPeriod, G_EnvShape, G_EnvShapeIcon)
              Dirty = #True
              SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)
            EndIf

          Case G_GenCode, G_Inject, G_CopyCode
            Protected Dim CodePB.a(NumPatterns * #SeeP_Size - 1)
            Protected gi
            For gi = 0 To NumPatterns * #SeeP_Size - 1
              CodePB(gi) = PB(gi)
            Next
            Protected GenCode.s = SeeGen_BuildCode(CodePB(), NumPatterns, SfxNumber, GetGadgetText(G_Tag))
            If GenCode = ""
              MessageRequester("Erro ao montar o driver",
                               "Linha " + Str(Z80Asm::GetAssembleErrorLine()) + ": " + Z80Asm::GetAssembleErrorText(),
                               #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
            Else
              Select EventGadget()
                Case G_Inject
                  If Not InjectTextAtCursor(GenCode)
                    MessageRequester("Erro", "Nenhuma aba de texto ativa para injetar o codigo.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
                  EndIf
                Case G_CopyCode
                  SetClipboardText(GenCode)
                Default
                  SetGadgetText(G_Status, Str(Len(GenCode)) + " caracteres de codigo gerados (Injetar no cursor/Copiar).")
              EndSelect
            EndIf

          Case G_New
            If Not Dirty Or Bool(MessageRequester("SFX nao registrado",
                 "As alteracoes deste SFX ainda nao foram registradas no projeto." + Chr(10) + "Descartar mesmo assim?",
                 #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
              ProjectDB::ListSeeSfxNumbers(SfxNav())
              If ListSize(SfxNav()) > 0
                LastElement(SfxNav())
                SfxNumber = SfxNav() + 1
              Else
                SfxNumber = 1
              EndIf
              NumPatterns = SeeEd_InitBlankSfx(PB())
              SelPattern = 0
              ScrollTop = 0
              ClipValid = #False
              Dirty = #False
              SetGadgetText(G_SfxNumberText, "#" + Str(SfxNumber))
              SetGadgetText(G_Tag, "")
              Loading = #True
              SeeEd_RefreshPanel(PB(), SelPattern, NumPatterns, G_PatIdxText, G_EvtCombo, G_EvtVal, G_FreqVal(), G_ToneOn(), G_NoiseOn(), G_FreqUp(), G_FreqDown(), G_RustleVal, G_RustleUp, G_RustleDown, G_VolVal(), G_VolWave(), G_VolUp(), G_VolDown(), G_EnvPeriod, G_EnvShape, G_EnvShapeIcon)
              Loading = #False
              SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)
            EndIf

          Case G_Register
            Protected Dim RegPB.a(NumPatterns * #SeeP_Size - 1)
            Protected ri
            For ri = 0 To NumPatterns * #SeeP_Size - 1
              RegPB(ri) = PB(ri)
            Next
            ProjectDB::StoreSeeSfx(SfxNumber, GetGadgetText(G_Tag), NumPatterns, RegPB())
            Dirty = #False

          Case G_First, G_Prev, G_Next, G_Last
            If Not Dirty Or Bool(MessageRequester("SFX nao registrado",
                 "As alteracoes deste SFX ainda nao foram registradas no projeto." + Chr(10) + "Descartar mesmo assim?",
                 #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
              ProjectDB::ListSeeSfxNumbers(SfxNav())
              Protected NavTarget
              Select EventGadget()
                Case G_First : NavTarget = SpriteEd_FindNavTarget(SfxNav(), 0, SfxNumber)
                Case G_Prev  : NavTarget = SpriteEd_FindNavTarget(SfxNav(), 1, SfxNumber)
                Case G_Next  : NavTarget = SpriteEd_FindNavTarget(SfxNav(), 2, SfxNumber)
                Case G_Last  : NavTarget = SpriteEd_FindNavTarget(SfxNav(), 3, SfxNumber)
              EndSelect
              If NavTarget >= 0
                SfxNumber = NavTarget
                Protected Dim NavPB.a(1)
                If ProjectDB::FetchSeeSfx(SfxNumber, NavPB())
                  NumPatterns = ProjectDB::LastSeeSfxPatternCount()
                  SfxTag = ProjectDB::LastSeeSfxTag()
                  Protected ni
                  For ni = 0 To NumPatterns * #SeeP_Size - 1
                    PB(ni) = NavPB(ni)
                  Next
                  SelPattern = 0 : ScrollTop = 0
                  Dirty = #False
                  SetGadgetText(G_SfxNumberText, "#" + Str(SfxNumber))
                  SetGadgetText(G_Tag, SfxTag)
                  Loading = #True
                  SeeEd_RefreshPanel(PB(), SelPattern, NumPatterns, G_PatIdxText, G_EvtCombo, G_EvtVal, G_FreqVal(), G_ToneOn(), G_NoiseOn(), G_FreqUp(), G_FreqDown(), G_RustleVal, G_RustleUp, G_RustleDown, G_VolVal(), G_VolWave(), G_VolUp(), G_VolDown(), G_EnvPeriod, G_EnvShape, G_EnvShapeIcon)
                  Loading = #False
                  SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)
                EndIf
              EndIf
            EndIf

          Case G_ImportSee
            Protected ImpPath.s = OpenFileRequester("Importar .SEE", "", "Arquivos .SEE (*.see)|*.see|Todos os arquivos (*.*)|*.*", 0)
            If ImpPath <> ""
              Protected Dim ImpFB.a(1)
              Protected ImpLen = SeeImp_LoadFile(ImpPath, ImpFB())
              If ImpLen = 0 Or Not SeeImp_IsValidHeader(ImpFB(), ImpLen)
                MessageRequester("Arquivo invalido",
                                 "Este arquivo nao parece ser um .SEE valido (identificacao " + Chr(34) + "SEE3" + Chr(34) + " nao encontrada nos 4 primeiros bytes).",
                                 #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
              Else
                NewList ImpSfxNums.i()
                NewList ImpStartPats.i()
                SeeImp_ListDefinedSfx(ImpFB(), ImpLen, ImpSfxNums(), ImpStartPats())
                If ListSize(ImpSfxNums()) = 0
                  MessageRequester("Nada pra importar", "Este arquivo .SEE nao tem nenhum SFX definido (tabela de posicoes vazia).", #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
                Else
                  Protected ImpStartPattern.i
                  If SeeEd_PickSfxFromFile(Win, ImpSfxNums(), ImpStartPats(), @ImpStartPattern)
                    If Not Dirty Or Bool(MessageRequester("SFX nao registrado",
                         "As alteracoes deste SFX ainda nao foram registradas no projeto." + Chr(10) + "Substituir os patterns mesmo assim?",
                         #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
                      Protected Dim ImpPB.a(1)
                      Protected ImpCount = SeeImp_ExtractSfxPatterns(ImpFB(), ImpLen, ImpStartPattern, ImpPB())
                      If ImpCount = 0
                        MessageRequester("Erro ao importar", "Nao foi possivel extrair patterns a partir do pattern inicial " + Str(ImpStartPattern) + ".", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
                      Else
                        NumPatterns = ImpCount
                        Protected impi
                        For impi = 0 To ImpCount * #SeeP_Size - 1
                          PB(impi) = ImpPB(impi)
                        Next
                        SelPattern = 0 : ScrollTop = 0
                        Dirty = #True
                        Loading = #True
                        SeeEd_RefreshPanel(PB(), SelPattern, NumPatterns, G_PatIdxText, G_EvtCombo, G_EvtVal, G_FreqVal(), G_ToneOn(), G_NoiseOn(), G_FreqUp(), G_FreqDown(), G_RustleVal, G_RustleUp, G_RustleDown, G_VolVal(), G_VolWave(), G_VolUp(), G_VolDown(), G_EnvPeriod, G_EnvShape, G_EnvShapeIcon)
                        Loading = #False
                        SetGadgetState(G_Scroll, 0)
                        SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)
                        SetGadgetText(G_Status, Str(ImpCount) + " patterns importados de " + GetFilePart(ImpPath) + ".")
                      EndIf
                    EndIf
                  EndIf
                EndIf
              EndIf
            EndIf

          Case G_Close
            Quit = #True

        EndSelect

      Case #PB_Event_Timer
        ; So dispara enquanto uma reproducao esta de fato ativa (o proprio
        ; "Tocar"/"Parar"/fim natural do som ja removem este timer - ver
        ; acima) - consulta GetSoundPosition() de verdade em vez de estimar
        ; o tempo decorrido por conta propria (imune a qualquer atraso de
        ; inicio do driver de audio). So redesenha a grade quando o pattern
        ; realmente muda (nao a cada tick de 40ms), pra nao piscar a toa.
        If EventTimer() = #SeeEd_PlayTimerId
          Protected PosMs.l = -1
          If SoundHandle
            PosMs = GetSoundPosition(SoundHandle, #PB_Sound_Millisecond)
          EndIf
          If PosMs < 0 Or PlayStepCountLive = 0 Or PosMs >= PlayTotalMsLive
            RemoveWindowTimer(Win, #SeeEd_PlayTimerId)
            If PlayCursorPattern <> -1
              PlayCursorPattern = -1
              SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)
            EndIf
          Else
            Protected StepFind.i = 0
            While StepFind < PlayStepCountLive - 1 And PlayStepStartMs(StepFind + 1) <= PosMs
              StepFind + 1
            Wend
            Protected NewCursorPat.i = PlayPatArr(StepFind)
            If NewCursorPat <> PlayCursorPattern
              PlayCursorPattern = NewCursorPat
              ; Acompanha o cursor: rola a grade automaticamente se o
              ; pattern tocando agora saiu da area visivel, senao um efeito
              ; com mais patterns que #SeeEd_GridRows deixaria o usuario sem
              ; ver o cursor andar assim que ele passasse da 18a linha.
              If PlayCursorPattern < ScrollTop Or PlayCursorPattern >= ScrollTop + #SeeEd_GridRows
                ScrollTop = PlayCursorPattern - #SeeEd_GridRows / 2
                If ScrollTop < 0 : ScrollTop = 0 : EndIf
                Protected MaxScroll.i = NumPatterns - #SeeEd_GridRows
                If MaxScroll < 0 : MaxScroll = 0 : EndIf
                If ScrollTop > MaxScroll : ScrollTop = MaxScroll : EndIf
                SetGadgetState(G_Scroll, ScrollTop)
              EndIf
              SeeEd_DrawGrid(G_Grid, PB(), NumPatterns, ScrollTop, SelPattern, PlayCursorPattern)
            EndIf
          EndIf
        EndIf

      Case #PB_Event_CloseWindow
        Quit = #True

    EndSelect
  Until Quit

  RemoveWindowTimer(Win, #SeeEd_PlayTimerId)
  If SoundHandle
    StopSound(SoundHandle)
    FreeSound(SoundHandle)
  EndIf
  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
