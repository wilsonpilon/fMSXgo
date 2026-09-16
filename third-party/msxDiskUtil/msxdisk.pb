; *************************************************************
; **                                                         **
; **                msxdisk.pb                               **
; **                                                         **
; ** MSX Floppy Disk Utility - Console CLI Interface        **
; **                                                         **
; ** Uses MSXDisk.pbi for file system logic.                 **
; **                                                         **
; *************************************************************

XIncludeFile "version.pbi"
XIncludeFile "MSXDisk.pbi"

Procedure ShowHelp()
  PrintN("MSX Disk Manager Utility v" + #VERSION$ + " Build " + #BUILD$ + " (PureBasic)")
  PrintN("Uso: msxdisk <comando> <imagem_disco.dsk> [argumentos...]")
  PrintN("")
  PrintN("Comandos disponíveis:")
  PrintN("  create <disk.dsk> [bootsector.bin]")
  PrintN("            Cria uma nova imagem de disco MSX em branco (720KB).")
  PrintN("            Opcionalmente, pode ser informado um setor de boot customizado.")
  PrintN("")
  PrintN("  list <disk.dsk> [-l]")
  PrintN("            Lista os arquivos contidos no disco.")
  PrintN("            Use '-l' para visualização detalhada (tamanho, data/hora).")
  PrintN("")
  PrintN("  add <disk.dsk> <local_file1> [local_file2 ...]")
  PrintN("            Adiciona um ou mais arquivos locais ao disco MSX.")
  PrintN("            Suporta curingas locais (ex: *.TXT, *.BAS).")
  PrintN("")
  PrintN("  extract <disk.dsk> [-d out_dir] [mask1 mask2 ...]")
  PrintN("            Extrai arquivos do disco MSX.")
  PrintN("            Use '-d out_dir' para especificar a pasta de destino.")
  PrintN("            Opcionalmente, passe máscaras de arquivos (ex: *.BAS, AUTOEXEC.BAT).")
  PrintN("")
  PrintN("  delete <disk.dsk> <filename>")
  PrintN("            Exclui um arquivo da imagem de disco MSX.")
  PrintN("")
EndProcedure

Procedure AddFilesWithWildcards(FilePattern$)
  Protected Dir$ = GetPathPart(FilePattern$)
  Protected Pattern$ = GetFilePart(FilePattern$)
  
  If Dir$ = ""
    Dir$ = "." + #PS$
  EndIf
  
  If FindString(Pattern$, "*") Or FindString(Pattern$, "?")
    Protected d = ExamineDirectory(#PB_Any, Dir$, Pattern$)
    If d
      Protected cnt = 0
      While NextDirectoryEntry(d)
        If DirectoryEntryType(d) = #PB_DirectoryEntry_File
          Protected fileName$ = DirectoryEntryName(d)
          Protected fullPath$ = Dir$ + fileName$
          Print("Adicionando: " + fileName$ + " ... ")
          If Not MSXDisk::AddFile(fullPath$, fileName$)
            PrintN("FALHA: " + MSXDisk::GetLastErrorMessage())
          Else
            PrintN("OK")
            cnt + 1
          EndIf
        EndIf
      Wend
      FinishDirectory(d)
      PrintN(Str(cnt) + " arquivo(s) adicionado(s).")
    Else
      PrintN("Nenhum arquivo encontrado correspondendo a: " + FilePattern$)
    EndIf
  Else
    Print("Adicionando: " + Pattern$ + " ... ")
    If Not MSXDisk::AddFile(FilePattern$, Pattern$)
      PrintN("FALHA: " + MSXDisk::GetLastErrorMessage())
    Else
      PrintN("OK")
      PrintN("1 arquivo adicionado.")
    EndIf
  EndIf
EndProcedure

Procedure Main()
  If Not OpenConsole()
    End 1
  EndIf
  
  Protected count = CountProgramParameters()
  If count < 2
    ShowHelp()
    CloseConsole()
    End 0
  EndIf
  
  Protected cmd$ = LCase(ProgramParameter(0))
  Protected disk$ = ProgramParameter(1)
  
  Select cmd$
    Case "create"
      Protected boot$ = ""
      If count > 2
        boot$ = ProgramParameter(2)
      EndIf
      
      PrintN("Criando disco: " + disk$ + " ...")
      If MSXDisk::CreateDisk(disk$, boot$)
        PrintN("Disco criado e formatado com sucesso (720KB).")
        MSXDisk::CloseDisk()
      Else
        PrintN("Erro ao criar o disco: " + MSXDisk::GetLastErrorMessage())
        CloseConsole()
        End 1
      EndIf
      
    Case "list"
      Protected detailed = #False
      If count > 2 And ProgramParameter(2) = "-l"
        detailed = #True
      EndIf
      
      If Not MSXDisk::OpenDisk(disk$)
        PrintN("Erro ao abrir disco: " + MSXDisk::GetLastErrorMessage())
        CloseConsole()
        End 1
      EndIf
      
      NewList files.MSXDisk::FileInfo()
      If MSXDisk::ListFiles(files())
        If detailed
          PrintN("Nome         Tamanho     Data / Hora")
          PrintN("---------------------------------------------")
          ForEach files()
            Protected dt$ = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", files()\DateTime)
            PrintN(LSet(files()\FileName, 12) + " " + RSet(Str(files()\Size), 8) + "    " + dt$)
          Next
        Else
          ForEach files()
            PrintN(files()\FileName)
          Next
        EndIf
      Else
        PrintN("Erro ao listar arquivos: " + MSXDisk::GetLastErrorMessage())
      EndIf
      MSXDisk::CloseDisk()
      
    Case "add"
      If Not MSXDisk::OpenDisk(disk$)
        PrintN("Erro ao abrir disco: " + MSXDisk::GetLastErrorMessage())
        CloseConsole()
        End 1
      EndIf
      
      Protected i
      For i = 2 To count - 1
        AddFilesWithWildcards(ProgramParameter(i))
      Next
      
      MSXDisk::CloseDisk()
      
    Case "extract"
      Protected outDir$ = ""
      Protected maskStart = 2
      
      If count > 2 And ProgramParameter(2) = "-d"
        If count > 3
          outDir$ = ProgramParameter(3)
          maskStart = 4
        Else
          PrintN("Erro: Diretorio de saida nao especificado apos -d.")
          CloseConsole()
          End 1
        EndIf
      EndIf
      
      If Not MSXDisk::OpenDisk(disk$)
        PrintN("Erro ao abrir disco: " + MSXDisk::GetLastErrorMessage())
        CloseConsole()
        End 1
      EndIf
      
      NewList masks$()
      For i = maskStart To count - 1
        AddElement(masks$())
        masks$() = MSXDisk::ConvertToFAT11(ProgramParameter(i))
      Next
      
      If outDir$ <> ""
        ; Create outDir if it doesn't exist
        If FileSize(outDir$) <> -2
          CreateDirectory(outDir$)
        EndIf
        If Right(outDir$, 1) <> #PS$
          outDir$ + #PS$
        EndIf
      EndIf
      
      NewList files.MSXDisk::FileInfo()
      If MSXDisk::ListFiles(files())
        Protected cnt = 0
        ForEach files()
          Protected match = #False
          If ListSize(masks$()) = 0
            match = #True
          Else
            ForEach masks$()
              If MSXDisk::MatchesFAT11(MSXDisk::ConvertToFAT11(files()\FileName), masks$())
                match = #True
                Break
              EndIf
            Next
          EndIf
          
          If match
            Protected dest$ = outDir$ + files()\FileName
            Print("Extraindo: " + files()\FileName + " -> " + dest$ + " ... ")
            If MSXDisk::ExtractFile(files()\FileName, dest$)
              PrintN("OK")
              cnt + 1
            Else
              PrintN("FALHA: " + MSXDisk::GetLastErrorMessage())
            EndIf
          EndIf
        Next
        PrintN(Str(cnt) + " arquivo(s) extraido(s).")
      Else
        PrintN("Erro ao ler arquivos do disco: " + MSXDisk::GetLastErrorMessage())
      EndIf
      MSXDisk::CloseDisk()
      
    Case "delete"
      If count < 3
        PrintN("Erro: Nome do arquivo a ser excluido nao informado.")
        CloseConsole()
        End 1
      EndIf
      
      Protected fileToDelete$ = ProgramParameter(2)
      If Not MSXDisk::OpenDisk(disk$)
        PrintN("Erro ao abrir disco: " + MSXDisk::GetLastErrorMessage())
        CloseConsole()
        End 1
      EndIf
      
      Print("Excluindo: " + fileToDelete$ + " ... ")
      If MSXDisk::DeleteMSXFile(fileToDelete$)
        PrintN("OK")
      Else
        PrintN("FALHA: " + MSXDisk::GetLastErrorMessage())
      EndIf
      MSXDisk::CloseDisk()
      
    Default
      ShowHelp()
  EndSelect
  
  CloseConsole()
EndProcedure

Main()
