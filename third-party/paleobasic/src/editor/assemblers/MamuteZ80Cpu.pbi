;
; ------------------------------------------------------------
;  Nucleo de execucao Z80 (Fase 1 do debugger visual, ver docs/SPEC.md modulo
;  32) - portado de forma independente a partir do conhecimento publico da
;  arquitetura Z80 (tabela de opcodes, flags documentadas e as principais
;  indocumentadas: F3/F5 copiados do resultado, IXH/IXL/IYH/IYL, DDCB/FDCB
;  tambem copiando pro registrador) - NAO e derivado do codigo-fonte do
;  fMSX/bafmsx (mesma politica ja registrada no SPEC.md pro estudo do modulo
;  32: fatos de engenharia, nao copia de codigo).
;
;  Opera direto sobre os campos Reg*/IFF1/IFF2/IM/Halted/Break* de
;  MamuteGui_State (MamuteAssemblerGui.pbi) e sobre a memoria simulada de
;  MamuteSupport.pbi (Mamute_ReadByte/WriteByte, que ja resolvem slot/pagina
;  via MamutePageMap). Sem VDP/PSG/FDC/BIOS - IN sempre le $FF, OUT so
;  descarta (Fase 1 e Z80-only, ver modulo 32 do SPEC).
;
;  Simplificacoes conscientes desta primeira leva (documentadas aqui pra nao
;  serem confundidas com bug depois):
;   - F3/F5 de BIT n,(HL)/(IX+d)/(IY+d) usam o byte lido (nao o registrador
;     interno WZ/MEMPTR do hardware real - efeito raramente observavel em
;     codigo real).
;   - Combinacoes DD+ED ou FD+ED (nao documentadas, sem uso pratico conhecido)
;     tratam o DD/FD anterior como desperdicado - mesmo comportamento real do
;     Z80 pra prefixos encadeados nao reconhecidos.
;   - INI/IND/OUTI/OUTD/OTIR/OTDR/INIR/INDR: flags C/H/PV seguem uma
;     aproximacao comum (nao a formula exata, historicamente pouco
;     documentada mesmo nas referencias oficiais) - N e Z (via B) estao
;     corretos.
;   - Cronometragem em T-states nao e simulada (debugger passo-a-passo nao
;     depende disso).
;   - IMPORTANTE (licao aprendida na sessao do bafmsx/): em PureBasic,
;     "Var | Valor" ou "Var & Valor" como instrucao solta NAO e um |=/&=
;     implicito - o resultado e descartado silenciosamente. Neste arquivo
;     toda mutacao de flag usa "Var = Var | Valor" explicito.
; ------------------------------------------------------------
;

;- ------------------------------------------------------------
;- Bits de flag (registrador F)
;- ------------------------------------------------------------
#Mz80_FC  = $01
#Mz80_FN  = $02
#Mz80_FPV = $04
#Mz80_FX  = $08 ; F3 (indocumentado)
#Mz80_FH  = $10
#Mz80_FY  = $20 ; F5 (indocumentado)
#Mz80_FZ  = $40
#Mz80_FS  = $80

#Mz80_Idx_None = 0
#Mz80_Idx_IX   = 1
#Mz80_Idx_IY   = 2

#Mz80_MaxStepBudget = 2000000

;- ------------------------------------------------------------
;- Acesso a pares de registrador (struct MamuteGui_State so tem bytes
;- separados, ver MamuteAssemblerGui.pbi - sem StructureUnion pra nao mexer
;- no layout usado pelo comando X ja existente)
;- ------------------------------------------------------------

Procedure.u Mz80_GetBC(*S.MamuteGui_State) : ProcedureReturn (*S\RegB << 8) | *S\RegC : EndProcedure
Procedure   Mz80_SetBC(*S.MamuteGui_State, V.u) : *S\RegB = (V >> 8) & $FF : *S\RegC = V & $FF : EndProcedure
Procedure.u Mz80_GetDE(*S.MamuteGui_State) : ProcedureReturn (*S\RegD << 8) | *S\RegE : EndProcedure
Procedure   Mz80_SetDE(*S.MamuteGui_State, V.u) : *S\RegD = (V >> 8) & $FF : *S\RegE = V & $FF : EndProcedure
Procedure.u Mz80_GetHL(*S.MamuteGui_State) : ProcedureReturn (*S\RegH << 8) | *S\RegL : EndProcedure
Procedure   Mz80_SetHL(*S.MamuteGui_State, V.u) : *S\RegH = (V >> 8) & $FF : *S\RegL = V & $FF : EndProcedure
Procedure.u Mz80_GetAF(*S.MamuteGui_State) : ProcedureReturn (*S\RegA << 8) | *S\RegF : EndProcedure
Procedure   Mz80_SetAF(*S.MamuteGui_State, V.u) : *S\RegA = (V >> 8) & $FF : *S\RegF = V & $FF : EndProcedure

Procedure.a Mz80_GetIXH(*S.MamuteGui_State) : ProcedureReturn (*S\RegIX >> 8) & $FF : EndProcedure
Procedure   Mz80_SetIXH(*S.MamuteGui_State, V.a) : *S\RegIX = (*S\RegIX & $00FF) | (V << 8) : EndProcedure
Procedure.a Mz80_GetIXL(*S.MamuteGui_State) : ProcedureReturn *S\RegIX & $FF : EndProcedure
Procedure   Mz80_SetIXL(*S.MamuteGui_State, V.a) : *S\RegIX = (*S\RegIX & $FF00) | V : EndProcedure
Procedure.a Mz80_GetIYH(*S.MamuteGui_State) : ProcedureReturn (*S\RegIY >> 8) & $FF : EndProcedure
Procedure   Mz80_SetIYH(*S.MamuteGui_State, V.a) : *S\RegIY = (*S\RegIY & $00FF) | (V << 8) : EndProcedure
Procedure.a Mz80_GetIYL(*S.MamuteGui_State) : ProcedureReturn *S\RegIY & $FF : EndProcedure
Procedure   Mz80_SetIYL(*S.MamuteGui_State, V.a) : *S\RegIY = (*S\RegIY & $FF00) | V : EndProcedure

;- ------------------------------------------------------------
;- Busca de bytes/palavras a partir de PC, pilha, deslocamento com sinal
;- ------------------------------------------------------------

Procedure.a Mz80_Fetch8(*S.MamuteGui_State)
  Protected V.a = Mamute_ReadByte(*S\RegPC)
  *S\RegPC = (*S\RegPC + 1) & $FFFF
  ProcedureReturn V
EndProcedure

Procedure.u Mz80_Fetch16(*S.MamuteGui_State)
  Protected Lo.a = Mz80_Fetch8(*S)
  Protected Hi.a = Mz80_Fetch8(*S)
  ProcedureReturn (Hi << 8) | Lo
EndProcedure

Procedure.i Mz80_SignedByte(V.a)
  If V >= 128
    ProcedureReturn V - 256
  EndIf
  ProcedureReturn V
EndProcedure

Procedure Mz80_Push16(*S.MamuteGui_State, V.u)
  *S\RegSP = (*S\RegSP - 1) & $FFFF
  Mamute_WriteByte(*S\RegSP, (V >> 8) & $FF)
  *S\RegSP = (*S\RegSP - 1) & $FFFF
  Mamute_WriteByte(*S\RegSP, V & $FF)
EndProcedure

Procedure.u Mz80_Pop16(*S.MamuteGui_State)
  Protected Lo.a = Mamute_ReadByte(*S\RegSP)
  *S\RegSP = (*S\RegSP + 1) & $FFFF
  Protected Hi.a = Mamute_ReadByte(*S\RegSP)
  *S\RegSP = (*S\RegSP + 1) & $FFFF
  ProcedureReturn (Hi << 8) | Lo
EndProcedure

Procedure.b Mz80_Parity(V.a)
  Protected N.a = V
  Protected Bits.i = 0, i.i
  For i = 0 To 7
    If N & 1 : Bits + 1 : EndIf
    N = N >> 1
  Next
  ProcedureReturn Bool((Bits & 1) = 0)
EndProcedure

;- ------------------------------------------------------------
;- Grade generica de registrador de 8 bits (B,C,D,E,H,L,(HL)/(IX+d)/(IY+d),A)
;- - UsesMemSlot indica que a instrucao TODA referencia a posicao 6 (memoria);
;- nesse caso H/L continuam sendo H/L reais mesmo sob DD/FD (regra real do
;- Z80: so quando NENHUM operando da instrucao usa (HL) que H/L viram IXH/IXL/
;- IYH/IYL).
;- ------------------------------------------------------------

