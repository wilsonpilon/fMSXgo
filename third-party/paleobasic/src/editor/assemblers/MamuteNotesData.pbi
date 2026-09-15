;
; ------------------------------------------------------------
;  Carregador do arquivo de notas do SUPER-X ("SUPER-X.TNK", docs/SPEC.md
;  modulo 45e) - pedido explicito do usuario: "Por hora apenas carregue
;  estas notas na memoria, vamos usar elas em outros comandos" (comandos
;  iM/iC/iL/iS ainda nao existem, ficam pra uma sessao futura, fase F do
;  modulo 45). Este arquivo so' tem o PARSER/estrutura em memoria - nenhum
;  comando do MON> chama Mamute_LoadNoteFile() ainda.
;
;  Formato do arquivo (doc do SUPER-X, secao "Note function"): 2 bytes no
;  inicio = quantidade de notas gravadas (nao "notas que sobram", como a
;  doc em ingles sugere - confirmado lendo o arquivo real de exemplo:
;  campo = 471, exatamente a quantidade de notas com conteudo real; as
;  512-471 = 41 restantes sao so padding, preenchido com 0x20 (espaco), nao
;  zero) + ate 512 registros fixos de 64 bytes cada:
;    endereco   2 bytes (little-endian)
;    slot       1 byte  (classificacao PROPRIA do SUPER-X: 0=Geral 1=MAIN
;                        2=SUB 3=FDC 4=RAM - NAO e' o mesmo conceito do
;                        #slot/sub-slot do enderecamento estendido,
;                        modulo 45b/Mamute_SxTarget - essas duas coisas so'
;                        coincidem de nome)
;    tipo       1 byte  (0=Geral 1=BIOS 2=WORK 3=DATA 4=PORT 5=MATH 6=KEY
;                        7=HOOK)
;    texto      60 bytes (japones - katakana meia-largura, Shift-JIS de
;                        byte unico 0xA1-0xDF, mesma faixa da doc: "ASCII
;                        128-255 e' japones" - confirmado decodificando o
;                        arquivo real com Shift-JIS, nao um encoding
;                        customizado como se suspeitava antes de olhar os
;                        bytes de verdade)
;  = 2 + 512*64 = 32770 bytes, bate exato com a doc.
;
;  O texto e' guardado CRU (Chr() byte a byte, sem tentar decodificar
;  Shift-JIS em tempo de execucao) - a traducao pro portugues das 471 notas
;  reais do arquivo de exemplo do SUPER-X vira conteudo ESTATICO da Ajuda
;  (MamuteSuperXNotesHelpData.pbi), nao decodificacao dinamica.
; ------------------------------------------------------------
;

Structure MamuteNote
  Addr.u
  SlotData.a
  TypeData.a
  Text.s ; bytes crus (Chr() 1 a 1) - pode conter caracteres > 127 (japones), sem decodificar
EndStructure

Global NewList MamuteNotes.MamuteNote()

