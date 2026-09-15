;
; ------------------------------------------------------------
;  Harness headless (sem GUI) do carregador do arquivo de notas do SUPER-X
;  (editor\assemblers\MamuteNotesData.pbi, docs/SPEC.md modulo 45e).
;
;  Uso:
;    MamuteNotesTestCli.exe <caminho para SUPER-X.TNK>
;
;  Compilar:
;  "C:\Basic\Compilers\pbcompiler.exe" editor\tools\MamuteNotesTestCli.pb /EXE editor\tools\MamuteNotesTestCli.exe /CONSOLE
;
;  Le o arquivo, imprime quantas notas carregou e os primeiros/ultimos
;  registros (endereco/slot/tipo) pra conferir contra a exploracao feita
;  em Python fora do projeto (SUPER-X.TNK real, 471 notas, primeira em
;  0000H) - SUPER-X.TNK e' arquivo de terceiros (ja commitado no repositorio
;  desde antes desta sessao - achado real/pendencia registrada em
;  docs/SPEC.md modulo 45e, NAO gitignored como se supunha antes de
;  verificar de verdade), nao faz parte de dist/ nem do .exe.
; ------------------------------------------------------------
;

EnableExplicit
OpenConsole()

XIncludeFile "..\assemblers\MamuteNotesData.pbi"

Define Path.s = ProgramParameter(0)
If Path = ""
  PrintN("Uso: MamuteNotesTestCli.exe <caminho para SUPER-X.TNK>")
  End 1
EndIf

If Not Mamute_LoadNoteFile(Path)
  PrintN("ERRO: nao conseguiu carregar " + Path + " (arquivo nao existe, ou tamanho nao bate com o formato esperado)")
  End 1
EndIf

Define Total.i = ListSize(MamuteNotes())
PrintN("Notas carregadas: " + Str(Total))
PrintN("")

Define Shown.i = 0
Define TypeNames.s = ""
Define Dim TypeCounts.i(7)

ForEach MamuteNotes()
  TypeCounts(MamuteNotes()\TypeData) + 1
  If Shown < 5 Or Shown >= Total - 5
    PrintN(RSet(Hex(MamuteNotes()\Addr), 4, "0") + "H  slot=" + Str(MamuteNotes()\SlotData) +
           "  tipo=" + Str(MamuteNotes()\TypeData) + "  bytes=" + Str(Len(MamuteNotes()\Text)))
  ElseIf Shown = 5
    PrintN("...")
  EndIf
  Shown + 1
Next

PrintN("")
PrintN("Contagem por tipo (0=Geral 1=BIOS 2=WORK 3=DATA 4=PORT 5=MATH 6=KEY 7=HOOK):")
Define t.i
For t = 0 To 7
  If TypeCounts(t) > 0
    PrintN("  tipo " + Str(t) + ": " + Str(TypeCounts(t)))
  EndIf
Next

CloseConsole()
