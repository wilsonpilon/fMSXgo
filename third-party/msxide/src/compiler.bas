#Include Once "compiler.bi"
#Include Once "db.bi"

Type KeywordToken
    kw As String
    tokHex As String
    tokData As String
    isJump As Integer
    literalMode As Integer
End Type

Const TOK_LITERAL_NONE = 0
Const TOK_LITERAL_DATA_REM = 1

Dim Shared gKeywords(1 To 256) As KeywordToken
Dim Shared gKeywordCount As Integer
Dim Shared gKeywordInit As Integer

Private Function CompilerDebugLogPath() As String
    Dim p As String = Environ("TEMP")
    If Len(p) = 0 Then p = CurDir()
    If Right(p, 1) <> "\\" And Right(p, 1) <> "/" Then p &= "\\"
    Return p & "bahero_compile_debug.log"
End Function

Private Function CompilerDebugSanitize(ByRef txt As String) As String
    Dim outText As String = ""
    Dim i As Integer
    For i = 1 To Len(txt)
        Dim ch As Integer = Asc(Mid(txt, i, 1))
        If ch = 9 Or ch = 10 Or ch = 13 Then
            outText &= " "
        Else
            outText &= Chr(ch)
        End If
    Next i
    Return Trim(outText)
End Function

Private Function CompilerLogNormalizeSlashes(ByRef txt As String) As String
    Dim src As String = Trim(txt)
    If Len(src) = 0 Then Return ""

    Dim pathSep As String = Chr(92)
    Dim outText As String = ""
    Dim lastSep As Integer = 0
    Dim preserveUnc As Integer = IIf(Left(src, 2) = "\\", -1, 0)
    Dim i As Integer

    For i = 1 To Len(src)
        Dim ch As String = Mid(src, i, 1)
        If ch = "/" Then ch = pathSep

        If ch = pathSep Then
            If Len(outText) = 0 Then
                outText &= ch
                lastSep = -1
            ElseIf preserveUnc <> 0 And Len(outText) = 1 And Left(outText, 1) = pathSep Then
                outText &= ch
                lastSep = -1
            ElseIf lastSep = 0 Then
                outText &= ch
                lastSep = -1
            End If
        Else
            outText &= ch
            lastSep = 0
        End If
    Next i

    Return outText
End Function

