;
; ------------------------------------------------------------
;  Motor SCREEN 2 (TMS9918 Graphics II) - FASE 1 do modulo 5 (ver plano em
;  andamento): modelo de dados fiel ao color clash de hardware (framebuffer
;  de bits + tabela de cores por scanline/celula) e o interpretador do
;  comando DRAW (linguagem de tartaruga do MSX-BASIC). Sem GUI - ver
;  editor/tools/Screen2TestCli.pb pro harness headless. Mesmo padrao
;  triadico motor/janela/harness ja usado em PsgSynth.pbi/MmlSynth.pbi
;  (modulos 6/8): a janela (editor/Screen2EditorGui.pbi, com CIRCLE/PAINT/
;  PSET/PRESET/TEXTO e geracao de codigo generica) fica pra uma proxima
;  fase, depois deste motor validado via CLI.
;
;  MODELO DE COR (o motivo de tudo isto existir): a Color Table real do
;  Graphics II guarda 1 byte (nibble alto = cor de tinta/FG, nibble baixo
;  = cor de fundo/BG) por LINHA DE SCANLINE de cada celula de 8 colunas -
;  nao 1 cor por celula inteira (diferenca chave pro attribute clash do
;  ZX Spectrum, que trava por bloco 8x8 inteiro). Isso significa que
;  qualquer faixa horizontal de 8 pixels (mesma linha Y, mesma celula
;  X/8) so pode mostrar 2 cores ao mesmo tempo - e um "color clash" de
;  verdade quando um segundo desenho usa uma cor diferente na mesma
;  faixa. RowFG()/RowBG() abaixo tem exatamente o tamanho da Color Table
;  real (192 linhas x 32 celulas = 6144 bytes cada, igual ao hardware).
;
;  NOTA (assumido, nao verificado contra hardware/emulador real ainda):
;  a direcao de rotacao dos comandos A1/A2/A3/TA do DRAW segue uma
;  convencao interna consistente (rotacao matricial padrao aplicada aos
;  deltas de movimento), mas o SENTIDO exato (horario vs anti-horario
;  visto na tela) ainda nao foi comparado contra o MSX-BASIC de verdade -
;  ponto pra revisar quando a janela (fase 3) permitir ver o resultado.
; ------------------------------------------------------------
;

#Scr2_Width  = 256   ; colunas de pixel (0..255)
#Scr2_Height = 192   ; linhas de pixel / scanlines (0..191)
#Scr2_Cols   = 32    ; celulas de 8px por linha (256/8)

#Scr2_DefaultFG = 15 ; branco - cor inicial de "tinta" de toda faixa nao desenhada
#Scr2_DefaultBG = 1  ; preto - cor inicial de "fundo" de toda faixa nao desenhada

; "Out params" do interpretador DRAW (posicao/cor finais) - mesmo padrao
; de FetchedAlphabetTag em ProjectDB.pbi: a array de retorno ja esta
; ocupada pelo framebuffer, entao o resto do estado final sai por globals
; lidos logo depois de chamar Scr2_ExecuteDraw().
Global Scr2_DrawLastX.i = 0
Global Scr2_DrawLastY.i = 0
Global Scr2_DrawLastColor.i = 0

; Zera o framebuffer inteiro (bits apagados, FG/BG de toda faixa nos
; defaults) - chamar antes de comecar um desenho novo.
Procedure Scr2_ClearFramebuffer(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2))
  Protected Y, X, Cx
  For Y = 0 To #Scr2_Height - 1
    For X = 0 To #Scr2_Width - 1
      PatternBit(Y, X) = 0
    Next
    For Cx = 0 To #Scr2_Cols - 1
      RowFG(Y, Cx) = #Scr2_DefaultFG
      RowBG(Y, Cx) = #Scr2_DefaultBG
    Next
  Next
EndProcedure

; Primitivo unico de escrita - replica fielmente o que a ROM do MSX-BASIC
; faz (nao detecta nem evita clash, so reproduz): TurnOn=#True (equivalente
; a PSET) acende o bit e SOBRESCREVE a cor de tinta (FG) da faixa inteira -
; qualquer outro pixel ja aceso naquela mesma faixa passa a exibir essa cor
; tambem, na proxima leitura (e assim que o clash aparece sozinho, sem
; precisar de logica extra: o render sempre le a mesma RowFG compartilhada
; da faixa). TurnOn=#False (equivalente a PRESET) apaga o bit; se
; ColorIdx>=0 foi passado, tambem atualiza a cor de fundo (BG) da faixa
; (ColorIdx<0 = "sem cor", so apaga o bit). Fora da tela e ignorado (clip
; silencioso, mesmo comportamento de SpriteEd_DrawLine).
Procedure Scr2_SetPixel(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), X.i, Y.i, ColorIdx.i, TurnOn.b)
  If X < 0 Or X >= #Scr2_Width Or Y < 0 Or Y >= #Scr2_Height
    ProcedureReturn
  EndIf
  Protected Cx = X / 8
  If TurnOn
    PatternBit(Y, X) = 1
    If ColorIdx >= 0
      RowFG(Y, Cx) = ColorIdx & $F
    EndIf
  Else
    PatternBit(Y, X) = 0
    If ColorIdx >= 0
      RowBG(Y, Cx) = ColorIdx & $F
    EndIf
  EndIf
