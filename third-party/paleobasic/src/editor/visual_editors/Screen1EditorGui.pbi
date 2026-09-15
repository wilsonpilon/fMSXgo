;
; ------------------------------------------------------------
;  Apelido interno: Pixelossauro (tema pre-historico do projeto, ver README.md)
;  Screen1EditorGui.pbi - Criar -> Screen 1...: editor de tela de texto MSX
;  SCREEN 1 (Graphic 1), no mesmo espirito de Screen0EditorGui.pbi (editor
;  de tela estilo TheDraw/AcidDraw, mas fiel ao hardware MSX real), porem
;  com a diferenca de cor real do SCREEN 1: nao existe UMA cor de tinta/
;  fundo pra tela inteira como no SCREEN 0 - a Color Table real do TMS9918
;  guarda 32 bytes (Tinta<<4|Fundo cada), 1 POR GRUPO DE 8 CODIGOS DE
;  CARACTERE (codigo\8, nao por posicao de tela): todo caractere de codigo
;  0-7 usa a mesma cor, 8-15 usa outra, etc. Confirmado contra a MSX Wiki
;  (VDP Table Base Address Registers/SCREEN 1) antes de escrever qualquer
;  codigo - endereco padrao &H2000, 32 bytes.
;
;  A "tabela ASCII do alfabeto escolhido" pedida pelo usuario e a grade de
;  256 celulas na coluna direita (Scr1Ed_DrawCharPicker) - mostra o BITMAP
;  REAL de cada um dos 256 codigos do alfabeto ativo (padrao ou um alfabeto
;  do banco do projeto), com o FUNDO de cada celula ja pintado na cor do seu
;  octeto (Tinta/Fundo do grupo de 8 a que aquele codigo pertence) - a
;  colorizacao pedida "direto na tabela ASCII". Clicar escolhe o "byte
;  atual" (usado pelas ferramentas Caractere/Bloco); as duas paletas
;  Tinta/Fundo ao lado da grade nao pintam a tela inteira como no SCREEN 0 -
;  elas mudam a cor do OCTETO do byte atual (os 8 codigos daquele grupo,
;  refletido tanto na propria grade quanto na tela).
;
;  Diferenca de armazenamento em relacao a Screen0EditorGui.pbi: aqui a
;  grade guarda o BYTE MSX CRU (0-255), nao um codepoint Unicode. Isso e
;  possivel (e mais simples) porque, ao contrario do SCREEN 0, o SCREEN 1
;  nao precisa do truque de "imprimir o glifo Unicode literal e deixar a
;  traducao -tr resolver depois": os 31 caracteres "grafico" de
;  DignifiedPreprocessor.pbi (Dig_TransReplacementOrder - moldura/naipes/
;  carinhas) SAO, na verdade, os codigos MSX 1-31 (confirmado lendo
;  Dig_TransReplacement: cada um vira Chr(1)+Chr(64+posicao) - Chr(1) e o
;  prefixo de escape que o driver de tela do MSX usa pra imprimir um dos 31
;  "graficos" ocupando os codigos de controle 1-31 sem colidir com controles
;  de verdade; a LETRA que segue codifica QUAL grafico, exatamente
;  Chr(64+posicao) onde posicao e o indice 1-based em Dig_TransReplacementOrder
;  - e DefaultCharsetMsx.pbi confirma isso byte a byte: os bitmaps dos
;  codigos 1-31 do alfabeto padrao SAO literalmente carinhas/naipes/moldura
;  na mesma ordem). Scr1Ed_GlyphByteFor() abaixo cobre essa faixa alem da
;  ASCII 32-126 e dos 128 Dig_TransOriginal (128-255) que Scr0Ed_GlyphByteFor
;  ja cobria - juntas, essas 3 faixas resolvem TODOS os 256 codigos exceto 0
;  e 127 (sem representacao Unicode neste codebase; so acessiveis clicando
;  a celula deles direto na grade de 256, nao digitando).
;
;  "Gerar codigo" (Scr1Ed_BuildCode) NAO reaproveita a traducao -tr do
;  pipeline Dignified como Screen0EditorGui.pbi faz - constroi a expressao
;  BASIC (literais entre aspas + CHR$(n) concatenado) diretamente a partir
;  dos bytes crus da grade (Scr1Ed_BuildLineExpr), o que e mais simples e
;  robusto aqui: sem depender de nenhuma tabela de traducao Unicode->MSX no
;  meio do caminho, so ASCII puro no .dmx gerado, correto pra qualquer
;  alfabeto (a fonte so muda a APARENCIA do byte, nunca seu numero).
;
;  Ferramentas (reaproveitando os helpers de moldura/sombra de
;  Screen0EditorGui.pbi por baixo, so trocando Unicode por byte via
;  Scr1Ed_ByteToChar/GlyphByteFor): Texto, Caractere, Quadro, Sombra, Bloco,
;  Borracha - mesmas 6 da primeira versao do Screen0 (sem "Atributo", que so
;  faz sentido no mecanismo de Cor 2/piscar exclusivo do WIDTH 80 do SCREEN 0).
;
;  Grade FIXA 32x24 (768 celulas) - SCREEN 1 do MSX nao tem WIDTH configuravel
;  como SCREEN 0, entao nao ha dialogo de "Novo" perguntando largura.
; ------------------------------------------------------------
;

#Scr1Ed_Cols      = 32
#Scr1Ed_Rows      = 24
#Scr1Ed_MaxCells  = #Scr1Ed_Cols * #Scr1Ed_Rows   ; 768

#Scr1Ed_ToolPanelW = 480
#Scr1Ed_ToolPanelH = 160

