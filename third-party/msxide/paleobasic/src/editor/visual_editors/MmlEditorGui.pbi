;
; ------------------------------------------------------------
;  Criar -> Musica (PLAY)...: editor de MML (Music Macro Language) para o
;  comando PLAY do MSX-BASIC, cobrindo os 3 canais (A/B/C) em paralelo -
;  mesmo espirito "sequenciador" do editor de som PSG (PsgEditorGui.pbi),
;  mas cada "passo" aqui e uma LINHA de texto MML (nao um snapshot de
;  registrador), montada clicando em botoes de comando que vao acrescentando
;  tokens numa "linha atual" editavel; "Inserir nova linha" fecha essa linha
;  e comeca a proxima. O motor de parse/mixagem/sintese fica em
;  editor/MmlSynth.pbi (sem GUI, reaproveitado tambem pelo harness headless
;  editor/tools/MmlTestCli.pb); esta janela so cuida da interface e da
;  persistencia via ProjectDB::.
; ------------------------------------------------------------
;

#MmlEd_MaxLines = 200

Global MmlEd_SoundSystemReady.b = #False

Procedure.b MmlEd_ConfirmDiscardSong()
  ProcedureReturn Bool(MessageRequester("Musica nao registrada",
                        "As alteracoes desta musica ainda nao foram registradas no projeto." + Chr(10) +
                        "Descartar mesmo assim?",
                        #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
EndProcedure

Procedure.i MmlEd_FindNavTarget(List Nav.i(), Direction.i, CurrentNumber.i)
  Protected Target.i = -1
  Select Direction
    Case 0
      If ListSize(Nav()) > 0
        FirstElement(Nav())
        Target = Nav()
      EndIf
    Case 3
      If ListSize(Nav()) > 0
        LastElement(Nav())
        Target = Nav()
      EndIf
    Case 1
      ForEach Nav()
        If Nav() < CurrentNumber And Nav() > Target
          Target = Nav()
        EndIf
      Next
    Case 2
      ForEach Nav()
        If Nav() > CurrentNumber And (Target = -1 Or Nav() < Target)
          Target = Nav()
        EndIf
      Next
  EndSelect
  ProcedureReturn Target
EndProcedure

; Acha em qual dos 3 elementos de Ids() esta EvG - devolve o indice do canal
; (0-2) ou -1. Usado pra despachar eventos dos botoes repetidos por canal sem
; precisar de 3x Case explicito pra cada um.
Procedure.i MmlEd_ChanOf(EvG.i, Array Ids.i(1))
  Protected c
  For c = 0 To 2
    If Ids(c) = EvG
      ProcedureReturn c
    EndIf
  Next
  ProcedureReturn -1
EndProcedure

Procedure MmlEd_RefreshList(G_List, Array Lines.s(2), Channel.i, LineCount.i)
  Protected i, Selected = GetGadgetState(G_List)
  ClearGadgetItems(G_List)
  For i = 0 To LineCount - 1
    AddGadgetItem(G_List, -1, Str(i) + Chr(10) + Lines(Channel, i))
  Next
  If Selected >= 0 And Selected < LineCount
    SetGadgetState(G_List, Selected)
  EndIf
EndProcedure

; Concatena as linhas 0..Count-1 de um canal (sem separador - cada linha ja e
; um trecho de MML valido por si so) mais, opcionalmente, a linha em edicao
; no final (pra "Tocar" poder prever antes de "Inserir nova linha").
Procedure.s MmlEd_JoinForPlay(Array Lines.s(2), Channel.i, LineCount.i, PendingText.s)
  Protected Result.s = ""
  Protected i
  For i = 0 To LineCount - 1
    Result + Lines(Channel, i)
  Next
  Result + PendingText
  ProcedureReturn Result
EndProcedure

Procedure MmlEditor_OpenWindow(ParentWindow)
  Protected ColW = 330
  Dim ColX.i(2)
  ColX(0) = 15 : ColX(1) = 360 : ColX(2) = 705
  Protected WinW = 1050
  Protected TopY = 45
  Protected ColH = 430

  Protected BelowY = TopY + ColH + 10
  Protected WinH = BelowY + 28 + 10 + 26 + 10 + 100 + 10 + 28 + 15

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Criar musica PLAY (MML)",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  If Not MmlEd_SoundSystemReady
    InitSound()
    MmlEd_SoundSystemReady = #True
  EndIf

  ; --- Barra de projeto ---
  Protected Cx = 15
  TextGadget(#PB_Any, Cx, 16, 55, 20, "Musica:")
  Cx + 55 + 4
  Protected G_SongNumberText = TextGadget(#PB_Any, Cx, 16, 40, 20, "#1")
  Cx + 40 + 10

  Protected G_First = ThemedButton(Cx, 12, 28, 26, Chr(9198), "")
  GadgetToolTip(G_First, "Primeira musica")
  Cx + 28 + 2
  Protected G_Prev = ThemedButton(Cx, 12, 28, 26, Chr(9664), "")
  GadgetToolTip(G_Prev, "Musica anterior")
  Cx + 28 + 2
  Protected G_Next = ThemedButton(Cx, 12, 28, 26, Chr(9654), "")
  GadgetToolTip(G_Next, "Proxima musica")
  Cx + 28 + 2
  Protected G_Last = ThemedButton(Cx, 12, 28, 26, Chr(9197), "")
  GadgetToolTip(G_Last, "Ultima musica")
  Cx + 28 + 16

  TextGadget(#PB_Any, Cx, 16, 32, 20, "Tag:")
  Cx + 32 + 4
  Protected G_Tag = StringGadget(#PB_Any, Cx, 14, 130, 22, "")
  GadgetToolTip(G_Tag, "Nome curto pra identificar a musica (ate 16 caracteres)")
  Cx + 130 + 16

  Protected NewSongIcon = SpriteEd_CreateNewSpriteIcon(22)
  Protected G_New = ButtonImageGadget(#PB_Any, Cx, 12, 34, 26, ImageID(NewSongIcon))
  GadgetToolTip(G_New, "Nova musica (numera automaticamente)")
  Cx + 34 + 6

  Protected RegisterSongIcon = SpriteEd_CreateRegisterIcon(22)
  Protected G_Register = ButtonImageGadget(#PB_Any, Cx, 12, 34, 26, ImageID(RegisterSongIcon))
  GadgetToolTip(G_Register, "Registrar: grava esta musica no banco do projeto")

  ; --- Colunas dos 3 canais ---
  Dim G_CurLine.i(2)
  Dim G_Accidental.i(2)
  Dim G_Duration.i(2)
  Dim G_Dots.i(2)
  Dim G_Note.i(2, 6)
  Dim G_Pause.i(2)
  Dim G_NoteNumField.i(2)
  Dim G_NoteNumBtn.i(2)
  Dim G_OctField.i(2)
  Dim G_OctBtn.i(2)
  Dim G_OctUp.i(2)
  Dim G_OctDown.i(2)
  Dim G_LenField.i(2)
  Dim G_LenBtn.i(2)
  Dim G_TempoField.i(2)
  Dim G_TempoBtn.i(2)
  Dim G_VolField.i(2)
  Dim G_VolBtn.i(2)
  Dim G_EnvPeriodField.i(2)
  Dim G_EnvPeriodBtn.i(2)
  Dim G_EnvShapeField.i(2)
  Dim G_EnvShapeBtn.i(2)
  Dim G_ClearLine.i(2)
  Dim G_NewLine.i(2)
  Dim G_UpdateLine.i(2)
  Dim G_LineList.i(2)
  Dim G_RemoveLine.i(2)
  Dim G_MoveUp.i(2)
  Dim G_MoveDown.i(2)

  Protected c, n, FX, Cy
  Protected ChannelNames.s = "ABC"
  Protected NoteNames.s = "CDEFGAB"

  For c = 0 To 2
    FX = ColX(c)
    FrameGadget(#PB_Any, FX, TopY, ColW, ColH, "Canal " + Mid(ChannelNames, c + 1, 1))

    TextGadget(#PB_Any, FX + 10, TopY + 20, 200, 18, "Linha atual:")
    G_CurLine(c) = StringGadget(#PB_Any, FX + 10, TopY + 38, ColW - 20, 22, "")
    GadgetToolTip(G_CurLine(c), "Texto MML sendo montado - os botoes abaixo acrescentam aqui; tambem pode digitar direto")

    ; Notas + pausa numa unica fileira (8 botoes de letra, "R" no mesmo
    ; estilo das notas em vez de um botao largo "Pausa (R)" a parte).
    Cy = TopY + 68
    For n = 0 To 6
      G_Note(c, n) = ThemedButton(FX + 10 + n * 34, Cy, 30, 24, Mid(NoteNames, n + 1, 1), "")
    Next
    GadgetToolTip(G_Note(c, 0), "Insere a nota (usa o acidente/duracao/pontos correntes ao lado)")
    G_Pause(c) = ThemedButton(FX + 10 + 7 * 34, Cy, 30, 24, "R", "")
    GadgetToolTip(G_Pause(c), "Pausa - insere uma pausa (usa duracao/pontos correntes)")

    Cy + 30
    G_Accidental(c) = ComboBoxGadget(#PB_Any, FX + 10, Cy, 120, 22)
    AddGadgetItem(G_Accidental(c), -1, "Natural")
    AddGadgetItem(G_Accidental(c), -1, "Sustenido (+)")
    AddGadgetItem(G_Accidental(c), -1, "Bemol (-)")
    SetGadgetState(G_Accidental(c), 0)
    GadgetToolTip(G_Accidental(c), "Acidente aplicado a proxima nota clicada")
    TextGadget(#PB_Any, FX + 136, Cy + 3, 16, 18, "D")
    G_Duration(c) = StringGadget(#PB_Any, FX + 150, Cy, 44, 22, "")
    GadgetToolTip(G_Duration(c), "Duracao da proxima nota/pausa (1-64, vazio = usa L atual)")
    TextGadget(#PB_Any, FX + 198, Cy + 3, 12, 18, ".")
    G_Dots(c) = StringGadget(#PB_Any, FX + 210, Cy, 34, 22, "0")
    GadgetToolTip(G_Dots(c), "Pontos de aumento (0-3) da proxima nota/pausa")

    ; Comandos parametrizados: campo + botao "+" compacto (em vez do antigo
    ; "Inserir N"/"Definir O"/"Definir L"/etc.) - o rotulo de 1 letra ja diz o
    ; comando MML, o "+" so confirma "acrescenta na linha atual". N e O juntam
    ; a mesma fileira (ambos mudam a nota/oitava), assim como L+T (parametros
    ; de tempo) e M+S (parametros de envelope).
    Cy + 28
    TextGadget(#PB_Any, FX + 10, Cy + 3, 12, 18, "N")
    G_NoteNumField(c) = StringGadget(#PB_Any, FX + 22, Cy, 42, 22, "")
    G_NoteNumBtn(c) = ThemedButton(FX + 66, Cy, 26, 22, "+", "")
    GadgetToolTip(G_NoteNumBtn(c), "Insere nota absoluta por numero (1-96, cromatica, 8 oitavas)")
    TextGadget(#PB_Any, FX + 104, Cy + 3, 12, 18, "O")
    G_OctField(c) = StringGadget(#PB_Any, FX + 116, Cy, 28, 22, "4")
    G_OctBtn(c) = ThemedButton(FX + 146, Cy, 26, 22, "+", "")
    GadgetToolTip(G_OctBtn(c), "Define a oitava atual (1-8)")
    G_OctUp(c) = ThemedButton(FX + 176, Cy, 26, 22, ">", "")
    GadgetToolTip(G_OctUp(c), "Sobe 1 oitava")
    G_OctDown(c) = ThemedButton(FX + 204, Cy, 26, 22, "<", "")
    GadgetToolTip(G_OctDown(c), "Desce 1 oitava")

    Cy + 28
    TextGadget(#PB_Any, FX + 10, Cy + 3, 12, 18, "L")
    G_LenField(c) = StringGadget(#PB_Any, FX + 22, Cy, 28, 22, "4")
    G_LenBtn(c) = ThemedButton(FX + 52, Cy, 26, 22, "+", "")
    GadgetToolTip(G_LenBtn(c), "Define a duracao padrao (1-64) das notas/pausas sem duracao explicita")
    TextGadget(#PB_Any, FX + 90, Cy + 3, 12, 18, "T")
    G_TempoField(c) = StringGadget(#PB_Any, FX + 102, Cy, 38, 22, "120")
    G_TempoBtn(c) = ThemedButton(FX + 142, Cy, 26, 22, "+", "")
    GadgetToolTip(G_TempoBtn(c), "Define o andamento em BPM (32-255)")

    Cy + 28
    TextGadget(#PB_Any, FX + 10, Cy + 3, 12, 18, "V")
    G_VolField(c) = StringGadget(#PB_Any, FX + 22, Cy, 28, 22, "8")
    G_VolBtn(c) = ThemedButton(FX + 52, Cy, 26, 22, "+", "")
    GadgetToolTip(G_VolBtn(c), "Define o volume do canal (0-15) - volta ao modo volume fixo (desliga o envelope)")

    Cy + 28
    TextGadget(#PB_Any, FX + 10, Cy + 3, 12, 18, "M")
    G_EnvPeriodField(c) = StringGadget(#PB_Any, FX + 22, Cy, 46, 22, "1000")
    G_EnvPeriodBtn(c) = ThemedButton(FX + 70, Cy, 26, 22, "+", "")
    GadgetToolTip(G_EnvPeriodBtn(c), "Define o periodo do envelope (1-65535) - so 1 gerador, compartilhado pelos 3 canais")
    TextGadget(#PB_Any, FX + 108, Cy + 3, 12, 18, "S")
    G_EnvShapeField(c) = StringGadget(#PB_Any, FX + 120, Cy, 28, 22, "0")
    G_EnvShapeBtn(c) = ThemedButton(FX + 150, Cy, 26, 22, "+", "")
    GadgetToolTip(G_EnvShapeBtn(c), "Define a forma do envelope (0-15) - liga o modo envelope neste canal e retrigga")

    Cy + 30
    G_ClearLine(c) = ThemedButton(FX + 10, Cy, 90, 24, "Limpar linha", Chr(#Icon_Clear))
    GadgetToolTip(G_ClearLine(c), "Apaga a linha atual (recomeca do zero)")
    G_UpdateLine(c) = ThemedButton(FX + 104, Cy, 90, 24, "Atualizar", "")
    GadgetToolTip(G_UpdateLine(c), "Aplica a linha atual sobre a linha selecionada na lista")
    G_NewLine(c) = ThemedButton(FX + 198, Cy, 122, 24, "Inserir nova linha", Chr(#Icon_Insert))
    GadgetToolTip(G_NewLine(c), "Fecha a linha atual como uma nova entrada na lista abaixo")

    Cy + 30
    G_LineList(c) = ListIconGadget(#PB_Any, FX + 10, Cy, ColW - 20, 108, "#", 30, #PB_ListIcon_FullRowSelect)
    AddGadgetColumn(G_LineList(c), 1, "Linha MML", ColW - 60)

    Cy + 112
    G_RemoveLine(c) = ThemedButton(FX + 10, Cy, 34, 24, "-", "")
    GadgetToolTip(G_RemoveLine(c), "Remove a linha selecionada")
    G_MoveUp(c) = ThemedButton(FX + 50, Cy, 34, 24, Chr(9650), "")
    GadgetToolTip(G_MoveUp(c), "Mover linha pra cima")
    G_MoveDown(c) = ThemedButton(FX + 88, Cy, 34, 24, Chr(9660), "")
    GadgetToolTip(G_MoveDown(c), "Mover linha pra baixo")
  Next

  ; --- Tocar/Parar + status ---
  Protected G_Play = ThemedButton(15, BelowY, 100, 28, "Tocar", Chr(#Icon_Play))
  GadgetToolTip(G_Play, "Toca os 3 canais juntos (linhas ja inseridas + a linha atual de cada canal)")
  Protected G_Stop = ThemedButton(125, BelowY, 100, 28, "Parar", Chr(#Icon_Stop))
  GadgetToolTip(G_Stop, "Parar")
  Protected G_Status = TextGadget(#PB_Any, 240, BelowY + 4, 700, 20, "")

  ; --- Geracao de codigo ---
  Protected GenY = BelowY + 28 + 10
  Protected G_GenPlay = ThemedButton(15, GenY, 165, 26, "Gerar codigo PLAY", "")
  Protected G_Inject = ThemedButton(190, GenY, 150, 26, "Injetar no cursor", Chr(#Icon_Insert))
  GadgetToolTip(G_Inject, "Insere o codigo gerado abaixo no cursor da aba de texto ativa")
  Protected G_Copy = ThemedButton(350, GenY, 100, 26, "Copiar", Chr(#Icon_Copy))
  GadgetToolTip(G_Copy, "Copia o codigo gerado abaixo para a area de transferencia")

  Protected CodeY = GenY + 26 + 8
  Protected G_CodeOutput = EditorGadget(#PB_Any, 15, CodeY, WinW - 30, 100)

  Protected G_Close = ThemedButton(WinW - 15 - 90, CodeY + 100 + 10, 90, 28, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  ; --- Estado ---
  Dim Lines.s(2, #MmlEd_MaxLines - 1)
  Dim LineCount.i(2)
  Dim SelectedLine.i(2)
  Dim CurAccidentalSuffix.s(2)
  For c = 0 To 2
    LineCount(c) = 0
    SelectedLine(c) = -1
  Next

  Protected SongNumber.i = 1
  Protected SongTag.s = ""
  Protected SongDirty.b = #False
  Protected SoundHandle.i = 0
  Protected TempWavPath.s = GetTemporaryDirectory() + "badig_mml_preview.wav"

  NewList Nav.i()
  ProjectDB::ListSongNumbers(Nav())
  If ListSize(Nav()) > 0
    FirstElement(Nav())
    SongNumber = Nav()
    If ProjectDB::FetchSong(SongNumber, Lines(), LineCount())
      SetGadgetText(G_Tag, ProjectDB::LastSongTag())
    EndIf
  EndIf
  SetGadgetText(G_SongNumberText, "#" + Str(SongNumber))
  For c = 0 To 2
    MmlEd_RefreshList(G_LineList(c), Lines(), c, LineCount(c))
  Next

  Protected Event, Quit = #False
  Protected NavTarget.i, NextNumber.i, k, j
  Protected EvG

  Repeat
    Event = WaitWindowEvent()
    Select Event

      Case #PB_Event_Gadget
        EvG = EventGadget()

        If EvG = G_Tag
          If EventType() = #PB_EventType_Change
            If Len(GetGadgetText(G_Tag)) > 16
              SetGadgetText(G_Tag, Left(GetGadgetText(G_Tag), 16))
            EndIf
          EndIf

        ElseIf EvG = G_First Or EvG = G_Prev Or EvG = G_Next Or EvG = G_Last
          Protected Dir = -1
          If EvG = G_First : Dir = 0
          ElseIf EvG = G_Prev : Dir = 1
          ElseIf EvG = G_Next : Dir = 2
          ElseIf EvG = G_Last : Dir = 3
          EndIf
          If Not SongDirty Or MmlEd_ConfirmDiscardSong()
            ProjectDB::ListSongNumbers(Nav())
            NavTarget = MmlEd_FindNavTarget(Nav(), Dir, SongNumber)
            If NavTarget >= 0
              If ProjectDB::FetchSong(NavTarget, Lines(), LineCount())
                SongNumber = NavTarget
                SetGadgetText(G_Tag, ProjectDB::LastSongTag())
                SetGadgetText(G_SongNumberText, "#" + Str(SongNumber))
                For c = 0 To 2
                  SelectedLine(c) = -1
                  SetGadgetText(G_CurLine(c), "")
                  MmlEd_RefreshList(G_LineList(c), Lines(), c, LineCount(c))
                Next
                SongDirty = #False
                SetGadgetText(G_Status, "Musica #" + Str(SongNumber) + " carregada.")
              EndIf
            EndIf
          EndIf

        ElseIf EvG = G_New
          If Not SongDirty Or MmlEd_ConfirmDiscardSong()
            ProjectDB::ListSongNumbers(Nav())
            NextNumber = 1
            If ListSize(Nav()) > 0
              LastElement(Nav())
              NextNumber = Nav() + 1
            EndIf
            SongNumber = NextNumber
            SongTag = ""
            SetGadgetText(G_Tag, "")
            SetGadgetText(G_SongNumberText, "#" + Str(SongNumber))
            For c = 0 To 2
              LineCount(c) = 0
              SelectedLine(c) = -1
              SetGadgetText(G_CurLine(c), "")
              MmlEd_RefreshList(G_LineList(c), Lines(), c, 0)
            Next
            SongDirty = #False
            SetGadgetText(G_Status, "Nova musica #" + Str(SongNumber) + ".")
          EndIf

        ElseIf EvG = G_Register
          SongTag = Left(GetGadgetText(G_Tag), 16)
          SetGadgetText(G_Tag, SongTag)
          If ProjectDB::StoreSong(SongNumber, SongTag, Lines(), LineCount())
            SongDirty = #False
            SetGadgetText(G_Status, "Musica #" + Str(SongNumber) + " registrada.")
          Else
            MessageRequester("Erro ao registrar",
                              "Nao foi possivel gravar a musica:" + Chr(10) + ProjectDB::GetLastError(),
                              #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
          EndIf

        ElseIf EvG = G_Play
          NewList EvA.MmlNoteEvent()
          NewList EnvA.MmlEnvCmd()
          NewList EvB.MmlNoteEvent()
          NewList EnvB.MmlEnvCmd()
          NewList EvC.MmlNoteEvent()
          NewList EnvC.MmlEnvCmd()
          MmlSynth_ParseChannel(MmlEd_JoinForPlay(Lines(), 0, LineCount(0), GetGadgetText(G_CurLine(0))), EvA(), EnvA(), #Psg_SampleRate)
          MmlSynth_ParseChannel(MmlEd_JoinForPlay(Lines(), 1, LineCount(1), GetGadgetText(G_CurLine(1))), EvB(), EnvB(), #Psg_SampleRate)
          MmlSynth_ParseChannel(MmlEd_JoinForPlay(Lines(), 2, LineCount(2), GetGadgetText(G_CurLine(2))), EvC(), EnvC(), #Psg_SampleRate)
          Protected TotalSamp = MmlSynth_SongTotalSamples(EvA(), EvB(), EvC())
          If TotalSamp > 0
            Protected *SongBuf = MmlSynth_RenderSong(EvA(), EvB(), EvC(), EnvA(), EnvB(), EnvC(), #Psg_SampleRate, TotalSamp)
            If *SongBuf
              PsgSynth_WriteWav(*SongBuf, TotalSamp, #Psg_SampleRate, TempWavPath)
              FreeMemory(*SongBuf)
              If SoundHandle
                StopSound(SoundHandle)
                FreeSound(SoundHandle)
              EndIf
              SoundHandle = LoadSound(#PB_Any, TempWavPath)
              If SoundHandle
                PlaySound(SoundHandle)
                SetGadgetText(G_Status, "Reproduzindo...")
              Else
                SetGadgetText(G_Status, "Nao foi possivel carregar o .wav renderizado.")
              EndIf
            EndIf
          Else
            MessageRequester("Nada para tocar", "Monte pelo menos uma nota em algum canal antes de Tocar.", #PB_MessageRequester_Ok)
          EndIf

        ElseIf EvG = G_Stop
          If SoundHandle
            StopSound(SoundHandle)
          EndIf
          SetGadgetText(G_Status, "")

        ElseIf EvG = G_GenPlay
          Protected PlayTextA.s = MmlEd_JoinForPlay(Lines(), 0, LineCount(0), GetGadgetText(G_CurLine(0)))
          Protected PlayTextB.s = MmlEd_JoinForPlay(Lines(), 1, LineCount(1), GetGadgetText(G_CurLine(1)))
          Protected PlayTextC.s = MmlEd_JoinForPlay(Lines(), 2, LineCount(2), GetGadgetText(G_CurLine(2)))
          Protected PlayCode.s = MmlSynth_BuildPlayStatement(PlayTextA, PlayTextB, PlayTextC)
          If PlayCode = ""
            MessageRequester("Nada para gerar", "Monte pelo menos uma nota em algum canal antes de gerar codigo.", #PB_MessageRequester_Ok)
          Else
            SetGadgetText(G_CodeOutput, PlayCode)
          EndIf

        ElseIf EvG = G_Inject
          Protected InjectCode.s = GetGadgetText(G_CodeOutput)
          If InjectCode = ""
            MessageRequester("Nada para injetar", "Gere o codigo primeiro (Gerar codigo PLAY).", #PB_MessageRequester_Ok)
          ElseIf InjectTextAtCursor(InjectCode)
            SetGadgetText(G_Status, "Codigo injetado no cursor.")
          Else
            MessageRequester("Nao foi possivel injetar",
                              "Nenhuma aba de texto ativa no editor pra receber o codigo.",
                              #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
          EndIf

        ElseIf EvG = G_Copy
          Protected CopyCode.s = GetGadgetText(G_CodeOutput)
          If CopyCode <> ""
            SetClipboardText(CopyCode)
            SetGadgetText(G_Status, "Codigo copiado para a area de transferencia.")
          EndIf

        ElseIf EvG = G_Close
          If Not SongDirty Or MmlEd_ConfirmDiscardSong()
            Quit = #True
          EndIf

        Else
          ; --- eventos repetidos por canal (notas, comandos, lista de linhas) ---
          Protected Handled.b = #False

          For c = 0 To 2
            For n = 0 To 6
              If EvG = G_Note(c, n)
                Protected AccIdx = GetGadgetState(G_Accidental(c))
                Protected AccSuffix.s = ""
                If AccIdx = 1 : AccSuffix = "+"
                ElseIf AccIdx = 2 : AccSuffix = "-"
                EndIf
                Protected DurText.s = Trim(GetGadgetText(G_Duration(c)))
                Protected DotsN = MmlSynth_Clamp(Val(GetGadgetText(G_Dots(c))), 0, 3)
                Protected DotsStr.s = ""
                Protected di
                For di = 1 To DotsN
                  DotsStr + "."
                Next
                SetGadgetText(G_CurLine(c), GetGadgetText(G_CurLine(c)) + Mid(NoteNames, n + 1, 1) + AccSuffix + DurText + DotsStr)
                SongDirty = #True
                Handled = #True
              EndIf
            Next
          Next

          If Not Handled
            c = MmlEd_ChanOf(EvG, G_Pause())
            If c >= 0
              Protected PDurText.s = Trim(GetGadgetText(G_Duration(c)))
              Protected PDotsN = MmlSynth_Clamp(Val(GetGadgetText(G_Dots(c))), 0, 3)
              Protected PDotsStr.s = ""
              Protected pdi
              For pdi = 1 To PDotsN
                PDotsStr + "."
              Next
              SetGadgetText(G_CurLine(c), GetGadgetText(G_CurLine(c)) + "R" + PDurText + PDotsStr)
              SongDirty = #True
              Handled = #True
            EndIf
          EndIf

          If Not Handled
            c = MmlEd_ChanOf(EvG, G_NoteNumBtn())
            If c >= 0
              SetGadgetText(G_CurLine(c), GetGadgetText(G_CurLine(c)) + "N" + Trim(GetGadgetText(G_NoteNumField(c))))
              SongDirty = #True
              Handled = #True
            EndIf
          EndIf

          If Not Handled
            c = MmlEd_ChanOf(EvG, G_OctBtn())
            If c >= 0
              SetGadgetText(G_CurLine(c), GetGadgetText(G_CurLine(c)) + "O" + Trim(GetGadgetText(G_OctField(c))))
              SongDirty = #True
              Handled = #True
            EndIf
          EndIf

          If Not Handled
            c = MmlEd_ChanOf(EvG, G_OctUp())
            If c >= 0
              SetGadgetText(G_CurLine(c), GetGadgetText(G_CurLine(c)) + ">")
              SongDirty = #True
              Handled = #True
            EndIf
          EndIf

          If Not Handled
            c = MmlEd_ChanOf(EvG, G_OctDown())
            If c >= 0
              SetGadgetText(G_CurLine(c), GetGadgetText(G_CurLine(c)) + "<")
              SongDirty = #True
              Handled = #True
            EndIf
          EndIf

          If Not Handled
            c = MmlEd_ChanOf(EvG, G_LenBtn())
            If c >= 0
              SetGadgetText(G_CurLine(c), GetGadgetText(G_CurLine(c)) + "L" + Trim(GetGadgetText(G_LenField(c))))
              SongDirty = #True
              Handled = #True
            EndIf
          EndIf

          If Not Handled
            c = MmlEd_ChanOf(EvG, G_TempoBtn())
            If c >= 0
              SetGadgetText(G_CurLine(c), GetGadgetText(G_CurLine(c)) + "T" + Trim(GetGadgetText(G_TempoField(c))))
              SongDirty = #True
              Handled = #True
            EndIf
          EndIf

          If Not Handled
            c = MmlEd_ChanOf(EvG, G_VolBtn())
            If c >= 0
              SetGadgetText(G_CurLine(c), GetGadgetText(G_CurLine(c)) + "V" + Trim(GetGadgetText(G_VolField(c))))
              SongDirty = #True
              Handled = #True
            EndIf
          EndIf

          If Not Handled
            c = MmlEd_ChanOf(EvG, G_EnvPeriodBtn())
            If c >= 0
              SetGadgetText(G_CurLine(c), GetGadgetText(G_CurLine(c)) + "M" + Trim(GetGadgetText(G_EnvPeriodField(c))))
              SongDirty = #True
              Handled = #True
            EndIf
          EndIf

          If Not Handled
            c = MmlEd_ChanOf(EvG, G_EnvShapeBtn())
            If c >= 0
              SetGadgetText(G_CurLine(c), GetGadgetText(G_CurLine(c)) + "S" + Trim(GetGadgetText(G_EnvShapeField(c))))
              SongDirty = #True
              Handled = #True
            EndIf
          EndIf

          If Not Handled
            c = MmlEd_ChanOf(EvG, G_ClearLine())
            If c >= 0
              SetGadgetText(G_CurLine(c), "")
              Handled = #True
            EndIf
          EndIf

          If Not Handled
            c = MmlEd_ChanOf(EvG, G_NewLine())
            If c >= 0
              If LineCount(c) < #MmlEd_MaxLines And Trim(GetGadgetText(G_CurLine(c))) <> ""
                Lines(c, LineCount(c)) = GetGadgetText(G_CurLine(c))
                LineCount(c) + 1
                SetGadgetText(G_CurLine(c), "")
                MmlEd_RefreshList(G_LineList(c), Lines(), c, LineCount(c))
                SetGadgetState(G_LineList(c), LineCount(c) - 1)
                SelectedLine(c) = -1
                SongDirty = #True
              EndIf
              Handled = #True
            EndIf
          EndIf

          If Not Handled
            c = MmlEd_ChanOf(EvG, G_UpdateLine())
            If c >= 0
              If SelectedLine(c) >= 0 And SelectedLine(c) < LineCount(c)
                Lines(c, SelectedLine(c)) = GetGadgetText(G_CurLine(c))
                MmlEd_RefreshList(G_LineList(c), Lines(), c, LineCount(c))
                SongDirty = #True
              Else
                MessageRequester("Nenhuma linha selecionada", "Selecione uma linha na lista pra atualizar.", #PB_MessageRequester_Ok)
              EndIf
              Handled = #True
            EndIf
          EndIf

          If Not Handled
            c = MmlEd_ChanOf(EvG, G_RemoveLine())
            If c >= 0
              If SelectedLine(c) >= 0 And SelectedLine(c) < LineCount(c)
                For k = SelectedLine(c) To LineCount(c) - 2
                  Lines(c, k) = Lines(c, k + 1)
                Next
                LineCount(c) - 1
                SelectedLine(c) = -1
                MmlEd_RefreshList(G_LineList(c), Lines(), c, LineCount(c))
                SongDirty = #True
              EndIf
              Handled = #True
            EndIf
          EndIf

          If Not Handled
            c = MmlEd_ChanOf(EvG, G_MoveUp())
            If c >= 0
              If SelectedLine(c) > 0 And SelectedLine(c) < LineCount(c)
                Protected TmpLineU.s = Lines(c, SelectedLine(c) - 1)
                Lines(c, SelectedLine(c) - 1) = Lines(c, SelectedLine(c))
                Lines(c, SelectedLine(c)) = TmpLineU
                SelectedLine(c) - 1
                MmlEd_RefreshList(G_LineList(c), Lines(), c, LineCount(c))
                SetGadgetState(G_LineList(c), SelectedLine(c))
                SongDirty = #True
              EndIf
              Handled = #True
            EndIf
          EndIf

          If Not Handled
            c = MmlEd_ChanOf(EvG, G_MoveDown())
            If c >= 0
              If SelectedLine(c) >= 0 And SelectedLine(c) < LineCount(c) - 1
                Protected TmpLineD.s = Lines(c, SelectedLine(c) + 1)
                Lines(c, SelectedLine(c) + 1) = Lines(c, SelectedLine(c))
                Lines(c, SelectedLine(c)) = TmpLineD
                SelectedLine(c) + 1
                MmlEd_RefreshList(G_LineList(c), Lines(), c, LineCount(c))
                SetGadgetState(G_LineList(c), SelectedLine(c))
                SongDirty = #True
              EndIf
              Handled = #True
            EndIf
          EndIf

          If Not Handled
            c = MmlEd_ChanOf(EvG, G_LineList())
            If c >= 0
              SelectedLine(c) = GetGadgetState(G_LineList(c))
              If SelectedLine(c) >= 0 And SelectedLine(c) < LineCount(c)
                SetGadgetText(G_CurLine(c), Lines(c, SelectedLine(c)))
              EndIf
              Handled = #True
            EndIf
          EndIf
        EndIf

      Case #PB_Event_CloseWindow
        If Not SongDirty Or MmlEd_ConfirmDiscardSong()
          Quit = #True
        EndIf

    EndSelect
  Until Quit

  If SoundHandle
    StopSound(SoundHandle)
    FreeSound(SoundHandle)
  EndIf
  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
