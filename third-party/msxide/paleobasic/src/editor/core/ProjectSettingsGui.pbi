;
; ------------------------------------------------------------
;  "Configurar -> Projeto...": permite marcar, por projeto, que Basic
;  Dignified/N80/MSXBAS2ROM usam uma configuracao PROPRIA deste projeto em
;  vez da global (ao lado do .exe, ver BadigSettings.pbi/N80Support.pbi/
;  MsxBas2RomSupport.pbi). Nao reimplementa nenhum campo das 3 telas
;  globais - so guarda um boolean "ligado/desligado" por ferramenta (via
;  ProjectDB::SetInfoValue/GetInfoValue, tabela project_info) e, quando
;  ligado, abre a MESMA janela de sempre (BadigCfg_OpenSettingsWindow/
;  N80Settings_OpenWindow/MsxBas2RomSettings_OpenWindow) apontada pra um
;  arquivo JSON ao lado do .msxproject (ProjectDB::OverrideSettingsPath())
;  em vez do JSON global - ver o parametro OverridePath dessas 3 janelas.
;
;  Consumido em RunDignifiedPreprocessor()/CompileMsxBas2RomFromActiveTab()/
;  AssembleAsmsxFromActiveTab() (BadigEditor.pb) - la que o override de
;  verdade entra em vigor (troca o Global BadigCfg/MsxBas2RomCfg/AsmsxCfg so
;  durante a operacao, com snapshot/restore). N80 ainda nao tem nenhum
;  consumidor (nenhum fluxo de compilacao via N80.exe existe no editor
;  ainda) - a flag fica pronta pra quando existir.
; ------------------------------------------------------------
;

; Precisa de um projeto ja salvo em disco (working_dir real) - "projeto 0"
; temporario nao tem pasta nenhuma pra guardar os JSON por-projeto.
Procedure.b ProjSettings_HasSavedProject()
  ProcedureReturn Bool(ProjectDB::GetWorkingDir() <> "")
EndProcedure

