#ifndef __PROJECT_BI__
#define __PROJECT_BI__

Declare Function ProjectNew(ByRef path As String, ByRef errMsg As String) As Integer
Declare Function ProjectOpen(ByRef path As String, ByRef errMsg As String) As Integer
Declare Function ProjectSave(ByRef errMsg As String, ByRef savedCount As Integer) As Integer
Declare Sub ProjectClose()
Declare Function ProjectIsActive() As Integer
Declare Function ProjectActiveName() As String
Declare Function ProjectActivePath() As String
Declare Function ProjectActiveDir() As String
Declare Sub ProjectRegisterFile(ByRef relPath As String, ByRef content As String)
Declare Sub ProjectListFilesWithExt(ByRef extLower As String, paths() As String, ByRef count As Integer)

#endif
