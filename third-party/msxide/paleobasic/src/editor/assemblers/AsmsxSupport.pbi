;
; ------------------------------------------------------------
;  Suporte ao asMSX (github.com/Fubukimaru/asMSX): terceiro assembler Z80
;  suportado pela IDE, ao lado do nativo (Z80Asm.pbi/Z80Link.pbi/Z80Lib.pbi)
;  e do N80/Nestor80 (N80Support.pbi) - ferramenta externa, chamada como
;  executavel, nao incorporada. Template de arquivo novo (Arquivo -> Novo
;  asMSX...), tela "Configurar -> asMSX..." (caminho do executavel + baixar
;  release oficial do GitHub) e Ajuda -> asMSX... (AsmsxHelpData.pbi/
;  AsmsxHelpGui.pbi, conteudo baked a partir de asmsx/doc/asmsx.md - ver
;  convert_asmsx.py, descartavel/nao versionado).
;
;  Ao contrario do N80 (3 programas em release tags diferentes do mesmo
;  repo, precisa varrer /releases) e do MSXBAS2ROM (asset .zip), o asMSX
;  publica um UNICO executavel avulso por SO/arquitetura em GET
;  releases/latest - mais simples, usa ExtTool_DownloadFile() em vez de
;  ExtTool_DownloadAndExtractZip() (ExternalToolDownload.pbi). Nomes de asset
;  confirmados direto na API (2026-08-11): "asmsx-win-x86-64.exe" (Windows
;  64-bit), "asmsx-linux-x86_64" (Linux 64-bit) - tambem existem
;  "asmsx-win-i686.exe"/"asmsx-linux-armhf"/"asmsx-darwin", fora do escopo
;  (o resto do projeto so builda Windows/Linux x64).
;
;  "Executar -> Montar Fonte asMSX..." (Asmsx_AssembleFile(), chamado por
;  AssembleAsmsxFromActiveTab() em BadigEditor.pb) roda o executavel
;  configurado contra a aba .asm ativa (salva num arquivo real primeiro - o
;  asMSX so aceita arquivo, nao stdin), com as opcoes -z/-s/-vv/-o de
;  AsmsxCfg (Configurar -> asMSX.../Configurar -> Projeto...).
; ------------------------------------------------------------
;

;- ------------------------------------------------------------
;- Template do arquivo novo (Arquivo -> Novo asMSX...)
;- ------------------------------------------------------------

; Comentario de cabecalho + diretivas padrao pertinentes a um programa MSX
; tipico carregavel via BLOAD"NOME.BIN",R (.BASIC - a saida mais simples de
; testar direto no openMSX, mesmo espirito do "HELLO, MSX!" de
; MsxBas2RomTemplateText()). .ORG 8000h e a pagina 2 (RAM em qualquer MSX
; padrao) - convencao comum pra binarios BLOAD, comentado pra o usuario
; poder trocar sem ter que descobrir o valor sozinho. Sintaxe de
; enderecamento indireto com colchetes (asMSX, ao contrario do Zilog padrao)
; e a diretiva .ZILOG (pra quem preferir parenteses) ficam citadas no
; cabecalho porque sao a diferenca mais visivel/confusa pra quem já conhece
; Z80 assembly "normal" (ver secao 1.4 "Syntax" do manual, Ajuda -> asMSX...).
Procedure.s AsmsxTemplateText()
  Protected Text.s = ""
  Text + "; ------------------------------------------------------------" + #CRLF$
  Text + ";  Projeto asMSX - github.com/Fubukimaru/asMSX" + #CRLF$
  Text + ";  Monte com: asmsx NOMEDOARQUIVO.ASM" + #CRLF$
  Text + ";" + #CRLF$
  Text + ";  Sintaxe: colchetes [ ] pra enderecamento indireto (nao" + #CRLF$
  Text + ";  parenteses) - use a diretiva .ZILOG se preferir a sintaxe Zilog" + #CRLF$
  Text + ";  padrao com parenteses. Comentarios com " + Chr(34) + ";" + Chr(34) +
                " (tambem aceita " + Chr(34) + "//" + Chr(34) + ", " +
                Chr(34) + "/* */" + Chr(34) + ", " + Chr(34) + "{ }" + Chr(34) +
                " e " + Chr(34) + "--" + Chr(34) + ")." + #CRLF$
  Text + "; ------------------------------------------------------------" + #CRLF$
  Text + #CRLF$
  Text + "    .BASIC              ; cabecalho p/ BLOAD" + Chr(34) + "NOME.BIN" + Chr(34) + ",R no MSX-BASIC" + #CRLF$
  Text + "    .ORG 8000h          ; pagina 2 (RAM) - troque conforme necessario" + #CRLF$
  Text + #CRLF$
  Text + "Inicio:" + #CRLF$
  Text + "    ret                 ; TODO: seu codigo aqui" + #CRLF$
  ProcedureReturn Text
