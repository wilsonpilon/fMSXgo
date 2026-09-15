;
; ------------------------------------------------------------
;  Suporte ao MSXBAS2ROM (github.com/amaurycarvalho/msxbas2rom): template de
;  arquivo novo (.bas classico, formato que o compilador espera - MSX-BASIC
;  tradicional numerado, sem Dignified), tela "Configurar -> MSXBas2Rom..."
;  que baixa o binario mais recente (Windows/Linux conforme o SO) e gera o
;  conteudo de "Ajuda -> MSXBas2Rom..." a partir de "-h" e das paginas reais
;  da wiki do projeto.
;
;  Nota: "msxbas2rom -D"/"--doc" NAO despeja documentacao - so imprime um
;  ponteiro pra wiki (confirmado rodando o binario). A wiki de verdade e bem
;  mais rica e e buscavel direto via raw.githubusercontent.com/wiki/<owner>/
;  <repo>/<Pagina>.md - e dai que vem o conteudo de Ajuda, nao do "-doc".
; ------------------------------------------------------------
;

;- ------------------------------------------------------------
;- Template do arquivo novo (Arquivo -> Novo MSXBas2Rom...)
;- ------------------------------------------------------------

Procedure.s MsxBas2RomTemplateText()
  Protected Text.s = ""
  Text + "10 REM ------------------------------------------------------------" + #CRLF$
  Text + "20 REM  Projeto MSXBAS2ROM" + #CRLF$
  Text + "30 REM  Compile com: msxbas2rom NOMEDOARQUIVO.BAS" + #CRLF$
  Text + "40 REM  https://github.com/amaurycarvalho/msxbas2rom" + #CRLF$
  Text + "50 REM ------------------------------------------------------------" + #CRLF$
  Text + "60 SCREEN 0" + #CRLF$
  Text + "70 PRINT " + Chr(34) + "HELLO, MSX!" + Chr(34) + #CRLF$
  Text + "80 END" + #CRLF$
  ProcedureReturn Text
EndProcedure

;- ------------------------------------------------------------
;- Configuracoes / persistencia (mesmo padrao de EditorCfg_FilePath() em
;- EditorSettings.pbi - JSON simples ao lado do .exe)
;- ------------------------------------------------------------

; Opcoes de linha de comando do msxbas2rom.exe (ver "-h"/tools/msxbas2rom/help/cli-help.md)
; que o usuario pode configurar em "Configurar -> MSXBas2Rom..." e "Configurar ->
; Projeto..." (mesma tela, so muda pra onde le/grava - ver OverridePath). Os 4
; flags puramente informativos (-h/-D/-H/-v, mostram texto e saem sem
; compilar nada) NAO entram aqui como toggle persistente - virariam um jeito
; facil do usuario "esquecer ligado" e o botao Compilar parar de gerar ROM;
; em vez disso sao 4 botoes de acao unica na tela (rodam so aquele flag e
; mostram o resultado, sem afetar nenhuma configuracao salva).
Structure MsxBas2RomSettings
  ExePath.s
  Version.s
  OptQuiet.b            ; -q
  OptDebug.b            ; -d
  CompileMode.s         ; "" (-c, ROM simples, padrao) / "a" / "x" / "6" / "7" / "4" / "k"
  InputPath.s           ; -i (vazio = usa o caminho do .bas gerado, comportamento atual)
  OutputPath.s          ; -o (vazio = ao lado do .bas, comportamento atual)
  SymbolFormat.s        ; "" (nao gerar) / "noi" (-s, padrao) / "cdb" / "symbol" / "omds"
  OptWriteLineNumbers.b ; --lin
  OptVSCodeInit.b       ; --vscode
EndStructure
Global MsxBas2RomCfg.MsxBas2RomSettings

Procedure.s MsxBas2Rom_ToolDir()
  ProcedureReturn GetPathPart(ProgramFilename()) + "editor\tools\msxbas2rom\"
EndProcedure

Procedure.s MsxBas2Rom_HelpDir()
  ProcedureReturn MsxBas2Rom_ToolDir() + "help\"
EndProcedure

Procedure.s MsxBas2Rom_DemoDir()
  ProcedureReturn MsxBas2Rom_ToolDir() + "demo\"
EndProcedure

Procedure.s MsxBas2Rom_GamesDir()
  ProcedureReturn MsxBas2Rom_ToolDir() + "games\"
EndProcedure

; OverridePath (opcional): ver comentario equivalente de BadigCfg_FilePath()
; (BadigSettings.pbi) - "" = caminho global de sempre, senao usa esse
; caminho direto (config por-projeto, "Configurar -> Projeto...").
Procedure.s MsxBas2RomCfg_FilePath(OverridePath.s = "")
  If OverridePath <> ""
    ProcedureReturn OverridePath
  EndIf
  ProcedureReturn GetPathPart(ProgramFilename()) + "editor\msxbas2rom_settings.json"
EndProcedure

Procedure MsxBas2RomCfg_Load(OverridePath.s = "")
  MsxBas2RomCfg\ExePath = ""
  MsxBas2RomCfg\Version = ""
  MsxBas2RomCfg\OptQuiet = #False
  MsxBas2RomCfg\OptDebug = #False
  MsxBas2RomCfg\CompileMode = ""
  MsxBas2RomCfg\InputPath = ""
  MsxBas2RomCfg\OutputPath = ""
  MsxBas2RomCfg\SymbolFormat = ""
  MsxBas2RomCfg\OptWriteLineNumbers = #False
  MsxBas2RomCfg\OptVSCodeInit = #False

  Protected FilePath.s = MsxBas2RomCfg_FilePath(OverridePath)
  If FileSize(FilePath) <= 0
    ProcedureReturn
  EndIf

  Protected Json = LoadJSON(#PB_Any, FilePath)
  If Not Json
    ProcedureReturn
  EndIf

  Protected Root = JSONValue(Json)
  Protected M
  M = GetJSONMember(Root, "ExePath")            : If M : MsxBas2RomCfg\ExePath            = GetJSONString(M)  : EndIf
  M = GetJSONMember(Root, "Version")            : If M : MsxBas2RomCfg\Version            = GetJSONString(M)  : EndIf
  M = GetJSONMember(Root, "OptQuiet")           : If M : MsxBas2RomCfg\OptQuiet           = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "OptDebug")           : If M : MsxBas2RomCfg\OptDebug           = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "CompileMode")        : If M : MsxBas2RomCfg\CompileMode        = GetJSONString(M)  : EndIf
  M = GetJSONMember(Root, "InputPath")          : If M : MsxBas2RomCfg\InputPath          = GetJSONString(M)  : EndIf
  M = GetJSONMember(Root, "OutputPath")         : If M : MsxBas2RomCfg\OutputPath         = GetJSONString(M)  : EndIf
  M = GetJSONMember(Root, "SymbolFormat")       : If M : MsxBas2RomCfg\SymbolFormat       = GetJSONString(M)  : EndIf
  M = GetJSONMember(Root, "OptWriteLineNumbers"): If M : MsxBas2RomCfg\OptWriteLineNumbers = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "OptVSCodeInit")      : If M : MsxBas2RomCfg\OptVSCodeInit      = GetJSONBoolean(M) : EndIf
  FreeJSON(Json)
