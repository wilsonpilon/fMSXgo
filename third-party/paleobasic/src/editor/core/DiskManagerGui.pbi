;
; ------------------------------------------------------------
;  Apelido interno: Diplodoco (tema pre-historico do projeto, ver README.md)
;  Criar -> Disco...: gerenciador grafico de discos MSX (.dsk)
;  Interface com dois paineis (estilo Norton/Total Commander): esquerda =
;  sistema de arquivos local (comeca no diretorio corrente do BadigEditor),
;  direita = conteudo do disco MSX aberto/em criacao. Botoes "Adicionar >>"/
;  "<< Extrair" fazem SEMPRE copia (nunca apagam a origem) nos dois sentidos.
;
;  Modelo de rascunho: ao escolher/criar um disco, as operacoes acontecem
;  numa copia temporaria (pasta temp do sistema) via MSXDisk::CreateDisk/
;  OpenDisk/AddFile/ExtractFile - o arquivo .dsk escolhido pelo usuario SO
;  e gravado de verdade ao clicar "Salvar"/"Salvar como.../"Duplicar...".
;  "Cancelar" descarta a copia temporaria sem tocar no arquivo de destino.
; ------------------------------------------------------------
;

#File_Pattern_Disk = "Imagem de disco MSX (*.dsk)|*.dsk|Todos os arquivos (*.*)|*.*"

Structure DiskMgrEntry
  Name.s
  IsDir.b
  Size.q
  DateTime.i
  SortKey.s
EndStructure

Procedure.s DiskMgr_EnsureTrailingSep(Dir.s)
  If Dir <> "" And Right(Dir, 1) <> "\"
    Dir + "\"
  EndIf
  ProcedureReturn Dir
EndProcedure

