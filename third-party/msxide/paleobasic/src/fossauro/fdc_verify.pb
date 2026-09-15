; fdc_verify.pb - fossauro WD1793 FDC verification harness
;
; Drives FDC_WriteReg()/FDC_ReadReg() (FDC.pbi) with the EXACT same memory-mapped register sequence
; a real MSX DISK.ROM issues (SIDE select -> DRIVE select -> RESTORE -> SECTOR -> READ/WRITE SECTOR
; -> poll status -> transfer 512 bytes through the DATA register), against a real 720KB .dsk image
; created by the main Paleobasic editor's own --diskmanipulator CLI, and checks the transferred bytes
; byte-for-byte against an independent ReadFile() of the same image - the strongest test available
; without driving the actual GUI/keyboard.
;
; Usage: fdc_verify.exe <disco.dsk>

EnableExplicit

Global ThreadExit.l = 0
Global ThreadPaused.l = 0

XIncludeFile "Z80_Tables.pbi"
XIncludeFile "Z80.pbi"
XIncludeFile "MSX.pbi" ; pulls in FDC.pbi

Procedure.s HexByte(v.a)
  ProcedureReturn "$" + Hex(v, #PB_Byte)
EndProcedure

Procedure ReadSectorViaFDC(Track.l, Side.l, Sector.l, *OutBuf, *StatusOut.Byte)
  FDC_WriteReg($7FFC, Side)
  FDC_WriteReg($7FFD, 1)            ; select drive A
  FDC_WriteReg($7FF8, $00)          ; RESTORE -> Track=0
  FDC_WriteReg($7FFB, Track & $FF)  ; stage target track into DATA (FDC.pbi's SEEK reads FDC\Data)
  FDC_WriteReg($7FF8, $10)          ; SEEK
  FDC_WriteReg($7FFA, Sector & $FF)
  FDC_WriteReg($7FF8, $80)          ; READ SECTOR

  Protected i.l, status.a
  For i = 0 To 511
    status = FDC_ReadReg($7FF8)
    If (status & $02) = 0
      *StatusOut\b = status
      ProcedureReturn i ; short transfer - report how many bytes actually came through
    EndIf
    PokeA(*OutBuf + i, FDC_ReadReg($7FFB))
  Next i
  *StatusOut\b = FDC_ReadReg($7FF8)
  ProcedureReturn 512
EndProcedure

Procedure WriteSectorViaFDC(Track.l, Side.l, Sector.l, *InBuf, *StatusOut.Byte)
  FDC_WriteReg($7FFC, Side)
  FDC_WriteReg($7FFD, 1)
  FDC_WriteReg($7FF8, $00)          ; RESTORE
  FDC_WriteReg($7FFB, Track & $FF)
  FDC_WriteReg($7FF8, $10)          ; SEEK
  FDC_WriteReg($7FFA, Sector & $FF)
  FDC_WriteReg($7FF8, $A0)          ; WRITE SECTOR

  Protected i.l
  For i = 0 To 511
    FDC_WriteReg($7FFB, PeekA(*InBuf + i))
  Next i
  *StatusOut\b = FDC_ReadReg($7FF8)
EndProcedure

Procedure Main()
  OpenConsole("fossauro FDC Verification")
  If CountProgramParameters() < 1
    PrintN("Uso: fdc_verify.exe <disco.dsk>")
    Input() : CloseConsole() : ProcedureReturn
  EndIf
  Protected diskPath.s = ProgramParameter(0)

  InitZ80Tables()
  InitializeMSXMemory()
  FDC_Reset()

  PrintN("=== Teste 1: disco nao montado -> status Not Ready ===")
  Protected buf.i = AllocateMemory(512)
  Protected st.a
  Protected got.l = ReadSectorViaFDC(0, 0, 1, buf, @st)
  PrintN("Bytes transferidos=" + Str(got) + " status final=" + HexByte(st) + " (esperado: 0 bytes, bit7 setado)")

  PrintN("")
  PrintN("=== Montando " + diskPath + " ===")
  If Not FDC_MountDisk(0, diskPath)
    PrintN("FALHA ao montar disco")
    Input() : CloseConsole() : ProcedureReturn
  EndIf
  PrintN("OK, tamanho=" + Str(FDCDrive(0)\Size) + " bytes")

  PrintN("")
  PrintN("=== Teste 2: ler trilha 0 lado 0 setor 1 (boot sector) via FDC, comparar com o arquivo real ===")
  got = ReadSectorViaFDC(0, 0, 1, buf, @st)
  Protected refFile.i = ReadFile(#PB_Any, diskPath)
  Protected refBuf.i = AllocateMemory(512)
  ReadData(refFile, refBuf, 512)
  CloseFile(refFile)
  Protected match.l = CompareMemory(buf, refBuf, 512)
  PrintN("Bytes transferidos=" + Str(got) + " status final=" + HexByte(st) + " (esperado: 512, bit0-1 sem erro)")
  PrintN("Conteudo bate byte-a-byte com o arquivo real? " + Bool(match) + " (1=sim)")
  PrintN("Primeiros bytes lidos: " + HexByte(PeekA(buf+0)) + " " + HexByte(PeekA(buf+1)) + " " + HexByte(PeekA(buf+2)) +
         " (esperado assinatura de boot sector MSX-DOS, normalmente $EB $FE/$3C ou $E9 ...)")

  PrintN("")
  PrintN("=== Teste 3: ler um setor claramente fora do disco -> Record Not Found ===")
  got = ReadSectorViaFDC(200, 1, 9, buf, @st)
  PrintN("Bytes transferidos=" + Str(got) + " status final=" + HexByte(st) + " (esperado: 0 bytes, bit4 setado = $10)")

  PrintN("")
  PrintN("=== Teste 4: escrever um setor de teste (trilha 10, lado 0, setor 3) e reler ===")
  Protected wbuf.i = AllocateMemory(512)
  Protected i.l
  For i = 0 To 511
    PokeA(wbuf + i, i & $FF)
  Next i
  WriteSectorViaFDC(10, 0, 3, wbuf, @st)
  PrintN("Status apos escrita=" + HexByte(st))
  got = ReadSectorViaFDC(10, 0, 3, buf, @st)
  match = CompareMemory(buf, wbuf, 512)
  PrintN("Releitura bate com o que foi escrito? " + Bool(match) + " (1=sim), status=" + HexByte(st))

  PrintN("")
  PrintN("Pressione Enter para sair...")
  Input()
  CloseConsole()
EndProcedure

Main()
