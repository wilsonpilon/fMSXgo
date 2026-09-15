; WD1793/FD1793 Floppy Disk Controller emulation for fossauro
;
; Real MSX hardware wires the FDC's 4 native registers plus 2 glue-logic control registers as
; MEMORY-MAPPED locations (not Z80 IN/OUT ports) at $7FF8-$7FFD, visible only while Primary Slot 3/
; Secondary Slot 1 is paged into CPU page 1 ($4000-$7FFF) - see MSXRdZ80/MSXWrZ80 (MSX.pbi), which
; already filter this exact address pattern. Port map confirmed empirically (2026-08-18) by scanning
; the real fMSX/DISK.ROM binary for every "LD A,(nn)"/"LD (nn),A" referencing $7FF0-$7FFF, then
; manually disassembling the surrounding bytes - not guessed from memory, since a real MSX board's
; exact glue-register bit layout is not part of the WD1793 chip's own (well-documented) spec:
;   $7FF8: STATUS (read) / COMMAND (write)     - WD1793 register 0
;   $7FF9: TRACK (read/write)                  - WD1793 register 1
;   $7FFA: SECTOR (read/write)                 - WD1793 register 2 (confirmed: driver does
;                                                 "LD A,L : INC A : LD (7FFA),A", i.e. writes a
;                                                 1-based sector number derived from a 0-based L)
;   $7FFB: DATA (read/write)                   - WD1793 register 3
;   $7FFC: SIDE select (write-only, bit0)      - confirmed: driver only ever writes 0 or 1 here,
;                                                 computed from a side-parity calculation
;   $7FFD: DRIVE/MOTOR control (write-only)    - confirmed: driver ORs a drive-dependent value
;                                                 with $C4 before writing; bit0/bit1 read here as
;                                                 drive A/B select (the functionally important part
;                                                 for routing to the right FDCDrive() - the other
;                                                 fixed bits in $C4 are motor/density-related and not
;                                                 modeled, matching this project's "commands complete
;                                                 instantly" approach already used for the VDP engine)
;
; Commands complete SYNCHRONOUSLY (no real seek/rotation timing) - same simplification already
; applied to V9938.pbi's VDPDraw() command engine. Disk images are plain raw sector dumps (no FAT12
; awareness needed at this layer - editor/MSXDisk.pbi in the main Paleobasic project handles that one
; layer up); standard MSX layout is 512 bytes/sector, 9 sectors/track, tracks interleaved by side:
;   LBA = (Track * 2 + Side) * 9 + (Sector - 1)
; matching every real MSX .dsk image in practice (180KB/360KB/720KB all use 9 sectors/track).

EnableExplicit

Structure FDCDriveState
  *Data
  Size.q
  Mounted.b
  ReadOnly.b
  Path.s
EndStructure

Structure FDCState
  Status.a
  Track.a
  Sector.a
  Data.a          ; DATA register latch (also used to stage the target track before a SEEK command)
  Side.a          ; from $7FFC, bit0
  DriveSel.l       ; -1 = none selected, 0 = drive A, 1 = drive B (from $7FFD bits0/1)
  XferActive.b
  XferWrite.b     ; 1 = WRITE SECTOR in progress (flushed to the disk image on completion)
  XferPos.w
  XferLen.w
  XferBuf.a[511]
EndStructure

Global FDC.FDCState
Global Dim FDCDrive.FDCDriveState(1) ; 0 = drive A, 1 = drive B

Procedure FDC_Reset()
  FDC\Status = 0 : FDC\Track = 0 : FDC\Sector = 1 : FDC\Data = 0
  FDC\Side = 0 : FDC\DriveSel = -1
  FDC\XferActive = 0 : FDC\XferWrite = 0 : FDC\XferPos = 0 : FDC\XferLen = 0
EndProcedure

