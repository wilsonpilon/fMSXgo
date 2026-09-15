;
; ------------------------------------------------------------
;  "Projeto -> Indice de recursos...": lista, num unico lugar, TODO o
;  conteudo guardado no .msxproject atual (documentos/programas, sprites,
;  alfabetos, sons, SFX, musicas, telas nos varios formatos, Graphos III,
;  Assembly Sub-Projects) mais os .dsk soltos ao lado do .msxproject.
;
;  Motivacao (pedido do usuario, 2026-08-21): quem digita um artigo de
;  revista/livro (type-in) quer poder empacotar, dentro de UM .msxproject so,
;  os programas E os artigos explicando como usa-los (como .md - ver
;  MdViewerGui.pbi/GenericMdHelpGui.pbi) e os discos prontos - abrindo o
;  projeto, a pessoa teria como ver rapido "o que tem aqui dentro" sem
;  precisar conhecer os nomes de arquivo de antemao.
;
;  So CATALOGA e abre o editor certo pra cada item - nao edita nada aqui
;  dentro. "Abrir" um documento troca pra aba correspondente (cria se
;  necessario, ver OpenFileIntoTab() em BadigEditor.pb); "Abrir" um recurso
;  numerado (sprite/alfabeto/som/etc) abre o editor daquele TIPO de recurso
;  (SpriteEditor_OpenWindow etc.) - esses editores ainda nao aceitam "abrir
;  direto no numero X" (nenhum _OpenWindow() do projeto toma esse parametro
;  hoje), entao o usuario pode precisar navegar ate o numero certo dentro do
;  editor depois de aberto; "Abrir" um disco abre o Gerenciador de Disco com
;  o caminho ja sugerido no seletor (ver DiskMgr_OpenWindow, parametro
;  InitialPath).
;
;  Deliberadamente NAO usa ProjectDB::Fetch*() pra mostrar a Tag de cada
;  recurso numerado (sprite/alfabeto/som/etc.): essas funcoes escrevem direto
;  nos Array parametro do tamanho REAL do recurso (grid_size, numero de
;  passos, etc.) sem nenhum ReDim interno - dar um array pre-dimensionado
;  pequeno demais estoura o limite (mesma familia de bug ja documentada no
;  CLAUDE.md deste projeto, ex.: CopyMap() em mapa vazio). Descobrir o
;  tamanho certo de cada um dos 12 tipos so pra mostrar uma tag numa lista
;  nao vale o risco - a lista mostra so o numero (List*Numbers(), que ja
;  garante que o recurso existe), sem abrir cada um.
; ------------------------------------------------------------
;

Structure ProjIndexRow
  Kind.s
  Path.s
EndStructure

Procedure ProjIndex_AddRow(ListIcon, List Rows.ProjIndexRow(), Kind.s, Path.s, Tipo.s, Item.s)
  AddGadgetItem(ListIcon, -1, Tipo + Chr(10) + Item)
  AddElement(Rows())
  Rows()\Kind = Kind
  Rows()\Path = Path
EndProcedure

; DocMode ("ASM"/"BAS"/"MD"/"DMX", ver AddDocumentTab() em BadigEditor.pb) ->
; rotulo humano pra coluna Tipo.
Procedure.s ProjIndex_DocTypeLabel(DocMode.s)
  Select DocMode
    Case "ASM"
      ProcedureReturn "Programa (Assembly)"
    Case "BAS"
      ProcedureReturn "Programa (MSX-BASIC)"
    Case "MD"
      ProcedureReturn "Artigo (Markdown)"
    Default
      ProcedureReturn "Programa (Basic Dignified)"
  EndSelect
EndProcedure

; Kind+Tipo+Numero de cada tipo de recurso numerado (sprites/alfabetos/sons/
; etc.) - todos seguem o mesmo padrao (ListXNumbers() -> "#N"), reunidos aqui
; num unico loop generico em vez de 12 blocos quase identicos.
Procedure ProjIndex_AddNumberedRows(ListIcon, List Rows.ProjIndexRow(), Kind.s, Tipo.s, List Numbers.i())
  ForEach Numbers()
    ProjIndex_AddRow(ListIcon, Rows(), Kind, "", Tipo, "#" + Str(Numbers()))
  Next
