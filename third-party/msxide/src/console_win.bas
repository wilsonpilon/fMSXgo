#Include Once "windows.bi"
#Include Once "console_win.bi"

Const MAX_CONSOLE_W = 180
Const MAX_CONSOLE_H = 80
Const INPUT_KEY_EVENT = &h0001
Const INPUT_MOUSE_EVENT = &h0002

Dim Shared gW As Integer
Dim Shared gH As Integer
Dim Shared gOut As HANDLE
Dim Shared gIn As HANDLE
Dim Shared gOriginalInMode As DWORD
Dim Shared gHasOriginalInMode As Integer
Dim Shared gMouseLeftDown As Integer
Dim Shared gCursorVisible As Integer
Dim Shared gRowText(1 To MAX_CONSOLE_H) As String
Dim Shared gRowAttr(1 To MAX_CONSOLE_H, 1 To MAX_CONSOLE_W) As UShort
Dim Shared gDirtyRowAny(1 To MAX_CONSOLE_H) As UByte
Dim Shared gDirtyCell(1 To MAX_CONSOLE_H, 1 To MAX_CONSOLE_W) As UByte

Dim Shared gFrameCharCalls As UInteger
Dim Shared gFrameAttrCalls As UInteger
Dim Shared gFrameFillCalls As UInteger

Dim Shared gLastCharCalls As UInteger
Dim Shared gLastAttrCalls As UInteger
Dim Shared gLastFillCalls As UInteger

Dim Shared gTotalCharCalls As UInteger
Dim Shared gTotalAttrCalls As UInteger
Dim Shared gTotalFillCalls As UInteger

Private Function Clamp(ByVal v As Integer, ByVal mn As Integer, ByVal mx As Integer) As Integer
    If v < mn Then Return mn
    If v > mx Then Return mx
    Return v
End Function

Private Function MakeAttr(ByVal fg As UByte, ByVal bg As UByte) As UShort
    Return Cast(UShort, (bg And 15) Shl 4 Or (fg And 15))
End Function

Private Function IsUniformAttr(ByVal y As Integer, ByVal x1 As Integer, ByVal x2 As Integer, ByRef outAttr As UShort) As Integer
    If x1 > x2 Then Return 0

    Dim a As UShort = gRowAttr(y, x1)
    Dim x As Integer
    For x = x1 + 1 To x2
        If gRowAttr(y, x) <> a Then Return 0
    Next x

    outAttr = a
    Return -1
End Function

Private Function IsRangeAttr(ByVal y As Integer, ByVal x1 As Integer, ByVal x2 As Integer, ByVal attrValue As UShort) As Integer
    If x1 > x2 Then Return -1

    Dim x As Integer
    For x = x1 To x2
        If gRowAttr(y, x) <> attrValue Then Return 0
    Next x

    Return -1
End Function

Private Sub MarkAllDirty()
    Dim y As Integer
    Dim x As Integer
    For y = 1 To gH
        gDirtyRowAny(y) = 1
        For x = 1 To gW
            gDirtyCell(y, x) = 1
        Next x
    Next y
End Sub

Private Sub MarkDirtyRange(ByVal y As Integer, ByVal x1 As Integer, ByVal x2 As Integer)
    If y < 1 Or y > gH Then Exit Sub
    If x1 > x2 Then Exit Sub

    x1 = Clamp(x1, 1, gW)
    x2 = Clamp(x2, 1, gW)
    If x1 > x2 Then Exit Sub

    Dim x As Integer
    gDirtyRowAny(y) = 1
    For x = x1 To x2
        gDirtyCell(y, x) = 1
    Next x
End Sub

Private Sub RestoreInputMode()
    If gIn = 0 Then Exit Sub

    Dim inputMode As DWORD
    If gHasOriginalInMode <> 0 Then
        inputMode = gOriginalInMode
    ElseIf GetConsoleMode(gIn, @inputMode) = 0 Then
        Exit Sub
    End If

    inputMode = inputMode Or ENABLE_EXTENDED_FLAGS
    inputMode = inputMode Or ENABLE_MOUSE_INPUT
    inputMode = inputMode Or ENABLE_WINDOW_INPUT
    inputMode = inputMode And Not ENABLE_QUICK_EDIT_MODE
    ' Sem isso o Windows intercepta Ctrl+C como sinal de encerramento do
    ' processo (CTRL_C_EVENT) e ele NUNCA chega como tecla normal via
    ' ReadConsoleInput - precisamos dele como tecla de verdade pro atalho
    ' de Copiar do editor.
    inputMode = inputMode And Not ENABLE_PROCESSED_INPUT
    SetConsoleMode(gIn, inputMode)
End Sub

