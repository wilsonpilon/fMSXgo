; *************************************************************
; **                                                         **
; **                MSXDisk.pbi                              **
; **                                                         **
; ** PureBasic Include Module for MSX Disk Image Management  **
; **                                                         **
; ** Re-implemented from Arnold Metselaar's C tools          **
; ** Separates file system logic from CLI/GUI interfaces.     **
; **                                                         **
; *************************************************************

DeclareModule MSXDisk
  Structure DirEntry
    d_fname.b[8]
    d_ext.b[3]
    d_attrib.b
    d_reserv.b[10]
    d_time.u
    d_date.u
    d_first.u
    d_size.l
  EndStructure

  Structure FileInfo
    FileName.s
    Size.l
    DateTime.i
    Attrib.b
    FirstCluster.u
  EndStructure

  Declare.i CreateDisk(DiskPath$, BootSectorPath$ = "")
  Declare.i OpenDisk(DiskPath$)
  Declare.i CloseDisk()
  Declare.i ListFiles(List FilesOut.FileInfo())
  Declare.i ExtractFile(MSXName$, DestPath$)
  Declare.i AddFile(LocalPath$, MSXName$ = "")
  Declare.i DeleteMSXFile(MSXName$)
  Declare.s GetLastErrorMessage()
  
  ; Utility functions exposed for helpers/external testing
  Declare.s ConvertToFAT11(Arg$)
  Declare.i MatchesFAT11(FAT11_Entry$, FAT11_Mask$)
EndDeclareModule

