;
; ------------------------------------------------------------
;  Z80SubProject.pbi - motor (sem GUI) do "subprojeto de Assembly" (Criar ->
;  Assembly Sub Project..., ver Z80SubProjectGui.pbi): um "Makefile
;  primitivo" que monta uma lista ordenada de fontes .asm em .REL (Z80Asm::
;  AssembleRelocatable), resolve as bibliotecas referenciadas via .REQUEST e
;  linka tudo (Z80Link::LinkFiles) num binario final - persistencia da lista
;  de arquivos em ProjectDB::StoreAsmSubProject/FetchAsmSubProject. Tambem
;  sabe empacotar um subconjunto de .asm do subprojeto numa biblioteca
;  (Z80Lib::CreateOrAddLibrary), pro caso de "quero gerar uma lib com estas
;  rotinas pra reusar depois".
;
;  Z80Link::LinkFiles so aceita UMA pasta de biblioteca (LibraryDir) - as
;  bibliotecas escolhidas pelo usuario, de qualquer lugar do disco, sao
;  copiadas pra uma pasta de trabalho temporaria ANTES do link (ver
;  Z80SubProj_StageLibraries) com o nome renomeado pra "<base>.rel", unica
;  extensao que Z80Link::LResolveLibPath realmente procura quando resolve um
;  nome de .REQUEST (sempre anexa ".rel" a qualquer nome que nao termine
;  exatamente em ".REL" - mesmo que o arquivo original tenha sido salvo como
;  ".lib" por Criar -> Biblioteca Z80...).
; ------------------------------------------------------------
;

Global Z80SubProj_LastError.s = ""
Global Z80SubProj_LastStartAddr.u = 0
Global Z80SubProj_LastEndAddr.u = 0

Procedure.s Z80SubProj_GetLastError()
  ProcedureReturn Z80SubProj_LastError
EndProcedure

Procedure.u Z80SubProj_GetBuildStartAddr()
  ProcedureReturn Z80SubProj_LastStartAddr
EndProcedure

Procedure.u Z80SubProj_GetBuildEndAddr()
  ProcedureReturn Z80SubProj_LastEndAddr
EndProcedure

