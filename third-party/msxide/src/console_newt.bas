#Include Once "../newt-freebasic/newt.bi"
#Include Once "console.bi"

Const MAX_CONSOLE_W = 180
Const MAX_CONSOLE_H = 80

Dim Shared gW As Integer = 100
Dim Shared gH As Integer = 35
Dim Shared gRowText(1 To MAX_CONSOLE_H) As String

Dim Shared gLastCharCalls As UInteger
Dim Shared gLastAttrCalls As UInteger
Dim Shared gLastFillCalls As UInteger

Dim Shared gFrameCharCalls As UInteger
Dim Shared gFrameAttrCalls As UInteger
Dim Shared gFrameFillCalls As UInteger

Dim Shared gTotalCharCalls As UInteger
Dim Shared gTotalAttrCalls As UInteger
Dim Shared gTotalFillCalls As UInteger
Dim Shared gInputForm As newtComponent
Dim Shared gVirtualMouseX As Integer = 1
Dim Shared gVirtualMouseY As Integer = 1
Dim Shared gVirtualMouseMode As Integer = 0
Dim Shared gPendingMouseActions(1 To 8) As Integer
Dim Shared gPendingMouseCount As Integer = 0

Private Sub QueueMouseAction(ByVal actionCode As Integer)
    If gPendingMouseCount >= 8 Then Exit Sub
    gPendingMouseCount += 1
    gPendingMouseActions(gPendingMouseCount) = actionCode
End Sub

Private Function EmitQueuedMouseAction(ByRef eventType As Integer, ByRef mouseX As Integer, ByRef mouseY As Integer, ByRef mouseAction As Integer) As Integer
    If gPendingMouseCount <= 0 Then Return 0

    eventType = MSX_INPUT_MOUSE
    mouseX = gVirtualMouseX
    mouseY = gVirtualMouseY
    mouseAction = gPendingMouseActions(1)

    Dim i As Integer
    For i = 1 To gPendingMouseCount - 1
        gPendingMouseActions(i) = gPendingMouseActions(i + 1)
    Next i
    gPendingMouseCount -= 1
    Return -1
End Function

Private Sub InitInputForm()
    gInputForm = newtForm(0, 0, 0)
    If gInputForm = 0 Then Exit Sub

    Dim i As Integer
    For i = 32 To 126
        newtFormAddHotKey(gInputForm, i)
    Next i

    newtFormAddHotKey(gInputForm, NEWT_KEY_ENTER)
    newtFormAddHotKey(gInputForm, NEWT_KEY_ESCAPE)
    newtFormAddHotKey(gInputForm, NEWT_KEY_BKSPC)
    newtFormAddHotKey(gInputForm, NEWT_KEY_DELETE)

    newtFormAddHotKey(gInputForm, NEWT_KEY_LEFT)
    newtFormAddHotKey(gInputForm, NEWT_KEY_RIGHT)
    newtFormAddHotKey(gInputForm, NEWT_KEY_UP)
    newtFormAddHotKey(gInputForm, NEWT_KEY_DOWN)
    newtFormAddHotKey(gInputForm, NEWT_KEY_HOME)
    newtFormAddHotKey(gInputForm, NEWT_KEY_END)
    newtFormAddHotKey(gInputForm, NEWT_KEY_PGUP)
    newtFormAddHotKey(gInputForm, NEWT_KEY_PGDN)

    newtFormAddHotKey(gInputForm, NEWT_KEY_F1)
    newtFormAddHotKey(gInputForm, NEWT_KEY_F2)
    newtFormAddHotKey(gInputForm, NEWT_KEY_F3)
    newtFormAddHotKey(gInputForm, NEWT_KEY_F4)
    newtFormAddHotKey(gInputForm, NEWT_KEY_F5)
    newtFormAddHotKey(gInputForm, NEWT_KEY_F6)
    newtFormAddHotKey(gInputForm, NEWT_KEY_F7)
    newtFormAddHotKey(gInputForm, NEWT_KEY_F8)
    newtFormAddHotKey(gInputForm, NEWT_KEY_F9)
    newtFormAddHotKey(gInputForm, NEWT_KEY_F10)
    newtFormAddHotKey(gInputForm, NEWT_KEY_F11)

    ' Mantem o loop responsivo sem bloquear indefinidamente no FormRun.
    newtFormSetTimer(gInputForm, 15)
