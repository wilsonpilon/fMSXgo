;
; ------------------------------------------------------------
;  Z80RelFormatLink.pbi - copia de Z80RelFormat.pbi dedicada ao Module
;  Z80Link (mesmo conteudo, arquivo diferente de proposito).
;
;  Motivo de existir uma copia em vez de reaproveitar Z80RelFormat.pbi
;  direto: XIncludeFile deduplica por CAMINHO DE ARQUIVO em todo o programa
;  (nao por Module) - quando Z80Asm.pbi e Z80Link.pbi coexistem na mesma
;  unidade de compilacao (BadigEditor.pb), o "XIncludeFile Z80RelFormat.pbi"
;  de dentro de "DeclareModule Z80Link" virava no-op (o compilador ja tinha
;  processado esse caminho de arquivo dentro de "DeclareModule Z80Asm"
;  antes), deixando #Z80Seg_Code/etc. inexistentes no namespace de Z80Link
;  (erro "Constant not found" em LEffectiveAddr) - so nao aparecia antes
;  porque editor/tools/Z80LinkTestCli.pb nunca incluia Z80Asm.pbi na mesma
;  unidade. Mesmo espirito de "cada Module tem a sua copia" ja usado pra
;  Z80LinkItemType (ver comentario em Z80Link.pbi, Enumeration logo depois
;  do "Module Z80Link").
; ------------------------------------------------------------
;

Enumeration Z80SegType
  #Z80Seg_Absolute  ; ASEG - endereço fixo, nunca deslocado pelo linker
  #Z80Seg_Code      ; CSEG
  #Z80Seg_Data      ; DSEG
  #Z80Seg_Common    ; bloco COMMON nomeado (ver CommonName)
EndEnumeration

Structure Z80Addr
  Value.u             ; valor de 16 bits, relativo ao inicio do segmento (0 se ASEG = absoluto de verdade)
  SegType.b           ; #Z80Seg_Absolute/Code/Data/Common
  CommonName.s        ; nome do bloco COMMON, só quando SegType = #Z80Seg_Common
EndStructure
