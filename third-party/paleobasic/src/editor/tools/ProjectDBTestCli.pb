;
; ------------------------------------------------------------
;  Ferramenta de linha de comando para testar o modulo de projeto MSX
;  (editor\ProjectDB.pbi) sem precisar abrir o editor nem simular cliques
;  de mouse num canvas (automacao de canvas se mostrou nao-confiavel neste
;  ambiente - ver conversas anteriores sobre o editor de sprites).
;
;  Roda um round-trip completo contra um projeto SQLite descartavel: cria o
;  projeto temporario implicito, registra sprites de tamanhos/modos
;  diferentes, lista os numeros, recarrega e compara byte a byte, sobrescreve
;  um sprite existente (confirma que nao duplica), promove o projeto pra um
;  arquivo permanente (SaveAs) e confirma que os dados continuam la.
;
;  Uso:
;    ProjectDBTestCli.exe <pasta_de_trabalho>
;      <pasta_de_trabalho>  pasta onde o projeto salvo (SaveAs) sera criado
;                           (apagada e recriada a cada execucao)
;
;  Compilar com:
;    "C:\Basic\Compilers\pbcompiler.exe" editor\tools\ProjectDBTestCli.pb /EXE editor\tools\ProjectDBTestCli.exe /CONSOLE
; ------------------------------------------------------------
;

EnableExplicit
OpenConsole()

XIncludeFile "..\core\ProjectDB.pbi"

Define WorkDir.s = ProgramParameter(0)
If WorkDir = ""
  PrintN("Uso: ProjectDBTestCli.exe <pasta_de_trabalho>")
  End 1
EndIf
If Right(WorkDir, 1) <> "\" And Right(WorkDir, 1) <> "/"
  WorkDir + "\"
EndIf
If FileSize(WorkDir) <> -2
  CreateDirectory(WorkDir)
EndIf

Define Failures = 0

Procedure CheckTrue(Ok.i, Label.s)
  Shared Failures
  If Ok
    PrintN("OK    - " + Label)
  Else
    PrintN("FALHA - " + Label + " -> " + ProjectDB::GetLastError())
    Failures + 1
  EndIf
EndProcedure

; Preenche Grid com um padrao determinístico e facil de comparar depois
; (cada bloco = (Row*GridSize+Col) mod 16, cobre todos os indices 0-15).
Procedure FillPattern(Array Grid.b(2), GridSize.i)
  Protected Row, Col
  For Row = 0 To GridSize - 1
    For Col = 0 To GridSize - 1
      Grid(Row, Col) = (Row * GridSize + Col) % 16
    Next
  Next
EndProcedure

Procedure.i GridsMatch(Array A.b(2), Array B.b(2), GridSize.i)
  Protected Row, Col
  For Row = 0 To GridSize - 1
    For Col = 0 To GridSize - 1
      If A(Row, Col) <> B(Row, Col)
        ProcedureReturn #False
      EndIf
    Next
  Next
  ProcedureReturn #True
EndProcedure

; 1) EnsureOpen cria o projeto temporario implicito ("noname")
CheckTrue(ProjectDB::EnsureOpen(), "EnsureOpen (projeto temporario implicito)")
CheckTrue(ProjectDB::IsTemp(), "IsTemp() = #True logo apos EnsureOpen")

; 2) Salva 3 sprites de tamanhos/modos diferentes
Dim GridA.b(15, 15) : FillPattern(GridA(), 16)
Dim GridB.b(15, 15) : FillPattern(GridB(), 8)
Dim GridC.b(15, 15) : FillPattern(GridC(), 16)

CheckTrue(ProjectDB::StoreSprite(1, "heroi", 16, 1, GridA()), "SaveSprite #1 (16x16, MSX1, tag 'heroi')")
CheckTrue(ProjectDB::StoreSprite(2, "bala", 8, 2, GridB()), "SaveSprite #2 (8x8, MSX2, tag 'bala')")
CheckTrue(ProjectDB::StoreSprite(3, "", 16, 1, GridC()), "SaveSprite #3 (16x16, MSX1, sem tag)")

; 3) ListSpriteNumbers - espera [1,2,3]
NewList Numbers.i()
ProjectDB::ListSpriteNumbers(Numbers())
CheckTrue(Bool(ListSize(Numbers()) = 3), "ListSpriteNumbers (esperado 3, achou " + Str(ListSize(Numbers())) + ")")
Define OrderOk.i = #True
If ListSize(Numbers()) = 3
  SelectElement(Numbers(), 0) : If Numbers() <> 1 : OrderOk = #False : EndIf
  SelectElement(Numbers(), 1) : If Numbers() <> 2 : OrderOk = #False : EndIf
  SelectElement(Numbers(), 2) : If Numbers() <> 3 : OrderOk = #False : EndIf
EndIf
CheckTrue(OrderOk, "ListSpriteNumbers em ordem crescente [1,2,3]")

; 4) LoadSprite #1 - confere grade, tag, tamanho e modo
Dim LoadedA.b(15, 15)
Define Loaded1.i = ProjectDB::FetchSprite(1, LoadedA())
CheckTrue(Loaded1, "LoadSprite #1")
CheckTrue(Bool(ProjectDB::LastGridSize() = 16), "Sprite #1: grid_size = 16 (achou " + Str(ProjectDB::LastGridSize()) + ")")
CheckTrue(Bool(ProjectDB::LastSpriteMode() = 1), "Sprite #1: sprite_mode = 1/MSX1 (achou " + Str(ProjectDB::LastSpriteMode()) + ")")
CheckTrue(Bool(ProjectDB::LastTag() = "heroi"), "Sprite #1: tag = 'heroi' (achou '" + ProjectDB::LastTag() + "')")
CheckTrue(GridsMatch(GridA(), LoadedA(), 16), "Sprite #1: grade recarregada bate byte a byte com a original")

