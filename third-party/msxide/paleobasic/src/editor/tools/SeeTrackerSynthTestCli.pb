;
; ------------------------------------------------------------
;  SeeTrackerSynthTestCli.pb - harness headless do motor SeeTrackerSynth.pbi
;  (interpretador de patterns .SEE -> PsgStepData + gerador de codigo).
;  Mesmo padrao PASS/FAIL de PsgTestCli.pb - exit code = numero de falhas.
;
;  Compilar:
;  "C:\Basic\Compilers\pbcompiler.exe" editor\tools\SeeTrackerSynthTestCli.pb /EXE editor\tools\SeeTrackerSynthTestCli.exe /CONSOLE
; ------------------------------------------------------------
;

EnableExplicit

XIncludeFile "..\assemblers\Z80Asm.pbi"
XIncludeFile "..\visual_editors\PsgSynth.pbi"
XIncludeFile "..\visual_editors\SeeTrackerDriverAsm.pbi"
XIncludeFile "..\visual_editors\SeeTrackerSynth.pbi"

OpenConsole()

Define Fails.i = 0

Macro CHECK(Cond, Msg)
  If Cond
    PrintN("PASS: " + Msg)
  Else
    PrintN("FAIL: " + Msg)
    Fails + 1
  EndIf
EndMacro

