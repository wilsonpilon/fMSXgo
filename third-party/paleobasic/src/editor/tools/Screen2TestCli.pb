;
; ------------------------------------------------------------
;  Harness headless (/CONSOLE) pro motor SCREEN 2 (editor/Screen2Synth.pbi)
;  - fase 1: so os primitivos de pixel/clash/DRAW, ainda sem GUI. Roda uma
;  bateria de casos fixos e imprime PASS/FAIL por caso, mais um dump ASCII
;  compacto de um framebuffer, pra inspecao visual rapida sem abrir a IDE.
;  Exit code != 0 indica alguma regressao (mesma convencao de
;  DigTestCli.pb/ProjectDBTestCli.pb).
;
;  Compilar: pbcompiler.exe editor\tools\Screen2TestCli.pb /EXE
;            editor\tools\Screen2TestCli.exe /CONSOLE
;  Rodar:    editor\tools\Screen2TestCli.exe
; ------------------------------------------------------------
;

XIncludeFile "..\visual_editors\Screen2Synth.pbi"

Global TestCount = 0
Global FailCount = 0

Procedure CheckEqual(Label.s, Actual.i, Expected.i)
  TestCount + 1
  If Actual = Expected
    PrintN("PASS  " + Label)
  Else
    PrintN("FAIL  " + Label + " - esperado " + Str(Expected) + ", obtido " + Str(Actual))
    FailCount + 1
  EndIf
EndProcedure

