;
; ------------------------------------------------------------
;  Ferramenta de linha de comando para testar o motor de emulacao do PSG
;  (editor\PsgSynth.pbi) sem precisar abrir o editor.
;
;  Renderiza uma sequencia de teste embutida (efeito "laser": 3 passos
;  variando a frequencia do canal A, mais um passo com ruido e envelope) pra
;  um .wav na pasta informada, e imprime estatisticas de sanidade (numero de
;  amostras, pico, e para um caso de tom puro isolado, o periodo da onda
;  gerada comparado com a frequencia pedida).
;
;  Uso:
;    PsgTestCli.exe <pasta_de_saida>
;      <pasta_de_saida>  pasta onde o(s) .wav de teste serao criados
;
;  Compilar com:
;    "C:\Basic\Compilers\pbcompiler.exe" editor\tools\PsgTestCli.pb /EXE editor\tools\PsgTestCli.exe /CONSOLE
; ------------------------------------------------------------
;

EnableExplicit
OpenConsole()

XIncludeFile "..\visual_editors\PsgSynth.pbi"

Define OutDir.s = ProgramParameter(0)
If OutDir = ""
  PrintN("Uso: PsgTestCli.exe <pasta_de_saida>")
  End 1
EndIf
If Right(OutDir, 1) <> "\" And Right(OutDir, 1) <> "/"
  OutDir + "\"
EndIf
If FileSize(OutDir) <> -2
  CreateDirectory(OutDir)
EndIf

Define Failures = 0

Procedure CheckTrue(Ok.i, Label.s)
  Shared Failures
  If Ok
    PrintN("OK    - " + Label)
  Else
    PrintN("FALHA - " + Label)
    Failures + 1
  EndIf
EndProcedure

; Monta um passo com todos os registradores zerados (silencio) como ponto de
; partida, retornando o indice pra permitir sobrescrever campos individuais.
Procedure PsgTest_ClearStep(*Step.PsgStepData)
  Protected r
  For r = 0 To 13
    *Step\Regs[r] = 0
  Next
  *Step\DurationFrames = 0
EndProcedure

; ------------------------------------------------------------
; Teste 1: tom puro no canal A (mixer so-tom, sem ruido/envelope) - permite
; conferir se o periodo da onda gerada bate com a frequencia pedida.
; ------------------------------------------------------------
Define.i TP1 = 200   ; periodo de registrador arbitrario
Define Dim PureTone.PsgStepData(0)
PsgTest_ClearStep(@PureTone(0))
PureTone(0)\Regs[0] = TP1 & $FF          ; R0 - fine tune canal A
PureTone(0)\Regs[1] = (TP1 >> 8) & $0F   ; R1 - coarse tune canal A
PureTone(0)\Regs[7] = %00111110          ; R7 - so tom A ligado (bit0=0), resto desligado
PureTone(0)\Regs[8] = 15                 ; R8 - volume max, sem envelope
PureTone(0)\DurationFrames = 30          ; meio segundo