Procedure.a Mz80_GetR8(*S.MamuteGui_State, Idx.a, IndexMode.a, UsesMemSlot.b, *Disp.Integer)
  Select Idx
    Case 0 : ProcedureReturn *S\RegB
    Case 1 : ProcedureReturn *S\RegC
    Case 2 : ProcedureReturn *S\RegD
    Case 3 : ProcedureReturn *S\RegE
    Case 4
      If IndexMode = 1 And Not UsesMemSlot
        ProcedureReturn Mz80_GetIXH(*S)
      ElseIf IndexMode = 2 And Not UsesMemSlot
        ProcedureReturn Mz80_GetIYH(*S)
      Else
        ProcedureReturn *S\RegH
      EndIf
    Case 5
      If IndexMode = 1 And Not UsesMemSlot
        ProcedureReturn Mz80_GetIXL(*S)
      ElseIf IndexMode = 2 And Not UsesMemSlot
        ProcedureReturn Mz80_GetIYL(*S)
      Else
        ProcedureReturn *S\RegL
      EndIf
    Case 6
      If IndexMode = 0
        ProcedureReturn Mamute_ReadByte(Mz80_GetHL(*S))
      Else
        Protected BaseG.u = *S\RegIX
        If IndexMode = 2 : BaseG = *S\RegIY : EndIf
        ProcedureReturn Mamute_ReadByte((BaseG + *Disp\i) & $FFFF)
      EndIf
    Case 7 : ProcedureReturn *S\RegA
  EndSelect
  ProcedureReturn 0
EndProcedure

Procedure Mz80_SetR8(*S.MamuteGui_State, Idx.a, IndexMode.a, Value.a, UsesMemSlot.b, *Disp.Integer)
  Select Idx
    Case 0 : *S\RegB = Value
    Case 1 : *S\RegC = Value
    Case 2 : *S\RegD = Value
    Case 3 : *S\RegE = Value
    Case 4
      If IndexMode = 1 And Not UsesMemSlot
        Mz80_SetIXH(*S, Value)
      ElseIf IndexMode = 2 And Not UsesMemSlot
        Mz80_SetIYH(*S, Value)
      Else
        *S\RegH = Value
      EndIf
    Case 5
      If IndexMode = 1 And Not UsesMemSlot
        Mz80_SetIXL(*S, Value)
      ElseIf IndexMode = 2 And Not UsesMemSlot
        Mz80_SetIYL(*S, Value)
      Else
        *S\RegL = Value
      EndIf
    Case 6
      If IndexMode = 0
        Mamute_WriteByte(Mz80_GetHL(*S), Value)
      Else
        Protected BaseS.u = *S\RegIX
        If IndexMode = 2 : BaseS = *S\RegIY : EndIf
        Mamute_WriteByte((BaseS + *Disp\i) & $FFFF, Value)
      EndIf
    Case 7 : *S\RegA = Value
  EndSelect
EndProcedure

;- ------------------------------------------------------------
;- Grade generica de par de 16 bits (BC,DE,HL/IX/IY,SP)
;- ------------------------------------------------------------

Procedure.u Mz80_Get16(*S.MamuteGui_State, PairIdx.a, IndexMode.a)
  Select PairIdx
    Case 0 : ProcedureReturn Mz80_GetBC(*S)
    Case 1 : ProcedureReturn Mz80_GetDE(*S)
    Case 2
      Select IndexMode
        Case 1 : ProcedureReturn *S\RegIX
        Case 2 : ProcedureReturn *S\RegIY
        Default : ProcedureReturn Mz80_GetHL(*S)
      EndSelect
    Case 3 : ProcedureReturn *S\RegSP
  EndSelect
  ProcedureReturn 0
EndProcedure

Procedure Mz80_Set16(*S.MamuteGui_State, PairIdx.a, IndexMode.a, V.u)
  Select PairIdx
    Case 0 : Mz80_SetBC(*S, V)
    Case 1 : Mz80_SetDE(*S, V)
    Case 2
      Select IndexMode
        Case 1 : *S\RegIX = V
        Case 2 : *S\RegIY = V
        Default : Mz80_SetHL(*S, V)
      EndSelect
    Case 3 : *S\RegSP = V
  EndSelect
EndProcedure

