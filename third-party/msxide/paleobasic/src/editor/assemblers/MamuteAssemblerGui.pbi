;
; ------------------------------------------------------------
;  Apelido interno: Mamute (tema pre-historico do projeto, ver README.md -
;  este ja era o nome oficial do modulo antes da troca de nomes do projeto)
;  Executar -> Mamute Assembler...: janela "monitor" inspirada nos antigos
;  montadores de linha de comando dos computadores de 8 bits dos anos 80 -
;  pedido explicito do usuario, referencia direta o MegaAssembler dele (tem
;  o manual original, mas so quer portar um subconjunto pequeno de comandos,
;  aos poucos). Nada de telas com campo/botao pra cada opcao: um prompt
;  "MON>" aceita comandos digitados, um de cada vez - ver Ajuda -> Mamute
;  Assembler... (MamuteHelpData.pbi/MamuteHelpGui.pbi, cresce junto com
;  MamuteGui_Dispatch() abaixo, um comando novo por sessao).
;
;  Primeira leva: BA/QUIT (fecha a janela). Segunda leva: PAGE (mostra/troca
;  qual SLOT fisico esta comutado em cada uma das 4 paginas visiveis pelo
;  Z80 agora mesmo - MamutePageMap(), MamuteSupport.pbi, XIncludeFile'd
;  antes deste arquivo, tambem tem o modelo de memoria 4x4x16KB e a tela
;  "Configurar -> Mamute Assembler..."). Terceira leva: DM (Despejo de
;  Memoria) - abre MamuteDumpGui.pbi (tambem XIncludeFile'd antes deste
;  arquivo), primeiro comando que realmente le/escreve a memoria simulada.
;  Quarta leva: ZAP - "muito parecido com o DM", so que edita SETORES de uma
;  imagem de disco (.dsk) em vez da memoria do MSX - abre MamuteZapGui.pbi.
;  Quinta leva: SCR - display grafico da memoria numa tela fixa 256x192,
;  modo horizontal/vertical - abre MamuteScrGui.pbi (tambem XIncludeFile'd
;  antes deste arquivo). Sexta leva: SH - busca de bytes/texto na memoria
;  (curinga entre virgulas vazias no modo bytes, deslocamento automatico no
;  modo texto) - so mostra o resultado no log, nao abre janela. Setima
;  leva: MS - grava uma string na memoria com deslocamento opcional, mesma
;  formula do bloco de texto do DM - tambem sem janela, so confirma no log.
;  Oitava leva: LOAD - carrega um arquivo escolhido numa janela (sem digitar
;  nome/CAS:/A:, diferente do manual original) pra dentro de um slot
;  escolhido pelo usuario - .ROM vai pros enderecos certos por tamanho
;  (4000 e/ou 8000), .BIN com cabecalho BLOAD vai pro endereco do
;  cabecalho, sem cabecalho pergunta o endereco (LOAD <nome> so sugere
;  nome/filtro na janela, nunca carrega direto). Nona leva: SAVE - o
;  inverso do LOAD, tambem com janela propria (MamuteSaveGui.pbi) - grava
;  um bloco de MamuteMem(Slot,...) num arquivo, com cabecalho BIN (FE+3
;  enderecos) ou ROM (AB+3 enderecos) opcional, ou sem cabecalho nenhum.
;  Decima/decima-primeira leva: M e S - mesmo esquema grafico do DM
;  (MamuteMGui.pbi), mas hexa digitado tecla-a-tecla direto (sem campo de
;  edicao); M usa 0-9/A-F fixos, S usa 16 teclas configuraveis em
;  "Configurar -> Mamute Assembler..." (MamuteSKeyMap(), MamuteSupport.pbi).
;  Decima-segunda leva: C - so guarda o modo de exibicao (0-3) que os
;  comandos D/P/V vao usar - sem janela, so confirma no log. Decima-terceira
;  leva: D/P/V - despejo formatado de memoria (mesmo Mamute_BuildDumpLines()
;  pros tres, formato conforme State\DisplayMode); D manda direto pro log
;  (video), P e V geram um PDF A4 simples (Mamute_SavePdfListing(),
;  MamutePdf.pbi, XIncludeFile'd antes deste arquivo - "impressora" de
;  verdade, driver Epson FX-80, fica pra uma sessao futura) e abrem "Salvar
;  como" no final; D/P leem a RAM/ROM (Mamute_ReadByte, resolve PAGE ativo),
;  V le a VRAM simulada nova (MamuteVRAM(), MamuteSupport.pbi - endereco
;  plano ate MamuteVramSize-1, sem banco/PAGE, porque VRAM de verdade nunca
;  foi mapeada no espaco de enderecos do Z80). Tamanho de VRAM (16/128/192KB)
;  configuravel em "Configurar -> Mamute Assembler...". Decima-quarta leva:
;  T/F - T <inic>,<fim>,<dest> transfere um bloco de RAM/ROM pra outro
;  endereco (copia de tras pra frente quando origem/destino se sobrepoe e o
;  destino vem depois da origem, mesmo algoritmo de um memmove seguro); F
;  <inic>,<fim>,<byte> preenche um bloco inteiro com o mesmo byte. Os dois
;  sem janela, so confirmam no log; sem wraparound (mesma regra do D/P/V) -
;  <dest> passar de FFFF e ?ERRO DE SINTAXE. Decima-quinta leva: G/X/R - G
;  <endinic>[,<brk1>[,<brk2>]] so VALIDA a sintaxe e confirma no log, sem
;  executar nada de verdade - execucao de programas fica pra uma fase futura
;  (pedido explicito do usuario). X [<reg>] mostra/edita os registradores Z80
;  simulados (MamuteGui_State\Reg*, novos campos) - sem argumento mostra os 7
;  pares (AF/BC/DE/HL/IX/IY/SP); com argumento (par OU byte isolado - A/F/B/
;  C/D/E/H/L - extensao sobre o manual original) caminha em sequencia
;  perguntando o novo valor de cada um via InputRequester(), valor atual
;  pre-preenchido (ENTER sem editar = mantem e continua, campo vazio/Cancelar
;  = para a caminhada). R [<offset>] so confirma no log que carregamento de
;  programa assemblado fica pra depois do assemblador embutido existir -
;  ignora os argumentos de proposito (pedido explicito do usuario). Decima-
;  setima leva: L/LP - disassembler Z80 de verdade (Mamute_DisasmOne()/
;  Mamute_DisasmBuildLines(), MamuteSupport.pbi - tabela de opcodes escrita
;  do zero via decomposicao x/y/z/p/q classica, ja que o assemblador Z80Asm.
;  pbi deste projeto codifica proceduralmente, sem tabela bytes->mnemonico
;  reaproveitavel). L manda a listagem pro log, LP gera PDF (mesma infra do
;  P/V); os dois aceitam [<endinic>[,<endfim>]] - sem <endfim>, 10
;  instrucoes; sem nada, continua do ultimo L/LP (*State\LastLAddr).
;  Ajuste de usabilidade (2026-08-12): usuario reportou "L 0,100 disassembla
;  poucas instrucoes" - investigado a fundo (harness de teste real contra o
;  ROM de verdade do usuario, repetido, batendo exatamente com o texto que
;  ele colou) e NAO era bug nenhum - a listagem inteira (115 linhas) estava
;  correta, so nao cabia na janela (720x480 antigo) sem rolar, e o usuario
;  nao tinha percebido a barra de rolagem. Aumentado WinW/WinH pra 960x640
;  (todos os gadgets ja eram parametrizados por WinW/WinH, so mudar aqui
;  redimensiona tudo) e o tamanho padrao da fonte de 14 pra 16
;  (MamuteFontSize, MamuteSupport.pbi - negrito ja era #True por padrao) -
;  fonte/tamanho/negrito continuam configuraveis em "Configurar -> Mamute
;  Assembler..." (ja existia antes desta sessao, so nao era do conhecimento
;  do usuario).
;  Decima-nona leva: EDIT - abre uma janela separada (MamuteEditGui.pbi,
;  XIncludeFile'd antes deste arquivo) pra digitar o programa-fonte Z80 no
;  formato de linhas numeradas do manual original ("NN Label: instrucao
;  operando ;comentario"). Passou por 2 reescritas na mesma sessao a partir
;  de feedback direto do usuario: 1a versao (clone do MON>, REPL) e 2a
;  versao (ListIconGadget) foram rejeitadas; a 3a e final reproduz o editor
;  de BASIC do ZX-81 de verdade (pedido explicito: "um editor exatamente
;  identico ao do ZX-81... exceto as teclas tokenizadas") - a listagem E' a
;  tela (CanvasGadget desenhado a mao), cursor ">" entre NN e o corpo da
;  linha, setas Cima/Baixo movem o cursor, ENTER com campo vazio puxa a
;  linha do cursor pra editar, tela cheia rola meia-tela sozinha, comando
;  LIST pagina tela-cheia-por-tela-cheia com pergunta S/N. Ver comentario
;  de topo de MamuteEditGui.pbi pro detalhe completo. Numeros sem sufixo
;  passam a ser hexadecimal por padrao (mudanca pedida em relacao ao manual
;  original, que usava decimal). So aceita/edita/lista o programa por hora
;  (Mamute_ParseAsmLine/Mamute_StoreAsmLine, MamuteSupport.pbi) - NEW/AUTO/
;  DELETE/RENUM e o assemblador de verdade (comando A) ficam pra sessoes
;  futuras.
;  Mais comandos entram aos poucos, sessao a sessao.
;
;  Historico de comandos (mesma sessao do SCR, pedido explicito do usuario):
;  Setas Cima/Baixo no campo MON> navegam pelo historico (MamuteGui_History(),
;  abaixo), persistido no arquivo de projeto atual via
;  ProjectDB::SetInfoValue/GetInfoValue (ProjectDB.pbi, XIncludeFile'd antes
;  deste arquivo) - ver MamuteGui_HistorySave()/Load().
;
;  Visual "terminal": fundo preto, texto monoespacado verde, ignorando o
;  tema da IDE de proposito (SetGadgetColor()/SetGadgetFont() explicitos,
;  nao SetWindowColor(..., Color_AppBg) do resto da IDE) - e pra lembrar um
;  terminal de verdade, nao mais um dialogo comum. Unico cuidado real:
;  App_StyleChildCallback (BadigEditor.pb) forca a fonte Segoe UI em TODO
;  controle nativo de QUALQUER janela no primeiro WM_PAINT dela (nao tem
;  como desligar isso por janela) - MamuteGui_ApplyRetroFont() e chamada de
;  novo logo antes do loop de eventos pra garantir que a fonte monoespacada
;  vence essa corrida.
; ------------------------------------------------------------
;

#MamuteGui_EnterShortcut = 9101
#MamuteGui_UpShortcut    = 9102
#MamuteGui_DownShortcut  = 9103
; Comando XTR (docs/SPEC.md modulo 45, TRACE) - ESC interrompe o loop modal
; de trace (MamuteGui_CmdXtr, mais abaixo). Registrado uma unica vez em
; MamuteAssembler_OpenWindow, junto com os 3 de cima - fora do trace, o
; #PB_Event_Menu correspondente simplesmente nao tem Case nenhum no loop
; principal e e' ignorado (nao precisa de comportamento fora do XTR).
#MamuteGui_EscShortcut   = 9104

; MamuteGui_Font agora e' declarado em MamuteSupport.pbi (hoisted pra la -
; MamuteEditGui.pbi, incluido antes deste arquivo, tambem precisa dele).

; Historico de comandos digitados no MON> - navegavel com Setas Cima/Baixo
; (pedido explicito do usuario), persistido entre sessoes (ver
; MamuteGui_HistoryLoad()/Save() mais abaixo). Global (nao dentro de
; MamuteGui_State) porque sobrevive a varias aberturas/fechamentos da
; janela dentro da mesma sessao do editor, nao so enquanto a janela esta
; aberta.
Global NewList MamuteGui_History.s()
#MamuteGui_HistoryMax = 200 ; limite defensivo - nao deixa crescer sem fim

; Recarrega a fonte a partir de MamuteFontName/Size/Bold (MamuteSupport.pbi,
; "Configurar -> Mamute Assembler...") toda vez que a janela abre - nao
; reaproveita entre aberturas (ao contrario da versao anterior) porque o
; usuario pode ter trocado a configuracao desde a ultima vez; libera a fonte
; anterior antes pra nao vazar um HFONT a cada abertura.
Procedure MamuteGui_EnsureFont()
  If MamuteGui_Font <> -1
    FreeFont(MamuteGui_Font)
  EndIf
  Protected Style.i = 0
  If MamuteFontBold : Style = #PB_Font_Bold : EndIf
  MamuteGui_Font = LoadFont(#PB_Any, MamuteFontName, MamuteFontSize, Style)
EndProcedure

; Acrescenta Text ao log (Accum recebido/devolvido explicitamente, mesmo
; motivo de OMSXGui_AppendLog() em OpenMSXConsoleGui.pbi - nao confiar no
; EditorGadget "lembrar" o proprio conteudo) e rola pro fim.
Procedure.s MamuteGui_AppendLog(G_Log, Accum.s, Text.s)
  If Accum <> ""
    Accum + Chr(13) + Chr(10)
  EndIf
  Accum + Text
  SetGadgetText(G_Log, Accum)
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    SendMessage_(GadgetID(G_Log), #EM_LINESCROLL, 0, 999999)
  CompilerEndIf
  ProcedureReturn Accum
EndProcedure

Structure MamuteGui_State
  LogAccum.s
  ShouldQuit.b
  HasLastSh.b   ; #True depois do 1o SH bem-sucedido nesta sessao da janela
  LastShAddr.i  ; endereco onde o ultimo SH achou algo - SH sem <end> continua daqui+1
  HasLastM.b    ; #True depois que a janela do M ja abriu ao menos uma vez
  LastMAddr.i   ; onde a janela do M ficou da ultima vez - M sem <endereco> reabre ali
  HasLastS.b    ; mesma ideia do M, mas rastreado separado (S tem "memoria" propria)
  LastSAddr.i
  DisplayMode.b ; comando C - modo de exibicao (0-3) que D/P/V vao usar; zero-inicializado = modo 0
  ChecksumAddrMode.b ; comando XCS - #False (zero-inicializado) = checksum NORMAL (so os bytes) do
                     ; despejo do XD; #True = "+ADDR" (soma tambem o byte baixo do endereco da linha)
  ; Registradores Z80 simulados (comando X, e agora tambem o motor de execucao real do
  ; comando G - MamuteZ80Cpu.pbi/MamuteDebuggerGui.pbi) - zero-inicializados (boot "limpo"),
  ; duram so a sessao da janela (mesmo espirito volatil do PAGE/DisplayMode).
  RegA.a : RegF.a : RegB.a : RegC.a : RegD.a : RegE.a : RegH.a : RegL.a
  RegIX.u : RegIY.u : RegSP.u
  HasLastL.b   ; #True depois do 1o L/LP bem-sucedido nesta sessao da janela
  LastLAddr.i  ; endereco logo apos a ultima instrucao mostrada - L/LP sem <endinic> continua dali
  ; Campos adicionados pro debugger visual (modulo 32 do SPEC, Fase 1) - PC nao existia antes
  ; (comando X nunca precisou dele), par alternado/I/R/IFF1/IFF2/IM idem. Ate 2 breakpoints,
  ; mesmo limite que a sintaxe do G ja aceitava desde o stub original.
  RegPC.u
  RegA2.a : RegF2.a : RegB2.a : RegC2.a : RegD2.a : RegE2.a : RegH2.a : RegL2.a
  RegI.a : RegR.a
  IFF1.b : IFF2.b : IM.a
  Halted.b
  HasBreak1.b : Break1Addr.u
  HasBreak2.b : Break2Addr.u
  ; Comando XGO (SUPER-X, docs/SPEC.md modulo 45j) - 5 breakpoints nomeados
  ; DEDICADOS (independentes de HasBreak1/Break2 acima, que continuam so' do
  ; comando G/debugger grafico, sem mudanca nenhuma) + XgoStep, a posicao
  ; atual na sequencia BP->BP1->BP2->BP3->(BPF dai em diante) que cada XGO
  ; sem argumento avanca - ver MamuteGui_XgoResolveTarget/MamuteGui_CmdXgo.
  ; HasLastXgo segue o mesmo idioma "sem argumento continua" do L/M/S/XD.
  HasXgoBp.b  : XgoBpAddr.u
  HasXgoBp1.b : XgoBp1Addr.u
  HasXgoBp2.b : XgoBp2Addr.u
  HasXgoBp3.b : XgoBp3Addr.u
  HasXgoBpF.b : XgoBpFAddr.u
  XgoStep.b
  HasLastXgo.b
  ; Comandos XD/XM (SUPER-X, docs/SPEC.md modulo 45/45b) - mesma "memoria de
  ; ultimo endereco" que M/S/L ja usam pra reabrir sem argumento; Target
  ; junto (docs/SPEC.md modulo 45b) - reabrir sem argumento tambem volta pro
  ; MESMO slot/sub-slot/VRAM de antes, nao so o endereco.
  HasLastXd.b : LastXdAddr.i : LastXdTarget.MamuteSxTarget
  HasLastXa.b : LastXaAddr.i : LastXaTarget.MamuteSxTarget
  HasLastXi.b : LastXiAddr.i : LastXiTarget.MamuteSxTarget
  HasLastXm.b : LastXmAddr.i : LastXmTarget.MamuteSxTarget
  HasLastXh.b : LastXhAddr.i : LastXhTarget.MamuteSxTarget
  ; Barra fixa de status (topo da janela, fora do log que rola) - pedido
  ; explicito do usuario: ultimo comando digitado + endereco/offset + slot
  ; de trabalho atual + miniatura 16x16 da memoria a partir dali. Ver
  ; MamuteGui_RefreshStatusBar() mais abaixo. LastCmdAddr/HasLastCmdAddr so'
  ; mudam quando o comando novo tem um endereco reconhecivel (primeiro
  ; token hexa dos argumentos) - sem isso, mantem o ultimo endereco valido
  ; conhecido, mesmo espirito "continua dali" do M/S/L/SH.
  LastCmdText.s
  HasLastCmdAddr.b
  LastCmdAddr.i
  ; "Disco corrente" (comandos de disco do SUPER-X, docs/SPEC.md modulo 45,
  ; a partir do XFS) - pedido explicito do usuario: um unico caminho de
  ; imagem .dsk compartilhado por QUALQUER comando de disco futuro, nao um
  ; campo por comando (idioma diferente do HasLastXd/etc. acima, que sao
  ; por-comando de proposito). So' o CAMINHO fica guardado aqui - o
  ; MSXDisk::OpenDisk()/CloseDisk() (unico DeclareModule real do projeto,
  ; MSXDisk.pbi) e' aberto e fechado a CADA comando que precisa ler o
  ; disco, nunca fica aberto entre comandos MON> (mesmo idioma do CLI
  ; --diskmanipulator/Gerenciador de Disco - evita segurar o arquivo
  ; travado). Mostrado na barra fixa de status (MamuteGui_RefreshStatusBar).
  HasCurrentDisk.b
  CurrentDiskPath.s
EndStructure

; Persistencia do historico - pedido explicito do usuario ("guarde inclusive
; entre secoes no arquivo de projeto"). Reaproveita ProjectDB::SetInfoValue/
; GetInfoValue (tabela generica "project_info", ProjectDB.pbi, XIncludeFile'd
; antes deste arquivo em BadigEditor.pb) - mesma chave/valor ja usada por
; "Configurar -> Projeto..." pros 3 booleans de override. Nao existe conceito
; separado de "projeto padrao" no codigo - ProjectDB::EnsureOpen() (chamado
; internamente por SetInfoValue/GetInfoValue) ja abre um projeto temporario
; implicito (noname.msxproject) sozinho na primeira vez que algo e gravado,
; se o usuario ainda nao tiver criado/aberto um projeto de verdade - "salve
; silenciosamente no projeto padrao" pedido pelo usuario ja e o comportamento
; padrao do ProjectDB, nada extra precisa ser feito aqui. Lista codificada
; como uma unica string separada por Chr(10), mesmo idioma de
; StoreAsmSubProject()/FetchAsmSubProject() (ProjectDB.pbi).
Procedure MamuteGui_HistorySave()
  Protected Joined.s = ""
  ForEach MamuteGui_History()
    If Joined <> ""
      Joined + Chr(10)
    EndIf
    Joined + MamuteGui_History()
  Next
  ProjectDB::SetInfoValue("mamute_mon_history", Joined)
EndProcedure

Procedure MamuteGui_HistoryLoad()
  ClearList(MamuteGui_History())
  Protected Raw.s = ProjectDB::GetInfoValue("mamute_mon_history")
  If Raw = ""
    ProcedureReturn
  EndIf
  Protected i.i, n.i = CountString(Raw, Chr(10)) + 1
  For i = 1 To n
    AddElement(MamuteGui_History())
    MamuteGui_History() = StringField(Raw, i, Chr(10))
  Next
EndProcedure

; Acrescenta Cmd ao historico (MamuteGui_History(), topo do arquivo) -
; ignora repeticao consecutiva do mesmo comando (nao faz sentido acumular
; "BA" dez vezes seguidas so porque o usuario apertou fleche-cima-Enter
; varias vezes) e derruba a entrada mais antiga quando passa do limite.
Procedure MamuteGui_HistoryAdd(Cmd.s)
  If ListSize(MamuteGui_History()) > 0
    LastElement(MamuteGui_History())
    If MamuteGui_History() = Cmd
      ProcedureReturn
    EndIf
  EndIf
  LastElement(MamuteGui_History())
  AddElement(MamuteGui_History())
  MamuteGui_History() = Cmd
  If ListSize(MamuteGui_History()) > #MamuteGui_HistoryMax
    FirstElement(MamuteGui_History())
    DeleteElement(MamuteGui_History())
  EndIf
EndProcedure

; Mostra o mapeamento ATIVO agora (MamutePageMap(), MamuteSupport.pbi) - uma
; linha por pagina, endereco real + slot comutado ali + sub-slot. Usado
; tanto por "PAGE ?" quanto logo apos qualquer "PAGE"/"PAGE X,Y,Z,W"
; bem-sucedido (feedback imediato, mesmo espirito de monitores de verdade
; ecoarem o estado apos um SET), e tambem no banner de abertura da janela.
; Sub-slot sempre mostrado como 0: nao existe registrador de "sub-slot
; ATIVO" por pagina neste simulador (decisao documentada em
; MamuteSupport.pbi, secao do MamuteSxTarget/MamuteMemSub) - so' os
; comandos SUPER-X (XD/XA/XI/XM) conseguem mirar um sub-slot 1-3
; explicitamente, via sufixo "#slot-subslot" no proprio endereco.
Procedure.s MamuteGui_ShowPageMap(G_Log, Accum.s)
  Protected Pagina.i
  For Pagina = 0 To 3
    Accum = MamuteGui_AppendLog(G_Log, Accum, "PAGE" + Str(Pagina) + "(" + Mamute_PageRangeText(Pagina) +
                                              ") SLOT " + Str(MamutePageMap(Pagina)) + "-0")
  Next
  ProcedureReturn Accum
EndProcedure

; Tenta achar um endereco hexa nos argumentos de Cmd (primeiro token depois
; do verbo, ate a primeira ","/"#") - alimenta so a barra de status
; (MamuteGui_RefreshStatusBar() abaixo), best-effort: comandos sem
; argumento em forma de endereco (BA, PAGE ?, X sem par, etc.) simplesmente
; nao atualizam o endereco mostrado, mantendo o ultimo conhecido (mesmo
; espirito "continua dali" que M/S/L/SH ja usam pra si mesmos).
Procedure.b MamuteGui_ExtractCmdAddr(Cmd.s, *OutAddr.Integer)
  Protected Trimmed.s = Trim(Cmd)
  If Left(Trimmed, 1) = "@" Or Left(Trimmed, 1) = "?"
    Trimmed = Trim(Mid(Trimmed, 2))
  EndIf
  Protected SpacePos.i = FindString(Trimmed, " ")
  If SpacePos = 0
    ProcedureReturn #False
  EndIf
  Protected Args.s = Trim(Mid(Trimmed, SpacePos + 1))
  If Args = ""
    ProcedureReturn #False
  EndIf
  Protected Tok.s = Args
  Protected CommaPos.i = FindString(Tok, ",")
  If CommaPos > 0
    Tok = Left(Tok, CommaPos - 1)
  EndIf
  Protected HashPos.i = FindString(Tok, "#")
  If HashPos > 0
    Tok = Left(Tok, HashPos - 1)
  EndIf
  Tok = Trim(Tok)
  ProcedureReturn Mamute_ParseHexAddr(Tok, *OutAddr)
EndProcedure

; Cor de um pixel da miniatura de memoria (MamuteGui_DrawMemSnapshot()
; abaixo) - gradiente do preto ate o verde do terminal (ColFront, mesmo
; RGB(60,220,90) usado no resto da janela) proporcional ao valor do byte,
; pra ficar visualmente coerente com o resto da janela em vez de um
; grayscale generico.
Procedure Mamute_BytePixelColor(V.a)
  Protected Frac.f = V / 255.0
  ProcedureReturn RGB(Int(60 * Frac), Int(220 * Frac), Int(90 * Frac))
EndProcedure

; Desenha a grade 16x16 (256 bytes a partir de BaseAddr, um pixel por byte,
; lido via Mamute_ReadByte() - resolve PAGE ativo, mesma regra do D/P/V) no
; CanvasGadget G_Canvas - pedido explicito do usuario ("trecho 16x16 com
; pixels representando os bytes a partir do endereco"). Sem endereco ainda
; conhecido (HasAddr = #False), so limpa o canvas.
Procedure MamuteGui_DrawMemSnapshot(G_Canvas, HasAddr.b, BaseAddr.i, ColBack.i)
  Protected CanvasSize.i = GadgetWidth(G_Canvas)
  Protected CellSize.i = CanvasSize / 16
  If Not StartDrawing(CanvasOutput(G_Canvas))
    ProcedureReturn
  EndIf
  Box(0, 0, CanvasSize, CanvasSize, ColBack)
  If HasAddr
    Protected Row.i, Col.i, Addr.i, V.a
    For Row = 0 To 15
      For Col = 0 To 15
        Addr = (BaseAddr + Row * 16 + Col) & $FFFF
        V = Mamute_ReadByte(Addr)
        Box(Col * CellSize, Row * CellSize, CellSize, CellSize, Mamute_BytePixelColor(V))
      Next
    Next
  EndIf
  StopDrawing()
EndProcedure

; Atualiza a barra fixa de status inteira (texto + miniatura) a partir do
; *State atual - chamada na abertura da janela e depois de todo comando
; despachado (MamuteAssembler_OpenWindow() abaixo), nao so na abertura,
; porque o endereco/slot mudam a cada comando e a memoria pode ter sido
; escrita por M/S/T/F/etc.
Procedure MamuteGui_RefreshStatusBar(G_StatusText, G_MemView, *State.MamuteGui_State, ColBack.i)
  Protected StatusText.s
  If *State\HasCurrentDisk
    StatusText = "DISCO: " + GetFilePart(*State\CurrentDiskPath)
  Else
    StatusText = "DISCO: (nenhum)"
  EndIf
  StatusText + Chr(13) + Chr(10)
  If *State\LastCmdText = ""
    StatusText + "ULTIMO: (nenhum)"
  Else
    StatusText + "ULTIMO: " + *State\LastCmdText
  EndIf
  If *State\HasLastCmdAddr
    Protected Slot.i, Pagina.i, Offset.i
    Mamute_ResolveAddress(*State\LastCmdAddr, @Slot, @Pagina, @Offset)
    StatusText + Chr(13) + Chr(10) + "END $" + Mamute_Hex4(*State\LastCmdAddr) +
                 "  OFFSET $" + Mamute_Hex4(Offset) + "  SLOT " + Str(Slot)
  Else
    StatusText + Chr(13) + Chr(10) + "(sem endereco ainda)"
  EndIf
  SetGadgetText(G_StatusText, StatusText)
  MamuteGui_DrawMemSnapshot(G_MemView, *State\HasLastCmdAddr, *State\LastCmdAddr, ColBack)
EndProcedure

; Token.s precisa ser 1+ digitos representando um numero de slot valido
; (0-3) - usado pra validar cada um dos 4 argumentos de "PAGE X,Y,Z,W".
Procedure.b MamuteGui_IsValidSlotToken(Token.s)
  If Token = ""
    ProcedureReturn #False
  EndIf
  Protected i
  For i = 1 To Len(Token)
    If Mid(Token, i, 1) < "0" Or Mid(Token, i, 1) > "9"
      ProcedureReturn #False
    EndIf
  Next
  ProcedureReturn Bool(Val(Token) >= 0 And Val(Token) <= 3)
EndProcedure

; PAGE (Args=""): coloca todas as 4 paginas no slot marcado como RAM.
; PAGE ? (Args="?"): so mostra o mapeamento ativo, sem mexer em nada.
; PAGE X,Y,Z,W (Args="X,Y,Z,W"): troca o mapeamento ativo pros 4 slots
; informados (pagina 0=X, 1=Y, 2=Z, 3=W). Qualquer outra forma = erro.
Procedure MamuteGui_CmdPage(G_Log, *State.MamuteGui_State, Args.s)
  If Args = ""
    Protected RamSlot.i = Mamute_FindRamSlot()
    If RamSlot = -1
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?NENHUM SLOT DE RAM CONFIGURADO")
      ProcedureReturn
    EndIf
    Protected P.i
    For P = 0 To 3
      MamutePageMap(P) = RamSlot
    Next
    *State\LogAccum = MamuteGui_ShowPageMap(G_Log, *State\LogAccum)
    ProcedureReturn
  EndIf

  If Args = "?"
    *State\LogAccum = MamuteGui_ShowPageMap(G_Log, *State\LogAccum)
    ProcedureReturn
  EndIf

  If CountString(Args, ",") <> 3
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected Dim ParsedSlots.i(3)
  Protected Idx.i, Token.s
  For Idx = 0 To 3
    Token = Trim(StringField(Args, Idx + 1, ","))
    If Not MamuteGui_IsValidSlotToken(Token)
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
    ParsedSlots(Idx) = Val(Token)
  Next

  For Idx = 0 To 3
    MamutePageMap(Idx) = ParsedSlots(Idx)
  Next
  *State\LogAccum = MamuteGui_ShowPageMap(G_Log, *State\LogAccum)
EndProcedure

; DM <endereco>[,<deslocamento>] - abre a janela de despejo/edicao de
; memoria (MamuteDumpGui.pbi, XIncludeFile'd antes deste arquivo) no
; endereco (hexa - "os enderecos em hexa sao o padrao de entrada de todos
; os comandos", pedido explicito do usuario) informado, com o deslocamento
; ASCII opcional (tambem hexa, com sinal, -7Fh a 80h). Vazio = sintaxe
; invalida (endereco e obrigatorio); deslocamento ausente = 0.
Procedure MamuteGui_CmdDm(Win, G_Log, *State.MamuteGui_State, Args.s)
  If Args = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected AddrToken.s, OffsetToken.s
  Protected CommaPos.i = FindString(Args, ",")
  If CommaPos > 0
    AddrToken = Trim(Left(Args, CommaPos - 1))
    OffsetToken = Trim(Mid(Args, CommaPos + 1))
  Else
    AddrToken = Trim(Args)
    OffsetToken = ""
  EndIf

  Protected Addr.i
  If Not Mamute_ParseHexAddr(AddrToken, @Addr)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected DmOffset.i = 0
  If OffsetToken <> ""
    If Not Mamute_ParseHexOffset(OffsetToken, @DmOffset)
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
  EndIf

  MamuteDump_Open(Win, Addr, DmOffset)
EndProcedure

; ZAP <setor inicial>[,<deslocamento>] - "muito parecido com o DM", pedido
; explicito do usuario, so que edita SETORES de uma imagem de disco (.dsk)
; em vez da memoria simulada do MSX - pede o arquivo (MamuteZapGui.pbi,
; XIncludeFile'd antes deste arquivo) antes de abrir a grade. <setor
; inicial> tambem em hexa (mesma regra do DM); <deslocamento> identico ao
; do DM (opcional, hexa com sinal, -7Fh a 80h).
Procedure MamuteGui_CmdZap(Win, G_Log, *State.MamuteGui_State, Args.s)
  If Args = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected SectorToken.s, OffsetToken.s
  Protected CommaPos.i = FindString(Args, ",")
  If CommaPos > 0
    SectorToken = Trim(Left(Args, CommaPos - 1))
    OffsetToken = Trim(Mid(Args, CommaPos + 1))
  Else
    SectorToken = Trim(Args)
    OffsetToken = ""
  EndIf

  Protected Sector.i
  If Not Mamute_ParseHexAddr(SectorToken, @Sector)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected ZapOffset.i = 0
  If OffsetToken <> ""
    If Not Mamute_ParseHexOffset(OffsetToken, @ZapOffset)
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
  EndIf

  MamuteZap_Open(Win, Sector, ZapOffset)
EndProcedure

; SCR <endinic>,<dx>,<dy>[,<modo>] - abre a janela de display grafico
; (MamuteScrGui.pbi, XIncludeFile'd antes deste arquivo). Todos os numeros
; sao hexa ("os enderecos em hexa sao o padrao de entrada de todos os
; comandos") - <endinic> 1-4 digitos, <dx>/<dy> 1-2 digitos (>=1, uma grade
; vazia nao faz sentido), <modo> opcional 1 digito (0 ou 1, default 0).
; Qualquer coisa fora disso (numero de campos errado, dx/dy zero, modo fora
; de 0-1) mostra ?ERRO DE SINTAXE, mesmo padrao do PAGE/DM/ZAP.
Procedure MamuteGui_CmdScr(Win, G_Log, *State.MamuteGui_State, Args.s)
  Protected FieldCount.i = CountString(Args, ",") + 1
  If Args = "" Or (FieldCount <> 3 And FieldCount <> 4)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected AddrToken.s = Trim(StringField(Args, 1, ","))
  Protected DxToken.s = Trim(StringField(Args, 2, ","))
  Protected DyToken.s = Trim(StringField(Args, 3, ","))
  Protected ModoToken.s = ""
  If FieldCount = 4
    ModoToken = Trim(StringField(Args, 4, ","))
  EndIf

  Protected Addr.i
  If Not Mamute_ParseHexAddr(AddrToken, @Addr)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected Dx.i, Dy.i
  If Not Mamute_IsHexString(DxToken, 2) Or Not Mamute_IsHexString(DyToken, 2)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Dx = Val("$" + DxToken)
  Dy = Val("$" + DyToken)
  If Dx < 1 Or Dy < 1
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected Modo.i = 0
  If ModoToken <> ""
    If Not Mamute_IsHexString(ModoToken, 1)
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
    Modo = Val("$" + ModoToken)
    If Modo <> 0 And Modo <> 1
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
  EndIf

  MamuteScr_Open(Win, Addr, Dx, Dy, Modo)
EndProcedure

; SH [<end>],<bt>[,[<bt>]...] busca uma sequencia de bytes em hexa pela
; memoria simulada; SH [<end>],'<string> busca um TEXTO, testando todos os
; deslocamentos possiveis (-7F a 80, mesma faixa do DM/ZAP) - acha tanto
; texto puro (deslocamento 0) quanto texto "cifrado" por deslocamento fixo
; (truque comum de jogos antigos pra nao deixar dialogo legivel num editor
; de disco cru). <end> omitido continua a busca a partir do ultimo endereco
; ACHADO + 1 (State\LastShAddr) - so faz sentido depois de um SH bem
; sucedido nesta mesma sessao da janela (State\HasLastSh). Vazio entre
; virgulas no modo bytes = curinga ("aquele byte pode ser qualquer um").
; Nao abre janela nenhuma - so mostra o resultado no log do MON>, comando de
; resposta rapida como PAGE.
Procedure MamuteGui_CmdSh(G_Log, *State.MamuteGui_State, Args.s)
  Protected CommaPos.i = FindString(Args, ",")
  If Args = "" Or CommaPos = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected AddrToken.s = Trim(Left(Args, CommaPos - 1))
  Protected Rest.s = Mid(Args, CommaPos + 1)

  Protected StartAddr.i
  If AddrToken = ""
    If Not *State\HasLastSh
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
    StartAddr = (*State\LastShAddr + 1) & $FFFF
  Else
    If Not Mamute_ParseHexAddr(AddrToken, @StartAddr)
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
  EndIf

  Protected TrimmedRest.s = Trim(Rest)
  Protected Found.b = #False, FoundAddr.i, FoundOffset.i
  Protected Try.i, CandAddr.i, j.i, Ok.b

  If Left(TrimmedRest, 1) = "'"
    ; Modo texto - "no minimo, duas letras" (pedido do manual original).
    Protected Target.s = Mid(TrimmedRest, 2)
    If Right(Target, 1) = "'"
      Target = Left(Target, Len(Target) - 1)
    EndIf
    If Len(Target) < 2
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf

    Protected TargetLen.i = Len(Target)
    Protected FirstRaw.a, RawDiff.i, NormOff.i, Rb.a
    For Try = 0 To 65535
      CandAddr = (StartAddr + Try) & $FFFF
      FirstRaw = Mamute_ReadByte(CandAddr)
      RawDiff = Asc(Left(Target, 1)) - FirstRaw
      NormOff = ((RawDiff + 127) % 256 + 256) % 256 - 127
      Ok = #True
      For j = 0 To TargetLen - 1
        Rb = Mamute_ReadByte((CandAddr + j) & $FFFF)
        If ((Rb + NormOff) & $FF) <> Asc(Mid(Target, j + 1, 1))
          Ok = #False
          Break
        EndIf
      Next
      If Ok
        Found = #True : FoundAddr = CandAddr : FoundOffset = NormOff
        Break
      EndIf
    Next

    If Found
      Protected Sign.s = "+"
      Protected AbsOff.i = FoundOffset
      If AbsOff < 0
        Sign = "-"
        AbsOff = -AbsOff
      EndIf
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
        "ACHADO EM " + Mamute_Hex4(FoundAddr) + " DESLOC " + Sign + Mamute_Hex2(AbsOff))
    Else
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "NAO ENCONTRADO")
    EndIf

  Else
    ; Modo bytes - pelo menos 1 byte, os demais (e o proprio primeiro) podem
    ; ser vazios (curinga).
    Protected FieldCount.i = CountString(Rest, ",") + 1
    Protected Dim Pattern.i(FieldCount - 1) ; -1 = curinga
    Protected i.i, Token.s
    For i = 1 To FieldCount
      Token = Trim(StringField(Rest, i, ","))
      If Token = ""
        Pattern(i - 1) = -1
      Else
        If Not Mamute_IsHexString(Token, 2)
          *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
          ProcedureReturn
        EndIf
        Pattern(i - 1) = Val("$" + Token)
      EndIf
    Next

    For Try = 0 To 65535
      CandAddr = (StartAddr + Try) & $FFFF
      Ok = #True
      For j = 0 To FieldCount - 1
        If Pattern(j) <> -1
          If Mamute_ReadByte((CandAddr + j) & $FFFF) <> Pattern(j)
            Ok = #False
            Break
          EndIf
        EndIf
      Next
      If Ok
        Found = #True : FoundAddr = CandAddr
        Break
      EndIf
    Next

    If Found
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "ACHADO EM " + Mamute_Hex4(FoundAddr))
    Else
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "NAO ENCONTRADO")
    EndIf
  EndIf

  If Found
    *State\LastShAddr = FoundAddr
    *State\HasLastSh = #True
  EndIf
EndProcedure

; MS <end>,[<dslc>],'<string> grava uma STRING crua na memoria simulada a
; partir de <end> - <dslc> opcional (hexa com sinal, -7F a 80, mesma faixa
; do DM/ZAP; 0 se omitido) "cifra" cada caractere igual o bloco de texto do
; DM: RawByte = (CodigoDoChar - Deslocamento) & FF - o mesmo texto reaparece
; legivel se depois for lido (DM) ou procurado (SH) com o MESMO
; deslocamento. Sem janela - so confirma no log do MON>. Escrita silenciosa
; em celulas que nao sejam RAM (Mamute_WriteByte ja recusa, mesma regra do
; DM) - nao ha como distinguir isso no resultado, mesmo espirito do DM.
Procedure MamuteGui_CmdMs(G_Log, *State.MamuteGui_State, Args.s)
  Protected CommaPos1.i = FindString(Args, ",")
  If Args = "" Or CommaPos1 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected AddrToken.s = Trim(Left(Args, CommaPos1 - 1))
  Protected Addr.i
  If Not Mamute_ParseHexAddr(AddrToken, @Addr)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected Rest.s = Mid(Args, CommaPos1 + 1)
  Protected TrimmedRest.s = Trim(Rest)
  Protected DslcToken.s, StringPart.s

  If Left(TrimmedRest, 1) = "'"
    DslcToken = ""
    StringPart = Mid(TrimmedRest, 2)
  Else
    Protected CommaPos2.i = FindString(Rest, ",")
    If CommaPos2 = 0
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
    DslcToken = Trim(Left(Rest, CommaPos2 - 1))
    Protected AfterDslc.s = Trim(Mid(Rest, CommaPos2 + 1))
    If Left(AfterDslc, 1) <> "'"
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
    StringPart = Mid(AfterDslc, 2)
  EndIf

  If Right(StringPart, 1) = "'"
    StringPart = Left(StringPart, Len(StringPart) - 1)
  EndIf
  If StringPart = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected Dslc.i = 0
  If DslcToken <> ""
    If Not Mamute_ParseHexOffset(DslcToken, @Dslc)
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
  EndIf

  Protected i.i
  For i = 1 To Len(StringPart)
    Mamute_WriteByte((Addr + i - 1) & $FFFF, (Asc(Mid(StringPart, i, 1)) - Dslc) & $FF)
  Next

  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "GRAVADO EM " + Mamute_Hex4(Addr))
EndProcedure

; LOAD - carrega um arquivo (janela de escolha, sem digitar nome/CAS:/A: -
; pedido explicito do usuario, diferente do "LOAD <arquivo>,B" do manual
; original) pra dentro de um SLOT escolhido pelo usuario (sempre perguntado,
; sugerindo o slot com RAM configurada - Mamute_FindRamSlot()). Sem
; argumentos - tudo interativo, por isso nao recebe Win (OpenFileRequester/
; InputRequester sao sempre modais da aplicacao inteira no PureBasic, nao
; precisam de handle de janela pai). Grava DIRETO em MamuteMem(Slot,...) -
; nao passa por Mamute_WriteByte()/PAGE, porque aqui o usuario esta
; escolhendo o slot fisico explicitamente (simula inserir um cartucho/
; carregar dado naquele slot), independente do mapeamento ativo agora.
; Tambem ajusta MamuteCfgCell() das paginas tocadas (RAM ou ROM, conforme o
; tipo de arquivo) - SO em memoria, nunca chama MamuteCfg_Save() - efeito
; dura so esta sessao da janela do Mamute Assembler, igual "inserir um
; cartucho" nao reescreve a configuracao salva do usuario. `.CAS` avisado
; como nao suportado ainda (pedido explicito) em vez de tentar interpretar
; errado.
; Args.s (opcional) - pedido explicito do usuario, "vamos permitir nome no
; LOAD, mas ele nao carrega, apenas sugere o nome na caixa de dialogo" - so
; pre-preenche o campo de nome do OpenFileRequester e, se a extensao do
; nome sugerido nao for .bin/.rom, acrescenta ela ao filtro (ex.: "LOAD
; alfabeto.alf" mostra "*.alf;*.bin;*.rom" no filtro padrao) - nunca pula o
; dialogo nem carrega direto.
Procedure MamuteGui_CmdLoad(G_Log, *State.MamuteGui_State, Win, Args.s)
  Protected SuggestedName.s = Trim(Args)
  Protected FilterPattern.s = "*.bin;*.rom"
  If SuggestedName <> ""
    Protected SuggestedExt.s = LCase(GetExtensionPart(SuggestedName))
    If SuggestedExt <> "" And SuggestedExt <> "bin" And SuggestedExt <> "rom"
      FilterPattern = "*." + SuggestedExt + ";" + FilterPattern
    EndIf
  EndIf
  Protected Filter.s = "Arquivos (" + FilterPattern + ")|" + FilterPattern + "|Todos os arquivos (*.*)|*.*"
  Protected FilePath.s = OpenFileRequester("Carregar arquivo - LOAD", SuggestedName, Filter, 0)
  If FilePath = ""
    ProcedureReturn ; cancelado - aborta sem log, mesmo espirito do ZAP
  EndIf

  Protected Ext.s = LCase(GetExtensionPart(FilePath))
  If Ext = "cas"
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ARQUIVOS .CAS NAO SUPORTADOS AINDA")
    ProcedureReturn
  EndIf

  Protected FSize.i = FileSize(FilePath)
  If FSize <= 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ARQUIVO INVALIDO")
    ProcedureReturn
  EndIf

  Protected RamSlot.i = Mamute_FindRamSlot()
  Protected SuggestSlot.s = "0"
  If RamSlot >= 0
    SuggestSlot = Str(RamSlot)
  EndIf
  Protected SlotAnswer.s = Trim(InputRequester("Carregar arquivo - LOAD",
    "Slot (0-3) para carregar - RAM sugerida: Slot " + SuggestSlot, SuggestSlot, 0, WindowID(Win)))
  If SlotAnswer = ""
    ProcedureReturn ; cancelado
  EndIf
  If Len(SlotAnswer) <> 1 Or SlotAnswer < "0" Or SlotAnswer > "3"
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?SLOT INVALIDO")
    ProcedureReturn
  EndIf
  Protected ChosenSlot.i = Val(SlotAnswer)

  Protected Fh = ReadFile(#PB_Any, FilePath)
  If Not Fh
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ARQUIVO INVALIDO")
    ProcedureReturn
  EndIf
  Protected Dim Buf.a(FSize - 1)
  ReadData(Fh, @Buf(0), FSize)
  CloseFile(Fh)

  Protected LoadAddr.i, DataOffset.i, DataLen.i, i.i, Addr.i, Pagina.i, Offset.i
  Protected Dim TouchedPage.b(3)
  Protected CellType.b

  If Ext = "rom"
    ; Cartucho ROM - endereco sempre 4000 (Pagina 1); ate 32KB tambem ocupa
    ; 8000 (Pagina 2). Mais que isso precisaria de mapper/bank switching,
    ; que este simulador nao faz.
    If FSize > 32768
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ROM MAIOR QUE 32KB NAO SUPORTADA")
      ProcedureReturn
    EndIf
    LoadAddr = $4000
    DataOffset = 0
    DataLen = FSize
    CellType = #MamuteMem_ROM
  Else
    ; Binario - com header BLOAD (0xFE + inicio/fim/exec, 2 bytes cada,
    ; little-endian - formato real do BSAVE do MSX-BASIC) carrega no
    ; endereco do header; sem header, pergunta o endereco ao usuario.
    If FSize >= 7 And Buf(0) = $FE
      LoadAddr = Buf(1) | (Buf(2) << 8)
      DataOffset = 7
      DataLen = FSize - 7
    Else
      Protected AddrAnswer.s = Trim(InputRequester("Carregar arquivo - LOAD",
        "Arquivo sem cabecalho BLOAD - endereco inicial (hexa, 0000-FFFF):", "0000", 0, WindowID(Win)))
      If AddrAnswer = ""
        ProcedureReturn ; cancelado
      EndIf
      If Not Mamute_ParseHexAddr(AddrAnswer, @LoadAddr)
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
        ProcedureReturn
      EndIf
      DataOffset = 0
      DataLen = FSize
    EndIf
    CellType = #MamuteMem_RAM
  EndIf

  For i = 0 To DataLen - 1
    Addr = (LoadAddr + i) & $FFFF
    Pagina = (Addr >> 14) & 3
    Offset = Addr & 16383
    MamuteMem(ChosenSlot, Pagina, Offset) = Buf(DataOffset + i)
    TouchedPage(Pagina) = #True
  Next
  For Pagina = 0 To 3
    If TouchedPage(Pagina)
      MamuteCfgCell(ChosenSlot, Pagina)\Tipo = CellType
    EndIf
  Next

  Protected FinalAddr.i = (LoadAddr + DataLen - 1) & $FFFF
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "CARREGADO NO SLOT " + Str(ChosenSlot) + " EM " + Mamute_Hex4(LoadAddr) +
    " - TAMANHO " + Mamute_Hex4(DataLen) + " - FIM " + Mamute_Hex4(FinalAddr))
EndProcedure

; SAVE [<nome>][,<endinic>,<endfim>[,<endexec>]] - abre a janela do SAVE
; (MamuteSaveGui.pbi, XIncludeFile'd antes deste arquivo), que faz todo o
; trabalho de verdade (escolher arquivo, slot, formato, gravar) e devolve
; uma linha de resultado pro log do MON> (ou "" se cancelado). <nome> e os
; enderecos sao so SUGESTOES pra pre-preencher a janela - nunca salvam
; nada sozinhos, pedido explicito do usuario ("mas ao abrir o dialogo...
; permita que o usuario edite"). Campo de nome vazio (`,4000,7FFF`) e
; aceito, mesma convencao do SH/MS.
Procedure MamuteGui_CmdSave(Win, G_Log, *State.MamuteGui_State, Args.s)
  Protected SuggestedName.s = ""
  Protected HasAddrs.b = #False
  Protected InStart.i = 0, InEnd.i = 0, InExec.i = 0

  If Args <> ""
    Protected FieldCount.i = CountString(Args, ",") + 1
    SuggestedName = Trim(StringField(Args, 1, ","))
    Select FieldCount
      Case 1
        ; so o nome, sem enderecos - janela pede o resto
      Case 3, 4
        Protected StartToken.s = Trim(StringField(Args, 2, ","))
        Protected EndToken.s = Trim(StringField(Args, 3, ","))
        If Not Mamute_ParseHexAddr(StartToken, @InStart) Or Not Mamute_ParseHexAddr(EndToken, @InEnd)
          *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
          ProcedureReturn
        EndIf
        If FieldCount = 4
          Protected ExecToken.s = Trim(StringField(Args, 4, ","))
          If Not Mamute_ParseHexAddr(ExecToken, @InExec)
            *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
            ProcedureReturn
          EndIf
        Else
          InExec = InStart
        EndIf
        HasAddrs = #True
      Default
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
        ProcedureReturn
    EndSelect
  EndIf

  Protected Dim NoExplicitBuf.a(0)
  Protected ResultMsg.s = MamuteSave_Open(Win, SuggestedName, HasAddrs, InStart, InEnd, InExec, #False, NoExplicitBuf())
  If ResultMsg <> ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, ResultMsg)
  EndIf
EndProcedure

; M [<endereco>] - edicao rapida (MamuteMGui.pbi, mesmo esquema do DM: setas/
; PgUp/PgDn/TAB/+-/botoes, mas hexa digitado tecla-a-tecla direto, sem campo
; de edicao - ver comentario de topo de MamuteMGui.pbi). <endereco> omitido
; continua de onde a janela do M ficou da ultima vez (State\LastMAddr) - so
; funciona depois que o M ja abriu ao menos uma vez nesta sessao da janela.
Procedure MamuteGui_CmdM(Win, G_Log, *State.MamuteGui_State, Args.s)
  Protected Addr.i
  Protected Trimmed.s = Trim(Args)
  If Trimmed = ""
    If Not *State\HasLastM
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
    Addr = *State\LastMAddr
  Else
    If Not Mamute_ParseHexAddr(Trimmed, @Addr)
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
  EndIf

  *State\LastMAddr = MamuteM_Open(Win, Addr, 0, #False)
  *State\HasLastM = #True
EndProcedure

; S [<endereco>] - "so como curiosidade", pedido do usuario: funciona igual
; ao M, mas escreve os nibbles usando as 16 teclas CONFIGURAVEIS em
; "Configurar -> Mamute Assembler..." (MamuteSKeyMap(), MamuteSupport.pbi)
; em vez de 0-9/A-F fixos. "Memoria" de ultimo endereco separada da do M
; (State\LastSAddr), mesmo espirito do comando S original ser uma variacao
; do M, nao o mesmo estado.
Procedure MamuteGui_CmdS(Win, G_Log, *State.MamuteGui_State, Args.s)
  Protected Addr.i
  Protected Trimmed.s = Trim(Args)
  If Trimmed = ""
    If Not *State\HasLastS
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
    Addr = *State\LastSAddr
  Else
    If Not Mamute_ParseHexAddr(Trimmed, @Addr)
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
  EndIf

  *State\LastSAddr = MamuteM_Open(Win, Addr, 0, #True)
  *State\HasLastS = #True
EndProcedure

; C <modo> - define o modo de exibicao (0-3) que os comandos D/P/V (ainda
; nao implementados) vao usar pra formatar a saida. So guarda o estado
; (State\DisplayMode, dura so esta sessao da janela - nao persiste em
; mamute_settings.json, mesmo espirito volatil do PAGE) e confirma no log,
; mesmo idioma do PAGE ecoando o estado apos uma mudanca. Precisa de espaco
; entre o verbo e o numero ("C 1") - o "C1" colado do manual original nao e
; reconhecido, porque MamuteGui_Dispatch() sempre separa verbo/argumentos
; pelo primeiro espaco.
Procedure MamuteGui_CmdC(G_Log, *State.MamuteGui_State, Args.s)
  Protected Trimmed.s = Trim(Args)
  If Not Mamute_IsHexString(Trimmed, 1)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected Mode.i = Val(Trimmed)
  If Mode < 0 Or Mode > 3
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  *State\DisplayMode = Mode
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "MODO " + Str(Mode) + ": " + Mamute_DisplayModeText(Mode))
EndProcedure

; Parser comum de "<endinic>[,<endfim>]" usado por D/P/V - IsVram escolhe
; entre Mamute_ParseHexAddr (RAM/ROM, 4 digitos, mapeamento PAGE ativo) e
; Mamute_ParseVramAddr (VRAM plana, 1-5 digitos, validada contra
; MamuteVramSize). Sem <endfim>, mostra so 16 bytes (pedido explicito do
; manual original), limitado ao teto do espaco de enderecos (sem
; wraparound, ao contrario do SH/M) - passar do teto e erro de sintaxe.
Procedure.b MamuteGui_ParseDpvArgs(Args.s, IsVram.b, *OutStart.Integer, *OutEnd.Integer)
  Protected CommaPos.i = FindString(Args, ",")
  Protected StartToken.s, EndToken.s
  If CommaPos > 0
    StartToken = Trim(Left(Args, CommaPos - 1))
    EndToken = Trim(Mid(Args, CommaPos + 1))
  Else
    StartToken = Trim(Args)
    EndToken = ""
  EndIf

  If StartToken = ""
    ProcedureReturn #False
  EndIf

  Protected StartAddr.i, EndAddr.i, MaxAddr.i
  If IsVram
    If Not Mamute_ParseVramAddr(StartToken, @StartAddr)
      ProcedureReturn #False
    EndIf
    MaxAddr = MamuteVramSize - 1
  Else
    If Not Mamute_ParseHexAddr(StartToken, @StartAddr)
      ProcedureReturn #False
    EndIf
    MaxAddr = $FFFF
  EndIf

  If EndToken = ""
    EndAddr = StartAddr + 15
    If EndAddr > MaxAddr : EndAddr = MaxAddr : EndIf
  Else
    If IsVram
      If Not Mamute_ParseVramAddr(EndToken, @EndAddr)
        ProcedureReturn #False
      EndIf
    Else
      If Not Mamute_ParseHexAddr(EndToken, @EndAddr)
        ProcedureReturn #False
      EndIf
    EndIf
    If EndAddr < StartAddr
      ProcedureReturn #False
    EndIf
  EndIf

  *OutStart\i = StartAddr
  *OutEnd\i = EndAddr
  ProcedureReturn #True
EndProcedure

; D <endinic>[,<endfim>] - despejo formatado da RAM/ROM direto no log do
; MON>, no formato definido pelo comando C (State\DisplayMode). Le via
; Mamute_ReadByte() - resolve pelo mapeamento PAGE ativo agora, mesma regra
; de leitura do DM.
Procedure MamuteGui_CmdD(G_Log, *State.MamuteGui_State, Args.s)
  Protected StartAddr.i, EndAddr.i
  If Not MamuteGui_ParseDpvArgs(Args, #False, @StartAddr, @EndAddr)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected NewList Lines.s()
  Mamute_BuildDumpLines(Lines(), StartAddr, EndAddr, *State\DisplayMode, #False)
  ForEach Lines()
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, Lines())
  Next
EndProcedure

; P <endinic>[,<endfim>] - mesmo despejo do D, mas "na impressora": ainda
; nao existe driver de impressora de verdade (Epson FX-80 fica pra uma
; sessao futura, pedido explicito do usuario), entao por hora gera um PDF A4
; simples (Mamute_SavePdfListing(), MamutePdf.pbi, XIncludeFile'd antes
; deste arquivo) e abre "Salvar como" no final.
Procedure MamuteGui_CmdP(G_Log, *State.MamuteGui_State, Args.s)
  Protected StartAddr.i, EndAddr.i
  If Not MamuteGui_ParseDpvArgs(Args, #False, @StartAddr, @EndAddr)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected NewList Lines.s()
  Mamute_BuildDumpLines(Lines(), StartAddr, EndAddr, *State\DisplayMode, #False)

  Protected FilePath.s = SaveFileRequester("Salvar listagem (P) como PDF", "listagem.pdf", "PDF (*.pdf)|*.pdf", 0)
  If FilePath = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "CANCELADO")
    ProcedureReturn
  EndIf
  If LCase(Right(FilePath, 4)) <> ".pdf"
    FilePath + ".pdf"
  EndIf

  Protected Header.s = "P " + Mamute_Hex4(StartAddr) + "-" + Mamute_Hex4(EndAddr) + " MODO " + Str(*State\DisplayMode)
  If Mamute_SavePdfListing(FilePath, Lines(), Header)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "PDF GRAVADO: " + FilePath)
  Else
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO AO GRAVAR PDF")
  EndIf
EndProcedure

; V <endinic>[,<endfim>] - igual ao P, mas le da VRAM simulada (MamuteVRAM(),
; endereco plano ate MamuteVramSize-1, sem PAGE nem banco algum - VRAM nunca
; foi mapeada no espaco de enderecos do Z80 de verdade, entao a mesma regra
; nao se aplica aqui) em vez da RAM/ROM.
Procedure MamuteGui_CmdV(G_Log, *State.MamuteGui_State, Args.s)
  Protected StartAddr.i, EndAddr.i
  If Not MamuteGui_ParseDpvArgs(Args, #True, @StartAddr, @EndAddr)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected NewList Lines.s()
  Mamute_BuildDumpLines(Lines(), StartAddr, EndAddr, *State\DisplayMode, #True)

  Protected FilePath.s = SaveFileRequester("Salvar listagem (V) como PDF", "listagem_vram.pdf", "PDF (*.pdf)|*.pdf", 0)
  If FilePath = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "CANCELADO")
    ProcedureReturn
  EndIf
  If LCase(Right(FilePath, 4)) <> ".pdf"
    FilePath + ".pdf"
  EndIf

  Protected Header.s = "V " + Mamute_HexPad(StartAddr, 5) + "-" + Mamute_HexPad(EndAddr, 5) + " MODO " + Str(*State\DisplayMode)
  If Mamute_SavePdfListing(FilePath, Lines(), Header)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "PDF GRAVADO: " + FilePath)
  Else
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO AO GRAVAR PDF")
  EndIf
EndProcedure

; T <endinic>,<endfim>,<enddest> - transfere o bloco [endinic,endfim] (RAM/ROM,
; mapeamento PAGE ativo agora) pra um novo bloco iniciado em <enddest>. Sem
; wraparound (mesma regra do D/P/V) - se <enddest> + tamanho do bloco passar
; de FFFF, e ?ERRO DE SINTAXE, nao da a volta pro 0000. Suporta origem/destino
; sobrepostos: copia de tras pra frente quando <enddest> > <endinic> (senao a
; copia sobrescreveria bytes de origem ainda nao lidos), de frente pra tras
; caso contrario - mesmo algoritmo de um memmove seguro.
Procedure MamuteGui_CmdT(G_Log, *State.MamuteGui_State, Args.s)
  Protected CommaPos1.i = FindString(Args, ",")
  If CommaPos1 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected Rest1.s = Mid(Args, CommaPos1 + 1)
  Protected CommaPos2.i = FindString(Rest1, ",")
  If CommaPos2 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected StartToken.s = Trim(Left(Args, CommaPos1 - 1))
  Protected EndToken.s = Trim(Left(Rest1, CommaPos2 - 1))
  Protected DestToken.s = Trim(Mid(Rest1, CommaPos2 + 1))

  Protected StartAddr.i, EndAddr.i, DestAddr.i
  If Not Mamute_ParseHexAddr(StartToken, @StartAddr) Or Not Mamute_ParseHexAddr(EndToken, @EndAddr) Or
     Not Mamute_ParseHexAddr(DestToken, @DestAddr)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  If EndAddr < StartAddr
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected Length.i = EndAddr - StartAddr + 1
  If DestAddr + Length - 1 > $FFFF
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected i.i
  If DestAddr > StartAddr
    For i = Length - 1 To 0 Step -1
      Mamute_WriteByte(DestAddr + i, Mamute_ReadByte(StartAddr + i))
    Next
  Else
    For i = 0 To Length - 1
      Mamute_WriteByte(DestAddr + i, Mamute_ReadByte(StartAddr + i))
    Next
  EndIf

  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "TRANSFERIDO " + Mamute_Hex4(StartAddr) + "-" + Mamute_Hex4(EndAddr) + " PARA " + Mamute_Hex4(DestAddr))
EndProcedure

; F <endinic>,<endfim>,<byte> - preenche o bloco [endinic,endfim] (RAM/ROM,
; mapeamento PAGE ativo agora) inteiro com <byte> (1-2 digitos hexa).
; Escrita silenciosa em celulas que nao sejam RAM (Mamute_WriteByte ja
; recusa, mesma regra do DM/MS/T).
Procedure MamuteGui_CmdF(G_Log, *State.MamuteGui_State, Args.s)
  Protected CommaPos1.i = FindString(Args, ",")
  If CommaPos1 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected Rest1.s = Mid(Args, CommaPos1 + 1)
  Protected CommaPos2.i = FindString(Rest1, ",")
  If CommaPos2 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected StartToken.s = Trim(Left(Args, CommaPos1 - 1))
  Protected EndToken.s = Trim(Left(Rest1, CommaPos2 - 1))
  Protected ByteToken.s = Trim(Mid(Rest1, CommaPos2 + 1))

  Protected StartAddr.i, EndAddr.i
  If Not Mamute_ParseHexAddr(StartToken, @StartAddr) Or Not Mamute_ParseHexAddr(EndToken, @EndAddr)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  If EndAddr < StartAddr
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  If Not Mamute_IsHexString(ByteToken, 2)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected FillByte.i = Val("$" + ByteToken)

  Protected Addr.i
  For Addr = StartAddr To EndAddr
    Mamute_WriteByte(Addr, FillByte)
  Next

  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "PREENCHIDO " + Mamute_Hex4(StartAddr) + "-" + Mamute_Hex4(EndAddr) + " COM " + Mamute_Hex2(FillByte))
EndProcedure

; G <endinic>[,<brkpnt1>[,<brkpnt2>]] - abre o debugger visual (MamuteDebuggerGui.pbi) no
; endereco informado, com ate 2 breakpoints opcionais ja armados (modulo 32 do SPEC.md, Fase 1
; do debugger visual - "simulador Z80 puro", sem VDP/PSG/FDC/BIOS - chamadas de sistema real
; nao sao simuladas, o usuario pula/ajusta registradores manualmente na janela e segue).
Procedure MamuteGui_CmdG(G_Log, *State.MamuteGui_State, Win, Args.s)
  Protected Trimmed.s = Trim(Args)
  If Trimmed = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected StartToken.s, Brk1Token.s = "", Brk2Token.s = ""
  Protected CommaPos1.i = FindString(Trimmed, ",")
  If CommaPos1 = 0
    StartToken = Trimmed
  Else
    StartToken = Trim(Left(Trimmed, CommaPos1 - 1))
    Protected Rest1.s = Mid(Trimmed, CommaPos1 + 1)
    Protected CommaPos2.i = FindString(Rest1, ",")
    If CommaPos2 = 0
      Brk1Token = Trim(Rest1)
    Else
      Brk1Token = Trim(Left(Rest1, CommaPos2 - 1))
      Brk2Token = Trim(Mid(Rest1, CommaPos2 + 1))
    EndIf
  EndIf

  Protected StartAddr.i, Brk1.i, Brk2.i
  If Not Mamute_ParseHexAddr(StartToken, @StartAddr)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  If Brk1Token <> "" And Not Mamute_ParseHexAddr(Brk1Token, @Brk1)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  If Brk2Token <> "" And Not Mamute_ParseHexAddr(Brk2Token, @Brk2)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  *State\HasBreak1 = Bool(Brk1Token <> "")
  If *State\HasBreak1 : *State\Break1Addr = Brk1 : EndIf
  *State\HasBreak2 = Bool(Brk2Token <> "")
  If *State\HasBreak2 : *State\Break2Addr = Brk2 : EndIf

  Protected Msg.s = "G " + Mamute_Hex4(StartAddr)
  If Brk1Token <> "" : Msg + "," + Mamute_Hex4(Brk1) : EndIf
  If Brk2Token <> "" : Msg + "," + Mamute_Hex4(Brk2) : EndIf
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, Msg)

  MamuteDebugger_Open(Win, *State, StartAddr)
EndProcedure

; R [<offset>] - carregamento de programa assemblado (gravado pela opcao 'I'
; do comando A original) depende do assemblador embutido, que tambem fica
; pra uma fase futura - pedido explicito do usuario: "apenas de a informacao
; na tela que vai ser implementado e mais nada". Sem parsing/validacao
; nenhuma - ignora Args de proposito, so confirma a informacao.
Procedure MamuteGui_CmdR(G_Log, *State.MamuteGui_State, Args.s)
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "R - CARREGAMENTO DE PROGRAMA ASSEMBLADO AINDA NAO IMPLEMENTADO, FICA PRA UMA FASE FUTURA")
EndProcedure

; FOSSAURO - comando NOVO, fora do vocabulario do MegaAssembler original de
; proposito (nao existe um "envie pra outro emulador rodando de verdade" no
; manual de 1986) - pedido explicito do usuario, primeira ponta-a-ponta do
; protocolo de controle remoto (ver docs/SPEC.md modulo 32u). Reenvia o
; MESMO intervalo [MamuteAsmLastStartAddr, MamuteAsmLastByteCount) que "A O"
; (tela EDIT) acabou de gravar em MamuteMem, lido de volta byte a byte via
; Mamute_ReadByte() (respeita o mapeamento PAGE ativo, igual DM/qualquer
; outro comando de memoria) - depois digita "DEFUSR0=&H<endereco>" na
; janela do Fossauro (ver Fossauro_SendAndType(), FossauroSupport.pbi).
; NAO executa mais o codigo sozinho por padrao (nao manda mais RUN cru):
; pedido explicito do usuario (2026-08-19, modulo 32y) - tecnicamente so'
; precisa transferir pra RAM, nao rodar; RUN cru sequestrava PC/SP de uma
; sessao MSX ja viva (modulo 32x), enquanto DEFUSR digitado deixa a
; BIOS/BASIC tratar a chamada com o contexto consistente dela. Se
; MamuteAutoRunAfterTransfer estiver ligado (Configurar -> Mamute Assembler...,
; MamuteSupport.pbi, default desligado), digita ":A=USR0(0)" na mesma linha
; do DEFUSR0, executando na hora - senao fica so' o DEFUSR0, pronto pro
; usuario digitar "A=USR0(0)" manualmente na janela do Fossauro quando
; quiser. Exige MamuteAsmLastWroteToRam (so' fica #True depois
; de um "A ...O..." bem-sucedido - "A" sozinho, sem "O", NAO escreve nada em
; MamuteMem, entao enviar seria so' lixo/zeros).
Procedure MamuteGui_CmdFossauro(G_Log, *State.MamuteGui_State)
  If Not MamuteAsmHasResult Or Not MamuteAsmLastWroteToRam
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
      "?NADA MONTADO COM 'O' AINDA (monte com 'A O' na tela EDIT antes de FOSSAURO)")
    ProcedureReturn
  EndIf
  If MamuteAsmLastByteCount <= 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?NADA GERADO (0 BYTES)")
    ProcedureReturn
  EndIf

  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "FOSSAURO: ENVIANDO " + Str(MamuteAsmLastByteCount) + " BYTES PARA " + Mamute_Hex4(MamuteAsmLastStartAddr) + "H...")

  Protected *Payload = AllocateMemory(MamuteAsmLastByteCount)
  Protected I.i
  For I = 0 To MamuteAsmLastByteCount - 1
    PokeA(*Payload + I, Mamute_ReadByte((MamuteAsmLastStartAddr + I) & $FFFF))
  Next I

  Protected ErrMsg.s = Fossauro_SendAndType(MamuteAsmLastStartAddr, *Payload, MamuteAsmLastByteCount, MamuteAutoRunAfterTransfer)
  FreeMemory(*Payload)

  If ErrMsg = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
      "OK - CARREGADO NO FOSSAURO EM " + Mamute_Hex4(MamuteAsmLastStartAddr) + "H, DEFUSR0 JA DIGITADO")
    If MamuteAutoRunAfterTransfer
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "EXECUTADO (A=USR0(0))")
    Else
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
        "DIGITE A=USR0(0) NA JANELA DO FOSSAURO PRA RODAR")
    EndIf
  Else
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?" + UCase(ErrMsg))
  EndIf
EndProcedure

; OPENMSX - mesma ideia do FOSSAURO logo acima, mirando a instancia de openMSX de verdade em
; vez do Fossauro (pedido explicito do usuario, 2026-08-19: "mesmo processo, mas voltando do
; compilador a pessoa usa openMSX" - reaproveita o bridge Tcl/XML ja existente,
; OpenMSXBridge.pbi modulo 12, em vez de reinventar). Mesmo intervalo
; [MamuteAsmLastStartAddr, MamuteAsmLastByteCount) lido via Mamute_ReadByte(), mas gravado byte
; a byte na RAM real via "debug write memory" (comando nativo do openMSX,
; OMSX_FlushMamuteProgram()) em vez de um protocolo proprio - depois digita "DEFUSR0=&H<endereco>"
; (+ ":A=USR0(0)" se MamuteAutoRunAfterTransfer, MESMA flag que o FOSSAURO usa - e' a mesma
; decisao "executar ou nao" pro usuario, independente de qual dos dois emuladores) via
; OMSX_TypeText() - "type" nativo do openMSX, digita no teclado emulado de verdade. Sobe o
; openMSX sozinho se precisar (OMSX_SendMamuteProgram() -> OMSX_Start(), mesmo botao "Executar
; -> Abrir o openMSX..." usa). Mesma exigencia de MamuteAsmLastWroteToRam do FOSSAURO.
Procedure MamuteGui_CmdOpenMSX(G_Log, *State.MamuteGui_State)
  If Not MamuteAsmHasResult Or Not MamuteAsmLastWroteToRam
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
      "?NADA MONTADO COM 'O' AINDA (monte com 'A O' na tela EDIT antes de OPENMSX)")
    ProcedureReturn
  EndIf
  If MamuteAsmLastByteCount <= 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?NADA GERADO (0 BYTES)")
    ProcedureReturn
  EndIf
  If BadigCfg\EmulatorPath = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
      "?CAMINHO DO OPENMSX NAO CONFIGURADO (Configurar -> openMSX...)")
    ProcedureReturn
  EndIf

  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "OPENMSX: ENVIANDO " + Str(MamuteAsmLastByteCount) + " BYTES PARA " + Mamute_Hex4(MamuteAsmLastStartAddr) + "H...")

  Protected *Payload = AllocateMemory(MamuteAsmLastByteCount)
  Protected I.i
  For I = 0 To MamuteAsmLastByteCount - 1
    PokeA(*Payload + I, Mamute_ReadByte((MamuteAsmLastStartAddr + I) & $FFFF))
  Next I

  Protected Ok.b = OMSX_SendMamuteProgram(MamuteAsmLastStartAddr, *Payload, MamuteAsmLastByteCount, MamuteAutoRunAfterTransfer)
  FreeMemory(*Payload)

  If Ok
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
      "OK - CARREGADO NO OPENMSX EM " + Mamute_Hex4(MamuteAsmLastStartAddr) + "H, DEFUSR0 JA DIGITADO")
    If MamuteAutoRunAfterTransfer
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "EXECUTADO (A=USR0(0))")
    Else
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
        "DIGITE A=USR0(0) NA JANELA DO OPENMSX PRA RODAR")
    EndIf
  Else
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?FALHA AO ABRIR O OPENMSX")
  EndIf
