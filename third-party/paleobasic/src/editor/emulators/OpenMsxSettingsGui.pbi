;
; ------------------------------------------------------------
;  OpenMsxSettingsGui.pbi - janela "Configurar -> openMSX...": versao
;  standalone dos MESMOS campos da aba "Emulador" de
;  "Configurar -> Basic Dignified..." (BadigCfg_OpenSettingsWindow, em
;  BadigSettings.pbi). Usa os procedimentos compartilhados de la
;  (BadigCfg_CreateEmulatorGadgets/ApplyEmulatorDefaults/
;  HandleEmulatorGadgetEvent/ApplyEmulatorGadgetsToConfig) pra nunca divergir:
;  as duas telas leem/gravam os mesmos campos BadigCfg\Em*, persistidos no
;  mesmo badig_settings.json (BadigCfg_Save()) e sincronizados de volta no
;  mesmo emulator_interface.ini (BadigCfg_SyncEmulatorIni()). Mantida
;  separada a pedido do usuario (quer as duas telas, nao substituir uma pela
;  outra) - ver o cabecalho de BadigSettings.pbi pro motivo de nao duplicar
;  os campos em vez de compartilhar.
; ------------------------------------------------------------
;

Procedure OpenMsxCfg_OpenSettingsWindow(ParentWindow)
  ; Mesma grade de layout das outras janelas de configuracao (24px de margem
  ; externa). WinW = 680 pra caber os mesmos campos da aba "Emulador"
  ; (512 + 8 + 64 = 584 de conteudo util, mais as margens de 24 dos dois
  ; lados) sem quebrar layout - identico ao WinW de BadigCfg_OpenSettingsWindow().
  Protected WinW = 680, WinH = 760 ; +168 vs. antes - a pagina "Emulador" cresceu (4 slots de extensao)
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Configuracoes do openMSX",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  Protected EmuG.BadigCfg_EmuGadgets
  BadigCfg_CreateEmulatorGadgets(0, @EmuG)
  BadigCfg_ApplyEmulatorDefaults(@EmuG)

  Protected G_Save = ThemedButton(WinW - 256, WinH - 56, 110, 32, "Salvar", Chr(#Icon_Save))
  GadgetToolTip(G_Save, "Salvar")
  Protected G_Cancel = ThemedButton(WinW - 134, WinH - 56, 110, 32, "Cancelar", "")

  Protected Event, Quit = #False, Saved = #False

  Repeat
    Event = WaitWindowEvent()

    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_Save
            Saved = #True
            Quit = #True

          Case G_Cancel
            Quit = #True

          Default
            ; Qualquer um dos 7 botoes "..." desta janela (executavel, setting, script, maquina,
            ; extensao A-D) - ver comentario equivalente em BadigCfg_OpenSettingsWindow()
            ; (BadigSettings.pbi).
            BadigCfg_HandleEmulatorGadgetEvent(Win, EventGadget(), @EmuG)
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  If Saved
    BadigCfg_ApplyEmulatorGadgetsToConfig(@EmuG)
    BadigCfg_Save()
    BadigCfg_SyncEmulatorIni()
  EndIf

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
