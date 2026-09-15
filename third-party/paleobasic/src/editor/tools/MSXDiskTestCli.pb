;
; ------------------------------------------------------------
;  Ferramenta de linha de comando para testar o modulo de disco MSX
;  (editor\MSXDisk.pbi, vendorizado de ../../msxDiskUtil) sem precisar
;  abrir o editor.
;
;  Roda um round-trip completo contra uma imagem .dsk descartavel: cria o
;  disco, injeta 2 arquivos locais, lista o conteudo, extrai um deles de
;  volta para outro caminho e compara byte a byte, apaga o outro e lista
;  de novo para confirmar a remocao. Serve para provar que TODAS as
;  funcoes do modulo (nao so CreateDisk/AddFile/CloseDisk, que e o unico
;  caminho ja exercitado pelo editor via RunOnOpenMSX) continuam
;  funcionando quando compiladas dentro do executavel (sem chamar
;  msxdisk.exe/DLL como processo externo).
;
;  Uso:
;    MSXDiskTestCli.exe <pasta_de_trabalho>
;      <pasta_de_trabalho>  pasta onde o .dsk de teste e os arquivos de
;                           entrada/saida serao criados (apagada e
;                           recriada a cada execucao)
;
;  Compilar com:
;    "C:\Basic\Compilers\pbcompiler.exe" editor\tools\MSXDiskTestCli.pb /EXE editor\tools\MSXDiskTestCli.exe /CONSOLE
; ------------------------------------------------------------
;

EnableExplicit
OpenConsole()

XIncludeFile "..\core\MSXDisk.pbi"

Define WorkDir.s = ProgramParameter(0)
If WorkDir = ""
  PrintN("Uso: MSXDiskTestCli.exe <pasta_de_trabalho>")
  End 1
EndIf
If Right(WorkDir, 1) <> "\" And Right(WorkDir, 1) <> "/"
  WorkDir + "\"
EndIf

Define Failures = 0

Procedure CheckTrue(Ok.i, Label.s)
  Shared Failures
  If Ok
    PrintN("OK   - " + Label)
  Else
    PrintN("FALHA - " + Label + " -> " + MSXDisk::GetLastErrorMessage())
    Failures + 1
  EndIf
EndProcedure

If FileSize(WorkDir) <> -2
  CreateDirectory(WorkDir)
EndIf

Define DiskPath.s = WorkDir + "test.dsk"
Define FileA.s = WorkDir + "input_a.txt"
Define FileB.s = WorkDir + "input_b.txt"
Define ExtractedA.s = WorkDir + "extracted_a.txt"

Define ContentA.s = "Hello MSX disk A - " + Str(Random(999999))
Define ContentB.s = "Hello MSX disk B - " + Str(Random(999999))

Define f = CreateFile(#PB_Any, FileA) : WriteString(f, ContentA) : CloseFile(f)
f = CreateFile(#PB_Any, FileB) : WriteString(f, ContentB) : CloseFile(f)

; 1) CreateDisk
CheckTrue(MSXDisk::CreateDisk(DiskPath), "CreateDisk(" + DiskPath + ")")

; 2) AddFile x2
CheckTrue(MSXDisk::AddFile(FileA, "FILEA.TXT"), "AddFile FILEA.TXT")
CheckTrue(MSXDisk::AddFile(FileB, "FILEB.TXT"), "AddFile FILEB.TXT")

; 3) ListFiles - espera 2 arquivos
NewList Files1.MSXDisk::FileInfo()
Define Listed1.i = MSXDisk::ListFiles(Files1())
CheckTrue(Bool(Listed1 And ListSize(Files1()) = 2), "ListFiles apos add (esperado 2, achou " + Str(ListSize(Files1())) + ")")
ForEach Files1()
  PrintN("     -> " + Files1()\FileName + " (" + Str(Files1()\Size) + " bytes)")
Next

; 4) ExtractFile - compara conteudo byte a byte
CheckTrue(MSXDisk::ExtractFile("FILEA.TXT", ExtractedA), "ExtractFile FILEA.TXT")
Define fr = ReadFile(#PB_Any, ExtractedA)
Define ExtractedContent.s = ""
If fr
  ExtractedContent = ReadString(fr, #PB_File_IgnoreEOL)
  CloseFile(fr)
EndIf
CheckTrue(Bool(ExtractedContent = ContentA), "Conteudo extraido bate com o original (" + Str(Len(ContentA)) + " bytes)")

; 5) DeleteMSXFile
CheckTrue(MSXDisk::DeleteMSXFile("FILEB.TXT"), "DeleteMSXFile FILEB.TXT")

; 6) ListFiles de novo - espera 1 arquivo (so FILEA.TXT sobrou)
NewList Files2.MSXDisk::FileInfo()
Define Listed2.i = MSXDisk::ListFiles(Files2())
CheckTrue(Bool(Listed2 And ListSize(Files2()) = 1), "ListFiles apos delete (esperado 1, achou " + Str(ListSize(Files2())) + ")")

; 7) CloseDisk + OpenDisk (reabre o mesmo .dsk do zero, ve se persistiu em disco)
MSXDisk::CloseDisk()
CheckTrue(MSXDisk::OpenDisk(DiskPath), "OpenDisk (reabrindo apos CloseDisk)")
NewList Files3.MSXDisk::FileInfo()
Define Listed3.i = MSXDisk::ListFiles(Files3())
CheckTrue(Bool(Listed3 And ListSize(Files3()) = 1), "ListFiles apos reabrir do disco (esperado 1, achou " + Str(ListSize(Files3())) + ")")
MSXDisk::CloseDisk()

; 8) ConvertToFAT11 / MatchesFAT11 (usados por extract/delete, testados isolados aqui)
Define FAT11.s = MSXDisk::ConvertToFAT11("filea.txt")
Define FAT11Mask.s = MSXDisk::ConvertToFAT11("FILE*.TXT")
CheckTrue(MSXDisk::MatchesFAT11(FAT11, FAT11Mask), "MatchesFAT11 com curinga (FILE*.TXT casa filea.txt)")

PrintN("")
If Failures = 0
  PrintN("TODOS OS TESTES PASSARAM.")
  End 0
Else
  PrintN(Str(Failures) + " TESTE(S) FALHARAM.")
  End 1
EndIf