EndProcedure

; Valor de 16 bits do par PairName (AF/BC/DE/HL a partir dos bytes, IX/IY/SP
; direto) - usado pelo modo "par" do X (ver comentario da Procedure abaixo).
; Casos AF'/BC'/DE'/HL' (par alternado) e PC acrescentados pro XRG (comando
; novo, ver MamuteGui_CmdXrg mais abaixo) - o X nunca passa esses nomes,
; entao a extensao nao muda o comportamento existente do X.
Procedure.i MamuteGui_RegPairValue(*State.MamuteGui_State, PairName.s)
  Select PairName
    Case "AF" : ProcedureReturn (*State\RegA << 8) | *State\RegF
    Case "BC" : ProcedureReturn (*State\RegB << 8) | *State\RegC
    Case "DE" : ProcedureReturn (*State\RegD << 8) | *State\RegE
    Case "HL" : ProcedureReturn (*State\RegH << 8) | *State\RegL
    Case "AF'" : ProcedureReturn (*State\RegA2 << 8) | *State\RegF2
    Case "BC'" : ProcedureReturn (*State\RegB2 << 8) | *State\RegC2
    Case "DE'" : ProcedureReturn (*State\RegD2 << 8) | *State\RegE2
    Case "HL'" : ProcedureReturn (*State\RegH2 << 8) | *State\RegL2
    Case "IX" : ProcedureReturn *State\RegIX
    Case "IY" : ProcedureReturn *State\RegIY
    Case "SP" : ProcedureReturn *State\RegSP
    Case "PC" : ProcedureReturn *State\RegPC
  EndSelect
  ProcedureReturn 0
