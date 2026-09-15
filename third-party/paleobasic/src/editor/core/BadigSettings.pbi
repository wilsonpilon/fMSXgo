;
; ------------------------------------------------------------
;  Configuracoes do Basic Dignified Suite
;  Cobre os tres .ini do toolchain Python de referencia (badig/):
;    - support/badig.ini            -> pagina "Basic Dignified"
;    - msx/badig_msx.ini + msx/msxbatoken/msxbatoken.ini -> pagina "MSX"
;    - msx/emulator_interface.ini   -> pagina "Emulador"
;  Persistidas em JSON proprio do editor (nao nos .ini do Python, que
;  continuam existindo so como referencia de comportamento). O caminho do
;  executavel do openMSX e o unico valor que so existe no .ini real (nao ha
;  flag de linha de comando equivalente no badig.py), entao ao salvar tambem
;  gravamos esse valor de volta no emulator_interface.ini.
; ------------------------------------------------------------
;

Structure BadigSettings
  ; -- Pagina 1: Basic Dignified (geral, badig.ini) --
  InstallDir.s       ; pasta onde o toolchain Python (badig/) esta instalado - ver BadigCfg_DefaultInstallDir()
  SystemId.s
  LineStart.i
  LineStep.i
  RemHeader.b
  StripSpaces.b
  CapitalizeAll.b
  Translate.b
  PrintReport.b
  LabelReport.b
  LineReport.b
  VarReport.b
  LexerReport.b
  ParserReport.b
  TabLenght.i
  VerboseLevel.i

  ; -- Pagina 2: MSX (badig_msx.ini + msxbatoken.ini) --
  ConvertPrint.s     ; "" = nao converter, "?" ou "P"
  StripThenGoto.s     ; "" = nao remover, "T" ou "G"
  TkList.b
  TkListWidth.i
  TkDelAscii.b
  TkVerbose.i         ; -1 = nao definido (usa padrao do badig.py)

  ; -- Pagina 3: Emulador (emulator_interface.ini) --
  EmRun.b
  EmulatorPath.s      ; caminho do executavel - PRIMEIRO campo real de proposito, os de baixo
                       ; (maquina/extensoes) precisam dele pra achar share/machines,share/extensions
  EmSetting.s          ; opcional - "-setting <arquivo>" (arquivo de configuracao settings.xml)
  EmScript.s           ; opcional - "-script <arquivo>" (script Tcl executado no boot)
  EmMachine.s
  EmExtensionA.s       ; opcional - "-exta <nome>" (openMSX aceita ate 4 extensoes simultaneas,
  EmExtensionB.s       ; slots A-D independentes - nao sao so "disco": qualquer hardware de
  EmExtensionC.s       ; extensao real, share/extensions/*.xml no proprio openMSX)
  EmExtensionD.s
  EmNoThrottle.b
  EmMonitor.b
  EmVerbose.i         ; -1 = nao definido
EndStructure

Global BadigCfg.BadigSettings

;- ------------------------------------------------------------
;- Valores padrao
;- ------------------------------------------------------------

; Se a instalacao "classica" (ao lado do .exe, "badig" - onde o submodulo do
; toolchain Python vive hoje) ja existir, usa ela como default (evita quebrar
; quem ja tem o projeto configurado). Senao, usa o novo default pedido: pasta
; "badig" dentro do caminho de instalacao do editor (EditorCfg\EditorPath,
; ver EditorSettings.pbi - editavel em Configurar -> Editor..., util para
; manter 2 instalacoes separadas do editor).
Procedure.s BadigCfg_DefaultInstallDir()
  Protected Legacy.s = GetPathPart(ProgramFilename()) + "badig"
  If FileSize(Legacy) = -2
    ProcedureReturn Legacy
  EndIf
  ProcedureReturn EditorCfg\EditorPath + "badig"
EndProcedure

Procedure BadigCfg_SetDefaults()
  BadigCfg\InstallDir = BadigCfg_DefaultInstallDir()
  BadigCfg\SystemId = "msx"
  BadigCfg\LineStart = 10
  BadigCfg\LineStep = 10
  BadigCfg\RemHeader = #True
  BadigCfg\StripSpaces = #False
  BadigCfg\CapitalizeAll = #False
  ; Traduzir por padrao: sem isso o arquivo fonte (UTF-8) e lido incorretamente
  ; quando ha caracteres especiais (box-drawing, acentos, letras gregas) em
  ; strings literais, corrompendo o .bmx gerado a partir dali.
  BadigCfg\Translate = #True
  BadigCfg\PrintReport = #False
  BadigCfg\LabelReport = #False
  BadigCfg\LineReport = #False
  BadigCfg\VarReport = #False
  BadigCfg\LexerReport = #False
  BadigCfg\ParserReport = #False
  BadigCfg\TabLenght = 4
  BadigCfg\VerboseLevel = 3

  BadigCfg\ConvertPrint = ""
  BadigCfg\StripThenGoto = ""
  BadigCfg\TkList = #False
  BadigCfg\TkListWidth = 16
  BadigCfg\TkDelAscii = #False
  BadigCfg\TkVerbose = -1

  BadigCfg\EmRun = #False
  BadigCfg\EmulatorPath = ""
  BadigCfg\EmSetting = ""
  BadigCfg\EmScript = ""
  BadigCfg\EmMachine = ""
  BadigCfg\EmExtensionA = ""
  BadigCfg\EmExtensionB = ""
  BadigCfg\EmExtensionC = ""
  BadigCfg\EmExtensionD = ""
  BadigCfg\EmNoThrottle = #False
  BadigCfg\EmMonitor = #True
  BadigCfg\EmVerbose = -1
EndProcedure

;- ------------------------------------------------------------
;- Persistencia em JSON
;- ------------------------------------------------------------

; OverridePath (opcional): "" = comportamento normal (JSON global ao lado
; do .exe); qualquer outro valor e usado como caminho COMPLETO em vez do
; global - usado por "Configurar -> Projeto..." (ProjectSettingsGui.pbi)
; pra ler/gravar um JSON por-projeto sem duplicar nenhuma logica de
; campo/UI (a janela de configuracao em si nao muda nada, so passa esse
; parametro adiante).
Procedure.s BadigCfg_FilePath(OverridePath.s = "")
  If OverridePath <> ""
    ProcedureReturn OverridePath
  EndIf
  ProcedureReturn GetPathPart(ProgramFilename()) + "editor\badig_settings.json"
EndProcedure

Procedure BadigCfg_Load(OverridePath.s = "")
  BadigCfg_SetDefaults()

  Protected FilePath.s = BadigCfg_FilePath(OverridePath)
  If FileSize(FilePath) <= 0
    ProcedureReturn #False
  EndIf

  Protected Json = LoadJSON(#PB_Any, FilePath)
  If Not Json
    ProcedureReturn #False
  EndIf

  Protected Root = JSONValue(Json)
  Protected M

  M = GetJSONMember(Root, "InstallDir")     : If M : BadigCfg\InstallDir = GetJSONString(M) : EndIf
  M = GetJSONMember(Root, "SystemId")       : If M : BadigCfg\SystemId = GetJSONString(M) : EndIf
  M = GetJSONMember(Root, "LineStart")      : If M : BadigCfg\LineStart = GetJSONInteger(M) : EndIf
  M = GetJSONMember(Root, "LineStep")       : If M : BadigCfg\LineStep = GetJSONInteger(M) : EndIf
  M = GetJSONMember(Root, "RemHeader")      : If M : BadigCfg\RemHeader = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "StripSpaces")    : If M : BadigCfg\StripSpaces = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "CapitalizeAll")  : If M : BadigCfg\CapitalizeAll = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "Translate")      : If M : BadigCfg\Translate = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "PrintReport")    : If M : BadigCfg\PrintReport = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "LabelReport")    : If M : BadigCfg\LabelReport = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "LineReport")     : If M : BadigCfg\LineReport = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "VarReport")      : If M : BadigCfg\VarReport = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "LexerReport")    : If M : BadigCfg\LexerReport = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "ParserReport")   : If M : BadigCfg\ParserReport = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "TabLenght")      : If M : BadigCfg\TabLenght = GetJSONInteger(M) : EndIf
  M = GetJSONMember(Root, "VerboseLevel")   : If M : BadigCfg\VerboseLevel = GetJSONInteger(M) : EndIf

  M = GetJSONMember(Root, "ConvertPrint")   : If M : BadigCfg\ConvertPrint = GetJSONString(M) : EndIf
  M = GetJSONMember(Root, "StripThenGoto")  : If M : BadigCfg\StripThenGoto = GetJSONString(M) : EndIf
  M = GetJSONMember(Root, "TkList")         : If M : BadigCfg\TkList = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "TkListWidth")    : If M : BadigCfg\TkListWidth = GetJSONInteger(M) : EndIf
  M = GetJSONMember(Root, "TkDelAscii")     : If M : BadigCfg\TkDelAscii = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "TkVerbose")      : If M : BadigCfg\TkVerbose = GetJSONInteger(M) : EndIf

  M = GetJSONMember(Root, "EmRun")          : If M : BadigCfg\EmRun = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "EmSetting")      : If M : BadigCfg\EmSetting = GetJSONString(M) : EndIf
  M = GetJSONMember(Root, "EmScript")       : If M : BadigCfg\EmScript = GetJSONString(M) : EndIf
  M = GetJSONMember(Root, "EmMachine")      : If M : BadigCfg\EmMachine = GetJSONString(M) : EndIf
  M = GetJSONMember(Root, "EmExtensionA")   : If M : BadigCfg\EmExtensionA = GetJSONString(M) : EndIf
  M = GetJSONMember(Root, "EmExtensionB")   : If M : BadigCfg\EmExtensionB = GetJSONString(M) : EndIf
  M = GetJSONMember(Root, "EmExtensionC")   : If M : BadigCfg\EmExtensionC = GetJSONString(M) : EndIf
  M = GetJSONMember(Root, "EmExtensionD")   : If M : BadigCfg\EmExtensionD = GetJSONString(M) : EndIf
  ; Migracao de config antiga (1 extensao so, formato "Nome:slot" opcional) - so aplica se
  ; nenhum dos 4 slots novos ja tiver sido carregado acima (config nova tem prioridade).
  If BadigCfg\EmExtensionA = "" And BadigCfg\EmExtensionB = "" And BadigCfg\EmExtensionC = "" And BadigCfg\EmExtensionD = ""
    M = GetJSONMember(Root, "EmExtension")
    If M
      Protected OldExt.s = GetJSONString(M)
      Protected OldColonPos.i = FindString(OldExt, ":")
      If OldColonPos > 0
        Select UCase(Mid(OldExt, OldColonPos + 1))
          Case "B" : BadigCfg\EmExtensionB = Left(OldExt, OldColonPos - 1)
          Case "C" : BadigCfg\EmExtensionC = Left(OldExt, OldColonPos - 1)
          Case "D" : BadigCfg\EmExtensionD = Left(OldExt, OldColonPos - 1)
          Default  : BadigCfg\EmExtensionA = Left(OldExt, OldColonPos - 1)
        EndSelect
      ElseIf OldExt <> ""
        BadigCfg\EmExtensionA = OldExt
      EndIf
    EndIf
  EndIf
  M = GetJSONMember(Root, "EmNoThrottle")   : If M : BadigCfg\EmNoThrottle = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "EmMonitor")      : If M : BadigCfg\EmMonitor = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "EmVerbose")      : If M : BadigCfg\EmVerbose = GetJSONInteger(M) : EndIf
  M = GetJSONMember(Root, "EmulatorPath")   : If M : BadigCfg\EmulatorPath = GetJSONString(M) : EndIf

  FreeJSON(Json)
  ProcedureReturn #True
EndProcedure

Procedure BadigCfg_Save(OverridePath.s = "")
  Protected Json = CreateJSON(#PB_Any)
  Protected Root = SetJSONObject(JSONValue(Json))

  SetJSONString(AddJSONMember(Root, "InstallDir"), BadigCfg\InstallDir)
  SetJSONString(AddJSONMember(Root, "SystemId"), BadigCfg\SystemId)
  SetJSONInteger(AddJSONMember(Root, "LineStart"), BadigCfg\LineStart)
  SetJSONInteger(AddJSONMember(Root, "LineStep"), BadigCfg\LineStep)
  SetJSONBoolean(AddJSONMember(Root, "RemHeader"), BadigCfg\RemHeader)
  SetJSONBoolean(AddJSONMember(Root, "StripSpaces"), BadigCfg\StripSpaces)
  SetJSONBoolean(AddJSONMember(Root, "CapitalizeAll"), BadigCfg\CapitalizeAll)
  SetJSONBoolean(AddJSONMember(Root, "Translate"), BadigCfg\Translate)
  SetJSONBoolean(AddJSONMember(Root, "PrintReport"), BadigCfg\PrintReport)
  SetJSONBoolean(AddJSONMember(Root, "LabelReport"), BadigCfg\LabelReport)
  SetJSONBoolean(AddJSONMember(Root, "LineReport"), BadigCfg\LineReport)
  SetJSONBoolean(AddJSONMember(Root, "VarReport"), BadigCfg\VarReport)
  SetJSONBoolean(AddJSONMember(Root, "LexerReport"), BadigCfg\LexerReport)
  SetJSONBoolean(AddJSONMember(Root, "ParserReport"), BadigCfg\ParserReport)
  SetJSONInteger(AddJSONMember(Root, "TabLenght"), BadigCfg\TabLenght)
  SetJSONInteger(AddJSONMember(Root, "VerboseLevel"), BadigCfg\VerboseLevel)

  SetJSONString(AddJSONMember(Root, "ConvertPrint"), BadigCfg\ConvertPrint)
  SetJSONString(AddJSONMember(Root, "StripThenGoto"), BadigCfg\StripThenGoto)
  SetJSONBoolean(AddJSONMember(Root, "TkList"), BadigCfg\TkList)
  SetJSONInteger(AddJSONMember(Root, "TkListWidth"), BadigCfg\TkListWidth)
  SetJSONBoolean(AddJSONMember(Root, "TkDelAscii"), BadigCfg\TkDelAscii)
  SetJSONInteger(AddJSONMember(Root, "TkVerbose"), BadigCfg\TkVerbose)

  SetJSONBoolean(AddJSONMember(Root, "EmRun"), BadigCfg\EmRun)
  SetJSONString(AddJSONMember(Root, "EmSetting"), BadigCfg\EmSetting)
  SetJSONString(AddJSONMember(Root, "EmScript"), BadigCfg\EmScript)
  SetJSONString(AddJSONMember(Root, "EmMachine"), BadigCfg\EmMachine)
  SetJSONString(AddJSONMember(Root, "EmExtensionA"), BadigCfg\EmExtensionA)
  SetJSONString(AddJSONMember(Root, "EmExtensionB"), BadigCfg\EmExtensionB)
  SetJSONString(AddJSONMember(Root, "EmExtensionC"), BadigCfg\EmExtensionC)
  SetJSONString(AddJSONMember(Root, "EmExtensionD"), BadigCfg\EmExtensionD)
  SetJSONBoolean(AddJSONMember(Root, "EmNoThrottle"), BadigCfg\EmNoThrottle)
  SetJSONBoolean(AddJSONMember(Root, "EmMonitor"), BadigCfg\EmMonitor)
  SetJSONInteger(AddJSONMember(Root, "EmVerbose"), BadigCfg\EmVerbose)
  SetJSONString(AddJSONMember(Root, "EmulatorPath"), BadigCfg\EmulatorPath)

  SaveJSON(Json, BadigCfg_FilePath(OverridePath), #PB_JSON_PrettyPrint)
  FreeJSON(Json)
EndProcedure

;- ------------------------------------------------------------
;- Sincroniza o caminho do emulador com o .ini real do badig/
;- (unico valor sem flag de linha de comando equivalente)
;- ------------------------------------------------------------

Procedure.s BadigCfg_OSSectionName()
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    ProcedureReturn "WINDOWS"
  CompilerElseIf #PB_Compiler_OS = #PB_OS_Linux
    ProcedureReturn "LINUX"
  CompilerElse
    ProcedureReturn "DARWIN"
  CompilerEndIf
EndProcedure

Procedure BadigCfg_SyncEmulatorIni()
  If BadigCfg\EmulatorPath = ""
    ProcedureReturn
  EndIf

  Protected IniPath.s = BadigCfg\InstallDir + "\msx\emulator_interface.ini"
  If FileSize(IniPath) <= 0
    ProcedureReturn
  EndIf

  Protected TargetSection.s = BadigCfg_OSSectionName()
  Protected InFile = ReadFile(#PB_Any, IniPath)
  If Not InFile
    ProcedureReturn
  EndIf

  Protected NewList Lines.s()
  Protected CurrentSection.s = ""
  Protected Line.s

  While Not Eof(InFile)
    Line = ReadString(InFile, #PB_UTF8)
    Protected Trimmed.s = Trim(Line)

    If Left(Trimmed, 1) = "[" And Right(Trimmed, 1) = "]"
      CurrentSection = UCase(Mid(Trimmed, 2, Len(Trimmed) - 2))
    ElseIf CurrentSection = TargetSection And LCase(Left(Trimmed, 13)) = "emulator_path"
      Line = "emulator_path = " + BadigCfg\EmulatorPath
    EndIf

    AddElement(Lines())
    Lines() = Line
  Wend
  CloseFile(InFile)

  Protected OutFile = CreateFile(#PB_Any, IniPath)
  If OutFile
    ForEach Lines()
      WriteStringN(OutFile, Lines(), #PB_UTF8)
    Next
    CloseFile(OutFile)
  EndIf
EndProcedure

;- ------------------------------------------------------------
;- Download do Basic Dignified Suite (clone via Git ou .zip do GitHub)
;- UseZipPacker() ja foi declarado em EditorSettings.pbi (incluido antes
;- deste arquivo - ver XIncludeFile em BadigEditor.pb).
;- ------------------------------------------------------------

#BadigSuite_GitUrl = "https://github.com/farique1/basic-dignified.git"
#BadigSuite_ZipUrl  = "https://github.com/farique1/basic-dignified/archive/refs/heads/main.zip"

UseNetworkTLS() ; necessario para ReceiveHTTPFile() conseguir falar https:// (GitHub)

; Descompacta ZipPath em TargetDir, removendo o prefixo de pasta unico que o
; GitHub inclui em arquivos de archive (ex.: "basic-dignified-main/") para que
; o conteudo do repositorio fique direto dentro de TargetDir, sem subpasta extra.
; OnlyUnderPrefix (opcional, "" = comportamento antigo/todo o zip): quando
; informado (ex.: "demo"), extrai SO as entradas dentro dessa subpasta do
; repositorio - o prefixo tambem e removido do caminho final, entao
; "demo/scroll1/scroll1.bas" com OnlyUnderPrefix = "demo" vira
; TargetDir\scroll1\scroll1.bas, como se "demo/" fosse a raiz do zip. Usado
; por MsxBas2Rom_DownloadExamples() (MsxBas2RomSupport.pbi) pra baixar so a
; pasta de exemplos de um repositorio grande sem extrair o resto (codigo
; fonte C++ etc.) pro disco do usuario.
Procedure.b BadigCfg_ExtractZip(ZipPath.s, TargetDir.s, OnlyUnderPrefix.s = "")
  Protected Pack = OpenPack(#PB_Any, ZipPath, #PB_PackerPlugin_Zip)
  If Not Pack
    ProcedureReturn #False
  EndIf

  If Not ExaminePack(Pack)
    ClosePack(Pack)
    ProcedureReturn #False
  EndIf

  Protected Prefix.s = ""
  If NextPackEntry(Pack) > 0
    Protected FirstName.s = PackEntryName(Pack)
    Protected SlashPos = FindString(FirstName, "/")
    If SlashPos > 0
      Prefix = Left(FirstName, SlashPos)
    EndIf
  EndIf

  CreateDirectory(TargetDir)

  Protected FilterPrefix.s = OnlyUnderPrefix
  If FilterPrefix <> "" And Right(FilterPrefix, 1) <> "/"
    FilterPrefix + "/"
  EndIf

  Protected EntryName.s, RelName.s, OutPath.s
  ExaminePack(Pack)
  While NextPackEntry(Pack) > 0
    EntryName = PackEntryName(Pack)
    RelName = EntryName
    If Prefix <> "" And Left(EntryName, Len(Prefix)) = Prefix
      RelName = Mid(EntryName, Len(Prefix) + 1)
    EndIf
    If RelName = ""
      Continue
    EndIf

    If FilterPrefix <> ""
      If Left(RelName, Len(FilterPrefix)) <> FilterPrefix
        Continue
      EndIf
      RelName = Mid(RelName, Len(FilterPrefix) + 1)
      If RelName = ""
        Continue
      EndIf
    EndIf

    OutPath = TargetDir + "\" + RelName

    If Right(EntryName, 1) = "/"
      CreateDirectory(OutPath)
    Else
      CreateDirectory(GetPathPart(OutPath))
      UncompressPackFile(Pack, OutPath)
    EndIf
  Wend

  ClosePack(Pack)
  ProcedureReturn #True
EndProcedure

Procedure BadigCfg_DownloadViaGit(TargetDir.s)
  Protected Params.s = "clone --depth 1 " + #BadigSuite_GitUrl + " " + Chr(34) + TargetDir + Chr(34)
  Protected Prog = RunProgram("git", Params, GetPathPart(ProgramFilename()), #PB_Program_Wait | #PB_Program_Hide)
  If Not Prog
    MessageRequester("Erro", "Git nao encontrado. Instale o Git (https://git-scm.com/) ou use a opcao de download via ZIP.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  Protected ExitCode = ProgramExitCode(Prog)
  CloseProgram(Prog)

  If ExitCode = 0
    MessageRequester("Basic Dignified Suite", "Clonado com sucesso em:" + Chr(10) + TargetDir,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
  Else
    MessageRequester("Erro", "O comando 'git clone' falhou (codigo " + Str(ExitCode) + ")." + Chr(10) +
                     "Verifique se a pasta ja existe e nao esta vazia, ou tente a opcao de download via ZIP.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
  EndIf
EndProcedure

Procedure BadigCfg_DownloadViaZip(TargetDir.s)
  Protected TmpZip.s = GetTemporaryDirectory() + "basic-dignified-" + Str(Random(999999)) + ".zip"

  If Not ReceiveHTTPFile(#BadigSuite_ZipUrl, TmpZip)
    MessageRequester("Erro", "Falha ao baixar o arquivo ZIP do GitHub." + Chr(10) + "Verifique sua conexao com a internet.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    If FileSize(TmpZip) >= 0 : DeleteFile(TmpZip) : EndIf
    ProcedureReturn
  EndIf

  If Not BadigCfg_ExtractZip(TmpZip, TargetDir)
    MessageRequester("Erro", "Falha ao descompactar o arquivo ZIP baixado.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    DeleteFile(TmpZip)
    ProcedureReturn
  EndIf

  DeleteFile(TmpZip)
  MessageRequester("Basic Dignified Suite", "Baixado e descompactado com sucesso em:" + Chr(10) + TargetDir,
                   #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
EndProcedure

Procedure BadigCfg_DownloadSuite(ParentWindow, TargetDir.s)
  If Trim(TargetDir) = ""
    MessageRequester("Erro", "Informe o diretorio de instalacao antes de baixar.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  If FileSize(TargetDir) = -2
    Protected Confirm = MessageRequester("Basic Dignified Suite",
      "A pasta" + Chr(10) + TargetDir + Chr(10) + "ja existe. Continuar pode sobrescrever arquivos nela." + Chr(10) + Chr(10) + "Continuar?",
      #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning)
    If Confirm <> #PB_MessageRequester_Yes
      ProcedureReturn
    EndIf
  EndIf

  Protected Method = MessageRequester("Basic Dignified Suite",
    "Como deseja baixar?" + Chr(10) + Chr(10) +
    "SIM = clonar com Git (recomendado, permite atualizar depois)" + Chr(10) +
    "NAO = baixar o .zip da branch main e descompactar" + Chr(10) + Chr(10) +
    "Pasta de destino:" + Chr(10) + TargetDir,
    #PB_MessageRequester_YesNoCancel | #PB_MessageRequester_Info)

  Select Method
    Case #PB_MessageRequester_Yes
      BadigCfg_DownloadViaGit(TargetDir)
    Case #PB_MessageRequester_No
      BadigCfg_DownloadViaZip(TargetDir)
  EndSelect
EndProcedure

;- ------------------------------------------------------------
;- Selecao de maquina/extensao do openMSX (lista os arquivos .xml de
;- share/machines ou share/extensions, a partir do diretorio do executavel
;- configurado no campo acima) - pedido pelo usuario para nao precisar
;- digitar o nome exato da maquina/extensao de cabeca.
;- ------------------------------------------------------------

; Lista os nomes (sem a extensao .xml) dos arquivos .xml em Dir, ordenados
; alfabeticamente (case-insensitive). Devolve #False se o diretorio nao existir.
Procedure.b BadigCfg_ListXmlNames(Dir.s, List Names.s())
  ClearList(Names())
  If FileSize(Dir) <> -2 ; -2 = diretorio existe
    ProcedureReturn #False
  EndIf

  Protected Handle = ExamineDirectory(#PB_Any, Dir, "*.xml")
  If Not Handle
    ProcedureReturn #False
  EndIf

  While NextDirectoryEntry(Handle)
    If DirectoryEntryType(Handle) = #PB_DirectoryEntry_File
      Protected Name.s = DirectoryEntryName(Handle)
      AddElement(Names())
      Names() = Left(Name, Len(Name) - 4) ; remove ".xml"
    EndIf
  Wend
  FinishDirectory(Handle)

  SortList(Names(), #PB_Sort_Ascending | #PB_Sort_NoCase)
  ProcedureReturn #True
EndProcedure

; Abre uma janela modal simples com uma lista dos itens encontrados em Dir
; para o usuario escolher um (duplo-clique ou "OK"). Devolve o nome escolhido
; (sem .xml) ou "" se cancelado, se o diretorio nao existir ou vier vazio
; (mostra um aviso claro nesses dois ultimos casos, apontando para o campo
; do executavel do openMSX que define a base da busca).
Procedure.s BadigCfg_PickXmlName(ParentWindow, Title.s, Dir.s, CurrentValue.s)
  Protected NewList Names.s()

  If Not BadigCfg_ListXmlNames(Dir, Names())
    MessageRequester("Diretorio nao encontrado",
                     "Nao foi possivel encontrar:" + Chr(10) + Dir + Chr(10) + Chr(10) +
                     "Confira o caminho do executavel do openMSX configurado acima.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn ""
  EndIf

  If ListSize(Names()) = 0
    MessageRequester("Nada encontrado",
                     "Nenhum arquivo .xml encontrado em:" + Chr(10) + Dir,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn ""
  EndIf

  Protected WinW = 420, WinH = 460
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, Title,
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #True, #False)
  If Not Win
    ProcedureReturn ""
  EndIf

  Protected G_List = ListViewGadget(#PB_Any, 24, 24, WinW - 48, WinH - 96)
  Protected SelectIndex = -1, i.i = 0
  ForEach Names()
    AddGadgetItem(G_List, -1, Names())
    If Names() = CurrentValue
      SelectIndex = i
    EndIf
    i + 1
  Next
  If SelectIndex >= 0
    SetGadgetState(G_List, SelectIndex)
  EndIf

  Protected G_Ok = ThemedButton(WinW - 256, WinH - 56, 110, 32, "OK", "")
  Protected G_Cancel = ThemedButton(WinW - 134, WinH - 56, 110, 32, "Cancelar", "")

  Protected Event, Quit = #False, Result.s = "", Sel.i

  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_List
            If EventType() = #PB_EventType_LeftDoubleClick
              Sel = GetGadgetState(G_List)
              If Sel >= 0
                Result = GetGadgetItemText(G_List, Sel)
              EndIf
              Quit = #True
            EndIf

          Case G_Ok
            Sel = GetGadgetState(G_List)
            If Sel >= 0
              Result = GetGadgetItemText(G_List, Sel)
            EndIf
            Quit = #True

          Case G_Cancel
            Quit = #True
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
  ProcedureReturn Result
EndProcedure

; Diretorio "share\<SubFolder>\" a partir do caminho do executavel do openMSX
; (respeitando o separador nativo do SO devolvido por GetPathPart).
Procedure.s BadigCfg_OpenMsxShareDir(ExePath.s, SubFolder.s)
  Protected Base.s = GetPathPart(ExePath)
  Protected Sep.s = Right(Base, 1)
  ProcedureReturn Base + "share" + Sep + SubFolder + Sep
EndProcedure

;- ------------------------------------------------------------
;- Campos da pagina "Emulador" - compartilhados entre a aba "Emulador" de
;- Configurar -> Basic Dignified... (BadigCfg_OpenSettingsWindow, abaixo) e a
;- janela standalone Configurar -> openMSX (OpenMsxCfg_OpenSettingsWindow, em
;- OpenMsxSettingsGui.pbi) - as duas leem/gravam os MESMOS campos BadigCfg\Em*
;- por construcao (nunca duas fontes de verdade), so a moldura ao redor muda
;- (aba de painel vs. janela propria).
;- ------------------------------------------------------------

Structure BadigCfg_EmuGadgets
  G_EmRun.i
  G_EmMonitor.i
  G_EmNoThrottle.i
  G_EmulatorPath.i
  G_EmulatorPathBrowse.i
  G_EmSetting.i
  G_EmSettingBrowse.i
  G_EmScript.i
  G_EmScriptBrowse.i
  G_EmMachine.i
  G_EmMachineBrowse.i
  G_EmExtensionA.i
  G_EmExtensionABrowse.i
  G_EmExtensionB.i
  G_EmExtensionBBrowse.i
  G_EmExtensionC.i
  G_EmExtensionCBrowse.i
  G_EmExtensionD.i
  G_EmExtensionDBrowse.i
  G_EmVerbose.i
EndStructure

; Cria os gadgets da pagina "Emulador" com Y deslocado por BaseY (mesmas
; coordenadas X de sempre) - funciona tanto dentro de um PanelGadget (chamado
; logo apos AddGadgetItem(Panel, -1, "Emulador"), ainda no contexto de
; gadget-list dessa pagina, BaseY = 0) quanto numa janela comum (BaseY = 0,
; mesma margem externa de 24px). Ordem de cima pra baixo escolhida de
; proposito (bug real reportado pelo usuario, 2026-08-19): o campo do
; EXECUTAVEL vem PRIMEIRO agora, porque Maquina/Extensoes dependem dele pra
; achar share/machines,share/extensions (ver BadigCfg_HandleEmulatorGadgetEvent
; abaixo) - na ordem antiga (Setting/Maquina/Extensao/Verbose/Executavel, o
; executavel por ULTIMO) o usuario clicava nos campos de cima pra baixo,
; caindo direto no aviso "informe o executavel primeiro" sem entender por que
; um campo que parecia nao ter relacao com o executavel pedia isso.
Procedure BadigCfg_CreateEmulatorGadgets(BaseY.i, *G.BadigCfg_EmuGadgets)
  *G\G_EmRun = CheckBoxGadget(#PB_Any, 24, BaseY + 24, 460, 22, "Abrir o openMSX e rodar o codigo apos gerar")
  *G\G_EmMonitor = CheckBoxGadget(#PB_Any, 24, BaseY + 54, 460, 22, "Monitorar execucao (detectar erros em runtime)")
  *G\G_EmNoThrottle = CheckBoxGadget(#PB_Any, 24, BaseY + 84, 460, 22, "Rodar sem limitador de velocidade (nothrottle)")

  TextGadget(#PB_Any, 24, BaseY + 136, 560, 20, "Caminho do executavel do openMSX (grava no emulator_interface.ini)")
  *G\G_EmulatorPath = StringGadget(#PB_Any, 24, BaseY + 164, 512, 24, BadigCfg\EmulatorPath)
  *G\G_EmulatorPathBrowse = ThemedButton(544, BaseY + 164, 64, 24, "...", "")

  TextGadget(#PB_Any, 24, BaseY + 214, 420, 20, "Arquivo de configuracao settings.xml (opcional, -setting)")
  *G\G_EmSetting = StringGadget(#PB_Any, 24, BaseY + 242, 512, 24, BadigCfg\EmSetting)
  *G\G_EmSettingBrowse = ThemedButton(544, BaseY + 242, 64, 24, "...", "")

  TextGadget(#PB_Any, 24, BaseY + 292, 420, 20, "Script Tcl a executar no boot (opcional, -script)")
  *G\G_EmScript = StringGadget(#PB_Any, 24, BaseY + 320, 512, 24, BadigCfg\EmScript)
  *G\G_EmScriptBrowse = ThemedButton(544, BaseY + 320, 64, 24, "...", "")

  TextGadget(#PB_Any, 24, BaseY + 370, 320, 20, "Maquina (machine)")
  *G\G_EmMachine = StringGadget(#PB_Any, 24, BaseY + 398, 512, 24, BadigCfg\EmMachine)
  *G\G_EmMachineBrowse = ThemedButton(544, BaseY + 398, 64, 24, "...", "")

  ; 4 slots simultaneos de verdade (-exta/-extb/-extc/-extd), todos opcionais - openMSX aceita
  ; qualquer hardware de extensao aqui (nao so "disco", apesar do rotulo antigo dizer isso -
  ; bug real reportado pelo usuario), um por slot fisico independente. Uma linha compacta cada
  ; (rotulo + campo + "..." lado a lado, nao empilhado como os campos acima) pra caber os 4 sem
  ; a janela ficar gigante.
  TextGadget(#PB_Any, 24, BaseY + 448, 560, 20, "Extensoes (opcional, ate 4 simultaneas - qualquer hardware, nao so disco)")
  *G\G_EmExtensionA = StringGadget(#PB_Any, 100, BaseY + 476, 436, 24, BadigCfg\EmExtensionA)
  TextGadget(#PB_Any, 24, BaseY + 480, 70, 20, "Slot A:")
  *G\G_EmExtensionABrowse = ThemedButton(544, BaseY + 476, 64, 24, "...", "")

  *G\G_EmExtensionB = StringGadget(#PB_Any, 100, BaseY + 510, 436, 24, BadigCfg\EmExtensionB)
  TextGadget(#PB_Any, 24, BaseY + 514, 70, 20, "Slot B:")
  *G\G_EmExtensionBBrowse = ThemedButton(544, BaseY + 510, 64, 24, "...", "")

  *G\G_EmExtensionC = StringGadget(#PB_Any, 100, BaseY + 544, 436, 24, BadigCfg\EmExtensionC)
  TextGadget(#PB_Any, 24, BaseY + 548, 70, 20, "Slot C:")
  *G\G_EmExtensionCBrowse = ThemedButton(544, BaseY + 544, 64, 24, "...", "")

  *G\G_EmExtensionD = StringGadget(#PB_Any, 100, BaseY + 578, 436, 24, BadigCfg\EmExtensionD)
  TextGadget(#PB_Any, 24, BaseY + 582, 70, 20, "Slot D:")
  *G\G_EmExtensionDBrowse = ThemedButton(544, BaseY + 578, 64, 24, "...", "")

  TextGadget(#PB_Any, 24, BaseY + 628, 420, 20, "Verbosidade do emulador (0-4, vazio = padrao)")
  *G\G_EmVerbose = StringGadget(#PB_Any, 24, BaseY + 656, 70, 24, "")
EndProcedure

; Preenche os gadgets criados acima com o BadigCfg atual - separado da criacao
; porque quem chama pode estar preenchendo varias paginas/gadgets de uma vez
; so depois de fechar a gadget-list (CloseGadgetList()).
Procedure BadigCfg_ApplyEmulatorDefaults(*G.BadigCfg_EmuGadgets)
  SetGadgetState(*G\G_EmRun, BadigCfg\EmRun)
  SetGadgetState(*G\G_EmMonitor, BadigCfg\EmMonitor)
  SetGadgetState(*G\G_EmNoThrottle, BadigCfg\EmNoThrottle)
  If BadigCfg\EmVerbose >= 0 : SetGadgetText(*G\G_EmVerbose, Str(BadigCfg\EmVerbose)) : EndIf
EndProcedure

; Escolhe um arquivo/maquina/extensao pro campo StringGadget *Field, usando *Browse como
; disparador - helper comum aos 7 botoes "..." desta pagina (executavel, setting, script,
; maquina, extensao A-D), evita repetir a mesma checagem de Ev 7 vezes.
Procedure.b BadigCfg_HandleEmulatorGadgetEvent(Win.i, Ev.i, *G.BadigCfg_EmuGadgets)
  If Ev = *G\G_EmulatorPathBrowse
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      Protected ExeFilter.s = "Executavel (*.exe)|*.exe|Todos os arquivos (*.*)|*.*"
    CompilerElse
      Protected ExeFilter.s = "Todos os arquivos (*.*)|*.*"
    CompilerEndIf
    Protected PickPath.s = OpenFileRequester("Selecione o executavel do openMSX",
                                             GetGadgetText(*G\G_EmulatorPath), ExeFilter, 0)
    If PickPath <> ""
      SetGadgetText(*G\G_EmulatorPath, PickPath)
    EndIf
    ProcedureReturn #True
  EndIf

  If Ev = *G\G_EmSettingBrowse
    Protected PickSetting.s = OpenFileRequester("Selecione o arquivo de configuracao (settings.xml) do openMSX",
                                                GetGadgetText(*G\G_EmSetting), "Todos os arquivos (*.*)|*.*", 0)
    If PickSetting <> ""
      SetGadgetText(*G\G_EmSetting, PickSetting)
    EndIf
    ProcedureReturn #True
  EndIf

  If Ev = *G\G_EmScriptBrowse
    Protected PickScript.s = OpenFileRequester("Selecione o script Tcl a executar no boot",
                                               GetGadgetText(*G\G_EmScript), "Scripts Tcl (*.tcl)|*.tcl|Todos os arquivos (*.*)|*.*", 0)
    If PickScript <> ""
      SetGadgetText(*G\G_EmScript, PickScript)
    EndIf
    ProcedureReturn #True
  EndIf

  If Ev = *G\G_EmMachineBrowse
    If Trim(GetGadgetText(*G\G_EmulatorPath)) = ""
      MessageRequester("Maquina", "Informe o caminho do executavel do openMSX acima primeiro.",
                       #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    Else
      Protected MachinesDir.s = BadigCfg_OpenMsxShareDir(GetGadgetText(*G\G_EmulatorPath), "machines")
      Protected PickedMachine.s = BadigCfg_PickXmlName(Win, "Selecione a maquina",
                                                       MachinesDir, GetGadgetText(*G\G_EmMachine))
      If PickedMachine <> ""
        SetGadgetText(*G\G_EmMachine, PickedMachine)
      EndIf
    EndIf
    ProcedureReturn #True
  EndIf

  ; 4 slots identicos exceto pelo StringGadget/titulo do dialogo - um bloco So(Ev = ...) por
  ; slot, mesma logica de sempre, sem mais o parsing de ":slot" (cada campo JA E' um slot).
  If Ev = *G\G_EmExtensionABrowse Or Ev = *G\G_EmExtensionBBrowse Or Ev = *G\G_EmExtensionCBrowse Or Ev = *G\G_EmExtensionDBrowse
    If Trim(GetGadgetText(*G\G_EmulatorPath)) = ""
      MessageRequester("Extensao", "Informe o caminho do executavel do openMSX acima primeiro.",
                       #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    Else
      Protected ExtField.i, ExtSlotLetter.s
      Select Ev
        Case *G\G_EmExtensionABrowse : ExtField = *G\G_EmExtensionA : ExtSlotLetter = "A"
        Case *G\G_EmExtensionBBrowse : ExtField = *G\G_EmExtensionB : ExtSlotLetter = "B"
        Case *G\G_EmExtensionCBrowse : ExtField = *G\G_EmExtensionC : ExtSlotLetter = "C"
        Case *G\G_EmExtensionDBrowse : ExtField = *G\G_EmExtensionD : ExtSlotLetter = "D"
      EndSelect
      Protected ExtensionsDir.s = BadigCfg_OpenMsxShareDir(GetGadgetText(*G\G_EmulatorPath), "extensions")
      Protected PickedExt.s = BadigCfg_PickXmlName(Win, "Selecione a extensao - Slot " + ExtSlotLetter,
                                                   ExtensionsDir, GetGadgetText(ExtField))
      If PickedExt <> ""
        SetGadgetText(ExtField, PickedExt)
      EndIf
    EndIf
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

; Le os gadgets de volta pro BadigCfg (SEM salvar - quem chama decide quando
; persistir, ja que BadigCfg_OpenSettingsWindow() ainda precisa ler as outras
; paginas antes de um unico BadigCfg_Save() final; OpenMsxCfg_OpenSettingsWindow(),
; que so tem esta pagina, salva logo em seguida).
Procedure BadigCfg_ApplyEmulatorGadgetsToConfig(*G.BadigCfg_EmuGadgets)
  BadigCfg\EmRun = GetGadgetState(*G\G_EmRun)
  BadigCfg\EmulatorPath = GetGadgetText(*G\G_EmulatorPath)
  BadigCfg\EmSetting = GetGadgetText(*G\G_EmSetting)
  BadigCfg\EmScript = GetGadgetText(*G\G_EmScript)
  BadigCfg\EmMachine = GetGadgetText(*G\G_EmMachine)
  BadigCfg\EmExtensionA = GetGadgetText(*G\G_EmExtensionA)
  BadigCfg\EmExtensionB = GetGadgetText(*G\G_EmExtensionB)
  BadigCfg\EmExtensionC = GetGadgetText(*G\G_EmExtensionC)
  BadigCfg\EmExtensionD = GetGadgetText(*G\G_EmExtensionD)
  BadigCfg\EmNoThrottle = GetGadgetState(*G\G_EmNoThrottle)
  BadigCfg\EmMonitor = GetGadgetState(*G\G_EmMonitor)
  If Trim(GetGadgetText(*G\G_EmVerbose)) = ""
    BadigCfg\EmVerbose = -1
  Else
    BadigCfg\EmVerbose = Val(GetGadgetText(*G\G_EmVerbose))
  EndIf
EndProcedure

;- ------------------------------------------------------------
;- Janela de configuracao (Configurar -> Basic Dignified...)
;- ------------------------------------------------------------

; OverridePath (opcional): "" = comportamento normal (le/grava o BadigCfg
; global, ja carregado pelo chamador antes de abrir esta janela). Quando
; nao vazio, carrega esse arquivo por-projeto pro MESMO Global BadigCfg
; antes de desenhar os campos (a janela em si nao muda nada) e o botao
; Salvar grava de volta nesse mesmo arquivo - quem chama com OverridePath
; <> "" e responsavel por salvar/restaurar o BadigCfg global antes/depois
; (ver ProjectSettingsGui.pbi), ja que essa struct e temporariamente usada
; como "rascunho" pra esta janela.
Procedure BadigCfg_OpenSettingsWindow(ParentWindow, OverridePath.s = "")
  If OverridePath <> ""
    BadigCfg_Load(OverridePath)
  EndIf

  ; Mesma grade de layout de EditorCfg_OpenSettingsWindow() (EditorSettings.pbi):
  ; 24px de margem externa, 24px de altura de campo, 8px entre um rotulo e o
  ; campo logo abaixo dele, ~26-30px entre grupos distintos.
  Protected WinW = 680, WinH = 804 ; +60 vs. antes - a pagina "Emulador" cresceu (4 slots de extensao)
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Configuracoes do Basic Dignified",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #True, #False)
  If Not Win
    ProcedureReturn
  EndIf

  Protected Panel = PanelGadget(#PB_Any, 24, 24, WinW - 48, 700)

  ;- Pagina 1: Basic Dignified ------------------------------------------------
  AddGadgetItem(Panel, -1, "Basic Dignified")

  TextGadget(#PB_Any, 24, 24, 160, 20, "Linha inicial")
  TextGadget(#PB_Any, 234, 24, 160, 20, "Passo de linha")
  TextGadget(#PB_Any, 444, 24, 160, 20, "Tamanho do TAB")
  Protected G_LineStart = StringGadget(#PB_Any, 24, 52, 90, 24, Str(BadigCfg\LineStart))
  Protected G_LineStep = StringGadget(#PB_Any, 234, 52, 90, 24, Str(BadigCfg\LineStep))
  Protected G_TabLenght = StringGadget(#PB_Any, 444, 52, 90, 24, Str(BadigCfg\TabLenght))

  TextGadget(#PB_Any, 24, 102, 200, 20, "Verbosidade (0-4)")
  Protected G_VerboseLevel = StringGadget(#PB_Any, 24, 130, 90, 24, Str(BadigCfg\VerboseLevel))

  ; Nota: coordenadas de gadgets criados dentro de um PanelGadget sao
  ; relativas a LARGURA DO PANEL (632px, WinW - 48), nao a largura da janela -
  ; a borda direita utilizavel e portanto 632 - 24 (margem direita) = 608, nao
  ; WinW - 24. Bug real encontrado por screenshot nesta sessao: uma primeira
  ; passada desta grade usava a margem da JANELA para a coluna direita e para
  ; os botoes "...", cortando texto/botoes pela borda do panel.
  TextGadget(#PB_Any, 24, 184, 300, 20, "Opcoes gerais")
  Protected G_RemHeader = CheckBoxGadget(#PB_Any, 24, 212, 280, 22, "Incluir cabecalho REM")
  Protected G_StripSpaces = CheckBoxGadget(#PB_Any, 328, 212, 280, 22, "Remover todos os espacos")
  Protected G_CapitalizeAll = CheckBoxGadget(#PB_Any, 24, 242, 280, 22, "Converter tudo para maiusculas")
  Protected G_Translate = CheckBoxGadget(#PB_Any, 328, 242, 280, 40, "Traduzir caracteres Unicode especiais para nativos MSX")

  TextGadget(#PB_Any, 24, 312, 320, 20, "Relatorios (salvar/exibir)")
  Protected G_PrintReport = CheckBoxGadget(#PB_Any, 24, 340, 280, 22, "Exibir relatorios em vez de salvar")
  Protected G_LabelReport = CheckBoxGadget(#PB_Any, 328, 340, 280, 22, "Rotulos como REM no codigo convertido")
  Protected G_LineReport = CheckBoxGadget(#PB_Any, 24, 370, 280, 22, "Correspondencia de linhas")
  Protected G_VarReport = CheckBoxGadget(#PB_Any, 328, 370, 280, 22, "Substituicao de variaveis")
  Protected G_LexerReport = CheckBoxGadget(#PB_Any, 24, 400, 280, 22, "Saida do lexer (tokens)")
  Protected G_ParserReport = CheckBoxGadget(#PB_Any, 328, 400, 280, 22, "Saida do parser (tokens)")

  TextGadget(#PB_Any, 24, 452, 500, 20, "Diretorio de instalacao do Basic Dignified Suite")
  Protected G_InstallDir = StringGadget(#PB_Any, 24, 480, 512, 24, BadigCfg\InstallDir)
  Protected G_InstallDirBrowse = ThemedButton(544, 480, 64, 24, "...", "")

  Protected G_DownloadSuite = ThemedButton(24, 520, 280, 28, "Baixar Basic Dignified Suite...", "")
  TextGadget(#PB_Any, 328, 520, 280, 40, "Clona com Git ou baixa um .zip do GitHub e descompacta no diretorio acima.")
  TextGadget(#PB_Any, 24, 576, 584, 40,
    "Opcional: o editor ja tem pre-processador e tokenizador nativos (menu Arquivo), nao precisa " +
    "deste diretorio pra funcionar. So baixe/instale se quiser rodar o Basic Dignified Suite " +
    "original em Python separadamente.")

  ;- Pagina 2: MSX -------------------------------------------------------------
  AddGadgetItem(Panel, -1, "MSX")

  TextGadget(#PB_Any, 24, 24, 200, 20, "Converter ? / PRINT")
  Protected G_ConvertPrint = ComboBoxGadget(#PB_Any, 24, 52, 260, 24)
  AddGadgetItem(G_ConvertPrint, -1, "Nao converter")
  AddGadgetItem(G_ConvertPrint, -1, "? -> PRINT")
  AddGadgetItem(G_ConvertPrint, -1, "PRINT -> ?")

  TextGadget(#PB_Any, 24, 106, 260, 20, "Remover THEN/ELSE ou GOTO")
  Protected G_StripThenGoto = ComboBoxGadget(#PB_Any, 24, 134, 300, 24)
  AddGadgetItem(G_StripThenGoto, -1, "Nao remover")
  AddGadgetItem(G_StripThenGoto, -1, "THEN/ELSE (apos IF)")
  AddGadgetItem(G_StripThenGoto, -1, "GOTO (apos THEN/ELSE)")

  TextGadget(#PB_Any, 24, 188, 300, 20, "Tokenizador (msxbatoken)")
  Protected G_TkList = CheckBoxGadget(#PB_Any, 24, 216, 280, 22, "Gerar arquivo de listagem")
  TextGadget(#PB_Any, 320, 218, 110, 20, "Colunas (1-32)")
  Protected G_TkListWidth = StringGadget(#PB_Any, 440, 214, 60, 24, Str(BadigCfg\TkListWidth))

  Protected G_TkDelAscii = CheckBoxGadget(#PB_Any, 24, 270, 340, 22, "Apagar o ASCII apos tokenizar")

  TextGadget(#PB_Any, 24, 322, 420, 20, "Verbosidade do tokenizador (0-5, vazio = padrao)")
  Protected G_TkVerbose = StringGadget(#PB_Any, 24, 350, 70, 24, "")
  If BadigCfg\TkVerbose >= 0 : SetGadgetText(G_TkVerbose, Str(BadigCfg\TkVerbose)) : EndIf

  ;- Pagina 3: Emulador --------------------------------------------------------
  AddGadgetItem(Panel, -1, "Emulador")

  Protected EmuG.BadigCfg_EmuGadgets
  BadigCfg_CreateEmulatorGadgets(0, @EmuG)

  CloseGadgetList()

  ;- Preenche os valores atuais -------------------------------------------------
  SetGadgetState(G_RemHeader, BadigCfg\RemHeader)
  SetGadgetState(G_StripSpaces, BadigCfg\StripSpaces)
  SetGadgetState(G_CapitalizeAll, BadigCfg\CapitalizeAll)
  SetGadgetState(G_Translate, BadigCfg\Translate)
  SetGadgetState(G_PrintReport, BadigCfg\PrintReport)
  SetGadgetState(G_LabelReport, BadigCfg\LabelReport)
  SetGadgetState(G_LineReport, BadigCfg\LineReport)
  SetGadgetState(G_VarReport, BadigCfg\VarReport)
  SetGadgetState(G_LexerReport, BadigCfg\LexerReport)
  SetGadgetState(G_ParserReport, BadigCfg\ParserReport)

  ; ConvertPrint guarda a forma FINAL desejada ("?" ou "P"), nao qual token
  ; esta sendo substituido - por isso o mapeamento e invertido em relacao ao
  ; rotulo do combo (item 1 "? -> PRINT" produz forma final "P", e vice-versa).
  Select BadigCfg\ConvertPrint
    Case "?" : SetGadgetState(G_ConvertPrint, 2)
    Case "P" : SetGadgetState(G_ConvertPrint, 1)
    Default  : SetGadgetState(G_ConvertPrint, 0)
  EndSelect

  Select BadigCfg\StripThenGoto
    Case "T" : SetGadgetState(G_StripThenGoto, 1)
    Case "G" : SetGadgetState(G_StripThenGoto, 2)
    Default  : SetGadgetState(G_StripThenGoto, 0)
  EndSelect

  SetGadgetState(G_TkList, BadigCfg\TkList)
  SetGadgetState(G_TkDelAscii, BadigCfg\TkDelAscii)

  BadigCfg_ApplyEmulatorDefaults(@EmuG)

  Protected G_Save = ThemedButton(WinW - 256, WinH - 56, 110, 32, "Salvar", Chr(#Icon_Save))
  GadgetToolTip(G_Save, "Salvar")
  Protected G_Cancel = ThemedButton(WinW - 134, WinH - 56, 110, 32, "Cancelar", "")

  Protected Event, Quit = #False, Saved = #False

  Repeat
    Event = WaitWindowEvent()

    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_InstallDirBrowse
            Protected PickInstallDir.s = PathRequester("Selecione o diretorio de instalacao do Basic Dignified Suite",
                                                        GetGadgetText(G_InstallDir))
            If PickInstallDir <> ""
              SetGadgetText(G_InstallDir, PickInstallDir)
            EndIf

          Case G_DownloadSuite
            BadigCfg_DownloadSuite(Win, GetGadgetText(G_InstallDir))

          Case G_Save
            Saved = #True
            Quit = #True

          Case G_Cancel
            Quit = #True

          Default
            ; Qualquer um dos 7 botoes "..." da pagina "Emulador" (executavel, setting, script,
            ; maquina, extensao A-D) - BadigCfg_HandleEmulatorGadgetEvent() checa Ev contra cada
            ; um e no-opa (devolve #False) se nao for nenhum deles, entao listar os IDs aqui um
            ; por um (como antes) so criava mais um lugar pra esquecer de atualizar ao adicionar
            ; um campo novo - ja aconteceu uma vez (Setting nunca virou "-setting" de verdade).
            BadigCfg_HandleEmulatorGadgetEvent(Win, EventGadget(), @EmuG)
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  If Saved
    Protected InstallDirText.s = GetGadgetText(G_InstallDir)
    If Right(InstallDirText, 1) = "\" Or Right(InstallDirText, 1) = "/"
      InstallDirText = Left(InstallDirText, Len(InstallDirText) - 1)
    EndIf
    BadigCfg\InstallDir = InstallDirText

    BadigCfg\LineStart = Val(GetGadgetText(G_LineStart))
    BadigCfg\LineStep = Val(GetGadgetText(G_LineStep))
    BadigCfg\TabLenght = Val(GetGadgetText(G_TabLenght))
    BadigCfg\VerboseLevel = Val(GetGadgetText(G_VerboseLevel))
    BadigCfg\RemHeader = GetGadgetState(G_RemHeader)
    BadigCfg\StripSpaces = GetGadgetState(G_StripSpaces)
    BadigCfg\CapitalizeAll = GetGadgetState(G_CapitalizeAll)
    BadigCfg\Translate = GetGadgetState(G_Translate)
    BadigCfg\PrintReport = GetGadgetState(G_PrintReport)
    BadigCfg\LabelReport = GetGadgetState(G_LabelReport)
    BadigCfg\LineReport = GetGadgetState(G_LineReport)
    BadigCfg\VarReport = GetGadgetState(G_VarReport)
    BadigCfg\LexerReport = GetGadgetState(G_LexerReport)
    BadigCfg\ParserReport = GetGadgetState(G_ParserReport)

    ; item 1 = "? -> PRINT" (forma final PRINT); item 2 = "PRINT -> ?" (forma final ?)
    Select GetGadgetState(G_ConvertPrint)
      Case 1 : BadigCfg\ConvertPrint = "P"
      Case 2 : BadigCfg\ConvertPrint = "?"
      Default : BadigCfg\ConvertPrint = ""
    EndSelect

    Select GetGadgetState(G_StripThenGoto)
      Case 1 : BadigCfg\StripThenGoto = "T"
      Case 2 : BadigCfg\StripThenGoto = "G"
      Default : BadigCfg\StripThenGoto = ""
    EndSelect

    BadigCfg\TkList = GetGadgetState(G_TkList)
    BadigCfg\TkListWidth = Val(GetGadgetText(G_TkListWidth))
    BadigCfg\TkDelAscii = GetGadgetState(G_TkDelAscii)
    If Trim(GetGadgetText(G_TkVerbose)) = ""
      BadigCfg\TkVerbose = -1
    Else
      BadigCfg\TkVerbose = Val(GetGadgetText(G_TkVerbose))
    EndIf

    BadigCfg_ApplyEmulatorGadgetsToConfig(@EmuG)

    BadigCfg_Save(OverridePath)
    If OverridePath = ""
      BadigCfg_SyncEmulatorIni() ; so faz sentido pro emulador "de verdade" da maquina, nao pra um override de projeto
    EndIf
  EndIf

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