Module MSXDisk
  Structure DirEntryArray
    Entry.DirEntry[0]
  EndStructure

  ; State variables
  Global DiskFile.i = 0
  Global DiskPath$ = ""
  Global Dim BootBlock.b(511)
  Global *FAT = 0
  Global FAT_len.l = 0
  Global *DIR = 0
  Global DIR_len.l = 0
  Global ndir.u = 0
  Global dir_ofs.l = 0
  Global data_ofs.l = 0
  Global clus_len.l = 0
  Global maxcl.u = 0
  Global LastError$ = ""

  ; Default MSX Boot Sector (512 bytes)
  DataSection
    DefaultBootBlock:
    Data.b $EB,$FE,$90,$56,$46,$42,$2D,$31,$39,$38,$39,$00,$02,$02,$01,$00
    Data.b $02,$70,$00,$A0,$05,$F9,$03,$00,$09,$00,$02,$00,$00,$00,$D0,$ED
    Data.b $53,$58,$C0,$32,$C2,$C0,$36,$55,$23,$36,$C0,$31,$1F,$F5,$11,$9D
    Data.b $C0,$0E,$0F,$CD,$7D,$F3,$3C,$28,$28,$11,$00,$01,$0E,$1A,$CD,$7D
    Data.b $F3,$21,$01,$00,$22,$AB,$C0,$21,$00,$3F,$11,$9D,$C0,$0E,$27,$CD
    Data.b $7D,$F3,$C3,$00,$01,$57,$C0,$CD,$00,$00,$79,$E6,$FE,$FE,$02,$20
    Data.b $07,$3A,$C2,$C0,$A7,$CA,$22,$40,$11,$77,$C0,$0E,$09,$CD,$7D,$F3
    Data.b $0E,$07,$CD,$7D,$F3,$18,$B4,$42,$6F,$6F,$74,$20,$65,$72,$72,$6F
    Data.b $72,$0D,$0A,$50,$72,$65,$73,$73,$20,$61,$6E,$79,$20,$6B,$65,$79
    Data.b $20,$66,$6F,$72,$20,$72,$65,$74,$72,$79,$0D,$0A,$24,$00,$4D,$53
    Data.b $58,$44,$4F,$53,$20,$20,$53,$59,$53,$00,$00,$00,$00,$00,$00,$00
    Data.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    Data.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$F3,$2A
    Data.b $51,$F3,$11,$00,$01,$19,$01,$00,$01,$11,$00,$C1,$ED,$B0,$3A,$EE
    Data.b $C0,$47,$11,$EF,$C0,$21,$00,$00,$CD,$51,$52,$F3,$76,$C9,$18,$64
    Data.b $3A,$AF,$80,$F9,$CA,$6D,$48,$D3,$A5,$0C,$8C,$2F,$9C,$CB,$E9,$89
    Data.b $D2,$00,$32,$26,$40,$94,$61,$19,$20,$E6,$80,$6D,$8A,$00,$00,$00
    Data.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    Data.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    Data.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    Data.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    Data.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    Data.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    Data.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    Data.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    Data.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    Data.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    Data.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    Data.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    Data.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    Data.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    Data.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  EndDataSection

  Procedure SetError(msg$)
    LastError$ = msg$
  EndProcedure

  Procedure.s GetLastErrorMessage()
    ProcedureReturn LastError$
  EndProcedure

  ; FAT12 read entry helper
  Procedure.u ReadFAT(clnr.u, *FAT_Ptr)
    Protected P = *FAT_Ptr + (clnr * 3) / 2
    Protected val.u = PeekA(P) | (PeekA(P + 1) << 8)
    If clnr & 1
      ProcedureReturn (val >> 4) & $0FFF
    Else
      ProcedureReturn val & $0FFF
    EndIf
  EndProcedure

  ; FAT12 write entry helper
  Procedure WriteFAT(clnr.u, val.u, *FAT_Ptr)
    Protected P = *FAT_Ptr + (clnr * 3) / 2
    If clnr & 1
      PokeA(P, (PeekA(P) & $0F) | ((val & $0F) << 4))
      PokeA(P + 1, (val >> 4) & $FF)
    Else
      PokeA(P, val & $FF)
      PokeA(P + 1, (PeekA(P + 1) & $F0) | ((val >> 8) & $0F))
    EndIf
  EndProcedure

  ; Timestamp conversions
  Procedure.i MSXTimeToPBDate(MSXTime.u, MSXDate.u)
    Protected Day = MSXDate & $1F
    Protected Month = (MSXDate >> 5) & $0F
    Protected Year = 1980 + ((MSXDate >> 9) & $7F)
    Protected Sec = (MSXTime & $1F) * 2
    Protected Min = (MSXTime >> 5) & $3F
    Protected Hour = (MSXTime >> 11) & $1F
    
    If Month < 1 Or Month > 12 : Month = 1 : EndIf
    If Day < 1 Or Day > 31 : Day = 1 : EndIf
    If Hour < 0 Or Hour > 23 : Hour = 0 : EndIf
    If Min < 0 Or Min > 59 : Min = 0 : EndIf
    If Sec < 0 Or Sec > 59 : Sec = 0 : EndIf
    
    ProcedureReturn Date(Year, Month, Day, Hour, Min, Sec)
  EndProcedure

  Procedure.u PBDateToMSXTime(PBDate.i)
    Protected Hour = Hour(PBDate)
    Protected Min = Minute(PBDate)
    Protected Sec = Second(PBDate) / 2
    ProcedureReturn (Hour << 11) | (Min << 5) | Sec
  EndProcedure

  Procedure.u PBDateToMSXDate(PBDate.i)
    Protected Year = Year(PBDate) - 1980
    If Year < 0 : Year = 0 : EndIf
    If Year > 127 : Year = 127 : EndIf
    Protected Month = Month(PBDate)
    Protected Day = Day(PBDate)
    ProcedureReturn (Year << 9) | (Month << 5) | Day
  EndProcedure

  ; Helper to convert standard name to FAT 11-byte representation (8.3 padded)
  Procedure.s ConvertToFAT11(Arg$)
    Protected res$ = Space(11)
    Protected k = 0
    Protected i = 1
    Protected len = Len(Arg$)
    Protected c$
    While k < 11
      If i <= len
        c$ = UCase(Mid(Arg$, i, 1))
      Else
        c$ = ""
      EndIf
      
      If c$ = "."
        If k < 8
          PokeA(@res$ + k, 32)
          k + 1
        Else
          i + 1
        EndIf
      ElseIf c$ = "*"
        PokeA(@res$ + k, Asc("?"))
        k + 1
        If k = 8
          i + 1
        EndIf
      ElseIf c$ = ""
        PokeA(@res$ + k, 32)
        k + 1
      Else
        PokeA(@res$ + k, Asc(c$))
        k + 1
        i + 1
      EndIf
    Wend
    ProcedureReturn res$
  EndProcedure

  ; Check if filename matches FAT11 mask (with wildcard support)
  Procedure.i MatchesFAT11(FAT11_Entry$, FAT11_Mask$)
    Protected k
    For k = 0 To 10
      Protected entryChar = Asc(Mid(FAT11_Entry$, k + 1, 1))
      Protected maskChar = Asc(Mid(FAT11_Mask$, k + 1, 1))
      If entryChar <> maskChar And maskChar <> Asc("?")
        ProcedureReturn #False
      EndIf
    Next
    ProcedureReturn #True
  EndProcedure

  ; Decode 11-character FAT directory entry name to standard string (e.g. "FILE.TXT")
  Procedure.s GetEntryName(*de.DirEntry)
    Protected name$ = ""
    Protected i
    For i = 0 To 7
      Protected char = *de\d_fname[i] & $FF
      If char = 0 Or char = 32
        Break
      EndIf
      name$ + Chr(char)
    Next
    Protected ext$ = ""
    For i = 0 To 2
      char = *de\d_ext[i] & $FF
      If char = 0 Or char = 32
        Break
      EndIf
      ext$ + Chr(char)
    Next
    If ext$ <> ""
      ProcedureReturn LCase(name$ + "." + ext$)
    Else
      ProcedureReturn LCase(name$)
    EndIf
  EndProcedure

  Procedure.i IsEntryUsed(*de.DirEntry)
    Protected firstChar = *de\d_fname[0] & $FF
    If firstChar = $E5 Or firstChar = $00
      ProcedureReturn #False
    EndIf
    ProcedureReturn #True
  EndProcedure

  Procedure.i ParseBootBlock()
    Protected seclen.u = (BootBlock(11) & $FF) | ((BootBlock(12) & $FF) << 8)
    Protected cl.u = BootBlock(13) & $FF
    If seclen <> 512 Or cl = 0
      SetError("Boot block does not contain valid sector/cluster parameters.")
      ProcedureReturn #False
    EndIf
    
    clus_len = seclen * cl
    ndir = (BootBlock(17) & $FF) | ((BootBlock(18) & $FF) << 8)
    
    Protected num_fats = BootBlock(16) & $FF
    Protected sectors_per_fat = (BootBlock(22) & $FF) | ((BootBlock(23) & $FF) << 8)
    
    dir_ofs = seclen * (1 + num_fats * sectors_per_fat)
    data_ofs = dir_ofs + ndir * 32
    
    Protected total_sectors = (BootBlock(19) & $FF) | ((BootBlock(20) & $FF) << 8)
    maxcl = (total_sectors - data_ofs / seclen) / cl + 1
    
    FAT_len = seclen * sectors_per_fat
    DIR_len = ndir * 32
    
    ProcedureReturn #True
  EndProcedure

  Procedure.i OpenDisk(DiskPathName$)
    If DiskFile <> 0
      CloseDisk()
    EndIf
    
    DiskFile = OpenFile(#PB_Any, DiskPathName$)
    If DiskFile = 0
      SetError("Cannot open disk image file: " + DiskPathName$)
      ProcedureReturn #False
    EndIf
    
    ; Read boot block
    FileSeek(DiskFile, 0)
    If ReadData(DiskFile, @BootBlock(0), 512) <> 512
      SetError("Cannot read boot sector from: " + DiskPathName$)
      CloseFile(DiskFile)
      DiskFile = 0
      ProcedureReturn #False
    EndIf
    
    ; Parse parameters
    If Not ParseBootBlock()
      CloseFile(DiskFile)
      DiskFile = 0
      ProcedureReturn #False
    EndIf
    
    ; Verify file size
    Protected expectedSize.q = ((BootBlock(19) & $FF) | ((BootBlock(20) & $FF) << 8)) * 512
    If Lof(DiskFile) <> expectedSize
      SetError("Disk image size (" + Str(Lof(DiskFile)) + ") does not match boot sector expected size (" + Str(expectedSize) + ").")
      CloseFile(DiskFile)
      DiskFile = 0
      ProcedureReturn #False
    EndIf
    
    ; Allocate and load FAT
    If *FAT : FreeMemory(*FAT) : EndIf
    *FAT = AllocateMemory(FAT_len)
    FileSeek(DiskFile, 512)
    If ReadData(DiskFile, *FAT, FAT_len) <> FAT_len
      SetError("Cannot read FAT from: " + DiskPathName$)
      CloseFile(DiskFile)
      DiskFile = 0
      ProcedureReturn #False
    EndIf
    
    ; Allocate and load Directory
    If *DIR : FreeMemory(*DIR) : EndIf
    *DIR = AllocateMemory(DIR_len)
    FileSeek(DiskFile, dir_ofs)
    If ReadData(DiskFile, *DIR, DIR_len) <> DIR_len
      SetError("Cannot read DIR from: " + DiskPathName$)
      CloseFile(DiskFile)
      DiskFile = 0
      ProcedureReturn #False
    EndIf
    
    DiskPath$ = DiskPathName$
    ProcedureReturn #True
  EndProcedure

  Procedure.i CreateDisk(DiskPathName$, BootSectorPath$ = "")
    If DiskFile <> 0
      CloseDisk()
    EndIf
    
    ; Load BootBlock
    If BootSectorPath$ <> ""
      Protected f = ReadFile(#PB_Any, BootSectorPath$)
      If f = 0
        SetError("Cannot open custom boot sector file: " + BootSectorPath$)
        ProcedureReturn #False
      EndIf
      ReadData(f, @BootBlock(0), 512)
      CloseFile(f)
    Else
      ; Use default
      CopyMemory(?DefaultBootBlock, @BootBlock(0), 512)
    EndIf
    
    ; Parse parameters to verify
    If Not ParseBootBlock()
      ProcedureReturn #False
    EndIf
    
    ; Open/Create the disk file for writing
    DiskFile = CreateFile(#PB_Any, DiskPathName$)
    If DiskFile = 0
      SetError("Cannot create disk image file: " + DiskPathName$)
      ProcedureReturn #False
    EndIf
    
    ; Write BootBlock
    WriteData(DiskFile, @BootBlock(0), 512)
    
    ; Allocate buffers
    If *FAT : FreeMemory(*FAT) : EndIf
    *FAT = AllocateMemory(FAT_len)
    If *DIR : FreeMemory(*DIR) : EndIf
    *DIR = AllocateMemory(DIR_len)
    
    ; Format FAT
    Protected mediaDescriptor.u = BootBlock(21) & $FF
    WriteFAT(0, mediaDescriptor | $F00, *FAT)
    WriteFAT(1, $FFF, *FAT)
    
    ; Write empty FAT and Directory to size it, and pad to full size
    Protected total_sectors = (BootBlock(19) & $FF) | ((BootBlock(20) & $FF) << 8)
    Protected total_size.q = total_sectors * 512
    
    Protected *zeros = AllocateMemory(512)
    FileSeek(DiskFile, total_size - 512)
    WriteData(DiskFile, *zeros, 512)
    FreeMemory(*zeros)
    
    ; Write formatted FAT and DIR
    ; First write FAT copies
    Protected num_fats = BootBlock(16) & $FF
    FileSeek(DiskFile, 512)
    Protected i
    For i = 0 To num_fats - 1
      WriteData(DiskFile, *FAT, FAT_len)
    Next
    
    ; Write DIR
    FileSeek(DiskFile, dir_ofs)
    WriteData(DiskFile, *DIR, DIR_len)
    
    DiskPath$ = DiskPathName$
    
    ; Close and reopen in read/write mode using OpenDisk
    CloseFile(DiskFile)
    DiskFile = 0
    
    ProcedureReturn OpenDisk(DiskPath$)
  EndProcedure

  Procedure.i CloseDisk()
    If DiskFile = 0
      ProcedureReturn #False
    EndIf
    
    ; Write FAT copies
    FileSeek(DiskFile, 512)
    Protected num_fats = BootBlock(16) & $FF
    Protected i
    For i = 0 To num_fats - 1
      WriteData(DiskFile, *FAT, FAT_len)
    Next
    
    ; Write Directory
    FileSeek(DiskFile, dir_ofs)
    WriteData(DiskFile, *DIR, DIR_len)
    
    CloseFile(DiskFile)
    DiskFile = 0
    DiskPath$ = ""
    
    If *FAT
      FreeMemory(*FAT)
      *FAT = 0
    EndIf
    If *DIR
      FreeMemory(*DIR)
      *DIR = 0
    EndIf
    
    ProcedureReturn #True
  EndProcedure

  Procedure.i ListFiles(List FilesOut.FileInfo())
    ClearList(FilesOut())
    If DiskFile = 0
      SetError("No disk image is open.")
      ProcedureReturn #False
    EndIf
    
    Protected *arr.DirEntryArray = *DIR
    Protected i
    For i = 0 To ndir - 1
      If IsEntryUsed(@*arr\Entry[i])
        AddElement(FilesOut())
        FilesOut()\FileName = GetEntryName(@*arr\Entry[i])
        FilesOut()\Size = *arr\Entry[i]\d_size
        FilesOut()\FirstCluster = *arr\Entry[i]\d_first
        FilesOut()\Attrib = *arr\Entry[i]\d_attrib
        FilesOut()\DateTime = MSXTimeToPBDate(*arr\Entry[i]\d_time, *arr\Entry[i]\d_date)
      EndIf
    Next
    
    ProcedureReturn #True
  EndProcedure

  Procedure.i ExtractFile(MSXName$, DestPath$)
    If DiskFile = 0
      SetError("No disk image is open.")
      ProcedureReturn #False
    EndIf
    
    Protected targetFAT11$ = ConvertToFAT11(MSXName$)
    Protected *arr.DirEntryArray = *DIR
    Protected i, entryIdx = -1
    
    For i = 0 To ndir - 1
      If IsEntryUsed(@*arr\Entry[i])
        Protected entryName11$ = Space(11)
        CopyMemory(@*arr\Entry[i]\d_fname[0], @entryName11$, 11)
        If entryName11$ = targetFAT11$
          entryIdx = i
          Break
        EndIf
      EndIf
    Next
    
    If entryIdx = -1
      SetError("File not found on disk image: " + MSXName$)
      ProcedureReturn #False
    EndIf
    
    Protected *de.DirEntry = @*arr\Entry[entryIdx]
    Protected size.q = *de\d_size
    Protected curcl.u = *de\d_first
    
    Protected localFile = CreateFile(#PB_Any, DestPath$)
    If localFile = 0
      SetError("Cannot create local file: " + DestPath$)
      ProcedureReturn #False
    EndIf
    
    Protected *secbuf = AllocateMemory(512)
    Protected sectors_per_cluster = BootBlock(13) & $FF
    
    While size > 0 And curcl >= 2 And curcl <= maxcl
      Protected cluster_offset.q = data_ofs + clus_len * (curcl - 2)
      FileSeek(DiskFile, cluster_offset)
      
      Protected s
      For s = 0 To sectors_per_cluster - 1
        If size <= 0 : Break : EndIf
        
        ReadData(DiskFile, *secbuf, 512)
        Protected bytesToWrite = 512
        If size < 512
          bytesToWrite = size
        EndIf
        
        WriteData(localFile, *secbuf, bytesToWrite)
        size - bytesToWrite
      Next
      
      curcl = ReadFAT(curcl, *FAT)
    Wend
    
    FreeMemory(*secbuf)
    CloseFile(localFile)
    
    If size > 0
      SetError("Warning: File was truncated, disk image might be corrupt.")
    EndIf
    
    ; Set modification date
    Protected pbDate = MSXTimeToPBDate(*de\d_time, *de\d_date)
    SetFileDate(DestPath$, #PB_Date_Modified, pbDate)
    
    ProcedureReturn #True
  EndProcedure

  Procedure.i DeleteMSXFile(MSXName$)
    If DiskFile = 0
      SetError("No disk image is open.")
      ProcedureReturn #False
    EndIf
    
    Protected targetFAT11$ = ConvertToFAT11(MSXName$)
    Protected *arr.DirEntryArray = *DIR
    Protected i, entryIdx = -1
    
    For i = 0 To ndir - 1
      If IsEntryUsed(@*arr\Entry[i])
        Protected entryName11$ = Space(11)
        CopyMemory(@*arr\Entry[i]\d_fname[0], @entryName11$, 11)
        If entryName11$ = targetFAT11$
          entryIdx = i
          Break
        EndIf
      EndIf
    Next
    
    If entryIdx = -1
      ; File not found, nothing to delete. That's fine.
      ProcedureReturn #True
    EndIf
    
    ; Free FAT chain
    Protected curcl.u = *arr\Entry[entryIdx]\d_first
    While curcl >= 2 And curcl <= maxcl
      Protected nextcl.u = ReadFAT(curcl, *FAT)
      WriteFAT(curcl, 0, *FAT)
      curcl = nextcl
    Wend
    
    ; Mark directory entry as deleted
    *arr\Entry[entryIdx]\d_fname[0] = $E5
    
    ProcedureReturn #True
  EndProcedure

  Procedure.i AddFile(LocalPath$, MSXName$ = "")
    If DiskFile = 0
      SetError("No disk image is open.")
      ProcedureReturn #False
    EndIf
    
    ; Open local file to read
    Protected localFile = ReadFile(#PB_Any, LocalPath$)
    If localFile = 0
      SetError("Cannot open local file: " + LocalPath$)
      ProcedureReturn #False
    EndIf
    
    Protected Size.q = Lof(localFile)
    
    If MSXName$ = ""
      MSXName$ = GetFilePart(LocalPath$)
    EndIf
    
    ; Delete existing file with the same name if it exists
    DeleteMSXFile(MSXName$)
    
    ; Find free directory entry
    Protected *arr.DirEntryArray = *DIR
    Protected dirpointer = -1
    Protected i
    For i = 0 To ndir - 1
      If Not IsEntryUsed(@*arr\Entry[i])
        dirpointer = i
        Break
      EndIf
    Next
    
    If dirpointer = -1
      SetError("Directory full. Cannot add file.")
      CloseFile(localFile)
      ProcedureReturn #False
    EndIf
    
    ; Write data cluster by cluster
    Protected prevcl.u = 0
    Protected bytesLeft.q = Size
    Protected *secbuf = AllocateMemory(512)
    Protected firstClSet = #False
    
    While bytesLeft > 0
      ; Find first free cluster
      Protected curcl.u = 0
      Protected c.u
      For c = 2 To maxcl
        If ReadFAT(c, *FAT) = 0
          curcl = c
          Break
        EndIf
      Next
      
      If curcl = 0
        ; Disk full!
        SetError("Disk full. Cannot write entire file.")
        ; Free the chain we allocated so far
        If firstClSet
          DeleteMSXFile(MSXName$)
        EndIf
        FreeMemory(*secbuf)
        CloseFile(localFile)
        ProcedureReturn #False
      EndIf
      
      If Not firstClSet
        *arr\Entry[dirpointer]\d_first = curcl
        firstClSet = #True
      EndIf
      
      ; Mark current cluster as EOF in FAT
      WriteFAT(curcl, $FFF, *FAT)
      
      ; Link previous cluster to this one
      If prevcl <> 0
        WriteFAT(prevcl, curcl, *FAT)
      EndIf
      
      ; Write data for this cluster
      Protected cluster_offset.q = data_ofs + clus_len * (curcl - 2)
      FileSeek(DiskFile, cluster_offset)
      
      Protected s
      Protected sectors_per_cluster = BootBlock(13) & $FF
      For s = 0 To sectors_per_cluster - 1
        If bytesLeft <= 0
          ; Pad remaining sectors of the cluster with 0
          FillMemory(*secbuf, 512, 0)
          WriteData(DiskFile, *secbuf, 512)
        Else
          Protected bytesToRead = 512
          If bytesLeft < 512
            bytesToRead = bytesLeft
          EndIf
          
          FillMemory(*secbuf, 512, 0)
          ReadData(localFile, *secbuf, bytesToRead)
          WriteData(DiskFile, *secbuf, 512)
          bytesLeft - bytesToRead
        EndIf
      Next
      
      prevcl = curcl
    Wend
    
    FreeMemory(*secbuf)
    CloseFile(localFile)
    
    ; Populate directory entry
    Protected *de.DirEntry = @*arr\Entry[dirpointer]
    Protected fat11Name$ = ConvertToFAT11(MSXName$)
    CopyMemory(@fat11Name$, @*de\d_fname[0], 11)
    *de\d_attrib = 0 ; Normal file
    FillMemory(@*de\d_reserv[0], 10, 0)
    
    ; Set time & date
    Protected localTime = GetFileDate(LocalPath$, #PB_Date_Modified)
    *de\d_time = PBDateToMSXTime(localTime)
    *de\d_date = PBDateToMSXDate(localTime)
    
    ; If 0-byte file, d_first should be 0
    If Not firstClSet
      *de\d_first = 0
    EndIf
    *de\d_size = Size
    
    ProcedureReturn #True
  EndProcedure
EndModule
