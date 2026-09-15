; Z80 CPU Emulation Core for PureBasic
; Portable Z80 Emulator
; Translated from C source by Marat Fayzullin

; Flag Bits in AF Register
#S_FLAG = $80       ; 1: Result negative
#Z_FLAG = $40       ; 1: Result is zero
#H_FLAG = $10       ; 1: Halfcarry/Halfborrow
#P_FLAG = $04       ; 1: Result is even / Overflow occurred
#V_FLAG = $04       ; 1: Overflow occurred
#N_FLAG = $02       ; 1: Subtraction occurred
#C_FLAG = $01       ; 1: Carry/Borrow occurred

; LoopZ80() returns / Interrupt Vectors
#INT_RST00 = $00C7  ; RST 00h
#INT_RST08 = $00CF  ; RST 08h
#INT_RST10 = $00D7  ; RST 10h
#INT_RST18 = $00DF  ; RST 18h
#INT_RST20 = $00E7  ; RST 20h
#INT_RST28 = $00EF  ; RST 28h
#INT_RST30 = $00F7  ; RST 30h
#INT_RST38 = $00FF  ; RST 38h
#INT_IRQ   = #INT_RST38
#INT_NMI   = $FFFD  ; Non-maskable interrupt
#INT_NONE  = $FFFF  ; No interrupt required
#INT_QUIT  = $FFFE  ; Exit the emulation

; Bits in IFF flip-flops
#IFF_1    = $01     ; IFF1 flip-flop
#IFF_IM1  = $02     ; 1: IM1 mode
#IFF_IM2  = $04     ; 1: IM2 mode
#IFF_2    = $08     ; IFF2 flip-flop
#IFF_EI   = $20     ; 1: EI pending
#IFF_HALT = $80     ; 1: CPU HALTed

; Structure representing low/high bytes of a 16-bit register
Structure RegBytes
  l.a
  h.a
EndStructure

; Union for 16-bit registers with individual byte access (LSB first)
Structure RegisterPair
  StructureUnion
    W.u
    B.RegBytes
  EndStructureUnion
EndStructure

; Main Z80 CPU context structure
Structure Z80
  AF.RegisterPair
  BC.RegisterPair
  DE.RegisterPair
  HL.RegisterPair
  IX.RegisterPair
  IY.RegisterPair
  XX.RegisterPair
  PC.RegisterPair
  SP.RegisterPair
  
  AF1.RegisterPair ; Shadow registers
  BC1.RegisterPair
  DE1.RegisterPair
  HL1.RegisterPair
  
  IFF.a ; Interrupt status/IFF flip-flops
  I.a   ; Interrupt vector register
  R.a   ; Refresh register
  
  IPeriod.l   ; Cycles between LoopZ80() calls
  ICount.l    ; Cycles remaining
  IBackup.l   ; Backup cycle count (used during EI)
  IRequest.u  ; Vector of pending interrupt
  IAutoReset.a ; Auto-reset of IRequest flag
  TrapBadOps.a ; Set to 1 to debug bad/illegal opcodes
  Trap.u      ; Trace trap address
  Trace.a     ; Tracing on/off
  User.i      ; Arbitrary user pointer/integer (RAM index, ID, etc)
EndStructure

