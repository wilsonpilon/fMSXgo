;
; ------------------------------------------------------------
;  FileBrowserGui.pbi - gerenciador de arquivos proprio (simples) para as
;  caixas "Abrir..."/"Salvar como..." do editor, no lugar dos dialogos
;  nativos do Windows (OpenFileRequester/SaveFileRequester). Mostra o
;  conteudo de pastas, permite entrar/sair de diretorio, trocar de unidade
;  (Windows) e filtrar por nome/tipo (ex.: "arq*.*", "*.msx*", "*.amx").
;
;  Mesma logica de navegacao ja provada em core/DiskManagerGui.pbi (painel
;  esquerdo daquele gerenciador de disco - DiskMgrEntry/DiskMgr_LoadLocalDir/
;  DiskMgr_ParentDir/DiskMgr_FormatSize), copiada aqui com nomes FB_* (dois
;  Structure/Procedure com o mesmo nome no mesmo compilation unit nao
;  compilam, e nao vale a pena refatorar o DiskManagerGui.pbi que ja
;  funciona so para compartilhar ~20 linhas) e estendida com o que faltava:
;  campo de filtro (la o ExamineDirectory e fixo em "*.*") e troca de
;  unidade (nao existe em nenhum outro lugar do projeto).
; ------------------------------------------------------------
;

EnableExplicit

#FileBrowser_Open = 0
#FileBrowser_Save = 1

Structure FBEntry
  Name.s
  IsDir.b
  Size.q
  DateTime.i
  SortKey.s
EndStructure

; Lembra a ultima pasta usada nesta sessao (conveniencia, igual o
; comportamento do dialogo nativo do Windows) - so em memoria, nunca salvo
; em disco.
Global FileBrowser_LastDir.s = ""

Procedure.s FB_EnsureTrailingSep(Dir.s)
  If Dir <> "" And Right(Dir, 1) <> "\"
    Dir + "\"
  EndIf
  ProcedureReturn Dir
EndProcedure