EndProcedure

; Cor efetiva pra renderizar o pixel (X,Y) - o que a tela mostraria de
; verdade, incluindo qualquer color clash ja acontecido. Fora da tela
; devolve 0.
Procedure.i Scr2_GetPixelColor(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), X.i, Y.i)
  If X < 0 Or X >= #Scr2_Width Or Y < 0 Or Y >= #Scr2_Height
    ProcedureReturn 0
  EndIf
  Protected Cx = X / 8
  If PatternBit(Y, X)
    ProcedureReturn RowFG(Y, Cx)
  Else
    ProcedureReturn RowBG(Y, Cx)
  EndIf
EndProcedure

; Reta por Bresenham inteiro - mesmo algoritmo de SpriteEd_DrawLine
; (editor/SpriteEditorGui.pbi), so que escrevendo via Scr2_SetPixel em vez
; de um grid de sprite. Usada tanto pelo interpretador DRAW (cada segmento
; de movimento e uma chamada daqui) quanto, numa fase futura, pelo comando
; LINE da janela.
Procedure Scr2_DrawLine(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), X1.i, Y1.i, X2.i, Y2.i, ColorIdx.i)
  Protected DX = Abs(X2 - X1), DY = Abs(Y2 - Y1)
  Protected SX, SY, ErrTerm, E2
  Protected CurX = X1, CurY = Y1
  If X1 < X2 : SX = 1 : Else : SX = -1 : EndIf
  If Y1 < Y2 : SY = 1 : Else : SY = -1 : EndIf
  ErrTerm = DX - DY
  Repeat
    Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), CurX, CurY, ColorIdx, #True)
    If CurX = X2 And CurY = Y2
      Break
    EndIf
    E2 = ErrTerm * 2
    If E2 > -DY
      ErrTerm - DY
      CurX + SX
    EndIf
    If E2 < DX
      ErrTerm + DX
      CurY + SY
    EndIf
  ForEver
EndProcedure

; Arredondamento "half away from zero" pra converter posicao float em
; pixel inteiro - usado em vez de Int() puro (que trunca) porque contas
; com Cos()/Sin() podem devolver algo como 109.99999999999999 em vez de
; 110 exato, e Int() truncaria pro pixel errado.
Procedure.i Scr2_RoundF(V.f)
  If V >= 0
    ProcedureReturn Int(V + 0.5)
  Else
    ProcedureReturn Int(V - 0.5)
  EndIf
EndProcedure

