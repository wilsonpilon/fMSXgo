; *************************************************************
; **                                                         **
; **                MSXDiskDLL.pb                            **
; **                                                         **
; ** MSX Disk Utility DLL Wrapper                            **
; **                                                         **
; ** Compile with: pbcompiler MSXDiskDLL.pb /DLL /OUTPUT MSXDisk.dll
; **                                                         **
; *************************************************************

XIncludeFile "MSXDisk.pbi"

; Global list for DLL directory listing cache
Global NewList DLLFiles.MSXDisk::FileInfo()

ProcedureDLL.i CreateMSXDisk(*DiskPath, *BootSectorPath)
  Protected disk$ = PeekS(*DiskPath, -1, #PB_UTF8)
  Protected boot$ = ""
  If *BootSectorPath
    boot$ = PeekS(*BootSectorPath, -1, #PB_UTF8)
  EndIf
  ProcedureReturn MSXDisk::CreateDisk(disk$, boot$)
EndProcedure

ProcedureDLL.i OpenMSXDisk(*DiskPath)
  Protected disk$ = PeekS(*DiskPath, -1, #PB_UTF8)
  ProcedureReturn MSXDisk::OpenDisk(disk$)
EndProcedure

ProcedureDLL.i CloseMSXDisk()
  ProcedureReturn MSXDisk::CloseDisk()
EndProcedure

ProcedureDLL.i ExtractMSXFile(*MSXName, *DestPath)
  Protected name$ = PeekS(*MSXName, -1, #PB_UTF8)
  Protected dest$ = PeekS(*DestPath, -1, #PB_UTF8)
  ProcedureReturn MSXDisk::ExtractFile(name$, dest$)
EndProcedure

ProcedureDLL.i AddMSXFile(*LocalPath, *MSXName)
  Protected local$ = PeekS(*LocalPath, -1, #PB_UTF8)
  Protected name$ = ""
  If *MSXName
    name$ = PeekS(*MSXName, -1, #PB_UTF8)
  EndIf
  ProcedureReturn MSXDisk::AddFile(local$, name$)
EndProcedure

ProcedureDLL.i DeleteMSXFile(*MSXName)
  Protected name$ = PeekS(*MSXName, -1, #PB_UTF8)
  ProcedureReturn MSXDisk::DeleteMSXFile(name$)
EndProcedure

ProcedureDLL.i GetMSXDiskError(*Buffer, MaxLen.i)
  Protected err$ = MSXDisk::GetLastErrorMessage()
  If *Buffer
    PokeS(*Buffer, err$, MaxLen, #PB_UTF8)
  EndIf
  ProcedureReturn Len(err$)
EndProcedure

ProcedureDLL.i GetMSXFileCount()
  ClearList(DLLFiles())
  If MSXDisk::ListFiles(DLLFiles())
    ProcedureReturn ListSize(DLLFiles())
  Else
    ProcedureReturn -1
  EndIf
EndProcedure

ProcedureDLL.i GetMSXFileInfo(Index.i, *NameBuffer, NameBufferMaxLen.i, *Size, *DateTime)
  If Index < 0 Or Index >= ListSize(DLLFiles())
    ProcedureReturn #False
  EndIf
  
  SelectElement(DLLFiles(), Index)
  
  If *NameBuffer
    PokeS(*NameBuffer, DLLFiles()\FileName, NameBufferMaxLen, #PB_UTF8)
  EndIf
  
  If *Size
    PokeL(*Size, DLLFiles()\Size)
  EndIf
  
  If *DateTime
    PokeL(*DateTime, DLLFiles()\DateTime)
  EndIf
  
  ProcedureReturn #True
EndProcedure