; Forward-declared here, real body lives in MSX.pbi (XIncludeFile'd after this file) -
; temporary crash-diagnostic checkpoints around RunZ80's LoopZ80() call, and the
; per-category log wrappers (LogCPU is what RunZ80 actually uses).
Declare LogMsg(Msg.s)
Declare LogCPU(Msg.s)

; Instruction trace state (used by RunZ80's main loop below) - declared here rather
; than in MSX.pbi because Z80.pbi is XIncludeFile'd first and RunZ80 needs these before
; MSX.pbi's own Globals section would otherwise define them. Off by default, auto-armed
; the moment PC enters the cartridge window ($4000-$7FFF) - see comment at the trace
; site in RunZ80() for the full rationale.
Global TraceActive.b = 0
Global TraceWasInCart.b = 0
Global TraceInstrInVisit.l = 0
#TraceMaxInstrPerVisit = 5000      ; cap per continuous stay inside cartridge range, so a
                                   ; game that legitimately runs there for a while doesn't
                                   ; flood the log - the ENTER/LEAVE markers still fire.

; Cheap (no I/O) rolling ring of the last #PCRingSize PCs, dumped via LogCPU the moment
; PC hits $0000 - that's the reset vector, so seeing it means something (RST 0, a wild
; jump, or a real machine reset) sent execution back to square one. This is what the
; per-instruction cartridge-range trace above can't see on its own, since the reset
; trigger typically fires from RAM/BIOS code outside that window. Capped so a game that
; legitimately resets itself repeatedly (or never does) doesn't flood the log either way.
#PCRingSize = 64
#PCRingMaxDumps = 5
Global Dim PCRing.u(#PCRingSize - 1)
Global PCRingPos.b = 0
Global PCRingDumps.b = 0
Global PCRingWasZero.b = 0

; --- Memory & I/O Callback Prototypes ---
Prototype.a RdZ80_Callback(Addr.u)
Prototype WrZ80_Callback(Addr.u, Value.a)
Prototype.a InZ80_Callback(Port.u)
Prototype OutZ80_Callback(Port.u, Value.a)
Prototype PatchZ80_Callback(*R.Z80)
Prototype.u LoopZ80_Callback(*R.Z80)
Prototype JumpZ80_Callback(PC.u)

; Global Callback pointers (to be set by the main emulator code)
; RdZ80 renamed to RealRdZ80 + SafeRdZ80() wrapper below - temporary crash diagnostic
; (confirmed via crash-dump analysis that the RdZ80 pointer goes NULL mid-run; every
; call site was bulk-renamed from "RdZ80(" to "SafeRdZ80(" across Z80.pbi and all
; Z80_Codes*.pbi to find exactly which call sees it null first).
Global RealRdZ80.RdZ80_Callback
Global WrZ80.WrZ80_Callback
Global InZ80.InZ80_Callback
Global OutZ80.OutZ80_Callback
Global PatchZ80.PatchZ80_Callback
Global LoopZ80.LoopZ80_Callback
Global JumpZ80.JumpZ80_Callback

Procedure.a SafeRdZ80(Addr.u)
  If Not RealRdZ80
    LogCPU("CRITICAL: RealRdZ80 NULL at call site, Addr=$" + Hex(Addr))
    End
  EndIf
  ProcedureReturn RealRdZ80(Addr)
EndProcedure

; --- Internal Emulation Procedures/Macros ---

; Sign extend an 8-bit value to a 32-bit signed integer
Macro SignExtend8(Val)
  ( (Val) | ($FFFFFF00 * ((Val) >> 7)) )
EndMacro

; Basic CPU helpers
Macro S(Fl)
  *R\AF\B\l = *R\AF\B\l | (Fl)
EndMacro

Macro R(Fl)
  *R\AF\B\l = *R\AF\B\l & (~(Fl))
EndMacro

Macro FLAGS(Rg, Fl)
  *R\AF\B\l = (Fl) | PZSTable(Rg)
EndMacro

Macro INCR(N)
  *R\R = ((*R\R + (N)) & $7F) | (*R\R & $80)
EndMacro

Macro OpZ80(Addr)
  SafeRdZ80(Addr)
EndMacro

Procedure.a ReadOp(*R.Z80)
  Protected val.a = SafeRdZ80(*R\PC\W)
  *R\PC\W + 1
  ProcedureReturn val
EndProcedure

Procedure.a ReadPop(*R.Z80)
  Protected val.a = SafeRdZ80(*R\SP\W)
  *R\SP\W + 1
  ProcedureReturn val
EndProcedure

; --- Translation Macros for Z80 Instructions ---

Macro M_RLC(Rg)
  *R\AF\B\l = (Rg) >> 7
  Rg = ((Rg) << 1) | *R\AF\B\l
  *R\AF\B\l = *R\AF\B\l | PZSTable(Rg)
EndMacro

Macro M_RRC(Rg)
  *R\AF\B\l = (Rg) & $01
  Rg = ((Rg) >> 1) | (*R\AF\B\l << 7)
  *R\AF\B\l = *R\AF\B\l | PZSTable(Rg)
EndMacro

Macro M_RL(Rg)
  If (Rg) & $80
    Rg = ((Rg) << 1) | (*R\AF\B\l & #C_FLAG)
    *R\AF\B\l = PZSTable(Rg) | #C_FLAG
  Else
    Rg = ((Rg) << 1) | (*R\AF\B\l & #C_FLAG)
    *R\AF\B\l = PZSTable(Rg)
  EndIf
EndMacro

Macro M_RR(Rg)
  If (Rg) & $01
    Rg = ((Rg) >> 1) | (*R\AF\B\l << 7)
    *R\AF\B\l = PZSTable(Rg) | #C_FLAG
  Else
    Rg = ((Rg) >> 1) | (*R\AF\B\l << 7)
    *R\AF\B\l = PZSTable(Rg)
  EndIf
EndMacro

Macro M_SLA(Rg)
  *R\AF\B\l = (Rg) >> 7
  Rg = (Rg) << 1
  *R\AF\B\l = *R\AF\B\l | PZSTable(Rg)
EndMacro

Macro M_SRA(Rg)
  *R\AF\B\l = (Rg) & #C_FLAG
  Rg = ((Rg) >> 1) | ((Rg) & $80)
  *R\AF\B\l = *R\AF\B\l | PZSTable(Rg)
EndMacro

Macro M_SLL(Rg)
  *R\AF\B\l = (Rg) >> 7
  Rg = ((Rg) << 1) | $01
  *R\AF\B\l = *R\AF\B\l | PZSTable(Rg)
EndMacro

Macro M_SRL(Rg)
  *R\AF\B\l = (Rg) & $01
  Rg = (Rg) >> 1
  *R\AF\B\l = *R\AF\B\l | PZSTable(Rg)
EndMacro

Macro M_BIT(Bit, Rg)
  *R\AF\B\l = (*R\AF\B\l & #C_FLAG) | #H_FLAG | PZSTable((Rg) & (1 << (Bit)))
EndMacro

Macro M_SET(Bit, Rg)
  Rg = (Rg) | (1 << (Bit))
EndMacro

Macro M_RES(Bit, Rg)
  Rg = (Rg) & (~(1 << (Bit)))
EndMacro

Macro M_POP(Rg)
  *R\Rg#\B\l = ReadPop(*R)
  *R\Rg#\B\h = ReadPop(*R)
EndMacro

Macro M_PUSH(Rg)
  *R\SP\W - 1 : WrZ80(*R\SP\W, *R\Rg#\B\h)
  *R\SP\W - 1 : WrZ80(*R\SP\W, *R\Rg#\B\l)
EndMacro

Macro M_CALL
  J\B\l = ReadOp(*R)
  J\B\h = ReadOp(*R)
  *R\SP\W - 1 : WrZ80(*R\SP\W, *R\PC\B\h)
  *R\SP\W - 1 : WrZ80(*R\SP\W, *R\PC\B\l)
  *R\PC\W = J\W
  If JumpZ80 : JumpZ80(J\W) : EndIf
EndMacro

Macro M_JP
  J\B\l = ReadOp(*R)
  J\B\h = SafeRdZ80(*R\PC\W)
  *R\PC\W = J\W
  If JumpZ80 : JumpZ80(J\W) : EndIf
EndMacro

Macro M_JR
  *R\PC\W + SignExtend8(SafeRdZ80(*R\PC\W)) + 1
  If JumpZ80 : JumpZ80(*R\PC\W) : EndIf
EndMacro

Macro M_RET
  *R\PC\B\l = ReadPop(*R)
  *R\PC\B\h = ReadPop(*R)
  If JumpZ80 : JumpZ80(*R\PC\W) : EndIf
EndMacro

Macro M_RST(Ad)
  *R\SP\W - 1 : WrZ80(*R\SP\W, *R\PC\B\h)
  *R\SP\W - 1 : WrZ80(*R\SP\W, *R\PC\B\l)
  *R\PC\W = Ad
  If JumpZ80 : JumpZ80(Ad) : EndIf
EndMacro

Macro M_LDWORD(Rg)
  *R\Rg#\B\l = ReadOp(*R)
  *R\Rg#\B\h = ReadOp(*R)
EndMacro

Macro M_ADD(Rg)
  J\W = *R\AF\B\h + (Rg)
  *R\AF\B\l = ZSTable(J\B\l) | J\B\h | ((*R\AF\B\h ! (Rg) ! J\B\l) & #H_FLAG)
  If (~(*R\AF\B\h ! (Rg)) & ((Rg) ! J\B\l) & $80)
    *R\AF\B\l = *R\AF\B\l | #V_FLAG
  EndIf
  *R\AF\B\h = J\B\l
EndMacro

Macro M_SUB(Rg)
  J\W = *R\AF\B\h - (Rg)
  *R\AF\B\l = ZSTable(J\B\l) | #N_FLAG | (J\B\h & #C_FLAG) | ((*R\AF\B\h ! (Rg) ! J\B\l) & #H_FLAG)
  If (((*R\AF\B\h ! (Rg)) & (*R\AF\B\h ! J\B\l) & $80))
    *R\AF\B\l = *R\AF\B\l | #V_FLAG
  EndIf
  *R\AF\B\h = J\B\l
EndMacro

Macro M_ADC(Rg)
  J\W = *R\AF\B\h + (Rg) + (*R\AF\B\l & #C_FLAG)
  *R\AF\B\l = ZSTable(J\B\l) | J\B\h | ((*R\AF\B\h ! (Rg) ! J\B\l) & #H_FLAG)
  If (~(*R\AF\B\h ! (Rg)) & ((Rg) ! J\B\l) & $80)
    *R\AF\B\l = *R\AF\B\l | #V_FLAG
  EndIf
  *R\AF\B\h = J\B\l
EndMacro

Macro M_SBC(Rg)
  J\W = *R\AF\B\h - (Rg) - (*R\AF\B\l & #C_FLAG)
  *R\AF\B\l = ZSTable(J\B\l) | #N_FLAG | (J\B\h & #C_FLAG) | ((*R\AF\B\h ! (Rg) ! J\B\l) & #H_FLAG)
  If (((*R\AF\B\h ! (Rg)) & (*R\AF\B\h ! J\B\l) & $80))
    *R\AF\B\l = *R\AF\B\l | #V_FLAG
  EndIf
  *R\AF\B\h = J\B\l
EndMacro

Macro M_CP(Rg)
  J\W = *R\AF\B\h - (Rg)
  *R\AF\B\l = ZSTable(J\B\l) | #N_FLAG | (J\B\h & #C_FLAG) | ((*R\AF\B\h ! (Rg) ! J\B\l) & #H_FLAG)
  If (((*R\AF\B\h ! (Rg)) & (*R\AF\B\h ! J\B\l) & $80))
    *R\AF\B\l = *R\AF\B\l | #V_FLAG
  EndIf
EndMacro

Macro M_AND(Rg)
  *R\AF\B\h = *R\AF\B\h & (Rg)
  *R\AF\B\l = #H_FLAG | PZSTable(*R\AF\B\h)
EndMacro

Macro M_OR(Rg)
  *R\AF\B\h = *R\AF\B\h | (Rg)
  *R\AF\B\l = PZSTable(*R\AF\B\h)
EndMacro

Macro M_XOR(Rg)
  *R\AF\B\h = *R\AF\B\h ! (Rg)
  *R\AF\B\l = PZSTable(*R\AF\B\h)
EndMacro

Macro M_IN(Rg)
  Rg = InZ80(*R\BC\W)
  *R\AF\B\l = PZSTable(Rg) | (*R\AF\B\l & #C_FLAG)
EndMacro

Macro M_INC(Rg)
  Rg + 1
  *R\AF\B\l = (*R\AF\B\l & #C_FLAG) | ZSTable(Rg)
  If Rg = $80
    *R\AF\B\l = *R\AF\B\l | #V_FLAG
  EndIf
  If (Rg & $0F) = 0
    *R\AF\B\l = *R\AF\B\l | #H_FLAG
  EndIf
EndMacro

Macro M_DEC(Rg)
  Rg - 1
  *R\AF\B\l = #N_FLAG | (*R\AF\B\l & #C_FLAG) | ZSTable(Rg)
  If Rg = $7F
    *R\AF\B\l = *R\AF\B\l | #V_FLAG
  EndIf
  If (Rg & $0F) = $0F
    *R\AF\B\l = *R\AF\B\l | #H_FLAG
  EndIf
EndMacro

Macro M_ADDW(Rg1, Rg2)
  J\W = (*R\Rg1#\W + *R\Rg2#\W) & $FFFF
  *R\AF\B\l = *R\AF\B\l & ~(#H_FLAG | #N_FLAG | #C_FLAG)
  If ((*R\Rg1#\W ! *R\Rg2#\W ! J\W) & $1000)
    *R\AF\B\l = *R\AF\B\l | #H_FLAG
  EndIf
  If (*R\Rg1#\W + *R\Rg2#\W) > $FFFF
    *R\AF\B\l = *R\AF\B\l | #C_FLAG
  EndIf
  *R\Rg1#\W = J\W
EndMacro

Macro M_ADCW(Rg)
  I = *R\AF\B\l & #C_FLAG
  J\W = (*R\HL\W + *R\Rg#\W + I) & $FFFF
  *R\AF\B\l = 0
  If (*R\HL\W + *R\Rg#\W + I) > $FFFF
    *R\AF\B\l = *R\AF\B\l | #C_FLAG
  EndIf
  If (~(*R\HL\W ! *R\Rg#\W) & (*R\Rg#\W ! J\W) & $8000)
    *R\AF\B\l = *R\AF\B\l | #V_FLAG
  EndIf
  If ((*R\HL\W ! *R\Rg#\W ! J\W) & $1000)
    *R\AF\B\l = *R\AF\B\l | #H_FLAG
  EndIf
  If J\W = 0
    *R\AF\B\l = *R\AF\B\l | #Z_FLAG
  EndIf
  *R\AF\B\l = *R\AF\B\l | (J\B\h & #S_FLAG)
  *R\HL\W = J\W
EndMacro

Macro M_SBCW(Rg)
  I = *R\AF\B\l & #C_FLAG
  J\W = (*R\HL\W - *R\Rg#\W - I) & $FFFF
  *R\AF\B\l = #N_FLAG
  If (*R\HL\W - *R\Rg#\W - I) < 0
    *R\AF\B\l = *R\AF\B\l | #C_FLAG
  EndIf
  If ((*R\HL\W ! *R\Rg#\W) & (*R\HL\W ! J\W) & $8000)
    *R\AF\B\l = *R\AF\B\l | #V_FLAG
  EndIf
  If ((*R\HL\W ! *R\Rg#\W ! J\W) & $1000)
    *R\AF\B\l = *R\AF\B\l | #H_FLAG
  EndIf
  If J\W = 0
    *R\AF\B\l = *R\AF\B\l | #Z_FLAG
  EndIf
  *R\AF\B\l = *R\AF\B\l | (J\B\h & #S_FLAG)
  *R\HL\W = J\W
EndMacro

; --- Prefix Opcode Decoders ---

Procedure CodesCB(*R.Z80)
  Protected I.a
  I = ReadOp(*R)
  *R\ICount - CyclesCB(I)
  INCR(1)
  Select I
    IncludeFile "Z80_CodesCB.pbi"
    Default:
      If *R\TrapBadOps
        Debug "Unrecognized instruction: CB " + Hex(I) + " at PC=" + Hex(*R\PC\W)
      EndIf
  EndSelect
EndProcedure

Procedure CodesDDCB(*R.Z80)
  Protected J.RegisterPair
  Protected I.a
  J\W = *R\IX\W + SignExtend8(ReadOp(*R))
  I = ReadOp(*R)
  *R\ICount - CyclesXXCB(I)
  Select I
    IncludeFile "Z80_CodesXCB.pbi"
    Default:
      If *R\TrapBadOps
        Debug "Unrecognized instruction: DD CB " + Hex(I) + " at PC=" + Hex(*R\PC\W)
      EndIf
  EndSelect
EndProcedure

Procedure CodesFDCB(*R.Z80)
  Protected J.RegisterPair
  Protected I.a
  J\W = *R\IY\W + SignExtend8(ReadOp(*R))
  I = ReadOp(*R)
  *R\ICount - CyclesXXCB(I)
  Select I
    IncludeFile "Z80_CodesXCB.pbi"
    Default:
      If *R\TrapBadOps
        Debug "Unrecognized instruction: FD CB " + Hex(I) + " at PC=" + Hex(*R\PC\W)
      EndIf
  EndSelect
EndProcedure

Procedure CodesED(*R.Z80)
  Protected I.a
  Protected J.RegisterPair
  I = ReadOp(*R)
  *R\ICount - CyclesED(I)
  INCR(1)
  Select I
    IncludeFile "Z80_CodesED.pbi"
    Case $ED : *R\PC\W - 1
    Default:
      If *R\TrapBadOps
        Debug "Unrecognized instruction: ED " + Hex(I) + " at PC=" + Hex(*R\PC\W)
      EndIf
  EndSelect
EndProcedure

Procedure CodesDD(*R.Z80)
  Protected I.a
  Protected J.RegisterPair
  *R\XX\W = *R\IX\W
  I = ReadOp(*R)
  *R\ICount - CyclesXX(I)
  INCR(1)
  Select I
    IncludeFile "Z80_CodesXX.pbi"
    Case $FD, $DD : *R\PC\W - 1
    Case $CB : CodesDDCB(*R)
    Default:
      If *R\TrapBadOps
        Debug "Unrecognized instruction: DD " + Hex(I) + " at PC=" + Hex(*R\PC\W)
      EndIf
  EndSelect
  *R\IX\W = *R\XX\W
EndProcedure

Procedure CodesFD(*R.Z80)
  Protected I.a
  Protected J.RegisterPair
  *R\XX\W = *R\IY\W
  I = ReadOp(*R)
  *R\ICount - CyclesXX(I)
  INCR(1)
  Select I
    IncludeFile "Z80_CodesXX.pbi"
    Case $FD, $DD : *R\PC\W - 1
    Case $CB : CodesFDCB(*R)
    Default:
      If *R\TrapBadOps
        Debug "Unrecognized instruction: FD " + Hex(I) + " at PC=" + Hex(*R\PC\W)
      EndIf
  EndSelect
  *R\IY\W = *R\XX\W
EndProcedure

; --- Public CPU API Functions ---

; Reset the CPU state
Procedure ResetZ80(*R.Z80)
  *R\PC\W     = $0000
  *R\SP\W     = $F000
  *R\AF\W     = $0000
  *R\BC\W     = $0000
  *R\DE\W     = $0000
  *R\HL\W     = $0000
  *R\AF1\W    = $0000
  *R\BC1\W    = $0000
  *R\DE1\W    = $0000
  *R\HL1\W    = $0000
  *R\IX\W     = $0000
  *R\IY\W     = $0000
  *R\I        = $00
  *R\R        = $00
  *R\IFF      = $00
  *R\ICount   = *R\IPeriod
  *R\IRequest = #INT_NONE
  *R\IBackup  = 0
  
  If JumpZ80 : JumpZ80(*R\PC\W) : EndIf
EndProcedure

; Trigger an Interrupt
Procedure IntZ80(*R.Z80, Vector.u)
  If *R\IFF & #IFF_HALT
    *R\PC\W + 1
    *R\IFF = *R\IFF & ~#IFF_HALT
  EndIf

  If (*R\IFF & #IFF_1) Or (Vector = #INT_NMI)
    Protected J.RegisterPair
    J\W = *R\PC\W
    *R\SP\W - 1 : WrZ80(*R\SP\W, J\B\h)
    *R\SP\W - 1 : WrZ80(*R\SP\W, J\B\l)
    
    If *R\IAutoReset And (Vector = *R\IRequest)
      *R\IRequest = #INT_NONE
    EndIf
    
    If Vector = #INT_NMI
      *R\IFF = *R\IFF & ~(#IFF_1 | #IFF_EI)
      *R\PC\W = $0066
      If JumpZ80 : JumpZ80($0066) : EndIf
      ProcedureReturn
    EndIf
    
    *R\IFF = *R\IFF & ~(#IFF_1 | #IFF_2 | #IFF_EI)
    
    If *R\IFF & #IFF_IM2
      Vector = (Vector & $FF) | (*R\I << 8)
      *R\PC\B\l = SafeRdZ80(Vector) : Vector + 1
      *R\PC\B\h = SafeRdZ80(Vector)
      If JumpZ80 : JumpZ80(*R\PC\W) : EndIf
      ProcedureReturn
    EndIf
    
    If *R\IFF & #IFF_IM1
      *R\PC\W = $0038
      If JumpZ80 : JumpZ80($0038) : EndIf
      ProcedureReturn
    EndIf
    
    Select Vector
      Case #INT_RST00 : *R\PC\W = $0000 : If JumpZ80 : JumpZ80($0000) : EndIf
      Case #INT_RST08 : *R\PC\W = $0008 : If JumpZ80 : JumpZ80($0008) : EndIf
      Case #INT_RST10 : *R\PC\W = $0010 : If JumpZ80 : JumpZ80($0010) : EndIf
      Case #INT_RST18 : *R\PC\W = $0018 : If JumpZ80 : JumpZ80($0018) : EndIf
      Case #INT_RST20 : *R\PC\W = $0020 : If JumpZ80 : JumpZ80($0020) : EndIf
      Case #INT_RST28 : *R\PC\W = $0028 : If JumpZ80 : JumpZ80($0028) : EndIf
      Case #INT_RST30 : *R\PC\W = $0030 : If JumpZ80 : JumpZ80($0030) : EndIf
      Case #INT_RST38 : *R\PC\W = $0038 : If JumpZ80 : JumpZ80($0038) : EndIf
    EndSelect
  EndIf
EndProcedure

; Run the CPU emulation loop
Procedure.u RunZ80(*R.Z80)
  Protected I.a
  Protected J.RegisterPair

  Repeat
    If Not RealRdZ80 : LogCPU("CRITICAL: RdZ80 NULL at top of RunZ80 loop, PC=$" + Hex(*R\PC\W)) : End : EndIf

    ; Reset watch: keep a rolling ring of the last #PCRingSize PCs (cheap, no I/O), and
    ; dump it the moment PC hits $0000 (the reset vector) - see the ring's declaration
    ; above for why. Edge-triggered (PCRingWasZero) so a genuine multi-instruction stay
    ; at PC=0 doesn't spam one dump per instruction.
    PCRing(PCRingPos) = *R\PC\W
    PCRingPos = (PCRingPos + 1) % #PCRingSize
    If *R\PC\W = 0
      If Not PCRingWasZero And PCRingDumps < #PCRingMaxDumps
        PCRingDumps + 1
        Protected RingMsg.s = "TRACE: PC=0000 (RESET) #" + Str(PCRingDumps) + " - last " + Str(#PCRingSize) +
                               " PCs before it (oldest first):"
        Protected k.i
        For k = 0 To #PCRingSize - 1
          RingMsg + " " + Hex(PCRing((PCRingPos + k) % #PCRingSize))
        Next k
        LogCPU(RingMsg)
      EndIf
      PCRingWasZero = 1
    Else
      PCRingWasZero = 0
    EndIf

    ; Instruction trace: ENTER/LEAVE markers whenever PC crosses into/out of the
    ; cartridge window ($4000-$7FFF), plus a full per-instruction PC trace while inside
    ; (capped per continuous visit so a game that legitimately runs there doesn't flood
    ; fossauro.log - the ENTER/LEAVE markers themselves are never suppressed). This is
    ; what answers "does the cartridge ever run, and where does control go if it gives
    ; it back to the BIOS" - see docs/SPEC.md module 32b / README changelog.
    Protected NowInCart.b = Bool(*R\PC\W >= $4000 And *R\PC\W < $8000)
    If NowInCart <> TraceWasInCart
      If NowInCart
        LogCPU("TRACE ENTER cartridge PC=$" + Hex(*R\PC\W) + " SP=$" + Hex(*R\SP\W))
        TraceActive = 1
        TraceInstrInVisit = 0
      Else
        LogCPU("TRACE LEAVE cartridge PC=$" + Hex(*R\PC\W) + " SP=$" + Hex(*R\SP\W))
        TraceActive = 0
      EndIf
      TraceWasInCart = NowInCart
    EndIf
    If TraceActive
      If TraceInstrInVisit < #TraceMaxInstrPerVisit
        LogCPU("TRACE PC=$" + Hex(*R\PC\W))
      ElseIf TraceInstrInVisit = #TraceMaxInstrPerVisit
        LogCPU("TRACE ... suppressing per-instruction trace past " + Str(#TraceMaxInstrPerVisit) +
               " instructions this visit, still in cartridge, PC=$" + Hex(*R\PC\W) +
               " (LEAVE marker above still fires when it exits)")
      EndIf
      TraceInstrInVisit + 1
    EndIf

    If *R\PC\W = $7D0D
      LogCPU("DIAG: PC=$7D0D HL=$" + Hex(*R\HL\W) + " A=$" + Hex(*R\AF\B\h) + " F=$" + Hex(*R\AF\B\l))
    EndIf

    I = ReadOp(*R)
    *R\ICount - Cycles(I)
    INCR(1)
    
    Select I
      Case $CB : CodesCB(*R)
      Case $ED : CodesED(*R)
      Case $DD : CodesDD(*R)
      Case $FD : CodesFD(*R)
      IncludeFile "Z80_Codes.pbi"
    EndSelect
    
    If *R\ICount <= 0
      If *R\IFF & #IFF_EI
        *R\IFF = (*R\IFF & ~#IFF_EI) | #IFF_1
        *R\ICount + *R\IBackup - 1
        
        If *R\ICount > 0
          J\W = *R\IRequest
        Else
          If Not RealRdZ80 : LogCPU("CRITICAL: RdZ80 NULL before LoopZ80 call site 1, PC=$" + Hex(*R\PC\W)) : End : EndIf
          J\W = LoopZ80(*R)
          If Not RealRdZ80 : LogCPU("CRITICAL: RdZ80 NULL after LoopZ80 call site 1, PC=$" + Hex(*R\PC\W)) : End : EndIf
          *R\ICount + *R\IPeriod
          If J\W = #INT_NONE
            J\W = *R\IRequest
          EndIf
        EndIf
      Else
        If Not RealRdZ80 : LogCPU("CRITICAL: RdZ80 NULL before LoopZ80 call site 2, PC=$" + Hex(*R\PC\W)) : End : EndIf
        J\W = LoopZ80(*R)
        If Not RealRdZ80 : LogCPU("CRITICAL: RdZ80 NULL after LoopZ80 call site 2, PC=$" + Hex(*R\PC\W)) : End : EndIf
        *R\ICount + *R\IPeriod
        If J\W = #INT_NONE
          J\W = *R\IRequest
        EndIf
      EndIf
      
      If J\W = #INT_QUIT
        ProcedureReturn *R\PC\W
      EndIf
      If J\W <> #INT_NONE
        IntZ80(*R, J\W)
      EndIf
    EndIf
  ForEver
  
  ProcedureReturn *R\PC\W
EndProcedure