; Diretorio pai de Dir (que ja deve terminar com "\"). Numa raiz de unidade
; (ex. "C:\") devolve a propria raiz, sem subir mais.
Procedure.s DiskMgr_ParentDir(Dir.s)
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

Procedure.s DiskMgr_FormatSize(Size.q)
  If Size < 1024
    ProcedureReturn Str(Size) + " B"
  ElseIf Size < 1024 * 1024
    ProcedureReturn StrF(Size / 1024.0, 1) + " KB"
  Else
    ProcedureReturn StrF(Size / (1024.0 * 1024.0), 1) + " MB"
  EndIf
EndProcedure

Procedure.s DiskMgr_NewTempPath()
  ProcedureReturn GetTemporaryDirectory() + "BadigDiskMgr_" +
                  FormatDate("%yyyy%mm%dd%hh%ii%ss", Date()) + "_" +
                  Str(Random(999999)) + ".dsk"
EndProcedure

; Lista o conteudo de Dir (diretorios e arquivos locais) em Entries(), com
; ".." primeiro (exceto em raiz de unidade), depois pastas, depois arquivos,
; cada grupo em ordem alfabetica (chave de ordenacao unica em SortKey).
Procedure DiskMgr_LoadLocalDir(Dir.s, List Entries.DiskMgrEntry())
  ClearList(Entries())

  Protected d = ExamineDirectory(#PB_Any, Dir, "*.*")
  If d
    While NextDirectoryEntry(d)
      Protected Name.s = DirectoryEntryName(d)
      If Name = "."
        ; pula, sem interesse para navegacao
      ElseIf Name = ".." And Len(Dir) <= 3
        ; ja esta na raiz da unidade, sem pai para subir
      Else
        AddElement(Entries())
        Entries()\Name = Name
        If DirectoryEntryType(d) = #PB_DirectoryEntry_Directory
          Entries()\IsDir = #True
          Entries()\Size = 0
        Else
          Entries()\IsDir = #False
          Entries()\Size = DirectoryEntrySize(d)
        EndIf
        Entries()\DateTime = DirectoryEntryDate(d, #PB_Date_Modified)

        If Name = ".."
          Entries()\SortKey = "0 .."
        Else
          Entries()\SortKey = Str(Bool(Not Entries()\IsDir)) + LCase(Name)
        EndIf
      EndIf
    Wend
    FinishDirectory(d)
  EndIf

  SortStructuredList(Entries(), #PB_Sort_Ascending, OffsetOf(DiskMgrEntry\SortKey), TypeOf(DiskMgrEntry\SortKey))
EndProcedure

Procedure DiskMgr_FillLocalListIcon(Gadget, List Entries.DiskMgrEntry())
  ClearGadgetItems(Gadget)
  ForEach Entries()
    Protected SizeText.s
    If Entries()\Name = ".."
      SizeText = ""
    ElseIf Entries()\IsDir
      SizeText = "<pasta>"
    Else
      SizeText = DiskMgr_FormatSize(Entries()\Size)
    EndIf
    AddGadgetItem(Gadget, -1, Entries()\Name + Chr(10) + SizeText)
  Next
EndProcedure

Procedure DiskMgr_FillDiskListIcon(Gadget, List Entries.MSXDisk::FileInfo())
  ClearGadgetItems(Gadget)
  ForEach Entries()
    Protected Dt.s = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Entries()\DateTime)
    AddGadgetItem(Gadget, -1, Entries()\FileName + Chr(10) + DiskMgr_FormatSize(Entries()\Size) + Chr(10) + Dt)
  Next
EndProcedure

; Le o disco atualmente aberto no modulo MSXDisk (so pode haver um por vez)
; e redesenha o painel direito.
Procedure DiskMgr_RefreshDiskGadget(Gadget)
  NewList Files.MSXDisk::FileInfo()
  MSXDisk::ListFiles(Files())
  DiskMgr_FillDiskListIcon(Gadget, Files())
EndProcedure

Procedure DiskMgr_SetSessionButtonsEnabled(Enabled.b, G_AddButton, G_ExtractButton, G_RemoveDiskButton, G_Save, G_SaveAs, G_Duplicate, G_DeleteDisk)
  DisableGadget(G_AddButton, Bool(Not Enabled))
  DisableGadget(G_ExtractButton, Bool(Not Enabled))
  DisableGadget(G_RemoveDiskButton, Bool(Not Enabled))
  DisableGadget(G_Save, Bool(Not Enabled))
  DisableGadget(G_SaveAs, Bool(Not Enabled))
  DisableGadget(G_Duplicate, Bool(Not Enabled))
  DisableGadget(G_DeleteDisk, Bool(Not Enabled))
EndProcedure

;- ------------------------------------------------------------
;- Janela principal (menu "Criar -> Disco...")
;- ------------------------------------------------------------

; InitialPath (opcional): pre-preenche o seletor de disco ("...") com esse
; caminho, pra quem abre esta janela ja sabendo qual .dsk quer (ex.: clicando
; um disco listado em Indice de recursos do projeto, ProjectIndexGui.pbi) nao
; precisar navegar de novo ate a pasta certa - o usuario ainda confirma no
; requester (abrir de fato so acontece no fluxo normal do botao "...", nao ha
; carregamento automatico aqui).
Procedure DiskMgr_OpenWindow(ParentWindow, InitialPath.s = "")
  ; Mesma grade de layout dos demais dialogos (EditorSettings.pbi/BadigSettings.pbi):
  ; 24px de margem externa, ~26-30px entre grupos - janela alargada (900->956)
  ; pra compensar a margem maior sem espremer os dois paineis de lista.
  Protected WinW = 956, WinH = 596
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Criar disco MSX",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  Protected LeftW = 380, MidW = 110, RightW = 366
  Protected LeftX = 24, MidX = LeftX + LeftW + 24, RightX = MidX + MidW + 24
  Protected PanelY = 96, PanelH = WinH - PanelY - 64 - 64

  TextGadget(#PB_Any, 24, 24, 140, 20, "Arquivo do disco:")
  Protected G_DiskPathText = StringGadget(#PB_Any, 172, 21, WinW - 24 - 90 - 8 - 172, 24, "", #PB_String_ReadOnly)
  Protected G_Browse = ThemedButton(WinW - 24 - 90, 21, 90, 24, "...", "")

  Protected G_LeftPathText = TextGadget(#PB_Any, LeftX, 64, LeftW, 20, "")
  Protected G_DiskStatusText = TextGadget(#PB_Any, RightX, 64, RightW, 20, "Nenhum disco selecionado")

  Protected G_LeftList = ListIconGadget(#PB_Any, LeftX, PanelY, LeftW, PanelH, "Nome", 260,
                                        #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines | #PB_ListIcon_MultiSelect)
  AddGadgetColumn(G_LeftList, 1, "Tamanho", 100)

  Protected MidCenterY = PanelY + PanelH / 2
  Protected G_AddButton     = ThemedButton(MidX + 5, MidCenterY - 82, MidW - 10, 32, "Adicionar >>", "")
  Protected G_ExtractButton = ThemedButton(MidX + 5, MidCenterY - 42, MidW - 10, 32, "<< Extrair", "")
  Protected G_RemoveLocalButton = ThemedButton(MidX + 5, MidCenterY + 10, MidW - 10, 32, "Remover local", Chr(#Icon_Remove))
  GadgetToolTip(G_RemoveLocalButton, "Remover local")
  Protected G_RemoveDiskButton  = ThemedButton(MidX + 5, MidCenterY + 50, MidW - 10, 32, "Remover disco", Chr(#Icon_Remove))
  GadgetToolTip(G_RemoveDiskButton, "Remover disco")

  Protected G_DiskList = ListIconGadget(#PB_Any, RightX, PanelY, RightW, PanelH, "Nome", 150,
                                        #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines | #PB_ListIcon_MultiSelect)
  AddGadgetColumn(G_DiskList, 1, "Tamanho", 90)
  AddGadgetColumn(G_DiskList, 2, "Data", 100)

  Protected G_Status = TextGadget(#PB_Any, 24, PanelY + PanelH + 16, WinW - 48, 40,
                                  "Use '...' para escolher um disco existente ou criar um novo.")

  Protected ButtonY = WinH - 56
  Protected G_Save      = ThemedButton(272, ButtonY, 100, 32, "Salvar", Chr(#Icon_Save))
  GadgetToolTip(G_Save, "Salvar")
  Protected G_SaveAs    = ThemedButton(384, ButtonY, 130, 32, "Salvar como...", Chr(#Icon_SaveAs))
  GadgetToolTip(G_SaveAs, "Salvar como...")
  Protected G_Duplicate = ThemedButton(526, ButtonY, 110, 32, "Duplicar...", "")
  Protected G_DeleteDisk = ThemedButton(648, ButtonY, 140, 32, "Excluir disco...", "")
  Protected G_Cancel    = ThemedButton(800, ButtonY, 132, 32, "Cancelar", "")

  Protected NewList LeftEntries.DiskMgrEntry()
  Protected LeftDir.s = DiskMgr_EnsureTrailingSep(GetCurrentDirectory())
  DiskMgr_LoadLocalDir(LeftDir, LeftEntries())
  DiskMgr_FillLocalListIcon(G_LeftList, LeftEntries())
  SetGadgetText(G_LeftPathText, LeftDir)

  Protected TargetPath.s = InitialPath, TempPath.s = "", DiskReady.b = #False
  DiskMgr_SetSessionButtonsEnabled(#False, G_AddButton, G_ExtractButton, G_RemoveDiskButton, G_Save, G_SaveAs, G_Duplicate, G_DeleteDisk)

  Protected Event, Quit = #False, i, Sel

  Repeat
    Event = WaitWindowEvent()
    Select Event

      Case #PB_Event_Gadget
        Select EventGadget()

          Case G_Browse
            Protected Confirmed.b = #True
            If DiskReady
              Confirmed = Bool(MessageRequester("Trocar de disco",
                                "Trocar de disco descarta as alteracoes desta sessao" + Chr(10) +
                                "(o arquivo " + TargetPath + " ainda nao foi salvo)." + Chr(10) + Chr(10) +
                                "Continuar mesmo assim?",
                                #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
            EndIf

            If Confirmed
              Protected Picked.s = OpenFileRequester("Escolher ou criar disco MSX", TargetPath, #File_Pattern_Disk, 0)
              If Picked <> ""
                If DiskReady
                  MSXDisk::CloseDisk()
                  DeleteFile(TempPath)
                  DiskReady = #False
                EndIf

                TargetPath = Picked
                TempPath = DiskMgr_NewTempPath()
                SetGadgetText(G_DiskPathText, TargetPath)

                Protected OpenOk.b
                If FileSize(TargetPath) >= 0
                  CopyFile(TargetPath, TempPath)
                  OpenOk = MSXDisk::OpenDisk(TempPath)
                Else
                  OpenOk = MSXDisk::CreateDisk(TempPath)
                EndIf

                If OpenOk
                  DiskReady = #True
                  DiskMgr_RefreshDiskGadget(G_DiskList)
                  DiskMgr_SetSessionButtonsEnabled(#True, G_AddButton, G_ExtractButton, G_RemoveDiskButton, G_Save, G_SaveAs, G_Duplicate, G_DeleteDisk)
                  SetGadgetText(G_DiskStatusText, "Disco (rascunho, nao salvo ainda)")
                  SetGadgetText(G_Status, "Pronto. Use 'Adicionar >>'/'<< Extrair' e depois 'Salvar' para gravar em " + TargetPath)
                Else
                  MessageRequester("Erro", "Nao foi possivel abrir/criar o disco:" + Chr(10) + MSXDisk::GetLastErrorMessage(),
                                    #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
                  DeleteFile(TempPath)
                  TargetPath = ""
                  TempPath = ""
                  SetGadgetText(G_DiskPathText, "")
                EndIf
              EndIf
            EndIf

          Case G_LeftList
            If EventType() = #PB_EventType_LeftDoubleClick
              Sel = GetGadgetState(G_LeftList)
              If Sel >= 0
                SelectElement(LeftEntries(), Sel)
                If LeftEntries()\Name = ".."
                  LeftDir = DiskMgr_ParentDir(LeftDir)
                  DiskMgr_LoadLocalDir(LeftDir, LeftEntries())
                  DiskMgr_FillLocalListIcon(G_LeftList, LeftEntries())
                  SetGadgetText(G_LeftPathText, LeftDir)
                ElseIf LeftEntries()\IsDir
                  LeftDir = DiskMgr_EnsureTrailingSep(LeftDir + LeftEntries()\Name)
                  DiskMgr_LoadLocalDir(LeftDir, LeftEntries())
                  DiskMgr_FillLocalListIcon(G_LeftList, LeftEntries())
                  SetGadgetText(G_LeftPathText, LeftDir)
                EndIf
              EndIf
            EndIf

          Case G_AddButton
            If Not DiskReady
              MessageRequester("Nenhum disco", "Escolha ou crie um disco primeiro (botao '...').", #PB_MessageRequester_Ok)
            Else
              Protected AnyAdded.b = #False
              For i = 0 To CountGadgetItems(G_LeftList) - 1
                If GetGadgetItemState(G_LeftList, i) & #PB_ListIcon_Selected
                  SelectElement(LeftEntries(), i)
                  If LeftEntries()\Name <> ".." And Not LeftEntries()\IsDir
                    If MSXDisk::AddFile(LeftDir + LeftEntries()\Name, "")
                      AnyAdded = #True
                    Else
                      MessageRequester("Erro ao adicionar", LeftEntries()\Name + ":" + Chr(10) + MSXDisk::GetLastErrorMessage(),
                                        #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
                    EndIf
                  EndIf
                EndIf
              Next
              If AnyAdded
                DiskMgr_RefreshDiskGadget(G_DiskList)
                SetGadgetText(G_DiskStatusText, "Disco (rascunho, nao salvo ainda)")
              EndIf
            EndIf

          Case G_ExtractButton
            If Not DiskReady
              MessageRequester("Nenhum disco", "Escolha ou crie um disco primeiro (botao '...').", #PB_MessageRequester_Ok)
            Else
              Protected AnyExtracted.b = #False
              NewList ExtractFiles.MSXDisk::FileInfo()
              MSXDisk::ListFiles(ExtractFiles())
              For i = 0 To CountGadgetItems(G_DiskList) - 1
                If GetGadgetItemState(G_DiskList, i) & #PB_ListIcon_Selected
                  SelectElement(ExtractFiles(), i)
                  If MSXDisk::ExtractFile(ExtractFiles()\FileName, LeftDir + ExtractFiles()\FileName)
                    AnyExtracted = #True
                  Else
                    MessageRequester("Erro ao extrair", ExtractFiles()\FileName + ":" + Chr(10) + MSXDisk::GetLastErrorMessage(),
                                      #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
                  EndIf
                EndIf
              Next
              If AnyExtracted
                DiskMgr_LoadLocalDir(LeftDir, LeftEntries())
                DiskMgr_FillLocalListIcon(G_LeftList, LeftEntries())
              EndIf
            EndIf

          Case G_RemoveLocalButton
            Protected NewList RemoveLocalNames.s()
            For i = 0 To CountGadgetItems(G_LeftList) - 1
              If GetGadgetItemState(G_LeftList, i) & #PB_ListIcon_Selected
                SelectElement(LeftEntries(), i)
                If LeftEntries()\Name <> ".." And Not LeftEntries()\IsDir
                  AddElement(RemoveLocalNames())
                  RemoveLocalNames() = LeftEntries()\Name
                EndIf
              EndIf
            Next
            If ListSize(RemoveLocalNames()) = 0
              MessageRequester("Nada selecionado", "Selecione um ou mais arquivos no painel esquerdo.", #PB_MessageRequester_Ok)
            Else
              Protected RemoveLocalMsg.s = "Excluir definitivamente " + Str(ListSize(RemoveLocalNames())) +
                                           " arquivo(s) de:" + Chr(10) + LeftDir + Chr(10) + Chr(10) +
                                           "Esta acao nao pode ser desfeita."
              If MessageRequester("Remover arquivo local", RemoveLocalMsg,
                                  #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes
                ForEach RemoveLocalNames()
                  If Not DeleteFile(LeftDir + RemoveLocalNames())
                    MessageRequester("Erro ao remover", RemoveLocalNames() + ": nao foi possivel excluir.",
                                      #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
                  EndIf
                Next
                DiskMgr_LoadLocalDir(LeftDir, LeftEntries())
                DiskMgr_FillLocalListIcon(G_LeftList, LeftEntries())
              EndIf
            EndIf

          Case G_RemoveDiskButton
            If Not DiskReady
              MessageRequester("Nenhum disco", "Escolha ou crie um disco primeiro (botao '...').", #PB_MessageRequester_Ok)
            Else
              Protected NewList RemoveDiskNames.s()
              NewList RemoveDiskFiles.MSXDisk::FileInfo()
              MSXDisk::ListFiles(RemoveDiskFiles())
              For i = 0 To CountGadgetItems(G_DiskList) - 1
                If GetGadgetItemState(G_DiskList, i) & #PB_ListIcon_Selected
                  SelectElement(RemoveDiskFiles(), i)
                  AddElement(RemoveDiskNames())
                  RemoveDiskNames() = RemoveDiskFiles()\FileName
                EndIf
              Next
              If ListSize(RemoveDiskNames()) = 0
                MessageRequester("Nada selecionado", "Selecione um ou mais arquivos no painel do disco.", #PB_MessageRequester_Ok)
              Else
                Protected RemoveDiskMsg.s = "Excluir definitivamente " + Str(ListSize(RemoveDiskNames())) +
                                            " arquivo(s) do disco (rascunho)." + Chr(10) + Chr(10) +
                                            "Esta acao nao pode ser desfeita (mas o disco original so e" + Chr(10) +
                                            "alterado de verdade se depois voce clicar Salvar)."
                If MessageRequester("Remover arquivo do disco", RemoveDiskMsg,
                                    #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes
                  Protected AnyRemoved.b = #False
                  ForEach RemoveDiskNames()
                    If MSXDisk::DeleteMSXFile(RemoveDiskNames())
                      AnyRemoved = #True
                    Else
                      MessageRequester("Erro ao remover", RemoveDiskNames() + ":" + Chr(10) + MSXDisk::GetLastErrorMessage(),
                                        #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
                    EndIf
                  Next
                  If AnyRemoved
                    DiskMgr_RefreshDiskGadget(G_DiskList)
                    SetGadgetText(G_DiskStatusText, "Disco (rascunho, nao salvo ainda)")
                  EndIf
                EndIf
              EndIf
            EndIf

          Case G_Save
            If DiskReady
              MSXDisk::CloseDisk()
              If CopyFile(TempPath, TargetPath)
                DeleteFile(TempPath)
                Quit = #True
              Else
                MessageRequester("Erro ao salvar", "Nao foi possivel gravar em:" + Chr(10) + TargetPath,
                                  #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
                MSXDisk::OpenDisk(TempPath)
              EndIf
            EndIf

          Case G_SaveAs
            If DiskReady
              Protected SaveAsPath.s = SaveFileRequester("Salvar disco como...", GetPathPart(TargetPath), #File_Pattern_Disk, 0)
              If SaveAsPath <> ""
                MSXDisk::CloseDisk()
                If CopyFile(TempPath, SaveAsPath)
                  DeleteFile(TempPath)
                  Quit = #True
                Else
                  MessageRequester("Erro ao salvar", "Nao foi possivel gravar em:" + Chr(10) + SaveAsPath,
                                    #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
                  MSXDisk::OpenDisk(TempPath)
                EndIf
              EndIf
            EndIf

          Case G_Duplicate
            If DiskReady
              Protected DupPath.s = SaveFileRequester("Duplicar disco como...", GetPathPart(TargetPath), #File_Pattern_Disk, 0)
              If DupPath <> ""
                MSXDisk::CloseDisk()
                If CopyFile(TempPath, DupPath)
                  MessageRequester("Duplicado", "Copia salva em:" + Chr(10) + DupPath, #PB_MessageRequester_Ok)
                Else
                  MessageRequester("Erro", "Falha ao copiar para:" + Chr(10) + DupPath,
                                    #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
                EndIf
                MSXDisk::OpenDisk(TempPath)
                DiskMgr_RefreshDiskGadget(G_DiskList)
              EndIf
            EndIf

          Case G_DeleteDisk
            If TargetPath <> ""
              If MessageRequester("Excluir disco",
                                  "Excluir definitivamente o disco:" + Chr(10) + TargetPath + Chr(10) + Chr(10) +
                                  "Esta acao nao pode ser desfeita.",
                                  #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes
                If DiskReady
                  MSXDisk::CloseDisk()
                  DiskReady = #False
                EndIf
                DeleteFile(TempPath)
                If FileSize(TargetPath) >= 0
                  DeleteFile(TargetPath)
                EndIf
                TargetPath = ""
                TempPath = ""
                SetGadgetText(G_DiskPathText, "")
                SetGadgetText(G_DiskStatusText, "Nenhum disco selecionado")
                SetGadgetText(G_Status, "Disco excluido. Use '...' para escolher ou criar outro.")
                ClearGadgetItems(G_DiskList)
                DiskMgr_SetSessionButtonsEnabled(#False, G_AddButton, G_ExtractButton, G_RemoveDiskButton, G_Save, G_SaveAs, G_Duplicate, G_DeleteDisk)
              EndIf
            EndIf

          Case G_Cancel
            Quit = #True
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  If DiskReady
    MSXDisk::CloseDisk()
  EndIf
  If TempPath <> "" And FileSize(TempPath) >= 0
    DeleteFile(TempPath)
  EndIf

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