End Sub

Private Function MapHotKeyToEditorKey(ByVal hotKey As Long) As String
    Select Case hotKey
        Case NEWT_KEY_ENTER
            Return Chr(13)
        Case NEWT_KEY_ESCAPE
            Return Chr(27)
        Case NEWT_KEY_BKSPC, 127
            Return Chr(8)
        Case NEWT_KEY_LEFT
            Return Chr(0) & Chr(75)
        Case NEWT_KEY_RIGHT
            Return Chr(0) & Chr(77)
        Case NEWT_KEY_UP
            Return Chr(0) & Chr(72)
        Case NEWT_KEY_DOWN
            Return Chr(0) & Chr(80)
        Case NEWT_KEY_HOME
            Return Chr(0) & Chr(71)
        Case NEWT_KEY_END
            Return Chr(0) & Chr(79)
        Case NEWT_KEY_PGUP
            Return Chr(0) & Chr(73)
        Case NEWT_KEY_PGDN
            Return Chr(0) & Chr(81)
        Case NEWT_KEY_DELETE
            Return Chr(0) & Chr(83)
        Case NEWT_KEY_F1
            Return Chr(0) & Chr(59)
        Case NEWT_KEY_F2
            Return Chr(0) & Chr(60)
        Case NEWT_KEY_F3
            Return Chr(0) & Chr(61)
        Case NEWT_KEY_F4
            Return Chr(0) & Chr(62)
        Case NEWT_KEY_F5
            Return Chr(0) & Chr(63)
        Case NEWT_KEY_F6
            Return Chr(0) & Chr(64)
        Case NEWT_KEY_F10
            Return Chr(0) & Chr(68)
        Case NEWT_KEY_F11
            Return Chr(0) & Chr(84)
    End Select

    If hotKey >= 32 And hotKey <= 126 Then
        Return Chr(hotKey)
    End If

    Return ""
End Function

Private Function Clamp(ByVal v As Integer, ByVal mn As Integer, ByVal mx As Integer) As Integer
    If v < mn Then Return mn
    If v > mx Then Return mx
    Return v
End Function

Sub ConsoleInit(ByVal w As Integer, ByVal h As Integer)
    newtInit()
    newtCls()

    Dim cols As Long
    Dim rows As Long
    newtGetScreenSize(@cols, @rows)

    If cols > 0 Then gW = cols
    If rows > 0 Then gH = rows

    gW = Clamp(gW, 40, MAX_CONSOLE_W)
    gH = Clamp(gH, 15, MAX_CONSOLE_H)

    If w > 0 Then gW = Clamp(w, 40, MAX_CONSOLE_W)
    If h > 0 Then gH = Clamp(h, 15, MAX_CONSOLE_H)

    ConsoleClear(7, 0)
    gVirtualMouseX = Clamp(gW \ 2, 1, gW)
    gVirtualMouseY = Clamp(gH \ 2, 1, gH)
    gVirtualMouseMode = 0
    gPendingMouseCount = 0
    InitInputForm()
End Sub

Sub ConsoleGetCurrentSize(ByRef w As Integer, ByRef h As Integer)
    Dim cols As Long
    Dim rows As Long
    newtGetScreenSize(@cols, @rows)

    If cols <= 0 Then cols = 100
    If rows <= 0 Then rows = 35

    w = Clamp(cols, 40, MAX_CONSOLE_W)
    h = Clamp(rows, 15, MAX_CONSOLE_H)
End Sub

Sub ConsoleShutdown()
    If gInputForm <> 0 Then
        newtFormDestroy(gInputForm)
        gInputForm = 0
    End If

    newtFinished()
End Sub

Sub ConsoleClear(ByVal fg As UByte = 7, ByVal bg As UByte = 0)
    Dim y As Integer
    For y = 1 To gH
        gRowText(y) = String(gW, " ")
    Next y
    newtCls()
