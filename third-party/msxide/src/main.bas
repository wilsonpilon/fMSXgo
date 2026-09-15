#Include Once "editor.bi"
#Include Once "db.bi"
#Include Once "console.bi"
#Include Once "compiler.bi"

Dim running As Integer = 1
Dim menuOpen As Integer = 0
Dim keyText As String
Dim startupName As String = "msx00.dmx"
Dim argText As String
Dim argIndex As Integer
Dim hasArgs As Integer = 0
Dim runHelpSmoke As Integer = 0
Dim runMamuteSmoke As Integer = 0
Dim runMamuteDiag As Integer = 0
Dim runEditSmoke As Integer = 0
Dim runKeysSmoke As Integer = 0
Dim runBadigSmoke As Integer = 0
Dim needsRedraw As Integer = 1
Dim inputType As Integer
Dim mouseX As Integer
Dim mouseY As Integer
Dim mouseAction As Integer

argIndex = 1
argText = Command(argIndex)
If Len(argText) > 0 Then
    hasArgs = 1
    If LCase(argText) = "--smoke-help" Then
        runHelpSmoke = -1
    ElseIf LCase(argText) = "--smoke-mamute" Then
        runMamuteSmoke = -1
    ElseIf LCase(argText) = "--mamute-diag" Then
        runMamuteDiag = -1
    ElseIf LCase(argText) = "--smoke-editor" Then
        runEditSmoke = -1
    ElseIf LCase(argText) = "--smoke-keys" Then
        runKeysSmoke = -1
    ElseIf LCase(argText) = "--smoke-badig" Then
        runBadigSmoke = -1
    End If
End If

' Testa a traducao de KEY_EVENT_RECORD (Ctrl/Alt/Shift+tecla) direto, sem
' precisar de banco/editor/documento nenhum - roda e sai antes de qualquer
' outra coisa neste arquivo.
If runKeysSmoke <> 0 Then
    Dim keysSmokeReport As String
    Dim keysSmokeOk As Integer = ConsoleRunKeyTranslationSmokeTest(keysSmokeReport)
    Print keysSmokeReport
    If keysSmokeOk <> 0 Then
        End 0
    Else
        End 1
    End If
End If

' Smoke test do preprocessador Basic Dignified (juncao de linha por :) -
' so' precisa de banco pra IntSetting/DbGetSetting terem algo pra ler
' (usa um banco descartavel proprio, igual o do Mamute, pra nunca tocar
' no msxide.db de verdade) - nao precisa de editor/documento nenhum.
Dim badigSmokeDbPath As String = "msxide_badig_smoke.db"
If runBadigSmoke <> 0 Then
    DbInit(badigSmokeDbPath)
    Dim badigSmokeReport As String
    Dim badigSmokeOk As Integer = CompilerRunJoinSmokeTest(badigSmokeReport)
    Print badigSmokeReport
    If badigSmokeOk <> 0 Then
        badigSmokeOk = CompilerRunFormatSmokeTest(badigSmokeReport)
        Print badigSmokeReport
    End If
    If badigSmokeOk <> 0 Then
        badigSmokeOk = CompilerRunVariableSmokeTest(badigSmokeReport)
        Print badigSmokeReport
    End If
    If badigSmokeOk <> 0 Then
        badigSmokeOk = CompilerRunFuncSmokeTest(badigSmokeReport)
        Print badigSmokeReport
    End If
    If badigSmokeOk <> 0 Then
        badigSmokeOk = CompilerRunNBasicSmokeTest(badigSmokeReport)
        Print badigSmokeReport
    End If
    DbShutdown()
    If Dir(badigSmokeDbPath) <> "" Then Kill badigSmokeDbPath
    If badigSmokeOk <> 0 Then
        End 0
    Else
        End 1
    End If
End If

' O smoke test do Mamute grava/rele configuracao real via DbSetSetting/
' DbGetSetting - usa um banco descartavel proprio pra nunca tocar no
' msxide.db de verdade do usuario.
Dim mamuteSmokeDbPath As String = "msxide_mamute_smoke.db"
If runMamuteSmoke <> 0 Then
    DbInit(mamuteSmokeDbPath)
Else
    DbInit("msxide.db")
End If
startupName = DbGetSetting("startup_document", "msx00.dmx")

If hasArgs = 0 Then
    EditorInit(startupName)
Else
    EditorInit("msx00.dmx")
End If

If hasArgs <> 0 Then
    If runHelpSmoke = 0 And runMamuteSmoke = 0 And runMamuteDiag = 0 And runEditSmoke = 0 And runKeysSmoke = 0 Then
        EditorOpenFromPath(argText)
        argIndex += 1
        While Len(Command(argIndex)) > 0
            EditorOpenFromPath(Command(argIndex))
            argIndex += 1
        Wend
    End If
End If

If runHelpSmoke <> 0 Then
    Dim smokeReport As String
    Dim smokeOk As Integer = EditorRunHelpSmokeTest(smokeReport)
    Print smokeReport
    EditorSaveAllToDb()
    DbShutdown()
    EditorShutdown()
    If smokeOk <> 0 Then
        End 0
    Else
        End 1
    End If
End If

If runMamuteSmoke <> 0 Then
    Dim mamuteSmokeReport As String
    Dim mamuteSmokeOk As Integer = EditorRunMamuteSmokeTest(mamuteSmokeReport)
    Print mamuteSmokeReport
    EditorSaveAllToDb()
    DbShutdown()
    EditorShutdown()
    If Dir(mamuteSmokeDbPath) <> "" Then Kill mamuteSmokeDbPath
    If mamuteSmokeOk <> 0 Then
        End 0
    Else
        End 1
    End If
End If

If runMamuteDiag <> 0 Then
    Dim diagReport As String
    EditorRunMamuteDiag(diagReport)
    Print diagReport
    EditorSaveAllToDb()
    DbShutdown()
    EditorShutdown()
    End 0
End If

If runEditSmoke <> 0 Then
    Dim editSmokeReport As String
    Dim editSmokeOk As Integer = EditorRunTextEditSmokeTest(editSmokeReport)
    Print editSmokeReport
    EditorSaveAllToDb()
    DbShutdown()
    EditorShutdown()
    If editSmokeOk <> 0 Then
        End 0
    Else
        End 1
    End If
End If

Do While running <> 0
    If needsRedraw <> 0 Then
        EditorDraw(menuOpen)
        needsRedraw = 0
    End If

    If ConsolePollInput(inputType, keyText, mouseX, mouseY, mouseAction) <> 0 Then
        If inputType = MSX_INPUT_KEY Then
            EditorHandleKey(keyText, running, menuOpen)
        ElseIf inputType = MSX_INPUT_MOUSE Then
            EditorHandleMouse(mouseX, mouseY, mouseAction, running, menuOpen)
        End If
        needsRedraw = 1
    Else
        ' "Monitora" o arquivo do documento ativo (pedido do usuario,
        ' 2026-09-12) - EditorCheckExternalChanges tem seu proprio throttle
        ' interno (no maximo 1x a cada 2s), entao chamar isto toda volta
        ' ociosa do loop e' barato (a maioria das chamadas nao faz nada).
        If EditorCheckExternalChanges() <> 0 Then needsRedraw = 1
        Sleep 5, 1
    End If
Loop

EditorSaveAllToDb()
DbShutdown()
EditorShutdown()