Sub ConsoleInit(ByVal w As Integer, ByVal h As Integer)
    Dim y As Integer
    Dim x As Integer

    gW = Clamp(w, 1, MAX_CONSOLE_W)
    gH = Clamp(h, 1, MAX_CONSOLE_H)
    gOut = GetStdHandle(STD_OUTPUT_HANDLE)
    gIn = GetStdHandle(STD_INPUT_HANDLE)

    ' Codepage OEM 860 (Portugues) em vez do padrao 437 (EUA) de um Windows
    ' em ingles: mantem os mesmos caracteres de linha/caixa (176-223, iguais
    ' em qualquer codepage OEM) mas cobre corretamente as letras acentuadas
    ' do portugues que faltam na 437 (ã, õ, Á, Í, Ó, Ú). Se falhar (SO nao
    ' suporta essa codepage por algum motivo), segue com o que ja estava
    ' ativo - ConsoleUtf8ToActiveCp le a codepage realmente ativa depois.
    SetConsoleOutputCP(860)
    SetConsoleCP(860)

    gHasOriginalInMode = 0
    If GetConsoleMode(gIn, @gOriginalInMode) <> 0 Then
        gHasOriginalInMode = -1
    End If
    RestoreInputMode()

    Dim sb As COORD
    sb.X = gW
    sb.Y = gH
    SetConsoleScreenBufferSize(gOut, sb)

    Dim rect As SMALL_RECT
    rect.Left = 0
    rect.Top = 0
    rect.Right = gW - 1
    rect.Bottom = gH - 1
    SetConsoleWindowInfo(gOut, TRUE, @rect)

    For y = 1 To gH
        gRowText(y) = String(gW, " ")
        For x = 1 To gW
            gRowAttr(y, x) = MakeAttr(7, 0)
            gDirtyCell(y, x) = 0
        Next x
        gDirtyRowAny(y) = 0
    Next y

    gCursorVisible = 1
    gFrameCharCalls = 0
    gFrameAttrCalls = 0
    gFrameFillCalls = 0
    gLastCharCalls = 0
    gLastAttrCalls = 0
    gLastFillCalls = 0
    gTotalCharCalls = 0
    gTotalAttrCalls = 0
    gTotalFillCalls = 0
    gMouseLeftDown = 0
    MarkAllDirty()
End Sub

Sub ConsoleGetCurrentSize(ByRef w As Integer, ByRef h As Integer)
    ' Maximiza a janela do console ANTES de ler o tamanho - pedido do
    ' usuario (2026-09-13): o desktop deve sempre ocupar a largura/altura
    ' total da janela do terminal. So' "ler o tamanho atual" sem maximizar
    ' primeiro fica preso no tamanho que a janela ja' estava - inclusive um
    ' tamanho pequeno deixado por uma execucao ANTERIOR deste mesmo
    ' programa (o Windows nao devolve a janela do console ao tamanho
    ' original sozinho so' porque o processo terminou).
    Dim hwnd As HWND = GetConsoleWindow()
    If hwnd <> 0 Then ShowWindow(hwnd, SW_MAXIMIZE)

    Dim outH As HANDLE = GetStdHandle(STD_OUTPUT_HANDLE)
    Dim info As CONSOLE_SCREEN_BUFFER_INFO

    If GetConsoleScreenBufferInfo(outH, @info) = 0 Then
        w = 100
        h = 35
        Exit Sub
    End If

    w = (info.srWindow.Right - info.srWindow.Left) + 1
    h = (info.srWindow.Bottom - info.srWindow.Top) + 1

    If w < 40 Then w = 40
    If h < 15 Then h = 15
    If w > MAX_CONSOLE_W Then w = MAX_CONSOLE_W
    If h > MAX_CONSOLE_H Then h = MAX_CONSOLE_H
End Sub

Sub ConsoleShutdown()
    If gHasOriginalInMode <> 0 Then
        SetConsoleMode(gIn, gOriginalInMode)
    End If

    Dim ci As CONSOLE_CURSOR_INFO
    ci.dwSize = 20
    ci.bVisible = TRUE
    SetConsoleCursorInfo(gOut, @ci)
End Sub