; Interpretador da mini-linguagem de tartaruga do comando DRAW (dialeto
; MSX-BASIC/GW-BASIC): tokeniza DrawString e vai desenhando (via
; Scr2_DrawLine) a partir de (StartX,StartY) com a cor inicial StartColor.
; Devolve a posicao/cor finais via Scr2_DrawLastX/Y/Color (ver comentario
; no topo do arquivo) - util pra encadear varios DRAW mantendo o cursor.
;
; Comandos reconhecidos (letra + numero opcional, tolerante a separador
; ";"/espaco/tab entre eles, exatamente como o BASIC real aceita):
;   U D L R          - move reto (cima/baixo/esquerda/direita), N unidades
;   E F G H          - move na diagonal (NE/SE/SO/NO)
;   M[+-]x,[+-]y      - move pra (x,y) absoluto, ou relativo se x/y tiver sinal
;   B / N             - prefixo do PROXIMO movimento: B = nao traca (so
;                        anda), N = traca mas volta o cursor pro ponto de
;                        partida depois
;   Cn                - troca a cor de tracado atual
;   Sn                - fator de escala (distancia real = valor*escala/4;
;                        default 4 = razao 1:1)
;   An                - angulo em passos de 90 graus (0-3)
;   TAn               - angulo fino em graus (-360..360), sobrescreve A
;   Pc,c2             - preenchimento (equivale a PAINT na posicao atual) -
;                        reconhecido e consumido, mas ainda NAO implementado
;                        (depende de Scr2_FloodFill, fase futura) - vira
;                        no-op por enquanto.
; NAO suportado (limitacao deliberada): Xstring$; (executar sub-string de
; variavel) - nao faz sentido numa ferramenta WYSIWYG sem variaveis BASIC
; de verdade por tras; reconhecido e pulado (ate o ";" seguinte) pra nao
; travar o resto do parser.
Procedure Scr2_ExecuteDraw(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), DrawString.s, StartX.i, StartY.i, StartColor.i)
  Protected UStr.s = UCase(DrawString)
  Protected StrLen = Len(UStr)
  Protected Pos = 1
  Protected Ch.s, Cmd.s
  Protected.f CurX = StartX, CurY = StartY
  Protected CurColor = StartColor
  Protected CurScale = 4
  Protected CurAngleStep = 0
  Protected.f CurAngleFine = 0
  Protected UseFineAngle.b = #False
  Protected NoDraw.b, NoMove.b
  Protected NumStart
  Protected.f Value
  Protected SignX, SignY, SignA
  Protected IsRelX.b, IsRelY.b
  Protected.f Xval, Yval
  Protected.f Dx, Dy, Rdx, Rdy, Dist, AngleRad
  Protected.f RotX, RotY, TmpX
  Protected StepIdx
  Protected.f NewX, NewY

  While Pos <= StrLen
    While Pos <= StrLen And (Mid(UStr, Pos, 1) = " " Or Mid(UStr, Pos, 1) = ";" Or Mid(UStr, Pos, 1) = Chr(9))
      Pos + 1
    Wend
    If Pos > StrLen
      Break
    EndIf

    NoDraw = #False : NoMove = #False
    Ch = Mid(UStr, Pos, 1)
    While Ch = "B" Or Ch = "N"
      If Ch = "B"
        NoDraw = #True
      Else
        NoMove = #True
      EndIf
      Pos + 1
      Ch = Mid(UStr, Pos, 1)
    Wend
    If Ch = ""
      Break
    EndIf

    If Ch = "T" And Mid(UStr, Pos + 1, 1) = "A"
      Cmd = "TA"
      Pos + 2
    Else
      Cmd = Ch
      Pos + 1
    EndIf

    Select Cmd

      Case "M"
        SignX = 1 : SignY = 1 : IsRelX = #False : IsRelY = #False
        If Mid(UStr, Pos, 1) = "+"
          IsRelX = #True : Pos + 1
        ElseIf Mid(UStr, Pos, 1) = "-"
          IsRelX = #True : SignX = -1 : Pos + 1
        EndIf
        NumStart = Pos
        While Pos <= StrLen And Mid(UStr, Pos, 1) >= "0" And Mid(UStr, Pos, 1) <= "9"
          Pos + 1
        Wend
        Xval = Val(Mid(UStr, NumStart, Pos - NumStart)) * SignX
        If Mid(UStr, Pos, 1) = ","
          Pos + 1
        EndIf
        If Mid(UStr, Pos, 1) = "+"
          IsRelY = #True : Pos + 1
        ElseIf Mid(UStr, Pos, 1) = "-"
          IsRelY = #True : SignY = -1 : Pos + 1
        EndIf
        NumStart = Pos
        While Pos <= StrLen And Mid(UStr, Pos, 1) >= "0" And Mid(UStr, Pos, 1) <= "9"
          Pos + 1
        Wend
        Yval = Val(Mid(UStr, NumStart, Pos - NumStart)) * SignY
        If IsRelX
          NewX = CurX + Xval
        Else
          NewX = Xval
        EndIf
        If IsRelY
          NewY = CurY + Yval
        Else
          NewY = Yval
        EndIf
        If Not NoDraw
          Scr2_DrawLine(PatternBit(), RowFG(), RowBG(), Scr2_RoundF(CurX), Scr2_RoundF(CurY), Scr2_RoundF(NewX), Scr2_RoundF(NewY), CurColor)
        EndIf
        If Not NoMove
          CurX = NewX : CurY = NewY
        EndIf

      Case "U", "D", "L", "R", "E", "F", "G", "H"
        NumStart = Pos
        While Pos <= StrLen And Mid(UStr, Pos, 1) >= "0" And Mid(UStr, Pos, 1) <= "9"
          Pos + 1
        Wend
        If Pos > NumStart
          Value = Val(Mid(UStr, NumStart, Pos - NumStart))
        Else
          Value = 1
        EndIf
        Select Cmd
          Case "U" : Dx = 0  : Dy = -1
          Case "D" : Dx = 0  : Dy = 1
          Case "L" : Dx = -1 : Dy = 0
          Case "R" : Dx = 1  : Dy = 0
          Case "E" : Dx = 1  : Dy = -1
          Case "F" : Dx = 1  : Dy = 1
          Case "G" : Dx = -1 : Dy = 1
          Case "H" : Dx = -1 : Dy = -1
        EndSelect
        If UseFineAngle
          ; angulo arbitrario (TA) - so aqui precisa mesmo de trigonometria
          AngleRad = Radian(CurAngleFine)
          Rdx = Dx * Cos(AngleRad) - Dy * Sin(AngleRad)
          Rdy = Dx * Sin(AngleRad) + Dy * Cos(AngleRad)
        Else
          ; rotacao exata em multiplos de 90 graus (A0-3) - sem Cos()/
          ; Sin(), pra nao arriscar erro de ponto flutuante tipo
          ; sin(90)=0.9999999999999999 truncando pro pixel errado; cada
          ; passo de 90 graus e so a troca (Dx,Dy) -> (-Dy,Dx)
          RotX = Dx : RotY = Dy
          For StepIdx = 1 To CurAngleStep
            TmpX = RotX
            RotX = -RotY
            RotY = TmpX
          Next
          Rdx = RotX
          Rdy = RotY
        EndIf
        Dist = Value * CurScale / 4
        NewX = CurX + Rdx * Dist
        NewY = CurY + Rdy * Dist
        If Not NoDraw
          Scr2_DrawLine(PatternBit(), RowFG(), RowBG(), Scr2_RoundF(CurX), Scr2_RoundF(CurY), Scr2_RoundF(NewX), Scr2_RoundF(NewY), CurColor)
        EndIf
        If Not NoMove
          CurX = NewX : CurY = NewY
        EndIf

      Case "C"
        NumStart = Pos
        While Pos <= StrLen And Mid(UStr, Pos, 1) >= "0" And Mid(UStr, Pos, 1) <= "9"
          Pos + 1
        Wend
        If Pos > NumStart
          CurColor = Val(Mid(UStr, NumStart, Pos - NumStart)) & $F
        EndIf

      Case "S"
        NumStart = Pos
        While Pos <= StrLen And Mid(UStr, Pos, 1) >= "0" And Mid(UStr, Pos, 1) <= "9"
          Pos + 1
        Wend
        If Pos > NumStart
          CurScale = Val(Mid(UStr, NumStart, Pos - NumStart))
        EndIf

      Case "A"
        NumStart = Pos
        While Pos <= StrLen And Mid(UStr, Pos, 1) >= "0" And Mid(UStr, Pos, 1) <= "9"
          Pos + 1
        Wend
        If Pos > NumStart
          CurAngleStep = Val(Mid(UStr, NumStart, Pos - NumStart)) % 4
          UseFineAngle = #False
        EndIf

      Case "TA"
        SignA = 1
        If Mid(UStr, Pos, 1) = "+"
          Pos + 1
        ElseIf Mid(UStr, Pos, 1) = "-"
          SignA = -1 : Pos + 1
        EndIf
        NumStart = Pos
        While Pos <= StrLen And Mid(UStr, Pos, 1) >= "0" And Mid(UStr, Pos, 1) <= "9"
          Pos + 1
        Wend
        If Pos > NumStart
          CurAngleFine = Val(Mid(UStr, NumStart, Pos - NumStart)) * SignA
          UseFineAngle = #True
        EndIf

      Case "P"
        NumStart = Pos
        While Pos <= StrLen And Mid(UStr, Pos, 1) >= "0" And Mid(UStr, Pos, 1) <= "9"
          Pos + 1
        Wend
        If Mid(UStr, Pos, 1) = ","
          Pos + 1
          NumStart = Pos
          While Pos <= StrLen And Mid(UStr, Pos, 1) >= "0" And Mid(UStr, Pos, 1) <= "9"
            Pos + 1
          Wend
        EndIf

      Case "X"
        While Pos <= StrLen And Mid(UStr, Pos, 1) <> ";"
          Pos + 1
        Wend
        If Pos <= StrLen
          Pos + 1
        EndIf

      Default
        ; comando desconhecido/caractere solto - ignora e segue, mesmo
        ; espirito tolerante do parser MML (nunca trava a previa por um
        ; erro de digitacao)

    EndSelect
  Wend

  Scr2_DrawLastX = Scr2_RoundF(CurX)
  Scr2_DrawLastY = Scr2_RoundF(CurY)
  Scr2_DrawLastColor = CurColor
