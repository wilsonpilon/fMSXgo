;
; ------------------------------------------------------------
;  Z80LinkTestCli.pb - harness headless (sem GUI) do linker Z80 nativo
;  (Z80Link.pbi). Mesmo padrao PASS/FAIL de Z80AsmTestCli.pb - exit code =
;  numero de falhas (0 = tudo passou).
;
;  Compilar:
;  "C:\Basic\Compilers\pbcompiler.exe" editor\tools\Z80LinkTestCli.pb /EXE editor\tools\Z80LinkTestCli.exe /CONSOLE
;
;  Uso: Z80LinkTestCli.exe                     roda a suite de regressao
;                                                (linka sample/testeL*.rel
;                                                ja gerados e compara contra
;                                                bytes fixados - oraculo
;                                                LK80.exe, ver docs/resumo-asm.md)
;       Z80LinkTestCli.exe --link <saida.bin> [--libdir <pasta>] <a.rel> [b.rel ...]
;                                                linka os .REL dados e grava
;                                                o binario cru - usado pra
;                                                comparar byte a byte com o
;                                                oraculo (LK80.exe) via
;                                                ferramenta externa (fc/cmp).
;                                                --libdir = pasta de busca
;                                                pros arquivos de .REQUEST
;                                                (equivalente a --library-dir
;                                                do LK80 real)
; ------------------------------------------------------------
;

EnableExplicit

XIncludeFile "..\assemblers\Z80Link.pbi"
XIncludeFile "..\assemblers\Z80Lib.pbi"

If CountProgramParameters() >= 3 And ProgramParameter(0) = "--libcreate"
  OpenConsole()
  Define LibPath.s = ProgramParameter(1)
  Define NewList InPaths.s()
  Define Idx2
  For Idx2 = 2 To CountProgramParameters() - 1
    AddElement(InPaths())
    InPaths() = ProgramParameter(Idx2)
  Next
  If Z80Lib::CreateOrAddLibrary(LibPath, InPaths())
    PrintN("OK: " + LibPath)
    End 0
  Else
    PrintN("LIBERROR: " + Z80Lib::GetLastLibError())
    End 1
  EndIf
EndIf

If CountProgramParameters() >= 2 And ProgramParameter(0) = "--liblist"
  OpenConsole()
  Define NewList Progs.Z80Lib::Z80LibProgramInfo()
  If Not Z80Lib::ListLibrary(ProgramParameter(1), Progs())
    PrintN("LIBERROR: " + Z80Lib::GetLastLibError())
    End 1
  EndIf
  ForEach Progs()
    PrintN(Progs()\Name + "  (" + Str(Progs()\SizeBytes) + " bytes)  publicos: " + Progs()\PublicSymbolsCsv)
  Next
  End 0
EndIf

If CountProgramParameters() >= 3 And ProgramParameter(0) = "--libremove"
  OpenConsole()
  If Z80Lib::RemoveProgram(ProgramParameter(1), ProgramParameter(2))
    PrintN("OK")
    End 0
  Else
    PrintN("LIBERROR: " + Z80Lib::GetLastLibError())
    End 1
  EndIf
EndIf

If CountProgramParameters() >= 2 And ProgramParameter(0) = "--link"
  OpenConsole()
  Define OutPath.s = ProgramParameter(1)
  Define LibDir.s = ""
  Define FirstRelIdx = 2
  If CountProgramParameters() >= 4 And ProgramParameter(2) = "--libdir"
    LibDir = ProgramParameter(3)
    FirstRelIdx = 4
  EndIf
  Define NewList Paths.s()
  Define Idx
  For Idx = FirstRelIdx To CountProgramParameters() - 1
    AddElement(Paths())
    Paths() = ProgramParameter(Idx)
  Next

  Define Dim OutBytes.a(65535)
  Define N = Z80Link::LinkFiles(Paths(), OutBytes(), LibDir)
  If N < 0
    PrintN("LINKERROR: " + Z80Link::GetLastLinkError())
    End 1
  EndIf

  If CreateFile(0, OutPath)
    If N > 0
      Define Dim WriteBuf.a(N - 1)
      Define Idx0
      For Idx0 = 0 To N - 1
        WriteBuf(Idx0) = OutBytes(Idx0)
      Next
      WriteData(0, @WriteBuf(), N)
    EndIf
    CloseFile(0)
  EndIf
  PrintN(Str(N) + " bytes (inicio " + Hex(Z80Link::GetLinkStartAddr()) + "h, fim " + Hex(Z80Link::GetLinkEndAddr()) + "h)")
  End 0
