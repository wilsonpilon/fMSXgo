#Include Once "project.bi"
#Include Once "db.bi"
#Include Once "dir.bi"

Const PROJECT_SCHEMA_VERSION = "1"

Dim Shared gProjectPath As String
Dim Shared gProjectDir As String
Dim Shared gProjectName As String

Private Function PathDirOfP(ByRef filePath As String) As String
    Dim lastSlash As Integer = InStrRev(filePath, Chr(92))
    Dim lastFwd As Integer = InStrRev(filePath, "/")
    If lastFwd > lastSlash Then lastSlash = lastFwd
    If lastSlash <= 0 Then Return ""
    Return Left(filePath, lastSlash)
End Function

Private Function BaseNameNoExtP(ByRef filePath As String) As String
    Dim dirPart As String = PathDirOfP(filePath)
    Dim filePart As String = Mid(filePath, Len(dirPart) + 1)
    Dim dotPos As Integer = InStrRev(filePart, ".")
    If dotPos > 0 Then Return Left(filePart, dotPos - 1)
    Return filePart
End Function

Private Function GetExtLowerP(ByRef filePath As String) As String
    Dim p As Integer = InStrRev(filePath, ".")
    If p <= 0 Then Return ""
    Return LCase(Mid(filePath, p))
End Function

' Dir() nao reconhece um diretorio existente quando o caminho termina com
' separador - tira a barra final antes de checar (mesmo cuidado ja tomado em
' compiler.bas: sempre testa sem barra, so anexa depois).
Private Function DirExistsP(ByRef dirPath As String) As Integer
    Dim p As String = dirPath
    If Len(p) > 0 And (Right(p, 1) = Chr(92) Or Right(p, 1) = "/") Then p = Left(p, Len(p) - 1)
    If Len(p) = 0 Then Return -1
    Return IIf(Dir(p, fbDirectory) <> "", -1, 0)
End Function

