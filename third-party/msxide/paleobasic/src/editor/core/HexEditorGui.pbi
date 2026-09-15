;
; ------------------------------------------------------------
;  Executar -> Editor Hexa...: editor hexadecimal generico para arquivos MSX
;  (abre qualquer arquivo do disco, nao so os do editor de texto). Mostra
;  offset/hex/ASCII e tenta identificar o formato reconhecendo os
;  cabecalhos que o proprio Badig gera - binario MSX BLOAD/BSAVE (byte de
;  tipo FEh + inicio/fim/execucao, ver Z80OutputGui.pbi e #CharEd_AlfID em
;  CharsetEditorGui.pbi), MSX-BASIC tokenizado (byte FFh, ver #Tok_Base em
;  MsxTokenizer.pbi) e o boot sector FAT12 de uma imagem de disco .dsk
;  (mesmos offsets de BootBlock() que MSXDisk.pbi le/escreve) - reconhece
;  tambem, por extensao/heuristica de conteudo (sem cabecalho magico
;  proprio): executavel MSX-DOS (.COM, codigo Z80 cru carregado em 0100h,
;  convencao CP/M), texto ASCII puro vs. BASIC MSX classico numerado (mesma
;  regra do tokenizador: toda linha comeca com numero) - alem de
;  permitir editar bytes individuais e salvar. Tambem mantem uma "galeria de
;  templates" (persistida em JSON, mesmo estilo de editor_settings.json/
;  badig_settings.json) de formatos binarios conhecidos (byte de tipo +
;  endereco inicial + tamanho dos dados) pra dar um nome amigavel a
;  binarios BLOAD/BSAVE que batam com um template registrado - ex.: um
;  alfabeto do Graphos III (byte FEh, inicio &H9200, 2048 bytes de dados,
;  ver GraphosNativeIO.pbi/CharsetEditorGui.pbi).
;
;  Edicao byte a byte via campo de texto (clique na grade seleciona, campo +
;  Aplicar grava) - sem foco de teclado direto no canvas nesta versao. Alem
;  disso, marcacao de intervalo (Marcar inicio/fim, mesmo padrao de
;  CharEd_MarkStart/MarkEnd do editor de alfabeto) habilita operacoes de
;  bloco: Preencher, Inserir (desloca), Sobrepor (nao desloca) e Excluir
;  (deslocando ou zerando) - se nao houver intervalo marcado, cada operacao
;  pergunta endereco inicial/final ou posicao.
; ------------------------------------------------------------
;

#HexEd_BytesPerRow  = 16
#HexEd_VisibleRows  = 26
#HexEd_MaxFileSize  = 8 * 1024 * 1024 ; guarda de sanidade - disquete MSX max e 720KB

#HexEd_FilePattern = "Todos os arquivos (*.*)|*.*|Binario/tokenizado MSX (*.bin;*.bas;*.bmx)|*.bin;*.bas;*.bmx|Executavel MSX-DOS (*.com)|*.com|Planilha SuperCalc 2 (*.cal)|*.cal|Banco de dados dBase II (*.dbf)|*.dbf|Imagem de disco (*.dsk)|*.dsk|ROM (*.rom)|*.rom"

Global Dim HexEd_Bytes.a(0)
Global HexEd_Size.i  = 0
Global HexEd_Path.s  = ""
Global HexEd_Dirty.b = #False

; Bloco de bytes temporario usado por Inserir/Sobrepor - vem de outro arquivo
; ou e gerado em branco (ver HexEd_PromptBlockSource).
Global Dim HexEd_ClipBytes.a(0)
Global HexEd_ClipSize.i = 0

; -1 num campo = "qualquer valor" (campo em branco na galeria de templates).
Structure HexEd_Template
  Name.s
  Ext.s      ; extensao sem ponto, minuscula, "" = qualquer
  FirstByte.i
  StartAddr.i
  DataSize.i
EndStructure

Global NewList HexEd_Templates.HexEd_Template()

Structure HexEd_Info
  TypeName.s
  Lines.s
EndStructure