Define TotalSamples1 = PsgSynth_TotalSamples(PureTone(), 1, #Psg_SampleRate)
Define *Buf1 = PsgSynth_RenderSequence(PureTone(), 1, #Psg_SampleRate, TotalSamples1)
CheckTrue(Bool(*Buf1 <> 0), "Renderiza tom puro (buffer alocado)")

If *Buf1
  ; Conta cruzamentos de zero pra estimar o periodo medido, e compara com o
  ; esperado por PsgFreq = Clock / (16 * TP).
  Define ExpectedFreq.d = #Psg_ClockHz / (16.0 * TP1)
  Define Crossings = 0
  Define Prev.w = PeekW(*Buf1)
  Define i
  For i = 1 To TotalSamples1 - 1
    Define Cur.w = PeekW(*Buf1 + i * 2)
    If Prev <= 0 And Cur > 0
      Crossings + 1
    EndIf
    Prev = Cur
  Next
  Define SecondsRendered.d = TotalSamples1 / #Psg_SampleRate
  Define MeasuredFreq.d = Crossings / SecondsRendered
  PrintN("      frequencia esperada ~" + StrD(ExpectedFreq, 1) + " Hz, medida ~" + StrD(MeasuredFreq, 1) + " Hz")
  CheckTrue(Bool(Abs(MeasuredFreq - ExpectedFreq) < (ExpectedFreq * 0.05)), "Frequencia do tom puro dentro de 5% do esperado")

  Define Peak = 0
  For i = 0 To TotalSamples1 - 1
    Define Sample.w = PeekW(*Buf1 + i * 2)
    If Abs(Sample) > Peak
      Peak = Abs(Sample)
    EndIf
  Next
  CheckTrue(Bool(Peak > 0), "Tom puro nao e silencio (pico > 0)")

  PsgSynth_WriteWav(*Buf1, TotalSamples1, #Psg_SampleRate, OutDir + "tone_a440ish.wav")
  PrintN("      escrito: " + OutDir + "tone_a440ish.wav")
  FreeMemory(*Buf1)
EndIf

; ------------------------------------------------------------
; Teste 2: volume 0 deve ser silencio absoluto.
; ------------------------------------------------------------
Define Dim Silence.PsgStepData(0)
PsgTest_ClearStep(@Silence(0))
Silence(0)\Regs[0] = TP1 & $FF
Silence(0)\Regs[1] = (TP1 >> 8) & $0F
Silence(0)\Regs[7] = %00111110
Silence(0)\Regs[8] = 0   ; volume 0
Silence(0)\DurationFrames = 10

Define TotalSamples2 = PsgSynth_TotalSamples(Silence(), 1, #Psg_SampleRate)
Define *Buf2 = PsgSynth_RenderSequence(Silence(), 1, #Psg_SampleRate, TotalSamples2)
If *Buf2
  Define AllZero.b = #True
  For i = 0 To TotalSamples2 - 1
    If PeekW(*Buf2 + i * 2) <> 0
      AllZero = #False
      Break
    EndIf
  Next
  CheckTrue(AllZero, "Volume 0 produz silencio absoluto")
  FreeMemory(*Buf2)
Else
  CheckTrue(#False, "Volume 0 produz silencio absoluto (buffer nao alocado)")
EndIf

; ------------------------------------------------------------
; Teste 3: efeito "laser" com 3 passos (frequencia caindo) + ruido/envelope
; no ultimo passo - so pra gerar um .wav audivel de verdade e o codigo BASIC
; correspondente, sem asserts numericos (validacao e de ouvido/leitura).
; ------------------------------------------------------------
Define Dim Laser.PsgStepData(2)

PsgTest_ClearStep(@Laser(0))
Laser(0)\Regs[0] = 60 & $FF : Laser(0)\Regs[1] = (60 >> 8) & $0F
Laser(0)\Regs[7] = %00111110
Laser(0)\Regs[8] = 15
Laser(0)\DurationFrames = 6

PsgTest_ClearStep(@Laser(1))
Laser(1)\Regs[0] = 150 & $FF : Laser(1)\Regs[1] = (150 >> 8) & $0F
Laser(1)\Regs[7] = %00111110
Laser(1)\Regs[8] = 15
Laser(1)\DurationFrames = 6

PsgTest_ClearStep(@Laser(2))
Laser(2)\Regs[0] = 300 & $FF : Laser(2)\Regs[1] = (300 >> 8) & $0F
Laser(2)\Regs[6] = 8                     ; periodo de ruido
Laser(2)\Regs[7] = %00110110             ; tom A + ruido A ligados
Laser(2)\Regs[8] = %00010000             ; canal A usa envelope
Laser(2)\Regs[11] = 40 & $FF
Laser(2)\Regs[12] = (40 >> 8) & $FF
Laser(2)\Regs[13] = 9                    ; forma 9 = decai uma vez e para em 0
Laser(2)\DurationFrames = 12

Define TotalSamples3 = PsgSynth_TotalSamples(Laser(), 3, #Psg_SampleRate)
Define *Buf3 = PsgSynth_RenderSequence(Laser(), 3, #Psg_SampleRate, TotalSamples3)
CheckTrue(Bool(*Buf3 <> 0), "Renderiza sequencia de 3 passos (laser)")
If *Buf3
  PsgSynth_WriteWav(*Buf3, TotalSamples3, #Psg_SampleRate, OutDir + "laser_fx.wav")
  PrintN("      escrito: " + OutDir + "laser_fx.wav")
  FreeMemory(*Buf3)
EndIf

Define BasicCode.s = PsgGen_BasicLines(Laser(), 3)
CheckTrue(Bool(FindString(BasicCode, "SOUND 0,60") > 0), "Codegen BASIC inclui SOUND 0,60 do passo 0")
CheckTrue(Bool(FindString(BasicCode, "SOUND 13,9") > 0), "Codegen BASIC inclui SOUND 13,9 (forma do envelope) so no passo 3")
PrintN("--- codigo BASIC gerado ---")
PrintN(BasicCode)

Define RawBytes.s = PsgGen_RawBytes(Laser(), 3)
CheckTrue(Bool(FindString(RawBytes, "DATA") > 0), "Codegen de bytes crus gera bloco DATA")
PrintN("--- bytes crus gerados ---")
PrintN(RawBytes)

PrintN("")
If Failures = 0
  PrintN("TODOS OS TESTES OK")
Else
  PrintN(Str(Failures) + " TESTE(S) FALHARAM")
  End 1
EndIf