EndProcedure

Procedure ProjIndex_FillList(ListIcon, List Rows.ProjIndexRow())
  ClearGadgetItems(ListIcon)
  ClearList(Rows())

  ; --- Documentos (programas/artigos) ---
  NewList DocPaths.s()
  ProjectDB::ListDocumentPaths(DocPaths())
  ForEach DocPaths()
    Protected DocPath.s = DocPaths()
    Protected DocMode.s = "DMX"
    If ProjectDB::FetchDocument(DocPath)
      DocMode = ProjectDB::LastDocumentMode()
    EndIf
    ProjIndex_AddRow(ListIcon, Rows(), "DOC", DocPath, ProjIndex_DocTypeLabel(DocMode), GetFilePart(DocPath))
  Next

  ; --- Recursos numerados (sprites, alfabetos, sons, telas, Graphos, etc.) ---
  NewList Numbers.i()

  ClearList(Numbers()) : ProjectDB::ListSpriteNumbers(Numbers())
  ProjIndex_AddNumberedRows(ListIcon, Rows(), "SPRITE", "Sprite", Numbers())

  ClearList(Numbers()) : ProjectDB::ListAlphabetNumbers(Numbers())
  ProjIndex_AddNumberedRows(ListIcon, Rows(), "ALPHABET", "Alfabeto (.ALF)", Numbers())

  ClearList(Numbers()) : ProjectDB::ListSoundNumbers(Numbers())
  ProjIndex_AddNumberedRows(ListIcon, Rows(), "SOUND", "Som (PSG)", Numbers())

  ClearList(Numbers()) : ProjectDB::ListSeeSfxNumbers(Numbers())
  ProjIndex_AddNumberedRows(ListIcon, Rows(), "SEESFX", "SFX (SEE Tracker)", Numbers())

  ClearList(Numbers()) : ProjectDB::ListSongNumbers(Numbers())
  ProjIndex_AddNumberedRows(ListIcon, Rows(), "SONG", "Musica (MML)", Numbers())

  ClearList(Numbers()) : ProjectDB::ListScreenNumbers(Numbers())
  ProjIndex_AddNumberedRows(ListIcon, Rows(), "SCREEN", "Tela (Screen 2)", Numbers())

  ClearList(Numbers()) : ProjectDB::ListScreen0Numbers(Numbers())
  ProjIndex_AddNumberedRows(ListIcon, Rows(), "SCREEN0", "Tela (Screen 0)", Numbers())

  ClearList(Numbers()) : ProjectDB::ListScreen1Numbers(Numbers())
  ProjIndex_AddNumberedRows(ListIcon, Rows(), "SCREEN1", "Tela (Screen 1)", Numbers())

  ClearList(Numbers()) : ProjectDB::ListScreen12Numbers(Numbers())
  ProjIndex_AddNumberedRows(ListIcon, Rows(), "SCREEN12", "Tela (Screen 1+2)", Numbers())

  ClearList(Numbers()) : ProjectDB::ListGraphosScreenNumbers(Numbers())
  ProjIndex_AddNumberedRows(ListIcon, Rows(), "GRAPHOS_SCREEN", "Graphos III (Tela)", Numbers())

  ClearList(Numbers()) : ProjectDB::ListGraphosLayoutNumbers(Numbers())
  ProjIndex_AddNumberedRows(ListIcon, Rows(), "GRAPHOS_LAYOUT", "Graphos III (Layout)", Numbers())

  ClearList(Numbers()) : ProjectDB::ListGraphosShapeNumbers(Numbers())
  ProjIndex_AddNumberedRows(ListIcon, Rows(), "GRAPHOS_SHAPE", "Graphos III (Shape)", Numbers())

  ClearList(Numbers()) : ProjectDB::ListAsmSubProjectNumbers(Numbers())
  ProjIndex_AddNumberedRows(ListIcon, Rows(), "ASMSUBPROJECT", "Assembly Sub-Projeto", Numbers())

  ; --- Discos (.dsk soltos ao lado do .msxproject - nao ficam guardados no
  ; banco do projeto como os demais tipos acima, ver DiskManagerGui.pbi) ---
  Protected ProjectDir.s = GetPathPart(ProjectDB::GetPath())
  If ProjectDir <> ""
    Protected DskDir.i = ExamineDirectory(#PB_Any, ProjectDir, "*.dsk")
    If DskDir
      While NextDirectoryEntry(DskDir)
        If DirectoryEntryType(DskDir) = #PB_DirectoryEntry_File
          Protected DskPath.s = ProjectDir + DirectoryEntryName(DskDir)
          ProjIndex_AddRow(ListIcon, Rows(), "DISK", DskPath, "Disco (.dsk)", GetFilePart(DskPath))
        EndIf
      Wend
      FinishDirectory(DskDir)
    EndIf
  EndIf
EndProcedure

Procedure ProjIndex_OpenSelected(ParentWindow, ListIcon, List Rows.ProjIndexRow())
  Protected Sel = GetGadgetState(ListIcon)
  If Sel < 0 Or Not SelectElement(Rows(), Sel)
    ProcedureReturn
  EndIf

  Select Rows()\Kind
    Case "DOC"
      OpenFileIntoTab(Rows()\Path)
    Case "SPRITE"
      SpriteEditor_OpenWindow(ParentWindow)
    Case "ALPHABET"
      CharsetEditor_OpenWindow(ParentWindow)
    Case "SOUND"
      PsgEditor_OpenWindow(ParentWindow)
    Case "SEESFX"
      SeeTrackerEditor_OpenWindow(ParentWindow)
    Case "SONG"
      MmlEditor_OpenWindow(ParentWindow)
    Case "SCREEN"
      Screen2Editor_OpenWindow(ParentWindow)
    Case "SCREEN0"
      Screen0Editor_OpenWindow(ParentWindow)
    Case "SCREEN1"
      Screen1Editor_OpenWindow(ParentWindow)
    Case "SCREEN12"
      Screen12Editor_OpenWindow(ParentWindow)
    Case "GRAPHOS_SCREEN", "GRAPHOS_LAYOUT", "GRAPHOS_SHAPE"
      GraphosScreenGui_OpenWindow(ParentWindow)
    Case "ASMSUBPROJECT"
      Z80SubProjectGui_OpenWindow(ParentWindow)
    Case "DISK"
      DiskMgr_OpenWindow(ParentWindow, Rows()\Path)
  EndSelect
EndProcedure

Procedure ProjIndex_OpenWindow(ParentWindow)
  Protected WinW = 640, WinH = 520
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Indice de recursos do projeto",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_SizeGadget)
  If Not Win
    ProcedureReturn
  EndIf

  Protected ProjLabel.s = ProjectDB::GetPath()
  If ProjLabel = ""
    ProjLabel = "(projeto ainda nao salvo)"
  EndIf
  TextGadget(#PB_Any, 24, 20, WinW - 48, 20, ProjLabel)

  Protected ListY = 48, ListH = WinH - ListY - 64
  Protected ListIcon = ListIconGadget(#PB_Any, 24, ListY, WinW - 48, ListH, "Tipo", 220,
                                      #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  AddGadgetColumn(ListIcon, 1, "Item", WinW - 48 - 220 - 24)

  NewList Rows.ProjIndexRow()
  ProjIndex_FillList(ListIcon, Rows())

  Protected G_Refresh = ThemedButton(24, WinH - 44, 130, 32, "Atualizar", Chr(#Icon_Refresh))
  Protected G_Open    = ThemedButton(WinW - 24 - 220, WinH - 44, 100, 32, "Abrir", "")
  Protected G_Close   = ThemedButton(WinW - 24 - 110, WinH - 44, 110, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case ListIcon
            If EventType() = #PB_EventType_LeftDoubleClick
              ProjIndex_OpenSelected(Win, ListIcon, Rows())
            EndIf

          Case G_Refresh
            ProjIndex_FillList(ListIcon, Rows())

          Case G_Open
            ProjIndex_OpenSelected(Win, ListIcon, Rows())

          Case G_Close
            Quit = #True
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