' Protocolo de tecla estendida do editor: 2 bytes, Chr(0) & Chr(codigo).
' Segue a tabela classica de scan codes estendidos do BIOS/DOS (INT16h)
' onde ela existe (setas, F1-F10, Ctrl+seta, Ctrl+Home/End/PgUp/PgDn,
' Shift+F1) - DOS nunca definiu codigos proprios pra Shift+seta ou
' Ctrl+seta-vertical, entao esses (e as combinacoes Ctrl+Shift+seta, usadas
' pra selecao de texto por palavra/paragrafo) usam uma faixa inventada
' (150-165) que nao colide com nada da tabela real. Ctrl+<letra> usa uma
' faixa proria (200-225 = 200 + (A..Z ofsetado de 0)) em vez do control-char
' ASCII classico (Ctrl+H=Chr(8), por exemplo) porque varios desses ja tem
' dono (Chr(8)=Backspace, Chr(9)=Tab, Chr(13)=Enter) - misturar os dois
' esquemas tornaria essas teclas indistinguiveis no protocolo. Alt+<letra>
' (letras de acesso rapido do menu) usa a mesma ideia, faixa 230-255.
' Shift+Del / Shift+Insert / Ctrl+Insert sao o trio classico de
' recortar/colar/copiar dos editores MS-DOS de antes do Ctrl+C/X/V
' (QEdit, Norton Editor, Brief...) - em vez de inventar codigo novo,
' cada um deles emite o MESMO byte que seu equivalente moderno ja usa
' (Ctrl+X=223, Ctrl+V=221, Ctrl+C=202), entao o editor.bas nem sabe que
' existe diferenca: ganha o atalho antigo de graca, com o mesmo guard de
' "editable" que o atalho novo ja tinha.
Private Function TranslateKeyEvent(ByRef rec As KEY_EVENT_RECORD, ByRef keyText As String) As Integer
    If rec.bKeyDown = 0 Then Return 0

    Dim ctrlDown As Integer = (rec.dwControlKeyState And (LEFT_CTRL_PRESSED Or RIGHT_CTRL_PRESSED))
    Dim shiftDown As Integer = (rec.dwControlKeyState And SHIFT_PRESSED)

    Select Case rec.wVirtualKeyCode
        Case VK_LEFT
            If ctrlDown <> 0 And shiftDown <> 0 Then
                keyText = Chr(0) & Chr(160)
            ElseIf ctrlDown <> 0 Then
                keyText = Chr(0) & Chr(115)
            ElseIf shiftDown <> 0 Then
                keyText = Chr(0) & Chr(152)
            Else
                keyText = Chr(0) & Chr(75)
            End If
            Return -1
        Case VK_RIGHT
            If ctrlDown <> 0 And shiftDown <> 0 Then
                keyText = Chr(0) & Chr(161)
            ElseIf ctrlDown <> 0 Then
                keyText = Chr(0) & Chr(116)
            ElseIf shiftDown <> 0 Then
                keyText = Chr(0) & Chr(153)
            Else
                keyText = Chr(0) & Chr(77)
            End If
            Return -1
        Case VK_UP
            If ctrlDown <> 0 And shiftDown <> 0 Then
                keyText = Chr(0) & Chr(162)
            ElseIf ctrlDown <> 0 Then
                keyText = Chr(0) & Chr(150)
            ElseIf shiftDown <> 0 Then
                keyText = Chr(0) & Chr(154)
            Else
                keyText = Chr(0) & Chr(72)
            End If
            Return -1
        Case VK_DOWN
            If ctrlDown <> 0 And shiftDown <> 0 Then
                keyText = Chr(0) & Chr(163)
            ElseIf ctrlDown <> 0 Then
                keyText = Chr(0) & Chr(151)
            ElseIf shiftDown <> 0 Then
                keyText = Chr(0) & Chr(155)
            Else
                keyText = Chr(0) & Chr(80)
            End If
            Return -1
        Case VK_HOME
            If ctrlDown <> 0 And shiftDown <> 0 Then
                keyText = Chr(0) & Chr(164)
            ElseIf ctrlDown <> 0 Then
                keyText = Chr(0) & Chr(119)
            ElseIf shiftDown <> 0 Then
                keyText = Chr(0) & Chr(156)
            Else
                keyText = Chr(0) & Chr(71)
            End If
            Return -1
        Case VK_END
            If ctrlDown <> 0 And shiftDown <> 0 Then
                keyText = Chr(0) & Chr(165)
            ElseIf ctrlDown <> 0 Then
                keyText = Chr(0) & Chr(117)
            ElseIf shiftDown <> 0 Then
                keyText = Chr(0) & Chr(157)
            Else
                keyText = Chr(0) & Chr(79)
            End If
            Return -1
        Case VK_PRIOR
            If ctrlDown <> 0 Then
                keyText = Chr(0) & Chr(132)
            ElseIf shiftDown <> 0 Then
                keyText = Chr(0) & Chr(158)
            Else
                keyText = Chr(0) & Chr(73)
            End If
            Return -1
        Case VK_NEXT
            If ctrlDown <> 0 Then
                keyText = Chr(0) & Chr(118)
            ElseIf shiftDown <> 0 Then
                keyText = Chr(0) & Chr(159)
            Else
                keyText = Chr(0) & Chr(81)
            End If
            Return -1
        Case VK_DELETE
            If shiftDown <> 0 Then
                keyText = Chr(0) & Chr(223) ' Shift+Del = Ctrl+X (recortar)
            Else
                keyText = Chr(0) & Chr(83)
            End If
            Return -1
        Case VK_INSERT
            If shiftDown <> 0 Then
                keyText = Chr(0) & Chr(221) ' Shift+Insert = Ctrl+V (colar)
                Return -1
            ElseIf ctrlDown <> 0 Then
                keyText = Chr(0) & Chr(202) ' Ctrl+Insert = Ctrl+C (copiar)
                Return -1
            End If
            Return 0
        Case VK_TAB
            If shiftDown <> 0 Then
                keyText = Chr(0) & Chr(15)
            Else
                keyText = Chr(9)
            End If
            Return -1
        Case VK_F1
            If shiftDown <> 0 Then
                keyText = Chr(0) & Chr(84)
            Else
                keyText = Chr(0) & Chr(59)
            End If
            Return -1
        Case VK_F2
            keyText = Chr(0) & Chr(60): Return -1
        Case VK_F3
            keyText = Chr(0) & Chr(61): Return -1
        Case VK_F4
            keyText = Chr(0) & Chr(62): Return -1
        Case VK_F5
            keyText = Chr(0) & Chr(63): Return -1
        Case VK_F6
            keyText = Chr(0) & Chr(64): Return -1
        Case VK_F7
            keyText = Chr(0) & Chr(65): Return -1
        Case VK_F8
            keyText = Chr(0) & Chr(66): Return -1
        Case VK_F9
            keyText = Chr(0) & Chr(67): Return -1
        Case VK_F10
            keyText = Chr(0) & Chr(68): Return -1
        Case VK_RETURN
            keyText = Chr(13): Return -1
        Case VK_BACK
            keyText = Chr(8): Return -1
        Case VK_ESCAPE
            keyText = Chr(27): Return -1
    End Select

    If ctrlDown <> 0 And rec.wVirtualKeyCode >= VK_A And rec.wVirtualKeyCode <= VK_Z Then
        keyText = Chr(0) & Chr(200 + (rec.wVirtualKeyCode - VK_A))
        Return -1
    End If

    ' Alt+<letra> = letras de acesso rapido do menu (faixa 230-255). So'
    ' com Alt puro - AltGr (usado por @/#/etc no layout PT-BR) chega com
    ' LEFT_CTRL_PRESSED e RIGHT_ALT_PRESSED ligados ao mesmo tempo, e nao
    ' pode ser confundido com isso.
    Dim altOnly As Integer = ((rec.dwControlKeyState And (LEFT_ALT_PRESSED Or RIGHT_ALT_PRESSED)) <> 0) And ctrlDown = 0
    If altOnly <> 0 And rec.wVirtualKeyCode >= VK_A And rec.wVirtualKeyCode <= VK_Z Then
        keyText = Chr(0) & Chr(230 + (rec.wVirtualKeyCode - VK_A))
        Return -1
    End If

    Dim c As Integer = rec.uChar.UnicodeChar
    If c >= 32 And c <= 126 Then
        keyText = Chr(c)
        Return -1
    End If

    Return 0
