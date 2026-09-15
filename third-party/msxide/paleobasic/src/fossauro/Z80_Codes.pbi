; Translated from Codes.h - Generated automatically

Case $20 :  If *R\AF\B\l&#Z_FLAG : *R\PC\W + 1 : Else : *R\ICount = *R\ICount - 5 : M_JR : EndIf
Case $30 :  If *R\AF\B\l&#C_FLAG : *R\PC\W + 1 : Else : *R\ICount = *R\ICount - 5 : M_JR : EndIf
Case $28 :  If *R\AF\B\l&#Z_FLAG : *R\ICount = *R\ICount - 5 : M_JR : Else : *R\PC\W + 1 : EndIf
Case $38 :  If *R\AF\B\l&#C_FLAG : *R\ICount = *R\ICount - 5 : M_JR : Else : *R\PC\W + 1 : EndIf
Case $C2 :  If *R\AF\B\l&#Z_FLAG : *R\PC\W + 2 : Else : M_JP : EndIf
Case $D2 :  If *R\AF\B\l&#C_FLAG : *R\PC\W + 2 : Else : M_JP : EndIf
Case $E2 :  If *R\AF\B\l&#P_FLAG : *R\PC\W + 2 : Else : M_JP : EndIf
Case $F2 :  If *R\AF\B\l&#S_FLAG : *R\PC\W + 2 : Else : M_JP : EndIf
Case $CA :  If *R\AF\B\l&#Z_FLAG : M_JP : Else : *R\PC\W + 2 : EndIf
Case $DA :  If *R\AF\B\l&#C_FLAG : M_JP : Else : *R\PC\W + 2 : EndIf
Case $EA :  If *R\AF\B\l&#P_FLAG : M_JP : Else : *R\PC\W + 2 : EndIf
Case $FA :  If *R\AF\B\l&#S_FLAG : M_JP : Else : *R\PC\W + 2 : EndIf
Case $C0 :  If  Not (*R\AF\B\l&#Z_FLAG) : *R\ICount = *R\ICount - 6 : M_RET : EndIf
Case $D0 :  If  Not (*R\AF\B\l&#C_FLAG) : *R\ICount = *R\ICount - 6 : M_RET : EndIf
Case $E0 :  If  Not (*R\AF\B\l&#P_FLAG) : *R\ICount = *R\ICount - 6 : M_RET : EndIf
Case $F0 :  If  Not (*R\AF\B\l&#S_FLAG) : *R\ICount = *R\ICount - 6 : M_RET : EndIf
Case $C8 :  If *R\AF\B\l&#Z_FLAG : *R\ICount = *R\ICount - 6 : M_RET : EndIf
Case $D8 :  If *R\AF\B\l&#C_FLAG : *R\ICount = *R\ICount - 6 : M_RET : EndIf
Case $E8 :  If *R\AF\B\l&#P_FLAG : *R\ICount = *R\ICount - 6 : M_RET : EndIf
Case $F8 :  If *R\AF\B\l&#S_FLAG : *R\ICount = *R\ICount - 6 : M_RET : EndIf
Case $C4 :  If *R\AF\B\l&#Z_FLAG : *R\PC\W + 2 : Else : *R\ICount = *R\ICount - 7 : M_CALL : EndIf
Case $D4 :  If *R\AF\B\l&#C_FLAG : *R\PC\W + 2 : Else : *R\ICount = *R\ICount - 7 : M_CALL : EndIf
Case $E4 :  If *R\AF\B\l&#P_FLAG : *R\PC\W + 2 : Else : *R\ICount = *R\ICount - 7 : M_CALL : EndIf
Case $F4 :  If *R\AF\B\l&#S_FLAG : *R\PC\W + 2 : Else : *R\ICount = *R\ICount - 7 : M_CALL : EndIf
Case $CC :  If *R\AF\B\l&#Z_FLAG : *R\ICount = *R\ICount - 7 : M_CALL : Else : *R\PC\W + 2 : EndIf
Case $DC :  If *R\AF\B\l&#C_FLAG : *R\ICount = *R\ICount - 7 : M_CALL : Else : *R\PC\W + 2 : EndIf
Case $EC :  If *R\AF\B\l&#P_FLAG : *R\ICount = *R\ICount - 7 : M_CALL : Else : *R\PC\W + 2 : EndIf
Case $FC :  If *R\AF\B\l&#S_FLAG : *R\ICount = *R\ICount - 7 : M_CALL : Else : *R\PC\W + 2 : EndIf
Case $80 :  M_ADD(*R\BC\B\h) 
Case $81 :  M_ADD(*R\BC\B\l) 
Case $82 :  M_ADD(*R\DE\B\h) 
Case $83 :  M_ADD(*R\DE\B\l) 
Case $84 :  M_ADD(*R\HL\B\h) 
Case $85 :  M_ADD(*R\HL\B\l) 
Case $87 :  M_ADD(*R\AF\B\h) 
Case $86 :  I=SafeRdZ80(*R\HL\W) : M_ADD(I) 
Case $C6 :  I=ReadOp(*R) : M_ADD(I) 
Case $90 :  M_SUB(*R\BC\B\h) 
Case $91 :  M_SUB(*R\BC\B\l) 
Case $92 :  M_SUB(*R\DE\B\h) 
Case $93 :  M_SUB(*R\DE\B\l) 
Case $94 :  M_SUB(*R\HL\B\h) 
Case $95 :  M_SUB(*R\HL\B\l) 
Case $97 :  *R\AF\B\h=0 : *R\AF\B\l=#N_FLAG|#Z_FLAG 
Case $96 :  I=SafeRdZ80(*R\HL\W) : M_SUB(I) 
Case $D6 :  I=ReadOp(*R) : M_SUB(I) 
Case $A0 :  M_AND(*R\BC\B\h) 
Case $A1 :  M_AND(*R\BC\B\l) 
Case $A2 :  M_AND(*R\DE\B\h) 
Case $A3 :  M_AND(*R\DE\B\l) 
Case $A4 :  M_AND(*R\HL\B\h) 
Case $A5 :  M_AND(*R\HL\B\l) 
Case $A7 :  M_AND(*R\AF\B\h) 
Case $A6 :  I=SafeRdZ80(*R\HL\W) : M_AND(I) 
Case $E6 :  I=ReadOp(*R) : M_AND(I) 
Case $B0 :  M_OR(*R\BC\B\h) 
Case $B1 :  M_OR(*R\BC\B\l) 
Case $B2 :  M_OR(*R\DE\B\h) 
Case $B3 :  M_OR(*R\DE\B\l) 
Case $B4 :  M_OR(*R\HL\B\h) 
Case $B5 :  M_OR(*R\HL\B\l) 
Case $B7 :  M_OR(*R\AF\B\h) 
Case $B6 :  I=SafeRdZ80(*R\HL\W) : M_OR(I) 
Case $F6 :  I=ReadOp(*R) : M_OR(I) 
Case $88 :  M_ADC(*R\BC\B\h) 
Case $89 :  M_ADC(*R\BC\B\l) 
Case $8A :  M_ADC(*R\DE\B\h) 
Case $8B :  M_ADC(*R\DE\B\l) 
Case $8C :  M_ADC(*R\HL\B\h) 
Case $8D :  M_ADC(*R\HL\B\l) 
Case $8F :  M_ADC(*R\AF\B\h) 
Case $8E :  I=SafeRdZ80(*R\HL\W) : M_ADC(I) 
Case $CE :  I=ReadOp(*R) : M_ADC(I) 
Case $98 :  M_SBC(*R\BC\B\h) 
Case $99 :  M_SBC(*R\BC\B\l) 
Case $9A :  M_SBC(*R\DE\B\h) 
Case $9B :  M_SBC(*R\DE\B\l) 
Case $9C :  M_SBC(*R\HL\B\h) 
Case $9D :  M_SBC(*R\HL\B\l) 
Case $9F :  M_SBC(*R\AF\B\h) 
Case $9E :  I=SafeRdZ80(*R\HL\W) : M_SBC(I) 
Case $DE :  I=ReadOp(*R) : M_SBC(I) 
Case $A8 :  M_XOR(*R\BC\B\h) 
Case $A9 :  M_XOR(*R\BC\B\l) 
Case $AA :  M_XOR(*R\DE\B\h) 
Case $AB :  M_XOR(*R\DE\B\l) 
Case $AC :  M_XOR(*R\HL\B\h) 
Case $AD :  M_XOR(*R\HL\B\l) 
Case $AF :  *R\AF\B\h=0 : *R\AF\B\l=#P_FLAG|#Z_FLAG 
Case $AE :  I=SafeRdZ80(*R\HL\W) : M_XOR(I) 
Case $EE :  I=ReadOp(*R) : M_XOR(I) 
Case $B8 :  M_CP(*R\BC\B\h) 
Case $B9 :  M_CP(*R\BC\B\l) 
Case $BA :  M_CP(*R\DE\B\h) 
Case $BB :  M_CP(*R\DE\B\l) 
Case $BC :  M_CP(*R\HL\B\h) 
Case $BD :  M_CP(*R\HL\B\l) 
Case $BF :  *R\AF\B\l=#N_FLAG|#Z_FLAG 
Case $BE :  I=SafeRdZ80(*R\HL\W) : M_CP(I) 
Case $FE :  I=ReadOp(*R) : M_CP(I) 
Case $01 :  M_LDWORD(BC) 
Case $11 :  M_LDWORD(DE) 
Case $21 :  M_LDWORD(HL) 
Case $31 :  M_LDWORD(SP) 
Case $E9 :  *R\PC\W=*R\HL\W : If JumpZ80 : JumpZ80(*R\PC\W) : EndIf
Case $F9 :  *R\SP\W=*R\HL\W 
Case $0A :  *R\AF\B\h=SafeRdZ80(*R\BC\W) 
Case $1A :  *R\AF\B\h=SafeRdZ80(*R\DE\W) 
Case $09 :  M_ADDW(HL,BC) 
Case $19 :  M_ADDW(HL,DE) 
Case $29 :  M_ADDW(HL,HL) 
Case $39 :  M_ADDW(HL,SP) 
Case $0B :  *R\BC\W = *R\BC\W - 1 
Case $1B :  *R\DE\W = *R\DE\W - 1 
Case $2B :  *R\HL\W = *R\HL\W - 1 
Case $3B :  *R\SP\W = *R\SP\W - 1 
Case $03 :  *R\BC\W = *R\BC\W + 1 
Case $13 :  *R\DE\W = *R\DE\W + 1 
Case $23 :  *R\HL\W = *R\HL\W + 1 
Case $33 :  *R\SP\W = *R\SP\W + 1 
Case $05 :  M_DEC(*R\BC\B\h) 
Case $0D :  M_DEC(*R\BC\B\l) 
Case $15 :  M_DEC(*R\DE\B\h) 
Case $1D :  M_DEC(*R\DE\B\l) 
Case $25 :  M_DEC(*R\HL\B\h) 
Case $2D :  M_DEC(*R\HL\B\l) 
Case $3D :  M_DEC(*R\AF\B\h) 
Case $35 :  I=SafeRdZ80(*R\HL\W) : M_DEC(I) : WrZ80(*R\HL\W,I) 
Case $04 :  M_INC(*R\BC\B\h) 
Case $0C :  M_INC(*R\BC\B\l) 
Case $14 :  M_INC(*R\DE\B\h) 
Case $1C :  M_INC(*R\DE\B\l) 
Case $24 :  M_INC(*R\HL\B\h) 
Case $2C :  M_INC(*R\HL\B\l) 
Case $3C :  M_INC(*R\AF\B\h) 
Case $34 :  I=SafeRdZ80(*R\HL\W) : M_INC(I) : WrZ80(*R\HL\W,I) 
Case $07 :  I=(Bool(*R\AF\B\h&$80) * (#C_FLAG)) 
   *R\AF\B\h=(*R\AF\B\h<<1)|I 
   *R\AF\B\l=(*R\AF\B\l&~(#C_FLAG|#N_FLAG|#H_FLAG))|I 
Case $17 :  I=(Bool(*R\AF\B\h&$80) * (#C_FLAG)) 
   *R\AF\B\h=(*R\AF\B\h<<1)|(*R\AF\B\l&#C_FLAG) 
   *R\AF\B\l=(*R\AF\B\l&~(#C_FLAG|#N_FLAG|#H_FLAG))|I 
Case $0F :  I=*R\AF\B\h&$01 
   *R\AF\B\h=(*R\AF\B\h>>1)|((Bool(I) * ($80))) 
   *R\AF\B\l=(*R\AF\B\l&~(#C_FLAG|#N_FLAG|#H_FLAG))|I 
Case $1F :  I=*R\AF\B\h&$01 
   *R\AF\B\h=(*R\AF\B\h>>1)|((Bool(*R\AF\B\l&#C_FLAG) * ($80))) 
   *R\AF\B\l=(*R\AF\B\l&~(#C_FLAG|#N_FLAG|#H_FLAG))|I 
Case $C7 :  M_RST($0000) 
Case $CF :  M_RST($0008) 
Case $D7 :  M_RST($0010) 
Case $DF :  M_RST($0018) 
Case $E7 :  M_RST($0020) 
Case $EF :  M_RST($0028) 
Case $F7 :  M_RST($0030) 
Case $FF :  M_RST($0038) 
Case $C5 :  M_PUSH(BC) 
Case $D5 :  M_PUSH(DE) 
Case $E5 :  M_PUSH(HL) 
Case $F5 :  M_PUSH(AF) 
Case $C1 :  M_POP(BC) 
Case $D1 :  M_POP(DE) 
Case $E1 :  M_POP(HL) 
Case $F1 :  M_POP(AF) 
Case $10 :  *R\BC\B\h - 1 : If *R\BC\B\h : *R\ICount = *R\ICount - 5 : M_JR : Else : *R\PC\W + 1 : EndIf
Case $C3 :  M_JP 
Case $18 :  M_JR 
Case $CD :  M_CALL 
Case $C9 :  M_RET 
Case $37 :  S(#C_FLAG) : R(#N_FLAG|#H_FLAG) 
Case $2F :  *R\AF\B\h=~*R\AF\B\h : S(#N_FLAG|#H_FLAG) 
Case $00 
Case $D3 :  I=ReadOp(*R) : OutZ80(I|(*R\AF\W&$FF00),*R\AF\B\h) 
Case $DB :  I=ReadOp(*R) : *R\AF\B\h=InZ80(I|(*R\AF\W&$FF00)) 
Case $76 :  *R\PC\W = *R\PC\W - 1 
   *R\IFF = *R\IFF | #IFF_HALT 
   *R\IBackup=0 
   *R\ICount=0 
Case $F3 :  If *R\IFF&#IFF_EI : *R\ICount = *R\ICount + *R\IBackup-1 : EndIf
   *R\IFF = *R\IFF & ~(#IFF_1|#IFF_2|#IFF_EI) 
Case $FB :  If  Not (*R\IFF&(#IFF_1|#IFF_EI)) : *R\IFF = *R\IFF | #IFF_2|#IFF_EI 
     *R\IBackup=*R\ICount 
     *R\ICount=1 : EndIf
Case $3F :  *R\AF\B\l = *R\AF\B\l ! #C_FLAG : R(#N_FLAG|#H_FLAG) 
   *R\AF\B\l = *R\AF\B\l | (Bool(*R\AF\B\l&#C_FLAG = 0) * (#H_FLAG)) 
Case $D9 :  J\W=*R\BC\W : *R\BC\W=*R\BC1\W : *R\BC1\W=J\W 
   J\W=*R\DE\W : *R\DE\W=*R\DE1\W : *R\DE1\W=J\W 
   J\W=*R\HL\W : *R\HL\W=*R\HL1\W : *R\HL1\W=J\W 
Case $EB :  J\W=*R\DE\W : *R\DE\W=*R\HL\W : *R\HL\W=J\W 
Case $08 :  J\W=*R\AF\W : *R\AF\W=*R\AF1\W : *R\AF1\W=J\W 
Case $40 :  *R\BC\B\h=*R\BC\B\h 
Case $48 :  *R\BC\B\l=*R\BC\B\h 
Case $50 :  *R\DE\B\h=*R\BC\B\h 
Case $58 :  *R\DE\B\l=*R\BC\B\h 
Case $60 :  *R\HL\B\h=*R\BC\B\h 
Case $68 :  *R\HL\B\l=*R\BC\B\h 
Case $78 :  *R\AF\B\h=*R\BC\B\h 
Case $70 :  WrZ80(*R\HL\W,*R\BC\B\h) 
Case $41 :  *R\BC\B\h=*R\BC\B\l 
Case $49 :  *R\BC\B\l=*R\BC\B\l 
Case $51 :  *R\DE\B\h=*R\BC\B\l 
Case $59 :  *R\DE\B\l=*R\BC\B\l 
Case $61 :  *R\HL\B\h=*R\BC\B\l 
Case $69 :  *R\HL\B\l=*R\BC\B\l 
Case $79 :  *R\AF\B\h=*R\BC\B\l 
Case $71 :  WrZ80(*R\HL\W,*R\BC\B\l) 
Case $42 :  *R\BC\B\h=*R\DE\B\h 
Case $4A :  *R\BC\B\l=*R\DE\B\h 
Case $52 :  *R\DE\B\h=*R\DE\B\h 
Case $5A :  *R\DE\B\l=*R\DE\B\h 
Case $62 :  *R\HL\B\h=*R\DE\B\h 
Case $6A :  *R\HL\B\l=*R\DE\B\h 
Case $7A :  *R\AF\B\h=*R\DE\B\h 
Case $72 :  WrZ80(*R\HL\W,*R\DE\B\h) 
Case $43 :  *R\BC\B\h=*R\DE\B\l 
Case $4B :  *R\BC\B\l=*R\DE\B\l 
Case $53 :  *R\DE\B\h=*R\DE\B\l 
Case $5B :  *R\DE\B\l=*R\DE\B\l 
Case $63 :  *R\HL\B\h=*R\DE\B\l 
Case $6B :  *R\HL\B\l=*R\DE\B\l 
Case $7B :  *R\AF\B\h=*R\DE\B\l 
Case $73 :  WrZ80(*R\HL\W,*R\DE\B\l) 
Case $44 :  *R\BC\B\h=*R\HL\B\h 
Case $4C :  *R\BC\B\l=*R\HL\B\h 
Case $54 :  *R\DE\B\h=*R\HL\B\h 
Case $5C :  *R\DE\B\l=*R\HL\B\h 
Case $64 :  *R\HL\B\h=*R\HL\B\h 
Case $6C :  *R\HL\B\l=*R\HL\B\h 
Case $7C :  *R\AF\B\h=*R\HL\B\h 
Case $74 :  WrZ80(*R\HL\W,*R\HL\B\h) 
Case $45 :  *R\BC\B\h=*R\HL\B\l 
Case $4D :  *R\BC\B\l=*R\HL\B\l 
Case $55 :  *R\DE\B\h=*R\HL\B\l 
Case $5D :  *R\DE\B\l=*R\HL\B\l 
Case $65 :  *R\HL\B\h=*R\HL\B\l 
Case $6D :  *R\HL\B\l=*R\HL\B\l 
Case $7D :  *R\AF\B\h=*R\HL\B\l 
Case $75 :  WrZ80(*R\HL\W,*R\HL\B\l) 
Case $47 :  *R\BC\B\h=*R\AF\B\h 
Case $4F :  *R\BC\B\l=*R\AF\B\h 
Case $57 :  *R\DE\B\h=*R\AF\B\h 
Case $5F :  *R\DE\B\l=*R\AF\B\h 
Case $67 :  *R\HL\B\h=*R\AF\B\h 
Case $6F :  *R\HL\B\l=*R\AF\B\h 
Case $7F :  *R\AF\B\h=*R\AF\B\h 
Case $77 :  WrZ80(*R\HL\W,*R\AF\B\h) 
Case $02 :  WrZ80(*R\BC\W,*R\AF\B\h) 
Case $12 :  WrZ80(*R\DE\W,*R\AF\B\h) 
Case $46 :  *R\BC\B\h=SafeRdZ80(*R\HL\W) 
Case $4E :  *R\BC\B\l=SafeRdZ80(*R\HL\W) 
Case $56 :  *R\DE\B\h=SafeRdZ80(*R\HL\W) 
Case $5E :  *R\DE\B\l=SafeRdZ80(*R\HL\W) 
Case $66 :  *R\HL\B\h=SafeRdZ80(*R\HL\W) 
Case $6E :  *R\HL\B\l=SafeRdZ80(*R\HL\W) 
Case $7E :  *R\AF\B\h=SafeRdZ80(*R\HL\W) 
Case $06 :  *R\BC\B\h=ReadOp(*R) 
Case $0E :  *R\BC\B\l=ReadOp(*R) 
Case $16 :  *R\DE\B\h=ReadOp(*R) 
Case $1E :  *R\DE\B\l=ReadOp(*R) 
Case $26 :  *R\HL\B\h=ReadOp(*R) 
Case $2E :  *R\HL\B\l=ReadOp(*R) 
Case $3E :  *R\AF\B\h=ReadOp(*R) 
Case $36 :  WrZ80(*R\HL\W,ReadOp(*R)) 
Case $22 :  J\B\l=ReadOp(*R) 
   J\B\h=ReadOp(*R) 
   WrZ80(J\W,*R\HL\B\l)  : J\W + 1
   WrZ80(J\W,*R\HL\B\h) 
Case $2A :  J\B\l=ReadOp(*R) 
   J\B\h=ReadOp(*R) 
   *R\HL\B\l=SafeRdZ80(J\W)  : J\W + 1
   *R\HL\B\h=SafeRdZ80(J\W) 
Case $3A :  J\B\l=ReadOp(*R) 
   J\B\h=ReadOp(*R) 
   *R\AF\B\h=SafeRdZ80(J\W) 
Case $32 :  J\B\l=ReadOp(*R) 
   J\B\h=ReadOp(*R) 
   WrZ80(J\W,*R\AF\B\h) 
Case $E3 :  J\B\l=SafeRdZ80(*R\SP\W) : J\B\h=SafeRdZ80(*R\SP\W + 1)
   WrZ80(*R\SP\W,*R\HL\B\l) : WrZ80(*R\SP\W + 1,*R\HL\B\h)
   *R\HL\W=J\W
Case $27 :  J\W=*R\AF\B\h 
   If *R\AF\B\l&#C_FLAG : J\W = J\W | 256 : EndIf
   If *R\AF\B\l&#H_FLAG : J\W = J\W | 512 : EndIf
   If *R\AF\B\l&#N_FLAG : J\W = J\W | 1024 : EndIf
   *R\AF\W=DAATable(J\W) 
 Default :   If *R\TrapBadOps : Debug "Unrecognized instruction" : EndIf
