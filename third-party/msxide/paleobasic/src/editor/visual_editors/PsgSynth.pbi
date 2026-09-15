;
; ------------------------------------------------------------
;  Motor de emulacao do PSG AY-3-8910/YM2149 (o chip de som usado pelo MSX,
;  controlado via os registradores 0-13 - exatamente os mesmos que o comando
;  SOUND do MSX-BASIC escreve). Sem nenhuma dependencia de GUI, para poder
;  ser incluido tanto pela janela "Criar -> Som..." (PsgEditorGui.pbi) quanto
;  pelo harness headless (editor/tools/PsgTestCli.pb).
;
;  Um "efeito" e representado como uma sequencia de PsgStepData (passos): cada
;  passo guarda os 14 registradores crus (0-255, layout identico ao SOUND n,v
;  do BASIC) e uma duracao em quadros de 1/60s. O estado do chip (fase dos 3
;  osciladores de tom, LFSR de ruido, contador de envelope) persiste entre
;  passos - so reinicia quando um passo realmente ESCREVE um valor diferente
;  em R13 (forma do envelope), igual ao hardware real (os demais registradores
;  nunca resetam fase).
;
;  Layout dos 14 registradores (identico ao AY-3-8910/YM2149 e ao SOUND do
;  MSX-BASIC):
;    R0/R1   periodo de tom do canal A (fine/coarse, 12 bits)
;    R2/R3   periodo de tom do canal B
;    R4/R5   periodo de tom do canal C
;    R6      periodo de ruido (5 bits, 0-31)
;    R7      mixer (bits 0-2 = desliga tom A/B/C, bits 3-5 = desliga ruido
;             A/B/C - ATIVO BAIXO: bit 1 = desligado)
;    R8/R9/R10  volume do canal A/B/C (bits 0-3 = 0-15, bit 4 = usa envelope)
;    R11/R12 periodo de envelope (fine/coarse, 16 bits)
;    R13     forma do envelope (4 bits: Continue/Attack/Alternate/Hold)
; ------------------------------------------------------------
;