EndProcedure

; Gera a linha BASIC do comando DRAW isolado - usado tanto pelo tipo
; #Scr2_Cmd_Draw de Scr2_GenBasicLines() abaixo quanto por quem so quer um
; DRAW solto sem passar pela lista de comandos.
Procedure.s Scr2_GenDrawStatement(DrawString.s)
  ProcedureReturn "DRAW " + Chr(34) + DrawString + Chr(34)
EndProcedure

; ------------------------------------------------------------
;  FASE 2: PSET/PRESET/LINE (wrappers finos sobre os primitivos acima),
;  CIRCLE (arco parametrico, cobre circulo/elipse/fatia de pizza) e PAINT
;  (flood fill 4-direcoes) - mais a lista de comandos mistos que a janela
;  (fase 3) vai manter e re-executar do zero a cada mudanca (mesmo
;  espirito de "replay" das listas de passos/linhas do PSG/MML).
; ------------------------------------------------------------

Procedure Scr2_Pset(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), X.i, Y.i, ColorIdx.i)
  Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), X, Y, ColorIdx, #True)
EndProcedure

Procedure Scr2_Preset(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), X.i, Y.i, ColorIdx.i)
  Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), X, Y, ColorIdx, #False)
EndProcedure

; BoxMode: 0 = reta normal, 1 = caixa vazia (equivalente a "LINE...,B"),
; 2 = caixa preenchida (equivalente a "LINE...,BF").
Procedure Scr2_LineStatement(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), X1.i, Y1.i, X2.i, Y2.i, ColorIdx.i, BoxMode.i)
  Protected MinX, MaxX, MinY, MaxY, Yi
  Select BoxMode
    Case 1
      Scr2_DrawLine(PatternBit(), RowFG(), RowBG(), X1, Y1, X2, Y1, ColorIdx)
      Scr2_DrawLine(PatternBit(), RowFG(), RowBG(), X2, Y1, X2, Y2, ColorIdx)
      Scr2_DrawLine(PatternBit(), RowFG(), RowBG(), X2, Y2, X1, Y2, ColorIdx)
      Scr2_DrawLine(PatternBit(), RowFG(), RowBG(), X1, Y2, X1, Y1, ColorIdx)
    Case 2
      MinX = X1 : MaxX = X2 : If MinX > MaxX : Swap MinX, MaxX : EndIf
      MinY = Y1 : MaxY = Y2 : If MinY > MaxY : Swap MinY, MaxY : EndIf
      For Yi = MinY To MaxY
        Scr2_DrawLine(PatternBit(), RowFG(), RowBG(), MinX, Yi, MaxX, Yi, ColorIdx)
      Next
    Default
      Scr2_DrawLine(PatternBit(), RowFG(), RowBG(), X1, Y1, X2, Y2, ColorIdx)
  EndSelect
