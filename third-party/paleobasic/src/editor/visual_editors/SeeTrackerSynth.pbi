;
; ------------------------------------------------------------
;  SeeTrackerSynth.pbi - motor sem GUI do "Criar -> SEE Tracker...": modelo
;  de dados do pattern (15 bytes CRUS, formato .SEE de verdade - ver Ajuda
;  -> SEE Tracker...), interpretador fiel ao driver (expande patterns +
;  eventos numa sequencia concreta de PsgStepData pra reaproveitar o motor
;  de sintese existente, PsgSynth.pbi) e o construtor do blob binario
;  .SEE-compativel + do codigo BASIC de carregamento.
;
;  Cada pattern e' guardado exatamente como no arquivo .SEE real (ver
;  Ajuda -> SEE Tracker..., "Formato de um pattern (15 bytes)"):
;    byte 0     event (bits 6-4 = comando, bits 3-0 = valor)
;    byte 1-2   frequencia canal 1 (12 bits + tuning up/down no byte alto)
;    byte 3-4   frequencia canal 2
;    byte 5-6   frequencia canal 3
;    byte 7     rustle (bits 4-0 = valor, bit 6/7 = tuning down/up)
;    byte 8     controle de canais (mixer, 6 bits, ativo baixo)
;    byte 9     volume canal 1 (bits 3-0 = valor, bit 4 = wave/envelope,
;               bit 6/7 = tuning down/up)
;    byte 10    volume canal 2
;    byte 11    volume canal 3
;    byte 12-13 periodo do envelope PSG (16 bits crus, regs 11/12 - SEM
;               mascara, apesar do manual original falar em "12 bits":
;               o driver escreve os bytes direto, conferido byte a byte)
;    byte 14    forma do envelope PSG (reg 13, cru)
;
;  Guardar o byte CRU (nao uma struct interpretada com campos separados)
;  deixa o "Gerar codigo" trivial (so concatena) e a mesma copia serve pro
;  interpretador de preview - sem risco de divergencia entre o que se edita
;  e o que realmente toca/e' gerado (mesma filosofia de Screen12EditorGui.pbi
;  guardando byte MSX cru por celula).
; ------------------------------------------------------------
;

