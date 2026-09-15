;
; ------------------------------------------------------------
;  Z80Link.pbi - linker Z80 nativo (Linkstor80/LK80-equivalente), Fase B do
;  assembler (ver docs/resumo-asm.md, docs/reference/nestor80-linker.md -
;  algoritmo extraido direto do C# do Nestor80,
;  Linker/RelocatableFilesProcessor.cs). PRIMEIRO CORTE: linka multiplos
;  .REL SEM biblioteca/.REQUEST ainda (fica pro corte 2, junto de
;  editor/Z80Lib.pbi).
;
;  Escopo suportado: leitura do bit-stream .REL formato ESTENDIDO (mesmo
;  formato que Z80Asm::AssembleRelocatable ja gera), modo de sequenciamento
;  PADRAO do LK80 ("dados antes de codigo", unico suportado - sem
;  --code/--data/--align-code/--align-data/--code-before-data ainda),
;  concatenacao de CSEG/DSEG/COMMON entre programas (endereco-base = fim do
;  programa anterior + 1, comecando em 0103h - convencao CP/M/LINK-80), ASEG,
;  resolucao PUBLIC<->EXTRN (corrente ChainExternal + ExternalPlusOffset/
;  MinusOffset), deteccao de simbolo publico duplicado entre programas.
;
;  Fora de escopo nesta etapa (erro explicito, nunca resultado silenciosamente
;  errado): item de extensao RPN (expressao composta com externo, tipo 4),
;  .REQUEST/biblioteca (tipo 3), --code/--data/--align-code/--align-data/
;  --code-before-data, deteccao de sobreposicao de segmento entre programas,
;  saida Intel HEX.
;
;  DeclareModule real (nao so prefixo) - mesmo padrao de Z80Asm/MSXDisk/
;  ProjectDB. Reaproveita Z80RelFormatLink.pbi (copia de Z80RelFormat.pbi
;  dedicada a este Module - ver comentario no topo daquele arquivo pro
;  motivo de ser uma copia separada) - mesmos valores numericos 0-3 =
;  ASEG/CSEG/DSEG/COMMON que Z80Asm::AssembleRelocatable ja usa pra
;  escrever o .REL - precisa vir incluido AQUI DENTRO do DeclareModule pelo
;  mesmo motivo ja documentado no topo de Z80RelFormat.pbi (Module nao
;  enxerga Structure/Enumeration de fora).
; ------------------------------------------------------------
;

DeclareModule Z80Link
  XIncludeFile "Z80RelFormatLink.pbi"

  ; Linka os .REL de RelPaths() na ordem dada e devolve o binario final em
  ; OutBytes() (precisa vir dimensionado com pelo menos 65536 posicoes pelo
  ; chamador, mesma convencao de Z80Asm::Assemble/AssembleRelocatable).
  ; LibraryDir = pasta onde procurar arquivos pedidos via .REQUEST (""=
  ; diretorio de trabalho atual, mesmo default do LK80 real). Devolve o
  ; numero de bytes (0 = nenhum conteudo) ou -1 em erro (GetLastLinkError()).
  Declare.i LinkFiles(List RelPaths.s(), Array OutBytes.a(1), LibraryDir.s = "")
  Declare.s GetLastLinkError()
  Declare.u GetLinkStartAddr()
  Declare.u GetLinkEndAddr()
EndDeclareModule

