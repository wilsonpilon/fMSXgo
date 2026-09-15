;
; ------------------------------------------------------------
;  Z80OutputGui.pbi - o que fazer com os bytes de um binario ja montado (modo
;  absoluto, Executar -> Montar Assembly (.bin)...), ja linkado (Executar ->
;  Linkar (.REL) -> binario..., ver Z80LinkGui.pbi) ou ja construido por um
;  subprojeto (Criar -> Assembly Sub Project..., ver Z80SubProjectGui.pbi):
;  quatro caminhos de saida, cobrindo tanto MSX-BASIC quanto MSX-DOS puro:
;    1) .bin no PC, com ou sem cabecalho MSX BLOAD (consumido pelo
;       MSX-BASIC).
;    2) .COM pronto pro MSX-DOS (sem cabecalho nenhum, sempre carregado em
;       0100h - o assembler funciona 100% independente do MSX-BASIC nesse
;       caminho, avisa se o fonte nao foi montado pra 0100h).
;    3) Disco MSX (.dsk) pronto pra rodar via AUTOEXEC.BAS ("BLOAD...,R") -
;       reaproveita MSXDisk.pbi, mesmo mecanismo ja usado por RunOnOpenMSX()
;       em BadigEditor.pb pro fluxo Dignified.
;    4) Listing BASIC (FOR/READ/POKE + DATA em hexa) pra colar dentro de um
;       programa MSX-BASIC sem precisar carregar um arquivo a parte - mesmo
;       espirito de PsgGen_RawBytes (PsgSynth.pbi), mas com o loop de POKE
;       que o PSG nao precisa (o PSG so gera uma tabela de dados pra uma
;       futura rotina Z80, nao um binario que precisa ir pra um endereco
;       especifico da RAM).
;  Cada exportacao que produz um arquivo de verdade (.bin/.com/.dsk, nao o
;  listing, que so vai pra area de transferencia/cursor) registra o metadado
;  em ProjectDB::StoreAsmBuild() quando SourceKey <> "" - ver comentario da
;  declaracao em ProjectDB.pbi.
; ------------------------------------------------------------
;

