;
; ------------------------------------------------------------
;  OpenMSXConsoleGui.pbi - janela do menu "Executar -> openMSX": abre o
;  openMSX com o pipe de comandos ligado (ver OpenMSXBridge.pbi) e da um
;  "mini Catapult" pra controlar essa mesma instancia, organizado em abas:
;
;    - "Console": transferir o programa atual, midia (disco/cartucho/
;      cassete), log + campo de comando livre (qualquer comando TCL que o
;      openMSX aceita via "-control" - "reset", "set pause on",
;      "screenshot", etc. - ver documentacao "External control protocol" do
;      openMSX).
;    - "Outros comandos": velocidade de emulacao (trackbar + 100% + turbo
;      segurando), Power/Reset/Pause, interruptor de firmware residente,
;      conectores das portas de joystick (Nada/Mouse/Teclado como
;      joystick/Paddle) e Ren Sha Turbo.
;    - "Video": renderer/escala/vsync/modo TV, deinterlace/limitar
;      sprites/tela cheia/desabilitar sprites/fonte de video, efeitos estilo
;      CRT (scanlines/blur/glow/gamma/noise, cada um com reset pro padrao),
;      screenshot com nome base + diretorio opcional + numeracao sequencial
;      automatica, LEDs (Power/Caps/Kana/Pause/Turbo/FDD) + botao STOP + FPS.
;    - "Volume": dispositivos de som descobertos dinamicamente (nomes reais
;      variam por cartucho, ver comentario de OMSX_DeviceVolume() em
;      OpenMSXBridge.pbi) + Volume/Balance + MIDI in/out.
;    - "Input Text": area grande de texto + Type/Clear - mesmo mecanismo de
;      "digitar no MSX" que a aba Console ja tinha, so que numa area maior e
;      dedicada.
;    - "Status Info": log passivo de TUDO que o openMSX reporta (mudou por
;      nosso comando ou nao) - mesmo stream do log da aba Console, sem os
;      ecos "> comando" (esses sao especificos da sessao interativa).
;
;  Util tanto durante a edicao (F5 usa a MESMA instancia, ver
;  OMSX_LoadDisk() em OpenMSXBridge.pbi e RunOnOpenMSX() em BadigEditor.pb)
;  quanto sozinho, sem nenhum arquivo aberto.
;
;  Fechar esta janela NAO fecha o openMSX - o processo continua rodando
;  (guardado em OMSX_Prog, ver OpenMSXBridge.pbi). Abrir "Executar ->
;  openMSX" de novo so reconecta uma nova janela a ele, pra dar pra alternar
;  entre editar codigo e mandar comando sem perder a sessao do emulador. Se o
;  usuario fechar o openMSX por fora (ou ele cair), o poll detecta isso e
;  desativa os controles que dependem do pipe.
; ------------------------------------------------------------
;

#OMSXGui_PollTimer = 9000
#OMSXGui_EnterShortcut = 9001