End Sub

Sub ConsoleSetCell(ByVal x As Integer, ByVal y As Integer, ByVal ch As UByte, ByVal fg As UByte = 7, ByVal bg As UByte = 0)
    If x < 1 Or x > gW Or y < 1 Or y > gH Then Exit Sub
    Mid(gRowText(y), x, 1) = Chr(ch)
End Sub

Sub ConsoleWriteText(ByVal x As Integer, ByVal y As Integer, ByRef txt As String, ByVal fg As UByte = 7, ByVal bg As UByte = 0, ByVal maxLen As Integer = -1)
    If y < 1 Or y > gH Then Exit Sub
    If x > gW Then Exit Sub

    Dim drawLen As Integer
    If maxLen < 0 Then
        drawLen = Len(txt)
    Else
        drawLen = maxLen
    End If

    If drawLen <= 0 Then Exit Sub
    If x < 1 Then
        drawLen += x - 1
        x = 1
    End If
    If drawLen <= 0 Then Exit Sub

    If x + drawLen - 1 > gW Then drawLen = gW - x + 1
    If drawLen <= 0 Then Exit Sub

    Dim outTxt As String = Left(txt & String(drawLen, " "), drawLen)
    Mid(gRowText(y), x, drawLen) = outTxt
End Sub

Sub ConsoleSetCursor(ByVal x As Integer, ByVal y As Integer, ByVal visible As Integer)
    If visible <> 0 Then
        newtCursorOn()
    Else
        newtCursorOff()
    End If
End Sub

Function ConsolePollInput(ByRef eventType As Integer, ByRef keyText As String, ByRef mouseX As Integer, ByRef mouseY As Integer, ByRef mouseAction As Integer) As Integer
    eventType = MSX_INPUT_NONE
    keyText = ""
    mouseX = 0
    mouseY = 0
    mouseAction = 0

    If EmitQueuedMouseAction(eventType, mouseX, mouseY, mouseAction) <> 0 Then
        Return -1
    End If

    If gInputForm = 0 Then Return 0

    Dim es As newtExitStruct
    newtFormRun(gInputForm, @es)

    If es.reason = NEWT_EXIT_HOTKEY Then
        If es.u.key = NEWT_KEY_F8 Then
            gVirtualMouseMode = IIf(gVirtualMouseMode = 0, 1, 0)
            Return 0
        End If

        If es.u.key = NEWT_KEY_F7 Then
            gVirtualMouseX = Clamp(gW \ 2, 1, gW)
            gVirtualMouseY = Clamp(gH \ 2, 1, gH)
            Return 0
        End If

        If gVirtualMouseMode <> 0 Then
            Select Case es.u.key
                Case NEWT_KEY_LEFT, Asc("h"), Asc("H")
                    gVirtualMouseX = Clamp(gVirtualMouseX - 1, 1, gW)
                    eventType = MSX_INPUT_MOUSE
                    mouseX = gVirtualMouseX
                    mouseY = gVirtualMouseY
                    mouseAction = MSX_MOUSE_MOVE
                    Return -1
                Case NEWT_KEY_RIGHT, Asc("l"), Asc("L")
                    gVirtualMouseX = Clamp(gVirtualMouseX + 1, 1, gW)
                    eventType = MSX_INPUT_MOUSE
                    mouseX = gVirtualMouseX
                    mouseY = gVirtualMouseY
                    mouseAction = MSX_MOUSE_MOVE
                    Return -1
                Case NEWT_KEY_UP, Asc("k"), Asc("K")
                    gVirtualMouseY = Clamp(gVirtualMouseY - 1, 1, gH)
                    eventType = MSX_INPUT_MOUSE
                    mouseX = gVirtualMouseX
                    mouseY = gVirtualMouseY
                    mouseAction = MSX_MOUSE_MOVE
                    Return -1
                Case NEWT_KEY_DOWN, Asc("j"), Asc("J")
                    gVirtualMouseY = Clamp(gVirtualMouseY + 1, 1, gH)
                    eventType = MSX_INPUT_MOUSE
                    mouseX = gVirtualMouseX
                    mouseY = gVirtualMouseY
                    mouseAction = MSX_MOUSE_MOVE
                    Return -1
                Case Asc(" "), NEWT_KEY_ENTER
                    QueueMouseAction(MSX_MOUSE_DOWN)
                    QueueMouseAction(MSX_MOUSE_UP)
                    Return EmitQueuedMouseAction(eventType, mouseX, mouseY, mouseAction)
                Case NEWT_KEY_F9, Asc("d"), Asc("D")
                    QueueMouseAction(MSX_MOUSE_DOWN)
                    QueueMouseAction(MSX_MOUSE_UP)
                    QueueMouseAction(MSX_MOUSE_DOWN)
                    QueueMouseAction(MSX_MOUSE_UP)
                    Return EmitQueuedMouseAction(eventType, mouseX, mouseY, mouseAction)
            End Select
        End If

        keyText = MapHotKeyToEditorKey(es.u.key)
        If Len(keyText) > 0 Then
            eventType = MSX_INPUT_KEY
            Return -1
        End If
    End If

    Return 0