End Function

' Testa TranslateKeyEvent direto, com KEY_EVENT_RECORD sinteticos - a unica
' forma de validar sem teclado de verdade que Ctrl+C/X/V/Z/Y/A/F/H,
' Alt+letra (mnemonico de menu), Shift/Ctrl+seta etc. realmente produzem o
' protocolo de 2 bytes que o editor espera. O smoke test do editor
' (--smoke-editor) injeta esses 2 bytes DIRETO em EditorHandleKey - nunca
' passa por aqui, entao nunca pegaria uma regressao nesta funcao.
Private Function CheckKeyTranslation(ByVal vk As Integer, ByVal ctrlState As DWORD, ByRef expected As String, ByRef testName As String, ByRef failReport As String) As Integer
    Dim rec As KEY_EVENT_RECORD
    rec.bKeyDown = 1
    rec.wVirtualKeyCode = vk
    rec.wVirtualScanCode = 0
    rec.dwControlKeyState = ctrlState
    rec.uChar.UnicodeChar = 0

    Dim keyText As String
    Dim gotKey As Integer = TranslateKeyEvent(rec, keyText)

    If gotKey = 0 Then
        failReport = "SMOKE KEYS FAIL: " & testName & " nao produziu tecla nenhuma"
        Return 0
    End If
    If keyText <> expected Then
        Dim gotHex As String = ""
        Dim i As Integer
        For i = 1 To Len(keyText)
            gotHex &= Hex(Asc(Mid(keyText, i, 1))) & " "
        Next i
        failReport = "SMOKE KEYS FAIL: " & testName & " produziu bytes [" & Trim(gotHex) & "] diferente do esperado"
        Return 0
    End If
    Return -1
End Function