; 5) LoadSprite #2 (8x8/MSX2) - mesmo round-trip com outro tamanho/modo
Dim LoadedB.b(15, 15)
Define Loaded2.i = ProjectDB::FetchSprite(2, LoadedB())
CheckTrue(Loaded2, "LoadSprite #2")
CheckTrue(Bool(ProjectDB::LastGridSize() = 8), "Sprite #2: grid_size = 8 (achou " + Str(ProjectDB::LastGridSize()) + ")")
CheckTrue(Bool(ProjectDB::LastSpriteMode() = 2), "Sprite #2: sprite_mode = 2/MSX2 (achou " + Str(ProjectDB::LastSpriteMode()) + ")")
CheckTrue(GridsMatch(GridB(), LoadedB(), 8), "Sprite #2: grade recarregada bate byte a byte com a original")

; 6) Sobrescreve o sprite #1 (tag e cor diferentes) - nao pode duplicar
Dim GridA2.b(15, 15)
Define Row, Col
For Row = 0 To 15 : For Col = 0 To 15 : GridA2(Row, Col) = 5 : Next : Next
CheckTrue(ProjectDB::StoreSprite(1, "heroi2", 16, 2, GridA2()), "SaveSprite #1 de novo (sobrescrevendo tag/modo)")
ClearList(Numbers())
ProjectDB::ListSpriteNumbers(Numbers())
CheckTrue(Bool(ListSize(Numbers()) = 3), "Ainda 3 sprites apos sobrescrever #1 (nao duplicou)")
Dim ReloadedA.b(15, 15)
ProjectDB::FetchSprite(1, ReloadedA())
CheckTrue(Bool(ProjectDB::LastTag() = "heroi2"), "Sprite #1: tag atualizada para 'heroi2'")
CheckTrue(Bool(ProjectDB::LastSpriteMode() = 2), "Sprite #1: sprite_mode atualizado para 2/MSX2")

; 7) SpriteExists
CheckTrue(ProjectDB::HasSprite(2), "SpriteExists(2) = #True")
CheckTrue(Bool(Not ProjectDB::HasSprite(99)), "SpriteExists(99) = #False")

; 8) HasUnsavedContent - projeto ainda e temporario e ja tem sprites
CheckTrue(ProjectDB::HasUnsavedContent(), "HasUnsavedContent() = #True (temporario com sprites)")

; 8b) Diretorio de trabalho (project_info) - round trip simples
ProjectDB::SetWorkingDir("C:\meu\projeto")
CheckTrue(Bool(ProjectDB::GetWorkingDir() = "C:\meu\projeto"), "GetWorkingDir() bate com SetWorkingDir()")

; 8c) StoreDocument/FetchDocument - copia do conteudo das abas de texto,
; guardada junto com o projeto a cada "Salvar"/"Salvar como" de uma aba
; (ver SaveDocument() em BadigEditor.pb).
Define DocPath1.s = WorkDir + "fonte1.dmx"
Define DocContent1.s = "label inicio:" + Chr(10) + "print " + Chr(34) + "ola" + Chr(34) + Chr(10)
CheckTrue(ProjectDB::StoreDocument(DocPath1, "DMX", DocContent1), "StoreDocument(fonte1.dmx)")
CheckTrue(ProjectDB::FetchDocument(DocPath1), "FetchDocument(fonte1.dmx)")
CheckTrue(Bool(ProjectDB::LastDocumentContent() = DocContent1), "Documento: conteudo bate com o salvo")
CheckTrue(Bool(ProjectDB::LastDocumentMode() = "DMX"), "Documento: modo = DMX")

; Salvar a mesma aba de novo (edicao) tem que atualizar, nao duplicar
Define DocContent1b.s = DocContent1 + "' mais uma linha"
CheckTrue(ProjectDB::StoreDocument(DocPath1, "DMX", DocContent1b), "StoreDocument(fonte1.dmx) de novo (edicao)")
ProjectDB::FetchDocument(DocPath1)
CheckTrue(Bool(ProjectDB::LastDocumentContent() = DocContent1b), "Documento: conteudo atualizado apos segunda gravacao")

; Conteudo com aspas simples tem que sobreviver ao escape da query SQL
Define DocPath2.s = WorkDir + "fonte2.asm"
Define DocContent2.s = "; it's a test" + Chr(10) + "ld a,'x'" + Chr(10)
CheckTrue(ProjectDB::StoreDocument(DocPath2, "ASM", DocContent2), "StoreDocument(fonte2.asm) com aspas simples no conteudo")
ProjectDB::FetchDocument(DocPath2)
CheckTrue(Bool(ProjectDB::LastDocumentContent() = DocContent2), "Documento: aspas simples preservadas (escape correto)")

; 8c-ii) ListDocumentPaths/DeleteDocument - usados por ResyncProjectDocumentsFromDisk()/
; RestoreMissingDocumentsToDisk() (BadigEditor.pb, pedido do usuario de
; 2026-08-10: levar o .msxproject de uma maquina pra outra com os fontes).
NewList ListedPaths.s()
ProjectDB::ListDocumentPaths(ListedPaths())
CheckTrue(Bool(ListSize(ListedPaths()) = 2), "ListDocumentPaths() lista os 2 documentos guardados")
Define FoundPath1.b = #False, FoundPath2.b = #False
ForEach ListedPaths()
  If ListedPaths() = DocPath1 : FoundPath1 = #True : EndIf
  If ListedPaths() = DocPath2 : FoundPath2 = #True : EndIf
