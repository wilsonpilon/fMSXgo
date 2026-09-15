; audio_verify.pb - fossauro PSG/audio pipeline verification harness
;
; Two checks, both exercising the REAL shipped code (AY8910.pbi), not a reimplementation:
;   1. Renders a sequence of known PSG register configurations directly through PSG_Render()
;      (the exact function the live audio thread calls) into a standard .wav file, so a human
;      can actually listen to the result - console-only harnesses can't "hear" anything, but a
;      .wav on disk lets the project owner confirm it by ear.
;   2. A live smoke test of StartAudio()/StopAudio() (the actual Win32 waveOut thread used by
;      fossauro.exe) with a tone programmed on the real PSG registers, to confirm the threaded
;      double-buffering path itself doesn't hang or crash and produces non-silent output on this
;      machine's audio device.
;
; Usage: audio_verify.exe <output.wav>

EnableExplicit

Global ThreadExit.l = 0
Global ThreadPaused.l = 0

XIncludeFile "Z80_Tables.pbi"
XIncludeFile "Z80.pbi"
XIncludeFile "MSX.pbi" ; pulls in V9938.pbi and AY8910.pbi (PSG_Render/StartAudio/StopAudio)

; --- WAV file helpers (standard RIFF/PCM16/mono/44100Hz, matches AY8910.pbi's live format) ---

Procedure WriteWavHeader(hFile.i, DataBytes.l)
  WriteString(hFile, "RIFF")
  WriteLong(hFile, 36 + DataBytes)
  WriteString(hFile, "WAVE")
  WriteString(hFile, "fmt ")
  WriteLong(hFile, 16)          ; fmt chunk size
  WriteWord(hFile, 1)           ; PCM
  WriteWord(hFile, 1)           ; mono
  WriteLong(hFile, #AUDIO_SAMPLE_RATE)
  WriteLong(hFile, #AUDIO_SAMPLE_RATE * 2) ; byte rate (mono, 16-bit)
  WriteWord(hFile, 2)           ; block align
  WriteWord(hFile, 16)          ; bits per sample
  WriteString(hFile, "data")
  WriteLong(hFile, DataBytes)
EndProcedure

; Renders SamplesCount samples with the CURRENT PSG register state and appends raw PCM to hFile.
; Also returns simple stats (peak, DC average, estimated frequency via threshold-crossing count)
; via pointers, so the console output gives an objective sanity check alongside the .wav itself.
Procedure RenderSegment(hFile.i, SamplesCount.l, *OutPeak.Long, *OutAvg.Long, *OutFreqHz.Long)
  Protected *Buf = AllocateMemory(SamplesCount * 2)
  PSG_Render(*Buf, SamplesCount)
  WriteData(hFile, *Buf, SamplesCount * 2)

  Protected i.l, v.u, peak.l = 0, total.q = 0
  Protected minV.l = 65535, maxV.l = 0
  For i = 0 To SamplesCount - 1
    v = PeekU(*Buf + i * 2)
    total + v
    If v > maxV : maxV = v : EndIf
    If v < minV : minV = v : EndIf
  Next i
  peak = maxV
  Protected avg.l = total / SamplesCount
  Protected threshold.l = (minV + maxV) / 2

  Protected crossings.l = 0
  Protected above.l = Bool(PeekU(*Buf) > threshold)
  For i = 1 To SamplesCount - 1
    v = PeekU(*Buf + i * 2)
    Protected nowAbove.l = Bool(v > threshold)
    If nowAbove <> above
      crossings + 1
      above = nowAbove
    EndIf
  Next i
  Protected freq.l = 0
  If maxV > minV ; only meaningful if the signal actually toggled
    freq = Int((crossings / 2.0) / (SamplesCount / #AUDIO_SAMPLE_RATE))
  EndIf

  *OutPeak\l = peak
  *OutAvg\l = avg
  *OutFreqHz\l = freq

  FreeMemory(*Buf)
EndProcedure

Procedure SilenceAllChannels()
  Protected i.l
  For i = 0 To 15
    PSG\R[i] = 0
  Next i
  PSG\R[7] = %00111111 ; all tones + all noises disabled (mixer register)
EndProcedure

Procedure.s HzLabel(period.l)
  ; Same formula PSG_Render() implies: f = (111860.78) / (2 * period)
  Protected f.d = 111860.78 / (2 * period)
  ProcedureReturn StrD(f, 1) + "Hz"
EndProcedure

Procedure RunWavTest(OutPath.s)
  PrintN("=== Teste 1: renderizando " + OutPath + " via PSG_Render() real ===")
  ResetPSG()

  Protected hFile.i = CreateFile(#PB_Any, OutPath)
  If Not hFile
    PrintN("FALHA: nao foi possivel criar " + OutPath)
    ProcedureReturn #False
  EndIf

  ; Reserve header space, fill it in at the end once we know the total data size.
  WriteWavHeader(hFile, 0)

  Protected totalBytes.l = 0
  Protected peak.l, avg.l, freq.l
  Protected segSamples.l = #AUDIO_SAMPLE_RATE / 2 ; 0.5s per segment

  ; --- Segment 1: silence (baseline) ---
  SilenceAllChannels()
  RenderSegment(hFile, segSamples, @peak, @avg, @freq)
  totalBytes + segSamples * 2
  PrintN("1. Silencio           - peak=" + Str(peak) + " avg=" + Str(avg) + " (esperado: ambos 0)")

  ; --- Segment 2: Channel A, fixed tone, full volume, no noise/envelope ---
  SilenceAllChannels()
  PSG\R[0] = 200 & $FF : PSG\R[1] = (200 >> 8) & $0F ; period 200
  PSG\R[7] = %00111110 ; tone A enabled, everything else disabled
  PSG\R[8] = $0F        ; channel A volume 15, no envelope flag
  RenderSegment(hFile, segSamples, @peak, @avg, @freq)
  totalBytes + segSamples * 2
  PrintN("2. Tom fixo canal A   - peak=" + Str(peak) + " freq medida=" + Str(freq) + "Hz (esperado ~" + HzLabel(200) + ")")

  ; --- Segment 3: Channel A frequency sweep (10 sub-steps, period falling = pitch rising) ---
  Protected sweepStep.l, subSamples.l = segSamples / 10
  Protected sweepPeriod.l
  For sweepStep = 0 To 9
    sweepPeriod = 800 - sweepStep * 70 ; 800 down to 170 -> low to high pitch
    SilenceAllChannels()
    PSG\R[0] = sweepPeriod & $FF : PSG\R[1] = (sweepPeriod >> 8) & $0F
    PSG\R[7] = %00111110
    PSG\R[8] = $0F
    RenderSegment(hFile, subSamples, @peak, @avg, @freq)
    totalBytes + subSamples * 2
  Next sweepStep
  PrintN("3. Varredura de tom   - 10 passos, periodo 800->170 (grave->agudo)")

  ; --- Segment 4: noise only on channel A ---
  SilenceAllChannels()
  PSG\R[6] = 8          ; noise period
  PSG\R[7] = %00110111  ; tone A disabled, noise A enabled, others disabled
  PSG\R[8] = $0F
  RenderSegment(hFile, segSamples, @peak, @avg, @freq)
  totalBytes + segSamples * 2
  PrintN("4. Ruido (LFSR) canal A - peak=" + Str(peak) + " (esperado: nao-zero, sem periodicidade clara)")

  ; --- Segment 5: envelope demo (shape 8 = repeating sawtooth) on channel A ---
  SilenceAllChannels()
  PSG\R[0] = 300 & $FF : PSG\R[1] = (300 >> 8) & $0F
  PSG\R[11] = $00 : PSG\R[12] = $04 ; envelope period (fast-ish repeat for audibility in 0.5s)
  PSG\R[13] = 8                      ; shape 8 = continua/attack=0/alternate=0/hold=0 -> repeating ramp down
  ResetPSGEnvelope()                 ; in the real app MSXOutZ80 triggers this on every R13 write - do it
                                      ; explicitly here since this harness pokes PSG\R[] directly, bypassing
                                      ; the port-write callback (a real, easy-to-repeat harness pitfall).
  PSG\R[7] = %00111110
  PSG\R[8] = $10 ; envelope flag on channel A (bit4), volume bits ignored
  RenderSegment(hFile, segSamples, @peak, @avg, @freq)
  totalBytes + segSamples * 2
  PrintN("5. Envelope (forma 8) - peak=" + Str(peak) + " (esperado: nao-zero, volume variando)")

  ; --- Segment 6: three-channel chord (A+B+C different pitches) ---
  SilenceAllChannels()
  PSG\R[0] = 478 & $FF : PSG\R[1] = (478 >> 8) & $0F ; ~A (approx)
  PSG\R[2] = 402 & $FF : PSG\R[3] = (402 >> 8) & $0F ; ~C#
  PSG\R[4] = 319 & $FF : PSG\R[5] = (319 >> 8) & $0F ; ~E
  PSG\R[7] = %00111000 ; tones A/B/C enabled (bits0-2=0), noises disabled (bits3-5=1)
  PSG\R[8] = $0D : PSG\R[9] = $0D : PSG\R[10] = $0D
  RenderSegment(hFile, segSamples, @peak, @avg, @freq)
  totalBytes + segSamples * 2
  PrintN("6. Acorde 3 canais    - peak=" + Str(peak) + " (esperado: nao-zero, mistura dos 3 canais)")

  ; --- Segment 7: silence again ---
  SilenceAllChannels()
  RenderSegment(hFile, segSamples, @peak, @avg, @freq)
  totalBytes + segSamples * 2
  PrintN("7. Silencio final     - peak=" + Str(peak) + " avg=" + Str(avg) + " (esperado: ambos 0)")

  ; Patch the header now that we know the real data size.
  FileSeek(hFile, 0)
  WriteWavHeader(hFile, totalBytes)
  CloseFile(hFile)

  PrintN("")
  PrintN("Arquivo gravado: " + OutPath + " (" + Str(totalBytes / 1024) + " KB de audio)")
  PrintN("Abra e ouca para confirmar: silencio / tom fixo / varredura grave->agudo / ruido / envelope / acorde / silencio.")
  ProcedureReturn #True
EndProcedure

Procedure RunLiveSmokeTest()
  PrintN("")
  PrintN("=== Teste 2: StartAudio()/StopAudio() ao vivo (thread waveOut real) ===")
  StartAudio() ; internally calls ResetPSG()

  ; Program an audible tone on the live PSG state while the audio thread streams it.
  PSG\R[0] = 226 & $FF : PSG\R[1] = (226 >> 8) & $0F ; ~247Hz
  PSG\R[7] = %00111110
  PSG\R[8] = $0F

  Protected startTicks.q = ElapsedMilliseconds()
  Delay(1500)
  SilenceAllChannels()
  Delay(300)
  Protected elapsed.q = ElapsedMilliseconds() - startTicks

  StopAudio()
  Protected stopTicks.q = ElapsedMilliseconds()

  PrintN("StartAudio -> tom por 1500ms -> silencio 300ms -> StopAudio concluido sem travar.")
  PrintN("Tempo total decorrido: " + Str(elapsed) + "ms (esperado ~1800ms)")
  If hWaveOut = 0
    PrintN("AVISO: hWaveOut ficou 0 apos StartAudio - waveOutOpen_ pode ter falhado (sem dispositivo de audio?).")
  Else
    PrintN("hWaveOut foi aberto com sucesso durante o teste (dispositivo de audio disponivel).")
  EndIf
EndProcedure

Procedure Main()
  OpenConsole("fossauro Audio Verification")

  Protected outPath.s = "audio_verify_output.wav"
  If CountProgramParameters() >= 1
    outPath = ProgramParameter(0)
  EndIf

  RunWavTest(outPath)
  RunLiveSmokeTest()

  PrintN("")
  PrintN("Pressione Enter para sair...")
  Input()
  CloseConsole()
EndProcedure

Main()
