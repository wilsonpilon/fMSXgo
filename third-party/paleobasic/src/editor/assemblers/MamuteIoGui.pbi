;
; ------------------------------------------------------------
;  Painel de Portas I/O do Mamute Assembler (comando XPP abre a janela;
;  XPI/XPO leem/escrevem manualmente) - pedido explicito do usuario:
;  "Vamos simular um painel de simulacao de I/O agora... um painel onde
;  colocamos algumas portas que desejamos monitorar, e conforme o programa
;  mandar um dado para a porta, ele escreve em (entrada), se uma rotina de
;  simulacao no futuro escrever algo devolvendo para o Z80, escreve em
;  (saida), mas por hora, o usuario pode colocar um byte na saida e ou na
;  entrada e simular os comandos que mandam dados para as portas de I/O...
;  com botoes o usuario pode incluir ou excluir portas, as portas que
;  sofrem alteracao podem mudar de cor... implemente mais 2 comandos XPI
;  <port>... e XPO <porta><byte>... Se a porta ainda nao aparece no painel
;  de portas, crie a mesma." (docs/SPEC.md modulo 46).
;
;  MODELO: "Entrada" = o ultimo byte que o PROGRAMA simulado mandou pra
;  essa porta via OUT (o que "entra" no dispositivo simulado, do ponto de
;  vista do dispositivo) - MamuteZ80Cpu.pbi ($D3/ED OUT (C),r/OUTI/OUTD)
;  chama Mamute_IOPort_SetEntrada() abaixo pra cada OUT de verdade
;  executado, e XPO faz exatamente a mesma chamada manualmente.  "Saida" =
;  o byte que uma instrucao IN vai LER dessa porta (o que o dispositivo
;  simulado devolve pro Z80) - MamuteZ80Cpu.pbi ($DB/ED IN r,(C)/INI/IND)
;  chama Mamute_IOPort_GetSaida() abaixo, e XPI faz a mesma leitura
;  manualmente. Como ainda nao existe nenhuma "rotina de simulacao" de
;  verdade (Fase 1, mesmo estagio que o resto da CPU simulada - ver
;  comentarios "sem dispositivo real" que estas mudancas substituem), o
;  unico jeito de "Saida" ter um valor diferente de $FF (padrao de barramento
;  flutuante, mesmo valor que o antigo stub de IN sempre devolvia) e' o
;  USUARIO digitar um valor no painel antes de rodar o programa (XGO/XTR) -
;  exatamente o "por hora, o usuario pode colocar um byte" do pedido.
;
;  Toda porta e' identificada por 1 byte (0-255, endereçamento de porta
;  classico do Z80/MSX via A7-A0 do barramento, "IN A,(n)"/"OUT (n),A") -
;  MamuteIOPort\Port.a ja cobre isso sozinho (tipo .a do PureBasic = byte
;  sem sinal 0-255), sem precisar de nenhuma validacao de faixa extra alem
;  de "2 digitos hexa" (Mamute_IsHexString(Token, 2), o mesmo teto).
;
;  Lista SEMPRE mantida em ORDEM CRESCENTE de porta (Mamute_IOPort_Ensure
;  insere na posicao certa) - facilita achar visualmente uma porta
;  especifica no painel conforme a lista cresce (o pedido menciona
;  "raramente os programas usam muitas portas", entao a lista tende a
;  ficar pequena e a ordem faz diferenca visual real).
;
;  "Mudam de cor" (\Changed) - MARCADO em qualquer escrita (Entrada OU
;  Saida, seja pela CPU de verdade, por XPO, ou por edicao manual no
;  proprio painel) - NUNCA por leitura (XPI/instrucao IN so' consultam,
;  nunca "alteram" nada). Fica marcado ate' o usuario limpar (botao
;  "Limpar Marcas" na janela) - nao ha' como o painel saber sozinho quando
;  o usuario "ja viu" a mudanca, entao a decisao e' o usuario reconhecer
;  explicitamente, mesma logica de "flags read-only ate' o usuario agir"
;  ja usada noutros lugares deste projeto (ex. HasLastMatch do XTP/XIR).
; ------------------------------------------------------------
;

