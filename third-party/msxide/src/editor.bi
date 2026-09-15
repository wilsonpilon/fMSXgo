#ifndef __EDITOR_BI__
#define __EDITOR_BI__

Const MAX_DOCS = 8
Const MAX_LINES = 2000
Const SCREEN_W = 100
Const SCREEN_H = 35

' Historico de undo/redo: cada nivel guarda o buffer inteiro serializado
' como UMA string (linhas juntadas por Chr(10), lineCount guardado a parte
' pra reconstruir sem ambiguidade quando ha linhas em branco no final) -
' bem mais barato de copiar/mover que um array de MAX_LINES strings por
' nivel (o que pesaria MUITO em BringDocumentToFront/CloseDocument, que já
' fazem docs(i) = docs(i+1) a cada troca de janela).
Const MAX_UNDO = 40

Type UndoSnapshot
    text As String
    lineCount As Integer
    cursorX As Integer
    cursorY As Integer
End Type

Type Document
    title As String
    filePath As String
    isHelp As Integer
    isMamuteTerm As Integer
    isMamuteEdit As Integer
    isMarkdown As Integer
    mdViewMode As Integer
    mdPreviewScrollY As Integer
    mdPreviewDirty As Integer
    isPixelEditor As Integer
    pixelEditKind As Integer
    pixelEditSelectedChar As Integer
    pixelEditZoomed As Integer
    pixelEditCursorRow As Integer
    pixelEditCursorCol As Integer
    pixelEditOverviewTop As Integer
    pixelEditBaseAddr As Integer
    pixelEditListFocus As Integer
    pixelEditListSelected As Integer
    pixelEditListScrollTop As Integer
    spriteSize As Integer
    spriteColorMode As Integer
    spriteColors(1 To MAX_LINES) As String
    helpTitle As String
    helpWrapWidth As Integer
    diskBaselineText As String ' ultimo conteudo lido/gravado em disco - ver EditorCheckExternalChanges
    lineCount As Integer
    lines(1 To MAX_LINES) As String
    cursorX As Integer
    cursorY As Integer
    scrollX As Integer
    scrollY As Integer
    winX As Integer
    winY As Integer
    winW As Integer
    winH As Integer
    isMaximized As Integer
    normalX As Integer
    normalY As Integer
    normalW As Integer
    normalH As Integer
    selActive As Integer
    selAnchorX As Integer
    selAnchorY As Integer
    undoTop As Integer
    redoTop As Integer
    undoRunKind As Integer
    undoRunAtX As Integer
    undoRunAtY As Integer
    undoStack(1 To MAX_UNDO) As UndoSnapshot
    redoStack(1 To MAX_UNDO) As UndoSnapshot
End Type

Declare Sub EditorInit(ByRef startupName As String)
Declare Sub EditorOpenFromPath(ByRef path As String)
Declare Sub EditorCreateUntitled()
Declare Sub EditorDraw(ByVal menuOpen As Integer)
Declare Sub EditorHandleKey(ByRef keyText As String, ByRef running As Integer, ByRef menuOpen As Integer)
Declare Sub EditorHandleMouse(ByVal mouseX As Integer, ByVal mouseY As Integer, ByVal mouseAction As Integer, ByRef running As Integer, ByRef menuOpen As Integer)
Declare Sub EditorSaveAllToDb()
Declare Sub EditorShutdown()
Declare Function EditorRunHelpSmokeTest(ByRef report As String) As Integer
Declare Function EditorRunTextEditSmokeTest(ByRef report As String) As Integer
Declare Function EditorRunMamuteSmokeTest(ByRef report As String) As Integer
Declare Function EditorRunMamuteDiag(ByRef report As String) As Integer
Declare Function EditorCheckExternalChanges() As Integer

#endif