EndProcedure

;- ------------------------------------------------------------
;- Configuracoes / persistencia
;- ------------------------------------------------------------

; OptZilog/OptSilent/OptVerbose/OutputPath espelham as opcoes de linha de
; comando do proprio asMSX (secao 1.5.1 do manual, Ajuda -> asMSX...): -z/-s/
; -vv/-o. "-r" (deprecated, o proprio manual diz que nao e mais necessario) e
; "-d" (so existe num build com YYDEBUG=1) ficaram de fora de proposito.
Structure AsmsxSettings
  ExePath.s
  Version.s
  OptZilog.b    ; -z
  OptSilent.b   ; -s
  OptVerbose.b  ; -vv
  OutputPath.s  ; -o
EndStructure
Global AsmsxCfg.AsmsxSettings

Procedure.s Asmsx_ToolDir()
  ProcedureReturn GetPathPart(ProgramFilename()) + "editor\tools\asmsx\"
EndProcedure

; OverridePath (opcional): ver comentario equivalente de BadigCfg_FilePath()
; (BadigSettings.pbi) - "" = caminho global de sempre, senao usa esse
; caminho direto (config por-projeto, "Configurar -> Projeto...").
Procedure.s AsmsxCfg_FilePath(OverridePath.s = "")
  If OverridePath <> ""
    ProcedureReturn OverridePath
  EndIf
  ProcedureReturn GetPathPart(ProgramFilename()) + "editor\asmsx_settings.json"
EndProcedure

Procedure AsmsxCfg_Load(OverridePath.s = "")
  AsmsxCfg\ExePath = ""
  AsmsxCfg\Version = ""
  AsmsxCfg\OptZilog = #False
  AsmsxCfg\OptSilent = #False
  AsmsxCfg\OptVerbose = #False
  AsmsxCfg\OutputPath = ""

  Protected FilePath.s = AsmsxCfg_FilePath(OverridePath)
  If FileSize(FilePath) <= 0
    ProcedureReturn
  EndIf

  Protected Json = LoadJSON(#PB_Any, FilePath)
  If Not Json
    ProcedureReturn
  EndIf

  Protected Root = JSONValue(Json)
  Protected M
  M = GetJSONMember(Root, "ExePath")    : If M : AsmsxCfg\ExePath    = GetJSONString(M)  : EndIf
  M = GetJSONMember(Root, "Version")    : If M : AsmsxCfg\Version    = GetJSONString(M)  : EndIf
  M = GetJSONMember(Root, "OptZilog")   : If M : AsmsxCfg\OptZilog   = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "OptSilent")  : If M : AsmsxCfg\OptSilent  = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "OptVerbose") : If M : AsmsxCfg\OptVerbose = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "OutputPath") : If M : AsmsxCfg\OutputPath = GetJSONString(M)  : EndIf
  FreeJSON(Json)
EndProcedure

