;
; ------------------------------------------------------------
;  Criar -> Som (PSG)...: editor de efeitos sonoros para o PSG AY-3-8910/
;  YM2149 do MSX, espelhando os registradores 0-13 do comando SOUND (canais
;  A/B/C de tom, ruido, envelope de volume por hardware). Um "som" e uma
;  pequena sequencia de passos - cada um com os 14 registradores crus + uma
;  duracao em quadros - um mini-sequenciador de UM instrumento/efeito, nao
;  um tracker multi-canal (isso fica pro modulo 7 do SPEC, ainda nao
;  especificado). O motor de sintese e a geracao de codigo ficam em
;  editor/PsgSynth.pbi (sem GUI, reaproveitado tambem pelo harness headless
;  editor/tools/PsgTestCli.pb); esta janela so cuida da interface e da
;  persistencia via ProjectDB::.
; ------------------------------------------------------------
;

#PsgEd_MaxSteps = 64

Global PsgEd_SoundSystemReady.b = #False

Procedure.i PsgEd_ClampInt(v.i, lo.i, hi.i)
  If v < lo : v = lo : EndIf
  If v > hi : v = hi : EndIf
  ProcedureReturn v
EndProcedure

Procedure.b PsgEd_ConfirmDiscardSound()
  ProcedureReturn Bool(MessageRequester("Som nao registrado",
                        "As alteracoes deste som ainda nao foram registradas no projeto." + Chr(10) +
                        "Descartar mesmo assim?",
                        #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
EndProcedure

; Mesma logica de SpriteEd_FindNavTarget (SpriteEditorGui.pbi) - acha o
; numero de som alvo dentro de Nav() (lista ordenada crescente de
; ProjectDB::ListSoundNumbers) pra cada botao de navegacao. Direction:
; 0=Primeiro, 1=Anterior, 2=Proximo, 3=Ultimo.
Procedure.i PsgEd_FindNavTarget(List Nav.i(), Direction.i, CurrentNumber.i)
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

Procedure.s PsgEd_EnvShapeLabel(Shape.i)
  Select Shape
    Case 0, 1, 2, 3
      ProcedureReturn Str(Shape) + " - pulso unico (decai, desliga)"
    Case 4, 5, 6, 7
      ProcedureReturn Str(Shape) + " - pulso unico (sobe, desliga)"
    Case 8
      ProcedureReturn "8 - decai repetindo"
    Case 9
      ProcedureReturn "9 - decai e para"
    Case 10
      ProcedureReturn "10 - decai/sobe alternando"
    Case 11
      ProcedureReturn "11 - decai e mantem no maximo"
    Case 12
      ProcedureReturn "12 - sobe repetindo"
    Case 13
      ProcedureReturn "13 - sobe e mantem no maximo"
    Case 14
      ProcedureReturn "14 - sobe/decai alternando"
    Case 15
      ProcedureReturn "15 - sobe e para"
  EndSelect
  ProcedureReturn Str(Shape)
EndProcedure

; Resumo de uma linha pra mostrar na lista de passos - so os canais que
; realmente produzem som (tom ligado e volume>0 ou usando envelope).
Procedure.s PsgEd_StepSummary(*Step.PsgStepData)
  Protected Result.s = ""
  Protected c, TP.i, VolReg.i, UseEnv.b, ToneOn.b, Names.s = "ABC", Any.b = #False

  For c = 0 To 2
    TP = ((*Step\Regs[c * 2 + 1] & $0F) << 8) | *Step\Regs[c * 2]
    VolReg = *Step\Regs[8 + c] & $0F
    UseEnv = Bool((*Step\Regs[8 + c] & $10) <> 0)
    ToneOn = Bool(((*Step\Regs[7] >> c) & 1) = 0)
    If ToneOn And (VolReg > 0 Or UseEnv)
      If Any
        Result + " "
      EndIf
      Result + Mid(Names, c + 1, 1) + "=" + StrD(PsgSynth_PeriodToHz(TP), 0) + "Hz"
      If UseEnv
        Result + "(env)"
      Else
        Result + " v" + Str(VolReg)
      EndIf
      Any = #True
    EndIf
  Next

  If Not Any
    Result = "(silencio)"
  EndIf
  Result + "  " + Str(*Step\DurationFrames) + "q"
  ProcedureReturn Result
EndProcedure

Procedure PsgEd_RefreshList(G_List, Array Steps.PsgStepData(1), StepCount.i)
  Protected i, Selected = GetGadgetState(G_List)
  ClearGadgetItems(G_List)
  For i = 0 To StepCount - 1
    AddGadgetItem(G_List, -1, Str(i) + Chr(10) + PsgEd_StepSummary(@Steps(i)))
  Next
  If Selected >= 0 And Selected < StepCount
    SetGadgetState(G_List, Selected)
  EndIf
EndProcedure

; Le os controles do painel "passo atual" pra dentro de *Step. G_Freq()/
; G_Vol()/G_EnvOn()/G_Tone()/G_Noise() sao arrays de 3 elementos (canal
; A/B/C, indice 0-2).
Procedure PsgEd_ReadPanel(*Step.PsgStepData, Array G_Freq.i(1), Array G_Vol.i(1), Array G_EnvOn.i(1), Array G_Tone.i(1), Array G_Noise.i(1), G_NoisePeriod, G_EnvPeriod, G_EnvShape, G_Duration)
  Protected c, TP.i, EP.i
  Protected Mixer.a = 0

  For c = 0 To 2
    TP = PsgSynth_HzToPeriod(ValD(GetGadgetText(G_Freq(c))))
    *Step\Regs[c * 2]     = TP & $FF
    *Step\Regs[c * 2 + 1] = (TP >> 8) & $0F

    *Step\Regs[8 + c] = PsgEd_ClampInt(Val(GetGadgetText(G_Vol(c))), 0, 15)
    If GetGadgetState(G_EnvOn(c))
      *Step\Regs[8 + c] = *Step\Regs[8 + c] | $10
    EndIf

    If Not GetGadgetState(G_Tone(c))
      Mixer = Mixer | (1 << c)
    EndIf
    If Not GetGadgetState(G_Noise(c))
      Mixer = Mixer | (1 << (c + 3))
    EndIf
  Next
  *Step\Regs[7] = Mixer

  *Step\Regs[6] = PsgEd_ClampInt(Val(GetGadgetText(G_NoisePeriod)), 0, 31)

  EP = PsgEd_ClampInt(Val(GetGadgetText(G_EnvPeriod)), 1, 65535)
  *Step\Regs[11] = EP & $FF
  *Step\Regs[12] = (EP >> 8) & $FF
  *Step\Regs[13] = GetGadgetState(G_EnvShape)

  *Step\DurationFrames = PsgEd_ClampInt(Val(GetGadgetText(G_Duration)), 1, 600)
EndProcedure

; Sentido inverso de PsgEd_ReadPanel - carrega *Step nos controles (usado ao
; selecionar um passo na lista pra edicao).
Procedure PsgEd_WritePanel(*Step.PsgStepData, Array G_Freq.i(1), Array G_Vol.i(1), Array G_EnvOn.i(1), Array G_Tone.i(1), Array G_Noise.i(1), G_NoisePeriod, G_EnvPeriod, G_EnvShape, G_Duration)
  Protected c, TP.i

  For c = 0 To 2
    TP = ((*Step\Regs[c * 2 + 1] & $0F) << 8) | *Step\Regs[c * 2]
    SetGadgetText(G_Freq(c), StrD(PsgSynth_PeriodToHz(TP), 1))
    SetGadgetText(G_Vol(c), Str(*Step\Regs[8 + c] & $0F))
    SetGadgetState(G_EnvOn(c), Bool((*Step\Regs[8 + c] & $10) <> 0))
    SetGadgetState(G_Tone(c), Bool(((*Step\Regs[7] >> c) & 1) = 0))
    SetGadgetState(G_Noise(c), Bool(((*Step\Regs[7] >> (c + 3)) & 1) = 0))
  Next

  SetGadgetText(G_NoisePeriod, Str(*Step\Regs[6] & $1F))
  SetGadgetText(G_EnvPeriod, Str((*Step\Regs[12] << 8) | *Step\Regs[11]))
  SetGadgetState(G_EnvShape, *Step\Regs[13])
  SetGadgetText(G_Duration, Str(*Step\DurationFrames))
EndProcedure

; Volta o painel pro estado "em branco" - volume 0 em todos os canais e
; mixer todo desligado, pra um passo novo comecar em silencio garantido em
; vez de um zumbido acidental de DC (tom E ruido desligados ao mesmo tempo
; deixam o canal sempre "ligado" no mixer real do PSG).
Procedure PsgEd_ResetPanel(Array G_Freq.i(1), Array G_Vol.i(1), Array G_EnvOn.i(1), Array G_Tone.i(1), Array G_Noise.i(1), G_NoisePeriod, G_EnvPeriod, G_EnvShape, G_Duration)
  Protected c
  For c = 0 To 2
    SetGadgetText(G_Freq(c), "440")
    SetGadgetText(G_Vol(c), "0")
    SetGadgetState(G_EnvOn(c), #False)
    SetGadgetState(G_Tone(c), #False)
    SetGadgetState(G_Noise(c), #False)
  Next
  SetGadgetText(G_NoisePeriod, "16")
  SetGadgetText(G_EnvPeriod, "1000")
  SetGadgetState(G_EnvShape, 0)
  SetGadgetText(G_Duration, "10")
EndProcedure

; Busca o som TargetNumber no projeto e carrega em Steps() (array passado
; por referencia). Devolve o numero de passos carregados (0 se nao achou -
; um som registrado sempre tem pelo menos 1 passo, entao 0 e um sentinela
; seguro de falha).
Procedure.i PsgEd_LoadSound(TargetNumber.i, Array Steps.PsgStepData(1), G_StepList, G_Tag, G_SoundNumberText)
  Dim RegsFlat.a(0)
  Dim DursFlat.w(0)
  If Not ProjectDB::FetchSound(TargetNumber, RegsFlat(), DursFlat())
    ProcedureReturn 0
  EndIf

  Protected NewCount = ProjectDB::LastSoundStepCount()
  Protected i, r
  For i = 0 To NewCount - 1
    For r = 0 To 13
      Steps(i)\Regs[r] = RegsFlat(i * 14 + r)
    Next
    Steps(i)\DurationFrames = DursFlat(i)
  Next

  SetGadgetText(G_Tag, ProjectDB::LastSoundTag())
  SetGadgetText(G_SoundNumberText, "#" + Str(TargetNumber))
  PsgEd_RefreshList(G_StepList, Steps(), NewCount)
  ProcedureReturn NewCount
EndProcedure

Procedure PsgEditor_OpenWindow(ParentWindow)
  Protected WinW = 755, WinH = 758
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Criar som PSG (SOUND)",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  If Not PsgEd_SoundSystemReady
    InitSound()
    PsgEd_SoundSystemReady = #True
  EndIf

  ; --- Barra de projeto (mesmo padrao de SpriteEditorGui.pbi/CharsetEditorGui.pbi) ---
  Protected Cx = 15
  TextGadget(#PB_Any, Cx, 16, 40, 20, "Som:")
  Cx + 40 + 4
  Protected G_SoundNumberText = TextGadget(#PB_Any, Cx, 16, 40, 20, "#1")
  Cx + 40 + 10

  Protected G_First = ThemedButton(Cx, 12, 28, 26, Chr(9198), "")
  GadgetToolTip(G_First, "Primeiro som")
  Cx + 28 + 2
  Protected G_Prev = ThemedButton(Cx, 12, 28, 26, Chr(9664), "")
  GadgetToolTip(G_Prev, "Som anterior")
  Cx + 28 + 2
  Protected G_Next = ThemedButton(Cx, 12, 28, 26, Chr(9654), "")
  GadgetToolTip(G_Next, "Proximo som")
  Cx + 28 + 2
  Protected G_Last = ThemedButton(Cx, 12, 28, 26, Chr(9197), "")
  GadgetToolTip(G_Last, "Ultimo som")
  Cx + 28 + 16

  TextGadget(#PB_Any, Cx, 16, 32, 20, "Tag:")
  Cx + 32 + 4
  Protected G_Tag = StringGadget(#PB_Any, Cx, 14, 130, 22, "")
  GadgetToolTip(G_Tag, "Nome curto pra identificar o som (ate 16 caracteres)")
  Cx + 130 + 16

  Protected NewSoundIcon = SpriteEd_CreateNewSpriteIcon(22)
  Protected G_New = ButtonImageGadget(#PB_Any, Cx, 12, 34, 26, ImageID(NewSoundIcon))
  GadgetToolTip(G_New, "Novo som (numera automaticamente)")
  Cx + 34 + 6

  Protected RegisterSoundIcon = SpriteEd_CreateRegisterIcon(22)
  Protected G_Register = ButtonImageGadget(#PB_Any, Cx, 12, 34, 26, ImageID(RegisterSoundIcon))
  GadgetToolTip(G_Register, "Registrar: grava este som no banco do projeto")

  ; --- Canais A/B/C ---
  Protected ChY = 56, ChH = 190, ChW = 235
  Dim ChX.i(2)
  ChX(0) = 15 : ChX(1) = 260 : ChX(2) = 505

  Dim G_Freq.i(2)
  Dim G_Vol.i(2)
  Dim G_EnvOn.i(2)
  Dim G_Tone.i(2)
  Dim G_Noise.i(2)

  Protected c, FX
  Protected ChannelNames.s = "ABC"
  For c = 0 To 2
    FX = ChX(c)
    FrameGadget(#PB_Any, FX, ChY, ChW, ChH, "Canal " + Mid(ChannelNames, c + 1, 1))

    TextGadget(#PB_Any, FX + 10, ChY + 26, 115, 20, "Frequencia (Hz):")
    G_Freq(c) = StringGadget(#PB_Any, FX + 130, ChY + 24, 90, 22, "440")

    TextGadget(#PB_Any, FX + 10, ChY + 56, 115, 20, "Volume (0-15):")
    G_Vol(c) = StringGadget(#PB_Any, FX + 130, ChY + 54, 60, 22, "0")
    GadgetToolTip(G_Vol(c), "0 a 15")

    G_EnvOn(c) = CheckBoxGadget(#PB_Any, FX + 10, ChY + 86, 200, 22, "Usar envelope (ignora volume)")
    GadgetToolTip(G_EnvOn(c), "Volume deste canal segue o gerador de envelope compartilhado em vez do campo Volume")

    G_Tone(c) = CheckBoxGadget(#PB_Any, FX + 10, ChY + 116, 90, 22, "Tom")
    G_Noise(c) = CheckBoxGadget(#PB_Any, FX + 115, ChY + 116, 90, 22, "Ruido")
    GadgetToolTip(G_Tone(c), "Liga o oscilador de tom (onda quadrada) deste canal no mixer")
    GadgetToolTip(G_Noise(c), "Liga o gerador de ruido (compartilhado pelos 3 canais) neste canal")
  Next

  ; --- Ruido / Envelope / Duracao (compartilhados pelo passo inteiro) ---
  Protected ShY = ChY + ChH + 10
  FrameGadget(#PB_Any, 15, ShY, ChW, 70, "Ruido (compartilhado)")
  TextGadget(#PB_Any, 25, ShY + 26, 110, 20, "Periodo (0-31):")
  Protected G_NoisePeriod = StringGadget(#PB_Any, 145, ShY + 24, 60, 22, "16")
  GadgetToolTip(G_NoisePeriod, "0 a 31")

  FrameGadget(#PB_Any, 260, ShY, ChW, 70, "Envelope (compartilhado)")
  TextGadget(#PB_Any, 270, ShY + 22, 55, 20, "Periodo:")
  Protected G_EnvPeriod = StringGadget(#PB_Any, 330, ShY + 20, 80, 22, "1000")
  GadgetToolTip(G_EnvPeriod, "1 a 65535")
  Protected G_EnvShape = ComboBoxGadget(#PB_Any, 270, ShY + 46, 215, 22)
  Protected s
  For s = 0 To 15
    AddGadgetItem(G_EnvShape, -1, PsgEd_EnvShapeLabel(s))
  Next
  SetGadgetState(G_EnvShape, 0)

  FrameGadget(#PB_Any, 505, ShY, ChW, 70, "Duracao deste passo")
  TextGadget(#PB_Any, 515, ShY + 22, 140, 20, "Quadros (60 = 1s):")
  Protected G_Duration = StringGadget(#PB_Any, 515, ShY + 44, 80, 22, "10")
  GadgetToolTip(G_Duration, "1 a 600")

  ; --- Botoes de edicao de passo ---
  Protected StepBtnY = ShY + 70 + 10
  Cx = 15
  Protected G_AddStep = ThemedButton(Cx, StepBtnY, 110, 26, "Adicionar passo", "")
  Cx + 110 + 6
  Protected G_UpdateStep = ThemedButton(Cx, StepBtnY, 110, 26, "Atualizar passo", "")
  Cx + 110 + 6
  Protected G_RemoveStep = ThemedButton(Cx, StepBtnY, 100, 26, "Remover", "")
  Cx + 100 + 6
  Protected G_MoveUp = ThemedButton(Cx, StepBtnY, 34, 26, Chr(9650), "")
  GadgetToolTip(G_MoveUp, "Mover passo pra cima")
  Cx + 34 + 4
  Protected G_MoveDown = ThemedButton(Cx, StepBtnY, 34, 26, Chr(9660), "")
  GadgetToolTip(G_MoveDown, "Mover passo pra baixo")
  Cx + 34 + 12
  Protected G_DuplicateStep = ThemedButton(Cx, StepBtnY, 110, 26, "Duplicar passo", "")

  ; --- Lista de passos ---
  Protected ListY = StepBtnY + 26 + 8
  Protected G_StepList = ListIconGadget(#PB_Any, 15, ListY, 725, 130, "#", 40, #PB_ListIcon_FullRowSelect)
  AddGadgetColumn(G_StepList, 1, "Resumo", 675)

  ; --- Tocar/Parar + status ---
  Protected PlayY = ListY + 130 + 10
  Protected G_Play = ThemedButton(15, PlayY, 100, 28, "Tocar", Chr(#Icon_Play))
  GadgetToolTip(G_Play, "Tocar")
  Protected G_Stop = ThemedButton(125, PlayY, 100, 28, "Parar", Chr(#Icon_Stop))
  GadgetToolTip(G_Stop, "Parar")
  Protected G_Status = TextGadget(#PB_Any, 240, PlayY + 4, 500, 20, "")

  ; --- Geracao de codigo ---
  Protected GenY = PlayY + 28 + 10
  Protected G_GenBasic = ThemedButton(15, GenY, 165, 26, "Gerar codigo BASIC", "")
  Protected G_GenRaw = ThemedButton(190, GenY, 150, 26, "Gerar bytes crus", "")
  Protected G_Inject = ThemedButton(350, GenY, 150, 26, "Injetar no cursor", Chr(#Icon_Insert))
  GadgetToolTip(G_Inject, "Insere o codigo gerado abaixo no cursor da aba de texto ativa")
  Protected G_Copy = ThemedButton(510, GenY, 100, 26, "Copiar", Chr(#Icon_Copy))
  GadgetToolTip(G_Copy, "Copia o codigo gerado abaixo para a area de transferencia")

  Protected CodeY = GenY + 26 + 8
  Protected G_CodeOutput = EditorGadget(#PB_Any, 15, CodeY, 725, 100)

  Protected G_Close = ThemedButton(WinW - 15 - 90, CodeY + 100 + 10, 90, 28, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  ; --- Estado ---
  Dim Steps.PsgStepData(#PsgEd_MaxSteps - 1)
  Protected StepCount.i = 0
  Protected SelectedStep.i = -1
  Protected SoundNumber.i = 1
  Protected SoundTag.s = ""
  Protected SoundDirty.b = #False
  Protected SoundHandle.i = 0
  Protected TempWavPath.s = GetTemporaryDirectory() + "badig_psg_preview.wav"

  NewList Nav.i()
  ProjectDB::ListSoundNumbers(Nav())
  If ListSize(Nav()) > 0
    FirstElement(Nav())
    SoundNumber = Nav()
    StepCount = PsgEd_LoadSound(SoundNumber, Steps(), G_StepList, G_Tag, G_SoundNumberText)
  Else
    SetGadgetText(G_SoundNumberText, "#1")
    PsgEd_RefreshList(G_StepList, Steps(), 0)
  EndIf
  PsgEd_ResetPanel(G_Freq(), G_Vol(), G_EnvOn(), G_Tone(), G_Noise(), G_NoisePeriod, G_EnvPeriod, G_EnvShape, G_Duration)

  Protected Event, Quit = #False
  Protected NavTarget.i, NextNumber.i, NewCount.i, k, j

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
            EndIf

          Case G_StepList
            SelectedStep = GetGadgetState(G_StepList)
            If SelectedStep >= 0 And SelectedStep < StepCount
              PsgEd_WritePanel(@Steps(SelectedStep), G_Freq(), G_Vol(), G_EnvOn(), G_Tone(), G_Noise(), G_NoisePeriod, G_EnvPeriod, G_EnvShape, G_Duration)
            EndIf

          Case G_AddStep
            If StepCount >= #PsgEd_MaxSteps
              MessageRequester("Limite atingido", "Maximo de " + Str(#PsgEd_MaxSteps) + " passos por som.", #PB_MessageRequester_Ok)
            Else
              PsgEd_ReadPanel(@Steps(StepCount), G_Freq(), G_Vol(), G_EnvOn(), G_Tone(), G_Noise(), G_NoisePeriod, G_EnvPeriod, G_EnvShape, G_Duration)
              StepCount + 1
              PsgEd_RefreshList(G_StepList, Steps(), StepCount)
              SetGadgetState(G_StepList, StepCount - 1)
              SelectedStep = StepCount - 1
              SoundDirty = #True
            EndIf

          Case G_UpdateStep
            If SelectedStep >= 0 And SelectedStep < StepCount
              PsgEd_ReadPanel(@Steps(SelectedStep), G_Freq(), G_Vol(), G_EnvOn(), G_Tone(), G_Noise(), G_NoisePeriod, G_EnvPeriod, G_EnvShape, G_Duration)
              PsgEd_RefreshList(G_StepList, Steps(), StepCount)
              SoundDirty = #True
            Else
              MessageRequester("Nenhum passo selecionado", "Selecione um passo na lista pra atualizar.", #PB_MessageRequester_Ok)
            EndIf

          Case G_RemoveStep
            If SelectedStep >= 0 And SelectedStep < StepCount
              For k = SelectedStep To StepCount - 2
                Steps(k) = Steps(k + 1)
              Next
              StepCount - 1
              SelectedStep = -1
              PsgEd_RefreshList(G_StepList, Steps(), StepCount)
              SoundDirty = #True
            Else
              MessageRequester("Nenhum passo selecionado", "Selecione um passo na lista pra remover.", #PB_MessageRequester_Ok)
            EndIf

          Case G_MoveUp
            If SelectedStep > 0 And SelectedStep < StepCount
              Protected TmpStepU.PsgStepData
              TmpStepU = Steps(SelectedStep - 1)
              Steps(SelectedStep - 1) = Steps(SelectedStep)
              Steps(SelectedStep) = TmpStepU
              SelectedStep - 1
              PsgEd_RefreshList(G_StepList, Steps(), StepCount)
              SetGadgetState(G_StepList, SelectedStep)
              SoundDirty = #True
            EndIf

          Case G_MoveDown
            If SelectedStep >= 0 And SelectedStep < StepCount - 1
              Protected TmpStepD.PsgStepData
              TmpStepD = Steps(SelectedStep + 1)
              Steps(SelectedStep + 1) = Steps(SelectedStep)
              Steps(SelectedStep) = TmpStepD
              SelectedStep + 1
              PsgEd_RefreshList(G_StepList, Steps(), StepCount)
              SetGadgetState(G_StepList, SelectedStep)
              SoundDirty = #True
            EndIf

          Case G_DuplicateStep
            If SelectedStep >= 0 And SelectedStep < StepCount And StepCount < #PsgEd_MaxSteps
              For j = StepCount To SelectedStep + 2 Step -1
                Steps(j) = Steps(j - 1)
              Next
              Steps(SelectedStep + 1) = Steps(SelectedStep)
              StepCount + 1
              SelectedStep + 1
              PsgEd_RefreshList(G_StepList, Steps(), StepCount)
              SetGadgetState(G_StepList, SelectedStep)
              SoundDirty = #True
            EndIf

          Case G_Play
            If StepCount > 0
              Protected TotalSamp = PsgSynth_TotalSamples(Steps(), StepCount, #Psg_SampleRate)
              If TotalSamp > 0
                Protected *Buf = PsgSynth_RenderSequence(Steps(), StepCount, #Psg_SampleRate, TotalSamp)
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
                    SetGadgetText(G_Status, "Reproduzindo...")
                  Else
                    SetGadgetText(G_Status, "Nao foi possivel carregar o .wav renderizado.")
                  EndIf
                EndIf
              EndIf
            Else
              MessageRequester("Nada para tocar", "Adicione pelo menos um passo antes de Tocar.", #PB_MessageRequester_Ok)
            EndIf

          Case G_Stop
            If SoundHandle
              StopSound(SoundHandle)
            EndIf
            SetGadgetText(G_Status, "")

          Case G_GenBasic
            If StepCount > 0
              SetGadgetText(G_CodeOutput, PsgGen_BasicLines(Steps(), StepCount))
            Else
              MessageRequester("Nada para gerar", "Adicione pelo menos um passo antes de gerar codigo.", #PB_MessageRequester_Ok)
            EndIf

          Case G_GenRaw
            If StepCount > 0
              SetGadgetText(G_CodeOutput, PsgGen_RawBytes(Steps(), StepCount))
            Else
              MessageRequester("Nada para gerar", "Adicione pelo menos um passo antes de gerar codigo.", #PB_MessageRequester_Ok)
            EndIf

          Case G_Inject
            Protected InjectCode.s = GetGadgetText(G_CodeOutput)
            If InjectCode = ""
              MessageRequester("Nada para injetar", "Gere o codigo primeiro (Gerar codigo BASIC/bytes crus).", #PB_MessageRequester_Ok)
            ElseIf InjectTextAtCursor(InjectCode)
              SetGadgetText(G_Status, "Codigo injetado no cursor.")
            Else
              MessageRequester("Nao foi possivel injetar",
                                "Nenhuma aba de texto ativa no editor pra receber o codigo.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
            EndIf

          Case G_Copy
            Protected CopyCode.s = GetGadgetText(G_CodeOutput)
            If CopyCode <> ""
              SetClipboardText(CopyCode)
              SetGadgetText(G_Status, "Codigo copiado para a area de transferencia.")
            EndIf

          Case G_First
            If Not SoundDirty Or PsgEd_ConfirmDiscardSound()
              ProjectDB::ListSoundNumbers(Nav())
              NavTarget = PsgEd_FindNavTarget(Nav(), 0, SoundNumber)
              If NavTarget >= 0
                NewCount = PsgEd_LoadSound(NavTarget, Steps(), G_StepList, G_Tag, G_SoundNumberText)
                If NewCount > 0
                  StepCount = NewCount : SoundNumber = NavTarget : SelectedStep = -1 : SoundDirty = #False
                  PsgEd_ResetPanel(G_Freq(), G_Vol(), G_EnvOn(), G_Tone(), G_Noise(), G_NoisePeriod, G_EnvPeriod, G_EnvShape, G_Duration)
                  SetGadgetText(G_Status, "Som #" + Str(SoundNumber) + " carregado.")
                EndIf
              EndIf
            EndIf

          Case G_Prev
            If Not SoundDirty Or PsgEd_ConfirmDiscardSound()
              ProjectDB::ListSoundNumbers(Nav())
              NavTarget = PsgEd_FindNavTarget(Nav(), 1, SoundNumber)
              If NavTarget >= 0
                NewCount = PsgEd_LoadSound(NavTarget, Steps(), G_StepList, G_Tag, G_SoundNumberText)
                If NewCount > 0
                  StepCount = NewCount : SoundNumber = NavTarget : SelectedStep = -1 : SoundDirty = #False
                  PsgEd_ResetPanel(G_Freq(), G_Vol(), G_EnvOn(), G_Tone(), G_Noise(), G_NoisePeriod, G_EnvPeriod, G_EnvShape, G_Duration)
                  SetGadgetText(G_Status, "Som #" + Str(SoundNumber) + " carregado.")
                EndIf
              EndIf
            EndIf

          Case G_Next
            If Not SoundDirty Or PsgEd_ConfirmDiscardSound()
              ProjectDB::ListSoundNumbers(Nav())
              NavTarget = PsgEd_FindNavTarget(Nav(), 2, SoundNumber)
              If NavTarget >= 0
                NewCount = PsgEd_LoadSound(NavTarget, Steps(), G_StepList, G_Tag, G_SoundNumberText)
                If NewCount > 0
                  StepCount = NewCount : SoundNumber = NavTarget : SelectedStep = -1 : SoundDirty = #False
                  PsgEd_ResetPanel(G_Freq(), G_Vol(), G_EnvOn(), G_Tone(), G_Noise(), G_NoisePeriod, G_EnvPeriod, G_EnvShape, G_Duration)
                  SetGadgetText(G_Status, "Som #" + Str(SoundNumber) + " carregado.")
                EndIf
              EndIf
            EndIf

          Case G_Last
            If Not SoundDirty Or PsgEd_ConfirmDiscardSound()
              ProjectDB::ListSoundNumbers(Nav())
              NavTarget = PsgEd_FindNavTarget(Nav(), 3, SoundNumber)
              If NavTarget >= 0
                NewCount = PsgEd_LoadSound(NavTarget, Steps(), G_StepList, G_Tag, G_SoundNumberText)
                If NewCount > 0
                  StepCount = NewCount : SoundNumber = NavTarget : SelectedStep = -1 : SoundDirty = #False
                  PsgEd_ResetPanel(G_Freq(), G_Vol(), G_EnvOn(), G_Tone(), G_Noise(), G_NoisePeriod, G_EnvPeriod, G_EnvShape, G_Duration)
                  SetGadgetText(G_Status, "Som #" + Str(SoundNumber) + " carregado.")
                EndIf
              EndIf
            EndIf

          Case G_New
            If Not SoundDirty Or PsgEd_ConfirmDiscardSound()
              ProjectDB::ListSoundNumbers(Nav())
              NextNumber = 1
              If ListSize(Nav()) > 0
                LastElement(Nav())
                NextNumber = Nav() + 1
              EndIf
              SoundNumber = NextNumber
              SoundTag = ""
              StepCount = 0
              SelectedStep = -1
              SetGadgetText(G_Tag, "")
              SetGadgetText(G_SoundNumberText, "#" + Str(SoundNumber))
              PsgEd_RefreshList(G_StepList, Steps(), StepCount)
              PsgEd_ResetPanel(G_Freq(), G_Vol(), G_EnvOn(), G_Tone(), G_Noise(), G_NoisePeriod, G_EnvPeriod, G_EnvShape, G_Duration)
              SoundDirty = #False
              SetGadgetText(G_Status, "Novo som #" + Str(SoundNumber) + ".")
            EndIf

          Case G_Register
            SoundTag = Left(GetGadgetText(G_Tag), 16)
            SetGadgetText(G_Tag, SoundTag)
            If StepCount = 0
              MessageRequester("Nada para registrar", "Adicione pelo menos um passo antes de Registrar.", #PB_MessageRequester_Ok)
            Else
              Dim RegsFlat.a(StepCount * 14 - 1)
              Dim DursFlat.w(StepCount - 1)
              Protected i2, r2
              For i2 = 0 To StepCount - 1
                For r2 = 0 To 13
                  RegsFlat(i2 * 14 + r2) = Steps(i2)\Regs[r2]
                Next
                DursFlat(i2) = Steps(i2)\DurationFrames
              Next
              If ProjectDB::StoreSound(SoundNumber, SoundTag, StepCount, RegsFlat(), DursFlat())
                SoundDirty = #False
                SetGadgetText(G_Status, "Som #" + Str(SoundNumber) + " registrado.")
              Else
                MessageRequester("Erro ao registrar",
                                  "Nao foi possivel gravar o som:" + Chr(10) + ProjectDB::GetLastError(),
                                  #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
              EndIf
            EndIf

          Case G_Close
            If Not SoundDirty Or PsgEd_ConfirmDiscardSound()
              Quit = #True
            EndIf

        EndSelect

      Case #PB_Event_CloseWindow
        If Not SoundDirty Or PsgEd_ConfirmDiscardSound()
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
