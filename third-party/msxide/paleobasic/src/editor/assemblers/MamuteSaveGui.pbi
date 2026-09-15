;
; ------------------------------------------------------------
;  Comando SAVE do Mamute Assembler - pedido explicito do usuario, mesmo
;  espirito do LOAD: uma janela normal (nao terminal preto/verde, estilo
;  "Configurar -> Mamute Assembler...") em vez de tudo digitado na linha de
;  comando. "SAVE [<nome>][,<endinic>,<endfim>[,<endexec>]]" pode sugerir
;  nome de arquivo e enderecos direto no comando, mas a janela sempre abre
;  pra revisar/editar tudo antes de gravar de verdade - nada e salvo so por
;  digitar o comando.
;
;  Campos da janela:
;  - Arquivo (StringGadget editavel + botao "..." com SaveFileRequester,
;    sugerido a partir do nome digitado no comando, se houver).
;  - Slot (0-3) - sugerido a partir do mapeamento ATIVO (MamutePageMap())
;    na pagina do endereco inicial informado no comando (ou pagina 1 se
;    nenhum endereco foi digitado ainda) - sempre editavel, pedido
;    explicito do usuario ("sugira a configuracao de SLOT corrente... mas
;    permita que o usuario edite").
;  - Endereco inicial/final/execucao - pre-preenchidos se vieram no
;    comando, sempre editaveis; execucao vazio = igual ao inicial (mesma
;    regra do SAVE do manual original).
;  - Formato: BIN (cabecalho real do BSAVE do MSX: byte FE + 3 enderecos,
;    2 bytes cada) ou ROM (cabecalho analogo pedido pelo usuario: "AB" + os
;    mesmos 3 enderecos, em vez do FE - NAO e o cabecalho real de cartucho
;    MSX de 16 bytes com INIT/STATEMENT/DEVICE/TEXT, e um formato proprio
;    mais simples deste simulador, do jeito que o usuario descreveu). Some
;    o padrao pra ROM se a extensao do arquivo for ".rom", mas o usuario
;    pode trocar o combo a qualquer momento - o combo manda na hora de
;    salvar, a extensao so decide o valor inicial.
;  - Checkbox "sem cabecalho" - ignora o formato escolhido acima e grava so
;    os bytes crus, sem nenhum cabecalho.
;
;  Le direto de MamuteMem(Slot,...) pro range pedido (mesma logica do LOAD,
;  bypass do PAGE/Mamute_ReadByte - o usuario escolhe explicitamente de
;  qual slot fisico ler, nao do que estiver mapeado ativo agora) - EXCETO
;  quando chamado com UseExplicitBuffer = #True (opcao I do comando A do
;  EDIT, MamuteEditGui.pbi, pedido explicito do usuario: "a I... salva em
;  DISCO o arquivo, abre o dialogo de save, e salva o header &HFE, os
;  enderecos inicial, final e execucao (ja sugira no dialogo), o slot (ja
;  sugira os ativos no momento)... o binario e criado no formato para o
;  BLOAD do BASIC ou LOAD do Mamute Assembler") - nesse caso os bytes vem
;  DIRETO de ExplicitBuf() (o codigo-objeto recem montado, indice 0 =
;  InStart), sem depender de nada ja ter sido escrito em MamuteMem (ao
;  contrario de "A O", que escreve na RAM simulada - "A I" nao precisa de
;  "A O" antes, exporta o buffer da montagem direto pro arquivo). O campo
;  Slot da janela nesse modo e' so' INFORMATIVO/sugestao (o formato
;  BLOAD/BSAVE real do MSX nao tem byte de slot) - editar o intervalo de
;  enderecos na janela ALEM do que foi montado preenche com zero (protegido
;  contra estourar ExplicitBuf(), que so' tem ByteCount elementos).
;
;  Devolve uma string de resultado (log do MON>) em vez de tocar
;  G_Log/MamuteGui_State diretamente - MamuteGui_State so e declarado mais
;  tarde em MamuteAssemblerGui.pbi (este arquivo e XIncludeFile'd antes),
;  mesma razao de MamuteScr_Open/MamuteZap_Open serem independentes do
;  resto do monitor. "" = cancelado, sem nada pra logar.
; ------------------------------------------------------------
;

; SvStart/SvEnd/SvExec ja em CPU-endereco (0-65535); Pagina derivada de
; SvStart pra sugerir o slot.
Procedure.i MamuteSave_SuggestSlot(HasAddrs.b, SvStart.i)
  Protected Pagina.i = 1 ; pagina de referencia (4000) se nenhum endereco foi informado ainda
  If HasAddrs
    Pagina = (SvStart >> 14) & 3
  EndIf
  ProcedureReturn MamutePageMap(Pagina)
EndProcedure

; Recalcula o combo de Formato a partir da extensao atual do campo Arquivo -
; so muda o valor SUGERIDO, o usuario pode trocar depois livremente.
Procedure MamuteSave_SyncFormat(G_File, G_Format)
  Protected Ext.s = LCase(GetExtensionPart(GetGadgetText(G_File)))
  If Ext = "rom"
    SetGadgetState(G_Format, 1)
  Else
    SetGadgetState(G_Format, 0)
  EndIf
EndProcedure

Procedure.s MamuteSave_Open(ParentWindow, SuggestedName.s, HasAddrs.b, InStart.i, InEnd.i, InExec.i, UseExplicitBuffer.b, Array ExplicitBuf.a(1))
  Protected WinW = 560
  Protected Margin = 20, RowH = 32, LabelW = 160

  Protected DefaultSlot.i = MamuteSave_SuggestSlot(HasAddrs, InStart)

  Protected WinH = Margin + RowH * 7 + 16 + 40 + Margin
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Mamute Assembler - SAVE",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn ""
  EndIf

  Protected CurY = Margin

  TextGadget(#PB_Any, Margin, CurY + 4, LabelW, 20, "Arquivo:")
  Protected G_File = StringGadget(#PB_Any, Margin + LabelW, CurY, WinW - Margin * 2 - LabelW - 64 - 8, 24, SuggestedName)
  Protected G_Browse = ThemedButton(WinW - Margin - 64, CurY - 2, 64, 26, "...", "")
  CurY + RowH

  TextGadget(#PB_Any, Margin, CurY + 4, LabelW, 20, "Slot (0-3):")
  Protected G_Slot = ComboBoxGadget(#PB_Any, Margin + LabelW, CurY, 100, 24)
  AddGadgetItem(G_Slot, -1, "0")
  AddGadgetItem(G_Slot, -1, "1")
  AddGadgetItem(G_Slot, -1, "2")
  AddGadgetItem(G_Slot, -1, "3")
  SetGadgetState(G_Slot, DefaultSlot)
  CurY + RowH

  TextGadget(#PB_Any, Margin, CurY + 4, LabelW, 20, "Endereco inicial:")
  Protected G_Start = StringGadget(#PB_Any, Margin + LabelW, CurY, 100, 24, "")
  If HasAddrs : SetGadgetText(G_Start, Mamute_Hex4(InStart)) : EndIf
  CurY + RowH

  TextGadget(#PB_Any, Margin, CurY + 4, LabelW, 20, "Endereco final:")
  Protected G_End = StringGadget(#PB_Any, Margin + LabelW, CurY, 100, 24, "")
  If HasAddrs : SetGadgetText(G_End, Mamute_Hex4(InEnd)) : EndIf
  CurY + RowH

  TextGadget(#PB_Any, Margin, CurY + 4, LabelW, 20, "Endereco de execucao:")
  Protected G_Exec = StringGadget(#PB_Any, Margin + LabelW, CurY, 100, 24, "")
  If HasAddrs : SetGadgetText(G_Exec, Mamute_Hex4(InExec)) : EndIf
  TextGadget(#PB_Any, Margin + LabelW + 108, CurY + 4, WinW - Margin - LabelW - 108, 20, "(vazio = igual ao inicial)")
  CurY + RowH

  TextGadget(#PB_Any, Margin, CurY + 4, LabelW, 20, "Formato:")
  Protected G_Format = ComboBoxGadget(#PB_Any, Margin + LabelW, CurY, 220, 24)
  AddGadgetItem(G_Format, -1, "BIN (cabecalho FE + enderecos)")
  AddGadgetItem(G_Format, -1, "ROM (cabecalho AB + enderecos)")
  MamuteSave_SyncFormat(G_File, G_Format)
  CurY + RowH

  Protected G_Headerless = CheckBoxGadget(#PB_Any, Margin + LabelW, CurY, WinW - Margin - LabelW, 22,
                                          "Salvar sem cabecalho (dados brutos)")
  CurY + RowH + 16

  Protected G_Save = ThemedButton(WinW - 256, CurY, 110, 32, "Salvar", Chr(#Icon_Save))
  Protected G_Cancel = ThemedButton(WinW - 134, CurY, 110, 32, "Cancelar", "")

  Protected ResultMsg.s = ""
  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_Browse
            Protected Ext.s = LCase(GetExtensionPart(GetGadgetText(G_File)))
            Protected Pattern.s = "Binario (*.bin)|*.bin|Cartucho ROM (*.rom)|*.rom|Todos os arquivos (*.*)|*.*"
            Protected PatPos.i = 0
            If Ext = "rom" : PatPos = 1 : EndIf
            Protected Picked.s = SaveFileRequester("Salvar arquivo - SAVE", GetGadgetText(G_File), Pattern, PatPos)
            If Picked <> ""
              SetGadgetText(G_File, Picked)
              MamuteSave_SyncFormat(G_File, G_Format)
            EndIf

          Case G_File
            If EventType() = #PB_EventType_Change
              MamuteSave_SyncFormat(G_File, G_Format)
            EndIf

          Case G_Save
            Protected SaveFilePath.s = Trim(GetGadgetText(G_File))
            If SaveFilePath = ""
              MessageRequester("SAVE", "Informe o nome do arquivo.", #PB_MessageRequester_Error)
              Continue
            EndIf

            Protected SvStart.i, SvEnd.i, SvExec.i
            If Not Mamute_ParseHexAddr(Trim(GetGadgetText(G_Start)), @SvStart) Or
               Not Mamute_ParseHexAddr(Trim(GetGadgetText(G_End)), @SvEnd)
              MessageRequester("SAVE", "Endereco inicial/final invalido - use hexa, 0000 a FFFF.", #PB_MessageRequester_Error)
              Continue
            EndIf
            If SvEnd < SvStart
              MessageRequester("SAVE", "O endereco final precisa ser maior ou igual ao inicial.", #PB_MessageRequester_Error)
              Continue
            EndIf
            Protected ExecTxt.s = Trim(GetGadgetText(G_Exec))
            If ExecTxt = ""
              SvExec = SvStart
            ElseIf Not Mamute_ParseHexAddr(ExecTxt, @SvExec)
              MessageRequester("SAVE", "Endereco de execucao invalido - use hexa, 0000 a FFFF.", #PB_MessageRequester_Error)
              Continue
            EndIf

            Protected SvSlot.i = GetGadgetState(G_Slot)
            Protected SvFormat.i = GetGadgetState(G_Format)
            Protected SvHeaderless.b = GetGadgetState(G_Headerless)

            Protected SvLen.i = SvEnd - SvStart + 1
            Protected HeaderLen.i = 0
            If Not SvHeaderless
              If SvFormat = 1 : HeaderLen = 8 : Else : HeaderLen = 7 : EndIf
            EndIf

            Protected Dim FullBuf.a(HeaderLen + SvLen - 1)
            Protected hp.i = 0
            If Not SvHeaderless
              If SvFormat = 1
                FullBuf(0) = Asc("A") : FullBuf(1) = Asc("B")
                hp = 2
              Else
                FullBuf(0) = $FE
                hp = 1
              EndIf
              FullBuf(hp) = SvStart & $FF         : FullBuf(hp + 1) = (SvStart >> 8) & $FF
              FullBuf(hp + 2) = SvEnd & $FF        : FullBuf(hp + 3) = (SvEnd >> 8) & $FF
              FullBuf(hp + 4) = SvExec & $FF       : FullBuf(hp + 5) = (SvExec >> 8) & $FF
              hp + 6
            EndIf

            Protected i.i, Addr.i, Pagina.i, Offset.i
            If UseExplicitBuffer
              ; "A I" - bytes vem direto do buffer da montagem recem feita,
              ; nao de MamuteMem(). Fora do alcance realmente montado
              ; (usuario editou o intervalo na janela pra algo maior) vira
              ; zero, protegido contra estourar ExplicitBuf().
              For i = 0 To SvLen - 1
                If i <= ArraySize(ExplicitBuf())
                  FullBuf(hp + i) = ExplicitBuf(i)
                Else
                  FullBuf(hp + i) = 0
                EndIf
              Next
            Else
              For i = 0 To SvLen - 1
                Addr = (SvStart + i) & $FFFF
                Pagina = (Addr >> 14) & 3
                Offset = Addr & 16383
                FullBuf(hp + i) = MamuteMem(SvSlot, Pagina, Offset)
              Next
            EndIf

            Protected Fh = CreateFile(#PB_Any, SaveFilePath)
            If Not Fh
              MessageRequester("SAVE", "Nao foi possivel criar o arquivo: " + SaveFilePath, #PB_MessageRequester_Error)
              Continue
            EndIf
            WriteData(Fh, @FullBuf(0), HeaderLen + SvLen)
            CloseFile(Fh)

            ResultMsg = "SALVO " + Chr(34) + GetFilePart(SaveFilePath) + Chr(34) + " - SLOT " + Str(SvSlot) +
                       " - " + Mamute_Hex4(SvStart) + "-" + Mamute_Hex4(SvEnd) + " - TAMANHO " + Mamute_Hex4(SvLen)
            Quit = #True

          Case G_Cancel
            Quit = #True
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
  ProcedureReturn ResultMsg
EndProcedure
