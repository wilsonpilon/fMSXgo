;
; ------------------------------------------------------------
;  Basic Dignified Editor
;  Editor de codigos para o dialeto MSX-BASIC do Basic Dignified Suite.
;  Escrito em PureBasic (Windows / Linux).
;  Realce de sintaxe via ScintillaGadget e pre-processador/tokenizador
;  Basic Dignified nativos (sem Python) em DignifiedPreprocessor.pbi/
;  MsxTokenizer.pbi.
; ------------------------------------------------------------
;

EnableExplicit

; Referenciada em EditorSettings.pbi (botao "Baixar fontes...") mas definida em
; FontDownloader.pbi, que precisa vir depois (usa EditorCfg_NormalizeDir e
; BadigCfg_ExtractZip) - forward declaration para quebrar a dependencia circular.
Declare.s FontDownloader_OpenWindow(ParentWindow, InitialFolder.s)

; Referenciada pelo botao "Injetar" do editor de sprites (SpriteEditorGui.pbi,
; incluido antes de Docs()/ActiveSciGadget() existirem) mas definida so mais
; abaixo neste arquivo - mesma forward declaration de FontDownloader_OpenWindow
; acima, mesmo motivo (dependencia circular do include).
Declare.b InjectTextAtCursor(Text.s)

; Referenciada pelos dialogos de "Abrir"/"Salvar como" do editor de alfabetos
; (CharsetEditorGui.pbi) e do fluxo de projeto mais abaixo - mesmo motivo das
; duas declaracoes acima (definida so mais abaixo neste arquivo).
Declare.s EnsureExtension(Path.s, Ext.s)

; Referenciada pelas janelas de disco/sprite/alfabeto/configuracoes
; (DiskManagerGui.pbi, SpriteEditorGui.pbi, CharsetEditorGui.pbi,
; BadigSettings.pbi, EditorSettings.pbi, FontDownloader.pbi, todas incluidas
; antes da definicao mais abaixo) - mesmo motivo das declaracoes acima.
Declare App_ApplyWindowIcon(WinNum)

; Referenciada pelo botao "Ajuda" do console do openMSX (OpenMSXConsoleGui.pbi,
; incluido bem antes de OpenMsxHelpGui.pbi, onde a janela de verdade e
; definida) - mesmo motivo das declaracoes acima.
Declare OpenMsxHelp_OpenWindow(ParentWindow)

; Referenciada pelo botao "Transferir programa atual" do console do openMSX
; (OpenMSXConsoleGui.pbi, incluido bem antes desta definicao "de verdade" mais
; abaixo neste arquivo) - mesmo motivo das declaracoes acima.
Declare RunBasicFromActiveTab()

; Referenciada pelo comando G do Mamute Assembler (MamuteGui_CmdG,
; MamuteAssemblerGui.pbi) mas definida em MamuteDebuggerGui.pbi, incluido
; DEPOIS (precisa da Structure MamuteGui_State, definida em
; MamuteAssemblerGui.pbi, e do nucleo MamuteZ80Cpu.pbi) - mesmo motivo das
; declaracoes acima, so que na direcao contraria (usado antes de definido).
; *State fica sem tipo aqui de proposito - a Structure MamuteGui_State ainda
; nao existe neste ponto do arquivo, e um ponteiro cru basta pro Declare (o
; tipo real e resolvido na definicao completa, em MamuteDebuggerGui.pbi).
Declare MamuteDebugger_Open(ParentWindow, *State, StartAddr.u)

; Mesmo motivo do Declare acima - Mz80_ExecuteOne() so' e' definida "de
; verdade" em MamuteZ80Cpu.pbi (precisa da Structure MamuteGui_State e do
; nucleo de decodificacao inteiro), mas o comando XGO (MamuteGui_CmdXgo/
; MamuteGui_XgoRunLoop, MamuteAssemblerGui.pbi, docs/SPEC.md modulo 45j) e'
; incluido ANTES e precisa chama-la em loop pra rodar o programa.
Declare Mz80_ExecuteOne(*S)

; Mesmo motivo dos Declare acima - Mamute_TranslatedNotesFilePath()/
; Mamute_ProtectTranslatedNotesIfPicked() so' sao definidas "de verdade" em
; MamuteNotesData.pbi, mas MamuteSettings_OpenWindow() (MamuteSupport.pbi,
; "Configurar -> Mamute Assembler...", docs/SPEC.md modulo 45y) e' incluida
; ANTES e precisa chama-las pro campo "Notas SUPER-X padrao".
Declare.s Mamute_TranslatedNotesFilePath()
Declare.s Mamute_ProtectTranslatedNotesIfPicked(PickedPath.s)

; Mesmo motivo do Declare acima - MamuteGui_AppendLog() so' e' definida "de
; verdade" dentro de MamuteAssemblerGui.pbi (mais abaixo), mas MamuteXmGui.pbi
; (comando XM, docs/SPEC.md modulo 45) precisa chama-la e e' incluido ANTES.
Declare.s MamuteGui_AppendLog(G_Log, Accum.s, Text.s)

; Mesmo motivo de novo - MamuteXm_Open() so' e' definida "de verdade" dentro
; de MamuteXmGui.pbi, mas MamuteXdGui.pbi (comando XD, botao "Multi" da cruz
; de modos, docs/SPEC.md modulo 45f) e' incluido ANTES e precisa chamar ela
; pra trocar de janela sem fechar/reabrir "por fora". MamuteSxTarget ja
; existe nesse ponto (MamuteSupport.pbi, incluido bem antes dos dois).
Declare.i MamuteXm_Open(ParentWindow, StartAddr.i, *Target.MamuteSxTarget)

; Mesmo motivo de novo, sentido INVERSO desta vez - MamuteXa_Open() so' e'
; definida "de verdade" dentro de MamuteXaGui.pbi (comando XA, modulo 45h),
; mas MamuteXdGui.pbi (comando XD, botao "Ascii" da cruz de modos, agora
; ligado de verdade pro XA) e' incluido ANTES e precisa chamar ela.
Declare.i MamuteXa_Open(ParentWindow, StartAddr.i, *Target.MamuteSxTarget)

; Mesmo motivo de novo - MamuteXi_Open() so' e' definida "de verdade" dentro
; de MamuteXiGui.pbi (comando XI, modulo 45i), mas MamuteXdGui.pbi/
; MamuteXaGui.pbi (botao "Disasm" da cruz de modos, agora ligado de verdade
; pro XI nos dois) sao incluidos ANTES e precisam chamar ela.
Declare.i MamuteXi_Open(ParentWindow, StartAddr.i, *Target.MamuteSxTarget)

; Mesmo motivo de novo - MamuteXh_Open() so' e' definida "de verdade" dentro
; de MamuteXhGui.pbi (comando XH, o editor de caracteres/sprites do SUPER-X -
; o ultimo placeholder "Char" da cruz de modos), mas MamuteXdGui.pbi/
; MamuteXaGui.pbi/MamuteXiGui.pbi (botao "Char" da cruz, agora ligado de
; verdade pro XH nos tres) sao incluidos ANTES e precisam chamar ela.
Declare.i MamuteXh_Open(ParentWindow, StartAddr.i, *Target.MamuteSxTarget)

; Structure EditorSettings/Global EditorCfg (definidos "de verdade" em
; EditorSettings.pbi, incluido logo abaixo) e os globais Color_* (tab bar/
; regua/sintaxe da area de edicao, preenchidos por ApplyTheme() mais adiante
; neste arquivo de acordo com EditorCfg\Theme) precisam estar aqui, ANTES do
; primeiro XIncludeFile - com EnableExplicit, ThemedButtons.pbi (incluido
; logo depois de EditorSettings.pbi) ja le EditorCfg\FontName/IconFontName e
; os Color_* dentro de ThemedUI_CreateButtonImage(), e a declaracao Global
; precisa aparecer antes textualmente (XIncludeFile e so inclusao textual -
; mesmo motivo dos Declare de procedure acima, so que pra Global/Structure).
Structure EditorSettings
  FontName.s
  FontSize.i
  FontFolder.s    ; pasta com .ttf/.otf/.ttc customizados (opcional)
  EditorPath.s    ; "onde o editor reside" (sempre termina com separador) - nao move o .exe, so serve de base para outros defaults
  Theme.s         ; um dos 4 IDs de EditorCfg_ThemeIdByIndex() (Snow/Paper/Mist/Linen) - so
                  ; temas claros desde a 7.33.10 (os 5 escuros foram removidos: o texto nativo
                  ; nao-tematizavel de checkbox/combobox/listview/scrollbar - so os botoes,
                  ; via ThemedButton, sao redesenhados - ficava com contraste ruim contra
                  ; fundo escuro; contra fundo claro o mesmo cinza nativo passa despercebido)
  Style.s         ; "Modern" ou "Classic" (formato das abas)
  IconFontName.s  ; override do nome de fonte de icones (Nerd Font); "" = usa o nome em
                  ; #EdFont_BundledIconFontName (fonte de icones empacotada em editor/fonts/,
                  ; ver EditorCfg_LoadCustomFonts()) quando IconsEnabled = #True
  IconsEnabled.b  ; #True (padrao) = botoes tematizados mostram icone (ThemedUI_CreateButtonImage,
                  ; ThemedButtons.pbi); #False = "(Nenhuma - usa texto)" escolhido nas Configuracoes
EndStructure

Global EditorCfg.EditorSettings
Global NewList CustomFontResources.s()   ; caminhos registrados via AddFontResourceEx, para poder remover ao trocar de pasta

; Nome de familia exato da fonte empacotada em editor/fonts/SymbolsNerdFontMono-Regular.ttf
; (conferido com System.Drawing.Text.PrivateFontCollection) - usada como fonte de icones
; padrao quando IconsEnabled = #True e IconFontName nao tem um override explicito. Precisa
; estar declarada aqui (antes do primeiro XIncludeFile) porque ThemedButtons.pbi a le dentro
; de ThemedUI_GetIconFont(), mesmo motivo de EditorCfg/Color_* acima.
#EdFont_BundledIconFontName = "Symbols Nerd Font Mono"

Global Color_AppBg, Color_EditorBg, Color_TabInactive, Color_TabHover
Global Color_TextActive, Color_TextInactive, Color_Accent, Color_CloseHover
Global Color_RulerBg, Color_RulerText, Color_RulerTick

Global Color_Syntax_Default, Color_Syntax_Comment, Color_Syntax_String
Global Color_Syntax_Statement, Color_Syntax_Operator, Color_Syntax_Function
Global Color_Syntax_Number, Color_Syntax_Label, Color_Syntax_DignifiedStmt
Global Color_Syntax_MsxBas2Rom
Global Color_Syntax_Remtag, Color_Caret, Color_SelBack, Color_LineNumberFore

