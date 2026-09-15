;
; ------------------------------------------------------------
;  Criar -> Alfabeto...: editor de charset MSX (bitmaps 8x8, 256 caracteres)
;  no formato de arquivo .ALF do Graphos III - um binario MSX classico
;  (cabecalho de 7 bytes: byte de tipo &HFE + enderecos inicial/final/
;  execucao, 2 bytes cada, little-endian) contendo 2048 bytes de dados: 256
;  caracteres, 8 bytes cada (um bitmap 8x8, bit 7 = pixel mais a esquerda),
;  carregado originalmente no endereco de VRAM &H9200 (Pattern Generator
;  Table).
;
;  Tabela de 256 caracteres (16 colunas x 16 linhas, indice = linha*16+col -
;  o layout ja corresponde ao codigo hexadecimal: cabecalho de linha = byte
;  alto, cabecalho de coluna = nibble baixo) com miniatura de cada glifo;
;  clicar num caractere carrega o bitmap na grade grande a direita, onde o
;  usuario liga/apaga pixels a mao; o botao "Registrar" e que de fato grava
;  os bytes editados de volta no alfabeto (e atualiza a miniatura na
;  tabela) - editar sem registrar nao muda o alfabeto em memoria.
; ------------------------------------------------------------
;

#CharEd_TableCellPx  = 18
#CharEd_TableHeaderW = 22
#CharEd_TableHeaderH = 18
#CharEd_TableCanvasW = #CharEd_TableHeaderW + 16 * #CharEd_TableCellPx
#CharEd_TableCanvasH = #CharEd_TableHeaderH + 16 * #CharEd_TableCellPx

#CharEd_EditPixelPx    = 30
#CharEd_EditCanvasSize = 8 * #CharEd_EditPixelPx

#CharEd_AlfDataSize    = 2048   ; 256 caracteres x 8 bytes
#CharEd_AlfHeaderSize  = 7      ; ID (1) + inicio/fim/execucao (2 bytes cada, little-endian)
#CharEd_AlfLoadAddress = $9200  ; endereco de VRAM da Pattern Generator Table no Graphos III
#CharEd_AlfID          = $FE    ; byte de tipo dos binarios MSX (CSAVE"...",CSAVE"...",B / BLOAD)

#CharEd_FilePattern = "Alfabeto Graphos III (*.alf)|*.alf|Todos os arquivos (*.*)|*.*"

; Desfazer/Refazer: pilha de instantaneos do alfabeto INTEIRO (256x8 = 2048
; bytes, barato de copiar). So acoes que gravam de fato em CharsetBytes()
; empilham um instantaneo (Registrar, efeitos em bloco/Tudo com Inverter/
; Espelhar/Girar/Apagar, Colar bloco, Colar alfabeto) - pixels editados mas
; ainda nao registrados (EditGrid) nao entram na pilha, mesmo espirito de
; "editar sem registrar nao muda o alfabeto em memoria" do resto do editor.
; A pilha e zerada ao trocar de alfabeto (navegacao/Novo/Carregar), pois um
; instantaneo de outro alfabeto nao faz sentido pra desfazer o atual.
#CharEd_MaxUndo = 50

Structure CharEd_AlphaSnapshot
  Bytes.a[2048]
EndStructure

; Efeitos que respeitam o bloco marcado (ver CharEd_ApplyGridEffectToRange) -
; sem bloco, afetam so o EditGrid do caractere atual (precisa de "Registrar").
#CharEd_Effect_Clear    = 0
#CharEd_Effect_Invert   = 1
#CharEd_Effect_FlipH    = 2
#CharEd_Effect_FlipV    = 3
#CharEd_Effect_Rotate90 = 4
#CharEd_Effect_Narrow   = 5
#CharEd_Effect_Italic   = 6
#CharEd_Effect_Bold     = 7
#CharEd_Effect_Wide     = 8
#CharEd_Effect_BoldLeft = 9
#CharEd_Effect_BoldRight = 10
#CharEd_Effect_WideBold  = 11

Global CharEd_LastError.s = ""

Procedure.s CharEd_GetLastError()
  ProcedureReturn CharEd_LastError
EndProcedure

