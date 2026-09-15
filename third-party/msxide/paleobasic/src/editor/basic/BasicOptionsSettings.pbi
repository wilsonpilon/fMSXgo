;
; ------------------------------------------------------------
;  Opcoes do Basic (auto completar de palavras-chave MSX-BASIC/Dignified e
;  variaveis declaradas no documento ativo). Persistidas em JSON proprio
;  (basic_options_settings.json, ao lado do .exe) - mesmo padrao de
;  EditorSettings.pbi/BadigSettings.pbi.
; ------------------------------------------------------------
;

; AutoCompleteCase controla a caixa das palavras-chave sugeridas (nao afeta
; variaveis - essas sempre aparecem com a grafia que o usuario ja usou no
; documento, mudar isso inseriria uma referencia com caixa diferente da
; declaracao original). Valores: "AsTyped" (acompanha a caixa do que o
; usuario ja digitou - maiusculo digitado sugere maiusculo, minusculo sugere
; minusculo), "Upper", "Lower".
Structure BasicOptionsSettings
  AutoCompleteEnabled.b
  AutoCompleteMinChars.i
  AutoCompleteCase.s
EndStructure

Global BasicOptionsCfg.BasicOptionsSettings

;- ------------------------------------------------------------
;- Valores padrao
;- ------------------------------------------------------------

Procedure BasicOptionsCfg_SetDefaults()
  BasicOptionsCfg\AutoCompleteEnabled  = #True
  BasicOptionsCfg\AutoCompleteMinChars = 3
  BasicOptionsCfg\AutoCompleteCase     = "AsTyped"
EndProcedure

;- ------------------------------------------------------------
;- Persistencia em JSON
;- ------------------------------------------------------------

Procedure.s BasicOptionsCfg_FilePath()
  ProcedureReturn GetPathPart(ProgramFilename()) + "editor\basic_options_settings.json"
EndProcedure

Procedure BasicOptionsCfg_Load()
  BasicOptionsCfg_SetDefaults()

  Protected FilePath.s = BasicOptionsCfg_FilePath()
  If FileSize(FilePath) <= 0
    ProcedureReturn #False
  EndIf

  Protected Json = LoadJSON(#PB_Any, FilePath)
  If Not Json
    ProcedureReturn #False
  EndIf

  Protected Root = JSONValue(Json)
  Protected M

  M = GetJSONMember(Root, "AutoCompleteEnabled")  : If M : BasicOptionsCfg\AutoCompleteEnabled = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "AutoCompleteMinChars") : If M : BasicOptionsCfg\AutoCompleteMinChars = GetJSONInteger(M) : EndIf
  M = GetJSONMember(Root, "AutoCompleteCase")     : If M : BasicOptionsCfg\AutoCompleteCase = GetJSONString(M) : EndIf

  FreeJSON(Json)

  If BasicOptionsCfg\AutoCompleteMinChars < 1
    BasicOptionsCfg\AutoCompleteMinChars = 1
  EndIf
  If BasicOptionsCfg\AutoCompleteCase <> "Upper" And BasicOptionsCfg\AutoCompleteCase <> "Lower" And BasicOptionsCfg\AutoCompleteCase <> "AsTyped"
    BasicOptionsCfg\AutoCompleteCase = "AsTyped"
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure BasicOptionsCfg_Save()
  Protected Json = CreateJSON(#PB_Any)
  Protected Root = SetJSONObject(JSONValue(Json))

  SetJSONBoolean(AddJSONMember(Root, "AutoCompleteEnabled"), BasicOptionsCfg\AutoCompleteEnabled)
  SetJSONInteger(AddJSONMember(Root, "AutoCompleteMinChars"), BasicOptionsCfg\AutoCompleteMinChars)
  SetJSONString(AddJSONMember(Root, "AutoCompleteCase"), BasicOptionsCfg\AutoCompleteCase)

  SaveJSON(Json, BasicOptionsCfg_FilePath(), #PB_JSON_PrettyPrint)
  FreeJSON(Json)
EndProcedure

;- ------------------------------------------------------------
;- Janela de configuracao (Configurar -> Basic Options...)
;- ------------------------------------------------------------

Procedure.b BasicOptionsCfg_OpenSettingsWindow(ParentWindow)
  Protected WinW = 460, WinH = 370
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Basic Options",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn #False
  EndIf

  Protected G_Enabled = CheckBoxGadget(#PB_Any, 24, 24, 412, 24, "Habilitar auto completar")
  SetGadgetState(G_Enabled, BasicOptionsCfg\AutoCompleteEnabled)

  TextGadget(#PB_Any, 24, 72, 300, 20, "Letras digitadas para ativar")
  Protected G_MinChars = StringGadget(#PB_Any, 24, 100, 60, 24, Str(BasicOptionsCfg\AutoCompleteMinChars))

  TextGadget(#PB_Any, 24, 144, 300, 20, "Caixa das palavras-chave sugeridas")
  Protected G_Case = ComboBoxGadget(#PB_Any, 24, 172, 320, 24)
  AddGadgetItem(G_Case, -1, "Como digitado (PRI -> PRINT, pri -> print)")
  AddGadgetItem(G_Case, -1, "Sempre maiusculas (PRINT)")
  AddGadgetItem(G_Case, -1, "Sempre minusculas (print)")
  Select BasicOptionsCfg\AutoCompleteCase
    Case "Upper" : SetGadgetState(G_Case, 1)
    Case "Lower" : SetGadgetState(G_Case, 2)
    Default      : SetGadgetState(G_Case, 0)
  EndSelect

  TextGadget(#PB_Any, 24, 230, 412, 54,
    "Sugere palavras-chave do MSX-BASIC/Basic Dignified e variaveis ja" + Chr(10) +
    "usadas no documento atual (sempre com a grafia original). Enter" + Chr(10) +
    "escolhe a primeira opcao, setas navegam e Esc cancela.")

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
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  If Saved
    BasicOptionsCfg\AutoCompleteEnabled = GetGadgetState(G_Enabled)

    BasicOptionsCfg\AutoCompleteMinChars = Val(GetGadgetText(G_MinChars))
    If BasicOptionsCfg\AutoCompleteMinChars < 1  : BasicOptionsCfg\AutoCompleteMinChars = 1  : EndIf
    If BasicOptionsCfg\AutoCompleteMinChars > 20 : BasicOptionsCfg\AutoCompleteMinChars = 20 : EndIf

    Select GetGadgetState(G_Case)
      Case 1  : BasicOptionsCfg\AutoCompleteCase = "Upper"
      Case 2  : BasicOptionsCfg\AutoCompleteCase = "Lower"
      Default : BasicOptionsCfg\AutoCompleteCase = "AsTyped"
    EndSelect

    BasicOptionsCfg_Save()
  EndIf

  CloseModelessChildWindow(ParentWindow, Win)

  ProcedureReturn Saved
EndProcedure