Function ConsoleRunKeyTranslationSmokeTest(ByRef report As String) As Integer
    report = ""

    If CheckKeyTranslation(VK_LEFT, 0, Chr(0) & Chr(75), "Seta esquerda", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_LEFT, SHIFT_PRESSED, Chr(0) & Chr(152), "Shift+Esquerda", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_LEFT, LEFT_CTRL_PRESSED, Chr(0) & Chr(115), "Ctrl+Esquerda", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_LEFT, LEFT_CTRL_PRESSED Or SHIFT_PRESSED, Chr(0) & Chr(160), "Ctrl+Shift+Esquerda", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_UP, LEFT_CTRL_PRESSED, Chr(0) & Chr(150), "Ctrl+Cima", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_PRIOR, LEFT_CTRL_PRESSED, Chr(0) & Chr(132), "Ctrl+PgUp", report) = 0 Then Return 0

    If CheckKeyTranslation(VK_C, LEFT_CTRL_PRESSED, Chr(0) & Chr(202), "Ctrl+C", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_X, LEFT_CTRL_PRESSED, Chr(0) & Chr(223), "Ctrl+X", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_V, LEFT_CTRL_PRESSED, Chr(0) & Chr(221), "Ctrl+V", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_DELETE, SHIFT_PRESSED, Chr(0) & Chr(223), "Shift+Del (recortar)", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_INSERT, SHIFT_PRESSED, Chr(0) & Chr(221), "Shift+Insert (colar)", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_INSERT, LEFT_CTRL_PRESSED, Chr(0) & Chr(202), "Ctrl+Insert (copiar)", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_A, LEFT_CTRL_PRESSED, Chr(0) & Chr(200), "Ctrl+A", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_Z, LEFT_CTRL_PRESSED, Chr(0) & Chr(225), "Ctrl+Z", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_Y, LEFT_CTRL_PRESSED, Chr(0) & Chr(224), "Ctrl+Y", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_F, LEFT_CTRL_PRESSED, Chr(0) & Chr(205), "Ctrl+F", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_H, LEFT_CTRL_PRESSED, Chr(0) & Chr(207), "Ctrl+H", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_L, LEFT_CTRL_PRESSED, Chr(0) & Chr(211), "Ctrl+L", report) = 0 Then Return 0
    ' Ctrl com o lado DIREITO fisico tambem tem que funcionar (nem todo
    ' teclado/layout usa o esquerdo).
    If CheckKeyTranslation(VK_C, RIGHT_CTRL_PRESSED, Chr(0) & Chr(202), "Ctrl(direito)+C", report) = 0 Then Return 0

    If CheckKeyTranslation(VK_A, LEFT_ALT_PRESSED, Chr(0) & Chr(230), "Alt+A", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_C, LEFT_ALT_PRESSED, Chr(0) & Chr(232), "Alt+C", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_P, LEFT_ALT_PRESSED, Chr(0) & Chr(245), "Alt+P", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_R, LEFT_ALT_PRESSED, Chr(0) & Chr(247), "Alt+R", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_M, LEFT_ALT_PRESSED, Chr(0) & Chr(242), "Alt+M", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_J, LEFT_ALT_PRESSED, Chr(0) & Chr(239), "Alt+J", report) = 0 Then Return 0

    If CheckKeyTranslation(VK_F8, 0, Chr(0) & Chr(66), "F8", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_F9, 0, Chr(0) & Chr(67), "F9", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_TAB, 0, Chr(9), "Tab", report) = 0 Then Return 0
    If CheckKeyTranslation(VK_TAB, SHIFT_PRESSED, Chr(0) & Chr(15), "Shift+Tab", report) = 0 Then Return 0

    ' AltGr (Ctrl+Alt direito juntos, usado pra @/#/etc no layout PT-BR) NAO
    ' pode ser confundido com Alt+letra (mnemonico de menu) - senao digitar
    ' caractere composto abriria um menu no meio da digitacao.
    Dim altGrRec As KEY_EVENT_RECORD
    altGrRec.bKeyDown = 1
    altGrRec.wVirtualKeyCode = VK_A
    altGrRec.dwControlKeyState = LEFT_CTRL_PRESSED Or RIGHT_ALT_PRESSED
    altGrRec.uChar.UnicodeChar = 0
    Dim altGrText As String
    Dim altGrGot As Integer = TranslateKeyEvent(altGrRec, altGrText)
    If altGrGot <> 0 And altGrText = Chr(0) & Chr(230) Then
        report = "SMOKE KEYS FAIL: AltGr+A foi confundido com Alt+A (mnemonico do menu Arquivo)"
        Return 0
    End If

    report = "SMOKE KEYS OK: Ctrl+letra (C/X/V/A/Z/Y/F/H/L, os dois lados de Ctrl), Alt+letra (A/C/P/R/M/J), Shift+seta, Ctrl+seta/PgUp, Ctrl+Shift+seta, F8/F9, Tab/Shift+Tab, AltGr nao confundido com Alt, Shift+Del/Shift+Insert/Ctrl+Insert (atalhos MS-DOS de recortar/colar/copiar)"
    Return -1