; Grade de escolha de caractere (256 codigos do alfabeto ativo, bitmap real
; 8x8 escalado 2x = 16px/celula - multiplo de 8 exato, ao contrario dos 20px
; do picker do Screen0 (que por isso usava fonte de sistema, nao bitmap).
#Scr1Ed_CharPickZoom   = 2
#Scr1Ed_CharPickCellPx = 8 * #Scr1Ed_CharPickZoom   ; 16
#Scr1Ed_CharPickCols   = 16
#Scr1Ed_CharPickRows   = 16
#Scr1Ed_CharPickW      = #Scr1Ed_CharPickCols * #Scr1Ed_CharPickCellPx   ; 256
#Scr1Ed_CharPickH      = #Scr1Ed_CharPickRows * #Scr1Ed_CharPickCellPx   ; 256

Enumeration
  #Scr1Ed_Tool_Text
  #Scr1Ed_Tool_Char
  #Scr1Ed_Tool_Box
  #Scr1Ed_Tool_Shadow
  #Scr1Ed_Tool_Fill
  #Scr1Ed_Tool_Erase
EndEnumeration

; Devolve o byte MSX (0-255) pra Ch, ou -1 se Ch nao tem representacao neste
; codebase (praticamente so os codigos 0 e 127, que nao aparecem em nenhuma
; das 3 tabelas Unicode existentes - Dig_TransOriginal/Dig_TransReplacementOrder
; cobrem 128-255 e 1-31 respectivamente, ver comentario grande no topo do
; arquivo). Superset de Scr0Ed_GlyphByteFor (Screen0EditorGui.pbi): tambem
; resolve a faixa 1-31 (os 31 "graficos" de escape), que Scr0Ed_GlyphByteFor
; devolve -1 porque o SCREEN 0 nunca precisou do byte deles.
Procedure.i Scr1Ed_GlyphByteFor(Ch.s)
  Protected Code = Asc(Ch)
  If Code >= 32 And Code <= 126
    ProcedureReturn Code
  EndIf
  Protected Idx = FindString(Dig_TransOriginal, Ch)
  If Idx > 0
    ProcedureReturn $80 + Idx - 1
  EndIf
  Idx = FindString(Dig_TransReplacementOrder, Ch)
  If Idx > 0
    ProcedureReturn Idx   ; 1-31
  EndIf
  ProcedureReturn -1
EndProcedure

; Caminho inverso de Scr1Ed_GlyphByteFor - "" pros 2 codigos sem
; representacao Unicode (0 e 127, ver acima).
Procedure.s Scr1Ed_ByteToChar(Byte.i)
  If Byte >= 32 And Byte <= 126
    ProcedureReturn Chr(Byte)
  ElseIf Byte >= 128 And Byte <= 255
    ProcedureReturn Mid(Dig_TransOriginal, Byte - 128 + 1, 1)
  ElseIf Byte >= 1 And Byte <= 31
    ProcedureReturn Mid(Dig_TransReplacementOrder, Byte, 1)
  EndIf
  ProcedureReturn ""
EndProcedure

; --- Moldura/sombra: reaproveita a logica de bitmask/juncao de
; Scr0Ed_BoxMaskToChar/BoxCharToMask (Screen0EditorGui.pbi, ja validada, so
; opera em cima de constantes Unicode compile-time) - so converte pra/de
; byte MSX nas bordas.
Procedure.i Scr1Ed_BoxMaskToByte(Mask.i)
  Protected Ch.s = Scr0Ed_BoxMaskToChar(Mask)
  If Ch = ""
    ProcedureReturn -1
  EndIf
  ProcedureReturn Scr1Ed_GlyphByteFor(Ch)
EndProcedure

Procedure Scr1Ed_StampBoxEdge(Array GridBytes.a(1), Col.i, Row.i, NewMask.i)
  If Col < 0 Or Col >= #Scr1Ed_Cols Or Row < 0 Or Row >= #Scr1Ed_Rows
    ProcedureReturn
  EndIf
  Protected Idx = Row * #Scr1Ed_Cols + Col
  Protected ExistingMask = Scr0Ed_BoxCharToMask(Scr1Ed_ByteToChar(GridBytes(Idx)))
  Protected NewByte = Scr1Ed_BoxMaskToByte(ExistingMask | NewMask)
  If NewByte = -1
    NewByte = Scr1Ed_BoxMaskToByte(NewMask)
  EndIf
  GridBytes(Idx) = NewByte
EndProcedure

Procedure Scr1Ed_DrawBox(Array GridBytes.a(1), X1.i, Y1.i, X2.i, Y2.i)
  Protected Xa = X1, Xb = X2, Ya = Y1, Yb = Y2, Col, Row
  If Xa > Xb : Swap Xa, Xb : EndIf
  If Ya > Yb : Swap Ya, Yb : EndIf

  If Ya = Yb
    For Col = Xa To Xb
      Scr1Ed_StampBoxEdge(GridBytes(), Col, Ya, 12)
    Next
    ProcedureReturn
  EndIf
  If Xa = Xb
    For Row = Ya To Yb
      Scr1Ed_StampBoxEdge(GridBytes(), Xa, Row, 3)
    Next
    ProcedureReturn
  EndIf

  Scr1Ed_StampBoxEdge(GridBytes(), Xa, Ya, 10)
  Scr1Ed_StampBoxEdge(GridBytes(), Xb, Ya, 6)
  Scr1Ed_StampBoxEdge(GridBytes(), Xa, Yb, 9)
  Scr1Ed_StampBoxEdge(GridBytes(), Xb, Yb, 5)
  For Col = Xa + 1 To Xb - 1
    Scr1Ed_StampBoxEdge(GridBytes(), Col, Ya, 12)
    Scr1Ed_StampBoxEdge(GridBytes(), Col, Yb, 12)
  Next
  For Row = Ya + 1 To Yb - 1
    Scr1Ed_StampBoxEdge(GridBytes(), Xa, Row, 3)
    Scr1Ed_StampBoxEdge(GridBytes(), Xb, Row, 3)
  Next
EndProcedure

Procedure Scr1Ed_ApplyShadow(Array GridBytes.a(1), X1.i, Y1.i, X2.i, Y2.i)
  Protected Xa = X1, Xb = X2, Ya = Y1, Yb = Y2, Col, Row
  If Xa > Xb : Swap Xa, Xb : EndIf
  If Ya > Yb : Swap Ya, Yb : EndIf
  Protected ShadowByte = Scr1Ed_GlyphByteFor(Chr($2592))  ; ▒

  Col = Xb + 1
  If Col < #Scr1Ed_Cols
    For Row = Ya + 1 To Yb + 1
      If Row < #Scr1Ed_Rows
        GridBytes(Row * #Scr1Ed_Cols + Col) = ShadowByte
      EndIf
    Next
  EndIf

  Row = Yb + 1
  If Row < #Scr1Ed_Rows
    For Col = Xa + 1 To Xb + 1
      If Col < #Scr1Ed_Cols
        GridBytes(Row * #Scr1Ed_Cols + Col) = ShadowByte
      EndIf
    Next
  EndIf
EndProcedure

Procedure Scr1Ed_FillRect(Array GridBytes.a(1), X1.i, Y1.i, X2.i, Y2.i, Byte.i)
  Protected Xa = X1, Xb = X2, Ya = Y1, Yb = Y2, Col, Row
  If Xa > Xb : Swap Xa, Xb : EndIf
  If Ya > Yb : Swap Ya, Yb : EndIf
  For Row = Ya To Yb
    For Col = Xa To Xb
      GridBytes(Row * #Scr1Ed_Cols + Col) = Byte
    Next
  Next
EndProcedure

; Estampa Text horizontalmente a partir de (StartCol,Row), cortando no fim
; da linha. Caracteres sem byte MSX correspondente (Scr1Ed_GlyphByteFor=-1)
; sao pulados (celula existente fica como estava) mas ainda avancam uma
; coluna, pra nao desalinhar o resto do texto digitado.
Procedure Scr1Ed_StampText(Array GridBytes.a(1), StartCol.i, Row.i, Text.s)
  Protected i, Col, B
  For i = 1 To Len(Text)
    Col = StartCol + i - 1
    If Col >= #Scr1Ed_Cols
      Break
    EndIf
    B = Scr1Ed_GlyphByteFor(Mid(Text, i, 1))
    If B >= 0
      GridBytes(Row * #Scr1Ed_Cols + Col) = B
    EndIf
  Next
EndProcedure

; Redesenha a tela inteira - cada celula usa Tinta/Fundo do OCTETO do seu
; proprio byte (byte>>3 = grupo de 8), nao uma cor global de tela (unica
; diferenca de fundo em relacao a Scr0Ed_RedrawCanvas). Reaproveita
; Scr0Ed_DrawGlyphBitmap (Screen0EditorGui.pbi) tal como esta - ja opera
; sobre byte MSX cru, nao precisa de nenhuma adaptacao.
Procedure Scr1Ed_RedrawCanvas(Canvas, Array GridBytes.a(1), Array CharsetBytes.a(2), Array OctetInk.a(1), Array OctetPaper.a(1), Array Palette.l(1), MarkCol.i = -1, MarkRow.i = -1)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected Zoom = Scr0Ed_ZoomForWidth(#Scr1Ed_Cols)
  Protected CellPx = 8 * Zoom
  Protected Row, Col, Idx, ByteCode, Octet, CellInk.l, CellPaper.l
  For Row = 0 To #Scr1Ed_Rows - 1
    For Col = 0 To #Scr1Ed_Cols - 1
      Idx = Row * #Scr1Ed_Cols + Col
      ByteCode = GridBytes(Idx)
      Octet = ByteCode >> 3
      CellInk = Palette(OctetInk(Octet))
      CellPaper = Palette(OctetPaper(Octet))
      Scr0Ed_DrawGlyphBitmap(CharsetBytes(), ByteCode, Col * CellPx, Row * CellPx, Zoom, CellInk, CellPaper)
    Next
  Next

  If MarkCol >= 0 And MarkRow >= 0
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(MarkCol * CellPx, MarkRow * CellPx, CellPx, CellPx, RGB(255, 220, 0))
    Box(MarkCol * CellPx + 1, MarkRow * CellPx + 1, CellPx - 2, CellPx - 2, RGB(255, 220, 0))
    DrawingMode(#PB_2DDrawing_Default)
  EndIf

  StopDrawing()
EndProcedure

; Grade de 256 celulas (a "tabela ASCII do alfabeto escolhido" pedida pelo
; usuario) - fundo de cada celula na cor do octeto daquele codigo, glifo
; bitmap real por cima (nunca aproximacao de fonte de sistema - ao
; contrario do picker do Screen0, todos os 256 codigos tem bitmap aqui, ver
; comentario grande no topo do arquivo).
Procedure Scr1Ed_DrawCharPicker(Canvas, Array CharsetBytes.a(2), Array OctetInk.a(1), Array OctetPaper.a(1), Array Palette.l(1), Selected.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected i, Row, Col, X, Y, Octet, InkRGB.l, PaperRGB.l
  For i = 0 To 255
    Row = i / #Scr1Ed_CharPickCols
    Col = i % #Scr1Ed_CharPickCols
    X = Col * #Scr1Ed_CharPickCellPx
    Y = Row * #Scr1Ed_CharPickCellPx
    Octet = i >> 3
    InkRGB = Palette(OctetInk(Octet))
    PaperRGB = Palette(OctetPaper(Octet))
    DrawingMode(#PB_2DDrawing_Default)
    Scr0Ed_DrawGlyphBitmap(CharsetBytes(), i, X, Y, #Scr1Ed_CharPickZoom, InkRGB, PaperRGB)

    DrawingMode(#PB_2DDrawing_Outlined)
    Box(X, Y, #Scr1Ed_CharPickCellPx, #Scr1Ed_CharPickCellPx, RGB(120, 120, 120))

    If i = Selected
      Box(X + 1, Y + 1, #Scr1Ed_CharPickCellPx - 2, #Scr1Ed_CharPickCellPx - 2, RGB(255, 220, 0))
    EndIf
  Next
  DrawingMode(#PB_2DDrawing_Default)
  StopDrawing()
EndProcedure

; Monta a expressao BASIC de uma linha (literais entre aspas + CHR$(n)
; concatenado com "+") a partir dos bytes crus da grade - "" se a linha
; inteira for espaco (32). Byte 34 (aspas) e qualquer byte fora de 32-126
; viram CHR$(n) isolado; o resto vira um literal entre aspas o mais longo
; possivel. Puro ASCII na saida, sem depender de nenhuma traducao Unicode.
Procedure.s Scr1Ed_BuildLineExpr(Array GridBytes.a(1), Row.i)
  Protected Q.s = Chr(34)
  Protected LastCol = -1, Col, B
  For Col = 0 To #Scr1Ed_Cols - 1
    If GridBytes(Row * #Scr1Ed_Cols + Col) <> 32
      LastCol = Col
    EndIf
  Next
  If LastCol = -1
    ProcedureReturn ""
  EndIf

  Protected Result.s = "", Literal.s = "", InLiteral.b = #False
  For Col = 0 To LastCol
    B = GridBytes(Row * #Scr1Ed_Cols + Col)
    If B >= 32 And B <= 126 And B <> 34
      If Not InLiteral
        If Result <> "" : Result + "+" : EndIf
        Literal = Q
        InLiteral = #True
      EndIf
      Literal + Chr(B)
    Else
      If InLiteral
        Result + Literal + Q
        InLiteral = #False
      EndIf
      If Result <> "" : Result + "+" : EndIf
      Result + "CHR$(" + Str(B) + ")"
    EndIf
  Next
  If InLiteral
    Result + Literal + Q
  EndIf
  ProcedureReturn Result
EndProcedure

; --- Geracao de codigo: SCREEN 1 + Tabela de Cores (32 grupos de 8
; caracteres, endereco padrao &H2000 - confirmado contra a MSX Wiki antes de
; escrever este bloco) + carregador de fonte customizada opcional (Pattern
; Generator Table do SCREEN 1, &H0000, mesmo endereco que
; CharEd_ScreenPgtAddress() ja usa - CharsetEditorGui.pbi) + LOCATE/PRINT do
; texto (linhas em branco viram nenhum PRINT).
Procedure.s Scr1Ed_BuildCode(Array GridBytes.a(1), Array OctetInk.a(1), Array OctetPaper.a(1), AlphabetNumber.i, Array CharsetBytes.a(2))
  Protected Result.s = ""
  Result + "SCREEN 1" + #CRLF$

  Result + "' Tabela de cores (32 grupos de 8 caracteres, Color Table padrao &H2000)" + #CRLF$
  Result + "FOR CI=0 TO 31:READ CD:VPOKE 8192+CI,CD:NEXT CI" + #CRLF$
  Protected OctIdx, LineVals.s = "", Count = 0
  For OctIdx = 0 To 31
    If Count > 0 And Count % 16 = 0
      Result + "DATA " + LineVals + #CRLF$
      LineVals = ""
    EndIf
    If LineVals <> ""
      LineVals + ","
    EndIf
    LineVals + "&H" + RSet(Hex(((OctetInk(OctIdx) & $F) << 4) | (OctetPaper(OctIdx) & $F)), 2, "0")
    Count + 1
  Next
  If LineVals <> ""
    Result + "DATA " + LineVals + #CRLF$
  EndIf

  If AlphabetNumber <> -1
    Result + "' Carrega a fonte customizada #" + Str(AlphabetNumber) + " na Pattern Generator Table do SCREEN 1 (&H0000)" + #CRLF$
    Result + "FOR SI=0 TO 2047:READ SD:VPOKE 0+SI,SD:NEXT SI" + #CRLF$
    Protected FRow, FCol, FLineVals.s = "", FCount = 0
    For FRow = 0 To 255
      For FCol = 0 To 7
        If FCount > 0 And FCount % 16 = 0
          Result + "DATA " + FLineVals + #CRLF$
          FLineVals = ""
        EndIf
        If FLineVals <> ""
          FLineVals + ","
        EndIf
        FLineVals + "&H" + RSet(Hex(CharsetBytes(FRow, FCol)), 2, "0")
        FCount + 1
      Next
    Next
    If FLineVals <> ""
      Result + "DATA " + FLineVals + #CRLF$
    EndIf
  EndIf

  Protected Row, Line.s
  For Row = 0 To #Scr1Ed_Rows - 1
    Line = Scr1Ed_BuildLineExpr(GridBytes(), Row)
    If Line <> ""
      Result + "LOCATE 0," + Str(Row) + ":PRINT " + Line + ";" + #CRLF$
    EndIf
  Next

  ProcedureReturn Result
EndProcedure

Procedure.b Scr1Ed_ConfirmDiscard()
  ProcedureReturn Bool(MessageRequester("Tela nao registrada",
                        "As alteracoes desta tela ainda nao foram registradas no projeto." + Chr(10) +
                        "Descartar mesmo assim?",
                        #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
EndProcedure

; Texto informativo do "byte atual" (grupo/octeto junto, pra deixar claro
; qual faixa de codigos a paleta ao lado vai colorir se clicada).
Procedure.s Scr1Ed_ByteInfoText(Byte.i)
  Protected Octet = Byte >> 3
  ProcedureReturn "Byte atual: " + Str(Byte) + " (&H" + RSet(Hex(Byte), 2, "0") + ") - octeto " + Str(Octet) +
                  " (codigos " + Str(Octet * 8) + "-" + Str(Octet * 8 + 7) + ")"
EndProcedure

; Reflete o estado atual na UI inteira - chamada apos carregar/criar/trocar
; de tela, trocar de fonte ou trocar o byte atual.
Procedure Scr1Ed_RefreshUI(G_Canvas, G_CharPicker, G_ScreenNumberText, G_Tag, G_FontCombo, G_PaletteInk, G_PalettePaper,
                           G_ByteInfo, ScreenNumber.i, Tag.s, AlphabetNumber.i, CurrentByte.i,
                           Array GridBytes.a(1), Array OctetInk.a(1), Array OctetPaper.a(1), Array CharsetBytes.a(2), Array Palette.l(1))
  SetGadgetText(G_ScreenNumberText, "#" + Str(ScreenNumber))
  SetGadgetText(G_Tag, Tag)
  SetGadgetText(G_ByteInfo, Scr1Ed_ByteInfoText(CurrentByte))

  If AlphabetNumber = -1
    SetGadgetState(G_FontCombo, 0)
    ProjectDB::FetchDefaultAlphabet(0, CharsetBytes())
  Else
    Protected i, Found = 0
    For i = 1 To CountGadgetItems(G_FontCombo) - 1
      If Val(Mid(GetGadgetItemText(G_FontCombo, i), 2)) = AlphabetNumber
        Found = i
        Break
      EndIf
    Next
    SetGadgetState(G_FontCombo, Found)
    ProjectDB::FetchAlphabet(AlphabetNumber, CharsetBytes())
  EndIf

  Protected Octet = CurrentByte >> 3
  Scr2Ed_RedrawMiniPalette(G_PaletteInk, OctetInk(Octet), Palette())
  Scr2Ed_RedrawMiniPalette(G_PalettePaper, OctetPaper(Octet), Palette())
  Scr1Ed_RedrawCanvas(G_Canvas, GridBytes(), CharsetBytes(), OctetInk(), OctetPaper(), Palette())
  Scr1Ed_DrawCharPicker(G_CharPicker, CharsetBytes(), OctetInk(), OctetPaper(), Palette(), CurrentByte)
EndProcedure

Procedure Screen1Editor_OpenWindow(ParentWindow)
  Protected LeftX = 24
  Protected CanvasY = 24
  Protected Zoom = Scr0Ed_ZoomForWidth(#Scr1Ed_Cols)   ; 4 (32 <= 40)
  Protected CanvasW = #Scr1Ed_Cols * 8 * Zoom            ; 1024
  Protected CanvasH = #Scr1Ed_Rows * 8 * Zoom            ; 768

  Protected RightX = LeftX + CanvasW + 24
  Protected RightColW = 340

  Protected InfoY = CanvasY
  Protected ByteLabelY = InfoY + 34
  Protected ByteFieldY = ByteLabelY + 24
  Protected PaletteLabelY = ByteFieldY + 24 + 16
  Protected CharPickLabelY = PaletteLabelY + 20 + #Scr2Ed_PaletteSize + 16
  Protected CharPickGridY = CharPickLabelY + 34 + 6
  Protected ProjBarY = CharPickGridY + #Scr1Ed_CharPickH + 12
  Protected ProjBarRow2Y = ProjBarY + #CharEd_IconBtnH + 6

  Protected ToolPanelY = CanvasY + CanvasH + 24

  Protected WinW = RightX + RightColW + 24
  Protected WinH = ToolPanelY + #Scr1Ed_ToolPanelH + 20

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Tela MSX (SCREEN 1)",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  Protected G_Canvas = CanvasGadget(#PB_Any, LeftX, CanvasY, CanvasW, CanvasH)

  TextGadget(#PB_Any, RightX, InfoY + 3, 45, 20, "Fonte:")
  Protected G_FontCombo = ComboBoxGadget(#PB_Any, RightX + 50, InfoY, 220, 24)
  AddGadgetItem(G_FontCombo, -1, "Padrao")

  TextGadget(#PB_Any, RightX, ByteLabelY, RightColW, 20, "Byte atual (digite ASCII ou clique na grade abaixo):")
  Protected G_AsciiChar = StringGadget(#PB_Any, RightX, ByteFieldY, 60, 24, " ")
  Protected G_ByteInfo = TextGadget(#PB_Any, RightX + 70, ByteFieldY + 4, RightColW - 70, 20, "")

  TextGadget(#PB_Any, RightX, PaletteLabelY, 150, 18, "Tinta do octeto:")
  Protected G_PaletteInk = CanvasGadget(#PB_Any, RightX, PaletteLabelY + 20, #Scr2Ed_PaletteSize, #Scr2Ed_PaletteSize)
  GadgetToolTip(G_PaletteInk, "Muda a cor de tinta dos 8 codigos do octeto do byte atual (Color Table do SCREEN 1)")
  TextGadget(#PB_Any, RightX + #Scr2Ed_PaletteSize + 16, PaletteLabelY, 150, 18, "Fundo do octeto:")
  Protected G_PalettePaper = CanvasGadget(#PB_Any, RightX + #Scr2Ed_PaletteSize + 16, PaletteLabelY + 20, #Scr2Ed_PaletteSize, #Scr2Ed_PaletteSize)
  GadgetToolTip(G_PalettePaper, "Muda a cor de fundo dos 8 codigos do octeto do byte atual (Color Table do SCREEN 1)")

  TextGadget(#PB_Any, RightX, CharPickLabelY, RightColW, 34,
    "Tabela ASCII do alfabeto (256 codigos) - clique escolhe o byte atual; o fundo de cada celula ja mostra a cor do octeto.")
  Protected G_CharPicker = CanvasGadget(#PB_Any, RightX, CharPickGridY, #Scr1Ed_CharPickW, #Scr1Ed_CharPickH)

  Protected Cx = RightX
  TextGadget(#PB_Any, Cx, ProjBarY + 5, 40, 20, "Tela:")
  Cx + 40 + 4
  Protected G_ScreenNumberText = TextGadget(#PB_Any, Cx, ProjBarY + 5, 40, 20, "#1")
  Cx + 40 + 10

  Protected FirstIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 0, #True)
  Protected G_First = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(FirstIcon))
  GadgetToolTip(G_First, "Primeira tela")
  Cx + #CharEd_IconBtnW + 2
  Protected PrevIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 0, #False)
  Protected G_Prev = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(PrevIcon))
  GadgetToolTip(G_Prev, "Tela anterior")
  Cx + #CharEd_IconBtnW + 2
  Protected NextIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 1, #False)
  Protected G_Next = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(NextIcon))
  GadgetToolTip(G_Next, "Proxima tela")
  Cx + #CharEd_IconBtnW + 2
  Protected LastIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 1, #True)
  Protected G_Last = ButtonImageGadget(#PB_Any, Cx, ProjBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(LastIcon))
  GadgetToolTip(G_Last, "Ultima tela")

  Cx = RightX
  TextGadget(#PB_Any, Cx, ProjBarRow2Y + 3, 32, 20, "Tag:")
  Cx + 32 + 4
  Protected G_Tag = StringGadget(#PB_Any, Cx, ProjBarRow2Y + 1, 150, 22, "")
  GadgetToolTip(G_Tag, "Nome curto pra identificar a tela (ate 16 caracteres)")
  Cx + 150 + 16

  Protected NewIcon = CharEd_CreateNewIcon(#CharEd_IconSize)
  Protected G_New = ButtonImageGadget(#PB_Any, Cx, ProjBarRow2Y, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(NewIcon))
  GadgetToolTip(G_New, "Nova tela (numera automaticamente, comeca em branco)")
  Cx + #CharEd_IconBtnW + 2
  Protected RegisterIcon = CharEd_CreateRegisterIcon(#CharEd_IconSize)
  Protected G_Register = ButtonImageGadget(#PB_Any, Cx, ProjBarRow2Y, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(RegisterIcon))
  GadgetToolTip(G_Register, "Registrar: grava esta tela no projeto")

  Protected G_Panel = PanelGadget(#PB_Any, LeftX, ToolPanelY, #Scr1Ed_ToolPanelW, #Scr1Ed_ToolPanelH)
  Protected ToolContentW = #Scr1Ed_ToolPanelW - 20

  AddGadgetItem(G_Panel, -1, "Texto")
    TextGadget(#PB_Any, 10, 10, ToolContentW, 40,
      "Digite o texto e clique no canvas pra posicionar (horizontal, a partir da celula clicada; corta se passar do fim da linha).")
    Protected G_TextInput = StringGadget(#PB_Any, 10, 56, ToolContentW, 24, "")

  AddGadgetItem(G_Panel, -1, "Caractere")
    TextGadget(#PB_Any, 10, 10, ToolContentW, 60,
      "Escolha o byte na tabela ASCII da coluna direita (ou digite ASCII no campo acima dela), depois clique ou arraste no canvas pra estampar.")

  AddGadgetItem(G_Panel, -1, "Quadro")
    TextGadget(#PB_Any, 10, 10, ToolContentW, 80,
      "Dois cliques no canvas: primeiro marca um canto, segundo marca o canto oposto - desenha a moldura com linhas simples, unindo automaticamente com quadros ja existentes que encostarem (formando T/cruz na juncao)." + Chr(10) + Chr(10) +
      "Botao direito cancela a marcacao pendente.")

  AddGadgetItem(G_Panel, -1, "Sombra")
    TextGadget(#PB_Any, 10, 10, ToolContentW, 80,
      "Dois cliques (cantos opostos de um retangulo, tipicamente o mesmo de um quadro ja desenhado) - estampa uma faixa de sombra deslocada uma celula pra baixo e pra direita, ao longo das bordas direita e inferior.")

  AddGadgetItem(G_Panel, -1, "Bloco")
    TextGadget(#PB_Any, 10, 10, ToolContentW, 90,
      "Dois cliques (cantos opostos) - preenche o retangulo inteiro com o byte atual. Util pra texturas, fundos ou apagar uma area maior de uma vez.")

  AddGadgetItem(G_Panel, -1, "Borracha")
    TextGadget(#PB_Any, 10, 10, ToolContentW, 40, "Clique ou arraste no canvas pra apagar (estampa espaco).")

  CloseGadgetList()

  Protected ButtonsX = LeftX + #Scr1Ed_ToolPanelW + 24
  Protected G_Inject = ThemedButton(ButtonsX, ToolPanelY, 180, 32, "Injetar no cursor", Chr(#Icon_Insert))
  Protected G_Copy = ThemedButton(ButtonsX, ToolPanelY + 40, 180, 32, "Copiar", Chr(#Icon_Copy))
  Protected G_Close = ThemedButton(ButtonsX, ToolPanelY + 80, 180, 32, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")
  GadgetToolTip(G_Inject, "Gera o codigo BASIC (SCREEN 1 + Tabela de Cores, mais o carregador de fonte se houver) e injeta na aba de texto ativa")
  GadgetToolTip(G_Copy, "Gera o mesmo codigo e copia pra area de transferencia")

  ; --- Estado ---
  Dim GridBytes.a(#Scr1Ed_MaxCells - 1)
  Dim OctetInk.a(31)
  Dim OctetPaper.a(31)
  Dim CharsetBytes.a(255, 7)
  Dim Palette.l(15)
  Dim PaletteNames.s(15)
  SpriteEd_FillPalette(Palette(), PaletteNames())

  Protected NewList AlphaNums.i()
  ProjectDB::ListAlphabetNumbers(AlphaNums())
  ForEach AlphaNums()
    AddGadgetItem(G_FontCombo, -1, "#" + Str(AlphaNums()))
  Next

  Protected ScreenNumber.i = 1
  Protected ScreenTag.s = ""
  Protected AlphabetNumber.i = -1
  Protected Dirty.b = #False
  Protected CurrentByte.i = 32

  Protected ClearIdx
  For ClearIdx = 0 To #Scr1Ed_MaxCells - 1
    GridBytes(ClearIdx) = 32
  Next
  For ClearIdx = 0 To 31
    OctetInk(ClearIdx) = 15
    OctetPaper(ClearIdx) = 1
  Next

  Protected NewList Nav.i()
  ProjectDB::ListScreen1Numbers(Nav())
  If ListSize(Nav()) > 0
    FirstElement(Nav())
    ScreenNumber = Nav()
    ProjectDB::FetchScreen1(ScreenNumber, GridBytes(), OctetInk(), OctetPaper())
    AlphabetNumber = ProjectDB::LastScreen1AlphabetNumber()
    ScreenTag = ProjectDB::LastScreen1Tag()
  EndIf

  Scr1Ed_RefreshUI(G_Canvas, G_CharPicker, G_ScreenNumberText, G_Tag, G_FontCombo, G_PaletteInk, G_PalettePaper, G_ByteInfo,
                   ScreenNumber, ScreenTag, AlphabetNumber, CurrentByte,
                   GridBytes(), OctetInk(), OctetPaper(), CharsetBytes(), Palette())

  Protected Event, Quit = #False, MouseX, MouseY, Col, Row, NavTarget
  Protected MarkCol = -1, MarkRow = -1
  Protected LastPaintCol = -1, LastPaintRow = -1
  Protected ActiveTab

  Repeat
    Event = WaitWindowEvent()

    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()

          Case G_Tag
            If EventType() = #PB_EventType_Change
              If Len(GetGadgetText(G_Tag)) > 16
                SetGadgetText(G_Tag, Left(GetGadgetText(G_Tag), 16))
              EndIf
              Dirty = #True
            EndIf

          Case G_AsciiChar
            If EventType() = #PB_EventType_Change
              Protected AsciiTxt.s = GetGadgetText(G_AsciiChar)
              If Len(AsciiTxt) > 1
                AsciiTxt = Left(AsciiTxt, 1)
                SetGadgetText(G_AsciiChar, AsciiTxt)
              EndIf
              If AsciiTxt <> ""
                Protected TypedByte = Scr1Ed_GlyphByteFor(AsciiTxt)
                If TypedByte >= 0
                  CurrentByte = TypedByte
                  SetGadgetText(G_ByteInfo, Scr1Ed_ByteInfoText(CurrentByte))
                  Scr2Ed_RedrawMiniPalette(G_PaletteInk, OctetInk(CurrentByte >> 3), Palette())
                  Scr2Ed_RedrawMiniPalette(G_PalettePaper, OctetPaper(CurrentByte >> 3), Palette())
                  Scr1Ed_DrawCharPicker(G_CharPicker, CharsetBytes(), OctetInk(), OctetPaper(), Palette(), CurrentByte)
                EndIf
              EndIf
            EndIf

          Case G_FontCombo
            If EventType() = #PB_EventType_Change
              Protected FontSel.s = GetGadgetText(G_FontCombo)
              If FontSel = "Padrao"
                AlphabetNumber = -1
                ProjectDB::FetchDefaultAlphabet(0, CharsetBytes())
              Else
                AlphabetNumber = Val(Mid(FontSel, 2))
                ProjectDB::FetchAlphabet(AlphabetNumber, CharsetBytes())
              EndIf
              Dirty = #True
              Scr1Ed_RedrawCanvas(G_Canvas, GridBytes(), CharsetBytes(), OctetInk(), OctetPaper(), Palette())
              Scr1Ed_DrawCharPicker(G_CharPicker, CharsetBytes(), OctetInk(), OctetPaper(), Palette(), CurrentByte)
            EndIf

          Case G_PaletteInk
            If EventType() = #PB_EventType_LeftButtonDown
              MouseX = GetGadgetAttribute(G_PaletteInk, #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(G_PaletteInk, #PB_Canvas_MouseY)
              Protected InkIdx = Scr2Ed_PaletteHitTest(MouseX, MouseY)
              If InkIdx >= 0
                OctetInk(CurrentByte >> 3) = InkIdx
                Dirty = #True
                Scr2Ed_RedrawMiniPalette(G_PaletteInk, InkIdx, Palette())
                Scr1Ed_RedrawCanvas(G_Canvas, GridBytes(), CharsetBytes(), OctetInk(), OctetPaper(), Palette())
                Scr1Ed_DrawCharPicker(G_CharPicker, CharsetBytes(), OctetInk(), OctetPaper(), Palette(), CurrentByte)
              EndIf
            EndIf

          Case G_PalettePaper
            If EventType() = #PB_EventType_LeftButtonDown
              MouseX = GetGadgetAttribute(G_PalettePaper, #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(G_PalettePaper, #PB_Canvas_MouseY)
              Protected PaperIdx = Scr2Ed_PaletteHitTest(MouseX, MouseY)
              If PaperIdx >= 0
                OctetPaper(CurrentByte >> 3) = PaperIdx
                Dirty = #True
                Scr2Ed_RedrawMiniPalette(G_PalettePaper, PaperIdx, Palette())
                Scr1Ed_RedrawCanvas(G_Canvas, GridBytes(), CharsetBytes(), OctetInk(), OctetPaper(), Palette())
                Scr1Ed_DrawCharPicker(G_CharPicker, CharsetBytes(), OctetInk(), OctetPaper(), Palette(), CurrentByte)
              EndIf
            EndIf

          Case G_CharPicker
            If EventType() = #PB_EventType_LeftButtonDown Or EventType() = #PB_EventType_LeftDoubleClick
              MouseX = GetGadgetAttribute(G_CharPicker, #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(G_CharPicker, #PB_Canvas_MouseY)
              If MouseX >= 0 And MouseY >= 0
                Protected PickCol = MouseX / #Scr1Ed_CharPickCellPx, PickRow = MouseY / #Scr1Ed_CharPickCellPx
                Protected PickByte = PickRow * #Scr1Ed_CharPickCols + PickCol
                If PickByte >= 0 And PickByte <= 255
                  CurrentByte = PickByte
                  SetGadgetText(G_AsciiChar, Scr1Ed_ByteToChar(CurrentByte))
                  SetGadgetText(G_ByteInfo, Scr1Ed_ByteInfoText(CurrentByte))
                  Scr2Ed_RedrawMiniPalette(G_PaletteInk, OctetInk(CurrentByte >> 3), Palette())
                  Scr2Ed_RedrawMiniPalette(G_PalettePaper, OctetPaper(CurrentByte >> 3), Palette())
                  Scr1Ed_DrawCharPicker(G_CharPicker, CharsetBytes(), OctetInk(), OctetPaper(), Palette(), CurrentByte)
                EndIf
              EndIf
            EndIf

          Case G_Canvas
            ActiveTab = GetGadgetState(G_Panel)

            Select EventType()
              Case #PB_EventType_LeftButtonDown
                MouseX = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseX)
                MouseY = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseY)
                If MouseX >= 0 And MouseY >= 0
                  Col = MouseX / (8 * Zoom)
                  Row = MouseY / (8 * Zoom)
                  If Col >= 0 And Col < #Scr1Ed_Cols And Row >= 0 And Row < #Scr1Ed_Rows
                    Select ActiveTab
                      Case #Scr1Ed_Tool_Text
                        Scr1Ed_StampText(GridBytes(), Col, Row, GetGadgetText(G_TextInput))
                        Dirty = #True

                      Case #Scr1Ed_Tool_Char
                        GridBytes(Row * #Scr1Ed_Cols + Col) = CurrentByte
                        LastPaintCol = Col : LastPaintRow = Row
                        Dirty = #True

                      Case #Scr1Ed_Tool_Box
                        If MarkCol = -1
                          MarkCol = Col : MarkRow = Row
                        Else
                          Scr1Ed_DrawBox(GridBytes(), MarkCol, MarkRow, Col, Row)
                          MarkCol = -1 : MarkRow = -1
                          Dirty = #True
                        EndIf

                      Case #Scr1Ed_Tool_Shadow
                        If MarkCol = -1
                          MarkCol = Col : MarkRow = Row
                        Else
                          Scr1Ed_ApplyShadow(GridBytes(), MarkCol, MarkRow, Col, Row)
                          MarkCol = -1 : MarkRow = -1
                          Dirty = #True
                        EndIf

                      Case #Scr1Ed_Tool_Fill
                        If MarkCol = -1
                          MarkCol = Col : MarkRow = Row
                        Else
                          Scr1Ed_FillRect(GridBytes(), MarkCol, MarkRow, Col, Row, CurrentByte)
                          MarkCol = -1 : MarkRow = -1
                          Dirty = #True
                        EndIf

                      Case #Scr1Ed_Tool_Erase
                        GridBytes(Row * #Scr1Ed_Cols + Col) = 32
                        LastPaintCol = Col : LastPaintRow = Row
                        Dirty = #True
                    EndSelect
                    Scr1Ed_RedrawCanvas(G_Canvas, GridBytes(), CharsetBytes(), OctetInk(), OctetPaper(), Palette(), MarkCol, MarkRow)
                  EndIf
                EndIf

              Case #PB_EventType_RightButtonDown
                If MarkCol <> -1
                  MarkCol = -1 : MarkRow = -1
                  Scr1Ed_RedrawCanvas(G_Canvas, GridBytes(), CharsetBytes(), OctetInk(), OctetPaper(), Palette())
                EndIf

              Case #PB_EventType_MouseMove
                If (ActiveTab = #Scr1Ed_Tool_Char Or ActiveTab = #Scr1Ed_Tool_Erase) And
                   (GetGadgetAttribute(G_Canvas, #PB_Canvas_Buttons) & #PB_Canvas_LeftButton)
                  MouseX = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseX)
                  MouseY = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseY)
                  Col = MouseX / (8 * Zoom)
                  Row = MouseY / (8 * Zoom)
                  If Col >= 0 And Col < #Scr1Ed_Cols And Row >= 0 And Row < #Scr1Ed_Rows And (Col <> LastPaintCol Or Row <> LastPaintRow)
                    If ActiveTab = #Scr1Ed_Tool_Char
                      GridBytes(Row * #Scr1Ed_Cols + Col) = CurrentByte
                    Else
                      GridBytes(Row * #Scr1Ed_Cols + Col) = 32
                    EndIf
                    LastPaintCol = Col : LastPaintRow = Row
                    Dirty = #True
                    Scr1Ed_RedrawCanvas(G_Canvas, GridBytes(), CharsetBytes(), OctetInk(), OctetPaper(), Palette())
                  EndIf
                EndIf
            EndSelect

          Case G_New
            If Not Dirty Or Scr1Ed_ConfirmDiscard()
              ProjectDB::ListScreen1Numbers(Nav())
              If ListSize(Nav()) > 0
                LastElement(Nav())
                ScreenNumber = Nav() + 1
              Else
                ScreenNumber = 1
              EndIf
              AlphabetNumber = -1
              CurrentByte = 32
              For ClearIdx = 0 To #Scr1Ed_MaxCells - 1
                GridBytes(ClearIdx) = 32
              Next
              For ClearIdx = 0 To 31
                OctetInk(ClearIdx) = 15
                OctetPaper(ClearIdx) = 1
              Next
              MarkCol = -1 : MarkRow = -1
              Dirty = #False
              Scr1Ed_RefreshUI(G_Canvas, G_CharPicker, G_ScreenNumberText, G_Tag, G_FontCombo, G_PaletteInk, G_PalettePaper, G_ByteInfo,
                               ScreenNumber, "", AlphabetNumber, CurrentByte,
                               GridBytes(), OctetInk(), OctetPaper(), CharsetBytes(), Palette())
            EndIf

          Case G_Register
            ProjectDB::StoreScreen1(ScreenNumber, GetGadgetText(G_Tag), AlphabetNumber, GridBytes(), OctetInk(), OctetPaper())
            Dirty = #False

          Case G_First, G_Prev, G_Next, G_Last
            If Not Dirty Or Scr1Ed_ConfirmDiscard()
              ProjectDB::ListScreen1Numbers(Nav())
              Select EventGadget()
                Case G_First : NavTarget = SpriteEd_FindNavTarget(Nav(), 0, ScreenNumber)
                Case G_Prev  : NavTarget = SpriteEd_FindNavTarget(Nav(), 1, ScreenNumber)
                Case G_Next  : NavTarget = SpriteEd_FindNavTarget(Nav(), 2, ScreenNumber)
                Case G_Last  : NavTarget = SpriteEd_FindNavTarget(Nav(), 3, ScreenNumber)
              EndSelect
              If NavTarget >= 0
                ScreenNumber = NavTarget
                ProjectDB::FetchScreen1(ScreenNumber, GridBytes(), OctetInk(), OctetPaper())
                AlphabetNumber = ProjectDB::LastScreen1AlphabetNumber()
                CurrentByte = 32
                MarkCol = -1 : MarkRow = -1 : Dirty = #False
                Scr1Ed_RefreshUI(G_Canvas, G_CharPicker, G_ScreenNumberText, G_Tag, G_FontCombo, G_PaletteInk, G_PalettePaper, G_ByteInfo,
                                 ScreenNumber, ProjectDB::LastScreen1Tag(), AlphabetNumber, CurrentByte,
                                 GridBytes(), OctetInk(), OctetPaper(), CharsetBytes(), Palette())
              EndIf
            EndIf

          Case G_Inject
            If Not InjectTextAtCursor(Scr1Ed_BuildCode(GridBytes(), OctetInk(), OctetPaper(), AlphabetNumber, CharsetBytes()))
              MessageRequester("Erro", "Nenhuma aba de texto ativa para injetar o codigo.",
                               #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
            EndIf

          Case G_Copy
            SetClipboardText(Scr1Ed_BuildCode(GridBytes(), OctetInk(), OctetPaper(), AlphabetNumber, CharsetBytes()))

          Case G_Close
            Quit = #True

        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True
    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
EndProcedure
