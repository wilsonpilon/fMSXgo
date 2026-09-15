#Include Once "../../src/db.bi"
#Include Once "../../src/compiler.bi"

Dim Shared failures As Integer = 0
Dim Shared checks As Integer = 0

Const DSK_SECTOR_SIZE = 512
Const DSK_RESERVED = 1
Const DSK_FAT_COUNT = 2
Const DSK_SECTORS_PER_FAT = 3
Const DSK_ROOT_SECTORS = 7
Const DSK_CLUSTER_SECTORS = 2

Private Sub Report(ByRef labelText As String, ByVal ok As Integer, ByRef detail As String = "")
    checks += 1
    If ok <> 0 Then
        Print "OK   - " & labelText
    Else
        Print "FAIL - " & labelText & IIf(Len(detail) > 0, " -> " & detail, "")
        failures += 1
    End If
End Sub

Private Function ReadBinary(ByRef pathName As String, ByRef outData As String) As Integer
    outData = ""
    If Dir(pathName) = "" Then Return 0

    Dim ff As Integer = FreeFile
    If Open(pathName For Binary Access Read As #ff) <> 0 Then Return 0

    Dim n As LongInt = Lof(ff)
    If n > 0 Then
        outData = Space(n)
        Get #ff, , outData
    End If

    Close #ff
    Return -1
End Function

Private Function ByteAt(ByRef raw As String, ByVal off0 As Integer) As Integer
    If off0 < 0 Or off0 >= Len(raw) Then Return 0
    Return Asc(Mid(raw, off0 + 1, 1))
End Function

Private Function ReadWordLE(ByRef raw As String, ByVal off0 As Integer) As Integer
    Return ByteAt(raw, off0) Or (ByteAt(raw, off0 + 1) Shl 8)
End Function

Private Function ReadDwordLE(ByRef raw As String, ByVal off0 As Integer) As LongInt
    Dim a As LongInt = ByteAt(raw, off0)
    Dim b As LongInt = ByteAt(raw, off0 + 1)
    Dim c As LongInt = ByteAt(raw, off0 + 2)
    Dim d As LongInt = ByteAt(raw, off0 + 3)
    Return a Or (b Shl 8) Or (c Shl 16) Or (d Shl 24)
End Function

Private Function Fat12GetEntry(ByRef fat As String, ByVal cluster As Integer) As Integer
    Dim off0 As Integer = (cluster * 3) \ 2
    Dim b0 As Integer = ByteAt(fat, off0)
    Dim b1 As Integer = ByteAt(fat, off0 + 1)

    If (cluster And 1) = 0 Then
        Return b0 Or ((b1 And &H0F) Shl 8)
    Else
        Return ((b0 And &HF0) Shr 4) Or (b1 Shl 4)
    End If
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
    If dotPos > 0 Then Return Left(filePart, dotPos - 1)
    Return filePart
End Function

Private Function ToDos83Name(ByRef fileName As String) As String
    Dim src As String = UCase(Trim(fileName))
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

    Dim cleanBase As String = ""
    Dim cleanExt As String = ""
    Dim i As Integer
    For i = 1 To Len(baseName)
        Dim c As Integer = Asc(Mid(baseName, i, 1))
        If (c >= Asc("A") And c <= Asc("Z")) Or (c >= Asc("0") And c <= Asc("9")) Or c = Asc("_") Then
            cleanBase &= Chr(c)
        Else
            cleanBase &= "_"
        End If
    Next i
    For i = 1 To Len(extName)
        Dim c As Integer = Asc(Mid(extName, i, 1))
        If (c >= Asc("A") And c <= Asc("Z")) Or (c >= Asc("0") And c <= Asc("9")) Or c = Asc("_") Then
            cleanExt &= Chr(c)
        Else
            cleanExt &= "_"
        End If
    Next i

    cleanBase = Left(cleanBase, 8)
    cleanExt = Left(cleanExt, 3)
    Return cleanBase & String(8 - Len(cleanBase), " ") & cleanExt & String(3 - Len(cleanExt), " ")
End Function

Private Function ExtractFromDsk(ByRef dskData As String, ByRef dos83 As String, ByRef outData As String, ByRef errMsg As String) As Integer
    outData = ""
    errMsg = ""

    Dim rootOffset As Integer = (DSK_RESERVED + DSK_FAT_COUNT * DSK_SECTORS_PER_FAT) * DSK_SECTOR_SIZE
    Dim dataOffset As Integer = (DSK_RESERVED + DSK_FAT_COUNT * DSK_SECTORS_PER_FAT + DSK_ROOT_SECTORS) * DSK_SECTOR_SIZE
    Dim clusterSize As Integer = DSK_CLUSTER_SECTORS * DSK_SECTOR_SIZE
    Dim fatOffset As Integer = DSK_RESERVED * DSK_SECTOR_SIZE
    Dim fatBytes As Integer = DSK_SECTORS_PER_FAT * DSK_SECTOR_SIZE
    Dim fat As String = Mid(dskData, fatOffset + 1, fatBytes)

    Dim entry As Integer
    For entry = 0 To 111
        Dim off0 As Integer = rootOffset + entry * 32
        Dim first As Integer = ByteAt(dskData, off0)
        If first = 0 Then Exit For
        If first = &HE5 Then Continue For

        Dim name11 As String = Mid(dskData, off0 + 1, 11)
        If name11 = dos83 Then
            Dim fileSize As LongInt = ReadDwordLE(dskData, off0 + 28)
            Dim cluster As Integer = ReadWordLE(dskData, off0 + 26)
            If fileSize <= 0 Then
                outData = ""
                Return -1
            End If

            Dim remain As LongInt = fileSize
            Do While remain > 0
                If cluster < 2 Or cluster >= &HFF8 Then Exit Do
                Dim chunk As Integer = clusterSize
                If remain < chunk Then chunk = remain

                Dim srcOff As Integer = dataOffset + (cluster - 2) * clusterSize
                outData &= Mid(dskData, srcOff + 1, chunk)
                remain -= chunk

                cluster = Fat12GetEntry(fat, cluster)
            Loop

            If Len(outData) <> fileSize Then
                errMsg = "Tamanho extraido difere: " & dos83
                Return 0
            End If

            Return -1
        End If
    Next entry

    errMsg = "Arquivo nao encontrado no DSK: " & dos83
    Return 0
End Function

Private Function ValidateDskRootStructure(ByRef dskData As String, ByRef baseName As String, ByVal includeDmx As Integer, ByRef errMsg As String) As Integer
    errMsg = ""

    Dim expectedNames(1 To 4) As String
    Dim expectedAttr(1 To 4) As Integer
    Dim expectedCount As Integer = 0

    If includeDmx <> 0 Then
        expectedCount += 1
        expectedNames(expectedCount) = ToDos83Name(baseName & ".DMX")
        expectedAttr(expectedCount) = &H20
    End If

    expectedCount += 1
    expectedNames(expectedCount) = ToDos83Name(baseName & ".AMX")
    expectedAttr(expectedCount) = &H20

    expectedCount += 1
    expectedNames(expectedCount) = ToDos83Name(baseName & ".BMX")
    expectedAttr(expectedCount) = &H20

    expectedCount += 1
    expectedNames(expectedCount) = ToDos83Name("AUTOEXEC.BAS")
    expectedAttr(expectedCount) = &H20

    Dim rootOffset As Integer = (DSK_RESERVED + DSK_FAT_COUNT * DSK_SECTORS_PER_FAT) * DSK_SECTOR_SIZE
    Dim idx As Integer
    For idx = 1 To expectedCount
        Dim off0 As Integer = rootOffset + (idx - 1) * 32
        Dim first As Integer = ByteAt(dskData, off0)
        If first = 0 Then
            errMsg = "Entrada raiz ausente na posicao " & idx
            Return 0
        End If
        If first = &HE5 Then
            errMsg = "Entrada deletada inesperada na posicao " & idx
            Return 0
        End If

        Dim gotName As String = Mid(dskData, off0 + 1, 11)
        If gotName <> expectedNames(idx) Then
            errMsg = "Ordem root invalida na posicao " & idx & ": esperado " & expectedNames(idx) & " obtido " & gotName
            Return 0
        End If

        Dim gotAttr As Integer = ByteAt(dskData, off0 + 11)
        If gotAttr <> expectedAttr(idx) Then
            errMsg = "Atributo invalido para " & expectedNames(idx) & ": esperado " & Hex(expectedAttr(idx), 2) & " obtido " & Hex(gotAttr, 2)
            Return 0
        End If
    Next idx

    ' Root directory should terminate right after the expected files.
    Dim endOff As Integer = rootOffset + expectedCount * 32
    If ByteAt(dskData, endOff) <> 0 Then
        errMsg = "Root directory contem entradas extras apos o conjunto esperado"
        Return 0
    End If

    Return -1
End Function

Private Function FindRootEntryOffset(ByRef dskData As String, ByRef dos83 As String, ByRef outOff0 As Integer) As Integer
    outOff0 = -1
    Dim rootOffset As Integer = (DSK_RESERVED + DSK_FAT_COUNT * DSK_SECTORS_PER_FAT) * DSK_SECTOR_SIZE

    Dim entry As Integer
    For entry = 0 To 111
        Dim off0 As Integer = rootOffset + entry * 32
        Dim first As Integer = ByteAt(dskData, off0)
        If first = 0 Then Exit For
        If first = &HE5 Then Continue For

        If Mid(dskData, off0 + 1, 11) = dos83 Then
            outOff0 = off0
            Return -1
        End If
    Next entry

    Return 0
End Function

Private Function ValidateDskEntryMetadata(ByRef dskData As String, ByRef dos83 As String, ByRef expectedData As String, ByRef extractedData As String, ByRef errMsg As String) As Integer
    errMsg = ""

    Dim off0 As Integer
    If FindRootEntryOffset(dskData, dos83, off0) = 0 Then
        errMsg = "Meta nao encontrada no root: " & dos83
        Return 0
    End If

    Dim fileSize As LongInt = ReadDwordLE(dskData, off0 + 28)
    Dim startCluster As Integer = ReadWordLE(dskData, off0 + 26)
    Dim expectedSize As LongInt = Len(expectedData)
    Dim extractedSize As LongInt = Len(extractedData)

    If fileSize <> expectedSize Then
        errMsg = "Tamanho root difere do arquivo gerado em " & dos83 & ": root=" & fileSize & " esperado=" & expectedSize
        Return 0
    End If
    If fileSize <> extractedSize Then
        errMsg = "Tamanho root difere do extraido em " & dos83 & ": root=" & fileSize & " extraido=" & extractedSize
        Return 0
    End If

    Dim clusterSize As Integer = DSK_CLUSTER_SECTORS * DSK_SECTOR_SIZE
    Dim neededClusters As Integer = 0
    If fileSize > 0 Then neededClusters = (fileSize + clusterSize - 1) \ clusterSize

    If neededClusters = 0 Then
        If startCluster <> 0 Then
            errMsg = "Arquivo vazio deve iniciar no cluster 0: " & dos83
            Return 0
        End If
        Return -1
    End If

    If startCluster < 2 Or startCluster >= &HFF8 Then
        errMsg = "Cluster inicial invalido em " & dos83 & ": " & startCluster
        Return 0
    End If

    Dim fatOffset As Integer = DSK_RESERVED * DSK_SECTOR_SIZE
    Dim fatBytes As Integer = DSK_SECTORS_PER_FAT * DSK_SECTOR_SIZE
    Dim fat As String = Mid(dskData, fatOffset + 1, fatBytes)
    Dim visited(0 To 4095) As UByte

    Dim cur As Integer = startCluster
    Dim n As Integer
    For n = 1 To neededClusters
        If cur < 2 Or cur > 4095 Then
            errMsg = "Cluster fora de faixa na cadeia FAT: " & dos83
            Return 0
        End If
        If visited(cur) <> 0 Then
            errMsg = "Loop detectado na cadeia FAT: " & dos83
            Return 0
        End If
        visited(cur) = 1

        Dim fatEntryOffset As Integer = (cur * 3) \ 2
        If fatEntryOffset + 1 >= Len(fat) Then
            errMsg = "Cadeia FAT excede tabela: " & dos83
            Return 0
        End If

        Dim nxt As Integer = Fat12GetEntry(fat, cur)
        If n < neededClusters Then
            If nxt < 2 Or nxt >= &HFF8 Then
                errMsg = "Cadeia FAT curta para " & dos83
                Return 0
            End If
            cur = nxt
        Else
            If nxt < &HFF8 Or nxt > &HFFF Then
                errMsg = "Cadeia FAT sem terminador EOC em " & dos83
                Return 0
            End If
        End If
    Next n

    Return -1
End Function

Private Function ValidateDosDateWord(ByVal dosDate As Integer) As Integer
    If dosDate = 0 Then Return -1

    Dim dayVal As Integer = dosDate And &H1F
    Dim monthVal As Integer = (dosDate Shr 5) And &H0F
    Dim yearVal As Integer = ((dosDate Shr 9) And &H7F) + 1980

    If yearVal < 1980 Or yearVal > 2107 Then Return 0
    If monthVal < 1 Or monthVal > 12 Then Return 0
    If dayVal < 1 Or dayVal > 31 Then Return 0
    Return -1
End Function

Private Function ValidateDosTimeWord(ByVal dosTime As Integer) As Integer
    If dosTime = 0 Then Return -1

    Dim sec2 As Integer = dosTime And &H1F
    Dim minVal As Integer = (dosTime Shr 5) And &H3F
    Dim hourVal As Integer = (dosTime Shr 11) And &H1F

    If hourVal < 0 Or hourVal > 23 Then Return 0
    If minVal < 0 Or minVal > 59 Then Return 0
    If sec2 < 0 Or sec2 > 29 Then Return 0
    Return -1
End Function

Private Function ValidateDskEntryDosTimestamps(ByRef dskData As String, ByRef dos83 As String, ByRef errMsg As String) As Integer
    errMsg = ""

    Dim off0 As Integer
    If FindRootEntryOffset(dskData, dos83, off0) = 0 Then
        errMsg = "Timestamp nao encontrado no root: " & dos83
        Return 0
    End If

    Dim crtTime As Integer = ReadWordLE(dskData, off0 + 14)
    Dim crtDate As Integer = ReadWordLE(dskData, off0 + 16)
    Dim accDate As Integer = ReadWordLE(dskData, off0 + 18)
    Dim wrtTime As Integer = ReadWordLE(dskData, off0 + 22)
    Dim wrtDate As Integer = ReadWordLE(dskData, off0 + 24)

    If ValidateDosTimeWord(crtTime) = 0 Then
        errMsg = "Create time DOS invalido em " & dos83
        Return 0
    End If
    If ValidateDosDateWord(crtDate) = 0 Then
        errMsg = "Create date DOS invalida em " & dos83
        Return 0
    End If
    If ValidateDosDateWord(accDate) = 0 Then
        errMsg = "Access date DOS invalida em " & dos83
        Return 0
    End If
    If ValidateDosTimeWord(wrtTime) = 0 Then
        errMsg = "Write time DOS invalido em " & dos83
        Return 0
    End If
    If ValidateDosDateWord(wrtDate) = 0 Then
        errMsg = "Write date DOS invalida em " & dos83
        Return 0
    End If

    ' Guard consistency when any timestamp/date starts being populated.
    If (wrtDate <> 0 And wrtTime = 0) Or (wrtTime <> 0 And wrtDate = 0) Then
        errMsg = "Write date/time parcial em " & dos83
        Return 0
    End If

    Return -1
End Function

Private Function CompareFiles(ByRef pathLeft As String, ByRef pathRight As String) As Integer
    Dim a As String
    Dim b As String
    If ReadBinary(pathLeft, a) = 0 Then Return 0
    If ReadBinary(pathRight, b) = 0 Then Return 0
    If Len(a) <> Len(b) Then Return 0
    Return IIf(a = b, -1, 0)
End Function

Private Sub DeleteIfExists(ByRef filePath As String)
    If Dir(filePath) <> "" Then Kill filePath
End Sub

Private Sub RunFixture(ByRef inputPath As String, ByRef expectedAmx As String, ByRef expectedBmx As String, ByRef printMode As String = "", ByRef ifJumpMode As String = "")
    Dim errMsg As String
    Dim outAmx As String
    Dim outBmx As String

    If Len(Trim(printMode)) > 0 Then DbSetSetting("cfg.msxbasic.badig.convert_print", printMode)
    If Len(Trim(ifJumpMode)) > 0 Then DbSetSetting("cfg.msxbasic.badig.strip_then_goto", ifJumpMode)

    If CompilerCompileToBmx(inputPath, outAmx, outBmx, errMsg) = 0 Then
        Report("compile " & inputPath, 0, errMsg)
        Exit Sub
    End If

    Report("amx exists " & outAmx, IIf(Dir(outAmx) <> "", -1, 0))
    Report("bmx exists " & outBmx, IIf(Dir(outBmx) <> "", -1, 0))

    Report("amx matches " & inputPath, CompareFiles(outAmx, expectedAmx), expectedAmx)
    Report("bmx matches " & inputPath, CompareFiles(outBmx, expectedBmx), expectedBmx)

    Dim dskPath As String
    If CompilerBuildRunDisk(inputPath, outAmx, outBmx, dskPath, errMsg) = 0 Then
        Report("dsk build " & inputPath, 0, errMsg)
        Exit Sub
    End If

    Report("dsk exists " & inputPath, IIf(Dir(dskPath) <> "", -1, 0), dskPath)

    Dim dskRaw As String
    If ReadBinary(dskPath, dskRaw) = 0 Then
        Report("dsk read " & inputPath, 0, dskPath)
        Exit Sub
    End If

    Dim baseName As String = UCase(BaseNameNoExt(inputPath))
    baseName = Left(baseName, 8)

    Dim hasDmx As Integer = 0
    Dim inExt As String = LCase(Right(inputPath, 4))
    If inExt = ".dmx" Or inExt = ".bad" Then hasDmx = -1

    Dim structErr As String
    Report("dsk root structure " & inputPath, ValidateDskRootStructure(dskRaw, baseName, hasDmx, structErr), structErr)

    Dim amxExp As String
    Dim bmxExp As String
    If ReadBinary(outAmx, amxExp) = 0 Then Report("read amx for dsk " & inputPath, 0, outAmx)
    If ReadBinary(outBmx, bmxExp) = 0 Then Report("read bmx for dsk " & inputPath, 0, outBmx)

    Dim ex As String
    Dim got As String
    Dim dskErr As String

    Dim amx83 As String = ToDos83Name(baseName & ".AMX")
    Dim bmx83 As String = ToDos83Name(baseName & ".BMX")
    Dim auto83 As String = ToDos83Name("AUTOEXEC.BAS")
    Dim dmx83 As String = ToDos83Name(baseName & ".DMX")
    Dim expectedAutoexec As String = "10 RUN " & Chr(34) & baseName & ".BMX" & Chr(34) & Chr(13) & Chr(10)

    If hasDmx <> 0 Then
        Report("dsk dmx dos datetime " & inputPath, ValidateDskEntryDosTimestamps(dskRaw, dmx83, dskErr), dskErr)
    End If

    If ExtractFromDsk(dskRaw, amx83, got, dskErr) = 0 Then
        Report("dsk has amx " & inputPath, 0, dskErr)
    Else
        Report("dsk amx bytes " & inputPath, IIf(got = amxExp, -1, 0), amx83)
        Report("dsk amx metadata " & inputPath, ValidateDskEntryMetadata(dskRaw, amx83, amxExp, got, dskErr), dskErr)
        Report("dsk amx dos datetime " & inputPath, ValidateDskEntryDosTimestamps(dskRaw, amx83, dskErr), dskErr)
    End If

    If ExtractFromDsk(dskRaw, bmx83, got, dskErr) = 0 Then
        Report("dsk has bmx " & inputPath, 0, dskErr)
    Else
        Report("dsk bmx bytes " & inputPath, IIf(got = bmxExp, -1, 0), bmx83)
        Report("dsk bmx metadata " & inputPath, ValidateDskEntryMetadata(dskRaw, bmx83, bmxExp, got, dskErr), dskErr)
        Report("dsk bmx dos datetime " & inputPath, ValidateDskEntryDosTimestamps(dskRaw, bmx83, dskErr), dskErr)
    End If

    If ExtractFromDsk(dskRaw, auto83, got, dskErr) = 0 Then
        Report("dsk has autoexec " & inputPath, 0, dskErr)
    Else
        Report("dsk autoexec bytes " & inputPath, IIf(got = expectedAutoexec, -1, 0), "AUTOEXEC.BAS")
        Report("dsk autoexec metadata " & inputPath, ValidateDskEntryMetadata(dskRaw, auto83, expectedAutoexec, got, dskErr), dskErr)
        Report("dsk autoexec dos datetime " & inputPath, ValidateDskEntryDosTimestamps(dskRaw, auto83, dskErr), dskErr)
    End If
End Sub

DbInit("test_regression.db")

DeleteIfExists("fixtures/inputs/loops_labels.amx")
DeleteIfExists("fixtures/inputs/loops_labels.bmx")
DeleteIfExists("fixtures/inputs/include_define.amx")
DeleteIfExists("fixtures/inputs/include_define.bmx")
DeleteIfExists("fixtures/outputs/remtags_custom.amx")
DeleteIfExists("fixtures/outputs/remtags_custom.bmx")
DeleteIfExists("fixtures/outputs/remtags_extra_custom.amx")
DeleteIfExists("fixtures/outputs/remtags_extra_custom.bmx")
DeleteIfExists("fixtures/inputs/float_scientific.amx")
DeleteIfExists("fixtures/inputs/float_scientific.bmx")
DeleteIfExists("fixtures/inputs/ns_main_big.amx")
DeleteIfExists("fixtures/inputs/ns_main_big.bmx")
DeleteIfExists("fixtures/inputs/msxbasic_modes.amx")
DeleteIfExists("fixtures/inputs/msxbasic_modes.bmx")

RunFixture(CurDir() & Chr(92) & "fixtures" & Chr(92) & "inputs" & Chr(92) & "loops_labels.dmx", _
           "fixtures/expected/loops_labels.amx", _
           "fixtures/expected/loops_labels.bmx")

RunFixture("fixtures/inputs/include_define.dmx", _
           "fixtures/expected/include_define.amx", _
           "fixtures/expected/include_define.bmx")

RunFixture("fixtures/inputs/remtags_export.dmx", _
           "fixtures/expected/remtags_export.amx", _
           "fixtures/expected/remtags_export.bmx")

RunFixture("fixtures/inputs/float_scientific.dmx", _
           "fixtures/expected/float_scientific.amx", _
           "fixtures/expected/float_scientific.bmx")

RunFixture("fixtures/inputs/ns_main_big.dmx", _
           "fixtures/expected/ns_main_big.amx", _
           "fixtures/expected/ns_main_big.bmx")

RunFixture("fixtures/inputs/remtags_extra.dmx", _
           "fixtures/expected/remtags_extra.amx", _
           "fixtures/expected/remtags_extra.bmx")

RunFixture("fixtures/inputs/msxbasic_modes.dmx", _
           "fixtures/expected/msxbasic_modes_q_then.amx", _
           "fixtures/expected/msxbasic_modes_q_then.bmx", _
           "?", "THEN")

RunFixture("fixtures/inputs/msxbasic_modes.dmx", _
           "fixtures/expected/msxbasic_modes_print_goto.amx", _
           "fixtures/expected/msxbasic_modes_print_goto.bmx", _
           "PRINT", "GOTO")

DbShutdown()

Print ""
If failures = 0 Then
    Print "REGRESSION OK: " & checks & " checks"
    End 0
Else
    Print "REGRESSION FAIL: " & failures & " of " & checks & " checks"
    End 1
End If
