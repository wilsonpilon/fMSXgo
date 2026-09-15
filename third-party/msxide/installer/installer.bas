' installer.bas - instalador nativo do msxIDE, sem dependencias externas.
' Espera encontrar uma pasta "distribute" ao lado deste .exe (mesmo diretorio),
' copia o conteudo pra pasta escolhida pelo usuario, cria atalho no Menu
' Iniciar e registra uma entrada de desinstalacao em "Aplicativos e recursos".
#Include Once "dir.bi"

Const MSXIDE_INSTALLER_VERSION = "0.5.0"
Const MSXIDE_INSTALLER_CODENAME = "MAMUTE.MAP"

Declare Sub Pause()

Dim exeDir As String = Exepath()
Dim sourceDir As String = exeDir & Chr(92) & "distribute"
Dim defaultInstallDir As String = Environ("LOCALAPPDATA") & Chr(92) & "msxIDE"
Dim installDirInput As String
Dim installDir As String
Dim dummy As String

' Modo silencioso: "installer.exe C:\caminho" instala direto, sem perguntar
' (tambem evita qualquer Pause() esperando teclado - util pra automacao/testes).
Dim cliArg As String = Trim(Command(1))

Print "=================================================="
Print "  msxIDE " & MSXIDE_INSTALLER_VERSION & " """ & MSXIDE_INSTALLER_CODENAME & """ - Instalador"
Print "=================================================="
Print

If Dir(sourceDir, fbDirectory) = "" Then
    Print "ERRO: pasta 'distribute' nao encontrada ao lado deste instalador."
    Print "(esperado em: " & sourceDir & ")"
    Print
    If Len(cliArg) = 0 Then Pause()
    End 1
End If

If Len(cliArg) > 0 Then
    installDirInput = cliArg
    Print "Pasta de instalacao (via linha de comando): " & cliArg
Else
    Print "Pasta de instalacao [" & defaultInstallDir & "]:"
    Line Input "> ", installDirInput
End If
If Len(Trim(installDirInput)) = 0 Then
    installDir = defaultInstallDir
Else
    installDir = Trim(installDirInput)
End If
If Right(installDir, 1) = Chr(92) Then installDir = Left(installDir, Len(installDir) - 1)

Print
Print "Instalando em: " & installDir
Print "Copiando arquivos..."

Shell("cmd /c if not exist " & Chr(34) & installDir & Chr(34) & " mkdir " & Chr(34) & installDir & Chr(34))
Shell("xcopy " & Chr(34) & sourceDir & Chr(34) & " " & Chr(34) & installDir & Chr(34) & " /E /I /Y /Q")

If Dir(installDir & Chr(92) & "msxide.exe") = "" Then
    Print "ERRO: falha ao copiar os arquivos pra " & installDir
    Print
    If Len(cliArg) = 0 Then Pause()
    End 1
End If
Print "Arquivos copiados."

' Atalho no Menu Iniciar (via COM do PowerShell - nao ha API nativa de .lnk no FreeBASIC).
Dim startMenuDir As String = Environ("APPDATA") & Chr(92) & "Microsoft\Windows\Start Menu\Programs"
Dim shortcutPath As String = startMenuDir & Chr(92) & "msxIDE.lnk"
Dim psScript As String = "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('" & shortcutPath & "');" _
    & "$s.TargetPath='" & installDir & Chr(92) & "msxide.exe';" _
    & "$s.WorkingDirectory='" & installDir & "';" _
    & "$s.IconLocation='" & installDir & Chr(92) & "msxide.exe';" _
    & "$s.Save()"
Shell("powershell -NoProfile -Command " & Chr(34) & psScript & Chr(34))
Print "Atalho criado no Menu Iniciar."

' Script de desinstalacao. Roda a partir de dentro da propria pasta que vai
' apagar - troca o diretorio de trabalho pra %TEMP% antes do rmdir /s /q, o
' que e suficiente no Windows (NTFS nao mantem lock exclusivo num .bat texto
' sendo so lido sequencialmente por cmd.exe). Deliberadamente SEM o truque
' classico de "copiar pra %TEMP% e re-executar" - esse padrao de auto-copia
' e auto-delecao e comumente sinalizado por antivirus (confirmado nesta
' sessao: o Windows Defender colocou em quarentena um desinstalador gerado
' com esse truque, impedindo ate a leitura do arquivo).
Dim uninstallBatPath As String = installDir & Chr(92) & "desinstalar.bat"
Dim ff As Integer = FreeFile
Open uninstallBatPath For Output As #ff
Print #ff, "@echo off"
Print #ff, "reg delete " & Chr(34) & "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\msxIDE" & Chr(34) & " /f >nul 2>&1"
Print #ff, "del " & Chr(34) & shortcutPath & Chr(34) & " >nul 2>&1"
Print #ff, "cd /d " & Chr(34) & "%TEMP%" & Chr(34)
Print #ff, "rmdir /s /q " & Chr(34) & installDir & Chr(34)
Close #ff
Print "Script de desinstalacao criado."

' Entrada em "Aplicativos e recursos" - gerada como um .bat com varios
' "reg add", em vez de importar um .reg via "regedit /s": testado nesta
' sessao e o .reg ficou nao-confiavel (a chave era criada mas os valores as
' vezes ficavam vazios, sem erro nenhum). "reg add" linha a linha e sincrono
' e direto, mesmo padrao ja usado e confirmado pro desinstalar.bat.
Dim regKeyPath As String = "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\msxIDE"
Dim regBatPath As String = Environ("TEMP") & Chr(92) & "msxide_registrar.bat"
Dim rf As Integer = FreeFile
Open regBatPath For Output As #rf
Print #rf, "@echo off"
Print #rf, "reg add " & Chr(34) & regKeyPath & Chr(34) & " /v DisplayName /t REG_SZ /d " & Chr(34) & "msxIDE" & Chr(34) & " /f >nul 2>&1"
Print #rf, "reg add " & Chr(34) & regKeyPath & Chr(34) & " /v DisplayVersion /t REG_SZ /d " & Chr(34) & MSXIDE_INSTALLER_VERSION & Chr(34) & " /f >nul 2>&1"
Print #rf, "reg add " & Chr(34) & regKeyPath & Chr(34) & " /v Publisher /t REG_SZ /d " & Chr(34) & "msxIDE project" & Chr(34) & " /f >nul 2>&1"
Print #rf, "reg add " & Chr(34) & regKeyPath & Chr(34) & " /v InstallLocation /t REG_SZ /d " & Chr(34) & installDir & Chr(34) & " /f >nul 2>&1"
Print #rf, "reg add " & Chr(34) & regKeyPath & Chr(34) & " /v DisplayIcon /t REG_SZ /d " & Chr(34) & installDir & Chr(92) & "msxide.exe" & Chr(34) & " /f >nul 2>&1"
Print #rf, "reg add " & Chr(34) & regKeyPath & Chr(34) & " /v UninstallString /t REG_SZ /d " & Chr(34) & "cmd /c " & Chr(92) & Chr(34) & uninstallBatPath & Chr(92) & Chr(34) & Chr(34) & " /f >nul 2>&1"
Print #rf, "reg add " & Chr(34) & regKeyPath & Chr(34) & " /v NoModify /t REG_DWORD /d 1 /f >nul 2>&1"
Print #rf, "reg add " & Chr(34) & regKeyPath & Chr(34) & " /v NoRepair /t REG_DWORD /d 1 /f >nul 2>&1"
Close #rf

Shell("cmd /c " & Chr(34) & regBatPath & Chr(34))
' Best-effort: alguns antivirus/EDR bloqueiam escrita nesse ramo do registro
' vinda de um executavel recem-compilado/nao assinado (confirmado nesta
' sessao). Nao trava a instalacao por isso - so informa o resultado real.
Dim regOkFile As String = Environ("TEMP") & Chr(92) & "msxide_regcheck.txt"
Shell("cmd /c reg query " & Chr(34) & regKeyPath & Chr(34) & " /v DisplayName >" & Chr(34) & regOkFile & Chr(34) & " 2>&1")
Dim regOk As Integer = 0
If Dir(regOkFile) <> "" Then
    Dim checkFf As Integer = FreeFile
    Dim checkLine As String
    Dim sawContent As Integer = 0
    Dim sawError As Integer = 0
    Open regOkFile For Input As #checkFf
    While Not Eof(checkFf)
        Line Input #checkFf, checkLine
        If Len(Trim(checkLine)) > 0 Then sawContent = -1
        If InStr(UCase(checkLine), "ERROR") > 0 Then sawError = -1
    Wend
    Close #checkFf
    Kill regOkFile
    If sawContent <> 0 And sawError = 0 Then regOk = -1
End If
If regOk <> 0 Then
    Print "Registrado em Aplicativos e recursos do Windows."
Else
    Print "Aviso: nao foi possivel registrar em Aplicativos e recursos (bloqueado"
    Print "pelo antivirus/EDR desta maquina - o programa continua funcionando"
    Print "normalmente, so nao vai aparecer na lista de desinstalacao do Windows;"
    Print "use " & Chr(34) & installDir & Chr(92) & "desinstalar.bat" & Chr(34) & " pra remover)."
End If

Print
Print "=================================================="
Print "  Instalacao concluida!"
Print "=================================================="
Print "  Local:  " & installDir
Print "  Atalho: Menu Iniciar > msxIDE"
Print "=================================================="
Print
If Len(cliArg) = 0 Then Pause()

Sub Pause()
    Dim k As String
    Print "Pressione Enter para sair..."
    Line Input k
End Sub
