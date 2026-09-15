;
; ------------------------------------------------------------
;  Suporte ao Fossauro (fossauro/fossauro.exe): port nativo em PureBasic do
;  fMSX, projeto irmao dentro deste mesmo repositorio - mas NAO incorporado
;  a esta IDE (licenca nao-comercial propria, LICENSE-fossauro, incompativel
;  com a licenca deste projeto - por isso nunca e linkado nem distribuido
;  junto, so chamado como executavel externo, mesma relacao que o openMSX
;  ja tem). "Executar -> Fossauro" (Fossauro_Launch()) e "Configurar ->
;  Fossauro..." (FossauroSettings_OpenWindow()) - mesma arquitetura de
;  AsmsxSupport.pbi/N80Support.pbi, sem canal de controle por pipe (ao
;  contrario do openMSX/OpenMSXBridge.pbi): o Fossauro e um .exe GUI
;  autonomo, so precisa ser iniciado e deixado rodando no seu proprio
;  processo/janela.
;
;  Flags de linha de comando usadas aqui (as unicas com efeito real
;  confirmado em fossauro/fossauro.pb - "Executar -> BASIC" no proprio
;  Fossauro/docs/SPEC.md tem a lista completa, incluindo as ainda inertes):
;  -msx1/-msx2/-msx2+ (modelo), -ram <paginas de 16KB>/-vram <paginas de
;  16KB> (memoria, mesmos valores validos dos menus Hardware -> RAM
;  Size/VRAM Size do proprio Fossauro), -pal/-ntsc, -verbose (grava
;  fossauro.log). "-diska"/"-diskb" existem no parser mas o FDC ainda nao
;  esta ligado ao boot (regressao conhecida, ver docs/SPEC.md modulo 32p) -
;  por isso ainda nao expostos aqui, so quando isso for corrigido.
; ------------------------------------------------------------
;

;- ------------------------------------------------------------
;- Configuracoes / persistencia
;- ------------------------------------------------------------

; RAMPages/VRAMPages guardam o valor cru em paginas de 16KB (nao o texto do
; combo) - mesmos 5 valores validos que fossauro/fossauro.pb aceita pra cada
; um (UpdateRAMSizeMenuCheck()/UpdateVRAMSizeMenuCheck()): RAM 4/8/16/32/64 =
; 64/128/256/512/1024KB, VRAM 1/2/4/8/12 = 16/32/64/128/192KB. Model guarda
; "1"/"2"/"2+" (mesma convencao curta usada no Hardware -> Model do proprio
; Fossauro).
Structure FossauroSettings
  ExePath.s
  Model.s          ; "1", "2" ou "2+"
  RAMPages.l
  VRAMPages.l
  Pal.b            ; -pal (senao -ntsc)
  Verbose.b        ; -verbose
  CartridgePath.s  ; carregado como cartucho do Slot A, se preenchido
EndStructure
Global FossauroCfg.FossauroSettings

; dist\fossauro\ - so' help/config do Fossauro (o .exe em si mora ao lado de
; PaleoBasic.exe, ver Fossauro_FindExe() abaixo - pedido explicito do usuario,
; 2026-08-19: os dois executaveis na raiz de dist\, cada um busca seus
; proprios helps/configuracoes na subpasta com seu nome).
Procedure.s FossauroDir()
  ProcedureReturn GetPathPart(ProgramFilename()) + "fossauro\"
EndProcedure

