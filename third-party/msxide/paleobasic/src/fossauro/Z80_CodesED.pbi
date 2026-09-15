; Translated from CodesED.h - Generated automatically

Case $FE :  PatchZ80(*R) 
Case $4A :  M_ADCW(BC) 
Case $5A :  M_ADCW(DE) 
Case $6A :  M_ADCW(HL) 
Case $7A :  M_ADCW(SP) 
Case $42 :  M_SBCW(BC) 
Case $52 :  M_SBCW(DE) 
Case $62 :  M_SBCW(HL) 
Case $72 :  M_SBCW(SP) 
Case $63 :  J\B\l=ReadOp(*R) 
   J\B\h=ReadOp(*R) 
   WrZ80(J\W,*R\HL\B\l)  : J\W + 1
   WrZ80(J\W,*R\HL\B\h) 
Case $53 :  J\B\l=ReadOp(*R) 
   J\B\h=ReadOp(*R) 
   WrZ80(J\W,*R\DE\B\l)  : J\W + 1
   WrZ80(J\W,*R\DE\B\h) 
Case $43 :  J\B\l=ReadOp(*R) 
   J\B\h=ReadOp(*R) 
   WrZ80(J\W,*R\BC\B\l)  : J\W + 1
   WrZ80(J\W,*R\BC\B\h) 
Case $73 :  J\B\l=ReadOp(*R) 
   J\B\h=ReadOp(*R) 
   WrZ80(J\W,*R\SP\B\l)  : J\W + 1
   WrZ80(J\W,*R\SP\B\h) 
Case $6B :  J\B\l=ReadOp(*R) 
   J\B\h=ReadOp(*R) 
   *R\HL\B\l=SafeRdZ80(J\W)  : J\W + 1
   *R\HL\B\h=SafeRdZ80(J\W) 
Case $5B :  J\B\l=ReadOp(*R) 
   J\B\h=ReadOp(*R) 
   *R\DE\B\l=SafeRdZ80(J\W)  : J\W + 1
   *R\DE\B\h=SafeRdZ80(J\W) 
Case $4B :  J\B\l=ReadOp(*R) 
   J\B\h=ReadOp(*R) 
   *R\BC\B\l=SafeRdZ80(J\W)  : J\W + 1
   *R\BC\B\h=SafeRdZ80(J\W) 
Case $7B :  J\B\l=ReadOp(*R) 
   J\B\h=ReadOp(*R) 
   *R\SP\B\l=SafeRdZ80(J\W)  : J\W + 1
   *R\SP\B\h=SafeRdZ80(J\W) 
