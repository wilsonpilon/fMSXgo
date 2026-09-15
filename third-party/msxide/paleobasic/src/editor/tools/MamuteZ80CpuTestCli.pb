;
; ------------------------------------------------------------
;  MamuteZ80CpuTestCli.pb - harness headless (sem GUI) do nucleo de execucao
;  Z80 do debugger visual do Mamute Assembler (editor\MamuteZ80Cpu.pbi).
;
;  MamuteZ80Cpu.pbi so referencia por NOME os simbolos MamuteGui_State/
;  Mamute_ReadByte/Mamute_WriteByte/Mamute_Hex4/Mamute_DisasmOne (nao os
;  inclui via XIncludeFile) - este harness fornece versoes minimas e
;  autocontidas desses simbolos (memoria plana de 64KB, sem sistema de
;  slots/paginas) em vez de arrastar MamuteSupport.pbi/MamuteAssemblerGui.pbi
;  inteiros (arquivos de GUI pesados) pra dentro de um /CONSOLE. A Structure
;  MamuteGui_State abaixo e uma COPIA dos campos reais (MamuteAssemblerGui.pbi)
;  - se os campos de registrador mudarem la, atualizar aqui tambem.
;
;  Compilar:
;  "C:\Basic\Compilers\pbcompiler.exe" editor\tools\MamuteZ80CpuTestCli.pb /EXE editor\tools\MamuteZ80CpuTestCli.exe /CONSOLE
;
;  Uso: MamuteZ80CpuTestCli.exe   (sem argumentos - roda a suite embutida)
;       exit code = numero de falhas (0 = tudo passou), mesmo padrao de
;       Z80AsmTestCli.pb/PsgTestCli.pb.
; ------------------------------------------------------------
;

EnableExplicit
OpenConsole()

Structure MamuteGui_State
  LogAccum.s
  ShouldQuit.b
  HasLastSh.b
  LastShAddr.i
  HasLastM.b
  LastMAddr.i
  HasLastS.b
  LastSAddr.i
  DisplayMode.b
  RegA.a : RegF.a : RegB.a : RegC.a : RegD.a : RegE.a : RegH.a : RegL.a
  RegIX.u : RegIY.u : RegSP.u
  HasLastL.b
  LastLAddr.i
  RegPC.u
  RegA2.a : RegF2.a : RegB2.a : RegC2.a : RegD2.a : RegE2.a : RegH2.a : RegL2.a
  RegI.a : RegR.a
  IFF1.b : IFF2.b : IM.a
  Halted.b
  HasBreak1.b : Break1Addr.u
  HasBreak2.b : Break2Addr.u
EndStructure

Global Dim TestMem.a(65535)

Procedure.a Mamute_ReadByte(Addr.i)
  ProcedureReturn TestMem(Addr & $FFFF)
EndProcedure

Procedure.b Mamute_WriteByte(Addr.i, Value.a)
  TestMem(Addr & $FFFF) = Value
  ProcedureReturn #True
EndProcedure

Procedure.s Mamute_Hex4(v.i)
  ProcedureReturn RSet(Hex(v & $FFFF), 4, "0")
EndProcedure

; Stand-in simplificado (NAO e um disassembler de verdade) - so cobre os
; opcodes usados pelos programas de teste abaixo, o suficiente pra
; Mz80_StepOver calcular o endereco de retorno certo apos um CALL. Qualquer
; opcode fora da lista cai no Default (1 byte), que so seria errado se um
; teste futuro usar StepOver sobre uma instrucao nao listada aqui.
Procedure.s Mamute_DisasmOne(Addr.i, *OutLen.Integer)
  Protected Op.a = Mamute_ReadByte(Addr)
  Select Op
    Case $3E, $C6, $D6, $06, $0E, $36, $CE, $E6, $EE, $F6, $FE, $DE, $16, $1E, $26, $2E : *OutLen\i = 2
    Case $21, $11, $31, $22, $2A, $32, $3A, $CD, $C4, $CC, $D4, $DC, $E4, $EC, $F4, $FC, $C2, $CA, $D2, $DA, $E2, $EA, $F2, $FA : *OutLen\i = 3
    Case $CB : *OutLen\i = 2
    Case $DD, $FD : *OutLen\i = 2 ; simplificado - nao cobre prefixo+CB nem operandos indexados (nao usado por StepOver nos testes)
    Case $ED : *OutLen\i = 2
    Default : *OutLen\i = 1
  EndSelect
  ProcedureReturn ""