Dim PatternBit.a(#Scr2_Height - 1, #Scr2_Width - 1)
Dim RowFG.a(#Scr2_Height - 1, #Scr2_Cols - 1)
Dim RowBG.a(#Scr2_Height - 1, #Scr2_Cols - 1)

If OpenConsole()

  PrintN("=== Teste 1: color clash na mesma faixa de 8px ===")
  Scr2_ClearFramebuffer(PatternBit(), RowFG(), RowBG())
  Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), 0, 0, 9, #True)
  CheckEqual("pixel (0,0) antes do clash = cor 9", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 0, 0), 9)
  Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), 5, 0, 2, #True) ; mesma faixa (x/8=0)
  CheckEqual("pixel (0,0) depois do clash = cor 2 (a faixa toda mudou)", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 0, 0), 2)
  CheckEqual("pixel (5,0) = cor 2", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 5, 0), 2)
  Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), 9, 0, 5, #True) ; faixa diferente (x/8=1)
  CheckEqual("pixel (0,0) nao muda com faixa diferente", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 0, 0), 2)
  CheckEqual("pixel (9,0) = cor 5 (faixa propria)", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 9, 0), 5)

  PrintN("")
  PrintN("=== Teste 2: PRESET apaga o bit e pode mudar o fundo da faixa ===")
  Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), 0, 0, 7, #False)
  CheckEqual("pixel (0,0) apagado e com novo fundo = cor 7", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 0, 0), 7)
  CheckEqual("pixel (5,0) (mesma faixa, ainda aceso) continua cor 2", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 5, 0), 2)

  PrintN("")
  PrintN("=== Teste 3: Scr2_DrawLine (reta horizontal) ===")
  Scr2_ClearFramebuffer(PatternBit(), RowFG(), RowBG())
  Scr2_DrawLine(PatternBit(), RowFG(), RowBG(), 0, 10, 10, 10, 7)
  CheckEqual("meio da reta (5,10) = cor 7", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 5, 10), 7)
  CheckEqual("ponta (0,10) = cor 7", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 0, 10), 7)
  CheckEqual("ponta (10,10) = cor 7", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 10, 10), 7)
  CheckEqual("fora da reta (5,11) continua fundo padrao (1)", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 5, 11), 1)

  PrintN("")
  PrintN("=== Teste 4: DRAW - quadrado fechado (U10 R10 D10 L10) ===")
  Scr2_ClearFramebuffer(PatternBit(), RowFG(), RowBG())
  Scr2_ExecuteDraw(PatternBit(), RowFG(), RowBG(), "U10R10D10L10", 50, 50, 9)
  CheckEqual("cursor volta em X", Scr2_DrawLastX, 50)
  CheckEqual("cursor volta em Y", Scr2_DrawLastY, 50)
  CheckEqual("topo do quadrado (55,40) pintado", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 55, 40), 9)
  CheckEqual("lado esquerdo (50,45) pintado", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 50, 45), 9)
  CheckEqual("lado direito (60,45) pintado", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 60, 45), 9)
  CheckEqual("base (55,50) pintada", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 55, 50), 9)
  CheckEqual("centro (55,45) NAO pintado", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 55, 45), 1)

  PrintN("")
  PrintN("=== Teste 5: DRAW - troca de cor no meio (C9U5C1U5) ===")
  Scr2_ClearFramebuffer(PatternBit(), RowFG(), RowBG())
  Scr2_ExecuteDraw(PatternBit(), RowFG(), RowBG(), "C9U5C1U5", 20, 90, 15)
  CheckEqual("primeiro trecho (20,88) = cor 9", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 20, 88), 9)
  CheckEqual("segundo trecho (20,82) = cor 1", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 20, 82), 1)
  CheckEqual("cor final reportada = 1", Scr2_DrawLastColor, 1)

  PrintN("")
  PrintN("=== Teste 6: DRAW - escala (S8 R10 == 20px) ===")
  Scr2_ExecuteDraw(PatternBit(), RowFG(), RowBG(), "S8R10", 0, 5, 3)
  CheckEqual("escala 8/4 dobra a distancia (10->20)", Scr2_DrawLastX, 20)

  PrintN("")
  PrintN("=== Teste 7: DRAW - angulo (A1/A2/A3 giram a direcao R) ===")
  Scr2_ExecuteDraw(PatternBit(), RowFG(), RowBG(), "A1R10", 100, 100, 3)
  CheckEqual("A1 R10 - X nao muda", Scr2_DrawLastX, 100)
  CheckEqual("A1 R10 - Y muda +10", Scr2_DrawLastY, 110)
  Scr2_ExecuteDraw(PatternBit(), RowFG(), RowBG(), "A2R10", 100, 100, 3)
  CheckEqual("A2 R10 - X muda -10", Scr2_DrawLastX, 90)
  CheckEqual("A2 R10 - Y nao muda", Scr2_DrawLastY, 100)
  Scr2_ExecuteDraw(PatternBit(), RowFG(), RowBG(), "A3R10", 100, 100, 3)
  CheckEqual("A3 R10 - X nao muda", Scr2_DrawLastX, 100)
  CheckEqual("A3 R10 - Y muda -10", Scr2_DrawLastY, 90)

  PrintN("")
  PrintN("=== Teste 8: DRAW - B (move sem tracar) e N (traca mas volta) ===")
  Scr2_ClearFramebuffer(PatternBit(), RowFG(), RowBG())
  Scr2_ExecuteDraw(PatternBit(), RowFG(), RowBG(), "BR10", 30, 30, 9)
  CheckEqual("BR10 - cursor anda", Scr2_DrawLastX, 40)
  CheckEqual("BR10 - nada foi tracado (35,30) fundo padrao", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 35, 30), 1)
  Scr2_ExecuteDraw(PatternBit(), RowFG(), RowBG(), "NR10", 30, 60, 9)
  CheckEqual("NR10 - traca (35,60) pintado", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 35, 60), 9)
  CheckEqual("NR10 - cursor volta pro ponto de partida", Scr2_DrawLastX, 30)

  PrintN("")
  PrintN("=== Dump ASCII (Teste 4 refeito, quadrado 50,40-60,50) ===")
  Scr2_ClearFramebuffer(PatternBit(), RowFG(), RowBG())
  Scr2_ExecuteDraw(PatternBit(), RowFG(), RowBG(), "U10R10D10L10", 50, 50, 9)
  Define DumpY, DumpX, C
  Define Line_.s
  For DumpY = 38 To 52
    Line_ = ""
    For DumpX = 48 To 62
      C = Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), DumpX, DumpY)
      If C = 9
        Line_ + "#"
      Else
        Line_ + "."
      EndIf
    Next
    PrintN(Line_)
  Next

  PrintN("")
  PrintN("=== Geracao de codigo (DRAW isolado) ===")
  PrintN(Scr2_GenDrawStatement("U10R10D10L10"))

  PrintN("")
  PrintN("=== Teste 9: CIRCLE (circulo completo) ===")
  Scr2_ClearFramebuffer(PatternBit(), RowFG(), RowBG())
  Scr2_DrawCircle(PatternBit(), RowFG(), RowBG(), 100, 100, 20, 5, 0, 0, 0)
  CheckEqual("ponta direita (120,100) na circunferencia", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 120, 100), 5)
  CheckEqual("ponta de cima (100,80) na circunferencia", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 100, 80), 5)
  CheckEqual("centro (100,100) NAO pintado (so contorno)", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 100, 100), 1)

  PrintN("")
  PrintN("=== Teste 10: CIRCLE (arco 0-90 graus, fatia de pizza) ===")
  Scr2_ClearFramebuffer(PatternBit(), RowFG(), RowBG())
  Scr2_DrawCircle(PatternBit(), RowFG(), RowBG(), 100, 100, 20, 6, Radian(0), Radian(90), 0, #True, #True)
  CheckEqual("dentro do arco (120,100) pintado", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 120, 100), 6)
  CheckEqual("raio inicial (110,100) pintado (fatia de pizza)", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 110, 100), 6)
  CheckEqual("fora do arco (80,100) NAO pintado", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 80, 100), 1)

  PrintN("")
  PrintN("=== Teste 11: LINE em modo caixa (B) e caixa preenchida (BF) ===")
  Scr2_ClearFramebuffer(PatternBit(), RowFG(), RowBG())
  Scr2_LineStatement(PatternBit(), RowFG(), RowBG(), 10, 10, 30, 20, 9, 1)
  CheckEqual("caixa vazia - borda (20,10) pintada", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 20, 10), 9)
  CheckEqual("caixa vazia - centro (20,15) NAO pintado", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 20, 15), 1)
  Scr2_LineStatement(PatternBit(), RowFG(), RowBG(), 50, 10, 70, 20, 9, 2)
  CheckEqual("caixa preenchida - centro (60,15) pintado", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 60, 15), 9)

  PrintN("")
  PrintN("=== Teste 12: PAINT (flood fill dentro de uma caixa) ===")
  Scr2_ClearFramebuffer(PatternBit(), RowFG(), RowBG())
  Scr2_LineStatement(PatternBit(), RowFG(), RowBG(), 100, 100, 140, 130, 9, 1)
  Scr2_FloodFill(PatternBit(), RowFG(), RowBG(), 120, 115, 4, -1)
  CheckEqual("interior da caixa preenchido", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 120, 115), 4)
  CheckEqual("borda de cima (scanline diferente do fill) continua cor 9", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 120, 100), 9)
  CheckEqual("fora da caixa nao foi afetado", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 200, 115), 1)
  ; Color clash de proposito: o pixel da borda ESQUERDA (100,115) e o
  ; interior logo do lado (101-103,115) estao na MESMA faixa de 8px
  ; (100/8 = 101/8 = ... = 103/8 = 12) e na MESMA scanline (115) - uma vez
  ; que o fill pinta essa faixa de cor 4, a faixa inteira (inclusive a
  ; borda, que continua com o bit aceso) passa a exibir 4. Isso e
  ; hardware real, nao bug - a mesma demonstracao que motivou este editor.
  CheckEqual("clash: borda esquerda (100,115) muda pra cor do fill (mesma faixa)", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 100, 115), 4)

  PrintN("")
  PrintN("=== Teste 13: lista de comandos - replay e geracao de codigo ===")
  NewList Cmds.Scr2_Command()
  AddElement(Cmds()) : Cmds()\CmdType = #Scr2_Cmd_Pset : Cmds()\X1 = 5 : Cmds()\Y1 = 5 : Cmds()\Color1 = 8
  AddElement(Cmds()) : Cmds()\CmdType = #Scr2_Cmd_Line : Cmds()\X1 = 0 : Cmds()\Y1 = 0 : Cmds()\X2 = 20 : Cmds()\Y2 = 0 : Cmds()\Color1 = 3 : Cmds()\BoxMode = 0
  AddElement(Cmds()) : Cmds()\CmdType = #Scr2_Cmd_Draw : Cmds()\X1 = 60 : Cmds()\Y1 = 60 : Cmds()\Color1 = 2 : Cmds()\DrawString = "U5R5"
  Scr2_ReplayAll(PatternBit(), RowFG(), RowBG(), Cmds())
  CheckEqual("replay - PSET (5,5) = cor 8", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 5, 5), 8)
  CheckEqual("replay - LINE (10,0) = cor 3", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 10, 0), 3)
  CheckEqual("replay - DRAW comeca em (60,55) = cor 2", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 60, 55), 2)
  Define GenCode.s = Scr2_GenBasicLines(Cmds())
  CheckEqual("codigo gerado contem PSET", Bool(FindString(GenCode, "PSET (5,5),8") > 0), #True)
  CheckEqual("codigo gerado contem LINE", Bool(FindString(GenCode, "LINE (0,0)-(20,0),3") > 0), #True)
  CheckEqual("codigo gerado contem DRAW", Bool(FindString(GenCode, Chr(34) + "U5R5" + Chr(34)) > 0), #True)
  PrintN(GenCode)

  PrintN("")
  PrintN("=== Teste 14: cursor grafico - PSET/PRESET absolutos e STEP ===")
  Scr2_ClearFramebuffer(PatternBit(), RowFG(), RowBG())
  NewList Cmds14.Scr2_Command()
  AddElement(Cmds14()) : Cmds14()\CmdType = #Scr2_Cmd_Pset : Cmds14()\X1 = 10 : Cmds14()\Y1 = 10 : Cmds14()\Color1 = 8
  AddElement(Cmds14()) : Cmds14()\CmdType = #Scr2_Cmd_Pset : Cmds14()\X1 = 5 : Cmds14()\Y1 = 5 : Cmds14()\Color1 = 8 : Cmds14()\StepP1 = #True
  AddElement(Cmds14()) : Cmds14()\CmdType = #Scr2_Cmd_Preset : Cmds14()\X1 = -5 : Cmds14()\Y1 = -5 : Cmds14()\Color1 = 1 : Cmds14()\StepP1 = #True
  Scr2_ReplayAll(PatternBit(), RowFG(), RowBG(), Cmds14())
  CheckEqual("PSET STEP(5,5) a partir do cursor (10,10) -> pixel (15,15) pintado", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 15, 15), 8)
  CheckEqual("PRESET STEP(-5,-5) a partir do cursor (15,15) -> apaga (10,10)", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 10, 10), 1)
  CheckEqual("cursor final X = 10", Scr2_CursorX, 10)
  CheckEqual("cursor final Y = 10", Scr2_CursorY, 10)

  PrintN("")
  PrintN("=== Teste 15: LINE - STEP no ponto 1, STEP no ponto 2, e sem ponto inicial ===")
  Scr2_ClearFramebuffer(PatternBit(), RowFG(), RowBG())
  NewList Cmds15.Scr2_Command()
  AddElement(Cmds15()) : Cmds15()\CmdType = #Scr2_Cmd_Pset : Cmds15()\X1 = 100 : Cmds15()\Y1 = 50 : Cmds15()\Color1 = 9
  AddElement(Cmds15()) : Cmds15()\CmdType = #Scr2_Cmd_Line : Cmds15()\X1 = 10 : Cmds15()\Y1 = 0 : Cmds15()\StepP1 = #True : Cmds15()\X2 = 130 : Cmds15()\Y2 = 50 : Cmds15()\Color1 = 3
  AddElement(Cmds15()) : Cmds15()\CmdType = #Scr2_Cmd_Line : Cmds15()\LineNoStart = #True : Cmds15()\X2 = 20 : Cmds15()\Y2 = 0 : Cmds15()\StepP2 = #True : Cmds15()\Color1 = 5
  Scr2_ReplayAll(PatternBit(), RowFG(), RowBG(), Cmds15())
  CheckEqual("LINE STEP(10,0) a partir do cursor (100,50) -> ponto1 (110,50), meio (120,50) pintado", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 120, 50), 3)
  CheckEqual("LINE -STEP(20,0): ponto1 = cursor (130,50), meio (140,50) pintado", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 140, 50), 5)
  CheckEqual("cursor final apos as 2 LINEs = 150", Scr2_CursorX, 150)

  PrintN("")
  PrintN("=== Teste 16: CIRCLE e PAINT com STEP no ponto 1 ===")
  Scr2_ClearFramebuffer(PatternBit(), RowFG(), RowBG())
  NewList Cmds16.Scr2_Command()
  AddElement(Cmds16()) : Cmds16()\CmdType = #Scr2_Cmd_Pset : Cmds16()\X1 = 60 : Cmds16()\Y1 = 60 : Cmds16()\Color1 = 2
  AddElement(Cmds16()) : Cmds16()\CmdType = #Scr2_Cmd_Circle : Cmds16()\X1 = 40 : Cmds16()\Y1 = 40 : Cmds16()\StepP1 = #True : Cmds16()\Radius = 10 : Cmds16()\Color1 = 6 : Cmds16()\StartDeg = 0 : Cmds16()\EndDeg = 360
  Scr2_ReplayAll(PatternBit(), RowFG(), RowBG(), Cmds16())
  CheckEqual("CIRCLE STEP(40,40) a partir do cursor (60,60) -> centro (100,100), borda (110,100) pintada", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 110, 100), 6)
  CheckEqual("cursor apos CIRCLE fica no centro (100,100)", Scr2_CursorX, 100)
  AddElement(Cmds16()) : Cmds16()\CmdType = #Scr2_Cmd_Line : Cmds16()\X1 = 150 : Cmds16()\Y1 = 20 : Cmds16()\X2 = 170 : Cmds16()\Y2 = 40 : Cmds16()\Color1 = 9 : Cmds16()\BoxMode = 1
  AddElement(Cmds16()) : Cmds16()\CmdType = #Scr2_Cmd_Paint : Cmds16()\X1 = -10 : Cmds16()\Y1 = -10 : Cmds16()\StepP1 = #True : Cmds16()\Color1 = 4 : Cmds16()\Color2 = -1
  Scr2_ReplayAll(PatternBit(), RowFG(), RowBG(), Cmds16())
  CheckEqual("caixa vazia (LINE B) desenhada, borda (160,20) pintada", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 160, 20), 9)
  CheckEqual("PAINT STEP(-10,-10) a partir do cursor (170,40) -> interior (160,30) preenchido", Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), 160, 30), 4)

  PrintN("")
  PrintN("=== Teste 17: Scr2_ReplayAll reseta o cursor a cada chamada (nao acumula) ===")
  NewList Cmds17.Scr2_Command()
  AddElement(Cmds17()) : Cmds17()\CmdType = #Scr2_Cmd_Pset : Cmds17()\X1 = 5 : Cmds17()\Y1 = 5 : Cmds17()\Color1 = 8 : Cmds17()\StepP1 = #True
  Scr2_ReplayAll(PatternBit(), RowFG(), RowBG(), Cmds17())
  CheckEqual("1a chamada: STEP(5,5) a partir do cursor zerado -> (5,5)", Scr2_CursorX, 5)
  Scr2_ReplayAll(PatternBit(), RowFG(), RowBG(), Cmds17())
  CheckEqual("2a chamada (mesma lista): cursor foi resetado antes do replay -> ainda (5,5), nao (10,10)", Scr2_CursorX, 5)

  PrintN("")
  PrintN("=== Teste 18: geracao de codigo com STEP e LINE sem ponto inicial ===")
  NewList Cmds18.Scr2_Command()
  AddElement(Cmds18()) : Cmds18()\CmdType = #Scr2_Cmd_Pset : Cmds18()\X1 = 5 : Cmds18()\Y1 = 5 : Cmds18()\Color1 = 8 : Cmds18()\StepP1 = #True
  AddElement(Cmds18()) : Cmds18()\CmdType = #Scr2_Cmd_Line : Cmds18()\X1 = 10 : Cmds18()\Y1 = 0 : Cmds18()\StepP1 = #True : Cmds18()\X2 = 130 : Cmds18()\Y2 = 50 : Cmds18()\Color1 = 3
  AddElement(Cmds18()) : Cmds18()\CmdType = #Scr2_Cmd_Line : Cmds18()\LineNoStart = #True : Cmds18()\X2 = 20 : Cmds18()\Y2 = 0 : Cmds18()\StepP2 = #True : Cmds18()\Color1 = 5
  AddElement(Cmds18()) : Cmds18()\CmdType = #Scr2_Cmd_Circle : Cmds18()\X1 = 40 : Cmds18()\Y1 = 40 : Cmds18()\StepP1 = #True : Cmds18()\Radius = 10 : Cmds18()\Color1 = 6 : Cmds18()\StartDeg = 0 : Cmds18()\EndDeg = 360
  AddElement(Cmds18()) : Cmds18()\CmdType = #Scr2_Cmd_Paint : Cmds18()\X1 = -10 : Cmds18()\Y1 = -10 : Cmds18()\StepP1 = #True : Cmds18()\Color1 = 4 : Cmds18()\Color2 = -1
  Define GenCode18.s = Scr2_GenBasicLines(Cmds18())
  CheckEqual("codigo PSET STEP", Bool(FindString(GenCode18, "PSET STEP(5,5),8") > 0), #True)
  CheckEqual("codigo LINE com STEP no ponto 1", Bool(FindString(GenCode18, "LINE STEP(10,0)-(130,50),3") > 0), #True)
  CheckEqual("codigo LINE sem ponto inicial + STEP no ponto 2", Bool(FindString(GenCode18, "LINE -STEP(20,0),5") > 0), #True)
  CheckEqual("codigo CIRCLE STEP", Bool(FindString(GenCode18, "CIRCLE STEP(40,40),10,6") > 0), #True)
  CheckEqual("codigo PAINT STEP", Bool(FindString(GenCode18, "PAINT STEP(-10,-10),4") > 0), #True)
  PrintN(GenCode18)

  PrintN("")
  PrintN("=== Resultado: " + Str(TestCount - FailCount) + "/" + Str(TestCount) + " OK ===")
  If FailCount > 0
    PrintN("REGRESSAO DETECTADA")
  EndIf

  CloseConsole()
EndIf

End FailCount