; Le um arquivo texto inteiro do disco (deteccao de BOM + reconstroi quebras
; de linha CRLF, mesmo padrao de OpenDocumentDialog() em BadigEditor.pb) -
; precisa ser independente de qualquer aba aberta, porque o subprojeto monta
; arquivos direto do disco, nao do editor.
; NOTA: parece um loop linha-a-linha (e por isso um audit anterior marcou
; isto como concatenacao O(n^2)), mas NAO e - ReadString(FileNum,
; #PB_File_IgnoreEOL) SEM parametro Length le o restante do arquivo INTEIRO
; numa unica chamada (confirmado na pratica: loop roda exatamente 1x
; independente do tamanho do arquivo), entao isto ja e O(n). Mantido como
; estava.
Procedure.s Z80SubProj_ReadTextFile(Path.s)
  Protected FileNum = ReadFile(#PB_Any, Path, #PB_File_BOM)
  If Not FileNum
    ProcedureReturn ""
  EndIf
  Protected Content.s = ""
  While Not Eof(FileNum)
    Content + ReadString(FileNum, #PB_File_IgnoreEOL) + Chr(13) + Chr(10)
  Wend
  CloseFile(FileNum)
  ProcedureReturn Content
EndProcedure

; Monta UM .asm (lido do disco) em .REL, salvando em RelOutPath. Nome do
; "programa" dentro do .REL = nome do arquivo sem extensao, maiusculo (mesma
; convencao de AssembleZ80RelFromActiveTab em BadigEditor.pb).
Procedure.i Z80SubProj_AssembleToRel(AsmPath.s, RelOutPath.s)
  If FileSize(AsmPath) < 0
    Z80SubProj_LastError = "Arquivo nao encontrado: " + AsmPath
    ProcedureReturn #False
  EndIf

  Protected SourceText.s = Z80SubProj_ReadTextFile(AsmPath)
  Protected ProgramName.s = UCase(GetFilePart(AsmPath, #PB_FileSystem_NoExtension))
  Protected Dim RelBytes.a(65535)
  Protected N = Z80Asm::AssembleRelocatable(SourceText, ProgramName, RelBytes())

  If N < 0
    Z80SubProj_LastError = GetFilePart(AsmPath) + " (linha " + Str(Z80Asm::GetAssembleErrorLine()) + "): " +
                            Z80Asm::GetAssembleErrorText()
    ProcedureReturn #False
  EndIf
  If N = 0
    Z80SubProj_LastError = GetFilePart(AsmPath) + ": nada foi gerado (fonte vazio ou so rotulos/EQU/diretivas)."
    ProcedureReturn #False
  EndIf

  Protected FileNum = CreateFile(#PB_Any, RelOutPath)
  If Not FileNum
    Z80SubProj_LastError = "Nao foi possivel gravar: " + RelOutPath
    ProcedureReturn #False
  EndIf
  Protected *Buf = AllocateMemory(N)
  Protected Idx
  For Idx = 0 To N - 1
    PokeB(*Buf + Idx, RelBytes(Idx))
  Next
  WriteData(FileNum, *Buf, N)
  CloseFile(FileNum)
  FreeMemory(*Buf)
  ProcedureReturn #True
EndProcedure

; Monta cada .asm de AsmPaths() em .REL dentro de WorkDir, devolvendo os
; caminhos gerados em OutRelPaths() (mesma ordem, prefixo numerico "NNN_"
; pra nao colidir se dois .asm de pastas diferentes tiverem o mesmo nome de
; arquivo, ex. dois "utils.asm") - helper compartilhado por
; Z80SubProj_Build()/BuildLibraryFromAsm(). Retorna #False no primeiro erro
; (Z80SubProj_GetLastError()), sem tentar montar o resto da lista.
Procedure.i Z80SubProj_AssembleAllToRel(List AsmPaths.s(), WorkDir.s, List OutRelPaths.s())
  ClearList(OutRelPaths())
  Protected Seq = 0
  ForEach AsmPaths()
    Seq + 1
    Protected RelPath.s = WorkDir + RSet(Str(Seq), 3, "0") + "_" + GetFilePart(AsmPaths(), #PB_FileSystem_NoExtension) + ".rel"
    If Not Z80SubProj_AssembleToRel(AsmPaths(), RelPath)
      ProcedureReturn #False
    EndIf
    AddElement(OutRelPaths())
    OutRelPaths() = RelPath
  Next
  ProcedureReturn #True
EndProcedure

; Copia cada biblioteca de LibPaths() pra StagingDir, renomeando pra
; "<nome-base>.rel" - ver comentario no topo do arquivo pro motivo dessa
; extensao ser obrigatoria. Copiar (nao mover) preserva o arquivo original
; de onde o usuario escolheu. Caso de borda aceito, nao tratado: duas libs
; com o mesmo nome-base (de pastas diferentes) colidiriam no staging - nao
; faz sentido de qualquer forma, já que um nome de .REQUEST so pode apontar
; pra um arquivo por vez.
Procedure Z80SubProj_StageLibraries(List LibPaths.s(), StagingDir.s)
  ForEach LibPaths()
    Protected BaseName.s = GetFilePart(LibPaths(), #PB_FileSystem_NoExtension)
    If BaseName <> ""
      CopyFile(LibPaths(), StagingDir + BaseName + ".rel")
    EndIf
  Next
EndProcedure

; Pasta de trabalho temporaria dedicada ao build - limpa (todos os arquivos
; soltos, sem entrar em subpasta) antes de cada Z80SubProj_Build/
; BuildLibraryFromAsm, mesmo espirito de ClearDiskDir() em BadigEditor.pb.
Procedure.s Z80SubProj_WorkDir()
  Protected Dir.s = GetTemporaryDirectory() + "z80subproj\"
  If FileSize(Dir) <> -2
    CreateDirectory(Dir)
  EndIf
  Protected d = ExamineDirectory(#PB_Any, Dir, "*.*")
  If d
    While NextDirectoryEntry(d)
      If DirectoryEntryType(d) = #PB_DirectoryEntry_File
        DeleteFile(Dir + DirectoryEntryName(d))
      EndIf
    Wend
    FinishDirectory(d)
  EndIf
  ProcedureReturn Dir
EndProcedure

; "Makefile primitivo": monta cada .asm de AsmPaths() em .REL (pasta de
; trabalho temporaria), empacota as bibliotecas de LibPaths() nessa mesma
; pasta (Z80SubProj_StageLibraries) e linka tudo (Z80Link::LinkFiles) num
; binario final em OutBytes(). Retorno: numero de bytes, ou -1 em erro
; (Z80SubProj_GetLastError()); endereco inicial/final via
; Z80SubProj_GetBuildStartAddr()/GetBuildEndAddr().
Procedure.i Z80SubProj_Build(List AsmPaths.s(), List LibPaths.s(), Array OutBytes.a(1))
  Z80SubProj_LastError = ""
  Z80SubProj_LastStartAddr = 0
  Z80SubProj_LastEndAddr = 0

  If ListSize(AsmPaths()) = 0
    Z80SubProj_LastError = "Nenhum arquivo .asm no subprojeto."
    ProcedureReturn -1
  EndIf

  Protected WorkDir.s = Z80SubProj_WorkDir()
  Protected NewList RelPaths.s()
  If Not Z80SubProj_AssembleAllToRel(AsmPaths(), WorkDir, RelPaths())
    ProcedureReturn -1
  EndIf

  Z80SubProj_StageLibraries(LibPaths(), WorkDir)

  Protected N = Z80Link::LinkFiles(RelPaths(), OutBytes(), WorkDir)
  If N < 0
    Z80SubProj_LastError = "Link: " + Z80Link::GetLastLinkError()
    ProcedureReturn -1
  EndIf

  Z80SubProj_LastStartAddr = Z80Link::GetLinkStartAddr()
  Z80SubProj_LastEndAddr = Z80Link::GetLinkEndAddr()
  ProcedureReturn N
EndProcedure

; Monta cada .asm de AsmPaths() em .REL (pasta de trabalho temporaria) e
; empacota tudo em LibPath via Z80Lib::CreateOrAddLibrary (cria o arquivo se
; nao existir, acrescenta se ja existir) - "quero reunir estas rotinas numa
; biblioteca pra reusar depois". LibPath deveria terminar em ".rel" pra
; poder ser referenciada via .REQUEST depois (ver comentario no topo do
; arquivo) - nao forcado aqui pra nao surpreender quem so quer arquivar uma
; biblioteca sem usa-la via .REQUEST ainda.
Procedure.i Z80SubProj_BuildLibraryFromAsm(List AsmPaths.s(), LibPath.s)
  Z80SubProj_LastError = ""

  If ListSize(AsmPaths()) = 0
    Z80SubProj_LastError = "Nenhum arquivo .asm selecionado."
    ProcedureReturn #False
  EndIf

  Protected WorkDir.s = Z80SubProj_WorkDir()
  Protected NewList RelPaths.s()
  If Not Z80SubProj_AssembleAllToRel(AsmPaths(), WorkDir, RelPaths())
    ProcedureReturn #False
  EndIf

  If Not Z80Lib::CreateOrAddLibrary(LibPath, RelPaths())
    Z80SubProj_LastError = "Biblioteca: " + Z80Lib::GetLastLibError()
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure
