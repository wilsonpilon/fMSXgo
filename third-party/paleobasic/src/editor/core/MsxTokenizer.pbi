;
; ------------------------------------------------------------
;  Apelido interno: Compsognato (tema pre-historico do projeto, ver README.md)
;  MSX Basic Tokenizer (nativo)
;  Converte MSX-BASIC classico em ASCII (com numeros de linha)
;  para o formato binario tokenizado (.bmx) que o MSX carrega.
;
;  Port fiel de badig/msx/msxbatoken/msxbatoken.py (MSX Basic
;  Tokenizer, parte do Basic Dignified Suite, Fred Rique/farique).
;  A tabela TOKENS e a ordem de casamento sao copiadas exatamente
;  do original: a ordem importa (ex.: "ERROR" antes de "ERR") para
;  o casamento "maior prefixo primeiro" funcionar igual ao MSX real.
;  Ver docs/SPEC.md modulo 11 e docs/reference/*.md para a
;  especificacao completa do formato.
; ------------------------------------------------------------
;

EnableExplicit

;- ------------------------------------------------------------
;- Tabela de tokens (comando -> bytes hex), ordem original preservada
;- ------------------------------------------------------------

DataSection
  Tok_TokenData:
  Data.s ">", "ee",     "PAINT", "bf",   "=", "ef",      "ERROR", "a6",   "ERR", "e2"
  Data.s "<", "f0",      "+", "f1",      "FIELD", "b1",   "PLAY", "c1",   "-", "f2"
  Data.s "FILES", "b7",  "POINT", "ed",  "*", "f3",       "POKE", "98",   "/", "f4"
  Data.s "FN", "de",     "^", "f5",      "FOR", "82",     "PRESET", "c3", "\", "fc"
  Data.s "PRINT", "91",  "?", "91",      "PSET", "c2",    "AND", "f6",   "GET", "b2"
  Data.s "PUT", "b3",    "GOSUB", "8d",  "READ", "87",    "GOTO", "89",  "ATTR$", "e9"
  Data.s "RENUM", "aa",  "AUTO", "a9",   "IF", "8b",      "RESTORE", "8c", "BASE", "c9"
  Data.s "IMP", "fa",    "RESUME", "a7", "BEEP", "c0",    "INKEY$", "ec", "RETURN", "8e"
  Data.s "BLOAD", "cf",  "INPUT", "85",  "BSAVE", "d0",   "INSTR", "e5", "RSET", "b9"
  Data.s "CALL", "ca",   "_", "5f",      "RUN", "8a",     "IPL", "d5",   "SAVE", "ba"
  Data.s "KEY", "cc",    "SCREEN", "c5", "KILL", "d4",    "SET", "d2",  "CIRCLE", "bc"
  Data.s "CLEAR", "92",  "CLOAD", "9b",  "LET", "88",     "SOUND", "c4", "CLOSE", "b4"
  Data.s "LFILES", "bb", "CLS", "9f",    "LINE", "af",    "SPC(", "df", "CMD", "d7"
  Data.s "LIST", "93",   "SPRITE", "c7", "COLOR", "bd",   "LLIST", "9e", "CONT", "99"
  Data.s "LOAD", "b5",   "STEP", "dc",   "COPY", "d6",    "LOCATE", "d8", "STOP", "90"
  Data.s "CSAVE", "9a",  "CSRLIN", "e8", "STRING$", "e3", "LPRINT", "9d", "SWAP", "a4"
  Data.s "LSET", "b8",   "TAB(", "db",   "MAX", "cd",     "DATA", "84",  "MERGE", "b6"
  Data.s "THEN", "da",   "TIME", "cb",   "TO", "d9",      "DEFDBL", "ae", "DEFINT", "ac"
  Data.s "DEFSTR", "ab", "TROFF", "a3",  "DEFSNG", "ad",  "TRON", "a2",  "DEF", "97"
  Data.s "MOD", "fb",    "USING", "e4",  "DELETE", "a8",  "MOTOR", "ce", "USR", "dd"
  Data.s "DIM", "86",    "NAME", "d3",   "DRAW", "be",    "NEW", "94",  "VARPTR", "e7"
  Data.s "NEXT", "83",   "VDP", "c8",    "DSKI$", "ea",   "NOT", "e0",  "DSKO$", "d1"
  Data.s "VPOKE", "c6",  "OFF", "eb",    "WAIT", "96",    "END", "81",  "ON", "95"
  Data.s "WIDTH", "a0",  "OPEN", "b0",   "XOR", "f8",     "EQV", "f9",  "OR", "f7"
  Data.s "ERASE", "a5",  "OUT", "9c",    "ERL", "e1",     "REM", "8f"
  Data.s "PDL", "ffa4",  "EXP", "ff8b",  "PEEK", "ff97",  "FIX", "ffa1", "POS", "ff91"
  Data.s "FPOS", "ffa7", "ABS", "ff86",  "FRE", "ff8f",   "ASC", "ff95", "ATN", "ff8e"
  Data.s "HEX$", "ff9b", "BIN$", "ff9d", "INP", "ff90",   "RIGHT$", "ff82", "RND", "ff88"
  Data.s "INT", "ff85",  "CDBL", "ffa0", "CHR$", "ff96",  "CINT", "ff9e", "LEFT$", "ff81"
  Data.s "SGN", "ff84",  "LEN", "ff92",  "SIN", "ff89",   "SPACE$", "ff99", "SQR", "ff87"
  Data.s "LOC(", "ffac28", "STICK", "ffa2", "COS", "ff8c", "LOF", "ffad", "STR$", "ff93"
  Data.s "CSNG", "ff9f", "LOG", "ff8a",  "STRIG", "ffa3", "LPOS", "ff9c", "CVD", "ffaa"
  Data.s "CVI", "ffa8",  "CVS", "ffa9",  "TAN", "ff8d",   "MID$", "ff83", "MKD$", "ffb0"
  Data.s "MKI$", "ffae", "MKS$", "ffaf", "VAL", "ff94",   "DSKF", "ffa6", "VPEEK", "ff98"
  Data.s "OCT$", "ff9a", "EOF", "ffab", "PAD", "ffa5"
  Data.s "'", "3a8fe6", "ELSE", "3aa1", "AS", "4153"
  Data.s "@@END@@", ""
EndDataSection

Global Dim Tok_Cmd.s(200)
Global Dim Tok_Hex.s(200)
Global Tok_Count.i

Global NewMap Tok_JumpSet.b()

Global Tok_HasError.b
Global Tok_ErrorMsg.s
Global Tok_ErrorLine.i

;- ------------------------------------------------------------
;- Inicializacao
;- ------------------------------------------------------------

Procedure Tok_InitTables()
  Protected cmd.s, hx.s, n.i

  If Tok_Count > 0
    ProcedureReturn ; ja inicializado
  EndIf

  Restore Tok_TokenData
  n = 0
  Repeat
    Read.s cmd
    Read.s hx
    If cmd = "@@END@@"
      Break
    EndIf
    Tok_Cmd(n) = cmd
    Tok_Hex(n) = hx
    n + 1
  ForEver
  Tok_Count = n

  ; JUMPS: instrucoes seguidas de numero(s) de linha alvo
  Tok_JumpSet("RESTORE") = #True
  Tok_JumpSet("AUTO") = #True
  Tok_JumpSet("RENUM") = #True
  Tok_JumpSet("DELETE") = #True
  Tok_JumpSet("RESUME") = #True
  Tok_JumpSet("ERL") = #True
  Tok_JumpSet("ELSE") = #True
  Tok_JumpSet("RUN") = #True
  Tok_JumpSet("LIST") = #True
  Tok_JumpSet("LLIST") = #True
  Tok_JumpSet("GOTO") = #True
  Tok_JumpSet("RETURN") = #True
  Tok_JumpSet("THEN") = #True
  Tok_JumpSet("GOSUB") = #True
EndProcedure

;- ------------------------------------------------------------
;- Helpers de caractere / string
;- ------------------------------------------------------------

Procedure.b Tok_IsDigit(C.s)
  ProcedureReturn Bool(C >= "0" And C <= "9")
EndProcedure

Procedure.b Tok_IsUpperAlpha(C.s)
  ProcedureReturn Bool(C >= "A" And C <= "Z")
EndProcedure

; Remove zeros a esquerda mantendo pelo menos um digito (equivalente a str(int(x)) para uma string so de digitos)
Procedure.s Tok_StripLeadingZeros(S.s)
  Protected i.i = 1
  If S = ""
    ProcedureReturn "0"
  EndIf
  While i < Len(S) And Mid(S, i, 1) = "0"
    i + 1
  Wend
  ProcedureReturn Mid(S, i, Len(S) - i + 1)
EndProcedure

; Compara dois numeros representados como strings de digitos (sem zeros a esquerda, sem sinal)
; Retorna -1 se A<B, 0 se A=B, 1 se A>B
Procedure.i Tok_CompareDigitStrings(A.s, B.s)
  If Len(A) <> Len(B)
    If Len(A) < Len(B)
      ProcedureReturn -1
    Else
      ProcedureReturn 1
    EndIf
  EndIf
  If A < B
    ProcedureReturn -1
  ElseIf A > B
    ProcedureReturn 1
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure.b Tok_DigitStrLE(A.s, B.s)
  ProcedureReturn Bool(Tok_CompareDigitStrings(A, B) <= 0)
EndProcedure

Procedure.b Tok_DigitStrGE(A.s, B.s)
  ProcedureReturn Bool(Tok_CompareDigitStrings(A, B) >= 0)
EndProcedure

Procedure Tok_Fail(LineNum.i, Msg.s)
  If Not Tok_HasError
    Tok_HasError = #True
    Tok_ErrorMsg = Msg
    Tok_ErrorLine = LineNum
  EndIf
EndProcedure

; Um byte como 2 digitos hex
Procedure.s Tok_ByteHex(V.i)
  ProcedureReturn RSet(Hex(V & $FF, #PB_Byte), 2, "0")
EndProcedure

; 16 bits como 2 bytes little-endian (4 digitos hex: baixo, alto)
Procedure.s Tok_Word16LE(V.i)
  ProcedureReturn Tok_ByteHex(V) + Tok_ByteHex(V >> 8)
EndProcedure

;- ------------------------------------------------------------
;- Codificacao de numeros em ponto flutuante (single/double)
;- Formato MSX: [header][precisao][digitos BCD, 2 por byte]
;- header = 1d (single) ou 1f (double)
;- precisao = 0x40 + numero de digitos inteiros (ou calculo especial se |x|<1)
;- ------------------------------------------------------------

; IntPart/FracDigits/OrigIntPart = ver Tok_ScanNumber. NumberStr = IntPart+FracDigits concatenados (sem ponto).
; Retorna o hex do literal e atualiza *OutIntPart (equivalente ao "nugget_integer" que a Python devolve,
; usado para o calculo de quantos caracteres foram consumidos da linha fonte).
Procedure.s Tok_ParseSgnDbl(Header.s, Precision.i, IntPart.s, FracDigits.s, OrigIntPart.s, NumberStr.s, *OutIntPart.String)
  Protected stripped.s, hexaPrecision.s, cropped.s, roundDigit.i, croppedNum.s
  Protected zerosTrimmed.s, leadZeroCount.i

  *OutIntPart\s = IntPart

  stripped = Tok_StripLeadingZeros(IntPart)
  If stripped = "0" And IntPart <> "0" ; equivalente a lstrip('0') == '' (todo zero ou vazio)
    stripped = ""
  EndIf
  If IntPart = ""
    stripped = ""
  EndIf

  If stripped = ""
    ; parte inteira e zero/ausente -> numero < 1 (ex: 0.005) ou realmente zero
    If FracDigits = "" Or Val(RTrim(Mid(FracDigits, 2), "0") + "0") = 0
      hexaPrecision = "00"
    Else
      *OutIntPart\s = OrigIntPart
      If Mid(FracDigits, 2, 1) = "0"
        zerosTrimmed = RTrim(Mid(FracDigits, 2), "0")
        leadZeroCount = Len(Mid(FracDigits, 2)) - Len(zerosTrimmed)
        hexaPrecision = Tok_ByteHex(64 - leadZeroCount)
      Else
        hexaPrecision = "40"
      EndIf
    EndIf
  Else
    hexaPrecision = Tok_ByteHex(Len(stripped) + 64)
  EndIf

  cropped = Tok_StripLeadingZeros(NumberStr)

  If Len(cropped) > Precision
    roundDigit = Val(Mid(cropped, Precision + 1, 1))
  Else
    roundDigit = 0
  EndIf

  croppedNum = Left(cropped, Precision)
  If Len(croppedNum) = 0
    croppedNum = "0"
  EndIf
  If roundDigit >= 5
    croppedNum = Str(Val(croppedNum) + 1)
  EndIf

  ProcedureReturn Header + hexaPrecision + croppedNum
EndProcedure

;- ------------------------------------------------------------
;- Parsing de um literal numerico a partir da posicao atual da linha
;- Retorna o hex do token e escreve em *Consumed quantos caracteres
;- (da linha original, sem CRLF) foram consumidos.
;- ------------------------------------------------------------

Procedure.s Tok_ScanNumber(Remaining.s, LineNum.i, *Consumed.Integer)
  Protected i.i, j.i
  Protected origIntPart.s, intPart.s, fracDigits.s, signalStr.s, notifConfirm.s
  Protected numberStr.s, isInt.b, isFloat.b
  Protected hexa.s, outIntWrap.String, tmpIntPart.s
  Protected expSign.s, expDigitsStr.s, expStart.i

  i = 1
  While i <= Len(Remaining) And Tok_IsDigit(Mid(Remaining, i, 1))
    i + 1
  Wend
  origIntPart = Left(Remaining, i - 1)
  intPart = origIntPart

  If Mid(Remaining, i, 1) = "."
    j = i + 1
    While j <= Len(Remaining) And Tok_IsDigit(Mid(Remaining, j, 1))
      j + 1
    Wend
    fracDigits = "." + Mid(Remaining, i + 1, j - (i + 1))
    If intPart = ""
      intPart = "0"
    EndIf
    numberStr = intPart + Mid(fracDigits, 2)
    signalStr = Mid(Remaining, j, 1)
    notifConfirm = Mid(Remaining, j + 1, 1)
    isFloat = #True
  Else
    numberStr = intPart
    signalStr = Mid(Remaining, i, 1)
    notifConfirm = Mid(Remaining, i + 1, 1)
  EndIf

  isInt = #False

  If signalStr = "%"
    numberStr = intPart
    isInt = #True
    If Tok_DigitStrGE(Tok_StripLeadingZeros(numberStr), "32768")
      Tok_Fail(LineNum, "Integer overflow: " + numberStr)
      ProcedureReturn ""
    EndIf
  ElseIf signalStr <> "%" And signalStr <> "!" And signalStr <> "#" And Not ((LCase(signalStr) = "e" Or LCase(signalStr) = "d") And (notifConfirm = "-" Or notifConfirm = "+"))
    signalStr = ""
    If fracDigits = ""
      isInt = #True
    EndIf
  EndIf

  Protected strippedNum.s = Tok_StripLeadingZeros(numberStr)
  Protected consumedIntPart.s = intPart

  Protected isSciNotation.b = Bool((LCase(signalStr) = "e" Or LCase(signalStr) = "d") And (notifConfirm = "-" Or notifConfirm = "+"))
  Protected isSingleRange.b = Bool((Tok_DigitStrGE(strippedNum, "32768") And Tok_DigitStrLE(strippedNum, "999999") And signalStr <> "#") Or (signalStr = "!") Or (Not isInt And Tok_DigitStrLE(strippedNum, "999999") And signalStr <> "#"))
  Protected isDoubleRange.b = Bool(Tok_DigitStrGE(strippedNum, "1000000") Or signalStr = "#" Or Not isInt)
  Protected isShortInt.b = Bool(Tok_DigitStrGE(strippedNum, "0") And Tok_DigitStrLE(strippedNum, "9"))
  Protected isByteInt.b = Bool(Tok_DigitStrGE(strippedNum, "10") And Tok_DigitStrLE(strippedNum, "255"))
  Protected isWordInt.b = Bool(Tok_DigitStrGE(strippedNum, "256") And Tok_DigitStrLE(strippedNum, "32767"))

  If isSciNotation
    ; notacao cientifica: reaproveita o motor de single/double aplicando o deslocamento do expoente
    ; posicao logo apos o sinal +/- do expoente:
    expStart = j + 2
    expDigitsStr = ""
    Protected k.i = expStart
    While k <= Len(Remaining) And Tok_IsDigit(Mid(Remaining, k, 1))
      expDigitsStr + Mid(Remaining, k, 1)
      k + 1
    Wend

    Protected expVal.i = Val(expDigitsStr)
    If notifConfirm = "-"
      expVal = -expVal
    EndIf

    Protected intDigitsNoZero.s = Tok_StripLeadingZeros(intPart)
    If intDigitsNoZero = "0" : intDigitsNoZero = "" : EndIf
    Protected expSize.i = Len(intDigitsNoZero) + expVal
    Protected manSize.i = expSize - Len(Mid(fracDigits, 2)) - Len(intDigitsNoZero)

    If expSize > 63 Or expSize < -64
      Tok_Fail(LineNum, "Float overflow: " + numberStr)
      ProcedureReturn ""
    EndIf

    Protected fractionalDigitsOut.i
    If manSize < 0
      fractionalDigitsOut = Abs(manSize)
    Else
      fractionalDigitsOut = 0
    EndIf

    ; desloca o ponto decimal por manSize casas (equivalente a * 10^manSize) trabalhando so com digitos
    Protected shiftedDigits.s = intDigitsNoZero + Mid(fracDigits, 2)
    If shiftedDigits = "" : shiftedDigits = "0" : EndIf
    Protected shiftedNum.s
    If fractionalDigitsOut > 0
      ; numero fracionario resultante: preenche com zeros a esquerda se necessario e trunca/arredonda
      Protected padded.s = shiftedDigits
      While Len(padded) <= fractionalDigitsOut
        padded = "0" + padded
      Wend
      shiftedNum = Left(padded, Len(padded) - fractionalDigitsOut)
    Else
      shiftedNum = shiftedDigits + RSet("", manSize, "0")
    EndIf

    Protected notationInteger.s = Tok_StripLeadingZeros(shiftedNum)
    Protected notationNumber.s = shiftedNum

    If LCase(signalStr) = "e" And Len(Tok_StripLeadingZeros(numberStr)) < 7
      hexa = Tok_ParseSgnDbl("1d", 6, notationInteger, "", origIntPart, notationNumber, @outIntWrap)
      While Len(hexa) < 10
        hexa + "0"
      Wend
      hexa = Left(hexa, 10)
    Else
      hexa = Tok_ParseSgnDbl("1f", 14, notationInteger, "", origIntPart, notationNumber, @outIntWrap)
      While Len(hexa) < 18
        hexa + "0"
      Wend
      hexa = Left(hexa, 18)
    EndIf

    consumedIntPart = intPart
    signalStr + Mid(Remaining, j, 1) ; sinal + expoente ja fazem parte de signalStr para calculo de consumo (aprox.)
    *Consumed\i = Len(intPart) + Len(fracDigits) + (k - j)
    ProcedureReturn hexa

  ElseIf isSingleRange

    hexa = Tok_ParseSgnDbl("1d", 6, intPart, fracDigits, origIntPart, numberStr, @outIntWrap)
    While Len(hexa) < 10
      hexa + "0"
    Wend
    hexa = Left(hexa, 10)
    consumedIntPart = outIntWrap\s

  ElseIf isDoubleRange

    hexa = Tok_ParseSgnDbl("1f", 14, intPart, fracDigits, origIntPart, numberStr, @outIntWrap)
    While Len(hexa) < 18
      hexa + "0"
    Wend
    hexa = Left(hexa, 18)
    consumedIntPart = outIntWrap\s

  ElseIf isShortInt
    hexa = Tok_ByteHex(Val(strippedNum) + 17)

  ElseIf isByteInt
    hexa = "0f" + Tok_ByteHex(Val(strippedNum))

  ElseIf isWordInt
    hexa = "1c" + Tok_Word16LE(Val(strippedNum))

  Else
    Tok_Fail(LineNum, "Number too high: " + strippedNum)
    ProcedureReturn ""
  EndIf

  *Consumed\i = Len(consumedIntPart) + Len(fracDigits) + Len(signalStr)
  ProcedureReturn hexa
EndProcedure

;- ------------------------------------------------------------
;- Tokenizacao de uma linha (sem numero de linha, sem CRLF)
;- ------------------------------------------------------------

Procedure.s Tok_TokenizeLineBody(Body.s, LineNum.i)
  Protected out.s, pos.i = 1
  Protected matched.b, ti.i, cmd.s, hx.s, cmdLen.i
  Protected c.s, c2.s
  Protected inDataLiteral.b = #False
  ; UCase(Body) calculado uma vez so fora do loop, em vez de um Mid() do
  ; restante da linha + UCase() a cada posicao (O(n) por posicao, O(n^2) no
  ; total pra linha inteira) - olhar so os cmdLen caracteres necessarios em
  ; UpperBody, ja maiusculo, e O(1) por checagem de palavra-chave.
  Protected UpperBody.s = UCase(Body)
  Protected BodyLen.i = Len(Body)

  While pos <= BodyLen
    matched = #False

    For ti = 0 To Tok_Count - 1
      cmd = Tok_Cmd(ti)
      cmdLen = Len(cmd)
      If cmdLen <= BodyLen - pos + 1 And Mid(UpperBody, pos, cmdLen) = cmd
        hx = Tok_Hex(ti)
        out + hx
        pos + cmdLen
        matched = #True

        If cmd = "AS"
          ; numero de arquivo (1-2 digitos) apos AS permanece literal (nao tokenizado como numero)
          Protected asStart.i = pos, asSpaces.i = 0, asDigits.s
          While pos <= Len(Body) And Mid(Body, pos, 1) = " "
            asSpaces + 1
            pos + 1
          Wend
          While pos <= Len(Body) And Tok_IsDigit(Mid(Body, pos, 1)) And Len(asDigits) < 2
            asDigits + Mid(Body, pos, 1)
            pos + 1
          Wend
          If asDigits <> ""
            Protected asi.i
            For asi = 1 To asSpaces
              out + "20"
            Next
            For asi = 1 To Len(asDigits)
              out + Tok_ByteHex(Asc(Mid(asDigits, asi, 1)))
            Next
          Else
            pos = asStart
          EndIf
        EndIf

        If FindMapElement(Tok_JumpSet(), cmd)
          Repeat
            Protected jSpaces.i = 0, jStart.i = pos
            While pos <= Len(Body) And Mid(Body, pos, 1) = " "
              jSpaces + 1
              pos + 1
            Wend
            If pos <= Len(Body) And Tok_IsDigit(Mid(Body, pos, 1))
              Protected jDigits.s = ""
              While pos <= Len(Body) And Tok_IsDigit(Mid(Body, pos, 1))
                jDigits + Mid(Body, pos, 1)
                pos + 1
              Wend
              If Val(jDigits) > 65529
                Tok_Fail(LineNum, "Line number jump too high: " + jDigits)
                ProcedureReturn ""
              EndIf
              Protected jsi.i
              For jsi = 1 To jSpaces
                out + "20"
              Next
              out + "0e" + Tok_Word16LE(Val(jDigits))
            ElseIf pos <= Len(Body) And Mid(Body, pos, 1) = ","
              Protected commaCount.i = 0
              While pos <= Len(Body) And Mid(Body, pos, 1) = ","
                commaCount + 1
                pos + 1
              Wend
              Protected csi.i
              For csi = 1 To jSpaces
                out + "20"
              Next
              For csi = 1 To commaCount
                out + "2c"
              Next
            Else
              pos = jStart
              Break
            EndIf
          ForEver
        EndIf

        If cmd = "DATA" Or cmd = "REM" Or cmd = "'" Or cmd = "CALL" Or cmd = "_"
          Protected litChar.s
          Repeat
            If pos > Len(Body)
              Break
            EndIf
            litChar = Mid(Body, pos, 1)
            If cmd = "CALL" Or cmd = "_"
              litChar = UCase(litChar)
            EndIf
            out + Tok_ByteHex(Asc(litChar))
            pos + 1

            Protected stopLiteral.b = Bool(pos > Len(Body) Or (cmd = "DATA" And Mid(Body, pos, 1) = ":") Or (cmd = "_" And (Mid(Body, pos, 1) = ":" Or Mid(Body, pos, 1) = "(")) Or (cmd = "CALL" And (Mid(Body, pos, 1) = ":" Or Mid(Body, pos, 1) = "(")))
            If stopLiteral
              Break
            EndIf
          ForEver
        EndIf

        Break
      EndIf
    Next ti

    If matched
      Continue
    EndIf

    c = Mid(Body, pos, 1)

    If Tok_IsDigit(c) Or (c = "." And Tok_IsDigit(Mid(Body, pos + 1, 1)))
      Protected consumed.i
      Protected numHex.s = Tok_ScanNumber(Mid(Body, pos, Len(Body) - pos + 1), LineNum, @consumed)
      If Tok_HasError
        ProcedureReturn ""
      EndIf
      out + numHex
      pos + consumed
      Continue
    EndIf

    If c = "&"
      c2 = UCase(Mid(Body, pos + 1, 1))
      If c2 = "H"
        Protected hStart.i = pos + 2, hDigits.s = ""
        While hStart <= Len(Body) And ((Mid(Body, hStart, 1) >= "0" And Mid(Body, hStart, 1) <= "9") Or (LCase(Mid(Body, hStart, 1)) >= "a" And LCase(Mid(Body, hStart, 1)) <= "f"))
          hDigits + Mid(Body, hStart, 1)
          hStart + 1
        Wend
        Protected hVal.i
        If hDigits = ""
          hVal = 0
        Else
          hVal = Val("$" + hDigits)
          If hVal > 65535
            Tok_Fail(LineNum, "Number overflow: " + hDigits)
            ProcedureReturn ""
          EndIf
        EndIf
        out + "0c" + Tok_Word16LE(hVal)
        pos = pos + 2 + Len(hDigits)
        Continue
      ElseIf c2 = "O"
        Protected oStart.i = pos + 2, oDigits.s = ""
        While oStart <= Len(Body) And Mid(Body, oStart, 1) >= "0" And Mid(Body, oStart, 1) <= "7"
          oDigits + Mid(Body, oStart, 1)
          oStart + 1
        Wend
        Protected oVal.i
        If oDigits = ""
          oVal = 0
        Else
          oVal = Val("%" + ReplaceString(Str(0), "0", "")) ; placeholder, calculado abaixo
          oVal = 0
          Protected oi.i
          For oi = 1 To Len(oDigits)
            oVal = oVal * 8 + Val(Mid(oDigits, oi, 1))
          Next
          If oVal > 65535
            Tok_Fail(LineNum, "Number overflow: " + oDigits)
            ProcedureReturn ""
          EndIf
        EndIf
        out + "0b" + Tok_Word16LE(oVal)
        pos = pos + 2 + Len(oDigits)
        Continue
      ElseIf c2 = "B"
        Protected bStart.i = pos + 2, bDigits.s = ""
        While bStart <= Len(Body) And (Mid(Body, bStart, 1) = "0" Or Mid(Body, bStart, 1) = "1")
          bDigits + Mid(Body, bStart, 1)
          bStart + 1
        Wend
        out + "2642"
        Protected bi.i
        For bi = 1 To Len(bDigits)
          out + Tok_ByteHex(Asc(Mid(bDigits, bi, 1)))
        Next
        pos = pos + 2 + Len(bDigits)
        Continue
      Else
        out + Tok_ByteHex(Asc("&"))
        pos + 1
        Continue
      EndIf
    EndIf

    If c = Chr(34) ; aspas
      Protected numQuotes.i = 0
      Repeat
        If Mid(Body, pos, 1) = Chr(34)
          numQuotes + 1
        EndIf
        out + Tok_ByteHex(Asc(Mid(Body, pos, 1)))
        pos + 1
        If numQuotes > 1 Or pos > Len(Body)
          Break
        EndIf
      ForEver
      Continue
    EndIf

    If Asc(c) >= 65 And Asc(c) <= 90 Or Tok_IsUpperAlpha(UCase(c))
      Protected isVar.b = #True
      Repeat
        c = UCase(Mid(Body, pos, 1))
        For ti = 0 To Tok_Count - 1
          cmd = Tok_Cmd(ti)
          cmdLen = Len(cmd)
          If cmdLen <= (Len(Body) - pos + 1) And UCase(Mid(Body, pos, cmdLen)) = cmd
            isVar = #False
          EndIf
        Next ti

        If (Asc(c) < 48 Or Asc(c) > 57) And (Asc(c) < 65 Or Asc(c) > 90) Or Not isVar
          isVar = #False
          Break
        EndIf
        out + Tok_ByteHex(Asc(c))
        pos + 1
      ForEver
      Continue
    EndIf

    out + Tok_ByteHex(Asc(UCase(c)))
    pos + 1
  Wend

  ProcedureReturn out
EndProcedure

;- ------------------------------------------------------------
;- Tokenizacao do programa inteiro (texto ASCII com numeros de linha)
;- Retorna a string hex do arquivo .bmx completo, ou "" em erro
;- (Tok_HasError / Tok_ErrorMsg / Tok_ErrorLine ficam preenchidos)
;- ------------------------------------------------------------

#Tok_Base = $8001

Procedure.s Tok_Tokenize(SourceText.s)
  Protected text.s, lineCount.i, li.i
  Protected lineOrder.i = 0, lineAddress.i = #Tok_Base
  Protected out.s = "ff"
  Protected raw.s, trimmed.s, lineNumStr.s, body.s, bodyHex.s
  Protected digStart.i, digEnd.i
  Protected lineNumber.i

  Tok_InitTables()
  Tok_HasError = #False
  Tok_ErrorMsg = ""
  Tok_ErrorLine = 0

  text = ReplaceString(SourceText, Chr(13) + Chr(10), Chr(10))
  text = ReplaceString(text, Chr(13), Chr(10))
  text = ReplaceString(text, Chr(9), "    ") ; Trim() nao remove tabs, so espacos
  lineCount = CountString(text, Chr(10)) + 1

  For li = 1 To lineCount
    raw = StringField(text, li, Chr(10))
    trimmed = Trim(raw)

    If trimmed = ""
      Continue
    EndIf

    If Trim(RemoveString(trimmed, " ")) <> "" And Len(RemoveString(trimmed, "0123456789")) = 0
      ; linha e so um numero, sem conteudo -> ignora (mesma regra do carregador original)
      Continue
    EndIf

    If Not Tok_IsDigit(Left(trimmed, 1))
      If Asc(Left(trimmed, 1)) = 26
        Continue
      EndIf
      Tok_Fail(li, "Line not starting with number.")
      Break
    EndIf

    digStart = 1
    digEnd = 1
    While digEnd <= Len(trimmed) And Tok_IsDigit(Mid(trimmed, digEnd, 1))
      digEnd + 1
    Wend
    lineNumStr = Mid(trimmed, digStart, digEnd - digStart)
    lineNumber = Val(lineNumStr)

    If lineNumber <= lineOrder
      Tok_Fail(li, "Line number out of order: " + lineNumStr)
      Break
    EndIf
    If lineNumber > 65529
      Tok_Fail(li, "Line number too high: " + lineNumStr)
      Break
    EndIf
    lineOrder = lineNumber

    body = Mid(trimmed, digEnd, Len(trimmed) - digEnd + 1)
    If Left(body, 1) = " "
      body = Mid(body, 2)
    EndIf

    bodyHex = Tok_TokenizeLineBody(body, li)
    If Tok_HasError
      Break
    EndIf

    Protected lineCompiled.s = Tok_Word16LE(lineNumber) + bodyHex
    lineAddress = lineAddress + (Len(lineCompiled) + 6) / 2
    lineCompiled = Tok_Word16LE(lineAddress) + lineCompiled + "00"
    out + lineCompiled
  Next li

  If Tok_HasError
    ProcedureReturn ""
  EndIf

  out + "0000"
  ProcedureReturn out
EndProcedure

;- ------------------------------------------------------------
;- Converte a string hex resultante em bytes e salva em disco
;- ------------------------------------------------------------

Procedure.b Tok_SaveHexAsBinary(HexStr.s, Path.s)
  Protected fileNum.i, i.i, byteVal.i
  Protected *buffer

  fileNum = CreateFile(#PB_Any, Path)
  If Not fileNum
    ProcedureReturn #False
  EndIf

  *buffer = AllocateMemory(Len(HexStr) / 2)
  If Not *buffer
    CloseFile(fileNum)
    ProcedureReturn #False
  EndIf

  For i = 1 To Len(HexStr) Step 2
    byteVal = Val("$" + Mid(HexStr, i, 2))
    PokeB(*buffer + (i - 1) / 2, byteVal)
  Next i

  WriteData(fileNum, *buffer, Len(HexStr) / 2)
  CloseFile(fileNum)
  FreeMemory(*buffer)

  ProcedureReturn #True
EndProcedure

;- ------------------------------------------------------------
;- Renumeracao de ASCII classico ("Criar arquivo .BAS")
;- ------------------------------------------------------------
;- Comandos cujo numero de linha alvo e de fato uma referencia para outra
;- linha do PROPRIO programa (por isso seguro remapear via OldToNew) -
;- subconjunto de Tok_JumpSet: RENUM/AUTO tem o 1o argumento como um numero
;- NOVO de destino (nao uma referencia existente) e DELETE/LIST/LLIST raramente
;- aparecem embutidos na logica de um programa (sao comandos de modo direto);
;- por seguranca esses ficam de fora do remapeamento (o numero e copiado como
;- esta) para nao arriscar reescrever um argumento que nao e uma referencia.
Procedure.b Tok_IsRenumberTargetCmd(Cmd.s)
  ProcedureReturn Bool(Cmd = "GOTO" Or Cmd = "GOSUB" Or Cmd = "THEN" Or Cmd = "ELSE" Or
                        Cmd = "RESTORE" Or Cmd = "RESUME" Or Cmd = "RETURN" Or Cmd = "RUN")
EndProcedure

; Reconstroi uma linha de ASCII classico (sem numero de linha) trocando os
; numeros-alvo de GOTO/GOSUB/THEN/ELSE/RESTORE/RESUME/RETURN/RUN (e as listas
; separadas por virgula de ON...GOTO/ON...GOSUB) pelo novo numero mapeado em
; OldToNew(), e colapsando espacos redundantes fora de literais. Espelha
; deliberadamente o mesmo fluxo de casamento de comandos/literais/numeros de
; Tok_TokenizeLineBody (incluindo o "quirk" de identificadores que comecam com
; prefixo de palavra-chave, tipo TOTAL -> TO + TAL) para que a decisao de "isto
; e um alvo de jump" seja identica a que o tokenizador vai tomar depois -
; reimplementar essa deteccao do zero arriscaria remapear o numero errado ou
; deixar um GOTO sem corrigir.
Procedure.s Tok_RenumberLineBody(Body.s, LineNum.i, Map OldToNew.i())
  Protected out.s, pos.i = 1
  Protected matched.b, ti.i, cmd.s, cmdLen.i
  Protected c.s, c2.s
  ; Mesma otimizacao de Tok_TokenizeLineBody acima: UCase(Body) uma vez so
  ; fora do loop, em vez de recomputar o restante da linha + UCase() a cada
  ; posicao (O(n^2) no total pra linha inteira).
  Protected UpperBody.s = UCase(Body)
  Protected BodyLen.i = Len(Body)

  While pos <= BodyLen
    matched = #False

    If Mid(Body, pos, 1) = " "
      While pos <= BodyLen And Mid(Body, pos, 1) = " "
        pos + 1
      Wend
      out + " "
      Continue
    EndIf

    For ti = 0 To Tok_Count - 1
      cmd = Tok_Cmd(ti)
      cmdLen = Len(cmd)
      If cmdLen <= BodyLen - pos + 1 And Mid(UpperBody, pos, cmdLen) = cmd
        out + cmd
        pos + cmdLen
        matched = #True

        If cmd = "AS"
          ; numero de arquivo (1-2 digitos) apos AS permanece literal
          Protected asStart.i = pos, asSpaces.i = 0, asDigits.s = ""
          While pos <= Len(Body) And Mid(Body, pos, 1) = " "
            asSpaces + 1
            pos + 1
          Wend
          While pos <= Len(Body) And Tok_IsDigit(Mid(Body, pos, 1)) And Len(asDigits) < 2
            asDigits + Mid(Body, pos, 1)
            pos + 1
          Wend
          If asDigits <> ""
            If asSpaces > 0 : out + " " : EndIf
            out + asDigits
          Else
            pos = asStart
          EndIf
        EndIf

        If FindMapElement(Tok_JumpSet(), cmd)
          Repeat
            Protected jSpaces.i = 0, jStart.i = pos
            While pos <= Len(Body) And Mid(Body, pos, 1) = " "
              jSpaces + 1
              pos + 1
            Wend
            If pos <= Len(Body) And Tok_IsDigit(Mid(Body, pos, 1))
              Protected jDigits.s = ""
              While pos <= Len(Body) And Tok_IsDigit(Mid(Body, pos, 1))
                jDigits + Mid(Body, pos, 1)
                pos + 1
              Wend
              If jSpaces > 0 : out + " " : EndIf
              If Tok_IsRenumberTargetCmd(cmd) And Val(jDigits) <> 0
                ; 0 nao e remapeado: e o sentinela de "ON ERROR GOTO 0"/
                ; "ON ERROR GOSUB 0" (desliga o tratamento de erro), nao uma
                ; referencia a uma linha real - confirmado contra caso real em
                ; sample/teste.dmx ("on error goto 0"). Nunca colide com um
                ; numero remapeado de verdade (NewStart minimo e 1).
                Protected key.s = Str(Val(jDigits))
                If Not FindMapElement(OldToNew(), key)
                  Tok_Fail(LineNum, cmd + " para linha inexistente: " + jDigits)
                  ProcedureReturn ""
                EndIf
                out + Str(OldToNew())
              Else
                out + jDigits
              EndIf
            ElseIf pos <= Len(Body) And Mid(Body, pos, 1) = ","
              Protected commaCount.i = 0
              While pos <= Len(Body) And Mid(Body, pos, 1) = ","
                commaCount + 1
                pos + 1
              Wend
              If jSpaces > 0 : out + " " : EndIf
              Protected csi.i
              For csi = 1 To commaCount
                out + ","
              Next
            Else
              pos = jStart
              Break
            EndIf
          ForEver
        EndIf

        If cmd = "DATA" Or cmd = "REM" Or cmd = "'" Or cmd = "CALL" Or cmd = "_"
          Protected litChar.s
          Repeat
            If pos > Len(Body)
              Break
            EndIf
            litChar = Mid(Body, pos, 1)
            If cmd = "CALL" Or cmd = "_"
              litChar = UCase(litChar)
            EndIf
            out + litChar
            pos + 1

            Protected stopLiteral.b = Bool(pos > Len(Body) Or (cmd = "DATA" And Mid(Body, pos, 1) = ":") Or (cmd = "_" And (Mid(Body, pos, 1) = ":" Or Mid(Body, pos, 1) = "(")) Or (cmd = "CALL" And (Mid(Body, pos, 1) = ":" Or Mid(Body, pos, 1) = "(")))
            If stopLiteral
              Break
            EndIf
          ForEver
        EndIf

        Break
      EndIf
    Next ti

    If Tok_HasError
      ProcedureReturn ""
    EndIf

    If matched
      Continue
    EndIf

    c = Mid(Body, pos, 1)

    If Tok_IsDigit(c) Or (c = "." And Tok_IsDigit(Mid(Body, pos + 1, 1)))
      Protected consumed.i
      Tok_ScanNumber(Mid(Body, pos, Len(Body) - pos + 1), LineNum, @consumed)
      If Tok_HasError
        ProcedureReturn ""
      EndIf
      out + Mid(Body, pos, consumed)
      pos + consumed
      Continue
    EndIf

    If c = "&"
      c2 = UCase(Mid(Body, pos + 1, 1))
      If c2 = "H"
        Protected hStart.i = pos + 2
        While hStart <= Len(Body) And ((Mid(Body, hStart, 1) >= "0" And Mid(Body, hStart, 1) <= "9") Or (LCase(Mid(Body, hStart, 1)) >= "a" And LCase(Mid(Body, hStart, 1)) <= "f"))
          hStart + 1
        Wend
        out + Mid(Body, pos, hStart - pos)
        pos = hStart
        Continue
      ElseIf c2 = "O"
        Protected oStart.i = pos + 2
        While oStart <= Len(Body) And Mid(Body, oStart, 1) >= "0" And Mid(Body, oStart, 1) <= "7"
          oStart + 1
        Wend
        out + Mid(Body, pos, oStart - pos)
        pos = oStart
        Continue
      ElseIf c2 = "B"
        Protected bStart.i = pos + 2
        While bStart <= Len(Body) And (Mid(Body, bStart, 1) = "0" Or Mid(Body, bStart, 1) = "1")
          bStart + 1
        Wend
        out + Mid(Body, pos, bStart - pos)
        pos = bStart
        Continue
      Else
        out + "&"
        pos + 1
        Continue
      EndIf
    EndIf

    If c = Chr(34) ; aspas
      Protected numQuotes.i = 0
      Repeat
        out + Mid(Body, pos, 1)
        If Mid(Body, pos, 1) = Chr(34)
          numQuotes + 1
        EndIf
        pos + 1
        If numQuotes > 1 Or pos > Len(Body)
          Break
        EndIf
      ForEver
      Continue
    EndIf

    If Asc(c) >= 65 And Asc(c) <= 90 Or Tok_IsUpperAlpha(UCase(c))
      Protected isVar.b = #True
      Repeat
        c = UCase(Mid(Body, pos, 1))
        For ti = 0 To Tok_Count - 1
          cmd = Tok_Cmd(ti)
          cmdLen = Len(cmd)
          If cmdLen <= (Len(Body) - pos + 1) And UCase(Mid(Body, pos, cmdLen)) = cmd
            isVar = #False
          EndIf
        Next ti

        If (Asc(c) < 48 Or Asc(c) > 57) And (Asc(c) < 65 Or Asc(c) > 90) Or Not isVar
          isVar = #False
          Break
        EndIf
        out + c
        pos + 1
      ForEver
      Continue
    EndIf

    out + UCase(c)
    pos + 1
  Wend

  ProcedureReturn out
EndProcedure

; Renumera um programa ASCII classico (com numeros de linha reais, nao
; Dignified), corrigindo todos os alvos de GOTO/GOSUB/THEN/ELSE/RESTORE/
; RESUME/RETURN/RUN (inclusive listas ON...GOTO/ON...GOSUB) para apontar para
; os numeros novos. Mesma semantica do comando RENUM real do MSX-BASIC:
; `RENUM [newline][,[oldline][,increment]]`
;   NewStart (newline): numero da nova primeira linha renumerada. Default 1
;     (ao contrario do RENUM real, cujo default e 10 - aqui o padrao segue
;     compacto/orientado a maquina, ver nota abaixo; quem quer o default
;     classico passa NewStart=10).
;   OldLineFrom (oldline): a partir de qual linha ANTIGA comeca a renumeracao
;     - linhas com numero menor que OldLineFrom ficam com o numero ORIGINAL
;     intocado (mapeadas na identidade, old=new, so para o remapeamento de
;     GOTO/GOSUB continuar correto). 0 (default) = renumera o programa
;     inteiro, igual ao "oldline" omitido no RENUM real (usa a primeira linha
;     do programa).
;   NewStep (increment): passo entre os numeros novos. Default 1 (RENUM real
;     usa 10; numeros baixos tokenizam em menos bytes - 0-9 cabem em 1 byte
;     contra 2-4 de numeros maiores, ver Tok_ScanNumber/isShortInt - por isso
;     o padrao aqui e mais compacto que o do RENUM real, que preserva espaco
;     pra inserir linhas manualmente depois, algo que nao faz sentido aqui
;     onde o alvo primario e o .bmx final, nao edicao ao vivo na maquina).
; Retorna "" e preenche Tok_HasError/Tok_ErrorMsg/Tok_ErrorLine em caso de
; erro (mesma convencao de Tok_Tokenize) - inclusive se OldLineFrom cair no
; meio das linhas ja renumeradas de forma a colidir com a numeracao antiga
; preservada (teria que reordenar o programa, RENUM real tambem recusa isso).
Procedure.s Tok_RenumberAscii(SourceText.s, NewStart.i = 1, NewStep.i = 1, OldLineFrom.i = 0)
  Protected text.s, lineCount.i, li.i
  Protected raw.s, trimmed.s, lineNumStr.s, body.s, bodyOut.s
  Protected digEnd.i, lineNumber.i, lineOrder.i = 0
  Protected newNum.i = NewStart
  Protected lastUnrenumbered.i = -1
  Protected renumbering.b = Bool(OldLineFrom <= 0)
  Protected out.s = ""
  NewMap OldToNew.i()

  Tok_InitTables()
  Tok_HasError = #False
  Tok_ErrorMsg = ""
  Tok_ErrorLine = 0

  text = ReplaceString(SourceText, Chr(13) + Chr(10), Chr(10))
  text = ReplaceString(text, Chr(13), Chr(10))
  text = ReplaceString(text, Chr(9), "    ")
  lineCount = CountString(text, Chr(10)) + 1

  ; passe 1: mapeia numero antigo -> novo numero, na ordem do arquivo. Linhas
  ; antes de OldLineFrom (quando informado) mantem seu proprio numero, so
  ; entram no mapa como identidade para o passe 2 conseguir resolver
  ; referencias que apontam pra elas.
  For li = 1 To lineCount
    raw = StringField(text, li, Chr(10))
    trimmed = Trim(raw)
    If trimmed = ""
      Continue
    EndIf
    If Trim(RemoveString(trimmed, " ")) <> "" And Len(RemoveString(trimmed, "0123456789")) = 0
      Continue
    EndIf
    If Not Tok_IsDigit(Left(trimmed, 1))
      If Asc(Left(trimmed, 1)) = 26
        Continue
      EndIf
      Tok_Fail(li, "Line not starting with number.")
      ProcedureReturn ""
    EndIf

    digEnd = 1
    While digEnd <= Len(trimmed) And Tok_IsDigit(Mid(trimmed, digEnd, 1))
      digEnd + 1
    Wend
    lineNumStr = Left(trimmed, digEnd - 1)
    lineNumber = Val(lineNumStr)

    If lineNumber <= lineOrder
      Tok_Fail(li, "Line number out of order: " + lineNumStr)
      ProcedureReturn ""
    EndIf
    If lineNumber > 65529
      Tok_Fail(li, "Line number too high: " + lineNumStr)
      ProcedureReturn ""
    EndIf
    lineOrder = lineNumber

    If Not renumbering And lineNumber >= OldLineFrom
      renumbering = #True
      If newNum <= lastUnrenumbered
        Tok_Fail(li, "Nova numeracao (" + Str(newNum) + ") colide com a numeracao original preservada (ate " + Str(lastUnrenumbered) + ") - use uma linha inicial maior.")
        ProcedureReturn ""
      EndIf
    EndIf

    If renumbering
      If newNum > 65529
        Tok_Fail(li, "Renumeracao ultrapassa 65529 - use um passo/inicio menor.")
        ProcedureReturn ""
      EndIf
      OldToNew(Str(lineNumber)) = newNum
      newNum + NewStep
    Else
      OldToNew(Str(lineNumber)) = lineNumber
      lastUnrenumbered = lineNumber
    EndIf
  Next li

  ; passe 2: reescreve o programa com os novos numeros e os alvos corrigidos
  For li = 1 To lineCount
    raw = StringField(text, li, Chr(10))
    trimmed = Trim(raw)
    If trimmed = ""
      Continue
    EndIf
    If Trim(RemoveString(trimmed, " ")) <> "" And Len(RemoveString(trimmed, "0123456789")) = 0
      Continue
    EndIf
    If Asc(Left(trimmed, 1)) = 26
      Continue
    EndIf

    digEnd = 1
    While digEnd <= Len(trimmed) And Tok_IsDigit(Mid(trimmed, digEnd, 1))
      digEnd + 1
    Wend
    lineNumStr = Left(trimmed, digEnd - 1)
    lineNumber = Val(lineNumStr)

    body = Mid(trimmed, digEnd, Len(trimmed) - digEnd + 1)
    While Left(body, 1) = " "
      body = Mid(body, 2)
    Wend

    bodyOut = Tok_RenumberLineBody(body, li, OldToNew())
    If Tok_HasError
      ProcedureReturn ""
    EndIf

    out + Str(OldToNew(Str(lineNumber))) + " " + Trim(bodyOut) + Chr(13) + Chr(10)
  Next li

  ProcedureReturn out
EndProcedure
