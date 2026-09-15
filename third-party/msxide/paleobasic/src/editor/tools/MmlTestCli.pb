;
; ------------------------------------------------------------
;  Ferramenta de linha de comando para testar o motor MML/PLAY
;  (editor\MmlSynth.pbi) sem precisar abrir o editor.
;
;  Cobre: parse de nota/pausa/duracao/pontos/oitava/nota-absoluta N,
;  merge cronologico de ate 3 canais independentes com envelope
;  compartilhado, geracao do PLAY final, e um .wav de uma musiquinha de
;  teste pra ouvir manualmente.
;
;  Uso:
;    MmlTestCli.exe <pasta_de_saida>
;
;  Compilar com:
;    "C:\Basic\Compilers\pbcompiler.exe" editor\tools\MmlTestCli.pb /EXE editor\tools\MmlTestCli.exe /CONSOLE
; ------------------------------------------------------------
;

EnableExplicit
OpenConsole()

XIncludeFile "..\visual_editors\PsgSynth.pbi"
XIncludeFile "..\visual_editors\MmlSynth.pbi"

Define OutDir.s = ProgramParameter(0)
If OutDir = ""
  PrintN("Uso: MmlTestCli.exe <pasta_de_saida>")
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

; ------------------------------------------------------------
; Teste 1: notas simples "CDEFGAB" em O4/L4 - 7 eventos, cada um 1 seminima
; a 120bpm (0.5s), frequencia da primeira nota (C4) bate com o esperado.
; ------------------------------------------------------------
NewList Ev1.MmlNoteEvent()
NewList Env1.MmlEnvCmd()
MmlSynth_ParseChannel("T120O4L4CDEFGAB", Ev1(), Env1(), #Psg_SampleRate)
CheckTrue(Bool(ListSize(Ev1()) = 7), "7 notas parseadas de 'CDEFGAB' (achou " + Str(ListSize(Ev1())) + ")")

FirstElement(Ev1())
Define ExpectedC4.d = 440.0 * Pow(2.0, (0 - 9) / 12.0 + (4 - 4))
Define MeasuredHz.d = PsgSynth_PeriodToHz(((Ev1()\TP) & $0FFF))
CheckTrue(Bool(Abs(MeasuredHz - ExpectedC4) < (ExpectedC4 * 0.02)), "Frequencia de C4 dentro de 2% do esperado (~" + StrD(ExpectedC4,1) + "Hz, achou " + StrD(MeasuredHz,1) + "Hz)")

Define ExpectedDurSamp.q = Round((60.0/120.0) * (4.0/4.0) * #Psg_SampleRate, #PB_Round_Nearest)
CheckTrue(Bool(Ev1()\DurSamples = ExpectedDurSamp), "Duracao de uma seminima a 120bpm bate (esperado " + Str(ExpectedDurSamp) + ", achou " + Str(Ev1()\DurSamples) + ")")

; ------------------------------------------------------------
; Teste 2: ponto de aumento - "L4C." deve durar 1.5x "L4C"
; ------------------------------------------------------------
NewList Ev2.MmlNoteEvent()
NewList Env2.MmlEnvCmd()
MmlSynth_ParseChannel("T120L4C.", Ev2(), Env2(), #Psg_SampleRate)
FirstElement(Ev2())
Define DottedDur.q = Ev2()\DurSamples
CheckTrue(Bool(Abs(DottedDur - Round(ExpectedDurSamp * 1.5, #PB_Round_Nearest)) <= 1), "Nota pontuada dura 1.5x a nota normal")

; ------------------------------------------------------------
; Teste 3: pausa produz TP=0
; ------------------------------------------------------------
NewList Ev3.MmlNoteEvent()
NewList Env3.MmlEnvCmd()
MmlSynth_ParseChannel("T120L4R", Ev3(), Env3(), #Psg_SampleRate)
FirstElement(Ev3())
CheckTrue(Bool(Ev3()\TP = 0), "Pausa (R) produz TP=0")

; ------------------------------------------------------------
; Teste 4: N46 (nota absoluta) deve soar igual a O4A (A4=440Hz)
; ------------------------------------------------------------
NewList Ev4a.MmlNoteEvent()
NewList Env4a.MmlEnvCmd()
MmlSynth_ParseChannel("O4A", Ev4a(), Env4a(), #Psg_SampleRate)
NewList Ev4b.MmlNoteEvent()
NewList Env4b.MmlEnvCmd()
MmlSynth_ParseChannel("N46", Ev4b(), Env4b(), #Psg_SampleRate)
FirstElement(Ev4a()) : FirstElement(Ev4b())
CheckTrue(Bool(Ev4a()\TP = Ev4b()\TP), "N46 (nota absoluta) bate com O4A (TP " + Str(Ev4a()\TP) + " vs " + Str(Ev4b()\TP) + ")")

; ------------------------------------------------------------
; Teste 5: S liga UseEnvelope pras notas seguintes; V desliga de novo
; ------------------------------------------------------------
NewList Ev5.MmlNoteEvent()
NewList Env5.MmlEnvCmd()
MmlSynth_ParseChannel("M500S9CV10C", Ev5(), Env5(), #Psg_SampleRate)
CheckTrue(Bool(ListSize(Env5()) = 2), "2 comandos de envelope capturados (M e S)")
CheckTrue(Bool(ListSize(Ev5()) = 2), "2 notas parseadas em 'M500S9CV10C'")
FirstElement(Ev5())
CheckTrue(Ev5()\UseEnvelope, "1a nota (apos S9) usa envelope")
LastElement(Ev5())
CheckTrue(Bool(Ev5()\UseEnvelope = #False), "2a nota (apos V10) volta a usar volume fixo")
CheckTrue(Bool(Ev5()\Volume = 10), "2a nota tem volume 10 (V10)")

; ------------------------------------------------------------
; Teste 6: merge de 2 canais + render - canal A toca uma nota longa, canal B
; fica em silencio e depois toca - so pra gerar um .wav audivel de verdade e
; conferir que o total de amostras bate com o canal mais longo.
; ------------------------------------------------------------
NewList EvA.MmlNoteEvent()
NewList EnvA.MmlEnvCmd()
MmlSynth_ParseChannel("T120O4L2C", EvA(), EnvA(), #Psg_SampleRate)   ; 1 nota de meia (1s)

NewList EvB.MmlNoteEvent()
NewList EnvB.MmlEnvCmd()
MmlSynth_ParseChannel("T120O5L4RE", EvB(), EnvB(), #Psg_SampleRate)  ; pausa de seminima + nota de seminima

NewList EvC.MmlNoteEvent()
NewList EnvC.MmlEnvCmd()
; canal C vazio (nao usado nesta musica de teste)

Define TotalSamp = MmlSynth_SongTotalSamples(EvA(), EvB(), EvC())
CheckTrue(Bool(TotalSamp > 0), "SongTotalSamples > 0")

Define *SongBuf = MmlSynth_RenderSong(EvA(), EvB(), EvC(), EnvA(), EnvB(), EnvC(), #Psg_SampleRate, TotalSamp)
CheckTrue(Bool(*SongBuf <> 0), "RenderSong aloca buffer")

If *SongBuf
  Define Peak = 0
  Define si
  For si = 0 To TotalSamp - 1
    Define SampVal.w = PeekW(*SongBuf + si * 2)
    If Abs(SampVal) > Peak
      Peak = Abs(SampVal)
    EndIf
  Next
  CheckTrue(Bool(Peak > 0), "Musica de teste nao e silencio total (pico > 0)")

  PsgSynth_WriteWav(*SongBuf, TotalSamp, #Psg_SampleRate, OutDir + "mml_song.wav")
  PrintN("      escrito: " + OutDir + "mml_song.wav")
  FreeMemory(*SongBuf)
EndIf

; ------------------------------------------------------------
; Teste 7: geracao do comando PLAY final (so concatenacao literal)
; ------------------------------------------------------------
Define Play1.s = MmlSynth_BuildPlayStatement("CDE", "", "")
CheckTrue(Bool(Play1 = "PLAY " + Chr(34) + "CDE" + Chr(34)), "PLAY so com canal A: '" + Play1 + "'")

Define Play2.s = MmlSynth_BuildPlayStatement("CDE", "EFG", "")
CheckTrue(Bool(Play2 = "PLAY " + Chr(34) + "CDE" + Chr(34) + "," + Chr(34) + "EFG" + Chr(34)), "PLAY com canais A e B: '" + Play2 + "'")

Define Play3.s = MmlSynth_BuildPlayStatement("CDE", "EFG", "GAB")
CheckTrue(Bool(Play3 = "PLAY " + Chr(34) + "CDE" + Chr(34) + "," + Chr(34) + "EFG" + Chr(34) + "," + Chr(34) + "GAB" + Chr(34)), "PLAY com os 3 canais: '" + Play3 + "'")

PrintN("")
If Failures = 0
  PrintN("TODOS OS TESTES OK")
Else
  PrintN(Str(Failures) + " TESTE(S) FALHARAM")
  End 1
EndIf