EndProcedure

Procedure MamuteGui_SetRegPair(*State.MamuteGui_State, PairName.s, Value.i)
  Select PairName
    Case "AF" : *State\RegA = (Value >> 8) & $FF : *State\RegF = Value & $FF
    Case "BC" : *State\RegB = (Value >> 8) & $FF : *State\RegC = Value & $FF
    Case "DE" : *State\RegD = (Value >> 8) & $FF : *State\RegE = Value & $FF
    Case "HL" : *State\RegH = (Value >> 8) & $FF : *State\RegL = Value & $FF
    Case "AF'" : *State\RegA2 = (Value >> 8) & $FF : *State\RegF2 = Value & $FF
    Case "BC'" : *State\RegB2 = (Value >> 8) & $FF : *State\RegC2 = Value & $FF
    Case "DE'" : *State\RegD2 = (Value >> 8) & $FF : *State\RegE2 = Value & $FF
    Case "HL'" : *State\RegH2 = (Value >> 8) & $FF : *State\RegL2 = Value & $FF
    Case "IX" : *State\RegIX = Value & $FFFF
    Case "IY" : *State\RegIY = Value & $FFFF
    Case "SP" : *State\RegSP = Value & $FFFF
    Case "PC" : *State\RegPC = Value & $FFFF
  EndSelect
EndProcedure

; Idem acima pros registradores de 1 byte - casos A'/F'/B'/C'/D'/E'/H'/L'
; (par alternado) e IXH/IXL/IYH/IYL (meios-indices) acrescentados pro XRG.
; Nao reaproveita Mz80_GetIXH/SetIXH etc. (MamuteZ80Cpu.pbi) porque aquele
; arquivo e' incluido DEPOIS deste em BadigEditor.pb - mesma extracao de
; bits, duplicada aqui de proposito.
Procedure.i MamuteGui_RegByteValue(*State.MamuteGui_State, RegName.s)
  Select RegName
    Case "A" : ProcedureReturn *State\RegA
    Case "F" : ProcedureReturn *State\RegF
    Case "B" : ProcedureReturn *State\RegB
    Case "C" : ProcedureReturn *State\RegC
    Case "D" : ProcedureReturn *State\RegD
    Case "E" : ProcedureReturn *State\RegE
    Case "H" : ProcedureReturn *State\RegH
    Case "L" : ProcedureReturn *State\RegL
    Case "A'" : ProcedureReturn *State\RegA2
    Case "F'" : ProcedureReturn *State\RegF2
    Case "B'" : ProcedureReturn *State\RegB2
    Case "C'" : ProcedureReturn *State\RegC2
    Case "D'" : ProcedureReturn *State\RegD2
    Case "E'" : ProcedureReturn *State\RegE2
    Case "H'" : ProcedureReturn *State\RegH2
    Case "L'" : ProcedureReturn *State\RegL2
    Case "IXH" : ProcedureReturn (*State\RegIX >> 8) & $FF
    Case "IXL" : ProcedureReturn *State\RegIX & $FF
    Case "IYH" : ProcedureReturn (*State\RegIY >> 8) & $FF
    Case "IYL" : ProcedureReturn *State\RegIY & $FF
  EndSelect
  ProcedureReturn 0
EndProcedure

Procedure MamuteGui_SetRegByte(*State.MamuteGui_State, RegName.s, Value.i)
  Select RegName
    Case "A" : *State\RegA = Value & $FF
    Case "F" : *State\RegF = Value & $FF
    Case "B" : *State\RegB = Value & $FF
    Case "C" : *State\RegC = Value & $FF
    Case "D" : *State\RegD = Value & $FF
    Case "E" : *State\RegE = Value & $FF
    Case "H" : *State\RegH = Value & $FF
    Case "L" : *State\RegL = Value & $FF
    Case "A'" : *State\RegA2 = Value & $FF
    Case "F'" : *State\RegF2 = Value & $FF
    Case "B'" : *State\RegB2 = Value & $FF
    Case "C'" : *State\RegC2 = Value & $FF
    Case "D'" : *State\RegD2 = Value & $FF
    Case "E'" : *State\RegE2 = Value & $FF
    Case "H'" : *State\RegH2 = Value & $FF
    Case "L'" : *State\RegL2 = Value & $FF
    Case "IXH" : *State\RegIX = (*State\RegIX & $00FF) | ((Value & $FF) << 8)
    Case "IXL" : *State\RegIX = (*State\RegIX & $FF00) | (Value & $FF)
    Case "IYH" : *State\RegIY = (*State\RegIY & $00FF) | ((Value & $FF) << 8)
    Case "IYL" : *State\RegIY = (*State\RegIY & $FF00) | (Value & $FF)
  EndSelect
EndProcedure

; Mostra os 7 pares (AF/BC/DE/HL/IX/IY/SP) em 2 linhas compactas no log.
Procedure.s MamuteGui_ShowRegs(G_Log, Accum.s, *State.MamuteGui_State)
  Accum = MamuteGui_AppendLog(G_Log, Accum,
    "AF=" + Mamute_Hex4(MamuteGui_RegPairValue(*State, "AF")) +
    " BC=" + Mamute_Hex4(MamuteGui_RegPairValue(*State, "BC")) +
    " DE=" + Mamute_Hex4(MamuteGui_RegPairValue(*State, "DE")) +
    " HL=" + Mamute_Hex4(MamuteGui_RegPairValue(*State, "HL")))
  Accum = MamuteGui_AppendLog(G_Log, Accum,
    "IX=" + Mamute_Hex4(*State\RegIX) + " IY=" + Mamute_Hex4(*State\RegIY) + " SP=" + Mamute_Hex4(*State\RegSP))
  ProcedureReturn Accum
EndProcedure

; "----" (nao definido) ou o endereco em hexa - usado pelas 5 colunas de
; breakpoint do MamuteGui_ShowRegsXrg() logo abaixo.
Procedure.s MamuteGui_XgoBreakText(HasIt.b, Addr.u)
  If HasIt : ProcedureReturn Mamute_Hex4(Addr) : EndIf
  ProcedureReturn "----"
EndProcedure

; Mostra os 7 pares "normais" (MamuteGui_ShowRegs() acima, reaproveitado tal
; e qual) mais os "secretos" (AF'/BC'/DE'/HL'), o PC e os 5 breakpoints
; nomeados do XGO (BP/BP1/BP2/BP3/BPF, docs/SPEC.md modulo 45j) - usado so'
; pelo XRG (comando novo, ver MamuteGui_CmdXrg logo abaixo).
Procedure.s MamuteGui_ShowRegsXrg(G_Log, Accum.s, *State.MamuteGui_State)
  Accum = MamuteGui_ShowRegs(G_Log, Accum, *State)
  Accum = MamuteGui_AppendLog(G_Log, Accum,
    "AF'=" + Mamute_Hex4(MamuteGui_RegPairValue(*State, "AF'")) +
    " BC'=" + Mamute_Hex4(MamuteGui_RegPairValue(*State, "BC'")) +
    " DE'=" + Mamute_Hex4(MamuteGui_RegPairValue(*State, "DE'")) +
    " HL'=" + Mamute_Hex4(MamuteGui_RegPairValue(*State, "HL'")))
  Accum = MamuteGui_AppendLog(G_Log, Accum, "PC=" + Mamute_Hex4(*State\RegPC))
  Accum = MamuteGui_AppendLog(G_Log, Accum,
    "BP=" + MamuteGui_XgoBreakText(*State\HasXgoBp, *State\XgoBpAddr) +
    " BP1=" + MamuteGui_XgoBreakText(*State\HasXgoBp1, *State\XgoBp1Addr) +
    " BP2=" + MamuteGui_XgoBreakText(*State\HasXgoBp2, *State\XgoBp2Addr) +
    " BP3=" + MamuteGui_XgoBreakText(*State\HasXgoBp3, *State\XgoBp3Addr) +
    " BPF=" + MamuteGui_XgoBreakText(*State\HasXgoBpF, *State\XgoBpFAddr))
  ProcedureReturn Accum
EndProcedure

; Classifica RegName (ja em maiusculas) pro XRG - 1 = registrador de 1 byte
; (2 digitos hexa), 2 = par de 16 bits (4 digitos hexa, incluindo os
; "secretos" AF'/BC'/DE'/HL' e o PC), 3 = um dos 5 breakpoints nomeados do
; XGO (BP/BP1/BP2/BP3/BPF - nao sao registradores de verdade, ver comentario
; da Procedure MamuteGui_CmdXrg abaixo e MamuteGui_CmdXgo/docs/SPEC.md
; modulo 45j), 0 = nome desconhecido.
Procedure.b MamuteGui_XrgRegKind(RegName.s)
  Select RegName
    Case "A", "F", "B", "C", "D", "E", "H", "L",
         "A'", "F'", "B'", "C'", "D'", "E'", "H'", "L'",
         "IXH", "IXL", "IYH", "IYL"
      ProcedureReturn 1
    Case "AF", "BC", "DE", "HL", "AF'", "BC'", "DE'", "HL'", "IX", "IY", "SP", "PC"
      ProcedureReturn 2
    Case "BP", "BP1", "BP2", "BP3", "BPF"
      ProcedureReturn 3
  EndSelect
  ProcedureReturn 0
EndProcedure

; Grava Addr no breakpoint nomeado RegName (BP/BP1/BP2/BP3/BPF) - usado so'
; pelo MamuteGui_CmdXrg (Kind=3) logo abaixo.
Procedure MamuteGui_XrgSetBreak(*State.MamuteGui_State, RegName.s, Addr.u)
  Select RegName
    Case "BP"  : *State\HasXgoBp  = #True : *State\XgoBpAddr  = Addr
    Case "BP1" : *State\HasXgoBp1 = #True : *State\XgoBp1Addr = Addr
    Case "BP2" : *State\HasXgoBp2 = #True : *State\XgoBp2Addr = Addr
    Case "BP3" : *State\HasXgoBp3 = #True : *State\XgoBp3Addr = Addr
    Case "BPF" : *State\HasXgoBpF = #True : *State\XgoBpFAddr = Addr
  EndSelect
EndProcedure

; XRG - porta do RG do SUPER-X (docs/SPEC.md modulo 45, inventario) - mostra/
; edita os registradores Z80 simulados (os mesmos campos Reg*/RegA2../RegPC
; de MamuteGui_State que o motor de execucao real de MamuteZ80Cpu.pbi ja usa,
; e que o comando X ja edita parcialmente). Pedido explicito do usuario:
;
;   XRG                 - sem argumento, mostra TODOS os pares (normais +
;                          "secretos" AF'/BC'/DE'/HL' + PC) mais o estado
;                          do BP (MamuteGui_ShowRegsXrg acima).
;   XRG *               - limpa TODOS os registradores (A-L, o par
;                          alternado, IX/IY/PC/I/R/IFF1/IFF2/IM/estado de
;                          HALT) EXCETO a pilha (SP) - mesma ressalva do
;                          inventario do SUPER-X ("RG *" limpa tudo "except
;                          stack").
;   XRG +               - reseta so' a pilha (SP) pro seu inicio - $0000
;                          (mesma convencao "zero-inicializado = boot
;                          limpo" ja documentada no topo da Structure
;                          MamuteGui_State; a pilha cresce pra baixo, entao
;                          SP=0000 e' o topo "logico" do espaco de 64K - o
;                          1o PUSH grava em $FFFF).
;   XRG <reg>,<valor>   - atribui <valor> (hexa) a <reg>. Registradores de 1
;                          byte (A/F/B/C/D/E/H/L, o par alternado com "'" e
;                          IXH/IXL/IYH/IYL) aceitam 1-2 digitos; pares de 16
;                          bits (AF/BC/DE/HL, o par alternado, IX/IY/SP/PC)
;                          aceitam 1-4. Alterar SP muda a MESMA RegSP que
;                          PUSH/POP/CALL/RET ja usam (MamuteZ80Cpu.pbi), nao
;                          e' um valor cosmetico separado. **BP/BP1/BP2/
;                          BP3/BPF nao sao registradores de verdade** - cada
;                          um marca um endereco de breakpoint DEDICADO
;                          (HasXgoBp*/XgoBp*Addr, independente de
;                          HasBreak1/Break2 que o comando G/debugger grafico
;                          continuam usando do jeito de sempre) - o XGO
;                          (docs/SPEC.md modulo 45j) para nesses enderecos
;                          em sequencia (BP->BP1->BP2->BP3->BPF) e mostra os
;                          registradores, mesmo idioma do manual original
;                          ("the program will stop at this point and the
;                          registers are displayed").
;
; Qualquer nome fora dos reconhecidos por MamuteGui_XrgRegKind() acima, ou
; sintaxe fora dos 4 formatos deste comentario, e' ?ERRO DE SINTAXE.
Procedure MamuteGui_CmdXrg(G_Log, *State.MamuteGui_State, Args.s)
  Protected Trimmed.s = UCase(Trim(Args))

  If Trimmed = ""
    *State\LogAccum = MamuteGui_ShowRegsXrg(G_Log, *State\LogAccum, *State)
    ProcedureReturn
  EndIf

  If Trimmed = "*"
    *State\RegA = 0 : *State\RegF = 0 : *State\RegB = 0 : *State\RegC = 0
    *State\RegD = 0 : *State\RegE = 0 : *State\RegH = 0 : *State\RegL = 0
    *State\RegA2 = 0 : *State\RegF2 = 0 : *State\RegB2 = 0 : *State\RegC2 = 0
    *State\RegD2 = 0 : *State\RegE2 = 0 : *State\RegH2 = 0 : *State\RegL2 = 0
    *State\RegIX = 0 : *State\RegIY = 0 : *State\RegPC = 0
    *State\RegI = 0 : *State\RegR = 0
    *State\IFF1 = #False : *State\IFF2 = #False : *State\IM = 0
    *State\Halted = #False
    *State\LogAccum = MamuteGui_ShowRegsXrg(G_Log, *State\LogAccum, *State)
    ProcedureReturn
  EndIf

  If Trimmed = "+"
    *State\RegSP = 0
    *State\LogAccum = MamuteGui_ShowRegsXrg(G_Log, *State\LogAccum, *State)
    ProcedureReturn
  EndIf

  Protected CommaPos.i = FindString(Trimmed, ",")
  If CommaPos = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected RegName.s = Trim(Left(Trimmed, CommaPos - 1))
  Protected ValTok.s = Trim(Mid(Trimmed, CommaPos + 1))
  If ValTok = "" Or FindString(ValTok, ",") > 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected Kind.b = MamuteGui_XrgRegKind(RegName)
  Protected Value.i

  Select Kind
    Case 1
      If Not Mamute_IsHexString(ValTok, 2)
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
        ProcedureReturn
      EndIf
      MamuteGui_SetRegByte(*State, RegName, Val("$" + ValTok))

    Case 2
      If Not Mamute_ParseHexAddr(ValTok, @Value)
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
        ProcedureReturn
      EndIf
      MamuteGui_SetRegPair(*State, RegName, Value)

    Case 3 ; BP/BP1/BP2/BP3/BPF - marca um dos 5 breakpoints nomeados do XGO
      If Not Mamute_ParseHexAddr(ValTok, @Value)
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
        ProcedureReturn
      EndIf
      MamuteGui_XrgSetBreak(*State, RegName, Value)

    Default
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
  EndSelect

  *State\LogAccum = MamuteGui_ShowRegsXrg(G_Log, *State\LogAccum, *State)
EndProcedure

; Resolve o alvo do PROXIMO run do XGO a partir de *State\XgoStep (0=procura
; BP, 1=BP1, 2=BP2, 3=BP3, 4+=so' BPF dai em diante) - "se o breakpoint da
; vez (BP/BP1/BP2/BP3) nao estiver definido, cai pro BPF se este estiver
; definido; se nem um nem outro, roda livre" (pedido explicito do usuario,
; docs/SPEC.md modulo 45j). #True + *OutAddr\i preenchido quando ha alvo;
; #False quando o run desta vez deve ser "livre" (MamuteGui_XgoRunLoop
; abaixo decide o criterio de parada nesse caso).
Procedure.b MamuteGui_XgoResolveTarget(*State.MamuteGui_State, *OutAddr.Integer)
  Protected HasStep.b, StepAddr.u
  Select *State\XgoStep
    Case 0 : HasStep = *State\HasXgoBp  : StepAddr = *State\XgoBpAddr
    Case 1 : HasStep = *State\HasXgoBp1 : StepAddr = *State\XgoBp1Addr
    Case 2 : HasStep = *State\HasXgoBp2 : StepAddr = *State\XgoBp2Addr
    Case 3 : HasStep = *State\HasXgoBp3 : StepAddr = *State\XgoBp3Addr
  EndSelect

  If HasStep
    *OutAddr\i = StepAddr
    ProcedureReturn #True
  EndIf
  If *State\HasXgoBpF
    *OutAddr\i = *State\XgoBpFAddr
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

; Roda o motor Z80 simulado (Mz80_ExecuteOne, MamuteZ80Cpu.pbi - nucleo
; historicamente delicado, ver CLAUDE.md; NADA nele foi tocado por este
; comando, so' chamado em loop igual ao Mz80_Run ja existente) a partir do
; RegPC atual, ate a PRIMEIRA condicao que bater:
;  - HALT (mesmo texto do Mz80_Run/StepInto ja existentes).
;  - RegPC = TargetAddr, SE HasTarget (o breakpoint da vez, ja resolvido por
;    MamuteGui_XgoResolveTarget acima).
;  - "fim de programa": RegSP > EntrySP - o RET que devolve pra ALEM de onde
;    este run comecou (mesmo criterio exato do Mz80_StepOut ja existente,
;    MamuteZ80Cpu.pbi) - SO' quando HasTarget=#False (com um breakpoint
;    definido, um RET no meio do caminho NAO para a execucao; o alvo e' o
;    unico criterio - pedido explicito do usuario).
;  - ESC pressionado (ExamineKeyboard()/KeyboardPushed, checado a cada 2000
;    instrucoes - poll barato o bastante pra nao pesar no throughput) - SO'
;    quando HasTarget=#False, mesmo raciocinio do RET acima. A cada checagem
;    tambem chama WindowEvent() (nao-bloqueante) so' pra manter a janela
;    respondendo (nao "Nao esta respondendo") durante um run livre longo -
;    eventos porventura enfileirados nesse meio tempo (ex.: fechar a janela)
;    ficam pendentes ate este loop retornar, mesma limitacao de qualquer
;    operacao "modal" longa.
;  - Teto de seguranca (#Mz80_MaxStepBudget, MamuteZ80Cpu.pbi) - rede de
;    protecao final contra loop infinito sem HALT/RET/ESC (com HasTarget
;    tambem se aplica - um breakpoint que nunca e' alcancado nao pode travar
;    o monitor pra sempre).
; Devolve o texto de status pro log via RETORNO DIRETO da funcao, NAO
; *Ptr.String out-parameter - bug real documentado no CLAUDE.md (2026-08-12,
; "L"/"LP"): esse idioma crashava neste mesmo arquivo/unidade de compilacao.
Procedure.s MamuteGui_XgoRunLoop(*State.MamuteGui_State, HasTarget.b, TargetAddr.u)
  If *State\Halted
    ProcedureReturn "CPU HALTADA (HALT) EM " + Mamute_Hex4(*State\RegPC)
  EndIf

  Protected EntrySP.u = *State\RegSP
  Protected Steps.q = 0

  Repeat
    Mz80_ExecuteOne(*State)
    Steps + 1

    If *State\Halted
      ProcedureReturn "CPU HALTADA (HALT) EM " + Mamute_Hex4(*State\RegPC)
    EndIf

    If HasTarget
      If *State\RegPC = TargetAddr
        ProcedureReturn "PARADO NO BREAKPOINT (" + Mamute_Hex4(*State\RegPC) + ")"
      EndIf
    Else
      If *State\RegSP > EntrySP
        ProcedureReturn "PROGRAMA TERMINOU (RET NO TOPO DA PILHA) EM " + Mamute_Hex4(*State\RegPC)
      EndIf
      If (Steps % 2000) = 0
        ExamineKeyboard()
        If KeyboardPushed(#PB_Key_Escape)
          ProcedureReturn "INTERROMPIDO PELO USUARIO (ESC) EM " + Mamute_Hex4(*State\RegPC)
        EndIf
        WindowEvent()
      EndIf
    EndIf

    ; #Mz80_MaxStepBudget (MamuteZ80Cpu.pbi) nao pode ser referenciada aqui -
    ; aquele arquivo e' incluido DEPOIS deste em BadigEditor.pb (mesmo motivo
    ; do Declare de Mz80_ExecuteOne no topo do arquivo) - literal duplicado
    ; de proposito, mesmo valor usado por Mz80_Run/StepOver/StepOut.
    If Steps > 2000000
      ProcedureReturn "RUN INTERROMPIDO - LIMITE DE 2000000 INSTRUCOES ATINGIDO EM " + Mamute_Hex4(*State\RegPC)
    EndIf
  ForEver
EndProcedure

; XGO <endereco>[#<slot>] - porta do GO do SUPER-X (inventario do modulo 45:
; "Executa programa (para em breakpoint, ver RG BP)") - inicia (ou continua)
; a execucao do motor Z80 simulado (MamuteZ80Cpu.pbi, o MESMO nucleo do
; comando G/debugger grafico) a partir de <endereco> (ou de onde a ultima
; chamada parou, se <endereco> for omitido), mostrando os registradores
; (MamuteGui_ShowRegsXrg) no ponto onde parou. Pedido explicito do usuario -
; sequencia de ate 5 breakpoints nomeados (BP/BP1/BP2/BP3/BPF, editaveis via
; XRG, ver comentario la e MamuteGui_XgoResolveTarget acima):
;
;   XGO <endereco>  - COMECA do zero em <endereco> (reseta XgoStep pra 0 -
;                      alvo desta chamada = BP). <endereco> aceita
;                      "#<slot>" (troca IMPLICITAMENTE o slot PRIMARIO
;                      mapeado na PAGINA de <endereco>, mesmo efeito do
;                      comando PAGE, ANTES de rodar - decisao confirmada
;                      com o usuario, docs/SPEC.md modulo 45j) - "#V" (VRAM)
;                      ou um sub-slot explicito (`#slot-sub`) sao
;                      ?ERRO DE SINTAXE: o motor de execucao Z80 simulado
;                      (Mz80_ExecuteOne/Fetch8) so' le/escreve via
;                      Mamute_ReadByte/WriteByte (PAGE-relativo comum) -
;                      nunca honrou sub-slot/VRAM explicito como os
;                      comandos de MEMORIA (XD/XM/XA/XI, Mamute_SxReadByte)
;                      ja honram, e threadar um alvo por TODO opcode do
;                      nucleo (usado tambem por Step/Run/Trace) seria um
;                      risco de regressao grande demais pra este pedido.
;   XGO             - CONTINUA de RegPC (onde a ultima chamada parou), alvo
;                      = BP1 na 2a chamada, BP2 na 3a, BP3 na 4a, BPF dai em
;                      diante. So' valido depois de pelo menos um
;                      "XGO <endereco>" bem-sucedido nesta sessao da janela
;                      (mesmo idioma "sem argumento, continua" do L/M/S/XD -
;                      HasLastXgo) - senao, ?ERRO DE SINTAXE.
;
; Se o alvo da vez nao existir (MamuteGui_XgoResolveTarget = #False, nem o
; breakpoint da vez nem o BPF de fallback definidos), roda "livre": para em
; HALT, no RET que devolve pra alem da pilha de entrada, em ESC, ou no teto
; de seguranca - "se o usuario nao tiver BP algum, executa ate o fim (RET)
; ou ate ESC" (pedido explicito do usuario) - MamuteGui_XgoRunLoop acima.
Procedure MamuteGui_CmdXgo(G_Log, *State.MamuteGui_State, Args.s)
  Protected Trimmed.s = Trim(Args)

  If Trimmed <> ""
    Protected StartAddr.i
    Protected Target.MamuteSxTarget
    If Not Mamute_ParseSxAddr(Trimmed, @StartAddr, @Target)
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
    If Target\IsVram Or (Target\IsExplicit And Target\SubSlot <> 0)
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf

    If Target\IsExplicit
      Protected Pagina.i = (StartAddr >> 14) & 3
      MamutePageMap(Pagina) = Target\Slot
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
        "PAGE" + Str(Pagina) + "(" + Mamute_PageRangeText(Pagina) + ") SLOT " + Str(Target\Slot) + "-0")
    EndIf

    *State\RegPC = StartAddr & $FFFF
    *State\XgoStep = 0
    *State\HasLastXgo = #True
  Else
    If Not *State\HasLastXgo
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
  EndIf

  Protected TargetAddr.i
  Protected HasTarget.b = MamuteGui_XgoResolveTarget(*State, @TargetAddr)

  Protected StatusText.s = MamuteGui_XgoRunLoop(*State, HasTarget, TargetAddr & $FFFF)
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, StatusText)

  If *State\XgoStep < 4 : *State\XgoStep + 1 : EndIf

  *State\LogAccum = MamuteGui_ShowRegsXrg(G_Log, *State\LogAccum, *State)
