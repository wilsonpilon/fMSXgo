#ifndef __CONSOLE_WIN_BI__
#define __CONSOLE_WIN_BI__

Const MSX_INPUT_NONE = 0
Const MSX_INPUT_KEY = 1
Const MSX_INPUT_MOUSE = 2

Const MSX_MOUSE_DOWN = 1
Const MSX_MOUSE_UP = 2
Const MSX_MOUSE_MOVE = 3
Const MSX_MOUSE_WHEEL_UP = 4
Const MSX_MOUSE_WHEEL_DOWN = 5

Declare Sub ConsoleInit(ByVal w As Integer, ByVal h As Integer)
Declare Sub ConsoleGetCurrentSize(ByRef w As Integer, ByRef h As Integer)
Declare Sub ConsoleShutdown()
Declare Sub ConsoleClear(ByVal fg As UByte = 7, ByVal bg As UByte = 0)
Declare Sub ConsoleSetCell(ByVal x As Integer, ByVal y As Integer, ByVal ch As UByte, ByVal fg As UByte = 7, ByVal bg As UByte = 0)
Declare Sub ConsoleWriteText(ByVal x As Integer, ByVal y As Integer, ByRef txt As String, ByVal fg As UByte = 7, ByVal bg As UByte = 0, ByVal maxLen As Integer = -1)
Declare Sub ConsoleSetCursor(ByVal x As Integer, ByVal y As Integer, ByVal visible As Integer)
Declare Function ConsolePollInput(ByRef eventType As Integer, ByRef keyText As String, ByRef mouseX As Integer, ByRef mouseY As Integer, ByRef mouseAction As Integer) As Integer
Declare Sub ConsoleBeginFrame()
Declare Sub ConsoleFlush()
Declare Sub ConsoleEndFrame()
Declare Sub ConsoleGetLastFrameStats(ByRef charCalls As UInteger, ByRef attrCalls As UInteger, ByRef fillCalls As UInteger)
Declare Sub ConsoleGetTotalStats(ByRef charCalls As UInteger, ByRef attrCalls As UInteger, ByRef fillCalls As UInteger)

#endif