Private Sub CompilerDebugLog(ByRef area As String, ByRef messageText As String)
    Dim logMsg As String = CompilerLogNormalizeSlashes(CompilerDebugSanitize(messageText))
    Dim ff As Integer = FreeFile
    If Open(CompilerDebugLogPath() For Append As #ff) <> 0 Then Exit Sub
    Print #ff, Date & " " & Time & " [" & area & "] " & logMsg
    Close #ff
End Sub

Private Function IsAlphaNumOrSigil(ByVal ch As Integer) As Integer
    If ch >= Asc("A") And ch <= Asc("Z") Then Return -1
    If ch >= Asc("a") And ch <= Asc("z") Then Return -1
    If ch >= Asc("0") And ch <= Asc("9") Then Return -1
    If ch = Asc("_") Or ch = Asc("$") Then Return -1
    Return 0
End Function

Private Function TokIsBoundaryBefore(ByRef textLine As String, ByVal idxChar As Integer) As Integer
    If idxChar <= 1 Then Return -1
    Dim prevCh As Integer = Asc(Mid(textLine, idxChar - 1, 1))
    Return IIf(IsAlphaNumOrSigil(prevCh) = 0, -1, 0)
End Function

Private Function TokIsBoundaryAfter(ByRef textLine As String, ByVal idxAfter As Integer) As Integer
    If idxAfter > Len(textLine) Then Return -1
    Dim nextCh As Integer = Asc(Mid(textLine, idxAfter, 1))
    Return IIf(IsAlphaNumOrSigil(nextCh) = 0, -1, 0)
End Function

Private Function ReadTextFile(ByRef filePath As String, ByRef outText As String, ByRef errMsg As String) As Integer
    outText = ""
    errMsg = ""

    If Len(filePath) = 0 Then
        errMsg = "Caminho de arquivo vazio."
        Return 0
    End If

    If Dir(filePath) = "" Then
        errMsg = "Arquivo nao encontrado: " & filePath
        Return 0
    End If

    Dim ff As Integer = FreeFile
    If Open(filePath For Input As #ff) <> 0 Then
        errMsg = "Falha ao abrir arquivo para leitura: " & filePath
        Return 0
    End If

    Dim lineText As String
    While Not Eof(ff)
        Line Input #ff, lineText
        outText &= lineText
        If Not Eof(ff) Then outText &= Chr(10)
    Wend
    Close #ff

    Return -1
End Function

Private Function ReadBinaryFile(ByRef filePath As String, ByRef outBytes As String, ByRef errMsg As String) As Integer
    outBytes = ""
    errMsg = ""

    If Dir(filePath) = "" Then
        errMsg = "Arquivo nao encontrado: " & filePath
        Return 0
    End If

    Dim ff As Integer = FreeFile
    If Open(filePath For Binary Access Read As #ff) <> 0 Then
        errMsg = "Falha ao abrir arquivo binario: " & filePath
        Return 0
    End If

    Dim sizeBytes As LongInt = Lof(ff)
    If sizeBytes < 0 Then
        Close #ff
        errMsg = "Falha ao ler tamanho de arquivo: " & filePath
        Return 0
    End If

    If sizeBytes > 0 Then
        outBytes = Space(sizeBytes)
        Get #ff, , outBytes
    End If
    Close #ff

    Return -1
End Function

Private Function WriteTextFile(ByRef filePath As String, ByRef content As String, ByRef errMsg As String) As Integer
    errMsg = ""
    Dim ff As Integer = FreeFile
    If Open(filePath For Output As #ff) <> 0 Then
        errMsg = "Falha ao abrir arquivo para escrita: " & filePath
        Return 0
    End If
    Print #ff, content;
    Close #ff
    Return -1
End Function

Private Function WriteBinaryFile(ByRef filePath As String, ByRef content As String, ByRef errMsg As String) As Integer
    errMsg = ""
    Dim ff As Integer = FreeFile
    If Open(filePath For Binary Access Write As #ff) <> 0 Then
        errMsg = "Falha ao abrir arquivo binario para escrita: " & filePath
        Return 0
    End If
    If Len(content) > 0 Then Put #ff, , content
    Close #ff
    Return -1
End Function

Private Function ClearDiskDirByPattern(ByRef diskDir As String, ByRef pattern As String, ByRef errMsg As String) As Integer
    Dim fileMask As String = diskDir
    If Right(fileMask, 1) <> Chr(92) And Right(fileMask, 1) <> "/" Then fileMask &= Chr(92)
    fileMask &= pattern

    Dim entryName As String = Dir(fileMask)
    While Len(entryName) > 0
        Dim filePath As String = diskDir
        If Right(filePath, 1) <> Chr(92) And Right(filePath, 1) <> "/" Then filePath &= Chr(92)
        filePath &= entryName

        If Dir(filePath) <> "" Then
            Kill filePath
            If Dir(filePath) <> "" Then
                errMsg = "Falha ao limpar arquivo antigo: " & filePath
                Return 0
            End If
        End If
        entryName = Dir()
    Wend

    Return -1
End Function

Private Function ClearRunDiskDir(ByRef diskDir As String, ByRef errMsg As String) As Integer
    errMsg = ""
    If ClearDiskDirByPattern(diskDir, "*.dsk", errMsg) = 0 Then Return 0
    If ClearDiskDirByPattern(diskDir, "*.amx", errMsg) = 0 Then Return 0
    If ClearDiskDirByPattern(diskDir, "*.bmx", errMsg) = 0 Then Return 0
    If ClearDiskDirByPattern(diskDir, "*.dmx", errMsg) = 0 Then Return 0
    If ClearDiskDirByPattern(diskDir, "*.bas", errMsg) = 0 Then Return 0
    If ClearDiskDirByPattern(diskDir, "*.asm", errMsg) = 0 Then Return 0
    If ClearDiskDirByPattern(diskDir, "*.bin", errMsg) = 0 Then Return 0
    Return -1
End Function

Private Function NormalizePathValue(ByRef pathValue As String) As String
    Dim src As String = Trim(pathValue)
    If Len(src) = 0 Then Return ""

    Dim pathSep As String = Chr(92)
    Dim outText As String = ""
    Dim lastSep As Integer = 0
    Dim preserveUnc As Integer = IIf(Left(src, 2) = "\\", -1, 0)
    Dim i As Integer

    For i = 1 To Len(src)
        Dim ch As String = Mid(src, i, 1)
        If ch = "/" Then ch = pathSep

        If ch = pathSep Then
            If Len(outText) = 0 Then
                outText &= ch
                lastSep = -1
            ElseIf preserveUnc <> 0 And Len(outText) = 1 And Left(outText, 1) = pathSep Then
                outText &= ch
                lastSep = -1
            ElseIf lastSep = 0 Then
                outText &= ch
                lastSep = -1
            End If
        Else
            outText &= ch
            lastSep = 0
        End If
    Next i

    Return outText
End Function

Private Function StripCR(ByRef txt As String) As String
    Dim outText As String = ""
    Dim i As Integer
    For i = 1 To Len(txt)
        Dim c As String = Mid(txt, i, 1)
        If c <> Chr(13) Then outText &= c
    Next i
    Return outText
End Function

' "Strip Spaces" (cfg.badig.strip_spaces) - remove TODOS os espacos/tabs
' fora de literais de string (o classico "crunch" de listagem BASIC: uma
' keyword tokeniza igual mesmo colada num numero/identificador/`:`
' seguinte, GOTO100 e' identico a GOTO 100 pro tokenizer real). So' nao
' mexe no que esta' entre aspas - "A  B" continua "A  B".
Private Function StripSpacesOutsideStrings(ByRef txt As String) As String
    Dim outText As String = ""
    Dim inString As Integer = 0
    Dim i As Integer

    For i = 1 To Len(txt)
        Dim ch As String = Mid(txt, i, 1)
        If ch = Chr(34) Then
            inString = Not inString
            outText &= ch
        ElseIf inString = 0 And (ch = " " Or ch = Chr(9)) Then
            ' fora de string: descarta o espaco/tab, nao substitui por nada
        Else
            outText &= ch
        End If
    Next i

    Return outText
End Function

Private Function IsTrueSetting(ByRef keyName As String, ByVal fallbackValue As Integer = 0) As Integer
    Dim fb As String = IIf(fallbackValue <> 0, "True", "False")
    Dim rawValue As String = LCase(Trim(DbGetSetting(keyName, fb)))

    Select Case rawValue
        Case "1", "true", "yes", "on", "y"
            Return -1
        Case "0", "false", "no", "off", "n"
            Return 0
    End Select

    Return fallbackValue
End Function

Private Function IntSetting(ByRef keyName As String, ByVal fallbackValue As Integer, ByVal minValue As Integer, ByVal maxValue As Integer) As Integer
    Dim rawValue As String = Trim(DbGetSetting(keyName, Trim(Str(fallbackValue))))
    Dim v As Integer = ValInt(rawValue)
    If v < minValue Then v = minValue
    If v > maxValue Then v = maxValue
    Return v
End Function

Private Function ParseNumberedLine(ByRef rawLine As String, ByRef lineNumber As Integer, ByRef bodyText As String) As Integer
    Dim s As String = LTrim(rawLine)
    lineNumber = 0
    bodyText = ""

    If Len(s) = 0 Then Return 0

    Dim i As Integer = 1
    While i <= Len(s)
        Dim ch As Integer = Asc(Mid(s, i, 1))
        If ch < Asc("0") Or ch > Asc("9") Then Exit While
        i += 1
    Wend

    If i = 1 Then Return 0
    lineNumber = ValInt(Left(s, i - 1))

    If i <= Len(s) Then
        bodyText = LTrim(Mid(s, i))
    Else
        bodyText = ""
    End If

    Return -1
End Function

Private Function RewriteInlineExitForLoop(ByRef textIn As String, ByVal targetLineNo As Integer) As String
    Dim src As String = textIn
    Dim outText As String = ""
    Dim inString As Integer = 0
    Dim i As Integer = 1
    Dim repl As String = "GOTO " & Trim(Str(targetLineNo))

    While i <= Len(src)
        Dim ch As String = Mid(src, i, 1)
        If ch = Chr(34) Then
            inString = Not inString
            outText &= ch
            i += 1
        ElseIf inString = 0 And i + 3 <= Len(src) _
            And UCase(Mid(src, i, 4)) = "EXIT" _
            And TokIsBoundaryBefore(src, i) <> 0 _
            And TokIsBoundaryAfter(src, i + 4) <> 0 Then
            outText &= repl
            i += 4
        Else
            outText &= ch
            i += 1
        End If
    Wend

    Return outText
End Function

Private Function NormalizeConvertPrintMode(ByRef rawValue As String) As String
    Dim v As String = UCase(Trim(rawValue))
    If v = "?" Or v = "PRINT" Then Return v

    ' Compatibilidade com valor legado bool.
    If v = "TRUE" Or v = "1" Or v = "YES" Or v = "ON" Then Return "?"
    If v = "FALSE" Or v = "0" Or v = "NO" Or v = "OFF" Then Return "PRINT"

    Return "PRINT"
End Function

Private Function NormalizeIfJumpMode(ByRef rawValue As String) As String
    Dim v As String = UCase(Trim(rawValue))
    If v = "THEN" Or v = "GOTO" Then Return v

    ' Compatibilidade com valor legado bool.
    If v = "TRUE" Or v = "1" Or v = "YES" Or v = "ON" Then Return "THEN"
    If v = "FALSE" Or v = "0" Or v = "NO" Or v = "OFF" Then Return "GOTO"

    Return "THEN"
End Function

Private Function IsTokenBoundaryAt(ByRef src As String, ByVal pos1 As Integer, ByVal tokenLen As Integer) As Integer
    Return IIf(TokIsBoundaryBefore(src, pos1) <> 0 And TokIsBoundaryAfter(src, pos1 + tokenLen) <> 0, -1, 0)
End Function

Private Function ContainsIfTokenOutsideString(ByRef src As String) As Integer
    Dim i As Integer = 1
    Dim inString As Integer = 0

    While i <= Len(src)
        Dim ch As String = Mid(src, i, 1)
        If ch = Chr(34) Then
            inString = Not inString
            i += 1
            Continue While
        End If

        If inString = 0 And i + 1 <= Len(src) Then
            If UCase(Mid(src, i, 2)) = "IF" And IsTokenBoundaryAt(src, i, 2) <> 0 Then
                Return -1
            End If
        End If
        i += 1
    Wend

    Return 0
End Function

Private Function NextNonSpacePos(ByRef src As String, ByVal startPos As Integer) As Integer
    Dim i As Integer = startPos
    While i <= Len(src)
        Dim ch As Integer = Asc(Mid(src, i, 1))
        If ch <> Asc(" ") And ch <> 9 Then Exit While
        i += 1
    Wend
    Return i
End Function

Private Function ConvertPrintByMode(ByRef src As String, ByRef modeText As String) As String
    Dim modeU As String = UCase(Trim(modeText))
    If modeU <> "?" And modeU <> "PRINT" Then Return src

    Dim outText As String = ""
    Dim inString As Integer = 0
    Dim i As Integer = 1

    While i <= Len(src)
        Dim ch As String = Mid(src, i, 1)
        If ch = Chr(34) Then
            inString = Not inString
            outText &= ch
            i += 1
            Continue While
        End If

        If inString = 0 And modeU = "?" And i + 4 <= Len(src) Then
            If UCase(Mid(src, i, 5)) = "PRINT" And IsTokenBoundaryAt(src, i, 5) <> 0 Then
                outText &= "?"
                i += 5
                Continue While
            End If
        End If

        If inString = 0 And modeU = "PRINT" And ch = "?" Then
            outText &= "PRINT"
            i += 1
            Continue While
        End If

        outText &= ch
        i += 1
    Wend

    Return outText
End Function

Private Function RewriteIfThenGotoByMode(ByRef src As String, ByRef modeText As String) As String
    Dim modeU As String = UCase(Trim(modeText))
    If modeU <> "THEN" And modeU <> "GOTO" Then Return src
    If ContainsIfTokenOutsideString(src) = 0 Then Return src

    Dim outText As String = ""
    Dim inString As Integer = 0
    Dim i As Integer = 1

    While i <= Len(src)
        Dim ch As String = Mid(src, i, 1)
        If ch = Chr(34) Then
            inString = Not inString
            outText &= ch
            i += 1
            Continue While
        End If

        If inString = 0 And i + 3 <= Len(src) Then
            If UCase(Mid(src, i, 4)) = "THEN" And IsTokenBoundaryAt(src, i, 4) <> 0 Then
                Dim p As Integer = NextNonSpacePos(src, i + 4)
                If p + 3 <= Len(src) And UCase(Mid(src, p, 4)) = "GOTO" And IsTokenBoundaryAt(src, p, 4) <> 0 Then
                    If modeU = "THEN" Then
                        outText &= "THEN"
                    Else
                        outText &= "GOTO"
                    End If
                    i = p + 4
                    Continue While
                ElseIf p <= Len(src) Then
                    Dim n0 As Integer = Asc(Mid(src, p, 1))
                    If n0 >= Asc("0") And n0 <= Asc("9") Then
                        If modeU = "THEN" Then
                            outText &= "THEN"
                        Else
                            outText &= "GOTO"
                        End If
                        i += 4
                        Continue While
                    End If
                End If
            End If
        End If

        If inString = 0 And modeU = "THEN" And i + 3 <= Len(src) Then
            If UCase(Mid(src, i, 4)) = "GOTO" And IsTokenBoundaryAt(src, i, 4) <> 0 Then
                Dim p As Integer = NextNonSpacePos(src, i + 4)
                If p <= Len(src) Then
                    Dim n0 As Integer = Asc(Mid(src, p, 1))
                    If n0 >= Asc("0") And n0 <= Asc("9") Then
                        outText &= "THEN"
                        i += 4
                        Continue While
                    End If
                End If
            End If
        End If

        outText &= ch
        i += 1
    Wend

    Return outText
End Function

Private Function ChangeExt(ByRef filePath As String, ByRef newExt As String) As String
    Dim p As Integer = InStrRev(filePath, ".")
    If p <= 0 Then Return filePath & newExt
    Return Left(filePath, p - 1) & newExt
End Function

Private Function GetExtLower(ByRef filePath As String) As String
    Dim p As Integer = InStrRev(filePath, ".")
    If p <= 0 Then Return ""
    Return LCase(Mid(filePath, p))
End Function

Private Function BaseNameNoExt(ByRef filePath As String) As String
    Dim lastSlash As Integer = InStrRev(filePath, Chr(92))
    Dim lastFwd As Integer = InStrRev(filePath, "/")
    If lastFwd > lastSlash Then lastSlash = lastFwd

    Dim filePart As String
    If lastSlash > 0 Then
        filePart = Mid(filePath, lastSlash + 1)
    Else
        filePart = filePath
    End If

    Dim dotPos As Integer = InStrRev(filePart, ".")
    If dotPos > 0 Then
        Return Left(filePart, dotPos - 1)
    End If
    Return filePart
End Function

Private Function PathDir(ByRef filePath As String) As String
    Dim lastSlash As Integer = InStrRev(filePath, Chr(92))
    Dim lastFwd As Integer = InStrRev(filePath, "/")
    If lastFwd > lastSlash Then lastSlash = lastFwd
    If lastSlash <= 0 Then Return CurDir()
    Return Left(filePath, lastSlash - 1)
End Function

Private Function ToAbsolutePathLocal(ByRef baseDir As String, ByRef pathValue As String) As String
    Dim p As String = Trim(pathValue)
    If Len(p) = 0 Then Return ""
    If Len(p) >= 2 And Mid(p, 2, 1) = ":" Then Return p
    If Left(p, 1) = Chr(92) Or Left(p, 1) = "/" Then Return p
    Dim sep As String = Chr(92)
    If Right(baseDir, 1) = Chr(92) Or Right(baseDir, 1) = "/" Then sep = ""
    Return baseDir & sep & p
End Function

Private Function StartsWithText(ByRef fullText As String, ByRef prefix As String) As Integer
    If Len(prefix) > Len(fullText) Then Return 0
    Return IIf(Left(fullText, Len(prefix)) = prefix, -1, 0)
End Function

Private Function HexDigitValue(ByVal c As Integer) As Integer
    If c >= Asc("0") And c <= Asc("9") Then Return c - Asc("0")
    If c >= Asc("A") And c <= Asc("F") Then Return c - Asc("A") + 10
    If c >= Asc("a") And c <= Asc("f") Then Return c - Asc("a") + 10
    Return -1
End Function

Private Function HexToBin(ByRef hexText As String) As String
    Dim h As String = Trim(hexText)
    Dim outData As String = ""
    Dim i As Integer

    If Len(h) Mod 2 <> 0 Then h = "0" & h

    For i = 1 To Len(h) Step 2
        Dim hi As Integer = HexDigitValue(Asc(Mid(h, i, 1)))
        Dim lo As Integer = HexDigitValue(Asc(Mid(h, i + 1, 1)))
        If hi < 0 Or lo < 0 Then Exit For
        outData &= Chr((hi Shl 4) Or lo)
    Next i

    Return outData
End Function

Type DefineEntry
    nameKey As String
    content As String
End Type

' Proto-funcoes (func .nome(args) / ret ...) - ver "Estagio 5b" no
' paleobasic (DignifiedPreprocessor.pbi) que serviu de referencia. nameKey
' e' ScopedName(ns, nome) como um define/label normal; bareUpper e' so' o
' nome (sem namespace) pra permitir o mesmo fallback "escopo -> global" que
' ApplyDefinesOnce/ResolveLabelRefs ja usam - uma chamada .nome(...) escrita
' no arquivo principal, DEPOIS de um include que define .nome, precisa achar
' a funcao mesmo se o namespace "atual" do ponto de chamada nao bater
' exatamente com o do ponto de definicao.
Type FuncEntry
    nameKey As String
    bareUpper As String
    paramList As String    ' "p1;p2;p3" (nomes dos parametros, na ordem)
    defaultList As String  ' "d1;d2;d3" (default de cada param, "" = sem default)
    retList As String      ' "e1;e2;e3" (expressoes do RET, preenchido so' quando o RET aparece)
End Type

Type ProcLine
    text As String
    kind As Integer
    loopId As Integer
    labelTarget As String
    nsKey As String
End Type

Type LabelMap
    nameKey As String
    stmtIndex As Integer
End Type

Type LoopState
    loopId As Integer
    labelName As String
End Type

Const STMT_NORMAL = 0
Const STMT_GOTO_LABEL = 1
Const STMT_EXIT_LOOP = 2

Private Function FindDefineIndex(defs() As DefineEntry, ByVal defCount As Integer, ByRef keyName As String) As Integer
    Dim k As String = UCase(Trim(keyName))
    Dim i As Integer
    For i = 1 To defCount
        If defs(i).nameKey = k Then Return i
    Next i
    Return 0
End Function

Private Sub UpsertDefine(defs() As DefineEntry, ByRef defCount As Integer, ByRef keyName As String, ByRef content As String)
    Dim norm As String = UCase(Trim(keyName))
    If Len(norm) = 0 Then Exit Sub

    Dim idx As Integer = FindDefineIndex(defs(), defCount, norm)
    If idx <= 0 Then
        defCount += 1
        ReDim Preserve defs(1 To defCount)
        idx = defCount
    End If

    defs(idx).nameKey = norm
    defs(idx).content = content
End Sub

Private Function ReplaceFirstBracketArg(ByRef sourceText As String, ByRef argValue As String) As String
    Dim p1 As Integer = InStr(sourceText, "[")
    If p1 <= 0 Then Return sourceText
    Dim p2 As Integer = InStr(p1 + 1, sourceText, "]")
    If p2 <= 0 Then Return sourceText

    Dim defaultArg As String = Mid(sourceText, p1 + 1, p2 - p1 - 1)
    Dim useArg As String = IIf(Len(argValue) > 0, argValue, defaultArg)
    Return Left(sourceText, p1 - 1) & useArg & Mid(sourceText, p2 + 1)
End Function

Private Function ScopedName(ByRef nsKey As String, ByRef localName As String) As String
    Return UCase(nsKey) & "|" & UCase(Trim(localName))
End Function

' ===========================================================================
' Variaveis de nome longo -> nome curto (2 letras), igual ao Basic Dignified
' Suite (badig.py get_declares/process_variable + badig_msx.py Description,
' c_reserved_kw/c_var_chr/trans_char). So' letras/numeros/underscore, nao
' pode comecar com numero nem ser so' numero, minimo 3 caracteres (BASIC_
' DIGNIFIED.md, secao "Long named variables"). Atribuidas em ORDEM
' DESCENDENTE de ZZ ate' AA (nunca uma letra so' ou letra+numero). O mesmo
' nome longo sempre vira o mesmo curto independente do sufixo de tipo
' ($%!#) - variable1 e variable1$ viram XX e XX$. DECLARE forca/reserva
' mapeamentos na mao, ~ mantem o nome longo (nunca encurtado, em NENHUMA
' ocorrencia do arquivo inteiro). Variaveis de 1-2 letras usadas direto no
' codigo NUNCA sao tocadas, e ficam reservadas (o auto-assign nunca gera
' um curto que colida com uma delas).
' ===========================================================================

Type VarMapEntry
    scopedKey As String  ' ScopedName(ns, NOMELONGO) - namespace isola includes diferentes
    shortVal As String   ' nome curto atribuido (1-2 chars, minusculo por padrao)
End Type

Type VarTokenSpan
    startPos As Integer   ' posicao (1-based) do 1o char do identificador
    lenChars As Integer   ' tamanho do identificador (sem o sufixo de tipo)
    hasTilde As Integer   ' -1 se precedido por ~ colado (sem espaco)
    typeCharPos As Integer ' posicao do sufixo $%!# logo depois, ou 0 se nao tem
End Type

Private Function IsIdentStartChar(ByVal ch As Integer) As Integer
    If ch >= Asc("A") And ch <= Asc("Z") Then Return -1
    If ch >= Asc("a") And ch <= Asc("z") Then Return -1
    Return 0
End Function

Private Function IsIdentBodyChar(ByVal ch As Integer) As Integer
    If IsIdentStartChar(ch) <> 0 Then Return -1
    If ch >= Asc("0") And ch <= Asc("9") Then Return -1
    If ch = Asc("_") Then Return -1
    Return 0
End Function

' Lista mestra de palavras reservadas (instrucoes/funcoes/operadores/saltos
' classicos do dialeto MSX-BASIC, badig_msx.py Description.__init__, mais os
' comandos proprios do Dignified, badig_dignified.py) - as funcoes com $
' (CHR$, INKEY$, etc) ja vem com o $ embutido, conferidas a parte contra
' "identificador & tipo" quando o tipo for exatamente $.
Private Function ReservedKeywordList() As String
    Return " AS BASE BEEP BLOAD BSAVE CALL CIRCLE CLEAR CLOAD CLOSE CLS CMD COLOR CONT COPY CSAVE CSRLIN DEF DEFDBL DEFINT MAXFILES DEFSNG DEFSTR DIM DRAW DSKI END EQV ERASE ERR ERROR FIELD FILES FN FOR GET IF INPUT INTERVAL IMP IPL KILL LET LFILES LINE LOAD LOCATE LPRINT LSET MAX MERGE MOTOR NAME NEW NEXT OFF ON OPEN OUT OUTPUT PAINT POINT POKE PRESET PRINT PSET PUT READ RSET SAVE SCREEN SET SOUND STEP STOP SWAP TIME TO TROFF TRON USING VPOKE WAIT WIDTH" & _
           " ATTR$ BIN$ CHR$ DSKO$ HEX$ INKEY$ INPUT$ LEFT$ MID$ MKD$ MKI$ MKS$ OCT$ RIGHT$ SPACE$ SPRITE$ STR$ STRING$" & _
           " ABS ASC ATN CDBL CINT COS CSNG CVD CVI CVS DSKF EOF EXP FIX FPOS FRE INP INSTR INT KEY LEN LOC LOF LOG LPOS PAD PDL PEEK PLAY POS RND SGN SIN SPC SPRITE SQR STICK STRIG TAB TAN VAL VARPTR VDP VPEEK" & _
           " RESTORE AUTO RENUM DELETE RESUME ERL ELSE RUN LIST LLIST GOTO RETURN THEN GOSUB" & _
           " AND MOD NOT OR XOR DATA REM" & _
           " DECLARE DEFINE INCLUDE KEEP ENDIF FUNC RET EXIT TRUE FALSE "
End Function

' USR/DEFUSR aceitam um digito opcional colado (USR0-USR9, DEFUSR0-DEFUSR9)
' - o resto das palavras reservadas nao tem essa variante.
Private Function IsUsrLikeReserved(ByRef upperIdent As String) As Integer
    Dim bases(1 To 2) As String
    bases(1) = "USR"
    bases(2) = "DEFUSR"
    Dim i As Integer
    For i = 1 To 2
        Dim b As String = bases(i)
        If upperIdent = b Then Return -1
        If Len(upperIdent) = Len(b) + 1 And Left(upperIdent, Len(b)) = b Then
            Dim lastCh As Integer = Asc(Right(upperIdent, 1))
            If lastCh >= Asc("0") And lastCh <= Asc("9") Then Return -1
        End If
    Next i
    Return 0
End Function

Private Function IsReservedKeyword(ByRef ident As String, ByRef typeCharIfAny As String) As Integer
    Dim u As String = UCase(ident)
    If IsUsrLikeReserved(u) <> 0 Then Return -1

    Dim list As String = ReservedKeywordList()
    If InStr(list, " " & u & " ") > 0 Then Return -1
    If typeCharIfAny = "$" And InStr(list, " " & u & "$ ") > 0 Then Return -1
    Return 0
End Function

' Varre o texto (fora de string literal) e devolve TODOS os identificadores
' (palavra-chave ou variavel, sem distincao ainda - quem chama decide) numa
' unica passada. Para na primeira REM/DATA/' encontrada fora de string (o
' resto da linha logica e' comentario ou dado literal - nem palavra reservada
' nem variavel deve ser "encontrada" ali dentro, senao um comentario em
' ingles vira sopa de variaveis trocadas).
Private Function TokenizeIdentifierSpans(ByRef text As String, spans() As VarTokenSpan) As Integer
    Dim spanCount As Integer = 0
    Dim n As Integer = Len(text)
    Dim i As Integer = 1
    Dim inString As Integer = 0

    While i <= n
        Dim ch As Integer = Asc(Mid(text, i, 1))

        If inString <> 0 Then
            If ch = Asc(Chr(34)) Then inString = 0
            i += 1
            Continue While
        End If

        If ch = Asc(Chr(34)) Then
            inString = -1
            i += 1
            Continue While
        End If

        If ch = Asc("'") Then Exit While ' REM curto - resto da linha e' comentario

        Dim boundaryBefore As Integer = (i = 1) Or (IsIdentBodyChar(Asc(Mid(text, i - 1, 1))) = 0)
        If boundaryBefore <> 0 Then
            If i + 2 <= n + 1 And UCase(Mid(text, i, 3)) = "REM" And IsIdentBodyChar(Asc(Mid(text, i + 3, 1))) = 0 Then Exit While
            If i + 3 <= n + 1 And UCase(Mid(text, i, 4)) = "DATA" And IsIdentBodyChar(Asc(Mid(text, i + 4, 1))) = 0 Then Exit While
        End If

        If IsIdentStartChar(ch) <> 0 Then
            Dim startPos As Integer = i
            Dim j As Integer = i + 1
            While j <= n AndAlso IsIdentBodyChar(Asc(Mid(text, j, 1))) <> 0
                j += 1
            Wend

            Dim hasTilde As Integer = 0
            If startPos > 1 AndAlso Mid(text, startPos - 1, 1) = "~" Then hasTilde = -1

            Dim typeCharPos As Integer = 0
            If j <= n Then
                Dim tch As String = Mid(text, j, 1)
                If tch = "$" Or tch = "%" Or tch = "!" Or tch = "#" Then typeCharPos = j
            End If

            spanCount += 1
            ReDim Preserve spans(1 To spanCount)
            spans(spanCount).startPos = startPos
            spans(spanCount).lenChars = j - startPos
            spans(spanCount).hasTilde = hasTilde
            spans(spanCount).typeCharPos = typeCharPos

            i = j
            Continue While
        End If

        i += 1
    Wend

    Return spanCount
End Function

Private Function FindStringIndex(arr() As String, ByVal n As Integer, ByRef key As String) As Integer
    Dim i As Integer
    For i = 1 To n
        If arr(i) = key Then Return i
    Next i
    Return 0
End Function

Private Sub AddStringIfMissing(arr() As String, ByRef n As Integer, ByRef key As String)
    If FindStringIndex(arr(), n, key) > 0 Then Exit Sub
    n += 1
    ReDim Preserve arr(1 To n)
    arr(n) = key
End Sub

Private Function FindVarMapIndex(varMap() As VarMapEntry, ByVal n As Integer, ByRef scopedKey As String) As Integer
    Dim i As Integer
    For i = 1 To n
        If varMap(i).scopedKey = scopedKey Then Return i
    Next i
    Return 0
End Function

Private Sub UpsertVarMap(varMap() As VarMapEntry, ByRef n As Integer, ByRef scopedKey As String, ByRef shortVal As String)
    Dim idx As Integer = FindVarMapIndex(varMap(), n, scopedKey)
    If idx <= 0 Then
        n += 1
        ReDim Preserve varMap(1 To n)
        idx = n
    End If
    varMap(idx).scopedKey = scopedKey
    varMap(idx).shortVal = shortVal
End Sub

' "declare longo:curto" (forca um mapeamento) ou "declare longo1,longo2,..."
' /"declare curto1,curto2,..." (reserva - nao deixa o auto-assign usar,
' seja um nome curto direto ou os 2 primeiros chars de um nome que vai
' ficar sempre por extenso). Varios itens separados por virgula na mesma
' linha. Chamado durante o parsing linha-a-linha, igual ao DEFINE - a
' linha inteira e' consumida, nunca vira um stmt de saida.
Private Function ProcessDeclareLine(ByRef body As String, ByRef currentNs As String, varMap() As VarMapEntry, ByRef varMapCount As Integer, keepLongKeys() As String, ByRef keepLongCount As Integer, reservedShortVals() As String, ByRef reservedShortCount As Integer, ByRef errMsg As String) As Integer
    If Len(Trim(body)) = 0 Then Return -1

    Dim items() As String
    Dim itemCount As Integer = 0
    Dim chunk As String = ""
    Dim i As Integer
    For i = 1 To Len(body)
        Dim ch As String = Mid(body, i, 1)
        If ch = "," Then
            itemCount += 1
            ReDim Preserve items(1 To itemCount)
            items(itemCount) = Trim(chunk)
            chunk = ""
        Else
            chunk &= ch
        End If
    Next i
    If Len(Trim(chunk)) > 0 Then
        itemCount += 1
        ReDim Preserve items(1 To itemCount)
        items(itemCount) = Trim(chunk)
    End If

    Dim di As Integer
    For di = 1 To itemCount
        Dim entry As String = items(di)
        If Len(entry) = 0 Then Continue For

        Dim colonPos As Integer = InStr(entry, ":")
        If colonPos > 0 Then
            Dim longName As String = Trim(Left(entry, colonPos - 1))
            Dim shortName As String = Trim(Mid(entry, colonPos + 1))

            If Len(longName) < 2 Or IsIdentStartChar(Asc(Left(longName, 1))) = 0 Then
                errMsg = "declare: nome longo invalido: " & longName
                Return 0
            End If
            If InStr("$%!#", Right(shortName, 1)) > 0 Then
                errMsg = "declare: nao pode usar sufixo de tipo ($%!#) - " & entry
                Return 0
            End If
            If Len(shortName) < 1 Or Len(shortName) > 2 Or IsIdentStartChar(Asc(Left(shortName, 1))) = 0 Then
                errMsg = "declare: nome curto invalido: " & shortName
                Return 0
            End If
            If IsReservedKeyword(longName, "") <> 0 Then
                errMsg = "declare: " & longName & " e' uma palavra reservada do BASIC."
                Return 0
            End If

            UpsertVarMap(varMap(), varMapCount, ScopedName(currentNs, longName), LCase(shortName))
            AddStringIfMissing(reservedShortVals(), reservedShortCount, UCase(shortName))
        Else
            If Len(entry) = 0 Or IsIdentStartChar(Asc(Left(entry, 1))) = 0 Then
                errMsg = "declare: identificador invalido: " & entry
                Return 0
            End If
            If Len(entry) = 1 Then
                errMsg = "declare: nao da' pra reservar variavel de 1 letra: " & entry
                Return 0
            End If

            If Len(entry) <= 2 Then
                AddStringIfMissing(reservedShortVals(), reservedShortCount, UCase(entry))
            Else
                If IsReservedKeyword(entry, "") <> 0 Then
                    errMsg = "declare: " & entry & " e' uma palavra reservada do BASIC."
                    Return 0
                End If
                AddStringIfMissing(keepLongKeys(), keepLongCount, ScopedName(currentNs, entry))
            End If
        End If
    Next di

    Return -1
End Function

' Varre TODAS as statements normais (kind=STMT_NORMAL) coletando: nomes
' ~marcados (ficam por extenso pra sempre), variaveis de 1-2 letras usadas
' direto (reservam esse curto), e candidatos a variavel longa (3+ letras,
' nao reservada, sem ~) na ORDEM em que aparecem no fonte - essa ordem e'
' a ordem de atribuicao do auto-assign (descendente de ZZ).
Private Sub CollectVariableUsage(stmts() As ProcLine, ByVal stmtCount As Integer, keepLongKeys() As String, ByRef keepLongCount As Integer, reservedShortVals() As String, ByRef reservedShortCount As Integer, longVarKeys() As String, ByRef longVarCount As Integer)
    Dim i As Integer
    For i = 1 To stmtCount
        If stmts(i).kind <> STMT_NORMAL Then Continue For

        Dim spans() As VarTokenSpan
        Dim spanCount As Integer = TokenizeIdentifierSpans(stmts(i).text, spans())
        Dim s As Integer
        For s = 1 To spanCount
            Dim ident As String = Mid(stmts(i).text, spans(s).startPos, spans(s).lenChars)
            Dim typeChar As String = ""
            If spans(s).typeCharPos > 0 Then typeChar = Mid(stmts(i).text, spans(s).typeCharPos, 1)

            If IsReservedKeyword(ident, typeChar) <> 0 Then Continue For

            If spans(s).hasTilde <> 0 Then
                If Len(ident) >= 3 Then AddStringIfMissing(keepLongKeys(), keepLongCount, ScopedName(stmts(i).nsKey, ident))
                Continue For
            End If

            If Len(ident) <= 2 Then
                AddStringIfMissing(reservedShortVals(), reservedShortCount, UCase(ident))
            Else
                AddStringIfMissing(longVarKeys(), longVarCount, ScopedName(stmts(i).nsKey, ident))
            End If
        Next s
    Next i
End Sub

' Gera o proximo par de letras livre, descendo de "zz" ate' "aa" (676
' combinacoes, nunca 1 letra so' nem letra+numero) - pula qualquer par ja'
' reservado (hardcoded, declare, ou 2 primeiras letras de um nome mantido
' por extenso).
Private Sub AssignShortNames(longVarKeys() As String, ByVal longVarCount As Integer, keepLongKeys() As String, ByVal keepLongCount As Integer, reservedShortVals() As String, ByRef reservedShortCount As Integer, varMap() As VarMapEntry, ByRef varMapCount As Integer)
    Const letters = "abcdefghijklmnopqrstuvwxyz"

    Dim k As Integer
    For k = 1 To keepLongCount
        Dim barPos As Integer = InStr(keepLongKeys(k), "|")
        Dim localPart As String = Mid(keepLongKeys(k), barPos + 1)
        AddStringIfMissing(reservedShortVals(), reservedShortCount, Left(localPart, 2))
    Next k
    For k = 1 To varMapCount
        AddStringIfMissing(reservedShortVals(), reservedShortCount, UCase(varMap(k).shortVal))
    Next k

    Dim varIndex As Integer = 675 ' 26*26 - 1, comeca em "zz"
    Dim v As Integer
    For v = 1 To longVarCount
        If FindVarMapIndex(varMap(), varMapCount, longVarKeys(v)) > 0 Then Continue For ' ja' veio de declare
        ' ~ em QUALQUER ocorrencia (mesmo numa so' linha, nao necessariamente
        ' a 1a) marca a variavel inteira como "mantem por extenso" pro
        ' arquivo todo - se apareceu aqui tambem sem ~ antes de a gente
        ' notar isso, precisa ser descartada agora, senao viraria curta
        ' nas ocorrencias sem ~ e comprida so' na com ~ (inconsistente).
        If FindStringIndex(keepLongKeys(), keepLongCount, longVarKeys(v)) > 0 Then Continue For

        Dim assigned As Integer = 0
        Do While varIndex >= 0 And assigned = 0
            Dim idxH As Integer = varIndex \ 26
            Dim idxL As Integer = varIndex Mod 26
            Dim candidate As String = Mid(letters, idxH + 1, 1) & Mid(letters, idxL + 1, 1)
            varIndex -= 1

            If FindStringIndex(reservedShortVals(), reservedShortCount, UCase(candidate)) = 0 Then
                UpsertVarMap(varMap(), varMapCount, longVarKeys(v), candidate)
                AddStringIfMissing(reservedShortVals(), reservedShortCount, UCase(candidate))
                assigned = -1
            End If
        Loop
    Next v
End Sub

' Reconstroi o texto trocando cada variavel longa conhecida pelo curto
' associado (mantendo o sufixo de tipo $%!# do jeito que estava) - palavra
' reservada, variavel curta usada direto e nome ~marcado passam intactos.
' O ~ em si e' sempre removido da saida (marcador de compilacao, nao existe
' no BASIC de verdade).
Private Function SubstituteVariables(ByRef text As String, ByRef nsKey As String, varMap() As VarMapEntry, ByVal varMapCount As Integer) As String
    Dim spans() As VarTokenSpan
    Dim spanCount As Integer = TokenizeIdentifierSpans(text, spans())
    If spanCount = 0 Then Return text

    Dim outText As String = ""
    Dim lastPos As Integer = 0
    Dim s As Integer
    For s = 1 To spanCount
        Dim gapEnd As Integer = spans(s).startPos - 1
        If spans(s).hasTilde <> 0 Then gapEnd -= 1
        outText &= Mid(text, lastPos + 1, gapEnd - lastPos)

        Dim ident As String = Mid(text, spans(s).startPos, spans(s).lenChars)
        Dim typeChar As String = ""
        If spans(s).typeCharPos > 0 Then typeChar = Mid(text, spans(s).typeCharPos, 1)

        Dim replaced As Integer = 0
        If IsReservedKeyword(ident, typeChar) = 0 And spans(s).hasTilde = 0 Then
            Dim idx As Integer = FindVarMapIndex(varMap(), varMapCount, ScopedName(nsKey, ident))
            If idx > 0 Then
                outText &= varMap(idx).shortVal & typeChar
                replaced = -1
            End If
        End If
        If replaced = 0 Then outText &= ident

        lastPos = spans(s).startPos + spans(s).lenChars - 1
        If replaced <> 0 And spans(s).typeCharPos > 0 Then lastPos = spans(s).typeCharPos
    Next s
    outText &= Mid(text, lastPos + 1)

    Return outText
End Function

Private Function ParseDefineLine(ByRef lineText As String, defs() As DefineEntry, ByRef defCount As Integer) As Integer
    Dim t As String = LTrim(lineText)
    If Len(t) < 6 Then Return 0
    If UCase(Left(t, 6)) <> "DEFINE" Then Return 0

    Dim body As String = Trim(Mid(t, 7))
    If Len(body) = 0 Then Return -1

    Dim items() As String
    Dim itemCount As Integer = 0
    Dim depth As Integer = 0
    Dim chunk As String = ""
    Dim i As Integer

    For i = 1 To Len(body)
        Dim ch As String = Mid(body, i, 1)
        If ch = "[" Then
            depth += 1
            chunk &= ch
        ElseIf ch = "]" Then
            If depth > 0 Then depth -= 1
            chunk &= ch
        ElseIf ch = "," And depth = 0 Then
            itemCount += 1
            ReDim Preserve items(1 To itemCount)
            items(itemCount) = Trim(chunk)
            chunk = ""
        Else
            chunk &= ch
        End If
    Next i

    If Len(Trim(chunk)) > 0 Then
        itemCount += 1
        ReDim Preserve items(1 To itemCount)
        items(itemCount) = Trim(chunk)
    End If

    For i = 1 To itemCount
        Dim one As String = items(i)
        Dim p1 As Integer = InStr(one, "[")
        Dim p2 As Integer = InStr(p1 + 1, one, "]")
        Dim p3 As Integer = InStr(p2 + 1, one, "[")
        Dim p4 As Integer = InStr(p3 + 1, one, "]")
        If p1 > 0 And p2 > p1 And p3 > p2 And p4 > p3 Then
            Dim dName As String = Mid(one, p1 + 1, p2 - p1 - 1)
            Dim dContent As String = Mid(one, p3 + 1, p4 - p3 - 1)
            UpsertDefine(defs(), defCount, dName, dContent)
        End If
    Next i

    Return -1
End Function

Private Function ApplyDefinesOnce(ByRef inText As String, defs() As DefineEntry, ByVal defCount As Integer, ByRef currentNs As String) As String
    Dim outText As String = ""
    Dim i As Integer = 1

    While i <= Len(inText)
        Dim ch As String = Mid(inText, i, 1)
        If ch = "[" Then
            Dim p2 As Integer = InStr(i + 1, inText, "]")
            If p2 > 0 Then
                Dim keyName As String = Mid(inText, i + 1, p2 - i - 1)
                Dim idx As Integer = FindDefineIndex(defs(), defCount, ScopedName(currentNs, keyName))
                If idx <= 0 Then idx = FindDefineIndex(defs(), defCount, keyName)
                If idx > 0 Then
                    Dim argValue As String = ""
                    Dim consumeTo As Integer = p2
                    If p2 < Len(inText) And Mid(inText, p2 + 1, 1) = "(" Then
                        Dim p3 As Integer = InStr(p2 + 2, inText, ")")
                        If p3 > 0 Then
                            argValue = Mid(inText, p2 + 2, p3 - p2 - 2)
                            consumeTo = p3
                        End If
                    End If

                    Dim repl As String = ReplaceFirstBracketArg(defs(idx).content, argValue)
                    outText &= repl
                    i = consumeTo + 1
                    Continue While
                End If
            End If
        End If

        outText &= ch
        i += 1
    Wend

    Return outText
End Function

Private Function ApplyDefinesRecursive(ByRef inText As String, defs() As DefineEntry, ByVal defCount As Integer) As String
    Dim cur As String = inText
    Dim pass As Integer
    Dim fallbackNs As String = ""
    For pass = 1 To 8
        Dim nxt As String = ApplyDefinesOnce(cur, defs(), defCount, fallbackNs)
        If nxt = cur Then Exit For
        cur = nxt
    Next pass
    Return cur
End Function

Private Function ApplyDefinesRecursiveScoped(ByRef inText As String, defs() As DefineEntry, ByVal defCount As Integer, ByRef currentNs As String) As String
    Dim cur As String = inText
    Dim pass As Integer
    For pass = 1 To 8
        Dim nxt As String = ApplyDefinesOnce(cur, defs(), defCount, currentNs)
        If nxt = cur Then Exit For
        cur = nxt
    Next pass
    Return cur
End Function

Private Function ExtractQuotedPath(ByRef lineText As String, ByRef outPath As String) As Integer
    outPath = ""
    Dim p1 As Integer = InStr(lineText, Chr(34))
    If p1 <= 0 Then Return 0
    Dim p2 As Integer = InStr(p1 + 1, lineText, Chr(34))
    If p2 <= p1 Then Return 0
    outPath = Mid(lineText, p1 + 1, p2 - p1 - 1)
    Return -1
End Function

Private Function ExpandIncludesText(ByRef sourcePath As String, ByRef sourceText As String, ByRef outText As String, ByRef errMsg As String, includeStack() As String, ByRef stackCount As Integer) As Integer
    Dim fullSourcePath As String = ToAbsolutePathLocal(CurDir(), sourcePath)
    Dim sourceDir As String = PathDir(fullSourcePath)
    Dim normalized As String = StripCR(sourceText)
    outText = "##BB:NS=" & fullSourcePath

    Dim posStart As Integer = 1
    While posStart <= Len(normalized)
        Dim br As Integer = InStr(posStart, normalized, Chr(10))
        Dim oneLine As String
        If br = 0 Then
            oneLine = Mid(normalized, posStart)
            posStart = Len(normalized) + 1
        Else
            oneLine = Mid(normalized, posStart, br - posStart)
            posStart = br + 1
        End If

        Dim t As String = LTrim(oneLine)
        If UCase(Left(t, 7)) = "INCLUDE" Then
            Dim relPath As String
            If ExtractQuotedPath(t, relPath) <> 0 Then
                Dim incPath As String = ToAbsolutePathLocal(sourceDir, relPath)
                Dim i As Integer
                For i = 1 To stackCount
                    If UCase(includeStack(i)) = UCase(incPath) Then
                        errMsg = "Include recursivo detectado: " & incPath
                        Return 0
                    End If
                Next i

                Dim incText As String
                If ReadTextFile(incPath, incText, errMsg) = 0 Then Return 0

                stackCount += 1
                ReDim Preserve includeStack(1 To stackCount)
                includeStack(stackCount) = incPath

                Dim expanded As String
                If ExpandIncludesText(incPath, incText, expanded, errMsg, includeStack(), stackCount) = 0 Then Return 0

                stackCount -= 1
                If stackCount > 0 Then
                    ReDim Preserve includeStack(1 To stackCount)
                Else
                    Erase includeStack
                End If

                If Len(outText) > 0 And Right(outText, 1) <> Chr(10) Then outText &= Chr(10)
                outText &= expanded
                If Len(outText) = 0 Or Right(outText, 1) <> Chr(10) Then outText &= Chr(10)
                Continue While
            End If
        End If

        If Len(outText) > 0 Then outText &= Chr(10)
        outText &= oneLine
    Wend

    Return -1
End Function

' "Linhas terminadas em : continuam na linha seguinte, e linhas iniciadas
' em : continuam a linha anterior" (BASIC_DIGNIFIED.md, "Line separation")
' - o : e' mantido no texto final, com a mesma funcao de separador de
' instrucoes do BASIC classico. Roda ANTES do loop principal de
' PreprocessDignified pra que cada "linha" que ele enxerga ja' seja o
' resultado final da juncao (vira uma unica linha numerada, nao varias).
Private Function JoinContinuationLines(ByRef textIn As String) As String
    Dim outText As String = ""
    Dim group As String = ""
    Dim haveGroup As Integer = 0
    Dim posStart As Integer = 1

    While posStart <= Len(textIn)
        Dim br As Integer = InStr(posStart, textIn, Chr(10))
        Dim oneLine As String
        If br = 0 Then
            oneLine = Mid(textIn, posStart)
            posStart = Len(textIn) + 1
        Else
            oneLine = Mid(textIn, posStart, br - posStart)
            posStart = br + 1
        End If

        Dim t As String = Trim(oneLine)

        If haveGroup = 0 Then
            group = t
            haveGroup = -1
        ElseIf Right(group, 1) = ":" Or Left(t, 1) = ":" Then
            If Right(group, 1) = ":" And Left(t, 1) = ":" Then
                group &= Mid(t, 2) ' os dois lados tem : - mantem so' um, senao duplicava
            Else
                group &= t
            End If
        Else
            If Len(outText) > 0 Then outText &= Chr(10)
            outText &= group
            group = t
        End If
    Wend

    If haveGroup <> 0 Then
        If Len(outText) > 0 Then outText &= Chr(10)
        outText &= group
    End If

    Return outText
End Function

Private Function FindLabelIndex(labels() As LabelMap, ByVal labelCount As Integer, ByRef nameKey As String) As Integer
    Dim key As String = UCase(Trim(nameKey))
    Dim i As Integer
    For i = 1 To labelCount
        If labels(i).nameKey = key Then Return i
    Next i
    Return 0
End Function

Private Function IsValidLabelName(ByRef nameText As String) As Integer
    Dim s As String = Trim(nameText)
    If Len(s) = 0 Then Return 0
    If s = "@" Then Return -1

    Dim i As Integer
    For i = 1 To Len(s)
        Dim c As Integer = Asc(Mid(s, i, 1))
        Dim ok As Integer = 0
        If c >= Asc("A") And c <= Asc("Z") Then ok = -1
        If c >= Asc("a") And c <= Asc("z") Then ok = -1
        If c >= Asc("0") And c <= Asc("9") Then ok = -1
        If c = Asc("_") Then ok = -1
        If ok = 0 Then Return 0
    Next i

    Dim firstC As Integer = Asc(Left(s, 1))
    If firstC >= Asc("0") And firstC <= Asc("9") Then Return 0

    Return -1
End Function

Private Function ResolveLabelRefs(ByRef textIn As String, ByVal stmtIndex As Integer, stmtLineNos() As Integer, labels() As LabelMap, ByVal labelCount As Integer, ByRef currentNs As String, ByRef errMsg As String) As String
    Dim outText As String = ""
    Dim i As Integer = 1
    Dim inString As Integer = 0

    While i <= Len(textIn)
        Dim ch As String = Mid(textIn, i, 1)

        If ch = Chr(34) Then
            inString = Not inString
            outText &= ch
            i += 1
            Continue While
        End If

        If inString = 0 And ch = "{" Then
            Dim p2 As Integer = InStr(i + 1, textIn, "}")
            If p2 > i Then
                Dim labelName As String = Mid(textIn, i + 1, p2 - i - 1)
                Dim key As String = UCase(Trim(labelName))
                Dim replacement As String

                If key = "@" Then
                    replacement = Trim(Str(stmtLineNos(stmtIndex)))
                Else
                    Dim idx As Integer = FindLabelIndex(labels(), labelCount, ScopedName(currentNs, key))
                    If idx <= 0 Then idx = FindLabelIndex(labels(), labelCount, key)
                    If idx <= 0 Then
                        errMsg = "Label nao encontrado: {" & labelName & "}"
                        Return ""
                    End If
                    replacement = Trim(Str(stmtLineNos(labels(idx).stmtIndex)))
                End If

                outText &= replacement
                i = p2 + 1
                Continue While
            End If
        End If

        outText &= ch
        i += 1
    Wend

    Return outText
End Function

' ===========================================================================
' Proto-funcoes (func .nome(args) / ret / chamadas .nome(args)) - porte do
' "Estagio 5b" do paleobasic (DignifiedPreprocessor.pbi: Dig_HandleFuncDef/
' Dig_HandleFuncRet/Dig_BuildFuncCallReplacement/Dig_FuncCalls_Piece),
' adaptado ao pipeline de linha-unica do msxIDE. Uma chamada ".nome(args)"
' vira "param1=arg1:param2=arg2:GOSUB {rotulo}:capturada1=retorno1:..." -
' o alvo do GOSUB usa a MESMA sintaxe "{rotulo}" de label ja resolvida por
' ResolveLabelRefs (com o mesmo fallback escopo->global), entao nao precisa
' de nenhum marcador especial: e' so' mais um label comum, cujo "corpo" e' o
' bloco entre "func .nome(...)" e o "ret" correspondente.
' ===========================================================================

Private Function FindFuncIndex(funcs() As FuncEntry, ByVal funcCount As Integer, ByRef keyName As String) As Integer
    Dim k As String = UCase(Trim(keyName))
    Dim i As Integer
    For i = 1 To funcCount
        If funcs(i).nameKey = k Then Return i
    Next i
    Return 0
End Function

Private Function FindFuncIndexByBareName(funcs() As FuncEntry, ByVal funcCount As Integer, ByRef bareName As String) As Integer
    Dim k As String = UCase(Trim(bareName))
    Dim i As Integer
    For i = 1 To funcCount
        If funcs(i).bareUpper = k Then Return i
    Next i
    Return 0
End Function

Private Function ResolveFuncIndex(funcs() As FuncEntry, ByVal funcCount As Integer, ByRef currentNs As String, ByRef bareName As String) As Integer
    Dim idx As Integer = FindFuncIndex(funcs(), funcCount, ScopedName(currentNs, bareName))
    If idx <= 0 Then idx = FindFuncIndexByBareName(funcs(), funcCount, bareName)
    Return idx
End Function

Private Function FuncLabelName(ByRef fname As String) As String
    Return "__FUNC_" & UCase(fname)
End Function

' Separa Text por virgulas de nivel superior (ignora virgula dentro de
' parenteses aninhados ou de literal entre aspas) - reusado pra argumentos
' de func, expressoes de ret e argumentos de chamada .nome(args). Texto
' vazio/so' espacos devolve 0 itens (func sem parametros).
Private Sub SplitTopLevelArgs(ByRef bodyText As String, outItems() As String, ByRef outCount As Integer)
    outCount = 0
    If Len(Trim(bodyText)) = 0 Then Exit Sub

    Dim depth As Integer = 0
    Dim inQuote As Integer = 0
    Dim startPos As Integer = 1
    Dim i As Integer
    For i = 1 To Len(bodyText)
        Dim ch As String = Mid(bodyText, i, 1)
        If inQuote <> 0 Then
            If ch = Chr(34) Then inQuote = 0
        Else
            If ch = Chr(34) Then
                inQuote = -1
            ElseIf ch = "(" Then
                depth += 1
            ElseIf ch = ")" Then
                depth -= 1
            ElseIf ch = "," And depth = 0 Then
                outCount += 1
                ReDim Preserve outItems(1 To outCount)
                outItems(outCount) = Trim(Mid(bodyText, startPos, i - startPos))
                startPos = i + 1
            End If
        End If
    Next i
    outCount += 1
    ReDim Preserve outItems(1 To outCount)
    outItems(outCount) = Trim(Mid(bodyText, startPos, Len(bodyText) - startPos + 1))
End Sub

' Acha a posicao do ')' que fecha o '(' em text(openPos), respeitando
' parenteses aninhados e literais entre aspas. Devolve 0 se nao fechar.
Private Function FindMatchingParenPos(ByRef text As String, ByVal openPos As Integer) As Integer
    Dim depth As Integer = 1
    Dim i As Integer = openPos + 1
    Dim inQuote As Integer = 0
    While i <= Len(text)
        Dim ch As String = Mid(text, i, 1)
        If inQuote <> 0 Then
            If ch = Chr(34) Then inQuote = 0
        Else
            If ch = Chr(34) Then
                inQuote = -1
            ElseIf ch = "(" Then
                depth += 1
            ElseIf ch = ")" Then
                depth -= 1
                If depth = 0 Then Return i
            End If
        End If
        i += 1
    Wend
    Return 0
End Function

' Acha a posicao do ULTIMO ':' de nivel superior em text (fora de literal
' entre aspas) - 0 se nao houver. Usado pra achar um "ret ..." colado no
' final de uma linha logica ja unida por JoinContinuationLines via ':' de
' continuacao (ex.: "gosub {x}:" seguido de "ret y" no fonte vira uma linha
' so' "gosub {x}:ret y" antes de chegar aqui - sem isso "ret" deixa de ser a
' primeira palavra da linha e nunca e' reconhecido).
Private Function FindLastTopLevelColonPos(ByRef text As String) As Integer
    Dim inQuote As Integer = 0
    Dim lastPos As Integer = 0
    Dim i As Integer
    For i = 1 To Len(text)
        Dim ch As String = Mid(text, i, 1)
        If inQuote <> 0 Then
            If ch = Chr(34) Then inQuote = 0
        Else
            If ch = Chr(34) Then
                inQuote = -1
            ElseIf ch = ":" Then
                lastPos = i
            End If
        End If
    Next i
    Return lastPos
End Function

Private Function FirstWordUpper(ByRef text As String) As String
    Dim sp As Integer = InStr(text, " ")
    If sp = 0 Then Return UCase(text)
    Return UCase(Left(text, sp - 1))
End Function

Private Function CountChar(ByRef s As String, ByRef ch As String) As Integer
    Dim cnt As Integer = 0
    Dim p As Integer = 1
    Do
        Dim f As Integer = InStr(p, s, ch)
        If f = 0 Then Exit Do
        cnt += 1
        p = f + 1
    Loop
    Return cnt
End Function

' Equivalente a StringField(s, idx, ";") do PureBasic - campo idx (1-based)
' de uma lista separada por ";".
Private Function FieldSemicolon(ByRef s As String, ByVal idx As Integer) As String
    Dim p As Integer = 1
    Dim curIdx As Integer = 1
    Do While curIdx < idx
        Dim f As Integer = InStr(p, s, ";")
        If f = 0 Then Return ""
        p = f + 1
        curIdx += 1
    Loop
    Dim nextP As Integer = InStr(p, s, ";")
    If nextP = 0 Then Return Mid(s, p)
    Return Mid(s, p, nextP - p)
End Function

' Tenta reconhecer "var1, var2 = " logo antes do fim de textSoFar (usado
' antes de uma chamada .nome(...) pra capturar os retornos). Devolve a
' posicao (1-based) onde comeca esse prefixo (pra caller cortar textSoFar
' ali) e preenche captureVars(); devolve 0 (e captureCount=0) se nao achar
' um prefixo valido - textSoFar fica intocado pelo caller nesse caso.
Private Function TryExtractCaptureVars(ByRef textSoFar As String, captureVars() As String, ByRef captureCount As Integer) As Integer
    captureCount = 0
    Dim s As String = textSoFar
    Dim i As Integer = Len(s)

    While i >= 1 AndAlso Mid(s, i, 1) = " "
        i -= 1
    Wend
    If i < 1 Then Return 0
    If Mid(s, i, 1) <> "=" Then Return 0
    If i >= 2 Then
        Dim beforeEq As String = Mid(s, i - 1, 1)
        If beforeEq = "<" Or beforeEq = ">" Or beforeEq = "=" Then Return 0
    End If
    i -= 1

    Dim scanPos As Integer = i
    Do While scanPos >= 1
        Dim c As String = Mid(s, scanPos, 1)
        If c = " " Or c = "," Or IsIdentBodyChar(Asc(c)) <> 0 Or c = "$" Or c = "%" Or c = "!" Or c = "#" Then
            scanPos -= 1
        Else
            Exit Do
        End If
    Loop

    Dim startBoundary As Integer = scanPos + 1
    If startBoundary > i Then Return 0
    Dim candidate As String = Mid(s, startBoundary, i - startBoundary + 1)
    If Len(Trim(candidate)) = 0 Then Return 0

    Dim pieces() As String
    Dim pieceCount As Integer = 0
    SplitTopLevelArgs(candidate, pieces(), pieceCount)
    If pieceCount = 0 Then Return 0

    Dim k As Integer
    For k = 1 To pieceCount
        Dim piece As String = Trim(pieces(k))
        If Len(piece) = 0 Then Return 0
        If IsIdentStartChar(Asc(Left(piece, 1))) = 0 Then Return 0
        Dim pi As Integer
        For pi = 2 To Len(piece)
            Dim pc As String = Mid(piece, pi, 1)
            If IsIdentBodyChar(Asc(pc)) = 0 And pc <> "$" And pc <> "%" And pc <> "!" And pc <> "#" Then Return 0
        Next pi
    Next k

    captureCount = pieceCount
    ReDim captureVars(1 To pieceCount)
    For k = 1 To pieceCount
        captureVars(k) = Trim(pieces(k))
    Next k

    Return startBoundary
End Function

' Monta o texto de substituicao de uma chamada .nome(args), incluindo
' atribuicao de argumentos, o GOSUB {rotulo} e atribuicao dos retornos
' capturados - evita "X=X" quando o valor ja e' o mesmo (mesma regra do
' paleobasic, pra nao gerar atribuicoes inuteis quando quem chama usa os
' mesmos nomes de variavel da definicao).
Private Function BuildFuncCallReplacement(ByRef fname As String, callArgs() As String, ByVal callArgCount As Integer, captureVars() As String, ByVal captureCount As Integer, funcs() As FuncEntry, ByVal funcCount As Integer, ByRef currentNs As String, ByRef errMsg As String) As String
    Dim fIdx As Integer = ResolveFuncIndex(funcs(), funcCount, currentNs, fname)
    If fIdx <= 0 Then
        errMsg = "Funcao nao definida: ." & fname
        Return ""
    End If

    Dim paramList As String = funcs(fIdx).paramList
    Dim defaultList As String = funcs(fIdx).defaultList
    Dim retList As String = funcs(fIdx).retList

    Dim nParams As Integer = 0
    If Len(paramList) > 0 Then nParams = CountChar(paramList, ";") + 1

    If callArgCount > nParams Then
        errMsg = "Chamada com argumentos demais: ." & fname
        Return ""
    End If

    Dim result As String = ""
    Dim k As Integer
    For k = 1 To nParams
        Dim pname As String = FieldSemicolon(paramList, k)
        Dim pdefault As String = FieldSemicolon(defaultList, k)
        Dim callVal As String = ""
        If k <= callArgCount Then callVal = callArgs(k)

        If Len(Trim(callVal)) > 0 Then
            If Trim(callVal) <> Trim(pname) Then result &= pname & "=" & callVal & ":"
        ElseIf Len(Trim(pdefault)) > 0 Then
            If Trim(pdefault) <> Trim(pname) Then result &= pname & "=" & pdefault & ":"
        End If
    Next k

    result &= "GOSUB {" & FuncLabelName(fname) & "}"

    Dim nRets As Integer = 0
    If Len(retList) > 0 Then nRets = CountChar(retList, ";") + 1
    For k = 1 To captureCount
        If k <= nRets Then
            Dim rexpr As String = FieldSemicolon(retList, k)
            If Trim(rexpr) <> Trim(captureVars(k)) Then result &= ":" & captureVars(k) & "=" & rexpr
        End If
    Next k

    Return result
End Function

' Varre uma linha INTEIRA (precisa ver a linha toda, nao um pedaco - os
' argumentos da chamada podem conter literais de string que quebrariam o
' casamento de parenteses se so' enxergasse um trecho) procurando chamadas
' .nome(args), com captura opcional de retorno "var1,var2 = .nome(args)"
' logo antes. Tem sua propria consciencia de string/comentario/DATA.
Private Function ExpandFuncCallsInLine(ByRef lineText As String, funcs() As FuncEntry, ByVal funcCount As Integer, ByRef currentNs As String, ByRef errMsg As String) As String
    Dim outText As String = ""
    Dim scanCharPos As Integer = 1
    Dim inQuote As Integer = 0
    Dim n As Integer = Len(lineText)

    While scanCharPos <= n
        Dim ch As String = Mid(lineText, scanCharPos, 1)

        If ch = Chr(34) Then
            inQuote = Not inQuote
            outText &= ch
            scanCharPos += 1
            Continue While
        End If

        If inQuote = 0 Then
            If ch = "'" Then
                outText &= Mid(lineText, scanCharPos)
                Exit While
            End If

            Dim boundaryBefore As Integer = (scanCharPos = 1) Or (IsIdentBodyChar(Asc(Mid(lineText, scanCharPos - 1, 1))) = 0)
            If boundaryBefore <> 0 And UCase(Mid(lineText, scanCharPos, 3)) = "REM" And IsIdentBodyChar(Asc(Mid(lineText, scanCharPos + 3, 1))) = 0 Then
                outText &= Mid(lineText, scanCharPos)
                Exit While
            End If
            If boundaryBefore <> 0 And UCase(Mid(lineText, scanCharPos, 4)) = "DATA" And IsIdentBodyChar(Asc(Mid(lineText, scanCharPos + 4, 1))) = 0 Then
                Dim dEnd As Integer = InStr(scanCharPos, lineText, ":")
                If dEnd = 0 Then dEnd = n + 1
                outText &= Mid(lineText, scanCharPos, dEnd - scanCharPos)
                scanCharPos = dEnd
                Continue While
            End If

            If ch = "." And IsIdentStartChar(Asc(Mid(lineText, scanCharPos + 1, 1))) <> 0 Then
                Dim np As Integer = scanCharPos + 1
                While np <= n AndAlso IsIdentBodyChar(Asc(Mid(lineText, np, 1))) <> 0
                    np += 1
                Wend
                If Mid(lineText, np, 1) = "(" Then
                    Dim fname As String = Mid(lineText, scanCharPos + 1, np - scanCharPos - 1)
                    Dim closeParen As Integer = FindMatchingParenPos(lineText, np)
                    If closeParen = 0 Then
                        errMsg = "Parenteses nao fechados na chamada: ." & fname
                        Return outText
                    End If

                    Dim callArgs() As String
                    Dim callArgCount As Integer = 0
                    SplitTopLevelArgs(Mid(lineText, np + 1, closeParen - np - 1), callArgs(), callArgCount)

                    Dim captureVars() As String
                    Dim captureCount As Integer = 0
                    Dim capStart As Integer = TryExtractCaptureVars(outText, captureVars(), captureCount)
                    If capStart > 0 Then outText = Left(outText, capStart - 1)

                    Dim replacement As String = BuildFuncCallReplacement(fname, callArgs(), callArgCount, captureVars(), captureCount, funcs(), funcCount, currentNs, errMsg)
                    If Len(errMsg) > 0 Then Return outText
                    outText &= replacement

                    scanCharPos = closeParen + 1
                    Continue While
                End If
            End If
        End If

        outText &= ch
        scanCharPos += 1
    Wend

    Return outText
End Function

Private Function PreprocessDignified(ByRef sourceText As String, ByRef srcPath As String, ByRef outAmxText As String, ByRef outAmxOverride As String, ByRef errMsg As String) As Integer
    errMsg = ""
    outAmxText = ""
    outAmxOverride = ""

    Dim lineStart As Integer = IntSetting("cfg.badig.line_start", 10, 1, 65535)
    Dim lineStep As Integer = IntSetting("cfg.badig.line_step", 10, 1, 9999)
    Dim stripSpaces As Integer = IsTrueSetting("cfg.badig.strip_spaces", 0)
    Dim uppercaseAll As Integer = IsTrueSetting("cfg.badig.capitalize_all", 0)
    Dim remHeaderText As String = Trim(DbGetSetting("cfg.badig.rem_header", ""))
    Dim useRemHeader As Integer = 0
    Dim convertPrintMode As String = NormalizeConvertPrintMode(DbGetSetting("cfg.msxbasic.badig.convert_print", ""))
    Dim ifJumpMode As String = NormalizeIfJumpMode(DbGetSetting("cfg.msxbasic.badig.strip_then_goto", ""))
    Dim currentNs As String = UCase(ToAbsolutePathLocal(CurDir(), srcPath))

    Dim includeStack() As String
    Dim stackCount As Integer = 1
    ReDim includeStack(1 To 1)
    includeStack(1) = srcPath

    Dim expandedSource As String
    If ExpandIncludesText(srcPath, sourceText, expandedSource, errMsg, includeStack(), stackCount) = 0 Then Return 0

    Dim defs() As DefineEntry
    Dim defCount As Integer = 0

    Dim funcs() As FuncEntry
    Dim funcCount As Integer = 0
    Dim inFuncName As String = ""
    Dim inFuncScopedKey As String = ""

    Dim stmts() As ProcLine
    Dim stmtCount As Integer = 0

    Dim varMap() As VarMapEntry
    Dim varMapCount As Integer = 0
    Dim keepLongKeys() As String
    Dim keepLongCount As Integer = 0
    Dim reservedShortVals() As String
    Dim reservedShortCount As Integer = 0
    Dim longVarKeys() As String
    Dim longVarCount As Integer = 0

    Dim labels() As LabelMap
    Dim labelCount As Integer = 0

    Dim loopStack() As LoopState
    Dim loopTop As Integer = 0
    Dim nextLoopId As Integer = 1
    Dim loopExitTarget() As Integer
    ReDim loopExitTarget(1 To 1)

    Dim pendingLabels() As String
    Dim pendingCount As Integer = 0

    Dim posStart As Integer = 1
    Dim normalized As String = JoinContinuationLines(StripCR(expandedSource))

    While posStart <= Len(normalized)
        Dim br As Integer = InStr(posStart, normalized, Chr(10))
        Dim oneLine As String
        If br = 0 Then
            oneLine = Mid(normalized, posStart)
            posStart = Len(normalized) + 1
        Else
            oneLine = Mid(normalized, posStart, br - posStart)
            posStart = br + 1
        End If

        Dim t As String = Trim(oneLine)
        If Len(t) = 0 Then Continue While

        Dim upperT As String = UCase(t)

        If Left(upperT, 5) = "##BB:" Then
            Dim payload As String = Trim(Mid(t, 6))
            Dim eqPos As Integer = InStr(payload, "=")
            If eqPos > 0 Then
                Dim rk As String = LCase(Trim(Left(payload, eqPos - 1)))
                Dim rv As String = Trim(Mid(payload, eqPos + 1))
                If rk = "ns" Then
                    If Len(rv) > 0 Then currentNs = UCase(rv)
                ElseIf rk = "export_file" Then
                    If Len(rv) > 0 Then
                        outAmxOverride = ToAbsolutePathLocal(PathDir(srcPath), rv)
                    End If
                ElseIf rk = "arguments" Then
                    Dim args As String = " " & rv & " "
                    Dim p As Integer
                    p = InStr(args, " -ss ")
                    If p > 0 Then stripSpaces = -1
                    p = InStr(args, " -ca ")
                    If p > 0 Then uppercaseAll = -1

                    p = InStr(args, " -rh ")
                    If p > 0 Then useRemHeader = -1

                    p = InStr(args, " -ls ")
                    If p > 0 Then
                        Dim tail As String = Mid(args, p + 5)
                        lineStart = ValInt(Trim(tail))
                        If lineStart < 1 Then lineStart = 1
                    End If

                    p = InStr(args, " -lp ")
                    If p > 0 Then
                        Dim tail2 As String = Mid(args, p + 5)
                        lineStep = ValInt(Trim(tail2))
                        If lineStep < 1 Then lineStep = 1
                    End If
                ElseIf rk = "help" Then
                    ' Mantem compatibilidade de parsing de remtag sem alterar pipeline.
                End If
            End If
            Continue While
        End If

        If Left(t, 2) = "##" Then Continue While

        Dim parseLine As String = t
        If UCase(Left(parseLine, 6)) = "DEFINE" Then
            Dim body As String = Trim(Mid(parseLine, 7))
            If Len(body) > 0 Then
                Dim items() As String
                Dim itemCount As Integer = 0
                Dim depth As Integer = 0
                Dim chunk As String = ""
                Dim di As Integer
                For di = 1 To Len(body)
                    Dim dch As String = Mid(body, di, 1)
                    If dch = "[" Then
                        depth += 1
                        chunk &= dch
                    ElseIf dch = "]" Then
                        If depth > 0 Then depth -= 1
                        chunk &= dch
                    ElseIf dch = "," And depth = 0 Then
                        itemCount += 1
                        ReDim Preserve items(1 To itemCount)
                        items(itemCount) = Trim(chunk)
                        chunk = ""
                    Else
                        chunk &= dch
                    End If
                Next di
                If Len(Trim(chunk)) > 0 Then
                    itemCount += 1
                    ReDim Preserve items(1 To itemCount)
                    items(itemCount) = Trim(chunk)
                End If

                For di = 1 To itemCount
                    Dim one As String = items(di)
                    Dim p1 As Integer = InStr(one, "[")
                    Dim p2 As Integer = InStr(p1 + 1, one, "]")
                    Dim p3 As Integer = InStr(p2 + 1, one, "[")
                    Dim p4 As Integer = InStr(p3 + 1, one, "]")
                    If p1 > 0 And p2 > p1 And p3 > p2 And p4 > p3 Then
                        Dim dName As String = Mid(one, p1 + 1, p2 - p1 - 1)
                        Dim dContent As String = Mid(one, p3 + 1, p4 - p3 - 1)
                        UpsertDefine(defs(), defCount, ScopedName(currentNs, dName), dContent)
                    End If
                Next di
            End If
            Continue While
        End If

        If UCase(Left(parseLine, 7)) = "DECLARE" And (Len(parseLine) = 7 Or IsIdentBodyChar(Asc(Mid(parseLine, 8, 1))) = 0) Then
            Dim declBody As String = Trim(Mid(parseLine, 8))
            If ProcessDeclareLine(declBody, currentNs, varMap(), varMapCount, keepLongKeys(), keepLongCount, reservedShortVals(), reservedShortCount, errMsg) = 0 Then
                Return 0
            End If
            Continue While
        End If

        t = ApplyDefinesRecursiveScoped(t, defs(), defCount, currentNs)
        t = Trim(t)
        If Len(t) = 0 Then Continue While

        If Left(UCase(t), 5) = "FUNC " Then
            If Len(inFuncName) > 0 Then
                errMsg = "Ja dentro de uma funcao: " & inFuncName
                Return 0
            End If

            Dim frest As String = Trim(Mid(t, 5))
            If Left(frest, 1) <> "." Then
                errMsg = "Nome de funcao invalido: " & frest
                Return 0
            End If

            Dim fparenPos As Integer = InStr(frest, "(")
            If fparenPos = 0 Then
                errMsg = "Funcao sem parenteses: " & frest
                Return 0
            End If

            Dim fname As String = Trim(Mid(frest, 2, fparenPos - 2))
            If IsValidLabelName(fname) = 0 Then
                errMsg = "Nome de funcao invalido: " & fname
                Return 0
            End If

            Dim fcloseParen As Integer = FindMatchingParenPos(frest, fparenPos)
            If fcloseParen = 0 Then
                errMsg = "Parenteses nao fechados na funcao: " & fname
                Return 0
            End If

            If Len(Trim(Mid(frest, fcloseParen + 1))) > 0 Then
                errMsg = "Conteudo apos 'func .nome(...)' na mesma linha nao suportado: " & fname
                Return 0
            End If

            Dim fScopedKey As String = ScopedName(currentNs, fname)
            If FindFuncIndex(funcs(), funcCount, fScopedKey) > 0 Then
                errMsg = "Funcao duplicada: " & fname
                Return 0
            End If

            Dim fargItems() As String
            Dim fargCount As Integer = 0
            SplitTopLevelArgs(Mid(frest, fparenPos + 1, fcloseParen - fparenPos - 1), fargItems(), fargCount)

            Dim fParamList As String = ""
            Dim fDefaultList As String = ""
            Dim fai As Integer
            For fai = 1 To fargCount
                Dim fargText As String = fargItems(fai)
                Dim feqPos As Integer = InStr(fargText, "=")
                Dim fpname As String
                Dim fpdefault As String
                If feqPos > 0 Then
                    fpname = Trim(Left(fargText, feqPos - 1))
                    fpdefault = Trim(Mid(fargText, feqPos + 1))
                Else
                    fpname = Trim(fargText)
                    fpdefault = ""
                End If
                If Len(fpname) = 0 Then
                    errMsg = "Argumento de funcao invalido: " & fargText
                    Return 0
                End If
                If Len(fParamList) > 0 Then
                    fParamList &= ";"
                    fDefaultList &= ";"
                End If
                fParamList &= fpname
                fDefaultList &= fpdefault
            Next fai

            funcCount += 1
            ReDim Preserve funcs(1 To funcCount)
            funcs(funcCount).nameKey = fScopedKey
            funcs(funcCount).bareUpper = UCase(fname)
            funcs(funcCount).paramList = fParamList
            funcs(funcCount).defaultList = fDefaultList
            funcs(funcCount).retList = ""

            inFuncName = fname
            inFuncScopedKey = fScopedKey

            pendingCount += 1
            ReDim Preserve pendingLabels(1 To pendingCount)
            pendingLabels(pendingCount) = ScopedName(currentNs, FuncLabelName(fname))

            Continue While
        End If

        Dim retColonPos As Integer = FindLastTopLevelColonPos(t)
        Dim retTail As String = t
        Dim retPrefix As String = ""
        If retColonPos > 0 Then
            retPrefix = Left(t, retColonPos)
            retTail = Trim(Mid(t, retColonPos + 1))
        End If

        If FirstWordUpper(retTail) = "RET" Then
            If Len(inFuncName) = 0 Then
                errMsg = "RET sem FUNC correspondente."
                Return 0
            End If

            Dim rrest As String = Trim(Mid(retTail, 4))
            Dim fRetItems() As String
            Dim fRetCount As Integer = 0
            SplitTopLevelArgs(rrest, fRetItems(), fRetCount)

            Dim fRetList As String = ""
            Dim fri As Integer
            For fri = 1 To fRetCount
                If Len(fRetList) > 0 Then fRetList &= ";"
                fRetList &= fRetItems(fri)
            Next fri

            Dim fRetIdx As Integer = FindFuncIndex(funcs(), funcCount, inFuncScopedKey)
            If fRetIdx > 0 Then funcs(fRetIdx).retList = fRetList

            inFuncName = ""
            inFuncScopedKey = ""

            t = Trim(retPrefix & "RETURN")
        End If

        Do While Left(t, 1) = "{" And InStr(t, "}") > 1
            Dim p2 As Integer = InStr(t, "}")
            Dim lbl As String = Mid(t, 2, p2 - 2)
            If IsValidLabelName(lbl) = 0 Then
                errMsg = "Label invalido: " & lbl
                Return 0
            End If
            pendingCount += 1
            ReDim Preserve pendingLabels(1 To pendingCount)
            pendingLabels(pendingCount) = ScopedName(currentNs, lbl)
            t = Trim(Mid(t, p2 + 1))
            If Len(t) > 0 And Left(t, 1) = ":" Then t = Trim(Mid(t, 2))
        Loop

        If Len(t) = 0 Then Continue While

        If Right(t, 1) = "{" Then
            Dim loopLbl As String = Trim(Left(t, Len(t) - 1))
            If IsValidLabelName(loopLbl) = 0 Then
                errMsg = "Loop label invalido: " & loopLbl
                Return 0
            End If

            pendingCount += 1
            ReDim Preserve pendingLabels(1 To pendingCount)
            pendingLabels(pendingCount) = ScopedName(currentNs, loopLbl)

            loopTop += 1
            ReDim Preserve loopStack(1 To loopTop)
            loopStack(loopTop).loopId = nextLoopId
            loopStack(loopTop).labelName = ScopedName(currentNs, loopLbl)

            If nextLoopId > UBound(loopExitTarget) Then ReDim Preserve loopExitTarget(1 To nextLoopId)
            loopExitTarget(nextLoopId) = 0
            nextLoopId += 1
            Continue While
        End If

        Dim stmt As ProcLine
        stmt.kind = STMT_NORMAL
        stmt.loopId = IIf(loopTop > 0, loopStack(loopTop).loopId, 0)
        stmt.labelTarget = ""
        stmt.nsKey = currentNs

        If t = "}" Then
            If loopTop <= 0 Then
                errMsg = "Fechamento de loop sem abertura."
                Return 0
            End If
            stmt.kind = STMT_GOTO_LABEL
            stmt.labelTarget = loopStack(loopTop).labelName
        ElseIf LCase(t) = "exit" Then
            If loopTop <= 0 Then
                errMsg = "exit fora de loop."
                Return 0
            End If
            stmt.kind = STMT_EXIT_LOOP
            stmt.loopId = loopStack(loopTop).loopId
        Else
            stmt.text = t
        End If

        stmtCount += 1
        ReDim Preserve stmts(1 To stmtCount)
        stmts(stmtCount) = stmt

        Dim i As Integer
        If pendingCount > 0 Then
            For i = 1 To pendingCount
                Dim keyLbl As String = pendingLabels(i)
                If FindLabelIndex(labels(), labelCount, keyLbl) > 0 Then
                    errMsg = "Label duplicado: " & keyLbl
                    Return 0
                End If
                labelCount += 1
                ReDim Preserve labels(1 To labelCount)
                labels(labelCount).nameKey = keyLbl
                labels(labelCount).stmtIndex = stmtCount
            Next i
            pendingCount = 0
            Erase pendingLabels
        End If

        If t = "}" Then
            loopExitTarget(loopStack(loopTop).loopId) = stmtCount + 1
            loopTop -= 1
            If loopTop > 0 Then
                ReDim Preserve loopStack(1 To loopTop)
            Else
                Erase loopStack
            End If
        End If
    Wend

    If loopTop > 0 Then
        errMsg = "Ha loop labels sem fechamento."
        Return 0
    End If

    If Len(inFuncName) > 0 Then
        errMsg = "Funcao sem RET: " & inFuncName
        Return 0
    End If

    If pendingCount > 0 Then
        errMsg = "Label no final sem comando associado."
        Return 0
    End If

    If stmtCount <= 0 Then
        errMsg = "Fonte vazia apos preprocessamento."
        Return 0
    End If

    ' Chamadas .nome(args) sao expandidas so' AGORA, depois que o loop acima
    ' inteiro ja' rodou - assim uma funcao pode ser chamada ANTES do seu
    ' proprio "func .nome(...)" aparecer no texto (ex.: NestorBASIC e'
    ' include"ado no topo do arquivo e chamado bem mais abaixo, mas o
    ' exemplo oficial do Basic Dignified tambem chama a funcao ANTES dela
    ' mesma, deixando a definicao "no fim, num ponto inalcancavel do
    ' codigo" - ver BASIC_DIGNIFIED.md). Se a expansao rodasse dentro do
    ' loop principal, uma chamada so' acharia funcoes ja' registradas ATE'
    ' aquele ponto do arquivo.
    Dim fcs As Integer
    For fcs = 1 To stmtCount
        If stmts(fcs).kind = STMT_NORMAL Then
            stmts(fcs).text = ExpandFuncCallsInLine(stmts(fcs).text, funcs(), funcCount, stmts(fcs).nsKey, errMsg)
            If Len(errMsg) > 0 Then Return 0
        End If
    Next fcs

    CollectVariableUsage(stmts(), stmtCount, keepLongKeys(), keepLongCount, reservedShortVals(), reservedShortCount, longVarKeys(), longVarCount)
    AssignShortNames(longVarKeys(), longVarCount, keepLongKeys(), keepLongCount, reservedShortVals(), reservedShortCount, varMap(), varMapCount)

    Dim stmtLineNos(1 To stmtCount) As Integer
    Dim i As Integer
    For i = 1 To stmtCount
        stmtLineNos(i) = lineStart + (i - 1) * lineStep
    Next i

    Dim outCount As Integer = 0
    For i = 1 To stmtCount
        Dim body As String = ""
        If stmts(i).kind = STMT_GOTO_LABEL Then
            Dim idx As Integer = FindLabelIndex(labels(), labelCount, stmts(i).labelTarget)
            If idx <= 0 Then
                errMsg = "Loop label inexistente: " & stmts(i).labelTarget
                Return 0
            End If
            body = "GOTO " & Trim(Str(stmtLineNos(labels(idx).stmtIndex)))
        ElseIf stmts(i).kind = STMT_EXIT_LOOP Then
            If stmts(i).loopId <= 0 Or stmts(i).loopId > UBound(loopExitTarget) Then
                errMsg = "exit com loop invalido."
                Return 0
            End If
            Dim targetStmt As Integer = loopExitTarget(stmts(i).loopId)
            If targetStmt <= 0 Or targetStmt > stmtCount Then
                errMsg = "exit sem destino de fechamento."
                Return 0
            End If
            body = "GOTO " & Trim(Str(stmtLineNos(targetStmt)))
        Else
            body = ResolveLabelRefs(stmts(i).text, i, stmtLineNos(), labels(), labelCount, stmts(i).nsKey, errMsg)
            If Len(errMsg) > 0 Then Return 0
            If stmts(i).loopId > 0 Then
                If stmts(i).loopId > UBound(loopExitTarget) Then
                    errMsg = "exit com loop invalido."
                    Return 0
                End If
                Dim targetStmt As Integer = loopExitTarget(stmts(i).loopId)
                If targetStmt <= 0 Or targetStmt > stmtCount Then
                    errMsg = "exit sem destino de fechamento."
                    Return 0
                End If
                body = RewriteInlineExitForLoop(body, stmtLineNos(targetStmt))
            End If
        End If

        body = SubstituteVariables(body, stmts(i).nsKey, varMap(), varMapCount)

        ' ConvertPrintByMode/RewriteIfThenGotoByMode precisam rodar ANTES do
        ' strip - elas reconhecem PRINT/THEN/GOTO exigindo um limite
        ' nao-alfanumerico dos dois lados (IsTokenBoundaryAt), pra nao
        ' confundir a keyword com um pedaco de identificador. Depois de
        ' stripado tudo fica colado (ex.: "IFXTHENGOTO100") e essa deteccao
        ' de limite quebraria - por isso o strip e' sempre o ULTIMO passo.
        body = ConvertPrintByMode(body, convertPrintMode)
        body = RewriteIfThenGotoByMode(body, ifJumpMode)
        If stripSpaces <> 0 Then body = StripSpacesOutsideStrings(body)
        If uppercaseAll <> 0 Then body = UCase(body)

        Dim outLine As String = Trim(Str(stmtLineNos(i))) & " " & body
        If outCount > 0 Then outAmxText &= Chr(13) & Chr(10)
        outAmxText &= outLine
        outCount += 1
    Next i

    If useRemHeader <> 0 And Len(remHeaderText) > 0 Then
        ' Remtag reconhecida; efeito textual completo sera aplicado em evolucao futura.
    End If

    Return -1
End Function

Private Sub InitKeywordTable()
    If gKeywordInit <> 0 Then Exit Sub

    gKeywordCount = 0

    #Macro ADDTOK(textValue, tokenHexValue, jumpFlag, literalFlag)
        gKeywordCount += 1
        gKeywords(gKeywordCount).kw = textValue
        gKeywords(gKeywordCount).tokHex = tokenHexValue
        gKeywords(gKeywordCount).tokData = HexToBin(tokenHexValue)
        gKeywords(gKeywordCount).isJump = jumpFlag
        gKeywords(gKeywordCount).literalMode = literalFlag
    #EndMacro

    ADDTOK(">", "ee", 0, TOK_LITERAL_NONE)
    ADDTOK("PAINT", "bf", 0, TOK_LITERAL_NONE)
    ADDTOK("=", "ef", 0, TOK_LITERAL_NONE)
    ADDTOK("ERROR", "a6", 0, TOK_LITERAL_NONE)
    ADDTOK("ERR", "e2", 1, TOK_LITERAL_NONE)
    ADDTOK("<", "f0", 0, TOK_LITERAL_NONE)
    ADDTOK("+", "f1", 0, TOK_LITERAL_NONE)
    ADDTOK("FIELD", "b1", 0, TOK_LITERAL_NONE)
    ADDTOK("PLAY", "c1", 0, TOK_LITERAL_NONE)
    ADDTOK("-", "f2", 0, TOK_LITERAL_NONE)
    ADDTOK("FILES", "b7", 0, TOK_LITERAL_NONE)
    ADDTOK("POINT", "ed", 0, TOK_LITERAL_NONE)
    ADDTOK("*", "f3", 0, TOK_LITERAL_NONE)
    ADDTOK("POKE", "98", 0, TOK_LITERAL_NONE)
    ADDTOK("/", "f4", 0, TOK_LITERAL_NONE)
    ADDTOK("FN", "de", 0, TOK_LITERAL_NONE)
    ADDTOK("^", "f5", 0, TOK_LITERAL_NONE)
    ADDTOK("FOR", "82", 0, TOK_LITERAL_NONE)
    ADDTOK("PRESET", "c3", 0, TOK_LITERAL_NONE)
    ADDTOK("\\", "fc", 0, TOK_LITERAL_NONE)
    ADDTOK("PRINT", "91", 0, TOK_LITERAL_NONE)
    ADDTOK("?", "91", 0, TOK_LITERAL_NONE)
    ADDTOK("PSET", "c2", 0, TOK_LITERAL_NONE)
    ADDTOK("AND", "f6", 0, TOK_LITERAL_NONE)
    ADDTOK("GET", "b2", 0, TOK_LITERAL_NONE)
    ADDTOK("PUT", "b3", 0, TOK_LITERAL_NONE)
    ADDTOK("GOSUB", "8d", 1, TOK_LITERAL_NONE)
    ADDTOK("READ", "87", 0, TOK_LITERAL_NONE)
    ADDTOK("GOTO", "89", 1, TOK_LITERAL_NONE)
    ADDTOK("ATTR$", "e9", 0, TOK_LITERAL_NONE)
    ADDTOK("RENUM", "aa", 1, TOK_LITERAL_NONE)
    ADDTOK("AUTO", "a9", 1, TOK_LITERAL_NONE)
    ADDTOK("IF", "8b", 0, TOK_LITERAL_NONE)
    ADDTOK("RESTORE", "8c", 1, TOK_LITERAL_NONE)
    ADDTOK("BASE", "c9", 0, TOK_LITERAL_NONE)
    ADDTOK("IMP", "fa", 0, TOK_LITERAL_NONE)
    ADDTOK("RESUME", "a7", 1, TOK_LITERAL_NONE)
    ADDTOK("BEEP", "c0", 0, TOK_LITERAL_NONE)
    ADDTOK("INKEY$", "ec", 0, TOK_LITERAL_NONE)
    ADDTOK("RETURN", "8e", 1, TOK_LITERAL_NONE)
    ADDTOK("BLOAD", "cf", 0, TOK_LITERAL_NONE)
    ADDTOK("INPUT", "85", 0, TOK_LITERAL_NONE)
    ADDTOK("BSAVE", "d0", 0, TOK_LITERAL_NONE)
    ADDTOK("INSTR", "e5", 0, TOK_LITERAL_NONE)
    ADDTOK("RSET", "b9", 0, TOK_LITERAL_NONE)
    ADDTOK("CALL", "ca", 0, TOK_LITERAL_DATA_REM)
    ADDTOK("_", "5f", 0, TOK_LITERAL_DATA_REM)
    ADDTOK("RUN", "8a", 1, TOK_LITERAL_NONE)
    ADDTOK("IPL", "d5", 0, TOK_LITERAL_NONE)
    ADDTOK("SAVE", "ba", 0, TOK_LITERAL_NONE)
    ADDTOK("KEY", "cc", 0, TOK_LITERAL_NONE)
    ADDTOK("SCREEN", "c5", 0, TOK_LITERAL_NONE)
    ADDTOK("KILL", "d4", 0, TOK_LITERAL_NONE)
    ADDTOK("SET", "d2", 0, TOK_LITERAL_NONE)
    ADDTOK("CIRCLE", "bc", 0, TOK_LITERAL_NONE)
    ADDTOK("CLEAR", "92", 0, TOK_LITERAL_NONE)
    ADDTOK("CLOAD", "9b", 0, TOK_LITERAL_NONE)
    ADDTOK("LET", "88", 0, TOK_LITERAL_NONE)
    ADDTOK("SOUND", "c4", 0, TOK_LITERAL_NONE)
    ADDTOK("CLOSE", "b4", 0, TOK_LITERAL_NONE)
    ADDTOK("LFILES", "bb", 0, TOK_LITERAL_NONE)
    ADDTOK("CLS", "9f", 0, TOK_LITERAL_NONE)
    ADDTOK("LINE", "af", 0, TOK_LITERAL_NONE)
    ADDTOK("SPC(", "df", 0, TOK_LITERAL_NONE)
    ADDTOK("CMD", "d7", 0, TOK_LITERAL_NONE)
    ADDTOK("LIST", "93", 1, TOK_LITERAL_NONE)
    ADDTOK("SPRITE", "c7", 0, TOK_LITERAL_NONE)
    ADDTOK("COLOR", "bd", 0, TOK_LITERAL_NONE)
    ADDTOK("LLIST", "9e", 1, TOK_LITERAL_NONE)
    ADDTOK("CONT", "99", 0, TOK_LITERAL_NONE)
    ADDTOK("LOAD", "b5", 0, TOK_LITERAL_NONE)
    ADDTOK("STEP", "dc", 0, TOK_LITERAL_NONE)
    ADDTOK("COPY", "d6", 0, TOK_LITERAL_NONE)
    ADDTOK("LOCATE", "d8", 0, TOK_LITERAL_NONE)
    ADDTOK("STOP", "90", 0, TOK_LITERAL_NONE)
    ADDTOK("CSAVE", "9a", 0, TOK_LITERAL_NONE)
    ADDTOK("CSRLIN", "e8", 0, TOK_LITERAL_NONE)
    ADDTOK("STRING$", "e3", 0, TOK_LITERAL_NONE)
    ADDTOK("LPRINT", "9d", 0, TOK_LITERAL_NONE)
    ADDTOK("SWAP", "a4", 0, TOK_LITERAL_NONE)
    ADDTOK("LSET", "b8", 0, TOK_LITERAL_NONE)
    ADDTOK("TAB(", "db", 0, TOK_LITERAL_NONE)
    ADDTOK("MAX", "cd", 0, TOK_LITERAL_NONE)
    ADDTOK("DATA", "84", 0, TOK_LITERAL_DATA_REM)
    ADDTOK("MERGE", "b6", 0, TOK_LITERAL_NONE)
    ADDTOK("THEN", "da", 1, TOK_LITERAL_NONE)
    ADDTOK("TIME", "cb", 0, TOK_LITERAL_NONE)
    ADDTOK("TO", "d9", 0, TOK_LITERAL_NONE)
    ADDTOK("DEFDBL", "ae", 0, TOK_LITERAL_NONE)
    ADDTOK("DEFINT", "ac", 0, TOK_LITERAL_NONE)
    ADDTOK("DEFSTR", "ab", 0, TOK_LITERAL_NONE)
    ADDTOK("TROFF", "a3", 0, TOK_LITERAL_NONE)
    ADDTOK("DEFSNG", "ad", 0, TOK_LITERAL_NONE)
    ADDTOK("TRON", "a2", 0, TOK_LITERAL_NONE)
    ADDTOK("DEF", "97", 0, TOK_LITERAL_NONE)
    ADDTOK("MOD", "fb", 0, TOK_LITERAL_NONE)
    ADDTOK("USING", "e4", 0, TOK_LITERAL_NONE)
    ADDTOK("DELETE", "a8", 1, TOK_LITERAL_NONE)
    ADDTOK("MOTOR", "ce", 0, TOK_LITERAL_NONE)
    ADDTOK("USR", "dd", 0, TOK_LITERAL_NONE)
    ADDTOK("DIM", "86", 0, TOK_LITERAL_NONE)
    ADDTOK("NAME", "d3", 0, TOK_LITERAL_NONE)
    ADDTOK("DRAW", "be", 0, TOK_LITERAL_NONE)
    ADDTOK("NEW", "94", 0, TOK_LITERAL_NONE)
    ADDTOK("VARPTR", "e7", 0, TOK_LITERAL_NONE)
    ADDTOK("NEXT", "83", 0, TOK_LITERAL_NONE)
    ADDTOK("VDP", "c8", 0, TOK_LITERAL_NONE)
    ADDTOK("DSKI$", "ea", 0, TOK_LITERAL_NONE)
    ADDTOK("NOT", "e0", 0, TOK_LITERAL_NONE)
    ADDTOK("DSKO$", "d1", 0, TOK_LITERAL_NONE)
    ADDTOK("VPOKE", "c6", 0, TOK_LITERAL_NONE)
    ADDTOK("OFF", "eb", 0, TOK_LITERAL_NONE)
    ADDTOK("WAIT", "96", 0, TOK_LITERAL_NONE)
    ADDTOK("END", "81", 0, TOK_LITERAL_NONE)
    ADDTOK("ON", "95", 0, TOK_LITERAL_NONE)
    ADDTOK("WIDTH", "a0", 0, TOK_LITERAL_NONE)
    ADDTOK("OPEN", "b0", 0, TOK_LITERAL_NONE)
    ADDTOK("XOR", "f8", 0, TOK_LITERAL_NONE)
    ADDTOK("EQV", "f9", 0, TOK_LITERAL_NONE)
    ADDTOK("OR", "f7", 0, TOK_LITERAL_NONE)
    ADDTOK("ERASE", "a5", 0, TOK_LITERAL_NONE)
    ADDTOK("OUT", "9c", 0, TOK_LITERAL_NONE)
    ADDTOK("ERL", "e1", 1, TOK_LITERAL_NONE)
    ADDTOK("REM", "8f", 0, TOK_LITERAL_DATA_REM)

    ADDTOK("PDL", "ffa4", 0, TOK_LITERAL_NONE)
    ADDTOK("EXP", "ff8b", 0, TOK_LITERAL_NONE)
    ADDTOK("PEEK", "ff97", 0, TOK_LITERAL_NONE)
    ADDTOK("FIX", "ffa1", 0, TOK_LITERAL_NONE)
    ADDTOK("POS", "ff91", 0, TOK_LITERAL_NONE)
    ADDTOK("FPOS", "ffa7", 0, TOK_LITERAL_NONE)
    ADDTOK("ABS", "ff86", 0, TOK_LITERAL_NONE)
    ADDTOK("FRE", "ff8f", 0, TOK_LITERAL_NONE)
    ADDTOK("ASC", "ff95", 0, TOK_LITERAL_NONE)
    ADDTOK("ATN", "ff8e", 0, TOK_LITERAL_NONE)
    ADDTOK("HEX$", "ff9b", 0, TOK_LITERAL_NONE)
    ADDTOK("BIN$", "ff9d", 0, TOK_LITERAL_NONE)
    ADDTOK("INP", "ff90", 0, TOK_LITERAL_NONE)
    ADDTOK("RIGHT$", "ff82", 0, TOK_LITERAL_NONE)
    ADDTOK("RND", "ff88", 0, TOK_LITERAL_NONE)
    ADDTOK("INT", "ff85", 0, TOK_LITERAL_NONE)
    ADDTOK("CDBL", "ffa0", 0, TOK_LITERAL_NONE)
    ADDTOK("CHR$", "ff96", 0, TOK_LITERAL_NONE)
    ADDTOK("CINT", "ff9e", 0, TOK_LITERAL_NONE)
    ADDTOK("LEFT$", "ff81", 0, TOK_LITERAL_NONE)
    ADDTOK("SGN", "ff84", 0, TOK_LITERAL_NONE)
    ADDTOK("LEN", "ff92", 0, TOK_LITERAL_NONE)
    ADDTOK("SIN", "ff89", 0, TOK_LITERAL_NONE)
    ADDTOK("SPACE$", "ff99", 0, TOK_LITERAL_NONE)
    ADDTOK("SQR", "ff87", 0, TOK_LITERAL_NONE)
    ADDTOK("LOC(", "ffac28", 0, TOK_LITERAL_NONE)
    ADDTOK("STICK", "ffa2", 0, TOK_LITERAL_NONE)
    ADDTOK("COS", "ff8c", 0, TOK_LITERAL_NONE)
    ADDTOK("LOF", "ffad", 0, TOK_LITERAL_NONE)
    ADDTOK("STR$", "ff93", 0, TOK_LITERAL_NONE)
    ADDTOK("CSNG", "ff9f", 0, TOK_LITERAL_NONE)
    ADDTOK("LOG", "ff8a", 0, TOK_LITERAL_NONE)
    ADDTOK("STRIG", "ffa3", 0, TOK_LITERAL_NONE)
    ADDTOK("LPOS", "ff9c", 0, TOK_LITERAL_NONE)
    ADDTOK("CVD", "ffaa", 0, TOK_LITERAL_NONE)
    ADDTOK("CVI", "ffa8", 0, TOK_LITERAL_NONE)
    ADDTOK("CVS", "ffa9", 0, TOK_LITERAL_NONE)
    ADDTOK("TAN", "ff8d", 0, TOK_LITERAL_NONE)
    ADDTOK("MID$", "ff83", 0, TOK_LITERAL_NONE)
    ADDTOK("MKD$", "ffb0", 0, TOK_LITERAL_NONE)
    ADDTOK("MKI$", "ffae", 0, TOK_LITERAL_NONE)
    ADDTOK("MKS$", "ffaf", 0, TOK_LITERAL_NONE)
    ADDTOK("VAL", "ff94", 0, TOK_LITERAL_NONE)
    ADDTOK("DSKF", "ffa6", 0, TOK_LITERAL_NONE)
    ADDTOK("VPEEK", "ff98", 0, TOK_LITERAL_NONE)
    ADDTOK("OCT$", "ff9a", 0, TOK_LITERAL_NONE)
    ADDTOK("EOF", "ffab", 0, TOK_LITERAL_NONE)
    ADDTOK("PAD", "ffa5", 0, TOK_LITERAL_NONE)

    ADDTOK("'", "3a8fe6", 0, TOK_LITERAL_DATA_REM)
    ADDTOK("ELSE", "3aa1", 1, TOK_LITERAL_NONE)
    ADDTOK("AS", "4153", 0, TOK_LITERAL_NONE)

    gKeywordInit = -1
End Sub

Private Function TokenizeLineBody(ByRef bodyText As String) As String
    InitKeywordTable()

    Dim outBin As String = ""
    Dim src As String = bodyText

    While Len(src) > 0
        Dim matched As Integer = 0
        Dim k As Integer

        For k = 1 To gKeywordCount
            Dim kw As String = gKeywords(k).kw
            If Len(src) >= Len(kw) And UCase(Left(src, Len(kw))) = kw Then
                outBin &= gKeywords(k).tokData
                src = Mid(src, Len(kw) + 1)
                matched = -1

                If kw = "AS" Then
                    Dim spaceLen As Integer = 0
                    While spaceLen < Len(src) And Mid(src, spaceLen + 1, 1) = " "
                        spaceLen += 1
                    Wend
                    Dim digitLen As Integer = 0
                    While spaceLen + digitLen < Len(src)
                        Dim c As Integer = Asc(Mid(src, spaceLen + digitLen + 1, 1))
                        If c < Asc("0") Or c > Asc("9") Then Exit While
                        digitLen += 1
                        If digitLen >= 2 Then Exit While
                    Wend
                    If digitLen > 0 Then
                        Dim n As Integer = ValInt(Mid(src, spaceLen + 1, digitLen))
                        Dim i As Integer
                        For i = 1 To spaceLen
                            outBin &= Chr(32)
                        Next i
                        outBin &= Chr(n And &HFF)
                        src = Mid(src, spaceLen + digitLen + 1)
                    End If
                End If

                If gKeywords(k).isJump <> 0 Then
                    Do
                        Dim s As Integer = 0
                        While s < Len(src) And Mid(src, s + 1, 1) = " "
                            s += 1
                        Wend
                        Dim p As Integer = s + 1
                        If p > Len(src) Then Exit Do

                        Dim d As Integer = 0
                        While p + d <= Len(src)
                            Dim c As Integer = Asc(Mid(src, p + d, 1))
                            If c < Asc("0") Or c > Asc("9") Then Exit While
                            d += 1
                        Wend

                        If d > 0 Then
                            Dim jumpLine As Integer = ValInt(Mid(src, p, d))
                            Dim i As Integer
                            For i = 1 To s
                                outBin &= Chr(32)
                            Next i
                            outBin &= Chr(&H0E) & Chr(jumpLine And &HFF) & Chr((jumpLine Shr 8) And &HFF)
                            src = Mid(src, p + d)
                        ElseIf Mid(src, p, 1) = "," Then
                            Dim commaLen As Integer = 0
                            While p + commaLen <= Len(src) And Mid(src, p + commaLen, 1) = ","
                                commaLen += 1
                            Wend
                            Dim i As Integer
                            For i = 1 To s
                                outBin &= Chr(32)
                            Next i
                            For i = 1 To commaLen
                                outBin &= ","
                            Next i
                            src = Mid(src, p + commaLen)
                        Else
                            Exit Do
                        End If
                    Loop
                End If

                If gKeywords(k).literalMode = TOK_LITERAL_DATA_REM Then
                    Do While Len(src) > 0
                        Dim c As String = Left(src, 1)
                        If kw = "DATA" And c = ":" Then Exit Do
                        If (kw = "CALL" Or kw = "_") And (c = ":" Or c = "(") Then Exit Do
                        If kw = "CALL" Or kw = "_" Then
                            outBin &= UCase(c)
                        Else
                            outBin &= c
                        End If
                        src = Mid(src, 2)
                        If kw = "REM" Or kw = "'" Then
                            If Len(src) = 0 Then Exit Do
                        End If
                    Loop
                End If

                Exit For
            End If
        Next k

        If matched <> 0 Then Continue While

        Dim firstCh As String = Left(src, 1)
        Dim firstCode As Integer = Asc(firstCh)

        If firstCode >= Asc("0") And firstCode <= Asc("9") Then
            Dim nLen As Integer = 0
            While nLen < Len(src)
                Dim c As Integer = Asc(Mid(src, nLen + 1, 1))
                If c < Asc("0") Or c > Asc("9") Then Exit While
                nLen += 1
            Wend
            If nLen > 0 Then
                Dim nValue As Integer = ValInt(Left(src, nLen))
                If nValue >= 0 And nValue <= 9 Then
                    outBin &= Chr(&H11 + nValue)
                ElseIf nValue >= 10 And nValue <= 255 Then
                    outBin &= Chr(&H0F) & Chr(nValue And &HFF)
                ElseIf nValue >= 256 And nValue <= 32767 Then
                    outBin &= Chr(&H1C) & Chr(nValue And &HFF) & Chr((nValue Shr 8) And &HFF)
                Else
                    outBin &= Left(src, nLen)
                End If
                src = Mid(src, nLen + 1)
                Continue While
            End If
        End If

        If Len(src) >= 2 And UCase(Left(src, 2)) = "&H" Then
            Dim dLen As Integer = 0
            While 2 + dLen < Len(src)
                Dim c As Integer = Asc(Mid(src, 3 + dLen, 1))
                If HexDigitValue(c) < 0 Then Exit While
                dLen += 1
            Wend
            Dim valText As String = Mid(src, 3, dLen)
            Dim nValue As Integer = IIf(Len(valText) > 0, Val("&H" & valText), 0)
            outBin &= Chr(&H0C) & Chr(nValue And &HFF) & Chr((nValue Shr 8) And &HFF)
            src = Mid(src, 3 + dLen)
            Continue While
        End If

        If Len(src) >= 2 And UCase(Left(src, 2)) = "&O" Then
            Dim dLen As Integer = 0
            While 2 + dLen < Len(src)
                Dim c As Integer = Asc(Mid(src, 3 + dLen, 1))
                If c < Asc("0") Or c > Asc("7") Then Exit While
                dLen += 1
            Wend
            Dim nValue As Integer = 0
            Dim i As Integer
            For i = 1 To dLen
                nValue = nValue * 8 + (Asc(Mid(src, 2 + i, 1)) - Asc("0"))
            Next i
            outBin &= Chr(&H0B) & Chr(nValue And &HFF) & Chr((nValue Shr 8) And &HFF)
            src = Mid(src, 3 + dLen)
            Continue While
        End If

        If Len(src) >= 2 And UCase(Left(src, 2)) = "&B" Then
            Dim dLen As Integer = 0
            While 2 + dLen < Len(src)
                Dim c As String = Mid(src, 3 + dLen, 1)
                If c <> "0" And c <> "1" Then Exit While
                dLen += 1
            Wend
            outBin &= Chr(&H26) & Chr(&H42)
            Dim i As Integer
            For i = 1 To dLen
                outBin &= Mid(src, 2 + i, 1)
            Next i
            src = Mid(src, 3 + dLen)
            Continue While
        End If

        If firstCh = Chr(34) Then
            outBin &= firstCh
            src = Mid(src, 2)
            Do While Len(src) > 0
                Dim c As String = Left(src, 1)
                outBin &= c
                src = Mid(src, 2)
                If c = Chr(34) Then Exit Do
            Loop
            Continue While
        End If

        outBin &= UCase(firstCh)
        src = Mid(src, 2)
    Wend

    Return outBin
End Function

Private Function BuildBmxFromAmxText(ByRef amxText As String, ByRef outBinary As String, ByRef errMsg As String) As Integer
    outBinary = ""
    errMsg = ""

    Dim normalized As String = StripCR(amxText)
    Dim bodyLines() As String
    Dim lineNos() As Integer
    Dim lineCount As Integer = 0
    Dim posStart As Integer = 1

    While posStart <= Len(normalized)
        Dim br As Integer = InStr(posStart, normalized, Chr(10))
        Dim oneLine As String
        If br = 0 Then
            oneLine = Mid(normalized, posStart)
            posStart = Len(normalized) + 1
        Else
            oneLine = Mid(normalized, posStart, br - posStart)
            posStart = br + 1
        End If

        oneLine = Trim(oneLine)
        If Len(oneLine) = 0 Then Continue While

        Dim ln As Integer
        Dim body As String
        If ParseNumberedLine(oneLine, ln, body) = 0 Then
            errMsg = "Linha sem numeracao: " & oneLine
            Return 0
        End If

        lineCount += 1
        ReDim Preserve bodyLines(1 To lineCount)
        ReDim Preserve lineNos(1 To lineCount)
        bodyLines(lineCount) = TokenizeLineBody(body)
        lineNos(lineCount) = ln
    Wend

    If lineCount = 0 Then
        errMsg = "Arquivo AMX vazio."
        Return 0
    End If

    Dim outBin As String = Chr(&HFF)
    Dim nextAddr As UInteger = &H8001
    Dim i As Integer

    For i = 1 To lineCount
        Dim lineData As String = bodyLines(i)
        Dim lineLen As Integer = Len(lineData)
        Dim addrAfter As UInteger = nextAddr + 4 + lineLen + 1

        outBin &= Chr(addrAfter And &HFF)
        outBin &= Chr((addrAfter Shr 8) And &HFF)
        outBin &= Chr(lineNos(i) And &HFF)
        outBin &= Chr((lineNos(i) Shr 8) And &HFF)
        outBin &= lineData
        outBin &= Chr(0)

        nextAddr = addrAfter
    Next i

    outBin &= Chr(0) & Chr(0)
    outBinary = outBin
    Return -1
End Function

Private Function ToDos83(ByRef fileName As String, ByRef outName83 As String, ByRef errMsg As String) As Integer
    Dim src As String = UCase(Trim(fileName))
    If Len(src) = 0 Then
        errMsg = "Nome de arquivo vazio."
        Return 0
    End If

    Dim dotPos As Integer = InStrRev(src, ".")
    Dim baseName As String
    Dim extName As String

    If dotPos > 0 Then
        baseName = Left(src, dotPos - 1)
        extName = Mid(src, dotPos + 1)
    Else
        baseName = src
        extName = ""
    End If

    Dim i As Integer
    Dim cleanBase As String = ""
    For i = 1 To Len(baseName)
        Dim c As Integer = Asc(Mid(baseName, i, 1))
        If (c >= Asc("A") And c <= Asc("Z")) Or (c >= Asc("0") And c <= Asc("9")) Or c = Asc("_") Then
            cleanBase &= Chr(c)
        Else
            cleanBase &= "_"
        End If
    Next i

    Dim cleanExt As String = ""
    For i = 1 To Len(extName)
        Dim c As Integer = Asc(Mid(extName, i, 1))
        If (c >= Asc("A") And c <= Asc("Z")) Or (c >= Asc("0") And c <= Asc("9")) Or c = Asc("_") Then
            cleanExt &= Chr(c)
        Else
            cleanExt &= "_"
        End If
    Next i

    If Len(cleanBase) = 0 Then cleanBase = "NONAME"
    cleanBase = Left(cleanBase, 8)
    cleanExt = Left(cleanExt, 3)

    outName83 = cleanBase & String(8 - Len(cleanBase), " ") & cleanExt & String(3 - Len(cleanExt), " ")
    Return -1
End Function

Private Sub Fat12SetEntry(fat() As UByte, ByVal cluster As Integer, ByVal value As Integer)
    Dim offset As Integer = (cluster * 3) \ 2

    If (cluster And 1) = 0 Then
        fat(offset) = value And &HFF
        fat(offset + 1) = (fat(offset + 1) And &HF0) Or ((value Shr 8) And &H0F)
    Else
        fat(offset) = (fat(offset) And &H0F) Or ((value Shl 4) And &HF0)
        fat(offset + 1) = (value Shr 4) And &HFF
    End If
End Sub

Private Function MsxDosBootCodeHex() As String
    ' Bootstrap Z80 do setor de boot (offsets 28-509), portado byte a byte
    ' do DefaultBootBlock de paleobasic/src/editor/core/MSXDisk.pbi (VFB-1989).
    ' O disco anterior so escrevia o BPB e zeros aqui: sem este bootstrap,
    ' o boot do MSX pula pro setor 0 e executa NOPs ate travar ("boot e para").
    Dim h As String
    h = "0000D0ED5358C032C2C036552336C0311FF5119DC00E0FCD7DF33C2828110001"
    h &= "0E1ACD7DF321010022ABC021003F119DC00E27CD7DF3C3000157C0CD000079E6"
    h &= "FEFE0220073AC2C0A7CA22401177C00E09CD7DF30E07CD7DF318B4426F6F7420"
    h &= "6572726F720D0A507265737320616E79206B657920666F722072657472790D0A"
    h &= "24004D5358444F53202053595300000000000000000000000000000000000000"
    h &= "000000000000000000000000000000000000F32A51F3110001190100011100C1"
    h &= "EDB03AEEC04711EFC0210000CD5152F376C918643AAF80F9CA6D48D3A50C8C2F"
    h &= "9CCBE989D20032264094611920E6806D8A000000000000000000000000000000"
    h &= "0000000000000000000000000000000000000000000000000000000000000000"
    h &= "0000000000000000000000000000000000000000000000000000000000000000"
    h &= "0000000000000000000000000000000000000000000000000000000000000000"
    h &= "0000000000000000000000000000000000000000000000000000000000000000"
    h &= "0000000000000000000000000000000000000000000000000000000000000000"
    h &= "0000000000000000000000000000000000000000000000000000000000000000"
    h &= "0000000000000000000000000000000000000000000000000000000000000000"
    h &= "0000"
    Return h
End Function

Const DISK_SECTOR_SIZE = 512
Const DISK_TOTAL_SECTORS = 1440
Const DISK_SIZE_BYTES = DISK_SECTOR_SIZE * DISK_TOTAL_SECTORS
Const DISK_SECTORS_PER_CLUSTER = 2
Const DISK_RESERVED_SECTORS = 1
Const DISK_FAT_COUNT = 2
Const DISK_SECTORS_PER_FAT = 3
Const DISK_ROOT_ENTRIES = 112
Const DISK_ROOT_DIR_SECTORS = 7

' Nucleo generico de montagem de disco FAT12 MSX-DOS 720KB: recebe a lista
' de arquivos (path local + nome 8.3) ja pronta e cuida do boot sector, FAT
' e diretorio raiz. Usado tanto pelo pipeline MSX-Basic/Basic Dignified
' (BuildRunDisk) quanto pelo pipeline asMSX (BuildAsmRunDisk).
Private Function BuildFat12DiskCore(filePath() As String, fileName() As String, ByVal fileCount As Integer, ByRef diskDir As String, ByRef baseName As String, ByRef outDiskPath As String, ByRef errMsg As String) As Integer
    Dim disk(0 To DISK_SIZE_BYTES - 1) As UByte
    Dim fat(0 To (DISK_SECTORS_PER_FAT * DISK_SECTOR_SIZE) - 1) As UByte

    Dim i As Integer
    For i = 0 To UBound(disk)
        disk(i) = 0
    Next i
    For i = 0 To UBound(fat)
        fat(i) = 0
    Next i

    disk(0) = &HEB
    disk(1) = &HFE
    disk(2) = &H90

    Dim oem As String = "MSXIDE  "
    For i = 1 To Len(oem)
        disk(2 + i) = Asc(Mid(oem, i, 1))
    Next i

    disk(11) = &H00
    disk(12) = &H02
    disk(13) = DISK_SECTORS_PER_CLUSTER
    disk(14) = DISK_RESERVED_SECTORS
    disk(15) = 0
    disk(16) = DISK_FAT_COUNT
    disk(17) = DISK_ROOT_ENTRIES And &HFF
    disk(18) = (DISK_ROOT_ENTRIES Shr 8) And &HFF
    disk(19) = DISK_TOTAL_SECTORS And &HFF
    disk(20) = (DISK_TOTAL_SECTORS Shr 8) And &HFF
    disk(21) = &HF9
    disk(22) = DISK_SECTORS_PER_FAT
    disk(23) = 0
    disk(24) = 9
    disk(25) = 0
    disk(26) = 2
    disk(27) = 0
    disk(510) = &H55
    disk(511) = &HAA

    Dim bootCode As String = HexToBin(MsxDosBootCodeHex())
    For i = 0 To Len(bootCode) - 1
        disk(28 + i) = Asc(Mid(bootCode, i + 1, 1))
    Next i

    fat(0) = &HF9
    fat(1) = &HFF
    fat(2) = &HFF

    Dim rootOffset As Integer = (DISK_RESERVED_SECTORS + DISK_FAT_COUNT * DISK_SECTORS_PER_FAT) * DISK_SECTOR_SIZE
    Dim dataOffset As Integer = (DISK_RESERVED_SECTORS + DISK_FAT_COUNT * DISK_SECTORS_PER_FAT + DISK_ROOT_DIR_SECTORS) * DISK_SECTOR_SIZE
    Dim clusterSize As Integer = DISK_SECTORS_PER_CLUSTER * DISK_SECTOR_SIZE
    Dim maxCluster As Integer = 2 + ((DISK_TOTAL_SECTORS - (DISK_RESERVED_SECTORS + DISK_FAT_COUNT * DISK_SECTORS_PER_FAT + DISK_ROOT_DIR_SECTORS)) \ DISK_SECTORS_PER_CLUSTER) - 1
    Dim nextCluster As Integer = 2

    For i = 1 To fileCount
        If i > DISK_ROOT_ENTRIES Then
            errMsg = "Numero de arquivos excede o diretorio raiz FAT12."
            Return 0
        End If

        Dim dataBytes As String
        If ReadBinaryFile(filePath(i), dataBytes, errMsg) = 0 Then Return 0

        Dim sz As Integer = Len(dataBytes)
        Dim startCluster As Integer = 0
        Dim neededClusters As Integer = 0

        If sz > 0 Then
            neededClusters = (sz + clusterSize - 1) \ clusterSize
            startCluster = nextCluster
            If (startCluster + neededClusters - 1) > maxCluster Then
                errMsg = "Espaco insuficiente no disco virtual."
                Return 0
            End If

            Dim c As Integer
            For c = 0 To neededClusters - 1
                Dim curCluster As Integer = startCluster + c
                Dim nxt As Integer = IIf(c = neededClusters - 1, &HFFF, curCluster + 1)
                Fat12SetEntry(fat(), curCluster, nxt)

                Dim srcPos As Integer = c * clusterSize + 1
                Dim chunk As Integer = clusterSize
                If srcPos + chunk - 1 > sz Then chunk = sz - srcPos + 1

                Dim dstPos As Integer = dataOffset + (curCluster - 2) * clusterSize
                Dim j As Integer
                For j = 0 To chunk - 1
                    disk(dstPos + j) = Asc(Mid(dataBytes, srcPos + j, 1))
                Next j
            Next c

            nextCluster = startCluster + neededClusters
        End If

        Dim dosName As String
        If ToDos83(fileName(i), dosName, errMsg) = 0 Then Return 0

        Dim entryOffset As Integer = rootOffset + (i - 1) * 32
        Dim n As Integer
        For n = 1 To 11
            disk(entryOffset + (n - 1)) = Asc(Mid(dosName, n, 1))
        Next n

        disk(entryOffset + 11) = &H20
        disk(entryOffset + 26) = startCluster And &HFF
        disk(entryOffset + 27) = (startCluster Shr 8) And &HFF
        disk(entryOffset + 28) = sz And &HFF
        disk(entryOffset + 29) = (sz Shr 8) And &HFF
        disk(entryOffset + 30) = (sz Shr 16) And &HFF
        disk(entryOffset + 31) = (sz Shr 24) And &HFF
    Next i

    Dim fat1Offset As Integer = DISK_RESERVED_SECTORS * DISK_SECTOR_SIZE
    Dim fat2Offset As Integer = (DISK_RESERVED_SECTORS + DISK_SECTORS_PER_FAT) * DISK_SECTOR_SIZE
    For i = 0 To UBound(fat)
        disk(fat1Offset + i) = fat(i)
        disk(fat2Offset + i) = fat(i)
    Next i

    outDiskPath = NormalizePathValue(diskDir & Left(baseName, 8) & ".dsk")

    Dim ff As Integer = FreeFile
    If Open(outDiskPath For Binary Access Write As #ff) <> 0 Then
        errMsg = "Falha ao criar disco: " & outDiskPath
        Return 0
    End If

    For i = 0 To UBound(disk)
        Put #ff, , disk(i)
    Next i

    Close #ff
    Return -1
End Function

Private Function PrepareRunDiskDir(ByRef srcPath As String, ByVal cleanDiskDir As Integer, ByRef diskDir As String, ByRef errMsg As String) As Integer
    Dim workRoot As String = NormalizePathValue(PathDir(srcPath))
    If Len(workRoot) = 0 Then workRoot = NormalizePathValue(CurDir())
    If Right(workRoot, 1) <> Chr(92) And Right(workRoot, 1) <> "/" Then workRoot &= Chr(92)

    diskDir = NormalizePathValue(workRoot & "disk")
    If Dir(diskDir) = "" Then MkDir diskDir
    If Right(diskDir, 1) <> Chr(92) And Right(diskDir, 1) <> "/" Then diskDir &= Chr(92)

    If cleanDiskDir <> 0 Then
        If ClearRunDiskDir(diskDir, errMsg) = 0 Then Return 0
    End If

    Return -1
End Function

Private Function BuildRunDisk(ByRef srcPath As String, ByRef amxPath As String, ByRef bmxPath As String, ByRef outDiskPath As String, ByRef errMsg As String, ByVal cleanDiskDir As Integer) As Integer
    Dim dmxPath As String = srcPath

    Dim srcExt As String = GetExtLower(srcPath)
    If srcExt <> ".dmx" And srcExt <> ".bad" Then
        dmxPath = ""
    End If

    Dim diskDir As String
    If PrepareRunDiskDir(srcPath, cleanDiskDir, diskDir, errMsg) = 0 Then Return 0

    Dim baseName As String = UCase(BaseNameNoExt(srcPath))
    If Len(baseName) = 0 Then baseName = "PROGRAM"

    Dim autoexecPath As String = NormalizePathValue(diskDir & "AUTOEXEC.BAS")
    Dim autoexecText As String = "10 RUN " & Chr(34) & Left(baseName, 8) & ".BMX" & Chr(34) & Chr(13) & Chr(10)
    If WriteTextFile(autoexecPath, autoexecText, errMsg) = 0 Then Return 0

    Dim filePath(1 To 4) As String
    Dim fileName(1 To 4) As String
    Dim fileCount As Integer = 0

    If Len(dmxPath) > 0 And Dir(dmxPath) <> "" Then
        fileCount += 1
        filePath(fileCount) = dmxPath
        fileName(fileCount) = Left(baseName, 8) & ".DMX"
    End If

    If Dir(amxPath) = "" Then
        errMsg = "Arquivo AMX nao encontrado: " & amxPath
        Return 0
    End If
    fileCount += 1
    filePath(fileCount) = amxPath
    fileName(fileCount) = Left(baseName, 8) & ".AMX"

    If Dir(bmxPath) = "" Then
        errMsg = "Arquivo BMX nao encontrado: " & bmxPath
        Return 0
    End If
    fileCount += 1
    filePath(fileCount) = bmxPath
    fileName(fileCount) = Left(baseName, 8) & ".BMX"

    fileCount += 1
    filePath(fileCount) = autoexecPath
    fileName(fileCount) = "AUTOEXEC.BAS"

    Return BuildFat12DiskCore(filePath(), fileName(), fileCount, diskDir, baseName, outDiskPath, errMsg)
End Function

Private Function BuildAsmRunDisk(ByRef srcPath As String, ByRef binPath As String, ByRef outDiskPath As String, ByRef errMsg As String, ByVal cleanDiskDir As Integer) As Integer
    Dim diskDir As String
    If PrepareRunDiskDir(srcPath, cleanDiskDir, diskDir, errMsg) = 0 Then Return 0

    Dim baseName As String = UCase(BaseNameNoExt(srcPath))
    If Len(baseName) = 0 Then baseName = "PROGRAM"

    Dim autoexecPath As String = NormalizePathValue(diskDir & "AUTOEXEC.BAS")
    Dim autoexecText As String = "10 BLOAD " & Chr(34) & Left(baseName, 8) & ".BIN" & Chr(34) & ",R" & Chr(13) & Chr(10)
    If WriteTextFile(autoexecPath, autoexecText, errMsg) = 0 Then Return 0

    Dim filePath(1 To 3) As String
    Dim fileName(1 To 3) As String
    Dim fileCount As Integer = 0

    If Dir(srcPath) <> "" Then
        fileCount += 1
        filePath(fileCount) = srcPath
        fileName(fileCount) = Left(baseName, 8) & ".ASM"
    End If

    If Dir(binPath) = "" Then
        errMsg = "Arquivo BIN nao encontrado: " & binPath
        Return 0
    End If
    fileCount += 1
    filePath(fileCount) = binPath
    fileName(fileCount) = Left(baseName, 8) & ".BIN"

    fileCount += 1
    filePath(fileCount) = autoexecPath
    fileName(fileCount) = "AUTOEXEC.BAS"

    Return BuildFat12DiskCore(filePath(), fileName(), fileCount, diskDir, baseName, outDiskPath, errMsg)
End Function

Function CompilerCompileToAmx(ByRef srcPath As String, ByRef outAmxPath As String, ByRef errMsg As String) As Integer
    CompilerDebugLog("compiler", "CompilerCompileToAmx start src=" & srcPath)
    errMsg = ""
    outAmxPath = ChangeExt(srcPath, ".amx")

    Dim ext As String = GetExtLower(srcPath)
    Dim sourceText As String
    If ReadTextFile(srcPath, sourceText, errMsg) = 0 Then
        CompilerDebugLog("compiler", "CompilerCompileToAmx fail read err=" & errMsg)
        Return 0
    End If

    Dim amxText As String
    If ext = ".amx" Or ext = ".asc" Then
        amxText = sourceText
    Else
        Dim amxOverride As String = ""
        If PreprocessDignified(sourceText, srcPath, amxText, amxOverride, errMsg) = 0 Then
            CompilerDebugLog("compiler", "CompilerCompileToAmx fail preprocess err=" & errMsg)
            Return 0
        End If
        If Len(amxOverride) > 0 Then outAmxPath = amxOverride
    End If

    If WriteTextFile(outAmxPath, amxText, errMsg) = 0 Then
        CompilerDebugLog("compiler", "CompilerCompileToAmx fail write err=" & errMsg)
        Return 0
    End If
    CompilerDebugLog("compiler", "CompilerCompileToAmx ok out=" & outAmxPath & " size=" & Trim(Str(Len(amxText))))
    Return -1
End Function

Private Function CompactUpper(ByRef s As String) As String
    Dim outS As String = ""
    Dim i As Integer
    For i = 1 To Len(s)
        Dim ch As String = Mid(s, i, 1)
        If ch <> " " Then outS &= ch
    Next i
    Return UCase(outS)
End Function

' Smoke test headless da juncao de linha por : (BASIC_DIGNIFIED.md, "Line
' separation") - chama PreprocessDignified direto em memoria, sem nenhum
' arquivo no disco (o texto de entrada nao usa INCLUDE, entao
' ExpandIncludesText nunca precisa ler nada fora da string).
Private Function SplitNonBlankTrimmedLines(ByRef txt As String, outLines() As String) As Integer
    Dim outLineCount As Integer = 0
    Dim posStart As Integer = 1
    Dim normalized As String = StripCR(txt)
    While posStart <= Len(normalized)
        Dim br As Integer = InStr(posStart, normalized, Chr(10))
        Dim oneLine As String
        If br = 0 Then
            oneLine = Mid(normalized, posStart)
            posStart = Len(normalized) + 1
        Else
            oneLine = Mid(normalized, posStart, br - posStart)
            posStart = br + 1
        End If
        If Len(Trim(oneLine)) > 0 Then
            outLineCount += 1
            ReDim Preserve outLines(1 To outLineCount)
            outLines(outLineCount) = Trim(oneLine)
        End If
    Wend
    Return outLineCount
End Function

Function CompilerRunJoinSmokeTest(ByRef report As String) As Integer
    Dim srcText As String = "screen 0:" & Chr(10) & "width 40" & Chr(10) & "print 1" & Chr(10) & ":print 2" & Chr(10) & "print 3"
    Dim amxText As String
    Dim amxOverride As String
    Dim errMsg As String

    If PreprocessDignified(srcText, "smoke_join.dmx", amxText, amxOverride, errMsg) = 0 Then
        report = "SMOKE BADIG FAIL: PreprocessDignified deu erro - " & errMsg
        Return 0
    End If

    Dim outLines() As String
    Dim outLineCount As Integer = SplitNonBlankTrimmedLines(amxText, outLines())

    ' "screen 0:" (: no fim) funde com "width 40" - vira UMA linha so'.
    ' "print 1" nao tem : de nenhum lado com "width 40", entao comeca
    ' grupo novo - mas ":print 2" (: no inicio) funde com ele. "print 3"
    ' nao tem : de nenhum lado, fica na sua propria linha. 3 grupos ao todo.
    If outLineCount <> 3 Then
        report = "SMOKE BADIG FAIL: esperava 3 linhas geradas, vieram " & Trim(Str(outLineCount)) & " - " & amxText
        Return 0
    End If

    Dim compact1 As String = CompactUpper(outLines(1))
    Dim compact2 As String = CompactUpper(outLines(2))

    If InStr(compact1, "SCREEN0:WIDTH40") = 0 Then
        report = "SMOKE BADIG FAIL: 1a linha nao tem o corpo esperado (screen 0:width 40) - '" & outLines(1) & "'"
        Return 0
    End If
    If InStr(compact2, "PRINT1:PRINT2") = 0 Then
        report = "SMOKE BADIG FAIL: 2a linha nao tem o corpo esperado (print 1:print 2) - '" & outLines(2) & "'"
        Return 0
    End If
    If InStr(UCase(outLines(3)), "PRINT 3") = 0 Then
        report = "SMOKE BADIG FAIL: 3a linha deveria ser PRINT 3 (sem : ligando a linha anterior) - '" & outLines(3) & "'"
        Return 0
    End If

    report = "SMOKE BADIG OK: linhas terminadas/iniciadas em : sao unidas numa unica linha numerada (screen 0:width 40, print 1:print 2), linha sem : fica separada (print 3)"
    Return -1
End Function

' Smoke test headless das 3 opcoes de formatacao do Basic Dignified que o
' preprocessador deve respeitar: Strip Spaces (cfg.badig.strip_spaces),
' Convert PRINT (cfg.msxbasic.badig.convert_print, "?" ou "PRINT") e
' Strip THEN GOTO (cfg.msxbasic.badig.strip_then_goto, "THEN" ou "GOTO").
' Grava/restaura as 3 chaves reais no banco (igual ao padrao do smoke do
' Mamute) pra nunca deixar sujeira permanente na configuracao de quem
' rodou o build.
Function CompilerRunFormatSmokeTest(ByRef report As String) As Integer
    Dim savedStrip As String = DbGetSetting("cfg.badig.strip_spaces", "False")
    Dim savedPrint As String = DbGetSetting("cfg.msxbasic.badig.convert_print", "")
    Dim savedThenGoto As String = DbGetSetting("cfg.msxbasic.badig.strip_then_goto", "")

    Dim amxText As String
    Dim amxOverride As String
    Dim errMsg As String
    Dim outLines() As String
    Dim outLineCount As Integer
    Dim srcWithSpecial As String

    ' --- Convert PRINT: "?" troca PRINT pelo sinal, "PRINT" troca o sinal
    ' pela palavra - dos dois lados, sem strip_spaces no meio pra nao
    ' interferir na leitura do resultado.
    DbSetSetting("cfg.badig.strip_spaces", "False")
    DbSetSetting("cfg.msxbasic.badig.strip_then_goto", "")

    DbSetSetting("cfg.msxbasic.badig.convert_print", "?")
    If PreprocessDignified("print 1", "smoke_fmt.dmx", amxText, amxOverride, errMsg) = 0 Then
        GoTo FormatSmokeFail
    End If
    outLineCount = SplitNonBlankTrimmedLines(amxText, outLines())
    If outLineCount <> 1 Or InStr(UCase(outLines(1)), "? 1") = 0 Then
        DbSetSetting("cfg.badig.strip_spaces", savedStrip)
        DbSetSetting("cfg.msxbasic.badig.convert_print", savedPrint)
        DbSetSetting("cfg.msxbasic.badig.strip_then_goto", savedThenGoto)
        report = "SMOKE BADIG FMT FAIL: Convert PRINT=? nao trocou PRINT por ? - '" & amxText & "'"
        Return 0
    End If

    DbSetSetting("cfg.msxbasic.badig.convert_print", "PRINT")
    If PreprocessDignified("? 1", "smoke_fmt.dmx", amxText, amxOverride, errMsg) = 0 Then
        GoTo FormatSmokeFail
    End If
    outLineCount = SplitNonBlankTrimmedLines(amxText, outLines())
    If outLineCount <> 1 Or InStr(UCase(outLines(1)), "PRINT 1") = 0 Then
        DbSetSetting("cfg.badig.strip_spaces", savedStrip)
        DbSetSetting("cfg.msxbasic.badig.convert_print", savedPrint)
        DbSetSetting("cfg.msxbasic.badig.strip_then_goto", savedThenGoto)
        report = "SMOKE BADIG FMT FAIL: Convert PRINT=PRINT nao trocou ? por PRINT - '" & amxText & "'"
        Return 0
    End If
    DbSetSetting("cfg.msxbasic.badig.convert_print", "")

    ' --- Strip THEN GOTO: "GOTO" derruba o THEN, "THEN" derruba o GOTO
    ' (as duas formas sao validas e equivalentes no MSX-BASIC classico).
    DbSetSetting("cfg.msxbasic.badig.strip_then_goto", "GOTO")
    If PreprocessDignified("if x=1 then goto 100", "smoke_fmt.dmx", amxText, amxOverride, errMsg) = 0 Then
        GoTo FormatSmokeFail
    End If
    outLineCount = SplitNonBlankTrimmedLines(amxText, outLines())
    If outLineCount <> 1 Or InStr(UCase(outLines(1)), "THEN") <> 0 Or InStr(UCase(outLines(1)), "GOTO 100") = 0 Then
        DbSetSetting("cfg.badig.strip_spaces", savedStrip)
        DbSetSetting("cfg.msxbasic.badig.convert_print", savedPrint)
        DbSetSetting("cfg.msxbasic.badig.strip_then_goto", savedThenGoto)
        report = "SMOKE BADIG FMT FAIL: Strip THEN GOTO=GOTO deveria derrubar o THEN - '" & amxText & "'"
        Return 0
    End If

    DbSetSetting("cfg.msxbasic.badig.strip_then_goto", "THEN")
    If PreprocessDignified("if x=1 goto 100", "smoke_fmt.dmx", amxText, amxOverride, errMsg) = 0 Then
        GoTo FormatSmokeFail
    End If
    outLineCount = SplitNonBlankTrimmedLines(amxText, outLines())
    If outLineCount <> 1 Or InStr(UCase(outLines(1)), "GOTO") <> 0 Or InStr(UCase(outLines(1)), "THEN 100") = 0 Then
        DbSetSetting("cfg.badig.strip_spaces", savedStrip)
        DbSetSetting("cfg.msxbasic.badig.convert_print", savedPrint)
        DbSetSetting("cfg.msxbasic.badig.strip_then_goto", savedThenGoto)
        report = "SMOKE BADIG FMT FAIL: Strip THEN GOTO=THEN deveria derrubar o GOTO - '" & amxText & "'"
        Return 0
    End If
    DbSetSetting("cfg.msxbasic.badig.strip_then_goto", "")

    ' --- Strip Spaces: remove TODOS os espacos fora de string (nao so'
    ' colapsa repetidos) - inclusive os que ficam colados no ':' - mas
    ' preserva o que estiver dentro de aspas.
    DbSetSetting("cfg.badig.strip_spaces", "True")
    If PreprocessDignified("print  ""a b""  :  print  2", "smoke_fmt.dmx", amxText, amxOverride, errMsg) = 0 Then
        GoTo FormatSmokeFail
    End If
    outLineCount = SplitNonBlankTrimmedLines(amxText, outLines())
    If outLineCount <> 1 Or InStr(UCase(outLines(1)), "PRINT" & Chr(34) & "A B" & Chr(34) & ":PRINT2") = 0 Then
        DbSetSetting("cfg.badig.strip_spaces", savedStrip)
        DbSetSetting("cfg.msxbasic.badig.convert_print", savedPrint)
        DbSetSetting("cfg.msxbasic.badig.strip_then_goto", savedThenGoto)
        report = "SMOKE BADIG FMT FAIL: Strip Spaces deveria remover todo espaco fora de string (preservando 'a b' entre aspas) - '" & amxText & "'"
        Return 0
    End If

    DbSetSetting("cfg.badig.strip_spaces", savedStrip)
    DbSetSetting("cfg.msxbasic.badig.convert_print", savedPrint)
    DbSetSetting("cfg.msxbasic.badig.strip_then_goto", savedThenGoto)

    ' --- Caracteres especiais MSX (Inserir->Caracteres Especiais no
    ' editor, codigos 128-255): o pipeline inteiro (editor/arquivo/
    ' PreprocessDignified) e' byte-a-byte, nunca passa por UTF-8 - entao
    ' um byte alto dentro de um literal de string tem que sair do outro
    ' lado IDENTICO, sem nenhuma "tradução" no compilador (a traducao
    ' inteira acontece na hora de INSERIR o caractere no editor, nao
    ' aqui). Confere com o byte 200 (arbitrario, dentro de 128-255).
    DbSetSetting("cfg.badig.strip_spaces", "False")
    srcWithSpecial = "print " & Chr(34) & "A" & Chr(200) & "B" & Chr(34)
    If PreprocessDignified(srcWithSpecial, "smoke_fmt.dmx", amxText, amxOverride, errMsg) = 0 Then
        DbSetSetting("cfg.badig.strip_spaces", savedStrip)
        GoTo FormatSmokeFail
    End If
    DbSetSetting("cfg.badig.strip_spaces", savedStrip)
    outLineCount = SplitNonBlankTrimmedLines(amxText, outLines())
    If outLineCount <> 1 Or InStr(outLines(1), "A" & Chr(200) & "B") = 0 Then
        DbSetSetting("cfg.msxbasic.badig.convert_print", savedPrint)
        DbSetSetting("cfg.msxbasic.badig.strip_then_goto", savedThenGoto)
        Dim gotHex As String = ""
        Dim hi As Integer
        For hi = 1 To Len(outLines(1))
            gotHex &= Hex(Asc(Mid(outLines(1), hi, 1))) & " "
        Next hi
        report = "SMOKE BADIG FMT FAIL: byte 200 (caractere especial MSX) nao sobreviveu intacto ao PreprocessDignified - bytes da linha: " & gotHex
        Return 0
    End If

    report = "SMOKE BADIG FMT OK: Convert PRINT (?/PRINT dos dois lados), Strip THEN GOTO (THEN/GOTO dos dois lados), Strip Spaces (remove tudo fora de string, preserva literal), caractere especial MSX (byte 128-255) preservado intacto dentro de string"
    Return -1

FormatSmokeFail:
    DbSetSetting("cfg.badig.strip_spaces", savedStrip)
    DbSetSetting("cfg.msxbasic.badig.convert_print", savedPrint)
    DbSetSetting("cfg.msxbasic.badig.strip_then_goto", savedThenGoto)
    report = "SMOKE BADIG FMT FAIL: PreprocessDignified deu erro - " & errMsg
    Return 0
End Function

' Smoke test headless da conversao de variaveis de nome longo -> curto
' (BASIC_DIGNIFIED.md, "Long named variables" - badig.py get_declares +
' badig_msx.py process_variable/get_hard_variable). Cada cenario e' uma
' chamada independente de PreprocessDignified, sem nenhuma config de
' banco envolvida (a feature nao depende de nenhuma chave cfg.*).
Function CompilerRunVariableSmokeTest(ByRef report As String) As Integer
    Dim amxText As String
    Dim amxOverride As String
    Dim errMsg As String
    Dim outLines() As String
    Dim outLineCount As Integer

    ' --- A: auto-assign descendente (zz) + mesmo curto independente do
    ' tipo ($) + string literal NUNCA e' varrida (senao "score" da string
    ' roubaria o "zz" que tem que ir pra "variable1", que aparece depois).
    If PreprocessDignified("print " & Chr(34) & "score is high" & Chr(34) & Chr(10) & "variable1=5" & Chr(10) & "print variable1$", "smoke_var.dmx", amxText, amxOverride, errMsg) = 0 Then
        report = "SMOKE BADIG VAR FAIL: cenario A - PreprocessDignified deu erro - " & errMsg
        Return 0
    End If
    outLineCount = SplitNonBlankTrimmedLines(amxText, outLines())
    If outLineCount <> 3 Then
        report = "SMOKE BADIG VAR FAIL: cenario A - esperava 3 linhas, veio " & Trim(Str(outLineCount)) & " - " & amxText
        Return 0
    End If
    If InStr(outLines(1), Chr(34) & "score is high" & Chr(34)) = 0 Then
        report = "SMOKE BADIG VAR FAIL: cenario A - string literal foi alterada (varrida por engano) - '" & outLines(1) & "'"
        Return 0
    End If
    If InStr(LCase(outLines(2)), "zz=5") = 0 Then
        report = "SMOKE BADIG VAR FAIL: cenario A - variable1 deveria virar zz (1o nome longo de verdade, a string nao conta) - '" & outLines(2) & "'"
        Return 0
    End If
    If InStr(LCase(outLines(3)), "zz$") = 0 Then
        report = "SMOKE BADIG VAR FAIL: cenario A - variable1$ deveria virar zz$ (mesmo curto do variable1 sem $) - '" & outLines(3) & "'"
        Return 0
    End If

    ' --- B: REM apaga o resto da linha da varredura - a 2a ocorrencia de
    ' "longname", dentro do comentario, NAO pode ser trocada.
    If PreprocessDignified("longname=1:rem this uses longname word", "smoke_var.dmx", amxText, amxOverride, errMsg) = 0 Then
        report = "SMOKE BADIG VAR FAIL: cenario B - PreprocessDignified deu erro - " & errMsg
        Return 0
    End If
    outLineCount = SplitNonBlankTrimmedLines(amxText, outLines())
    If outLineCount <> 1 Then
        report = "SMOKE BADIG VAR FAIL: cenario B - esperava 1 linha, veio " & Trim(Str(outLineCount)) & " - " & amxText
        Return 0
    End If
    If InStr(LCase(outLines(1)), "zz=1") = 0 Then
        report = "SMOKE BADIG VAR FAIL: cenario B - longname (antes do REM) deveria virar zz - '" & outLines(1) & "'"
        Return 0
    End If
    If InStr(LCase(outLines(1)), "rem this uses longname word") = 0 Then
        report = "SMOKE BADIG VAR FAIL: cenario B - texto do REM nao pode ser mexido (longname ali dentro tem que continuar por extenso) - '" & outLines(1) & "'"
        Return 0
    End If

    ' --- C: declare explicito (myvar:mv), declare reserva curto (zz),
    ' ~ mantem nome por extenso em TODAS as ocorrencias (mesmo a sem ~).
    Dim srcC As String = "declare myvar:mv" & Chr(10) & "declare zz" & Chr(10) & "myvar=1" & Chr(10) & "~longkept=2" & Chr(10) & "print longkept" & Chr(10) & "otherlong=3"
    If PreprocessDignified(srcC, "smoke_var.dmx", amxText, amxOverride, errMsg) = 0 Then
        report = "SMOKE BADIG VAR FAIL: cenario C - PreprocessDignified deu erro - " & errMsg
        Return 0
    End If
    outLineCount = SplitNonBlankTrimmedLines(amxText, outLines())
    If outLineCount <> 4 Then
        report = "SMOKE BADIG VAR FAIL: cenario C - esperava 4 linhas (as 2 declare nao geram linha), veio " & Trim(Str(outLineCount)) & " - " & amxText
        Return 0
    End If
    If InStr(LCase(outLines(1)), "mv=1") = 0 Then
        report = "SMOKE BADIG VAR FAIL: cenario C - myvar deveria virar mv (declare explicito) - '" & outLines(1) & "'"
        Return 0
    End If
    If InStr(LCase(outLines(2)), "longkept=2") = 0 Then
        report = "SMOKE BADIG VAR FAIL: cenario C - ~longkept deveria manter o nome por extenso, sem o ~ - '" & outLines(2) & "'"
        Return 0
    End If
    If InStr(LCase(outLines(3)), "print longkept") = 0 Then
        report = "SMOKE BADIG VAR FAIL: cenario C - segunda ocorrencia de longkept (sem ~) tambem tem que ficar por extenso - '" & outLines(3) & "'"
        Return 0
    End If
    If InStr(LCase(outLines(4)), "zy=3") = 0 Then
        report = "SMOKE BADIG VAR FAIL: cenario C - otherlong deveria virar zy (zz reservado por declare, mv e' o curto do myvar, lo e' reservado pelas 2 letras de longkept) - '" & outLines(4) & "'"
        Return 0
    End If

    ' --- D: variavel de 1-2 letras usada direto nunca e' tocada.
    If PreprocessDignified("ab=5", "smoke_var.dmx", amxText, amxOverride, errMsg) = 0 Then
        report = "SMOKE BADIG VAR FAIL: cenario D - PreprocessDignified deu erro - " & errMsg
        Return 0
    End If
    outLineCount = SplitNonBlankTrimmedLines(amxText, outLines())
    If outLineCount <> 1 Or InStr(LCase(outLines(1)), "ab=5") = 0 Then
        report = "SMOKE BADIG VAR FAIL: cenario D - variavel curta 'ab' usada direto nao pode ser alterada - '" & amxText & "'"
        Return 0
    End If

    report = "SMOKE BADIG VAR OK: nome longo->curto (zz descendente), mesmo curto independente de tipo ($), string/REM protegidos da varredura, declare explicito e reserva de curto, ~ mantem nome por extenso em todas as ocorrencias, variavel de 1-2 letras usada direto nunca e' tocada"
    Return -1
End Function

' Smoke test headless do nbasic.dmx (apelidos do NestorBASIC, 2026-09-13) -
' confere que "include " & Chr(34) & "nbasic.dmx" & Chr(34) resolve de
' verdade (arquivo precisa estar na raiz do msxIDE, CurDir() de quem roda
' isto) e que os apelidos viram o NUMERO certo de usr() depois do
' preprocessamento - sem isso, um erro de digitacao/duplicata no
' nbasic.dmx so' apareceria quando algum usuario tentasse compilar um
' programa de verdade usando NestorBASIC.
Function CompilerRunNBasicSmokeTest(ByRef report As String) As Integer
    Dim amxText As String
    Dim amxOverride As String
    Dim errMsg As String

    If Dir("nbasic.dmx") = "" Then
        report = "SMOKE NBASIC FAIL: nbasic.dmx nao encontrado na raiz (CurDir=" & CurDir() & ")"
        Return 0
    End If

    Dim srcText As String = "include " & Chr(34) & "nbasic.dmx" & Chr(34) & Chr(10) & _
        "valor = 0 : erro = 0" & Chr(10) & _
        "erro = .NB_ReadByte(4, &H100) : valor = p(2)" & Chr(10) & _
        "erro = .NB_GetAttrByName(" & Chr(34) & "TESTE.BIN" & Chr(34) & ")"

    If PreprocessDignified(srcText, "smoke_nbasic_test.dmx", amxText, amxOverride, errMsg) = 0 Then
        report = "SMOKE NBASIC FAIL: PreprocessDignified deu erro - " & errMsg
        Return 0
    End If

    Dim compactUp As String = CompactUpper(amxText)
    If InStr(compactUp, "USR(2)") = 0 Then
        report = "SMOKE NBASIC FAIL: .NB_ReadByte deveria chamar usr(2) - saida: " & amxText
        Return 0
    End If
    ' NB_GetAttrByHandle e NB_GetAttrByName compartilham o numero 50 de
    ' proposito (mesma rotina do NestorBASIC, escolhida por p(0)=255 = "por
    ' nome" - ver comentario no proprio nbasic.dmx) - confere que resolveu
    ' pro numero certo mesmo assim.
    If InStr(compactUp, "USR(50)") = 0 Then
        report = "SMOKE NBASIC FAIL: .NB_GetAttrByName deveria chamar usr(50) - saida: " & amxText
        Return 0
    End If
    ' Confere so' as DUAS chamadas de verdade que este teste faz (nao um
    ' "sem .NB_ em lugar nenhum" generico - os proprios comentarios do
    ' arquivo (mantidos de proposito, ' nao e' ##) mencionam varios outros
    ' nomes .NB_Algo em prosa, o que e' esperado e nao indica bug nenhum).
    If InStr(compactUp, ".NB_READBYTE(") > 0 Then
        report = "SMOKE NBASIC FAIL: sobrou chamada .NB_ReadByte(...) sem expandir na saida - " & amxText
        Return 0
    End If
    If InStr(compactUp, ".NB_GETATTRBYNAME(") > 0 Then
        report = "SMOKE NBASIC FAIL: sobrou chamada .NB_GetAttrByName(...) sem expandir na saida - " & amxText
        Return 0
    End If
    If InStr(compactUp, "GOSUB") = 0 Or InStr(compactUp, "RETURN") = 0 Then
        report = "SMOKE NBASIC FAIL: chamadas deveriam virar GOSUB/RETURN - saida: " & amxText
        Return 0
    End If

    ' Todo "func .NB_Nome(...) / ... / erro = usr(numero)" do arquivo real
    ' (nao um texto de teste solto) precisa ter um numero de usr() UNICO
    ' por nome de funcao, e todo numero usado tem que estar entre 0 e 86
    ' (faixa documentada no cabecalho do arquivo) - confere direto no
    ' nbasic.dmx pra pegar erro de digitacao/duplicata que um teste so'
    ' com 2 chamadas acima nunca alcancaria. So' considera o PRIMEIRO
    ' usr(numero) de cada func (a maioria tem um so'; .NB_ErrorText nao
    ' tem nenhum - fica de fora, contado a parte).
    Dim nbasicText As String
    Dim readErrMsg As String
    If ReadTextFile("nbasic.dmx", nbasicText, readErrMsg) = 0 Then
        report = "SMOKE NBASIC FAIL: nao consegui reler nbasic.dmx pra conferir duplicatas - " & readErrMsg
        Return 0
    End If
    Dim names() As String
    Dim nameCount As Integer = 0
    Dim numbers() As Integer
    Dim funcsWithoutUsr As Integer = 0
    Dim p As Integer = 1
    Do
        Dim fPos As Integer = InStr(p, nbasicText, "func .NB_")
        If fPos = 0 Then Exit Do
        Dim nameStart As Integer = fPos + Len("func .")
        Dim nameEnd As Integer = InStr(nameStart, nbasicText, "(")
        If nameEnd = 0 Then Exit Do
        Dim oneName As String = Trim(Mid(nbasicText, nameStart, nameEnd - nameStart))

        Dim dupIdx As Integer = 0
        Dim k As Integer
        For k = 1 To nameCount
            If names(k) = oneName Then dupIdx = k
        Next k
        If dupIdx > 0 Then
            report = "SMOKE NBASIC FAIL: funcao '" & oneName & "' duplicada em nbasic.dmx"
            Return 0
        End If

        ' Acha o proximo "ret" (fim do corpo desta func) e procura
        ' "usr(numero)" so' dentro desse intervalo.
        Dim retPos As Integer = InStr(nameEnd, nbasicText, Chr(10) & "ret ")
        If retPos = 0 Then retPos = Len(nbasicText)
        Dim usrPos As Integer = InStr(nameEnd, nbasicText, "usr(")
        If usrPos > 0 And usrPos < retPos Then
            Dim numStart As Integer = usrPos + 4
            Dim numEnd As Integer = InStr(numStart, nbasicText, ")")
            Dim oneNum As Integer = ValInt(Mid(nbasicText, numStart, numEnd - numStart))
            If oneNum < 0 Or oneNum > 86 Then
                report = "SMOKE NBASIC FAIL: '" & oneName & "' com usr() fora da faixa 0-86 (" & Trim(Str(oneNum)) & ")"
                Return 0
            End If
            nameCount += 1
            If nameCount = 1 Then
                ReDim names(1 To 1)
                ReDim numbers(1 To 1)
            Else
                ReDim Preserve names(1 To nameCount)
                ReDim Preserve numbers(1 To nameCount)
            End If
            names(nameCount) = oneName
            numbers(nameCount) = oneNum
        Else
            funcsWithoutUsr += 1
        End If

        p = retPos + 1
    Loop

    If nameCount < 80 Then
        report = "SMOKE NBASIC FAIL: nbasic.dmx deveria ter pelo menos 80 funcoes com usr() direto (achou " & Trim(Str(nameCount)) & ", mais " & Trim(Str(funcsWithoutUsr)) & " sem usr() direto)"
        Return 0
    End If

    report = "SMOKE NBASIC OK: include " & Chr(34) & "nbasic.dmx" & Chr(34) & " com func/ret de verdade, .NB_ReadByte->usr(2), .NB_GetAttrByName->usr(50) (compartilhado com .NB_GetAttrByHandle de proposito), " & Trim(Str(nameCount)) & " funcoes com usr() direto sem numero duplicado, todas no intervalo 0-86 (mais " & Trim(Str(funcsWithoutUsr)) & " sem usr() direto, ex.: .NB_ErrorText)"
    Return -1
End Function

' Proto-funcao "func .nome(args) / ret" - exemplo com 2 chamadas a mesma
' funcao: uma que reusa os MESMOS nomes de variavel da definicao (parametro
' e retorno "pulam" a atribuicao, ver BuildFuncCallReplacement) e outra que
' usa nomes diferentes (precisa gerar as atribuicoes de verdade).
Function CompilerRunFuncSmokeTest(ByRef report As String) As Integer
    Dim amxText As String
    Dim amxOverride As String
    Dim errMsg As String

    Dim srcText As String = _
        "seg = 1 : addr = 256" & Chr(10) & _
        "erro = .rd(seg, addr)" & Chr(10) & _
        "myerr = .rd(seg, addr)" & Chr(10) & _
        "print erro" & Chr(10) & _
        "end" & Chr(10) & _
        "func .rd(segmento, endereco)" & Chr(10) & _
        "p(0) = segmento : p(1) = endereco" & Chr(10) & _
        "erro = usr(2)" & Chr(10) & _
        "ret erro"

    If PreprocessDignified(srcText, "smoke_func_test.dmx", amxText, amxOverride, errMsg) = 0 Then
        report = "SMOKE FUNC FAIL: PreprocessDignified deu erro - " & errMsg
        Return 0
    End If

    Dim compactUp As String = CompactUpper(amxText)

    If InStr(compactUp, ".RD(") > 0 Then
        report = "SMOKE FUNC FAIL: sobrou chamada .RD(...) sem expandir - " & amxText
        Return 0
    End If
    If InStr(compactUp, "GOSUB") = 0 Then
        report = "SMOKE FUNC FAIL: chamada nao virou GOSUB - " & amxText
        Return 0
    End If
    If InStr(compactUp, "RETURN") = 0 Then
        report = "SMOKE FUNC FAIL: RET nao virou RETURN - " & amxText
        Return 0
    End If
    If InStr(compactUp, "FUNC") > 0 Then
        report = "SMOKE FUNC FAIL: sobrou palavra FUNC na saida - " & amxText
        Return 0
    End If

    Dim outLines() As String
    Dim outLineCount As Integer = SplitNonBlankTrimmedLines(amxText, outLines())
    If outLineCount < 6 Then
        report = "SMOKE FUNC FAIL: esperava pelo menos 6 linhas numeradas - " & amxText
        Return 0
    End If

    Dim colonSep As String = ":"
    If CountChar(outLines(2), colonSep) < 1 Then
        report = "SMOKE FUNC FAIL: 1a chamada (mesmos nomes) deveria pular atribuicao de argumento mas ainda ter o GOSUB - linha: " & outLines(2)
        Return 0
    End If
    If CountChar(outLines(3), colonSep) < 2 Then
        report = "SMOKE FUNC FAIL: 2a chamada (nomes diferentes: myerr<>erro) deveria gerar atribuicao explicita do retorno - linha: " & outLines(3)
        Return 0
    End If

    report = "SMOKE FUNC OK: func .nome(args)/ret funcionando, chamada com nomes iguais aos da definicao pula atribuicao inutil (arg e retorno), chamada com nomes diferentes atribui de verdade, GOSUB/RETURN resolvidos via {label} normal"
    Return -1
End Function

Function CompilerTokenizeAmx(ByRef amxPath As String, ByRef outBmxPath As String, ByRef errMsg As String) As Integer
    CompilerDebugLog("compiler", "CompilerTokenizeAmx start amx=" & amxPath)
    errMsg = ""
    outBmxPath = ChangeExt(amxPath, ".bmx")

    Dim amxText As String
    If ReadTextFile(amxPath, amxText, errMsg) = 0 Then
        CompilerDebugLog("compiler", "CompilerTokenizeAmx fail read err=" & errMsg)
        Return 0
    End If

    Dim binOut As String
    If BuildBmxFromAmxText(amxText, binOut, errMsg) = 0 Then
        CompilerDebugLog("compiler", "CompilerTokenizeAmx fail tokenize err=" & errMsg)
        Return 0
    End If

    If WriteBinaryFile(outBmxPath, binOut, errMsg) = 0 Then
        CompilerDebugLog("compiler", "CompilerTokenizeAmx fail write err=" & errMsg)
        Return 0
    End If
    CompilerDebugLog("compiler", "CompilerTokenizeAmx ok out=" & outBmxPath & " size=" & Trim(Str(Len(binOut))))
    Return -1
End Function

Function CompilerCompileToBmx(ByRef srcPath As String, ByRef outAmxPath As String, ByRef outBmxPath As String, ByRef errMsg As String) As Integer
    CompilerDebugLog("compiler", "CompilerCompileToBmx start src=" & srcPath)
    errMsg = ""
    outAmxPath = ""
    outBmxPath = ""

    If CompilerCompileToAmx(srcPath, outAmxPath, errMsg) = 0 Then
        CompilerDebugLog("compiler", "CompilerCompileToBmx fail compile-amx err=" & errMsg)
        Return 0
    End If
    If CompilerTokenizeAmx(outAmxPath, outBmxPath, errMsg) = 0 Then
        CompilerDebugLog("compiler", "CompilerCompileToBmx fail tokenize err=" & errMsg)
        Return 0
    End If

    CompilerDebugLog("compiler", "CompilerCompileToBmx ok amx=" & outAmxPath & " bmx=" & outBmxPath)
    Return -1
End Function

Function CompilerBuildRunDisk(ByRef srcPath As String, ByRef amxPath As String, ByRef bmxPath As String, ByRef outDiskPath As String, ByRef errMsg As String, ByVal cleanDiskDir As Integer = 0) As Integer
    outDiskPath = ""
    CompilerDebugLog("compiler", "CompilerBuildRunDisk start src=" & srcPath & " amx=" & amxPath & " bmx=" & bmxPath & " cleanDiskDir=" & Trim(Str(cleanDiskDir)))
    Dim rc As Integer = BuildRunDisk(srcPath, amxPath, bmxPath, outDiskPath, errMsg, cleanDiskDir)
    If rc = 0 Then
        CompilerDebugLog("compiler", "CompilerBuildRunDisk fail err=" & errMsg)
    Else
        CompilerDebugLog("compiler", "CompilerBuildRunDisk ok dsk=" & outDiskPath)
    End If
    Return rc
End Function

Function CompilerBuildAsmRunDisk(ByRef srcPath As String, ByRef binPath As String, ByRef outDiskPath As String, ByRef errMsg As String, ByVal cleanDiskDir As Integer = 0) As Integer
    outDiskPath = ""
    CompilerDebugLog("compiler", "CompilerBuildAsmRunDisk start src=" & srcPath & " bin=" & binPath & " cleanDiskDir=" & Trim(Str(cleanDiskDir)))
    Dim rc As Integer = BuildAsmRunDisk(srcPath, binPath, outDiskPath, errMsg, cleanDiskDir)
    If rc = 0 Then
        CompilerDebugLog("compiler", "CompilerBuildAsmRunDisk fail err=" & errMsg)
    Else
        CompilerDebugLog("compiler", "CompilerBuildAsmRunDisk ok dsk=" & outDiskPath)
    End If
    Return rc
End Function

' Le um .bin no formato de cabecalho MSX-BASIC (BSAVE/asmsx .BASIC):
' byte 0 = &HFE, bytes 1-2 = endereco inicial, 3-4 = endereco final,
' 5-6 = endereco de execucao (little endian). payload = bytes apos o cabecalho.
Private Function ReadBasicBinHeader(ByRef binPath As String, ByRef startAddr As Integer, ByRef endAddr As Integer, ByRef execAddr As Integer, ByRef payload As String, ByRef errMsg As String) As Integer
    Dim raw As String
    If ReadBinaryFile(binPath, raw, errMsg) = 0 Then Return 0

    If Len(raw) < 7 Then
        errMsg = "Arquivo BIN invalido (menor que o cabecalho): " & binPath
        Return 0
    End If

    If Asc(Mid(raw, 1, 1)) <> &HFE Then
        errMsg = "Arquivo BIN sem cabecalho MSX-BASIC (0xFE): " & binPath
        Return 0
    End If

    startAddr = Asc(Mid(raw, 2, 1)) Or (Asc(Mid(raw, 3, 1)) Shl 8)
    endAddr = Asc(Mid(raw, 4, 1)) Or (Asc(Mid(raw, 5, 1)) Shl 8)
    execAddr = Asc(Mid(raw, 6, 1)) Or (Asc(Mid(raw, 7, 1)) Shl 8)
    payload = Mid(raw, 8)

    Return -1
End Function

Function CompilerReadAsmBinInfo(ByRef binPath As String, ByRef startAddr As Integer, ByRef endAddr As Integer, ByRef execAddr As Integer, ByRef errMsg As String) As Integer
    Dim payload As String
    Return ReadBasicBinHeader(binPath, startAddr, endAddr, execAddr, payload, errMsg)
End Function

' Gera um bloco Basic Dignified que embute os bytes do .bin (sem o cabecalho)
' via DATA/READ/POKE e cria o DEFUSRn correspondente - alternativa ao BLOAD
' para quando o binario precisa ficar auto-contido no proprio .dmx.
' Byte em hex de 2 digitos maiusculos, sem prefixo (formato usado nas
' linhas DATA do carregador: "C9,C3,...", lido de volta com VAL("&H"+A$)).
Private Function ByteHex2(ByVal value As Integer) As String
    Return Right("0" & Hex(value And &HFF), 2)
End Function

Function CompilerBuildAsmDataLoader(ByRef binPath As String, ByRef labelName As String, ByVal usrIndex As Integer, ByRef outCode As String, ByRef errMsg As String) As Integer
    Dim startAddr As Integer
    Dim endAddr As Integer
    Dim execAddr As Integer
    Dim payload As String

    If ReadBasicBinHeader(binPath, startAddr, endAddr, execAddr, payload, errMsg) = 0 Then Return 0

    Dim total As Integer = Len(payload)
    If total <= 0 Then
        errMsg = "Arquivo BIN sem conteudo apos o cabecalho: " & binPath
        Return 0
    End If

    Dim usrTag As String = "USR" & Trim(Str(usrIndex))
    Dim ind As String = "    "

    Dim s As String
    s = "{" & labelName & "}" & Chr(10)
    s &= ind & "' Chame com: A=" & usrTag & "(0)  ou  PRINT " & usrTag & "(0)" & Chr(10)
    s &= ind & "restore {@}" & Chr(10)
    s &= ind & "for asmidx = 0 to &H" & Hex(total - 1) & Chr(10)
    s &= ind & "read asmbytehex$" & Chr(10)
    s &= ind & "poke &H" & Hex(startAddr) & "+asmidx,val(" & Chr(34) & "&h" & Chr(34) & "+asmbytehex$)" & Chr(10)
    s &= ind & "next asmidx" & Chr(10)
    s &= ind & "defusr" & Trim(Str(usrIndex)) & " = &H" & Hex(execAddr) & Chr(10)
    s &= ind & "return" & Chr(10)

    Dim bytePos As Integer = 1
    While bytePos <= total
        Dim lineVals As String = ""
        Dim k As Integer
        For k = 0 To 7
            If bytePos > total Then Exit For
            If Len(lineVals) > 0 Then lineVals &= ","
            lineVals &= ByteHex2(Asc(Mid(payload, bytePos, 1)))
            bytePos += 1
        Next k
        s &= ind & "data " & lineVals & Chr(10)
    Wend

    outCode = s
    Return -1
End Function

' Byte em hex "seguro" pra assembler: sempre com um "0" antes (mesmo quando
' nao precisaria) e sufixo "h", pra nunca ser confundido com um identificador
' quando o primeiro digito hex e uma letra (ex.: C9h vira 0C9h).
Private Function AsmHexByte(ByVal value As Integer) As String
    Return "0" & ByteHex2(value) & "h"
End Function

' Gera um .inc no formato do asmsx (label + DEFB, 8 bytes por linha, hex) com
' os bytes do .bin (sem o cabecalho MSX-BASIC), pra ser incluido em outros
' programas asm via .INCLUDE - so os bytes brutos, sem endereco: a posicao
' fica a cargo de quem inclui.
Function CompilerBuildAsmIncFile(ByRef binPath As String, ByRef srcAsmPath As String, ByRef labelName As String, ByRef outIncPath As String, ByRef errMsg As String) As Integer
    Dim startAddr As Integer
    Dim endAddr As Integer
    Dim execAddr As Integer
    Dim payload As String

    If ReadBasicBinHeader(binPath, startAddr, endAddr, execAddr, payload, errMsg) = 0 Then Return 0

    Dim total As Integer = Len(payload)
    If total <= 0 Then
        errMsg = "Arquivo BIN sem conteudo apos o cabecalho: " & binPath
        Return 0
    End If

    Dim s As String
    s = labelName & ":" & Chr(10)

    Dim bytePos As Integer = 1
    While bytePos <= total
        Dim lineVals As String = ""
        Dim k As Integer
        For k = 0 To 7
            If bytePos > total Then Exit For
            If Len(lineVals) > 0 Then lineVals &= ","
            lineVals &= AsmHexByte(Asc(Mid(payload, bytePos, 1)))
            bytePos += 1
        Next k
        s &= "    defb " & lineVals & Chr(10)
    Wend

    outIncPath = ChangeExt(srcAsmPath, ".inc")
    If WriteTextFile(outIncPath, s, errMsg) = 0 Then Return 0

    Return -1
End Function
