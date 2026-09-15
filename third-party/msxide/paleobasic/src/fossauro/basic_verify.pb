; basic_verify.pb - Headless boot verification for fossauro
EnableExplicit

Global ThreadExit.l = 0
Global ThreadPaused.l = 0
Global CustomFrameCounter.l = 0

; Include emulation modules
XIncludeFile "Z80_Tables.pbi"
XIncludeFile "Z80.pbi"
XIncludeFile "MSX.pbi"

; Custom loop callback to terminate after 300 frames
Procedure.u MyLoopZ80(*R.Z80)
  Protected res.u = MSXLoopZ80(*R)
  If FramePending = 1
    FramePending = 0 ; Clear the pending frame flag so we can detect the next one
    CustomFrameCounter + 1
  EndIf
  If CustomFrameCounter >= 300
    ProcedureReturn #INT_QUIT
  EndIf
  ProcedureReturn res
EndProcedure

Procedure VerifyBasic()
  OpenConsole("fossauro BASIC Boot Verification")
  PrintN("Initializing emulation state...")
  InitZ80Tables()
  InitializeMSXMemory()
  
  RealRdZ80 = @MSXRdZ80()
  WrZ80 = @MSXWrZ80()
  InZ80 = @MSXInZ80()
  OutZ80 = @MSXOutZ80()
  LoopZ80 = @MyLoopZ80()
  
  PrintN("Loading BIOS ROM...")
  If Not MSXLoadBIOS("roms/MSX.ROM")
    PrintN("ERROR: Failed to load roms/MSX.ROM")
    End
  EndIf
  
  PrintN("Resetting hardware...")
  ResetZ80(@CPU)
  ResetVDP()
  ResetPSG()
  
  PrintN("Running emulation for 300 frames (approx. 5 seconds)...")
  RunZ80(@CPU)
  PrintN("Emulation finished.")
  PrintN("Last PC: $" + Hex(CPU\PC\W))
  PrintN("Last SP: $" + Hex(CPU\SP\W))
  PrintN("Custom Frame Count: " + Str(CustomFrameCounter))
  
  Protected vram_non_zero.l = 0
  Protected idx_vram.l
  For idx_vram = 0 To $20000 - 1
    If PeekA(*VRAM + idx_vram) <> 0
      vram_non_zero + 1
    EndIf
  Next
  PrintN("VRAM Non-Zero Bytes: " + Str(vram_non_zero))
  
  PrintN("ChrTab Offset: $" + Hex(ChrTab - *VRAM))
  PrintN("ChrGen Offset: $" + Hex(ChrGen - *VRAM))
  PrintN("ColTab Offset: $" + Hex(ColTab - *VRAM))
  PrintN("ScrMode: " + Str(ScrMode))
  
  Protected name_table_non_zero.l = 0
  Protected spaces.l = 0
  Protected others.l = 0
  For idx_vram = $1800 To $1AFF
    Protected ch.a = PeekA(*VRAM + idx_vram)
    If ch <> 0
      name_table_non_zero + 1
      If ch = 32
        spaces + 1
      Else
        others + 1
      EndIf
    EndIf
  Next
  PrintN("Name Table Non-Zero Bytes: " + Str(name_table_non_zero))
  PrintN("Name Table spaces: " + Str(spaces) + ", others: " + Str(others))
  
  PrintN("Byte at $FD9A (HTIMI): $" + Hex(SafeRdZ80($FD9A)))
  PrintN("Bytes at $0038: $" + Hex(SafeRdZ80($0038)) + " $" + Hex(SafeRdZ80($0039)) + " $" + Hex(SafeRdZ80($003A)))
  
  PrintN("PSLReg: $" + Hex(PSLReg))
  Protected idx_p.l
  For idx_p = 0 To 3
    PrintN("Page " + Str(idx_p) + ": PSL=" + Str(PSL(idx_p)) + " SSL=" + Str(SSL(idx_p)) + " ptr0=" + Str(*RAM(idx_p*2)) + " ptr1=" + Str(*RAM(idx_p*2+1)))
  Next idx_p
  
  CloseConsole()
EndProcedure

VerifyBasic()
