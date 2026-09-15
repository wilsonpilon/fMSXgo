#Include Once "db.bi"

Type sqlite3 As Any
Type sqlite3_stmt As Any

Const SQLITE_OK = 0
Const SQLITE_ROW = 100
Const SQLITE_DONE = 101

Dim Shared gDb As sqlite3 Ptr
Dim Shared gProjectDb As sqlite3 Ptr
Dim Shared gSqliteDll As Any Ptr

Declare Function CMemCpy Cdecl Alias "memcpy" (ByVal dest As Any Ptr, ByVal src As Any Ptr, ByVal n As Integer) As Any Ptr

Dim Shared p_sqlite3_open As Function Cdecl (ByVal filename As ZString Ptr, ByVal ppDb As sqlite3 Ptr Ptr) As Integer
Dim Shared p_sqlite3_close As Function Cdecl (ByVal db As sqlite3 Ptr) As Integer
Dim Shared p_sqlite3_exec As Function Cdecl (ByVal db As sqlite3 Ptr, ByVal sql As ZString Ptr, ByVal callback As Any Ptr, ByVal arg As Any Ptr, ByVal errMsg As ZString Ptr Ptr) As Integer
Dim Shared p_sqlite3_free As Sub Cdecl (ByVal p As Any Ptr)
Dim Shared p_sqlite3_prepare_v2 As Function Cdecl (ByVal db As sqlite3 Ptr, ByVal zSql As ZString Ptr, ByVal nByte As Integer, ByVal ppStmt As sqlite3_stmt Ptr Ptr, ByVal pzTail As ZString Ptr Ptr) As Integer
Dim Shared p_sqlite3_step As Function Cdecl (ByVal pStmt As sqlite3_stmt Ptr) As Integer
Dim Shared p_sqlite3_finalize As Function Cdecl (ByVal pStmt As sqlite3_stmt Ptr) As Integer
Dim Shared p_sqlite3_bind_text As Function Cdecl (ByVal pStmt As sqlite3_stmt Ptr, ByVal idx As Integer, ByVal txt As ZString Ptr, ByVal n As Integer, ByVal dtor As Any Ptr) As Integer
Dim Shared p_sqlite3_bind_int As Function Cdecl (ByVal pStmt As sqlite3_stmt Ptr, ByVal idx As Integer, ByVal value As Integer) As Integer
Dim Shared p_sqlite3_bind_double As Function Cdecl (ByVal pStmt As sqlite3_stmt Ptr, ByVal idx As Integer, ByVal value As Double) As Integer
Dim Shared p_sqlite3_bind_blob As Function Cdecl (ByVal pStmt As sqlite3_stmt Ptr, ByVal idx As Integer, ByVal blob As Any Ptr, ByVal n As Integer, ByVal dtor As Any Ptr) As Integer
Dim Shared p_sqlite3_column_text As Function Cdecl (ByVal pStmt As sqlite3_stmt Ptr, ByVal col As Integer) As ZString Ptr
Dim Shared p_sqlite3_column_blob As Function Cdecl (ByVal pStmt As sqlite3_stmt Ptr, ByVal col As Integer) As Any Ptr
Dim Shared p_sqlite3_column_bytes As Function Cdecl (ByVal pStmt As sqlite3_stmt Ptr, ByVal col As Integer) As Integer

Private Function ResolveSqliteSymbols() As Integer
    p_sqlite3_open = DyLibSymbol(gSqliteDll, "sqlite3_open")
    p_sqlite3_close = DyLibSymbol(gSqliteDll, "sqlite3_close")
    p_sqlite3_exec = DyLibSymbol(gSqliteDll, "sqlite3_exec")
    p_sqlite3_free = DyLibSymbol(gSqliteDll, "sqlite3_free")
    p_sqlite3_prepare_v2 = DyLibSymbol(gSqliteDll, "sqlite3_prepare_v2")
    p_sqlite3_step = DyLibSymbol(gSqliteDll, "sqlite3_step")
    p_sqlite3_finalize = DyLibSymbol(gSqliteDll, "sqlite3_finalize")
    p_sqlite3_bind_text = DyLibSymbol(gSqliteDll, "sqlite3_bind_text")
    p_sqlite3_bind_int = DyLibSymbol(gSqliteDll, "sqlite3_bind_int")
    p_sqlite3_bind_double = DyLibSymbol(gSqliteDll, "sqlite3_bind_double")
    p_sqlite3_bind_blob = DyLibSymbol(gSqliteDll, "sqlite3_bind_blob")
    p_sqlite3_column_text = DyLibSymbol(gSqliteDll, "sqlite3_column_text")
    p_sqlite3_column_blob = DyLibSymbol(gSqliteDll, "sqlite3_column_blob")
    p_sqlite3_column_bytes = DyLibSymbol(gSqliteDll, "sqlite3_column_bytes")

    If p_sqlite3_open = 0 Then Return 0
    If p_sqlite3_close = 0 Then Return 0
    If p_sqlite3_exec = 0 Then Return 0
    If p_sqlite3_free = 0 Then Return 0
    If p_sqlite3_prepare_v2 = 0 Then Return 0
    If p_sqlite3_step = 0 Then Return 0
    If p_sqlite3_finalize = 0 Then Return 0
    If p_sqlite3_bind_text = 0 Then Return 0
    If p_sqlite3_bind_int = 0 Then Return 0
    If p_sqlite3_bind_double = 0 Then Return 0
    If p_sqlite3_bind_blob = 0 Then Return 0
    If p_sqlite3_column_text = 0 Then Return 0
    If p_sqlite3_column_blob = 0 Then Return 0
    If p_sqlite3_column_bytes = 0 Then Return 0

    Return -1