EndProcedure

XIncludeFile "..\assemblers\MamuteZ80Cpu.pbi"

Define Failures = 0

Procedure CheckEqual(Actual.q, Expected.q, Label.s)
  Shared Failures
  If Actual = Expected
    PrintN("OK    - " + Label)
  Else
    PrintN("FALHA - " + Label + " (esperado " + Hex(Expected) + ", obtido " + Hex(Actual) + ")")
    Failures + 1
  EndIf
EndProcedure

Procedure CheckTrue(Ok.i, Label.s)
  Shared Failures
  If Ok
    PrintN("OK    - " + Label)
  Else
    PrintN("FALHA - " + Label)
    Failures + 1
  EndIf
EndProcedure

;- ------------------------------------------------------------
;- Programa 1: LD/ADD/SUB/INC r/INC (HL)/LD rr,nn/LD (HL),n/EX DE,HL/
;- LD SP,nn/PUSH/POP/CALL/RET/NOP/HALT - grade base do opcode set.
;- ------------------------------------------------------------
Procedure Mz80Test_LoadProgram1()
  Protected Bytes.s = "3E 05 C6 0A D6 0F 3C 06 FF 04 21 00 90 36 55 34 11 34 12 EB 31 00 81 E5 C1 CD 20 80 00 76"
  Protected Addr.i = $8000
  Protected i.i
  For i = 1 To CountString(Bytes, " ") + 1
    TestMem(Addr) = Val("$" + StringField(Bytes, i, " "))
    Addr + 1
  Next
  ; Sub-rotina em $8020: LD A,99h / RET
  TestMem($8020) = $3E : TestMem($8021) = $99 : TestMem($8022) = $C9
EndProcedure

