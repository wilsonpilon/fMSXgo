;
; ------------------------------------------------------------
;  Z80Asm.pbi - assembler Z80 nativo, compativel M80/L80 (dialeto N80/
;  Nestor80 de Konamiman, https://github.com/Konamiman/Nestor80 - clone de
;  referencia gitignored em nestor80/, NAO dependencia de runtime, ver
;  docs/resumo-asm.md e docs/reference/nestor80-language.md).
;
;  DeclareModule real (nao so prefixo) porque o subsistema tem muitos verbos
;  genericos (Process/Resolve/Emit) que colidiriam com o resto do arquivo -
;  mesma decisao ja tomada para ProjectDB.pbi/MSXDisk.pbi.
;
;  Vocabulario (mnemonicos/registradores/diretivas/operadores) e usado tanto
;  pelo motor quanto pelo realce de sintaxe HighlightZ80Text() em
;  BadigEditor.pb - fonte unica aqui dentro, o highlighter so consome via
;  Z80Asm::IsMnemonic()/IsRegister()/IsDirective()/IsOperatorWord().
; ------------------------------------------------------------
;

DeclareModule Z80Asm
  ; Structure Z80Addr/Enumeration Z80SegType - ver comentario no topo de
  ; Z80RelFormat.pbi sobre por que a inclusao tem que acontecer aqui dentro.
  XIncludeFile "Z80RelFormat.pbi"

  ; Resultado de ParseLine() - precisa estar aqui dentro (nao so no Module)
  ; pelo mesmo motivo de Z80Addr, ver comentario acima/docs/resumo-asm.md.
  Structure Z80ParsedLine
    HasLabel.b
    Label.s          ; maiusculo, sem os dois-pontos
    LabelIsPublic.b  ; "::" em vez de ":" (so relevante pra Fase B/REL)
    LabelHasColon.b  ; #True = rotulo classico "nome:"; #False = veio da forma
                      ; "nome EQU/DEFL/ASET valor" (sem dois-pontos, ver LR/M80 -
                      ; EQU/DEFL/ASET sao "constantDefinitionOpcodes", o simbolo
                      ; antes deles nunca precisa de ":")
    HasOperator.b
    Operator.s       ; maiusculo - mnemonico Z80, diretiva ou (Fase A ainda nao) nome de macro
    ArgsText.s       ; texto cru dos argumentos, comentario ja removido, case original preservado
    HasComment.b
    Comment.s        ; sem o ";" inicial
    IsBlank.b        ; linha vazia ou so comentario (sem label nem operador)
  EndStructure

  ; Uma LINHA de listagem estilo assembler classico (endereco/valor + ate 4
  ; bytes hexa + linha-fonte), pedido explicito do usuario reproduzindo o
  ; formato do comando A do MegaAssembler original - ver comentario de
  ; GetListingRowCount()/GetListingRow() abaixo pro detalhe completo. Uma
  ; UNICA linha-fonte que gera mais de 4 bytes (DEFM de string longa, por
  ; exemplo) vira VARIAS Z80ListingRow em sequencia - so a PRIMEIRA tem
  ; SourceLine/HasAddr preenchidos, as de continuacao tem so os bytes.
  Structure Z80ListingRow
    SourceLine.i  ; numero da linha-fonte (1-based, mesma numeracao de GetAssembleErrorLine())
                   ; - 0 numa linha de CONTINUACAO (bytes extras da MESMA linha-fonte anterior)
    HasAddr.b      ; #True so' na 1a linha de cada grupo - #False nas de continuacao
    IsEqu.b        ; #True = Addr abaixo e' na verdade o VALOR resolvido do EQU/DEFL/ASET,
                    ; nao um endereco de memoria
    Addr.u
    ByteCount.b    ; quantos dos 4 campos Byte0..Byte3 abaixo sao validos nesta linha (0-4)
    Byte0.a
    Byte1.a
    Byte2.a
    Byte3.a
  EndStructure

  ; Uma LINHA de referencia cruzada de simbolos (opcao R do comando A - ver
  ; comentario de GetXrefRowCount()/GetXrefRow() abaixo). Um simbolo com mais
  ; de 4 usos vira VARIAS Z80XrefRow em sequencia (mesmo idioma de
  ; Z80ListingRow acima) - so a PRIMEIRA linha de cada simbolo tem
  ; SymName/HasValue/Value preenchidos, as de continuacao so' tem os
  ; enderecos de uso extras.
  Structure Z80XrefRow
    SymName.s      ; nome do simbolo (maiusculas) - "" numa linha de CONTINUACAO
    HasValue.b     ; #True so' na 1a linha de cada simbolo - #False nas de continuacao
    Value.u        ; valor guardado do simbolo (endereco de definicao pra rotulo
                    ; posicional, valor constante pra EQU/DEFL/ASET - Assemble() nao
                    ; distingue os dois casos, e' o MESMO campo Symbols()\Addr\Value)
    AddrCount.b    ; quantos dos 4 campos Addr0..Addr3 abaixo sao validos nesta linha (0-4)
    Addr0.u
    Addr1.u
    Addr2.u
    Addr3.u
  EndStructure

  Declare InitKeywordMaps()
  Declare.i IsMnemonic(Word.s)
  Declare.i IsRegister(Word.s)
  Declare.i IsDirective(Word.s)
  Declare.i IsOperatorWord(Word.s)

  ; Listas achatadas (uma palavra por espaco, maiusculas) do vocabulario
  ; acima - KwMnemonic()/KwRegister()/KwDirective()/KwOperatorWord() sao
  ; Maps privados do Module (nao aparecem aqui dentro do DeclareModule),
  ; entao quem precisa enumerar tudo (ex.: auto completar do modo "ASM" em
  ; BadigEditor.pb) usa isso em vez de acessar os Maps direto - mesmo formato
  ; que FillKeywordMap() ja consome do lado de fora.
  Declare.s MnemonicList()
  Declare.s RegisterList()
  Declare.s DirectiveList()
  Declare.s OperatorWordList()

  ; Avaliador de expressao + tabela de simbolos (ver docs/reference/nestor80-language.md)
  Declare   ResetState()
  Declare   SetCurrentLocation(Value.u)
  Declare.i DefineSymbol(Name.s, Value.u, IsConstant.b = #False)
  Declare.i IsSymbolKnown(Name.s)
  Declare.u GetSymbolValue(Name.s)
  Declare.i EvalExpr(Text.s, *Out.Z80Addr)
  Declare.s GetLastEvalError()
  Declare.s GetLastEvalUnknownSymbol()

  ; Parser de linha (ver docs/reference/nestor80-language.md, "Formato da linha-fonte")
  Declare.b ParseLine(RawLine.s, *Out.Z80ParsedLine)

  ; Codificador de instrucao Z80 (tabela de opcodes) - EmitMode=#False so calcula o
  ; tamanho em bytes (usado no pass 1, nao avalia expressao nenhuma); EmitMode=#True
  ; avalia as expressoes de verdade e preenche Out() (usado no pass 2). Out() precisa
  ; vir dimensionado Array Out.a(3) pelo chamador (toda instrucao Z80 cabe em 4 bytes).
  ; ArgsText = texto cru dos operandos (0/1/2, separados por virgula), tipicamente
  ; vindo direto de Z80ParsedLine\ArgsText. Devolve o numero de bytes (0-4) ou -1 em
  ; erro (ver GetLastAsmError()). Le/usa CurLoc (ver SetCurrentLocation()) pra
  ; calcular deslocamento relativo de JR/DJNZ - o chamador precisa ter ajustado
  ; CurLoc pro endereco desta instrucao ANTES de chamar.
  Declare.i EncodeInstruction(Mnemonic.s, ArgsText.s, EmitMode.b, Array Out.a(1))
  Declare.s GetLastAsmError()

  ; Escritor de bit-stream do formato .REL (Fase B - ver docs/reference/nestor80-rel-format.md
  ; e docs/resumo-asm.md). Espelha, em baixo nivel, Assembler/Relocatable/BitStreamWriter.cs +
  ; a camada WriteByte/WriteAddress/WriteLinkItem/WriteSymbolField de Assembler/OutputGenerator.cs
  ; do Nestor80 - so o formato ESTENDIDO e suportado (recomendacao da propria doc de referencia;
  ; o legado --link-80-compatibility fica de fora). Um .REL e um bit-stream (nao byte-alinhado):
  ; prefixo "0"+8 bits = byte absoluto; prefixo "1"+2 bits de segmento (so CSEG/DSEG/COMMON -
  ; "1"+"00" e reservado pro item de link)+16 bits (LE) = valor relocavel; prefixo "100"+4 bits
  ; de tipo (+ campos opcionais de endereco/simbolo) = item de link. Validado byte a byte contra
  ; um .REL minimo real do N80.exe, ver log de decisoes tecnicas em docs/resumo-asm.md.
  ; Ainda NAO integrado ao driver de 2 passes (Assemble()) - essa e a proxima tarefa da Fase B
  ; (deteccao build absoluto vs. relocavel + serializacao real linha a linha).
  Enumeration Z80RelItemType
    #Z80Rel_EntrySymbol          ; 0  - simbolo PUBLIC (declarado no topo do arquivo)
    #Z80Rel_SelectCommonBlock    ; 1  - troca o bloco COMMON ativo
    #Z80Rel_ProgramName          ; 2  - NAME/TITLE
    #Z80Rel_RequestLibrarySearch ; 3  - .REQUEST
    #Z80Rel_ExtensionLinkItem    ; 4  - item de extensao (expressao com externo, RPN)
    #Z80Rel_DefineCommonSize     ; 5  - tamanho de um bloco COMMON
    #Z80Rel_ChainExternal        ; 6  - cadeia de posicoes a corrigir pra um externo
    #Z80Rel_DefineEntryPoint     ; 7  - define valor de um simbolo PUBLIC
    #Z80Rel_ExternalMinusOffset  ; 8  - nunca gerado pelo MACRO-80/Nestor80
    #Z80Rel_ExternalPlusOffset   ; 9  - simbolo+valor / simbolo-valor
    #Z80Rel_DataAreaSize         ; 10 - tamanho total do DSEG
    #Z80Rel_SetLocationCounter   ; 11 - ASEG/CSEG/DSEG/COMMON trocam o contador de localizacao
    #Z80Rel_ChainAddress         ; 12 - nunca gerado de verdade
    #Z80Rel_ProgramAreaSize      ; 13 - tamanho total do CSEG
    #Z80Rel_EndProgram           ; 14 - fim do programa (forca alinhamento de byte)
    #Z80Rel_EndFile              ; 15 - fim do arquivo, sem campos
  EndEnumeration

  Declare   RelW_Reset()
  Declare   RelW_WriteBits(Value.l, NBits.b)
  Declare   RelW_WriteExtendedHeader()
  Declare   RelW_WriteByteItem(B.a)
  Declare   RelW_WriteValueItem(SegType.b, Value.u)
  Declare   RelW_WriteLinkItem(ItemType.b, HasAddr.b = #False, AddrSeg.b = 0, AddrValue.u = 0, HasSymbol.b = #False, Symbol.s = "")
  Declare   RelW_ForceByteBoundary()
  Declare.i RelW_GetByteCount()
  Declare.i RelW_GetBytes(Array Out.a(1))

  ; Driver relocavel (Fase B, integrado ao driver de 2 passes) - detecta e
  ; monta builds que usam CSEG/DSEG/COMMON/PUBLIC/EXTRN de verdade, gerando
  ; um .REL via RelW_* acima. Convive com o driver absoluto (Assemble()) sem
  ; alterar seu comportamento - cada um serve um formato de saida diferente,
  ; ver comentario da secao RunOnePassRel em Z80Asm.pbi pro escopo suportado/
  ; nao suportado (expressao externa composta, valor relocavel de 1 byte,
  ; .PHASE no modo relocavel, biblioteca ficam pra depois). Erros usam os
  ; MESMOS GetAssembleErrorLine()/GetAssembleErrorText() de Assemble().
  Declare.i NeedsRelocatable(SourceText.s)
  Declare.i AssembleRelocatable(SourceText.s, ProgramName.s, Array OutBytes.a(1))

  ; Driver de 2 passes - so absoluto por enquanto (ORG/label/EQU/DEFL/ASET/
  ; instrucoes de CPU; ASEG/CSEG/DSEG/COMMON/PUBLIC/EXTRN reconhecidas sem
  ; efeito pleno - Fase B). OutBytes precisa vir dimensionado pelo chamador
  ; com pelo menos 65536 posicoes (Array OutBytes.a(65535)) - devolve quantos
  ; bytes de fato foram usados (0 = nada gerado) ou -1 em erro (ver
  ; GetAssembleErrorLine()/GetAssembleErrorText()).
  Declare.i Assemble(SourceText.s, Array OutBytes.a(1))
  Declare.i GetAssembleErrorLine()
  Declare.s GetAssembleErrorText()
  ; Endereco do primeiro/ultimo byte tocado na ultima chamada a Assemble() -
  ; so tem sentido depois de uma chamada com sucesso (N > 0); usado pra
  ; montar o cabecalho MSX BLOAD (FE + inicio + fim + execucao), ver
  ; AssembleZ80FromActiveTab() em BadigEditor.pb.
  Declare.u GetAssembleStartAddr()
  Declare.u GetAssembleEndAddr()

  ; Listagem estilo assembler classico (Z80ListingRow acima) da ULTIMA
  ; chamada a Assemble() - so' populada de verdade quando Assemble() tem
  ; SUCESSO (gravada durante o PASS 2/emissao de RunOnePass, unico pass com
  ; enderecos/valores ja resolvidos de verdade - pass 1 nunca escreve aqui).
  ; Pedido explicito do usuario, reproduzindo o formato do comando A do
  ; MegaAssembler original: "numero_da_linha, o_endereco ou o_valor do EQU,
  ; ate 4 codigos hexa (mais linhas se precisar), o conteudo da linha".
  ; Padrao indice+getter (como GetAssembleErrorLine/Text acima) em vez de
  ; devolver um List() direto - mais simples, sem depender de passar List
  ; por parametro atraves da fronteira do Module.
  Declare.i GetListingRowCount()
  Declare GetListingRow(Index.i, *Out.Z80ListingRow)

  ; Referencia cruzada de simbolos (Z80XrefRow acima) da ULTIMA chamada a
  ; Assemble() com sucesso - mesmo padrao indice+getter de GetListingRow()
  ; acima, mesma razao (nao passar List pela fronteira do Module). Ordenada
  ; alfabeticamente por nome de simbolo; dentro de cada simbolo, os
  ; enderecos de uso vem em ORDEM DE OCORRENCIA no fonte (= ordem crescente
  ; de endereco, ja que o pass 2 varre o programa de cima pra baixo).
  Declare.i GetXrefRowCount()
  Declare GetXrefRow(Index.i, *Out.Z80XrefRow)

  ; Nomes de simbolo em ordem de DEFINICAO/aparicao no fonte (opcao D do
  ; comando A, Mamute - "identica ao S, porem por ordem de aparicao e nao
  ; alfabetica") - indice+getter de novo, devolve so' o NOME; o valor/
  ; endereco de cada um ja e' publico via GetSymbolValue(Name) (acima).
  Declare.i GetLabelDefOrderCount()
  Declare.s GetLabelDefOrderName(Index.i)
EndDeclareModule

Module Z80Asm

  Global NewMap KwMnemonic.b()
  Global NewMap KwRegister.b()
  Global NewMap KwDirective.b()
  Global NewMap KwOperatorWord.b()
  Global KeywordMapsReady.b = #False

  ;- ------------------------------------------------------------
  ;- Vocabulario (mesmas listas que estavam em BadigEditor.pb ate 2026-07-24,
  ;- migradas pra ca - ver docs/resumo-asm.md, tarefa "Migrar tabelas de
  ;- keyword Z80 para Z80Asm.pbi")
  ;- ------------------------------------------------------------

  Procedure FillKwMap(Map Dest.b(), Words.s)
    Protected Count = CountString(Words, " ") + 1
    Protected Idx, Word.s
    For Idx = 1 To Count
      Word = StringField(Words, Idx, " ")
      If Word <> ""
        Dest(Word) = #True
      EndIf
    Next
  EndProcedure

  Procedure InitKeywordMaps()
    If KeywordMapsReady
      ProcedureReturn
    EndIf

    ; Mnemonicos Z80 (documentados + indocumentados de uso comum, ex. SLL)
    FillKwMap(KwMnemonic(),
      "ADC ADD AND BIT CALL CCF CP CPD CPDR CPI CPIR CPL DAA DEC DI DJNZ EI EX " +
      "EXX HALT IM IN INC IND INDR INI INIR JP JR LD LDD LDDR LDI LDIR NEG NOP " +
      "OR OTDR OTIR OUT OUTD OUTI POP PUSH RES RET RETI RETN RL RLA RLC RLCA " +
      "RLD RR RRA RRC RRCA RRD RST SBC SCF SET SLA SLL SRA SRL SUB XOR")

    ; Registradores e codigos de condicao de desvio (NZ/Z/NC/C/PO/PE/P/M) -
    ; tratados com o mesmo estilo (ambos sao "operandos de hardware")
    FillKwMap(KwRegister(),
      "A B C D E H L I R IX IY SP AF BC DE HL PC IXH IXL IYH IYL NZ Z NC PO PE P M")

    ; Diretivas do assembler - inclui as com "." do dialeto N80 (RADIX/PHASE/
    ; etc guardadas SEM o ponto aqui; o "." e reconhecido a parte no lexer,
    ; ver Z80_ScanDotWord() dentro de HighlightZ80Text em BadigEditor.pb)
    FillKwMap(KwDirective(),
      "EQU DEFL ASET ORG DEFB DB DEFM DEFW DW DEFS DS DEFZ DZ INCBIN PUBLIC " +
      "ENTRY GLOBAL EXTRN EXT EXTERNAL ROOT IF IFT COND IFF IFE IF1 IF2 IFABS " +
      "IFREL IFDEF IFNDEF IFB IFNB IFIDN IFIDNI IFDIF IFDIFI IFCPU IFNCPU ELSE " +
      "ENDIF MACRO ENDM REPT IRP IRPC IRPS LOCAL EXITM CONTM MODULE ENDMOD " +
      "ASEG CSEG DSEG COMMON AREA TITLE SUBTTL PAGE MAINPAGE END ENDOUT " +
      "RELAB XRELAB EXTROOT XEXTROOT PHASE DEPHASE LIST XLIST LALL SALL XALL " +
      "LFCOND SFCOND TFCOND CPU Z80 STRENC STRESC PRINT PRINT1 PRINT2 PRINTX " +
      "WARN ERROR FATAL REQUEST RADIX ALIGN COMMENT CREF XCREF")

    ; Operadores por extenso usados em expressoes (AND/OR/XOR/NOT ficam de fora
    ; daqui de proposito - ja sao reconhecidos como mnemonicos acima, e o
    ; destaque visual e o mesmo nos dois usos)
    FillKwMap(KwOperatorWord(), "LOW HIGH MOD SHR SHL EQ NE NEQ LT LE LTE GT GE GTE NUL TYPE")

    KeywordMapsReady = #True
  EndProcedure

  Procedure.i IsMnemonic(Word.s)
    InitKeywordMaps()
    ProcedureReturn Bool(FindMapElement(KwMnemonic(), UCase(Word)))
  EndProcedure

  Procedure.i IsRegister(Word.s)
    InitKeywordMaps()
    ProcedureReturn Bool(FindMapElement(KwRegister(), UCase(Word)))
  EndProcedure

  Procedure.i IsDirective(Word.s)
    InitKeywordMaps()
    ProcedureReturn Bool(FindMapElement(KwDirective(), UCase(Word)))
  EndProcedure

  Procedure.i IsOperatorWord(Word.s)
    InitKeywordMaps()
    ProcedureReturn Bool(FindMapElement(KwOperatorWord(), UCase(Word)))
  EndProcedure

  Procedure.s MnemonicList()
    InitKeywordMaps()
    Protected Result.s = ""
    ForEach KwMnemonic()
      If Result <> "" : Result + " " : EndIf
      Result + MapKey(KwMnemonic())
    Next
    ProcedureReturn Result
  EndProcedure

  Procedure.s RegisterList()
    InitKeywordMaps()
    Protected Result.s = ""
    ForEach KwRegister()
      If Result <> "" : Result + " " : EndIf
      Result + MapKey(KwRegister())
    Next
    ProcedureReturn Result
  EndProcedure

  Procedure.s DirectiveList()
    InitKeywordMaps()
    Protected Result.s = ""
    ForEach KwDirective()
      If Result <> "" : Result + " " : EndIf
      Result + MapKey(KwDirective())
    Next
    ProcedureReturn Result
  EndProcedure

  Procedure.s OperatorWordList()
    InitKeywordMaps()
    Protected Result.s = ""
    ForEach KwOperatorWord()
      If Result <> "" : Result + " " : EndIf
      Result + MapKey(KwOperatorWord())
    Next
    ProcedureReturn Result
  EndProcedure

  ;- ------------------------------------------------------------
  ;- Tabela de simbolos + avaliador de expressao (RPN/shunting-yard) - mesma
  ;- precedencia e regras do Nestor80 (Assembler/Expressions/Expression*.cs,
  ;- valores de Precedence conferidos direto no fonte C#), ver
  ;- docs/reference/nestor80-language.md secao "Expressoes". Motor
  ;- autocontido (nao depende de nenhum helper de BadigEditor.pb - eles sao
  ;- declarados textualmente DEPOIS do ponto de XIncludeFile deste arquivo,
  ;- entao nao estariam visiveis aqui).
  ;- ------------------------------------------------------------

  ; Helpers de Z80Addr (construtor + comparacao de segmento) - vivem aqui
  ; dentro do Module, nao em Z80RelFormat.pbi, porque esse arquivo so pode
  ; conter Structure/Enumeration (ver comentario no topo dele); o futuro
  ; Z80Link.pbi (Fase B) tera sua propria copia trivial destes 3 helpers.

  Procedure Z80Addr_Make(*Out.Z80Addr, Value.u, SegType.b, CommonName.s = "")
    *Out\Value = Value
    *Out\SegType = SegType
    *Out\CommonName = CommonName
  EndProcedure

  Procedure.b Z80Addr_IsAbsolute(*A.Z80Addr)
    ProcedureReturn Bool(*A\SegType = #Z80Seg_Absolute)
  EndProcedure

  ; Compara segmento (nao valor) - usado pelo avaliador de expressao pra
  ; decidir se uma subtracao entre dois valores relocaveis do mesmo segmento
  ; vira um valor absoluto (regra do Nestor80/M80: end1-end2 no mesmo
  ; segmento = distancia absoluta) - sem consumidor ainda na Fase A (so
  ; ASEG existe de verdade), fica pronta pra Fase B.
  Procedure.b Z80Addr_SameSegment(*A.Z80Addr, *B.Z80Addr)
    If *A\SegType <> *B\SegType
      ProcedureReturn #False
    EndIf
    If *A\SegType = #Z80Seg_Common
      ProcedureReturn Bool(*A\CommonName = *B\CommonName)
    EndIf
    ProcedureReturn #True
  EndProcedure

  Structure Z80Symbol
    Addr.Z80Addr
    IsKnown.b     ; ja recebeu um valor (rotulo definido / EQU / DEFL atribuido)
    IsConstant.b  ; EQU - nao pode ser redefinido (DEFL e rotulo podem)
  EndStructure

  ; Estado auxiliar do driver relocavel (RunOnePassRel/AssembleRelocatable,
  ; Fase B - ver secao propria mais abaixo, depois de RelW_*).
  Structure Z80RelChainState
    LastPos.Z80Addr  ; posicao (area+valor) do ultimo slot escrito pra esse externo ate agora
    DisplayName.s    ; grafia com maiusc/minusc ORIGINAL (da 1a ocorrencia) - usada no ChainExternal
                      ; final; a CHAVE do Map (sempre maiuscula) e so pra casar case-insensitive
  EndStructure

  Structure Z80RelCommonSizeEntry
    Name.s
    Size.u
  EndStructure

  Global NewMap Symbols.Z80Symbol()
  Global CurLoc.Z80Addr    ; contador de localizacao "reportado" ($/rotulos/JR) - atualizado pelo
                           ; driver de 2 passes; dentro de um bloco .PHASE, difere da posicao real de
                           ; escrita (ver RealPos/PhaseActive logo abaixo e docs/resumo-asm.md)
  Global RealPos.u         ; posicao real de escrita em Mem() - sempre avanca em lockstep com CurLoc
                           ; (mesma quantidade de bytes a cada instrucao/diretiva), mas so os DOIS
                           ; sao iguais fora de um bloco .PHASE
  Global PhaseActive.b = #False
  Global PassNumber.b = 1  ; 1 ou 2 - idem
  Global LastEvalError.s
  Global LastEvalUnknownSymbol.s
  Global AsmErrorLine.i    ; erro do driver de 2 passes (absoluto OU relocavel - GetAssembleErrorLine/Text
  Global AsmErrorText.s    ; ja precisam disso aqui em cima porque RunOnePassRel usa antes de RunOnePass no arquivo)

  ; Listagem estilo assembler classico (ver Z80ListingRow/GetListingRow no
  ; DeclareModule) - so' RunOnePass (driver ABSOLUTO) grava aqui por hora,
  ; so' durante o pass de EMISSAO (SizeOnly=#False) - RunOnePassRel nao
  ; participa disso ainda (ninguem pediu listagem pro modo relocavel).
  Global NewList ZListingRows.Z80ListingRow()

  ; Registro CRU de cada uso de simbolo (nome + endereco de quem referenciou),
  ; gravado dentro de EvalPostfixExpr() (Case #Z80Tk_Symbol, mais abaixo) toda
  ; vez que um simbolo CONHECIDO e' resolvido durante o pass de EMISSAO
  ; (PassNumber=2, agora finalmente usado pra isso - ver comentario do
  ; proprio Global acima). XrefBuildRows() (mais abaixo) consome isso pra
  ; montar XrefRows() (agrupado por simbolo, ordenado, fatiado em blocos de
  ; ate 4 - mesmo idioma de Z80ListingRow/ZListing_AddRow acima).
  Structure Z80SymbolRef
    SymName.s
    Addr.u
  EndStructure
  Global NewList SymbolRefs.Z80SymbolRef()
  Global NewList XrefRows.Z80XrefRow()

  ; Nomes de simbolo em ORDEM DE DEFINICAO (= ordem de aparicao no fonte,
  ; ver comentario dentro de DefineSymbolSeg() acima) - opcao D do comando A
  ; (Mamute), "identica ao S, porem a lista de labels e' por ordem de
  ; aparicao e nao alfabetica" (pedido explicito do usuario). Cada nome
  ; aparece UMA vez so', gravado no momento exato em que o simbolo vira
  ; conhecido de verdade (nao na 1a MENCAO, que pode ser uma referencia pra
  ; frente antes da definicao de verdade).
  Global NewList SymbolDefOrder.s()

  ; Acrescenta 1+ Z80ListingRow cobrindo ByteVals() (List.a(), qualquer
  ; tamanho) em fatias de ate 4 bytes - so' a PRIMEIRA fatia leva
  ; SourceLine/HasAddr/IsEqu/Addr; as de continuacao ficam com esses campos
  ; zerados/em branco (ver comentario de Z80ListingRow). Chamada tanto pra
  ; instrucoes de CPU quanto pra diretivas de dados - os dois emissores
  ; convergem aqui em vez de duplicar a logica de fatiamento.
  Procedure ZListing_AddRow(SrcLine.i, IsEquLine.b, AddrOrValue.u, List ByteVals.a())
    Protected First.b = #True
    Protected Chunk.i = 0
    ForEach ByteVals()
      If Chunk = 0
        AddElement(ZListingRows())
        If First
          ZListingRows()\SourceLine = SrcLine
          ZListingRows()\HasAddr = #True
          ZListingRows()\IsEqu = IsEquLine
          ZListingRows()\Addr = AddrOrValue
          First = #False
        EndIf
      EndIf
      Select Chunk
        Case 0 : ZListingRows()\Byte0 = ByteVals()
        Case 1 : ZListingRows()\Byte1 = ByteVals()
        Case 2 : ZListingRows()\Byte2 = ByteVals()
        Case 3 : ZListingRows()\Byte3 = ByteVals()
      EndSelect
      ZListingRows()\ByteCount + 1
      Chunk + 1
      If Chunk >= 4 : Chunk = 0 : EndIf
    Next
    ; linha SEM bytes (EQU/DEFL/ASET, ou DS sem preenchimento) - ainda
    ; precisa de 1 linha na listagem, so' com o endereco/valor.
    If ListSize(ByteVals()) = 0
      AddElement(ZListingRows())
      ZListingRows()\SourceLine = SrcLine
      ZListingRows()\HasAddr = #True
      ZListingRows()\IsEqu = IsEquLine
      ZListingRows()\Addr = AddrOrValue
      ZListingRows()\ByteCount = 0
    EndIf
  EndProcedure

  ; Monta XrefRows() a partir de Symbols() (tabela final, pos-pass2) +
  ; SymbolRefs() (usos gravados por EvalPostfixExpr() durante o pass de
  ; emissao) - chamada do fim de Assemble() em toda montagem bem-sucedida.
  ; Ordena por NOME (SortList() em maiusculas = ordem alfabetica classica,
  ; mesma convencao do print do MegaAssembler original); dentro de cada
  ; simbolo, os enderecos de uso ficam na ORDEM em que SymbolRefs() foi
  ; preenchido (= ordem de ocorrencia no fonte = ordem crescente de
  ; endereco). Simbolo sem NENHUM uso ainda ganha 1 linha (so' com o valor,
  ; AddrCount=0) - aparece na referencia cruzada mesmo assim, mesmo espirito
  ; de um "definido mas nunca usado" ser informacao util pro programador.
  Procedure XrefBuildRows()
    ClearList(XrefRows())

    NewList Names.s()
    ForEach Symbols()
      If Symbols()\IsKnown
        AddElement(Names())
        Names() = MapKey(Symbols())
      EndIf
    Next
    SortList(Names(), #PB_Sort_Ascending)

    Protected SymValue.u, UseCount.i, Remaining.i, ThisChunk.i, b.i
    Protected FirstRow.b
    ForEach Names()
      SymValue = Symbols(Names())\Addr\Value

      NewList UseAddrs.u()
      ForEach SymbolRefs()
        If SymbolRefs()\SymName = Names()
          AddElement(UseAddrs())
          UseAddrs() = SymbolRefs()\Addr
        EndIf
      Next
      UseCount = ListSize(UseAddrs())
      ResetList(UseAddrs())

      FirstRow = #True
      If UseCount = 0
        AddElement(XrefRows())
        XrefRows()\SymName = Names()
        XrefRows()\HasValue = #True
        XrefRows()\Value = SymValue
        XrefRows()\AddrCount = 0
      Else
        Remaining = UseCount
        While Remaining > 0
          AddElement(XrefRows())
          If FirstRow
            XrefRows()\SymName = Names()
            XrefRows()\HasValue = #True
            XrefRows()\Value = SymValue
            FirstRow = #False
          EndIf
          ThisChunk = Remaining
          If ThisChunk > 4 : ThisChunk = 4 : EndIf
          XrefRows()\AddrCount = ThisChunk
          For b = 0 To ThisChunk - 1
            NextElement(UseAddrs())
            Select b
              Case 0 : XrefRows()\Addr0 = UseAddrs()
              Case 1 : XrefRows()\Addr1 = UseAddrs()
              Case 2 : XrefRows()\Addr2 = UseAddrs()
              Case 3 : XrefRows()\Addr3 = UseAddrs()
            EndSelect
          Next
          Remaining - ThisChunk
        Wend
      EndIf
    Next
  EndProcedure

  Procedure.i GetXrefRowCount()
    ProcedureReturn ListSize(XrefRows())
  EndProcedure

  Procedure GetXrefRow(Index.i, *Out.Z80XrefRow)
    If Index < 0 Or Index >= ListSize(XrefRows())
      ProcedureReturn
    EndIf
    SelectElement(XrefRows(), Index)
    *Out\SymName = XrefRows()\SymName
    *Out\HasValue = XrefRows()\HasValue
    *Out\Value = XrefRows()\Value
    *Out\AddrCount = XrefRows()\AddrCount
    *Out\Addr0 = XrefRows()\Addr0
    *Out\Addr1 = XrefRows()\Addr1
    *Out\Addr2 = XrefRows()\Addr2
    *Out\Addr3 = XrefRows()\Addr3
  EndProcedure

  Procedure.i GetLabelDefOrderCount()
    ProcedureReturn ListSize(SymbolDefOrder())
  EndProcedure

  Procedure.s GetLabelDefOrderName(Index.i)
    If Index < 0 Or Index >= ListSize(SymbolDefOrder())
      ProcedureReturn ""
    EndIf
    SelectElement(SymbolDefOrder(), Index)
    ProcedureReturn SymbolDefOrder()
  EndProcedure

  ; Macros basicas (MACRO/ENDM/EXITM/LOCAL) - ver ExpandLines() mais abaixo.
  ; BodyText guarda o corpo cru com as linhas unidas por Chr(10) (mesmo
  ; padrao de "linhas unidas por Chr(10) numa unica coluna TEXT" ja usado em
  ; mml_songs no ProjectDB.pbi) - substituicao de parametro/LOCAL acontece
  ; por cima desse texto na hora da expansao, nao na hora da definicao.
  Structure Z80MacroDef
    ParamNames.s  ; nomes dos parametros, separados por espaco, em ordem posicional ("" = sem parametro)
    BodyText.s
  EndStructure

  Global NewMap Macros.Z80MacroDef()
  Global MacroExpansionCounter.i = 0

  Enumeration Z80OpCode
    #Z80Op_Plus
    #Z80Op_Minus
    #Z80Op_Mul
    #Z80Op_Div
    #Z80Op_Mod
    #Z80Op_Shl
    #Z80Op_Shr
    #Z80Op_And
    #Z80Op_Or
    #Z80Op_Xor
    #Z80Op_Not        ; unario (bitwise complement)
    #Z80Op_Eq
    #Z80Op_Ne
    #Z80Op_Lt
    #Z80Op_Le
    #Z80Op_Gt
    #Z80Op_Ge
    #Z80Op_High       ; unario
    #Z80Op_Low        ; unario
    #Z80Op_UnaryMinus
    #Z80Op_UnaryPlus
  EndEnumeration

  Enumeration Z80TokKind
    #Z80Tk_Number
    #Z80Tk_Symbol
    #Z80Tk_CurLoc     ; "$" isolado
    #Z80Tk_Operator
    #Z80Tk_LParen
    #Z80Tk_RParen
  EndEnumeration

  Structure Z80ExprTok
    Kind.b
    NumValue.Z80Addr  ; usado quando Kind = Number (e recebe o resultado ja avaliado durante EvalPostfix)
    SymName.s         ; usado quando Kind = Symbol
    IsExternal.b      ; sufixo ## (guardado, sem efeito ate a Fase B/linker)
    OpCode.b          ; usado quando Kind = Operator
  EndStructure

  ;- Classificacao de caracteres (copia local, deliberadamente independente
  ;- dos helpers globais de BadigEditor.pb - ver comentario da secao acima)

  Procedure.b ChIsDigit(C.s)
    ProcedureReturn Bool(C >= "0" And C <= "9")
  EndProcedure

  Procedure.b ChIsHexDigit(C.s)
    Protected U.s = UCase(C)
    ProcedureReturn Bool(ChIsDigit(C) Or (U >= "A" And U <= "F"))
  EndProcedure

  Procedure.b ChIsAlpha(C.s)
    Protected U.s = UCase(C)
    ProcedureReturn Bool(U >= "A" And U <= "Z")
  EndProcedure

  ; Caracteres validos de simbolo alem de letra/digito, por regra da
  ; linguagem (docs/reference/nestor80-language.md: letras, digitos, $.?@_;
  ; primeiro caractere nao pode ser digito). Restrito a ASCII de proposito -
  ; o Nestor80 aceita qualquer letra Unicode, mas fonte MSX/Z80 real e
  ; sempre ASCII na pratica; simplifica o scanner char-a-char em PureBasic.
  Procedure.b ChIsIdentExtra(C.s)
    ProcedureReturn Bool(C = "$" Or C = "." Or C = "?" Or C = "@" Or C = "_")
  EndProcedure

  Procedure.b ChIsIdentStart(C.s)
    ProcedureReturn Bool(ChIsAlpha(C) Or ChIsIdentExtra(C))
  EndProcedure

  Procedure.b ChIsIdentCont(C.s)
    ProcedureReturn Bool(ChIsAlpha(C) Or ChIsDigit(C) Or ChIsIdentExtra(C))
  EndProcedure

  ;- ------------------------------------------------------------
  ;- Parser de linha: "[label:[:]] [operador] [argumentos] [;comentario]"
  ;- (docs/reference/nestor80-language.md, "Formato da linha-fonte", LR:151-177).
  ;- So separa a linha em pedacos - NAO classifica o operador (mnemonico vs.
  ;- diretiva vs. nome de macro), isso e trabalho do driver de 2 passes
  ;- (proxima tarefa), que ja tem Z80Asm::IsMnemonic()/IsDirective() pra isso.
  ;- Nao trata ".COMMENT" (comentario multi-linha) - precisa de estado entre
  ;- linhas, fica a cargo do driver.
  ;- ------------------------------------------------------------

  ; Acha a posicao (1-based) do primeiro ";" fora de aspas, ou 0 se nao achar -
  ; consciente de string entre aspas simples/duplas (mesma regra de escape por
  ; aspa dobrada usada em TokenizeExpr: '' ou "" dentro do mesmo delimitador =
  ; aspa literal, nao fecha a string).
  Procedure.i FindCommentStart(Line.s)
    Protected LineLen = Len(Line)
    Protected I = 1, C.s, Delim.s
    While I <= LineLen
      C = Mid(Line, I, 1)
      If C = ";"
        ProcedureReturn I
      EndIf
      If C = Chr(34) Or C = "'"
        Delim = C
        I + 1
        While I <= LineLen
          C = Mid(Line, I, 1)
          If C = Delim
            If I < LineLen And Mid(Line, I + 1, 1) = Delim
              I + 2
              Continue
            EndIf
            I + 1
            Break
          EndIf
          I + 1
        Wend
        Continue
      EndIf
      I + 1
    Wend
    ProcedureReturn 0
  EndProcedure

  ; Devolve a posicao (1-based) do primeiro caractere nao-espaco/tab a partir
  ; de Start, ou Len(S)+1 se so sobrar espaco ate o fim (NAO usa Trim() -
  ; Trim() so remove espaco, nao tab, mesma armadilha ja documentada no
  ; historico do pre-processador Dignified, ver docs/SPEC.md modulo 3).
  Procedure.i SkipWs(S.s, Start.i)
    Protected L = Len(S), I = Start
    While I <= L And (Mid(S, I, 1) = " " Or Mid(S, I, 1) = Chr(9))
      I + 1
    Wend
    ProcedureReturn I
  EndProcedure

  ; Remove espaco/tab do fim de S (equivalente a RTrim, mas tab-aware).
  Procedure.s RTrimWs(S.s)
    Protected L = Len(S)
    While L > 0 And (Mid(S, L, 1) = " " Or Mid(S, L, 1) = Chr(9))
      L - 1
    Wend
    ProcedureReturn Left(S, L)
  EndProcedure

  Procedure.b ParseLine(RawLine.s, *Out.Z80ParsedLine)
    Protected CommentPos = FindCommentStart(RawLine)
    Protected Code.s
    Protected CodeLen, I, WStart, WStop, Word1.s, Word2.s, AfterWord1, P2, W2Start, W2End

    *Out\HasLabel = #False       : *Out\Label = ""
    *Out\LabelIsPublic = #False  : *Out\LabelHasColon = #False
    *Out\HasOperator = #False    : *Out\Operator = ""
    *Out\ArgsText = ""
    *Out\HasComment = #False     : *Out\Comment = ""
    *Out\IsBlank = #False

    If CommentPos > 0
      *Out\HasComment = #True
      *Out\Comment = RTrimWs(Mid(RawLine, SkipWs(RawLine, CommentPos + 1)))
      Code = Left(RawLine, CommentPos - 1)
    Else
      Code = RawLine
    EndIf

    CodeLen = Len(Code)
    I = SkipWs(Code, 1)

    If I > CodeLen
      ; nada alem de espaco (e talvez comentario) - linha em branco
      *Out\IsBlank = #True
      ProcedureReturn #True
    EndIf

    ; --- primeira palavra da linha ---
    If Not ChIsIdentStart(Mid(Code, I, 1))
      ; nao comeca com identificador valido - devolve tudo como ArgsText cru
      ; e deixa o driver de 2 passes reportar o erro de sintaxe (mesma
      ; postura de "nao implementa bare expression" da Fase A, ver LR:497).
      *Out\ArgsText = RTrimWs(Mid(Code, I))
      ProcedureReturn #True
    EndIf

    WStart = I
    I + 1
    While I <= CodeLen And ChIsIdentCont(Mid(Code, I, 1))
      I + 1
    Wend
    WStop = I - 1
    Word1 = UCase(Mid(Code, WStart, WStop - WStart + 1))
    AfterWord1 = I

    ; --- Forma classica "rotulo:" / "rotulo::" (LR:161) ---
    If I <= CodeLen And Mid(Code, I, 1) = ":"
      *Out\HasLabel = #True
      *Out\Label = Word1
      *Out\LabelHasColon = #True
      I + 1
      If I <= CodeLen And Mid(Code, I, 1) = ":"
        *Out\LabelIsPublic = #True
        I + 1
      EndIf

      I = SkipWs(Code, I)
      If I > CodeLen
        ProcedureReturn #True ; linha so com rotulo, sem operador
      EndIf
      If Not ChIsIdentStart(Mid(Code, I, 1))
        *Out\ArgsText = RTrimWs(Mid(Code, I))
        ProcedureReturn #True
      EndIf

      WStart = I
      I + 1
      While I <= CodeLen And ChIsIdentCont(Mid(Code, I, 1))
        I + 1
      Wend
      WStop = I - 1
      *Out\HasOperator = #True
      *Out\Operator = UCase(Mid(Code, WStart, WStop - WStart + 1))

      I = SkipWs(Code, I)
      If I <= CodeLen
        *Out\ArgsText = RTrimWs(Mid(Code, I))
      EndIf
      ProcedureReturn #True
    EndIf

    ; --- Sem ":" - pode ser "simbolo EQU/DEFL/ASET valor" (constantDefinitionOpcodes
    ; do Nestor80 - o simbolo antes deles NUNCA leva ":", ver
    ; docs/reference/nestor80-language.md, secao EQU/DEFL/ASET) ou "nome MACRO
    ; params" (mesma forma - nome da macro tambem fica em posicao de rotulo,
    ; sem ":" obrigatorio, ver secao "Macros: MACRO/ENDM/EXITM/LOCAL") ou
    ; entao Word1 ja e o proprio operador (mnemonico/diretiva/chamada de
    ; macro). So da pra saber espiando a proxima palavra.
    P2 = SkipWs(Code, AfterWord1)
    If P2 <= CodeLen And ChIsIdentStart(Mid(Code, P2, 1))
      W2Start = P2
      P2 + 1
      While P2 <= CodeLen And ChIsIdentCont(Mid(Code, P2, 1))
        P2 + 1
      Wend
      W2End = P2 - 1
      Word2 = UCase(Mid(Code, W2Start, W2End - W2Start + 1))

      If Word2 = "EQU" Or Word2 = "DEFL" Or Word2 = "ASET" Or Word2 = "MACRO"
        *Out\HasLabel = #True
        *Out\Label = Word1
        *Out\LabelHasColon = #False
        *Out\HasOperator = #True
        *Out\Operator = Word2

        P2 = SkipWs(Code, P2)
        If P2 <= CodeLen
          *Out\ArgsText = RTrimWs(Mid(Code, P2))
        EndIf
        ProcedureReturn #True
      EndIf
    EndIf

    ; --- Word1 e o proprio operador (sem rotulo) ---
    *Out\HasOperator = #True
    *Out\Operator = Word1
    I = SkipWs(Code, AfterWord1)
    If I <= CodeLen
      *Out\ArgsText = RTrimWs(Mid(Code, I))
    EndIf

    ProcedureReturn #True
  EndProcedure

  ;- Precedencia (menor numero = liga mais forte) e teste de "e unario" -
  ;- valores identicos aos de ArithmeticOperator.Precedence no fonte C# do
  ;- Nestor80 (Assembler/Expressions/ExpressionParts/ArithmeticOperators/*.cs).

  Procedure.i OpPrecedence(Op.b)
    Select Op
      Case #Z80Op_High, #Z80Op_Low
        ProcedureReturn 1
      Case #Z80Op_Mul, #Z80Op_Div, #Z80Op_Mod, #Z80Op_Shl, #Z80Op_Shr
        ProcedureReturn 2
      Case #Z80Op_UnaryMinus, #Z80Op_UnaryPlus
        ProcedureReturn 3
      Case #Z80Op_Plus, #Z80Op_Minus
        ProcedureReturn 4
      Case #Z80Op_Eq, #Z80Op_Ne, #Z80Op_Lt, #Z80Op_Le, #Z80Op_Gt, #Z80Op_Ge
        ProcedureReturn 5
      Case #Z80Op_Not
        ProcedureReturn 6
      Case #Z80Op_And
        ProcedureReturn 7
      Case #Z80Op_Or, #Z80Op_Xor
        ProcedureReturn 8
    EndSelect
    ProcedureReturn 99
  EndProcedure

  Procedure.b OpIsUnary(Op.b)
    ProcedureReturn Bool(Op = #Z80Op_Not Or Op = #Z80Op_High Or Op = #Z80Op_Low Or
                          Op = #Z80Op_UnaryMinus Or Op = #Z80Op_UnaryPlus)
  EndProcedure

  ; Palavra reservada -> opcode, para os operadores expressos por extenso
  ; (AND/OR/XOR/NOT sao reconhecidas aqui tambem, apesar de tambem serem
  ; mnemonicos Z80 - contexto de expressao sempre vence nesta funcao).
  ; Retorna -1 quando a palavra nao e nenhum operador conhecido.
  Procedure.i WordToOpCode(Word.s)
    Select UCase(Word)
      Case "AND"          : ProcedureReturn #Z80Op_And
      Case "OR"            : ProcedureReturn #Z80Op_Or
      Case "XOR"           : ProcedureReturn #Z80Op_Xor
      Case "NOT"           : ProcedureReturn #Z80Op_Not
      Case "MOD"           : ProcedureReturn #Z80Op_Mod
      Case "SHR"           : ProcedureReturn #Z80Op_Shr
      Case "SHL"           : ProcedureReturn #Z80Op_Shl
      Case "HIGH"          : ProcedureReturn #Z80Op_High
      Case "LOW"           : ProcedureReturn #Z80Op_Low
      Case "EQ"            : ProcedureReturn #Z80Op_Eq
      Case "NE", "NEQ"     : ProcedureReturn #Z80Op_Ne
      Case "LT"            : ProcedureReturn #Z80Op_Lt
      Case "LE", "LTE"     : ProcedureReturn #Z80Op_Le
      Case "GT"            : ProcedureReturn #Z80Op_Gt
      Case "GE", "GTE"     : ProcedureReturn #Z80Op_Ge
    EndSelect
    ProcedureReturn -1
  EndProcedure

  ;- ------------------------------------------------------------
  ;- Tokenizador de expressao (texto -> lista infixa de Z80ExprTok)
  ;- ------------------------------------------------------------

  ;- Helpers de validacao de digitos por base (usados pelo tokenizador abaixo -
  ;- precisam vir antes dele: PureBasic, dentro de um Module, nao resolve
  ;- chamada a uma Procedure ainda nao definida textualmente).

  Procedure.b CountAllHex(S.s)
    Protected Idx
    For Idx = 1 To Len(S)
      If Not ChIsHexDigit(Mid(S, Idx, 1)) : ProcedureReturn #False : EndIf
    Next
    ProcedureReturn #True
  EndProcedure

  Procedure.b CountAllOctal(S.s)
    Protected Idx, C.s
    For Idx = 1 To Len(S)
      C = Mid(S, Idx, 1)
      If C < "0" Or C > "7" : ProcedureReturn #False : EndIf
    Next
    ProcedureReturn #True
  EndProcedure

  Procedure.b CountAllDecimal(S.s)
    Protected Idx
    For Idx = 1 To Len(S)
      If Not ChIsDigit(Mid(S, Idx, 1)) : ProcedureReturn #False : EndIf
    Next
    ProcedureReturn #True
  EndProcedure

  Procedure.b CountAllBinary(S.s)
    Protected Idx, C.s
    For Idx = 1 To Len(S)
      C = Mid(S, Idx, 1)
      If C <> "0" And C <> "1" : ProcedureReturn #False : EndIf
    Next
    ProcedureReturn #True
  EndProcedure

  ; Converte uma sequencia de digitos octais para uma string hex equivalente
  ; (PureBasic Val() nao tem prefixo nativo pra octal) - constroi o valor
  ; digito a digito e devolve em hex pra reaproveitar Val("$"+...) no chamador.
  Procedure.s Hex_FromOctalDigits(S.s)
    Protected Idx, V.q = 0
    For Idx = 1 To Len(S)
      V = (V * 8) + (Asc(Mid(S, Idx, 1)) - Asc("0"))
    Next
    ProcedureReturn Hex(V)
  EndProcedure

  Procedure.b TokenizeExpr(Text.s, List Toks.Z80ExprTok())
    Protected TextLen = Len(Text)
    Protected I = 1, Start, C.s, C2.s, Word.s, Raw.s
    Protected LastWasOperand.b = #False  ; true logo apos numero/simbolo/$/')'

    ClearList(Toks())
    LastEvalError = ""

    While I <= TextLen
      C = Mid(Text, I, 1)

      If C = " " Or C = Chr(9)
        I + 1
        Continue
      EndIf

      If C = "("
        AddElement(Toks()) : Toks()\Kind = #Z80Tk_LParen
        I + 1 : LastWasOperand = #False
        Continue
      EndIf

      If C = ")"
        AddElement(Toks()) : Toks()\Kind = #Z80Tk_RParen
        I + 1 : LastWasOperand = #True
        Continue
      EndIf

      ; --- "$" isolado = contador de localizacao atual ---
      If C = "$" And (I = TextLen Or Not ChIsIdentCont(Mid(Text, I + 1, 1)))
        AddElement(Toks()) : Toks()\Kind = #Z80Tk_CurLoc
        I + 1 : LastWasOperand = #True
        Continue
      EndIf

      ; --- Hex prefixado com # (#1A2B) ---
      If C = "#" And I < TextLen And ChIsHexDigit(Mid(Text, I + 1, 1))
        Start = I + 1
        I + 1
        While I <= TextLen And ChIsHexDigit(Mid(Text, I, 1))
          I + 1
        Wend
        AddElement(Toks()) : Toks()\Kind = #Z80Tk_Number
        Z80Addr_Make(@Toks()\NumValue, Val("$" + Mid(Text, Start, I - Start)), #Z80Seg_Absolute)
        LastWasOperand = #True
        Continue
      EndIf

      ; --- Binario prefixado com % (%1010) ---
      If C = "%" And I < TextLen And (Mid(Text, I + 1, 1) = "0" Or Mid(Text, I + 1, 1) = "1")
        Start = I + 1
        I + 1
        While I <= TextLen And (Mid(Text, I, 1) = "0" Or Mid(Text, I, 1) = "1")
          I + 1
        Wend
        AddElement(Toks()) : Toks()\Kind = #Z80Tk_Number
        Z80Addr_Make(@Toks()\NumValue, Val("%" + Mid(Text, Start, I - Start)), #Z80Seg_Absolute)
        LastWasOperand = #True
        Continue
      EndIf

      ; --- Literal de string (1-2 caracteres viram valor numerico; ver
      ; docs/reference/nestor80-language.md - primeiro caractere = byte
      ; alto, segundo = byte baixo) ---
      If C = Chr(34) Or C = "'"
        Protected Delim.s = C
        Protected Body.s = ""
        Start = I
        I + 1
        While I <= TextLen
          C2 = Mid(Text, I, 1)
          If C2 = Delim
            If I < TextLen And Mid(Text, I + 1, 1) = Delim
              Body + Delim : I + 2 : Continue
            EndIf
            I + 1
            Break
          EndIf
          If C2 = Chr(13) Or C2 = Chr(10)
            Break
          EndIf
          Body + C2 : I + 1
        Wend
        Select Len(Body)
          Case 0
            AddElement(Toks()) : Toks()\Kind = #Z80Tk_Number
            Z80Addr_Make(@Toks()\NumValue, 0, #Z80Seg_Absolute)
          Case 1
            AddElement(Toks()) : Toks()\Kind = #Z80Tk_Number
            Z80Addr_Make(@Toks()\NumValue, Asc(Body), #Z80Seg_Absolute)
          Case 2
            AddElement(Toks()) : Toks()\Kind = #Z80Tk_Number
            Z80Addr_Make(@Toks()\NumValue, (Asc(Left(Body,1)) << 8) | Asc(Mid(Body,2,1)), #Z80Seg_Absolute)
          Default
            LastEvalError = "String com mais de 2 caracteres nao pode ser usada como valor numerico: " + Body
            ProcedureReturn #False
        EndSelect
        LastWasOperand = #True
        Continue
      EndIf

      ; --- Numeros (comecam com digito - identificador nao pode comecar com
      ; digito, entao "0FFh"/"1Ah"/"10"/"377Q"/"1010B" etc. so podem cair
      ; aqui; "FFh" sem o "0" na frente vira identificador, mesma regra
      ; classica M80) ---
      If ChIsDigit(C)
        Start = I
        ; prefixos 0x/0X (hex) e 0b/0B (binario) - so quando o token inteiro
        ; comeca exatamente por eles
        If C = "0" And I < TextLen And (UCase(Mid(Text, I + 1, 1)) = "X" Or UCase(Mid(Text, I + 1, 1)) = "B")
          Protected PrefixIsHex.b = Bool(UCase(Mid(Text, I + 1, 1)) = "X")
          Protected PStart = I + 2
          I + 2
          If PrefixIsHex
            While I <= TextLen And ChIsHexDigit(Mid(Text, I, 1))
              I + 1
            Wend
          Else
            While I <= TextLen And (Mid(Text, I, 1) = "0" Or Mid(Text, I, 1) = "1")
              I + 1
            Wend
          EndIf
          If I > PStart
            AddElement(Toks()) : Toks()\Kind = #Z80Tk_Number
            If PrefixIsHex
              Z80Addr_Make(@Toks()\NumValue, Val("$" + Mid(Text, PStart, I - PStart)), #Z80Seg_Absolute)
            Else
              Z80Addr_Make(@Toks()\NumValue, Val("%" + Mid(Text, PStart, I - PStart)), #Z80Seg_Absolute)
            EndIf
            LastWasOperand = #True
            Continue
          Else
            I = Start ; nao era prefixo de verdade (ex. "0x" sozinho, sem digitos) - recua e trata como decimal "0"
          EndIf
        EndIf

        ; token cru: maior sequencia alfanumerica a partir do digito inicial
        While I <= TextLen And (ChIsDigit(Mid(Text, I, 1)) Or ChIsAlpha(Mid(Text, I, 1)))
          I + 1
        Wend
        Raw = UCase(Mid(Text, Start, I - Start))
        C2 = Right(Raw, 1)
        Protected Digits.s, Value.u, Ok.b = #False

        If C2 = "H"
          Digits = Left(Raw, Len(Raw) - 1)
          If Digits <> "" And CountAllHex(Digits)
            Value = Val("$" + Digits) : Ok = #True
          EndIf
        ElseIf C2 = "O" Or C2 = "Q"
          Digits = Left(Raw, Len(Raw) - 1)
          If Digits <> "" And CountAllOctal(Digits)
            Value = Val("$" + Hex_FromOctalDigits(Digits)) ; ver helper abaixo
            Ok = #True
          EndIf
        ElseIf C2 = "D" Or C2 = "M"
          Digits = Left(Raw, Len(Raw) - 1)
          If Digits <> "" And CountAllDecimal(Digits)
            Value = Val(Digits) : Ok = #True
          EndIf
        ElseIf C2 = "B" Or C2 = "I"
          Digits = Left(Raw, Len(Raw) - 1)
          If Digits <> "" And CountAllBinary(Digits)
            Value = Val("%" + Digits) : Ok = #True
          EndIf
        EndIf

        If Not Ok
          ; sem sufixo reconhecido (ou sufixo nao bateu com os digitos que
          ; vieram antes) - trata o token inteiro como decimal
          If CountAllDecimal(Raw)
            Value = Val(Raw) : Ok = #True
          EndIf
        EndIf

        If Not Ok
          LastEvalError = "Numero invalido: " + Raw
          ProcedureReturn #False
        EndIf

        AddElement(Toks()) : Toks()\Kind = #Z80Tk_Number
        Z80Addr_Make(@Toks()\NumValue, Value, #Z80Seg_Absolute)
        LastWasOperand = #True
        Continue
      EndIf

      ; --- Identificadores / simbolos / operadores por extenso ---
      If ChIsIdentStart(C)
        Start = I
        I + 1
        While I <= TextLen And ChIsIdentCont(Mid(Text, I, 1))
          I + 1
        Wend
        Word = Mid(Text, Start, I - Start)

        Protected OpCode.i = WordToOpCode(Word)
        If OpCode >= 0
          AddElement(Toks()) : Toks()\Kind = #Z80Tk_Operator : Toks()\OpCode = OpCode
          LastWasOperand = #False
          Continue
        EndIf

        Protected IsExt.b = #False
        If I + 1 <= TextLen And Mid(Text, I, 2) = "##"
          IsExt = #True : I + 2
        EndIf

        AddElement(Toks()) : Toks()\Kind = #Z80Tk_Symbol
        Toks()\SymName = UCase(Word)
        Toks()\IsExternal = IsExt
        LastWasOperand = #True
        Continue
      EndIf

      ; --- Operadores simbolicos ---
      Select C
        Case "+"
          AddElement(Toks()) : Toks()\Kind = #Z80Tk_Operator
          If LastWasOperand
            Toks()\OpCode = #Z80Op_Plus
          Else
            Toks()\OpCode = #Z80Op_UnaryPlus
          EndIf
          I + 1 : LastWasOperand = #False
          Continue
        Case "-"
          AddElement(Toks()) : Toks()\Kind = #Z80Tk_Operator
          If LastWasOperand
            Toks()\OpCode = #Z80Op_Minus
          Else
            Toks()\OpCode = #Z80Op_UnaryMinus
          EndIf
          I + 1 : LastWasOperand = #False
          Continue
        Case "*"
          AddElement(Toks()) : Toks()\Kind = #Z80Tk_Operator : Toks()\OpCode = #Z80Op_Mul
          I + 1 : LastWasOperand = #False
          Continue
        Case "/"
          AddElement(Toks()) : Toks()\Kind = #Z80Tk_Operator : Toks()\OpCode = #Z80Op_Div
          I + 1 : LastWasOperand = #False
          Continue
      EndSelect

      LastEvalError = "Caractere inesperado em expressao: '" + C + "'"
      ProcedureReturn #False
    Wend

    ProcedureReturn #True
  EndProcedure

  ;- ------------------------------------------------------------
  ;- Shunting-yard: lista infixa -> lista posfixa (RPN). Unarios sao
  ;- empilhados sem checar precedencia (igual ao Nestor80: sempre resolvidos
  ;- no proximo operador binario ou ")" - ver Postfixize() em
  ;- Expression.Evaluation.cs); binarios esvaziam a pilha enquanto o topo
  ;- tiver precedencia <= a do operador que esta entrando.
  ;- ------------------------------------------------------------

  Procedure.b ToPostfixExpr(List InToks.Z80ExprTok(), List OutToks.Z80ExprTok())
    NewList OpStack.Z80ExprTok()
    ClearList(OutToks())

    ForEach InToks()
      Select InToks()\Kind
        Case #Z80Tk_Number, #Z80Tk_Symbol, #Z80Tk_CurLoc
          AddElement(OutToks())
          CopyStructure(@InToks(), @OutToks(), Z80ExprTok)

        Case #Z80Tk_LParen
          AddElement(OpStack())
          CopyStructure(@InToks(), @OpStack(), Z80ExprTok)

        Case #Z80Tk_RParen
          Protected FoundOpen.b = #False
          While ListSize(OpStack()) > 0
            LastElement(OpStack())
            If OpStack()\Kind = #Z80Tk_LParen
              FoundOpen = #True
              DeleteElement(OpStack())
              Break
            EndIf
            AddElement(OutToks())
            CopyStructure(@OpStack(), @OutToks(), Z80ExprTok)
            DeleteElement(OpStack())
          Wend
          If Not FoundOpen
            LastEvalError = "Parenteses desbalanceados: falta '('"
            ProcedureReturn #False
          EndIf

        Case #Z80Tk_Operator
          If OpIsUnary(InToks()\OpCode)
            AddElement(OpStack())
            CopyStructure(@InToks(), @OpStack(), Z80ExprTok)
          Else
            Protected NewPrec.i = OpPrecedence(InToks()\OpCode)
            While ListSize(OpStack()) > 0
              LastElement(OpStack())
              If OpStack()\Kind = #Z80Tk_LParen
                Break
              EndIf
              Protected StackPrec.i = OpPrecedence(OpStack()\OpCode)
              If StackPrec > NewPrec And Not OpIsUnary(OpStack()\OpCode)
                Break
              EndIf
              AddElement(OutToks())
              CopyStructure(@OpStack(), @OutToks(), Z80ExprTok)
              DeleteElement(OpStack())
            Wend
            AddElement(OpStack())
            CopyStructure(@InToks(), @OpStack(), Z80ExprTok)
          EndIf
      EndSelect
    Next

    While ListSize(OpStack()) > 0
      LastElement(OpStack())
      If OpStack()\Kind = #Z80Tk_LParen
        LastEvalError = "Parenteses desbalanceados: sobrou '('"
        ProcedureReturn #False
      EndIf
      AddElement(OutToks())
      CopyStructure(@OpStack(), @OutToks(), Z80ExprTok)
      DeleteElement(OpStack())
    Wend

    ProcedureReturn #True
  EndProcedure

  ;- ------------------------------------------------------------
  ;- Avaliacao da lista posfixa contra a tabela de simbolos atual. Devolve
  ;- #False se a expressao referenciar (pelo menos) um simbolo ainda
  ;- desconhecido - nesse caso NAO e erro fatal no pass 1 (ver
  ;- LastEvalUnknownSymbol); o chamador (driver de 2 passes, proxima tarefa)
  ;- decide o que fazer (reservar tamanho e enfileirar fixup).
  ;- ------------------------------------------------------------

  Procedure.b EvalPostfixExpr(List Toks.Z80ExprTok(), *Out.Z80Addr)
    NewList Stack.Z80Addr()
    Protected *A.Z80Addr, *B.Z80Addr, R.Z80Addr

    ForEach Toks()
      Select Toks()\Kind
        Case #Z80Tk_Number
          AddElement(Stack())
          CopyStructure(@Toks()\NumValue, @Stack(), Z80Addr)

        Case #Z80Tk_CurLoc
          AddElement(Stack())
          CopyStructure(@CurLoc, @Stack(), Z80Addr)

        Case #Z80Tk_Symbol
          If Not FindMapElement(Symbols(), Toks()\SymName)
            AddMapElement(Symbols(), Toks()\SymName)
            Symbols()\IsKnown = #False
          EndIf
          If Not Symbols(Toks()\SymName)\IsKnown
            LastEvalUnknownSymbol = Toks()\SymName
            ProcedureReturn #False
          EndIf
          ; Referencia cruzada (opcao R do comando A, Mamute) - todo simbolo
          ; CONHECIDO resolvido aqui durante o pass de EMISSAO conta como um
          ; "uso" no endereco da linha atual (CurLoc ainda nao avancou pra
          ; alem da linha corrente nesse ponto). So' pass 2 (PassNumber=2) -
          ; pass 1 resolveria os MESMOS usos de novo e duplicaria tudo.
          If PassNumber = 2
            AddElement(SymbolRefs())
            SymbolRefs()\SymName = Toks()\SymName
            SymbolRefs()\Addr = CurLoc\Value
          EndIf
          AddElement(Stack())
          CopyStructure(@Symbols(Toks()\SymName)\Addr, @Stack(), Z80Addr)

        Case #Z80Tk_Operator
          If OpIsUnary(Toks()\OpCode)
            If ListSize(Stack()) < 1
              LastEvalError = "Expressao mal formada (operador unario sem operando)"
              ProcedureReturn #False
            EndIf
            LastElement(Stack()) : *A = @Stack()
            Select Toks()\OpCode
              Case #Z80Op_UnaryMinus
                Z80Addr_Make(@R, (-*A\Value) & $FFFF, *A\SegType, *A\CommonName)
              Case #Z80Op_UnaryPlus
                CopyStructure(*A, @R, Z80Addr)
              Case #Z80Op_Not
                Z80Addr_Make(@R, (~*A\Value) & $FFFF, #Z80Seg_Absolute)
              Case #Z80Op_High
                Z80Addr_Make(@R, (*A\Value >> 8) & $FF, #Z80Seg_Absolute)
              Case #Z80Op_Low
                Z80Addr_Make(@R, *A\Value & $FF, #Z80Seg_Absolute)
            EndSelect
            DeleteElement(Stack())
            AddElement(Stack())
            CopyStructure(@R, @Stack(), Z80Addr)
          Else
            If ListSize(Stack()) < 2
              LastEvalError = "Expressao mal formada (operador binario sem dois operandos)"
              ProcedureReturn #False
            EndIf
            LastElement(Stack()) : *B = @Stack() : DeleteElement(Stack())
            LastElement(Stack()) : *A = @Stack() : DeleteElement(Stack())

            ; Soma/subtracao entre valores relocaveis (Fase B, ver
            ; docs/resumo-asm.md/nestor80-rel-format.md "modelo do programador"):
            ; reloc+abs/abs+reloc = reloc (mesmo segmento do operando relocavel);
            ; reloc-abs = reloc (segmento de A); reloc-reloc NO MESMO segmento =
            ; absoluto (a distancia entre dois enderecos do mesmo segmento ja e
            ; conhecida sem precisar do endereco base final, que so o linker
            ; decide); qualquer outra combinacao com pelo menos um operando
            ; relocavel (reloc+reloc, reloc-reloc de segmentos diferentes) exigiria
            ; o mecanismo de item de extensao RPN do Nestor80 - fora de escopo
            ; nesta fase (expressao relocavel composta rara), erro explicito em vez
            ; de silenciosamente virar absoluto errado. Os demais operadores
            ; (mul/div/mod/shift/bitwise/relacionais) so fazem sentido pra valores
            ; ja conhecidos em tempo de montagem - continuam exigindo os dois
            ; operandos absolutos, agora com erro explicito em vez de assumir.
            Protected AAbs.b = Bool(*A\SegType = #Z80Seg_Absolute)
            Protected BAbs.b = Bool(*B\SegType = #Z80Seg_Absolute)
            Select Toks()\OpCode
              Case #Z80Op_Plus
                If AAbs And BAbs
                  Z80Addr_Make(@R, (*A\Value + *B\Value) & $FFFF, #Z80Seg_Absolute)
                ElseIf AAbs And Not BAbs
                  Z80Addr_Make(@R, (*A\Value + *B\Value) & $FFFF, *B\SegType, *B\CommonName)
                ElseIf Not AAbs And BAbs
                  Z80Addr_Make(@R, (*A\Value + *B\Value) & $FFFF, *A\SegType, *A\CommonName)
                Else
                  LastEvalError = "Soma entre dois valores relocaveis nao suportada nesta fase (Fase B parcial - precisaria de item de extensao RPN)"
                  ProcedureReturn #False
                EndIf
              Case #Z80Op_Minus
                If AAbs And BAbs
                  Z80Addr_Make(@R, (*A\Value - *B\Value) & $FFFF, #Z80Seg_Absolute)
                ElseIf Not AAbs And BAbs
                  Z80Addr_Make(@R, (*A\Value - *B\Value) & $FFFF, *A\SegType, *A\CommonName)
                ElseIf Not AAbs And Not BAbs And Z80Addr_SameSegment(*A, *B)
                  Z80Addr_Make(@R, (*A\Value - *B\Value) & $FFFF, #Z80Seg_Absolute)
                Else
                  LastEvalError = "Subtracao envolvendo valor relocavel nao suportada nesta fase (absoluto-relocavel, ou relocaveis de segmentos diferentes - precisaria de item de extensao RPN)"
                  ProcedureReturn #False
                EndIf
              Case #Z80Op_Mul
                If Not (AAbs And BAbs) : LastEvalError = "*: operandos precisam ser absolutos" : ProcedureReturn #False : EndIf
                Z80Addr_Make(@R, (*A\Value * *B\Value) & $FFFF, #Z80Seg_Absolute)
              Case #Z80Op_Div
                If Not (AAbs And BAbs) : LastEvalError = "/: operandos precisam ser absolutos" : ProcedureReturn #False : EndIf
                If *B\Value = 0
                  LastEvalError = "Divisao por zero"
                  ProcedureReturn #False
                EndIf
                Z80Addr_Make(@R, (*A\Value / *B\Value) & $FFFF, #Z80Seg_Absolute)
              Case #Z80Op_Mod
                If Not (AAbs And BAbs) : LastEvalError = "MOD: operandos precisam ser absolutos" : ProcedureReturn #False : EndIf
                If *B\Value = 0
                  LastEvalError = "Divisao por zero (MOD)"
                  ProcedureReturn #False
                EndIf
                Z80Addr_Make(@R, (*A\Value % *B\Value) & $FFFF, #Z80Seg_Absolute)
              Case #Z80Op_Shl
                If Not (AAbs And BAbs) : LastEvalError = "SHL: operandos precisam ser absolutos" : ProcedureReturn #False : EndIf
                Z80Addr_Make(@R, (*A\Value << *B\Value) & $FFFF, #Z80Seg_Absolute)
              Case #Z80Op_Shr
                If Not (AAbs And BAbs) : LastEvalError = "SHR: operandos precisam ser absolutos" : ProcedureReturn #False : EndIf
                Z80Addr_Make(@R, (*A\Value >> *B\Value) & $FFFF, #Z80Seg_Absolute)
              Case #Z80Op_And
                If Not (AAbs And BAbs) : LastEvalError = "AND: operandos precisam ser absolutos" : ProcedureReturn #False : EndIf
                Z80Addr_Make(@R, (*A\Value & *B\Value) & $FFFF, #Z80Seg_Absolute)
              Case #Z80Op_Or
                If Not (AAbs And BAbs) : LastEvalError = "OR: operandos precisam ser absolutos" : ProcedureReturn #False : EndIf
                Z80Addr_Make(@R, (*A\Value | *B\Value) & $FFFF, #Z80Seg_Absolute)
              Case #Z80Op_Xor
                If Not (AAbs And BAbs) : LastEvalError = "XOR: operandos precisam ser absolutos" : ProcedureReturn #False : EndIf
                Z80Addr_Make(@R, (*A\Value ! *B\Value) & $FFFF, #Z80Seg_Absolute)
              ; Relacionais: convencao M80/Nestor80 - verdadeiro = FFFFh, falso = 0000h
              Case #Z80Op_Eq
                If Not (AAbs And BAbs) : LastEvalError = "EQ: operandos precisam ser absolutos" : ProcedureReturn #False : EndIf
                Z80Addr_Make(@R, Bool(*A\Value = *B\Value) * $FFFF, #Z80Seg_Absolute)
              Case #Z80Op_Ne
                If Not (AAbs And BAbs) : LastEvalError = "NE: operandos precisam ser absolutos" : ProcedureReturn #False : EndIf
                Z80Addr_Make(@R, Bool(*A\Value <> *B\Value) * $FFFF, #Z80Seg_Absolute)
              Case #Z80Op_Lt
                If Not (AAbs And BAbs) : LastEvalError = "LT: operandos precisam ser absolutos" : ProcedureReturn #False : EndIf
                Z80Addr_Make(@R, Bool(*A\Value < *B\Value) * $FFFF, #Z80Seg_Absolute)
              Case #Z80Op_Le
                If Not (AAbs And BAbs) : LastEvalError = "LE: operandos precisam ser absolutos" : ProcedureReturn #False : EndIf
                Z80Addr_Make(@R, Bool(*A\Value <= *B\Value) * $FFFF, #Z80Seg_Absolute)
              Case #Z80Op_Gt
                If Not (AAbs And BAbs) : LastEvalError = "GT: operandos precisam ser absolutos" : ProcedureReturn #False : EndIf
                Z80Addr_Make(@R, Bool(*A\Value > *B\Value) * $FFFF, #Z80Seg_Absolute)
              Case #Z80Op_Ge
                If Not (AAbs And BAbs) : LastEvalError = "GE: operandos precisam ser absolutos" : ProcedureReturn #False : EndIf
                Z80Addr_Make(@R, Bool(*A\Value >= *B\Value) * $FFFF, #Z80Seg_Absolute)
            EndSelect
            AddElement(Stack())
            CopyStructure(@R, @Stack(), Z80Addr)
          EndIf
      EndSelect
    Next

    If ListSize(Stack()) <> 1
      LastEvalError = "Expressao mal formada (sobrou mais de um valor na pilha)"
      ProcedureReturn #False
    EndIf

    LastElement(Stack())
    CopyStructure(@Stack(), *Out, Z80Addr)
    ProcedureReturn #True
  EndProcedure

  ;- ------------------------------------------------------------
  ;- API publica
  ;- ------------------------------------------------------------

  Procedure ResetState()
    ClearMap(Symbols())
    Z80Addr_Make(@CurLoc, 0, #Z80Seg_Absolute)
    PassNumber = 1
    LastEvalError = ""
    LastEvalUnknownSymbol = ""
  EndProcedure

  Procedure SetCurrentLocation(Value.u)
    CurLoc\Value = Value
  EndProcedure

  ; Versao geral (segmento arbitrario) - DefineSymbol() abaixo e so um atalho
  ; pra #Z80Seg_Absolute (mantido intacto pra nao mudar o contrato da API
  ; publica de Fase A). Usada pelo driver relocavel (RunOnePassRel, Fase B)
  ; pra rotulos definidos dentro de CSEG/DSEG/COMMON.
  Procedure.i DefineSymbolSeg(Name.s, Value.u, SegType.b, CommonName.s, IsConstant.b = #False)
    Protected Key.s = UCase(Name)
    If FindMapElement(Symbols(), Key) And Symbols()\IsKnown And Symbols()\IsConstant
      If Symbols()\Addr\Value = Value And Symbols()\Addr\SegType = SegType And Symbols()\Addr\CommonName = CommonName
        ProcedureReturn #True ; redefinicao idempotente (mesma linha EQU vista de novo no pass 2) - ok
      EndIf
      LastEvalError = "Simbolo ja definido (EQU nao pode ser redefinido): " + Key
      ProcedureReturn #False
    EndIf
    ; Precisa saber se o simbolo JA estava #True em IsKnown ANTES desta
    ; chamada - uma referencia direta (EvalPostfixExpr, Case #Z80Tk_Symbol)
    ; pode ja ter criado a chave do Map como placeholder (IsKnown=#False)
    ; numa referencia PRA FRENTE (rotulo usado antes de ser definido no
    ; fonte) - "Not FindMapElement()" sozinho nao bastaria pra detectar
    ; "esta e' a definicao de verdade" nesse caso (ver uso logo abaixo, opcao
    ; D do comando A - ordem de DEFINICAO, nao de 1a mencao).
    Protected WasKnownBefore.b = Bool(FindMapElement(Symbols(), Key) And Symbols()\IsKnown)
    If Not FindMapElement(Symbols(), Key)
      AddMapElement(Symbols(), Key)
    EndIf
    Z80Addr_Make(@Symbols()\Addr, Value, SegType, CommonName)
    Symbols()\IsKnown = #True
    Symbols()\IsConstant = IsConstant
    ; Referencia cruzada em ORDEM DE APARICAO (opcao D do comando A, Mamute)
    ; - grava so' na transicao "ainda nao conhecido -> conhecido", que so'
    ; acontece UMA vez por simbolo, na linha-fonte que realmente o define -
    ; como o pass 1 varre o fonte de cima pra baixo, essa ordem JA e' a
    ; ordem de aparicao, sem precisar de PassNumber nem indice de linha.
    If Not WasKnownBefore
      AddElement(SymbolDefOrder())
      SymbolDefOrder() = Key
    EndIf
    ProcedureReturn #True
  EndProcedure

  Procedure.i DefineSymbol(Name.s, Value.u, IsConstant.b = #False)
    ProcedureReturn DefineSymbolSeg(Name, Value, #Z80Seg_Absolute, "", IsConstant)
  EndProcedure

  Procedure.i IsSymbolKnown(Name.s)
    Protected Key.s = UCase(Name)
    If FindMapElement(Symbols(), Key)
      ProcedureReturn Symbols()\IsKnown
    EndIf
    ProcedureReturn #False
  EndProcedure

  Procedure.u GetSymbolValue(Name.s)
    Protected Key.s = UCase(Name)
    If FindMapElement(Symbols(), Key)
      ProcedureReturn Symbols()\Addr\Value
    EndIf
    ProcedureReturn 0
  EndProcedure

  Procedure.i EvalExpr(Text.s, *Out.Z80Addr)
    NewList Infix.Z80ExprTok()
    NewList Postfix.Z80ExprTok()

    LastEvalError = ""
    LastEvalUnknownSymbol = ""

    If Not TokenizeExpr(Text, Infix())
      ProcedureReturn #False
    EndIf
    If ListSize(Infix()) = 0
      LastEvalError = "Expressao vazia"
      ProcedureReturn #False
    EndIf
    If Not ToPostfixExpr(Infix(), Postfix())
      ProcedureReturn #False
    EndIf
    ProcedureReturn EvalPostfixExpr(Postfix(), *Out)
  EndProcedure

  Procedure.s GetLastEvalError()
    ProcedureReturn LastEvalError
  EndProcedure

  Procedure.s GetLastEvalUnknownSymbol()
    ProcedureReturn LastEvalUnknownSymbol
  EndProcedure

  ;- ------------------------------------------------------------
  ;- Codificador de instrucoes Z80 (tabela de opcodes) - ver
  ;- docs/reference/nestor80-language.md, secao "Gramatica de modos de
  ;- enderecamento". Classificacao de operando primeiro (ClassifyOperand),
  ;- depois um dispatcher por familia de mnemonico. O tamanho de qualquer
  ;- instrucao Z80 e 100% determinado pela FORMA do(s) operando(s), nunca
  ;- pelo valor - por isso o pass 1 (EmitMode=#False) nunca chama EvalExpr
  ;- de verdade (EvalOperandExpr/EvalDisplacement so simulam um valor 0),
  ;- so classifica formato.
  ;- ------------------------------------------------------------

  Global LastAsmError.s

  Procedure.s GetLastAsmError()
    ProcedureReturn LastAsmError
  EndProcedure

  Enumeration Z80OperandKind
    #Z80Opnd_None
    #Z80Opnd_Reg8
    #Z80Opnd_Reg16
    #Z80Opnd_RegAF
    #Z80Opnd_IX
    #Z80Opnd_IY
    #Z80Opnd_IXHalf   ; IXH(RegCode=4)/IXL(RegCode=5)
    #Z80Opnd_IYHalf   ; IYH(RegCode=4)/IYL(RegCode=5)
    #Z80Opnd_IndHL
    #Z80Opnd_IndBC
    #Z80Opnd_IndDE
    #Z80Opnd_IndSP
    #Z80Opnd_IndC
    #Z80Opnd_IndIX    ; "(IX)" (Expr="") ou "(IX+d)"/"(IX-d)" (Expr=deslocamento)
    #Z80Opnd_IndIY
    #Z80Opnd_Cond     ; NZ Z NC C PO PE P M
    #Z80Opnd_Imm      ; expressao "solta"
    #Z80Opnd_IndImm   ; "(expressao)" generico, ex. (nn)
  EndEnumeration

  Structure Z80Operand
    Kind.b
    RegCode.b   ; Reg8: B=0 C=1 D=2 E=3 H=4 L=5 A=7 | Reg16/qq/IXHalf/IYHalf: ver comentarios acima | Cond: NZ=0 Z=1 NC=2 C=3 PO=4 PE=5 P=6 M=7
    Expr.s      ; Imm/IndImm: a expressao inteira; IndIX/IndIY: so o deslocamento (pode ser "")
    Present.b
  EndStructure

  ; Espaco/tab nas pontas ja removido por quem monta ArgsText (ParseLine) -
  ; SkipWs/RTrimWs aqui e defesa extra (operando isolado apos split por
  ; virgula pode sobrar com espaco em volta, ex. "LD A, B").
  Procedure ClassifyOperand(Text.s, *Out.Z80Operand)
    Protected T.s = RTrimWs(Mid(Text, SkipWs(Text, 1)))
    Protected U.s = UCase(T)

    *Out\Kind = #Z80Opnd_Imm
    *Out\RegCode = 0
    *Out\Expr = T
    *Out\Present = Bool(T <> "")

    If T = ""
      *Out\Kind = #Z80Opnd_None
      ProcedureReturn
    EndIf

    Select U
      Case "B"  : *Out\Kind = #Z80Opnd_Reg8 : *Out\RegCode = 0 : ProcedureReturn
      Case "C"  : *Out\Kind = #Z80Opnd_Reg8 : *Out\RegCode = 1 : ProcedureReturn
      Case "D"  : *Out\Kind = #Z80Opnd_Reg8 : *Out\RegCode = 2 : ProcedureReturn
      Case "E"  : *Out\Kind = #Z80Opnd_Reg8 : *Out\RegCode = 3 : ProcedureReturn
      Case "H"  : *Out\Kind = #Z80Opnd_Reg8 : *Out\RegCode = 4 : ProcedureReturn
      Case "L"  : *Out\Kind = #Z80Opnd_Reg8 : *Out\RegCode = 5 : ProcedureReturn
      Case "A"  : *Out\Kind = #Z80Opnd_Reg8 : *Out\RegCode = 7 : ProcedureReturn
      Case "BC" : *Out\Kind = #Z80Opnd_Reg16 : *Out\RegCode = 0 : ProcedureReturn
      Case "DE" : *Out\Kind = #Z80Opnd_Reg16 : *Out\RegCode = 1 : ProcedureReturn
      Case "HL" : *Out\Kind = #Z80Opnd_Reg16 : *Out\RegCode = 2 : ProcedureReturn
      Case "SP" : *Out\Kind = #Z80Opnd_Reg16 : *Out\RegCode = 3 : ProcedureReturn
      Case "AF" : *Out\Kind = #Z80Opnd_RegAF : *Out\RegCode = 3 : ProcedureReturn
      Case "IX" : *Out\Kind = #Z80Opnd_IX : ProcedureReturn
      Case "IY" : *Out\Kind = #Z80Opnd_IY : ProcedureReturn
      Case "IXH": *Out\Kind = #Z80Opnd_IXHalf : *Out\RegCode = 4 : ProcedureReturn
      Case "IXL": *Out\Kind = #Z80Opnd_IXHalf : *Out\RegCode = 5 : ProcedureReturn
      Case "IYH": *Out\Kind = #Z80Opnd_IYHalf : *Out\RegCode = 4 : ProcedureReturn
      Case "IYL": *Out\Kind = #Z80Opnd_IYHalf : *Out\RegCode = 5 : ProcedureReturn
      Case "(HL)" : *Out\Kind = #Z80Opnd_IndHL : ProcedureReturn
      Case "(BC)" : *Out\Kind = #Z80Opnd_IndBC : ProcedureReturn
      Case "(DE)" : *Out\Kind = #Z80Opnd_IndDE : ProcedureReturn
      Case "(SP)" : *Out\Kind = #Z80Opnd_IndSP : ProcedureReturn
      Case "(C)"  : *Out\Kind = #Z80Opnd_IndC : ProcedureReturn
      Case "(IX)" : *Out\Kind = #Z80Opnd_IndIX : *Out\Expr = "" : ProcedureReturn
      Case "(IY)" : *Out\Kind = #Z80Opnd_IndIY : *Out\Expr = "" : ProcedureReturn
      Case "NZ" : *Out\Kind = #Z80Opnd_Cond : *Out\RegCode = 0 : ProcedureReturn
      Case "Z"  : *Out\Kind = #Z80Opnd_Cond : *Out\RegCode = 1 : ProcedureReturn
      Case "NC" : *Out\Kind = #Z80Opnd_Cond : *Out\RegCode = 2 : ProcedureReturn
      Case "PO" : *Out\Kind = #Z80Opnd_Cond : *Out\RegCode = 4 : ProcedureReturn
      Case "PE" : *Out\Kind = #Z80Opnd_Cond : *Out\RegCode = 5 : ProcedureReturn
      Case "P"  : *Out\Kind = #Z80Opnd_Cond : *Out\RegCode = 6 : ProcedureReturn
      Case "M"  : *Out\Kind = #Z80Opnd_Cond : *Out\RegCode = 7 : ProcedureReturn
    EndSelect
    ; nota: "C" sozinho fica classificado Reg8 acima (mais comum) - JP/JR/
    ; CALL/RET tratam "C" como condicao explicitamente quando a posicao do
    ; operando pede uma condicao (ver EncodeJp/EncodeJr/EncodeCallRet: elas
    ; conferem Op1\Kind = #Z80Opnd_Cond OU, pro caso especial de "C" sozinho
    ; na posicao de condicao, ainda cai como Reg8 com RegCode=1 - tratado a
    ; parte on ambiguidade importa).

    ; (IX+d)/(IX-d)/(IY+d)/(IY-d) - o operando INTEIRO precisa ser exatamente
    ; essa forma (parenteses de abertura E fechamento cobrindo tudo) - e uma
    ; forma de enderecamento de hardware distinta, nao uma expressao comum.
    If Len(T) >= 2 And Left(T, 1) = "(" And Right(T, 1) = ")"
      Protected Inner.s = Mid(T, 2, Len(T) - 2)
      Protected InnerU.s = UCase(Inner)
      If Left(InnerU, 2) = "IX" And Len(Inner) > 2 And (Mid(InnerU, 3, 1) = "+" Or Mid(InnerU, 3, 1) = "-")
        *Out\Kind = #Z80Opnd_IndIX
        *Out\Expr = Mid(Inner, 3)
        ProcedureReturn
      ElseIf Left(InnerU, 2) = "IY" And Len(Inner) > 2 And (Mid(InnerU, 3, 1) = "+" Or Mid(InnerU, 3, 1) = "-")
        *Out\Kind = #Z80Opnd_IndIY
        *Out\Expr = Mid(Inner, 3)
        ProcedureReturn
      EndIf
    EndIf

    ; "(expressao)" generico = IndImm - QUALQUER operando que comece com "("
    ; e tratado como forma de memoria (nn) pelo M80/Nestor80, MESMO quando
    ; sobra texto depois do ")" que fecha esse primeiro parenteses (ex.
    ; "(FOO SHL 4) OR BAR" - confirmado contra o oraculo N80.exe: produz
    ; LD A,(nn) com nn = FOO SHL 4 OR BAR avaliado inteiro, nao LD A,n).
    ; Por isso NAO tira os parenteses aqui - Expr recebe o texto ORIGINAL
    ; inteiro (parenteses inclusos), e quem resolve o agrupamento e o
    ; proprio avaliador de expressao (que ja trata "("/")" como parenteses
    ; normais de precedencia).
    If Left(T, 1) = "("
      *Out\Kind = #Z80Opnd_IndImm
      *Out\Expr = T
      ProcedureReturn
    EndIf

    ; sobra o caso geral: expressao solta (Imm), ja preenchido no default acima
  EndProcedure

  ; Conta operandos (0/1/2) separados por virgula fora de aspas/parenteses.
  Procedure.i CountOperands(ArgsText.s)
    Protected L = Len(ArgsText), I = 1, C.s, Depth = 0, N
    If RTrimWs(Mid(ArgsText, SkipWs(ArgsText, 1))) = ""
      ProcedureReturn 0
    EndIf
    N = 1
    While I <= L
      C = Mid(ArgsText, I, 1)
      If C = Chr(34) Or C = "'"
        Protected Delim.s = C
        I + 1
        While I <= L And Mid(ArgsText, I, 1) <> Delim
          I + 1
        Wend
      ElseIf C = "("
        Depth + 1
      ElseIf C = ")"
        Depth - 1
      ElseIf C = "," And Depth = 0
        N + 1
      EndIf
      I + 1
    Wend
    ProcedureReturn N
  EndProcedure

  ; Devolve o texto cru do operando Index (1 ou 2), sem aparar espaco nas
  ; pontas (ClassifyOperand ja faz isso).
  Procedure.s GetOperand(ArgsText.s, Index.i)
    Protected L = Len(ArgsText), I = 1, C.s, Depth = 0, N = 1, Start = 1
    While I <= L
      C = Mid(ArgsText, I, 1)
      If C = Chr(34) Or C = "'"
        Protected Delim.s = C
        I + 1
        While I <= L And Mid(ArgsText, I, 1) <> Delim
          I + 1
        Wend
      ElseIf C = "("
        Depth + 1
      ElseIf C = ")"
        Depth - 1
      ElseIf C = "," And Depth = 0
        If N = Index
          ProcedureReturn Mid(ArgsText, Start, I - Start)
        EndIf
        N + 1
        Start = I + 1
      EndIf
      I + 1
    Wend
    If N = Index
      ProcedureReturn Mid(ArgsText, Start)
    EndIf
    ProcedureReturn ""
  EndProcedure

  ; So avalia de verdade quando EmitMode (pass 2) - no pass 1 devolve #True
  ; com valor 0 sem tocar no avaliador/tabela de simbolos (tamanho de
  ; instrucao Z80 nunca depende do VALOR de uma expressao, so da forma).
  Procedure.b EvalOperandExpr(Expr.s, EmitMode.b, *OutVal.Z80Addr)
    If Not EmitMode
      Z80Addr_Make(*OutVal, 0, #Z80Seg_Absolute)
      ProcedureReturn #True
    EndIf
    If Not EvalExpr(Expr, *OutVal)
      ; propaga o motivo pra LastAsmError - sem isso, todo Encode* que so faz
      ; "If Not EvalOperandExpr(...) : ProcedureReturn -1 : EndIf" devolveria
      ; erro sem mensagem nenhuma (achado real depurando sample/teste.asm).
      LastAsmError = "Expressao invalida (" + Expr + "): " + LastEvalError + LastEvalUnknownSymbol
      ProcedureReturn #False
    EndIf
    ProcedureReturn #True
  EndProcedure

  ; Idem, mas pra deslocamento de (IX+d)/(IY+d) - trata Expr="" (forma "(IX)"
  ; pura, sem deslocamento) como zero, sem chamar o avaliador.
  Procedure.b EvalDisplacement(Expr.s, EmitMode.b, *OutVal.Z80Addr)
    If Expr = ""
      Z80Addr_Make(*OutVal, 0, #Z80Seg_Absolute)
      ProcedureReturn #True
    EndIf
    ProcedureReturn EvalOperandExpr(Expr, EmitMode, *OutVal)
  EndProcedure

  ;- Familias de instrucao - cada uma devolve o numero de bytes (0-4) ou -1
  ;- (erro, ver LastAsmError). Precisam vir ANTES de EncodeInstruction() no
  ;- arquivo (PureBasic, dentro de um Module, nao resolve chamada a uma
  ;- Procedure ainda nao definida textualmente - mesma regra ja documentada
  ;- pro tokenizador de expressao).

  Procedure.i EncodeRst(*Op1.Z80Operand, EmitMode.b, Array Out.a(1))
    Protected V.Z80Addr
    If Not *Op1\Present
      LastAsmError = "RST precisa de um operando (0,8,16,24,32,40,48,56)"
      ProcedureReturn -1
    EndIf
    If Not EvalOperandExpr(*Op1\Expr, EmitMode, @V)
      ProcedureReturn -1
    EndIf
    Out(0) = $C7
    If EmitMode
      If (V\Value & 7) <> 0 Or V\Value > 56
        LastAsmError = "RST: valor invalido (precisa ser 0,8,16,24,32,40,48 ou 56): " + Str(V\Value)
        ProcedureReturn -1
      EndIf
      Out(0) = $C7 | ((V\Value / 8) << 3)
    EndIf
    ProcedureReturn 1
  EndProcedure

  Procedure.i EncodeIm(*Op1.Z80Operand, EmitMode.b, Array Out.a(1))
    Protected V.Z80Addr
    If Not *Op1\Present
      LastAsmError = "IM precisa de um operando (0, 1 ou 2)"
      ProcedureReturn -1
    EndIf
    If Not EvalOperandExpr(*Op1\Expr, EmitMode, @V)
      ProcedureReturn -1
    EndIf
    Out(0) = $ED
    If EmitMode
      Select V\Value
        Case 0 : Out(1) = $46
        Case 1 : Out(1) = $56
        Case 2 : Out(1) = $5E
        Default
          LastAsmError = "IM: valor invalido (precisa ser 0, 1 ou 2)"
          ProcedureReturn -1
      EndSelect
    EndIf
    ProcedureReturn 2
  EndProcedure

  Procedure.i EncodeEx(*Op1.Z80Operand, *Op2.Z80Operand, EmitMode.b, Array Out.a(1))
    If *Op1\Kind = #Z80Opnd_Reg16 And *Op1\RegCode = 1 And *Op2\Kind = #Z80Opnd_Reg16 And *Op2\RegCode = 2
      Out(0) = $EB
      ProcedureReturn 1
    EndIf
    If *Op1\Kind = #Z80Opnd_RegAF And UCase(*Op2\Expr) = "AF'"
      Out(0) = $08
      ProcedureReturn 1
    EndIf
    If *Op1\Kind = #Z80Opnd_IndSP
      If *Op2\Kind = #Z80Opnd_Reg16 And *Op2\RegCode = 2
        Out(0) = $E3
        ProcedureReturn 1
      ElseIf *Op2\Kind = #Z80Opnd_IX
        Out(0) = $DD : Out(1) = $E3
        ProcedureReturn 2
      ElseIf *Op2\Kind = #Z80Opnd_IY
        Out(0) = $FD : Out(1) = $E3
        ProcedureReturn 2
      EndIf
    EndIf
    LastAsmError = "EX: combinacao de operandos invalida"
    ProcedureReturn -1
  EndProcedure

  Procedure.i EncodeIn(*Op1.Z80Operand, *Op2.Z80Operand, NOps.i, EmitMode.b, Array Out.a(1))
    Protected V.Z80Addr
    If NOps <> 2
      LastAsmError = "IN precisa de 2 operandos"
      ProcedureReturn -1
    EndIf
    If *Op1\Kind = #Z80Opnd_Reg8 And *Op1\RegCode = 7 And *Op2\Kind = #Z80Opnd_IndImm
      If Not EvalOperandExpr(*Op2\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      Out(0) = $DB
      If EmitMode : Out(1) = V\Value & $FF : EndIf
      ProcedureReturn 2
    EndIf
    If *Op1\Kind = #Z80Opnd_Reg8 And *Op2\Kind = #Z80Opnd_IndC
      Out(0) = $ED
      Out(1) = $40 | (*Op1\RegCode << 3)
      ProcedureReturn 2
    EndIf
    LastAsmError = "IN: combinacao de operandos invalida"
    ProcedureReturn -1
  EndProcedure

  Procedure.i EncodeOut(*Op1.Z80Operand, *Op2.Z80Operand, EmitMode.b, Array Out.a(1))
    Protected V.Z80Addr
    If *Op1\Kind = #Z80Opnd_IndImm And *Op2\Kind = #Z80Opnd_Reg8 And *Op2\RegCode = 7
      If Not EvalOperandExpr(*Op1\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      Out(0) = $D3
      If EmitMode : Out(1) = V\Value & $FF : EndIf
      ProcedureReturn 2
    EndIf
    If *Op1\Kind = #Z80Opnd_IndC And *Op2\Kind = #Z80Opnd_Reg8
      Out(0) = $ED
      Out(1) = $41 | (*Op2\RegCode << 3)
      ProcedureReturn 2
    EndIf
    LastAsmError = "OUT: combinacao de operandos invalida"
    ProcedureReturn -1
  EndProcedure

  Procedure.i EncodePushPop(Base.a, *Op1.Z80Operand, EmitMode.b, Array Out.a(1))
    Select *Op1\Kind
      Case #Z80Opnd_Reg16
        If *Op1\RegCode = 3
          LastAsmError = "PUSH/POP: SP nao existe aqui (o slot 11 e AF, nao SP - quis dizer AF?)"
          ProcedureReturn -1
        EndIf
        Out(0) = Base | (*Op1\RegCode << 4)
        ProcedureReturn 1
      Case #Z80Opnd_RegAF
        Out(0) = Base | (3 << 4)
        ProcedureReturn 1
      Case #Z80Opnd_IX
        Out(0) = $DD : Out(1) = Base | (2 << 4)
        ProcedureReturn 2
      Case #Z80Opnd_IY
        Out(0) = $FD : Out(1) = Base | (2 << 4)
        ProcedureReturn 2
    EndSelect
    LastAsmError = "PUSH/POP: operando invalido (precisa ser BC, DE, HL, AF, IX ou IY)"
    ProcedureReturn -1
  EndProcedure

  Procedure.i EncodeIncDec(IsInc.b, *Op1.Z80Operand, EmitMode.b, Array Out.a(1))
    Protected V.Z80Addr
    Protected Op8.a, Op16.a, OpIxIy.a, OpInd.a, OpHalfH.a, OpHalfL.a
    If IsInc
      Op8 = $04 : Op16 = $03 : OpIxIy = $23 : OpInd = $34 : OpHalfH = $24 : OpHalfL = $2C
    Else
      Op8 = $05 : Op16 = $0B : OpIxIy = $2B : OpInd = $35 : OpHalfH = $25 : OpHalfL = $2D
    EndIf

    Select *Op1\Kind
      Case #Z80Opnd_Reg8
        Out(0) = Op8 | (*Op1\RegCode << 3)
        ProcedureReturn 1
      Case #Z80Opnd_IndHL
        Out(0) = Op8 | (6 << 3)
        ProcedureReturn 1
      Case #Z80Opnd_Reg16
        Out(0) = Op16 | (*Op1\RegCode << 4)
        ProcedureReturn 1
      Case #Z80Opnd_IX
        Out(0) = $DD : Out(1) = OpIxIy
        ProcedureReturn 2
      Case #Z80Opnd_IY
        Out(0) = $FD : Out(1) = OpIxIy
        ProcedureReturn 2
      Case #Z80Opnd_IXHalf
        Out(0) = $DD
        If *Op1\RegCode = 4 : Out(1) = OpHalfH : Else : Out(1) = OpHalfL : EndIf
        ProcedureReturn 2
      Case #Z80Opnd_IYHalf
        Out(0) = $FD
        If *Op1\RegCode = 4 : Out(1) = OpHalfH : Else : Out(1) = OpHalfL : EndIf
        ProcedureReturn 2
      Case #Z80Opnd_IndIX
        Out(0) = $DD : Out(1) = OpInd
        If Not EvalDisplacement(*Op1\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
        If EmitMode : Out(2) = V\Value & $FF : EndIf
        ProcedureReturn 3
      Case #Z80Opnd_IndIY
        Out(0) = $FD : Out(1) = OpInd
        If Not EvalDisplacement(*Op1\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
        If EmitMode : Out(2) = V\Value & $FF : EndIf
        ProcedureReturn 3
    EndSelect
    LastAsmError = "INC/DEC: operando invalido"
    ProcedureReturn -1
  EndProcedure

  Procedure.i EncodeAluSingle(Idx.a, *Op1.Z80Operand, *Op2.Z80Operand, NOps.i, EmitMode.b, Array Out.a(1))
    Protected V.Z80Addr
    Protected TheOp.Z80Operand
    If NOps = 2
      If *Op1\Kind <> #Z80Opnd_Reg8 Or *Op1\RegCode <> 7
        LastAsmError = "So A pode ser o primeiro operando quando dois sao dados"
        ProcedureReturn -1
      EndIf
      CopyStructure(*Op2, @TheOp, Z80Operand)
    ElseIf NOps = 1
      CopyStructure(*Op1, @TheOp, Z80Operand)
    Else
      LastAsmError = "Precisa de 1 operando (ou 2, com A como o primeiro)"
      ProcedureReturn -1
    EndIf

    Select TheOp\Kind
      Case #Z80Opnd_Reg8
        Out(0) = $80 | (Idx << 3) | TheOp\RegCode
        ProcedureReturn 1
      Case #Z80Opnd_IndHL
        Out(0) = $80 | (Idx << 3) | 6
        ProcedureReturn 1
      Case #Z80Opnd_IXHalf
        Out(0) = $DD : Out(1) = $80 | (Idx << 3) | TheOp\RegCode
        ProcedureReturn 2
      Case #Z80Opnd_IYHalf
        Out(0) = $FD : Out(1) = $80 | (Idx << 3) | TheOp\RegCode
        ProcedureReturn 2
      Case #Z80Opnd_IndIX
        Out(0) = $DD : Out(1) = $86 | (Idx << 3)
        If Not EvalDisplacement(TheOp\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
        If EmitMode : Out(2) = V\Value & $FF : EndIf
        ProcedureReturn 3
      Case #Z80Opnd_IndIY
        Out(0) = $FD : Out(1) = $86 | (Idx << 3)
        If Not EvalDisplacement(TheOp\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
        If EmitMode : Out(2) = V\Value & $FF : EndIf
        ProcedureReturn 3
      Case #Z80Opnd_IndImm
        LastAsmError = "So (HL), (IX+d) ou (IY+d) sao validos aqui, nao (nn)"
        ProcedureReturn -1
      Case #Z80Opnd_Imm
        If Not EvalOperandExpr(TheOp\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
        Out(0) = $C6 | (Idx << 3)
        If EmitMode : Out(1) = V\Value & $FF : EndIf
        ProcedureReturn 2
    EndSelect
    LastAsmError = "Operando invalido"
    ProcedureReturn -1
  EndProcedure

  Procedure.i EncodeAdd(*Op1.Z80Operand, *Op2.Z80Operand, NOps.i, EmitMode.b, Array Out.a(1))
    If NOps <> 2
      LastAsmError = "ADD precisa de 2 operandos"
      ProcedureReturn -1
    EndIf

    If *Op1\Kind = #Z80Opnd_Reg8 And *Op1\RegCode = 7
      ProcedureReturn EncodeAluSingle(0, *Op1, *Op2, 2, EmitMode, Out())
    EndIf

    If *Op1\Kind = #Z80Opnd_Reg16 And *Op1\RegCode = 2
      If *Op2\Kind = #Z80Opnd_Reg16
        Out(0) = $09 | (*Op2\RegCode << 4)
        ProcedureReturn 1
      EndIf
      LastAsmError = "ADD HL,?: segundo operando precisa ser BC, DE, HL ou SP"
      ProcedureReturn -1
    EndIf

    If *Op1\Kind = #Z80Opnd_IX
      Out(0) = $DD
      If *Op2\Kind = #Z80Opnd_Reg16 And *Op2\RegCode <> 2
        Out(1) = $09 | (*Op2\RegCode << 4)
        ProcedureReturn 2
      ElseIf *Op2\Kind = #Z80Opnd_IX
        Out(1) = $09 | (2 << 4)
        ProcedureReturn 2
      EndIf
      LastAsmError = "ADD IX,?: segundo operando precisa ser BC, DE, IX ou SP"
      ProcedureReturn -1
    EndIf

    If *Op1\Kind = #Z80Opnd_IY
      Out(0) = $FD
      If *Op2\Kind = #Z80Opnd_Reg16 And *Op2\RegCode <> 2
        Out(1) = $09 | (*Op2\RegCode << 4)
        ProcedureReturn 2
      ElseIf *Op2\Kind = #Z80Opnd_IY
        Out(1) = $09 | (2 << 4)
        ProcedureReturn 2
      EndIf
      LastAsmError = "ADD IY,?: segundo operando precisa ser BC, DE, IY ou SP"
      ProcedureReturn -1
    EndIf

    LastAsmError = "ADD: combinacao de operandos invalida"
    ProcedureReturn -1
  EndProcedure

  Procedure.i EncodeAdcSbc(IsAdc.b, *Op1.Z80Operand, *Op2.Z80Operand, NOps.i, EmitMode.b, Array Out.a(1))
    If NOps <> 2
      LastAsmError = "ADC/SBC precisa de 2 operandos"
      ProcedureReturn -1
    EndIf

    If *Op1\Kind = #Z80Opnd_Reg8 And *Op1\RegCode = 7
      If IsAdc
        ProcedureReturn EncodeAluSingle(1, *Op1, *Op2, 2, EmitMode, Out())
      Else
        ProcedureReturn EncodeAluSingle(3, *Op1, *Op2, 2, EmitMode, Out())
      EndIf
    EndIf

    If *Op1\Kind = #Z80Opnd_Reg16 And *Op1\RegCode = 2 And *Op2\Kind = #Z80Opnd_Reg16
      Out(0) = $ED
      If IsAdc
        Out(1) = $4A | (*Op2\RegCode << 4)
      Else
        Out(1) = $42 | (*Op2\RegCode << 4)
      EndIf
      ProcedureReturn 2
    EndIf

    LastAsmError = "ADC/SBC: combinacao de operandos invalida"
    ProcedureReturn -1
  EndProcedure

  ; "C" sozinho classifica como Reg8 (RegCode=1) em ClassifyOperand, nao como
  ; #Z80Opnd_Cond (colisao de nome registrador-C/condicao-C - so "C" tem esse
  ; problema, NZ/Z/NC/PO/PE/P/M nunca colidem com registrador nenhum). Aqui e
  ; onde a ambiguidade e resolvida: JP/JR/CALL/RET aceitam "C" como condicao
  ; (RegCode de condicao = 3) alem da forma #Z80Opnd_Cond normal.
  Procedure.i CondCodeOf(*Op.Z80Operand)
    If *Op\Kind = #Z80Opnd_Cond
      ProcedureReturn *Op\RegCode
    EndIf
    If *Op\Kind = #Z80Opnd_Reg8 And *Op\RegCode = 1
      ProcedureReturn 3 ; "C" - condicao C tem RegCode 3, nao 1 (esse e o do registrador)
    EndIf
    ProcedureReturn -1
  EndProcedure

  Procedure.i EncodeJp(*Op1.Z80Operand, *Op2.Z80Operand, NOps.i, EmitMode.b, Array Out.a(1))
    Protected V.Z80Addr
    If NOps = 1
      Select *Op1\Kind
        Case #Z80Opnd_IndHL
          Out(0) = $E9
          ProcedureReturn 1
        Case #Z80Opnd_IndIX
          Out(0) = $DD : Out(1) = $E9
          ProcedureReturn 2
        Case #Z80Opnd_IndIY
          Out(0) = $FD : Out(1) = $E9
          ProcedureReturn 2
        Case #Z80Opnd_Imm
          If Not EvalOperandExpr(*Op1\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
          Out(0) = $C3
          If EmitMode
            Out(1) = V\Value & $FF
            Out(2) = (V\Value >> 8) & $FF
          EndIf
          ProcedureReturn 3
      EndSelect
      LastAsmError = "JP: operando invalido"
      ProcedureReturn -1
    ElseIf NOps = 2
      Protected CCjp.i = CondCodeOf(*Op1)
      If CCjp < 0
        LastAsmError = "JP cc,nn: primeiro operando precisa ser uma condicao (NZ,Z,NC,C,PO,PE,P,M)"
        ProcedureReturn -1
      EndIf
      If Not EvalOperandExpr(*Op2\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      Out(0) = $C2 | (CCjp << 3)
      If EmitMode
        Out(1) = V\Value & $FF
        Out(2) = (V\Value >> 8) & $FF
      EndIf
      ProcedureReturn 3
    EndIf
    LastAsmError = "JP: numero de operandos invalido"
    ProcedureReturn -1
  EndProcedure

  ; JR/DJNZ: deslocamento relativo = alvo - (CurLoc + 2) - CurLoc precisa
  ; estar no endereco desta instrucao (o driver de 2 passes garante isso).
  Procedure.i EncodeJr(*Op1.Z80Operand, *Op2.Z80Operand, NOps.i, EmitMode.b, Array Out.a(1))
    Protected V.Z80Addr
    Protected TargetExpr.s
    Protected BaseOp.a

    If NOps = 1
      BaseOp = $18
      TargetExpr = *Op1\Expr
    ElseIf NOps = 2
      Protected CCjr.i = CondCodeOf(*Op1)
      If CCjr < 0 Or CCjr > 3
        LastAsmError = "JR cc,e: condicao precisa ser NZ, Z, NC ou C"
        ProcedureReturn -1
      EndIf
      Select CCjr
        Case 0 : BaseOp = $20
        Case 1 : BaseOp = $28
        Case 2 : BaseOp = $30
        Case 3 : BaseOp = $38
      EndSelect
      TargetExpr = *Op2\Expr
    Else
      LastAsmError = "JR: numero de operandos invalido"
      ProcedureReturn -1
    EndIf

    Out(0) = BaseOp
    If Not EmitMode
      ProcedureReturn 2
    EndIf

    If Not EvalExpr(TargetExpr, @V)
      LastAsmError = "JR: " + LastEvalError + LastEvalUnknownSymbol
      ProcedureReturn -1
    EndIf
    Protected Disp.i = V\Value - (CurLoc\Value + 2)
    If Disp < -128 Or Disp > 127
      LastAsmError = "JR: alvo fora de alcance (-128..127), deslocamento = " + Str(Disp)
      ProcedureReturn -1
    EndIf
    Out(1) = Disp & $FF
    ProcedureReturn 2
  EndProcedure

  Procedure.i EncodeDjnz(*Op1.Z80Operand, EmitMode.b, Array Out.a(1))
    Protected V.Z80Addr
    Out(0) = $10
    If Not EmitMode
      ProcedureReturn 2
    EndIf
    If Not EvalExpr(*Op1\Expr, @V)
      LastAsmError = "DJNZ: " + LastEvalError + LastEvalUnknownSymbol
      ProcedureReturn -1
    EndIf
    Protected Disp.i = V\Value - (CurLoc\Value + 2)
    If Disp < -128 Or Disp > 127
      LastAsmError = "DJNZ: alvo fora de alcance (-128..127), deslocamento = " + Str(Disp)
      ProcedureReturn -1
    EndIf
    Out(1) = Disp & $FF
    ProcedureReturn 2
  EndProcedure

  Procedure.i EncodeCallRet(IsCall.b, *Op1.Z80Operand, *Op2.Z80Operand, NOps.i, EmitMode.b, Array Out.a(1))
    Protected V.Z80Addr
    If IsCall
      If NOps = 1
        If Not EvalOperandExpr(*Op1\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
        Out(0) = $CD
        If EmitMode
          Out(1) = V\Value & $FF
          Out(2) = (V\Value >> 8) & $FF
        EndIf
        ProcedureReturn 3
      ElseIf NOps = 2
        Protected CCcall.i = CondCodeOf(*Op1)
        If CCcall < 0
          LastAsmError = "CALL cc,nn: primeiro operando precisa ser uma condicao"
          ProcedureReturn -1
        EndIf
        If Not EvalOperandExpr(*Op2\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
        Out(0) = $C4 | (CCcall << 3)
        If EmitMode
          Out(1) = V\Value & $FF
          Out(2) = (V\Value >> 8) & $FF
        EndIf
        ProcedureReturn 3
      EndIf
      LastAsmError = "CALL: numero de operandos invalido"
      ProcedureReturn -1
    Else
      If NOps = 0
        Out(0) = $C9
        ProcedureReturn 1
      ElseIf NOps = 1
        Protected CCret.i = CondCodeOf(*Op1)
        If CCret < 0
          LastAsmError = "RET cc: operando precisa ser uma condicao"
          ProcedureReturn -1
        EndIf
        Out(0) = $C0 | (CCret << 3)
        ProcedureReturn 1
      EndIf
      LastAsmError = "RET: numero de operandos invalido"
      ProcedureReturn -1
    EndIf
  EndProcedure

  Procedure.i EncodeCbShift(M.s, *Op1.Z80Operand, EmitMode.b, Array Out.a(1))
    Protected Idx.a, V.Z80Addr
    Select M
      Case "RLC" : Idx = 0
      Case "RRC" : Idx = 1
      Case "RL"  : Idx = 2
      Case "RR"  : Idx = 3
      Case "SLA" : Idx = 4
      Case "SRA" : Idx = 5
      Case "SLL" : Idx = 6
      Case "SRL" : Idx = 7
    EndSelect

    Select *Op1\Kind
      Case #Z80Opnd_Reg8
        Out(0) = $CB : Out(1) = (Idx << 3) | *Op1\RegCode
        ProcedureReturn 2
      Case #Z80Opnd_IndHL
        Out(0) = $CB : Out(1) = (Idx << 3) | 6
        ProcedureReturn 2
      Case #Z80Opnd_IndIX
        Out(0) = $DD : Out(1) = $CB
        If Not EvalDisplacement(*Op1\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
        If EmitMode : Out(2) = V\Value & $FF : EndIf
        Out(3) = (Idx << 3) | 6
        ProcedureReturn 4
      Case #Z80Opnd_IndIY
        Out(0) = $FD : Out(1) = $CB
        If Not EvalDisplacement(*Op1\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
        If EmitMode : Out(2) = V\Value & $FF : EndIf
        Out(3) = (Idx << 3) | 6
        ProcedureReturn 4
    EndSelect
    LastAsmError = M + ": operando invalido"
    ProcedureReturn -1
  EndProcedure

  Procedure.i EncodeCbBit(M.s, *Op1.Z80Operand, *Op2.Z80Operand, EmitMode.b, Array Out.a(1))
    Protected Base.a, V.Z80Addr, Bv.Z80Addr, B.u
    Select M
      Case "BIT" : Base = $40
      Case "RES" : Base = $80
      Case "SET" : Base = $C0
    EndSelect

    If Not EvalOperandExpr(*Op1\Expr, EmitMode, @Bv) : ProcedureReturn -1 : EndIf
    If EmitMode
      If Bv\Value > 7
        LastAsmError = M + ": numero de bit precisa ser 0-7"
        ProcedureReturn -1
      EndIf
      B = Bv\Value
    EndIf

    Select *Op2\Kind
      Case #Z80Opnd_Reg8
        Out(0) = $CB : Out(1) = Base | (B << 3) | *Op2\RegCode
        ProcedureReturn 2
      Case #Z80Opnd_IndHL
        Out(0) = $CB : Out(1) = Base | (B << 3) | 6
        ProcedureReturn 2
      Case #Z80Opnd_IndIX
        Out(0) = $DD : Out(1) = $CB
        If Not EvalDisplacement(*Op2\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
        If EmitMode : Out(2) = V\Value & $FF : EndIf
        Out(3) = Base | (B << 3) | 6
        ProcedureReturn 4
      Case #Z80Opnd_IndIY
        Out(0) = $FD : Out(1) = $CB
        If Not EvalDisplacement(*Op2\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
        If EmitMode : Out(2) = V\Value & $FF : EndIf
        Out(3) = Base | (B << 3) | 6
        ProcedureReturn 4
    EndSelect
    LastAsmError = M + ": segundo operando invalido"
    ProcedureReturn -1
  EndProcedure

  Procedure.i EncodeLd(*Op1.Z80Operand, *Op2.Z80Operand, EmitMode.b, Array Out.a(1))
    Protected V.Z80Addr

    If Not *Op1\Present Or Not *Op2\Present
      LastAsmError = "LD precisa de 2 operandos"
      ProcedureReturn -1
    EndIf

    ; --- LD A,I / LD I,A / LD A,R / LD R,A (formas fixas - "I"/"R" nao tem
    ; Kind proprio, caem como Imm com Expr="I"/"R") ---
    If *Op1\Kind = #Z80Opnd_Reg8 And *Op1\RegCode = 7 And *Op2\Kind = #Z80Opnd_Imm
      If UCase(*Op2\Expr) = "I"
        Out(0) = $ED : Out(1) = $57 : ProcedureReturn 2
      ElseIf UCase(*Op2\Expr) = "R"
        Out(0) = $ED : Out(1) = $5F : ProcedureReturn 2
      EndIf
    EndIf
    If *Op2\Kind = #Z80Opnd_Reg8 And *Op2\RegCode = 7 And *Op1\Kind = #Z80Opnd_Imm
      If UCase(*Op1\Expr) = "I"
        Out(0) = $ED : Out(1) = $47 : ProcedureReturn 2
      ElseIf UCase(*Op1\Expr) = "R"
        Out(0) = $ED : Out(1) = $4F : ProcedureReturn 2
      EndIf
    EndIf

    ; --- LD r,r' (incluindo (HL) dos dois lados, exceto (HL),(HL) = HALT) ---
    If (*Op1\Kind = #Z80Opnd_Reg8 Or *Op1\Kind = #Z80Opnd_IndHL) And (*Op2\Kind = #Z80Opnd_Reg8 Or *Op2\Kind = #Z80Opnd_IndHL)
      If *Op1\Kind = #Z80Opnd_IndHL And *Op2\Kind = #Z80Opnd_IndHL
        LastAsmError = "LD (HL),(HL) nao existe (seria HALT)"
        ProcedureReturn -1
      EndIf
      Protected R1.a, R2.a
      If *Op1\Kind = #Z80Opnd_IndHL : R1 = 6 : Else : R1 = *Op1\RegCode : EndIf
      If *Op2\Kind = #Z80Opnd_IndHL : R2 = 6 : Else : R2 = *Op2\RegCode : EndIf
      Out(0) = $40 | (R1 << 3) | R2
      ProcedureReturn 1
    EndIf

    ; --- LD r,n / LD (HL),n ---
    If (*Op1\Kind = #Z80Opnd_Reg8 Or *Op1\Kind = #Z80Opnd_IndHL) And *Op2\Kind = #Z80Opnd_Imm
      Protected R1b.a
      If *Op1\Kind = #Z80Opnd_IndHL : R1b = 6 : Else : R1b = *Op1\RegCode : EndIf
      If Not EvalOperandExpr(*Op2\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      Out(0) = $06 | (R1b << 3)
      If EmitMode : Out(1) = V\Value & $FF : EndIf
      ProcedureReturn 2
    EndIf

    ; --- LD A,(BC)/(DE) ; LD (BC)/(DE),A ---
    If *Op1\Kind = #Z80Opnd_Reg8 And *Op1\RegCode = 7 And *Op2\Kind = #Z80Opnd_IndBC
      Out(0) = $0A : ProcedureReturn 1
    EndIf
    If *Op1\Kind = #Z80Opnd_Reg8 And *Op1\RegCode = 7 And *Op2\Kind = #Z80Opnd_IndDE
      Out(0) = $1A : ProcedureReturn 1
    EndIf
    If *Op1\Kind = #Z80Opnd_IndBC And *Op2\Kind = #Z80Opnd_Reg8 And *Op2\RegCode = 7
      Out(0) = $02 : ProcedureReturn 1
    EndIf
    If *Op1\Kind = #Z80Opnd_IndDE And *Op2\Kind = #Z80Opnd_Reg8 And *Op2\RegCode = 7
      Out(0) = $12 : ProcedureReturn 1
    EndIf

    ; --- LD A,(nn) ; LD (nn),A ---
    If *Op1\Kind = #Z80Opnd_Reg8 And *Op1\RegCode = 7 And *Op2\Kind = #Z80Opnd_IndImm
      If Not EvalOperandExpr(*Op2\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      Out(0) = $3A
      If EmitMode : Out(1) = V\Value & $FF : Out(2) = (V\Value >> 8) & $FF : EndIf
      ProcedureReturn 3
    EndIf
    If *Op1\Kind = #Z80Opnd_IndImm And *Op2\Kind = #Z80Opnd_Reg8 And *Op2\RegCode = 7
      If Not EvalOperandExpr(*Op1\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      Out(0) = $32
      If EmitMode : Out(1) = V\Value & $FF : Out(2) = (V\Value >> 8) & $FF : EndIf
      ProcedureReturn 3
    EndIf

    ; --- LD HL,(nn) ; LD (nn),HL ; LD dd,(nn)/(nn),dd (ED, BC/DE/SP) ---
    If *Op1\Kind = #Z80Opnd_Reg16 And *Op2\Kind = #Z80Opnd_IndImm
      If Not EvalOperandExpr(*Op2\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      If *Op1\RegCode = 2
        Out(0) = $2A
        If EmitMode : Out(1) = V\Value & $FF : Out(2) = (V\Value >> 8) & $FF : EndIf
        ProcedureReturn 3
      Else
        Out(0) = $ED : Out(1) = $4B | (*Op1\RegCode << 4)
        If EmitMode : Out(2) = V\Value & $FF : Out(3) = (V\Value >> 8) & $FF : EndIf
        ProcedureReturn 4
      EndIf
    EndIf
    If *Op1\Kind = #Z80Opnd_IndImm And *Op2\Kind = #Z80Opnd_Reg16
      If Not EvalOperandExpr(*Op1\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      If *Op2\RegCode = 2
        Out(0) = $22
        If EmitMode : Out(1) = V\Value & $FF : Out(2) = (V\Value >> 8) & $FF : EndIf
        ProcedureReturn 3
      Else
        Out(0) = $ED : Out(1) = $43 | (*Op2\RegCode << 4)
        If EmitMode : Out(2) = V\Value & $FF : Out(3) = (V\Value >> 8) & $FF : EndIf
        ProcedureReturn 4
      EndIf
    EndIf

    ; --- LD IX,(nn)/LD(nn),IX ; LD IY,(nn)/LD(nn),IY ---
    If *Op1\Kind = #Z80Opnd_IX And *Op2\Kind = #Z80Opnd_IndImm
      If Not EvalOperandExpr(*Op2\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      Out(0) = $DD : Out(1) = $2A
      If EmitMode : Out(2) = V\Value & $FF : Out(3) = (V\Value >> 8) & $FF : EndIf
      ProcedureReturn 4
    EndIf
    If *Op1\Kind = #Z80Opnd_IndImm And *Op2\Kind = #Z80Opnd_IX
      If Not EvalOperandExpr(*Op1\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      Out(0) = $DD : Out(1) = $22
      If EmitMode : Out(2) = V\Value & $FF : Out(3) = (V\Value >> 8) & $FF : EndIf
      ProcedureReturn 4
    EndIf
    If *Op1\Kind = #Z80Opnd_IY And *Op2\Kind = #Z80Opnd_IndImm
      If Not EvalOperandExpr(*Op2\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      Out(0) = $FD : Out(1) = $2A
      If EmitMode : Out(2) = V\Value & $FF : Out(3) = (V\Value >> 8) & $FF : EndIf
      ProcedureReturn 4
    EndIf
    If *Op1\Kind = #Z80Opnd_IndImm And *Op2\Kind = #Z80Opnd_IY
      If Not EvalOperandExpr(*Op1\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      Out(0) = $FD : Out(1) = $22
      If EmitMode : Out(2) = V\Value & $FF : Out(3) = (V\Value >> 8) & $FF : EndIf
      ProcedureReturn 4
    EndIf

    ; --- LD dd,nn / LD IX,nn / LD IY,nn (16-bit imediato) ---
    If *Op1\Kind = #Z80Opnd_Reg16 And *Op2\Kind = #Z80Opnd_Imm
      If Not EvalOperandExpr(*Op2\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      Out(0) = $01 | (*Op1\RegCode << 4)
      If EmitMode : Out(1) = V\Value & $FF : Out(2) = (V\Value >> 8) & $FF : EndIf
      ProcedureReturn 3
    EndIf
    If *Op1\Kind = #Z80Opnd_IX And *Op2\Kind = #Z80Opnd_Imm
      If Not EvalOperandExpr(*Op2\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      Out(0) = $DD : Out(1) = $21
      If EmitMode : Out(2) = V\Value & $FF : Out(3) = (V\Value >> 8) & $FF : EndIf
      ProcedureReturn 4
    EndIf
    If *Op1\Kind = #Z80Opnd_IY And *Op2\Kind = #Z80Opnd_Imm
      If Not EvalOperandExpr(*Op2\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      Out(0) = $FD : Out(1) = $21
      If EmitMode : Out(2) = V\Value & $FF : Out(3) = (V\Value >> 8) & $FF : EndIf
      ProcedureReturn 4
    EndIf

    ; --- LD SP,HL / LD SP,IX / LD SP,IY ---
    If *Op1\Kind = #Z80Opnd_Reg16 And *Op1\RegCode = 3 And *Op2\Kind = #Z80Opnd_Reg16 And *Op2\RegCode = 2
      Out(0) = $F9 : ProcedureReturn 1
    EndIf
    If *Op1\Kind = #Z80Opnd_Reg16 And *Op1\RegCode = 3 And *Op2\Kind = #Z80Opnd_IX
      Out(0) = $DD : Out(1) = $F9 : ProcedureReturn 2
    EndIf
    If *Op1\Kind = #Z80Opnd_Reg16 And *Op1\RegCode = 3 And *Op2\Kind = #Z80Opnd_IY
      Out(0) = $FD : Out(1) = $F9 : ProcedureReturn 2
    EndIf

    ; --- LD r,(IX+d) / LD (IX+d),r / LD (IX+d),n (e IY) ---
    If *Op1\Kind = #Z80Opnd_Reg8 And *Op2\Kind = #Z80Opnd_IndIX
      Out(0) = $DD : Out(1) = $46 | (*Op1\RegCode << 3)
      If Not EvalDisplacement(*Op2\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      If EmitMode : Out(2) = V\Value & $FF : EndIf
      ProcedureReturn 3
    EndIf
    If *Op1\Kind = #Z80Opnd_Reg8 And *Op2\Kind = #Z80Opnd_IndIY
      Out(0) = $FD : Out(1) = $46 | (*Op1\RegCode << 3)
      If Not EvalDisplacement(*Op2\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      If EmitMode : Out(2) = V\Value & $FF : EndIf
      ProcedureReturn 3
    EndIf
    If *Op1\Kind = #Z80Opnd_IndIX And *Op2\Kind = #Z80Opnd_Reg8
      Out(0) = $DD : Out(1) = $70 | *Op2\RegCode
      If Not EvalDisplacement(*Op1\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      If EmitMode : Out(2) = V\Value & $FF : EndIf
      ProcedureReturn 3
    EndIf
    If *Op1\Kind = #Z80Opnd_IndIY And *Op2\Kind = #Z80Opnd_Reg8
      Out(0) = $FD : Out(1) = $70 | *Op2\RegCode
      If Not EvalDisplacement(*Op1\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      If EmitMode : Out(2) = V\Value & $FF : EndIf
      ProcedureReturn 3
    EndIf
    If *Op1\Kind = #Z80Opnd_IndIX And *Op2\Kind = #Z80Opnd_Imm
      Protected D1.Z80Addr, N1.Z80Addr
      Out(0) = $DD : Out(1) = $36
      If Not EvalDisplacement(*Op1\Expr, EmitMode, @D1) : ProcedureReturn -1 : EndIf
      If Not EvalOperandExpr(*Op2\Expr, EmitMode, @N1) : ProcedureReturn -1 : EndIf
      If EmitMode : Out(2) = D1\Value & $FF : Out(3) = N1\Value & $FF : EndIf
      ProcedureReturn 4
    EndIf
    If *Op1\Kind = #Z80Opnd_IndIY And *Op2\Kind = #Z80Opnd_Imm
      Protected D2.Z80Addr, N2.Z80Addr
      Out(0) = $FD : Out(1) = $36
      If Not EvalDisplacement(*Op1\Expr, EmitMode, @D2) : ProcedureReturn -1 : EndIf
      If Not EvalOperandExpr(*Op2\Expr, EmitMode, @N2) : ProcedureReturn -1 : EndIf
      If EmitMode : Out(2) = D2\Value & $FF : Out(3) = N2\Value & $FF : EndIf
      ProcedureReturn 4
    EndIf

    ; --- IXH/IXL/IYH/IYL (indocumentado - subconjunto pratico: LD com n,
    ; LD com A/B/C/D/E ou o outro half do MESMO indice, sem cruzar IX/IY) ---
    If *Op1\Kind = #Z80Opnd_IXHalf And *Op2\Kind = #Z80Opnd_Imm
      If Not EvalOperandExpr(*Op2\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      Out(0) = $DD : Out(1) = $06 | (*Op1\RegCode << 3)
      If EmitMode : Out(2) = V\Value & $FF : EndIf
      ProcedureReturn 3
    EndIf
    If *Op1\Kind = #Z80Opnd_IYHalf And *Op2\Kind = #Z80Opnd_Imm
      If Not EvalOperandExpr(*Op2\Expr, EmitMode, @V) : ProcedureReturn -1 : EndIf
      Out(0) = $FD : Out(1) = $06 | (*Op1\RegCode << 3)
      If EmitMode : Out(2) = V\Value & $FF : EndIf
      ProcedureReturn 3
    EndIf
    If *Op1\Kind = #Z80Opnd_IXHalf And (*Op2\Kind = #Z80Opnd_Reg8 Or *Op2\Kind = #Z80Opnd_IXHalf)
      Out(0) = $DD : Out(1) = $40 | (*Op1\RegCode << 3) | *Op2\RegCode
      ProcedureReturn 2
    EndIf
    If *Op2\Kind = #Z80Opnd_IXHalf And *Op1\Kind = #Z80Opnd_Reg8
      Out(0) = $DD : Out(1) = $40 | (*Op1\RegCode << 3) | *Op2\RegCode
      ProcedureReturn 2
    EndIf
    If *Op1\Kind = #Z80Opnd_IYHalf And (*Op2\Kind = #Z80Opnd_Reg8 Or *Op2\Kind = #Z80Opnd_IYHalf)
      Out(0) = $FD : Out(1) = $40 | (*Op1\RegCode << 3) | *Op2\RegCode
      ProcedureReturn 2
    EndIf
    If *Op2\Kind = #Z80Opnd_IYHalf And *Op1\Kind = #Z80Opnd_Reg8
      Out(0) = $FD : Out(1) = $40 | (*Op1\RegCode << 3) | *Op2\RegCode
      ProcedureReturn 2
    EndIf

    LastAsmError = "LD: combinacao de operandos invalida"
    ProcedureReturn -1
  EndProcedure

  Procedure.i EncodeInstruction(Mnemonic.s, ArgsText.s, EmitMode.b, Array Out.a(1))
    Protected M.s = UCase(Mnemonic)
    Protected NOps = CountOperands(ArgsText)
    Protected Op1.Z80Operand, Op2.Z80Operand

    LastAsmError = ""

    If NOps >= 1
      ClassifyOperand(GetOperand(ArgsText, 1), @Op1)
    Else
      Op1\Kind = #Z80Opnd_None : Op1\Present = #False
    EndIf
    If NOps >= 2
      ClassifyOperand(GetOperand(ArgsText, 2), @Op2)
    Else
      Op2\Kind = #Z80Opnd_None : Op2\Present = #False
    EndIf

    Select M
      Case "NOP"  : Out(0) = $00 : ProcedureReturn 1
      Case "HALT" : Out(0) = $76 : ProcedureReturn 1
      Case "DI"   : Out(0) = $F3 : ProcedureReturn 1
      Case "EI"   : Out(0) = $FB : ProcedureReturn 1
      Case "DAA"  : Out(0) = $27 : ProcedureReturn 1
      Case "CPL"  : Out(0) = $2F : ProcedureReturn 1
      Case "CCF"  : Out(0) = $3F : ProcedureReturn 1
      Case "SCF"  : Out(0) = $37 : ProcedureReturn 1
      Case "RLCA" : Out(0) = $07 : ProcedureReturn 1
      Case "RLA"  : Out(0) = $17 : ProcedureReturn 1
      Case "RRCA" : Out(0) = $0F : ProcedureReturn 1
      Case "RRA"  : Out(0) = $1F : ProcedureReturn 1
      Case "EXX"  : Out(0) = $D9 : ProcedureReturn 1
      Case "NEG"  : Out(0) = $ED : Out(1) = $44 : ProcedureReturn 2
      Case "RETN" : Out(0) = $ED : Out(1) = $45 : ProcedureReturn 2
      Case "RETI" : Out(0) = $ED : Out(1) = $4D : ProcedureReturn 2
      Case "RLD"  : Out(0) = $ED : Out(1) = $6F : ProcedureReturn 2
      Case "RRD"  : Out(0) = $ED : Out(1) = $67 : ProcedureReturn 2
      Case "LDI"  : Out(0) = $ED : Out(1) = $A0 : ProcedureReturn 2
      Case "LDD"  : Out(0) = $ED : Out(1) = $A8 : ProcedureReturn 2
      Case "LDIR" : Out(0) = $ED : Out(1) = $B0 : ProcedureReturn 2
      Case "LDDR" : Out(0) = $ED : Out(1) = $B8 : ProcedureReturn 2
      Case "CPI"  : Out(0) = $ED : Out(1) = $A1 : ProcedureReturn 2
      Case "CPD"  : Out(0) = $ED : Out(1) = $A9 : ProcedureReturn 2
      Case "CPIR" : Out(0) = $ED : Out(1) = $B1 : ProcedureReturn 2
      Case "CPDR" : Out(0) = $ED : Out(1) = $B9 : ProcedureReturn 2
      Case "INI"  : Out(0) = $ED : Out(1) = $A2 : ProcedureReturn 2
      Case "IND"  : Out(0) = $ED : Out(1) = $AA : ProcedureReturn 2
      Case "INIR" : Out(0) = $ED : Out(1) = $B2 : ProcedureReturn 2
      Case "INDR" : Out(0) = $ED : Out(1) = $BA : ProcedureReturn 2
      Case "OUTI" : Out(0) = $ED : Out(1) = $A3 : ProcedureReturn 2
      Case "OUTD" : Out(0) = $ED : Out(1) = $AB : ProcedureReturn 2
      Case "OTIR" : Out(0) = $ED : Out(1) = $B3 : ProcedureReturn 2
      Case "OTDR" : Out(0) = $ED : Out(1) = $BB : ProcedureReturn 2
      Case "RST"  : ProcedureReturn EncodeRst(@Op1, EmitMode, Out())
      Case "IM"   : ProcedureReturn EncodeIm(@Op1, EmitMode, Out())
      Case "EX"   : ProcedureReturn EncodeEx(@Op1, @Op2, EmitMode, Out())
      Case "IN"   : ProcedureReturn EncodeIn(@Op1, @Op2, NOps, EmitMode, Out())
      Case "OUT"  : ProcedureReturn EncodeOut(@Op1, @Op2, EmitMode, Out())
      Case "PUSH" : ProcedureReturn EncodePushPop($C5, @Op1, EmitMode, Out())
      Case "POP"  : ProcedureReturn EncodePushPop($C1, @Op1, EmitMode, Out())
      Case "INC"  : ProcedureReturn EncodeIncDec(#True, @Op1, EmitMode, Out())
      Case "DEC"  : ProcedureReturn EncodeIncDec(#False, @Op1, EmitMode, Out())
      Case "ADD"  : ProcedureReturn EncodeAdd(@Op1, @Op2, NOps, EmitMode, Out())
      Case "ADC"  : ProcedureReturn EncodeAdcSbc(#True, @Op1, @Op2, NOps, EmitMode, Out())
      Case "SBC"  : ProcedureReturn EncodeAdcSbc(#False, @Op1, @Op2, NOps, EmitMode, Out())
      Case "SUB"  : ProcedureReturn EncodeAluSingle(2, @Op1, @Op2, NOps, EmitMode, Out())
      Case "AND"  : ProcedureReturn EncodeAluSingle(4, @Op1, @Op2, NOps, EmitMode, Out())
      Case "XOR"  : ProcedureReturn EncodeAluSingle(5, @Op1, @Op2, NOps, EmitMode, Out())
      Case "OR"   : ProcedureReturn EncodeAluSingle(6, @Op1, @Op2, NOps, EmitMode, Out())
      Case "CP"   : ProcedureReturn EncodeAluSingle(7, @Op1, @Op2, NOps, EmitMode, Out())
      Case "LD"   : ProcedureReturn EncodeLd(@Op1, @Op2, EmitMode, Out())
      Case "JP"   : ProcedureReturn EncodeJp(@Op1, @Op2, NOps, EmitMode, Out())
      Case "JR"   : ProcedureReturn EncodeJr(@Op1, @Op2, NOps, EmitMode, Out())
      Case "DJNZ" : ProcedureReturn EncodeDjnz(@Op1, EmitMode, Out())
      Case "CALL" : ProcedureReturn EncodeCallRet(#True, @Op1, @Op2, NOps, EmitMode, Out())
      Case "RET"  : ProcedureReturn EncodeCallRet(#False, @Op1, @Op2, NOps, EmitMode, Out())
      Case "RLC", "RRC", "RL", "RR", "SLA", "SRA", "SLL", "SRL"
        ProcedureReturn EncodeCbShift(M, @Op1, EmitMode, Out())
      Case "BIT", "SET", "RES"
        ProcedureReturn EncodeCbBit(M, @Op1, @Op2, EmitMode, Out())
    EndSelect

    LastAsmError = "Mnemonico Z80 desconhecido: " + Mnemonic
    ProcedureReturn -1
  EndProcedure

  ;- ------------------------------------------------------------
  ;- Escritor de bit-stream do formato .REL (Fase B) - ver comentario no
  ;- DeclareModule acima e docs/reference/nestor80-rel-format.md. Buffer
  ;- proprio (RelBuf), separado do Mem() de 64KB do driver absoluto - cresce
  ;- por dobra (ReDim 1D, seguro - so ReDim de dimensao >1 corrompe heap, ver
  ;- memoria purebasic_redim_last_dim_only).
  ;- ------------------------------------------------------------

  Global Dim RelBuf.a(4095)
  Global RelBufCap.i = 4096
  Global RelByteCount.i = 0
  Global RelBitPos.b = 0    ; 0-7: bits ja usados no byte parcial RelBuf(RelByteCount-1); 0 = nenhum byte parcial pendente

  Procedure RelW_Reset()
    RelByteCount = 0
    RelBitPos = 0
  EndProcedure

  Procedure RelW_EnsureCap(NeedBytes.i)
    If NeedBytes <= RelBufCap
      ProcedureReturn
    EndIf
    Protected NewCap = RelBufCap
    While NewCap < NeedBytes
      NewCap = NewCap * 2
    Wend
    ReDim RelBuf.a(NewCap - 1)
    RelBufCap = NewCap
  EndProcedure

  ; Grava um byte JA COMPLETO diretamente no buffer, fora do mecanismo de item
  ; bit a bit - usado so pro cabecalho de 16 bytes do formato estendido (que e
  ; literalmente colado no arquivo, ANTES de qualquer item de bit-stream
  ; comecar, nao um "byte absoluto" dentro da gramatica de itens). Exige
  ; alinhamento de byte (RelBitPos = 0) - responsabilidade do chamador.
  Procedure RelW_AppendRawByte(B.a)
    RelW_EnsureCap(RelByteCount + 1)
    RelBuf(RelByteCount) = B
    RelByteCount + 1
  EndProcedure

  ; Empacota os NBits bits menos significativos de Value no bit-stream,
  ; bit a bit, do mais significativo pro menos significativo, sempre
  ; preenchendo cada byte do buffer a partir do bit mais significativo (MSB)
  ; primeiro - mesma semantica de BitStreamWriter.Write() do Nestor80
  ; (Assembler/Relocatable/BitStreamWriter.cs), confirmada empiricamente
  ; decodificando um .REL real do N80.exe bit a bit (ver docs/resumo-asm.md).
  Procedure RelW_WriteBits(Value.l, NBits.b)
    Protected Idx.b, BitVal.b
    For Idx = NBits - 1 To 0 Step -1
      If RelBitPos = 0
        RelW_EnsureCap(RelByteCount + 1)
        RelBuf(RelByteCount) = 0
        RelByteCount + 1
      EndIf
      BitVal = (Value >> Idx) & 1
      If BitVal
        RelBuf(RelByteCount - 1) = RelBuf(RelByteCount - 1) | (BitVal << (7 - RelBitPos))
      EndIf
      RelBitPos + 1
      If RelBitPos = 8 : RelBitPos = 0 : EndIf
    Next
  EndProcedure

  Procedure RelW_ForceByteBoundary()
    RelBitPos = 0   ; o byte parcial ja existe em RelBuf() (criado zerado, so bits 1 sao ORados) - so precisa
                     ; parar de completa-lo; proximo Write comeca um byte novo
  EndProcedure

  ; Cabecalho fixo de 16 bytes do formato estendido Nestor80 - por si so uma
  ; codificacao valida de ProgramName "LNKSTOR" + DataSegSize 0 + EndOfProgram
  ; FFFFh + EndOfFile (ver docs/reference/nestor80-rel-format.md), colada
  ; direto no arquivo ANTES do primeiro item de bit-stream de cada programa -
  ; identica byte a byte ao inicio de um .REL real gerado pelo N80.exe.
  Procedure RelW_WriteExtendedHeader()
    RelW_ForceByteBoundary()
    RelW_AppendRawByte($85) : RelW_AppendRawByte($D3) : RelW_AppendRawByte($13) : RelW_AppendRawByte($92)
    RelW_AppendRawByte($D4) : RelW_AppendRawByte($D5) : RelW_AppendRawByte($13) : RelW_AppendRawByte($D4)
    RelW_AppendRawByte($A5) : RelW_AppendRawByte($00) : RelW_AppendRawByte($00) : RelW_AppendRawByte($13)
    RelW_AppendRawByte($8F) : RelW_AppendRawByte($FF) : RelW_AppendRawByte($F0) : RelW_AppendRawByte($9E)
  EndProcedure

  ; "Byte absoluto": prefixo "0" + 8 bits do valor (WriteByte() no Nestor80)
  Procedure RelW_WriteByteItem(B.a)
    RelW_WriteBits(0, 1)
    RelW_WriteBits(B, 8)
  EndProcedure

  ; "Valor relocavel": prefixo "1" + 2 bits de segmento + 16 bits do valor,
  ; byte baixo primeiro depois byte alto (little-endian, cada um escrito como
  ; 8 bits MSB-first normais - WriteAddress() no Nestor80). SegType SO pode
  ; ser Code/Data/Common (#Z80Seg_Absolute=0 e reservado: "1"+"00" e o prefixo
  ; do item de link, nunca um valor relocavel de verdade - ASEG nunca precisa
  ; de relocacao, entao nunca gera este item).
  Procedure RelW_WriteValueItem(SegType.b, Value.u)
    RelW_WriteBits(1, 1)
    RelW_WriteBits(SegType, 2)
    RelW_WriteBits(Value & $FF, 8)
    RelW_WriteBits((Value >> 8) & $FF, 8)
  EndProcedure

  ; Campo de simbolo do formato ESTENDIDO (WriteSymbolField()/logica de escape
  ; de WriteLinkItem() no Nestor80): campo normal = 3 bits de tamanho (0-7) +
  ; N bytes UTF-8; quando o simbolo tem mais de 7 bytes (ou 2-7 bytes cujo
  ; primeiro byte de conteudo e FFh, caso ambiguo) vira um "escape": 3 bits de
  ; tamanho =2 (ou 3/4) + FFh + tamanho real em 1-3 bytes little-endian,
  ; seguido dos bytes de verdade do simbolo (sem outro prefixo de tamanho).
  Procedure RelW_WriteSymbolField(Sym.s)
    Protected NBytes = StringByteLength(Sym, #PB_UTF8)
    Protected Dim B.a(0)
    If NBytes > 0
      ReDim B.a(NBytes - 1)
      Protected *SymMem = AllocateMemory(NBytes + 1)
      PokeS(*SymMem, Sym, -1, #PB_UTF8)
      Protected Idx
      For Idx = 0 To NBytes - 1
        B(Idx) = PeekA(*SymMem + Idx)
      Next
      FreeMemory(*SymMem)
    EndIf

    If NBytes > 7 Or (NBytes > 1 And B(0) = $FF)
      Protected LegacyLen
      If NBytes < 256
        LegacyLen = 2
      ElseIf NBytes < 65536
        LegacyLen = 3
      Else
        LegacyLen = 4
      EndIf
      RelW_WriteBits(LegacyLen, 3)
      RelW_WriteBits($FF, 8)
      RelW_WriteBits(NBytes & $FF, 8)
      If LegacyLen >= 3 : RelW_WriteBits((NBytes >> 8) & $FF, 8) : EndIf
      If LegacyLen >= 4 : RelW_WriteBits((NBytes >> 16) & $FF, 8) : EndIf
    Else
      RelW_WriteBits(NBytes, 3)
    EndIf

    For Idx = 0 To NBytes - 1
      RelW_WriteBits(B(Idx), 8)
    Next
  EndProcedure

  ; Item de link generico: prefixo "100" + 4 bits de tipo + campo opcional de
  ; endereco (2 bits segmento + 16 bits valor) + campo opcional de simbolo
  ; (ver RelW_WriteSymbolField) - espelha as sobrecargas de WriteLinkItem() no
  ; Nestor80. Ao contrario de RelW_WriteValueItem, o campo de endereco aqui
  ; DENTRO de um item de link aceita qualquer segmento (incl. ASEG=0) sem
  ; ambiguidade nenhuma, porque o "100" ja identificou que e um item de link -
  ; so o nivel mais externo do bit-stream reserva "1"+"00" pro item de link.
  Procedure RelW_WriteLinkItem(ItemType.b, HasAddr.b = #False, AddrSeg.b = 0, AddrValue.u = 0, HasSymbol.b = #False, Symbol.s = "")
    RelW_WriteBits(%100, 3)
    RelW_WriteBits(ItemType, 4)
    If HasAddr
      RelW_WriteBits(AddrSeg, 2)
      RelW_WriteBits(AddrValue & $FF, 8)
      RelW_WriteBits((AddrValue >> 8) & $FF, 8)
    EndIf
    If HasSymbol
      RelW_WriteSymbolField(Symbol)
    EndIf
  EndProcedure

  Procedure.i RelW_GetByteCount()
    ProcedureReturn RelByteCount
  EndProcedure

  ; Out() precisa vir dimensionado pelo chamador com pelo menos
  ; RelW_GetByteCount() posicoes (mesma convencao de Assemble()/OutBytes).
  Procedure.i RelW_GetBytes(Array Out.a(1))
    Protected Idx
    For Idx = 0 To RelByteCount - 1
      Out(Idx) = RelBuf(Idx)
    Next
    ProcedureReturn RelByteCount
  EndProcedure

  ;- ------------------------------------------------------------
  ; Forward declares - ExpandLines()/EncodeDataDirective() so sao definidas
  ; mais abaixo (secoes de condicionais/macros e diretivas de dados), mas
  ; RunOnePassRel (logo a seguir) precisa chamar as duas - mesma assinatura
  ; dos Declares que ja existem la embaixo, junto de cada definicao.
  Declare.b ExpandLines(List InLines.s(), List OutLines.s(), SizeOnly.b, Depth.i)
  Declare.b EncodeDataDirective(Op.s, ArgsText.s, EmitMode.b, List OutBytes.a())
  Declare   SplitSourceLines(SourceText.s, List Lines.s())

  ;- ------------------------------------------------------------
  ;- Driver de 2 passes RELOCAVEL (RunOnePassRel/AssembleRelocatable) - Fase B,
  ;- consome o escritor de bit-stream RelW_* acima. NAO mexe em RunOnePass()/
  ;- Assemble() (driver absoluto original, Fase A) - convivem lado a lado,
  ;- cada um serve um formato de saida diferente; o chamador decide qual usar
  ;- (ver NeedsRelocatable() abaixo). ASEG/CSEG/DSEG/COMMON/PUBLIC/EXTRN
  ;- passam a ter efeito de verdade AQUI (contador de localizacao por area,
  ;- exportacao de simbolos, referencia a externo via corrente) - continuam
  ;- sendo reconhecidos-sem-efeito no driver absoluto, de proposito (Fase A
  ;- so entende ASEG puro, nunca foi validada com segmentos de verdade).
  ;-
  ;- Escopo suportado: ASEG/CSEG/DSEG/COMMON (contador por area, COMMON reseta
  ;- pra 0 a cada entrada - ver docs/reference/nestor80-rel-format.md), ORG
  ;- dentro de qualquer area, PUBLIC/ENTRY/GLOBAL (e rotulo com "::"), EXTRN/
  ;- EXT/EXTERNAL como referencia BARE simples (operando de CALL/JP/LD nn ou
  ;- de DW = so o nome do externo, nada mais - vira item de corrente
  ;- ChainExternal). Fora de escopo nesta etapa (erro explicito - ver cada
  ;- ponto abaixo -, nunca silenciosamente errado): expressao composta
  ;- envolvendo externo (precisaria do item de extensao RPN, ex. "(FOO+1)*2"),
  ;- soma entre dois valores relocaveis ou subtracao entre relocaveis de
  ;- segmentos diferentes (EvalPostfixExpr acima), valor relocavel truncado
  ;- pra 1 byte (ExpandDataOperand acima), .PHASE/.DEPHASE, biblioteca/
  ;- .REQUEST (essa ultima e trabalho do futuro Z80Link.pbi/Z80Lib.pbi, nao
  ;- do assembler).
  ;- ------------------------------------------------------------

  Global RelCurArea.b
  Global RelCurCommonName.s
  Global RelLocASEG.u, RelLocCSEG.u, RelLocDSEG.u, RelLocCOMMON.u
  Global NewMap RelCommonMaxSize.u()        ; maior offset ja alcancado por nome de bloco COMMON (todas as visitas)
  Global NewList RelCommonMaxSizeFrozen.Z80RelCommonSizeEntry()  ; "foto" tirada no fim do pass 1, usada pro cabecalho do pass 2
  Global RelLastSelectedCommon.s            ; ultimo SelectCommonBlock realmente emitido (evita repetir)
  ; chave = nome em MAIUSCULO (casar case-insensitive, mesma convencao dos
  ; simbolos locais); valor = grafia ORIGINAL declarada no EXTRN/EXT/EXTERNAL
  ; ("" = nao declarado) - usada como o nome de verdade gravado no .REL.
  Global NewMap RelExternDeclared.s()
  Global NewMap RelChainState.Z80RelChainState()
  Global NewList RelChainOrder.s()          ; nomes externos REFERENCIADOS de verdade, na ordem da 1a referencia
  Global NewList RelPublicOrder.s()         ; nomes PUBLIC/ENTRY/GLOBAL/"::" , na ordem declarada
  Global NewMap RelPublicSeen.b()           ; dedup de RelPublicOrder
  Global RelEndAddrSeg.b, RelEndAddrVal.u   ; operando do END (0 absoluto se nao tiver)

  ; Normaliza um texto de operando pra comparar contra um nome de externo
  ; declarado: maiusculo, aparado, e SEM os parenteses de endereçamento
  ; indireto se houver (a forma "(EXTERNO)" - ex. "ld a,(shareddata)" - e tao
  ; comum quanto a forma sem parenteses "call externo"; sem isso, so a
  ; segunda forma seria reconhecida como referencia bare).
  Procedure.s BareExternKeyOf(Text.s)
    Protected T.s = UCase(Trim(Text))
    If Len(T) >= 2 And Left(T, 1) = "(" And Right(T, 1) = ")"
      T = Trim(Mid(T, 2, Len(T) - 2))
    EndIf
    ProcedureReturn T
  EndProcedure

  Procedure.b Is16BitRegName(S.s)
    Select UCase(S)
      Case "BC", "DE", "HL", "SP", "IX", "IY"
        ProcedureReturn #True
    EndSelect
    ProcedureReturn #False
  EndProcedure

  Procedure.u RelAreaCounter(Area.b, CommonName.s)
    Select Area
      Case #Z80Seg_Absolute : ProcedureReturn RelLocASEG
      Case #Z80Seg_Code     : ProcedureReturn RelLocCSEG
      Case #Z80Seg_Data     : ProcedureReturn RelLocDSEG
      Case #Z80Seg_Common   : ProcedureReturn RelLocCOMMON
    EndSelect
    ProcedureReturn 0
  EndProcedure

  Procedure RelSetAreaCounter(Area.b, CommonName.s, NewVal.u)
    Select Area
      Case #Z80Seg_Absolute : RelLocASEG = NewVal
      Case #Z80Seg_Code     : RelLocCSEG = NewVal
      Case #Z80Seg_Data     : RelLocDSEG = NewVal
      Case #Z80Seg_Common
        RelLocCOMMON = NewVal
        If NewVal > RelCommonMaxSize(CommonName)
          RelCommonMaxSize(CommonName) = NewVal
        EndIf
    EndSelect
  EndProcedure

  Procedure RelAdvanceArea(Area.b, CommonName.s, Delta.i)
    RelSetAreaCounter(Area, CommonName, (RelAreaCounter(Area, CommonName) + Delta) & $FFFF)
  EndProcedure

  ; Emite "SetLocationCounter" (+ "SelectCommonBlock" antes, se o bloco COMMON
  ; mudou) - usado tanto ao trocar de area (ASEG/CSEG/DSEG/COMMON) quanto num
  ; ORG dentro da area atual. So escreve de verdade em EmitMode (pass 2) - o
  ; pass 1 so precisa dos contadores em si (RelSetAreaCounter/RelAdvanceArea),
  ; nunca do bit-stream.
  Procedure RelEmitAreaSwitch(Area.b, CommonName.s, NewValue.u, EmitMode.b)
    If Not EmitMode
      ProcedureReturn
    EndIf
    If Area = #Z80Seg_Common And CommonName <> RelLastSelectedCommon
      RelW_WriteLinkItem(#Z80Rel_SelectCommonBlock, #False, 0, 0, #True, CommonName)
      RelLastSelectedCommon = CommonName
    EndIf
    RelW_WriteLinkItem(#Z80Rel_SetLocationCounter, #True, Area, NewValue)
  EndProcedure

  ; Referencia a um simbolo externo via o mecanismo de "corrente" (link item
  ; tipo 6 ChainExternal, ver docs/reference/nestor80-rel-format.md) - a
  ; PRIMEIRA referencia a um nome grava 2 bytes absolutos 00 00 (fim da
  ; corrente); cada referencia SEGUINTE ao MESMO nome grava, no lugar dos 2
  ; bytes, um item de VALOR RELOCAVEL apontando pra posicao da referencia
  ; anterior (area+contador de entao) - formando uma lista encadeada pra
  ; tras que o linker percorre, corrigindo cada posicao com o valor final do
  ; externo. NowArea/NowValue/NowCommon = posicao (area ativa + contador ANTES
  ; de avancar por estes 2 bytes) de onde estes 2 bytes estao sendo escritos
  ; agora - vira o novo "ultimo elo" pra uma eventual proxima referencia.
  ; Key = maiusculo (identidade/dedup do externo, case-insensitive); DisplayName
  ; = grafia original (da 1a ocorrencia) - so usada se esta for a primeira vez
  ; que este Key aparece (ocorrencias seguintes reusam o DisplayName ja
  ; gravado, mesmo que a grafia mude entre chamadas - grafia da 1a vitoria).
  Procedure RelWriteExternalChainRef(Key.s, DisplayName.s, NowArea.b, NowValue.u, NowCommon.s)
    If FindMapElement(RelChainState(), Key)
      RelW_WriteValueItem(RelChainState()\LastPos\SegType, RelChainState()\LastPos\Value)
    Else
      AddMapElement(RelChainState(), Key)
      RelChainState()\DisplayName = DisplayName
      AddElement(RelChainOrder())
      RelChainOrder() = Key
      RelW_WriteByteItem(0)
      RelW_WriteByteItem(0)
    EndIf
    Z80Addr_Make(@RelChainState()\LastPos, NowValue, NowArea, NowCommon)
  EndProcedure

  ; Descobre, pra uma linha de instrucao de CPU ja classificada como LD/JP/
  ; CALL, qual texto de operando (se algum) carrega o imediato de 16 bits que
  ; termina como os 2 ULTIMOS bytes da instrucao ja codificada - unico ponto
  ; do ISA Z80 onde um valor relocavel de 16 bits pode aparecer embutido
  ; numa instrucao (JR/DJNZ usam deslocamento relativo, sempre absoluto por
  ; construcao - ver EvalPostfixExpr/Z80Addr_SameSegment; nenhuma outra forma
  ; de instrucao carrega imediato de 16 bits). So um heuristico de FORMA (usa
  ; IsRegister/parenteses pra achar o operando candidato) - a classificacao
  ; de verdade (e absoluta seguranca contra falso positivo, ex. "(IX+d)")
  ; acontece depois, tentando avaliar esse texto e checando o SegType/erro
  ; devolvido, ver uso em RunOnePassRel.
  Procedure.s RelFindTailOperandText(Mnemonic.s, ArgsText.s)
    Protected NOps = CountOperands(ArgsText)
    Select Mnemonic
      Case "JP", "CALL"
        If NOps = 1
          Protected T1.s = Trim(GetOperand(ArgsText, 1))
          Protected T1U.s = UCase(T1)
          Protected T1Inner.s = T1U
          If Len(T1U) >= 2 And Left(T1U, 1) = "(" And Right(T1U, 1) = ")"
            T1Inner = Trim(Mid(T1U, 2, Len(T1U) - 2))
          EndIf
          If Not IsRegister(T1Inner)
            ProcedureReturn T1
          EndIf
        ElseIf NOps = 2
          ProcedureReturn Trim(GetOperand(ArgsText, 2))
        EndIf
      Case "LD"
        If NOps = 2
          Protected LT1.s = Trim(GetOperand(ArgsText, 1))
          Protected LT2.s = Trim(GetOperand(ArgsText, 2))
          Protected LT1U.s = UCase(LT1)
          Protected LT2U.s = UCase(LT2)
          Protected LT1IsMem.b = Bool(Len(LT1U) >= 2 And Left(LT1U, 1) = "(" And Right(LT1U, 1) = ")")
          Protected LT2IsMem.b = Bool(Len(LT2U) >= 2 And Left(LT2U, 1) = "(" And Right(LT2U, 1) = ")")
          Protected LT1Inner.s = LT1U : If LT1IsMem : LT1Inner = Trim(Mid(LT1U, 2, Len(LT1U) - 2)) : EndIf
          Protected LT2Inner.s = LT2U : If LT2IsMem : LT2Inner = Trim(Mid(LT2U, 2, Len(LT2U) - 2)) : EndIf
          If LT1IsMem And Not IsRegister(LT1Inner)
            ProcedureReturn LT1
          ElseIf LT2IsMem And Not IsRegister(LT2Inner)
            ProcedureReturn LT2
          ElseIf Not LT1IsMem And Not LT2IsMem And Is16BitRegName(LT1U)
            ProcedureReturn LT2
          EndIf
        EndIf
    EndSelect
    ProcedureReturn ""
  EndProcedure

  ; Roda um pass sobre Lines() em modo relocavel. SizeOnly=#True (pass 1) so
  ; mede (contadores por area + tabela de simbolos completa - nenhum RelW_*
  ; chamado); SizeOnly=#False (pass 2) escreve o .REL de verdade em RelBuf via
  ; RelW_* - comeca escrevendo o cabecalho (ProgramName/EntrySymbol/tamanhos),
  ; usando FinalCSEGSize/FinalDSEGSize (medidos no pass 1 - ver
  ; AssembleRelocatable) e RelCommonMaxSizeFrozen (idem). RelPublicOrder()/
  ; RelExternDeclared() NAO sao resetados aqui (de proposito - precisam
  ; sobreviver do pass 1 pro pass 2 poder escrever EntrySymbol/reconhecer
  ; externo ja no INICIO do pass 2, antes do conteudo em si ser reprocessado -
  ; ver reset em AssembleRelocatable). O resto (contadores de posicao, corrente
  ; de externo) reseta em toda chamada, cada pass refaz a caminhada do zero.
  Procedure.b RunOnePassRel(List Lines.s(), SizeOnly.b, ProgramName.s, FinalCSEGSize.u = 0, FinalDSEGSize.u = 0)
    Protected LineNum = 0
    Protected PL.Z80ParsedLine
    Protected Dim Bytes.a(3)
    Protected Len4.i, Idx
    Protected Ended.b = #False
    Protected V1.Z80Addr, V2.Z80Addr
    Protected EmitMode.b = Bool(Not SizeOnly)

    RelCurArea = #Z80Seg_Code : RelCurCommonName = ""  ; CSEG e a area padrao (Nestor80, WritingRelocatableCode.md)
    RelLocASEG = 0 : RelLocCSEG = 0 : RelLocDSEG = 0 : RelLocCOMMON = 0
    RelLastSelectedCommon = ""
    ClearMap(RelChainState())
    ClearList(RelChainOrder())
    RelEndAddrSeg = #Z80Seg_Absolute : RelEndAddrVal = 0

    Z80Addr_Make(@CurLoc, 0, RelCurArea, RelCurCommonName)

    If EmitMode
      RelW_Reset()
      RelW_WriteExtendedHeader()
      RelW_WriteLinkItem(#Z80Rel_ProgramName, #False, 0, 0, #True, ProgramName)
      ForEach RelPublicOrder()
        RelW_WriteLinkItem(#Z80Rel_EntrySymbol, #False, 0, 0, #True, RelPublicOrder())
      Next
      ForEach RelCommonMaxSizeFrozen()
        RelW_WriteLinkItem(#Z80Rel_DefineCommonSize, #True, #Z80Seg_Absolute, RelCommonMaxSizeFrozen()\Size, #True, RelCommonMaxSizeFrozen()\Name)
      Next
      RelW_WriteLinkItem(#Z80Rel_DataAreaSize, #True, #Z80Seg_Absolute, FinalDSEGSize)
      If FinalCSEGSize > 0
        RelW_WriteLinkItem(#Z80Rel_ProgramAreaSize, #True, #Z80Seg_Code, FinalCSEGSize)
      EndIf
    EndIf

    Protected NewList ExpLines.s()
    If Not ExpandLines(Lines(), ExpLines(), SizeOnly, 0)
      AsmErrorLine = LineNum : AsmErrorText = LastAsmError
      ProcedureReturn #False
    EndIf

    ForEach ExpLines()
      If Ended
        Break
      EndIf
      LineNum + 1

      ParseLine(ExpLines(), @PL)

      If PL\IsBlank
        Continue
      EndIf

      ; Achado real (2026-08-13, exposto pelo comando A do Mamute Assembler):
      ; uma linha com label DE DOIS PONTOS ("NOME:") E operador EQU/DEFL/
      ; ASET nao pode definir o simbolo AQUI (posicional, no CurLoc) - isso
      ; e' so pro caso de label "normal" (rotulo de instrucao/dado). Se o
      ; operador for um "constantDefinitionOpcode", o Select abaixo ja'
      ; define o simbolo com o VALOR CERTO (o resultado da expressao, nao o
      ; endereco corrente) - definir os DOIS fazia o mesmo nome colidir
      ; consigo mesmo no pass 2 (2o valor <> 1o valor -> "simbolo ja
      ; definido"), mesmo com uma unica definicao real no fonte. O dialeto
      ; M80/Nestor80 classico evita isso nunca colocando ":" no label de um
      ; EQU ("NOME EQU valor", sem dois-pontos - ver comentario de
      ; LabelHasColon no topo do arquivo) - mas o Mamute Assembler (unico
      ; consumidor que gera "NOME: EQU valor" COM dois-pontos) precisa que
      ; isso funcione tambem.
      Protected IsConstDefOpRel.b = Bool(PL\HasOperator And (PL\Operator = "EQU" Or PL\Operator = "DEFL" Or PL\Operator = "ASET"))
      If PL\HasLabel And PL\LabelHasColon
        If Not IsConstDefOpRel
          If Not DefineSymbolSeg(PL\Label, CurLoc\Value, RelCurArea, RelCurCommonName, #False)
            AsmErrorLine = LineNum : AsmErrorText = LastEvalError
            ProcedureReturn #False
          EndIf
        EndIf
        If PL\LabelIsPublic And Not RelPublicSeen(UCase(PL\Label))
          RelPublicSeen(UCase(PL\Label)) = #True
          AddElement(RelPublicOrder()) : RelPublicOrder() = PL\Label
        EndIf
      EndIf

      If Not PL\HasOperator
        Continue
      EndIf

      Select PL\Operator
        Case "EQU"
          If EvalExpr(PL\ArgsText, @V1)
            If Not DefineSymbolSeg(PL\Label, V1\Value, V1\SegType, V1\CommonName, #True)
              AsmErrorLine = LineNum : AsmErrorText = LastEvalError
              ProcedureReturn #False
            EndIf
          ElseIf EmitMode
            AsmErrorLine = LineNum : AsmErrorText = "EQU: " + LastEvalError + LastEvalUnknownSymbol
            ProcedureReturn #False
          EndIf
          Continue

        Case "DEFL", "ASET"
          If EvalExpr(PL\ArgsText, @V2)
            If Not DefineSymbolSeg(PL\Label, V2\Value, V2\SegType, V2\CommonName, #False)
              AsmErrorLine = LineNum : AsmErrorText = LastEvalError
              ProcedureReturn #False
            EndIf
          ElseIf EmitMode
            AsmErrorLine = LineNum : AsmErrorText = "DEFL/ASET: " + LastEvalError + LastEvalUnknownSymbol
            ProcedureReturn #False
          EndIf
          Continue

        Case "ORG"
          Protected VOrg.Z80Addr
          If EvalExpr(PL\ArgsText, @VOrg)
            RelSetAreaCounter(RelCurArea, RelCurCommonName, VOrg\Value)
            Z80Addr_Make(@CurLoc, VOrg\Value, RelCurArea, RelCurCommonName)
            RelEmitAreaSwitch(RelCurArea, RelCurCommonName, VOrg\Value, EmitMode)
          ElseIf EmitMode
            AsmErrorLine = LineNum : AsmErrorText = "ORG: " + LastEvalError + LastEvalUnknownSymbol
            ProcedureReturn #False
          EndIf
          Continue

        Case "END"
          Protected VEnd.Z80Addr
          If RTrimWs(Mid(PL\ArgsText, SkipWs(PL\ArgsText, 1))) <> ""
            If EvalExpr(PL\ArgsText, @VEnd)
              RelEndAddrSeg = VEnd\SegType : RelEndAddrVal = VEnd\Value
            ElseIf EmitMode
              AsmErrorLine = LineNum : AsmErrorText = "END: " + LastEvalError + LastEvalUnknownSymbol
              ProcedureReturn #False
            EndIf
          EndIf
          Ended = #True
          Continue

        Case ".PHASE", "PHASE", ".DEPHASE", "DEPHASE"
          AsmErrorLine = LineNum
          AsmErrorText = PL\Operator + ": nao suportado no modo relocavel ainda (Fase B parcial)"
          ProcedureReturn #False

        Case "ASEG"
          RelCurArea = #Z80Seg_Absolute : RelCurCommonName = ""
          RelEmitAreaSwitch(RelCurArea, RelCurCommonName, RelAreaCounter(RelCurArea, RelCurCommonName), EmitMode)
          Z80Addr_Make(@CurLoc, RelAreaCounter(RelCurArea, RelCurCommonName), RelCurArea)
          Continue

        Case "CSEG"
          RelCurArea = #Z80Seg_Code : RelCurCommonName = ""
          RelEmitAreaSwitch(RelCurArea, RelCurCommonName, RelAreaCounter(RelCurArea, RelCurCommonName), EmitMode)
          Z80Addr_Make(@CurLoc, RelAreaCounter(RelCurArea, RelCurCommonName), RelCurArea)
          Continue

        Case "DSEG"
          RelCurArea = #Z80Seg_Data : RelCurCommonName = ""
          RelEmitAreaSwitch(RelCurArea, RelCurCommonName, RelAreaCounter(RelCurArea, RelCurCommonName), EmitMode)
          Z80Addr_Make(@CurLoc, RelAreaCounter(RelCurArea, RelCurCommonName), RelCurArea)
          Continue

        Case "COMMON"
          Protected CommonRaw.s = Trim(RTrimWs(Mid(PL\ArgsText, SkipWs(PL\ArgsText, 1))))
          Protected CommonNameArg.s
          If Len(CommonRaw) >= 2 And Left(CommonRaw, 1) = "/" And Right(CommonRaw, 1) = "/"
            CommonNameArg = UCase(Trim(Mid(CommonRaw, 2, Len(CommonRaw) - 2)))
          Else
            AsmErrorLine = LineNum : AsmErrorText = "COMMON: forma esperada e COMMON /nome/ (nome pode ser vazio)"
            ProcedureReturn #False
          EndIf
          RelCurArea = #Z80Seg_Common : RelCurCommonName = CommonNameArg
          RelLocCOMMON = 0 ; entrar num bloco COMMON sempre reseta o contador pra 0 (ver doc de referencia)
          RelEmitAreaSwitch(RelCurArea, RelCurCommonName, 0, EmitMode)
          Z80Addr_Make(@CurLoc, 0, RelCurArea, RelCurCommonName)
          Continue

        Case "PUBLIC", "ENTRY", "GLOBAL"
          Protected PubN = CountOperands(PL\ArgsText)
          Protected PubI
          For PubI = 1 To PubN
            Protected PubNameOrig.s = Trim(GetOperand(PL\ArgsText, PubI))
            Protected PubNameKey.s = UCase(PubNameOrig)
            If PubNameKey <> "" And Not RelPublicSeen(PubNameKey)
              RelPublicSeen(PubNameKey) = #True
              AddElement(RelPublicOrder()) : RelPublicOrder() = PubNameOrig
            EndIf
          Next
          Continue

        Case "EXTRN", "EXT", "EXTERNAL"
          Protected ExtN = CountOperands(PL\ArgsText)
          Protected ExtI
          For ExtI = 1 To ExtN
            Protected ExtNameOrig.s = Trim(GetOperand(PL\ArgsText, ExtI))
            Protected ExtKey.s = UCase(ExtNameOrig)
            If ExtKey <> ""
              RelExternDeclared(ExtKey) = ExtNameOrig
            EndIf
          Next
          Continue

        Case ".REQUEST", "REQUEST"
          ; ".REQUEST nome[,nome...]" (LR:1627-1635) - so grava o pedido no
          ; .REL (item de link tipo 3); a busca/resolucao de verdade e
          ; trabalho do LINKER (Z80Link.pbi), nao do assembler.
          Protected ReqN = CountOperands(PL\ArgsText)
          Protected ReqI
          For ReqI = 1 To ReqN
            Protected ReqName.s = Trim(GetOperand(PL\ArgsText, ReqI))
            If ReqName <> "" And EmitMode
              RelW_WriteLinkItem(#Z80Rel_RequestLibrarySearch, #False, 0, 0, #True, ReqName)
            EndIf
          Next
          Continue

        Case "AREA", "TITLE", "SUBTTL", "PAGE", "MAINPAGE", "ENDOUT", "ROOT", "RELAB", "XRELAB", "EXTROOT", "XEXTROOT"
          Continue

        Case "DB", "DEFB", "DEFM", "DC", "DZ", "DEFZ"
          NewList DataBytes.a()
          If Not EncodeDataDirective(PL\Operator, PL\ArgsText, EmitMode, DataBytes())
            AsmErrorLine = LineNum : AsmErrorText = LastAsmError
            ProcedureReturn #False
          EndIf
          If EmitMode
            ForEach DataBytes()
              RelW_WriteByteItem(DataBytes())
            Next
          EndIf
          RelAdvanceArea(RelCurArea, RelCurCommonName, ListSize(DataBytes()))
          CurLoc\Value = (CurLoc\Value + ListSize(DataBytes())) & $FFFF
          Continue

        Case "DS", "DEFS"
          ; Sem valor de preenchimento explicito, o Nestor80 NAO materializa
          ; bytes reais no .REL - so avanca o contador de localizacao (item
          ; SetLocationCounter), equivalente a "ORG $+tamanho" (ver
          ; OutputGenerator.cs/GenerateRelocatable, ramo "initDefs=false" -
          ; comportamento padrao do N80.exe, confirmado por oraculo). So
          ; escreve bytes de verdade quando um segundo operando (valor) foi
          ; dado explicitamente.
          NewList DataBytes.a()
          If Not EncodeDataDirective(PL\Operator, PL\ArgsText, EmitMode, DataBytes())
            AsmErrorLine = LineNum : AsmErrorText = LastAsmError
            ProcedureReturn #False
          EndIf
          Protected DsHasFill.b = Bool(CountOperands(PL\ArgsText) = 2)
          If EmitMode
            If DsHasFill
              ForEach DataBytes()
                RelW_WriteByteItem(DataBytes())
              Next
            Else
              RelEmitAreaSwitch(RelCurArea, RelCurCommonName, (RelAreaCounter(RelCurArea, RelCurCommonName) + ListSize(DataBytes())) & $FFFF, EmitMode)
            EndIf
          EndIf
          RelAdvanceArea(RelCurArea, RelCurCommonName, ListSize(DataBytes()))
          CurLoc\Value = (CurLoc\Value + ListSize(DataBytes())) & $FFFF
          Continue

        Case "DW", "DEFW"
          Protected NOpsDw = CountOperands(PL\ArgsText)
          If NOpsDw = 0
            AsmErrorLine = LineNum : AsmErrorText = PL\Operator + ": precisa de pelo menos um operando"
            ProcedureReturn #False
          EndIf
          If EmitMode
            Protected DwLineStart.u = RelAreaCounter(RelCurArea, RelCurCommonName)
            Protected DwI
            For DwI = 1 To NOpsDw
              Protected DwText.s = Trim(GetOperand(PL\ArgsText, DwI))
              Protected VDw.Z80Addr
              If EvalExpr(DwText, @VDw)
                If VDw\SegType = #Z80Seg_Absolute
                  RelW_WriteByteItem(VDw\Value & $FF)
                  RelW_WriteByteItem((VDw\Value >> 8) & $FF)
                Else
                  RelW_WriteValueItem(VDw\SegType, VDw\Value)
                EndIf
              Else
                Protected DwUnk.s = UCase(LastEvalUnknownSymbol)
                If DwUnk <> "" And BareExternKeyOf(DwText) = DwUnk And RelExternDeclared(DwUnk) <> ""
                  RelWriteExternalChainRef(DwUnk, RelExternDeclared(DwUnk), RelCurArea, DwLineStart + (DwI - 1) * 2, RelCurCommonName)
                ElseIf DwUnk <> "" And RelExternDeclared(DwUnk) <> ""
                  AsmErrorLine = LineNum : AsmErrorText = "Expressao externa composta nao suportada nesta fase (Fase B parcial): " + DwText
                  ProcedureReturn #False
                Else
                  AsmErrorLine = LineNum : AsmErrorText = PL\Operator + ": " + LastEvalError + LastEvalUnknownSymbol
                  ProcedureReturn #False
                EndIf
              EndIf
            Next
          EndIf
          RelAdvanceArea(RelCurArea, RelCurCommonName, NOpsDw * 2)
          CurLoc\Value = (CurLoc\Value + NOpsDw * 2) & $FFFF
          Continue
      EndSelect

      If Not IsMnemonic(PL\Operator)
        AsmErrorLine = LineNum
        AsmErrorText = "Diretiva/mnemonico nao suportado ainda nesta fase: " + PL\Operator
        ProcedureReturn #False
      EndIf

      ; Classifica o operando-cauda ANTES de chamar EncodeInstruction() -
      ; precisa saber JA se e uma referencia bare a externo pra poder definir
      ; um simbolo temporario (valor 0) e o encoder (compartilhado com o
      ; driver absoluto, nunca soube de EXTRN) conseguir avaliar a expressao
      ; sem erro - os bytes que ele produzir pra essa posicao sao descartados
      ; de qualquer forma (a emissao de verdade usa RelWriteExternalChainRef,
      ; nao Bytes()). Removido logo depois de EncodeInstruction pra nao
      ; contaminar a tabela de simbolos (ver comentario da secao acima).
      Protected TailText.s = RelFindTailOperandText(PL\Operator, PL\ArgsText)
      Protected TailIsReloc.b = #False
      Protected TailSeg2.b = #Z80Seg_Absolute, TailCommon2.s = ""
      Protected TailIsExtern2.b = #False, TailExternKey2.s = "", TailExternName2.s = ""
      If EmitMode And TailText <> ""
        Protected VTail.Z80Addr
        If EvalExpr(TailText, @VTail)
          If VTail\SegType <> #Z80Seg_Absolute
            TailIsReloc = #True : TailSeg2 = VTail\SegType : TailCommon2 = VTail\CommonName
          EndIf
        Else
          Protected TUnk.s = UCase(LastEvalUnknownSymbol)
          If TUnk <> "" And BareExternKeyOf(TailText) = TUnk And RelExternDeclared(TUnk) <> ""
            TailIsReloc = #True : TailIsExtern2 = #True
            TailExternKey2 = TUnk : TailExternName2 = RelExternDeclared(TUnk)
            DefineSymbolSeg(TUnk, 0, #Z80Seg_Absolute, "", #False)
          ElseIf TUnk <> "" And RelExternDeclared(TUnk) <> ""
            AsmErrorLine = LineNum : AsmErrorText = "Expressao externa composta nao suportada nesta fase (Fase B parcial): " + PL\ArgsText
            ProcedureReturn #False
          EndIf
        EndIf
      EndIf

      Protected InstrLineStart.u = RelAreaCounter(RelCurArea, RelCurCommonName)
      Len4 = EncodeInstruction(PL\Operator, PL\ArgsText, EmitMode, Bytes())

      If TailIsExtern2
        If FindMapElement(Symbols(), TailExternKey2)
          DeleteMapElement(Symbols())
        EndIf
      EndIf

      If Len4 < 0
        AsmErrorLine = LineNum : AsmErrorText = LastAsmError
        ProcedureReturn #False
      EndIf

      If EmitMode
        If TailIsReloc And Len4 >= 2
          For Idx = 0 To Len4 - 3
            RelW_WriteByteItem(Bytes(Idx))
          Next
          If TailIsExtern2
            RelWriteExternalChainRef(TailExternKey2, TailExternName2, RelCurArea, InstrLineStart + Len4 - 2, RelCurCommonName)
          Else
            RelW_WriteValueItem(TailSeg2, Bytes(Len4 - 2) | (Bytes(Len4 - 1) << 8))
          EndIf
        Else
          For Idx = 0 To Len4 - 1
            RelW_WriteByteItem(Bytes(Idx))
          Next
        EndIf
      EndIf

      RelAdvanceArea(RelCurArea, RelCurCommonName, Len4)
      CurLoc\Value = (CurLoc\Value + Len4) & $FFFF
    Next

    If EmitMode
      ForEach RelPublicOrder()
        Protected PubDisplay.s = RelPublicOrder()
        Protected PubKey.s = UCase(PubDisplay)
        If Not FindMapElement(Symbols(), PubKey) Or Not Symbols(PubKey)\IsKnown
          AsmErrorLine = LineNum
          AsmErrorText = "PUBLIC " + PubDisplay + ": simbolo nunca definido"
          ProcedureReturn #False
        EndIf
        Protected PubSeg.b = Symbols(PubKey)\Addr\SegType
        Protected PubVal.u = Symbols(PubKey)\Addr\Value
        Protected PubCommon.s = Symbols(PubKey)\Addr\CommonName
        If PubSeg = #Z80Seg_Common And PubCommon <> RelLastSelectedCommon
          RelW_WriteLinkItem(#Z80Rel_SelectCommonBlock, #False, 0, 0, #True, PubCommon)
          RelLastSelectedCommon = PubCommon
        EndIf
        RelW_WriteLinkItem(#Z80Rel_DefineEntryPoint, #True, PubSeg, PubVal, #True, PubDisplay)
      Next

      ForEach RelChainOrder()
        Protected ChKey.s = RelChainOrder()
        RelW_WriteLinkItem(#Z80Rel_ChainExternal, #True, RelChainState(ChKey)\LastPos\SegType, RelChainState(ChKey)\LastPos\Value, #True, RelChainState(ChKey)\DisplayName)
      Next

      RelW_WriteLinkItem(#Z80Rel_EndProgram, #True, RelEndAddrSeg, RelEndAddrVal)
      RelW_ForceByteBoundary()
      RelW_WriteLinkItem(#Z80Rel_EndFile)
    EndIf

    ProcedureReturn #True
  EndProcedure

  ; Pre-varredura barata (so ParseLine linha a linha, sem macro/condicional)
  ; pra decidir se um fonte precisa do driver relocavel (CSEG/DSEG/COMMON/
  ; PUBLIC/EXTRN/rotulo "::" de verdade em algum lugar) ou se o driver
  ; absoluto de Fase A (Assemble()) basta. Usada pelo chamador (editor/CLI)
  ; ANTES de decidir qual dos dois chamar - AssembleRelocatable() nao chama
  ; isso sozinho.
  Procedure.i NeedsRelocatable(SourceText.s)
    Protected NewList SLines.s()
    SplitSourceLines(SourceText, SLines())
    Protected PL2.Z80ParsedLine
    ForEach SLines()
      ParseLine(SLines(), @PL2)
      If PL2\LabelIsPublic
        ProcedureReturn #True
      EndIf
      If PL2\HasOperator
        Select UCase(PL2\Operator)
          Case "CSEG", "DSEG", "COMMON", "PUBLIC", "ENTRY", "GLOBAL", "EXTRN", "EXT", "EXTERNAL"
            ProcedureReturn #True
        EndSelect
      EndIf
      If FindString(PL2\ArgsText, "##")
        ProcedureReturn #True
      EndIf
    Next
    ProcedureReturn #False
  EndProcedure

  ; Monta em modo relocavel, gerando um .REL de verdade em OutBytes (formato
  ; estendido Nestor80, ver RelW_*/docs/reference/nestor80-rel-format.md).
  ; ProgramName vazio vira "NONAME" (o formato exige um nome - Nestor80 usa o
  ; nome do arquivo fonte; quem chama a partir do editor deve passar o nome
  ; da aba/arquivo quando existir). OutBytes precisa vir dimensionado bem
  ; grande pelo chamador (um .REL pode ser maior que o binario absoluto
  ; equivalente, por causa do overhead de item/cabecalho por instrucao
  ; relocavel - 65536*2 e uma margem confortavel pra qualquer fonte real).
  ; Devolve o numero de bytes ou -1 em erro (GetAssembleErrorLine()/
  ; GetAssembleErrorText(), MESMOS acessores de Assemble()).
  Procedure.i AssembleRelocatable(SourceText.s, ProgramName.s, Array OutBytes.a(1))
    Protected NewList Lines.s()
    Protected PName.s = ProgramName
    If PName = ""
      PName = "NONAME"
    EndIf

    ResetState()
    AsmErrorLine = 0 : AsmErrorText = ""
    ClearList(RelPublicOrder())
    ClearMap(RelPublicSeen())
    ClearMap(RelExternDeclared())
    ClearMap(RelCommonMaxSize())

    SplitSourceLines(SourceText, Lines())

    If Not RunOnePassRel(Lines(), #True, PName)
      ProcedureReturn -1
    EndIf

    Protected FinalCSEG.u = RelLocCSEG
    Protected FinalDSEG.u = RelLocDSEG
    ClearList(RelCommonMaxSizeFrozen())
    ForEach RelCommonMaxSize()
      AddElement(RelCommonMaxSizeFrozen())
      RelCommonMaxSizeFrozen()\Name = MapKey(RelCommonMaxSize())
      RelCommonMaxSizeFrozen()\Size = RelCommonMaxSize()
    Next

    If Not RunOnePassRel(Lines(), #False, PName, FinalCSEG, FinalDSEG)
      ProcedureReturn -1
    EndIf

    Protected N = RelW_GetByteCount()
    If N > 0
      RelW_GetBytes(OutBytes())
    EndIf
    ProcedureReturn N
  EndProcedure

  ;- ------------------------------------------------------------
  ;- Driver de 2 passes - so absoluto por enquanto (ORG define o contador de
  ;- localizacao; rotulo/EQU/DEFL/ASET; instrucoes de CPU via
  ;- EncodeInstruction; ASEG/CSEG/DSEG/COMMON/PUBLIC/EXTRN reconhecidas sem
  ;- efeito pleno - Fase B; DB/DW/DS/DC/DEFZ/condicionais/macros ainda nao -
  ;- proximas tarefas). Reprocessa o texto-fonte inteiro do zero em cada
  ;- pass (mesma estrategia do proprio Nestor80 - ver docs/resumo-asm.md),
  ;- entao nao precisa de lista de fixups: no pass 2 todo rotulo definido em
  ;- QUALQUER lugar do arquivo ja esta na tabela de simbolos.
  ;- ------------------------------------------------------------

  Global MinAddrTouched.i, MaxAddrTouched.i, AnyByteWritten.b

  Procedure.i GetAssembleErrorLine()
    ProcedureReturn AsmErrorLine
  EndProcedure

  Procedure.s GetAssembleErrorText()
    ProcedureReturn AsmErrorText
  EndProcedure

  Procedure.u GetAssembleStartAddr()
    ProcedureReturn MinAddrTouched & $FFFF
  EndProcedure

  Procedure.u GetAssembleEndAddr()
    ProcedureReturn MaxAddrTouched & $FFFF
  EndProcedure

  Procedure.i GetListingRowCount()
    ProcedureReturn ListSize(ZListingRows())
  EndProcedure

  Procedure GetListingRow(Index.i, *Out.Z80ListingRow)
    If Index < 0 Or Index >= ListSize(ZListingRows())
      ProcedureReturn
    EndIf
    SelectElement(ZListingRows(), Index)
    *Out\SourceLine = ZListingRows()\SourceLine
    *Out\HasAddr = ZListingRows()\HasAddr
    *Out\IsEqu = ZListingRows()\IsEqu
    *Out\Addr = ZListingRows()\Addr
    *Out\ByteCount = ZListingRows()\ByteCount
    *Out\Byte0 = ZListingRows()\Byte0
    *Out\Byte1 = ZListingRows()\Byte1
    *Out\Byte2 = ZListingRows()\Byte2
    *Out\Byte3 = ZListingRows()\Byte3
  EndProcedure

  Procedure SplitSourceLines(SourceText.s, List Lines.s())
    ClearList(Lines())
    Protected Norm.s = ReplaceString(SourceText, Chr(13) + Chr(10), Chr(10))
    Norm = ReplaceString(Norm, Chr(13), Chr(10))
    Protected N = CountString(Norm, Chr(10)) + 1
    Protected Idx
    For Idx = 1 To N
      AddElement(Lines())
      Lines() = StringField(Norm, Idx, Chr(10))
    Next
  EndProcedure

  ;- ------------------------------------------------------------
  ;- Diretivas de dados (DB/DEFB/DEFM, DW/DEFW, DS/DEFS, DC, DZ/DEFZ) - ver
  ;- docs/reference/nestor80-language.md. Precisam vir ANTES de RunOnePass
  ;- (mesma regra de forward-reference dentro de um Module).
  ;- ------------------------------------------------------------

  ; Um operando de DB/DC/DZ: string entre aspas (qualquer tamanho, aspa
  ; dobrada = aspa literal, mesma regra de TokenizeExpr) vira bytes crus dos
  ; caracteres; senao e uma expressao numerica de 1 byte (& $FF). Bytes
  ; ficam sempre conhecidos em quantidade mesmo no pass 1 (uma expressao
  ; numerica sempre gera exatamente 1 byte, independente do valor - so o
  ; VALOR muda entre passes, nunca a contagem).
  Procedure.b ExpandDataOperand(Text.s, EmitMode.b, List OutBytes.a())
    Protected T.s = RTrimWs(Mid(Text, SkipWs(Text, 1)))
    Protected V.Z80Addr
    Protected Idx

    If Len(T) >= 2 And (Left(T, 1) = Chr(34) Or Left(T, 1) = "'") And Right(T, 1) = Left(T, 1)
      Protected Delim.s = Left(T, 1)
      Protected Body.s = Mid(T, 2, Len(T) - 2)
      Body = ReplaceString(Body, Delim + Delim, Delim)
      For Idx = 1 To Len(Body)
        AddElement(OutBytes())
        OutBytes() = Asc(Mid(Body, Idx, 1)) & $FF
      Next
      ProcedureReturn #True
    EndIf

    If Not EvalOperandExpr(T, EmitMode, @V)
      ProcedureReturn #False
    EndIf
    ; Um operando de 1 byte (DB/DC/DZ/preenchimento de DS) precisa resolver
    ; absoluto - truncar um endereco relocavel pra 1 byte exigiria o item de
    ; extensao RPN "StoreAsByte" do Nestor80 (ex. HIGH/LOW de um simbolo
    ; CSEG/DSEG), fora de escopo nesta fase (ver docs/resumo-asm.md) - erro
    ; explicito em vez de truncar silenciosamente um valor que so o linker
    ; conhece de verdade. So dispara com EmitMode (pass 2 - so quando o
    ; SegType real ja esta disponivel; no pass 1 EvalOperandExpr sempre
    ; devolve absoluto por construcao, ver comentario acima).
    If EmitMode And V\SegType <> #Z80Seg_Absolute
      LastAsmError = "Valor relocavel truncado pra 1 byte nao suportado nesta fase (Fase B parcial): " + T
      ProcedureReturn #False
    EndIf
    AddElement(OutBytes())
    OutBytes() = V\Value & $FF
    ProcedureReturn #True
  EndProcedure

  ; Devolve #True/#False (erro, ver LastAsmError). OutBytes (List, cresce
  ; livre - nenhuma diretiva de dados tem tamanho maximo fixo, diferente de
  ; instrucao de CPU) recebe os bytes gerados. Em pass 1 (EmitMode=#False)
  ; a CONTAGEM de bytes ja sai certa sem avaliar valor nenhum (ExpandDataOperand/
  ; EvalOperandExpr ja garantem isso) - excecao: o TAMANHO de DS precisa ser
  ; conhecido de verdade ja no pass 1 (LR:1959, nao pode depender de rotulo
  ; definido so depois - por isso usa EvalExpr direto, nao EvalOperandExpr).
  Procedure.b EncodeDataDirective(Op.s, ArgsText.s, EmitMode.b, List OutBytes.a())
    ClearList(OutBytes())
    Protected NOps = CountOperands(ArgsText)
    Protected Idx

    Select Op
      Case "DB", "DEFB", "DEFM"
        If NOps = 0
          LastAsmError = Op + ": precisa de pelo menos um operando"
          ProcedureReturn #False
        EndIf
        For Idx = 1 To NOps
          If Not ExpandDataOperand(GetOperand(ArgsText, Idx), EmitMode, OutBytes())
            ProcedureReturn #False
          EndIf
        Next
        ProcedureReturn #True

      Case "DZ", "DEFZ"
        If NOps = 0
          LastAsmError = Op + ": precisa de pelo menos um operando"
          ProcedureReturn #False
        EndIf
        For Idx = 1 To NOps
          If Not ExpandDataOperand(GetOperand(ArgsText, Idx), EmitMode, OutBytes())
            ProcedureReturn #False
          EndIf
        Next
        AddElement(OutBytes())
        OutBytes() = 0
        ProcedureReturn #True

      Case "DC"
        If NOps = 0
          LastAsmError = "DC: precisa de pelo menos um operando"
          ProcedureReturn #False
        EndIf
        For Idx = 1 To NOps
          If Not ExpandDataOperand(GetOperand(ArgsText, Idx), EmitMode, OutBytes())
            ProcedureReturn #False
          EndIf
        Next
        If EmitMode And ListSize(OutBytes()) > 0
          LastElement(OutBytes())
          OutBytes() = OutBytes() | $80
        EndIf
        ProcedureReturn #True

      Case "DW", "DEFW"
        If NOps = 0
          LastAsmError = Op + ": precisa de pelo menos um operando"
          ProcedureReturn #False
        EndIf
        Protected VW.Z80Addr
        For Idx = 1 To NOps
          If Not EvalOperandExpr(GetOperand(ArgsText, Idx), EmitMode, @VW)
            ProcedureReturn #False
          EndIf
          AddElement(OutBytes()) : OutBytes() = VW\Value & $FF
          AddElement(OutBytes()) : OutBytes() = (VW\Value >> 8) & $FF
        Next
        ProcedureReturn #True

      Case "DS", "DEFS"
        If NOps < 1 Or NOps > 2
          LastAsmError = "DS: precisa de 1 ou 2 operandos (tamanho[,valor])"
          ProcedureReturn #False
        EndIf
        Protected SizeV.Z80Addr
        If Not EvalExpr(GetOperand(ArgsText, 1), @SizeV)
          LastAsmError = "DS: tamanho precisa ser conhecido ja no pass 1 (nao pode depender de rotulo definido so depois): " + LastEvalError + LastEvalUnknownSymbol
          ProcedureReturn #False
        EndIf
        Protected FillV.u = 0
        If NOps = 2
          Protected FillAddr.Z80Addr
          If Not EvalOperandExpr(GetOperand(ArgsText, 2), EmitMode, @FillAddr)
            ProcedureReturn #False
          EndIf
          FillV = FillAddr\Value & $FF
        EndIf
        Protected DsIdx
        For DsIdx = 1 To SizeV\Value
          AddElement(OutBytes()) : OutBytes() = FillV
        Next
        ProcedureReturn #True
    EndSelect

    LastAsmError = "Diretiva de dados desconhecida: " + Op
    ProcedureReturn #False
  EndProcedure

  ;- ------------------------------------------------------------
  ;- Condicionais (IF/IFT/IFE/IFF/IFDEF/IFNDEF/IF1/IF2/ELSE/ENDIF) e macros
  ;- basicas (MACRO/ENDM/EXITM/LOCAL) - ver docs/reference/nestor80-language.md.
  ;- ExpandLines() roda uma vez no INICIO de cada pass (RunOnePass chama,
  ;- ve abaixo) e devolve uma lista "achatada" sem IF/MACRO/ENDM nenhum -
  ;- so linhas de verdade pra montar. Rodar isso a cada pass (nao uma vez so
  ;- pro Assemble() inteiro) e o que permite IF1/IF2 enxergarem o pass certo.
  ;- REPT/IRP/IRPC/MODULE/labels locais ficam pra depois (Fase C, ver
  ;- docs/resumo-asm.md).
  ;- ------------------------------------------------------------

  ; Troca toda ocorrencia de Word (case-insensitive, respeitando fronteira de
  ; identificador - nao troca dentro de "FOOBAR" procurando "FOO") por
  ; Replacement, em Text inteiro (pode ter varias linhas). Usado tanto pra
  ; substituicao de parametro de macro quanto pra renomeacao de simbolo LOCAL.
  Procedure.s SubstituteWord(Text.s, Word.s, Replacement.s)
    If Word = ""
      ProcedureReturn Text
    EndIf
    Protected Result.s = ""
    Protected L = Len(Text), I = 1, C.s
    Protected WU.s = UCase(Word)
    Protected Start, Tok.s

    While I <= L
      C = Mid(Text, I, 1)
      If ChIsIdentStart(C)
        Start = I
        I + 1
        While I <= L And ChIsIdentCont(Mid(Text, I, 1))
          I + 1
        Wend
        Tok = Mid(Text, Start, I - Start)
        If UCase(Tok) = WU
          Result + Replacement
        Else
          Result + Tok
        EndIf
        Continue
      EndIf
      Result + C
      I + 1
    Wend
    ProcedureReturn Result
  EndProcedure

  Declare.b ExpandLines(List InLines.s(), List OutLines.s(), SizeOnly.b, Depth.i)

  #Z80Asm_MaxMacroDepth = 16

  Procedure.b ExpandLines(List InLines.s(), List OutLines.s(), SizeOnly.b, Depth.i)
    ClearList(OutLines())

    If Depth > #Z80Asm_MaxMacroDepth
      LastAsmError = "Macros aninhadas demais (limite " + Str(#Z80Asm_MaxMacroDepth) + ") - possivel recursao infinita"
      ProcedureReturn #False
    EndIf

    If Depth = 0
      ; chamada de fora (nao recursiva de corpo de macro) - reconstroi a
      ; tabela de macros e reseta o contador de LOCAL do zero, pra pass 1 e
      ; pass 2 produzirem exatamente a mesma sequencia de sufixos (mesma
      ; ordem de expansao, mesmo texto-fonte).
      ClearMap(Macros())
      MacroExpansionCounter = 0
    EndIf

    Protected NewList CondStack.b()  ; um nivel por IF ativo - #True = condicao bateu nesse nivel

    Protected DefiningMacro.b = #False
    Protected DefMacroName.s, DefMacroParams.s, DefMacroBody.s
    Protected DefMacroDepth.i = 0

    ForEach InLines()
      Protected RawLine.s = InLines()
      Protected PLx.Z80ParsedLine
      ParseLine(RawLine, @PLx)

      ; --- capturando o corpo de uma definicao MACRO...ENDM ---
      If DefiningMacro
        If PLx\HasOperator And PLx\Operator = "MACRO"
          DefMacroDepth + 1
        ElseIf PLx\HasOperator And PLx\Operator = "ENDM"
          If DefMacroDepth > 0
            DefMacroDepth - 1
          Else
            If Not FindMapElement(Macros(), DefMacroName)
              AddMapElement(Macros(), DefMacroName)
            EndIf
            Macros()\ParamNames = DefMacroParams
            Macros()\BodyText = DefMacroBody
            DefiningMacro = #False
            Continue
          EndIf
        EndIf
        DefMacroBody + RawLine + Chr(10)
        Continue
      EndIf

      Protected Skipping.b = #False
      ForEach CondStack()
        If Not CondStack()
          Skipping = #True
          Break
        EndIf
      Next

      ; EQU/DEFL/ASET precisam ser resolvidos AQUI TAMBEM (nao so na passada
      ; principal em RunOnePass, que so acontece DEPOIS que ExpandLines()
      ; termina) - senao "FLAG equ 1" seguido de "if FLAG" no mesmo arquivo
      ; nunca veria o simbolo pronto a tempo. Rotulo (posicao = contador de
      ; localizacao) fica de fora de proposito - ExpandLines nao rastreia
      ; tamanho de instrucao/endereco, so RunOnePass faz isso; um `IF` que
      ; dependa do VALOR de um rotulo (nao de uma EQU) e uma lacuna conhecida
      ; e aceita nesta fase (baixa prioridade, padrao raro). DefineSymbol()
      ; e seguro de chamar de novo aqui e mais uma vez em RunOnePass (mesma
      ; ideia ja usada pra permitir EQU "repetido" entre pass 1 e pass 2).
      If Not Skipping And PLx\HasOperator And PLx\HasLabel And Not PLx\LabelHasColon
        Select PLx\Operator
          Case "EQU"
            Protected EqV.Z80Addr
            If EvalExpr(PLx\ArgsText, @EqV)
              DefineSymbol(PLx\Label, EqV\Value, #True)
            EndIf
          Case "DEFL", "ASET"
            Protected DlV.Z80Addr
            If EvalExpr(PLx\ArgsText, @DlV)
              Protected DlKey.s = UCase(PLx\Label)
              If Not FindMapElement(Symbols(), DlKey)
                AddMapElement(Symbols(), DlKey)
              EndIf
              Z80Addr_Make(@Symbols()\Addr, DlV\Value, #Z80Seg_Absolute)
              Symbols()\IsKnown = #True
              Symbols()\IsConstant = #False
            EndIf
        EndSelect
      EndIf

      If PLx\HasOperator
        Select PLx\Operator
          Case "IF", "IFT"
            Protected CV1.Z80Addr, C1.b = #False
            If Not Skipping
              If Not EvalExpr(PLx\ArgsText, @CV1)
                LastAsmError = "IF: " + LastEvalError + LastEvalUnknownSymbol
                ProcedureReturn #False
              EndIf
              C1 = Bool(CV1\Value <> 0)
            EndIf
            AddElement(CondStack()) : CondStack() = C1
            Continue

          Case "IFE", "IFF"
            Protected CV2.Z80Addr, C2.b = #False
            If Not Skipping
              If Not EvalExpr(PLx\ArgsText, @CV2)
                LastAsmError = "IFE/IFF: " + LastEvalError + LastEvalUnknownSymbol
                ProcedureReturn #False
              EndIf
              C2 = Bool(CV2\Value = 0)
            EndIf
            AddElement(CondStack()) : CondStack() = C2
            Continue

          Case "IFDEF"
            AddElement(CondStack()) : CondStack() = IsSymbolKnown(RTrimWs(Mid(PLx\ArgsText, SkipWs(PLx\ArgsText, 1))))
            Continue

          Case "IFNDEF"
            AddElement(CondStack()) : CondStack() = Bool(Not IsSymbolKnown(RTrimWs(Mid(PLx\ArgsText, SkipWs(PLx\ArgsText, 1)))))
            Continue

          Case "IF1"
            AddElement(CondStack()) : CondStack() = SizeOnly
            Continue

          Case "IF2"
            AddElement(CondStack()) : CondStack() = Bool(Not SizeOnly)
            Continue

          Case "ELSE"
            If ListSize(CondStack()) = 0
              LastAsmError = "ELSE sem IF correspondente"
              ProcedureReturn #False
            EndIf
            LastElement(CondStack())
            CondStack() = Bool(Not CondStack())
            Continue

          Case "ENDIF"
            If ListSize(CondStack()) = 0
              LastAsmError = "ENDIF sem IF correspondente"
              ProcedureReturn #False
            EndIf
            LastElement(CondStack())
            DeleteElement(CondStack())
            Continue

          Case "EXITM"
            If Skipping
              Continue
            EndIf
            Break

          Case "LOCAL"
            ; so faz sentido dentro do corpo de uma macro (chamado de dentro
            ; de uma recursao de ExpandLines) - fora disso, so ignora.
            Continue

          Case "MACRO"
            If Skipping
              Continue
            EndIf
            ; nome da macro vem em posicao de rotulo ("nome MACRO p1,p2" ou
            ; "nome: MACRO p1,p2" - ":" opcional, LR:883-923) - ParseLine ja
            ; resolve os dois jeitos (lookahead EQU/DEFL/ASET/MACRO ou rotulo
            ; classico), entao aqui e so ler PLx\Label.
            If Not PLx\HasLabel
              LastAsmError = "MACRO precisa de um nome antes: nome MACRO param1,param2"
              ProcedureReturn #False
            EndIf
            DefMacroName = UCase(PLx\Label)
            DefMacroParams = ReplaceString(PLx\ArgsText, ",", " ")
            DefMacroBody = ""
            DefMacroDepth = 0
            DefiningMacro = #True
            Continue
        EndSelect

        If Not Skipping And FindMapElement(Macros(), UCase(PLx\Operator))
          Protected ParamNames.s = Macros()\ParamNames
          Protected Body.s = Macros()\BodyText
          Protected NParams = 0
          If RTrimWs(Mid(ParamNames, SkipWs(ParamNames, 1))) <> ""
            NParams = CountString(Trim(ParamNames), " ") + 1
          EndIf

          MacroExpansionCounter + 1
          Protected Suffix.s = "__m" + Str(MacroExpansionCounter)

          ; LOCAL <nomes> - primeiro renomeia (sufixo unico desta expansao)
          ; todos os simbolos declarados, pra nao colidir entre invocacoes
          ; diferentes da mesma macro.
          Protected NewList BodyPreLines.s()
          SplitSourceLines(Body, BodyPreLines())
          ForEach BodyPreLines()
            Protected PLl.Z80ParsedLine
            ParseLine(BodyPreLines(), @PLl)
            If PLl\HasOperator And PLl\Operator = "LOCAL"
              Protected LNames.s = ReplaceString(PLl\ArgsText, ",", " ")
              Protected LCount = CountString(Trim(LNames), " ") + 1
              Protected LIdx
              For LIdx = 1 To LCount
                Protected LName.s = Trim(StringField(LNames, LIdx, " "))
                If LName <> ""
                  Body = SubstituteWord(Body, LName, LName + Suffix)
                EndIf
              Next
            EndIf
          Next

          Protected PIdx
          For PIdx = 1 To NParams
            Protected PName.s = UCase(StringField(Trim(ParamNames), PIdx, " "))
            Protected PVal.s = GetOperand(PLx\ArgsText, PIdx)
            Body = SubstituteWord(Body, PName, PVal)
          Next

          Protected NewList MacroLines.s()
          SplitSourceLines(Body, MacroLines())
          Protected NewList MacroOut.s()
          If Not ExpandLines(MacroLines(), MacroOut(), SizeOnly, Depth + 1)
            ProcedureReturn #False
          EndIf
          ForEach MacroOut()
            AddElement(OutLines())
            OutLines() = MacroOut()
          Next
          Continue
        EndIf
      EndIf

      If Skipping
        Continue
      EndIf

      AddElement(OutLines())
      OutLines() = RawLine
    Next

    ProcedureReturn #True
  EndProcedure

  Procedure.b RunOnePass(List Lines.s(), SizeOnly.b, Array Mem.a(1))
    Protected LineNum = 0
    Protected PL.Z80ParsedLine
    Protected Dim Bytes.a(3)
    Protected Len4.i, Idx
    Protected Ended.b = #False
    Protected V1.Z80Addr, V2.Z80Addr, V3.Z80Addr
    Protected EmitNow.b
    EmitNow = Bool(Not SizeOnly)
    ; PassNumber (Global, ver comentario na declaracao) finalmente usado de
    ; verdade - EvalPostfixExpr() checa isso pra so' gravar referencia
    ; cruzada de simbolo (SymbolRefs()) durante o pass de EMISSAO.
    If SizeOnly
      PassNumber = 1
    Else
      PassNumber = 2
    EndIf
    ; Lista reaproveitada pra alimentar ZListing_AddRow() no caso de
    ; instrucao de CPU (Bytes() acima e' um Array de tamanho fixo, nao um
    ; List) - declarada UMA vez aqui fora (nao dentro do loop) e limpa
    ; explicitamente antes de cada uso, mesmo cuidado que EncodeDataDirective()
    ; ja' toma sozinho pra DataBytes() (ClearList() como 1a acao) - um
    ; NewList sozinho, sem ClearList, NAO reseta nada entre passagens pela
    ; mesma linha de codigo num loop.
    NewList InstrBytesForListing.a()

    Z80Addr_Make(@CurLoc, 0, #Z80Seg_Absolute)
    RealPos = 0
    PhaseActive = #False

    Protected NewList ExpLines.s()
    If Not ExpandLines(Lines(), ExpLines(), SizeOnly, 0)
      AsmErrorLine = LineNum : AsmErrorText = LastAsmError
      ProcedureReturn #False
    EndIf

    ForEach ExpLines()
      If Ended
        Break
      EndIf
      LineNum + 1

      ParseLine(ExpLines(), @PL)

      If PL\IsBlank
        Continue
      EndIf

      ; Mesmo achado/correcao do RunOnePassRel acima (ver comentario la') -
      ; label de dois-pontos + EQU/DEFL/ASET nao pode definir o simbolo
      ; POSICIONALMENTE aqui, so' pelo Select abaixo (valor certo da
      ; expressao) - senao colide consigo mesmo no pass 2.
      If PL\HasLabel And PL\LabelHasColon And Not (PL\HasOperator And (PL\Operator = "EQU" Or PL\Operator = "DEFL" Or PL\Operator = "ASET"))
        If Not DefineSymbol(PL\Label, CurLoc\Value, #False)
          AsmErrorLine = LineNum : AsmErrorText = LastEvalError
          ProcedureReturn #False
        EndIf
      EndIf

      If Not PL\HasOperator
        Continue
      EndIf

      Select PL\Operator
        Case "EQU"
          If EvalExpr(PL\ArgsText, @V1)
            If Not DefineSymbol(PL\Label, V1\Value, #True)
              AsmErrorLine = LineNum : AsmErrorText = LastEvalError
              ProcedureReturn #False
            EndIf
            If Not SizeOnly
              NewList EmptyBytesEqu.a()
              ZListing_AddRow(LineNum, #True, V1\Value, EmptyBytesEqu())
            EndIf
          ElseIf Not SizeOnly
            AsmErrorLine = LineNum : AsmErrorText = "EQU: " + LastEvalError + LastEvalUnknownSymbol
            ProcedureReturn #False
          EndIf
          Continue

        Case "DEFL", "ASET"
          If EvalExpr(PL\ArgsText, @V2)
            Protected Key2.s = UCase(PL\Label)
            If Not FindMapElement(Symbols(), Key2)
              AddMapElement(Symbols(), Key2)
            EndIf
            Z80Addr_Make(@Symbols()\Addr, V2\Value, #Z80Seg_Absolute)
            Symbols()\IsKnown = #True
            Symbols()\IsConstant = #False
            If Not SizeOnly
              NewList EmptyBytesDefl.a()
              ZListing_AddRow(LineNum, #True, V2\Value, EmptyBytesDefl())
            EndIf
          ElseIf Not SizeOnly
            AsmErrorLine = LineNum : AsmErrorText = "DEFL/ASET: " + LastEvalError + LastEvalUnknownSymbol
            ProcedureReturn #False
          EndIf
          Continue

        Case "ORG"
          If EvalExpr(PL\ArgsText, @V3)
            CurLoc\Value = V3\Value
            RealPos = V3\Value ; ORG dentro de um bloco .PHASE nao e suportado (restricao tambem
                                ; existente no Nestor80 pra ASEG/CSEG/etc dentro de .PHASE) - fora
                                ; de um bloco, mantem CurLoc/RealPos sincronizados como sempre
          ElseIf Not SizeOnly
            AsmErrorLine = LineNum : AsmErrorText = "ORG: " + LastEvalError + LastEvalUnknownSymbol
            ProcedureReturn #False
          EndIf
          Continue

        Case "END"
          Ended = #True
          Continue

        Case ".PHASE", "PHASE"
          ; Contador de localizacao "reportado" ($/rotulos/JR) passa a mostrar
          ; o endereco pedido, mas a escrita real continua de onde estava
          ; (RealPos intocado) - ver docs/reference/nestor80-language.md e
          ; MACRO-80.txt secao 2.6.29 "Relocation Before Loading". O valor
          ; precisa ser conhecido JA (nao pode depender de rotulo definido
          ; so depois - mesma restricao de DS, documentada no Nestor80).
          Protected VPhase.Z80Addr
          If EvalExpr(PL\ArgsText, @VPhase)
            CurLoc\Value = VPhase\Value
            PhaseActive = #True
          ElseIf Not SizeOnly
            AsmErrorLine = LineNum : AsmErrorText = ".PHASE: " + LastEvalError + LastEvalUnknownSymbol
            ProcedureReturn #False
          EndIf
          Continue

        Case ".DEPHASE", "DEPHASE"
          ; CurLoc volta a bater com RealPos (equivalente a "nunca ter saido
          ; do endereco real") - ver comentario da Structure no topo do
          ; modulo pra explicacao completa do mecanismo.
          CurLoc\Value = RealPos
          PhaseActive = #False
          Continue

        Case "ASEG", "CSEG", "DSEG", "COMMON", "PUBLIC", "EXTRN", "EXT", "EXTERNAL", "ENTRY", "GLOBAL"
          Continue

        Case "DB", "DEFB", "DEFM", "DW", "DEFW", "DS", "DEFS", "DC", "DZ", "DEFZ"
          NewList DataBytes.a()
          If Not EncodeDataDirective(PL\Operator, PL\ArgsText, EmitNow, DataBytes())
            AsmErrorLine = LineNum : AsmErrorText = LastAsmError
            ProcedureReturn #False
          EndIf
          If Not SizeOnly
            Protected DIdx = 0
            Protected DA.i
            ForEach DataBytes()
              DA = (RealPos + DIdx) & $FFFF
              Mem(DA) = DataBytes()
              If Not AnyByteWritten
                MinAddrTouched = DA : MaxAddrTouched = DA : AnyByteWritten = #True
              Else
                If DA < MinAddrTouched : MinAddrTouched = DA : EndIf
                If DA > MaxAddrTouched : MaxAddrTouched = DA : EndIf
              EndIf
              DIdx + 1
            Next
            ZListing_AddRow(LineNum, #False, RealPos, DataBytes())
          EndIf
          CurLoc\Value = (CurLoc\Value + ListSize(DataBytes())) & $FFFF
          RealPos = (RealPos + ListSize(DataBytes())) & $FFFF
          Continue
      EndSelect

      If Not IsMnemonic(PL\Operator)
        AsmErrorLine = LineNum
        AsmErrorText = "Diretiva/mnemonico nao suportado ainda nesta fase: " + PL\Operator
        ProcedureReturn #False
      EndIf

      Len4 = EncodeInstruction(PL\Operator, PL\ArgsText, EmitNow, Bytes())
      If Len4 < 0
        AsmErrorLine = LineNum : AsmErrorText = LastAsmError
        ProcedureReturn #False
      EndIf

      If Not SizeOnly
        For Idx = 0 To Len4 - 1
          Protected A.i = (RealPos + Idx) & $FFFF
          Mem(A) = Bytes(Idx)
          If Not AnyByteWritten
            MinAddrTouched = A : MaxAddrTouched = A : AnyByteWritten = #True
          Else
            If A < MinAddrTouched : MinAddrTouched = A : EndIf
            If A > MaxAddrTouched : MaxAddrTouched = A : EndIf
          EndIf
        Next
        ClearList(InstrBytesForListing())
        For Idx = 0 To Len4 - 1
          AddElement(InstrBytesForListing())
          InstrBytesForListing() = Bytes(Idx)
        Next
        ZListing_AddRow(LineNum, #False, RealPos, InstrBytesForListing())
      EndIf

      CurLoc\Value = (CurLoc\Value + Len4) & $FFFF
      RealPos = (RealPos + Len4) & $FFFF
    Next

    ProcedureReturn #True
  EndProcedure

  Procedure.i Assemble(SourceText.s, Array OutBytes.a(1))
    NewList Lines.s()
    Protected Dim Mem.a(65535)
    Protected Idx

    ResetState()
    AsmErrorLine = 0 : AsmErrorText = ""
    MinAddrTouched = 0 : MaxAddrTouched = 0 : AnyByteWritten = #False
    ClearList(ZListingRows())
    ClearList(SymbolRefs())
    ClearList(SymbolDefOrder())

    SplitSourceLines(SourceText, Lines())

    If Not RunOnePass(Lines(), #True, Mem())
      ProcedureReturn -1
    EndIf

    If Not RunOnePass(Lines(), #False, Mem())
      ProcedureReturn -1
    EndIf

    XrefBuildRows()

    If Not AnyByteWritten
      ProcedureReturn 0
    EndIf

    Protected N = MaxAddrTouched - MinAddrTouched + 1
    For Idx = 0 To N - 1
      OutBytes(Idx) = Mem(MinAddrTouched + Idx)
    Next
    ProcedureReturn N
  EndProcedure

EndModule