EndProcedure

; Executa UMA instrucao a partir de RegPC (mesmo motor Z80 simulado do G/
; XGO/debugger - Mz80_ExecuteOne, MamuteZ80Cpu.pbi, NADA tocado) e mostra o
; endereco/bytes/mnemonico da instrucao que rodou mais os registradores
; principais (MamuteGui_ShowRegs - AF/BC/DE/HL/IX/IY/SP, mesmo formato
; compacto do comando X; sem os "secretos"/BP do XRG de proposito, pra nao
; encher o log demais numa sessao de trace de varios passos). Usado so' pelo
; XTR (MamuteGui_CmdXtr abaixo). ProcedureReturn #False quando a CPU haltou
; (o trace se encerra sozinho nesse caso, sem esperar ESC) - #True enquanto
; deve continuar aceitando ENTER.
Procedure.b MamuteGui_XtrStepAndShow(G_Log, *State.MamuteGui_State)
  If *State\Halted
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "CPU HALTADA (HALT) EM " + Mamute_Hex4(*State\RegPC))
    ProcedureReturn #False
  EndIf

  Protected InstrLen.i
  Protected Text.s = Mamute_DisasmOne(*State\RegPC, @InstrLen)
  If InstrLen < 1 : InstrLen = 1 : EndIf
  Protected HexBytes.s = "", i.i
  For i = 0 To InstrLen - 1
    If HexBytes <> "" : HexBytes + " " : EndIf
    HexBytes + Mamute_Hex2(Mamute_ReadByte(*State\RegPC + i))
  Next
  Protected Line.s = Mamute_Hex4(*State\RegPC) + "  " + LSet(HexBytes, 11, " ") + "  " + Text

  Mz80_ExecuteOne(*State)

  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, Line)
  *State\LogAccum = MamuteGui_ShowRegs(G_Log, *State\LogAccum, *State)

  If *State\Halted
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "CPU HALTADA (HALT) EM " + Mamute_Hex4(*State\RegPC))
    ProcedureReturn #False
  EndIf
  ProcedureReturn #True
EndProcedure

; XTR <endereco> - porta do TR do SUPER-X (inventario do modulo 45: "Trace
; passo a passo, imprime registradores a cada instrucao") - pedido explicito
; do usuario: comeca em <endereco>, executa a instrucao, mostra os
; registradores e FICA um loop modal proprio esperando ENTER (mais uma
; instrucao) ou ESC (interrompe). Nao aceita sufixo de slot/VRAM (mesmo
; escopo do TR original - so' um endereco puro) - se precisar rodar num slot
; especifico, troca a PAGE antes com o comando `PAGE` (ou usa `XGO
; <endereco>#<slot>` pra so' comecar la, mas XGO nao para a cada instrucao).
;
; Loop modal PROPRIO (WaitWindowEvent() aninhado dentro do dispatch) em vez
; de um flag de "modo trace" no loop principal de MamuteAssembler_OpenWindow
; - reaproveita o MESMO #MamuteGui_EnterShortcut que o campo de comando ja
; usa (ENTER sem nada de novo digitado no campo simplesmente nao aciona nada
; ali, entao nao ha conflito nenhum em interceptar o mesmo atalho aqui
; dentro enquanto o trace estiver rodando) mais o novo #MamuteGui_EscShortcut
; (registrado uma vez so' em MamuteAssembler_OpenWindow). Fechar a janela
; (Alt+F4/botao X) durante o trace marca ShouldQuit pra o loop PRINCIPAL
; tambem encerrar assim que este retornar.
Procedure MamuteGui_CmdXtr(G_Log, *State.MamuteGui_State, Args.s)
  Protected Trimmed.s = Trim(Args)
  Protected StartAddr.i
  If Not Mamute_ParseHexAddr(Trimmed, @StartAddr)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  *State\RegPC = StartAddr & $FFFF
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "TRACE EM " + Mamute_Hex4(*State\RegPC) + " - ENTER = PROXIMA INSTRUCAO, ESC = INTERROMPE")

  If Not MamuteGui_XtrStepAndShow(G_Log, *State)
    ProcedureReturn ; ja haltou no 1o passo - nem entra no loop modal
  EndIf

  Protected Ev, Quit.b = #False
  Repeat
    Ev = WaitWindowEvent()
    Select Ev
      Case #PB_Event_Menu
        Select EventMenu()
          Case #MamuteGui_EnterShortcut
            If Not MamuteGui_XtrStepAndShow(G_Log, *State)
              Quit = #True
            EndIf

          Case #MamuteGui_EscShortcut
            *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "TRACE INTERROMPIDO (ESC)")
            Quit = #True
        EndSelect

      Case #PB_Event_CloseWindow
        *State\ShouldQuit = #True
        Quit = #True
    EndSelect
  Until Quit
EndProcedure

; XSD <arquivo>,<inicio>[#slot[-sub]|#V|#S|#4|#5],<final>[,B|D|X] - porta do
; SD do SUPER-X (inventario do modulo 45: "Super disassembler: disassembly
; pra arquivo texto, ou exporta bytes crus como DEFB/DATA/inline X-BASIC") -
; pedido explicito do usuario. Puramente LEITURA de memoria (Mamute_
; SxReadByte/Mamute_DisasmOne, mesmo *Target opcional que XD/XM/XA/XI ja
; usam desde os modulos 45b/45i) - honra slot/sub-slot/VRAM completo, SEM a
; limitacao do XGO (que so' honra slot primario porque PRECISA executar
; contra memoria mapeada de verdade; aqui e' so' leitura, nao ha esse
; problema).
;
; SEM modo (`,B`/`,D`/`,X` omitido) - **listagem assembly de verdade**, uma
; instrucao decodificada por linha (Mamute_DisasmOne, sem coluna de
; endereco/bytes - diferente do XI, que salva pra LEITURA humana; aqui e'
; pra REALIMENTAR um compilador Z80 externo), com um `ORG <inicio>H` no
; topo (necessario pra montar de volta nos enderecos certos - sem isso as
; instrucoes com operando absoluto continuariam corretas, mas o proprio
; posicionamento do bloco ficaria errado).
;
; `,B`/`,D`/`,X` - **exportacao de bytes CRUS** (ignora fronteiras de
; instrucao de proposito - 8 bytes fixos por linha, pedido explicito do
; usuario), em vez de disassembly:
;   B - `DEFB xxH,xxH,...` (sintaxe Z80 assembler, 8 bytes por linha).
;   D - `<linha> DATA &Hxx,&Hxx,...` (BASIC, 8 bytes por linha, `<linha>`
;       comecando em 10000 e subindo de 10 em 10) - **"&H" obrigatorio**:
;       sem ele nao seria hexadecimal NENHUM pro interpretador BASIC (viraria
;       decimal ou erro de sintaxe) - "sempre no formato hexadecimal" (pedido
;       do usuario) so' e' verdade com o prefixo. Ganha uma linha extra no
;       final com o loop pra reler e gravar: `<linha> FOR I=&H<inicio> TO
;       &H<final>:READ A:POKE I,A:NEXT I` (pedido explicito do usuario -
;       "ja coloque no final as linhas para ler os DATA e dar poke... for,
;       read, poke, next"). **Rejeita VRAM** (`?ERRO DE SINTAXE`) - o loop
;       gerado faz `POKE` (memoria comum), que nao tem o menor sentido pros
;       MESMOS numeros de endereco se a origem for VRAM (precisaria de
;       `VPOKE`, fora de escopo aqui).
;   X - `<linha> '#&Hxx,&Hxx,...` (formato de dados embutidos do X-BASIC -
;       linha comecando com `'#`, sem virgula antes do 1o valor - o proprio
;       X-BASIC ja sabe carregar isso sozinho, sem loop `FOR/READ/POKE`
;       nenhum, diferente do `D`).
;
; **Sempre abre o dialogo "Salvar como"** sugerindo `<arquivo>` como nome
; (pedido explicito do usuario - diferente do XI, que grava direto sem
; dialogo) - extensao sugerida `.asm` (sem modo/`B`) ou `.bas` (`D`/`X`) se
; `<arquivo>` nao tiver nenhuma. Cancelar o dialogo = "CANCELADO", sem gravar
; nada (mesmo idioma do `?XD`/`?XI`, modulo 45i).
Procedure MamuteGui_CmdXsd(G_Log, *State.MamuteGui_State, Args.s)
  Protected CommaPos1.i = FindString(Args, ",")
  If CommaPos1 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected FileToken.s = Trim(Left(Args, CommaPos1 - 1))
  Protected Rest1.s = Mid(Args, CommaPos1 + 1)

  Protected CommaPos2.i = FindString(Rest1, ",")
  If FileToken = "" Or CommaPos2 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected StartToken.s = Trim(Left(Rest1, CommaPos2 - 1))
  Protected Rest2.s = Mid(Rest1, CommaPos2 + 1)

  Protected EndToken.s, ModeToken.s = ""
  Protected CommaPos3.i = FindString(Rest2, ",")
  If CommaPos3 = 0
    EndToken = Trim(Rest2)
  Else
    EndToken = Trim(Left(Rest2, CommaPos3 - 1))
    ModeToken = UCase(Trim(Mid(Rest2, CommaPos3 + 1)))
    If FindString(ModeToken, ",") > 0 Or (ModeToken <> "B" And ModeToken <> "D" And ModeToken <> "X")
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
  EndIf

  Protected StartAddr.i, EndAddr.i
  Protected Target.MamuteSxTarget
  If Not Mamute_ParseSxAddr(StartToken, @StartAddr, @Target)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  If ModeToken = "D" And Target\IsVram
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected EndOk.b
  If Target\IsVram
    EndOk = Mamute_ParseVramAddr(EndToken, @EndAddr)
  Else
    EndOk = Mamute_ParseHexAddr(EndToken, @EndAddr)
  EndIf
  If Not EndOk Or EndAddr < StartAddr
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected DefaultExt.s = ".asm"
  Protected Pattern.s = "Fonte Z80 (*.asm)|*.asm|Todos os arquivos (*.*)|*.*"
  If ModeToken = "D" Or ModeToken = "X"
    DefaultExt = ".bas"
    Pattern = "Listagem BASIC (*.bas)|*.bas|Todos os arquivos (*.*)|*.*"
  EndIf

  Protected FilePath.s = SaveFileRequester("Salvar listagem (XSD) como", FileToken, Pattern, 0)
  If FilePath = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "CANCELADO")
    ProcedureReturn
  EndIf
  If GetExtensionPart(FilePath) = ""
    FilePath + DefaultExt
  EndIf

  Protected NewList Lines.s()
  Protected Addr.i, Count.i, LineText.s

  Select ModeToken
    Case "B"
      Addr = StartAddr
      While Addr <= EndAddr
        LineText = "DEFB "
        Count = 0
        While Addr <= EndAddr And Count < 8
          If Count > 0 : LineText + "," : EndIf
          LineText + Mamute_Hex2(Mamute_SxReadByte(Addr, @Target)) + "H"
          Addr + 1 : Count + 1
        Wend
        AddElement(Lines()) : Lines() = LineText
      Wend

    Case "D"
      Protected LineNum.i = 10000
      Addr = StartAddr
      While Addr <= EndAddr
        LineText = Str(LineNum) + " DATA "
        Count = 0
        While Addr <= EndAddr And Count < 8
          If Count > 0 : LineText + "," : EndIf
          LineText + "&H" + Mamute_Hex2(Mamute_SxReadByte(Addr, @Target))
          Addr + 1 : Count + 1
        Wend
        AddElement(Lines()) : Lines() = LineText
        LineNum + 10
      Wend
      AddElement(Lines())
      Lines() = Str(LineNum) + " FOR I=&H" + Mamute_Hex4(StartAddr) + " TO &H" + Mamute_Hex4(EndAddr) +
                 ":READ A:POKE I,A:NEXT I"

    Case "X"
      Protected LineNumX.i = 10000
      Addr = StartAddr
      While Addr <= EndAddr
        LineText = Str(LineNumX) + " '#"
        Count = 0
        While Addr <= EndAddr And Count < 8
          If Count > 0 : LineText + "," : EndIf
          LineText + "&H" + Mamute_Hex2(Mamute_SxReadByte(Addr, @Target))
          Addr + 1 : Count + 1
        Wend
        AddElement(Lines()) : Lines() = LineText
        LineNumX + 10
      Wend

    Default ; sem modo - listagem assembly (Mamute_DisasmOne, sem coluna de endereco/bytes)
      AddElement(Lines()) : Lines() = "        ORG " + Mamute_Hex4(StartAddr) + "H"
      Protected CurAddr.i = StartAddr
      Protected InstrLen.i
      Repeat
        If CurAddr > EndAddr : Break : EndIf
        Protected Text.s = Mamute_DisasmOne(CurAddr, @InstrLen, @Target)
        If InstrLen < 1 : InstrLen = 1 : EndIf
        AddElement(Lines()) : Lines() = "        " + Text
        CurAddr + InstrLen
      ForEver
  EndSelect

  If Mamute_SaveTextListing(FilePath, Lines())
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "GRAVADO: " + GetFilePart(FilePath))
  Else
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO AO GRAVAR ARQUIVO")
  EndIf
EndProcedure

; Deslocamento com sinal de ate 4 digitos hexa (+-0000..FFFF) - usado so'
; pelo <offset> do XSV/XLD abaixo. NAO reaproveita Mamute_ParseHexOffset()
; (MamuteSupport.pbi, comando XI) de proposito: aquela funcao e' limitada a
; -7Fh..80h (deslocamento de 1 BYTE, pensado pra "nudge" de disassembler) -
; deslocar um ENDERECO de 16 bits (relocar 8000H pra C000H, por exemplo)
; precisa de alcance bem maior.
Procedure.b Mamute_ParseAddrOffset(Token.s, *OutValue.Integer)
  If Token = ""
    ProcedureReturn #False
  EndIf
  Protected Sign.i = 1
  Protected Digits.s = Token
  If Left(Token, 1) = "+"
    Digits = Mid(Token, 2)
  ElseIf Left(Token, 1) = "-"
    Sign = -1
    Digits = Mid(Token, 2)
  EndIf
  If Not Mamute_IsHexString(Digits, 4)
    ProcedureReturn #False
  EndIf
  *OutValue\i = Sign * Val("$" + Digits)
  ProcedureReturn #True
EndProcedure

; XSV <nome>,<inicio>[#slot[-subslot]|#S|#5],<fim>[,<execucao>[,<offset>]]
; - porta do SV do SUPER-X (inventario do modulo 45: "Salva com cabecalho
; BSAVE") - pedido explicito do usuario: "funciona exatamente igual ao
; BSAVE do BASIC, abrindo o dialogo para o usuario informar o nome do
; arquivo (sugerido por <nome>)". Cabecalho BSAVE real do MSX (7 bytes:
; $FE + inicio/fim/execucao, cada um 2 bytes little-endian) - MESMO formato
; que o "BIN" do SAVE nativo (MamuteSaveGui.pbi) ja grava, mas NAO
; reaproveita aquela janela (rica, com Slot/Formato/sem-cabecalho editaveis
; - pra outro caso de uso, "grava o que estiver mapeado agora"): aqui e'
; so' um SaveFileRequester direto sugerindo <nome> (mesmo idioma do XSD,
; modulo 45m - "abrindo o dialogo" pro usuario e' o FILE PICKER, nao uma
; janela de edicao inteira) - decisao de manter os dois caminhos
; separados, sem risco de mexer no SAVE/"A I" ja funcionando.
;
; <inicio> aceita o sufixo de alvo completo (slot/sub-slot/#S/#5) EXCETO
; VRAM (#V/#4) - ?ERRO DE SINTAXE se vier: BSAVE de verdade no MSX NUNCA
; salva de VRAM (precisaria de VPEEK, formato/uso completamente diferente),
; entao aceitar VRAM aqui quebraria a promessa de "exatamente igual ao
; BSAVE do BASIC". <fim> e' sempre um endereco puro, no MESMO alvo -
; mesma convencao do XBT/XRT/XFL/XCM/XFD/XTS.
;
; <execucao> vazio = igual a <inicio> (MESMA regra do BSAVE original e do
; SAVE nativo). <offset>, quando informado, desloca so' os 3 ENDERECOS
; GRAVADOS NO CABECALHO (inicio/fim/execucao) - os BYTES continuam lidos
; do intervalo [<inicio>,<fim>] de verdade no simulador. **Decisao pra uma
; ambiguidade real do pedido do usuario, documentada em docs/SPEC.md
; modulo 45u**: util pra montar/testar codigo num endereco de trabalho
; aqui no monitor e gerar um arquivo .bin que declara um endereco de
; carga DIFERENTE (o endereco real de destino), pra depois carregar de
; volta com XLD (ou BLOAD de verdade) no lugar certo.
Procedure MamuteGui_CmdXsv(G_Log, *State.MamuteGui_State, Args.s)
  Protected CommaPos1.i = FindString(Args, ",")
  If CommaPos1 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected NameToken.s = Trim(Left(Args, CommaPos1 - 1))
  Protected Rest1.s = Mid(Args, CommaPos1 + 1)
  If NameToken = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected CommaPos2.i = FindString(Rest1, ",")
  If CommaPos2 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected StartToken.s = Trim(Left(Rest1, CommaPos2 - 1))
  Protected Rest2.s = Mid(Rest1, CommaPos2 + 1)

  Protected EndToken.s, ExecToken.s = "", OffsetToken.s = ""
  Protected CommaPos3.i = FindString(Rest2, ",")
  If CommaPos3 = 0
    EndToken = Trim(Rest2)
  Else
    EndToken = Trim(Left(Rest2, CommaPos3 - 1))
    Protected Rest3.s = Mid(Rest2, CommaPos3 + 1)
    Protected CommaPos4.i = FindString(Rest3, ",")
    If CommaPos4 = 0
      ExecToken = Trim(Rest3)
    Else
      ExecToken = Trim(Left(Rest3, CommaPos4 - 1))
      OffsetToken = Trim(Mid(Rest3, CommaPos4 + 1))
      If FindString(OffsetToken, ",") > 0
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
        ProcedureReturn
      EndIf
    EndIf
  EndIf

  Protected StartAddr.i, EndAddr.i, ExecAddr.i, OffsetVal.i = 0
  Protected Target.MamuteSxTarget
  If Not Mamute_ParseSxAddr(StartToken, @StartAddr, @Target) Or Target\IsVram
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  If Not Mamute_ParseHexAddr(EndToken, @EndAddr) Or EndAddr < StartAddr
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  If ExecToken = ""
    ExecAddr = StartAddr
  ElseIf Not Mamute_ParseHexAddr(ExecToken, @ExecAddr)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  If OffsetToken <> "" And Not Mamute_ParseAddrOffset(OffsetToken, @OffsetVal)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected FilePath.s = SaveFileRequester("Salvar como BSAVE (XSV)", NameToken,
    "Binario BSAVE (*.bin)|*.bin|Todos os arquivos (*.*)|*.*", 0)
  If FilePath = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "CANCELADO")
    ProcedureReturn
  EndIf
  If GetExtensionPart(FilePath) = "" : FilePath + ".bin" : EndIf

  Protected DataLen.i = EndAddr - StartAddr + 1
  Protected Dim Buf.a(6 + DataLen - 1)
  Protected HStart.u = (StartAddr + OffsetVal) & $FFFF
  Protected HEndAddr.u = (EndAddr + OffsetVal) & $FFFF
  Protected HExec.u = (ExecAddr + OffsetVal) & $FFFF
  Buf(0) = $FE
  Buf(1) = HStart & $FF    : Buf(2) = (HStart >> 8) & $FF
  Buf(3) = HEndAddr & $FF  : Buf(4) = (HEndAddr >> 8) & $FF
  Buf(5) = HExec & $FF     : Buf(6) = (HExec >> 8) & $FF

  Protected i.i
  For i = 0 To DataLen - 1
    Buf(7 + i) = Mamute_SxReadByte(StartAddr + i, @Target)
  Next

  Protected Fh = CreateFile(#PB_Any, FilePath)
  If Not Fh
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO AO GRAVAR ARQUIVO")
    ProcedureReturn
  EndIf
  WriteData(Fh, @Buf(0), 7 + DataLen)
  CloseFile(Fh)

  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "GRAVADO: " + GetFilePart(FilePath) + " (" + Mamute_Hex4(HStart) + "-" + Mamute_Hex4(HEndAddr) +
    " EXEC " + Mamute_Hex4(HExec) + ")")
EndProcedure

; XLD <nome>[,<offset>[#slot[-subslot]|#S|#5]] - porta do LD do SUPER-X
; (inventario do modulo 45: "Carrega com cabecalho BLOAD") - pedido
; explicito do usuario: "cria o XLD <name>[,<offset>#<slot>-<subslot>], que
; abre o dialogo para buscar um arquivo, sugerido pelo nome, e com um
; offset opcional". Le o cabecalho BSAVE real (7 bytes: $FE + inicio/fim/
; execucao, little-endian) - ?ARQUIVO INVALIDO se o 1o byte nao for $FE
; (mesma exigencia do BLOAD de verdade do MSX).
;
; <offset> ausente - carrega no MESMO endereco que o cabecalho ja diz
; (<inicio> gravado no arquivo), PAGE-relativo comum (mesmo comportamento
; "sem sufixo cai no PAGE ativo" de todo o resto do modulo 45). <offset>
; presente - ignora o endereco do cabecalho pra fins de ESCRITA, carrega
; a partir de <offset> (aceita o MESMO sufixo de alvo do XSV, tambem
; rejeitando VRAM - BLOAD de verdade tambem nunca escreve em VRAM direto).
; Endereco de execucao do cabecalho so' e' MOSTRADO no log - XLD nunca
; executa nada sozinho (equivalente ao BLOAD SEM ",R"; rodar fica por conta
; de XGO depois, se o usuario quiser).
Procedure MamuteGui_CmdXld(G_Log, *State.MamuteGui_State, Args.s)
  Protected Trimmed.s = Trim(Args)
  If Trimmed = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected CommaPos.i = FindString(Trimmed, ",")
  Protected NameToken.s, OffsetToken.s = ""
  If CommaPos = 0
    NameToken = Trimmed
  Else
    NameToken = Trim(Left(Trimmed, CommaPos - 1))
    OffsetToken = Trim(Mid(Trimmed, CommaPos + 1))
    If FindString(OffsetToken, ",") > 0
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
  EndIf
  If NameToken = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected HasOffset.b = Bool(OffsetToken <> "")
  Protected OffsetAddr.i
  Protected OffsetTarget.MamuteSxTarget
  If HasOffset
    If Not Mamute_ParseSxAddr(OffsetToken, @OffsetAddr, @OffsetTarget) Or OffsetTarget\IsVram
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
  EndIf

  Protected FilePath.s = OpenFileRequester("Selecione o arquivo BSAVE (XLD)", NameToken,
    "Binario BSAVE (*.bin)|*.bin|Todos os arquivos (*.*)|*.*", 0)
  If FilePath = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "CANCELADO")
    ProcedureReturn
  EndIf

  Protected Fh = ReadFile(#PB_Any, FilePath)
  If Not Fh
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ARQUIVO INVALIDO")
    ProcedureReturn
  EndIf
  Protected FileLen.q = Lof(Fh)
  If FileLen < 7
    CloseFile(Fh)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ARQUIVO INVALIDO")
    ProcedureReturn
  EndIf

  Protected Dim Hdr.a(6)
  ReadData(Fh, @Hdr(0), 7)
  If Hdr(0) <> $FE
    CloseFile(Fh)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ARQUIVO INVALIDO")
    ProcedureReturn
  EndIf
  Protected HStart.u = Hdr(1) | (Hdr(2) << 8)
  Protected HEndAddr.u = Hdr(3) | (Hdr(4) << 8)
  Protected HExec.u = Hdr(5) | (Hdr(6) << 8)

  Protected DataLen.i = HEndAddr - HStart + 1
  If DataLen < 0 : DataLen = 0 : EndIf
  Protected AvailBytes.q = FileLen - 7
  If DataLen > AvailBytes : DataLen = AvailBytes : EndIf

  Protected Dim DataBuf.a(DataLen)
  If DataLen > 0 : ReadData(Fh, @DataBuf(0), DataLen) : EndIf
  CloseFile(Fh)

  Protected WriteAddr.i
  Protected Target.MamuteSxTarget
  If HasOffset
    WriteAddr = OffsetAddr
    CopyStructure(@OffsetTarget, @Target, MamuteSxTarget)
  Else
    WriteAddr = HStart
  EndIf

  Protected i.i
  For i = 0 To DataLen - 1
    Mamute_SxWriteByte((WriteAddr + i) & $FFFF, DataBuf(i), @Target)
  Next

  Protected EndWriteAddr.u = (WriteAddr + DataLen - 1) & $FFFF
  If DataLen = 0 : EndWriteAddr = WriteAddr & $FFFF : EndIf
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "CARREGADO: " + GetFilePart(FilePath) + " EM " + Mamute_Hex4(WriteAddr & $FFFF) + "-" +
    Mamute_Hex4(EndWriteAddr) + " (EXEC " + Mamute_Hex4(HExec) + ")")
EndProcedure

; XIM <endereco>,<slot>,<tipo>,<texto> - porta do iM (Input Memo) do
; SUPER-X (funcao "Note" da doc original) - adiciona uma nota nova em
; MamuteNotes(), em memoria (so' persiste em disco via XIS depois). Pedido
; explicito do usuario: "porte estes comandos" (iM/iC/iL/iS), respondendo
; ao pedido anterior de poder "consultar um endereco" a partir de um
; arquivo de notas (docs/SPEC.md modulo 45x).
;
; <endereco> hexa 1-4 digitos. <slot>/<tipo> sao os codigos NUMERICOS
; PROPRIOS do SUPER-X (0-4 e 0-7, ver cabecalho de MamuteNotesData.pbi) -
; nao o #slot-subslot do enderecamento estendido do resto do modulo 45,
; essas duas coisas so' coincidem de nome (mesma ressalva ja documentada
; no parser do .TNK original). <texto> e' TUDO que sobra depois da 3a
; virgula (pode conter espacos e qualquer pontuacao, exceto ";" que a
; gravacao do XIS troca por "," se aparecer - mesma sanitizacao do
; Mamute_SaveTranslatedNotes()).
Procedure MamuteGui_CmdXim(G_Log, *State.MamuteGui_State, Args.s)
  Protected CommaPos1.i = FindString(Args, ",")
  If CommaPos1 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected AddrToken.s = Trim(Left(Args, CommaPos1 - 1))
  Protected Rest1.s = Mid(Args, CommaPos1 + 1)

  Protected CommaPos2.i = FindString(Rest1, ",")
  If CommaPos2 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected SlotToken.s = Trim(Left(Rest1, CommaPos2 - 1))
  Protected Rest2.s = Mid(Rest1, CommaPos2 + 1)

  Protected CommaPos3.i = FindString(Rest2, ",")
  If CommaPos3 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected TypeToken.s = Trim(Left(Rest2, CommaPos3 - 1))
  Protected TextToken.s = Trim(Mid(Rest2, CommaPos3 + 1))

  Protected Addr.i
  If Not Mamute_ParseHexAddr(AddrToken, @Addr)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  If Not Mamute_IsDecimalString(SlotToken) Or Val(SlotToken) < 0 Or Val(SlotToken) > 4
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  If Not Mamute_IsDecimalString(TypeToken) Or Val(TypeToken) < 0 Or Val(TypeToken) > 7
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  If TextToken = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  AddElement(MamuteNotes())
  MamuteNotes()\Addr = Addr
  MamuteNotes()\SlotData = Val(SlotToken)
  MamuteNotes()\TypeData = Val(TypeToken)
  MamuteNotes()\Text = TextToken

  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "NOTA ADICIONADA EM " + Mamute_Hex4(Addr) + " (" + Str(ListSize(MamuteNotes())) + " NA MEMORIA)")
EndProcedure

; XIC <endereco> - porta do iC (Input Check/Consult) do SUPER-X - consulta
; nota(s) gravada(s) pra um endereco em MamuteNotes(). Pode haver MAIS DE
; UMA nota no mesmo endereco (17 casos reais confirmados nas 471 notas
; originais - coincidencias numericas entre BIOS/PORT, ou SUB-ROM vs
; ROM principal, ver docs/SPEC.md modulo 45x) - XIC mostra TODAS, uma
; linha de log por nota, em vez de só a primeira.
Procedure MamuteGui_CmdXic(G_Log, *State.MamuteGui_State, Args.s)
  Protected Trimmed.s = Trim(Args)
  Protected Addr.i
  If Not Mamute_ParseHexAddr(Trimmed, @Addr)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected Found.b = #False
  ForEach MamuteNotes()
    If MamuteNotes()\Addr = Addr
      Found = #True
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
        Mamute_Hex4(Addr) + " [" + Mamute_NoteSlotName(MamuteNotes()\SlotData) + "/" +
        Mamute_NoteTypeName(MamuteNotes()\TypeData) + "] " + MamuteNotes()\Text)
    EndIf
  Next
  If Not Found
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?NOTA NAO ENCONTRADA")
  EndIf
EndProcedure

; XIL [<nome>] - porta do iL (Input Load) do SUPER-X - carrega um arquivo
; de notas pra MamuteNotes() (ClearList antes, substitui o que tinha).
; Abre SEMPRE o dialogo "Selecione o arquivo" (mesmo idioma do resto do
; modulo 45) - <nome>, se informado, so' entra como sugestao inicial do
; dialogo, exatamente como o <nome> do XLD/XL#.
;
; A sugestao PADRAO (sem <nome>) e' o arquivo TRADUZIDO que o Paleobasic ja
; traz pronto (Mamute_TranslatedNotesFilePath(), resource/superx/
; SUPER-X-PT.notas) - NUNCA o SUPER-X.TNK original em japones (que nem
; segue este formato de texto, so' o binario Shift-JIS de 64 bytes/registro
; lido por Mamute_LoadNoteFile(), dormant). Pedido explicito do usuario:
; "assegure-se de ler o arquivo ja traduzido de notas e nao o original em
; japones" - por isso XIL usa Mamute_LoadTranslatedNotes() e nunca
; Mamute_LoadNoteFile() (docs/SPEC.md modulo 45x).
Procedure MamuteGui_CmdXil(G_Log, *State.MamuteGui_State, Args.s)
  Protected NameToken.s = Trim(Args)
  If NameToken = ""
    NameToken = Mamute_TranslatedNotesFilePath()
  EndIf

  Protected FilePath.s = OpenFileRequester("Selecione o arquivo de notas (XIL)", NameToken,
    "Notas traduzidas (*.notas)|*.notas|Todos os arquivos (*.*)|*.*", 0)
  If FilePath = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "CANCELADO")
    ProcedureReturn
  EndIf

  If Not Mamute_LoadTranslatedNotes(FilePath)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ARQUIVO INVALIDO")
    ProcedureReturn
  EndIf

  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "CARREGADO: " + GetFilePart(FilePath) + " (" + Str(ListSize(MamuteNotes())) + " NOTAS)")