End Function

Private Sub ExecSqlOn(ByVal db As sqlite3 Ptr, ByRef sql As String)
    Dim As ZString Ptr errMsg = 0
    Dim rc As Integer = p_sqlite3_exec(db, StrPtr(sql), 0, 0, @errMsg)
    If rc <> SQLITE_OK Then
        If errMsg <> 0 Then
            p_sqlite3_free(errMsg)
        End If
    End If
End Sub

Private Sub ExecSql(ByRef sql As String)
    Dim As ZString Ptr errMsg = 0
    Dim rc As Integer = p_sqlite3_exec(gDb, StrPtr(sql), 0, 0, @errMsg)
    If rc <> SQLITE_OK Then
        If errMsg <> 0 Then
            Print "SQLite error: "; *errMsg
            p_sqlite3_free(errMsg)
        End If
    End If
End Sub

Private Function SettingExists(ByRef keyName As String) As Integer
    Dim sql As String = "SELECT value FROM settings WHERE key = ? LIMIT 1;"
    Dim stmt As sqlite3_stmt Ptr

    If p_sqlite3_prepare_v2(gDb, StrPtr(sql), -1, @stmt, 0) <> SQLITE_OK Then Return 0
    p_sqlite3_bind_text(stmt, 1, StrPtr(keyName), -1, Cast(Any Ptr, -1))

    Dim found As Integer = IIf(p_sqlite3_step(stmt) = SQLITE_ROW, -1, 0)
    p_sqlite3_finalize(stmt)
    Return found
End Function

Private Sub DbSetSettingIfMissing(ByRef keyName As String, ByRef keyValue As String)
    If SettingExists(keyName) = 0 Then
        DbSetSetting(keyName, keyValue)
    End If
End Sub

