;
; ------------------------------------------------------------
;  Apelido interno: Pteranodonte (tema pre-historico do projeto, ver README.md)
;  OpenMSXBridge.pbi - ponte com o openMSX pra controle externo (menu
;  "Executar -> openMSX", janela em OpenMSXConsoleGui.pbi).
;
;  Historico curto (por que isto NAO usa "-control stdio"): a primeira
;  versao usava "-control stdio" + RunProgram(...#PB_Program_Write) pra
;  escrever comandos no stdin do processo, seguindo a doc oficial
;  "Controlling openMSX from External Applications". Nao funcionou -
;  nenhum comando surtia efeito, nem resposta nenhuma no log (so o boot
;  default do openMSX, independente do nosso lado do pipe). Lendo o
;  Catapult de verdade (openmsx/catapult/src/openMSXController.cpp,
;  Launch(), bloco #ifdef __WXMSW__) ficou claro o motivo: NO WINDOWS, o
;  proprio Catapult NUNCA usa "-control stdio" - ele usa
;  "-control pipe:<nome>" (um NAMED PIPE dedicado so pra comandos de
;  entrada) e mantem STDOUT/STDERR normais (via pipe anonimo comum,
;  CreateProcess+STARTF_USESTDHANDLES) so pra ler respostas/log. Ou seja: a
;  metade "escrever no stdin" do protocolo "-control stdio" e a que nao e
;  confiavel no Windows (motivo exato nao documentado nem no codigo do
;  Catapult, so o workaround) - a metade "ler do stdout" continua normal
;  (mesmo RunProgram(...#PB_Program_Read|Error) que ja usavamos).
;
;  Reescrito aqui pra seguir exatamente esse padrao: comandos saem por um
;  named pipe que ABRIMOS NOS MESMOS (CreateNamedPipe_ com
;  PIPE_ACCESS_OUTBOUND - so escrita, mesma direcao que o Catapult usa),
;  openMSX conecta nele sozinho ao processar "-control pipe:<nome>"
;  (CliConnection.cc, PipeConnection::PipeConnection() abre o pipe como
;  cliente via CreateFileA) - e so RunProgram(...#PB_Program_Read|Error)
;  pra ler as respostas/log, sem #PB_Program_Write nenhum (nao mexemos no
;  stdin de verdade do processo).
;
;  ConnectNamedPipe_() bloqueia ate o openMSX conectar - roda numa
;  CreateThread() dedicada (mesma ideia exata de
;  openmsx/catapult/src/PipeConnectThread.cpp) pra nao travar a GUI
;  enquanto o openMSX ainda esta subindo.
; ------------------------------------------------------------
;

#PIPE_ACCESS_OUTBOUND = $00000002
#OMSX_PipeType_Byte    = $00000000
#OMSX_PipeMode_Wait    = $00000000
#OMSX_PipeBufSize      = 8192

Global OMSX_Prog.i = 0
Global OMSX_PipeHandle.i = 0
Global OMSX_PipeConnected.b = #False
Global OMSX_PipeThread.i = 0
Global OMSX_LaunchCounter.i = 0

; Estado ao vivo (Ligado/Pausado) - alimentado por "<update type="setting" ...>", NAO por
; reply de comando. Ver comentario de OMSX_PipeConnectThread() ("openmsx_update enable
; setting"): diferente de so ler a resposta do comando que A GENTE mandou (que fica muda
; se o estado mudar por outro caminho - tecla de pause dentro da janela do openMSX, script
; Tcl, etc.), isso reflete QUALQUER mudanca de "power"/"pause", nao só a nossa própria.
; "*Known" comeca #False porque nao sabemos o estado real ate a primeira atualizacao chegar
; (o boot manda "set power on" mas a confirmacao só vem depois, de forma assíncrona).
Global OMSX_PowerKnown.b = #False
Global OMSX_PowerOn.b = #False
Global OMSX_PausedKnown.b = #False
Global OMSX_Paused.b = #False

; Mesma ideia (alimentado por "<update type="setting" ...>", nao por reply de
; comando - ver OMSX_Poll()) pros controles da aba "Outros comandos"
; (OpenMSXConsoleGui.pbi): velocidade de emulacao ("speed", 1-9999%),
; interruptor de firmware residente ("firmwareswitch", so existe em algumas
; maquinas) e Ren Sha Turbo ("renshaturbo", 0-100, so existe em maquinas com
; suporte de hardware - turboR etc.). "*Known" comeca #False pelo mesmo
; motivo de OMSX_PowerKnown: nao sabemos o valor real ate a primeira
; atualizacao chegar.
Global OMSX_SpeedKnown.b = #False
Global OMSX_Speed.i = 100
Global OMSX_FirmwareKnown.b = #False
Global OMSX_FirmwareOn.b = #False
Global OMSX_RenshaKnown.b = #False
Global OMSX_RenshaOn.b = #False

; LEDs da aba "Video" (OpenMSXConsoleGui.pbi) - "power" e "pause" reaproveitam
; OMSX_PowerOn/OMSX_Paused acima (mesmo settings, ja rastreados: ligar a
; maquina ou pausar TAMBEM acende o LED correspondente, nao sao coisas
; separadas). Caps/Kana/Turbo/FDD sao read-only (o openMSX que controla,
; nunca setados por nos) mas passam pelo MESMO mecanismo de "<update
; type="setting">" que tudo mais aqui - simples questao de assinar o nome
; certo.
Global OMSX_LedCapsKnown.b = #False
Global OMSX_LedCapsOn.b = #False
Global OMSX_LedKanaKnown.b = #False
Global OMSX_LedKanaOn.b = #False
Global OMSX_LedTurboKnown.b = #False
Global OMSX_LedTurboOn.b = #False
Global OMSX_LedFddKnown.b = #False
Global OMSX_LedFddOn.b = #False

; FPS (aba "Video") - NAO e um "setting" (nao vem via "openmsx_update"), e
; uma estatistica de execucao consultada sob demanda com "openmsx_info fps".
; Como o protocolo daqui e "fire and forget" (sem id de correlacao
; comando->resposta), OMSX_AwaitingFps marca "a proxima linha <reply> que
; chegar e a resposta dessa consulta" - funciona bem desde que ninguem mais
; mande outro comando bem no meio (mesma suposicao de ordem serial que o
; resto da ponte ja faz implicitamente). Quem dispara a consulta
; periodicamente e a GUI (nao aqui, pra nao gerar trafego sem ninguem
; pedindo) - ver OMSX_QueryFps().
Global OMSX_FpsKnown.b = #False
Global OMSX_Fps.s = ""
Global OMSX_AwaitingFps.b = #False

; Preenchido por OMSX_Poll() a cada chamada com TUDO que chegou nesse tick,
; sem nenhum filtro (inclusive a resposta crua de "openmsx_info fps") - ver
; comentario dentro de OMSX_Poll() pra por que a resposta do FPS e suprimida
; do valor de RETORNO da funcao (usado pelo log conciso da aba "Console") mas
; nao deste global (usado pelo log verboso da aba "Status Info"). Global em
; vez de um out-parameter *Ptr.String de proposito - ver nota sobre o bug de
; crash de out-parameters .String neste codebase (CLAUDE.md/SPEC.md modulo
; sobre o disassembler do Mamute).
Global OMSX_LastVerboseChunk.s = ""

; Toggles da aba "Video" (OpenMSXConsoleGui.pbi) - mesmo mecanismo de
; sempre ("<update type="setting">", ver OMSX_Poll()). OMSX_TvModeOn e
; derivado da string de "scale_algorithm" (nao um bool nativo do openMSX):
; #True quando o valor atual e exatamente "TV" (ver RenderSettings.cc real -
; "simple"/"ScaleNx"/"hq"/"RGBtriplet"/"TV" sao os valores possiveis, so
; expomos o toggle simple<->TV pedido, nao o combo completo).
Global OMSX_VSyncKnown.b = #False
Global OMSX_VSyncOn.b = #False
; "Modo TV" virou dropdown de verdade (pedido explicito do usuario, "como no
; Catapult") com as 5 opcoes reais de scale_algorithm (simple/ScaleNx/hq/
; RGBtriplet/TV, ver RenderSettings.cc do openMSX) em vez de um toggle
; simple<->TV so - guarda a string crua, nao um booleano.
Global OMSX_ScaleAlgorithmKnown.b = #False
Global OMSX_ScaleAlgorithm.s = "simple"
Global OMSX_DeinterlaceKnown.b = #False
Global OMSX_DeinterlaceOn.b = #False
Global OMSX_LimitSpritesKnown.b = #False
Global OMSX_LimitSpritesOn.b = #False
Global OMSX_FullscreenKnown.b = #False
Global OMSX_FullscreenOn.b = #False
Global OMSX_DisableSpritesKnown.b = #False
Global OMSX_DisableSpritesOn.b = #False

; Barras estilo CRT da aba "Video" - mesmo mecanismo, sincroniza o valor
; real (idempotente durante arraste manual - ver comentario no timer de
; poll, OpenMSXConsoleGui.pbi). Gamma fica como STRING (nao Int) porque e
; float ("1.10" etc.) - convertido pra posicao de trackbar (*10) so na hora
; de exibir, ver OMSXGui_OpenWindow().
Global OMSX_ScanlineKnown.b = #False
Global OMSX_Scanline.i = 20
Global OMSX_BlurKnown.b = #False
Global OMSX_Blur.i = 50
Global OMSX_GlowKnown.b = #False
Global OMSX_Glow.i = 0
Global OMSX_GammaKnown.b = #False
Global OMSX_Gamma.s = "1.1"
Global OMSX_NoiseKnown.b = #False
Global OMSX_Noise.i = 0

; Dispositivos de som da aba "Volume" (OpenMSXConsoleGui.pbi) - descobertos
; DINAMICAMENTE, nunca por nome fixo. Confirmado ao vivo contra um openMSX de
; verdade (2026-08-08): so "PSG" e "keyclick" sao nomes fixos - qualquer
; outro dispositivo (SCC+, MSX-MUSIC/FM-PAC, MoonSound FM/wave, MSX-AUDIO,
; cassete, DAC de cartucho) usa o nome comercial COMPLETO do hardware
; especifico conectado (ex.: "Konami SCC+ Cartridge with expanded RAM (1)",
; "Sunrise MoonSound (1) FM") - varia por ROM/config/quantidade de
; instancias, entao fixar sliders por nome simplesmente nao funcionaria.
; Em vez disso, qualquer "<update type="setting" name="X_volume">" que
; chegar (todo device de som manda isso assim que existe, ja que
; "openmsx_update enable setting" - assinado no boot - cobre TODOS os
; settings, nao so os que a gente conhece de antemao) vira uma entrada no
; Map abaixo, keyed pelo nome real do dispositivo. OMSX_DeviceListDirty
; avisa a GUI que a lista mudou (dispositivo novo apareceu) pra ela
; reconstruir o ListView so quando precisa, nao a cada tick.
Global NewMap OMSX_DeviceVolume.i()
Global NewMap OMSX_DeviceBalance.i()
Global OMSX_DeviceListDirty.b = #False

; Conectores MIDI (aba "Volume") - MESMO problema dos dispositivos de som:
; nao sao nomes fixos tipo "midi-in"/"midi-out" (confirmado ao vivo: nesta
; maquina sao "Generic MSX-Audio-MIDI-in"/"...-MIDI-out", nomes do hardware
; especifico). Descobertos com UMA consulta "plug" (lista todos os
; conectores) ao abrir a aba - ver OMSX_QueryMidiConnectors()/
; OMSX_FindConnectorByName() mais abaixo.
Global OMSX_MidiInConnector.s = ""
Global OMSX_MidiOutConnector.s = ""
Global OMSX_AwaitingPlugList.b = #False

; "Adicionar dispositivo" manual (aba "Volume") - consultar "set
; NOME_volume" (SEM valor - so LEITURA, nao muda nada) nao dispara
; "<update>" nenhum (confirmado ao vivo: so mudancas de verdade notificam,
; nao consultas), entao a descoberta passiva sozinha tem um problema de
; "ovo e galinha" no boot (nada mudou ainda, lista fica vazia pra sempre).
; Isto complementa com consulta ativa sob demanda pra UM nome que o usuario
; digitou (descoberto por ele via o proprio menu do openMSX, "Mostrar
; ajustes dos chips de som", ja que os nomes variam por cartucho - ver
; comentario de OMSX_DeviceVolume() acima). Funcao em si fica perto de
; OMSX_QueryFps()/OMSX_QueryMidiConnectors() mais abaixo (precisa de
; OMSX_IsRunning() ja definida).
Global OMSX_AwaitingDeviceQuery.s = ""

; Caminho de um .dsk pendente de carregar assim que o pipe conectar - ver
; OMSX_LoadDisk() e o final de OMSX_PipeConnectThread() (mesma logica ja
; usada pra sequencia de boot: nao da pra mandar comando nenhum antes do
; pipe conectar de verdade, entao um pedido feito nesse meio-tempo fica
; guardado aqui em vez de se perder).
Global OMSX_PendingDiskPath.s = ""

; Mesma ideia de OMSX_PendingDiskPath acima, mas pro comando OPENMSX do Mamute Assembler
; (MamuteGui_CmdOpenMSX(), MamuteAssemblerGui.pbi) - guarda um programa montado que precisou
; esperar o openMSX subir/conectar antes de poder ser transferido. OMSX_PendingMamuteAddr = -1
; quer dizer "nada pendente" (0 e' um endereco valido de verdade, por isso nao serve de
; sentinela). *OMSX_PendingMamuteBytes e' uma COPIA propria (AllocateMemory) - o *Payload de
; quem chama e' liberado logo depois da chamada, nao sobrevive ate o flush assincrono.
Global OMSX_PendingMamuteAddr.i = -1
Global *OMSX_PendingMamuteBytes = 0
Global OMSX_PendingMamuteByteCount.i = 0
Global OMSX_PendingMamuteAutoRun.b = #False

; Maquina/extensoes com que a instancia ATUAL foi de fato lancada (preenchido
; em OMSX_Start() so quando ele realmente sobe um processo novo, nao quando
; so reaproveita um ja rodando) - "-machine"/"-exta".."-extd" so valem no
; lancamento, entao isso serve pra comparar com BadigCfg\EmMachine/
; EmExtensionA..D e avisar o usuario se ele mudou a configuracao com o
; openMSX ja aberto (ver OpenMSXConsoleGui.pbi). Um Global por slot (nao um
; unico como antes) - 4 slots simultaneos de verdade, ver OMSX_BuildParams().
Global OMSX_LaunchedMachine.s = ""
Global OMSX_LaunchedExtensionA.s = ""
Global OMSX_LaunchedExtensionB.s = ""
Global OMSX_LaunchedExtensionC.s = ""
Global OMSX_LaunchedExtensionD.s = ""

; Usada por OMSX_ExtractAnySettingUpdate() - diferente de
; OMSX_ExtractSettingUpdate() (que so serve quando ja sabemos o nome exato
; do setting de antemao), extrai nome E valor de QUALQUER "<update
; type="setting">", pra descobrir dispositivos de som na hora (ver
; OMSX_DeviceVolume()/OMSX_DeviceBalance() acima).
Structure OMSX_SettingUpdate
  Name.s
  Value.s
EndStructure

Declare OMSX_SendCommand(Cmd.s)
Declare OMSX_ShowWindow()
Declare OMSX_FlushMamuteProgram(Addr.u, *Payload, ByteCount.i, AutoRun.b)

; Zera todo o estado ligado a UMA instancia do openMSX (handles, flags de
; conexao/power/pause, disco pendente) - usado tanto quando
; OMSX_IsRunning() detecta que o processo morreu por fora quanto por
; OMSX_Stop() (encerramento de proposito). NAO zera OMSX_Prog - quem chama
; decide isso (precisa do valor antigo pra CloseProgram() antes de zerar).
Procedure OMSX_ResetState()
  If OMSX_PipeHandle
    CloseHandle_(OMSX_PipeHandle)
    OMSX_PipeHandle = 0
  EndIf
  If OMSX_PipeThread
    CloseHandle_(OMSX_PipeThread)
    OMSX_PipeThread = 0
  EndIf
  OMSX_PipeConnected = #False
  OMSX_PowerKnown = #False
  OMSX_PausedKnown = #False
  OMSX_PendingDiskPath = ""
EndProcedure

; #True se o processo guardado em OMSX_Prog ainda esta vivo. Alem de
; consultar, tambem faz a faxina (fecha handles e zera estado) quando o
; openMSX ja morreu por fora (usuario fechou a janela do emulador, crash,
; etc.) - assim o resto do modulo nunca precisa checar isso duas vezes.
Procedure.b OMSX_IsRunning()
  If OMSX_Prog = 0
    ProcedureReturn #False
  EndIf
  If Not ProgramRunning(OMSX_Prog)
    CloseProgram(OMSX_Prog)
    OMSX_Prog = 0
    OMSX_ResetState()
    ProcedureReturn #False
  EndIf
  ProcedureReturn #True
EndProcedure

; Monta os parametros de linha de comando do openMSX a partir de BadigCfg\Em* - "-setting"/
; "-script" sao flags reais do openMSX (CommandLineParser.cc: "-setting", "-script", ambas
; BEFORE_SETTINGS), confirmado lendo o codigo-fonte vendorizado neste repo
; (openmsx/openmsx/src/CommandLineParser.cc). Extensoes: openMSX aceita ate 4 SLOTS
; simultaneos e independentes - "-exta"/"-extb"/"-extc"/"-extd" (mais um "-ext" generico de
; slot automatico que esta tela nao expoe, ver openmsx/openmsx/src/CliExtension.cc:
; `for (const auto* ext : {"-ext", "-exta", "-extb", "-extc", "-extd"})`) - nao "so disco",
; qualquer hardware de extensao real (bug de rotulo/campo unico corrigido nesta mesma sessao,
; pedido explicito do usuario: "o openmsx permite 4 extensões simultâneas, todas opcionais").
Procedure.s OMSX_BuildParams(PipeName.s)
  Protected Params.s = "-control pipe:" + PipeName + " "
  If BadigCfg\EmSetting <> ""
    Params + "-setting " + Chr(34) + BadigCfg\EmSetting + Chr(34) + " "
  EndIf
  If BadigCfg\EmScript <> ""
    Params + "-script " + Chr(34) + BadigCfg\EmScript + Chr(34) + " "
  EndIf
  If BadigCfg\EmMachine <> ""
    Params + "-machine " + Chr(34) + BadigCfg\EmMachine + Chr(34) + " "
  EndIf
  If BadigCfg\EmExtensionA <> ""
    Params + "-exta " + Chr(34) + BadigCfg\EmExtensionA + Chr(34) + " "
  EndIf
  If BadigCfg\EmExtensionB <> ""
    Params + "-extb " + Chr(34) + BadigCfg\EmExtensionB + Chr(34) + " "
  EndIf
  If BadigCfg\EmExtensionC <> ""
    Params + "-extc " + Chr(34) + BadigCfg\EmExtensionC + Chr(34) + " "
  EndIf
  If BadigCfg\EmExtensionD <> ""
    Params + "-extd " + Chr(34) + BadigCfg\EmExtensionD + Chr(34) + " "
  EndIf
  ProcedureReturn Params
EndProcedure

; Escreve bytes crus no named pipe de comando - usado tanto pelo handshake
; "<openmsx-control>" quanto por OMSX_SendCommand() (que so embrulha o
; texto em "<command>...</command>" antes de chamar isto).
Procedure OMSX_SendRaw(Text.s)
  If OMSX_PipeHandle = 0
    ProcedureReturn
  EndIf
  Protected *Buf = UTF8(Text)
  Protected BufLen = StringByteLength(Text, #PB_UTF8)
  Protected BytesWritten.l
  WriteFile_(OMSX_PipeHandle, *Buf, BufLen, @BytesWritten, #Null)
  FreeMemory(*Buf)
EndProcedure

; Roda numa thread a parte (ver comentario no topo do arquivo) - bloqueia
; em ConnectNamedPipe_() ate o openMSX (processo cliente) conectar nesse
; pipe, depois manda a sequencia de boot direto daqui (equivalente ao
; PostLaunch()/InitLaunchScript() do Catapult): handshake
; "<openmsx-control>", "unset renderer" (tira do renderer "none" que
; "-control" força por padrao - nome do renderer padrao varia entre builds
; do openMSX, entao reverter pro default e mais seguro que um nome fixo
; tipo "SDL"), "set power on" (a maquina fica desligada sob "-control",
; confirmado lendo CommandLineParser::parse()/main.cc do openMSX: o
; reactor.powerOn() so roda quando o parseStatus e RUN, nao CONTROL).
Procedure OMSX_PipeConnectThread(*Dummy)
  Protected Ok = ConnectNamedPipe_(OMSX_PipeHandle, #Null)
  ; ERROR_PIPE_CONNECTED (535): cliente ja tinha conectado antes desta
  ; chamada (corrida rara, mas nao e erro de verdade nesse caso).
  If Ok Or GetLastError_() = 535
    OMSX_PipeConnected = #True
    OMSX_SendRaw("<openmsx-control>" + Chr(10))
    ; Assina notificacoes de mudanca de qualquer "setting" (comando real do
    ; openMSX, GlobalCommandController.cc "openmsx_update enable <tipo>")
    ; ANTES do "set power on" abaixo, de proposito - assim ja capturamos a
    ; propria transicao de ligar no boot, nao so mudancas futuras. Sem isso,
    ; o unico jeito de saber se a maquina esta ligada/pausada e o reply
    ; direto de um comando que A GENTE mandou (fica cego se o estado mudar
    ; por outro caminho, ex. o usuario apertando pause na janela do proprio
    ; openMSX). Com a assinatura, toda mudanca de "power"/"pause" (nossa ou
    ; nao) chega como "<update type="setting" name="...">valor</update>" -
    ; ver OMSX_Poll()/OMSX_ExtractSettingUpdate().
    OMSX_SendCommand("openmsx_update enable setting")
    OMSX_SendCommand("unset renderer")
    OMSX_SendCommand("set power on")

    ; Disco pedido enquanto o openMSX ainda estava subindo (ver
    ; OMSX_LoadDisk()) - manda agora que a conexao de verdade acabou de
    ; completar, mesmo espirito da sequencia de boot acima.
    If OMSX_PendingDiskPath <> ""
      OMSX_SendCommand("diska insert " + Chr(34) + OMSX_PendingDiskPath + Chr(34))
      OMSX_SendCommand("reset")
      OMSX_PendingDiskPath = ""
    EndIf

    ; Mesma ideia acima, pro comando OPENMSX do Mamute Assembler (ver comentario do Global
    ; OMSX_PendingMamuteAddr, topo do arquivo).
    If OMSX_PendingMamuteAddr >= 0
      OMSX_FlushMamuteProgram(OMSX_PendingMamuteAddr, *OMSX_PendingMamuteBytes, OMSX_PendingMamuteByteCount, OMSX_PendingMamuteAutoRun)
      FreeMemory(*OMSX_PendingMamuteBytes)
      *OMSX_PendingMamuteBytes = 0
      OMSX_PendingMamuteAddr = -1
    EndIf
  EndIf
EndProcedure

; Abre o openMSX com o named pipe de comando ja criado ANTES do processo
; subir (precisa existir primeiro - o construtor de PipeConnection do
; openMSX tenta abrir o pipe como cliente assim que processa
; "-control pipe:<nome>" na linha de comando, e falha se o servidor - nos -
; ainda nao tiver criado). Reaproveita o processo atual se ja estiver
; rodando (#True direto, sem abrir um segundo). Nao mostra
; MessageRequester nenhum - quem chama decide como avisar o usuario (a
; janela de console, em OpenMSXConsoleGui.pbi, ja checa EmulatorPath antes
; de chegar aqui).
Procedure.b OMSX_Start()
  If OMSX_IsRunning()
    ProcedureReturn #True
  EndIf
  If BadigCfg\EmulatorPath = ""
    ProcedureReturn #False
  EndIf

  OMSX_LaunchCounter + 1
  ; Nome unico por lancamento (PID do editor + contador), mesma ideia do
  ; Catapult ("Catapult-<pid>-<contador>") - evita colisao entre duas
  ; instancias do editor ou dois "Executar -> openMSX" seguidos.
  Protected PipeName.s = "BadigEditorOMSX_" + Str(GetCurrentProcessId_()) + "_" + Str(OMSX_LaunchCounter)
  Protected FullPipePath.s = "\\.\pipe\" + PipeName

  OMSX_PipeHandle = CreateNamedPipe_(FullPipePath, #PIPE_ACCESS_OUTBOUND,
                                      #OMSX_PipeType_Byte | #OMSX_PipeMode_Wait,
                                      1, #OMSX_PipeBufSize, #OMSX_PipeBufSize, 0, #Null)
  If OMSX_PipeHandle = 0 Or OMSX_PipeHandle = -1
    OMSX_PipeHandle = 0
    ProcedureReturn #False
  EndIf

  Protected Params.s = OMSX_BuildParams(PipeName)
  OMSX_Prog = RunProgram(BadigCfg\EmulatorPath, Params, GetPathPart(BadigCfg\EmulatorPath),
                          #PB_Program_Open | #PB_Program_Read | #PB_Program_Error)
  If Not OMSX_Prog
    CloseHandle_(OMSX_PipeHandle)
    OMSX_PipeHandle = 0
    ProcedureReturn #False
  EndIf

  ; "-machine"/"-exta".."-extd" so valem no lancamento - guarda o que foi de
  ; fato usado pra dar pra comparar depois com BadigCfg\EmMachine/
  ; EmExtensionA..D (ver comentario dos globais, topo do arquivo).
  OMSX_LaunchedMachine = BadigCfg\EmMachine
  OMSX_LaunchedExtensionA = BadigCfg\EmExtensionA
  OMSX_LaunchedExtensionB = BadigCfg\EmExtensionB
  OMSX_LaunchedExtensionC = BadigCfg\EmExtensionC
  OMSX_LaunchedExtensionD = BadigCfg\EmExtensionD

  OMSX_PipeConnected = #False
  OMSX_PipeThread = CreateThread(@OMSX_PipeConnectThread(), 0)
  ProcedureReturn #True
EndProcedure

; Escapa "&"/"<"/">" como entidades XML antes de embrulhar em "<command>...</command>" -
; sem isso, um comando (ou texto digitado via OMSX_TypeText()) contendo esses caracteres
; quebra silenciosamente o parser real do openMSX. Confirmado lendo
; openmsx/openmsx/src/events/AdhocCliCommParser.cc: e uma maquina de estados byte-a-byte
; que, dentro de "<command>", trata "<" e "&" como inicio de tag/entidade - um "<" cru
; NAO seguido por "/command>" (ex. "IF X<10" colado de um listing BASIC) faz o parser
; voltar pro estado inicial "procurando <command>", **descartando** o resto do comando
; sem erro nenhum reportado. Mesma logica de escape que o Catapult de verdade usa
; (openmsx/catapult/src/openMSXController.cpp, WriteCommand(),
; "xmlEncodeEntitiesReentrant()") antes de mandar qualquer comando pelo pipe.
Procedure.s OMSX_XmlEscape(Text.s)
  Protected Escaped.s = Text
  Escaped = ReplaceString(Escaped, "&", "&amp;")
  Escaped = ReplaceString(Escaped, "<", "&lt;")
  Escaped = ReplaceString(Escaped, ">", "&gt;")
  ProcedureReturn Escaped
EndProcedure

Procedure OMSX_SendCommand(Cmd.s)
  If OMSX_IsRunning() And OMSX_PipeConnected And Trim(Cmd) <> ""
    OMSX_SendRaw("<command>" + OMSX_XmlEscape(Cmd) + "</command>" + Chr(10))
  EndIf
EndProcedure

; Escapa Text pra virar UMA "palavra" Tcl valida (nivel Tcl, ANTES do XML-escape acima,
; que e nivel transporte - as duas camadas juntas espelham exatamente o Catapult:
; utils::tclEscapeWord() + xmlEncodeEntitiesReentrant() em WriteCommand()). Preserva o
; conteudo literal (espacos, quebras de linha, chaves, etc.) escapando o que o parser Tcl
; do proprio comando (nao o parser XML) trataria como separador/especial dentro de
; "<command>...</command>". ORDEM IMPORTA: escapar a barra invertida primeiro, senao os
; escapes inseridos pelos passos seguintes seriam escapados de novo.
Procedure.s OMSX_TclEscapeWord(Text.s)
  Protected Escaped.s = Text
  Escaped = ReplaceString(Escaped, "\", "\\")
  ; CRLF (EditorGadget no Windows) -> um so marcador antes de virar "\r" (2 chars: barra +
  ; r) - o Tcl interpreta essa sequencia como um CR de verdade (Enter) ao "digitar",
  ; equivalente ao "\n" -> "\\r" do Catapult (wxTextCtrl la so usa "\n").
  Escaped = ReplaceString(Escaped, Chr(13) + Chr(10), Chr(10))
  Escaped = ReplaceString(Escaped, Chr(10), "\r")
  Escaped = ReplaceString(Escaped, "$", "\$")
  Escaped = ReplaceString(Escaped, Chr(34), "\" + Chr(34))
  Escaped = ReplaceString(Escaped, "[", "\[")
  Escaped = ReplaceString(Escaped, "]", "\]")
  Escaped = ReplaceString(Escaped, "}", "\}")
  Escaped = ReplaceString(Escaped, "{", "\{")
  Escaped = ReplaceString(Escaped, " ", "\ ")
  Escaped = ReplaceString(Escaped, ";", "\;")
  ProcedureReturn Escaped
EndProcedure

; Digita Text no MSX emulado, como se fosse teclado de verdade - mesmo mecanismo do
; Catapult (InputPage.cpp, OnTypeText(): "type -- " + tclEscapeWord(texto)). O comando
; "type" (script Tcl embutido no openMSX, share/scripts/type.tcl) delega por padrao pro
; comando nativo "type_via_keyboard" (Keyboard.cc, KeyInserter::execute()), que pressiona/
; solta teclas de verdade na matriz de teclado emulada - "\r" dentro do texto vira Enter.
; "--" avisa o parser de flags do openMSX (parseTclArgs) que acabaram as opcoes tipo
; "-freq"/"-release"/"-cancel", entao mesmo um texto comecando com "-" nao e confundido
; com uma flag.
Procedure OMSX_TypeText(Text.s)
  If Trim(Text) = ""
    ProcedureReturn
  EndIf
  OMSX_SendCommand("type -- " + OMSX_TclEscapeWord(Text))
EndProcedure

; Escreve *Payload (ByteCount bytes, a partir de Addr) direto na RAM visivel do Z80 via o
; comando de debug nativo do openMSX "debug write memory <endereco> <valor>" (debuggable
; "memory" = espaco de enderecamento de 64KB que o CPU enxerga, confirmado lendo
; openmsx/openmsx/src/cpu/MSXCPUInterface.cc/src/debugger/Debugger.cc, "checkNumArgs(tokens,
; 5, ..., "debuggable address value")" - um byte por comando, sem bloco). Depois digita
; "DEFUSR0=&H<Addr>" (+ ":A=USR0(0)" se AutoRun) via OMSX_TypeText() - mesma logica do
; Fossauro_SendAndType() (FossauroSupport.pbi, docs/SPEC.md modulos 32y/32z): nao existe RUN
; cru aqui, o texto entra pelo teclado emulado de verdade e o BASIC processa com o proprio
; contexto. Uso interno - chamado direto (ja conectado) ou via OMSX_PendingMamuteAddr
; (OMSX_PipeConnectThread() acima) quando o openMSX ainda estava subindo.
Procedure OMSX_FlushMamuteProgram(Addr.u, *Payload, ByteCount.i, AutoRun.b)
  Protected I.i
  For I = 0 To ByteCount - 1
    OMSX_SendCommand("debug write memory " + Str((Addr + I) & $FFFF) + " " + Str(PeekA(*Payload + I) & $FF))
  Next I

  Protected DefUsrLine.s = "DEFUSR0=&H" + RSet(Hex(Addr & $FFFF), 4, "0")
  If AutoRun
    DefUsrLine + ":A=USR0(0)"
  EndIf
  OMSX_TypeText(DefUsrLine + Chr(13))
EndProcedure

; Comando OPENMSX do Mamute Assembler (MamuteGui_CmdOpenMSX(), MamuteAssemblerGui.pbi) -
; equivalente ao FOSSAURO (Fossauro_SendAndType(), FossauroSupport.pbi), so' que mirando a
; instancia de openMSX de verdade em vez do Fossauro. Sobe o openMSX se precisar (OMSX_Start(),
; reaproveita se ja estiver rodando, mesmo padrao de OMSX_LoadDisk() logo abaixo) - se o pipe
; ainda nao tiver conectado, guarda uma COPIA dos bytes em OMSX_PendingMamuteBytes pra
; OMSX_PipeConnectThread() mandar assim que a conexao completar, em vez de perder o pedido
; (o *Payload de quem chama e' liberado logo depois desta chamada retornar).
Procedure.b OMSX_SendMamuteProgram(Addr.u, *Payload, ByteCount.i, AutoRun.b = #False)
  If OMSX_IsRunning() And OMSX_PipeConnected
    OMSX_FlushMamuteProgram(Addr, *Payload, ByteCount, AutoRun)
    ProcedureReturn #True
  EndIf

  If Not OMSX_Start()
    ProcedureReturn #False
  EndIf

  If *OMSX_PendingMamuteBytes
    FreeMemory(*OMSX_PendingMamuteBytes)
  EndIf
  *OMSX_PendingMamuteBytes = AllocateMemory(ByteCount)
  CopyMemory(*Payload, *OMSX_PendingMamuteBytes, ByteCount)
  OMSX_PendingMamuteByteCount = ByteCount
  OMSX_PendingMamuteAutoRun = AutoRun
  OMSX_PendingMamuteAddr = Addr ; por ultimo de proposito - e' o sinal que o flush usa (>= 0)
  ProcedureReturn #True
EndProcedure

; Atalho pro botao "Mostrar janela" da console (OpenMSXConsoleGui.pbi) -
; mesmo comando que o boot automatico ja manda (ver
; OMSX_PipeConnectThread()), disponivel sob demanda pra quando o usuario
; tiver voltado pro renderer "none" na mao (ex. via "set renderer none").
;
; "unset renderer" (reverte pro valor padrao), NAO "set renderer SDL" - o
; nome exato do renderer com janela varia entre builds do openMSX (SDL,
; SDLGL, SDLGL-PP...) e um nome errado so gera um "nok" silencioso no
; console sem abrir nada. O Catapult de verdade (openMSX/catapult no
; GitHub, src/player.py, classe VisibleSetting.setValue - e tambem
; InitLaunchScript() do C++ real, "AddCommand(wxT("unset renderer"))")
; faz exatamente isso.
Procedure OMSX_ShowWindow()
  OMSX_SendCommand("unset renderer")
EndProcedure

; Carrega DiskPath (um .dsk ja pronto, ver RunOnOpenMSX() em BadigEditor.pb)
; na instancia ATUAL do openMSX em vez de abrir uma nova - sobe o emulador se
; precisar (OMSX_Start(), reaproveita se ja estiver rodando) e troca o disco
; da unidade A com "diska insert" + "reset" (equivalente a trocar o
; disquete e reiniciar um MSX de verdade, sem fechar a janela do emulador).
; Se o pipe ainda nao tiver conectado (openMSX acabou de subir agora
; mesmo), guarda DiskPath em OMSX_PendingDiskPath pra
; OMSX_PipeConnectThread() mandar os mesmos dois comandos assim que a
; conexao completar, em vez de perder o pedido.
Procedure.b OMSX_LoadDisk(DiskPath.s)
  If OMSX_IsRunning() And OMSX_PipeConnected
    OMSX_SendCommand("diska insert " + Chr(34) + DiskPath + Chr(34))
    OMSX_SendCommand("reset")
    ProcedureReturn #True
  EndIf

  If Not OMSX_Start()
    ProcedureReturn #False
  EndIf
  OMSX_PendingDiskPath = DiskPath
  ProcedureReturn #True
EndProcedure

; Encerra a instancia atual DE PROPOSITO (diferente de "set power off", que
; so desliga a maquina virtual mas deixa o processo/janela do openMSX
; abertos) - usado pelo botao "Reiniciar openMSX" (OpenMSXConsoleGui.pbi)
; quando o usuario mudou maquina/extensao em Configurar -> openMSX e quer
; aplicar de verdade (nao da pra trocar isso a quente, sao flags so de
; lancamento). Pede uma saida limpa primeiro (comando Tcl nativo "exit"),
; da um tempo curto pra processar e so entao fecha na marra via
; CloseProgram() - mesmo padrao que o resto do modulo ja usa pra tratar o
; processo como podendo morrer a qualquer momento.
Procedure OMSX_Stop()
  If Not OMSX_IsRunning()
    ProcedureReturn
  EndIf
  OMSX_SendCommand("exit")
  Delay(300)
  CloseProgram(OMSX_Prog)
  OMSX_Prog = 0
  OMSX_ResetState()
EndProcedure

; Tira as tags XML mais comuns do protocolo pra sobrar so o texto legivel no
; console - limpeza simples por substituicao de string (nao um parser XML de
; verdade), mesmo espirito do msx_bridge.py (que so faz .replace("<reply>",
; "").replace("</reply>", "")). Suficiente pra um console de comando manual;
; se um dia precisar interpretar o resultado (ok/nok) por codigo, ai sim
; vale a pena um parser de verdade.
; Extrai o valor de uma linha crua "<update type="setting" name="X">valor</update>"
; (ANTES de OMSX_CleanLine(), que mutila as tags) - "" se a linha nao for uma atualizacao
; de "SettingName". Usado por OMSX_Poll() pra manter OMSX_PowerOn/OMSX_Paused sincronizados
; com o estado real do openMSX (ver assinatura "openmsx_update enable setting" em
; OMSX_PipeConnectThread()). Parser simples por substring (mesmo espirito de
; OMSX_CleanLine() - nao um parser XML de verdade), suficiente porque o formato de
; "<update>" do proprio openMSX (CliConnection.cc, update()) e sempre essa forma fixa.
Procedure.s OMSX_ExtractSettingUpdate(RawLine.s, SettingName.s)
  If FindString(RawLine, "<update type=" + Chr(34) + "setting" + Chr(34)) = 0
    ProcedureReturn ""
  EndIf
  Protected Needle.s = "name=" + Chr(34) + SettingName + Chr(34) + ">"
  Protected NamePos.i = FindString(RawLine, Needle)
  If NamePos = 0
    ProcedureReturn ""
  EndIf
  Protected ValueStart.i = NamePos + Len(Needle)
  Protected ValueEnd.i = FindString(RawLine, "<", ValueStart)
  If ValueEnd = 0
    ProcedureReturn ""
  EndIf
  ProcedureReturn Mid(RawLine, ValueStart, ValueEnd - ValueStart)
EndProcedure

; Extrai o conteudo cru de uma linha "<reply result="...">CONTEUDO</reply>"
; (ANTES de OMSX_CleanLine() mutilar as tags) - "" se a linha nao for uma
; reply. Usado so por OMSX_QueryFps()/OMSX_Poll() pra pegar a resposta de
; "openmsx_info fps" sem esperar um "<update type=setting>" (que so existe
; pra settings de verdade, nao pra consultas avulsas tipo openmsx_info).
Procedure.s OMSX_ExtractReplyContent(RawLine.s)
  Protected TagPos.i = FindString(RawLine, "<reply")
  If TagPos = 0
    ProcedureReturn ""
  EndIf
  Protected GtPos.i = FindString(RawLine, ">", TagPos)
  If GtPos = 0
    ProcedureReturn ""
  EndIf
  Protected CloseStart.i = FindString(RawLine, "</reply>", GtPos)
  If CloseStart = 0
    ProcedureReturn ""
  EndIf
  ProcedureReturn Mid(RawLine, GtPos + 1, CloseStart - GtPos - 1)
EndProcedure

; Extrai nome+valor de QUALQUER "<update type="setting" ...name="X">valor</update>"
; (ANTES de OMSX_CleanLine() mutilar as tags, mesmo motivo de sempre) - #False
; se a linha nao for uma atualizacao de setting. Usado so pra descoberta
; dinamica de dispositivo de som (OMSX_Poll() confere se Name termina em
; "_volume"/"_balance") - diferente de OMSX_ExtractSettingUpdate(), que
; exige saber o nome exato de antemao.
Procedure.b OMSX_ExtractAnySettingUpdate(RawLine.s, *Out.OMSX_SettingUpdate)
  If FindString(RawLine, "<update type=" + Chr(34) + "setting" + Chr(34)) = 0
    ProcedureReturn #False
  EndIf
  Protected Needle.s = "name=" + Chr(34)
  Protected NamePos.i = FindString(RawLine, Needle)
  If NamePos = 0
    ProcedureReturn #False
  EndIf
  Protected NameStart.i = NamePos + Len(Needle)
  Protected NameEnd.i = FindString(RawLine, Chr(34), NameStart)
  If NameEnd = 0
    ProcedureReturn #False
  EndIf
  Protected GtPos.i = FindString(RawLine, ">", NameEnd)
  If GtPos = 0
    ProcedureReturn #False
  EndIf
  Protected CloseStart.i = FindString(RawLine, "</update>", GtPos)
  If CloseStart = 0
    ProcedureReturn #False
  EndIf
  *Out\Name = Mid(RawLine, NameStart, NameEnd - NameStart)
  *Out\Value = Mid(RawLine, GtPos + 1, CloseStart - GtPos - 1)
  ProcedureReturn #True
EndProcedure

; Acha, dentro da resposta cheia do comando "plug" (sem argumentos - lista
; TODOS os conectores/pluggables atuais, uma "linha" por conector no
; formato "conector: pluggable", separadas por "&#x0a;" ja que veio dentro
; de um XML), o nome de um conector cujo PROPRIO NOME contem NeedleLower
; (case-insensitive) - usado pra achar o conector MIDI-in/MIDI-out de
; verdade, que varia por hardware (ver comentario de OMSX_MidiInConnector
; acima). "" se nao achar.
Procedure.s OMSX_FindConnectorByName(ReplyContent.s, NeedleLower.s)
  Protected Lines.s = ReplaceString(ReplyContent, "&#x0a;", Chr(10))
  Protected N.i = CountString(Lines, Chr(10)) + 1
  Protected I.i
  For I = 1 To N
    Protected OneLine.s = StringField(Lines, I, Chr(10))
    Protected ColonPos.i = FindString(OneLine, ":")
    If ColonPos > 0
      Protected ConnName.s = Trim(Left(OneLine, ColonPos - 1))
      If FindString(LCase(ConnName), NeedleLower) > 0
        ProcedureReturn ConnName
      EndIf
    EndIf
  Next
  ProcedureReturn ""
EndProcedure

; Consulta sob demanda UM nome de dispositivo digitado manualmente (botao
; "Adicionar" da aba "Volume") - ver comentario de OMSX_AwaitingDeviceQuery,
; topo do arquivo.
Procedure OMSX_QueryDevice(DevName.s)
  If OMSX_IsRunning() And OMSX_PipeConnected And Trim(DevName) <> ""
    OMSX_AwaitingDeviceQuery = DevName
    OMSX_SendCommand("set " + Chr(34) + DevName + "_volume" + Chr(34))
  EndIf
EndProcedure

; Dispara a consulta que descobre os conectores MIDI-in/MIDI-out de verdade
; desta maquina - ver OMSX_Poll() pra onde a resposta e capturada
; (OMSX_AwaitingPlugList). Chamada uma vez ao abrir a aba "Volume" (nao
; precisa repetir - conectores nao aparecem/somem sozinhos em runtime).
Procedure OMSX_QueryMidiConnectors()
  If OMSX_IsRunning() And OMSX_PipeConnected
    OMSX_AwaitingPlugList = #True
    OMSX_SendCommand("plug")
  EndIf
EndProcedure

; Consulta o FPS atual - so dispara o comando e marca "aguardando resposta",
; ver OMSX_Poll() pra onde a resposta e capturada. Chamada periodicamente
; pela GUI (nao daqui), pra nao gerar trafego sem ninguem pedindo.
Procedure OMSX_QueryFps()
  If OMSX_IsRunning() And OMSX_PipeConnected
    OMSX_AwaitingFps = #True
    OMSX_SendCommand("openmsx_info fps")
  EndIf
EndProcedure

; Tabela real da matriz de teclado MSX (linha/mascara por tecla), usada tanto
; pra simular teclas especiais (STOP, ESC, F1-F5, setas, etc.) via
; "keymatrixdown"/"keymatrixup" quanto pelas tags ⟦NOME⟧ da aba "Input Text"
; (ver OMSX_TypeTextWithTags() abaixo). Devolve Linha*256+Mascara, ou -1 se
; Name nao for uma tecla especial reconhecida.
;
; Verificada CRUZANDO DUAS FONTES INDEPENDENTES (2026-08-20), byte a byte,
; nao só uma leitura de codigo: a tabela real do openMSX
; (getMSXMapping()/KeyMatrixPosition, resource/openmsx/openmsx/src/input/
; Keyboard.cc - "// row/bit 7 6 5 4 3 2 1 0" comentado no proprio arquivo) e a
; tabela KeyboardData ja portada do fMSX real pro proprio simulador MSX deste
; projeto (src/fossauro/MSX.pbi, Data.b Row,Mask por tecla) - as duas batem
; 100% em tudo que interessa aqui (linhas 6/7/8: modificadores, funcao,
; controle, cursor). Achado um bug real nesse cruzamento: o comentario antigo
; desta mesma funcao (removido agora) afirmava STOP = linha 7 mascara 0x08,
; "confirmado" contra um binding real do openMSX que na verdade NAO EXISTE
; nos scripts vendorizados (share/scripts/*.tcl nao tem nenhum "bind PAGEUP
; keymatrixdown" - PAGEUP e "go_back_one_step", sem relacao com STOP) - ou
; seja, essa "confirmacao" de uma sessao anterior nunca foi verificada de
; verdade. O valor certo e linha 7 mascara 0x10 (0x08 naquela linha e TAB) -
; corrigido aqui E em OMSX_PressStop() abaixo, que ate agora estava
; pressionando TAB sempre que o usuario clicava "STOP".
Procedure.i OMSX_KeyTagRowMask(Name.s)
  Select UCase(Name)
    Case "ESC", "ESCAPE"   : ProcedureReturn 7 * 256 + $04
    Case "F1"              : ProcedureReturn 6 * 256 + $20
    Case "F2"              : ProcedureReturn 6 * 256 + $40
    Case "F3"              : ProcedureReturn 6 * 256 + $80
    Case "F4"              : ProcedureReturn 7 * 256 + $01
    Case "F5"              : ProcedureReturn 7 * 256 + $02
    Case "TAB"             : ProcedureReturn 7 * 256 + $08
    Case "STOP"            : ProcedureReturn 7 * 256 + $10
    Case "BS", "BACKSPACE" : ProcedureReturn 7 * 256 + $20
    Case "SELECT"          : ProcedureReturn 7 * 256 + $40
    Case "ENTER", "RETURN" : ProcedureReturn 7 * 256 + $80
    Case "HOME"            : ProcedureReturn 8 * 256 + $02
    Case "INS", "INSERT"   : ProcedureReturn 8 * 256 + $04
    Case "DEL", "DELETE"   : ProcedureReturn 8 * 256 + $08
    Case "LEFT"            : ProcedureReturn 8 * 256 + $10
    Case "UP"              : ProcedureReturn 8 * 256 + $20
    Case "DOWN"            : ProcedureReturn 8 * 256 + $40
    Case "RIGHT"           : ProcedureReturn 8 * 256 + $80
    Case "SHIFT"           : ProcedureReturn 6 * 256 + $01
    Case "CTRL", "CONTROL" : ProcedureReturn 6 * 256 + $02
    Case "GRAPH"           : ProcedureReturn 6 * 256 + $04
    Case "CAPS", "CAPSLOCK": ProcedureReturn 6 * 256 + $08
    Case "CODE"            : ProcedureReturn 6 * 256 + $10
  EndSelect
  ProcedureReturn -1
EndProcedure

; Pulso curto (down seguido de up) numa posicao Linha*256+Mascara da matriz de
; teclado (ver OMSX_KeyTagRowMask() acima) - como um toque de tecla de
; verdade, mesmo padrao de delay curto e bloqueante que OMSX_Stop() ja usa
; pra dar tempo do comando anterior ser processado.
Procedure OMSX_PressMatrixKey(RowMask.i)
  Protected Row.i = RowMask >> 8
  Protected Mask.i = RowMask & $FF
  OMSX_SendCommand("keymatrixdown " + Str(Row) + " " + Str(Mask))
  Delay(50)
  OMSX_SendCommand("keymatrixup " + Str(Row) + " " + Str(Mask))
EndProcedure

; Pressiona VARIAS posicoes da matriz ao mesmo tempo - todas as
; "keymatrixdown" primeiro, na ORDEM dada (sem soltar nenhuma no meio), UM SO
; delay, depois todas as "keymatrixup" na ordem INVERSA (ultima pressionada,
; primeira solta) - como segurar um modificador de verdade (Shift/Ctrl/Graph)
; e So DEPOIS tocar a tecla principal, ao contrario de OMSX_PressMatrixKey()
; (pulso independente, solta antes de ir pra proxima). Pedido explicito do
; usuario 2026-08-20: "[SHIFT][F1]" sequencial (dois OMSX_PressMatrixKey()) ja
; cobria o caso "aperta e solta uma, depois a outra", mas fazia falta o caso
; "segura as duas juntas" (SHIFT+F1 de verdade, por exemplo). RowMasks() e um
; array de Linha*256+Mascara ja resolvidos (ver OMSX_ResolveComboRowMasks()),
; Count itens validos a partir do indice 0.
Procedure OMSX_PressMatrixCombo(Array RowMasks.i(1), Count.i)
  Protected I.i, Row.i, Mask.i
  For I = 0 To Count - 1
    Row = RowMasks(I) >> 8
    Mask = RowMasks(I) & $FF
    OMSX_SendCommand("keymatrixdown " + Str(Row) + " " + Str(Mask))
  Next I
  Delay(80)
  For I = Count - 1 To 0 Step -1
    Row = RowMasks(I) >> 8
    Mask = RowMasks(I) & $FF
    OMSX_SendCommand("keymatrixup " + Str(Row) + " " + Str(Mask))
  Next I
EndProcedure

; Resolve o conteudo de uma tag de combo "NOME1+NOME2+..." (ver
; OMSX_TypeTextWithTags() abaixo) pra uma lista de Linha*256+Mascara em
; RowMasks() - devolve quantos itens resolveu, ou -1 se QUALQUER nome do
; combo nao for reconhecido (tudo ou nada: nao faz sentido pressionar so
; metade de "SHIFT+F1" por um typo no segundo nome). Limite de 8 teclas
; simultaneas - bem mais que qualquer combo real do MSX precisaria.
Procedure.i OMSX_ResolveComboRowMasks(TagName.s, Array RowMasks.i(1))
  Protected Count.i = 0
  Protected Pos.i = 1, NextPlus.i, Part.s, RM.i
  While Pos <= Len(TagName)
    If Count > ArraySize(RowMasks())
      ProcedureReturn -1
    EndIf
    NextPlus = FindString(TagName, "+", Pos)
    If NextPlus = 0
      Part = Trim(Mid(TagName, Pos))
      Pos = Len(TagName) + 1
    Else
      Part = Trim(Mid(TagName, Pos, NextPlus - Pos))
      Pos = NextPlus + 1
    EndIf
    If Part = ""
      ProcedureReturn -1
    EndIf
    RM = OMSX_KeyTagRowMask(Part)
    If RM < 0
      ProcedureReturn -1
    EndIf
    RowMasks(Count) = RM
    Count + 1
  Wend
  ProcedureReturn Count
EndProcedure

; Simula a tecla STOP fisica do teclado MSX (Ctrl+Stop interrompe um
; programa BASIC em execucao - "break").
Procedure OMSX_PressStop()
  OMSX_PressMatrixKey(OMSX_KeyTagRowMask("STOP"))
EndProcedure

; Digita Text no MSX como OMSX_TypeText() (ver acima), mas reconhecendo tags
; ⟦NOME⟧ (colchetes duplos Unicode U+27E6/U+27E7 - de proposito NAO os
; colchetes ASCII "[ ]" comuns, que aparecem o tempo todo em texto/BASIC de
; verdade, ex. PRINT "Pressiona [ESC]": essa string continua saindo literal,
; so a tag ⟦ESC⟧ vira tecla) - com DOIS formatos de tag:
;   - ⟦NOME⟧ (uma tecla so) vira um pulso independente (aperta E solta) via
;     OMSX_PressMatrixKey() - "[SHIFT][F1]" nesse formato aperta/solta SHIFT,
;     depois aperta/solta F1, sequencial, uma tecla nunca fica presa
;     enquanto a outra e tocada.
;   - ⟦NOME1+NOME2+...⟧ (com "+") vira um COMBO via OMSX_PressMatrixCombo()/
;     OMSX_ResolveComboRowMasks() - todas apertadas primeiro (SHIFT+F1
;     segura SHIFT, so DEPOIS toca F1, so DEPOIS solta as duas) - pedido
;     explicito do usuario 2026-08-20 pra cobrir combos de verdade
;     (Shift+F1, Ctrl+Select, etc.) que o formato sequencial nao alcança.
; Em ambos os formatos, o texto literal ao redor e mandado normalmente via
; OMSX_TypeText() em pedacos. Uma tag com nome (ou algum nome dentro de um
; combo) nao reconhecido, ou um colchete de abertura sem fechamento, volta
; como texto literal (colchetes inclusos) em vez de simplesmente sumir sem
; aviso - no caso do combo e tudo ou nada, nunca aperta so metade. Usada pelo
; botao "Type" da aba "Input Text" (OpenMSXConsoleGui.pbi) - a paleta de
; botoes de tecla especial daquela aba insere as tags no cursor (single ou
; combo, conforme "Modo Combo"), o usuario nao precisa digitar ⟦ ⟧ a mao.
Procedure OMSX_TypeTextWithTags(Text.s)
  Protected OpenBr.s = Chr($27E6)
  Protected CloseBr.s = Chr($27E7)
  Protected Pos.i = 1
  Protected TagStart.i, TagEnd.i, TagName.s, RowMask.i, ComboCount.i
  Protected Dim ComboRowMask.i(7)
  While Pos <= Len(Text)
    TagStart = FindString(Text, OpenBr, Pos)
    If TagStart = 0
      OMSX_TypeText(Mid(Text, Pos))
      Break
    EndIf
    If TagStart > Pos
      OMSX_TypeText(Mid(Text, Pos, TagStart - Pos))
    EndIf
    TagEnd = FindString(Text, CloseBr, TagStart + 1)
    If TagEnd = 0
      OMSX_TypeText(Mid(Text, TagStart))
      Break
    EndIf
    TagName = Mid(Text, TagStart + 1, TagEnd - TagStart - 1)
    If FindString(TagName, "+") > 0
      ComboCount = OMSX_ResolveComboRowMasks(TagName, ComboRowMask())
      If ComboCount > 0
        OMSX_PressMatrixCombo(ComboRowMask(), ComboCount)
      Else
        OMSX_TypeText(Mid(Text, TagStart, TagEnd - TagStart + 1))
      EndIf
    Else
      RowMask = OMSX_KeyTagRowMask(TagName)
      If RowMask >= 0
        OMSX_PressMatrixKey(RowMask)
      Else
        OMSX_TypeText(Mid(Text, TagStart, TagEnd - TagStart + 1))
      EndIf
    EndIf
    Pos = TagEnd + 1
  Wend
EndProcedure

Procedure.s OMSX_CleanLine(Line.s)
  Protected Clean.s = Trim(Line)
  Clean = ReplaceString(Clean, "<reply result=" + Chr(34) + "nok" + Chr(34) + ">", "[ERRO] ")
  Clean = ReplaceString(Clean, "<reply result=" + Chr(34) + "ok" + Chr(34) + ">", "")
  Clean = ReplaceString(Clean, "<reply>", "")
  Clean = ReplaceString(Clean, "</reply>", "")
  Clean = ReplaceString(Clean, "<log level=" + Chr(34) + "info" + Chr(34) + ">", "[log] ")
  Clean = ReplaceString(Clean, "<log level=" + Chr(34) + "warning" + Chr(34) + ">", "[aviso] ")
  Clean = ReplaceString(Clean, "<log level=" + Chr(34) + "error" + Chr(34) + ">", "[ERRO] ")
  Clean = ReplaceString(Clean, "</log>", "")
  Clean = ReplaceString(Clean, "<update type=" + Chr(34), "[update ")
  Clean = ReplaceString(Clean, "</update>", "")
  Clean = ReplaceString(Clean, "<openmsx-output>", "")
  Clean = ReplaceString(Clean, "</openmsx-output>", "")
  ProcedureReturn Trim(Clean)
EndProcedure

; Chamada a cada tick do timer da janela de console (ver OpenMSXConsoleGui.pbi):
; devolve as linhas novas de stdout/stderr ja limpas, uma por linha
; separadas por Chr(10) ("" se nao houver nada novo). "" tambem quando o
; processo ja nao esta mais rodando - quem chama usa OMSX_IsRunning() a
; parte pra distinguir esse caso. A sequencia de boot (handshake/renderer/
; power) NAO e mais disparada daqui - ver OMSX_PipeConnectThread(), que
; dispara assim que a conexao de verdade acontece, em vez de um timer fixo.
Procedure.s OMSX_Poll()
  If Not OMSX_IsRunning()
    ProcedureReturn ""
  EndIf

  Protected Result.s = ""
  Protected Verbose.s = ""
  Protected Line.s
  Protected SettingVal.s
  Protected SkipLog.b
  While OMSX_Prog And AvailableProgramOutput(OMSX_Prog)
    Line = ReadProgramString(OMSX_Prog)
    If Line = "" : Break : EndIf

    ; Le o estado ao vivo da linha CRUA, antes de limpar (OMSX_CleanLine() mutila as
    ; tags) - ver comentario de OMSX_ExtractSettingUpdate() e a assinatura
    ; "openmsx_update enable setting" em OMSX_PipeConnectThread().
    SettingVal = OMSX_ExtractSettingUpdate(Line, "power")
    If SettingVal <> ""
      OMSX_PowerOn = Bool(SettingVal = "true")
      OMSX_PowerKnown = #True
    EndIf
    SettingVal = OMSX_ExtractSettingUpdate(Line, "pause")
    If SettingVal <> ""
      OMSX_Paused = Bool(SettingVal = "true")
      OMSX_PausedKnown = #True
    EndIf
    SettingVal = OMSX_ExtractSettingUpdate(Line, "speed")
    If SettingVal <> ""
      OMSX_Speed = Val(SettingVal)
      OMSX_SpeedKnown = #True
    EndIf
    SettingVal = OMSX_ExtractSettingUpdate(Line, "firmwareswitch")
    If SettingVal <> ""
      OMSX_FirmwareOn = Bool(SettingVal = "true")
      OMSX_FirmwareKnown = #True
    EndIf
    SettingVal = OMSX_ExtractSettingUpdate(Line, "renshaturbo")
    If SettingVal <> ""
      OMSX_RenshaOn = Bool(Val(SettingVal) > 0)
      OMSX_RenshaKnown = #True
    EndIf
    SettingVal = OMSX_ExtractSettingUpdate(Line, "caps")
    If SettingVal <> ""
      OMSX_LedCapsOn = Bool(SettingVal = "true")
      OMSX_LedCapsKnown = #True
    EndIf
    SettingVal = OMSX_ExtractSettingUpdate(Line, "kana")
    If SettingVal <> ""
      OMSX_LedKanaOn = Bool(SettingVal = "true")
      OMSX_LedKanaKnown = #True
    EndIf
    SettingVal = OMSX_ExtractSettingUpdate(Line, "turbo")
    If SettingVal <> ""
      OMSX_LedTurboOn = Bool(SettingVal = "true")
      OMSX_LedTurboKnown = #True
    EndIf
    SettingVal = OMSX_ExtractSettingUpdate(Line, "fdd")
    If SettingVal <> ""
      OMSX_LedFddOn = Bool(SettingVal = "true")
      OMSX_LedFddKnown = #True
    EndIf
    SettingVal = OMSX_ExtractSettingUpdate(Line, "vsync")
    If SettingVal <> ""
      OMSX_VSyncOn = Bool(SettingVal = "true")
      OMSX_VSyncKnown = #True
    EndIf
    SettingVal = OMSX_ExtractSettingUpdate(Line, "scale_algorithm")
    If SettingVal <> ""
      OMSX_ScaleAlgorithm = SettingVal
      OMSX_ScaleAlgorithmKnown = #True
    EndIf
    SettingVal = OMSX_ExtractSettingUpdate(Line, "deinterlace")
    If SettingVal <> ""
      OMSX_DeinterlaceOn = Bool(SettingVal = "true")
      OMSX_DeinterlaceKnown = #True
    EndIf
    SettingVal = OMSX_ExtractSettingUpdate(Line, "limitsprites")
    If SettingVal <> ""
      OMSX_LimitSpritesOn = Bool(SettingVal = "true")
      OMSX_LimitSpritesKnown = #True
    EndIf
    SettingVal = OMSX_ExtractSettingUpdate(Line, "fullscreen")
    If SettingVal <> ""
      OMSX_FullscreenOn = Bool(SettingVal = "true")
      OMSX_FullscreenKnown = #True
    EndIf
    SettingVal = OMSX_ExtractSettingUpdate(Line, "disablesprites")
    If SettingVal <> ""
      OMSX_DisableSpritesOn = Bool(SettingVal = "true")
      OMSX_DisableSpritesKnown = #True
    EndIf
    SettingVal = OMSX_ExtractSettingUpdate(Line, "scanline")
    If SettingVal <> ""
      OMSX_Scanline = Val(SettingVal)
      OMSX_ScanlineKnown = #True
    EndIf
    SettingVal = OMSX_ExtractSettingUpdate(Line, "blur")
    If SettingVal <> ""
      OMSX_Blur = Val(SettingVal)
      OMSX_BlurKnown = #True
    EndIf
    SettingVal = OMSX_ExtractSettingUpdate(Line, "glow")
    If SettingVal <> ""
      OMSX_Glow = Val(SettingVal)
      OMSX_GlowKnown = #True
    EndIf
    SettingVal = OMSX_ExtractSettingUpdate(Line, "gamma")
    If SettingVal <> ""
      OMSX_Gamma = SettingVal
      OMSX_GammaKnown = #True
    EndIf
    SettingVal = OMSX_ExtractSettingUpdate(Line, "noise")
    If SettingVal <> ""
      OMSX_Noise = Val(SettingVal)
      OMSX_NoiseKnown = #True
    EndIf

    ; Resposta de "openmsx_info fps" (nao e um "<update type=setting>", ver
    ; comentario de OMSX_AwaitingFps/OMSX_QueryFps() no topo do arquivo) -
    ; checado ANTES de OMSX_CleanLine() mutilar a linha, mesmo motivo de
    ; tudo acima. Consultado ~1x/segundo pela GUI so pra alimentar o display
    ; de FPS (ver OMSXGui_DrawFpsDisplay()) - a linha crua da resposta (so um
    ; numero) nao interessa como "resultado de comando" em NENHUM dos dois
    ; logs (nem "Console" nem "Status Info") - poluia os dois a cada segundo
    ; (relatado pelo usuario 2026-08-20, o log verboso ficou poluido do
    ; mesmo jeito assim que o display de FPS dedicado passou a existir),
    ; entao SkipLog tira ela dos dois (Result E Verbose) - so alimenta
    ; OMSX_Fps/OMSX_FpsKnown mesmo, que e o unico consumidor de verdade.
    SkipLog = #False
    If OMSX_AwaitingFps
      Protected ReplyContent.s = OMSX_ExtractReplyContent(Line)
      If ReplyContent <> ""
        OMSX_Fps = ReplyContent
        OMSX_FpsKnown = #True
        OMSX_AwaitingFps = #False
        SkipLog = #True
      EndIf
    EndIf

    ; Resposta de "set NOME_volume" (consulta manual, ver OMSX_QueryDevice())
    ; - se o nome existir de verdade, isto adiciona o dispositivo ao Map
    ; mesmo sem nenhuma mudanca real ter ocorrido (resolve o "ovo e
    ; galinha" da descoberta so-passiva). Se o nome NAO existir, a resposta
    ; vem como erro (Val() disso vira 0) mas o [ERRO] correspondente ja
    ; aparece no log de qualquer jeito via OMSX_CleanLine() normal - o
    ; usuario ve que falhou.
    If OMSX_AwaitingDeviceQuery <> ""
      Protected DevReply.s = OMSX_ExtractReplyContent(Line)
      If DevReply <> ""
        If AddMapElement(OMSX_DeviceVolume(), OMSX_AwaitingDeviceQuery)
          OMSX_DeviceListDirty = #True
        EndIf
        OMSX_DeviceVolume(OMSX_AwaitingDeviceQuery) = Val(DevReply)
        OMSX_AwaitingDeviceQuery = ""
      EndIf
    EndIf

    ; Resposta de "plug" (lista de conectores) - ver OMSX_QueryMidiConnectors().
    If OMSX_AwaitingPlugList
      Protected PlugReply.s = OMSX_ExtractReplyContent(Line)
      If PlugReply <> ""
        OMSX_MidiInConnector = OMSX_FindConnectorByName(PlugReply, "midi-in")
        OMSX_MidiOutConnector = OMSX_FindConnectorByName(PlugReply, "midi-out")
        OMSX_AwaitingPlugList = #False
      EndIf
    EndIf

    ; Descoberta dinamica de dispositivo de som (aba "Volume") - qualquer
    ; setting terminando em "_volume"/"_balance" vira uma entrada no Map,
    ; keyed pelo nome real do dispositivo (ver comentario de
    ; OMSX_DeviceVolume() no topo do arquivo). AddMapElement() devolve
    ; #True so quando a chave e NOVA - e o sinal certo pra avisar a GUI que
    ; a lista mudou, sem precisar comparar antes/depois.
    Protected Upd.OMSX_SettingUpdate
    If OMSX_ExtractAnySettingUpdate(Line, @Upd)
      If Right(Upd\Name, 7) = "_volume"
        Protected DevName.s = Left(Upd\Name, Len(Upd\Name) - 7)
        If AddMapElement(OMSX_DeviceVolume(), DevName)
          OMSX_DeviceListDirty = #True
        EndIf
        OMSX_DeviceVolume(DevName) = Val(Upd\Value)
      ElseIf Right(Upd\Name, 8) = "_balance"
        Protected DevName2.s = Left(Upd\Name, Len(Upd\Name) - 8)
        AddMapElement(OMSX_DeviceBalance(), DevName2)
        OMSX_DeviceBalance(DevName2) = Val(Upd\Value)
      EndIf
    EndIf

    Line = OMSX_CleanLine(Line)
    If Line <> "" And Not SkipLog
      Verbose + Line + Chr(10)
      Result + Line + Chr(10)
    EndIf
  Wend
  ; ReadProgramError() nao tem uma "AvailableProgramError()" irma (so existe
  ; AvailableProgramOutput(), pro stdout) - mas ao contrario de
  ; ReadProgramString()/ReadProgramData(), ela ja e nao-bloqueante por conta
  ; propria (doc: "doesn't halt the program flow if no error output is
  ; available"), devolvendo "" quando nao ha nada novo - dá pra chamar direto
  ; em loop ate isso acontecer.
  If OMSX_Prog
    Repeat
      Line = ReadProgramError(OMSX_Prog)
      If Line = "" : Break : EndIf
      Result + "[stderr] " + Trim(Line) + Chr(10)
      Verbose + "[stderr] " + Trim(Line) + Chr(10)
    ForEver
  EndIf

  OMSX_LastVerboseChunk = Verbose
  ProcedureReturn Result
EndProcedure

; Texto curto pra um indicador de estado na GUI (OpenMSXConsoleGui.pbi) - "?" enquanto o
; primeiro "<update type="setting" ...>" ainda nao chegou (ver OMSX_PowerKnown/
; OMSX_PausedKnown). Chamar so quando OMSX_IsRunning() for #True.
Procedure.s OMSX_StatusText()
  Protected Txt.s
  If OMSX_PowerKnown
    If OMSX_PowerOn : Txt = "Ligado" : Else : Txt = "Desligado" : EndIf
  Else
    Txt = "?"
  EndIf
  Txt + "  |  "
  If OMSX_PausedKnown
    If OMSX_Paused : Txt + "PAUSADO" : Else : Txt + "Rodando" : EndIf
  Else
    Txt + "?"
  EndIf
  ProcedureReturn Txt
EndProcedure
