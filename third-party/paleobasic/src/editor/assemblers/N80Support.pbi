;
; ------------------------------------------------------------
;  Suporte ao N80/LinkStor80/LibStor80 (github.com/Konamiman/Nestor80 - mesmo
;  autor do NestorBASIC ja suportado, "Konamiman"). Os 3 programas moram no
;  MESMO repositorio, mas em release tags DIFERENTES (N80 e a release mais
;  recente do repo; LinkStor80/LK80 e LibStor80/LB80 sao releases proprias,
;  mais antigas - confirmado varrendo o historico de releases via API:
;  "n80-v1.3.5" pro N80 mais recente, "n80-v1.3.3-lk80-v1.1" pro LK80 mais
;  recente, "lb80-v1.0" pro LB80). Por isso o download NAO pode usar
;  GET /releases/latest (so devolveria N80) - precisa varrer GET /releases
;  (lista completa) procurando o asset de cada prefixo.
;
;  "Configurar -> N80..." baixa as 3 versoes standalone (SelfContained) +
;  gera "Ajuda -> N80..." com um topico por ferramenta (saida de --help) mais
;  a referencia de linguagem do N80 e o manual M80L80 (docs/MACRO-80.txt no
;  proprio repositorio - "Microsoft M80 DOC", bate exatamente com "M80L80";
;  existe tambem docs/asmlnk.txt mas e o manual do ASxxxx/ASLINK do SDCC, sem
;  relacao - nao e baixado).
; ------------------------------------------------------------
;

;- ------------------------------------------------------------
;- Configuracoes / persistencia
;- ------------------------------------------------------------

Structure N80Settings
  N80Path.s
  N80Version.s
  LK80Path.s
  LK80Version.s
  LB80Path.s
  LB80Version.s
EndStructure
Global N80Cfg.N80Settings

Procedure.s N80_ToolDir()
  ProcedureReturn GetPathPart(ProgramFilename()) + "editor\tools\n80\"
EndProcedure

Procedure.s N80_HelpDir()
  ProcedureReturn N80_ToolDir() + "help\"
EndProcedure

; OverridePath (opcional): ver comentario equivalente de BadigCfg_FilePath()
; (BadigSettings.pbi) - "" = caminho global de sempre, senao usa esse
; caminho direto (config por-projeto, "Configurar -> Projeto...").
Procedure.s N80Cfg_FilePath(OverridePath.s = "")
  If OverridePath <> ""
    ProcedureReturn OverridePath
  EndIf
  ProcedureReturn GetPathPart(ProgramFilename()) + "editor\n80_settings.json"
EndProcedure