Structure MamuteIOPort
  Port.a
  EntradaByte.a
  SaidaByte.a
  HasEntrada.b
  HasSaida.b
  Changed.b
EndStructure

Global NewList MamuteIOPorts.MamuteIOPort()

; Garante que Port exista em MamuteIOPorts() (cria uma entrada nova, com
; Entrada/Saida ainda indefinidos, inserida em ordem crescente de porta) -
; #True se CRIOU agora, #False se ja existia. Usado tanto pelas
; instrucoes OUT/IN de verdade da CPU simulada (MamuteZ80Cpu.pbi) quanto
; pelos comandos manuais XPI/XPO/pelo proprio painel - pedido explicito do
; usuario: "se a porta ainda nao aparece no painel de portas, crie a
; mesma".
Procedure.b Mamute_IOPort_Ensure(Port.a)
  ForEach MamuteIOPorts()
    If MamuteIOPorts()\Port = Port
      ProcedureReturn #False
    EndIf
    If MamuteIOPorts()\Port > Port
      Protected NewPort.MamuteIOPort
      NewPort\Port = Port
      InsertElement(MamuteIOPorts())
      MamuteIOPorts() = NewPort
      ProcedureReturn #True
    EndIf
  Next
  ; maior que todas as portas ja existentes (ou lista vazia) - vai no fim
  AddElement(MamuteIOPorts())
  MamuteIOPorts()\Port = Port
  ProcedureReturn #True
EndProcedure

; Chamado por toda OUT de verdade (MamuteZ80Cpu.pbi: $D3, ED OUT (C),r,
; OUTI/OUTD) e pelo comando XPO - grava "Entrada", cria a porta se
; necessario, e marca \Changed.
Procedure Mamute_IOPort_SetEntrada(Port.a, Value.a)
  Mamute_IOPort_Ensure(Port)
  ForEach MamuteIOPorts()
    If MamuteIOPorts()\Port = Port
      MamuteIOPorts()\EntradaByte = Value
      MamuteIOPorts()\HasEntrada = #True
      MamuteIOPorts()\Changed = #True
      Break
    EndIf
  Next
EndProcedure

; Chamado pela edicao manual de "Saida" no painel (e, no futuro, por uma
; rotina de simulacao de verdade) - grava "Saida", cria a porta se
; necessario, e marca \Changed.
Procedure Mamute_IOPort_SetSaida(Port.a, Value.a)
  Mamute_IOPort_Ensure(Port)
  ForEach MamuteIOPorts()
    If MamuteIOPorts()\Port = Port
      MamuteIOPorts()\SaidaByte = Value
      MamuteIOPorts()\HasSaida = #True
      MamuteIOPorts()\Changed = #True
      Break
    EndIf
  Next
EndProcedure