; Gera um loop FOR/READ/POKE + blocos DATA (16 bytes por linha, hexa) que
; carrega o binario montado no endereco StartAddr - o caminho "consumivel
; sem precisar carregar arquivo nenhum" pedido no modulo 2c do SPEC. Nomes de
; variavel ZZ1/ZZ2 (mesma convencao ja usada em PsgGen_BasicLines, que evita
; colidir com variaveis do programa do usuario).
Procedure.s Z80Gen_BasicLoader(Array Bytes.a(1), NBytes.i, StartAddr.u)
  Protected Result.s = ""
  Protected HexStart.s = "&H" + Hex(StartAddr, #PB_Word)
  Protected DisplayHex.s = Hex(StartAddr, #PB_Word) + "h"

  Result + "' Codigo Z80 montado - " + Str(NBytes) + " bytes, carrega em " + DisplayHex + #CRLF$
  Result + "FOR ZZ1=0 TO " + Str(NBytes - 1) + #CRLF$
  Result + "READ ZZ2" + #CRLF$
  Result + "POKE " + HexStart + "+ZZ1,ZZ2" + #CRLF$
  Result + "NEXT ZZ1" + #CRLF$
  Result + "' Para chamar: DEFUSR=" + HexStart + " : A=USR(0)" + #CRLF$

  Protected i, Col = 0
  Protected Line.s = ""
  For i = 0 To NBytes - 1
    If Col = 0
      Line = "DATA "
    Else
      Line + ","
    EndIf
    Line + "&H" + RSet(Hex(Bytes(i), #PB_Byte), 2, "0")
    Col + 1
    If Col = 16 Or i = NBytes - 1
      Result + Line + #CRLF$
      Col = 0
    EndIf
  Next

  ProcedureReturn Result
EndProcedure

; Mesmo texto/opcoes que AssembleZ80FromActiveTab ja perguntava antes desta
; extracao - so virou uma funcao a parte pra ser reaproveitada pelo linker
; tambem. Retorno: -1 cancelou, 0 sem cabecalho, 1 com cabecalho.
Procedure.i Z80Out_AskBLoadHeaderChoice(NBytes.i, StartAddr.u, EndAddr.u)
  Protected HexStart.s = Hex(StartAddr, #PB_Word)
  Protected HexEnd.s = Hex(EndAddr, #PB_Word)
  Protected Q.s = Chr(34)
  Protected MsgTxt.s = "Montado: " + Str(NBytes) + " bytes, endereco " + HexStart + "h-" + HexEnd + "h." + Chr(10) + Chr(10) +
    "Adicionar cabecalho MSX BLOAD (pra carregar com BLOAD" + Q + "..." + Q + ",R do MSX-BASIC)?" + Chr(10) +
    "Sim = .bin com cabecalho (endereco de execucao = " + HexStart + "h, igual ao de carga)" + Chr(10) +
    "Nao = binario cru (mesmo formato de um .COM quando o fonte usa ORG 100h)"
  Protected Choice = MessageRequester("Montar", MsgTxt, #PB_MessageRequester_YesNoCancel | #PB_MessageRequester_Info)
  If Choice = #PB_MessageRequester_Cancel
    ProcedureReturn -1
  EndIf
  ProcedureReturn Bool(Choice = #PB_MessageRequester_Yes)
EndProcedure

; Grava Bytes(0..NBytes-1) em Path, com o cabecalho classico MSX BLOAD (FE +
; inicio + fim + execucao, escrito byte a byte de proposito - nao WriteWord,
; pra nao depender da ordem de bytes nativa da plataforma que compila o
; editor) quando AddHeader. Mesmo codigo que ja existia embutido em
; AssembleZ80FromActiveTab.
Procedure.i Z80Out_WriteBinFile(Path.s, Array Bytes.a(1), NBytes.i, StartAddr.u, EndAddr.u, AddHeader.b)
  Protected FileNum = CreateFile(#PB_Any, Path)
  If Not FileNum
    ProcedureReturn #False
  EndIf

  If AddHeader
    WriteByte(FileNum, $FE)
    WriteByte(FileNum, StartAddr & $FF) : WriteByte(FileNum, (StartAddr >> 8) & $FF)
    WriteByte(FileNum, EndAddr & $FF)   : WriteByte(FileNum, (EndAddr >> 8) & $FF)
    WriteByte(FileNum, StartAddr & $FF) : WriteByte(FileNum, (StartAddr >> 8) & $FF)
  EndIf

  Protected *Buf = AllocateMemory(NBytes)
  Protected Idx
  For Idx = 0 To NBytes - 1
    PokeB(*Buf + Idx, Bytes(Idx))
  Next
  WriteData(FileNum, *Buf, NBytes)
  CloseFile(FileNum)
  FreeMemory(*Buf)
  ProcedureReturn #True
EndProcedure

; Caminho 1: .bin solto no PC, pergunta cabecalho, grava, registra no
; projeto (StoreAsmBuild) quando SourceKey <> "".
Procedure Z80Out_ExportBin(SuggestBaseName.s, Array Bytes.a(1), NBytes.i, StartAddr.u, EndAddr.u, SourceKey.s, BuildKind.s)
  Protected HeaderChoice = Z80Out_AskBLoadHeaderChoice(NBytes, StartAddr, EndAddr)
  If HeaderChoice = -1
    ProcedureReturn
  EndIf

  Protected SavePath.s = SaveFileRequester("Salvar binario montado", SuggestBaseName + ".bin",
                                           "Binario Z80 (*.bin)|*.bin|Todos os arquivos (*.*)|*.*", 0)
  If SavePath = ""
    ProcedureReturn
  EndIf
  SavePath = EnsureExtension(SavePath, "bin")

  If Not Z80Out_WriteBinFile(SavePath, Bytes(), NBytes, StartAddr, EndAddr, HeaderChoice)
    MessageRequester("Erro", "Nao foi possivel salvar o arquivo:" + Chr(10) + SavePath,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  If SourceKey <> ""
    ProjectDB::StoreAsmBuild(SourceKey, BuildKind, "BIN", SavePath, StartAddr, EndAddr, HeaderChoice)
  EndIf

  MessageRequester("Montado", Str(NBytes) + " bytes salvos em:" + Chr(10) + SavePath,
                   #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
EndProcedure

; Caminho 2: .COM pronto pra rodar direto do MSX-DOS (sem passar pelo
; MSX-BASIC/BLOAD nenhum) - binario cru, SEM cabecalho (diferente do caminho
; 1, que pergunta) porque um .COM classico CP/M/MSX-DOS nao tem cabecalho
; nenhum: o carregador do sistema operacional sempre poe o codigo em 0100h e
; pula pra la, o proprio ORG 100h do fonte e o que faz esse endereco bater
; com o que o assembler calculou. Avisa (sem bloquear) se o fonte foi
; montado pra outro endereco, porque nesse caso o binario ainda e gravado
; mas provavelmente nao vai rodar certo (enderecos absolutos calculados a
; partir de outro ORG).
Procedure Z80Out_ExportCom(SuggestBaseName.s, Array Bytes.a(1), NBytes.i, StartAddr.u, EndAddr.u, SourceKey.s, BuildKind.s)
  If StartAddr <> $100
    Protected WarnTxt.s = "O codigo foi montado para o endereco " + Hex(StartAddr, #PB_Word) + "h, nao " + Hex($100, #PB_Word) + "h." + Chr(10) + Chr(10) +
      "Um .COM e sempre carregado em 0100h pelo MSX-DOS/CP-M, independente do ORG do fonte - se o " +
      "codigo usa enderecos absolutos calculados a partir de outro ORG, ele provavelmente nao vai " +
      "funcionar certo." + Chr(10) + Chr(10) + "Salvar mesmo assim?"
    If MessageRequester("Endereco diferente de 0100h", WarnTxt, #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_No
      ProcedureReturn
    EndIf
  EndIf

  Protected SavePath.s = SaveFileRequester("Salvar .COM (MSX-DOS)", SuggestBaseName + ".com",
                                           "Programa MSX-DOS (*.com)|*.com|Todos os arquivos (*.*)|*.*", 0)
  If SavePath = ""
    ProcedureReturn
  EndIf
  SavePath = EnsureExtension(SavePath, "com")

  If Not Z80Out_WriteBinFile(SavePath, Bytes(), NBytes, StartAddr, EndAddr, #False)
    MessageRequester("Erro", "Nao foi possivel salvar o arquivo:" + Chr(10) + SavePath,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  If SourceKey <> ""
    ProjectDB::StoreAsmBuild(SourceKey, BuildKind, "COM", SavePath, StartAddr, EndAddr, #False)
  EndIf

  MessageRequester("Montado", Str(NBytes) + " bytes salvos em:" + Chr(10) + SavePath,
                   #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
EndProcedure

; Caminho 3: disco MSX (.dsk) com AUTOEXEC.BAS ("10 BLOAD"NOME.BIN",R") -
; sempre grava com cabecalho (BLOAD,R depende dele pra saber endereco de
; carga/execucao, diferente do caminho 1/bin que pergunta) - reaproveita
; MSXDisk.pbi, mesmo mecanismo ja usado por RunOnOpenMSX() (BadigEditor.pb)
; pro fluxo Dignified. Arquivos intermediarios ficam na pasta temporaria do
; sistema e sao apagados depois de montar o disco.
Procedure Z80Out_ExportDisk(SuggestBaseName.s, Array Bytes.a(1), NBytes.i, StartAddr.u, EndAddr.u, SourceKey.s, BuildKind.s)
  Protected DskPath.s = SaveFileRequester("Salvar disco MSX", SuggestBaseName + ".dsk",
                                          "Disco MSX (*.dsk)|*.dsk|Todos os arquivos (*.*)|*.*", 0)
  If DskPath = ""
    ProcedureReturn
  EndIf
  DskPath = EnsureExtension(DskPath, "dsk")

  Protected UBase.s = Left(UCase(GetFilePart(SuggestBaseName, #PB_FileSystem_NoExtension)), 8)
  If UBase = ""
    UBase = "PROGRAM"
  EndIf

  Protected TempDir.s = GetTemporaryDirectory()
  Protected BinTemp.s = TempDir + "z80out_" + UBase + ".bin"
  Protected AutoexecTemp.s = TempDir + "z80out_autoexec.bas"

  If Not Z80Out_WriteBinFile(BinTemp, Bytes(), NBytes, StartAddr, EndAddr, #True)
    MessageRequester("Erro", "Nao foi possivel preparar o binario temporario.",
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  Protected f = CreateFile(#PB_Any, AutoexecTemp)
  If f
    WriteString(f, "10 BLOAD" + Chr(34) + UBase + ".BIN" + Chr(34) + ",R" + Chr(13) + Chr(10))
    CloseFile(f)
  EndIf

  Protected Ok.b = MSXDisk::CreateDisk(DskPath)
  If Ok : Ok = MSXDisk::AddFile(BinTemp, UBase + ".BIN") : EndIf
  If Ok : Ok = MSXDisk::AddFile(AutoexecTemp, "AUTOEXEC.BAS") : EndIf
  Protected DiskErr.s = MSXDisk::GetLastErrorMessage()
  MSXDisk::CloseDisk()

  DeleteFile(BinTemp)
  DeleteFile(AutoexecTemp)

  If Not Ok
    MessageRequester("Erro ao montar o disco", DiskErr,
                     #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  If SourceKey <> ""
    ProjectDB::StoreAsmBuild(SourceKey, BuildKind, "DSK", DskPath, StartAddr, EndAddr, #True)
  EndIf

  MessageRequester("Disco gravado", "Disco MSX salvo em:" + Chr(10) + DskPath + Chr(10) + Chr(10) +
                   "AUTOEXEC.BAS carrega e roda " + UBase + ".BIN automaticamente (BLOAD,R).",
                   #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
EndProcedure

; Caminho 4: listing BASIC (FOR/READ/POKE + DATA) - nao produz arquivo
; nenhum (so vai pra area de transferencia ou pro cursor da aba ativa), por
; isso nao chama StoreAsmBuild (ver comentario da declaracao em
; ProjectDB.pbi: so builds que viram arquivo de verdade sao registradas).
Procedure Z80Out_ShowListing(Array Bytes.a(1), NBytes.i, StartAddr.u, ParentWindow.i)
  Protected ListingText.s = Z80Gen_BasicLoader(Bytes(), NBytes, StartAddr)

  Protected WinW = 580, WinH = 460
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Listing BASIC (DATA/POKE)",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_SizeGadget)
  If Not Win
    ProcedureReturn
  EndIf

  Protected G_Text = EditorGadget(#PB_Any, 24, 24, WinW - 48, 364)
  SetGadgetText(G_Text, ListingText)
  Protected G_Copy = ThemedButton(24, 404, 100, 32, "Copiar", Chr(#Icon_Copy))
  GadgetToolTip(G_Copy, "Copiar")
  Protected G_Inject = ThemedButton(136, 404, 150, 32, "Injetar no cursor", Chr(#Icon_Insert))
  GadgetToolTip(G_Inject, "Injetar no cursor")
  Protected G_Close = ThemedButton(WinW - 24 - 110, 404, 110, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_Copy
            SetClipboardText(GetGadgetText(G_Text))
          Case G_Inject
            If Not InjectTextAtCursor(GetGadgetText(G_Text))
              MessageRequester("Erro", "Nenhuma aba de texto ativa para injetar o codigo.",
                               #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
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

; Janela pequena de escolha, reaproveitada por "Montar Assembly (.bin)"
; (modo absoluto), "Linkar (.REL) -> binario" (Z80LinkGui.pbi) e "Assembly
; Sub Project -> Montar tudo" (Z80SubProjectGui.pbi) - um so lugar pra
; decidir o que fazer com um binario ja pronto. SourceKey/BuildKind
; alimentam ProjectDB::StoreAsmBuild() quando a exportacao produz arquivo de
; verdade (bin/com/disco) - "" desliga o registro (usado quando nao ha uma
; chave estavel, ex. aba ainda sem salvar).
Procedure Z80Out_ChooseAndExport(SuggestBaseName.s, Array Bytes.a(1), NBytes.i, StartAddr.u, EndAddr.u, SourceKey.s, BuildKind.s, ParentWindow.i)
  Protected WinW = 400, WinH = 276
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Saida da montagem",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  Protected InfoTxt.s = Str(NBytes) + " bytes, endereco " + Hex(StartAddr, #PB_Word) + "h-" + Hex(EndAddr, #PB_Word) + "h."
  TextGadget(#PB_Any, 24, 24, WinW - 48, 20, InfoTxt)

  Protected G_Bin    = ThemedButton(24, 60, WinW - 48, 32, "Salvar .bin no PC...", Chr(#Icon_Save))
  GadgetToolTip(G_Bin, "Salvar .bin no PC...")
  Protected G_Com    = ThemedButton(24, 100, WinW - 48, 32, "Gerar .COM (MSX-DOS, independente do BASIC)...", "")
  Protected G_Dsk    = ThemedButton(24, 140, WinW - 48, 32, "Gravar disco MSX (.dsk, BLOAD)...", Chr(#Icon_Save))
  GadgetToolTip(G_Dsk, "Gravar disco MSX (.dsk, BLOAD)...")
  Protected G_List   = ThemedButton(24, 180, WinW - 48, 32, "Gerar listing BASIC (DATA/POKE)...", "")
  Protected G_Cancel = ThemedButton(24, 220, WinW - 48, 32, "Cancelar", "")

  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_Bin
            Z80Out_ExportBin(SuggestBaseName, Bytes(), NBytes, StartAddr, EndAddr, SourceKey, BuildKind)
            Quit = #True
          Case G_Com
            Z80Out_ExportCom(SuggestBaseName, Bytes(), NBytes, StartAddr, EndAddr, SourceKey, BuildKind)
            Quit = #True
          Case G_Dsk
            Z80Out_ExportDisk(SuggestBaseName, Bytes(), NBytes, StartAddr, EndAddr, SourceKey, BuildKind)
            Quit = #True
          Case G_List
            Z80Out_ShowListing(Bytes(), NBytes, StartAddr, Win)
            Quit = #True
          Case G_Cancel
            Quit = #True
        EndSelect
      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