Procedure AsmsxCfg_Save(OverridePath.s = "")
  Protected Json = CreateJSON(#PB_Any)
  Protected Root = SetJSONObject(JSONValue(Json))
  SetJSONString(AddJSONMember(Root, "ExePath"), AsmsxCfg\ExePath)
  SetJSONString(AddJSONMember(Root, "Version"), AsmsxCfg\Version)
  SetJSONBoolean(AddJSONMember(Root, "OptZilog"), AsmsxCfg\OptZilog)
  SetJSONBoolean(AddJSONMember(Root, "OptSilent"), AsmsxCfg\OptSilent)
  SetJSONBoolean(AddJSONMember(Root, "OptVerbose"), AsmsxCfg\OptVerbose)
  SetJSONString(AddJSONMember(Root, "OutputPath"), AsmsxCfg\OutputPath)
  SaveJSON(Json, AsmsxCfg_FilePath(OverridePath), #PB_JSON_PrettyPrint)
  FreeJSON(Json)
EndProcedure

;- ------------------------------------------------------------
;- Download (Configurar -> asMSX -> Baixar versao mais recente)
;- ------------------------------------------------------------

Procedure.s Asmsx_FindExe()
  Protected Dir.s = Asmsx_ToolDir()
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    If FileSize(Dir + "asmsx.exe") > 0 : ProcedureReturn Dir + "asmsx.exe" : EndIf
  CompilerElse
    If FileSize(Dir + "asmsx") > 0 : ProcedureReturn Dir + "asmsx" : EndIf
  CompilerEndIf
  ProcedureReturn ""
EndProcedure

; Acha o asset avulso da release mais recente pro SO atual via GET
; releases/latest (unico release, sem historico pra varrer - mesma familia
; de MsxBas2Rom_ResolveAssetUrl()). *OutVersion recebe o "tag_name" (ex.:
; "1.2.0").
Procedure.s Asmsx_ResolveAssetUrl(*OutVersion.String)
  *OutVersion\s = ""
  Protected JsonText.s = ExtTool_HttpGetText("https://api.github.com/repos/Fubukimaru/asMSX/releases/latest")
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

  Protected AssetName.s
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    AssetName = "asmsx-win-x86-64.exe"
  CompilerElse
    AssetName = "asmsx-linux-x86_64"
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
        If NameM And GetJSONString(NameM) = AssetName
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

; Baixa so o executavel (release mais atual do GitHub) e salva as
; configuracoes. StatusGadget (pode ser 0) recebe feedback textual a cada
; passo - mesmo padrao bloqueante de MsxBas2Rom_DownloadExe()/N80_Download().
Procedure.b Asmsx_DownloadExe(StatusGadget)
  ExtTool_SetStatus(StatusGadget, "Consultando release mais recente no GitHub...")
  Protected Version.String
  Protected AssetUrl.s = Asmsx_ResolveAssetUrl(@Version)
  If AssetUrl = ""
    ExtTool_SetStatus(StatusGadget, "Falha ao consultar o GitHub (verifique sua conexao).")
    ProcedureReturn #False
  EndIf

  Protected ToolDir.s = Asmsx_ToolDir()
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Protected TargetPath.s = ToolDir + "asmsx.exe"
  CompilerElse
    Protected TargetPath.s = ToolDir + "asmsx"
  CompilerEndIf

  ExtTool_SetStatus(StatusGadget, "Baixando asMSX " + Version\s + "...")
  If Not ExtTool_DownloadFile(AssetUrl, TargetPath)
    ExtTool_SetStatus(StatusGadget, "Falha ao baixar o executavel.")
    ProcedureReturn #False
  EndIf

  AsmsxCfg\ExePath = TargetPath
  AsmsxCfg\Version = Version\s
  AsmsxCfg_Save()

  ExtTool_SetStatus(StatusGadget, "Concluido: asMSX " + Version\s + " instalado em " + ToolDir)
  ProcedureReturn #True
EndProcedure

Procedure.s Asmsx_VersionStatusText()
  If AsmsxCfg\ExePath <> "" And FileSize(AsmsxCfg\ExePath) > 0
    If AsmsxCfg\Version <> ""
      ProcedureReturn "Versao instalada: " + AsmsxCfg\Version
    Else
      ProcedureReturn "Executavel configurado (versao desconhecida - instalado manualmente)."
    EndIf
  Else
    ProcedureReturn "Nenhuma versao baixada ainda."
  EndIf
EndProcedure

;- ------------------------------------------------------------
;- Montar (Executar -> Montar Fonte asMSX...)
;- ------------------------------------------------------------

; Monta a linha de argumentos a partir de AsmsxCfg (Configurar -> asMSX.../
; Configurar -> Projeto... - mesma struct, so muda pra onde le/grava, mesmo
; idioma de MsxBas2Rom_BuildCliArgs()). Ordem segue a secao 1.5.1 do manual.
Procedure.s Asmsx_BuildCliArgs(AsmPath.s)
  Protected Args.s = ""
  If AsmsxCfg\OptZilog  : Args + "-z " : EndIf
  If AsmsxCfg\OptSilent : Args + "-s " : EndIf
  If AsmsxCfg\OptVerbose : Args + "-vv " : EndIf
  If AsmsxCfg\OutputPath <> ""
    Args + "-o " + Chr(34) + AsmsxCfg\OutputPath + Chr(34) + " "
  EndIf
  Args + Chr(34) + AsmPath + Chr(34)
  ProcedureReturn Args
EndProcedure

; Roda o executavel configurado contra AsmPath (.asm ja salvo em disco - o
; asMSX so aceita arquivo real, nao stdin) e mostra o resultado num
; MessageRequester - mesmo idioma de captura de saida + ProgramExitCode() de
; MsxBas2Rom_CompileToRom() (ExitCode e o unico sinal confiavel de sucesso/
; falha). Ao contrario do MSXBas2Rom, o asMSX NAO tem um nome de saida fixo
; previsivel (o tipo/nome do arquivo gerado depende de diretivas dentro do
; proprio fonte - .BASIC/.ROM/.MSXDOS/etc, nao de uma flag de linha de
; comando) - por isso aqui so reporta a saida capturada (o proprio asMSX
; imprime os nomes dos arquivos gerados), sem tentar adivinhar/checar um
; caminho esperado.
Procedure.b Asmsx_AssembleFile(AsmPath.s)
  Protected Prog = RunProgram(AsmsxCfg\ExePath, Asmsx_BuildCliArgs(AsmPath), GetPathPart(AsmPath),
                               #PB_Program_Open | #PB_Program_Read | #PB_Program_Error | #PB_Program_Hide)
  If Not Prog
    MessageRequester("Montar Fonte asMSX",
                     "Nao foi possivel iniciar o executavel do asMSX:" + Chr(10) + AsmsxCfg\ExePath,
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

  If ExitCode = 0
    MessageRequester("Montar Fonte asMSX",
                     "Montado com sucesso:" + Chr(10) + AsmPath + Chr(10) + Chr(10) + Output,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
    ProcedureReturn #True
  Else
    MessageRequester("Erro ao montar",
                     "asMSX terminou com codigo " + Str(ExitCode) + "." + Chr(10) + Chr(10) + Output,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf
EndProcedure

;- ------------------------------------------------------------
;- Tela "Configurar -> asMSX..."
;- ------------------------------------------------------------

; OverridePath (opcional): ver MsxBas2RomSettings_OpenWindow() pro mesmo
; padrao - so troca de onde AsmsxCfg_Load()/_Save() le/grava.
Procedure AsmsxSettings_OpenWindow(ParentWindow, OverridePath.s = "")
  AsmsxCfg_Load(OverridePath)
  ; Se ainda nao ha caminho salvo, tenta achar um executavel ja baixado antes
  ; (ex.: settings.json apagado/recriado) na pasta padrao antes de mostrar o
  ; campo vazio.
  If AsmsxCfg\ExePath = ""
    AsmsxCfg\ExePath = Asmsx_FindExe()
  EndIf
  Protected KnownExePath.s = AsmsxCfg\ExePath ; pra saber se o campo foi trocado manualmente ao salvar

  Protected WinW = 640, WinH = 500
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Configurar - asMSX",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  TextGadget(#PB_Any, 24, 24, WinW - 48, 40,
            "asMSX e um Z80 cross-assembler pra MSX (nao incorporado a esta IDE - so" + Chr(10) +
            "chamado como executavel externo). github.com/Fubukimaru/asMSX")

  TextGadget(#PB_Any, 24, 76, WinW - 48, 20, "Caminho do executavel (baixe abaixo ou escolha se ja tiver instalado)")
  Protected G_ExePath = StringGadget(#PB_Any, 24, 104, WinW - 24 - 64 - 32, 24, AsmsxCfg\ExePath)
  Protected G_ExePathBrowse = ThemedButton(WinW - 24 - 64, 104, 64, 24, "...", "")

  Protected G_VersionInfo = TextGadget(#PB_Any, 24, 138, WinW - 48, 20, Asmsx_VersionStatusText())

  Protected G_Download = ThemedButton(24, 172, 280, 28, "Baixar versao mais recente", "")
  Protected G_Status = TextGadget(#PB_Any, 24, 212, WinW - 48, 40, "")

  TextGadget(#PB_Any, 24, 264, WinW - 48, 20, "Opcoes de linha de comando (usadas em Executar -> Montar Fonte asMSX...)")
  Protected G_Zilog = CheckBoxGadget(#PB_Any, 24, 292, 280, 22, "Sintaxe Zilog padrao, sem precisar de .ZILOG (-z)")
  Protected G_Silent = CheckBoxGadget(#PB_Any, 328, 292, 280, 22, "Modo silencioso (-s)")
  Protected G_Verbose = CheckBoxGadget(#PB_Any, 24, 320, 280, 22, "Modo verboso - mais mensagens (-vv)")

  TextGadget(#PB_Any, 24, 356, WinW - 48, 20, "Caminho/prefixo de saida (-o, vazio = ao lado do fonte)")
  Protected G_OutputPath = StringGadget(#PB_Any, 24, 384, WinW - 24 - 64 - 32, 24, AsmsxCfg\OutputPath)
  Protected G_OutputPathBrowse = ThemedButton(WinW - 24 - 64, 384, 64, 24, "...", "")

  Protected G_Save = ThemedButton(WinW - 256, WinH - 56, 110, 32, "Salvar", Chr(#Icon_Save))
  GadgetToolTip(G_Save, "Salvar")
  Protected G_Cancel = ThemedButton(WinW - 134, WinH - 56, 110, 32, "Cancelar", "")

  SetGadgetState(G_Zilog, AsmsxCfg\OptZilog)
  SetGadgetState(G_Silent, AsmsxCfg\OptSilent)
  SetGadgetState(G_Verbose, AsmsxCfg\OptVerbose)

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
            Protected PickPath.s = OpenFileRequester("Selecione o executavel do asMSX",
                                                     GetGadgetText(G_ExePath), ExeFilter, 0)
            If PickPath <> ""
              SetGadgetText(G_ExePath, PickPath)
            EndIf

          Case G_OutputPathBrowse
            Protected PickOutputDir.s = PathRequester("Selecione a pasta de saida (-o)", GetGadgetText(G_OutputPath))
            If PickOutputDir <> ""
              SetGadgetText(G_OutputPath, PickOutputDir)
            EndIf

          Case G_Download
            DisableGadget(G_Download, #True)
            DisableGadget(G_Save, #True)
            DisableGadget(G_Cancel, #True)
            If Asmsx_DownloadExe(G_Status)
              AsmsxCfg_Load()
              KnownExePath = AsmsxCfg\ExePath
              SetGadgetText(G_ExePath, AsmsxCfg\ExePath)
              SetGadgetText(G_VersionInfo, Asmsx_VersionStatusText())
            EndIf
            DisableGadget(G_Download, #False)
            DisableGadget(G_Save, #False)
            DisableGadget(G_Cancel, #False)

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
      AsmsxCfg\Version = "" ; caminho trocado a mao - versao desconhecida
    EndIf
    AsmsxCfg\ExePath = NewExePath
    AsmsxCfg\OptZilog = GetGadgetState(G_Zilog)
    AsmsxCfg\OptSilent = GetGadgetState(G_Silent)
    AsmsxCfg\OptVerbose = GetGadgetState(G_Verbose)
    AsmsxCfg\OutputPath = GetGadgetText(G_OutputPath)
    AsmsxCfg_Save(OverridePath)
  EndIf

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