; --- Teste 1: pattern simples, sem evento, 1 canal ligado ---
Define Dim PB1.a(#SeeP_Size - 1)
SeeP_Clear(PB1(), 0)
SeeP_SetFreq(PB1(), 0, 0, 500, #False, #False)
SeeP_SetChannelOn(PB1(), 0, 0, #True, #False)
SeeP_SetVol(PB1(), 0, 0, 15, #False, #False, #False)
SeeP_SetEvent(PB1(), 0, #SeeEvt_End, 0)

NewList Steps1.PsgStepData()
NewList PatIdx1.i()
Define Ended1.b = SeeSynth_Expand(PB1(), 1, 0, Steps1(), PatIdx1())
CHECK(Ended1, "Teste 1: efeito com so END termina (nao trunca)")
CHECK(ListSize(Steps1()) = 0, "Teste 1: END no primeiro pattern nao emite nenhum step (correto - so encerra)")

; --- Teste 2: 2 patterns, freq 500 -> HALT(2) -> mesmo pattern reaplicado ---
Define Dim PB2.a(#SeeP_Size * 2 - 1)
SeeP_Clear(PB2(), 0)
SeeP_SetFreq(PB2(), 0, 0, 500, #False, #False)
SeeP_SetChannelOn(PB2(), 0, 0, #True, #False)
SeeP_SetVol(PB2(), 0, 0, 15, #False, #False, #False)
SeeP_SetEvent(PB2(), 0, #SeeEvt_Halt, 2)

SeeP_Clear(PB2(), 1)
SeeP_SetEvent(PB2(), 1, #SeeEvt_End, 0)

NewList Steps2.PsgStepData()
NewList PatIdx2.i()
Define Ended2.b = SeeSynth_Expand(PB2(), 2, 0, Steps2(), PatIdx2())
CHECK(Ended2, "Teste 2: HALT seguido de END termina corretamente")
; Espera 2 steps: 1 "segura estado anterior" (silencio, ja que nao havia
; nada antes) por 2 quadros (Val=2, Tempo=0 -> 2*(0+1)=2), depois o proprio
; pattern 0 por 1 quadro (Tempo+1=1). Total 3 quadros.
Define TotalDur2.i = 0
ForEach Steps2()
  TotalDur2 + Steps2()\DurationFrames
Next
CHECK(ListSize(Steps2()) = 2, "Teste 2: HALT(2) gera 2 steps (espera + aplica)")
CHECK(TotalDur2 = 3, "Teste 2: duracao total = 3 quadros (2 de espera + 1 de aplicacao), veio " + Str(TotalDur2))
FirstElement(Steps2())
CHECK(Steps2()\Regs[0] = 0 And Steps2()\Regs[1] = 0, "Teste 2: 1o step (espera) e' silencio (sem estado anterior)")
LastElement(Steps2())
Define ExpFreqLo.i = 500 & $FF, ExpFreqHi.i = (500 >> 8) & $0F
CHECK(Steps2()\Regs[0] = ExpFreqLo And Steps2()\Regs[1] = ExpFreqHi, "Teste 2: 2o step tem a frequencia 500 do pattern 0")
; PatIdx2 (cursor de playback do editor - ver SeeTrackerEditorGui.pbi): os
; 2 steps do HALT (espera + aplica) vem AMBOS do pattern 0 (o unico que
; existe alem do END) - o cursor deve ficar "parado" nele o tempo todo.
CHECK(ListSize(PatIdx2()) = 2, "Teste 2: PatIdx2 tem 1 indice de pattern por step (2), veio " + Str(ListSize(PatIdx2())))
FirstElement(PatIdx2())
Define PatIdx2First.i = PatIdx2()
LastElement(PatIdx2())
Define PatIdx2Last.i = PatIdx2()
CHECK(PatIdx2First = 0 And PatIdx2Last = 0, "Teste 2: os 2 steps do HALT apontam pro pattern 0 (espera E aplica), veio " + Str(PatIdx2First) + "/" + Str(PatIdx2Last))

; --- Teste 3: FOR(3)/NEXT loop - conta quantas vezes o pattern do FOR e' emitido ---
Define Dim PB3.a(#SeeP_Size * 3 - 1)
SeeP_Clear(PB3(), 0)
SeeP_SetFreq(PB3(), 0, 0, 111, #False, #False)
SeeP_SetChannelOn(PB3(), 0, 0, #True, #False)
SeeP_SetVol(PB3(), 0, 0, 15, #False, #False, #False)
SeeP_SetEvent(PB3(), 0, #SeeEvt_For, 3)

SeeP_Clear(PB3(), 1)
SeeP_SetEvent(PB3(), 1, #SeeEvt_Next, 0)

SeeP_Clear(PB3(), 2)
SeeP_SetEvent(PB3(), 2, #SeeEvt_End, 0)

NewList Steps3.PsgStepData()
NewList PatIdx3.i()
Define Ended3.b = SeeSynth_Expand(PB3(), 3, 0, Steps3(), PatIdx3())
CHECK(Ended3, "Teste 3: FOR/NEXT/END termina corretamente (nao trava)")
; FOR dispara 1x (emite pattern0), depois NEXT reaplica pattern0 mais
; (3-1)=2 vezes antes do contador zerar, e a ultima vez que NEXT roda com
; contador=0 emite o proprio NEXT (pattern1, silencio) e segue pro END.
; Total esperado: 1 (FOR) + 2 (NEXT re-emitindo pattern0) + 1 (NEXT final,
; pattern1) = 4 steps.
CHECK(ListSize(Steps3()) = 4, "Teste 3: FOR(3)/NEXT gera 4 steps (1 FOR + 2 reaplicacoes + 1 NEXT final), veio " + Str(ListSize(Steps3())))
Define CountFreq111.i = 0
ForEach Steps3()
  If Steps3()\Regs[0] = (111 & $FF) And Steps3()\Regs[1] = ((111 >> 8) & $0F)
    CountFreq111 + 1
  EndIf
Next
CHECK(CountFreq111 = 3, "Teste 3: frequencia 111 (pattern do FOR) aparece exatamente 3 vezes (1+2 repeticoes)")
; PatIdx3 (cursor de playback): esperado [0,0,0,1] - FOR e as 2 reaplicacoes
; do NEXT ficam todas no pattern 0 (a ancora do loop), so o ULTIMO step
; (NEXT com contador zerado, que processa o proprio pattern1) move o
; cursor pro pattern 1 - exatamente o instante em que o loop realmente
; termina e o replay segue adiante.
CHECK(ListSize(PatIdx3()) = 4, "Teste 3: PatIdx3 tem 1 indice de pattern por step (4), veio " + Str(ListSize(PatIdx3())))
Define CountPat0.i = 0
ForEach PatIdx3()
  If PatIdx3() = 0 : CountPat0 + 1 : EndIf
Next
LastElement(PatIdx3())
Define PatIdx3Last.i = PatIdx3()
CHECK(CountPat0 = 3, "Teste 3: 3 dos 4 steps apontam pro pattern 0 (FOR + 2 reaplicacoes do NEXT), veio " + Str(CountPat0))
CHECK(PatIdx3Last = 1, "Teste 3: o cursor so move pro pattern 1 no ULTIMO step (NEXT com contador zerado), veio " + Str(PatIdx3Last))

; --- Teste 4: RERUN sem fim trunca no teto de seguranca (nao trava) ---
Define Dim PB4.a(#SeeP_Size * 2 - 1)
SeeP_Clear(PB4(), 0)
SeeP_SetEvent(PB4(), 0, #SeeEvt_Start, 0)
SeeP_Clear(PB4(), 1)
SeeP_SetEvent(PB4(), 1, #SeeEvt_Rerun, 0)

NewList Steps4.PsgStepData()
NewList PatIdx4.i()
Define Ended4.b = SeeSynth_Expand(PB4(), 2, 0, Steps4(), PatIdx4(), 100) ; teto baixo de proposito pro teste ser rapido
CHECK(Not Ended4, "Teste 4: RERUN sem fim NAO termina sozinho (retorna #False - truncado pelo teto)")
Define TotalDur4.i = 0
ForEach Steps4()
  TotalDur4 + Steps4()\DurationFrames
Next
CHECK(TotalDur4 >= 100, "Teste 4: preview foi truncado no teto de seguranca (>=100 quadros), veio " + Str(TotalDur4))

; --- Teste 5: geracao de codigo (driver + blob) nao falha e contem os marcadores esperados ---
Define Code5.s = SeeGen_BuildCode(PB2(), 2, 7, "teste")
CHECK(Code5 <> "", "Teste 5: SeeGen_BuildCode nao retornou vazio (driver assemblou)")
CHECK(FindString(Code5, "DEFUSR0") > 0, "Teste 5: codigo gerado tem DEFUSR0 (liga o driver)")
CHECK(FindString(Code5, "DEFUSR1=" + Str($C000 + 15)) > 0, "Teste 5: codigo gerado tem DEFUSR1 no vetor BSETFX (+15)")
CHECK(FindString(Code5, "USR(7)") > 0, "Teste 5: codigo gerado usa o numero do SFX (7) no USR() de tocar")

; --- Teste 6: blob .SEE tem o cabecalho no formato confirmado ---
Define Dim Blob6.a(1)
Define BlobLen6.i = SeeGen_BuildSeeBlob(PB2(), 2, 3, Blob6())
CHECK(Blob6(0) = Asc("S") And Blob6(1) = Asc("E") And Blob6(2) = Asc("E") And Blob6(3) = Asc("3"), "Teste 6: blob comeca com SEE3")
CHECK(Blob6(8) = $FF And Blob6(9) = $03, "Teste 6: HISPT ($08-09) = $03FF (constante de capacidade)")
Define ExpHipta.i = 16 + 512 + 2 * 15
CHECK(Blob6(10) = (ExpHipta & $FF) And Blob6(11) = ((ExpHipta >> 8) & $FF), "Teste 6: HIPTA ($0A-0B) bate com 16+512+patterns*15")
CHECK(BlobLen6 = 16 + 512 + 2 * 15, "Teste 6: tamanho total do blob bate (header+tabela cheia+patterns)")
CHECK(Blob6(16 + 3 * 2) = 0 And Blob6(16 + 3 * 2 + 1) = 0, "Teste 6: slot da tabela de posicoes do SFX #3 aponta pro pattern 0")
CHECK(Blob6(16 + 0 * 2 + 1) = $FF, "Teste 6: slot 0 (nao usado) tem o sentinela $FF no byte alto")

PrintN("")
If Fails = 0
  PrintN("TODOS OS TESTES PASSARAM")
Else
  PrintN(Str(Fails) + " TESTE(S) FALHARAM")
EndIf
End Fails