CompilerIf Not Defined(SEETRACKERSYNTH_PBI_INCLUDED, #PB_Constant)
#SEETRACKERSYNTH_PBI_INCLUDED = 1

#SeeP_Event  = 0
#SeeP_Freq1L = 1
#SeeP_Freq1H = 2
#SeeP_Freq2L = 3
#SeeP_Freq2H = 4
#SeeP_Freq3L = 5
#SeeP_Freq3H = 6
#SeeP_Rustle = 7
#SeeP_Ctrl   = 8
#SeeP_Vol1   = 9
#SeeP_Vol2   = 10
#SeeP_Vol3   = 11
#SeeP_EnvLo  = 12
#SeeP_EnvHi  = 13
#SeeP_EnvShp = 14
#SeeP_Size   = 15

; Codigos de evento (nibble alto, ja deslocado - bits 6-4 do byte $00, ver
; Ajuda -> SEE Tracker..., "Bits exatos do byte de evento").
Enumeration SeeEvt
  #SeeEvt_None  = $00
  #SeeEvt_Halt  = $10
  #SeeEvt_For   = $20
  #SeeEvt_Next  = $30
  #SeeEvt_Start = $40
  #SeeEvt_Rerun = $50
  #SeeEvt_Tempo = $60
  #SeeEvt_End   = $70
EndEnumeration

; --- Acesso a campos individuais (le/grava direto no array achatado do
; chamador, PatternBytes(PatIdx*15+campo) - sem Structure de proposito, pra
; a mesma representacao servir tanto o array de trabalho da GUI quanto
; ProjectDB::StoreSeeSfx/FetchSeeSfx sem conversao) ---

Procedure.a SeeP_EventCmd(Array PB.a(1), Idx.i)
  ProcedureReturn PB(Idx * #SeeP_Size + #SeeP_Event) & $70
EndProcedure

Procedure.a SeeP_EventVal(Array PB.a(1), Idx.i)
  ProcedureReturn PB(Idx * #SeeP_Size + #SeeP_Event) & $0F
EndProcedure

Procedure SeeP_SetEvent(Array PB.a(1), Idx.i, Cmd.a, Val.a)
  PB(Idx * #SeeP_Size + #SeeP_Event) = (Cmd & $70) | (Val & $0F)
EndProcedure

; Freq de 0-2; devolve o valor 12 bits e as duas flags de tuning via ponteiro
Procedure.u SeeP_FreqVal(Array PB.a(1), Idx.i, Ch.i)
  Protected Lo.a = PB(Idx * #SeeP_Size + 1 + Ch * 2)
  Protected Hi.a = PB(Idx * #SeeP_Size + 2 + Ch * 2)
  ProcedureReturn ((Hi & $0F) << 8) | Lo
EndProcedure

Procedure.b SeeP_FreqTuneUp(Array PB.a(1), Idx.i, Ch.i)
  ProcedureReturn Bool((PB(Idx * #SeeP_Size + 2 + Ch * 2) & $80) <> 0)
EndProcedure

Procedure.b SeeP_FreqTuneDown(Array PB.a(1), Idx.i, Ch.i)
  ProcedureReturn Bool((PB(Idx * #SeeP_Size + 2 + Ch * 2) & $40) <> 0)
EndProcedure

Procedure SeeP_SetFreq(Array PB.a(1), Idx.i, Ch.i, Val.u, TuneUp.b, TuneDown.b)
  Protected Hi.a = (Val >> 8) & $0F
  If TuneUp : Hi | $80 : EndIf
  If TuneDown : Hi | $40 : EndIf
  PB(Idx * #SeeP_Size + 1 + Ch * 2) = Val & $FF
  PB(Idx * #SeeP_Size + 2 + Ch * 2) = Hi
EndProcedure

Procedure.a SeeP_RustleVal(Array PB.a(1), Idx.i)
  ProcedureReturn PB(Idx * #SeeP_Size + #SeeP_Rustle) & $1F
EndProcedure

Procedure.b SeeP_RustleTuneUp(Array PB.a(1), Idx.i)
  ProcedureReturn Bool((PB(Idx * #SeeP_Size + #SeeP_Rustle) & $80) <> 0)
EndProcedure

Procedure.b SeeP_RustleTuneDown(Array PB.a(1), Idx.i)
  ProcedureReturn Bool((PB(Idx * #SeeP_Size + #SeeP_Rustle) & $40) <> 0)
EndProcedure

Procedure SeeP_SetRustle(Array PB.a(1), Idx.i, Val.a, TuneUp.b, TuneDown.b)
  Protected B.a = Val & $1F
  If TuneUp : B | $80 : EndIf
  If TuneDown : B | $40 : EndIf
  PB(Idx * #SeeP_Size + #SeeP_Rustle) = B
EndProcedure

; Canal de som/rustle "ON" (fiel ao hardware/manual: bit 0 = LIGADO) - Ch 0-2
Procedure.b SeeP_ToneOn(Array PB.a(1), Idx.i, Ch.i)
  ProcedureReturn Bool((PB(Idx * #SeeP_Size + #SeeP_Ctrl) & (1 << Ch)) = 0)
EndProcedure

Procedure.b SeeP_NoiseOn(Array PB.a(1), Idx.i, Ch.i)
  ProcedureReturn Bool((PB(Idx * #SeeP_Size + #SeeP_Ctrl) & (1 << (Ch + 3))) = 0)
EndProcedure

Procedure SeeP_SetChannelOn(Array PB.a(1), Idx.i, Ch.i, ToneOn.b, NoiseOn.b)
  Protected B.a = PB(Idx * #SeeP_Size + #SeeP_Ctrl)
  If ToneOn : B & ~(1 << Ch) : Else : B | (1 << Ch) : EndIf
  If NoiseOn : B & ~(1 << (Ch + 3)) : Else : B | (1 << (Ch + 3)) : EndIf
  PB(Idx * #SeeP_Size + #SeeP_Ctrl) = B & $3F
EndProcedure

Procedure.a SeeP_VolVal(Array PB.a(1), Idx.i, Ch.i)
  ProcedureReturn PB(Idx * #SeeP_Size + #SeeP_Vol1 + Ch) & $0F
EndProcedure

Procedure.b SeeP_VolWave(Array PB.a(1), Idx.i, Ch.i)
  ProcedureReturn Bool((PB(Idx * #SeeP_Size + #SeeP_Vol1 + Ch) & $10) <> 0)
EndProcedure

Procedure.b SeeP_VolTuneUp(Array PB.a(1), Idx.i, Ch.i)
  ProcedureReturn Bool((PB(Idx * #SeeP_Size + #SeeP_Vol1 + Ch) & $80) <> 0)
EndProcedure

Procedure.b SeeP_VolTuneDown(Array PB.a(1), Idx.i, Ch.i)
  ProcedureReturn Bool((PB(Idx * #SeeP_Size + #SeeP_Vol1 + Ch) & $40) <> 0)
EndProcedure

Procedure SeeP_SetVol(Array PB.a(1), Idx.i, Ch.i, Val.a, Wave.b, TuneUp.b, TuneDown.b)
  Protected B.a = Val & $0F
  If Wave : B | $10 : EndIf
  If TuneUp : B | $80 : EndIf
  If TuneDown : B | $40 : EndIf
  PB(Idx * #SeeP_Size + #SeeP_Vol1 + Ch) = B
EndProcedure

Procedure.u SeeP_EnvPeriod(Array PB.a(1), Idx.i)
  ProcedureReturn PB(Idx * #SeeP_Size + #SeeP_EnvLo) | (PB(Idx * #SeeP_Size + #SeeP_EnvHi) << 8)
EndProcedure

Procedure SeeP_SetEnvPeriod(Array PB.a(1), Idx.i, Val.u)
  PB(Idx * #SeeP_Size + #SeeP_EnvLo) = Val & $FF
  PB(Idx * #SeeP_Size + #SeeP_EnvHi) = (Val >> 8) & $FF
EndProcedure

Procedure.a SeeP_EnvShape(Array PB.a(1), Idx.i)
  ProcedureReturn PB(Idx * #SeeP_Size + #SeeP_EnvShp)
EndProcedure

Procedure SeeP_SetEnvShape(Array PB.a(1), Idx.i, Val.a)
  PB(Idx * #SeeP_Size + #SeeP_EnvShp) = Val
EndProcedure

; Preenche um pattern novo com o "silencio padrao" (tudo desligado, sem
; evento) - equivalente ao pattern em branco do editor original.
Procedure SeeP_Clear(Array PB.a(1), Idx.i)
  Protected b
  For b = 0 To #SeeP_Size - 1
    PB(Idx * #SeeP_Size + b) = 0
  Next
  ; canais desligados = bits LIGADOS no byte de controle (ativo baixo)
  PB(Idx * #SeeP_Size + #SeeP_Ctrl) = $3F
EndProcedure

; ================================================================
; Interpretador: expande Patterns(StartIdx..) numa sequencia concreta de
; PsgStepData (ver PsgSynth.pbi), fiel ao MAIN/DOEVENT/SETPSG do driver
; (SeeTrackerDriverAsm.pbi) - inclusive a interacao real entre TEMPO e HALT
; (ver comentario grande em Ajuda -> SEE Tracker... nao cobre este nivel de
; detalhe; deduzido lendo o driver linha a linha nesta sessao):
;   - TEMPO (evento "TMP") controla de quantos em quantos "quadros" o
;     replay realmente re-processa (cada "passo logico" = TempoValue+1
;     quadros reais de 1/60s).
;   - HALT(x) NAO pausa o replay inteiro: o pattern que contem o HALT so
;     tem seus proprios dados PSG aplicados depois de x passos logicos
;     extras (o estado anterior continua soando esse tempo todo); no passo
;     logico seguinte ao fim da espera, os dados do PRoprio pattern do HALT
;     sao aplicados normalmente e o ponteiro avanca.
; FOR/NEXT/START/RERUN reaplicam so os DADOS do pattern-ancora (nunca
; reprocessam o evento de novo) - ver "Como FOR/NEXT...realmente funcionam".
; ================================================================

#SeeSynth_MaxLoops = 4
#SeeSynth_DefaultMaxFrames = 3600  ; ~60s a 60fps - teto de seguranca pra RERUN nao travar o preview

Structure SeeSynthLoopSlot
  Counter.a
  ReturnIdx.i
EndStructure

; Converte os 15 bytes do pattern Idx nos 14 registradores PSG crus,
; aplicando tuning/slide relativo ao passo anterior (*Prev, ou 0 = sem
; historico -> considera o "registrador anterior" zero em tudo) e o
; wraparound exato do driver (mascara SEMPRE aplicada DEPOIS da soma/
; subtracao, nunca clampada - ver Ajuda -> SEE Tracker..., "Slides de
; afinacao e volume"). NAO aplica FIXVOL/Max Volume (fica sempre no volume
; bruto, equivalente a Max Volume=15 - simplificacao so do PREVIEW, o
; codigo .SEE gerado continua exato e aplica a escala de verdade no
; hardware/driver real).
Procedure SeeSynth_BuildRegs(Array PB.a(1), Idx.i, *Out.PsgStepData, *Prev.PsgStepData = 0)
  Protected Ch
  Protected.u Freq, PrevFreq
  Protected.a Rustle, PrevRustle, Vol, PrevVol
  Protected TuneUp.b, TuneDown.b

  For Ch = 0 To 2
    Freq = SeeP_FreqVal(PB(), Idx, Ch)
    TuneUp = SeeP_FreqTuneUp(PB(), Idx, Ch)
    TuneDown = SeeP_FreqTuneDown(PB(), Idx, Ch)
    If TuneUp Or TuneDown
      PrevFreq = 0
      If *Prev
        PrevFreq = *Prev\Regs[Ch * 2] | (*Prev\Regs[Ch * 2 + 1] << 8)
      EndIf
      If TuneUp
        Freq = (PrevFreq + Freq) & $FFF
      Else
        Freq = (PrevFreq - Freq) & $FFF
      EndIf
    EndIf
    *Out\Regs[Ch * 2] = Freq & $FF
    *Out\Regs[Ch * 2 + 1] = (Freq >> 8) & $0F
  Next

  Rustle = SeeP_RustleVal(PB(), Idx)
  TuneUp = SeeP_RustleTuneUp(PB(), Idx)
  TuneDown = SeeP_RustleTuneDown(PB(), Idx)
  If TuneUp Or TuneDown
    PrevRustle = 0
    If *Prev : PrevRustle = *Prev\Regs[6] : EndIf
    If TuneUp
      Rustle = (PrevRustle + Rustle) & $1F
    Else
      Rustle = (PrevRustle - Rustle) & $1F
    EndIf
  EndIf
  *Out\Regs[6] = Rustle

  *Out\Regs[7] = PB(Idx * #SeeP_Size + #SeeP_Ctrl) & $3F

  For Ch = 0 To 2
    Vol = SeeP_VolVal(PB(), Idx, Ch)
    If SeeP_VolWave(PB(), Idx, Ch)
      *Out\Regs[8 + Ch] = Vol | $10
    Else
      TuneUp = SeeP_VolTuneUp(PB(), Idx, Ch)
      TuneDown = SeeP_VolTuneDown(PB(), Idx, Ch)
      PrevVol = 0
      If *Prev : PrevVol = *Prev\Regs[8 + Ch] & $0F : EndIf
      If TuneUp
        Vol = (PrevVol + Vol) & $0F   ; sem clamp - pode dar a volta (fiel ao driver)
      ElseIf TuneDown
        If Vol > PrevVol
          Vol = 0                     ; com clamp em 0 (fiel ao driver, VOL_DW)
        Else
          Vol = PrevVol - Vol
        EndIf
      EndIf
      *Out\Regs[8 + Ch] = Vol & $0F
    EndIf
  Next

  *Out\Regs[11] = SeeP_EnvPeriod(PB(), Idx) & $FF
  *Out\Regs[12] = (SeeP_EnvPeriod(PB(), Idx) >> 8) & $FF
  *Out\Regs[13] = SeeP_EnvShape(PB(), Idx)
EndProcedure

; Devolve #True se expandiu ate um EV_END real (efeito termina sozinho);
; #False se parou por bater no teto de MaxFrames (RERUN sem fim, tipico da
; parte "sustain" de um efeito - preview truncado de proposito).
;
; OutPatIdx() sai em paralelo a OutSteps() (mesmo tamanho, elemento a
; elemento) - o pattern de ORIGEM de cada step, usado pelo cursor de
; playback do editor (SeeTrackerEditorGui.pbi) pra saber em qual linha da
; grade destacar enquanto o som toca. O step de espera do HALT (ver Case
; #SeeEvt_Halt abaixo) tambem aponta pro pattern do proprio HALT (Cur) -
; visualmente o cursor fica "parado" naquela linha durante a espera, que e'
; exatamente o que esta acontecendo (o replay ainda nao avancou).
Procedure.b SeeSynth_Expand(Array PB.a(1), NumPatterns.i, StartIdx.i, List OutSteps.PsgStepData(), List OutPatIdx.i(), MaxFrames.i = #SeeSynth_DefaultMaxFrames)
  ClearList(OutSteps())
  ClearList(OutPatIdx())
  If StartIdx < 0 Or StartIdx >= NumPatterns
    ProcedureReturn #True
  EndIf

  Protected Cur.i = StartIdx
  Protected TempoVal.a = 0
  Protected LoopNr.a = 0
  Dim Loops.SeeSynthLoopSlot(#SeeSynth_MaxLoops - 1)
  Protected ClpAddr.i = -1
  Protected TotalFrames.i = 0
  Protected Cmd.a, Val.a
  Protected PrevStep.PsgStepData
  Protected HasPrev.b = #False
  Protected SafetyIters.i = 0, MaxIters.i = NumPatterns * 64 + 4096 ; teto generoso p/ nao travar em dado mal-formado

  ; Macro (nao Procedure) de proposito: precisa ver direto as variaveis
  ; locais desta chamada (TempoVal/PrevStep/HasPrev/TotalFrames), mesmo
  ; motivo das outras janelas de Ajuda desta IDE usarem Macro pro "Voltar".
  Macro SeeSynth_Emit(PatIdx)
    AddElement(OutSteps())
    If HasPrev
      SeeSynth_BuildRegs(PB(), PatIdx, @OutSteps(), @PrevStep)
    Else
      SeeSynth_BuildRegs(PB(), PatIdx, @OutSteps())
    EndIf
    OutSteps()\DurationFrames = TempoVal + 1
    TotalFrames + OutSteps()\DurationFrames
    PrevStep = OutSteps()
    HasPrev = #True
    AddElement(OutPatIdx())
    OutPatIdx() = PatIdx
  EndMacro

  Repeat
    SafetyIters + 1
    If SafetyIters > MaxIters Or TotalFrames >= MaxFrames
      ProcedureReturn #False
    EndIf

    If Cur < 0 Or Cur >= NumPatterns
      ProcedureReturn #True ; ponteiro saiu da lista - trata como fim
    EndIf

    Cmd = SeeP_EventCmd(PB(), Cur)
    Val = SeeP_EventVal(PB(), Cur)

    Select Cmd
      Case #SeeEvt_Halt
        ; Segura o estado ANTERIOR por Val passos logicos (Val*(TempoVal+1)
        ; quadros), depois aplica os dados deste MESMO pattern por 1 passo
        ; logico e avanca - ver comentario grande no topo do arquivo.
        If Val > 0
          AddElement(OutSteps())
          If HasPrev
            OutSteps() = PrevStep
          EndIf
          OutSteps()\DurationFrames = Val * (TempoVal + 1)
          TotalFrames + OutSteps()\DurationFrames
          AddElement(OutPatIdx())
          OutPatIdx() = Cur
        EndIf
        SeeSynth_Emit(Cur)
        Cur + 1

      Case #SeeEvt_For
        LoopNr = (LoopNr + 1) % #SeeSynth_MaxLoops
        Loops(LoopNr)\Counter = Val
        Loops(LoopNr)\ReturnIdx = Cur
        SeeSynth_Emit(Cur)
        Cur + 1

      Case #SeeEvt_Next
        Loops(LoopNr)\Counter - 1
        If Loops(LoopNr)\Counter = 0
          LoopNr = (LoopNr - 1 + #SeeSynth_MaxLoops) % #SeeSynth_MaxLoops
          SeeSynth_Emit(Cur)
          Cur + 1
        Else
          SeeSynth_Emit(Loops(LoopNr)\ReturnIdx)
          Cur = Loops(LoopNr)\ReturnIdx + 1
        EndIf

      Case #SeeEvt_Start
        ClpAddr = Cur
        SeeSynth_Emit(Cur)
        Cur + 1

      Case #SeeEvt_Rerun
        If ClpAddr >= 0
          SeeSynth_Emit(ClpAddr)
          Cur = ClpAddr + 1
        Else
          Cur + 1 ; RERUN sem START antes - dado mal formado, so segue
        EndIf

      Case #SeeEvt_Tempo
        TempoVal = Val
        SeeSynth_Emit(Cur)
        Cur + 1

      Case #SeeEvt_End
        ProcedureReturn #True

      Default ; #SeeEvt_None
        SeeSynth_Emit(Cur)
        Cur + 1
    EndSelect
  ForEver
EndProcedure

; ================================================================
; Construtor do blob binario .SEE-compativel (ver Ajuda -> SEE Tracker...,
; grupo "Formato de arquivo .SEE" - offsets confirmados por analise cruzada
; 2026-08-06) pra UM UNICO SFX (o "Gerar codigo" desta IDE, como os demais
; editores desta IDE - PsgEditorGui.pbi/PsgGen_* - gera so o conteudo
; ATUAL sendo editado, nao o banco inteiro do projeto).
; ================================================================

Procedure.i SeeGen_BuildSeeBlob(Array PB.a(1), NumPatterns.i, SfxNumber.i, Array OutBlob.a(1))
  ; A tabela de posicoes precisa ser SEMPRE os 512 bytes cheios (256 slots) -
  ; o driver (SeeTrackerDriverAsm.pbi, C_PTAD) usa PATTS_OFS=#0210 (=16+512)
  ; como constante FIXA pro inicio dos dados de pattern, nao um valor lido
  ; do arquivo. Uma tabela menor deslocaria os patterns pro lugar errado -
  ; bug real pego so ao revisar esta funcao contra o driver antes do
  ; primeiro teste (nao existe no formato original, so nesta 1a versao
  ; desta funcao).
  Protected HeaderLen = 16
  Protected PosTableLen = 512
  Protected PattLen = NumPatterns * 15
  Protected TotalLen = HeaderLen + PosTableLen + PattLen
  ReDim OutBlob(TotalLen - 1)

  ; ID: "SEE3" + 4 bytes livres (so os 4 primeiros importam pro driver)
  OutBlob(0) = Asc("S") : OutBlob(1) = Asc("E") : OutBlob(2) = Asc("E") : OutBlob(3) = Asc("3")
  OutBlob(4) = Asc("I") : OutBlob(5) = Asc("D") : OutBlob(6) = Asc("E") : OutBlob(7) = 1

  ; $08-$09 HISPT - constante de capacidade (1024 patterns enderecaveis)
  OutBlob(8) = $FF : OutBlob(9) = $03

  ; $0A-$0B HIPTA - offset (a partir de SEEADR) do fim dos dados de pattern
  Protected HiptaVal.u = HeaderLen + PosTableLen + PattLen
  OutBlob(10) = HiptaVal & $FF : OutBlob(11) = (HiptaVal >> 8) & $FF

  ; $0C-$0D HISFX - numero do SFX mais alto valido (so o proprio, os outros
  ; 255 slots ficam marcados como nao-usados abaixo)
  OutBlob(12) = SfxNumber & $FF : OutBlob(13) = (SfxNumber >> 8) & $FF

  ; $0E-$0F FLELN - tamanho total do arquivo (campo nao lido pelo player,
  ; preenchido por completude/inspecao - ver Ajuda -> SEE Tracker...)
  OutBlob(14) = TotalLen & $FF : OutBlob(15) = (TotalLen >> 8) & $FF

  ; Tabela de posicoes cheia (256 slots): todos marcados como nao-usados
  ; (sentinela byte alto #FF, ver Ajuda -> SEE Tracker...) exceto o slot do
  ; proprio SfxNumber, que aponta pro pattern 0 (unico SFX deste blob).
  Protected i
  For i = 0 To 255
    OutBlob(HeaderLen + i * 2) = 0 : OutBlob(HeaderLen + i * 2 + 1) = $FF
  Next
  OutBlob(HeaderLen + SfxNumber * 2) = 0
  OutBlob(HeaderLen + SfxNumber * 2 + 1) = 0

  ; Patterns crus (ja no formato exato)
  Protected b
  For i = 0 To NumPatterns - 1
    For b = 0 To 14
      OutBlob(HeaderLen + PosTableLen + i * 15 + b) = PB(i * 15 + b)
    Next
  Next

  ProcedureReturn TotalLen
EndProcedure

; ================================================================
; Importacao de arquivo .SEE real (gerado pelo editor original) - le o
; cabecalho/tabela de posicoes/patterns de volta, pro formato interno desta
; IDE (array achatado de 15 bytes/pattern). Usa os offsets confirmados por
; analise cruzada (Ajuda -> SEE Tracker..., "Cabecalho do arquivo... " +
; "Tabela de posicoes de SFX") - NAO confia no campo HISFX do cabecalho pra
; saber quantos SFX existem (visto uma leitura implausivel nele no
; QUARTH.SEE de exemplo, ver Ajuda), varre a tabela de posicoes inteira
; (256 slots fixos) procurando o sentinela $FF em cada slot.
; ================================================================

#SeeImp_HeaderLen  = 16
#SeeImp_PosTabLen  = 512
#SeeImp_PattBase   = #SeeImp_HeaderLen + #SeeImp_PosTabLen ; 528, mesmo PATTS_OFS do driver
#SeeImp_MaxPatternsPerSfx = 512 ; teto de seguranca (metade da capacidade do formato) contra arquivo sem END

; Confere so os 4 primeiros bytes (mesmo criterio permissivo do driver real -
; ver Ajuda -> SEE Tracker..., aceita tanto "SEE3org" quanto "SEE3EDIT").
Procedure.b SeeImp_IsValidHeader(Array FileBytes.a(1), FileLen.i)
  If FileLen < #SeeImp_PattBase
    ProcedureReturn #False
  EndIf
  ProcedureReturn Bool(FileBytes(0) = Asc("S") And FileBytes(1) = Asc("E") And FileBytes(2) = Asc("E") And FileBytes(3) = Asc("3"))
EndProcedure

; Preenche OutSfxNumbers()/OutStartPatterns() com cada slot da tabela de
; posicoes que NAO tem o sentinela $FF no byte alto - um par por SFX
; realmente definido no arquivo (na ordem do numero do SFX, 0-255).
Procedure SeeImp_ListDefinedSfx(Array FileBytes.a(1), FileLen.i, List OutSfxNumbers.i(), List OutStartPatterns.i())
  ClearList(OutSfxNumbers())
  ClearList(OutStartPatterns())
  If Not SeeImp_IsValidHeader(FileBytes(), FileLen)
    ProcedureReturn
  EndIf

  Protected i, Lo.a, Hi.a
  For i = 0 To 255
    Lo = FileBytes(#SeeImp_HeaderLen + i * 2)
    Hi = FileBytes(#SeeImp_HeaderLen + i * 2 + 1)
    If Hi <> $FF
      AddElement(OutSfxNumbers()) : OutSfxNumbers() = i
      AddElement(OutStartPatterns()) : OutStartPatterns() = Lo | (Hi << 8)
    EndIf
  Next
EndProcedure

; Extrai os patterns de UM sfx a partir do pattern inicial StartPattern,
; andando sequencialmente (mesma suposicao do proprio editor original: os
; patterns de um efeito ficam em posicoes CONSECUTIVAS na area de dados,
; todos os exemplos do manual sao assim) ate encontrar um evento END
; (incluido) ou bater o teto de seguranca/fim do arquivo. Devolve o numero
; de patterns extraidos (0 = nada, arquivo invalido ou StartPattern fora
; do arquivo).
Procedure.i SeeImp_ExtractSfxPatterns(Array FileBytes.a(1), FileLen.i, StartPattern.i, Array OutPB.a(1))
  If Not SeeImp_IsValidHeader(FileBytes(), FileLen)
    ProcedureReturn 0
  EndIf

  Protected Count.i = 0
  Protected PattIdx.i = StartPattern
  Protected Offset.i, b
  Protected Dim Tmp.a(#SeeImp_MaxPatternsPerSfx * #SeeP_Size - 1)

  Repeat
    Offset = #SeeImp_PattBase + PattIdx * 15
    If Offset + 15 > FileLen Or Count >= #SeeImp_MaxPatternsPerSfx
      Break
    EndIf
    For b = 0 To 14
      Tmp(Count * #SeeP_Size + b) = FileBytes(Offset + b)
    Next
    Protected IsEnd.b = Bool((Tmp(Count * #SeeP_Size + #SeeP_Event) & $70) = #SeeEvt_End)
    Count + 1
    PattIdx + 1
    If IsEnd
      Break
    EndIf
  ForEver

  If Count > 0
    ReDim OutPB(Count * #SeeP_Size - 1)
    Protected i
    For i = 0 To Count * #SeeP_Size - 1
      OutPB(i) = Tmp(i)
    Next
  EndIf
  ProcedureReturn Count
EndProcedure

; Le o arquivo inteiro pra um array de bytes achatado - helper de
; conveniencia (ReadFile/ReadData) pro chamador nao repetir esse boilerplate.
Procedure.i SeeImp_LoadFile(Path.s, Array OutBytes.a(1))
  Protected FileNum = ReadFile(#PB_Any, Path)
  If Not FileNum
    ProcedureReturn 0
  EndIf
  Protected Len.i = Lof(FileNum)
  If Len <= 0
    CloseFile(FileNum)
    ProcedureReturn 0
  EndIf
  ReDim OutBytes(Len - 1)
  ReadData(FileNum, @OutBytes(0), Len)
  CloseFile(FileNum)
  ProcedureReturn Len
EndProcedure

; ================================================================
; Geracao de codigo BASIC: monta o driver (Z80Asm::Assemble sobre
; SeeDrv_SourceCode(), ver SeeTrackerDriverAsm.pbi) + o blob .SEE do SFX
; atual, tudo via DATA+POKE (mesmo espirito de PsgGen_RawBytes/os
; carregadores de fonte customizada dos editores Screen0/1/1+2 - sem
; depender de BLOAD/arquivo em disco), mais as linhas DEFUSR/USR() prontas.
; ================================================================

#SeeGen_DriverAddr = $C000
#SeeGen_DataAddr   = $8000

Procedure.s SeeGen_DataLines(Array Bytes.a(1), Count.i)
  Protected Result.s = "", Line.s = "", i, InLine = 0
  For i = 0 To Count - 1
    If InLine = 0
      Line = "DATA "
    Else
      Line + ","
    EndIf
    Line + Str(Bytes(i))
    InLine + 1
    If InLine = 16 Or i = Count - 1
      Result + Line + #CRLF$
      Line = "" : InLine = 0
    EndIf
  Next
  ProcedureReturn Result
EndProcedure

; Devolve "" em erro (chamador consulta Z80Asm::GetAssembleErrorLine()/
; GetAssembleErrorText() nesse caso - estado global do modulo, nao precisa
; de out-param aqui); senao o codigo BASIC pronto.
Procedure.s SeeGen_BuildCode(Array PB.a(1), NumPatterns.i, SfxNumber.i, SfxTag.s)
  Protected Dim AsmBytes.a(65535)
  Protected N = Z80Asm::Assemble(SeeDrv_SourceCode(), AsmBytes())
  If N <= 0
    ProcedureReturn ""
  EndIf

  Protected Dim DrvBytes.a(N - 1)
  Protected i
  For i = 0 To N - 1
    DrvBytes(i) = AsmBytes(i)
  Next

  Protected Dim Blob.a(1)
  Protected BlobLen = SeeGen_BuildSeeBlob(PB(), NumPatterns, SfxNumber, Blob())

  ; Endereco real de SEEADR (variavel de trabalho do driver) consultado no
  ; assembler, nao um offset chumbado - continua correto se a fonte de
  ; SeeDrv_SourceCode() mudar de tamanho no futuro.
  Protected SeeAdrAddr.u = Z80Asm::GetSymbolValue("SEEADR")

  Protected TagSuffix.s = ""
  If SfxTag <> ""
    TagSuffix = " (" + SfxTag + ")"
  EndIf

  Protected Result.s = ""
  Result + "' --- Driver de replay SEE Tracker (nativo desta IDE, ver Ajuda -> SEE Tracker...) ---" + #CRLF$
  Result + "FOR SI=0 TO " + Str(N - 1) + ":READ SD:POKE " + Str(#SeeGen_DriverAddr) + "+SI,SD:NEXT SI" + #CRLF$
  Result + SeeGen_DataLines(DrvBytes(), N)
  Result + "' --- Dados do SFX #" + Str(SfxNumber) + TagSuffix + " (formato .SEE) ---" + #CRLF$
  Result + "FOR SI=0 TO " + Str(BlobLen - 1) + ":READ SD:POKE " + Str(#SeeGen_DataAddr) + "+SI,SD:NEXT SI" + #CRLF$
  Result + SeeGen_DataLines(Blob(), BlobLen)
  Result + "' --- Usar (ver Ajuda -> SEE Tracker... para detalhe de cada vetor) ---" + #CRLF$
  Result + "POKE " + Str(SeeAdrAddr) + "," + Str(#SeeGen_DataAddr & $FF) + ":POKE " + Str(SeeAdrAddr + 1) + "," + Str((#SeeGen_DataAddr >> 8) & $FF) + " ' SEEADR = endereco dos dados" + #CRLF$
  Result + "DEFUSR0=" + Str(#SeeGen_DriverAddr) + ":A=USR(0)  ' liga o driver (SEE_IN)" + #CRLF$
  Result + "DEFUSR1=" + Str(#SeeGen_DriverAddr + 15) + ":A=USR(" + Str(SfxNumber) + ")  ' toca o SFX #" + Str(SfxNumber) + " (prioridade 0)" + #CRLF$
  Result + "DEFUSR2=" + Str(#SeeGen_DriverAddr + 9) + ":A=USR(0)  ' corta o SFX (CUTSFX)" + #CRLF$
  Result + "DEFUSR3=" + Str(#SeeGen_DriverAddr + 3) + ":A=USR(0)  ' desliga o driver (SEE_EX)" + #CRLF$

  ProcedureReturn Result
EndProcedure

CompilerEndIf ; SEETRACKERSYNTH_PBI_INCLUDED
