;
; ------------------------------------------------------------
;  Z80SubProjectGui.pbi - Criar -> Assembly Sub Project...: janela do
;  "subprojeto de Assembly" (motor sem GUI em Z80SubProject.pbi) - um
;  Makefile primitivo onde o usuario junta varios .asm (montados em .REL na
;  hora do build) mais bibliotecas (.REQUEST) numa unica lista com ORDEM, e
;  manda montar tudo de uma vez num binario final. Mesmo padrao de barra de
;  projeto (numero/tag/navegacao/Novo/Registrar) dos demais editores
;  registrados no `.msxproject` (Sprite/Alfabeto/Som/Musica/Tela) - aqui o
;  "conteudo" e so a lista ordenada de caminhos, nao um asset editavel.
; ------------------------------------------------------------
;

; Troca de posicao os elementos IndexA/IndexB (0-based) de Paths() - helper
; generico reaproveitado tanto pra lista de .asm quanto pra lista de .lib
; (Subir/Descer).
Procedure Z80SubProjGui_ListSwap(List Paths.s(), IndexA.i, IndexB.i)
  If SelectElement(Paths(), IndexA)
    Protected TmpA.s = Paths()
    If SelectElement(Paths(), IndexB)
      Protected TmpB.s = Paths()
      Paths() = TmpA
      SelectElement(Paths(), IndexA)
      Paths() = TmpB
    EndIf
  EndIf
EndProcedure

; Carrega o subprojeto Number pra dentro da UI (listas + tag + numero) - usa
; Z80LinkGui_Refresh() (Z80LinkGui.pbi, generico) pras duas listas.
Procedure.i Z80SubProjGui_Load(Number.i, List AsmFiles.s(), List LibFiles.s(), G_AsmList, G_LibList, G_Tag, G_NumberText)
  If Not ProjectDB::FetchAsmSubProject(Number, AsmFiles(), LibFiles())
    ProcedureReturn #False
  EndIf
  Z80LinkGui_Refresh(G_AsmList, AsmFiles())
  Z80LinkGui_Refresh(G_LibList, LibFiles())
  SetGadgetText(G_Tag, ProjectDB::LastAsmSubProjectTag())
  SetGadgetText(G_NumberText, "#" + Str(Number))
  ProcedureReturn #True
EndProcedure