; Le um .alf no formato binario do Graphos III (ver cabecalho do arquivo).
; Valida o byte de tipo (&HFE) e o tamanho minimo antes de aceitar os dados -
; um cabecalho invalido provavelmente significa que o arquivo nao e um
; alfabeto de verdade, entao preferimos falhar a carregar lixo silenciosamente.
Procedure.b CharEd_LoadAlf(Path.s, Array CharsetBytes.a(2))
  Protected FileNum = ReadFile(#PB_Any, Path)
  If Not FileNum
    CharEd_LastError = "Nao foi possivel abrir o arquivo: " + Path
    ProcedureReturn #False
  EndIf

  Protected TotalSize = #CharEd_AlfHeaderSize + #CharEd_AlfDataSize
  Protected FileLen = Lof(FileNum)
  If FileLen < TotalSize
    CloseFile(FileNum)
    CharEd_LastError = "Arquivo pequeno demais pra ser um alfabeto Graphos III valido (" +
                        Str(FileLen) + " bytes, esperado pelo menos " + Str(TotalSize) + ")."
    ProcedureReturn #False
  EndIf

  Protected *Buffer = AllocateMemory(TotalSize)
  ReadData(FileNum, *Buffer, TotalSize)
  CloseFile(FileNum)

  Protected ID.a = PeekA(*Buffer)
  If ID <> #CharEd_AlfID
    FreeMemory(*Buffer)
    CharEd_LastError = "Tipo de arquivo invalido: byte inicial e &H" + RSet(Hex(ID), 2, "0") +
                        " (esperado &H" + RSet(Hex(#CharEd_AlfID), 2, "0") + ", binario MSX)."
    ProcedureReturn #False
  EndIf

  Protected Row, Col
  For Row = 0 To 255
    For Col = 0 To 7
      CharsetBytes(Row, Col) = PeekA(*Buffer + #CharEd_AlfHeaderSize + Row * 8 + Col)
    Next
  Next
  FreeMemory(*Buffer)
  CharEd_LastError = ""
  ProcedureReturn #True
EndProcedure

; Grava um .alf no formato binario do Graphos III: ID &HFE, endereco inicial
; &H9200, endereco final = inicio + tamanho - 1 (endereco do ULTIMO byte,
; inclusive - convencao padrao dos binarios MSX, confirmada contra o
; cabecalho de um .alf real do Graphos III), execucao = inicio, seguido dos
; 2048 bytes de dados (256 caracteres x 8 bytes).
Procedure.b CharEd_SaveAlf(Path.s, Array CharsetBytes.a(2))
  Protected FileNum = CreateFile(#PB_Any, Path)
  If Not FileNum
    CharEd_LastError = "Nao foi possivel criar o arquivo: " + Path
    ProcedureReturn #False
  EndIf

  Protected TotalSize = #CharEd_AlfHeaderSize + #CharEd_AlfDataSize
  Protected *Buffer = AllocateMemory(TotalSize)

  Protected StartAddr.u = #CharEd_AlfLoadAddress
  Protected EndAddr.u   = #CharEd_AlfLoadAddress + #CharEd_AlfDataSize - 1
  Protected ExecAddr.u  = #CharEd_AlfLoadAddress

  PokeA(*Buffer + 0, #CharEd_AlfID)
  PokeA(*Buffer + 1, StartAddr & $FF) : PokeA(*Buffer + 2, (StartAddr >> 8) & $FF)
  PokeA(*Buffer + 3, EndAddr & $FF)   : PokeA(*Buffer + 4, (EndAddr >> 8) & $FF)
  PokeA(*Buffer + 5, ExecAddr & $FF)  : PokeA(*Buffer + 6, (ExecAddr >> 8) & $FF)

  Protected Row, Col
  For Row = 0 To 255
    For Col = 0 To 7
      PokeA(*Buffer + #CharEd_AlfHeaderSize + Row * 8 + Col, CharsetBytes(Row, Col))
    Next
  Next

  WriteData(FileNum, *Buffer, TotalSize)
  CloseFile(FileNum)
  FreeMemory(*Buffer)
  CharEd_LastError = ""
  ProcedureReturn #True
EndProcedure

; Endereco VRAM da Pattern Generator Table pra cada SCREEN do MSX-BASIC
; (0=Texto 1, 1=Graphic 1, 2=Graphic 2, 3=Multicolor). Por padrao do
; MSX-BASIC (sem BASE(4)=... explicito) a PGT fica em &H0000 nos quatro
; modos - so a Name/Color Table muda de endereco entre eles - mas mantido
; como funcao por SCREEN (nao uma constante unica) pra deixar explicito e
; facil de ajustar se algum dia um desses modos precisar de outro valor
; (ex.: SCREEN 2 tem 3 "tercos" de 2048 bytes na PGT; este alfabeto de 256
; caracteres/2048 bytes so preenche o primeiro terco, &H0000-&H07FF).
Procedure.u CharEd_ScreenPgtAddress(ScreenMode.i)
  ProcedureReturn $0000
EndProcedure

; Monta as linhas DATA do alfabeto inteiro (256 caracteres x 8 bytes = 2048
; bytes), 16 bytes hex por linha - mesmo formato/largura de linha usado por
; Scr2Ed_GenAlphabetLoader (Screen2EditorGui.pbi) pro alfabeto da SCREEN 2.
Procedure.s CharEd_BuildDataLines(Array CharsetBytes.a(2))
  Protected Text.s = ""
  Protected Row, Col, LineVals.s = "", Count = 0
  For Row = 0 To 255
    For Col = 0 To 7
      If Count > 0 And Count % 16 = 0
        Text + "data " + LineVals + #CRLF$
        LineVals = ""
      EndIf
      If LineVals <> "" : LineVals + "," : EndIf
      LineVals + "&H" + RSet(Hex(CharsetBytes(Row, Col)), 2, "0")
      Count + 1
    Next
  Next
  If LineVals <> ""
    Text + "data " + LineVals + #CRLF$
  EndIf
  ProcedureReturn Text
EndProcedure

; Texto do botao "Gerar apenas DATA": comentario de identificacao + as
; linhas DATA, sem loop de leitura nenhum - so os bytes crus, prontos pra
; um RESTORE/READ escrito a mao (ou pra um loop montado depois com
; CharEd_BuildLoopText, se o usuario decidir usar o loop mais tarde).
Procedure.s CharEd_BuildDataOnlyText(Array CharsetBytes.a(2), AlphaNumber.i, AlphaTag.s)
  Protected TagSuffix.s = ""
  If AlphaTag <> ""
    TagSuffix = " (" + AlphaTag + ")"
  EndIf
  Protected Text.s = "' Alfabeto #" + Str(AlphaNumber) + TagSuffix +
                      " - 256 caracteres 8x8, Pattern Generator Table (" + Str(#CharEd_AlfDataSize) + " bytes)" + #CRLF$
  Text + CharEd_BuildDataLines(CharsetBytes())
  ProcedureReturn Text
EndProcedure

; Texto do botao "Gerar DATA + loop VRAM": {label} + DATA (via
; CharEd_BuildDataOnlyText) + RESTORE + um loop FOR/READ/VPOKE que copia os
; 2048 bytes direto pra Pattern Generator Table do SCREEN escolhido no
; menu popup (CharEd_ScreenPgtAddress).
Procedure.s CharEd_BuildLoopText(Array CharsetBytes.a(2), AlphaNumber.i, AlphaTag.s, ScreenMode.i)
  Protected LabelName.s = "alf" + Str(AlphaNumber)
  Protected PgtAddr.u = CharEd_ScreenPgtAddress(ScreenMode)
  Protected AddrHex.s = "&H" + RSet(Hex(PgtAddr), 4, "0")

  Protected Text.s = "{" + LabelName + "}" + #CRLF$
  Text + CharEd_BuildDataOnlyText(CharsetBytes(), AlphaNumber, AlphaTag)
  Text + #CRLF$
  Text + "restore {" + LabelName + "}" + #CRLF$
  Text + "' Copia para a Pattern Generator Table da SCREEN " + Str(ScreenMode) + " (" + AddrHex + ")" + #CRLF$
  Text + "for alf_i = 0 to " + Str(#CharEd_AlfDataSize - 1) + #CRLF$
  Text + "  read alf_b" + #CRLF$
  Text + "  vpoke " + AddrHex + " + alf_i, alf_b" + #CRLF$
  Text + "next alf_i" + #CRLF$

  ProcedureReturn Text
EndProcedure

; Texto do botao "Salvar BIN (Graphos III) + BLOAD", inserido no cursor
; depois de escrever o .bin em disco (mesmo formato de CharEd_SaveAlf: BSAVE
; de 7 bytes, base &H9200): a linha BLOAD carrega no endereco gravado no
; proprio cabecalho do arquivo (&H9200, convencao do Graphos III) - como o
; BLOAD classico do MSX-BASIC nao aceita endereco de destino alternativo,
; se a Pattern Generator Table real do SCREEN escolhido for outro endereco
; (o caso comum: &H0000) um segundo loop copia de VRAM pra VRAM
; (VPEEK/VPOKE) de &H9200 pro endereco final, cobrindo o "deslocamento"
; entre o endereco de carga do arquivo e o endereco de uso em tela.
Procedure.s CharEd_BuildBloadText(Filename.s, ScreenMode.i)
  Protected PgtAddr.u = CharEd_ScreenPgtAddress(ScreenMode)
  Protected LoadAddrHex.s = "&H" + RSet(Hex(#CharEd_AlfLoadAddress), 4, "0")
  Protected PgtAddrHex.s = "&H" + RSet(Hex(PgtAddr), 4, "0")
  Protected Quote.s = Chr(34)

  Protected Text.s = "' Carrega " + Filename + " (formato Graphos III, base " + LoadAddrHex + ")" + #CRLF$
  Text + "bload " + Quote + Filename + Quote + ",s" + #CRLF$
  If PgtAddr <> #CharEd_AlfLoadAddress
    Text + "' Copia da area de carga do Graphos III (" + LoadAddrHex + ") pra Pattern Generator Table da SCREEN " +
           Str(ScreenMode) + " (" + PgtAddrHex + ")" + #CRLF$
    Text + "for alf_i = 0 to " + Str(#CharEd_AlfDataSize - 1) + #CRLF$
    Text + "  vpoke " + PgtAddrHex + " + alf_i, vpeek(" + LoadAddrHex + " + alf_i)" + #CRLF$
    Text + "next alf_i" + #CRLF$
  EndIf

  ProcedureReturn Text
EndProcedure

; Menu popup pequeno com as 4 SCREEN validas pro alfabeto (usado tanto por
; "Gerar DATA + loop VRAM" quanto por "Salvar BIN + BLOAD") - a escolha do
; usuario chega depois no loop de eventos como #PB_Event_Menu/EventMenu()
; (0-3, mesmo numero da SCREEN), nunca sincronamente aqui; cancelar o popup
; (clicar fora) nao gera evento nenhum.
Procedure CharEd_ShowScreenPopupMenu(Win)
  Protected Menu = CreatePopupMenu(#PB_Any)
  MenuItem(0, "SCREEN 0 (Texto 1)")
  MenuItem(1, "SCREEN 1 (Graphic 1)")
  MenuItem(2, "SCREEN 2 (Graphic 2)")
  MenuItem(3, "SCREEN 3 (Multicolor)")
  DisplayPopupMenu(Menu, WindowID(Win))
  FreeMenu(Menu)
EndProcedure

; Desempacota os 8 bytes do caractere CharIndex em EditGrid (8x8, 0/1) - bit
; 7 de cada byte e a coluna 0 (pixel mais a esquerda), igual ao layout real
; do bitmap MSX.
Procedure CharEd_UnpackChar(Array CharsetBytes.a(2), CharIndex.i, Array EditGrid.a(2))
  Protected Row, Col, ByteVal.a
  For Row = 0 To 7
    ByteVal = CharsetBytes(CharIndex, Row)
    For Col = 0 To 7
      If ByteVal & (1 << (7 - Col))
        EditGrid(Row, Col) = 1
      Else
        EditGrid(Row, Col) = 0
      EndIf
    Next
  Next
EndProcedure

; Empacota EditGrid (8x8, 0/1) de volta nos 8 bytes do caractere CharIndex -
; chamado pelo botao "Registrar", nunca automaticamente ao editar.
Procedure CharEd_PackChar(Array EditGrid.a(2), Array CharsetBytes.a(2), CharIndex.i)
  Protected Row, Col, ByteVal.a
  For Row = 0 To 7
    ByteVal = 0
    For Col = 0 To 7
      If EditGrid(Row, Col)
        ByteVal = ByteVal | (1 << (7 - Col))
      EndIf
    Next
    CharsetBytes(CharIndex, Row) = ByteVal
  Next
EndProcedure

Procedure CharEd_ClearEditGrid(Array EditGrid.a(2))
  Protected Row, Col
  For Row = 0 To 7
    For Col = 0 To 7
      EditGrid(Row, Col) = 0
    Next
  Next
EndProcedure

Procedure CharEd_InvertEditGrid(Array EditGrid.a(2))
  Protected Row, Col
  For Row = 0 To 7
    For Col = 0 To 7
      EditGrid(Row, Col) = 1 - EditGrid(Row, Col)
    Next
  Next
EndProcedure

; Espelha o EditGrid (8x8) na horizontal - coluna Col troca de lugar com a
; coluna (7-Col), linha a linha.
Procedure CharEd_FlipHEditGrid(Array EditGrid.a(2))
  Protected Row, Col, Tmp.a
  For Row = 0 To 7
    For Col = 0 To 3
      Tmp = EditGrid(Row, Col)
      EditGrid(Row, Col) = EditGrid(Row, 7 - Col)
      EditGrid(Row, 7 - Col) = Tmp
    Next
  Next
EndProcedure

; Espelha o EditGrid (8x8) na vertical - linha Row troca de lugar com a
; linha (7-Row), coluna a coluna.
Procedure CharEd_FlipVEditGrid(Array EditGrid.a(2))
  Protected Row, Col, Tmp.a
  For Row = 0 To 3
    For Col = 0 To 7
      Tmp = EditGrid(Row, Col)
      EditGrid(Row, Col) = EditGrid(7 - Row, Col)
      EditGrid(7 - Row, Col) = Tmp
    Next
  Next
EndProcedure

; Gira o EditGrid (8x8) 90 graus no sentido horario: novo(Row,Col) =
; antigo(7-Col, Row) - formula padrao de rotacao horaria de matriz quadrada.
Procedure CharEd_RotateEditGrid(Array EditGrid.a(2))
  Protected Row, Col
  Dim Tmp.a(7, 7)
  For Row = 0 To 7
    For Col = 0 To 7
      Tmp(Row, Col) = EditGrid(Row, Col)
    Next
  Next
  For Row = 0 To 7
    For Col = 0 To 7
      EditGrid(Row, Col) = Tmp(7 - Col, Row)
    Next
  Next
EndProcedure

; Estreitar: condensa as 5 colunas da METADE ESQUERDA do glifo (0..4) em so 3
; colunas de saida, juntando pares de colunas por OR - truque classico de
; texto MSX pra caber 64 colunas onde so caberiam 32 (glifo "normal" ocupa
; a celula de 8px inteira, glifo "estreito" so usa as 3 colunas mais a
; esquerda, o resto sempre apagado). Formula pedida pelo usuario, em termos
; de mascara de bits (bit7=col0 .. bit0=col7):
;   byte1 = (byte & %00011000) <> 0 ? %00100000 : 0   -> colunas 3,4 -> col2
;   byte2 = (byte & %11000000) <> 0 ? %10000000 : 0   -> colunas 0,1 -> col0
;   byte3 = (byte & %00100000) <> 0 ? %01000000 : 0   -> coluna  2   -> col1
;   saida = byte1 | byte2 | byte3
; Em termos de pixel (equivalente bit a bit, mais facil de ler no EditGrid):
Procedure CharEd_NarrowEditGrid(Array EditGrid.a(2))
  Protected Row, Col0.a, Col1.a, Col2.a
  For Row = 0 To 7
    Col0 = Bool(EditGrid(Row, 0) Or EditGrid(Row, 1))
    Col1 = EditGrid(Row, 2)
    Col2 = Bool(EditGrid(Row, 3) Or EditGrid(Row, 4))
    EditGrid(Row, 0) = Col0
    EditGrid(Row, 1) = Col1
    EditGrid(Row, 2) = Col2
    EditGrid(Row, 3) = 0
    EditGrid(Row, 4) = 0
    EditGrid(Row, 5) = 0
    EditGrid(Row, 6) = 0
    EditGrid(Row, 7) = 0
  Next
EndProcedure

; Italico: desloca cada linha pra direita por uma quantidade que diminui de
; cima pra baixo - as 2 primeiras linhas (0,1) deslocam 2 bits, as 3
; seguintes (2,3,4) deslocam 1 bit, e as 3 ultimas (5,6,7) ficam iguais (0
; bits) - pedido exato do usuario. "Deslocar N bits a direita" equivale a
; empurrar as colunas pra direita: NovaCol(c) = VelhaCol(c-N) se c>=N, senao
; 0 - as N colunas mais a direita da linha original saem da celula e se
; perdem (mesmo comportamento de um SHR de verdade, sem wrap-around).
Procedure CharEd_ItalicEditGrid(Array EditGrid.a(2))
  Protected Row, Col, Shift.i
  Dim Tmp.a(7, 7)
  For Row = 0 To 7
    For Col = 0 To 7
      Tmp(Row, Col) = EditGrid(Row, Col)
    Next
  Next
  For Row = 0 To 7
    Select Row
      Case 0, 1
        Shift = 2
      Case 2, 3, 4
        Shift = 1
      Default
        Shift = 0
    EndSelect
    For Col = 0 To 7
      If Col >= Shift
        EditGrid(Row, Col) = Tmp(Row, Col - Shift)
      Else
        EditGrid(Row, Col) = 0
      EndIf
    Next
  Next
EndProcedure

; Negrito: desloca cada linha 1 bit a direita (equivale a dividir o byte por
; 2) e faz OR com a linha original - a "sombra" deslocada engrossa cada
; traco vertical em 1px, dando aspecto de negrito. Mesma regra de
; NovaCol(c) = VelhaCol(c-1) usada no Italico, so que aqui o resultado e
; OR'd com a coluna original em vez de substitui-la.
Procedure CharEd_BoldEditGrid(Array EditGrid.a(2))
  Protected Row, Col
  Dim Tmp.a(7, 7)
  For Row = 0 To 7
    For Col = 0 To 7
      Tmp(Row, Col) = EditGrid(Row, Col)
    Next
  Next
  For Row = 0 To 7
    For Col = 0 To 7
      If Col >= 1
        EditGrid(Row, Col) = Bool(Tmp(Row, Col) Or Tmp(Row, Col - 1))
      Else
        EditGrid(Row, Col) = Tmp(Row, Col)
      EndIf
    Next
  Next
EndProcedure

; Largo: combina as colunas 0-2 do byte original com as colunas 3-7 do byte
; deslocado 1 bit a direita - equivale a "ByteA OR ByteB" onde ByteA =
; Original AND %11100000 (colunas 0-2) e ByteB = (Original >> 1) AND
; %00011111 (colunas 3-7 do deslocado, ou seja colunas 2-6 do original
; movidas 1 posicao pra direita). Na pratica repete a coluna 2 (aparece nas
; posicoes 2 E 3 do resultado) e empurra o resto, esticando o glifo em 1px -
; oposto do "Estreitar". Coluna 7 do original se perde (cai fora da celula
; no deslocamento), mesmo comportamento de um SHR de verdade.
Procedure CharEd_WideEditGrid(Array EditGrid.a(2))
  Protected Row, Col
  Dim Tmp.a(7, 7)
  For Row = 0 To 7
    For Col = 0 To 7
      Tmp(Row, Col) = EditGrid(Row, Col)
    Next
  Next
  For Row = 0 To 7
    For Col = 0 To 7
      If Col <= 2
        EditGrid(Row, Col) = Tmp(Row, Col)
      Else
        EditGrid(Row, Col) = Tmp(Row, Col - 1)
      EndIf
    Next
  Next
EndProcedure

; Bold (esquerda): ByteA = Original AND %11100000 (colunas 0-2), depois
; ByteA OR (Original >> 1) inteiro (sem mascara desta vez) - diferenca pro
; "Largo" comum: aqui as colunas 1-2 tambem recebem o OR com a copia
; deslocada (engrossando o lado esquerdo, igual o Negrito faria ali), e as
; colunas 3-7 continuam vindo so da copia deslocada (igual o Largo comum).
; Coluna 0 fica igual ao original (o deslocado nao contribui ali, vira 0).
Procedure CharEd_BoldLeftEditGrid(Array EditGrid.a(2))
  Protected Row, Col
  Dim Tmp.a(7, 7)
  For Row = 0 To 7
    For Col = 0 To 7
      Tmp(Row, Col) = EditGrid(Row, Col)
    Next
  Next
  For Row = 0 To 7
    For Col = 0 To 7
      Select Col
        Case 0
          EditGrid(Row, Col) = Tmp(Row, Col)
        Case 1, 2
          EditGrid(Row, Col) = Bool(Tmp(Row, Col) Or Tmp(Row, Col - 1))
        Default
          EditGrid(Row, Col) = Tmp(Row, Col - 1)
      EndSelect
    Next
  Next
EndProcedure

; Bold (direita): ByteB = (Original >> 1) AND %00011111 (colunas 3-7 do
; deslocado), depois ByteB OR Original inteiro (sem mascara) - espelho do
; "Bold (esquerda)" acima: aqui as colunas 0-2 ficam iguais ao original (o
; deslocado nao contribui ali, mascarado fora), e as colunas 3-7 recebem o
; OR com a copia deslocada, engrossando o lado direito do glifo.
Procedure CharEd_BoldRightEditGrid(Array EditGrid.a(2))
  Protected Row, Col
  Dim Tmp.a(7, 7)
  For Row = 0 To 7
    For Col = 0 To 7
      Tmp(Row, Col) = EditGrid(Row, Col)
    Next
  Next
  For Row = 0 To 7
    For Col = 0 To 7
      If Col <= 2
        EditGrid(Row, Col) = Tmp(Row, Col)
      Else
        EditGrid(Row, Col) = Bool(Tmp(Row, Col) Or Tmp(Row, Col - 1))
      EndIf
    Next
  Next
EndProcedure

; Largo (bold): faz o mesmo processo do "Largo" comum, depois aplica o mesmo
; engrossamento do "Negrito" (OR de cada linha com ela mesma deslocada 1 bit
; a direita) em cima do resultado ja alargado - ou seja, e literalmente
; Bold(Largo(x)), reaproveitando as duas transformacoes ja existentes em vez
; de reimplementar a formula de bits nova.
Procedure CharEd_WideBoldEditGrid(Array EditGrid.a(2))
  CharEd_WideEditGrid(EditGrid())
  CharEd_BoldEditGrid(EditGrid())
EndProcedure

; Aplica um dos efeitos acima (Clear/Invert/FlipH/FlipV/Rotate90/Narrow/
; Italico/Negrito/Largo/Bold esquerda/Bold direita/Largo bold) direto em
; CharsetBytes(), num intervalo [StartIdx..EndIdx] de caracteres - usado
; pelo modo "bloco marcado" (ou "All") dos botoes de efeito, que mexem no
; alfabeto de uma vez em vez de exigir "Registrar" caractere por caractere.
; Reaproveita Unpack/transforma/Pack pra nao duplicar a logica de bits.
Procedure CharEd_ApplyGridEffectToRange(Array CharsetBytes.a(2), StartIdx.i, EndIdx.i, EffectId.i)
  Protected Idx
  Dim TempGrid.a(7, 7)
  For Idx = StartIdx To EndIdx
    CharEd_UnpackChar(CharsetBytes(), Idx, TempGrid())
    Select EffectId
      Case #CharEd_Effect_Clear
        CharEd_ClearEditGrid(TempGrid())
      Case #CharEd_Effect_Invert
        CharEd_InvertEditGrid(TempGrid())
      Case #CharEd_Effect_FlipH
        CharEd_FlipHEditGrid(TempGrid())
      Case #CharEd_Effect_FlipV
        CharEd_FlipVEditGrid(TempGrid())
      Case #CharEd_Effect_Rotate90
        CharEd_RotateEditGrid(TempGrid())
      Case #CharEd_Effect_Narrow
        CharEd_NarrowEditGrid(TempGrid())
      Case #CharEd_Effect_Italic
        CharEd_ItalicEditGrid(TempGrid())
      Case #CharEd_Effect_Bold
        CharEd_BoldEditGrid(TempGrid())
      Case #CharEd_Effect_Wide
        CharEd_WideEditGrid(TempGrid())
      Case #CharEd_Effect_BoldLeft
        CharEd_BoldLeftEditGrid(TempGrid())
      Case #CharEd_Effect_BoldRight
        CharEd_BoldRightEditGrid(TempGrid())
      Case #CharEd_Effect_WideBold
        CharEd_WideBoldEditGrid(TempGrid())
    EndSelect
    CharEd_PackChar(TempGrid(), CharsetBytes(), Idx)
  Next
EndProcedure

; Copia CharsetBytes() (256x8) de/para um instantaneo achatado de 2048 bytes
; (ver CharEd_AlphaSnapshot) - usado pela pilha de Desfazer/Refazer abaixo.
Procedure CharEd_SnapshotFromArray(Array CharsetBytes.a(2), *Snap.CharEd_AlphaSnapshot)
  Protected Row, Col
  For Row = 0 To 255
    For Col = 0 To 7
      *Snap\Bytes[Row * 8 + Col] = CharsetBytes(Row, Col)
    Next
  Next
EndProcedure

Procedure CharEd_ArrayFromSnapshot(*Snap.CharEd_AlphaSnapshot, Array CharsetBytes.a(2))
  Protected Row, Col
  For Row = 0 To 255
    For Col = 0 To 7
      CharsetBytes(Row, Col) = *Snap\Bytes[Row * 8 + Col]
    Next
  Next
EndProcedure

; Empilha o estado ATUAL de CharsetBytes() (antes da mudanca que esta prestes
; a acontecer) na pilha de Desfazer, e descarta a pilha de Refazer (uma nova
; acao invalida qualquer "refazer" pendente - mesma convencao de qualquer
; editor com undo/redo). Limita a profundidade da pilha (#CharEd_MaxUndo)
; descartando o instantaneo mais antigo quando excede.
Procedure CharEd_PushUndo(List UndoStack.CharEd_AlphaSnapshot(), List RedoStack.CharEd_AlphaSnapshot(), Array CharsetBytes.a(2))
  ClearList(RedoStack())
  AddElement(UndoStack())
  CharEd_SnapshotFromArray(CharsetBytes(), @UndoStack())
  If ListSize(UndoStack()) > #CharEd_MaxUndo
    FirstElement(UndoStack())
    DeleteElement(UndoStack())
  EndIf
EndProcedure

; Habilita/desabilita os botoes Desfazer/Refazer conforme o que ha nas pilhas
; - chamado depois de toda operacao que empilha/desempilha um instantaneo, e
; ao trocar de alfabeto (pilhas zeradas, ver comentario no topo do arquivo).
Procedure CharEd_UpdateUndoRedoButtons(G_Undo, G_Redo, List UndoStack.CharEd_AlphaSnapshot(), List RedoStack.CharEd_AlphaSnapshot())
  DisableGadget(G_Undo, Bool(ListSize(UndoStack()) = 0))
  DisableGadget(G_Redo, Bool(ListSize(RedoStack()) = 0))
EndProcedure

; Empacota/desempacota EditGrid (8x8, 0/1) de/para um array simples de 8 bytes
; - mesma logica bit a bit de CharEd_PackChar/CharEd_UnpackChar, mas sem
; passar pelo array CharsetBytes(256,8) inteiro; usado pelo clipboard de
; caractere (Copiar/Colar), que so precisa guardar UM caractere solto.
Procedure CharEd_PackGridBytes(Array EditGrid.a(2), Array OutBytes.a(1))
  Protected Row, Col, ByteVal.a
  For Row = 0 To 7
    ByteVal = 0
    For Col = 0 To 7
      If EditGrid(Row, Col)
        ByteVal = ByteVal | (1 << (7 - Col))
      EndIf
    Next
    OutBytes(Row) = ByteVal
  Next
EndProcedure

Procedure CharEd_UnpackGridBytes(Array InBytes.a(1), Array EditGrid.a(2))
  Protected Row, Col, ByteVal.a
  For Row = 0 To 7
    ByteVal = InBytes(Row)
    For Col = 0 To 7
      If ByteVal & (1 << (7 - Col))
        EditGrid(Row, Col) = 1
      Else
        EditGrid(Row, Col) = 0
      EndIf
    Next
  Next
EndProcedure

; "Caractere: 65 ($41) 'A'" - so mostra o caractere impresso pra faixa ASCII
; imprimivel (32-126); fora dela o charset MSX diverge do Unicode/Windows-1252
; e Chr() poderia desenhar qualquer coisa.
Procedure.s CharEd_CharStatusText(CharIndex.i)
  Protected Label.s = "Caractere: " + Str(CharIndex) + " ($" + RSet(Hex(CharIndex), 2, "0") + ")"
  If CharIndex >= 32 And CharIndex <= 126
    Label = Label + " '" + Chr(CharIndex) + "'"
  EndIf
  ProcedureReturn Label
EndProcedure

; Os 8 bytes hex do caractere sendo editado agora (recalculado a cada
; pixel alterado, antes de "Registrar") - leitura rapida pro usuario
; conferir/copiar os bytes, estilo editor de charset classico.
Procedure.s CharEd_HexBytesText(Array EditGrid.a(2))
  Protected Result.s = "", Row, Col, ByteVal.a
  For Row = 0 To 7
    ByteVal = 0
    For Col = 0 To 7
      If EditGrid(Row, Col)
        ByteVal = ByteVal | (1 << (7 - Col))
      EndIf
    Next
    Result = Result + "&H" + RSet(Hex(ByteVal), 2, "0")
    If Row < 7
      Result = Result + ","
    EndIf
  Next
  ProcedureReturn Result
EndProcedure

; "Bloco: $41..$5A (26 caracteres)" - status do intervalo marcado para o
; botao "Inverter" em modo bloco (ver CharEd_NormalizeBlock()); "nao marcado"
; quando BlockStart/BlockEnd ainda nao foram definidos (-1).
Procedure.s CharEd_BlockStatusText(BlockStart.i, BlockEnd.i)
  If BlockStart < 0 Or BlockEnd < 0
    ProcedureReturn "Bloco: nao marcado (Inverter afeta so o caractere atual)"
  EndIf
  Protected BStart = BlockStart, BEnd = BlockEnd
  If BStart > BEnd
    Swap BStart, BEnd
  EndIf
  ProcedureReturn "Bloco: $" + RSet(Hex(BStart), 2, "0") + "..$" + RSet(Hex(BEnd), 2, "0") +
                  " (" + Str(BEnd - BStart + 1) + " caracteres)"
EndProcedure

Procedure CharEd_UpdateFileLabel(G_FileLabel, CurrentPath.s)
  If CurrentPath = ""
    SetGadgetText(G_FileLabel, "Arquivo: (novo, sem nome)")
  Else
    SetGadgetText(G_FileLabel, "Arquivo: " + CurrentPath)
  EndIf
EndProcedure

; Tabela inteira (16x16 = 256 caracteres) com cabecalho hex de linha/coluna
; (linha = byte alto, coluna = nibble baixo - a posicao na grade ja e o
; codigo do caractere) e uma miniatura 8x8 (zoom 2x) de cada glifo, tal como
; esta em CharsetBytes agora. O caractere selecionado ganha um contorno
; vermelho; o intervalo marcado por "Marcar inicio/fim de bloco" (se algum
; estiver definido) ganha um contorno azul em cada caractere do intervalo -
; BlockStart/BlockEnd = -1 (default) significa "nenhum bloco marcado".
Procedure CharEd_RedrawTable(Canvas, Array CharsetBytes.a(2), Selected.i, BlockStart.i = -1, BlockEnd.i = -1)
  Protected HexDigits.s = "0123456789ABCDEF"
  Protected HasBlock.b = Bool(BlockStart >= 0 And BlockEnd >= 0)
  Protected BStart, BEnd
  If HasBlock
    BStart = BlockStart : BEnd = BlockEnd
    If BStart > BEnd
      Swap BStart, BEnd
    EndIf
  EndIf
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf

  Box(0, 0, #CharEd_TableCanvasW, #CharEd_TableCanvasH, RGB(255, 255, 255))

  DrawingMode(#PB_2DDrawing_Transparent)
  FrontColor(RGB(90, 90, 90))
  Protected i
  For i = 0 To 15
    DrawText(#CharEd_TableHeaderW + i * #CharEd_TableCellPx + 5, 2, Mid(HexDigits, i + 1, 1))
    DrawText(2, #CharEd_TableHeaderH + i * #CharEd_TableCellPx + 3, RSet(Hex(i * 16), 2, "0"))
  Next

  DrawingMode(#PB_2DDrawing_Default)
  Protected CharIdx, TableRow, TableCol, CellX, CellY, PxRow, PxCol, ByteVal.a
  Protected Zoom = 2
  For CharIdx = 0 To 255
    TableRow = CharIdx / 16
    TableCol = CharIdx % 16
    CellX = #CharEd_TableHeaderW + TableCol * #CharEd_TableCellPx + 1
    CellY = #CharEd_TableHeaderH + TableRow * #CharEd_TableCellPx + 1

    For PxRow = 0 To 7
      ByteVal = CharsetBytes(CharIdx, PxRow)
      For PxCol = 0 To 7
        If ByteVal & (1 << (7 - PxCol))
          Box(CellX + PxCol * Zoom, CellY + PxRow * Zoom, Zoom, Zoom, RGB(0, 0, 0))
        EndIf
      Next
    Next

    If HasBlock And CharIdx >= BStart And CharIdx <= BEnd
      DrawingMode(#PB_2DDrawing_Outlined)
      Box(CellX - 1, CellY - 1, 8 * Zoom + 2, 8 * Zoom + 2, RGB(40, 90, 210))
      DrawingMode(#PB_2DDrawing_Default)
    EndIf

    If CharIdx = Selected
      DrawingMode(#PB_2DDrawing_Outlined)
      Box(CellX - 1, CellY - 1, 8 * Zoom + 2, 8 * Zoom + 2, RGB(205, 40, 40))
      DrawingMode(#PB_2DDrawing_Default)
    EndIf
  Next

  StopDrawing()
EndProcedure

; Grade grande editavel (8x8, um quadrado grosso por pixel) com linhas de
; grade finas e uma cruz central mais forte de referencia (igual a maioria
; dos editores de charset classicos).
Procedure CharEd_RedrawEditCanvas(Canvas, Array EditGrid.a(2))
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf

  Box(0, 0, #CharEd_EditCanvasSize, #CharEd_EditCanvasSize, RGB(255, 255, 255))

  Protected Row, Col, X, Y
  For Row = 0 To 7
    For Col = 0 To 7
      If EditGrid(Row, Col)
        X = Col * #CharEd_EditPixelPx
        Y = Row * #CharEd_EditPixelPx
        Box(X + 1, Y + 1, #CharEd_EditPixelPx - 1, #CharEd_EditPixelPx - 1, RGB(0, 0, 0))
      EndIf
    Next
  Next

  Protected i
  For i = 0 To 8
    Line(i * #CharEd_EditPixelPx, 0, 0, #CharEd_EditCanvasSize, RGB(180, 180, 180))
    Line(0, i * #CharEd_EditPixelPx, #CharEd_EditCanvasSize, 0, RGB(180, 180, 180))
  Next
  Line(4 * #CharEd_EditPixelPx, 0, 0, #CharEd_EditCanvasSize, RGB(120, 120, 200))
  Line(0, 4 * #CharEd_EditPixelPx, #CharEd_EditCanvasSize, 0, RGB(120, 120, 200))

  StopDrawing()
EndProcedure

Procedure.b CharEd_ConfirmDiscardChar()
  ProcedureReturn Bool(MessageRequester("Caractere nao registrado",
                        "As alteracoes deste caractere ainda nao foram registradas no alfabeto." + Chr(10) +
                        "Descartar mesmo assim?",
                        #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
EndProcedure

Procedure.b CharEd_ConfirmDiscardAlphabet()
  ProcedureReturn Bool(MessageRequester("Alfabeto nao registrado",
                        "As alteracoes deste alfabeto (ou do caractere em edicao) ainda nao foram" + Chr(10) +
                        "registradas no projeto. Descartar mesmo assim?",
                        #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
EndProcedure

; Busca o alfabeto TargetNumber no projeto e atualiza a UI inteira (numero,
; tag, tabela, grade grande, status do caractere selecionado, bytes hex) -
; sempre reseta a selecao de caractere para 0. Nao mexe em AlphaNumber/
; AlphaTag do chamador; quem chama deve ler ProjectDB::LastAlphabetTag() em
; seguida pra manter as proprias variaveis em dia (mesmo padrao de
; SpriteEd_LoadSprite em SpriteEditorGui.pbi).
Procedure.b CharEd_LoadAlphabetUI(TargetNumber.i, G_AlphaNumberText, G_Tag, G_Table, G_EditCanvas, G_CharStatus, G_HexBytes, Array CharsetBytes.a(2), Array EditGrid.a(2), BlockStart.i = -1, BlockEnd.i = -1)
  If Not ProjectDB::FetchAlphabet(TargetNumber, CharsetBytes())
    ProcedureReturn #False
  EndIf
  SetGadgetText(G_AlphaNumberText, "#" + Str(TargetNumber))
  SetGadgetText(G_Tag, ProjectDB::LastAlphabetTag())
  CharEd_UnpackChar(CharsetBytes(), 0, EditGrid())
  CharEd_RedrawTable(G_Table, CharsetBytes(), 0, BlockStart, BlockEnd)
  CharEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
  SetGadgetText(G_CharStatus, CharEd_CharStatusText(0))
  SetGadgetText(G_HexBytes, CharEd_HexBytesText(EditGrid()))
  ProcedureReturn #True
EndProcedure

; ------------------------------------------------------------
;  Icones monocromaticos dos botoes (cinza escuro/claro, sem cor) - mesmo
;  estilo "desenhado em memoria" ja usado em SpriteEditorGui.pbi
;  (SpriteEd_CreateXxxIcon), so que em tons de cinza em vez de coloridos:
;  faz sentido pra um editor de bitmap preto-e-branco, e mantem os botoes
;  pequenos (34x26) sem depender de arquivo de icone externo. Varios botoes
;  de escopo diferente (caractere/alfabeto/bloco) reaproveitam o MESMO
;  desenho base (ex.: Copiar/Copiar alfabeto/Copiar bloco) - a posicao na
;  janela e o texto do tooltip e que diferenciam o escopo, nao o icone.
; ------------------------------------------------------------

#CharEd_IconInk   = $2D2D2D  ; cinza escuro (BGR, formato aceito por RGB()/CreateImage - ver nota abaixo)
#CharEd_IconInkLt = $969696  ; cinza claro

#CharEd_IconSize = 22
#CharEd_IconBtnW = 34
#CharEd_IconBtnH = 26

; Triangulo preenchido apontando na horizontal, desenhado por faixas
; horizontais (uma LineXY por linha Y, largura interpolada entre a base e o
; apice) - sem precisar de preenchimento de poligono. Reaproveitado pela seta
; de navegacao abaixo e pelos icones de espelhar (Flip H/V).
Procedure CharEd_DrawFilledHTri(CenterY.i, BaseX.i, ApexX.i, Half.i, Color.l)
  Protected y
  Protected.f Frac, EdgeX
  For y = -Half To Half
    Frac = 1 - Abs(y) / Half
    EdgeX = BaseX + (ApexX - BaseX) * Frac
    LineXY(BaseX, CenterY + y, EdgeX, CenterY + y, Color)
  Next
EndProcedure

; Mesma ideia, mas apontando na vertical (faixas verticais) - usado pelos
; icones de espelhar vertical e girar.
Procedure CharEd_DrawFilledVTri(CenterX.i, BaseY.i, ApexY.i, Half.i, Color.l)
  Protected x
  Protected.f Frac, EdgeY
  For x = -Half To Half
    Frac = 1 - Abs(x) / Half
    EdgeY = BaseY + (ApexY - BaseY) * Frac
    LineXY(CenterX + x, BaseY, CenterX + x, EdgeY, Color)
  Next
EndProcedure

; Seta/triangulo de navegacao (Primeiro/Anterior/Proximo/Ultimo) - Direction
; 0 = aponta pra esquerda, 1 = aponta pra direita; WithBar acrescenta uma
; barra vertical do lado apontado (Primeiro/Ultimo tem barra, Anterior/
; Proximo nao) - um unico desenho parametrizado reaproveitado pelos 4 botoes.
Procedure CharEd_CreateNavIcon(Size.i, Direction.i, WithBar.b)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected Cy = Size / 2, Half = Size / 2 - 5
    Protected BaseX, ApexX
    If Direction = 1
      BaseX = Size / 2 - Half : ApexX = Size / 2 + Half
    Else
      BaseX = Size / 2 + Half : ApexX = Size / 2 - Half
    EndIf
    CharEd_DrawFilledHTri(Cy, BaseX, ApexX, Half, #CharEd_IconInk)
    If WithBar
      If Direction = 1
        Box(Size / 2 + Half + 1, 3, 2, Size - 6, #CharEd_IconInk)
      Else
        Box(Size / 2 - Half - 3, 3, 2, Size - 6, #CharEd_IconInk)
      EndIf
    EndIf
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Novo alfabeto": pagina em branco com um "+" no canto.
Procedure CharEd_CreateNewIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(2, 2, Size - 8, Size - 4, #CharEd_IconInk)
    DrawingMode(#PB_2DDrawing_Default)
    Box(Size - 9, Size / 2 - 1, 8, 2, #CharEd_IconInk)
    Box(Size - 6, Size / 2 - 4, 2, 8, #CharEd_IconInk)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Registrar": ficha/cartao com linhas de campo - reaproveitado tanto para
; "Registrar" (caractere) quanto "Registrar alfabeto".
Procedure CharEd_CreateRegisterIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Box(2, 3, Size - 4, Size - 6, RGB(250, 250, 250))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(2, 3, Size - 4, Size - 6, #CharEd_IconInk)
    DrawingMode(#PB_2DDrawing_Default)
    Box(5, 7, Size - 10, 2, #CharEd_IconInk)
    Box(5, 11, Size - 10, 2, #CharEd_IconInk)
    Box(5, 15, Size - 14, 2, #CharEd_IconInk)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Copiar": duas folhas empilhadas - reaproveitado para Copiar (caractere),
; Copiar alfabeto e Copiar bloco.
Procedure CharEd_CreateCopyIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(7, 2, Size - 10, Size - 6, #CharEd_IconInkLt)
    DrawingMode(#PB_2DDrawing_Default)
    Box(2, 6, Size - 10, Size - 6, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(2, 6, Size - 10, Size - 6, #CharEd_IconInk)
    DrawingMode(#PB_2DDrawing_Default)
    Line(5, 9, Size - 16, 0, #CharEd_IconInk)
    Line(5, 13, Size - 16, 0, #CharEd_IconInk)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Colar": prancheta com grampo e linhas de texto - reaproveitado para Colar
; (caractere), Colar alfabeto e Colar bloco.
Procedure CharEd_CreatePasteIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Box(4, 5, Size - 8, Size - 7, RGB(250, 250, 250))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(4, 5, Size - 8, Size - 7, #CharEd_IconInk)
    DrawingMode(#PB_2DDrawing_Default)
    Box(Size / 2 - 3, 2, 6, 5, #CharEd_IconInkLt)
    Line(7, 10, Size - 14, 0, #CharEd_IconInk)
    Line(7, 14, Size - 14, 0, #CharEd_IconInk)
    Line(7, 18, Size - 14, 0, #CharEd_IconInk)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Carregar do Graphos III...": pasta (aba + corpo) - simbolo de abrir/
; importar um arquivo externo.
Procedure CharEd_CreateOpenIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Box(2, 8, 7, 3, RGB(245, 245, 245))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(2, 8, 7, 3, #CharEd_IconInk)
    DrawingMode(#PB_2DDrawing_Default)
    Box(2, 9, Size - 4, Size - 13, RGB(245, 245, 245))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(2, 9, Size - 4, Size - 13, #CharEd_IconInk)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Salvar como...": disquete classico (corpo + tampa deslizante + etiqueta).
Procedure CharEd_CreateSaveAsIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Box(2, 2, Size - 4, Size - 4, RGB(245, 245, 245))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(2, 2, Size - 4, Size - 4, #CharEd_IconInk)
    DrawingMode(#PB_2DDrawing_Default)
    Box(5, 2, Size - 10, 6, #CharEd_IconInkLt)
    Box(5, Size - 9, Size - 10, 7, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(5, Size - 9, Size - 10, 7, #CharEd_IconInk)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Gerar DATA + loop VRAM": pagina de codigo com linhas de texto e uma seta
; pra baixo com lacinho (circulo), sinalizando DATA + FOR/READ/VPOKE.
Procedure CharEd_CreateGenLoopIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(2, 2, Size - 10, Size - 6, #CharEd_IconInk)
    DrawingMode(#PB_2DDrawing_Default)
    Box(4, 5, Size - 14, 2, #CharEd_IconInkLt)
    Box(4, 9, Size - 14, 2, #CharEd_IconInkLt)
    Box(4, 13, Size - 18, 2, #CharEd_IconInkLt)
    Protected i
    For i = -1 To 1
      LineXY(Size - 6 + i, 1, Size - 6 + i, 11, #CharEd_IconInk)
    Next
    LineXY(Size - 10, 7, Size - 6, 12, #CharEd_IconInk)
    LineXY(Size - 2, 7, Size - 6, 12, #CharEd_IconInk)
    DrawingMode(#PB_2DDrawing_Outlined)
    Circle(Size - 6, Size - 4, 3, #CharEd_IconInk)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Gerar apenas DATA": pagina de codigo com linhas de texto, sem seta - so
; o DATA puro, sem loop de leitura.
Procedure CharEd_CreateGenDataIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(2, 2, Size - 4, Size - 4, #CharEd_IconInk)
    DrawingMode(#PB_2DDrawing_Default)
    Box(5, 5, Size - 10, 2, #CharEd_IconInkLt)
    Box(5, 9, Size - 10, 2, #CharEd_IconInkLt)
    Box(5, 13, Size - 14, 2, #CharEd_IconInkLt)
    Box(5, 17, Size - 10, 2, #CharEd_IconInkLt)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Salvar BIN (Graphos III) + BLOAD": disquete igual ao "Salvar como...",
; com uma setinha no canto inferior indicando que tambem gera a linha BLOAD.
Procedure CharEd_CreateSaveBinIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Box(1, 1, Size - 9, Size - 4, RGB(245, 245, 245))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(1, 1, Size - 9, Size - 4, #CharEd_IconInk)
    DrawingMode(#PB_2DDrawing_Default)
    Box(3, 1, Size - 13, 5, #CharEd_IconInkLt)
    Box(3, Size - 10, Size - 13, 6, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(3, Size - 10, Size - 13, 6, #CharEd_IconInk)
    DrawingMode(#PB_2DDrawing_Default)
    Protected j
    For j = -1 To 1
      LineXY(Size - 5 + j, Size - 13, Size - 5 + j, Size - 4, #CharEd_IconInk)
    Next
    LineXY(Size - 9, Size - 8, Size - 5, Size - 4, #CharEd_IconInk)
    LineXY(Size - 1, Size - 8, Size - 5, Size - 4, #CharEd_IconInk)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Marcar inicio": colchete "[" grosso.
Procedure CharEd_CreateMarkStartIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Box(6, 3, 3, Size - 6, #CharEd_IconInk)
    Box(6, 3, 8, 3, #CharEd_IconInk)
    Box(6, Size - 6, 8, 3, #CharEd_IconInk)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Marcar fim": colchete "]" grosso (espelho do anterior).
Procedure CharEd_CreateMarkEndIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Box(Size - 9, 3, 3, Size - 6, #CharEd_IconInk)
    Box(Size - 14, 3, 8, 3, #CharEd_IconInk)
    Box(Size - 14, Size - 6, 8, 3, #CharEd_IconInk)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Limpar bloco": colchetes "[ ]" claros com um X escuro por cima - simbolo
; de "descartar a marcacao do intervalo".
Procedure CharEd_CreateClearBlockIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Box(2, 4, 2, Size - 8, #CharEd_IconInkLt)
    Box(2, 4, 5, 2, #CharEd_IconInkLt)
    Box(2, Size - 6, 5, 2, #CharEd_IconInkLt)
    Box(Size - 4, 4, 2, Size - 8, #CharEd_IconInkLt)
    Box(Size - 7, 4, 5, 2, #CharEd_IconInkLt)
    Box(Size - 7, Size - 6, 5, 2, #CharEd_IconInkLt)
    Protected i
    For i = -1 To 1
      LineXY(6 + i, 5, Size - 7, Size - 6, #CharEd_IconInk)
      LineXY(6 + i, Size - 6, Size - 7, 5, #CharEd_IconInk)
    Next
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Limpar" (caractere): mini-grade riscada por uma diagonal - mesmo desenho
; de SpriteEd_CreateClearIcon, em cinza.
Procedure CharEd_CreateClearIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected Cell = (Size - 6) / 2
    Box(2, 2, Cell, Cell, #CharEd_IconInkLt)
    Box(Size - 2 - Cell, 2, Cell, Cell, #CharEd_IconInkLt)
    Box(2, Size - 2 - Cell, Cell, Cell, #CharEd_IconInkLt)
    Box(Size - 2 - Cell, Size - 2 - Cell, Cell, Cell, #CharEd_IconInkLt)
    Protected i
    For i = -1 To 1
      LineXY(1 + i, Size - 2, Size - 2, 1 + i, #CharEd_IconInk)
    Next
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(0, 0, Size, Size, RGB(150, 150, 150))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Inverter": circulo meio preto/meio branco - simbolo classico de inversao,
; mesmo desenho de SpriteEd_CreateInvertIcon (ja monocromatico).
Procedure CharEd_CreateInvertIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected R = Size / 2 - 2
    Circle(Size / 2, Size / 2, R, #CharEd_IconInk)
    Box(Size / 2, Size / 2 - R, R + 1, R * 2 + 1, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Circle(Size / 2, Size / 2, R, #CharEd_IconInkLt)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Desfazer"/"Refazer": arco de ~270 graus com uma seta curta na ponta -
; Mirrored = #False desenha o arco "abrindo" pro lado direito (Refazer,
; sentido horario); Mirrored = #True espelha cada ponto na horizontal,
; produzindo o mesmo desenho abrindo pro lado esquerdo (Desfazer) sem
; precisar recalcular a trigonometria duas vezes.
Procedure CharEd_CreateCircularArrowIcon(Size.i, Mirrored.b)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))

    Protected.f Cx = Size / 2, Cy = Size / 2, R = Size / 2 - 6
    Protected.f MirrorAxis = Size - 1
    Protected.f StartDeg = 30, EndDeg = 300, Ang, X, Y, PrevX, PrevY
    Protected Steps = 16, i

    PrevX = Cx + R * Cos(Radian(StartDeg)) : PrevY = Cy - R * Sin(Radian(StartDeg))
    If Mirrored : PrevX = MirrorAxis - PrevX : EndIf
    For i = 1 To Steps
      Ang = StartDeg + (EndDeg - StartDeg) * i / Steps
      X = Cx + R * Cos(Radian(Ang)) : Y = Cy - R * Sin(Radian(Ang))
      If Mirrored : X = MirrorAxis - X : EndIf
      LineXY(PrevX, PrevY, X, Y, #CharEd_IconInk)
      PrevX = X : PrevY = Y
    Next

    ; seta curta na ponta final do arco (fica embaixo, do lado da abertura)
    If Mirrored
      CharEd_DrawFilledHTri(Int(Y), Int(X) + 5, Int(X) - 3, 4, #CharEd_IconInk)
    Else
      CharEd_DrawFilledHTri(Int(Y), Int(X) - 5, Int(X) + 3, 4, #CharEd_IconInk)
    EndIf

    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Espelhar horizontal/vertical": linha pontilhada no eixo de espelhamento
; (vertical p/ Flip H, horizontal p/ Flip V) com duas setas apontando pra
; dentro, uma de cada lado - IsFlipVertical escolhe qual orientacao.
Procedure CharEd_CreateFlipIcon(Size.i, IsFlipVertical.b)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected Cx = Size / 2, Cy = Size / 2, Half = Size / 2 - 6, d
    If IsFlipVertical
      For d = 2 To Size - 3 Step 3
        Box(d, Cy - 1, 2, 2, #CharEd_IconInkLt)
      Next
      CharEd_DrawFilledVTri(Cx, 2, Cy - 2, Half, #CharEd_IconInk)
      CharEd_DrawFilledVTri(Cx, Size - 3, Cy + 2, Half, #CharEd_IconInk)
    Else
      For d = 2 To Size - 3 Step 3
        Box(Cx - 1, d, 2, 2, #CharEd_IconInkLt)
      Next
      CharEd_DrawFilledHTri(Cy, 2, Cx - 2, Half, #CharEd_IconInk)
      CharEd_DrawFilledHTri(Cy, Size - 3, Cx + 2, Half, #CharEd_IconInk)
    EndIf
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Girar 90 graus": quadrado central (o glifo) com um arco horario ao redor
; e uma seta na ponta, sugerindo o giro.
Procedure CharEd_CreateRotateIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))

    Box(Size / 2 - 4, Size / 2 - 4, 8, 8, #CharEd_IconInkLt)
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(Size / 2 - 4, Size / 2 - 4, 8, 8, #CharEd_IconInk)
    DrawingMode(#PB_2DDrawing_Default)

    Protected.f Cx = Size / 2, Cy = Size / 2, R = Size / 2 - 3
    Protected.f StartDeg = 100, EndDeg = -160, Ang, X, Y, PrevX, PrevY
    Protected Steps = 14, i
    PrevX = Cx + R * Cos(Radian(StartDeg)) : PrevY = Cy - R * Sin(Radian(StartDeg))
    For i = 1 To Steps
      Ang = StartDeg + (EndDeg - StartDeg) * i / Steps
      X = Cx + R * Cos(Radian(Ang)) : Y = Cy - R * Sin(Radian(Ang))
      LineXY(PrevX, PrevY, X, Y, #CharEd_IconInk)
      PrevX = X : PrevY = Y
    Next
    CharEd_DrawFilledHTri(Int(Y), Int(X) - 4, Int(X) + 4, 4, #CharEd_IconInk)

    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "All" (marcar o alfabeto inteiro como bloco): retangulo pontilhado, simbolo
; classico de selecionar tudo (marquee).
Procedure CharEd_CreateSelectAllIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected d
    For d = 2 To Size - 4 Step 4
      Box(d, 2, 2, 2, #CharEd_IconInk)
      Box(d, Size - 4, 2, 2, #CharEd_IconInk)
    Next
    For d = 2 To Size - 4 Step 4
      Box(2, d, 2, 2, #CharEd_IconInk)
      Box(Size - 4, d, 2, 2, #CharEd_IconInk)
    Next
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Estreitar": barra escura estreita no centro (o resultado condensado) com
; duas setas claras comprimindo dos dois lados - mesmas setas triangulares
; do icone de espelhar, aqui apontando pra dentro sem linha de eixo.
Procedure CharEd_CreateNarrowIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected Cx = Size / 2, Cy = Size / 2, Half = Size / 2 - 5
    CharEd_DrawFilledHTri(Cy, 2, Cx - 5, Half, #CharEd_IconInkLt)
    CharEd_DrawFilledHTri(Cy, Size - 3, Cx + 5, Half, #CharEd_IconInkLt)
    Box(Cx - 2, 3, 4, Size - 6, #CharEd_IconInk)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Italico": 3 barrinhas empilhadas, deslocando pra direita conforme sobem -
; ilustra literalmente o efeito (linhas de cima deslocam mais que as de
; baixo, as ultimas ficam paradas).
Procedure CharEd_CreateItalicIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected Cx = Size / 2, BarW = 10, BarH = 4
    Box(Cx - BarW / 2 + 5, 2, BarW, BarH, #CharEd_IconInk)
    Box(Cx - BarW / 2 + 2, 9, BarW, BarH, #CharEd_IconInk)
    Box(Cx - BarW / 2 - 3, 16, BarW, BarH, #CharEd_IconInk)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Negrito": barra clara (traco original) com uma barra escura mais larga
; sobreposta 1px a direita - ilustra o OR do traco original com a copia
; deslocada, que e exatamente o que o efeito faz.
Procedure CharEd_CreateBoldIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected Cx = Size / 2
    Box(Cx - 5, 3, 4, Size - 6, #CharEd_IconInkLt)
    Box(Cx - 4, 3, 6, Size - 6, #CharEd_IconInk)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Largo": barra curta no centro com duas setas claras apontando pra FORA
; (esticando) - espelho do icone de "Estreitar", que aponta pra dentro.
Procedure CharEd_CreateWideIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected Cx = Size / 2, Cy = Size / 2, Half = Size / 2 - 6, BarHalfW = 3
    Box(Cx - BarHalfW, Cy - 2, BarHalfW * 2, 4, #CharEd_IconInk)
    CharEd_DrawFilledHTri(Cy, Cx - BarHalfW - 1, 0, Half, #CharEd_IconInkLt)
    CharEd_DrawFilledHTri(Cy, Cx + BarHalfW, Size - 1, Half, #CharEd_IconInkLt)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Bold esquerda": barra encostada na borda direita (lado que fica fixo)
; com uma unica seta clara apontando pra fora, so do lado esquerdo -
; assimetrico, ao contrario do "Largo" (que estica dos dois lados); espelho
; horizontal do icone de "Bold direita" logo abaixo.
Procedure CharEd_CreateBoldLeftIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected Cy = Size / 2, Half = Size / 2 - 6
    Box(Size - 10, Cy - 2, 8, 4, #CharEd_IconInk)
    CharEd_DrawFilledHTri(Cy, Size - 11, 0, Half, #CharEd_IconInkLt)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Bold direita": barra encostada na borda esquerda (lado que fica fixo)
; com uma unica seta clara apontando pra fora, so do lado direito - espelho
; horizontal do icone de "Bold esquerda" acima.
Procedure CharEd_CreateBoldRightIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected Cy = Size / 2, Half = Size / 2 - 6
    Box(2, Cy - 2, 8, 4, #CharEd_IconInk)
    CharEd_DrawFilledHTri(Cy, 11, Size - 1, Half, #CharEd_IconInkLt)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Largo bold": mesmo desenho do "Largo" (barra central com setas claras
; apontando pra fora dos dois lados), so que com a barra mais grossa -
; combina os dois sinais visuais (esticar + engrossar).
Procedure CharEd_CreateWideBoldIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected Cx = Size / 2, Cy = Size / 2, Half = Size / 2 - 6, BarHalfW = 4
    Box(Cx - BarHalfW, Cy - 3, BarHalfW * 2, 6, #CharEd_IconInk)
    CharEd_DrawFilledHTri(Cy, Cx - BarHalfW - 1, 0, Half, #CharEd_IconInkLt)
    CharEd_DrawFilledHTri(Cy, Cx + BarHalfW, Size - 1, Half, #CharEd_IconInkLt)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

Procedure CharsetEditor_OpenWindow(ParentWindow)
  Protected LeftX = 15
  Protected ProjBarY = 15
  Protected AlphaClipY = ProjBarY + 34
  Protected FileBarY = AlphaClipY + 34
  Protected ExportBarY = FileBarY + 34
  Protected TableY = ExportBarY + 34

  Protected RightX = LeftX + #CharEd_TableCanvasW + 20
  Protected RightW = #CharEd_EditCanvasSize

  Protected LeftBottom = TableY + #CharEd_TableCanvasH
  Protected BlockBarY = LeftBottom + 15
  Protected BlockBarY2 = BlockBarY + 30
  Protected BlockBarY3 = BlockBarY2 + 26
  Protected CloseY = BlockBarY3 + 34

  Protected EditY = TableY + 24
  Protected HexBytesY = EditY + #CharEd_EditCanvasSize + 6
  Protected BtnY = HexBytesY + 26
  Protected BtnY2 = BtnY + 32
  Protected BtnY3 = BtnY2 + 32
  Protected BtnY4 = BtnY3 + 32
  Protected BtnY5 = BtnY4 + 32
  Protected RightBottom = BtnY5 + 28

  Protected WinW = RightX + RightW + 15
  Protected WinH
  If RightBottom > CloseY + 30
    WinH = RightBottom + 15
  Else
    WinH = CloseY + 30 + 15
  EndIf

  ; Barra de projeto (numero/navegacao/tag/Novo/Registrar alfabeto) pode
  ; precisar de mais largura que a tabela+grade - WinW cresce se preciso.
  ; Botoes viraram icones (34px) em vez de texto - ver bloco de
  ; CharEd_CreateXxxIcon() acima de CharsetEditor_OpenWindow.
  Protected Cx = LeftX + 60 + 4 + 40 + 10 + #CharEd_IconBtnW + 2 + #CharEd_IconBtnW + 2 + #CharEd_IconBtnW + 2 +
                 #CharEd_IconBtnW + 16 + 32 + 4 + 110 + 16 + #CharEd_IconBtnW + 6 + #CharEd_IconBtnW + 15
  If Cx > WinW
    WinW = Cx
  EndIf

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Criar alfabeto MSX (Graphos III)",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  ; Barra de projeto: numero do alfabeto atual, navegacao entre os alfabetos
  ; ja registrados no projeto, tag (nome curto) e os botoes Novo/Registrar -
  ; mesmo padrao da barra de projeto do editor de sprites.
  Cx = LeftX
  TextGadget(#PB_Any, Cx, ProjBarY + 5, 60, 20, "Alfabeto:")
  Cx + 60 + 4
  Protected G_AlphaNumberText = TextGadget(#PB_Any, Cx, ProjBarY + 5, 40, 20, "#1")
  Cx + 40 + 10

  Protected FirstIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 0, #True)
  Protected G_First = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(FirstIcon))
  GadgetToolTip(G_First, "Primeiro alfabeto")
  Cx + #CharEd_IconBtnW + 2
  Protected PrevIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 0, #False)
  Protected G_Prev = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(PrevIcon))
  GadgetToolTip(G_Prev, "Alfabeto anterior")
  Cx + #CharEd_IconBtnW + 2
  Protected NextIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 1, #False)
  Protected G_Next = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(NextIcon))
  GadgetToolTip(G_Next, "Proximo alfabeto")
  Cx + #CharEd_IconBtnW + 2
  Protected LastIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 1, #True)
  Protected G_Last = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(LastIcon))
  GadgetToolTip(G_Last, "Ultimo alfabeto")
  Cx + #CharEd_IconBtnW + 16

  TextGadget(#PB_Any, Cx, ProjBarY + 5, 32, 20, "Tag:")
  Cx + 32 + 4
  Protected G_Tag = StringGadget(#PB_Any, Cx, ProjBarY + 3, 110, 22, "")
  GadgetToolTip(G_Tag, "Nome curto pra identificar o alfabeto (ate 16 caracteres)")
  Cx + 110 + 16

  Protected NewAlphaIcon = CharEd_CreateNewIcon(#CharEd_IconSize)
  Protected G_AlphaNew = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(NewAlphaIcon))
  GadgetToolTip(G_AlphaNew, "Novo alfabeto (numera automaticamente, sempre parte do msx.alf padrao)")
  Cx + #CharEd_IconBtnW + 6
  Protected RegisterAlphaIcon = CharEd_CreateRegisterIcon(#CharEd_IconSize)
  Protected G_AlphaRegister = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(RegisterAlphaIcon))
  GadgetToolTip(G_AlphaRegister, "Registrar alfabeto: grava este alfabeto inteiro (256 caracteres) no projeto")

  ; Clipboard de alfabeto inteiro (256 caracteres): Copiar guarda o alfabeto
  ; em edicao (aplicando primeiro qualquer pixel pendente do caractere atual,
  ; pra nao deixar nada de fora); Colar substitui o alfabeto em edicao pelo
  ; que estiver copiado (ainda precisa de "Registrar alfabeto" pra valer no
  ; projeto) - permite duplicar um alfabeto inteiro pra outro numero.
  Protected CopyAlphaIcon = CharEd_CreateCopyIcon(#CharEd_IconSize)
  Protected G_CopyAlpha  = ButtonImageGadget(#PB_Any, LeftX, AlphaClipY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(CopyAlphaIcon))
  GadgetToolTip(G_CopyAlpha, "Copiar alfabeto: copia os 256 caracteres deste alfabeto pra area de transferencia da sessao")
  Protected PasteAlphaIcon = CharEd_CreatePasteIcon(#CharEd_IconSize)
  Protected G_PasteAlpha = ButtonImageGadget(#PB_Any, LeftX + #CharEd_IconBtnW + 6, AlphaClipY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(PasteAlphaIcon))
  GadgetToolTip(G_PasteAlpha, "Colar alfabeto: substitui os 256 caracteres deste alfabeto pelo que foi copiado - use 'Registrar alfabeto' pra salvar no projeto")

  Protected G_FileLabel    = TextGadget(#PB_Any, LeftX, FileBarY + 5, 260, 20, "")
  Protected OpenIcon = CharEd_CreateOpenIcon(#CharEd_IconSize)
  Protected G_LoadGraphos  = ButtonImageGadget(#PB_Any, LeftX + 270, FileBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(OpenIcon))
  GadgetToolTip(G_LoadGraphos, "Carregar do Graphos III...: importa um alfabeto .alf como um NOVO alfabeto (numeracao automatica) - use 'Registrar alfabeto' para salvar no projeto")
  Protected SaveAsIcon = CharEd_CreateSaveAsIcon(#CharEd_IconSize)
  Protected G_SaveAs       = ButtonImageGadget(#PB_Any, LeftX + 270 + #CharEd_IconBtnW + 6, FileBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(SaveAsIcon))
  GadgetToolTip(G_SaveAs, "Salvar como...: exporta o alfabeto em edicao para um arquivo .alf do Graphos III, independente do projeto")

  ; Barra de exportacao pra codigo Basic Dignified: os tres botoes abaixo
  ; inserem texto no cursor da aba de texto ativa (mesmo InjectTextAtCursor
  ; usado pelo editor de sprites), nao mexem no arquivo .alf/projeto.
  Protected GenLoopIcon = CharEd_CreateGenLoopIcon(#CharEd_IconSize)
  Protected G_GenLoop = ButtonImageGadget(#PB_Any, LeftX, ExportBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(GenLoopIcon))
  GadgetToolTip(G_GenLoop, "Gerar DATA + loop VRAM: pergunta a SCREEN (0-3) e insere DATA + loop FOR/READ/VPOKE pra Pattern Generator Table no cursor da aba de texto ativa")

  Protected GenDataIcon = CharEd_CreateGenDataIcon(#CharEd_IconSize)
  Protected G_GenData = ButtonImageGadget(#PB_Any, LeftX + #CharEd_IconBtnW + 6, ExportBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(GenDataIcon))
  GadgetToolTip(G_GenData, "Gerar apenas DATA: insere so as linhas DATA do alfabeto (sem loop de leitura) no cursor da aba de texto ativa")

  Protected SaveBinIcon = CharEd_CreateSaveBinIcon(#CharEd_IconSize)
  Protected G_SaveBin = ButtonImageGadget(#PB_Any, LeftX + (#CharEd_IconBtnW + 6) * 2, ExportBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(SaveBinIcon))
  GadgetToolTip(G_SaveBin, "Salvar BIN (Graphos III) + BLOAD: salva o alfabeto em disco (mesmo formato do 'Salvar como...') e insere a linha BLOAD no cursor, perguntando a SCREEN (0-3) de destino")

  Protected G_Table = CanvasGadget(#PB_Any, LeftX, TableY, #CharEd_TableCanvasW, #CharEd_TableCanvasH)

  ; Bloco marcado na tabela (le o botao "Inverter" mais abaixo, evento
  ; G_Invert): "Marcar inicio"/"Marcar fim" gravam o caractere selecionado no
  ; momento do clique; "Limpar bloco" volta ao modo padrao (Inverter afeta so
  ; o caractere atual).
  Protected MarkStartIcon = CharEd_CreateMarkStartIcon(#CharEd_IconSize)
  Protected G_MarkStart  = ButtonImageGadget(#PB_Any, LeftX, BlockBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(MarkStartIcon))
  GadgetToolTip(G_MarkStart, "Marcar inicio: marca o caractere selecionado como inicio do intervalo (ex.: A)")
  Protected MarkEndIcon = CharEd_CreateMarkEndIcon(#CharEd_IconSize)
  Protected G_MarkEnd    = ButtonImageGadget(#PB_Any, LeftX + #CharEd_IconBtnW + 6, BlockBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(MarkEndIcon))
  GadgetToolTip(G_MarkEnd, "Marcar fim: marca o caractere selecionado como fim do intervalo (ex.: Z)")
  Protected SelectAllIcon = CharEd_CreateSelectAllIcon(#CharEd_IconSize)
  Protected G_All = ButtonImageGadget(#PB_Any, LeftX + (#CharEd_IconBtnW + 6) * 2, BlockBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(SelectAllIcon))
  GadgetToolTip(G_All, "All: marca o alfabeto inteiro (256 caracteres) como bloco, pra aplicar Inverter/Espelhar/Girar/Apagar em todos de uma vez")

  ; Copiar bloco/Colar bloco: guardam/restauram o INTERVALO marcado (nao so um
  ; caractere) - Colar cola a partir do caractere selecionado na tabela (ex.:
  ; marcar A..Z, Copiar bloco, selecionar "a", Colar bloco substitui a..z
  ; pelos bytes de A..Z) e remarca o intervalo colado como o novo bloco, pra
  ; poder "Inverter" na sequencia sem remarcar - permite ter os dois: o
  ; conjunto original e uma copia (depois invertida) lado a lado.
  Protected ClearBlockIcon = CharEd_CreateClearBlockIcon(#CharEd_IconSize)
  Protected G_ClearBlock = ButtonImageGadget(#PB_Any, LeftX, BlockBarY2, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(ClearBlockIcon))
  GadgetToolTip(G_ClearBlock, "Limpar bloco: desmarca o intervalo - Inverter volta a afetar so o caractere atual")
  Protected CopyBlockIcon = CharEd_CreateCopyIcon(#CharEd_IconSize)
  Protected G_CopyBlock  = ButtonImageGadget(#PB_Any, LeftX + #CharEd_IconBtnW + 6, BlockBarY2, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(CopyBlockIcon))
  GadgetToolTip(G_CopyBlock, "Copiar bloco: copia todos os caracteres do intervalo marcado pra area de transferencia da sessao")
  Protected PasteBlockIcon = CharEd_CreatePasteIcon(#CharEd_IconSize)
  Protected G_PasteBlock = ButtonImageGadget(#PB_Any, LeftX + (#CharEd_IconBtnW + 6) * 2, BlockBarY2, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(PasteBlockIcon))
  GadgetToolTip(G_PasteBlock, "Colar bloco: cola o intervalo copiado a partir do caractere selecionado, e marca o destino como o novo bloco")
  Protected G_BlockStatus = TextGadget(#PB_Any, LeftX, BlockBarY3, #CharEd_TableCanvasW, 20, "")

  Protected G_Close = ThemedButton(LeftX, CloseY, 100, 30, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  Protected G_CharStatus = TextGadget(#PB_Any, RightX, TableY, RightW, 20, "")
  Protected G_EditCanvas = CanvasGadget(#PB_Any, RightX, EditY, #CharEd_EditCanvasSize, #CharEd_EditCanvasSize)
  Protected G_HexBytes   = TextGadget(#PB_Any, RightX, HexBytesY, RightW, 20, "")

  Protected RegisterIcon = CharEd_CreateRegisterIcon(#CharEd_IconSize)
  Protected G_Register = ButtonImageGadget(#PB_Any, RightX, BtnY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(RegisterIcon))
  GadgetToolTip(G_Register, "Registrar: grava os pixels editados neste caractere (nao registra o alfabeto)")
  Protected ClearIcon = CharEd_CreateClearIcon(#CharEd_IconSize)
  Protected G_Clear    = ButtonImageGadget(#PB_Any, RightX + #CharEd_IconBtnW + 6, BtnY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(ClearIcon))
  GadgetToolTip(G_Clear, "Limpar: apaga todos os pixels do caractere em edicao")
  Protected InvertIcon = CharEd_CreateInvertIcon(#CharEd_IconSize)
  Protected G_Invert   = ButtonImageGadget(#PB_Any, RightX + (#CharEd_IconBtnW + 6) * 2, BtnY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(InvertIcon))
  GadgetToolTip(G_Invert, "Inverter: sem bloco marcado, inverte so o caractere atual. Com bloco marcado, inverte todo o intervalo direto no alfabeto")

  ; Clipboard de um unico caractere: Copiar guarda o que esta desenhado agora
  ; na grade de edicao (mesmo sem ter sido "Registrado" ainda); Colar
  ; substitui a grade de edicao pelo que foi copiado (ainda precisa de
  ; "Registrar" pra valer no alfabeto). Funciona entre caracteres do mesmo
  ; alfabeto ou de alfabetos diferentes (navegue - o clipboard nao muda).
  Protected CopyCharIcon = CharEd_CreateCopyIcon(#CharEd_IconSize)
  Protected G_CopyChar  = ButtonImageGadget(#PB_Any, RightX, BtnY2, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(CopyCharIcon))
  GadgetToolTip(G_CopyChar, "Copiar: copia o caractere em edicao pra area de transferencia da sessao")
  Protected PasteCharIcon = CharEd_CreatePasteIcon(#CharEd_IconSize)
  Protected G_PasteChar = ButtonImageGadget(#PB_Any, RightX + #CharEd_IconBtnW + 6, BtnY2, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(PasteCharIcon))
  GadgetToolTip(G_PasteChar, "Colar: cola o caractere copiado neste caractere - use 'Registrar' pra valer no alfabeto")

  ; Desfazer/Refazer: agem sobre o alfabeto inteiro (256 caracteres), nao so
  ; o caractere em edicao - ver comentario de CharEd_PushUndo/#CharEd_MaxUndo
  ; no topo do arquivo pra saber exatamente quais acoes entram na pilha.
  Protected UndoIcon = CharEd_CreateCircularArrowIcon(#CharEd_IconSize, #True)
  Protected G_Undo = ButtonImageGadget(#PB_Any, RightX, BtnY3, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(UndoIcon))
  GadgetToolTip(G_Undo, "Desfazer: desfaz a ultima alteracao gravada no alfabeto (Registrar, efeitos em bloco/All, colar bloco/alfabeto)")
  Protected RedoIcon = CharEd_CreateCircularArrowIcon(#CharEd_IconSize, #False)
  Protected G_Redo = ButtonImageGadget(#PB_Any, RightX + #CharEd_IconBtnW + 6, BtnY3, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(RedoIcon))
  GadgetToolTip(G_Redo, "Refazer: refaz a alteracao desfeita mais recentemente")

  ; Efeitos de bloco: mesmo padrao dual do Inverter acima (sem bloco marcado,
  ; afeta so o caractere em edicao via EditGrid, precisa de "Registrar"; com
  ; bloco marcado - ou via "All" - aplica direto em CharsetBytes, em todo o
  ; intervalo de uma vez, e empilha undo).
  Protected FlipHIcon = CharEd_CreateFlipIcon(#CharEd_IconSize, #False)
  Protected G_FlipH = ButtonImageGadget(#PB_Any, RightX, BtnY4, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(FlipHIcon))
  GadgetToolTip(G_FlipH, "Espelhar horizontal: sem bloco, so o caractere atual. Com bloco/All, espelha cada caractere do intervalo direto no alfabeto")
  Protected FlipVIcon = CharEd_CreateFlipIcon(#CharEd_IconSize, #True)
  Protected G_FlipV = ButtonImageGadget(#PB_Any, RightX + #CharEd_IconBtnW + 6, BtnY4, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(FlipVIcon))
  GadgetToolTip(G_FlipV, "Espelhar vertical: sem bloco, so o caractere atual. Com bloco/All, espelha cada caractere do intervalo direto no alfabeto")
  Protected RotateIcon = CharEd_CreateRotateIcon(#CharEd_IconSize)
  Protected G_Rotate90 = ButtonImageGadget(#PB_Any, RightX + (#CharEd_IconBtnW + 6) * 2, BtnY4, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(RotateIcon))
  GadgetToolTip(G_Rotate90, "Girar 90 graus (sentido horario): sem bloco, so o caractere atual. Com bloco/All, gira cada caractere do intervalo direto no alfabeto")
  Protected EraseAllIcon = CharEd_CreateClearIcon(#CharEd_IconSize)
  Protected G_EraseBlock = ButtonImageGadget(#PB_Any, RightX + (#CharEd_IconBtnW + 6) * 3, BtnY4, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(EraseAllIcon))
  GadgetToolTip(G_EraseBlock, "Apagar: sem bloco, so o caractere atual (igual 'Limpar'). Com bloco/All, apaga cada caractere do intervalo direto no alfabeto")
  Protected NarrowIcon = CharEd_CreateNarrowIcon(#CharEd_IconSize)
  Protected G_Narrow = ButtonImageGadget(#PB_Any, RightX + (#CharEd_IconBtnW + 6) * 4, BtnY4, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(NarrowIcon))
  GadgetToolTip(G_Narrow, "Estreitar: condensa as 5 colunas da metade esquerda do glifo em 3 (uteis pra caber 64 colunas de texto). Sem bloco, so o caractere atual. Com bloco/All, aplica direto no alfabeto")
  Protected ItalicIcon = CharEd_CreateItalicIcon(#CharEd_IconSize)
  Protected G_Italic = ButtonImageGadget(#PB_Any, RightX + (#CharEd_IconBtnW + 6) * 5, BtnY4, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(ItalicIcon))
  GadgetToolTip(G_Italic, "Italico: linhas 0-1 deslocam 2 bits a direita, linhas 2-4 deslocam 1 bit, linhas 5-7 ficam iguais. Sem bloco, so o caractere atual. Com bloco/All, aplica direto no alfabeto")
  Protected BoldIcon = CharEd_CreateBoldIcon(#CharEd_IconSize)
  Protected G_Bold = ButtonImageGadget(#PB_Any, RightX, BtnY5, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(BoldIcon))
  GadgetToolTip(G_Bold, "Negrito: cada linha vira OR entre ela mesma e ela deslocada 1 bit a direita, engrossando os tracos. Sem bloco, so o caractere atual. Com bloco/All, aplica direto no alfabeto")
  Protected WideIcon = CharEd_CreateWideIcon(#CharEd_IconSize)
  Protected G_Wide = ButtonImageGadget(#PB_Any, RightX + #CharEd_IconBtnW + 6, BtnY5, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(WideIcon))
  GadgetToolTip(G_Wide, "Largo: junta as colunas 0-2 do original com as colunas 3-7 do original deslocado 1 bit a direita, esticando o glifo. Sem bloco, so o caractere atual. Com bloco/All, aplica direto no alfabeto")
  Protected BoldLeftIcon = CharEd_CreateBoldLeftIcon(#CharEd_IconSize)
  Protected G_BoldLeft = ButtonImageGadget(#PB_Any, RightX + (#CharEd_IconBtnW + 6) * 2, BtnY5, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(BoldLeftIcon))
  GadgetToolTip(G_BoldLeft, "Bold (esquerda): colunas 0-2 do original com OR do deslocado 1 bit a direita, engrossando o lado esquerdo do glifo. Sem bloco, so o caractere atual. Com bloco/All, aplica direto no alfabeto")
  Protected BoldRightIcon = CharEd_CreateBoldRightIcon(#CharEd_IconSize)
  Protected G_BoldRight = ButtonImageGadget(#PB_Any, RightX + (#CharEd_IconBtnW + 6) * 3, BtnY5, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(BoldRightIcon))
  GadgetToolTip(G_BoldRight, "Bold (direita): OR entre o original e ele deslocado 1 bit a direita (so colunas 3-7), engrossando o lado direito do glifo. Sem bloco, so o caractere atual. Com bloco/All, aplica direto no alfabeto")
  Protected WideBoldIcon = CharEd_CreateWideBoldIcon(#CharEd_IconSize)
  Protected G_WideBold = ButtonImageGadget(#PB_Any, RightX + (#CharEd_IconBtnW + 6) * 4, BtnY5, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(WideBoldIcon))
  GadgetToolTip(G_WideBold, "Largo (bold): aplica o Largo comum e depois o Negrito em cima do resultado. Sem bloco, so o caractere atual. Com bloco/All, aplica direto no alfabeto")

  Dim CharsetBytes.a(255, 7)
  Dim EditGrid.a(7, 7)
  Protected Selected.i = 0
  Protected EditDirty.b = #False
  Protected CurrentPath.s = ""

  Protected AlphaNumber.i = 1
  Protected AlphaTag.s = ""
  Protected AlphaDirty.b = #False

  ; Clipboard de sessao (caractere solto e alfabeto inteiro) e intervalo de
  ; bloco marcado - tudo local a esta janela, mesmo padrao do clipboard de
  ; sprite (SpriteEditorGui.pbi): so dura enquanto a janela estiver aberta.
  Dim ClipChar.a(7)
  Protected ClipCharValid.b = #False
  Dim ClipAlpha.a(255, 7)
  Protected ClipAlphaValid.b = #False
  Dim ClipBlock.a(255, 7)
  Protected ClipBlockLen.i = 0
  Protected ClipBlockValid.b = #False
  Protected BlockStart.i = -1
  Protected BlockEnd.i = -1

  ; Pilhas de Desfazer/Refazer - ver comentario de #CharEd_MaxUndo/
  ; CharEd_PushUndo no topo do arquivo. Zeradas sempre que o alfabeto em
  ; edicao troca (navegacao/Novo/Carregar).
  NewList UndoStack.CharEd_AlphaSnapshot()
  NewList RedoStack.CharEd_AlphaSnapshot()

  ; Abre (ou reaproveita) o projeto atual e carrega o primeiro alfabeto ja
  ; registrado nele, se houver; senao comeca com o alfabeto #1 (ainda nao
  ; registrado) usando o msx.alf padrao (alfabeto 0 do "projeto 0" de
  ; defaults, sempre em memoria - ver ProjectDB::FetchDefaultAlphabet()).
  ProjectDB::EnsureOpen()
  NewList ExistingAlphabets.i()
  ProjectDB::ListAlphabetNumbers(ExistingAlphabets())
  If ListSize(ExistingAlphabets()) > 0
    FirstElement(ExistingAlphabets())
    AlphaNumber = ExistingAlphabets()
    ProjectDB::FetchAlphabet(AlphaNumber, CharsetBytes())
    AlphaTag = ProjectDB::LastAlphabetTag()
  Else
    ProjectDB::FetchDefaultAlphabet(0, CharsetBytes())
  EndIf
  CharEd_UnpackChar(CharsetBytes(), Selected, EditGrid())

  SetGadgetText(G_AlphaNumberText, "#" + Str(AlphaNumber))
  SetGadgetText(G_Tag, AlphaTag)
  CharEd_UpdateFileLabel(G_FileLabel, CurrentPath)
  SetGadgetText(G_BlockStatus, CharEd_BlockStatusText(BlockStart, BlockEnd))
  CharEd_RedrawTable(G_Table, CharsetBytes(), Selected, BlockStart, BlockEnd)
  CharEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
  SetGadgetText(G_CharStatus, CharEd_CharStatusText(Selected))
  SetGadgetText(G_HexBytes, CharEd_HexBytesText(EditGrid()))
  CharEd_UpdateUndoRedoButtons(G_Undo, G_Redo, UndoStack(), RedoStack())

  Protected Event, Quit = #False
  Protected MouseX, MouseY, TableRow, TableCol, NewSelected, PxRow, PxCol
  Protected DragValue.i, LastEditRow.i = -1, LastEditCol.i = -1
  Protected NavTarget.i
  NewList Nav.i()

  ; Estado da acao pendente no menu popup de SCREEN (0-3): a escolha do
  ; usuario chega depois, como #PB_Event_Menu, entao o botao que abriu o
  ; popup (Gerar DATA+loop ou Salvar BIN) precisa ficar marcado aqui pra
  ; saber o que fazer quando o EventMenu() chegar.
  Protected PendingScreenAction.i = 0   ; 0 = nenhuma, 1 = Gerar DATA+loop, 2 = Salvar BIN
  Protected PendingBinFilename.s = ""   ; nome do .bin ja salvo, usado so pela acao 2

  Repeat
    Event = WaitWindowEvent()
    Select Event

      Case #PB_Event_Gadget
        Select EventGadget()

          Case G_LoadGraphos
            Protected OpenPath.s = OpenFileRequester("Carregar alfabeto do Graphos III (.alf)", CurrentPath, #CharEd_FilePattern, 0)
            If OpenPath <> ""
              If Not (EditDirty Or AlphaDirty) Or CharEd_ConfirmDiscardAlphabet()
                ; CharEd_LoadAlf() so grava em CharsetBytes() depois de validar
                ; tipo/tamanho do arquivo inteiro - em caso de erro a chamada
                ; abaixo nao toca no array, entao o alfabeto atual em memoria
                ; fica intacto (nao ha necessidade de limpar antes).
                If CharEd_LoadAlf(OpenPath, CharsetBytes())
                  CurrentPath = OpenPath
                  ; Importar sempre vira um alfabeto NOVO (numeracao
                  ; automatica, mesma regra de "Novo alfabeto") - nunca
                  ; sobrescreve um banco ja registrado no projeto so por
                  ; importar um .alf externo; e assim que da pra ter varios
                  ; alfabetos Graphos III diferentes no mesmo projeto.
                  ProjectDB::ListAlphabetNumbers(Nav())
                  AlphaNumber = 1
                  If ListSize(Nav()) > 0
                    LastElement(Nav())
                    AlphaNumber = Nav() + 1
                  EndIf
                  AlphaTag = ""
                  Selected = 0
                  EditDirty = #False
                  AlphaDirty = #True
                  CharEd_UnpackChar(CharsetBytes(), Selected, EditGrid())
                  SetGadgetText(G_AlphaNumberText, "#" + Str(AlphaNumber))
                  SetGadgetText(G_Tag, AlphaTag)
                  CharEd_UpdateFileLabel(G_FileLabel, CurrentPath)
                  CharEd_RedrawTable(G_Table, CharsetBytes(), Selected, BlockStart, BlockEnd)
                  CharEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
                  SetGadgetText(G_CharStatus, CharEd_CharStatusText(Selected))
                  SetGadgetText(G_HexBytes, CharEd_HexBytesText(EditGrid()))
                  ClearList(UndoStack()) : ClearList(RedoStack())
                  CharEd_UpdateUndoRedoButtons(G_Undo, G_Redo, UndoStack(), RedoStack())
                Else
                  MessageRequester("Erro ao carregar alfabeto",
                                    "Nao foi possivel carregar:" + Chr(10) + OpenPath + Chr(10) + CharEd_GetLastError(),
                                    #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
                EndIf
              EndIf
            EndIf

          Case G_SaveAs
            Protected SavePath.s = SaveFileRequester("Salvar alfabeto MSX (Graphos III)", CurrentPath, #CharEd_FilePattern, 0)
            If SavePath <> ""
              SavePath = EnsureExtension(SavePath, "alf")
              If CharEd_SaveAlf(SavePath, CharsetBytes())
                CurrentPath = SavePath
                CharEd_UpdateFileLabel(G_FileLabel, CurrentPath)
              Else
                MessageRequester("Erro ao salvar alfabeto",
                                  "Nao foi possivel salvar em:" + Chr(10) + SavePath + Chr(10) + CharEd_GetLastError(),
                                  #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
              EndIf
            EndIf

          Case G_GenLoop
            PendingScreenAction = 1
            CharEd_ShowScreenPopupMenu(Win)

          Case G_GenData
            Protected DataOnlyText.s = CharEd_BuildDataOnlyText(CharsetBytes(), AlphaNumber, AlphaTag)
            If InjectTextAtCursor(DataOnlyText)
              SetGadgetText(G_CharStatus, "DATA do alfabeto #" + Str(AlphaNumber) + " inserido no cursor.")
            Else
              MessageRequester("Nao foi possivel inserir",
                                "Nenhuma aba de texto ativa no editor pra receber o codigo.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
            EndIf

          Case G_SaveBin
            Protected BinPath.s = SaveFileRequester("Salvar alfabeto MSX (BIN Graphos III)", CurrentPath,
                                                     "Binario MSX BLOAD (*.bin)|*.bin|Todos os arquivos (*.*)|*.*", 0)
            If BinPath <> ""
              BinPath = EnsureExtension(BinPath, "bin")
              If CharEd_SaveAlf(BinPath, CharsetBytes())
                PendingBinFilename = UCase(GetFilePart(BinPath))
                PendingScreenAction = 2
                CharEd_ShowScreenPopupMenu(Win)
              Else
                MessageRequester("Erro ao salvar alfabeto",
                                  "Nao foi possivel salvar em:" + Chr(10) + BinPath + Chr(10) + CharEd_GetLastError(),
                                  #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
              EndIf
            EndIf

          Case G_Register
            CharEd_PushUndo(UndoStack(), RedoStack(), CharsetBytes())
            CharEd_PackChar(EditGrid(), CharsetBytes(), Selected)
            EditDirty = #False
            AlphaDirty = #True
            CharEd_RedrawTable(G_Table, CharsetBytes(), Selected, BlockStart, BlockEnd)
            CharEd_UpdateUndoRedoButtons(G_Undo, G_Redo, UndoStack(), RedoStack())

          Case G_First
            If Not (EditDirty Or AlphaDirty) Or CharEd_ConfirmDiscardAlphabet()
              ProjectDB::ListAlphabetNumbers(Nav())
              NavTarget = SpriteEd_FindNavTarget(Nav(), 0, AlphaNumber)
              If NavTarget >= 0
                If CharEd_LoadAlphabetUI(NavTarget, G_AlphaNumberText, G_Tag, G_Table, G_EditCanvas, G_CharStatus, G_HexBytes, CharsetBytes(), EditGrid(), BlockStart, BlockEnd)
                  AlphaNumber = NavTarget
                  AlphaTag = ProjectDB::LastAlphabetTag()
                  Selected = 0
                  EditDirty = #False
                  AlphaDirty = #False
                  ClearList(UndoStack()) : ClearList(RedoStack())
                  CharEd_UpdateUndoRedoButtons(G_Undo, G_Redo, UndoStack(), RedoStack())
                EndIf
              EndIf
            EndIf

          Case G_Prev
            If Not (EditDirty Or AlphaDirty) Or CharEd_ConfirmDiscardAlphabet()
              ProjectDB::ListAlphabetNumbers(Nav())
              NavTarget = SpriteEd_FindNavTarget(Nav(), 1, AlphaNumber)
              If NavTarget >= 0
                If CharEd_LoadAlphabetUI(NavTarget, G_AlphaNumberText, G_Tag, G_Table, G_EditCanvas, G_CharStatus, G_HexBytes, CharsetBytes(), EditGrid(), BlockStart, BlockEnd)
                  AlphaNumber = NavTarget
                  AlphaTag = ProjectDB::LastAlphabetTag()
                  Selected = 0
                  EditDirty = #False
                  AlphaDirty = #False
                  ClearList(UndoStack()) : ClearList(RedoStack())
                  CharEd_UpdateUndoRedoButtons(G_Undo, G_Redo, UndoStack(), RedoStack())
                EndIf
              EndIf
            EndIf

          Case G_Next
            If Not (EditDirty Or AlphaDirty) Or CharEd_ConfirmDiscardAlphabet()
              ProjectDB::ListAlphabetNumbers(Nav())
              NavTarget = SpriteEd_FindNavTarget(Nav(), 2, AlphaNumber)
              If NavTarget >= 0
                If CharEd_LoadAlphabetUI(NavTarget, G_AlphaNumberText, G_Tag, G_Table, G_EditCanvas, G_CharStatus, G_HexBytes, CharsetBytes(), EditGrid(), BlockStart, BlockEnd)
                  AlphaNumber = NavTarget
                  AlphaTag = ProjectDB::LastAlphabetTag()
                  Selected = 0
                  EditDirty = #False
                  AlphaDirty = #False
                  ClearList(UndoStack()) : ClearList(RedoStack())
                  CharEd_UpdateUndoRedoButtons(G_Undo, G_Redo, UndoStack(), RedoStack())
                EndIf
              EndIf
            EndIf

          Case G_Last
            If Not (EditDirty Or AlphaDirty) Or CharEd_ConfirmDiscardAlphabet()
              ProjectDB::ListAlphabetNumbers(Nav())
              NavTarget = SpriteEd_FindNavTarget(Nav(), 3, AlphaNumber)
              If NavTarget >= 0
                If CharEd_LoadAlphabetUI(NavTarget, G_AlphaNumberText, G_Tag, G_Table, G_EditCanvas, G_CharStatus, G_HexBytes, CharsetBytes(), EditGrid(), BlockStart, BlockEnd)
                  AlphaNumber = NavTarget
                  AlphaTag = ProjectDB::LastAlphabetTag()
                  Selected = 0
                  EditDirty = #False
                  AlphaDirty = #False
                  ClearList(UndoStack()) : ClearList(RedoStack())
                  CharEd_UpdateUndoRedoButtons(G_Undo, G_Redo, UndoStack(), RedoStack())
                EndIf
              EndIf
            EndIf

          Case G_AlphaNew
            If Not (EditDirty Or AlphaDirty) Or CharEd_ConfirmDiscardAlphabet()
              ProjectDB::ListAlphabetNumbers(Nav())
              Protected NextAlphaNum.i = 1
              If ListSize(Nav()) > 0
                LastElement(Nav())
                NextAlphaNum = Nav() + 1
              EndIf
              AlphaNumber = NextAlphaNum
              AlphaTag = ""
              Selected = 0
              EditDirty = #False
              AlphaDirty = #False
              ; "Novo alfabeto" sempre parte do msx.alf padrao (alfabeto 0
              ; do projeto de defaults), nunca em branco - pedido explicito,
              ; diferente do "Novo sprite" (que comeca em branco).
              ProjectDB::FetchDefaultAlphabet(0, CharsetBytes())
              CharEd_UnpackChar(CharsetBytes(), Selected, EditGrid())
              SetGadgetText(G_AlphaNumberText, "#" + Str(AlphaNumber))
              SetGadgetText(G_Tag, AlphaTag)
              CharEd_RedrawTable(G_Table, CharsetBytes(), Selected, BlockStart, BlockEnd)
              CharEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
              SetGadgetText(G_CharStatus, CharEd_CharStatusText(Selected))
              SetGadgetText(G_HexBytes, CharEd_HexBytesText(EditGrid()))
              ClearList(UndoStack()) : ClearList(RedoStack())
              CharEd_UpdateUndoRedoButtons(G_Undo, G_Redo, UndoStack(), RedoStack())
            EndIf

          Case G_AlphaRegister
            ; Registrar o alfabeto tambem aplica qualquer edicao pendente do
            ; caractere atual primeiro (senao esses pixels ficariam de fora
            ; do que e gravado no projeto, sem o usuario perceber).
            If EditDirty
              CharEd_PackChar(EditGrid(), CharsetBytes(), Selected)
              EditDirty = #False
              CharEd_RedrawTable(G_Table, CharsetBytes(), Selected, BlockStart, BlockEnd)
            EndIf
            AlphaTag = Left(GetGadgetText(G_Tag), 16)
            SetGadgetText(G_Tag, AlphaTag)
            If ProjectDB::StoreAlphabet(AlphaNumber, AlphaTag, CharsetBytes())
              AlphaDirty = #False
            Else
              MessageRequester("Erro ao registrar",
                                "Nao foi possivel gravar o alfabeto:" + Chr(10) + ProjectDB::GetLastError(),
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
            EndIf

          Case G_CopyAlpha
            ; Aplica qualquer pixel pendente do caractere atual antes de
            ; copiar, mesmo motivo do G_AlphaRegister acima - o clipboard
            ; deve refletir exatamente o que esta sendo visto na tela.
            If EditDirty
              CharEd_PackChar(EditGrid(), CharsetBytes(), Selected)
              EditDirty = #False
              AlphaDirty = #True
              CharEd_RedrawTable(G_Table, CharsetBytes(), Selected, BlockStart, BlockEnd)
            EndIf
            CopyArray(CharsetBytes(), ClipAlpha())
            ClipAlphaValid = #True

          Case G_PasteAlpha
            If ClipAlphaValid
              If Not (EditDirty Or AlphaDirty) Or CharEd_ConfirmDiscardAlphabet()
                CharEd_PushUndo(UndoStack(), RedoStack(), CharsetBytes())
                CopyArray(ClipAlpha(), CharsetBytes())
                EditDirty = #False
                AlphaDirty = #True
                CharEd_UnpackChar(CharsetBytes(), Selected, EditGrid())
                CharEd_RedrawTable(G_Table, CharsetBytes(), Selected, BlockStart, BlockEnd)
                CharEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
                SetGadgetText(G_HexBytes, CharEd_HexBytesText(EditGrid()))
                CharEd_UpdateUndoRedoButtons(G_Undo, G_Redo, UndoStack(), RedoStack())
              EndIf
            Else
              MessageRequester("Colar alfabeto", "Nenhum alfabeto foi copiado ainda nesta sessao.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
            EndIf

          Case G_Tag
            If EventType() = #PB_EventType_Change
              If Len(GetGadgetText(G_Tag)) > 16
                SetGadgetText(G_Tag, Left(GetGadgetText(G_Tag), 16))
              EndIf
            EndIf

          Case G_Clear
            CharEd_ClearEditGrid(EditGrid())
            EditDirty = #True
            CharEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
            SetGadgetText(G_HexBytes, CharEd_HexBytesText(EditGrid()))

          Case G_Invert
            ; Sem bloco marcado: comportamento de sempre, so o caractere em
            ; edicao (via EditGrid, precisa de "Registrar" pra valer). Com
            ; bloco marcado (Marcar inicio/fim de bloco, ou via "All"):
            ; inverte todos os caracteres do intervalo direto em
            ; CharsetBytes, ignorando o EditGrid - operacao de alfabeto, nao
            ; de pixel (mesmo padrao dual dos efeitos abaixo).
            If BlockStart >= 0 And BlockEnd >= 0
              Protected InvStart = BlockStart, InvEnd = BlockEnd
              If InvStart > InvEnd
                Swap InvStart, InvEnd
              EndIf
              Protected DoBlockInvert.b = #True
              ; Se o caractere selecionado esta dentro do intervalo e tem
              ; pixel editado ainda nao registrado, ele seria perdido (o
              ; intervalo mexe direto em CharsetBytes, nao no EditGrid) -
              ; confirma antes de descartar.
              If EditDirty And Selected >= InvStart And Selected <= InvEnd
                DoBlockInvert = CharEd_ConfirmDiscardChar()
              EndIf
              If DoBlockInvert
                CharEd_PushUndo(UndoStack(), RedoStack(), CharsetBytes())
                CharEd_ApplyGridEffectToRange(CharsetBytes(), InvStart, InvEnd, #CharEd_Effect_Invert)
                EditDirty = #False
                AlphaDirty = #True
                CharEd_UnpackChar(CharsetBytes(), Selected, EditGrid())
                CharEd_RedrawTable(G_Table, CharsetBytes(), Selected, BlockStart, BlockEnd)
                CharEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
                SetGadgetText(G_HexBytes, CharEd_HexBytesText(EditGrid()))
                CharEd_UpdateUndoRedoButtons(G_Undo, G_Redo, UndoStack(), RedoStack())
              EndIf
            Else
              CharEd_InvertEditGrid(EditGrid())
              EditDirty = #True
              CharEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
              SetGadgetText(G_HexBytes, CharEd_HexBytesText(EditGrid()))
            EndIf

          Case G_FlipH, G_FlipV, G_Rotate90, G_EraseBlock, G_Narrow, G_Italic, G_Bold, G_Wide, G_BoldLeft, G_BoldRight, G_WideBold
            ; Mesmo padrao dual do Inverter acima - um unico bloco de codigo
            ; pros 11 efeitos (o EffectId e que muda), pra nao repetir a
            ; logica de bloco/undo 11 vezes.
            Protected EffectId.i
            Select EventGadget()
              Case G_FlipH     : EffectId = #CharEd_Effect_FlipH
              Case G_FlipV     : EffectId = #CharEd_Effect_FlipV
              Case G_Rotate90  : EffectId = #CharEd_Effect_Rotate90
              Case G_EraseBlock: EffectId = #CharEd_Effect_Clear
              Case G_Narrow    : EffectId = #CharEd_Effect_Narrow
              Case G_Italic    : EffectId = #CharEd_Effect_Italic
              Case G_Bold      : EffectId = #CharEd_Effect_Bold
              Case G_Wide      : EffectId = #CharEd_Effect_Wide
              Case G_BoldLeft  : EffectId = #CharEd_Effect_BoldLeft
              Case G_BoldRight : EffectId = #CharEd_Effect_BoldRight
              Case G_WideBold  : EffectId = #CharEd_Effect_WideBold
            EndSelect
            If BlockStart >= 0 And BlockEnd >= 0
              Protected EffStart = BlockStart, EffEnd = BlockEnd
              If EffStart > EffEnd
                Swap EffStart, EffEnd
              EndIf
              Protected DoBlockEffect.b = #True
              If EditDirty And Selected >= EffStart And Selected <= EffEnd
                DoBlockEffect = CharEd_ConfirmDiscardChar()
              EndIf
              If DoBlockEffect
                CharEd_PushUndo(UndoStack(), RedoStack(), CharsetBytes())
                CharEd_ApplyGridEffectToRange(CharsetBytes(), EffStart, EffEnd, EffectId)
                EditDirty = #False
                AlphaDirty = #True
                CharEd_UnpackChar(CharsetBytes(), Selected, EditGrid())
                CharEd_RedrawTable(G_Table, CharsetBytes(), Selected, BlockStart, BlockEnd)
                CharEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
                SetGadgetText(G_HexBytes, CharEd_HexBytesText(EditGrid()))
                CharEd_UpdateUndoRedoButtons(G_Undo, G_Redo, UndoStack(), RedoStack())
              EndIf
            Else
              Select EffectId
                Case #CharEd_Effect_FlipH    : CharEd_FlipHEditGrid(EditGrid())
                Case #CharEd_Effect_FlipV    : CharEd_FlipVEditGrid(EditGrid())
                Case #CharEd_Effect_Rotate90 : CharEd_RotateEditGrid(EditGrid())
                Case #CharEd_Effect_Clear    : CharEd_ClearEditGrid(EditGrid())
                Case #CharEd_Effect_Narrow   : CharEd_NarrowEditGrid(EditGrid())
                Case #CharEd_Effect_Italic   : CharEd_ItalicEditGrid(EditGrid())
                Case #CharEd_Effect_Bold     : CharEd_BoldEditGrid(EditGrid())
                Case #CharEd_Effect_Wide     : CharEd_WideEditGrid(EditGrid())
                Case #CharEd_Effect_BoldLeft : CharEd_BoldLeftEditGrid(EditGrid())
                Case #CharEd_Effect_BoldRight: CharEd_BoldRightEditGrid(EditGrid())
                Case #CharEd_Effect_WideBold : CharEd_WideBoldEditGrid(EditGrid())
              EndSelect
              EditDirty = #True
              CharEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
              SetGadgetText(G_HexBytes, CharEd_HexBytesText(EditGrid()))
            EndIf

          Case G_All
            BlockStart = 0
            BlockEnd = 255
            SetGadgetText(G_BlockStatus, CharEd_BlockStatusText(BlockStart, BlockEnd))
            CharEd_RedrawTable(G_Table, CharsetBytes(), Selected, BlockStart, BlockEnd)

          Case G_Undo
            If ListSize(UndoStack()) > 0
              AddElement(RedoStack())
              CharEd_SnapshotFromArray(CharsetBytes(), @RedoStack())
              LastElement(UndoStack())
              CharEd_ArrayFromSnapshot(@UndoStack(), CharsetBytes())
              DeleteElement(UndoStack())
              EditDirty = #False
              AlphaDirty = #True
              CharEd_UnpackChar(CharsetBytes(), Selected, EditGrid())
              CharEd_RedrawTable(G_Table, CharsetBytes(), Selected, BlockStart, BlockEnd)
              CharEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
              SetGadgetText(G_HexBytes, CharEd_HexBytesText(EditGrid()))
              CharEd_UpdateUndoRedoButtons(G_Undo, G_Redo, UndoStack(), RedoStack())
            EndIf

          Case G_Redo
            If ListSize(RedoStack()) > 0
              AddElement(UndoStack())
              CharEd_SnapshotFromArray(CharsetBytes(), @UndoStack())
              LastElement(RedoStack())
              CharEd_ArrayFromSnapshot(@RedoStack(), CharsetBytes())
              DeleteElement(RedoStack())
              EditDirty = #False
              AlphaDirty = #True
              CharEd_UnpackChar(CharsetBytes(), Selected, EditGrid())
              CharEd_RedrawTable(G_Table, CharsetBytes(), Selected, BlockStart, BlockEnd)
              CharEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
              SetGadgetText(G_HexBytes, CharEd_HexBytesText(EditGrid()))
              CharEd_UpdateUndoRedoButtons(G_Undo, G_Redo, UndoStack(), RedoStack())
            EndIf

          Case G_CopyChar
            CharEd_PackGridBytes(EditGrid(), ClipChar())
            ClipCharValid = #True

          Case G_PasteChar
            If ClipCharValid
              CharEd_UnpackGridBytes(ClipChar(), EditGrid())
              EditDirty = #True
              CharEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
              SetGadgetText(G_HexBytes, CharEd_HexBytesText(EditGrid()))
            Else
              MessageRequester("Colar caractere", "Nenhum caractere foi copiado ainda nesta sessao.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
            EndIf

          Case G_MarkStart
            BlockStart = Selected
            SetGadgetText(G_BlockStatus, CharEd_BlockStatusText(BlockStart, BlockEnd))
            CharEd_RedrawTable(G_Table, CharsetBytes(), Selected, BlockStart, BlockEnd)

          Case G_MarkEnd
            BlockEnd = Selected
            SetGadgetText(G_BlockStatus, CharEd_BlockStatusText(BlockStart, BlockEnd))
            CharEd_RedrawTable(G_Table, CharsetBytes(), Selected, BlockStart, BlockEnd)

          Case G_ClearBlock
            BlockStart = -1
            BlockEnd = -1
            SetGadgetText(G_BlockStatus, CharEd_BlockStatusText(BlockStart, BlockEnd))
            CharEd_RedrawTable(G_Table, CharsetBytes(), Selected, BlockStart, BlockEnd)

          Case G_CopyBlock
            If BlockStart >= 0 And BlockEnd >= 0
              Protected CpStart = BlockStart, CpEnd = BlockEnd
              If CpStart > CpEnd
                Swap CpStart, CpEnd
              EndIf
              ; Aplica qualquer pixel pendente do caractere atual antes de
              ; copiar, se ele estiver dentro do intervalo - mesmo motivo do
              ; G_CopyAlpha acima.
              If EditDirty And Selected >= CpStart And Selected <= CpEnd
                CharEd_PackChar(EditGrid(), CharsetBytes(), Selected)
                EditDirty = #False
                AlphaDirty = #True
                CharEd_RedrawTable(G_Table, CharsetBytes(), Selected, BlockStart, BlockEnd)
              EndIf
              Protected CpIdx, CpRow
              ClipBlockLen = CpEnd - CpStart + 1
              For CpIdx = 0 To ClipBlockLen - 1
                For CpRow = 0 To 7
                  ClipBlock(CpIdx, CpRow) = CharsetBytes(CpStart + CpIdx, CpRow)
                Next
              Next
              ClipBlockValid = #True
            Else
              MessageRequester("Copiar bloco", "Nenhum bloco marcado - use 'Marcar inicio'/'Marcar fim' primeiro.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
            EndIf

          Case G_PasteBlock
            If ClipBlockValid
              Protected PasteStart = Selected
              Protected PasteEnd = PasteStart + ClipBlockLen - 1
              If PasteEnd > 255
                MessageRequester("Colar bloco",
                                  "O bloco copiado (" + Str(ClipBlockLen) + " caracteres) nao cabe a partir do" + Chr(10) +
                                  "caractere " + Str(PasteStart) + " ($" + RSet(Hex(PasteStart), 2, "0") + ") - selecione um caractere inicial menor.",
                                  #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
              Else
                ; O intervalo de destino e escrito direto em CharsetBytes,
                ; ignorando o EditGrid - se o caractere selecionado esta
                ; dentro do destino e tem pixel pendente nao registrado, ele
                ; seria perdido (mesmo cuidado do Inverter em modo bloco).
                Protected DoPasteBlock.b = #True
                If EditDirty And Selected >= PasteStart And Selected <= PasteEnd
                  DoPasteBlock = CharEd_ConfirmDiscardChar()
                EndIf
                If DoPasteBlock
                  CharEd_PushUndo(UndoStack(), RedoStack(), CharsetBytes())
                  Protected PbIdx, PbRow
                  For PbIdx = 0 To ClipBlockLen - 1
                    For PbRow = 0 To 7
                      CharsetBytes(PasteStart + PbIdx, PbRow) = ClipBlock(PbIdx, PbRow)
                    Next
                  Next
                  EditDirty = #False
                  AlphaDirty = #True
                  ; Remarca o intervalo recem-colado como o novo bloco - assim
                  ; da pra "Inverter" na sequencia sem precisar remarcar (o
                  ; pedido original: colar A..Z em cima de a..z e depois
                  ; inverter so essa faixa colada, tendo os dois conjuntos -
                  ; normal e invertido - lado a lado no mesmo alfabeto).
                  BlockStart = PasteStart
                  BlockEnd = PasteEnd
                  CharEd_UnpackChar(CharsetBytes(), Selected, EditGrid())
                  SetGadgetText(G_BlockStatus, CharEd_BlockStatusText(BlockStart, BlockEnd))
                  CharEd_RedrawTable(G_Table, CharsetBytes(), Selected, BlockStart, BlockEnd)
                  CharEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
                  SetGadgetText(G_HexBytes, CharEd_HexBytesText(EditGrid()))
                  CharEd_UpdateUndoRedoButtons(G_Undo, G_Redo, UndoStack(), RedoStack())
                EndIf
              EndIf
            Else
              MessageRequester("Colar bloco", "Nenhum bloco foi copiado ainda nesta sessao.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
            EndIf

          Case G_Table
            If EventType() = #PB_EventType_LeftButtonDown
              MouseX = GetGadgetAttribute(G_Table, #PB_Canvas_MouseX) - #CharEd_TableHeaderW
              MouseY = GetGadgetAttribute(G_Table, #PB_Canvas_MouseY) - #CharEd_TableHeaderH
              If MouseX >= 0 And MouseY >= 0
                TableCol = MouseX / #CharEd_TableCellPx
                TableRow = MouseY / #CharEd_TableCellPx
                If TableCol >= 0 And TableCol < 16 And TableRow >= 0 And TableRow < 16
                  NewSelected = TableRow * 16 + TableCol
                  If NewSelected <> Selected
                    If Not EditDirty Or CharEd_ConfirmDiscardChar()
                      Selected = NewSelected
                      EditDirty = #False
                      CharEd_UnpackChar(CharsetBytes(), Selected, EditGrid())
                      CharEd_RedrawTable(G_Table, CharsetBytes(), Selected, BlockStart, BlockEnd)
                      CharEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
                      SetGadgetText(G_CharStatus, CharEd_CharStatusText(Selected))
                      SetGadgetText(G_HexBytes, CharEd_HexBytesText(EditGrid()))
                    EndIf
                  EndIf
                EndIf
              EndIf
            EndIf

          Case G_EditCanvas
            Select EventType()

              Case #PB_EventType_LeftButtonDown
                MouseX = GetGadgetAttribute(G_EditCanvas, #PB_Canvas_MouseX)
                MouseY = GetGadgetAttribute(G_EditCanvas, #PB_Canvas_MouseY)
                PxCol = MouseX / #CharEd_EditPixelPx
                PxRow = MouseY / #CharEd_EditPixelPx
                If PxRow >= 0 And PxRow < 8 And PxCol >= 0 And PxCol < 8
                  If EditGrid(PxRow, PxCol)
                    DragValue = 0
                  Else
                    DragValue = 1
                  EndIf
                  EditGrid(PxRow, PxCol) = DragValue
                  EditDirty = #True
                  LastEditRow = PxRow : LastEditCol = PxCol
                  CharEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
                  SetGadgetText(G_HexBytes, CharEd_HexBytesText(EditGrid()))
                EndIf

              ; Arrastar com o botao esquerdo pressionado pinta uma sequencia
              ; de pixels com o mesmo valor do primeiro clique (nao fica
              ; alternando a cada pixel passado por cima) - mesmo padrao do
              ; lapis/borracha do editor de sprites.
              Case #PB_EventType_MouseMove
                If GetGadgetAttribute(G_EditCanvas, #PB_Canvas_Buttons) & #PB_Canvas_LeftButton
                  MouseX = GetGadgetAttribute(G_EditCanvas, #PB_Canvas_MouseX)
                  MouseY = GetGadgetAttribute(G_EditCanvas, #PB_Canvas_MouseY)
                  PxCol = MouseX / #CharEd_EditPixelPx
                  PxRow = MouseY / #CharEd_EditPixelPx
                  If PxRow >= 0 And PxRow < 8 And PxCol >= 0 And PxCol < 8 And (PxRow <> LastEditRow Or PxCol <> LastEditCol)
                    EditGrid(PxRow, PxCol) = DragValue
                    EditDirty = #True
                    LastEditRow = PxRow : LastEditCol = PxCol
                    CharEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
                    SetGadgetText(G_HexBytes, CharEd_HexBytesText(EditGrid()))
                  EndIf
                EndIf

            EndSelect

          Case G_Close
            If Not (EditDirty Or AlphaDirty) Or CharEd_ConfirmDiscardAlphabet()
              Quit = #True
            EndIf

        EndSelect

      ; Resposta do menu popup de SCREEN aberto por G_GenLoop/G_SaveBin (ver
      ; CharEd_ShowScreenPopupMenu) - PendingScreenAction diz qual dos dois
      ; botoes abriu o popup, ja que a escolha chega assincrona.
      Case #PB_Event_Menu
        Protected ChosenScreen.i = EventMenu()
        Select PendingScreenAction
          Case 1
            Protected LoopText.s = CharEd_BuildLoopText(CharsetBytes(), AlphaNumber, AlphaTag, ChosenScreen)
            If InjectTextAtCursor(LoopText)
              SetGadgetText(G_CharStatus, "Alfabeto #" + Str(AlphaNumber) + " inserido: DATA + loop VRAM (SCREEN " + Str(ChosenScreen) + ") no cursor.")
            Else
              MessageRequester("Nao foi possivel inserir",
                                "Nenhuma aba de texto ativa no editor pra receber o codigo.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
            EndIf
          Case 2
            Protected BloadText.s = CharEd_BuildBloadText(PendingBinFilename, ChosenScreen)
            If InjectTextAtCursor(BloadText)
              SetGadgetText(G_CharStatus, "Linha BLOAD (SCREEN " + Str(ChosenScreen) + ") inserida no cursor.")
            Else
              MessageRequester("Nao foi possivel inserir",
                                "Nenhuma aba de texto ativa no editor pra receber o codigo.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
            EndIf
        EndSelect
        PendingScreenAction = 0

      Case #PB_Event_CloseWindow
        If Not (EditDirty Or AlphaDirty) Or CharEd_ConfirmDiscardAlphabet()
          Quit = #True
        EndIf

    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
  FreeImage(FirstIcon)
  FreeImage(PrevIcon)
  FreeImage(NextIcon)
  FreeImage(LastIcon)
  FreeImage(NewAlphaIcon)
  FreeImage(RegisterAlphaIcon)
  FreeImage(CopyAlphaIcon)
  FreeImage(PasteAlphaIcon)
  FreeImage(OpenIcon)
  FreeImage(SaveAsIcon)
  FreeImage(GenLoopIcon)
  FreeImage(GenDataIcon)
  FreeImage(SaveBinIcon)
  FreeImage(MarkStartIcon)
  FreeImage(MarkEndIcon)
  FreeImage(SelectAllIcon)
  FreeImage(ClearBlockIcon)
  FreeImage(CopyBlockIcon)
  FreeImage(PasteBlockIcon)
  FreeImage(RegisterIcon)
  FreeImage(ClearIcon)
  FreeImage(InvertIcon)
  FreeImage(CopyCharIcon)
  FreeImage(PasteCharIcon)
  FreeImage(UndoIcon)
  FreeImage(RedoIcon)
  FreeImage(FlipHIcon)
  FreeImage(FlipVIcon)
  FreeImage(RotateIcon)
  FreeImage(EraseAllIcon)
  FreeImage(NarrowIcon)
  FreeImage(ItalicIcon)
  FreeImage(BoldIcon)
  FreeImage(WideIcon)
  FreeImage(BoldLeftIcon)
  FreeImage(BoldRightIcon)
  FreeImage(WideBoldIcon)
EndProcedure