EndProcedure

; XIS <nome> - porta do iS (Input Save) do SUPER-X - grava MamuteNotes()
; (o que estiver em memoria agora - carregado via XIL + o que foi
; adicionado via XIM) no mesmo formato texto traduzido do XIL. <nome> e'
; so' a sugestao inicial do dialogo "Salvar como" (mesmo idioma do XSV).
Procedure MamuteGui_CmdXis(G_Log, *State.MamuteGui_State, Args.s)
  Protected NameToken.s = Trim(Args)
  If NameToken = ""
    NameToken = Mamute_TranslatedNotesFilePath()
  EndIf

  Protected FilePath.s = SaveFileRequester("Salvar arquivo de notas (XIS)", NameToken,
    "Notas traduzidas (*.notas)|*.notas|Todos os arquivos (*.*)|*.*", 0)
  If FilePath = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "CANCELADO")
    ProcedureReturn
  EndIf
  If GetExtensionPart(FilePath) = "" : FilePath + ".notas" : EndIf

  If Not Mamute_SaveTranslatedNotes(FilePath)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO AO GRAVAR ARQUIVO")
    ProcedureReturn
  EndIf

  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "GRAVADO: " + GetFilePart(FilePath) + " (" + Str(ListSize(MamuteNotes())) + " NOTAS)")
EndProcedure

; XIR [<endereco>] - visualizador interativo das notas em memoria
; (MamuteXirGui.pbi) - pedido explicito do usuario: "faca um comando XIR
; que abre uma janela e mostra o conteudo das notas, uma por uma, permite
; rolar com botoes, e permite busca com case, sem case e expressao
; regular" (docs/SPEC.md modulo 45z). <endereco>, se informado, abre ja'
; na primeira nota daquele endereco (sem exigir que exista - cai na
; primeira nota da lista se nao encontrar); sem argumento, sempre abre na
; primeira nota. <endereco> e' hexa simples (Mamute_ParseHexAddr, mesma
; validacao do XIC) - notas nao tem conceito de slot/sub-slot/VRAM, entao
; nao usa Mamute_ParseSxAddr como XM/XH/etc.
Procedure MamuteGui_CmdXir(Win, G_Log, *State.MamuteGui_State, Args.s)
  Protected Trimmed.s = Trim(Args)
  Protected InitialAddr.i = -1
  If Trimmed <> ""
    Protected Addr.i
    If Not Mamute_ParseHexAddr(Trimmed, @Addr)
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
    InitialAddr = Addr
  EndIf
  MamuteXir_Open(Win, InitialAddr)
EndProcedure

; XPP - abre o Painel de Portas I/O (MamuteIoGui.pbi) - pedido explicito do
; usuario: "um painel onde colocamos algumas portas que desejamos
; monitorar... com botoes o usuario pode incluir ou excluir portas... as
; portas que sofrem alteracao podem mudar de cor" (docs/SPEC.md modulo
; 46). Nome escolhido pra ABRIR o painel - o usuario so' pediu XPI/XPO
; explicitamente (os comandos de ler/escrever uma porta), o comando de
; abrir a janela do painel em si precisava de algum nome; "PP" = Painel de
; Portas, mesmo prefixo X e mesma dupla de letras de contexto I/O das
; outras duas.
Procedure MamuteGui_CmdXpp(Win, G_Log, *State.MamuteGui_State, Args.s)
  MamuteIoPanel_Open(Win)
EndProcedure

; XPI <porta> - porta do "leia um byte da porta e mostre no prompt"
; pedido explicito do usuario: "XPI <port> que le um dado da porta <port>
; e mostra no prompt". Simula manualmente a instrucao IN do Z80: le
; "Saida" da porta no Painel de Portas I/O (Mamute_IOPort_GetSaida,
; MamuteIoGui.pbi - mesma funcao que as instrucoes IN de verdade
; MamuteZ80Cpu.pbi usam durante XGO/XTR), criando a porta no painel se
; ainda nao existir (pedido explicito: "se a porta ainda nao aparece no
; painel de portas, crie a mesma"). Nao marca a porta como alterada -
; ler nao e' "sofrer modificacao".
Procedure MamuteGui_CmdXpi(G_Log, *State.MamuteGui_State, Args.s)
  Protected Trimmed.s = Trim(Args)
  If Not Mamute_IsHexString(Trimmed, 2)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected PortVal.i = Val("$" + Trimmed)
  Protected ValueRead.a = Mamute_IOPort_GetSaida(PortVal)
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "PORTA " + Mamute_Hex2(PortVal) + " = " + Mamute_Hex2(ValueRead))
EndProcedure

; XPO <porta>,<byte> - "escreva um byte na porta especificada" pedido
; explicito do usuario: "XPO <porta><byte> que permite escrever o <byte>
; na <porta> especificada" (virgula entre os dois argumentos - mesma
; convencao de 2 argumentos do resto do modulo 45, ex. XRG <reg>,<valor>).
; Simula manualmente a instrucao OUT do Z80: grava "Entrada" da porta no
; Painel de Portas I/O (Mamute_IOPort_SetEntrada - mesma funcao que as
; instrucoes OUT de verdade usam), criando a porta no painel se ainda nao
; existir e marcando-a como alterada (mesmo efeito que uma OUT de verdade
; do programa simulado teria).
Procedure MamuteGui_CmdXpo(G_Log, *State.MamuteGui_State, Args.s)
  Protected CommaPos.i = FindString(Args, ",")
  If CommaPos = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected PortToken.s = Trim(Left(Args, CommaPos - 1))
  Protected ByteToken.s = Trim(Mid(Args, CommaPos + 1))
  If Not Mamute_IsHexString(PortToken, 2) Or Not Mamute_IsHexString(ByteToken, 2)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected PortVal.i = Val("$" + PortToken)
  Protected ByteVal.a = Val("$" + ByteToken)
  Mamute_IOPort_SetEntrada(PortVal, ByteVal)

  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "PORTA " + Mamute_Hex2(PortVal) + " <- " + Mamute_Hex2(ByteVal))
EndProcedure

; XS# <nome>,<inicio>[#slot[-sub]|#V|#S],<fim> - porta do S# do SUPER-X
; (inventario do modulo 45: "Salva bytes crus, sem cabecalho") - pedido
; explicito do usuario: "salva um bloco bruto de dados no disco, abre o
; dialogo sugerindo o <nome>... salva os dados brutos do <inicio> ao <fim>
; sem header binario ou de outro tipo". Batizado XS# (nao S#) - decisao
; explicita do usuario apos pergunta direta, mesma consistencia de prefixo
; de todo o resto dos comandos portados do SUPER-X nesta sessao (mesmo
; raciocinio do CO->XCO, modulo 45n).
;
; Ao contrario do XSV/XLD (BSAVE/BLOAD DE VERDADE, que rejeitam VRAM pra
; ficar fiel ao hardware real - modulo 45u), XS#/XL# sao um dump/restore
; CRU generico sem pretensao de imitar nenhum formato de arquivo do MSX de
; verdade - aceitam VRAM tambem (`#V`/`#4`), mesmo escopo de alvo completo
; que o XSD (modulo 45m) ja usa. Zero cabecalho, literalmente so' os bytes
; do intervalo, byte a byte - mais simples que o XSV de proposito.
Procedure MamuteGui_CmdXsRaw(G_Log, *State.MamuteGui_State, Args.s)
  Protected CommaPos1.i = FindString(Args, ",")
  If CommaPos1 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected NameToken.s = Trim(Left(Args, CommaPos1 - 1))
  Protected Rest1.s = Mid(Args, CommaPos1 + 1)
  If NameToken = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected CommaPos2.i = FindString(Rest1, ",")
  If CommaPos2 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected StartToken.s = Trim(Left(Rest1, CommaPos2 - 1))
  Protected EndToken.s = Trim(Mid(Rest1, CommaPos2 + 1))
  If FindString(EndToken, ",") > 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected StartAddr.i, EndAddr.i
  Protected Target.MamuteSxTarget
  If Not Mamute_ParseSxAddr(StartToken, @StartAddr, @Target)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected EndOk.b
  If Target\IsVram
    EndOk = Mamute_ParseVramAddr(EndToken, @EndAddr)
  Else
    EndOk = Mamute_ParseHexAddr(EndToken, @EndAddr)
  EndIf
  If Not EndOk Or EndAddr < StartAddr
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected FilePath.s = SaveFileRequester("Salvar bytes crus (XS#)", NameToken,
    "Binario cru (*.bin)|*.bin|Todos os arquivos (*.*)|*.*", 0)
  If FilePath = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "CANCELADO")
    ProcedureReturn
  EndIf
  If GetExtensionPart(FilePath) = "" : FilePath + ".bin" : EndIf

  Protected DataLen.i = EndAddr - StartAddr + 1
  Protected Dim Buf.a(DataLen - 1)
  Protected i.i
  For i = 0 To DataLen - 1
    Buf(i) = Mamute_SxReadByte(StartAddr + i, @Target)
  Next

  Protected Fh = CreateFile(#PB_Any, FilePath)
  If Not Fh
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO AO GRAVAR ARQUIVO")
    ProcedureReturn
  EndIf
  WriteData(Fh, @Buf(0), DataLen)
  CloseFile(Fh)

  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "GRAVADO: " + GetFilePart(FilePath) + " (" + Mamute_HexPad(StartAddr, 4) + Mamute_SxTargetSuffixText(@Target) +
    "-" + Mamute_HexPad(EndAddr, 4) + " - " + Str(DataLen) + " BYTE(S))")
EndProcedure

; XL# <nome>,<inicio>[#slot[-sub]|#V|#S] - porta do L# do SUPER-X
; (inventario do modulo 45: "Carrega bytes crus, sem cabecalho") - analogo
; do XS# acima, pedido explicito do usuario ("crie tambem o analogo L# que
; carrega dados brutos do disco"). Sem <fim> (mesma sintaxe do L# original)
; - o tamanho vem do proprio arquivo (Lof()), carrega ele INTEIRO a partir
; de <inicio>. Rejeita overflow do alvo (StartAddr+tamanho-1 > Mamute_
; SxMaxAddr()) como ?ERRO DE SINTAXE em vez de dar a volta - mesma
; convencao do XBT/XRT/XFL (nunca "enrola" no destino silenciosamente).
Procedure MamuteGui_CmdXlRaw(G_Log, *State.MamuteGui_State, Args.s)
  Protected CommaPos.i = FindString(Args, ",")
  If CommaPos = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected NameToken.s = Trim(Left(Args, CommaPos - 1))
  Protected StartToken.s = Trim(Mid(Args, CommaPos + 1))
  If NameToken = "" Or FindString(StartToken, ",") > 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected StartAddr.i
  Protected Target.MamuteSxTarget
  If Not Mamute_ParseSxAddr(StartToken, @StartAddr, @Target)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected FilePath.s = OpenFileRequester("Selecione o arquivo de bytes crus (XL#)", NameToken,
    "Binario cru (*.bin)|*.bin|Todos os arquivos (*.*)|*.*", 0)
  If FilePath = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "CANCELADO")
    ProcedureReturn
  EndIf

  Protected Fh = ReadFile(#PB_Any, FilePath)
  If Not Fh
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ARQUIVO INVALIDO")
    ProcedureReturn
  EndIf
  Protected DataLen.q = Lof(Fh)

  If StartAddr + DataLen - 1 > Mamute_SxMaxAddr(@Target)
    CloseFile(Fh)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected Dim Buf.a(DataLen)
  If DataLen > 0 : ReadData(Fh, @Buf(0), DataLen) : EndIf
  CloseFile(Fh)

  Protected i.i
  For i = 0 To DataLen - 1
    Mamute_SxWriteByte(StartAddr + i, Buf(i), @Target)
  Next

  Protected EndAddr.i = StartAddr + DataLen - 1
  If DataLen = 0 : EndAddr = StartAddr : EndIf
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "CARREGADO: " + GetFilePart(FilePath) + " EM " + Mamute_HexPad(StartAddr, 4) + Mamute_SxTargetSuffixText(@Target) +
    "-" + Mamute_HexPad(EndAddr, 4) + " - " + Str(DataLen) + " BYTE(S))")
EndProcedure

; Abre o dialogo de imagem de disco (#File_Pattern_Disk, DiskManagerGui.pbi -
; mesmo filtro que o ZAP/Gerenciador de Disco ja usam) sugerindo
; SuggestedName - usado pelo XFS e por QUALQUER comando de disco futuro
; (docs/SPEC.md modulo 45). #True + *State\CurrentDiskPath/HasCurrentDisk
; atualizados se o usuario escolheu um arquivo; #False (estado ANTERIOR
; preservado, nunca limpo) se cancelou.
Procedure.b MamuteGui_PickDisk(*State.MamuteGui_State, SuggestedName.s)
  Protected Picked.s = OpenFileRequester("Selecione a imagem de disco (DSK)", SuggestedName, #File_Pattern_Disk, 0)
  If Picked = ""
    ProcedureReturn #False
  EndIf
  *State\CurrentDiskPath = Picked
  *State\HasCurrentDisk = #True
  ProcedureReturn #True
EndProcedure

; Garante que ha' um disco corrente pronto pra uso - **mudanca drastica de
; design, pedido explicito do usuario** (substitui o antigo esquema
; "[,<nome>]" por comando, que so' existiu por 1 sessao): "todos os
; comandos de disco... vamos eliminar o nome deles, o nome vai ser sempre o
; nome corrente... para cada comando de disco, caso nao exista um disco
; previamente carregado por XDK, ai sim abra o dialogo". Ou seja: NENHUM
; comando de disco (XFS/XCI/XTP/XL%/XS%) aceita mais um argumento de nome/
; troca de disco - so' o XDK (abaixo) TROCA o disco corrente; os outros so'
; USAM o que ja esta carregado, abrindo o dialogo (MamuteGui_PickDisk, sem
; sugestao de nome nenhuma) so' na PRIMEIRA vez, se ainda nao houver disco
; corrente. #True quando *State\CurrentDiskPath esta pronto pra uso; #False
; quando o usuario cancelou o dialogo (CANCELADO ja LOGADO aqui) - o
; chamador so' precisa dar ProcedureReturn nesse caso.
Procedure.b MamuteGui_EnsureCurrentDisk(G_Log, *State.MamuteGui_State)
  If *State\HasCurrentDisk
    ProcedureReturn #True
  EndIf
  If Not MamuteGui_PickDisk(*State, "")
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "CANCELADO")
    ProcedureReturn #False
  EndIf
  ProcedureReturn #True
EndProcedure

; XDK [<nome>] - pedido explicito do usuario, junto com a mudanca drastica
; documentada em MamuteGui_EnsureCurrentDisk acima: "vamos criar um comando
; novo XDK [<nome>] que vai abrir o dialogo para buscar uma imagem de disco
; de MSX (DSK), sugerindo o nome (opcional)". Nome nao existe no SUPER-X
; original (nenhum verbo "DK" no inventario do modulo 45) - inventado pra
; esta sessao especificamente como o UNICO comando que TROCA o disco
; corrente (SEMPRE abre o dialogo, mesmo ja tendo um disco carregado -
; diferente do MamuteGui_EnsureCurrentDisk, que so' abre se NAO houver
; nenhum ainda). <nome>, se dado, e' so' a SUGESTAO inicial do campo do
; dialogo (mesmo idioma "sugerindo o nome" de XSD/XSV/etc), nunca um
; caminho usado direto sem confirmar. Cancelar preserva o disco corrente
; anterior (se havia) - CANCELADO, sem trocar nada.
Procedure MamuteGui_CmdXdk(G_Log, *State.MamuteGui_State, Args.s)
  Protected SuggestedName.s = Trim(Args)
  If Not MamuteGui_PickDisk(*State, SuggestedName)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "CANCELADO")
    ProcedureReturn
  EndIf
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "DISCO: " + GetFilePart(*State\CurrentDiskPath))
EndProcedure

; XFS - porta do FS do SUPER-X (inventario do modulo 45: "Lista arquivos do
; disco (equivalente a DIR)") - PRIMEIRO comando de disco do Mamute
; Assembler. Sem argumento nenhum (mudanca de design, ver comentario do
; MamuteGui_EnsureCurrentDisk acima - a antiga sintaxe "XFS[,<nome>]" desta
; mesma sessao foi ELIMINADA por pedido explicito do usuario: "vamos
; padronizar todos sem nome, o nome e' o corrente"). Lista o disco corrente
; direto; se ainda nao houver nenhum, abre o dialogo de escolha primeiro
; (MamuteGui_EnsureCurrentDisk).
;
; Usa o MSXDisk:: existente (unico DeclareModule real do projeto, ja usado
; pelo Gerenciador de Disco/CLI --diskmanipulator/montagem do disco de
; execucao do openMSX) - MSXDisk::OpenDisk()/ListFiles()/CloseDisk(), NADA
; de rotina nova de FAT12 (pedido explicito do usuario: "use o sistema de
; DSK que o PaleoBasic ja tem pra poder trabalhar com discos"). Abre/fecha
; o disco a CADA chamada, nunca fica aberto entre comandos MON> - mesmo
; idioma do CLI/Gerenciador (evita segurar o arquivo travado enquanto o
; usuario digita outros comandos no meio tempo).
Procedure MamuteGui_CmdXfs(G_Log, *State.MamuteGui_State, Args.s)
  If Trim(Args) <> ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  If Not MamuteGui_EnsureCurrentDisk(G_Log, *State)
    ProcedureReturn
  EndIf

  If Not MSXDisk::OpenDisk(*State\CurrentDiskPath)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO AO ABRIR O DISCO: " + MSXDisk::GetLastErrorMessage())
    ProcedureReturn
  EndIf

  NewList Files.MSXDisk::FileInfo()
  If MSXDisk::ListFiles(Files())
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, GetFilePart(*State\CurrentDiskPath) + ":")
    If ListSize(Files()) = 0
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "(DISCO VAZIO)")
    Else
      ForEach Files()
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
          LSet(Files()\FileName, 12) + " " + RSet(Str(Files()\Size), 7))
      Next
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, Str(ListSize(Files())) + " ARQUIVO(S)")
    EndIf
  Else
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO AO LISTAR: " + MSXDisk::GetLastErrorMessage())
  EndIf

  MSXDisk::CloseDisk()
EndProcedure