EndProcedure

#Scr2_PI = 3.14159265358979

; CIRCLE parametrico: cobre circulo (Aspect=0 -> tratado como 1, circulo
; de verdade), elipse (Aspect<>0, razao altura/largura) e arco/fatia de
; pizza (StartAngle<>EndAngle, radianos) numa formula so - amostra pontos
; ao longo do arco e liga cada par consecutivo com Scr2_DrawLine (em vez
; de um midpoint-circle "de verdade"), simples e correto pra qualquer
; combinacao de aspecto/angulo, ao custo de nao ser o algoritmo mais
; rapido possivel (irrelevante na escala de uma janela de edicao).
; PieStart/PieEnd = #True tracam uma reta do centro ate a ponta do arco
; correspondente (equivalente a angulo negativo no CIRCLE do MSX-BASIC).
Procedure Scr2_DrawCircle(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), CX.i, CY.i, Radius.i, ColorIdx.i, StartAngle.f, EndAngle.f, Aspect.f, PieStart.b = #False, PieEnd.b = #False)
  Protected.f RX = Radius, RY
  If Aspect = 0
    RY = Radius
  Else
    RY = Radius * Aspect
  EndIf
  Protected Steps = Radius * 4
  If Steps < 36
    Steps = 36
  EndIf
  Protected.f Total = EndAngle - StartAngle
  If Total = 0
    Total = 2 * #Scr2_PI
    EndAngle = StartAngle + Total
  EndIf
  Protected i, PrevX, PrevY, CurPX, CurPY
  Protected.f Ang
  PrevX = CX + Scr2_RoundF(RX * Cos(StartAngle))
  PrevY = CY - Scr2_RoundF(RY * Sin(StartAngle))
  If PieStart
    Scr2_DrawLine(PatternBit(), RowFG(), RowBG(), CX, CY, PrevX, PrevY, ColorIdx)
  EndIf
  For i = 1 To Steps
    Ang = StartAngle + Total * i / Steps
    CurPX = CX + Scr2_RoundF(RX * Cos(Ang))
    CurPY = CY - Scr2_RoundF(RY * Sin(Ang))
    Scr2_DrawLine(PatternBit(), RowFG(), RowBG(), PrevX, PrevY, CurPX, CurPY, ColorIdx)
    PrevX = CurPX : PrevY = CurPY
  Next
  If PieEnd
    Scr2_DrawLine(PatternBit(), RowFG(), RowBG(), CX, CY, PrevX, PrevY, ColorIdx)
  EndIf
EndProcedure

; PAINT: preenchimento por area conectada, pilha explicita 4-direcoes -
; mesmo algoritmo de SpriteEd_FloodFill (editor/SpriteEditorGui.pbi),
; adaptado pra ler/escrever cor via Scr2_GetPixelColor/Scr2_SetPixel em vez
; de um grid de sprite. BorderColor<0 = sem cor de borda (preenche a
; regiao inteira da MESMA cor que estava no ponto de partida, como
; PAINT(x,y),c sem o parametro de borda); BorderColor>=0 = preenche tudo
; que nao for a cor de borda nem ja a cor de preenchimento (comportamento
; de PAINT(x,y),c,bordercolor - pode "vazar" por cima de cores diferentes
; da de partida, exatamente como o PAINT real).
Structure Scr2_FillPoint
  X.i
  Y.i
EndStructure