Procedure N80Cfg_Load(OverridePath.s = "")
  N80Cfg\N80Path = "" : N80Cfg\N80Version = ""
  N80Cfg\LK80Path = "" : N80Cfg\LK80Version = ""
  N80Cfg\LB80Path = "" : N80Cfg\LB80Version = ""

  Protected FilePath.s = N80Cfg_FilePath(OverridePath)
  If FileSize(FilePath) <= 0
    ProcedureReturn
  EndIf

  Protected Json = LoadJSON(#PB_Any, FilePath)
  If Not Json
    ProcedureReturn
  EndIf

  Protected Root = JSONValue(Json)
  Protected M
  M = GetJSONMember(Root, "N80Path")     : If M : N80Cfg\N80Path     = GetJSONString(M) : EndIf
  M = GetJSONMember(Root, "N80Version")  : If M : N80Cfg\N80Version  = GetJSONString(M) : EndIf
  M = GetJSONMember(Root, "LK80Path")    : If M : N80Cfg\LK80Path    = GetJSONString(M) : EndIf
  M = GetJSONMember(Root, "LK80Version") : If M : N80Cfg\LK80Version = GetJSONString(M) : EndIf
  M = GetJSONMember(Root, "LB80Path")    : If M : N80Cfg\LB80Path    = GetJSONString(M) : EndIf
  M = GetJSONMember(Root, "LB80Version") : If M : N80Cfg\LB80Version = GetJSONString(M) : EndIf
  FreeJSON(Json)
EndProcedure

Procedure N80Cfg_Save(OverridePath.s = "")
  Protected Json = CreateJSON(#PB_Any)
  Protected Root = SetJSONObject(JSONValue(Json))
  SetJSONString(AddJSONMember(Root, "N80Path"), N80Cfg\N80Path)
  SetJSONString(AddJSONMember(Root, "N80Version"), N80Cfg\N80Version)
  SetJSONString(AddJSONMember(Root, "LK80Path"), N80Cfg\LK80Path)
  SetJSONString(AddJSONMember(Root, "LK80Version"), N80Cfg\LK80Version)
  SetJSONString(AddJSONMember(Root, "LB80Path"), N80Cfg\LB80Path)
  SetJSONString(AddJSONMember(Root, "LB80Version"), N80Cfg\LB80Version)
  SaveJSON(Json, N80Cfg_FilePath(OverridePath), #PB_JSON_PrettyPrint)
  FreeJSON(Json)
EndProcedure

;- ------------------------------------------------------------
;- Download
;- ------------------------------------------------------------

Structure N80_ResolvedAsset
  Url.s
  Version.s
EndStructure

Procedure.s N80_ExtractVersion(AssetName.s, Prefix.s, Suffix.s)
  ProcedureReturn Mid(AssetName, Len(Prefix) + 1, Len(AssetName) - Len(Prefix) - Len(Suffix))
EndProcedure

; Varre TODAS as releases do repo (uma unica chamada, per_page=100 cobre o
; historico inteiro - confirmado, so tem ~15 releases desde a v1.0 original)
; e acha, pra cada um dos 3 prefixos, o asset standalone (SelfContained) mais
; recente pro SO atual - "mais recente" e garantido pela API ja devolver as
; releases em ordem do mais novo pro mais velho, entao so guarda o PRIMEIRO
; match de cada prefixo.
Procedure.b N80_ResolveAllAssets(*OutN80.N80_ResolvedAsset, *OutLK80.N80_ResolvedAsset, *OutLB80.N80_ResolvedAsset)
  Protected JsonText.s = ExtTool_HttpGetText("https://api.github.com/repos/Konamiman/Nestor80/releases?per_page=100")
  If JsonText = ""
    ProcedureReturn #False
  EndIf

  Protected JsonHandle = ParseJSON(#PB_Any, JsonText)
  If Not JsonHandle
    ProcedureReturn #False
  EndIf

  Protected OsRid.s
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    OsRid = "win-x64"
  CompilerElse
    OsRid = "linux-x64"
  CompilerEndIf
  Protected Suffix.s = "_SelfContained_" + OsRid + ".zip"

  Protected Root = JSONValue(JsonHandle)
  Protected N = JSONArraySize(Root)
  Protected Ri, Rel, AssetsElem, Ai, AN, Item, NameM, UrlM, Name.s
  For Ri = 0 To N - 1
    Rel = GetJSONElement(Root, Ri)
    If Not Rel : Continue : EndIf
    AssetsElem = GetJSONMember(Rel, "assets")
    If Not AssetsElem : Continue : EndIf
    AN = JSONArraySize(AssetsElem)
    For Ai = 0 To AN - 1
      Item = GetJSONElement(AssetsElem, Ai)
      If Not Item : Continue : EndIf
      NameM = GetJSONMember(Item, "name")
      If Not NameM : Continue : EndIf
      Name = GetJSONString(NameM)
      If Right(Name, Len(Suffix)) <> Suffix
        Continue
      EndIf
      UrlM = GetJSONMember(Item, "browser_download_url")
      If Not UrlM : Continue : EndIf

      If Left(Name, 4) = "N80_" And *OutN80\Url = ""
        *OutN80\Url = GetJSONString(UrlM)
        *OutN80\Version = N80_ExtractVersion(Name, "N80_", Suffix)
      ElseIf Left(Name, 5) = "LK80_" And *OutLK80\Url = ""
        *OutLK80\Url = GetJSONString(UrlM)
        *OutLK80\Version = N80_ExtractVersion(Name, "LK80_", Suffix)
      ElseIf Left(Name, 5) = "LB80_" And *OutLB80\Url = ""
        *OutLB80\Url = GetJSONString(UrlM)
        *OutLB80\Version = N80_ExtractVersion(Name, "LB80_", Suffix)
      EndIf
    Next
  Next

  FreeJSON(JsonHandle)
  ProcedureReturn #True
EndProcedure

Procedure.s N80_FindExe(BaseName.s)
  Protected Dir.s = N80_ToolDir()
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    If FileSize(Dir + BaseName + ".exe") > 0 : ProcedureReturn Dir + BaseName + ".exe" : EndIf
  CompilerElse
    If FileSize(Dir + BaseName) > 0 : ProcedureReturn Dir + BaseName : EndIf
  CompilerEndIf
  ProcedureReturn ""
EndProcedure

; "Melhor esforco" de leve normalizacao do manual M80L80 (texto plano de
; largura fixa, sem estrutura Markdown nenhuma - CHAPTER/secoes sao so linhas
; centralizadas em CAIXA ALTA): qualquer linha com pelo menos 1 letra e SEM
; nenhuma letra minuscula vira um titulo "## " (pega "CHAPTER 1", "NOTE",
; "2.1  RUNNING MACRO-80", titulos de secao etc.); o resto do texto fica
; intocado (preserva alinhamento de colunas dos exemplos de codigo, que
; reformatar quebraria).
Procedure.s N80_NormalizeMacro80Text(Text.s)
  Protected Out.s = ""
  Protected LineCount = CountString(Text, Chr(10)) + 1
  Protected i, Line.s, Trimmed.s, IsHeading.b, HasLetter.b, c.s, j

  For i = 1 To LineCount
    Line = ReplaceString(StringField(Text, i, Chr(10)), Chr(13), "")
    Trimmed = Trim(Line)

    IsHeading = #False
    If Trimmed <> "" And Len(Trimmed) <= 60
      IsHeading = #True
      HasLetter = #False
      For j = 1 To Len(Trimmed)
        c = Mid(Trimmed, j, 1)
        If c >= "a" And c <= "z"
          IsHeading = #False
          Break
        EndIf
        If c >= "A" And c <= "Z"
          HasLetter = #True
        EndIf
      Next
      If Not HasLetter
        IsHeading = #False
      EndIf
    EndIf

    If IsHeading
      Out + "## " + Trimmed + #CRLF$
    Else
      Out + Line + #CRLF$
    EndIf
  Next

  ProcedureReturn Out
EndProcedure

Procedure N80_SaveHelpTopic(HelpDir.s, FileName.s, Title.s, Group.s, Body.s, List Topics.GenMdHelp_TopicItem())
  Protected FNum = CreateFile(#PB_Any, HelpDir + FileName)
  If Not FNum
    ProcedureReturn
  EndIf
  WriteString(FNum, Body)
  CloseFile(FNum)
  AddElement(Topics())
  Topics()\File  = FileName
  Topics()\Title = Title
  Topics()\Group = Group
EndProcedure

; Baixa N80+LinkStor80+LibStor80 (standalone) + gera a Ajuda (--help de cada
; um + LanguageReference/WritingRelocatableCode do N80 + manual M80L80).
; StatusGadget pode ser 0 (chamada sem UI) - ver ExtTool_SetStatus().
Procedure.b N80_Download(StatusGadget)
  ExtTool_SetStatus(StatusGadget, "Consultando releases no GitHub (N80/LinkStor80/LibStor80)...")
  Protected N80Asset.N80_ResolvedAsset, LK80Asset.N80_ResolvedAsset, LB80Asset.N80_ResolvedAsset
  If Not N80_ResolveAllAssets(@N80Asset, @LK80Asset, @LB80Asset)
    ExtTool_SetStatus(StatusGadget, "Falha ao consultar o GitHub (verifique sua conexao).")
    ProcedureReturn #False
  EndIf
  If N80Asset\Url = "" Or LK80Asset\Url = "" Or LB80Asset\Url = ""
    ExtTool_SetStatus(StatusGadget, "Nao achei os 3 assets standalone esperados nas releases do repositorio.")
    ProcedureReturn #False
  EndIf

  Protected ToolDir.s = N80_ToolDir()

  ExtTool_SetStatus(StatusGadget, "Baixando N80 " + N80Asset\Version + "...")
  If Not ExtTool_DownloadAndExtractZip(N80Asset\Url, ToolDir)
    ExtTool_SetStatus(StatusGadget, "Falha ao baixar/descompactar o N80.")
    ProcedureReturn #False
  EndIf

  ExtTool_SetStatus(StatusGadget, "Baixando LinkStor80 " + LK80Asset\Version + "...")
  If Not ExtTool_DownloadAndExtractZip(LK80Asset\Url, ToolDir)
    ExtTool_SetStatus(StatusGadget, "Falha ao baixar/descompactar o LinkStor80.")
    ProcedureReturn #False
  EndIf

  ExtTool_SetStatus(StatusGadget, "Baixando LibStor80 " + LB80Asset\Version + "...")
  If Not ExtTool_DownloadAndExtractZip(LB80Asset\Url, ToolDir)
    ExtTool_SetStatus(StatusGadget, "Falha ao baixar/descompactar o LibStor80.")
    ProcedureReturn #False
  EndIf

  Protected N80Exe.s = N80_FindExe("N80")
  Protected LK80Exe.s = N80_FindExe("LK80")
  Protected LB80Exe.s = N80_FindExe("LB80")
  If N80Exe = "" Or LK80Exe = "" Or LB80Exe = ""
    ExtTool_SetStatus(StatusGadget, "Pacotes baixados, mas algum executavel nao foi encontrado.")
    ProcedureReturn #False
  EndIf

  Protected HelpDir.s = N80_HelpDir()
  CreateDirectory(HelpDir)
  NewList Topics.GenMdHelp_TopicItem()

  ExtTool_SetStatus(StatusGadget, "Gerando referencia de linha de comando do N80...")
  N80_SaveHelpTopic(HelpDir, "n80-cli.md", "Linha de comando (N80 --help)", "N80",
                    "# N80 - referencia de linha de comando" + #CRLF$ + #CRLF$ + "```" + #CRLF$ +
                    ExtTool_RunCaptureOutput(N80Exe, "--help") + "```" + #CRLF$, Topics())

  ExtTool_SetStatus(StatusGadget, "Baixando referencia de linguagem do N80...")
  Protected LangRef.s = ExtTool_HttpGetText("https://raw.githubusercontent.com/Konamiman/Nestor80/master/docs/LanguageReference.md")
  If LangRef <> ""
    N80_SaveHelpTopic(HelpDir, "n80-language-reference.md", "Referencia da linguagem", "N80", LangRef, Topics())
  EndIf

  Protected WritingRel.s = ExtTool_HttpGetText("https://raw.githubusercontent.com/Konamiman/Nestor80/master/docs/WritingRelocatableCode.md")
  If WritingRel <> ""
    N80_SaveHelpTopic(HelpDir, "n80-writing-relocatable-code.md", "Escrevendo codigo relocavel", "N80", WritingRel, Topics())
  EndIf

  ExtTool_SetStatus(StatusGadget, "Gerando referencia de linha de comando do LinkStor80...")
  N80_SaveHelpTopic(HelpDir, "lk80-cli.md", "Linha de comando (LK80 --help)", "LinkStor80",
                    "# LinkStor80 - referencia de linha de comando" + #CRLF$ + #CRLF$ + "```" + #CRLF$ +
                    ExtTool_RunCaptureOutput(LK80Exe, "--help") + "```" + #CRLF$, Topics())

  ExtTool_SetStatus(StatusGadget, "Gerando referencia de linha de comando do LibStor80...")
  N80_SaveHelpTopic(HelpDir, "lb80-cli.md", "Linha de comando (LB80 --help)", "LibStor80",
                    "# LibStor80 - referencia de linha de comando" + #CRLF$ + #CRLF$ + "```" + #CRLF$ +
                    ExtTool_RunCaptureOutput(LB80Exe, "--help") + "```" + #CRLF$, Topics())

  ExtTool_SetStatus(StatusGadget, "Baixando manual M80L80...")
  Protected Macro80Raw.s = ExtTool_HttpGetText("https://raw.githubusercontent.com/Konamiman/Nestor80/master/docs/MACRO-80.txt")
  If Macro80Raw <> ""
    N80_SaveHelpTopic(HelpDir, "m80l80-manual.md", "Manual M80L80 (MACRO-80/LINK-80/CREF-80/LIB-80)", "M80L80",
                      "# Manual M80L80 - Microsoft MACRO-80 / LINK-80 / CREF-80 / LIB-80" + #CRLF$ + #CRLF$ +
                      "Fonte original: docs/MACRO-80.txt no repositorio do N80 - texto de largura fixa " +
                      "convertido com normalizacao leve (titulos detectados por linhas so em CAIXA ALTA)." +
                      #CRLF$ + #CRLF$ + N80_NormalizeMacro80Text(Macro80Raw), Topics())
  EndIf

  GenMdHelp_SaveIndex(HelpDir, Topics())

  N80Cfg\N80Path  = N80Exe  : N80Cfg\N80Version  = N80Asset\Version
  N80Cfg\LK80Path = LK80Exe : N80Cfg\LK80Version = LK80Asset\Version
  N80Cfg\LB80Path = LB80Exe : N80Cfg\LB80Version = LB80Asset\Version
  N80Cfg_Save()

  ExtTool_SetStatus(StatusGadget, "Concluido: N80 " + N80Asset\Version + ", LinkStor80 " + LK80Asset\Version +
                                  ", LibStor80 " + LB80Asset\Version + " instalados em " + ToolDir)
  ProcedureReturn #True
EndProcedure

;- ------------------------------------------------------------
;- Tela "Configurar -> N80..."
;- ------------------------------------------------------------

; OverridePath (opcional): ver BadigCfg_OpenSettingsWindow() (BadigSettings.pbi)
; pro mesmo padrao - aqui so troca de onde N80Cfg_Load() le no momento de
; abrir a janela (nao ha campo editavel nesta tela alem do proprio download,
; que continua salvando global de proposito - N80 ainda nao tem nenhum
; consumidor de config por-projeto, ver ProjectSettingsGui.pbi).
Procedure N80Settings_OpenWindow(ParentWindow, OverridePath.s = "")
  N80Cfg_Load(OverridePath)

  Protected WinW = 640, WinH = 336
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Configurar - N80",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  TextGadget(#PB_Any, 24, 24, WinW - 48, 40,
            "N80 (Nestor80), LinkStor80 e LibStor80 - assembler/linker/biblioteca Z80" + Chr(10) +
            "compativeis com MACRO-80/LINK-80/LIB-80. github.com/Konamiman/Nestor80")

  Protected G_Installed = TextGadget(#PB_Any, 24, 80, WinW - 48, 40, "")
  If N80Cfg\N80Path <> "" And FileSize(N80Cfg\N80Path) > 0
    SetGadgetText(G_Installed,
                 "N80 " + N80Cfg\N80Version + " / LinkStor80 " + N80Cfg\LK80Version +
                 " / LibStor80 " + N80Cfg\LB80Version + Chr(10) + N80_ToolDir())
  Else
    SetGadgetText(G_Installed, "Nao instalado ainda.")
  EndIf

  Protected G_Download = ThemedButton(24, 140, 280, 28, "Baixar versoes mais recentes", "")
  Protected G_Status = TextGadget(#PB_Any, 24, 188, WinW - 48, 60, "")

  Protected G_Close = ThemedButton(WinW - 24 - 110, WinH - 56, 110, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_Download
            DisableGadget(G_Download, #True)
            DisableGadget(G_Close, #True)
            If N80_Download(G_Status)
              N80Cfg_Load()
              SetGadgetText(G_Installed,
                           "N80 " + N80Cfg\N80Version + " / LinkStor80 " + N80Cfg\LK80Version +
                           " / LibStor80 " + N80Cfg\LB80Version + Chr(10) + N80_ToolDir())
            EndIf
            DisableGadget(G_Download, #False)
            DisableGadget(G_Close, #False)

          Case G_Close
            Quit = #True
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
