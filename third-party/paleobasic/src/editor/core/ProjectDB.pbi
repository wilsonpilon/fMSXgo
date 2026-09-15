;
; ------------------------------------------------------------
;  ProjectDB.pbi - armazenamento de "projeto MSX" num arquivo SQLite unico.
;  Guarda hoje Sprites, Alfabetos, Sons (PSG) e Musicas (MML/PLAY) - ver
;  docs/SPEC.md / CLAUDE.md; outros tipos de conteudo do projeto (Basic,
;  Assembly, Telas, listagens LM) ganham tabela quando tiverem editor propio.
;
;  Ao iniciar sem nenhum parametro de linha de comando, BadigEditor.pb chama
;  EnsureOpen() logo de cara, que cria "noname.msxproject" dentro de
;  "<exe>\projects\" (NewTempPath() abaixo) - o projeto implicito onde
;  tudo vai sendo gravado ate o usuario criar um projeto explicito
;  (Arquivo -> Novo projeto...) ou salvar o "noname" num local definitivo
;  (que o app oferece ao sair, se houver conteudo registrado - ver
;  OfferSaveProject() em BadigEditor.pb). Pedido explicito do usuario
;  (2026-08-19, reorganizacao de diretorios) - antes vivia em
;  GetTemporaryDirectory() (pasta temp do SO, perdida em qualquer limpeza de
;  temp/troca de maquina); agora e' um lugar durável dentro de dist\, mesmo
;  espirito de dist\res\/dist\sample\ (conteudo que "mora" ao lado do
;  executavel). O ARQUIVO em si nao e' versionado (estado mutavel de sessao
;  pra sessao, ver .gitignore) - so' a pasta projects\ existe garantida.
;
;  A grade de pixels de cada sprite vira uma coluna TEXT: um digito
;  hexadecimal por bloco (0-F, cobre os indices de cor 0-15 da palheta),
;  grid_size*grid_size caracteres, linha a linha - evita depender da API de
;  bind de BLOB do driver SQLite do PureBasic (nao usada em nenhum exemplo
;  local, sem necessidade real aqui).
; ------------------------------------------------------------
;

UseSQLiteDatabase()

DeclareModule ProjectDB
  Declare.i EnsureOpen()
  Declare.i CreateNew(Path.s)
  Declare.i OpenExisting(Path.s)
  Declare.i SaveAs(NewPath.s)
  Declare.i IsTemp()
  Declare.s GetPath()
  Declare.i HasUnsavedContent()
  Declare Close()

  Declare SetWorkingDir(Dir.s)
  Declare.s GetWorkingDir()
  Declare SetInfoValue(Key.s, Value.s)
  Declare.s GetInfoValue(Key.s)
  Declare.s OverrideSettingsPath(FileName.s)

  Declare.i StoreDocument(Path.s, Mode.s, Content.s)
  Declare.i FetchDocument(Path.s)
  Declare.s LastDocumentContent()
  Declare.s LastDocumentMode()
  Declare ListDocumentPaths(List Paths.s())
  Declare DeleteDocument(Path.s)

  Declare.i StoreSprite(Number.i, Tag.s, GridSize.i, SpriteMode.i, Array Grid.b(2))
  Declare.i FetchSprite(Number.i, Array Grid.b(2))
  Declare.i LastGridSize()
  Declare.i LastSpriteMode()
  Declare.s LastTag()
  Declare.i HasSprite(Number.i)
  Declare ListSpriteNumbers(List Numbers.i())

  Declare.i StoreAlphabet(Number.i, Tag.s, Array CharsetBytes.a(2))
  Declare.i FetchAlphabet(Number.i, Array CharsetBytes.a(2))
  Declare.s LastAlphabetTag()
  Declare.i HasAlphabet(Number.i)
  Declare ListAlphabetNumbers(List Numbers.i())

  ; Um "som" e uma sequencia de passos, cada um com os 14 registradores crus
  ; do PSG (SOUND 0-13) + duracao em quadros - ver editor/PsgSynth.pbi/
  ; PsgEditorGui.pbi. Regs() e 1D "achatado" (Regs(i*14+r), NumSteps*14
  ; elementos - nao uma matriz 2D, porque ReDim so redimensiona a ULTIMA
  ; dimensao de um array no PureBasic, e FetchSound precisa devolver um
  ; numero de passos variavel); Durations() tem NumSteps elementos. Arrays
  ; primitivos (nao a estrutura PsgStepData de PsgSynth.pbi) pra este modulo
  ; nao depender da ordem de XIncludeFile de PsgSynth.pbi - mesmo espirito de
  ; Array Grid.b(2)/CharsetBytes.a(2) acima.
  Declare.i StoreSound(Number.i, Tag.s, NumSteps.i, Array Regs.a(1), Array Durations.w(1))
  Declare.i FetchSound(Number.i, Array Regs.a(1), Array Durations.w(1))
  Declare.i LastSoundStepCount()
  Declare.s LastSoundTag()
  Declare.i HasSound(Number.i)
  Declare ListSoundNumbers(List Numbers.i())

  ; SeeTrackerEditorGui.pbi ("Criar -> SEE Tracker...") - um "SFX" e uma
  ; sequencia ORDENADA de patterns, cada um os 15 bytes CRUS exatamente no
  ; formato de arquivo .SEE real (evento + 3x frequencia + rustle + controle
  ; de canais + 3x volume + periodo/forma de envelope - ver
  ; editor/SeeTrackerSynth.pbi e Ajuda -> SEE Tracker...). PatternBytes() e
  ; 1D "achatado" (PatternBytes(i*15+b), NumPatterns*15 elementos - mesmo
  ; motivo de Regs() em StoreSound/FetchSound acima: ReDim so redimensiona a
  ; ULTIMA dimensao de um array no PureBasic). Guardar o byte CRU (nao uma
  ; struct interpretada) deixa a serializacao aqui identica ao que
  ; "Gerar codigo"/o driver de replay realmente consomem - sem risco de
  ; divergencia entre "o que editamos" e "o que sai"/"o que toca".
  Declare.i StoreSeeSfx(Number.i, Tag.s, NumPatterns.i, Array PatternBytes.a(1))
  Declare.i FetchSeeSfx(Number.i, Array PatternBytes.a(1))
  Declare.i LastSeeSfxPatternCount()
  Declare.s LastSeeSfxTag()
  Declare.i HasSeeSfx(Number.i)
  Declare ListSeeSfxNumbers(List Numbers.i())

  ; Uma "musica" MML/PLAY guarda as linhas de texto MML montadas em cada um
  ; dos 3 canais (A/B/C) - ver editor/MmlSynth.pbi/MmlEditorGui.pbi. Lines()
  ; e uma matriz 2D FIXA (canal 0-2, indice de linha) dimensionada pelo
  ; chamador (Dim Lines.s(2, N-1)) - nunca redimensionada aqui dentro
  ; (LineCount() controla quantas linhas de cada canal estao realmente em
  ; uso), entao nao esbarra na limitacao de ReDim documentada acima pra
  ; StoreSound/FetchSound.
  Declare.i StoreSong(Number.i, Tag.s, Array Lines.s(2), Array LineCount.i(1))
  Declare.i FetchSong(Number.i, Array Lines.s(2), Array LineCount.i(1))
  Declare.s LastSongTag()
  Declare.i HasSong(Number.i)
  Declare ListSongNumbers(List Numbers.i())

  ; Uma "tela" (editor grafico SCREEN 2, modulo 5) guarda a LISTA DE
  ; COMANDOS de desenho (nao o framebuffer resultante) como um unico TEXT
  ; opaco - um comando por linha, campos separados por "|". ProjectDB.pbi
  ; nao conhece a Structure Scr2_Command (definida em Screen2Synth.pbi,
  ; incluido DEPOIS deste arquivo em BadigEditor.pb) - o mesmo motivo que
  ; ja levou StoreSound/FetchSound a usar arrays primitivos em vez da
  ; Structure PsgStepData de PsgSynth.pbi. Quem serializa/desserializa e
  ; Screen2EditorGui.pbi; aqui e so um blob de texto guardado e devolvido.
  Declare.i StoreScreen(Number.i, Tag.s, CommandsText.s)
  Declare.i FetchScreen(Number.i)
  Declare.s LastScreenCommandsText()
  Declare.s LastScreenTag()
  Declare.i HasScreen(Number.i)
  Declare ListScreenNumbers(List Numbers.i())

  ; Screen0EditorGui.pbi ("Criar -> Screen 0...") - editor de tela de texto
  ; estilo TheDraw/AcidDraw, fiel ao hardware MSX: uma grade fixa Width x 24
  ; de CARACTERES UNICODE (nao bytes MSX crus - ver comentario grande no topo
  ; de Screen0EditorGui.pbi: 31 dos 159 caracteres especiais do -tr precisam
  ; do escape de impressao CHR$(1)+CHR$(n), nao cabem num unico byte 0-255,
  ; entao o grid grava o CODEPOINT Unicode de cada celula, 4 digitos hex
  ; cada - "Gerar codigo" deixa a traducao -tr resolver pro byte/escape MSX
  ; na hora de tokenizar). INK/PAPER (Ink/Paper) sao globais pra tela inteira,
  ; fieis ao SCREEN 0 classico (40 colunas). Em telas de 80 colunas (WIDTH 80,
  ; modo T2 do VDP) o hardware real tem um SEGUNDO par de cor (Ink2/Paper2,
  ; VDP R#12) que cada caractere pode usar, piscando com o par normal num
  ; ritmo configuravel (BlinkOnPeriod/BlinkOffPeriod, VDP R#13, nibbles 0-15
  ; = unidades de 1/6s cada) ou travado permanentemente na cor2 (zerando
  ; BlinkOnPeriod) - GridAttrs marca, 1 byte (0 ou 1) por celula, quais
  ; celulas usam esse mecanismo (tabela de piscar de verdade do VDP, 1 bit
  ; por celula la, mas guardada aqui 1 byte por celula pelo mesmo motivo de
  ; GridCodes: simplicidade > espaco, SQLite TEXT nao liga). Sem efeito em
  ; telas de 40 colunas (o hardware nao tem esse recurso nesse modo).
  ; AlphabetNumber = -1 significa fonte padrao (nao referencia nenhum
  ; alfabeto do banco); qualquer outro valor e o numero de um alfabeto ja
  ; registrado em "alphabets" (usado so pra PREVIEW do editor e pro
  ; carregador de fonte gerado - o texto em si nao depende do bitmap da
  ; fonte pra ser correto).
  Declare.i StoreScreen0(Number.i, Tag.s, Width.i, Ink.i, Paper.i, AlphabetNumber.i,
                         Ink2.i, Paper2.i, BlinkOn.i, BlinkOff.i, Array GridCodes.u(1), Array GridAttrs.a(1))
  Declare.i FetchScreen0(Number.i, Array GridCodes.u(1), Array GridAttrs.a(1))
  Declare.s LastScreen0Tag()
  Declare.i LastScreen0Width()
  Declare.i LastScreen0Ink()
  Declare.i LastScreen0Paper()
  Declare.i LastScreen0AlphabetNumber()
  Declare.i LastScreen0Ink2()
  Declare.i LastScreen0Paper2()
  Declare.i LastScreen0BlinkOn()
  Declare.i LastScreen0BlinkOff()
  Declare.i HasScreen0(Number.i)
  Declare ListScreen0Numbers(List Numbers.i())

  ; Screen1EditorGui.pbi ("Criar -> Screen 1...") - grade FIXA 32x24 (768
  ; celulas) de bytes MSX crus 0-255 (nao Unicode como screen0_screens acima -
  ; SCREEN 1 nao tem os 31 caracteres de escape sem byte proprio que motivaram
  ; guardar Unicode no screen0; aqui cada celula JA E o byte final, hex-
  ; codificado 2 digitos). octet_data guarda os 32 pares Tinta/Fundo (1 digito
  ; hex cada, 4 bits) da Color Table real do SCREEN 1 - grupo de 8 codigos de
  ; caractere por entrada (codigo\8), nao por posicao de tela.
  Declare.i StoreScreen1(Number.i, Tag.s, AlphabetNumber.i, Array GridBytes.a(1), Array OctetInk.a(1), Array OctetPaper.a(1))
  Declare.i FetchScreen1(Number.i, Array GridBytes.a(1), Array OctetInk.a(1), Array OctetPaper.a(1))
  Declare.s LastScreen1Tag()
  Declare.i LastScreen1AlphabetNumber()
  Declare.i HasScreen1(Number.i)
  Declare ListScreen1Numbers(List Numbers.i())

  ; Screen12EditorGui.pbi ("Criar -> Screen 1+2...") - mesma grade FIXA 32x24
  ; de screen1_screens, mas gerando SCREEN 2 (Graphics II) de verdade: a
  ; Pattern/Color Table reais do SCREEN 2 sao divididas em 3 "tercos" de 2048
  ; bytes (selecionados por qual terco de linhas de tela - 0-7/8-15/16-23 -
  ; a celula esta), CADA TERCO com seu proprio alfabeto (AlphaThirds(0..2),
  ; -1 = fonte padrao), e a Color Table de verdade guarda 1 par Tinta/Fundo
  ; POR LINHA DE SCANLINE de cada codigo de caractere (nao 1 por celula nem 1
  ; por grupo de 8 codigos como screen1_screens) - 3 tercos x 256 codigos x 8
  ; linhas = 6144 entradas, exatamente do tamanho da Color Table real
  ; (6144 bytes). color_data guarda 2 digitos hex/entrada (1 pra Tinta, 1
  ; pra Fundo, ordem Terco->Codigo->Linha, mesma convencao 4 bits/cor de
  ; octet_data em screen1_screens).
  Declare.i StoreScreen12(Number.i, Tag.s, Array AlphaThirds.i(1), Array GridBytes.a(1), Array ColorInk.a(3), Array ColorPaper.a(3))
  Declare.i FetchScreen12(Number.i, Array AlphaThirds.i(1), Array GridBytes.a(1), Array ColorInk.a(3), Array ColorPaper.a(3))
  Declare.s LastScreen12Tag()
  Declare.i HasScreen12(Number.i)
  Declare ListScreen12Numbers(List Numbers.i())

  ; Graphos III (modulo 14, GraphosScreenGui.pbi) guarda 3 tipos de conteudo,
  ; cada um um FRAMEBUFFER puro (nao lista de comandos como "screens" acima,
  ; que pertence ao editor "Draw Screen 2..." do modulo 5 - tabelas
  ; separadas de proposito, formatos incompativeis): TELA (pixels + Tinta/
  ; Fundo por faixa, igual ao framebuffer PatternBit/RowFG/RowBG do editor),
  ; LAYOUT (so pixels, sem cor - equivalente ao .LAY do Graphos III
  ; original) e SHAPE (recorte retangular de tamanho VARIAVEL, igual ao
  ; CRIA SHAPES do original, sem a escolha de mascara/tipo ainda - isso fica
  ; pro carimbo em MISCELANEA, fase futura). Pattern/Color sao empacotados 1
  ; byte por celula de 8 pixels (mesmo layout logico da Pattern/Color Table
  ; de verdade do TMS9918 - byte de cor com INK no nibble alto e PAPER no
  ; nibble baixo), hex-codificados 2 digitos por byte, mesmo padrao ja usado
  ; por StoreAlphabet acima. Como este arquivo compila ANTES de
  ; Screen2Synth.pbi (ordem de XIncludeFile em BadigEditor.pb), os limites
  ; 256/192/32 sao literais aqui, nao #Scr2_Width/Height/Cols - mesmo motivo
  ; de StoreAlphabet hardcodar 256/8 em vez de uma constante externa.
  Declare.i StoreGraphosScreen(Number.i, Tag.s, Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2))
  Declare.i FetchGraphosScreen(Number.i, Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2))
  Declare.s LastGraphosScreenTag()
  Declare.i HasGraphosScreen(Number.i)
  Declare ListGraphosScreenNumbers(List Numbers.i())

  Declare.i StoreGraphosLayout(Number.i, Tag.s, Array PatternBit.a(2))
  Declare.i FetchGraphosLayout(Number.i, Array PatternBit.a(2))
  Declare.s LastGraphosLayoutTag()
  Declare.i HasGraphosLayout(Number.i)
  Declare ListGraphosLayoutNumbers(List Numbers.i())

  ; Width/Height variam por shape (recorte retangular do tamanho que o
  ; usuario marcou no canvas) - PatternBit()/RowFG()/RowBG() do chamador sao
  ; sempre dimensionados no tamanho MAXIMO do canvas (igual Tela/Layout);
  ; Store/Fetch so leem/escrevem a sub-regiao [0..Height-1, 0..Width-1].
  Declare.i StoreGraphosShape(Number.i, Tag.s, Width.i, Height.i, Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2))
  Declare.i FetchGraphosShape(Number.i, Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2))
  Declare.s LastGraphosShapeTag()
  Declare.i LastGraphosShapeWidth()
  Declare.i LastGraphosShapeHeight()
  Declare.i HasGraphosShape(Number.i)
  Declare ListGraphosShapeNumbers(List Numbers.i())

  ; Metadado da ULTIMA exportacao de binario feita a partir do assembler Z80
  ; (modulo 2/2b, ver editor/Z80Asm.pbi/Z80Link.pbi) - montagem absoluta de
  ; uma aba .asm (BuildKind="ABS") ou binario final de uma sessao de link
  ; (BuildKind="LINK"), sempre que o resultado vira de fato um arquivo
  ; consumivel no PC/disco MSX (OutputKind "BIN"/"DSK" - nao ha registro pra
  ; "so gerei o listing DATA/POKE e copiei", que nao produz nenhum arquivo em
  ; disco, ver editor/Z80OutputGui.pbi). SourceKey e o caminho do .asm de
  ; origem (montagem simples) ou do binario final ja salvo (sessao de link,
  ; que nao tem uma unica aba de origem) - so serve de chave de "ultima
  ; build", sem outro uso. Fora da soma de HasUnsavedContent() de proposito,
  ; mesmo motivo de "documents": e metadado de algo que ja foi exportado pra
  ; um arquivo independente em disco, perder o registro no banco temporario
  ; nao perde trabalho de verdade.
  Declare.i StoreAsmBuild(SourceKey.s, BuildKind.s, OutputKind.s, OutputPath.s, StartAddr.u, EndAddr.u, BLoadHeader.i)
  Declare.i FetchAsmBuild(SourceKey.s)
  Declare.s LastAsmBuildKind()
  Declare.s LastAsmBuildOutputKind()
  Declare.s LastAsmBuildOutputPath()
  Declare.u LastAsmBuildStartAddr()
  Declare.u LastAsmBuildEndAddr()
  Declare.i LastAsmBuildBLoadHeader()
  Declare.i HasAsmBuild(SourceKey.s)
  Declare ListAsmBuildKeys(List Keys.s())

  ; Um "subprojeto de Assembly" (Criar -> Assembly Sub Project..., modulo 2/2b,
  ; ver editor/Z80SubProject.pbi/Z80SubProjectGui.pbi) e um "Makefile
  ; primitivo": uma lista ORDENADA de fontes .asm (cada uma vira um .REL na
  ; hora de montar) mais uma lista ORDENADA de bibliotecas (.REQUEST)
  ; referenciadas no link - a ordem de ambas importa (mesma ordem de
  ; concatenacao CSEG/DSEG/COMMON e de resolucao que Z80Link::LinkFiles usa).
  ; AsmFiles()/LibFiles() sao TEXT unidos por Chr(10) na ordem escolhida
  ; (mesmo padrao de mml_songs\lines_a/b/c) - simples o bastante pra nao
  ; precisar de tabela filha. Diferente de asm_builds (metadado de algo ja
  ; exportado pra um arquivo independente), aqui e configuracao de verdade
  ; sem nenhuma copia em outro lugar - entra na soma de HasUnsavedContent().
  Declare.i StoreAsmSubProject(Number.i, Tag.s, List AsmFiles.s(), List LibFiles.s())
  Declare.i FetchAsmSubProject(Number.i, List AsmFiles.s(), List LibFiles.s())
  Declare.s LastAsmSubProjectTag()
  Declare.i HasAsmSubProject(Number.i)
  Declare ListAsmSubProjectNumbers(List Numbers.i())

  ; "Projeto 0": banco SQLite a parte, sempre em memoria (nunca em arquivo,
  ; nunca salvo), recriado do zero a cada vez que a IDE abre - fonte interna
  ; de conteudo padrao (hoje so o alfabeto 0 = msx.alf embutido no executavel
  ; via DefaultCharsetMsx.pbi; outros tipos de conteudo ganham entrada aqui
  ; conforme forem sendo desenvolvidos). So leitura pelo resto do app.
  Declare.i FetchDefaultAlphabet(Number.i, Array CharsetBytes.a(2))

  Declare.s GetLastError()