Private Function ReadTextFile(ByRef filePath As String) As String
    If Len(filePath) = 0 Then Return ""
    If Dir(filePath) = "" Then Return ""

    Dim ff As Integer = FreeFile
    Dim lineText As String
    Dim outText As String = ""

    If Open(filePath For Input As #ff) <> 0 Then Return ""
    While Not Eof(ff)
        Line Input #ff, lineText
        outText &= lineText
        If Not Eof(ff) Then outText &= Chr(10)
    Wend
    Close #ff
    Return outText
End Function

Private Sub SeedConfigFromIni(ByRef configGroup As String, ByRef iniPath As String, ByRef keyPrefix As String = "")
    If Len(iniPath) = 0 Then Exit Sub
    If Dir(iniPath) = "" Then Exit Sub

    Dim ff As Integer = FreeFile
    Dim rawLine As String
    Dim secName As String = "configs"

    If Open(iniPath For Input As #ff) <> 0 Then Exit Sub
    While Not Eof(ff)
        Line Input #ff, rawLine
        Dim t As String = Trim(rawLine)

        If Len(t) = 0 Then Continue While
        If Left(t, 1) = ";" Then Continue While
        If Left(t, 1) = "#" Then Continue While

        If Left(t, 1) = "[" And Right(t, 1) = "]" Then
            secName = LCase(Trim(Mid(t, 2, Len(t) - 2)))
            Continue While
        End If

        Dim eqPos As Integer = InStr(t, "=")
        If eqPos <= 0 Then Continue While

        Dim k As String = LCase(Trim(Left(t, eqPos - 1)))
        Dim v As String = Trim(Mid(t, eqPos + 1))
        If Len(k) = 0 Then Continue While

        Dim idKey As String
        If secName = "configs" Then
            idKey = keyPrefix & k
        Else
            idKey = keyPrefix & secName & "." & k
        End If

        DbSetSettingIfMissing("cfg." & configGroup & "." & idKey, v)
    Wend
    Close #ff
End Sub

Private Sub SeedHelpDoc(ByRef docName As String, ByRef fallbackPath As String)
    Dim keyName As String = "help." & LCase(docName)
    Dim content As String = ReadTextFile(fallbackPath)
    If Len(content) > 0 Then DbSetSetting(keyName, content)
End Sub

Private Sub AppendConfigLine(ByRef target As String, ByRef lineText As String)
    target &= lineText & Chr(10)
End Sub

Private Function CfgKey(ByRef configGroup As String, ByRef settingKey As String) As String
    Return "cfg." & LCase(configGroup) & "." & LCase(settingKey)
End Function

Private Function NormalizeMsxConvertPrint(ByRef rawValue As String) As String
    Dim t As String = UCase(Trim(rawValue))
    If t = "PRINT" Or t = "?" Then Return t
    If t = "TRUE" Or t = "1" Or t = "YES" Or t = "ON" Or t = "Y" Then Return "?"
    If t = "FALSE" Or t = "0" Or t = "NO" Or t = "OFF" Or t = "N" Then Return "PRINT"
    Return "PRINT"
End Function

Private Function NormalizeMsxThenGoto(ByRef rawValue As String) As String
    Dim t As String = UCase(Trim(rawValue))
    If t = "THEN" Or t = "GOTO" Then Return t
    If t = "TRUE" Or t = "1" Or t = "YES" Or t = "ON" Or t = "Y" Then Return "THEN"
    If t = "FALSE" Or t = "0" Or t = "NO" Or t = "OFF" Or t = "N" Then Return "GOTO"
    Return "THEN"
End Function

Private Function StripCR(ByRef textIn As String) As String
    Dim outText As String = ""
    Dim i As Integer
    For i = 1 To Len(textIn)
        Dim ch As String = Mid(textIn, i, 1)
        If ch <> Chr(13) Then outText &= ch
    Next i
    Return outText
End Function

Sub DbInit(ByRef dbPath As String)
    gSqliteDll = DyLibLoad("sqlite3.dll")
    If gSqliteDll = 0 Then
        Print "Nao foi possivel carregar sqlite3.dll."
        Print "Coloque sqlite3.dll ao lado do executavel ou no PATH."
        End 1
    End If

    If ResolveSqliteSymbols() = 0 Then
        Print "sqlite3.dll carregada, mas com simbolos ausentes/incompativeis."
        End 1
    End If

    Dim rc As Integer = p_sqlite3_open(StrPtr(dbPath), @gDb)
    If rc <> SQLITE_OK Then
        Print "Falha ao abrir banco SQLite: "; dbPath
        End 1
    End If

    ExecSql("PRAGMA journal_mode=WAL;")
    ExecSql("CREATE TABLE IF NOT EXISTS settings(key TEXT PRIMARY KEY, value TEXT NOT NULL);")
    ExecSql("CREATE TABLE IF NOT EXISTS projects(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, created_at TEXT DEFAULT CURRENT_TIMESTAMP);")
    ExecSql("CREATE TABLE IF NOT EXISTS documents(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, file_path TEXT NOT NULL, cursor_x INTEGER NOT NULL DEFAULT 1, cursor_y INTEGER NOT NULL DEFAULT 1, updated_at TEXT DEFAULT CURRENT_TIMESTAMP);")
    ExecSql("CREATE TABLE IF NOT EXISTS perf_metrics_sec(id INTEGER PRIMARY KEY AUTOINCREMENT, bucket_time TEXT NOT NULL, backend_version TEXT NOT NULL, frame_count INTEGER NOT NULL, avg_char_calls REAL NOT NULL, avg_attr_calls REAL NOT NULL, avg_fill_calls REAL NOT NULL, p95_char_calls REAL NOT NULL, p95_attr_calls REAL NOT NULL, p95_fill_calls REAL NOT NULL, created_at TEXT DEFAULT CURRENT_TIMESTAMP);")

    DbSetSetting("source_base_url", "https://example.com/msx/")
    DbSetSetting("startup_document", "msx00.dmx")
    DbSetSetting("backend_version", "win32-buffer-v3")

    ExecSql("DELETE FROM settings WHERE key = 'tool.python';")
    ExecSql("DELETE FROM settings WHERE key = 'tool.badig_path';")
    ExecSql("DELETE FROM settings WHERE key = 'tool.digtestcli_path';")
    ExecSql("DELETE FROM settings WHERE key = 'tool.runbasiccli_path';")

    SeedConfigFromIni("badig", "basic-dignified\\support\\badig.ini")
    SeedConfigFromIni("msxbasic", "basic-dignified\\msx\\badig_msx.ini", "badig.")
    SeedConfigFromIni("msxbasic", "basic-dignified\\msx\\msxbatoken\\msxbatoken.ini", "tokenizer.")
    SeedConfigFromIni("emulator", "basic-dignified\\msx\\emulator_interface.ini")

    ' Migra/normaliza configuracao MSX Basic para enums semanticos.
    DbSetSetting("cfg.msxbasic.badig.convert_print", NormalizeMsxConvertPrint(DbGetSetting("cfg.msxbasic.badig.convert_print", "PRINT")))
    DbSetSetting("cfg.msxbasic.badig.strip_then_goto", NormalizeMsxThenGoto(DbGetSetting("cfg.msxbasic.badig.strip_then_goto", "THEN")))

    SeedHelpDoc("BASIC_DIGNIFIED", "basic-dignified\\documentation\\BASIC_DIGNIFIED.md")
    SeedHelpDoc("DIGNIFIED", "basic-dignified\\documentation\\DIGNIFIED.md")
    SeedHelpDoc("BATOKEN", "basic-dignified\\documentation\\BATOKEN.md")

    ' docs/help/*.md sao mantidos dentro deste proprio repositorio (ao contrario
    ' dos 3 acima, vendorizados do basic-dignified) - precisam do mesmo reseed
    ' incondicional a cada abertura do banco, senao DbGetHelpDoc() (cache
    ' permanente na 1a leitura, nunca reflete edicao seguinte no .md) trava a
    ' tela de Ajuda numa versao antiga pra sempre depois da 1a vez que abrir.
    SeedHelpDoc("EDITOR", "docs\\help\\editor.md")
    SeedHelpDoc("NESTORBASIC", "docs\\help\\nestorbasic.md")
    SeedHelpDoc("SEETRACKER", "docs\\help\\seetracker.md")
    SeedHelpDoc("MSXBAS2ROM", "docs\\help\\msxbas2rom.md")
    SeedHelpDoc("MAMUTE", "docs\\help\\mamute.md")
    SeedHelpDoc("MARKDOWN", "docs\\help\\markdown.md")
End Sub

Function DbGetHelpDoc(ByRef docName As String, ByRef fallbackPath As String = "") As String
    Dim keyName As String = "help." & LCase(docName)
    Dim txt As String = DbGetSetting(keyName, "")

    If Len(txt) > 0 Then Return txt

    If Len(fallbackPath) > 0 Then
        txt = ReadTextFile(fallbackPath)
        If Len(txt) > 0 Then
            DbSetSetting(keyName, txt)
            Return txt
        End If
    End If

    Return ""
End Function

Function DbGetConfigDocument(ByRef configGroup As String) As String
    Dim g As String = LCase(configGroup)
    Dim doc As String = ""

    Select Case g
        Case "badig"
            AppendConfigLine(doc, "[CONFIGS]")
            AppendConfigLine(doc, "use_ini_file = " & DbGetSetting(CfgKey(g, "use_ini_file"), "True"))
            AppendConfigLine(doc, "source_file = " & DbGetSetting(CfgKey(g, "source_file"), ""))
            AppendConfigLine(doc, "destin_file = " & DbGetSetting(CfgKey(g, "destin_file"), ""))
            AppendConfigLine(doc, "system_id = " & DbGetSetting(CfgKey(g, "system_id"), "msx"))
            AppendConfigLine(doc, "line_start = " & DbGetSetting(CfgKey(g, "line_start"), ""))
            AppendConfigLine(doc, "line_step = " & DbGetSetting(CfgKey(g, "line_step"), ""))
            AppendConfigLine(doc, "rem_header = " & DbGetSetting(CfgKey(g, "rem_header"), ""))
            AppendConfigLine(doc, "strip_spaces = " & DbGetSetting(CfgKey(g, "strip_spaces"), ""))
            AppendConfigLine(doc, "capitalize_all = " & DbGetSetting(CfgKey(g, "capitalize_all"), ""))
            AppendConfigLine(doc, "translate = " & DbGetSetting(CfgKey(g, "translate"), ""))
            AppendConfigLine(doc, "print_report = " & DbGetSetting(CfgKey(g, "print_report"), ""))
            AppendConfigLine(doc, "label_report = " & DbGetSetting(CfgKey(g, "label_report"), ""))
            AppendConfigLine(doc, "var_report = " & DbGetSetting(CfgKey(g, "var_report"), ""))
            AppendConfigLine(doc, "line_report = " & DbGetSetting(CfgKey(g, "line_report"), ""))
            AppendConfigLine(doc, "lexer_report = " & DbGetSetting(CfgKey(g, "lexer_report"), ""))
            AppendConfigLine(doc, "parser_report = " & DbGetSetting(CfgKey(g, "parser_report"), ""))
            AppendConfigLine(doc, "tab_lenght = " & DbGetSetting(CfgKey(g, "tab_lenght"), ""))
            AppendConfigLine(doc, "verbose_level = " & DbGetSetting(CfgKey(g, "verbose_level"), ""))

        Case "msxbasic"
            AppendConfigLine(doc, "[BADIG_MSX]")
            AppendConfigLine(doc, "convert_print = " & DbGetSetting(CfgKey(g, "badig.convert_print"), "PRINT"))
            AppendConfigLine(doc, "strip_then_goto = " & DbGetSetting(CfgKey(g, "badig.strip_then_goto"), "THEN"))
            AppendConfigLine(doc, "")
            AppendConfigLine(doc, "[MSXBATOKEN]")
            AppendConfigLine(doc, "file_load = " & DbGetSetting(CfgKey(g, "tokenizer.file_load"), ""))
            AppendConfigLine(doc, "file_save = " & DbGetSetting(CfgKey(g, "tokenizer.file_save"), ""))
            AppendConfigLine(doc, "list = " & DbGetSetting(CfgKey(g, "tokenizer.list"), "16"))
            AppendConfigLine(doc, "del_ascii = " & DbGetSetting(CfgKey(g, "tokenizer.del_ascii"), ""))
            AppendConfigLine(doc, "verbose = " & DbGetSetting(CfgKey(g, "tokenizer.verbose"), "3"))

        Case "emulator"
            AppendConfigLine(doc, "[CONFIGS]")
            AppendConfigLine(doc, "run = " & DbGetSetting(CfgKey(g, "run"), ""))
            AppendConfigLine(doc, "setting = " & DbGetSetting(CfgKey(g, "setting"), ""))
            AppendConfigLine(doc, "machine = " & DbGetSetting(CfgKey(g, "machine"), ""))
            AppendConfigLine(doc, "extension = " & DbGetSetting(CfgKey(g, "extension"), ""))
            AppendConfigLine(doc, "monitor = " & DbGetSetting(CfgKey(g, "monitor"), ""))
            AppendConfigLine(doc, "nothrottle = " & DbGetSetting(CfgKey(g, "nothrottle"), ""))
            AppendConfigLine(doc, "verbose = " & DbGetSetting(CfgKey(g, "verbose"), ""))
            AppendConfigLine(doc, "")
            AppendConfigLine(doc, "[WINDOWS]")
            AppendConfigLine(doc, "emulator_path = " & DbGetSetting(CfgKey(g, "windows.emulator_path"), ""))
            AppendConfigLine(doc, "")
            AppendConfigLine(doc, "[DARWIN]")
            AppendConfigLine(doc, "emulator_path = " & DbGetSetting(CfgKey(g, "darwin.emulator_path"), ""))
            AppendConfigLine(doc, "")
            AppendConfigLine(doc, "[LINUX]")
            AppendConfigLine(doc, "emulator_path = " & DbGetSetting(CfgKey(g, "linux.emulator_path"), ""))
    End Select

    Return doc
End Function

Sub DbSaveConfigDocument(ByRef configGroup As String, ByRef content As String)
    Dim g As String = LCase(configGroup)
    Dim text As String = StripCR(content)
    Dim sectionName As String = "configs"
    Dim startPos As Integer = 1

    While startPos <= Len(text)
        Dim br As Integer = InStr(startPos, text, Chr(10))
        Dim lineText As String
        If br = 0 Then
            lineText = Mid(text, startPos)
            startPos = Len(text) + 1
        Else
            lineText = Mid(text, startPos, br - startPos)
            startPos = br + 1
        End If

        Dim t As String = Trim(lineText)
        If Len(t) = 0 Then Continue While
        If Left(t, 1) = ";" Then Continue While
        If Left(t, 1) = "#" Then Continue While

        If Left(t, 1) = "[" And Right(t, 1) = "]" Then
            sectionName = LCase(Trim(Mid(t, 2, Len(t) - 2)))
            Continue While
        End If

        Dim eqPos As Integer = InStr(t, "=")
        If eqPos <= 0 Then Continue While

        Dim k As String = LCase(Trim(Left(t, eqPos - 1)))
        Dim v As String = Trim(Mid(t, eqPos + 1))
        If Len(k) = 0 Then Continue While

        Dim settingName As String
        Select Case g
            Case "badig"
                settingName = k

            Case "msxbasic"
                If sectionName = "msxbatoken" Then
                    settingName = "tokenizer." & k
                Else
                    settingName = "badig." & k
                End If

            Case "emulator"
                If sectionName = "configs" Then
                    settingName = k
                Else
                    settingName = sectionName & "." & k
                End If

            Case Else
                settingName = sectionName & "." & k
        End Select

        If g = "msxbasic" And settingName = "badig.convert_print" Then
            v = NormalizeMsxConvertPrint(v)
        ElseIf g = "msxbasic" And settingName = "badig.strip_then_goto" Then
            v = NormalizeMsxThenGoto(v)
        End If

        DbSetSetting(CfgKey(g, settingName), v)
    Wend
End Sub

Sub DbShutdown()
    DbProjectClose()

    If gDb <> 0 Then
        p_sqlite3_close(gDb)
        gDb = 0
    End If

    If gSqliteDll <> 0 Then
        DyLibFree(gSqliteDll)
        gSqliteDll = 0
    End If
End Sub

' ---------------------------------------------------------------------------
' Projeto (.msxproj): segunda conexao SQLite, tratada como um "zip" - abrir
' extrai project_files pro disco, salvar reimporta o que estiver no disco.
' cfg.* enquanto um projeto estiver aberto vai pra project_config em vez da
' tabela settings global (ver DbGetSetting/DbSetSetting mais abaixo).
' ---------------------------------------------------------------------------

Private Sub CreateProjectSchema(ByVal db As sqlite3 Ptr)
    ExecSqlOn(db, "PRAGMA journal_mode=WAL;")
    ExecSqlOn(db, "CREATE TABLE IF NOT EXISTS project_meta(key TEXT PRIMARY KEY, value TEXT NOT NULL);")
    ExecSqlOn(db, "CREATE TABLE IF NOT EXISTS project_config(key TEXT PRIMARY KEY, value TEXT NOT NULL);")
    ExecSqlOn(db, "CREATE TABLE IF NOT EXISTS project_files(rel_path TEXT PRIMARY KEY, content BLOB NOT NULL, updated_at TEXT DEFAULT CURRENT_TIMESTAMP);")
End Sub

Sub DbProjectClose()
    If gProjectDb <> 0 Then
        p_sqlite3_close(gProjectDb)
        gProjectDb = 0
    End If
End Sub

Function DbProjectOpen(ByRef dbPath As String) As Integer
    DbProjectClose()
    Dim rc As Integer = p_sqlite3_open(StrPtr(dbPath), @gProjectDb)
    If rc <> SQLITE_OK Then
        gProjectDb = 0
        Return 0
    End If
    CreateProjectSchema(gProjectDb)
    Return -1
End Function

Function DbProjectIsActive() As Integer
    Return IIf(gProjectDb <> 0, -1, 0)
End Function

Sub DbProjectSetMeta(ByRef keyName As String, ByRef keyValue As String)
    If gProjectDb = 0 Then Exit Sub
    Dim sql As String = "INSERT INTO project_meta(key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value;"
    Dim stmt As sqlite3_stmt Ptr
    If p_sqlite3_prepare_v2(gProjectDb, StrPtr(sql), -1, @stmt, 0) <> SQLITE_OK Then Exit Sub
    p_sqlite3_bind_text(stmt, 1, StrPtr(keyName), -1, Cast(Any Ptr, -1))
    p_sqlite3_bind_text(stmt, 2, StrPtr(keyValue), -1, Cast(Any Ptr, -1))
    p_sqlite3_step(stmt)
    p_sqlite3_finalize(stmt)
End Sub

Function DbProjectGetMeta(ByRef keyName As String, ByRef fallback As String = "") As String
    If gProjectDb = 0 Then Return fallback
    Dim sql As String = "SELECT value FROM project_meta WHERE key = ? LIMIT 1;"
    Dim stmt As sqlite3_stmt Ptr
    Dim result As String = fallback
    If p_sqlite3_prepare_v2(gProjectDb, StrPtr(sql), -1, @stmt, 0) <> SQLITE_OK Then Return result
    p_sqlite3_bind_text(stmt, 1, StrPtr(keyName), -1, Cast(Any Ptr, -1))
    If p_sqlite3_step(stmt) = SQLITE_ROW Then
        Dim txt As ZString Ptr = p_sqlite3_column_text(stmt, 0)
        If txt <> 0 Then result = *txt
    End If
    p_sqlite3_finalize(stmt)
    Return result
End Function

Sub DbProjectSetConfig(ByRef keyName As String, ByRef keyValue As String)
    If gProjectDb = 0 Then Exit Sub
    Dim sql As String = "INSERT INTO project_config(key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value;"
    Dim stmt As sqlite3_stmt Ptr
    If p_sqlite3_prepare_v2(gProjectDb, StrPtr(sql), -1, @stmt, 0) <> SQLITE_OK Then Exit Sub
    p_sqlite3_bind_text(stmt, 1, StrPtr(keyName), -1, Cast(Any Ptr, -1))
    p_sqlite3_bind_text(stmt, 2, StrPtr(keyValue), -1, Cast(Any Ptr, -1))
    p_sqlite3_step(stmt)
    p_sqlite3_finalize(stmt)
End Sub

Function DbProjectConfigExists(ByRef keyName As String) As Integer
    If gProjectDb = 0 Then Return 0
    Dim sql As String = "SELECT value FROM project_config WHERE key = ? LIMIT 1;"
    Dim stmt As sqlite3_stmt Ptr
    If p_sqlite3_prepare_v2(gProjectDb, StrPtr(sql), -1, @stmt, 0) <> SQLITE_OK Then Return 0
    p_sqlite3_bind_text(stmt, 1, StrPtr(keyName), -1, Cast(Any Ptr, -1))
    Dim found As Integer = IIf(p_sqlite3_step(stmt) = SQLITE_ROW, -1, 0)
    p_sqlite3_finalize(stmt)
    Return found
End Function

Function DbProjectGetConfig(ByRef keyName As String, ByRef fallback As String = "") As String
    If gProjectDb = 0 Then Return fallback
    Dim sql As String = "SELECT value FROM project_config WHERE key = ? LIMIT 1;"
    Dim stmt As sqlite3_stmt Ptr
    Dim result As String = fallback
    If p_sqlite3_prepare_v2(gProjectDb, StrPtr(sql), -1, @stmt, 0) <> SQLITE_OK Then Return result
    p_sqlite3_bind_text(stmt, 1, StrPtr(keyName), -1, Cast(Any Ptr, -1))
    If p_sqlite3_step(stmt) = SQLITE_ROW Then
        Dim txt As ZString Ptr = p_sqlite3_column_text(stmt, 0)
        If txt <> 0 Then result = *txt
    End If
    p_sqlite3_finalize(stmt)
    Return result
End Function

Sub DbProjectSetFile(ByRef relPath As String, ByRef content As String)
    If gProjectDb = 0 Then Exit Sub
    Dim sql As String = "INSERT INTO project_files(rel_path, content, updated_at) VALUES (?, ?, CURRENT_TIMESTAMP) ON CONFLICT(rel_path) DO UPDATE SET content=excluded.content, updated_at=CURRENT_TIMESTAMP;"
    Dim stmt As sqlite3_stmt Ptr
    If p_sqlite3_prepare_v2(gProjectDb, StrPtr(sql), -1, @stmt, 0) <> SQLITE_OK Then Exit Sub
    p_sqlite3_bind_text(stmt, 1, StrPtr(relPath), -1, Cast(Any Ptr, -1))
    If Len(content) > 0 Then
        p_sqlite3_bind_blob(stmt, 2, StrPtr(content), Len(content), Cast(Any Ptr, -1))
    Else
        p_sqlite3_bind_blob(stmt, 2, 0, 0, Cast(Any Ptr, -1))
    End If
    p_sqlite3_step(stmt)
    p_sqlite3_finalize(stmt)
End Sub

Function DbProjectGetFile(ByRef relPath As String, ByRef found As Integer) As String
    found = 0
    If gProjectDb = 0 Then Return ""
    Dim sql As String = "SELECT content FROM project_files WHERE rel_path = ? LIMIT 1;"
    Dim stmt As sqlite3_stmt Ptr
    Dim result As String = ""
    If p_sqlite3_prepare_v2(gProjectDb, StrPtr(sql), -1, @stmt, 0) <> SQLITE_OK Then Return result
    p_sqlite3_bind_text(stmt, 1, StrPtr(relPath), -1, Cast(Any Ptr, -1))
    If p_sqlite3_step(stmt) = SQLITE_ROW Then
        found = -1
        Dim blobPtr As Any Ptr = p_sqlite3_column_blob(stmt, 0)
        Dim blobLen As Integer = p_sqlite3_column_bytes(stmt, 0)
        If blobPtr <> 0 And blobLen > 0 Then
            result = Space(blobLen)
            CMemCpy(StrPtr(result), blobPtr, blobLen)
        End If
    End If
    p_sqlite3_finalize(stmt)
    Return result
End Function

Sub DbProjectListFiles(paths() As String, ByRef count As Integer)
    count = 0
    If gProjectDb = 0 Then Exit Sub
    Dim sql As String = "SELECT rel_path FROM project_files ORDER BY rel_path;"
    Dim stmt As sqlite3_stmt Ptr
    If p_sqlite3_prepare_v2(gProjectDb, StrPtr(sql), -1, @stmt, 0) <> SQLITE_OK Then Exit Sub
    While p_sqlite3_step(stmt) = SQLITE_ROW
        Dim txt As ZString Ptr = p_sqlite3_column_text(stmt, 0)
        If txt <> 0 Then
            count += 1
            If count = 1 Then
                ReDim paths(1 To 1)
            Else
                ReDim Preserve paths(1 To count)
            End If
            paths(count) = *txt
        End If
    Wend
    p_sqlite3_finalize(stmt)
End Sub

' Copia project_config e project_files de um outro .msxproj (o template) pro
' projeto atualmente aberto - usado so na criacao de um projeto novo.
Function DbProjectCopyFromTemplate(ByRef templatePath As String) As Integer
    If gProjectDb = 0 Then Return 0
    If Dir(templatePath) = "" Then Return 0

    Dim tmplDb As sqlite3 Ptr
    If p_sqlite3_open(StrPtr(templatePath), @tmplDb) <> SQLITE_OK Then Return 0
    CreateProjectSchema(tmplDb)

    Dim stmt As sqlite3_stmt Ptr
    Dim sql As String = "SELECT key, value FROM project_config;"
    If p_sqlite3_prepare_v2(tmplDb, StrPtr(sql), -1, @stmt, 0) = SQLITE_OK Then
        While p_sqlite3_step(stmt) = SQLITE_ROW
            Dim kTxt As ZString Ptr = p_sqlite3_column_text(stmt, 0)
            Dim vTxt As ZString Ptr = p_sqlite3_column_text(stmt, 1)
            If kTxt <> 0 And vTxt <> 0 Then DbProjectSetConfig(*kTxt, *vTxt)
        Wend
        p_sqlite3_finalize(stmt)
    End If

    sql = "SELECT rel_path, content FROM project_files;"
    If p_sqlite3_prepare_v2(tmplDb, StrPtr(sql), -1, @stmt, 0) = SQLITE_OK Then
        While p_sqlite3_step(stmt) = SQLITE_ROW
            Dim pTxt As ZString Ptr = p_sqlite3_column_text(stmt, 0)
            Dim blobPtr As Any Ptr = p_sqlite3_column_blob(stmt, 1)
            Dim blobLen As Integer = p_sqlite3_column_bytes(stmt, 1)
            If pTxt <> 0 Then
                Dim content As String = ""
                If blobPtr <> 0 And blobLen > 0 Then
                    content = Space(blobLen)
                    CMemCpy(StrPtr(content), blobPtr, blobLen)
                End If
                DbProjectSetFile(*pTxt, content)
            End If
        Wend
        p_sqlite3_finalize(stmt)
    End If

    p_sqlite3_close(tmplDb)
    Return -1
End Function

Sub DbSetSetting(ByRef keyName As String, ByRef keyValue As String)
    If gProjectDb <> 0 And Left(keyName, 4) = "cfg." Then
        DbProjectSetConfig(keyName, keyValue)
        Exit Sub
    End If

    Dim sql As String = "INSERT INTO settings(key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value;"
    Dim stmt As sqlite3_stmt Ptr

    If p_sqlite3_prepare_v2(gDb, StrPtr(sql), -1, @stmt, 0) <> SQLITE_OK Then Exit Sub

    p_sqlite3_bind_text(stmt, 1, StrPtr(keyName), -1, Cast(Any Ptr, -1))
    p_sqlite3_bind_text(stmt, 2, StrPtr(keyValue), -1, Cast(Any Ptr, -1))
    p_sqlite3_step(stmt)
    p_sqlite3_finalize(stmt)
End Sub

Function DbGetSetting(ByRef keyName As String, ByRef fallback As String = "") As String
    If gProjectDb <> 0 And Left(keyName, 4) = "cfg." Then
        If DbProjectConfigExists(keyName) <> 0 Then Return DbProjectGetConfig(keyName, fallback)
    End If

    Dim sql As String = "SELECT value FROM settings WHERE key = ? LIMIT 1;"
    Dim stmt As sqlite3_stmt Ptr
    Dim result As String = fallback

    If p_sqlite3_prepare_v2(gDb, StrPtr(sql), -1, @stmt, 0) <> SQLITE_OK Then Return result

    p_sqlite3_bind_text(stmt, 1, StrPtr(keyName), -1, Cast(Any Ptr, -1))

    If p_sqlite3_step(stmt) = SQLITE_ROW Then
        Dim txt As ZString Ptr = p_sqlite3_column_text(stmt, 0)
        If txt <> 0 Then result = *txt
    End If

    p_sqlite3_finalize(stmt)
    Return result
End Function

Sub DbSaveDocumentState(ByRef title As String, ByRef filePath As String, ByVal cursorX As Integer, ByVal cursorY As Integer)
    Dim sql As String = "INSERT INTO documents(title, file_path, cursor_x, cursor_y) VALUES (?, ?, ?, ?);"
    Dim stmt As sqlite3_stmt Ptr

    If p_sqlite3_prepare_v2(gDb, StrPtr(sql), -1, @stmt, 0) <> SQLITE_OK Then Exit Sub

    p_sqlite3_bind_text(stmt, 1, StrPtr(title), -1, Cast(Any Ptr, -1))
    p_sqlite3_bind_text(stmt, 2, StrPtr(filePath), -1, Cast(Any Ptr, -1))
    p_sqlite3_bind_int(stmt, 3, cursorX)
    p_sqlite3_bind_int(stmt, 4, cursorY)

    p_sqlite3_step(stmt)
    p_sqlite3_finalize(stmt)
End Sub

Sub DbSavePerfSecond(ByRef backendVersion As String, ByRef bucketTime As String, ByVal frameCount As Integer, ByVal avgChar As Double, ByVal avgAttr As Double, ByVal avgFill As Double, ByVal p95Char As Double, ByVal p95Attr As Double, ByVal p95Fill As Double)
    Dim sql As String = "INSERT INTO perf_metrics_sec(bucket_time, backend_version, frame_count, avg_char_calls, avg_attr_calls, avg_fill_calls, p95_char_calls, p95_attr_calls, p95_fill_calls) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);"
    Dim stmt As sqlite3_stmt Ptr

    If p_sqlite3_prepare_v2(gDb, StrPtr(sql), -1, @stmt, 0) <> SQLITE_OK Then Exit Sub

    p_sqlite3_bind_text(stmt, 1, StrPtr(bucketTime), -1, Cast(Any Ptr, -1))
    p_sqlite3_bind_text(stmt, 2, StrPtr(backendVersion), -1, Cast(Any Ptr, -1))
    p_sqlite3_bind_int(stmt, 3, frameCount)
    p_sqlite3_bind_double(stmt, 4, avgChar)
    p_sqlite3_bind_double(stmt, 5, avgAttr)
    p_sqlite3_bind_double(stmt, 6, avgFill)
    p_sqlite3_bind_double(stmt, 7, p95Char)
    p_sqlite3_bind_double(stmt, 8, p95Attr)
    p_sqlite3_bind_double(stmt, 9, p95Fill)

    p_sqlite3_step(stmt)
    p_sqlite3_finalize(stmt)
End Sub
