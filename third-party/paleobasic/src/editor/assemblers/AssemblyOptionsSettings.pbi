;
; ------------------------------------------------------------
;  Opcoes do Assembly (auto completar de mnemonicos/registradores/diretivas
;  do Z80 e rotulos declarados no documento ativo, modo "ASM" - ver
;  Z80Asm::MnemonicList()/RegisterList()/DirectiveList()/OperatorWordList()
;  em Z80Asm.pbi). Persistidas em JSON proprio (assembly_options_settings.json,
;  ao lado do .exe) - mesmo padrao de BasicOptionsSettings.pbi, mas
;  independente dela (usuario pode querer mnemonicos sempre maiusculos e
;  palavras-chave do Basic sempre minusculas, por exemplo).
; ------------------------------------------------------------
;

; AutoCompleteCase controla a caixa dos mnemonicos/registradores/diretivas
; sugeridos (nao afeta rotulos - esses sempre aparecem com a grafia que o
; usuario ja usou no documento). Valores: "AsTyped", "Upper", "Lower".
Structure AssemblyOptionsSettings
  AutoCompleteEnabled.b
  AutoCompleteMinChars.i
  AutoCompleteCase.s
EndStructure

Global AssemblyOptionsCfg.AssemblyOptionsSettings

;- ------------------------------------------------------------
;- Valores padrao
;- ------------------------------------------------------------

Procedure AssemblyOptionsCfg_SetDefaults()
  AssemblyOptionsCfg\AutoCompleteEnabled  = #True
  AssemblyOptionsCfg\AutoCompleteMinChars = 3
  AssemblyOptionsCfg\AutoCompleteCase     = "AsTyped"
EndProcedure

;- ------------------------------------------------------------
;- Persistencia em JSON
;- ------------------------------------------------------------

Procedure.s AssemblyOptionsCfg_FilePath()
  ProcedureReturn GetPathPart(ProgramFilename()) + "editor\assembly_options_settings.json"
EndProcedure

Procedure AssemblyOptionsCfg_Load()
  AssemblyOptionsCfg_SetDefaults()

  Protected FilePath.s = AssemblyOptionsCfg_FilePath()
  If FileSize(FilePath) <= 0
    ProcedureReturn #False
  EndIf

  Protected Json = LoadJSON(#PB_Any, FilePath)
  If Not Json
    ProcedureReturn #False
  EndIf

  Protected Root = JSONValue(Json)
  Protected M

  M = GetJSONMember(Root, "AutoCompleteEnabled")  : If M : AssemblyOptionsCfg\AutoCompleteEnabled = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "AutoCompleteMinChars") : If M : AssemblyOptionsCfg\AutoCompleteMinChars = GetJSONInteger(M) : EndIf
  M = GetJSONMember(Root, "AutoCompleteCase")     : If M : AssemblyOptionsCfg\AutoCompleteCase = GetJSONString(M) : EndIf

  FreeJSON(Json)

  If AssemblyOptionsCfg\AutoCompleteMinChars < 1
    AssemblyOptionsCfg\AutoCompleteMinChars = 1
  EndIf
  If AssemblyOptionsCfg\AutoCompleteCase <> "Upper" And AssemblyOptionsCfg\AutoCompleteCase <> "Lower" And AssemblyOptionsCfg\AutoCompleteCase <> "AsTyped"
    AssemblyOptionsCfg\AutoCompleteCase = "AsTyped"
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure AssemblyOptionsCfg_Save()
  Protected Json = CreateJSON(#PB_Any)
  Protected Root = SetJSONObject(JSONValue(Json))

  SetJSONBoolean(AddJSONMember(Root, "AutoCompleteEnabled"), AssemblyOptionsCfg\AutoCompleteEnabled)
  SetJSONInteger(AddJSONMember(Root, "AutoCompleteMinChars"), AssemblyOptionsCfg\AutoCompleteMinChars)
  SetJSONString(AddJSONMember(Root, "AutoCompleteCase"), AssemblyOptionsCfg\AutoCompleteCase)

  SaveJSON(Json, AssemblyOptionsCfg_FilePath(), #PB_JSON_PrettyPrint)
  FreeJSON(Json)
EndProcedure

;- ------------------------------------------------------------
;- Janela de configuracao (Configurar -> Assembly...)
;- ------------------------------------------------------------

Procedure.b AssemblyOptionsCfg_OpenSettingsWindow(ParentWindow)
  Protected WinW = 460, WinH = 370
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Assembly Options",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn #False
  EndIf

  Protected G_Enabled = CheckBoxGadget(#PB_Any, 24, 24, 412, 24, "Habilitar auto completar")
  SetGadgetState(G_Enabled, AssemblyOptionsCfg\AutoCompleteEnabled)

  TextGadget(#PB_Any, 24, 72, 300, 20, "Letras digitadas para ativar")
  Protected G_MinChars = StringGadget(#PB_Any, 24, 100, 60, 24, Str(AssemblyOptionsCfg\AutoCompleteMinChars))

  TextGadget(#PB_Any, 24, 144, 300, 20, "Caixa dos mnemonicos/diretivas sugeridos")
  Protected G_Case = ComboBoxGadget(#PB_Any, 24, 172, 320, 24)
  AddGadgetItem(G_Case, -1, "Como digitado (PU -> PUSH, pu -> push)")
  AddGadgetItem(G_Case, -1, "Sempre maiusculas (PUSH)")
  AddGadgetItem(G_Case, -1, "Sempre minusculas (push)")
  Select AssemblyOptionsCfg\AutoCompleteCase
    Case "Upper" : SetGadgetState(G_Case, 1)
    Case "Lower" : SetGadgetState(G_Case, 2)
    Default      : SetGadgetState(G_Case, 0)
  EndSelect

  TextGadget(#PB_Any, 24, 230, 412, 54,
    "Sugere mnemonicos, registradores/condicoes e diretivas do Z80 (dialeto" + Chr(10) +
    "N80/Nestor80) e rotulos ja usados no documento atual (sempre com a" + Chr(10) +
    "grafia original). Enter escolhe a primeira opcao, setas navegam e Esc cancela.")

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
    AssemblyOptionsCfg\AutoCompleteEnabled = GetGadgetState(G_Enabled)

    AssemblyOptionsCfg\AutoCompleteMinChars = Val(GetGadgetText(G_MinChars))
    If AssemblyOptionsCfg\AutoCompleteMinChars < 1  : AssemblyOptionsCfg\AutoCompleteMinChars = 1  : EndIf
    If AssemblyOptionsCfg\AutoCompleteMinChars > 20 : AssemblyOptionsCfg\AutoCompleteMinChars = 20 : EndIf

    Select GetGadgetState(G_Case)
      Case 1  : AssemblyOptionsCfg\AutoCompleteCase = "Upper"
      Case 2  : AssemblyOptionsCfg\AutoCompleteCase = "Lower"
      Default : AssemblyOptionsCfg\AutoCompleteCase = "AsTyped"
    EndSelect

    AssemblyOptionsCfg_Save()
  EndIf

  CloseModelessChildWindow(ParentWindow, Win)

  ProcedureReturn Saved
EndProcedure