EndProcedure

Procedure MsxBas2RomCfg_Save(OverridePath.s = "")
  Protected Json = CreateJSON(#PB_Any)
  Protected Root = SetJSONObject(JSONValue(Json))
  SetJSONString(AddJSONMember(Root, "ExePath"), MsxBas2RomCfg\ExePath)
  SetJSONString(AddJSONMember(Root, "Version"), MsxBas2RomCfg\Version)
  SetJSONBoolean(AddJSONMember(Root, "OptQuiet"), MsxBas2RomCfg\OptQuiet)
  SetJSONBoolean(AddJSONMember(Root, "OptDebug"), MsxBas2RomCfg\OptDebug)
  SetJSONString(AddJSONMember(Root, "CompileMode"), MsxBas2RomCfg\CompileMode)
  SetJSONString(AddJSONMember(Root, "InputPath"), MsxBas2RomCfg\InputPath)
  SetJSONString(AddJSONMember(Root, "OutputPath"), MsxBas2RomCfg\OutputPath)
  SetJSONString(AddJSONMember(Root, "SymbolFormat"), MsxBas2RomCfg\SymbolFormat)
  SetJSONBoolean(AddJSONMember(Root, "OptWriteLineNumbers"), MsxBas2RomCfg\OptWriteLineNumbers)
  SetJSONBoolean(AddJSONMember(Root, "OptVSCodeInit"), MsxBas2RomCfg\OptVSCodeInit)
  SaveJSON(Json, MsxBas2RomCfg_FilePath(OverridePath), #PB_JSON_PrettyPrint)
  FreeJSON(Json)
EndProcedure

;- ------------------------------------------------------------
;- Compilacao para ROM (Executar -> Compilar ROM (MSXBas2Rom)...)
;- ------------------------------------------------------------

; Roda o msxbas2rom.exe configurado contra BasPath (.bas ja em ASCII
; classico, ver CompileMsxBas2RomFromActiveTab em BadigEditor.pb) pra gerar
; o .rom - mesmo nome base, ao lado do .bas (convencao do proprio
; compilador, "Generates <filename.rom>", ver compiling-code.md). Reaproveita
; o mesmo padrao de captura de saida de ExtTool_RunCaptureOutput
; (ExternalToolDownload.pbi), mas TAMBEM checa ProgramExitCode() - o
; msxbas2rom nao tem uma convencao clara de sucesso/erro so pelo texto do
; stdout, exit code e o unico sinal confiavel (mesmo idioma de RunProgram +
; ProgramExitCode + MessageRequester ja usado em BadigCfg_DownloadViaGit
; pro "git clone", unico outro precedente no projeto de checar exit code de
; processo externo). Mostra o resultado direto num MessageRequester (acao
; unica, sem StatusGadget - diferente dos downloads, que ficam numa janela
; aberta o tempo todo).
; Monta a linha de argumentos a partir de MsxBas2RomCfg (ver "Configurar ->
; MSXBas2Rom.../Configurar -> Projeto..." - mesma struct, so muda pra onde
; le/grava). Ordem das secoes segue "msxbas2rom -h": gerais, modo de
; compilacao (mutuamente exclusivos - so um -c/-a/-x/-6/-7/-4/-k), caminhos,
; especiais. "" (CompileMode/SymbolFormat) = comportamento padrao do proprio
; compilador, nao precisa passar flag nenhuma.
Procedure.s MsxBas2Rom_BuildCliArgs(BasPath.s)
  Protected Args.s = ""

  If MsxBas2RomCfg\OptQuiet : Args + "-q " : EndIf
  If MsxBas2RomCfg\OptDebug : Args + "-d " : EndIf

  Select MsxBas2RomCfg\CompileMode
    Case "a" : Args + "-a "
    Case "x" : Args + "-x "
    Case "6" : Args + "-6 "
    Case "7" : Args + "-7 "
    Case "4" : Args + "-4 "
    Case "k" : Args + "-k "
  EndSelect

  If MsxBas2RomCfg\InputPath <> ""
    Args + "-i " + Chr(34) + MsxBas2RomCfg\InputPath + Chr(34) + " "
  EndIf
  If MsxBas2RomCfg\OutputPath <> ""
    Args + "-o " + Chr(34) + MsxBas2RomCfg\OutputPath + Chr(34) + " "
  EndIf

  Select MsxBas2RomCfg\SymbolFormat
    Case "noi"    : Args + "-s "
    Case "cdb"    : Args + "--cdb "
    Case "symbol" : Args + "--symbol "
    Case "omds"   : Args + "--omds "
  EndSelect
  If MsxBas2RomCfg\OptWriteLineNumbers : Args + "--lin " : EndIf
  If MsxBas2RomCfg\OptVSCodeInit : Args + "--vscode " : EndIf

  Args + Chr(34) + BasPath + Chr(34)
  ProcedureReturn Args
EndProcedure

; Caminho esperado do .rom apos compilar BasPath, considerando o override
; -o (Configurar -> MSXBas2Rom...) - "" = comportamento padrao do
; compilador (ao lado do .bas). -o e tratado como PASTA (nao arquivo,
; "output path" - mesmo espirito de "-i = input path"), entao sempre monta
; o nome do .rom dentro dela.
Procedure.s MsxBas2Rom_ExpectedRomPath(BasPath.s)
  If MsxBas2RomCfg\OutputPath = ""
    ProcedureReturn GetPathPart(BasPath) + GetFilePart(BasPath, #PB_FileSystem_NoExtension) + ".rom"
  EndIf

  Protected OutDir.s = MsxBas2RomCfg\OutputPath
  If Right(OutDir, 1) <> "\" And Right(OutDir, 1) <> "/"
    OutDir + "\"
  EndIf
  ProcedureReturn OutDir + GetFilePart(BasPath, #PB_FileSystem_NoExtension) + ".rom"
EndProcedure

Procedure.b MsxBas2Rom_CompileToRom(BasPath.s)
  Protected Prog = RunProgram(MsxBas2RomCfg\ExePath, MsxBas2Rom_BuildCliArgs(BasPath), GetPathPart(BasPath),
                               #PB_Program_Open | #PB_Program_Read | #PB_Program_Error | #PB_Program_Hide)
  If Not Prog
    MessageRequester("Compilar ROM (MSXBas2Rom)",
                     "Nao foi possivel iniciar o msxbas2rom.exe:" + Chr(10) + MsxBas2RomCfg\ExePath,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  Protected Output.s = "", Line.s
  While ProgramRunning(Prog)
    If AvailableProgramOutput(Prog)
      Output + ReadProgramString(Prog) + #CRLF$
    EndIf
    Line = ReadProgramError(Prog)
    If Line <> ""
      Output + Line + #CRLF$
    EndIf
  Wend
  While AvailableProgramOutput(Prog)
    Output + ReadProgramString(Prog) + #CRLF$
  Wend
  Repeat
    Line = ReadProgramError(Prog)
    If Line = "" : Break : EndIf
    Output + Line + #CRLF$
  ForEver

  Protected ExitCode = ProgramExitCode(Prog)
  CloseProgram(Prog)

  Protected RomPath.s = MsxBas2Rom_ExpectedRomPath(BasPath)
  If ExitCode = 0 And FileSize(RomPath) > 0
    MessageRequester("Compilar ROM (MSXBas2Rom)",
                     "ROM gerada com sucesso:" + Chr(10) + RomPath,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
    ProcedureReturn #True
  Else
    MessageRequester("Erro ao compilar",
                     "msxbas2rom.exe terminou com codigo " + Str(ExitCode) + "." + Chr(10) + Chr(10) + Output,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf
EndProcedure

;- ------------------------------------------------------------
;- Download (Configurar -> MSXBas2Rom -> Baixar versao mais recente)
;- ------------------------------------------------------------

; Acha o asset .zip da release mais recente pro SO atual via GET
; releases/latest (um unico release, sem precisar varrer historico - ao
; contrario do N80/LK80/LB80, ver N80Support.pbi). *OutVersion recebe o
; "tag_name" da release (ex.: "v1.2.1.0").
Procedure.s MsxBas2Rom_ResolveAssetUrl(*OutVersion.String)
  *OutVersion\s = ""
  Protected JsonText.s = ExtTool_HttpGetText("https://api.github.com/repos/amaurycarvalho/msxbas2rom/releases/latest")
  If JsonText = ""
    ProcedureReturn ""
  EndIf

  Protected JsonHandle = ParseJSON(#PB_Any, JsonText)
  If Not JsonHandle
    ProcedureReturn ""
  EndIf

  Protected Root = JSONValue(JsonHandle)
  Protected M = GetJSONMember(Root, "tag_name")
  If M : *OutVersion\s = GetJSONString(M) : EndIf

  Protected OsTag.s
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    OsTag = "-windows-x64-bin.zip"
  CompilerElse
    OsTag = "-linux-x64-bin.zip"
  CompilerEndIf

  Protected Result.s = ""
  Protected AssetsElem = GetJSONMember(Root, "assets")
  If AssetsElem
    Protected N = JSONArraySize(AssetsElem)
    Protected Idx, Item, NameM, UrlM
    For Idx = 0 To N - 1
      Item = GetJSONElement(AssetsElem, Idx)
      If Item
        NameM = GetJSONMember(Item, "name")
        If NameM And FindString(GetJSONString(NameM), OsTag) > 0
          UrlM = GetJSONMember(Item, "browser_download_url")
          If UrlM
            Result = GetJSONString(UrlM)
            Break
          EndIf
        EndIf
      EndIf
    Next
  EndIf

  FreeJSON(JsonHandle)
  ProcedureReturn Result
EndProcedure

Procedure.s MsxBas2Rom_FindExe()
  Protected Dir.s = MsxBas2Rom_ToolDir()
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    If FileSize(Dir + "msxbas2rom.exe") > 0 : ProcedureReturn Dir + "msxbas2rom.exe" : EndIf
  CompilerElse
    If FileSize(Dir + "msxbas2rom") > 0 : ProcedureReturn Dir + "msxbas2rom" : EndIf
  CompilerEndIf
  ProcedureReturn ""
EndProcedure

; Paginas da wiki oficial (raw.githubusercontent.com/wiki/.../<Pagina>.md,
; nome EXATO do arquivo real na wiki - case-sensitive) organizadas nos mesmos
; grupos/ordem da wiki de verdade: a pagina Home.md tem uma tabela "Quick
; Reference" (Instalacao/Primeiros passos/Uso/Guia de referencia/Exemplos/...)
; e a pagina Documentation.md e o hub "Reference Guide" que lista as 12
; sub-paginas de referencia (confirmado clonando amaurycarvalho/msxbas2rom.
; wiki.git e lendo Home.md/Documentation.md direto, 2026-08-09). Games/
; Contributing/Branding ficam de fora de proposito - sao paginas da
; comunidade/creditos do projeto msxbas2rom, nao guia de uso do dialeto (o
; usuario pediu especificamente "guia de referencia pratico pra quem quer
; usar este dialeto"). "cli-help.md" (gerado a partir de "-h", nao baixado)
; entra como topico extra em MsxBas2Rom_UpdateDocumentation, nao aqui.
DataSection
  MsxBas2Rom_WikiPages:
  Data.s "Home",               "Visao geral do projeto",           "Primeiros passos"
  Data.s "Install",            "Instalacao",                       "Primeiros passos"
  Data.s "Gettingstarted",     "Primeiros passos",                 "Primeiros passos"
  Data.s "Usage",              "Uso e opcoes de linha de comando",  "Primeiros passos"
  Data.s "Documentation",      "Visao geral da referencia",        "Guia de referencia"
  Data.s "Compiling-Code",     "Limitacoes e diferencas ao compilar", "Guia de referencia"
  Data.s "Resource-Directives", "Diretivas de recursos (assets)",  "Guia de referencia"
  Data.s "Extended-Commands",  "Comandos estendidos",              "Guia de referencia"
  Data.s "Extended-Functions", "Funcoes estendidas",                "Guia de referencia"
  Data.s "Music-Support",      "Musica (Arkos Tracker)",           "Guia de referencia"
  Data.s "MTF-Support",        "Mapas de tela (MSX Tile Forge)",   "Guia de referencia"
  Data.s "nMT-Support",        "Mapas de tela (nMSXTiles)",        "Guia de referencia"
  Data.s "TS-Support",         "Sprites (Tiny Sprite)",            "Guia de referencia"
  Data.s "VSCode_integration", "Integracao com VSCode",            "Guia de referencia"
  Data.s "msxbas2rom_vscode_manual_setup", "VSCode - configuracao manual", "Guia de referencia"
  Data.s "Debugging_with_OpenMSX", "Depuracao com o openMSX",      "Guia de referencia"
  Data.s "Compiler-Architecture", "Arquitetura do compilador",     "Guia de referencia"
  Data.s "Getting-Help",       "Como obter ajuda",                 "Guia de referencia"
  Data.s "Examples",           "Exemplos prontos",                 "Exemplos"
  Data.s "@@END@@", "", ""
EndDataSection

; Baixa so o executavel (release mais atual do GitHub) e salva as
; configuracoes. StatusGadget (pode ser 0) recebe feedback textual a cada
; passo, ja que tudo aqui e bloqueante (ExtTool_SetStatus cuida de bombear a
; fila de eventos pra o texto aparecer antes do proximo passo travar a UI de
; novo). Geracao da Ajuda (wiki/"-h") fica em MsxBas2Rom_UpdateDocumentation(),
; acionada pelo botao separado "Atualizar documentacao".
Procedure.b MsxBas2Rom_DownloadExe(StatusGadget)
  ExtTool_SetStatus(StatusGadget, "Consultando release mais recente no GitHub...")
  Protected Version.String
  Protected AssetUrl.s = MsxBas2Rom_ResolveAssetUrl(@Version)
  If AssetUrl = ""
    ExtTool_SetStatus(StatusGadget, "Falha ao consultar o GitHub (verifique sua conexao).")
    ProcedureReturn #False
  EndIf

  Protected ToolDir.s = MsxBas2Rom_ToolDir()
  ExtTool_SetStatus(StatusGadget, "Baixando " + Version\s + "...")
  If Not ExtTool_DownloadAndExtractZip(AssetUrl, ToolDir)
    ExtTool_SetStatus(StatusGadget, "Falha ao baixar/descompactar o pacote.")
    ProcedureReturn #False
  EndIf

  Protected ExePath.s = MsxBas2Rom_FindExe()
  If ExePath = ""
    ExtTool_SetStatus(StatusGadget, "Pacote baixado, mas o executavel nao foi encontrado.")
    ProcedureReturn #False
  EndIf

  MsxBas2RomCfg\ExePath = ExePath
  MsxBas2RomCfg\Version = Version\s
  MsxBas2RomCfg_Save()

  ExtTool_SetStatus(StatusGadget, "Concluido: " + Version\s + " instalado em " + ToolDir)
  ProcedureReturn #True
EndProcedure

; A janela de Ajuda (GenMdHelp_OpenWindow) abre qualquer link "[texto](url)"
; passando a URL crua pra explorer.exe/xdg-open (GenMdHelp_OpenUrl) - links
; RELATIVOS da wiki (ex.: "[Instalacao](Install)", forma normal de link
; interno entre paginas de uma wiki do GitHub) tentariam abrir um arquivo
; chamado "Install" no diretorio de trabalho, nao a pagina. Reescreve pra URL
; absoluta da wiki de verdade antes de salvar em disco, assim o link funciona
; (abre no navegador) mesmo pra paginas que este topico NAO baixou (ex.: um
; link pra "Games"/"Contributing", deixados de fora de proposito - ver
; MsxBas2Rom_WikiPages). So toca em "](...)" cuja URL nao tem "://" (ja
; absoluta) nem comeca com "#" (ancora dentro da mesma pagina, sem
; equivalente aqui por nao haver ancoras reais no renderer).
Procedure.s MsxBas2Rom_RewriteWikiLinks(Markdown.s)
  Protected Result.s = ""
  Protected Pos = 1
  Protected SearchPos, UrlStart, UrlEnd
  Protected Url.s
  Repeat
    SearchPos = FindString(Markdown, "](", Pos)
    If SearchPos = 0
      Result + Mid(Markdown, Pos)
      Break
    EndIf
    UrlStart = SearchPos + 2
    UrlEnd = FindString(Markdown, ")", UrlStart)
    If UrlEnd = 0
      Result + Mid(Markdown, Pos)
      Break
    EndIf
    Url = Mid(Markdown, UrlStart, UrlEnd - UrlStart)
    Result + Mid(Markdown, Pos, UrlStart - Pos) ; tudo antes da URL, incluindo "]("
    If FindString(Url, "://") = 0 And Left(Url, 1) <> "#"
      Url = "https://github.com/amaurycarvalho/msxbas2rom/wiki/" + Url
    EndIf
    Result + Url + ")"
    Pos = UrlEnd + 1
  ForEver
  ProcedureReturn Result
EndProcedure

; Botao "Atualizar documentacao": roda "-h" do executavel configurado (se
; houver) e baixa as paginas de MsxBas2Rom_WikiPages, montando a mesma
; estrutura de pasta+_index.json que GenMdHelp_OpenWindow() (Ajuda ->
; MSXBas2Rom...) espera - mesmo padrao de MsxBas2Rom_DownloadExe() (bloqueante,
; ExtTool_SetStatus a cada passo). Pode ser chamado de novo no futuro pra
; re-sincronizar com a wiki sem precisar de uma nova versao do .exe.
Procedure.b MsxBas2Rom_UpdateDocumentation(StatusGadget)
  Protected HelpDir.s = MsxBas2Rom_HelpDir()
  ExtTool_CreateDirectoryRecursive(HelpDir)
  NewList Topics.GenMdHelp_TopicItem()

  If MsxBas2RomCfg\ExePath <> "" And FileSize(MsxBas2RomCfg\ExePath) > 0
    ExtTool_SetStatus(StatusGadget, "Gerando referencia de linha de comando (-h)...")
    Protected HelpOutput.s = ExtTool_RunCaptureOutput(MsxBas2RomCfg\ExePath, "-h")
    Protected CliFile = CreateFile(#PB_Any, HelpDir + "cli-help.md")
    If CliFile
      WriteStringN(CliFile, "# MSXBAS2ROM - referencia de linha de comando (-h)")
      WriteStringN(CliFile, "")
      WriteStringN(CliFile, "```")
      WriteString(CliFile, HelpOutput)
      WriteStringN(CliFile, "```")
      CloseFile(CliFile)
      AddElement(Topics())
      Topics()\File  = "cli-help.md"
      Topics()\Title = "Linha de comando (-h)"
      Topics()\Group = "Linha de comando"
    EndIf
  EndIf

  Restore MsxBas2Rom_WikiPages
  Protected PageName.s, PageTitle.s, PageGroup.s
  Protected OkCount = 0, FailCount = 0
  Repeat
    Read.s PageName
    Read.s PageTitle
    Read.s PageGroup
    If PageName = "@@END@@"
      Break
    EndIf

    ExtTool_SetStatus(StatusGadget, "Baixando wiki: " + PageName + "...")
    Protected PageMd.s = ExtTool_HttpGetText("https://raw.githubusercontent.com/wiki/amaurycarvalho/msxbas2rom/" + PageName + ".md")
    If PageMd <> ""
      PageMd = MsxBas2Rom_RewriteWikiLinks(PageMd)
      Protected PageFile.s = LCase(PageName) + ".md"
      Protected FNum = CreateFile(#PB_Any, HelpDir + PageFile)
      If FNum
        WriteString(FNum, PageMd)
        CloseFile(FNum)
        AddElement(Topics())
        Topics()\File  = PageFile
        Topics()\Title = PageTitle
        Topics()\Group = PageGroup
        OkCount + 1
      EndIf
    Else
      FailCount + 1
    EndIf
  ForEver

  If ListSize(Topics()) = 0
    ExtTool_SetStatus(StatusGadget, "Falha ao baixar a documentacao (verifique sua conexao).")
    ProcedureReturn #False
  EndIf

  GenMdHelp_SaveIndex(HelpDir, Topics())

  If FailCount = 0
    ExtTool_SetStatus(StatusGadget, "Documentacao atualizada: " + Str(OkCount) + " pagina(s).")
  Else
    ExtTool_SetStatus(StatusGadget, "Documentacao atualizada: " + Str(OkCount) + " pagina(s), " + Str(FailCount) + " falharam.")
  EndIf
  ProcedureReturn #True
EndProcedure

;- ------------------------------------------------------------
;- Exemplos de codigo reais (demo do msxbas2rom + jogos msxbasic) - "Baixar
;- exemplos"/"Baixar jogos completos", Configurar -> MSXBas2Rom...
;- ------------------------------------------------------------

; Varre recursivamente Dir (ja no disco, pasta baixada) por .bas/.md,
; empilhando cada achado em Topics(). Cada subpasta de PRIMEIRO NIVEL dentro
; de Dir vira seu proprio grupo (GroupPrefix + nome da subpasta, ex.: "Demo:
; scroll1"/"Jogo: Fortknox") - qualquer coisa mais profunda dentro dela
; (ex.: Fortknox\disk\AUTOEXEC.BAS) entra NO MESMO grupo, com o titulo
; prefixado pelo caminho relativo dentro do jogo/demo (ex.: "disk\
; AUTOEXEC.BAS") em vez de virar outro nivel de grupo (o motor de Ajuda so
; suporta um nivel de agrupamento, ver GenMdHelp_PopulateTree). Arquivo
; direto na raiz de Dir (sem subpasta - ex.: um README.md geral do
; repositorio) entra no grupo RootGroupName. IndexRelPrefix e o caminho
; RELATIVO A PASTA DE AJUDA (MsxBas2Rom_HelpDir()) que alcanca Dir (ex.:
; "..\demo\") - os arquivos ficam onde foram baixados, sem copia-los pra
; dentro da pasta de Ajuda.
Procedure MsxBas2Rom_ScanCodeExamplesRec(Dir.s, IndexRelPrefix.s, CurGroup.s, TitlePrefix.s, RootLevel.b, GroupPrefix.s, RootGroupName.s, List Topics.GenMdHelp_TopicItem())
  Protected Handle = ExamineDirectory(#PB_Any, Dir, "*.*")
  If Not Handle
    ProcedureReturn
  EndIf

  While NextDirectoryEntry(Handle)
    Protected Name.s = DirectoryEntryName(Handle)
    If Name = "." Or Name = ".."
      Continue
    EndIf

    If DirectoryEntryType(Handle) = #PB_DirectoryEntry_Directory
      If RootLevel
        MsxBas2Rom_ScanCodeExamplesRec(Dir + Name + "\", IndexRelPrefix + Name + "\", GroupPrefix + Name, "", #False, GroupPrefix, RootGroupName, Topics())
      Else
        MsxBas2Rom_ScanCodeExamplesRec(Dir + Name + "\", IndexRelPrefix + Name + "\", CurGroup, TitlePrefix + Name + "\", #False, GroupPrefix, RootGroupName, Topics())
      EndIf
    Else
      Protected NameLower.s = LCase(Name)
      If Right(NameLower, 4) = ".bas" Or Right(NameLower, 3) = ".md"
        AddElement(Topics())
        Topics()\File = IndexRelPrefix + Name
        Topics()\Title = TitlePrefix + Name
        If RootLevel
          Topics()\Group = RootGroupName
        Else
          Topics()\Group = CurGroup
        EndIf
      EndIf
    EndIf
  Wend
  FinishDirectory(Handle)
EndProcedure

Procedure MsxBas2Rom_ScanCodeExamples(RootDir.s, IndexRelPrefix.s, GroupPrefix.s, RootGroupName.s, List Topics.GenMdHelp_TopicItem())
  MsxBas2Rom_ScanCodeExamplesRec(RootDir, IndexRelPrefix, "", "", #True, GroupPrefix, RootGroupName, Topics())
EndProcedure

; Botao "Baixar exemplos": baixa SO a pasta "demo/" do repositorio
; msxbas2rom (zip do repo inteiro via codeload.github.com, filtrado por
; OnlyUnderPrefix = "demo" - ver BadigCfg_ExtractZip/ExtTool_
; DownloadAndExtractZip - assim nao extrai o codigo-fonte C++ do compilador
; pro disco do usuario) pra MsxBas2Rom_DemoDir(), baixando TODOS os arquivos
; (imagens, ROMs, sprites, musica, nao so .bas/.md - pedido explicito do
; usuario "baixe os arquivos no disco"). Só os .bas/.md entram como topico
; de Ajuda (GenMdHelp_MergeIndex preserva os topicos de "Atualizar
; documentacao"/"Baixar jogos completos", que gravam no MESMO _index.json).
Procedure.b MsxBas2Rom_DownloadExamples(StatusGadget)
  Protected DemoDir.s = MsxBas2Rom_DemoDir()
  ExtTool_SetStatus(StatusGadget, "Baixando exemplos (demo) do msxbas2rom...")
  If Not ExtTool_DownloadAndExtractZip("https://codeload.github.com/amaurycarvalho/msxbas2rom/zip/refs/heads/master", DemoDir, "demo")
    ExtTool_SetStatus(StatusGadget, "Falha ao baixar os exemplos (verifique sua conexao).")
    ProcedureReturn #False
  EndIf

  NewList Topics.GenMdHelp_TopicItem()
  MsxBas2Rom_ScanCodeExamples(DemoDir, "..\demo\", "Demo: ", "Exemplos (demo)", Topics())
  If ListSize(Topics()) = 0
    ExtTool_SetStatus(StatusGadget, "Exemplos baixados, mas nenhum .bas/.md encontrado.")
    ProcedureReturn #False
  EndIf

  ExtTool_CreateDirectoryRecursive(MsxBas2Rom_HelpDir())
  GenMdHelp_MergeIndex(MsxBas2Rom_HelpDir(), Topics())

  ExtTool_SetStatus(StatusGadget, "Exemplos baixados: " + Str(ListSize(Topics())) + " arquivo(s) em " + DemoDir)
  ProcedureReturn #True
EndProcedure

; Botao "Baixar jogos completos": baixa o repositorio amaurycarvalho/
; msxbasic inteiro (zip pequeno, ~2.4 MB, sem codigo C++ pra filtrar) pra
; MsxBas2Rom_GamesDir() - 10 jogos completos em MSX BASIC, cada um na sua
; propria pasta (README.md + .bas + imagens/musica/niveis/disco). Mesmo
; agrupamento por pasta de MsxBas2Rom_DownloadExamples(), prefixo "Jogo: "
; em vez de "Demo: ".
Procedure.b MsxBas2Rom_DownloadGames(StatusGadget)
  Protected GamesDir.s = MsxBas2Rom_GamesDir()
  ExtTool_SetStatus(StatusGadget, "Baixando jogos de exemplo (amaurycarvalho/msxbasic)...")
  If Not ExtTool_DownloadAndExtractZip("https://codeload.github.com/amaurycarvalho/msxbasic/zip/refs/heads/main", GamesDir)
    ExtTool_SetStatus(StatusGadget, "Falha ao baixar os jogos (verifique sua conexao).")
    ProcedureReturn #False
  EndIf

  NewList Topics.GenMdHelp_TopicItem()
  MsxBas2Rom_ScanCodeExamples(GamesDir, "..\games\", "Jogo: ", "Jogos MSX BASIC (msxbasic)", Topics())
  If ListSize(Topics()) = 0
    ExtTool_SetStatus(StatusGadget, "Jogos baixados, mas nenhum .bas/.md encontrado.")
    ProcedureReturn #False
  EndIf

  ExtTool_CreateDirectoryRecursive(MsxBas2Rom_HelpDir())
  GenMdHelp_MergeIndex(MsxBas2Rom_HelpDir(), Topics())

  ExtTool_SetStatus(StatusGadget, "Jogos baixados: " + Str(ListSize(Topics())) + " arquivo(s) em " + GamesDir)
  ProcedureReturn #True
EndProcedure

;- ------------------------------------------------------------
;- Tela "Configurar -> MSXBas2Rom..."
;- ------------------------------------------------------------

; Texto de status de instalacao mostrado acima dos botoes - so reflete
; Version/ExePath do MsxBas2RomCfg atual (nao valida o campo editavel do
; caminho, que pode ter sido digitado/escolhido pelo usuario sem "Salvar"
; ainda).
Procedure.s MsxBas2Rom_VersionStatusText()
  If MsxBas2RomCfg\ExePath <> "" And FileSize(MsxBas2RomCfg\ExePath) > 0
    If MsxBas2RomCfg\Version <> ""
      ProcedureReturn "Versao instalada: " + MsxBas2RomCfg\Version
    Else
      ProcedureReturn "Executavel configurado (versao desconhecida - instalado manualmente)."
    EndIf
  Else
    ProcedureReturn "Nenhuma versao baixada ainda."
  EndIf
EndProcedure

; OverridePath (opcional): ver BadigCfg_OpenSettingsWindow() (BadigSettings.pbi)
; pro mesmo padrao - so afeta onde o campo ExePath e lido/salvo (Load no
; topo, Save no botao "Salvar"); os botoes de download continuam baixando
; pra pasta global de sempre (tools/msxbas2rom/ - nao faz sentido duplicar
; o executavel por projeto), mas o caminho que aparece no campo apos um
; download pode ser salvo no override do projeto normalmente.
; Indices do ComboBox "Modo de compilacao" (pagina 2) <-> MsxBas2RomCfg\CompileMode
; ("" = -c/padrao, item 0). Mesma ordem nos dois lados (combo/Select),
; centralizado aqui pra nao desalinhar se um dia mudar.
Procedure.s MsxBas2Rom_CompileModeToCode(ComboIndex.i)
  Select ComboIndex
    Case 1 : ProcedureReturn "a"
    Case 2 : ProcedureReturn "x"
    Case 3 : ProcedureReturn "6"
    Case 4 : ProcedureReturn "7"
    Case 5 : ProcedureReturn "4"
    Case 6 : ProcedureReturn "k"
    Default : ProcedureReturn ""
  EndSelect
EndProcedure

Procedure.i MsxBas2Rom_CompileModeToCombo(Code.s)
  Select Code
    Case "a" : ProcedureReturn 1
    Case "x" : ProcedureReturn 2
    Case "6" : ProcedureReturn 3
    Case "7" : ProcedureReturn 4
    Case "4" : ProcedureReturn 5
    Case "k" : ProcedureReturn 6
    Default  : ProcedureReturn 0
  EndSelect
EndProcedure

Procedure.s MsxBas2Rom_SymbolFormatToCode(ComboIndex.i)
  Select ComboIndex
    Case 1 : ProcedureReturn "noi"
    Case 2 : ProcedureReturn "cdb"
    Case 3 : ProcedureReturn "symbol"
    Case 4 : ProcedureReturn "omds"
    Default : ProcedureReturn ""
  EndSelect
EndProcedure

Procedure.i MsxBas2Rom_SymbolFormatToCombo(Code.s)
  Select Code
    Case "noi"    : ProcedureReturn 1
    Case "cdb"    : ProcedureReturn 2
    Case "symbol" : ProcedureReturn 3
    Case "omds"   : ProcedureReturn 4
    Default       : ProcedureReturn 0
  EndSelect
EndProcedure

; Roda o msxbas2rom.exe so com um flag informativo (-h/-D/-H/-v - mostram
; texto e saem sem compilar nada, ver comentario de MsxBas2RomSettings acima)
; e mostra a saida capturada num MessageRequester - acao unica, nao afeta
; nenhuma configuracao salva (por isso NAO sao checkbox persistente na
; tela, so estes 4 botoes).
Procedure MsxBas2Rom_RunInfoFlag(ExePath.s, Flag.s, Title.s)
  If ExePath = "" Or FileSize(ExePath) <= 0
    MessageRequester(Title, "Configure o caminho do msxbas2rom.exe primeiro.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf
  Protected Output.s = ExtTool_RunCaptureOutput(ExePath, Flag)
  If Output = ""
    Output = "(sem saida)"
  EndIf
  MessageRequester(Title, Output, #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
EndProcedure

Procedure MsxBas2RomSettings_OpenWindow(ParentWindow, OverridePath.s = "")
  MsxBas2RomCfg_Load(OverridePath)
  ; Se ainda nao ha caminho salvo, tenta achar um executavel ja baixado antes
  ; (ex.: settings.json apagado/recriado) na pasta padrao antes de mostrar o
  ; campo vazio.
  If MsxBas2RomCfg\ExePath = ""
    MsxBas2RomCfg\ExePath = MsxBas2Rom_FindExe()
  EndIf
  Protected KnownExePath.s = MsxBas2RomCfg\ExePath ; pra saber se o campo foi trocado manualmente ao salvar

  Protected WinW = 680, WinH = 620
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Configurar - MSXBas2Rom",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  Protected Panel = PanelGadget(#PB_Any, 24, 24, WinW - 48, WinH - 104)
  Protected PanelWidth = WinW - 48

  ;- Pagina 1: Geral -----------------------------------------------------
  AddGadgetItem(Panel, -1, "Geral")

  TextGadget(#PB_Any, 24, 24, PanelWidth - 48, 40,
            "MSXBAS2ROM compila programas MSX-BASIC classicos (.bas) direto em ROM (nao incorporado a esta IDE - so chamado como executavel externo)." + Chr(10) +
            "github.com/amaurycarvalho/msxbas2rom")

  TextGadget(#PB_Any, 24, 76, PanelWidth - 48, 20, "Caminho do msxbas2rom.exe (baixe abaixo ou escolha se ja tiver instalado)")
  Protected G_ExePath = StringGadget(#PB_Any, 24, 104, PanelWidth - 24 - 64 - 32, 24, MsxBas2RomCfg\ExePath)
  Protected G_ExePathBrowse = ThemedButton(PanelWidth - 24 - 64, 104, 64, 24, "...", "")

  Protected G_VersionInfo = TextGadget(#PB_Any, 24, 138, PanelWidth - 48, 20, MsxBas2Rom_VersionStatusText())

  Protected G_Download = ThemedButton(24, 172, 296, 28, "Baixar versao mais recente", "")
  Protected G_UpdateDocs = ThemedButton(328, 172, 288, 28, "Atualizar documentacao", "")
  GadgetToolTip(G_UpdateDocs, "Baixa/atualiza o conteudo de Ajuda -> MSXBas2Rom... a partir da wiki oficial")

  Protected G_DownloadExamples = ThemedButton(24, 208, 296, 28, "Baixar exemplos (demo)", "")
  GadgetToolTip(G_DownloadExamples, "Baixa os exemplos oficiais (demo/) do msxbas2rom e mostra os .bas em Ajuda -> MSXBas2Rom...")
  Protected G_DownloadGames = ThemedButton(328, 208, 288, 28, "Baixar jogos completos", "")
  GadgetToolTip(G_DownloadGames, "Baixa os jogos completos de amaurycarvalho/msxbasic e mostra os .bas/.md em Ajuda -> MSXBas2Rom...")

  Protected G_Status = TextGadget(#PB_Any, 24, 248, PanelWidth - 48, 40, "")

  ;- Pagina 2: Opcoes de compilacao ---------------------------------------
  ; Espelha 1:1 "msxbas2rom -h" (tools/msxbas2rom/help/cli-help.md) - grupos
  ; na mesma ordem: gerais, modo de compilacao (mutuamente exclusivo),
  ; caminhos, especiais. Ver MsxBas2Rom_BuildCliArgs() (aplicado so no
  ; momento de compilar, nao aqui).
  AddGadgetItem(Panel, -1, "Opcoes de compilacao")

  TextGadget(#PB_Any, 24, 24, PanelWidth - 48, 20, "Opcoes gerais")
  Protected G_Quiet = CheckBoxGadget(#PB_Any, 24, 52, 280, 22, "Modo silencioso (-q)")
  Protected G_Debug = CheckBoxGadget(#PB_Any, 328, 52, 280, 22, "Modo debug - mostra detalhes (-d)")

  TextGadget(#PB_Any, 24, 96, PanelWidth - 48, 20, "Modo de compilacao (mutuamente exclusivo)")
  Protected G_CompileMode = ComboBoxGadget(#PB_Any, 24, 124, 400, 24)
  AddGadgetItem(G_CompileMode, -1, "ROM simples (padrao, -c)")
  AddGadgetItem(G_CompileMode, -1, "Automatico - cai pra ASCII8 se a ROM simples nao couber (-a)")
  AddGadgetItem(G_CompileMode, -1, "MegaROM ASCII8 (-x)")
  AddGadgetItem(G_CompileMode, -1, "MegaROM ASCII16 (-6)")
  AddGadgetItem(G_CompileMode, -1, "MegaROM ASCII16-X (-7)")
  AddGadgetItem(G_CompileMode, -1, "MegaROM Konami (-4)")
  AddGadgetItem(G_CompileMode, -1, "MegaROM Konami SCC (-k)")

  TextGadget(#PB_Any, 24, 176, PanelWidth - 48, 20, "Caminho de entrada (-i, vazio = pasta do .bas gerado)")
  Protected G_InputPath = StringGadget(#PB_Any, 24, 204, PanelWidth - 24 - 64 - 32, 24, MsxBas2RomCfg\InputPath)
  Protected G_InputPathBrowse = ThemedButton(PanelWidth - 24 - 64, 204, 64, 24, "...", "")

  TextGadget(#PB_Any, 24, 244, PanelWidth - 48, 20, "Caminho de saida (-o, vazio = pasta do .bas gerado)")
  Protected G_OutputPath = StringGadget(#PB_Any, 24, 272, PanelWidth - 24 - 64 - 32, 24, MsxBas2RomCfg\OutputPath)
  Protected G_OutputPathBrowse = ThemedButton(PanelWidth - 24 - 64, 272, 64, 24, "...", "")

  TextGadget(#PB_Any, 24, 312, PanelWidth - 48, 20, "Opcoes especiais")
  Protected G_SymbolFormat = ComboBoxGadget(#PB_Any, 24, 340, 400, 24)
  AddGadgetItem(G_SymbolFormat, -1, "Nao gerar simbolos de depuracao")
  AddGadgetItem(G_SymbolFormat, -1, ".noi - openMSX (-s)")
  AddGadgetItem(G_SymbolFormat, -1, ".cdb - sdcc (--cdb)")
  AddGadgetItem(G_SymbolFormat, -1, ".symbol - pasmo (--symbol)")
  AddGadgetItem(G_SymbolFormat, -1, ".omds - openMSX obsoleto (--omds)")

  Protected G_WriteLineNumbers = CheckBoxGadget(#PB_Any, 24, 380, PanelWidth - 48, 22,
                                                "Gravar numeros de linha do MSX-BASIC no binario (--lin)")
  Protected G_VSCodeInit = CheckBoxGadget(#PB_Any, 24, 408, PanelWidth - 48, 22,
                                          "Inicializar projeto VSCode no diretorio atual (--vscode)")

  TextGadget(#PB_Any, 24, 448, PanelWidth - 48, 20, "Acoes rapidas (so mostram informacao, nao compilam nada)")
  Protected InfoBtnW = (PanelWidth - 48 - 24) / 4
  Protected G_InfoHelp = ThemedButton(24, 476, InfoBtnW, 28, "Ajuda (-h)", "")
  Protected G_InfoDoc = ThemedButton(24 + InfoBtnW + 8, 476, InfoBtnW, 28, "Guia rapido (-D)", "")
  Protected G_InfoHistory = ThemedButton(24 + (InfoBtnW + 8) * 2, 476, InfoBtnW, 28, "Historico (-H)", "")
  Protected G_InfoVersion = ThemedButton(24 + (InfoBtnW + 8) * 3, 476, InfoBtnW, 28, "Versao (-v)", "")

  CloseGadgetList() ; fecha o PanelGadget

  SetGadgetState(G_Quiet, MsxBas2RomCfg\OptQuiet)
  SetGadgetState(G_Debug, MsxBas2RomCfg\OptDebug)
  SetGadgetState(G_CompileMode, MsxBas2Rom_CompileModeToCombo(MsxBas2RomCfg\CompileMode))
  SetGadgetState(G_SymbolFormat, MsxBas2Rom_SymbolFormatToCombo(MsxBas2RomCfg\SymbolFormat))
  SetGadgetState(G_WriteLineNumbers, MsxBas2RomCfg\OptWriteLineNumbers)
  SetGadgetState(G_VSCodeInit, MsxBas2RomCfg\OptVSCodeInit)

  Protected G_Save = ThemedButton(WinW - 256, WinH - 56, 110, 32, "Salvar", Chr(#Icon_Save))
  GadgetToolTip(G_Save, "Salvar")
  Protected G_Cancel = ThemedButton(WinW - 134, WinH - 56, 110, 32, "Cancelar", "")

  ; As 4 acoes de rede (Download/UpdateDocs/DownloadExamples/DownloadGames)
  ; sao bloqueantes e mutuamente exclusivas - trava todos os 6 botoes durante
  ; qualquer uma delas, nao só o que foi clicado, pra evitar clique duplo ou
  ; salvar/cancelar no meio de um download.
  Macro MsxBas2Rom_LockButtons(State)
    DisableGadget(G_Download, State)
    DisableGadget(G_UpdateDocs, State)
    DisableGadget(G_DownloadExamples, State)
    DisableGadget(G_DownloadGames, State)
    DisableGadget(G_Save, State)
    DisableGadget(G_Cancel, State)
  EndMacro

  Protected Event, Quit = #False, Saved = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_ExePathBrowse
            CompilerIf #PB_Compiler_OS = #PB_OS_Windows
              Protected ExeFilter.s = "Executavel (*.exe)|*.exe|Todos os arquivos (*.*)|*.*"
            CompilerElse
              Protected ExeFilter.s = "Todos os arquivos (*.*)|*.*"
            CompilerEndIf
            Protected PickPath.s = OpenFileRequester("Selecione o executavel do msxbas2rom",
                                                     GetGadgetText(G_ExePath), ExeFilter, 0)
            If PickPath <> ""
              SetGadgetText(G_ExePath, PickPath)
            EndIf

          Case G_InputPathBrowse
            Protected PickInputDir.s = PathRequester("Selecione a pasta de entrada (-i)", GetGadgetText(G_InputPath))
            If PickInputDir <> ""
              SetGadgetText(G_InputPath, PickInputDir)
            EndIf

          Case G_OutputPathBrowse
            Protected PickOutputDir.s = PathRequester("Selecione a pasta de saida (-o)", GetGadgetText(G_OutputPath))
            If PickOutputDir <> ""
              SetGadgetText(G_OutputPath, PickOutputDir)
            EndIf

          Case G_InfoHelp
            MsxBas2Rom_RunInfoFlag(GetGadgetText(G_ExePath), "-h", "MSXBas2Rom - Ajuda (-h)")

          Case G_InfoDoc
            MsxBas2Rom_RunInfoFlag(GetGadgetText(G_ExePath), "-D", "MSXBas2Rom - Guia rapido (-D)")

          Case G_InfoHistory
            MsxBas2Rom_RunInfoFlag(GetGadgetText(G_ExePath), "-H", "MSXBas2Rom - Historico (-H)")

          Case G_InfoVersion
            MsxBas2Rom_RunInfoFlag(GetGadgetText(G_ExePath), "-v", "MSXBas2Rom - Versao (-v)")

          Case G_Download
            MsxBas2Rom_LockButtons(#True)
            If MsxBas2Rom_DownloadExe(G_Status)
              MsxBas2RomCfg_Load()
              KnownExePath = MsxBas2RomCfg\ExePath
              SetGadgetText(G_ExePath, MsxBas2RomCfg\ExePath)
              SetGadgetText(G_VersionInfo, MsxBas2Rom_VersionStatusText())
            EndIf
            MsxBas2Rom_LockButtons(#False)

          Case G_UpdateDocs
            MsxBas2Rom_LockButtons(#True)
            MsxBas2RomCfg\ExePath = GetGadgetText(G_ExePath) ; usa o caminho exibido, mesmo sem "Salvar" ainda
            MsxBas2Rom_UpdateDocumentation(G_Status)
            MsxBas2Rom_LockButtons(#False)

          Case G_DownloadExamples
            MsxBas2Rom_LockButtons(#True)
            MsxBas2Rom_DownloadExamples(G_Status)
            MsxBas2Rom_LockButtons(#False)

          Case G_DownloadGames
            MsxBas2Rom_LockButtons(#True)
            MsxBas2Rom_DownloadGames(G_Status)
            MsxBas2Rom_LockButtons(#False)

          Case G_Save
            Saved = #True
            Quit = #True

          Case G_Cancel
            Quit = #True
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  If Saved
    Protected NewExePath.s = GetGadgetText(G_ExePath)
    If NewExePath <> KnownExePath
      MsxBas2RomCfg\Version = "" ; caminho trocado a mao - versao desconhecida
    EndIf
    MsxBas2RomCfg\ExePath = NewExePath
    MsxBas2RomCfg\OptQuiet = GetGadgetState(G_Quiet)
    MsxBas2RomCfg\OptDebug = GetGadgetState(G_Debug)
    MsxBas2RomCfg\CompileMode = MsxBas2Rom_CompileModeToCode(GetGadgetState(G_CompileMode))
    MsxBas2RomCfg\InputPath = GetGadgetText(G_InputPath)
    MsxBas2RomCfg\OutputPath = GetGadgetText(G_OutputPath)
    MsxBas2RomCfg\SymbolFormat = MsxBas2Rom_SymbolFormatToCode(GetGadgetState(G_SymbolFormat))
    MsxBas2RomCfg\OptWriteLineNumbers = GetGadgetState(G_WriteLineNumbers)
    MsxBas2RomCfg\OptVSCodeInit = GetGadgetState(G_VSCodeInit)
    MsxBas2RomCfg_Save(OverridePath)
  EndIf

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