; XCI - porta do CI do SUPER-X (inventario do modulo 45: "Uso do disco
; (clusters usados/total)") - pedido explicito do usuario: "mostra a
; quantidade de clusters livres do disco / quantidade total de clusters".
; Sem argumento nenhum, mesma logica de disco corrente do XFS (ver
; comentario la e de MamuteGui_EnsureCurrentDisk acima) - so' o que faz
; DEPOIS de abrir o disco muda. Nova MSXDisk::GetClusterInfo() (MSXDisk.pbi)
; varre a FAT em memoria com o MESMO criterio que MSXDisk::AddFile() ja usa
; internamente pra achar um cluster livre (ReadFAT(c,*FAT)=0) - nenhuma
; logica nova de FAT12, so' leitura; unica adicao nova NO MODULO MSXDisk
; nesta sessao (pedido explicito do usuario: "use o sistema de DSK que o
; PaleoBasic ja tem... se nao for possivel, crie rotinas diferentes" - foi
; possivel, so' precisou de UMA funcao nova, publica, ao lado de ListFiles).
Procedure MamuteGui_CmdXci(G_Log, *State.MamuteGui_State, Args.s)
  If Trim(Args) <> ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  If Not MamuteGui_EnsureCurrentDisk(G_Log, *State)
    ProcedureReturn
  EndIf

  If Not MSXDisk::OpenDisk(*State\CurrentDiskPath)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO AO ABRIR O DISCO: " + MSXDisk::GetLastErrorMessage())
    ProcedureReturn
  EndIf

  Protected Free.l, Total.l
  If MSXDisk::GetClusterInfo(@Free, @Total)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
      GetFilePart(*State\CurrentDiskPath) + ": " + Str(Free) + " / " + Str(Total) + " CLUSTERS LIVRES")
  Else
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO: " + MSXDisk::GetLastErrorMessage())
  EndIf

  MSXDisk::CloseDisk()
EndProcedure

; XTP <arquivo> - porta do TP do SUPER-X (inventario do modulo 45: "Exibe
; arquivo de texto (paginado, ENTER/ESPACO/ESC)") - pedido explicito do
; usuario: "mostra o conteudo de um arquivo na tela, crie um read simples,
; com botoes pra rolar a tela pros lados, linha a linha, pagina a pagina,
; como outros visualizadores do programa". <arquivo> e' o nome de um
; arquivo DENTRO do disco corrente (mesmo "disco corrente" do XFS/XCI,
; modulos 45p/45q/comentario da Structure) - NAO um caminho do sistema de
; arquivos do host. **Achado real, corrigido ainda na sessao anterior**: a
; primeira versao lia <arquivo> como caminho do host, o que dava
; ?ARQUIVO INVALIDO pra qualquer nome listado pelo XFS (o usuario reportou
; exatamente isso) - TP esta agrupado com FS/CI/CD/BL/SV/LD no inventario
; do modulo 45, e' um comando de DISCO, nao um visualizador de arquivo
; qualquer do host. NAO tem mais `[,<nome>]` (mudanca drastica de design,
; ver comentario de MamuteGui_EnsureCurrentDisk acima) - `<arquivo>` e' o
; UNICO argumento agora; sem disco corrente, abre o dialogo primeiro.
;
; Extrai o arquivo do disco pra um temporario (MSXDisk::ExtractFile(),
; GetTemporaryDirectory()) - MSXDisk:: nao tem "ler pra memoria" direto, so'
; "extrair pra um caminho real" (mesma API que o Gerenciador de Disco/CLI
; --diskmanipulator ja usam) - le DAQUELE temporario, apaga na sequencia.
; MamuteXtp_Open() (MamuteXtpGui.pbi) nunca sabe a diferenca; so' recebe um
; DisplayName separado (o nome de VERDADE dentro do disco) pro titulo da
; janela, nao o caminho temporario. Janela de verdade em MamuteXtpGui.pbi -
; ver comentario no topo daquele arquivo pro design completo (janela SEM
; cruz de modos, EditorGadget recortado manualmente nos dois eixos, 6
; botoes no MESMO layout do XH).
Procedure MamuteGui_CmdXtp(Win, G_Log, *State.MamuteGui_State, Args.s)
  Protected FileToken.s = Trim(Args)
  If FileToken = "" Or FindString(FileToken, ",") > 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  If Not MamuteGui_EnsureCurrentDisk(G_Log, *State)
    ProcedureReturn
  EndIf

  If Not MSXDisk::OpenDisk(*State\CurrentDiskPath)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO AO ABRIR O DISCO: " + MSXDisk::GetLastErrorMessage())
    ProcedureReturn
  EndIf

  Protected TempPath.s = GetTemporaryDirectory() + "mamute_xtp_view.tmp"
  Protected ExtractOk.b = MSXDisk::ExtractFile(FileToken, TempPath)
  Protected ExtractErr.s = MSXDisk::GetLastErrorMessage()
  MSXDisk::CloseDisk()

  If Not ExtractOk
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ARQUIVO INVALIDO: " + ExtractErr)
    ProcedureReturn
  EndIf

  Protected ErrMsg.s = MamuteXtp_Open(Win, TempPath, FileToken)
  DeleteFile(TempPath)
  If ErrMsg <> ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, ErrMsg)
  EndIf
EndProcedure

#Mamute_DiskSectorSize = 512

; Le UM setor FISICO (512 bytes) do arquivo de imagem de disco corrente
; pro buffer *Buf - I/O bruto DIRETO NO ARQUIVO, sem passar pelo MSXDisk::
; (aquele modulo so' entende arquivos/diretorio via FAT12 - um "setor N"
; isolado esta ABAIXO desse nivel, mais perto do hardware de verdade -
; decisao direta do pedido do usuario: "use o sistema que ja tem, se nao
; for possivel, crie rotinas diferentes" - aqui nao foi possivel, o
; MSXDisk:: nao expoe leitura por setor). #True se leu os 512 bytes
; certinho.
Procedure.b Mamute_ReadDiskSector(DiskPath.s, SectorNum.i, *Buf)
  Protected Fh = ReadFile(#PB_Any, DiskPath)
  If Not Fh
    ProcedureReturn #False
  EndIf
  FileSeek(Fh, SectorNum * #Mamute_DiskSectorSize)
  Protected Got.i = ReadData(Fh, *Buf, #Mamute_DiskSectorSize)
  CloseFile(Fh)
  ProcedureReturn Bool(Got = #Mamute_DiskSectorSize)
EndProcedure

; Grava UM setor (512 bytes) no arquivo de imagem de disco corrente, EM
; CIMA do que ja estava la' - OpenFile(), NAO CreateFile(): CreateFile()
; TRUNCARIA o disco inteiro (apagando tudo); OpenFile() so' abre um
; arquivo JA EXISTENTE pra edicao, sem mexer no resto do conteudo.
Procedure.b Mamute_WriteDiskSector(DiskPath.s, SectorNum.i, *Buf)
  Protected Fh = OpenFile(#PB_Any, DiskPath)
  If Not Fh
    ProcedureReturn #False
  EndIf
  FileSeek(Fh, SectorNum * #Mamute_DiskSectorSize)
  WriteData(Fh, *Buf, #Mamute_DiskSectorSize)
  CloseFile(Fh)
  ProcedureReturn #True
EndProcedure

; Parseia "<setorinic>[,<setorfim>],<endereco>[#slot[-sub]|#V|#S]" -
; compartilhado por XL%/XS% (identico nos dois, so' a DIRECAO da copia
; depois muda). <setorinic>/<setorfim> sao HEXA (mesma convencao numerica
; de todo o resto do monitor) - <setorfim> ausente = "carregue/grave
; apenas um unico setor" (pedido explicito do usuario, os dois comandos).
; Valida a faixa de setor contra o TAMANHO REAL do disco corrente
; (FileSize()) e overflow do alvo de memoria (Mamute_SxMaxAddr() - mesma
; convencao "nunca da a volta silenciosamente" do XL#/XBT/XRT/XFL). #True
; com *OutSecStart/*OutSecEnd/*OutAddr/*OutTarget prontos; #False ja deixou
; ?ERRO DE SINTAXE logado, o chamador so' precisa dar ProcedureReturn.
Procedure.b MamuteGui_ParseSectorArgs(G_Log, *State.MamuteGui_State, Args.s,
                                       *OutSecStart.Integer, *OutSecEnd.Integer,
                                       *OutAddr.Integer, *OutTarget.MamuteSxTarget)
  Protected CommaPos1.i = FindString(Args, ",")
  If CommaPos1 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn #False
  EndIf
  Protected SecStartToken.s = Trim(Left(Args, CommaPos1 - 1))
  Protected Rest1.s = Mid(Args, CommaPos1 + 1)

  Protected SecEndToken.s = "", AddrToken.s
  Protected CommaPos2.i = FindString(Rest1, ",")
  If CommaPos2 = 0
    AddrToken = Trim(Rest1)
  Else
    SecEndToken = Trim(Left(Rest1, CommaPos2 - 1))
    AddrToken = Trim(Mid(Rest1, CommaPos2 + 1))
    If FindString(AddrToken, ",") > 0
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn #False
    EndIf
  EndIf

  Protected SecStart.i, SecEnd.i
  If Not Mamute_IsHexString(SecStartToken, 4)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn #False
  EndIf
  SecStart = Val("$" + SecStartToken)

  If SecEndToken = ""
    SecEnd = SecStart
  Else
    If Not Mamute_IsHexString(SecEndToken, 4)
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn #False
    EndIf
    SecEnd = Val("$" + SecEndToken)
  EndIf
  If SecEnd < SecStart
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn #False
  EndIf

  Protected Addr.i
  If Not Mamute_ParseSxAddr(AddrToken, @Addr, *OutTarget)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn #False
  EndIf

  Protected DiskSize.q = FileSize(*State\CurrentDiskPath)
  Protected TotalSectors.q = DiskSize / #Mamute_DiskSectorSize
  If SecEnd >= TotalSectors
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn #False
  EndIf

  Protected TotalBytes.i = (SecEnd - SecStart + 1) * #Mamute_DiskSectorSize
  If Addr + TotalBytes - 1 > Mamute_SxMaxAddr(*OutTarget)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn #False
  EndIf

  *OutSecStart\i = SecStart
  *OutSecEnd\i = SecEnd
  *OutAddr\i = Addr
  ProcedureReturn #True
EndProcedure

; XL% <setorinic>[,<setorfim>],<endereco>[#slot[-sub]|#V|#S] - porta do L%
; do SUPER-X (inventario do modulo 45: "Le setor(es) de disco direto pra
; memoria") - pedido explicito do usuario: "pega do arquivo de imagem de
; disco corrente, o <setor inicial>... carrega no <endereco>, ate chegar
; ao <setor final>, se o setor final nao for informado, carregue apenas um
; unico setor". Usa o disco CORRENTE (MamuteGui_EnsureCurrentDisk - mesma
; mudanca de design do XFS/XCI/XTP, sem nome nenhum no comando).
; <endereco> aceita VRAM - mesmo escopo do XS#/XL# (modulo 45v): setor cru
; pra VRAM e' uma operacao real do MSX (o proprio NestorBASIC tem
; .NB_ReadSectorsToVram equivalente, visto no .dmx do usuario testado no
; XTP).
Procedure MamuteGui_CmdXlPct(G_Log, *State.MamuteGui_State, Args.s)
  If Not MamuteGui_EnsureCurrentDisk(G_Log, *State)
    ProcedureReturn
  EndIf

  Protected SecStart.i, SecEnd.i, Addr.i
  Protected Target.MamuteSxTarget
  If Not MamuteGui_ParseSectorArgs(G_Log, *State, Args, @SecStart, @SecEnd, @Addr, @Target)
    ProcedureReturn
  EndIf

  Protected Dim SecBuf.a(#Mamute_DiskSectorSize - 1)
  Protected s.i, b.i
  For s = 0 To SecEnd - SecStart
    If Not Mamute_ReadDiskSector(*State\CurrentDiskPath, SecStart + s, @SecBuf(0))
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO AO LER O SETOR " + Mamute_Hex4(SecStart + s))
      ProcedureReturn
    EndIf
    For b = 0 To #Mamute_DiskSectorSize - 1
      Mamute_SxWriteByte(Addr + s * #Mamute_DiskSectorSize + b, SecBuf(b), @Target)
    Next
  Next

  Protected TotalBytes.i = (SecEnd - SecStart + 1) * #Mamute_DiskSectorSize
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "CARREGADO: SETOR(ES) " + Mamute_Hex4(SecStart) + "-" + Mamute_Hex4(SecEnd) + " EM " +
    Mamute_HexPad(Addr, 4) + Mamute_SxTargetSuffixText(@Target) + "-" +
    Mamute_HexPad(Addr + TotalBytes - 1, 4) + " (" + Str(TotalBytes) + " BYTE(S))")
EndProcedure

; XS% <setorinic>[,<setorfim>],<endereco>[#slot[-sub]|#V|#S] - porta do S%
; do SUPER-X (inventario do modulo 45: "Grava memoria direto em setor(es)
; de disco") - pedido explicito do usuario: "faz o reverso [do XL%], salva
; um endereco de memoria em setor de disco, se nao for informado o setor
; final, grava apenas um unico setor". MESMA sintaxe/validacao do XL%
; (MamuteGui_ParseSectorArgs) - so' a direcao da copia inverte.
;
; Grava DIRETO EM CIMA do disco corrente (Mamute_WriteDiskSector() -
; OpenFile(), nunca CreateFile(), pra nao truncar o resto do disco) - sem
; confirmacao extra, mesmo espirito "MON> executa na hora" de todo o resto
; do monitor (M/S/F/XFL/XS# ja escrevem sem perguntar) - o SUPER-X original
; tambem nao pede confirmacao nenhuma pro S%.
Procedure MamuteGui_CmdXsPct(G_Log, *State.MamuteGui_State, Args.s)
  If Not MamuteGui_EnsureCurrentDisk(G_Log, *State)
    ProcedureReturn
  EndIf

  Protected SecStart.i, SecEnd.i, Addr.i
  Protected Target.MamuteSxTarget
  If Not MamuteGui_ParseSectorArgs(G_Log, *State, Args, @SecStart, @SecEnd, @Addr, @Target)
    ProcedureReturn
  EndIf

  Protected Dim SecBuf.a(#Mamute_DiskSectorSize - 1)
  Protected s.i, b.i
  For s = 0 To SecEnd - SecStart
    For b = 0 To #Mamute_DiskSectorSize - 1
      SecBuf(b) = Mamute_SxReadByte(Addr + s * #Mamute_DiskSectorSize + b, @Target)
    Next
    If Not Mamute_WriteDiskSector(*State\CurrentDiskPath, SecStart + s, @SecBuf(0))
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO AO GRAVAR O SETOR " + Mamute_Hex4(SecStart + s))
      ProcedureReturn
    EndIf
  Next

  Protected TotalBytes.i = (SecEnd - SecStart + 1) * #Mamute_DiskSectorSize
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "GRAVADO: SETOR(ES) " + Mamute_Hex4(SecStart) + "-" + Mamute_Hex4(SecEnd) + " DE " +
    Mamute_HexPad(Addr, 4) + Mamute_SxTargetSuffixText(@Target) + "-" +
    Mamute_HexPad(Addr + TotalBytes - 1, 4) + " (" + Str(TotalBytes) + " BYTE(S))")
EndProcedure

; X [<reg>] - sem argumento, mostra os 7 pares de registrador (AF/BC/DE/HL/
; IX/IY/SP). Com argumento, entra no modo de edicao a partir de <reg> -
; aceita tanto um PAR (AF/BC/DE/HL/IX/IY/SP, editado como um valor de 16
; bits/4 digitos hexa de uma vez) quanto um registrador de 1 BYTE isolado
; (A/F/B/C/D/E/H/L, 2 digitos hexa) - extensao pedida explicitamente pelo
; usuario sobre o manual original (que so tem os bytes A-L mais X/Y/S como
; abreviacao de IX/IY/SP, sem nomes de par diretos). Caminha em sequencia a
; partir do registrador escolhido (AF->BC->DE->HL->IX->IY->SP no modo par,
; A->F->B->C->D->E->H->L no modo byte), perguntando o novo valor de cada um
; via InputRequester() - o valor ATUAL vem pre-preenchido na caixa, entao
; <ENTER> sem editar "mantem o que esta" (reescreve o mesmo valor, sem
; mudanca real) e continua pro proximo; apagar o campo e confirmar (ou
; Cancelar/Esc - PureBasic nao distingue os dois, os dois retornam string
; vazia) para a caminhada inteira, mesmo espirito do "tecle RETURN pra
; parar" do manual original.
Procedure MamuteGui_CmdX(G_Log, *State.MamuteGui_State, Args.s)
  Protected Trimmed.s = UCase(Trim(Args))
  If Trimmed = ""
    *State\LogAccum = MamuteGui_ShowRegs(G_Log, *State\LogAccum, *State)
    ProcedureReturn
  EndIf

  Protected Dim PairSeq.s(6)
  PairSeq(0) = "AF" : PairSeq(1) = "BC" : PairSeq(2) = "DE" : PairSeq(3) = "HL"
  PairSeq(4) = "IX" : PairSeq(5) = "IY" : PairSeq(6) = "SP"

  Protected Dim ByteSeq.s(7)
  ByteSeq(0) = "A" : ByteSeq(1) = "F" : ByteSeq(2) = "B" : ByteSeq(3) = "C"
  ByteSeq(4) = "D" : ByteSeq(5) = "E" : ByteSeq(6) = "H" : ByteSeq(7) = "L"

  Protected Mode.b, StartIdx.i = -1, i.i
  For i = 0 To 6
    If PairSeq(i) = Trimmed
      StartIdx = i : Mode = 0
      Break
    EndIf
  Next
  If StartIdx = -1
    For i = 0 To 7
      If ByteSeq(i) = Trimmed
        StartIdx = i : Mode = 1
        Break
      EndIf
    Next
  EndIf

  If StartIdx = -1
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected Walking.b = #True, RegName.s, CurStr.s, NewStr.s, Digits.i, CurVal.i
  If Mode = 0
    Digits = 4
    For i = StartIdx To 6
      If Not Walking : Break : EndIf
      RegName = PairSeq(i)
      CurVal = MamuteGui_RegPairValue(*State, RegName)
      CurStr = Mamute_Hex4(CurVal)
      NewStr = Trim(InputRequester("X - " + RegName, "Novo valor de " + RegName + " (4 digitos hexa - ENTER mantem, vazio/Cancelar interrompe):", CurStr))
      If NewStr = ""
        Walking = #False
      ElseIf Mamute_IsHexString(NewStr, Digits)
        MamuteGui_SetRegPair(*State, RegName, Val("$" + NewStr))
      Else
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
        Walking = #False
      EndIf
    Next
  Else
    Digits = 2
    For i = StartIdx To 7
      If Not Walking : Break : EndIf
      RegName = ByteSeq(i)
      CurVal = MamuteGui_RegByteValue(*State, RegName)
      CurStr = Mamute_Hex2(CurVal)
      NewStr = Trim(InputRequester("X - " + RegName, "Novo valor de " + RegName + " (2 digitos hexa - ENTER mantem, vazio/Cancelar interrompe):", CurStr))
      If NewStr = ""
        Walking = #False
      ElseIf Mamute_IsHexString(NewStr, Digits)
        MamuteGui_SetRegByte(*State, RegName, Val("$" + NewStr))
      Else
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
        Walking = #False
      EndIf
    Next
  EndIf

  *State\LogAccum = MamuteGui_ShowRegs(G_Log, *State\LogAccum, *State)
EndProcedure

; Parser comum de "[<endinic>[,<endfim>]]" pro L/LP - os tres jeitos do
; manual original: nenhum argumento (continua do ultimo L/LP - *State\
; LastLAddr), so <endinic> (10 instrucoes a partir dali) ou os dois
; (decodifica ate ultrapassar <endfim>, mesma regra de Mamute_
; DisasmBuildLines em MamuteSupport.pbi). *OutHasEnd\i vira #True/#False.
Procedure.b MamuteGui_ParseLArgs(Args.s, *State.MamuteGui_State, *OutStart.Integer, *OutHasEnd.Integer, *OutEnd.Integer)
  Protected Trimmed.s = Trim(Args)
  Protected StartToken.s, EndToken.s = ""
  Protected CommaPos.i = FindString(Trimmed, ",")
  If CommaPos > 0
    StartToken = Trim(Left(Trimmed, CommaPos - 1))
    EndToken = Trim(Mid(Trimmed, CommaPos + 1))
  Else
    StartToken = Trimmed
  EndIf

  Protected StartAddr.i
  If StartToken = ""
    If Not *State\HasLastL
      ProcedureReturn #False
    EndIf
    StartAddr = *State\LastLAddr
  Else
    If Not Mamute_ParseHexAddr(StartToken, @StartAddr)
      ProcedureReturn #False
    EndIf
  EndIf

  Protected HasEnd.b = #False
  Protected EndAddr.i = 0
  If EndToken <> ""
    If Not Mamute_ParseHexAddr(EndToken, @EndAddr)
      ProcedureReturn #False
    EndIf
    If EndAddr < StartAddr
      ProcedureReturn #False
    EndIf
    HasEnd = #True
  EndIf

  *OutStart\i = StartAddr
  *OutHasEnd\i = HasEnd
  *OutEnd\i = EndAddr
  ProcedureReturn #True
EndProcedure

; L [<endinic>[,<endfim>]] - disassembla a RAM/ROM (mapeamento PAGE ativo
; agora) direto no log do MON>. Sem janela, mesmo espirito do D. <CTRL+STOP>
; do manual original pra interromper NAO se aplica aqui - a desmontagem
; inteira e calculada de uma vez, nao ha nada "rodando" em tempo real pra
; interromper.
Procedure MamuteGui_CmdL(G_Log, *State.MamuteGui_State, Args.s)
  Protected StartAddr.i, HasEndI.i, EndAddr.i
  If Not MamuteGui_ParseLArgs(Args, *State, @StartAddr, @HasEndI, @EndAddr)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected NewList Lines.s()
  Protected NextAddr.i
  Mamute_DisasmBuildLines(Lines(), StartAddr, Bool(HasEndI), EndAddr, @NextAddr)
  ForEach Lines()
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, Lines())
  Next

  *State\LastLAddr = NextAddr
  *State\HasLastL = #True
EndProcedure

; LP [<endinic>[,<endfim>]] - mesma desmontagem do L, mas "na impressora":
; gera um PDF A4 simples (mesma infra do P/V - Mamute_SavePdfListing(),
; MamutePdf.pbi) e abre "Salvar como" no final, em vez de mandar pro log.
Procedure MamuteGui_CmdLp(G_Log, *State.MamuteGui_State, Args.s)
  Protected StartAddr.i, HasEndI.i, EndAddr.i
  If Not MamuteGui_ParseLArgs(Args, *State, @StartAddr, @HasEndI, @EndAddr)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected NewList Lines.s()
  Protected NextAddr.i
  Mamute_DisasmBuildLines(Lines(), StartAddr, Bool(HasEndI), EndAddr, @NextAddr)

  Protected FilePath.s = SaveFileRequester("Salvar listagem (LP) como PDF", "listagem_disasm.pdf", "PDF (*.pdf)|*.pdf", 0)
  If FilePath = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "CANCELADO")
    ProcedureReturn
  EndIf
  If LCase(Right(FilePath, 4)) <> ".pdf"
    FilePath + ".pdf"
  EndIf

  Protected Header.s = "L " + Mamute_Hex4(StartAddr)
  If HasEndI
    Header + "-" + Mamute_Hex4(EndAddr)
  EndIf
  If Mamute_SavePdfListing(FilePath, Lines(), Header)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "PDF GRAVADO: " + FilePath)
  Else
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO AO GRAVAR PDF")
  EndIf

  *State\LastLAddr = NextAddr
  *State\HasLastL = #True
EndProcedure

; CL <expressao> - calculadora: converte um numero (ou avalia uma expressao
; matematica) e mostra o resultado em HEX, BIN (16 bits), DEC sem sinal e
; DEC com sinal, sempre em 16 bits com wraparound. Numeros seguem a mesma
; convencao hexa-por-padrao do resto do Mamute, com sufixos opcionais D/d
; (decimal), B/b (binario), H/h (hexa) e O/o (octal); operadores + - * / %
; (modulo) | (or) & (and) ^ (xor) ! (not, unario) e parenteses pra mudar a
; ordem - ver Mamute_CL_Eval()/Mamute_CL_ParseNumber() em MamuteSupport.pbi.
Procedure MamuteGui_CmdCl(G_Log, *State.MamuteGui_State, Args.s)
  If Trim(Args) = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected Result.i
  If Not Mamute_CL_Eval(Args, @Result)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?" + MamuteCL_LastError)
    ProcedureReturn
  EndIf

  Protected Signed.i = Result
  If Signed >= $8000
    Signed - $10000
  EndIf

  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "HEX  : " + Mamute_Hex4(Result) + "H")
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "BIN  : " + RSet(Bin(Result), 16, "0"))
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "DEC+ : " + Str(Result))
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "DEC+-: " + Str(Signed))
EndProcedure

; XD [<endereco>] / XD <inic>[#slot[-subslot]][,<fim>[,<arquivo>]] - porta do
; comando D do SUPER-X (docs/SPEC.md modulo 45; nao confundir com o D do
; proprio Mamute, MODULO 31, que e outra coisa - por isso o prefixo X). UM
; endereco (ou nenhum, reabre onde ficou) abre a grade interativa hexa+ASCII
; (MamuteXdGui.pbi, bloco ASCII TAMBEM editavel, "/@ como no original). DOIS
; OU TRES enderecos/campos (separados por virgula) NAO abrem grade nenhuma:
; - DOIS (<inic>,<fim>) - despejo nao-interativo direto no log, mesmo
;   formato do D/MamuteGui_CmdD (doc do SUPER-X: "Two Addresses: give a non
;   stop list output"). <inic> aceita o mesmo sufixo #slot[-subslot]/#V/#S
;   da forma de UM endereco (modulo 45b) - Mamute_BuildDumpLinesSx() honra o
;   alvo resolvido em vez de sempre ler a PAGE ativa. <fim> e' sempre um
;   endereco CPU simples (0000-FFFF), sem sufixo - so' o inicio escolhe
;   slot/VRAM, igual a sintaxe original do SUPER-X (`<inic>[#slot],<fim>`).
; - TRES (<inic>,<fim>,<arquivo>) - modulo 45g (docs/SPEC.md): em vez de
;   listar em texto, GRAVA o intervalo de bytes crus como arquivo binario,
;   abrindo a MESMA janela do comando SAVE do MON> (MamuteSave_Open(),
;   MamuteSaveGui.pbi) com "<arquivo>" como nome sugerido - usuario ainda
;   escolhe/revisa slot(so' informativo aqui, os bytes ja vem prontos)/
;   formato BIN-ROM/cabecalho antes de gravar de verdade, nada e' salvo so'
;   por digitar o comando. Le os bytes via Mamute_SxReadByte (honra
;   slot/sub-slot/VRAM do <inic>) pra um buffer explicito, MESMA tecnica
;   ja usada pelo "A I" do EDIT (MamuteEditGui.pbi).
; <fim> OMITIDO (modulo 45h, pedido explicito do usuario "quando nao
; informar fim, assuma 256 bytes nos comandos") - duas formas aceitas:
; "XD <inic>,,<arquivo>" (virgula dupla, <fim> explicitamente vazio) OU o
; atalho "XD <inic>,<arquivo>" (SO' dois campos - se o segundo campo nao
; parsear como endereco hexa valido, e' tratado como <arquivo> direto, sem
; precisar da virgula dupla). Nos dois casos <fim> vira StartAddr+255,
; CLAMPADO no teto do alvo (Mamute_SxMaxAddr - $FFFF normal, MamuteVramSize-1
; em VRAM) em vez de dar a volta. "XD <inic>," (virgula sobrando, nada depois
; - nem <fim> nem <arquivo>) tambem usa o default de 256 bytes, despejando no
; log como se fosse so' "XD <inic>". Uma virgula sobrando DEPOIS de um <fim>
; explicito e valido, sem nada apos ela (ex.: "XD 4000,4010,") continua erro
; de sintaxe - "virgula demais" nao e' a mesma coisa que "<fim> omitido".
; PrinterMode (docs/SPEC.md modulo 45c, MamuteGui_Dispatch detecta o "?" na
; frente e passa isso aqui) manda a listagem de DOIS enderecos pra um PDF em
; vez do log - nao se aplica nem a UM endereco (abre grade, nao ha o que
; "imprimir") nem a TRES (ja vai pro SAVE, nao faz sentido combinar com
; impressora).
Procedure MamuteGui_CmdXd(Win, G_Log, *State.MamuteGui_State, Args.s, PrinterMode.b = #False)
  Protected Trimmed.s = Trim(Args)
  Protected CommaPos.i = FindString(Trimmed, ",")

  If CommaPos > 0
    Protected StartAddr.i, EndAddr.i
    Protected DumpTarget.MamuteSxTarget
    Protected StartTok.s = Trim(Left(Trimmed, CommaPos - 1))
    Protected FieldCount.i = CountString(Trimmed, ",") + 1
    Protected Field2.s = Trim(StringField(Trimmed, 2, ","))
    Protected Field3.s = ""
    If FieldCount >= 3 : Field3 = Trim(StringField(Trimmed, 3, ",")) : EndIf
    Protected FileTok.s = ""
    Protected SyntaxOk.b = #True

    If FieldCount > 3 Or Not Mamute_ParseSxAddr(StartTok, @StartAddr, @DumpTarget)
      SyntaxOk = #False
    ElseIf Mamute_ParseHexAddr(Field2, @EndAddr)
      If EndAddr < StartAddr Or (FieldCount = 3 And Field3 = "")
        SyntaxOk = #False
      Else
        FileTok = Field3
      EndIf
    ElseIf Field2 = ""
      EndAddr = StartAddr + 255
      If EndAddr > Mamute_SxMaxAddr(@DumpTarget) : EndAddr = Mamute_SxMaxAddr(@DumpTarget) : EndIf
      FileTok = Field3
    ElseIf FieldCount = 2
      EndAddr = StartAddr + 255
      If EndAddr > Mamute_SxMaxAddr(@DumpTarget) : EndAddr = Mamute_SxMaxAddr(@DumpTarget) : EndIf
      FileTok = Field2
    Else
      SyntaxOk = #False
    EndIf

    If Not SyntaxOk
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf

    If FileTok <> ""
      If PrinterMode
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?IMPRESSAO NAO APLICAVEL A ESTE COMANDO")
        ProcedureReturn
      EndIf

      Protected SxLen.i = EndAddr - StartAddr + 1
      Protected Dim SxBuf.a(SxLen - 1)
      Protected SxI.i
      For SxI = 0 To SxLen - 1
        SxBuf(SxI) = Mamute_SxReadByte((StartAddr + SxI) & $FFFF, @DumpTarget)
      Next

      Protected SxSaveMsg.s = MamuteSave_Open(Win, FileTok, #True, StartAddr, EndAddr, StartAddr, #True, SxBuf())
      If SxSaveMsg <> ""
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, SxSaveMsg)
      EndIf
      ProcedureReturn
    EndIf

    Protected NewList XdLines.s()
    Mamute_BuildDumpLinesSx(XdLines(), StartAddr, EndAddr, *State\ChecksumAddrMode, @DumpTarget)

    If PrinterMode
      ; "?XD" = "impressora" do SUPER-X, que aqui vira PDF - mesma tecnica
      ; do P (Mamute_SavePdfListing, modulo 31).
      Protected FilePath.s = SaveFileRequester("Salvar listagem (?XD) como PDF", "listagem_xd.pdf", "PDF (*.pdf)|*.pdf", 0)
      If FilePath = ""
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "CANCELADO")
        ProcedureReturn
      EndIf
      If LCase(Right(FilePath, 4)) <> ".pdf"
        FilePath + ".pdf"
      EndIf
      Protected ChecksumModeText.s = "NORMAL"
      If *State\ChecksumAddrMode : ChecksumModeText = "+ADDR" : EndIf
      Protected Header.s = "?XD " + Mamute_Hex4(StartAddr) + "-" + Mamute_Hex4(EndAddr) + " CHECKSUM " + ChecksumModeText
      If Mamute_SavePdfListing(FilePath, XdLines(), Header)
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "PDF GRAVADO: " + FilePath)
      Else
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO AO GRAVAR PDF")
      EndIf
      ProcedureReturn
    EndIf

    ForEach XdLines()
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, XdLines())
    Next
    ProcedureReturn
  EndIf

  If PrinterMode
    ; Um endereco so' abre a grade interativa - nao ha "listagem" nenhuma
    ; pra imprimir nesse modo (mesma logica do proprio SUPER-X: "?" so' faz
    ; sentido combinado com a forma de DOIS enderecos, a unica que gera uma
    ; listagem estatica).
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?IMPRESSAO SO FUNCIONA COM DOIS ENDERECOS (XD <inic>,<fim>)")
    ProcedureReturn
  EndIf

  Protected Addr.i
  Protected Target.MamuteSxTarget
  If Trimmed = ""
    If Not *State\HasLastXd
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
    Addr = *State\LastXdAddr
    CopyStructure(@*State\LastXdTarget, @Target, MamuteSxTarget)
  Else
    If Not Mamute_ParseSxAddr(Trimmed, @Addr, @Target)
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
  EndIf

  Mamute_VarStoreBase(Addr, @Target) ; "commands store base address in variable 0", doc do SUPER-X
  *State\LastXdAddr = MamuteXd_Open(Win, Addr, 0, @Target)
  CopyStructure(@Target, @*State\LastXdTarget, MamuteSxTarget)
  *State\HasLastXd = #True
EndProcedure

; XA [<endereco>] / XA <inic>[#slot[-subslot]][,<fim>[,<arquivo>]] - porta do
; comando A do SUPER-X (docs/SPEC.md modulo 45h, pedido explicito do
; usuario: "ele e igual ao XD... o processo e o mesmo do anterior"). MESMA
; sintaxe/mecanismo do XD (modulo 45/45b/45g) - UM endereco abre a tela
; interativa (MamuteXaGui.pbi, dedicada, SO' ASCII, sem coluna hexa - decisao
; explicita do usuario via pergunta direta); DOIS/TRES campos despejam texto
; (ou arquivo binario) sem abrir tela nenhuma. Unica diferenca de verdade
; contra o XD: o despejo em texto usa Mamute_BuildAsciiDumpLines() (so'
; ASCII, sem coluna hexa/checksum - nao ha "*State\DisplayMode" aqui, o A do
; SUPER-X nao tem formato alternativo) e a tela interativa e' MamuteXa_Open()
; em vez de MamuteXd_Open(). <fim> omitido tambem assume 256 bytes (mesma
; regra/mesmo texto de comentario do XD, ver ali).
Procedure MamuteGui_CmdXa(Win, G_Log, *State.MamuteGui_State, Args.s, PrinterMode.b = #False)
  Protected Trimmed.s = Trim(Args)
  Protected CommaPos.i = FindString(Trimmed, ",")

  If CommaPos > 0
    Protected StartAddr.i, EndAddr.i
    Protected DumpTarget.MamuteSxTarget
    Protected StartTok.s = Trim(Left(Trimmed, CommaPos - 1))
    Protected FieldCount.i = CountString(Trimmed, ",") + 1
    Protected Field2.s = Trim(StringField(Trimmed, 2, ","))
    Protected Field3.s = ""
    If FieldCount >= 3 : Field3 = Trim(StringField(Trimmed, 3, ",")) : EndIf
    Protected FileTok.s = ""
    Protected SyntaxOk.b = #True

    If FieldCount > 3 Or Not Mamute_ParseSxAddr(StartTok, @StartAddr, @DumpTarget)
      SyntaxOk = #False
    ElseIf Mamute_ParseHexAddr(Field2, @EndAddr)
      If EndAddr < StartAddr Or (FieldCount = 3 And Field3 = "")
        SyntaxOk = #False
      Else
        FileTok = Field3
      EndIf
    ElseIf Field2 = ""
      EndAddr = StartAddr + 255
      If EndAddr > Mamute_SxMaxAddr(@DumpTarget) : EndAddr = Mamute_SxMaxAddr(@DumpTarget) : EndIf
      FileTok = Field3
    ElseIf FieldCount = 2
      EndAddr = StartAddr + 255
      If EndAddr > Mamute_SxMaxAddr(@DumpTarget) : EndAddr = Mamute_SxMaxAddr(@DumpTarget) : EndIf
      FileTok = Field2
    Else
      SyntaxOk = #False
    EndIf

    If Not SyntaxOk
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf

    If FileTok <> ""
      If PrinterMode
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?IMPRESSAO NAO APLICAVEL A ESTE COMANDO")
        ProcedureReturn
      EndIf

      Protected SxLen.i = EndAddr - StartAddr + 1
      Protected Dim SxBuf.a(SxLen - 1)
      Protected SxI.i
      For SxI = 0 To SxLen - 1
        SxBuf(SxI) = Mamute_SxReadByte((StartAddr + SxI) & $FFFF, @DumpTarget)
      Next

      Protected SxSaveMsg.s = MamuteSave_Open(Win, FileTok, #True, StartAddr, EndAddr, StartAddr, #True, SxBuf())
      If SxSaveMsg <> ""
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, SxSaveMsg)
      EndIf
      ProcedureReturn
    EndIf

    Protected NewList XaLines.s()
    Mamute_BuildAsciiDumpLines(XaLines(), StartAddr, EndAddr, @DumpTarget)

    If PrinterMode
      ; "?XA" = "impressora" do SUPER-X, que aqui vira PDF - mesma tecnica
      ; do XD/P (Mamute_SavePdfListing, modulo 31).
      Protected FilePath.s = SaveFileRequester("Salvar listagem (?XA) como PDF", "listagem_xa.pdf", "PDF (*.pdf)|*.pdf", 0)
      If FilePath = ""
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "CANCELADO")
        ProcedureReturn
      EndIf
      If LCase(Right(FilePath, 4)) <> ".pdf"
        FilePath + ".pdf"
      EndIf
      Protected Header.s = "?XA " + Mamute_Hex4(StartAddr) + "-" + Mamute_Hex4(EndAddr)
      If Mamute_SavePdfListing(FilePath, XaLines(), Header)
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "PDF GRAVADO: " + FilePath)
      Else
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO AO GRAVAR PDF")
      EndIf
      ProcedureReturn
    EndIf

    ForEach XaLines()
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, XaLines())
    Next
    ProcedureReturn
  EndIf

  If PrinterMode
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?IMPRESSAO SO FUNCIONA COM DOIS ENDERECOS (XA <inic>,<fim>)")
    ProcedureReturn
  EndIf

  Protected Addr.i
  Protected Target.MamuteSxTarget
  If Trimmed = ""
    If Not *State\HasLastXa
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
    Addr = *State\LastXaAddr
    CopyStructure(@*State\LastXaTarget, @Target, MamuteSxTarget)
  Else
    If Not Mamute_ParseSxAddr(Trimmed, @Addr, @Target)
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
  EndIf

  Mamute_VarStoreBase(Addr, @Target) ; "commands store base address in variable 0", doc do SUPER-X
  *State\LastXaAddr = MamuteXa_Open(Win, Addr, @Target)
  CopyStructure(@Target, @*State\LastXaTarget, MamuteSxTarget)
  *State\HasLastXa = #True
EndProcedure

; XI [<endereco>] / XI <inic>[#slot[-subslot]][,<fim>[,<arquivo>]] - porta do
; comando I do SUPER-X (docs/SPEC.md modulo 45i, pedido explicito do usuario:
; "lista o disassembly do endereco inicial, ate o final (opcional) ou salva
; com nome (opcional) igual aos outros comandos acima"). MESMA estrutura de
; campos do XD/XA (modulo 45/45g/45h) - UM endereco abre uma tela de
; VISUALIZACAO (MamuteXiGui.pbi, decisao explicita do usuario via pergunta
; direta - sem edicao/pilha de jump-call, isso fica pra depois); DOIS/TRES
; campos despejam o disassembly em texto sem abrir tela nenhuma. <fim>
; omitido tambem assume 256 bytes (mesma regra do XD/XA, modulo 45h).
; Diferenca de verdade contra XD/XA no terceiro campo: o `<arquivo>` do XI
; NAO abre o dialogo do SAVE (que so' faz sentido pra bytes crus) - grava a
; LISTAGEM de texto do disassembly direto (Mamute_SaveTextListing(),
; MamuteSupport.pbi), decisao confirmada com o usuario via pergunta direta.
Procedure MamuteGui_CmdXi(Win, G_Log, *State.MamuteGui_State, Args.s, PrinterMode.b = #False)
  Protected Trimmed.s = Trim(Args)
  Protected CommaPos.i = FindString(Trimmed, ",")

  If CommaPos > 0
    Protected StartAddr.i, EndAddr.i
    Protected DumpTarget.MamuteSxTarget
    Protected StartTok.s = Trim(Left(Trimmed, CommaPos - 1))
    Protected FieldCount.i = CountString(Trimmed, ",") + 1
    Protected Field2.s = Trim(StringField(Trimmed, 2, ","))
    Protected Field3.s = ""
    If FieldCount >= 3 : Field3 = Trim(StringField(Trimmed, 3, ",")) : EndIf
    Protected FileTok.s = ""
    Protected SyntaxOk.b = #True

    If FieldCount > 3 Or Not Mamute_ParseSxAddr(StartTok, @StartAddr, @DumpTarget)
      SyntaxOk = #False
    ElseIf Mamute_ParseHexAddr(Field2, @EndAddr)
      If EndAddr < StartAddr Or (FieldCount = 3 And Field3 = "")
        SyntaxOk = #False
      Else
        FileTok = Field3
      EndIf
    ElseIf Field2 = ""
      EndAddr = StartAddr + 255
      If EndAddr > Mamute_SxMaxAddr(@DumpTarget) : EndAddr = Mamute_SxMaxAddr(@DumpTarget) : EndIf
      FileTok = Field3
    ElseIf FieldCount = 2
      EndAddr = StartAddr + 255
      If EndAddr > Mamute_SxMaxAddr(@DumpTarget) : EndAddr = Mamute_SxMaxAddr(@DumpTarget) : EndIf
      FileTok = Field2
    Else
      SyntaxOk = #False
    EndIf

    If Not SyntaxOk
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf

    Protected NewList XiLines.s()
    Protected NextA.i
    Mamute_DisasmBuildLines(XiLines(), StartAddr, #True, EndAddr, @NextA, @DumpTarget)

    If FileTok <> ""
      If PrinterMode
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?IMPRESSAO NAO APLICAVEL A ESTE COMANDO")
        ProcedureReturn
      EndIf

      Protected Header2.s = "XI " + Mamute_Hex4(StartAddr) + "-" + Mamute_Hex4(EndAddr)
      If Mamute_SaveTextListing(FileTok, XiLines(), Header2)
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
          "SALVO " + Chr(34) + FileTok + Chr(34) + " - " + Mamute_Hex4(StartAddr) + "-" + Mamute_Hex4(EndAddr))
      Else
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO AO GRAVAR ARQUIVO")
      EndIf
      ProcedureReturn
    EndIf

    If PrinterMode
      ; "?XI" = "impressora" do SUPER-X, que aqui vira PDF - mesma tecnica
      ; do XD/XA/P (Mamute_SavePdfListing, modulo 31).
      Protected FilePath.s = SaveFileRequester("Salvar listagem (?XI) como PDF", "listagem_xi.pdf", "PDF (*.pdf)|*.pdf", 0)
      If FilePath = ""
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "CANCELADO")
        ProcedureReturn
      EndIf
      If LCase(Right(FilePath, 4)) <> ".pdf"
        FilePath + ".pdf"
      EndIf
      Protected Header.s = "?XI " + Mamute_Hex4(StartAddr) + "-" + Mamute_Hex4(EndAddr)
      If Mamute_SavePdfListing(FilePath, XiLines(), Header)
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "PDF GRAVADO: " + FilePath)
      Else
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO AO GRAVAR PDF")
      EndIf
      ProcedureReturn
    EndIf

    ForEach XiLines()
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, XiLines())
    Next
    ProcedureReturn
  EndIf

  If PrinterMode
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?IMPRESSAO SO FUNCIONA COM DOIS ENDERECOS (XI <inic>,<fim>)")
    ProcedureReturn
  EndIf

  Protected Addr.i
  Protected Target.MamuteSxTarget
  If Trimmed = ""
    If Not *State\HasLastXi
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
    Addr = *State\LastXiAddr
    CopyStructure(@*State\LastXiTarget, @Target, MamuteSxTarget)
  Else
    If Not Mamute_ParseSxAddr(Trimmed, @Addr, @Target)
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
  EndIf

  Mamute_VarStoreBase(Addr, @Target) ; "commands store base address in variable 0", doc do SUPER-X
  *State\LastXiAddr = MamuteXi_Open(Win, Addr, @Target)
  CopyStructure(@Target, @*State\LastXiTarget, MamuteSxTarget)
  *State\HasLastXi = #True
EndProcedure

; XM [<endereco>] - porta do comando M do SUPER-X (docs/SPEC.md modulo 45;
; nao confundir com o M do proprio Mamute, modulo 31, que e outra coisa).
; Abre a janela interativa MamuteXmGui.pbi - endereco atual + entrada
; assembler/dados, avancando sozinho a cada linha aceita. Sem argumento,
; reabre onde a janela do XM ficou da ultima vez (mesmo idioma do M/S/XD).
Procedure MamuteGui_CmdXm(Win, G_Log, *State.MamuteGui_State, Args.s)
  Protected Trimmed.s = Trim(Args)
  Protected Addr.i
  Protected Target.MamuteSxTarget
  If Trimmed = ""
    If Not *State\HasLastXm
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
    Addr = *State\LastXmAddr
    CopyStructure(@*State\LastXmTarget, @Target, MamuteSxTarget)
  Else
    If Not Mamute_ParseSxAddr(Trimmed, @Addr, @Target)
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
  EndIf

  Mamute_VarStoreBase(Addr, @Target) ; "commands store base address in variable 0", doc do SUPER-X
  *State\LastXmAddr = MamuteXm_Open(Win, Addr, @Target)
  CopyStructure(@Target, @*State\LastXmTarget, MamuteSxTarget)
  *State\HasLastXm = #True
EndProcedure

; XH [<endereco>] - porta do comando H do SUPER-X (docs/SPEC.md modulo 45/45f)
; - o editor de caracteres/sprites, ultimo placeholder "Char" da cruz de
; modos. Abre a janela interativa MamuteXhGui.pbi, editando os 4 caracteres/
; sprites consecutivos a partir do endereco (32 bytes). Sem argumento, reabre
; onde a janela do XH ficou da ultima vez (mesmo idioma do M/S/XD/XA/XI/XM).
Procedure MamuteGui_CmdXh(Win, G_Log, *State.MamuteGui_State, Args.s)
  Protected Trimmed.s = Trim(Args)
  Protected Addr.i
  Protected Target.MamuteSxTarget
  If Trimmed = ""
    If Not *State\HasLastXh
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
    Addr = *State\LastXhAddr
    CopyStructure(@*State\LastXhTarget, @Target, MamuteSxTarget)
  Else
    If Not Mamute_ParseSxAddr(Trimmed, @Addr, @Target)
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
      ProcedureReturn
    EndIf
  EndIf

  Mamute_VarStoreBase(Addr, @Target) ; "commands store base address in variable 0", doc do SUPER-X
  *State\LastXhAddr = MamuteXh_Open(Win, Addr, @Target)
  CopyStructure(@Target, @*State\LastXhTarget, MamuteSxTarget)
  *State\HasLastXh = #True
EndProcedure

; XBT <endinic>[#slot[-subslot]|#V|#4|#S|#5],<endfim>,<enddest>[#slot[-subslot]|
; #V|#4|#S|#5] - transfere o bloco [endinic,endfim] pra um novo bloco iniciado
; em <enddest>, pedido explicito do usuario: "inclusive intra-slots" - origem
; e destino podem ter alvos (slot/sub-slot/VRAM) DIFERENTES um do outro, cada
; um resolvido de forma independente (Mamute_ParseSxAddr), ao contrario do T
; comum (modulo 31), que so trabalha PAGE-relativo com um unico endereco de
; 16 bits pros tres tokens. Batizado XBT (nao XT) por pedido explicito do
; usuario - "BT" de "Block Transfer", pra nao colidir com o T do proprio
; Mamute nem com nenhum outro comando SUPER-X ja portado.
;
; <endfim> e' um endereco PURO (sem sufixo de alvo) - sempre no MESMO alvo que
; <endinic> ja resolveu, exatamente como o Field2 do modo "dois enderecos" do
; XD/XA (docs/SPEC.md modulo 45g) - so' faz sentido delimitar o FIM de um
; bloco que comeca num alvo ja escolhido, nao um alvo proprio. Aceita ate 5
; digitos quando <endinic> mirou VRAM (Mamute_ParseVramAddr), 4 digitos nos
; outros casos (Mamute_ParseHexAddr) - mesma logica de Mamute_SxMaxAddr().
;
; Sem wraparound nenhum dos dois lados (mesma regra do T/D/P/V) - <enddest> +
; tamanho do bloco passando do teto do ALVO DE DESTINO (Mamute_SxMaxAddr) e
; ?ERRO DE SINTAXE, nunca da a volta. Cruza slot/sub-slot/VRAM livremente -
; "intra-slots" pedido explicito do usuario.
;
; Direcao da copia (tras-pra-frente quando <enddest> numericamente MAIOR que
; <endinic>, frente-pra-tras senao) sempre a mesma logica segura de um memmove
; do T comum - continua correta mesmo quando origem/destino sao alvos
; DIFERENTES (nesse caso nao ha sobreposicao de verdade nenhuma, entao a
; direcao escolhida nao muda o resultado, so' o T ja fazia essa comparacao
; simples, sem precisar detectar "e' o mesmo alvo?" primeiro).
Procedure MamuteGui_CmdXbt(G_Log, *State.MamuteGui_State, Args.s)
  Protected CommaPos1.i = FindString(Args, ",")
  If CommaPos1 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected Rest1.s = Mid(Args, CommaPos1 + 1)
  Protected CommaPos2.i = FindString(Rest1, ",")
  If CommaPos2 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected StartToken.s = Trim(Left(Args, CommaPos1 - 1))
  Protected EndToken.s = Trim(Left(Rest1, CommaPos2 - 1))
  Protected DestToken.s = Trim(Mid(Rest1, CommaPos2 + 1))

  Protected StartAddr.i, EndAddr.i, DestAddr.i
  Protected SrcTarget.MamuteSxTarget, DestTarget.MamuteSxTarget

  If Not Mamute_ParseSxAddr(StartToken, @StartAddr, @SrcTarget)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected EndOk.b
  If SrcTarget\IsVram
    EndOk = Mamute_ParseVramAddr(EndToken, @EndAddr)
  Else
    EndOk = Mamute_ParseHexAddr(EndToken, @EndAddr)
  EndIf
  If Not EndOk Or EndAddr < StartAddr
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  If Not Mamute_ParseSxAddr(DestToken, @DestAddr, @DestTarget)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected Length.i = EndAddr - StartAddr + 1
  If DestAddr + Length - 1 > Mamute_SxMaxAddr(@DestTarget)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected i.i
  If DestAddr > StartAddr
    For i = Length - 1 To 0 Step -1
      Mamute_SxWriteByte(DestAddr + i, Mamute_SxReadByte(StartAddr + i, @SrcTarget), @DestTarget)
    Next
  Else
    For i = 0 To Length - 1
      Mamute_SxWriteByte(DestAddr + i, Mamute_SxReadByte(StartAddr + i, @SrcTarget), @DestTarget)
    Next
  EndIf

  Protected SrcDigits.i = 4
  If SrcTarget\IsVram : SrcDigits = 5 : EndIf
  Protected DestDigits.i = 4
  If DestTarget\IsVram : DestDigits = 5 : EndIf

  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "TRANSFERIDO " + Mamute_HexPad(StartAddr, SrcDigits) + Mamute_SxTargetSuffixText(@SrcTarget) + "-" +
    Mamute_HexPad(EndAddr, SrcDigits) + Mamute_SxTargetSuffixText(@SrcTarget) + " PARA " +
    Mamute_HexPad(DestAddr, DestDigits) + Mamute_SxTargetSuffixText(@DestTarget))
EndProcedure

; XRT <endinic>[#slot[-subslot]|#V|#4|#S|#5],<endfim>,<enddest>[#slot[-subslot]|
; #V|#4|#S|#5] - "Relocating Transfer": mesma sintaxe de 3 campos do XBT (ao
; lado), mas em vez de copiar os bytes crus, RELOCALIZA um programa Z80 -
; decodifica cada instrucao do bloco [endinic,endfim] (motor de disassembly
; do L/LP/XI, Mamute_DisasmOne(), so pra descobrir o TAMANHO de cada
; instrucao - nao usa o texto formatado) e, pra cada instrucao que carrega um
; endereco absoluto de 16 bits (JP/CALL/JP cc/CALL cc, LD dd,nn, LD (nn),HL/
; LD HL,(nn)/LD (nn),A/LD A,(nn), formas estendidas ED/DD/FD equivalentes -
; em TODAS elas o endereco sao sempre os ULTIMOS 2 bytes da instrucao, o que
; simplifica bastante o patch), soma o deslocamento (<enddest>-<endinic>) SE
; e SO SE o endereco embutido cair DENTRO de [endinic,endfim] - pedido
; explicito do usuario: "CALL 8012 -> CALL C012" ao mover 8000->C000, mas
; "CALL 4D" (BIOS, fora do intervalo) fica intocado. JR/DJNZ (saltos
; RELATIVOS) nao precisam de ajuste quando o alvo tambem esta dentro do
; bloco (fonte E destino se movem juntos, mesma distancia relativa) - so'
; recalcula o deslocamento quando o alvo de um JR/DJNZ fica FORA do bloco
; (salto pra codigo fixo externo), abortando com erro se o novo deslocamento
; nao couber em -128..127 (nada e' gravado nesse caso - todo o bloco e' lido
; pra um buffer local e decodificado ANTES de qualquer escrita no destino,
; entao um erro no meio da decodificacao nunca deixa o destino pela metade).
;
; Limitacao aceita, documentada (mesma classe de limitacao ja assumida pelo
; disassembler do L/LP/XI - "nao da pra decodificar Z80 de forma 100%
; confiavel sem executar de verdade"): tabelas de dados inline (DEFW com
; enderecos de salto, por exemplo) NO MEIO do codigo sao lidas como se fossem
; instrucao, podendo confundir a decodificacao dali em diante - relocar um
; bloco assim pode produzir resultado errado. Funciona bem pro caso comum
; (codigo assembly continuo, sem dados misturados no meio do fluxo).
Procedure MamuteGui_CmdXrt(G_Log, *State.MamuteGui_State, Args.s)
  Protected CommaPos1.i = FindString(Args, ",")
  If CommaPos1 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected Rest1.s = Mid(Args, CommaPos1 + 1)
  Protected CommaPos2.i = FindString(Rest1, ",")
  If CommaPos2 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected StartToken.s = Trim(Left(Args, CommaPos1 - 1))
  Protected EndToken.s = Trim(Left(Rest1, CommaPos2 - 1))
  Protected DestToken.s = Trim(Mid(Rest1, CommaPos2 + 1))

  Protected StartAddr.i, EndAddr.i, DestAddr.i
  Protected SrcTarget.MamuteSxTarget, DestTarget.MamuteSxTarget

  If Not Mamute_ParseSxAddr(StartToken, @StartAddr, @SrcTarget)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected EndOk.b
  If SrcTarget\IsVram
    EndOk = Mamute_ParseVramAddr(EndToken, @EndAddr)
  Else
    EndOk = Mamute_ParseHexAddr(EndToken, @EndAddr)
  EndIf
  If Not EndOk Or EndAddr < StartAddr
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  If Not Mamute_ParseSxAddr(DestToken, @DestAddr, @DestTarget)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected Length.i = EndAddr - StartAddr + 1
  If DestAddr + Length - 1 > Mamute_SxMaxAddr(@DestTarget)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected Delta.i = DestAddr - StartAddr

  ; Le o bloco INTEIRO pra um buffer local antes de mexer no destino - source
  ; e destino podem se sobrepor (mesmo alvo, faixas cruzadas) sem risco
  ; nenhum de corromper nada no meio da decodificacao, e um erro (JR fora de
  ; alcance, abaixo) pode abortar sem ter gravado nada ainda.
  Protected Dim Buf.a(Length - 1)
  Protected k.i
  For k = 0 To Length - 1
    Buf(k) = Mamute_SxReadByte(StartAddr + k, @SrcTarget)
  Next

  Protected CurAddr.i, InstrLen.i, DiscardText.s
  Protected b0.a, b1.a
  Protected IsAbsPatch.b, IsRelJump.b, Truncated.b
  Protected AbsVal.i, RelSigned.i, OldTarget.i, NewInstrAddr.i, NewRel.i
  Protected PatchCount.i = 0

  k = 0
  While k < Length
    CurAddr = StartAddr + k
    DiscardText = Mamute_DisasmOne(CurAddr, @InstrLen, @SrcTarget)
    If InstrLen <= 0 : InstrLen = 1 : EndIf ; guarda defensiva - nunca deveria acontecer, a tabela do disassembler cobre todo opcode

    Truncated = Bool(k + InstrLen > Length)
    If Truncated
      InstrLen = Length - k ; <endfim> nao alinhado com o fim de uma instrucao - so copia o resto sem tentar remendar
    EndIf

    IsAbsPatch = #False
    IsRelJump = #False
    b0 = Buf(k)
    If Not Truncated
      Select b0
        Case $C3, $CD, $C2, $CA, $D2, $DA, $E2, $EA, $F2, $FA, $C4, $CC, $D4, $DC, $E4, $EC, $F4, $FC,
             $01, $11, $21, $31, $22, $2A, $32, $3A
          IsAbsPatch = #True

        Case $ED
          If InstrLen >= 2
            b1 = Buf(k + 1)
            Select b1
              Case $43, $4B, $53, $5B, $63, $6B, $73, $7B
                IsAbsPatch = #True
            EndSelect
          EndIf

        Case $DD, $FD
          If InstrLen >= 2
            b1 = Buf(k + 1)
            Select b1
              Case $21, $22, $2A
                IsAbsPatch = #True
            EndSelect
          EndIf

        Case $18, $20, $28, $30, $38, $10 ; JR e / JR cc,e / DJNZ e
          IsRelJump = #True
      EndSelect
    EndIf

    If IsAbsPatch And InstrLen >= 2
      AbsVal = Buf(k + InstrLen - 2) | (Buf(k + InstrLen - 1) << 8)
      If AbsVal >= StartAddr And AbsVal <= EndAddr
        AbsVal = (AbsVal + Delta) & $FFFF
        Buf(k + InstrLen - 2) = AbsVal & $FF
        Buf(k + InstrLen - 1) = (AbsVal >> 8) & $FF
        PatchCount + 1
      EndIf

    ElseIf IsRelJump And InstrLen = 2
      RelSigned = Buf(k + 1)
      If RelSigned > 127 : RelSigned - 256 : EndIf
      OldTarget = (CurAddr + 2 + RelSigned) & $FFFF
      If OldTarget < StartAddr Or OldTarget > EndAddr
        ; alvo fica FORA do bloco (salto pra codigo fixo externo) - o
        ; deslocamento relativo precisa mudar, ja que a instrucao em si vai
        ; se mover mas o alvo externo nao.
        NewInstrAddr = DestAddr + k
        NewRel = OldTarget - (NewInstrAddr + 2)
        If NewRel < -128 Or NewRel > 127
          *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
            "?RELOCACAO INVALIDA: JR/DJNZ EM " + Mamute_Hex4(CurAddr) + " NAO ALCANCA O ALVO EXTERNO " +
            Mamute_Hex4(OldTarget) + " DEPOIS DE MOVER (FORA DE -128..127)")
          ProcedureReturn
        EndIf
        Buf(k + 1) = NewRel & $FF
        PatchCount + 1
      EndIf
    EndIf

    k + InstrLen
  Wend

  Protected wi.i
  For wi = 0 To Length - 1
    Mamute_SxWriteByte(DestAddr + wi, Buf(wi), @DestTarget)
  Next

  Protected SrcDigits2.i = 4
  If SrcTarget\IsVram : SrcDigits2 = 5 : EndIf
  Protected DestDigits2.i = 4
  If DestTarget\IsVram : DestDigits2 = 5 : EndIf

  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "RELOCADO " + Mamute_HexPad(StartAddr, SrcDigits2) + Mamute_SxTargetSuffixText(@SrcTarget) + "-" +
    Mamute_HexPad(EndAddr, SrcDigits2) + Mamute_SxTargetSuffixText(@SrcTarget) + " PARA " +
    Mamute_HexPad(DestAddr, DestDigits2) + Mamute_SxTargetSuffixText(@DestTarget) +
    " (" + Str(PatchCount) + " PONTEIRO(S) AJUSTADO(S))")
EndProcedure

; XFL <endinic>[#slot[-subslot]|#V|#4|#S|#5],<endfim>,<valor> - versao do F
; comum (modulo 31, ao lado) que entende o enderecamento estendido do
; SUPER-X: preenche [endinic,endfim] inteiro com <valor> (1-2 digitos hexa)
; no ALVO explicito informado (slot/sub-slot/VRAM), em vez de sempre PAGE-
; relativo. <endfim> e' sempre um endereco PURO (sem sufixo), no MESMO alvo
; que <endinic> ja escolheu - mesma convencao do XBT/XRT (ao lado).
Procedure MamuteGui_CmdXfl(G_Log, *State.MamuteGui_State, Args.s)
  Protected CommaPos1.i = FindString(Args, ",")
  If CommaPos1 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected Rest1.s = Mid(Args, CommaPos1 + 1)
  Protected CommaPos2.i = FindString(Rest1, ",")
  If CommaPos2 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected StartToken.s = Trim(Left(Args, CommaPos1 - 1))
  Protected EndToken.s = Trim(Left(Rest1, CommaPos2 - 1))
  Protected ByteToken.s = Trim(Mid(Rest1, CommaPos2 + 1))

  Protected StartAddr.i, EndAddr.i
  Protected Target.MamuteSxTarget

  If Not Mamute_ParseSxAddr(StartToken, @StartAddr, @Target)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected EndOk.b
  If Target\IsVram
    EndOk = Mamute_ParseVramAddr(EndToken, @EndAddr)
  Else
    EndOk = Mamute_ParseHexAddr(EndToken, @EndAddr)
  EndIf
  If Not EndOk Or EndAddr < StartAddr
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  If Not Mamute_IsHexString(ByteToken, 2)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected FillByte.i = Val("$" + ByteToken)

  Protected Addr.i
  For Addr = StartAddr To EndAddr
    Mamute_SxWriteByte(Addr, FillByte, @Target)
  Next

  Protected Digits.i = 4
  If Target\IsVram : Digits = 5 : EndIf

  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "PREENCHIDO " + Mamute_HexPad(StartAddr, Digits) + Mamute_SxTargetSuffixText(@Target) + "-" +
    Mamute_HexPad(EndAddr, Digits) + Mamute_SxTargetSuffixText(@Target) + " COM " + Mamute_Hex2(FillByte))
EndProcedure

; XCM <endinic>[#slot[-subslot]|#V|#4|#S|#5],<endfim>,<endcomp>[#slot[-subslot]|
; #V|#4|#S|#5][,S] - compara byte a byte o bloco [endinic,endfim] com o bloco
; de mesmo tamanho comecando em <endcomp> (alvo TOTALMENTE independente,
; "intra-slots" como o XBT/XRT/XFL, ao lado). Por padrao lista so' os bytes
; DIFERENTES (endereco+valor dos dois lados); ",S" no final (pedido explicito
; do usuario) inverte pro modo "iguais" - lista so' os bytes que BATEM.
; <endfim> e' sempre um endereco puro, no MESMO alvo que <endinic> ja
; escolheu (mesma convencao do XBT/XRT/XFL).
Procedure MamuteGui_CmdXcm(G_Log, *State.MamuteGui_State, Args.s)
  Protected CommaPos1.i = FindString(Args, ",")
  If CommaPos1 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected Rest1.s = Mid(Args, CommaPos1 + 1)
  Protected CommaPos2.i = FindString(Rest1, ",")
  If CommaPos2 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected StartToken.s = Trim(Left(Args, CommaPos1 - 1))
  Protected EndToken.s = Trim(Left(Rest1, CommaPos2 - 1))
  Protected Rest2.s = Mid(Rest1, CommaPos2 + 1)

  ; Quarto campo ",S" e' opcional - so procura uma TERCEIRA virgula dentro do
  ; que sobrou depois do segundo campo.
  Protected CompareToken.s, FlagToken.s
  Protected CommaPos3.i = FindString(Rest2, ",")
  If CommaPos3 > 0
    CompareToken = Trim(Left(Rest2, CommaPos3 - 1))
    FlagToken = UCase(Trim(Mid(Rest2, CommaPos3 + 1)))
  Else
    CompareToken = Trim(Rest2)
    FlagToken = ""
  EndIf
  If FlagToken <> "" And FlagToken <> "S"
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected ShowEqual.b = Bool(FlagToken = "S")

  Protected StartAddr.i, EndAddr.i, CompAddr.i
  Protected SrcTarget.MamuteSxTarget, CompTarget.MamuteSxTarget

  If Not Mamute_ParseSxAddr(StartToken, @StartAddr, @SrcTarget)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected EndOk.b
  If SrcTarget\IsVram
    EndOk = Mamute_ParseVramAddr(EndToken, @EndAddr)
  Else
    EndOk = Mamute_ParseHexAddr(EndToken, @EndAddr)
  EndIf
  If Not EndOk Or EndAddr < StartAddr
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  If Not Mamute_ParseSxAddr(CompareToken, @CompAddr, @CompTarget)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected Length.i = EndAddr - StartAddr + 1
  If CompAddr + Length - 1 > Mamute_SxMaxAddr(@CompTarget)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected SrcDigits.i = 4
  If SrcTarget\IsVram : SrcDigits = 5 : EndIf
  Protected CompDigits.i = 4
  If CompTarget\IsVram : CompDigits = 5 : EndIf

  Protected i.i, AddrA.i, AddrB.i, ValA.a, ValB.a, IsMatch.b, Op.s
  Protected Hits.i = 0
  For i = 0 To Length - 1
    AddrA = StartAddr + i
    AddrB = CompAddr + i
    ValA = Mamute_SxReadByte(AddrA, @SrcTarget)
    ValB = Mamute_SxReadByte(AddrB, @CompTarget)
    IsMatch = Bool(ValA = ValB)
    If (ShowEqual And IsMatch) Or (Not ShowEqual And Not IsMatch)
      If IsMatch : Op = "==" : Else : Op = "<>" : EndIf
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
        Mamute_HexPad(AddrA, SrcDigits) + Mamute_SxTargetSuffixText(@SrcTarget) + ": " + Mamute_Hex2(ValA) +
        " " + Op + " " +
        Mamute_HexPad(AddrB, CompDigits) + Mamute_SxTargetSuffixText(@CompTarget) + ": " + Mamute_Hex2(ValB))
      Hits + 1
    EndIf
  Next

  If ShowEqual
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, Str(Hits) + " BYTE(S) IGUAL(IS)")
  Else
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, Str(Hits) + " DIFERENCA(S) ENCONTRADA(S)")
  EndIf
EndProcedure

; XFD <endinic>[#slot[-subslot]|#V|#4|#S|#5],<endfim> - "Find": pede (via
; InputRequester(), pedido explicito do usuario - "o sistema pede uma
; instrucao em ASM") uma UNICA instrucao Z80 e lista todo endereco dentro de
; [endinic,endfim] onde essa MESMA instrucao (opcode + operando, byte a
; byte) aparece.
;
; Monta a instrucao digitada UMA vez so (Z80Asm::ParseLine+EncodeInstruction,
; mesmo motor do XM/comando A) ancorada em <endinic> - suficiente pra
; qualquer instrucao com operando ABSOLUTO (CALL/JP/LD nn/etc., que codificam
; sempre os MESMOS bytes independente de onde ficam). *Limitacao aceita*:
; JR/DJNZ (saltos RELATIVOS) codificam bytes DIFERENTES dependendo de onde
; ficam - a busca funciona, mas so' acha ocorrencias na MESMA distancia
; relativa da instrucao digitada, nao "todo JR pro mesmo alvo absoluto"
; (limitacao documentada, mesmo espirito do aviso ja existente no `XRT`).
;
; So conta como ocorrencia uma instrucao REAL, alinhada num limite de
; instrucao de verdade (decodificada via Mamute_DisasmOne(), mesmo motor do
; L/LP/XI/XRT) - nao uma busca de bytes crua tipo o `SH`, que acharia
; coincidencias no MEIO de outra instrucao/dado.
Procedure MamuteGui_CmdXfd(Win, G_Log, *State.MamuteGui_State, Args.s)
  Protected CommaPos1.i = FindString(Args, ",")
  If CommaPos1 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected StartToken.s = Trim(Left(Args, CommaPos1 - 1))
  Protected EndToken.s = Trim(Mid(Args, CommaPos1 + 1))
  If FindString(EndToken, ",") > 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected StartAddr.i, EndAddr.i
  Protected Target.MamuteSxTarget

  If Not Mamute_ParseSxAddr(StartToken, @StartAddr, @Target)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected EndOk.b
  If Target\IsVram
    EndOk = Mamute_ParseVramAddr(EndToken, @EndAddr)
  Else
    EndOk = Mamute_ParseHexAddr(EndToken, @EndAddr)
  EndIf
  If Not EndOk Or EndAddr < StartAddr
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected InstrText.s = Trim(InputRequester("XFD - Buscar instrucao", "Instrucao Z80 a procurar:", ""))
  If InstrText = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "CANCELADO")
    ProcedureReturn
  EndIf

  Z80Asm::ResetState() ; limpa qualquer estado deixado por um "Montar" (EDIT)/XM anterior
  Protected PL.Z80Asm::Z80ParsedLine
  Z80Asm::ParseLine(InstrText, @PL)
  If PL\IsBlank Or Not PL\HasOperator Or PL\HasLabel
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Z80Asm::SetCurrentLocation(StartAddr)
  Dim PatBytes.a(3)
  Protected PatLen.i = Z80Asm::EncodeInstruction(PL\Operator, PL\ArgsText, #True, PatBytes())
  If PatLen <= 0
    Protected AsmErr.s = Z80Asm::GetLastAsmError()
    If AsmErr = "" : AsmErr = "ERRO DE SINTAXE" : EndIf
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?" + AsmErr)
    ProcedureReturn
  EndIf

  Protected Digits.i = 4
  If Target\IsVram : Digits = 5 : EndIf

  Protected Length.i = EndAddr - StartAddr + 1
  Protected CurAddr.i, InstrLen.i, DisasmText.s
  Protected k.i = 0
  Protected Hits.i = 0
  Protected MatchOk.b, bi.i

  While k < Length
    CurAddr = StartAddr + k
    DisasmText = Mamute_DisasmOne(CurAddr, @InstrLen, @Target)
    If InstrLen <= 0 : InstrLen = 1 : EndIf
    If k + InstrLen > Length : Break : EndIf ; instrucao nao cabe inteira dentro do intervalo - para, nao conta parcial

    MatchOk = Bool(InstrLen = PatLen)
    If MatchOk
      For bi = 0 To PatLen - 1
        If Mamute_SxReadByte(CurAddr + bi, @Target) <> PatBytes(bi)
          MatchOk = #False
          Break
        EndIf
      Next
    EndIf

    If MatchOk
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
        Mamute_HexPad(CurAddr, Digits) + Mamute_SxTargetSuffixText(@Target) + ": " + DisasmText)
      Hits + 1
    EndIf

    k + InstrLen
  Wend

  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, Str(Hits) + " OCORRENCIA(S) ENCONTRADA(S)")
EndProcedure

; XCO [<frente>],[<fundo>],[<borda>] - porta do CO do SUPER-X (batizado XCO,
; nao CO - decisao explicita do usuario logo apos a implementacao inicial,
; pra ficar consistente com o prefixo X de todo o resto dos comandos
; portados do SUPER-X nesta sessao: XD/XA/XI/XH/XM/XGO/XTR/XSD/XRG/XTS/XCS/
; XBT/XRT/XFL/XCM/XFD) (inventario do modulo 45: "Cor da tela") - pedido
; explicito do usuario: "podendo mudar a
; cor geral do mamute assembly, pelo menos na parte interna de display e de
; entrada de comandos e das janelas extras de comandos". Troca a paleta do
; Mamute Assembler INTEIRO - monitor principal (log/entrada de comandos),
; XD/XM/XA/XI/XH, debugger grafico, DM/ZAP/SCR/M/EDIT - toda janela do
; Mamute agora le Mamute_CurrentFrontColor()/Mamute_CurrentBackColor()/
; Mamute_CurrentBorderColor() (MamuteSupport.pbi) em vez do RGB() hardcoded
; que cada uma tinha localmente antes (achado real: 72 ocorrencias em 12
; arquivos diferentes, todas migradas nesta sessao).
;
; <frente>/<fundo>/<borda> sao indices 0-15 da paleta REAL, FIXA, do MSX1/
; TMS9918 (Mamute_Msx1PaletteRGB()) - **DECIMAL, nao hexa**, de proposito:
; mesma convencao do `COLOR frente,fundo,borda` do MSX BASIC de verdade
; (o `XCO` PORTA um comando de cor de tela MSX - faz sentido seguir a
; convencao de cor do MSX, nao a convencao hexadecimal do resto do monitor).
; Qualquer um dos 3 pode ficar VAZIO (virgula sem nada, ou omitido no final)
; - mantem o valor atual dessa cor sozinho, mesma convencao do `COLOR`
; original (so muda o que foi informado). Sem argumento nenhum, so mostra o
; estado atual.
;
; Nao repinta janela nenhuma JA ABERTA - vale a partir da PROXIMA janela
; aberta (mesmo espirito de outras configuracoes "estaticas" do Mamute, ex.:
; fonte). Persistido em mamute_settings.json (MamuteCfg_Save, ja existente)
; - sobrevive entre sessoes, diferente do XCS/DisplayMode (esses continuam
; volateis de proposito).
Procedure MamuteGui_CmdXco(G_Log, *State.MamuteGui_State, Args.s)
  Protected Trimmed.s = Trim(Args)

  If Trimmed = ""
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
      "XCO " + Str(MamuteColorFg) + "," + Str(MamuteColorBg) + "," + Str(MamuteColorBorder))
    ProcedureReturn
  EndIf

  If CountString(Trimmed, ",") > 2
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected Dim Tok.s(2)
  Tok(0) = Trim(StringField(Trimmed, 1, ","))
  Tok(1) = Trim(StringField(Trimmed, 2, ","))
  Tok(2) = Trim(StringField(Trimmed, 3, ","))

  Protected NewFg.i = MamuteColorFg, NewBg.i = MamuteColorBg, NewBorder.i = MamuteColorBorder
  Protected i.i, k.i, V.i, Valid.b

  For i = 0 To 2
    If Tok(i) <> ""
      Valid = Bool(Len(Tok(i)) <= 2)
      If Valid
        For k = 1 To Len(Tok(i))
          If Mid(Tok(i), k, 1) < "0" Or Mid(Tok(i), k, 1) > "9"
            Valid = #False
          EndIf
        Next
      EndIf
      If Valid
        V = Val(Tok(i))
        If V < 0 Or V > 15 : Valid = #False : EndIf
      EndIf
      If Not Valid
        *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
        ProcedureReturn
      EndIf
      Select i
        Case 0 : NewFg = V
        Case 1 : NewBg = V
        Case 2 : NewBorder = V
      EndSelect
    EndIf
  Next

  MamuteColorFg = NewFg
  MamuteColorBg = NewBg
  MamuteColorBorder = NewBorder
  MamuteCfg_Save()

  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
    "XCO " + Str(MamuteColorFg) + "," + Str(MamuteColorBg) + "," + Str(MamuteColorBorder) +
    " - vale a partir da proxima janela aberta")
EndProcedure

; XCS - alterna o tipo de calculo do checksum usado pelo despejo do XD
; (`XD <endinic>,<endfim>`, Mamute_BuildDumpLinesSx()) - pedido explicito do
; usuario: "normal" (soma so' os bytes da linha) <-> "+ADDR" (soma tambem o
; byte baixo do endereco da linha, checksum de 8 bits/1 byte). Sem
; argumentos - so alterna e confirma no log, mesmo idioma do PAGE/C ecoando
; o estado apos uma mudanca. Dura so' esta sessao da janela (nao persiste em
; mamute_settings.json, mesmo espirito volatil do PAGE/DisplayMode).
Procedure MamuteGui_CmdXcs(G_Log, *State.MamuteGui_State)
  *State\ChecksumAddrMode = Bool(Not *State\ChecksumAddrMode)
  Protected ModeText.s = "NORMAL (soma so os bytes)"
  If *State\ChecksumAddrMode : ModeText = "+ADDR (soma tambem o byte baixo do endereco)" : EndIf
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "CHECKSUM: " + ModeText)
EndProcedure

; XTS <endinic>[#slot[-subslot]|#V|#4|#S|#5],<endfim> - calcula UM checksum
; agregado do bloco [endinic,endfim] inteiro (soma de TODOS os bytes, 16
; bits, com wraparound - mesma convencao numerica do CL, ao lado) e mostra o
; resultado nos MESMOS 4 formatos do CL (HEX/BIN/DEC+/DEC+-) mais OCTAL -
; pedido explicito do usuario. Diferente do checksum POR LINHA do despejo do
; XD (8 bits, comando XCS) - este e' um unico valor de 16 bits pro bloco
; inteiro, mais util pra comparar/verificar a integridade de um bloco
; inteiro (ex.: um ROM) de uma vez, nao linha a linha. <endfim> e' sempre um
; endereco puro, no MESMO alvo que <endinic> ja escolheu (mesma convencao do
; XBT/XRT/XFL/XCM/XFD).
Procedure MamuteGui_CmdXts(G_Log, *State.MamuteGui_State, Args.s)
  Protected CommaPos1.i = FindString(Args, ",")
  If CommaPos1 = 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf
  Protected StartToken.s = Trim(Left(Args, CommaPos1 - 1))
  Protected EndToken.s = Trim(Mid(Args, CommaPos1 + 1))
  If FindString(EndToken, ",") > 0
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected StartAddr.i, EndAddr.i
  Protected Target.MamuteSxTarget

  If Not Mamute_ParseSxAddr(StartToken, @StartAddr, @Target)
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected EndOk.b
  If Target\IsVram
    EndOk = Mamute_ParseVramAddr(EndToken, @EndAddr)
  Else
    EndOk = Mamute_ParseHexAddr(EndToken, @EndAddr)
  EndIf
  If Not EndOk Or EndAddr < StartAddr
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  Protected Sum.i = 0
  Protected Addr.i
  For Addr = StartAddr To EndAddr
    Sum + Mamute_SxReadByte(Addr, @Target)
  Next
  Sum = Sum & $FFFF

  Protected Signed.i = Sum
  If Signed >= $8000 : Signed - $10000 : EndIf

  ; PureBasic nao tem Oct() nativo (so Hex()/Bin()) - converte a mao, digito
  ; a digito, do jeito classico (resto da divisao por 8, do fim pro comeco).
  Protected OctStr.s = ""
  Protected OctTemp.i = Sum
  If OctTemp = 0
    OctStr = "0"
  Else
    While OctTemp > 0
      OctStr = Str(OctTemp % 8) + OctStr
      OctTemp = OctTemp / 8
    Wend
  EndIf

  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "HEX  : " + Mamute_Hex4(Sum) + "H")
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "BIN  : " + RSet(Bin(Sum), 16, "0"))
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "DEC+ : " + Str(Sum))
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "DEC+-: " + Str(Signed))
  *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "OCT  : " + RSet(OctStr, 6, "0"))
EndProcedure

; "@" sozinho no prompt - mostra o conteudo das 7 variaveis de debugger do
; SUPER-X (docs/SPEC.md modulo 45d): @0-@3 normais + @B/@E/@S especiais.
; "(vazia)" pras que ainda nao foram definidas nesta sessao da janela.
Procedure.s MamuteGui_ShowVars(G_Log, Accum.s)
  Protected Names.s = "0123BES"
  Protected i.i, Name.s, *V.MamuteVarSlot, Line.s
  For i = 1 To Len(Names)
    Name = Mid(Names, i, 1)
    *V = Mamute_VarPtr(Name)
    Line = "@" + Name + " = "
    If *V\HasValue
      Line + Mamute_SxFormatAddr(*V\Addr, @*V\Target)
    Else
      Line + "(vazia)"
    EndIf
    Accum = MamuteGui_AppendLog(G_Log, Accum, Line)
  Next
  ProcedureReturn Accum
EndProcedure

; Um comando digitado por chamada - primeiro token (ate o espaco) e o verbo,
; o resto (se houver) sao os argumentos crus, cada comando decide sozinho
; como interpretar os proprios argumentos. Select isolado de proposito -
; cada comando novo (ver Ajuda -> Mamute Assembler...) vira so mais um Case
; aqui, sem mexer no resto da janela.
Procedure MamuteGui_Dispatch(Win, G_Log, *State.MamuteGui_State, Cmd.s)
  Protected Trimmed.s = Trim(Cmd)

  ; "@" no inicio da linha INTEIRA - variaveis de debugger do SUPER-X
  ; (docs/SPEC.md modulo 45d). "@" sozinho mostra as 7; "@<nome>=<endereco>
  ; [#slot]" define uma. Nenhuma das duas formas tem "verbo" separado por
  ; espaco do jeito normal, entao verificado ANTES do split Verb/Args -
  ; depois disso, "@<nome>" ja funciona como ENDERECO em qualquer comando do
  ; SUPER-X (Mamute_ParseSxAddr(), MamuteSupport.pbi, entende sozinho).
  If Left(Trimmed, 1) = "@"
    If Trimmed = "@"
      *State\LogAccum = MamuteGui_ShowVars(G_Log, *State\LogAccum)
      ProcedureReturn
    EndIf
    Protected EqPos.i = FindString(Trimmed, "=")
    Protected VarName.s, ValueTok.s
    Protected *VSlot.MamuteVarSlot
    If EqPos > 1
      VarName = Trim(Mid(Trimmed, 2, EqPos - 2))
      ValueTok = Trim(Mid(Trimmed, EqPos + 1))
      *VSlot = Mamute_VarPtr(VarName)
    EndIf
    Protected VAddr.i
    Protected VTarget.MamuteSxTarget
    If *VSlot And ValueTok <> "" And Mamute_ParseSxAddr(ValueTok, @VAddr, @VTarget)
      *VSlot\HasValue = #True
      *VSlot\Addr = VAddr
      CopyStructure(@VTarget, @*VSlot\Target, MamuteSxTarget)
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum,
        "@" + UCase(VarName) + " = " + Mamute_SxFormatAddr(VAddr, @VTarget))
      ProcedureReturn
    EndIf
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?ERRO DE SINTAXE")
    ProcedureReturn
  EndIf

  ; "?" na frente de um comando do SUPER-X manda a saida pra "impressora" -
  ; que aqui vira PDF, mesma tecnica ja usada por P/LP (Mamute_SavePdfListing,
  ; modulo 31) - doc do SUPER-X: "Place a ? in front of the command" (secao
  ; "General information"). So' vale pros comandos PORTADOS do SUPER-X
  ; (XD/XM/futuros) - decisao explicita do usuario ("Todos os comandos do
  ; Super-X"); os herdados do MegaAssembler ja tem seu proprio verbo
  ; dedicado pra isso (D->P, L->LP), nao precisam de prefixo nenhum.
  Protected PrinterMode.b = #False
  If Left(Trimmed, 1) = "?"
    PrinterMode = #True
    Trimmed = Trim(Mid(Trimmed, 2))
  EndIf

  ; Verbo termina no primeiro ESPACO ou VIRGULA, o que vier primeiro -
  ; achado real do modulo 45t: na sessao do XFS/XCI, o pedido original do
  ; usuario mostrava a forma GRUDADA ("XFS,arquivo", sem espaco nenhum
  ; antes da virgula) pro entao-existente "[,<nome>]" desses comandos - o
  ; split so' por espaco rejeitava isso (o "XFS,arquivo" inteiro virava um
  ; "verbo" desconhecido, ?COMANDO INVALIDO). Fix mantido mesmo depois que
  ; o "[,<nome>]" foi ELIMINADO (modulo 45w - "todos os comandos de disco
  ; vamos eliminar o nome deles, o nome vai ser sempre o corrente", XDK
  ; virou o unico jeito de trocar disco) - nenhum comando usa mais virgula
  ; logo apos o verbo hoje, entao o ramo "virgula primeiro" abaixo fica
  ; inerte na pratica, mas nao faz mal nenhum deixar (backward-compatible,
  ; sem custo). Quando o espaco vem ANTES de qualquer virgula (o caso
  ; comum - "XRG BP1,4000", "XTS 4000,4010" etc.), nada muda: continua
  ; cortando so' no espaco, virgula nenhuma e' tocada.
  Protected SpacePos.i = FindString(Trimmed, " ")
  Protected CommaPos.i = FindString(Trimmed, ",")
  Protected Verb.s, Args.s
  If SpacePos > 0 And (CommaPos = 0 Or SpacePos < CommaPos)
    Verb = UCase(Left(Trimmed, SpacePos - 1))
    Args = Trim(Mid(Trimmed, SpacePos + 1))
  ElseIf CommaPos > 0
    Verb = UCase(Left(Trimmed, CommaPos - 1))
    Args = Mid(Trimmed, CommaPos)
  Else
    Verb = UCase(Trimmed)
    Args = ""
  EndIf

  ; XD/XA/XI entendem "?" (os tres tem uma forma de listagem estatica de
  ; verdade - XM e' uma sessao interativa, nao da pra "imprimir"). Comandos
  ; futuros que ganharem listagem propria (SD, por exemplo) entram nesta
  ; lista quando chegar a vez deles.
  If PrinterMode And Verb <> "XD" And Verb <> "XA" And Verb <> "XI"
    *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?IMPRESSAO NAO APLICAVEL A ESTE COMANDO")
    ProcedureReturn
  EndIf

  Select Verb
    Case "BA", "QUIT"
      *State\ShouldQuit = #True

    ; XQT - porta do QT do SUPER-X (inventario do modulo 45: "Sai pro BASIC")
    ; - pedido explicito do usuario: "so encerra o Mamute Assembler", mesmo
    ; comportamento exato do BA/QUIT nativo (fecha a janela, sem mensagem
    ; nenhuma no log antes) - so' um segundo nome pro mesmo efeito, mesma
    ; razao de existir do resto dos comandos com prefixo X (nome livre,
    ; sem colisao, mas sem comportamento novo pra inventar aqui).
    Case "XQT"
      *State\ShouldQuit = #True

    Case "CLS"
      SetGadgetText(G_Log, "")
      *State\LogAccum = ""

    Case "PAGE"
      MamuteGui_CmdPage(G_Log, *State, Args)

    Case "DM"
      MamuteGui_CmdDm(Win, G_Log, *State, Args)

    Case "ZAP"
      MamuteGui_CmdZap(Win, G_Log, *State, Args)

    Case "SCR"
      MamuteGui_CmdScr(Win, G_Log, *State, Args)

    Case "SH"
      MamuteGui_CmdSh(G_Log, *State, Args)

    Case "MS"
      MamuteGui_CmdMs(G_Log, *State, Args)

    Case "LOAD"
      MamuteGui_CmdLoad(G_Log, *State, Win, Args)

    Case "SAVE"
      MamuteGui_CmdSave(Win, G_Log, *State, Args)

    Case "M"
      MamuteGui_CmdM(Win, G_Log, *State, Args)

    Case "S"
      MamuteGui_CmdS(Win, G_Log, *State, Args)

    Case "C"
      MamuteGui_CmdC(G_Log, *State, Args)

    Case "D"
      MamuteGui_CmdD(G_Log, *State, Args)

    Case "P"
      MamuteGui_CmdP(G_Log, *State, Args)

    Case "V"
      MamuteGui_CmdV(G_Log, *State, Args)

    Case "T"
      MamuteGui_CmdT(G_Log, *State, Args)

    Case "F"
      MamuteGui_CmdF(G_Log, *State, Args)

    Case "G"
      MamuteGui_CmdG(G_Log, *State, Win, Args)

    Case "X"
      MamuteGui_CmdX(G_Log, *State, Args)

    Case "R"
      MamuteGui_CmdR(G_Log, *State, Args)

    Case "FOSSAURO"
      MamuteGui_CmdFossauro(G_Log, *State)

    Case "OPENMSX"
      MamuteGui_CmdOpenMSX(G_Log, *State)

    Case "L"
      MamuteGui_CmdL(G_Log, *State, Args)

    Case "LP"
      MamuteGui_CmdLp(G_Log, *State, Args)

    Case "CL"
      MamuteGui_CmdCl(G_Log, *State, Args)

    Case "XD"
      MamuteGui_CmdXd(Win, G_Log, *State, Args, PrinterMode)

    Case "XA"
      MamuteGui_CmdXa(Win, G_Log, *State, Args, PrinterMode)

    Case "XI"
      MamuteGui_CmdXi(Win, G_Log, *State, Args, PrinterMode)

    Case "XM"
      MamuteGui_CmdXm(Win, G_Log, *State, Args)

    Case "XH"
      MamuteGui_CmdXh(Win, G_Log, *State, Args)

    Case "XBT"
      MamuteGui_CmdXbt(G_Log, *State, Args)

    Case "XRT"
      MamuteGui_CmdXrt(G_Log, *State, Args)

    Case "XFL"
      MamuteGui_CmdXfl(G_Log, *State, Args)

    Case "XCM"
      MamuteGui_CmdXcm(G_Log, *State, Args)

    Case "XFD"
      MamuteGui_CmdXfd(Win, G_Log, *State, Args)

    Case "XCO"
      MamuteGui_CmdXco(G_Log, *State, Args)

    Case "XCS"
      MamuteGui_CmdXcs(G_Log, *State)

    Case "XTS"
      MamuteGui_CmdXts(G_Log, *State, Args)

    Case "XRG"
      MamuteGui_CmdXrg(G_Log, *State, Args)

    Case "XGO"
      MamuteGui_CmdXgo(G_Log, *State, Args)

    Case "XTR"
      MamuteGui_CmdXtr(G_Log, *State, Args)

    Case "XSD"
      MamuteGui_CmdXsd(G_Log, *State, Args)

    Case "XFS"
      MamuteGui_CmdXfs(G_Log, *State, Args)

    Case "XCI"
      MamuteGui_CmdXci(G_Log, *State, Args)

    Case "XTP"
      MamuteGui_CmdXtp(Win, G_Log, *State, Args)

    Case "XSV"
      MamuteGui_CmdXsv(G_Log, *State, Args)

    Case "XLD"
      MamuteGui_CmdXld(G_Log, *State, Args)

    Case "XS#"
      MamuteGui_CmdXsRaw(G_Log, *State, Args)

    Case "XL#"
      MamuteGui_CmdXlRaw(G_Log, *State, Args)

    Case "XDK"
      MamuteGui_CmdXdk(G_Log, *State, Args)

    Case "XL%"
      MamuteGui_CmdXlPct(G_Log, *State, Args)

    Case "XS%"
      MamuteGui_CmdXsPct(G_Log, *State, Args)

    Case "XIM"
      MamuteGui_CmdXim(G_Log, *State, Args)

    Case "XIC"
      MamuteGui_CmdXic(G_Log, *State, Args)

    Case "XIL"
      MamuteGui_CmdXil(G_Log, *State, Args)

    Case "XIS"
      MamuteGui_CmdXis(G_Log, *State, Args)

    Case "XIR"
      MamuteGui_CmdXir(Win, G_Log, *State, Args)

    Case "XPP"
      MamuteGui_CmdXpp(Win, G_Log, *State, Args)

    Case "XPI"
      MamuteGui_CmdXpi(G_Log, *State, Args)

    Case "XPO"
      MamuteGui_CmdXpo(G_Log, *State, Args)

    Case "EDIT"
      MamuteEdit_Open(Win)

    Default
      *State\LogAccum = MamuteGui_AppendLog(G_Log, *State\LogAccum, "?COMANDO INVALIDO")
  EndSelect
EndProcedure

Procedure MamuteAssembler_OpenWindow(ParentWindow)
  MamuteCfg_Load()
  MamuteGui_EnsureFont() ; depende de MamuteFontName/Size/Bold, ja carregados acima
  Mamute_ResetPageMapToDefault() ; "estado de boot" - ver MamuteSupport.pbi
  Mamute_LoadPhysicalMemory() ; le os arquivos ROM/BASIC configurados pra MamuteMem() de verdade
  MamuteGui_HistoryLoad() ; historico do MON> gravado no projeto (ou projeto padrao) - recarrega
                          ; toda vez que a janela abre, o projeto pode ter mudado desde a ultima vez

  Protected WinW = 960, WinH = 640
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Mamute Assembler",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered, #True, #False)
  If Not Win
    ProcedureReturn
  EndIf

  Protected ColFront = Mamute_CurrentFrontColor(), ColBack = Mamute_CurrentBackColor(), ColBorder = Mamute_CurrentBorderColor()
  SetWindowColor(Win, ColBorder)

  ; Barra fixa de status (topo, FORA do log que rola) - pedido explicito do
  ; usuario: disco corrente (docs/SPEC.md modulo 45, XFS em diante), ultimo
  ; comando digitado, endereco/offset e slot de trabalho atual, e uma
  ; miniatura 16x16 (um pixel por byte) da memoria a partir dali. G_Status
  ; e' texto de 3 linhas agora (era 2 antes do disco corrente - StatusSize
  ; aumentado de 64 pra 84 pra caber a linha nova sem cortar); G_MemView e'
  ; o CanvasGadget da miniatura, ao lado (StatusSize x StatusSize = grade
  ; 16x16 a StatusSize/16 px por byte). Atualizada por
  ; MamuteGui_RefreshStatusBar() abaixo, tanto na abertura quanto apos cada
  ; comando despachado.
  Protected StatusSize = 84
  Protected G_Status = TextGadget(#PB_Any, 16, 16, WinW - 32 - StatusSize - 16, StatusSize, "")
  SetGadgetColor(G_Status, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Status, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Status, FontID(MamuteGui_Font))

  Protected G_MemView = CanvasGadget(#PB_Any, WinW - 16 - StatusSize, 16, StatusSize, StatusSize)

  Protected G_Log = EditorGadget(#PB_Any, 16, 16 + StatusSize + 8, WinW - 32, WinH - 72 - (StatusSize + 8), #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
  SetGadgetColor(G_Log, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Log, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Log, FontID(MamuteGui_Font))

  Protected G_Prompt = TextGadget(#PB_Any, 16, WinH - 46, 64, 24, "MON>")
  SetGadgetColor(G_Prompt, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Prompt, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Prompt, FontID(MamuteGui_Font))

  Protected G_Input = StringGadget(#PB_Any, 80, WinH - 48, WinW - 96, 26, "")
  SetGadgetColor(G_Input, #PB_Gadget_FrontColor, ColFront)
  SetGadgetColor(G_Input, #PB_Gadget_BackColor, ColBack)
  SetGadgetFont(G_Input, FontID(MamuteGui_Font))

  ; Reaplica a fonte - ver nota no topo do arquivo sobre App_StyleChildCallback.
  ; So chamar SetGadgetFont aqui de novo NAO bastava de verdade (achado real,
  ; 2026-08-25: usuario reportou que esta janela - a UNICA tela do Mamute que
  ; usa controles nativos, RICHEDIT/Static/Edit, em vez de tudo desenhado a
  ; mao num CanvasGadget como DM/M/S/XD/etc - ignorava MamuteFontName/Size/
  ; Bold e ficava pequena, presa na Segoe UI). Causa raiz: o WM_PAINT que
  ; aciona o clobber (App_StyleChildCallback, BadigEditor.pb - forca Segoe UI
  ; em TODO controle nativo) so e' ENTREGUE no primeiro WaitWindowEvent() do
  ; loop la embaixo, ou seja, DEPOIS deste bloco inteiro ja ter rodado -
  ; reaplicar "antes do loop" nunca vencia a corrida, so' parecia vencer.
  ; Fix: forca esse WM_PAINT (e o clobber junto) a acontecer AGORA, de forma
  ; sincrona, via SendMessage_ direto na janela - App_DarkModeWindowProc so'
  ; clobra uma vez por HWND (guarda App_StyledWindows()), entao depois desta
  ; linha a fonte reaplicada abaixo e' a que sobrevive pro resto da sessao.
  SendMessage_(WindowID(Win), #WM_PAINT, 0, 0)
  SetGadgetFont(G_Status, FontID(MamuteGui_Font))
  SetGadgetFont(G_Log, FontID(MamuteGui_Font))
  SetGadgetFont(G_Prompt, FontID(MamuteGui_Font))
  SetGadgetFont(G_Input, FontID(MamuteGui_Font))

  Protected State.MamuteGui_State
  State\LogAccum = MamuteGui_AppendLog(G_Log, "", "MAMUTE ASSEMBLY V" + #App_Version)
  State\LogAccum = MamuteGui_AppendLog(G_Log, State\LogAccum, "COPYRIGHT (C) 2026 BARNEY")
  State\LogAccum = MamuteGui_AppendLog(G_Log, State\LogAccum, "")
  State\LogAccum = MamuteGui_AppendLog(G_Log, State\LogAccum, "Digite BA ou QUIT para encerrar.")
  State\LogAccum = MamuteGui_AppendLog(G_Log, State\LogAccum, "")
  State\LogAccum = MamuteGui_ShowPageMap(G_Log, State\LogAccum)
  State\LogAccum = MamuteGui_AppendLog(G_Log, State\LogAccum, "")

  ; Carga automatica do arquivo de notas padrao (campo "Notas SUPER-X
  ; padrao", Configurar -> Mamute Assembler..., MamuteSupport.pbi) -
  ; pedido explicito do usuario: "para ser carregado sempre que o Mamute
  ; iniciar" (docs/SPEC.md modulo 45y). "" (padrao) = nao tenta carregar
  ; nada, sem log nenhum sobre isso - so' aparece linha no log quando o
  ; usuario de fato configurou um arquivo.
  If MamuteDefaultNotesFile <> ""
    If Mamute_LoadTranslatedNotes(MamuteDefaultNotesFile)
      State\LogAccum = MamuteGui_AppendLog(G_Log, State\LogAccum,
        "NOTAS PADRAO CARREGADAS: " + GetFilePart(MamuteDefaultNotesFile) + " (" +
        Str(ListSize(MamuteNotes())) + " NOTAS)")
    Else
      State\LogAccum = MamuteGui_AppendLog(G_Log, State\LogAccum,
        "?NAO FOI POSSIVEL CARREGAR AS NOTAS PADRAO: " + GetFilePart(MamuteDefaultNotesFile))
    EndIf
    State\LogAccum = MamuteGui_AppendLog(G_Log, State\LogAccum, "")
  EndIf

  MamuteGui_RefreshStatusBar(G_Status, G_MemView, @State, ColBack)

  SetActiveGadget(G_Input)
  AddKeyboardShortcut(Win, #PB_Shortcut_Return, #MamuteGui_EnterShortcut)
  AddKeyboardShortcut(Win, #PB_Shortcut_Up, #MamuteGui_UpShortcut)
  AddKeyboardShortcut(Win, #PB_Shortcut_Down, #MamuteGui_DownShortcut)
  AddKeyboardShortcut(Win, #PB_Shortcut_Escape, #MamuteGui_EscShortcut)

  ; Posicao de navegacao no historico - -1 = "fora" dele (campo livre, o
  ; usuario esta digitando algo novo); 0..ListSize-1 = indice do comando
  ; sendo revisitado agora. Cima anda pro passado (indice menor), Baixo pro
  ; presente (indice maior, ate sair de volta pra -1 = campo vazio).
  Protected HistPos.i = -1
  Protected InputEndPos.i ; usado so pelos handlers de Cima/Baixo abaixo, pra por o cursor no fim do texto

  Protected Event, Quit = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Menu
        If EventMenu() = #MamuteGui_EnterShortcut
          Protected Cmd.s = Trim(GetGadgetText(G_Input))
          If Cmd <> ""
            State\LogAccum = MamuteGui_AppendLog(G_Log, State\LogAccum, "MON>" + Cmd)
            SetGadgetText(G_Input, "")
            HistPos = -1
            MamuteGui_HistoryAdd(Cmd)
            MamuteGui_HistorySave()
            Protected ExtractedAddr.i
            If MamuteGui_ExtractCmdAddr(Cmd, @ExtractedAddr)
              State\LastCmdAddr = ExtractedAddr
              State\HasLastCmdAddr = #True
            EndIf
            State\LastCmdText = Cmd
            MamuteGui_Dispatch(Win, G_Log, @State, Cmd)
            MamuteGui_RefreshStatusBar(G_Status, G_MemView, @State, ColBack)
            If State\ShouldQuit
              Quit = #True
            EndIf
          EndIf

        ElseIf EventMenu() = #MamuteGui_UpShortcut
          Protected HistCount.i = ListSize(MamuteGui_History())
          If HistCount > 0
            If HistPos = -1
              HistPos = HistCount - 1
            ElseIf HistPos > 0
              HistPos - 1
            EndIf
            SelectElement(MamuteGui_History(), HistPos)
            SetGadgetText(G_Input, MamuteGui_History())
            CompilerIf #PB_Compiler_OS = #PB_OS_Windows
              InputEndPos = Len(GetGadgetText(G_Input))
              SendMessage_(GadgetID(G_Input), #EM_SETSEL, InputEndPos, InputEndPos)
            CompilerEndIf
          EndIf

        ElseIf EventMenu() = #MamuteGui_DownShortcut
          If HistPos <> -1
            If HistPos < ListSize(MamuteGui_History()) - 1
              HistPos + 1
              SelectElement(MamuteGui_History(), HistPos)
              SetGadgetText(G_Input, MamuteGui_History())
            Else
              HistPos = -1
              SetGadgetText(G_Input, "")
            EndIf
            CompilerIf #PB_Compiler_OS = #PB_OS_Windows
              InputEndPos = Len(GetGadgetText(G_Input))
              SendMessage_(GadgetID(G_Input), #EM_SETSEL, InputEndPos, InputEndPos)
            CompilerEndIf
          EndIf
        EndIf

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