EndIf

Global TestCount = 0
Global FailCount = 0

; Linka os .REL dados (caminhos relativos ao diretorio de trabalho) e compara
; contra uma string hex esperada - regressao self-contained (bytes fixados
; numa sessao anterior contra o oraculo LK80.exe, ver docs/resumo-asm.md),
; sem precisar do LK80.exe presente pra rodar.
Procedure CheckLinkFiles(Desc.s, ExpectedHex.s, Array Paths2.s(1), LibDir.s = "")
  TestCount + 1
  Protected NewList Paths.s()
  Protected Idx
  For Idx = 0 To ArraySize(Paths2())
    AddElement(Paths())
    Paths() = Paths2(Idx)
  Next

  Protected Dim OutBytes.a(65535)
  Protected N = Z80Link::LinkFiles(Paths(), OutBytes(), LibDir)
  If N < 0
    FailCount + 1
    PrintN("FAIL  LinkFiles  " + Desc + "  erro: " + Z80Link::GetLastLinkError())
    ProcedureReturn
  EndIf

  Protected ExpN = Len(ExpectedHex) / 2
  Protected Ok.b = Bool(N = ExpN)
  Protected ExpB.a
  If Ok
    For Idx = 0 To N - 1
      ExpB = Val("$" + Mid(ExpectedHex, Idx * 2 + 1, 2))
      If OutBytes(Idx) <> ExpB
        Ok = #False
        Break
      EndIf
    Next
  EndIf
  If Ok
    PrintN("PASS  LinkFiles  " + Desc + "  (" + Str(N) + " bytes, inicio " + Hex(Z80Link::GetLinkStartAddr()) + "h)")
  Else
    FailCount + 1
    Protected GotHex.s = ""
    For Idx = 0 To N - 1
      GotHex + RSet(Hex(OutBytes(Idx)), 2, "0")
    Next
    PrintN("FAIL  LinkFiles  " + Desc + "  esperado " + Str(ExpN) + " bytes, obtido " + Str(N) + " [" + GotHex + "]")
  EndIf
EndProcedure

OpenConsole()

PrintN("=== Z80Link - linkagem de multiplos .REL (Fase B, corte 1) ===")

Define Dim Files1.s(0)
Files1(0) = "sample/teste4_rel_public.rel"
CheckLinkFiles("um so modulo, sem externo (teste4_rel_public.rel, linkado sozinho)",
  "3E01C9", Files1())

Define Dim Files2.s(1)
Files2(0) = "sample/teste7_link_main.rel"
Files2(1) = "sample/teste7_link_lib.rel"
CheckLinkFiles("2 modulos, PUBLIC/EXTRN cruzado (main chama lib, lib usa dado do main)",
  "CD0801C92A3A0701C9", Files2())

Define Dim Files3.s(1)
Files3(0) = "sample/teste8_link_common_a.rel"
Files3(1) = "sample/teste8_link_common_b.rel"
CheckLinkFiles("2 modulos compartilhando bloco COMMON /shared/ (rotulos diferentes, mesmo endereco)",
  "0000CD0901C92A030123220301C9", Files3())

