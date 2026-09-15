;
; ------------------------------------------------------------
;  Z80RelFormat.pbi - so as definicoes de TIPO (Structure/Enumeration)
;  compartilhadas entre o assembler (Z80Asm.pbi) e o futuro linker
;  (Z80Link.pbi, Fase B) para representar um valor "relocável": não só o
;  número de 16 bits, mas também a que segmento ele pertence - mesmo
;  conceito do "Address" do Nestor80 (Relocatable/Address.cs), ver
;  docs/reference/nestor80-language.md e docs/resumo-asm.md.
;
;  Sem nenhuma Procedure aqui de proposito: este arquivo e incluido via
;  XIncludeFile de DENTRO do bloco "DeclareModule X ... EndDeclareModule" de
;  quem precisar dele (hoje so Z80Asm.pbi) - um Module do PureBasic nao
;  enxerga Structure/Enumeration definidas fora dele mesmo com forward
;  declaration (confirmado empiricamente nesta sessao - ver
;  docs/resumo-asm.md, log de decisoes tecnicas), entao a inclusao PRECISA
;  acontecer dentro do DeclareModule, e DeclareModule so aceita
;  declaracoes (nao corpo de Procedure) - por isso os helpers
;  Z80Addr_Make()/etc. moraram para dentro de cada Module que usa este
;  arquivo, em vez de ficarem aqui (mesmo espirito de nao compartilhar
;  Structure entre modulos ja usado em ProjectDB.pbi/psg_sounds/screens -
;  ver comentario la).
; ------------------------------------------------------------
;

; Enumeration normal (nao EnumerationBinary) de proposito - #Z80Seg_Absolute
; precisa valer 0, que e o valor default de um Z80Addr recem-criado
; (Dim/AddMapElement/etc zeram os bytes) sem passar por Z80Addr_Make.
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