End Function

Private Function TranslateMouseEvent(ByRef rec As MOUSE_EVENT_RECORD, ByRef mouseX As Integer, ByRef mouseY As Integer, ByRef mouseAction As Integer) As Integer
    mouseX = rec.dwMousePosition.X + 1
    mouseY = rec.dwMousePosition.Y + 1
    mouseAction = 0

    Dim leftNow As Integer = IIf((rec.dwButtonState And FROM_LEFT_1ST_BUTTON_PRESSED) <> 0, 1, 0)

    If rec.dwEventFlags = MOUSE_MOVED Then
        If leftNow <> 0 Then
            mouseAction = MSX_MOUSE_MOVE
        End If
    ElseIf rec.dwEventFlags = DOUBLE_CLICK Then
        mouseAction = MSX_MOUSE_DOWN
    ElseIf rec.dwEventFlags = MOUSE_WHEELED Then
        ' Delta do wheel fica na word alta de dwButtonState (com sinal).
        Dim wheelDelta As Short = Cast(Short, (rec.dwButtonState Shr 16) And &hFFFF)
        If wheelDelta > 0 Then
            mouseAction = MSX_MOUSE_WHEEL_UP
        ElseIf wheelDelta < 0 Then
            mouseAction = MSX_MOUSE_WHEEL_DOWN
        End If
    ElseIf rec.dwEventFlags = 0 Then
        If leftNow <> 0 And gMouseLeftDown = 0 Then
            mouseAction = MSX_MOUSE_DOWN
        ElseIf leftNow = 0 And gMouseLeftDown <> 0 Then
            mouseAction = MSX_MOUSE_UP
        End If
    End If

    gMouseLeftDown = leftNow
    Return IIf(mouseAction <> 0, -1, 0)
End Function

Function ConsolePollInput(ByRef eventType As Integer, ByRef keyText As String, ByRef mouseX As Integer, ByRef mouseY As Integer, ByRef mouseAction As Integer) As Integer
    eventType = MSX_INPUT_NONE
    keyText = ""
    mouseAction = 0

    Dim available As DWORD
    Dim tries As Integer

    For tries = 1 To 16
        If GetNumberOfConsoleInputEvents(gIn, @available) = 0 Then Return 0
        If available = 0 Then Return 0

        Dim ir As INPUT_RECORD
        Dim readCount As DWORD
        If ReadConsoleInput(gIn, @ir, 1, @readCount) = 0 Then Return 0
        If readCount = 0 Then Return 0

        Select Case ir.EventType
            Case INPUT_KEY_EVENT
                If TranslateKeyEvent(ir.Event.KeyEvent, keyText) <> 0 Then
                    eventType = MSX_INPUT_KEY
                    Return -1
                End If
            Case INPUT_MOUSE_EVENT
                If TranslateMouseEvent(ir.Event.MouseEvent, mouseX, mouseY, mouseAction) <> 0 Then
                    eventType = MSX_INPUT_MOUSE
                    Return -1
                End If
        End Select
    Next tries

    Return 0
End Function

Sub ConsoleResetInputState()
    gMouseLeftDown = 0
    If gIn <> 0 Then FlushConsoleInputBuffer(gIn)
    RestoreInputMode()
End Sub

Sub ConsoleClear(ByVal fg As UByte = 7, ByVal bg As UByte = 0)
    Dim y As Integer
    Dim x As Integer
    Dim attr As UShort = MakeAttr(fg, bg)

    For y = 1 To gH
        gRowText(y) = String(gW, " ")
        For x = 1 To gW
            gRowAttr(y, x) = attr
            gDirtyCell(y, x) = 1
        Next x
        gDirtyRowAny(y) = 1
    Next y
End Sub

Sub ConsoleSetCell(ByVal x As Integer, ByVal y As Integer, ByVal ch As UByte, ByVal fg As UByte = 7, ByVal bg As UByte = 0)
    If x < 1 Or x > gW Or y < 1 Or y > gH Then Exit Sub

    Mid(gRowText(y), x, 1) = Chr(ch)
    gRowAttr(y, x) = MakeAttr(fg, bg)
    MarkDirtyRange(y, x, x)
End Sub