EndDeclareModule

Module ProjectDB
  ; Incluido de dentro do proprio Module (nao no topo de BadigEditor.pb como
  ; os demais XIncludeFile) porque um Module do PureBasic nao enxerga
  ; procedures/DataSection definidas fora dele, mesmo com forward
  ; declaration - so funciona se a inclusao acontecer aqui dentro.
  XIncludeFile "../visual_editors/DefaultCharsetMsx.pbi"

  #DB = 0
  #DefaultsDB = 1   ; "projeto 0" - conexao SQLite separada, sempre :memory:

  Global IsOpen.b = #False
  Global TempFlag.b = #False
  Global CurrentPath.s = ""
  Global LastError.s = ""
  Global FetchedGridSize.i = 0
  Global FetchedSpriteMode.i = 0
  Global FetchedTag.s = ""
  Global FetchedDocContent.s = ""
  Global FetchedDocMode.s = ""
  Global FetchedAlphabetTag.s = ""
  Global FetchedSoundTag.s = ""
  Global FetchedStepCount.i = 0
  Global FetchedSeeSfxTag.s = ""
  Global FetchedSeeSfxPatternCount.i = 0
  Global FetchedSongTag.s = ""
  Global FetchedScreenTag.s = ""
  Global FetchedScreenCommandsText.s = ""
  Global FetchedScreen0Tag.s = ""
  Global FetchedScreen0Width.i = 0
  Global FetchedScreen0Ink.i = 0
  Global FetchedScreen0Paper.i = 0
  Global FetchedScreen0AlphabetNumber.i = -1
  Global FetchedScreen0Ink2.i = 15
  Global FetchedScreen0Paper2.i = 1
  Global FetchedScreen0BlinkOn.i = 8
  Global FetchedScreen0BlinkOff.i = 8
  Global FetchedScreen1Tag.s = ""
  Global FetchedScreen1AlphabetNumber.i = -1
  Global FetchedScreen12Tag.s = ""
  Global FetchedGraphosScreenTag.s = ""
  Global FetchedGraphosLayoutTag.s = ""
  Global FetchedGraphosShapeTag.s = ""
  Global FetchedGraphosShapeWidth.i = 0
  Global FetchedGraphosShapeHeight.i = 0
  Global FetchedAsmBuildKind.s = ""
  Global FetchedAsmBuildOutputKind.s = ""
  Global FetchedAsmBuildOutputPath.s = ""
  Global FetchedAsmBuildStartAddr.u = 0
  Global FetchedAsmBuildEndAddr.u = 0
  Global FetchedAsmBuildBLoadHeader.i = 0
  Global FetchedSubProjTag.s = ""
  Global DefaultsOpen.b = #False

  Procedure.s NewTempPath()
    Protected ProjectsDir.s = GetPathPart(ProgramFilename()) + "projects\"
    If FileSize(ProjectsDir) <> -2 ; -2 = diretorio ja existe
      CreateDirectory(ProjectsDir)
    EndIf
    ProcedureReturn ProjectsDir + "noname.msxproject"
  EndProcedure

  Procedure RunSchema()
    DatabaseUpdate(#DB, "CREATE TABLE IF NOT EXISTS project_info (key TEXT PRIMARY KEY, value TEXT)")
    DatabaseUpdate(#DB, "CREATE TABLE IF NOT EXISTS sprites (" +
                         "sprite_number INTEGER PRIMARY KEY, " +
                         "tag TEXT, " +
                         "grid_size INTEGER NOT NULL, " +
                         "sprite_mode INTEGER NOT NULL, " +
                         "pixel_data TEXT NOT NULL, " +
                         "updated_at TEXT)")
    DatabaseUpdate(#DB, "CREATE TABLE IF NOT EXISTS documents (" +
                         "path TEXT PRIMARY KEY, " +
                         "mode TEXT NOT NULL, " +
                         "content TEXT NOT NULL, " +
                         "updated_at TEXT)")
    DatabaseUpdate(#DB, "CREATE TABLE IF NOT EXISTS alphabets (" +
                         "alphabet_number INTEGER PRIMARY KEY, " +
                         "tag TEXT, " +
                         "charset_data TEXT NOT NULL, " +
                         "updated_at TEXT)")
    DatabaseUpdate(#DB, "CREATE TABLE IF NOT EXISTS psg_sounds (" +
                         "sound_number INTEGER PRIMARY KEY, " +
                         "tag TEXT, " +
                         "step_count INTEGER NOT NULL, " +
                         "steps_data TEXT NOT NULL, " +
                         "updated_at TEXT)")
    DatabaseUpdate(#DB, "CREATE TABLE IF NOT EXISTS see_sfx (" +
                         "sfx_number INTEGER PRIMARY KEY, " +
                         "tag TEXT, " +
                         "pattern_count INTEGER NOT NULL, " +
                         "patterns_data TEXT NOT NULL, " +
                         "updated_at TEXT)")
    DatabaseUpdate(#DB, "CREATE TABLE IF NOT EXISTS mml_songs (" +
                         "song_number INTEGER PRIMARY KEY, " +
                         "tag TEXT, " +
                         "lines_a TEXT NOT NULL, " +
                         "lines_b TEXT NOT NULL, " +
                         "lines_c TEXT NOT NULL, " +
                         "updated_at TEXT)")
    DatabaseUpdate(#DB, "CREATE TABLE IF NOT EXISTS screens (" +
                         "screen_number INTEGER PRIMARY KEY, " +
                         "tag TEXT, " +
                         "commands_data TEXT NOT NULL, " +
                         "updated_at TEXT)")
    DatabaseUpdate(#DB, "CREATE TABLE IF NOT EXISTS screen0_screens (" +
                         "screen0_number INTEGER PRIMARY KEY, " +
                         "tag TEXT, " +
                         "width INTEGER NOT NULL, " +
                         "ink_color INTEGER NOT NULL, " +
                         "paper_color INTEGER NOT NULL, " +
                         "alphabet_number INTEGER NOT NULL, " +
                         "grid_data TEXT NOT NULL, " +
                         "ink2_color INTEGER NOT NULL DEFAULT 15, " +
                         "paper2_color INTEGER NOT NULL DEFAULT 1, " +
                         "blink_on_period INTEGER NOT NULL DEFAULT 8, " +
                         "blink_off_period INTEGER NOT NULL DEFAULT 8, " +
                         "attr_data TEXT NOT NULL DEFAULT '', " +
                         "updated_at TEXT)")
    DatabaseUpdate(#DB, "CREATE TABLE IF NOT EXISTS screen1_screens (" +
                         "screen1_number INTEGER PRIMARY KEY, " +
                         "tag TEXT, " +
                         "alphabet_number INTEGER NOT NULL, " +
                         "grid_data TEXT NOT NULL, " +
                         "octet_data TEXT NOT NULL, " +
                         "updated_at TEXT)")
    DatabaseUpdate(#DB, "CREATE TABLE IF NOT EXISTS screen12_screens (" +
                         "screen12_number INTEGER PRIMARY KEY, " +
                         "tag TEXT, " +
                         "alphabet0 INTEGER NOT NULL, " +
                         "alphabet1 INTEGER NOT NULL, " +
                         "alphabet2 INTEGER NOT NULL, " +
                         "grid_data TEXT NOT NULL, " +
                         "color_data TEXT NOT NULL, " +
                         "updated_at TEXT)")
    DatabaseUpdate(#DB, "CREATE TABLE IF NOT EXISTS graphos_screens (" +
                         "screen_number INTEGER PRIMARY KEY, " +
                         "tag TEXT, " +
                         "pattern_data TEXT NOT NULL, " +
                         "color_data TEXT NOT NULL, " +
                         "updated_at TEXT)")
    DatabaseUpdate(#DB, "CREATE TABLE IF NOT EXISTS graphos_layouts (" +
                         "layout_number INTEGER PRIMARY KEY, " +
                         "tag TEXT, " +
                         "pattern_data TEXT NOT NULL, " +
                         "updated_at TEXT)")
    DatabaseUpdate(#DB, "CREATE TABLE IF NOT EXISTS graphos_shapes (" +
                         "shape_number INTEGER PRIMARY KEY, " +
                         "tag TEXT, " +
                         "width INTEGER NOT NULL, " +
                         "height INTEGER NOT NULL, " +
                         "pattern_data TEXT NOT NULL, " +
                         "color_data TEXT NOT NULL, " +
                         "updated_at TEXT)")
    DatabaseUpdate(#DB, "CREATE TABLE IF NOT EXISTS asm_builds (" +
                         "source_key TEXT PRIMARY KEY, " +
                         "build_kind TEXT NOT NULL, " +
                         "output_kind TEXT NOT NULL, " +
                         "output_path TEXT NOT NULL, " +
                         "start_addr INTEGER NOT NULL, " +
                         "end_addr INTEGER NOT NULL, " +
                         "bload_header INTEGER NOT NULL, " +
                         "updated_at TEXT)")
    DatabaseUpdate(#DB, "CREATE TABLE IF NOT EXISTS asm_subprojects (" +
                         "subproject_number INTEGER PRIMARY KEY, " +
                         "tag TEXT, " +
                         "asm_files TEXT NOT NULL, " +
                         "lib_files TEXT NOT NULL, " +
                         "updated_at TEXT)")
  EndProcedure

  ; Fecha o banco atual (se houver) e abre em Path, criando o arquivo antes
  ; se preciso (SQLite/OpenDatabase espera que o arquivo ja exista).
  Procedure.i OpenAt(Path.s, CreateFileFirst.b)
    If IsOpen
      CloseDatabase(#DB)
      IsOpen = #False
    EndIf

    If CreateFileFirst
      Protected FileNum = CreateFile(#PB_Any, Path)
      If Not FileNum
        LastError = "Nao foi possivel criar o arquivo: " + Path
        ProcedureReturn #False
      EndIf
      CloseFile(FileNum)
    EndIf

    If Not OpenDatabase(#DB, Path, "", "")
      LastError = "Nao foi possivel abrir o banco: " + Path
      ProcedureReturn #False
    EndIf

    IsOpen = #True
    CurrentPath = Path
    ProcedureReturn #True
  EndProcedure

  ; Achado real (2026-08-12, pedido do Mamute Assembler guardar historico de
  ; comandos "mesmo sem projeto aberto, entre sessoes"): OpenAt(...,
  ; CreateFileFirst=#True) sempre chamava CreateFile(), que TRUNCA um
  ; arquivo existente - o projeto temporario implicito (NewTempPath(),
  ; "noname.msxproject") era apagado toda vez que o editor abria de novo e
  ; algo tocava ProjectDB pela primeira vez nessa sessao, mesmo que a sessao
  ; anterior ja tivesse gravado dado nele. Afetava qualquer consumidor do
  ; projeto temporario, nao so o Mamute (ex.: os 3 booleans de override em
  ; "Configurar -> Projeto..."). So cria o arquivo do zero se ele ainda nao
  ; existir - se ja existir (sessao anterior sem projeto salvo), abre e
  ; reaproveita o conteudo, dado que RunSchema() so faz CREATE TABLE IF NOT
  ; EXISTS (nunca apaga dado). CreateNew() (Arquivo -> Novo projeto...)
  ; continua chamando OpenAt(..., #True) direto, sem essa checagem - "Novo
  ; projeto" precisa mesmo comecar vazio, mesmo que o caminho escolhido ja
  ; tenha um arquivo (o dialogo de Salvar Como ja confirma sobrescrever
  ; antes de devolver o caminho).
  Procedure.i EnsureOpen()
    If IsOpen
      ProcedureReturn #True
    EndIf
    Protected TempPath.s = NewTempPath()
    Protected NeedsCreate.b = Bool(FileSize(TempPath) < 0)
    If Not OpenAt(TempPath, NeedsCreate)
      ProcedureReturn #False
    EndIf
    RunSchema()
    TempFlag = #True
    SetWorkingDir(GetCurrentDirectory())
    ProcedureReturn #True
  EndProcedure

  ; Cria um projeto novo e vazio em Path e passa a usa-lo. Se o projeto
  ; anterior era o temporario implicito, apaga o arquivo temporario (quem
  ; chama e responsavel por ja ter oferecido salvar o conteudo antigo antes).
  Procedure.i CreateNew(Path.s)
    Protected OldPath.s = CurrentPath
    Protected WasTemp.b = TempFlag

    If Not OpenAt(Path, #True)
      ProcedureReturn #False
    EndIf
    RunSchema()
    TempFlag = #False
    SetWorkingDir(GetCurrentDirectory())

    If WasTemp And OldPath <> "" And OldPath <> Path
      DeleteFile(OldPath)
    EndIf
    ProcedureReturn #True
  EndProcedure

  ; Abre um projeto ja existente em Path (Arquivo -> Abrir projeto...) e
  ; passa a usa-lo - nao cria nada, o arquivo precisa existir. RunSchema()
  ; roda mesmo assim (CREATE TABLE IF NOT EXISTS, nunca mexe em dado
  ; existente) pra cobrir um projeto mais antigo/parcial que ainda nao tenha
  ; alguma tabela. Se o projeto anterior era o temporario implicito, apaga o
  ; arquivo temporario (quem chama e responsavel por ja ter oferecido salvar
  ; o conteudo antigo antes - ver OfferSaveProject() em BadigEditor.pb).
  Procedure.i OpenExisting(Path.s)
    If FileSize(Path) < 0
      LastError = "Arquivo nao encontrado: " + Path
      ProcedureReturn #False
    EndIf

    Protected OldPath.s = CurrentPath
    Protected WasTemp.b = TempFlag

    If Not OpenAt(Path, #False)
      ProcedureReturn #False
    EndIf
    RunSchema()
    TempFlag = #False

    If WasTemp And OldPath <> "" And OldPath <> Path
      DeleteFile(OldPath)
    EndIf
    ProcedureReturn #True
  EndProcedure

  ; Promove o projeto atual (normalmente o temporario) para NewPath, como um
  ; "Salvar como": copia o arquivo, reabre no novo local, e so entao apaga o
  ; antigo se ele era o temporario.
  Procedure.i SaveAs(NewPath.s)
    If Not IsOpen
      ProcedureReturn #False
    EndIf

    Protected OldPath.s = CurrentPath
    Protected WasTemp.b = TempFlag

    CloseDatabase(#DB)
    IsOpen = #False

    If Not CopyFile(OldPath, NewPath)
      LastError = "Nao foi possivel copiar para: " + NewPath
      OpenDatabase(#DB, OldPath, "", "")
      IsOpen = #True
      ProcedureReturn #False
    EndIf

    If Not OpenDatabase(#DB, NewPath, "", "")
      LastError = "Nao foi possivel reabrir: " + NewPath
      ; Reabre o banco antigo pra nao deixar IsOpen/CurrentPath inconsistentes -
      ; sem isso, EnsureOpen() (chamado por quase todo o resto do modulo) nao
      ; olha CurrentPath e criaria um novo projeto temporario do zero,
      ; abandonando o projeto real do usuario silenciosamente.
      OpenDatabase(#DB, OldPath, "", "")
      IsOpen = #True
      ProcedureReturn #False
    EndIf

    IsOpen = #True
    CurrentPath = NewPath
    TempFlag = #False

    If WasTemp And OldPath <> ""
      DeleteFile(OldPath)
    EndIf
    ProcedureReturn #True
  EndProcedure

  Procedure.i IsTemp()
    ProcedureReturn TempFlag
  EndProcedure

  Procedure.s GetPath()
    ProcedureReturn CurrentPath
  EndProcedure

  ; True quando o projeto ainda e o temporario implicito (nunca foi salvo
  ; num local permanente) E ja tem pelo menos um registro num dos tipos de
  ; conteudo que so existem dentro do banco do projeto (sprites, alfabetos,
  ; sons PSG, musicas MML, telas SCREEN 2, subprojetos de Assembly) - e o
  ; sinal usado pra avisar o usuario ao sair ou ao criar outro projeto.
  ; Documentos (.dmx/.asm/tokenizado) E asm_builds (metadado de "ultima
  ; exportacao", ver comentario da declaracao de StoreAsmBuild) ficam de
  ; fora de proposito: sao copia/derivado de um arquivo que ja existe em
  ; disco por conta propria, entao perder o registro no banco temporario
  ; nao perde trabalho de verdade (diferente de sprite/alfabeto/som/musica/
  ; tela/subprojeto, que so vivem aqui - um subprojeto e so a LISTA de
  ; arquivos/libs, configuracao real sem nenhuma copia em outro lugar).
  Procedure.i HasUnsavedContent()
    If Not IsOpen Or Not TempFlag
      ProcedureReturn #False
    EndIf

    Protected Count.i = 0
    If DatabaseQuery(#DB, "SELECT " +
                           "(SELECT COUNT(*) FROM sprites) + " +
                           "(SELECT COUNT(*) FROM alphabets) + " +
                           "(SELECT COUNT(*) FROM psg_sounds) + " +
                           "(SELECT COUNT(*) FROM mml_songs) + " +
                           "(SELECT COUNT(*) FROM screens) + " +
                           "(SELECT COUNT(*) FROM graphos_screens) + " +
                           "(SELECT COUNT(*) FROM graphos_layouts) + " +
                           "(SELECT COUNT(*) FROM graphos_shapes) + " +
                           "(SELECT COUNT(*) FROM asm_subprojects)")
      If NextDatabaseRow(#DB)
        Count = Val(GetDatabaseString(#DB, 0))
      EndIf
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Bool(Count > 0)
  EndProcedure

  ; Fecha o banco; se ainda era o temporario implicito (nunca promovido a um
  ; arquivo permanente), apaga o arquivo - quem decide salvar antes e quem
  ; chama (ver fluxo de saida/"Novo projeto" em BadigEditor.pb).
  Procedure Close()
    If IsOpen
      CloseDatabase(#DB)
      IsOpen = #False
    EndIf
    If TempFlag And CurrentPath <> ""
      DeleteFile(CurrentPath)
    EndIf
    CurrentPath = ""
  EndProcedure

  ; Diretorio "de trabalho" do projeto: pasta onde os arquivos-fonte (abas de
  ; texto) estao sendo salvos - atualizado a cada SaveDocument() bem-sucedido
  ; em BadigEditor.pb (GetPathPart do caminho salvo). Chave/valor avulsa em
  ; project_info, inicializada com GetCurrentDirectory() quando o projeto e
  ; criado (implicito "noname" ou "Novo projeto..."), antes de qualquer
  ; arquivo ter sido salvo - "o diretorio corrente se o usuario usou o
  ; padrao".
  Procedure SetWorkingDir(Dir.s)
    If Not EnsureOpen()
      ProcedureReturn
    EndIf

    Protected SafeDir.s = ReplaceString(Dir, "'", "''")
    DatabaseUpdate(#DB, "DELETE FROM project_info WHERE key='working_dir'")
    DatabaseUpdate(#DB, "INSERT INTO project_info (key, value) VALUES ('working_dir', '" + SafeDir + "')")
  EndProcedure

  Procedure.s GetWorkingDir()
    If Not EnsureOpen()
      ProcedureReturn ""
    EndIf

    Protected Result.s = ""
    If DatabaseQuery(#DB, "SELECT value FROM project_info WHERE key='working_dir'")
      If NextDatabaseRow(#DB)
        Result = GetDatabaseString(#DB, 0)
      EndIf
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Result
  EndProcedure

  ; Versao generica de SetWorkingDir/GetWorkingDir acima (qualquer chave, nao
  ; so "working_dir") - usada por "Configurar -> Projeto..." (ProjectSettingsGui.pbi)
  ; pra guardar os 3 booleans "usar config especifica deste projeto"
  ; (badig/n80/msxbas2rom_override_enabled). Mesmo padrao DELETE+INSERT (nao
  ; UPSERT - SQLite embutido do PureBasic pode nao suportar a sintaxe
  ; ON CONFLICT em toda versao).
  Procedure SetInfoValue(Key.s, Value.s)
    If Not EnsureOpen()
      ProcedureReturn
    EndIf

    Protected SafeKey.s = ReplaceString(Key, "'", "''")
    Protected SafeValue.s = ReplaceString(Value, "'", "''")
    DatabaseUpdate(#DB, "DELETE FROM project_info WHERE key='" + SafeKey + "'")
    DatabaseUpdate(#DB, "INSERT INTO project_info (key, value) VALUES ('" + SafeKey + "', '" + SafeValue + "')")
  EndProcedure

  Procedure.s GetInfoValue(Key.s)
    If Not EnsureOpen()
      ProcedureReturn ""
    EndIf

    Protected SafeKey.s = ReplaceString(Key, "'", "''")
    Protected Result.s = ""
    If DatabaseQuery(#DB, "SELECT value FROM project_info WHERE key='" + SafeKey + "'")
      If NextDatabaseRow(#DB)
        Result = GetDatabaseString(#DB, 0)
      EndIf
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Result
  EndProcedure

  ; Caminho de um arquivo de configuracao POR PROJETO (ex.:
  ; "project_badig_settings.json") - ao lado do .msxproject salvo, mesma
  ; pasta de GetWorkingDir(). "" quando ainda nao ha projeto salvo (working
  ; dir vazio) - quem chama (ProjectSettingsGui.pbi) trata isso desabilitando
  ; a tela com uma mensagem "salve o projeto primeiro", nao tenta escrever
  ; num caminho vazio.
  Procedure.s OverrideSettingsPath(FileName.s)
    Protected Dir.s = GetWorkingDir()
    If Dir = ""
      ProcedureReturn ""
    EndIf
    If Right(Dir, 1) <> "\" And Right(Dir, 1) <> "/"
      Dir + "\"
    EndIf
    ProcedureReturn Dir + FileName
  EndProcedure

  ; Guarda uma copia atualizada do conteudo de uma aba de texto ja salva em
  ; disco (Path sempre um caminho absoluto real, nunca aba "noname" ainda nao
  ; salva) - chamado por SaveDocument() em BadigEditor.pb logo apos escrever
  ; o arquivo .dmx/.amx/.asm, mantendo o projeto com uma copia em sincronia
  ; com o que esta no disco. DELETE + INSERT (mesmo padrao de StoreSprite)
  ; chaveado por path, entao salvar a mesma aba de novo so atualiza a linha.
  Procedure.i StoreDocument(Path.s, Mode.s, Content.s)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected SafePath.s = ReplaceString(Path, "'", "''")
    Protected SafeMode.s = ReplaceString(Mode, "'", "''")
    Protected SafeContent.s = ReplaceString(Content, "'", "''")

    DatabaseUpdate(#DB, "DELETE FROM documents WHERE path='" + SafePath + "'")
    Protected SQL.s = "INSERT INTO documents (path, mode, content, updated_at) VALUES ('" +
                       SafePath + "', '" + SafeMode + "', '" + SafeContent + "', datetime('now'))"
    ProcedureReturn DatabaseUpdate(#DB, SQL)
  EndProcedure

  ; Le de volta a copia de uma aba guardada por StoreDocument(); mesmo padrao
  ; de FetchSprite() (campos extras via LastDocumentContent()/LastDocumentMode()
  ; em vez de parametro de saida por ponteiro de string).
  Procedure.i FetchDocument(Path.s)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected SafePath.s = ReplaceString(Path, "'", "''")
    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT mode, content FROM documents WHERE path='" + SafePath + "'")
      If NextDatabaseRow(#DB)
        FetchedDocMode = GetDatabaseString(#DB, 0)
        FetchedDocContent = GetDatabaseString(#DB, 1)
        Found = #True
      EndIf
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure.s LastDocumentContent()
    ProcedureReturn FetchedDocContent
  EndProcedure

  Procedure.s LastDocumentMode()
    ProcedureReturn FetchedDocMode
  EndProcedure

  ; Remove a linha de um documento (usado por RestoreMissingDocumentsToDisk()
  ; em BadigEditor.pb quando o arquivo e re-extraido pra um caminho NOVO -
  ; a linha antiga, chaveada pelo caminho original de outra maquina, precisa
  ; sair pra nao ficar duplicada/inalcancavel).
  Procedure DeleteDocument(Path.s)
    If Not EnsureOpen()
      ProcedureReturn
    EndIf
    Protected SafePath.s = ReplaceString(Path, "'", "''")
    DatabaseUpdate(#DB, "DELETE FROM documents WHERE path='" + SafePath + "'")
  EndProcedure

  ; Todos os caminhos de documentos ja guardados por StoreDocument() -
  ; usado por RestoreMissingDocumentsToDisk()/ResyncProjectDocumentsFromDisk()
  ; (BadigEditor.pb) pra saber quais arquivos o projeto ja conhece, sem
  ; precisar adivinhar varrendo o diretorio de trabalho.
  Procedure ListDocumentPaths(List Paths.s())
    ClearList(Paths())
    If Not EnsureOpen()
      ProcedureReturn
    EndIf

    If DatabaseQuery(#DB, "SELECT path FROM documents ORDER BY path ASC")
      While NextDatabaseRow(#DB)
        AddElement(Paths())
        Paths() = GetDatabaseString(#DB, 0)
      Wend
      FinishDatabaseQuery(#DB)
    EndIf
  EndProcedure

  Procedure.i StoreSprite(Number.i, Tag.s, GridSize.i, SpriteMode.i, Array Grid.b(2))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected Row, Col
    Protected HexData.s = ""
    For Row = 0 To GridSize - 1
      For Col = 0 To GridSize - 1
        HexData = HexData + Hex(Grid(Row, Col))
      Next
    Next

    Protected SafeTag.s = Left(ReplaceString(Tag, "'", "''"), 16)

    ; DELETE + INSERT em vez de "ON CONFLICT DO UPDATE" pra nao depender de
    ; uma versao especifica do SQLite.
    DatabaseUpdate(#DB, "DELETE FROM sprites WHERE sprite_number=" + Str(Number))
    Protected SQL.s = "INSERT INTO sprites (sprite_number, tag, grid_size, sprite_mode, pixel_data, updated_at) VALUES (" +
                       Str(Number) + ", '" + SafeTag + "', " + Str(GridSize) + ", " + Str(SpriteMode) +
                       ", '" + HexData + "', datetime('now'))"
    ProcedureReturn DatabaseUpdate(#DB, SQL)
  EndProcedure

  ; Le o sprite Number pra dentro de Grid() e devolve #True/#False; os demais
  ; campos (tag/tamanho/modo) ficam disponiveis logo em seguida via
  ; LastTag()/LastGridSize()/LastSpriteMode() (evita parametros de saida por
  ; ponteiro pra string, que nao sobrevivem ao retorno da procedure).
  Procedure.i FetchSprite(Number.i, Array Grid.b(2))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT tag, grid_size, sprite_mode, pixel_data FROM sprites WHERE sprite_number=" + Str(Number))
      If NextDatabaseRow(#DB)
        FetchedTag = GetDatabaseString(#DB, 0)
        FetchedGridSize = Val(GetDatabaseString(#DB, 1))
        FetchedSpriteMode = Val(GetDatabaseString(#DB, 2))
        Protected PixelData.s = GetDatabaseString(#DB, 3)

        Protected Row, Col, Idx = 0
        For Row = 0 To FetchedGridSize - 1
          For Col = 0 To FetchedGridSize - 1
            If Idx < Len(PixelData)
              Grid(Row, Col) = Val("$" + Mid(PixelData, Idx + 1, 1))
            EndIf
            Idx + 1
          Next
        Next
        Found = #True
      EndIf
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure.i LastGridSize()
    ProcedureReturn FetchedGridSize
  EndProcedure

  Procedure.i LastSpriteMode()
    ProcedureReturn FetchedSpriteMode
  EndProcedure

  Procedure.s LastTag()
    ProcedureReturn FetchedTag
  EndProcedure

  Procedure.i HasSprite(Number.i)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT 1 FROM sprites WHERE sprite_number=" + Str(Number))
      Found = NextDatabaseRow(#DB)
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure ListSpriteNumbers(List Numbers.i())
    ClearList(Numbers())
    If Not EnsureOpen()
      ProcedureReturn
    EndIf

    If DatabaseQuery(#DB, "SELECT sprite_number FROM sprites ORDER BY sprite_number ASC")
      While NextDatabaseRow(#DB)
        AddElement(Numbers())
        Numbers() = Val(GetDatabaseString(#DB, 0))
      Wend
      FinishDatabaseQuery(#DB)
    EndIf
  EndProcedure

  ; Empacota CharsetBytes (256x8) num unico TEXT hex (2 digitos por byte,
  ; 4096 caracteres) e grava (DELETE+INSERT, mesmo padrao de StoreSprite) na
  ; tabela alphabets de DBNum - interna, usada tanto pelo projeto ativo
  ; (#DB) quanto pelo projeto de defaults (#DefaultsDB, so na semeadura do
  ; alfabeto 0).
  Procedure.i StoreAlphabetInto(DBNum.i, Number.i, Tag.s, Array CharsetBytes.a(2))
    Protected Row, Col
    Protected HexData.s = ""
    For Row = 0 To 255
      For Col = 0 To 7
        HexData = HexData + RSet(Hex(CharsetBytes(Row, Col)), 2, "0")
      Next
    Next

    Protected SafeTag.s = Left(ReplaceString(Tag, "'", "''"), 16)

    DatabaseUpdate(DBNum, "DELETE FROM alphabets WHERE alphabet_number=" + Str(Number))
    Protected SQL.s = "INSERT INTO alphabets (alphabet_number, tag, charset_data, updated_at) VALUES (" +
                       Str(Number) + ", '" + SafeTag + "', '" + HexData + "', datetime('now'))"
    ProcedureReturn DatabaseUpdate(DBNum, SQL)
  EndProcedure

  ; Le de volta um alfabeto de DBNum pra dentro de CharsetBytes (256x8) -
  ; tag extra via LastAlphabetTag() (mesmo padrao de FetchSprite/FetchDocument).
  Procedure.i FetchAlphabetFrom(DBNum.i, Number.i, Array CharsetBytes.a(2))
    Protected Found.b = #False
    If DatabaseQuery(DBNum, "SELECT tag, charset_data FROM alphabets WHERE alphabet_number=" + Str(Number))
      If NextDatabaseRow(DBNum)
        FetchedAlphabetTag = GetDatabaseString(DBNum, 0)
        Protected HexData.s = GetDatabaseString(DBNum, 1)
        Protected Row, Col, Idx = 0
        For Row = 0 To 255
          For Col = 0 To 7
            CharsetBytes(Row, Col) = Val("$" + Mid(HexData, Idx * 2 + 1, 2))
            Idx + 1
          Next
        Next
        Found = #True
      EndIf
      FinishDatabaseQuery(DBNum)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure.i StoreAlphabet(Number.i, Tag.s, Array CharsetBytes.a(2))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf
    ProcedureReturn StoreAlphabetInto(#DB, Number, Tag, CharsetBytes())
  EndProcedure

  Procedure.i FetchAlphabet(Number.i, Array CharsetBytes.a(2))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf
    ProcedureReturn FetchAlphabetFrom(#DB, Number, CharsetBytes())
  EndProcedure

  Procedure.s LastAlphabetTag()
    ProcedureReturn FetchedAlphabetTag
  EndProcedure

  Procedure.i HasAlphabet(Number.i)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT 1 FROM alphabets WHERE alphabet_number=" + Str(Number))
      Found = NextDatabaseRow(#DB)
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure ListAlphabetNumbers(List Numbers.i())
    ClearList(Numbers())
    If Not EnsureOpen()
      ProcedureReturn
    EndIf

    If DatabaseQuery(#DB, "SELECT alphabet_number FROM alphabets ORDER BY alphabet_number ASC")
      While NextDatabaseRow(#DB)
        AddElement(Numbers())
        Numbers() = Val(GetDatabaseString(#DB, 0))
      Wend
      FinishDatabaseQuery(#DB)
    EndIf
  EndProcedure

  ; Empacota Regs()/Durations() (Regs "achatado" em 1D, NumSteps*14
  ; elementos - Regs(i*14+r) - e nao uma matriz 2D, porque ReDim so
  ; redimensiona a ULTIMA dimensao de um array no PureBasic; um array 1D e a
  ; unica forma segura de FetchSound devolver um numero de passos variavel)
  ; num unico TEXT hex de largura fixa (32 digitos por passo: 28 dos 14
  ; registradores de 1 byte + 4 da duracao de 2 bytes) e grava (DELETE+INSERT,
  ; mesmo padrao de StoreSprite/StoreAlphabet).
  Procedure.i StoreSound(Number.i, Tag.s, NumSteps.i, Array Regs.a(1), Array Durations.w(1))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected i, r
    Protected HexData.s = ""
    For i = 0 To NumSteps - 1
      For r = 0 To 13
        HexData = HexData + RSet(Hex(Regs(i * 14 + r)), 2, "0")
      Next
      HexData = HexData + RSet(Hex(Durations(i)), 4, "0")
    Next

    Protected SafeTag.s = Left(ReplaceString(Tag, "'", "''"), 16)

    DatabaseUpdate(#DB, "DELETE FROM psg_sounds WHERE sound_number=" + Str(Number))
    Protected SQL.s = "INSERT INTO psg_sounds (sound_number, tag, step_count, steps_data, updated_at) VALUES (" +
                       Str(Number) + ", '" + SafeTag + "', " + Str(NumSteps) + ", '" + HexData + "', datetime('now'))"
    ProcedureReturn DatabaseUpdate(#DB, SQL)
  EndProcedure

  ; Le de volta um som pra dentro de Regs()/Durations() (redimensionados aqui
  ; dentro pro tamanho certo - Array passado por referencia, ReDim afeta o
  ; array do chamador; Regs e 1D "achatado", ver comentario de StoreSound);
  ; tag/numero de passos extras via LastSoundTag()/LastSoundStepCount()
  ; (mesmo padrao de FetchSprite/FetchAlphabet).
  Procedure.i FetchSound(Number.i, Array Regs.a(1), Array Durations.w(1))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT tag, step_count, steps_data FROM psg_sounds WHERE sound_number=" + Str(Number))
      If NextDatabaseRow(#DB)
        FetchedSoundTag = GetDatabaseString(#DB, 0)
        FetchedStepCount = Val(GetDatabaseString(#DB, 1))
        Protected HexData.s = GetDatabaseString(#DB, 2)

        If FetchedStepCount > 0
          ReDim Regs(FetchedStepCount * 14 - 1)
          ReDim Durations(FetchedStepCount - 1)
          Protected i, r, Pos = 1
          For i = 0 To FetchedStepCount - 1
            For r = 0 To 13
              Regs(i * 14 + r) = Val("$" + Mid(HexData, Pos, 2))
              Pos + 2
            Next
            Durations(i) = Val("$" + Mid(HexData, Pos, 4))
            Pos + 4
          Next
        EndIf
        Found = #True
      EndIf
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure.i LastSoundStepCount()
    ProcedureReturn FetchedStepCount
  EndProcedure

  Procedure.s LastSoundTag()
    ProcedureReturn FetchedSoundTag
  EndProcedure

  Procedure.i HasSound(Number.i)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT 1 FROM psg_sounds WHERE sound_number=" + Str(Number))
      Found = NextDatabaseRow(#DB)
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure ListSoundNumbers(List Numbers.i())
    ClearList(Numbers())
    If Not EnsureOpen()
      ProcedureReturn
    EndIf

    If DatabaseQuery(#DB, "SELECT sound_number FROM psg_sounds ORDER BY sound_number ASC")
      While NextDatabaseRow(#DB)
        AddElement(Numbers())
        Numbers() = Val(GetDatabaseString(#DB, 0))
      Wend
      FinishDatabaseQuery(#DB)
    EndIf
  EndProcedure

  ; Empacota PatternBytes() (1D achatado, NumPatterns*15 elementos) num TEXT
  ; hex de largura fixa (30 digitos/pattern) - mesmo padrao de StoreSound
  ; acima, so trocando 14+2 bytes/passo por 15 bytes/pattern.
  Procedure.i StoreSeeSfx(Number.i, Tag.s, NumPatterns.i, Array PatternBytes.a(1))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected i, b
    Protected HexData.s = ""
    For i = 0 To NumPatterns - 1
      For b = 0 To 14
        HexData = HexData + RSet(Hex(PatternBytes(i * 15 + b)), 2, "0")
      Next
    Next

    Protected SafeTag.s = Left(ReplaceString(Tag, "'", "''"), 16)

    DatabaseUpdate(#DB, "DELETE FROM see_sfx WHERE sfx_number=" + Str(Number))
    Protected SQL.s = "INSERT INTO see_sfx (sfx_number, tag, pattern_count, patterns_data, updated_at) VALUES (" +
                       Str(Number) + ", '" + SafeTag + "', " + Str(NumPatterns) + ", '" + HexData + "', datetime('now'))"
    ProcedureReturn DatabaseUpdate(#DB, SQL)
  EndProcedure

  Procedure.i FetchSeeSfx(Number.i, Array PatternBytes.a(1))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT tag, pattern_count, patterns_data FROM see_sfx WHERE sfx_number=" + Str(Number))
      If NextDatabaseRow(#DB)
        FetchedSeeSfxTag = GetDatabaseString(#DB, 0)
        FetchedSeeSfxPatternCount = Val(GetDatabaseString(#DB, 1))
        Protected HexData.s = GetDatabaseString(#DB, 2)

        If FetchedSeeSfxPatternCount > 0
          ReDim PatternBytes(FetchedSeeSfxPatternCount * 15 - 1)
          Protected i, b, Pos = 1
          For i = 0 To FetchedSeeSfxPatternCount - 1
            For b = 0 To 14
              PatternBytes(i * 15 + b) = Val("$" + Mid(HexData, Pos, 2))
              Pos + 2
            Next
          Next
        EndIf
        Found = #True
      EndIf
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure.i LastSeeSfxPatternCount()
    ProcedureReturn FetchedSeeSfxPatternCount
  EndProcedure

  Procedure.s LastSeeSfxTag()
    ProcedureReturn FetchedSeeSfxTag
  EndProcedure

  Procedure.i HasSeeSfx(Number.i)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf
    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT 1 FROM see_sfx WHERE sfx_number=" + Str(Number))
      Found = NextDatabaseRow(#DB)
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure ListSeeSfxNumbers(List Numbers.i())
    ClearList(Numbers())
    If Not EnsureOpen()
      ProcedureReturn
    EndIf

    If DatabaseQuery(#DB, "SELECT sfx_number FROM see_sfx ORDER BY sfx_number ASC")
      While NextDatabaseRow(#DB)
        AddElement(Numbers())
        Numbers() = Val(GetDatabaseString(#DB, 0))
      Wend
      FinishDatabaseQuery(#DB)
    EndIf
  EndProcedure

  ; Grava as linhas MML dos 3 canais (Lines(canal, indice), LineCount(canal)
  ; linhas validas por canal) como 3 colunas TEXT, cada uma com as linhas
  ; daquele canal unidas por Chr(10) (DELETE+INSERT, mesmo padrao dos demais).
  Procedure.i StoreSong(Number.i, Tag.s, Array Lines.s(2), Array LineCount.i(1))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected c, i
    Dim Joined.s(2)
    For c = 0 To 2
      Joined(c) = ""
      For i = 0 To LineCount(c) - 1
        If i > 0
          Joined(c) = Joined(c) + Chr(10)
        EndIf
        Joined(c) = Joined(c) + Lines(c, i)
      Next
      Joined(c) = ReplaceString(Joined(c), "'", "''")
    Next

    Protected SafeTag.s = Left(ReplaceString(Tag, "'", "''"), 16)

    DatabaseUpdate(#DB, "DELETE FROM mml_songs WHERE song_number=" + Str(Number))
    Protected SQL.s = "INSERT INTO mml_songs (song_number, tag, lines_a, lines_b, lines_c, updated_at) VALUES (" +
                       Str(Number) + ", '" + SafeTag + "', '" + Joined(0) + "', '" + Joined(1) + "', '" + Joined(2) +
                       "', datetime('now'))"
    ProcedureReturn DatabaseUpdate(#DB, SQL)
  EndProcedure

  ; Le de volta uma musica pra dentro de Lines()/LineCount() (arrays fixos,
  ; dimensionados pelo chamador - so preenche ate a capacidade, nunca
  ; redimensiona); tag extra via LastSongTag().
  Procedure.i FetchSong(Number.i, Array Lines.s(2), Array LineCount.i(1))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT tag, lines_a, lines_b, lines_c FROM mml_songs WHERE song_number=" + Str(Number))
      If NextDatabaseRow(#DB)
        FetchedSongTag = GetDatabaseString(#DB, 0)
        Protected c, p, Parts
        Protected RawText.s
        Protected MaxIdx = ArraySize(Lines(), 2)
        For c = 0 To 2
          RawText = GetDatabaseString(#DB, 1 + c)
          LineCount(c) = 0
          If RawText <> ""
            Parts = CountString(RawText, Chr(10)) + 1
            For p = 1 To Parts
              If LineCount(c) <= MaxIdx
                Lines(c, LineCount(c)) = StringField(RawText, p, Chr(10))
                LineCount(c) + 1
              EndIf
            Next
          EndIf
        Next
        Found = #True
      EndIf
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure.s LastSongTag()
    ProcedureReturn FetchedSongTag
  EndProcedure

  Procedure.i HasSong(Number.i)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT 1 FROM mml_songs WHERE song_number=" + Str(Number))
      Found = NextDatabaseRow(#DB)
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure ListSongNumbers(List Numbers.i())
    ClearList(Numbers())
    If Not EnsureOpen()
      ProcedureReturn
    EndIf

    If DatabaseQuery(#DB, "SELECT song_number FROM mml_songs ORDER BY song_number ASC")
      While NextDatabaseRow(#DB)
        AddElement(Numbers())
        Numbers() = Val(GetDatabaseString(#DB, 0))
      Wend
      FinishDatabaseQuery(#DB)
    EndIf
  EndProcedure

  ; CommandsText e um blob opaco (um comando por linha, ja serializado por
  ; Screen2EditorGui.pbi) - so escapa aspas simples pra SQL, igual
  ; StoreDocument() faz com Content; sem hex-encoding, sem conhecer a
  ; Structure Scr2_Command.
  Procedure.i StoreScreen(Number.i, Tag.s, CommandsText.s)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected SafeTag.s = Left(ReplaceString(Tag, "'", "''"), 16)
    Protected SafeCommands.s = ReplaceString(CommandsText, "'", "''")

    DatabaseUpdate(#DB, "DELETE FROM screens WHERE screen_number=" + Str(Number))
    Protected SQL.s = "INSERT INTO screens (screen_number, tag, commands_data, updated_at) VALUES (" +
                       Str(Number) + ", '" + SafeTag + "', '" + SafeCommands + "', datetime('now'))"
    ProcedureReturn DatabaseUpdate(#DB, SQL)
  EndProcedure

  ; Sem parametro de Array de saida (nao ha estrutura pra preencher aqui) -
  ; tag e texto dos comandos saem via LastScreenTag()/LastScreenCommandsText(),
  ; mesmo padrao "out-param" de FetchDocument()/FetchAlphabet().
  Procedure.i FetchScreen(Number.i)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT tag, commands_data FROM screens WHERE screen_number=" + Str(Number))
      If NextDatabaseRow(#DB)
        FetchedScreenTag = GetDatabaseString(#DB, 0)
        FetchedScreenCommandsText = GetDatabaseString(#DB, 1)
        Found = #True
      EndIf
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure.s LastScreenCommandsText()
    ProcedureReturn FetchedScreenCommandsText
  EndProcedure

  Procedure.s LastScreenTag()
    ProcedureReturn FetchedScreenTag
  EndProcedure

  Procedure.i HasScreen(Number.i)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT 1 FROM screens WHERE screen_number=" + Str(Number))
      Found = NextDatabaseRow(#DB)
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure ListScreenNumbers(List Numbers.i())
    ClearList(Numbers())
    If Not EnsureOpen()
      ProcedureReturn
    EndIf

    If DatabaseQuery(#DB, "SELECT screen_number FROM screens ORDER BY screen_number ASC")
      While NextDatabaseRow(#DB)
        AddElement(Numbers())
        Numbers() = Val(GetDatabaseString(#DB, 0))
      Wend
      FinishDatabaseQuery(#DB)
    EndIf
  EndProcedure

  ; --- Screen0EditorGui.pbi ("Criar -> Screen 0...") - grid de bytes de
  ; caractere (Width x 24), hex-codificado 2 digitos/byte igual a
  ; StoreAlphabet acima. Width/Ink/Paper/AlphabetNumber saem via getters
  ; "Last*" (mesmo padrao out-param de LastScreenTag/LastGridSize etc.).
  Procedure.i StoreScreen0(Number.i, Tag.s, Width.i, Ink.i, Paper.i, AlphabetNumber.i,
                           Ink2.i, Paper2.i, BlinkOn.i, BlinkOff.i, Array GridCodes.u(1), Array GridAttrs.a(1))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected SafeTag.s = Left(ReplaceString(Tag, "'", "''"), 16)
    Protected HexData.s = "", AttrHex.s = ""
    Protected Idx
    For Idx = 0 To Width * 24 - 1
      HexData = HexData + RSet(Hex(GridCodes(Idx)), 4, "0")
      AttrHex = AttrHex + RSet(Hex(GridAttrs(Idx)), 2, "0")
    Next

    DatabaseUpdate(#DB, "DELETE FROM screen0_screens WHERE screen0_number=" + Str(Number))
    Protected SQL.s = "INSERT INTO screen0_screens " +
                       "(screen0_number, tag, width, ink_color, paper_color, alphabet_number, grid_data, " +
                       "ink2_color, paper2_color, blink_on_period, blink_off_period, attr_data, updated_at) VALUES (" +
                       Str(Number) + ", '" + SafeTag + "', " + Str(Width) + ", " + Str(Ink) + ", " + Str(Paper) + ", " +
                       Str(AlphabetNumber) + ", '" + HexData + "', " +
                       Str(Ink2) + ", " + Str(Paper2) + ", " + Str(BlinkOn) + ", " + Str(BlinkOff) + ", " +
                       "'" + AttrHex + "', datetime('now'))"
    ProcedureReturn DatabaseUpdate(#DB, SQL)
  EndProcedure

  ; GridCodes/GridAttrs devem vir pre-alocados pelo chamador com pelo menos
  ; 80*24 elementos (a maior largura suportada) - mesmo padrao de FetchSprite
  ; acima (que assume Grid() ja alocado 16x16, o maior GridSize possivel,
  ; mesmo quando o sprite de verdade e 8x8): so os primeiros Width*24
  ; elementos sao preenchidos, o resto fica com o que ja estava la.
  Procedure.i FetchScreen0(Number.i, Array GridCodes.u(1), Array GridAttrs.a(1))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT tag, width, ink_color, paper_color, alphabet_number, grid_data, " +
                          "ink2_color, paper2_color, blink_on_period, blink_off_period, attr_data " +
                          "FROM screen0_screens WHERE screen0_number=" + Str(Number))
      If NextDatabaseRow(#DB)
        FetchedScreen0Tag = GetDatabaseString(#DB, 0)
        FetchedScreen0Width = Val(GetDatabaseString(#DB, 1))
        FetchedScreen0Ink = Val(GetDatabaseString(#DB, 2))
        FetchedScreen0Paper = Val(GetDatabaseString(#DB, 3))
        FetchedScreen0AlphabetNumber = Val(GetDatabaseString(#DB, 4))
        FetchedScreen0Ink2 = Val(GetDatabaseString(#DB, 6))
        FetchedScreen0Paper2 = Val(GetDatabaseString(#DB, 7))
        FetchedScreen0BlinkOn = Val(GetDatabaseString(#DB, 8))
        FetchedScreen0BlinkOff = Val(GetDatabaseString(#DB, 9))

        Protected HexData.s = GetDatabaseString(#DB, 5)
        Protected AttrHex.s = GetDatabaseString(#DB, 10)
        Protected Idx
        For Idx = 0 To FetchedScreen0Width * 24 - 1
          GridCodes(Idx) = Val("$" + Mid(HexData, Idx * 4 + 1, 4))
          If Idx * 2 + 2 <= Len(AttrHex)
            GridAttrs(Idx) = Val("$" + Mid(AttrHex, Idx * 2 + 1, 2))
          Else
            GridAttrs(Idx) = 0
          EndIf
        Next
        Found = #True
      EndIf
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure.s LastScreen0Tag()
    ProcedureReturn FetchedScreen0Tag
  EndProcedure

  Procedure.i LastScreen0Width()
    ProcedureReturn FetchedScreen0Width
  EndProcedure

  Procedure.i LastScreen0Ink()
    ProcedureReturn FetchedScreen0Ink
  EndProcedure

  Procedure.i LastScreen0Paper()
    ProcedureReturn FetchedScreen0Paper
  EndProcedure

  Procedure.i LastScreen0AlphabetNumber()
    ProcedureReturn FetchedScreen0AlphabetNumber
  EndProcedure

  Procedure.i LastScreen0Ink2()
    ProcedureReturn FetchedScreen0Ink2
  EndProcedure

  Procedure.i LastScreen0Paper2()
    ProcedureReturn FetchedScreen0Paper2
  EndProcedure

  Procedure.i LastScreen0BlinkOn()
    ProcedureReturn FetchedScreen0BlinkOn
  EndProcedure

  Procedure.i LastScreen0BlinkOff()
    ProcedureReturn FetchedScreen0BlinkOff
  EndProcedure

  Procedure.i HasScreen0(Number.i)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT 1 FROM screen0_screens WHERE screen0_number=" + Str(Number))
      Found = NextDatabaseRow(#DB)
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure ListScreen0Numbers(List Numbers.i())
    ClearList(Numbers())
    If Not EnsureOpen()
      ProcedureReturn
    EndIf

    If DatabaseQuery(#DB, "SELECT screen0_number FROM screen0_screens ORDER BY screen0_number ASC")
      While NextDatabaseRow(#DB)
        AddElement(Numbers())
        Numbers() = Val(GetDatabaseString(#DB, 0))
      Wend
      FinishDatabaseQuery(#DB)
    EndIf
  EndProcedure

  ; --- Screen1EditorGui.pbi ("Criar -> Screen 1...") - grade FIXA 32x24
  ; (768 celulas, sempre - SCREEN 1 do MSX nao tem largura configuravel como
  ; SCREEN 0) de bytes MSX crus 0-255 hex-codificados 2 digitos/celula (nao
  ; Unicode - ver comentario grande no topo de Screen1EditorGui.pbi pro
  ; porque disso ser diferente de screen0_screens). octet_data guarda os 32
  ; pares Tinta/Fundo (1 digito hex cada = 4 bits, mesma faixa 0-15 de
  ; qualquer cor MSX1) da Color Table real do SCREEN 1, 1 par por GRUPO de 8
  ; codigos de caractere (codigo\8), nao por posicao de tela - 64 digitos hex
  ; ao todo. Como este arquivo compila ANTES de Screen1EditorGui.pbi (ordem
  ; de XIncludeFile em BadigEditor.pb), os limites 768/32 sao literais aqui,
  ; nao constantes externas - mesmo motivo/padrao ja usado por StoreAlphabet/
  ; StoreGraphosScreen acima.
  Procedure.i StoreScreen1(Number.i, Tag.s, AlphabetNumber.i, Array GridBytes.a(1), Array OctetInk.a(1), Array OctetPaper.a(1))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected SafeTag.s = Left(ReplaceString(Tag, "'", "''"), 16)
    Protected GridHex.s = "", OctetHex.s = ""
    Protected Idx
    For Idx = 0 To 767
      GridHex + RSet(Hex(GridBytes(Idx)), 2, "0")
    Next
    For Idx = 0 To 31
      OctetHex + RSet(Hex(OctetInk(Idx) & $F), 1, "0") + RSet(Hex(OctetPaper(Idx) & $F), 1, "0")
    Next

    DatabaseUpdate(#DB, "DELETE FROM screen1_screens WHERE screen1_number=" + Str(Number))
    Protected SQL.s = "INSERT INTO screen1_screens (screen1_number, tag, alphabet_number, grid_data, octet_data, updated_at) VALUES (" +
                       Str(Number) + ", '" + SafeTag + "', " + Str(AlphabetNumber) + ", '" + GridHex + "', '" + OctetHex + "', datetime('now'))"
    ProcedureReturn DatabaseUpdate(#DB, SQL)
  EndProcedure

  Procedure.i FetchScreen1(Number.i, Array GridBytes.a(1), Array OctetInk.a(1), Array OctetPaper.a(1))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT tag, alphabet_number, grid_data, octet_data FROM screen1_screens WHERE screen1_number=" + Str(Number))
      If NextDatabaseRow(#DB)
        FetchedScreen1Tag = GetDatabaseString(#DB, 0)
        FetchedScreen1AlphabetNumber = Val(GetDatabaseString(#DB, 1))
        Protected GridHex.s = GetDatabaseString(#DB, 2)
        Protected OctetHex.s = GetDatabaseString(#DB, 3)
        Protected Idx
        For Idx = 0 To 767
          GridBytes(Idx) = Val("$" + Mid(GridHex, Idx * 2 + 1, 2))
        Next
        For Idx = 0 To 31
          OctetInk(Idx) = Val("$" + Mid(OctetHex, Idx * 2 + 1, 1))
          OctetPaper(Idx) = Val("$" + Mid(OctetHex, Idx * 2 + 2, 1))
        Next
        Found = #True
      EndIf
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure.s LastScreen1Tag()
    ProcedureReturn FetchedScreen1Tag
  EndProcedure

  Procedure.i LastScreen1AlphabetNumber()
    ProcedureReturn FetchedScreen1AlphabetNumber
  EndProcedure

  Procedure.i HasScreen1(Number.i)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf
    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT 1 FROM screen1_screens WHERE screen1_number=" + Str(Number))
      Found = NextDatabaseRow(#DB)
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure ListScreen1Numbers(List Numbers.i())
    ClearList(Numbers())
    If Not EnsureOpen()
      ProcedureReturn
    EndIf
    If DatabaseQuery(#DB, "SELECT screen1_number FROM screen1_screens ORDER BY screen1_number ASC")
      While NextDatabaseRow(#DB)
        AddElement(Numbers())
        Numbers() = Val(GetDatabaseString(#DB, 0))
      Wend
      FinishDatabaseQuery(#DB)
    EndIf
  EndProcedure

  ; --- Screen12EditorGui.pbi ("Criar -> Screen 1+2...") - mesma grade 32x24
  ; (768 celulas, literal aqui pelo mesmo motivo/padrao ja usado por
  ; StoreScreen1 acima) de screen1_screens, porem gerando SCREEN 2 de
  ; verdade: 3 alfabetos (1 por terco) e uma Color Table completa (3 tercos x
  ; 256 codigos x 8 linhas de scanline = 6144 entradas, literal 6144 aqui
  ; pelo mesmo motivo). color_data e' Terco (mais externo) -> Codigo ->
  ; Linha, 2 digitos hex/entrada (1 pra Tinta, 1 pra Fundo).
  Procedure.i StoreScreen12(Number.i, Tag.s, Array AlphaThirds.i(1), Array GridBytes.a(1), Array ColorInk.a(3), Array ColorPaper.a(3))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected SafeTag.s = Left(ReplaceString(Tag, "'", "''"), 16)
    Protected GridHex.s = "", ColorHex.s = ""
    Protected Idx, Th, Cd, Rw
    For Idx = 0 To 767
      GridHex + RSet(Hex(GridBytes(Idx)), 2, "0")
    Next
    For Th = 0 To 2
      For Cd = 0 To 255
        For Rw = 0 To 7
          ColorHex + RSet(Hex(ColorInk(Th, Cd, Rw) & $F), 1, "0") + RSet(Hex(ColorPaper(Th, Cd, Rw) & $F), 1, "0")
        Next
      Next
    Next

    DatabaseUpdate(#DB, "DELETE FROM screen12_screens WHERE screen12_number=" + Str(Number))
    Protected SQL.s = "INSERT INTO screen12_screens " +
                       "(screen12_number, tag, alphabet0, alphabet1, alphabet2, grid_data, color_data, updated_at) VALUES (" +
                       Str(Number) + ", '" + SafeTag + "', " + Str(AlphaThirds(0)) + ", " + Str(AlphaThirds(1)) + ", " + Str(AlphaThirds(2)) + ", " +
                       "'" + GridHex + "', '" + ColorHex + "', datetime('now'))"
    ProcedureReturn DatabaseUpdate(#DB, SQL)
  EndProcedure

  Procedure.i FetchScreen12(Number.i, Array AlphaThirds.i(1), Array GridBytes.a(1), Array ColorInk.a(3), Array ColorPaper.a(3))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT tag, alphabet0, alphabet1, alphabet2, grid_data, color_data FROM screen12_screens WHERE screen12_number=" + Str(Number))
      If NextDatabaseRow(#DB)
        FetchedScreen12Tag = GetDatabaseString(#DB, 0)
        AlphaThirds(0) = Val(GetDatabaseString(#DB, 1))
        AlphaThirds(1) = Val(GetDatabaseString(#DB, 2))
        AlphaThirds(2) = Val(GetDatabaseString(#DB, 3))
        Protected GridHex.s = GetDatabaseString(#DB, 4)
        Protected ColorHex.s = GetDatabaseString(#DB, 5)
        Protected Idx, Th, Cd, Rw, Pos
        For Idx = 0 To 767
          GridBytes(Idx) = Val("$" + Mid(GridHex, Idx * 2 + 1, 2))
        Next
        Pos = 0
        For Th = 0 To 2
          For Cd = 0 To 255
            For Rw = 0 To 7
              ColorInk(Th, Cd, Rw) = Val("$" + Mid(ColorHex, Pos * 2 + 1, 1))
              ColorPaper(Th, Cd, Rw) = Val("$" + Mid(ColorHex, Pos * 2 + 2, 1))
              Pos + 1
            Next
          Next
        Next
        Found = #True
      EndIf
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure.s LastScreen12Tag()
    ProcedureReturn FetchedScreen12Tag
  EndProcedure

  Procedure.i HasScreen12(Number.i)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf
    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT 1 FROM screen12_screens WHERE screen12_number=" + Str(Number))
      Found = NextDatabaseRow(#DB)
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure ListScreen12Numbers(List Numbers.i())
    ClearList(Numbers())
    If Not EnsureOpen()
      ProcedureReturn
    EndIf
    If DatabaseQuery(#DB, "SELECT screen12_number FROM screen12_screens ORDER BY screen12_number ASC")
      While NextDatabaseRow(#DB)
        AddElement(Numbers())
        Numbers() = Val(GetDatabaseString(#DB, 0))
      Wend
      FinishDatabaseQuery(#DB)
    EndIf
  EndProcedure

  ; --- Graphos III (modulo 14) - Telas/Layouts/Shapes, ver comentario grande
  ; na declaracao no topo do arquivo. Pattern: 1 bit por pixel (bit 7-Col do
  ; byte, mesma convencao de StoreAlphabet/CharEd_PackChar). Color: 1 byte
  ; por celula de 8 pixels, INK no nibble alto/PAPER no nibble baixo (layout
  ; logico da Color Table de verdade do TMS9918).

  Procedure.i StoreGraphosScreen(Number.i, Tag.s, Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf
    Protected Y, Cx, Bit, X, ByteVal.a
    Protected PatternHex.s = "", ColorHex.s = ""
    For Y = 0 To 191
      For Cx = 0 To 31
        ByteVal = 0
        For Bit = 0 To 7
          X = Cx * 8 + Bit
          If PatternBit(Y, X)
            ByteVal | (1 << (7 - Bit))
          EndIf
        Next
        PatternHex + RSet(Hex(ByteVal), 2, "0")
        ByteVal = ((RowFG(Y, Cx) & $F) << 4) | (RowBG(Y, Cx) & $F)
        ColorHex + RSet(Hex(ByteVal), 2, "0")
      Next
    Next

    Protected SafeTag.s = Left(ReplaceString(Tag, "'", "''"), 16)
    DatabaseUpdate(#DB, "DELETE FROM graphos_screens WHERE screen_number=" + Str(Number))
    Protected SQL.s = "INSERT INTO graphos_screens (screen_number, tag, pattern_data, color_data, updated_at) VALUES (" +
                       Str(Number) + ", '" + SafeTag + "', '" + PatternHex + "', '" + ColorHex + "', datetime('now'))"
    ProcedureReturn DatabaseUpdate(#DB, SQL)
  EndProcedure

  Procedure.i FetchGraphosScreen(Number.i, Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf
    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT tag, pattern_data, color_data FROM graphos_screens WHERE screen_number=" + Str(Number))
      If NextDatabaseRow(#DB)
        FetchedGraphosScreenTag = GetDatabaseString(#DB, 0)
        Protected PatternHex.s = GetDatabaseString(#DB, 1)
        Protected ColorHex.s = GetDatabaseString(#DB, 2)
        Protected Y, Cx, Bit, X, ByteVal.a, Idx = 0
        For Y = 0 To 191
          For Cx = 0 To 31
            ByteVal = Val("$" + Mid(PatternHex, Idx * 2 + 1, 2))
            For Bit = 0 To 7
              X = Cx * 8 + Bit
              If ByteVal & (1 << (7 - Bit))
                PatternBit(Y, X) = 1
              Else
                PatternBit(Y, X) = 0
              EndIf
            Next
            ByteVal = Val("$" + Mid(ColorHex, Idx * 2 + 1, 2))
            RowFG(Y, Cx) = (ByteVal >> 4) & $F
            RowBG(Y, Cx) = ByteVal & $F
            Idx + 1
          Next
        Next
        Found = #True
      EndIf
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure.s LastGraphosScreenTag()
    ProcedureReturn FetchedGraphosScreenTag
  EndProcedure

  Procedure.i HasGraphosScreen(Number.i)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf
    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT 1 FROM graphos_screens WHERE screen_number=" + Str(Number))
      Found = NextDatabaseRow(#DB)
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure ListGraphosScreenNumbers(List Numbers.i())
    ClearList(Numbers())
    If Not EnsureOpen()
      ProcedureReturn
    EndIf
    If DatabaseQuery(#DB, "SELECT screen_number FROM graphos_screens ORDER BY screen_number ASC")
      While NextDatabaseRow(#DB)
        AddElement(Numbers())
        Numbers() = Val(GetDatabaseString(#DB, 0))
      Wend
      FinishDatabaseQuery(#DB)
    EndIf
  EndProcedure

  ; LAYOUT: so o pixel (PatternBit) - sem cor nenhuma, equivalente ao .LAY
  ; do Graphos III original ("so o video sem atributos").
  Procedure.i StoreGraphosLayout(Number.i, Tag.s, Array PatternBit.a(2))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf
    Protected Y, Cx, Bit, X, ByteVal.a
    Protected PatternHex.s = ""
    For Y = 0 To 191
      For Cx = 0 To 31
        ByteVal = 0
        For Bit = 0 To 7
          X = Cx * 8 + Bit
          If PatternBit(Y, X)
            ByteVal | (1 << (7 - Bit))
          EndIf
        Next
        PatternHex + RSet(Hex(ByteVal), 2, "0")
      Next
    Next

    Protected SafeTag.s = Left(ReplaceString(Tag, "'", "''"), 16)
    DatabaseUpdate(#DB, "DELETE FROM graphos_layouts WHERE layout_number=" + Str(Number))
    Protected SQL.s = "INSERT INTO graphos_layouts (layout_number, tag, pattern_data, updated_at) VALUES (" +
                       Str(Number) + ", '" + SafeTag + "', '" + PatternHex + "', datetime('now'))"
    ProcedureReturn DatabaseUpdate(#DB, SQL)
  EndProcedure

  Procedure.i FetchGraphosLayout(Number.i, Array PatternBit.a(2))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf
    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT tag, pattern_data FROM graphos_layouts WHERE layout_number=" + Str(Number))
      If NextDatabaseRow(#DB)
        FetchedGraphosLayoutTag = GetDatabaseString(#DB, 0)
        Protected PatternHex.s = GetDatabaseString(#DB, 1)
        Protected Y, Cx, Bit, X, ByteVal.a, Idx = 0
        For Y = 0 To 191
          For Cx = 0 To 31
            ByteVal = Val("$" + Mid(PatternHex, Idx * 2 + 1, 2))
            For Bit = 0 To 7
              X = Cx * 8 + Bit
              If ByteVal & (1 << (7 - Bit))
                PatternBit(Y, X) = 1
              Else
                PatternBit(Y, X) = 0
              EndIf
            Next
            Idx + 1
          Next
        Next
        Found = #True
      EndIf
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure.s LastGraphosLayoutTag()
    ProcedureReturn FetchedGraphosLayoutTag
  EndProcedure

  Procedure.i HasGraphosLayout(Number.i)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf
    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT 1 FROM graphos_layouts WHERE layout_number=" + Str(Number))
      Found = NextDatabaseRow(#DB)
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure ListGraphosLayoutNumbers(List Numbers.i())
    ClearList(Numbers())
    If Not EnsureOpen()
      ProcedureReturn
    EndIf
    If DatabaseQuery(#DB, "SELECT layout_number FROM graphos_layouts ORDER BY layout_number ASC")
      While NextDatabaseRow(#DB)
        AddElement(Numbers())
        Numbers() = Val(GetDatabaseString(#DB, 0))
      Wend
      FinishDatabaseQuery(#DB)
    EndIf
  EndProcedure

  ; SHAPE: recorte retangular de tamanho VARIAVEL (Width/Height proprios,
  ; diferente de Tela/Layout que sao sempre 256x192) - PatternBit()/RowFG()/
  ; RowBG() do chamador continuam dimensionados no tamanho MAXIMO do canvas;
  ; so a sub-regiao [0..Height-1, 0..Width-1] e' lida/escrita.
  Procedure.i StoreGraphosShape(Number.i, Tag.s, Width.i, Height.i, Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf
    Protected ColsW = (Width + 7) / 8
    Protected Y, Cx, Bit, X, ByteVal.a
    Protected PatternHex.s = "", ColorHex.s = ""
    For Y = 0 To Height - 1
      For Cx = 0 To ColsW - 1
        ByteVal = 0
        For Bit = 0 To 7
          X = Cx * 8 + Bit
          If X < Width And PatternBit(Y, X)
            ByteVal | (1 << (7 - Bit))
          EndIf
        Next
        PatternHex + RSet(Hex(ByteVal), 2, "0")
        ByteVal = ((RowFG(Y, Cx) & $F) << 4) | (RowBG(Y, Cx) & $F)
        ColorHex + RSet(Hex(ByteVal), 2, "0")
      Next
    Next

    Protected SafeTag.s = Left(ReplaceString(Tag, "'", "''"), 16)
    DatabaseUpdate(#DB, "DELETE FROM graphos_shapes WHERE shape_number=" + Str(Number))
    Protected SQL.s = "INSERT INTO graphos_shapes (shape_number, tag, width, height, pattern_data, color_data, updated_at) VALUES (" +
                       Str(Number) + ", '" + SafeTag + "', " + Str(Width) + ", " + Str(Height) + ", '" + PatternHex + "', '" + ColorHex + "', datetime('now'))"
    ProcedureReturn DatabaseUpdate(#DB, SQL)
  EndProcedure

  Procedure.i FetchGraphosShape(Number.i, Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2))
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf
    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT tag, width, height, pattern_data, color_data FROM graphos_shapes WHERE shape_number=" + Str(Number))
      If NextDatabaseRow(#DB)
        FetchedGraphosShapeTag = GetDatabaseString(#DB, 0)
        FetchedGraphosShapeWidth = Val(GetDatabaseString(#DB, 1))
        FetchedGraphosShapeHeight = Val(GetDatabaseString(#DB, 2))
        Protected PatternHex.s = GetDatabaseString(#DB, 3)
        Protected ColorHex.s = GetDatabaseString(#DB, 4)
        Protected ColsW = (FetchedGraphosShapeWidth + 7) / 8
        Protected Y, Cx, Bit, X, ByteVal.a, Idx = 0
        For Y = 0 To FetchedGraphosShapeHeight - 1
          For Cx = 0 To ColsW - 1
            ByteVal = Val("$" + Mid(PatternHex, Idx * 2 + 1, 2))
            For Bit = 0 To 7
              X = Cx * 8 + Bit
              If X < FetchedGraphosShapeWidth
                If ByteVal & (1 << (7 - Bit))
                  PatternBit(Y, X) = 1
                Else
                  PatternBit(Y, X) = 0
                EndIf
              EndIf
            Next
            ByteVal = Val("$" + Mid(ColorHex, Idx * 2 + 1, 2))
            RowFG(Y, Cx) = (ByteVal >> 4) & $F
            RowBG(Y, Cx) = ByteVal & $F
            Idx + 1
          Next
        Next
        Found = #True
      EndIf
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure.s LastGraphosShapeTag()
    ProcedureReturn FetchedGraphosShapeTag
  EndProcedure

  Procedure.i LastGraphosShapeWidth()
    ProcedureReturn FetchedGraphosShapeWidth
  EndProcedure

  Procedure.i LastGraphosShapeHeight()
    ProcedureReturn FetchedGraphosShapeHeight
  EndProcedure

  Procedure.i HasGraphosShape(Number.i)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf
    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT 1 FROM graphos_shapes WHERE shape_number=" + Str(Number))
      Found = NextDatabaseRow(#DB)
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure ListGraphosShapeNumbers(List Numbers.i())
    ClearList(Numbers())
    If Not EnsureOpen()
      ProcedureReturn
    EndIf
    If DatabaseQuery(#DB, "SELECT shape_number FROM graphos_shapes ORDER BY shape_number ASC")
      While NextDatabaseRow(#DB)
        AddElement(Numbers())
        Numbers() = Val(GetDatabaseString(#DB, 0))
      Wend
      FinishDatabaseQuery(#DB)
    EndIf
  EndProcedure

  ; Grava (DELETE+INSERT, mesmo padrao dos demais Store*) o metadado da
  ; ultima exportacao de binario do assembler pra SourceKey - ver comentario
  ; da declaracao acima pro que cada campo significa.
  Procedure.i StoreAsmBuild(SourceKey.s, BuildKind.s, OutputKind.s, OutputPath.s, StartAddr.u, EndAddr.u, BLoadHeader.i)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected SafeKey.s = ReplaceString(SourceKey, "'", "''")
    Protected SafeKind.s = ReplaceString(BuildKind, "'", "''")
    Protected SafeOutKind.s = ReplaceString(OutputKind, "'", "''")
    Protected SafeOutPath.s = ReplaceString(OutputPath, "'", "''")

    DatabaseUpdate(#DB, "DELETE FROM asm_builds WHERE source_key='" + SafeKey + "'")
    Protected SQL.s = "INSERT INTO asm_builds (source_key, build_kind, output_kind, output_path, start_addr, end_addr, bload_header, updated_at) VALUES (" +
                       "'" + SafeKey + "', '" + SafeKind + "', '" + SafeOutKind + "', '" + SafeOutPath + "', " +
                       Str(StartAddr) + ", " + Str(EndAddr) + ", " + Str(Bool(BLoadHeader)) + ", datetime('now'))"
    ProcedureReturn DatabaseUpdate(#DB, SQL)
  EndProcedure

  ; Le de volta o metadado de build pra SourceKey; campos extras via
  ; LastAsmBuildKind()/LastAsmBuildOutputKind()/LastAsmBuildOutputPath()/
  ; LastAsmBuildStartAddr()/LastAsmBuildEndAddr()/LastAsmBuildBLoadHeader()
  ; (mesmo padrao de FetchSound/LastSoundTag()).
  Procedure.i FetchAsmBuild(SourceKey.s)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected SafeKey.s = ReplaceString(SourceKey, "'", "''")
    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT build_kind, output_kind, output_path, start_addr, end_addr, bload_header " +
                          "FROM asm_builds WHERE source_key='" + SafeKey + "'")
      If NextDatabaseRow(#DB)
        FetchedAsmBuildKind = GetDatabaseString(#DB, 0)
        FetchedAsmBuildOutputKind = GetDatabaseString(#DB, 1)
        FetchedAsmBuildOutputPath = GetDatabaseString(#DB, 2)
        FetchedAsmBuildStartAddr = Val(GetDatabaseString(#DB, 3))
        FetchedAsmBuildEndAddr = Val(GetDatabaseString(#DB, 4))
        FetchedAsmBuildBLoadHeader = Val(GetDatabaseString(#DB, 5))
        Found = #True
      EndIf
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure.s LastAsmBuildKind()
    ProcedureReturn FetchedAsmBuildKind
  EndProcedure

  Procedure.s LastAsmBuildOutputKind()
    ProcedureReturn FetchedAsmBuildOutputKind
  EndProcedure

  Procedure.s LastAsmBuildOutputPath()
    ProcedureReturn FetchedAsmBuildOutputPath
  EndProcedure

  Procedure.u LastAsmBuildStartAddr()
    ProcedureReturn FetchedAsmBuildStartAddr
  EndProcedure

  Procedure.u LastAsmBuildEndAddr()
    ProcedureReturn FetchedAsmBuildEndAddr
  EndProcedure

  Procedure.i LastAsmBuildBLoadHeader()
    ProcedureReturn FetchedAsmBuildBLoadHeader
  EndProcedure

  Procedure.i HasAsmBuild(SourceKey.s)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected SafeKey.s = ReplaceString(SourceKey, "'", "''")
    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT 1 FROM asm_builds WHERE source_key='" + SafeKey + "'")
      Found = NextDatabaseRow(#DB)
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure ListAsmBuildKeys(List Keys.s())
    ClearList(Keys())
    If Not EnsureOpen()
      ProcedureReturn
    EndIf

    If DatabaseQuery(#DB, "SELECT source_key FROM asm_builds ORDER BY updated_at DESC")
      While NextDatabaseRow(#DB)
        AddElement(Keys())
        Keys() = GetDatabaseString(#DB, 0)
      Wend
      FinishDatabaseQuery(#DB)
    EndIf
  EndProcedure

  ; Grava (DELETE+INSERT, mesmo padrao dos demais Store*) as listas de .asm/
  ; .lib do subprojeto Number, unindo cada lista por Chr(10) na ordem dada
  ; (mesmo padrao de StoreSong\lines_a/b/c).
  Procedure.i StoreAsmSubProject(Number.i, Tag.s, List AsmFiles.s(), List LibFiles.s())
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected Joined1.s = "", Joined2.s = ""
    ForEach AsmFiles()
      If Joined1 <> ""
        Joined1 + Chr(10)
      EndIf
      Joined1 + AsmFiles()
    Next
    ForEach LibFiles()
      If Joined2 <> ""
        Joined2 + Chr(10)
      EndIf
      Joined2 + LibFiles()
    Next
    Joined1 = ReplaceString(Joined1, "'", "''")
    Joined2 = ReplaceString(Joined2, "'", "''")
    Protected SafeTag.s = Left(ReplaceString(Tag, "'", "''"), 16)

    DatabaseUpdate(#DB, "DELETE FROM asm_subprojects WHERE subproject_number=" + Str(Number))
    Protected SQL.s = "INSERT INTO asm_subprojects (subproject_number, tag, asm_files, lib_files, updated_at) VALUES (" +
                       Str(Number) + ", '" + SafeTag + "', '" + Joined1 + "', '" + Joined2 + "', datetime('now'))"
    ProcedureReturn DatabaseUpdate(#DB, SQL)
  EndProcedure

  ; Le de volta as listas de .asm/.lib do subprojeto Number pra dentro de
  ; AsmFiles()/LibFiles() (limpas primeiro); tag extra via
  ; LastAsmSubProjectTag() (mesmo padrao de FetchSong/LastSongTag()).
  Procedure.i FetchAsmSubProject(Number.i, List AsmFiles.s(), List LibFiles.s())
    ClearList(AsmFiles())
    ClearList(LibFiles())
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT tag, asm_files, lib_files FROM asm_subprojects WHERE subproject_number=" + Str(Number))
      If NextDatabaseRow(#DB)
        FetchedSubProjTag = GetDatabaseString(#DB, 0)
        Protected RawAsm.s = GetDatabaseString(#DB, 1)
        Protected RawLib.s = GetDatabaseString(#DB, 2)
        Protected i, n
        If RawAsm <> ""
          n = CountString(RawAsm, Chr(10)) + 1
          For i = 1 To n
            AddElement(AsmFiles())
            AsmFiles() = StringField(RawAsm, i, Chr(10))
          Next
        EndIf
        If RawLib <> ""
          n = CountString(RawLib, Chr(10)) + 1
          For i = 1 To n
            AddElement(LibFiles())
            LibFiles() = StringField(RawLib, i, Chr(10))
          Next
        EndIf
        Found = #True
      EndIf
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure.s LastAsmSubProjectTag()
    ProcedureReturn FetchedSubProjTag
  EndProcedure

  Procedure.i HasAsmSubProject(Number.i)
    If Not EnsureOpen()
      ProcedureReturn #False
    EndIf

    Protected Found.b = #False
    If DatabaseQuery(#DB, "SELECT 1 FROM asm_subprojects WHERE subproject_number=" + Str(Number))
      Found = NextDatabaseRow(#DB)
      FinishDatabaseQuery(#DB)
    EndIf
    ProcedureReturn Found
  EndProcedure

  Procedure ListAsmSubProjectNumbers(List Numbers.i())
    ClearList(Numbers())
    If Not EnsureOpen()
      ProcedureReturn
    EndIf

    If DatabaseQuery(#DB, "SELECT subproject_number FROM asm_subprojects ORDER BY subproject_number ASC")
      While NextDatabaseRow(#DB)
        AddElement(Numbers())
        Numbers() = Val(GetDatabaseString(#DB, 0))
      Wend
      FinishDatabaseQuery(#DB)
    EndIf
  EndProcedure

  ; Abre (uma unica vez por sessao) o banco SQLite ":memory:" do "projeto 0"
  ; e semeia o alfabeto 0 com o charset padrao do MSX embutido no executavel
  ; (FillDefaultMsxCharset(), de DefaultCharsetMsx.pbi) - nunca toca em
  ; disco, nunca e salvo, nao interfere no projeto ativo (#DB e #DefaultsDB
  ; sao conexoes separadas).
  Procedure.i EnsureDefaultsOpen()
    If DefaultsOpen
      ProcedureReturn #True
    EndIf

    If Not OpenDatabase(#DefaultsDB, ":memory:", "", "")
      LastError = "Nao foi possivel abrir o projeto de defaults em memoria."
      ProcedureReturn #False
    EndIf

    DatabaseUpdate(#DefaultsDB, "CREATE TABLE IF NOT EXISTS alphabets (" +
                                 "alphabet_number INTEGER PRIMARY KEY, " +
                                 "tag TEXT, " +
                                 "charset_data TEXT NOT NULL, " +
                                 "updated_at TEXT)")

    Dim SeedBytes.a(255, 7)
    FillDefaultMsxCharset(SeedBytes())
    StoreAlphabetInto(#DefaultsDB, 0, "msx", SeedBytes())

    DefaultsOpen = #True
    ProcedureReturn #True
  EndProcedure

  Procedure.i FetchDefaultAlphabet(Number.i, Array CharsetBytes.a(2))
    If Not EnsureDefaultsOpen()
      ProcedureReturn #False
    EndIf
    ProcedureReturn FetchAlphabetFrom(#DefaultsDB, Number, CharsetBytes())
  EndProcedure

  Procedure.s GetLastError()
    If DatabaseError() <> ""
      ProcedureReturn DatabaseError()
    EndIf
    ProcedureReturn LastError
  EndProcedure
EndModule