Next
CheckTrue(FoundPath1, "ListDocumentPaths() inclui fonte1.dmx")
CheckTrue(FoundPath2, "ListDocumentPaths() inclui fonte2.asm")

ProjectDB::DeleteDocument(DocPath1)
CheckTrue(Bool(ProjectDB::FetchDocument(DocPath1) = #False), "DeleteDocument(fonte1.dmx) remove a linha (FetchDocument falha depois)")
ProjectDB::ListDocumentPaths(ListedPaths())
CheckTrue(Bool(ListSize(ListedPaths()) = 1), "ListDocumentPaths() reflete a remocao (so fonte2.asm sobra)")
; devolve fonte1.dmx pro estado esperado pelos testes de SaveAs/OpenExisting mais abaixo
CheckTrue(ProjectDB::StoreDocument(DocPath1, "DMX", DocContent1b), "StoreDocument(fonte1.dmx) restaurado apos teste de DeleteDocument")

; 8d) StoreAlphabet/FetchAlphabet - alfabetos (charset 256x8) do projeto,
; mesmo padrao Store/Fetch/List dos sprites.
Procedure FillAlphaPattern(Array CharsetBytes.a(2), Seed.i)
  Protected Row, Col
  For Row = 0 To 255
    For Col = 0 To 7
      CharsetBytes(Row, Col) = (Row * 8 + Col + Seed) % 256
    Next
  Next
EndProcedure

Procedure.i AlphaBytesMatch(Array A.a(2), Array B.a(2))
  Protected Row, Col
  For Row = 0 To 255
    For Col = 0 To 7
      If A(Row, Col) <> B(Row, Col)
        ProcedureReturn #False
      EndIf
    Next
  Next
  ProcedureReturn #True
EndProcedure

Dim AlphaA.a(255, 7) : FillAlphaPattern(AlphaA(), 0)
Dim AlphaB.a(255, 7) : FillAlphaPattern(AlphaB(), 37)

CheckTrue(ProjectDB::StoreAlphabet(1, "fonte1", AlphaA()), "StoreAlphabet #1 (tag 'fonte1')")
CheckTrue(ProjectDB::StoreAlphabet(2, "fonte2", AlphaB()), "StoreAlphabet #2 (tag 'fonte2')")

NewList AlphaNumbers.i()
ProjectDB::ListAlphabetNumbers(AlphaNumbers())
CheckTrue(Bool(ListSize(AlphaNumbers()) = 2), "ListAlphabetNumbers (esperado 2, achou " + Str(ListSize(AlphaNumbers())) + ")")

Dim LoadedAlphaA.a(255, 7)
CheckTrue(ProjectDB::FetchAlphabet(1, LoadedAlphaA()), "FetchAlphabet #1")
CheckTrue(Bool(ProjectDB::LastAlphabetTag() = "fonte1"), "Alfabeto #1: tag = 'fonte1'")
CheckTrue(AlphaBytesMatch(AlphaA(), LoadedAlphaA()), "Alfabeto #1: 2048 bytes batem com o original")

; Sobrescreve o alfabeto #1 (tag diferente) - nao pode duplicar
CheckTrue(ProjectDB::StoreAlphabet(1, "fonte1b", AlphaB()), "StoreAlphabet #1 de novo (sobrescrevendo tag/dados)")
ClearList(AlphaNumbers())
ProjectDB::ListAlphabetNumbers(AlphaNumbers())
CheckTrue(Bool(ListSize(AlphaNumbers()) = 2), "Ainda 2 alfabetos apos sobrescrever #1 (nao duplicou)")
ProjectDB::FetchAlphabet(1, LoadedAlphaA())
CheckTrue(Bool(ProjectDB::LastAlphabetTag() = "fonte1b"), "Alfabeto #1: tag atualizada para 'fonte1b'")
CheckTrue(AlphaBytesMatch(AlphaB(), LoadedAlphaA()), "Alfabeto #1: dados atualizados apos sobrescrever")

CheckTrue(ProjectDB::HasAlphabet(2), "HasAlphabet(2) = #True")
CheckTrue(Bool(Not ProjectDB::HasAlphabet(99)), "HasAlphabet(99) = #False")

; screens (editor grafico SCREEN 2, modulo 5) - commands_data e um blob de
; texto opaco pro ProjectDB (Screen2EditorGui.pbi que serializa/desserializa
; a lista de comandos) - aqui so testa que o texto vai e volta intacto.
Define ScreenCmdsA.s = "PSET|5|5|8" + Chr(10) + "LINE|0|0|20|0|3|0"
Define ScreenCmdsB.s = "DRAW|60|60|2|U5R5"

CheckTrue(ProjectDB::StoreScreen(1, "tela1", ScreenCmdsA), "StoreScreen #1 (tag 'tela1')")
CheckTrue(ProjectDB::StoreScreen(2, "tela2", ScreenCmdsB), "StoreScreen #2 (tag 'tela2')")

NewList ScreenNumbers.i()
ProjectDB::ListScreenNumbers(ScreenNumbers())
CheckTrue(Bool(ListSize(ScreenNumbers()) = 2), "ListScreenNumbers (esperado 2, achou " + Str(ListSize(ScreenNumbers())) + ")")

CheckTrue(ProjectDB::FetchScreen(1), "FetchScreen #1")
CheckTrue(Bool(ProjectDB::LastScreenTag() = "tela1"), "Tela #1: tag = 'tela1'")
CheckTrue(Bool(ProjectDB::LastScreenCommandsText() = ScreenCmdsA), "Tela #1: comandos batem com o original")

; Sobrescreve a tela #1 - nao pode duplicar
CheckTrue(ProjectDB::StoreScreen(1, "tela1b", ScreenCmdsB), "StoreScreen #1 de novo (sobrescrevendo tag/comandos)")
ClearList(ScreenNumbers())
ProjectDB::ListScreenNumbers(ScreenNumbers())
CheckTrue(Bool(ListSize(ScreenNumbers()) = 2), "Ainda 2 telas apos sobrescrever #1 (nao duplicou)")
ProjectDB::FetchScreen(1)
CheckTrue(Bool(ProjectDB::LastScreenTag() = "tela1b"), "Tela #1: tag atualizada para 'tela1b'")
CheckTrue(Bool(ProjectDB::LastScreenCommandsText() = ScreenCmdsB), "Tela #1: comandos atualizados apos sobrescrever")

CheckTrue(ProjectDB::HasScreen(2), "HasScreen(2) = #True")
CheckTrue(Bool(Not ProjectDB::HasScreen(99)), "HasScreen(99) = #False")

; 8e) StoreSound/FetchSound - efeitos PSG (sequencia de passos com 14
; registradores + duracao), mesmo padrao Store/Fetch/List dos sprites/alfabetos.
; Regs e 1D "achatado" (Regs(i*14+r)) - ver comentario de StoreSound em
; ProjectDB.pbi (ReDim so redimensiona a ultima dimensao de um array).
Procedure.i SoundRegsMatch(Array A.a(1), Array B.a(1), NumSteps.i)
  Protected i
  For i = 0 To NumSteps * 14 - 1
    If A(i) <> B(i)
      ProcedureReturn #False
    EndIf
  Next
  ProcedureReturn #True