; Acrescenta Text (uma ou mais linhas separadas por Chr(10), "" ignorado) ao final do log,
; convertendo pra CRLF (EditorGadget nativo) e rolando pro fim. Recebe/devolve o texto
; acumulado (Accum) explicitamente, em vez de reler o conteudo atual via GetGadgetText() -
; relato real de uso (2026-07-30): depois de alguns comandos (ex. consultar "set renderer"),
; o log "esvaziava" sozinho e so o texto mais novo continuava aparecendo dali pra frente,
; mesmo o openMSX continuando a responder normalmente por baixo (confirmado nao ser
; travamento do openMSX nem do pipe/protocolo - ver OpenMSXBridge.pbi). Causa exata dentro
; do controle nativo nao identificada, mas manter o acumulado so do nosso lado (nunca
; dependendo do widget "lembrar" o que ja escrevemos) elimina essa classe inteira de bug,
; nao so o sintoma pontual.
Procedure.s OMSXGui_AppendLog(G_Log, Accum.s, Text.s)
  If Text = ""
    ProcedureReturn Accum
  EndIf
  Protected Add.s = ReplaceString(RTrim(Text, Chr(10)), Chr(10), Chr(13) + Chr(10))
  If Add = ""
    ProcedureReturn Accum
  EndIf
  If Accum <> ""
    Accum + Chr(13) + Chr(10)
  EndIf
  Accum + Add
  SetGadgetText(G_Log, Accum)
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    SendMessage_(GadgetID(G_Log), #EM_LINESCROLL, 0, 999999)
  CompilerEndIf
  ProcedureReturn Accum
EndProcedure

; Le o texto do campo de comando, manda pro openMSX e ecoa no log - usado
; tanto pelo botao "Enviar" quanto pelo atalho Enter (#OMSXGui_EnterShortcut).
; Mesmo motivo de OMSXGui_AppendLog() acima: recebe/devolve o acumulado.
Procedure.s OMSXGui_Send(G_Log, G_Input, Accum.s)
  Protected Cmd.s = Trim(GetGadgetText(G_Input))
  If Cmd = ""
    ProcedureReturn Accum
  EndIf
  Accum = OMSXGui_AppendLog(G_Log, Accum, "> " + Cmd)
  OMSX_SendCommand(Cmd)
  SetGadgetText(G_Input, "")
  ProcedureReturn Accum
EndProcedure

; Manda um comando qualquer e ecoa no log - usado por todos os botoes que nao
; sao o campo de comando livre (midia, velocidade, power/reset/pause,
; firmware, joystick, ren sha turbo), ja que OMSX_SendCommand() sozinho nao
; loga nada - so as respostas assincronas aparecem via OMSX_Poll().
Procedure.s OMSXGui_SendLogged(G_Log, Accum.s, Cmd.s)
  Accum = OMSXGui_AppendLog(G_Log, Accum, "> " + Cmd)
  OMSX_SendCommand(Cmd)
  ProcedureReturn Accum
EndProcedure

; Desenha o botao "Turbo" (CanvasGadget, nao ButtonGadget - PRECISA ser um
; Canvas porque ButtonGadget so avisa no CLIQUE completo, sem evento de
; "botao do mouse abaixado" separado do "solto"; um botao de segurar exige
; os dois separados, e CanvasGadget e o unico gadget nativo do PureBasic que
; da #PB_EventType_LeftButtonDown/Up de verdade). Pressed muda a cor de
; fundo, pra dar feedback visual claro de que esta segurando.
Procedure OMSXGui_DrawTurboButton(G_Turbo, Pressed.b)
  If StartDrawing(CanvasOutput(G_Turbo))
    If Pressed
      Box(0, 0, GadgetWidth(G_Turbo), GadgetHeight(G_Turbo), RGB(200, 90, 40))
    Else
      Box(0, 0, GadgetWidth(G_Turbo), GadgetHeight(G_Turbo), RGB(90, 90, 90))
    EndIf
    DrawingMode(#PB_2DDrawing_Transparent)
    Protected TxtW = TextWidth("Turbo (segurar)")
    DrawText((GadgetWidth(G_Turbo) - TxtW) / 2, GadgetHeight(G_Turbo) / 2 - 8, "Turbo (segurar)", RGB(255, 255, 255))
    StopDrawing()
  EndIf
EndProcedure

; Atualiza o ROTULO visivel de um ThemedButton (ButtonImageGadget, ver
; ThemedButtons.pbi) - SetGadgetText() nao faz NADA visualmente nesse tipo de
; gadget, porque o que aparece na tela e uma IMAGEM gerada uma vez na
; criacao (ThemedUI_CreateButtonImage()), nao o "texto" do gadget. Bug real
; e silencioso (sem erro de compilacao nem crash) encontrado 2026-08-20
; verificando ao vivo o novo G_BottomPower (Power na barra inferior): o
; rotulo nunca atualizava apesar do "Estado: Ligado" no topo confirmar que o
; estado interno estava certo - na verdade ja afetava TODOS os botoes de
; estado dinamico deste arquivo (G_Power/G_Pause/G_Firmware/G_Rensha/G_VSync/
; G_Deinterlace/G_LimitSprites/G_Fullscreen/G_DisableSprites): o comando
; "set X on/off" sempre era enviado certo, so o ROTULO mostrado de volta
; nunca refletia isso. W/H tem que bater com os passados na criacao do
; ThemedButton (a imagem e redesenhada do zero nesse tamanho).
Procedure OMSXGui_SetButtonText(G_Button, W.i, H.i, Text.s)
  SetGadgetAttribute(G_Button, #PB_Button_Image, ImageID(ThemedUI_CreateButtonImage(W, H, Text, "")))
EndProcedure

; Desenha o "quadro" de FPS da barra inferior (sempre visivel, qualquer aba)
; como um mini-display digital - fundo escuro, texto sobrescrito a cada
; chamada (CanvasGadget redesenhado do zero, nao um TextGadget acumulando
; nada) em vez de virar mais uma linha de log poluindo a tela (pedido do
; usuario 2026-08-20 - ver tambem OMSX_LastVerboseChunk/OMSX_Poll() em
; OpenMSXBridge.pbi, que agora tira a resposta crua do FPS do log conciso da
; aba "Console").
Procedure OMSXGui_DrawFpsDisplay(G_Fps, FpsText.s)
  If Not StartDrawing(CanvasOutput(G_Fps))
    ProcedureReturn
  EndIf
  Box(0, 0, GadgetWidth(G_Fps), GadgetHeight(G_Fps), RGB(15, 15, 15))
  DrawingMode(#PB_2DDrawing_Outlined)
  Box(0, 0, GadgetWidth(G_Fps) - 1, GadgetHeight(G_Fps) - 1, RGB(90, 90, 90))
  DrawingMode(#PB_2DDrawing_Transparent)
  Protected TxtW = TextWidth(FpsText)
  Protected TxtH = TextHeight(FpsText)
  DrawText((GadgetWidth(G_Fps) - TxtW) / 2, (GadgetHeight(G_Fps) - TxtH) / 2, FpsText, RGB(80, 230, 120))
  StopDrawing()
EndProcedure

; Insere TagText (ja com as colchetes Unicode ⟦ ⟧, ver OMSX_TypeTextWithTags()
; em OpenMSXBridge.pbi) na posicao do cursor/selecao de G_Edit, substituindo
; a selecao se houver uma - mesma tecnica nativa (EM_GETSEL/EM_SETSEL) ja
; usada por MamuteAssemblerGui.pbi/MamuteEditGui.pbi neste projeto pra
; posicionar o cursor num EditorGadget, so que lendo a selecao em vez de so
; escrever nela. Fora do Windows (sem SendMessage_ nativo), cai pra "acrescenta
; no final" - aproximacao razoavel, ja que EditorGadget nao expoe a posicao do
; cursor de forma portavel.
Procedure OMSXGui_InsertTagAtCursor(G_Edit, TagText.s)
  Protected CurText.s = GetGadgetText(G_Edit)
  Protected StartPos.i, EndPos.i
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Protected SelStart.l, SelEnd.l
    SendMessage_(GadgetID(G_Edit), #EM_GETSEL, @SelStart, @SelEnd)
    StartPos = SelStart
    EndPos = SelEnd
  CompilerElse
    StartPos = Len(CurText)
    EndPos = StartPos
  CompilerEndIf
  SetGadgetText(G_Edit, Left(CurText, StartPos) + TagText + Mid(CurText, EndPos + 1))
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Protected NewCaret.i = StartPos + Len(TagText)
    SendMessage_(GadgetID(G_Edit), #EM_SETSEL, NewCaret, NewCaret)
  CompilerEndIf
  SetActiveGadget(G_Edit)
EndProcedure

; Junta os itens de uma List.s() com Sep entre eles ("" se a lista estiver
; vazia) - usado pra montar tanto o texto de preview ("SHIFT + F1") quanto a
; tag de verdade ("SHIFT+F1") do "Modo Combo" (ver comentario de
; G_ComboToggle, OMSXGui_OpenWindow()) a partir da MESMA lista de nomes
; pendentes, sem duas formatacoes divergentes.
Procedure.s OMSXGui_JoinList(List Names.s(), Sep.s)
  Protected Result.s = ""
  ForEach Names()
    If Result <> "" : Result + Sep : EndIf
    Result + Names()
  Next
  ProcedureReturn Result
EndProcedure

; Nome do pluggable do openMSX pra cada item do combo de porta de joystick
; (Nada/Mouse/Teclado P1/Teclado P2/Paddle, ver OMSXGui_OpenWindow()) -
; "" (indice 0, "Nada") significa "unplug" em vez de "plug". Confirmado
; contra o manual/codigo-fonte real do openMSX: "mouse" e "paddle" sao
; pluggables de verdade (Mouse.cc/Paddle.cc); "keyjoystick1"/"keyjoystick2"
; sao o teclado do PC agindo como joystick 1/2 (o openMSX NAO tem um
; pluggable literal "keypad").
Procedure.s OMSXGui_JoyPluggableName(Idx.i)
  Select Idx
    Case 1 : ProcedureReturn "mouse"
    Case 2 : ProcedureReturn "keyjoystick1"
    Case 3 : ProcedureReturn "keyjoystick2"
    Case 4 : ProcedureReturn "paddle"
  EndSelect
  ProcedureReturn ""
EndProcedure

; Desenha os 6 LEDs (Power/Caps/Kana/Pause/Turbo/FDD) num unico CanvasGadget -
; circulo colorido (verde se ligado, cinza-escuro se desligado ou "?" se o
; estado ainda nao chegou) com o nome embaixo. Known/On vem dos globais
; OMSX_Led*Known/On (Power/Pause reaproveitam OMSX_PowerOn/OMSX_Paused, ver
; comentario no topo de OpenMSXBridge.pbi).
Procedure OMSXGui_DrawOneLed(Cx.i, Cy.i, Label.s, Known.b, IsOn.b)
  Protected Color.i
  If Not Known
    Color = RGB(120, 100, 20) ; amarelo-escuro = estado ainda desconhecido
  ElseIf IsOn
    Color = RGB(60, 220, 60)  ; verde = ligado
  Else
    Color = RGB(70, 70, 70)   ; cinza = desligado
  EndIf
  Circle(Cx, Cy, 10, Color)
  Protected TxtW = TextWidth(Label)
  DrawText(Cx - TxtW / 2, Cy + 16, Label, RGB(220, 220, 220))
EndProcedure

Procedure OMSXGui_DrawLeds(G_Leds, PowerKnown.b, PowerOn.b, CapsKnown.b, CapsOn.b, KanaKnown.b, KanaOn.b, PauseKnown.b, PauseOn.b, TurboKnown.b, TurboOn.b, FddKnown.b, FddOn.b)
  If Not StartDrawing(CanvasOutput(G_Leds))
    ProcedureReturn
  EndIf
  Box(0, 0, GadgetWidth(G_Leds), GadgetHeight(G_Leds), RGB(40, 40, 40))
  DrawingMode(#PB_2DDrawing_Transparent)

  OMSXGui_DrawOneLed(30, 18, "Power", PowerKnown, PowerOn)
  OMSXGui_DrawOneLed(94, 18, "Caps", CapsKnown, CapsOn)
  OMSXGui_DrawOneLed(158, 18, "Kana", KanaKnown, KanaOn)
  OMSXGui_DrawOneLed(222, 18, "Pause", PauseKnown, PauseOn)
  OMSXGui_DrawOneLed(286, 18, "Turbo", TurboKnown, TurboOn)
  OMSXGui_DrawOneLed(350, 18, "FDD", FddKnown, FddOn)

  StopDrawing()
EndProcedure

; Numero sequencial livre pra "<BaseName><NNNN>.png" dentro de Dir (o maior
; numero ja usado + 1, ou 0 se nao houver nenhum) - mesmo espirito de
; BadigCfg_ListXmlNames() (BadigSettings.pbi): varre o diretorio uma vez,
; sem guardar estado entre chamadas. Usado pelo botao "Capturar screenshot"
; quando um diretorio proprio foi escolhido, pra numerar sem depender do
; "-prefix" nativo do openMSX (que sempre grava na pasta padrao dele).
; Nome do dispositivo atualmente selecionado no ListViewGadget de
; dispositivos de som (aba "Volume") - "" se nada selecionado (lista vazia
; ou nenhuma selecao ainda).
Procedure.s OMSXGui_SelectedDevice(G_DeviceList)
  Protected Sel.i = GetGadgetState(G_DeviceList)
  If Sel < 0
    ProcedureReturn ""
  EndIf
  ProcedureReturn GetGadgetItemText(G_DeviceList, Sel)
EndProcedure

Procedure.i OMSXGui_NextShotNumber(Dir.s, BaseName.s)
  Protected MaxNum.i = -1
  Protected Handle = ExamineDirectory(#PB_Any, Dir, BaseName + "*.png")
  If Handle
    While NextDirectoryEntry(Handle)
      If DirectoryEntryType(Handle) = #PB_DirectoryEntry_File
        Protected Name.s = DirectoryEntryName(Handle)
        Protected NumPart.s = Mid(Name, Len(BaseName) + 1, Len(Name) - Len(BaseName) - 4)
        Protected AllDigits.b = Bool(Len(NumPart) > 0)
        Protected K.i
        For K = 1 To Len(NumPart)
          If FindString("0123456789", Mid(NumPart, K, 1)) = 0
            AllDigits = #False
          EndIf
        Next
        If AllDigits And Val(NumPart) > MaxNum
          MaxNum = Val(NumPart)
        EndIf
      EndIf
    Wend
    FinishDirectory(Handle)
  EndIf
  ProcedureReturn MaxNum + 1
EndProcedure

Procedure OMSXGui_OpenWindow(ParentWindow)
  If BadigCfg\EmulatorPath = ""
    MessageRequester("openMSX nao configurado",
                     "Configure o caminho do executavel do openMSX em" + Chr(10) +
                     "Configurar -> openMSX... (ou Configurar -> Basic Dignified... -> aba Emulador).",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  Protected AlreadyRunning.b = OMSX_IsRunning()
  If Not OMSX_Start()
    MessageRequester("Erro", "Nao foi possivel executar o openMSX:" + Chr(10) + BadigCfg\EmulatorPath,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  Protected WinW = 940, WinH = 766
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "openMSX",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_SizeGadget)
  If Not Win
    ProcedureReturn
  EndIf
  ; O openMSX (processo a parte) continua rodando normalmente enquanto esta
  ; janela bloqueia a principal (ver motivo do DisableWindow em
  ; OpenModelessChildWindow(), BadigEditor.pb) - so a EDICAO fica bloqueada
  ; ate fechar este console.

  ; Indicador de estado (Ligado/Desligado, Rodando/Pausado) - ver OMSX_StatusText() em
  ; OpenMSXBridge.pbi. Alimentado por "<update type="setting" ...>" (assinado no boot,
  ; OMSX_PipeConnectThread()), entao reflete o estado real mesmo se ele mudar por outro
  ; caminho que nao um comando mandado por esta janela (ex. o usuario pausando pela
  ; propria janela do openMSX).
  Protected G_Status     = TextGadget(#PB_Any, 24, 24, WinW - 48, 20, "Estado: ?  |  ?", #PB_Text_Center)

  ; Botao principal: pega o codigo da aba ativa do editor e roda na MESMA
  ; instancia (RunBasicFromActiveTab() -> RunOnOpenMSX() -> OMSX_LoadDisk(),
  ; ver BadigEditor.pb/OpenMSXBridge.pbi) - nao abre uma janela nova do
  ; openMSX a cada F5/clique, so troca o disco e reinicia. G_MismatchWarn
  ; avisa quando maquina/extensao configuradas mudaram desde que esta
  ; instancia subiu (ver timer de poll abaixo) - "-machine"/"-ext" so valem
  ; no lancamento, entao so "Reiniciar openMSX" aplica isso de verdade.
  Protected G_Transfer    = ThemedButton(24, 54, 280, 30, "Transferir programa atual", "")
  Protected G_MismatchWarn = TextGadget(#PB_Any, 316, 60, 600, 20, "")

  Protected Panel = PanelGadget(#PB_Any, 24, 96, WinW - 48, 600)

  ;- Aba "Console" ---------------------------------------------------------
  AddGadgetItem(Panel, -1, "Console")

  TextGadget(#PB_Any, 24, 16, 400, 18, "Midia (unidade de disco A / cartucho / cassete)")

  TextGadget(#PB_Any, 24, 38, 70, 20, "Disco A:")
  Protected G_DiskPath    = StringGadget(#PB_Any, 98, 34, 520, 24, "")
  Protected G_DiskBrowse  = ThemedButton(622, 34, 50, 24, "...", "")
  Protected G_DiskInsert  = ThemedButton(676, 34, 90, 24, "Inserir", Chr(#Icon_Insert))
  GadgetToolTip(G_DiskInsert, "Inserir")
  Protected G_DiskEject   = ThemedButton(770, 34, 90, 24, "Ejetar", Chr(#Icon_Eject))
  GadgetToolTip(G_DiskEject, "Ejetar")

  TextGadget(#PB_Any, 24, 70, 70, 20, "Cartucho:")
  Protected G_CartPath    = StringGadget(#PB_Any, 98, 66, 520, 24, "")
  Protected G_CartBrowse  = ThemedButton(622, 66, 50, 24, "...", "")
  Protected G_CartInsert  = ThemedButton(676, 66, 90, 24, "Inserir", Chr(#Icon_Insert))
  GadgetToolTip(G_CartInsert, "Inserir")
  Protected G_CartEject   = ThemedButton(770, 66, 90, 24, "Ejetar", Chr(#Icon_Eject))
  GadgetToolTip(G_CartEject, "Ejetar")

  TextGadget(#PB_Any, 24, 102, 70, 20, "Cassete:")
  Protected G_CasPath     = StringGadget(#PB_Any, 98, 98, 520, 24, "")
  Protected G_CasBrowse   = ThemedButton(622, 98, 50, 24, "...", "")
  Protected G_CasInsert   = ThemedButton(676, 98, 90, 24, "Inserir", Chr(#Icon_Insert))
  GadgetToolTip(G_CasInsert, "Inserir")
  Protected G_CasEject    = ThemedButton(770, 98, 90, 24, "Ejetar", Chr(#Icon_Eject))
  GadgetToolTip(G_CasEject, "Ejetar")

  Protected G_Log        = EditorGadget(#PB_Any, 24, 140, WinW - 96, 300, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)

  Protected G_Input      = StringGadget(#PB_Any, 24, 456, WinW - 230, 24, "")
  Protected G_Send       = ThemedButton(WinW - 198, 456, 102, 24, "Enviar" + Chr(9) + "Enter", "")

  ;- Aba "Outros comandos" --------------------------------------------------
  AddGadgetItem(Panel, -1, "Outros comandos")

  TextGadget(#PB_Any, 24, 16, 300, 18, "Velocidade de emulacao")
  Protected G_Speed      = TrackBarGadget(#PB_Any, 24, 38, 500, 30, 1, 800)
  SetGadgetState(G_Speed, 100)
  Protected G_SpeedLabel = TextGadget(#PB_Any, 534, 44, 80, 20, "100%")
  Protected G_Speed100   = ThemedButton(624, 36, 80, 28, "100%", "")
  Protected G_Turbo      = CanvasGadget(#PB_Any, 714, 36, 150, 28)
  OMSXGui_DrawTurboButton(G_Turbo, #False)
  GadgetToolTip(G_Speed, "Velocidade manual (1% a 800%) - equivale ao comando " + Chr(34) + "set speed <valor>" + Chr(34) + " do openMSX")
  GadgetToolTip(G_Turbo, "Acelera ao maximo enquanto pressionado, volta a 100% ao soltar")

  TextGadget(#PB_Any, 24, 88, 300, 18, "Controles")
  Protected G_Power       = ThemedButton(24, 110, 130, 28, "Power: ?", "")
  Protected G_Reset       = ThemedButton(164, 110, 100, 28, "Reset", Chr(#Icon_Refresh))
  GadgetToolTip(G_Reset, "Reset")
  Protected G_Pause       = ThemedButton(274, 110, 130, 28, "Pause: ?", "")

  Protected G_Firmware    = ThemedButton(24, 150, 220, 28, "Firmware: ?", "")
  GadgetToolTip(G_Firmware, "Liga/desliga o software residente em memoria (interruptor de firmware) - so existe em algumas maquinas MSX")
  Protected G_Rensha      = ThemedButton(254, 150, 220, 28, "Ren Sha Turbo: ?", "")
  GadgetToolTip(G_Rensha, "Acelera o botao de tiro (auto fire de hardware) - so existe em maquinas com suporte (turboR, etc.)")

  TextGadget(#PB_Any, 24, 202, 300, 18, "Conectores das portas de joystick")
  TextGadget(#PB_Any, 24, 228, 100, 22, "Joystick 1:")
  Protected G_Joy1 = ComboBoxGadget(#PB_Any, 134, 224, 240, 24)
  TextGadget(#PB_Any, 24, 260, 100, 22, "Joystick 2:")
  Protected G_Joy2 = ComboBoxGadget(#PB_Any, 134, 256, 240, 24)
  Protected Idx
  For Idx = 0 To 1
    Protected G_JoyCombo = G_Joy1
    If Idx = 1 : G_JoyCombo = G_Joy2 : EndIf
    AddGadgetItem(G_JoyCombo, -1, "Nada")
    AddGadgetItem(G_JoyCombo, -1, "Mouse")
    AddGadgetItem(G_JoyCombo, -1, "Teclado (P1)")
    AddGadgetItem(G_JoyCombo, -1, "Teclado (P2)")
    AddGadgetItem(G_JoyCombo, -1, "Paddle")
    SetGadgetState(G_JoyCombo, 0)
  Next

  ;- Aba "Video" -------------------------------------------------------------
  AddGadgetItem(Panel, -1, "Video")

  TextGadget(#PB_Any, 24, 16, 300, 18, "Renderizacao")
  TextGadget(#PB_Any, 24, 40, 70, 20, "Renderer:")
  Protected G_Renderer = ComboBoxGadget(#PB_Any, 98, 36, 140, 24)
  AddGadgetItem(G_Renderer, -1, "SDLGL-PP")
  AddGadgetItem(G_Renderer, -1, "none")
  SetGadgetState(G_Renderer, 0)
  TextGadget(#PB_Any, 250, 40, 55, 20, "Escala:")
  Protected G_Scale = ComboBoxGadget(#PB_Any, 310, 36, 70, 24)
  AddGadgetItem(G_Scale, -1, "2")
  AddGadgetItem(G_Scale, -1, "3")
  AddGadgetItem(G_Scale, -1, "4")
  SetGadgetState(G_Scale, 0)
  Protected G_VSync   = ThemedButton(396, 36, 100, 26, "VSync: ?", "")
  TextGadget(#PB_Any, 610, 40, 65, 20, "Modo TV:")
  Protected G_TvMode  = ComboBoxGadget(#PB_Any, 680, 36, 140, 24)
  AddGadgetItem(G_TvMode, -1, "simple")
  AddGadgetItem(G_TvMode, -1, "ScaleNx")
  AddGadgetItem(G_TvMode, -1, "hq")
  AddGadgetItem(G_TvMode, -1, "RGBtriplet")
  AddGadgetItem(G_TvMode, -1, "TV")
  SetGadgetState(G_TvMode, 0)
  GadgetToolTip(G_TvMode, "scale_algorithm - como no Catapult: simple (padrao), ScaleNx (suaviza bordas), hq (deteccao de borda), RGBtriplet (efeito de mascara RGB, melhor em escala 3), TV (emula o brilho tipo CRT)")

  TextGadget(#PB_Any, 24, 76, 300, 18, "Efeitos")
  Protected G_Deinterlace   = ThemedButton(24, 98, 140, 26, "Deinterlace: ?", "")
  Protected G_LimitSprites  = ThemedButton(174, 98, 150, 26, "Limitar sprites: ?", "")
  Protected G_Fullscreen    = ThemedButton(334, 98, 120, 26, "Tela cheia: ?", "")
  Protected G_DisableSprites = ThemedButton(464, 98, 170, 26, "Desabilitar sprites: ?", "")

  TextGadget(#PB_Any, 24, 140, 110, 22, "Fonte de video:")
  Protected G_VideoSource = ComboBoxGadget(#PB_Any, 140, 136, 160, 24)
  AddGadgetItem(G_VideoSource, -1, "MSX")
  AddGadgetItem(G_VideoSource, -1, "GFX9000")
  AddGadgetItem(G_VideoSource, -1, "Video9000")
  SetGadgetState(G_VideoSource, 0)
  GadgetToolTip(G_VideoSource, "So faz efeito se houver uma extensao GFX9000/Video9000 conectada")

  TextGadget(#PB_Any, 24, 182, 400, 18, "Efeitos de tela (estilo CRT)")

  TextGadget(#PB_Any, 24, 210, 90, 20, "Scanlines:")
  Protected G_Scanline      = TrackBarGadget(#PB_Any, 118, 204, 300, 28, 0, 100)
  Protected G_ScanlineLabel = TextGadget(#PB_Any, 424, 210, 50, 20, "20")
  Protected G_ScanlineReset = ThemedButton(480, 204, 70, 26, "Reset", Chr(#Icon_Refresh))
  GadgetToolTip(G_ScanlineReset, "Reset")

  TextGadget(#PB_Any, 24, 242, 90, 20, "Blur:")
  Protected G_Blur      = TrackBarGadget(#PB_Any, 118, 236, 300, 28, 0, 100)
  Protected G_BlurLabel = TextGadget(#PB_Any, 424, 242, 50, 20, "50")
  Protected G_BlurReset = ThemedButton(480, 236, 70, 26, "Reset", Chr(#Icon_Refresh))
  GadgetToolTip(G_BlurReset, "Reset")

  TextGadget(#PB_Any, 24, 274, 90, 20, "Glow:")
  Protected G_Glow      = TrackBarGadget(#PB_Any, 118, 268, 300, 28, 0, 100)
  Protected G_GlowLabel = TextGadget(#PB_Any, 424, 274, 50, 20, "0")
  Protected G_GlowReset = ThemedButton(480, 268, 70, 26, "Reset", Chr(#Icon_Refresh))
  GadgetToolTip(G_GlowReset, "Reset")

  ; Gamma e float (0.1 a 5.0, padrao 1.1 - ver RenderSettings.cc real do
  ; openMSX) - a trackbar so faz posicoes inteiras, entao guarda o valor *10
  ; (1 a 50) e converte na hora de mandar/mostrar.
  TextGadget(#PB_Any, 24, 306, 90, 20, "Gamma:")
  Protected G_Gamma      = TrackBarGadget(#PB_Any, 118, 300, 300, 28, 1, 50)
  Protected G_GammaLabel = TextGadget(#PB_Any, 424, 306, 50, 20, "1.1")
  Protected G_GammaReset = ThemedButton(480, 300, 70, 26, "Reset", Chr(#Icon_Refresh))
  GadgetToolTip(G_GammaReset, "Reset")

  TextGadget(#PB_Any, 24, 338, 90, 20, "Noise:")
  Protected G_Noise      = TrackBarGadget(#PB_Any, 118, 332, 300, 28, 0, 100)
  Protected G_NoiseLabel = TextGadget(#PB_Any, 424, 338, 50, 20, "0")
  Protected G_NoiseReset = ThemedButton(480, 332, 70, 26, "Reset", Chr(#Icon_Refresh))
  GadgetToolTip(G_NoiseReset, "Reset")

  SetGadgetState(G_Scanline, 20)
  SetGadgetState(G_Blur, 50)
  SetGadgetState(G_Glow, 0)
  SetGadgetState(G_Gamma, 11)
  SetGadgetState(G_Noise, 0)

  TextGadget(#PB_Any, 24, 384, 300, 18, "Screenshot")
  TextGadget(#PB_Any, 24, 410, 90, 20, "Nome base:")
  Protected G_ShotName = StringGadget(#PB_Any, 118, 406, 200, 24, "screenshot")
  TextGadget(#PB_Any, 340, 410, 150, 20, "Diretorio (opcional):")
  Protected G_ShotDir       = StringGadget(#PB_Any, 484, 406, 280, 24, "")
  Protected G_ShotDirBrowse = ThemedButton(768, 406, 50, 24, "...", "")
  Protected G_ShotTake = ThemedButton(24, 440, 240, 28, "Capturar screenshot", "")
  GadgetToolTip(G_ShotTake, "Sem diretorio escolhido, salva na pasta padrao do openMSX (screenshots/) usando numeracao sequencial nativa (-prefix)")

  TextGadget(#PB_Any, 24, 486, 300, 18, "LEDs / Status")
  Protected G_Leds = CanvasGadget(#PB_Any, 24, 508, 400, 50)
  OMSXGui_DrawLeds(G_Leds, #False, #False, #False, #False, #False, #False, #False, #False, #False, #False, #False, #False)
  Protected G_Stop = ThemedButton(440, 518, 100, 30, "STOP", "")
  GadgetToolTip(G_Stop, "Simula a tecla STOP do teclado MSX (Ctrl+Stop interrompe um programa BASIC)")
  Protected G_FpsLabel = TextGadget(#PB_Any, 560, 524, 150, 22, "FPS: ?")

  ;- Aba "Volume" --------------------------------------------------------------
  AddGadgetItem(Panel, -1, "Volume")

  TextGadget(#PB_Any, 24, 16, 400, 18, "Dispositivos de som")
  TextGadget(#PB_Any, 24, 42, 70, 20, "Adicionar:")
  Protected G_DeviceAddName = StringGadget(#PB_Any, 98, 38, 260, 24, "")
  Protected G_DeviceAdd     = ThemedButton(364, 38, 90, 24, "Adicionar", Chr(#Icon_Add))
  GadgetToolTip(G_DeviceAdd, "Adicionar")
  GadgetToolTip(G_DeviceAddName, "Nome exato do dispositivo - PSG, keyclick e cassetteplayer sao fixos; os demais (SCC+, FM-PAC/MSX-Music, MoonSound, MSX-Audio...) usam o nome comercial completo do hardware conectado, consulte no proprio menu do openMSX (Configuracoes -> Audio -> Mostrar ajustes dos chips de som)")
  Protected G_DeviceList = ListViewGadget(#PB_Any, 24, 70, 400, 178)
  GadgetToolTip(G_DeviceList, "Dispositivos descobertos automaticamente (quando algo muda o volume/balance dele) ou adicionados manualmente acima")

  TextGadget(#PB_Any, 440, 16, 300, 18, "Dispositivo selecionado")
  Protected G_DeviceSelName = TextGadget(#PB_Any, 440, 38, 456, 22, "(nenhum)")

  TextGadget(#PB_Any, 440, 68, 90, 20, "Volume:")
  Protected G_DevVolume      = TrackBarGadget(#PB_Any, 440, 90, 280, 28, 0, 100)
  Protected G_DevVolumeLabel = TextGadget(#PB_Any, 730, 96, 60, 20, "-")

  TextGadget(#PB_Any, 440, 128, 90, 20, "Balance:")
  Protected G_DevBalance      = TrackBarGadget(#PB_Any, 440, 150, 280, 28, -100, 100)
  Protected G_DevBalanceLabel = TextGadget(#PB_Any, 730, 156, 60, 20, "-")
  GadgetToolTip(G_DevBalance, "-100 = totalmente no canal esquerdo, 0 = centro (estereo normal), 100 = totalmente no canal direito - substitui o antigo Mute/Left/Right/Stereo do Catapult (removido do openMSX atual)")

  Protected G_DevMute = ThemedButton(440, 188, 160, 28, "Mudo (Volume 0)", Chr(#Icon_Mute))
  GadgetToolTip(G_DevMute, "Mudo (Volume 0)")

  TextGadget(#PB_Any, 24, 260, 200, 18, "MIDI")

  TextGadget(#PB_Any, 24, 286, 165, 20, "MIDI IN (arquivo .mid):")
  Protected G_MidiInPath       = StringGadget(#PB_Any, 190, 282, 320, 24, "")
  Protected G_MidiInBrowse     = ThemedButton(516, 282, 50, 24, "...", "")
  Protected G_MidiInConnect    = ThemedButton(572, 282, 90, 24, "Conectar", Chr(#Icon_Plug))
  GadgetToolTip(G_MidiInConnect, "Conectar")
  Protected G_MidiInDisconnect = ThemedButton(668, 282, 110, 24, "Desconectar", Chr(#Icon_Unplug))
  GadgetToolTip(G_MidiInDisconnect, "Desconectar")
  Protected G_MidiInStatus     = TextGadget(#PB_Any, 24, 310, 754, 18, "Conector MIDI IN: procurando...")

  TextGadget(#PB_Any, 24, 338, 165, 20, "MIDI OUT (log em arquivo):")
  Protected G_MidiOutPath       = StringGadget(#PB_Any, 190, 334, 320, 24, "")
  Protected G_MidiOutBrowse     = ThemedButton(516, 334, 50, 24, "...", "")
  Protected G_MidiOutConnect    = ThemedButton(572, 334, 90, 24, "Conectar", Chr(#Icon_Plug))
  GadgetToolTip(G_MidiOutConnect, "Conectar")
  Protected G_MidiOutDisconnect = ThemedButton(668, 334, 110, 24, "Desconectar", Chr(#Icon_Unplug))
  GadgetToolTip(G_MidiOutDisconnect, "Desconectar")
  Protected G_MidiOutStatus     = TextGadget(#PB_Any, 24, 362, 754, 18, "Conector MIDI OUT: procurando...")

  TextGadget(#PB_Any, 24, 400, 180, 20, "Log de audio geral (WAV):")
  Protected G_AudioLog = ThemedButton(210, 396, 220, 26, "Gravar / Parar log de audio", "")
  GadgetToolTip(G_AudioLog, "Alterna gravacao de audio (comando " + Chr(34) + "soundlog" + Chr(34) + " do openMSX) - clique de novo pra parar")

  ;- Aba "Input Text" ----------------------------------------------------------
  AddGadgetItem(Panel, -1, "Input Text")

  TextGadget(#PB_Any, 24, 16, WinW - 96, 18,
    "Digite ou cole o texto abaixo - " + Chr(34) + "Type" + Chr(34) + " digita no MSX como se fosse teclado de verdade (mesmo mecanismo do Catapult - quebras de linha viram Enter). Use os botoes abaixo pra inserir uma tecla especial (ESC, F1-F5, setas...) sem confundir com texto literal.")

  ; Paleta de teclas especiais - array-driven pra nao repetir 20+ vezes o
  ; mesmo par ThemedButton+tooltip. Cada botao insere, na posicao do cursor
  ; de G_TypeInput, uma tag ⟦NOME⟧ (colchetes Unicode reservados, ver
  ; OMSX_TypeTextWithTags() em OpenMSXBridge.pbi pro porque NAO sao os
  ; colchetes ASCII comuns "[ ]") que o botao "Type" abaixo traduz pra um
  ; toque de tecla de verdade em vez de digitar como texto - da pra misturar
  ; livremente com texto normal (inclusive contendo "[ESC]" ASCII literal,
  ; que nao e afetado) e mandar tudo de uma vez.
  Protected Dim TypeKeyLabel.s(30)
  Protected TypeKeyCount.i = 0
  Macro OMSXAddTypeKey(Lbl)
    TypeKeyLabel(TypeKeyCount) = Lbl
    TypeKeyCount + 1
  EndMacro
  OMSXAddTypeKey("ESC")    : OMSXAddTypeKey("F1")     : OMSXAddTypeKey("F2")    : OMSXAddTypeKey("F3")
  OMSXAddTypeKey("F4")     : OMSXAddTypeKey("F5")     : OMSXAddTypeKey("TAB")   : OMSXAddTypeKey("BS")
  OMSXAddTypeKey("DEL")    : OMSXAddTypeKey("INS")    : OMSXAddTypeKey("HOME")  : OMSXAddTypeKey("SELECT")
  OMSXAddTypeKey("STOP")   : OMSXAddTypeKey("ENTER")  : OMSXAddTypeKey("LEFT")  : OMSXAddTypeKey("UP")
  OMSXAddTypeKey("DOWN")   : OMSXAddTypeKey("RIGHT")  : OMSXAddTypeKey("GRAPH") : OMSXAddTypeKey("CODE")
  OMSXAddTypeKey("CTRL")   : OMSXAddTypeKey("SHIFT")  : OMSXAddTypeKey("CAPS")

  Protected Dim TypeKeyGadget.i(30)
  Protected TKX.i = 24, TKY.i = 40
  Protected TKW.i = 70, TKI.i
  For TKI = 0 To TypeKeyCount - 1
    If TKX + TKW > WinW - 72 ; mesma margem direita de G_TypeInput/G_Log/G_StatusLog (WinW - 96 de largura a partir de x=24)
      TKX = 24
      TKY + 30
    EndIf
    TypeKeyGadget(TKI) = ThemedButton(TKX, TKY, TKW, 26, TypeKeyLabel(TKI), "")
    GadgetToolTip(TypeKeyGadget(TKI), "Insere a tecla especial " + Chr(34) + TypeKeyLabel(TKI) + Chr(34) + " no cursor - nao confunde com texto literal")
    TKX + TKW + 4
  Next
  ; "Modo Combo" - com o modo NORMAL (padrao), cada botao da paleta insere
  ; sua propria tag ⟦NOME⟧ na hora (pulso independente: aperta E solta, ver
  ; OMSX_PressMatrixKey() em OpenMSXBridge.pbi) - "[SHIFT][F1]" nesse modo
  ; aperta/solta SHIFT, depois aperta/solta F1, sequencial. Com o modo COMBO
  ; ligado, os cliques na paleta NAO inserem mais na hora - acumulam num
  ; combo (G_ComboLabel mostra o que ja foi clicado) ate "Inserir combo"
  ; escrever uma UNICA tag ⟦NOME1+NOME2+...⟧ no cursor - essa vira
  ; OMSX_PressMatrixCombo() (segura todas, so DEPOIS solta) em vez de pulsos
  ; independentes. Pedido explicito do usuario 2026-08-20: precisava dos dois
  ; comportamentos ("as vezes sequencial ja resolve, mas as vezes precisa
  ; segurar Shift/Ctrl/Select junto com outra tecla de verdade").
  Protected ComboRowY.i = TKY + 34
  Protected G_ComboToggle = ThemedButton(24, ComboRowY, 160, 28, "Modo Combo: OFF", "")
  GadgetToolTip(G_ComboToggle, "Ligado: os botoes acima acumulam num combo (todas as teclas pressionadas JUNTAS, soltas so no final) em vez de inserir na hora")
  Protected G_ComboLabel  = TextGadget(#PB_Any, 194, ComboRowY + 5, 470, 20, "Combo: (vazio)")
  Protected G_ComboInsert = ThemedButton(674, ComboRowY, 90, 28, "Inserir", "")
  GadgetToolTip(G_ComboInsert, "Insere o combo acumulado como uma unica tag - todas as teclas pressionadas ao mesmo tempo")
  Protected G_ComboCancel = ThemedButton(774, ComboRowY, 90, 28, "Cancelar", "")
  GadgetToolTip(G_ComboCancel, "Descarta o combo acumulado sem inserir nada")

  Protected TypeInputY.i = ComboRowY + 34

  Protected G_TypeInput = EditorGadget(#PB_Any, 24, TypeInputY, WinW - 96, 520 - TypeInputY, #PB_Editor_WordWrap)
  Protected G_TypeGo    = ThemedButton(24, 530, 160, 30, "Type", "")
  Protected G_TypeClear = ThemedButton(194, 530, 100, 30, "Clear", "")
  GadgetToolTip(G_TypeGo, "Digita o texto acima no MSX (comando " + Chr(34) + "type" + Chr(34) + " do openMSX) - tags " + Chr(34) + "⟦NOME⟧" + Chr(34) + " viram tecla especial (⟦A+B⟧ = combo, segura todas), o resto vira texto literal")

  ;- Aba "Status Info" -----------------------------------------------------------
  AddGadgetItem(Panel, -1, "Status Info")

  TextGadget(#PB_Any, 24, 16, WinW - 96, 18, "Tudo que o openMSX reporta (mudancas de estado, avisos, erros) - inclusive o que NAO foi voce que mandou.")
  Protected G_StatusLog = EditorGadget(#PB_Any, 24, 40, WinW - 96, 520, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)

  CloseGadgetList()

  Protected G_Restart      = ThemedButton(24, 712, 160, 30, "Reiniciar openMSX", Chr(#Icon_Refresh))
  ; Display de FPS + botao de Power na barra inferior (sempre visivel,
  ; qualquer aba - pedido do usuario 2026-08-20, "logo depois do botao de
  ; reset embaixo"): acesso rapido sem precisar trocar pra aba "Outros
  ; comandos" (que ja tem seu proprio Power/Reset/Pause - este Power aqui e
  ; so um atalho pro MESMO comando "set power on/off", nao duplica estado).
  Protected G_FpsDisplayBottom = CanvasGadget(#PB_Any, 194, 712, 110, 30)
  OMSXGui_DrawFpsDisplay(G_FpsDisplayBottom, "FPS: --")
  GadgetToolTip(G_FpsDisplayBottom, "FPS atual do openMSX (openmsx_info fps), atualizado ~1x/segundo")
  Protected G_BottomPower  = ThemedButton(314, 712, 130, 30, "Power: ?", "")
  Protected G_ShowWindow = ThemedButton(454, 712, 140, 30, "Mostrar janela", Chr(#Icon_Eye))
  Protected G_Help       = ThemedButton(604, 712, 90, 30, "Ajuda", "")
  Protected G_Close      = ThemedButton(WinW - 109, 712, 85, 30, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")
  GadgetToolTip(G_ShowWindow, "Envia " + Chr(34) + "unset renderer" + Chr(34) + " - o openMSX sobe com -control em modo sem janela (renderer none) ate isso ser enviado")
  GadgetToolTip(G_Restart, "Encerra e sobe uma instancia nova do openMSX, ja com a maquina/extensao configuradas agora em Configurar -> openMSX... (nao da pra trocar isso numa instancia ja rodando)")
  GadgetToolTip(G_Help, "Abre a Ajuda -> openMSX (consulta de comandos/configuracoes)")

  SetActiveGadget(G_Input)
  AddWindowTimer(Win, #OMSXGui_PollTimer, 150)
  AddKeyboardShortcut(Win, #PB_Shortcut_Return, #OMSXGui_EnterShortcut)

  If OMSX_IsRunning()
    SetGadgetText(G_Status, "Estado: " + OMSX_StatusText())
  EndIf

  ; Descobre os conectores MIDI IN/OUT de verdade desta maquina (variam por
  ; hardware, ver comentario de OMSX_MidiInConnector em OpenMSXBridge.pbi) -
  ; uma vez so, o timer de poll (mais abaixo) captura a resposta.
  OMSX_QueryMidiConnectors()

  Protected LogAccum.s = ""
  Protected StatusLogAccum.s = ""
  If AlreadyRunning
    LogAccum = OMSXGui_AppendLog(G_Log, LogAccum, "--- reconectado ao openMSX ja aberto (" + BadigCfg\EmulatorPath + ") ---")
  Else
    LogAccum = OMSXGui_AppendLog(G_Log, LogAccum, "--- iniciando openMSX (" + BadigCfg\EmulatorPath + ") ---")
  EndIf

  Protected Event, Quit.b = #False
  Protected PickPath.s
  Protected FpsTick.i = 0

  ; Estado do "Modo Combo" (ver comentario na criacao de G_ComboToggle acima) -
  ; ComboPendingNames() guarda so os NOMES (ex. "SHIFT","F1"), a tag final
  ; "⟦SHIFT+F1⟧" so e montada no clique de "Inserir".
  Protected ComboMode.b = #False
  Protected NewList ComboPendingNames.s()
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Menu
        If EventMenu() = #OMSXGui_EnterShortcut
          LogAccum = OMSXGui_Send(G_Log, G_Input, LogAccum)
        EndIf

      Case #PB_Event_Gadget
        ; Botoes da paleta de teclas especiais (aba "Input Text") sao
        ; array-driven (ver TypeKeyGadget()/TypeKeyLabel() acima) - checados
        ; ANTES do Select principal em vez de virar 23 "Case" repetidos.
        Protected TypeKeyClicked.i = -1, TKCheck.i
        For TKCheck = 0 To TypeKeyCount - 1
          If EventGadget() = TypeKeyGadget(TKCheck)
            TypeKeyClicked = TKCheck
            Break
          EndIf
        Next
        If TypeKeyClicked >= 0
          If ComboMode
            ; Modo Combo ligado - acumula o nome em vez de inserir na hora
            ; (ver comentario de G_ComboToggle na criacao da aba acima).
            AddElement(ComboPendingNames())
            ComboPendingNames() = TypeKeyLabel(TypeKeyClicked)
            SetGadgetText(G_ComboLabel, "Combo: " + OMSXGui_JoinList(ComboPendingNames(), " + "))
          Else
            OMSXGui_InsertTagAtCursor(G_TypeInput, Chr($27E6) + TypeKeyLabel(TypeKeyClicked) + Chr($27E7))
          EndIf
          Continue
        EndIf

        Select EventGadget()
          Case G_Send
            LogAccum = OMSXGui_Send(G_Log, G_Input, LogAccum)

          Case G_Transfer
            LogAccum = OMSXGui_AppendLog(G_Log, LogAccum, "--- transferindo programa da aba ativa ---")
            RunBasicFromActiveTab()

          Case G_Restart
            LogAccum = OMSXGui_AppendLog(G_Log, LogAccum, "--- reiniciando openMSX ---")
            OMSX_Stop()
            If Not OMSX_Start()
              LogAccum = OMSXGui_AppendLog(G_Log, LogAccum, "[ERRO] nao foi possivel religar o openMSX")
            EndIf
          Case G_ShowWindow
            LogAccum = OMSXGui_AppendLog(G_Log, LogAccum, "> unset renderer")
            OMSX_ShowWindow()

          Case G_DiskBrowse
            PickPath = OpenFileRequester("Selecione o disco", GetGadgetText(G_DiskPath),
                                         "Disco MSX (*.dsk)|*.dsk|Todos os arquivos (*.*)|*.*", 0)
            If PickPath <> "" : SetGadgetText(G_DiskPath, PickPath) : EndIf
          Case G_DiskInsert
            If Trim(GetGadgetText(G_DiskPath)) <> ""
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "diska insert " + Chr(34) + GetGadgetText(G_DiskPath) + Chr(34))
            EndIf
          Case G_DiskEject
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "diska eject")

          Case G_CartBrowse
            PickPath = OpenFileRequester("Selecione o cartucho", GetGadgetText(G_CartPath),
                                         "ROM MSX (*.rom)|*.rom|Todos os arquivos (*.*)|*.*", 0)
            If PickPath <> "" : SetGadgetText(G_CartPath, PickPath) : EndIf
          Case G_CartInsert
            If Trim(GetGadgetText(G_CartPath)) <> ""
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "carta insert " + Chr(34) + GetGadgetText(G_CartPath) + Chr(34))
            EndIf
          Case G_CartEject
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "carta eject")

          Case G_CasBrowse
            PickPath = OpenFileRequester("Selecione o cassete", GetGadgetText(G_CasPath),
                                         "Cassete MSX (*.cas;*.wav)|*.cas;*.wav|Todos os arquivos (*.*)|*.*", 0)
            If PickPath <> "" : SetGadgetText(G_CasPath, PickPath) : EndIf
          Case G_CasInsert
            If Trim(GetGadgetText(G_CasPath)) <> ""
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "cassetteplayer insert " + Chr(34) + GetGadgetText(G_CasPath) + Chr(34))
            EndIf
          Case G_CasEject
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "cassetteplayer eject")

          Case G_Speed
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set speed " + Str(GetGadgetState(G_Speed)))

          Case G_Speed100
            SetGadgetState(G_Speed, 100)
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set speed 100")

          Case G_Turbo
            Select EventType()
              Case #PB_EventType_LeftButtonDown
                OMSXGui_DrawTurboButton(G_Turbo, #True)
                LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set speed 9999")
              Case #PB_EventType_LeftButtonUp, #PB_EventType_MouseLeave
                OMSXGui_DrawTurboButton(G_Turbo, #False)
                SetGadgetState(G_Speed, 100)
                LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set speed 100")
            EndSelect

          Case G_Power, G_BottomPower
            If OMSX_PowerKnown And OMSX_PowerOn
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set power off")
            Else
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set power on")
            EndIf

          Case G_Reset
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "reset")

          Case G_Pause
            If OMSX_PausedKnown And OMSX_Paused
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set pause off")
            Else
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set pause on")
            EndIf

          Case G_Firmware
            If OMSX_FirmwareKnown And OMSX_FirmwareOn
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set firmwareswitch off")
            Else
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set firmwareswitch on")
            EndIf

          Case G_Rensha
            If OMSX_RenshaKnown And OMSX_RenshaOn
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set renshaturbo 0")
            Else
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set renshaturbo 100")
            EndIf

          Case G_Joy1
            Protected Pl1.s = OMSXGui_JoyPluggableName(GetGadgetState(G_Joy1))
            If Pl1 = ""
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "unplug joyporta")
            Else
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "plug joyporta " + Pl1)
            EndIf

          Case G_Joy2
            Protected Pl2.s = OMSXGui_JoyPluggableName(GetGadgetState(G_Joy2))
            If Pl2 = ""
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "unplug joyportb")
            Else
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "plug joyportb " + Pl2)
            EndIf

          Case G_Renderer
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set renderer " + GetGadgetText(G_Renderer))

          Case G_Scale
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set scale_factor " + GetGadgetText(G_Scale))

          Case G_VSync
            If OMSX_VSyncKnown And OMSX_VSyncOn
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set vsync off")
            Else
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set vsync on")
            EndIf

          Case G_TvMode
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set scale_algorithm " + GetGadgetText(G_TvMode))

          Case G_Deinterlace
            If OMSX_DeinterlaceKnown And OMSX_DeinterlaceOn
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set deinterlace off")
            Else
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set deinterlace on")
            EndIf

          Case G_LimitSprites
            If OMSX_LimitSpritesKnown And OMSX_LimitSpritesOn
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set limitsprites off")
            Else
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set limitsprites on")
            EndIf

          Case G_Fullscreen
            If OMSX_FullscreenKnown And OMSX_FullscreenOn
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set fullscreen off")
            Else
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set fullscreen on")
            EndIf

          Case G_DisableSprites
            If OMSX_DisableSpritesKnown And OMSX_DisableSpritesOn
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set disablesprites off")
            Else
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set disablesprites on")
            EndIf

          Case G_VideoSource
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set videosource " + GetGadgetText(G_VideoSource))

          Case G_Scanline
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set scanline " + Str(GetGadgetState(G_Scanline)))
          Case G_ScanlineReset
            SetGadgetState(G_Scanline, 20)
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set scanline 20")

          Case G_Blur
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set blur " + Str(GetGadgetState(G_Blur)))
          Case G_BlurReset
            SetGadgetState(G_Blur, 50)
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set blur 50")

          Case G_Glow
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set glow " + Str(GetGadgetState(G_Glow)))
          Case G_GlowReset
            SetGadgetState(G_Glow, 0)
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set glow 0")

          Case G_Gamma
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set gamma " + StrF(GetGadgetState(G_Gamma) / 10.0, 1))
          Case G_GammaReset
            SetGadgetState(G_Gamma, 11)
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set gamma 1.1")

          Case G_Noise
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set noise " + Str(GetGadgetState(G_Noise)))
          Case G_NoiseReset
            SetGadgetState(G_Noise, 0)
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set noise 0")

          Case G_ShotDirBrowse
            PickPath = PathRequester("Selecione o diretorio para salvar screenshots", GetGadgetText(G_ShotDir))
            If PickPath <> "" : SetGadgetText(G_ShotDir, PickPath) : EndIf

          Case G_ShotTake
            Protected ShotBase.s = Trim(GetGadgetText(G_ShotName))
            If ShotBase = "" : ShotBase = "screenshot" : EndIf
            Protected ShotDirVal.s = Trim(GetGadgetText(G_ShotDir))
            If ShotDirVal <> "" And FileSize(ShotDirVal) = -2
              If Right(ShotDirVal, 1) <> "\" And Right(ShotDirVal, 1) <> "/"
                ShotDirVal + "\"
              EndIf
              Protected NextNum.i = OMSXGui_NextShotNumber(ShotDirVal, ShotBase)
              Protected ShotFile.s = ShotDirVal + ShotBase + RSet(Str(NextNum), 4, "0") + ".png"
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "screenshot " + Chr(34) + ShotFile + Chr(34))
            Else
              ; sem diretorio valido escolhido - usa a pasta padrao do
              ; openMSX (screenshots/) com numeracao sequencial nativa dele
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "screenshot -prefix " + Chr(34) + ShotBase + Chr(34))
            EndIf

          Case G_Stop
            LogAccum = OMSXGui_AppendLog(G_Log, LogAccum, "> [STOP]")
            OMSX_PressStop()

          Case G_DeviceAdd
            Protected AddName.s = Trim(GetGadgetText(G_DeviceAddName))
            If AddName <> ""
              LogAccum = OMSXGui_AppendLog(G_Log, LogAccum, "--- procurando dispositivo " + Chr(34) + AddName + Chr(34) + " ---")
              OMSX_QueryDevice(AddName)
              SetGadgetText(G_DeviceAddName, "")
            EndIf

          Case G_DeviceList
            ; sincronizado de verdade no timer de poll (le do Map) - aqui so
            ; evita esperar o proximo tick pra atualizar o nome mostrado.
            Protected SelDevNow.s = OMSXGui_SelectedDevice(G_DeviceList)
            If SelDevNow <> ""
              SetGadgetText(G_DeviceSelName, SelDevNow)
            EndIf

          Case G_DevVolume
            Protected VolDev.s = OMSXGui_SelectedDevice(G_DeviceList)
            If VolDev <> ""
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set " + Chr(34) + VolDev + "_volume" + Chr(34) + " " + Str(GetGadgetState(G_DevVolume)))
            EndIf

          Case G_DevBalance
            Protected BalDev.s = OMSXGui_SelectedDevice(G_DeviceList)
            If BalDev <> ""
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set " + Chr(34) + BalDev + "_balance" + Chr(34) + " " + Str(GetGadgetState(G_DevBalance)))
            EndIf

          Case G_DevMute
            Protected MuteDev.s = OMSXGui_SelectedDevice(G_DeviceList)
            If MuteDev <> ""
              SetGadgetState(G_DevVolume, 0)
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set " + Chr(34) + MuteDev + "_volume" + Chr(34) + " 0")
            EndIf

          Case G_MidiInBrowse
            PickPath = OpenFileRequester("Selecione o arquivo MIDI", GetGadgetText(G_MidiInPath),
                                         "Arquivos MIDI (*.mid)|*.mid|Todos os arquivos (*.*)|*.*", 0)
            If PickPath <> "" : SetGadgetText(G_MidiInPath, PickPath) : EndIf

          Case G_MidiInConnect
            If OMSX_MidiInConnector = ""
              OMSX_QueryMidiConnectors()
              LogAccum = OMSXGui_AppendLog(G_Log, LogAccum, "--- procurando conector MIDI IN, tente de novo em 1s ---")
            ElseIf Trim(GetGadgetText(G_MidiInPath)) <> ""
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set midi-in-readfilename " + Chr(34) + GetGadgetText(G_MidiInPath) + Chr(34))
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "plug " + Chr(34) + OMSX_MidiInConnector + Chr(34) + " midi-in-reader")
            EndIf

          Case G_MidiInDisconnect
            If OMSX_MidiInConnector <> ""
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "unplug " + Chr(34) + OMSX_MidiInConnector + Chr(34))
            EndIf

          Case G_MidiOutBrowse
            PickPath = SaveFileRequester("Selecione o arquivo de log MIDI", GetGadgetText(G_MidiOutPath),
                                         "Arquivos MIDI (*.mid)|*.mid|Todos os arquivos (*.*)|*.*", 0)
            If PickPath <> "" : SetGadgetText(G_MidiOutPath, PickPath) : EndIf

          Case G_MidiOutConnect
            If OMSX_MidiOutConnector = ""
              OMSX_QueryMidiConnectors()
              LogAccum = OMSXGui_AppendLog(G_Log, LogAccum, "--- procurando conector MIDI OUT, tente de novo em 1s ---")
            ElseIf Trim(GetGadgetText(G_MidiOutPath)) <> ""
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "set midi-out-logfilename " + Chr(34) + GetGadgetText(G_MidiOutPath) + Chr(34))
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "plug " + Chr(34) + OMSX_MidiOutConnector + Chr(34) + " midi-out-logger")
            EndIf

          Case G_MidiOutDisconnect
            If OMSX_MidiOutConnector <> ""
              LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "unplug " + Chr(34) + OMSX_MidiOutConnector + Chr(34))
            EndIf

          Case G_AudioLog
            LogAccum = OMSXGui_SendLogged(G_Log, LogAccum, "soundlog")

          Case G_TypeGo
            Protected TypeText.s = GetGadgetText(G_TypeInput)
            If Trim(TypeText) <> ""
              LogAccum = OMSXGui_AppendLog(G_Log, LogAccum, "> [digitando " + Str(Len(TypeText)) + " caracteres no MSX]")
              OMSX_TypeTextWithTags(TypeText)
            EndIf

          Case G_TypeClear
            SetGadgetText(G_TypeInput, "")

          Case G_ComboToggle
            If ComboMode
              ComboMode = #False
            Else
              ComboMode = #True
            EndIf
            If ComboMode
              OMSXGui_SetButtonText(G_ComboToggle, 160, 28, "Modo Combo: ON")
            Else
              OMSXGui_SetButtonText(G_ComboToggle, 160, 28, "Modo Combo: OFF")
              ClearList(ComboPendingNames())
              SetGadgetText(G_ComboLabel, "Combo: (vazio)")
            EndIf

          Case G_ComboInsert
            If ListSize(ComboPendingNames()) > 0
              OMSXGui_InsertTagAtCursor(G_TypeInput, Chr($27E6) + OMSXGui_JoinList(ComboPendingNames(), "+") + Chr($27E7))
              ClearList(ComboPendingNames())
              SetGadgetText(G_ComboLabel, "Combo: (vazio)")
            EndIf

          Case G_ComboCancel
            ClearList(ComboPendingNames())
            SetGadgetText(G_ComboLabel, "Combo: (vazio)")

          Case G_Help
            OpenMsxHelp_OpenWindow(Win)

          Case G_Close
            Quit = #True
        EndSelect

      Case #PB_Event_Timer
        If EventTimer() = #OMSXGui_PollTimer
          If OMSX_IsRunning()
            Protected PollResult.s = OMSX_Poll()
            LogAccum = OMSXGui_AppendLog(G_Log, LogAccum, PollResult)
            ; Aba "Status Info" - stream VERBOSO (OMSX_LastVerboseChunk, ver
            ; OMSX_Poll() em OpenMSXBridge.pbi): tudo que o openMSX manda,
            ; mudou por nosso comando ou nao, SEM os ecos "> comando" (esses
            ; ficam so no Console, sao especificos da sessao interativa, nao
            ; "status que aconteceu"). A resposta crua de "openmsx_info fps"
            ; fica de fora dos DOIS logs (Console e Status Info) desde
            ; 2026-08-20 - ja tem o display dedicado da barra inferior
            ; (G_FpsDisplayBottom), poluia tambem o Status Info em tempo
            ; real, mesmo depois do display existir.
            StatusLogAccum = OMSXGui_AppendLog(G_StatusLog, StatusLogAccum, OMSX_LastVerboseChunk)
            SetGadgetText(G_Status, "Estado: " + OMSX_StatusText())

            If OMSX_SpeedKnown
              SetGadgetState(G_Speed, OMSX_Speed)
              SetGadgetText(G_SpeedLabel, Str(OMSX_Speed) + "%")
            EndIf
            If OMSX_PowerKnown
              If OMSX_PowerOn
                OMSXGui_SetButtonText(G_Power, 130, 28, "Power: Ligado")
                OMSXGui_SetButtonText(G_BottomPower, 130, 30, "Power: Ligado")
              Else
                OMSXGui_SetButtonText(G_Power, 130, 28, "Power: Desligado")
                OMSXGui_SetButtonText(G_BottomPower, 130, 30, "Power: Desligado")
              EndIf
            EndIf
            If OMSX_PausedKnown
              If OMSX_Paused : OMSXGui_SetButtonText(G_Pause, 130, 28, "Pause: Pausado") : Else : OMSXGui_SetButtonText(G_Pause, 130, 28, "Pause: Rodando") : EndIf
            EndIf
            If OMSX_FirmwareKnown
              If OMSX_FirmwareOn : OMSXGui_SetButtonText(G_Firmware, 220, 28, "Firmware: Ligado") : Else : OMSXGui_SetButtonText(G_Firmware, 220, 28, "Firmware: Desligado") : EndIf
            EndIf
            If OMSX_RenshaKnown
              If OMSX_RenshaOn : OMSXGui_SetButtonText(G_Rensha, 220, 28, "Ren Sha Turbo: Ligado") : Else : OMSXGui_SetButtonText(G_Rensha, 220, 28, "Ren Sha Turbo: Desligado") : EndIf
            EndIf

            ; Aba "Video" - mesmo padrao: botao de toggle mostra o estado
            ; real, trackbar/label seguem o valor atual (idempotente durante
            ; arraste manual, ja que cada posicao nova ja manda "set X val"
            ; e o eco que volta so confirma o mesmo valor).
            If OMSX_VSyncKnown
              If OMSX_VSyncOn : OMSXGui_SetButtonText(G_VSync, 100, 26, "VSync: Ligado") : Else : OMSXGui_SetButtonText(G_VSync, 100, 26, "VSync: Desligado") : EndIf
            EndIf
            If OMSX_ScaleAlgorithmKnown
              Select OMSX_ScaleAlgorithm
                Case "simple"     : SetGadgetState(G_TvMode, 0)
                Case "ScaleNx"    : SetGadgetState(G_TvMode, 1)
                Case "hq"         : SetGadgetState(G_TvMode, 2)
                Case "RGBtriplet" : SetGadgetState(G_TvMode, 3)
                Case "TV"         : SetGadgetState(G_TvMode, 4)
              EndSelect
            EndIf
            If OMSX_DeinterlaceKnown
              If OMSX_DeinterlaceOn : OMSXGui_SetButtonText(G_Deinterlace, 140, 26, "Deinterlace: Ligado") : Else : OMSXGui_SetButtonText(G_Deinterlace, 140, 26, "Deinterlace: Desligado") : EndIf
            EndIf
            If OMSX_LimitSpritesKnown
              If OMSX_LimitSpritesOn : OMSXGui_SetButtonText(G_LimitSprites, 150, 26, "Limitar sprites: Ligado") : Else : OMSXGui_SetButtonText(G_LimitSprites, 150, 26, "Limitar sprites: Desligado") : EndIf
            EndIf
            If OMSX_FullscreenKnown
              If OMSX_FullscreenOn : OMSXGui_SetButtonText(G_Fullscreen, 120, 26, "Tela cheia: Ligado") : Else : OMSXGui_SetButtonText(G_Fullscreen, 120, 26, "Tela cheia: Desligado") : EndIf
            EndIf
            If OMSX_DisableSpritesKnown
              If OMSX_DisableSpritesOn : OMSXGui_SetButtonText(G_DisableSprites, 170, 26, "Desabilitar sprites: Ligado") : Else : OMSXGui_SetButtonText(G_DisableSprites, 170, 26, "Desabilitar sprites: Desligado") : EndIf
            EndIf

            If OMSX_ScanlineKnown
              SetGadgetState(G_Scanline, OMSX_Scanline)
              SetGadgetText(G_ScanlineLabel, Str(OMSX_Scanline))
            EndIf
            If OMSX_BlurKnown
              SetGadgetState(G_Blur, OMSX_Blur)
              SetGadgetText(G_BlurLabel, Str(OMSX_Blur))
            EndIf
            If OMSX_GlowKnown
              SetGadgetState(G_Glow, OMSX_Glow)
              SetGadgetText(G_GlowLabel, Str(OMSX_Glow))
            EndIf
            If OMSX_GammaKnown
              SetGadgetState(G_Gamma, Round(ValF(OMSX_Gamma) * 10, #PB_Round_Nearest))
              SetGadgetText(G_GammaLabel, OMSX_Gamma)
            EndIf
            If OMSX_NoiseKnown
              SetGadgetState(G_Noise, OMSX_Noise)
              SetGadgetText(G_NoiseLabel, Str(OMSX_Noise))
            EndIf

            OMSXGui_DrawLeds(G_Leds, OMSX_PowerKnown, OMSX_PowerOn,
                             OMSX_LedCapsKnown, OMSX_LedCapsOn,
                             OMSX_LedKanaKnown, OMSX_LedKanaOn,
                             OMSX_PausedKnown, OMSX_Paused,
                             OMSX_LedTurboKnown, OMSX_LedTurboOn,
                             OMSX_LedFddKnown, OMSX_LedFddOn)

            ; FPS: consulta sob demanda (nao e um "setting"), throttled a
            ; ~1x/segundo (a cada 6 ticks do timer de 150ms) - ver
            ; OMSX_QueryFps()/OMSX_AwaitingFps em OpenMSXBridge.pbi.
            FpsTick + 1
            If FpsTick >= 6
              FpsTick = 0
              OMSX_QueryFps()
            EndIf
            If OMSX_FpsKnown
              SetGadgetText(G_FpsLabel, "FPS: " + StrF(ValF(OMSX_Fps), 1))
              OMSXGui_DrawFpsDisplay(G_FpsDisplayBottom, "FPS: " + StrF(ValF(OMSX_Fps), 1))
            EndIf

            ; Aba "Volume" - reconstroi a lista so quando um dispositivo
            ; NOVO apareceu (OMSX_DeviceListDirty, ver OpenMSXBridge.pbi),
            ; preservando a selecao atual pelo NOME (o indice pode mudar,
            ; ja que a lista e reordenada em ordem alfabetica a cada
            ; reconstrucao).
            If OMSX_DeviceListDirty
              Protected PrevSelName.s = OMSXGui_SelectedDevice(G_DeviceList)
              Protected NewList DevNames.s()
              ForEach OMSX_DeviceVolume()
                AddElement(DevNames())
                DevNames() = MapKey(OMSX_DeviceVolume())
              Next
              SortList(DevNames(), #PB_Sort_Ascending | #PB_Sort_NoCase)
              ClearGadgetItems(G_DeviceList)
              Protected NewSelIndex.i = -1, DevIdx.i = 0
              ForEach DevNames()
                AddGadgetItem(G_DeviceList, -1, DevNames())
                If DevNames() = PrevSelName
                  NewSelIndex = DevIdx
                EndIf
                DevIdx + 1
              Next
              If NewSelIndex >= 0
                SetGadgetState(G_DeviceList, NewSelIndex)
              ElseIf CountGadgetItems(G_DeviceList) > 0
                SetGadgetState(G_DeviceList, 0)
              EndIf
              OMSX_DeviceListDirty = #False
            EndIf

            ; Sincroniza Volume/Balance com o dispositivo ATUALMENTE
            ; selecionado - idempotente durante arraste manual, mesmo
            ; motivo de sempre (o eco que volta so confirma o valor que a
            ; gente acabou de mandar).
            Protected SelDevPoll.s = OMSXGui_SelectedDevice(G_DeviceList)
            If SelDevPoll <> ""
              SetGadgetText(G_DeviceSelName, SelDevPoll)
              If FindMapElement(OMSX_DeviceVolume(), SelDevPoll)
                SetGadgetState(G_DevVolume, OMSX_DeviceVolume())
                SetGadgetText(G_DevVolumeLabel, Str(OMSX_DeviceVolume()))
              EndIf
              If FindMapElement(OMSX_DeviceBalance(), SelDevPoll)
                SetGadgetState(G_DevBalance, OMSX_DeviceBalance())
                SetGadgetText(G_DevBalanceLabel, Str(OMSX_DeviceBalance()))
              EndIf
            Else
              SetGadgetText(G_DeviceSelName, "(nenhum)")
            EndIf

            If OMSX_MidiInConnector <> ""
              SetGadgetText(G_MidiInStatus, "Conector MIDI IN: " + OMSX_MidiInConnector)
            EndIf
            If OMSX_MidiOutConnector <> ""
              SetGadgetText(G_MidiOutStatus, "Conector MIDI OUT: " + OMSX_MidiOutConnector)
            EndIf

            ; "-machine"/"-ext" so valem no lancamento (ver OMSX_LaunchedMachine/
            ; Extension, OpenMSXBridge.pbi) - avisa se o que esta configurado
            ; agora diverge do que esta rodando, ja que so "Reiniciar openMSX"
            ; aplica uma mudanca dessas de verdade.
            If BadigCfg\EmMachine <> OMSX_LaunchedMachine Or BadigCfg\EmExtensionA <> OMSX_LaunchedExtensionA Or
               BadigCfg\EmExtensionB <> OMSX_LaunchedExtensionB Or BadigCfg\EmExtensionC <> OMSX_LaunchedExtensionC Or
               BadigCfg\EmExtensionD <> OMSX_LaunchedExtensionD
              SetGadgetText(G_MismatchWarn, "Maquina/extensao mudou em Configurar -> openMSX... - clique " + Chr(34) + "Reiniciar openMSX" + Chr(34) + " pra aplicar.")
            Else
              SetGadgetText(G_MismatchWarn, "")
            EndIf
          Else
            LogAccum = OMSXGui_AppendLog(G_Log, LogAccum, "--- openMSX foi encerrado ---")
            StatusLogAccum = OMSXGui_AppendLog(G_StatusLog, StatusLogAccum, "--- openMSX foi encerrado ---")
            SetGadgetText(G_Status, "Estado: openMSX encerrado")
            SetGadgetText(G_MismatchWarn, "")
            OMSXGui_SetButtonText(G_BottomPower, 130, 30, "Power: ?")
            OMSXGui_DrawFpsDisplay(G_FpsDisplayBottom, "FPS: --")
            DisableGadget(G_BottomPower, #True)
            DisableGadget(G_Input, #True)
            DisableGadget(G_Send, #True)
            DisableGadget(G_ShowWindow, #True)
            DisableGadget(G_DiskInsert, #True)
            DisableGadget(G_DiskEject, #True)
            DisableGadget(G_CartInsert, #True)
            DisableGadget(G_CartEject, #True)
            DisableGadget(G_CasInsert, #True)
            DisableGadget(G_CasEject, #True)
            DisableGadget(G_Speed, #True)
            DisableGadget(G_Speed100, #True)
            DisableGadget(G_Power, #True)
            DisableGadget(G_Reset, #True)
            DisableGadget(G_Pause, #True)
            DisableGadget(G_Firmware, #True)
            DisableGadget(G_Rensha, #True)
            DisableGadget(G_Joy1, #True)
            DisableGadget(G_Joy2, #True)
            DisableGadget(G_Renderer, #True)
            DisableGadget(G_Scale, #True)
            DisableGadget(G_VSync, #True)
            DisableGadget(G_TvMode, #True)
            DisableGadget(G_Deinterlace, #True)
            DisableGadget(G_LimitSprites, #True)
            DisableGadget(G_Fullscreen, #True)
            DisableGadget(G_DisableSprites, #True)
            DisableGadget(G_VideoSource, #True)
            DisableGadget(G_Scanline, #True)
            DisableGadget(G_ScanlineReset, #True)
            DisableGadget(G_Blur, #True)
            DisableGadget(G_BlurReset, #True)
            DisableGadget(G_Glow, #True)
            DisableGadget(G_GlowReset, #True)
            DisableGadget(G_Gamma, #True)
            DisableGadget(G_GammaReset, #True)
            DisableGadget(G_Noise, #True)
            DisableGadget(G_NoiseReset, #True)
            DisableGadget(G_ShotTake, #True)
            DisableGadget(G_ShotDirBrowse, #True)
            DisableGadget(G_Stop, #True)
            DisableGadget(G_DeviceAdd, #True)
            DisableGadget(G_DevVolume, #True)
            DisableGadget(G_DevBalance, #True)
            DisableGadget(G_DevMute, #True)
            DisableGadget(G_MidiInBrowse, #True)
            DisableGadget(G_MidiInConnect, #True)
            DisableGadget(G_MidiInDisconnect, #True)
            DisableGadget(G_MidiOutBrowse, #True)
            DisableGadget(G_MidiOutConnect, #True)
            DisableGadget(G_MidiOutDisconnect, #True)
            DisableGadget(G_AudioLog, #True)
            DisableGadget(G_TypeGo, #True)
            RemoveWindowTimer(Win, #OMSXGui_PollTimer)
          EndIf
        EndIf

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  If OMSX_IsRunning()
    RemoveWindowTimer(Win, #OMSXGui_PollTimer)
  EndIf
  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