' Converte texto UTF-8 (a codificacao em que os arquivos .md de ajuda e o
' banco de dados guardam o texto) para a codepage de saida realmente ativa
' no console (normalmente 860, definida em ConsoleInit; le a ativa de novo
' aqui em vez de assumir, caso o SO tenha recusado o SetConsoleOutputCP).
' Sem isso, cada acento vira 2-3 bytes UTF-8 exibidos como glifos errados.
Function ConsoleUtf8ToActiveCp(ByRef txt As String) As String
    Dim srcLen As Long = Len(txt)
    If srcLen <= 0 Then Return txt

    Dim targetCp As UInteger = GetConsoleOutputCP()
    If targetCp = 0 Then Return txt

    Dim wLen As Long = MultiByteToWideChar(CP_UTF8, 0, StrPtr(txt), srcLen, 0, 0)
    If wLen <= 0 Then Return txt

    Dim wBuf As Any Ptr = CAllocate((wLen + 1) * 2)
    If wBuf = 0 Then Return txt
    MultiByteToWideChar(CP_UTF8, 0, StrPtr(txt), srcLen, Cast(LPWSTR, wBuf), wLen)

    Dim outLen As Long = WideCharToMultiByte(targetCp, 0, Cast(LPCWCH, wBuf), wLen, 0, 0, 0, 0)
    If outLen <= 0 Then
        DeAllocate(wBuf)
        Return txt
    End If

    Dim outBuf As Any Ptr = CAllocate(outLen + 1)
    If outBuf = 0 Then
        DeAllocate(wBuf)
        Return txt
    End If
    WideCharToMultiByte(targetCp, 0, Cast(LPCWCH, wBuf), wLen, Cast(LPSTR, outBuf), outLen, 0, 0)

    Dim result As String = Space(outLen)
    CopyMemory(StrPtr(result), outBuf, outLen)

    DeAllocate(wBuf)
    DeAllocate(outBuf)

    Return result
End Function

' Integracao com a area de transferencia REAL do Windows (CF_UNICODETEXT) -
' sem isso, Ctrl+C/Ctrl+X/Ctrl+V do editor mexiam so' numa string interna
' do processo, e colar fora do msxide trazia o que estivesse no clipboard
' do Windows antes (nunca o que acabou de ser copiado/recortado dentro do
' editor). txt/o retorno usam a mesma codepage do console (GetConsoleOutputCP,
' normalmente 860) - o mesmo byte-a-byte que ConsoleSetCell ja espera.
Sub ConsoleSetClipboardText(ByRef text As String)
    Dim srcLen As Long = Len(text)
    Dim srcCp As UInteger = GetConsoleOutputCP()
    If srcCp = 0 Then srcCp = CP_OEMCP

    Dim wLen As Long = 0
    If srcLen > 0 Then
        wLen = MultiByteToWideChar(srcCp, 0, StrPtr(text), srcLen, 0, 0)
        If wLen < 0 Then wLen = 0
    End If

    If OpenClipboard(0) = 0 Then Exit Sub
    EmptyClipboard()

    Dim hMem As HGLOBAL = GlobalAlloc(GMEM_MOVEABLE, CULng((wLen + 1) * 2))
    If hMem <> 0 Then
        Dim wBuf As Any Ptr = GlobalLock(hMem)
        If wBuf <> 0 Then
            If wLen > 0 Then MultiByteToWideChar(srcCp, 0, StrPtr(text), srcLen, Cast(LPWSTR, wBuf), wLen)
            Cast(UShort Ptr, wBuf)[wLen] = 0
            GlobalUnlock(hMem)
            SetClipboardData(CF_UNICODETEXT, hMem)
        End If
    End If

    CloseClipboard()
End Sub

Function ConsoleGetClipboardText() As String
    Dim result As String = ""
    If IsClipboardFormatAvailable(CF_UNICODETEXT) = 0 Then Return ""
    If OpenClipboard(0) = 0 Then Return ""

    Dim hMem As HANDLE = GetClipboardData(CF_UNICODETEXT)
    If hMem <> 0 Then
        Dim wBuf As Any Ptr = GlobalLock(hMem)
        If wBuf <> 0 Then
            Dim wLen As Long = lstrlenW(Cast(LPCWSTR, wBuf))
            If wLen > 0 Then
                Dim targetCp As UInteger = GetConsoleOutputCP()
                If targetCp = 0 Then targetCp = CP_OEMCP

                Dim outLen As Long = WideCharToMultiByte(targetCp, 0, Cast(LPCWCH, wBuf), wLen, 0, 0, 0, 0)
                If outLen > 0 Then
                    Dim outBuf As Any Ptr = CAllocate(outLen + 1)
                    If outBuf <> 0 Then
                        WideCharToMultiByte(targetCp, 0, Cast(LPCWCH, wBuf), wLen, Cast(LPSTR, outBuf), outLen, 0, 0)
                        result = Space(outLen)
                        CopyMemory(StrPtr(result), outBuf, outLen)
                        DeAllocate(outBuf)
                    End If
                End If
            End If
            GlobalUnlock(hMem)
        End If
    End If

    CloseClipboard()
    Return result
End Function

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

    Dim i As Integer
    Dim attr As UShort = MakeAttr(fg, bg)
    For i = 0 To drawLen - 1
        gRowAttr(y, x + i) = attr
    Next i

    MarkDirtyRange(y, x, x + drawLen - 1)