; Le um arquivo .TNK inteiro pra MamuteNotes() (ClearList antes, sempre
; substitui o que tinha). #True se leu com sucesso; #False se nao abriu o
; arquivo OU se o tamanho nao bate com o formato esperado (2 + 512*64
; bytes) - nesse caso MamuteNotes() fica vazia, sem tentar interpretar
; dado corrompido/incompleto.
Procedure.b Mamute_LoadNoteFile(FilePath.s)
  ClearList(MamuteNotes())

  Protected Fh.i = ReadFile(#PB_Any, FilePath)
  If Not Fh
    ProcedureReturn #False
  EndIf

  ; ">=", nao "=" - o .TNK real de exemplo (SUPER-X.TNK original) tem 126
  ; bytes A MAIS que o esperado (32896 em vez de 32770) - achado real,
  ; confirmado inspecionando o arquivo: sobra depois do ultimo dos 512
  ; registros, nao faz parte do formato descrito na doc, provavelmente lixo/
  ; padding do gravador original. So' recusa arquivo CURTO demais (truncado).
  Protected FileSize.i = Lof(Fh)
  If FileSize < 2 + 512 * 64
    CloseFile(Fh)
    ProcedureReturn #False
  EndIf

  Protected CountLow.a = ReadByte(Fh)
  Protected CountHigh.a = ReadByte(Fh)
  Protected NoteCount.i = CountLow | (CountHigh << 8)
  If NoteCount < 0 Or NoteCount > 512
    CloseFile(Fh)
    ProcedureReturn #False
  EndIf

  Protected i.i, b.i
  Protected AddrLow.a, AddrHigh.a, SlotByte.a, TypeByte.a
  Protected TextByte.a
  For i = 0 To NoteCount - 1
    AddrLow = ReadByte(Fh)
    AddrHigh = ReadByte(Fh)
    SlotByte = ReadByte(Fh)
    TypeByte = ReadByte(Fh)
    Protected TextRaw.s = ""
    For b = 0 To 59
      TextByte = ReadByte(Fh)
      TextRaw + Chr(TextByte)
    Next

    AddElement(MamuteNotes())
    MamuteNotes()\Addr = AddrLow | (AddrHigh << 8)
    MamuteNotes()\SlotData = SlotByte
    MamuteNotes()\TypeData = TypeByte
    MamuteNotes()\Text = TextRaw
  Next

  CloseFile(Fh)
  ProcedureReturn #True
EndProcedure

; Caminho do arquivo de notas TRADUZIDO que o proprio Paleobasic ja traz
; pronto (resource/superx/SUPER-X-PT.notas, copiado pra dist/editor/
; SUPER-X-PT.notas pelo build.ps1) - usado como SUGESTAO padrao pelo XIL,
; NUNCA o SUPER-X.TNK original (japones, others/superx/ - arquivo de
; terceiros, nao versionado em dist/) - pedido explicito do usuario:
; "assegure-se de ler o arquivo ja traduzido de notas e nao o original em
; japones" (docs/SPEC.md modulo 45x).
Procedure.s Mamute_TranslatedNotesFilePath()
  ProcedureReturn GetPathPart(ProgramFilename()) + "editor\SUPER-X-PT.notas"
EndProcedure

; Formato PROPRIO deste porte (NAO o binario Shift-JIS de 64 bytes/registro
; do SUPER-X.TNK original, acima) - texto UTF-8 puro (com BOM), uma nota
; por linha, 4 campos separados por ";": ENDERECO (4 digitos hexa) ; SLOT
; (0-4, classificacao propria do SUPER-X - 0=Geral 1=MAIN 2=SUB 3=FDC
; 4=RAM) ; TIPO (0-7 - 0=Geral 1=BIOS 2=WORK 3=DATA 4=PORT 5=MATH 6=KEY
; 7=HOOK) ; TEXTO (livre, SEM o limite de 60 caracteres do formato
; original - as traducoes reais sao mais verbosas que o original em
; japones e nao caberiam truncadas nesse limite). Gerado uma unica vez, a
; partir das 471 notas ja traduzidas em MamuteSuperXNotesHelpData.pbi (um
; script Python descartavel, fora do projeto, extraiu endereco+tipo+texto
; de volta dos literais de string ja escritos a mao - ver docs/SPEC.md
; modulo 45x pro relato completo, inclusive os 2 achados reais de parsing:
; texto com "+" literal dentro de citacoes, tipo "CTRL+STOP", confundindo
; um split ingenuo com a concatenacao `+` do PureBasic).
;
; #True se abriu o arquivo (linhas mal formadas dentro dele sao SO'
; IGNORADAS uma a uma, nao abortam o carregamento inteiro).
Procedure.b Mamute_LoadTranslatedNotes(FilePath.s)
  ClearList(MamuteNotes())
  Protected Fh.i = ReadFile(#PB_Any, FilePath, #PB_File_BOM)
  If Not Fh
    ProcedureReturn #False
  EndIf

  Protected Line.s
  While Not Eof(Fh)
    Line = ReadString(Fh)
    If Trim(Line) = ""
      Continue
    EndIf

    Protected AddrTok.s = StringField(Line, 1, ";")
    Protected SlotTok.s = StringField(Line, 2, ";")
    Protected TypeTok.s = StringField(Line, 3, ";")
    If Not Mamute_IsHexString(AddrTok, 4) Or Not Mamute_IsHexString(SlotTok, 1) Or Not Mamute_IsHexString(TypeTok, 1)
      Continue ; linha mal formada - ignora, nao aborta o arquivo inteiro
    EndIf
    ; TEXTO e' TUDO depois do 3o ";" (reconstroi manualmente em vez de usar
    ; StringField(Line,4,";") - o texto pode, em tese, ter um ";" sobrando
    ; que o gerador nao sanitizou, e' mais seguro pegar "o resto da linha")
    Protected PrefixLen.i = Len(AddrTok) + 1 + Len(SlotTok) + 1 + Len(TypeTok) + 1
    Protected TextTok.s = Mid(Line, PrefixLen + 1)

    AddElement(MamuteNotes())
    MamuteNotes()\Addr = Val("$" + AddrTok)
    MamuteNotes()\SlotData = Val(SlotTok)
    MamuteNotes()\TypeData = Val(TypeTok)
    MamuteNotes()\Text = TextTok
  Wend

  CloseFile(Fh)
  ProcedureReturn #True
EndProcedure

; Nomes exibidos pelo XIC (slot/tipo do SUPER-X, ver cabecalho do arquivo) -
; qualquer valor fora de 0-4/0-7 (nao deveria acontecer, mas XIM aceita
; digitar qualquer numero) cai no Default e mostra o numero cru.
Procedure.s Mamute_NoteSlotName(SlotData.a)
  Select SlotData
    Case 0 : ProcedureReturn "GERAL"
    Case 1 : ProcedureReturn "MAIN"
    Case 2 : ProcedureReturn "SUB"
    Case 3 : ProcedureReturn "FDC"
    Case 4 : ProcedureReturn "RAM"
    Default : ProcedureReturn Str(SlotData)
  EndSelect
EndProcedure

Procedure.s Mamute_NoteTypeName(TypeData.a)
  Select TypeData
    Case 0 : ProcedureReturn "GERAL"
    Case 1 : ProcedureReturn "BIOS"
    Case 2 : ProcedureReturn "WORK"
    Case 3 : ProcedureReturn "DATA"
    Case 4 : ProcedureReturn "PORT"
    Case 5 : ProcedureReturn "MATH"
    Case 6 : ProcedureReturn "KEY"
    Case 7 : ProcedureReturn "HOOK"
    Default : ProcedureReturn Str(TypeData)
  EndSelect
EndProcedure

; Caminho do arquivo "sombra" editavel (mesma pasta do arquivo traduzido
; original) - usado pra nunca deixar o campo "Notas SUPER-X padrao"
; (Configurar -> Mamute Assembler..., MamuteSupport.pbi) nem o XIS
; sobrescreverem o SUPER-X-PT.notas que o proprio Paleobasic ja traz
; pronto.
Procedure.s Mamute_ShadowNotesFilePath()
  ProcedureReturn GetPathPart(ProgramFilename()) + "editor\SUPER-X-SHADOW.notas"
EndProcedure

; Se PickedPath aponta EXATAMENTE pro arquivo traduzido original
; (Mamute_TranslatedNotesFilePath()), protege-o (marca somente-leitura) e
; devolve o caminho do arquivo-sombra editavel no lugar dele (cria uma
; copia se ainda nao existir uma) - avisa o usuario via MessageRequester.
; Qualquer OUTRO caminho (inclusive o proprio arquivo-sombra) volta
; inalterado, sem aviso nenhum. Pedido explicito do usuario: "se o usuario
; escolher o SUPER-X-PT.notas, preserve-o como apenas leitura, informe que
; vai criar um SUPER-X-SHADOW.notas e este vai ser o padrao pra preservar
; o original" (docs/SPEC.md modulo 45y).
Procedure.s Mamute_ProtectTranslatedNotesIfPicked(PickedPath.s)
  If UCase(PickedPath) <> UCase(Mamute_TranslatedNotesFilePath())
    ProcedureReturn PickedPath
  EndIf

  Protected ShadowPath.s = Mamute_ShadowNotesFilePath()
  Protected AlreadyExisted.b = Bool(FileSize(ShadowPath) > 0)
  If Not AlreadyExisted
    If Not CopyFile(PickedPath, ShadowPath)
      MessageRequester("Nao foi possivel proteger o arquivo original",
        GetFilePart(PickedPath) + " e' o arquivo de notas TRADUZIDO original que acompanha o " +
        "Paleobasic - nao foi possivel criar a copia editavel (" + GetFilePart(ShadowPath) +
        "). Usando o arquivo original mesmo assim.", #PB_MessageRequester_Error)
      ProcedureReturn PickedPath
    EndIf
  EndIf

  SetFileAttributes(PickedPath, #PB_FileSystem_ReadOnly)

  If AlreadyExisted
    MessageRequester("Arquivo original protegido",
      GetFilePart(PickedPath) + " e' o arquivo de notas traduzido original que acompanha o " +
      "Paleobasic - marcado como somente leitura. Usando a copia editavel ja existente (" +
      GetFilePart(ShadowPath) + ") como arquivo padrao, pra preservar o original.",
      #PB_MessageRequester_Info)
  Else
    MessageRequester("Arquivo original protegido",
      GetFilePart(PickedPath) + " e' o arquivo de notas traduzido original que acompanha o " +
      "Paleobasic - marcado como somente leitura. Foi criada uma copia editavel (" +
      GetFilePart(ShadowPath) + "), que sera usada como arquivo padrao a partir de agora, pra " +
      "preservar o original.", #PB_MessageRequester_Info)
  EndIf

  ProcedureReturn ShadowPath
EndProcedure

; Grava MamuteNotes() (o que estiver em memoria agora - carregado via XIL +
; o que foi adicionado via XIM) no MESMO formato de Mamute_LoadTranslatedNotes()
; acima. #True se gravou com sucesso.
Procedure.b Mamute_SaveTranslatedNotes(FilePath.s)
  Protected Fh.i = CreateFile(#PB_Any, FilePath)
  If Not Fh
    ProcedureReturn #False
  EndIf
  Protected SafeText.s
  ForEach MamuteNotes()
    SafeText = ReplaceString(MamuteNotes()\Text, ";", ",")
    SafeText = ReplaceString(SafeText, Chr(13), " ")
    SafeText = ReplaceString(SafeText, Chr(10), " ")
    WriteStringN(Fh, Mamute_Hex4(MamuteNotes()\Addr) + ";" + Str(MamuteNotes()\SlotData) + ";" +
                     Str(MamuteNotes()\TypeData) + ";" + SafeText, #PB_UTF8)
  Next
  CloseFile(Fh)
  ProcedureReturn #True
EndProcedure
