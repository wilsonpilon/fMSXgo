;
; ------------------------------------------------------------
;  Z80LibGui.pbi - Criar -> Biblioteca Z80 (.LIB)...: gerenciador de
;  bibliotecas de objetos relocaveis (modulo 2b, motor em editor/Z80Lib.pbi -
;  DeclareModule Z80Lib, compativel LB80). Uma biblioteca .LIB e uma colecao
;  de programas .REL nomeados - o linker (Executar -> Linkar (.REL) ->
;  binario..., Z80LinkGui.pbi) resolve .REQUEST contra ela, trazendo pro
;  binario final so os programas de dentro que realmente resolvem algum
;  simbolo externo pendente (linkagem estatica seletiva). Segue o mesmo
;  espirito "Criar" do gerenciador de disco (DiskManagerGui.pbi): edita um
;  ATIVO (a biblioteca) independente de qualquer aba de texto aberta -
;  diferente do gerenciador de disco, aqui nao ha rascunho em copia
;  temporaria porque Z80Lib::CreateOrAddLibrary/RemoveProgram ja gravam
;  direto e de forma atomica no arquivo escolhido.
; ------------------------------------------------------------
;

; Recarrega a lista de programas a partir do arquivo em LibPath (Z80Lib::
; ListLibrary) - LibPath = "" (biblioteca "Nova..." ainda sem nenhum
; programa adicionado) ou arquivo inexistente so limpam a lista, sem erro
; (uma .LIB so passa a existir de fato no primeiro "Adicionar .REL...").
Procedure Z80LibGui_Refresh(ListGadget, StatusGadget, LibPath.s)
  ClearGadgetItems(ListGadget)
  If LibPath = "" Or FileSize(LibPath) < 0
    SetGadgetText(StatusGadget, "Biblioteca ainda vazia (sem arquivo) - use 'Adicionar .REL...' para criar.")
    ProcedureReturn
  EndIf

  Protected NewList Programs.Z80Lib::Z80LibProgramInfo()
  If Not Z80Lib::ListLibrary(LibPath, Programs())
    SetGadgetText(StatusGadget, "Erro ao ler a biblioteca: " + Z80Lib::GetLastLibError())
    ProcedureReturn
  EndIf

  ForEach Programs()
    AddGadgetItem(ListGadget, -1, Programs()\Name + Chr(10) + Str(Programs()\SizeBytes) + " bytes" + Chr(10) + Programs()\PublicSymbolsCsv)
  Next
  SetGadgetText(StatusGadget, Str(ListSize(Programs())) + " programa(s) em " + LibPath)
EndProcedure

Procedure Z80LibGui_OpenWindow(ParentWindow)
  Protected WinW = 660, WinH = 470
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Biblioteca Z80 (.LIB)",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  TextGadget(#PB_Any, 24, 24, 80, 20, "Biblioteca:")
  Protected G_LibPathText = StringGadget(#PB_Any, 112, 22, 323, 24, "", #PB_String_ReadOnly)
  Protected G_New  = ThemedButton(443, 21, 90, 28, "Nova...", Chr(#Icon_Add))
  GadgetToolTip(G_New, "Nova...")
  Protected G_Open = ThemedButton(541, 21, 95, 28, "Abrir...", "")

  Protected G_List = ListIconGadget(#PB_Any, 24, 64, WinW - 48, 220, "Programa", 150,
                                    #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  AddGadgetColumn(G_List, 1, "Tamanho", 90)
  AddGadgetColumn(G_List, 2, "Simbolos publicos", WinW - 48 - 150 - 90 - 20)

  Protected G_Status = TextGadget(#PB_Any, 24, 304, WinW - 48, 40, "Use 'Nova...' ou 'Abrir...' para escolher uma biblioteca.")

  Protected G_Add    = ThemedButton(24, 364, 160, 30, "Adicionar .REL...", "")
  Protected G_Remove = ThemedButton(200, 364, 160, 30, "Remover selecionado", Chr(#Icon_Remove))
  GadgetToolTip(G_Remove, "Remover selecionado")

  Protected ButtonY = WinH - 56
  Protected G_Close = ThemedButton(WinW - 24 - 110, ButtonY, 110, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  Protected LibPath.s = ""
  Protected Event, Quit = #False, Sel
  Protected PickedFile.s, ProgName.s
  Protected NewList AddPaths.s()

  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()

          Case G_New
            PickedFile = SaveFileRequester("Nova biblioteca Z80", "",
                                           "Biblioteca Z80 (*.lib)|*.lib|Todos os arquivos (*.*)|*.*", 0)
            If PickedFile <> ""
              PickedFile = EnsureExtension(PickedFile, "lib")
              If FileSize(PickedFile) >= 0
                DeleteFile(PickedFile)
              EndIf
              LibPath = PickedFile
              SetGadgetText(G_LibPathText, LibPath)
              Z80LibGui_Refresh(G_List, G_Status, LibPath)
            EndIf

          Case G_Open
            PickedFile = OpenFileRequester("Abrir biblioteca Z80", "",
                                           "Biblioteca Z80 (*.lib)|*.lib|Todos os arquivos (*.*)|*.*", 0)
            If PickedFile <> ""
              LibPath = PickedFile
              SetGadgetText(G_LibPathText, LibPath)
              Z80LibGui_Refresh(G_List, G_Status, LibPath)
            EndIf

          Case G_Add
            If LibPath = ""
              SetGadgetText(G_Status, "Escolha 'Nova...' ou 'Abrir...' antes de adicionar programas.")
            Else
              PickedFile = OpenFileRequester("Adicionar .REL a biblioteca", "",
                                             "Objeto Z80 relocavel (*.rel)|*.rel|Todos os arquivos (*.*)|*.*", 0,
                                             #PB_Requester_MultiSelection)
              If PickedFile <> ""
                ClearList(AddPaths())
                Repeat
                  AddElement(AddPaths())
                  AddPaths() = PickedFile
                  PickedFile = NextSelectedFileName()
                Until PickedFile = ""

                If Z80Lib::CreateOrAddLibrary(LibPath, AddPaths())
                  Z80LibGui_Refresh(G_List, G_Status, LibPath)
                Else
                  SetGadgetText(G_Status, "Erro: " + Z80Lib::GetLastLibError())
                EndIf
              EndIf
            EndIf

          Case G_Remove
            Sel = GetGadgetState(G_List)
            If LibPath = "" Or Sel < 0
              SetGadgetText(G_Status, "Selecione um programa da lista para remover.")
            Else
              ProgName = GetGadgetItemText(G_List, Sel, 0)
              If Z80Lib::RemoveProgram(LibPath, ProgName)
                Z80LibGui_Refresh(G_List, G_Status, LibPath)
              Else
                SetGadgetText(G_Status, "Erro: " + Z80Lib::GetLastLibError())
              EndIf
            EndIf

          Case G_Close
            Quit = #True

        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True

    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