; Abre uma janela filha com o chrome padrao da IDE (cor de fundo + icone via
; App_ApplyWindowIcon, ainda so forward-declarada aqui - Declare acima cobre
; isso) - toda janela "Criar -> X.../Configurar -> X..." repetia essa mesma
; sequencia de 4 linhas antes de cada uma. Devolve 0 em caso de falha, mesmo
; contrato de OpenWindow(). Com Modal=#True (padrao), tambem desabilita
; ParentWindow - use Modal=#False pra uma janela nao-bloqueante (ex.:
; visualizador que pode ficar aberto junto com o resto da IDE, ver
; MdViewerGui.pbi). O motivo do DisableWindow(ParentWindow) em si (nao so
; deste helper, de toda janela secundaria do app): o loop de eventos e
; compartilhado (WaitWindowEvent() pega evento de QUALQUER janela aberta),
; entao sem desabilitar a janela principal os cliques/teclas nela ficariam
; "perdidos" (chegam no loop da janela secundaria, que nao sabe tratar os
; gadgets dela) em vez de irem pro loop principal - pareceria travada.
; CloseModelessChildWindow() desfaz simetricamente no fechamento - precisa
; vir ANTES do primeiro XIncludeFile (mesmo motivo dos Declare/Global/
; Structure acima: EnableExplicit + inclusao textual exige declaracao antes
; de qualquer arquivo que a use). ApplyBg=#False cobre a unica excecao real
; (BadigCfg_ChooseXmlName, BadigSettings.pbi - uma janela picker pequena
; dominada por uma ListViewGadget que nunca chamou SetWindowColor()).
Procedure.i OpenModelessChildWindow(ParentWindow, X, Y, WinW, WinH, Title.s, Flags, Modal.b = #True, ApplyBg.b = #True)
  Protected Win = OpenWindow(#PB_Any, X, Y, WinW, WinH, Title, Flags)
  If Not Win
    ProcedureReturn 0
  EndIf
  If ApplyBg
    SetWindowColor(Win, Color_AppBg)
  EndIf
  App_ApplyWindowIcon(Win)
  If Modal
    DisableWindow(ParentWindow, #True)
  EndIf
  ProcedureReturn Win
EndProcedure

Procedure CloseModelessChildWindow(ParentWindow, Win, Modal.b = #True)
  If Modal
    DisableWindow(ParentWindow, #False)
  EndIf
  CloseWindow(Win)
EndProcedure

; Primeiro de todos os XIncludeFile de proposito: precisa vir antes de
; qualquer arquivo de janela/dialogo (todos usam a Macro ThemedButton() pra
; nao ficar com chrome nativo do Windows - ver ThemedButtons.pbi).
XIncludeFile "core/ThemedButtons.pbi"

XIncludeFile "core/MsxTokenizer.pbi"
XIncludeFile "core/DignifiedPreprocessor.pbi"
XIncludeFile "assemblers/Z80Asm.pbi"
XIncludeFile "core/EditorSettings.pbi"
XIncludeFile "core/BadigSettings.pbi"
XIncludeFile "basic/BasicOptionsSettings.pbi"
XIncludeFile "assemblers/AssemblyOptionsSettings.pbi"
XIncludeFile "emulators/OpenMsxSettingsGui.pbi"
; Precisa vir antes de FontDownloader.pbi - reaproveita ExtTool_HttpGetText/
; ExtTool_DownloadAndExtractZip/ExtTool_FlushEvents em vez de duplica-las (so
; depende de BadigCfg_ExtractZip, ja incluido acima via BadigSettings.pbi).
XIncludeFile "core/ExternalToolDownload.pbi"
XIncludeFile "core/FontDownloader.pbi"
XIncludeFile "core/CharMapGui.pbi"
XIncludeFile "core/MSXDisk.pbi"
XIncludeFile "core/DiskManagerGui.pbi"
XIncludeFile "emulators/OpenMSXBridge.pbi"
XIncludeFile "emulators/OpenMSXConsoleGui.pbi"
XIncludeFile "core/ProjectDB.pbi"
XIncludeFile "visual_editors/SpriteEditorGui.pbi"
XIncludeFile "visual_editors/CharsetEditorGui.pbi"
XIncludeFile "visual_editors/AquarelaCharsetEditorGui.pbi"
XIncludeFile "visual_editors/PsgSynth.pbi"
XIncludeFile "visual_editors/PsgEditorGui.pbi"
XIncludeFile "visual_editors/MmlSynth.pbi"
XIncludeFile "visual_editors/MmlEditorGui.pbi"
XIncludeFile "visual_editors/SeeTrackerDriverAsm.pbi"
XIncludeFile "visual_editors/SeeTrackerSynth.pbi"
XIncludeFile "visual_editors/SeeTrackerEditorGui.pbi"
XIncludeFile "visual_editors/Screen2Synth.pbi"
XIncludeFile "visual_editors/Screen2EditorGui.pbi"
XIncludeFile "visual_editors/Screen0EditorGui.pbi"
XIncludeFile "visual_editors/Screen1EditorGui.pbi"
XIncludeFile "visual_editors/Screen12EditorGui.pbi"
XIncludeFile "visual_editors/GraphosNativeIO.pbi"
XIncludeFile "visual_editors/GraphosScreenGui.pbi"
XIncludeFile "assemblers/Z80Link.pbi"
XIncludeFile "assemblers/Z80Lib.pbi"
XIncludeFile "assemblers/Z80OutputGui.pbi"
XIncludeFile "assemblers/Z80LinkGui.pbi"
XIncludeFile "assemblers/Z80LibGui.pbi"
XIncludeFile "assemblers/Z80SubProject.pbi"
XIncludeFile "assemblers/Z80SubProjectGui.pbi"
XIncludeFile "basic/NestorBasicSupport.pbi"
XIncludeFile "basic/NestorBasicHelpData.pbi"
XIncludeFile "basic/NestorBasicHelpGui.pbi"
XIncludeFile "help/MsxBasicDictData.pbi"
XIncludeFile "help/MsxBasic2PlusDictData.pbi"
XIncludeFile "help/MsxBasicManualData.pbi"
XIncludeFile "help/MsxBasic2PlusManualData.pbi"
XIncludeFile "help/MsxBasicHelpGui.pbi"
XIncludeFile "help/BasicDignifiedHelpData.pbi"
XIncludeFile "help/BasicDignifiedHelpGui.pbi"
XIncludeFile "visual_editors/SeeTrackerHelpData.pbi"
XIncludeFile "visual_editors/SeeTrackerHelpGui.pbi"
XIncludeFile "help/OpenMsxHelpData.pbi"
XIncludeFile "help/OpenMsxHelpGui.pbi"
XIncludeFile "help/MsxManualsHelpData.pbi"
XIncludeFile "help/MsxManualsHelpGui.pbi"
XIncludeFile "help/MsxSoftwareHelpData.pbi"
XIncludeFile "help/MsxSoftwareHelpGui.pbi"
XIncludeFile "help/BiosCallsHelpData.pbi"
XIncludeFile "help/BiosCallsHelpGui.pbi"
XIncludeFile "help/HardwareHelpData.pbi"
XIncludeFile "help/HardwareHelpGui.pbi"
XIncludeFile "help/BiosDocHelpData.pbi"
XIncludeFile "help/BiosDocHelpGui.pbi"
XIncludeFile "help/RedBookHelpData.pbi"
XIncludeFile "help/RedBookHelpGui.pbi"
XIncludeFile "help/Th2HandbookHelpData.pbi"
XIncludeFile "help/Th2HandbookHelpGui.pbi"
XIncludeFile "help/GenericMdHelpGui.pbi"
XIncludeFile "core/EditorHelpGui.pbi"
XIncludeFile "basic/MsxBas2RomSupport.pbi"
XIncludeFile "assemblers/N80Support.pbi"
XIncludeFile "assemblers/AsmsxSupport.pbi"
XIncludeFile "assemblers/AsmsxHelpData.pbi"
XIncludeFile "assemblers/AsmsxHelpGui.pbi"
XIncludeFile "assemblers/MamuteSupport.pbi"
XIncludeFile "assemblers/MamuteNotesData.pbi"
XIncludeFile "assemblers/MamuteHelpData.pbi"
XIncludeFile "assemblers/MamuteSuperXNotesHelpData.pbi"
XIncludeFile "assemblers/MamuteHelpGui.pbi"
XIncludeFile "assemblers/MamuteDumpGui.pbi"
XIncludeFile "assemblers/MamuteZapGui.pbi"
XIncludeFile "assemblers/MamuteScrGui.pbi"
XIncludeFile "assemblers/MamuteSaveGui.pbi"
XIncludeFile "assemblers/MamuteMGui.pbi"
XIncludeFile "assemblers/MamuteXdGui.pbi"
XIncludeFile "assemblers/MamuteXaGui.pbi"
XIncludeFile "assemblers/MamuteXiGui.pbi"
XIncludeFile "assemblers/MamuteXmGui.pbi"
XIncludeFile "assemblers/MamuteXhGui.pbi"
XIncludeFile "assemblers/MamuteXtpGui.pbi"
XIncludeFile "assemblers/MamuteXirGui.pbi"
XIncludeFile "assemblers/MamuteIoGui.pbi"
XIncludeFile "assemblers/MamutePdf.pbi"
XIncludeFile "assemblers/MamuteEditGui.pbi"
XIncludeFile "assemblers/MamuteAssemblerGui.pbi"
XIncludeFile "assemblers/MamuteZ80Cpu.pbi"
XIncludeFile "assemblers/MamuteDebuggerGui.pbi"
XIncludeFile "core/ProjectSettingsGui.pbi"
XIncludeFile "core/FileAssociationGui.pbi"

;- ------------------------------------------------------------
;- CLI de manipulacao de disco MSX: "PaleoBasic.exe --diskmanipulator
;- <comando> <disco.dsk> [argumentos...]" - mesmos comandos/sintaxe do
;- msxdisk.exe original (msxDiskUtil/msxdisk.pb), rodando com o modulo
;- MSXDisk.pbi ja incorporado no proprio executavel (sem chamar msxdisk.exe
;- como processo externo). Detectada e tratada bem no inicio do programa
;- principal (ver "Programa principal", perto do fim do arquivo), antes de
;- qualquer janela ser aberta.
;- ------------------------------------------------------------

Procedure CliShowHelp()
  PrintN("MSX Disk Manager (embutido no Paleobasic)")
  PrintN("Uso: PaleoBasic.exe --diskmanipulator <comando> <imagem_disco.dsk> [argumentos...]")
  PrintN("")
  PrintN("Comandos disponiveis:")
  PrintN("  create <disk.dsk> [bootsector.bin]")
  PrintN("            Cria uma nova imagem de disco MSX em branco (720KB).")
  PrintN("            Opcionalmente, pode ser informado um setor de boot customizado.")
  PrintN("")
  PrintN("  list <disk.dsk> [-l]")
  PrintN("            Lista os arquivos contidos no disco.")
  PrintN("            Use '-l' para visualizacao detalhada (tamanho, data/hora).")
  PrintN("")
  PrintN("  add <disk.dsk> <local_file1> [local_file2 ...]")
  PrintN("            Adiciona um ou mais arquivos locais ao disco MSX.")
  PrintN("            Suporta curingas locais (ex: *.TXT, *.BAS).")
  PrintN("")
  PrintN("  extract <disk.dsk> [-d out_dir] [mask1 mask2 ...]")
  PrintN("            Extrai arquivos do disco MSX.")
  PrintN("            Use '-d out_dir' para especificar a pasta de destino.")
  PrintN("            Opcionalmente, passe mascaras de arquivos (ex: *.BAS, AUTOEXEC.BAT).")
  PrintN("")
  PrintN("  delete <disk.dsk> <filename>")
  PrintN("            Exclui um arquivo da imagem de disco MSX.")
  PrintN("")
EndProcedure

Procedure CliAddFilesWithWildcards(FilePattern.s)
  Protected Dir.s = GetPathPart(FilePattern)
  Protected Pattern.s = GetFilePart(FilePattern)

  If Dir = ""
    Dir = "." + #PS$
  EndIf

  If FindString(Pattern, "*") Or FindString(Pattern, "?")
    Protected d = ExamineDirectory(#PB_Any, Dir, Pattern)
    If d
      Protected cnt = 0
      While NextDirectoryEntry(d)
        If DirectoryEntryType(d) = #PB_DirectoryEntry_File
          Protected FileName.s = DirectoryEntryName(d)
          Protected FullPath.s = Dir + FileName
          Print("Adicionando: " + FileName + " ... ")
          If Not MSXDisk::AddFile(FullPath, FileName)
            PrintN("FALHA: " + MSXDisk::GetLastErrorMessage())
          Else
            PrintN("OK")
            cnt + 1
          EndIf
        EndIf
      Wend
      FinishDirectory(d)
      PrintN(Str(cnt) + " arquivo(s) adicionado(s).")
    Else
      PrintN("Nenhum arquivo encontrado correspondendo a: " + FilePattern)
    EndIf
  Else
    Print("Adicionando: " + Pattern + " ... ")
    If Not MSXDisk::AddFile(FilePattern, Pattern)
      PrintN("FALHA: " + MSXDisk::GetLastErrorMessage())
    Else
      PrintN("OK")
      PrintN("1 arquivo adicionado.")
    EndIf
  EndIf
EndProcedure

; Todos os argumentos do msxdisk.exe original ficam deslocados +1 posicao
; aqui dentro, porque ProgramParameter(0) e sempre "--diskmanipulator" (quem
; chama ja conferiu isso antes de entrar aqui).
Procedure.i RunDiskManipulatorCli()
  OpenConsole()

  Protected TotalCount = CountProgramParameters()
  Protected Count = TotalCount - 1
  If Count < 2
    CliShowHelp()
    ProcedureReturn 0
  EndIf

  Protected Cmd.s = LCase(ProgramParameter(1))
  Protected Disk.s = ProgramParameter(2)
  Protected i

  Select Cmd
    Case "create"
      Protected Boot.s = ""
      If Count > 2
        Boot = ProgramParameter(3)
      EndIf

      PrintN("Criando disco: " + Disk + " ...")
      If MSXDisk::CreateDisk(Disk, Boot)
        PrintN("Disco criado e formatado com sucesso (720KB).")
        MSXDisk::CloseDisk()
      Else
        PrintN("Erro ao criar o disco: " + MSXDisk::GetLastErrorMessage())
        ProcedureReturn 1
      EndIf

    Case "list"
      Protected Detailed.b = #False
      If Count > 2 And ProgramParameter(3) = "-l"
        Detailed = #True
      EndIf

      If Not MSXDisk::OpenDisk(Disk)
        PrintN("Erro ao abrir disco: " + MSXDisk::GetLastErrorMessage())
        ProcedureReturn 1
      EndIf

      NewList Files.MSXDisk::FileInfo()
      If MSXDisk::ListFiles(Files())
        If Detailed
          PrintN("Nome         Tamanho     Data / Hora")
          PrintN("---------------------------------------------")
          ForEach Files()
            Protected Dt.s = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Files()\DateTime)
            PrintN(LSet(Files()\FileName, 12) + " " + RSet(Str(Files()\Size), 8) + "    " + Dt)
          Next
        Else
          ForEach Files()
            PrintN(Files()\FileName)
          Next
        EndIf
      Else
        PrintN("Erro ao listar arquivos: " + MSXDisk::GetLastErrorMessage())
      EndIf
      MSXDisk::CloseDisk()

    Case "add"
      If Not MSXDisk::OpenDisk(Disk)
        PrintN("Erro ao abrir disco: " + MSXDisk::GetLastErrorMessage())
        ProcedureReturn 1
      EndIf

      For i = 3 To TotalCount - 1
        CliAddFilesWithWildcards(ProgramParameter(i))
      Next

      MSXDisk::CloseDisk()

    Case "extract"
      Protected OutDir.s = ""
      Protected MaskStart = 3

      If Count > 2 And ProgramParameter(3) = "-d"
        If Count > 3
          OutDir = ProgramParameter(4)
          MaskStart = 5
        Else
          PrintN("Erro: Diretorio de saida nao especificado apos -d.")
          ProcedureReturn 1
        EndIf
      EndIf

      If Not MSXDisk::OpenDisk(Disk)
        PrintN("Erro ao abrir disco: " + MSXDisk::GetLastErrorMessage())
        ProcedureReturn 1
      EndIf

      NewList Masks.s()
      For i = MaskStart To TotalCount - 1
        AddElement(Masks())
        Masks() = MSXDisk::ConvertToFAT11(ProgramParameter(i))
      Next

      If OutDir <> ""
        If FileSize(OutDir) <> -2
          CreateDirectory(OutDir)
        EndIf
        If Right(OutDir, 1) <> #PS$
          OutDir + #PS$
        EndIf
      EndIf

      NewList ExtractFiles.MSXDisk::FileInfo()
      If MSXDisk::ListFiles(ExtractFiles())
        Protected Cnt = 0
        ForEach ExtractFiles()
          Protected Match.b = #False
          If ListSize(Masks()) = 0
            Match = #True
          Else
            ForEach Masks()
              If MSXDisk::MatchesFAT11(MSXDisk::ConvertToFAT11(ExtractFiles()\FileName), Masks())
                Match = #True
                Break
              EndIf
            Next
          EndIf

          If Match
            Protected Dest.s = OutDir + ExtractFiles()\FileName
            Print("Extraindo: " + ExtractFiles()\FileName + " -> " + Dest + " ... ")
            If MSXDisk::ExtractFile(ExtractFiles()\FileName, Dest)
              PrintN("OK")
              Cnt + 1
            Else
              PrintN("FALHA: " + MSXDisk::GetLastErrorMessage())
            EndIf
          EndIf
        Next
        PrintN(Str(Cnt) + " arquivo(s) extraido(s).")
      Else
        PrintN("Erro ao ler arquivos do disco: " + MSXDisk::GetLastErrorMessage())
      EndIf
      MSXDisk::CloseDisk()

    Case "delete"
      If Count < 3
        PrintN("Erro: Nome do arquivo a ser excluido nao informado.")
        ProcedureReturn 1
      EndIf

      Protected FileToDelete.s = ProgramParameter(3)
      If Not MSXDisk::OpenDisk(Disk)
        PrintN("Erro ao abrir disco: " + MSXDisk::GetLastErrorMessage())
        ProcedureReturn 1
      EndIf

      Print("Excluindo: " + FileToDelete + " ... ")
      If MSXDisk::DeleteMSXFile(FileToDelete)
        PrintN("OK")
      Else
        PrintN("FALHA: " + MSXDisk::GetLastErrorMessage())
      EndIf
      MSXDisk::CloseDisk()

    Default
      CliShowHelp()
  EndSelect

  ProcedureReturn 0
EndProcedure

;- ------------------------------------------------------------
;- Constantes gerais
;- ------------------------------------------------------------

Enumeration Windows
  #MainWindow
EndEnumeration

Enumeration Gadgets
  #TabBarGadget
  #RulerGadget
EndEnumeration

Enumeration StatusBars
  #MainStatusBar
EndEnumeration

Enumeration Menus
  #MainMenu
EndEnumeration

Enumeration MenuItems
  #Menu_New
  #Menu_NewAssembly
  #Menu_NewAsmsx
  #Menu_NewNestorBasic
  #Menu_NewMsxBas2Rom
  #Menu_NewMD
  #Menu_NewProject
  #Menu_OpenProject
  #Menu_SaveProject
  #Menu_SaveProjectAs
  #Menu_ProjectIndex
  #Menu_Open
  #Menu_Save
  #Menu_SaveAs
  #Menu_SaveAll
  #Menu_TokenizeNative
  #Menu_RenumberToBas
  #Menu_DignifiedToAscii
  #Menu_DignifiedToTokenized
  #Menu_CloseTab
  #Menu_Exit
  #Menu_Find
  #Menu_FindNext
  #Menu_Replace
  #Menu_GotoLine
  #Menu_CreateDisk
  #Menu_CreateSprite
  #Menu_CreateAlphabet
  #Menu_CreateAlphabetAquarela
  #Menu_CreateSound
  #Menu_CreateMml
  #Menu_CreateScreen2
  #Menu_CreateScreen0
  #Menu_CreateScreen1
  #Menu_CreateScreen12
  #Menu_CreateSeeTracker
  #Menu_CreateZ80Lib
  #Menu_CreateAsmSubProject
  #Menu_CreateGraphosScreen
  #Menu_InsertSpecialChar
  #Menu_RunBasic
  #Menu_RunNestorBasic
  #Menu_CompileMsxBas2RomRom
  #Menu_RenumberBasic
  #Menu_AssembleZ80
  #Menu_AssembleZ80Rel
  #Menu_LinkZ80
  #Menu_AssembleAsmsx
  #Menu_HexEditor
  #Menu_MamuteAssembler
  #Menu_OpenMSXConsole
  #Menu_ViewMdTxt
  #Menu_ViewMdTxtSplit
  #Menu_ConfigureBadig
  #Menu_ConfigureEditor
  #Menu_ConfigureBasicOptions
  #Menu_ConfigureAssemblyOptions
  #Menu_ConfigureMsxBas2Rom
  #Menu_ConfigureN80
  #Menu_ConfigureAsmsx
  #Menu_ConfigureMamuteAssembler
  #Menu_ConfigureOpenMSX
  #Menu_ConfigureFileAssociations
  #Menu_ConfigureProject
  #Menu_HelpEditor
  #Menu_HelpNestorBasic
  #Menu_HelpMsxBasic
  #Menu_HelpManuals
  #Menu_HelpSoftware
  #Menu_HelpBiosCalls
  #Menu_HelpHardware
  #Menu_HelpBiosDoc
  #Menu_HelpRedBook
  #Menu_HelpTh2Handbook
  #Menu_HelpBasicDignified
  #Menu_HelpSeeTracker
  #Menu_HelpMamuteAssembler
  #Menu_HelpOpenMSX
  #Menu_HelpMsxBas2Rom
  #Menu_HelpN80
  #Menu_HelpAsmsx
  #Menu_HelpAbout
EndEnumeration

; Numeros de estilo do Scintilla usados pelo realce de sintaxe.
; 0 (STYLE_DEFAULT) fica reservado para texto/identificadores comuns.
Enumeration 1
  #Style_Comment
  #Style_String
  #Style_Statement
  #Style_Operator
  #Style_Function
  #Style_Number
  #Style_Label
  #Style_DignifiedStmt
  #Style_MsxBas2Rom
  #Style_Remtag
  #Style_MdHeading1
  #Style_MdHeading2
  #Style_MdHeading3
  #Style_MdBold
  #Style_MdCode
  #Style_MdLink
EndEnumeration

#Event_Rehighlight = #PB_Event_FirstCustomValue
#Event_UpdateUI    = #PB_Event_FirstCustomValue + 1
; Disparado de ScintillaCallBack (#SCN_CHARADDED) e tratado no loop principal -
; nao pode chamar ScintillaSendMessage direto de dentro da notificacao (ver
; comentario em ScintillaCallBack), entao o trabalho real (montar a lista e
; mandar SCI_AUTOCSHOW) e adiado igual ao #Event_Rehighlight.
#Event_AutoComplete = #PB_Event_FirstCustomValue + 3

#App_Title      = "Paleobasic"
#App_SplashW    = 600  ; splash na abertura (paleobasic.png, 3:2) - ver App_ShowSplash/App_CloseSplash
#App_SplashH    = 400
#App_SplashMinMs = 2200
#File_Pattern     = "MSX-BASIC Dignified (*.dmx)|*.dmx|MSX Basic ASCII (*.amx)|*.amx|Todos os arquivos (*.*)|*.*"
#File_Pattern_ASM = "Z80 Assembly (*.asm)|*.asm|Todos os arquivos (*.*)|*.*"
#File_Pattern_MD  = "Markdown (*.md)|*.md|Todos os arquivos (*.*)|*.*"
#File_Pattern_Project = "Projeto MSX (*.msxproject)|*.msxproject|Todos os arquivos (*.*)|*.*"
#File_Pattern_Open = "Todos os suportados (*.dmx;*.amx;*.asm;*.md)|*.dmx;*.amx;*.asm;*.md|" +
                     "MSX-BASIC Dignified (*.dmx)|*.dmx|MSX Basic ASCII (*.amx)|*.amx|" +
                     "Z80 Assembly (*.asm)|*.asm|Markdown (*.md)|*.md|Todos os arquivos (*.*)|*.*"

; Versao/build normalmente injetadas via build.ps1 (/CONSTANT App_Version=...,
; -Version/-BuildDate) - fallback aqui so para compilar direto pela IDE do
; PureBasic (F5), fora do build.ps1.
; 7.7.1 = codinome "BFG9200" (pedido explicito do usuario) - BFG9000 do Doom
; cruzado com 9200h, o endereco de VRAM (Alfabeto/Layout/Tela do Graphos III)
; que virou a assinatura daquela sessao (galeria de templates do Editor Hexa).
; 7.9.1 = bump pedido explicitamente pelo usuario ao fechar Renumerar (RENUM),
; integracao MSXBas2Rom/N80-LinkStor80-LibStor80 e destaque de sintaxe do
; MSXBas2Rom - sem codinome novo desta vez.
; 7.25.0 = codinome "HEXORCIST" (pedido explicito do usuario) - Hex do Editor
; Hexa + Exorcist, sessao inteira sobre reconhecer (esconjurar) formatos
; binarios que antes caiam em "dados crus": .COM, SuperCalc 2 (.CAL), dBase
; II (.DBF) e os 4 formatos nativos do Graphos III (.ALF/.LAY/.SCR/.SHP).
CompilerIf Not Defined(App_Version, #PB_Constant)
  #App_Version = "8.1.6"
CompilerEndIf
CompilerIf Not Defined(App_Build, #PB_Constant)
  #App_Build = "DEV"
CompilerEndIf
CompilerIf Not Defined(App_BuildDate, #PB_Constant)
  #App_BuildDate = "compilado fora do build.ps1"
CompilerEndIf

; Tab bar / regua de colunas - abas customizadas (com botao de fechar) desenhadas
; num CanvasGadget, no lugar do PanelGadget nativo (que nao suporta isso e tem
; visual datado demais nas 3 plataformas).
#TabBar_Height   = 36
#Ruler_Height    = 20
#Tab_PadX        = 14
#Tab_MinWidth    = 90
#Tab_MaxWidth    = 220
#Tab_CloseSize   = 14
#Tab_CloseGap    = 10
#Tab_Gap         = 2

; Global Color_* (tab bar/regua/sintaxe) e Structure EditorSettings/Global
; EditorCfg moveram pro topo deste arquivo (antes do primeiro XIncludeFile) -
; ThemedButtons.pbi ja usa os dois desde bem cedo na cadeia de includes. Ver
; comentario la em cima.
XIncludeFile "core/HexEditorGui.pbi"

; Preenche todos os globais Color_* acima de acordo com EditorCfg\Theme (um
; dos 7 IDs de EditorCfg_ThemeIdByIndex() em EditorSettings.pbi). Paletas
; desenhadas e aprovadas fora do PureBasic (mockup HTML) antes de virar
; codigo - ver docs/RELEASE_NOTES.md pela origem/inspiracao de cada uma.
; Default (tema desconhecido/settings.json corrompido) cai em Graphite.
Procedure ApplyTheme()
  Select EditorCfg\Theme
    Case "Snow"
      Color_AppBg        = RGB(242, 243, 245)
      Color_EditorBg      = RGB(255, 255, 255)
      Color_TabInactive   = RGB(230, 232, 236)
      Color_TabHover      = RGB(217, 220, 226)
      Color_TextActive    = RGB(38, 42, 51)
      Color_TextInactive  = RGB(107, 114, 128)
      Color_Accent        = RGB(52, 104, 192)
      Color_CloseHover    = RGB(194, 59, 82)
      Color_RulerBg       = RGB(237, 238, 241)
      Color_RulerText     = RGB(118, 124, 136)
      Color_RulerTick     = RGB(213, 216, 222)

      Color_Syntax_Default       = RGB(43, 47, 56)
      Color_Syntax_Comment       = RGB(138, 143, 156)
      Color_Syntax_String        = RGB(47, 125, 79)
      Color_Syntax_Statement     = RGB(154, 63, 160)
      Color_Syntax_Operator      = RGB(194, 59, 82)
      Color_Syntax_Function      = RGB(52, 104, 192)
      Color_Syntax_Number        = RGB(176, 106, 18)
      Color_Syntax_Label         = RGB(156, 124, 10)
      Color_Syntax_DignifiedStmt = RGB(195, 61, 111)
      Color_Syntax_MsxBas2Rom    = RGB(0, 131, 143)
      Color_Syntax_Remtag        = RGB(165, 118, 12)
      Color_Caret                = RGB(0, 0, 0)
      Color_SelBack               = RGB(207, 224, 251)
      Color_LineNumberFore       = RGB(144, 152, 166)

    Case "Mist"
      Color_AppBg        = RGB(230, 236, 244)
      Color_EditorBg      = RGB(255, 255, 255)
      Color_TabInactive   = RGB(214, 224, 236)
      Color_TabHover      = RGB(198, 211, 227)
      Color_TextActive    = RGB(30, 41, 59)
      Color_TextInactive  = RGB(100, 116, 139)
      Color_Accent        = RGB(37, 99, 235)
      Color_CloseHover    = RGB(220, 38, 38)
      Color_RulerBg       = RGB(222, 230, 240)
      Color_RulerText     = RGB(100, 116, 139)
      Color_RulerTick     = RGB(196, 208, 224)

      Color_Syntax_Default       = RGB(30, 41, 59)
      Color_Syntax_Comment       = RGB(115, 130, 150)
      Color_Syntax_String        = RGB(21, 128, 91)
      Color_Syntax_Statement     = RGB(126, 34, 172)
      Color_Syntax_Operator      = RGB(190, 40, 60)
      Color_Syntax_Function      = RGB(37, 99, 235)
      Color_Syntax_Number        = RGB(180, 90, 20)
      Color_Syntax_Label         = RGB(146, 108, 10)
      Color_Syntax_DignifiedStmt = RGB(180, 50, 110)
      Color_Syntax_MsxBas2Rom    = RGB(0, 121, 133)
      Color_Syntax_Remtag        = RGB(150, 105, 15)
      Color_Caret                = RGB(0, 0, 0)
      Color_SelBack               = RGB(196, 214, 245)
      Color_LineNumberFore       = RGB(130, 142, 160)

    Case "Linen"
      Color_AppBg        = RGB(244, 236, 245)
      Color_EditorBg      = RGB(253, 249, 253)
      Color_TabInactive   = RGB(231, 218, 233)
      Color_TabHover      = RGB(219, 201, 223)
      Color_TextActive    = RGB(51, 39, 54)
      Color_TextInactive  = RGB(126, 108, 130)
      Color_Accent        = RGB(147, 51, 179)
      Color_CloseHover    = RGB(200, 50, 90)
      Color_RulerBg       = RGB(236, 226, 238)
      Color_RulerText     = RGB(126, 108, 130)
      Color_RulerTick     = RGB(213, 196, 216)

      Color_Syntax_Default       = RGB(51, 39, 54)
      Color_Syntax_Comment       = RGB(140, 122, 144)
      Color_Syntax_String        = RGB(60, 130, 80)
      Color_Syntax_Statement     = RGB(147, 51, 179)
      Color_Syntax_Operator      = RGB(190, 45, 100)
      Color_Syntax_Function      = RGB(110, 70, 190)
      Color_Syntax_Number        = RGB(178, 96, 20)
      Color_Syntax_Label         = RGB(150, 105, 15)
      Color_Syntax_DignifiedStmt = RGB(190, 55, 130)
      Color_Syntax_MsxBas2Rom    = RGB(10, 130, 125)
      Color_Syntax_Remtag        = RGB(150, 105, 15)
      Color_Caret                = RGB(0, 0, 0)
      Color_SelBack               = RGB(224, 200, 230)
      Color_LineNumberFore       = RGB(150, 135, 155)

    Case "Paper"
      Color_AppBg        = RGB(236, 225, 204)
      Color_EditorBg      = RGB(244, 236, 220)
      Color_TabInactive   = RGB(227, 213, 184)
      Color_TabHover      = RGB(216, 200, 165)
      Color_TextActive    = RGB(60, 50, 37)
      Color_TextInactive  = RGB(138, 122, 92)
      Color_Accent        = RGB(181, 101, 29)
      Color_CloseHover    = RGB(179, 69, 47)
      Color_RulerBg       = RGB(232, 220, 192)
      Color_RulerText     = RGB(138, 122, 92)
      Color_RulerTick     = RGB(211, 193, 156)

      Color_Syntax_Default       = RGB(60, 50, 37)
      Color_Syntax_Comment       = RGB(156, 138, 104)
      Color_Syntax_String        = RGB(92, 122, 60)
      Color_Syntax_Statement     = RGB(154, 78, 158)
      Color_Syntax_Operator      = RGB(179, 69, 47)
      Color_Syntax_Function      = RGB(47, 111, 143)
      Color_Syntax_Number        = RGB(181, 101, 29)
      Color_Syntax_Label         = RGB(151, 131, 31)
      Color_Syntax_DignifiedStmt = RGB(161, 61, 99)
      Color_Syntax_MsxBas2Rom    = RGB(28, 138, 130)
      Color_Syntax_Remtag        = RGB(138, 109, 31)
      Color_Caret                = RGB(0, 0, 0)
      Color_SelBack               = RGB(217, 196, 143)
      Color_LineNumberFore       = RGB(165, 148, 110)

    Default ; "Snow" e qualquer valor desconhecido/legado (ex.: settings.json
             ; salvo por uma versao anterior aos 4 temas, com um dos 5 IDs
             ; escuros removidos - EditorCfg_Load() ja migra esses IDs para um
             ; dos 4 atuais antes de ApplyTheme() ser chamado, entao este
             ; Default so deveria disparar num corrompimento direto do JSON)
      Color_AppBg        = RGB(242, 243, 245)
      Color_EditorBg      = RGB(255, 255, 255)
      Color_TabInactive   = RGB(230, 232, 236)
      Color_TabHover      = RGB(217, 220, 226)
      Color_TextActive    = RGB(38, 42, 51)
      Color_TextInactive  = RGB(107, 114, 128)
      Color_Accent        = RGB(52, 104, 192)
      Color_CloseHover    = RGB(194, 59, 82)
      Color_RulerBg       = RGB(237, 238, 241)
      Color_RulerText     = RGB(118, 124, 136)
      Color_RulerTick     = RGB(213, 216, 222)

      Color_Syntax_Default       = RGB(43, 47, 56)
      Color_Syntax_Comment       = RGB(138, 143, 156)
      Color_Syntax_String        = RGB(47, 125, 79)
      Color_Syntax_Statement     = RGB(154, 63, 160)
      Color_Syntax_Operator      = RGB(194, 59, 82)
      Color_Syntax_Function      = RGB(52, 104, 192)
      Color_Syntax_Number        = RGB(176, 106, 18)
      Color_Syntax_Label         = RGB(156, 124, 10)
      Color_Syntax_DignifiedStmt = RGB(195, 61, 111)
      Color_Syntax_MsxBas2Rom    = RGB(0, 131, 143)
      Color_Syntax_Remtag        = RGB(165, 118, 12)
      Color_Caret                = RGB(0, 0, 0)
      Color_SelBack               = RGB(207, 224, 251)
      Color_LineNumberFore       = RGB(144, 152, 166)
  EndSelect
EndProcedure

;- ------------------------------------------------------------
;- Estruturas e listas globais
;- ------------------------------------------------------------

Structure Document
  Path.s            ; caminho completo no disco, vazio se ainda nao foi salvo
  Mode.s            ; "DMX" (MSX-BASIC/Dignified, default) ou "ASM" (Z80 Assembly)
  Modified.b        ; 1 se ha alteracoes nao salvas
  SciGadget.i       ; ScintillaGadget associado a esta aba
  UntitledName.s    ; nome estavel ("nonameN"), so usado enquanto Path = ""
  DisplayCaption.s  ; rotulo ja computado (nome + " *" se modificado), cache para RedrawTabBar
  TabX1.i           ; retangulo da aba inteira na tab bar (hit-test de clique/hover)
  TabX2.i
  CloseX1.i         ; retangulo do botao "x" de fechar, dentro da aba
  CloseX2.i
EndStructure

Global NewList Docs.Document()
Global UntitledCount = 0
Global NestorBasicUntitledCount = 0   ; contador separado pra "nbasic1.dmx", "nbasic2.dmx"... (ver AddDocumentTab)
Global ActiveTabPosition.i = -1
Global HoverTabPosition.i = -1
Global HoverCloseTabPosition.i = -1

; Enquanto verdadeiro, mudancas de texto no Scintilla nao marcam o
; documento como modificado (usado ao carregar conteudo programaticamente).
Global SuppressModifiedTracking.b = #False

; --- INSTRUMENTACAO TEMPORARIA (investigacao do bug "abas somem") ---------
; Log de diagnostico gravado ao lado do .exe (tabdebug.log) - WriteStringN +
; FlushFileBuffers em vez de Debug/PrintN (ver CLAUDE.md: PrintN/Debug nao
; aparecem de forma confiavel a partir deste processo). REMOVER depois que o
; bug for identificado.
Global TabDebugFile.i = 0
Procedure TabDebugLog(Msg.s)
  If Not TabDebugFile
    TabDebugFile = OpenFile(#PB_Any, GetPathPart(ProgramFilename()) + "tabdebug.log", #PB_File_Append)
  EndIf
  If TabDebugFile
    WriteStringN(TabDebugFile, FormatDate("%hh:%ii:%ss.", Date()) + RSet(Str(ElapsedMilliseconds() % 1000), 3, "0") + "  " + Msg)
    FlushFileBuffers(TabDebugFile)
  EndIf
EndProcedure

; Tabelas de palavras-chave do dialeto MSX-BASIC/Dignified, usadas tanto
; pelo realce de sintaxe quanto como base para a futura tokenizacao.
Global NewMap KwStatement.b()
Global NewMap KwFunctionPlain.b()
Global NewMap KwFunctionDollar.b()
Global NewMap KwOperatorWord.b()
Global NewMap KwDignifiedStmt.b()
Global NewMap KwBoolean.b()

; Nomes dos wrappers ".NB_*" do NestorBASIC (ver NestorBasicSupport.pbi/
; NestorBasicHelpData.pbi) - guardados SEM o "." inicial (o "." nao entra na
; nocao de "palavra" do Scintilla, entao o prefixo digitado que dispara o
; auto completar ja chega sem ele, ver ShowAutoComplete) - preenchido em
; InitKeywordMaps() a partir de NBHelp_Topics()\Wrapper, fonte unica com a
; janela de ajuda (evita manter uma segunda lista igual e desalinhada).
; NestorBASIC nao tem um Mode proprio (o template "Novo Nestor Basic..." cria
; um documento "DMX" comum, so com o texto dos wrappers ja colado dentro) -
; entao esses nomes ficam sempre disponiveis em documentos DMX, igual
; KwDignifiedStmt.
Global NewMap KwNestorBasic.b()

; Extensoes de vocabulario do MSXBAS2ROM (github.com/amaurycarvalho/msxbas2rom
; - ver editor/MsxBas2RomSupport.pbi), so usadas quando o documento esta em
; modo "BAS" (ver HighlightDocument/HighlightDignifiedText, e Dig_IsReservedWord
; em DignifiedPreprocessor.pbi) - um programa Dignified/.dmx comum pode
; perfeitamente ter uma variavel chamada TURBO ou COLLISION, entao essas
; palavras so viram destaque de palavra-chave/palavra reservada nos arquivos
; que sao de fato projetos MSXBAS2ROM. Lista extraida do conteudo real
; baixado em "Configurar -> MSXBas2Rom... -> Baixar" (tools/msxbas2rom/help/
; extended-commands.md e extended-functions.md). Mapas declarados em
; DignifiedPreprocessor.pbi (nao aqui) - precisam existir la pra harnesses
; standalone (DigTestCli.pb) que so incluem aquele arquivo; a populacao
; abaixo via FillKeywordMap() e redundante com a de Dig_InitReservedKw()
; (idempotente, ambas convivem sem problema) e garante que o destaque de
; sintaxe funcione mesmo antes do usuario rodar qualquer acao Dignified.

; Vocabulario do lexer de Z80 Assembly (modo "ASM" dos documentos) mora em
; Z80Asm.pbi (Z80Asm::IsMnemonic()/IsRegister()/IsDirective()/IsOperatorWord(),
; Z80Asm::InitKeywordMaps()) - fonte unica compartilhada com o motor do
; assembler, ver docs/resumo-asm.md. Copias locais abaixo (preenchidas em
; InitKeywordMaps() via Z80Asm::MnemonicList()/RegisterList()/DirectiveList()/
; OperatorWordList()) sao so pro auto completar (ShowAutoComplete) - os Maps
; de verdade continuam privados dentro do Module, ver comentario deles la.
Global NewMap KwZ80Mnemonic.b()
Global NewMap KwZ80Register.b()
Global NewMap KwZ80Directive.b()
Global NewMap KwZ80OperatorWord.b()

;- ------------------------------------------------------------
;- Declaracoes
;- ------------------------------------------------------------

Declare   FillKeywordMap(Map Dest.b(), Words.s)
Declare   InitKeywordMaps()
Declare.s ReadSciText(Sci)
Declare   WriteSciText(Sci, Text.s)
Declare   EmitRun(Sci, Text.s, Style)
Declare.b IsAlphaChar(C.s)
Declare.b IsDigitChar(C.s)
Declare.b IsWordChar(C.s)
Declare   HighlightDocument(Sci)
Declare   HighlightDignifiedText(Sci, Text.s, IsMsxBas2Rom.b = #False)
Declare   HighlightZ80Text(Sci, Text.s)
Declare   HighlightMarkdownInline(Sci, LineText.s, BaseStyle)
Declare   HighlightMarkdownText(Sci, Text.s)
Declare   SetupEditorStyles(Sci)
Declare   UpdateLineNumberMargin(Sci)
Declare   ActiveSciGadget()
Declare   UpdateStatusBar()
Declare   ScintillaCallBack(Gadget, *scinotify.SCNotification)
Declare.b IsReservedKeyword(WordUpper.s, IsMsxBas2Rom.b = #False)
Declare.s GetSciTextRange(Sci, StartPos, EndPos)
Declare.s ApplyKeywordCase(Word.s, Prefix.s, CaseMode.s)
Declare.i AutoCompleteMinCharsForGadget(Sci)
Declare   ShowAutoComplete(Sci)
Declare   HandleAutoCompleteCharAdded(Sci, CharCode)
Declare   Editor_Find()   ; EditorSearch.pbi (incluido no fim do arquivo)
Declare   Editor_FindNext()
Declare   Editor_Replace()
Declare   Editor_GotoLine()
Declare   MdView_OpenSingle(ParentWindow)  ; MdViewerGui.pbi (incluido no fim do arquivo)
Declare   MdView_OpenSplit(ParentWindow)
Declare   ProjIndex_OpenWindow(ParentWindow)  ; ProjectIndexGui.pbi (incluido no fim do arquivo)
Declare.s ComputeTabCaption(Position)
Declare   RedrawTabBar()
Declare   RedrawRuler()
Declare   SetActiveTab(Position)
Declare   AddDocumentTab(Path.s = "", Content.s = "", Mode.s = "DMX", UntitledBase.s = "noname")
Declare   FindDocumentByGadget(GadgetNum)
Declare   UpdateTabCaption(Position)
Declare   OpenDocumentDialog()
Declare.b SaveDocument(SaveAs.b = #False)
Declare.b ConfirmDiscard(Text.s)
Declare.b SaveProject(SaveAsFlag.b = #False)
Declare.b OfferSaveProject()
Declare.b SaveAllDocuments()
Declare   CloseTab(Position)
Declare   SaveAsTokenizedNative()
Declare   SaveAsAsciiFromDignified()
Declare   SaveAsTokenizedFromDignified()
Declare   RunOnOpenMSX(BaseName.s, DmxText.s, AsciiText.s, HexOut.s, IncludeNestorBasic.b = #False)
Declare   Dig_SyncConfigFromBadigCfg()
Declare   ResizeInterface()

;- ------------------------------------------------------------
;- Palavras-chave do dialeto (classicas MSX-BASIC + Dignified)
;- ------------------------------------------------------------

Procedure FillKeywordMap(Map Dest.b(), Words.s)
  Protected Count = CountString(Words, " ") + 1
  Protected Idx, Word.s
  For Idx = 1 To Count
    Word = StringField(Words, Idx, " ")
    If Word <> ""
      Dest(Word) = #True
    EndIf
  Next
EndProcedure

Procedure InitKeywordMaps()
  ; Instrucoes/comandos classicos do MSX-BASIC (incluindo os de desvio)
  FillKeywordMap(KwStatement(),
    "AS AUTO BEEP BLOAD BSAVE CALL CIRCLE CLEAR CLOAD CLOSE CLS CMD COLOR " +
    "CONT COPY CSAVE CSRLIN DATA DEF DEFDBL DEFINT DEFSNG DEFSTR DELETE DIM " +
    "DRAW DSKO ELSE END ERASE ERROR FIELD FILES FOR GET GOSUB GOTO IF INPUT " +
    "IPL KANJI KEY KILL LET LINE LIST LLIST LOAD LOCATE LPRINT LSET " +
    "MAXFILES MERGE MOTOR NAME NEW NEXT OFF ON OPEN OUT OUTPUT PAINT PLAY " +
    "POINT POKE PRESET PRINT PSET PUT READ RENUM RESTORE RESUME RETURN " +
    "RSET RUN SAVE SCREEN SET SOUND SPRITE STEP STOP SWAP THEN TO TROFF " +
    "TRON USING VPOKE WAIT WIDTH")

  ; Funcoes classicas sem sufixo $
  FillKeywordMap(KwFunctionPlain(),
    "ABS ASC ATN BASE CDBL CINT COS CSNG CVD CVI CVS DATE DSKF EOF ERL ERR " +
    "EXP FIX FN FPOS FRE INP INSTR INTERVAL INT LEN LOC LOF LOG LPOS PAD " +
    "PDL PEEK POS RND SGN SIN SPC SQR STICK STRIG TAB TAN TIME USR VAL " +
    "VARPTR VDP VPEEK")

  ; Funcoes classicas com sufixo $ (nome base, sem o $)
  FillKeywordMap(KwFunctionDollar(),
    "ATTR BIN CHR DSKI HEX INKEY INPUT LEFT MID MKD MKI MKS OCT RIGHT " +
    "SPACE SPRITE STR STRING")

  ; Operadores logicos (por extenso)
  FillKeywordMap(KwOperatorWord(), "AND OR NOT XOR MOD EQV IMP")

  ; Instrucoes exclusivas do Basic Dignified
  FillKeywordMap(KwDignifiedStmt(), "DEFINE DECLARE INCLUDE KEEP ENDIF FUNC RET EXIT")

  ; Booleanos do Basic Dignified
  FillKeywordMap(KwBoolean(), "TRUE FALSE")

  ; Wrappers ".NB_*" do NestorBASIC - NBHelp_BuildData() e idempotente (so
  ; monta NBHelp_Topics() na primeira chamada, ver seu proprio guard), entao
  ; chamar aqui garante a lista pronta mesmo se a janela de ajuda nunca foi
  ; aberta nesta sessao. Wrapper.s vem com o "." na frente e, em topicos com
  ; mais de uma variante (ex.: funcoes 50/51), varios nomes separados por
  ; " / " - separa tudo, tira o "." e ignora topicos sem wrapper (introducao/
  ; grupo, Wrapper.s = "").
  NBHelp_BuildData()
  ClearMap(KwNestorBasic())
  Protected NBTopic.i, NBPart.i, NBName.s
  ForEach NBHelp_Topics()
    If NBHelp_Topics()\Wrapper <> ""
      For NBPart = 1 To CountString(NBHelp_Topics()\Wrapper, "/") + 1
        NBName = Trim(StringField(NBHelp_Topics()\Wrapper, NBPart, "/"))
        If Left(NBName, 1) = "."
          NBName = Mid(NBName, 2)
        EndIf
        If NBName <> ""
          KwNestorBasic(NBName) = #True
        EndIf
      Next
    EndIf
  Next

  ; MSXBAS2ROM - diretivas de recurso (compile-time, mesmo estilo visual das
  ; diretivas Dignified - INCLUDE ja e compartilhado com KwDignifiedStmt)
  FillKeywordMap(KwMsxBas2RomDirective(), "FILE TEXT")

  ; MSXBAS2ROM - comandos estendidos (sub-comandos de CMD, palavras de
  ; comandos compostos tipo "SET TILE PATTERN"/"SCREEN PASTE FROM", e
  ; instrucoes novas tipo IDATA/IREAD/IRESTORE/IPOKE)
  FillKeywordMap(KwMsxBas2RomStatement(),
    "KEYCLKOFF CLRKEY RUNASM RUNBAS MUTE RAMTOVRAM VRAMTORAM RAMTORAM RSCTORAM " +
    "DISSCR ENASCR PAGE CLRSCR SETFNT UPDFNTCLR CLIP WRTVRAM WRTFNT WRTCHR " +
    "WRTCLR WRTSCR WRTSPR WRTSPRPAT WRTSPRCLR WRTSPRATR PLYLOAD PLYSONG " +
    "PLYPLAY PLYMUTE PLYSOUND PLYLOOP PLYREPLAY IPOKE " +
    "FROM SCROLL FONT PATTERN FLIP ROTATE DATE " +
    "IRESTORE IREAD IDATA")

  ; MSXBAS2ROM - funcoes estendidas (HEAP()/MSX()/COLLISION() etc; TILE()/
  ; TURBO() tambem aparecem como parte de comandos tipo "PUT TILE"/"CMD
  ; TURBO" mas ficam so aqui - o lexer nao olha a frente pra saber se vem um
  ; "(" depois, entao um so dos dois estilos vence; funcao foi a escolha)
  FillKeywordMap(KwMsxBas2RomFunctionPlain(),
    "HEAP MSX NTSC TURBO MAKER IPEEK PSG COLLISION RESOURCE RESOURCESIZE " +
    "PLYSTATUS TILE USR0 USR1 USR2 USR3")

  ; Vocabulario do Z80 (modo "ASM") - copia local achatada, ver comentario
  ; dos Maps KwZ80* acima.
  FillKeywordMap(KwZ80Mnemonic(), Z80Asm::MnemonicList())
  FillKeywordMap(KwZ80Register(), Z80Asm::RegisterList())
  FillKeywordMap(KwZ80Directive(), Z80Asm::DirectiveList())
  FillKeywordMap(KwZ80OperatorWord(), Z80Asm::OperatorWordList())
EndProcedure

;- ------------------------------------------------------------
;- Acesso ao texto do ScintillaGadget (UTF-8)
;- ------------------------------------------------------------

Procedure.s ReadSciText(Sci)
  Protected ByteLen = ScintillaSendMessage(Sci, #SCI_GETTEXTLENGTH)
  Protected *Buffer, Result.s
  If ByteLen <= 0
    ProcedureReturn ""
  EndIf
  *Buffer = AllocateMemory(ByteLen + 1)
  If *Buffer
    ScintillaSendMessage(Sci, #SCI_GETTEXT, ByteLen + 1, *Buffer)
    Result = PeekS(*Buffer, -1, #PB_UTF8)
    FreeMemory(*Buffer)
  EndIf
  ProcedureReturn Result
EndProcedure

Procedure WriteSciText(Sci, Text.s)
  Protected *Buffer = UTF8(Text)
  ScintillaSendMessage(Sci, #SCI_SETTEXT, 0, *Buffer)
  FreeMemory(*Buffer)
EndProcedure

; Aplica um estilo a proxima faixa de bytes, avancando o cursor
; interno de "styling" do Scintilla pelo tamanho (em bytes UTF-8) do texto.
Procedure EmitRun(Sci, Text.s, Style)
  Protected ByteLen = StringByteLength(Text, #PB_UTF8)
  If ByteLen > 0
    ScintillaSendMessage(Sci, #SCI_SETSTYLING, ByteLen, Style)
  EndIf
EndProcedure

Procedure.b IsAlphaChar(C.s)
  ProcedureReturn Bool((C >= "A" And C <= "Z") Or (C >= "a" And C <= "z"))
EndProcedure

Procedure.b IsDigitChar(C.s)
  ProcedureReturn Bool(C >= "0" And C <= "9")
EndProcedure

Procedure.b IsWordChar(C.s)
  ProcedureReturn Bool(IsAlphaChar(C) Or IsDigitChar(C) Or C = "_")
EndProcedure

;- ------------------------------------------------------------
;- Realce de sintaxe (lexer artesanal, executado a cada mudanca)
;- ------------------------------------------------------------

; Despacha para o lexer certo conforme o modo do documento dono deste
; ScintillaGadget ("DMX" = MSX-BASIC/Dignified, "ASM" = Z80 Assembly) -
; margem de numeros de linha e regua sao independentes de modo, ficam aqui.
Procedure HighlightDocument(Sci)
  Protected Text.s = ReadSciText(Sci)

  UpdateLineNumberMargin(Sci)
  If Sci = ActiveSciGadget()
    RedrawRuler()
  EndIf

  If Len(Text) = 0
    ProcedureReturn
  EndIf

  Protected DocPos = FindDocumentByGadget(Sci)
  Protected Mode.s = "DMX"
  If DocPos >= 0 And SelectElement(Docs(), DocPos)
    Mode = Docs()\Mode
  EndIf

  If Mode = "ASM"
    HighlightZ80Text(Sci, Text)
  ElseIf Mode = "MD"
    HighlightMarkdownText(Sci, Text)
  Else
    HighlightDignifiedText(Sci, Text, Bool(Mode = "BAS"))
  EndIf
EndProcedure

Procedure HighlightDignifiedText(Sci, Text.s, IsMsxBas2Rom.b = #False)
  Protected TextLen = Len(Text)
  Protected I = 1
  Protected AtLineStart.b = #True
  Protected InsideExclusiveBlock.b = #False
  Protected InsideRegularBlock.b = #False
  Protected InDataLiteral.b = #False

  Protected C.s, C2.s, Start, Word.s, CommentLen
  Protected PeekStart, PeekEnd, LineRest.s, LineTrim.s, LineTrimUC.s

  ScintillaSendMessage(Sci, #SCI_STARTSTYLING, 0, 0)

  While I <= TextLen
    C = Mid(Text, I, 1)

    ; --- Fim de linha ---
    If C = Chr(13) Or C = Chr(10)
      EmitRun(Sci, C, #Style_Default)
      I + 1
      AtLineStart = #True
      InDataLiteral = #False
      Continue
    EndIf

    ; --- Construcoes ancoradas no inicio da linha ---
    If AtLineStart
      PeekStart = I
      PeekEnd = I
      While PeekEnd <= TextLen And Mid(Text, PeekEnd, 1) <> Chr(13) And Mid(Text, PeekEnd, 1) <> Chr(10)
        PeekEnd + 1
      Wend
      LineRest = Mid(Text, PeekStart, PeekEnd - PeekStart)
      LineTrim = Trim(LineRest)
      LineTrimUC = UCase(LineTrim)

      If Left(LineTrimUC, 5) = "##BB:" Or Left(LineTrimUC, 5) = "##BD:"
        EmitRun(Sci, LineRest, #Style_Remtag)
        I = PeekEnd
        AtLineStart = #False
        Continue
      ElseIf LineTrimUC = "###"
        If InsideExclusiveBlock : InsideExclusiveBlock = #False : Else : InsideExclusiveBlock = #True : EndIf
        EmitRun(Sci, LineRest, #Style_Comment)
        I = PeekEnd
        AtLineStart = #False
        Continue
      ElseIf LineTrimUC = "''"
        If InsideRegularBlock : InsideRegularBlock = #False : Else : InsideRegularBlock = #True : EndIf
        EmitRun(Sci, LineRest, #Style_Comment)
        I = PeekEnd
        AtLineStart = #False
        Continue
      ElseIf InsideExclusiveBlock Or InsideRegularBlock
        EmitRun(Sci, LineRest, #Style_Comment)
        I = PeekEnd
        AtLineStart = #False
        Continue
      ElseIf Left(LineTrimUC, 2) = "##"
        EmitRun(Sci, LineRest, #Style_Comment)
        I = PeekEnd
        AtLineStart = #False
        Continue
      ElseIf LineTrim = "}"
        EmitRun(Sci, LineRest, #Style_Label)
        I = PeekEnd
        AtLineStart = #False
        Continue
      EndIf

      AtLineStart = #False
    EndIf

    ; --- Comentario ' ate o final da linha ---
    If C = "'"
      CommentLen = 0
      While I + CommentLen <= TextLen And Mid(Text, I + CommentLen, 1) <> Chr(13) And Mid(Text, I + CommentLen, 1) <> Chr(10)
        CommentLen + 1
      Wend
      EmitRun(Sci, Mid(Text, I, CommentLen), #Style_Comment)
      I + CommentLen
      Continue
    EndIf

    ; --- Literais de texto "..." ---
    If C = Chr(34)
      Start = I
      I + 1
      While I <= TextLen And Mid(Text, I, 1) <> Chr(34) And Mid(Text, I, 1) <> Chr(13) And Mid(Text, I, 1) <> Chr(10)
        I + 1
      Wend
      If I <= TextLen And Mid(Text, I, 1) = Chr(34)
        I + 1
      EndIf
      EmitRun(Sci, Mid(Text, Start, I - Start), #Style_String)
      Continue
    EndIf

    ; --- Rotulos {nome} ---
    If C = "{"
      Start = I
      I + 1
      While I <= TextLen And Mid(Text, I, 1) <> "}" And Mid(Text, I, 1) <> Chr(13) And Mid(Text, I, 1) <> Chr(10)
        I + 1
      Wend
      If I <= TextLen And Mid(Text, I, 1) = "}"
        I + 1
      EndIf
      EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Label)
      Continue
    EndIf

    ; --- Defines [nome] ---
    If C = "["
      Start = I
      I + 1
      While I <= TextLen And Mid(Text, I, 1) <> "]" And Mid(Text, I, 1) <> Chr(13) And Mid(Text, I, 1) <> Chr(10)
        I + 1
      Wend
      If I <= TextLen And Mid(Text, I, 1) = "]"
        I + 1
      EndIf
      EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Label)
      Continue
    EndIf

    ; --- Chamada de proto-funcao .nome ---
    If C = "." And I < TextLen And IsAlphaChar(Mid(Text, I + 1, 1))
      Start = I
      I + 1
      While I <= TextLen And IsWordChar(Mid(Text, I, 1))
        I + 1
      Wend
      EmitRun(Sci, Mid(Text, Start, I - Start), #Style_DignifiedStmt)
      Continue
    EndIf

    ; --- Toggle de rem #nome ---
    If C = "#" And I < TextLen And IsAlphaChar(Mid(Text, I + 1, 1))
      Start = I
      I + 1
      While I <= TextLen And IsWordChar(Mid(Text, I, 1))
        I + 1
      Wend
      EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Label)
      Continue
    EndIf

    ; --- Identificadores / palavras-chave ---
    If IsAlphaChar(C)
      Start = I
      I + 1
      While I <= TextLen And IsWordChar(Mid(Text, I, 1))
        I + 1
      Wend
      Word = UCase(Mid(Text, Start, I - Start))

      ; Rotulo de loop: nome{ ... }
      If I <= TextLen And Mid(Text, I, 1) = "{"
        I + 1
        EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Label)
        Continue
      EndIf

      If I <= TextLen And Mid(Text, I, 1) = "$"
        If FindMapElement(KwFunctionDollar(), Word)
          I + 1
          EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Function)
          Continue
        ElseIf FindMapElement(KwStatement(), Word)
          EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Statement)
          Continue
        EndIf
      EndIf

      If FindMapElement(KwDignifiedStmt(), Word)
        EmitRun(Sci, Mid(Text, Start, I - Start), #Style_DignifiedStmt)
        Continue
      ElseIf FindMapElement(KwBoolean(), Word)
        EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Number)
        Continue
      ElseIf FindMapElement(KwStatement(), Word)
        EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Statement)
        If Word = "DATA"
          InDataLiteral = #True
        EndIf
        Continue
      ElseIf IsMsxBas2Rom And FindMapElement(KwMsxBas2RomDirective(), Word)
        EmitRun(Sci, Mid(Text, Start, I - Start), #Style_MsxBas2Rom)
        Continue
      ElseIf IsMsxBas2Rom And FindMapElement(KwMsxBas2RomStatement(), Word)
        EmitRun(Sci, Mid(Text, Start, I - Start), #Style_MsxBas2Rom)
        If Word = "IDATA"
          InDataLiteral = #True
        EndIf
        Continue
      ElseIf FindMapElement(KwFunctionPlain(), Word)
        EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Function)
        Continue
      ElseIf IsMsxBas2Rom And FindMapElement(KwMsxBas2RomFunctionPlain(), Word)
        EmitRun(Sci, Mid(Text, Start, I - Start), #Style_MsxBas2Rom)
        Continue
      ElseIf FindMapElement(KwOperatorWord(), Word)
        EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Operator)
        Continue
      Else
        If I <= TextLen And (Mid(Text, I, 1) = "$" Or Mid(Text, I, 1) = "%" Or Mid(Text, I, 1) = "!" Or Mid(Text, I, 1) = "#")
          I + 1
        EndIf
        EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Default)
        Continue
      EndIf
    EndIf

    ; --- Numeros hexadecimais/octais/binarios &H &O &B ---
    If C = "&" And I < TextLen
      C2 = UCase(Mid(Text, I + 1, 1))
      If C2 = "H" Or C2 = "O" Or C2 = "B"
        Start = I
        I + 2
        While I <= TextLen And IsWordChar(Mid(Text, I, 1))
          I + 1
        Wend
        EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Number)
        Continue
      EndIf
    EndIf

    ; --- Numeros decimais/ponto flutuante ---
    If IsDigitChar(C) Or (C = "." And I < TextLen And IsDigitChar(Mid(Text, I + 1, 1)))
      Start = I
      While I <= TextLen And (IsDigitChar(Mid(Text, I, 1)) Or Mid(Text, I, 1) = ".")
        I + 1
      Wend
      If I <= TextLen And (UCase(Mid(Text, I, 1)) = "E" Or UCase(Mid(Text, I, 1)) = "D") And I + 1 <= TextLen And (Mid(Text, I + 1, 1) = "+" Or Mid(Text, I + 1, 1) = "-")
        I + 2
        While I <= TextLen And IsDigitChar(Mid(Text, I, 1))
          I + 1
        Wend
      EndIf
      If I <= TextLen And (Mid(Text, I, 1) = "%" Or Mid(Text, I, 1) = "!" Or Mid(Text, I, 1) = "#")
        I + 1
      EndIf
      EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Number)
      Continue
    EndIf

    ; --- Modo literal de DATA (ate ':' ou fim de linha) ---
    If InDataLiteral And C <> ":"
      Start = I
      While I <= TextLen And Mid(Text, I, 1) <> ":" And Mid(Text, I, 1) <> Chr(13) And Mid(Text, I, 1) <> Chr(10)
        I + 1
      Wend
      EmitRun(Sci, Mid(Text, Start, I - Start), #Style_String)
      Continue
    EndIf

    ; --- Operadores compostos e simbolos ---
    If C = "+" Or C = "-" Or C = "*" Or C = "/" Or C = "^" Or C = "\" Or C = "=" Or C = "<" Or C = ">"
      Start = I
      I + 1
      If I <= TextLen
        C2 = Mid(Text, I, 1)
        If ((C = "+" And (C2 = "+" Or C2 = "=")) Or (C = "-" And (C2 = "-" Or C2 = "=")) Or
            (C = "*" And C2 = "=") Or (C = "/" And C2 = "=") Or (C = "^" And C2 = "=") Or
            (C = "<" And (C2 = ">" Or C2 = "=")) Or (C = ">" And C2 = "="))
          I + 1
        EndIf
      EndIf
      EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Operator)
      InDataLiteral = #False
      Continue
    EndIf

    ; --- Separadores ---
    If C = ":" Or C = "," Or C = ";" Or C = "(" Or C = ")" Or C = "~" Or C = "@"
      EmitRun(Sci, C, #Style_Operator)
      I + 1
      If C = ":"
        InDataLiteral = #False
      EndIf
      Continue
    EndIf

    ; --- Qualquer outro caractere (espacos, etc) ---
    EmitRun(Sci, C, #Style_Default)
    I + 1
  Wend
EndProcedure

;- ------------------------------------------------------------
;- Realce de sintaxe - Z80 Assembly (dialeto N80/Nestor80)
;-
;- Estilos reaproveitados do modo Dignified (mesma paleta, sem globals
;- novos): #Style_Comment (";"), #Style_String ('..'/".."), #Style_Statement
;- (mnemonicos), #Style_Function (registradores/condicoes), #Style_Number
;- (literais numericos em qualquer radix), #Style_Label (rotulos e rotulos
;- relativos ".nome"), #Style_DignifiedStmt (diretivas do assembler,
;- reaproveitado aqui como estilo generico de "diretiva"), #Style_Operator
;- (operadores por extenso e simbolos).
;-
;- Regra de rotulo vs. mnemonico/diretiva na 1a palavra da linha: se a
;- palavra bate com alguma tabela de palavra-chave (diretiva/mnemonico/
;- registrador/operador), usa o estilo correspondente ONDE QUER que apareca
;- na linha; só cai para "rotulo" quando e a PRIMEIRA palavra da linha E nao
;- bate com nenhuma tabela - mesma convencao classica MACRO-80/Z80 (rotulo
;- sem dois-pontos e reconhecido por nao ser palavra reservada, nao por
;- coluna). Cobre tanto "LABEL: LD A,1" quanto "CONST EQU 5" quanto "ORG
;- 100H" (ORG e diretiva conhecida, nao vira rotulo mesmo comecando a linha).
;-
;- Escopo nao coberto (limitacoes conhecidas, aceitas por simplicidade):
;- bloco ".COMMENT <delim>...<delim>" com delimitador arbitrario (so o
;- comentario de linha ";" e reconhecido); precisao total de qual sufixo de
;- radix fecha um literal numerico multi-digito (visualmente inofensivo -
;- o token inteiro ainda e destacado como numero, so a fronteira exata entre
;- "digitos" e "sufixo" internamente pode variar).
;- ------------------------------------------------------------

Procedure.b Z80_IsWordStartChar(C.s)
  ProcedureReturn Bool(IsAlphaChar(C) Or C = "?" Or C = "@" Or C = "_")
EndProcedure

Procedure.b Z80_IsWordChar(C.s)
  ProcedureReturn Bool(IsWordChar(C) Or C = "?" Or C = "@" Or C = "$" Or C = ".")
EndProcedure

Procedure HighlightZ80Text(Sci, Text.s)
  Protected TextLen = Len(Text)
  Protected I = 1
  Protected AtLineStart.b = #True
  Protected C.s, C2.s, Start, Word.s, CommentLen

  ScintillaSendMessage(Sci, #SCI_STARTSTYLING, 0, 0)

  While I <= TextLen
    C = Mid(Text, I, 1)

    ; --- Fim de linha ---
    If C = Chr(13) Or C = Chr(10)
      EmitRun(Sci, C, #Style_Default)
      I + 1
      AtLineStart = #True
      Continue
    EndIf

    ; --- Espaco/tab no inicio da linha nao conta como token real ---
    If AtLineStart And (C = " " Or C = Chr(9))
      EmitRun(Sci, C, #Style_Default)
      I + 1
      Continue
    EndIf

    ; --- Comentario ; ate o final da linha ---
    If C = ";"
      CommentLen = 0
      While I + CommentLen <= TextLen And Mid(Text, I + CommentLen, 1) <> Chr(13) And Mid(Text, I + CommentLen, 1) <> Chr(10)
        CommentLen + 1
      Wend
      EmitRun(Sci, Mid(Text, I, CommentLen), #Style_Comment)
      I + CommentLen
      AtLineStart = #False
      Continue
    EndIf

    ; --- Literais de string "..." (com escapes \" e \\) ---
    If C = Chr(34)
      Start = I
      I + 1
      While I <= TextLen And Mid(Text, I, 1) <> Chr(13) And Mid(Text, I, 1) <> Chr(10)
        If Mid(Text, I, 1) = "\" And I < TextLen
          I + 2
          Continue
        EndIf
        If Mid(Text, I, 1) = Chr(34)
          I + 1
          Break
        EndIf
        I + 1
      Wend
      EmitRun(Sci, Mid(Text, Start, I - Start), #Style_String)
      AtLineStart = #False
      Continue
    EndIf

    ; --- Literais de string/char '...' (aspa simples dobrada '' = escapada) ---
    If C = "'"
      Start = I
      I + 1
      While I <= TextLen And Mid(Text, I, 1) <> Chr(13) And Mid(Text, I, 1) <> Chr(10)
        If Mid(Text, I, 1) = "'"
          If I < TextLen And Mid(Text, I + 1, 1) = "'"
            I + 2
            Continue
          EndIf
          I + 1
          Break
        EndIf
        I + 1
      Wend
      EmitRun(Sci, Mid(Text, Start, I - Start), #Style_String)
      AtLineStart = #False
      Continue
    EndIf

    ; --- Hex entre aspas simples: X'1A2B' / x'1a2b' ---
    If (C = "X" Or C = "x") And I < TextLen And Mid(Text, I + 1, 1) = "'"
      Start = I
      I + 2
      While I <= TextLen And Mid(Text, I, 1) <> "'" And Mid(Text, I, 1) <> Chr(13) And Mid(Text, I, 1) <> Chr(10)
        I + 1
      Wend
      If I <= TextLen And Mid(Text, I, 1) = "'"
        I + 1
      EndIf
      EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Number)
      AtLineStart = #False
      Continue
    EndIf

    ; --- Prefixos numericos 0x.. (hex) e 0b.. (binario) ---
    If C = "0" And I < TextLen And (UCase(Mid(Text, I + 1, 1)) = "X" Or UCase(Mid(Text, I + 1, 1)) = "B")
      Start = I
      I + 2
      While I <= TextLen And Z80_IsWordChar(Mid(Text, I, 1))
        I + 1
      Wend
      EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Number)
      AtLineStart = #False
      Continue
    EndIf

    ; --- Hex prefixado com # (#1A2B) ---
    If C = "#" And I < TextLen And IsWordChar(Mid(Text, I + 1, 1))
      Start = I
      I + 1
      While I <= TextLen And Z80_IsWordChar(Mid(Text, I, 1))
        I + 1
      Wend
      EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Number)
      AtLineStart = #False
      Continue
    EndIf

    ; --- Numeros: digitos + letras hex A-F, sufixo de radix opcional
    ; (B/I/D/M/O/Q/H) - ver nota de escopo no cabecalho desta procedure ---
    If IsDigitChar(C)
      Start = I
      While I <= TextLen And (IsDigitChar(Mid(Text, I, 1)) Or (UCase(Mid(Text, I, 1)) >= "A" And UCase(Mid(Text, I, 1)) <= "F"))
        I + 1
      Wend
      If I <= TextLen
        C2 = UCase(Mid(Text, I, 1))
        If C2 = "B" Or C2 = "I" Or C2 = "D" Or C2 = "M" Or C2 = "O" Or C2 = "Q" Or C2 = "H"
          I + 1
        EndIf
      EndIf
      EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Number)
      AtLineStart = #False
      Continue
    EndIf

    ; --- "$" isolado = endereco/posicao atual (nao colado a um identificador) ---
    If C = "$" And (I = TextLen Or Not IsWordChar(Mid(Text, I + 1, 1)))
      EmitRun(Sci, C, #Style_Number)
      I + 1
      AtLineStart = #False
      Continue
    EndIf

    ; --- Diretiva com ponto (.RADIX, .PHASE, ...) ou rotulo relativo (.nome) ---
    If C = "." And I < TextLen And Z80_IsWordStartChar(Mid(Text, I + 1, 1))
      Start = I
      I + 1
      While I <= TextLen And Z80_IsWordChar(Mid(Text, I, 1))
        I + 1
      Wend
      Word = UCase(Mid(Text, Start + 1, I - Start - 1))
      If Z80Asm::IsDirective(Word)
        EmitRun(Sci, Mid(Text, Start, I - Start), #Style_DignifiedStmt)
      Else
        EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Label)
      EndIf
      AtLineStart = #False
      Continue
    EndIf

    ; --- Identificadores / mnemonicos / registradores / diretivas / rotulos ---
    If Z80_IsWordStartChar(C)
      Start = I
      I + 1
      While I <= TextLen And Z80_IsWordChar(Mid(Text, I, 1))
        I + 1
      Wend
      Word = UCase(Mid(Text, Start, I - Start))

      ; "AF'" (par de registrador sombra) - inclui o apostrofo no token
      If Word = "AF" And I <= TextLen And Mid(Text, I, 1) = "'"
        I + 1
      EndIf

      If Z80Asm::IsDirective(Word)
        EmitRun(Sci, Mid(Text, Start, I - Start), #Style_DignifiedStmt)
      ElseIf Z80Asm::IsMnemonic(Word)
        EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Statement)
      ElseIf Z80Asm::IsRegister(Word)
        EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Function)
      ElseIf Z80Asm::IsOperatorWord(Word)
        EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Operator)
      ElseIf AtLineStart
        ; primeira palavra da linha, nao e palavra reservada -> rotulo
        ; (consome ":" ou "::" final, se houver)
        If I <= TextLen And Mid(Text, I, 1) = ":"
          I + 1
          If I <= TextLen And Mid(Text, I, 1) = ":"
            I + 1
          EndIf
        EndIf
        EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Label)
      Else
        EmitRun(Sci, Mid(Text, Start, I - Start), #Style_Default)
      EndIf
      AtLineStart = #False
      Continue
    EndIf

    ; --- Operadores/simbolos ---
    If C = "+" Or C = "-" Or C = "*" Or C = "/" Or C = "=" Or C = "<" Or C = ">" Or
       C = ":" Or C = "," Or C = "(" Or C = ")" Or C = "!" Or C = "%" Or C = "&"
      EmitRun(Sci, C, #Style_Operator)
      I + 1
      AtLineStart = #False
      Continue
    EndIf

    ; --- Qualquer outro caractere (espacos no meio da linha, etc) ---
    EmitRun(Sci, C, #Style_Default)
    I + 1
  Wend
EndProcedure

; Varre uma unica linha (sem CR/LF) de markdown "corpo" (nao titulo, nao dentro
; de bloco de codigo) procurando **negrito**, `codigo` e [texto](url) - os
; marcadores continuam no texto (isto e edicao, nao renderizacao: o buffer nao
; pode virar outra coisa do que o usuario digitou), so ganham estilo junto do
; conteudo que delimitam. BaseStyle e o estilo de fundo do texto corrido (fora
; de qualquer marcador).
Procedure HighlightMarkdownInline(Sci, LineText.s, BaseStyle)
  Protected LineLen = Len(LineText)
  Protected Pos = 1, Buf.s = "", CurStyle = BaseStyle
  Protected InBold.b = #False, InCode.b = #False
  Protected LinkTextEnd, LinkUrlEnd

  While Pos <= LineLen
    If Mid(LineText, Pos, 1) = "[" And Not InCode
      LinkTextEnd = FindString(LineText, "]", Pos + 1)
      If LinkTextEnd > 0 And Mid(LineText, LinkTextEnd + 1, 1) = "("
        LinkUrlEnd = FindString(LineText, ")", LinkTextEnd + 2)
        If LinkUrlEnd > 0
          If Buf <> "" : EmitRun(Sci, Buf, CurStyle) : Buf = "" : EndIf
          EmitRun(Sci, Mid(LineText, Pos, LinkUrlEnd - Pos + 1), #Style_MdLink)
          Pos = LinkUrlEnd + 1
          Continue
        EndIf
      EndIf
    EndIf

    If Mid(LineText, Pos, 2) = "**"
      If Buf <> "" : EmitRun(Sci, Buf, CurStyle) : Buf = "" : EndIf
      EmitRun(Sci, "**", #Style_MdBold)
      If InBold : InBold = #False : Else : InBold = #True : EndIf
      If InBold : CurStyle = #Style_MdBold : Else : CurStyle = BaseStyle : EndIf
      Pos + 2
      Continue
    ElseIf Mid(LineText, Pos, 1) = "`"
      If Buf <> "" : EmitRun(Sci, Buf, CurStyle) : Buf = "" : EndIf
      EmitRun(Sci, "`", #Style_MdCode)
      If InCode : InCode = #False : Else : InCode = #True : EndIf
      If InCode : CurStyle = #Style_MdCode : Else : CurStyle = BaseStyle : EndIf
      Pos + 1
      Continue
    EndIf

    Buf + Mid(LineText, Pos, 1)
    Pos + 1
  Wend

  If Buf <> ""
    EmitRun(Sci, Buf, CurStyle)
  EndIf
EndProcedure

; Realce de Markdown para o modo de edicao ("MD") - titulos #/##/###
; (linha inteira vira #Style_MdHeadingN, sem varredura inline, mesma regra de
; GenMdHelp_RenderMarkdown), blocos ``` (linhas de abre/fecha e conteudo viram
; #Style_MdCode) e, no corpo comum, **negrito**/`codigo`/[texto](url) via
; HighlightMarkdownInline(). Ao contrario do renderizador de visualizacao
; (GenMdHelp_RenderMarkdown), aqui o texto do buffer nunca e reescrito - so
; estilo e aplicado por cima do que o usuario digitou.
Procedure HighlightMarkdownText(Sci, Text.s)
  Protected TextLen = Len(Text)
  Protected I = 1
  Protected AtLineStart.b = #True
  Protected InCodeBlock.b = #False
  Protected C.s, PeekEnd, LineRest.s, LineTrim.s

  ScintillaSendMessage(Sci, #SCI_STARTSTYLING, 0, 0)

  While I <= TextLen
    C = Mid(Text, I, 1)

    If C = Chr(13) Or C = Chr(10)
      EmitRun(Sci, C, #Style_Default)
      I + 1
      AtLineStart = #True
      Continue
    EndIf

    If AtLineStart
      PeekEnd = I
      While PeekEnd <= TextLen And Mid(Text, PeekEnd, 1) <> Chr(13) And Mid(Text, PeekEnd, 1) <> Chr(10)
        PeekEnd + 1
      Wend
      LineRest = Mid(Text, I, PeekEnd - I)
      LineTrim = Trim(LineRest)

      If Left(LineTrim, 3) = "```"
        EmitRun(Sci, LineRest, #Style_MdCode)
        If InCodeBlock : InCodeBlock = #False : Else : InCodeBlock = #True : EndIf
        I = PeekEnd
        AtLineStart = #False
        Continue
      ElseIf InCodeBlock
        EmitRun(Sci, LineRest, #Style_MdCode)
        I = PeekEnd
        AtLineStart = #False
        Continue
      ElseIf Left(LineTrim, 4) = "### "
        EmitRun(Sci, LineRest, #Style_MdHeading3)
        I = PeekEnd
        AtLineStart = #False
        Continue
      ElseIf Left(LineTrim, 3) = "## "
        EmitRun(Sci, LineRest, #Style_MdHeading2)
        I = PeekEnd
        AtLineStart = #False
        Continue
      ElseIf Left(LineTrim, 2) = "# "
        EmitRun(Sci, LineRest, #Style_MdHeading1)
        I = PeekEnd
        AtLineStart = #False
        Continue
      EndIf

      HighlightMarkdownInline(Sci, LineRest, #Style_Default)
      I = PeekEnd
      AtLineStart = #False
      Continue
    EndIf

    ; Nao deveria chegar aqui (todo caractere fora de EOL e consumido pelo
    ; bloco AtLineStart acima, que sempre avanca ate o fim da linha) - mantido
    ; so como rede de seguranca contra I nao avancar.
    EmitRun(Sci, C, #Style_Default)
    I + 1
  Wend
EndProcedure

;- ------------------------------------------------------------
;- Aparencia do ScintillaGadget (fonte/tema conforme EditorCfg - ver
;- ApplyTheme() e EditorSettings.pbi)
;- ------------------------------------------------------------

Procedure SetupEditorStyles(Sci)
  Protected *FontName
  Protected *MonoFont

  ScintillaSendMessage(Sci, #SCI_SETCODEPAGE, #SC_CP_UTF8)

  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #STYLE_DEFAULT, Color_Syntax_Default)
  ScintillaSendMessage(Sci, #SCI_STYLESETBACK, #STYLE_DEFAULT, Color_EditorBg)
  *FontName = UTF8(EditorCfg\FontName)
  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #STYLE_DEFAULT, *FontName)
  FreeMemory(*FontName)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #STYLE_DEFAULT, EditorCfg\FontSize)
  ScintillaSendMessage(Sci, #SCI_STYLECLEARALL)

  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #Style_Comment, Color_Syntax_Comment)
  ScintillaSendMessage(Sci, #SCI_STYLESETITALIC, #Style_Comment, #True)

  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #Style_String, Color_Syntax_String)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #Style_Statement, Color_Syntax_Statement)
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #Style_Statement, #True)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #Style_Operator, Color_Syntax_Operator)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #Style_Function, Color_Syntax_Function)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #Style_Number, Color_Syntax_Number)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #Style_Label, Color_Syntax_Label)
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #Style_Label, #True)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #Style_DignifiedStmt, Color_Syntax_DignifiedStmt)
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #Style_DignifiedStmt, #True)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #Style_MsxBas2Rom, Color_Syntax_MsxBas2Rom)
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #Style_MsxBas2Rom, #True)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #Style_Remtag, Color_Syntax_Remtag)
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #Style_Remtag, #True)

  ; Estilos do modo "MD" (HighlightMarkdownText) - reaproveita as mesmas cores
  ; do tema em vez de criar uma paleta Color_Syntax_Md* propria, mesma logica
  ; visual do renderizador de visualizacao (GenMdHelp_SetupStyles).
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #Style_MdHeading1, Color_Syntax_Function)
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #Style_MdHeading1, #True)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #Style_MdHeading1, EditorCfg\FontSize + 6)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #Style_MdHeading2, Color_Syntax_Function)
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #Style_MdHeading2, #True)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #Style_MdHeading2, EditorCfg\FontSize + 3)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #Style_MdHeading3, Color_Syntax_Function)
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #Style_MdHeading3, #True)
  ScintillaSendMessage(Sci, #SCI_STYLESETSIZE, #Style_MdHeading3, EditorCfg\FontSize + 1)
  ScintillaSendMessage(Sci, #SCI_STYLESETBOLD, #Style_MdBold, #True)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #Style_MdCode, Color_Syntax_Number)
  *MonoFont = UTF8("Consolas")
  ScintillaSendMessage(Sci, #SCI_STYLESETFONT, #Style_MdCode, *MonoFont)
  FreeMemory(*MonoFont)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #Style_MdLink, Color_Accent)
  ScintillaSendMessage(Sci, #SCI_STYLESETUNDERLINE, #Style_MdLink, #True)

  ScintillaSendMessage(Sci, #SCI_SETCARETFORE, Color_Caret)
  ScintillaSendMessage(Sci, #SCI_SETSELBACK, 1, Color_SelBack)
  ScintillaSendMessage(Sci, #SCI_SETTABWIDTH, 4)

  ; Margem de numeros de linha - unica margem usada (sem marcadores/folding)
  ScintillaSendMessage(Sci, #SCI_STYLESETFORE, #STYLE_LINENUMBER, Color_LineNumberFore)
  ScintillaSendMessage(Sci, #SCI_STYLESETBACK, #STYLE_LINENUMBER, Color_RulerBg)
  ScintillaSendMessage(Sci, #SCI_SETMARGINTYPEN, 0, #SC_MARGIN_NUMBER)
  ScintillaSendMessage(Sci, #SCI_SETMARGINWIDTHN, 1, 0)
  ScintillaSendMessage(Sci, #SCI_SETMARGINWIDTHN, 2, 0)
  UpdateLineNumberMargin(Sci)

  ; Auto completar (ver #SCN_CHARADDED em ScintillaCallBack e Configurar ->
  ; Basic Options...) - ignora maiusculas/minusculas na filtragem (o MSX-BASIC
  ; nao diferencia) e deixa o proprio Scintilla ordenar a lista alfabetica que
  ; ShowAutoComplete monta sem se preocupar com ordem.
  ScintillaSendMessage(Sci, #SCI_AUTOCSETIGNORECASE, #True)
  ScintillaSendMessage(Sci, #SCI_AUTOCSETORDER, #SC_ORDER_PERFORMSORT)
EndProcedure

; Recalcula a largura da margem de numeros de linha com base na quantidade de
; digitos necessaria (numero de linhas do documento) e na largura real do
; caractere na fonte monoespacada em uso - mantem a margem sempre do tamanho
; certo (nem apertada demais, nem larga demais) conforme o arquivo cresce.
Procedure UpdateLineNumberMargin(Sci)
  Protected Digits = Len(Str(ScintillaSendMessage(Sci, #SCI_GETLINECOUNT)))
  If Digits < 3 : Digits = 3 : EndIf
  Protected *Sample = UTF8(RSet("", Digits, "9"))
  Protected TextW = ScintillaSendMessage(Sci, #SCI_TEXTWIDTH, #STYLE_LINENUMBER, *Sample)
  FreeMemory(*Sample)
  ScintillaSendMessage(Sci, #SCI_SETMARGINWIDTHN, 0, TextW + 16)
EndProcedure

;- ------------------------------------------------------------
;- Callback do Scintilla (mudancas de texto -> realce + modificado)
;- ------------------------------------------------------------

; Nao chama de volta o Scintilla diretamente daqui: a notificacao ainda
; esta em andamento (dentro do proprio SendMessage que a disparou), entao
; o trabalho real (reler texto, aplicar estilos) e adiado para o loop
; principal atraves de PostEvent, evitando reentrancia no controle.
Procedure ScintillaCallBack(Gadget, *scinotify.SCNotification)
  Select *scinotify\nmhdr\code
    Case #SCN_MODIFIED
      If *scinotify\modificationType & (#SC_MOD_INSERTTEXT | #SC_MOD_DELETETEXT)
        PostEvent(#Event_Rehighlight, #MainWindow, Gadget, 0, SuppressModifiedTracking)
      EndIf

    Case #SCN_UPDATEUI
      ; disparado em scroll/mudanca de selecao/caret - mantem a regua de colunas
      ; e a margem de numeros de linha alinhadas com o que esta sendo exibido
      PostEvent(#Event_UpdateUI, #MainWindow, Gadget, 0, 0)

    Case #SCN_CHARADDED
      ; ver comentario de #Event_AutoComplete - so adia pra la, nao mexe no
      ; Scintilla aqui dentro
      PostEvent(#Event_AutoComplete, #MainWindow, Gadget, 0, *scinotify\ch)
  EndSelect
EndProcedure

;- ------------------------------------------------------------
;- Auto completar (Configurar -> Basic Options...) - palavras-chave do
;- MSX-BASIC/Basic Dignified (mapas Kw*, ver InitKeywordMaps) e variaveis
;- usadas no documento ativo, disparado por #SCN_CHARADDED/#Event_AutoComplete
;- ------------------------------------------------------------

; Layout esperado pelo SCI_GETTEXTRANGE nativo do Scintilla (usado por
; GetSciTextRange, abaixo).
Structure Sci_TextRange
  cpMin.l
  cpMax.l
  lpstrText.i
EndStructure

; Testa se WordUpper (ja em maiusculas) e uma palavra reservada do dialeto -
; mesmos mapas usados pelo realce de sintaxe (KwFunctionDollar guarda so o
; nome base, sem o "$", entao o sufixo e removido antes de checar). Quando
; IsMsxBas2Rom, inclui tambem o vocabulario estendido do MSXBAS2ROM (so faz
; sentido oferecer/excluir essas palavras em documentos modo "BAS").
Procedure.b IsReservedKeyword(WordUpper.s, IsMsxBas2Rom.b = #False)
  Protected Base.s = WordUpper
  Protected HasDollarSuffix.b = #False
  If Right(WordUpper, 1) = "$"
    Base = Left(WordUpper, Len(WordUpper) - 1)
    HasDollarSuffix = #True
  EndIf

  If FindMapElement(KwStatement(), WordUpper)      : ProcedureReturn #True : EndIf
  If FindMapElement(KwFunctionPlain(), WordUpper)  : ProcedureReturn #True : EndIf
  If HasDollarSuffix And FindMapElement(KwFunctionDollar(), Base) : ProcedureReturn #True : EndIf
  If FindMapElement(KwOperatorWord(), WordUpper)   : ProcedureReturn #True : EndIf
  If FindMapElement(KwDignifiedStmt(), WordUpper)  : ProcedureReturn #True : EndIf
  If FindMapElement(KwBoolean(), WordUpper)        : ProcedureReturn #True : EndIf

  If IsMsxBas2Rom
    If FindMapElement(KwMsxBas2RomDirective(), WordUpper)    : ProcedureReturn #True : EndIf
    If FindMapElement(KwMsxBas2RomStatement(), WordUpper)    : ProcedureReturn #True : EndIf
    If FindMapElement(KwMsxBas2RomFunctionPlain(), WordUpper) : ProcedureReturn #True : EndIf
  EndIf

  ProcedureReturn #False
EndProcedure

; Le o trecho [StartPos, EndPos) do buffer do Scintilla (posicoes em bytes,
; UTF-8) via SCI_GETTEXTRANGE - seguro decodificar como UTF-8 mesmo em meio
; ao documento porque os limites usados por ShowAutoComplete/CollectDocument-
; Variables sempre caem em fronteira de caractere ASCII (letra/digito/"_"),
; nunca no meio de uma sequencia multi-byte.
Procedure.s GetSciTextRange(Sci, StartPos, EndPos)
  Protected Length = EndPos - StartPos
  If Length <= 0
    ProcedureReturn ""
  EndIf

  Protected *Buffer = AllocateMemory(Length + 1)
  If Not *Buffer
    ProcedureReturn ""
  EndIf

  Protected TR.Sci_TextRange
  TR\cpMin = StartPos
  TR\cpMax = EndPos
  TR\lpstrText = *Buffer

  ScintillaSendMessage(Sci, #SCI_GETTEXTRANGE, 0, @TR)
  Protected Result.s = PeekS(*Buffer, -1, #PB_UTF8)
  FreeMemory(*Buffer)

  ProcedureReturn Result
EndProcedure

; Acrescenta Word a Cand() se seu prefixo (ate o tamanho do que ja foi
; digitado) bater com PrefixUpper, ignorando maiusculas/minusculas - a chave
; do mapa e o proprio texto exibido no popup, entao duplicatas (mesma
; palavra-chave/variavel vista mais de uma vez) sao descartadas de graca.
Procedure AddIfPrefixMatch(Map Cand.b(), Word.s, PrefixUpper.s)
  If Left(UCase(Word), Len(PrefixUpper)) = PrefixUpper
    Cand(Word) = #True
  EndIf
EndProcedure

; Varre o texto do documento (mesma logica de IsAlphaChar/IsWordChar usada no
; realce) coletando identificadores que nao sejam palavra reservada - vira a
; lista de "variaveis conhecidas" oferecida junto com as palavras-chave.
; Guarda so a primeira grafia (maiuscula/minuscula) encontrada de cada nome.
Procedure CollectDocumentVariables(Sci, Map VarDisplay.s(), IsMsxBas2Rom.b)
  Protected Text.s = ReadSciText(Sci)
  Protected TextLen = Len(Text)
  Protected Pos = 1, WStart, C.s, Word.s

  While Pos <= TextLen
    C = Mid(Text, Pos, 1)
    If IsAlphaChar(C)
      WStart = Pos
      Pos + 1
      While Pos <= TextLen And IsWordChar(Mid(Text, Pos, 1))
        Pos + 1
      Wend
      If Pos <= TextLen And FindString("$%!#", Mid(Text, Pos, 1))
        Pos + 1
      EndIf

      Word = Mid(Text, WStart, Pos - WStart)
      If Not IsReservedKeyword(UCase(Word), IsMsxBas2Rom) And Not FindMapElement(VarDisplay(), UCase(Word))
        VarDisplay(UCase(Word)) = Word
      EndIf
    Else
      Pos + 1
    EndIf
  Wend
EndProcedure

; Varre o documento (modo "ASM") coletando rotulos - mesma regra classica
; MACRO-80/Z80 do highlighter de verdade (HighlightZ80Text, mais acima): o
; primeiro token de cada linha que nao bate com nenhuma tabela reservada
; (Z80Asm::IsDirective/IsMnemonic/IsRegister/IsOperatorWord) e rotulo, com ou
; sem ":" no final; rotulos relativos ".nome" tambem contam (guardados SEM o
; "." - mesmo motivo do "." do NestorBASIC em ShowAutoComplete, a fronteira
; de palavra do Scintilla ja para antes dele). Verificacao mais simples que a
; do highlighter de verdade (nao trata string/comentario no resto da linha
; com precisao de token a token) porque so precisa do primeiro token de cada
; linha - o resto da linha e so pulado ate a proxima quebra.
Procedure CollectZ80Labels(Sci, Map LabelDisplay.s())
  Protected Text.s = ReadSciText(Sci)
  Protected TextLen = Len(Text)
  Protected Pos = 1, C.s, WStart, Word.s, WordUpper.s

  While Pos <= TextLen
    While Pos <= TextLen And (Mid(Text, Pos, 1) = " " Or Mid(Text, Pos, 1) = Chr(9))
      Pos + 1
    Wend

    If Pos <= TextLen
      C = Mid(Text, Pos, 1)

      If C = "." And Pos < TextLen And Z80_IsWordStartChar(Mid(Text, Pos + 1, 1))
        WStart = Pos + 1
        Pos + 2
        While Pos <= TextLen And Z80_IsWordChar(Mid(Text, Pos, 1))
          Pos + 1
        Wend
        Word = Mid(Text, WStart, Pos - WStart)
        WordUpper = UCase(Word)
        If Not Z80Asm::IsDirective(WordUpper) And Not FindMapElement(LabelDisplay(), WordUpper)
          LabelDisplay(WordUpper) = Word
        EndIf
      ElseIf Z80_IsWordStartChar(C)
        WStart = Pos
        Pos + 1
        While Pos <= TextLen And Z80_IsWordChar(Mid(Text, Pos, 1))
          Pos + 1
        Wend
        Word = Mid(Text, WStart, Pos - WStart)
        WordUpper = UCase(Word)
        If Not Z80Asm::IsDirective(WordUpper) And Not Z80Asm::IsMnemonic(WordUpper) And
           Not Z80Asm::IsRegister(WordUpper) And Not Z80Asm::IsOperatorWord(WordUpper) And
           Not FindMapElement(LabelDisplay(), WordUpper)
          LabelDisplay(WordUpper) = Word
        EndIf
      EndIf
    EndIf

    While Pos <= TextLen And Mid(Text, Pos, 1) <> Chr(13) And Mid(Text, Pos, 1) <> Chr(10)
      Pos + 1
    Wend
    While Pos <= TextLen And (Mid(Text, Pos, 1) = Chr(13) Or Mid(Text, Pos, 1) = Chr(10))
      Pos + 1
    Wend
  Wend
EndProcedure

; Ajusta a caixa de uma palavra-chave (os mapas Kw* guardam tudo em
; maiusculas) conforme CaseMode ("AsTyped"/"Upper"/"Lower" - BasicOptionsCfg
; ou AssemblyOptionsCfg dependendo do modo do documento, ver ShowAutoComplete)
; - "AsTyped" acompanha a caixa do prefixo que o usuario ja digitou (Prefix,
; na grafia original, nao a versao uppercased usada so pra comparar); se o
; prefixo for ambiguo/misto (ex.: "Pri"), mantem maiusculas (grafia como o
; mapa guarda). So se aplica a palavras-chave/mnemonicos - variaveis
; (CollectDocumentVariables) e rotulos (CollectZ80Labels) ficam sempre com a
; grafia que ja aparece no documento.
Procedure.s ApplyKeywordCase(Word.s, Prefix.s, CaseMode.s)
  Select CaseMode
    Case "Upper"
      ProcedureReturn UCase(Word)
    Case "Lower"
      ProcedureReturn LCase(Word)
    Default ; "AsTyped"
      If Prefix <> "" And Prefix = LCase(Prefix) And Prefix <> UCase(Prefix)
        ProcedureReturn LCase(Word)
      ElseIf Prefix <> "" And Prefix = UCase(Prefix) And Prefix <> LCase(Prefix)
        ProcedureReturn UCase(Word)
      Else
        ProcedureReturn Word
      EndIf
  EndSelect
EndProcedure

; Monta a lista de sugestoes e manda SCI_AUTOCSHOW - so chamada de dentro do
; loop principal (HandleAutoCompleteCharAdded), nunca direto da notificacao
; do Scintilla. Ramifica em duas fontes de vocabulario completamente
; diferentes conforme o modo do documento: "ASM" usa Z80Asm::* (mnemonicos/
; registradores/diretivas/operadores + rotulos do documento, config em
; AssemblyOptionsCfg); "DMX"/"BAS" usa os mapas Kw* de MSX-BASIC/Dignified +
; NestorBASIC + variaveis do documento (config em BasicOptionsCfg) - mesma
; logica de antes, so reorganizada pra dentro do ramo Else.
Procedure ShowAutoComplete(Sci)
  Protected Pos = ScintillaSendMessage(Sci, #SCI_GETCURRENTPOS)
  Protected WStart = ScintillaSendMessage(Sci, #SCI_WORDSTARTPOSITION, Pos, #True)
  Protected WLen = Pos - WStart

  Protected DocPos = FindDocumentByGadget(Sci)
  Protected DocMode.s = ""
  If DocPos >= 0 And SelectElement(Docs(), DocPos)
    DocMode = Docs()\Mode
  EndIf

  Protected Prefix.s = GetSciTextRange(Sci, WStart, Pos)
  Protected PrefixUpper.s = UCase(Prefix)

  NewMap Candidates.b()

  If DocMode = "ASM"
    If WLen < AssemblyOptionsCfg\AutoCompleteMinChars
      ProcedureReturn
    EndIf

    ForEach KwZ80Mnemonic()     : AddIfPrefixMatch(Candidates(), ApplyKeywordCase(MapKey(KwZ80Mnemonic()), Prefix, AssemblyOptionsCfg\AutoCompleteCase), PrefixUpper)     : Next
    ForEach KwZ80Register()     : AddIfPrefixMatch(Candidates(), ApplyKeywordCase(MapKey(KwZ80Register()), Prefix, AssemblyOptionsCfg\AutoCompleteCase), PrefixUpper)     : Next
    ForEach KwZ80Directive()    : AddIfPrefixMatch(Candidates(), ApplyKeywordCase(MapKey(KwZ80Directive()), Prefix, AssemblyOptionsCfg\AutoCompleteCase), PrefixUpper)    : Next
    ForEach KwZ80OperatorWord() : AddIfPrefixMatch(Candidates(), ApplyKeywordCase(MapKey(KwZ80OperatorWord()), Prefix, AssemblyOptionsCfg\AutoCompleteCase), PrefixUpper) : Next

    NewMap LabelDisplay.s()
    CollectZ80Labels(Sci, LabelDisplay())
    ForEach LabelDisplay()
      AddIfPrefixMatch(Candidates(), LabelDisplay(), PrefixUpper)
    Next
  Else
    If WLen < BasicOptionsCfg\AutoCompleteMinChars
      ProcedureReturn
    EndIf

    Protected IsMsxBas2Rom.b = Bool(DocMode = "BAS")

    ForEach KwStatement()      : AddIfPrefixMatch(Candidates(), ApplyKeywordCase(MapKey(KwStatement()), Prefix, BasicOptionsCfg\AutoCompleteCase), PrefixUpper)     : Next
    ForEach KwFunctionPlain()  : AddIfPrefixMatch(Candidates(), ApplyKeywordCase(MapKey(KwFunctionPlain()), Prefix, BasicOptionsCfg\AutoCompleteCase), PrefixUpper) : Next
    ForEach KwFunctionDollar() : AddIfPrefixMatch(Candidates(), ApplyKeywordCase(MapKey(KwFunctionDollar()) + "$", Prefix, BasicOptionsCfg\AutoCompleteCase), PrefixUpper) : Next
    ForEach KwOperatorWord()   : AddIfPrefixMatch(Candidates(), ApplyKeywordCase(MapKey(KwOperatorWord()), Prefix, BasicOptionsCfg\AutoCompleteCase), PrefixUpper)  : Next
    ForEach KwDignifiedStmt()  : AddIfPrefixMatch(Candidates(), ApplyKeywordCase(MapKey(KwDignifiedStmt()), Prefix, BasicOptionsCfg\AutoCompleteCase), PrefixUpper) : Next
    ForEach KwBoolean()        : AddIfPrefixMatch(Candidates(), ApplyKeywordCase(MapKey(KwBoolean()), Prefix, BasicOptionsCfg\AutoCompleteCase), PrefixUpper)       : Next

    ; Wrappers .NB_* do NestorBASIC - grafia canonica preservada (sem
    ; ApplyKeywordCase), ver comentario do Map KwNestorBasic().
    ForEach KwNestorBasic() : AddIfPrefixMatch(Candidates(), MapKey(KwNestorBasic()), PrefixUpper) : Next

    If IsMsxBas2Rom
      ForEach KwMsxBas2RomDirective()     : AddIfPrefixMatch(Candidates(), ApplyKeywordCase(MapKey(KwMsxBas2RomDirective()), Prefix, BasicOptionsCfg\AutoCompleteCase), PrefixUpper)     : Next
      ForEach KwMsxBas2RomStatement()     : AddIfPrefixMatch(Candidates(), ApplyKeywordCase(MapKey(KwMsxBas2RomStatement()), Prefix, BasicOptionsCfg\AutoCompleteCase), PrefixUpper)     : Next
      ForEach KwMsxBas2RomFunctionPlain() : AddIfPrefixMatch(Candidates(), ApplyKeywordCase(MapKey(KwMsxBas2RomFunctionPlain()), Prefix, BasicOptionsCfg\AutoCompleteCase), PrefixUpper) : Next
    EndIf

    NewMap VarDisplay.s()
    CollectDocumentVariables(Sci, VarDisplay(), IsMsxBas2Rom)
    ForEach VarDisplay()
      AddIfPrefixMatch(Candidates(), VarDisplay(), PrefixUpper)
    Next
  EndIf

  Protected List.s = ""
  ForEach Candidates()
    If List <> "" : List + " " : EndIf
    List + MapKey(Candidates())
  Next

  If List = ""
    ProcedureReturn
  EndIf

  Protected *ListBuf = UTF8(List)
  ScintillaSendMessage(Sci, #SCI_AUTOCSHOW, WLen, *ListBuf)
  FreeMemory(*ListBuf)
EndProcedure

; Minimo de letras configurado para o documento dono de Sci (BasicOptionsCfg
; ou AssemblyOptionsCfg conforme o modo) - usado tanto por
; HandleAutoCompleteCharAdded quanto pelo cancelamento por backspace em
; #Event_UpdateUI, pra nao duplicar a mesma decisao de modo em dois lugares.
Procedure.i AutoCompleteMinCharsForGadget(Sci)
  Protected DocPos = FindDocumentByGadget(Sci)
  If DocPos < 0 Or Not SelectElement(Docs(), DocPos)
    ProcedureReturn 1
  EndIf
  If Docs()\Mode = "ASM"
    ProcedureReturn AssemblyOptionsCfg\AutoCompleteMinChars
  EndIf
  ProcedureReturn BasicOptionsCfg\AutoCompleteMinChars
EndProcedure

; Tratador de #Event_AutoComplete (adiado de #SCN_CHARADDED) - CharCode e o
; caractere que acabou de ser inserido (ver *scinotify\ch em ScintillaCall-
; Back). Documentos "DMX"/"BAS" usam BasicOptionsCfg; "ASM" usa
; AssemblyOptionsCfg (Configurar -> Assembly...); markdown fica de fora, sem
; vocabulario. So chama ShowAutoComplete no exato instante em que a palavra
; sendo digitada atinge o minimo configurado - depois disso o proprio
; Scintilla filtra o popup ja aberto conforme mais letras entram, sem
; precisar remontar a lista (que varre o documento inteiro atras de
; variaveis/rotulos) a cada tecla. O conjunto de "caracteres de palavra" que
; conta pro gatilho tambem muda por modo: Z80_IsWordChar (asm, aceita
; $/./?/@) vs IsWordChar (basic, alnum+"_").
Procedure HandleAutoCompleteCharAdded(Sci, CharCode)
  Protected DocPos = FindDocumentByGadget(Sci)
  If DocPos < 0 Or Not SelectElement(Docs(), DocPos)
    ProcedureReturn
  EndIf

  Protected DocMode.s = Docs()\Mode
  Protected Ch.s = Chr(CharCode)
  Protected IsWordCh.b, Enabled.b

  If DocMode = "ASM"
    IsWordCh = Z80_IsWordChar(Ch)
    Enabled  = AssemblyOptionsCfg\AutoCompleteEnabled
  ElseIf DocMode = "DMX" Or DocMode = "BAS"
    IsWordCh = IsWordChar(Ch)
    Enabled  = BasicOptionsCfg\AutoCompleteEnabled
  Else
    ProcedureReturn
  EndIf

  If Not Enabled
    ProcedureReturn
  EndIf

  Protected MinChars = AutoCompleteMinCharsForGadget(Sci)

  If IsWordCh
    Protected Pos = ScintillaSendMessage(Sci, #SCI_GETCURRENTPOS)
    Protected WStart = ScintillaSendMessage(Sci, #SCI_WORDSTARTPOSITION, Pos, #True)
    If Pos - WStart = MinChars
      ShowAutoComplete(Sci)
    EndIf
  ElseIf ScintillaSendMessage(Sci, #SCI_AUTOCACTIVE)
    ScintillaSendMessage(Sci, #SCI_AUTOCCANCEL)
  EndIf
EndProcedure

;- ------------------------------------------------------------
;- Documentos / abas (tab bar customizada - ver RedrawTabBar/RedrawRuler)
;- ------------------------------------------------------------

; Gadget Scintilla da aba ativa no momento, ou 0 se nao houver nenhuma aba.
Procedure ActiveSciGadget()
  If ActiveTabPosition < 0 Or Not SelectElement(Docs(), ActiveTabPosition)
    ProcedureReturn 0
  EndIf
  ProcedureReturn Docs()\SciGadget
EndProcedure

; Insere Text na posicao do cursor (substituindo a selecao, se houver) da aba
; ativa no momento - usado pelo botao "Injetar" do editor de sprites
; (SpriteEditorGui.pbi) pra colar o DATA gerado direto no codigo. O proprio
; Scintilla dispara a notificacao de mudanca normalmente (mesmo caminho que
; marca Docs()\Modified para edicao via teclado), entao nao precisa mexer
; nisso aqui manualmente.
Procedure.b InjectTextAtCursor(Text.s)
  Protected Sci = ActiveSciGadget()
  If Not Sci
    ProcedureReturn #False
  EndIf
  Protected *Buffer = UTF8(Text)
  ScintillaSendMessage(Sci, #SCI_REPLACESEL, 0, *Buffer)
  FreeMemory(*Buffer)
  ProcedureReturn #True
EndProcedure

; Torna a aba em Position a aba visivel/ativa: mostra o ScintillaGadget dela e
; esconde todos os outros, atualiza a selecao visual da tab bar e a regua.
Procedure SetActiveTab(Position)
  TabDebugLog("SetActiveTab(" + Str(Position) + ")  DocsCount=" + Str(ListSize(Docs())) + "  ActiveBefore=" + Str(ActiveTabPosition))
  If Not SelectElement(Docs(), Position)
    TabDebugLog("  SetActiveTab: SelectElement FALHOU, abortando")
    ProcedureReturn
  EndIf

  ActiveTabPosition = Position

  Protected P = 0
  ForEach Docs()
    HideGadget(Docs()\SciGadget, Bool(P <> Position))
    P + 1
  Next

  SelectElement(Docs(), Position)
  SetActiveGadget(Docs()\SciGadget)
  UpdateLineNumberMargin(Docs()\SciGadget)

  RedrawTabBar()
  RedrawRuler()
  UpdateStatusBar()
EndProcedure

Procedure AddDocumentTab(Path.s = "", Content.s = "", Mode.s = "DMX", UntitledBase.s = "noname")
  Protected InnerW, InnerH, Sci

  TabDebugLog("AddDocumentTab entrada  Path='" + Path + "'  Mode=" + Mode + "  DocsCountAntes=" + Str(ListSize(Docs())))

  InnerW = GadgetWidth(#RulerGadget)
  InnerH = WindowHeight(#MainWindow) - StatusBarHeight(#MainStatusBar) - #TabBar_Height - #Ruler_Height
  If InnerW <= 0 : InnerW = WindowWidth(#MainWindow) : EndIf
  If InnerH <= 0 : InnerH = 200 : EndIf

  Sci = ScintillaGadget(#PB_Any, 0, #TabBar_Height + #Ruler_Height, InnerW, InnerH, @ScintillaCallBack())
  SetupEditorStyles(Sci)

  ; Se Path foi informado (abrindo um arquivo existente), o modo e detectado
  ; pela extensao, ignorando o parametro Mode (que so vale para "Novo"/"Novo
  ; Assembly", quando ainda nao ha arquivo em disco).
  Protected DocMode.s = Mode
  If Path <> ""
    Select LCase(GetExtensionPart(Path))
      Case "asm", "z80", "mac"
        DocMode = "ASM"
      Case "bas"
        DocMode = "BAS" ; MSX-BASIC classico "padrao" (msxbas2rom etc) - ver MsxBas2RomSupport.pbi
      Case "md"
        DocMode = "MD"  ; manuais/artigos - ver HighlightMarkdownText/MdViewerGui.pbi
      Default
        DocMode = "DMX"
    EndSelect
  EndIf

  AddElement(Docs())
  Docs()\Path      = Path
  Docs()\Mode      = DocMode
  Docs()\Modified  = #False
  Docs()\SciGadget = Sci
  If Path = ""
    Protected UntitledExt.s = ".dmx"
    If DocMode = "ASM"
      UntitledExt = ".asm"
    ElseIf DocMode = "BAS"
      UntitledExt = ".bas"
    ElseIf DocMode = "MD"
      UntitledExt = ".md"
    EndIf
    If UntitledBase = "noname"
      UntitledCount + 1
      Docs()\UntitledName = "noname" + Str(UntitledCount) + UntitledExt
    Else
      NestorBasicUntitledCount + 1
      Docs()\UntitledName = UntitledBase + Str(NestorBasicUntitledCount) + UntitledExt
    EndIf
  EndIf

  If Content <> ""
    SuppressModifiedTracking = #True
    WriteSciText(Sci, Content)
    SuppressModifiedTracking = #False
  EndIf

  ScintillaSendMessage(Sci, #SCI_EMPTYUNDOBUFFER)
  Docs()\Modified = #False

  Protected NewPosition = ListSize(Docs()) - 1
  TabDebugLog("AddDocumentTab saida  NewPosition=" + Str(NewPosition) + "  Sci=" + Str(Sci) + "  DocsCountDepois=" + Str(ListSize(Docs())))
  UpdateTabCaption(NewPosition)
  SetActiveTab(NewPosition)
EndProcedure

Procedure FindDocumentByGadget(GadgetNum)
  Protected Position = 0
  ForEach Docs()
    If Docs()\SciGadget = GadgetNum
      ProcedureReturn Position
    EndIf
    Position + 1
  Next
  ProcedureReturn -1
EndProcedure

; Atualiza a barra de status (rodape): campo 0 = modo (INS/SBR); campo 1 =
; nome do arquivo da aba ativa; campo 2 = linha/coluna do cursor.
Procedure UpdateStatusBar()
  Protected ModeText.s = "", NameText.s = "", PosText.s = ""

  Protected Sci = ActiveSciGadget()
  If Sci
    If ScintillaSendMessage(Sci, #SCI_GETOVERTYPE)
      ModeText = "SBR"
    Else
      ModeText = "INS"
    EndIf
  EndIf

  If ActiveTabPosition >= 0 And SelectElement(Docs(), ActiveTabPosition)
    NameText = Docs()\DisplayCaption
    Protected Sci2 = Docs()\SciGadget
    Protected Pos = ScintillaSendMessage(Sci2, #SCI_GETCURRENTPOS)
    Protected Line = ScintillaSendMessage(Sci2, #SCI_LINEFROMPOSITION, Pos) + 1
    Protected Col = ScintillaSendMessage(Sci2, #SCI_GETCOLUMN, Pos) + 1
    PosText = "Lin " + Str(Line) + ", Col " + Str(Col)
  EndIf

  StatusBarText(#MainStatusBar, 0, ModeText)
  StatusBarText(#MainStatusBar, 1, NameText)
  StatusBarText(#MainStatusBar, 2, PosText, #PB_StatusBar_Right)
EndProcedure

; Recalcula Docs()\DisplayCaption (nome + " *" se modificado) e redesenha a tab
; bar. Chamada sempre que o nome, caminho ou estado "modificado" de uma aba muda.
Procedure UpdateTabCaption(Position)
  If Not SelectElement(Docs(), Position)
    ProcedureReturn
  EndIf

  Protected Caption.s
  If Docs()\Path = ""
    Caption = Docs()\UntitledName
  Else
    Caption = GetFilePart(Docs()\Path)
  EndIf
  If Docs()\Modified
    Caption + " *"
  EndIf
  Docs()\DisplayCaption = Caption

  RedrawTabBar()
  UpdateStatusBar()
EndProcedure

; Desenha a tab bar customizada (uma aba "chip" arredondada por documento, com
; botao de fechar embutido) - ver hit-test correspondente no loop de eventos
; principal (#PB_Event_Gadget / #TabBarGadget).
Procedure RedrawTabBar()
  Protected W = GadgetWidth(#TabBarGadget)
  Protected H = GadgetHeight(#TabBarGadget)
  Protected StartOk = StartDrawing(CanvasOutput(#TabBarGadget))
  TabDebugLog("RedrawTabBar  W=" + Str(W) + " H=" + Str(H) + " StartDrawingOk=" + Str(StartOk) + " DocsCount=" + Str(ListSize(Docs())) + " ActiveTabPosition=" + Str(ActiveTabPosition))
  If W <= 0 Or H <= 0 Or Not StartOk
    TabDebugLog("  RedrawTabBar: abortando (W/H invalido ou StartDrawing falhou)")
    ProcedureReturn
  EndIf

  Box(0, 0, W, H, Color_AppBg)
  DrawingMode(#PB_2DDrawing_Transparent)

  Protected X = 4, Position = 0
  Protected TabW, TextW, AvailTextW, BgColor, TextColor, CloseColor
  Protected Caption.s, DrawCaption.s, CloseX, CloseY

  ForEach Docs()
    Caption = Docs()\DisplayCaption
    TextW = TextWidth(Caption)
    TabW = TextW + 2 * #Tab_PadX + #Tab_CloseSize + #Tab_CloseGap
    If TabW < #Tab_MinWidth : TabW = #Tab_MinWidth : EndIf
    If TabW > #Tab_MaxWidth : TabW = #Tab_MaxWidth : EndIf

    Docs()\TabX1 = X
    Docs()\TabX2 = X + TabW

    If Position = ActiveTabPosition
      BgColor = Color_EditorBg : TextColor = Color_TextActive
    ElseIf Position = HoverTabPosition
      BgColor = Color_TabHover : TextColor = Color_TextActive
    Else
      BgColor = Color_TabInactive : TextColor = Color_TextInactive
    EndIf

    DrawingMode(#PB_2DDrawing_Default)
    If EditorCfg\Style = "Classic"
      Box(X, 6, TabW, H - 6, BgColor)
    Else
      RoundBox(X, 6, TabW, H - 6, 6, 6, BgColor)
    EndIf
    DrawingMode(#PB_2DDrawing_Transparent)

    AvailTextW = TabW - 2 * #Tab_PadX - #Tab_CloseSize - #Tab_CloseGap
    DrawCaption = Caption
    While TextWidth(DrawCaption) > AvailTextW And Len(DrawCaption) > 1
      DrawCaption = Left(DrawCaption, Len(DrawCaption) - 1)
    Wend
    If DrawCaption <> Caption
      DrawCaption = Left(DrawCaption, Len(DrawCaption) - 1) + "…"
    EndIf

    FrontColor(TextColor)
    DrawText(X + #Tab_PadX, (H - TextHeight(DrawCaption)) / 2, DrawCaption)

    CloseX = X + TabW - #Tab_PadX - #Tab_CloseSize
    CloseY = (H - #Tab_CloseSize) / 2 + 3
    Docs()\CloseX1 = CloseX
    Docs()\CloseX2 = CloseX + #Tab_CloseSize

    If Position = HoverCloseTabPosition
      CloseColor = Color_CloseHover
    Else
      CloseColor = TextColor
    EndIf
    FrontColor(CloseColor)
    LineXY(CloseX, CloseY, CloseX + #Tab_CloseSize, CloseY + #Tab_CloseSize)
    LineXY(CloseX, CloseY + #Tab_CloseSize, CloseX + #Tab_CloseSize, CloseY)

    If Position = ActiveTabPosition And TabW > 12
      Box(X + 6, H - 3, TabW - 12, 3, Color_Accent)
    EndIf

    X + TabW + #Tab_Gap
    Position + 1
  Next

  StopDrawing()
EndProcedure

; Desenha a regua de colunas da aba ativa, alinhada pixel a pixel com o texto
; do ScintillaGadget correspondente (mesma largura de caractere, mesma margem,
; mesmo deslocamento de rolagem horizontal) - ver #Event_UpdateUI no loop
; principal, que redesenha isto a cada rolagem/mudanca de caret.
Procedure RedrawRuler()
  Protected Sci = ActiveSciGadget()
  Protected W = GadgetWidth(#RulerGadget)
  Protected H = GadgetHeight(#RulerGadget)
  If W <= 0 Or H <= 0 Or Not StartDrawing(CanvasOutput(#RulerGadget))
    ProcedureReturn
  EndIf

  Box(0, 0, W, H, Color_RulerBg)

  If Sci
    Protected *Zero = UTF8("0")
    Protected CharW = ScintillaSendMessage(Sci, #SCI_TEXTWIDTH, #STYLE_DEFAULT, *Zero)
    FreeMemory(*Zero)
    If CharW <= 0 : CharW = 8 : EndIf

    Protected MarginTotal = ScintillaSendMessage(Sci, #SCI_GETMARGINWIDTHN, 0) + ScintillaSendMessage(Sci, #SCI_GETMARGINWIDTHN, 1) + ScintillaSendMessage(Sci, #SCI_GETMARGINWIDTHN, 2) + ScintillaSendMessage(Sci, #SCI_GETMARGINWIDTHN, 3) + ScintillaSendMessage(Sci, #SCI_GETMARGINWIDTHN, 4)
    Protected XOffset = ScintillaSendMessage(Sci, #SCI_GETXOFFSET)
    Protected FirstColX = MarginTotal - XOffset

    Protected FirstCol = 0
    If FirstColX < 0
      FirstCol = (0 - FirstColX) / CharW
    EndIf

    DrawingMode(#PB_2DDrawing_Transparent)

    Protected Col = FirstCol, X, Label.s
    Repeat
      X = FirstColX + Col * CharW
      If X > W
        Break
      EndIf
      If X >= 0
        If (Col + 1) % 10 = 0
          FrontColor(Color_RulerTick)
          LineXY(X, H - 10, X, H - 1)
          Label = Str(Col + 1)
          FrontColor(Color_RulerText)
          DrawText(X - TextWidth(Label) / 2, 1, Label)
        ElseIf (Col + 1) % 5 = 0
          FrontColor(Color_RulerTick)
          LineXY(X, H - 6, X, H - 1)
        Else
          FrontColor(Color_RulerTick)
          LineXY(X, H - 3, X, H - 1)
        EndIf
      EndIf
      Col + 1
    Until Col > FirstCol + 2000 ; guarda de seguranca (evita loop infinito se CharW ficar 0)
  EndIf

  StopDrawing()
EndProcedure

; Abre Path numa aba: se ja estiver aberto, so troca pra ela; senao le do
; disco e cria a aba (AddDocumentTab detecta o modo pela extensao). Usado por
; OpenDocumentDialog() (usuario escolhe o arquivo) e por ProjIndex_OpenWindow()
; (usuario clica um "documento" listado no indice do projeto). #True se a aba
; ficou pronta (ja existia ou foi aberta agora), #False se o arquivo nao pode
; ser lido (mensagem de erro ja mostrada aqui).
Procedure.b OpenFileIntoTab(Path.s)
  Protected Position = 0
  ForEach Docs()
    If Docs()\Path = Path
      SetActiveTab(Position)
      ProcedureReturn #True
    EndIf
    Position + 1
  Next

  Protected FileNum = ReadFile(#PB_Any, Path, #PB_File_BOM)
  If Not FileNum
    MessageRequester("Erro", "Nao foi possivel abrir o arquivo:" + Chr(10) + Path, #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  Protected Content.s
  While Not Eof(FileNum)
    Content + ReadString(FileNum, #PB_File_IgnoreEOL) + Chr(13) + Chr(10)
  Wend
  CloseFile(FileNum)

  AddDocumentTab(Path, Content)
  ProcedureReturn #True
EndProcedure

Procedure OpenDocumentDialog()
  Protected Path.s = OpenFileRequester("Abrir arquivo", "", #File_Pattern_Open, 0)
  If Path = ""
    ProcedureReturn
  EndIf

  OpenFileIntoTab(Path)
EndProcedure

Procedure.b SaveDocument(SaveAs.b = #False)
  Protected Position = ActiveTabPosition
  If Position < 0 Or Not SelectElement(Docs(), Position)
    ProcedureReturn #False
  EndIf

  Protected Path.s = Docs()\Path
  Protected Pattern.s = #File_Pattern
  If Docs()\Mode = "ASM"
    Pattern = #File_Pattern_ASM
  ElseIf Docs()\Mode = "MD"
    Pattern = #File_Pattern_MD
  EndIf

  If SaveAs Or Path = ""
    Protected Suggestion.s = Path
    If Suggestion = ""
      Suggestion = Docs()\UntitledName
    EndIf
    Protected NewPath.s = SaveFileRequester("Salvar como", Suggestion, Pattern, 0)
    If NewPath = ""
      ProcedureReturn #False
    EndIf
    Path = NewPath
  EndIf

  Protected FileNum = CreateFile(#PB_Any, Path)
  If Not FileNum
    MessageRequester("Erro", "Nao foi possivel salvar o arquivo:" + Chr(10) + Path, #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  Protected Text.s = ReadSciText(Docs()\SciGadget)
  WriteString(FileNum, Text)
  CloseFile(FileNum)

  Docs()\Path     = Path
  Docs()\Modified = #False
  UpdateTabCaption(Position)

  ; Alem do arquivo em disco, mantem uma copia atualizada do conteudo desta
  ; aba dentro do projeto atual (.msxproject) e registra a pasta como "onde
  ; os arquivos estao sendo trabalhados" - ver ProjectDB::StoreDocument()/
  ; SetWorkingDir() em ProjectDB.pbi.
  ProjectDB::StoreDocument(Path, Docs()\Mode, Text)
  ProjectDB::SetWorkingDir(GetPathPart(Path))

  ProcedureReturn #True
EndProcedure

Procedure.b ConfirmDiscard(Text.s)
  Protected Result = MessageRequester(#App_Title, Text, #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning)
  ProcedureReturn Bool(Result = #PB_MessageRequester_Yes)
EndProcedure

; Se Path nao tem nenhuma extensao, acrescenta Ext (sem ponto) - usado nos
; dialogos de projeto (.msxproject) pra garantir a extensao padrao mesmo
; quando o usuario so digita um nome no SaveFileRequester; nao mexe na
; escolha se o usuario ja digitou alguma outra extensao.
Procedure.s EnsureExtension(Path.s, Ext.s)
  If GetExtensionPart(Path) = ""
    ProcedureReturn Path + "." + Ext
  EndIf
  ProcedureReturn Path
EndProcedure

; Splashscreen na abertura do programa: mostra paleobasic.png (fica direto em
; dist\, ao lado do proprio .exe - GetPathPart(ProgramFilename())) numa
; janela sem borda, centralizada e sempre no topo, por pelo menos
; #App_SplashMinMs no total.
; Dividido em duas chamadas (Show logo no inicio do "Programa principal",
; Close so depois do init pesado) em vez de um Delay() bloqueante isolado,
; pra nao atrasar a abertura alem do necessario: se o init (InitKeywordMaps,
; EditorCfg_Load etc.) demorar quase #App_SplashMinMs sozinho, App_CloseSplash
; so espera a diferenca (podendo ser quase nada); se for rapido, espera o
; resto. Se o arquivo da imagem nao existir (build fora do repo completo),
; App_SplashWin fica -1 e App_CloseSplash() e um no-op - nunca trava o
; programa por causa da splash.
Global App_SplashWin.i = -1
Global App_SplashImg.i = -1
Global App_SplashStartTime.i

Procedure App_ShowSplash()
  Protected SplashPath.s = GetPathPart(ProgramFilename()) + "paleobasic.png"
  App_SplashImg = LoadImage(#PB_Any, SplashPath)
  If Not App_SplashImg
    ProcedureReturn
  EndIf
  ResizeImage(App_SplashImg, #App_SplashW, #App_SplashH, #PB_Image_Smooth)
  App_SplashWin = OpenWindow(#PB_Any, 0, 0, #App_SplashW, #App_SplashH, "",
                              #PB_Window_BorderLess | #PB_Window_ScreenCentered)
  ; NAO usar "If Not App_SplashWin" aqui: #MainWindow (Enumeration Windows) ainda
  ; nao foi aberto neste ponto, entao o alocador #PB_Any pode legitimamente devolver
  ; 0 pra esta janela - "Not 0" seria tratado como falha por engano (bug pego e
  ; corrigido antes deste comentario existir: a splash nunca aparecia, porque
  ; App_SplashWin virava -1 mesmo com OpenWindow tendo funcionado). IsWindow() e o
  ; jeito certo de checar sucesso quando o numero pode ser 0.
  If Not IsWindow(App_SplashWin)
    FreeImage(App_SplashImg)
    App_SplashImg = -1
    App_SplashWin = -1
    ProcedureReturn
  EndIf
  ImageGadget(#PB_Any, 0, 0, #App_SplashW, #App_SplashH, ImageID(App_SplashImg))
  StickyWindow(App_SplashWin, #True)
  WindowEvent() ; bombeia a fila uma vez pra garantir que a janela realmente pinte antes do init continuar
  App_SplashStartTime = ElapsedMilliseconds()
EndProcedure

Procedure App_CloseSplash()
  If App_SplashWin = -1
    ProcedureReturn
  EndIf
  Protected Remaining = #App_SplashMinMs - (ElapsedMilliseconds() - App_SplashStartTime)
  While Remaining > 0
    WindowEvent()
    Delay(10)
    Remaining - 10
  Wend
  CloseWindow(App_SplashWin)
  FreeImage(App_SplashImg)
  App_SplashWin = -1
EndProcedure

; Icone do aplicativo (paleobasic.ico) para toda janela top-level (barra de
; titulo/sistema, barra de tarefas, Alt+Tab) - extraido do proprio .exe em
; runtime via ExtractIconEx, nao de um arquivo .ico ao lado do executavel:
; o .ico ja fica embutido como recurso do binario pelo /ICON do build.ps1
; (o mesmo recurso que o Windows Explorer usa pra mostrar o icone do
; arquivo), entao ler de volta do proprio processo mantem o .exe
; autocontido, sem depender de um arquivo externo sobreviver ao lado dele.
; Carregado uma unica vez (cache nos Globals) e reaplicado em cada janela
; nova via WM_SETICON.
Global App_IconBig.i, App_IconSmall.i, App_IconLoaded.b = #False

; Fonte de UI moderna (Segoe UI) aplicada a todos os controles nativos das
; janelas secundarias (dialogos de configuracao, gerenciador de disco, etc.)
; no lugar da fonte padrao do sistema - carregada uma unica vez, mesma
; logica de cache do icone acima. O #MainWindow fica de fora (ver
; App_ApplyWindowIcon abaixo): sua tab bar/regua/editor ja tem tipografia
; propria, cuidadosamente ajustada por SetupEditorStyles().
Global App_UIFont.i = 0, App_UIFontLoaded.b = #False

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  ; DwmSetWindowAttribute nao vem pre-declarada pelo PureBasic (ao contrario
  ; de SendMessage_/GetWindowLong_/etc, que fazem parte do conjunto de APIs
  ; que o compilador conhece nativamente) - precisa de Import explicito
  ; contra Dwmapi.lib. So usada pra pintar a barra de titulo escura no tema
  ; Dark (DWMWA_USE_IMMERSIVE_DARK_MODE), puramente cosmetico.
  Import "Dwmapi.lib"
    DwmSetWindowAttribute(hWnd.i, dwAttribute.l, *pvAttribute, cbAttribute.l)
  EndImport
CompilerEndIf

; ------------------------------------------------------------
; Dark mode nativo dos controles (Windows 10 1809+ / 11)
; ------------------------------------------------------------
; Fundo realmente escuro em botoes/checkboxes/combos/campos de texto, nao so
; a cor de fundo da janela por tras deles (o que o resto de App_ApplyWindowIcon
; ja fazia). Usa as APIs nao documentadas da uxtheme.dll que o Explorer, o
; Windows Terminal, o VS Code etc. usam pra isso - nao existe API publica pra
; "modo escuro de verdade" em controles Win32 nativos. Referencia:
; github.com/ysc3839/win32-darkmode (conferido em 2026-08-02).
;
; Ordinais confirmados nesse projeto de referencia (numero, nao nome - GetProcAddress
; por ordinal, ver App_GetProcAddressOrdinal abaixo):
;   104 RefreshImmersiveColorPolicyState()
;   133 AllowDarkModeForWindow(HWND, BOOL) - liga/desliga por janela
;   135 SetPreferredAppMode(PreferredAppMode) - build >= 18362 (1903); em
;       builds mais antigas (1809) o mesmo ordinal e AllowDarkModeForApp(BOOL)
;   136 FlushMenuThemes()
; Como sao ordinais, o numero pode em teoria apontar pra outra funcao numa
; build futura do Windows - por isso so ativa depois de confirmar
; build >= 17763 (1809, primeira com essas APIs) via RtlGetNtVersionNumbers
; (ntdll - tambem nao documentada, mas usada ha mais de uma decada por
; incontaveis apps pra saber a build real sem o teto que GetVersion() aplica
; sem manifesto de compatibilidade) e todo GetProcAddress e checado antes de
; usar. Se qualquer passo falhar (Windows mais antigo, ordinal ausente...),
; App_DarkModeSupported fica #False e a janela so fica com o fundo escuro já
; aplicado acima - nunca pior do que sem essa funcionalidade.
CompilerIf #PB_Compiler_OS = #PB_OS_Windows

  Enumeration
    #App_AppMode_Default
    #App_AppMode_AllowDark
  EndEnumeration

  Prototype.l Proto_SetPreferredAppMode(Mode.l)
  Prototype.l Proto_AllowDarkModeForWindow(hWnd.i, Allow.l)
  Prototype   Proto_FlushMenuThemes()
  Prototype   Proto_RefreshImmersiveColorPolicyState()
  Prototype   Proto_RtlGetNtVersionNumbers(*Major.Long, *Minor.Long, *Build.Long)

  ; Import proprio de GetProcAddress (em vez do GetProcAddress_ que o PB ja
  ; conhece nativamente) com o 2o parametro tipado como Long em vez de
  ; string: por ordinal, o valor passado e o proprio numero (equivalente ao
  ; macro C MAKEINTRESOURCE), nao um ponteiro pra string - declarar como
  ; Long deixa isso explicito e evita qualquer ambiguidade de tipo na
  ; chamada (GetProcAddress_ nativo do PB espera uma string no 2o parametro).
  ;
  ; Real bug found 2026-08-18 (docs/SPEC.md module 32q): a bare "As GetProcAddress" here
  ; linked fine on x64 pbcompiler builds (no name decoration on that ABI) but failed with
  ; "undefined symbol: GetProcAddress" on this machine's x86 pbcompiler.exe - x86 Windows
  ; stdcall imports need the decorated form (_Name@ArgBytes) in the import library, and
  ; PureBasic only auto-decorates names for its OWN built-in WinAPI declares, not for a
  ; manual Import block's "As" alias. GetProcAddress(HMODULE, LPCSTR) takes 2 pointer-sized
  ; stdcall args = 8 bytes on x86, hence "_GetProcAddress@8"; on x64 there's no decoration
  ; at all, so the plain name is required there instead - CompilerSelect picks the form
  ; matching whichever pbcompiler variant is doing the actual build.
  Import "Kernel32.lib"
    CompilerSelect #PB_Compiler_Processor
      CompilerCase #PB_Processor_x86
        App_GetProcAddressOrdinal(hModule.i, Ordinal.l) As "_GetProcAddress@8"
      CompilerDefault
        App_GetProcAddressOrdinal(hModule.i, Ordinal.l) As "GetProcAddress"
    CompilerEndSelect
  EndImport

  Global App_pSetPreferredAppMode.Proto_SetPreferredAppMode
  Global App_pAllowDarkModeForWindow.Proto_AllowDarkModeForWindow
  Global App_pFlushMenuThemes.Proto_FlushMenuThemes
  Global App_pRefreshImmersiveColorPolicyState.Proto_RefreshImmersiveColorPolicyState
  Global App_DarkModeInitDone.b = #False
  Global App_DarkModeSupported.b = #False

  Procedure App_InitDarkMode()
    App_DarkModeInitDone = #True

    ; GetFunction() (o wrapper de alto nivel do PB pra OpenLibrary/GetProcAddress,
    ; ja usado em EdAddFontResourceEx acima em EditorSettings.pbi) em vez de
    ; GetModuleHandle_/GetProcAddress_ crus: a assinatura WinAPI real de
    ; GetProcAddress espera SEMPRE uma string ANSI pro nome da funcao (nao
    ; existe variante "W"), mas a ligacao generica GetProcAddress_ do PB
    ; marshala a string literal como Unicode neste projeto (compilado em
    ; Unicode) - o nome chega corrompido e a busca falha sempre (confirmado
    ; via log: GetProcAddress_ nunca encontrava RtlGetNtVersionNumbers,
    ; deixando App_DarkModeSupported permanentemente #False). GetFunction faz
    ; essa conversao corretamente por dentro.
    Protected hNtdll = OpenLibrary(#PB_Any, "ntdll.dll")
    If Not hNtdll : ProcedureReturn : EndIf
    Protected *pRtlGetNtVersionNumbers = GetFunction(hNtdll, "RtlGetNtVersionNumbers")
    If Not *pRtlGetNtVersionNumbers : ProcedureReturn : EndIf

    Protected pVersionFn.Proto_RtlGetNtVersionNumbers = *pRtlGetNtVersionNumbers
    Protected Major.l, Minor.l, Build.l
    pVersionFn(@Major, @Minor, @Build)
    Build & $0FFFFFFF   ; os 4 bits mais altos sao flags internas, nao fazem parte do numero da build

    If Build < 17763    ; Windows 10 1809 - primeira build com essas APIs
      ProcedureReturn
    EndIf

    Protected hUxtheme = LoadLibrary_("uxtheme.dll")
    If Not hUxtheme : ProcedureReturn : EndIf

    App_pSetPreferredAppMode = App_GetProcAddressOrdinal(hUxtheme, 135)
    App_pAllowDarkModeForWindow = App_GetProcAddressOrdinal(hUxtheme, 133)
    App_pFlushMenuThemes = App_GetProcAddressOrdinal(hUxtheme, 136)
    App_pRefreshImmersiveColorPolicyState = App_GetProcAddressOrdinal(hUxtheme, 104)

    If App_pSetPreferredAppMode = 0 Or App_pAllowDarkModeForWindow = 0 Or App_pFlushMenuThemes = 0
      ProcedureReturn
    EndIf

    App_pSetPreferredAppMode(#App_AppMode_AllowDark)
    If App_pRefreshImmersiveColorPolicyState
      App_pRefreshImmersiveColorPolicyState()
    EndIf
    App_pFlushMenuThemes()
    App_DarkModeSupported = #True
  EndProcedure

  ; Callback de EnumChildWindows_ que aplica o "estilo moderno" (fonte +
  ; tema) a cada controle filho de uma janela - fonte Segoe UI sempre, tema
  ; "DarkMode_Explorer" so quando App_DarkModeSupported. So e disparado de
  ; forma preguicosa, na primeira mensagem que a janela recebe depois de
  ; entrar no loop de eventos (ver App_DarkModeWindowProc abaixo) - NUNCA
  ; direto de dentro de App_ApplyWindowIcon: la ele roda logo apos
  ; OpenWindow(), mas ANTES de qualquer TextGadget/ButtonGadget/etc ser
  ; criado em cada um dos ~25 dialogos (todos seguem o padrao OpenWindow ->
  ; App_ApplyWindowIcon -> criacao dos gadgets) - EnumChildWindows_ chamado
  ; naquele momento nao encontra filho nenhum. Bug real, descoberto so
  ; depois de tirar um screenshot de verdade da janela (PrintWindow, ver
  ; SPEC/CLAUDE.md) e ver rotulos com fundo claro/texto marrom, destoando do
  ; resto ja escuro - nao daria pra pegar isso so lendo o codigo.
  ;
  ; Nota: tentativa de tambem forcar a cor de rotulos (TextGadget) via
  ; SetGadgetColor(GetDlgCtrlID_(hWnd), ...) foi abandonada - GetDlgCtrlID_
  ; NAO devolve o numero do gadget PB neste caso (os valores batidos, ~96
  ; bytes um do outro, sao claramente enderecos de alguma struct interna do
  ; PB, nao IDs de controle) e a chamada nunca acertava um gadget de
  ; verdade. A cor marrom do texto dos rotulos se mostrou independente de
  ; qualquer coisa neste arquivo (persiste igual com SetWindowColor
  ; desligado e com App_DarkModeSupported nos dois estados) - parece ser o
  ; render padrao do TextGadget do PB nesta versao/maquina, nao uma
  ; regressao introduzida aqui. Corrigir isso direito exigiria colorir cada
  ; rotulo no proprio arquivo de cada dialogo (onde o numero do gadget e
  ; conhecido de verdade), um trabalho maior, dialogo por dialogo.
  Procedure App_StyleChildCallback(hWnd, lParam)
    If App_UIFont
      SendMessage_(hWnd, #WM_SETFONT, FontID(App_UIFont), #True)
    EndIf

    If App_DarkModeSupported
      If EditorCfg_ThemeIsDark(EditorCfg\Theme)
        SetWindowTheme_(hWnd, @"DarkMode_Explorer", #Null)
      Else
        SetWindowTheme_(hWnd, #Null, #Null)
      EndIf
    EndIf
    ProcedureReturn #True
  EndProcedure

  ; Uma entrada por HWND, nunca limpa - cada dialogo abre com uma janela
  ; nova (HWND novo) por sessao de uso, o custo de memoria de HWNDs antigos
  ; acumulados ao longo de uma sessao longa e desprezivel.
  Global NewMap App_StyledWindows.b()

  ; Pincel cacheado (evita vazar um HBRUSH a cada repintura) pro fundo dos
  ; campos de texto/combo via WM_CTLCOLOREDIT/LISTBOX - continua util como
  ; reforco do que o SetGadgetColor acima ja faz (mesma cor, mesmo
  ; resultado), mas e o unico jeito de tambem colorir o dropdown do combo,
  ; que SetGadgetColor nao alcanca.
  Procedure App_EditorBgBrush()
    Static Cached.i, CachedRGB.i = -1
    If CachedRGB <> Color_EditorBg
      If Cached : DeleteObject_(Cached) : EndIf
      Cached = CreateSolidBrush_(Color_EditorBg)
      CachedRGB = Color_EditorBg
    EndIf
    ProcedureReturn Cached
  EndProcedure

  ; Mesmo cache de App_EditorBgBrush() acima, mas pro fundo do proprio
  ; dialogo (Color_AppBg) - usado por WM_CTLCOLORSTATIC (ver
  ; App_DarkModeWindowProc) pra rotulos (TextGadget) nao ficarem com uma
  ; "placa" clara atras do texto: sem isso, o Windows pinta o fundo do
  ; controle STATIC com a cor de janela padrao do tema do SO (clara),
  ; mesmo com SetWindowColor(Win, Color_AppBg) ja aplicado na janela em
  ; volta - texto marrom escuro sobre fundo claro, destoando do resto
  ; escuro do dialogo (achado real via screenshot, nao so leitura de
  ; codigo - ver comentario de App_StyleChildCallback acima. A tentativa
  ; anterior de resolver isso via SetGadgetColor()+GetDlgCtrlID_ falhava
  ; porque GetDlgCtrlID_ nao devolve o numero do gadget PB neste contexto;
  ; WM_CTLCOLORSTATIC resolve no nivel de mensagem, sem precisar do numero
  ; do gadget, e cobre TextGadget/GroupBox/static de qualquer dialogo
  ; automaticamente - nao so os ja tratados via WM_CTLCOLOREDIT/LISTBOX
  ; acima).
  Procedure App_AppBgBrush()
    Static Cached.i, CachedRGB.i = -1
    If CachedRGB <> Color_AppBg
      If Cached : DeleteObject_(Cached) : EndIf
      Cached = CreateSolidBrush_(Color_AppBg)
      CachedRGB = Color_AppBg
    EndIf
    ProcedureReturn Cached
  EndProcedure

  Procedure App_DarkModeWindowProc(hWnd, uMsg, wParam, lParam)
    ; So prime em WM_PAINT (nao na primeira mensagem qualquer): mensagens
    ; como WM_PARENTNOTIFY chegam SINCRONAMENTE durante a criacao de cada
    ; gadget (no meio das chamadas TextGadget()/ButtonGadget()/etc, uma por
    ; controle), entao "a primeira mensagem que a janela recebe" podia pegar
    ; o dialogo com 1 controle so (ou nenhum) - confirmado com log real
    ; (Static, ctrlid=-1, nem gadget de verdade ainda). WM_PAINT so acontece
    ; quando a fila de mensagens fica ociosa, ou seja, depois que TODO o
    ; codigo sincrono de criacao de gadgets do procedimento ja rodou.
    If uMsg = #WM_PAINT
      Protected Key.s = Str(hWnd)
      If Not App_StyledWindows(Key)
        App_StyledWindows(Key) = #True
        EnumChildWindows_(hWnd, @App_StyleChildCallback(), 0)
      EndIf
    EndIf

    If App_DarkModeSupported And EditorCfg_ThemeIsDark(EditorCfg\Theme)
      Select uMsg
        Case #WM_CTLCOLOREDIT, #WM_CTLCOLORLISTBOX
          SetTextColor_(wParam, Color_TextActive)
          SetBkColor_(wParam, Color_EditorBg)
          ProcedureReturn App_EditorBgBrush()
        Case #WM_CTLCOLORSTATIC
          SetTextColor_(wParam, Color_TextActive)
          SetBkColor_(wParam, Color_AppBg)
          ProcedureReturn App_AppBgBrush()
      EndSelect
    EndIf
    ProcedureReturn #PB_ProcessPureBasicEvents
  EndProcedure

CompilerEndIf

Procedure App_ApplyWindowIcon(WinNum)
  ; ExtractIconEx_/WM_SETICON sao WinAPI puro (achado real compilando no Linux
  ; via WSL, 2026-07-29, ver CLAUDE.md) - sem equivalente generico aqui pra
  ; outros OS (Linux nao embute /ICON no binario, ver build.sh), entao esta
  ; funcao vira no-op fora do Windows. Chamada incondicionalmente de ~25
  ; lugares (toda janela top-level), por isso o guard fica dentro do corpo em
  ; vez de nos call sites. Alem do icone, agora tambem centraliza o "toque
  ; moderno" comum a toda janela top-level: fonte Segoe UI nos controles
  ; nativos, fundo alinhado ao tema (Color_AppBg, ver ApplyTheme()), barra
  ; de titulo escura no tema Dark e, quando App_DarkModeSupported (ver
  ; App_InitDarkMode acima), controles nativos (botoes/combos/campos de
  ; texto) com fundo escuro de verdade - tirar a cara "Windows 95" dos
  ; dialogos, sem mexer no editor principal (ja tem tipografia/tema
  ; proprios) nem arriscar reescrever cada janela individualmente.
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    If Not App_IconLoaded
      App_IconLoaded = #True
      ExtractIconEx_(ProgramFilename(), 0, @App_IconBig, @App_IconSmall, 1)
    EndIf
    If Not IsWindow(WinNum)
      ProcedureReturn
    EndIf
    If App_IconBig
      SendMessage_(WindowID(WinNum), #WM_SETICON, #ICON_BIG, App_IconBig)
    EndIf
    If App_IconSmall
      SendMessage_(WindowID(WinNum), #WM_SETICON, #ICON_SMALL, App_IconSmall)
    EndIf

    If Not App_UIFontLoaded
      App_UIFontLoaded = #True
      App_UIFont = LoadFont(#PB_Any, "Segoe UI", 9)
    EndIf

    If Not App_DarkModeInitDone
      App_InitDarkMode()
    EndIf

    ; AllowDarkModeForWindow tambem no #MainWindow (nao so nos dialogos
    ; secundarios abaixo): ele proprio nao usa o resto deste bloco (tab
    ; bar/regua/editor tem tema proprio, ver ApplyTheme()), mas seus filhos
    ; nativos novos - toolbar, status bar - se beneficiam do mesmo sinal
    ; "esta janela permite controles escuros" que comctl32 consulta na
    ; ancestral ao pintar esses controles.
    If App_DarkModeSupported
      App_pAllowDarkModeForWindow(WindowID(WinNum), EditorCfg_ThemeIsDark(EditorCfg\Theme))
    EndIf

    If WinNum <> #MainWindow
      SetWindowColor(WinNum, Color_AppBg)
      ; So registra o callback (fonte/cor dos filhos, ver App_StyleChildCallback
      ; acima) - nao chama EnumChildWindows_ aqui: os gadgets do dialogo ainda
      ; nao existem neste ponto (App_ApplyWindowIcon roda logo apos OpenWindow,
      ; antes de qualquer TextGadget/ButtonGadget/etc), so a primeira mensagem
      ; recebida ja dentro do loop de eventos garante isso.
      SetWindowCallback(@App_DarkModeWindowProc(), WinNum)
    EndIf

    Protected DarkModeFlag.l
    If EditorCfg_ThemeIsDark(EditorCfg\Theme)
      DarkModeFlag = #True
    Else
      DarkModeFlag = #False
    EndIf
    ; 20 = DWMWA_USE_IMMERSIVE_DARK_MODE (Windows 10 20H1+/11); builds mais
    ; antigos (1809-1903) usavam o valor 19 pro mesmo atributo - tenta os
    ; dois, sem erro se nenhum existir (versoes ainda mais antigas do Windows
    ; simplesmente ficam com a barra de titulo padrao).
    If DwmSetWindowAttribute(WindowID(WinNum), 20, @DarkModeFlag, SizeOf(Long))
      DwmSetWindowAttribute(WindowID(WinNum), 19, @DarkModeFlag, SizeOf(Long))
    EndIf
  CompilerEndIf
EndProcedure

; Garante que o projeto ativo sempre tenha um alfabeto marcado com a tag
; "padrao" - pedido explicito do usuario pra que o Graphos III (menu TEXTO,
; GraphosScreenGui.pbi) e qualquer outro consumidor futuro sempre encontrem
; um alfabeto pronto pra usar, sem precisar que o usuario passe primeiro por
; "Criar -> Alfabeto Graphos III..." e registre um manualmente. So cria um
; alfabeto novo se NENHUM dos ja registrados tiver essa tag (percorre e
; confere via LastAlphabetTag() apos cada FetchAlphabet - nao ha indice por
; tag no schema); se ja existir um "padrao" (por exemplo, projeto salvo por
; uma sessao anterior), nao mexe em nada. O conteudo semeado e' o mesmo
; charset MSX embutido no executavel que "Novo alfabeto" ja usa
; (ProjectDB::FetchDefaultAlphabet(0, ...), ver DefaultCharsetMsx.pbi) -
; nenhum dado novo, so reaproveitado.
Procedure App_EnsureDefaultAlphabet()
  NewList Nums.i()
  ProjectDB::ListAlphabetNumbers(Nums())
  Protected Found.b = #False
  Dim ExistingBytes.a(255, 7)
  ForEach Nums()
    ProjectDB::FetchAlphabet(Nums(), ExistingBytes())
    If LCase(ProjectDB::LastAlphabetTag()) = "padrao"
      Found = #True
      Break
    EndIf
  Next
  If Not Found
    Protected NextNum.i = 0
    If ListSize(Nums()) > 0
      LastElement(Nums())
      NextNum = Nums() + 1
    EndIf
    Dim DefaultBytes.a(255, 7)
    If ProjectDB::FetchDefaultAlphabet(0, DefaultBytes())
      ProjectDB::StoreAlphabet(NextNum, "padrao", DefaultBytes())
    EndIf
  EndIf
EndProcedure

; Pedido explicito do usuario (2026-08-10): o .msxproject ja guarda uma
; copia dos fontes de texto (BASIC/.dmx/.amx/.bas e Assembly/.asm) via
; StoreDocument() - mas so quando cada aba e salva individualmente. Esta
; funcao forca uma resincronizacao completa (le o conteudo REAL do disco,
; nao o buffer do Scintilla - "pegar as versoes que estao no disco",
; pedido literal do usuario) pra todo caminho que o projeto ja conhece
; (ProjectDB::ListDocumentPaths()) MAIS toda aba aberta nesta sessao que
; ainda nao estava na lista (arquivo novo, salvo nesta sessao mas talvez
; ainda nao rastreado) - torna "Salvar projeto"/"Salvar Tudo"/fechar o
; programa um ponto onde o .msxproject fica garantidamente um espelho fiel
; do que esta no disco, pra poder levar so o .msxproject de uma maquina pra
; outra (ver RestoreMissingDocumentsToDisk() abaixo, o caminho inverso).
; Projeto ainda temporario ("noname", nunca salvo) nao tem nada persistente
; pra sincronizar - nao faz nada nesse caso.
Procedure ResyncProjectDocumentsFromDisk()
  If ProjectDB::IsTemp()
    ProcedureReturn
  EndIf

  NewList Paths.s()
  ProjectDB::ListDocumentPaths(Paths())

  Protected AlreadyListed.b, ExistingPath.s
  ForEach Docs()
    If Docs()\Path <> ""
      AlreadyListed = #False
      ForEach Paths()
        ExistingPath = Paths()
        If ExistingPath = Docs()\Path
          AlreadyListed = #True
          Break
        EndIf
      Next
      If Not AlreadyListed
        AddElement(Paths())
        Paths() = Docs()\Path
      EndIf
    EndIf
  Next

  Protected DiskPath.s, FNum.i, DiskContent.s, DocMode.s, TabIdx.i, FoundOpenTab.b
  ForEach Paths()
    DiskPath = Paths()
    If FileSize(DiskPath) < 0
      Continue ; arquivo nao existe mais no disco - nao ha nada fresco pra gravar
    EndIf

    FNum = ReadFile(#PB_Any, DiskPath, #PB_File_BOM)
    If Not FNum
      Continue
    EndIf
    DiskContent = ""
    While Not Eof(FNum)
      DiskContent + ReadString(FNum, #PB_File_IgnoreEOL) + #CRLF$
    Wend
    CloseFile(FNum)

    ; Mode: se houver uma aba aberta com este caminho, usa o Mode dela (mais
    ; confiavel); senao, mantem o Mode que o projeto ja tinha guardado antes.
    FoundOpenTab = #False
    ForEach Docs()
      If Docs()\Path = DiskPath
        DocMode = Docs()\Mode
        FoundOpenTab = #True
        Break
      EndIf
    Next
    If Not FoundOpenTab
      If ProjectDB::FetchDocument(DiskPath)
        DocMode = ProjectDB::LastDocumentMode()
      Else
        DocMode = "DMX" ; fallback razoavel pra um caminho novo sem historico
      EndIf
    EndIf

    ProjectDB::StoreDocument(DiskPath, DocMode, DiskContent)
  Next
EndProcedure

; Caminho inverso de ResyncProjectDocumentsFromDisk(): chamado logo apos
; abrir um projeto (ProjectDB::OpenExisting), extrai pro disco qualquer
; fonte que o projeto conhece mas que nao existe no caminho gravado -
; exatamente o caso de abrir o MESMO .msxproject numa maquina diferente
; (unidade/usuario/pasta diferentes, ver pedido do usuario "quando abrir em
; outro local, descompactar/extrair os fontes no diretorio"). O caminho
; gravado (de quando o projeto foi salvo, possivelmente noutra maquina) e
; so uma sugestao de NOME de arquivo - o destino real e sempre ao lado do
; .msxproject sendo aberto agora (ProjectDB::GetPath()), entao o projeto
; fica autocontido/portatil de verdade, sem depender da estrutura de pastas
; original. Quando o destino difere do caminho gravado, a linha da tabela
; "documents" e re-chaveada pro caminho novo (senao um Salvar futuro criaria
; uma segunda linha com o caminho antigo, nunca mais alcancavel).
Procedure RestoreMissingDocumentsToDisk()
  Protected ProjectDir.s = GetPathPart(ProjectDB::GetPath())
  If ProjectDir = ""
    ProcedureReturn ; projeto temporario - nao ha "ao lado do .msxproject" ainda
  EndIf

  NewList Paths.s()
  ProjectDB::ListDocumentPaths(Paths())

  Protected RecordedPath.s, TargetPath.s, FNum.i, RestoredCount.i = 0
  ForEach Paths()
    RecordedPath = Paths()
    If FileSize(RecordedPath) >= 0
      Continue ; ja existe no caminho gravado - nada a extrair
    EndIf

    If Not ProjectDB::FetchDocument(RecordedPath)
      Continue
    EndIf

    TargetPath = ProjectDir + GetFilePart(RecordedPath)
    If FileSize(TargetPath) >= 0
      Continue ; ja existe algo com esse nome ao lado do projeto - nao sobrescreve
    EndIf

    FNum = CreateFile(#PB_Any, TargetPath)
    If Not FNum
      Continue
    EndIf
    WriteString(FNum, ProjectDB::LastDocumentContent())
    CloseFile(FNum)
    RestoredCount + 1

    If TargetPath <> RecordedPath
      ProjectDB::StoreDocument(TargetPath, ProjectDB::LastDocumentMode(), ProjectDB::LastDocumentContent())
      ProjectDB::DeleteDocument(RecordedPath)
    EndIf
  Next

  If RestoredCount > 0
    ProjectDB::SetWorkingDir(ProjectDir)
    MessageRequester("Projeto aberto",
                     Str(RestoredCount) + " arquivo(s) fonte extraido(s) de volta pro disco em:" + Chr(10) + ProjectDir,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
  EndIf
EndProcedure

; Salva o projeto atual (menu Arquivo -> Salvar projeto / Salvar projeto
; como...). Se ja tem um caminho permanente e SaveAsFlag e #False, nao ha
; nada a fazer: ao contrario das abas de texto, o ProjectDB grava cada
; StoreSprite() na hora (SQLite), entao nunca fica "sujo" em memoria. Se
; ainda e o projeto temporario "noname" (ou SaveAsFlag = #True, pedindo
; explicitamente um novo nome/local), pede o caminho e promove/copia pra
; la via ProjectDB::SaveAs() - sugere o caminho atual quando ja permanente,
; pra facilitar "salvar uma copia com outro nome".
Procedure.b SaveProject(SaveAsFlag.b = #False)
  If Not SaveAsFlag And Not ProjectDB::IsTemp()
    ResyncProjectDocumentsFromDisk() ; pedido do usuario: "Salvar projeto" tambem resincroniza os fontes
    ProcedureReturn #True
  EndIf

  Protected Suggestion.s = ""
  If Not ProjectDB::IsTemp()
    Suggestion = ProjectDB::GetPath()
  EndIf

  Protected SavePath.s = SaveFileRequester("Salvar projeto como...", Suggestion, #File_Pattern_Project, 0)
  If SavePath = ""
    ProcedureReturn #False
  EndIf
  SavePath = EnsureExtension(SavePath, "msxproject")

  If Not ProjectDB::SaveAs(SavePath)
    MessageRequester("Erro ao salvar projeto",
                      "Nao foi possivel salvar em:" + Chr(10) + SavePath + Chr(10) + ProjectDB::GetLastError(),
                      #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf
  ResyncProjectDocumentsFromDisk()
  ProcedureReturn #True
EndProcedure

; Se o projeto atual (implicito "noname") ainda nao foi salvo num arquivo
; permanente e ja tem sprites registrados, oferece salvar antes de seguir
; em frente (usado antes de "Novo projeto" e ao sair). Devolve #True se e
; seguro continuar (nao havia nada a salvar, ou salvou com sucesso, ou o
; usuario preferiu descartar); #False so quando o usuario cancelou o
; dialogo de salvar - nesse caso a acao que chamou deve ser abortada, para
; nao perder dado silenciosamente.
Procedure.b OfferSaveProject()
  If Not ProjectDB::HasUnsavedContent()
    ProcedureReturn #True
  EndIf

  Protected Answer = MessageRequester("Projeto nao salvo",
                        "O projeto atual (noname) ainda nao foi salvo num arquivo permanente" + Chr(10) +
                        "e ja tem sprites registrados." + Chr(10) + Chr(10) +
                        "Deseja salvar antes de continuar?",
                        #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning)
  If Answer <> #PB_MessageRequester_Yes
    ProcedureReturn #True
  EndIf

  ProcedureReturn SaveProject(#True)
EndProcedure

; Arquivo -> Salvar Tudo: salva cada aba aberta (na ordem) mais o projeto,
; numa acao so. SaveDocument() so opera na aba ATIVA no momento (ver seu
; comentario) - nao tem parametro pra apontar pra uma aba especifica -
; entao o loop abaixo alterna a aba ativa a cada iteracao via SetActiveTab()
; e restaura a aba que estava ativa antes no final. Continua salvando as
; abas seguintes mesmo se o usuario cancelar o dialogo "Salvar como..." de
; uma aba ainda sem nome (melhor esforco, uma aba cancelada nao deve travar
; o salvamento das outras); o retorno indica se TUDO foi salvo com sucesso.
;
; O projeto so e salvo se: ja tem um arquivo .msxproject permanente (nesse
; caso SaveProject(#False) e barato/silencioso, ver seu proprio guard) OU e
; o projeto temporario mas com conteudo de verdade (sprites/alfabetos/sons/
; etc, mesmo criterio de OfferSaveProject() via
; ProjectDB::HasUnsavedContent()) - sem isso, "Salvar Tudo" num projeto
; temporario vazio forçaria sempre um dialogo "Salvar projeto como..." so
; pra salvar dois arquivos de texto soltos, o que seria surpreendente; e
; sem o dialogo de confirmacao do OfferSaveProject() porque aqui o usuario
; ja pediu explicitamente pra salvar tudo, perguntar de novo seria redundante.
Procedure.b SaveAllDocuments()
  Protected SavedActive = ActiveTabPosition
  Protected Position, AllOK.b = #True

  For Position = 0 To ListSize(Docs()) - 1
    SetActiveTab(Position)
    If Not SaveDocument(#False)
      AllOK = #False
    EndIf
  Next

  If SavedActive >= 0 And SavedActive < ListSize(Docs())
    SetActiveTab(SavedActive)
  EndIf

  If Not ProjectDB::IsTemp() Or ProjectDB::HasUnsavedContent()
    If Not SaveProject(#False)
      AllOK = #False
    EndIf
  EndIf

  ProcedureReturn AllOK
EndProcedure

; Versao/build/data sao constantes de compilacao injetadas pelo build.ps1
; (via /CONSTANT) - ver fallback no topo do arquivo para compilacao direto
; pela IDE do PureBasic.
Procedure ShowAboutDialog()
  Protected Text.s = #App_Title + " - IDE MSX BASIC + Z80" + Chr(10) + Chr(10) +
    "Versao: " + #App_Version + Chr(10) +
    "Build: " + #App_Build + Chr(10) +
    "Data: " + #App_BuildDate + Chr(10) + Chr(10) +
    "(C) " + Str(Year(Date())) + " Wilson Pilon"

  MessageRequester("Sobre", Text, #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
EndProcedure

Procedure CloseTab(Position)
  If Not SelectElement(Docs(), Position)
    ProcedureReturn
  EndIf

  If Docs()\Modified
    Protected Name.s = GetFilePart(Docs()\Path)
    If Name = "" : Name = "este documento" : EndIf
    If Not ConfirmDiscard("'" + Name + "' tem alteracoes nao salvas." + Chr(10) + "Fechar mesmo assim?")
      ProcedureReturn
    EndIf
  EndIf

  Protected WasActive = ActiveTabPosition

  FreeGadget(Docs()\SciGadget)
  DeleteElement(Docs())

  If ListSize(Docs()) = 0
    AddDocumentTab()
    ProcedureReturn
  EndIf

  ; Fechar uma aba que nao e a ativa nao deve trocar o documento visivel -
  ; mantem a mesma aba ativa de antes, so ajustando o indice se a fechada
  ; estava antes dela na lista (todo mundo depois desliza um indice pra tras).
  Protected NewActive
  If Position = WasActive
    NewActive = Position
  ElseIf Position < WasActive
    NewActive = WasActive - 1
  Else
    NewActive = WasActive
  EndIf

  If NewActive >= ListSize(Docs())
    NewActive = ListSize(Docs()) - 1
  EndIf
  SetActiveTab(NewActive)
EndProcedure

; Deteccao simples de ASCII classico (linhas ja numeradas, sem Dignified):
; a primeira linha com conteudo comeca com um digito. Usada tanto pelo menu
; de tokenizacao manual (SaveAsTokenizedNative) quanto pelos fluxos
; "Executar" (RunBasicFromActiveTab/RunNestorBasicFromActiveTab) para decidir
; se pulam o pre-processador Dignified e tokenizam a aba direto.
Procedure.b LooksLikeClassicAscii(SourceText.s)
  Protected FirstContentLine.s = ""
  Protected LineIdx
  For LineIdx = 0 To CountString(SourceText, Chr(10))
    FirstContentLine = Trim(StringField(ReplaceString(SourceText, Chr(13), ""), LineIdx + 1, Chr(10)))
    If FirstContentLine <> ""
      Break
    EndIf
  Next
  If FirstContentLine = ""
    ProcedureReturn #False
  EndIf
  ProcedureReturn Bool(Asc(FirstContentLine) >= 48 And Asc(FirstContentLine) <= 57)
EndProcedure

; Tokeniza o conteudo da aba atual (MSX-BASIC ASCII classico, com numeros de
; linha) usando o tokenizador nativo (MsxTokenizer.pbi) e salva o binario
; resultante como .bmx. Nao depende de Python nem do toolchain badig/.
Procedure SaveAsTokenizedNative()
  Protected Position = ActiveTabPosition
  If Position < 0 Or Not SelectElement(Docs(), Position)
    ProcedureReturn
  EndIf

  Protected SourceText.s = ReadSciText(Docs()\SciGadget)

  ; Este menu espera ASCII classico (linhas ja numeradas), nao Dignified -
  ; avisa em vez de deixar o erro criptico do tokenizador confundir o usuario.
  If Not LooksLikeClassicAscii(SourceText)
    MessageRequester("Arquivo nao parece ser ASCII classico",
                     "Este menu tokeniza MSX-BASIC classico (linhas ja numeradas)." + Chr(10) +
                     "Este arquivo parece ser codigo Dignified (nao comeca com numero)." + Chr(10) + Chr(10) +
                     "Use 'Dignified -> tokenizado nativo (.bmx)...' em vez disso.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  Protected HexOut.s = Tok_Tokenize(SourceText)

  If Tok_HasError
    MessageRequester("Erro ao tokenizar",
                     "Linha " + Str(Tok_ErrorLine) + ": " + Tok_ErrorMsg,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  Protected Suggestion.s = Docs()\Path
  If Suggestion = ""
    Suggestion = Docs()\UntitledName
  EndIf
  Suggestion = GetPathPart(Suggestion) + GetFilePart(Suggestion, #PB_FileSystem_NoExtension) + ".bmx"

  Protected SavePath.s = SaveFileRequester("Salvar como tokenizado", Suggestion,
                                           "MSX Basic tokenizado (*.bmx)|*.bmx|Todos os arquivos (*.*)|*.*", 0)
  If SavePath = ""
    ProcedureReturn
  EndIf

  If Not Tok_SaveHexAsBinary(HexOut, SavePath)
    MessageRequester("Erro", "Nao foi possivel salvar o arquivo:" + Chr(10) + SavePath,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  MessageRequester("Tokenizado gerado", "Salvo em:" + Chr(10) + SavePath,
                   #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
EndProcedure

; Renumera o ASCII classico da aba atual (Tok_RenumberAscii, MsxTokenizer.pbi)
; para a numeracao mais compacta (1,2,3...), corrigindo GOTO/GOSUB/THEN/ELSE/
; RESTORE/RESUME/RETURN/RUN pros novos numeros, e deixa salvar o resultado como
; .bas (ASCII "padrao" MSX-DOS), .amx (convencao interna deste projeto) ou,
; encadeando com o tokenizador nativo, direto como .bmx.
Procedure SaveAsRenumberedBas()
  Protected Position = ActiveTabPosition
  If Position < 0 Or Not SelectElement(Docs(), Position)
    ProcedureReturn
  EndIf

  Protected SourceText.s = ReadSciText(Docs()\SciGadget)

  If Not LooksLikeClassicAscii(SourceText)
    MessageRequester("Arquivo nao parece ser ASCII classico",
                     "Este menu renumera MSX-BASIC classico (linhas ja numeradas)." + Chr(10) +
                     "Este arquivo parece ser codigo Dignified (nao comeca com numero)." + Chr(10) + Chr(10) +
                     "Use 'Dignified -> ASCII nativo (.amx)...' em vez disso.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  Protected RenumberedAscii.s = Tok_RenumberAscii(SourceText)
  If Tok_HasError
    MessageRequester("Erro ao renumerar",
                     "Linha " + Str(Tok_ErrorLine) + ": " + Tok_ErrorMsg,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  Protected Suggestion.s = Docs()\Path
  If Suggestion = ""
    Suggestion = Docs()\UntitledName
  EndIf
  Suggestion = GetPathPart(Suggestion) + GetFilePart(Suggestion, #PB_FileSystem_NoExtension) + ".bas"

  Protected SavePath.s = SaveFileRequester("Salvar como MSX-BASIC renumerado", Suggestion,
                                           "MSX-BASIC padrao (*.bas)|*.bas|MSX Basic ASCII (*.amx)|*.amx|" +
                                           "MSX Basic tokenizado (*.bmx)|*.bmx|Todos os arquivos (*.*)|*.*", 0)
  If SavePath = ""
    ProcedureReturn
  EndIf

  If LCase(GetExtensionPart(SavePath)) = "bmx"
    Protected HexOut.s = Tok_Tokenize(RenumberedAscii)
    If Tok_HasError
      MessageRequester("Erro ao tokenizar",
                       "Linha " + Str(Tok_ErrorLine) + ": " + Tok_ErrorMsg,
                       #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
      ProcedureReturn
    EndIf
    If Not Tok_SaveHexAsBinary(HexOut, SavePath)
      MessageRequester("Erro", "Nao foi possivel salvar o arquivo:" + Chr(10) + SavePath,
                       #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
      ProcedureReturn
    EndIf
  Else
    Protected FileNum = CreateFile(#PB_Any, SavePath)
    If Not FileNum
      MessageRequester("Erro", "Nao foi possivel salvar o arquivo:" + Chr(10) + SavePath,
                       #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
      ProcedureReturn
    EndIf
    WriteString(FileNum, RenumberedAscii)
    CloseFile(FileNum)
  EndIf

  MessageRequester("Renumerado gerado", "Salvo em:" + Chr(10) + SavePath,
                   #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
EndProcedure

; Menu "Executar -> Renumerar...": equivalente nativo do comando RENUM do
; MSX-BASIC. Ao contrario de SaveAsRenumberedBas() (sempre renumera o
; programa inteiro pra numeracao mais compacta e exporta pra um arquivo
; novo), este renumera o programa DIGITADO na aba, no lugar (como o RENUM
; real faz na maquina), aceitando os mesmos 3 parametros do comando original:
; `RENUM [nova linha inicial][,[linha a partir da qual renumerar][,incremento]]`.
; Linhas antes da "linha a partir da qual renumerar" mantem seu numero
; original (Tok_RenumberAscii() ja trata isso via OldLineFrom). O motor
; (Tok_RenumberAscii/Tok_RenumberLineBody, MsxTokenizer.pbi) resolve GOTO/
; GOSUB/THEN/ELSE/RESTORE/RESUME/RETURN/RUN (incl. ON...GOTO/ON...GOSUB e
; IF...THEN GOTO) em duas passadas: a 1a mapeia numero-antigo -> numero-novo
; percorrendo o programa inteiro, a 2a reescreve cada linha resolvendo os
; alvos contra esse mapa - so assim um GOTO que aponta pra FRENTE no programa
; (referencia uma linha que so vai ser numerada depois, no arquivo) resolve
; corretamente.
Procedure RenumberActiveTabInPlace()
  Protected Position = ActiveTabPosition
  If Position < 0 Or Not SelectElement(Docs(), Position)
    ProcedureReturn
  EndIf

  Protected SourceText.s = ReadSciText(Docs()\SciGadget)

  If Not LooksLikeClassicAscii(SourceText)
    MessageRequester("Arquivo nao parece ser ASCII classico",
                     "Renumerar (RENUM) so funciona com MSX-BASIC classico (linhas ja numeradas)." + Chr(10) +
                     "Este arquivo parece ser codigo Dignified (nao comeca com numero).",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  Protected Answer.s = InputRequester("Renumerar (RENUM)", "Nova linha inicial:", "10", 0, WindowID(#MainWindow))
  If Answer = ""
    ProcedureReturn
  EndIf
  Protected NewStart.i = Val(Answer)
  If NewStart < 1
    MessageRequester("Renumerar (RENUM)", "A nova linha inicial deve ser 1 ou maior.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  Answer = InputRequester("Renumerar (RENUM)", "Incremento entre as linhas:", "10", 0, WindowID(#MainWindow))
  If Answer = ""
    ProcedureReturn
  EndIf
  Protected NewStep.i = Val(Answer)
  If NewStep < 1
    MessageRequester("Renumerar (RENUM)", "O incremento deve ser 1 ou maior.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  Answer = InputRequester("Renumerar (RENUM)",
                          "Renumerar a partir de qual linha (numero antigo)?" + Chr(10) +
                          "Deixe em branco para renumerar o programa inteiro.", "", 0, WindowID(#MainWindow))
  Protected OldLineFrom.i = Val(Answer) ; "" -> 0 -> Tok_RenumberAscii trata como "programa inteiro"
  If OldLineFrom < 0
    MessageRequester("Renumerar (RENUM)", "A linha inicial deve ser 0 ou maior.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  Protected RenumberedAscii.s = Tok_RenumberAscii(SourceText, NewStart, NewStep, OldLineFrom)
  If Tok_HasError
    MessageRequester("Erro ao renumerar",
                     "Linha " + Str(Tok_ErrorLine) + ": " + Tok_ErrorMsg,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  WriteSciText(Docs()\SciGadget, RenumberedAscii)
EndProcedure

; Copia as configuracoes da tela "Configurar -> Basic Dignified..." (BadigCfg,
; ver editor/BadigSettings.pbi) para os globals Dig_* lidos pelo pre-processador
; nativo (editor/DignifiedPreprocessor.pbi), unificando as duas telas de
; configuracao num so conjunto de opcoes (ver docs/SPEC.md modulo 3e).
Procedure Dig_SyncConfigFromBadigCfg()
  Dig_LineStart = BadigCfg\LineStart
  Dig_LineStep = BadigCfg\LineStep
  Dig_RemHeader = BadigCfg\RemHeader
  Dig_TabLength = BadigCfg\TabLenght
  Dig_StripSpaces = BadigCfg\StripSpaces
  Dig_CapitalizeAll = BadigCfg\CapitalizeAll
  Dig_Translate = BadigCfg\Translate
  Dig_ConvertPrintCfg = BadigCfg\ConvertPrint
  Dig_StripThenGotoCfg = BadigCfg\StripThenGoto
EndProcedure

; Roda o pre-processador Dignified nativo (DignifiedPreprocessor.pbi) sobre o
; conteudo da aba atual e devolve o texto ASCII classico resultante, ou ""
; em erro (mostrando o dialogo de erro). Usado pelas duas procedures abaixo.
Procedure.s RunDignifiedPreprocessor()
  ; "Configurar -> Projeto..." (ProjectSettingsGui.pbi): se o projeto atual
  ; tiver "usar configuracao especifica" ligado pro Basic Dignified, troca
  ; o BadigCfg global pelo do projeto so durante esta chamada (snapshot no
  ; comeco, restaura antes de qualquer retorno) - mesmo idioma de save/
  ; restore ja usado em Dig_ProcessSource pra Dig_CurrentPrefix/Dig_Defines().
  Protected UsingProjectOverride.b = #False
  Protected BadigCfgSnapshot.BadigSettings
  If ProjectDB::GetInfoValue("badig_override_enabled") = "1"
    Protected OverridePath.s = ProjectDB::OverrideSettingsPath("project_badig_settings.json")
    If OverridePath <> ""
      BadigCfgSnapshot = BadigCfg
      BadigCfg_Load(OverridePath)
      UsingProjectOverride = #True
    EndIf
  EndIf

  Dig_SyncConfigFromBadigCfg()
  Protected SourceText.s = ReadSciText(Docs()\SciGadget)
  Protected BasePath.s = ""
  If Docs()\Path <> ""
    BasePath = GetPathPart(Docs()\Path)
  EndIf
  ; Mesmo criterio ja usado pro destaque de sintaxe/autocompletar (:2135) -
  ; documentos MSXBAS2ROM ("Novo MSXBas2Rom...") protegem o vocabulario
  ; estendido (FILE/TEXT/CMD.../HEAP()/etc.) contra o encurtamento de
  ; variaveis, e diretivas FILE/TEXT saem sem numero de linha.
  Protected IsMsxBas2Rom.b = Bool(Docs()\Mode = "BAS")
  Protected AsciiOut.s = Dig_Preprocess(SourceText, BasePath, IsMsxBas2Rom)

  Protected HadError.b = Dig_HasError
  Protected ErrLine.i = Dig_ErrorLine
  Protected ErrMsg.s = Dig_ErrorMsg

  If UsingProjectOverride
    BadigCfg = BadigCfgSnapshot
  EndIf

  If HadError
    MessageRequester("Erro no pre-processador Dignified",
                     "Linha " + Str(ErrLine) + ": " + ErrMsg,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn ""
  EndIf

  ProcedureReturn AsciiOut
EndProcedure

; Converte o Dignified da aba atual para MSX-BASIC ASCII classico (nativo,
; sem Python) e salva como .amx.
Procedure SaveAsAsciiFromDignified()
  Protected Position = ActiveTabPosition
  If Position < 0 Or Not SelectElement(Docs(), Position)
    ProcedureReturn
  EndIf

  Protected AsciiOut.s = RunDignifiedPreprocessor()
  If AsciiOut = ""
    ProcedureReturn
  EndIf

  Protected Suggestion.s = Docs()\Path
  If Suggestion = ""
    Suggestion = Docs()\UntitledName
  EndIf
  Suggestion = GetPathPart(Suggestion) + GetFilePart(Suggestion, #PB_FileSystem_NoExtension) + ".amx"
  If Dig_ExportFileOverride <> ""
    ; remtag ##BB:export_file=... da linha fonte - so preenche a sugestao,
    ; usuario ainda confirma/troca no dialogo de salvar
    Suggestion = Dig_ExportFileOverride
  EndIf

  Protected SavePath.s = SaveFileRequester("Salvar como ASCII classico", Suggestion,
                                           "MSX Basic ASCII (*.amx)|*.amx|Todos os arquivos (*.*)|*.*", 0)
  If SavePath = ""
    ProcedureReturn
  EndIf

  Protected FileNum = CreateFile(#PB_Any, SavePath)
  If Not FileNum
    MessageRequester("Erro", "Nao foi possivel salvar o arquivo:" + Chr(10) + SavePath,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf
  WriteString(FileNum, AsciiOut)
  CloseFile(FileNum)

  MessageRequester("ASCII gerado", "Salvo em:" + Chr(10) + SavePath,
                   #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
EndProcedure

; Converte o Dignified da aba atual direto para tokenizado .bmx, encadeando
; o pre-processador nativo com o tokenizador nativo. Sem Python em nenhum passo.
Procedure SaveAsTokenizedFromDignified()
  Protected Position = ActiveTabPosition
  If Position < 0 Or Not SelectElement(Docs(), Position)
    ProcedureReturn
  EndIf

  Protected AsciiOut.s = RunDignifiedPreprocessor()
  If AsciiOut = ""
    ProcedureReturn
  EndIf

  Protected HexOut.s = Tok_Tokenize(AsciiOut)
  If Tok_HasError
    MessageRequester("Erro ao tokenizar",
                     "Linha " + Str(Tok_ErrorLine) + ": " + Tok_ErrorMsg,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  Protected Suggestion.s = Docs()\Path
  If Suggestion = ""
    Suggestion = Docs()\UntitledName
  EndIf
  Suggestion = GetPathPart(Suggestion) + GetFilePart(Suggestion, #PB_FileSystem_NoExtension) + ".bmx"
  If Dig_ExportFileOverride <> ""
    Suggestion = Dig_ExportFileOverride
  EndIf

  Protected SavePath.s = SaveFileRequester("Salvar como tokenizado", Suggestion,
                                           "MSX Basic tokenizado (*.bmx)|*.bmx|Todos os arquivos (*.*)|*.*", 0)
  If SavePath = ""
    ProcedureReturn
  EndIf

  If Not Tok_SaveHexAsBinary(HexOut, SavePath)
    MessageRequester("Erro", "Nao foi possivel salvar o arquivo:" + Chr(10) + SavePath,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  MessageRequester("Tokenizado gerado", "Salvo em:" + Chr(10) + SavePath,
                   #PB_MessageRequester_Ok | #PB_MessageRequester_Info)

  If BadigCfg\EmRun
    Protected DmxSource.s = ReadSciText(Docs()\SciGadget)
    Protected BaseName.s = GetFilePart(SavePath, #PB_FileSystem_NoExtension)
    RunOnOpenMSX(BaseName, DmxSource, AsciiOut, HexOut)
  EndIf
EndProcedure

; Menu "Executar -> BASIC" (F5): preprocessa (Dignified -> ASCII), tokeniza e
; manda direto para RunOnOpenMSX() - mesmo pipeline final de
; SaveAsTokenizedFromDignified() quando "Abrir o openMSX e rodar o codigo
; apos gerar" esta marcado, so que aqui e sempre (acao explicita de "rodar",
; sem depender do checkbox EmRun nem passar pelo dialogo de Salvar Como).
; Se a aba ja contem ASCII classico (linhas numeradas - ver
; LooksLikeClassicAscii), pula o pre-processador Dignified e tokeniza a aba
; direto, senao o pre-processador mangla os numeros de linha originais
; tratando-os como texto comum em vez de reconhecer o arquivo como ja pronto.
Procedure RunBasicFromActiveTab()
  Protected Position = ActiveTabPosition
  If Position < 0 Or Not SelectElement(Docs(), Position)
    ProcedureReturn
  EndIf

  If Docs()\Mode = "ASM"
    MessageRequester("Executar -> BASIC",
                     "A aba ativa e Assembly (.asm), nao MSX-BASIC/Dignified." + Chr(10) +
                     "Executar Assembly ainda nao e suportado.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
    ProcedureReturn
  EndIf

  Protected AsciiOut.s
  If LooksLikeClassicAscii(ReadSciText(Docs()\SciGadget))
    AsciiOut = ReadSciText(Docs()\SciGadget)
  Else
    AsciiOut = RunDignifiedPreprocessor()
    If AsciiOut = ""
      ProcedureReturn
    EndIf
  EndIf

  Protected HexOut.s = Tok_Tokenize(AsciiOut)
  If Tok_HasError
    MessageRequester("Erro ao tokenizar",
                     "Linha " + Str(Tok_ErrorLine) + ": " + Tok_ErrorMsg,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  Protected Suggestion.s = Docs()\Path
  If Suggestion = ""
    Suggestion = Docs()\UntitledName
  EndIf
  Protected BaseName.s = GetFilePart(Suggestion, #PB_FileSystem_NoExtension)

  Protected DmxSource.s = ReadSciText(Docs()\SciGadget)
  RunOnOpenMSX(BaseName, DmxSource, AsciiOut, HexOut)
EndProcedure

; Menu "Executar -> Nestor Basic": identico a RunBasicFromActiveTab(), so que
; manda IncludeNestorBasic=#True pra RunOnOpenMSX() copiar NBASIC.BIN/
; NBASIC.DAT (de res/) pro disco antes de montar o run.dsk e rodar. Mesma
; deteccao de ASCII classico (pula o pre-processador Dignified quando a aba
; ja tem linhas numeradas) - ver RunBasicFromActiveTab().
Procedure RunNestorBasicFromActiveTab()
  Protected Position = ActiveTabPosition
  If Position < 0 Or Not SelectElement(Docs(), Position)
    ProcedureReturn
  EndIf

  If Docs()\Mode = "ASM"
    MessageRequester("Executar -> Nestor Basic",
                     "A aba ativa e Assembly (.asm), nao MSX-BASIC/Dignified." + Chr(10) +
                     "Executar Assembly ainda nao e suportado.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
    ProcedureReturn
  EndIf

  Protected AsciiOut.s
  If LooksLikeClassicAscii(ReadSciText(Docs()\SciGadget))
    AsciiOut = ReadSciText(Docs()\SciGadget)
  Else
    AsciiOut = RunDignifiedPreprocessor()
    If AsciiOut = ""
      ProcedureReturn
    EndIf
  EndIf

  Protected HexOut.s = Tok_Tokenize(AsciiOut)
  If Tok_HasError
    MessageRequester("Erro ao tokenizar",
                     "Linha " + Str(Tok_ErrorLine) + ": " + Tok_ErrorMsg,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  Protected Suggestion.s = Docs()\Path
  If Suggestion = ""
    Suggestion = Docs()\UntitledName
  EndIf
  Protected BaseName.s = GetFilePart(Suggestion, #PB_FileSystem_NoExtension)

  Protected DmxSource.s = ReadSciText(Docs()\SciGadget)
  RunOnOpenMSX(BaseName, DmxSource, AsciiOut, HexOut, #True)
EndProcedure

; Menu "Executar -> Compilar ROM (MSXBas2Rom)...": gera o ASCII classico
; (mesma deteccao de ASCII-ja-pronto de RunBasicFromActiveTab; quando
; precisa do pre-processador, RunDignifiedPreprocessor() ja ativa o modo
; MSXBAS2ROM sozinho - ver Docs()\Mode = "BAS" ali), salva num .bas de
; verdade e roda o msxbas2rom.exe configurado (Configurar -> MSXBas2Rom...)
; pra gerar o .ROM. NUNCA tokeniza - diferente de RunBasicFromActiveTab/
; RunNestorBasicFromActiveTab, msxbas2rom.exe compila direto do texto
; classico, nao do formato tokenizado nativo desta IDE.
Procedure CompileMsxBas2RomFromActiveTab()
  Protected Position = ActiveTabPosition
  If Position < 0 Or Not SelectElement(Docs(), Position)
    ProcedureReturn
  EndIf

  If Docs()\Mode <> "BAS"
    MessageRequester("Compilar ROM (MSXBas2Rom)",
                     "A aba ativa nao e um documento MSXBAS2ROM (.bas)." + Chr(10) +
                     "Use Arquivo -> Novo MSXBas2Rom... para criar um.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
    ProcedureReturn
  EndIf

  ; "Configurar -> Projeto..." (ProjectSettingsGui.pbi): se o projeto atual
  ; tiver "usar configuracao especifica" ligado pro MSXBas2Rom, troca o
  ; MsxBas2RomCfg global (so o ExePath importa aqui) pelo do projeto so
  ; durante esta chamada - mesmo idioma de RunDignifiedPreprocessor() acima.
  Protected UsingProjectOverride.b = #False
  Protected MsxBas2RomCfgSnapshot.MsxBas2RomSettings
  If ProjectDB::GetInfoValue("msxbas2rom_override_enabled") = "1"
    Protected OverridePath.s = ProjectDB::OverrideSettingsPath("project_msxbas2rom_settings.json")
    If OverridePath <> ""
      MsxBas2RomCfgSnapshot = MsxBas2RomCfg
      MsxBas2RomCfg_Load(OverridePath)
      UsingProjectOverride = #True
    EndIf
  EndIf

  If MsxBas2RomCfg\ExePath = "" Or FileSize(MsxBas2RomCfg\ExePath) <= 0
    MessageRequester("Compilar ROM (MSXBas2Rom)",
                     "Configure o caminho do msxbas2rom.exe primeiro (Configurar -> MSXBas2Rom...).",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    If UsingProjectOverride : MsxBas2RomCfg = MsxBas2RomCfgSnapshot : EndIf
    ProcedureReturn
  EndIf

  Protected AsciiOut.s
  If LooksLikeClassicAscii(ReadSciText(Docs()\SciGadget))
    AsciiOut = ReadSciText(Docs()\SciGadget)
  Else
    AsciiOut = RunDignifiedPreprocessor()
    If AsciiOut = ""
      If UsingProjectOverride : MsxBas2RomCfg = MsxBas2RomCfgSnapshot : EndIf
      ProcedureReturn
    EndIf
  EndIf

  Protected Suggestion.s = Docs()\Path
  If Suggestion = ""
    Suggestion = Docs()\UntitledName
  EndIf
  Suggestion = GetPathPart(Suggestion) + GetFilePart(Suggestion, #PB_FileSystem_NoExtension) + ".bas"

  Protected BasPath.s = SaveFileRequester("Salvar .bas para compilar com o MSXBas2Rom", Suggestion,
                                          "MSX Basic classico (*.bas)|*.bas|Todos os arquivos (*.*)|*.*", 0)
  If BasPath = ""
    If UsingProjectOverride : MsxBas2RomCfg = MsxBas2RomCfgSnapshot : EndIf
    ProcedureReturn
  EndIf

  Protected FileNum = CreateFile(#PB_Any, BasPath)
  If Not FileNum
    MessageRequester("Erro", "Nao foi possivel salvar o arquivo:" + Chr(10) + BasPath,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    If UsingProjectOverride : MsxBas2RomCfg = MsxBas2RomCfgSnapshot : EndIf
    ProcedureReturn
  EndIf
  WriteString(FileNum, AsciiOut)
  CloseFile(FileNum)

  MsxBas2Rom_CompileToRom(BasPath)

  If UsingProjectOverride
    MsxBas2RomCfg = MsxBas2RomCfgSnapshot
  EndIf
EndProcedure

;- ------------------------------------------------------------
;- Montar Fonte asMSX (menu "Executar") - chama o executavel EXTERNO do
;- asMSX (AsmsxSupport.pbi) contra a aba .asm ativa, ao contrario de "Montar
;- Assembly (.bin)/(.REL)" abaixo, que usam o assembler NATIVO desta IDE
;- (Z80Asm.pbi). O asMSX so aceita um arquivo real em disco (nao stdin), por
;- isso salva a aba antes de montar - mesmo idioma de
;- CompileMsxBas2RomFromActiveTab() acima (sempre pergunta onde salvar, nunca
;- sobrescreve silenciosamente o arquivo ja aberto).
;- ------------------------------------------------------------

Procedure AssembleAsmsxFromActiveTab()
  Protected Position = ActiveTabPosition
  If Position < 0 Or Not SelectElement(Docs(), Position)
    ProcedureReturn
  EndIf

  If Docs()\Mode <> "ASM"
    MessageRequester("Montar Fonte asMSX",
                     "A aba ativa nao e Assembly (.asm)." + Chr(10) +
                     "Abra ou crie uma aba .asm (Arquivo -> Novo asMSX...) antes de montar.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
    ProcedureReturn
  EndIf

  ; "Configurar -> Projeto..." (ProjectSettingsGui.pbi): mesmo idioma de
  ; CompileMsxBas2RomFromActiveTab() acima - snapshot/troca/restore do
  ; Global AsmsxCfg so durante esta chamada, se o override estiver ligado.
  Protected UsingProjectOverride.b = #False
  Protected AsmsxCfgSnapshot.AsmsxSettings
  If ProjectDB::GetInfoValue("asmsx_override_enabled") = "1"
    Protected OverridePath.s = ProjectDB::OverrideSettingsPath("project_asmsx_settings.json")
    If OverridePath <> ""
      AsmsxCfgSnapshot = AsmsxCfg
      AsmsxCfg_Load(OverridePath)
      UsingProjectOverride = #True
    EndIf
  EndIf

  If AsmsxCfg\ExePath = "" Or FileSize(AsmsxCfg\ExePath) <= 0
    MessageRequester("Montar Fonte asMSX",
                     "Configure o caminho do executavel do asMSX primeiro (Configurar -> asMSX...).",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    If UsingProjectOverride : AsmsxCfg = AsmsxCfgSnapshot : EndIf
    ProcedureReturn
  EndIf

  Protected Suggestion.s = Docs()\Path
  If Suggestion = ""
    Suggestion = Docs()\UntitledName
  EndIf
  Suggestion = GetPathPart(Suggestion) + GetFilePart(Suggestion, #PB_FileSystem_NoExtension) + ".asm"

  Protected AsmPath.s = SaveFileRequester("Salvar .asm para montar com o asMSX", Suggestion,
                                          "Assembly asMSX (*.asm)|*.asm|Todos os arquivos (*.*)|*.*", 0)
  If AsmPath = ""
    If UsingProjectOverride : AsmsxCfg = AsmsxCfgSnapshot : EndIf
    ProcedureReturn
  EndIf

  Protected FileNum = CreateFile(#PB_Any, AsmPath)
  If Not FileNum
    MessageRequester("Erro", "Nao foi possivel salvar o arquivo:" + Chr(10) + AsmPath,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    If UsingProjectOverride : AsmsxCfg = AsmsxCfgSnapshot : EndIf
    ProcedureReturn
  EndIf
  WriteString(FileNum, ReadSciText(Docs()\SciGadget))
  CloseFile(FileNum)

  Asmsx_AssembleFile(AsmPath)

  If UsingProjectOverride
    AsmsxCfg = AsmsxCfgSnapshot
  EndIf
EndProcedure

;- ------------------------------------------------------------
;- Montar Assembly (.asm) -> binario (menu "Executar") - modo absoluto
;- (.bin, Ctrl+F5) e relocavel (.REL, insumo do linker/biblioteca - modulo
;- 2b, ver docs/resumo-asm.md). Saida do modo absoluto passa por
;- Z80Out_ChooseAndExport (Z80OutputGui.pbi) - .bin no PC, disco MSX (.dsk)
;- ou listing BASIC; o linker propriamente dito mora em Z80LinkGui.pbi.
;- ------------------------------------------------------------

Procedure AssembleZ80FromActiveTab()
  Protected Position = ActiveTabPosition
  If Position < 0 Or Not SelectElement(Docs(), Position)
    ProcedureReturn
  EndIf

  If Docs()\Mode <> "ASM"
    MessageRequester("Montar",
                     "A aba ativa nao e Assembly (.asm)." + Chr(10) +
                     "Abra ou crie uma aba .asm (Arquivo -> Novo Assembly) antes de montar.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
    ProcedureReturn
  EndIf

  Protected SourceText.s = ReadSciText(Docs()\SciGadget)
  Protected Dim AsmBytes.a(65535)
  Protected N = Z80Asm::Assemble(SourceText, AsmBytes())

  If N < 0
    MessageRequester("Erro ao montar",
                     "Linha " + Str(Z80Asm::GetAssembleErrorLine()) + ": " + Z80Asm::GetAssembleErrorText(),
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  If N = 0
    MessageRequester("Montar",
                     "Nada foi gerado (fonte vazio ou so rotulos/EQU/diretivas sem saida de bytes).",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
    ProcedureReturn
  EndIf

  Protected StartAddr.u = Z80Asm::GetAssembleStartAddr()
  Protected EndAddr.u = Z80Asm::GetAssembleEndAddr()

  Protected Suggestion.s = Docs()\Path
  If Suggestion = ""
    Suggestion = Docs()\UntitledName
  EndIf
  Protected BaseName.s = GetPathPart(Suggestion) + GetFilePart(Suggestion, #PB_FileSystem_NoExtension)

  ; SourceKey pra ProjectDB::StoreAsmBuild() e o caminho do .asm em disco -
  ; uma aba ainda sem salvar (Docs()\Path = "") nao tem chave estavel, entao
  ; fica de fora do registro do projeto (mesmo espirito de "documents": so
  ; faz sentido registrar algo com um caminho de verdade em disco).
  Protected SourceKey.s = Docs()\Path

  Z80Out_ChooseAndExport(BaseName, AsmBytes(), N, StartAddr, EndAddr, SourceKey, "ABS", #MainWindow)
EndProcedure

; Monta a aba ASM ativa em modo RELOCAVEL (.REL, formato estendido Nestor80 -
; ver Z80Asm::AssembleRelocatable/modulo 2b) em vez de absoluto - o .REL
; resultante e o insumo do linker (Executar -> Linkar (.REL) -> binario...,
; Z80LinkGui.pbi) ou de uma biblioteca .LIB (Criar -> Biblioteca Z80...,
; Z80LibGui.pbi). Diferente de AssembleZ80FromActiveTab, nao passa por
; Z80Out_ChooseAndExport nem grava em ProjectDB: um .REL nao roda sozinho no
; MSX (e um artefato intermediario), entao nao faz sentido pra "ultimo .bin
; gerado" nem pra BLOAD/disco/listing - so precisa virar arquivo pro linker
; ler depois.
Procedure AssembleZ80RelFromActiveTab()
  Protected Position = ActiveTabPosition
  If Position < 0 Or Not SelectElement(Docs(), Position)
    ProcedureReturn
  EndIf

  If Docs()\Mode <> "ASM"
    MessageRequester("Montar relocavel",
                     "A aba ativa nao e Assembly (.asm)." + Chr(10) +
                     "Abra ou crie uma aba .asm (Arquivo -> Novo Assembly) antes de montar.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
    ProcedureReturn
  EndIf

  Protected SourceText.s = ReadSciText(Docs()\SciGadget)

  Protected Suggestion.s = Docs()\Path
  If Suggestion = ""
    Suggestion = Docs()\UntitledName
  EndIf
  ; Nome de programa no formato .REL (M80/Nestor80 tradicionalmente usa ate
  ; 6 caracteres, mas Z80Asm::AssembleRelocatable nao trunca - so o nome do
  ; arquivo, maiusculo, sem extensao, pra ficar previsivel pra quem for
  ; escolher esse .REL depois num link/biblioteca).
  Protected ProgramName.s = UCase(GetFilePart(Suggestion, #PB_FileSystem_NoExtension))

  Protected Dim RelBytes.a(65535)
  Protected N = Z80Asm::AssembleRelocatable(SourceText, ProgramName, RelBytes())

  If N < 0
    MessageRequester("Erro ao montar",
                     "Linha " + Str(Z80Asm::GetAssembleErrorLine()) + ": " + Z80Asm::GetAssembleErrorText(),
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  If N = 0
    MessageRequester("Montar relocavel",
                     "Nada foi gerado (fonte vazio ou so rotulos/EQU/diretivas sem saida de bytes).",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
    ProcedureReturn
  EndIf

  Protected BaseSuggestion.s = GetPathPart(Suggestion) + GetFilePart(Suggestion, #PB_FileSystem_NoExtension) + ".rel"
  Protected SavePath.s = SaveFileRequester("Salvar objeto relocavel", BaseSuggestion,
                                           "Objeto Z80 relocavel (*.rel)|*.rel|Todos os arquivos (*.*)|*.*", 0)
  If SavePath = ""
    ProcedureReturn
  EndIf
  SavePath = EnsureExtension(SavePath, "rel")

  Protected FileNum = CreateFile(#PB_Any, SavePath)
  If Not FileNum
    MessageRequester("Erro", "Nao foi possivel salvar o arquivo:" + Chr(10) + SavePath,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf
  Protected *Buf = AllocateMemory(N)
  Protected Idx
  For Idx = 0 To N - 1
    PokeB(*Buf + Idx, RelBytes(Idx))
  Next
  WriteData(FileNum, *Buf, N)
  CloseFile(FileNum)
  FreeMemory(*Buf)

  MessageRequester("Montado", Str(N) + " bytes (" + ProgramName + ") salvos em:" + Chr(10) + SavePath,
                   #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
EndProcedure

;- ------------------------------------------------------------
;- Rodar no openMSX: monta um disquete .dsk com o .dmx/.amx/.bmx
;- gerados e abre o openMSX ja com esse disco montado (menu "Dignified
;- -> tokenizado nativo...", quando "Abrir o openMSX e rodar o codigo
;- apos gerar" esta marcado nas configuracoes). Rotinas de disco
;- vendorizadas de msxDiskUtil (MSXDisk.pbi, modulo MSXDisk) - nada de
;- subprocess externo para montar o .dsk, so para abrir o proprio
;- openMSX (unico subprocess desta funcao, e nao tem como no PC rodar
;- o programa MSX de outro jeito).
;- ------------------------------------------------------------

; Diretorio "disk" ao lado do executavel (dist\, mesma convencao do default de
; InstallDir, "badig" - ver BadigCfg_DefaultInstallDir()) - area de
; trabalho onde o disquete de execucao e montado a cada "rodar no openMSX".
Procedure.s RunOnOpenMSX_DiskDir()
  Protected Dir.s = GetPathPart(ProgramFilename()) + "disk\"
  If FileSize(Dir) <> -2
    CreateDirectory(Dir)
  EndIf
  ProcedureReturn Dir
EndProcedure

; Apaga o conteudo de DiskDir antes de montar um disco novo - sem isso, cada
; "Executar" com um BaseName diferente (outro projeto/arquivo) so acumulava
; .dmx/.amx/.bmx/autoexec.bas de execucoes anteriores na mesma pasta (o
; MSXDisk::CreateDisk() sobrescreve o run.dsk, mas os arquivos LOCAIS soltos
; ao lado ficavam para tras). So arquivos (nao entra em subpastas).
Procedure ClearDiskDir(Dir.s)
  Protected d = ExamineDirectory(#PB_Any, Dir, "*.*")
  If Not d : ProcedureReturn : EndIf
  While NextDirectoryEntry(d)
    If DirectoryEntryType(d) = #PB_DirectoryEntry_File
      DeleteFile(Dir + DirectoryEntryName(d))
    EndIf
  Wend
  FinishDirectory(d)
EndProcedure

Procedure RunOnOpenMSX(BaseName.s, DmxText.s, AsciiText.s, HexOut.s, IncludeNestorBasic.b = #False)
  If BadigCfg\EmulatorPath = ""
    MessageRequester("openMSX nao configurado",
                     "Configure o caminho do executavel do openMSX em" + Chr(10) +
                     "Configurar -> Basic Dignified... -> aba Emulador.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  Protected DiskDir.s = RunOnOpenMSX_DiskDir()
  If FileSize(DiskDir) <> -2
    MessageRequester("Erro", "Nao foi possivel criar o diretorio:" + Chr(10) + DiskDir,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  ClearDiskDir(DiskDir)

  Protected UBase.s = UCase(BaseName)

  Protected DmxLocal.s = DiskDir + BaseName + ".dmx"
  Protected AmxLocal.s = DiskDir + BaseName + ".amx"
  Protected BmxLocal.s = DiskDir + BaseName + ".bmx"
  Protected AutoexecLocal.s = DiskDir + "autoexec.bas"

  Protected f
  f = CreateFile(#PB_Any, DmxLocal)
  If f : WriteString(f, DmxText) : CloseFile(f) : EndIf
  f = CreateFile(#PB_Any, AmxLocal)
  If f : WriteString(f, AsciiText) : CloseFile(f) : EndIf
  If Not Tok_SaveHexAsBinary(HexOut, BmxLocal)
    MessageRequester("Erro", "Nao foi possivel gravar:" + Chr(10) + BmxLocal,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  ; AUTOEXEC.BAS - convencao do MSX-BASIC/MSX-DOS: se esse arquivo existir no
  ; disco de boot, e carregado e rodado automaticamente ao ligar/reiniciar -
  ; aqui so encaminha para o .BMX que acabou de ser gerado.
  f = CreateFile(#PB_Any, AutoexecLocal)
  If f : WriteString(f, "10 RUN " + Chr(34) + UBase + ".BMX" + Chr(34) + Chr(13) + Chr(10)) : CloseFile(f) : EndIf

  ; "Executar -> Nestor Basic": copia NBASIC.BIN/NBASIC.DAT (de res/, ao
  ; lado de editor/) pro mesmo diretorio de disco antes de montar o run.dsk -
  ; sem eles no disco, o BLOAD"NBASIC.BIN",R gerado por
  ; NestorBasicSupport.pbi nao acha o arquivo dentro do openMSX.
  Protected NBasicBinLocal.s = DiskDir + "NBASIC.BIN"
  Protected NBasicDatLocal.s = DiskDir + "NBASIC.DAT"
  If IncludeNestorBasic
    Protected ResDir.s = GetPathPart(ProgramFilename()) + "res\"
    If Not CopyFile(ResDir + "NBASIC.BIN", NBasicBinLocal) Or Not CopyFile(ResDir + "NBASIC.DAT", NBasicDatLocal)
      MessageRequester("Erro", "Nao foi possivel copiar NBASIC.BIN/NBASIC.DAT de:" + Chr(10) + ResDir,
                       #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
      ProcedureReturn
    EndIf
  EndIf

  ; MSX-DOS/FAT12 e 8.3 - nomes de arquivo maiores que 8 caracteres sao
  ; truncados automaticamente por MSXDisk::ConvertToFAT11() ao adicionar.
  Protected DiskPath.s = DiskDir + "run.dsk"
  If Not MSXDisk::CreateDisk(DiskPath)
    MessageRequester("Erro ao criar o disco", MSXDisk::GetLastErrorMessage(),
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  Protected Ok.b = #True
  If Ok : Ok = MSXDisk::AddFile(DmxLocal, UBase + ".DMX") : EndIf
  If Ok : Ok = MSXDisk::AddFile(AmxLocal, UBase + ".AMX") : EndIf
  If Ok : Ok = MSXDisk::AddFile(BmxLocal, UBase + ".BMX") : EndIf
  If Ok : Ok = MSXDisk::AddFile(AutoexecLocal, "AUTOEXEC.BAS") : EndIf
  If Ok And IncludeNestorBasic
    Ok = MSXDisk::AddFile(NBasicBinLocal, "NBASIC.BIN")
    If Ok : Ok = MSXDisk::AddFile(NBasicDatLocal, "NBASIC.DAT") : EndIf
  EndIf
  Protected DiskErr.s = MSXDisk::GetLastErrorMessage()
  MSXDisk::CloseDisk()

  If Not Ok
    MessageRequester("Erro ao montar o disco", DiskErr,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  ; Reaproveita a instancia atual do openMSX em vez de abrir uma nova a cada
  ; run: OMSX_LoadDisk() (OpenMSXBridge.pbi) sobe o emulador se precisar
  ; (com -machine/-ext atuais, ver OMSX_BuildParams()) ou, se ja estiver
  ; rodando, so troca o disco da unidade A e reinicia - equivalente a trocar
  ; o disquete de um MSX de verdade sem fechar a janela do emulador.
  If Not OMSX_LoadDisk(DiskPath)
    MessageRequester("Erro", "Nao foi possivel executar o openMSX:" + Chr(10) + BadigCfg\EmulatorPath,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
  EndIf
EndProcedure

;- ------------------------------------------------------------
;- Layout / redimensionamento
;- ------------------------------------------------------------

Procedure ResizeInterface()
  Protected FullW = WindowWidth(#MainWindow)
  Protected FullH = WindowHeight(#MainWindow) - StatusBarHeight(#MainStatusBar)
  If FullH < 0 : FullH = 0 : EndIf

  ResizeGadget(#TabBarGadget, 0, 0, FullW, #TabBar_Height)
  ResizeGadget(#RulerGadget, 0, #TabBar_Height, FullW, #Ruler_Height)

  Protected InnerH = FullH - #TabBar_Height - #Ruler_Height
  If InnerH < 0 : InnerH = 0 : EndIf

  ForEach Docs()
    ResizeGadget(Docs()\SciGadget, 0, #TabBar_Height + #Ruler_Height, FullW, InnerH)
  Next

  RedrawTabBar()
  RedrawRuler()
EndProcedure

;- ------------------------------------------------------------
;- Programa principal
;- ------------------------------------------------------------

; "PaleoBasic.exe --diskmanipulator ..." roda so a CLI de disco (ver
; RunDiskManipulatorCli()) e sai, sem abrir nenhuma janela.
If ProgramParameter(0) = "--diskmanipulator"
  End RunDiskManipulatorCli()
EndIf

; O executavel e compilado com /CONSOLE (ver build.ps1) para a CLI acima
; funcionar de verdade (herdar o console do terminal que chamou, em vez de
; abrir uma janela de console nova e desconectada) - isso faz o Windows
; anexar um console automaticamente a QUALQUER execucao, inclusive o uso
; normal como editor grafico. FreeConsole_() fecha essa janela de console
; indesejada antes de abrir a GUI. WinAPI puro (achado real compilando no
; Linux via WSL, 2026-07-29, ver CLAUDE.md) - no Linux um binario -cl
; (--console, ver build.sh) roda direto no terminal que o chamou sem abrir
; nenhuma janela extra, entao nao ha nada equivalente a desanexar aqui.
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  FreeConsole_()
CompilerEndIf

; PNG so decodifica com o codec registrado em runtime - sem isso, LoadImage()
; de um .png sempre falha (retorna 0) mesmo com o arquivo certo no caminho certo.
UsePNGImageDecoder()
App_ShowSplash()

InitKeywordMaps()
Z80Asm::InitKeywordMaps()
EditorCfg_Load()
EditorCfg_LoadCustomFonts()
ApplyTheme()
BadigCfg_Load()
BasicOptionsCfg_Load()
AssemblyOptionsCfg_Load()

; Sem nenhum parametro de linha de comando (uso normal, clicando no .exe),
; ja abre o projeto implicito "noname.msxproject" de cara, pra qualquer
; recurso (por enquanto so Sprites) poder ir sendo gravado nele sem precisar
; que o usuario crie um projeto primeiro. Se um .msxproject foi passado como
; parametro (2 clique no arquivo com a associacao de "Configurar ->
; Associacoes de arquivo..." ligada, ver FileAssociationGui.pbi), abre esse
; projeto direto em vez do implicito - ProjectDB::OpenExisting/
; RestoreMissingDocumentsToDisk() nao dependem de nenhuma janela ainda
; aberta, entao rodar aqui (antes do OpenWindow do #MainWindow, igual o
; caminho do projeto implicito ja fazia) e seguro. "--diskmanipulator" ja
; terminou o processo antes daqui.
Define StartupProjectPath.s = ""
If CountProgramParameters() > 0
  Define FirstParam.s = ProgramParameter(0)
  If LCase(GetExtensionPart(FirstParam)) = "msxproject" And FileSize(FirstParam) >= 0
    StartupProjectPath = FirstParam
  EndIf
EndIf

If StartupProjectPath <> ""
  If ProjectDB::OpenExisting(StartupProjectPath)
    RestoreMissingDocumentsToDisk()
  Else
    MessageRequester("Erro ao abrir projeto",
                      "Nao foi possivel abrir:" + Chr(10) + StartupProjectPath + Chr(10) + ProjectDB::GetLastError(),
                      #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProjectDB::EnsureOpen()
  EndIf
  App_EnsureDefaultAlphabet()
ElseIf CountProgramParameters() = 0
  ProjectDB::EnsureOpen()
  App_EnsureDefaultAlphabet()
EndIf

App_CloseSplash()

If Not OpenWindow(#MainWindow, 0, 0, 1000, 700, #App_Title, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget)
  End
EndIf
SetWindowColor(#MainWindow, Color_AppBg)
App_ApplyWindowIcon(#MainWindow)

CreateMenu(#MainMenu, WindowID(#MainWindow))
  MenuTitle("Arquivo")
    MenuItem(#Menu_New,      "Novo" + Chr(9) + "Ctrl+N")
    MenuItem(#Menu_NewAssembly, "Novo Assembly" + Chr(9) + "Ctrl+Shift+N")
    MenuItem(#Menu_NewAsmsx, "Novo asMSX...")
    MenuItem(#Menu_NewNestorBasic, "Novo Nestor Basic...")
    MenuItem(#Menu_NewMsxBas2Rom, "Novo MSXBas2Rom...")
    MenuItem(#Menu_NewMD, "Novo MD...")
    MenuItem(#Menu_Open,     "Abrir..." + Chr(9) + "Ctrl+O")
    MenuBar()
    MenuItem(#Menu_Save,     "Salvar" + Chr(9) + "Ctrl+S")
    MenuItem(#Menu_SaveAs,   "Salvar como..." + Chr(9) + "Ctrl+Shift+S")
    MenuItem(#Menu_SaveAll,  "Salvar Tudo" + Chr(9) + "Ctrl+Alt+S")
    MenuBar()
    MenuItem(#Menu_DignifiedToAscii, "Dignified -> ASCII nativo (.amx)...")
    MenuItem(#Menu_DignifiedToTokenized, "Dignified -> tokenizado nativo (.bmx)...")
    MenuBar()
    MenuItem(#Menu_TokenizeNative, "ASCII classico ja aberto -> tokenizado nativo (.bmx)...")
    MenuItem(#Menu_RenumberToBas, "ASCII classico ja aberto -> renumerar e criar .BAS...")
    MenuBar()
    MenuItem(#Menu_CloseTab, "Fechar aba" + Chr(9) + "Ctrl+W")
    MenuBar()
    MenuItem(#Menu_Exit,     "Sair" + Chr(9) + "Alt+F4")
  MenuTitle("Projeto")
    MenuItem(#Menu_NewProject, "Novo projeto..." + Chr(9) + "Ctrl+Alt+N")
    MenuItem(#Menu_OpenProject, "Abrir projeto..." + Chr(9) + "Ctrl+Alt+O")
    MenuItem(#Menu_SaveProject, "Salvar projeto")
    MenuItem(#Menu_SaveProjectAs, "Salvar projeto como...")
    MenuBar()
    MenuItem(#Menu_ProjectIndex, "Indice de recursos..." + Chr(9) + "Ctrl+Alt+R")
    MenuItem(#Menu_ConfigureProject, "Configuracoes do projeto...")
  MenuTitle("Editar")
    MenuItem(#Menu_Find,     "Buscar..." + Chr(9) + "Ctrl+F")
    MenuItem(#Menu_FindNext, "Buscar proxima" + Chr(9) + "F3")
    MenuItem(#Menu_Replace,  "Substituir..." + Chr(9) + "Ctrl+H")
    MenuBar()
    MenuItem(#Menu_GotoLine, "Ir para linha..." + Chr(9) + "Ctrl+G")
  MenuTitle("Criar")
    MenuItem(#Menu_CreateDisk, "Disco..." + Chr(9) + "Ctrl+Shift+D")
    MenuItem(#Menu_CreateSprite, "Sprite..." + Chr(9) + "Ctrl+Shift+P")
    MenuItem(#Menu_CreateAlphabet, "Alfabeto Graphos III..." + Chr(9) + "Ctrl+Shift+A")
    MenuItem(#Menu_CreateAlphabetAquarela, "Alfabeto Aquarela...")
    MenuItem(#Menu_CreateSound, "Som (PSG)..." + Chr(9) + "Ctrl+Shift+G")
    MenuItem(#Menu_CreateSeeTracker, "SEE Tracker..." + Chr(9) + "Ctrl+Shift+T")
    MenuItem(#Menu_CreateMml, "Musica (PLAY)..." + Chr(9) + "Ctrl+Shift+M")
    MenuItem(#Menu_CreateScreen2, "Draw Screen 2..." + Chr(9) + "Ctrl+Shift+2")
    MenuItem(#Menu_CreateGraphosScreen, "Graphos III Screen 2...")
    MenuItem(#Menu_CreateScreen0, "Screen 0..." + Chr(9) + "Ctrl+Shift+0")
    MenuItem(#Menu_CreateScreen1, "Screen 1..." + Chr(9) + "Ctrl+Shift+1")
    MenuItem(#Menu_CreateScreen12, "Screen 1+2...")
    MenuItem(#Menu_CreateZ80Lib, "Biblioteca Z80 (.LIB)...")
    MenuItem(#Menu_CreateAsmSubProject, "Assembly Sub Project...")
  MenuTitle("Inserir")
    MenuItem(#Menu_InsertSpecialChar, "Caractere Especial..." + Chr(9) + "Ctrl+Alt+I")
  MenuTitle("Executar")
    MenuItem(#Menu_RunBasic, "BASIC" + Chr(9) + "F5")
    MenuItem(#Menu_RunNestorBasic, "Nestor Basic" + Chr(9) + "Shift+F5")
    MenuBar()
    MenuItem(#Menu_CompileMsxBas2RomRom, "Compilar ROM (MSXBas2Rom)...")
    MenuBar()
    MenuItem(#Menu_RenumberBasic, "Renumerar..." + Chr(9) + "F6")
    MenuBar()
    MenuItem(#Menu_AssembleZ80, "Montar Assembly (.bin)..." + Chr(9) + "Ctrl+F5")
    MenuItem(#Menu_AssembleZ80Rel, "Montar Assembly relocavel (.REL)..." + Chr(9) + "Ctrl+Shift+F5")
    MenuItem(#Menu_LinkZ80, "Linkar (.REL) -> binario..." + Chr(9) + "Ctrl+Alt+F5")
    MenuBar()
    MenuItem(#Menu_AssembleAsmsx, "Montar Fonte asMSX...")
    MenuBar()
    MenuItem(#Menu_HexEditor, "Editor Hexa..." + Chr(9) + "F7")
    MenuBar()
    MenuItem(#Menu_MamuteAssembler, "Mamute Assembler...")
    MenuBar()
    MenuItem(#Menu_OpenMSXConsole, "openMSX (console de comandos)..." + Chr(9) + "F8")
    MenuBar()
    MenuItem(#Menu_ViewMdTxt, "Ver MD/TXT..." + Chr(9) + "F9")
    MenuItem(#Menu_ViewMdTxtSplit, "Ver MD+TXT..." + Chr(9) + "Shift+F9")
  MenuTitle("Configurar")
    MenuItem(#Menu_ConfigureBadig, "Basic Dignified...")
    MenuItem(#Menu_ConfigureEditor, "Editor..." + Chr(9) + "Ctrl+Alt+E")
    MenuItem(#Menu_ConfigureBasicOptions, "Basic Options...")
    MenuItem(#Menu_ConfigureAssemblyOptions, "Assembly...")
    MenuItem(#Menu_ConfigureMsxBas2Rom, "MSXBas2Rom...")
    MenuItem(#Menu_ConfigureN80, "N80...")
    MenuItem(#Menu_ConfigureAsmsx, "asMSX...")
    MenuItem(#Menu_ConfigureMamuteAssembler, "Mamute Assembler...")
    MenuItem(#Menu_ConfigureOpenMSX, "openMSX...")
    MenuBar()
    MenuItem(#Menu_ConfigureFileAssociations, "Associacoes de arquivo...")
  MenuTitle("Ajuda")
    MenuItem(#Menu_HelpEditor, "Editor..." + Chr(9) + "F1")
    MenuItem(#Menu_HelpNestorBasic, "Nestor Basic...")
    MenuItem(#Menu_HelpMsxBasic, "MSX BASIC...")
    MenuItem(#Menu_HelpManuals, "Manuais MSX...")
    MenuItem(#Menu_HelpSoftware, "MSX-Basic/DOS/CP-M (RuMSX)...")
    MenuItem(#Menu_HelpBiosCalls, "BIOS MSX: Chamadas (RuMSX)...")
    MenuItem(#Menu_HelpHardware, "BIOS MSX: Hardware (RuMSX)...")
    MenuItem(#Menu_HelpBiosDoc, "BIOS MSX: Documentacao (RuMSX)...")
    MenuItem(#Menu_HelpRedBook, "Livro Vermelho...")
    MenuItem(#Menu_HelpTh2Handbook, "MSX2 Technical Handbook...")
    MenuItem(#Menu_HelpBasicDignified, "Basic Dignified...")
    MenuItem(#Menu_HelpSeeTracker, "SEE Tracker...")
    MenuItem(#Menu_HelpMamuteAssembler, "Mamute Assembler...")
    MenuItem(#Menu_HelpOpenMSX, "openMSX...")
    MenuItem(#Menu_HelpMsxBas2Rom, "MSXBas2Rom...")
    MenuItem(#Menu_HelpN80, "N80...")
    MenuItem(#Menu_HelpAsmsx, "asMSX...")
    MenuItem(#Menu_HelpAbout, "Sobre...")

AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_N, #Menu_New)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_N, #Menu_NewAssembly)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_O, #Menu_Open)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_S, #Menu_Save)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_S, #Menu_SaveAs)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_Alt | #PB_Shortcut_S, #Menu_SaveAll)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_W, #Menu_CloseTab)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_F5, #Menu_RunBasic)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_F5, #Menu_AssembleZ80)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_F, #Menu_Find)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_F3, #Menu_FindNext)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_H, #Menu_Replace)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_G, #Menu_GotoLine)

; Projeto (Ctrl+Alt+<letra igual ao equivalente de arquivo>) e Inserir/Configurar
; (Ctrl+Alt+<mnemonico>) - prefixo reservado pra acoes "de segundo nivel" que nao
; cabiam nos atalhos de arquivo/edicao ja ocupados.
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_Alt | #PB_Shortcut_N, #Menu_NewProject)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_Alt | #PB_Shortcut_O, #Menu_OpenProject)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_Alt | #PB_Shortcut_R, #Menu_ProjectIndex)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_Alt | #PB_Shortcut_I, #Menu_InsertSpecialChar)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_Alt | #PB_Shortcut_E, #Menu_ConfigureEditor)

; Executar - F5 already Executar BASIC/Montar Assembly; resto do grupo F5 (variantes
; de rodar/montar/linkar) e F6-F9 (ferramentas de um clique so).
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Shift | #PB_Shortcut_F5, #Menu_RunNestorBasic)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_F5, #Menu_AssembleZ80Rel)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_Alt | #PB_Shortcut_F5, #Menu_LinkZ80)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_F6, #Menu_RenumberBasic)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_F7, #Menu_HexEditor)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_F8, #Menu_OpenMSXConsole)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_F9, #Menu_ViewMdTxt)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Shift | #PB_Shortcut_F9, #Menu_ViewMdTxtSplit)

; Criar (editores visuais) - Ctrl+Shift+<mnemonico ou numero da tela MSX>. So os
; itens citados pelo usuario/mais usados ganharam tecla; Alfabeto Aquarela, Graphos
; III Screen 2, Screen 1+2, Biblioteca Z80 e Assembly Sub Project ficam so no menu
; (variantes menos usadas dos editores acima - nao valia a pena um 3o/4o modificador
; so pra caber mais uma tecla).
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_D, #Menu_CreateDisk)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_P, #Menu_CreateSprite)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_A, #Menu_CreateAlphabet)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_G, #Menu_CreateSound)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_T, #Menu_CreateSeeTracker)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_M, #Menu_CreateMml)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_2, #Menu_CreateScreen2)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_0, #Menu_CreateScreen0)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_1, #Menu_CreateScreen1)

; Ajuda -> Editor... tambem no classico F1 (alem do menu) - convencao universal de "ajuda".
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_F1, #Menu_HelpEditor)

CanvasGadget(#TabBarGadget, 0, 0, WindowWidth(#MainWindow), #TabBar_Height)
CanvasGadget(#RulerGadget, 0, #TabBar_Height, WindowWidth(#MainWindow), #Ruler_Height)

CreateStatusBar(#MainStatusBar, WindowID(#MainWindow))
  AddStatusBarField(70)          ; modo (INS/SBR)
  AddStatusBarField(#PB_Ignore)  ; nome do arquivo
  AddStatusBarField(160)         ; linha/coluna

AddDocumentTab()
ResizeInterface()

Define Event, Quit, Position, AllSaved, Discard, ChangedGadget, DocPos, AcPos, AcStart
Define TabDebug_Hit.b
Define MouseX, MouseY, HitPos, NewHoverTab, NewHoverClose

Repeat
  Event = WaitWindowEvent()

  Select Event

    Case #PB_Event_Menu
      Select EventMenu()
        Case #Menu_New
          TabDebugLog("Menu #Menu_New selecionado")
          AddDocumentTab()

        Case #Menu_NewAssembly
          AddDocumentTab("", "", "ASM")

        Case #Menu_NewAsmsx
          AddDocumentTab("", AsmsxTemplateText(), "ASM", "asmsx")

        Case #Menu_NewNestorBasic
          AddDocumentTab("", NestorBasicTemplateText(), "DMX", "nbasic")

        Case #Menu_NewMsxBas2Rom
          AddDocumentTab("", MsxBas2RomTemplateText(), "BAS", "msxbas2rom")

        Case #Menu_NewMD
          AddDocumentTab("", "", "MD")

        Case #Menu_NewProject
          If OfferSaveProject()
            Define NewProjectPath.s = SaveFileRequester("Novo projeto MSX", "", #File_Pattern_Project, 0)
            If NewProjectPath <> ""
              NewProjectPath = EnsureExtension(NewProjectPath, "msxproject")
              If Not ProjectDB::CreateNew(NewProjectPath)
                MessageRequester("Erro ao criar projeto",
                                  "Nao foi possivel criar:" + Chr(10) + NewProjectPath + Chr(10) + ProjectDB::GetLastError(),
                                  #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
              EndIf
            EndIf
          EndIf

        Case #Menu_OpenProject
          If OfferSaveProject()
            Define OpenProjectPath.s = OpenFileRequester("Abrir projeto MSX", "", #File_Pattern_Project, 0)
            If OpenProjectPath <> ""
              If Not ProjectDB::OpenExisting(OpenProjectPath)
                MessageRequester("Erro ao abrir projeto",
                                  "Nao foi possivel abrir:" + Chr(10) + OpenProjectPath + Chr(10) + ProjectDB::GetLastError(),
                                  #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
              Else
                RestoreMissingDocumentsToDisk()
              EndIf
            EndIf
          EndIf

        Case #Menu_SaveProject
          SaveProject(#False)

        Case #Menu_SaveProjectAs
          SaveProject(#True)

        Case #Menu_ProjectIndex
          ProjIndex_OpenWindow(#MainWindow)

        Case #Menu_Open
          OpenDocumentDialog()

        Case #Menu_Save
          SaveDocument(#False)

        Case #Menu_SaveAs
          SaveDocument(#True)

        Case #Menu_SaveAll
          SaveAllDocuments()

        Case #Menu_TokenizeNative
          SaveAsTokenizedNative()

        Case #Menu_RenumberToBas
          SaveAsRenumberedBas()

        Case #Menu_DignifiedToAscii
          SaveAsAsciiFromDignified()

        Case #Menu_DignifiedToTokenized
          SaveAsTokenizedFromDignified()

        Case #Menu_CloseTab
          CloseTab(ActiveTabPosition)

        Case #Menu_Find
          Editor_Find()

        Case #Menu_FindNext
          Editor_FindNext()

        Case #Menu_Replace
          Editor_Replace()

        Case #Menu_GotoLine
          Editor_GotoLine()

        Case #Menu_Exit
          Quit = 1

        Case #Menu_CreateDisk
          DiskMgr_OpenWindow(#MainWindow)

        Case #Menu_CreateSprite
          SpriteEditor_OpenWindow(#MainWindow)

        Case #Menu_CreateAlphabet
          CharsetEditor_OpenWindow(#MainWindow)

        Case #Menu_CreateAlphabetAquarela
          AquarelaCharsetEditor_OpenWindow(#MainWindow)

        Case #Menu_CreateSound
          PsgEditor_OpenWindow(#MainWindow)

        Case #Menu_CreateSeeTracker
          SeeTrackerEditor_OpenWindow(#MainWindow)

        Case #Menu_CreateMml
          MmlEditor_OpenWindow(#MainWindow)

        Case #Menu_CreateScreen2
          Screen2Editor_OpenWindow(#MainWindow)

        Case #Menu_CreateGraphosScreen
          GraphosScreenGui_OpenWindow(#MainWindow)

        Case #Menu_CreateScreen0
          Screen0Editor_OpenWindow(#MainWindow)

        Case #Menu_CreateScreen1
          Screen1Editor_OpenWindow(#MainWindow)

        Case #Menu_CreateScreen12
          Screen12Editor_OpenWindow(#MainWindow)

        Case #Menu_CreateZ80Lib
          Z80LibGui_OpenWindow(#MainWindow)

        Case #Menu_CreateAsmSubProject
          Z80SubProjectGui_OpenWindow(#MainWindow)

        Case #Menu_InsertSpecialChar
          CharMap_OpenWindow(#MainWindow)

        Case #Menu_RunBasic
          RunBasicFromActiveTab()

        Case #Menu_RunNestorBasic
          RunNestorBasicFromActiveTab()

        Case #Menu_CompileMsxBas2RomRom
          CompileMsxBas2RomFromActiveTab()

        Case #Menu_RenumberBasic
          RenumberActiveTabInPlace()

        Case #Menu_AssembleZ80
          AssembleZ80FromActiveTab()

        Case #Menu_AssembleZ80Rel
          AssembleZ80RelFromActiveTab()

        Case #Menu_LinkZ80
          Z80LinkGui_OpenWindow(#MainWindow)

        Case #Menu_AssembleAsmsx
          AssembleAsmsxFromActiveTab()

        Case #Menu_HexEditor
          HexEditor_OpenWindow(#MainWindow)

        Case #Menu_MamuteAssembler
          MamuteAssembler_OpenWindow(#MainWindow)

        Case #Menu_OpenMSXConsole
          OMSXGui_OpenWindow(#MainWindow)

        Case #Menu_ViewMdTxt
          MdView_OpenSingle(#MainWindow)

        Case #Menu_ViewMdTxtSplit
          MdView_OpenSplit(#MainWindow)

        Case #Menu_ConfigureBadig
          BadigCfg_OpenSettingsWindow(#MainWindow)

        Case #Menu_ConfigureEditor
          If EditorCfg_OpenSettingsWindow(#MainWindow)
            ApplyTheme()
            SetWindowColor(#MainWindow, Color_AppBg)
            ForEach Docs()
              SetupEditorStyles(Docs()\SciGadget)
              HighlightDocument(Docs()\SciGadget)
            Next
            ResizeInterface()
          EndIf

        Case #Menu_ConfigureBasicOptions
          BasicOptionsCfg_OpenSettingsWindow(#MainWindow)

        Case #Menu_ConfigureAssemblyOptions
          AssemblyOptionsCfg_OpenSettingsWindow(#MainWindow)

        Case #Menu_ConfigureMsxBas2Rom
          MsxBas2RomSettings_OpenWindow(#MainWindow)

        Case #Menu_ConfigureN80
          N80Settings_OpenWindow(#MainWindow)

        Case #Menu_ConfigureAsmsx
          AsmsxSettings_OpenWindow(#MainWindow)

        Case #Menu_ConfigureMamuteAssembler
          MamuteSettings_OpenWindow(#MainWindow)

        Case #Menu_ConfigureOpenMSX
          OpenMsxCfg_OpenSettingsWindow(#MainWindow)

        Case #Menu_ConfigureFileAssociations
          FileAssoc_OpenWindow(#MainWindow)

        Case #Menu_ConfigureProject
          ProjSettings_OpenWindow(#MainWindow)

        Case #Menu_HelpEditor
          EditorHelp_OpenWindow(#MainWindow)

        Case #Menu_HelpNestorBasic
          NestorBasicHelp_OpenWindow(#MainWindow)

        Case #Menu_HelpMsxBasic
          MsxBasicHelp_OpenWindow(#MainWindow)

        Case #Menu_HelpManuals
          MsxManualsHelp_OpenWindow(#MainWindow)

        Case #Menu_HelpSoftware
          MsxSoftwareHelp_OpenWindow(#MainWindow)

        Case #Menu_HelpBiosCalls
          BiosCallsHelp_OpenWindow(#MainWindow)

        Case #Menu_HelpHardware
          HardwareHelp_OpenWindow(#MainWindow)

        Case #Menu_HelpBiosDoc
          BiosDocHelp_OpenWindow(#MainWindow)

        Case #Menu_HelpRedBook
          RedBookHelp_OpenWindow(#MainWindow)

        Case #Menu_HelpTh2Handbook
          Th2HandbookHelp_OpenWindow(#MainWindow)

        Case #Menu_HelpBasicDignified
          BasicDignifiedHelp_OpenWindow(#MainWindow)

        Case #Menu_HelpSeeTracker
          SeeTrackerHelp_OpenWindow(#MainWindow)

        Case #Menu_HelpMamuteAssembler
          MamuteHelp_OpenWindow(#MainWindow)

        Case #Menu_HelpOpenMSX
          OpenMsxHelp_OpenWindow(#MainWindow)

        Case #Menu_HelpMsxBas2Rom
          GenMdHelp_OpenWindow(#MainWindow, "Ajuda - MSXBas2Rom", MsxBas2Rom_HelpDir())

        Case #Menu_HelpN80
          GenMdHelp_OpenWindow(#MainWindow, "Ajuda - N80 / LinkStor80 / LibStor80 / M80L80", N80_HelpDir())

        Case #Menu_HelpAsmsx
          AsmsxHelp_OpenWindow(#MainWindow)

        Case #Menu_HelpAbout
          ShowAboutDialog()
      EndSelect

    Case #PB_Event_Gadget
      Select EventGadget()
        Case #TabBarGadget
          Select EventType()
            Case #PB_EventType_LeftButtonDown
              MouseX = GetGadgetAttribute(#TabBarGadget, #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(#TabBarGadget, #PB_Canvas_MouseY)
              HitPos = 0
              TabDebug_Hit = #False
              ForEach Docs()
                If MouseX >= Docs()\TabX1 And MouseX < Docs()\TabX2
                  TabDebug_Hit = #True
                  If MouseX >= Docs()\CloseX1 - 4 And MouseX <= Docs()\CloseX2 + 4 And MouseY >= 4 And MouseY <= #TabBar_Height - 4
                    TabDebugLog("TabBar click: fechar aba HitPos=" + Str(HitPos) + " MouseX=" + Str(MouseX) + " MouseY=" + Str(MouseY))
                    CloseTab(HitPos)
                  Else
                    TabDebugLog("TabBar click: trocar para HitPos=" + Str(HitPos) + " MouseX=" + Str(MouseX) + " MouseY=" + Str(MouseY))
                    SetActiveTab(HitPos)
                  EndIf
                  Break
                EndIf
                HitPos + 1
              Next
              If Not TabDebug_Hit
                TabDebugLog("TabBar click: NENHUMA aba atingida  MouseX=" + Str(MouseX) + " MouseY=" + Str(MouseY) + " DocsCount=" + Str(ListSize(Docs())))
              EndIf

            Case #PB_EventType_MouseMove
              MouseX = GetGadgetAttribute(#TabBarGadget, #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(#TabBarGadget, #PB_Canvas_MouseY)
              NewHoverTab = -1
              NewHoverClose = -1
              HitPos = 0
              ForEach Docs()
                If MouseX >= Docs()\TabX1 And MouseX < Docs()\TabX2
                  NewHoverTab = HitPos
                  If MouseX >= Docs()\CloseX1 - 4 And MouseX <= Docs()\CloseX2 + 4
                    NewHoverClose = HitPos
                  EndIf
                  Break
                EndIf
                HitPos + 1
              Next
              If NewHoverTab <> HoverTabPosition Or NewHoverClose <> HoverCloseTabPosition
                HoverTabPosition = NewHoverTab
                HoverCloseTabPosition = NewHoverClose
                RedrawTabBar()
              EndIf

            Case #PB_EventType_MouseLeave
              If HoverTabPosition <> -1 Or HoverCloseTabPosition <> -1
                HoverTabPosition = -1
                HoverCloseTabPosition = -1
                RedrawTabBar()
              EndIf
          EndSelect
      EndSelect

    Case #PB_Event_CloseWindow
      Quit = 1

    Case #PB_Event_SizeWindow
      ResizeInterface()

    Case #Event_UpdateUI
      ChangedGadget = EventGadget()
      If ChangedGadget = ActiveSciGadget()
        UpdateLineNumberMargin(ChangedGadget)
        RedrawRuler()
        UpdateStatusBar()
      EndIf
      ; Apaga o popup de auto completar se um backspace derrubou a palavra
      ; sendo digitada abaixo do minimo de letras configurado (SCN_CHARADDED
      ; so dispara ao inserir, entao o encolhimento e pego aqui).
      If ScintillaSendMessage(ChangedGadget, #SCI_AUTOCACTIVE)
        AcPos = ScintillaSendMessage(ChangedGadget, #SCI_GETCURRENTPOS)
        AcStart = ScintillaSendMessage(ChangedGadget, #SCI_WORDSTARTPOSITION, AcPos, #True)
        If AcPos - AcStart < AutoCompleteMinCharsForGadget(ChangedGadget)
          ScintillaSendMessage(ChangedGadget, #SCI_AUTOCCANCEL)
        EndIf
      EndIf

    Case #Event_Rehighlight
      ChangedGadget = EventGadget()
      TabDebugLog("Event_Rehighlight  ChangedGadget=" + Str(ChangedGadget) + "  ActiveSciGadget=" + Str(ActiveSciGadget()) + "  EventData=" + Str(EventData()))
      If Not EventData()
        DocPos = FindDocumentByGadget(ChangedGadget)
        If DocPos >= 0
          If SelectElement(Docs(), DocPos)
            If Not Docs()\Modified
              Docs()\Modified = #True
              UpdateTabCaption(DocPos)
            EndIf
          EndIf
        EndIf
      EndIf
      HighlightDocument(ChangedGadget)

    Case #Event_AutoComplete
      HandleAutoCompleteCharAdded(EventGadget(), EventData())

  EndSelect

  If Quit
    AllSaved = #True
    ForEach Docs()
      If Docs()\Modified
        AllSaved = #False
        Break
      EndIf
    Next
    If Not AllSaved
      Discard = ConfirmDiscard("Existem documentos com alteracoes nao salvas." + Chr(10) + "Sair mesmo assim?")
      If Not Discard
        Quit = 0
      EndIf
    EndIf

    ; Projeto (sprites) nao salvo permanentemente - so pergunta se os
    ; documentos de texto ja deixaram passar (senao seria uma segunda
    ; confirmacao em cima da primeira).
    If Quit And ProjectDB::HasUnsavedContent()
      If Not OfferSaveProject()
        Quit = 0
      EndIf
    EndIf
  EndIf

Until Quit = 1

; Pedido do usuario: ao encerrar o programa, garante que o .msxproject fica
; com uma copia fresca (do disco, nao do buffer) de todos os fontes que ja
; conhece - ver ResyncProjectDocumentsFromDisk() acima.
ResyncProjectDocumentsFromDisk()
ProjectDB::Close()
End

; Mesmo motivo do XIncludeFile "core/EditorSearch.pbi" logo abaixo: usa
; Docs()/ActiveTabPosition/ReadSciText/WriteSciText/HighlightMarkdownText/
; SetupEditorStyles, todos definidos ao longo deste arquivo - ver Declare de
; MdView_OpenSingle/MdView_OpenSplit perto do topo para a chamada em
; #Menu_ViewMdTxt/#Menu_ViewMdTxtSplit, que vem antes textualmente.
XIncludeFile "core/MdViewerGui.pbi"

; Mesmo motivo acima: ProjIndex_OpenWindow() precisa de AddDocumentTab()/
; SetActiveTab()/Docs(), todos definidos ao longo deste arquivo - ver Declare
; de ProjIndex_OpenWindow perto do topo para a chamada em #Menu_ProjectIndex,
; que vem antes textualmente.
XIncludeFile "core/ProjectIndexGui.pbi"

; Incluido so aqui no fim (nao junto com os demais XIncludeFile no topo) porque
; usa ActiveSciGadget(), definido ao longo deste arquivo - ver Declare de
; Editor_Find/Editor_FindNext/Editor_Replace/Editor_GotoLine perto do topo
; para as poucas chamadas na direcao inversa.
XIncludeFile "core/EditorSearch.pbi"
