;
; ------------------------------------------------------------
;  PaleoBasicSetup.pb - instalador standalone do PaleoBasic.
;
;  Programa PEQUENO e AUTOCONTIDO, de proposito: nao faz XIncludeFile de
;  nada de src/editor/ (BadigEditor.pb e as dezenas de .pbi sao o EDITOR, nao
;  tem nada a ver com instalacao) - so duplica os poucos trechos realmente
;  necessarios (registro de associacao de arquivo, no mesmo formato/ProgId
;  que FileAssociationGui.pbi ja usa, pra ficar 100% compativel com o que o
;  editor detecta em "Configurar -> Associacoes de arquivo...").
;
;  O que faz, nessa ordem, tudo perguntado numa unica tela (sem wizard de
;  varias paginas - pedido do usuario era simplicidade):
;   1. Pergunta a pasta de instalacao (default: %LOCALAPPDATA%\PaleoBasic -
;      escolhido de proposito por NAO precisar de elevacao/UAC, ao contrario
;      de Program Files; ver decisao do usuario abaixo).
;   2. Detecta se ja existe uma instalacao ali (PaleoBasic.exe presente) -
;      se sim, a tela vira "Atualizar" em vez de "Instalar".
;   3. Extrai o payload (dist\ inteiro, exceto configuracoes/ROMs/projetos
;      pessoais - ver BuildPayloadZip.pb/build-installer.ps1) embutido neste
;      .exe via IncludeBinary, pulando qualquer arquivo de configuracao
;      (editor/*.json, fossauro/*.json) que JA EXISTA no destino - e assim
;      que "atualizar preserva configuracao" e satisfeito, sem logica
;      separada de "modo update": a mesma regra vale nos dois casos, so que
;      numa instalacao nova nao ha nada pra preservar ainda.
;   4. Associa .msxproject ao PaleoBasic.exe recem-instalado (registro em
;      HKEY_CURRENT_USER\Software\Classes, sem precisar de admin - mesmo
;      lugar/ProgId que FileAssociationGui.pbi).
;   5. Acrescenta a pasta de instalacao ao PATH do USUARIO (nao o do
;      sistema/HKLM - pedido explicito do usuario, 2026-08-22: sem
;      elevacao/UAC, mesmo espirito do item 4).
;
;  Decisao do usuario (2026-08-22, antes de comecar a escrever isto): escopo
;  "so usuario atual" (sem UAC) em vez de "maquina toda"; payload ZIP
;  embutido no proprio .exe do instalador (gerado a cada build) em vez de um
;  arquivo .zip separado ao lado - ver AskUserQuestion na conversa que gerou
;  este arquivo.
; ------------------------------------------------------------

EnableExplicit

#App_Title = "PaleoBasic"
CompilerIf Not Defined(App_Version, #PB_Constant)
  #App_Version = "0.0.0-dev"
CompilerEndIf

;- ------------------------------------------------------------
;- Registro do Windows (RegCreateKeyExW/etc nao vem pre-declarado por este
;- pbcompiler - mesmo achado/idioma ja documentado em FileAssociationGui.pbi
;- do editor principal, duplicado aqui de proposito porque este instalador e
;- um .pb separado, sem XIncludeFile daquele arquivo).
;- ------------------------------------------------------------
Import "Advapi32.lib"
  CompilerSelect #PB_Compiler_Processor
    CompilerCase #PB_Processor_x86
      Reg_RegCreateKeyExW(hKey.i, SubKey.p-unicode, Reserved.l, Class.i, Options.l, Sam.l, SecAttr.i, *Result.Integer, Disposition.i) As "_RegCreateKeyExW@36"
      Reg_RegSetValueExW(hKey.i, ValueName.p-unicode, Reserved.l, ValType.l, *Data, DataLen.l) As "_RegSetValueExW@24"
      Reg_RegOpenKeyExW(hKey.i, SubKey.p-unicode, Options.l, Sam.l, *Result.Integer) As "_RegOpenKeyExW@20"
      Reg_RegQueryValueExW(hKey.i, ValueName.p-unicode, Reserved.i, *ValType.Long, *Data, *DataLen.Long) As "_RegQueryValueExW@24"
      Reg_RegCloseKey(hKey.i) As "_RegCloseKey@4"
    CompilerDefault
      Reg_RegCreateKeyExW(hKey.i, SubKey.p-unicode, Reserved.l, Class.i, Options.l, Sam.l, SecAttr.i, *Result.Integer, Disposition.i) As "RegCreateKeyExW"
      Reg_RegSetValueExW(hKey.i, ValueName.p-unicode, Reserved.l, ValType.l, *Data, DataLen.l) As "RegSetValueExW"
      Reg_RegOpenKeyExW(hKey.i, SubKey.p-unicode, Options.l, Sam.l, *Result.Integer) As "RegOpenKeyExW"
      Reg_RegQueryValueExW(hKey.i, ValueName.p-unicode, Reserved.i, *ValType.Long, *Data, *DataLen.Long) As "RegQueryValueExW"
      Reg_RegCloseKey(hKey.i) As "RegCloseKey"
  CompilerEndSelect
EndImport

Import "Shell32.lib"
  CompilerSelect #PB_Compiler_Processor
    CompilerCase #PB_Processor_x86
      Reg_SHChangeNotify(EventId.l, Flags.l, Item1.i, Item2.i) As "_SHChangeNotify@16"
    CompilerDefault
      Reg_SHChangeNotify(EventId.l, Flags.l, Item1.i, Item2.i) As "SHChangeNotify"
  CompilerEndSelect
EndImport

#Reg_SHCNE_ASSOCCHANGED = $08000000
#Reg_SHCNF_IDLIST       = $0000

#FileAssoc_Extension = ".msxproject"
#FileAssoc_ProgId    = "PaleoBasic.Project"

; Le o valor (default, "") de uma chave HKEY_CURRENT_USER\<SubKey>.
Procedure.s Reg_ReadDefaultValue(SubKey.s)
  Protected hKey.i, Result.s = ""
  Protected ValType.l, DataLen.l
  Protected *Buffer = AllocateMemory(4096)
  If Not *Buffer
    ProcedureReturn ""
  EndIf

  If Reg_RegOpenKeyExW(#HKEY_CURRENT_USER, SubKey, 0, #KEY_READ, @hKey) = #ERROR_SUCCESS
    DataLen = 4096
    If Reg_RegQueryValueExW(hKey, "", 0, @ValType, *Buffer, @DataLen) = #ERROR_SUCCESS And (ValType = #REG_SZ Or ValType = #REG_EXPAND_SZ)
      Result = PeekS(*Buffer, -1, #PB_Unicode)
    EndIf
    Reg_RegCloseKey(hKey)
  EndIf

  FreeMemory(*Buffer)
  ProcedureReturn Result
EndProcedure

Procedure.b Reg_WriteDefaultValue(SubKey.s, Value.s)
  Protected hKey.i, Disposition.l
  If Reg_RegCreateKeyExW(#HKEY_CURRENT_USER, SubKey, 0, 0, #REG_OPTION_NON_VOLATILE, #KEY_WRITE, 0, @hKey, @Disposition) <> #ERROR_SUCCESS
    ProcedureReturn #False
  EndIf
  Reg_RegSetValueExW(hKey, "", 0, #REG_SZ, @Value, (Len(Value) + 1) * SizeOf(Character))
  Reg_RegCloseKey(hKey)
  ProcedureReturn #True
EndProcedure

; Le/grava um valor NOMEADO (nao o "(Default)" da chave) - usado pro PATH
; (HKEY_CURRENT_USER\Environment, valor "Path", tipo REG_EXPAND_SZ).
Procedure.s Reg_ReadNamedValue(SubKey.s, ValueName.s)
  Protected hKey.i, Result.s = ""
  Protected ValType.l, DataLen.l
  Protected *Buffer = AllocateMemory(32768) ; PATH pode ficar bem grande
  If Not *Buffer
    ProcedureReturn ""
  EndIf

  If Reg_RegOpenKeyExW(#HKEY_CURRENT_USER, SubKey, 0, #KEY_READ, @hKey) = #ERROR_SUCCESS
    DataLen = 32768
    If Reg_RegQueryValueExW(hKey, ValueName, 0, @ValType, *Buffer, @DataLen) = #ERROR_SUCCESS And (ValType = #REG_SZ Or ValType = #REG_EXPAND_SZ)
      Result = PeekS(*Buffer, -1, #PB_Unicode)
    EndIf
    Reg_RegCloseKey(hKey)
  EndIf

  FreeMemory(*Buffer)
  ProcedureReturn Result
EndProcedure

Procedure.b Reg_WriteNamedValueExpand(SubKey.s, ValueName.s, Value.s)
  Protected hKey.i, Disposition.l
  If Reg_RegCreateKeyExW(#HKEY_CURRENT_USER, SubKey, 0, 0, #REG_OPTION_NON_VOLATILE, #KEY_WRITE, 0, @hKey, @Disposition) <> #ERROR_SUCCESS
    ProcedureReturn #False
  EndIf
  Reg_RegSetValueExW(hKey, ValueName, 0, #REG_EXPAND_SZ, @Value, (Len(Value) + 1) * SizeOf(Character))
  Reg_RegCloseKey(hKey)
  ProcedureReturn #True
EndProcedure

; Caminho do .exe do PaleoBasic ja instalado, entre aspas, pronto pra entrar
; num valor de registro ("comando"/"DefaultIcon").
Procedure.s ExeQuoted(InstallDir.s)
  ProcedureReturn Chr(34) + InstallDir + "\PaleoBasic.exe" + Chr(34)
EndProcedure

; Mesmo formato/ProgId que FileAssociationGui.pbi (editor/core/) - registrar
; aqui deixa "Configurar -> Associacoes de arquivo..." do proprio editor
; mostrando a caixa ja marcada, sem precisar o usuario mexer em nada depois
; de instalar.
Procedure Setup_ApplyFileAssociation(InstallDir.s)
  Reg_WriteDefaultValue("Software\Classes\" + #FileAssoc_Extension, #FileAssoc_ProgId)
  Reg_WriteDefaultValue("Software\Classes\" + #FileAssoc_ProgId, "Projeto PaleoBasic (MSX)")
  Reg_WriteDefaultValue("Software\Classes\" + #FileAssoc_ProgId + "\DefaultIcon", ExeQuoted(InstallDir) + ",0")
  Reg_WriteDefaultValue("Software\Classes\" + #FileAssoc_ProgId + "\shell\open\command",
                        ExeQuoted(InstallDir) + " " + Chr(34) + "%1" + Chr(34))
  Reg_SHChangeNotify(#Reg_SHCNE_ASSOCCHANGED, #Reg_SHCNF_IDLIST, 0, 0)
EndProcedure

; Acrescenta InstallDir ao PATH do usuario (HKEY_CURRENT_USER\Environment,
; valor "Path") se ainda nao estiver la - nunca duplica numa reinstalacao/
; atualizacao. Retorna #True se o registro foi alterado (pra decidir se vale
; a pena fazer o broadcast de WM_SETTINGCHANGE).
Procedure.b Setup_AddToUserPath(InstallDir.s)
  Protected CurrentPath.s = Reg_ReadNamedValue("Environment", "Path")
  Protected Target.s = InstallDir

  ; Comparacao por segmento, sem distinguir maiusculas/minusculas (Windows) e
  ; ignorando uma "\" final a mais que o usuario possa ter digitado.
  Protected NormTarget.s = LCase(RTrim(Target, "\"))
  Protected I, Segment.s, Count = CountString(CurrentPath, ";") + 1
  For I = 1 To Count
    Segment = StringField(CurrentPath, I, ";")
    If LCase(RTrim(Trim(Segment), "\")) = NormTarget
      ProcedureReturn #False ; ja esta no PATH, nada a fazer
    EndIf
  Next

  Protected NewPath.s
  If Trim(CurrentPath) = ""
    NewPath = Target
  ElseIf Right(Trim(CurrentPath), 1) = ";"
    NewPath = CurrentPath + Target
  Else
    NewPath = CurrentPath + ";" + Target
  EndIf

  Reg_WriteNamedValueExpand("Environment", "Path", NewPath)
  ProcedureReturn #True
EndProcedure

Procedure Setup_BroadcastEnvironmentChange()
  Protected Result.i
  SendMessageTimeout_(#HWND_BROADCAST, #WM_SETTINGCHANGE, 0, @"Environment", #SMTO_ABORTIFHUNG, 5000, @Result)
EndProcedure

;- ------------------------------------------------------------
;- Extracao do payload (dist\ empacotado - ver BuildPayloadZip.pb)
;- ------------------------------------------------------------

; Cria Path e todos os diretorios pai que faltarem - CreateDirectory() do PB
; so garante o ultimo nivel (ver exemplo oficial Packer.pb.html, que so cria
; um nivel), entao subimos a arvore criando de fora pra dentro.
Procedure EnsureDirExists(Path.s)
  If Path = "" Or FileSize(Path) = -2
    ProcedureReturn
  EndIf
  Protected Parent.s = GetPathPart(RTrim(Path, "\"))
  If Parent <> "" And Parent <> Path
    EnsureDirExists(RTrim(Parent, "\"))
  EndIf
  If FileSize(Path) <> -2
    CreateDirectory(Path)
  EndIf
EndProcedure

; Arquivos de configuracao (preferencias do usuario/caminhos de ferramentas
; ja customizados) - nunca sobrescritos se JA existirem no destino. Numa
; instalacao nova (nao existem ainda) sao extraidos normalmente, trazendo os
; defaults que o pacote traz; numa atualizacao, o que ja esta no destino
; prevalece - e assim que "manter configuracoes existentes" e satisfeito,
; sem precisar de um modo "update" separado (ver cabecalho do arquivo).
Procedure.b IsPreserveOnUpdatePath(ArchiveName.s)
  Protected N.s = LCase(ArchiveName)
  If (Left(N, 7) = "editor/" Or Left(N, 9) = "fossauro/") And Right(N, 5) = ".json"
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

DataSection
  Payload_Start:
  IncludeBinary "payload.zip"
  Payload_End:
EndDataSection

; Extrai o payload embutido pra dentro de InstallDir, pulando arquivos de
; config que ja existam (ver IsPreserveOnUpdatePath). StatusGadget/
; ProgressGadget sao atualizados a cada arquivo (podem ser 0 pra rodar sem
; UI, usado nao aqui mas deixado assim por simetria). Devolve #True se tudo
; ocorreu sem erro de extracao (arquivos pulados por preservacao NAO contam
; como erro).
Procedure.b Setup_ExtractPayload(InstallDir.s, StatusGadget.i, ProgressGadget.i)
  UseZipPacker()

  Protected PayloadSize = ?Payload_End - ?Payload_Start
  Protected Pack = CatchPack(#PB_Any, ?Payload_Start, PayloadSize, #PB_PackerPlugin_Zip)
  If Not Pack
    ProcedureReturn #False
  EndIf

  ; Primeira passada so pra contar entradas (pro ProgressBar) - CatchPack
  ; permite examinar de novo do zero rodando ExaminePack outra vez.
  Protected Total = 0
  If ExaminePack(Pack)
    While NextPackEntry(Pack)
      Total + 1
    Wend
  EndIf
  If ProgressGadget And Total > 0
    SetGadgetAttribute(ProgressGadget, #PB_ProgressBar_Maximum, Total)
  EndIf

  Protected Ok = #True
  Protected Done = 0
  Protected ArchiveName.s, DestPath.s, DestDir.s

  If ExaminePack(Pack)
    While NextPackEntry(Pack)
      ArchiveName = PackEntryName(Pack)
      DestPath = InstallDir + "\" + ReplaceString(ArchiveName, "/", "\")

      If IsPreserveOnUpdatePath(ArchiveName) And FileSize(DestPath) >= 0
        ; Config ja existe no destino - preserva, nao mexe.
      Else
        DestDir = GetPathPart(DestPath)
        EnsureDirExists(RTrim(DestDir, "\"))
        If UncompressPackFile(Pack, DestPath, ArchiveName) = -1
          Ok = #False
        EndIf
      EndIf

      Done + 1
      If ProgressGadget
        SetGadgetState(ProgressGadget, Done)
      EndIf
      If StatusGadget
        SetGadgetText(StatusGadget, "Extraindo: " + ArchiveName)
      EndIf
      ; Deixa a janela redesenhar durante a extracao (senao fica "travada"
      ; visualmente ate o loop inteiro terminar) - so bombeia eventos de
      ; redesenho, sem processar entrada do usuario no meio da instalacao.
      WindowEvent()
    Wend
  EndIf

  ClosePack(Pack)
  ProcedureReturn Ok
EndProcedure

;- ------------------------------------------------------------
;- Interface
;- ------------------------------------------------------------

Enumeration Windows
  #Win_Main
EndEnumeration

Enumeration Gadgets
  #G_Title
  #G_Desc
  #G_PathLabel
  #G_PathField
  #G_PathBrowse
  #G_StatusText
  #G_ChkAssoc
  #G_ChkPath
  #G_Progress
  #G_ProgressText
  #G_ChkOpenAfter
  #G_ActionButton
  #G_CloseButton
EndEnumeration

; Pasta padrao sugerida: %LOCALAPPDATA%\PaleoBasic - gravavel sem elevacao,
; ao contrario de Program Files (decisao do usuario: instalacao por usuario,
; sem UAC - ver cabecalho do arquivo).
Procedure.s Setup_DefaultInstallDir()
  Protected LocalAppData.s = GetEnvironmentVariable("LOCALAPPDATA")
  If LocalAppData = ""
    LocalAppData = GetHomeDirectory() + "AppData\Local"
  EndIf
  ProcedureReturn RTrim(LocalAppData, "\") + "\PaleoBasic"
EndProcedure

Procedure.b Setup_HasExistingInstall(Dir.s)
  ProcedureReturn Bool(FileSize(RTrim(Dir, "\") + "\PaleoBasic.exe") > 0)
EndProcedure

Procedure Setup_UpdateModeUI()
  Protected Dir.s = RTrim(GetGadgetText(#G_PathField), "\")
  If Setup_HasExistingInstall(Dir)
    SetGadgetText(#G_StatusText, "Instalacao existente detectada nesta pasta - as configuracoes atuais serao mantidas.")
    SetGadgetText(#G_ActionButton, "Atualizar")
  Else
    SetGadgetText(#G_StatusText, "Pasta nova - sera criada uma instalacao limpa.")
    SetGadgetText(#G_ActionButton, "Instalar")
  EndIf
EndProcedure

Procedure Setup_RunInstall()
  Protected Dir.s = RTrim(Trim(GetGadgetText(#G_PathField)), "\")
  If Dir = ""
    MessageRequester(#App_Title, "Escolha uma pasta de instalacao.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  EnsureDirExists(Dir)
  If FileSize(Dir) <> -2
    MessageRequester(#App_Title, "Nao foi possivel criar a pasta:" + Chr(10) + Dir, #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  DisableGadget(#G_PathField, #True)
  DisableGadget(#G_PathBrowse, #True)
  DisableGadget(#G_ChkAssoc, #True)
  DisableGadget(#G_ChkPath, #True)
  DisableGadget(#G_ActionButton, #True)
  HideGadget(#G_Progress, #False)
  HideGadget(#G_ProgressText, #False)

  Protected ExtractOk = Setup_ExtractPayload(Dir, #G_ProgressText, #G_Progress)

  If GetGadgetState(#G_ChkAssoc) = 1
    Setup_ApplyFileAssociation(Dir)
  EndIf

  Protected PathChanged = #False
  If GetGadgetState(#G_ChkPath) = 1
    PathChanged = Setup_AddToUserPath(Dir)
  EndIf
  If PathChanged
    Setup_BroadcastEnvironmentChange()
  EndIf

  If ExtractOk
    SetGadgetText(#G_ProgressText, "Instalacao concluida.")
    MessageRequester(#App_Title, "Instalacao concluida em:" + Chr(10) + Dir, #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
  Else
    SetGadgetText(#G_ProgressText, "Instalacao concluida com avisos (ver acima).")
    MessageRequester(#App_Title, "A instalacao terminou, mas alguns arquivos nao puderam ser extraidos." + Chr(10) + "Tente rodar o instalador de novo, ou copie manualmente os arquivos que faltarem.", #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
  EndIf

  HideGadget(#G_ChkOpenAfter, #False)
  SetGadgetText(#G_ActionButton, "Concluir")
  DisableGadget(#G_ActionButton, #False)
  SetGadgetState(#G_ActionButton, 0)
EndProcedure

Procedure Setup_OpenMainWindow()
  Protected WinW = 560, WinH = 420
  OpenWindow(#Win_Main, 0, 0, WinW, WinH, "Instalador - " + #App_Title, #PB_Window_SystemMenu | #PB_Window_ScreenCentered)

  TextGadget(#G_Title, 24, 20, WinW - 48, 28, "Instalar " + #App_Title + " " + #App_Version)
  SetGadgetFont(#G_Title, LoadFont(#PB_Any, "Segoe UI", 14, #PB_Font_Bold))

  TextGadget(#G_Desc, 24, 56, WinW - 48, 40,
             "IDE para MSX BASIC (Basic Dignified) e Z80 Assembly. Escolha a pasta de instalacao abaixo.")

  TextGadget(#G_PathLabel, 24, 108, WinW - 48, 20, "Pasta de instalacao:")
  StringGadget(#G_PathField, 24, 130, WinW - 48 - 90, 26, Setup_DefaultInstallDir())
  ButtonGadget(#G_PathBrowse, WinW - 24 - 80, 130, 80, 26, "...")

  TextGadget(#G_StatusText, 24, 166, WinW - 48, 36, "")

  CheckBoxGadget(#G_ChkAssoc, 24, 212, WinW - 48, 22, "Associar arquivos " + #FileAssoc_Extension + " ao " + #App_Title)
  SetGadgetState(#G_ChkAssoc, 1)

  CheckBoxGadget(#G_ChkPath, 24, 238, WinW - 48, 22, "Adicionar a pasta de instalacao ao PATH (permite chamar '" + #App_Title + "' de qualquer lugar)")
  SetGadgetState(#G_ChkPath, 1)

  ProgressBarGadget(#G_Progress, 24, 276, WinW - 48, 20, 0, 100)
  HideGadget(#G_Progress, #True)
  TextGadget(#G_ProgressText, 24, 300, WinW - 48, 20, "")
  HideGadget(#G_ProgressText, #True)

  CheckBoxGadget(#G_ChkOpenAfter, 24, 330, WinW - 48, 22, "Abrir o " + #App_Title + " agora")
  SetGadgetState(#G_ChkOpenAfter, 1)
  HideGadget(#G_ChkOpenAfter, #True)

  ButtonGadget(#G_ActionButton, WinW - 24 - 140, WinH - 56, 140, 32, "Instalar")
  ButtonGadget(#G_CloseButton, 24, WinH - 56, 100, 32, "Cancelar")

  Setup_UpdateModeUI()
EndProcedure

Setup_OpenMainWindow()

Define Event, InstallStarted.b = #False, Quit.b = #False
Define Chosen.s
Repeat
  Event = WaitWindowEvent()
  Select Event
    Case #PB_Event_Gadget
      Select EventGadget()
        Case #G_PathField
          Setup_UpdateModeUI()

        Case #G_PathBrowse
          Chosen = PathRequester("Escolha a pasta de instalacao", GetGadgetText(#G_PathField))
          If Chosen <> ""
            SetGadgetText(#G_PathField, RTrim(Chosen, "\") + "\" + #App_Title)
            Setup_UpdateModeUI()
          EndIf

        Case #G_ActionButton
          If Not InstallStarted
            InstallStarted = #True
            Setup_RunInstall()
          Else
            If GetGadgetState(#G_ChkOpenAfter) = 1
              RunProgram(RTrim(GetGadgetText(#G_PathField), "\") + "\PaleoBasic.exe")
            EndIf
            Quit = #True
          EndIf

        Case #G_CloseButton
          Quit = #True
      EndSelect

    Case #PB_Event_CloseWindow
      Quit = #True
  EndSelect
Until Quit

End