Module Z80Link

  ; Mesmos valores numericos de Z80Asm::Z80RelItemType (LinkItemType.cs do
  ; Nestor80) - copia trivial local (mesmo espirito de Z80Addr_Make/etc ja
  ; documentado em Z80Asm.pbi: um Module nao compartilha Enumeration com
  ; outro, cada um tem a sua).
  Enumeration Z80LinkItemType
    #ZL_EntrySymbol
    #ZL_SelectCommonBlock
    #ZL_ProgramName
    #ZL_RequestLibrarySearch
    #ZL_ExtensionLinkItem
    #ZL_DefineCommonSize
    #ZL_ChainExternal
    #ZL_DefineEntryPoint
    #ZL_ExternalMinusOffset
    #ZL_ExternalPlusOffset
    #ZL_DataAreaSize
    #ZL_SetLocationCounter
    #ZL_ChainAddress
    #ZL_ProgramAreaSize
    #ZL_EndProgram
    #ZL_EndFile
  EndEnumeration

  #ZL_Item_Byte  = 0
  #ZL_Item_Value = 1
  #ZL_Item_Link  = 2

  #ZL_DefaultCodeStart = $0103  ; convencao CP/M/LINK-80, ver docs/reference/nestor80-rel-format.md

  ; Um item decodificado do bit-stream - byte absoluto, valor relocavel ou
  ; item de link (com campos opcionais de endereco/simbolo, ver Kind).
  Structure Z80RelParsedItem
    Kind.b          ; #ZL_Item_Byte/Value/Link
    ByteVal.a       ; Kind=Byte
    Seg.b           ; Kind=Value, ou Kind=Link com HasAddr (Z80SegType)
    Value.u         ; Kind=Value, ou Kind=Link com HasAddr
    LinkType.b      ; Kind=Link (Z80LinkItemType)
    HasAddr.b       ; Kind=Link
    HasSym.b        ; Kind=Link
    Sym.s           ; Kind=Link com HasSym
  EndStructure

  Structure Z80RelReaderState
    *Buf
    Len.i
    ByteIdx.i
    BitPos.b
  EndStructure

  Structure Z80LinkCommonBlock
    StartAddr.u
    Size.u
    DefinedInProgram.s
  EndStructure

  Structure Z80LinkExternalRef
    SymbolName.s    ; maiusculo
    ProgramName.s
    ChainStartAddr.u
  EndStructure

  ; Um "programa" dentro de um arquivo de biblioteca pedido via .REQUEST -
  ; PB nao permite List dentro de Structure, entao os itens de TODOS os
  ; programas de TODAS as bibliotecas pedidas ficam num unico List global
  ; achatado (LLibItems - ver abaixo); StartIdx/EndIdx (inclusive) marcam o
  ; trecho deste programa especifico dentro dele. PublicSymbolsCsv = nomes
  ; (maiusculo) separados por "," (nomes de simbolo Z80 nunca tem virgula).
  Structure Z80LinkLibProgram
    LibFileName.s
    ProgramName.s
    PublicSymbolsCsv.s
    StartIdx.i
    EndIdx.i
    Loaded.b
  EndStructure

  ;- ------------------------------------------------------------
  ;- Leitor de bit-stream - espelha, ao contrario, Z80Asm::RelW_*/
  ;- Linker/Infrastructure/BitStreamReader.cs do Nestor80. MSB-first, mesma
  ;- semantica confirmada por decodificacao manual byte a byte numa sessao
  ;- anterior (ver docs/resumo-asm.md, log de decisoes tecnicas).
  ;- ------------------------------------------------------------

  Procedure.u RR_ReadBits(*St.Z80RelReaderState, NBits.b)
    Protected Idx.b, Bit.a, V.u
    For Idx = 1 To NBits
      Bit = (PeekA(*St\Buf + *St\ByteIdx) >> (7 - *St\BitPos)) & 1
      V = (V << 1) | Bit
      *St\BitPos + 1
      If *St\BitPos = 8
        *St\BitPos = 0
        *St\ByteIdx + 1
      EndIf
    Next
    ProcedureReturn V
  EndProcedure

  Procedure.b RR_AtEnd(*St.Z80RelReaderState)
    ProcedureReturn Bool(*St\ByteIdx >= *St\Len)
  EndProcedure

  Procedure RR_ForceByteBoundary(*St.Z80RelReaderState)
    If *St\BitPos > 0
      *St\BitPos = 0
      *St\ByteIdx + 1
    EndIf
  EndProcedure

  ; Cabecalho fixo de 16 bytes do formato estendido - se bater a assinatura
  ; exata (sempre bate, ver Z80Asm::RelW_WriteExtendedHeader), pula (fica
  ; alinhado a byte, nunca chamado no meio de um item). Se nao bater, nao
  ; pula nada (arquivo legado/nao-estendido - fora de escopo, mas nao trava:
  ; o parser normal vai so falhar de forma clara no primeiro item invalido).
  Procedure.b RR_CheckAndSkipHeader(*St.Z80RelReaderState)
    If *St\Len - *St\ByteIdx < 16
      ProcedureReturn #False
    EndIf
    Protected Dim HB.a(15)
    HB(0)=$85 : HB(1)=$D3 : HB(2)=$13 : HB(3)=$92 : HB(4)=$D4 : HB(5)=$D5 : HB(6)=$13 : HB(7)=$D4
    HB(8)=$A5 : HB(9)=$00 : HB(10)=$00 : HB(11)=$13 : HB(12)=$8F : HB(13)=$FF : HB(14)=$F0 : HB(15)=$9E
    Protected Idx
    For Idx = 0 To 15
      If PeekA(*St\Buf + *St\ByteIdx + Idx) <> HB(Idx)
        ProcedureReturn #False
      EndIf
    Next
    *St\ByteIdx + 16
    ProcedureReturn #True
  EndProcedure

  ; Campo de simbolo formato ESTENDIDO - espelha Z80Asm::RelW_WriteSymbolField
  ; (3 bits de tamanho 0-7 + N bytes UTF-8; tamanho>=2 com 1o byte FFh =
  ; escape, tamanho real em 1-3 bytes little-endian a seguir, depois os
  ; bytes de verdade).
  Procedure.s RR_ReadSymbolField(*St.Z80RelReaderState)
    Protected Ln.b = RR_ReadBits(*St, 3)
    Protected Dim Raw.a(0)
    Protected Idx
    If Ln > 0
      ReDim Raw.a(Ln - 1)
      For Idx = 0 To Ln - 1
        Raw(Idx) = RR_ReadBits(*St, 8)
      Next
    EndIf

    Protected RealLen.i
    Protected *Mem
    Protected ResS.s

    If Ln >= 2 And Raw(0) = $FF
      Select Ln
        Case 2 : RealLen = Raw(1)
        Case 3 : RealLen = Raw(1) | (Raw(2) << 8)
        Default : RealLen = Raw(1) | (Raw(2) << 8) | (Raw(3) << 16)
      EndSelect
      If RealLen <= 0
        ProcedureReturn ""
      EndIf
      *Mem = AllocateMemory(RealLen + 1)
      For Idx = 0 To RealLen - 1
        PokeA(*Mem + Idx, RR_ReadBits(*St, 8))
      Next
      ResS = PeekS(*Mem, RealLen, #PB_UTF8)
      FreeMemory(*Mem)
      ProcedureReturn ResS
    EndIf

    If Ln = 0
      ProcedureReturn ""
    EndIf
    *Mem = AllocateMemory(Ln + 1)
    For Idx = 0 To Ln - 1
      PokeA(*Mem + Idx, Raw(Idx))
    Next
    ResS = PeekS(*Mem, Ln, #PB_UTF8)
    FreeMemory(*Mem)
    ProcedureReturn ResS
  EndProcedure

  ; Le UM item do bit-stream (prefixo "0"=byte / "1"+seg=valor relocavel /
  ; "100"+tipo=item de link, ver docs/reference/nestor80-rel-format.md).
  Procedure.b RR_ReadItem(*St.Z80RelReaderState, *Out.Z80RelParsedItem)
    *Out\Kind = 0 : *Out\Sym = "" : *Out\HasAddr = #False : *Out\HasSym = #False
    Protected P1.b = RR_ReadBits(*St, 1)
    If P1 = 0
      *Out\Kind = #ZL_Item_Byte
      *Out\ByteVal = RR_ReadBits(*St, 8)
      ProcedureReturn #True
    EndIf

    Protected Seg.b = RR_ReadBits(*St, 2)
    If Seg <> 0
      *Out\Kind = #ZL_Item_Value
      *Out\Seg = Seg
      Protected Lo.b = RR_ReadBits(*St, 8)
      Protected Hi.b = RR_ReadBits(*St, 8)
      *Out\Value = Lo | (Hi << 8)
      ProcedureReturn #True
    EndIf

    *Out\Kind = #ZL_Item_Link
    *Out\LinkType = RR_ReadBits(*St, 4)
    If *Out\LinkType = #ZL_EndFile
      ProcedureReturn #True
    EndIf
    If *Out\LinkType >= 5
      *Out\HasAddr = #True
      *Out\Seg = RR_ReadBits(*St, 2)
      Protected ALo.b = RR_ReadBits(*St, 8)
      Protected AHi.b = RR_ReadBits(*St, 8)
      *Out\Value = ALo | (AHi << 8)
    EndIf
    If *Out\LinkType <= 7
      *Out\HasSym = #True
      *Out\Sym = RR_ReadSymbolField(*St)
    EndIf
    ProcedureReturn #True
  EndProcedure

  ; Faz o parse do arquivo INTEIRO (pode ter varios "programas" concatenados,
  ; caso de biblioteca - ver formato) numa lista PLANA de itens; os
  ; marcadores EndProgram/EndFile ficam DENTRO da lista (o chamador corta em
  ; EndProgram, ver LinkFiles). Devolve #False so em erro de leitura de
  ; verdade (bit-stream corrompido no meio de um item).
  Procedure.b RR_ParseBuffer(*Buf, BufLen.i, List Items.Z80RelParsedItem())
    Protected St.Z80RelReaderState
    St\Buf = *Buf : St\Len = BufLen : St\ByteIdx = 0 : St\BitPos = 0
    ClearList(Items())

    Repeat
      RR_CheckAndSkipHeader(@St)
      Repeat
        AddElement(Items())
        If Not RR_ReadItem(@St, @Items())
          ProcedureReturn #False
        EndIf
        If Items()\Kind = #ZL_Item_Link And Items()\LinkType = #ZL_EndFile
          ProcedureReturn #True
        EndIf
        If Items()\Kind = #ZL_Item_Link And Items()\LinkType = #ZL_EndProgram
          RR_ForceByteBoundary(@St)
          Break
        EndIf
      ForEver
    Until RR_AtEnd(@St)
    ProcedureReturn #True
  EndProcedure

  ;- ------------------------------------------------------------
  ;- Algoritmo de linkagem - espelha Linker/RelocatableFilesProcessor.cs
  ;- (ProcessProgram/EffectiveAddressOf/ResolveExternalChain/DoLinking), so
  ;- o modo de sequenciamento "dados antes de codigo" (padrao do LK80 sem
  ;- --code/--data/--align-*/--code-before-data - unico suportado nesta
  ;- etapa, ver docs/resumo-asm.md).
  ;- ------------------------------------------------------------

  Global LLastError.s
  Global Dim LMem.a(65535)
  Global LStartAddr.u, LEndAddr.u, LAnyContent.b

  Global LPrevHasContent.b, LPrevMaxSegEnd.u  ; do ULTIMO programa com conteudo (CSEG/DSEG/ASEG - NAO COMMON, ver ProgramInfo.MaxSegmentEnd no C#)

  Global NewMap LCommonBlocks.Z80LinkCommonBlock()  ; chave = nome maiusculo
  Global NewMap LSymbols.u()                        ; chave = nome maiusculo -> endereco final resolvido
  Global NewMap LSymbolOwner.s()                    ; chave = nome maiusculo -> nome do programa que definiu (deteccao de duplicata)
  Global NewList LExternalsPending.Z80LinkExternalRef()
  Global NewMap LOffsetForExternalAddr.i()          ; chave = Str(endereco) -> deslocamento com sinal (ExternalPlusOffset/MinusOffset)

  Global LLibraryDir.s
  Global NewMap LRequestedLibNames.b()              ; nomes (maiusculo) de biblioteca ja pedidos (dedup, ver .REQUEST no LK80 real)
  Global NewList LLibItems.Z80RelParsedItem()        ; itens de TODOS os programas de TODAS as bibliotecas pedidas, achatado
  Global NewList LLibProgIndex.Z80LinkLibProgram()   ; um registro por programa de biblioteca (ver Z80LinkLibProgram acima)

  Global LProgCodeStart.u, LProgCodeEnd.u
  Global LProgDataStart.u, LProgDataEnd.u
  Global LProgCommonStart.u
  Global LProgAbsStart.u, LProgAbsEnd.u, LProgHasAbs.b
  Global LCurArea.b, LCurAddr.u, LCurCommonName.s
  Global LCurProgramName.s
  Global NewMap LCurProgSymbols.b()

  Procedure.s GetLastLinkError()
    ProcedureReturn LLastError
  EndProcedure

  Procedure.u GetLinkStartAddr()
    ProcedureReturn LStartAddr
  EndProcedure

  Procedure.u GetLinkEndAddr()
    ProcedureReturn LEndAddr
  EndProcedure

  Procedure.u ULMin(A.u, B.u)
    If A < B : ProcedureReturn A : EndIf
    ProcedureReturn B
  EndProcedure

  Procedure.u ULMax(A.u, B.u)
    If A > B : ProcedureReturn A : EndIf
    ProcedureReturn B
  EndProcedure

  ;- ------------------------------------------------------------
  ;- .REQUEST/biblioteca (Fase B, corte 2) - um arquivo de biblioteca e
  ;- simplesmente varios "programas" .REL concatenados (mesmo RR_ParseBuffer
  ;- de cima ja entende isso, so nunca tinha sido usado com mais de um
  ;- programa por arquivo). Diferente do C# do Nestor80 (que, nesta versao
  ;- local testada, parece so enxergar o simbolo publico do PRIMEIRO
  ;- programa de uma biblioteca multi-programa pedida via .REQUEST - bug/
  ;- limitacao confirmada empiricamente, ver docs/resumo-asm.md), aqui cada
  ;- PROGRAMA da biblioteca e indexado separadamente (LLibProgIndex) - so o
  ;- programa que realmente resolve um externo pendente entra no binario
  ;- final, nunca a biblioteca inteira (linkagem estatica seletiva, pedido
  ;- original do usuario).
  ;- ------------------------------------------------------------

  Procedure.s LResolveLibPath(FileName.s)
    Protected FullName.s = FileName
    If Not (Len(FullName) > 4 And UCase(Right(FullName, 4)) = ".REL")
      FullName + ".rel"
    EndIf
    If LLibraryDir <> ""
      Protected Dir.s = LLibraryDir
      If Right(Dir, 1) <> "\" And Right(Dir, 1) <> "/"
        Dir + "\"
      EndIf
      ProcedureReturn Dir + FullName
    EndIf
    ProcedureReturn FullName
  EndProcedure

  Procedure.b LCsvContains(Csv.s, Name.s)
    If Csv = ""
      ProcedureReturn #False
    EndIf
    Protected N = CountString(Csv, ",") + 1
    Protected Idx
    For Idx = 1 To N
      If StringField(Csv, Idx, ",") = Name
        ProcedureReturn #True
      EndIf
    Next
    ProcedureReturn #False
  EndProcedure

  ; Copia o trecho [StartIdx..EndIdx] (indices 0-based, inclusive) de
  ; LLibItems() pra uma lista nova - usado pra extrair UM programa especifico
  ; de biblioteca na hora de carrega-lo de verdade via ProcessProgram().
  Procedure LCopyLibProgramItems(StartIdx.i, EndIdx.i, List Out.Z80RelParsedItem())
    ClearList(Out())
    Protected Idx
    For Idx = StartIdx To EndIdx
      If SelectElement(LLibItems(), Idx)
        AddElement(Out())
        CopyStructure(@LLibItems(), @Out(), Z80RelParsedItem)
      EndIf
    Next
  EndProcedure

  ; Le e faz o parse de um arquivo de biblioteca pedido via .REQUEST,
  ; indexando cada "programa" dele separadamente em LLibProgIndex() (itens
  ; de verdade ficam achatados em LLibItems(), StartIdx/EndIdx marcam o
  ; trecho de cada programa). So um no-op se esse nome ja foi pedido antes
  ; (mesma regra do LK80 real). NAO carrega nenhum programa ainda - so
  ; indexa; o carregamento de verdade (seletivo) acontece depois, em
  ; LinkFiles(), conforme os externos pendentes forem descobertos.
  Procedure.b LLoadRequestedLibraryFile(FileName.s)
    Protected Key.s = UCase(FileName)
    If FindMapElement(LRequestedLibNames(), Key)
      ProcedureReturn #True
    EndIf
    LRequestedLibNames(Key) = #True

    Protected FullPath.s = LResolveLibPath(FileName)
    Protected FileNum = ReadFile(#PB_Any, FullPath)
    If Not FileNum
      LLastError = ".REQUEST: nao consegui abrir biblioteca " + FullPath
      ProcedureReturn #False
    EndIf
    Protected FLen = Lof(FileNum)
    Protected *FBuf = AllocateMemory(FLen)
    ReadData(FileNum, *FBuf, FLen)
    CloseFile(FileNum)

    Protected NewList Items.Z80RelParsedItem()
    If Not RR_ParseBuffer(*FBuf, FLen, Items())
      FreeMemory(*FBuf)
      LLastError = ".REQUEST: erro fazendo parse de " + FullPath
      ProcedureReturn #False
    EndIf
    FreeMemory(*FBuf)

    Protected CurStart.i = ListSize(LLibItems())
    Protected CurProgName.s = ""
    Protected CurPubCsv.s = ""
    ForEach Items()
      AddElement(LLibItems())
      CopyStructure(@Items(), @LLibItems(), Z80RelParsedItem)
      If Items()\Kind = #ZL_Item_Link
        If Items()\LinkType = #ZL_ProgramName And CurProgName = ""
          CurProgName = Items()\Sym
        ElseIf Items()\LinkType = #ZL_EntrySymbol
          If CurPubCsv = ""
            CurPubCsv = UCase(Items()\Sym)
          Else
            CurPubCsv = CurPubCsv + "," + UCase(Items()\Sym)
          EndIf
        ElseIf Items()\LinkType = #ZL_EndProgram
          Protected CurEnd.i = ListSize(LLibItems()) - 1
          AddElement(LLibProgIndex())
          LLibProgIndex()\LibFileName = FileName
          LLibProgIndex()\ProgramName = CurProgName
          LLibProgIndex()\PublicSymbolsCsv = CurPubCsv
          LLibProgIndex()\StartIdx = CurStart
          LLibProgIndex()\EndIdx = CurEnd
          LLibProgIndex()\Loaded = #False
          CurStart = ListSize(LLibItems())
          CurProgName = ""
          CurPubCsv = ""
        EndIf
      EndIf
    Next

    ProcedureReturn #True
  EndProcedure

  ; Endereco efetivo (final, ja linkado) de um valor relocavel do programa
  ; ATUAL (LProgCodeStart/LProgDataStart/LCommonBlocks/LCurCommonName ja
  ; calculados - ver ProcessProgram). ASEG e absoluto, nao muda.
  Procedure.u LEffectiveAddr(Seg.b, Value.u)
    Select Seg
      Case #Z80Seg_Code : ProcedureReturn (LProgCodeStart + Value) & $FFFF
      Case #Z80Seg_Data : ProcedureReturn (LProgDataStart + Value) & $FFFF
      Case #Z80Seg_Common
        If FindMapElement(LCommonBlocks(), UCase(LCurCommonName))
          ProcedureReturn (LCommonBlocks()\StartAddr + Value) & $FFFF
        EndIf
        ProcedureReturn Value & $FFFF
      Default
        ProcedureReturn Value & $FFFF ; ASEG - ja e absoluto
    EndSelect
  EndProcedure

  ; Processa UM programa (lista de itens entre o inicio do arquivo/programa
  ; anterior e o EndProgram deste, inclusive) - 2 passadas: 1a so le os
  ; itens que declaram tamanho (ProgramAreaSize/DataAreaSize/
  ; DefineCommonSize/ProgramName), calcula o endereco-base; 2a percorre tudo
  ; de verdade escrevendo em LMem() e resolvendo PUBLIC/enfileirando EXTRN.
  Procedure.b ProcessProgram(List Items.Z80RelParsedItem())
    ClearMap(LCurProgSymbols())
    LProgHasAbs = #False
    LProgAbsStart = 65535 : LProgAbsEnd = 0
    LCurCommonName = ""

    Protected ProgName.s = ""
    Protected ProgSize.u = 0, DataSize.u = 0
    Protected CommonsSize.u = 0
    Protected NewList NewBlocksThisProgram.s()

    ForEach Items()
      If Items()\Kind = #ZL_Item_Link
        Select Items()\LinkType
          Case #ZL_ProgramName
            If ProgName = "" : ProgName = Items()\Sym : EndIf
          Case #ZL_ProgramAreaSize
            ProgSize = Items()\Value
          Case #ZL_DataAreaSize
            DataSize = Items()\Value
          Case #ZL_DefineCommonSize
            Protected CKey.s = UCase(Items()\Sym)
            If FindMapElement(LCommonBlocks(), CKey)
              If LCommonBlocks()\Size < Items()\Value
                LLastError = "Bloco COMMON '" + Items()\Sym + "' redefinido com tamanho maior (" + Str(Items()\Value) + ") que o original (" + Str(LCommonBlocks()\Size) + ")"
                ProcedureReturn #False
              EndIf
            Else
              AddMapElement(LCommonBlocks(), CKey)
              LCommonBlocks()\Size = Items()\Value
              LCommonBlocks()\DefinedInProgram = ProgName
              LCommonBlocks()\StartAddr = CommonsSize ; provisorio - reposicionado abaixo
              AddElement(NewBlocksThisProgram()) : NewBlocksThisProgram() = CKey
              CommonsSize = (CommonsSize + Items()\Value) & $FFFF
            EndIf
        EndSelect
      EndIf
    Next

    LCurProgramName = ProgName

    Protected BaseAddr.u
    If LPrevHasContent
      BaseAddr = (LPrevMaxSegEnd + 1) & $FFFF
    Else
      BaseAddr = #ZL_DefaultCodeStart
    EndIf

    ; Modo "dados antes de codigo" (padrao do LK80, unico suportado): COMMON,
    ; depois DSEG, depois CSEG, todos a partir do mesmo endereco-base.
    LProgCommonStart = BaseAddr
    LProgDataStart = (LProgCommonStart + CommonsSize) & $FFFF
    LProgCodeStart = (LProgDataStart + DataSize) & $FFFF

    ForEach NewBlocksThisProgram()
      If FindMapElement(LCommonBlocks(), NewBlocksThisProgram())
        LCommonBlocks()\StartAddr = (LProgCommonStart + LCommonBlocks()\StartAddr) & $FFFF
      EndIf
    Next

    If ProgSize = 0
      LProgCodeEnd = LProgCodeStart
    Else
      LProgCodeEnd = (LProgCodeStart + ProgSize - 1) & $FFFF
    EndIf
    If DataSize = 0
      LProgDataEnd = LProgDataStart
    Else
      LProgDataEnd = (LProgDataStart + DataSize - 1) & $FFFF
    EndIf

    If Not LAnyContent
      LStartAddr = 65535 : LEndAddr = 0
    EndIf
    If ProgSize > 0
      LStartAddr = ULMin(LStartAddr, LProgCodeStart)
      LEndAddr = ULMax(LEndAddr, LProgCodeEnd)
      LAnyContent = #True
    EndIf
    If DataSize > 0 Or CommonsSize > 0
      LStartAddr = ULMin(LStartAddr, LProgCommonStart)
      LEndAddr = ULMax(LEndAddr, LProgDataEnd)
      LAnyContent = #True
    EndIf

    LCurArea = #Z80Seg_Code
    LCurAddr = LProgCodeStart

    ForEach Items()
      Select Items()\Kind
        Case #ZL_Item_Byte
          LMem(LCurAddr) = Items()\ByteVal
          LCurAddr = (LCurAddr + 1) & $FFFF
          If LCurArea = #Z80Seg_Absolute
            LProgAbsEnd = ULMax(LProgAbsEnd, (LCurAddr - 1) & $FFFF)
          EndIf

        Case #ZL_Item_Value
          Protected EffV.u = LEffectiveAddr(Items()\Seg, Items()\Value)
          LMem(LCurAddr) = EffV & $FF
          LMem((LCurAddr + 1) & $FFFF) = (EffV >> 8) & $FF
          LCurAddr = (LCurAddr + 2) & $FFFF
          If LCurArea = #Z80Seg_Absolute
            LProgAbsEnd = ULMax(LProgAbsEnd, (LCurAddr - 1) & $FFFF)
          EndIf

        Case #ZL_Item_Link
          Select Items()\LinkType
            Case #ZL_SetLocationCounter
              LCurArea = Items()\Seg
              LCurAddr = LEffectiveAddr(Items()\Seg, Items()\Value)
              If LCurArea = #Z80Seg_Absolute
                LProgHasAbs = #True
                LProgAbsStart = ULMin(LProgAbsStart, LCurAddr)
                LStartAddr = ULMin(LStartAddr, LProgAbsStart)
                LAnyContent = #True
              EndIf

            Case #ZL_DefineEntryPoint
              Protected EPKey.s = UCase(Items()\Sym)
              If Not FindMapElement(LCurProgSymbols(), EPKey)
                Protected EPVal.u = LEffectiveAddr(Items()\Seg, Items()\Value)
                If FindMapElement(LSymbolOwner(), EPKey)
                  LLastError = "Simbolo '" + Items()\Sym + "' definido em mais de um programa (" + LSymbolOwner(EPKey) + " e " + LCurProgramName + ")"
                  ProcedureReturn #False
                EndIf
                LSymbols(EPKey) = EPVal
                LSymbolOwner(EPKey) = LCurProgramName
                LCurProgSymbols(EPKey) = #True
              EndIf

            Case #ZL_ChainExternal
              If Items()\Seg = #Z80Seg_Absolute And Items()\Value = 0
                ; referencia externa usada so dentro de uma expressao (item de
                ; extensao) - nunca gerada pelo nosso AssembleRelocatable ainda,
                ; mas presente na spec (ver docs/reference/nestor80-rel-format.md) - ignorar
              Else
                Protected ChainAddr.u = LEffectiveAddr(Items()\Seg, Items()\Value)
                AddElement(LExternalsPending())
                LExternalsPending()\SymbolName = UCase(Items()\Sym)
                LExternalsPending()\ProgramName = LCurProgramName
                LExternalsPending()\ChainStartAddr = ChainAddr
              EndIf

            Case #ZL_ExternalPlusOffset
              LOffsetForExternalAddr(Str(LCurAddr)) = Items()\Value
            Case #ZL_ExternalMinusOffset
              LOffsetForExternalAddr(Str(LCurAddr)) = -Items()\Value

            Case #ZL_SelectCommonBlock
              Protected SelKey.s = UCase(Items()\Sym)
              If Not FindMapElement(LCommonBlocks(), SelKey)
                LLastError = "Bloco COMMON '" + Items()\Sym + "' selecionado sem ter sido definido"
                ProcedureReturn #False
              EndIf
              LCurCommonName = SelKey

            Case #ZL_ExtensionLinkItem
              LLastError = "Item de extensao RPN (expressao composta com externo) nao suportado nesta fase (Fase B parcial): programa " + LCurProgramName
              ProcedureReturn #False

            Case #ZL_RequestLibrarySearch
              If Not LLoadRequestedLibraryFile(Items()\Sym)
                ProcedureReturn #False
              EndIf

            Case #ZL_ChainAddress
              LLastError = "Item de link 'Chain address' (tipo 12) nao suportado - nunca gerado por assemblers reais"
              ProcedureReturn #False

            Case #ZL_EndProgram
              Break
          EndSelect
      EndSelect
    Next

    If LProgHasAbs
      LEndAddr = ULMax(LEndAddr, LProgAbsEnd)
    EndIf

    Protected ThisMaxSegEnd.u
    If LProgHasAbs
      ThisMaxSegEnd = ULMax(ULMax(LProgCodeEnd, LProgDataEnd), LProgAbsEnd)
    Else
      ThisMaxSegEnd = ULMax(LProgCodeEnd, LProgDataEnd)
    EndIf
    If ProgSize > 0 Or DataSize > 0 Or LProgHasAbs Or CommonsSize > 0
      LPrevHasContent = #True
      LPrevMaxSegEnd = ThisMaxSegEnd
    EndIf

    ProcedureReturn #True
  EndProcedure

  Procedure.i LinkFiles(List RelPaths.s(), Array OutBytes.a(1), LibraryDir.s = "")
    LLastError = ""
    LLibraryDir = LibraryDir
    ClearMap(LCommonBlocks())
    ClearMap(LSymbols())
    ClearMap(LSymbolOwner())
    ClearList(LExternalsPending())
    ClearMap(LOffsetForExternalAddr())
    ClearMap(LRequestedLibNames())
    ClearList(LLibItems())
    ClearList(LLibProgIndex())
    Protected Idx
    For Idx = 0 To 65535
      LMem(Idx) = 0
    Next
    LStartAddr = 65535 : LEndAddr = 0 : LAnyContent = #False
    LPrevHasContent = #False : LPrevMaxSegEnd = 0

    ForEach RelPaths()
      Protected Path.s = RelPaths()
      Protected FileNum = ReadFile(#PB_Any, Path)
      If Not FileNum
        LLastError = "Nao consegui abrir " + Path
        ProcedureReturn -1
      EndIf
      Protected FLen = Lof(FileNum)
      Protected *FBuf = AllocateMemory(FLen)
      ReadData(FileNum, *FBuf, FLen)
      CloseFile(FileNum)

      Protected NewList Items.Z80RelParsedItem()
      If Not RR_ParseBuffer(*FBuf, FLen, Items())
        FreeMemory(*FBuf)
        LLastError = "Erro fazendo parse de " + Path
        ProcedureReturn -1
      EndIf
      FreeMemory(*FBuf)

      ; um arquivo pode ter varios "programas" concatenados (biblioteca) -
      ; corta em EndProgram, chama ProcessProgram pra cada um
      Protected NewList ProgItems.Z80RelParsedItem()
      ClearList(ProgItems())
      ForEach Items()
        AddElement(ProgItems())
        CopyStructure(@Items(), @ProgItems(), Z80RelParsedItem)
        If Items()\Kind = #ZL_Item_Link And Items()\LinkType = #ZL_EndProgram
          If Not ProcessProgram(ProgItems())
            ProcedureReturn -1
          EndIf
          ClearList(ProgItems())
        EndIf
      Next
    Next

    ; resolve bibliotecas pedidas via .REQUEST - ponto fixo: cada rodada
    ; procura, pra cada externo AINDA pendente, um programa de biblioteca
    ; ainda nao carregado cujos simbolos publicos incluam esse nome (1o
    ; achado ganha, mesma regra do LK80 real) e carrega ele de verdade
    ; (ProcessProgram) - carregar um programa pode introduzir NOVOS externos
    ; pendentes (se o proprio programa de biblioteca tiver EXTRN, inclusive
    ; pra outro programa da MESMA ou de OUTRA biblioteca pedida), entao
    ; repete ate uma rodada inteira nao carregar nada novo (cobre 1+ niveis
    ; de transitividade entre programas de biblioteca).
    Protected LoadedSomething.b = #True
    While LoadedSomething
      LoadedSomething = #False
      Protected NewList PendingNames.s()
      ForEach LExternalsPending()
        If Not FindMapElement(LSymbols(), LExternalsPending()\SymbolName)
          AddElement(PendingNames())
          PendingNames() = LExternalsPending()\SymbolName
        EndIf
      Next
      ForEach PendingNames()
        Protected PName.s = PendingNames()
        ForEach LLibProgIndex()
          If Not LLibProgIndex()\Loaded And LCsvContains(LLibProgIndex()\PublicSymbolsCsv, PName)
            LLibProgIndex()\Loaded = #True
            Protected NewList LibProgItems.Z80RelParsedItem()
            LCopyLibProgramItems(LLibProgIndex()\StartIdx, LLibProgIndex()\EndIdx, LibProgItems())
            If Not ProcessProgram(LibProgItems())
              ProcedureReturn -1
            EndIf
            LoadedSomething = #True
            Break
          EndIf
        Next
      Next
    Wend

    ; resolve as correntes de externo (ver RelWriteExternalChainRef em
    ; Z80Asm.pbi pro lado escritor - aqui e o inverso: percorre a lista
    ; encadeada de posicoes-a-corrigir, gravando o valor final resolvido em
    ; cada uma, terminada por uma posicao cujo conteudo e 0)
    ForEach LExternalsPending()
      If Not FindMapElement(LSymbols(), LExternalsPending()\SymbolName)
        LLastError = "Nao consegui resolver simbolo externo: " + LExternalsPending()\SymbolName + " (programa " + LExternalsPending()\ProgramName + ")"
        ProcedureReturn -1
      EndIf
      Protected ExtVal.u = LSymbols(LExternalsPending()\SymbolName)
      Protected Addr.u = LExternalsPending()\ChainStartAddr
      Protected Guard.i = 0
      Repeat
        Protected NextLink.u = LMem(Addr) | (LMem((Addr + 1) & $FFFF) << 8)
        Protected EffVal.u = ExtVal
        If FindMapElement(LOffsetForExternalAddr(), Str(Addr))
          EffVal = (ExtVal + LOffsetForExternalAddr()) & $FFFF
        EndIf
        LMem(Addr) = EffVal & $FF
        LMem((Addr + 1) & $FFFF) = (EffVal >> 8) & $FF
        If NextLink = 0
          Break
        EndIf
        Addr = NextLink
        Guard + 1
      Until Guard >= 32768
      If Guard >= 32768
        LLastError = "Loop infinito resolvendo corrente do simbolo externo: " + LExternalsPending()\SymbolName
        ProcedureReturn -1
      EndIf
    Next

    If Not LAnyContent
      ProcedureReturn 0
    EndIf

    Protected N = (LEndAddr - LStartAddr + 1) & $FFFF
    For Idx = 0 To N - 1
      OutBytes(Idx) = LMem((LStartAddr + Idx) & $FFFF)
    Next
    ProcedureReturn N
  EndProcedure

EndModule
