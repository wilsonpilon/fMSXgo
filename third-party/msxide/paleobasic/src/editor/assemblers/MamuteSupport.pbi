;
; ------------------------------------------------------------
;  Suporte ao Mamute Assembler (MamuteAssemblerGui.pbi): simulacao do
;  sistema de slots do MSX - 4 slots (0-3), 4 paginas de 16KB por slot
;  (Pagina 0: 0000-3FFF, Pagina 1: 4000-7FFF, Pagina 2: 8000-BFFF, Pagina 3:
;  C000-FFFF, exatamente como o hardware real do MSX endereca memoria via
;  paginacao). MamuteMem() e um bloco 4x4 de 16KB cada (256KB no total) -
;  toda em branco por enquanto (Dim zera sozinho), preenchida por arquivo
;  real (BIOS/BASIC/cartucho) numa sessao futura.
;
;  "Configurar -> Mamute Assembler..." (MamuteSettings_OpenWindow abaixo)
;  configura o que existe FISICAMENTE em cada uma das 16 celulas Slot x
;  Pagina (Vazio/RAM/ROM/BASIC + arquivo, pra ROM/BASIC) - configuracao
;  fixa, nao muda em tempo de execucao. Ao escolher um arquivo de 32KB pra
;  uma celula ROM na Pagina 0 (BIOS), a tela pergunta se e BIOS+BASIC
;  combinados (comum em MSX real) - se sim, aponta a Pagina 0 e a Pagina 1
;  do MESMO slot pro MESMO arquivo, cada uma com o FileOffset certo (0 pros
;  primeiros 16KB/BIOS, #Mamute_PageSize pros ultimos 16KB/BASIC).
;  O comando PAGE (MamuteAssemblerGui.pbi)
;  mexe num conceito DIFERENTE: MamutePageMap() e o mapeamento ATIVO agora
;  mesmo - pra cada uma das 4 paginas visiveis pelo Z80 (0-3), qual dos 4
;  slots fisicos esta "comutado" ali - exatamente como o registrador de slot
;  primario (porta A8h) de um MSX de verdade. E esse mapeamento ativo (nao a
;  configuracao fisica) que vai decidir, em sessoes futuras, de qual bloco
;  de 16KB um comando que mostra/edita memoria realmente le/escreve.
; ------------------------------------------------------------
;

#MamuteMem_Empty = 0
#MamuteMem_RAM   = 1
#MamuteMem_ROM   = 2
#MamuteMem_Basic = 3

#Mamute_PageSize = 16384 ; 16KB - tamanho de cada bloco/pagina
#Mamute_CombinedBiosBasicSize = 32768 ; 32KB - BIOS+BASIC combinados num arquivo so (comum em MSX real)

; Bloco de memoria simulada: [Slot][Pagina][Offset 0..16383] - 4x4x16KB =
; 256KB. Global Dim zera sozinho (PureBasic) - "toda a memoria em branco"
; sem precisar de nenhum laco de inicializacao.
Global Dim MamuteMem.a(3, 3, 16383)

; VRAM simulada (comandos V/futuros VLOAD/VSAVE) - pedido explicito do
; usuario, "ainda nao temos VRAM, mas vamos implementar entao". Diferente
; da RAM/ROM (que passa pelo sistema de 4 slots x 4 paginas, espelhando o
; barramento de enderecos de 16 bits do Z80), a VRAM de um MSX real NUNCA
; fica mapeada nesse espaco - e acessada por PORTA de I/O (o VDP tem seu
; proprio contador de endereco interno), entao nao ha "pagina"/"slot" real
; pra simular. Por isso o endereco da VRAM aqui e PLANO e DIRETO, de 0 ate
; #Mamute_VramMaxSize-1 (192KB, o maior tamanho configuravel) - sem bancos,
; sem paginacao, sem PAGE - a opcao mais simples entre as que o usuario
; sugeriu ("permitirmos o enderecamento de ate os 128Kb" - ampliado aqui
; pro teto de 192KB). MamuteVramSize (configuravel em "Configurar -> Mamute
; Assembler...": 16/128/192KB) e so o LIMITE de validacao - o array em si
; sempre aloca o tamanho maximo (192KB e trivial em memoria), evitando
; ReDim/perda de dado se o usuario mudar o tamanho configurado depois.
#Mamute_VramMaxSize = 196608 ; 192KB - maior tamanho configuravel
Global Dim MamuteVRAM.a(#Mamute_VramMaxSize - 1)
Global MamuteVramSize.i = 16384 ; 16KB por padrao - mesmo tamanho que o MegaAssembler original (MSX1) enxergava

; FileOffset: deslocamento (em bytes) dentro de FilePath de onde comecam os
; 16KB desta celula - normalmente 0 (arquivo do tamanho exato da pagina),
; mas #Mamute_PageSize (16384) quando esta celula e a metade FINAL de um
; arquivo BIOS+BASIC combinado de 32KB (ver MamuteSettings_HandleFilePick())
; - assim os dois pontos (BIOS na Pagina 0, BASIC na Pagina 1 do mesmo slot)
; apontam pro MESMO arquivo, cada um lendo a metade certa.
Structure MamuteMemCell
  Tipo.b     ; #MamuteMem_Empty/RAM/ROM/Basic
  FilePath.s ; so usado quando Tipo = ROM ou Basic
  FileOffset.i
EndStructure
Global Dim MamuteCfgCell.MamuteMemCell(3, 3) ; [Slot][Pagina]

; Mapeamento ATIVO agora mesmo - MamutePageMap(Pagina) = Slot comutado
; naquela pagina. Recalculado pro "estado de boot" (Mamute_ResetPageMapToDefault)
; toda vez que a janela do Mamute Assembler abre - ver comentario no topo.
Global Dim MamutePageMap.i(3)

; Fonte do terminal (MamuteAssemblerGui.pbi) - configuravel em "Configurar ->
; Mamute Assembler..." (pedido explicito do usuario, fonte padrao ficou
; pequena demais). Monoespacada de proposito (EditorCfg_EnumMonospaceFonts(),
; EditorSettings.pbi, mesma enumeracao ja usada pela fonte do editor de
; codigo) - uma fonte proporcional quebraria o alinhamento em grade do
; terminal.
Global MamuteFontName.s = "Consolas"
Global MamuteFontSize.i = 16
Global MamuteFontBold.b = #True

; Cor da tela (comando CO, docs/SPEC.md modulo 45, porta do CO do SUPER-X) -
; indices 0-15 da paleta REAL, FIXA, do MSX1/TMS9918 (Mamute_Msx1PaletteRGB()
; logo abaixo) - nao editavel, exatamente como o hardware de verdade (MSX1
; nao tem paleta programavel, diferente do V9938/MSX2). Front/Back/Border
; configuraveis via CO, persistidos em mamute_settings.json (MamuteCfg_Load/
; Save abaixo). Default 3/1/1 (Verde Claro/Preto/Preto) reproduz o visual
; "terminal verde sobre preto" que o Mamute sempre teve - achado real ao
; implementar o CO: esse visual estava hardcoded como RGB(60,220,90)/
; RGB(0,0,0) SEPARADAMENTE em 12 arquivos/72 lugares (cada janela do Mamute
; tinha sua PROPRIA copia local), todos migrados pra ler daqui.
Global MamuteColorFg.i     = 3
Global MamuteColorBg.i     = 1
Global MamuteColorBorder.i = 1

; Paleta REAL do TMS9918 (VDP do MSX1), RGB aproximado (mesmos valores
; usados por emuladores como o openMSX) - indice 0 (transparente) devolve o
; mesmo preto do indice 1, ja que nao ha "transparencia" de verdade fora de
; sprites (mesma simplificacao que o resto do simulador ja assume em outros
; lugares).
Procedure.i Mamute_Msx1PaletteRGB(Index.i)
  Select Index & 15
    Case 1  : ProcedureReturn RGB(0, 0, 0)       ; Preto
    Case 2  : ProcedureReturn RGB(33, 200, 66)   ; Verde Medio
    Case 3  : ProcedureReturn RGB(94, 220, 120)  ; Verde Claro
    Case 4  : ProcedureReturn RGB(84, 85, 237)   ; Azul Escuro
    Case 5  : ProcedureReturn RGB(125, 118, 252) ; Azul Claro
    Case 6  : ProcedureReturn RGB(212, 82, 77)   ; Vermelho Escuro
    Case 7  : ProcedureReturn RGB(66, 235, 245)  ; Ciano
    Case 8  : ProcedureReturn RGB(252, 85, 84)   ; Vermelho Medio
    Case 9  : ProcedureReturn RGB(255, 121, 120) ; Vermelho Claro
    Case 10 : ProcedureReturn RGB(212, 193, 84)  ; Amarelo Escuro
    Case 11 : ProcedureReturn RGB(230, 206, 128) ; Amarelo Claro
    Case 12 : ProcedureReturn RGB(33, 176, 59)   ; Verde Escuro
    Case 13 : ProcedureReturn RGB(201, 91, 186)  ; Magenta
    Case 14 : ProcedureReturn RGB(204, 204, 204) ; Cinza
    Case 15 : ProcedureReturn RGB(255, 255, 255) ; Branco
    Default : ProcedureReturn RGB(0, 0, 0)       ; 0 = Transparente -> preto
  EndSelect
EndProcedure

Procedure.i Mamute_CurrentFrontColor()
  ProcedureReturn Mamute_Msx1PaletteRGB(MamuteColorFg)
EndProcedure
Procedure.i Mamute_CurrentBackColor()
  ProcedureReturn Mamute_Msx1PaletteRGB(MamuteColorBg)
EndProcedure
Procedure.i Mamute_CurrentBorderColor()
  ProcedureReturn Mamute_Msx1PaletteRGB(MamuteColorBorder)
EndProcedure

; Comandos FOSSAURO e OPENMSX (MamuteGui_CmdFossauro()/MamuteGui_CmdOpenMSX(),
; MamuteAssemblerGui.pbi) - depois do LOAD, sempre digita "DEFUSR0=&H<endereco>" na sessao MSX
; (ver Fossauro_SendAndType()/FossauroSupport.pbi ou OMSX_SendMamuteProgram()/
; OpenMSXBridge.pbi, docs/SPEC.md modulos 32y/32z/33); se esta flag estiver ligada, digita
; ":A=USR0(0)" junto na MESMA linha, executando na hora que o Enter e' "digitado" - continua
; passando pelo interpretador BASIC de verdade (nao e' RUN cru nem debug set pc), so' automatiza
; o "digitar A=USR0(0) e apertar Enter" manual. MESMA flag pros dois comandos (e' a mesma
; decisao "executar ou nao" pro usuario, independente do alvo). Desligada por padrao de
; proposito - pedido explicito do usuario (2026-08-19): o comportamento padrao continua so'
; transferir, executar e' opt-in.
Global MamuteAutoRunAfterTransfer.b = #False

; Arquivo de notas do SUPER-X (comandos XIM/XIC/XIL/XIS, docs/SPEC.md
; modulo 45x) carregado automaticamente toda vez que o Mamute abre - campo
; "Notas SUPER-X padrao" em Configurar -> Mamute Assembler...
; (MamuteSettings_OpenWindow abaixo), persistido em mamute_settings.json
; (MamuteCfg_Load/Save). "" (padrao) = nao carrega nada automaticamente -
; pedido explicito do usuario: "abra um campo para escolher um arquivo de
; nota padrao para ser carregado sempre que o Mamute iniciar" (modulo
; 45y). Se o usuario escolher justamente o arquivo traduzido ORIGINAL que
; o Paleobasic ja traz pronto (Mamute_TranslatedNotesFilePath(),
; MamuteNotesData.pbi), Mamute_ProtectTranslatedNotesIfPicked() substitui
; isto pelo caminho do arquivo-sombra editavel automaticamente - este
; Global nunca guarda o caminho do arquivo original protegido.
Global MamuteDefaultNotesFile.s = ""

; Fonte carregada (HFONT) a partir dos 3 campos acima - Global aqui (nao em
; MamuteAssemblerGui.pbi, onde MamuteGui_EnsureFont() de fato a carrega/
; recarrega) so pela ordem de declaracao: MamuteEditGui.pbi (janela do
; comando EDIT) e' XIncludeFile'd ANTES de MamuteAssemblerGui.pbi e tambem
; precisa ler este Global - mesmo idioma "hoist a declaracao, nao a
; logica" ja documentado em CLAUDE.md pra este projeto.
Global MamuteGui_Font.i = -1

; Teclado numerico reduzido do comando S (MamuteMGui.pbi) - pedido explicito
; do usuario: "vamos criar uma opcao no Configurar -> Mamute Assembler pra
; o usuario escolher quais teclas do teclado ele vai usar como
; 1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,0". Indexado pelo VALOR do nibble (0-15),
; nao pela ordem de exibicao pedida (que comeca em 1 e termina em 0) - mais
; simples de usar em tempo de execucao (MamuteSKeyMap(Valor) direto). A tela
; de Configurar e que reordena pra mostrar "1" primeiro e "0" por ultimo.
; Padrao pedido explicitamente pelo usuario: "1,2,3,4,q,w,e,r,a,s,d,f,z,x,c,v"
; - mesmo layout classico de teclado numerico em jogos/emuladores (4x4 nos
; cantos esquerdos do teclado QWERTY).
Global Dim MamuteSKeyMap.s(15)

Procedure Mamute_SKeyMapDefaults()
  MamuteSKeyMap(0)  = "V" ; ultimo na ordem de exibicao (1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,0)
  MamuteSKeyMap(1)  = "1"
  MamuteSKeyMap(2)  = "2"
  MamuteSKeyMap(3)  = "3"
  MamuteSKeyMap(4)  = "4"
  MamuteSKeyMap(5)  = "Q"
  MamuteSKeyMap(6)  = "W"
  MamuteSKeyMap(7)  = "E"
  MamuteSKeyMap(8)  = "R"
  MamuteSKeyMap(9)  = "A"
  MamuteSKeyMap(10) = "S" ; valor A
  MamuteSKeyMap(11) = "D" ; valor B
  MamuteSKeyMap(12) = "F" ; valor C
  MamuteSKeyMap(13) = "Z" ; valor D
  MamuteSKeyMap(14) = "X" ; valor E
  MamuteSKeyMap(15) = "C" ; valor F
EndProcedure

Procedure.s Mamute_PageRangeText(Pagina.i)
  Select Pagina
    Case 0 : ProcedureReturn "0000-3FFF"
    Case 1 : ProcedureReturn "4000-7FFF"
    Case 2 : ProcedureReturn "8000-BFFF"
    Case 3 : ProcedureReturn "C000-FFFF"
  EndSelect
  ProcedureReturn "????-????"
EndProcedure

Procedure.s Mamute_TipoText(Tipo.b)
  Select Tipo
    Case #MamuteMem_RAM   : ProcedureReturn "RAM"
    Case #MamuteMem_ROM   : ProcedureReturn "ROM"
    Case #MamuteMem_Basic : ProcedureReturn "BASIC"
  EndSelect
  ProcedureReturn "Vazio"
EndProcedure

; Descricao do modo de exibicao escolhido pelo comando C - usado por ele
; mesmo (so pra confirmar no log) e, mais tarde, pelos comandos D/P/V que
; vao realmente formatar a saida conforme esse modo.
Procedure.s Mamute_DisplayModeText(Mode.b)
  Select Mode
    Case 0 : ProcedureReturn "HEXA+ASCII, 4 BYTES/LINHA"
    Case 1 : ProcedureReturn "HEXA+ASCII, 16 BYTES/LINHA"
    Case 2 : ProcedureReturn "HEXA, 8 BYTES/LINHA + CHECKSUM (SOMA+ENDERECO)"
    Case 3 : ProcedureReturn "HEXA, 8 BYTES/LINHA + CHECKSUM (SO SOMA)"
  EndSelect
  ProcedureReturn "?"
EndProcedure

; Primeiro slot (0..3, varrendo em ordem) com RAM configurada em QUALQUER
; pagina - usado por "PAGE" sem parametros ("coloca todas as paginas no
; slot marcado como RAM"). -1 se nenhum slot tem RAM configurada ainda.
Procedure Mamute_FindRamSlot()
  Protected Slot, Pagina
  For Slot = 0 To 3
    For Pagina = 0 To 3
      If MamuteCfgCell(Slot, Pagina)\Tipo = #MamuteMem_RAM
        ProcedureReturn Slot
      EndIf
    Next
  Next
  ProcedureReturn -1
EndProcedure

; Recalcula MamutePageMap() a partir da configuracao fisica (MamuteCfgCell) -
; "estado de boot": pra cada pagina, usa o slot configurado ali (ROM/BASIC
; ganham de RAM se as duas existirem na mesma pagina - RAM so vence quando
; e a UNICA coisa configurada); pagina sem nada configurado cai no slot 0
; por padrao (comportamento deterministico, sem "barramento flutuante").
Procedure Mamute_ResetPageMapToDefault()
  Protected Pagina, Slot, Chosen.i, ChosenIsRam.b, Found.b, Tipo.b
  For Pagina = 0 To 3
    Chosen = 0 : ChosenIsRam = #True : Found = #False
    For Slot = 0 To 3
      Tipo = MamuteCfgCell(Slot, Pagina)\Tipo
      If Tipo <> #MamuteMem_Empty
        If Not Found
          Chosen = Slot
          ChosenIsRam = Bool(Tipo = #MamuteMem_RAM)
          Found = #True
        ElseIf ChosenIsRam And Tipo <> #MamuteMem_RAM
          Chosen = Slot
          ChosenIsRam = #False
        EndIf
      EndIf
    Next
    MamutePageMap(Pagina) = Chosen
  Next
EndProcedure

; Le de verdade o conteudo dos arquivos ROM/BASIC configurados
; (MamuteCfgCell()\FilePath) pro bloco de MamuteMem() correspondente,
; respeitando FileOffset (metade final de um arquivo BIOS+BASIC combinado de
; 32KB - ver MamuteSettings_HandleFilePick acima). Ate aqui (SCR, modulo 31)
; MamuteMem() ficava sempre em branco mesmo com ROM configurada - "sessao
; futura" que virou necessaria agora que um comando (SCR) precisa mostrar
; dado real de ROM pra fazer sentido. Zera a celula antes de tentar ler (nao
; so quando falha) - reabrir a janela depois de trocar a config (ex.: tipo
; ROM -> Vazio, ou apontar pra outro arquivo) nao deve deixar lixo de uma
; carga anterior. Arquivo ausente/menor que 16KB: preenche o que der, resto
; fica zerado (nao e erro - igual um MSX real com uma ROM menor instalada).
Procedure Mamute_LoadPhysicalMemory()
  Protected Slot.i, Pagina.i, i.i
  Protected FilePath.s, FileOff.i, Fh.i
  For Slot = 0 To 3
    For Pagina = 0 To 3
      For i = 0 To #Mamute_PageSize - 1
        MamuteMem(Slot, Pagina, i) = 0
      Next

      If MamuteCfgCell(Slot, Pagina)\Tipo = #MamuteMem_ROM Or MamuteCfgCell(Slot, Pagina)\Tipo = #MamuteMem_Basic
        FilePath = MamuteCfgCell(Slot, Pagina)\FilePath
        FileOff = MamuteCfgCell(Slot, Pagina)\FileOffset
        If FilePath <> "" And FileSize(FilePath) > 0
          Fh = ReadFile(#PB_Any, FilePath)
          If Fh
            FileSeek(Fh, FileOff)
            ReadData(Fh, @MamuteMem(Slot, Pagina, 0), #Mamute_PageSize)
            CloseFile(Fh)
          EndIf
        EndIf
      EndIf
    Next
  Next
EndProcedure

;- ------------------------------------------------------------
;- Acesso a memoria por endereco de CPU (0000-FFFF) - usa MamutePageMap()
;- pra achar o slot ativo, exatamente como o comando PAGE deixou configurado.
;- Base de qualquer comando futuro que mostra/edita memoria (DM e o
;- primeiro) - ver comentario no topo do arquivo.
;- ------------------------------------------------------------

; Resolve um endereco de CPU (0-65535, sem checar faixa - chamador garante)
; pro Slot/Pagina/Offset fisicos correspondentes, considerando o mapeamento
; ATIVO agora (MamutePageMap()), nao a configuracao fisica crua.
Procedure Mamute_ResolveAddress(Addr.i, *OutSlot.Integer, *OutPagina.Integer, *OutOffset.Integer)
  Protected Pagina.i = (Addr >> 14) & 3
  *OutPagina\i = Pagina
  *OutSlot\i = MamutePageMap(Pagina)
  *OutOffset\i = Addr & (#Mamute_PageSize - 1)
EndProcedure

; #True so quando a celula fisica mapeada em Addr agora e RAM - ROM/BASIC/
; Vazio sao somente-leitura (fisicamente nao ha o que escrever ali, igual
; hardware real: ROM nao aceita escrita, e sem nada configurado nao ha chip
; nenhum pra responder).
Procedure.b Mamute_CanWriteAt(Addr.i)
  Protected Slot.i, Pagina.i, Offset.i
  Mamute_ResolveAddress(Addr, @Slot, @Pagina, @Offset)
  ProcedureReturn Bool(MamuteCfgCell(Slot, Pagina)\Tipo = #MamuteMem_RAM)
EndProcedure

Procedure.a Mamute_ReadByte(Addr.i)
  Protected Slot.i, Pagina.i, Offset.i
  Mamute_ResolveAddress(Addr, @Slot, @Pagina, @Offset)
  ProcedureReturn MamuteMem(Slot, Pagina, Offset)
EndProcedure

; #True se escreveu de verdade (Mamute_CanWriteAt); #False sem tocar em nada
; se a celula mapeada agora nao for RAM.
Procedure.b Mamute_WriteByte(Addr.i, Value.a)
  If Not Mamute_CanWriteAt(Addr)
    ProcedureReturn #False
  EndIf
  Protected Slot.i, Pagina.i, Offset.i
  Mamute_ResolveAddress(Addr, @Slot, @Pagina, @Offset)
  MamuteMem(Slot, Pagina, Offset) = Value
  ProcedureReturn #True
EndProcedure

;- ------------------------------------------------------------
;- Formatacao/parse hexadecimal - "enderecos em hexa sao o padrao de
;- entrada de todos os comandos" (pedido explicito do usuario).
;- ------------------------------------------------------------

Procedure.s Mamute_Hex2(v.i)
  ProcedureReturn RSet(Hex(v & $FF), 2, "0")
EndProcedure

Procedure.s Mamute_Hex4(v.i)
  ProcedureReturn RSet(Hex(v & $FFFF), 4, "0")
EndProcedure

; Endereco em hexa com largura variavel (usado pra VRAM - ate 5 digitos,
; 0-2FFFF pros 192KB maximos) - Mamute_Hex4() acima fica curto pra isso.
Procedure.s Mamute_HexPad(v.i, Digits.i)
  ProcedureReturn RSet(Hex(v), Digits, "0")
EndProcedure

; Valida que Token so tem digitos hex (0-9A-Fa-f), 1 a MaxLen deles.
Procedure.b Mamute_IsHexString(Token.s, MaxLen.i)
  If Len(Token) < 1 Or Len(Token) > MaxLen
    ProcedureReturn #False
  EndIf
  Protected i
  For i = 1 To Len(Token)
    If FindString("0123456789ABCDEFabcdef", Mid(Token, i, 1)) = 0
      ProcedureReturn #False
    EndIf
  Next
  ProcedureReturn #True
EndProcedure

; Endereco de 16 bits sem sinal, 1-4 digitos hex (ex.: "4000", "8000").
Procedure.b Mamute_ParseHexAddr(Token.s, *OutValue.Integer)
  If Not Mamute_IsHexString(Token, 4)
    ProcedureReturn #False
  EndIf
  *OutValue\i = Val("$" + Token)
  ProcedureReturn #True
EndProcedure

; Endereco de VRAM - plano, 1-5 digitos hex, validado contra o tamanho
; configurado agora (MamuteSKeyMap ja usa esse idioma de "configuravel em
; Configurar -> Mamute Assembler..." - MamuteVramSize e o mesmo espirito).
; Sem wraparound (diferente dos enderecos de RAM/CPU) - passar do limite e
; erro de sintaxe, nao da volta pro 0.
Procedure.b Mamute_ParseVramAddr(Token.s, *OutValue.Integer)
  If Not Mamute_IsHexString(Token, 5)
    ProcedureReturn #False
  EndIf
  Protected V.i = Val("$" + Token)
  If V < 0 Or V >= MamuteVramSize
    ProcedureReturn #False
  EndIf
  *OutValue\i = V
  ProcedureReturn #True
EndProcedure

;- ------------------------------------------------------------
;- Enderecamento estendido do SUPER-X (docs/SPEC.md modulo 45/45b) -
;- "<endereco>[#<slot 0-3>[-<subslot 0-3>]]" ou "<endereco>#V"/"#4" (VRAM) ou
;- "#S"/"#5" (mapeamento PAGE corrente, mesmo efeito de nao informar sufixo
;- nenhum). Usado so' pelos comandos PORTADOS do SUPER-X (XD/XM e futuros -
;- MamuteXdGui.pbi/MamuteXmGui.pbi) - decisao explicita do usuario de NAO
;- retrofitar isso nos comandos herdados do MegaAssembler (D/M/T/F/etc.),
;- que continuam so PAGE-relativos como sempre foram.
;-
;- Sub-slot expandido - pedido explicito do usuario, MSX de verdade
;- suportava ate 1MB de RAM assim (4 slots primarios x 4 sub-slots x 64KB,
;- caso real: cartucho de RAM de 64KB somado aos 64KB padrao rodando CP/M
;- com RAMDISK). MamuteMem() (0-3,0-3,16383) CONTINUA sendo o sub-slot 0 de
;- cada slot primario, sem realocar/duplicar nada - MamuteMemSub() (novo)
;- guarda so os sub-slots 1-3. Ainda NAO existe registrador de "sub-slot
;- ATIVO" por slot primario (isso seria emulacao de hardware de verdade,
;- escopo do debugger/execucao - modulo 32/Mz80Cpu - nao deste parser de
;- endereco) - "<endereco>#<slot>" sem sub-slot informado assume sub-slot 0,
;- sempre, de proposito, decisao simples e documentada.
;-
;- Sub-slots 1-3 comecam SEMPRE como RAM gravavel (sem Vazio/ROM/BASIC por
;- celula - ainda nao existe tela de configuracao fisica por sub-slot,
;- MamuteCfgCell so' cobre [Slot][Pagina]) - decisao deliberada: e exatamente
;- o caso de uso que motivou o pedido (RAM expandida em sub-slot).
;- ------------------------------------------------------------

; [SlotPrimario 0-3][SubSlot-1 0-2 (=sub-slot 1,2,3)][Pagina 0-3][Offset] -
; 4x3x4x16KB = 768KB. Global Dim zera sozinho, mesmo idioma do MamuteMem().
Global Dim MamuteMemSub.a(3, 2, 3, 16383)

Structure MamuteSxTarget
  IsVram.b     ; #True = mira MamuteVRAM(), Addr e' offset plano ali (nao passa por slot/pagina)
  IsExplicit.b ; #True = slot primario explicito informado (#slot ou #slot-subslot) - NAO usa PAGE
  Slot.b       ; slot primario 0-3, valido so quando IsExplicit
  SubSlot.b    ; sub-slot 0-3, valido so quando IsExplicit (0 quando nao informado = sub-slot 0)
EndStructure

; Parseia so a PARTE DEPOIS do "#" (token sem o "#" - ex.: "3-1", "V", "4",
; "S", "5", "3"). #False = sufixo invalido (nem V/4/S/5 nem slot 0-3 valido).
Procedure.b Mamute_ParseSxSlotSuffix(Suffix.s, *OutTarget.MamuteSxTarget)
  Protected U.s = UCase(Suffix)
  If U = "V" Or U = "4"
    *OutTarget\IsVram = #True
    ProcedureReturn #True
  EndIf
  If U = "S" Or U = "5"
    *OutTarget\IsExplicit = #False
    ProcedureReturn #True
  EndIf

  Protected DashPos.i = FindString(U, "-")
  Protected HasDash.b = Bool(DashPos > 0)
  Protected SlotTok.s, SubTok.s
  If HasDash
    SlotTok = Left(U, DashPos - 1)
    SubTok = Mid(U, DashPos + 1)
    If SubTok = "" ; "3-" (traco sem nada depois) - malformado, nao "sem sub-slot"
      ProcedureReturn #False
    EndIf
  Else
    SlotTok = U
    SubTok = ""
  EndIf

  If Len(SlotTok) <> 1 Or FindString("0123", SlotTok) = 0
    ProcedureReturn #False
  EndIf
  *OutTarget\IsExplicit = #True
  *OutTarget\Slot = Val(SlotTok)

  If SubTok <> ""
    If Len(SubTok) <> 1 Or FindString("0123", SubTok) = 0
      ProcedureReturn #False
    EndIf
    *OutTarget\SubSlot = Val(SubTok)
  Else
    *OutTarget\SubSlot = 0
  EndIf
  ProcedureReturn #True
EndProcedure

;- ------------------------------------------------------------
;- Variaveis de debugger do SUPER-X (docs/SPEC.md modulo 45d,
;- others/superx/SUPER-X.DOC.pdf, secao "Debugger variables") - 7 no total:
;- @0-@3 (normais) + @B/@E/@S (especiais - Begin/End/Start-ou-Size,
;- preenchidas automaticamente por comandos de carga em disco quando esses
;- existirem - ainda nao implementados, ver docs/SPEC.md modulo 45 fase F).
;- Cada variavel guarda um ENDERECO COMPLETO (endereco + alvo/slot/sub-
;- slot/VRAM, nao so' o numero cru) - "@0=8000#3-1" grava os dois juntos, e
;- usar "@0" no lugar de um endereco (`Mamute_ParseSxAddr`, ver abaixo)
;- devolve os dois de volta. So' os comandos PORTADOS do SUPER-X entendem
;- variavel (mesma decisao de escopo do resto do modulo 45).
;- ------------------------------------------------------------

Structure MamuteVarSlot
  HasValue.b            ; #True depois de setada pelo menos uma vez
  Addr.i
  Target.MamuteSxTarget
EndStructure

Global Dim MamuteVarNum.MamuteVarSlot(3) ; @0-@3
Global MamuteVarB.MamuteVarSlot          ; @B - Begin address
Global MamuteVarE.MamuteVarSlot          ; @E - End address
Global MamuteVarS.MamuteVarSlot          ; @S - Start address / Size

; Devolve um PONTEIRO pra celula certa (Dim numerado ou um dos 3 Globals
; especiais) a partir do NOME digitado ("0".."3","B","E","S", sem o "@" na
; frente - quem chama ja tira) - 0 (nulo) se o nome nao bater com nenhuma
; das 7 variaveis.
Procedure.i Mamute_VarPtr(Name.s)
  Protected U.s = UCase(Name)
  If Len(U) <> 1
    ProcedureReturn 0
  EndIf
  If U >= "0" And U <= "3"
    ProcedureReturn @MamuteVarNum(Val(U))
  ElseIf U = "B"
    ProcedureReturn @MamuteVarB
  ElseIf U = "E"
    ProcedureReturn @MamuteVarE
  ElseIf U = "S"
    ProcedureReturn @MamuteVarS
  EndIf
  ProcedureReturn 0
EndProcedure

; "Commands store base address in variable 0" (doc do SUPER-X, mesma secao
; "Debugger variables") - XD/XM chamam isso ao abrir com um endereco
; resolvido (MamuteGui_CmdXd/CmdXm, MamuteAssemblerGui.pbi), sobrescrevendo
; @0 sozinho, sem o usuario precisar setar na mao.
Procedure Mamute_VarStoreBase(Addr.i, *T.MamuteSxTarget)
  MamuteVarNum(0)\HasValue = #True
  MamuteVarNum(0)\Addr = Addr
  CopyStructure(*T, @MamuteVarNum(0)\Target, MamuteSxTarget)
EndProcedure

; Declare antecipado - Mamute_SxTargetSuffixText() so' e' definida mais
; abaixo (perto de Mamute_SxWrapAddr()), mesmo motivo/idioma ja documentado
; no topo do projeto pra "declaration order e' load-bearing".
Declare.s Mamute_SxTargetSuffixText(*T.MamuteSxTarget)

; Formata endereco+alvo pro log/rotulo - mesma logica de MamuteXm_FormatAddr
; (MamuteXmGui.pbi), reescrita aqui como utilitario compartilhado (usado
; tambem pela exibicao de variaveis, MamuteAssemblerGui.pbi) - digitos 4 ou
; 5 (VRAM) + sufixo de alvo (Mamute_SxTargetSuffixText, "" quando e' so o
; PAGE corrente).
Procedure.s Mamute_SxFormatAddr(Addr.i, *T.MamuteSxTarget)
  Protected Digits.i = 4
  If *T\IsVram : Digits = 5 : EndIf
  ProcedureReturn Mamute_HexPad(Addr, Digits) + Mamute_SxTargetSuffixText(*T)
EndProcedure

; Parseia "<endereco>[#<sufixo>]" completo, OU "@<nome>" (variavel de
; debugger - devolve o endereco+alvo GRAVADOS na variavel, ignorando
; qualquer coisa depois - nao existe "@0#3" pra sobrescrever o alvo de uma
; variavel, so' redefinindo ela de novo). *OutTarget sempre inicializado
; (mesmo em caso de erro, pra nunca deixar lixo). Addr resolvido pela regra
; certa pro alvo - Mamute_ParseHexAddr (0000-FFFF) pra RAM/ROM/sub-slot;
; Mamute_ParseVramAddr (1-5 digitos, validado contra MamuteVramSize) quando
; o sufixo pedir VRAM - mesma largura que os comandos V/P ja usam, decisao
; de manter a VRAM consistente em vez de travar em 4 digitos so por causa do
; formato original do SUPER-X.
Procedure.b Mamute_ParseSxAddr(Token.s, *OutAddr.Integer, *OutTarget.MamuteSxTarget)
  *OutTarget\IsVram = #False
  *OutTarget\IsExplicit = #False
  *OutTarget\Slot = 0
  *OutTarget\SubSlot = 0

  If Left(Token, 1) = "@"
    Protected *VS.MamuteVarSlot = Mamute_VarPtr(Mid(Token, 2))
    If Not *VS Or Not *VS\HasValue
      ProcedureReturn #False
    EndIf
    *OutAddr\i = *VS\Addr
    CopyStructure(@*VS\Target, *OutTarget, MamuteSxTarget)
    ProcedureReturn #True
  EndIf

  Protected HashPos.i = FindString(Token, "#")
  Protected AddrTok.s, SuffixTok.s
  If HashPos > 0
    AddrTok = Left(Token, HashPos - 1)
    SuffixTok = Mid(Token, HashPos + 1)
    If SuffixTok = "" Or Not Mamute_ParseSxSlotSuffix(SuffixTok, *OutTarget)
      ProcedureReturn #False
    EndIf
  Else
    AddrTok = Token
  EndIf

  If *OutTarget\IsVram
    ProcedureReturn Mamute_ParseVramAddr(AddrTok, *OutAddr)
  EndIf
  ProcedureReturn Mamute_ParseHexAddr(AddrTok, *OutAddr)
EndProcedure

; Le/escreve um byte no ALVO ja resolvido (*T) - equivalente a
; Mamute_ReadByte()/Mamute_WriteByte() (que continuam existindo e em uso por
; todo o resto do Mamute), mas honrando slot/sub-slot explicito ou VRAM em
; vez de sempre passar pelo mapeamento PAGE corrente. *T\IsExplicit=#False e
; IsVram=#False cai direto pro Mamute_ReadByte/WriteByte normal (mesmo
; resultado de sempre) - nenhum comando que use isso muda de comportamento
; quando nenhum sufixo e digitado.
Procedure.a Mamute_SxReadByte(Addr.i, *T.MamuteSxTarget)
  If *T\IsVram
    ProcedureReturn MamuteVRAM(Addr)
  EndIf
  If Not *T\IsExplicit
    ProcedureReturn Mamute_ReadByte(Addr)
  EndIf
  Protected Pagina.i = (Addr >> 14) & 3
  Protected Offset.i = Addr & (#Mamute_PageSize - 1)
  If *T\SubSlot = 0
    ProcedureReturn MamuteMem(*T\Slot, Pagina, Offset)
  EndIf
  ProcedureReturn MamuteMemSub(*T\Slot, *T\SubSlot - 1, Pagina, Offset)
EndProcedure

; #True se escreveu de verdade. Sub-slot 0 respeita a configuracao fisica da
; celula (MamuteCfgCell, so RAM aceita escrita - mesma regra do
; Mamute_WriteByte comum, so que consultando o Slot EXPLICITO em vez do
; MamutePageMap). Sub-slots 1-3 sao sempre RAM gravavel (ver comentario no
; topo da secao - ainda nao ha config fisica por sub-slot).
Procedure.b Mamute_SxWriteByte(Addr.i, Value.a, *T.MamuteSxTarget)
  If *T\IsVram
    MamuteVRAM(Addr) = Value
    ProcedureReturn #True
  EndIf
  If Not *T\IsExplicit
    ProcedureReturn Mamute_WriteByte(Addr, Value)
  EndIf
  Protected Pagina.i = (Addr >> 14) & 3
  Protected Offset.i = Addr & (#Mamute_PageSize - 1)
  If *T\SubSlot = 0
    If MamuteCfgCell(*T\Slot, Pagina)\Tipo <> #MamuteMem_RAM
      ProcedureReturn #False
    EndIf
    MamuteMem(*T\Slot, Pagina, Offset) = Value
    ProcedureReturn #True
  EndIf
  MamuteMemSub(*T\Slot, *T\SubSlot - 1, Pagina, Offset) = Value
  ProcedureReturn #True
EndProcedure

; Descreve o alvo pro rotulo de status/titulo de janela (XD/XM) - "" quando
; e' so o PAGE corrente (nada de especial pra mostrar).
Procedure.s Mamute_SxTargetSuffixText(*T.MamuteSxTarget)
  If *T\IsVram
    ProcedureReturn "#V"
  EndIf
  If Not *T\IsExplicit
    ProcedureReturn ""
  EndIf
  If *T\SubSlot = 0
    ProcedureReturn "#" + Str(*T\Slot)
  EndIf
  ProcedureReturn "#" + Str(*T\Slot) + "-" + Str(*T\SubSlot)
EndProcedure

; Envelopa um endereco pro alvo - 0000-FFFF (16 bits, AND) pra RAM/ROM/
; sub-slot; MODULO #Mamute_VramMaxSize pra VRAM (tem que ser modulo de
; verdade, nao AND - 192KB nao e potencia de 2). Usado pela navegacao da
; grade do XD (paginacao +-128 bytes escapa da faixa facil).
Procedure.i Mamute_SxWrapAddr(Addr.i, *T.MamuteSxTarget)
  If *T\IsVram
    Protected M.i = Addr % #Mamute_VramMaxSize
    If M < 0 : M + #Mamute_VramMaxSize : EndIf
    ProcedureReturn M
  EndIf
  ProcedureReturn Addr & $FFFF
EndProcedure

; Maior endereco valido pro alvo - $FFFF pra RAM/ROM/sub-slot, MamuteVramSize-1
; (tamanho CONFIGURADO agora, nao o teto fisico de 192KB do array) pra VRAM -
; mesmo teto que Mamute_ParseVramAddr ja valida na digitacao manual. Usado
; pelo default de 256 bytes quando <fim> e' omitido (docs/SPEC.md modulo 45g/
; 45h, XD/XA) - CLAMPA em vez de dar a volta, pra nunca produzir um EndAddr <
; StartAddr sozinho perto do topo da faixa.
Procedure.i Mamute_SxMaxAddr(*T.MamuteSxTarget)
  If *T\IsVram
    ProcedureReturn MamuteVramSize - 1
  EndIf
  ProcedureReturn $FFFF
EndProcedure

;- ------------------------------------------------------------
;- Calculadora do comando CL (MamuteGui_CmdCl, MamuteAssemblerGui.pbi) -
;- avaliador de expressao independente do Z80Asm::EvalExpr (que existe pra
;- outro proposito - fonte-assembly, com simbolos/segmentos e DEFAULT
;- DECIMAL classico M80) porque o CL segue a convencao inversa, ja
;- estabelecida no resto do Mamute: hexa por padrao, sem sufixo nenhum (ver
;- Mamute_ParseHexAddr acima). Tudo em 16 bits sem sinal, com wraparound em
;- toda operacao (mesma convencao de endereco do resto do Mamute) - nao ha
;- overflow de verdade, um resultado "grande demais" so' da a volta.
;- ------------------------------------------------------------

; Digitos validos em cada base, sem limite de tamanho (Mamute_IsHexString
; acima exige um MaxLen porque foi feita pra enderecos de largura fixa).
Procedure.b Mamute_IsOctalDigits(s.s)
  If Len(s) < 1
    ProcedureReturn #False
  EndIf
  Protected i.i
  For i = 1 To Len(s)
    If FindString("01234567", Mid(s, i, 1)) = 0
      ProcedureReturn #False
    EndIf
  Next
  ProcedureReturn #True
EndProcedure

Procedure.b Mamute_IsDecimalDigits(s.s)
  If Len(s) < 1
    ProcedureReturn #False
  EndIf
  Protected i.i
  For i = 1 To Len(s)
    If FindString("0123456789", Mid(s, i, 1)) = 0
      ProcedureReturn #False
    EndIf
  Next
  ProcedureReturn #True
EndProcedure

Procedure.b Mamute_IsBinaryDigits(s.s)
  If Len(s) < 1
    ProcedureReturn #False
  EndIf
  Protected i.i
  For i = 1 To Len(s)
    If Mid(s, i, 1) <> "0" And Mid(s, i, 1) <> "1"
      ProcedureReturn #False
    EndIf
  Next
  ProcedureReturn #True
EndProcedure

Procedure.i Mamute_OctalToInt(s.s)
  Protected i.i, V.i = 0
  For i = 1 To Len(s)
    V = (V << 3) | Val(Mid(s, i, 1))
  Next
  ProcedureReturn V
EndProcedure

; Numero da calculadora CL - mesma convencao hexa-por-padrao do resto do
; Mamute, estendida com sufixos D/d (decimal), B/b (binario), H/h (hexa,
; redundante com o padrao) e O/o (octal), pedido explicito do usuario. O
; sufixo tem prioridade sobre o hexa-padrao SE os digitos antes dele forem
; validos naquela base (mesma regra classica M80/Nestor80 de Z80Asm.pbi, so
; com o padrao trocado de decimal pra hexa) - por isso "10D" vira decimal
; 10, nao hexa 10D; pra hexa de verdade nesse caso especifico, use o
; sufixo H explicito ("10DH").
Procedure.b Mamute_CL_ParseNumber(Token.s, *OutValue.Integer)
  Protected Raw.s = UCase(Token)
  If Raw = ""
    ProcedureReturn #False
  EndIf
  Protected C2.s = Right(Raw, 1)
  Protected Digits.s, Value.i, Ok.b = #False

  If C2 = "H"
    Digits = Left(Raw, Len(Raw) - 1)
    If Digits <> "" And Mamute_IsHexString(Digits, Len(Digits))
      Value = Val("$" + Digits) : Ok = #True
    EndIf
  ElseIf C2 = "O"
    Digits = Left(Raw, Len(Raw) - 1)
    If Digits <> "" And Mamute_IsOctalDigits(Digits)
      Value = Mamute_OctalToInt(Digits) : Ok = #True
    EndIf
  ElseIf C2 = "D"
    Digits = Left(Raw, Len(Raw) - 1)
    If Digits <> "" And Mamute_IsDecimalDigits(Digits)
      Value = Val(Digits) : Ok = #True
    EndIf
  ElseIf C2 = "B"
    Digits = Left(Raw, Len(Raw) - 1)
    If Digits <> "" And Mamute_IsBinaryDigits(Digits)
      Value = Val("%" + Digits) : Ok = #True
    EndIf
  EndIf

  If Not Ok And Mamute_IsHexString(Raw, Len(Raw))
    Value = Val("$" + Raw) : Ok = #True
  EndIf

  If Not Ok
    ProcedureReturn #False
  EndIf

  *OutValue\i = Value & $FFFF
  ProcedureReturn #True
EndProcedure

; Tokens crus da ultima chamada a Mamute_CL_Tokenize()/tabuleiro do parser -
; Global de proposito (mesmo idioma de MamuteAsmLastStartAddr etc. no resto
; do arquivo): o comando CL roda um de cada vez, sincrono, sem reentrancia,
; entao nao precisa de contexto passado por ponteiro entre os niveis de
; precedencia abaixo.
Global Dim MamuteCL_Tok.s(255)
Global MamuteCL_NTok.i
Global MamuteCL_Pos.i
Global MamuteCL_LastError.s

Procedure.b Mamute_CL_Tokenize(Expr.s)
  MamuteCL_NTok = 0
  Protected TextLen.i = Len(Expr)
  Protected I.i = 1
  Protected C.s, U.s
  While I <= TextLen
    C = Mid(Expr, I, 1)
    U = UCase(C)
    If C = " " Or C = Chr(9)
      I + 1
      Continue
    EndIf

    If (C >= "0" And C <= "9") Or (U >= "A" And U <= "Z")
      Protected Start.i = I
      While I <= TextLen And ((Mid(Expr, I, 1) >= "0" And Mid(Expr, I, 1) <= "9") Or
                               (UCase(Mid(Expr, I, 1)) >= "A" And UCase(Mid(Expr, I, 1)) <= "Z"))
        I + 1
      Wend
      If MamuteCL_NTok >= ArraySize(MamuteCL_Tok())
        MamuteCL_LastError = "ERRO DE SINTAXE"
        ProcedureReturn #False
      EndIf
      MamuteCL_Tok(MamuteCL_NTok) = Mid(Expr, Start, I - Start)
      MamuteCL_NTok + 1
      Continue
    EndIf

    If FindString("+-*/%|&^!()", C)
      If MamuteCL_NTok >= ArraySize(MamuteCL_Tok())
        MamuteCL_LastError = "ERRO DE SINTAXE"
        ProcedureReturn #False
      EndIf
      MamuteCL_Tok(MamuteCL_NTok) = C
      MamuteCL_NTok + 1
      I + 1
      Continue
    EndIf

    ; "@<nome>" - variavel de debugger do SUPER-X (docs/SPEC.md modulo 45d) -
    ; vira o ENDERECO cru gravado nela (so' o numero, sem slot/alvo - nao faz
    ; sentido dentro de uma expressao aritmetica) - exemplo do proprio manual
    ; original: "CL @1+1". Mesmo truque de marcador Chr(1) do literal ASCII
    ; acima - ParsePrimary ja sabe pular Mamute_CL_ParseNumber() pra esses.
    If C = "@"
      Protected VStart.i = I
      I + 1
      While I <= TextLen And ((Mid(Expr, I, 1) >= "0" And Mid(Expr, I, 1) <= "9") Or
                               (UCase(Mid(Expr, I, 1)) >= "A" And UCase(Mid(Expr, I, 1)) <= "Z"))
        I + 1
      Wend
      Protected VarName.s = Mid(Expr, VStart + 1, I - VStart - 1)
      Protected *VS2.MamuteVarSlot = Mamute_VarPtr(VarName)
      If Not *VS2 Or Not *VS2\HasValue
        MamuteCL_LastError = "VARIAVEL INVALIDA OU NAO DEFINIDA: @" + VarName
        ProcedureReturn #False
      EndIf
      If MamuteCL_NTok >= ArraySize(MamuteCL_Tok())
        MamuteCL_LastError = "ERRO DE SINTAXE"
        ProcedureReturn #False
      EndIf
      MamuteCL_Tok(MamuteCL_NTok) = Chr(1) + Str(*VS2\Addr)
      MamuteCL_NTok + 1
      Continue
    EndIf

    ; Literal ASCII entre aspas simples OU duplas, 0-2 caracteres, delimitador
    ; dobrado escapa a si mesmo ("" ou '') - mesma convencao ja usada pelo
    ; tokenizador de expressao do Z80Asm.pbi (Z80Asm::EvalExpr), reaproveitada
    ; aqui pra bater com o pedido do usuario (numeros da calculadora do
    ; SUPER-X aceitam ASCII entre aspas, "max 2 letters"). 1 char = o codigo
    ; dele; 2 chars = byte alto (1o) + byte baixo (2o), igual Z80Asm. O valor
    ; ja calculado vira token marcado com Chr(1) na frente - nunca colide com
    ; um token normal (so' digito/letra vem da rotina acima) - ParsePrimary
    ; reconhece o marcador e pula Mamute_CL_ParseNumber() direto pro Val().
    If C = "'" Or C = Chr(34)
      Protected Delim.s = C
      Protected Body.s = ""
      Protected Closed.b = #False
      I + 1
      While I <= TextLen
        Protected C2.s = Mid(Expr, I, 1)
        If C2 = Delim
          If I < TextLen And Mid(Expr, I + 1, 1) = Delim
            Body + Delim : I + 2 : Continue
          EndIf
          I + 1
          Closed = #True
          Break
        EndIf
        Body + C2 : I + 1
      Wend
      If Not Closed
        MamuteCL_LastError = "ASPAS SEM FECHAR"
        ProcedureReturn #False
      EndIf
      Protected LitVal.i
      Select Len(Body)
        Case 0 : LitVal = 0
        Case 1 : LitVal = Asc(Body)
        Case 2 : LitVal = (Asc(Left(Body, 1)) << 8) | Asc(Mid(Body, 2, 1))
        Default
          MamuteCL_LastError = "STRING COM MAIS DE 2 CARACTERES: " + Body
          ProcedureReturn #False
      EndSelect
      If MamuteCL_NTok >= ArraySize(MamuteCL_Tok())
        MamuteCL_LastError = "ERRO DE SINTAXE"
        ProcedureReturn #False
      EndIf
      MamuteCL_Tok(MamuteCL_NTok) = Chr(1) + Str(LitVal & $FFFF)
      MamuteCL_NTok + 1
      Continue
    EndIf

    MamuteCL_LastError = "ERRO DE SINTAXE"
    ProcedureReturn #False
  Wend
  ProcedureReturn #True
EndProcedure

Procedure.s Mamute_CL_Peek()
  If MamuteCL_Pos < MamuteCL_NTok
    ProcedureReturn MamuteCL_Tok(MamuteCL_Pos)
  EndIf
  ProcedureReturn ""
EndProcedure

; Descida recursiva classica, precedencia estilo C (do mais apertado pro
; mais frouxo): unario (- ! +) > * / % > + - > & (and) > ^ (xor) > | (or).
; So' Mamute_CL_ParsePrimary() referencia Mamute_CL_ParseOr() de volta (pros
; parenteses) - Declare width antecipado por seguranca, mesmo idioma ja
; usado em BadigEditor.pb pra procedures referenciadas fora de ordem (ver
; nota de "declaration order e load-bearing" no topo do projeto).
Declare.b Mamute_CL_ParseOr(*OutValue.Integer)

Procedure.b Mamute_CL_ParsePrimary(*OutValue.Integer)
  Protected Tok.s = Mamute_CL_Peek()
  If Tok = ""
    MamuteCL_LastError = "ERRO DE SINTAXE"
    ProcedureReturn #False
  EndIf

  If Tok = "("
    MamuteCL_Pos + 1
    Protected Inner.i
    If Not Mamute_CL_ParseOr(@Inner)
      ProcedureReturn #False
    EndIf
    If Mamute_CL_Peek() <> ")"
      MamuteCL_LastError = "ERRO DE SINTAXE"
      ProcedureReturn #False
    EndIf
    MamuteCL_Pos + 1
    *OutValue\i = Inner
    ProcedureReturn #True
  EndIf

  Protected Value.i
  If Left(Tok, 1) = Chr(1) ; literal ASCII ja calculado no tokenizador, ver Mamute_CL_Tokenize
    Value = Val(Mid(Tok, 2))
    MamuteCL_Pos + 1
    *OutValue\i = Value
    ProcedureReturn #True
  EndIf
  If Not Mamute_CL_ParseNumber(Tok, @Value)
    MamuteCL_LastError = "NUMERO INVALIDO: " + Tok
    ProcedureReturn #False
  EndIf
  MamuteCL_Pos + 1
  *OutValue\i = Value
  ProcedureReturn #True
EndProcedure

Procedure.b Mamute_CL_ParseUnary(*OutValue.Integer)
  Protected Tok.s = Mamute_CL_Peek()
  If Tok = "-"
    MamuteCL_Pos + 1
    Protected V.i
    If Not Mamute_CL_ParseUnary(@V)
      ProcedureReturn #False
    EndIf
    *OutValue\i = (-V) & $FFFF
    ProcedureReturn #True
  ElseIf Tok = "!"
    MamuteCL_Pos + 1
    Protected V2.i
    If Not Mamute_CL_ParseUnary(@V2)
      ProcedureReturn #False
    EndIf
    *OutValue\i = (~V2) & $FFFF ; "!" do CL = NOT bit a bit ("~" do PureBasic - o "!" do PB e' XOR, nao serve aqui)
    ProcedureReturn #True
  ElseIf Tok = "+"
    MamuteCL_Pos + 1
    ProcedureReturn Mamute_CL_ParseUnary(*OutValue)
  EndIf
  ProcedureReturn Mamute_CL_ParsePrimary(*OutValue)
EndProcedure

Procedure.b Mamute_CL_ParseMul(*OutValue.Integer)
  Protected L.i
  If Not Mamute_CL_ParseUnary(@L)
    ProcedureReturn #False
  EndIf
  Protected Tok.s = Mamute_CL_Peek()
  While Tok = "*" Or Tok = "/" Or Tok = "%"
    MamuteCL_Pos + 1
    Protected R.i
    If Not Mamute_CL_ParseUnary(@R)
      ProcedureReturn #False
    EndIf
    Select Tok
      Case "*"
        L = (L * R) & $FFFF
      Case "/"
        If R = 0
          MamuteCL_LastError = "DIVISAO POR ZERO"
          ProcedureReturn #False
        EndIf
        L = (L / R) & $FFFF
      Case "%"
        If R = 0
          MamuteCL_LastError = "DIVISAO POR ZERO"
          ProcedureReturn #False
        EndIf
        L = (L % R) & $FFFF
    EndSelect
    Tok = Mamute_CL_Peek()
  Wend
  *OutValue\i = L
  ProcedureReturn #True
EndProcedure

Procedure.b Mamute_CL_ParseAdd(*OutValue.Integer)
  Protected L.i
  If Not Mamute_CL_ParseMul(@L)
    ProcedureReturn #False
  EndIf
  Protected Tok.s = Mamute_CL_Peek()
  While Tok = "+" Or Tok = "-"
    MamuteCL_Pos + 1
    Protected R.i
    If Not Mamute_CL_ParseMul(@R)
      ProcedureReturn #False
    EndIf
    If Tok = "+"
      L = (L + R) & $FFFF
    Else
      L = (L - R) & $FFFF
    EndIf
    Tok = Mamute_CL_Peek()
  Wend
  *OutValue\i = L
  ProcedureReturn #True
EndProcedure

Procedure.b Mamute_CL_ParseAnd(*OutValue.Integer)
  Protected L.i
  If Not Mamute_CL_ParseAdd(@L)
    ProcedureReturn #False
  EndIf
  While Mamute_CL_Peek() = "&"
    MamuteCL_Pos + 1
    Protected R.i
    If Not Mamute_CL_ParseAdd(@R)
      ProcedureReturn #False
    EndIf
    L = (L & R) & $FFFF
  Wend
  *OutValue\i = L
  ProcedureReturn #True
EndProcedure

Procedure.b Mamute_CL_ParseXor(*OutValue.Integer)
  Protected L.i
  If Not Mamute_CL_ParseAnd(@L)
    ProcedureReturn #False
  EndIf
  While Mamute_CL_Peek() = "^"
    MamuteCL_Pos + 1
    Protected R.i
    If Not Mamute_CL_ParseAnd(@R)
      ProcedureReturn #False
    EndIf
    L = (L ! R) & $FFFF ; "^" do CL = XOR ("!" do PureBasic)
  Wend
  *OutValue\i = L
  ProcedureReturn #True
EndProcedure

Procedure.b Mamute_CL_ParseOr(*OutValue.Integer)
  Protected L.i
  If Not Mamute_CL_ParseXor(@L)
    ProcedureReturn #False
  EndIf
  While Mamute_CL_Peek() = "|"
    MamuteCL_Pos + 1
    Protected R.i
    If Not Mamute_CL_ParseXor(@R)
      ProcedureReturn #False
    EndIf
    L = (L | R) & $FFFF
  Wend
  *OutValue\i = L
  ProcedureReturn #True
EndProcedure

; Ponto de entrada - tokeniza e avalia Expr inteira (1 numero ou uma
; expressao com operadores/parenteses), sempre em 16 bits sem sinal com
; wraparound. #False + Mamute_CL_LastError preenchido em qualquer erro
; (sintaxe, numero invalido, divisao/modulo por zero, parenteses sobrando).
Procedure.b Mamute_CL_Eval(Expr.s, *OutValue.Integer)
  MamuteCL_LastError = "ERRO DE SINTAXE"
  If Not Mamute_CL_Tokenize(Expr)
    ProcedureReturn #False
  EndIf
  If MamuteCL_NTok = 0
    ProcedureReturn #False
  EndIf
  MamuteCL_Pos = 0
  Protected Result.i
  If Not Mamute_CL_ParseOr(@Result)
    ProcedureReturn #False
  EndIf
  If MamuteCL_Pos < MamuteCL_NTok
    MamuteCL_LastError = "ERRO DE SINTAXE"
    ProcedureReturn #False
  EndIf
  *OutValue\i = Result & $FFFF
  ProcedureReturn #True
EndProcedure

; Monta as linhas formatadas de um dump de memoria (StartAddr..EndAddr,
; inclusive) conforme o Mode do comando C - usado pelo D (manda pro log),
; P e V (manda pro PDF). IsVram=#True le de MamuteVRAM() (endereco plano,
; sem PAGE) em vez de Mamute_ReadByte() (RAM/ROM, resolve pelo mapeamento
; ATIVO). Modo 0/1: hexa+ASCII, 4 ou 16 bytes/linha. Modo 2/3: so hexa, 8
; bytes/linha, com checksum (soma dos bytes, +byte baixo do endereco so no
; modo 2) no final de cada linha.
Procedure Mamute_BuildDumpLines(List Lines.s(), StartAddr.i, EndAddr.i, Mode.b, IsVram.b)
  ClearList(Lines())
  Protected BytesPerLine.i
  Select Mode
    Case 0 : BytesPerLine = 4
    Case 1 : BytesPerLine = 16
    Default : BytesPerLine = 8 ; modo 2/3
  EndSelect

  Protected AddrDigits.i = 4
  If IsVram : AddrDigits = 5 : EndIf

  Protected Addr.i = StartAddr
  Protected LineAddr.i, HexPart.s, AsciiPart.s, Checksum.i, i.i, RawByte.a, Line.s
  While Addr <= EndAddr
    LineAddr = Addr
    HexPart = "" : AsciiPart = "" : Checksum = 0
    For i = 0 To BytesPerLine - 1
      If Addr > EndAddr : Break : EndIf
      If IsVram
        RawByte = MamuteVRAM(Addr)
      Else
        RawByte = Mamute_ReadByte(Addr & $FFFF)
      EndIf
      HexPart + Mamute_Hex2(RawByte) + " "
      If Mode = 0 Or Mode = 1
        If RawByte >= 32 And RawByte <= 126
          AsciiPart + Chr(RawByte)
        Else
          AsciiPart + "."
        EndIf
      EndIf
      Checksum + RawByte
      Addr + 1
    Next

    Line = Mamute_HexPad(LineAddr, AddrDigits) + ": " + HexPart
    Select Mode
      Case 0, 1
        Line + " " + AsciiPart
      Case 2
        Line + RSet(Hex((Checksum + (LineAddr & $FF)) & $FF), 2, "0")
      Case 3
        Line + RSet(Hex(Checksum & $FF), 2, "0")
    EndSelect
    AddElement(Lines())
    Lines() = Line
  Wend
EndProcedure

; Mesma ideia de Mamute_BuildDumpLines() acima, mas honrando um
; MamuteSxTarget completo (slot/sub-slot explicito ou VRAM via
; Mamute_SxReadByte) em vez de so' um flag IsVram - usada SO' pela forma de
; dois/tres enderecos do XD (docs/SPEC.md modulo 45g), que aceita
; "<inic>#<slot>-<subslot>,<fim>[,<arquivo>]" (o mesmo sufixo de slot que a
; forma de UM endereco/grade interativa ja aceitava desde o modulo 45b).
; Mamute_BuildDumpLines() em si fica INTOCADA - continua servindo D/P/V
; (heranca MegaAssembler, com seus proprios 4 modos via comando C).
;
; Formato FIXO (pedido explicito do usuario, 2026-08-26 - "esqueci de dizer
; na epoca"): sempre 8 bytes/linha, hexa E ASCII E checksum juntos na MESMA
; linha - "AAAA XX XX XX XX XX XX XX XX : YY : QQQQQQQQ" (AAAA=endereco,
; XX=bytes, YY=checksum de 1 byte, QQQQQQQQ=ASCII dos bytes, "." pros nao-
; imprimiveis). Substituiu os 4 modos antigos (herdados de Mode.b, que
; alternavam ascii OU checksum, nunca os dois juntos) - agora e' sempre os
; tres juntos, sem selecao de modo nenhuma pro XD (o comando C continua so
; pro D/P/V, que tem seu proprio historico de formato). ChecksumAddrMode
; (comando XCS, MamuteGui_CmdXcs) troca so' o CALCULO do checksum: soma dos
; bytes sozinha (#False, "normal") ou soma dos bytes + byte baixo do
; endereco da linha (#True, "+ADDR") - mesma formula ja usada pelos antigos
; modos 2/3 de Mamute_BuildDumpLines(), agora exposta como um toggle
; independente em vez de amarrada a um "modo de exibicao" com 4 opcoes.
Procedure Mamute_BuildDumpLinesSx(List Lines.s(), StartAddr.i, EndAddr.i, ChecksumAddrMode.b, *T.MamuteSxTarget)
  ClearList(Lines())
  Protected BytesPerLine.i = 8

  Protected AddrDigits.i = 4
  If *T\IsVram : AddrDigits = 5 : EndIf

  Protected Addr.i = StartAddr
  Protected LineAddr.i, HexPart.s, AsciiPart.s, Checksum.i, i.i, RawByte.a, Line.s
  While Addr <= EndAddr
    LineAddr = Addr
    HexPart = "" : AsciiPart = "" : Checksum = 0
    For i = 0 To BytesPerLine - 1
      If Addr > EndAddr : Break : EndIf
      RawByte = Mamute_SxReadByte(Addr, *T)
      HexPart + Mamute_Hex2(RawByte) + " "
      If RawByte >= 32 And RawByte <= 126
        AsciiPart + Chr(RawByte)
      Else
        AsciiPart + "."
      EndIf
      Checksum + RawByte
      Addr + 1
    Next

    If ChecksumAddrMode
      Checksum + (LineAddr & $FF)
    EndIf

    Line = Mamute_HexPad(LineAddr, AddrDigits) + " " + Trim(HexPart) + " : " + Mamute_Hex2(Checksum & $FF) + " : " + AsciiPart
    AddElement(Lines())
    Lines() = Line
  Wend
EndProcedure

; Despejo em texto PURO ASCII (sem coluna hexa nenhuma) - usado pela forma de
; dois/tres enderecos do XA (docs/SPEC.md modulo 45h, porta do comando A do
; SUPER-X). 64 bytes/linha (a mesma largura da grade interativa MamuteXaGui.pbi,
; 16x16=256 bytes por tela, entao 4 linhas de grade = 1 linha de log). Nao
; recebe "Mode" (o XD tem 4 formatos hexa+checksum, mas o A do SUPER-X e' so'
; texto - nao ha modo pra escolher aqui).
Procedure Mamute_BuildAsciiDumpLines(List Lines.s(), StartAddr.i, EndAddr.i, *T.MamuteSxTarget)
  ClearList(Lines())
  Protected AddrDigits.i = 4
  If *T\IsVram : AddrDigits = 5 : EndIf
  Protected BytesPerLine.i = 64

  Protected Addr.i = StartAddr
  Protected LineAddr.i, Txt.s, i.i, RawByte.a
  While Addr <= EndAddr
    LineAddr = Addr
    Txt = ""
    For i = 0 To BytesPerLine - 1
      If Addr > EndAddr : Break : EndIf
      RawByte = Mamute_SxReadByte(Addr, *T)
      If RawByte >= 32 And RawByte <= 126
        Txt + Chr(RawByte)
      Else
        Txt + "."
      EndIf
      Addr + 1
    Next
    AddElement(Lines())
    Lines() = Mamute_HexPad(LineAddr, AddrDigits) + ": " + Txt
  Wend
EndProcedure

; Grava Lines() (uma linha de texto por elemento) num arquivo de texto puro,
; com HeaderText (se nao vazio) na primeira linha - usado pelo terceiro
; campo (<arquivo>) do XI (docs/SPEC.md modulo 45i): ao contrario do
; XD/XA (que salvam BYTES CRUS via o dialogo do SAVE), o XI salva a
; LISTAGEM de texto do disassembly direto, sem dialogo nenhum - decisao
; explicita do usuario via pergunta direta ("salva a LISTAGEM de texto").
; #True se gravou com sucesso.
Procedure.b Mamute_SaveTextListing(FilePath.s, List Lines.s(), HeaderText.s = "")
  Protected Fh = CreateFile(#PB_Any, FilePath)
  If Not Fh
    ProcedureReturn #False
  EndIf
  If HeaderText <> ""
    WriteStringN(Fh, HeaderText)
  EndIf
  ForEach Lines()
    WriteStringN(Fh, Lines())
  Next
  CloseFile(Fh)
  ProcedureReturn #True
EndProcedure

; Deslocamento com sinal opcional ("+"/"-" na frente, 1-2 digitos hex depois)
; - faixa -7Fh (-127) a 80h (128), pedido explicito do usuario. "80" sem
; sinal e tratado como positivo (+80h), igual "+80".
Procedure.b Mamute_ParseHexOffset(Token.s, *OutValue.Integer)
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
  If Not Mamute_IsHexString(Digits, 2)
    ProcedureReturn #False
  EndIf
  Protected Value.i = Sign * Val("$" + Digits)
  If Value < -$7F Or Value > $80
    ProcedureReturn #False
  EndIf
  *OutValue\i = Value
  ProcedureReturn #True
EndProcedure

;- ------------------------------------------------------------
;- Disassembler Z80 (comandos L/LP) - pedido explicito do usuario: "voce tem
;- os dados do Z80 consigo" (confirmado - conjunto de instrucoes documentado
;- e as formas nao-documentadas mais estaveis/conhecidas, como IXH/IXL/IYH/
;- IYL e as formas indexadas do CB, sao bem estabelecidas e usadas aqui) -
;- decodificacao de bytes crus em texto mnemonico, do zero (nao existe
;- nenhuma tabela de opcodes reaproveitavel no assemblador Z80Asm.pbi deste
;- projeto - ele CODIFICA mnemonico->bytes proceduralmente por familia de
;- instrucao, nao tem uma tabela estatica bytes->mnemonico pra inverter).
;-
;- Decomposicao usada (esquema padrao/classico de decodificacao do Z80,
;- amplamente documentado - a mesma base conceitual dos dois projetos que o
;- usuario indicou como referencia, DASM80 e disark): pro byte de opcode b,
;-   x = (b>>6)&3, y=(b>>3)&7, z=b&7, p=y>>1, q=y&1
;- Cada bloco x/z abaixo segue exatamente essa tabela classica.
;-
;- IndexMode (0=nenhum,1=IX,2=IY) troca H/L por IXH/IXL/IYH/IYL, (HL) por
;- (IX+d)/(IY+d), e HL por IX/IY em QUALQUER lugar da tabela base onde esses
;- registradores apareceriam - funciona porque a mesma tabela/formulas sao
;- reaproveitadas com tabelas de nomes de registrador diferentes; opcodes que
;- NAO referenciam H/L/(HL)/HL de jeito nenhum (ex.: "LD BC,nn") produzem o
;- MESMO texto nas 3 tabelas, entao nao precisa de uma lista separada de
;- "quais opcodes o DD/FD afeta" - a substituicao "automatica" ja da o
;- resultado certo em todos os casos (inclusive EX DE,HL/EXX/HALT, que nunca
;- passam pelas tabelas de registrador parametrizadas, entao ficam
;- corretamente IMUNES ao prefixo, igual o hardware real).
;-
;- Prefixos DD/FD encadeados (ex.: "DD FD 21 xx xx") sao tratados exatamente
;- como o hardware real: cada prefixo warning e consumido 1 byte por vez, so
;- o ULTIMO prefixo antes do opcode de verdade "vale" - implementado com um
;- laco simples que consome DD/FD em sequencia antes de decodificar.
;- ------------------------------------------------------------
;-

; Leitura de byte pro disassembler - Sx-aware (docs/SPEC.md modulo 45i, porta
; do "I" do SUPER-X como XI) quando *T e' passado (endereco explicito/slot/
; sub-slot/VRAM honrado via Mamute_SxWrapAddr()/Mamute_SxReadByte(), mesma
; convencao do XD/XA/XM), cai pro Mamute_ReadByte()+"&$FFFF" classico
; (comportamento IDENTICO a antes desta mudanca) quando *T e' nulo (0) - TODO
; consumidor PRE-EXISTENTE deste motor (L/LP no modulo 31, o disassembler ao
; vivo do debugger em MamuteDebuggerGui.pbi, o log de step em
; MamuteZ80Cpu.pbi) continua chamando Mamute_DisasmOne()/Mamute_DisasmBuildLines()
; sem esse parametro novo (default 0 automatico), entao continua 100%
; inalterado - so' o XI passa um alvo de verdade.
Procedure.a Mamute_DisasmRb(Addr.i, *T.MamuteSxTarget)
  If *T
    ProcedureReturn Mamute_SxReadByte(Mamute_SxWrapAddr(Addr, *T), *T)
  EndIf
  ProcedureReturn Mamute_ReadByte(Addr & $FFFF)
EndProcedure

; Formata um deslocamento de 1 byte com sinal (-80 a +7F) como "+05"/"-05" -
; usado nos operandos "(IX+05)"/"(IY-05)".
Procedure.s Mamute_DisasmSignedDisp(d.a)
  Protected Signed.i = d
  If Signed > 127 : Signed - 256 : EndIf
  If Signed < 0
    ProcedureReturn "-" + Mamute_Hex2(-Signed)
  Else
    ProcedureReturn "+" + Mamute_Hex2(Signed)
  EndIf
EndProcedure

; Tabela "crua" B/C/D/E/H/L/(HL)/A - SEM substituicao de indice, usada pelo
; CB puro (nao-indexado) e pelo registrador-sombra das formas indexadas do
; CB (esse "sombra" sempre grava no registrador de 8 bits de verdade, nunca
; em IXH/IXL - comportamento real do hardware, mesmo nas formas nao
; documentadas).
Procedure.s Mamute_DisasmReg8Plain(Idx.i)
  Select Idx
    Case 0 : ProcedureReturn "B"
    Case 1 : ProcedureReturn "C"
    Case 2 : ProcedureReturn "D"
    Case 3 : ProcedureReturn "E"
    Case 4 : ProcedureReturn "H"
    Case 5 : ProcedureReturn "L"
    Case 6 : ProcedureReturn "(HL)"
    Case 7 : ProcedureReturn "A"
  EndSelect
  ProcedureReturn "?"
EndProcedure

Procedure.s Mamute_DisasmRotName(y.i)
  Select y
    Case 0 : ProcedureReturn "RLC"
    Case 1 : ProcedureReturn "RRC"
    Case 2 : ProcedureReturn "RL"
    Case 3 : ProcedureReturn "RR"
    Case 4 : ProcedureReturn "SLA"
    Case 5 : ProcedureReturn "SRA"
    Case 6 : ProcedureReturn "SLL" ; nao documentada, mas estavel/conhecida
    Case 7 : ProcedureReturn "SRL"
  EndSelect
  ProcedureReturn "?"
EndProcedure

Procedure.s Mamute_DisasmCC8(y.i)
  Select y
    Case 0 : ProcedureReturn "NZ"
    Case 1 : ProcedureReturn "Z"
    Case 2 : ProcedureReturn "NC"
    Case 3 : ProcedureReturn "C"
    Case 4 : ProcedureReturn "PO"
    Case 5 : ProcedureReturn "PE"
    Case 6 : ProcedureReturn "P"
    Case 7 : ProcedureReturn "M"
  EndSelect
  ProcedureReturn "?"
EndProcedure

Procedure.s Mamute_DisasmAluText(y.i, Operand.s)
  Select y
    Case 0 : ProcedureReturn "ADD A," + Operand
    Case 1 : ProcedureReturn "ADC A," + Operand
    Case 2 : ProcedureReturn "SUB " + Operand
    Case 3 : ProcedureReturn "SBC A," + Operand
    Case 4 : ProcedureReturn "AND " + Operand
    Case 5 : ProcedureReturn "XOR " + Operand
    Case 6 : ProcedureReturn "OR " + Operand
    Case 7 : ProcedureReturn "CP " + Operand
  EndSelect
  ProcedureReturn "?"
EndProcedure

; Par de 16 bits no esquema BC/DE/HL/SP (slot 2 = HL, substituido por IX/IY
; conforme IndexMode).
Procedure.s Mamute_DisasmReg16(Slot.i, IndexMode.b)
  Select Slot
    Case 0 : ProcedureReturn "BC"
    Case 1 : ProcedureReturn "DE"
    Case 2
      Select IndexMode
        Case 1 : ProcedureReturn "IX"
        Case 2 : ProcedureReturn "IY"
        Default : ProcedureReturn "HL"
      EndSelect
    Case 3 : ProcedureReturn "SP"
  EndSelect
  ProcedureReturn "?"
EndProcedure

; Mesma ideia, mas esquema BC/DE/HL/AF (usado so por PUSH/POP) - slot 3 e
; SEMPRE "AF" (nunca substituido - PUSH/POP AF nao existe como IX/IY, o
; hardware real ignora o prefixo nesse caso, e como este slot nunca troca de
; nome aqui, o resultado ja sai certo sem precisar de nenhum caso especial).
Procedure.s Mamute_DisasmReg16Alt(Slot.i, IndexMode.b)
  Select Slot
    Case 0 : ProcedureReturn "BC"
    Case 1 : ProcedureReturn "DE"
    Case 2
      Select IndexMode
        Case 1 : ProcedureReturn "IX"
        Case 2 : ProcedureReturn "IY"
        Default : ProcedureReturn "HL"
      EndSelect
    Case 3 : ProcedureReturn "AF"
  EndSelect
  ProcedureReturn "?"
EndProcedure

; Registrador de 8 bits com substituicao de indice - Idx 4/5 viram IXH/IXL/
; IYH/IYL (nao documentado, mas estavel/conhecido), Idx 6 vira (IX+d)/(IY+d)
; e CONSOME 1 byte de deslocamento em *Cursor (le e avanca) - so quando
; IndexMode<>0; sem prefixo, Idx 6 e so "(HL)" direto, sem byte extra.
Procedure.s Mamute_DisasmReg8(Idx.i, IndexMode.b, *Cursor.Integer, *T.MamuteSxTarget = 0)
  Select Idx
    Case 0 : ProcedureReturn "B"
    Case 1 : ProcedureReturn "C"
    Case 2 : ProcedureReturn "D"
    Case 3 : ProcedureReturn "E"
    Case 4
      Select IndexMode
        Case 1 : ProcedureReturn "IXH"
        Case 2 : ProcedureReturn "IYH"
        Default : ProcedureReturn "H"
      EndSelect
    Case 5
      Select IndexMode
        Case 1 : ProcedureReturn "IXL"
        Case 2 : ProcedureReturn "IYL"
        Default : ProcedureReturn "L"
      EndSelect
    Case 6
      If IndexMode = 0
        ProcedureReturn "(HL)"
      Else
        Protected D.a = Mamute_DisasmRb(*Cursor\i, *T)
        *Cursor\i + 1
        Protected IxName.s
        If IndexMode = 1 : IxName = "IX" : Else : IxName = "IY" : EndIf
        ProcedureReturn "(" + IxName + Mamute_DisasmSignedDisp(D) + ")"
      EndIf
    Case 7 : ProcedureReturn "A"
  EndSelect
  ProcedureReturn "?"
EndProcedure

; Le um imediato de 16 bits little-endian a partir de *Cursor (avanca 2).
Procedure.i Mamute_DisasmReadImm16(*Cursor.Integer, *T.MamuteSxTarget = 0)
  Protected Lo.a = Mamute_DisasmRb(*Cursor\i, *T)
  Protected Hi.a = Mamute_DisasmRb(*Cursor\i + 1, *T)
  *Cursor\i + 2
  ProcedureReturn Lo | (Hi << 8)
EndProcedure

; Le o deslocamento relativo de 1 byte com sinal do JR/DJNZ a partir de
; *Cursor (avanca 1) e calcula o endereco de destino - relativo ao endereco
; JA DEPOIS do deslocamento (mesma convencao do Z80 de verdade: o PC ja
; avancou pela instrucao inteira antes do calculo) - como *Cursor aqui ja
; inclui qualquer prefixo DD/FD consumido antes (ver Mamute_DisasmOne), o
; destino sai certo mesmo num DD/FD+JR "desperdicado".
Procedure.s Mamute_DisasmRelTarget(*Cursor.Integer, *T.MamuteSxTarget = 0)
  Protected e.a = Mamute_DisasmRb(*Cursor\i, *T)
  *Cursor\i + 1
  Protected Signed.i = e
  If Signed > 127 : Signed - 256 : EndIf
  ProcedureReturn Mamute_Hex4((*Cursor\i + Signed) & $FFFF)
EndProcedure

; Decodifica um opcode CB-prefixado (bit ops) - IndexMode=0: 2 bytes (CB+op),
; alvo B/C/D/E/H/L/(HL)/A direto. IndexMode<>0: forma indexada de 4 bytes no
; total (DD/FD CB d op, contando o prefixo) - deslocamento 'd' vem ANTES do
; sub-opcode aqui (diferente das formas nao-CB, onde 'd' vem DEPOIS), alvo
; sempre (IX+d)/(IY+d); campo z2 (0-7, 6=sem copia) seleciona uma copia
; "sombra" nao documentada pro registrador de 8 bits real (nunca IXH/IXL) -
; nao existe pro BIT (nao tem escrita nenhuma pra copiar).
Procedure.s Mamute_DisasmDecodeCB(IndexMode.b, *Cursor.Integer, *T.MamuteSxTarget = 0)
  Protected d.a
  If IndexMode <> 0
    d = Mamute_DisasmRb(*Cursor\i, *T)
    *Cursor\i + 1
  EndIf
  Protected op.a = Mamute_DisasmRb(*Cursor\i, *T)
  *Cursor\i + 1

  Protected x2.i = (op >> 6) & 3
  Protected y2.i = (op >> 3) & 7
  Protected z2.i = op & 7

  Protected Target.s
  If IndexMode = 0
    Target = Mamute_DisasmReg8Plain(z2)
  Else
    Protected IxName.s
    If IndexMode = 1 : IxName = "IX" : Else : IxName = "IY" : EndIf
    Target = "(" + IxName + Mamute_DisasmSignedDisp(d) + ")"
  EndIf

  Protected Result.s
  Select x2
    Case 0 : Result = Mamute_DisasmRotName(y2) + " " + Target
    Case 1 : Result = "BIT " + Str(y2) + "," + Target
    Case 2 : Result = "RES " + Str(y2) + "," + Target
    Case 3 : Result = "SET " + Str(y2) + "," + Target
  EndSelect

  If IndexMode <> 0 And z2 <> 6 And x2 <> 1
    Result + "," + Mamute_DisasmReg8Plain(z2)
  EndIf

  ProcedureReturn Result
EndProcedure

; Decodifica um opcode ED-prefixado - NUNCA afetado por IndexMode (hardware
; real: ED ignora completamente qualquer DD/FD pendente, o prefixo fica so
; "desperdicado" mas ainda conta como byte consumido em Mamute_DisasmOne).
; x2=0 e x2=3 (fora dos blocos de bloco y2>=4/z2<=3) sao oficialmente
; indefinidos - comportamento real e estavel: agem como NOP de 2 bytes.
Procedure.s Mamute_DisasmDecodeED(*Cursor.Integer, *T.MamuteSxTarget = 0)
  Protected ed.a = Mamute_DisasmRb(*Cursor\i, *T)
  *Cursor\i + 1

  Protected x2.i = (ed >> 6) & 3
  Protected y2.i = (ed >> 3) & 7
  Protected z2.i = ed & 7
  Protected p2.i = y2 >> 1
  Protected q2.i = y2 & 1
  Protected Imm16.i
  Protected Rp.s
  Protected ImVal.i

  If x2 = 1
    Select z2
      Case 0
        If y2 = 6 : ProcedureReturn "IN F,(C)" : EndIf
        ProcedureReturn "IN " + Mamute_DisasmReg8Plain(y2) + ",(C)"
      Case 1
        If y2 = 6 : ProcedureReturn "OUT (C),0" : EndIf
        ProcedureReturn "OUT (C)," + Mamute_DisasmReg8Plain(y2)
      Case 2
        Rp = Mamute_DisasmReg16(p2, 0)
        If q2 = 0 : ProcedureReturn "SBC HL," + Rp : EndIf
        ProcedureReturn "ADC HL," + Rp
      Case 3
        Imm16 = Mamute_DisasmReadImm16(*Cursor, *T)
        Rp = Mamute_DisasmReg16(p2, 0)
        If q2 = 0 : ProcedureReturn "LD (" + Mamute_Hex4(Imm16) + ")," + Rp : EndIf
        ProcedureReturn "LD " + Rp + ",(" + Mamute_Hex4(Imm16) + ")"
      Case 4
        ProcedureReturn "NEG"
      Case 5
        If y2 = 1 : ProcedureReturn "RETI" : EndIf
        ProcedureReturn "RETN"
      Case 6
        Select y2
          Case 0, 1, 4, 5 : ImVal = 0
          Case 2, 6 : ImVal = 1
          Case 3, 7 : ImVal = 2
        EndSelect
        ProcedureReturn "IM " + Str(ImVal)
      Case 7
        Select y2
          Case 0 : ProcedureReturn "LD I,A"
          Case 1 : ProcedureReturn "LD R,A"
          Case 2 : ProcedureReturn "LD A,I"
          Case 3 : ProcedureReturn "LD A,R"
          Case 4 : ProcedureReturn "RRD"
          Case 5 : ProcedureReturn "RLD"
          Default : ProcedureReturn "NOP"
        EndSelect
    EndSelect
  ElseIf x2 = 2 And z2 <= 3 And y2 >= 4
    Select y2
      Case 4
        Select z2
          Case 0 : ProcedureReturn "LDI"
          Case 1 : ProcedureReturn "CPI"
          Case 2 : ProcedureReturn "INI"
          Case 3 : ProcedureReturn "OUTI"
        EndSelect
      Case 5
        Select z2
          Case 0 : ProcedureReturn "LDD"
          Case 1 : ProcedureReturn "CPD"
          Case 2 : ProcedureReturn "IND"
          Case 3 : ProcedureReturn "OUTD"
        EndSelect
      Case 6
        Select z2
          Case 0 : ProcedureReturn "LDIR"
          Case 1 : ProcedureReturn "CPIR"
          Case 2 : ProcedureReturn "INIR"
          Case 3 : ProcedureReturn "OTIR"
        EndSelect
      Case 7
        Select z2
          Case 0 : ProcedureReturn "LDDR"
          Case 1 : ProcedureReturn "CPDR"
          Case 2 : ProcedureReturn "INDR"
          Case 3 : ProcedureReturn "OTDR"
        EndSelect
    EndSelect
  EndIf

  ProcedureReturn "NOP"
EndProcedure

; Decodifica um opcode da tabela BASE (nao-CB/ED/DD/FD) - IndexMode troca
; H/L/(HL)/HL pelos equivalentes IX/IY em QUALQUER lugar que apareceriam,
; via Mamute_DisasmReg8()/Reg16()/Reg16Alt() (ver comentario no topo desta
; secao pra por que isso basta, sem precisar de uma lista separada de "quais
; opcodes o prefixo afeta").
Procedure.s Mamute_DisasmDecodeBase(b.a, IndexMode.b, *Cursor.Integer, *T.MamuteSxTarget = 0)
  Protected x.i = (b >> 6) & 3
  Protected y.i = (b >> 3) & 7
  Protected z.i = b & 7
  Protected p.i = y >> 1
  Protected q.i = y & 1
  Protected Result.s
  Protected Imm16.i
  Protected Imm8.a
  Protected RegTxt.s

  Select x
    Case 0
      Select z
        Case 0
          Select y
            Case 0 : Result = "NOP"
            Case 1 : Result = "EX AF,AF'"
            Case 2 : Result = "DJNZ " + Mamute_DisasmRelTarget(*Cursor, *T)
            Case 3 : Result = "JR " + Mamute_DisasmRelTarget(*Cursor, *T)
            Default : Result = "JR " + Mamute_DisasmCC8(y - 4) + "," + Mamute_DisasmRelTarget(*Cursor, *T)
          EndSelect
        Case 1
          If q = 0
            Imm16 = Mamute_DisasmReadImm16(*Cursor, *T)
            Result = "LD " + Mamute_DisasmReg16(p, IndexMode) + "," + Mamute_Hex4(Imm16)
          Else
            Result = "ADD " + Mamute_DisasmReg16(2, IndexMode) + "," + Mamute_DisasmReg16(p, IndexMode)
          EndIf
        Case 2
          Select p
            Case 0
              If q = 0 : Result = "LD (BC),A" : Else : Result = "LD A,(BC)" : EndIf
            Case 1
              If q = 0 : Result = "LD (DE),A" : Else : Result = "LD A,(DE)" : EndIf
            Case 2
              Imm16 = Mamute_DisasmReadImm16(*Cursor, *T)
              If q = 0
                Result = "LD (" + Mamute_Hex4(Imm16) + ")," + Mamute_DisasmReg16(2, IndexMode)
              Else
                Result = "LD " + Mamute_DisasmReg16(2, IndexMode) + ",(" + Mamute_Hex4(Imm16) + ")"
              EndIf
            Case 3
              Imm16 = Mamute_DisasmReadImm16(*Cursor, *T)
              If q = 0 : Result = "LD (" + Mamute_Hex4(Imm16) + "),A" : Else : Result = "LD A,(" + Mamute_Hex4(Imm16) + ")" : EndIf
          EndSelect
        Case 3
          If q = 0 : Result = "INC " + Mamute_DisasmReg16(p, IndexMode) : Else : Result = "DEC " + Mamute_DisasmReg16(p, IndexMode) : EndIf
        Case 4
          Result = "INC " + Mamute_DisasmReg8(y, IndexMode, *Cursor, *T)
        Case 5
          Result = "DEC " + Mamute_DisasmReg8(y, IndexMode, *Cursor, *T)
        Case 6
          RegTxt = Mamute_DisasmReg8(y, IndexMode, *Cursor, *T)
          Imm8 = Mamute_DisasmRb(*Cursor\i, *T)
          *Cursor\i + 1
          Result = "LD " + RegTxt + "," + Mamute_Hex2(Imm8)
        Case 7
          Select y
            Case 0 : Result = "RLCA"
            Case 1 : Result = "RRCA"
            Case 2 : Result = "RLA"
            Case 3 : Result = "RRA"
            Case 4 : Result = "DAA"
            Case 5 : Result = "CPL"
            Case 6 : Result = "SCF"
            Case 7 : Result = "CCF"
          EndSelect
      EndSelect

    Case 1
      If y = 6 And z = 6
        Result = "HALT"
      Else
        Result = "LD " + Mamute_DisasmReg8(y, IndexMode, *Cursor, *T) + "," + Mamute_DisasmReg8(z, IndexMode, *Cursor, *T)
      EndIf

    Case 2
      Result = Mamute_DisasmAluText(y, Mamute_DisasmReg8(z, IndexMode, *Cursor, *T))

    Case 3
      Select z
        Case 0
          Result = "RET " + Mamute_DisasmCC8(y)
        Case 1
          If q = 0
            Result = "POP " + Mamute_DisasmReg16Alt(p, IndexMode)
          Else
            Select p
              Case 0 : Result = "RET"
              Case 1 : Result = "EXX"
              Case 2 : Result = "JP (" + Mamute_DisasmReg16(2, IndexMode) + ")"
              Case 3 : Result = "LD SP," + Mamute_DisasmReg16(2, IndexMode)
            EndSelect
          EndIf
        Case 2
          Imm16 = Mamute_DisasmReadImm16(*Cursor, *T)
          Result = "JP " + Mamute_DisasmCC8(y) + "," + Mamute_Hex4(Imm16)
        Case 3
          Select y
            Case 0
              Imm16 = Mamute_DisasmReadImm16(*Cursor, *T)
              Result = "JP " + Mamute_Hex4(Imm16)
            Case 1
              Result = "?" ; CB ja interceptado antes desta funcao - nunca deveria chegar aqui
            Case 2
              Imm8 = Mamute_DisasmRb(*Cursor\i, *T) : *Cursor\i + 1
              Result = "OUT (" + Mamute_Hex2(Imm8) + "),A"
            Case 3
              Imm8 = Mamute_DisasmRb(*Cursor\i, *T) : *Cursor\i + 1
              Result = "IN A,(" + Mamute_Hex2(Imm8) + ")"
            Case 4
              Result = "EX (SP)," + Mamute_DisasmReg16(2, IndexMode)
            Case 5
              Result = "EX DE,HL" ; nunca substituido - hardware real ignora o prefixo aqui
            Case 6
              Result = "DI"
            Case 7
              Result = "EI"
          EndSelect
        Case 4
          Imm16 = Mamute_DisasmReadImm16(*Cursor, *T)
          Result = "CALL " + Mamute_DisasmCC8(y) + "," + Mamute_Hex4(Imm16)
        Case 5
          If q = 0
            Result = "PUSH " + Mamute_DisasmReg16Alt(p, IndexMode)
          Else
            Select p
              Case 0
                Imm16 = Mamute_DisasmReadImm16(*Cursor, *T)
                Result = "CALL " + Mamute_Hex4(Imm16)
              Case 1 : Result = "?" ; DD ja interceptado antes desta funcao
              Case 2 : Result = "?" ; ED ja interceptado antes desta funcao
              Case 3 : Result = "?" ; FD ja interceptado antes desta funcao
            EndSelect
          EndIf
        Case 6
          Imm8 = Mamute_DisasmRb(*Cursor\i, *T) : *Cursor\i + 1
          Result = Mamute_DisasmAluText(y, Mamute_Hex2(Imm8))
        Case 7
          Result = "RST " + Mamute_Hex2(y * 8)
      EndSelect
  EndSelect

  ProcedureReturn Result
EndProcedure

; Ponto de entrada: decodifica UMA instrucao a partir de Addr (que pode
; comecar com 0, 1 ou mais bytes DD/FD encadeados - ver comentario no topo
; da secao). Devolve o comprimento TOTAL em *OutLen (incluindo prefixos) e o
; texto mnemonico+operandos em *OutText.
; Devolve o texto mnemonico+operandos diretamente (nao por ponteiro de
; String "Out" - esse padrao, embora documentado, travou com acesso
; invalido de verdade neste build/contexto especifico ao escrever em
; *Ptr.String\s vindo de dentro desta unidade de compilacao gigante;
; comprimento total ainda sai por ponteiro de Integer em *OutLen, que
; funciona sem problema (mesmo padrao ja usado em Mamute_ParseHexAddr()
; etc.) - so o ponteiro de String especificamente que nao e confiavel aqui.
Procedure.s Mamute_DisasmOne(Addr.i, *OutLen.Integer, *T.MamuteSxTarget = 0)
  Protected PrefixCount.i = 0
  Protected IndexMode.b = 0
  Protected CurAddr.i = Addr
  Protected b.a = Mamute_DisasmRb(CurAddr, *T)

  While (b = $DD Or b = $FD) And PrefixCount < 8 ; guarda defensiva - encadeamento real nunca chega nem perto disso
    If b = $DD : IndexMode = 1 : Else : IndexMode = 2 : EndIf
    PrefixCount + 1
    CurAddr + 1
    b = Mamute_DisasmRb(CurAddr, *T)
  Wend

  Protected Cursor.i = CurAddr + 1
  Protected Text.s
  Select b
    Case $CB
      Text = Mamute_DisasmDecodeCB(IndexMode, @Cursor, *T)
    Case $ED
      Text = Mamute_DisasmDecodeED(@Cursor, *T)
    Default
      Text = Mamute_DisasmDecodeBase(b, IndexMode, @Cursor, *T)
  EndSelect

  *OutLen\i = PrefixCount + (Cursor - CurAddr)
  ProcedureReturn Text
EndProcedure

; Monta as linhas formatadas "ENDERECO  BYTES-HEXA  MNEMONICO" pros
; comandos L/LP, a partir de StartAddr - se HasEndAddr, decodifica ate
; ultrapassar EndAddr (instrucao que comeca dentro do intervalo entra
; inteira, mesmo que termine depois - comportamento padrao de disassembler,
; igual o exemplo do manual original); senao, decodifica exatamente 10
; instrucoes. A listagem PARA (nao envolve pro endereco 0000) assim que a
; PROXIMA instrucao comecaria depois de FFFF - decodificar enderecos indo
; pra tras no meio de uma mesma listagem seria confuso de ler, diferente do
; wraparound de leitura ja usado pelo SH/M (que faz sentido ali porque so
; devolve UM endereco encontrado, nao uma sequencia de linhas). Se os
; ULTIMOS bytes de uma unica instrucao que ja comecou dentro do limite
; passarem um pouco de FFFF (ex.: uma instrucao de 3 bytes comecando em
; FFFE), esses bytes finais ainda sao lidos via o wraparound normal de
; Mamute_ReadByte(...&$FFFF) - so a listagem como um todo nao continua
; depois disso. *OutNextAddr recebe o endereco logo apos a ultima instrucao
; mostrada, pra "L sem endereco" continuar dali.
Procedure Mamute_DisasmBuildLines(List Lines.s(), StartAddr.i, HasEndAddr.b, EndAddr.i, *OutNextAddr.Integer, *T.MamuteSxTarget = 0)
  ClearList(Lines())
  Protected CurAddr.i = StartAddr
  Protected LineCount.i = 0
  Protected InstrLen.i
  Protected Text.s
  Protected HexBytes.s
  Protected i.i
  Protected RawByte.a
  Protected Line.s
  Protected AddrDigits.i = 4
  Protected MaxAddr.i = $FFFF
  Protected LineAddr.i
  If *T
    If *T\IsVram : AddrDigits = 5 : EndIf
    MaxAddr = Mamute_SxMaxAddr(*T)
  EndIf

  Repeat
    If HasEndAddr
      If CurAddr > EndAddr : Break : EndIf
    Else
      If LineCount >= 10 : Break : EndIf
    EndIf

    Text = Mamute_DisasmOne(CurAddr, @InstrLen, *T)
    If InstrLen < 1 : InstrLen = 1 : EndIf

    HexBytes = ""
    For i = 0 To InstrLen - 1
      RawByte = Mamute_DisasmRb(CurAddr + i, *T)
      If HexBytes <> "" : HexBytes + " " : EndIf
      HexBytes + Mamute_Hex2(RawByte)
    Next

    If *T
      LineAddr = Mamute_SxWrapAddr(CurAddr, *T)
    Else
      LineAddr = CurAddr & $FFFF
    EndIf
    Line = Mamute_HexPad(LineAddr, AddrDigits) + "  " + LSet(HexBytes, 11, " ") + "  " + Text
    AddElement(Lines())
    Lines() = Line

    CurAddr + InstrLen
    LineCount + 1
  Until CurAddr > MaxAddr

  If *T
    *OutNextAddr\i = Mamute_SxWrapAddr(CurAddr, *T)
  Else
    *OutNextAddr\i = CurAddr & $FFFF
  EndIf
EndProcedure

; Converte um caractere ("Q", "1", "z"...) na constante #PB_Shortcut_* certa,
; pra registrar como AddKeyboardShortcut() - usado pelo comando S
; (MamuteMGui.pbi) pras 16 teclas configuraveis. 0 (nenhuma constante) se
; Ch nao for exatamente 1 letra/digito.
Procedure.i Mamute_KeyCharToShortcut(Ch.s)
  If Len(Ch) <> 1
    ProcedureReturn 0
  EndIf
  Select UCase(Ch)
    Case "0" : ProcedureReturn #PB_Shortcut_0
    Case "1" : ProcedureReturn #PB_Shortcut_1
    Case "2" : ProcedureReturn #PB_Shortcut_2
    Case "3" : ProcedureReturn #PB_Shortcut_3
    Case "4" : ProcedureReturn #PB_Shortcut_4
    Case "5" : ProcedureReturn #PB_Shortcut_5
    Case "6" : ProcedureReturn #PB_Shortcut_6
    Case "7" : ProcedureReturn #PB_Shortcut_7
    Case "8" : ProcedureReturn #PB_Shortcut_8
    Case "9" : ProcedureReturn #PB_Shortcut_9
    Case "A" : ProcedureReturn #PB_Shortcut_A
    Case "B" : ProcedureReturn #PB_Shortcut_B
    Case "C" : ProcedureReturn #PB_Shortcut_C
    Case "D" : ProcedureReturn #PB_Shortcut_D
    Case "E" : ProcedureReturn #PB_Shortcut_E
    Case "F" : ProcedureReturn #PB_Shortcut_F
    Case "G" : ProcedureReturn #PB_Shortcut_G
    Case "H" : ProcedureReturn #PB_Shortcut_H
    Case "I" : ProcedureReturn #PB_Shortcut_I
    Case "J" : ProcedureReturn #PB_Shortcut_J
    Case "K" : ProcedureReturn #PB_Shortcut_K
    Case "L" : ProcedureReturn #PB_Shortcut_L
    Case "M" : ProcedureReturn #PB_Shortcut_M
    Case "N" : ProcedureReturn #PB_Shortcut_N
    Case "O" : ProcedureReturn #PB_Shortcut_O
    Case "P" : ProcedureReturn #PB_Shortcut_P
    Case "Q" : ProcedureReturn #PB_Shortcut_Q
    Case "R" : ProcedureReturn #PB_Shortcut_R
    Case "S" : ProcedureReturn #PB_Shortcut_S
    Case "T" : ProcedureReturn #PB_Shortcut_T
    Case "U" : ProcedureReturn #PB_Shortcut_U
    Case "V" : ProcedureReturn #PB_Shortcut_V
    Case "W" : ProcedureReturn #PB_Shortcut_W
    Case "X" : ProcedureReturn #PB_Shortcut_X
    Case "Y" : ProcedureReturn #PB_Shortcut_Y
    Case "Z" : ProcedureReturn #PB_Shortcut_Z
  EndSelect
  ProcedureReturn 0
EndProcedure

;- ------------------------------------------------------------
;- Configuracoes / persistencia
;- ------------------------------------------------------------

Procedure.s MamuteCfg_FilePath()
  ProcedureReturn GetPathPart(ProgramFilename()) + "editor\mamute_settings.json"
EndProcedure

Procedure MamuteCfg_Load()
  Protected Slot, Pagina
  For Slot = 0 To 3
    For Pagina = 0 To 3
      MamuteCfgCell(Slot, Pagina)\Tipo = #MamuteMem_Empty
      MamuteCfgCell(Slot, Pagina)\FilePath = ""
      MamuteCfgCell(Slot, Pagina)\FileOffset = 0
    Next
  Next
  MamuteFontName = "Consolas"
  MamuteFontSize = 16
  MamuteFontBold = #True
  Mamute_SKeyMapDefaults()
  MamuteVramSize = 16384
  MamuteAutoRunAfterTransfer = #False
  MamuteDefaultNotesFile = ""
  MamuteColorFg = 3 : MamuteColorBg = 1 : MamuteColorBorder = 1

  Protected FilePath.s = MamuteCfg_FilePath()
  If FileSize(FilePath) <= 0
    ProcedureReturn
  EndIf

  Protected Json = LoadJSON(#PB_Any, FilePath)
  If Not Json
    ProcedureReturn
  EndIf

  Protected Root = JSONValue(Json)
  Protected M
  M = GetJSONMember(Root, "FontName") : If M : MamuteFontName = GetJSONString(M)  : EndIf
  M = GetJSONMember(Root, "FontSize") : If M : MamuteFontSize = GetJSONInteger(M) : EndIf
  M = GetJSONMember(Root, "FontBold") : If M : MamuteFontBold = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "VramSize") : If M : MamuteVramSize = GetJSONInteger(M) : EndIf
  M = GetJSONMember(Root, "AutoRunAfterTransfer") : If M : MamuteAutoRunAfterTransfer = GetJSONBoolean(M) : EndIf
  M = GetJSONMember(Root, "DefaultNotesFile") : If M : MamuteDefaultNotesFile = GetJSONString(M) : EndIf
  If MamuteVramSize <> 16384 And MamuteVramSize <> 131072 And MamuteVramSize <> 196608
    MamuteVramSize = 16384 ; valor invalido/corrompido - volta pro padrao seguro
  EndIf
  M = GetJSONMember(Root, "ColorFg")     : If M : MamuteColorFg     = GetJSONInteger(M) : EndIf
  M = GetJSONMember(Root, "ColorBg")     : If M : MamuteColorBg     = GetJSONInteger(M) : EndIf
  M = GetJSONMember(Root, "ColorBorder") : If M : MamuteColorBorder = GetJSONInteger(M) : EndIf
  If MamuteColorFg < 0 Or MamuteColorFg > 15 : MamuteColorFg = 3 : EndIf
  If MamuteColorBg < 0 Or MamuteColorBg > 15 : MamuteColorBg = 1 : EndIf
  If MamuteColorBorder < 0 Or MamuteColorBorder > 15 : MamuteColorBorder = 1 : EndIf

  Protected CellsElem = GetJSONMember(Root, "Cells")
  If CellsElem
    Protected N = JSONArraySize(CellsElem)
    Protected Idx, Item, S, P
    For Idx = 0 To N - 1
      Item = GetJSONElement(CellsElem, Idx)
      If Item
        S = -1 : P = -1
        M = GetJSONMember(Item, "Slot")  : If M : S = GetJSONInteger(M) : EndIf
        M = GetJSONMember(Item, "Pagina") : If M : P = GetJSONInteger(M) : EndIf
        If S >= 0 And S <= 3 And P >= 0 And P <= 3
          M = GetJSONMember(Item, "Tipo") : If M : MamuteCfgCell(S, P)\Tipo = GetJSONInteger(M) : EndIf
          M = GetJSONMember(Item, "Arquivo") : If M : MamuteCfgCell(S, P)\FilePath = GetJSONString(M) : EndIf
          M = GetJSONMember(Item, "Offset") : If M : MamuteCfgCell(S, P)\FileOffset = GetJSONInteger(M) : EndIf
        EndIf
      EndIf
    Next
  EndIf

  ; Teclado do comando S - array plano de 16 strings de 1 caractere,
  ; indexado pelo VALOR do nibble (0-15), nao pela ordem de exibicao.
  Protected SKeysElem = GetJSONMember(Root, "SKeys")
  If SKeysElem And JSONArraySize(SKeysElem) = 16
    Protected KIdx
    For KIdx = 0 To 15
      Protected KItem = GetJSONElement(SKeysElem, KIdx)
      If KItem : MamuteSKeyMap(KIdx) = GetJSONString(KItem) : EndIf
    Next
  EndIf
  FreeJSON(Json)
EndProcedure

Procedure MamuteCfg_Save()
  Protected Json = CreateJSON(#PB_Any)
  Protected Root = SetJSONObject(JSONValue(Json))
  SetJSONString(AddJSONMember(Root, "FontName"), MamuteFontName)
  SetJSONInteger(AddJSONMember(Root, "FontSize"), MamuteFontSize)
  SetJSONBoolean(AddJSONMember(Root, "FontBold"), MamuteFontBold)
  SetJSONInteger(AddJSONMember(Root, "VramSize"), MamuteVramSize)
  SetJSONBoolean(AddJSONMember(Root, "AutoRunAfterTransfer"), MamuteAutoRunAfterTransfer)
  SetJSONString(AddJSONMember(Root, "DefaultNotesFile"), MamuteDefaultNotesFile)
  SetJSONInteger(AddJSONMember(Root, "ColorFg"), MamuteColorFg)
  SetJSONInteger(AddJSONMember(Root, "ColorBg"), MamuteColorBg)
  SetJSONInteger(AddJSONMember(Root, "ColorBorder"), MamuteColorBorder)
  Protected CellsElem = SetJSONArray(AddJSONMember(Root, "Cells"))

  Protected Slot, Pagina, Elem
  For Slot = 0 To 3
    For Pagina = 0 To 3
      Elem = AddJSONElement(CellsElem)
      SetJSONObject(Elem)
      SetJSONInteger(AddJSONMember(Elem, "Slot"), Slot)
      SetJSONInteger(AddJSONMember(Elem, "Pagina"), Pagina)
      SetJSONInteger(AddJSONMember(Elem, "Tipo"), MamuteCfgCell(Slot, Pagina)\Tipo)
      SetJSONString(AddJSONMember(Elem, "Arquivo"), MamuteCfgCell(Slot, Pagina)\FilePath)
      SetJSONInteger(AddJSONMember(Elem, "Offset"), MamuteCfgCell(Slot, Pagina)\FileOffset)
    Next
  Next

  Protected SKeysElem = SetJSONArray(AddJSONMember(Root, "SKeys"))
  Protected KIdx2
  For KIdx2 = 0 To 15
    SetJSONString(AddJSONElement(SKeysElem), MamuteSKeyMap(KIdx2))
  Next

  SaveJSON(Json, MamuteCfg_FilePath(), #PB_JSON_PrettyPrint)
  FreeJSON(Json)
EndProcedure

;- ------------------------------------------------------------
;- Tela "Configurar -> Mamute Assembler..."
;- ------------------------------------------------------------

; Atualiza o texto exibido na linha ItemIdx da lista a partir de
; WorkCells(Slot,Pagina) - usado tanto ao popular a lista inteira quanto ao
; refletir uma edicao pontual (Tipo/Arquivo do celula selecionada).
Procedure MamuteSettings_RefreshRow(List, ItemIdx.i, Slot.i, Pagina.i, Array WorkCells.MamuteMemCell(2))
  SetGadgetItemText(List, ItemIdx, Str(Slot), 0)
  SetGadgetItemText(List, ItemIdx, Str(Pagina), 1)
  SetGadgetItemText(List, ItemIdx, Mamute_PageRangeText(Pagina), 2)
  SetGadgetItemText(List, ItemIdx, Mamute_TipoText(WorkCells(Slot, Pagina)\Tipo), 3)
  Protected ArquivoText.s = WorkCells(Slot, Pagina)\FilePath
  If ArquivoText <> "" And WorkCells(Slot, Pagina)\FileOffset > 0
    ArquivoText + " (ultimos 16KB)"
  EndIf
  SetGadgetItemText(List, ItemIdx, ArquivoText, 4)
EndProcedure

Procedure.b MamuteSettings_TipoUsesFile(Tipo.b)
  ProcedureReturn Bool(Tipo = #MamuteMem_ROM Or Tipo = #MamuteMem_Basic)
EndProcedure

Procedure MamuteSettings_OpenWindow(ParentWindow)
  MamuteCfg_Load()

  ; Copia de trabalho - Salvar/Cancelar decide se isso vira o MamuteCfgCell()
  ; global de verdade, mesmo espirito das outras telas de Configurar desta
  ; IDE (nunca aplica edicao direto no global antes de "Salvar").
  Protected Dim WorkCells.MamuteMemCell(3, 3)
  Protected Slot, Pagina
  For Slot = 0 To 3
    For Pagina = 0 To 3
      WorkCells(Slot, Pagina) = MamuteCfgCell(Slot, Pagina)
    Next
  Next

  Protected WinW = 820, WinH = 870
  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Configurar - Mamute Assembler",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  TextGadget(#PB_Any, 24, 24, WinW - 48, 40,
            "Configuracao fisica dos 16 blocos de memoria (4 slots x 4 paginas de 16KB) simulados pelo" + Chr(10) +
            "Mamute Assembler. Selecione uma linha pra ajustar o tipo/arquivo abaixo.")

  Protected G_List = ListIconGadget(#PB_Any, 24, 76, WinW - 48, 300, "Slot", 60, #PB_ListIcon_FullRowSelect)
  AddGadgetColumn(G_List, 1, "Pagina", 70)
  AddGadgetColumn(G_List, 2, "Endereco", 110)
  AddGadgetColumn(G_List, 3, "Tipo", 90)
  AddGadgetColumn(G_List, 4, "Arquivo", WinW - 48 - 60 - 70 - 110 - 90)

  For Slot = 0 To 3
    For Pagina = 0 To 3
      AddGadgetItem(G_List, -1, "" + Chr(10) + "" + Chr(10) + "" + Chr(10) + "" + Chr(10) + "")
      MamuteSettings_RefreshRow(G_List, Slot * 4 + Pagina, Slot, Pagina, WorkCells())
    Next
  Next

  Protected EditY = 76 + 300 + 24
  TextGadget(#PB_Any, 24, EditY + 4, 50, 20, "Tipo:")
  Protected G_Tipo = ComboBoxGadget(#PB_Any, 80, EditY, 160, 24)
  AddGadgetItem(G_Tipo, #MamuteMem_Empty, "Vazio")
  AddGadgetItem(G_Tipo, #MamuteMem_RAM, "RAM")
  AddGadgetItem(G_Tipo, #MamuteMem_ROM, "ROM")
  AddGadgetItem(G_Tipo, #MamuteMem_Basic, "BASIC")
  DisableGadget(G_Tipo, #True)

  TextGadget(#PB_Any, 260, EditY + 4, 60, 20, "Arquivo:")
  Protected G_File = StringGadget(#PB_Any, 324, EditY, WinW - 324 - 24 - 64 - 8, 24, "")
  Protected G_FileBrowse = ThemedButton(WinW - 24 - 64, EditY, 64, 24, "...", "")
  DisableGadget(G_File, #True)
  DisableGadget(G_FileBrowse, #True)

  ; Fonte do terminal (MamuteAssemblerGui.pbi) - monoespacada de proposito,
  ; mesma enumeracao ja usada pela fonte do editor de codigo
  ; (EditorCfg_EnumMonospaceFonts(), EditorSettings.pbi).
  Protected FontY = EditY + 48
  TextGadget(#PB_Any, 24, FontY + 4, 140, 20, "Fonte do terminal:")
  Protected G_TermFont = ComboBoxGadget(#PB_Any, 170, FontY, 220, 24)

  Protected NewList TermFonts.s()
  EditorCfg_EnumMonospaceFonts(TermFonts())
  Protected TermFontIndex = -1, TermFontIdx = 0
  ForEach TermFonts()
    AddGadgetItem(G_TermFont, -1, TermFonts())
    If TermFonts() = MamuteFontName
      TermFontIndex = TermFontIdx
    EndIf
    TermFontIdx + 1
  Next
  If TermFontIndex < 0
    AddGadgetItem(G_TermFont, -1, MamuteFontName)
    TermFontIndex = CountGadgetItems(G_TermFont) - 1
  EndIf
  SetGadgetState(G_TermFont, TermFontIndex)

  TextGadget(#PB_Any, 400, FontY + 4, 40, 20, "Tam.")
  Protected G_TermFontSize = StringGadget(#PB_Any, 444, FontY, 50, 24, Str(MamuteFontSize))

  Protected G_TermFontBold = CheckBoxGadget(#PB_Any, 510, FontY + 3, 140, 22, "Negrito")
  SetGadgetState(G_TermFontBold, MamuteFontBold)

  ; Teclado do comando S (MamuteMGui.pbi) - pedido explicito do usuario:
  ; "escolher quais teclas do teclado ele vai usar como
  ; 1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,0". Grade 4x4 na MESMA ordem de exibicao
  ; pedida (nao a ordem de armazenamento por valor, ver MamuteSKeyMap() em
  ; MamuteSupport.pbi) - com o padrao 1,2,3,4/Q,W,E,R/A,S,D,F/Z,X,C,V isso
  ; visualmente cai exatamente sobre essas 4 fileiras do teclado QWERTY.
  Protected KeysY = FontY + 48
  TextGadget(#PB_Any, 24, KeysY, WinW - 48, 20,
            "Teclado do comando S - qual tecla digitar pra cada digito hexa (0-9, A-F):")
  KeysY + 26

  ; DisplayOrder(i) = o VALOR do nibble mostrado na posicao i da grade
  ; (0..15, varrendo esquerda->direita, cima->baixo) - "1,2,3,4,5,6,7,8,9,A,
  ; B,C,D,E,F,0" pedido explicito do usuario, valor 0 por ultimo de proposito.
  Protected Dim DisplayOrder.i(15)
  DisplayOrder(0)=1 : DisplayOrder(1)=2 : DisplayOrder(2)=3 : DisplayOrder(3)=4
  DisplayOrder(4)=5 : DisplayOrder(5)=6 : DisplayOrder(6)=7 : DisplayOrder(7)=8
  DisplayOrder(8)=9 : DisplayOrder(9)=10 : DisplayOrder(10)=11 : DisplayOrder(11)=12
  DisplayOrder(12)=13 : DisplayOrder(13)=14 : DisplayOrder(14)=15 : DisplayOrder(15)=0

  Protected Dim G_SKey(15)
  Protected KeyCol.i, KeyRow.i, KeyCellW.i = (WinW - 48) / 4, KeyIdx.i, KeyValue.i, KeyX.i, KeyRowY.i
  For KeyRow = 0 To 3
    KeyRowY = KeysY + KeyRow * 34
    For KeyCol = 0 To 3
      KeyIdx = KeyRow * 4 + KeyCol
      KeyValue = DisplayOrder(KeyIdx)
      KeyX = 24 + KeyCol * KeyCellW
      TextGadget(#PB_Any, KeyX, KeyRowY + 3, 30, 20, Mid("0123456789ABCDEF", KeyValue + 1, 1) + ":")
      G_SKey(KeyIdx) = StringGadget(#PB_Any, KeyX + 34, KeyRowY, 50, 24, MamuteSKeyMap(KeyValue))
    Next
  Next
  KeysY + 4 * 34 + 8

  ; VRAM simulada (comandos V, futuros VLOAD/VSAVE) - pedido explicito do
  ; usuario: "permita incluir tambem configuracao de VRAM... escolha entre
  ; 16, 128 ou 192 Kb". Enderecamento plano (sem bancos - ver comentario de
  ; MamuteVRAM() em MamuteSupport.pbi), entao a unica escolha real aqui e o
  ; tamanho/limite superior.
  TextGadget(#PB_Any, 24, KeysY + 4, 140, 20, "Tamanho da VRAM:")
  Protected G_VramSize = ComboBoxGadget(#PB_Any, 170, KeysY, 160, 24)
  AddGadgetItem(G_VramSize, 0, "16 KB (MSX1)")
  AddGadgetItem(G_VramSize, 1, "128 KB")
  AddGadgetItem(G_VramSize, 2, "192 KB")
  Select MamuteVramSize
    Case 131072 : SetGadgetState(G_VramSize, 1)
    Case 196608 : SetGadgetState(G_VramSize, 2)
    Default     : SetGadgetState(G_VramSize, 0)
  EndSelect
  KeysY + 34

  ; Comandos FOSSAURO/OPENMSX (MamuteAssemblerGui.pbi/FossauroSupport.pbi/OpenMSXBridge.pbi) -
  ; ver comentario do Global MamuteAutoRunAfterTransfer acima. Mesma flag pros dois alvos
  ; (e' a mesma decisao "executar ou nao" pro usuario). Desligado por padrao.
  Protected G_AutoRunAfterTransfer = CheckBoxGadget(#PB_Any, 24, KeysY + 3, WinW - 48, 22,
                                               "Executar automaticamente apos transferir - Fossauro/openMSX (A=USR0(0))")
  SetGadgetState(G_AutoRunAfterTransfer, MamuteAutoRunAfterTransfer)
  KeysY + 34

  ; Notas do SUPER-X por endereco (comandos XIM/XIC/XIL/XIS, docs/SPEC.md
  ; modulo 45x) - pedido explicito do usuario: "abra um campo para
  ; escolher um arquivo de nota padrao para ser carregado sempre que o
  ; Mamute iniciar" (modulo 45y). Mesmo layout Label+StringGadget+Botao
  ; "..." do campo "Arquivo:" da lista de memoria, la em cima. Vazio
  ; (padrao) = nao carrega nada automaticamente.
  TextGadget(#PB_Any, 24, KeysY + 4, 160, 20, "Notas SUPER-X padrao:")
  Protected G_NotesFile = StringGadget(#PB_Any, 190, KeysY, WinW - 190 - 24 - 64 - 8, 24, MamuteDefaultNotesFile)
  Protected G_NotesFileBrowse = ThemedButton(WinW - 24 - 64, KeysY, 64, 24, "...", "")
  KeysY + 34

  Protected G_Save = ThemedButton(WinW - 256, WinH - 56, 110, 32, "Salvar", Chr(#Icon_Save))
  GadgetToolTip(G_Save, "Salvar")
  Protected G_Cancel = ThemedButton(WinW - 134, WinH - 56, 110, 32, "Cancelar", "")

  Protected SelectedSlot.i = -1, SelectedPagina.i = -1

  Protected Event, Quit = #False, Saved = #False
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_List
            If EventType() = #PB_EventType_Change
              Protected Sel = GetGadgetState(G_List)
              If Sel >= 0
                SelectedSlot = Sel / 4
                SelectedPagina = Sel % 4
                DisableGadget(G_Tipo, #False)
                SetGadgetState(G_Tipo, WorkCells(SelectedSlot, SelectedPagina)\Tipo)
                SetGadgetText(G_File, WorkCells(SelectedSlot, SelectedPagina)\FilePath)
                Protected UsesFile.b = MamuteSettings_TipoUsesFile(WorkCells(SelectedSlot, SelectedPagina)\Tipo)
                DisableGadget(G_File, Bool(Not UsesFile))
                DisableGadget(G_FileBrowse, Bool(Not UsesFile))
              EndIf
            EndIf

          Case G_Tipo
            If SelectedSlot >= 0
              Protected NewTipo.b = GetGadgetState(G_Tipo)
              WorkCells(SelectedSlot, SelectedPagina)\Tipo = NewTipo
              Protected UsesFile2.b = MamuteSettings_TipoUsesFile(NewTipo)
              DisableGadget(G_File, Bool(Not UsesFile2))
              DisableGadget(G_FileBrowse, Bool(Not UsesFile2))
              If Not UsesFile2
                WorkCells(SelectedSlot, SelectedPagina)\FilePath = ""
                SetGadgetText(G_File, "")
              EndIf
              MamuteSettings_RefreshRow(G_List, SelectedSlot * 4 + SelectedPagina, SelectedSlot, SelectedPagina, WorkCells())
              SetGadgetState(G_List, SelectedSlot * 4 + SelectedPagina)
            EndIf

          Case G_File
            If SelectedSlot >= 0 And EventType() = #PB_EventType_Change
              WorkCells(SelectedSlot, SelectedPagina)\FilePath = GetGadgetText(G_File)
              WorkCells(SelectedSlot, SelectedPagina)\FileOffset = 0 ; digitado a mao - abandona o offset de uma divisao BIOS+BASIC anterior
              MamuteSettings_RefreshRow(G_List, SelectedSlot * 4 + SelectedPagina, SelectedSlot, SelectedPagina, WorkCells())
              SetGadgetState(G_List, SelectedSlot * 4 + SelectedPagina)
            EndIf

          Case G_FileBrowse
            If SelectedSlot >= 0
              Protected PickPath.s = OpenFileRequester("Selecione o arquivo (ROM/BASIC)", GetGadgetText(G_File),
                                                       "Todos os arquivos (*.*)|*.*", 0)
              If PickPath <> ""
                ; Arquivo de 32KB escolhido pra uma celula ROM na Pagina 0 (BIOS) -
                ; muito comum a BIOS e o BASIC virem combinados num unico arquivo
                ; assim num MSX real. Pergunta antes de assumir - "Nao" trata como
                ; um arquivo qualquer (usa so os primeiros 16KB aqui, nao mexe na
                ; Pagina 1). O usuario continua livre pra trocar o arquivo da
                ; Pagina 1 manualmente depois, mesmo apos o "Sim" auto-preencher.
                Protected HandledAsCombined.b = #False
                If SelectedPagina = 0 And WorkCells(SelectedSlot, 0)\Tipo = #MamuteMem_ROM And FileSize(PickPath) = #Mamute_CombinedBiosBasicSize
                  Protected CombinedAnswer = MessageRequester("BIOS + BASIC combinados?",
                    "Este arquivo tem 32KB - e comum a BIOS e o BASIC virem combinados num unico" + Chr(10) +
                    "arquivo assim num MSX real." + Chr(10) + Chr(10) +
                    "Usar os primeiros 16KB aqui (BIOS, Pagina 0) e os ultimos 16KB na Pagina 1" + Chr(10) +
                    "(BASIC) deste mesmo slot?",
                    #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
                  If CombinedAnswer = #PB_MessageRequester_Yes
                    WorkCells(SelectedSlot, 0)\FilePath = PickPath
                    WorkCells(SelectedSlot, 0)\FileOffset = 0
                    WorkCells(SelectedSlot, 1)\Tipo = #MamuteMem_Basic
                    WorkCells(SelectedSlot, 1)\FilePath = PickPath
                    WorkCells(SelectedSlot, 1)\FileOffset = #Mamute_PageSize
                    MamuteSettings_RefreshRow(G_List, SelectedSlot * 4 + 0, SelectedSlot, 0, WorkCells())
                    MamuteSettings_RefreshRow(G_List, SelectedSlot * 4 + 1, SelectedSlot, 1, WorkCells())
                    HandledAsCombined = #True
                  EndIf
                EndIf

                If Not HandledAsCombined
                  WorkCells(SelectedSlot, SelectedPagina)\FilePath = PickPath
                  WorkCells(SelectedSlot, SelectedPagina)\FileOffset = 0
                  MamuteSettings_RefreshRow(G_List, SelectedSlot * 4 + SelectedPagina, SelectedSlot, SelectedPagina, WorkCells())
                EndIf

                SetGadgetText(G_File, PickPath)
                SetGadgetState(G_List, SelectedSlot * 4 + SelectedPagina)
              EndIf
            EndIf

          Case G_NotesFileBrowse
            Protected NotesPick.s = OpenFileRequester("Selecione o arquivo de notas padrao",
              GetGadgetText(G_NotesFile), "Notas traduzidas (*.notas)|*.notas|Todos os arquivos (*.*)|*.*", 0)
            If NotesPick <> ""
              SetGadgetText(G_NotesFile, Mamute_ProtectTranslatedNotesIfPicked(NotesPick))
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
    For Slot = 0 To 3
      For Pagina = 0 To 3
        MamuteCfgCell(Slot, Pagina) = WorkCells(Slot, Pagina)
      Next
    Next
    MamuteFontName = GetGadgetText(G_TermFont)
    Protected TypedSize.i = Val(GetGadgetText(G_TermFontSize))
    If TypedSize < 6 : TypedSize = 6 : EndIf
    If TypedSize > 72 : TypedSize = 72 : EndIf
    MamuteFontSize = TypedSize
    MamuteFontBold = GetGadgetState(G_TermFontBold)

    Protected KIdxSave.i, TypedKey.s
    For KIdxSave = 0 To 15
      TypedKey = Trim(GetGadgetText(G_SKey(KIdxSave)))
      If TypedKey <> ""
        MamuteSKeyMap(DisplayOrder(KIdxSave)) = UCase(Left(TypedKey, 1))
      EndIf
    Next

    Select GetGadgetState(G_VramSize)
      Case 1 : MamuteVramSize = 131072
      Case 2 : MamuteVramSize = 196608
      Default : MamuteVramSize = 16384
    EndSelect

    MamuteAutoRunAfterTransfer = GetGadgetState(G_AutoRunAfterTransfer)

    ; Protege tambem se o caminho foi DIGITADO a mao (nao so' escolhido via
    ; "..." acima, ja tratado no Case G_NotesFileBrowse) - mesma checagem,
    ; Mamute_ProtectTranslatedNotesIfPicked() so' age se bater exatamente
    ; com o arquivo traduzido original.
    Protected TypedNotesPath.s = Trim(GetGadgetText(G_NotesFile))
    If TypedNotesPath <> ""
      TypedNotesPath = Mamute_ProtectTranslatedNotesIfPicked(TypedNotesPath)
    EndIf
    MamuteDefaultNotesFile = TypedNotesPath

    MamuteCfg_Save()
  EndIf

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure

; ------------------------------------------------------------
; Editor de linhas do Assembly do Mamute (comando EDIT, MamuteEditGui.pbi) -
; formato do manual original (megasm/exe/MEGASM.TXT, secao "Programas em
; Assembly"): "NN Label: instrucao operando ;comentario", NN obrigatorio,
; Label/comentario opcionais. Mudanca pedida explicitamente pelo usuario em
; relacao ao manual original: numeros SEM sufixo agora sao HEXADECIMAL por
; padrao (o manual original usava decimal como padrao), "para ficar
; uniforme" com o resto do Mamute (enderecos hexa ja sao o padrao de
; entrada em todo comando do MON>, DM em diante). Sufixos continuam os tres
; do manual - H (hexa, redundante com o padrao agora, mantido por
; compatibilidade), B (binario), D (decimal, o unico jeito de escrever
; decimal agora que deixou de ser o padrao). A regra do manual original "se
; comecar por letra, precisa de zero na frente" agora vale tambem SEM
; sufixo, ja que hexa e' o padrao - e o que garante que um token comecando
; em LETRA e' sempre label/identificador, nunca numero (so um token que
; comeca com digito 0-9 chega a ser tratado como numero em qualquer lugar
; deste bloco).
; ------------------------------------------------------------

Structure MamuteEditLine
  LineNum.i
  RawText.s   ; corpo completo digitado (sem o NN) - guardado a parte pra um futuro LIST
  LabelText.s ; sem o ":" final; "" se nao tiver
  Instr.s     ; mnemonico/pseudo-instrucao, sempre maiusculo
  Operand.s   ; texto cru do operando (antes do ";")
  Comment.s   ; texto depois do ";", sem o ";"; "" se nao tiver
EndStructure

; Programa-fonte em memoria - Global (nao dentro do estado de uma janela)
; porque sobrevive a varias aberturas/fechamentos da janela EDIT dentro da
; mesma sessao do editor, mesmo espirito de MamuteGui_History()
; (MamuteAssemblerGui.pbi) - "o programa fica na memoria do EMA" (manual
; original) ate um NEW (comando de gerenciamento do fonte, ainda nao
; implementado - fora do escopo desta sessao, que e' so aceitar/guardar
; linhas).
Global NewList MamuteEditProgram.MamuteEditLine()

; Resultados do ultimo SEARCH/LSEARCH bem-sucedido - indices (0-based) em
; MamuteEditProgram() das linhas que bateram, em ordem crescente. Global
; (mesmo espirito de MamuteEditProgram() acima, nao embutido no estado da
; janela - evita depender de passar List embutido numa Structure por
; parametro, caso incerto o suficiente pra nao arriscar) - consumido pelo
; modo "filtro" do EDIT (MamuteEditState\FilterMode, MamuteEditGui.pbi) pra
; mostrar so essas linhas na tela.
Global NewList MamuteSearchMatches.i()

; Resultado da ULTIMA montagem BEM-SUCEDIDA (A ou A O - os dois calculam o
; mesmo intervalo de enderecos, ver comando MAP abaixo) - Global, mesmo
; espirito de MamuteEditProgram()/MamuteSearchMatches() acima, sobrevive a
; fechamentos/reaberturas da janela EDIT. Uma tentativa de montagem que
; FALHA (erro de sintaxe) NAO mexe nisso - "ultimo resultado bem-sucedido
; conhecido" fica intacto ate a PROXIMA montagem bem-sucedida (mesmo
; espirito de HasLastSh/LastShAddr no MON> - so' atualiza em sucesso,nunca
; some por causa de uma tentativa falha). NEW (Mamute_AsmNew() abaixo) e' a
; UNICA acao que zera isso de proposito, ja que apaga o programa que gerou
; o resultado.
Global MamuteAsmHasResult.b = #False
Global MamuteAsmLastStartAddr.u
Global MamuteAsmLastEndAddr.u
Global MamuteAsmLastByteCount.i

; #True somente quando a montagem que gerou LastStartAddr/LastEndAddr/
; LastByteCount tambem usou a flag "O" (gravou de verdade em MamuteMem via
; Mamute_WriteByte - ver o "If AsmHasO" em MamuteEditGui.pbi). Zerado no
; INICIO de toda tentativa de montagem (Mamute_AsmAssemble abaixo, antes de
; saber se "O" foi pedido desta vez) e setado #True so' pelo chamador, apos
; escrever os bytes com sucesso - existe pro comando FOSSAURO
; (MamuteGui_CmdFossauro(), MamuteAssemblerGui.pbi) conseguir recusar enviar
; um intervalo de enderecos que na verdade nunca foi escrito na RAM simulada
; (ex.: usuario rodou so' "A", sem "O", e tentou "FOSSAURO" na sequencia).
Global MamuteAsmLastWroteToRam.b = #False

; Listagem formatada (linhas de texto ja' prontas pra desenhar) da ULTIMA
; montagem bem-sucedida - pedido explicito do usuario, reproduzindo o
; formato classico do comando A do MegaAssembler original: "numero da
; linha, o endereco ou o valor do EQU, ate 4 codigos hexa (mais linhas se
; precisar), o conteudo da linha". Preenchida por
; Mamute_AsmBuildListingLines() logo abaixo, chamada de dentro de
; Mamute_AsmAssemble() em toda montagem bem-sucedida - mesmo espirito
; Global de MamuteSearchMatches() (evita passar List por parametro atraves
; de ponteiro pra Structure).
Global NewList MamuteAsmListingLines.s()

; Referencia cruzada de simbolos formatada (opcao R do comando A, pedido
; explicito do usuario com um print real do MegaAssembler original de
; exemplo - images/msxbasica-19.png): uma linha por simbolo (EQU/DEFL/ASET
; OU rotulo posicional - o print nao distingue os dois, o valor mostrado ja'
; e' correto pros dois casos, ver Z80Asm::Z80XrefRow), nome + valor/endereco
; de definicao + enderecos de uso (ate 4 por linha, linhas extras se
; precisar - mesmo idioma do MamuteAsmListingLines() acima). Preenchida por
; Mamute_AsmBuildXrefLines() logo abaixo, chamada INCONDICIONALMENTE de
; dentro de Mamute_AsmAssemble() em toda montagem bem-sucedida (barato de
; calcular mesmo quando "R" nao foi pedido) - o comando "A R"
; (MamuteEditGui.pbi) decide se anexa isso ao final de
; MamuteAsmListingLines() antes de mostrar na tela.
Global NewList MamuteAsmXrefLines.s()

; Listagem alfabetica simples de labels formatada (opcao S do comando A,
; pedido explicito do usuario: "gera ao final uma listagem dos labels em
; ordem alfabetica e o endereco onde foram definidos, digo o endereco para
; onde apontam") - mesmos dados de MamuteAsmXrefLines() acima (mesma tabela
; Z80Asm::XrefRows(), ja ordenada alfabeticamente), so' NOME + VALOR, SEM os
; enderecos de uso (Mamute_AsmBuildLabelListLines() abaixo ignora
; Row\AddrCount/Addr0..3, aproveita so' as linhas com Row\HasValue - pula as
; de continuacao, que em MamuteAsmXrefLines() so existem por causa dos
; enderecos de uso que aqui nao aparecem). Preenchida por Mamute_
; AsmBuildLabelListLines() logo abaixo, chamada INCONDICIONALMENTE de
; dentro de Mamute_AsmAssemble() em toda montagem bem-sucedida, mesmo
; espirito de MamuteAsmXrefLines() - "A S" (MamuteEditGui.pbi) decide se
; anexa isso ao final de MamuteAsmListingLines().
Global NewList MamuteAsmLabelListLines.s()

; Listagem de labels em ORDEM DE APARICAO (opcao D do comando A, pedido
; explicito do usuario: "e' identica a A S, porem a lista de labels e' por
; ordem de aparicao e nao alfabetica") - mesmo layout "NOME  VALOR" de
; MamuteAsmLabelListLines() acima, mas a fonte dos nomes e'
; Z80Asm::GetLabelDefOrderCount()/GetLabelDefOrderName() (ordem de
; DEFINICAO no fonte, ver comentario em DefineSymbolSeg(), Z80Asm.pbi) em
; vez de Z80Asm::XrefRows() (alfabetica) - valor de cada um continua vindo
; de Z80Asm::GetSymbolValue() (ja publico, sem precisar de API nova pra
; isso). Preenchida por Mamute_AsmBuildLabelOrderLines() logo abaixo,
; chamada INCONDICIONALMENTE de dentro de Mamute_AsmAssemble(), mesmo
; espirito de MamuteAsmLabelListLines() - "A D" (MamuteEditGui.pbi) decide
; se anexa isso ao final de MamuteAsmListingLines().
Global NewList MamuteAsmLabelOrderLines.s()

; Motor comum de SEARCH/LSEARCH (MEGASM.TXT linhas 738/750, pedido explicito
; do usuario com sintaxe adaptada): `'<string>'` entre aspas = busca
; LITERAL, case-sensitive, texto exato; sem aspas = busca LIVRE,
; case-insensitive ("strings, comandos, labels, etc" - qualquer palavra,
; sem diferenciar maiusculas/minusculas, do jeito que mnemonicos/labels ja
; sao tratados no resto do EDIT - Z80Asm::IsMnemonic()/
; Mamute_IsValidAsmLabel() ja normalizam por UCase). Busca no CORPO cru
; (RawText) de cada linha - label+instrucao+operando+comentario juntos,
; mesmo escopo do CHANGE. Preenche MamuteSearchMatches() (efeito colateral
; deliberado, ver nota acima). Retorna a quantidade de ocorrencias achadas;
; -1 = erro de sintaxe (termo de busca vazio).
Procedure.i Mamute_AsmSearch(Args.s)
  ClearList(MamuteSearchMatches())
  Protected Trimmed.s = Trim(Args)
  If Trimmed = ""
    ProcedureReturn -1
  EndIf

  Protected Needle.s
  Protected CaseSensitive.b
  If Left(Trimmed, 1) = "'"
    Protected ClosePos.i = FindString(Trimmed, "'", 2)
    If ClosePos > 0
      Needle = Mid(Trimmed, 2, ClosePos - 2)
    Else
      Needle = Mid(Trimmed, 2)
    EndIf
    CaseSensitive = #True
  Else
    Needle = Trimmed
    CaseSensitive = #False
  EndIf
  If Needle = ""
    ProcedureReturn -1
  EndIf

  Protected NeedleCmp.s = Needle
  If Not CaseSensitive
    NeedleCmp = UCase(Needle)
  EndIf

  Protected Idx.i = 0
  Protected Hay.s
  ForEach MamuteEditProgram()
    Hay = MamuteEditProgram()\RawText
    If Not CaseSensitive
      Hay = UCase(Hay)
    EndIf
    If FindString(Hay, NeedleCmp) > 0
      AddElement(MamuteSearchMatches())
      MamuteSearchMatches() = Idx
    EndIf
    Idx + 1
  Next

  ProcedureReturn ListSize(MamuteSearchMatches())
EndProcedure

; Numero no dialeto do EDIT do Mamute - ver comentario de topo desta secao.
; Token PRECISA comecar com digito 0-9 (quem chama ja filtrou por isso -
; nenhum token comecando em letra chega aqui). Sufixo opcional no ULTIMO
; caractere (H/B/D, maiusculo ou minusculo) decide a base explicitamente e
; SEMPRE vence sobre a leitura hexa padrao - unica forma de resolver a
; ambiguidade real entre "ultimo digito hexa B/D" e "sufixo B/D" (H nunca e'
; digito hexa valido, mas B e D sao) - decisao de interpretacao do Claude,
; o usuario nao detalhou este caso especifico. Pra escrever um hexa que
; termine em B/D sem ambiguidade, use o sufixo H explicito (ex.: "1BH").
Procedure.b Mamute_ParseAsmNumber(Token.s, *OutValue.Integer)
  If Token = ""
    ProcedureReturn #False
  EndIf
  If Mid(Token, 1, 1) < "0" Or Mid(Token, 1, 1) > "9"
    ProcedureReturn #False
  EndIf

  Protected LastCh.s = UCase(Right(Token, 1))
  Protected Digits.s, Base.i
  Select LastCh
    Case "H"
      Digits = Left(Token, Len(Token) - 1) : Base = 16
    Case "B"
      Digits = Left(Token, Len(Token) - 1) : Base = 2
    Case "D"
      Digits = Left(Token, Len(Token) - 1) : Base = 10
    Default
      Digits = Token : Base = 16
  EndSelect
  If Digits = ""
    ProcedureReturn #False
  EndIf

  Protected HexDigits.s = "0123456789ABCDEF"
  Protected i.i, Ch.s, DigVal.i, Value.i = 0
  For i = 1 To Len(Digits)
    Ch = UCase(Mid(Digits, i, 1))
    DigVal = FindString(HexDigits, Ch, 1) - 1
    If DigVal < 0 Or DigVal >= Base
      ProcedureReturn #False
    EndIf
    Value = Value * Base + DigVal
  Next

  *OutValue\i = Value
  ProcedureReturn #True
EndProcedure

; Identificador de label - primeiro caractere letra ou "_", resto
; letras/digitos/"_" - regra generica de qualquer assembler (o manual
; original nao detalha a gramatica exata de nomes de label).
Procedure.b Mamute_IsValidAsmLabel(Text.s)
  If Text = ""
    ProcedureReturn #False
  EndIf
  Protected First.s = UCase(Mid(Text, 1, 1))
  If (First < "A" Or First > "Z") And First <> "_"
    ProcedureReturn #False
  EndIf
  Protected i.i, Ch.s
  For i = 2 To Len(Text)
    Ch = UCase(Mid(Text, i, 1))
    If (Ch < "A" Or Ch > "Z") And (Ch < "0" Or Ch > "9") And Ch <> "_"
      ProcedureReturn #False
    EndIf
  Next
  ProcedureReturn #True
EndProcedure

; Pseudo-instrucoes do editor Assembly do Mamute - as 6 do manual original
; pedidas explicitamente pelo usuario (ORG/DEFB/DEFW/DEFM/DEFS/EQU) MAIS
; END (nao estava na lista do usuario, mas e' a ultima linha do PROPRIO
; exemplo do manual original - "120 END", megasm/exe/MEGASM.TXT linha 1113
; - sem ela nem o exemplo oficial do manual seria aceito; adicionada por
; interpretacao do Claude). Deliberadamente NAO o vocabulario inteiro de
; diretivas do Nestor80 (Z80Asm::IsDirective() tem muito mais - MACRO/IF/
; PUBLIC/etc. - fora de escopo aqui).
Procedure.b Mamute_IsAsmPseudoOp(Word.s)
  Select UCase(Word)
    Case "ORG", "DEFB", "DEFW", "DEFM", "DEFS", "EQU", "END"
      ProcedureReturn #True
    Default
      ProcedureReturn #False
  EndSelect
EndProcedure

; Varre Operand procurando tokens alfanumericos (fora de trechos entre
; apostrofos - texto/char literal de DEFB/DEFM/etc, nunca numero) - todo
; token que comeca com digito 0-9 precisa passar por
; Mamute_ParseAsmNumber(); tokens comecando em letra (label/registrador) nao
; sao validados aqui (sem tabela de simbolos nesta fase - "por hora vamos
; apenas aceitar o programa", pedido explicito do usuario - validacao
; semantica/enderecamento fica pro futuro comando de montagem, igual o
; manual original so detecta esse tipo de erro durante o "A" - ver a tabela
; de erros D/F/M/U/Q/O do comando A, MEGASM.TXT).
Procedure.b Mamute_ValidateAsmOperandNumbers(Operand.s)
  Protected InQuote.b = #False
  Protected L.i = Len(Operand)
  Protected i.i, Ch.s, Token.s = ""
  Protected DummyVal.i

  For i = 1 To L + 1
    If i <= L
      Ch = Mid(Operand, i, 1)
    Else
      Ch = " " ; sentinela pra fechar o ultimo token pendente
    EndIf

    If InQuote
      If Ch = "'"
        InQuote = #False
      EndIf
      Continue
    EndIf

    If Ch = "'"
      InQuote = #True
      If Token <> ""
        If Mid(Token, 1, 1) >= "0" And Mid(Token, 1, 1) <= "9"
          If Not Mamute_ParseAsmNumber(Token, @DummyVal)
            ProcedureReturn #False
          EndIf
        EndIf
        Token = ""
      EndIf
      Continue
    EndIf

    If (Ch >= "0" And Ch <= "9") Or (Ch >= "A" And Ch <= "Z") Or (Ch >= "a" And Ch <= "z")
      Token + Ch
    Else
      If Token <> ""
        If Mid(Token, 1, 1) >= "0" And Mid(Token, 1, 1) <= "9"
          If Not Mamute_ParseAsmNumber(Token, @DummyVal)
            ProcedureReturn #False
          EndIf
        EndIf
        Token = ""
      EndIf
    EndIf
  Next

  ProcedureReturn #True
EndProcedure

; Parser de UMA linha completa "NN Label: instrucao operando ;comentario"
; (grafia do manual original, secao "Programas em Assembly") pro formato
; interno (MamuteEditLine). So validacao SINTATICA (numero de linha,
; rotulo, instrucao reconhecida, formato dos numeros no operando) - nao
; valida modo de enderecamento nem resolve labels, isso fica pro futuro
; comando de montagem ("por hora vamos apenas aceitar o programa, depois
; trataremos a compilacao", pedido explicito do usuario). Retorna #False
; (linha rejeitada, *Out inalterado) em qualquer desvio da gramatica.
Procedure.b Mamute_ParseAsmLine(RawText.s, *Out.MamuteEditLine)
  Protected Text.s = RawText ; sem Trim aqui - o NN precisa comecar na coluna 1

  ; NN - 1+ digitos obrigatorios logo no inicio, seguidos de espaco.
  Protected i.i = 1
  Protected L.i = Len(Text)
  While i <= L And Mid(Text, i, 1) >= "0" And Mid(Text, i, 1) <= "9"
    i + 1
  Wend
  If i = 1
    ProcedureReturn #False ; sem nenhum digito - NN e' obrigatorio
  EndIf
  Protected LineNumToken.s = Left(Text, i - 1)
  If Len(LineNumToken) > 5 ; mesmo teto pratico do numero de linha do BASIC/MSX (0-65529)
    ProcedureReturn #False
  EndIf
  Protected LineNum.i = Val(LineNumToken)
  If LineNum > 65529
    ProcedureReturn #False
  EndIf
  If i > L Or Mid(Text, i, 1) <> " "
    ProcedureReturn #False ; precisa de espaco separando NN do resto
  EndIf
  Protected Body.s = Trim(Mid(Text, i + 1))
  If Body = ""
    ProcedureReturn #False ; corpo vazio - "apagar digitando so o numero" fica pro futuro comando DELETE
  EndIf

  ; Separa comentario (";" fora de apostrofos) do resto da linha.
  Protected InQuote.b = #False
  Protected CommentPos.i = 0
  Protected BL.i = Len(Body)
  Protected ScanCh.s
  For i = 1 To BL
    ScanCh = Mid(Body, i, 1)
    If ScanCh = "'"
      InQuote = Bool(Not InQuote)
    ElseIf ScanCh = ";" And Not InQuote
      CommentPos = i
      Break
    EndIf
  Next
  Protected Comment.s = ""
  Protected MainPart.s = Body
  If CommentPos > 0
    Comment = Trim(Mid(Body, CommentPos + 1))
    MainPart = Trim(Left(Body, CommentPos - 1))
  EndIf
  If MainPart = ""
    ProcedureReturn #False ; so tinha comentario - falta a instrucao
  EndIf

  ; Label opcional - primeiro token termina em ":" (sem espaco antes dele).
  Protected SpacePos.i = FindString(MainPart, " ")
  Protected FirstTok.s, RestAfterFirst.s
  If SpacePos > 0
    FirstTok = Left(MainPart, SpacePos - 1)
    RestAfterFirst = LTrim(Mid(MainPart, SpacePos + 1))
  Else
    FirstTok = MainPart
    RestAfterFirst = ""
  EndIf

  Protected LabelText.s = ""
  Protected InstrSection.s
  If Right(FirstTok, 1) = ":"
    LabelText = Left(FirstTok, Len(FirstTok) - 1)
    If Not Mamute_IsValidAsmLabel(LabelText)
      ProcedureReturn #False
    EndIf
    InstrSection = RestAfterFirst
  Else
    InstrSection = MainPart
  EndIf

  If InstrSection = ""
    ProcedureReturn #False ; tinha so o label, sem instrucao
  EndIf

  Protected SpacePos2.i = FindString(InstrSection, " ")
  Protected InstrTok.s, Operand.s
  If SpacePos2 > 0
    InstrTok = Left(InstrSection, SpacePos2 - 1)
    Operand = Trim(Mid(InstrSection, SpacePos2 + 1))
  Else
    InstrTok = InstrSection
    Operand = ""
  EndIf

  Protected Instr.s = UCase(InstrTok)
  If Not Z80Asm::IsMnemonic(Instr) And Not Mamute_IsAsmPseudoOp(Instr)
    ProcedureReturn #False ; instrucao/pseudo-instrucao desconhecida
  EndIf
  If Instr = "EQU" And LabelText = ""
    ProcedureReturn #False ; "Label: EQU endereco" - label e' obrigatorio pro EQU
  EndIf
  ; As 6 pseudo-instrucoes do manual (nao o END, que nao leva operando) tem
  ; sintaxe fixa de 1 operando sempre obrigatorio.
  If Operand = "" And (Instr = "ORG" Or Instr = "DEFB" Or Instr = "DEFW" Or Instr = "DEFM" Or Instr = "DEFS" Or Instr = "EQU")
    ProcedureReturn #False
  EndIf

  If Instr = "DEFM"
    If Left(Operand, 1) <> "'"
      ProcedureReturn #False ; "DEFM 'texto'" - precisa comecar com apostrofo
    EndIf
  Else
    If Not Mamute_ValidateAsmOperandNumbers(Operand)
      ProcedureReturn #False
    EndIf
  EndIf

  *Out\LineNum = LineNum
  *Out\RawText = Body
  *Out\LabelText = LabelText
  *Out\Instr = Instr
  *Out\Operand = Operand
  *Out\Comment = Comment
  ProcedureReturn #True
EndProcedure

; Guarda/substitui uma linha no programa em memoria (MamuteEditProgram()),
; mantendo a lista sempre ordenada por LineNum - mesmo comportamento
; "digitar de novo o mesmo numero substitui a linha" do BASIC/MegaAssembler
; original ("as linhas podem ser editadas como se fossem em BASIC").
Procedure Mamute_StoreAsmLine(*Line.MamuteEditLine)
  ForEach MamuteEditProgram()
    If MamuteEditProgram()\LineNum = *Line\LineNum
      MamuteEditProgram()\RawText = *Line\RawText
      MamuteEditProgram()\LabelText = *Line\LabelText
      MamuteEditProgram()\Instr = *Line\Instr
      MamuteEditProgram()\Operand = *Line\Operand
      MamuteEditProgram()\Comment = *Line\Comment
      ProcedureReturn
    ElseIf MamuteEditProgram()\LineNum > *Line\LineNum
      InsertElement(MamuteEditProgram())
      MamuteEditProgram()\LineNum = *Line\LineNum
      MamuteEditProgram()\RawText = *Line\RawText
      MamuteEditProgram()\LabelText = *Line\LabelText
      MamuteEditProgram()\Instr = *Line\Instr
      MamuteEditProgram()\Operand = *Line\Operand
      MamuteEditProgram()\Comment = *Line\Comment
      ProcedureReturn
    EndIf
  Next
  ; maior que todas as existentes (ou lista vazia) - acrescenta no fim
  AddElement(MamuteEditProgram())
  MamuteEditProgram()\LineNum = *Line\LineNum
  MamuteEditProgram()\RawText = *Line\RawText
  MamuteEditProgram()\LabelText = *Line\LabelText
  MamuteEditProgram()\Instr = *Line\Instr
  MamuteEditProgram()\Operand = *Line\Operand
  MamuteEditProgram()\Comment = *Line\Comment
EndProcedure

; ------------------------------------------------------------
; Comandos de gerenciamento do programa-fonte do EDIT (NEW/DELETE/RENUM/
; CHANGE/LOAD/SAVE, MEGASM.TXT secao "Programas em Assembly") - pedido
; explicito do usuario depois de ver o EDIT em estilo ZX-81 funcionando.
; ------------------------------------------------------------

; Token so com digitos 0-9 - usado pelos numeros de linha de DELETE/RENUM
; (decimais puros, diferente dos enderecos hexa do resto do Mamute).
Procedure.b Mamute_IsDecimalString(Token.s)
  If Token = ""
    ProcedureReturn #False
  EndIf
  Protected i.i
  For i = 1 To Len(Token)
    If Mid(Token, i, 1) < "0" Or Mid(Token, i, 1) > "9"
      ProcedureReturn #False
    EndIf
  Next
  ProcedureReturn #True
EndProcedure

; NEW - apaga o programa-fonte inteiro da memoria, sem confirmacao (mesmo
; comportamento direto do manual original: "o comando NEW simplesmente
; apaga o programa-fonte existente na memoria do EMA"). Tambem invalida o
; ultimo resultado de montagem (MamuteAsmHasResult) - o programa que gerou
; aquele resultado nao existe mais, entao MAP nao deve continuar mostrando
; um intervalo de enderecos de um programa apagado.
Procedure Mamute_AsmNew()
  ClearList(MamuteEditProgram())
  MamuteAsmHasResult = #False
EndProcedure

; DELETE <lininic>[-[<linfin>]] (MEGASM.TXT linha 666) - apaga linhas do
; programa-fonte:
;   <lininic>             so essa linha
;   <lininic>-<linfin>    intervalo [lininic,linfin], inclusive (forma do manual)
;   <lininic>-            de lininic ate o FIM do programa - extensao sobre o
;                         manual (que so documenta a forma com <linfin> explicito),
;                         pedido explicito do usuario ("[-[<linha final>]]"), mesma
;                         convencao do proprio "LIST <li>-" do manual original.
; Devolve quantas linhas foram apagadas; -1 = erro de sintaxe.
Procedure.i Mamute_AsmDelete(Args.s)
  Protected DashPos.i = FindString(Args, "-")
  Protected StartTok.s, EndTok.s
  Protected HasEnd.b = #False
  Protected EndLine.i

  If DashPos > 0
    StartTok = Trim(Left(Args, DashPos - 1))
    EndTok = Trim(Mid(Args, DashPos + 1))
    If EndTok <> ""
      If Not Mamute_IsDecimalString(EndTok)
        ProcedureReturn -1
      EndIf
      HasEnd = #True
      EndLine = Val(EndTok)
    EndIf
  Else
    StartTok = Trim(Args)
  EndIf

  If Not Mamute_IsDecimalString(StartTok)
    ProcedureReturn -1
  EndIf
  Protected StartLine.i = Val(StartTok)

  If DashPos = 0
    EndLine = StartLine
  ElseIf Not HasEnd
    EndLine = 65529 ; "ate o fim" - teto pratico do numero de linha (mesmo do NN do EDIT)
  EndIf
  If EndLine < StartLine
    ProcedureReturn -1
  EndIf

  Protected Deleted.i = 0
  ForEach MamuteEditProgram()
    If MamuteEditProgram()\LineNum >= StartLine And MamuteEditProgram()\LineNum <= EndLine
      DeleteElement(MamuteEditProgram())
      Deleted + 1
    EndIf
  Next
  ProcedureReturn Deleted
EndProcedure

; RENUM [<novali>[,<antigali>[,<incr>]]] (MEGASM.TXT linha 675, mesma ordem
; de parametros do manual - "novali,antigali,incr" - NAO a ordem
; "novalinha,incremento,linhainicialtroca" que o usuario escreveu ao pedir
; este comando; seguido o manual por ser a fonte de verdade documentada
; pra este comando especifico, mas sinalizado aqui pro usuario corrigir se
; realmente quiser a ordem que ele digitou):
;   <novali>   novo numero da PRIMEIRA linha do trecho renumerado (default 10)
;   <antigali> numero (na numeracao ANTIGA) a partir de onde comeca a
;              renumeracao - linhas com NN < antigali ficam intocadas
;              (default: a primeira linha existente, ou seja, o programa
;              INTEIRO e' renumerado)
;   <incr>     incremento entre as linhas renumeradas (default 10)
; Sem nenhum parametro: renumera tudo, comecando em 10, incremento 10 (regra
; explicita do manual). Rejeita a operacao INTEIRA (nada e' alterado) se a
; nova numeracao colidir com uma linha nao renumerada ou passar do teto
; 65529 - nunca aplica uma renumeracao pela metade.
Procedure.b Mamute_AsmRenum(Args.s)
  Protected NovaLi.i = 10
  Protected AntigaLi.i = -1 ; -1 = sentinela "nao especificado"
  Protected Incr.i = 10

  If Args <> ""
    Protected FieldCount.i = CountString(Args, ",") + 1
    If FieldCount > 3
      ProcedureReturn #False
    EndIf
    Protected T1.s = Trim(StringField(Args, 1, ","))
    If T1 <> ""
      If Not Mamute_IsDecimalString(T1) : ProcedureReturn #False : EndIf
      NovaLi = Val(T1)
    EndIf
    If FieldCount >= 2
      Protected T2.s = Trim(StringField(Args, 2, ","))
      If T2 <> ""
        If Not Mamute_IsDecimalString(T2) : ProcedureReturn #False : EndIf
        AntigaLi = Val(T2)
      EndIf
    EndIf
    If FieldCount >= 3
      Protected T3.s = Trim(StringField(Args, 3, ","))
      If T3 <> ""
        If Not Mamute_IsDecimalString(T3) : ProcedureReturn #False : EndIf
        Incr = Val(T3)
        If Incr <= 0 : ProcedureReturn #False : EndIf
      EndIf
    EndIf
  EndIf

  If ListSize(MamuteEditProgram()) = 0
    ProcedureReturn #True ; nada pra renumerar - nao e' erro
  EndIf

  If AntigaLi = -1
    FirstElement(MamuteEditProgram())
    AntigaLi = MamuteEditProgram()\LineNum
  EndIf

  Protected NewLines.i = 0
  ForEach MamuteEditProgram()
    If MamuteEditProgram()\LineNum >= AntigaLi
      NewLines + 1
    EndIf
  Next
  If NewLines = 0
    ProcedureReturn #True ; antigali depois de todo mundo - nada pra fazer
  EndIf

  Protected LastNew.i = NovaLi + (NewLines - 1) * Incr
  If NovaLi < 0 Or LastNew > 65529
    ProcedureReturn #False
  EndIf

  ; a faixa nova [NovaLi..LastNew] nao pode encostar em nenhuma linha
  ; MANTIDA (NN < AntigaLi) - senao a lista deixaria de ficar ordenada.
  ForEach MamuteEditProgram()
    If MamuteEditProgram()\LineNum < AntigaLi And MamuteEditProgram()\LineNum >= NovaLi
      ProcedureReturn #False
    EndIf
  Next

  Protected NextNum.i = NovaLi
  ForEach MamuteEditProgram()
    If MamuteEditProgram()\LineNum >= AntigaLi
      MamuteEditProgram()\LineNum = NextNum
      NextNum + Incr
    EndIf
  Next
  ProcedureReturn #True
EndProcedure

; CHANGE '<string1>'[,'<string2>'] - sintaxe adaptada pedida pelo usuario
; (o manual original mostra "CHANGE '<string1>'[<string2>]", sem virgula
; nem aspas no <string2> - aqui usado o mesmo idioma de virgula+apostrofo
; ja estabelecido pelo SH/MS deste projeto, mais uniforme). Troca todas as
; ocorrencias de String1 por String2 no CORPO de cada linha (RawText -
; label+instrucao+operando+comentario juntos, igual o manual: "troca as
; ocorrencias de <string1> no programa-fonte"); String2 vazio APAGA as
; ocorrencias de String1 (regra explicita do manual). Cada linha alterada
; e' RE-VALIDADA via Mamute_ParseAsmLine() antes de aplicar - se a troca
; quebrar a gramatica da linha, essa linha especifica fica como estava
; (sem meio-termo "salvo com erro"). Devolve quantas linhas foram
; efetivamente alteradas; -1 = erro de sintaxe (String1 vazio).
Procedure.i Mamute_AsmChange(String1.s, String2.s)
  If String1 = ""
    ProcedureReturn -1
  EndIf

  Protected Changed.i = 0
  Protected NewBody.s, FullLine.s
  Protected Reparsed.MamuteEditLine
  ForEach MamuteEditProgram()
    If FindString(MamuteEditProgram()\RawText, String1) > 0
      NewBody = ReplaceString(MamuteEditProgram()\RawText, String1, String2)
      FullLine = Str(MamuteEditProgram()\LineNum) + " " + NewBody
      If Mamute_ParseAsmLine(FullLine, @Reparsed)
        MamuteEditProgram()\RawText = Reparsed\RawText
        MamuteEditProgram()\LabelText = Reparsed\LabelText
        MamuteEditProgram()\Instr = Reparsed\Instr
        MamuteEditProgram()\Operand = Reparsed\Operand
        MamuteEditProgram()\Comment = Reparsed\Comment
        Changed + 1
      EndIf
    EndIf
  Next
  ProcedureReturn Changed
EndProcedure

; SAVE - abre "Salvar como" (sem digitar nome, mesmo padrao ja usado pelo
; LOAD do MON> - MamuteGui_CmdLoad, MamuteAssemblerGui.pbi) e grava o
; programa-fonte inteiro em ASCII puro, uma linha por linha ("NN corpo" -
; o MESMO texto que, digitado de volta no EDIT, reproduz a linha via
; Mamute_ParseAsmLine - round-trip garantido). Formato PROPRIO desta porta,
; NAO o formato binario proprietario do MegaAssembler original - pedido
; explicito do usuario ("inicialmente vamos salvar em ASCII... em outra
; oportunidade vamos tentar ler e interpretar o padrao [proprietario] pra
; poder importar arquivos originais do mega assembler" - fora de escopo
; desta sessao). Devolve mensagem de status pro G_Status ("" = cancelado).
Procedure.s Mamute_AsmSave()
  Protected FilePath.s = SaveFileRequester("Salvar programa-fonte - SAVE", "",
    "Programas Mamute (*.mza)|*.mza|Todos os arquivos (*.*)|*.*", 0)
  If FilePath = ""
    ProcedureReturn ""
  EndIf
  If GetExtensionPart(FilePath) = ""
    FilePath + ".mza"
  EndIf

  Protected Fh = CreateFile(#PB_Any, FilePath)
  If Not Fh
    ProcedureReturn "?ERRO AO GRAVAR ARQUIVO"
  EndIf
  ForEach MamuteEditProgram()
    WriteStringN(Fh, Str(MamuteEditProgram()\LineNum) + " " + MamuteEditProgram()\RawText)
  Next
  CloseFile(Fh)
  ProcedureReturn "GRAVADO: " + GetFilePart(FilePath)
EndProcedure

; Motor comum de LOAD/MERGE - abre "Abrir" (sem digitar nome, mesmo padrao
; do SAVE acima) e le um arquivo no mesmo formato ASCII de Mamute_AsmSave()
; (NAO o formato proprietario do MegaAssembler original, ver nota lá) -
; cada linha lida passa pelo MESMO Mamute_ParseAsmLine() da digitacao ao
; vivo, depois Mamute_StoreAsmLine() (que ja SUBSTITUI automaticamente
; qualquer linha existente com o MESMO NN, mantendo a lista ordenada) -
; e' exatamente a regra "em caso de colisao de numero, a linha lida do
; arquivo prevalece" do comando MERGE do manual original (equivalente ao
; MERGE do BASIC), sem precisar de logica extra pra isso. Linhas invalidas
; no arquivo (ex.: editado a mao, corrompido) sao ignoradas silenciosamente,
; nao abortam a leitura inteira. ClearFirst=#True (LOAD) apaga o programa
; em memoria ANTES de ler, o que faz a substituicao-por-NN virar
; efetivamente "so o arquivo importa"; #False (MERGE) nao apaga nada -
; funde de verdade com o que ja estava la. Devolve quantas linhas foram
; lidas com sucesso; -1 = dialogo cancelado.
Procedure.i Mamute_AsmLoadOrMerge(Title.s, ClearFirst.b)
  Protected FilePath.s = OpenFileRequester(Title, "",
    "Programas Mamute (*.mza)|*.mza|Todos os arquivos (*.*)|*.*", 0)
  If FilePath = ""
    ProcedureReturn -1
  EndIf

  Protected Fh = ReadFile(#PB_Any, FilePath)
  If Not Fh
    ProcedureReturn -1
  EndIf

  If ClearFirst
    ClearList(MamuteEditProgram())
  EndIf
  Protected Loaded.i = 0
  Protected LineText.s
  Protected Parsed.MamuteEditLine
  While Not Eof(Fh)
    LineText = ReadString(Fh, #PB_UTF8)
    If Trim(LineText) <> ""
      If Mamute_ParseAsmLine(LineText, @Parsed)
        Mamute_StoreAsmLine(@Parsed)
        Loaded + 1
      EndIf
    EndIf
  Wend
  CloseFile(Fh)
  ProcedureReturn Loaded
EndProcedure

; LOAD - SUBSTITUI o programa-fonte em memoria pelo conteudo do arquivo
; escolhido. Ver Mamute_AsmLoadOrMerge() acima pro detalhe completo.
Procedure.i Mamute_AsmLoad()
  ProcedureReturn Mamute_AsmLoadOrMerge("Carregar programa-fonte - LOAD", #True)
EndProcedure

; MERGE - pedido explicito do usuario, "igual ao MERGE do BASIC": mostra o
; MESMO dialogo do LOAD, mas NAO apaga o programa em memoria - funde os
; dois. Linhas do arquivo com o MESMO numero de uma linha ja existente
; SOBREPOEM a existente (regra explicita do usuario, tambem a regra do
; manual original: "a existente na memoria sera apagada, prevalecendo a
; linha lida da fita"). Ver Mamute_AsmLoadOrMerge() acima pro detalhe.
Procedure.i Mamute_AsmMerge()
  ProcedureReturn Mamute_AsmLoadOrMerge("Merge de programa-fonte - MERGE", #False)
EndProcedure

; ------------------------------------------------------------
; Comando A (assembla o programa-fonte, MEGASM.TXT linha 786) - pedido
; explicito do usuario, respondido com uma pergunta antes de escrever
; codigo: "acha que da pra implementar o compilador?" A resposta foi NAO
; escrever um compilador novo - `Z80Asm.pbi` (modulo 2 do projeto, mesmo
; motor de "Executar -> Montar Assembly" da IDE principal) JA' e' um
; assembler Z80 completo, compativel M80/Nestor80, validado byte a byte
; contra o N80.exe real. Como o vocabulario do EDIT (Mamute_IsAsmPseudoOp/
; Z80Asm::IsMnemonic) ja' e' um SUBCONJUNTO do que Z80Asm.pbi entende, cada
; linha de MamuteEditProgram() (via RawText, ja sem o NN) ja' e' texto-
; fonte Nestor80 valido - "montar" e' so juntar as linhas e chamar
; Z80Asm::Assemble(), sem tradutor nenhum no meio.
;
; Mensagens de erro: o manual original usa codigos de 1 letra (D/F/M/U/Q/O)
; por cima da linha - pedido explicito do usuario pra usar as mensagens
; DESCRITIVAS de Z80Asm::GetAssembleErrorText() em vez disso ("vai
; facilitar"), sem tentar reconstruir os codigos antigos.
; ------------------------------------------------------------

Structure MamuteAsmResult
  Ok.b          ; #True = montado sem erro (mesmo que ByteCount=0, so rotulos/EQU/diretivas)
  ErrorLine.i    ; NN do Mamute onde o erro ocorreu (0 = nao aplicavel/nao mapeado)
  ErrorText.s
  ByteCount.i    ; quantos bytes foram gerados (0 = nada)
  StartAddr.u
  EndAddr.u
EndStructure

; Devolve o NN (numero de linha do Mamute) correspondente a' LinhaFonte
; (1-based - mesma numeracao que Z80Asm::GetAssembleErrorLine() devolve).
; Como o texto-fonte pra Z80Asm::Assemble() e' montado juntando
; MamuteEditProgram() em ordem, 1 linha de texto por elemento (nunca
; linhas em branco - Mamute_ParseAsmLine ja rejeita corpo vazio), a linha K
; do fonte e' SEMPRE o K-esimo elemento da lista, sem precisar de nenhuma
; tabela de mapeamento a parte. -1 se fora da faixa.
Procedure.i Mamute_AsmLineNumberAtSourceLine(LinhaFonte.i)
  If LinhaFonte < 1 Or LinhaFonte > ListSize(MamuteEditProgram())
    ProcedureReturn -1
  EndIf
  SelectElement(MamuteEditProgram(), LinhaFonte - 1)
  ProcedureReturn MamuteEditProgram()\LineNum
EndProcedure

; Se Token comeca com digito 0-9 e NAO tem sufixo H/B/D reconhecido no
; final, acrescenta "H" - achado real desta sessao (usuario reportou "0a2 e'
; invalido" ao compilar): o EDIT aceita numeros SEM sufixo como HEXADECIMAL
; por padrao (Mamute_ParseAsmNumber, pedido explicito do usuario "pra ficar
; uniforme" com o resto do Mamute), mas Z80Asm.pbi (o motor reaproveitado
; pra montar de verdade) segue a convencao classica M80/Nestor80 - numero
; SEM sufixo e' DECIMAL por padrao (conferido lendo TokenizeExpr() em
; Z80Asm.pbi). "0A2" digitado no EDIT significa hexa 162 pro usuario, mas
; o Z80Asm tentaria ler "0A2" como decimal (tem letra, nao bate) e
; rejeitaria com "Numero invalido: 0A2" - exatamente o erro relatado. A
; traducao so' precisa ACRESCENTAR "H" - sufixos que JA' existem (H/B/D)
; tem o MESMO significado nos dois sistemas (conferido no mesmo
; TokenizeExpr), entao ficam intocados.
Procedure.s Mamute_MaybeAddHexSuffix(Token.s)
  If Token = "" Or Mid(Token, 1, 1) < "0" Or Mid(Token, 1, 1) > "9"
    ProcedureReturn Token
  EndIf
  Protected LastCh.s = UCase(Right(Token, 1))
  If LastCh = "H" Or LastCh = "B" Or LastCh = "D"
    ProcedureReturn Token
  EndIf
  ProcedureReturn Token + "H"
EndProcedure

; Aplica Mamute_MaybeAddHexSuffix() a cada token numerico do Operando,
; preservando tudo o mais (pontuacao, registradores, labels, texto entre
; apostrofos nunca e' tocado) - mesmo scanner quote-aware de
; Mamute_ValidateAsmOperandNumbers() acima, so' que RECONSTRUINDO o texto
; em vez de so validar.
Procedure.s Mamute_TranslateOperandForZ80Asm(Operand.s)
  Protected Result.s = ""
  Protected InQuote.b = #False
  Protected L.i = Len(Operand)
  Protected i.i, Ch.s, Token.s = ""

  For i = 1 To L + 1
    If i <= L
      Ch = Mid(Operand, i, 1)
    Else
      Ch = " "
    EndIf

    If InQuote
      Result + Ch
      If Ch = "'"
        InQuote = #False
      EndIf
      Continue
    EndIf

    If Ch = "'"
      If Token <> ""
        Result + Mamute_MaybeAddHexSuffix(Token)
        Token = ""
      EndIf
      InQuote = #True
      Result + Ch
      Continue
    EndIf

    If (Ch >= "0" And Ch <= "9") Or (Ch >= "A" And Ch <= "Z") Or (Ch >= "a" And Ch <= "z")
      Token + Ch
    Else
      If Token <> ""
        Result + Mamute_MaybeAddHexSuffix(Token)
        Token = ""
      EndIf
      If i <= L
        Result + Ch
      EndIf
    EndIf
  Next

  ProcedureReturn Result
EndProcedure

; Formata Z80Asm::GetListingRow() (ja' preenchida pela ultima
; Z80Asm::Assemble() bem-sucedida) em texto pronto pra desenhar, colunas
; fixas com ESPACOS (nao TAB literal - GDI num CanvasGadget nao expande
; tab de forma confiavel, mesmo achado ja documentado pra
; MamuteEdit_PadToColumn() no EDIT): "NN  ENDR  XX XX XX XX  conteudo" -
; NN/ENDR em branco numa linha de CONTINUACAO (mais de 4 bytes na mesma
; linha-fonte). O conteudo usa RawText cru (nao o alinhamento em tab-stop
; de MamuteEdit_FormatLine(), que vive em MamuteEditGui.pbi - incluido
; DEPOIS de MamuteSupport.pbi, chamar de dentro daqui violaria a ordem de
; declaracao) - suficiente pra uma listagem, que e' um documento a parte,
; nao a tela viva de edicao. Preenche MamuteAsmListingLines() acima.
;
; HideLineNumbers (opcao N do comando A do manual original, MEGASM.TXT
; linha 793: "Nao lista o numero das linhas") - so' a coluna NN fica em
; branco, ENDR/hex/conteudo continuam exatamente iguais (pedido explicito
; do usuario: "de resto e' igual").
Procedure Mamute_AsmBuildListingLines(HideLineNumbers.b = #False)
  ClearList(MamuteAsmListingLines())
  Protected RowCount.i = Z80Asm::GetListingRowCount()
  Protected i.i, b.i, Idx0.i
  Protected Row.Z80Asm::Z80ListingRow
  Protected Line.s, HexPart.s, Content.s, NumPart.s

  For i = 0 To RowCount - 1
    Z80Asm::GetListingRow(i, @Row)

    Content = ""
    If Row\HasAddr
      Idx0 = Row\SourceLine - 1
      If Idx0 >= 0 And Idx0 < ListSize(MamuteEditProgram())
        SelectElement(MamuteEditProgram(), Idx0)
        Content = MamuteEditProgram()\RawText
        If HideLineNumbers
          NumPart = Space(5)
        Else
          NumPart = RSet(Str(MamuteEditProgram()\LineNum), 5)
        EndIf
        Line = NumPart + "  " + Mamute_Hex4(Row\Addr) + "  "
      Else
        Line = Space(5) + "  " + Space(4) + "  "
      EndIf
    Else
      Line = Space(5) + "  " + Space(4) + "  "
    EndIf

    HexPart = ""
    For b = 0 To Row\ByteCount - 1
      Select b
        Case 0 : HexPart + Mamute_Hex2(Row\Byte0) + " "
        Case 1 : HexPart + Mamute_Hex2(Row\Byte1) + " "
        Case 2 : HexPart + Mamute_Hex2(Row\Byte2) + " "
        Case 3 : HexPart + Mamute_Hex2(Row\Byte3) + " "
      EndSelect
    Next
    Line + LSet(HexPart, 12) + " " + Content

    AddElement(MamuteAsmListingLines())
    MamuteAsmListingLines() = Line
  Next
EndProcedure

; Formata Z80Asm::GetXrefRow() (ja' preenchida pela ultima Z80Asm::Assemble()
; bem-sucedida) em texto pronto pra desenhar: "NOME  VALOR  ENDR ENDR ..."
; - NOME/VALOR em branco numa linha de CONTINUACAO (simbolo com mais de 4
; usos). Mesmas colunas fixas com ESPACOS de Mamute_AsmBuildListingLines()
; acima (motivo identico: GDI num CanvasGadget nao expande tab). Preenche
; MamuteAsmXrefLines() acima.
Procedure Mamute_AsmBuildXrefLines()
  ClearList(MamuteAsmXrefLines())
  Protected RowCount.i = Z80Asm::GetXrefRowCount()
  Protected i.i, a.i
  Protected Row.Z80Asm::Z80XrefRow
  Protected Line.s, AddrPart.s

  For i = 0 To RowCount - 1
    Z80Asm::GetXrefRow(i, @Row)

    If Row\HasValue
      Line = LSet(Row\SymName, 8) + "  " + Mamute_Hex4(Row\Value) + "  "
    Else
      Line = Space(8) + "  " + Space(4) + "  "
    EndIf

    AddrPart = ""
    For a = 0 To Row\AddrCount - 1
      Select a
        Case 0 : AddrPart + Mamute_Hex4(Row\Addr0) + " "
        Case 1 : AddrPart + Mamute_Hex4(Row\Addr1) + " "
        Case 2 : AddrPart + Mamute_Hex4(Row\Addr2) + " "
        Case 3 : AddrPart + Mamute_Hex4(Row\Addr3) + " "
      EndSelect
    Next
    Line + Trim(AddrPart)

    AddElement(MamuteAsmXrefLines())
    MamuteAsmXrefLines() = Line
  Next
EndProcedure

; Formata a mesma tabela de Z80Asm::GetXrefRow() (ja' ordenada
; alfabeticamente) em "NOME  VALOR" simples - opcao S do comando A, pedido
; explicito do usuario: so' o nome e o endereco/valor de definicao, SEM os
; enderecos de uso (isso e' o "R"). So' aproveita as linhas com HasValue
; (a 1a de cada simbolo em Z80Asm::XrefRows()) - pula as de continuacao,
; que so existem por causa dos enderecos de uso que aqui nao interessam.
; Preenche MamuteAsmLabelListLines() acima.
Procedure Mamute_AsmBuildLabelListLines()
  ClearList(MamuteAsmLabelListLines())
  Protected RowCount.i = Z80Asm::GetXrefRowCount()
  Protected i.i
  Protected Row.Z80Asm::Z80XrefRow

  For i = 0 To RowCount - 1
    Z80Asm::GetXrefRow(i, @Row)
    If Row\HasValue
      AddElement(MamuteAsmLabelListLines())
      MamuteAsmLabelListLines() = LSet(Row\SymName, 8) + "  " + Mamute_Hex4(Row\Value)
    EndIf
  Next
EndProcedure

; Mesmo layout "NOME  VALOR" de Mamute_AsmBuildLabelListLines() acima, mas
; usando Z80Asm::GetLabelDefOrderCount()/GetLabelDefOrderName() (ordem de
; DEFINICAO no fonte) em vez de Z80Asm::XrefRows() (alfabetica) - opcao D
; do comando A, pedido explicito do usuario: "identica a A S, porem a
; lista de labels e' por ordem de aparicao e nao alfabetica". Preenche
; MamuteAsmLabelOrderLines() acima.
Procedure Mamute_AsmBuildLabelOrderLines()
  ClearList(MamuteAsmLabelOrderLines())
  Protected Count.i = Z80Asm::GetLabelDefOrderCount()
  Protected i.i, Name.s

  For i = 0 To Count - 1
    Name = Z80Asm::GetLabelDefOrderName(i)
    AddElement(MamuteAsmLabelOrderLines())
    MamuteAsmLabelOrderLines() = LSet(Name, 8) + "  " + Mamute_Hex4(Z80Asm::GetSymbolValue(Name))
  Next
EndProcedure

; Monta MamuteEditProgram() inteiro via Z80Asm::Assemble() - so' faz a
; passagem/validacao (sem gravar em lugar nenhum ainda; quem chama decide o
; que fazer com OutBytes()/StartAddr/EndAddr em caso de sucesso - ver
; comando "A O" em MamuteEditGui.pbi). OutBytes precisa vir dimensionado
; pelo chamador (Array OutBytes.a(65535), mesma exigencia de
; Z80Asm::Assemble()).
;
; **Limitacao conhecida, aceita por ora**: se o programa tiver MAIS de um
; ORG com um vao entre os dois blocos, StartAddr/EndAddr cobrem o vao
; INTEIRO (Z80Asm::Assemble() so' rastreia o endereco minimo/maximo
; tocado, nao um mapa byte a byte) - o vao vem preenchido com zeros. Isso
; e' exatamente a MESMA limitacao que "Executar -> Montar Assembly" da IDE
; principal ja aceita pra exportar em arquivo (Z80Out_ChooseAndExport);
; aqui importa mais porque "A O" ESCREVE na RAM simulada por cima do que
; ja estava la' - um programa com um unico ORG (caso comum, e' o que o
; usuario descreveu) nao tem esse problema.
Procedure Mamute_AsmAssemble(*Out.MamuteAsmResult, Array OutBytes.a(1), HideLineNumbers.b = #False, OffsetValue.i = 0)
  *Out\Ok = #False
  *Out\ErrorLine = 0
  *Out\ErrorText = ""
  *Out\ByteCount = 0
  *Out\StartAddr = 0
  *Out\EndAddr = 0
  MamuteAsmLastWroteToRam = #False ; ve o comentario junto do Global acima - o chamador seta #True se "O" escrever com sucesso

  ; Reconstroi cada linha a partir dos campos JA' separados (Label/Instr/
  ; Operand), em vez de usar RawText direto - precisa traduzir o Operando
  ; pro dialeto numerico do Z80Asm (Mamute_TranslateOperandForZ80Asm() logo
  ; acima, ver comentario la' pro achado completo). Comentario incluido de
  ; volta so' por fidelidade (Z80Asm ja ignora comentario de qualquer jeito
  ; - nunca precisa de traducao).
  ;
  ; OffsetValue (opcao /<offset> do comando A, pedido explicito do usuario:
  ; "compila o programa mas adiciona o OFFSET ao ORG para gerar em outro
  ; endereco") - somado ao operando de toda linha `ORG` (envolvido entre
  ; parenteses, "0" na frente do literal hexa garantindo que o Z80Asm nao
  ; confunda com um label mesmo se comecar com A-F) ANTES de reconstruir o
  ; texto-fonte - o resto da montagem (rotulos, saltos, listagem) segue
  ; automaticamente o ORG deslocado, sem precisar mexer em mais nada (nao
  ; ha necessidade de tocar Z80Asm.pbi pra isso - a expressao aritmetica ja
  ; resolve tudo). Se o programa tiver MAIS de um `ORG`, o MESMO offset e'
  ; somado a todos, consistente.
  Protected SourceText.s = ""
  Protected LineOut.s
  Protected OrgOperand.s
  ForEach MamuteEditProgram()
    If SourceText <> ""
      SourceText + Chr(10)
    EndIf
    LineOut = ""
    If MamuteEditProgram()\LabelText <> ""
      LineOut = MamuteEditProgram()\LabelText + ": "
    EndIf
    LineOut + MamuteEditProgram()\Instr
    If MamuteEditProgram()\Operand <> ""
      OrgOperand = Mamute_TranslateOperandForZ80Asm(MamuteEditProgram()\Operand)
      If OffsetValue <> 0 And MamuteEditProgram()\Instr = "ORG"
        OrgOperand = "(" + OrgOperand + ")+0" + Mamute_Hex4(OffsetValue) + "H"
      EndIf
      LineOut + " " + OrgOperand
    EndIf
    If MamuteEditProgram()\Comment <> ""
      LineOut + " ;" + MamuteEditProgram()\Comment
    EndIf
    SourceText + LineOut
  Next

  Protected N.i = Z80Asm::Assemble(SourceText, OutBytes())
  If N < 0
    Protected SrcLine.i = Z80Asm::GetAssembleErrorLine()
    Protected MappedLine.i = Mamute_AsmLineNumberAtSourceLine(SrcLine)
    If MappedLine >= 0
      *Out\ErrorLine = MappedLine
    EndIf
    *Out\ErrorText = Z80Asm::GetAssembleErrorText()
    ProcedureReturn
  EndIf

  *Out\Ok = #True
  *Out\ByteCount = N
  If N > 0
    *Out\StartAddr = Z80Asm::GetAssembleStartAddr()
    *Out\EndAddr = Z80Asm::GetAssembleEndAddr()
  EndIf

  ; Guarda o resultado pro comando MAP (MamuteEditGui.pbi) - QUALQUER
  ; montagem bem-sucedida atualiza isso, "A" sozinho ou "A O" (os dois
  ; calculam o mesmo intervalo, so' "A O" tambem grava na RAM - ver
  ; comentario de MamuteAsmHasResult acima). Uma tentativa que falha (N<0)
  ; nunca chega aqui (o ProcedureReturn do bloco de erro acima ja' saiu).
  MamuteAsmHasResult = #True
  MamuteAsmLastByteCount = N
  MamuteAsmLastStartAddr = *Out\StartAddr
  MamuteAsmLastEndAddr = *Out\EndAddr
  Mamute_AsmBuildListingLines(HideLineNumbers)
  Mamute_AsmBuildXrefLines()
  Mamute_AsmBuildLabelListLines()
  Mamute_AsmBuildLabelOrderLines()
EndProcedure