Procedure.b Mz80_TestCond(*S.MamuteGui_State, CondIdx.a)
  Protected F.a = *S\RegF
  Select CondIdx
    Case 0 : ProcedureReturn Bool((F & #Mz80_FZ) = 0)   ; NZ
    Case 1 : ProcedureReturn Bool((F & #Mz80_FZ) <> 0)  ; Z
    Case 2 : ProcedureReturn Bool((F & #Mz80_FC) = 0)   ; NC
    Case 3 : ProcedureReturn Bool((F & #Mz80_FC) <> 0)  ; C
    Case 4 : ProcedureReturn Bool((F & #Mz80_FPV) = 0)  ; PO
    Case 5 : ProcedureReturn Bool((F & #Mz80_FPV) <> 0) ; PE
    Case 6 : ProcedureReturn Bool((F & #Mz80_FS) = 0)   ; P
    Case 7 : ProcedureReturn Bool((F & #Mz80_FS) <> 0)  ; M
  EndSelect
  ProcedureReturn #False
EndProcedure

;- ------------------------------------------------------------
;- ALU de 8 bits (usada pela grade $80-$BF, imediatos $C6.., NEG do ED, etc.)
;- ------------------------------------------------------------

Procedure.a Mz80_Add8(*S.MamuteGui_State, A.a, B.a, WithCarry.b)
  Protected CarryIn.a = 0
  If WithCarry And (*S\RegF & #Mz80_FC) : CarryIn = 1 : EndIf
  Protected Result.i = A + B + CarryIn
  Protected R8.a = Result & $FF
  Protected F.a = 0
  If R8 = 0 : F = F | #Mz80_FZ : EndIf
  F = F | (R8 & #Mz80_FS)
  F = F | (R8 & (#Mz80_FY | #Mz80_FX))
  If (((A & $0F) + (B & $0F) + CarryIn) > $0F) : F = F | #Mz80_FH : EndIf
  If Result > $FF : F = F | #Mz80_FC : EndIf
  If (((A ! B) & $80) = 0) And (((A ! R8) & $80) <> 0) : F = F | #Mz80_FPV : EndIf
  *S\RegF = F
  ProcedureReturn R8
EndProcedure

Procedure.a Mz80_Sub8(*S.MamuteGui_State, A.a, B.a, WithCarry.b)
  Protected CarryIn.a = 0
  If WithCarry And (*S\RegF & #Mz80_FC) : CarryIn = 1 : EndIf
  Protected Result.i = A - B - CarryIn
  Protected R8.a = Result & $FF
  Protected F.a = #Mz80_FN
  If R8 = 0 : F = F | #Mz80_FZ : EndIf
  F = F | (R8 & #Mz80_FS)
  F = F | (R8 & (#Mz80_FY | #Mz80_FX))
  If (((A & $0F) - (B & $0F) - CarryIn) < 0) : F = F | #Mz80_FH : EndIf
  If Result < 0 : F = F | #Mz80_FC : EndIf
  If (((A ! B) & $80) <> 0) And (((A ! R8) & $80) <> 0) : F = F | #Mz80_FPV : EndIf
  *S\RegF = F
  ProcedureReturn R8
EndProcedure

Procedure.a Mz80_And8(*S.MamuteGui_State, A.a, B.a)
  Protected R8.a = A & B
  Protected F.a = #Mz80_FH
  If R8 = 0 : F = F | #Mz80_FZ : EndIf
  F = F | (R8 & #Mz80_FS)
  F = F | (R8 & (#Mz80_FY | #Mz80_FX))
  If Mz80_Parity(R8) : F = F | #Mz80_FPV : EndIf
  *S\RegF = F
  ProcedureReturn R8
EndProcedure

Procedure.a Mz80_Or8(*S.MamuteGui_State, A.a, B.a)
  Protected R8.a = A | B
  Protected F.a = 0
  If R8 = 0 : F = F | #Mz80_FZ : EndIf
  F = F | (R8 & #Mz80_FS)
  F = F | (R8 & (#Mz80_FY | #Mz80_FX))
  If Mz80_Parity(R8) : F = F | #Mz80_FPV : EndIf
  *S\RegF = F
  ProcedureReturn R8
EndProcedure

Procedure.a Mz80_Xor8(*S.MamuteGui_State, A.a, B.a)
  Protected R8.a = A ! B
  Protected F.a = 0
  If R8 = 0 : F = F | #Mz80_FZ : EndIf
  F = F | (R8 & #Mz80_FS)
  F = F | (R8 & (#Mz80_FY | #Mz80_FX))
  If Mz80_Parity(R8) : F = F | #Mz80_FPV : EndIf
  *S\RegF = F
  ProcedureReturn R8
EndProcedure

Procedure Mz80_DoAlu(*S.MamuteGui_State, AluOp.a, Operand.a)
  Select AluOp
    Case 0 : *S\RegA = Mz80_Add8(*S, *S\RegA, Operand, #False)
    Case 1 : *S\RegA = Mz80_Add8(*S, *S\RegA, Operand, #True)
    Case 2 : *S\RegA = Mz80_Sub8(*S, *S\RegA, Operand, #False)
    Case 3 : *S\RegA = Mz80_Sub8(*S, *S\RegA, Operand, #True)
    Case 4 : *S\RegA = Mz80_And8(*S, *S\RegA, Operand)
    Case 5 : *S\RegA = Mz80_Xor8(*S, *S\RegA, Operand)
    Case 6 : *S\RegA = Mz80_Or8(*S, *S\RegA, Operand)
    Case 7 : Mz80_Sub8(*S, *S\RegA, Operand, #False) ; CP - so flags
  EndSelect
EndProcedure

Procedure.a Mz80_Inc8(*S.MamuteGui_State, V.a)
  Protected R8.a = (V + 1) & $FF
  Protected F.a = *S\RegF & #Mz80_FC
  If R8 = 0 : F = F | #Mz80_FZ : EndIf
  F = F | (R8 & #Mz80_FS)
  F = F | (R8 & (#Mz80_FY | #Mz80_FX))
  If (V & $0F) = $0F : F = F | #Mz80_FH : EndIf
  If V = $7F : F = F | #Mz80_FPV : EndIf
  *S\RegF = F
  ProcedureReturn R8
EndProcedure

Procedure.a Mz80_Dec8(*S.MamuteGui_State, V.a)
  Protected R8.a = (V - 1) & $FF
  Protected F.a = (*S\RegF & #Mz80_FC) | #Mz80_FN
  If R8 = 0 : F = F | #Mz80_FZ : EndIf
  F = F | (R8 & #Mz80_FS)
  F = F | (R8 & (#Mz80_FY | #Mz80_FX))
  If (V & $0F) = 0 : F = F | #Mz80_FH : EndIf
  If V = $80 : F = F | #Mz80_FPV : EndIf
  *S\RegF = F
  ProcedureReturn R8
EndProcedure

;- ------------------------------------------------------------
;- Aritmetica de 16 bits
;- ------------------------------------------------------------

Procedure.u Mz80_Add16(*S.MamuteGui_State, A.u, B.u)
  Protected Result.l = A + B
  Protected R16.u = Result & $FFFF
  Protected F.a = *S\RegF & (#Mz80_FS | #Mz80_FZ | #Mz80_FPV)
  If (((A & $0FFF) + (B & $0FFF)) > $0FFF) : F = F | #Mz80_FH : EndIf
  F = F | ((R16 >> 8) & (#Mz80_FY | #Mz80_FX))
  If Result > $FFFF : F = F | #Mz80_FC : EndIf
  *S\RegF = F
  ProcedureReturn R16
EndProcedure

Procedure.u Mz80_Adc16(*S.MamuteGui_State, A.u, B.u)
  Protected CarryIn.l = 0
  If *S\RegF & #Mz80_FC : CarryIn = 1 : EndIf
  Protected Result.l = A + B + CarryIn
  Protected R16.u = Result & $FFFF
  Protected F.a = 0
  If R16 = 0 : F = F | #Mz80_FZ : EndIf
  F = F | ((R16 >> 8) & #Mz80_FS)
  F = F | ((R16 >> 8) & (#Mz80_FY | #Mz80_FX))
  If (((A & $0FFF) + (B & $0FFF) + CarryIn) > $0FFF) : F = F | #Mz80_FH : EndIf
  If Result > $FFFF : F = F | #Mz80_FC : EndIf
  If (((A ! B) & $8000) = 0) And (((A ! R16) & $8000) <> 0) : F = F | #Mz80_FPV : EndIf
  *S\RegF = F
  ProcedureReturn R16
EndProcedure

Procedure.u Mz80_Sbc16(*S.MamuteGui_State, A.u, B.u)
  Protected CarryIn.l = 0
  If *S\RegF & #Mz80_FC : CarryIn = 1 : EndIf
  Protected Result.l = A - B - CarryIn
  Protected R16.u = Result & $FFFF
  Protected F.a = #Mz80_FN
  If R16 = 0 : F = F | #Mz80_FZ : EndIf
  F = F | ((R16 >> 8) & #Mz80_FS)
  F = F | ((R16 >> 8) & (#Mz80_FY | #Mz80_FX))
  If (((A & $0FFF) - (B & $0FFF) - CarryIn) < 0) : F = F | #Mz80_FH : EndIf
  If Result < 0 : F = F | #Mz80_FC : EndIf
  If (((A ! B) & $8000) <> 0) And (((A ! R16) & $8000) <> 0) : F = F | #Mz80_FPV : EndIf
  *S\RegF = F
  ProcedureReturn R16
EndProcedure

;- ------------------------------------------------------------
;- Rotacao/deslocamento de 8 bits (grupo 0 do CB) e BIT/RES/SET
;- ------------------------------------------------------------

Procedure.a Mz80_RotShift8(*S.MamuteGui_State, SubOp.a, V.a)
  Protected R8.a, CarryOut.b, OldC.a
  Select SubOp
    Case 0 ; RLC
      CarryOut = Bool((V & $80) <> 0)
      R8 = ((V << 1) | (V >> 7)) & $FF
    Case 1 ; RRC
      CarryOut = Bool((V & $01) <> 0)
      R8 = ((V >> 1) | (V << 7)) & $FF
    Case 2 ; RL
      CarryOut = Bool((V & $80) <> 0)
      OldC = 0
      If *S\RegF & #Mz80_FC : OldC = 1 : EndIf
      R8 = ((V << 1) | OldC) & $FF
    Case 3 ; RR
      CarryOut = Bool((V & $01) <> 0)
      OldC = 0
      If *S\RegF & #Mz80_FC : OldC = $80 : EndIf
      R8 = ((V >> 1) | OldC) & $FF
    Case 4 ; SLA
      CarryOut = Bool((V & $80) <> 0)
      R8 = (V << 1) & $FF
    Case 5 ; SRA
      CarryOut = Bool((V & $01) <> 0)
      R8 = ((V >> 1) | (V & $80)) & $FF
    Case 6 ; SLL (indocumentado)
      CarryOut = Bool((V & $80) <> 0)
      R8 = ((V << 1) | $01) & $FF
    Case 7 ; SRL
      CarryOut = Bool((V & $01) <> 0)
      R8 = (V >> 1) & $FF
  EndSelect

  Protected F.a = 0
  If CarryOut : F = F | #Mz80_FC : EndIf
  If R8 = 0 : F = F | #Mz80_FZ : EndIf
  F = F | (R8 & #Mz80_FS)
  F = F | (R8 & (#Mz80_FY | #Mz80_FX))
  If Mz80_Parity(R8) : F = F | #Mz80_FPV : EndIf
  *S\RegF = F
  ProcedureReturn R8
EndProcedure

Procedure Mz80_Bit8(*S.MamuteGui_State, BitIdx.a, V.a)
  Protected TestVal.a = V & (1 << BitIdx)
  Protected F.a = (*S\RegF & #Mz80_FC) | #Mz80_FH
  If TestVal = 0
    F = F | #Mz80_FZ | #Mz80_FPV
  EndIf
  If BitIdx = 7 And TestVal <> 0
    F = F | #Mz80_FS
  EndIf
  F = F | (V & (#Mz80_FY | #Mz80_FX)) ; simplificacao documentada no topo do arquivo
  *S\RegF = F
EndProcedure

Procedure.a Mz80_Res8(BitIdx.a, V.a)
  ProcedureReturn V & (~(1 << BitIdx))
EndProcedure

Procedure.a Mz80_Set8(BitIdx.a, V.a)
  ProcedureReturn V | (1 << BitIdx)
EndProcedure

;- ------------------------------------------------------------
;- Instrucoes de acumulador dedicadas (RLCA/RRCA/RLA/RRA/DAA/CPL/SCF/CCF)
;- ------------------------------------------------------------

Procedure Mz80_RLCA(*S.MamuteGui_State)
  Protected A.a = *S\RegA
  Protected CarryOut.b = Bool((A & $80) <> 0)
  Protected R8.a = ((A << 1) | (A >> 7)) & $FF
  Protected F.a = *S\RegF & (#Mz80_FS | #Mz80_FZ | #Mz80_FPV)
  If CarryOut : F = F | #Mz80_FC : EndIf
  F = F | (R8 & (#Mz80_FY | #Mz80_FX))
  *S\RegA = R8
  *S\RegF = F
EndProcedure

Procedure Mz80_RRCA(*S.MamuteGui_State)
  Protected A.a = *S\RegA
  Protected CarryOut.b = Bool((A & $01) <> 0)
  Protected R8.a = ((A >> 1) | (A << 7)) & $FF
  Protected F.a = *S\RegF & (#Mz80_FS | #Mz80_FZ | #Mz80_FPV)
  If CarryOut : F = F | #Mz80_FC : EndIf
  F = F | (R8 & (#Mz80_FY | #Mz80_FX))
  *S\RegA = R8
  *S\RegF = F
EndProcedure

Procedure Mz80_RLA(*S.MamuteGui_State)
  Protected A.a = *S\RegA
  Protected OldC.a = 0
  If *S\RegF & #Mz80_FC : OldC = 1 : EndIf
  Protected CarryOut.b = Bool((A & $80) <> 0)
  Protected R8.a = ((A << 1) | OldC) & $FF
  Protected F.a = *S\RegF & (#Mz80_FS | #Mz80_FZ | #Mz80_FPV)
  If CarryOut : F = F | #Mz80_FC : EndIf
  F = F | (R8 & (#Mz80_FY | #Mz80_FX))
  *S\RegA = R8
  *S\RegF = F
EndProcedure

Procedure Mz80_RRA(*S.MamuteGui_State)
  Protected A.a = *S\RegA
  Protected OldC.a = 0
  If *S\RegF & #Mz80_FC : OldC = $80 : EndIf
  Protected CarryOut.b = Bool((A & $01) <> 0)
  Protected R8.a = ((A >> 1) | OldC) & $FF
  Protected F.a = *S\RegF & (#Mz80_FS | #Mz80_FZ | #Mz80_FPV)
  If CarryOut : F = F | #Mz80_FC : EndIf
  F = F | (R8 & (#Mz80_FY | #Mz80_FX))
  *S\RegA = R8
  *S\RegF = F
EndProcedure

Procedure Mz80_DAA(*S.MamuteGui_State)
  Protected A.a = *S\RegA
  Protected F.a = *S\RegF
  Protected Correction.a = 0
  Protected CarryOut.b = Bool(F & #Mz80_FC)
  Protected HalfCarry.b = Bool(F & #Mz80_FH)
  Protected Negative.b = Bool(F & #Mz80_FN)

  If HalfCarry Or ((A & $0F) > 9)
    Correction = Correction | $06
  EndIf
  If CarryOut Or (A > $99)
    Correction = Correction | $60
    CarryOut = #True
  EndIf

  Protected NewHalfCarry.b
  If Negative
    NewHalfCarry = Bool(HalfCarry And ((A & $0F) < 6))
    A = (A - Correction) & $FF
  Else
    NewHalfCarry = Bool((A & $0F) > 9)
    A = (A + Correction) & $FF
  EndIf

  Protected NewF.a = 0
  If Negative : NewF = NewF | #Mz80_FN : EndIf
  If NewHalfCarry : NewF = NewF | #Mz80_FH : EndIf
  If CarryOut : NewF = NewF | #Mz80_FC : EndIf
  If Mz80_Parity(A) : NewF = NewF | #Mz80_FPV : EndIf
  If A = 0 : NewF = NewF | #Mz80_FZ : EndIf
  NewF = NewF | (A & #Mz80_FS)
  NewF = NewF | (A & (#Mz80_FY | #Mz80_FX))

  *S\RegA = A
  *S\RegF = NewF
EndProcedure

Procedure Mz80_CPL(*S.MamuteGui_State)
  *S\RegA = (~*S\RegA) & $FF
  Protected F.a = *S\RegF & (#Mz80_FS | #Mz80_FZ | #Mz80_FC | #Mz80_FPV)
  F = F | #Mz80_FH | #Mz80_FN
  F = F | (*S\RegA & (#Mz80_FY | #Mz80_FX))
  *S\RegF = F
EndProcedure

Procedure Mz80_SCF(*S.MamuteGui_State)
  Protected F.a = *S\RegF & (#Mz80_FS | #Mz80_FZ | #Mz80_FPV)
  F = F | #Mz80_FC
  F = F | (*S\RegA & (#Mz80_FY | #Mz80_FX))
  *S\RegF = F
EndProcedure

Procedure Mz80_CCF(*S.MamuteGui_State)
  Protected OldC.b = Bool(*S\RegF & #Mz80_FC)
  Protected F.a = *S\RegF & (#Mz80_FS | #Mz80_FZ | #Mz80_FPV)
  If OldC
    F = F | #Mz80_FH
  Else
    F = F | #Mz80_FC
  EndIf
  F = F | (*S\RegA & (#Mz80_FY | #Mz80_FX))
  *S\RegF = F
EndProcedure

;- ------------------------------------------------------------
;- Instrucoes de bloco do ED (LDI/LDD/LDIR/LDDR/CPI/CPD/CPIR/CPDR/
;- INI/IND/INIR/INDR/OUTI/OUTD/OTIR/OTDR)
;- ------------------------------------------------------------

Procedure Mz80_LDI(*S.MamuteGui_State)
  Protected V.a = Mamute_ReadByte(Mz80_GetHL(*S))
  Mamute_WriteByte(Mz80_GetDE(*S), V)
  Mz80_SetHL(*S, (Mz80_GetHL(*S) + 1) & $FFFF)
  Mz80_SetDE(*S, (Mz80_GetDE(*S) + 1) & $FFFF)
  Mz80_SetBC(*S, (Mz80_GetBC(*S) - 1) & $FFFF)
  Protected F.a = *S\RegF & (#Mz80_FS | #Mz80_FZ | #Mz80_FC)
  Protected N.a = (V + *S\RegA) & $FF
  F = F | (N & #Mz80_FX)
  F = F | ((N & $02) << 4)
  If Mz80_GetBC(*S) <> 0 : F = F | #Mz80_FPV : EndIf
  *S\RegF = F
EndProcedure

Procedure Mz80_LDD(*S.MamuteGui_State)
  Protected V.a = Mamute_ReadByte(Mz80_GetHL(*S))
  Mamute_WriteByte(Mz80_GetDE(*S), V)
  Mz80_SetHL(*S, (Mz80_GetHL(*S) - 1) & $FFFF)
  Mz80_SetDE(*S, (Mz80_GetDE(*S) - 1) & $FFFF)
  Mz80_SetBC(*S, (Mz80_GetBC(*S) - 1) & $FFFF)
  Protected F.a = *S\RegF & (#Mz80_FS | #Mz80_FZ | #Mz80_FC)
  Protected N.a = (V + *S\RegA) & $FF
  F = F | (N & #Mz80_FX)
  F = F | ((N & $02) << 4)
  If Mz80_GetBC(*S) <> 0 : F = F | #Mz80_FPV : EndIf
  *S\RegF = F
EndProcedure

Procedure Mz80_CPI(*S.MamuteGui_State)
  Protected V.a = Mamute_ReadByte(Mz80_GetHL(*S))
  Protected Result.a = (*S\RegA - V) & $FF
  Protected HalfC.b = Bool((*S\RegA & $0F) < (V & $0F))
  Mz80_SetHL(*S, (Mz80_GetHL(*S) + 1) & $FFFF)
  Mz80_SetBC(*S, (Mz80_GetBC(*S) - 1) & $FFFF)
  Protected F.a = (*S\RegF & #Mz80_FC) | #Mz80_FN
  If Result = 0 : F = F | #Mz80_FZ : EndIf
  F = F | (Result & #Mz80_FS)
  If HalfC : F = F | #Mz80_FH : EndIf
  Protected N.a = Result
  If HalfC : N = (N - 1) & $FF : EndIf
  F = F | (N & #Mz80_FX)
  F = F | ((N & $02) << 4)
  If Mz80_GetBC(*S) <> 0 : F = F | #Mz80_FPV : EndIf
  *S\RegF = F
EndProcedure

Procedure Mz80_CPD(*S.MamuteGui_State)
  Protected V.a = Mamute_ReadByte(Mz80_GetHL(*S))
  Protected Result.a = (*S\RegA - V) & $FF
  Protected HalfC.b = Bool((*S\RegA & $0F) < (V & $0F))
  Mz80_SetHL(*S, (Mz80_GetHL(*S) - 1) & $FFFF)
  Mz80_SetBC(*S, (Mz80_GetBC(*S) - 1) & $FFFF)
  Protected F.a = (*S\RegF & #Mz80_FC) | #Mz80_FN
  If Result = 0 : F = F | #Mz80_FZ : EndIf
  F = F | (Result & #Mz80_FS)
  If HalfC : F = F | #Mz80_FH : EndIf
  Protected N.a = Result
  If HalfC : N = (N - 1) & $FF : EndIf
  F = F | (N & #Mz80_FX)
  F = F | ((N & $02) << 4)
  If Mz80_GetBC(*S) <> 0 : F = F | #Mz80_FPV : EndIf
  *S\RegF = F
EndProcedure

Procedure Mz80_INI(*S.MamuteGui_State)
  Protected V.a = Mamute_IOPort_GetSaida(*S\RegC) ; porta C - "Saida" do Painel de Portas I/O
  Mamute_WriteByte(Mz80_GetHL(*S), V)
  Mz80_SetHL(*S, (Mz80_GetHL(*S) + 1) & $FFFF)
  *S\RegB = (*S\RegB - 1) & $FF
  Protected F.a = #Mz80_FN
  If *S\RegB = 0 : F = F | #Mz80_FZ : EndIf
  F = F | (*S\RegB & #Mz80_FS)
  F = F | (*S\RegB & (#Mz80_FY | #Mz80_FX))
  *S\RegF = F
EndProcedure

Procedure Mz80_IND(*S.MamuteGui_State)
  Protected V.a = Mamute_IOPort_GetSaida(*S\RegC) ; porta C - "Saida" do Painel de Portas I/O
  Mamute_WriteByte(Mz80_GetHL(*S), V)
  Mz80_SetHL(*S, (Mz80_GetHL(*S) - 1) & $FFFF)
  *S\RegB = (*S\RegB - 1) & $FF
  Protected F.a = #Mz80_FN
  If *S\RegB = 0 : F = F | #Mz80_FZ : EndIf
  F = F | (*S\RegB & #Mz80_FS)
  F = F | (*S\RegB & (#Mz80_FY | #Mz80_FX))
  *S\RegF = F
EndProcedure

Procedure Mz80_OUTI(*S.MamuteGui_State)
  Mamute_IOPort_SetEntrada(*S\RegC, Mamute_ReadByte(Mz80_GetHL(*S))) ; porta C - "Entrada" do Painel de Portas I/O
  Mz80_SetHL(*S, (Mz80_GetHL(*S) + 1) & $FFFF)
  *S\RegB = (*S\RegB - 1) & $FF
  Protected F.a = #Mz80_FN
  If *S\RegB = 0 : F = F | #Mz80_FZ : EndIf
  F = F | (*S\RegB & #Mz80_FS)
  F = F | (*S\RegB & (#Mz80_FY | #Mz80_FX))
  *S\RegF = F
EndProcedure

Procedure Mz80_OUTD(*S.MamuteGui_State)
  Mamute_IOPort_SetEntrada(*S\RegC, Mamute_ReadByte(Mz80_GetHL(*S))) ; porta C - "Entrada" do Painel de Portas I/O
  Mz80_SetHL(*S, (Mz80_GetHL(*S) - 1) & $FFFF)
  *S\RegB = (*S\RegB - 1) & $FF
  Protected F.a = #Mz80_FN
  If *S\RegB = 0 : F = F | #Mz80_FZ : EndIf
  F = F | (*S\RegB & #Mz80_FS)
  F = F | (*S\RegB & (#Mz80_FY | #Mz80_FX))
  *S\RegF = F
EndProcedure

;- ------------------------------------------------------------
;- Dispatcher CB (grupo 0=rot/shift, 1=BIT, 2=RES, 3=SET)
;- ------------------------------------------------------------

Procedure Mz80_ExecuteCB(*S.MamuteGui_State)
  Protected Opcode.a = Mz80_Fetch8(*S)
  Protected Group.a = (Opcode >> 6) & 3
  Protected SubOp.a = (Opcode >> 3) & 7
  Protected RIdx.a = Opcode & 7
  Protected UsesMem.b = Bool(RIdx = 6)
  Protected Disp.i = 0
  Protected V.a = Mz80_GetR8(*S, RIdx, 0, UsesMem, @Disp)

  Select Group
    Case 0
      Mz80_SetR8(*S, RIdx, 0, Mz80_RotShift8(*S, SubOp, V), UsesMem, @Disp)
    Case 1
      Mz80_Bit8(*S, SubOp, V)
    Case 2
      Mz80_SetR8(*S, RIdx, 0, Mz80_Res8(SubOp, V), UsesMem, @Disp)
    Case 3
      Mz80_SetR8(*S, RIdx, 0, Mz80_Set8(SubOp, V), UsesMem, @Disp)
  EndSelect
EndProcedure

; DD CB <disp> <op> / FD CB <disp> <op> - deslocamento ja lido pelo chamador
; (Mz80_ExecuteOne, ordem real do Z80: disp vem logo apos CB, antes do byte de
; opcode). Sempre opera em (IX+d)/(IY+d); RIdx (bits 2-0 do opcode) so decide
; se o resultado TAMBEM e copiado pra um registrador de 8 bits (comportamento
; indocumentado real do Z80) - RIdx=6 significa "so memoria", sem copia.
Procedure Mz80_ExecuteCBIndexed(*S.MamuteGui_State, IndexMode.a, Disp.i, Opcode.a)
  Protected Group.a = (Opcode >> 6) & 3
  Protected SubOp.a = (Opcode >> 3) & 7
  Protected RIdx.a = Opcode & 7
  Protected BaseCB.u = *S\RegIX
  If IndexMode = 2 : BaseCB = *S\RegIY : EndIf
  Protected Addr.u = (BaseCB + Disp) & $FFFF
  Protected V.a = Mamute_ReadByte(Addr)
  Protected Result.a

  Select Group
    Case 0
      Result = Mz80_RotShift8(*S, SubOp, V)
      Mamute_WriteByte(Addr, Result)
      If RIdx <> 6 : Mz80_SetR8(*S, RIdx, 0, Result, #False, 0) : EndIf
    Case 1
      Mz80_Bit8(*S, SubOp, V)
    Case 2
      Result = Mz80_Res8(SubOp, V)
      Mamute_WriteByte(Addr, Result)
      If RIdx <> 6 : Mz80_SetR8(*S, RIdx, 0, Result, #False, 0) : EndIf
    Case 3
      Result = Mz80_Set8(SubOp, V)
      Mamute_WriteByte(Addr, Result)
      If RIdx <> 6 : Mz80_SetR8(*S, RIdx, 0, Result, #False, 0) : EndIf
  EndSelect
EndProcedure

;- ------------------------------------------------------------
;- Dispatcher ED
;- ------------------------------------------------------------

Procedure Mz80_ExecuteED(*S.MamuteGui_State)
  Protected Opcode.a = Mz80_Fetch8(*S)

  Select Opcode
    Case $40, $48, $50, $58, $60, $68, $70, $78 ; IN r,(C) - $70 = IN F,(C) indocumentado
      Protected InIdx.a = (Opcode >> 3) & 7
      Protected InVal.a = Mamute_IOPort_GetSaida(*S\RegC) ; porta C - "Saida" do Painel de Portas I/O
      Protected FIn.a = *S\RegF & #Mz80_FC
      If InVal = 0 : FIn = FIn | #Mz80_FZ : EndIf
      FIn = FIn | (InVal & #Mz80_FS)
      FIn = FIn | (InVal & (#Mz80_FY | #Mz80_FX))
      If Mz80_Parity(InVal) : FIn = FIn | #Mz80_FPV : EndIf
      *S\RegF = FIn
      If InIdx <> 6 : Mz80_SetR8(*S, InIdx, 0, InVal, #False, 0) : EndIf

    Case $41, $49, $51, $59, $61, $69, $71, $79 ; OUT (C),r - $71 = OUT (C),0 indocumentado (envia a constante 0, nao um registrador)
      Protected OutIdxE.a = (Opcode >> 3) & 7
      Protected OutValE.a = 0
      If OutIdxE <> 6 : OutValE = Mz80_GetR8(*S, OutIdxE, 0, #False, 0) : EndIf
      Mamute_IOPort_SetEntrada(*S\RegC, OutValE) ; porta C - "Entrada" do Painel de Portas I/O

    Case $42, $52, $62, $72 ; SBC HL,rr
      Protected SbcPair.a = (Opcode >> 4) & 3
      Mz80_SetHL(*S, Mz80_Sbc16(*S, Mz80_GetHL(*S), Mz80_Get16(*S, SbcPair, 0)))

    Case $4A, $5A, $6A, $7A ; ADC HL,rr
      Protected AdcPair.a = (Opcode >> 4) & 3
      Mz80_SetHL(*S, Mz80_Adc16(*S, Mz80_GetHL(*S), Mz80_Get16(*S, AdcPair, 0)))

    Case $43, $53, $63, $73 ; LD (nn),rr
      Protected LdPairOut.a = (Opcode >> 4) & 3
      Protected AddrOut.u = Mz80_Fetch16(*S)
      Protected VOut.u = Mz80_Get16(*S, LdPairOut, 0)
      Mamute_WriteByte(AddrOut, VOut & $FF)
      Mamute_WriteByte((AddrOut + 1) & $FFFF, (VOut >> 8) & $FF)

    Case $4B, $5B, $6B, $7B ; LD rr,(nn)
      Protected LdPairIn.a = (Opcode >> 4) & 3
      Protected AddrIn.u = Mz80_Fetch16(*S)
      Protected VInLo.a = Mamute_ReadByte(AddrIn)
      Protected VInHi.a = Mamute_ReadByte((AddrIn + 1) & $FFFF)
      Mz80_Set16(*S, LdPairIn, 0, (VInHi << 8) | VInLo)

    Case $44, $4C, $54, $5C, $64, $6C, $74, $7C ; NEG (e duplicatas indocumentadas)
      *S\RegA = Mz80_Sub8(*S, 0, *S\RegA, #False)

    Case $45, $4D, $55, $5D, $65, $6D, $75, $7D ; RETN/RETI (identicos aqui - sem controlador de IRQ real)
      *S\RegPC = Mz80_Pop16(*S)
      *S\IFF1 = *S\IFF2

    Case $46, $4E, $66, $6E : *S\IM = 0
    Case $56, $76         : *S\IM = 1
    Case $5E, $7E         : *S\IM = 2

    Case $47 : *S\RegI = *S\RegA
    Case $4F : *S\RegR = *S\RegA

    Case $57 ; LD A,I
      *S\RegA = *S\RegI
      Protected F57.a = *S\RegF & #Mz80_FC
      If *S\RegA = 0 : F57 = F57 | #Mz80_FZ : EndIf
      F57 = F57 | (*S\RegA & #Mz80_FS)
      F57 = F57 | (*S\RegA & (#Mz80_FY | #Mz80_FX))
      If *S\IFF2 : F57 = F57 | #Mz80_FPV : EndIf
      *S\RegF = F57

    Case $5F ; LD A,R
      *S\RegA = *S\RegR
      Protected F5F.a = *S\RegF & #Mz80_FC
      If *S\RegA = 0 : F5F = F5F | #Mz80_FZ : EndIf
      F5F = F5F | (*S\RegA & #Mz80_FS)
      F5F = F5F | (*S\RegA & (#Mz80_FY | #Mz80_FX))
      If *S\IFF2 : F5F = F5F | #Mz80_FPV : EndIf
      *S\RegF = F5F

    Case $67 ; RRD
      Protected M67.a = Mamute_ReadByte(Mz80_GetHL(*S))
      Protected NewA67.a = (*S\RegA & $F0) | (M67 & $0F)
      Protected NewM67.a = ((*S\RegA & $0F) << 4) | (M67 >> 4)
      *S\RegA = NewA67
      Mamute_WriteByte(Mz80_GetHL(*S), NewM67)
      Protected F67.a = *S\RegF & #Mz80_FC
      If *S\RegA = 0 : F67 = F67 | #Mz80_FZ : EndIf
      F67 = F67 | (*S\RegA & #Mz80_FS)
      F67 = F67 | (*S\RegA & (#Mz80_FY | #Mz80_FX))
      If Mz80_Parity(*S\RegA) : F67 = F67 | #Mz80_FPV : EndIf
      *S\RegF = F67

    Case $6F ; RLD
      Protected M6F.a = Mamute_ReadByte(Mz80_GetHL(*S))
      Protected NewA6F.a = (*S\RegA & $F0) | (M6F >> 4)
      Protected NewM6F.a = ((M6F << 4) & $F0) | (*S\RegA & $0F)
      *S\RegA = NewA6F
      Mamute_WriteByte(Mz80_GetHL(*S), NewM6F)
      Protected F6F.a = *S\RegF & #Mz80_FC
      If *S\RegA = 0 : F6F = F6F | #Mz80_FZ : EndIf
      F6F = F6F | (*S\RegA & #Mz80_FS)
      F6F = F6F | (*S\RegA & (#Mz80_FY | #Mz80_FX))
      If Mz80_Parity(*S\RegA) : F6F = F6F | #Mz80_FPV : EndIf
      *S\RegF = F6F

    Case $A0 : Mz80_LDI(*S)
    Case $A8 : Mz80_LDD(*S)
    Case $B0
      Mz80_LDI(*S)
      If Mz80_GetBC(*S) <> 0 : *S\RegPC = (*S\RegPC - 2) & $FFFF : EndIf
    Case $B8
      Mz80_LDD(*S)
      If Mz80_GetBC(*S) <> 0 : *S\RegPC = (*S\RegPC - 2) & $FFFF : EndIf

    Case $A1 : Mz80_CPI(*S)
    Case $A9 : Mz80_CPD(*S)
    Case $B1
      Mz80_CPI(*S)
      If Mz80_GetBC(*S) <> 0 And (*S\RegF & #Mz80_FZ) = 0 : *S\RegPC = (*S\RegPC - 2) & $FFFF : EndIf
    Case $B9
      Mz80_CPD(*S)
      If Mz80_GetBC(*S) <> 0 And (*S\RegF & #Mz80_FZ) = 0 : *S\RegPC = (*S\RegPC - 2) & $FFFF : EndIf

    Case $A2 : Mz80_INI(*S)
    Case $AA : Mz80_IND(*S)
    Case $B2
      Mz80_INI(*S)
      If *S\RegB <> 0 : *S\RegPC = (*S\RegPC - 2) & $FFFF : EndIf
    Case $BA
      Mz80_IND(*S)
      If *S\RegB <> 0 : *S\RegPC = (*S\RegPC - 2) & $FFFF : EndIf

    Case $A3 : Mz80_OUTI(*S)
    Case $AB : Mz80_OUTD(*S)
    Case $B3
      Mz80_OUTI(*S)
      If *S\RegB <> 0 : *S\RegPC = (*S\RegPC - 2) & $FFFF : EndIf
    Case $BB
      Mz80_OUTD(*S)
      If *S\RegB <> 0 : *S\RegPC = (*S\RegPC - 2) & $FFFF : EndIf

    Default
      ; ED nao documentado (ex.: $77/$7F) - ja consumiu os 2 bytes via fetch,
      ; sem efeito, PC continua correto (equivalente a NOP de 2 bytes real).
  EndSelect
EndProcedure

;- ------------------------------------------------------------
;- Dispatcher base (256 opcodes nao-prefixados) - IndexMode define se
;- referencias a "HL"/H/L viram IX/IY/IXH/IXL/IYH/IYL (ver Mz80_GetR8/SetR8/
;- Get16/Set16 acima pras regras exatas, incl. excecao do EX DE,HL).
;- ------------------------------------------------------------

Procedure Mz80_ExecuteBase(*S.MamuteGui_State, Opcode.a, IndexMode.a)
  Select Opcode
    Case $00 ; NOP

    Case $01, $11, $21, $31 ; LD rr,nn
      Protected PairIdxLdNN.a = (Opcode >> 4) & 3
      Mz80_Set16(*S, PairIdxLdNN, IndexMode, Mz80_Fetch16(*S))

    Case $02 : Mamute_WriteByte(Mz80_GetBC(*S), *S\RegA)
    Case $0A : *S\RegA = Mamute_ReadByte(Mz80_GetBC(*S))
    Case $12 : Mamute_WriteByte(Mz80_GetDE(*S), *S\RegA)
    Case $1A : *S\RegA = Mamute_ReadByte(Mz80_GetDE(*S))

    Case $03, $13, $23, $33 ; INC rr
      Protected PairIdxIncRR.a = (Opcode >> 4) & 3
      Mz80_Set16(*S, PairIdxIncRR, IndexMode, (Mz80_Get16(*S, PairIdxIncRR, IndexMode) + 1) & $FFFF)

    Case $0B, $1B, $2B, $3B ; DEC rr
      Protected PairIdxDecRR.a = (Opcode >> 4) & 3
      Mz80_Set16(*S, PairIdxDecRR, IndexMode, (Mz80_Get16(*S, PairIdxDecRR, IndexMode) - 1) & $FFFF)

    Case $09, $19, $29, $39 ; ADD HL/IX/IY,rr
      Protected PairIdxAddRR.a = (Opcode >> 4) & 3
      Protected AddDst.u = Mz80_Get16(*S, 2, IndexMode)
      Protected AddSrc.u = Mz80_Get16(*S, PairIdxAddRR, IndexMode)
      Mz80_Set16(*S, 2, IndexMode, Mz80_Add16(*S, AddDst, AddSrc))

    Case $04, $0C, $14, $1C, $24, $2C, $34, $3C ; INC r
      Protected RIdxInc.a = (Opcode >> 3) & 7
      Protected UsesMemInc.b = Bool(RIdxInc = 6)
      Protected DispInc.i = 0
      If UsesMemInc And IndexMode <> 0
        DispInc = Mz80_SignedByte(Mz80_Fetch8(*S))
      EndIf
      Protected OldInc.a = Mz80_GetR8(*S, RIdxInc, IndexMode, UsesMemInc, @DispInc)
      Mz80_SetR8(*S, RIdxInc, IndexMode, Mz80_Inc8(*S, OldInc), UsesMemInc, @DispInc)

    Case $05, $0D, $15, $1D, $25, $2D, $35, $3D ; DEC r
      Protected RIdxDec.a = (Opcode >> 3) & 7
      Protected UsesMemDec.b = Bool(RIdxDec = 6)
      Protected DispDec.i = 0
      If UsesMemDec And IndexMode <> 0
        DispDec = Mz80_SignedByte(Mz80_Fetch8(*S))
      EndIf
      Protected OldDec.a = Mz80_GetR8(*S, RIdxDec, IndexMode, UsesMemDec, @DispDec)
      Mz80_SetR8(*S, RIdxDec, IndexMode, Mz80_Dec8(*S, OldDec), UsesMemDec, @DispDec)

    Case $06, $0E, $16, $1E, $26, $2E, $36, $3E ; LD r,n
      Protected RIdxLdN.a = (Opcode >> 3) & 7
      Protected UsesMemLdN.b = Bool(RIdxLdN = 6)
      Protected DispLdN.i = 0
      If UsesMemLdN And IndexMode <> 0
        DispLdN = Mz80_SignedByte(Mz80_Fetch8(*S)) ; desloc ANTES do imediato (ordem real do Z80)
      EndIf
      Protected ImmLdN.a = Mz80_Fetch8(*S)
      Mz80_SetR8(*S, RIdxLdN, IndexMode, ImmLdN, UsesMemLdN, @DispLdN)

    Case $07 : Mz80_RLCA(*S)
    Case $0F : Mz80_RRCA(*S)
    Case $17 : Mz80_RLA(*S)
    Case $1F : Mz80_RRA(*S)
    Case $27 : Mz80_DAA(*S)
    Case $2F : Mz80_CPL(*S)
    Case $37 : Mz80_SCF(*S)
    Case $3F : Mz80_CCF(*S)

    Case $08 ; EX AF,AF'
      Protected TmpAFHi.a = *S\RegA
      Protected TmpAFLo.a = *S\RegF
      *S\RegA = *S\RegA2 : *S\RegF = *S\RegF2
      *S\RegA2 = TmpAFHi : *S\RegF2 = TmpAFLo

    Case $10 ; DJNZ e
      *S\RegB = (*S\RegB - 1) & $FF
      Protected DjnzOfs.i = Mz80_SignedByte(Mz80_Fetch8(*S))
      If *S\RegB <> 0
        *S\RegPC = (*S\RegPC + DjnzOfs) & $FFFF
      EndIf

    Case $18 ; JR e
      Protected JrOfs.i = Mz80_SignedByte(Mz80_Fetch8(*S))
      *S\RegPC = (*S\RegPC + JrOfs) & $FFFF

    Case $20, $28, $30, $38 ; JR cc,e
      Protected JrCondIdx.a = (Opcode >> 3) & 3
      Protected JrOfsC.i = Mz80_SignedByte(Mz80_Fetch8(*S))
      If Mz80_TestCond(*S, JrCondIdx)
        *S\RegPC = (*S\RegPC + JrOfsC) & $FFFF
      EndIf

    Case $22 ; LD (nn),HL/IX/IY
      Protected Addr22.u = Mz80_Fetch16(*S)
      Protected V22.u = Mz80_Get16(*S, 2, IndexMode)
      Mamute_WriteByte(Addr22, V22 & $FF)
      Mamute_WriteByte((Addr22 + 1) & $FFFF, (V22 >> 8) & $FF)

    Case $2A ; LD HL/IX/IY,(nn)
      Protected Addr2A.u = Mz80_Fetch16(*S)
      Protected Lo2A.a = Mamute_ReadByte(Addr2A)
      Protected Hi2A.a = Mamute_ReadByte((Addr2A + 1) & $FFFF)
      Mz80_Set16(*S, 2, IndexMode, (Hi2A << 8) | Lo2A)

    Case $32 : Mamute_WriteByte(Mz80_Fetch16(*S), *S\RegA)
    Case $3A : *S\RegA = Mamute_ReadByte(Mz80_Fetch16(*S))

    Case $76 ; HALT
      *S\Halted = #True
      *S\RegPC = (*S\RegPC - 1) & $FFFF

    Case $40 To $7F ; LD r,r' ($76 ja tratado acima)
      Protected DstLd.a = (Opcode >> 3) & 7
      Protected SrcLd.a = Opcode & 7
      Protected UsesMemLd.b = Bool(DstLd = 6 Or SrcLd = 6)
      Protected DispLd.i = 0
      If UsesMemLd And IndexMode <> 0
        DispLd = Mz80_SignedByte(Mz80_Fetch8(*S))
      EndIf
      Protected ValLd.a = Mz80_GetR8(*S, SrcLd, IndexMode, UsesMemLd, @DispLd)
      Mz80_SetR8(*S, DstLd, IndexMode, ValLd, UsesMemLd, @DispLd)

    Case $80 To $BF ; ALU A,r
      Protected AluOpR.a = (Opcode >> 3) & 7
      Protected RIdxAlu.a = Opcode & 7
      Protected UsesMemAlu.b = Bool(RIdxAlu = 6)
      Protected DispAlu.i = 0
      If UsesMemAlu And IndexMode <> 0
        DispAlu = Mz80_SignedByte(Mz80_Fetch8(*S))
      EndIf
      Protected OperandAlu.a = Mz80_GetR8(*S, RIdxAlu, IndexMode, UsesMemAlu, @DispAlu)
      Mz80_DoAlu(*S, AluOpR, OperandAlu)

    Case $C0, $C8, $D0, $D8, $E0, $E8, $F0, $F8 ; RET cc
      Protected RetCondIdx.a = (Opcode >> 3) & 7
      If Mz80_TestCond(*S, RetCondIdx)
        *S\RegPC = Mz80_Pop16(*S)
      EndIf

    Case $C1 : Mz80_SetBC(*S, Mz80_Pop16(*S))
    Case $D1 : Mz80_SetDE(*S, Mz80_Pop16(*S))
    Case $E1 : Mz80_Set16(*S, 2, IndexMode, Mz80_Pop16(*S))
    Case $F1 : Mz80_SetAF(*S, Mz80_Pop16(*S))

    Case $C2, $CA, $D2, $DA, $E2, $EA, $F2, $FA ; JP cc,nn
      Protected JpCondIdx.a = (Opcode >> 3) & 7
      Protected JpAddr.u = Mz80_Fetch16(*S)
      If Mz80_TestCond(*S, JpCondIdx)
        *S\RegPC = JpAddr
      EndIf

    Case $C3 : *S\RegPC = Mz80_Fetch16(*S)

    Case $C4, $CC, $D4, $DC, $E4, $EC, $F4, $FC ; CALL cc,nn
      Protected CallCondIdx.a = (Opcode >> 3) & 7
      Protected CallAddrC.u = Mz80_Fetch16(*S)
      If Mz80_TestCond(*S, CallCondIdx)
        Mz80_Push16(*S, *S\RegPC)
        *S\RegPC = CallAddrC
      EndIf

    Case $C5 : Mz80_Push16(*S, Mz80_GetBC(*S))
    Case $D5 : Mz80_Push16(*S, Mz80_GetDE(*S))
    Case $E5 : Mz80_Push16(*S, Mz80_Get16(*S, 2, IndexMode))
    Case $F5 : Mz80_Push16(*S, Mz80_GetAF(*S))

    Case $C6, $CE, $D6, $DE, $E6, $EE, $F6, $FE ; ALU A,n
      Protected AluOpI.a = (Opcode >> 3) & 7
      Protected ImmAlu.a = Mz80_Fetch8(*S)
      Mz80_DoAlu(*S, AluOpI, ImmAlu)

    Case $C7, $CF, $D7, $DF, $E7, $EF, $F7, $FF ; RST
      Mz80_Push16(*S, *S\RegPC)
      *S\RegPC = Opcode & $38

    Case $C9 : *S\RegPC = Mz80_Pop16(*S)

    Case $CD ; CALL nn
      Protected CallAddr.u = Mz80_Fetch16(*S)
      Mz80_Push16(*S, *S\RegPC)
      *S\RegPC = CallAddr

    Case $D3 ; OUT (n),A - grava "Entrada" da porta no Painel de Portas I/O (Mamute_IOPort_SetEntrada, MamuteIoGui.pbi)
      Protected OutPortImm.a = Mz80_Fetch8(*S)
      Mamute_IOPort_SetEntrada(OutPortImm, *S\RegA)

    Case $DB ; IN A,(n) - le "Saida" da porta no Painel de Portas I/O (Mamute_IOPort_GetSaida)
      Protected InPortImm.a = Mz80_Fetch8(*S)
      *S\RegA = Mamute_IOPort_GetSaida(InPortImm)

    Case $D9 ; EXX
      Protected TB.a = *S\RegB : Protected TC.a = *S\RegC
      *S\RegB = *S\RegB2 : *S\RegC = *S\RegC2 : *S\RegB2 = TB : *S\RegC2 = TC
      Protected TD.a = *S\RegD : Protected TE.a = *S\RegE
      *S\RegD = *S\RegD2 : *S\RegE = *S\RegE2 : *S\RegD2 = TD : *S\RegE2 = TE
      Protected TH.a = *S\RegH : Protected TL.a = *S\RegL
      *S\RegH = *S\RegH2 : *S\RegL = *S\RegL2 : *S\RegH2 = TH : *S\RegL2 = TL

    Case $E3 ; EX (SP),HL/IX/IY
      Protected SpVal.u = Mz80_Get16(*S, 2, IndexMode)
      Protected MemLo.a = Mamute_ReadByte(*S\RegSP)
      Protected MemHi.a = Mamute_ReadByte((*S\RegSP + 1) & $FFFF)
      Mamute_WriteByte(*S\RegSP, SpVal & $FF)
      Mamute_WriteByte((*S\RegSP + 1) & $FFFF, (SpVal >> 8) & $FF)
      Mz80_Set16(*S, 2, IndexMode, (MemHi << 8) | MemLo)

    Case $E9 : *S\RegPC = Mz80_Get16(*S, 2, IndexMode) ; JP (HL)/(IX)/(IY)

    Case $EB ; EX DE,HL - NUNCA afetado por indice (mesmo sob DD/FD, sempre HL real)
      Protected TmpDE.u = Mz80_GetDE(*S)
      Mz80_SetDE(*S, Mz80_GetHL(*S))
      Mz80_SetHL(*S, TmpDE)

    Case $F3 : *S\IFF1 = #False : *S\IFF2 = #False ; DI
    Case $FB : *S\IFF1 = #True  : *S\IFF2 = #True  ; EI

    Case $F9 : *S\RegSP = Mz80_Get16(*S, 2, IndexMode) ; LD SP,HL/IX/IY

    Default
      ; Nao deveria acontecer - todos os 256 opcodes base estao cobertos acima
      ; (CB/ED/DD/FD sao interceptados por Mz80_ExecuteOne antes de chegar aqui).
  EndSelect
EndProcedure

;- ------------------------------------------------------------
;- Ponto de entrada unico - trata cadeias de prefixo DD/FD (o ultimo vale;
;- se vier ED logo depois, o DD/FD anterior fica sem efeito - comportamento
;- real do Z80 pra essa combinacao nao documentada).
;- ------------------------------------------------------------

Procedure Mz80_ExecuteOne(*S.MamuteGui_State)
  If *S\Halted
    ProcedureReturn ; HALT "prende" o PC ali ate uma interrupcao (nao existe na Fase 1)
  EndIf

  Protected IndexMode.a = 0
  Protected Opcode.a = Mz80_Fetch8(*S)
  While Opcode = $DD Or Opcode = $FD
    If Opcode = $DD : IndexMode = 1 : Else : IndexMode = 2 : EndIf
    Opcode = Mz80_Fetch8(*S)
  Wend

  Select Opcode
    Case $CB
      If IndexMode = 0
        Mz80_ExecuteCB(*S)
      Else
        Protected DispCB.i = Mz80_SignedByte(Mz80_Fetch8(*S))
        Protected CBOp.a = Mz80_Fetch8(*S)
        Mz80_ExecuteCBIndexed(*S, IndexMode, DispCB, CBOp)
      EndIf
    Case $ED
      Mz80_ExecuteED(*S)
    Default
      Mz80_ExecuteBase(*S, Opcode, IndexMode)
  EndSelect
EndProcedure

;- ------------------------------------------------------------
;- Controle de alto nivel (Reset/Step Into/Step Over/Step Out/Run) - chamado
;- pela GUI (MamuteDebuggerGui.pbi)
;- ------------------------------------------------------------

Procedure Mz80_ResetToStart(*State.MamuteGui_State, StartAddr.u)
  *State\RegPC = StartAddr
  *State\Halted = #False
  *State\IFF1 = #False
  *State\IFF2 = #False
  *State\IM = 0
  *State\RegI = 0
  *State\RegR = 0
EndProcedure

Procedure.s Mz80_StepInto(*State.MamuteGui_State)
  If *State\Halted
    ProcedureReturn "CPU HALTADA (HALT) - sem interrupcao configurada pra retomar"
  EndIf
  Protected Len.i
  Protected Text.s = Mamute_DisasmOne(*State\RegPC, @Len)
  Mz80_ExecuteOne(*State)
  ProcedureReturn Text
EndProcedure

; #True = completou normalmente (ou nao era CALL/RST, virou um StepInto simples);
; #False = abortou por estourar o teto de seguranca (a chamada nunca retornou).
Procedure.b Mz80_StepOver(*State.MamuteGui_State)
  If *State\Halted
    ProcedureReturn #True
  EndIf
  Protected Len.i
  Mamute_DisasmOne(*State\RegPC, @Len)
  Protected Opcode.a = Mamute_ReadByte(*State\RegPC)
  Protected IsCall.b = Bool(Opcode = $CD Or Opcode = $C4 Or Opcode = $CC Or Opcode = $D4 Or Opcode = $DC Or Opcode = $E4 Or Opcode = $EC Or Opcode = $F4 Or Opcode = $FC Or (Opcode & $C7) = $C7)

  If Not IsCall
    Mz80_ExecuteOne(*State)
    ProcedureReturn #True
  EndIf

  Protected ReturnAddr.u = (*State\RegPC + Len) & $FFFF
  Mz80_ExecuteOne(*State) ; entra na chamada (ou no RST)
  Protected Steps.q = 0
  While *State\RegPC <> ReturnAddr And Not *State\Halted
    Mz80_ExecuteOne(*State)
    Steps + 1
    If Steps > #Mz80_MaxStepBudget
      ProcedureReturn #False
    EndIf
  Wend
  ProcedureReturn #True
EndProcedure

Procedure.b Mz80_StepOut(*State.MamuteGui_State)
  If *State\Halted
    ProcedureReturn #True
  EndIf
  Protected EntrySP.u = *State\RegSP
  Protected Steps.q = 0
  Repeat
    Mz80_ExecuteOne(*State)
    Steps + 1
    If *State\Halted
      ProcedureReturn #True
    EndIf
    If Steps > #Mz80_MaxStepBudget
      ProcedureReturn #False
    EndIf
  Until *State\RegSP > EntrySP
  ProcedureReturn #True
EndProcedure

Procedure.s Mz80_Run(*State.MamuteGui_State)
  If *State\Halted
    ProcedureReturn "CPU HALTADA (HALT) EM " + Mamute_Hex4(*State\RegPC)
  EndIf
  Protected Steps.q = 0
  Repeat
    Mz80_ExecuteOne(*State)
    Steps + 1
    If *State\Halted
      ProcedureReturn "CPU HALTADA (HALT) EM " + Mamute_Hex4(*State\RegPC)
    EndIf
    If *State\HasBreak1 And *State\RegPC = *State\Break1Addr
      ProcedureReturn "PARADO NO BREAKPOINT 1 (" + Mamute_Hex4(*State\RegPC) + ")"
    EndIf
    If *State\HasBreak2 And *State\RegPC = *State\Break2Addr
      ProcedureReturn "PARADO NO BREAKPOINT 2 (" + Mamute_Hex4(*State\RegPC) + ")"
    EndIf
    If Steps > #Mz80_MaxStepBudget
      ProcedureReturn "RUN INTERROMPIDO - LIMITE DE " + Str(#Mz80_MaxStepBudget) + " INSTRUCOES ATINGIDO"
    EndIf
  ForEver
EndProcedure