PrintN("")
PrintN("=== Z80Link - .REQUEST/biblioteca (Fase B, corte 2) ===")
; O LK80.exe local desta maquina tem uma limitacao/bug confirmado (ver
; docs/resumo-asm.md): so enxerga o simbolo publico do PRIMEIRO programa de
; uma biblioteca .REQUEST com mais de um programa. teste9 pede o SEGUNDO
; programa (funcb, dentro de teste9_link_request_lib.rel = moda+modb) - nao
; da pra validar contra o LK80.exe real nesse caso especifico, mas o
; resultado (so 7 bytes = so MODB entrou, MODA ficou de fora) foi conferido
; manualmente e bate com o padrao ja validado quando o simbolo pedido e do
; PRIMEIRO programa (ver log de decisoes tecnicas).
Define Dim Files4.s(0)
Files4(0) = "sample/teste9_link_request_main.rel"
CheckLinkFiles("biblioteca com 2 programas via .REQUEST, so o 2o (MODB/funcb) e referenciado - linkagem estatica seletiva",
  "CD0701C93E02C9", Files4(), "sample")

Define Dim Files5.s(0)
Files5(0) = "sample/teste10_link_transitive_main.rel"
CheckLinkFiles("biblioteca com 3 programas encadeados (funcx->funcy->funcz) via .REQUEST - resolucao transitiva",
  "CD0701C9CD0B01C9CD0F01C93E09C9", Files5(), "sample")

PrintN("")
PrintN("=== Z80Lib - gerenciador de biblioteca (create/add/list/remove) ===")

Procedure CheckLibCreateAddListRemove()
  Protected TmpLib.s = GetTemporaryDirectory() + "z80libtest_" + Str(Random(999999999)) + ".rel"

  TestCount + 1
  Protected NewList In1.s()
  AddElement(In1()) : In1() = "sample/teste9_link_request_moda.rel"
  If Not Z80Lib::CreateOrAddLibrary(TmpLib, In1())
    FailCount + 1 : PrintN("FAIL  Z80Lib create  " + Z80Lib::GetLastLibError()) : ProcedureReturn
  EndIf
  Protected NewList In2.s()
  AddElement(In2()) : In2() = "sample/teste9_link_request_modb.rel"
  If Not Z80Lib::CreateOrAddLibrary(TmpLib, In2())
    FailCount + 1 : PrintN("FAIL  Z80Lib add  " + Z80Lib::GetLastLibError()) : ProcedureReturn
  EndIf

  Protected NewList Progs.Z80Lib::Z80LibProgramInfo()
  If Not Z80Lib::ListLibrary(TmpLib, Progs())
    FailCount + 1 : PrintN("FAIL  Z80Lib list  " + Z80Lib::GetLastLibError()) : ProcedureReturn
  EndIf
  Protected Names.s = ""
  ForEach Progs()
    Names + Progs()\Name + ";"
  Next
  If Names = "MODA;MODB;"
    PrintN("PASS  Z80Lib create(moda) + add(modb) + list  (MODA;MODB;)")
  Else
    FailCount + 1
    PrintN("FAIL  Z80Lib create+add+list  esperado MODA;MODB; obtido " + Names)
  EndIf

  TestCount + 1
  If Not Z80Lib::RemoveProgram(TmpLib, "moda")
    FailCount + 1 : PrintN("FAIL  Z80Lib remove  " + Z80Lib::GetLastLibError()) : ProcedureReturn
  EndIf
  Protected NewList Progs2.Z80Lib::Z80LibProgramInfo()
  Z80Lib::ListLibrary(TmpLib, Progs2())
  Protected Names2.s = ""
  ForEach Progs2()
    Names2 + Progs2()\Name + ";"
  Next
  If Names2 = "MODB;"
    PrintN("PASS  Z80Lib remove(moda)  (sobrou MODB;)")
  Else
    FailCount + 1
    PrintN("FAIL  Z80Lib remove  esperado MODB; obtido " + Names2)
  EndIf

  DeleteFile(TmpLib)
EndProcedure

; create/add validados byte a byte contra LB80.exe real (mesma sequencia
; create(moda)+add(modb) produz arquivo identico ao LB80.exe, ver
; docs/resumo-asm.md); remove validado comparando contra modb.rel isolado
; (biblioteca de 1 programa so = o proprio .REL daquele programa).
CheckLibCreateAddListRemove()

PrintN("")
PrintN("=== Resultado ===")
PrintN(Str(TestCount) + " testes, " + Str(FailCount) + " falhas")

End FailCount