; Diretorio pai de Dir (que ja deve terminar com "\"). Numa raiz de unidade
; (ex. "C:\") devolve a propria raiz, sem subir mais.
Procedure.s FB_ParentDir(Dir.s)
  Protected Trimmed.s = Dir
  If Right(Trimmed, 1) = "\"
    Trimmed = Left(Trimmed, Len(Trimmed) - 1)
  EndIf
  Protected Parent.s = GetPathPart(Trimmed)
  If Parent = "" Or Parent = Trimmed
    ProcedureReturn Dir
  EndIf
  ProcedureReturn Parent
EndProcedure

Procedure.s FB_FormatSize(Size.q)
  If Size < 1024
    ProcedureReturn Str(Size) + " B"
  ElseIf Size < 1024 * 1024
    ProcedureReturn StrF(Size / 1024.0, 1) + " KB"
  Else
    ProcedureReturn StrF(Size / (1024.0 * 1024.0), 1) + " MB"
  EndIf
EndProcedure

; Lista o conteudo de Dir em Entries(): ".." primeiro (exceto em raiz de
; unidade), depois pastas, depois arquivos, cada grupo em ordem alfabetica.
; Duas passadas de ExamineDirectory de proposito: pastas sempre aparecem
; (senao nao da pra navegar), so os ARQUIVOS respeitam Pattern - mesmo
; comportamento dos dialogos nativos (o filtro de tipo nunca esconde pastas).
Procedure FB_LoadDir(Dir.s, Pattern.s, List Entries.FBEntry())
  ClearList(Entries())

  Protected FilterPattern.s = Pattern
  If FilterPattern = ""
    FilterPattern = "*.*"
  EndIf

  Protected dd = ExamineDirectory(#PB_Any, Dir, "*.*")
  If dd
    While NextDirectoryEntry(dd)
      If DirectoryEntryType(dd) = #PB_DirectoryEntry_Directory
        Protected DName.s = DirectoryEntryName(dd)
        If DName = "."
          ; pula, sem interesse para navegacao
        ElseIf DName = ".." And Len(Dir) <= 3
          ; ja esta na raiz da unidade, sem pai para subir
        Else
          AddElement(Entries())
          Entries()\Name = DName
          Entries()\IsDir = #True
          Entries()\DateTime = DirectoryEntryDate(dd, #PB_Date_Modified)
          If DName = ".."
            Entries()\SortKey = "0 .."
          Else
            Entries()\SortKey = "1" + LCase(DName)
          EndIf
        EndIf
      EndIf
    Wend
    FinishDirectory(dd)
  EndIf

  Protected fd = ExamineDirectory(#PB_Any, Dir, FilterPattern)
  If fd
    While NextDirectoryEntry(fd)
      If DirectoryEntryType(fd) = #PB_DirectoryEntry_File
        AddElement(Entries())
        Entries()\Name = DirectoryEntryName(fd)
        Entries()\IsDir = #False
        Entries()\Size = DirectoryEntrySize(fd)
        Entries()\DateTime = DirectoryEntryDate(fd, #PB_Date_Modified)
        Entries()\SortKey = "2" + LCase(Entries()\Name)
      EndIf
    Wend
    FinishDirectory(fd)
  EndIf

  SortStructuredList(Entries(), #PB_Sort_Ascending, OffsetOf(FBEntry\SortKey), TypeOf(FBEntry\SortKey))
EndProcedure

Procedure FB_FillListIcon(Gadget, List Entries.FBEntry())
  ClearGadgetItems(Gadget)
  ForEach Entries()
    Protected SizeText.s, DateText.s
    If Entries()\Name = ".."
      SizeText = "" : DateText = ""
    ElseIf Entries()\IsDir
      SizeText = "<pasta>"
      DateText = FormatDate("%yyyy-%mm-%dd %hh:%ii", Entries()\DateTime)
    Else
      SizeText = FB_FormatSize(Entries()\Size)
      DateText = FormatDate("%yyyy-%mm-%dd %hh:%ii", Entries()\DateTime)
    EndIf
    AddGadgetItem(Gadget, -1, Entries()\Name + Chr(10) + SizeText + Chr(10) + DateText)
  Next
EndProcedure

; Enumera unidades disponiveis (bitmask de A-Z, GetLogicalDrives_ do
; kernel32) - "unidade de disco" so existe no Windows, e nao ha comando
; builtin do PureBasic para isso (ao contrario de ExamineDirectory, que e
; cross-platform). Sem equivalente em Linux/Mac por natureza (ver
; paleobasic/CLAUDE.md sobre o build Linux via build.sh) - la o combo de
; unidade nem e criado, ver FileBrowser_Show.
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  Procedure FB_ListDrives(List Drives.s())
    ClearList(Drives())
    Protected Mask.l = GetLogicalDrives_()
    Protected i.i
    For i = 0 To 25
      If Mask & (1 << i)
        AddElement(Drives())
        Drives() = Chr(65 + i) + ":\"
      EndIf
    Next
  EndProcedure
CompilerEndIf

; Mostra o gerenciador de arquivos e devolve o caminho completo escolhido,
; ou "" se cancelado.
; Mode        = #FileBrowser_Open ou #FileBrowser_Save
; Title       = titulo da janela
; InitialDir  = pasta inicial ("" = ultima pasta usada na sessao, ou a pasta
;               do usuario se nunca navegou)
; InitialName = nome sugerido no campo "Nome do arquivo" (tipicamente "" no
;               modo Abrir, nome do arquivo atual no modo Salvar)
; Pattern     = filtro inicial de arquivos (ex. "*.dmx", "*.msxproject",
;               "*.*") - o usuario pode editar livremente (nome: "arq*.*",
;               tipo: "*.msx*"/"*.amx")
Procedure.s FileBrowser_Show(ParentWindow.i, Mode.b, Title.s, InitialDir.s, InitialName.s, Pattern.s)
  Protected CurDir.s = InitialDir
  If CurDir = "" Or FileSize(CurDir) <> -2
    CurDir = FileBrowser_LastDir
  EndIf
  If CurDir = "" Or FileSize(CurDir) <> -2
    CurDir = GetHomeDirectory()
  EndIf
  CurDir = FB_EnsureTrailingSep(CurDir)

  Protected FilterInit.s = Pattern
  If FilterInit = ""
    FilterInit = "*.*"
  EndIf

  Protected WinW = 760, WinH = 550
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, Title,
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_SizeGadget)
  If Not Win
    ProcedureReturn ""
  EndIf

  Protected NewList Drives.s()
  Protected G_Drive
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    FB_ListDrives(Drives())
    G_Drive = ComboBoxGadget(#PB_Any, 24, 24, 90, 24)
    Protected DriveIndex.i = 0, DriveSelIndex.i = 0
    ForEach Drives()
      AddGadgetItem(G_Drive, -1, Drives())
      If LCase(Left(Drives(), 1)) = LCase(Left(CurDir, 1))
        DriveSelIndex = DriveIndex
      EndIf
      DriveIndex + 1
    Next
    SetGadgetState(G_Drive, DriveSelIndex)
  CompilerEndIf

  ; ThemedButton so desenha o icone OU o texto (icone tem prioridade, texto e
  ; so o fallback quando a fonte de icones esta desabilitada/indisponivel -
  ; ver ThemedUI_CreateButtonImage em ThemedButtons.pbi) - por isso sempre
  ; passa um texto real, nunca "", mesmo nos botoes com icone.
  Protected G_Up = ThemedButton(122, 24, 80, 24, "Subir", Chr(#Icon_ArrowUp))
  GadgetToolTip(G_Up, "Subir um nivel")
  Protected G_Refresh = ThemedButton(210, 24, 100, 24, "Atualizar", Chr(#Icon_Refresh))
  GadgetToolTip(G_Refresh, "Atualizar")
  Protected G_Path = StringGadget(#PB_Any, 318, 24, 336, 24, CurDir)
  Protected G_Go = ThemedButton(662, 24, 74, 24, "Ir", "")

  Protected G_List = ListIconGadget(#PB_Any, 24, 60, WinW - 48, 320, "Nome", 350,
                                    #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  AddGadgetColumn(G_List, 1, "Tamanho", 120)
  AddGadgetColumn(G_List, 2, "Modificado", 180)

  TextGadget(#PB_Any, 24, 392, 60, 20, "Filtro")
  Protected G_Filter = StringGadget(#PB_Any, 90, 390, 340, 24, FilterInit)
  Protected G_ApplyFilter = ThemedButton(440, 390, 110, 24, "Aplicar", "")

  TextGadget(#PB_Any, 24, 428, 300, 20, "Nome do arquivo")
  Protected G_Name = StringGadget(#PB_Any, 24, 452, WinW - 48, 24, InitialName)

  Protected OkLabel.s, OkIcon.s
  If Mode = #FileBrowser_Open
    OkLabel = "Abrir" : OkIcon = Chr(#Icon_Open)
  Else
    OkLabel = "Salvar" : OkIcon = Chr(#Icon_Save)
  EndIf
  Protected G_Ok = ThemedButton(WinW - 256, WinH - 56, 110, 32, OkLabel, OkIcon)
  Protected G_Cancel = ThemedButton(WinW - 134, WinH - 56, 110, 32, "Cancelar", Chr(#Icon_Close))

  Protected NewList Entries.FBEntry()
  FB_LoadDir(CurDir, FilterInit, Entries())
  FB_FillListIcon(G_List, Entries())

  Protected Result.s = ""
  Protected Event, Quit = #False

  Repeat
    Event = WaitWindowEvent()
    Protected DoAccept.b = #False

    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          ; G_Drive so existe de verdade no Windows (ver CompilerIf acima),
          ; mas o Case fica sempre presente - so o CORPO e condicional -
          ; pra nao depender de CompilerIf cruzando um Case sem seu proprio
          ; EndSelect (fora do escopo deste arquivo pra confirmar que
          ; compila em todas as versoes do PureBasic usadas pelo projeto).
          Case G_Drive
            CompilerIf #PB_Compiler_OS = #PB_OS_Windows
              Protected PickedDrive.i = GetGadgetState(G_Drive)
              If PickedDrive >= 0 And SelectElement(Drives(), PickedDrive)
                CurDir = Drives()
                FB_LoadDir(CurDir, GetGadgetText(G_Filter), Entries())
                FB_FillListIcon(G_List, Entries())
                SetGadgetText(G_Path, CurDir)
              EndIf
            CompilerEndIf

          Case G_Up
            CurDir = FB_ParentDir(CurDir)
            FB_LoadDir(CurDir, GetGadgetText(G_Filter), Entries())
            FB_FillListIcon(G_List, Entries())
            SetGadgetText(G_Path, CurDir)

          Case G_Refresh
            FB_LoadDir(CurDir, GetGadgetText(G_Filter), Entries())
            FB_FillListIcon(G_List, Entries())

          Case G_ApplyFilter
            FB_LoadDir(CurDir, GetGadgetText(G_Filter), Entries())
            FB_FillListIcon(G_List, Entries())

          Case G_Go
            Protected TypedPath.s = FB_EnsureTrailingSep(GetGadgetText(G_Path))
            If FileSize(TypedPath) = -2
              CurDir = TypedPath
              FB_LoadDir(CurDir, GetGadgetText(G_Filter), Entries())
              FB_FillListIcon(G_List, Entries())
              SetGadgetText(G_Path, CurDir)
            Else
              MessageRequester("Caminho invalido", "Pasta nao encontrada:" + Chr(10) + TypedPath,
                               #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
            EndIf

          Case G_List
            If EventType() = #PB_EventType_LeftDoubleClick
              Protected Sel.i = GetGadgetState(G_List)
              If Sel >= 0 And SelectElement(Entries(), Sel)
                If Entries()\Name = ".."
                  CurDir = FB_ParentDir(CurDir)
                  FB_LoadDir(CurDir, GetGadgetText(G_Filter), Entries())
                  FB_FillListIcon(G_List, Entries())
                  SetGadgetText(G_Path, CurDir)
                ElseIf Entries()\IsDir
                  CurDir = FB_EnsureTrailingSep(CurDir + Entries()\Name)
                  FB_LoadDir(CurDir, GetGadgetText(G_Filter), Entries())
                  FB_FillListIcon(G_List, Entries())
                  SetGadgetText(G_Path, CurDir)
                Else
                  SetGadgetText(G_Name, Entries()\Name)
                  If Mode = #FileBrowser_Open
                    DoAccept = #True
                  EndIf
                EndIf
              EndIf
            EndIf

          Case G_Ok
            DoAccept = #True

          Case G_Cancel
            Quit = #True
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect

    If DoAccept
      Protected NameText.s = Trim(GetGadgetText(G_Name))
      If NameText = ""
        MessageRequester("Nome de arquivo", "Informe um nome de arquivo.",
                         #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
      Else
        Protected FullPath.s = CurDir + NameText
        Protected Accepted.b = #True
        If Mode = #FileBrowser_Save And FileSize(FullPath) >= 0
          Accepted = Bool(MessageRequester("Confirmar",
                          "O arquivo ja existe:" + Chr(10) + FullPath + Chr(10) + Chr(10) + "Sobrescrever?",
                          #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
        EndIf
        If Accepted
          Result = FullPath
          FileBrowser_LastDir = CurDir
          Quit = #True
        EndIf
      EndIf
    EndIf
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
  ProcedureReturn Result
EndProcedure