End Sub

Sub ConsoleSetCursor(ByVal x As Integer, ByVal y As Integer, ByVal visible As Integer)
    x = Clamp(x, 1, gW)
    y = Clamp(y, 1, gH)

    Dim ci As CONSOLE_CURSOR_INFO
    ci.dwSize = 20
    ci.bVisible = IIf(visible <> 0, TRUE, FALSE)
    SetConsoleCursorInfo(gOut, @ci)
    gCursorVisible = visible

    Dim c As COORD
    c.X = x - 1
    c.Y = y - 1
    SetConsoleCursorPosition(gOut, c)
End Sub

Sub ConsoleBeginFrame()
    gFrameCharCalls = 0
    gFrameAttrCalls = 0
    gFrameFillCalls = 0
End Sub

Sub ConsoleFlush()
    Dim y As Integer
    For y = 1 To gH
        If gDirtyRowAny(y) <> 0 Then
            Dim x As Integer = 1

            Dim hasPendingAttrBatch As Integer = 0
            Dim pendingAttr As UShort = 0
            Dim pendingStart As Integer = 0
            Dim pendingEnd As Integer = 0

            Dim written As DWORD
            Do While x <= gW
                While x <= gW And gDirtyCell(y, x) = 0
                    x += 1
                Wend
                If x > gW Then Exit Do

                Dim x1 As Integer = x
                While x <= gW And gDirtyCell(y, x) <> 0
                    x += 1
                Wend
                Dim x2 As Integer = x - 1
                Dim runLen As Integer = x2 - x1 + 1

                Dim c As COORD
                c.X = x1 - 1
                c.Y = y - 1

                Dim textPtr As ZString Ptr = Cast(ZString Ptr, Cast(UByte Ptr, StrPtr(gRowText(y))) + (x1 - 1))

                Dim i As Integer
                For i = x1 To x2
                    gDirtyCell(y, i) = 0
                Next i

                WriteConsoleOutputCharacter(gOut, textPtr, runLen, c, @written)
                gFrameCharCalls += 1
                gTotalCharCalls += 1

                Dim runAttr As UShort
                Dim runIsUniform As Integer = IsUniformAttr(y, x1, x2, runAttr)

                If runIsUniform <> 0 Then
                    If hasPendingAttrBatch = 0 Then
                        hasPendingAttrBatch = 1
                        pendingAttr = runAttr
                        pendingStart = x1
                        pendingEnd = x2
                    Else
                        Dim canMerge As Integer = 0
                        If runAttr = pendingAttr Then
                            If x1 = pendingEnd + 1 Then
                                canMerge = -1
                            ElseIf x1 > pendingEnd + 1 Then
                                ' Permite mesclar atravessando gaps se o gap tambem usa o mesmo atributo.
                                If IsRangeAttr(y, pendingEnd + 1, x1 - 1, pendingAttr) <> 0 Then
                                    canMerge = -1
                                End If
                            End If
                        End If

                        If canMerge <> 0 Then
                            pendingEnd = x2
                        Else
                            Dim cAttr As COORD
                            cAttr.X = pendingStart - 1
                            cAttr.Y = y - 1
                            FillConsoleOutputAttribute(gOut, pendingAttr, pendingEnd - pendingStart + 1, cAttr, @written)
                            gFrameFillCalls += 1
                            gTotalFillCalls += 1

                            pendingAttr = runAttr
                            pendingStart = x1
                            pendingEnd = x2
                        End If
                    End If
                Else
                    If hasPendingAttrBatch <> 0 Then
                        Dim cAttr As COORD
                        cAttr.X = pendingStart - 1
                        cAttr.Y = y - 1
                        FillConsoleOutputAttribute(gOut, pendingAttr, pendingEnd - pendingStart + 1, cAttr, @written)
                        gFrameFillCalls += 1
                        gTotalFillCalls += 1
                        hasPendingAttrBatch = 0
                    End If

                    Dim attrPtr As UShort Ptr = @gRowAttr(y, x1)
                    WriteConsoleOutputAttribute(gOut, attrPtr, runLen, c, @written)
                    gFrameAttrCalls += 1
                    gTotalAttrCalls += 1
                End If
            Loop

            If hasPendingAttrBatch <> 0 Then
                Dim cAttr As COORD
                cAttr.X = pendingStart - 1
                cAttr.Y = y - 1
                FillConsoleOutputAttribute(gOut, pendingAttr, pendingEnd - pendingStart + 1, cAttr, @written)
                gFrameFillCalls += 1
                gTotalFillCalls += 1
            End If

            gDirtyRowAny(y) = 0
        End If
    Next y
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
    available = 0
    enabled = 0
    x = 0
    y = 0
End Sub