EndProcedure

Dim SoundRegsA.a(27)
SoundRegsA(0 * 14 + 0) = 60  : SoundRegsA(0 * 14 + 1) = 0 : SoundRegsA(0 * 14 + 7) = %00111110 : SoundRegsA(0 * 14 + 8) = 15
SoundRegsA(1 * 14 + 6) = 8   : SoundRegsA(1 * 14 + 7) = %00110110 : SoundRegsA(1 * 14 + 8) = 16
SoundRegsA(1 * 14 + 11) = 40 : SoundRegsA(1 * 14 + 13) = 9
Dim SoundDursA.w(1)
SoundDursA(0) = 6 : SoundDursA(1) = 12

CheckTrue(ProjectDB::StoreSound(1, "laser", 2, SoundRegsA(), SoundDursA()), "StoreSound #1 (2 passos, tag 'laser')")

Dim SoundRegsB.a(13)
SoundRegsB(0) = 200 : SoundRegsB(1) = 1 : SoundRegsB(7) = %00111110 : SoundRegsB(8) = 10
Dim SoundDursB.w(0)
SoundDursB(0) = 30
CheckTrue(ProjectDB::StoreSound(2, "beep", 1, SoundRegsB(), SoundDursB()), "StoreSound #2 (1 passo, tag 'beep')")

NewList SoundNumbers.i()
ProjectDB::ListSoundNumbers(SoundNumbers())
CheckTrue(Bool(ListSize(SoundNumbers()) = 2), "ListSoundNumbers (esperado 2, achou " + Str(ListSize(SoundNumbers())) + ")")

Dim LoadedSoundA.a(0)
CheckTrue(ProjectDB::FetchSound(1, LoadedSoundA(), SoundDursA()), "FetchSound #1")
CheckTrue(Bool(ProjectDB::LastSoundTag() = "laser"), "Som #1: tag = 'laser'")
CheckTrue(Bool(ProjectDB::LastSoundStepCount() = 2), "Som #1: step_count = 2 (achou " + Str(ProjectDB::LastSoundStepCount()) + ")")
CheckTrue(SoundRegsMatch(SoundRegsA(), LoadedSoundA(), 2), "Som #1: registradores recarregados batem com o original")
CheckTrue(Bool(SoundDursA(0) = 6 And SoundDursA(1) = 12), "Som #1: duracoes recarregadas batem com o original")

; Sobrescreve o som #1 (menos passos, tag diferente) - nao pode duplicar
Dim SoundRegsA2.a(13)
SoundRegsA2(8) = 5
Dim SoundDursA2.w(0)
SoundDursA2(0) = 3
CheckTrue(ProjectDB::StoreSound(1, "laser2", 1, SoundRegsA2(), SoundDursA2()), "StoreSound #1 de novo (sobrescrevendo, agora com 1 passo)")
ClearList(SoundNumbers())
ProjectDB::ListSoundNumbers(SoundNumbers())
CheckTrue(Bool(ListSize(SoundNumbers()) = 2), "Ainda 2 sons apos sobrescrever #1 (nao duplicou)")
ProjectDB::FetchSound(1, LoadedSoundA(), SoundDursA())
CheckTrue(Bool(ProjectDB::LastSoundTag() = "laser2"), "Som #1: tag atualizada para 'laser2'")
CheckTrue(Bool(ProjectDB::LastSoundStepCount() = 1), "Som #1: step_count atualizado para 1")

CheckTrue(ProjectDB::HasSound(2), "HasSound(2) = #True")
CheckTrue(Bool(Not ProjectDB::HasSound(99)), "HasSound(99) = #False")

