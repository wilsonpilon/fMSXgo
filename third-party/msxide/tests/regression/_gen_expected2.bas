#Include Once "src/db.bi"
#Include Once "src/compiler.bi"

Function Build(ByRef inputPath As String, ByRef outAmx As String, ByRef outBmx As String) As Integer
    Dim e As String
    If CompilerCompileToBmx(inputPath, outAmx, outBmx, e) = 0 Then
        Print "FAIL " & inputPath & " -> " & e
        Return 0
    End If
    Print outAmx
    Print outBmx
    Return -1
End Function

Dim amx As String
Dim bmx As String
DbInit("tests/regression/test_regression.db")

If Build("tests/regression/fixtures/inputs/loops_labels.dmx", amx, bmx) = 0 Then End 1
If Build("tests/regression/fixtures/inputs/include_define.dmx", amx, bmx) = 0 Then End 1
If Build("tests/regression/fixtures/inputs/remtags_export.dmx", amx, bmx) = 0 Then End 1
If Build("tests/regression/fixtures/inputs/float_scientific.dmx", amx, bmx) = 0 Then End 1
If Build("tests/regression/fixtures/inputs/ns_main_big.dmx", amx, bmx) = 0 Then End 1
If Build("tests/regression/fixtures/inputs/remtags_extra.dmx", amx, bmx) = 0 Then End 1
DbShutdown()
End 0
