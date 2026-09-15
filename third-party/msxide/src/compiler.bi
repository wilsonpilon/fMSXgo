#ifndef __COMPILER_BI__
#define __COMPILER_BI__

Declare Function CompilerCompileToAmx(ByRef srcPath As String, ByRef outAmxPath As String, ByRef errMsg As String) As Integer
Declare Function CompilerTokenizeAmx(ByRef amxPath As String, ByRef outBmxPath As String, ByRef errMsg As String) As Integer
Declare Function CompilerCompileToBmx(ByRef srcPath As String, ByRef outAmxPath As String, ByRef outBmxPath As String, ByRef errMsg As String) As Integer
Declare Function CompilerBuildRunDisk(ByRef srcPath As String, ByRef amxPath As String, ByRef bmxPath As String, ByRef outDiskPath As String, ByRef errMsg As String, ByVal cleanDiskDir As Integer = 0) As Integer
Declare Function CompilerBuildAsmRunDisk(ByRef srcPath As String, ByRef binPath As String, ByRef outDiskPath As String, ByRef errMsg As String, ByVal cleanDiskDir As Integer = 0) As Integer
Declare Function CompilerReadAsmBinInfo(ByRef binPath As String, ByRef startAddr As Integer, ByRef endAddr As Integer, ByRef execAddr As Integer, ByRef errMsg As String) As Integer
Declare Function CompilerBuildAsmDataLoader(ByRef binPath As String, ByRef labelName As String, ByVal usrIndex As Integer, ByRef outCode As String, ByRef errMsg As String) As Integer
Declare Function CompilerBuildAsmIncFile(ByRef binPath As String, ByRef srcAsmPath As String, ByRef labelName As String, ByRef outIncPath As String, ByRef errMsg As String) As Integer
Declare Function CompilerRunJoinSmokeTest(ByRef report As String) As Integer
Declare Function CompilerRunFormatSmokeTest(ByRef report As String) As Integer
Declare Function CompilerRunVariableSmokeTest(ByRef report As String) As Integer
Declare Function CompilerRunNBasicSmokeTest(ByRef report As String) As Integer
Declare Function CompilerRunFuncSmokeTest(ByRef report As String) As Integer

#endif