Private Function ReadBinaryFileP(ByRef filePath As String, ByRef outBytes As String) As Integer
    outBytes = ""
    If Dir(filePath) = "" Then Return 0

    Dim ff As Integer = FreeFile
    If Open(filePath For Binary Access Read As #ff) <> 0 Then Return 0

    Dim sizeBytes As LongInt = Lof(ff)
    If sizeBytes > 0 Then
        outBytes = Space(sizeBytes)
        Get #ff, , outBytes
    End If
    Close #ff
    Return -1
End Function

Private Function WriteBinaryFileP(ByRef filePath As String, ByRef content As String) As Integer
    Dim ff As Integer = FreeFile
    If Open(filePath For Binary Access Write As #ff) <> 0 Then Return 0
    If Len(content) > 0 Then Put #ff, , content
    Close #ff
    Return -1
End Function

Private Function IsTrackedExt(ByRef ext As String) As Integer
    Dim list As String = "|.dmx|.bad|.amx|.asc|.bmx|.bas|.asm|.inc|.bin|.dsk|.md|.alf|.spr|"
    Return IIf(InStr(list, "|" & ext & "|") > 0, -1, 0)
End Function

' Varre um diretorio (raso, sem recursao) por arquivos com extensao
' rastreada, acumulando "prefix & nomeArquivo" em paths().
Private Sub ScanDirInto(ByRef dirPath As String, ByRef prefix As String, paths() As String, ByRef count As Integer)
    Dim entry As String = Dir(dirPath & "*.*")
    While Len(entry) > 0
        If entry <> "." And entry <> ".." Then
            Dim ext As String = GetExtLowerP(entry)
            If IsTrackedExt(ext) <> 0 Then
                count += 1
                If count = 1 Then
                    ReDim paths(1 To 1)
                Else
                    ReDim Preserve paths(1 To count)
                End If
                paths(count) = prefix & entry
            End If
        End If
        entry = Dir()
    Wend
End Sub

Private Function ProjectTemplatePath() As String
    Return CurDir() & Chr(92) & "templates" & Chr(92) & "default.msxproj"
End Function

Function ProjectIsActive() As Integer
    Return DbProjectIsActive()
End Function

Function ProjectActiveName() As String
    Return gProjectName
End Function

Function ProjectActivePath() As String
    Return gProjectPath
End Function

Function ProjectActiveDir() As String
    Return gProjectDir
End Function

' Grava (ou atualiza) o conteudo de um arquivo do projeto direto no banco,
' sem depender de "Salvar Projeto" (scan do disco) - usado pelo editor de
' fontes pra registrar cada .alf assim que e' salvo em disco, ja deixando
' o projeto com o registro atualizado na hora.
Sub ProjectRegisterFile(ByRef relPath As String, ByRef content As String)
    If DbProjectIsActive() = 0 Then Exit Sub
    DbProjectSetFile(relPath, content)
End Sub

' Lista (caminhos relativos ao projeto) todo arquivo ja registrado no banco
' do projeto ativo cuja extensao bata com extLower (ex.: ".alf") - usado
' pelo editor de fontes pra montar a lista de "alfabetos no projeto".
Sub ProjectListFilesWithExt(ByRef extLower As String, paths() As String, ByRef count As Integer)
    count = 0
    If DbProjectIsActive() = 0 Then Exit Sub

    Dim allPaths() As String
    Dim allCount As Integer
    DbProjectListFiles(allPaths(), allCount)

    Dim i As Integer
    For i = 1 To allCount
        If GetExtLowerP(allPaths(i)) = extLower Then
            count += 1
            If count = 1 Then
                ReDim paths(1 To 1)
            Else
                ReDim Preserve paths(1 To count)
            End If
            paths(count) = allPaths(i)
        End If
    Next i
End Sub

Sub ProjectClose()
    DbProjectClose()
    gProjectPath = ""
    gProjectDir = ""
    gProjectName = ""
End Sub

' Extrai todos os arquivos guardados no projeto ativo pra pasta de trabalho
' (gProjectDir), sobrescrevendo copias locais - o banco e sempre quem manda
' na hora de abrir.
Private Function ProjectExtractAll(ByRef errMsg As String) As Integer
    errMsg = ""
    If DbProjectIsActive() = 0 Then
        errMsg = "Nenhum projeto aberto."
        Return 0
    End If

    If DirExistsP(gProjectDir) = 0 Then MkDir gProjectDir

    Dim paths() As String
    Dim count As Integer
    DbProjectListFiles(paths(), count)

    Dim i As Integer
    For i = 1 To count
        Dim relPath As String = paths(i)
        Dim found As Integer
        Dim content As String = DbProjectGetFile(relPath, found)
        If found <> 0 Then
            Dim fullPath As String = gProjectDir & relPath
            Dim fileDir As String = PathDirOfP(fullPath)
            If Len(fileDir) > 0 And DirExistsP(fileDir) = 0 Then MkDir fileDir
            WriteBinaryFileP(fullPath, content)
        End If
    Next i

    Return -1
End Function

Function ProjectNew(ByRef path As String, ByRef errMsg As String) As Integer
    errMsg = ""

    If DbProjectOpen(path) = 0 Then
        errMsg = "Falha ao criar arquivo de projeto: " & path
        Return 0
    End If

    gProjectPath = path
    gProjectDir = PathDirOfP(path)
    If Len(gProjectDir) = 0 Then gProjectDir = CurDir() & Chr(92)
    gProjectName = BaseNameNoExtP(path)

    DbProjectSetMeta("name", gProjectName)
    DbProjectSetMeta("schema_version", PROJECT_SCHEMA_VERSION)
    DbProjectSetMeta("created_at", Date & " " & Time)

    Dim templatePath As String = ProjectTemplatePath()
    If Dir(templatePath) <> "" And LCase(templatePath) <> LCase(path) Then
        DbProjectCopyFromTemplate(templatePath)
    End If

    Return ProjectExtractAll(errMsg)
End Function

Function ProjectOpen(ByRef path As String, ByRef errMsg As String) As Integer
    errMsg = ""

    If Dir(path) = "" Then
        errMsg = "Arquivo de projeto nao encontrado: " & path
        Return 0
    End If

    If DbProjectOpen(path) = 0 Then
        errMsg = "Falha ao abrir arquivo de projeto: " & path
        Return 0
    End If

    gProjectPath = path
    gProjectDir = PathDirOfP(path)
    If Len(gProjectDir) = 0 Then gProjectDir = CurDir() & Chr(92)
    gProjectName = DbProjectGetMeta("name", BaseNameNoExtP(path))

    Return ProjectExtractAll(errMsg)
End Function

' Varre a pasta de trabalho (raiz + disk\) e reimporta tudo que bate com a
' whitelist de extensoes pro banco do projeto.
Function ProjectSave(ByRef errMsg As String, ByRef savedCount As Integer) As Integer
    errMsg = ""
    savedCount = 0
    If DbProjectIsActive() = 0 Then
        errMsg = "Nenhum projeto aberto."
        Return 0
    End If

    Dim paths() As String
    Dim count As Integer = 0
    ScanDirInto(gProjectDir, "", paths(), count)

    Dim diskSubdirNoSep As String = gProjectDir & "disk"
    If DirExistsP(diskSubdirNoSep) <> 0 Then
        ScanDirInto(diskSubdirNoSep & Chr(92), "disk" & Chr(92), paths(), count)
    End If

    Dim romsSubdirNoSep As String = gProjectDir & "roms"
    If DirExistsP(romsSubdirNoSep) <> 0 Then
        ScanDirInto(romsSubdirNoSep & Chr(92), "roms" & Chr(92), paths(), count)
    End If

    Dim i As Integer
    For i = 1 To count
        Dim content As String
        If ReadBinaryFileP(gProjectDir & paths(i), content) <> 0 Then
            DbProjectSetFile(paths(i), content)
            savedCount += 1
        End If
    Next i

    DbProjectSetMeta("last_saved_at", Date & " " & Time)
    Return -1
End Function