; 8f) StoreSong/FetchSong - musicas MML/PLAY (3 canais de linhas de texto),
; mesmo padrao Store/Fetch/List dos demais tipos de conteudo.
Procedure.i SongLinesMatch(Array A.s(2), Array CountA.i(1), Array B.s(2), Array CountB.i(1))
  Protected c, i
  For c = 0 To 2
    If CountA(c) <> CountB(c)
      ProcedureReturn #False
    EndIf
    For i = 0 To CountA(c) - 1
      If A(c, i) <> B(c, i)
        ProcedureReturn #False
      EndIf
    Next
  Next
  ProcedureReturn #True
EndProcedure

Dim SongLinesA.s(2, 9)
Dim SongCountA.i(2)
SongLinesA(0, 0) = "T120O4L8CDEFGAB" : SongLinesA(0, 1) = "L4CEG"
SongCountA(0) = 2
SongLinesA(1, 0) = "O3L4EGB"
SongCountA(1) = 1
SongCountA(2) = 0   ; canal C vazio

CheckTrue(ProjectDB::StoreSong(1, "cancao1", SongLinesA(), SongCountA()), "StoreSong #1 (2 linhas A, 1 linha B, C vazio)")

Dim SongLinesB.s(2, 9)
Dim SongCountB.i(2)
SongLinesB(0, 0) = "T140O5CDE"
SongCountB(0) = 1
CheckTrue(ProjectDB::StoreSong(2, "cancao2", SongLinesB(), SongCountB()), "StoreSong #2 (1 linha so no canal A)")

NewList SongNumbers.i()
ProjectDB::ListSongNumbers(SongNumbers())
CheckTrue(Bool(ListSize(SongNumbers()) = 2), "ListSongNumbers (esperado 2, achou " + Str(ListSize(SongNumbers())) + ")")

Dim LoadedSongA.s(2, 9)
Dim LoadedSongCountA.i(2)
CheckTrue(ProjectDB::FetchSong(1, LoadedSongA(), LoadedSongCountA()), "FetchSong #1")
CheckTrue(Bool(ProjectDB::LastSongTag() = "cancao1"), "Musica #1: tag = 'cancao1'")
CheckTrue(SongLinesMatch(SongLinesA(), SongCountA(), LoadedSongA(), LoadedSongCountA()), "Musica #1: linhas dos 3 canais batem com o original")

; Sobrescreve a musica #1 (menos linhas, tag diferente) - nao pode duplicar
Dim SongLinesA2.s(2, 9)
Dim SongCountA2.i(2)
SongLinesA2(0, 0) = "R1"
SongCountA2(0) = 1
CheckTrue(ProjectDB::StoreSong(1, "cancao1b", SongLinesA2(), SongCountA2()), "StoreSong #1 de novo (sobrescrevendo, agora com 1 linha)")
ClearList(SongNumbers())
ProjectDB::ListSongNumbers(SongNumbers())
CheckTrue(Bool(ListSize(SongNumbers()) = 2), "Ainda 2 musicas apos sobrescrever #1 (nao duplicou)")
ProjectDB::FetchSong(1, LoadedSongA(), LoadedSongCountA())
CheckTrue(Bool(ProjectDB::LastSongTag() = "cancao1b"), "Musica #1: tag atualizada para 'cancao1b'")
CheckTrue(Bool(LoadedSongCountA(0) = 1), "Musica #1: contagem de linhas do canal A atualizada para 1")

CheckTrue(ProjectDB::HasSong(2), "HasSong(2) = #True")
CheckTrue(Bool(Not ProjectDB::HasSong(99)), "HasSong(99) = #False")