Procedure.l FDC_MountDisk(Drive.l, FileName.s)
  If Drive < 0 Or Drive > 1 : ProcedureReturn #False : EndIf
  If FDCDrive(Drive)\Data : FreeMemory(FDCDrive(Drive)\Data) : FDCDrive(Drive)\Data = 0 : EndIf
  FDCDrive(Drive)\Mounted = 0

  Protected f.i = ReadFile(#PB_Any, FileName)
  If Not f
    ProcedureReturn #False
  EndIf
  Protected sz.q = Lof(f)
  FDCDrive(Drive)\Data = AllocateMemory(sz)
  If Not FDCDrive(Drive)\Data
    CloseFile(f)
    ProcedureReturn #False
  EndIf
  ReadData(f, FDCDrive(Drive)\Data, sz)
  CloseFile(f)

  FDCDrive(Drive)\Size = sz
  FDCDrive(Drive)\Path = FileName
  FDCDrive(Drive)\ReadOnly = 0
  FDCDrive(Drive)\Mounted = 1
  ProcedureReturn #True
EndProcedure

Procedure FDC_EjectDisk(Drive.l)
  If Drive < 0 Or Drive > 1 : ProcedureReturn : EndIf
  If FDCDrive(Drive)\Data : FreeMemory(FDCDrive(Drive)\Data) : FDCDrive(Drive)\Data = 0 : EndIf
  FDCDrive(Drive)\Mounted = 0
  FDCDrive(Drive)\Path = ""
EndProcedure

Procedure.q FDC_SectorOffset(Track.l, Side.l, Sector.l)
  ProcedureReturn ((Track * 2 + Side) * 9 + (Sector - 1)) * 512
EndProcedure

Procedure FDC_DoCommand(Cmd.a)
  FDC\XferActive = 0

  Protected *Drv.FDCDriveState
  If FDC\DriveSel >= 0 And FDC\DriveSel <= 1
    *Drv = @FDCDrive(FDC\DriveSel)
  EndIf
  Protected ready.b = Bool(*Drv <> 0 And *Drv\Mounted)

  Protected typeBits.a = (Cmd >> 4) & $0F
  Protected off.q

  Select typeBits
    Case $0 ; RESTORE - home the head to track 0
      FDC\Track = 0
      FDC\Status = $00
      If Not ready : FDC\Status = $80 : Else : FDC\Status = $04 : EndIf ; bit2 = TRACK00

    Case $1 ; SEEK - target track was staged into the DATA register beforehand
      FDC\Track = FDC\Data
      FDC\Status = 0
      If Not ready
        FDC\Status = $80
      ElseIf FDC\Track = 0
        FDC\Status = $04
      EndIf

    Case $2, $3 ; STEP (no direction tracking needed - MSX-DOS always follows with RESTORE/SEEK)
      FDC\Status = 0
      If Not ready : FDC\Status = $80 : EndIf

    Case $4, $5 ; STEP IN
      If FDC\Track < 255 : FDC\Track + 1 : EndIf
      FDC\Status = 0
      If Not ready : FDC\Status = $80 : EndIf

    Case $6, $7 ; STEP OUT
      If FDC\Track > 0 : FDC\Track - 1 : EndIf
      FDC\Status = 0
      If Not ready
        FDC\Status = $80
      ElseIf FDC\Track = 0
        FDC\Status = $04
      EndIf

    Case $8, $9 ; READ SECTOR
      If Not ready
        FDC\Status = $80
      Else
        off = FDC_SectorOffset(FDC\Track, FDC\Side, FDC\Sector)
        If off < 0 Or off + 512 > *Drv\Size
          FDC\Status = $10 ; Record Not Found
        Else
          CopyMemory(*Drv\Data + off, @FDC\XferBuf[0], 512)
          FDC\XferActive = 1 : FDC\XferWrite = 0 : FDC\XferPos = 0 : FDC\XferLen = 512
          FDC\Status = $02 ; DRQ
        EndIf
      EndIf

    Case $A, $B ; WRITE SECTOR
      If Not ready
        FDC\Status = $80
      Else
        off = FDC_SectorOffset(FDC\Track, FDC\Side, FDC\Sector)
        If off < 0 Or off + 512 > *Drv\Size
          FDC\Status = $10
        Else
          FDC\XferActive = 1 : FDC\XferWrite = 1 : FDC\XferPos = 0 : FDC\XferLen = 512
          FDC\Status = $02
        EndIf
      EndIf

    Case $C ; READ ADDRESS - Track/Side/Sector/length-code/CRC(2, unchecked)
      If Not ready
        FDC\Status = $80
      Else
        FDC\XferBuf[0] = FDC\Track : FDC\XferBuf[1] = FDC\Side : FDC\XferBuf[2] = FDC\Sector
        FDC\XferBuf[3] = 2 : FDC\XferBuf[4] = 0 : FDC\XferBuf[5] = 0
        FDC\XferActive = 1 : FDC\XferWrite = 0 : FDC\XferPos = 0 : FDC\XferLen = 6
        FDC\Status = $02
      EndIf

    Default ; $D FORCE INTERRUPT terminates any pending command (handled by the XferActive=0 above);
            ; $E/$F (READ TRACK/WRITE TRACK, raw-track/format support) are not implemented - report
            ; a clean error instead of silently doing nothing, so a caller relying on them fails
            ; fast rather than hangs.
      FDC\Status = 0
      If Not ready : FDC\Status = $80 : EndIf
      If typeBits = $E Or typeBits = $F : FDC\Status = $10 : EndIf
  EndSelect
EndProcedure

Procedure.a FDC_ReadReg(A.u)
  Select A & $0F
    Case 8 ; STATUS
      Protected s.a = FDC\Status
      If FDC\XferActive And FDC\XferPos < FDC\XferLen
        s | $02
      EndIf
      ProcedureReturn s

    Case 9
      ProcedureReturn FDC\Track

    Case 10
      ProcedureReturn FDC\Sector

    Case 11 ; DATA
      If FDC\XferActive And Not FDC\XferWrite And FDC\XferPos < FDC\XferLen
        Protected v.a = FDC\XferBuf[FDC\XferPos]
        FDC\XferPos + 1
        If FDC\XferPos >= FDC\XferLen : FDC\XferActive = 0 : EndIf
        ProcedureReturn v
      EndIf
      ProcedureReturn FDC\Data

    Default
      ProcedureReturn $FF
  EndSelect
EndProcedure

Procedure FDC_WriteReg(A.u, V.a)
  Select A & $0F
    Case 8 ; COMMAND
      FDC_DoCommand(V)

    Case 9
      FDC\Track = V

    Case 10
      FDC\Sector = V

    Case 11 ; DATA
      If FDC\XferActive And FDC\XferWrite And FDC\XferPos < FDC\XferLen
        FDC\XferBuf[FDC\XferPos] = V
        FDC\XferPos + 1
        If FDC\XferPos >= FDC\XferLen
          FDC\XferActive = 0
          Protected *Drv.FDCDriveState
          If FDC\DriveSel >= 0 And FDC\DriveSel <= 1 : *Drv = @FDCDrive(FDC\DriveSel) : EndIf
          If *Drv And *Drv\Mounted And Not *Drv\ReadOnly
            Protected off.q = FDC_SectorOffset(FDC\Track, FDC\Side, FDC\Sector)
            If off >= 0 And off + FDC\XferLen <= *Drv\Size
              CopyMemory(@FDC\XferBuf[0], *Drv\Data + off, FDC\XferLen)
            EndIf
          EndIf
        EndIf
      Else
        FDC\Data = V
      EndIf

    Case 12 ; SIDE select
      FDC\Side = V & 1

    Case 13 ; DRIVE/MOTOR control - bit0 = drive A, bit1 = drive B, other bits (motor/density,
            ; always $C4 in this DISK.ROM's writes) not modeled, matching the "instant command"
            ; simplification used throughout this port.
      If V & 1
        FDC\DriveSel = 0
      ElseIf V & 2
        FDC\DriveSel = 1
      Else
        FDC\DriveSel = -1
      EndIf
  EndSelect
EndProcedure
