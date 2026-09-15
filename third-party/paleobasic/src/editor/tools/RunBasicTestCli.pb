;
; ------------------------------------------------------------
;  Ferramenta de linha de comando para testar o pipeline do menu
;  "Executar -> BASIC" (F5, BadigEditor.pb: RunBasicFromActiveTab() /
;  RunOnOpenMSX()) sem precisar abrir o editor nem o openMSX de verdade.
;
;  Reproduz os mesmos passos que RunOnOpenMSX() faz para montar o disco de
;  execucao: preprocessa Dignified -> ASCII, tokeniza para .bmx, escreve
;  .dmx/.amx/.bmx + AUTOEXEC.BAS num disco novo, depois reabre o disco e
;  confere que os 4 arquivos batem byte a byte com o que foi escrito
;  (nao chama o openMSX - so a montagem do disco, que e a parte nova
;  exercitada pelo menu).
;
;  Uso:
;    RunBasicTestCli.exe <entrada.dmx> <pasta_de_trabalho>
; ------------------------------------------------------------
;

EnableExplicit
OpenConsole()

XIncludeFile "..\core\DignifiedPreprocessor.pbi"
XIncludeFile "..\core\MsxTokenizer.pbi"
XIncludeFile "..\core\MSXDisk.pbi"

Define InPath.s = ProgramParameter(0)
Define WorkDir.s = ProgramParameter(1)
If InPath = "" Or WorkDir = ""
  PrintN("Uso: RunBasicTestCli.exe <entrada.dmx> <pasta_de_trabalho>")
  End 1
EndIf
If Right(WorkDir, 1) <> "\" And Right(WorkDir, 1) <> "/"
  WorkDir + "\"
EndIf
If FileSize(WorkDir) <> -2
  CreateDirectory(WorkDir)
EndIf

Define Failures = 0
Procedure CheckTrue(Ok.i, Label.s, Detail.s = "")
  Shared Failures
  If Ok
    PrintN("OK   - " + Label)
  Else
    PrintN("FALHA - " + Label + " -> " + Detail)
    Failures + 1
  EndIf
EndProcedure

; 1) Le o .dmx de entrada (mesmo fixture de regressao do projeto)
Define fnum = ReadFile(#PB_Any, InPath, #PB_File_BOM)
If Not fnum
  PrintN("Nao foi possivel abrir: " + InPath)
  End 1
EndIf
Define DmxSource.s = ""
While Not Eof(fnum)
  DmxSource + ReadString(fnum, #PB_File_IgnoreEOL) + Chr(13) + Chr(10)
Wend
CloseFile(fnum)

; 2) Preprocessa (Dignified -> ASCII classico) - mesmo que RunDignifiedPreprocessor()
Define AsciiOut.s = Dig_Preprocess(DmxSource, GetPathPart(InPath))
CheckTrue(Bool(Not Dig_HasError), "Dig_Preprocess sem erro", "linha " + Str(Dig_ErrorLine) + ": " + Dig_ErrorMsg)
If Dig_HasError : End 1 : EndIf

; 3) Tokeniza - mesmo que RunBasicFromActiveTab()
Define HexOut.s = Tok_Tokenize(AsciiOut)
CheckTrue(Bool(Not Tok_HasError), "Tok_Tokenize sem erro", "linha " + Str(Tok_ErrorLine) + ": " + Tok_ErrorMsg)
If Tok_HasError : End 1 : EndIf