Procedure Scr2_FloodFill(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), StartX.i, StartY.i, FillColor.i, BorderColor.i = -1)
  Protected TargetColor = Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), StartX, StartY)
  If BorderColor < 0 And TargetColor = FillColor
    ProcedureReturn
  EndIf
  NewList Stack.Scr2_FillPoint()
  AddElement(Stack()) : Stack()\X = StartX : Stack()\Y = StartY
  Protected PX, PY, CurColor
  Protected ShouldFill.b
  While ListSize(Stack()) > 0
    LastElement(Stack())
    PX = Stack()\X : PY = Stack()\Y
    DeleteElement(Stack())
    If PX >= 0 And PX < #Scr2_Width And PY >= 0 And PY < #Scr2_Height
      CurColor = Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), PX, PY)
      ShouldFill = #False
      If BorderColor >= 0
        If CurColor <> BorderColor And CurColor <> FillColor
          ShouldFill = #True
        EndIf
      Else
        If CurColor = TargetColor And CurColor <> FillColor
          ShouldFill = #True
        EndIf
      EndIf
      If ShouldFill
        Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), PX, PY, FillColor, #True)
        AddElement(Stack()) : Stack()\X = PX + 1 : Stack()\Y = PY
        AddElement(Stack()) : Stack()\X = PX - 1 : Stack()\Y = PY
        AddElement(Stack()) : Stack()\X = PX     : Stack()\Y = PY + 1
        AddElement(Stack()) : Stack()\X = PX     : Stack()\Y = PY - 1
      EndIf
    EndIf
  Wend
EndProcedure

; ------------------------------------------------------------
;  Lista de comandos mistos - o que a janela (fase 3) guarda/edita/
;  reordena (ListIconGadget, Adicionar/Atualizar/Remover/Mover, mesmo
;  padrao da lista de passos do PSG/linhas do MML) e o que fica salvo no
;  projeto. Scr2_ReplayAll() reconstroi o framebuffer do zero a cada
;  mudanca (mesma filosofia "sem estado incremental fragil" do replay de
;  passos do PSG); Scr2_GenBasicLines() gera o codigo BASIC final, um
;  comando por linha, na mesma ordem.
;
;  #Scr2_Cmd_Text e reconhecido aqui mas o BLIT do glifo (que precisa dos
;  bytes de um alfabeto do projeto) fica a cargo da janela/GUI - o motor
;  nao depende do ProjectDB (mesma separacao de PsgSynth.pbi/MmlSynth.pbi,
;  que tambem nunca importam ProjectDB.pbi).
; ------------------------------------------------------------

#Scr2_Cmd_Pset   = 0
#Scr2_Cmd_Preset = 1
#Scr2_Cmd_Line   = 2
#Scr2_Cmd_Circle = 3
#Scr2_Cmd_Paint  = 4
#Scr2_Cmd_Draw   = 5
#Scr2_Cmd_Text   = 6

Structure Scr2_Command
  CmdType.i
  X1.i
  Y1.i
  X2.i
  Y2.i
  Radius.i
  Color1.i
  Color2.i
  StartDeg.f
  EndDeg.f
  Aspect.f
  PieStart.b
  PieEnd.b
  BoxMode.i
  DrawString.s
  ; STEP (ver comentario grande antes de Scr2_ReplayCommand): StepP1 - X1/Y1
  ; e um DESLOCAMENTO a partir do cursor grafico atual, nao coordenada
  ; absoluta. StepP2 - so LINE, mesma ideia pro X2/Y2 (relativo ao PONTO 1
  ; da propria LINE, nao ao cursor). LineNoStart - so LINE, equivale a
  ; "LINE -(x2,y2)" do MSX-BASIC (sem ponto inicial nenhum, usa o cursor
  ; atual como esta) - quando #True, X1/Y1/StepP1 sao ignorados.
  StepP1.b
  StepP2.b
  LineNoStart.b
  ; So usados pelo #Scr2_Cmd_Text (fase 3): X1/Y1 (acima) sao o ponto de
  ; ancora em PIXEL (canto superior esquerdo do texto), igual a qualquer
  ; outro comando - nao coluna/linha de celula de caractere. Third e
  ; derivado de Y1 (Y1\64) na hora de gerar o carregador VPOKE do alfabeto.
  TextStr.s
  Third.i
  AlphaNum.i
EndStructure

; "Cursor grafico" do MSX-BASIC (a posicao que STEP usa como referencia) -
; PSET/PRESET/LINE/CIRCLE/PAINT de verdade sempre deixam o cursor na ultima
; coordenada de referencia usada (LINE deixa no ponto final; CIRCLE/PAINT/
; PSET/PRESET deixam no proprio ponto). Scr2_ReplayAll() reseta pra (0,0)
; no comeco de cada replay (mesmo estado inicial de um SCREEN 2 novo);
; DRAW tambem atualiza (via Scr2_DrawLastX/Y, ja calculado por
; Scr2_ExecuteDraw); TEXTO (LOCATE/PRINT) NAO mexe aqui - e um cursor de
; texto separado do cursor grafico no MSX-BASIC de verdade.
Global Scr2_CursorX.i = 0
Global Scr2_CursorY.i = 0

