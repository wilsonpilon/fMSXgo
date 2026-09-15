;
; ------------------------------------------------------------
;  GraphosNativeIO.pbi - leitura/escrita dos formatos NATIVOS do Graphos III
;  original (.ALF/.LAY/.SCR/.SHP), pra importar telas/layouts/shapes de
;  disquetes/arquivos reais de MSX pro nosso projeto, e exportar de volta
;  pro formato que o Graphos III de verdade consegue ler (BLOAD).
;
;  Fonte da especificacao dos formatos (fase 8, pedido explicito do
;  usuario - "veja se consegue entender os formatos"): os visualizadores
;  Python em graphos-IV/ (alphabetV.py/layoutV.py/screenV.py/shapeV_2.py,
;  referencia de leitura, gitignored - ver .gitignore), as fontes Pascal
;  ORIGINAIS de CyberKnight (Masao Kawata) que esses visualizadores
;  reimplementam (graphos-IV/readers/msx*vw.pas) e a documentacao escrita
;  pelo proprio autor (graphos-IV/readers/g3viewer.doc, secao 3) - as tres
;  fontes concordam entre si e foram testadas contra arquivos REAIS ja
;  presentes neste repositorio (graphos/Layout/*.LAY, graphos/Telas/*.SCR,
;  graphos/Shapes/*.SHP, extraidos de disquetes de verdade).
;
;  .ALF (alfabeto) NAO precisa de nada novo aqui - ja implementado
;  corretamente em CharsetEditorGui.pbi (modulo 4): cabecalho BSAVE de 7
;  bytes (tipo $FE + inicio $9200 + fim $99FF + exec $9200) + 2048 bytes
;  crus (256 caracteres x 8 bytes, 1 bit por pixel).
;
;  .LAY (layout): cabecalho BSAVE de 7 bytes (tipo + inicio $9200 + FIM
;  variavel + exec $9200), onde FIM determina o tamanho dos dados
;  comprimidos (Length = Fim - $9200 + 1). Dados = RLE restrito + ofuscacao:
;  cada byte do arquivo tem +$99 somado (mod 256) em cima do valor real; so
;  os valores REAIS $00 e $FF (osso "branco"/"preto" solidos, os mais
;  comuns numa imagem 1-bit) sao RLE-comprimidos (marcador + byte de
;  contagem); qualquer outro valor e' literal. So' guarda PADRAO (video),
;  nunca cor - "layout" no Graphos III e' so' o desenho em preto e branco.
;
;  .SCR (tela/display): cabecalho BSAVE de 7 bytes (tipo + inicio + FIM +
;  exec, inicio=exec=$9200 ou $9000 dependendo da versao) seguido de uma
;  ROTINA DE APRESENTACAO (codigo Z80 de verdade - carrega/copia os dados
;  pras posicoes corretas de VRAM quando executada via BLOAD"nome",R) de
;  tamanho VARIAVEL, seguida de 6144 bytes de padrao (Pattern Generator
;  Table) + 6144 bytes de cor (Color Table). GraphosNative_ScrProgramData
;  abaixo e' uma rotina de 129 bytes extraida de um arquivo .SCR real
;  (graphos-IV/G3Viewer/msxmetal.scr, criado com o Graphos III de verdade
;  por CyberKnight) - confirmada BYTE A BYTE identica (pelo menos nos
;  primeiros 118 bytes, ate' o RET final) a` mesma rotina encontrada em
;  graphos-IV/III/GRAPHOS.SCR e STARWARS.SCR (que usam base $9200 em vez de
;  $9000), confirmando que a rotina NAO depende do proprio endereco de carga
;  (so' referencia enderecos fixos de VRAM) - segura de usar com base $9200,
;  o mesmo endereco ja usado por ALF/LAY nesta IDE. IMPORTANTE (descoberto
;  comparando VARIAS amostras reais): o tamanho da rotina NAO e' sempre 129 -
;  graphos-IV/III/ROBOCOP.SCR, S-COBRA.SCR, FULL-T.SCR e nossos proprios
;  graphos/Telas/MSX_310/S-SHP*.SCR usam uma rotina de 121 bytes (uma
;  variante ligeiramente diferente, ainda nao decodificada byte a byte - tem
;  ate' um trecho com texto legivel tipo "COMPACTA"/"IMPR"/"PRIA", parece um
;  save feito por uma versao/ferramenta com suporte a impressora, mas o
;  bloco final de 12288 bytes de padrao+cor e' identico em formato). Por
;  isso GraphosNative_LoadScr NUNCA confia no tamanho do cabecalho pra saber
;  quantos bytes pular - ele calcula a partir do TAMANHO REAL DO ARQUIVO em
;  disco (TamanhoArquivo - 7 - 12288 = tamanho da rotina, seja ela qual for),
;  ja que os ultimos 12288 bytes sao sempre padrao+cor de tamanho fixo. A
;  rotina em si e' sempre DESCARTADA sem ser interpretada (nunca executamos
;  Z80 nenhum aqui, so' pulamos os bytes) - so' precisamos saber ONDE ela
;  termina. Ao EXPORTAR, sempre gravamos a rotina de 129 bytes verificada
;  (funciona de verdade num MSX real via BLOAD"nome",R), independente de
;  qual variante foi usada no arquivo importado originalmente.
;
;  IMPORTANTE: o padrao/cor dentro do arquivo NAO usa a mesma ordem
;  "linha a linha" que os arrays PatternBit(Y,X)/RowFG,RowBG(Y,Cx) desta
;  IDE usam internamente (esses sao simples e "logicos", pensados so' pra
;  nosso proprio uso) - o arquivo usa o endereco REAL de VRAM do TMS9918
;  pro modo SCREEN 2: a tela e' dividida em 3 "tercos" de 64 scanlines cada
;  (T=0,1,2), e dentro de cada terco existem 256 "tiles" de 8x8 pixels
;  (A=0..255, endereco relativo A*8+T*$800); os 8 bytes de um tile sao as 8
;  scanlines desse tile, um byte cada. GraphosNative_Pack/UnpackPatternVram
;  e Pack/UnpackColorVram fazem essa conversao nos dois sentidos - toda
;  leitura/escrita de arquivo passa por eles.
;
;  .SHP (shape/banco de shapes): sem cabecalho BSAVE - estrutura propria
;  "01 (bloco) 02 (bloco) ... xx (bloco) FF", onde o primeiro byte de cada
;  bloco e' o NUMERO do shape (1-254, igual a nossa propria numeracao de
;  projeto) seguido de tipo(1 byte)/largura em pixels sempre multiplo de 8
;  (1 byte)/altura em tiles de 8x8 (1 byte) e os dados: tipo 1=so padrao,
;  2=padrao+cor, 3=mascara+padrao, 4=mascara+padrao+cor. Cada plano tem
;  Largura*AlturaEmTiles bytes, em ordem de TILE simples (sem os 3 tercos
;  do .SCR/.LAY - shapes nao vivem fixos na VRAM). Byte $FF sozinho (sem
;  T/S/H depois) marca o fim do banco.
;
;  Exportamos sempre tipo 2 (padrao+cor, sem mascara - carimbo MASCARA/
;  AND/OR/XOR do modulo 14g ja cobre o uso pratico); ao importar, shapes
;  tipo 3/4 (com mascara) tem a mascara ignorada por enquanto (nenhuma
;  ferramenta desta IDE ainda usa mascara de shape - fase futura).
; ------------------------------------------------------------
;

#GraphosNative_TableSize = 6144 ; #Scr2_Height * #Scr2_Cols = 192*32

; --- Conversao logica (PatternBit/RowFG/RowBG desta IDE) <-> ordem real de
; VRAM (3 tercos x 256 tiles x 8 bytes) usada pelos arquivos .SCR/.LAY ---

Procedure GraphosNative_PackPatternVram(Array PatternBit.a(2), Array Out.a(1))
  Protected Y, X, Bit, T, TileRow, Cx, A, Scanline, Offset, ByteVal.a
  For Y = 0 To #Scr2_Height - 1
    T = Y / 64
    TileRow = (Y % 64) / 8
    Scanline = Y % 8
    For Cx = 0 To #Scr2_Cols - 1
      A = TileRow * 32 + Cx
      Offset = T * 2048 + A * 8 + Scanline
      ByteVal = 0
      For Bit = 0 To 7
        X = Cx * 8 + Bit
        If PatternBit(Y, X)
          ByteVal | (1 << (7 - Bit))
        EndIf
      Next
      Out(Offset) = ByteVal
    Next
  Next
EndProcedure

Procedure GraphosNative_UnpackPatternVram(Array In.a(1), Array PatternBit.a(2))
  Protected Y, X, Bit, T, TileRow, Cx, A, Scanline, Offset, ByteVal.a
  For Y = 0 To #Scr2_Height - 1
    T = Y / 64
    TileRow = (Y % 64) / 8
    Scanline = Y % 8
    For Cx = 0 To #Scr2_Cols - 1
      A = TileRow * 32 + Cx
      Offset = T * 2048 + A * 8 + Scanline
      ByteVal = In(Offset)
      For Bit = 0 To 7
        X = Cx * 8 + Bit
        If ByteVal & (1 << (7 - Bit))
          PatternBit(Y, X) = 1
        Else
          PatternBit(Y, X) = 0
        EndIf
      Next
    Next
  Next
EndProcedure

Procedure GraphosNative_PackColorVram(Array RowFG.a(2), Array RowBG.a(2), Array Out.a(1))
  Protected Y, T, TileRow, Cx, A, Scanline, Offset
  For Y = 0 To #Scr2_Height - 1
    T = Y / 64
    TileRow = (Y % 64) / 8
    Scanline = Y % 8
    For Cx = 0 To #Scr2_Cols - 1
      A = TileRow * 32 + Cx
      Offset = T * 2048 + A * 8 + Scanline
      Out(Offset) = ((RowFG(Y, Cx) & $F) << 4) | (RowBG(Y, Cx) & $F)
    Next
  Next
EndProcedure

Procedure GraphosNative_UnpackColorVram(Array In.a(1), Array RowFG.a(2), Array RowBG.a(2))
  Protected Y, T, TileRow, Cx, A, Scanline, Offset, ByteVal.a
  For Y = 0 To #Scr2_Height - 1
    T = Y / 64
    TileRow = (Y % 64) / 8
    Scanline = Y % 8
    For Cx = 0 To #Scr2_Cols - 1
      A = TileRow * 32 + Cx
      Offset = T * 2048 + A * 8 + Scanline
      ByteVal = In(Offset)
      RowFG(Y, Cx) = (ByteVal >> 4) & $F
      RowBG(Y, Cx) = ByteVal & $F
    Next
  Next
EndProcedure

; --- .LAY: RLE restrito (so' $00/$FF) + ofuscacao "+$99" -----------------

Procedure.i GraphosNative_SaveLay(Path.s, Array PatternBit.a(2))
  Dim Vram.a(#GraphosNative_TableSize - 1)
  GraphosNative_PackPatternVram(PatternBit(), Vram())

  ; Upper bound seguro pro buffer codificado: pior caso e' todo byte
  ; isolado 0/$FF virando um par (marcador+contagem=1), dobrando o tamanho.
  Dim Enc.a(#GraphosNative_TableSize * 2 - 1)
  Protected Pos = 0, OutPos = 0, CurVal.a, RunLen, EncByte.a
  While Pos < #GraphosNative_TableSize
    CurVal = Vram(Pos)
    If CurVal = 0 Or CurVal = $FF
      RunLen = 1
      While Pos + RunLen < #GraphosNative_TableSize And Vram(Pos + RunLen) = CurVal And RunLen < 255
        RunLen + 1
      Wend
      EncByte = (CurVal + $99) & $FF
      Enc(OutPos) = EncByte : OutPos + 1
      Enc(OutPos) = RunLen : OutPos + 1
      Pos + RunLen
    Else
      EncByte = (CurVal + $99) & $FF
      Enc(OutPos) = EncByte : OutPos + 1
      Pos + 1
    EndIf
  Wend

  Protected FileNum = CreateFile(#PB_Any, Path)
  If Not FileNum
    ProcedureReturn #False
  EndIf
  Protected EndAddr = $9200 + OutPos - 1
  WriteByte(FileNum, $FE)
  WriteByte(FileNum, $00) : WriteByte(FileNum, $92)
  WriteByte(FileNum, EndAddr & $FF) : WriteByte(FileNum, (EndAddr >> 8) & $FF)
  WriteByte(FileNum, $00) : WriteByte(FileNum, $92)
  Protected i
  For i = 0 To OutPos - 1
    WriteByte(FileNum, Enc(i))
  Next
  CloseFile(FileNum)
  ProcedureReturn #True
EndProcedure

Procedure.i GraphosNative_LoadLay(Path.s, Array PatternBit.a(2))
  Protected FileNum = ReadFile(#PB_Any, Path)
  If Not FileNum
    ProcedureReturn #False
  EndIf
  ReadByte(FileNum) ; tipo (sempre $FE, nao usado)
  Protected StartLo.a = ReadByte(FileNum), StartHi.a = ReadByte(FileNum)
  Protected EndLo.a = ReadByte(FileNum), EndHi.a = ReadByte(FileNum)
  ReadByte(FileNum) : ReadByte(FileNum) ; exec (nao usado)
  Protected StartAddr = StartLo | (StartHi << 8)
  Protected EndAddr = EndLo | (EndHi << 8)
  Protected Counter = EndAddr - StartAddr + 1

  Dim Vram.a(#GraphosNative_TableSize - 1)
  Protected OutPos = 0, RawByte.a, DecVal.a, RepCount.a, i

  While Counter > 0 And Not Eof(FileNum) And OutPos < #GraphosNative_TableSize
    RawByte = ReadByte(FileNum)
    Counter - 1
    DecVal = (RawByte - $99) & $FF
    If DecVal = 0 Or DecVal = $FF
      If Eof(FileNum)
        Break
      EndIf
      RepCount = ReadByte(FileNum)
      For i = 1 To RepCount
        If OutPos < #GraphosNative_TableSize
          Vram(OutPos) = DecVal : OutPos + 1
        EndIf
      Next
    Else
      Vram(OutPos) = DecVal : OutPos + 1
    EndIf
  Wend
  CloseFile(FileNum)

  GraphosNative_UnpackPatternVram(Vram(), PatternBit())
  ProcedureReturn #True
EndProcedure

; --- .SCR: rotina de apresentacao (129 bytes, extraida de um .SCR real -
; ver comentario grande no topo) + padrao + cor -----------------------

#GraphosNative_ScrProgramLen = 129

DataSection
  GraphosNative_ScrProgramData:
  Data.b $CD,$CB,$FE,$3B,$3B,$E1,$11,$76,$00,$19,$E5,$CD,$41,$00,$E1,$E5
  Data.b $11,$00,$00,$01,$00,$18,$CD,$5C,$00,$E1,$01,$00,$18,$09,$11,$00
  Data.b $20,$CD,$5C,$00,$C3,$44,$00,$11,$00,$18,$3E,$08,$D9,$21,$00,$00
  Data.b $11,$00,$20,$01,$08,$00,$D9,$F5,$E5,$D5,$D9,$E5,$D5,$D9,$01,$00
  Data.b $03,$7E,$D9,$CD,$4D,$00,$D9,$19,$7E,$A7,$ED,$52,$D9,$19,$CD,$4D
  Data.b $00,$A7,$ED,$52,$D9,$C5,$01,$08,$00,$09,$C1,$D9,$09,$D9,$0B,$78
  Data.b $B1,$20,$DE,$D9,$D1,$E1,$23,$D9,$D1,$E1,$23,$F1,$3D,$20,$C8,$C9
  Data.b $3E,$20,$E5,$11,$00,$18,$19,$E5,$FD,$00,$00,$00,$00,$00,$00,$00
  Data.b $00
EndDataSection

Procedure.i GraphosNative_SaveScr(Path.s, Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2))
  Dim PatVram.a(#GraphosNative_TableSize - 1)
  Dim ColVram.a(#GraphosNative_TableSize - 1)
  GraphosNative_PackPatternVram(PatternBit(), PatVram())
  GraphosNative_PackColorVram(RowFG(), RowBG(), ColVram())

  Protected FileNum = CreateFile(#PB_Any, Path)
  If Not FileNum
    ProcedureReturn #False
  EndIf
  Protected TotalLen = #GraphosNative_ScrProgramLen + #GraphosNative_TableSize * 2
  Protected EndAddr = $9200 + TotalLen - 1
  WriteByte(FileNum, $FE)
  WriteByte(FileNum, $00) : WriteByte(FileNum, $92)
  WriteByte(FileNum, EndAddr & $FF) : WriteByte(FileNum, (EndAddr >> 8) & $FF)
  WriteByte(FileNum, $00) : WriteByte(FileNum, $92)

  Protected *Ptr = ?GraphosNative_ScrProgramData
  Protected i
  For i = 1 To #GraphosNative_ScrProgramLen
    WriteByte(FileNum, PeekA(*Ptr))
    *Ptr + 1
  Next
  For i = 0 To #GraphosNative_TableSize - 1
    WriteByte(FileNum, PatVram(i))
  Next
  For i = 0 To #GraphosNative_TableSize - 1
    WriteByte(FileNum, ColVram(i))
  Next
  CloseFile(FileNum)
  ProcedureReturn #True
EndProcedure

Procedure.i GraphosNative_LoadScr(Path.s, Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2))
  Protected FileNum = ReadFile(#PB_Any, Path)
  If Not FileNum
    ProcedureReturn #False
  EndIf
  ReadByte(FileNum) ; tipo
  ReadByte(FileNum) : ReadByte(FileNum) ; inicio (nao usado)
  ReadByte(FileNum) : ReadByte(FileNum) ; fim (nao usado - ver nota abaixo)
  ReadByte(FileNum) : ReadByte(FileNum) ; exec (nao usado)

  ; O tamanho da rotina de apresentacao VARIA de arquivo pra arquivo -
  ; comparando amostras reais (graphos-IV/III/GRAPHOS.SCR e STARWARS.SCR tem
  ; rotina de 129 bytes; ROBOCOP.SCR/S-COBRA.SCR/FULL-T.SCR e nossos proprios
  ; graphos/Telas/*.SCR tem 121 bytes - programas diferentes, nao um bug de
  ; leitura) o campo "fim" do cabecalho BSAVE NEM SEMPRE bate com o tamanho
  ; real do arquivo em disco (alguns exemplares vieram truncados/copiados de
  ; forma imperfeita de disquete). Por isso calculamos o tamanho da rotina a
  ; partir do TAMANHO REAL DO ARQUIVO, nao do cabecalho: os ultimos 12288
  ; bytes SEMPRE sao padrao+cor (tamanho fixo), entao o que sobra antes disso
  ; e' a rotina, seja ela qual for - ela e' descartada sem ser interpretada.
  Protected FileLen = Lof(FileNum)
  Protected ProgLen = FileLen - 7 - #GraphosNative_TableSize * 2
  If ProgLen < 0 : ProgLen = 0 : EndIf

  Protected i
  For i = 1 To ProgLen
    If Eof(FileNum) : Break : EndIf
    ReadByte(FileNum) ; descarta a rotina de apresentacao - nao interpretada
  Next

  Dim PatVram.a(#GraphosNative_TableSize - 1)
  Dim ColVram.a(#GraphosNative_TableSize - 1)
  For i = 0 To #GraphosNative_TableSize - 1
    If Eof(FileNum)
      PatVram(i) = 0
    Else
      PatVram(i) = ReadByte(FileNum)
    EndIf
  Next
  For i = 0 To #GraphosNative_TableSize - 1
    If Eof(FileNum)
      ColVram(i) = $F1
    Else
      ColVram(i) = ReadByte(FileNum)
    EndIf
  Next
  CloseFile(FileNum)

  GraphosNative_UnpackPatternVram(PatVram(), PatternBit())
  GraphosNative_UnpackColorVram(ColVram(), RowFG(), RowBG())
  ProcedureReturn #True
EndProcedure

; --- .SHP: banco de shapes (sem cabecalho BSAVE) --------------------------

Structure GraphosNative_ShpEntry
  Offset.i
  Number.i
  Type.i
  Width.i
  HeightTiles.i
EndStructure

; Sempre exporta tipo 2 (padrao+cor) como arquivo de UM shape so' (mais
; util pra "exportar este shape" do que manter/mutar um banco existente com
; varios) - K=1 sempre, terminado por $FF.
Procedure.i GraphosNative_SaveShp(Path.s, Width.i, HeightTiles.i, Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2))
  Protected WTiles = Width / 8
  Protected PlaneSize = Width * HeightTiles
  Dim PatBuf.a(PlaneSize - 1)
  Dim ColBuf.a(PlaneSize - 1)
  Protected tx, ty, line, bit, x, y, ByteVal.a, Offset

  For ty = 0 To HeightTiles - 1
    For tx = 0 To WTiles - 1
      For line = 0 To 7
        Offset = (tx + ty * WTiles) * 8 + line
        y = ty * 8 + line
        ByteVal = 0
        For bit = 0 To 7
          x = tx * 8 + bit
          If PatternBit(y, x)
            ByteVal | (1 << (7 - bit))
          EndIf
        Next
        PatBuf(Offset) = ByteVal
        ColBuf(Offset) = ((RowFG(y, tx) & $F) << 4) | (RowBG(y, tx) & $F)
      Next
    Next
  Next

  Protected FileNum = CreateFile(#PB_Any, Path)
  If Not FileNum
    ProcedureReturn #False
  EndIf
  WriteByte(FileNum, 1)
  WriteByte(FileNum, 2)
  WriteByte(FileNum, Width)
  WriteByte(FileNum, HeightTiles)
  Protected i
  For i = 0 To PlaneSize - 1
    WriteByte(FileNum, PatBuf(i))
  Next
  For i = 0 To PlaneSize - 1
    WriteByte(FileNum, ColBuf(i))
  Next
  WriteByte(FileNum, $FF)
  CloseFile(FileNum)
  ProcedureReturn #True
EndProcedure

; Mapeia todos os shapes de um banco (arquivo com varios blocos) sem ler os
; dados de imagem - so' os cabecalhos [K][T][S][H], pulando o resto.
Procedure GraphosNative_ScanShpFile(Path.s, List Entries.GraphosNative_ShpEntry())
  ClearList(Entries())
  Protected FileNum = ReadFile(#PB_Any, Path)
  If Not FileNum
    ProcedureReturn
  EndIf
  Protected FileLen = Lof(FileNum)
  Protected K.a, T.a, S.a, H.a, PlaneSize, Skip

  While Loc(FileNum) < FileLen
    K = ReadByte(FileNum)
    If K = $FF Or Eof(FileNum)
      Break
    EndIf
    If Loc(FileNum) + 3 > FileLen
      Break
    EndIf
    T = ReadByte(FileNum)
    S = ReadByte(FileNum)
    H = ReadByte(FileNum)
    AddElement(Entries())
    Entries()\Offset = Loc(FileNum) - 4
    Entries()\Number = K
    Entries()\Type = T
    Entries()\Width = S
    Entries()\HeightTiles = H
    PlaneSize = S * H
    Select T
      Case 1 : Skip = PlaneSize
      Case 3 : Skip = PlaneSize * 2
      Case 4 : Skip = PlaneSize * 3
      Default : Skip = PlaneSize * 2 ; tipo 2 (padrao) - tambem usado como fallback de tipo desconhecido
    EndSelect
    FileSeek(FileNum, Loc(FileNum) + Skip)
  Wend
  CloseFile(FileNum)
EndProcedure

; Le UM shape (posicao/tipo/tamanho ja conhecidos de GraphosNative_ScanShpFile)
; pros arrays locais 0-based (mesmo layout de ShapeCapturePattern/FG/BG do
; modulo 14e). Mascara (tipos 3/4) e' lida mas ainda IGNORADA - nenhuma
; ferramenta desta IDE usa mascara de shape por enquanto (fase futura).
Procedure.i GraphosNative_LoadShapeAt(Path.s, Offset.i, Type.i, Width.i, HeightTiles.i, Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2))
  Protected FileNum = ReadFile(#PB_Any, Path)
  If Not FileNum
    ProcedureReturn #False
  EndIf
  FileSeek(FileNum, Offset + 4)

  Protected WTiles = Width / 8
  Protected PlaneSize = Width * HeightTiles
  Dim PatBuf.a(PlaneSize - 1)
  Dim ColBuf.a(PlaneSize - 1)
  Protected i

  Select Type
    Case 1
      For i = 0 To PlaneSize - 1 : PatBuf(i) = ReadByte(FileNum) : Next
      For i = 0 To PlaneSize - 1 : ColBuf(i) = $F0 : Next
    Case 3
      For i = 0 To PlaneSize - 1 : ReadByte(FileNum) : Next ; mascara, ignorada
      For i = 0 To PlaneSize - 1 : PatBuf(i) = ReadByte(FileNum) : Next
      For i = 0 To PlaneSize - 1 : ColBuf(i) = $F0 : Next
    Case 4
      For i = 0 To PlaneSize - 1 : ReadByte(FileNum) : Next ; mascara, ignorada
      For i = 0 To PlaneSize - 1 : PatBuf(i) = ReadByte(FileNum) : Next
      For i = 0 To PlaneSize - 1 : ColBuf(i) = ReadByte(FileNum) : Next
    Default ; tipo 2 (padrao+cor)
      For i = 0 To PlaneSize - 1 : PatBuf(i) = ReadByte(FileNum) : Next
      For i = 0 To PlaneSize - 1 : ColBuf(i) = ReadByte(FileNum) : Next
  EndSelect
  CloseFile(FileNum)

  Protected tx, ty, line, bit, x, y, Offs, ByteVal.a
  For ty = 0 To HeightTiles - 1
    For tx = 0 To WTiles - 1
      For line = 0 To 7
        Offs = (tx + ty * WTiles) * 8 + line
        y = ty * 8 + line
        ByteVal = PatBuf(Offs)
        For bit = 0 To 7
          x = tx * 8 + bit
          If ByteVal & (1 << (7 - bit))
            PatternBit(y, x) = 1
          Else
            PatternBit(y, x) = 0
          EndIf
        Next
        RowFG(y, tx) = (ColBuf(Offs) >> 4) & $F
        RowBG(y, tx) = ColBuf(Offs) & $F
      Next
    Next
  Next
  ProcedureReturn #True
EndProcedure
