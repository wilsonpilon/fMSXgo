;
; ------------------------------------------------------------
;  Motor de compilacao/sintese de MML (Music Macro Language) do comando PLAY
;  do MSX-BASIC. Sem nenhuma dependencia de GUI - incluido tanto pela janela
;  "Criar -> Musica (PLAY)..." (MmlEditorGui.pbi) quanto pelo harness headless
;  (editor/tools/MmlTestCli.pb).
;
;  Reaproveita ao maximo o motor de PSG ja existente (PsgSynth.pbi) - o PLAY
;  toca no mesmo chip do SOUND (mesmos 3 osciladores de tom, mesmo unico
;  gerador de envelope compartilhado). Este arquivo so faz duas coisas que o
;  PsgSynth.pbi nao fazia: (1) PARSEAR uma string MML por canal numa lista de
;  eventos de nota (PsgSynth_HzToPeriod ja resolve nota->registrador), e
;  (2) MESCLAR cronologicamente os 3 canais independentes num unico fluxo de
;  PsgStepData, chamando PsgSynth_RenderStep() (inalterado) para cada
;  intervalo. Nenhum DSP novo foi escrito.
;
;  Dialeto MML coberto (MSX-BASIC, ver docs/SPEC.md modulo 8):
;    A-G[+/-][duracao][.]   nota (sustenido +/#/bemol -, duracao 1-64, pontos)
;    R[duracao][.]          pausa
;    N<1-96>                nota absoluta (cromatica, 8 oitavas x 12 semitons)
;    O<1-8>                 define oitava (default 4)
;    > / <                  sobe/desce 1 oitava
;    L<1-64>                duracao padrao (default 4)
;    T<32-255>               andamento/BPM (default 120)
;    V<0-15>                volume do canal (default 8) - desliga o envelope
;    M<1-65535>             periodo do envelope (registrador R11/R12 do PSG)
;    S<0-15>                forma do envelope (registrador R13) - LIGA o modo
;                           envelope neste canal (so retrigga quando escrito)
;  Caracteres nao reconhecidos (inclusive espaco) sao ignorados - o parser
;  nunca "erra" (o codigo PLAY final gerado e sempre o texto literal que o
;  usuario montou, nao depende deste parser - ver MmlSynth_BuildPlayStatement).
; ------------------------------------------------------------
;

EnableExplicit

XIncludeFile "PsgSynth.pbi"

Structure MmlNoteEvent
  StartSample.q
  DurSamples.q
  TP.i             ; periodo de registrador (0 = pausa/silencio)
  Volume.b
  UseEnvelope.b
EndStructure

; Comando M ou S encontrado durante o parse de UM canal, com seu instante
; absoluto (em amostras) dentro da timeline DAQUELE canal - usado depois pra
; mesclar cronologicamente com os outros 2 canais (o envelope e compartilhado
; pelo chip inteiro, nao é por canal).
Structure MmlEnvCmd
  SampleTime.q
  IsShape.b        ; #True = comando S (retrigga o envelope); #False = comando M (so atualiza o periodo pendente)
  Value.i
EndStructure

Structure MmlEnvRetrigger
  SampleTime.q
  Period.i
  Shape.b
EndStructure

; Wrapper minimo pra permitir 3 saidas por ponteiro em MmlSynth_FindActiveNote
; sem ambiguidade de sintaxe (ponteiro tipado com tipo basico usa PokeL/PeekL,
; nao \campo - tipando com esta struct de 1 campo, \v funciona e o layout de
; memoria e identico ao de um .l puro).
Structure MmlOutInt
  v.l
EndStructure

Procedure.i MmlSynth_Clamp(v.i, lo.i, hi.i)
  If v < lo : v = lo : EndIf
  If v > hi : v = hi : EndIf
  ProcedureReturn v
EndProcedure

Procedure.i MmlSynth_NoteBaseSemitone(Letter.s)
  Select Letter
    Case "C" : ProcedureReturn 0
    Case "D" : ProcedureReturn 2
    Case "E" : ProcedureReturn 4
    Case "F" : ProcedureReturn 5
    Case "G" : ProcedureReturn 7
    Case "A" : ProcedureReturn 9
    Case "B" : ProcedureReturn 11
  EndSelect
  ProcedureReturn 0
EndProcedure

; Temperamento igual, A na oitava 4 = 440 Hz (convencao padrao).
Procedure.d MmlSynth_NoteFreq(Octave.i, Semitone.i)
  Protected.d Exponent = (Semitone - 9) / 12.0 + (Octave - 4)
  ProcedureReturn 440.0 * Pow(2.0, Exponent)
EndProcedure

; L=4 e uma seminima (quarter note): duracao em quartos = 4/L. Cada ponto
; multiplica a duracao corrente por 1,5x (mesma convencao ja confirmada para
; o dialeto MSX/GW-BASIC MML - nao e a formula "aditiva" classica de teoria
; musical, e a multiplicativa mais simples de implementar num interpretador).
Procedure.q MmlSynth_DurationSamples(Tempo.i, Length.i, Dots.i, SampleRate.i)
  Protected.d Quarters = 4.0 / Length
  Protected.d Seconds = (60.0 / Tempo) * Quarters
  Protected i
  For i = 1 To Dots
    Seconds * 1.5
  Next
  ProcedureReturn Round(Seconds * SampleRate, #PB_Round_Nearest)
EndProcedure

; Devolve a posicao logo apos o ultimo digito decimal a partir de Pos (Pos
; inalterado se nao ha digito ali) - o chamador calcula o valor com
; Val(Mid(Texto, PosOriginal, PosNova-PosOriginal)).
Procedure.i MmlSynth_SkipDigits(MmlText.s, Pos.i)
  Protected L = Len(MmlText)
  While Pos <= L And Mid(MmlText, Pos, 1) >= "0" And Mid(MmlText, Pos, 1) <= "9"
    Pos + 1
  Wend
  ProcedureReturn Pos
EndProcedure

; Parseia o texto MML de UM canal pra dentro de Events()/EnvCmds() (limpos no
; inicio). Tolerante: qualquer caractere nao reconhecido (inclusive espaco) e
; simplesmente pulado.
Procedure MmlSynth_ParseChannel(MmlText.s, List Events.MmlNoteEvent(), List EnvCmds.MmlEnvCmd(), SampleRate.i)
  ClearList(Events())
  ClearList(EnvCmds())

  Protected Octave.i = 4
  Protected DefaultLen.i = 4
  Protected Tempo.i = 120
  Protected Volume.i = 8
  Protected UseEnvelope.b = #False
  Protected.q CurSample = 0

  Protected Pos.i = 1
  Protected L = Len(UCase(MmlText))
  Protected MmlU.s = UCase(MmlText)
  Protected Ch.s
  Protected NumStart.i, NumVal.i
  Protected Semitone.i, Dots.i
  Protected.d Freq
  Protected TP.i
  Protected.q Dur

  While Pos <= L
    Ch = Mid(MmlU, Pos, 1)
    Select Ch
      Case "A", "B", "C", "D", "E", "F", "G"
        Semitone = MmlSynth_NoteBaseSemitone(Ch)
        Pos + 1
        If Pos <= L
          Protected Acc.s = Mid(MmlU, Pos, 1)
          If Acc = "+" Or Acc = "#"
            Semitone + 1
            Pos + 1
          ElseIf Acc = "-"
            Semitone - 1
            Pos + 1
          EndIf
        EndIf
        NumStart = Pos
        Pos = MmlSynth_SkipDigits(MmlU, Pos)
        If Pos > NumStart
          NumVal = Val(Mid(MmlU, NumStart, Pos - NumStart))
        Else
          NumVal = DefaultLen
        EndIf
        Dots = 0
        While Pos <= L And Mid(MmlU, Pos, 1) = "."
          Dots + 1
          Pos + 1
        Wend

        Freq = MmlSynth_NoteFreq(Octave, Semitone)
        TP = PsgSynth_HzToPeriod(Freq)
        Dur = MmlSynth_DurationSamples(Tempo, NumVal, Dots, SampleRate)

        AddElement(Events())
        Events()\StartSample = CurSample
        Events()\DurSamples = Dur
        Events()\TP = TP
        Events()\Volume = Volume
        Events()\UseEnvelope = UseEnvelope
        CurSample + Dur

      Case "R"
        Pos + 1
        NumStart = Pos
        Pos = MmlSynth_SkipDigits(MmlU, Pos)
        If Pos > NumStart
          NumVal = Val(Mid(MmlU, NumStart, Pos - NumStart))
        Else
          NumVal = DefaultLen
        EndIf
        Dots = 0
        While Pos <= L And Mid(MmlU, Pos, 1) = "."
          Dots + 1
          Pos + 1
        Wend
        Dur = MmlSynth_DurationSamples(Tempo, NumVal, Dots, SampleRate)

        AddElement(Events())
        Events()\StartSample = CurSample
        Events()\DurSamples = Dur
        Events()\TP = 0
        Events()\Volume = 0
        Events()\UseEnvelope = #False
        CurSample + Dur

      Case "N"
        Pos + 1
        NumStart = Pos
        Pos = MmlSynth_SkipDigits(MmlU, Pos)
        If Pos > NumStart
          NumVal = Val(Mid(MmlU, NumStart, Pos - NumStart))
        Else
          NumVal = 1
        EndIf
        NumVal = MmlSynth_Clamp(NumVal, 1, 96)
        Protected NOctave.i = ((NumVal - 1) / 12) + 1
        Protected NSemi.i = (NumVal - 1) % 12
        Freq = MmlSynth_NoteFreq(NOctave, NSemi)
        TP = PsgSynth_HzToPeriod(Freq)
        Dur = MmlSynth_DurationSamples(Tempo, DefaultLen, 0, SampleRate)

        AddElement(Events())
        Events()\StartSample = CurSample
        Events()\DurSamples = Dur
        Events()\TP = TP
        Events()\Volume = Volume
        Events()\UseEnvelope = UseEnvelope
        CurSample + Dur

      Case "O"
        Pos + 1
        NumStart = Pos
        Pos = MmlSynth_SkipDigits(MmlU, Pos)
        If Pos > NumStart
          Octave = MmlSynth_Clamp(Val(Mid(MmlU, NumStart, Pos - NumStart)), 1, 8)
        EndIf

      Case ">"
        Pos + 1
        Octave = MmlSynth_Clamp(Octave + 1, 1, 8)

      Case "<"
        Pos + 1
        Octave = MmlSynth_Clamp(Octave - 1, 1, 8)

      Case "L"
        Pos + 1
        NumStart = Pos
        Pos = MmlSynth_SkipDigits(MmlU, Pos)
        If Pos > NumStart
          DefaultLen = MmlSynth_Clamp(Val(Mid(MmlU, NumStart, Pos - NumStart)), 1, 64)
        EndIf

      Case "T"
        Pos + 1
        NumStart = Pos
        Pos = MmlSynth_SkipDigits(MmlU, Pos)
        If Pos > NumStart
          Tempo = MmlSynth_Clamp(Val(Mid(MmlU, NumStart, Pos - NumStart)), 32, 255)
        EndIf

      Case "V"
        Pos + 1
        NumStart = Pos
        Pos = MmlSynth_SkipDigits(MmlU, Pos)
        If Pos > NumStart
          Volume = MmlSynth_Clamp(Val(Mid(MmlU, NumStart, Pos - NumStart)), 0, 15)
        EndIf
        UseEnvelope = #False

      Case "M"
        Pos + 1
        NumStart = Pos
        Pos = MmlSynth_SkipDigits(MmlU, Pos)
        If Pos > NumStart
          AddElement(EnvCmds())
          EnvCmds()\SampleTime = CurSample
          EnvCmds()\IsShape = #False
          EnvCmds()\Value = MmlSynth_Clamp(Val(Mid(MmlU, NumStart, Pos - NumStart)), 1, 65535)
        EndIf

      Case "S"
        Pos + 1
        NumStart = Pos
        Pos = MmlSynth_SkipDigits(MmlU, Pos)
        If Pos > NumStart
          AddElement(EnvCmds())
          EnvCmds()\SampleTime = CurSample
          EnvCmds()\IsShape = #True
          EnvCmds()\Value = MmlSynth_Clamp(Val(Mid(MmlU, NumStart, Pos - NumStart)), 0, 15)
        EndIf
        UseEnvelope = #True

      Default
        Pos + 1   ; espaco ou caractere desconhecido - ignora
    EndSelect
  Wend
EndProcedure

Procedure.q MmlSynth_ChannelEndSample(List Events.MmlNoteEvent())
  Protected.q MaxEnd = 0
  ForEach Events()
    If Events()\StartSample + Events()\DurSamples > MaxEnd
      MaxEnd = Events()\StartSample + Events()\DurSamples
    EndIf
  Next
  ProcedureReturn MaxEnd
EndProcedure

Procedure.i MmlSynth_SongTotalSamples(List EventsA.MmlNoteEvent(), List EventsB.MmlNoteEvent(), List EventsC.MmlNoteEvent())
  Protected.q MaxEnd = MmlSynth_ChannelEndSample(EventsA())
  Protected.q EndB = MmlSynth_ChannelEndSample(EventsB())
  Protected.q EndC = MmlSynth_ChannelEndSample(EventsC())
  If EndB > MaxEnd : MaxEnd = EndB : EndIf
  If EndC > MaxEnd : MaxEnd = EndC : EndIf
  ProcedureReturn MaxEnd
EndProcedure

; Acha o evento de nota que cobre QueryTime no canal (0/silencio se nenhum -
; ex.: silencio inicial antes da primeira nota, ou depois da ultima).
Procedure MmlSynth_FindActiveNote(List Events.MmlNoteEvent(), QueryTime.q, *TP.MmlOutInt, *Vol.MmlOutInt, *UseEnv.MmlOutInt)
  *TP\v = 0
  *Vol\v = 0
  *UseEnv\v = #False
  ForEach Events()
    If Events()\StartSample <= QueryTime And (Events()\StartSample + Events()\DurSamples) > QueryTime
      *TP\v = Events()\TP
      *Vol\v = Events()\Volume
      *UseEnv\v = Events()\UseEnvelope
      ProcedureReturn
    EndIf
  Next
EndProcedure

; Mescla os 3 canais ja parseados (eventos + comandos de envelope) num unico
; buffer PCM, reaproveitando PsgSynth_RenderStep() sem modifica-lo: monta um
; PsgStepData por intervalo entre pontos de corte (inicio/fim de nota em
; qualquer canal, ou instante de um comando S) e chama RenderStep com o
; numero exato de amostras do intervalo - sem passar pelo caminho baseado em
; quadros/DurationFrames (mais preciso pra musica). TotalSamples deve vir de
; MmlSynth_SongTotalSamples() antes. O chamador deve FreeMemory() o retorno.
Procedure.i MmlSynth_RenderSong(List EventsA.MmlNoteEvent(), List EventsB.MmlNoteEvent(), List EventsC.MmlNoteEvent(),
                                 List EnvCmdsA.MmlEnvCmd(), List EnvCmdsB.MmlEnvCmd(), List EnvCmdsC.MmlEnvCmd(),
                                 SampleRate.i, TotalSamples.i)
  If TotalSamples <= 0
    ProcedureReturn 0
  EndIf

  Protected *Buffer = AllocateMemory(TotalSamples * 2)
  If Not *Buffer
    ProcedureReturn 0
  EndIf

  ; --- comandos M/S dos 3 canais, mesclados em ordem cronologica GLOBAL - so
  ; assim da pra saber, no instante de cada S, qual foi o M mais recente
  ; (o envelope e um unico gerador compartilhado pelo chip inteiro).
  NewList AllEnv.MmlEnvCmd()
  ForEach EnvCmdsA() : AddElement(AllEnv()) : AllEnv() = EnvCmdsA() : Next
  ForEach EnvCmdsB() : AddElement(AllEnv()) : AllEnv() = EnvCmdsB() : Next
  ForEach EnvCmdsC() : AddElement(AllEnv()) : AllEnv() = EnvCmdsC() : Next

  ; ordena por SampleTime - insertion sort simples (nao ha constante pronta
  ; do PureBasic pra SortStructuredList com campo .q, e a lista e tipicamente
  ; pequena - poucos comandos M/S por musica montada a mao).
  Protected EnvCount = ListSize(AllEnv())
  If EnvCount > 1
    Dim EnvArr.MmlEnvCmd(EnvCount - 1)
    Protected ei = 0
    ForEach AllEnv()
      EnvArr(ei) = AllEnv()
      ei + 1
    Next
    Protected ej, ek
    Protected EnvTmp.MmlEnvCmd
    For ej = 1 To EnvCount - 1
      EnvTmp = EnvArr(ej)
      ek = ej - 1
      While ek >= 0 And EnvArr(ek)\SampleTime > EnvTmp\SampleTime
        EnvArr(ek + 1) = EnvArr(ek)
        ek - 1
      Wend
      EnvArr(ek + 1) = EnvTmp
    Next
    ClearList(AllEnv())
    For ej = 0 To EnvCount - 1
      AddElement(AllEnv())
      AllEnv() = EnvArr(ej)
    Next
  EndIf

  Protected PendingPeriod.i = 1000
  NewList Retrig.MmlEnvRetrigger()
  ForEach AllEnv()
    If AllEnv()\IsShape
      AddElement(Retrig())
      Retrig()\SampleTime = AllEnv()\SampleTime
      Retrig()\Period = PendingPeriod
      Retrig()\Shape = AllEnv()\Value
    Else
      PendingPeriod = AllEnv()\Value
    EndIf
  Next

  ; --- pontos de corte: inicio/fim de toda nota nos 3 canais + instante de
  ; todo retrigger de envelope + 0/TotalSamples como limites.
  NewList Bounds.q()
  AddElement(Bounds()) : Bounds() = 0
  AddElement(Bounds()) : Bounds() = TotalSamples
  ForEach EventsA()
    AddElement(Bounds()) : Bounds() = EventsA()\StartSample
    AddElement(Bounds()) : Bounds() = EventsA()\StartSample + EventsA()\DurSamples
  Next
  ForEach EventsB()
    AddElement(Bounds()) : Bounds() = EventsB()\StartSample
    AddElement(Bounds()) : Bounds() = EventsB()\StartSample + EventsB()\DurSamples
  Next
  ForEach EventsC()
    AddElement(Bounds()) : Bounds() = EventsC()\StartSample
    AddElement(Bounds()) : Bounds() = EventsC()\StartSample + EventsC()\DurSamples
  Next
  ForEach Retrig()
    AddElement(Bounds()) : Bounds() = Retrig()\SampleTime
  Next

  Protected NumBoundsRaw = ListSize(Bounds())
  Dim RawArr.q(NumBoundsRaw - 1)
  Protected bi = 0
  ForEach Bounds()
    RawArr(bi) = Bounds()
    bi + 1
  Next

  ; ordena RawArr (insertion sort - mesmo motivo de AllEnv acima)
  Protected bj, bk
  Protected.q BoundsTmp
  For bj = 1 To NumBoundsRaw - 1
    BoundsTmp = RawArr(bj)
    bk = bj - 1
    While bk >= 0 And RawArr(bk) > BoundsTmp
      RawArr(bk + 1) = RawArr(bk)
      bk - 1
    Wend
    RawArr(bk + 1) = BoundsTmp
  Next

  ; remove duplicatas consecutivas
  Dim BoundArr.q(NumBoundsRaw - 1)
  Protected NumBounds = 0
  Protected LastVal.q = -1
  For bi = 0 To NumBoundsRaw - 1
    If RawArr(bi) <> LastVal
      BoundArr(NumBounds) = RawArr(bi)
      NumBounds + 1
      LastVal = RawArr(bi)
    EndIf
  Next

  Protected St.PsgChipState
  PsgSynth_InitState(@St)

  Protected CurShape.b = 0
  Protected CurPeriod.i = 1000
  Protected Cursor.i = 0
  Protected i
  Protected.q IntervalStart, IntervalEnd, NumSamp
  Protected TPa.l, Vola.l, UEa.l
  Protected TPb.l, Volb.l, UEb.l
  Protected TPc.l, Volc.l, UEc.l
  Protected Mixer.a
  Protected Snap.PsgStepData

  For i = 0 To NumBounds - 2
    IntervalStart = BoundArr(i)
    IntervalEnd = BoundArr(i + 1)
    NumSamp = IntervalEnd - IntervalStart
    If NumSamp > 0
      MmlSynth_FindActiveNote(EventsA(), IntervalStart, @TPa, @Vola, @UEa)
      MmlSynth_FindActiveNote(EventsB(), IntervalStart, @TPb, @Volb, @UEb)
      MmlSynth_FindActiveNote(EventsC(), IntervalStart, @TPc, @Volc, @UEc)

      Snap\Regs[0] = TPa & $FF : Snap\Regs[1] = (TPa >> 8) & $0F
      Snap\Regs[2] = TPb & $FF : Snap\Regs[3] = (TPb >> 8) & $0F
      Snap\Regs[4] = TPc & $FF : Snap\Regs[5] = (TPc >> 8) & $0F
      Snap\Regs[6] = 0   ; PLAY/MML nao usa ruido

      Mixer = %00111000  ; ruido sempre desligado nos 3 canais (bits 3-5)
      If TPa = 0 : Mixer = Mixer | %00000001 : EndIf
      If TPb = 0 : Mixer = Mixer | %00000010 : EndIf
      If TPc = 0 : Mixer = Mixer | %00000100 : EndIf
      Snap\Regs[7] = Mixer

      Snap\Regs[8]  = Vola & $0F : If UEa : Snap\Regs[8]  = Snap\Regs[8]  | $10 : EndIf
      Snap\Regs[9]  = Volb & $0F : If UEb : Snap\Regs[9]  = Snap\Regs[9]  | $10 : EndIf
      Snap\Regs[10] = Volc & $0F : If UEc : Snap\Regs[10] = Snap\Regs[10] | $10 : EndIf

      ForEach Retrig()
        If Retrig()\SampleTime = IntervalStart
          CurPeriod = Retrig()\Period
          CurShape = Retrig()\Shape
        EndIf
      Next
      Snap\Regs[11] = CurPeriod & $FF
      Snap\Regs[12] = (CurPeriod >> 8) & $FF
      Snap\Regs[13] = CurShape

      PsgSynth_RenderStep(@St, @Snap, SampleRate, *Buffer, Cursor, NumSamp)
      Cursor + NumSamp
    EndIf
  Next

  ProcedureReturn *Buffer
EndProcedure

; Concatena o MML de cada canal (ja com as linhas do usuario juntadas) no
; comando PLAY final, omitindo canais vazios a partir do ultimo usado (ex.: so
; A e B usados -> PLAY "..","..", sem virgula/aspas extra pro C).
Procedure.s MmlSynth_BuildPlayStatement(LinesA.s, LinesB.s, LinesC.s)
  Protected A.s = ReplaceString(LinesA, Chr(34), "")
  Protected B.s = ReplaceString(LinesB, Chr(34), "")
  Protected C.s = ReplaceString(LinesC, Chr(34), "")

  Protected LastNonEmpty = 0
  If C <> "" : LastNonEmpty = 3
  ElseIf B <> "" : LastNonEmpty = 2
  ElseIf A <> "" : LastNonEmpty = 1
  EndIf

  If LastNonEmpty = 0
    ProcedureReturn ""
  EndIf

  Protected Result.s = "PLAY " + Chr(34) + A + Chr(34)
  If LastNonEmpty >= 2
    Result + "," + Chr(34) + B + Chr(34)
  EndIf
  If LastNonEmpty >= 3
    Result + "," + Chr(34) + C + Chr(34)
  EndIf
  ProcedureReturn Result
EndProcedure