Procedure.b Z80SubProjGui_ConfirmDiscard()
  ProcedureReturn Bool(MessageRequester("Subprojeto nao registrado",
                        "As alteracoes deste subprojeto ainda nao foram registradas." + Chr(10) +
                        "Descartar mesmo assim?",
                        #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
EndProcedure

Procedure Z80SubProjectGui_OpenWindow(ParentWindow)
  Protected WinW = 760, WinH = 560
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Subprojeto de Assembly",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  ; --- Barra de projeto (mesmo padrao de Psg/Mml/Screen2EditorGui.pbi) ---
  Protected Cx = 15
  TextGadget(#PB_Any, Cx, 16, 90, 20, "Subprojeto:")
  Cx + 90 + 4
  Protected G_NumberText = TextGadget(#PB_Any, Cx, 16, 40, 20, "#1")
  Cx + 40 + 10

  Protected G_First = ThemedButton(Cx, 12, 28, 26, Chr(9198), "")
  GadgetToolTip(G_First, "Primeiro subprojeto")
  Cx + 28 + 2
  Protected G_Prev = ThemedButton(Cx, 12, 28, 26, Chr(9664), "")
  GadgetToolTip(G_Prev, "Subprojeto anterior")
  Cx + 28 + 2
  Protected G_Next = ThemedButton(Cx, 12, 28, 26, Chr(9654), "")
  GadgetToolTip(G_Next, "Proximo subprojeto")
  Cx + 28 + 2
  Protected G_Last = ThemedButton(Cx, 12, 28, 26, Chr(9197), "")
  GadgetToolTip(G_Last, "Ultimo subprojeto")
  Cx + 28 + 16

  TextGadget(#PB_Any, Cx, 16, 32, 20, "Tag:")
  Cx + 32 + 4
  Protected G_Tag = StringGadget(#PB_Any, Cx, 14, 150, 22, "")
  GadgetToolTip(G_Tag, "Nome curto pra identificar o subprojeto (ate 16 caracteres)")
  Cx + 150 + 16

  Protected NewIcon = SpriteEd_CreateNewSpriteIcon(22)
  Protected G_New = ButtonImageGadget(#PB_Any, Cx, 12, 34, 26, ImageID(NewIcon))
  GadgetToolTip(G_New, "Novo subprojeto (numera automaticamente)")
  Cx + 34 + 6

  Protected RegisterIcon = SpriteEd_CreateRegisterIcon(22)
  Protected G_Register = ButtonImageGadget(#PB_Any, Cx, 12, 34, 26, ImageID(RegisterIcon))
  GadgetToolTip(G_Register, "Registrar: grava este subprojeto no banco do projeto")

  ; --- Lista de .ASM (esquerda) ---
  ; Barra de projeto acima fica no padrao compacto de toolbar (igual aos
  ; demais editores Sprite/Alfabeto/Som/Musica/Tela) - so o conteudo abaixo
  ; dela ganha a margem/respiro de 24px dos dialogos de formulario.
  Protected ListY = 64, ListH = 260
  Protected AsmX = 24, AsmW = 400
  TextGadget(#PB_Any, AsmX, ListY, AsmW, 20, "Arquivos .ASM (ordem de link):")
  Protected G_AsmList = ListIconGadget(#PB_Any, AsmX, ListY + 22, AsmW, ListH, "Arquivo", AsmW - 20,
                                       #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines | #PB_ListIcon_MultiSelect)

  Protected AsmBtnY = ListY + 22 + ListH + 10
  Protected G_AsmAdd    = ThemedButton(AsmX, AsmBtnY, 95, 26, "Adicionar...", Chr(#Icon_Add))
  GadgetToolTip(G_AsmAdd, "Adicionar...")
  Protected G_AsmRemove = ThemedButton(AsmX + 100, AsmBtnY, 95, 26, "Remover", "")
  Protected G_AsmUp     = ThemedButton(AsmX + 200, AsmBtnY, 95, 26, "Subir", Chr(#Icon_ArrowUp))
  GadgetToolTip(G_AsmUp, "Subir")
  Protected G_AsmDown   = ThemedButton(AsmX + 300, AsmBtnY, 95, 26, "Descer", Chr(#Icon_ArrowDown))
  GadgetToolTip(G_AsmDown, "Descer")

  Protected G_GenLib = ThemedButton(AsmX, AsmBtnY + 32, AsmW, 28, "Gerar biblioteca a partir dos .ASM selecionados...", Chr(#Icon_Hammer))
  GadgetToolTip(G_GenLib, "Sem nada marcado na lista acima, usa TODOS os .asm do subprojeto")

  ; --- Lista de bibliotecas (direita) ---
  Protected LibX = AsmX + AsmW + 24, LibW = WinW - LibX - 24
  TextGadget(#PB_Any, LibX, ListY, LibW, 20, "Bibliotecas (.REQUEST):")
  Protected G_LibList = ListIconGadget(#PB_Any, LibX, ListY + 22, LibW, ListH, "Arquivo", LibW - 20,
                                       #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)

  Protected LibBtnY = AsmBtnY
  Protected G_LibAdd    = ThemedButton(LibX, LibBtnY, LibW / 2 - 3, 26, "Adicionar biblioteca...", "")
  Protected G_LibRemove = ThemedButton(LibX + LibW / 2 + 3, LibBtnY, LibW / 2 - 3, 26, "Remover biblioteca", Chr(#Icon_Remove))
  GadgetToolTip(G_LibRemove, "Remover biblioteca")

  TextGadget(#PB_Any, LibX, LibBtnY + 34, LibW, 40,
             "Cada .REQUEST no .asm precisa bater com o nome do arquivo (sem extensao) de uma biblioteca desta lista.")

  ; --- Status + Montar tudo ---
  Protected StatusY = AsmBtnY + 32 + 28 + 20
  Protected G_Status = TextGadget(#PB_Any, 24, StatusY, WinW - 48, 40, "")

  Protected ButtonY = WinH - 56
  Protected G_Build = ThemedButton(24, ButtonY, 220, 32, "Montar tudo (Build)...", Chr(#Icon_Hammer))
  GadgetToolTip(G_Build, "Montar tudo (Build)...")
  Protected G_Close = ThemedButton(WinW - 24 - 110, ButtonY, 110, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  ; --- Estado ---
  Protected SubProjNumber.i = 1
  Protected SubProjDirty.b = #False
  Protected NewList AsmFiles.s()
  Protected NewList LibFiles.s()

  Protected NewList Nav.i()
  ProjectDB::ListAsmSubProjectNumbers(Nav())
  If ListSize(Nav()) > 0
    FirstElement(Nav())
    SubProjNumber = Nav()
    Z80SubProjGui_Load(SubProjNumber, AsmFiles(), LibFiles(), G_AsmList, G_LibList, G_Tag, G_NumberText)
  Else
    SetGadgetText(G_NumberText, "#1")
  EndIf

  Protected Event, Quit = #False, Sel, NavTarget
  Protected PickedFile.s, Pick.s
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()

          Case G_Tag
            If EventType() = #PB_EventType_Change
              If Len(GetGadgetText(G_Tag)) > 16
                SetGadgetText(G_Tag, Left(GetGadgetText(G_Tag), 16))
              EndIf
              SubProjDirty = #True
            EndIf

          Case G_AsmAdd
            PickedFile = OpenFileRequester("Adicionar .ASM", "",
                                           "Assembly Z80 (*.asm;*.z80;*.mac)|*.asm;*.z80;*.mac|Todos os arquivos (*.*)|*.*", 0,
                                           #PB_Requester_MultiSelection)
            If PickedFile <> ""
              Repeat
                AddElement(AsmFiles())
                AsmFiles() = PickedFile
                PickedFile = NextSelectedFileName()
              Until PickedFile = ""
              Z80LinkGui_Refresh(G_AsmList, AsmFiles())
              SubProjDirty = #True
            EndIf

          Case G_AsmRemove
            Sel = GetGadgetState(G_AsmList)
            If Sel >= 0 And SelectElement(AsmFiles(), Sel)
              DeleteElement(AsmFiles())
              Z80LinkGui_Refresh(G_AsmList, AsmFiles())
              SubProjDirty = #True
            EndIf

          Case G_AsmUp
            Sel = GetGadgetState(G_AsmList)
            If Sel > 0
              Z80SubProjGui_ListSwap(AsmFiles(), Sel, Sel - 1)
              Z80LinkGui_Refresh(G_AsmList, AsmFiles())
              SetGadgetState(G_AsmList, Sel - 1)
              SubProjDirty = #True
            EndIf

          Case G_AsmDown
            Sel = GetGadgetState(G_AsmList)
            If Sel >= 0 And Sel < ListSize(AsmFiles()) - 1
              Z80SubProjGui_ListSwap(AsmFiles(), Sel, Sel + 1)
              Z80LinkGui_Refresh(G_AsmList, AsmFiles())
              SetGadgetState(G_AsmList, Sel + 1)
              SubProjDirty = #True
            EndIf

          Case G_LibAdd
            PickedFile = OpenFileRequester("Adicionar biblioteca", "",
                                           "Biblioteca/objeto Z80 (*.rel;*.lib)|*.rel;*.lib|Todos os arquivos (*.*)|*.*", 0,
                                           #PB_Requester_MultiSelection)
            If PickedFile <> ""
              Repeat
                AddElement(LibFiles())
                LibFiles() = PickedFile
                PickedFile = NextSelectedFileName()
              Until PickedFile = ""
              Z80LinkGui_Refresh(G_LibList, LibFiles())
              SubProjDirty = #True
            EndIf

          Case G_LibRemove
            Sel = GetGadgetState(G_LibList)
            If Sel >= 0 And SelectElement(LibFiles(), Sel)
              DeleteElement(LibFiles())
              Z80LinkGui_Refresh(G_LibList, LibFiles())
              SubProjDirty = #True
            EndIf

          Case G_GenLib
            Protected NewList SelectedAsm.s()
            Protected i
            For i = 0 To CountGadgetItems(G_AsmList) - 1
              If GetGadgetItemState(G_AsmList, i) & #PB_ListIcon_Selected
                If SelectElement(AsmFiles(), i)
                  AddElement(SelectedAsm())
                  SelectedAsm() = AsmFiles()
                EndIf
              EndIf
            Next
            If ListSize(SelectedAsm()) = 0
              ; Nada marcado - usa a lista inteira do subprojeto.
              CopyList(AsmFiles(), SelectedAsm())
            EndIf

            If ListSize(SelectedAsm()) = 0
              SetGadgetText(G_Status, "Adicione arquivos .asm ao subprojeto antes de gerar uma biblioteca.")
            Else
              Pick = SaveFileRequester("Gerar/acrescentar biblioteca", "",
                                       "Biblioteca Z80 (*.rel)|*.rel|Todos os arquivos (*.*)|*.*", 0)
              If Pick <> ""
                If Z80SubProj_BuildLibraryFromAsm(SelectedAsm(), Pick)
                  SetGadgetText(G_Status, Str(ListSize(SelectedAsm())) + " programa(s) empacotado(s) em " + Pick)
                  If MessageRequester("Biblioteca gerada",
                                      "Adicionar " + GetFilePart(Pick) + " a lista de bibliotecas deste subprojeto?",
                                      #PB_MessageRequester_YesNo | #PB_MessageRequester_Info) = #PB_MessageRequester_Yes
                    AddElement(LibFiles())
                    LibFiles() = Pick
                    Z80LinkGui_Refresh(G_LibList, LibFiles())
                    SubProjDirty = #True
                  EndIf
                Else
                  SetGadgetText(G_Status, "Erro: " + Z80SubProj_GetLastError())
                EndIf
              EndIf
            EndIf

          Case G_Build
            If ListSize(AsmFiles()) = 0
              SetGadgetText(G_Status, "Adicione pelo menos um arquivo .asm antes de montar.")
            Else
              Protected Dim OutBytes.a(65535)
              Protected N = Z80SubProj_Build(AsmFiles(), LibFiles(), OutBytes())
              If N < 0
                SetGadgetText(G_Status, "Erro: " + Z80SubProj_GetLastError())
              ElseIf N = 0
                SetGadgetText(G_Status, "Nada foi gerado.")
              Else
                Protected StartAddr.u = Z80SubProj_GetBuildStartAddr()
                Protected EndAddr.u = Z80SubProj_GetBuildEndAddr()
                Protected Tag.s = GetGadgetText(G_Tag)
                Protected BaseName.s = "subprojeto" + Str(SubProjNumber)
                If Tag <> ""
                  BaseName = Tag
                EndIf
                Protected SourceKey.s = "SUBPROJ|" + Str(SubProjNumber)
                SetGadgetText(G_Status, Str(N) + " bytes montados, endereco " +
                             Hex(StartAddr, #PB_Word) + "h-" + Hex(EndAddr, #PB_Word) + "h.")
                Z80Out_ChooseAndExport(BaseName, OutBytes(), N, StartAddr, EndAddr, SourceKey, "SUBPROJECT", Win)
              EndIf
            EndIf

          Case G_First
            If Not SubProjDirty Or Z80SubProjGui_ConfirmDiscard()
              ProjectDB::ListAsmSubProjectNumbers(Nav())
              NavTarget = SpriteEd_FindNavTarget(Nav(), 0, SubProjNumber)
              If NavTarget >= 0 And Z80SubProjGui_Load(NavTarget, AsmFiles(), LibFiles(), G_AsmList, G_LibList, G_Tag, G_NumberText)
                SubProjNumber = NavTarget : SubProjDirty = #False
                SetGadgetText(G_Status, "Subprojeto #" + Str(SubProjNumber) + " carregado.")
              EndIf
            EndIf

          Case G_Prev
            If Not SubProjDirty Or Z80SubProjGui_ConfirmDiscard()
              ProjectDB::ListAsmSubProjectNumbers(Nav())
              NavTarget = SpriteEd_FindNavTarget(Nav(), 1, SubProjNumber)
              If NavTarget >= 0 And Z80SubProjGui_Load(NavTarget, AsmFiles(), LibFiles(), G_AsmList, G_LibList, G_Tag, G_NumberText)
                SubProjNumber = NavTarget : SubProjDirty = #False
                SetGadgetText(G_Status, "Subprojeto #" + Str(SubProjNumber) + " carregado.")
              EndIf
            EndIf

          Case G_Next
            If Not SubProjDirty Or Z80SubProjGui_ConfirmDiscard()
              ProjectDB::ListAsmSubProjectNumbers(Nav())
              NavTarget = SpriteEd_FindNavTarget(Nav(), 2, SubProjNumber)
              If NavTarget >= 0 And Z80SubProjGui_Load(NavTarget, AsmFiles(), LibFiles(), G_AsmList, G_LibList, G_Tag, G_NumberText)
                SubProjNumber = NavTarget : SubProjDirty = #False
                SetGadgetText(G_Status, "Subprojeto #" + Str(SubProjNumber) + " carregado.")
              EndIf
            EndIf

          Case G_Last
            If Not SubProjDirty Or Z80SubProjGui_ConfirmDiscard()
              ProjectDB::ListAsmSubProjectNumbers(Nav())
              NavTarget = SpriteEd_FindNavTarget(Nav(), 3, SubProjNumber)
              If NavTarget >= 0 And Z80SubProjGui_Load(NavTarget, AsmFiles(), LibFiles(), G_AsmList, G_LibList, G_Tag, G_NumberText)
                SubProjNumber = NavTarget : SubProjDirty = #False
                SetGadgetText(G_Status, "Subprojeto #" + Str(SubProjNumber) + " carregado.")
              EndIf
            EndIf

          Case G_New
            If Not SubProjDirty Or Z80SubProjGui_ConfirmDiscard()
              ProjectDB::ListAsmSubProjectNumbers(Nav())
              Protected NextNumber.i = 1
              If ListSize(Nav()) > 0
                LastElement(Nav())
                NextNumber = Nav() + 1
              EndIf
              SubProjNumber = NextNumber
              ClearList(AsmFiles())
              ClearList(LibFiles())
              SetGadgetText(G_Tag, "")
              SetGadgetText(G_NumberText, "#" + Str(SubProjNumber))
              Z80LinkGui_Refresh(G_AsmList, AsmFiles())
              Z80LinkGui_Refresh(G_LibList, LibFiles())
              SubProjDirty = #False
              SetGadgetText(G_Status, "Novo subprojeto #" + Str(SubProjNumber) + ".")
            EndIf

          Case G_Register
            Protected RegTag.s = Left(GetGadgetText(G_Tag), 16)
            SetGadgetText(G_Tag, RegTag)
            If ProjectDB::StoreAsmSubProject(SubProjNumber, RegTag, AsmFiles(), LibFiles())
              SubProjDirty = #False
              SetGadgetText(G_Status, "Subprojeto #" + Str(SubProjNumber) + " registrado.")
            Else
              MessageRequester("Erro ao registrar",
                               "Nao foi possivel gravar o subprojeto:" + Chr(10) + ProjectDB::GetLastError(),
                               #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
            EndIf

          Case G_Close
            If Not SubProjDirty Or Z80SubProjGui_ConfirmDiscard()
              Quit = #True
            EndIf

        EndSelect

      Case #PB_Event_CloseWindow
        If Not SubProjDirty Or Z80SubProjGui_ConfirmDiscard()
          Quit = #True
        EndIf

    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