; Uma "pagina" completa (checkbox + status + botao Editar) dentro do
; PanelGadget - repetida 3x (Basic Dignified/N80/MSXBas2Rom), gadgets
; criados direto (sem struct de retorno) porque o loop de eventos abaixo
; trata os 3 conjuntos de botoes de forma identica, so trocando qual
; EnabledKey/OverrideFile/OpenFn usar.
Procedure ProjSettings_CreatePage(PanelWidth.i, Title.s, Description.s, *G_Enable.Integer, *G_Status.Integer, *G_Edit.Integer)
  TextGadget(#PB_Any, 24, 24, PanelWidth - 48, 40, Description)
  *G_Enable\i = CheckBoxGadget(#PB_Any, 24, 76, PanelWidth - 48, 22, "Usar configuracao especifica deste projeto")
  *G_Status\i = TextGadget(#PB_Any, 24, 108, PanelWidth - 48, 20, "")
  *G_Edit\i = ThemedButton(24, 140, 280, 28, "Editar configuracoes deste projeto...", "")
EndProcedure

Procedure ProjSettings_UpdateStatus(G_Status.i, Enabled.b)
  If Enabled
    SetGadgetText(G_Status, "Configuracao especifica deste projeto ATIVA.")
  Else
    SetGadgetText(G_Status, "Usando a configuracao global (Configurar -> ... normal).")
  EndIf
EndProcedure

Procedure ProjSettings_OpenWindow(ParentWindow)
  If Not ProjSettings_HasSavedProject()
    MessageRequester("Configurar - Projeto",
                     "Salve o projeto primeiro (Projeto -> Salvar projeto como...)." + Chr(10) +
                     "A configuracao por projeto fica guardada ao lado do arquivo .msxproject.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
    ProcedureReturn
  EndIf

  Protected WinW = 560, WinH = 280
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Configurar - Projeto",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  Protected Panel = PanelGadget(#PB_Any, 24, 24, WinW - 48, WinH - 88)
  Protected PanelWidth = WinW - 48

  AddGadgetItem(Panel, -1, "Basic Dignified")
  Protected G_BadigEnable, G_BadigStatus, G_BadigEdit
  ProjSettings_CreatePage(PanelWidth, "Basic Dignified",
                         "Opcoes de conversao Dignified -> ASCII (renumeracao, PRINT/THEN/GOTO, tokenizador...) usadas so neste projeto.",
                         @G_BadigEnable, @G_BadigStatus, @G_BadigEdit)

  AddGadgetItem(Panel, -1, "N80")
  Protected G_N80Enable, G_N80Status, G_N80Edit
  ProjSettings_CreatePage(PanelWidth, "N80",
                         "Caminho dos executaveis N80/LinkStor80/LibStor80 usado so neste projeto.",
                         @G_N80Enable, @G_N80Status, @G_N80Edit)

  AddGadgetItem(Panel, -1, "MSXBas2Rom")
  Protected G_MsxBas2RomEnable, G_MsxBas2RomStatus, G_MsxBas2RomEdit
  ProjSettings_CreatePage(PanelWidth, "MSXBas2Rom",
                         "Caminho do msxbas2rom.exe usado so neste projeto (Executar -> Compilar ROM (MSXBas2Rom)...).",
                         @G_MsxBas2RomEnable, @G_MsxBas2RomStatus, @G_MsxBas2RomEdit)

  AddGadgetItem(Panel, -1, "asMSX")
  Protected G_AsmsxEnable, G_AsmsxStatus, G_AsmsxEdit
  ProjSettings_CreatePage(PanelWidth, "asMSX",
                         "Caminho e opcoes do asMSX usados so neste projeto (Executar -> Montar Fonte asMSX...).",
                         @G_AsmsxEnable, @G_AsmsxStatus, @G_AsmsxEdit)

  CloseGadgetList() ; fecha o PanelGadget

  SetGadgetState(G_BadigEnable, Bool(ProjectDB::GetInfoValue("badig_override_enabled") = "1"))
  SetGadgetState(G_N80Enable, Bool(ProjectDB::GetInfoValue("n80_override_enabled") = "1"))
  SetGadgetState(G_MsxBas2RomEnable, Bool(ProjectDB::GetInfoValue("msxbas2rom_override_enabled") = "1"))
  SetGadgetState(G_AsmsxEnable, Bool(ProjectDB::GetInfoValue("asmsx_override_enabled") = "1"))
  Protected InitBadigOn.b = GetGadgetState(G_BadigEnable)
  Protected InitN80On.b = GetGadgetState(G_N80Enable)
  Protected InitMsxOn.b = GetGadgetState(G_MsxBas2RomEnable)
  Protected InitAsmsxOn.b = GetGadgetState(G_AsmsxEnable)
  ProjSettings_UpdateStatus(G_BadigStatus, InitBadigOn)
  ProjSettings_UpdateStatus(G_N80Status, InitN80On)
  ProjSettings_UpdateStatus(G_MsxBas2RomStatus, InitMsxOn)
  ProjSettings_UpdateStatus(G_AsmsxStatus, InitAsmsxOn)
  DisableGadget(G_BadigEdit, Bool(Not InitBadigOn))
  DisableGadget(G_N80Edit, Bool(Not InitN80On))
  DisableGadget(G_MsxBas2RomEdit, Bool(Not InitMsxOn))
  DisableGadget(G_AsmsxEdit, Bool(Not InitAsmsxOn))

  Protected G_Close = ThemedButton(WinW - 24 - 110, WinH - 56, 110, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_BadigEnable
            Protected BadigOn.b = GetGadgetState(G_BadigEnable)
            ProjectDB::SetInfoValue("badig_override_enabled", Str(Bool(BadigOn)))
            ProjSettings_UpdateStatus(G_BadigStatus, BadigOn)
            DisableGadget(G_BadigEdit, Bool(Not BadigOn))

          Case G_N80Enable
            Protected N80On.b = GetGadgetState(G_N80Enable)
            ProjectDB::SetInfoValue("n80_override_enabled", Str(Bool(N80On)))
            ProjSettings_UpdateStatus(G_N80Status, N80On)
            DisableGadget(G_N80Edit, Bool(Not N80On))

          Case G_MsxBas2RomEnable
            Protected MsxOn.b = GetGadgetState(G_MsxBas2RomEnable)
            ProjectDB::SetInfoValue("msxbas2rom_override_enabled", Str(Bool(MsxOn)))
            ProjSettings_UpdateStatus(G_MsxBas2RomStatus, MsxOn)
            DisableGadget(G_MsxBas2RomEdit, Bool(Not MsxOn))

          Case G_AsmsxEnable
            Protected AsmsxOn.b = GetGadgetState(G_AsmsxEnable)
            ProjectDB::SetInfoValue("asmsx_override_enabled", Str(Bool(AsmsxOn)))
            ProjSettings_UpdateStatus(G_AsmsxStatus, AsmsxOn)
            DisableGadget(G_AsmsxEdit, Bool(Not AsmsxOn))

          Case G_BadigEdit
            BadigCfg_OpenSettingsWindow(Win, ProjectDB::OverrideSettingsPath("project_badig_settings.json"))

          Case G_N80Edit
            N80Settings_OpenWindow(Win, ProjectDB::OverrideSettingsPath("project_n80_settings.json"))

          Case G_MsxBas2RomEdit
            MsxBas2RomSettings_OpenWindow(Win, ProjectDB::OverrideSettingsPath("project_msxbas2rom_settings.json"))

          Case G_AsmsxEdit
            AsmsxSettings_OpenWindow(Win, ProjectDB::OverrideSettingsPath("project_asmsx_settings.json"))

          Case G_Close
            Quit = #True
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