; Chamado por toda IN de verdade (MamuteZ80Cpu.pbi: $DB, ED IN r,(C),
; INI/IND) e pelo comando XPI - le "Saida", criando a porta se necessario
; (mesma regra das escritas), mas SEM marcar \Changed (ler nao e'
; modificar). $FF (barramento flutuante) se a porta nunca teve "Saida"
; definida - mesmo valor que o antigo stub "sem dispositivo real" sempre
; devolvia, entao programas que so' fazem IN sem que o usuario tenha
; configurado nada continuam vendo exatamente o comportamento de antes.
Procedure.a Mamute_IOPort_GetSaida(Port.a)
  Mamute_IOPort_Ensure(Port)
  ForEach MamuteIOPorts()
    If MamuteIOPorts()\Port = Port
      If MamuteIOPorts()\HasSaida
        ProcedureReturn MamuteIOPorts()\SaidaByte
      Else
        ProcedureReturn $FF
      EndIf
    EndIf
  Next
  ProcedureReturn $FF ; nunca deveria cair aqui (Ensure acima ja' garantiu) - so seguranca
EndProcedure

;- ------------------------------------------------------------
;- Janela "XPP" - Painel de Portas I/O
;- ------------------------------------------------------------

#MamuteIo_Shortcut_Escape = 9850

; Redesenha a lista inteira a partir de MamuteIOPorts() - ClearGadgetItems
; + AddGadgetItem por porta, com SetGadgetItemColor destacando (fundo
; amarelo claro, independente do tema - a lista em si fica com as cores
; NATIVAS do Windows de proposito, mesmo idioma do G_List de
; "Configurar -> Mamute Assembler..." em MamuteSupport.pbi, que tambem
; nunca aplicou o tema verde-terminal a um ListIconGadget) as portas com
; \Changed = #True.
Procedure MamuteIoPanel_RefreshList(G_List)
  ClearGadgetItems(G_List)
  Protected Idx.i = 0
  ForEach MamuteIOPorts()
    Protected EntradaTxt.s = "--"
    If MamuteIOPorts()\HasEntrada : EntradaTxt = Mamute_Hex2(MamuteIOPorts()\EntradaByte) : EndIf
    Protected SaidaTxt.s = "--"
    If MamuteIOPorts()\HasSaida : SaidaTxt = Mamute_Hex2(MamuteIOPorts()\SaidaByte) : EndIf
    AddGadgetItem(G_List, -1, Mamute_Hex2(MamuteIOPorts()\Port) + Chr(10) + EntradaTxt + Chr(10) + SaidaTxt)
    If MamuteIOPorts()\Changed
      SetGadgetItemColor(G_List, Idx, #PB_Gadget_BackColor, RGB(255, 255, 150))
    EndIf
    Idx + 1
  Next
EndProcedure

Procedure MamuteIoPanel_Open(ParentWindow)
  Protected MStyle.i = 0
  If MamuteFontBold : MStyle = #PB_Font_Bold : EndIf
  Protected MFont = LoadFont(#PB_Any, MamuteFontName, MamuteFontSize, MStyle)
  If Not MFont
    MFont = LoadFont(#PB_Any, "Consolas", 14, #PB_Font_Bold)
  EndIf
  Protected BtnFont = LoadFont(#PB_Any, "Consolas", 14, #PB_Font_Bold)
  If Not BtnFont : BtnFont = MFont : EndIf

  Protected ColFront = Mamute_CurrentFrontColor(), ColBack = Mamute_CurrentBackColor(), ColBorder = Mamute_CurrentBorderColor()

  Protected Margin = 16, RowH = 26, BtnH = 28, BtnGap = 8
  Protected WinW = 640
  Protected ListH = 260
  Protected LegendH = 20, StatusH = 20
  ; Soma exata das linhas montadas abaixo (Legenda / Lista / Porta+Botoes /
  ; Entrada+Saida+Botoes / Limpar Marcas / Status), MESMA tecnica de calcular
  ; WinH ANTES de abrir a janela ja usada pelo XTP/XIR (MamuteXtpGui.pbi/
  ; MamuteXirGui.pbi) - mais seguro que redimensionar depois de criar os
  ; gadgets.
  Protected WinH = Margin + LegendH + 8 + ListH + 12 + RowH + 12 + RowH + 12 + BtnH + 12 + StatusH + Margin

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Mamute Assembler - XPP - Painel de Portas I/O",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #True, #False)
  If Not Win
    ProcedureReturn
  EndIf
  SetWindowColor(Win, ColBorder)

  Protected CurY = Margin

  Protected LegendTxt.s = "Selecione uma porta na lista pra editar - ESC fecha"
  Protected G_Legend = TextGadget(#PB_Any, Margin, CurY, WinW - Margin * 2, LegendH, LegendTxt)
  SetGadgetColor(G_Legend, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Legend, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Legend, FontID(MFont))
  CurY + LegendH + 8

  Protected G_List = ListIconGadget(#PB_Any, Margin, CurY, WinW - Margin * 2, ListH, "Porta", 80, #PB_ListIcon_FullRowSelect)
  AddGadgetColumn(G_List, 1, "Entrada", (WinW - Margin * 2 - 80) / 2)
  AddGadgetColumn(G_List, 2, "Saida", (WinW - Margin * 2 - 80) / 2)
  CurY + ListH + 12

  ; Linha "Porta:" + Adicionar/Remover - <porta> digitada aqui e' o alvo
  ; de TODOS os botoes desta janela (Adicionar/Remover/Definir Entrada/
  ; Definir Saida) - selecionar uma linha na lista so' PREENCHE estes
  ; campos pra conveniencia, nunca guarda uma "selecao" separada - evita
  ; qualquer ambiguidade entre "o que esta selecionado" e "o que os
  ; botoes afetam" (sao sempre a mesma coisa: o que esta' digitado aqui).
  Protected CurX = Margin
  Protected G_PortaLabel = TextGadget(#PB_Any, CurX, CurY + 4, 60, RowH, "Porta:") : CurX + 60 + BtnGap
  SetGadgetColor(G_PortaLabel, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_PortaLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_PortaLabel, FontID(MFont))

  Protected G_PortaField = StringGadget(#PB_Any, CurX, CurY, 50, RowH, "") : CurX + 50 + BtnGap
  SetGadgetColor(G_PortaField, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_PortaField, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_PortaField, FontID(MFont))

  Protected G_AddBtn = CanvasGadget(#PB_Any, CurX, CurY, 110, BtnH) : CurX + 110 + BtnGap
  MamuteXd_DrawButton(G_AddBtn, "ADICIONAR", BtnFont)
  GadgetToolTip(G_AddBtn, "Cria a porta no painel se ainda nao existir")

  Protected G_RemoveBtn = CanvasGadget(#PB_Any, CurX, CurY, 110, BtnH)
  MamuteXd_DrawButton(G_RemoveBtn, "REMOVER", BtnFont)
  GadgetToolTip(G_RemoveBtn, "Remove a porta digitada acima do painel")
  CurY + RowH + 12

  ; Linha "Entrada:"/"Saida:" - edicao manual dos dois valores (pedido
  ; explicito do usuario: "o usuario pode colocar um byte na saida e ou na
  ; entrada").
  CurX = Margin
  Protected G_EntradaLabel = TextGadget(#PB_Any, CurX, CurY + 4, 60, RowH, "Entrada:") : CurX + 60 + BtnGap
  SetGadgetColor(G_EntradaLabel, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_EntradaLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_EntradaLabel, FontID(MFont))

  Protected G_EntradaField = StringGadget(#PB_Any, CurX, CurY, 50, RowH, "") : CurX + 50 + BtnGap
  SetGadgetColor(G_EntradaField, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_EntradaField, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_EntradaField, FontID(MFont))

  Protected G_SetEntradaBtn = CanvasGadget(#PB_Any, CurX, CurY, 100, BtnH) : CurX + 100 + BtnGap * 3
  MamuteXd_DrawButton(G_SetEntradaBtn, "DEFINIR", BtnFont)
  GadgetToolTip(G_SetEntradaBtn, "Grava o byte digitado como Entrada da porta")

  Protected G_SaidaLabel = TextGadget(#PB_Any, CurX, CurY + 4, 50, RowH, "Saida:") : CurX + 50 + BtnGap
  SetGadgetColor(G_SaidaLabel, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_SaidaLabel, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_SaidaLabel, FontID(MFont))

  Protected G_SaidaField = StringGadget(#PB_Any, CurX, CurY, 50, RowH, "") : CurX + 50 + BtnGap
  SetGadgetColor(G_SaidaField, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_SaidaField, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_SaidaField, FontID(MFont))

  Protected G_SetSaidaBtn = CanvasGadget(#PB_Any, CurX, CurY, 100, BtnH)
  MamuteXd_DrawButton(G_SetSaidaBtn, "DEFINIR", BtnFont)
  GadgetToolTip(G_SetSaidaBtn, "Grava o byte digitado como Saida da porta")
  CurY + RowH + 12

  Protected G_ClearBtn = CanvasGadget(#PB_Any, Margin, CurY, 160, BtnH)
  MamuteXd_DrawButton(G_ClearBtn, "LIMPAR MARCAS", BtnFont)
  GadgetToolTip(G_ClearBtn, "Tira o destaque de todas as portas alteradas")
  CurY + BtnH + 12

  Protected G_Status = TextGadget(#PB_Any, Margin, CurY, WinW - Margin * 2, StatusH, "")
  SetGadgetColor(G_Status, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Status, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Status, FontID(MFont))

  MamuteIoPanel_RefreshList(G_List)

  AddKeyboardShortcut(Win, #PB_Shortcut_Escape, #MamuteIo_Shortcut_Escape)

  Macro MamuteIo_ReadPortaField(OutVar)
    If Not Mamute_IsHexString(Trim(GetGadgetText(G_PortaField)), 2)
      SetGadgetText(G_Status, "?ERRO DE SINTAXE (PORTA)")
      Continue
    EndIf
    OutVar = Val("$" + Trim(GetGadgetText(G_PortaField)))
  EndMacro

  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_List
            If EventType() = #PB_EventType_Change
              Protected Sel = GetGadgetState(G_List)
              If Sel >= 0 And SelectElement(MamuteIOPorts(), Sel)
                SetGadgetText(G_PortaField, Mamute_Hex2(MamuteIOPorts()\Port))
                If MamuteIOPorts()\HasEntrada
                  SetGadgetText(G_EntradaField, Mamute_Hex2(MamuteIOPorts()\EntradaByte))
                Else
                  SetGadgetText(G_EntradaField, "")
                EndIf
                If MamuteIOPorts()\HasSaida
                  SetGadgetText(G_SaidaField, Mamute_Hex2(MamuteIOPorts()\SaidaByte))
                Else
                  SetGadgetText(G_SaidaField, "")
                EndIf
              EndIf
            EndIf

          Case G_AddBtn
            If EventType() = #PB_EventType_LeftButtonDown
              Protected AddPort.i
              MamuteIo_ReadPortaField(AddPort)
              Mamute_IOPort_Ensure(AddPort)
              MamuteIoPanel_RefreshList(G_List)
              SetGadgetText(G_Status, "PORTA " + Mamute_Hex2(AddPort) + " NO PAINEL")
            EndIf

          Case G_RemoveBtn
            If EventType() = #PB_EventType_LeftButtonDown
              Protected RemPort.i
              MamuteIo_ReadPortaField(RemPort)
              Protected RemFound.b = #False
              ForEach MamuteIOPorts()
                If MamuteIOPorts()\Port = RemPort
                  DeleteElement(MamuteIOPorts())
                  RemFound = #True
                  Break
                EndIf
              Next
              MamuteIoPanel_RefreshList(G_List)
              If RemFound
                SetGadgetText(G_Status, "PORTA " + Mamute_Hex2(RemPort) + " REMOVIDA")
              Else
                SetGadgetText(G_Status, "?PORTA NAO ENCONTRADA")
              EndIf

            EndIf

          Case G_SetEntradaBtn
            If EventType() = #PB_EventType_LeftButtonDown
              Protected SEPort.i
              MamuteIo_ReadPortaField(SEPort)
              If Not Mamute_IsHexString(Trim(GetGadgetText(G_EntradaField)), 2)
                SetGadgetText(G_Status, "?ERRO DE SINTAXE (ENTRADA)")
                Continue
              EndIf
              Mamute_IOPort_SetEntrada(SEPort, Val("$" + Trim(GetGadgetText(G_EntradaField))))
              MamuteIoPanel_RefreshList(G_List)
              SetGadgetText(G_Status, "ENTRADA DA PORTA " + Mamute_Hex2(SEPort) + " DEFINIDA")
            EndIf

          Case G_SetSaidaBtn
            If EventType() = #PB_EventType_LeftButtonDown
              Protected SSPort.i
              MamuteIo_ReadPortaField(SSPort)
              If Not Mamute_IsHexString(Trim(GetGadgetText(G_SaidaField)), 2)
                SetGadgetText(G_Status, "?ERRO DE SINTAXE (SAIDA)")
                Continue
              EndIf
              Mamute_IOPort_SetSaida(SSPort, Val("$" + Trim(GetGadgetText(G_SaidaField))))
              MamuteIoPanel_RefreshList(G_List)
              SetGadgetText(G_Status, "SAIDA DA PORTA " + Mamute_Hex2(SSPort) + " DEFINIDA")
            EndIf

          Case G_ClearBtn
            If EventType() = #PB_EventType_LeftButtonDown
              ForEach MamuteIOPorts()
                MamuteIOPorts()\Changed = #False
              Next
              MamuteIoPanel_RefreshList(G_List)
              SetGadgetText(G_Status, "MARCAS LIMPAS")
            EndIf
        EndSelect

      Case #PB_Event_Menu
        Select EventMenu()
          Case #MamuteIo_Shortcut_Escape
            Quit = #True
        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