; 8g) StoreAsmBuild/FetchAsmBuild - metadado da ultima exportacao de binario
; do assembler Z80 (modulo 2b), mesmo padrao Store/Fetch/Has dos demais tipos
; de conteudo - so que SourceKey e TEXT (caminho do .asm ou, pra uma sessao
; de link, "LINK|" + os .rel na ordem escolhida), nao numero sequencial - ver
; comentario da declaracao em ProjectDB.pbi.
CheckTrue(ProjectDB::StoreAsmBuild("C:\proj\game.asm", "ABS", "BIN", "C:\proj\game.bin", 32768, 32800, #True),
         "StoreAsmBuild (montagem absoluta, com cabecalho)")
CheckTrue(ProjectDB::StoreAsmBuild("LINK|C:\proj\a.rel|C:\proj\b.rel", "LINK", "DSK", "C:\proj\game.dsk", 256, 4095, #True),
         "StoreAsmBuild (link, saida em disco)")

CheckTrue(ProjectDB::FetchAsmBuild("C:\proj\game.asm"), "FetchAsmBuild(game.asm)")
CheckTrue(Bool(ProjectDB::LastAsmBuildKind() = "ABS"), "AsmBuild(game.asm): build_kind = 'ABS'")
CheckTrue(Bool(ProjectDB::LastAsmBuildOutputKind() = "BIN"), "AsmBuild(game.asm): output_kind = 'BIN'")
CheckTrue(Bool(ProjectDB::LastAsmBuildOutputPath() = "C:\proj\game.bin"), "AsmBuild(game.asm): output_path bate")
CheckTrue(Bool(ProjectDB::LastAsmBuildStartAddr() = 32768), "AsmBuild(game.asm): start_addr = 32768")
CheckTrue(Bool(ProjectDB::LastAsmBuildEndAddr() = 32800), "AsmBuild(game.asm): end_addr = 32800")
CheckTrue(Bool(ProjectDB::LastAsmBuildBLoadHeader() = 1), "AsmBuild(game.asm): bload_header = 1")

; Sobrescreve (mesma SourceKey) - nao pode duplicar, tem que atualizar
CheckTrue(ProjectDB::StoreAsmBuild("C:\proj\game.asm", "ABS", "BIN", "C:\proj\game_v2.bin", 32768, 32900, #False),
         "StoreAsmBuild (mesma SourceKey de novo, sobrescrevendo)")
ProjectDB::FetchAsmBuild("C:\proj\game.asm")
CheckTrue(Bool(ProjectDB::LastAsmBuildOutputPath() = "C:\proj\game_v2.bin"), "AsmBuild(game.asm): output_path atualizado apos sobrescrever")
CheckTrue(Bool(ProjectDB::LastAsmBuildBLoadHeader() = 0), "AsmBuild(game.asm): bload_header atualizado para 0")

NewList AsmBuildKeys.s()
ProjectDB::ListAsmBuildKeys(AsmBuildKeys())
CheckTrue(Bool(ListSize(AsmBuildKeys()) = 2), "ListAsmBuildKeys (esperado 2, achou " + Str(ListSize(AsmBuildKeys())) + ")")

CheckTrue(ProjectDB::HasAsmBuild("LINK|C:\proj\a.rel|C:\proj\b.rel"), "HasAsmBuild(link) = #True")
CheckTrue(Bool(Not ProjectDB::HasAsmBuild("nao existe")), "HasAsmBuild(chave inexistente) = #False")

; 8h) StoreAsmSubProject/FetchAsmSubProject - "Makefile primitivo" do
; assembler Z80 (Criar -> Assembly Sub Project...): lista ordenada de .asm +
; lista ordenada de .lib, cada uma serializada como TEXT unido por Chr(10)
; (mesmo padrao de StoreSong/lines_a).
Procedure.i StrListsMatch(List A.s(), List B.s())
  If ListSize(A()) <> ListSize(B())
    ProcedureReturn #False
  EndIf
  FirstElement(A()) : FirstElement(B())
  Protected i
  For i = 1 To ListSize(A())
    If A() <> B()
      ProcedureReturn #False
    EndIf
    NextElement(A()) : NextElement(B())
  Next
  ProcedureReturn #True
EndProcedure

NewList SubProjAsmA.s()
AddElement(SubProjAsmA()) : SubProjAsmA() = "src\main.asm"
AddElement(SubProjAsmA()) : SubProjAsmA() = "src\utils.asm"
NewList SubProjLibA.s()
AddElement(SubProjLibA()) : SubProjLibA() = "libs\mathlib.rel"
CheckTrue(ProjectDB::StoreAsmSubProject(1, "jogo1", SubProjAsmA(), SubProjLibA()),
         "StoreAsmSubProject #1 (2 .asm, 1 .lib)")

NewList SubProjAsmB.s()
AddElement(SubProjAsmB()) : SubProjAsmB() = "demo\demo.asm"
NewList SubProjLibB.s()
CheckTrue(ProjectDB::StoreAsmSubProject(2, "demo", SubProjAsmB(), SubProjLibB()),
         "StoreAsmSubProject #2 (1 .asm, sem lib)")

NewList SubProjNumbers.i()
ProjectDB::ListAsmSubProjectNumbers(SubProjNumbers())
CheckTrue(Bool(ListSize(SubProjNumbers()) = 2), "ListAsmSubProjectNumbers (esperado 2, achou " + Str(ListSize(SubProjNumbers())) + ")")

NewList LoadedSubProjAsm.s()
NewList LoadedSubProjLib.s()
CheckTrue(ProjectDB::FetchAsmSubProject(1, LoadedSubProjAsm(), LoadedSubProjLib()), "FetchAsmSubProject #1")
CheckTrue(Bool(ProjectDB::LastAsmSubProjectTag() = "jogo1"), "SubProject #1: tag = 'jogo1'")
CheckTrue(StrListsMatch(SubProjAsmA(), LoadedSubProjAsm()), "SubProject #1: lista de .asm bate com a original")
CheckTrue(StrListsMatch(SubProjLibA(), LoadedSubProjLib()), "SubProject #1: lista de .lib bate com a original")

; Sobrescreve (mesmo numero) - reordena os .asm e some com a lib
NewList SubProjAsmA2.s()
AddElement(SubProjAsmA2()) : SubProjAsmA2() = "src\utils.asm"
AddElement(SubProjAsmA2()) : SubProjAsmA2() = "src\main.asm"
NewList SubProjLibA2.s()
CheckTrue(ProjectDB::StoreAsmSubProject(1, "jogo1b", SubProjAsmA2(), SubProjLibA2()),
         "StoreAsmSubProject #1 de novo (sobrescrevendo, ordem trocada, sem lib)")
ClearList(SubProjNumbers())
ProjectDB::ListAsmSubProjectNumbers(SubProjNumbers())
CheckTrue(Bool(ListSize(SubProjNumbers()) = 2), "Ainda 2 subprojetos apos sobrescrever #1 (nao duplicou)")
ClearList(LoadedSubProjAsm()) : ClearList(LoadedSubProjLib())
ProjectDB::FetchAsmSubProject(1, LoadedSubProjAsm(), LoadedSubProjLib())
CheckTrue(Bool(ProjectDB::LastAsmSubProjectTag() = "jogo1b"), "SubProject #1: tag atualizada para 'jogo1b'")
CheckTrue(StrListsMatch(SubProjAsmA2(), LoadedSubProjAsm()), "SubProject #1: ordem de .asm atualizada")
CheckTrue(Bool(ListSize(LoadedSubProjLib()) = 0), "SubProject #1: lista de .lib esvaziada apos sobrescrever")

CheckTrue(ProjectDB::HasAsmSubProject(2), "HasAsmSubProject(2) = #True")
CheckTrue(Bool(Not ProjectDB::HasAsmSubProject(99)), "HasAsmSubProject(99) = #False")

; "Projeto 0" (defaults, sempre em memoria): alfabeto 0 = msx.alf embutido
; no executavel - confere que bate byte a byte com o .alf real do
; repositorio (alfabetos\msx.alf, dois niveis acima de editor\tools\), pra
; pegar caso o embutido fique desatualizado em relacao ao arquivo fonte.
Dim DefaultAlpha.a(255, 7)
CheckTrue(ProjectDB::FetchDefaultAlphabet(0, DefaultAlpha()), "FetchDefaultAlphabet(0) (projeto 0/defaults)")

Define RealAlfPath.s = GetPathPart(ProgramFilename()) + "..\..\alfabetos\msx.alf"
Define RealAlfMatches.i = #False
Define AlfFile = ReadFile(#PB_Any, RealAlfPath)
If AlfFile
  Dim RealAlfBytes.a(255, 7)
  FileSeek(AlfFile, 7)   ; pula o cabecalho binario MSX (ID + enderecos)
  Define RRow, RCol
  For RRow = 0 To 255
    For RCol = 0 To 7
      RealAlfBytes(RRow, RCol) = ReadByte(AlfFile) & $FF
    Next
  Next
  CloseFile(AlfFile)
  RealAlfMatches = AlphaBytesMatch(RealAlfBytes(), DefaultAlpha())
EndIf
CheckTrue(RealAlfMatches, "Alfabeto 0 (defaults) bate byte a byte com alfabetos\msx.alf real")

; 9) SaveAs promove pro arquivo permanente
Define SavedPath.s = WorkDir + "meuprojeto.msxproject"
CheckTrue(ProjectDB::SaveAs(SavedPath), "SaveAs(" + SavedPath + ")")
CheckTrue(Bool(FileSize(SavedPath) > 0), "Arquivo do projeto existe e tem conteudo apos SaveAs")
CheckTrue(Bool(Not ProjectDB::IsTemp()), "IsTemp() = #False apos SaveAs")
CheckTrue(Bool(ProjectDB::GetPath() = SavedPath), "GetPath() aponta pro novo arquivo permanente")
CheckTrue(Bool(Not ProjectDB::HasUnsavedContent()), "HasUnsavedContent() = #False apos SaveAs (ja nao e mais temporario)")

; 10) Dados continuam acessiveis depois do SaveAs (reabriu no novo arquivo)
ClearList(Numbers())
ProjectDB::ListSpriteNumbers(Numbers())
CheckTrue(Bool(ListSize(Numbers()) = 3), "ListSpriteNumbers ainda mostra 3 sprites apos SaveAs")
Dim FinalA.b(15, 15)
ProjectDB::FetchSprite(3, FinalA())
CheckTrue(GridsMatch(GridC(), FinalA(), 16), "Sprite #3 ainda bate byte a byte apos SaveAs + reabrir")
CheckTrue(Bool(ProjectDB::GetWorkingDir() = "C:\meu\projeto"), "GetWorkingDir() ainda bate apos SaveAs")
ProjectDB::FetchDocument(DocPath1)
CheckTrue(Bool(ProjectDB::LastDocumentContent() = DocContent1b), "Documento fonte1.dmx ainda bate apos SaveAs")
ClearList(AlphaNumbers())
ProjectDB::ListAlphabetNumbers(AlphaNumbers())
CheckTrue(Bool(ListSize(AlphaNumbers()) = 2), "ListAlphabetNumbers ainda mostra 2 alfabetos apos SaveAs")
ProjectDB::FetchAlphabet(2, LoadedAlphaA())
CheckTrue(AlphaBytesMatch(AlphaB(), LoadedAlphaA()), "Alfabeto #2 ainda bate byte a byte apos SaveAs")
ClearList(SoundNumbers())
ProjectDB::ListSoundNumbers(SoundNumbers())
CheckTrue(Bool(ListSize(SoundNumbers()) = 2), "ListSoundNumbers ainda mostra 2 sons apos SaveAs")
ProjectDB::FetchSound(2, LoadedSoundA(), SoundDursB())
CheckTrue(Bool(ProjectDB::LastSoundTag() = "beep"), "Som #2 ainda bate (tag 'beep') apos SaveAs")
ClearList(SongNumbers())
ProjectDB::ListSongNumbers(SongNumbers())
CheckTrue(Bool(ListSize(SongNumbers()) = 2), "ListSongNumbers ainda mostra 2 musicas apos SaveAs")
ProjectDB::FetchSong(2, LoadedSongA(), LoadedSongCountA())
CheckTrue(Bool(ProjectDB::LastSongTag() = "cancao2"), "Musica #2 ainda bate (tag 'cancao2') apos SaveAs")
ClearList(AsmBuildKeys())
ProjectDB::ListAsmBuildKeys(AsmBuildKeys())
CheckTrue(Bool(ListSize(AsmBuildKeys()) = 2), "ListAsmBuildKeys ainda mostra 2 builds apos SaveAs")
ProjectDB::FetchAsmBuild("C:\proj\game.asm")
CheckTrue(Bool(ProjectDB::LastAsmBuildOutputPath() = "C:\proj\game_v2.bin"), "AsmBuild(game.asm) ainda bate apos SaveAs")
ClearList(SubProjNumbers())
ProjectDB::ListAsmSubProjectNumbers(SubProjNumbers())
CheckTrue(Bool(ListSize(SubProjNumbers()) = 2), "ListAsmSubProjectNumbers ainda mostra 2 subprojetos apos SaveAs")
ClearList(LoadedSubProjAsm()) : ClearList(LoadedSubProjLib())
ProjectDB::FetchAsmSubProject(2, LoadedSubProjAsm(), LoadedSubProjLib())
CheckTrue(Bool(ProjectDB::LastAsmSubProjectTag() = "demo" And StrListsMatch(SubProjAsmB(), LoadedSubProjAsm())),
         "SubProject #2 ainda bate (tag 'demo', lista de .asm) apos SaveAs")

; 11) OpenExisting - simula "Arquivo -> Abrir projeto...": fecha tudo e
; reabre do zero so a partir do caminho salvo, sem passar por EnsureOpen.
ProjectDB::Close()
CheckTrue(ProjectDB::OpenExisting(SavedPath), "OpenExisting(" + SavedPath + ") apos fechar")
CheckTrue(Bool(Not ProjectDB::IsTemp()), "IsTemp() = #False logo apos OpenExisting")
CheckTrue(Bool(ProjectDB::GetPath() = SavedPath), "GetPath() aponta pro arquivo reaberto")
ClearList(Numbers())
ProjectDB::ListSpriteNumbers(Numbers())
CheckTrue(Bool(ListSize(Numbers()) = 3), "ListSpriteNumbers mostra 3 sprites apos OpenExisting")
Dim ReopenedB.b(15, 15)
ProjectDB::FetchSprite(2, ReopenedB())
CheckTrue(GridsMatch(GridB(), ReopenedB(), 8), "Sprite #2 ainda bate byte a byte apos OpenExisting")
CheckTrue(Bool(ProjectDB::GetWorkingDir() = "C:\meu\projeto"), "GetWorkingDir() ainda bate apos OpenExisting")
ProjectDB::FetchDocument(DocPath2)
CheckTrue(Bool(ProjectDB::LastDocumentContent() = DocContent2), "Documento fonte2.asm ainda bate apos OpenExisting")
ClearList(AlphaNumbers())
ProjectDB::ListAlphabetNumbers(AlphaNumbers())
CheckTrue(Bool(ListSize(AlphaNumbers()) = 2), "ListAlphabetNumbers ainda mostra 2 alfabetos apos OpenExisting")
ProjectDB::FetchAlphabet(1, LoadedAlphaA())
CheckTrue(AlphaBytesMatch(AlphaB(), LoadedAlphaA()), "Alfabeto #1 ainda bate byte a byte apos OpenExisting")
ClearList(SoundNumbers())
ProjectDB::ListSoundNumbers(SoundNumbers())
CheckTrue(Bool(ListSize(SoundNumbers()) = 2), "ListSoundNumbers ainda mostra 2 sons apos OpenExisting")
ProjectDB::FetchSound(1, LoadedSoundA(), SoundDursA2())
CheckTrue(Bool(ProjectDB::LastSoundTag() = "laser2" And ProjectDB::LastSoundStepCount() = 1), "Som #1 ainda bate (tag 'laser2', 1 passo) apos OpenExisting")
ClearList(SongNumbers())
ProjectDB::ListSongNumbers(SongNumbers())
CheckTrue(Bool(ListSize(SongNumbers()) = 2), "ListSongNumbers ainda mostra 2 musicas apos OpenExisting")
ProjectDB::FetchSong(1, LoadedSongA(), LoadedSongCountA())
CheckTrue(Bool(ProjectDB::LastSongTag() = "cancao1b" And LoadedSongCountA(0) = 1), "Musica #1 ainda bate (tag 'cancao1b', 1 linha) apos OpenExisting")
ClearList(AsmBuildKeys())
ProjectDB::ListAsmBuildKeys(AsmBuildKeys())
CheckTrue(Bool(ListSize(AsmBuildKeys()) = 2), "ListAsmBuildKeys ainda mostra 2 builds apos OpenExisting")
ProjectDB::FetchAsmBuild("LINK|C:\proj\a.rel|C:\proj\b.rel")
CheckTrue(Bool(ProjectDB::LastAsmBuildOutputPath() = "C:\proj\game.dsk"), "AsmBuild(link) ainda bate apos OpenExisting")
ClearList(SubProjNumbers())
ProjectDB::ListAsmSubProjectNumbers(SubProjNumbers())
CheckTrue(Bool(ListSize(SubProjNumbers()) = 2), "ListAsmSubProjectNumbers ainda mostra 2 subprojetos apos OpenExisting")
ClearList(LoadedSubProjAsm()) : ClearList(LoadedSubProjLib())
ProjectDB::FetchAsmSubProject(1, LoadedSubProjAsm(), LoadedSubProjLib())
CheckTrue(Bool(ProjectDB::LastAsmSubProjectTag() = "jogo1b" And StrListsMatch(SubProjAsmA2(), LoadedSubProjAsm())),
         "SubProject #1 ainda bate (tag 'jogo1b', ordem de .asm) apos OpenExisting")
CheckTrue(Bool(Not ProjectDB::OpenExisting(WorkDir + "nao_existe.msxproject")), "OpenExisting falha graciosamente com arquivo inexistente")

; 12) Close nao deve travar (limpeza final)
ProjectDB::Close()
PrintN("Close() executado sem erro.")

PrintN("")
If Failures = 0
  PrintN("TODOS OS TESTES PASSARAM.")
  End 0
Else
  PrintN(Str(Failures) + " TESTE(S) FALHARAM.")
  End 1
EndIf