; Resolve o ponto (X1,Y1) de um comando contra o cursor grafico atual
; (Scr2_CursorX/Y) - StepP1 faz X1/Y1 serem lidos como deslocamento em vez
; de coordenada absoluta. Duas funcoes (X e Y) em vez de uma so com
; parametros de saida por ponteiro, porque PureBasic so deixa dereferenciar
; ponteiro com "\campo" pra ponteiro de Structure, nao de tipo basico.
Procedure.i Scr2_ResolveP1X(*Cmd.Scr2_Command)
  If *Cmd\StepP1
    ProcedureReturn Scr2_CursorX + *Cmd\X1
  Else
    ProcedureReturn *Cmd\X1
  EndIf
EndProcedure

Procedure.i Scr2_ResolveP1Y(*Cmd.Scr2_Command)
  If *Cmd\StepP1
    ProcedureReturn Scr2_CursorY + *Cmd\Y1
  Else
    ProcedureReturn *Cmd\Y1
  EndIf
EndProcedure

Procedure Scr2_ReplayCommand(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), *Cmd.Scr2_Command)
  Protected RX1.i, RY1.i, RX2.i, RY2.i
  Select *Cmd\CmdType
    Case #Scr2_Cmd_Pset
      RX1 = Scr2_ResolveP1X(*Cmd) : RY1 = Scr2_ResolveP1Y(*Cmd)
      Scr2_Pset(PatternBit(), RowFG(), RowBG(), RX1, RY1, *Cmd\Color1)
      Scr2_CursorX = RX1 : Scr2_CursorY = RY1
    Case #Scr2_Cmd_Preset
      RX1 = Scr2_ResolveP1X(*Cmd) : RY1 = Scr2_ResolveP1Y(*Cmd)
      Scr2_Preset(PatternBit(), RowFG(), RowBG(), RX1, RY1, *Cmd\Color1)
      Scr2_CursorX = RX1 : Scr2_CursorY = RY1
    Case #Scr2_Cmd_Line
      ; ponto 1: sem inicio explicito (equivalente a "LINE -(x2,y2)") usa o
      ; cursor como esta; senao resolve STEP contra o cursor normalmente.
      ; ponto 2: STEP e relativo ao PONTO 1 desta mesma LINE (nao ao
      ; cursor pre-comando) - assim "LINE (x,y)-STEP(dx,dy)" significa
      ; "desenha dx,dy a partir do primeiro ponto", igual ao MSX-BASIC real.
      If *Cmd\LineNoStart
        RX1 = Scr2_CursorX : RY1 = Scr2_CursorY
      Else
        RX1 = Scr2_ResolveP1X(*Cmd) : RY1 = Scr2_ResolveP1Y(*Cmd)
      EndIf
      If *Cmd\StepP2
        RX2 = RX1 + *Cmd\X2 : RY2 = RY1 + *Cmd\Y2
      Else
        RX2 = *Cmd\X2 : RY2 = *Cmd\Y2
      EndIf
      Scr2_LineStatement(PatternBit(), RowFG(), RowBG(), RX1, RY1, RX2, RY2, *Cmd\Color1, *Cmd\BoxMode)
      Scr2_CursorX = RX2 : Scr2_CursorY = RY2
    Case #Scr2_Cmd_Circle
      RX1 = Scr2_ResolveP1X(*Cmd) : RY1 = Scr2_ResolveP1Y(*Cmd)
      Scr2_DrawCircle(PatternBit(), RowFG(), RowBG(), RX1, RY1, *Cmd\Radius, *Cmd\Color1, Radian(*Cmd\StartDeg), Radian(*Cmd\EndDeg), *Cmd\Aspect, *Cmd\PieStart, *Cmd\PieEnd)
      Scr2_CursorX = RX1 : Scr2_CursorY = RY1
    Case #Scr2_Cmd_Paint
      RX1 = Scr2_ResolveP1X(*Cmd) : RY1 = Scr2_ResolveP1Y(*Cmd)
      Scr2_FloodFill(PatternBit(), RowFG(), RowBG(), RX1, RY1, *Cmd\Color1, *Cmd\Color2)
      Scr2_CursorX = RX1 : Scr2_CursorY = RY1
    Case #Scr2_Cmd_Draw
      Scr2_ExecuteDraw(PatternBit(), RowFG(), RowBG(), *Cmd\DrawString, *Cmd\X1, *Cmd\Y1, *Cmd\Color1)
      Scr2_CursorX = Scr2_DrawLastX : Scr2_CursorY = Scr2_DrawLastY
    Case #Scr2_Cmd_Text
      ; nao-op no motor - ver comentario acima (a GUI blita o texto ela
      ; mesma, chamando Scr2_SetPixel com os bytes do alfabeto que ela
      ; buscou no ProjectDB); LOCATE/PRINT nao mexem no cursor GRAFICO.
  EndSelect
EndProcedure

