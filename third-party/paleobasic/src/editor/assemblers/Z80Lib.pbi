;
; ------------------------------------------------------------
;  Z80Lib.pbi - gerenciador de biblioteca .LIB (Libstor80/LB80-equivalente),
;  Fase B do assembler, corte 2 (junto do .REQUEST em Z80Link.pbi - ver
;  docs/resumo-asm.md). Um arquivo de biblioteca e simplesmente varios
;  "programas" .REL concatenados, cada um com seu proprio cabecalho de 16
;  bytes (formato estendido) e seu proprio item "Fim de programa" - so UM
;  "Fim de arquivo" no finalzinho, do ULTIMO programa (ver
;  docs/reference/nestor80-rel-format.md, secao "Bibliotecas").
;
;  Achado que simplifica MUITO criar/somar bibliotecas: como
;  Z80Asm::RelW_ForceByteBoundary() sempre roda ANTES do item "Fim de
;  arquivo" (7 bits, "100"+"1111") tanto no escritor nativo quanto no
;  Nestor80 real, o ultimo byte de QUALQUER .REL de programa unico e SEMPRE
;  exatamente 9Eh (7 bits do item + 1 bit de padding = 1001 1110b) - conferido
;  em todo .REL gerado nesta sessao. Ou seja, "tirar o Fim de arquivo" de um
;  .REL de programa unico e so cortar o ULTIMO BYTE - nao precisa entender
;  bit-stream nenhum pra "create"/"add", so concatenacao de bytes com um
;  corte simples no fim de cada pedaco (exceto o ultimo, que fica intacto).
;  "list"/"remove" ai sim precisam de um leitor de verdade (pra achar nome
;  de programa/simbolos publicos/fronteiras entre programas) - copia trivial
;  do mesmo leitor de Z80Link.pbi (RR_*), mesmo espirito de nao compartilhar
;  Structure/logica pequena entre modulos ja documentado la.
;
;  DeclareModule real (nao so prefixo) - mesmo padrao de Z80Asm/Z80Link/
;  MSXDisk/ProjectDB.
; ------------------------------------------------------------
;

DeclareModule Z80Lib
  Structure Z80LibProgramInfo
    Name.s
    PublicSymbolsCsv.s  ; nomes (maiusculo) separados por "," ("" = nenhum simbolo publico)
    SizeBytes.i
  EndStructure

  ; Cria (se LibPath nao existir ainda) ou acrescenta (se ja existir) os
  ; programas dos .REL de RelPaths(), na ordem dada. Erro se algum nome de
  ; programa colidir com um ja presente na biblioteca ou entre os arquivos
  ; sendo adicionados agora (mesma regra do LB80 real, sem --allow-duplicates).
  Declare.b CreateOrAddLibrary(LibPath.s, List RelPaths.s())

  ; Lista os programas de uma biblioteca (ou de um .REL de programa unico -
  ; funciona igual, so devolve 1 item).
  Declare.b ListLibrary(LibPath.s, List Programs.Z80LibProgramInfo())

  ; Remove UM programa (pelo nome, case-insensitive) de uma biblioteca. Se
  ; era o ultimo programa, o arquivo e apagado (mesma regra do LB80 real).
  ; Devolve #False se o nome nao existia na biblioteca (nao e erro fatal,
  ; ver GetLastLibError() pra distinguir "nao achei" de erro de verdade).
  Declare.b RemoveProgram(LibPath.s, ProgramName.s)

  Declare.s GetLastLibError()
EndDeclareModule