Case $67 :  I=SafeRdZ80(*R\HL\W) 
   J\B\l=(I>>4)|(*R\AF\B\h<<4) 
   WrZ80(*R\HL\W,J\B\l) 
   *R\AF\B\h=(I&$0F)|(*R\AF\B\h&$F0) 
   *R\AF\B\l=PZSTable(*R\AF\B\h)|(*R\AF\B\l&#C_FLAG) 
Case $6F :  I=SafeRdZ80(*R\HL\W) 
   J\B\l=(I<<4)|(*R\AF\B\h&$0F) 
   WrZ80(*R\HL\W,J\B\l) 
   *R\AF\B\h=(I>>4)|(*R\AF\B\h&$F0) 
   *R\AF\B\l=PZSTable(*R\AF\B\h)|(*R\AF\B\l&#C_FLAG) 
Case $57 :  *R\AF\B\h=*R\I 
   *R\AF\B\l=(*R\AF\B\l&#C_FLAG)|((Bool(*R\IFF&#IFF_2) * (#P_FLAG)))|ZSTable(*R\AF\B\h) 
Case $5F :  *R\AF\B\h=*R\R 
   *R\AF\B\l=(*R\AF\B\l&#C_FLAG)|((Bool(*R\IFF&#IFF_2) * (#P_FLAG)))|ZSTable(*R\AF\B\h) 
Case $47 :  *R\I=*R\AF\B\h 
Case $4F :  *R\R=*R\AF\B\h 
Case $46 :  *R\IFF = *R\IFF & ~(#IFF_IM1|#IFF_IM2) 
Case $56 :  *R\IFF=(*R\IFF&~#IFF_IM2)|#IFF_IM1 
Case $5E :  *R\IFF=(*R\IFF&~#IFF_IM1)|#IFF_IM2 
Case $4D, $45 :  If *R\IFF&#IFF_2 : *R\IFF = *R\IFF | #IFF_1 : Else : *R\IFF = *R\IFF & ~#IFF_1 : EndIf
                M_RET 
Case $44 :  I=*R\AF\B\h : *R\AF\B\h=0 : M_SUB(I) 
Case $40 :  M_IN(*R\BC\B\h) 
Case $48 :  M_IN(*R\BC\B\l) 
Case $50 :  M_IN(*R\DE\B\h) 
Case $58 :  M_IN(*R\DE\B\l) 
Case $60 :  M_IN(*R\HL\B\h) 
Case $68 :  M_IN(*R\HL\B\l) 
Case $78 :  M_IN(*R\AF\B\h) 
Case $70 :  M_IN(J\B\l) 
Case $41 :  OutZ80(*R\BC\W,*R\BC\B\h) 
Case $49 :  OutZ80(*R\BC\W,*R\BC\B\l) 
Case $51 :  OutZ80(*R\BC\W,*R\DE\B\h) 
Case $59 :  OutZ80(*R\BC\W,*R\DE\B\l) 
Case $61 :  OutZ80(*R\BC\W,*R\HL\B\h) 
Case $69 :  OutZ80(*R\BC\W,*R\HL\B\l) 
Case $79 :  OutZ80(*R\BC\W,*R\AF\B\h) 
Case $71 :  OutZ80(*R\BC\W,0) 
Case $A2 :  WrZ80(*R\HL\W,InZ80(*R\BC\W))  : *R\HL\W + 1
   *R\BC\B\h - 1 
   *R\AF\B\l=#N_FLAG|((Bool(*R\BC\B\h = 0) * (#Z_FLAG))) 
Case $B2 :  WrZ80(*R\HL\W,InZ80(*R\BC\W))  : *R\HL\W + 1
   *R\BC\B\h - 1 : If *R\BC\B\h : *R\AF\B\l=#N_FLAG : *R\ICount = *R\ICount - 21 : *R\PC\W - 2 : Else : *R\AF\B\l=#Z_FLAG|#N_FLAG : *R\ICount = *R\ICount - 16 : EndIf
Case $AA :  WrZ80(*R\HL\W,InZ80(*R\BC\W))  : *R\HL\W - 1
   *R\BC\B\h - 1 
   *R\AF\B\l=#N_FLAG|((Bool(*R\BC\B\h = 0) * (#Z_FLAG))) 
Case $BA :  WrZ80(*R\HL\W,InZ80(*R\BC\W))  : *R\HL\W - 1
   *R\BC\B\h - 1 : If Not *R\BC\B\h : *R\AF\B\l=#N_FLAG : *R\ICount = *R\ICount - 21 : *R\PC\W - 2 : Else : *R\AF\B\l=#Z_FLAG|#N_FLAG : *R\ICount = *R\ICount - 16 : EndIf
Case $A3 :  *R\BC\B\h - 1 
   I=SafeRdZ80(*R\HL\W)  : *R\HL\W + 1
   OutZ80(*R\BC\W,I) 
   *R\AF\B\l=#N_FLAG|((Bool(*R\BC\B\h = 0) * (#Z_FLAG)|((Bool(*R\HL\B\l+I>255) * ((#C_FLAG|#H_FLAG)))))) 
Case $B3 :  *R\BC\B\h - 1 
   I=SafeRdZ80(*R\HL\W)  : *R\HL\W + 1
   OutZ80(*R\BC\W,I) 
   If *R\BC\B\h : *R\AF\B\l=#N_FLAG|((Bool(*R\HL\B\l+I>255) * ((#C_FLAG|#H_FLAG)))) 
     *R\ICount = *R\ICount - 21 
     *R\PC\W - 2 : Else : *R\AF\B\l=#Z_FLAG|#N_FLAG|((Bool(*R\HL\B\l+I>255) * ((#C_FLAG|#H_FLAG)))) 
     *R\ICount = *R\ICount - 16 : EndIf
Case $AB :  *R\BC\B\h - 1 
   I=SafeRdZ80(*R\HL\W)  : *R\HL\W - 1
   OutZ80(*R\BC\W,I) 
   *R\AF\B\l=#N_FLAG|((Bool(*R\BC\B\h = 0) * (#Z_FLAG)|((Bool(*R\HL\B\l+I>255) * ((#C_FLAG|#H_FLAG)))))) 
Case $BB :  *R\BC\B\h - 1 
   I=SafeRdZ80(*R\HL\W)  : *R\HL\W - 1
   OutZ80(*R\BC\W,I) 
   If *R\BC\B\h : *R\AF\B\l=#N_FLAG|((Bool(*R\HL\B\l+I>255) * ((#C_FLAG|#H_FLAG)))) 
     *R\ICount = *R\ICount - 21 
     *R\PC\W - 2 : Else : *R\AF\B\l=#Z_FLAG|#N_FLAG|((Bool(*R\HL\B\l+I>255) * ((#C_FLAG|#H_FLAG)))) 
     *R\ICount = *R\ICount - 16 : EndIf
Case $A0 :  WrZ80(*R\DE\W,SafeRdZ80(*R\HL\W))  : *R\DE\W + 1 : *R\HL\W + 1
   *R\BC\W - 1 
   *R\AF\B\l=(*R\AF\B\l&~(#N_FLAG|#H_FLAG|#P_FLAG))|((Bool(*R\BC\W) * (#P_FLAG))) 
Case $B0 :  WrZ80(*R\DE\W,SafeRdZ80(*R\HL\W))  : *R\DE\W + 1 : *R\HL\W + 1
   *R\BC\W - 1 : If *R\BC\W : *R\AF\B\l=(*R\AF\B\l&~(#H_FLAG|#P_FLAG))|#N_FLAG 
     *R\ICount = *R\ICount - 21 
     *R\PC\W - 2 : Else : *R\AF\B\l = *R\AF\B\l & ~(#N_FLAG|#H_FLAG|#P_FLAG) 
     *R\ICount = *R\ICount - 16 : EndIf
Case $A8 :  WrZ80(*R\DE\W,SafeRdZ80(*R\HL\W))  : *R\DE\W - 1 : *R\HL\W - 1
   *R\BC\W - 1 
   *R\AF\B\l=(*R\AF\B\l&~(#N_FLAG|#H_FLAG|#P_FLAG))|((Bool(*R\BC\W) * (#P_FLAG))) 
Case $B8 :  WrZ80(*R\DE\W,SafeRdZ80(*R\HL\W))  : *R\DE\W - 1 : *R\HL\W - 1
   *R\AF\B\l = *R\AF\B\l & ~(#N_FLAG|#H_FLAG|#P_FLAG) 
   *R\BC\W - 1 : If *R\BC\W : *R\AF\B\l=(*R\AF\B\l&~(#H_FLAG|#P_FLAG))|#N_FLAG 
     *R\ICount = *R\ICount - 21 
     *R\PC\W - 2 : Else : *R\AF\B\l = *R\AF\B\l & ~(#N_FLAG|#H_FLAG|#P_FLAG) 
     *R\ICount = *R\ICount - 16 : EndIf
Case $A1 :  I=SafeRdZ80(*R\HL\W)  : *R\HL\W + 1
   J\B\l=*R\AF\B\h-I 
   *R\BC\W - 1 
   *R\AF\B\l =     #N_FLAG|(*R\AF\B\l&#C_FLAG)|ZSTable(J\B\l)|     ((*R\AF\B\h!I!J\B\l)&#H_FLAG)|((Bool(*R\BC\W) * (#P_FLAG))) 
Case $B1 :  I=SafeRdZ80(*R\HL\W)  : *R\HL\W + 1
   J\B\l=*R\AF\B\h-I 
   *R\BC\W - 1 : If *R\BC\W And J\B\l : *R\ICount = *R\ICount - 21 : *R\PC\W - 2 : Else : *R\ICount = *R\ICount - 16 : EndIf
   *R\AF\B\l =     #N_FLAG|(*R\AF\B\l&#C_FLAG)|ZSTable(J\B\l)|     ((*R\AF\B\h!I!J\B\l)&#H_FLAG)|((Bool(*R\BC\W) * (#P_FLAG))) 
Case $A9 :  I=SafeRdZ80(*R\HL\W)  : *R\HL\W - 1
   J\B\l=*R\AF\B\h-I 
   *R\BC\W - 1 
   *R\AF\B\l =     #N_FLAG|(*R\AF\B\l&#C_FLAG)|ZSTable(J\B\l)|     ((*R\AF\B\h!I!J\B\l)&#H_FLAG)|((Bool(*R\BC\W) * (#P_FLAG))) 
Case $B9 :  I=SafeRdZ80(*R\HL\W)  : *R\HL\W - 1
   J\B\l=*R\AF\B\h-I 
   *R\BC\W - 1 : If *R\BC\W And J\B\l : *R\ICount = *R\ICount - 21 : *R\PC\W - 2 : Else : *R\ICount = *R\ICount - 16 : EndIf
   *R\AF\B\l =     #N_FLAG|(*R\AF\B\l&#C_FLAG)|ZSTable(J\B\l)|     ((*R\AF\B\h!I!J\B\l)&#H_FLAG)|((Bool(*R\BC\W) * (#P_FLAG))) 