Procedure Mz80Test_Program1()
  Protected S.MamuteGui_State
  Mz80_ResetToStart(@S, $8000)

  Mz80_StepInto(@S) : CheckEqual(S\RegA, $05, "P1 step1: LD A,05 -> A=05")
  Mz80_StepInto(@S) : CheckEqual(S\RegA, $0F, "P1 step2: ADD A,0Ah -> A=0F")
  CheckTrue(Bool((S\RegF & #Mz80_FC) = 0), "P1 step2: sem carry")
  Mz80_StepInto(@S) : CheckEqual(S\RegA, $00, "P1 step3: SUB 0Fh -> A=00")
  CheckTrue(Bool((S\RegF & #Mz80_FZ) <> 0), "P1 step3: flag Z ligada")
  Mz80_StepInto(@S) : CheckEqual(S\RegA, $01, "P1 step4: INC A -> A=01")
  Mz80_StepInto(@S) : CheckEqual(S\RegB, $FF, "P1 step5: LD B,FFh")
  Mz80_StepInto(@S)
  CheckEqual(S\RegB, $00, "P1 step6: INC B (FFh+1) -> B=00 (wrap)")
  CheckTrue(Bool((S\RegF & #Mz80_FZ) <> 0), "P1 step6: flag Z ligada")
  CheckTrue(Bool((S\RegF & #Mz80_FH) <> 0), "P1 step6: flag H ligada")
  Mz80_StepInto(@S) : CheckEqual(Mz80_GetHL(@S), $9000, "P1 step7: LD HL,9000h")
  Mz80_StepInto(@S) : CheckEqual(TestMem($9000), $55, "P1 step8: LD (HL),55h")
  Mz80_StepInto(@S) : CheckEqual(TestMem($9000), $56, "P1 step9: INC (HL) -> mem[9000]=56h")
  Mz80_StepInto(@S) : CheckEqual(Mz80_GetDE(@S), $1234, "P1 step10: LD DE,1234h")
  Mz80_StepInto(@S)
  CheckEqual(Mz80_GetDE(@S), $9000, "P1 step11: EX DE,HL -> DE=9000h")
  CheckEqual(Mz80_GetHL(@S), $1234, "P1 step11: EX DE,HL -> HL=1234h")
  Mz80_StepInto(@S) : CheckEqual(S\RegSP, $8100, "P1 step12: LD SP,8100h")
  Mz80_StepInto(@S)
  CheckEqual(S\RegSP, $80FE, "P1 step13: PUSH HL -> SP=80FEh")
  CheckEqual(TestMem($80FE), $34, "P1 step13: mem[80FE]=34h (byte baixo)")
  CheckEqual(TestMem($80FF), $12, "P1 step13: mem[80FF]=12h (byte alto)")
  Mz80_StepInto(@S)
  CheckEqual(Mz80_GetBC(@S), $1234, "P1 step14: POP BC -> BC=1234h")
  CheckEqual(S\RegSP, $8100, "P1 step14: SP de volta a 8100h")
  Mz80_StepInto(@S)
  CheckEqual(S\RegPC, $8020, "P1 step15: CALL 8020h -> PC=8020h")
  CheckEqual(S\RegSP, $80FE, "P1 step15: SP apos push do retorno")
  Mz80_StepInto(@S) : CheckEqual(S\RegA, $99, "P1 step16: LD A,99h (dentro da sub-rotina)")
  Mz80_StepInto(@S)
  CheckEqual(S\RegPC, $801C, "P1 step17: RET -> PC=801Ch (logo apos o CALL)")
  CheckEqual(S\RegSP, $8100, "P1 step17: SP de volta a 8100h apos RET")
  Mz80_StepInto(@S) : CheckEqual(S\RegPC, $801D, "P1 step18: NOP -> PC=801Dh")
  Mz80_StepInto(@S)
  CheckEqual(S\RegPC, $801D, "P1 step19: HALT -> PC fica em 801Dh")
  CheckTrue(S\Halted, "P1 step19: Halted = #True")
EndProcedure

; Mesmo programa 1, mas usando Mz80_StepOver sobre o CALL 8020h (deve
; executar CALL+LD A,99h+RET inteiros numa unica chamada, sem passar pela
; sub-rotina passo a passo).
Procedure Mz80Test_Program1_StepOver()
  Protected S.MamuteGui_State
  Mz80_ResetToStart(@S, $8000)
  Protected i.i
  For i = 1 To 14 : Mz80_StepInto(@S) : Next ; anda ate a instrucao CALL (PC=8019h)
  CheckEqual(S\RegPC, $8019, "P1/StepOver: chegou no CALL (PC=8019h)")

  Protected Ok.b = Mz80_StepOver(@S)
  CheckTrue(Ok, "P1/StepOver: nao estourou o teto de seguranca")
  CheckEqual(S\RegPC, $801C, "P1/StepOver: PC=801Ch (logo apos o CALL, sub-rotina inteira executada)")
  CheckEqual(S\RegA, $99, "P1/StepOver: A=99h (setado dentro da sub-rotina)")
  CheckEqual(S\RegSP, $8100, "P1/StepOver: SP de volta a 8100h")
EndProcedure

;- ------------------------------------------------------------
;- Programa 2: LD IX,nn / LD (IX+d),n / DD CB (SET/BIT indexado)
;- ------------------------------------------------------------
Procedure Mz80Test_Program2()
  Protected Addr.i = $8100
  Protected Bytes.s = "DD 21 00 90 DD 36 05 42 DD CB 05 C6 DD CB 05 5E 76"
  Protected i.i
  For i = 1 To CountString(Bytes, " ") + 1
    TestMem(Addr) = Val("$" + StringField(Bytes, i, " "))
    Addr + 1
  Next

  Protected S.MamuteGui_State
  Mz80_ResetToStart(@S, $8100)

  Mz80_StepInto(@S) : CheckEqual(S\RegIX, $9000, "P2 step1: LD IX,9000h")
  Mz80_StepInto(@S) : CheckEqual(TestMem($9005), $42, "P2 step2: LD (IX+5),42h -> mem[9005]=42h")
  Mz80_StepInto(@S) : CheckEqual(TestMem($9005), $43, "P2 step3: SET 0,(IX+5) -> mem[9005]=43h")
  Mz80_StepInto(@S)
  CheckTrue(Bool((S\RegF & #Mz80_FZ) <> 0), "P2 step4: BIT 3,(IX+5) sobre 43h -> bit3=0 -> Z ligada")
EndProcedure

;- ------------------------------------------------------------
;- Programa 3: LDIR (bloco ED) - single-step deve reexecutar a MESMA
;- instrucao ate BC=0, exatamente como um debugger real precisa mostrar.
;- ------------------------------------------------------------
Procedure Mz80Test_Program3()
  TestMem($9000) = $11 : TestMem($9001) = $22 : TestMem($9002) = $33

  Protected Addr.i = $8200
  Protected Bytes.s = "21 00 90 11 00 A0 01 03 00 ED B0 76"
  Protected i.i
  For i = 1 To CountString(Bytes, " ") + 1
    TestMem(Addr) = Val("$" + StringField(Bytes, i, " "))
    Addr + 1
  Next

  Protected S.MamuteGui_State
  Mz80_ResetToStart(@S, $8200)
  Mz80_StepInto(@S) : CheckEqual(Mz80_GetHL(@S), $9000, "P3 step1: LD HL,9000h")
  Mz80_StepInto(@S) : CheckEqual(Mz80_GetDE(@S), $A000, "P3 step2: LD DE,0A000h")
  Mz80_StepInto(@S) : CheckEqual(Mz80_GetBC(@S), $0003, "P3 step3: LD BC,0003h")

  Mz80_StepInto(@S)
  CheckEqual(S\RegPC, $8209, "P3 LDIR iter1: PC volta pra 8209h (BC ainda <> 0)")
  CheckEqual(TestMem($A000), $11, "P3 LDIR iter1: mem[A000]=11h copiado")
  CheckEqual(Mz80_GetBC(@S), 2, "P3 LDIR iter1: BC=2")

  Mz80_StepInto(@S)
  CheckEqual(TestMem($A001), $22, "P3 LDIR iter2: mem[A001]=22h copiado")
  CheckEqual(Mz80_GetBC(@S), 1, "P3 LDIR iter2: BC=1")

  Mz80_StepInto(@S)
  CheckEqual(TestMem($A002), $33, "P3 LDIR iter3: mem[A002]=33h copiado")
  CheckEqual(Mz80_GetBC(@S), 0, "P3 LDIR iter3: BC=0")
  CheckEqual(S\RegPC, $820B, "P3 LDIR iter3: BC=0, PC segue pra 820Bh (nao repete mais)")
EndProcedure

;- ------------------------------------------------------------
;- Programa 4: overflow (PV) de ADD/SUB, DAA (correcao BCD), CPL/SCF/CCF,
;- ADC HL,rr/SBC HL,rr (ED) com carry.
;- ------------------------------------------------------------
Procedure Mz80Test_Program4()
  Protected Addr.i = $8300
  Protected Bytes.s = "3E 7F C6 01 3E 80 D6 01 3E 15 C6 27 27 3E AA 2F 37 3F 21 FF FF 01 01 00 37 ED 4A 11 02 00 37 ED 52 76"
  Protected i.i
  For i = 1 To CountString(Bytes, " ") + 1
    TestMem(Addr) = Val("$" + StringField(Bytes, i, " "))
    Addr + 1
  Next

  Protected S.MamuteGui_State
  Mz80_ResetToStart(@S, $8300)

  Mz80_StepInto(@S) : Mz80_StepInto(@S) ; LD A,7Fh / ADD A,01h
  CheckEqual(S\RegA, $80, "P4: ADD A,7Fh+01h -> A=80h (overflow)")
  CheckTrue(Bool((S\RegF & #Mz80_FPV) <> 0), "P4: ADD 7Fh+01h -> PV ligada (overflow)")
  CheckTrue(Bool((S\RegF & #Mz80_FS) <> 0), "P4: ADD 7Fh+01h -> S ligada")

  Mz80_StepInto(@S) : Mz80_StepInto(@S) ; LD A,80h / SUB 01h
  CheckEqual(S\RegA, $7F, "P4: SUB 80h-01h -> A=7Fh (overflow)")
  CheckTrue(Bool((S\RegF & #Mz80_FPV) <> 0), "P4: SUB 80h-01h -> PV ligada (overflow)")
  CheckTrue(Bool((S\RegF & #Mz80_FC) = 0), "P4: SUB 80h-01h -> sem borrow (C=0)")

  Mz80_StepInto(@S) : Mz80_StepInto(@S) : Mz80_StepInto(@S) ; LD A,15h / ADD A,27h / DAA
  CheckEqual(S\RegA, $42, "P4: DAA apos 15h+27h (binario) -> A=42h (BCD correto, 15+27=42)")

  Mz80_StepInto(@S) : Mz80_StepInto(@S) ; LD A,AAh / CPL
  CheckEqual(S\RegA, $55, "P4: CPL de AAh -> A=55h")

  Mz80_StepInto(@S) ; SCF
  CheckTrue(Bool((S\RegF & #Mz80_FC) <> 0), "P4: SCF -> C ligada")
  Mz80_StepInto(@S) ; CCF
  CheckTrue(Bool((S\RegF & #Mz80_FC) = 0), "P4: CCF apos SCF -> C desligada (complementou)")

  Mz80_StepInto(@S) : Mz80_StepInto(@S) : Mz80_StepInto(@S) ; LD HL,FFFFh / LD BC,0001h / SCF
  Mz80_StepInto(@S) ; ADC HL,BC (ED 4A)
  CheckEqual(Mz80_GetHL(@S), $0001, "P4: ADC HL,BC (FFFFh+0001h+1) -> HL=0001h (estourou)")
  CheckTrue(Bool((S\RegF & #Mz80_FC) <> 0), "P4: ADC HL,BC -> C ligada")

  Mz80_StepInto(@S) : Mz80_StepInto(@S) ; LD DE,0002h / SCF
  Mz80_StepInto(@S) ; SBC HL,DE (ED 52)
  CheckEqual(Mz80_GetHL(@S), $FFFE, "P4: SBC HL,DE (0001h-0002h-1) -> HL=FFFEh")
  CheckTrue(Bool((S\RegF & #Mz80_FC) <> 0), "P4: SBC HL,DE -> C ligada (borrow)")
  CheckTrue(Bool((S\RegF & #Mz80_FS) <> 0), "P4: SBC HL,DE -> S ligada")
EndProcedure

Mz80Test_LoadProgram1()
Mz80Test_Program1()
Mz80Test_LoadProgram1() ; recarrega (Program1_StepOver reusa os mesmos enderecos)
Mz80Test_Program1_StepOver()
Mz80Test_Program2()
Mz80Test_Program3()
Mz80Test_Program4()

PrintN("")
If Failures = 0
  PrintN("TODOS OS TESTES PASSARAM")
Else
  PrintN(Str(Failures) + " TESTE(S) FALHARAM")
EndIf
End Failures