; Guarda de inclusao: BadigEditor.pb inclui este arquivo diretamente E
; MmlSynth.pbi (tambem incluido por BadigEditor.pb) inclui de novo via
; XIncludeFile "PsgSynth.pbi" - o pbcompiler do Windows deduplica isso
; silenciosamente por caminho de arquivo resolvido, mas o pbcompiler Linux
; (testado com PureBasic real via WSL, 2026-07-29) nao faz essa deduplicacao,
; causando "Structure already declared: PsgStepData". Guarda explicita para
; nao depender desse comportamento variar entre plataforma/versao do
; compilador.
CompilerIf Not Defined(PSGSYNTH_PBI_INCLUDED, #PB_Constant)
#PSGSYNTH_PBI_INCLUDED = 1

EnableExplicit

#Psg_ClockHz = 1789772.5   ; clock do PSG no MSX (3.579545 MHz / 2)
#Psg_SampleRate = 44100
#PsgGen_LoopItersPerFrame = 15  ; placeholder aproximado p/ delay FOR/NEXT gerado - nao calibrado contra hardware/emulador real, ajustavel pelo usuario

Structure PsgStepData
  Regs.a[14]
  DurationFrames.w
EndStructure

Structure PsgChipState
  TonePhase.d[3]
  ToneOut.b[3]
  NoisePhase.d
  NoiseShift.l
  NoiseOut.b
  EnvPhase.d
  EnvLevel.b
  EnvDir.b
  EnvHolding.b
  EnvContinue.b
  EnvAttack.b
  EnvAlternate.b
  EnvHold.b
  LastEnvShape.b
  EnvShapeValid.b
EndStructure

Procedure PsgSynth_InitState(*St.PsgChipState)
  Protected c
  For c = 0 To 2
    *St\TonePhase[c] = 0
    *St\ToneOut[c] = 0
  Next
  *St\NoisePhase = 0
  *St\NoiseShift = 1   ; nunca pode ser 0 - travaria o LFSR (feedback sempre 0)
  *St\NoiseOut = 0
  *St\EnvPhase = 0
  *St\EnvLevel = 0
  *St\EnvDir = 1
  *St\EnvHolding = #False
  *St\EnvShapeValid = #False
EndProcedure

; Conversao Hz <-> periodo de registrador (12 bits, 1-4095), usada pela UI
; pra deixar o usuario digitar frequencia em Hz em vez do periodo cru.
Procedure.i PsgSynth_HzToPeriod(Hz.d)
  Protected TP.i
  If Hz <= 0
    ProcedureReturn 1
  EndIf
  TP = Round(#Psg_ClockHz / (16.0 * Hz), #PB_Round_Nearest)
  If TP < 1 : TP = 1 : EndIf
  If TP > 4095 : TP = 4095 : EndIf
  ProcedureReturn TP
EndProcedure

Procedure.d PsgSynth_PeriodToHz(TP.i)
  If TP < 1 : TP = 1 : EndIf
  ProcedureReturn #Psg_ClockHz / (16.0 * TP)
EndProcedure

; Tabela de volume logaritmica de 16 passos (aproximacao publicada do
; AY-3-8910/YM2149 - nao e linear, e o que da o timbre reconhecivel do chip).
Procedure.d PsgSynth_VolumeLevel(Level.a)
  Static Initialized.b = #False
  Static Dim Tbl.d(15)
  If Not Initialized
    Tbl(0)  = 0.0000 : Tbl(1)  = 0.0100 : Tbl(2)  = 0.0137 : Tbl(3)  = 0.0201
    Tbl(4)  = 0.0287 : Tbl(5)  = 0.0435 : Tbl(6)  = 0.0653 : Tbl(7)  = 0.0980
    Tbl(8)  = 0.1330 : Tbl(9)  = 0.2005 : Tbl(10) = 0.2929 : Tbl(11) = 0.3948
    Tbl(12) = 0.5474 : Tbl(13) = 0.6663 : Tbl(14) = 0.8547 : Tbl(15) = 1.0000
    Initialized = #True
  EndIf
  If Level < 0 : Level = 0 : EndIf
  If Level > 15 : Level = 15 : EndIf
  ProcedureReturn Tbl(Level)
EndProcedure

; Reinicia o gerador de envelope a partir de um novo valor de R13 - so deve
; ser chamada quando o passo realmente ESCREVE um R13 diferente do anterior.
Procedure PsgSynth_ApplyEnvShape(*St.PsgChipState, Shape.a)
  *St\LastEnvShape = Shape
  *St\EnvShapeValid = #True
  *St\EnvContinue  = Bool((Shape & %1000) <> 0)
  *St\EnvAttack    = Bool((Shape & %0100) <> 0)
  *St\EnvAlternate = Bool((Shape & %0010) <> 0)
  *St\EnvHold      = Bool((Shape & %0001) <> 0)
  If *St\EnvAttack
    *St\EnvLevel = 0
    *St\EnvDir = 1
  Else
    *St\EnvLevel = 15
    *St\EnvDir = -1
  EndIf
  *St\EnvHolding = #False
  *St\EnvPhase = 0
EndProcedure

; Avanca o envelope em um "degrau" (0-15). Logica derivada da tabela de
; formas de hardware documentada do AY-3-8910 (10 formas nomeadas, valores
; 8-15 de R13; valores 0-7 sempre colapsam num unico ramp seguido de silencio
; porque Continue=0).
Procedure PsgSynth_EnvTick(*St.PsgChipState)
  If *St\EnvHolding
    ProcedureReturn
  EndIf
  *St\EnvLevel + *St\EnvDir
  If *St\EnvLevel > 15 Or *St\EnvLevel < 0
    If *St\EnvLevel > 15
      *St\EnvLevel = 15
    Else
      *St\EnvLevel = 0
    EndIf
    If Not *St\EnvContinue
      *St\EnvLevel = 0
      *St\EnvHolding = #True
    ElseIf *St\EnvHold
      If *St\EnvAlternate
        *St\EnvLevel = 15 - *St\EnvLevel
      EndIf
      *St\EnvHolding = #True
    ElseIf *St\EnvAlternate
      *St\EnvDir = -*St\EnvDir
    Else
      *St\EnvLevel = 15 - *St\EnvLevel   ; reinicia o mesmo ramp (dente de serra)
    EndIf
  EndIf
EndProcedure

Procedure.i PsgSynth_StepSamples(*Step.PsgStepData, SampleRate.i)
  ProcedureReturn Round(*Step\DurationFrames * SampleRate / 60.0, #PB_Round_Nearest)
EndProcedure

; Sintetiza um unico passo direto no buffer PCM 16 bits mono, a partir da
; amostra StartSample (o estado *St ja deve estar inicializado e e
; atualizado/persistido para o proximo passo).
Procedure PsgSynth_RenderStep(*St.PsgChipState, *Step.PsgStepData, SampleRate.i, *Buffer, StartSample.i, NumSamples.i)
  Protected c, i, r
  Protected.d TicksPerSample = #Psg_ClockHz / SampleRate

  If (Not *St\EnvShapeValid) Or *Step\Regs[13] <> *St\LastEnvShape
    PsgSynth_ApplyEnvShape(*St, *Step\Regs[13])
  EndIf

  Protected Dim TP.i(2)
  For c = 0 To 2
    TP(c) = ((*Step\Regs[c*2+1] & $0F) << 8) | *Step\Regs[c*2]
    If TP(c) = 0 : TP(c) = 1 : EndIf
  Next

  Protected NP.i = *Step\Regs[6] & $1F
  If NP = 0 : NP = 1 : EndIf

  Protected EP.i = (*Step\Regs[12] << 8) | *Step\Regs[11]
  If EP = 0 : EP = 1 : EndIf

  Protected Mixer.a = *Step\Regs[7]
  Protected Dim ToneOn.b(2)
  Protected Dim NoiseOn.b(2)
  For c = 0 To 2
    ToneOn(c)  = Bool(((Mixer >> c) & 1) = 0)
    NoiseOn(c) = Bool(((Mixer >> (c + 3)) & 1) = 0)
  Next

  Protected Dim VolReg.a(2)
  Protected Dim UseEnv.b(2)
  For c = 0 To 2
    VolReg(c) = *Step\Regs[8 + c] & $0F
    UseEnv(c) = Bool((*Step\Regs[8 + c] & $10) <> 0)
  Next

  Protected Dim ToneHalfPeriod.d(2)
  For c = 0 To 2
    ToneHalfPeriod(c) = 8.0 * TP(c)
  Next
  Protected.d NoisePeriod   = 16.0 * NP
  Protected.d EnvStepPeriod = 8.0 * EP

  Protected *Sample.Word = *Buffer + (StartSample * 2)
  Protected.d Mix
  Protected Feedback.l
  Protected ToneBit.b, NoiseBit.b, Gate.b, Level.b
  Protected Sample16.l

  For i = 0 To NumSamples - 1
    For c = 0 To 2
      *St\TonePhase[c] + TicksPerSample
      While *St\TonePhase[c] >= ToneHalfPeriod(c)
        *St\TonePhase[c] - ToneHalfPeriod(c)
        *St\ToneOut[c] = 1 - *St\ToneOut[c]
      Wend
    Next

    *St\NoisePhase + TicksPerSample
    While *St\NoisePhase >= NoisePeriod
      *St\NoisePhase - NoisePeriod
      Feedback = (*St\NoiseShift & 1) ! ((*St\NoiseShift >> 3) & 1)
      *St\NoiseShift = (*St\NoiseShift >> 1) | (Feedback << 16)
      *St\NoiseOut = *St\NoiseShift & 1
    Wend

    *St\EnvPhase + TicksPerSample
    While *St\EnvPhase >= EnvStepPeriod
      *St\EnvPhase - EnvStepPeriod
      PsgSynth_EnvTick(*St)
    Wend

    Mix = 0
    For c = 0 To 2
      If ToneOn(c)
        ToneBit = *St\ToneOut[c]
      Else
        ToneBit = 1
      EndIf
      If NoiseOn(c)
        NoiseBit = *St\NoiseOut
      Else
        NoiseBit = 1
      EndIf
      Gate = ToneBit & NoiseBit
      If Gate
        If UseEnv(c)
          Level = *St\EnvLevel
        Else
          Level = VolReg(c)
        EndIf
        Mix + PsgSynth_VolumeLevel(Level)
      EndIf
    Next

    Sample16 = Round((Mix / 3.0) * 32000, #PB_Round_Nearest)
    If Sample16 > 32000 : Sample16 = 32000 : EndIf
    If Sample16 < -32000 : Sample16 = -32000 : EndIf
    PokeW(*Sample, Sample16)
    *Sample + 2
  Next
EndProcedure

Procedure.i PsgSynth_TotalSamples(Array Steps.PsgStepData(1), NumSteps.i, SampleRate.i)
  Protected i, Total = 0
  For i = 0 To NumSteps - 1
    Total + PsgSynth_StepSamples(@Steps(i), SampleRate)
  Next
  ProcedureReturn Total
EndProcedure

; Renderiza a sequencia inteira num buffer alocado (o chamador deve ter
; calculado TotalSamples via PsgSynth_TotalSamples antes, e e responsavel
; por FreeMemory() do resultado). Devolve 0 se nao ha nada pra renderizar.
Procedure.i PsgSynth_RenderSequence(Array Steps.PsgStepData(1), NumSteps.i, SampleRate.i, TotalSamples.i)
  If TotalSamples <= 0
    ProcedureReturn 0
  EndIf

  Protected *Buffer = AllocateMemory(TotalSamples * 2)
  If Not *Buffer
    ProcedureReturn 0
  EndIf

  Protected St.PsgChipState
  PsgSynth_InitState(@St)

  Protected i, StepSamp, Cursor = 0
  For i = 0 To NumSteps - 1
    StepSamp = PsgSynth_StepSamples(@Steps(i), SampleRate)
    If StepSamp > 0
      PsgSynth_RenderStep(@St, @Steps(i), SampleRate, *Buffer, Cursor, StepSamp)
      Cursor + StepSamp
    EndIf
  Next

  ProcedureReturn *Buffer
EndProcedure

; Escreve um .wav PCM mono 16 bits minimo a partir do buffer renderizado.
Procedure.i PsgSynth_WriteWav(*Buffer, NumSamples.i, SampleRate.i, Path.s)
  Protected FileNum = CreateFile(#PB_Any, Path)
  If Not FileNum
    ProcedureReturn #False
  EndIf

  Protected DataBytes.l = NumSamples * 2
  Protected ByteRate.l = SampleRate * 2

  WriteString(FileNum, "RIFF", #PB_Ascii)
  WriteLong(FileNum, 36 + DataBytes)
  WriteString(FileNum, "WAVE", #PB_Ascii)
  WriteString(FileNum, "fmt ", #PB_Ascii)
  WriteLong(FileNum, 16)
  WriteWord(FileNum, 1)
  WriteWord(FileNum, 1)
  WriteLong(FileNum, SampleRate)
  WriteLong(FileNum, ByteRate)
  WriteWord(FileNum, 2)
  WriteWord(FileNum, 16)
  WriteString(FileNum, "data", #PB_Ascii)
  WriteLong(FileNum, DataBytes)
  If NumSamples > 0
    WriteData(FileNum, *Buffer, DataBytes)
  EndIf
  CloseFile(FileNum)
  ProcedureReturn #True
EndProcedure

; Gera as linhas "SOUND n,valor" prontas para colar num programa MSX-BASIC.
; So emite, a partir do 2o passo, os registradores que MUDARAM em relacao ao
; passo anterior (registrador nao tocado mantem o valor de antes no hardware
; real). O delay entre passos usa um FOR/NEXT com contador aproximado (nao
; calibrado sample-accurate contra hardware/emulador - ver #PsgGen_LoopItersPerFrame).
Procedure.s PsgGen_BasicLines(Array Steps.PsgStepData(1), NumSteps.i)
  Protected Result.s = ""
  Protected i, r
  Protected Dim PrevRegs.a(13)
  Protected HasPrev.b = #False

  For i = 0 To NumSteps - 1
    For r = 0 To 13
      If (Not HasPrev) Or Steps(i)\Regs[r] <> PrevRegs(r)
        Result + "SOUND " + Str(r) + "," + Str(Steps(i)\Regs[r]) + #CRLF$
      EndIf
    Next
    For r = 0 To 13
      PrevRegs(r) = Steps(i)\Regs[r]
    Next
    HasPrev = #True

    If Steps(i)\DurationFrames > 0
      Result + "' aguarda ~" + Str(Steps(i)\DurationFrames) + " quadros (1/60s, aproximado)" + #CRLF$
      Result + "FOR ZZ1=1 TO " + Str(Steps(i)\DurationFrames * #PsgGen_LoopItersPerFrame) + ":NEXT ZZ1" + #CRLF$
    EndIf
  Next

  ProcedureReturn Result
EndProcedure

; Gera um bloco de DATA com os 14 bytes de registrador crus + duracao por
; passo (para uma futura rotina Z80/#asm que escreva direto nas portas do
; PSG - mais rapido que varias chamadas SOUND em runtime).
Procedure.s PsgGen_RawBytes(Array Steps.PsgStepData(1), NumSteps.i)
  Protected Result.s = ""
  Protected i, r, Line.s

  For i = 0 To NumSteps - 1
    Result + "' Passo " + Str(i) + " (dura ~" + Str(Steps(i)\DurationFrames) + " quadros)" + #CRLF$
    Line = "DATA "
    For r = 0 To 13
      Line + "&H" + RSet(Hex(Steps(i)\Regs[r], #PB_Byte), 2, "0") + ","
    Next
    Line + Str(Steps(i)\DurationFrames)
    Result + Line + #CRLF$
  Next

  ProcedureReturn Result
EndProcedure

CompilerEndIf ; PSGSYNTH_PBI_INCLUDED