; 4) Monta os arquivos locais + AUTOEXEC.BAS - mesma logica de RunOnOpenMSX()
Define BaseName.s = GetFilePart(InPath, #PB_FileSystem_NoExtension)
Define UBase.s = UCase(BaseName)

Define DmxLocal.s = WorkDir + BaseName + ".dmx"
Define AmxLocal.s = WorkDir + BaseName + ".amx"
Define BmxLocal.s = WorkDir + BaseName + ".bmx"
Define AutoexecLocal.s = WorkDir + "autoexec.bas"
Define AutoexecContent.s = "10 RUN " + Chr(34) + UBase + ".BMX" + Chr(34) + Chr(13) + Chr(10)

Define f = CreateFile(#PB_Any, DmxLocal) : WriteString(f, DmxSource) : CloseFile(f)
f = CreateFile(#PB_Any, AmxLocal) : WriteString(f, AsciiOut) : CloseFile(f)
CheckTrue(Tok_SaveHexAsBinary(HexOut, BmxLocal), "Gravar " + BmxLocal)
f = CreateFile(#PB_Any, AutoexecLocal) : WriteString(f, AutoexecContent) : CloseFile(f)

; 5) Monta o disco - mesma logica de RunOnOpenMSX()
Define DiskPath.s = WorkDir + "run_test.dsk"
CheckTrue(MSXDisk::CreateDisk(DiskPath), "CreateDisk", MSXDisk::GetLastErrorMessage())

Define Ok.b = #True
If Ok : Ok = MSXDisk::AddFile(DmxLocal, UBase + ".DMX") : EndIf
If Ok : Ok = MSXDisk::AddFile(AmxLocal, UBase + ".AMX") : EndIf
If Ok : Ok = MSXDisk::AddFile(BmxLocal, UBase + ".BMX") : EndIf
If Ok : Ok = MSXDisk::AddFile(AutoexecLocal, "AUTOEXEC.BAS") : EndIf
CheckTrue(Ok, "AddFile dos 4 arquivos (DMX/AMX/BMX/AUTOEXEC.BAS)", MSXDisk::GetLastErrorMessage())
MSXDisk::CloseDisk()

; 6) Reabre o disco do zero e confere os 4 arquivos byte a byte
CheckTrue(MSXDisk::OpenDisk(DiskPath), "OpenDisk (reabrindo do zero)")

NewList Files.MSXDisk::FileInfo()
Define Listed.i = MSXDisk::ListFiles(Files())
CheckTrue(Bool(Listed And ListSize(Files()) = 4), "ListFiles (esperado 4, achou " + Str(ListSize(Files())) + ")")
ForEach Files()
  PrintN("     -> " + Files()\FileName + " (" + Str(Files()\Size) + " bytes)")
Next

Procedure.b ExtractAndCompare(MsxName.s, OriginalLocalPath.s, OutDir.s)
  Protected ExtractedPath.s = OutDir + "extracted_" + MsxName
  If Not MSXDisk::ExtractFile(MsxName, ExtractedPath)
    ProcedureReturn #False
  EndIf
  Protected OrigSize.q = FileSize(OriginalLocalPath)
  Protected ExtSize.q = FileSize(ExtractedPath)
  If OrigSize <> ExtSize
    ProcedureReturn #False
  EndIf
  Protected o = ReadFile(#PB_Any, OriginalLocalPath)
  Protected e = ReadFile(#PB_Any, ExtractedPath)
  Protected Equal.b = #True
  While Not Eof(o) And Equal
    If ReadByte(o) <> ReadByte(e) : Equal = #False : EndIf
  Wend
  CloseFile(o) : CloseFile(e)
  ProcedureReturn Equal
EndProcedure

CheckTrue(ExtractAndCompare(UBase + ".DMX", DmxLocal, WorkDir), "Extrair e comparar " + UBase + ".DMX")
CheckTrue(ExtractAndCompare(UBase + ".AMX", AmxLocal, WorkDir), "Extrair e comparar " + UBase + ".AMX")
CheckTrue(ExtractAndCompare(UBase + ".BMX", BmxLocal, WorkDir), "Extrair e comparar " + UBase + ".BMX")
CheckTrue(ExtractAndCompare("AUTOEXEC.BAS", AutoexecLocal, WorkDir), "Extrair e comparar AUTOEXEC.BAS")

MSXDisk::CloseDisk()

PrintN("")
If Failures = 0
  PrintN("TODOS OS TESTES PASSARAM.")
  End 0
Else
  PrintN(Str(Failures) + " TESTE(S) FALHARAM.")
  End 1
EndIf
