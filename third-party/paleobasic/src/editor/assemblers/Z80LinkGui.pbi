;
; ------------------------------------------------------------
;  Z80LinkGui.pbi - Executar -> Linkar (.REL) -> binario...: janela do linker
;  Z80 compativel M80/L80 (modulo 2b, motor em editor/Z80Link.pbi). Pega uma
;  lista ORDENADA de .REL (cada um vindo de Executar -> Montar Assembly
;  relocavel (.REL)... por aba, ver AssembleZ80RelFromActiveTab em
;  BadigEditor.pb - a ordem importa, e a mesma ordem de concatenacao de
;  CSEG/DSEG/COMMON que Z80Link::LinkFiles usa) mais uma pasta de biblioteca
;  opcional (resolucao de .REQUEST), linka e manda o binario final pro mesmo
;  escolhedor de saida do assembler absoluto (Z80Out_ChooseAndExport,
;  Z80OutputGui.pbi) - .bin no PC, disco MSX (.dsk) ou listing BASIC.
;  Gerenciar o CONTEUDO de uma biblioteca .LIB (criar/adicionar/remover
;  programa) e uma janela separada - ver Z80LibGui.pbi (Criar -> Biblioteca
;  Z80...).
; ------------------------------------------------------------
;

Procedure Z80LinkGui_Refresh(ListGadget, List Paths.s())
  ClearGadgetItems(ListGadget)
  ForEach Paths()
    AddGadgetItem(ListGadget, -1, Paths())
  Next
EndProcedure

Procedure.s Z80LinkGui_JoinPaths(List Paths.s())
  Protected Result.s = ""
  ForEach Paths()
    If Result <> ""
      Result + "|"
    EndIf
    Result + Paths()
  Next
  ProcedureReturn Result
EndProcedure

Procedure Z80LinkGui_OpenWindow(ParentWindow)
  Protected WinW = 660, WinH = 460
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Linkar (.REL) -> binario",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  TextGadget(#PB_Any, 24, 24, 400, 20, "Arquivos .REL (na ordem de link):")
  Protected G_List = ListIconGadget(#PB_Any, 24, 52, 460, 180, "Arquivo", 450,
                                    #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)

  Protected BtnX = 508
  Protected G_Add    = ThemedButton(BtnX, 52, 130, 28, "Adicionar...", Chr(#Icon_Add))
  GadgetToolTip(G_Add, "Adicionar...")
  Protected G_Remove = ThemedButton(BtnX, 88, 130, 28, "Remover", "")
  Protected G_Up     = ThemedButton(BtnX, 124, 130, 28, "Subir", Chr(#Icon_ArrowUp))
  GadgetToolTip(G_Up, "Subir")
  Protected G_Down   = ThemedButton(BtnX, 160, 130, 28, "Descer", Chr(#Icon_ArrowDown))
  GadgetToolTip(G_Down, "Descer")

  TextGadget(#PB_Any, 24, 258, 380, 20, "Pasta de biblioteca (.REQUEST, opcional):")
  Protected G_LibDir = StringGadget(#PB_Any, 24, 286, 524, 24, "", #PB_String_ReadOnly)
  Protected G_LibBrowse = ThemedButton(556, 286, 80, 24, "...", "")

  Protected G_Status = TextGadget(#PB_Any, 24, 330, WinW - 48, 50, "")

  Protected ButtonY = WinH - 56
  Protected G_LinkBtn = ThemedButton(24, ButtonY, 150, 32, "Linkar...", Chr(#Icon_Link))
  GadgetToolTip(G_LinkBtn, "Linkar...")
  Protected G_Close   = ThemedButton(WinW - 24 - 110, ButtonY, 110, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  Protected NewList RelPaths.s()

  Protected Event, Quit = #False, Sel
  Protected PickedFile.s, TmpA.s, TmpB.s, Pick.s
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()

          Case G_Add
            PickedFile = OpenFileRequester("Adicionar .REL", "",
                                           "Objeto Z80 relocavel (*.rel)|*.rel|Todos os arquivos (*.*)|*.*", 0,
                                           #PB_Requester_MultiSelection)
            If PickedFile <> ""
              Repeat
                AddElement(RelPaths())
                RelPaths() = PickedFile
                PickedFile = NextSelectedFileName()
              Until PickedFile = ""
              Z80LinkGui_Refresh(G_List, RelPaths())
            EndIf

          Case G_Remove
            Sel = GetGadgetState(G_List)
            If Sel >= 0 And SelectElement(RelPaths(), Sel)
              DeleteElement(RelPaths())
              Z80LinkGui_Refresh(G_List, RelPaths())
            EndIf

          Case G_Up
            Sel = GetGadgetState(G_List)
            If Sel > 0 And SelectElement(RelPaths(), Sel)
              TmpA = RelPaths()
              SelectElement(RelPaths(), Sel - 1)
              TmpB = RelPaths()
              RelPaths() = TmpA
              SelectElement(RelPaths(), Sel)
              RelPaths() = TmpB
              Z80LinkGui_Refresh(G_List, RelPaths())
              SetGadgetState(G_List, Sel - 1)
            EndIf

          Case G_Down
            Sel = GetGadgetState(G_List)
            If Sel >= 0 And Sel < ListSize(RelPaths()) - 1 And SelectElement(RelPaths(), Sel)
              TmpA = RelPaths()
              SelectElement(RelPaths(), Sel + 1)
              TmpB = RelPaths()
              RelPaths() = TmpA
              SelectElement(RelPaths(), Sel)
              RelPaths() = TmpB
              Z80LinkGui_Refresh(G_List, RelPaths())
              SetGadgetState(G_List, Sel + 1)
            EndIf

          Case G_LibBrowse
            Pick = PathRequester("Selecione a pasta de bibliotecas (.REQUEST)", GetGadgetText(G_LibDir))
            If Pick <> ""
              SetGadgetText(G_LibDir, Pick)
            EndIf

          Case G_LinkBtn
            If ListSize(RelPaths()) = 0
              SetGadgetText(G_Status, "Adicione pelo menos um arquivo .REL antes de linkar.")
            Else
              Protected Dim OutBytes.a(65535)
              Protected NLink = Z80Link::LinkFiles(RelPaths(), OutBytes(), GetGadgetText(G_LibDir))
              If NLink < 0
                SetGadgetText(G_Status, "Erro: " + Z80Link::GetLastLinkError())
              ElseIf NLink = 0
                SetGadgetText(G_Status, "Nada foi gerado.")
              Else
                Protected StartAddr.u = Z80Link::GetLinkStartAddr()
                Protected EndAddr.u = Z80Link::GetLinkEndAddr()
                Protected SourceKey.s = "LINK|" + Z80LinkGui_JoinPaths(RelPaths())
                SelectElement(RelPaths(), 0)
                Protected BaseName.s = GetPathPart(RelPaths()) + GetFilePart(RelPaths(), #PB_FileSystem_NoExtension) + "_link"
                SetGadgetText(G_Status, Str(NLink) + " bytes linkados, endereco " +
                             Hex(StartAddr, #PB_Word) + "h-" + Hex(EndAddr, #PB_Word) + "h.")
                Z80Out_ChooseAndExport(BaseName, OutBytes(), NLink, StartAddr, EndAddr, SourceKey, "LINK", Win)
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