Procedure Scr2_ReplayAll(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), List Commands.Scr2_Command())
  Scr2_ClearFramebuffer(PatternBit(), RowFG(), RowBG())
  Scr2_CursorX = 0 : Scr2_CursorY = 0
  ForEach Commands()
    Scr2_ReplayCommand(PatternBit(), RowFG(), RowBG(), @Commands())
  Next
EndProcedure

; Monta o texto "(x,y)" ou "STEP(x,y)" de um ponto, conforme a flag STEP do
; comando - usado por Scr2_GenBasicLines pra gerar sintaxe BASIC real.
Procedure.s Scr2_GenPointStr(X.i, Y.i, UseStep.b)
  If UseStep
    ProcedureReturn "STEP(" + Str(X) + "," + Str(Y) + ")"
  Else
    ProcedureReturn "(" + Str(X) + "," + Str(Y) + ")"
  EndIf
EndProcedure

; Gera o codigo BASIC final, um comando por linha, na mesma ordem da
; lista - mesmo padrao de string-building simples de
; PsgGen_BasicLines/PsgGen_RawBytes (editor/PsgSynth.pbi). Angulos de
; CIRCLE sao guardados em graus na lista (mais amigavel de digitar) e
; convertidos pra radianos so aqui, na hora de gerar o texto BASIC de
; verdade (que exige radianos) - StartDeg=0/EndDeg=360 sem fatia de pizza
; e tratado como "circulo completo", omitindo os parametros opcionais.
; STEP/"sem ponto inicial" (LINE -(x,y)) sao emitidos textualmente aqui,
; refletindo exatamente o que Scr2_ReplayCommand calcula em tempo de
; desenho (a resolucao contra o cursor grafico so acontece no MSX real).
Procedure.s Scr2_GenBasicLines(List Commands.Scr2_Command())
  Protected Result.s = ""
  Protected Suffix.s, Line2.s, PaintLine.s
  Protected.f StartRad, EndRad
  ForEach Commands()
    Select Commands()\CmdType
      Case #Scr2_Cmd_Pset
        Result + "PSET " + Scr2_GenPointStr(Commands()\X1, Commands()\Y1, Commands()\StepP1) + "," + Str(Commands()\Color1) + #CRLF$
      Case #Scr2_Cmd_Preset
        Result + "PRESET " + Scr2_GenPointStr(Commands()\X1, Commands()\Y1, Commands()\StepP1) + "," + Str(Commands()\Color1) + #CRLF$
      Case #Scr2_Cmd_Line
        Suffix = ""
        If Commands()\BoxMode = 1
          Suffix = ",B"
        ElseIf Commands()\BoxMode = 2
          Suffix = ",BF"
        EndIf
        If Commands()\LineNoStart
          Result + "LINE -" + Scr2_GenPointStr(Commands()\X2, Commands()\Y2, Commands()\StepP2) + "," + Str(Commands()\Color1) + Suffix + #CRLF$
        Else
          Result + "LINE " + Scr2_GenPointStr(Commands()\X1, Commands()\Y1, Commands()\StepP1) + "-" + Scr2_GenPointStr(Commands()\X2, Commands()\Y2, Commands()\StepP2) + "," + Str(Commands()\Color1) + Suffix + #CRLF$
        EndIf
      Case #Scr2_Cmd_Circle
        Line2 = "CIRCLE " + Scr2_GenPointStr(Commands()\X1, Commands()\Y1, Commands()\StepP1) + "," + Str(Commands()\Radius) + "," + Str(Commands()\Color1)
        StartRad = Radian(Commands()\StartDeg)
        EndRad = Radian(Commands()\EndDeg)
        If Commands()\PieStart : StartRad = -StartRad : EndIf
        If Commands()\PieEnd   : EndRad = -EndRad : EndIf
        If Commands()\StartDeg <> 0 Or Commands()\EndDeg <> 360 Or Commands()\PieStart Or Commands()\PieEnd
          Line2 + "," + StrF(StartRad, 6) + "," + StrF(EndRad, 6)
          If Commands()\Aspect <> 0
            Line2 + "," + StrF(Commands()\Aspect, 4)
          EndIf
        ElseIf Commands()\Aspect <> 0
          Line2 + ",,," + StrF(Commands()\Aspect, 4)
        EndIf
        Result + Line2 + #CRLF$
      Case #Scr2_Cmd_Paint
        PaintLine = "PAINT " + Scr2_GenPointStr(Commands()\X1, Commands()\Y1, Commands()\StepP1) + "," + Str(Commands()\Color1)
        If Commands()\Color2 >= 0
          PaintLine + "," + Str(Commands()\Color2)
        EndIf
        Result + PaintLine + #CRLF$
      Case #Scr2_Cmd_Draw
        Result + Scr2_GenDrawStatement(Commands()\DrawString) + #CRLF$
      Case #Scr2_Cmd_Text
        Result + "' TODO: texto com alfabeto customizado (terco " + Str(Commands()\Third) + ") - ver carregador VPOKE" + #CRLF$
    EndSelect
  Next
  ProcedureReturn Result
EndProcedure
