;
; ------------------------------------------------------------
;  Gerador de PDF minimo pros comandos P/V do Mamute Assembler - pedido
;  explicito do usuario: "eu estou para criar um driver para Epson FX-80...
;  mas por hora, gere apenas um PDF A4 com os dados da listagem". PureBasic
;  nao tem biblioteca de PDF nativa, entao o arquivo e montado a mao aqui -
;  formato PDF 1.4 minimo (Catalog + Pages + 1 Page/Content por pagina de
;  listagem + fonte Courier base14, sem precisar embutir fonte nenhuma).
;  Conteudo e 100% texto ASCII simples (digitos hexa, letras, espacos,
;  pontuacao) - nao precisa de nenhuma codificacao especial nem stream
;  binario/comprimido, o que mantem a montagem do arquivo simples o
;  bastante pra fazer directo, sem depender de nenhuma lib externa.
; ------------------------------------------------------------
;

#MamutePdf_LinesPerPage = 56 ; cabe numa A4 com Courier 9pt + cabecalho, com folga

; Escapa parenteses e barra invertida - unicos caracteres que precisam de
; escape dentro de uma string literal "(...)" de um content stream PDF.
Procedure.s Mamute_PdfEscape(Text.s)
  Text = ReplaceString(Text, "\", "\\")
  Text = ReplaceString(Text, "(", "\(")
  Text = ReplaceString(Text, ")", "\)")
  ProcedureReturn Text
EndProcedure

; Gera um PDF A4 (595x842pt) simples com HeaderText no topo de cada pagina
; e Lines() (uma linha de texto por elemento, ja formatada por
; Mamute_BuildDumpLines) em Courier 9pt abaixo. #True se gravou com
; sucesso. Paginas quebradas automaticamente a cada
; #MamutePdf_LinesPerPage linhas.
Procedure.b Mamute_SavePdfListing(FilePath.s, List Lines.s(), HeaderText.s)
  Protected TotalLines.i = ListSize(Lines())
  Protected PageCount.i = (TotalLines + #MamutePdf_LinesPerPage - 1) / #MamutePdf_LinesPerPage
  If PageCount < 1 : PageCount = 1 : EndIf

  Protected FontObjNum.i = 3 + 2 * PageCount

  ; Monta o content stream de cada pagina (texto puro, comandos PDF minimos:
  ; BT/ET abre/fecha bloco de texto, Tf escolhe fonte/tamanho, Td move a
  ; posicao, Tj mostra uma string).
  Protected Dim ContentStreams.s(PageCount - 1)
  Protected PageIdx.i, LineCountThisPage.i, GlobalLineIdx.i = 0
  Protected CurStream.s

  ResetList(Lines())
  For PageIdx = 0 To PageCount - 1
    CurStream = "BT /F1 9 Tf 40 800 Td (" +
                Mamute_PdfEscape(HeaderText + " - Pagina " + Str(PageIdx + 1) + "/" + Str(PageCount)) +
                ") Tj" + Chr(10)
    CurStream + "0 -20 Td" + Chr(10)
    For LineCountThisPage = 1 To #MamutePdf_LinesPerPage
      If GlobalLineIdx >= TotalLines : Break : EndIf
      NextElement(Lines())
      CurStream + "(" + Mamute_PdfEscape(Lines()) + ") Tj 0 -11 Td" + Chr(10)
      GlobalLineIdx + 1
    Next
    CurStream + "ET"
    ContentStreams(PageIdx) = CurStream
  Next

  ; Corpo de cada objeto PDF, indexado pelo proprio numero do objeto (1-based,
  ; indice 0 nunca usado - objeto 0 e reservado pelo formato PDF pro proprio
  ; xref).
  Protected Dim ObjBody.s(FontObjNum)
  ObjBody(1) = "<< /Type /Catalog /Pages 2 0 R >>"

  Protected KidsStr.s = ""
  For PageIdx = 0 To PageCount - 1
    If KidsStr <> "" : KidsStr + " " : EndIf
    KidsStr + Str(3 + PageIdx) + " 0 R"
  Next
  ObjBody(2) = "<< /Type /Pages /Kids [" + KidsStr + "] /Count " + Str(PageCount) + " >>"

  Protected PageObjNum.i, ContentObjNum.i, StreamLen.i
  For PageIdx = 0 To PageCount - 1
    PageObjNum = 3 + PageIdx
    ContentObjNum = 3 + PageCount + PageIdx
    ObjBody(PageObjNum) = "<< /Type /Page /Parent 2 0 R /Resources << /Font << /F1 " + Str(FontObjNum) +
                          " 0 R >> >> /MediaBox [0 0 595 842] /Contents " + Str(ContentObjNum) + " 0 R >>"
    StreamLen = Len(ContentStreams(PageIdx))
    ObjBody(ContentObjNum) = "<< /Length " + Str(StreamLen) + " >>" + Chr(10) + "stream" + Chr(10) +
                             ContentStreams(PageIdx) + Chr(10) + "endstream"
  Next

  ObjBody(FontObjNum) = "<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>"

  ; Serializa tudo numa string so, registrando o offset (em bytes - todo o
  ; conteudo e ASCII puro de proposito, 1 caractere = 1 byte) de cada objeto
  ; pra montar a tabela xref no final, exigida pelo formato PDF.
  Protected PdfStr.s = "%PDF-1.4" + Chr(10)
  Protected Dim ObjOffset.i(FontObjNum)
  Protected ObjNum.i
  For ObjNum = 1 To FontObjNum
    ObjOffset(ObjNum) = Len(PdfStr)
    PdfStr + Str(ObjNum) + " 0 obj" + Chr(10) + ObjBody(ObjNum) + Chr(10) + "endobj" + Chr(10)
  Next

  Protected XrefOffset.i = Len(PdfStr)
  PdfStr + "xref" + Chr(10)
  PdfStr + "0 " + Str(FontObjNum + 1) + Chr(10)
  PdfStr + "0000000000 65535 f " + Chr(10)
  For ObjNum = 1 To FontObjNum
    PdfStr + RSet(Str(ObjOffset(ObjNum)), 10, "0") + " 00000 n " + Chr(10)
  Next
  PdfStr + "trailer" + Chr(10)
  PdfStr + "<< /Size " + Str(FontObjNum + 1) + " /Root 1 0 R >>" + Chr(10)
  PdfStr + "startxref" + Chr(10)
  PdfStr + Str(XrefOffset) + Chr(10)
  PdfStr + "%%EOF"

  Protected Fh = CreateFile(#PB_Any, FilePath)
  If Not Fh
    ProcedureReturn #False
  EndIf
  WriteString(Fh, PdfStr, #PB_Ascii)
  CloseFile(Fh)
  ProcedureReturn #True
EndProcedure
