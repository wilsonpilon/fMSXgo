;
; ------------------------------------------------------------
;  Harness headless (/CONSOLE) pro codec de formatos nativos do Graphos III
;  (editor/GraphosNativeIO.pbi - .LAY/.SCR/.SHP). Carrega arquivos REAIS ja
;  presentes no repositorio (graphos/Layout|Telas|Shapes/...), faz round-trip
;  (importa -> exporta pro mesmo formato -> reimporta) e confere que os dados
;  batem, validando encode/decode sem precisar abrir a IDE. Exit code != 0
;  indica alguma regressao (mesma convencao de Screen2TestCli.pb).
;
;  Compilar: pbcompiler.exe editor\tools\GraphosNativeIOTestCli.pb /EXE
;            editor\tools\GraphosNativeIOTestCli.exe /CONSOLE
;  Rodar:    editor\tools\GraphosNativeIOTestCli.exe <scratch_dir>
; ------------------------------------------------------------
;

XIncludeFile "..\visual_editors\Screen2Synth.pbi"
XIncludeFile "..\visual_editors\GraphosNativeIO.pbi"

Global TestCount = 0
Global FailCount = 0

Procedure CheckTrue(Label.s, Cond.i)
  TestCount + 1
  If Cond
    PrintN("PASS  " + Label)
  Else
    PrintN("FAIL  " + Label)
    FailCount + 1
  EndIf
EndProcedure

If CountProgramParameters() < 1
  PrintN("Uso: GraphosNativeIOTestCli.exe <scratch_dir>")
  End 1
EndIf

Global ScratchDir.s = ProgramParameter(0)
If Right(ScratchDir, 1) <> "\" And Right(ScratchDir, 1) <> "/"
  ScratchDir + "\"
EndIf
CreateDirectory(ScratchDir)