; Static, checked-in reference content (fossauro/help/*.md + _index.json) - NOT a runtime download
; cache like N80_HelpDir()/MsxBas2Rom_HelpDir(), so GenMdHelp_OpenWindow() (Ajuda -> Fossauro...)
; always has something to show without needing a "Baixar" step first.
Procedure.s Fossauro_HelpDir()
  ProcedureReturn FossauroDir() + "help\"
EndProcedure

; fossauro.exe fica na RAIZ de dist\ (irmao de PaleoBasic.exe), nao dentro de
; FossauroDir() (essa e' so' pra help/config) - mesmo diretorio de
; GetPathPart(ProgramFilename()).
Procedure.s Fossauro_FindExe()
  Protected Dir.s = GetPathPart(ProgramFilename())
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    If FileSize(Dir + "fossauro.exe") > 0 : ProcedureReturn Dir + "fossauro.exe" : EndIf
  CompilerElse
    If FileSize(Dir + "fossauro") > 0 : ProcedureReturn Dir + "fossauro" : EndIf
  CompilerEndIf
  ProcedureReturn ""
EndProcedure

; OverridePath (opcional): mesmo padrao de AsmsxCfg_FilePath() - "" = caminho
; global de sempre, senao usa esse caminho direto (config por-projeto).
Procedure.s FossauroCfg_FilePath(OverridePath.s = "")
  If OverridePath <> ""
    ProcedureReturn OverridePath
  EndIf
  ProcedureReturn GetPathPart(ProgramFilename()) + "editor\fossauro_settings.json"
EndProcedure

Procedure FossauroCfg_Load(OverridePath.s = "")
  ; Padroes batem com o proprio startup padrao do fossauro.exe (MSX1, 64KB
  ; RAM, 16KB VRAM, NTSC - escolha explicita do dono do projeto, ver
  ; fossauro/SPEC.md).
  FossauroCfg\ExePath = ""
  FossauroCfg\Model = "1"
  FossauroCfg\RAMPages = 4
  FossauroCfg\VRAMPages = 1
  FossauroCfg\Pal = #False
  FossauroCfg\Verbose = #False
  FossauroCfg\CartridgePath = ""

  Protected FilePath.s = FossauroCfg_FilePath(OverridePath)
  If FileSize(FilePath) <= 0
    ProcedureReturn
  EndIf

  Protected Json = LoadJSON(#PB_Any, FilePath)
  If Not Json
    ProcedureReturn
  EndIf

  Protected Root = JSONValue(Json)
  Protected M
  M = GetJSONMember(Root, "ExePath")       : If M : FossauroCfg\ExePath       = GetJSONString(M)  : EndIf
  M = GetJSONMember(Root, "Model")         : If M : FossauroCfg\Model         = GetJSONString(M)  : EndIf
  M = GetJSONMember(Root, "RAMPages")      : If M : FossauroCfg\RAMPages      = GetJSONInteger(M) : EndIf
  M = GetJSONMember(Root, "VRAMPages")     : If M : FossauroCfg\VRAMPages     = GetJSONInteger(M) : EndIf
  M = GetJSONMember(Root, "Pal")           : If M : FossauroCfg\Pal           = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "Verbose")       : If M : FossauroCfg\Verbose       = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "CartridgePath") : If M : FossauroCfg\CartridgePath = GetJSONString(M)  : EndIf
  FreeJSON(Json)
EndProcedure

Procedure FossauroCfg_Save(OverridePath.s = "")
  Protected Json = CreateJSON(#PB_Any)
  Protected Root = SetJSONObject(JSONValue(Json))
  SetJSONString(AddJSONMember(Root, "ExePath"), FossauroCfg\ExePath)
  SetJSONString(AddJSONMember(Root, "Model"), FossauroCfg\Model)
  SetJSONInteger(AddJSONMember(Root, "RAMPages"), FossauroCfg\RAMPages)
  SetJSONInteger(AddJSONMember(Root, "VRAMPages"), FossauroCfg\VRAMPages)
  SetJSONBoolean(AddJSONMember(Root, "Pal"), FossauroCfg\Pal)
  SetJSONBoolean(AddJSONMember(Root, "Verbose"), FossauroCfg\Verbose)
  SetJSONString(AddJSONMember(Root, "CartridgePath"), FossauroCfg\CartridgePath)
  SaveJSON(Json, FossauroCfg_FilePath(OverridePath), #PB_JSON_PrettyPrint)
  FreeJSON(Json)
EndProcedure

;- ------------------------------------------------------------
;- Executar -> Fossauro
;- ------------------------------------------------------------

Procedure.s Fossauro_BuildCliArgs()
  Protected Args.s = ""
  Select FossauroCfg\Model
    Case "2"  : Args + "-msx2 "
    Case "2+" : Args + "-msx2+ "
    Default   : Args + "-msx1 "
  EndSelect
  Args + "-ram " + Str(FossauroCfg\RAMPages) + " "
  Args + "-vram " + Str(FossauroCfg\VRAMPages) + " "
  If FossauroCfg\Pal
    Args + "-pal "
  Else
    Args + "-ntsc "
  EndIf
  If FossauroCfg\Verbose
    Args + "-verbose "
  EndIf
  If FossauroCfg\CartridgePath <> ""
    Args + Chr(34) + FossauroCfg\CartridgePath + Chr(34) + " "
  EndIf
  ProcedureReturn Trim(Args)
EndProcedure

; Inicia o fossauro.exe configurado com as opcoes padrao (Configurar ->
; Fossauro...) e deixa rodando no seu proprio processo/janela - RunProgram()
; fire-and-forget, nao ha nada pra acompanhar aqui logo apos abrir. A
; instancia recem-aberta ainda pode ser controlada DEPOIS via o pipe de
; controle proprio (ver Fossauro_SendAndRun() abaixo) - diferente do
; OpenMSXBridge.pbi (openMSX de verdade), que usa o protocolo de controle
; nativo do openMSX (Tcl/XML); o Fossauro fala um protocolo bem mais simples,
; proprio, ver docs/SPEC.md modulo 32u.
Procedure.b Fossauro_Launch()
  FossauroCfg_Load()
  If FossauroCfg\ExePath = "" Or FileSize(FossauroCfg\ExePath) <= 0
    MessageRequester("Fossauro",
                     "Caminho do executavel do Fossauro nao configurado (ou nao encontrado)." + Chr(10) +
                     "Configure em Configurar -> Fossauro...",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  Protected Prog = RunProgram(FossauroCfg\ExePath, Fossauro_BuildCliArgs(), GetPathPart(FossauroCfg\ExePath),
                               #PB_Program_Open)
  If Not Prog
    MessageRequester("Fossauro",
                     "Nao foi possivel iniciar o executavel do Fossauro:" + Chr(10) + FossauroCfg\ExePath,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf
  CloseProgram(Prog) ; so libera o identificador do PB - o processo do fossauro continua rodando
  ProcedureReturn #True
EndProcedure

;- ------------------------------------------------------------
;- Pipe de controle (cliente) - fala com o servidor de fossauro/fossauro.pb
;- (PipeServerThreadProc, ver docs/SPEC.md modulo 32u)
;- ------------------------------------------------------------

; Protocolo proprio, texto+binario, deliberadamente NAO o protocolo do
; openMSX (Tcl/XML) - ver o comentario de Fossauro_Launch() acima e o modulo
; 32u. So conversa com uma instancia JA RODANDO (nao lanca o fossauro.exe
; sozinho) - CreateFile_ falhando com #INVALID_HANDLE_VALUE e' o sinal disso.
#Fossauro_PipeName = "\\.\pipe\fossauro"

Procedure.s FossauroPipe_ReadLine(hPipe.i)
  Protected Line.s = ""
  Protected Ch.a
  Protected BytesRead.l
  Repeat
    If Not ReadFile_(hPipe, @Ch, 1, @BytesRead, 0) Or BytesRead = 0
      ProcedureReturn "" ; fossauro fechou a conexao
    EndIf
    If Ch = 10 ; LF
      ProcedureReturn RTrim(Line, Chr(13))
    EndIf
    Line + Chr(Ch)
    If Len(Line) > 4096
      ProcedureReturn ""
    EndIf
  ForEver
EndProcedure

Procedure.b FossauroPipe_WriteRaw(hPipe.i, *Buffer, Length.l)
  Protected Written.l
  ProcedureReturn Bool(WriteFile_(hPipe, *Buffer, Length, @Written, 0) And Written = Length)
EndProcedure

Procedure.b FossauroPipe_WriteLine(hPipe.i, Text.s)
  Protected Line.s = Text + Chr(10)
  Protected ByteLen.l = Len(Line) ; comandos do protocolo sao ASCII puro, 1 byte/char
  Protected *Buf = AllocateMemory(ByteLen)
  PokeS(*Buf, Line, ByteLen, #PB_Ascii | #PB_String_NoZero)
  Protected Ok.b = FossauroPipe_WriteRaw(hPipe, *Buf, ByteLen)
  FreeMemory(*Buf)
  ProcedureReturn Ok
EndProcedure

; Conecta no fossauro ja rodando, manda "LOAD <Addr> <ByteCount>" + os bytes
; de *Payload, depois "RUN <Addr>". Generico de proposito - nao sabe nada
; sobre Mamute/MamuteMem, so recebe um ponteiro/tamanho ja prontos; quem
; chama (MamuteGui_CmdFossauro(), MamuteAssemblerGui.pbi) e' quem monta o
; buffer a partir de Mamute_ReadByte() - assim este arquivo nao depende de
; MamuteSupport.pbi (que e' incluido DEPOIS deste no XIncludeFile de
; BadigEditor.pb - ver a nota de ordem de declaracao no topo do CLAUDE.md).
; Retorna "" em sucesso total, ou uma mensagem de erro pronta pra log.
Procedure.s Fossauro_SendAndRun(Addr.u, *Payload, ByteCount.i)
  Protected hPipe.i = CreateFile_(#Fossauro_PipeName, #GENERIC_READ | #GENERIC_WRITE, 0, 0,
                                   #OPEN_EXISTING, 0, 0)
  If hPipe = #INVALID_HANDLE_VALUE
    ProcedureReturn "fossauro nao esta rodando (ou o pipe de controle nao esta disponivel) - abra Executar -> Fossauro primeiro"
  EndIf

  Protected Result.s = ""
  If Not FossauroPipe_WriteLine(hPipe, "LOAD " + Str(Addr) + " " + Str(ByteCount))
    Result = "falha ao enviar o comando LOAD"
  ElseIf Not FossauroPipe_WriteRaw(hPipe, *Payload, ByteCount)
    Result = "falha ao enviar o codigo-objeto"
  Else
    Protected LoadReply.s = FossauroPipe_ReadLine(hPipe)
    If LoadReply <> "OK"
      Result = "fossauro recusou o LOAD: " + LoadReply
    ElseIf Not FossauroPipe_WriteLine(hPipe, "RUN " + Str(Addr))
      Result = "falha ao enviar o comando RUN"
    Else
      Protected RunReply.s = FossauroPipe_ReadLine(hPipe)
      If RunReply <> "OK"
        Result = "fossauro recusou o RUN: " + RunReply
      EndIf
    EndIf
  EndIf

  CloseHandle_(hPipe)
  ProcedureReturn Result
EndProcedure

; Conecta no fossauro ja rodando, manda "LOAD <Addr> <ByteCount>" + os bytes de *Payload,
; depois digita "DEFUSR0=&H<Addr>" (+ ":A=USR0(0)" se AutoRun) + Enter via TYPE (Case "TYPE",
; fossauro.pb) - NAO usa RUN cru. Pedido explicito do usuario (2026-08-19, ver docs/SPEC.md
; modulo 32y): tecnicamente so' precisa transferir o programa pra RAM, nao rodar - RUN cru
; sequestra PC/SP de uma sessao MSX ja viva (ver o comentario de Fossauro_SendAndRun() acima e
; o modulo 32x), enquanto digitar DEFUSR no prompt de verdade deixa a BIOS/BASIC tratar a
; chamada com o proprio contexto consistente dela. Sintaxe corrigida na mesma sessao (usuario
; apontou o erro ao testar): "DEFUSR0=" (nao "DEFUSR(0)=") e "USR0(0)" (nao "USR(0)") - MSX
; BASIC tem 10 funcoes USR numeradas (USR0-USR9, cada uma com seu proprio DEFUSRn), e "USR(0)"
; sem numero e' a forma de UM UNICO USR (equivalente a DEFUSR0 e' DEFUSR, chamado por USR(0) com
; o "0" sendo so' o argumento passado pra funcao, nao o indice dela) - as duas formas nao se
; misturam. AutoRun (ligado via "Fossauro: executar automaticamente..." em Configurar -> Mamute
; Assembler..., MamuteAutoRunAfterTransfer, default desligado) digita a chamada ":A=USR0(0)" na MESMA
; linha do DEFUSR0, executando assim que o Enter e' "digitado" - ainda passa pelo interpretador
; BASIC de verdade, so' automatiza o "digitar e apertar Enter" manual. Mesma divisao de
; responsabilidade do Fossauro_SendAndRun(): generico, nao sabe nada sobre Mamute/MamuteMem.
Procedure.s Fossauro_SendAndType(Addr.u, *Payload, ByteCount.i, AutoRun.b = #False)
  Protected hPipe.i = CreateFile_(#Fossauro_PipeName, #GENERIC_READ | #GENERIC_WRITE, 0, 0,
                                   #OPEN_EXISTING, 0, 0)
  If hPipe = #INVALID_HANDLE_VALUE
    ProcedureReturn "fossauro nao esta rodando (ou o pipe de controle nao esta disponivel) - abra Executar -> Fossauro primeiro"
  EndIf

  Protected Result.s = ""
  If Not FossauroPipe_WriteLine(hPipe, "LOAD " + Str(Addr) + " " + Str(ByteCount))
    Result = "falha ao enviar o comando LOAD"
  ElseIf Not FossauroPipe_WriteRaw(hPipe, *Payload, ByteCount)
    Result = "falha ao enviar o codigo-objeto"
  Else
    Protected LoadReply.s = FossauroPipe_ReadLine(hPipe)
    If LoadReply <> "OK"
      Result = "fossauro recusou o LOAD: " + LoadReply
    Else
      Protected DefUsrLine.s = "DEFUSR0=&H" + RSet(Hex(Addr & $FFFF), 4, "0")
      If AutoRun
        DefUsrLine + ":A=USR0(0)"
      EndIf
      DefUsrLine + Chr(13)
      Protected TypeBytes.l = Len(DefUsrLine)
      Protected *TypeBuf = AllocateMemory(TypeBytes)
      PokeS(*TypeBuf, DefUsrLine, TypeBytes, #PB_Ascii | #PB_String_NoZero)
      If Not FossauroPipe_WriteLine(hPipe, "TYPE " + Str(TypeBytes)) Or Not FossauroPipe_WriteRaw(hPipe, *TypeBuf, TypeBytes)
        Result = "falha ao enviar o comando TYPE"
      Else
        Protected TypeReply.s = FossauroPipe_ReadLine(hPipe)
        If TypeReply <> "OK"
          Result = "fossauro recusou o TYPE: " + TypeReply
        EndIf
      EndIf
      FreeMemory(*TypeBuf)
    EndIf
  EndIf

  CloseHandle_(hPipe)
  ProcedureReturn Result
EndProcedure

;- ------------------------------------------------------------
;- Tela "Configurar -> Fossauro..."
;- ------------------------------------------------------------

Procedure FossauroSettings_OpenWindow(ParentWindow, OverridePath.s = "")
  FossauroCfg_Load(OverridePath)
  If FossauroCfg\ExePath = ""
    FossauroCfg\ExePath = Fossauro_FindExe()
  EndIf

  Protected WinW = 680, WinH = 440
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Configurar - Fossauro",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  TextGadget(#PB_Any, 24, 24, WinW - 48, 40,
            "Fossauro e o emulador de MSX nativo do projeto (nao incorporado a esta IDE - so" + Chr(10) +
            "chamado como executavel externo). Configuracoes padrao usadas em Executar -> Fossauro.")

  TextGadget(#PB_Any, 24, 76, WinW - 48, 20, "Caminho do executavel (fossauro/fossauro.exe)")
  Protected G_ExePath = StringGadget(#PB_Any, 24, 104, WinW - 24 - 64 - 32, 24, FossauroCfg\ExePath)
  Protected G_ExePathBrowse = ThemedButton(WinW - 24 - 64, 104, 64, 24, "...", "")

  TextGadget(#PB_Any, 24, 148, 180, 20, "Tipo de maquina")
  Protected G_Model = ComboBoxGadget(#PB_Any, 24, 176, 180, 24)
  AddGadgetItem(G_Model, -1, "MSX1")
  AddGadgetItem(G_Model, -1, "MSX2")
  AddGadgetItem(G_Model, -1, "MSX2+")

  TextGadget(#PB_Any, 228, 148, 180, 20, "RAM")
  Protected G_RAM = ComboBoxGadget(#PB_Any, 228, 176, 180, 24)
  AddGadgetItem(G_RAM, -1, "64 KB")
  AddGadgetItem(G_RAM, -1, "128 KB")
  AddGadgetItem(G_RAM, -1, "256 KB")
  AddGadgetItem(G_RAM, -1, "512 KB")
  AddGadgetItem(G_RAM, -1, "1024 KB")

  TextGadget(#PB_Any, 432, 148, 180, 20, "VRAM")
  Protected G_VRAM = ComboBoxGadget(#PB_Any, 432, 176, 180, 24)
  AddGadgetItem(G_VRAM, -1, "16 KB")
  AddGadgetItem(G_VRAM, -1, "32 KB")
  AddGadgetItem(G_VRAM, -1, "64 KB")
  AddGadgetItem(G_VRAM, -1, "128 KB")
  AddGadgetItem(G_VRAM, -1, "192 KB")

  Protected G_Pal = CheckBoxGadget(#PB_Any, 24, 220, 260, 22, "Temporizacao PAL (desmarcado = NTSC)")
  Protected G_Verbose = CheckBoxGadget(#PB_Any, 300, 220, 340, 22, "Log verboso (-verbose, grava fossauro.log)")

  TextGadget(#PB_Any, 24, 264, WinW - 48, 20, "Cartucho padrao ao iniciar (opcional)")
  Protected G_CartPath = StringGadget(#PB_Any, 24, 292, WinW - 24 - 64 - 32, 24, FossauroCfg\CartridgePath)
  Protected G_CartPathBrowse = ThemedButton(WinW - 24 - 64, 292, 64, 24, "...", "")

  Protected G_Save = ThemedButton(WinW - 256, WinH - 56, 110, 32, "Salvar", Chr(#Icon_Save))
  GadgetToolTip(G_Save, "Salvar")
  Protected G_Cancel = ThemedButton(WinW - 134, WinH - 56, 110, 32, "Cancelar", "")

  Select FossauroCfg\Model
    Case "2"  : SetGadgetState(G_Model, 1)
    Case "2+" : SetGadgetState(G_Model, 2)
    Default   : SetGadgetState(G_Model, 0)
  EndSelect

  Select FossauroCfg\RAMPages
    Case 8  : SetGadgetState(G_RAM, 1)
    Case 16 : SetGadgetState(G_RAM, 2)
    Case 32 : SetGadgetState(G_RAM, 3)
    Case 64 : SetGadgetState(G_RAM, 4)
    Default : SetGadgetState(G_RAM, 0) ; 4 paginas / 64KB
  EndSelect

  Select FossauroCfg\VRAMPages
    Case 2  : SetGadgetState(G_VRAM, 1)
    Case 4  : SetGadgetState(G_VRAM, 2)
    Case 8  : SetGadgetState(G_VRAM, 3)
    Case 12 : SetGadgetState(G_VRAM, 4)
    Default : SetGadgetState(G_VRAM, 0) ; 1 pagina / 16KB
  EndSelect

  SetGadgetState(G_Pal, FossauroCfg\Pal)
  SetGadgetState(G_Verbose, FossauroCfg\Verbose)

  Protected Event, Quit = #False, Saved = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_ExePathBrowse
            CompilerIf #PB_Compiler_OS = #PB_OS_Windows
              Protected ExeFilter.s = "Executavel (*.exe)|*.exe|Todos os arquivos (*.*)|*.*"
            CompilerElse
              Protected ExeFilter.s = "Todos os arquivos (*.*)|*.*"
            CompilerEndIf
            Protected PickExePath.s = OpenFileRequester("Selecione o executavel do Fossauro",
                                                        GetGadgetText(G_ExePath), ExeFilter, 0)
            If PickExePath <> ""
              SetGadgetText(G_ExePath, PickExePath)
            EndIf

          Case G_CartPathBrowse
            Protected CartFilter.s = "ROM MSX (*.rom;*.mx1;*.mx2)|*.rom;*.mx1;*.mx2|Todos os arquivos (*.*)|*.*"
            Protected PickCartPath.s = OpenFileRequester("Selecione o cartucho padrao",
                                                         GetGadgetText(G_CartPath), CartFilter, 0)
            If PickCartPath <> ""
              SetGadgetText(G_CartPath, PickCartPath)
            EndIf

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
    FossauroCfg\ExePath = GetGadgetText(G_ExePath)
    Select GetGadgetState(G_Model)
      Case 1  : FossauroCfg\Model = "2"
      Case 2  : FossauroCfg\Model = "2+"
      Default : FossauroCfg\Model = "1"
    EndSelect
    Select GetGadgetState(G_RAM)
      Case 1  : FossauroCfg\RAMPages = 8
      Case 2  : FossauroCfg\RAMPages = 16
      Case 3  : FossauroCfg\RAMPages = 32
      Case 4  : FossauroCfg\RAMPages = 64
      Default : FossauroCfg\RAMPages = 4
    EndSelect
    Select GetGadgetState(G_VRAM)
      Case 1  : FossauroCfg\VRAMPages = 2
      Case 2  : FossauroCfg\VRAMPages = 4
      Case 3  : FossauroCfg\VRAMPages = 8
      Case 4  : FossauroCfg\VRAMPages = 12
      Default : FossauroCfg\VRAMPages = 1
    EndSelect
    FossauroCfg\Pal = GetGadgetState(G_Pal)
    FossauroCfg\Verbose = GetGadgetState(G_Verbose)
    FossauroCfg\CartridgePath = GetGadgetText(G_CartPath)
    FossauroCfg_Save(OverridePath)
  EndIf

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