End Function

Sub ConsoleResetInputState()
    gPendingMouseCount = 0
End Sub

Sub ConsoleBeginFrame()
    gFrameCharCalls = 0
    gFrameAttrCalls = 0
    gFrameFillCalls = 0
End Sub

Sub ConsoleFlush()
    Dim y As Integer
    Dim lineText As String
    For y = 1 To gH
        lineText = gRowText(y)
        If gVirtualMouseMode <> 0 And y = gVirtualMouseY Then
            Mid(lineText, gVirtualMouseX, 1) = Chr(254)
        End If

        newtDrawRootText(0, y - 1, StrPtr(lineText))
        gFrameCharCalls += 1
        gTotalCharCalls += 1
    Next y

    newtRefresh()
End Sub

Sub ConsoleEndFrame()
    gLastCharCalls = gFrameCharCalls
    gLastAttrCalls = gFrameAttrCalls
    gLastFillCalls = gFrameFillCalls
End Sub

Sub ConsoleGetLastFrameStats(ByRef charCalls As UInteger, ByRef attrCalls As UInteger, ByRef fillCalls As UInteger)
    charCalls = gLastCharCalls
    attrCalls = gLastAttrCalls
    fillCalls = gLastFillCalls
End Sub

Sub ConsoleGetTotalStats(ByRef charCalls As UInteger, ByRef attrCalls As UInteger, ByRef fillCalls As UInteger)
    charCalls = gTotalCharCalls
    attrCalls = gTotalAttrCalls
    fillCalls = gTotalFillCalls
End Sub

Sub ConsoleGetMouseHud(ByRef available As Integer, ByRef enabled As Integer, ByRef x As Integer, ByRef y As Integer)
    available = -1
    enabled = gVirtualMouseMode
    x = gVirtualMouseX
    y = gVirtualMouseY
End Sub

' Terminais Linux (onde este backend roda) ja exibem UTF-8 nativamente -
' nao ha codepage de console pra converter, entao devolve o texto intacto.
Function ConsoleUtf8ToActiveCp(ByRef txt As String) As String
    Return txt
End Function

' Integracao com a area de transferencia do sistema (X11/Wayland) ainda nao
' implementada neste backend - Ctrl+C/X/V do editor continuam funcionando
' normalmente entre documentos do proprio msxIDE (clipboard interno), so'
' nao chegam a sincronizar com outros programas do terminal.
Sub ConsoleSetClipboardText(ByRef text As String)
End Sub

Function ConsoleGetClipboardText() As String
    Return ""
End Function

' TranslateKeyEvent deste backend trabalha em cima de sequencias ANSI de
' terminal, nao de KEY_EVENT_RECORD do Windows Console API - o smoke test
' sintetico (pensado pra validar Ctrl/Alt+letra via dwControlKeyState) so'
' faz sentido pro backend win.
Function ConsoleRunKeyTranslationSmokeTest(ByRef report As String) As Integer
    report = "SMOKE KEYS: nao aplicavel ao backend newt (nao usa Windows Console API)"
    Return -1
End Function
