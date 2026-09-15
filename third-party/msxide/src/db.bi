#ifndef __DB_BI__
#define __DB_BI__

Declare Sub DbInit(ByRef dbPath As String)
Declare Sub DbShutdown()
Declare Sub DbSetSetting(ByRef keyName As String, ByRef keyValue As String)
Declare Function DbGetSetting(ByRef keyName As String, ByRef fallback As String = "") As String
Declare Function DbGetHelpDoc(ByRef docName As String, ByRef fallbackPath As String = "") As String
Declare Function DbGetConfigDocument(ByRef configGroup As String) As String
Declare Sub DbSaveConfigDocument(ByRef configGroup As String, ByRef content As String)
Declare Sub DbSaveDocumentState(ByRef title As String, ByRef filePath As String, ByVal cursorX As Integer, ByVal cursorY As Integer)
Declare Sub DbSavePerfSecond(ByRef backendVersion As String, ByRef bucketTime As String, ByVal frameCount As Integer, ByVal avgChar As Double, ByVal avgAttr As Double, ByVal avgFill As Double, ByVal p95Char As Double, ByVal p95Attr As Double, ByVal p95Fill As Double)

Declare Sub DbProjectClose()
Declare Function DbProjectOpen(ByRef dbPath As String) As Integer
Declare Function DbProjectIsActive() As Integer
Declare Sub DbProjectSetMeta(ByRef keyName As String, ByRef keyValue As String)
Declare Function DbProjectGetMeta(ByRef keyName As String, ByRef fallback As String = "") As String
Declare Sub DbProjectSetConfig(ByRef keyName As String, ByRef keyValue As String)
Declare Function DbProjectConfigExists(ByRef keyName As String) As Integer
Declare Function DbProjectGetConfig(ByRef keyName As String, ByRef fallback As String = "") As String
Declare Sub DbProjectSetFile(ByRef relPath As String, ByRef content As String)
Declare Function DbProjectGetFile(ByRef relPath As String, ByRef found As Integer) As String
Declare Sub DbProjectListFiles(paths() As String, ByRef count As Integer)
Declare Function DbProjectCopyFromTemplate(ByRef templatePath As String) As Integer

#endif
