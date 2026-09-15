;
; ------------------------------------------------------------
;  Harness de console pro motor do "subprojeto de Assembly"
;  (editor\Z80SubProject.pbi) - monta .asm reais de sample/ (os mesmos ja
;  usados como oraculo de regressao do linker em Z80LinkTestCli.pb) em .REL
;  via Z80SubProj_Build/BuildLibraryFromAsm e compara o binario final byte a
;  byte contra os mesmos resultados ja validados contra o LK80.exe real
;  (ver docs/resumo-asm.md) - sem precisar montar os .rel manualmente antes,
;  cobrindo a ponta a ponta "varios .asm -> binario final" que a GUI
;  (Z80SubProjectGui.pbi) tambem exercita.
;
;  Compilar com:
;    "C:\Basic\Compilers\pbcompiler.exe" editor\tools\Z80SubProjectTestCli.pb /EXE editor\tools\Z80SubProjectTestCli.exe /CONSOLE
;  Rodar a partir da raiz do repositorio (caminhos relativos a "sample\").
; ------------------------------------------------------------
;

EnableExplicit
OpenConsole()

XIncludeFile "..\assemblers\Z80Asm.pbi"
XIncludeFile "..\assemblers\Z80Link.pbi"
XIncludeFile "..\assemblers\Z80Lib.pbi"
XIncludeFile "..\assemblers\Z80SubProject.pbi"

Z80Asm::InitKeywordMaps()

Define TestCount = 0, FailCount = 0

Procedure.s BytesToHex(Array B.a(1), N.i)
  Protected Result.s = "", i
  For i = 0 To N - 1
    Result + RSet(Hex(B(i)), 2, "0")
  Next
  ProcedureReturn Result
EndProcedure

Procedure CheckBuild(Desc.s, List AsmPaths.s(), List LibPaths.s(), ExpHex.s)
  Shared TestCount, FailCount
  TestCount + 1
  Protected Dim OutBytes.a(65535)
  Protected N = Z80SubProj_Build(AsmPaths(), LibPaths(), OutBytes())
  If N < 0
    FailCount + 1
    PrintN("FAIL  " + Desc + "  erro: " + Z80SubProj_GetLastError())
    ProcedureReturn
  EndIf
  Protected GotHex.s = BytesToHex(OutBytes(), N)
  If GotHex = ExpHex
    PrintN("PASS  " + Desc + "  (" + Str(N) + " bytes)")
  Else
    FailCount + 1
    PrintN("FAIL  " + Desc + "  esperado " + ExpHex + " obtido " + GotHex)
  EndIf
EndProcedure

PrintN("=== Z80SubProject - build 'varios .asm -> binario' (Makefile primitivo) ===")

; Mesmo par main/lib do teste7 do Z80LinkTestCli.pb, mas montado aqui a
; partir dos .asm (nao dos .rel ja prontos) - PUBLIC/EXTRN cruzado (main
; chama lib, lib le dado do main).
Define NewList Asm1.s()
AddElement(Asm1()) : Asm1() = "sample/teste7_link_main.asm"
AddElement(Asm1()) : Asm1() = "sample/teste7_link_lib.asm"
Define NewList NoLibs.s()
CheckBuild("2 .asm, PUBLIC/EXTRN cruzado (teste7)", Asm1(), NoLibs(), "CD0801C92A3A0701C9")

; Mesmo par do teste8 (bloco COMMON compartilhado).
Define NewList Asm2.s()
AddElement(Asm2()) : Asm2() = "sample/teste8_link_common_a.asm"
AddElement(Asm2()) : Asm2() = "sample/teste8_link_common_b.asm"
CheckBuild("2 .asm compartilhando bloco COMMON (teste8)", Asm2(), NoLibs(), "0000CD0901C92A030123220301C9")

PrintN("")
PrintN("=== Z80SubProject - gerar biblioteca a partir de .asm + build com .REQUEST ===")

; Empacota moda.asm+modb.asm numa biblioteca com o MESMO nome-base que
; teste9_link_request_main.asm pede via ".request teste9_link_request_lib" -
; confirma que Z80SubProj_BuildLibraryFromAsm() produz algo que
; Z80SubProj_Build() consegue resolver via .REQUEST de ponta a ponta.
; O nome-BASE do arquivo (sem extensao) precisa bater exatamente com o nome
; pedido em ".request teste9_link_request_lib" dentro de
; teste9_link_request_main.asm - por isso mora numa subpasta propria em vez
; de ganhar um prefixo de isolamento no nome do arquivo.
TestCount + 1
Define LibDir.s = GetTemporaryDirectory() + "z80subprojtest\"
If FileSize(LibDir) <> -2 : CreateDirectory(LibDir) : EndIf
Define LibOut.s = LibDir + "teste9_link_request_lib.rel"
DeleteFile(LibOut)
Define NewList LibAsm.s()
AddElement(LibAsm()) : LibAsm() = "sample/teste9_link_request_moda.asm"
AddElement(LibAsm()) : LibAsm() = "sample/teste9_link_request_modb.asm"
If Z80SubProj_BuildLibraryFromAsm(LibAsm(), LibOut)
  PrintN("PASS  BuildLibraryFromAsm(moda+modb)  (" + Str(FileSize(LibOut)) + " bytes em " + LibOut + ")")
Else
  FailCount + 1
  PrintN("FAIL  BuildLibraryFromAsm  erro: " + Z80SubProj_GetLastError())
EndIf

; O nome de arquivo pedido via .REQUEST e "teste9_link_request_lib" (sem
; caminho) - Z80SubProj_StageLibraries copia LibOut renomeando pro
; nome-base dele mesmo (independente de onde esta salvo), entao o que
; importa aqui e o nome-BASE de LibOut bater com o pedido no .asm.
Define NewList Asm3.s()
AddElement(Asm3()) : Asm3() = "sample/teste9_link_request_main.asm"
Define NewList Lib3.s()
AddElement(Lib3()) : Lib3() = LibOut
CheckBuild("main + biblioteca gerada (so MODB entra, linkagem estatica seletiva)", Asm3(), Lib3(), "CD0701C93E02C9")

DeleteFile(LibOut)

PrintN("")
PrintN("=== Resultado ===")
PrintN(Str(TestCount) + " testes, " + Str(FailCount) + " falhas")

End FailCount
