;
; ------------------------------------------------------------
;  Comando XM do Mamute Assembler - porta do comando M do monitor SUPER-X
;  (docs/SPEC.md modulo 45, others/superx/SUPER-X.DOC.pdf, secao "Assembly
;  input"). Batizado XM (nao M) porque o Mamute ja tem seu proprio M (grade
;  de edicao rapida de memoria, herdado do MegaAssembler, MamuteMGui.pbi,
;  modulo 31) com significado diferente - mesma decisao do XD (ver
;  MamuteXdGui.pbi).
;
;  "Entra em modo interativo, mostra o endereco e espera entrada que e
;  gravada na memoria. O contador de endereco avanca sozinho apos gravacao
;  bem-sucedida. Por padrao a entrada e assembler." (doc do SUPER-X) - janela
;  nova, dedicada (nao reaproveita o log do MON> - mesmo raciocinio do EDIT,
;  modulo 31: uma sub-sessao interativa de verdade precisa do seu proprio
;  laco de eventos, nao cabe no fluxo "uma linha, um comando" do MON>
;  principal). Layout deliberadamente igual ao MON> (EditorGadget de log +
;  rotulo de endereco + StringGadget de entrada) pra ficar visualmente
;  familiar.
;
;  Gramatica de cada linha digitada (ver MamuteXm_ProcessLine abaixo pro
;  detalhe completo):
;  - `I [<n>]` - lista as proximas <n> instrucoes (default 20) a partir do
;    endereco atual, so' leitura, nao avanca nada - reaproveita
;    Mamute_DisasmBuildLines() (mesmo motor do L/LP, modulo 31).
;  - `<sinal><dado1>[,<dado2>,...]` - grava dados crus no endereco atual e
;    avanca: `.` 1 byte cada item, `:`/`;` 2 bytes cada item (little-endian),
;    `[` 1 byte cada item, `"` string literal crua (resto da linha, sem
;    precisar fechar aspas - mesma convencao ja usada pelo MS, modulo 31).
;    Cada item de `.`/`:`/`;`/`[` passa por Mamute_CL_Eval() (MamuteSupport.pbi)
;    - aceita numero simples OU expressao completa (+ - * / % | & ^ ! (),
;      literal ASCII 'A'/"AB") - mesma calculadora do comando CL, decisao ja
;    registrada no modulo 45 do SPEC (reusar a MESMA convencao numerica em
;    todo comando novo, em vez do dialeto proprio do SUPER-X original).
;  - `<endereco>[#slot[-subslot]|#V|#4|#S|#5] [<sinal><dado>...]` - pula o
;    endereco/ALVO atual pro informado (so' quando o 1o token bate com
;    Mamute_ParseSxAddr() E NAO e' um mnemonico Z80 reconhecido -
;    `Z80Asm::IsMnemonic()` evita ambiguidade real com os DOIS mnemonicos
;    sem operando que tambem sao hexa valido, `DAA`/`CCF`; sem essa checagem
;    "DAA" sozinho virava salto pro endereco 0DAAh em vez da instrucao) - se
;    sobrar conteudo depois do endereco, ja processa como dado (mesma regra
;    acima) nessa mesma linha. O sufixo de slot/VRAM (docs/SPEC.md modulo
;    45b, Mamute_ParseSxAddr()/MamuteSupport.pbi) TROCA o alvo da sessao
;    inteira dali em diante (nao volta pro PAGE sozinho) - "D000#3-1"
;    redireciona escrita/leitura pro slot 3 sub-slot 1 ate a proxima troca
;    ou fechar a janela.
;  - qualquer outra coisa - tenta montar como UMA instrucao Z80 de verdade
;    via `Z80Asm::ParseLine()`+`Z80Asm::EncodeInstruction()` (motor nativo
;    ja usado pelo comando A do EDIT, modulo 31), grava os bytes gerados e
;    avanca o endereco pelo tamanho da instrucao.
; ------------------------------------------------------------
;

#MamuteXm_EnterShortcut = 9740
#MamuteXm_UpShortcut    = 9741
#MamuteXm_DownShortcut  = 9742
#MamuteXm_EscShortcut   = 9743

Global MamuteXm_LastError.s
Global MamuteXm_LastLogText.s

Procedure.b MamuteXm_IsTypeSign(Ch.s)
  ProcedureReturn Bool(Ch = "." Or Ch = ":" Or Ch = ";" Or Ch = "[" Or Ch = Chr(34))
EndProcedure

; Processa "<sinal><dado1>[,<dado2>,...]" a partir de *InOutAddr, gravando na
; memoria e avancando o endereco. #False + MamuteXm_LastError em qualquer
; item invalido - nada e gravado se ALGUM item falhar (valida tudo antes de
; escrever qualquer byte). MamuteXm_LastLogText preenchido com os bytes
; gravados em hexa, pro chamador ecoar no log.
Procedure.b MamuteXm_ProcessData(Sign.s, DataText.s, *InOutAddr.Integer, *T.MamuteSxTarget)
  If Sign = Chr(34)
    If DataText = ""
      MamuteXm_LastError = "ERRO DE SINTAXE"
      ProcedureReturn #False
    EndIf
    Protected Addr1.i = *InOutAddr\i
    Protected HexPart1.s = ""
    Protected i1.i, Code1.a
    For i1 = 1 To Len(DataText)
      Code1 = Asc(Mid(DataText, i1, 1)) & $FF
      Mamute_SxWriteByte(Addr1, Code1, *T)
      HexPart1 + Mamute_Hex2(Code1) + " "
      Addr1 = Mamute_SxWrapAddr(Addr1 + 1, *T)
    Next
    *InOutAddr\i = Addr1
    MamuteXm_LastLogText = Trim(HexPart1)
    ProcedureReturn #True
  EndIf

  If DataText = ""
    MamuteXm_LastError = "ERRO DE SINTAXE"
    ProcedureReturn #False
  EndIf

  Protected Width.i = 1
  If Sign = ":" Or Sign = ";" : Width = 2 : EndIf

  ; 1a passada: avalia TODOS os itens antes de gravar qualquer byte (evita
  ; escrita parcial se um item no meio da lista for invalido).
  Protected NewList Values.i()
  Protected Remaining.s = DataText
  Protected CommaPos.i, Tok.s, V.i
  Repeat
    CommaPos = FindString(Remaining, ",")
    If CommaPos > 0
      Tok = Trim(Left(Remaining, CommaPos - 1))
      Remaining = Mid(Remaining, CommaPos + 1)
    Else
      Tok = Trim(Remaining)
      Remaining = ""
    EndIf
    If Tok = ""
      MamuteXm_LastError = "ERRO DE SINTAXE"
      ProcedureReturn #False
    EndIf
    If Not Mamute_CL_Eval(Tok, @V)
      MamuteXm_LastError = "NUMERO INVALIDO: " + Tok
      ProcedureReturn #False
    EndIf
    AddElement(Values())
    Values() = V
  Until Remaining = ""

  Protected Addr2.i = *InOutAddr\i
  Protected HexPart2.s = ""
  ForEach Values()
    If Width = 1
      Mamute_SxWriteByte(Addr2, Values() & $FF, *T)
      HexPart2 + Mamute_Hex2(Values() & $FF) + " "
      Addr2 = Mamute_SxWrapAddr(Addr2 + 1, *T)
    Else
      Mamute_SxWriteByte(Addr2, Values() & $FF, *T)
      Mamute_SxWriteByte(Mamute_SxWrapAddr(Addr2 + 1, *T), (Values() >> 8) & $FF, *T)
      HexPart2 + Mamute_Hex2(Values() & $FF) + " " + Mamute_Hex2((Values() >> 8) & $FF) + " "
      Addr2 = Mamute_SxWrapAddr(Addr2 + 2, *T)
    EndIf
  Next
  *InOutAddr\i = Addr2
  MamuteXm_LastLogText = Trim(HexPart2)
  ProcedureReturn #True
EndProcedure

; Tenta montar Line como UMA instrucao Z80 (via Z80Asm::ParseLine +
; EncodeInstruction, motor nativo ja usado pelo comando A do EDIT). Grava os
; bytes gerados em *InOutAddr, avanca. #False + MamuteXm_LastError se nao for
; uma instrucao valida.
Procedure.b MamuteXm_ProcessInstruction(Line.s, *InOutAddr.Integer, *T.MamuteSxTarget)
  Protected PL.Z80Asm::Z80ParsedLine
  Z80Asm::ParseLine(Line, @PL)
  If PL\IsBlank Or Not PL\HasOperator Or PL\HasLabel
    MamuteXm_LastError = "ERRO DE SINTAXE"
    ProcedureReturn #False
  EndIf

  Z80Asm::SetCurrentLocation(*InOutAddr\i)
  Dim Out.a(3)
  Protected N.i = Z80Asm::EncodeInstruction(PL\Operator, PL\ArgsText, #True, Out())
  If N <= 0
    Protected AsmErr.s = Z80Asm::GetLastAsmError()
    If AsmErr = "" : AsmErr = "ERRO DE SINTAXE" : EndIf
    MamuteXm_LastError = AsmErr
    ProcedureReturn #False
  EndIf

  Protected Addr.i = *InOutAddr\i
  Protected HexPart.s = ""
  Protected bi.i
  For bi = 0 To N - 1
    Mamute_SxWriteByte(Addr, Out(bi), *T)
    HexPart + Mamute_Hex2(Out(bi)) + " "
    Addr = Mamute_SxWrapAddr(Addr + 1, *T)
  Next
  *InOutAddr\i = Addr
  MamuteXm_LastLogText = Trim(HexPart)
  ProcedureReturn #True
EndProcedure

; Processa UMA linha digitada no prompt do XM - devolve #True se algo foi
; gravado/deve ser ecoado no log (MamuteXm_LastLogText preenchido), #False em
; erro (MamuteXm_LastError preenchido) OU quando a linha era so' a listagem
; "I" (nada gravado, mas nao e' erro - *OutIsListing sinaliza esse caso pro
; chamador tratar/mostrar diferente).
; *T e' o alvo ATUAL da sessao - lido (pras leituras/escritas de dado) e
; ESCRITO quando a linha tem um salto de endereco com sufixo de slot/VRAM
; (docs/SPEC.md modulo 45b) - dali em diante toda a sessao do XM usa o alvo
; novo, ate o proximo salto com sufixo ou fechar a janela.
Procedure.b MamuteXm_ProcessLine(Line.s, *InOutAddr.Integer, *OutIsListing.Integer, *T.MamuteSxTarget)
  *OutIsListing\i = #False
  Protected Trimmed.s = Trim(Line)
  If Trimmed = ""
    ProcedureReturn #False
  EndIf

  Protected UTrim.s = UCase(Trimmed)
  If UTrim = "I" Or (Len(UTrim) > 1 And Left(UTrim, 1) = "I" And Mid(UTrim, 2, 1) = " ")
    *OutIsListing\i = #True
    ProcedureReturn #True
  EndIf

  Protected FirstCh.s = Left(Trimmed, 1)
  If MamuteXm_IsTypeSign(FirstCh)
    ProcedureReturn MamuteXm_ProcessData(FirstCh, Mid(Trimmed, 2), *InOutAddr, *T)
  EndIf

  Protected SpacePos.i = FindString(Trimmed, " ")
  Protected FirstTok.s, Rest.s
  If SpacePos > 0
    FirstTok = Left(Trimmed, SpacePos - 1)
    Rest = Trim(Mid(Trimmed, SpacePos + 1))
  Else
    FirstTok = Trimmed
    Rest = ""
  EndIf

  Protected NewAddr.i
  Protected NewTarget.MamuteSxTarget
  ; "endereco sem sufixo #... assume o slot ATUAL" (doc do SUPER-X, secao
  ; "General information" - "If the slot number is left out... the current
  ; slot is assumed") - por isso so troca *T quando o token TEM "#" de
  ; verdade; sem "#", o salto move so o ponteiro, mantendo o alvo (slot/sub-
  ; slot/VRAM) que a sessao ja estava usando. "#S"/"#5" EXPLICITO ainda
  ; reseta pro PAGE corrente de proposito (e a forma documentada de voltar).
  Protected HasHashSuffix.b = Bool(FindString(FirstTok, "#") > 0)
  If Not Z80Asm::IsMnemonic(UCase(FirstTok)) And Mamute_ParseSxAddr(FirstTok, @NewAddr, @NewTarget) And
     (Rest = "" Or MamuteXm_IsTypeSign(Left(Rest, 1)))
    *InOutAddr\i = NewAddr
    If HasHashSuffix
      CopyStructure(@NewTarget, *T, MamuteSxTarget)
    EndIf
    If Rest = ""
      MamuteXm_LastLogText = ""
      ProcedureReturn #True
    EndIf
    ProcedureReturn MamuteXm_ProcessData(Left(Rest, 1), Mid(Rest, 2), *InOutAddr, *T)
  EndIf

  ProcedureReturn MamuteXm_ProcessInstruction(Trimmed, *InOutAddr, *T)
EndProcedure

; Formata o endereco atual pro rotulo de prompt/log - 4 digitos (ou 5 se o
; alvo agora for VRAM) + sufixo de slot/VRAM (Mamute_SxTargetSuffixText -
; "" quando o alvo e' so o PAGE corrente, sem nada especial pra mostrar).
Procedure.s MamuteXm_FormatAddr(Addr.i, *T.MamuteSxTarget)
  Protected Digits.i = 4
  If *T\IsVram : Digits = 5 : EndIf
  ProcedureReturn Mamute_HexPad(Addr, Digits) + Mamute_SxTargetSuffixText(*T)
EndProcedure

; Devolve o endereco final (onde o cursor ficou ao fechar) - mesmo idioma do
; M/S/XD, pra "sem argumento, continua daqui". *Target e' o alvo inicial
; (PAGE corrente/slot explicito/sub-slot/VRAM, ver MamuteAssemblerGui.pbi) -
; TAMBEM usado como out-parameter: ao fechar, guarda o alvo com que a sessao
; ficou (pode ter mudado no meio, via linha "ENDERECO#slot", ver
; MamuteXm_ProcessLine) pra "sem argumento, continua dali" reabrir no MESMO
; alvo, nao so' o mesmo endereco.
Procedure.i MamuteXm_Open(ParentWindow, StartAddr.i, *Target.MamuteSxTarget)
  Z80Asm::ResetState() ; limpa qualquer estado deixado por um "Montar" (EDIT) anterior - XM nao usa simbolos/labels

  Protected CurTarget.MamuteSxTarget
  CopyStructure(*Target, @CurTarget, MamuteSxTarget)
  Protected CurAddr.i = Mamute_SxWrapAddr(StartAddr, @CurTarget)

  Protected MStyle.i = 0
  If MamuteFontBold : MStyle = #PB_Font_Bold : EndIf
  Protected MFont = LoadFont(#PB_Any, MamuteFontName, MamuteFontSize, MStyle)
  If Not MFont
    MFont = LoadFont(#PB_Any, "Consolas", 14, #PB_Font_Bold)
  EndIf

  Protected WinW = 760, WinH = 520
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Mamute Assembler - XM (SUPER-X)",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #True, #False)
  If Not Win
    ProcedureReturn StartAddr
  EndIf

  Protected ColFront = Mamute_CurrentFrontColor(), ColBack = Mamute_CurrentBackColor(), ColBorder = Mamute_CurrentBorderColor()
  SetWindowColor(Win, ColBorder)

  Protected G_Legend = TextGadget(#PB_Any, 16, 12, WinW - 32, 20,
    "I [<n>]: lista  .:;[  dados (1/2/2/1 byte)  " + Chr(34) + "texto  ENDERECO[#slot[-sub]|#V|#S]: salta  " +
    "senao: instrucao Z80  ESC: sai")
  SetGadgetColor(G_Legend, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Legend, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Legend, FontID(MFont))

  Protected G_Log = EditorGadget(#PB_Any, 16, 40, WinW - 32, WinH - 96, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
  SetGadgetColor(G_Log, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Log, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Log, FontID(MFont))

  Protected G_Prompt = TextGadget(#PB_Any, 16, WinH - 46, 140, 24, MamuteXm_FormatAddr(CurAddr, @CurTarget) + ">")
  SetGadgetColor(G_Prompt, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Prompt, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Prompt, FontID(MFont))

  Protected G_Input = StringGadget(#PB_Any, 160, WinH - 48, WinW - 176, 26, "")
  SetGadgetColor(G_Input, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Input, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Input, FontID(MFont))

  Protected LogAccum.s = MamuteGui_AppendLog(G_Log, "", "XM " + MamuteXm_FormatAddr(CurAddr, @CurTarget) + " - modo assembler/dados (ESC sai)")

  SetActiveGadget(G_Input)
  AddKeyboardShortcut(Win, #PB_Shortcut_Return, #MamuteXm_EnterShortcut)
  AddKeyboardShortcut(Win, #PB_Shortcut_Up, #MamuteXm_UpShortcut)
  AddKeyboardShortcut(Win, #PB_Shortcut_Down, #MamuteXm_DownShortcut)
  AddKeyboardShortcut(Win, #PB_Shortcut_Escape, #MamuteXm_EscShortcut)

  Protected NewList LineHist.s()
  Protected HistPos.i = -1

  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Menu
        Select EventMenu()
          Case #MamuteXm_EnterShortcut
            Protected Line.s = GetGadgetText(G_Input)
            If Trim(Line) <> ""
              SetGadgetText(G_Input, "")
              HistPos = -1
              AddElement(LineHist())
              LineHist() = Line

              Protected IsListing.i
              Protected LineStartAddr.i = CurAddr
              Protected NewAddr.i = CurAddr
              If MamuteXm_ProcessLine(Line, @NewAddr, @IsListing, @CurTarget)
                If IsListing
                  ; "I" reaproveita Mamute_DisasmBuildLines(), que so' le via
                  ; Mamute_ReadByte() (PAGE-relativo) - nao entende slot
                  ; explicito/sub-slot/VRAM ainda (docs/SPEC.md modulo 45b).
                  ; Recusa em vez de mostrar bytes errados silenciosamente.
                  If CurTarget\IsExplicit Or CurTarget\IsVram
                    LogAccum = MamuteGui_AppendLog(G_Log, LogAccum, "?LISTAGEM 'I' SO FUNCIONA COM O PAGE CORRENTE (sem #slot/#V)")
                  Else
                    Protected NStr.s = Trim(Mid(Trim(Line), 2))
                    Protected NLines.i = 20
                    Protected NVal.i
                    If NStr <> "" And Mamute_CL_Eval(NStr, @NVal) And NVal > 0
                      NLines = NVal
                    EndIf
                    Protected NewList DLines.s()
                    Protected NextAddr.i
                    Mamute_DisasmBuildLines(DLines(), CurAddr, #True, (CurAddr + NLines * 4) & $FFFF, @NextAddr)
                    Protected Shown.i = 0
                    ForEach DLines()
                      If Shown >= NLines : Break : EndIf
                      LogAccum = MamuteGui_AppendLog(G_Log, LogAccum, DLines())
                      Shown + 1
                    Next
                  EndIf
                Else
                  CurAddr = NewAddr
                  If MamuteXm_LastLogText <> ""
                    LogAccum = MamuteGui_AppendLog(G_Log, LogAccum,
                      MamuteXm_FormatAddr(LineStartAddr, @CurTarget) + "  " + LSet(MamuteXm_LastLogText, 20, " ") + Line)
                  Else
                    LogAccum = MamuteGui_AppendLog(G_Log, LogAccum, "-> " + MamuteXm_FormatAddr(CurAddr, @CurTarget))
                  EndIf
                  SetGadgetText(G_Prompt, MamuteXm_FormatAddr(CurAddr, @CurTarget) + ">")
                EndIf
              Else
                LogAccum = MamuteGui_AppendLog(G_Log, LogAccum, "?" + MamuteXm_LastError)
              EndIf
            EndIf

          Case #MamuteXm_UpShortcut
            Protected HCount.i = ListSize(LineHist())
            If HCount > 0
              If HistPos = -1
                HistPos = HCount - 1
              ElseIf HistPos > 0
                HistPos - 1
              EndIf
              SelectElement(LineHist(), HistPos)
              SetGadgetText(G_Input, LineHist())
            EndIf

          Case #MamuteXm_DownShortcut
            If HistPos <> -1
              If HistPos < ListSize(LineHist()) - 1
                HistPos + 1
                SelectElement(LineHist(), HistPos)
                SetGadgetText(G_Input, LineHist())
              Else
                HistPos = -1
                SetGadgetText(G_Input, "")
              EndIf
            EndIf

          Case #MamuteXm_EscShortcut
            Quit = #True
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
  CopyStructure(@CurTarget, *Target, MamuteSxTarget)
  ProcedureReturn CurAddr
EndProcedure