If OpenConsole()

  PrintN("=== Teste 1: .LAY round-trip (graphos/Layout/MSX_327/AFIF1.LAY) ===")
  Dim PatA.a(#Scr2_Height - 1, #Scr2_Width - 1)
  Dim PatB.a(#Scr2_Height - 1, #Scr2_Width - 1)
  Define LayIn.s = "graphos\Layout\MSX_327\AFIF1.LAY"
  Define LayOut.s = ScratchDir + "roundtrip.lay"
  Define Ok1.i = GraphosNative_LoadLay(LayIn, PatA())
  CheckTrue("carrega AFIF1.LAY", Ok1)

  Define SetBits.i = 0
  Define Y, X
  For Y = 0 To #Scr2_Height - 1
    For X = 0 To #Scr2_Width - 1
      If PatA(Y, X) : SetBits + 1 : EndIf
    Next
  Next
  PrintN("  bits acesos no padrao carregado: " + Str(SetBits))
  CheckTrue("padrao carregado nao esta vazio", Bool(SetBits > 0))
  CheckTrue("padrao carregado nao esta 100% aceso (teria virado ruido)", Bool(SetBits < (#Scr2_Height * #Scr2_Width)))

  Define Ok2.i = GraphosNative_SaveLay(LayOut, PatA())
  CheckTrue("salva roundtrip.lay", Ok2)
  Define Ok3.i = GraphosNative_LoadLay(LayOut, PatB())
  CheckTrue("recarrega roundtrip.lay", Ok3)

  Define Diffs.i = 0
  For Y = 0 To #Scr2_Height - 1
    For X = 0 To #Scr2_Width - 1
      If PatA(Y, X) <> PatB(Y, X) : Diffs + 1 : EndIf
    Next
  Next
  CheckTrue("round-trip .LAY identico bit a bit (0 diffs, obtido " + Str(Diffs) + ")", Bool(Diffs = 0))

  PrintN("")
  PrintN("=== Teste 2: .SCR round-trip (graphos/Telas/MSX_310/S-SHP01.SCR) ===")
  Dim ScrPatA.a(#Scr2_Height - 1, #Scr2_Width - 1)
  Dim ScrFgA.a(#Scr2_Height - 1, #Scr2_Cols - 1)
  Dim ScrBgA.a(#Scr2_Height - 1, #Scr2_Cols - 1)
  Dim ScrPatB.a(#Scr2_Height - 1, #Scr2_Width - 1)
  Dim ScrFgB.a(#Scr2_Height - 1, #Scr2_Cols - 1)
  Dim ScrBgB.a(#Scr2_Height - 1, #Scr2_Cols - 1)
  Define ScrIn.s = "graphos\Telas\MSX_310\S-SHP01.SCR"
  Define ScrOut.s = ScratchDir + "roundtrip.scr"
  Define Ok4.i = GraphosNative_LoadScr(ScrIn, ScrPatA(), ScrFgA(), ScrBgA())
  CheckTrue("carrega S-SHP01.SCR", Ok4)

  Define ScrSetBits.i = 0
  For Y = 0 To #Scr2_Height - 1
    For X = 0 To #Scr2_Width - 1
      If ScrPatA(Y, X) : ScrSetBits + 1 : EndIf
    Next
  Next
  PrintN("  bits acesos no padrao carregado: " + Str(ScrSetBits))
  CheckTrue("padrao da tela carregado nao esta vazio", Bool(ScrSetBits > 0))

  Define Ok5.i = GraphosNative_SaveScr(ScrOut, ScrPatA(), ScrFgA(), ScrBgA())
  CheckTrue("salva roundtrip.scr", Ok5)
  Define Ok6.i = GraphosNative_LoadScr(ScrOut, ScrPatB(), ScrFgB(), ScrBgB())
  CheckTrue("recarrega roundtrip.scr", Ok6)

  Define ScrDiffsPat.i = 0, ScrDiffsCol.i = 0
  For Y = 0 To #Scr2_Height - 1
    For X = 0 To #Scr2_Width - 1
      If ScrPatA(Y, X) <> ScrPatB(Y, X) : ScrDiffsPat + 1 : EndIf
    Next
    For X = 0 To #Scr2_Cols - 1
      If ScrFgA(Y, X) <> ScrFgB(Y, X) Or ScrBgA(Y, X) <> ScrBgB(Y, X) : ScrDiffsCol + 1 : EndIf
    Next
  Next
  CheckTrue("round-trip .SCR padrao identico (0 diffs, obtido " + Str(ScrDiffsPat) + ")", Bool(ScrDiffsPat = 0))
  CheckTrue("round-trip .SCR cor identica (0 diffs, obtido " + Str(ScrDiffsCol) + ")", Bool(ScrDiffsCol = 0))

  PrintN("")
  PrintN("=== Teste 3: .SHP banco - scan (graphos/Shapes/MSX_092/PC-1.SHP) ===")
  NewList Entries.GraphosNative_ShpEntry()
  Define ShpIn.s = "graphos\Shapes\MSX_092\PC-1.SHP"
  GraphosNative_ScanShpFile(ShpIn, Entries())
  PrintN("  shapes encontrados: " + Str(ListSize(Entries())))
  CheckTrue("encontrou pelo menos 1 shape no banco", Bool(ListSize(Entries()) > 0))

  FirstElement(Entries())
  PrintN("  shape 1: numero=" + Str(Entries()\Number) + " tipo=" + Str(Entries()\Type) + " largura=" + Str(Entries()\Width) + " altura(tiles)=" + Str(Entries()\HeightTiles))
  CheckTrue("primeiro shape tem numero 1", Bool(Entries()\Number = 1))
  CheckTrue("primeiro shape tem largura multipla de 8", Bool((Entries()\Width % 8) = 0))

  Define ShpWidth.i = Entries()\Width
  Define ShpHTiles.i = Entries()\HeightTiles
  Define ShpType.i = Entries()\Type
  Define ShpOffset.i = Entries()\Offset

  PrintN("")
  PrintN("=== Teste 4: .SHP round-trip (carrega shape 1, exporta, recarrega) ===")
  Dim ShpPatA.a(ShpHTiles * 8 - 1, ShpWidth - 1)
  Dim ShpFgA.a(ShpHTiles * 8 - 1, ShpWidth / 8 - 1)
  Dim ShpBgA.a(ShpHTiles * 8 - 1, ShpWidth / 8 - 1)
  Define Ok7.i = GraphosNative_LoadShapeAt(ShpIn, ShpOffset, ShpType, ShpWidth, ShpHTiles, ShpPatA(), ShpFgA(), ShpBgA())
  CheckTrue("carrega shape 1 do banco", Ok7)

  Define ShpSetBits.i = 0
  For Y = 0 To ShpHTiles * 8 - 1
    For X = 0 To ShpWidth - 1
      If ShpPatA(Y, X) : ShpSetBits + 1 : EndIf
    Next
  Next
  PrintN("  bits acesos no shape carregado: " + Str(ShpSetBits))
  CheckTrue("padrao do shape carregado nao esta vazio", Bool(ShpSetBits > 0))

  Define ShpOut.s = ScratchDir + "roundtrip.shp"
  Define Ok8.i = GraphosNative_SaveShp(ShpOut, ShpWidth, ShpHTiles, ShpPatA(), ShpFgA(), ShpBgA())
  CheckTrue("salva roundtrip.shp", Ok8)

  NewList Entries2.GraphosNative_ShpEntry()
  GraphosNative_ScanShpFile(ShpOut, Entries2())
  CheckTrue("banco exportado tem exatamente 1 shape", Bool(ListSize(Entries2()) = 1))
  FirstElement(Entries2())
  CheckTrue("shape exportado preserva largura", Bool(Entries2()\Width = ShpWidth))
  CheckTrue("shape exportado preserva altura", Bool(Entries2()\HeightTiles = ShpHTiles))
  CheckTrue("shape exportado e' sempre tipo 2 (padrao+cor)", Bool(Entries2()\Type = 2))

  Dim ShpPatB.a(ShpHTiles * 8 - 1, ShpWidth - 1)
  Dim ShpFgB.a(ShpHTiles * 8 - 1, ShpWidth / 8 - 1)
  Dim ShpBgB.a(ShpHTiles * 8 - 1, ShpWidth / 8 - 1)
  Define Ok9.i = GraphosNative_LoadShapeAt(ShpOut, Entries2()\Offset, Entries2()\Type, Entries2()\Width, Entries2()\HeightTiles, ShpPatB(), ShpFgB(), ShpBgB())
  CheckTrue("recarrega shape exportado", Ok9)

  Define ShpDiffs.i = 0
  For Y = 0 To ShpHTiles * 8 - 1
    For X = 0 To ShpWidth - 1
      If ShpPatA(Y, X) <> ShpPatB(Y, X) : ShpDiffs + 1 : EndIf
    Next
  Next
  CheckTrue("round-trip .SHP padrao identico (0 diffs, obtido " + Str(ShpDiffs) + ")", Bool(ShpDiffs = 0))

  PrintN("")
  PrintN("=== Resultado: " + Str(TestCount - FailCount) + "/" + Str(TestCount) + " OK ===")
  If FailCount > 0
    PrintN("REGRESSAO DETECTADA")
  EndIf

  CloseConsole()
EndIf

End FailCount