; ------------------------------------------------------------
; Formatacao hex sempre com largura fixa - Hex(valor, #PB_Byte/#PB_Word) NAO
; preenche com zeros a esquerda neste PureBasic (Hex(0,#PB_Byte) retorna "0",
; nao "00"), entao a largura tem que ser forcada manualmente com RSet ou os
; valores baixos (00-0F) saem sem o zero e confundem o usuario.
; ------------------------------------------------------------
Procedure.s HexEd_Hex2(v.i)
  ProcedureReturn RSet(Hex(v & $FF), 2, "0")
EndProcedure

Procedure.s HexEd_Hex4(v.i)
  ProcedureReturn RSet(Hex(v & $FFFF), 4, "0")
EndProcedure

Procedure.s HexEd_Hex6(v.i)
  ProcedureReturn RSet(Hex(v & $FFFFFF), 6, "0")
EndProcedure

;- ------------------------------------------------------------
;- Galeria de templates: persistencia em JSON (mesmo estilo de
;- EditorCfg_FilePath/BadigCfg_FilePath) + semente padrao na primeira vez.
;- ------------------------------------------------------------

Procedure.s HexEd_TemplatesFilePath()
  ProcedureReturn GetPathPart(ProgramFilename()) + "editor\hexeditor_templates.json"
EndProcedure

Procedure HexEd_SeedDefaultTemplates()
  ClearList(HexEd_Templates())

  AddElement(HexEd_Templates())
  HexEd_Templates()\Name      = "Alfabeto Graphos III (.ALF)"
  HexEd_Templates()\Ext       = "alf"
  HexEd_Templates()\FirstByte = $FE
  HexEd_Templates()\StartAddr = $9200
  HexEd_Templates()\DataSize  = 2048

  ; Layout/Tela do Graphos III tem tamanho de dados VARIAVEL (RLE/rotina de
  ; apresentacao propria) - so o byte de tipo e a base de VRAM identificam o
  ; formato, ver comentario de GraphosNativeIO.pbi.
  AddElement(HexEd_Templates())
  HexEd_Templates()\Name      = "Layout Graphos III (.LAY)"
  HexEd_Templates()\Ext       = "lay"
  HexEd_Templates()\FirstByte = $FE
  HexEd_Templates()\StartAddr = $9200
  HexEd_Templates()\DataSize  = -1

  AddElement(HexEd_Templates())
  HexEd_Templates()\Name      = "Tela Graphos III (.SCR)"
  HexEd_Templates()\Ext       = "scr"
  HexEd_Templates()\FirstByte = $FE
  HexEd_Templates()\StartAddr = -1
  HexEd_Templates()\DataSize  = -1
EndProcedure

Procedure HexEd_SaveTemplates()
  Protected Json = CreateJSON(#PB_Any)
  Protected Root = SetJSONArray(JSONValue(Json))
  Protected Elem

  ForEach HexEd_Templates()
    Elem = AddJSONElement(Root)
    SetJSONObject(Elem)
    SetJSONString(AddJSONMember(Elem, "Name"), HexEd_Templates()\Name)
    SetJSONString(AddJSONMember(Elem, "Ext"), HexEd_Templates()\Ext)
    SetJSONInteger(AddJSONMember(Elem, "FirstByte"), HexEd_Templates()\FirstByte)
    SetJSONInteger(AddJSONMember(Elem, "StartAddr"), HexEd_Templates()\StartAddr)
    SetJSONInteger(AddJSONMember(Elem, "DataSize"), HexEd_Templates()\DataSize)
  Next

  SaveJSON(Json, HexEd_TemplatesFilePath(), #PB_JSON_PrettyPrint)
  FreeJSON(Json)
EndProcedure

Procedure HexEd_LoadTemplates()
  Protected FilePath.s = HexEd_TemplatesFilePath()
  If FileSize(FilePath) <= 0
    HexEd_SeedDefaultTemplates()
    HexEd_SaveTemplates()
    ProcedureReturn
  EndIf

  Protected Json = LoadJSON(#PB_Any, FilePath)
  If Not Json
    HexEd_SeedDefaultTemplates()
    ProcedureReturn
  EndIf

  Protected Root = JSONValue(Json)
  ClearList(HexEd_Templates())

  Protected N = JSONArraySize(Root)
  Protected i, Elem, M
  For i = 0 To N - 1
    Elem = GetJSONElement(Root, i)
    If Elem
      AddElement(HexEd_Templates())
      M = GetJSONMember(Elem, "Name")      : If M : HexEd_Templates()\Name      = GetJSONString(M)  : EndIf
      M = GetJSONMember(Elem, "Ext")        : If M : HexEd_Templates()\Ext       = GetJSONString(M)  : EndIf
      M = GetJSONMember(Elem, "FirstByte")  : If M : HexEd_Templates()\FirstByte = GetJSONInteger(M) : EndIf
      M = GetJSONMember(Elem, "StartAddr")  : If M : HexEd_Templates()\StartAddr = GetJSONInteger(M) : EndIf
      M = GetJSONMember(Elem, "DataSize")   : If M : HexEd_Templates()\DataSize  = GetJSONInteger(M) : EndIf
    EndIf
  Next
  FreeJSON(Json)

  If ListSize(HexEd_Templates()) = 0
    HexEd_SeedDefaultTemplates()
    HexEd_SaveTemplates()
  EndIf
EndProcedure

; Primeiro template cujos campos preenchidos (<>-1 ou "") batem com o
; arquivo - "" e -1 na galeria significam "qualquer valor", entao um
; template vazio bateria com tudo (o usuario e quem controla a
; especificidade adicionando os campos que quiser).
Procedure.s HexEd_MatchTemplate(Ext.s, FirstByte.i, StartAddr.i, DataSize.i)
  ForEach HexEd_Templates()
    If (HexEd_Templates()\Ext = "" Or HexEd_Templates()\Ext = Ext) And
       (HexEd_Templates()\FirstByte = -1 Or HexEd_Templates()\FirstByte = FirstByte) And
       (HexEd_Templates()\StartAddr = -1 Or HexEd_Templates()\StartAddr = StartAddr) And
       (HexEd_Templates()\DataSize = -1 Or HexEd_Templates()\DataSize = DataSize)
      ProcedureReturn HexEd_Templates()\Name
    EndIf
  Next
  ProcedureReturn ""
EndProcedure

;- ------------------------------------------------------------
;- Reconhecimento de formato de arquivo
;- ------------------------------------------------------------

; Heuristica pra distinguir um listing BASIC MSX classico (ASCII, todo linha
; comecando com numero - unico formato que o tokenizador desta IDE aceita de
; entrada) de texto ASCII puro qualquer: olha so o primeiro caractere visivel
; do arquivo (pulando espaco/tab de indentacao) - se for digito, e uma linha
; numerada; se vier uma linha em branco antes de qualquer caractere visivel,
; ja considera que nao e (todo BASIC classico valido comeca com numero na
; primeira linha).
Procedure.b HexEd_LooksLikeBasicSource(Array Bytes.a(1), Size.i)
  Protected i.i, Ch.i
  For i = 0 To Size - 1
    Ch = Bytes(i) & $FF
    If Ch = 32 Or Ch = 9
      ; espaco/tab de indentacao antes do primeiro char visivel - ignora
    ElseIf Ch = 10 Or Ch = 13
      ProcedureReturn #False
    Else
      ProcedureReturn Bool(Ch >= 48 And Ch <= 57)
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

; Reconhece os formatos que este app produz/consome (ver comentario do topo)
; e, se nada bater, tenta classificar como texto ASCII puro antes de cair em
; "dados crus". So le Bytes()/Size - nao depende de janela nem estado global
; (exceto a lista HexEd_Templates(), tratada como so-leitura aqui).
Procedure HexEd_DescribeFile(Array Bytes.a(1), Size.i, Path.s, *Info.HexEd_Info)
  Protected Ext.s = LCase(GetExtensionPart(Path))
  Protected b0.i, i.i, Ch.i, Printable.b = #True
  Protected StartAddr.i, EndAddr.i, ExecAddr.i, DataSize.i, TplName.s

  *Info\TypeName = "(arquivo vazio)"
  *Info\Lines = "Tamanho: 0 bytes"
  If Size <= 0
    ProcedureReturn
  EndIf

  *Info\Lines = "Tamanho: " + Str(Size) + " bytes"
  b0 = Bytes(0) & $FF

  If Ext = "dsk" And Size >= 24
    Protected BytesPerSector.i = (Bytes(11) & $FF) | ((Bytes(12) & $FF) << 8)
    Protected SecPerCluster.i  = Bytes(13) & $FF
    Protected NumFats.i        = Bytes(16) & $FF
    Protected RootEntries.i    = (Bytes(17) & $FF) | ((Bytes(18) & $FF) << 8)
    Protected TotalSectors.i   = (Bytes(19) & $FF) | ((Bytes(20) & $FF) << 8)
    Protected MediaDesc.i      = Bytes(21) & $FF
    Protected SectorsPerFat.i  = (Bytes(22) & $FF) | ((Bytes(23) & $FF) << 8)
    Protected RootDirOffset.i  = (1 + NumFats * SectorsPerFat) * BytesPerSector

    *Info\TypeName = "Imagem de disco MSX (FAT12)"
    *Info\Lines = "Tamanho: " + Str(Size) + " bytes" + Chr(13) + Chr(10) +
                  "Bytes por setor: " + Str(BytesPerSector) + Chr(13) + Chr(10) +
                  "Setores por cluster: " + Str(SecPerCluster) + Chr(13) + Chr(10) +
                  "Numero de FATs: " + Str(NumFats) + Chr(13) + Chr(10) +
                  "Entradas no diretorio raiz: " + Str(RootEntries) + Chr(13) + Chr(10) +
                  "Total de setores: " + Str(TotalSectors) + Chr(13) + Chr(10) +
                  "Descritor de midia: " + HexEd_Hex2(MediaDesc) + "h" + Chr(13) + Chr(10) +
                  "Setores por FAT: " + Str(SectorsPerFat) + Chr(13) + Chr(10) +
                  "Boot sector: offset 000000h" + Chr(13) + Chr(10) +
                  "Diretorio raiz: offset " + HexEd_Hex6(RootDirOffset) + "h"
    ProcedureReturn
  EndIf

  ; Extensao .COM - checado antes dos bytes magicos FEh/FFh porque um
  ; executavel MSX-DOS e codigo Z80 cru sem cabecalho (mesma convencao
  ; CP/M): o primeiro byte e so o primeiro opcode do programa, pode
  ; perfeitamente valer FEh (CP n) ou FFh (RST 38h) por coincidencia, e
  ; nesse caso a extensao e o unico sinal confiavel de que NAO e um
  ; BLOAD/BSAVE nem um tokenizado.
  If Ext = "com" And Size > 0
    *Info\TypeName = "Executavel MSX-DOS (.COM)"
    *Info\Lines = "Tamanho: " + Str(Size) + " bytes" + Chr(13) + Chr(10) +
                  "Formato: codigo de maquina Z80 cru, sem cabecalho (convencao MSX-DOS/CP-M)" + Chr(13) + Chr(10) +
                  "Endereco de carga e execucao: " + HexEd_Hex4($0100) + "h (fixo, todo .COM MSX-DOS carrega ai)"
    ProcedureReturn
  EndIf

  ; SuperCalc 2 MSX (.CAL) - assinatura de texto "SuperCalc ver." nos
  ; primeiros 14 bytes, confirmada identica byte-a-byte em 6 arquivos .CAL
  ; reais (sc2/msx/*.CAL, ver docs/reference/supercalc2-cal-format.md) -
  ; suficientemente longa e especifica pra nao precisar checar extensao.
  ; So reconhece o arquivo (assinatura + titulo + onde a secao de dados
  ; comeca) - o layout byte a byte de cada celula dentro da secao de dados
  ; ainda nao foi decifrado com confianca suficiente pra decodificar aqui.
  If Size >= 768
    Protected Sig.s = ""
    Protected SigIdx.i
    For SigIdx = 0 To 13
      Sig + Chr(Bytes(SigIdx) & $FF)
    Next

    If Sig = "SuperCalc ver."
      Protected Ver.s = ""
      Protected VerIdx.i = 16
      While VerIdx < Size And VerIdx < 22 And (Bytes(VerIdx) & $FF) <> 13 And (Bytes(VerIdx) & $FF) <> 10
        Ver + Chr(Bytes(VerIdx) & $FF)
        VerIdx + 1
      Wend

      Protected Title.s = ""
      Protected TitleIdx.i = $16
      Protected TitleEnd.i = $66
      If TitleEnd > Size : TitleEnd = Size : EndIf
      While TitleIdx < TitleEnd And (Bytes(TitleIdx) & $FF) <> 0
        Title + Chr(Bytes(TitleIdx) & $FF)
        TitleIdx + 1
      Wend
      If Title = "" : Title = "(sem titulo)" : EndIf

      *Info\TypeName = "Planilha SuperCalc 2 MSX (.CAL)"
      *Info\Lines = "Tamanho: " + Str(Size) + " bytes" + Chr(13) + Chr(10) +
                    "Assinatura: SuperCalc ver. " + Ver + Chr(13) + Chr(10) +
                    "Titulo: " + Title + Chr(13) + Chr(10) +
                    "Cabecalho fixo: offset 000000h a 0002FFh (768 bytes)" + Chr(13) + Chr(10) +
                    "Secao de dados: a partir de offset 000300h"
      ProcedureReturn
    EndIf
  EndIf

  ; Banco de dados dBase II (.DBF) - byte de tipo 02h checado JUNTO com a
  ; extensao (diferente da assinatura de 14 bytes do SuperCalc, um unico
  ; byte sozinho e fraco demais pra confiar sem a extensao tambem bater).
  ; Layout confirmado contra um .DBF real (ver docs/reference/dbase2-dbf-format.md):
  ; byte 0 = 02h, bytes 1-2 = num. de registros (LE), bytes 6-7 = tamanho
  ; do registro em bytes (LE, inclui o byte de flag de exclusao),
  ; descritores de campo de 16 bytes cada a partir do offset 8 (nome de 11
  ; bytes terminado em NUL + tipo (1 char: C/N/...) + tamanho (1 byte) + 3
  ; bytes reservados), ate 32 campos, terminados por 0Dh - dados sempre
  ; comecam no offset fixo 209h (8 + 32*16 + 1 = espaco reservado pra ate
  ; 32 descritores mesmo que menos campos existam de verdade).
  If Ext = "dbf" And Size >= 521 And b0 = $02
    Protected DbRecCount.i = (Bytes(1) & $FF) | ((Bytes(2) & $FF) << 8)
    Protected DbRecLen.i   = (Bytes(6) & $FF) | ((Bytes(7) & $FF) << 8)
    Protected DbFieldIdx.i, DbOff.i, DbFieldName.s, DbType.s, DbLen.i
    Protected DbNi.i, DbCh.i, FieldLines.s = "", DbFieldCount.i = 0

    For DbFieldIdx = 0 To 31
      DbOff = 8 + DbFieldIdx * 16
      If DbOff + 15 >= Size : Break : EndIf
      If (Bytes(DbOff) & $FF) = $0D : Break : EndIf

      DbFieldName = ""
      For DbNi = 0 To 10
        DbCh = Bytes(DbOff + DbNi) & $FF
        If DbCh = 0 : Break : EndIf
        DbFieldName + Chr(DbCh)
      Next
      DbType = Chr(Bytes(DbOff + 11) & $FF)
      DbLen  = Bytes(DbOff + 12) & $FF

      FieldLines + Chr(13) + Chr(10) + "  " + DbFieldName + " (" + DbType + ", " + Str(DbLen) + " bytes)"
      DbFieldCount + 1
    Next

    *Info\TypeName = "Banco de dados dBase II (.DBF)"
    *Info\Lines = "Tamanho: " + Str(Size) + " bytes" + Chr(13) + Chr(10) +
                  "Registros: " + Str(DbRecCount) + Chr(13) + Chr(10) +
                  "Tamanho do registro: " + Str(DbRecLen) + " bytes (1 byte de flag + campos)" + Chr(13) + Chr(10) +
                  "Secao de dados: a partir de offset 000209h" + Chr(13) + Chr(10) +
                  "Campos (" + Str(DbFieldCount) + "):" + FieldLines
    ProcedureReturn
  EndIf

  ; Alfabeto Graphos III (.ALF) - formato JA CONHECIDO (nao precisou de
  ; engenharia reversa nesta sessao, ver editor/GraphosNativeIO.pbi/
  ; CharsetEditorGui.pbi, modulo 4/14i): cabecalho BSAVE FEh + 2048 bytes
  ; de dados (256 caracteres x 8 bytes, Pattern Generator Table de SCREEN
  ; 1). Validado contra os 781 arquivos .ALF reais deste repositorio
  ; (graphos/+graphos-IV/, harness descartavel) - achados dessa validacao
  ; em lote que NAO estavam documentados antes: (1) o endereco de inicio
  ; NEM SEMPRE e 9200h (ex.: LETR-*.ALF usa outros enderecos) - por isso
  ; aqui so exige DataSize=2048, sem travar em StartAddr fixo, diferente
  ; da galeria de templates generica (essa sim trava em 9200h, deliberado,
  ; ver HexEd_SeedDefaultTemplates); (2) uma minoria real de arquivos
  ; declara Fim=Inicio+2048 em vez do Fim=Inicio+2047 esperado (convencao
  ; "fim exclusivo" de outra ferramenta/versao, confirmada em 3 arquivos
  ; reais de conteudo diferente com o mesmo padrao de cabecalho) - por
  ; isso DataSize=2049 tambem e aceito. Arquivos sem cabecalho FEh (uma
  ; segunda variante rara vista em SHADOW/SOMBRA/TORTA/LETR-40.ALF etc.,
  ; comecando direto com dado ou ate texto ASCII) e arquivos truncados
  ; (menos de 2048 bytes de dados de verdade apesar do cabecalho declarar
  ; 2048) ficam de fora deliberadamente - formato desconhecido ou dado
  ; incompleto demais pra confiar.
  If Ext = "alf" And Size >= (7 + 2048) And b0 = $FE
    Protected AlfStart.i = (Bytes(1) & $FF) | ((Bytes(2) & $FF) << 8)
    Protected AlfEnd.i   = (Bytes(3) & $FF) | ((Bytes(4) & $FF) << 8)
    Protected AlfDataSize.i = AlfEnd - AlfStart + 1
    If AlfDataSize = 2048 Or AlfDataSize = 2049
      *Info\TypeName = "Alfabeto Graphos III (.ALF)"
      *Info\Lines = "Tamanho: " + Str(Size) + " bytes" + Chr(13) + Chr(10) +
                    "Cabecalho BLOAD/BSAVE: inicio " + HexEd_Hex4(AlfStart) + "h, fim " + HexEd_Hex4(AlfEnd) + "h" + Chr(13) + Chr(10) +
                    "256 caracteres x 8 bytes (fonte 8x8, Pattern Generator Table de SCREEN 1)"
      ProcedureReturn
    EndIf
  EndIf

  ; Layout Graphos III (.LAY) - formato JA CONHECIDO (ver
  ; editor/GraphosNativeIO.pbi, modulo 14i): cabecalho BSAVE FEh, inicio
  ; fixo 9200h, fim VARIAVEL (dados comprimidos). Dados = RLE restrito (so
  ; 00h/FFh) + ofuscacao (+99h mod 256 em cada byte). Validacao FORTE (nao
  ; so o cabecalho): decodifica os dados de verdade e confere que da
  ; EXATAMENTE 6144 bytes (tamanho fixo da Pattern Generator Table de
  ; SCREEN 2 completa) - um arquivo qualquer com esse cabecalho quase
  ; certamente NAO decodificaria pra esse tamanho exato por acaso.
  If Ext = "lay" And Size >= 7 And b0 = $FE
    Protected LayStart.i = (Bytes(1) & $FF) | ((Bytes(2) & $FF) << 8)
    Protected LayEnd.i   = (Bytes(3) & $FF) | ((Bytes(4) & $FF) << 8)
    Protected LayDataSize.i = LayEnd - LayStart + 1
    If LayStart = $9200 And LayDataSize > 0 And (7 + LayDataSize) <= Size
      ; Para assim que os 6144 bytes esperados forem decodificados, mesmo
      ; que sobrem bytes comprimidos nao consumidos - o campo "fim" do
      ; cabecalho (que define LayInEnd) nem sempre bate exatamente com o
      ; fim real dos dados uteis (mesma licao do .SCR abaixo: nao confiar
      ; cegamente no cabecalho). Consumir "ate acabar o input declarado"
      ; em vez de "ate ter 6144 bytes decodificados" fazia sobra de
      ; padding no final ser interpretada como mais um marcador RLE
      ; truncado, derrubando falsos negativos em arquivos reais validos.
      Protected LayPos.i = 7, LayIn.i, LayReal.i, LayRun.i, LayOutLen.i = 0
      Protected LayInEnd.i = 7 + LayDataSize
      Protected LayOk.b = #True
      While LayPos < LayInEnd And LayOutLen < #GraphosNative_TableSize
        LayIn = Bytes(LayPos) & $FF
        LayReal = (LayIn + $67) & $FF ; desfaz o +99h (mod 256) da ofuscacao
        LayPos + 1
        If LayReal = 0 Or LayReal = $FF
          If LayPos >= LayInEnd
            LayOk = #False : Break
          EndIf
          LayRun = Bytes(LayPos) & $FF
          LayPos + 1
          LayOutLen + LayRun
        Else
          LayOutLen + 1
        EndIf
      Wend
      If LayOk And LayOutLen = #GraphosNative_TableSize
        *Info\TypeName = "Layout Graphos III (.LAY)"
        *Info\Lines = "Tamanho: " + Str(Size) + " bytes" + Chr(13) + Chr(10) +
                      "Cabecalho BLOAD/BSAVE: inicio " + HexEd_Hex4($9200) + "h, fim " + HexEd_Hex4(LayEnd) + "h" + Chr(13) + Chr(10) +
                      "Dados comprimidos: " + Str(LayDataSize) + " bytes (RLE restrito 00h/FFh + ofuscacao +99h)" + Chr(13) + Chr(10) +
                      "Decodificado: " + Str(LayOutLen) + " bytes (confere - Pattern Generator Table de SCREEN 2 completa)"
        ProcedureReturn
      EndIf
    EndIf
  EndIf

  ; Tela Graphos III (.SCR) - formato JA CONHECIDO (ver
  ; editor/GraphosNativeIO.pbi, modulo 14i): cabecalho BSAVE FEh + rotina
  ; de apresentacao Z80 de TAMANHO VARIAVEL (129 ou 121 bytes nas amostras
  ; reais estudadas, ha outras variantes possiveis) + 12288 bytes fixos de
  ; padrao+cor (Pattern Generator Table + Color Table de SCREEN 2
  ; completas). O campo "fim" do cabecalho nem sempre bate com o tamanho
  ; real do arquivo (amostras truncadas/copiadas de disquete de forma
  ; imperfeita) - por isso a validacao usa o TAMANHO REAL DO ARQUIVO, nao
  ; o cabecalho, exatamente como GraphosNative_LoadScr ja faz.
  If Ext = "scr" And Size >= (7 + #GraphosNative_TableSize * 2) And b0 = $FE
    Protected ScrProgLen.i = Size - 7 - #GraphosNative_TableSize * 2
    *Info\TypeName = "Tela Graphos III (.SCR)"
    *Info\Lines = "Tamanho: " + Str(Size) + " bytes" + Chr(13) + Chr(10) +
                  "Cabecalho BLOAD/BSAVE (FEh)" + Chr(13) + Chr(10) +
                  "Rotina de apresentacao Z80: " + Str(ScrProgLen) + " bytes (descartada na leitura, nao interpretada)" + Chr(13) + Chr(10) +
                  "Padrao + cor: " + Str(#GraphosNative_TableSize * 2) + " bytes (SCREEN 2 completa, 3 tercos x 256 tiles x 8 bytes cada plano)"
    ProcedureReturn
  EndIf

  ; Banco de shapes Graphos III (.SHP) - formato JA CONHECIDO (ver
  ; editor/GraphosNativeIO.pbi, modulo 14i) mas SEM cabecalho BLOAD/BSAVE -
  ; por isso passava batido nos outros formatos e caia direto em "binario
  ; desconhecido". Estrutura propria: sequencia de blocos [K numero do
  ; shape 1-254][T tipo][S largura em pixels][H altura em tiles 8x8][dados
  ; - S*H bytes por "plano", 1/2/2/3 planos conforme o tipo 1/2/3/4],
  ; terminada por um byte K=FFh sozinho. Validacao percorre a cadeia de
  ; blocos INTEIRA (mesmo algoritmo de GraphosNative_ScanShpFile, so que
  ; sobre Bytes()/Size em vez de arquivo) - so reconhece se a cadeia for
  ; bem formada do inicio ao fim E terminar exatamente no FFh (nao em EOF
  ; por acaso), com pelo menos 1 shape - proteção contra falso positivo,
  ; ja que o byte K sozinho (1-254) e' uma assinatura fraca sem isso.
  If Ext = "shp" And Size >= 4
    Protected ShpPos.i = 0, ShpCount.i = 0, ShpOk.b = #False
    Protected ShpK.i, ShpT.i, ShpS.i, ShpH.i, ShpPlaneSize.i, ShpSkip.i, ShpNext.i
    While ShpPos < Size
      ShpK = Bytes(ShpPos) & $FF
      If ShpK = $FF
        If ShpCount >= 1 : ShpOk = #True : EndIf
        Break
      EndIf
      If ShpK = 0 Or ShpPos + 3 >= Size
        Break
      EndIf
      ShpT = Bytes(ShpPos + 1) & $FF
      ShpS = Bytes(ShpPos + 2) & $FF
      ShpH = Bytes(ShpPos + 3) & $FF
      If ShpS = 0 Or (ShpS % 8) <> 0 Or ShpH = 0
        Break
      EndIf
      ShpPlaneSize = ShpS * ShpH
      Select ShpT
        Case 1 : ShpSkip = ShpPlaneSize
        Case 3 : ShpSkip = ShpPlaneSize * 2
        Case 4 : ShpSkip = ShpPlaneSize * 3
        Default : ShpSkip = ShpPlaneSize * 2 ; tipo 2 (padrao+cor), tambem fallback de tipo desconhecido
      EndSelect
      ShpNext = ShpPos + 4 + ShpSkip
      If ShpNext > Size
        Break
      EndIf
      ShpCount + 1
      ShpPos = ShpNext
    Wend

    If ShpOk
      *Info\TypeName = "Banco de shapes Graphos III (.SHP)"
      *Info\Lines = "Tamanho: " + Str(Size) + " bytes" + Chr(13) + Chr(10) +
                    "Sem cabecalho BLOAD/BSAVE (estrutura propria de blocos)" + Chr(13) + Chr(10) +
                    "Shapes no banco: " + Str(ShpCount) + Chr(13) + Chr(10) +
                    "Terminador FFh: offset " + HexEd_Hex6(ShpPos) + "h"
      ProcedureReturn
    EndIf
  EndIf

  If b0 = $FE And Size >= 7
    StartAddr = (Bytes(1) & $FF) | ((Bytes(2) & $FF) << 8)
    EndAddr   = (Bytes(3) & $FF) | ((Bytes(4) & $FF) << 8)
    ExecAddr  = (Bytes(5) & $FF) | ((Bytes(6) & $FF) << 8)
    DataSize  = EndAddr - StartAddr + 1
    TplName   = HexEd_MatchTemplate(Ext, b0, StartAddr, DataSize)

    If TplName <> ""
      *Info\TypeName = TplName + " (binario MSX BLOAD/BSAVE)"
    Else
      *Info\TypeName = "Binario MSX (BLOAD/BSAVE, cabecalho FEh)"
    EndIf
    *Info\Lines = "Tamanho: " + Str(Size) + " bytes" + Chr(13) + Chr(10) +
                  "Byte de tipo: " + HexEd_Hex2($FE) + "h (binario)" + Chr(13) + Chr(10) +
                  "Endereco inicial: " + HexEd_Hex4(StartAddr) + "h" + Chr(13) + Chr(10) +
                  "Endereco final: " + HexEd_Hex4(EndAddr) + "h" + Chr(13) + Chr(10) +
                  "Endereco de execucao: " + HexEd_Hex4(ExecAddr) + "h" + Chr(13) + Chr(10) +
                  "Tamanho dos dados: " + Str(DataSize) + " bytes"
    If TplName <> ""
      *Info\Lines + Chr(13) + Chr(10) + "Template: " + TplName
    EndIf
    ProcedureReturn
  EndIf

  If b0 = $FF
    *Info\TypeName = "MSX-BASIC tokenizado"
    *Info\Lines = "Tamanho: " + Str(Size) + " bytes" + Chr(13) + Chr(10) +
                  "Byte de tipo: " + HexEd_Hex2($FF) + "h (tokenizado)" + Chr(13) + Chr(10) +
                  "Endereco de carga (convencao Badig): " + HexEd_Hex4($8001) + "h"
    If Size >= 5
      Protected NextLineAddr.i = (Bytes(1) & $FF) | ((Bytes(2) & $FF) << 8)
      Protected FirstLineNum.i = (Bytes(3) & $FF) | ((Bytes(4) & $FF) << 8)
      *Info\Lines + Chr(13) + Chr(10) +
                    "Primeira linha: numero " + Str(FirstLineNum) + ", proximo ponteiro " + HexEd_Hex4(NextLineAddr) + "h"
    EndIf
    ProcedureReturn
  EndIf

  For i = 0 To Size - 1
    Ch = Bytes(i) & $FF
    If Ch <> 9 And Ch <> 10 And Ch <> 13 And (Ch < 32 Or Ch > 126)
      Printable = #False
      Break
    EndIf
  Next
  If Printable
    If HexEd_LooksLikeBasicSource(Bytes(), Size)
      *Info\TypeName = "Basic MSX classico (ASCII, linhas numeradas)"
    Else
      *Info\TypeName = "Texto ASCII puro"
    EndIf
  Else
    *Info\TypeName = "Binario desconhecido / dados crus"
  EndIf
EndProcedure

Procedure.b HexEd_ConfirmDiscard()
  ProcedureReturn Bool(MessageRequester("Alteracoes nao salvas",
                        "Este arquivo tem bytes editados que ainda nao foram salvos." + Chr(10) +
                        "Descartar mesmo assim?",
                        #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
EndProcedure

Procedure.b HexEd_LoadFile(Path.s)
  Protected FileNum = ReadFile(#PB_Any, Path)
  If Not FileNum
    ProcedureReturn #False
  EndIf

  Protected FileLen.i = Lof(FileNum)
  If FileLen > #HexEd_MaxFileSize
    CloseFile(FileNum)
    MessageRequester("Arquivo grande demais",
                      "O arquivo tem " + Str(FileLen) + " bytes; o Editor Hexa aceita ate " +
                      Str(#HexEd_MaxFileSize) + " bytes.",
                      #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  If FileLen > 0
    ReDim HexEd_Bytes(FileLen - 1)
    ReadData(FileNum, @HexEd_Bytes(0), FileLen)
  Else
    ReDim HexEd_Bytes(0)
  EndIf
  CloseFile(FileNum)

  HexEd_Size  = FileLen
  HexEd_Path  = Path
  HexEd_Dirty = #False
  ProcedureReturn #True
EndProcedure

Procedure.b HexEd_SaveFile(Path.s)
  Protected FileNum = CreateFile(#PB_Any, Path)
  If Not FileNum
    ProcedureReturn #False
  EndIf
  If HexEd_Size > 0
    WriteData(FileNum, @HexEd_Bytes(0), HexEd_Size)
  EndIf
  CloseFile(FileNum)
  ProcedureReturn #True
EndProcedure

; MaxLen limita a quantidade de digitos aceitos (2 pra byte, 4 pra endereco,
; 8 pra offset de arquivo grande).
Procedure.b HexEd_IsHexString(s.s, MaxLen.i)
  Protected i
  If Len(s) < 1 Or Len(s) > MaxLen
    ProcedureReturn #False
  EndIf
  For i = 1 To Len(s)
    If FindString("0123456789ABCDEFabcdef", Mid(s, i, 1)) = 0
      ProcedureReturn #False
    EndIf
  Next
  ProcedureReturn #True
EndProcedure

Procedure.i HexEd_TotalRows()
  If HexEd_Size <= 0
    ProcedureReturn 0
  EndIf
  ProcedureReturn (HexEd_Size + #HexEd_BytesPerRow - 1) / #HexEd_BytesPerRow
EndProcedure

;- ------------------------------------------------------------
;- Desenho da grade hexadecimal
;- ------------------------------------------------------------

; Desenha uma linha (16 bytes) dentro de um StartDrawing() ja aberto pelo
; chamador - endereco, os 16 bytes em hex (grupo de 8+8) e a coluna ASCII.
; O byte selecionado (cursor) ganha uma borda na cor de destaque
; (Color_Accent) por cima do preenchimento de selecao, bem mais visivel que
; so o preenchimento; bytes dentro do intervalo marcado (Marcar inicio/fim)
; ganham um preenchimento mais suave (RangeTint, sem borda) pra distinguir
; "cursor atual" de "intervalo marcado para operacao de bloco". A linha
; inteira que contem cursor OU intervalo tem o endereco pintado na cor de
; destaque, pra achar a linha de longe mesmo com a grade rolada.
Procedure HexEd_PaintRow(RowY.i, Off.i, Sel.i, RangeStart.i, RangeEnd.i, RangeTint.l, HexX.i, AsciiX.i, CW.i, RowH.i, HalfCW.i)
  Protected i, val, bx, ax, ch, InRange.b
  Protected RowHasSel.b = Bool((Sel >= Off And Sel < Off + #HexEd_BytesPerRow) Or
                                (RangeStart >= 0 And RangeEnd >= Off And RangeStart < Off + #HexEd_BytesPerRow))
  Protected AddrColor = Color_TextInactive
  If RowHasSel
    AddrColor = Color_Accent
  EndIf
  DrawText(0, RowY, RSet(Hex(Off), 6, "0") + ":", AddrColor, Color_EditorBg)

  For i = 0 To #HexEd_BytesPerRow - 1
    If Off + i >= HexEd_Size
      Break
    EndIf
    val = HexEd_Bytes(Off + i) & $FF
    bx = HexX + i * HalfCW * 3
    If i >= 8
      bx + CW
    EndIf
    InRange = Bool(RangeStart >= 0 And Off + i >= RangeStart And Off + i <= RangeEnd)
    If Off + i = Sel
      Box(bx - 3, RowY - 1, CW + 4, RowH + 1, Color_Accent)
      Box(bx - 1, RowY, CW, RowH - 2, Color_SelBack)
    ElseIf InRange
      Box(bx - 1, RowY, CW, RowH - 2, RangeTint)
    EndIf
    DrawText(bx, RowY, HexEd_Hex2(val), Color_TextActive, Color_EditorBg)
  Next

  For i = 0 To #HexEd_BytesPerRow - 1
    If Off + i >= HexEd_Size
      Break
    EndIf
    val = HexEd_Bytes(Off + i) & $FF
    If val >= 32 And val <= 126
      ch = val
    Else
      ch = 46 ; "."
    EndIf
    ax = AsciiX + i * HalfCW
    InRange = Bool(RangeStart >= 0 And Off + i >= RangeStart And Off + i <= RangeEnd)
    If Off + i = Sel
      Box(ax - 2, RowY - 1, HalfCW + 3, RowH + 1, Color_Accent)
      Box(ax, RowY, HalfCW - 1, RowH - 2, Color_SelBack)
    ElseIf InRange
      Box(ax, RowY, HalfCW - 1, RowH - 2, RangeTint)
    EndIf
    DrawText(ax, RowY, Chr(ch), Color_TextActive, Color_EditorBg)
  Next
EndProcedure

Procedure HexEd_Repaint(Canvas.i, ScrollTop.i, Sel.i, RangeStart.i, RangeEnd.i, HexX.i, AsciiX.i, CW.i, RowH.i, HalfCW.i, Font.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  DrawingFont(FontID(Font))
  Box(0, 0, GadgetWidth(Canvas), GadgetHeight(Canvas), Color_EditorBg)
  Protected RangeTint = RGB((Red(Color_EditorBg) * 2 + Red(Color_Accent)) / 3,
                            (Green(Color_EditorBg) * 2 + Green(Color_Accent)) / 3,
                            (Blue(Color_EditorBg) * 2 + Blue(Color_Accent)) / 3)
  Protected r, off
  For r = 0 To #HexEd_VisibleRows - 1
    off = (ScrollTop + r) * #HexEd_BytesPerRow
    If off >= HexEd_Size
      Break
    EndIf
    HexEd_PaintRow(r * RowH, off, Sel, RangeStart, RangeEnd, RangeTint, HexX, AsciiX, CW, RowH, HalfCW)
  Next
  StopDrawing()
EndProcedure

Procedure HexEd_RefreshHeader(PathLabel.i, InfoTitle.i, InfoGad.i)
  Protected Info.HexEd_Info
  If HexEd_Path = ""
    SetGadgetText(PathLabel, "(nenhum arquivo aberto)")
  ElseIf HexEd_Dirty
    SetGadgetText(PathLabel, HexEd_Path + " *")
  Else
    SetGadgetText(PathLabel, HexEd_Path)
  EndIf
  HexEd_DescribeFile(HexEd_Bytes(), HexEd_Size, HexEd_Path, @Info)
  SetGadgetText(InfoTitle, "Tipo de arquivo: " + Info\TypeName)
  SetGadgetText(InfoGad, Info\Lines)
EndProcedure

;- ------------------------------------------------------------
;- Barra de rolagem vertical customizada. O ScrollBarGadget nativo aqui
;- renderizava enorme/esticado e com os botoes trocados (esquerda subia,
;- direita descia) - trocado por dois ButtonImageGadget tradicionais
;- (seta pra cima/baixo, reaproveitando CharEd_DrawFilledVTri de
;- CharsetEditorGui.pbi) mais um CanvasGadget no meio desenhando uma
;- trilha com um "thumb" proporcional (tamanho = fracao visivel do
;- arquivo, posicao = fracao ja rolada), igual barra de rolagem
;- tradicional de qualquer editor.
;- ------------------------------------------------------------

Procedure HexEd_CreateArrowIcon(Size.i, PointUp.b)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, Color_TabInactive)
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, Color_TabInactive)
    Protected Cx = Size / 2, Half = Size / 2 - 4
    If PointUp
      CharEd_DrawFilledVTri(Cx, Size - 4, 4, Half, Color_TextActive)
    Else
      CharEd_DrawFilledVTri(Cx, 4, Size - 4, Half, Color_TextActive)
    EndIf
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Botoes tematizados: ver ThemedButtons.pbi (Macro ThemedButton(), constantes
; #Icon_*) - generalizado pra la a partir do que nasceu aqui (v7.31.3).

Procedure HexEd_PaintTrack(Canvas.i, ScrollTop.i, TotalRows.i, VisibleRows.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected W = GadgetWidth(Canvas), H = GadgetHeight(Canvas)
  Box(0, 0, W, H, Color_EditorBg)
  Box(0, 0, W, 1, Color_TextInactive)
  Box(0, H - 1, W, 1, Color_TextInactive)
  Box(0, 0, 1, H, Color_TextInactive)
  Box(W - 1, 0, 1, H, Color_TextInactive)

  Protected ThumbH, ThumbY, MaxTop
  If TotalRows <= VisibleRows Or TotalRows <= 0
    ThumbH = H - 4
    ThumbY = 2
  Else
    ThumbH = H * VisibleRows / TotalRows
    If ThumbH < 16 : ThumbH = 16 : EndIf
    If ThumbH > H - 4 : ThumbH = H - 4 : EndIf
    MaxTop = TotalRows - VisibleRows
    If MaxTop > 0
      ThumbY = 2 + (H - 4 - ThumbH) * ScrollTop / MaxTop
    Else
      ThumbY = 2
    EndIf
  EndIf
  Box(2, ThumbY, W - 4, ThumbH, Color_Accent)
  StopDrawing()
EndProcedure

;- ------------------------------------------------------------
;- Intervalo marcado (Marcar inicio/fim) e operacoes de bloco (Preencher,
;- Inserir, Sobrepor, Excluir) - se nao houver intervalo marcado, cada
;- operacao pede endereco inicial/final (ou so a posicao, no caso de
;- Inserir/Sobrepor) por InputRequester, mesmo padrao ja usado em
;- EditorSearch.pbi (Ir para linha/Buscar).
;- ------------------------------------------------------------

Procedure.s HexEd_RangeText(S.i, E.i)
  If S < 0 Or E < 0
    ProcedureReturn "Selecao: (nenhuma - clique um byte e use Marcar inicio/fim)"
  EndIf
  ProcedureReturn "Selecao: " + HexEd_Hex6(S) + "h - " + HexEd_Hex6(E) + "h (" + Str(E - S + 1) + " byte(s))"
EndProcedure

; Usa o intervalo marcado se for valido; senao pergunta inicio/fim. Escreve
; o resultado em OutStartAddr/OutEndAddr (enderecos de variaveis Integer do
; chamador, via @Var) - devolve #False se o usuario cancelou ou nao ha
; arquivo aberto.
Procedure.b HexEd_ResolveRange(ParentWin.i, CurStart.i, CurEnd.i, OutStartAddr.i, OutEndAddr.i)
  If CurStart >= 0 And CurEnd >= 0 And CurStart <= CurEnd And CurEnd < HexEd_Size
    PokeI(OutStartAddr, CurStart)
    PokeI(OutEndAddr, CurEnd)
    ProcedureReturn #True
  EndIf

  If HexEd_Size <= 0
    MessageRequester("Selecao", "Abra um arquivo primeiro.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  Protected StartText.s = InputRequester("Intervalo de bytes", "Endereco inicial (hex, offset no arquivo):",
                                          "0", 0, WindowID(ParentWin))
  If StartText = ""
    ProcedureReturn #False
  EndIf
  If Not HexEd_IsHexString(StartText, 8)
    MessageRequester("Erro", "Endereco inicial invalido.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  Protected EndText.s = InputRequester("Intervalo de bytes", "Endereco final (hex, offset no arquivo, inclusive):",
                                        HexEd_Hex6(HexEd_Size - 1), 0, WindowID(ParentWin))
  If EndText = ""
    ProcedureReturn #False
  EndIf
  If Not HexEd_IsHexString(EndText, 8)
    MessageRequester("Erro", "Endereco final invalido.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  Protected S.i = Val("$" + StartText)
  Protected E.i = Val("$" + EndText)
  If S > E
    Swap S, E
  EndIf
  If S < 0 : S = 0 : EndIf
  If E >= HexEd_Size : E = HexEd_Size - 1 : EndIf
  If S > E
    MessageRequester("Erro", "Intervalo invalido.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  PokeI(OutStartAddr, S)
  PokeI(OutEndAddr, E)
  ProcedureReturn #True
EndProcedure

; Posicao unica (pra Inserir/Sobrepor) - hex, 0 a HexEd_Size (inclusive,
; onde "= Size" significa "no fim do arquivo").
Procedure.i HexEd_PromptPosition(ParentWin.i, Title.s, DefaultPos.i)
  Protected PosText.s = InputRequester(Title,
                          "Posicao (hex, offset no arquivo, 0 a " + HexEd_Hex6(HexEd_Size) + "h):",
                          HexEd_Hex6(DefaultPos), 0, WindowID(ParentWin))
  If PosText = ""
    ProcedureReturn -1
  EndIf
  If Not HexEd_IsHexString(PosText, 8)
    MessageRequester("Erro", "Posicao invalida.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    ProcedureReturn -1
  EndIf
  Protected P.i = Val("$" + PosText)
  If P < 0 : P = 0 : EndIf
  If P > HexEd_Size : P = HexEd_Size : EndIf
  ProcedureReturn P
EndProcedure

; Preenche HexEd_ClipBytes()/HexEd_ClipSize a partir de outro arquivo
; (inteiro) ou de bytes em branco (quantidade + valor escolhidos pelo
; usuario) - usado por Inserir bloco e Sobrepor bloco.
Procedure.b HexEd_PromptBlockSource(ParentWin.i)
  Protected Choice = MessageRequester("Origem dos dados",
                        "Trazer os bytes de outro arquivo?" + Chr(10) + Chr(10) +
                        "Sim = escolher um arquivo inteiro." + Chr(10) +
                        "Nao = bytes em branco (voce escolhe quantidade e valor)." + Chr(10) +
                        "Cancelar = desistir da operacao.",
                        #PB_MessageRequester_YesNoCancel)

  If Choice = #PB_MessageRequester_Cancel
    ProcedureReturn #False

  ElseIf Choice = #PB_MessageRequester_Yes
    Protected SrcPath.s = OpenFileRequester("Escolher arquivo de origem", "", #HexEd_FilePattern, 0)
    If SrcPath = ""
      ProcedureReturn #False
    EndIf
    Protected FileNum = ReadFile(#PB_Any, SrcPath)
    If Not FileNum
      MessageRequester("Erro", "Nao foi possivel ler:" + Chr(10) + SrcPath, #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
      ProcedureReturn #False
    EndIf
    Protected SrcLen.i = Lof(FileNum)
    If SrcLen <= 0 Or SrcLen > #HexEd_MaxFileSize
      CloseFile(FileNum)
      MessageRequester("Erro", "Arquivo vazio ou grande demais.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
      ProcedureReturn #False
    EndIf
    ReDim HexEd_ClipBytes(SrcLen - 1)
    ReadData(FileNum, @HexEd_ClipBytes(0), SrcLen)
    CloseFile(FileNum)
    HexEd_ClipSize = SrcLen
    ProcedureReturn #True

  Else ; No -> bytes em branco
    Protected CountText.s = InputRequester("Bytes em branco", "Quantidade de bytes:", "16", 0, WindowID(ParentWin))
    If CountText = ""
      ProcedureReturn #False
    EndIf
    Protected Count.i = Val(CountText)
    If Count <= 0 Or Count > #HexEd_MaxFileSize
      MessageRequester("Erro", "Quantidade invalida.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
      ProcedureReturn #False
    EndIf
    Protected ValText.s = InputRequester("Bytes em branco", "Valor (hex) para preencher:", "00", 0, WindowID(ParentWin))
    If ValText = "" Or Not HexEd_IsHexString(ValText, 2)
      ProcedureReturn #False
    EndIf
    Protected FillVal.i = Val("$" + ValText) & $FF
    ReDim HexEd_ClipBytes(Count - 1)
    Protected ci
    For ci = 0 To Count - 1
      HexEd_ClipBytes(ci) = FillVal
    Next
    HexEd_ClipSize = Count
    ProcedureReturn #True
  EndIf
EndProcedure

; Insere HexEd_ClipBytes() na posicao Pos, deslocando tudo que vem depois
; pra frente (o arquivo cresce ClipSize bytes).
Procedure HexEd_InsertBlockAt(Pos.i)
  Protected OldSize = HexEd_Size
  Protected C = HexEd_ClipSize
  Protected NewSize = OldSize + C
  Protected i
  ReDim HexEd_Bytes(NewSize - 1)
  For i = OldSize - 1 To Pos Step -1
    HexEd_Bytes(i + C) = HexEd_Bytes(i)
  Next
  For i = 0 To C - 1
    HexEd_Bytes(Pos + i) = HexEd_ClipBytes(i)
  Next
  HexEd_Size = NewSize
  HexEd_Dirty = #True
EndProcedure

; Sobrescreve a partir da posicao Pos com HexEd_ClipBytes() SEM deslocar o
; que ja existe depois - so cresce o arquivo se o bloco passar do fim atual.
Procedure HexEd_OverwriteBlockAt(Pos.i)
  Protected C = HexEd_ClipSize
  Protected NewSize = HexEd_Size
  If Pos + C > NewSize
    NewSize = Pos + C
  EndIf
  If NewSize > HexEd_Size
    ReDim HexEd_Bytes(NewSize - 1)
  EndIf
  Protected i
  For i = 0 To C - 1
    HexEd_Bytes(Pos + i) = HexEd_ClipBytes(i)
  Next
  HexEd_Size = NewSize
  HexEd_Dirty = #True
EndProcedure

; Remove [Start,End] de verdade, deslocando o restante pra tras (o arquivo
; encolhe).
Procedure HexEd_DeleteRangeShift(Start.i, LastPos.i)
  Protected L = LastPos - Start + 1
  Protected OldSize = HexEd_Size
  Protected NewSize = OldSize - L
  Protected i
  For i = LastPos + 1 To OldSize - 1
    HexEd_Bytes(i - L) = HexEd_Bytes(i)
  Next
  If NewSize > 0
    ReDim HexEd_Bytes(NewSize - 1)
  Else
    ReDim HexEd_Bytes(0)
  EndIf
  HexEd_Size = NewSize
  HexEd_Dirty = #True
EndProcedure

; Sobrescreve [Start,LastPos] com 00 no lugar - tamanho do arquivo nao muda.
Procedure HexEd_DeleteRangeZero(Start.i, LastPos.i)
  Protected i
  For i = Start To LastPos
    HexEd_Bytes(i) = 0
  Next
  HexEd_Dirty = #True
EndProcedure

;- ------------------------------------------------------------
;- Galeria de templates (janela propria, filha da janela do Editor Hexa)
;- ------------------------------------------------------------

Procedure HexEd_RefillTemplateList(ListGad.i)
  ClearGadgetItems(ListGad)
  ForEach HexEd_Templates()
    Protected Row.s = HexEd_Templates()\Name + Chr(10) +
                       HexEd_Templates()\Ext + Chr(10)
    If HexEd_Templates()\FirstByte = -1
      Row + "-" + Chr(10)
    Else
      Row + HexEd_Hex2(HexEd_Templates()\FirstByte) + "h" + Chr(10)
    EndIf
    If HexEd_Templates()\StartAddr = -1
      Row + "-" + Chr(10)
    Else
      Row + HexEd_Hex4(HexEd_Templates()\StartAddr) + "h" + Chr(10)
    EndIf
    If HexEd_Templates()\DataSize = -1
      Row + "-"
    Else
      Row + Str(HexEd_Templates()\DataSize)
    EndIf
    AddGadgetItem(ListGad, -1, Row)
  Next
EndProcedure

Procedure HexEd_OpenTemplateGallery(ParentWindow)
  Protected WinW = 620, WinH = 420
  Protected LeftX = 15, TopY = 15

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Galeria de templates - Editor Hexa",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  Protected G_List = ListIconGadget(#PB_Any, LeftX, TopY, WinW - 2 * LeftX, 220, "Nome", 220,
                                     #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  AddGadgetColumn(G_List, 1, "Extensao", 70)
  AddGadgetColumn(G_List, 2, "Byte", 60)
  AddGadgetColumn(G_List, 3, "Endereco", 80)
  AddGadgetColumn(G_List, 4, "Tamanho (dados)", 130)
  HexEd_RefillTemplateList(G_List)

  Protected FormY = TopY + 230
  TextGadget(#PB_Any, LeftX, FormY, 240, 20, "Nome:")
  Protected G_Name = StringGadget(#PB_Any, LeftX, FormY + 18, 240, 22, "")

  TextGadget(#PB_Any, LeftX + 250, FormY, 60, 20, "Ext.:")
  Protected G_Ext = StringGadget(#PB_Any, LeftX + 250, FormY + 18, 60, 22, "")
  GadgetToolTip(G_Ext, "Extensao sem ponto (ex.: alf) - em branco = qualquer")

  TextGadget(#PB_Any, LeftX + 320, FormY, 70, 20, "Byte (hex):")
  Protected G_Byte = StringGadget(#PB_Any, LeftX + 320, FormY + 18, 70, 22, "", #PB_String_UpperCase)
  GadgetToolTip(G_Byte, "Primeiro byte do arquivo, em hexadecimal (ex.: FE) - em branco = qualquer")

  TextGadget(#PB_Any, LeftX + 400, FormY, 90, 20, "Endereco (hex):")
  Protected G_Addr = StringGadget(#PB_Any, LeftX + 400, FormY + 18, 90, 22, "", #PB_String_UpperCase)
  GadgetToolTip(G_Addr, "Endereco inicial do cabecalho BLOAD/BSAVE, em hexadecimal (ex.: 9200) - em branco = qualquer")

  TextGadget(#PB_Any, LeftX + 500, FormY, 100, 20, "Tamanho (dados):")
  Protected G_Size = StringGadget(#PB_Any, LeftX + 500, FormY + 18, 100, 22, "")
  GadgetToolTip(G_Size, "Tamanho dos dados (fim - inicio + 1), em bytes decimais - em branco = qualquer")

  Protected ButtonY = FormY + 50
  Protected G_Add = ThemedButton(LeftX, ButtonY, 140, 26, "Adicionar", Chr(#Icon_Add))
  GadgetToolTip(G_Add, "Adicionar")
  Protected G_Remove = ThemedButton(LeftX + 150, ButtonY, 160, 26, "Remover selecionado", Chr(#Icon_Remove))
  GadgetToolTip(G_Remove, "Remover selecionado")
  Protected G_Status = TextGadget(#PB_Any, LeftX + 320, ButtonY + 4, WinW - LeftX - 320 - 100, 20, "")
  Protected G_Close = ThemedButton(WinW - LeftX - 90, ButtonY, 90, 26, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  Protected TplEvent, Quit.b = #False
  Protected NewByte.i, NewAddr.i, NewSize.i, Sel.i, ByteText.s, AddrText.s, SizeText.s

  Repeat
    TplEvent = WaitWindowEvent()

    Select TplEvent
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_Add
            If Trim(GetGadgetText(G_Name)) = ""
              SetGadgetText(G_Status, "Informe um nome para o template.")
            Else
              ByteText = Trim(GetGadgetText(G_Byte))
              AddrText = Trim(GetGadgetText(G_Addr))
              SizeText = Trim(GetGadgetText(G_Size))

              If ByteText <> "" And Not HexEd_IsHexString(ByteText, 2)
                SetGadgetText(G_Status, "Byte invalido - use ate 2 digitos hexadecimais, ou deixe em branco.")
              ElseIf AddrText <> "" And Not HexEd_IsHexString(AddrText, 4)
                SetGadgetText(G_Status, "Endereco invalido - use ate 4 digitos hexadecimais, ou deixe em branco.")
              ElseIf SizeText <> "" And Not Val(SizeText) > 0
                SetGadgetText(G_Status, "Tamanho invalido - use um numero decimal maior que zero, ou deixe em branco.")
              Else
                If ByteText = "" : NewByte = -1 : Else : NewByte = Val("$" + ByteText) : EndIf
                If AddrText = "" : NewAddr = -1 : Else : NewAddr = Val("$" + AddrText) : EndIf
                If SizeText = "" : NewSize = -1 : Else : NewSize = Val(SizeText) : EndIf

                AddElement(HexEd_Templates())
                HexEd_Templates()\Name      = Trim(GetGadgetText(G_Name))
                HexEd_Templates()\Ext       = LCase(Trim(GetGadgetText(G_Ext)))
                HexEd_Templates()\FirstByte = NewByte
                HexEd_Templates()\StartAddr = NewAddr
                HexEd_Templates()\DataSize  = NewSize
                HexEd_SaveTemplates()
                HexEd_RefillTemplateList(G_List)

                SetGadgetText(G_Name, "")
                SetGadgetText(G_Ext, "")
                SetGadgetText(G_Byte, "")
                SetGadgetText(G_Addr, "")
                SetGadgetText(G_Size, "")
                SetGadgetText(G_Status, "Template adicionado.")
              EndIf
            EndIf

          Case G_Remove
            Sel = GetGadgetState(G_List)
            If Sel < 0
              SetGadgetText(G_Status, "Selecione um template na lista primeiro.")
            Else
              If SelectElement(HexEd_Templates(), Sel)
                DeleteElement(HexEd_Templates())
                HexEd_SaveTemplates()
                HexEd_RefillTemplateList(G_List)
                SetGadgetText(G_Status, "Template removido.")
              EndIf
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

;- ------------------------------------------------------------
;- Janela principal do Editor Hexa
;- ------------------------------------------------------------

Procedure HexEditor_OpenWindow(ParentWindow)
  HexEd_LoadTemplates()

  Protected LeftX = 15, TopY = 15
  Protected InfoW = 300
  Protected CanvasX = LeftX + InfoW + 20
  Protected Row2Y = TopY + 34   ; barra de operacoes de bloco
  Protected Row3Y = Row2Y + 34  ; rotulo do intervalo marcado
  Protected CanvasY = Row3Y + 30

  Protected HexFont = LoadFont(#PB_Any, "Consolas", 10)
  If Not HexFont
    HexFont = LoadFont(#PB_Any, "Courier New", 10)
  EndIf

  ; Mede a fonte monoespacada num bitmap temporario pra descobrir a grade de
  ; colunas antes de abrir a janela (a largura da janela depende disso).
  Protected CharW, CharH
  Protected MeasureImg = CreateImage(#PB_Any, 10, 10)
  If MeasureImg And StartDrawing(ImageOutput(MeasureImg))
    DrawingFont(FontID(HexFont))
    CharW = TextWidth("00")
    CharH = TextHeight("0") + 2
    StopDrawing()
  EndIf
  If MeasureImg
    FreeImage(MeasureImg)
  EndIf
  If CharW <= 0 : CharW = 16 : EndIf
  If CharH <= 0 : CharH = 16 : EndIf
  Protected HalfCharW = CharW / 2
  If HalfCharW <= 0 : HalfCharW = 8 : EndIf

  ; Mesma formula usada em HexEd_PaintRow/hit-test: endereco "000000:" (7
  ; chars) + 1 char de folga, depois 16 bytes de 1.5 char cada (2 digitos +
  ; espaco) com 1 char extra de folga no meio (grupo de 8+8), depois 2 chars
  ; de folga e a coluna ASCII (16 chars) + margem direita.
  Protected HexColX   = 8 * HalfCharW
  Protected AsciiColX = HexColX + 49 * HalfCharW + 2 * HalfCharW
  Protected CanvasW   = AsciiColX + #HexEd_BytesPerRow * HalfCharW + 2 * HalfCharW
  Protected CanvasH   = #HexEd_VisibleRows * CharH

  Protected ScrollBtnH = 22
  Protected ScrollW = 22
  Protected ScrollX = CanvasX + CanvasW + 4
  Protected EditBarY = CanvasY + CanvasH + 12

  ; Largura da barra de operacoes de bloco (7 botoes) - a janela precisa ser
  ; larga o bastante pra ela tambem, nao so pra grade/canvas.
  Protected Row2Width = 110 + 6 + 100 + 6 + 120 + 16 + 110 + 6 + 140 + 6 + 150 + 6 + 140

  Protected WinW = ScrollX + ScrollW + 15
  If LeftX + Row2Width + 15 > WinW
    WinW = LeftX + Row2Width + 15
  EndIf
  Protected WinH = EditBarY + 3 * 30 + 15

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Editor Hexa MSX",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  Protected G_Open = ThemedButton(LeftX, TopY, 110, 26, "Abrir arquivo...", Chr(#Icon_Open))
  GadgetToolTip(G_Open, "Abrir arquivo...")
  Protected G_Save = ThemedButton(LeftX + 116, TopY, 80, 26, "Salvar", Chr(#Icon_Save))
  GadgetToolTip(G_Save, "Salvar")
  Protected G_SaveAs = ThemedButton(LeftX + 202, TopY, 120, 26, "Salvar como...", Chr(#Icon_SaveAs))
  GadgetToolTip(G_SaveAs, "Salvar como...")
  Protected G_Templates = ThemedButton(LeftX + 328, TopY, 160, 26, "Galeria de templates...", Chr(#Icon_Gallery))
  GadgetToolTip(G_Templates, "Galeria de templates...")
  Protected G_PathLabel = TextGadget(#PB_Any, LeftX + 494, TopY + 5, CanvasX + CanvasW - LeftX - 494, 20,
                                     "(nenhum arquivo aberto)")

  ; Barra de operacoes de bloco - Marcar inicio/fim define o intervalo que
  ; Preencher/Inserir/Sobrepor/Excluir usam; sem intervalo marcado, cada uma
  ; pergunta endereco/posicao na hora.
  Protected Cx = LeftX
  Protected G_MarkStart = ThemedButton(Cx, Row2Y, 110, 26, "Marcar inicio", Chr(#Icon_Flag))
  Cx + 110 + 6
  Protected G_MarkEnd = ThemedButton(Cx, Row2Y, 100, 26, "Marcar fim", Chr(#Icon_Bookmark))
  Cx + 100 + 6
  Protected G_ClearRange = ThemedButton(Cx, Row2Y, 120, 26, "Limpar selecao", Chr(#Icon_Clear))
  Cx + 120 + 16
  Protected G_Fill = ThemedButton(Cx, Row2Y, 110, 26, "Preencher...", Chr(#Icon_Fill))
  Cx + 110 + 6
  Protected G_Insert = ThemedButton(Cx, Row2Y, 140, 26, "Inserir bloco...", Chr(#Icon_Insert))
  Cx + 140 + 6
  Protected G_Overwrite = ThemedButton(Cx, Row2Y, 150, 26, "Sobrepor bloco...", Chr(#Icon_Overwrite))
  Cx + 150 + 6
  Protected G_Delete = ThemedButton(Cx, Row2Y, 140, 26, "Excluir bloco...", Chr(#Icon_Delete))
  GadgetToolTip(G_MarkStart, "Marca o byte selecionado na grade como inicio do intervalo")
  GadgetToolTip(G_MarkEnd, "Marca o byte selecionado na grade como fim do intervalo")
  GadgetToolTip(G_ClearRange, "Limpa o intervalo marcado")
  GadgetToolTip(G_Fill, "Preenche o intervalo marcado (ou pergunta inicio/fim) com um valor")
  GadgetToolTip(G_Insert, "Insere bytes na posicao escolhida, deslocando o resto do arquivo pra frente")
  GadgetToolTip(G_Overwrite, "Sobrescreve a partir da posicao escolhida, sem deslocar o que ja existe")
  GadgetToolTip(G_Delete, "Exclui o intervalo marcado (ou pergunta inicio/fim), deslocando ou zerando")

  Protected G_RangeLabel = TextGadget(#PB_Any, LeftX, Row3Y + 4, Row2Width, 20, "")

  Protected G_TypeTitle = TextGadget(#PB_Any, LeftX, CanvasY, InfoW, 20, "Tipo de arquivo:")
  Protected G_Info = EditorGadget(#PB_Any, LeftX, CanvasY + 22, InfoW, CanvasH - 22, #PB_Editor_ReadOnly)
  SetGadgetColor(G_Info, #PB_Gadget_BackColor, Color_EditorBg)
  SetGadgetColor(G_Info, #PB_Gadget_FrontColor, Color_TextActive)

  Protected G_Hex = CanvasGadget(#PB_Any, CanvasX, CanvasY, CanvasW, CanvasH)

  Protected G_ScrollUp = ButtonImageGadget(#PB_Any, ScrollX, CanvasY, ScrollW, ScrollBtnH,
                                            ImageID(HexEd_CreateArrowIcon(16, #True)))
  Protected G_ScrollTrack = CanvasGadget(#PB_Any, ScrollX, CanvasY + ScrollBtnH, ScrollW, CanvasH - 2 * ScrollBtnH)
  Protected G_ScrollDown = ButtonImageGadget(#PB_Any, ScrollX, CanvasY + CanvasH - ScrollBtnH, ScrollW, ScrollBtnH,
                                              ImageID(HexEd_CreateArrowIcon(16, #False)))

  ; Barra inferior em 3 linhas bem separadas (Offset / Valor+Aplicar /
  ; Status+Fechar) - antes o rotulo de status esticava ate a borda direita e
  ; ficava por cima do botao Fechar, que sumia atras do texto.
  TextGadget(#PB_Any, LeftX, EditBarY + 4, 90, 20, "Offset:")
  Protected G_OffsetLabel = TextGadget(#PB_Any, LeftX + 90, EditBarY + 4, 200, 20, "(nenhum)")

  TextGadget(#PB_Any, LeftX, EditBarY + 34, 90, 20, "Valor (hex):")
  Protected G_ByteValue = StringGadget(#PB_Any, LeftX + 90, EditBarY + 32, 50, 22, "", #PB_String_UpperCase)
  Protected G_Apply = ThemedButton(LeftX + 150, EditBarY + 31, 90, 24, "Aplicar", Chr(#Icon_Check))
  GadgetToolTip(G_Apply, "Aplicar")

  Protected G_Status = TextGadget(#PB_Any, LeftX, EditBarY + 64, CanvasX + CanvasW - LeftX - 100, 20, "")
  Protected G_Close = ThemedButton(CanvasX + CanvasW - 90, EditBarY + 61, 90, 24, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  Protected SelOffset.i = -1
  Protected RangeStart.i = -1
  Protected RangeEnd.i = -1
  Protected ScrollTop.i = 0
  Protected TotalRows.i = HexEd_TotalRows()

  SetGadgetText(G_RangeLabel, HexEd_RangeText(RangeStart, RangeEnd))
  HexEd_RefreshHeader(G_PathLabel, G_TypeTitle, G_Info)
  HexEd_Repaint(G_Hex, ScrollTop, SelOffset, RangeStart, RangeEnd, HexColX, AsciiColX, CharW, CharH, HalfCharW, HexFont)
  HexEd_PaintTrack(G_ScrollTrack, ScrollTop, TotalRows, #HexEd_VisibleRows)

  Define HexEvent, Quit.b = #False
  Define MouseX.i, MouseY.i, Row.i, Col.i, Found.b, i.i, bx.i, ax.i
  Define NewVal.i, ByteText.s, MaxTop.i

  Repeat
    HexEvent = WaitWindowEvent()

    Select HexEvent
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_Open
            If Not HexEd_Dirty Or HexEd_ConfirmDiscard()
              Protected OpenPath.s = OpenFileRequester("Abrir arquivo", "", #HexEd_FilePattern, 0)
              If OpenPath <> ""
                If HexEd_LoadFile(OpenPath)
                  SelOffset = -1
                  RangeStart = -1
                  RangeEnd = -1
                  ScrollTop = 0
                  TotalRows = HexEd_TotalRows()
                  SetGadgetText(G_OffsetLabel, "(nenhum)")
                  SetGadgetText(G_ByteValue, "")
                  SetGadgetText(G_RangeLabel, HexEd_RangeText(RangeStart, RangeEnd))
                  SetGadgetText(G_Status, "")
                  HexEd_RefreshHeader(G_PathLabel, G_TypeTitle, G_Info)
                  HexEd_Repaint(G_Hex, ScrollTop, SelOffset, RangeStart, RangeEnd, HexColX, AsciiColX, CharW, CharH, HalfCharW, HexFont)
                  HexEd_PaintTrack(G_ScrollTrack, ScrollTop, TotalRows, #HexEd_VisibleRows)
                Else
                  MessageRequester("Erro ao abrir",
                                    "Nao foi possivel ler o arquivo:" + Chr(10) + OpenPath,
                                    #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
                EndIf
              EndIf
            EndIf

          Case G_Save
            If HexEd_Path = ""
              PostEvent(#PB_Event_Gadget, Win, G_SaveAs)
            Else
              If HexEd_SaveFile(HexEd_Path)
                HexEd_Dirty = #False
                SetGadgetText(G_Status, "Salvo.")
                HexEd_RefreshHeader(G_PathLabel, G_TypeTitle, G_Info)
              Else
                MessageRequester("Erro ao salvar",
                                  "Nao foi possivel escrever em:" + Chr(10) + HexEd_Path,
                                  #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
              EndIf
            EndIf

          Case G_SaveAs
            If HexEd_Size > 0 Or HexEd_Path <> ""
              Protected SavePath.s = SaveFileRequester("Salvar como", HexEd_Path, #HexEd_FilePattern, 0)
              If SavePath <> ""
                If HexEd_SaveFile(SavePath)
                  HexEd_Path = SavePath
                  HexEd_Dirty = #False
                  SetGadgetText(G_Status, "Salvo.")
                  HexEd_RefreshHeader(G_PathLabel, G_TypeTitle, G_Info)
                Else
                  MessageRequester("Erro ao salvar",
                                    "Nao foi possivel escrever em:" + Chr(10) + SavePath,
                                    #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
                EndIf
              EndIf
            EndIf

          Case G_Templates
            HexEd_OpenTemplateGallery(Win)
            If HexEd_Path <> ""
              HexEd_RefreshHeader(G_PathLabel, G_TypeTitle, G_Info)
            EndIf

          Case G_Apply
            If SelOffset < 0 Or SelOffset >= HexEd_Size
              SetGadgetText(G_Status, "Selecione um byte primeiro (clique na grade).")
            Else
              ByteText = Trim(GetGadgetText(G_ByteValue))
              If Not HexEd_IsHexString(ByteText, 2)
                SetGadgetText(G_Status, "Valor invalido - use 1 ou 2 digitos hexadecimais (0-F).")
              Else
                NewVal = Val("$" + ByteText)
                HexEd_Bytes(SelOffset) = NewVal & $FF
                HexEd_Dirty = #True
                SetGadgetText(G_ByteValue, HexEd_Hex2(NewVal))
                SetGadgetText(G_Status, "Byte " + HexEd_Hex6(SelOffset) + "h atualizado.")
                HexEd_RefreshHeader(G_PathLabel, G_TypeTitle, G_Info)
                HexEd_Repaint(G_Hex, ScrollTop, SelOffset, RangeStart, RangeEnd, HexColX, AsciiColX, CharW, CharH, HalfCharW, HexFont)
              EndIf
            EndIf

          Case G_MarkStart
            If SelOffset < 0
              SetGadgetText(G_Status, "Clique um byte na grade primeiro.")
            Else
              RangeStart = SelOffset
              If RangeEnd >= 0 And RangeEnd < RangeStart
                Swap RangeStart, RangeEnd
              EndIf
              SetGadgetText(G_RangeLabel, HexEd_RangeText(RangeStart, RangeEnd))
              SetGadgetText(G_Status, "Inicio da selecao marcado.")
              HexEd_Repaint(G_Hex, ScrollTop, SelOffset, RangeStart, RangeEnd, HexColX, AsciiColX, CharW, CharH, HalfCharW, HexFont)
            EndIf

          Case G_MarkEnd
            If SelOffset < 0
              SetGadgetText(G_Status, "Clique um byte na grade primeiro.")
            Else
              RangeEnd = SelOffset
              If RangeStart >= 0 And RangeEnd < RangeStart
                Swap RangeStart, RangeEnd
              EndIf
              SetGadgetText(G_RangeLabel, HexEd_RangeText(RangeStart, RangeEnd))
              SetGadgetText(G_Status, "Fim da selecao marcado.")
              HexEd_Repaint(G_Hex, ScrollTop, SelOffset, RangeStart, RangeEnd, HexColX, AsciiColX, CharW, CharH, HalfCharW, HexFont)
            EndIf

          Case G_ClearRange
            RangeStart = -1
            RangeEnd = -1
            SetGadgetText(G_RangeLabel, HexEd_RangeText(RangeStart, RangeEnd))
            SetGadgetText(G_Status, "Selecao limpa.")
            HexEd_Repaint(G_Hex, ScrollTop, SelOffset, RangeStart, RangeEnd, HexColX, AsciiColX, CharW, CharH, HalfCharW, HexFont)

          Case G_Fill
            Protected FS.i, FE.i
            If HexEd_ResolveRange(Win, RangeStart, RangeEnd, @FS, @FE)
              Protected FillText.s = InputRequester("Preencher",
                                        "Valor (hex) para preencher " + Str(FE - FS + 1) + " byte(s):",
                                        "00", 0, WindowID(Win))
              If FillText <> "" And HexEd_IsHexString(FillText, 2)
                Protected FVal.i = Val("$" + FillText) & $FF
                Protected fi.i
                For fi = FS To FE
                  HexEd_Bytes(fi) = FVal
                Next
                HexEd_Dirty = #True
                SetGadgetText(G_Status, "Preenchido " + HexEd_Hex6(FS) + "h-" + HexEd_Hex6(FE) + "h com " + HexEd_Hex2(FVal) + "h.")
                HexEd_RefreshHeader(G_PathLabel, G_TypeTitle, G_Info)
                HexEd_Repaint(G_Hex, ScrollTop, SelOffset, RangeStart, RangeEnd, HexColX, AsciiColX, CharW, CharH, HalfCharW, HexFont)
              EndIf
            EndIf

          Case G_Insert
            Protected InsPos.i
            If SelOffset >= 0
              InsPos = SelOffset
            Else
              InsPos = HexEd_PromptPosition(Win, "Inserir bloco (desloca)", HexEd_Size)
            EndIf
            If InsPos >= 0
              If HexEd_PromptBlockSource(Win)
                HexEd_InsertBlockAt(InsPos)
                SelOffset = -1 : RangeStart = -1 : RangeEnd = -1
                TotalRows = HexEd_TotalRows()
                MaxTop = TotalRows - #HexEd_VisibleRows
                If MaxTop < 0 : MaxTop = 0 : EndIf
                If ScrollTop > MaxTop : ScrollTop = MaxTop : EndIf
                SetGadgetText(G_OffsetLabel, "(nenhum)")
                SetGadgetText(G_ByteValue, "")
                SetGadgetText(G_RangeLabel, HexEd_RangeText(RangeStart, RangeEnd))
                SetGadgetText(G_Status, "Bloco de " + Str(HexEd_ClipSize) + " byte(s) inserido em " +
                                        HexEd_Hex6(InsPos) + "h (arquivo agora tem " + Str(HexEd_Size) + " bytes).")
                HexEd_RefreshHeader(G_PathLabel, G_TypeTitle, G_Info)
                HexEd_Repaint(G_Hex, ScrollTop, SelOffset, RangeStart, RangeEnd, HexColX, AsciiColX, CharW, CharH, HalfCharW, HexFont)
                HexEd_PaintTrack(G_ScrollTrack, ScrollTop, TotalRows, #HexEd_VisibleRows)
              EndIf
            EndIf

          Case G_Overwrite
            Protected OvPos.i
            If SelOffset >= 0
              OvPos = SelOffset
            Else
              OvPos = HexEd_PromptPosition(Win, "Sobrepor bloco (nao desloca)", HexEd_Size)
            EndIf
            If OvPos >= 0
              If HexEd_PromptBlockSource(Win)
                HexEd_OverwriteBlockAt(OvPos)
                SelOffset = -1 : RangeStart = -1 : RangeEnd = -1
                TotalRows = HexEd_TotalRows()
                MaxTop = TotalRows - #HexEd_VisibleRows
                If MaxTop < 0 : MaxTop = 0 : EndIf
                If ScrollTop > MaxTop : ScrollTop = MaxTop : EndIf
                SetGadgetText(G_OffsetLabel, "(nenhum)")
                SetGadgetText(G_ByteValue, "")
                SetGadgetText(G_RangeLabel, HexEd_RangeText(RangeStart, RangeEnd))
                SetGadgetText(G_Status, "Bloco de " + Str(HexEd_ClipSize) + " byte(s) sobreposto em " +
                                        HexEd_Hex6(OvPos) + "h (arquivo agora tem " + Str(HexEd_Size) + " bytes).")
                HexEd_RefreshHeader(G_PathLabel, G_TypeTitle, G_Info)
                HexEd_Repaint(G_Hex, ScrollTop, SelOffset, RangeStart, RangeEnd, HexColX, AsciiColX, CharW, CharH, HalfCharW, HexFont)
                HexEd_PaintTrack(G_ScrollTrack, ScrollTop, TotalRows, #HexEd_VisibleRows)
              EndIf
            EndIf

          Case G_Delete
            Protected DS.i, DE.i
            If HexEd_ResolveRange(Win, RangeStart, RangeEnd, @DS, @DE)
              Protected DelMode = MessageRequester("Excluir bloco",
                                     "Deslocar os bytes seguintes pra tras (excluir de verdade, arquivo encolhe)?" + Chr(10) + Chr(10) +
                                     "Sim = excluir e deslocar." + Chr(10) +
                                     "Nao = so sobrescrever com 00 no lugar (tamanho nao muda)." + Chr(10) +
                                     "Cancelar = desistir.",
                                     #PB_MessageRequester_YesNoCancel)
              If DelMode = #PB_MessageRequester_Yes
                HexEd_DeleteRangeShift(DS, DE)
                SelOffset = -1 : RangeStart = -1 : RangeEnd = -1
                TotalRows = HexEd_TotalRows()
                MaxTop = TotalRows - #HexEd_VisibleRows
                If MaxTop < 0 : MaxTop = 0 : EndIf
                If ScrollTop > MaxTop : ScrollTop = MaxTop : EndIf
                SetGadgetText(G_OffsetLabel, "(nenhum)")
                SetGadgetText(G_ByteValue, "")
                SetGadgetText(G_RangeLabel, HexEd_RangeText(RangeStart, RangeEnd))
                SetGadgetText(G_Status, "Bytes " + HexEd_Hex6(DS) + "h-" + HexEd_Hex6(DE) + "h excluidos (arquivo agora tem " +
                                        Str(HexEd_Size) + " bytes).")
                HexEd_RefreshHeader(G_PathLabel, G_TypeTitle, G_Info)
                HexEd_Repaint(G_Hex, ScrollTop, SelOffset, RangeStart, RangeEnd, HexColX, AsciiColX, CharW, CharH, HalfCharW, HexFont)
                HexEd_PaintTrack(G_ScrollTrack, ScrollTop, TotalRows, #HexEd_VisibleRows)
              ElseIf DelMode = #PB_MessageRequester_No
                HexEd_DeleteRangeZero(DS, DE)
                SetGadgetText(G_Status, "Bytes " + HexEd_Hex6(DS) + "h-" + HexEd_Hex6(DE) + "h zerados.")
                HexEd_RefreshHeader(G_PathLabel, G_TypeTitle, G_Info)
                HexEd_Repaint(G_Hex, ScrollTop, SelOffset, RangeStart, RangeEnd, HexColX, AsciiColX, CharW, CharH, HalfCharW, HexFont)
              EndIf
            EndIf

          Case G_Close
            If Not HexEd_Dirty Or HexEd_ConfirmDiscard()
              Quit = #True
            EndIf

          Case G_ScrollUp
            If ScrollTop > 0
              ScrollTop - 1
              HexEd_Repaint(G_Hex, ScrollTop, SelOffset, RangeStart, RangeEnd, HexColX, AsciiColX, CharW, CharH, HalfCharW, HexFont)
              HexEd_PaintTrack(G_ScrollTrack, ScrollTop, TotalRows, #HexEd_VisibleRows)
            EndIf

          Case G_ScrollDown
            MaxTop = TotalRows - #HexEd_VisibleRows
            If MaxTop < 0 : MaxTop = 0 : EndIf
            If ScrollTop < MaxTop
              ScrollTop + 1
              HexEd_Repaint(G_Hex, ScrollTop, SelOffset, RangeStart, RangeEnd, HexColX, AsciiColX, CharW, CharH, HalfCharW, HexFont)
              HexEd_PaintTrack(G_ScrollTrack, ScrollTop, TotalRows, #HexEd_VisibleRows)
            EndIf

          Case G_ScrollTrack
            If EventType() = #PB_EventType_LeftButtonDown
              Protected ClickY = GetGadgetAttribute(G_ScrollTrack, #PB_Canvas_MouseY)
              Protected TrackH = GadgetHeight(G_ScrollTrack)
              MaxTop = TotalRows - #HexEd_VisibleRows
              If MaxTop < 0 : MaxTop = 0 : EndIf
              If MaxTop > 0 And TrackH > 0
                ScrollTop = (ClickY * TotalRows) / TrackH - (#HexEd_VisibleRows / 2)
                If ScrollTop < 0 : ScrollTop = 0 : EndIf
                If ScrollTop > MaxTop : ScrollTop = MaxTop : EndIf
                HexEd_Repaint(G_Hex, ScrollTop, SelOffset, RangeStart, RangeEnd, HexColX, AsciiColX, CharW, CharH, HalfCharW, HexFont)
                HexEd_PaintTrack(G_ScrollTrack, ScrollTop, TotalRows, #HexEd_VisibleRows)
              EndIf
            EndIf

          Case G_Hex
            If EventType() = #PB_EventType_LeftButtonDown
              MouseX = GetGadgetAttribute(G_Hex, #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(G_Hex, #PB_Canvas_MouseY)
              Row = MouseY / CharH
              Found = #False
              For i = 0 To #HexEd_BytesPerRow - 1
                bx = HexColX + i * HalfCharW * 3
                If i >= 8
                  bx + CharW
                EndIf
                If MouseX >= bx - 2 And MouseX < bx + CharW
                  Col = i
                  Found = #True
                  Break
                EndIf
              Next
              If Not Found
                For i = 0 To #HexEd_BytesPerRow - 1
                  ax = AsciiColX + i * HalfCharW
                  If MouseX >= ax - 1 And MouseX < ax + HalfCharW
                    Col = i
                    Found = #True
                    Break
                  EndIf
                Next
              EndIf
              If Found
                Protected ClickOff = (ScrollTop + Row) * #HexEd_BytesPerRow + Col
                If ClickOff >= 0 And ClickOff < HexEd_Size
                  SelOffset = ClickOff
                  SetGadgetText(G_OffsetLabel, HexEd_Hex6(SelOffset) + "h (" + Str(SelOffset) + ")")
                  SetGadgetText(G_ByteValue, HexEd_Hex2(HexEd_Bytes(SelOffset)))
                  SetGadgetText(G_Status, "")
                  HexEd_Repaint(G_Hex, ScrollTop, SelOffset, RangeStart, RangeEnd, HexColX, AsciiColX, CharW, CharH, HalfCharW, HexFont)
                EndIf
              EndIf
            ElseIf EventType() = #PB_EventType_MouseWheel
              Protected WheelDelta = GetGadgetAttribute(G_Hex, #PB_Canvas_WheelDelta)
              MaxTop = TotalRows - #HexEd_VisibleRows
              If MaxTop < 0 : MaxTop = 0 : EndIf
              ScrollTop = ScrollTop - WheelDelta * 3
              If ScrollTop < 0 : ScrollTop = 0 : EndIf
              If ScrollTop > MaxTop : ScrollTop = MaxTop : EndIf
              HexEd_Repaint(G_Hex, ScrollTop, SelOffset, RangeStart, RangeEnd, HexColX, AsciiColX, CharW, CharH, HalfCharW, HexFont)
              HexEd_PaintTrack(G_ScrollTrack, ScrollTop, TotalRows, #HexEd_VisibleRows)
            EndIf
        EndSelect

      Case #PB_Event_CloseWindow
        If Not HexEd_Dirty Or HexEd_ConfirmDiscard()
          Quit = #True
        EndIf

    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