Module Z80Lib

  #ZLB_Item_Byte  = 0
  #ZLB_Item_Value = 1
  #ZLB_Item_Link  = 2

  Enumeration Z80LibItemType
    #ZLB_EntrySymbol
    #ZLB_SelectCommonBlock
    #ZLB_ProgramName
    #ZLB_RequestLibrarySearch
    #ZLB_ExtensionLinkItem
    #ZLB_DefineCommonSize
    #ZLB_ChainExternal
    #ZLB_DefineEntryPoint
    #ZLB_ExternalMinusOffset
    #ZLB_ExternalPlusOffset
    #ZLB_DataAreaSize
    #ZLB_SetLocationCounter
    #ZLB_ChainAddress
    #ZLB_ProgramAreaSize
    #ZLB_EndProgram
    #ZLB_EndFile
  EndEnumeration

  Structure Z80LibParsedItem
    Kind.b
    Seg.b
    Value.u
    LinkType.b
    HasSym.b
    Sym.s
  EndStructure

  ; Como RR_ReadItem/RR_ParseBuffer de Z80Link.pbi, mas essa copia so
  ; precisa dos CAMPOS usados por list/remove (nome de programa + simbolo
  ; publico + fronteira de byte entre programas) - nao precisa decodificar
  ; valor relocavel nem campo de endereco de item de link (Seg/Value ainda
  ; sao lidos, so pra manter a posicao certa no bit-stream, mas descartados).
  Structure Z80LibReaderState
    *Buf
    Len.i
    ByteIdx.i
    BitPos.b
  EndStructure

  Structure Z80LibProgramRange
    Name.s
    PublicSymbolsCsv.s
    ByteStart.i   ; inicio do cabecalho de 16 bytes deste programa
    ByteEnd.i     ; exclusivo - byte onde o PROXIMO programa comecaria (ou onde o EndFile comeca, se for o ultimo)
  EndStructure

  Structure Z80LibChunk
    Ptr.i
    Len.i
  EndStructure

  ; PureBasic nao deixa dereferenciar ponteiro de tipo nativo (*P.i\i) - so
  ; de Structure - caixinha de 1 campo so pra devolver um ponteiro por
  ; out-param (ver LB_ReadWholeFile).
  Structure Z80LibPtrBox
    P.i
  EndStructure

  Global LBLastError.s

  Procedure.s GetLastLibError()
    ProcedureReturn LBLastError
  EndProcedure

  Procedure.u RB_ReadBits(*St.Z80LibReaderState, NBits.b)
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

  Procedure.b RB_AtEnd(*St.Z80LibReaderState)
    ProcedureReturn Bool(*St\ByteIdx >= *St\Len)
  EndProcedure

  Procedure RB_ForceByteBoundary(*St.Z80LibReaderState)
    If *St\BitPos > 0
      *St\BitPos = 0
      *St\ByteIdx + 1
    EndIf
  EndProcedure

  Procedure.b RB_CheckAndSkipHeader(*St.Z80LibReaderState)
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

  Procedure.s RB_ReadSymbolField(*St.Z80LibReaderState)
    Protected Ln.b = RB_ReadBits(*St, 3)
    Protected Dim Raw.a(0)
    Protected Idx
    If Ln > 0
      ReDim Raw.a(Ln - 1)
      For Idx = 0 To Ln - 1
        Raw(Idx) = RB_ReadBits(*St, 8)
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
        PokeA(*Mem + Idx, RB_ReadBits(*St, 8))
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

  Procedure.b RB_ReadItem(*St.Z80LibReaderState, *Out.Z80LibParsedItem)
    *Out\Kind = 0 : *Out\Sym = "" : *Out\HasSym = #False
    Protected P1.b = RB_ReadBits(*St, 1)
    If P1 = 0
      *Out\Kind = #ZLB_Item_Byte
      RB_ReadBits(*St, 8)
      ProcedureReturn #True
    EndIf
    Protected Seg.b = RB_ReadBits(*St, 2)
    If Seg <> 0
      *Out\Kind = #ZLB_Item_Value
      RB_ReadBits(*St, 16)
      ProcedureReturn #True
    EndIf
    *Out\Kind = #ZLB_Item_Link
    *Out\LinkType = RB_ReadBits(*St, 4)
    If *Out\LinkType = #ZLB_EndFile
      ProcedureReturn #True
    EndIf
    If *Out\LinkType >= 5
      RB_ReadBits(*St, 2)
      RB_ReadBits(*St, 16)
    EndIf
    If *Out\LinkType <= 7
      *Out\HasSym = #True
      *Out\Sym = RB_ReadSymbolField(*St)
    EndIf
    ProcedureReturn #True
  EndProcedure

  ; Indexa TODOS os programas de um buffer .REL/.LIB - nome, simbolos
  ; publicos (CSV) e fronteira de byte [ByteStart, ByteEnd) de cada um.
  Procedure.b IndexLibraryBuffer(*Buf, BufLen.i, List Progs.Z80LibProgramRange())
    Protected St.Z80LibReaderState
    St\Buf = *Buf : St\Len = BufLen : St\ByteIdx = 0 : St\BitPos = 0
    ClearList(Progs())

    Protected It.Z80LibParsedItem
    Protected CurStart.i, CurName.s, CurCsv.s

    Repeat
      CurStart = St\ByteIdx
      ; Nao trata falha aqui como erro fatal de proposito: no ULTIMO
      ; programa do arquivo, depois do EndProgram so sobra o item "Fim de
      ; Arquivo" (sem cabecalho de 16 bytes nenhum antes dele) - a checagem
      ; simplesmente nao bate, ByteIdx fica intocado, e o item lido a seguir
      ; (RB_ReadItem) reconhece o EndFile normalmente. So um cabecalho de
      ; verdade faz ByteIdx avancar aqui (mesmo padrao de Z80Link::RR_ParseBuffer).
      RB_CheckAndSkipHeader(@St)
      CurName = "" : CurCsv = ""
      Repeat
        If Not RB_ReadItem(@St, @It)
          ProcedureReturn #False
        EndIf
        If It\Kind = #ZLB_Item_Link
          If It\LinkType = #ZLB_EndFile
            ProcedureReturn #True
          EndIf
          If It\LinkType = #ZLB_ProgramName And CurName = ""
            CurName = It\Sym
          ElseIf It\LinkType = #ZLB_EntrySymbol
            If CurCsv = ""
              CurCsv = UCase(It\Sym)
            Else
              CurCsv = CurCsv + "," + UCase(It\Sym)
            EndIf
          ElseIf It\LinkType = #ZLB_EndProgram
            RB_ForceByteBoundary(@St)
            AddElement(Progs())
            Progs()\Name = CurName
            Progs()\PublicSymbolsCsv = CurCsv
            Progs()\ByteStart = CurStart
            Progs()\ByteEnd = St\ByteIdx
            Break
          EndIf
        EndIf
      ForEver
    Until RB_AtEnd(@St)
    ProcedureReturn #True
  EndProcedure

  Procedure.i LB_ReadWholeFile(Path.s, *OutBuf.Z80LibPtrBox)
    Protected FileNum = ReadFile(#PB_Any, Path)
    If Not FileNum
      ProcedureReturn -1
    EndIf
    Protected FLen = Lof(FileNum)
    Protected *Buf = AllocateMemory(FLen)
    ReadData(FileNum, *Buf, FLen)
    CloseFile(FileNum)
    *OutBuf\P = *Buf
    ProcedureReturn FLen
  EndProcedure

  Procedure.b ListLibrary(LibPath.s, List Programs.Z80LibProgramInfo())
    LBLastError = ""
    ClearList(Programs())
    Protected BufAddr.Z80LibPtrBox
    Protected FLen = LB_ReadWholeFile(LibPath, @BufAddr)
    If FLen < 0
      LBLastError = "Nao consegui abrir " + LibPath
      ProcedureReturn #False
    EndIf

    Protected NewList Ranges.Z80LibProgramRange()
    Protected Ok.b = IndexLibraryBuffer(BufAddr\P, FLen, Ranges())
    FreeMemory(BufAddr\P)
    If Not Ok
      LBLastError = "Erro fazendo parse de " + LibPath + " (formato estendido esperado)"
      ProcedureReturn #False
    EndIf

    ForEach Ranges()
      AddElement(Programs())
      Programs()\Name = Ranges()\Name
      Programs()\PublicSymbolsCsv = Ranges()\PublicSymbolsCsv
      Programs()\SizeBytes = Ranges()\ByteEnd - Ranges()\ByteStart
    Next
    ProcedureReturn #True
  EndProcedure

  ; Concatena os bytes de todos os .REL de entrada, cortando o ultimo byte
  ; (sempre 9Eh = item "Fim de arquivo", ver comentario no topo do arquivo)
  ; de todos MENOS o ultimo pedaco escrito no arquivo de saida.
  Procedure.b CreateOrAddLibrary(LibPath.s, List RelPaths.s())
    LBLastError = ""

    Protected NewList ExistingNames.s()
    Protected AppendMode.b = Bool(FileSize(LibPath) > 0)

    If AppendMode
      Protected NewList ExistingProgs.Z80LibProgramInfo()
      If Not ListLibrary(LibPath, ExistingProgs())
        ProcedureReturn #False
      EndIf
      ForEach ExistingProgs()
        AddElement(ExistingNames())
        ExistingNames() = UCase(ExistingProgs()\Name)
      Next
    EndIf

    ; valida nomes (sem --allow-duplicates, mesma regra do LB80 real) e
    ; colhe os bytes de cada arquivo de entrada de uma vez so
    Protected NewList Chunks.Z80LibChunk()
    Protected NewMap SeenNow.b()

    ForEach RelPaths()
      Protected Path.s = RelPaths()
      Protected BufAddr.Z80LibPtrBox
      Protected FLen = LB_ReadWholeFile(Path, @BufAddr)
      If FLen < 0
        LBLastError = "Nao consegui abrir " + Path
        ProcedureReturn #False
      EndIf
      If FLen < 1 Or PeekA(BufAddr\P + FLen - 1) <> $9E
        FreeMemory(BufAddr\P)
        ForEach Chunks() : FreeMemory(Chunks()\Ptr) : Next
        LBLastError = Path + " nao parece um .REL valido (nao termina no item Fim de Arquivo)"
        ProcedureReturn #False
      EndIf

      Protected NewList TheseProgs.Z80LibProgramRange()
      If Not IndexLibraryBuffer(BufAddr\P, FLen, TheseProgs())
        FreeMemory(BufAddr\P)
        ForEach Chunks() : FreeMemory(Chunks()\Ptr) : Next
        LBLastError = Path + ": erro fazendo parse (formato estendido esperado)"
        ProcedureReturn #False
      EndIf
      ForEach TheseProgs()
        Protected NKey.s = UCase(TheseProgs()\Name)
        Protected Dup.b = #False
        ForEach ExistingNames()
          If ExistingNames() = NKey : Dup = #True : Break : EndIf
        Next
        If Not Dup And FindMapElement(SeenNow(), NKey)
          Dup = #True
        EndIf
        If Dup
          FreeMemory(BufAddr\P)
          ForEach Chunks() : FreeMemory(Chunks()\Ptr) : Next
          LBLastError = "Programa '" + TheseProgs()\Name + "' ja existe na biblioteca ou esta duplicado nos arquivos de entrada"
          ProcedureReturn #False
        EndIf
        SeenNow(NKey) = #True
      Next

      AddElement(Chunks())
      Chunks()\Ptr = BufAddr\P
      Chunks()\Len = FLen
    Next

    If ListSize(Chunks()) = 0
      LBLastError = "Nenhum arquivo de entrada"
      ProcedureReturn #False
    EndIf

    Protected OutFileNum = CreateFile(#PB_Any, LibPath + ".tmp")
    If Not OutFileNum
      ForEach Chunks() : FreeMemory(Chunks()\Ptr) : Next
      LBLastError = "Nao consegui criar " + LibPath + ".tmp"
      ProcedureReturn #False
    EndIf

    If AppendMode
      Protected ExistBufAddr.Z80LibPtrBox
      Protected ExistLen = LB_ReadWholeFile(LibPath, @ExistBufAddr)
      WriteData(OutFileNum, ExistBufAddr\P, ExistLen - 1) ; sem o Fim de Arquivo antigo
      FreeMemory(ExistBufAddr\P)
    EndIf

    Protected Total = ListSize(Chunks())
    Protected Idx = 0
    ForEach Chunks()
      Idx + 1
      If Idx < Total
        WriteData(OutFileNum, Chunks()\Ptr, Chunks()\Len - 1) ; sem o Fim de Arquivo deste pedaco
      Else
        WriteData(OutFileNum, Chunks()\Ptr, Chunks()\Len)     ; ultimo pedaco - mantem o Fim de Arquivo
      EndIf
      FreeMemory(Chunks()\Ptr)
    Next
    CloseFile(OutFileNum)

    If FileSize(LibPath) >= 0
      DeleteFile(LibPath)
    EndIf
    RenameFile(LibPath + ".tmp", LibPath)
    ProcedureReturn #True
  EndProcedure

  Procedure.b RemoveProgram(LibPath.s, ProgramName.s)
    LBLastError = ""
    Protected BufAddr.Z80LibPtrBox
    Protected FLen = LB_ReadWholeFile(LibPath, @BufAddr)
    If FLen < 0
      LBLastError = "Nao consegui abrir " + LibPath
      ProcedureReturn #False
    EndIf

    Protected NewList Ranges.Z80LibProgramRange()
    If Not IndexLibraryBuffer(BufAddr\P, FLen, Ranges())
      FreeMemory(BufAddr\P)
      LBLastError = "Erro fazendo parse de " + LibPath
      ProcedureReturn #False
    EndIf

    Protected Key.s = UCase(ProgramName)
    Protected FoundStart.i = -1, FoundEnd.i
    ForEach Ranges()
      If UCase(Ranges()\Name) = Key
        FoundStart = Ranges()\ByteStart
        FoundEnd = Ranges()\ByteEnd
        Break
      EndIf
    Next
    If FoundStart < 0
      FreeMemory(BufAddr\P)
      LBLastError = "Programa '" + ProgramName + "' nao encontrado em " + LibPath
      ProcedureReturn #False
    EndIf

    If ListSize(Ranges()) = 1
      FreeMemory(BufAddr\P)
      DeleteFile(LibPath)
      ProcedureReturn #True
    EndIf

    Protected OutFileNum = CreateFile(#PB_Any, LibPath + ".tmp")
    If Not OutFileNum
      FreeMemory(BufAddr\P)
      LBLastError = "Nao consegui criar " + LibPath + ".tmp"
      ProcedureReturn #False
    EndIf
    If FoundStart > 0
      WriteData(OutFileNum, BufAddr\P, FoundStart)
    EndIf
    If FoundEnd < FLen
      WriteData(OutFileNum, BufAddr\P + FoundEnd, FLen - FoundEnd)
    EndIf
    CloseFile(OutFileNum)
    FreeMemory(BufAddr\P)

    DeleteFile(LibPath)
    RenameFile(LibPath + ".tmp", LibPath)
    ProcedureReturn #True
  EndProcedure

EndModule
