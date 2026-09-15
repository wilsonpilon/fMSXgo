;
; ------------------------------------------------------------
;  Criar -> Alfabeto Aquarela...: editor de charset MSX no formato .FNT do
;  Aquarela (ver docs/reference/aquarela.md pra engenharia reversa completa)
;  - registro de 32 bytes por caractere, em 2 planos de 16 bytes (bytes 0-15
;  = coluna esquerda de cada uma das 16 linhas, bytes 16-31 = coluna
;  direita), formando um glifo real de 16x16 - MESMO quando o desenho de
;  fato so usa a metade esquerda (fontes "8x8" do Aquarela, que sao a
;  maioria das amostras testadas), a grade de edicao mostra sempre as 16
;  colunas inteiras, igual ao editor de verdade.
;
;  DESLOCAMENTO DE 7 BYTES (confirmado 2026-07-23 comparando pixel a pixel
;  contra uma screenshot do Aquarela rodando de verdade num emulador): o
;  primeiro registro de 32 bytes NAO comeca no byte 0 do arquivo, comeca no
;  byte 7 (#AqEd_RecordOffset). Os 7 bytes antes disso sao a ponta final
;  (wrap-around) do ULTIMO registro do arquivo, nao lixo/cabecalho - ver
;  #AqEd_SaveFnt() pra como isso e replicado ao salvar. Sem esse
;  deslocamento, cada caractere decodificado parecia ter um "floreio"
;  decorativo desconexo no topo (na real, os ultimos 7 bytes do caractere
;  ANTERIOR) e faltavam as ~7 linhas finais do caractere de verdade.
;
;  Os primeiros 46 caracteres sao editaveis aqui (A-Z, &, ?, !, ", 0-9, ., :,
;  -, (, ), ,) - o trecho da tabela de caracteres do Aquarela confirmado por
;  testes reais do usuario contra varias fontes comerciais do disco original
;  (ver "Observacao visual do usuario" em aquarela.md pros demais, e o
;  arquivo LOGO.FNT que confirma a mesma ordem ate entrar em minusculas). Ao
;  salvar, os registros 46-71 (ate completar 72 = formato de 2304 bytes, a
;  variante sem bytes finais nao explicados e com todos os arquivos testados
;  carregando sem erro no Aquarela) sao preenchidos com o byte de
;  posicao-vazia $40.
;
;  Sem integracao com ProjectDB (que hoje so modela o formato 256x8 do
;  Graphos III) - esta e uma ferramenta autocontida baseada em arquivo
;  (Abrir/Salvar/Salvar como), no mesmo espirito do fluxo
;  "Carregar do Graphos III.../Salvar como..." do editor de alfabetos, so
;  que sem o conceito de "projeto" por enquanto.
; ------------------------------------------------------------
;

#AqEd_Cols = 8
#AqEd_Rows = 6          ; 8*6 = 48 celulas na grade, so as 46 primeiras sao usadas (ver AqEd_Slots)
#AqEd_Slots = 46        ; A-Z(26) + & ? ! "(4) + 0-9(10) + . : - ( ) ,(6) - confirmado por teste real
#AqEd_RecSize = 32      ; bytes por caractere (2 planos de 16 bytes)
#AqEd_RecordOffset = 7  ; deslocamento do 1o registro real em relacao ao inicio do arquivo (ver nota acima)
#AqEd_FileSlots = 72    ; total de registros de um .fnt exportado (formato de 2304 bytes)
#AqEd_FileDataSize = 2304 ; #AqEd_FileSlots * #AqEd_RecSize
#AqEd_BlankFill = $40   ; byte de "posicao vazia" usado nos registros 46..71 ao salvar

#AqEd_TableCellW = 40
#AqEd_TableLabelH = 14
#AqEd_TableZoom = 2
#AqEd_TableGlyphPx = 16 * #AqEd_TableZoom              ; 32
#AqEd_TableCellH = #AqEd_TableLabelH + #AqEd_TableGlyphPx + 4 ; 50
#AqEd_TableCanvasW = #AqEd_Cols * #AqEd_TableCellW
#AqEd_TableCanvasH = #AqEd_Rows * #AqEd_TableCellH

#AqEd_EditPixelPx = 20
#AqEd_EditCanvasSize = 16 * #AqEd_EditPixelPx           ; 320

#AqEd_FilePattern = "Alfabeto Aquarela (*.fnt)|*.fnt|Todos os arquivos (*.*)|*.*"

Global AqEd_LastError.s = ""

Procedure.s AqEd_GetLastError()
  ProcedureReturn AqEd_LastError
EndProcedure

; Rotulo do caractere na posicao Index (0-45) - trecho da tabela do Aquarela
; confirmado por teste real (ver comentario do topo do arquivo): A-Z, &, ?,
; !, ", 0-9, ., :, -, (, ), ,
Procedure.s AqEd_CharLabel(Index.i)
  Select Index
    Case 0 To 25
      ProcedureReturn Chr(65 + Index)
    Case 26
      ProcedureReturn "&"
    Case 27
      ProcedureReturn "?"
    Case 28
      ProcedureReturn "!"
    Case 29
      ProcedureReturn Chr(34)
    Case 30 To 39
      ProcedureReturn Str(Index - 30)
    Case 40
      ProcedureReturn "."
    Case 41
      ProcedureReturn ":"
    Case 42
      ProcedureReturn "-"
    Case 43
      ProcedureReturn "("
    Case 44
      ProcedureReturn ")"
    Case 45
      ProcedureReturn ","
  EndSelect
  ProcedureReturn "?"
EndProcedure

Procedure.s AqEd_CharStatusText(CharIndex.i)
  ProcedureReturn "Caractere: " + Str(CharIndex) + " ('" + AqEd_CharLabel(CharIndex) + "')"
EndProcedure

; Le um .fnt do Aquarela - sem cabecalho, so exige que o arquivo tenha pelo
; menos #AqEd_Slots registros de 32 bytes; qualquer coisa alem disso (os
; arquivos reais tem ate 71/72 registros) e ignorada, ja que so os primeiros
; 46 caracteres sao editaveis aqui. Nao valida se a posicao 0 realmente
; decodifica como 'A' (a marca de arquivo integro descoberta em
; aquarela.md) - fica a cargo do usuario conferir visualmente por enquanto.
Procedure.b AqEd_LoadFnt(Path.s, Array CharsetBytes.a(2))
  Protected FileNum = ReadFile(#PB_Any, Path)
  If Not FileNum
    AqEd_LastError = "Nao foi possivel abrir o arquivo: " + Path
    ProcedureReturn #False
  EndIf

  Protected MinSize = #AqEd_RecordOffset + #AqEd_Slots * #AqEd_RecSize
  Protected FileLen = Lof(FileNum)
  If FileLen < MinSize
    CloseFile(FileNum)
    AqEd_LastError = "Arquivo pequeno demais pra ser um alfabeto Aquarela valido (" +
                      Str(FileLen) + " bytes, esperado pelo menos " + Str(MinSize) + ")."
    ProcedureReturn #False
  EndIf

  Protected *Buffer = AllocateMemory(MinSize)
  ReadData(FileNum, *Buffer, MinSize)
  CloseFile(FileNum)

  Protected Idx, ByteOfs
  For Idx = 0 To #AqEd_Slots - 1
    For ByteOfs = 0 To #AqEd_RecSize - 1
      CharsetBytes(Idx, ByteOfs) = PeekA(*Buffer + #AqEd_RecordOffset + Idx * #AqEd_RecSize + ByteOfs)
    Next
  Next
  FreeMemory(*Buffer)
  AqEd_LastError = ""
  ProcedureReturn #True
EndProcedure

; Grava um .fnt no formato de 2304 bytes (72 registros) - a variante
; confirmada por teste real do usuario contra todas as amostras testadas
; (ver aquarela.md). Os primeiros #AqEd_RecordOffset (7) bytes do arquivo e
; tudo alem dos 46 caracteres editados aqui ficam com o byte de
; posicao-vazia $40 (mesma convencao usada por dezenas de arquivos reais do
; corpus) - os 46 caracteres editados vao nos registros reais 0..45,
; deslocados #AqEd_RecordOffset bytes conforme a formula confirmada (ver
; comentario no topo do arquivo).
Procedure.b AqEd_SaveFnt(Path.s, Array CharsetBytes.a(2))
  Protected FileNum = CreateFile(#PB_Any, Path)
  If Not FileNum
    AqEd_LastError = "Nao foi possivel criar o arquivo: " + Path
    ProcedureReturn #False
  EndIf

  Protected *Buffer = AllocateMemory(#AqEd_FileDataSize)
  FillMemory(*Buffer, #AqEd_FileDataSize, #AqEd_BlankFill, #PB_Byte)

  Protected Idx, ByteOfs
  For Idx = 0 To #AqEd_Slots - 1
    For ByteOfs = 0 To #AqEd_RecSize - 1
      PokeA(*Buffer + #AqEd_RecordOffset + Idx * #AqEd_RecSize + ByteOfs, CharsetBytes(Idx, ByteOfs))
    Next
  Next

  WriteData(FileNum, *Buffer, #AqEd_FileDataSize)
  CloseFile(FileNum)
  FreeMemory(*Buffer)
  AqEd_LastError = ""
  ProcedureReturn #True
EndProcedure

; Desempacota os 32 bytes do caractere CharIndex em EditGrid (16x16, 0/1) -
; formula confirmada em aquarela.md: byte esquerdo = CharsetBytes(idx, linha),
; byte direito = CharsetBytes(idx, 16+linha), bit 7 = coluna mais a esquerda
; de cada byte.
Procedure AqEd_UnpackChar(Array CharsetBytes.a(2), CharIndex.i, Array EditGrid.a(2))
  Protected Row, Col, LeftByte.a, RightByte.a
  For Row = 0 To 15
    LeftByte = CharsetBytes(CharIndex, Row)
    RightByte = CharsetBytes(CharIndex, 16 + Row)
    For Col = 0 To 7
      If LeftByte & (1 << (7 - Col))
        EditGrid(Row, Col) = 1
      Else
        EditGrid(Row, Col) = 0
      EndIf
      If RightByte & (1 << (7 - Col))
        EditGrid(Row, 8 + Col) = 1
      Else
        EditGrid(Row, 8 + Col) = 0
      EndIf
    Next
  Next
EndProcedure

; Empacota EditGrid (16x16, 0/1) de volta nos 32 bytes do caractere
; CharIndex - chamado pelo botao "Registrar", nunca automaticamente.
Procedure AqEd_PackChar(Array EditGrid.a(2), Array CharsetBytes.a(2), CharIndex.i)
  Protected Row, Col, LeftByte.a, RightByte.a
  For Row = 0 To 15
    LeftByte = 0 : RightByte = 0
    For Col = 0 To 7
      If EditGrid(Row, Col)
        LeftByte = LeftByte | (1 << (7 - Col))
      EndIf
      If EditGrid(Row, 8 + Col)
        RightByte = RightByte | (1 << (7 - Col))
      EndIf
    Next
    CharsetBytes(CharIndex, Row) = LeftByte
    CharsetBytes(CharIndex, 16 + Row) = RightByte
  Next
EndProcedure

Procedure AqEd_ClearEditGrid(Array EditGrid.a(2))
  Protected Row, Col
  For Row = 0 To 15
    For Col = 0 To 15
      EditGrid(Row, Col) = 0
    Next
  Next
EndProcedure

Procedure AqEd_InvertEditGrid(Array EditGrid.a(2))
  Protected Row, Col
  For Row = 0 To 15
    For Col = 0 To 15
      EditGrid(Row, Col) = 1 - EditGrid(Row, Col)
    Next
  Next
EndProcedure

; Empacota/desempacota EditGrid (16x16) de/para um array simples de 32
; bytes - clipboard de UM caractere solto, mesmo padrao de
; CharEd_PackGridBytes/UnpackGridBytes em CharsetEditorGui.pbi.
Procedure AqEd_PackGridBytes(Array EditGrid.a(2), Array OutBytes.a(1))
  Protected Row, Col, LeftByte.a, RightByte.a
  For Row = 0 To 15
    LeftByte = 0 : RightByte = 0
    For Col = 0 To 7
      If EditGrid(Row, Col)
        LeftByte = LeftByte | (1 << (7 - Col))
      EndIf
      If EditGrid(Row, 8 + Col)
        RightByte = RightByte | (1 << (7 - Col))
      EndIf
    Next
    OutBytes(Row) = LeftByte
    OutBytes(16 + Row) = RightByte
  Next
EndProcedure

Procedure AqEd_UnpackGridBytes(Array InBytes.a(1), Array EditGrid.a(2))
  Protected Row, Col, LeftByte.a, RightByte.a
  For Row = 0 To 15
    LeftByte = InBytes(Row)
    RightByte = InBytes(16 + Row)
    For Col = 0 To 7
      If LeftByte & (1 << (7 - Col))
        EditGrid(Row, Col) = 1
      Else
        EditGrid(Row, Col) = 0
      EndIf
      If RightByte & (1 << (7 - Col))
        EditGrid(Row, 8 + Col) = 1
      Else
        EditGrid(Row, 8 + Col) = 0
      EndIf
    Next
  Next
EndProcedure

Procedure.b AqEd_ConfirmDiscardChar()
  ProcedureReturn Bool(MessageRequester("Caractere nao registrado",
                        "As alteracoes deste caractere ainda nao foram registradas." + Chr(10) +
                        "Descartar mesmo assim?",
                        #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
EndProcedure

Procedure.b AqEd_ConfirmDiscardFile()
  ProcedureReturn Bool(MessageRequester("Alfabeto nao salvo",
                        "As alteracoes deste alfabeto (ou do caractere em edicao) ainda nao foram" + Chr(10) +
                        "salvas. Descartar mesmo assim?",
                        #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
EndProcedure

Procedure AqEd_UpdateFileLabel(G_FileLabel, CurrentPath.s)
  If CurrentPath = ""
    SetGadgetText(G_FileLabel, "Arquivo: (novo, sem nome)")
  Else
    SetGadgetText(G_FileLabel, "Arquivo: " + CurrentPath)
  EndIf
EndProcedure

; Tabela de 46 caracteres (grade de 8 colunas x 6 linhas, as 2 ultimas
; celulas ficam sem uso - so o trecho confirmado por teste real, ver
; comentario do topo do arquivo), com o rotulo do
; caractere acima de cada miniatura 16x16 (zoom 2x = 32x32). O caractere
; selecionado ganha um contorno vermelho ao redor da celula inteira.
Procedure AqEd_RedrawTable(Canvas, Array CharsetBytes.a(2), Selected.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf

  Box(0, 0, #AqEd_TableCanvasW, #AqEd_TableCanvasH, RGB(255, 255, 255))

  Protected CharIdx, TableRow, TableCol, CellX, CellY, GlyphX, GlyphY, PxRow, PxCol, LeftByte.a, RightByte.a
  Protected Zoom = #AqEd_TableZoom
  For CharIdx = 0 To #AqEd_Slots - 1
    TableRow = CharIdx / #AqEd_Cols
    TableCol = CharIdx % #AqEd_Cols
    CellX = TableCol * #AqEd_TableCellW
    CellY = TableRow * #AqEd_TableCellH
    GlyphX = CellX + (#AqEd_TableCellW - #AqEd_TableGlyphPx) / 2
    GlyphY = CellY + #AqEd_TableLabelH

    DrawingMode(#PB_2DDrawing_Transparent)
    FrontColor(RGB(90, 90, 90))
    DrawText(CellX + #AqEd_TableCellW / 2 - 4, CellY + 1, AqEd_CharLabel(CharIdx))

    DrawingMode(#PB_2DDrawing_Default)
    For PxRow = 0 To 15
      LeftByte = CharsetBytes(CharIdx, PxRow)
      RightByte = CharsetBytes(CharIdx, 16 + PxRow)
      For PxCol = 0 To 7
        If LeftByte & (1 << (7 - PxCol))
          Box(GlyphX + PxCol * Zoom, GlyphY + PxRow * Zoom, Zoom, Zoom, RGB(0, 0, 0))
        EndIf
        If RightByte & (1 << (7 - PxCol))
          Box(GlyphX + (8 + PxCol) * Zoom, GlyphY + PxRow * Zoom, Zoom, Zoom, RGB(0, 0, 0))
        EndIf
      Next
    Next

    If CharIdx = Selected
      DrawingMode(#PB_2DDrawing_Outlined)
      Box(CellX + 1, CellY + 1, #AqEd_TableCellW - 2, #AqEd_TableCellH - 2, RGB(205, 40, 40))
      DrawingMode(#PB_2DDrawing_Default)
    EndIf
  Next

  StopDrawing()
EndProcedure

; Grade grande editavel (16x16, um quadrado grosso por pixel) com linhas de
; grade finas e uma cruz central mais forte de referencia (entre as
; colunas/linhas 7 e 8) - sempre mostra as 16 colunas inteiras, mesmo pros
; glifos "8x8" do Aquarela que na pratica so usam a metade esquerda.
Procedure AqEd_RedrawEditCanvas(Canvas, Array EditGrid.a(2))
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf

  Box(0, 0, #AqEd_EditCanvasSize, #AqEd_EditCanvasSize, RGB(255, 255, 255))

  Protected Row, Col, X, Y
  For Row = 0 To 15
    For Col = 0 To 15
      If EditGrid(Row, Col)
        X = Col * #AqEd_EditPixelPx
        Y = Row * #AqEd_EditPixelPx
        Box(X + 1, Y + 1, #AqEd_EditPixelPx - 1, #AqEd_EditPixelPx - 1, RGB(0, 0, 0))
      EndIf
    Next
  Next

  ; Linhas de grade desenhadas com Box() de 1px em vez de Line() - Line() nao
  ; renderizava nesta janela em teste real (StartDrawing() retornava sucesso,
  ; mas as linhas simplesmente nao apareciam na tela); Box() de 1px produz o
  ; mesmo resultado visual e funciona.
  Protected i
  For i = 0 To 16
    Box(i * #AqEd_EditPixelPx, 0, 1, #AqEd_EditCanvasSize, RGB(180, 180, 180))
    Box(0, i * #AqEd_EditPixelPx, #AqEd_EditCanvasSize, 1, RGB(180, 180, 180))
  Next
  Box(8 * #AqEd_EditPixelPx, 0, 1, #AqEd_EditCanvasSize, RGB(120, 120, 200))
  Box(0, 8 * #AqEd_EditPixelPx, #AqEd_EditCanvasSize, 1, RGB(120, 120, 200))

  StopDrawing()
EndProcedure

Procedure AquarelaCharsetEditor_OpenWindow(ParentWindow)
  Protected LeftX = 15
  Protected FileBarY = 15
  Protected TableY = FileBarY + 34
  Protected TableBottom = TableY + #AqEd_TableCanvasH
  Protected CloseY = TableBottom + 15

  Protected RightX = LeftX + #AqEd_TableCanvasW + 20
  Protected CharStatusY = TableY
  Protected EditY = CharStatusY + 24
  Protected BtnY = EditY + #AqEd_EditCanvasSize + 10
  Protected BtnY2 = BtnY + 32

  Protected WinW = RightX + #AqEd_EditCanvasSize + 15
  Protected WinH
  If CloseY + 30 > BtnY2 + 28
    WinH = CloseY + 30 + 15
  Else
    WinH = BtnY2 + 28 + 15
  EndIf

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Criar alfabeto MSX (Aquarela)",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  Protected Cx = LeftX
  Protected G_FileLabel = TextGadget(#PB_Any, Cx, FileBarY + 5, 260, 20, "")
  Cx + 270

  Protected NewIcon = CharEd_CreateNewIcon(#CharEd_IconSize)
  Protected G_New = ButtonImageGadget(#PB_Any, Cx, FileBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(NewIcon))
  GadgetToolTip(G_New, "Novo: comeca um alfabeto em branco (46 caracteres, A-Z + & ? ! aspas + 0-9 + . : - ( ) ,)")
  Cx + #CharEd_IconBtnW + 6

  Protected OpenIcon = CharEd_CreateOpenIcon(#CharEd_IconSize)
  Protected G_Open = ButtonImageGadget(#PB_Any, Cx, FileBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(OpenIcon))
  GadgetToolTip(G_Open, "Abrir...: carrega um alfabeto .fnt do Aquarela (le so os primeiros 46 caracteres)")
  Cx + #CharEd_IconBtnW + 6

  Protected RegisterIconFile = CharEd_CreateRegisterIcon(#CharEd_IconSize)
  Protected G_Save = ButtonImageGadget(#PB_Any, Cx, FileBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(RegisterIconFile))
  GadgetToolTip(G_Save, "Salvar: grava no arquivo atual (formato de 2304 bytes, 72 registros)")
  Cx + #CharEd_IconBtnW + 6

  Protected SaveAsIcon = CharEd_CreateSaveAsIcon(#CharEd_IconSize)
  Protected G_SaveAs = ButtonImageGadget(#PB_Any, Cx, FileBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(SaveAsIcon))
  GadgetToolTip(G_SaveAs, "Salvar como...: grava o alfabeto em edicao num novo arquivo .fnt")

  Protected G_Table = CanvasGadget(#PB_Any, LeftX, TableY, #AqEd_TableCanvasW, #AqEd_TableCanvasH)
  Protected G_Close = ThemedButton(LeftX, CloseY, 100, 30, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  Protected G_CharStatus = TextGadget(#PB_Any, RightX, CharStatusY, #AqEd_EditCanvasSize, 20, "")
  Protected G_EditCanvas = CanvasGadget(#PB_Any, RightX, EditY, #AqEd_EditCanvasSize, #AqEd_EditCanvasSize)

  Protected RegisterIcon = CharEd_CreateRegisterIcon(#CharEd_IconSize)
  Protected G_Register = ButtonImageGadget(#PB_Any, RightX, BtnY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(RegisterIcon))
  GadgetToolTip(G_Register, "Registrar: grava os pixels editados neste caractere")
  Protected ClearIcon = CharEd_CreateClearIcon(#CharEd_IconSize)
  Protected G_Clear = ButtonImageGadget(#PB_Any, RightX + #CharEd_IconBtnW + 6, BtnY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(ClearIcon))
  GadgetToolTip(G_Clear, "Limpar: apaga todos os pixels do caractere em edicao")
  Protected InvertIcon = CharEd_CreateInvertIcon(#CharEd_IconSize)
  Protected G_Invert = ButtonImageGadget(#PB_Any, RightX + (#CharEd_IconBtnW + 6) * 2, BtnY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(InvertIcon))
  GadgetToolTip(G_Invert, "Inverter: inverte todos os pixels do caractere em edicao")

  Protected CopyCharIcon = CharEd_CreateCopyIcon(#CharEd_IconSize)
  Protected G_CopyChar = ButtonImageGadget(#PB_Any, RightX, BtnY2, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(CopyCharIcon))
  GadgetToolTip(G_CopyChar, "Copiar: copia o caractere em edicao pra area de transferencia da sessao")
  Protected PasteCharIcon = CharEd_CreatePasteIcon(#CharEd_IconSize)
  Protected G_PasteChar = ButtonImageGadget(#PB_Any, RightX + #CharEd_IconBtnW + 6, BtnY2, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(PasteCharIcon))
  GadgetToolTip(G_PasteChar, "Colar: cola o caractere copiado neste caractere - use 'Registrar' pra valer")

  Dim CharsetBytes.a(#AqEd_Slots - 1, #AqEd_RecSize - 1)
  Dim EditGrid.a(15, 15)
  Protected Selected.i = 0
  Protected EditDirty.b = #False
  Protected FileDirty.b = #False
  Protected CurrentPath.s = ""

  Dim ClipChar.a(#AqEd_RecSize - 1)
  Protected ClipCharValid.b = #False

  AqEd_UpdateFileLabel(G_FileLabel, CurrentPath)
  AqEd_RedrawTable(G_Table, CharsetBytes(), Selected)
  AqEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
  SetGadgetText(G_CharStatus, AqEd_CharStatusText(Selected))

  Protected Event, Quit = #False
  Protected MouseX, MouseY, TableRow, TableCol, NewSelected, PxRow, PxCol
  Protected DragValue.i, LastEditRow.i = -1, LastEditCol.i = -1

  Repeat
    Event = WaitWindowEvent()
    Select Event

      Case #PB_Event_Gadget
        Select EventGadget()

          Case G_New
            If Not (EditDirty Or FileDirty) Or AqEd_ConfirmDiscardFile()
              Dim CharsetBytes.a(#AqEd_Slots - 1, #AqEd_RecSize - 1)
              CurrentPath = ""
              Selected = 0
              EditDirty = #False
              FileDirty = #False
              AqEd_UnpackChar(CharsetBytes(), Selected, EditGrid())
              AqEd_UpdateFileLabel(G_FileLabel, CurrentPath)
              AqEd_RedrawTable(G_Table, CharsetBytes(), Selected)
              AqEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
              SetGadgetText(G_CharStatus, AqEd_CharStatusText(Selected))
            EndIf

          Case G_Open
            Protected OpenPath.s = OpenFileRequester("Abrir alfabeto Aquarela (.fnt)", CurrentPath, #AqEd_FilePattern, 0)
            If OpenPath <> ""
              If Not (EditDirty Or FileDirty) Or AqEd_ConfirmDiscardFile()
                If AqEd_LoadFnt(OpenPath, CharsetBytes())
                  CurrentPath = OpenPath
                  Selected = 0
                  EditDirty = #False
                  FileDirty = #False
                  AqEd_UnpackChar(CharsetBytes(), Selected, EditGrid())
                  AqEd_UpdateFileLabel(G_FileLabel, CurrentPath)
                  AqEd_RedrawTable(G_Table, CharsetBytes(), Selected)
                  AqEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
                  SetGadgetText(G_CharStatus, AqEd_CharStatusText(Selected))
                Else
                  MessageRequester("Erro ao abrir alfabeto",
                                    "Nao foi possivel abrir:" + Chr(10) + OpenPath + Chr(10) + AqEd_GetLastError(),
                                    #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
                EndIf
              EndIf
            EndIf

          Case G_Save, G_SaveAs
            Protected SavePath.s = CurrentPath
            If EventGadget() = G_SaveAs Or SavePath = ""
              SavePath = SaveFileRequester("Salvar alfabeto Aquarela", CurrentPath, #AqEd_FilePattern, 0)
            EndIf
            If SavePath <> ""
              SavePath = EnsureExtension(SavePath, "fnt")
              If AqEd_SaveFnt(SavePath, CharsetBytes())
                CurrentPath = SavePath
                FileDirty = #False
                AqEd_UpdateFileLabel(G_FileLabel, CurrentPath)
              Else
                MessageRequester("Erro ao salvar alfabeto",
                                  "Nao foi possivel salvar em:" + Chr(10) + SavePath + Chr(10) + AqEd_GetLastError(),
                                  #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
              EndIf
            EndIf

          Case G_Register
            AqEd_PackChar(EditGrid(), CharsetBytes(), Selected)
            EditDirty = #False
            FileDirty = #True
            AqEd_RedrawTable(G_Table, CharsetBytes(), Selected)

          Case G_Clear
            AqEd_ClearEditGrid(EditGrid())
            EditDirty = #True
            AqEd_RedrawEditCanvas(G_EditCanvas, EditGrid())

          Case G_Invert
            AqEd_InvertEditGrid(EditGrid())
            EditDirty = #True
            AqEd_RedrawEditCanvas(G_EditCanvas, EditGrid())

          Case G_CopyChar
            AqEd_PackGridBytes(EditGrid(), ClipChar())
            ClipCharValid = #True

          Case G_PasteChar
            If ClipCharValid
              AqEd_UnpackGridBytes(ClipChar(), EditGrid())
              EditDirty = #True
              AqEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
            Else
              MessageRequester("Colar caractere", "Nenhum caractere foi copiado ainda nesta sessao.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
            EndIf

          Case G_Table
            If EventType() = #PB_EventType_LeftButtonDown
              MouseX = GetGadgetAttribute(G_Table, #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(G_Table, #PB_Canvas_MouseY)
              If MouseX >= 0 And MouseY >= 0
                TableCol = MouseX / #AqEd_TableCellW
                TableRow = MouseY / #AqEd_TableCellH
                If TableCol >= 0 And TableCol < #AqEd_Cols And TableRow >= 0 And TableRow < #AqEd_Rows
                  NewSelected = TableRow * #AqEd_Cols + TableCol
                  If NewSelected < #AqEd_Slots And NewSelected <> Selected
                    If Not EditDirty Or AqEd_ConfirmDiscardChar()
                      Selected = NewSelected
                      EditDirty = #False
                      AqEd_UnpackChar(CharsetBytes(), Selected, EditGrid())
                      AqEd_RedrawTable(G_Table, CharsetBytes(), Selected)
                      AqEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
                      SetGadgetText(G_CharStatus, AqEd_CharStatusText(Selected))
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
                PxCol = MouseX / #AqEd_EditPixelPx
                PxRow = MouseY / #AqEd_EditPixelPx
                If PxRow >= 0 And PxRow < 16 And PxCol >= 0 And PxCol < 16
                  If EditGrid(PxRow, PxCol)
                    DragValue = 0
                  Else
                    DragValue = 1
                  EndIf
                  EditGrid(PxRow, PxCol) = DragValue
                  EditDirty = #True
                  LastEditRow = PxRow : LastEditCol = PxCol
                  AqEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
                EndIf

              Case #PB_EventType_MouseMove
                If GetGadgetAttribute(G_EditCanvas, #PB_Canvas_Buttons) & #PB_Canvas_LeftButton
                  MouseX = GetGadgetAttribute(G_EditCanvas, #PB_Canvas_MouseX)
                  MouseY = GetGadgetAttribute(G_EditCanvas, #PB_Canvas_MouseY)
                  PxCol = MouseX / #AqEd_EditPixelPx
                  PxRow = MouseY / #AqEd_EditPixelPx
                  If PxRow >= 0 And PxRow < 16 And PxCol >= 0 And PxCol < 16 And (PxRow <> LastEditRow Or PxCol <> LastEditCol)
                    EditGrid(PxRow, PxCol) = DragValue
                    EditDirty = #True
                    LastEditRow = PxRow : LastEditCol = PxCol
                    AqEd_RedrawEditCanvas(G_EditCanvas, EditGrid())
                  EndIf
                EndIf

            EndSelect

          Case G_Close
            If Not (EditDirty Or FileDirty) Or AqEd_ConfirmDiscardFile()
              Quit = #True
            EndIf

        EndSelect

      Case #PB_Event_CloseWindow
        If Not (EditDirty Or FileDirty) Or AqEd_ConfirmDiscardFile()
          Quit = #True
        EndIf

    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
  FreeImage(NewIcon)
  FreeImage(OpenIcon)
  FreeImage(RegisterIconFile)
  FreeImage(SaveAsIcon)
  FreeImage(RegisterIcon)
  FreeImage(ClearIcon)
  FreeImage(InvertIcon)
  FreeImage(CopyCharIcon)
  FreeImage(PasteCharIcon)
EndProcedure
