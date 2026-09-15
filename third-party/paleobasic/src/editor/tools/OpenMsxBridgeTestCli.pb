;
; ------------------------------------------------------------
;  Ferramenta de linha de comando para testar OpenMSXBridge.pbi (menu
;  "Executar -> openMSX...") contra um openMSX de verdade, sem abrir a GUI
;  do editor. Sobe o processo com "-control pipe:<nome>", espera a conexao,
;  manda alguns comandos e grava tudo que volta pelo stdout/stderr num
;  arquivo de log.
;
;  Por que log em ARQUIVO, nao PrintN num console: chama FreeConsole_() logo
;  no inicio, de proposito, pra reproduzir o estado real do editor GUI no
;  momento em que OMSX_Start() e chamado (BadigEditor.pb chama
;  FreeConsole_() antes de abrir qualquer janela - ver CLAUDE.md/build.ps1
;  "/CONSOLE"). Isso importa de verdade: `openmsx/openmsx/src/main.cc`,
;  EnableConsoleOutput(), faz
;    if (AttachConsole(ATTACH_PARENT_PROCESS)) {
;        freopen("CONOUT$", "w", stdout); freopen("CONOUT$", "w", stderr);
;    }
;  ou seja, SE o processo que chama RunProgram() tiver um console de verdade
;  anexado (ex.: rodar esta mesma ferramenta direto de um terminal, sem
;  chamar FreeConsole_() antes), o openMSX filho reabre seu proprio
;  stdout/stderr apontando pro CONSOLE herdado (CONOUT$), **descartando** o
;  pipe anonimo que RunProgram(...#PB_Program_Read|Error) preparou pra
;  capturar a saida - ReadProgramString()/ReadProgramError() ficam vendo
;  sempre "" (confirmado ao vivo nesta maquina, 2026-07-30: 0 bytes
;  capturados, mesmo do "<openmsx-output>" que a doc do protocolo diz que
;  deveria vir logo no handshake). Sem console nenhum anexado ao processo
;  chamador (AttachConsole falha), o openMSX mantem os handles herdados via
;  STARTUPINFO/STARTF_USESTDHANDLES e a captura funciona normalmente - e
;  esse e exatamente o estado real do BadigEditor.exe (GUI) quando chama
;  OMSX_Start()/RunOnOpenMSX(). Validado ao vivo nesta maquina (2026-07-30)
;  contra um openMSX 21.0 de verdade (C:\msx\openMSX\openmsx.exe): pipe
;  conectou em ~300ms, replies reais de "set power off"/"set power on"
;  ("false"/"true") e "openmsx_info platform" ("mingw32") vieram
;  corretamente pelo OMSX_Poll().
;
;  Uso:
;    OpenMsxBridgeTestCli.exe <arquivo_log> <caminho openmsx.exe> [maquina] [extensao]
; ------------------------------------------------------------
;

EnableExplicit

; Stub minimo de BadigCfg - so os 3 campos que OpenMSXBridge.pbi realmente le,
; pra nao precisar puxar BadigSettings.pbi (JSON/GUI) so pra este teste.
Structure BadigSettingsStub
  EmulatorPath.s
  EmMachine.s
  EmExtension.s
EndStructure
Global BadigCfg.BadigSettingsStub

XIncludeFile "..\emulators\OpenMSXBridge.pbi"

Define LogPath.s  = ProgramParameter(0)
Define ExePath.s  = ProgramParameter(1)
Define Machine.s  = ProgramParameter(2)
Define Extension.s = ProgramParameter(3)

; Ver comentario no topo do arquivo - crucial pra reproduzir o estado real
; do editor GUI (que ja chamou isto antes de abrir qualquer janela).
FreeConsole_()

If LogPath = "" Or ExePath = ""
  End 1
EndIf

Define LogFile = CreateFile(#PB_Any, LogPath)
If Not LogFile
  End 1
EndIf

Procedure LogMsg(LogFile, Text.s)
  WriteStringN(LogFile, Text)
EndProcedure

BadigCfg\EmulatorPath = ExePath
BadigCfg\EmMachine = Machine
BadigCfg\EmExtension = Extension

LogMsg(LogFile, "--- OMSX_Start() ---")
If Not OMSX_Start()
  LogMsg(LogFile, "FALHA: OMSX_Start() retornou #False")
  CloseFile(LogFile)
  End 1
EndIf

; Espera ate 10s pela conexao do pipe (OMSX_PipeConnectThread roda em paralelo)
Define WaitMs = 0
While Not OMSX_PipeConnected And WaitMs < 10000 And OMSX_IsRunning()
  Delay(100)
  WaitMs + 100
Wend

If Not OMSX_PipeConnected
  LogMsg(LogFile, "FALHA: pipe nao conectou em 10s (OMSX_IsRunning=" + Str(OMSX_IsRunning()) + ")")
  CloseFile(LogFile)
  End 1
EndIf
LogMsg(LogFile, "Pipe conectado em ~" + Str(WaitMs) + "ms.")

; Drena a saida por 2s (deve conter os replies do boot: unset renderer/set power on)
Define Drain.s, i
For i = 1 To 20
  Delay(100)
  Drain = OMSX_Poll()
  If Drain <> "" : LogMsg(LogFile, Drain) : EndIf
Next

LogMsg(LogFile, "--- Enviando 'set power off' / 'set power on' / consulta de plataforma ---")
OMSX_SendCommand("set power off")
OMSX_SendCommand("set power on")
OMSX_SendCommand("openmsx_info platform")

For i = 1 To 20
  Delay(100)
  Drain = OMSX_Poll()
  If Drain <> "" : LogMsg(LogFile, Drain) : EndIf
Next

LogMsg(LogFile, "--- fim (openMSX permanece aberto - fechar manualmente) ---")
LogMsg(LogFile, "OMSX_IsRunning() final = " + Str(OMSX_IsRunning()))
CloseFile(LogFile)
End 0
