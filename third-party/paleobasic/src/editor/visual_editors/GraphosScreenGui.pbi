;
; ------------------------------------------------------------
;  Criar -> Graphos III Screen 2...: primeiro editor da familia "Graphos
;  III" nesta IDE (ver graphos/graphos.txt, manual original do programa,
;  Renato Degiovani 1987 / A&L Software 1997) - reproduz o modulo EDITA
;  TELA do Graphos III original, focado em telas/shapes/layout. O editor de
;  alfabetos do Graphos III JA existe nesta IDE (CharsetEditorGui.pbi,
;  formato .ALF) - pedido explicito do usuario pra NAO duplicar essa parte
;  aqui, cada funcao do Graphos III vira uma opcao separada dentro de
;  "Criar", e esta e a primeira: a tela.
;
;  O Graphos III original usava as teclas F1-F5 pra abrir os menus DESENHO/
;  TEXTO/TELA/AJUSTE/MISCELANEA - aqui cada operacao vira um botao/icone, no
;  mesmo espirito do editor de sprites (SpriteEditorGui.pbi), em vez de
;  teclas de funcao.
;
;  FASE 1 cobriu so "a tela que representa a SCREEN 2": canvas com color
;  clash identico ao MSX (motor editor/Screen2Synth.pbi, 69 casos de teste),
;  paleta INK/PAPER, TRACO (Lapis/Borracha) e LIMPA TELA.
;
;  FASE 2 (esta sessao) completa o resto do menu DESENHO (F1) do Graphos III
;  original: BLOCO, LINHA, RETANGULO, RAIO, CIRCULO, PINTURA, SPRAY e FILL.
;  Nenhuma dessas operacoes precisou de motor novo - Scr2_DrawLine (reta),
;  Scr2_LineStatement (BoxMode=1, contorno de retangulo) e Scr2_DrawCircle ja
;  existiam prontos em Screen2Synth.pbi (usados pelo editor "Draw Screen
;  2..."), assim como Scr2_FloodFill (FILL). So PINTURA (altera so a cor de
;  FUNDO da faixa, sem tocar no bit do pixel nem na cor de FRENTE) e SPRAY
;  (borrifo aleatorio) sao logica nova, pequena, escrita abaixo.
;
;  Igual ao Graphos III original ("os atributos de todas as posicoes
;  alteradas recebem a cor de FRENTE selecionada, com excecao de PINTURA,
;  que so mexe no FUNDO"): TRACO/BLOCO/LINHA/RETANGULO/RAIO/CIRCULO/SPRAY/
;  FILL desenham com INK; so PINTURA usa PAPER. E, tambem fiel ao original
;  ("INSERT/DELETE funciona com TRACO, BLOCO, SPRAY e todo o menu de
;  TEXTO"), so essas tres ferramentas respeitam o alternador Lapis(INS)/
;  Borracha(DEL) (o TEXTO, hoje ja implementado na fase 3, nunca apaga -
;  sempre imprime com as cores escolhidas) - LINHA/RETANGULO/RAIO/
;  CIRCULO/FILL sempre desenham (nunca apagam) e PINTURA sempre pinta com
;  PAPER, entao o alternador fica desabilitado quando uma dessas esta ativa.
;
;  LINHA/RETANGULO/RAIO/CIRCULO seguem o mesmo padrao de "ancora + previa
;  elastica + segundo clique confirma" do editor "Draw Screen 2..."
;  (reaproveita Scr2Ed_DrawLinePreview/DrawCirclePreview de
;  Screen2EditorGui.pbi, sem duplicar o desenho da previa), mas com uma
;  diferenca de semantica ditada pelo manual original: em LINHA o ponto
;  final vira automaticamente o ponto inicial do proximo segmento (encadeia,
;  poligono aberto); em RETANGULO/RAIO/CIRCULO a ancora (vertice fixo/origem
;  do raio/centro) permanece FIXA entre desenhos - o usuario clica varias
;  vezes e cada clique produz uma nova forma a partir da MESMA ancora, ate
;  cancelar com o botao direito (equivalente ao ESC do original) ou trocar
;  de ferramenta.
;
;  FASE 3 (esta sessao) implementa o menu TEXTO (F2): escreve na tela com um
;  alfabeto ja registrado no projeto (Criar -> Alfabeto Graphos III...,
;  ProjectDB::FetchAlphabet - mesmo formato 256x8 do modulo 4), nas 6
;  variacoes do manual original - NORMAL, ITALIC, BOLD, DUPLO (dupla
;  altura), DUPLO BOLD (dupla altura e largura) e LARGO (dupla largura).
;  ITALIC/BOLD reaproveitam as MESMAS transformacoes de bits ja escritas pro
;  editor de alfabetos (CharEd_ItalicEditGrid/BoldEditGrid,
;  CharsetEditorGui.pbi, modulo 4c) sem duplicar a formula - a diferenca e
;  que aqui a transformacao e' aplicada so na hora de desenhar (o alfabeto
;  guardado no banco nunca e' alterado). DUPLO/LARGO/DUPLO BOLD sao
;  duplicacao geometrica de linha/coluna no framebuffer (nao mexem no
;  formato do glifo), igual ao "dupla altura/largura" classico de impressora
;  matricial que da nome as opcoes. Mesmo padrao de "Posicionar -> previa
;  elastica segue o mouse -> clique fixa" ja usado pela ferramenta TEXTO do
;  editor "Draw Screen 2..." (Scr2Ed_DrawTextPreview original, aqui
;  reescrito como GraphosScr_DrawTextPreview pra suportar as 6 variacoes),
;  so que sem o grid de 8px/STEP (irrelevante aqui, ja que este editor nao
;  gera codigo BASIC ainda - so framebuffer).
;
;  FASE 4 (esta sessao) implementa o menu TELA (F3): SALVA TELA/Restaurar
;  (buffer da tela inteira - pixels + INK + PAPER), INVERTE VIDEO (so
;  pixels)/INVERTE ATRIBUTOS (so cores), RETIRA VIDEO/REPOE VIDEO (backup e
;  restauracao so dos pixels) e RETIRA ATRIBUTOS/REPOE ATRIBUTOS (idem so
;  das cores) - LIMPA TELA ja existia desde a fase 1. IMPRIME TELA fica de
;  fora (nao ha suporte a impressora nesta IDE). Cada par RETIRA/REPOE usa
;  seu proprio slot de backup (video/atributos/tela inteira sao 3 backups
;  independentes, nao um "buffer" unico compartilhado como no original) -
;  mais simples de raciocinar e nao exige reproduzir o "HOME/CLS restaura o
;  ultimo passo, sempre" do Graphos III de verdade (isso seria um undo geral
;  pra QUALQUER operacao desta janela, fora de escopo aqui).
;
;  Pedido explicito do usuario nesta sessao, alem da FASE 4: reorganizar o
;  layout (a coluna direita estava ficando alta demais, com a area abaixo do
;  canvas praticamente vazia) e usar icone em todo botao de acao. As duas
;  grades de ferramentas (DESENHO/TELA) passam de 3 pra 5 icones por linha
;  (RightW 160->200), cortando 1 linha de cada uma. RETIRA/REPOE (video e
;  atributos) compartilham um unico gerador de icone parametrizado
;  (GraphosScr_CreateRetiraRepoeIcon) em vez de 4 quase-identicos. TEXTO
;  (unico que sobrou fora da coluna direita) desce pra uma faixa abaixo do
;  canvas, uma linha por opcao (label + campo, pedido explicito do usuario
;  - "linha a linha", nao tudo espremido lado a lado numa linha so); BLOCO
;  (tamanho do cursor da ferramenta BLOCO), que tambem tinha ido pra essa
;  faixa numa primeira tentativa, voltou pra coluna direita, logo abaixo da
;  grade DESENHO (pedido explicito do usuario - fica junto da ferramenta
;  que ele configura). Tambem nesta sessao (fora deste arquivo):
;  `BadigEditor.pb` ganhou `App_EnsureDefaultAlphabet()`, chamada uma vez no
;  arranque da IDE - garante que o projeto ativo sempre tenha um alfabeto
;  com a tag "padrao" (semeado do mesmo charset MSX embutido que "Novo
;  alfabeto" ja usa), pra este editor (menu TEXTO) e qualquer outro
;  consumidor futuro sempre terem um alfabeto pronto sem passar por "Criar
;  -> Alfabeto Graphos III..." primeiro.
;
;  FASE 5 (esta sessao): persistencia no projeto (.msxproject) - pedido
;  explicito do usuario ("colocar os trabalhos do Graphos no arquivo de
;  Projeto tambem. Telas, shapes, layouts"). Tres tabelas novas em
;  ProjectDB.pbi (graphos_screens/graphos_layouts/graphos_shapes, ver
;  comentario grande la - framebuffer puro, DIFERENTE da tabela "screens" ja
;  existente do editor "Draw Screen 2..." modulo 5, que guarda lista de
;  comandos), cada uma com o MESMO padrao numero/navegacao/tag/Novo/
;  Registrar ja usado pelo editor de sprites/alfabetos
;  (CharEd_CreateNavIcon/NewIcon/RegisterIcon, #CharEd_IconBtnW/H,
;  SpriteEd_FindNavTarget - tudo reaproveitado, nada novo):
;
;  - TELA e LAYOUT compartilham o MESMO canvas em edicao e a MESMA flag
;    CanvasDirty - sao 2 "formatos de salvar" o mesmo framebuffer (TELA =
;    pixels + cores; LAYOUT = so pixels, equivalente ao .LAY original), nao
;    2 documentos independentes. "Novo" em qualquer um limpa o canvas
;    (Scr2_ClearFramebuffer) e numera automaticamente (maior numero + 1, ou
;    0 se a lista estiver vazia); navegar (Primeiro/Anterior/Proximo/
;    Ultimo) busca do projeto e substitui o canvas inteiro. Pedido de
;    confirmacao (GraphosScr_ConfirmDiscardChanges) antes de descartar
;    alteracoes nao registradas, mesmo padrao de
;    CharEd_ConfirmDiscardAlphabet/Scr2Ed_ConfirmDiscardScreen.
;  - SHAPE e' um recorte retangular de tamanho VARIAVEL, buffer proprio
;    (ShapeCapturePattern/FG/BG, ShapeDirty independente do canvas
;    principal) - "Marcar area..." arma um modo de 2 cliques igual RETANGULO
;    (ShapeMarkPending/ShapeMarkHasAnchor, previa via
;    Scr2Ed_DrawLinePreview BoxMode=1) que CAPTURA o recorte marcado do
;    canvas principal pro buffer do shape (nao desenha nada) assim que o 2o
;    canto e' clicado. O eixo X da selecao e' sempre alinhado (snap) ao grid
;    de 8px antes de capturar - garante que cada celula de cor local do
;    shape corresponda a uma celula INTEIRA da tela de origem, sem precisar
;    reamostrar/interpolar cor nenhuma (Y nao precisa de snap, ja que a cor
;    e' por linha de varredura, nao por bloco 8x8). Previa em miniatura
;    (GraphosScr_RedrawShapePreview) escala o recorte pra caber numa caixa
;    fixa de 150x70, ja que nao da pra reaproveitar Scr2Ed_RedrawCanvas
;    (fixo em 256x192/zoom 2).
;
;  Deliberadamente FORA desta fase: escolha de mascara/tipo do SHAPE (isso
;  e' CRIA SHAPES de verdade, seção 3.8 do manual - fica pro carimbo/AND/OR/
;  XOR de MISCELANEA, fase futura); os formatos de arquivo nativos DISPLAY
;  (.SCR)/LAYOUT (.LAY)/COMPAC (.VTC+.ATC) continuam sem leitura/escrita em
;  disco (a persistencia aqui e' so no banco SQLite do projeto).
;
;  FASE 6 (esta sessao) implementa o menu AJUSTE (F4): SCROLL (1px, so
;  "video"/PatternBit, a parte que sai e' perdida)/SCROLL 8x8 (video +
;  atributos juntos, area vazia preenchida com INK/PAPER atuais) e ROTACAO
;  (1px, so video)/ROTACAO 8x8 (video + atributos), ambas com wraparound (a
;  parte que sai reentra pelo lado oposto) em vez de perder dados. "video"
;  vs "atributos" segue a MESMA distincao ja usada por INVERTE VIDEO/INVERTE
;  ATRIBUTOS (fase 4). UI: 2 alternadores independentes (passo 1px/8px;
;  modo SCROLL/ROTACAO, icone de seta-com-parede reaproveitado de
;  CharEd_CreateNavIcon(WithBar=#True) pro modo SCROLL e icone de seta
;  circular pro ROTACAO) + 4 setas de direcao (acao unica - aplicam a
;  combinacao passo+modo atual na hora do clique, sem "Registrar"; icones
;  reaproveitam CharEd_DrawFilledHTri/VTri do editor de alfabetos em vez de
;  desenhar triangulo do zero). Todas as 4 operacoes usam uma copia
;  temporaria do framebuffer (Dim Tmp) em vez de deslocar in-place, mais
;  simples de raciocinar numa tela pequena (256x192).
;
;  FASE 7 (esta sessao) implementa o menu MISCELANEA (F5): ZOOM, SHAPE
;  (carimbo), CORTE e GRID.
;
;  - GRID: no original altera de verdade a cor de PAPER de toda a tela pra
;    desenhar uma malha (destrutivo, limitacao de hardware); aqui e' um
;    OVERLAY nao destrutivo (linhas finas desenhadas por cima do canvas a
;    cada redesenho, GraphosScr_DrawGridOverlay/RedrawCanvasFull) - mais
;    seguro e no espirito de "mostrar/esconder grade" de qualquer editor
;    grafico moderno. Precisou de um redesenho "completo" novo
;    (GraphosScr_RedrawCanvasFull) que sempre substitui as antigas chamadas
;    diretas a Scr2Ed_RedrawCanvas (31 pontos no arquivo) - senao o overlay
;    ficaria defasado a cada operacao de desenho.
;  - CORTE: mark retangular (2 cliques, sem alinhamento de 8px - so mexe em
;    PatternBit, nunca em RowFG/RowBG, fiel ao manual: "manipula e modifica
;    os pixels") + Inverter (I)/Espelhar horizontal (E)/Espelhar vertical
;    (R), aplicados direto no recorte marcado. Sem o "TECLAS DO CURSOR
;    deslocam o corte" do original (mover uma selecao flutuante arrastando)
;    - fora de escopo, mesma linha de simplificacao ja aplicada em
;    TEXTO/SHAPE (clique fixa, sem arrastar-e-confirmar).
;  - SHAPE (carimbo): usa o shape CARREGADO NA BARRA DE PROJETO (fase 5) -
;    nenhuma UI de selecao nova. MASCARA cola pixels+cores (substitui tudo);
;    AND/OR/XOR sao logica so no BIT do pixel (fiel ao manual: "embora os
;    atributos nao sejam alterados") - onde um pixel novo acende nessas 3,
;    usa a cor que a celula de destino ja tinha. Posicionamento no mesmo
;    padrao "Posicionar -> previa segue o mouse -> clique fixa" de TEXTO.
;  - ZOOM: reinterpretacao simplificada (o original tinha 3 quadros TELA/
;    INK/PAPER e modos A/S/R por tecla) - marca uma regiao (2 cliques) e
;    abre uma JANELA A PARTE (GraphosScr_OpenZoomWindow, mesmo padrao modal
;    de sub-janela ja usado por SpriteEditorGui/CharsetEditorGui) mostrando
;    so' aquela regiao bem ampliada, com Lapis/Borracha (INK/PAPER herdados
;    da janela principal) - escreve DIRETO nos MESMOS arrays PatternBit/
;    RowFG/RowBG da janela principal (arrays por referencia no PureBasic),
;    entao fechar o Zoom so precisa de 1 redesenho pra refletir as edicoes.
;
;  Deliberadamente FORA desta fase: escolha de TIPO de shape do CRIA SHAPES
;  original (secao 3.8 - so o TIPO 1 permite escolher mascara/AND/OR/XOR;
;  aqui todo shape aceita os 4 modos, simplificacao); os formatos de arquivo
;  nativos DISPLAY (.SCR)/LAYOUT (.LAY)/COMPAC (.VTC+.ATC) em disco (a
;  persistencia de Tela/Layout/Shape continua so no banco SQLite do
;  projeto, ver FASE 5).
; ------------------------------------------------------------
;

Enumeration GraphosScrTool
  #GraphosScrTool_Traco
  #GraphosScrTool_Bloco
  #GraphosScrTool_Linha
  #GraphosScrTool_Retangulo
  #GraphosScrTool_Raio
  #GraphosScrTool_Circulo
  #GraphosScrTool_Pintura
  #GraphosScrTool_Spray
  #GraphosScrTool_Fill
EndEnumeration

; Alternador INS/DEL do Graphos III original (teclas INSERT/DELETE) -
; controla se TRACO/BLOCO/SPRAY setam (Lapis, com INK) ou resetam
; (Borracha, com PAPER) os pixels alterados.
Enumeration GraphosPenMode
  #GraphosPenMode_Insert
  #GraphosPenMode_Delete
EndEnumeration

; As 6 variacoes do menu TEXTO (F2) do Graphos III original, na mesma ordem
; do manual (graphos/graphos.txt, secao 3.2.2).
Enumeration GraphosTextStyle
  #GraphosTextStyle_Normal
  #GraphosTextStyle_Italic
  #GraphosTextStyle_Bold
  #GraphosTextStyle_Duplo
  #GraphosTextStyle_DuploBold
  #GraphosTextStyle_Largo
EndEnumeration

; Tamanho valido do cursor da ferramenta BLOCO (campos de texto livre, sem
; SpinGadget nesta base de codigo - validado na hora do uso).
Procedure.i GraphosScr_ClampBlockSize(V.i)
  If V < 1
    ProcedureReturn 1
  ElseIf V > 64
    ProcedureReturn 64
  Else
    ProcedureReturn V
  EndIf
EndProcedure

; Ferramentas que respeitam o alternador Lapis/Borracha - as demais
; (LINHA/RETANGULO/RAIO/CIRCULO/FILL sempre com INK, PINTURA sempre com
; PAPER) ignoram PenMode.
Procedure.b GraphosScr_ToolUsesPenMode(ToolMode.i)
  ProcedureReturn Bool(ToolMode = #GraphosScrTool_Traco Or ToolMode = #GraphosScrTool_Bloco Or ToolMode = #GraphosScrTool_Spray)
EndProcedure

; BLOCO do Graphos III original: TRACO com "altura e largura de cursor"
; ajustaveis - aqui um retangulo BlockW x BlockH de pixels centrado no ponto
; do cursor, cada pixel setado/resetado exatamente como TRACO (mesmo
; PenMode). Scr2_SetPixel ja faz o clip silencioso fora da tela.
Procedure GraphosScr_ApplyBlock(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), CenterX.i, CenterY.i, BlockW.i, BlockH.i, PenMode.i, InkColor.i, PaperColor.i)
  Protected StartX = CenterX - (BlockW / 2)
  Protected StartY = CenterY - (BlockH / 2)
  Protected X, Y
  For Y = StartY To StartY + BlockH - 1
    For X = StartX To StartX + BlockW - 1
      If PenMode = #GraphosPenMode_Insert
        Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), X, Y, InkColor, #True)
      Else
        Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), X, Y, PaperColor, #False)
      EndIf
    Next
  Next
EndProcedure

; PINTURA do Graphos III original: "altera a cor de fundo dos pontos
; indicados pelo cursor... sem alterar a cor de frente do desenho" - so
; grava RowBG da faixa de 8 pixels sob o cursor, nunca mexe em PatternBit
; nem em RowFG (diferente de Scr2_SetPixel, que sempre acende/apaga o bit).
Procedure GraphosScr_PaintBackground(Array RowBG.a(2), X.i, Y.i, PaperColor.i)
  If X < 0 Or X >= #Scr2_Width Or Y < 0 Or Y >= #Scr2_Height
    ProcedureReturn
  EndIf
  RowBG(Y, X / 8) = PaperColor & $F
EndProcedure

; SPRAY do Graphos III original: "imita o resultado de uma pintura com
; spray, padrao aleatorio, tende a formar um borrao compacto caso nao haja
; deslocamento do cursor" - a cada chamada (clique ou passo de arraste),
; borrifa alguns pixels em posicoes aleatorias dentro de um raio quadrado
; ao redor do cursor, respeitando o mesmo PenMode de TRACO/BLOCO.
#GraphosScr_SprayRadius = 5
#GraphosScr_SprayDabs   = 6

Procedure GraphosScr_ApplySpray(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), CenterX.i, CenterY.i, PenMode.i, InkColor.i, PaperColor.i)
  Protected i, PX, PY
  For i = 1 To #GraphosScr_SprayDabs
    PX = CenterX + Random(#GraphosScr_SprayRadius * 2) - #GraphosScr_SprayRadius
    PY = CenterY + Random(#GraphosScr_SprayRadius * 2) - #GraphosScr_SprayRadius
    If PenMode = #GraphosPenMode_Insert
      Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), PX, PY, InkColor, #True)
    Else
      Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), PX, PY, PaperColor, #False)
    EndIf
  Next
EndProcedure

; TRACO/BLOCO/PINTURA/SPRAY sao "ferramentas de arraste" - aplicadas tanto
; no clique quanto, continuamente, em cada novo pixel visitado durante o
; arraste (mesmo padrao de SpriteEd_ApplyTool do editor de sprites).
; LINHA/RETANGULO/RAIO/CIRCULO/FILL sao "de clique unico" e ficam fora
; daqui, tratadas direto no laco de eventos (precisam de ancora/previa ou
; disparam uma unica vez).
Procedure GraphosScr_ApplyDragTool(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), X.i, Y.i, ToolMode.i, PenMode.i, InkColor.i, PaperColor.i, BlockW.i, BlockH.i)
  Select ToolMode
    Case #GraphosScrTool_Traco
      If PenMode = #GraphosPenMode_Insert
        Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), X, Y, InkColor, #True)
      Else
        Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), X, Y, PaperColor, #False)
      EndIf

    Case #GraphosScrTool_Bloco
      GraphosScr_ApplyBlock(PatternBit(), RowFG(), RowBG(), X, Y, BlockW, BlockH, PenMode, InkColor, PaperColor)

    Case #GraphosScrTool_Pintura
      GraphosScr_PaintBackground(RowBG(), X, Y, PaperColor)

    Case #GraphosScrTool_Spray
      GraphosScr_ApplySpray(PatternBit(), RowFG(), RowBG(), X, Y, PenMode, InkColor, PaperColor)

  EndSelect
EndProcedure

; LIMPA TELA (menu TELA do Graphos III original): apaga todos os pixels e
; grava INK/PAPER atuais em toda faixa - diferente de Scr2_ClearFramebuffer
; (que sempre usa os defaults #Scr2_DefaultFG/BG), aqui usa as cores que o
; usuario tem selecionadas no momento, igual ao "ATRIBUTOS" do original.
Procedure GraphosScr_ClearWithColors(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), InkColor.i, PaperColor.i)
  Protected Y, X, Cx
  For Y = 0 To #Scr2_Height - 1
    For X = 0 To #Scr2_Width - 1
      PatternBit(Y, X) = 0
    Next
    For Cx = 0 To #Scr2_Cols - 1
      RowFG(Y, Cx) = InkColor
      RowBG(Y, Cx) = PaperColor
    Next
  Next
EndProcedure

; --- Menu TELA (F3, fase 4) - operacoes de tela inteira -------------------

; INVERTE VIDEO: inverte o estado de cada pixel (aceso vira apagado e
; vice-versa), sem tocar em nenhuma cor INK/PAPER de faixa.
Procedure GraphosScr_InvertVideo(Array PatternBit.a(2))
  Protected X, Y
  For Y = 0 To #Scr2_Height - 1
    For X = 0 To #Scr2_Width - 1
      PatternBit(Y, X) = 1 - PatternBit(Y, X)
    Next
  Next
EndProcedure

; INVERTE ATRIBUTOS: troca INK e PAPER de toda faixa, sem alterar nenhum
; pixel.
Procedure GraphosScr_InvertAttrs(Array RowFG.a(2), Array RowBG.a(2))
  Protected Y, Cx, Tmp
  For Y = 0 To #Scr2_Height - 1
    For Cx = 0 To #Scr2_Cols - 1
      Tmp = RowFG(Y, Cx)
      RowFG(Y, Cx) = RowBG(Y, Cx)
      RowBG(Y, Cx) = Tmp
    Next
  Next
EndProcedure

; RETIRA VIDEO/REPOE VIDEO: RETIRA guarda os pixels atuais num backup
; dedicado e reseta todos (a tela passa a mostrar so a cor de PAPER de cada
; faixa); REPOE devolve o que foi guardado. Nunca mexe em RowFG/RowBG (esse
; backup e' separado, ver RETIRA/REPOE ATRIBUTOS abaixo).
Procedure GraphosScr_RetiraVideo(Array PatternBit.a(2), Array BackupPattern.a(2))
  Protected X, Y
  For Y = 0 To #Scr2_Height - 1
    For X = 0 To #Scr2_Width - 1
      BackupPattern(Y, X) = PatternBit(Y, X)
      PatternBit(Y, X) = 0
    Next
  Next
EndProcedure

Procedure GraphosScr_RepoeVideo(Array PatternBit.a(2), Array BackupPattern.a(2))
  Protected X, Y
  For Y = 0 To #Scr2_Height - 1
    For X = 0 To #Scr2_Width - 1
      PatternBit(Y, X) = BackupPattern(Y, X)
    Next
  Next
EndProcedure

; RETIRA ATRIBUTOS/REPOE ATRIBUTOS: RETIRA guarda INK/PAPER de toda faixa
; num backup dedicado e grava as cores default (branco/preto, mesmo par de
; Scr2_ClearFramebuffer) em toda a tela - "deixando a vista somente os
; pixels setados", como no manual original; REPOE devolve as cores
; guardadas. Nunca mexe em PatternBit.
Procedure GraphosScr_RetiraAtributos(Array RowFG.a(2), Array RowBG.a(2), Array BackupFG.a(2), Array BackupBG.a(2))
  Protected Y, Cx
  For Y = 0 To #Scr2_Height - 1
    For Cx = 0 To #Scr2_Cols - 1
      BackupFG(Y, Cx) = RowFG(Y, Cx)
      BackupBG(Y, Cx) = RowBG(Y, Cx)
      RowFG(Y, Cx) = #Scr2_DefaultFG
      RowBG(Y, Cx) = #Scr2_DefaultBG
    Next
  Next
EndProcedure

Procedure GraphosScr_RepoeAtributos(Array RowFG.a(2), Array RowBG.a(2), Array BackupFG.a(2), Array BackupBG.a(2))
  Protected Y, Cx
  For Y = 0 To #Scr2_Height - 1
    For Cx = 0 To #Scr2_Cols - 1
      RowFG(Y, Cx) = BackupFG(Y, Cx)
      RowBG(Y, Cx) = BackupBG(Y, Cx)
    Next
  Next
EndProcedure

; SALVA TELA/Restaurar: backup e restauracao da tela INTEIRA (pixels + INK +
; PAPER) - equivalente ao "buffer" do Graphos III original (no original,
; HOME/CLS sempre recupera a ultima tela salva, automaticamente, no inicio
; de QUALQUER operacao). Aqui e' escopado so a este par de botoes (backup
; explicito sob pedido do usuario) em vez de um undo geral pra toda a
; janela - fora de escopo desta fase.
Procedure GraphosScr_SalvaTela(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), Array BackupPattern.a(2), Array BackupFG.a(2), Array BackupBG.a(2))
  Protected X, Y, Cx
  For Y = 0 To #Scr2_Height - 1
    For X = 0 To #Scr2_Width - 1
      BackupPattern(Y, X) = PatternBit(Y, X)
    Next
    For Cx = 0 To #Scr2_Cols - 1
      BackupFG(Y, Cx) = RowFG(Y, Cx)
      BackupBG(Y, Cx) = RowBG(Y, Cx)
    Next
  Next
EndProcedure

Procedure GraphosScr_RestauraTela(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), Array BackupPattern.a(2), Array BackupFG.a(2), Array BackupBG.a(2))
  Protected X, Y, Cx
  For Y = 0 To #Scr2_Height - 1
    For X = 0 To #Scr2_Width - 1
      PatternBit(Y, X) = BackupPattern(Y, X)
    Next
    For Cx = 0 To #Scr2_Cols - 1
      RowFG(Y, Cx) = BackupFG(Y, Cx)
      RowBG(Y, Cx) = BackupBG(Y, Cx)
    Next
  Next
EndProcedure

; --- Menu AJUSTE (F4, fase 6) - SCROLL/ROTACAO, inteiro (1px) e 8x8 ------
;
; Direcao: 0=cima, 1=baixo, 2=esquerda, 3=direita (mesma convencao das
; setas de teclado do original). SCROLL perde a parte que sai da tela;
; ROTACAO faz a parte que sai reentrar pelo lado oposto (wraparound).
; "video" (so PatternBit) e "atributos" (RowFG/RowBG) seguem a MESMA
; distincao ja usada por INVERTE VIDEO/INVERTE ATRIBUTOS (modulo 14b): SCROLL/
; ROTACAO comuns (1px) mexem so no video; as variantes 8x8 mexem nos dois.
;
; Todas usam uma copia temporaria (Dim Tmp) em vez de deslocar in-place -
; mais simples de raciocinar (sem se preocupar com ordem de iteracao
; sobrescrevendo dados ainda nao lidos) e barato o bastante numa tela
; 256x192.
Procedure GraphosScr_ScrollVideo1px(Array PatternBit.a(2), Direction.i)
  Dim Tmp.a(#Scr2_Height - 1, #Scr2_Width - 1)
  Protected X, Y
  For Y = 0 To #Scr2_Height - 1
    For X = 0 To #Scr2_Width - 1
      Tmp(Y, X) = PatternBit(Y, X)
    Next
  Next
  For Y = 0 To #Scr2_Height - 1
    For X = 0 To #Scr2_Width - 1
      Select Direction
        Case 0
          If Y < #Scr2_Height - 1 : PatternBit(Y, X) = Tmp(Y + 1, X) : Else : PatternBit(Y, X) = 0 : EndIf
        Case 1
          If Y > 0 : PatternBit(Y, X) = Tmp(Y - 1, X) : Else : PatternBit(Y, X) = 0 : EndIf
        Case 2
          If X < #Scr2_Width - 1 : PatternBit(Y, X) = Tmp(Y, X + 1) : Else : PatternBit(Y, X) = 0 : EndIf
        Case 3
          If X > 0 : PatternBit(Y, X) = Tmp(Y, X - 1) : Else : PatternBit(Y, X) = 0 : EndIf
      EndSelect
    Next
  Next
EndProcedure

Procedure GraphosScr_RotateVideo1px(Array PatternBit.a(2), Direction.i)
  Dim Tmp.a(#Scr2_Height - 1, #Scr2_Width - 1)
  Protected X, Y
  For Y = 0 To #Scr2_Height - 1
    For X = 0 To #Scr2_Width - 1
      Tmp(Y, X) = PatternBit(Y, X)
    Next
  Next
  For Y = 0 To #Scr2_Height - 1
    For X = 0 To #Scr2_Width - 1
      Select Direction
        Case 0 : PatternBit(Y, X) = Tmp((Y + 1) % #Scr2_Height, X)
        Case 1 : PatternBit(Y, X) = Tmp((Y - 1 + #Scr2_Height) % #Scr2_Height, X)
        Case 2 : PatternBit(Y, X) = Tmp(Y, (X + 1) % #Scr2_Width)
        Case 3 : PatternBit(Y, X) = Tmp(Y, (X - 1 + #Scr2_Width) % #Scr2_Width)
      EndSelect
    Next
  Next
EndProcedure

; 8x8: desloca 8 SCANLINES (cima/baixo) ou 8 colunas de pixel = 1 celula de
; cor inteira (esquerda/direita) - a cor no MSX real ja e' por linha de
; varredura (nao por bloco 8x8), entao um deslocamento vertical nao precisa
; de nenhum alinhamento especial de celula; so o horizontal precisa (Cx =
; X/8), daí deslocar RowFG/RowBG por 1 celula em vez de 8 "unidades".
Procedure GraphosScr_ScrollVideo8px(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), Direction.i, InkColor.i, PaperColor.i)
  Dim TmpP.a(#Scr2_Height - 1, #Scr2_Width - 1)
  Dim TmpFG.a(#Scr2_Height - 1, #Scr2_Cols - 1)
  Dim TmpBG.a(#Scr2_Height - 1, #Scr2_Cols - 1)
  Protected X, Y, Cx
  For Y = 0 To #Scr2_Height - 1
    For X = 0 To #Scr2_Width - 1
      TmpP(Y, X) = PatternBit(Y, X)
    Next
    For Cx = 0 To #Scr2_Cols - 1
      TmpFG(Y, Cx) = RowFG(Y, Cx)
      TmpBG(Y, Cx) = RowBG(Y, Cx)
    Next
  Next
  Select Direction
    Case 0 ; cima
      For Y = 0 To #Scr2_Height - 1
        For X = 0 To #Scr2_Width - 1
          If Y + 8 < #Scr2_Height : PatternBit(Y, X) = TmpP(Y + 8, X) : Else : PatternBit(Y, X) = 0 : EndIf
        Next
        For Cx = 0 To #Scr2_Cols - 1
          If Y + 8 < #Scr2_Height
            RowFG(Y, Cx) = TmpFG(Y + 8, Cx) : RowBG(Y, Cx) = TmpBG(Y + 8, Cx)
          Else
            RowFG(Y, Cx) = InkColor : RowBG(Y, Cx) = PaperColor
          EndIf
        Next
      Next
    Case 1 ; baixo
      For Y = 0 To #Scr2_Height - 1
        For X = 0 To #Scr2_Width - 1
          If Y - 8 >= 0 : PatternBit(Y, X) = TmpP(Y - 8, X) : Else : PatternBit(Y, X) = 0 : EndIf
        Next
        For Cx = 0 To #Scr2_Cols - 1
          If Y - 8 >= 0
            RowFG(Y, Cx) = TmpFG(Y - 8, Cx) : RowBG(Y, Cx) = TmpBG(Y - 8, Cx)
          Else
            RowFG(Y, Cx) = InkColor : RowBG(Y, Cx) = PaperColor
          EndIf
        Next
      Next
    Case 2 ; esquerda
      For Y = 0 To #Scr2_Height - 1
        For X = 0 To #Scr2_Width - 1
          If X + 8 < #Scr2_Width : PatternBit(Y, X) = TmpP(Y, X + 8) : Else : PatternBit(Y, X) = 0 : EndIf
        Next
        For Cx = 0 To #Scr2_Cols - 1
          If Cx + 1 < #Scr2_Cols
            RowFG(Y, Cx) = TmpFG(Y, Cx + 1) : RowBG(Y, Cx) = TmpBG(Y, Cx + 1)
          Else
            RowFG(Y, Cx) = InkColor : RowBG(Y, Cx) = PaperColor
          EndIf
        Next
      Next
    Case 3 ; direita
      For Y = 0 To #Scr2_Height - 1
        For X = 0 To #Scr2_Width - 1
          If X - 8 >= 0 : PatternBit(Y, X) = TmpP(Y, X - 8) : Else : PatternBit(Y, X) = 0 : EndIf
        Next
        For Cx = 0 To #Scr2_Cols - 1
          If Cx - 1 >= 0
            RowFG(Y, Cx) = TmpFG(Y, Cx - 1) : RowBG(Y, Cx) = TmpBG(Y, Cx - 1)
          Else
            RowFG(Y, Cx) = InkColor : RowBG(Y, Cx) = PaperColor
          EndIf
        Next
      Next
  EndSelect
EndProcedure

Procedure GraphosScr_RotateVideo8px(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), Direction.i)
  Dim TmpP.a(#Scr2_Height - 1, #Scr2_Width - 1)
  Dim TmpFG.a(#Scr2_Height - 1, #Scr2_Cols - 1)
  Dim TmpBG.a(#Scr2_Height - 1, #Scr2_Cols - 1)
  Protected X, Y, Cx
  For Y = 0 To #Scr2_Height - 1
    For X = 0 To #Scr2_Width - 1
      TmpP(Y, X) = PatternBit(Y, X)
    Next
    For Cx = 0 To #Scr2_Cols - 1
      TmpFG(Y, Cx) = RowFG(Y, Cx)
      TmpBG(Y, Cx) = RowBG(Y, Cx)
    Next
  Next
  Select Direction
    Case 0 ; cima
      For Y = 0 To #Scr2_Height - 1
        For X = 0 To #Scr2_Width - 1
          PatternBit(Y, X) = TmpP((Y + 8) % #Scr2_Height, X)
        Next
        For Cx = 0 To #Scr2_Cols - 1
          RowFG(Y, Cx) = TmpFG((Y + 8) % #Scr2_Height, Cx) : RowBG(Y, Cx) = TmpBG((Y + 8) % #Scr2_Height, Cx)
        Next
      Next
    Case 1 ; baixo
      For Y = 0 To #Scr2_Height - 1
        For X = 0 To #Scr2_Width - 1
          PatternBit(Y, X) = TmpP((Y - 8 + #Scr2_Height) % #Scr2_Height, X)
        Next
        For Cx = 0 To #Scr2_Cols - 1
          RowFG(Y, Cx) = TmpFG((Y - 8 + #Scr2_Height) % #Scr2_Height, Cx) : RowBG(Y, Cx) = TmpBG((Y - 8 + #Scr2_Height) % #Scr2_Height, Cx)
        Next
      Next
    Case 2 ; esquerda
      For Y = 0 To #Scr2_Height - 1
        For X = 0 To #Scr2_Width - 1
          PatternBit(Y, X) = TmpP(Y, (X + 8) % #Scr2_Width)
        Next
        For Cx = 0 To #Scr2_Cols - 1
          RowFG(Y, Cx) = TmpFG(Y, (Cx + 1) % #Scr2_Cols) : RowBG(Y, Cx) = TmpBG(Y, (Cx + 1) % #Scr2_Cols)
        Next
      Next
    Case 3 ; direita
      For Y = 0 To #Scr2_Height - 1
        For X = 0 To #Scr2_Width - 1
          PatternBit(Y, X) = TmpP(Y, (X - 8 + #Scr2_Width) % #Scr2_Width)
        Next
        For Cx = 0 To #Scr2_Cols - 1
          RowFG(Y, Cx) = TmpFG(Y, (Cx - 1 + #Scr2_Cols) % #Scr2_Cols) : RowBG(Y, Cx) = TmpBG(Y, (Cx - 1 + #Scr2_Cols) % #Scr2_Cols)
        Next
      Next
  EndSelect
EndProcedure

; Mensagem de status legivel pras 16 combinacoes passo x modo x direcao.
Procedure.s GraphosScr_AjusteStatusText(Step8.b, Rotacao.b, Direction.i)
  Protected Txt.s
  If Rotacao
    Txt = "ROTACAO"
  Else
    Txt = "SCROLL"
  EndIf
  If Step8
    Txt + " 8x8"
  Else
    Txt + " 1px"
  EndIf
  Select Direction
    Case 0 : Txt + " para cima"
    Case 1 : Txt + " para baixo"
    Case 2 : Txt + " para esquerda"
    Case 3 : Txt + " para direita"
  EndSelect
  ProcedureReturn Txt
EndProcedure

; --- TEXTO (fase 3): imprime uma string usando um alfabeto do projeto
; (ProjectDB::FetchAlphabet, formato CharsetBytes(255,7) do modulo 4) -----
;
; NORMAL/ITALIC/BOLD sao transformacao de FORMA do glifo (reaproveita
; CharEd_UnpackChar/ItalicEditGrid/BoldEditGrid de CharsetEditorGui.pbi, sem
; duplicar a formula de bits) - continuam 8x8; DUPLO/LARGO/DUPLO BOLD sao
; duplicacao geometrica de linha/coluna no framebuffer, sem mexer na forma.
; ScaleX/ScaleY resolvem as 6 combinacoes com um so par de loops.
Procedure GraphosScr_TextScaleX(Style.i)
  ProcedureReturn Bool(Style = #GraphosTextStyle_Largo Or Style = #GraphosTextStyle_DuploBold) + 1
EndProcedure

Procedure GraphosScr_TextScaleY(Style.i)
  ProcedureReturn Bool(Style = #GraphosTextStyle_Duplo Or Style = #GraphosTextStyle_DuploBold) + 1
EndProcedure

; StartX/StartY = pixel bruto do canto superior esquerdo do 1o caractere,
; igual a Scr2Ed_BlitText - cada caractere seguinte desloca (8*ScaleX)px.
Procedure GraphosScr_BlitTextStyled(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), Array CharsetBytes.a(2), TextStr.s, StartX.i, StartY.i, InkColor.i, PaperColor.i, Style.i)
  Protected ScaleX = GraphosScr_TextScaleX(Style)
  Protected ScaleY = GraphosScr_TextScaleY(Style)
  Protected i, Code, Row, Col, DupRow, DupCol, BaseX, BaseY, PixelOn.b
  Dim Grid.a(7, 7)
  BaseX = StartX
  For i = 1 To Len(TextStr)
    Code = Asc(Mid(TextStr, i, 1))
    If Code >= 0 And Code <= 255
      CharEd_UnpackChar(CharsetBytes(), Code, Grid())
      Select Style
        Case #GraphosTextStyle_Italic
          CharEd_ItalicEditGrid(Grid())
        Case #GraphosTextStyle_Bold
          CharEd_BoldEditGrid(Grid())
      EndSelect
      BaseY = StartY
      For Row = 0 To 7
        For Col = 0 To 7
          PixelOn = Bool(Grid(Row, Col))
          For DupRow = 0 To ScaleY - 1
            For DupCol = 0 To ScaleX - 1
              If PixelOn
                Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), BaseX + Col * ScaleX + DupCol, BaseY + Row * ScaleY + DupRow, InkColor, #True)
              Else
                Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), BaseX + Col * ScaleX + DupCol, BaseY + Row * ScaleY + DupRow, PaperColor, #False)
              EndIf
            Next
          Next
        Next
      Next
    EndIf
    BaseX + 8 * ScaleX
  Next
EndProcedure

; "Quadro elastico" da ferramenta TEXTO - mesmo espirito de
; Scr2Ed_DrawTextPreview (editor "Draw Screen 2..."), mas desenhando por
; cima do canvas ja redesenhado (nao toca no framebuffer real) e suportando
; as 6 variacoes via GraphosScr_TextScaleX/Y, igual ao blit de verdade.
Procedure GraphosScr_DrawTextPreview(Canvas, Array CharsetBytes.a(2), TextStr.s, BaseX.i, BaseY.i, InkColor.l, PaperColor.l, Style.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected ScaleX = GraphosScr_TextScaleX(Style)
  Protected ScaleY = GraphosScr_TextScaleY(Style)
  Protected i, Code, Row, Col, CX, CY, CurX
  Dim Grid.a(7, 7)
  CurX = BaseX
  For i = 1 To Len(TextStr)
    Code = Asc(Mid(TextStr, i, 1))
    If Code >= 0 And Code <= 255
      CharEd_UnpackChar(CharsetBytes(), Code, Grid())
      Select Style
        Case #GraphosTextStyle_Italic
          CharEd_ItalicEditGrid(Grid())
        Case #GraphosTextStyle_Bold
          CharEd_BoldEditGrid(Grid())
      EndSelect
      For Row = 0 To 7
        For Col = 0 To 7
          CX = (CurX + Col * ScaleX) * #Scr2Ed_Zoom
          CY = (BaseY + Row * ScaleY) * #Scr2Ed_Zoom
          If Grid(Row, Col)
            Box(CX, CY, ScaleX * #Scr2Ed_Zoom, ScaleY * #Scr2Ed_Zoom, InkColor)
          Else
            Box(CX, CY, ScaleX * #Scr2Ed_Zoom, ScaleY * #Scr2Ed_Zoom, PaperColor)
          EndIf
        Next
      Next
    EndIf
    CurX + 8 * ScaleX
  Next
  Protected TextW = (CurX - BaseX) * #Scr2Ed_Zoom, TextH = 8 * ScaleY * #Scr2Ed_Zoom
  DrawingMode(#PB_2DDrawing_Outlined)
  Box(BaseX * #Scr2Ed_Zoom, BaseY * #Scr2Ed_Zoom, TextW, TextH, Scr2Ed_AnchorColor)
  DrawingMode(#PB_2DDrawing_Default)
  StopDrawing()
EndProcedure

; --- Icones novos (fase 2) - mesmo estilo monocromatico/24bpp dos icones ja
; usados pelo editor de sprites (SpriteEditorGui.pbi), so que especificos
; de operacoes que nao existem em nenhum outro editor desta IDE. BLOCO,
; LINHA, RETANGULO, CIRCULO e FILL reaproveitam icones ja existentes do
; editor de sprites (Brush/LineTool/RectOutline/EllipseOutline/Fill) -
; encaixam conceitualmente sem precisar de desenho novo.

; Icone do botao "Traco": um unico pixel ampliado dentro de uma moldura -
; simboliza a edicao pixel a pixel (em oposicao ao BLOCO, que mexe em varios
; de uma vez).
Procedure GraphosScr_CreatePixelIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(2, 2, Size - 4, Size - 4, RGB(170, 170, 170))
    DrawingMode(#PB_2DDrawing_Default)
    Box(Size / 2 - 3, Size / 2 - 3, 6, 6, RGB(20, 20, 20))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Raio": varios segmentos de reta partindo de uma unica
; origem fixa (bolinha azul), lembrando o leque de linhas que a operacao RAIO
; traca a partir do ponto marcado como referencia.
Procedure GraphosScr_CreateRayIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected OX = 3, OY = Size - 4
    LineXY(OX, OY, Size - 4, 3, RGB(20, 20, 20))
    LineXY(OX, OY, Size - 3, Size / 2, RGB(20, 20, 20))
    LineXY(OX, OY, Size / 2, 3, RGB(20, 20, 20))
    Circle(OX, OY, 3, RGB(30, 110, 220))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Pintura": quadrado dividido - metade de cima (o "desenho"/
; tinta) fica intocada, metade de baixo (o "fundo") aparece recolorida de
; laranja, comunicando que so o FUNDO muda.
Procedure GraphosScr_CreatePaintIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    LineXY(3, 4, Size - 4, 4, RGB(20, 20, 20))
    LineXY(3, 8, Size - 7, 8, RGB(20, 20, 20))
    Box(2, Size / 2, Size - 4, Size / 2 - 2, RGB(235, 150, 40))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(2, Size / 2, Size - 4, Size / 2 - 2, RGB(150, 90, 20))
    DrawingMode(#PB_2DDrawing_Default)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Spray": nuvem de pontinhos, lembrando o borrifo aleatorio
; que a operacao produz (posicoes fixas no icone - so o desenho de dentro da
; ferramenta e' aleatorio de verdade).
Procedure GraphosScr_CreateSprayIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Circle(4, Size - 4, 1, RGB(30, 130, 200))
    Circle(8, Size - 7, 1, RGB(30, 130, 200))
    Circle(6, Size - 11, 1, RGB(30, 130, 200))
    Circle(11, Size - 3, 1, RGB(30, 130, 200))
    Circle(13, Size - 9, 1, RGB(30, 130, 200))
    Circle(16, Size - 5, 1, RGB(30, 130, 200))
    Circle(9, Size - 14, 1, RGB(30, 130, 200))
    Circle(17, Size - 12, 1, RGB(30, 130, 200))
    Circle(2, Size - 9, 1, RGB(30, 130, 200))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Salvar tela": disquete classico - simboliza o backup da
; tela inteira no buffer (SALVA TELA do menu TELA).
Procedure GraphosScr_CreateSaveIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Box(2, 2, Size - 4, Size - 4, RGB(60, 90, 160))
    Box(Size / 2 - 4, 2, 8, 6, RGB(220, 220, 230))
    Box(5, Size - 9, Size - 10, 7, RGB(230, 230, 235))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(2, 2, Size - 4, Size - 4, RGB(20, 30, 60))
    DrawingMode(#PB_2DDrawing_Default)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Restaurar tela": seta circular (undo classico) -
; simboliza trazer de volta o que "Salvar tela" guardou no buffer.
Procedure GraphosScr_CreateUndoIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Circle(Size / 2, Size / 2 + 1, Size / 2 - 4, RGB(40, 130, 70))
    DrawingMode(#PB_2DDrawing_Default)
    LineXY(4, Size / 2 - 3, 4, 4, RGB(40, 130, 70))
    LineXY(4, 4, Size / 2 - 2, 4, RGB(40, 130, 70))
    LineXY(3, Size / 2 - 5, 8, Size / 2, RGB(40, 130, 70))
    LineXY(3, Size / 2 - 5, 9, Size / 2 - 8, RGB(40, 130, 70))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Inverte video": quadrado dividido - metade preta com
; ponto branco, metade branca com ponto preto - simboliza a inversao do
; estado de cada pixel (INVERTE VIDEO), sem mexer em cores.
Procedure GraphosScr_CreateInvertVideoIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Box(2, 2, (Size - 4) / 2, Size - 4, RGB(20, 20, 20))
    Box(2 + (Size - 4) / 2, 2, (Size - 4) / 2, Size - 4, RGB(235, 235, 235))
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(2, 2, Size - 4, Size - 4, RGB(120, 120, 120))
    DrawingMode(#PB_2DDrawing_Default)
    Circle(2 + (Size - 4) / 4, Size / 2, 3, RGB(235, 235, 235))
    Circle(2 + (Size - 4) * 3 / 4, Size / 2, 3, RGB(20, 20, 20))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone do botao "Inverte atributos": dois retalhos de cor (laranja/azul,
; papel de INK/PAPER) com setas opostas entre eles - simboliza a troca de
; INK/PAPER de toda a tela (INVERTE ATRIBUTOS), sem mexer em pixels.
Procedure GraphosScr_CreateInvertAttrsIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Box(2, 2, Size / 2 - 3, Size - 4, RGB(235, 150, 40))
    Box(Size / 2 + 1, 2, Size / 2 - 3, Size - 4, RGB(60, 110, 200))
    LineXY(Size / 2 - 4, 6, Size / 2 + 4, 6, RGB(20, 20, 20))
    LineXY(Size / 2 + 1, 3, Size / 2 + 4, 6, RGB(20, 20, 20))
    LineXY(Size / 2 + 1, 9, Size / 2 + 4, 6, RGB(20, 20, 20))
    LineXY(Size / 2 - 4, Size - 7, Size / 2 + 4, Size - 7, RGB(20, 20, 20))
    LineXY(Size / 2 - 1, Size - 10, Size / 2 - 4, Size - 7, RGB(20, 20, 20))
    LineXY(Size / 2 - 1, Size - 4, Size / 2 - 4, Size - 7, RGB(20, 20, 20))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone parametrizado do par RETIRA/REPOE (video e atributos, 4 botoes com
; um so gerador): quadrado xadrez preto/branco pra VIDEO (so pixels) ou
; laranja solido pra ATRIBUTOS (so cor), com uma seta no canto superior
; direito - pra cima (RETIRA, remove) ou pra baixo (REPOE, devolve).
Procedure GraphosScr_CreateRetiraRepoeIcon(Size.i, IsAttrs.b, IsRepoe.b)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    If IsAttrs
      Box(2, 7, Size - 13, Size - 9, RGB(235, 150, 40))
      DrawingMode(#PB_2DDrawing_Outlined)
      Box(2, 7, Size - 13, Size - 9, RGB(150, 90, 20))
      DrawingMode(#PB_2DDrawing_Default)
    Else
      Box(2, 7, (Size - 13) / 2, (Size - 9) / 2, RGB(20, 20, 20))
      Box(2 + (Size - 13) / 2, 7 + (Size - 9) / 2, (Size - 13) / 2, (Size - 9) / 2, RGB(20, 20, 20))
      DrawingMode(#PB_2DDrawing_Outlined)
      Box(2, 7, Size - 13, Size - 9, RGB(120, 120, 120))
      DrawingMode(#PB_2DDrawing_Default)
    EndIf
    Protected AX = Size - 7
    If IsRepoe
      LineXY(AX, 2, AX, 10, RGB(190, 40, 40))
      LineXY(AX - 3, 6, AX, 10, RGB(190, 40, 40))
      LineXY(AX + 3, 6, AX, 10, RGB(190, 40, 40))
    Else
      LineXY(AX, 10, AX, 2, RGB(190, 40, 40))
      LineXY(AX - 3, 6, AX, 2, RGB(190, 40, 40))
      LineXY(AX + 3, 6, AX, 2, RGB(190, 40, 40))
    EndIf
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; --- Icones do menu AJUSTE (F4, fase 6) -----------------------------------

; Seta solida generica - Direction: 0=cima, 1=baixo, 2=esquerda, 3=direita
; (mesma convencao das procedures de scroll/rotacao). Um so gerador
; parametrizado pros 4 botoes de direcao, em vez de 4 quase-identicos -
; reaproveita CharEd_DrawFilledHTri/VTri (CharsetEditorGui.pbi, ja usados
; pelos icones de espelhar/girar do editor de alfabetos) em vez de duplicar
; a logica de preencher um triangulo.
Procedure GraphosScr_CreateArrowIcon(Size.i, Direction.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected Mid = Size / 2, Half = Size / 2 - 4
    Select Direction
      Case 0 : CharEd_DrawFilledVTri(Mid, Size - 5, 4, Half, RGB(40, 90, 160))
      Case 1 : CharEd_DrawFilledVTri(Mid, 4, Size - 5, Half, RGB(40, 90, 160))
      Case 2 : CharEd_DrawFilledHTri(Mid, Size - 5, 4, Half, RGB(40, 90, 160))
      Case 3 : CharEd_DrawFilledHTri(Mid, 4, Size - 5, Half, RGB(40, 90, 160))
    EndSelect
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "8 pixels" (passo do SCROLL/ROTACAO 8x8): quadrado solido maior,
; contrastando com o pixel isolado de GraphosScr_CreatePixelIcon (o passo de
; 1px reaproveita esse icone direto, sem precisar de outro novo).
Procedure GraphosScr_CreateStep8Icon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Box(3, 3, Size - 6, Size - 6, RGB(20, 20, 20))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Rotacao" (wraparound - a parte que sai reentra pelo lado oposto): seta
; circular, mesmo espirito conceitual do icone de "Restaurar"
; (GraphosScr_CreateUndoIcon) mas cor propria, pra nao confundir as duas
; acoes (uma e' backup/restore, a outra e' modo de deslocamento).
Procedure GraphosScr_CreateRotateModeIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Circle(Size / 2, Size / 2, Size / 2 - 3, RGB(150, 60, 170))
    DrawingMode(#PB_2DDrawing_Default)
    LineXY(Size - 5, Size / 2 - 4, Size - 5, 4, RGB(150, 60, 170))
    LineXY(Size - 5, 4, Size - 9, 4, RGB(150, 60, 170))
    LineXY(Size - 5, 4, Size - 9, 8, RGB(150, 60, 170))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; --- Persistencia no projeto (fase 5) - Telas/Layouts/Shapes, ver
; ProjectDB.pbi (StoreGraphosScreen/Layout/Shape e familia) e comentario
; grande no topo do arquivo. Mesmo padrao de confirmacao de descarte ja
; usado pelo editor de alfabetos/sprites (CharEd_ConfirmDiscardAlphabet/
; SpriteEd_ConfirmDiscardSprite) - uma so mensagem generica, reaproveitada
; pra Tela/Layout (compartilham CanvasDirty, ja que sao dois formatos de
; salvar o MESMO framebuffer em edicao) e pra Shape (ShapeDirty, buffer
; proprio, separado do canvas principal).
Procedure.b GraphosScr_ConfirmDiscardChanges()
  ProcedureReturn Bool(MessageRequester("Alteracoes nao registradas",
                        "Ha alteracoes ainda nao registradas no projeto. Descartar mesmo assim?",
                        #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
EndProcedure

; Previa em miniatura de um SHAPE (recorte de tamanho variavel, W x H) - nao
; da pra reaproveitar Scr2Ed_RedrawCanvas (fixo em 256x192/zoom 2), entao
; escala pra caber na caixinha #GraphosScr_ShapePrevW x ...PrevH, centralizado.
; Scr2_GetPixelColor(...) continua valido aqui mesmo com PatternBit/RowFG/
; RowBG dimensionados no tamanho MAXIMO do canvas (so' os limites 256/192 do
; motor importam pro clip interno, nao o W/H logico do shape).
#GraphosScr_ShapePrevW = 150
#GraphosScr_ShapePrevH = 70

Procedure GraphosScr_RedrawShapePreview(Canvas, Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), Array Palette.l(1), W.i, H.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Box(0, 0, #GraphosScr_ShapePrevW, #GraphosScr_ShapePrevH, RGB(70, 70, 70))
  If W > 0 And H > 0
    Protected Z = #GraphosScr_ShapePrevW / W
    Protected ZY = #GraphosScr_ShapePrevH / H
    If ZY < Z : Z = ZY : EndIf
    If Z < 1 : Z = 1 : EndIf
    Protected DrawW = W * Z, DrawH = H * Z
    Protected OffX = (#GraphosScr_ShapePrevW - DrawW) / 2, OffY = (#GraphosScr_ShapePrevH - DrawH) / 2
    Protected X, Y, C
    For Y = 0 To H - 1
      For X = 0 To W - 1
        C = Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), X, Y)
        Box(OffX + X * Z, OffY + Y * Z, Z, Z, Palette(C))
      Next
    Next
  EndIf
  StopDrawing()
EndProcedure

; --- Menu MISCELANEA (F5, fase 7): ZOOM, SHAPE (carimbo), CORTE, GRID -----

; GRID: malha mostrando os limites das celulas de 8x8 (24x32 no sistema de
; coordenadas do Graphos III). O original altera de verdade a cor de PAPER
; de toda a tela pra desenhar essa malha (destrutivo, precisava disso por
; limitacao de hardware); aqui e' reinterpretado como um OVERLAY nao
; destrutivo (linhas finas cinza desenhadas por cima do canvas a cada
; redesenho, nunca gravadas em PatternBit/RowFG/RowBG) - mais seguro (nao
; existe risco de perder as cores de verdade da tela) e mais no espirito de
; "mostrar/esconder grade" que qualquer editor grafico moderno ja tem.
Procedure GraphosScr_DrawGridOverlay(Canvas)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected i
  DrawingMode(#PB_2DDrawing_Default)
  For i = 0 To #Scr2_Width Step 8
    LineXY(i * #Scr2Ed_Zoom, 0, i * #Scr2Ed_Zoom, #Scr2_Height * #Scr2Ed_Zoom, RGB(150, 150, 150))
  Next
  For i = 0 To #Scr2_Height Step 8
    LineXY(0, i * #Scr2Ed_Zoom, #Scr2_Width * #Scr2Ed_Zoom, i * #Scr2Ed_Zoom, RGB(150, 150, 150))
  Next
  StopDrawing()
EndProcedure

; Redesenho "completo" do canvas principal - sempre usado no lugar de
; Scr2Ed_RedrawCanvas puro daqui em diante, pra que o overlay de GRID (se
; ligado) nunca fique defasado depois de qualquer operacao de desenho.
Procedure GraphosScr_RedrawCanvasFull(Canvas, Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), Array Palette.l(1), ShowGrid.b)
  Scr2Ed_RedrawCanvas(Canvas, PatternBit(), RowFG(), RowBG(), Palette())
  If ShowGrid
    GraphosScr_DrawGridOverlay(Canvas)
  EndIf
EndProcedure

; CORTE: manipula os PIXELS (nunca as cores - "o usuario manipula e modifica
; os pixels de uma determinada parte da tela", manual original) de um
; recorte retangular marcado no canvas. Sem alinhamento de 8px (ao contrario
; do SHAPE) porque CORTE nunca mexe em RowFG/RowBG, entao nao ha celula de
; cor pra desalinhar.
Procedure GraphosScr_CorteInvert(Array PatternBit.a(2), X.i, Y.i, W.i, H.i)
  Protected PX, PY
  For PY = Y To Y + H - 1
    For PX = X To X + W - 1
      PatternBit(PY, PX) = 1 - PatternBit(PY, PX)
    Next
  Next
EndProcedure

; "E" do manual original: espelha o corte na direcao horizontal (inverte a
; ordem das colunas dentro do recorte).
Procedure GraphosScr_CorteMirrorH(Array PatternBit.a(2), X.i, Y.i, W.i, H.i)
  Protected PX, PY
  Protected.a Tmp
  For PY = Y To Y + H - 1
    For PX = 0 To (W / 2) - 1
      Tmp = PatternBit(PY, X + PX)
      PatternBit(PY, X + PX) = PatternBit(PY, X + W - 1 - PX)
      PatternBit(PY, X + W - 1 - PX) = Tmp
    Next
  Next
EndProcedure

; "R" do manual original: espelha o corte na direcao vertical (inverte a
; ordem das linhas dentro do recorte).
Procedure GraphosScr_CorteMirrorV(Array PatternBit.a(2), X.i, Y.i, W.i, H.i)
  Protected PX, PY
  Protected.a Tmp
  For PX = X To X + W - 1
    For PY = 0 To (H / 2) - 1
      Tmp = PatternBit(Y + PY, PX)
      PatternBit(Y + PY, PX) = PatternBit(Y + H - 1 - PY, PX)
      PatternBit(Y + H - 1 - PY, PX) = Tmp
    Next
  Next
EndProcedure

; Contorno solido marcando o recorte do CORTE - desenhado so' logo apos
; marcar/aplicar uma operacao (nao sobrevive a outros redesenhos depois
; disso, mesma limitacao pratica da previa do SHAPE - o recorte em si
; continua lembrado internamente mesmo que o contorno visual suma).
Procedure GraphosScr_DrawCorteOverlay(Canvas, X.i, Y.i, W.i, H.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  DrawingMode(#PB_2DDrawing_Outlined)
  Box(X * #Scr2Ed_Zoom, Y * #Scr2Ed_Zoom, W * #Scr2Ed_Zoom, H * #Scr2Ed_Zoom, RGB(150, 60, 170))
  DrawingMode(#PB_2DDrawing_Default)
  StopDrawing()
EndProcedure


; SHAPE (carimbo): posiciona um shape do banco (o que estiver carregado na
; barra de projeto Shape, fase 5) sobre a tela principal. MASCARA cola
; pixels E cores do shape (substitui tudo, "apagando o que esta por baixo");
; AND/OR/XOR sao operacoes logicas SO no bit do pixel - nunca mexem em
; RowFG/RowBG (fiel ao manual: "embora os atributos nao sejam alterados") -
; onde um pixel novo acende, ele usa a cor que a celula de destino ja tinha.
; DestX precisa estar alinhado ao grid de 8px (mesma exigencia da captura,
; ver GraphosScr_ComputeSnapRect) pra colar corretamente as celulas de cor
; no modo MASCARA.
Enumeration GraphosStampMode
  #GraphosStampMode_Mascara
  #GraphosStampMode_And
  #GraphosStampMode_Or
  #GraphosStampMode_Xor
EndEnumeration

Procedure GraphosScr_StampShape(Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), Array ShapePattern.a(2), Array ShapeFG.a(2), Array ShapeBG.a(2), DestX.i, DestY.i, ShapeW.i, ShapeH.i, Mode.i)
  Protected SX, SY, DX, DY, SPix, Cx, SCx
  If Mode = #GraphosStampMode_Mascara
    For SY = 0 To ShapeH - 1
      DY = DestY + SY
      If DY >= 0 And DY < #Scr2_Height
        For SX = 0 To ShapeW - 1
          DX = DestX + SX
          If DX >= 0 And DX < #Scr2_Width
            PatternBit(DY, DX) = ShapePattern(SY, SX)
          EndIf
        Next
        For SCx = 0 To (ShapeW / 8) - 1
          Cx = (DestX / 8) + SCx
          If Cx >= 0 And Cx < #Scr2_Cols
            RowFG(DY, Cx) = ShapeFG(SY, SCx)
            RowBG(DY, Cx) = ShapeBG(SY, SCx)
          EndIf
        Next
      EndIf
    Next
  Else
    For SY = 0 To ShapeH - 1
      DY = DestY + SY
      If DY >= 0 And DY < #Scr2_Height
        For SX = 0 To ShapeW - 1
          DX = DestX + SX
          If DX >= 0 And DX < #Scr2_Width
            SPix = ShapePattern(SY, SX)
            Select Mode
              Case #GraphosStampMode_And : PatternBit(DY, DX) = SPix & PatternBit(DY, DX)
              Case #GraphosStampMode_Or  : PatternBit(DY, DX) = SPix | PatternBit(DY, DX)
              Case #GraphosStampMode_Xor : PatternBit(DY, DX) = Bool(SPix <> PatternBit(DY, DX))
            EndSelect
          EndIf
        Next
      EndIf
    Next
  EndIf
EndProcedure

; "Quadro elastico" do carimbo - segue o mouse ate o clique fixar (mesmo
; padrao de TEXTO/GraphosScr_DrawTextPreview), sempre mostrando as cores
; PROPRIAS do shape (independente do modo escolhido - e' so' um guia visual
; de posicionamento, o resultado real depende do modo na hora de carimbar).
Procedure GraphosScr_DrawStampPreview(Canvas, Array ShapePattern.a(2), Array ShapeFG.a(2), Array ShapeBG.a(2), Array Palette.l(1), DestX.i, DestY.i, W.i, H.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected SX, SY, CX, CY, C
  For SY = 0 To H - 1
    For SX = 0 To W - 1
      C = Scr2_GetPixelColor(ShapePattern(), ShapeFG(), ShapeBG(), SX, SY)
      CX = (DestX + SX) * #Scr2Ed_Zoom
      CY = (DestY + SY) * #Scr2Ed_Zoom
      Box(CX, CY, #Scr2Ed_Zoom, #Scr2Ed_Zoom, Palette(C))
    Next
  Next
  DrawingMode(#PB_2DDrawing_Outlined)
  Box(DestX * #Scr2Ed_Zoom, DestY * #Scr2Ed_Zoom, W * #Scr2Ed_Zoom, H * #Scr2Ed_Zoom, Scr2Ed_AnchorColor)
  DrawingMode(#PB_2DDrawing_Default)
  StopDrawing()
EndProcedure

; ZOOM: edicao ampliada de uma regiao marcada do canvas - reinterpretacao
; simplificada do original (que tinha 3 quadros TELA/INK/PAPER e modos
; A/S/R de pixel escolhidos por tecla) - aqui e' so' Lapis/Borracha, mesmo
; par ja usado no resto do editor, numa janela a parte. Roda seu proprio
; laco de eventos (modal em relacao a janela principal do Graphos, mesmo
; padrao de sub-janela ja usado por SpriteEditorGui/CharsetEditorGui) e
; escreve DIRETO nos MESMOS arrays PatternBit/RowFG/RowBG da janela
; principal (arrays sao passados por referencia no PureBasic - nenhuma
; copia, nenhum "aplicar de volta" precisa acontecer ao fechar).
Procedure GraphosScr_RedrawZoomCanvas(Canvas, Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), Array Palette.l(1), RegionX.i, RegionY.i, RegionW.i, RegionH.i, ZoomFactor.i)
  If Not StartDrawing(CanvasOutput(Canvas))
    ProcedureReturn
  EndIf
  Protected X, Y, C
  For Y = 0 To RegionH - 1
    For X = 0 To RegionW - 1
      C = Scr2_GetPixelColor(PatternBit(), RowFG(), RowBG(), RegionX + X, RegionY + Y)
      Box(X * ZoomFactor, Y * ZoomFactor, ZoomFactor, ZoomFactor, Palette(C))
    Next
  Next
  DrawingMode(#PB_2DDrawing_Outlined)
  For Y = 1 To RegionH - 1
    LineXY(0, Y * ZoomFactor, RegionW * ZoomFactor, Y * ZoomFactor, RGB(210, 210, 210))
  Next
  For X = 1 To RegionW - 1
    LineXY(X * ZoomFactor, 0, X * ZoomFactor, RegionH * ZoomFactor, RGB(210, 210, 210))
  Next
  DrawingMode(#PB_2DDrawing_Default)
  StopDrawing()
EndProcedure

Procedure GraphosScr_OpenZoomWindow(ParentWin, Array PatternBit.a(2), Array RowFG.a(2), Array RowBG.a(2), Array Palette.l(1), RegionX.i, RegionY.i, RegionW.i, RegionH.i, InkColor.i, PaperColor.i)
  Protected ZoomFactor = 300 / RegionW
  Protected ZFY = 300 / RegionH
  If ZFY < ZoomFactor : ZoomFactor = ZFY : EndIf
  If ZoomFactor < 2 : ZoomFactor = 2 : EndIf
  If ZoomFactor > 24 : ZoomFactor = 24 : EndIf
  Protected CanvasW = RegionW * ZoomFactor, CanvasH = RegionH * ZoomFactor

  Protected Win = OpenModelessChildWindow(ParentWin, 0, 0, CanvasW + 30, CanvasH + 70,
                                          "Zoom (" + Str(RegionW) + "x" + Str(RegionH) + ")",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  Protected G_ZCanvas = CanvasGadget(#PB_Any, 15, 15, CanvasW, CanvasH)
  Protected PencilIcon = SpriteEd_CreatePencilIcon(22)
  Protected G_ZPencil = ButtonImageGadget(#PB_Any, 15, CanvasH + 25, 34, 30, ImageID(PencilIcon), #PB_Button_Toggle)
  GadgetToolTip(G_ZPencil, "Lapis: liga o pixel com a cor de Tinta")
  Protected EraserIcon = SpriteEd_CreateEraserIcon(22)
  Protected G_ZEraser = ButtonImageGadget(#PB_Any, 55, CanvasH + 25, 34, 30, ImageID(EraserIcon), #PB_Button_Toggle)
  GadgetToolTip(G_ZEraser, "Borracha: apaga o pixel usando a cor de Fundo")
  Dim ZPenGadgets.i(1)
  ZPenGadgets(0) = G_ZPencil
  ZPenGadgets(1) = G_ZEraser
  Protected G_ZClose = ThemedButton(CanvasW - 85, CanvasH + 25, 100, 30, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_ZClose, "Fechar")

  Protected ZPenMode.i = #GraphosPenMode_Insert
  SetGadgetState(G_ZPencil, #True)

  GraphosScr_RedrawZoomCanvas(G_ZCanvas, PatternBit(), RowFG(), RowBG(), Palette(), RegionX, RegionY, RegionW, RegionH, ZoomFactor)

  Protected Event, Quit = #False, MouseX, MouseY, PX, PY
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case G_ZPencil
            ZPenMode = #GraphosPenMode_Insert
            SpriteEd_UnpressOtherTools(ZPenGadgets(), G_ZPencil)
            SetGadgetState(G_ZPencil, #True)

          Case G_ZEraser
            ZPenMode = #GraphosPenMode_Delete
            SpriteEd_UnpressOtherTools(ZPenGadgets(), G_ZEraser)
            SetGadgetState(G_ZEraser, #True)

          Case G_ZCanvas
            Select EventType()
              Case #PB_EventType_LeftButtonDown
                MouseX = GetGadgetAttribute(G_ZCanvas, #PB_Canvas_MouseX)
                MouseY = GetGadgetAttribute(G_ZCanvas, #PB_Canvas_MouseY)
                PX = RegionX + (MouseX / ZoomFactor)
                PY = RegionY + (MouseY / ZoomFactor)
                If PX >= RegionX And PX < RegionX + RegionW And PY >= RegionY And PY < RegionY + RegionH
                  If ZPenMode = #GraphosPenMode_Insert
                    Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), PX, PY, InkColor, #True)
                  Else
                    Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), PX, PY, PaperColor, #False)
                  EndIf
                  GraphosScr_RedrawZoomCanvas(G_ZCanvas, PatternBit(), RowFG(), RowBG(), Palette(), RegionX, RegionY, RegionW, RegionH, ZoomFactor)
                EndIf

              Case #PB_EventType_MouseMove
                If GetGadgetAttribute(G_ZCanvas, #PB_Canvas_Buttons) & #PB_Canvas_LeftButton
                  MouseX = GetGadgetAttribute(G_ZCanvas, #PB_Canvas_MouseX)
                  MouseY = GetGadgetAttribute(G_ZCanvas, #PB_Canvas_MouseY)
                  PX = RegionX + (MouseX / ZoomFactor)
                  PY = RegionY + (MouseY / ZoomFactor)
                  If PX >= RegionX And PX < RegionX + RegionW And PY >= RegionY And PY < RegionY + RegionH
                    If ZPenMode = #GraphosPenMode_Insert
                      Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), PX, PY, InkColor, #True)
                    Else
                      Scr2_SetPixel(PatternBit(), RowFG(), RowBG(), PX, PY, PaperColor, #False)
                    EndIf
                    GraphosScr_RedrawZoomCanvas(G_ZCanvas, PatternBit(), RowFG(), RowBG(), Palette(), RegionX, RegionY, RegionW, RegionH, ZoomFactor)
                  EndIf
                EndIf
            EndSelect

          Case G_ZClose
            Quit = #True

        EndSelect

      Case #PB_Event_CloseWindow
        Quit = #True

    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWin, Win)
EndProcedure

; --- Icones do menu MISCELANEA (F5, fase 7) -------------------------------

Procedure GraphosScr_CreateZoomIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    DrawingMode(#PB_2DDrawing_Outlined)
    Circle(Size / 2 - 3, Size / 2 - 3, Size / 2 - 7, RGB(40, 90, 160))
    DrawingMode(#PB_2DDrawing_Default)
    LineXY(Size / 2 + 1, Size / 2 + 1, Size - 4, Size - 4, RGB(40, 90, 160))
    LineXY(Size / 2 + 2, Size / 2 + 1, Size - 4, Size - 5, RGB(40, 90, 160))
    LineXY(Size / 2 + 1, Size / 2 + 2, Size - 5, Size - 4, RGB(40, 90, 160))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Icone parametrizado das 4 operacoes de carimbo (MASCARA/AND/OR/XOR) - 2
; quadrados sobrepostos (A = shape, azul; B = tela, laranja) mostrando
; exatamente qual regiao logica fica colorida em cada modo, em vez de 4
; icones desenhados a mao sem relacao visual entre si.
Procedure GraphosScr_CreateStampModeIcon(Size.i, Mode.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected AX = 2, BX = Size / 2 - 1, W = Size / 2 + 1, TY = 4, H = Size - 10
    Protected OverlapX = BX, OverlapW = (AX + W) - BX
    Protected Blue = RGB(60, 110, 200), Orange = RGB(230, 150, 40), Purple = RGB(140, 90, 170)
    Select Mode
      Case #GraphosStampMode_Mascara
        Box(AX, TY, (BX + W) - AX, H, Blue)
      Case #GraphosStampMode_And
        DrawingMode(#PB_2DDrawing_Outlined)
        Box(AX, TY, W, H, Blue)
        Box(BX, TY, W, H, Orange)
        DrawingMode(#PB_2DDrawing_Default)
        Box(OverlapX, TY, OverlapW, H, Purple)
      Case #GraphosStampMode_Or
        Box(AX, TY, OverlapX - AX, H, Blue)
        Box(OverlapX, TY, OverlapW, H, Purple)
        Box(OverlapX + OverlapW, TY, (BX + W) - (OverlapX + OverlapW), H, Orange)
      Case #GraphosStampMode_Xor
        Box(AX, TY, OverlapX - AX, H, Blue)
        Box(OverlapX + OverlapW, TY, (BX + W) - (OverlapX + OverlapW), H, Orange)
    EndSelect
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Carimbar shape" (acao) - silhueta classica de carimbo de borracha.
Procedure GraphosScr_CreateStampIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Box(3, Size - 8, Size - 6, 6, RGB(90, 60, 40))
    Box(Size / 2 - 3, Size - 16, 6, 8, RGB(120, 90, 60))
    Box(Size / 2 - 5, 4, 10, 6, RGB(150, 110, 70))
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; "Marcar area" do CORTE - retangulo tracejado (marquee classico).
Procedure GraphosScr_CreateSelectIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected i
    For i = 3 To Size - 5 Step 4
      LineXY(i, 3, i + 2, 3, RGB(20, 20, 20))
      LineXY(i, Size - 4, i + 2, Size - 4, RGB(20, 20, 20))
      LineXY(3, i, 3, i + 2, RGB(20, 20, 20))
      LineXY(Size - 4, i, Size - 4, i + 2, RGB(20, 20, 20))
    Next
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

; Espelhar horizontal ("E")/vertical ("R") do CORTE - 2 setas apontando pra
; uma linha central, reaproveitando CharEd_DrawFilledHTri/VTri (mesmas
; usadas pelas setas do menu AJUSTE, fase 6).
Procedure GraphosScr_CreateMirrorIcon(Size.i, Horizontal.b)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected Mid = Size / 2
    Protected Half = Size / 2 - 6
    If Half < 2 : Half = 2 : EndIf
    If Horizontal
      LineXY(Mid, 2, Mid, Size - 3, RGB(120, 120, 120))
      CharEd_DrawFilledHTri(Mid, 3, Mid - 3, Half, RGB(150, 60, 170))
      CharEd_DrawFilledHTri(Mid, Size - 4, Mid + 3, Half, RGB(150, 60, 170))
    Else
      LineXY(2, Mid, Size - 3, Mid, RGB(120, 120, 120))
      CharEd_DrawFilledVTri(Mid, 3, Mid - 3, Half, RGB(150, 60, 170))
      CharEd_DrawFilledVTri(Mid, Size - 4, Mid + 3, Half, RGB(150, 60, 170))
    EndIf
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

Procedure GraphosScr_CreateGridIcon(Size.i)
  Protected Img = CreateImage(#PB_Any, Size, Size, 24, RGB(255, 255, 255))
  If StartDrawing(ImageOutput(Img))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, Size, Size, RGB(255, 255, 255))
    Protected Cell = Size / 4, Row, Col
    For Row = 0 To 3
      For Col = 0 To 3
        If (Row + Col) % 2 = 0
          Box(Col * Cell, Row * Cell, Cell, Cell, RGB(205, 205, 205))
        EndIf
      Next
    Next
    DrawingMode(#PB_2DDrawing_Outlined)
    Box(0, 0, Size, Size, RGB(130, 130, 130))
    DrawingMode(#PB_2DDrawing_Default)
    StopDrawing()
  EndIf
  ProcedureReturn Img
EndProcedure

Procedure GraphosScreenGui_OpenWindow(ParentWindow)
  Protected Zoom = 2
  Protected CanvasW = #Scr2_Width * Zoom, CanvasH = #Scr2_Height * Zoom
  Protected CanvasX = 15, CanvasY = 50
  Protected RightX = CanvasX + CanvasW + 20
  Protected RightW = 200

  ; --- Layout pre-calculado (precisa existir antes do OpenWindow pra
  ; dimensionar a janela). Reorganizado nesta sessao (pedido explicito do
  ; usuario: a coluna direita estava ficando alta demais e a area abaixo do
  ; canvas, vazia) - agora a coluna direita so tem as grades de ferramentas
  ; (icones, 5 por linha em vez de 3) e a paleta/status, enquanto BLOCO/
  ; TEXTO (campos de texto, mais naturais na horizontal) descem pra uma
  ; faixa abaixo do canvas, ao lado do botao Fechar. INK/PAPER lado a lado
  ; (nao empilhados) - pedido explicito do usuario, economiza uma faixa
  ; inteira (72px) de altura na coluna direita.
  Protected PaletteSize = #Scr2Ed_PaletteSize

  Protected DesenhoLabelY = CanvasY + 18 + PaletteSize + 16
  Protected DesenhoRow1Y = DesenhoLabelY + 18
  Protected DesenhoRow2Y = DesenhoRow1Y + 36
  Protected DesenhoBottom = DesenhoRow2Y + 30

  ; BLOCO (tamanho do cursor da ferramenta BLOCO) logo abaixo da grade
  ; DESENHO - pedido explicito do usuario, fica junto da ferramenta que ele
  ; configura em vez de longe dela na faixa abaixo do canvas.
  Protected BlockLabelY = DesenhoBottom + 16
  Protected BlockFieldY = BlockLabelY + 18
  Protected BlockBottom = BlockFieldY + 22

  Protected PenLabelY = BlockBottom + 16
  Protected PenY = PenLabelY + 18
  Protected PenBottom = PenY + 30

  Protected TelaLabelY = PenBottom + 16
  Protected TelaRow1Y = TelaLabelY + 18
  Protected TelaRow2Y = TelaRow1Y + 36
  Protected TelaBottom = TelaRow2Y + 30

  ; Menu AJUSTE (F4, fase 6): modo (passo 1px/8px, SCROLL/ROTACAO) + 4 setas
  ; de direcao, logo abaixo da grade TELA.
  Protected AjusteLabelY = TelaBottom + 16
  Protected AjusteModeY = AjusteLabelY + 18
  Protected AjusteArrowY = AjusteModeY + 36
  Protected AjusteBottom = AjusteArrowY + 30

  ; Menu MISCELANEA (F5, fase 7): 11 icones, 5 por linha (mesmo padrao das
  ; grades DESENHO/TELA) - ZOOM/carimbo(4 modos)/CORTE(marcar+3 acoes)/GRID.
  Protected MiscLabelY = AjusteBottom + 16
  Protected MiscRow1Y = MiscLabelY + 18
  Protected MiscRow2Y = MiscRow1Y + 36
  Protected MiscRow3Y = MiscRow2Y + 36
  Protected MiscBottom = MiscRow3Y + 30

  Protected StatusY = MiscBottom + 14
  Protected StatusH = 90
  Protected StatusBottom = StatusY + StatusH

  ; Faixa abaixo do canvas: barras de projeto Tela/Layout/Shape (fase 5,
  ; persistencia no .msxproject - mesmo padrao numero/navegacao/tag/Novo/
  ; Registrar do editor de sprites/alfabetos) e depois o TEXTO (BLOCO mudou
  ; pra coluna direita, ver acima) - uma linha por opcao (label + campo),
  ; pedido explicito do usuario em vez do layout anterior (tudo numa linha
  ; so). Ancorada logo abaixo do canvas (nao da coluna direita) - pedido
  ; explicito do usuario, "subir tudo mais proximo ao fim do canvas" -
  ; cada linha desta faixa fica bem mais estreita que RightX (nunca invade
  ; a coluna direita em X), entao nao ha risco de colisao mesmo com Y
  ; comecando logo cedo.
  Protected ScreenBarY = CanvasY + CanvasH + 14
  Protected LayoutBarY = ScreenBarY + 30
  Protected ShapeBarY = LayoutBarY + 30
  ; "Marcar area..." + previa do Shape ganham linha PROPRIA abaixo dos 3
  ; navegadores (pedido explicito do usuario) - na mesma linha do Shape
  ; extendiam demais em X (ate' a previa), quase encostando na coluna
  ; direita; numa linha separada, estreita, isso deixa de ser um problema.
  Protected ShapeMarkRowY = ShapeBarY + 34
  Protected ShapeBottom = ShapeMarkRowY + #GraphosScr_ShapePrevH

  Protected TextSectionLabelY = ShapeBottom + 14
  Protected TextAlphaRowY = TextSectionLabelY + 18
  Protected TextStyleRowY = TextAlphaRowY + 26
  Protected TextStrRowY = TextStyleRowY + 26
  Protected TextBtnRowY = TextStrRowY + 26
  Protected TextBottom = TextBtnRowY + 26
  Protected CloseY = TextBottom + 14
  Protected CloseBottom = CloseY + 30

  Protected WinW = RightX + RightW + 15

  Protected WinH = StatusBottom + 20
  If CloseBottom + 20 > WinH
    WinH = CloseBottom + 20
  EndIf

  Protected Win = OpenModelessChildWindow(ParentWindow, 0, 0, WinW, WinH, "Graphos III - Tela (SCREEN 2)",
                                          #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If Not Win
    ProcedureReturn
  EndIf

  TextGadget(#PB_Any, CanvasX, 16, CanvasW, 20,
             "SCREEN 2 (256x192) - color clash identico ao MSX: 2 cores por faixa de 8 pixels")
  Protected G_Canvas = CanvasGadget(#PB_Any, CanvasX, CanvasY, CanvasW, CanvasH)

  ; --- Paleta INK/PAPER lado a lado (pedido explicito do usuario - antes
  ; ficavam empilhadas, uma faixa de 72px em cima da outra) - mesma paleta
  ; MSX1 e mesmo desenho de swatch ja usados por "Criar -> Draw Screen
  ; 2...", reaproveitados sem mudanca ---
  TextGadget(#PB_Any, RightX, CanvasY, 85, 18, "Tinta (INK):")
  Protected G_PaletteInk = CanvasGadget(#PB_Any, RightX, CanvasY + 18, PaletteSize, PaletteSize)
  TextGadget(#PB_Any, RightX + PaletteSize + 16, CanvasY, 110, 18, "Fundo (PAPER):")
  Protected G_PalettePaper = CanvasGadget(#PB_Any, RightX + PaletteSize + 16, CanvasY + 18, PaletteSize, PaletteSize)

  ; --- Ferramentas do menu DESENHO (F1): TRACO/BLOCO/LINHA/RETANGULO/RAIO/
  ; CIRCULO/PINTURA/SPRAY/FILL, 5 icones por linha ---
  TextGadget(#PB_Any, RightX, DesenhoLabelY, RightW, 16, "Ferramenta (DESENHO):")

  Protected TracoIcon = GraphosScr_CreatePixelIcon(22)
  Protected G_ToolTraco = ButtonImageGadget(#PB_Any, RightX, DesenhoRow1Y, 34, 30, ImageID(TracoIcon), #PB_Button_Toggle)
  GadgetToolTip(G_ToolTraco, "TRACO: liga/apaga um pixel por vez - arraste pra riscar")

  Protected BlocoIcon = SpriteEd_CreateBrushIcon(22)
  Protected G_ToolBloco = ButtonImageGadget(#PB_Any, RightX + 40, DesenhoRow1Y, 34, 30, ImageID(BlocoIcon), #PB_Button_Toggle)
  GadgetToolTip(G_ToolBloco, "BLOCO: como o TRACO, mas altera um bloco Largura x Altura de pixels de uma vez")

  Protected LinhaIcon = SpriteEd_CreateLineToolIcon(22)
  Protected G_ToolLinha = ButtonImageGadget(#PB_Any, RightX + 80, DesenhoRow1Y, 34, 30, ImageID(LinhaIcon), #PB_Button_Toggle)
  GadgetToolTip(G_ToolLinha, "LINHA: marque o ponto inicial e o final - o final vira o inicio do proximo segmento")

  Protected RetanguloIcon = SpriteEd_CreateRectOutlineIcon(22)
  Protected G_ToolRetangulo = ButtonImageGadget(#PB_Any, RightX + 120, DesenhoRow1Y, 34, 30, ImageID(RetanguloIcon), #PB_Button_Toggle)
  GadgetToolTip(G_ToolRetangulo, "RETANGULO: marque um vertice fixo e depois o vertice oposto - clique direito cancela")

  Protected RaioIcon = GraphosScr_CreateRayIcon(22)
  Protected G_ToolRaio = ButtonImageGadget(#PB_Any, RightX + 160, DesenhoRow1Y, 34, 30, ImageID(RaioIcon), #PB_Button_Toggle)
  GadgetToolTip(G_ToolRaio, "RAIO: marque a origem fixa e depois cada ponto final - clique direito cancela")

  Protected CirculoIcon = SpriteEd_CreateEllipseOutlineIcon(22)
  Protected G_ToolCirculo = ButtonImageGadget(#PB_Any, RightX, DesenhoRow2Y, 34, 30, ImageID(CirculoIcon), #PB_Button_Toggle)
  GadgetToolTip(G_ToolCirculo, "CIRCULO: marque o centro fixo e depois um ponto por onde o circulo deve passar")

  Protected PinturaIcon = GraphosScr_CreatePaintIcon(22)
  Protected G_ToolPintura = ButtonImageGadget(#PB_Any, RightX + 40, DesenhoRow2Y, 34, 30, ImageID(PinturaIcon), #PB_Button_Toggle)
  GadgetToolTip(G_ToolPintura, "PINTURA: muda so a cor de Fundo sob o cursor, sem alterar o desenho (Tinta)")

  Protected SprayIcon = GraphosScr_CreateSprayIcon(22)
  Protected G_ToolSpray = ButtonImageGadget(#PB_Any, RightX + 80, DesenhoRow2Y, 34, 30, ImageID(SprayIcon), #PB_Button_Toggle)
  GadgetToolTip(G_ToolSpray, "SPRAY: borrifo aleatorio de pixels ao redor do cursor")

  Protected FillIcon = SpriteEd_CreateFillIcon(22)
  Protected G_ToolFill = ButtonImageGadget(#PB_Any, RightX + 120, DesenhoRow2Y, 34, 30, ImageID(FillIcon), #PB_Button_Toggle)
  GadgetToolTip(G_ToolFill, "FILL: preenche com Tinta a area conectada ao ponto clicado")

  Dim ToolGadgets.i(8)
  ToolGadgets(0) = G_ToolTraco
  ToolGadgets(1) = G_ToolBloco
  ToolGadgets(2) = G_ToolLinha
  ToolGadgets(3) = G_ToolRetangulo
  ToolGadgets(4) = G_ToolRaio
  ToolGadgets(5) = G_ToolCirculo
  ToolGadgets(6) = G_ToolPintura
  ToolGadgets(7) = G_ToolSpray
  ToolGadgets(8) = G_ToolFill

  ; --- Tamanho do cursor da ferramenta BLOCO, logo abaixo da grade DESENHO ---
  TextGadget(#PB_Any, RightX, BlockLabelY, RightW, 16, "Bloco - Largura x Altura:")
  Protected G_BlockW = StringGadget(#PB_Any, RightX, BlockFieldY, 45, 22, "2")
  TextGadget(#PB_Any, RightX + 48, BlockFieldY + 3, 12, 16, "x")
  Protected G_BlockH = StringGadget(#PB_Any, RightX + 62, BlockFieldY, 45, 22, "2")
  GadgetToolTip(G_BlockW, "Largura do bloco em pixels (1-64)")
  GadgetToolTip(G_BlockH, "Altura do bloco em pixels (1-64)")

  ; --- Alternador Lapis(INS)/Borracha(DEL) - so importa pra TRACO/BLOCO/
  ; SPRAY (ver GraphosScr_ToolUsesPenMode); fica desabilitado nas demais ---
  TextGadget(#PB_Any, RightX, PenLabelY, RightW, 16, "Modo (INS/DEL):")
  Protected PencilIcon = SpriteEd_CreatePencilIcon(22)
  Protected G_Pencil = ButtonImageGadget(#PB_Any, RightX, PenY, 34, 30, ImageID(PencilIcon), #PB_Button_Toggle)
  GadgetToolTip(G_Pencil, "Lapis (INSERT): TRACO/BLOCO/SPRAY setam pixels com a cor de Tinta")
  Protected EraserIcon = SpriteEd_CreateEraserIcon(22)
  Protected G_Eraser = ButtonImageGadget(#PB_Any, RightX + 40, PenY, 34, 30, ImageID(EraserIcon), #PB_Button_Toggle)
  GadgetToolTip(G_Eraser, "Borracha (DELETE): TRACO/BLOCO/SPRAY apagam pixels usando a cor de Fundo")
  Dim PenGadgets.i(1)
  PenGadgets(0) = G_Pencil
  PenGadgets(1) = G_Eraser

  ; --- Operacoes do menu TELA (F3, fase 4), 5 icones por linha - LIMPAR/
  ; SALVAR/RESTAURAR/INVERTE VIDEO/INVERTE ATRIBUTOS/RETIRA VIDEO/REPOE
  ; VIDEO/RETIRA ATRIBUTOS/REPOE ATRIBUTOS ---
  TextGadget(#PB_Any, RightX, TelaLabelY, RightW, 16, "Tela (TELA):")

  Protected LimparIcon = SpriteEd_CreateClearIcon(22)
  Protected G_TelaLimpar = ButtonImageGadget(#PB_Any, RightX, TelaRow1Y, 34, 30, ImageID(LimparIcon))
  GadgetToolTip(G_TelaLimpar, "LIMPA TELA: apaga tudo com as cores Tinta/Fundo atuais")

  Protected SalvarIcon = GraphosScr_CreateSaveIcon(22)
  Protected G_TelaSalva = ButtonImageGadget(#PB_Any, RightX + 40, TelaRow1Y, 34, 30, ImageID(SalvarIcon))
  GadgetToolTip(G_TelaSalva, "SALVA TELA: guarda a tela inteira (pixels + cores) num buffer")

  Protected RestaurarIcon = GraphosScr_CreateUndoIcon(22)
  Protected G_TelaRestaura = ButtonImageGadget(#PB_Any, RightX + 80, TelaRow1Y, 34, 30, ImageID(RestaurarIcon))
  GadgetToolTip(G_TelaRestaura, "Restaurar: devolve a tela guardada por SALVA TELA")

  Protected InverteVideoIcon = GraphosScr_CreateInvertVideoIcon(22)
  Protected G_TelaInverteVideo = ButtonImageGadget(#PB_Any, RightX + 120, TelaRow1Y, 34, 30, ImageID(InverteVideoIcon))
  GadgetToolTip(G_TelaInverteVideo, "INVERTE VIDEO: inverte o estado de cada pixel, sem mexer nas cores")

  Protected InverteAtributosIcon = GraphosScr_CreateInvertAttrsIcon(22)
  Protected G_TelaInverteAtributos = ButtonImageGadget(#PB_Any, RightX + 160, TelaRow1Y, 34, 30, ImageID(InverteAtributosIcon))
  GadgetToolTip(G_TelaInverteAtributos, "INVERTE ATRIBUTOS: troca Tinta/Fundo de toda a tela, sem mexer nos pixels")

  Protected RetiraVideoIcon = GraphosScr_CreateRetiraRepoeIcon(22, #False, #False)
  Protected G_TelaRetiraVideo = ButtonImageGadget(#PB_Any, RightX, TelaRow2Y, 34, 30, ImageID(RetiraVideoIcon))
  GadgetToolTip(G_TelaRetiraVideo, "RETIRA VIDEO: apaga os pixels (guarda num buffer pra REPOE VIDEO)")

  Protected RepoeVideoIcon = GraphosScr_CreateRetiraRepoeIcon(22, #False, #True)
  Protected G_TelaRepoeVideo = ButtonImageGadget(#PB_Any, RightX + 40, TelaRow2Y, 34, 30, ImageID(RepoeVideoIcon))
  GadgetToolTip(G_TelaRepoeVideo, "REPOE VIDEO: devolve os pixels apagados por RETIRA VIDEO")

  Protected RetiraAtributosIcon = GraphosScr_CreateRetiraRepoeIcon(22, #True, #False)
  Protected G_TelaRetiraAtributos = ButtonImageGadget(#PB_Any, RightX + 80, TelaRow2Y, 34, 30, ImageID(RetiraAtributosIcon))
  GadgetToolTip(G_TelaRetiraAtributos, "RETIRA ATRIBUTOS: remove as cores (guarda num buffer pra REPOE ATRIBUTOS), so os pixels ficam a vista")

  Protected RepoeAtributosIcon = GraphosScr_CreateRetiraRepoeIcon(22, #True, #True)
  Protected G_TelaRepoeAtributos = ButtonImageGadget(#PB_Any, RightX + 120, TelaRow2Y, 34, 30, ImageID(RepoeAtributosIcon))
  GadgetToolTip(G_TelaRepoeAtributos, "REPOE ATRIBUTOS: devolve as cores removidas por RETIRA ATRIBUTOS")

  ; --- Menu AJUSTE (F4, fase 6): passo (1px/8px) + modo (SCROLL/ROTACAO) +
  ; 4 setas de direcao. Passo e modo sao 2 alternadores independentes (mesmo
  ; padrao de botao-imagem + SpriteEd_UnpressOtherTools ja usado por Lapis/
  ; Borracha) - GraphosScr_ToolUsesPenMode nao se aplica aqui, sao 2 grupos
  ; a parte do ToolMode das ferramentas de DESENHO ---
  TextGadget(#PB_Any, RightX, AjusteLabelY, RightW, 16, "Ajuste (AJUSTE):")

  Protected Step1Icon = GraphosScr_CreatePixelIcon(22)
  Protected G_AjusteStep1 = ButtonImageGadget(#PB_Any, RightX, AjusteModeY, 34, 30, ImageID(Step1Icon), #PB_Button_Toggle)
  GadgetToolTip(G_AjusteStep1, "Passo de 1 pixel")
  Protected Step8Icon = GraphosScr_CreateStep8Icon(22)
  Protected G_AjusteStep8 = ButtonImageGadget(#PB_Any, RightX + 40, AjusteModeY, 34, 30, ImageID(Step8Icon), #PB_Button_Toggle)
  GadgetToolTip(G_AjusteStep8, "Passo de 8 pixels (desloca video + atributos juntos)")
  Dim AjusteStepGadgets.i(1)
  AjusteStepGadgets(0) = G_AjusteStep1
  AjusteStepGadgets(1) = G_AjusteStep8

  Protected ScrollModeIcon = CharEd_CreateNavIcon(22, 1, #True)
  Protected G_AjusteScroll = ButtonImageGadget(#PB_Any, RightX + 90, AjusteModeY, 34, 30, ImageID(ScrollModeIcon), #PB_Button_Toggle)
  GadgetToolTip(G_AjusteScroll, "SCROLL: a parte que sai da tela e' perdida")
  Protected RotateModeIcon = GraphosScr_CreateRotateModeIcon(22)
  Protected G_AjusteRotacao = ButtonImageGadget(#PB_Any, RightX + 130, AjusteModeY, 34, 30, ImageID(RotateModeIcon), #PB_Button_Toggle)
  GadgetToolTip(G_AjusteRotacao, "ROTACAO: a parte que sai da tela reentra pelo lado oposto")
  Dim AjusteWrapGadgets.i(1)
  AjusteWrapGadgets(0) = G_AjusteScroll
  AjusteWrapGadgets(1) = G_AjusteRotacao

  Protected ArrowUpIcon = GraphosScr_CreateArrowIcon(22, 0)
  Protected G_AjusteUp = ButtonImageGadget(#PB_Any, RightX, AjusteArrowY, 34, 30, ImageID(ArrowUpIcon))
  GadgetToolTip(G_AjusteUp, "Aplica pra cima")
  Protected ArrowDownIcon = GraphosScr_CreateArrowIcon(22, 1)
  Protected G_AjusteDown = ButtonImageGadget(#PB_Any, RightX + 40, AjusteArrowY, 34, 30, ImageID(ArrowDownIcon))
  GadgetToolTip(G_AjusteDown, "Aplica pra baixo")
  Protected ArrowLeftIcon = GraphosScr_CreateArrowIcon(22, 2)
  Protected G_AjusteLeft = ButtonImageGadget(#PB_Any, RightX + 80, AjusteArrowY, 34, 30, ImageID(ArrowLeftIcon))
  GadgetToolTip(G_AjusteLeft, "Aplica pra esquerda")
  Protected ArrowRightIcon = GraphosScr_CreateArrowIcon(22, 3)
  Protected G_AjusteRight = ButtonImageGadget(#PB_Any, RightX + 120, AjusteArrowY, 34, 30, ImageID(ArrowRightIcon))
  GadgetToolTip(G_AjusteRight, "Aplica pra direita")

  ; --- Menu MISCELANEA (F5, fase 7): ZOOM, SHAPE (carimbo com 4 modos),
  ; CORTE (marcar + Inverter/Espelhar) e GRID, 5 icones por linha ---
  TextGadget(#PB_Any, RightX, MiscLabelY, RightW, 16, "Misc (MISCELANEA):")

  Protected ZoomIcon = GraphosScr_CreateZoomIcon(22)
  Protected G_MiscZoom = ButtonImageGadget(#PB_Any, RightX, MiscRow1Y, 34, 30, ImageID(ZoomIcon))
  GadgetToolTip(G_MiscZoom, "ZOOM: marque 2 pontos no canvas (igual RETANGULO) pra abrir aquela area numa janela de edicao ampliada")

  Protected StampMascaraIcon = GraphosScr_CreateStampModeIcon(22, #GraphosStampMode_Mascara)
  Protected G_StampMascara = ButtonImageGadget(#PB_Any, RightX + 40, MiscRow1Y, 34, 30, ImageID(StampMascaraIcon), #PB_Button_Toggle)
  GadgetToolTip(G_StampMascara, "Carimbo MASCARA: cola pixels e cores do shape, substituindo tudo")

  Protected StampAndIcon = GraphosScr_CreateStampModeIcon(22, #GraphosStampMode_And)
  Protected G_StampAnd = ButtonImageGadget(#PB_Any, RightX + 80, MiscRow1Y, 34, 30, ImageID(StampAndIcon), #PB_Button_Toggle)
  GadgetToolTip(G_StampAnd, "Carimbo AND: so acende onde o shape E a tela ja estavam acesos (interseccao)")

  Protected StampOrIcon = GraphosScr_CreateStampModeIcon(22, #GraphosStampMode_Or)
  Protected G_StampOr = ButtonImageGadget(#PB_Any, RightX + 120, MiscRow1Y, 34, 30, ImageID(StampOrIcon), #PB_Button_Toggle)
  GadgetToolTip(G_StampOr, "Carimbo OR: acende onde o shape OU a tela ja estavam acesos (uniao)")

  Protected StampXorIcon = GraphosScr_CreateStampModeIcon(22, #GraphosStampMode_Xor)
  Protected G_StampXor = ButtonImageGadget(#PB_Any, RightX + 160, MiscRow1Y, 34, 30, ImageID(StampXorIcon), #PB_Button_Toggle)
  GadgetToolTip(G_StampXor, "Carimbo XOR: acende so onde um dos dois (shape OU tela, nunca os dois) estava aceso")

  Dim StampModeGadgets.i(3)
  StampModeGadgets(0) = G_StampMascara
  StampModeGadgets(1) = G_StampAnd
  StampModeGadgets(2) = G_StampOr
  StampModeGadgets(3) = G_StampXor

  Protected StampIcon = GraphosScr_CreateStampIcon(22)
  Protected G_StampPlace = ButtonImageGadget(#PB_Any, RightX, MiscRow2Y, 34, 30, ImageID(StampIcon))
  GadgetToolTip(G_StampPlace, "Carimbar shape: usa o shape carregado na barra de projeto Shape - mova o mouse ate o lugar certo e clique (direito cancela)")

  Protected CorteMarkIcon = GraphosScr_CreateSelectIcon(22)
  Protected G_CorteMark = ButtonImageGadget(#PB_Any, RightX + 40, MiscRow2Y, 34, 30, ImageID(CorteMarkIcon))
  GadgetToolTip(G_CorteMark, "CORTE: marque o vertice superior esquerdo e depois o inferior direito da area a manipular")

  Protected CorteInvertIcon = GraphosScr_CreateInvertVideoIcon(22)
  Protected G_CorteInvert = ButtonImageGadget(#PB_Any, RightX + 80, MiscRow2Y, 34, 30, ImageID(CorteInvertIcon))
  GadgetToolTip(G_CorteInvert, "CORTE - Inverter (I): inverte o estado dos pixels do recorte marcado")

  Protected CorteMirrorHIcon = GraphosScr_CreateMirrorIcon(22, #True)
  Protected G_CorteMirrorH = ButtonImageGadget(#PB_Any, RightX + 120, MiscRow2Y, 34, 30, ImageID(CorteMirrorHIcon))
  GadgetToolTip(G_CorteMirrorH, "CORTE - Espelhar horizontal (E): espelha o recorte na direcao horizontal")

  Protected CorteMirrorVIcon = GraphosScr_CreateMirrorIcon(22, #False)
  Protected G_CorteMirrorV = ButtonImageGadget(#PB_Any, RightX + 160, MiscRow2Y, 34, 30, ImageID(CorteMirrorVIcon))
  GadgetToolTip(G_CorteMirrorV, "CORTE - Espelhar vertical (R): espelha o recorte na direcao vertical")

  Protected GridIcon = GraphosScr_CreateGridIcon(22)
  Protected G_MiscGrid = ButtonImageGadget(#PB_Any, RightX, MiscRow3Y, 34, 30, ImageID(GridIcon), #PB_Button_Toggle)
  GadgetToolTip(G_MiscGrid, "GRID: mostra/esconde a malha de celulas 8x8 (so' visual, nao altera a tela)")

  Protected G_Status = TextGadget(#PB_Any, RightX, StatusY, RightW, StatusH, "")

  ; --- Persistencia no projeto (fase 5): Tela/Layout/Shape, mesmo padrao
  ; numero/navegacao/tag/Novo/Registrar do editor de sprites/alfabetos
  ; (reaproveita CharEd_CreateNavIcon/NewIcon/RegisterIcon e
  ; #CharEd_IconBtnW/H sem nenhuma mudanca) ---
  Protected Cx = CanvasX

  TextGadget(#PB_Any, Cx, ScreenBarY + 5, 45, 20, "Tela:")
  Cx + 45 + 4
  Protected G_ScreenNumberText = TextGadget(#PB_Any, Cx, ScreenBarY + 5, 40, 20, "#0")
  Cx + 40 + 10
  Protected ScreenFirstIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 0, #True)
  Protected G_ScreenFirst = ButtonImageGadget(#PB_Any, Cx, ScreenBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(ScreenFirstIcon))
  GadgetToolTip(G_ScreenFirst, "Primeira tela")
  Cx + #CharEd_IconBtnW + 2
  Protected ScreenPrevIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 0, #False)
  Protected G_ScreenPrev = ButtonImageGadget(#PB_Any, Cx, ScreenBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(ScreenPrevIcon))
  GadgetToolTip(G_ScreenPrev, "Tela anterior")
  Cx + #CharEd_IconBtnW + 2
  Protected ScreenNextIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 1, #False)
  Protected G_ScreenNext = ButtonImageGadget(#PB_Any, Cx, ScreenBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(ScreenNextIcon))
  GadgetToolTip(G_ScreenNext, "Proxima tela")
  Cx + #CharEd_IconBtnW + 2
  Protected ScreenLastIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 1, #True)
  Protected G_ScreenLast = ButtonImageGadget(#PB_Any, Cx, ScreenBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(ScreenLastIcon))
  GadgetToolTip(G_ScreenLast, "Ultima tela")
  Cx + #CharEd_IconBtnW + 16
  TextGadget(#PB_Any, Cx, ScreenBarY + 5, 32, 20, "Tag:")
  Cx + 32 + 4
  Protected G_ScreenTag = StringGadget(#PB_Any, Cx, ScreenBarY + 3, 110, 22, "")
  GadgetToolTip(G_ScreenTag, "Nome curto pra identificar a tela (ate 16 caracteres)")
  Cx + 110 + 16
  Protected NewScreenIcon = CharEd_CreateNewIcon(#CharEd_IconSize)
  Protected G_ScreenNew = ButtonImageGadget(#PB_Any, Cx, ScreenBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(NewScreenIcon))
  GadgetToolTip(G_ScreenNew, "Nova tela (numera automaticamente, limpa o canvas)")
  Cx + #CharEd_IconBtnW + 6
  Protected RegisterScreenIcon = CharEd_CreateRegisterIcon(#CharEd_IconSize)
  Protected G_ScreenRegister = ButtonImageGadget(#PB_Any, Cx, ScreenBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(RegisterScreenIcon))
  GadgetToolTip(G_ScreenRegister, "Registrar TELA: grava pixels + Tinta/Fundo da tela inteira no projeto")
  Cx + #CharEd_IconBtnW + 3
  Protected ScreenNativeIcon = GraphosScr_CreateSaveIcon(#CharEd_IconSize)
  Protected G_ScreenNative = ButtonImageGadget(#PB_Any, Cx, ScreenBarY, 28, #CharEd_IconBtnH, ImageID(ScreenNativeIcon))
  GadgetToolTip(G_ScreenNative, "Arquivo .SCR nativo do Graphos III - importar/exportar")

  Cx = CanvasX
  TextGadget(#PB_Any, Cx, LayoutBarY + 5, 45, 20, "Layout:")
  Cx + 45 + 4
  Protected G_LayoutNumberText = TextGadget(#PB_Any, Cx, LayoutBarY + 5, 40, 20, "#0")
  Cx + 40 + 10
  Protected LayoutFirstIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 0, #True)
  Protected G_LayoutFirst = ButtonImageGadget(#PB_Any, Cx, LayoutBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(LayoutFirstIcon))
  GadgetToolTip(G_LayoutFirst, "Primeiro layout")
  Cx + #CharEd_IconBtnW + 2
  Protected LayoutPrevIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 0, #False)
  Protected G_LayoutPrev = ButtonImageGadget(#PB_Any, Cx, LayoutBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(LayoutPrevIcon))
  GadgetToolTip(G_LayoutPrev, "Layout anterior")
  Cx + #CharEd_IconBtnW + 2
  Protected LayoutNextIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 1, #False)
  Protected G_LayoutNext = ButtonImageGadget(#PB_Any, Cx, LayoutBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(LayoutNextIcon))
  GadgetToolTip(G_LayoutNext, "Proximo layout")
  Cx + #CharEd_IconBtnW + 2
  Protected LayoutLastIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 1, #True)
  Protected G_LayoutLast = ButtonImageGadget(#PB_Any, Cx, LayoutBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(LayoutLastIcon))
  GadgetToolTip(G_LayoutLast, "Ultimo layout")
  Cx + #CharEd_IconBtnW + 16
  TextGadget(#PB_Any, Cx, LayoutBarY + 5, 32, 20, "Tag:")
  Cx + 32 + 4
  Protected G_LayoutTag = StringGadget(#PB_Any, Cx, LayoutBarY + 3, 110, 22, "")
  GadgetToolTip(G_LayoutTag, "Nome curto pra identificar o layout (ate 16 caracteres)")
  Cx + 110 + 16
  Protected NewLayoutIcon = CharEd_CreateNewIcon(#CharEd_IconSize)
  Protected G_LayoutNew = ButtonImageGadget(#PB_Any, Cx, LayoutBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(NewLayoutIcon))
  GadgetToolTip(G_LayoutNew, "Novo layout (numera automaticamente, limpa o canvas)")
  Cx + #CharEd_IconBtnW + 6
  Protected RegisterLayoutIcon = CharEd_CreateRegisterIcon(#CharEd_IconSize)
  Protected G_LayoutRegister = ButtonImageGadget(#PB_Any, Cx, LayoutBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(RegisterLayoutIcon))
  GadgetToolTip(G_LayoutRegister, "Registrar LAYOUT: grava so os pixels da tela (sem cor) no projeto")
  Cx + #CharEd_IconBtnW + 3
  Protected LayoutNativeIcon = GraphosScr_CreateSaveIcon(#CharEd_IconSize)
  Protected G_LayoutNative = ButtonImageGadget(#PB_Any, Cx, LayoutBarY, 28, #CharEd_IconBtnH, ImageID(LayoutNativeIcon))
  GadgetToolTip(G_LayoutNative, "Arquivo .LAY nativo do Graphos III - importar/exportar")

  Cx = CanvasX
  TextGadget(#PB_Any, Cx, ShapeBarY + 5, 45, 20, "Shape:")
  Cx + 45 + 4
  Protected G_ShapeNumberText = TextGadget(#PB_Any, Cx, ShapeBarY + 5, 40, 20, "#0")
  Cx + 40 + 10
  Protected ShapeFirstIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 0, #True)
  Protected G_ShapeFirst = ButtonImageGadget(#PB_Any, Cx, ShapeBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(ShapeFirstIcon))
  GadgetToolTip(G_ShapeFirst, "Primeiro shape")
  Cx + #CharEd_IconBtnW + 2
  Protected ShapePrevIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 0, #False)
  Protected G_ShapePrev = ButtonImageGadget(#PB_Any, Cx, ShapeBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(ShapePrevIcon))
  GadgetToolTip(G_ShapePrev, "Shape anterior")
  Cx + #CharEd_IconBtnW + 2
  Protected ShapeNextIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 1, #False)
  Protected G_ShapeNext = ButtonImageGadget(#PB_Any, Cx, ShapeBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(ShapeNextIcon))
  GadgetToolTip(G_ShapeNext, "Proximo shape")
  Cx + #CharEd_IconBtnW + 2
  Protected ShapeLastIcon = CharEd_CreateNavIcon(#CharEd_IconSize, 1, #True)
  Protected G_ShapeLast = ButtonImageGadget(#PB_Any, Cx, ShapeBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(ShapeLastIcon))
  GadgetToolTip(G_ShapeLast, "Ultimo shape")
  Cx + #CharEd_IconBtnW + 16
  TextGadget(#PB_Any, Cx, ShapeBarY + 5, 32, 20, "Tag:")
  Cx + 32 + 4
  Protected G_ShapeTag = StringGadget(#PB_Any, Cx, ShapeBarY + 3, 110, 22, "")
  GadgetToolTip(G_ShapeTag, "Nome curto pra identificar o shape (ate 16 caracteres)")
  Cx + 110 + 16
  Protected NewShapeIcon = CharEd_CreateNewIcon(#CharEd_IconSize)
  Protected G_ShapeNew = ButtonImageGadget(#PB_Any, Cx, ShapeBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(NewShapeIcon))
  GadgetToolTip(G_ShapeNew, "Novo shape (numera automaticamente, esvazia a captura)")
  Cx + #CharEd_IconBtnW + 6
  Protected RegisterShapeIcon = CharEd_CreateRegisterIcon(#CharEd_IconSize)
  Protected G_ShapeRegister = ButtonImageGadget(#PB_Any, Cx, ShapeBarY, #CharEd_IconBtnW, #CharEd_IconBtnH, ImageID(RegisterShapeIcon))
  GadgetToolTip(G_ShapeRegister, "Registrar SHAPE: grava o recorte capturado (pixels + cores) no projeto")
  Cx + #CharEd_IconBtnW + 3
  Protected ShapeNativeIcon = GraphosScr_CreateSaveIcon(#CharEd_IconSize)
  Protected G_ShapeNative = ButtonImageGadget(#PB_Any, Cx, ShapeBarY, 28, #CharEd_IconBtnH, ImageID(ShapeNativeIcon))
  GadgetToolTip(G_ShapeNative, "Arquivo .SHP nativo do Graphos III - importar/exportar")

  ; "Marcar area..." + previa numa linha PROPRIA abaixo dos 3 navegadores
  ; (pedido explicito do usuario) - na mesma linha do Shape se estendiam
  ; demais em X (ate' a previa), quase encostando na coluna direita.
  Cx = CanvasX
  Protected G_ShapeMark = ThemedButton(Cx, ShapeMarkRowY, 110, #CharEd_IconBtnH + 4, "Marcar area...", Chr(#Icon_Flag))
  GadgetToolTip(G_ShapeMark, "Marque 2 pontos no canvas (igual RETANGULO) pra capturar aquele recorte como o shape atual - clique direito cancela")
  Cx + 110 + 16
  Protected G_ShapePreview = CanvasGadget(#PB_Any, Cx, ShapeMarkRowY, #GraphosScr_ShapePrevW, #GraphosScr_ShapePrevH)
  GadgetToolTip(G_ShapePreview, "Previa do shape capturado (escalada pra caber)")

  ; --- Faixa abaixo do canvas: so o TEXTO (F2) agora, uma linha por opcao
  ; (label + campo), em vez de tudo espremido numa linha so ---
  TextGadget(#PB_Any, CanvasX, TextSectionLabelY, 300, 16, "Texto (alfabeto do projeto):")

  TextGadget(#PB_Any, CanvasX, TextAlphaRowY + 3, 70, 16, "Alfabeto:")
  Protected G_TextAlpha = ComboBoxGadget(#PB_Any, CanvasX + 75, TextAlphaRowY, 250, 22)
  GadgetToolTip(G_TextAlpha, "Alfabeto do projeto (Criar -> Alfabeto Graphos III...)")

  TextGadget(#PB_Any, CanvasX, TextStyleRowY + 3, 70, 16, "Estilo:")
  Protected G_TextStyle = ComboBoxGadget(#PB_Any, CanvasX + 75, TextStyleRowY, 250, 22)
  AddGadgetItem(G_TextStyle, -1, "NORMAL")
  AddGadgetItem(G_TextStyle, -1, "ITALIC")
  AddGadgetItem(G_TextStyle, -1, "BOLD")
  AddGadgetItem(G_TextStyle, -1, "DUPLO")
  AddGadgetItem(G_TextStyle, -1, "DUPLO BOLD")
  AddGadgetItem(G_TextStyle, -1, "LARGO")
  SetGadgetState(G_TextStyle, #GraphosTextStyle_Normal)
  GadgetToolTip(G_TextStyle, "Estilo de impressao do TEXTO")

  TextGadget(#PB_Any, CanvasX, TextStrRowY + 3, 70, 16, "Texto:")
  Protected G_TextStr = StringGadget(#PB_Any, CanvasX + 75, TextStrRowY, 350, 22, "")
  GadgetToolTip(G_TextStr, "Texto a imprimir")

  Protected G_TextPlace = ThemedButton(CanvasX, TextBtnRowY, 200, 26, "Posicionar TEXTO...", "")
  GadgetToolTip(G_TextPlace, "Arma o modo de posicionamento - mova o mouse ate o lugar certo e clique no canvas (direito cancela)")

  Protected G_Close = ThemedButton(CanvasX, CloseY, 100, 30, "Fechar", Chr(#Icon_Close))
  GadgetToolTip(G_Close, "Fechar")

  ; --- Estado ---
  Dim PatternBit.a(#Scr2_Height - 1, #Scr2_Width - 1)
  Dim RowFG.a(#Scr2_Height - 1, #Scr2_Cols - 1)
  Dim RowBG.a(#Scr2_Height - 1, #Scr2_Cols - 1)
  Scr2_ClearFramebuffer(PatternBit(), RowFG(), RowBG())

  Dim Palette.l(15)
  Dim PaletteNames.s(15)
  SpriteEd_FillPalette(Palette(), PaletteNames())

  Protected InkColor.i = #Scr2_DefaultFG
  Protected PaperColor.i = #Scr2_DefaultBG
  Protected ToolMode.i = #GraphosScrTool_Traco
  Protected PenMode.i = #GraphosPenMode_Insert
  Protected LastPaintX.i = -1, LastPaintY.i = -1

  ; Ancora das ferramentas de 2 cliques (LINHA/RETANGULO/RAIO/CIRCULO) -
  ; PendingActive marca que o 1o ponto ja foi marcado e a previa elastica
  ; deve seguir o mouse ate o 2o clique (ou o cancelamento via botao direito).
  Protected PendingActive.b = #False
  Protected AnchorX.i, AnchorY.i

  ; TEXTO (F2) - mesmo padrao de PendingActive acima, mas com o alfabeto/
  ; texto/cores/estilo congelados no momento de "Posicionar..." (pra nao
  ; mudar no meio do posicionamento se o usuario mexer nos campos).
  Protected TextPlacementActive.b = #False
  Protected TextPendingStr.s, TextPendingAlpha.i, TextPendingInk.i, TextPendingPaper.i, TextPendingStyle.i
  Dim TextPendingCharset.a(255, 7)

  ; Backups do menu TELA (fase 4) - 3 slots independentes (video/atributos/
  ; tela inteira), ver comentario grande no topo do arquivo.
  Protected VideoBackupValid.b = #False
  Dim VideoBackupPattern.a(#Scr2_Height - 1, #Scr2_Width - 1)
  Protected AttrBackupValid.b = #False
  Dim AttrBackupFG.a(#Scr2_Height - 1, #Scr2_Cols - 1)
  Dim AttrBackupBG.a(#Scr2_Height - 1, #Scr2_Cols - 1)
  Protected FullBackupValid.b = #False
  Dim FullBackupPattern.a(#Scr2_Height - 1, #Scr2_Width - 1)
  Dim FullBackupFG.a(#Scr2_Height - 1, #Scr2_Cols - 1)
  Dim FullBackupBG.a(#Scr2_Height - 1, #Scr2_Cols - 1)

  ; Persistencia no projeto (fase 5) - Tela/Layout compartilham o MESMO
  ; canvas em edicao (sao 2 formatos de salvar o mesmo framebuffer, ver
  ; comentario grande no topo do arquivo), entao compartilham CanvasDirty;
  ; Shape tem seu proprio buffer de captura (ShapeCapture*) e seu proprio
  ; ShapeDirty, independentes do canvas principal.
  Protected ScreenNumber.i = 0, ScreenTag.s = ""
  Protected LayoutNumber.i = 0, LayoutTag.s = ""
  Protected CanvasDirty.b = #False

  Protected ShapeNumber.i = 0, ShapeTag.s = "", ShapeW.i = 8, ShapeH.i = 8
  Protected ShapeDirty.b = #False
  Dim ShapeCapturePattern.a(#Scr2_Height - 1, #Scr2_Width - 1)
  Dim ShapeCaptureFG.a(#Scr2_Height - 1, #Scr2_Cols - 1)
  Dim ShapeCaptureBG.a(#Scr2_Height - 1, #Scr2_Cols - 1)
  Protected ShapeMarkPending.b = #False, ShapeMarkHasAnchor.b = #False
  Protected ShapeMarkAnchorX.i, ShapeMarkAnchorY.i

  ; Menu AJUSTE (F4, fase 6) - passo/modo sao 2 alternadores independentes,
  ; as 4 setas sao acao unica (aplicam a combinacao passo+modo atual na hora
  ; do clique, sem precisar de "Registrar").
  Protected AjusteStep8.b = #False
  Protected AjusteRotacao.b = #False

  ; Menu MISCELANEA (F5, fase 7) - GRID (overlay nao destrutivo, ver
  ; GraphosScr_DrawGridOverlay), CORTE (recorte marcado + Inverter/Espelhar,
  ; sem alinhamento de 8px - so mexe em pixel), SHAPE/carimbo (modo +
  ; posicionamento tipo TEXTO) e ZOOM (marca regiao, abre janela de edicao
  ; ampliada).
  Protected GridVisible.b = #False

  Protected CorteMarkPending.b = #False, CorteMarkHasAnchor.b = #False
  Protected CorteAnchorX.i, CorteAnchorY.i
  Protected CorteValid.b = #False
  Protected CorteX.i, CorteY.i, CorteW.i, CorteH.i

  Protected StampMode.i = #GraphosStampMode_Mascara
  Protected StampPlacementActive.b = #False

  Protected ZoomMarkPending.b = #False, ZoomMarkHasAnchor.b = #False
  Protected ZoomAnchorX.i, ZoomAnchorY.i

  GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
  GraphosScr_RedrawShapePreview(G_ShapePreview, ShapeCapturePattern(), ShapeCaptureFG(), ShapeCaptureBG(), Palette(), ShapeW, ShapeH)
  Scr2Ed_RedrawMiniPalette(G_PaletteInk, InkColor, Palette())
  Scr2Ed_RedrawMiniPalette(G_PalettePaper, PaperColor, Palette())
  SetGadgetState(G_ToolTraco, #True)
  SetGadgetState(G_Pencil, #True)
  SetGadgetState(G_AjusteStep1, #True)
  SetGadgetState(G_AjusteScroll, #True)

  ; Popula o combo de alfabetos do projeto - ProjectDB::FetchAlphabet e
  ; chamado de verdade so em G_TextPlace, ao entrar no modo de colocacao.
  ProjectDB::EnsureOpen()
  NewList TextAlphaNums.i()
  ProjectDB::ListAlphabetNumbers(TextAlphaNums())
  ForEach TextAlphaNums()
    AddGadgetItem(G_TextAlpha, -1, "#" + Str(TextAlphaNums()))
  Next
  If ListSize(TextAlphaNums()) > 0
    SetGadgetState(G_TextAlpha, 0)
  EndIf

  Protected Event, Quit = #False
  Protected MouseX, MouseY, PX, PY, Idx
  Protected DX.f, DY.f, Radius.i
  Protected BW.i, BH.i
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()

          Case G_PaletteInk
            If EventType() = #PB_EventType_LeftButtonDown
              MouseX = GetGadgetAttribute(G_PaletteInk, #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(G_PaletteInk, #PB_Canvas_MouseY)
              Idx = Scr2Ed_PaletteHitTest(MouseX, MouseY)
              If Idx >= 0
                InkColor = Idx
                Scr2Ed_RedrawMiniPalette(G_PaletteInk, InkColor, Palette())
              EndIf
            EndIf

          Case G_PalettePaper
            If EventType() = #PB_EventType_LeftButtonDown
              MouseX = GetGadgetAttribute(G_PalettePaper, #PB_Canvas_MouseX)
              MouseY = GetGadgetAttribute(G_PalettePaper, #PB_Canvas_MouseY)
              Idx = Scr2Ed_PaletteHitTest(MouseX, MouseY)
              If Idx >= 0
                PaperColor = Idx
                Scr2Ed_RedrawMiniPalette(G_PalettePaper, PaperColor, Palette())
              EndIf
            EndIf

          Case G_ToolTraco, G_ToolBloco, G_ToolLinha, G_ToolRetangulo, G_ToolRaio, G_ToolCirculo, G_ToolPintura, G_ToolSpray, G_ToolFill
            Select EventGadget()
              Case G_ToolTraco     : ToolMode = #GraphosScrTool_Traco
              Case G_ToolBloco     : ToolMode = #GraphosScrTool_Bloco
              Case G_ToolLinha     : ToolMode = #GraphosScrTool_Linha
              Case G_ToolRetangulo : ToolMode = #GraphosScrTool_Retangulo
              Case G_ToolRaio      : ToolMode = #GraphosScrTool_Raio
              Case G_ToolCirculo   : ToolMode = #GraphosScrTool_Circulo
              Case G_ToolPintura   : ToolMode = #GraphosScrTool_Pintura
              Case G_ToolSpray     : ToolMode = #GraphosScrTool_Spray
              Case G_ToolFill      : ToolMode = #GraphosScrTool_Fill
            EndSelect
            SpriteEd_UnpressOtherTools(ToolGadgets(), EventGadget())
            SetGadgetState(EventGadget(), #True)
            DisableGadget(G_Pencil, Bool(Not GraphosScr_ToolUsesPenMode(ToolMode)))
            DisableGadget(G_Eraser, Bool(Not GraphosScr_ToolUsesPenMode(ToolMode)))
            If PendingActive Or TextPlacementActive Or ShapeMarkPending Or StampPlacementActive Or CorteMarkPending Or ZoomMarkPending
              PendingActive = #False
              TextPlacementActive = #False
              ShapeMarkPending = #False
              ShapeMarkHasAnchor = #False
              StampPlacementActive = #False
              CorteMarkPending = #False
              CorteMarkHasAnchor = #False
              ZoomMarkPending = #False
              ZoomMarkHasAnchor = #False
              GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
            EndIf

          Case G_Pencil
            PenMode = #GraphosPenMode_Insert
            SpriteEd_UnpressOtherTools(PenGadgets(), G_Pencil)
            SetGadgetState(G_Pencil, #True)

          Case G_Eraser
            PenMode = #GraphosPenMode_Delete
            SpriteEd_UnpressOtherTools(PenGadgets(), G_Eraser)
            SetGadgetState(G_Eraser, #True)

          Case G_AjusteStep1
            AjusteStep8 = #False
            SpriteEd_UnpressOtherTools(AjusteStepGadgets(), G_AjusteStep1)
            SetGadgetState(G_AjusteStep1, #True)

          Case G_AjusteStep8
            AjusteStep8 = #True
            SpriteEd_UnpressOtherTools(AjusteStepGadgets(), G_AjusteStep8)
            SetGadgetState(G_AjusteStep8, #True)

          Case G_AjusteScroll
            AjusteRotacao = #False
            SpriteEd_UnpressOtherTools(AjusteWrapGadgets(), G_AjusteScroll)
            SetGadgetState(G_AjusteScroll, #True)

          Case G_AjusteRotacao
            AjusteRotacao = #True
            SpriteEd_UnpressOtherTools(AjusteWrapGadgets(), G_AjusteRotacao)
            SetGadgetState(G_AjusteRotacao, #True)

          Case G_AjusteUp, G_AjusteDown, G_AjusteLeft, G_AjusteRight
            Protected AjusteDir.i
            Select EventGadget()
              Case G_AjusteUp    : AjusteDir = 0
              Case G_AjusteDown  : AjusteDir = 1
              Case G_AjusteLeft  : AjusteDir = 2
              Case G_AjusteRight : AjusteDir = 3
            EndSelect
            If AjusteRotacao
              If AjusteStep8
                GraphosScr_RotateVideo8px(PatternBit(), RowFG(), RowBG(), AjusteDir)
              Else
                GraphosScr_RotateVideo1px(PatternBit(), AjusteDir)
              EndIf
            Else
              If AjusteStep8
                GraphosScr_ScrollVideo8px(PatternBit(), RowFG(), RowBG(), AjusteDir, InkColor, PaperColor)
              Else
                GraphosScr_ScrollVideo1px(PatternBit(), AjusteDir)
              EndIf
            EndIf
            CanvasDirty = #True
            PendingActive = #False
            TextPlacementActive = #False
            ShapeMarkPending = #False
            ShapeMarkHasAnchor = #False
            GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
            SetGadgetText(G_Status, "AJUSTE: " + GraphosScr_AjusteStatusText(AjusteStep8, AjusteRotacao, AjusteDir))

          Case G_MiscZoom
            ZoomMarkPending = #True
            ZoomMarkHasAnchor = #False
            PendingActive = #False
            TextPlacementActive = #False
            ShapeMarkPending = #False
            ShapeMarkHasAnchor = #False
            CorteMarkPending = #False
            CorteMarkHasAnchor = #False
            StampPlacementActive = #False
            SpriteEd_UnpressOtherTools(ToolGadgets(), -1)
            SetGadgetText(G_Status, "ZOOM: clique no 1o canto no canvas (direito cancela).")

          Case G_StampMascara, G_StampAnd, G_StampOr, G_StampXor
            Select EventGadget()
              Case G_StampMascara : StampMode = #GraphosStampMode_Mascara
              Case G_StampAnd     : StampMode = #GraphosStampMode_And
              Case G_StampOr      : StampMode = #GraphosStampMode_Or
              Case G_StampXor     : StampMode = #GraphosStampMode_Xor
            EndSelect
            SpriteEd_UnpressOtherTools(StampModeGadgets(), EventGadget())
            SetGadgetState(EventGadget(), #True)

          Case G_StampPlace
            PendingActive = #False
            TextPlacementActive = #False
            ShapeMarkPending = #False
            ShapeMarkHasAnchor = #False
            CorteMarkPending = #False
            CorteMarkHasAnchor = #False
            ZoomMarkPending = #False
            ZoomMarkHasAnchor = #False
            StampPlacementActive = #True
            SpriteEd_UnpressOtherTools(ToolGadgets(), -1)
            SetGadgetText(G_Status, "Carimbar shape: mova o mouse ate o lugar certo e clique no canvas (direito cancela)")

          Case G_CorteMark
            CorteMarkPending = #True
            CorteMarkHasAnchor = #False
            PendingActive = #False
            TextPlacementActive = #False
            ShapeMarkPending = #False
            ShapeMarkHasAnchor = #False
            ZoomMarkPending = #False
            ZoomMarkHasAnchor = #False
            StampPlacementActive = #False
            SpriteEd_UnpressOtherTools(ToolGadgets(), -1)
            SetGadgetText(G_Status, "CORTE: clique no vertice superior esquerdo no canvas (direito cancela).")

          Case G_CorteInvert
            If CorteValid
              GraphosScr_CorteInvert(PatternBit(), CorteX, CorteY, CorteW, CorteH)
              CanvasDirty = #True
              GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
              GraphosScr_DrawCorteOverlay(G_Canvas, CorteX, CorteY, CorteW, CorteH)
              SetGadgetText(G_Status, "CORTE: pixels invertidos.")
            Else
              SetGadgetText(G_Status, "CORTE: marque uma area primeiro (botao 'Marcar area').")
            EndIf

          Case G_CorteMirrorH
            If CorteValid
              GraphosScr_CorteMirrorH(PatternBit(), CorteX, CorteY, CorteW, CorteH)
              CanvasDirty = #True
              GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
              GraphosScr_DrawCorteOverlay(G_Canvas, CorteX, CorteY, CorteW, CorteH)
              SetGadgetText(G_Status, "CORTE: espelhado na horizontal.")
            Else
              SetGadgetText(G_Status, "CORTE: marque uma area primeiro (botao 'Marcar area').")
            EndIf

          Case G_CorteMirrorV
            If CorteValid
              GraphosScr_CorteMirrorV(PatternBit(), CorteX, CorteY, CorteW, CorteH)
              CanvasDirty = #True
              GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
              GraphosScr_DrawCorteOverlay(G_Canvas, CorteX, CorteY, CorteW, CorteH)
              SetGadgetText(G_Status, "CORTE: espelhado na vertical.")
            Else
              SetGadgetText(G_Status, "CORTE: marque uma area primeiro (botao 'Marcar area').")
            EndIf

          Case G_MiscGrid
            GridVisible = Bool(Not GridVisible)
            SetGadgetState(G_MiscGrid, GridVisible)
            GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)

          Case G_TelaLimpar
            GraphosScr_ClearWithColors(PatternBit(), RowFG(), RowBG(), InkColor, PaperColor)
            PendingActive = #False
            TextPlacementActive = #False
            CanvasDirty = #True
            GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
            SetGadgetText(G_Status, "Tela limpa (Tinta " + Str(InkColor) + ", Fundo " + Str(PaperColor) + ").")

          Case G_TelaSalva
            GraphosScr_SalvaTela(PatternBit(), RowFG(), RowBG(), FullBackupPattern(), FullBackupFG(), FullBackupBG())
            FullBackupValid = #True
            PendingActive = #False
            TextPlacementActive = #False
            SetGadgetText(G_Status, "SALVA TELA: tela guardada no buffer.")

          Case G_TelaRestaura
            PendingActive = #False
            TextPlacementActive = #False
            If FullBackupValid
              GraphosScr_RestauraTela(PatternBit(), RowFG(), RowBG(), FullBackupPattern(), FullBackupFG(), FullBackupBG())
              CanvasDirty = #True
              GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
              SetGadgetText(G_Status, "Restaurar: tela devolvida do buffer.")
            Else
              SetGadgetText(G_Status, "Restaurar: nenhuma tela guardada ainda - use SALVA TELA primeiro.")
            EndIf

          Case G_TelaInverteVideo
            GraphosScr_InvertVideo(PatternBit())
            PendingActive = #False
            TextPlacementActive = #False
            CanvasDirty = #True
            GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
            SetGadgetText(G_Status, "INVERTE VIDEO: pixels invertidos.")

          Case G_TelaInverteAtributos
            GraphosScr_InvertAttrs(RowFG(), RowBG())
            PendingActive = #False
            TextPlacementActive = #False
            CanvasDirty = #True
            GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
            SetGadgetText(G_Status, "INVERTE ATRIBUTOS: Tinta/Fundo trocados em toda a tela.")

          Case G_TelaRetiraVideo
            GraphosScr_RetiraVideo(PatternBit(), VideoBackupPattern())
            VideoBackupValid = #True
            PendingActive = #False
            TextPlacementActive = #False
            CanvasDirty = #True
            GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
            SetGadgetText(G_Status, "RETIRA VIDEO: pixels apagados (guardados pra REPOE VIDEO).")

          Case G_TelaRepoeVideo
            PendingActive = #False
            TextPlacementActive = #False
            If VideoBackupValid
              GraphosScr_RepoeVideo(PatternBit(), VideoBackupPattern())
              CanvasDirty = #True
              GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
              SetGadgetText(G_Status, "REPOE VIDEO: pixels devolvidos.")
            Else
              SetGadgetText(G_Status, "REPOE VIDEO: nada pra repor - use RETIRA VIDEO primeiro.")
            EndIf

          Case G_TelaRetiraAtributos
            GraphosScr_RetiraAtributos(RowFG(), RowBG(), AttrBackupFG(), AttrBackupBG())
            AttrBackupValid = #True
            PendingActive = #False
            TextPlacementActive = #False
            CanvasDirty = #True
            GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
            SetGadgetText(G_Status, "RETIRA ATRIBUTOS: cores removidas (guardadas pra REPOE ATRIBUTOS).")

          Case G_TelaRepoeAtributos
            PendingActive = #False
            TextPlacementActive = #False
            If AttrBackupValid
              GraphosScr_RepoeAtributos(RowFG(), RowBG(), AttrBackupFG(), AttrBackupBG())
              CanvasDirty = #True
              GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
              SetGadgetText(G_Status, "REPOE ATRIBUTOS: cores devolvidas.")
            Else
              SetGadgetText(G_Status, "REPOE ATRIBUTOS: nada pra repor - use RETIRA ATRIBUTOS primeiro.")
            EndIf

          Case G_ScreenNew
            If Not CanvasDirty Or GraphosScr_ConfirmDiscardChanges()
              NewList ScreenNav.i()
              ProjectDB::ListGraphosScreenNumbers(ScreenNav())
              Protected NextScreenNum.i = 0
              If ListSize(ScreenNav()) > 0
                LastElement(ScreenNav())
                NextScreenNum = ScreenNav() + 1
              EndIf
              ScreenNumber = NextScreenNum
              ScreenTag = ""
              Scr2_ClearFramebuffer(PatternBit(), RowFG(), RowBG())
              CanvasDirty = #False
              PendingActive = #False
              TextPlacementActive = #False
              SetGadgetText(G_ScreenNumberText, "#" + Str(ScreenNumber))
              SetGadgetText(G_ScreenTag, ScreenTag)
              GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
              SetGadgetText(G_Status, "Nova tela #" + Str(ScreenNumber) + ".")
            EndIf

          Case G_ScreenRegister
            ScreenTag = GetGadgetText(G_ScreenTag)
            ProjectDB::StoreGraphosScreen(ScreenNumber, ScreenTag, PatternBit(), RowFG(), RowBG())
            CanvasDirty = #False
            SetGadgetText(G_Status, "Tela #" + Str(ScreenNumber) + " registrada no projeto.")

          Case G_ScreenNative
            Protected PopupScr = CreatePopupMenu(#PB_Any)
            MenuItem(1, "Importar tela .SCR nativa...")
            MenuItem(2, "Exportar tela .SCR nativa...")
            DisplayPopupMenu(PopupScr, WindowID(Win))

          Case G_ScreenFirst, G_ScreenPrev, G_ScreenNext, G_ScreenLast
            NewList ScreenNav2.i()
            ProjectDB::ListGraphosScreenNumbers(ScreenNav2())
            Protected ScreenDir.i
            Select EventGadget()
              Case G_ScreenFirst : ScreenDir = 0
              Case G_ScreenPrev  : ScreenDir = 1
              Case G_ScreenNext  : ScreenDir = 2
              Case G_ScreenLast  : ScreenDir = 3
            EndSelect
            Protected ScreenTarget.i = SpriteEd_FindNavTarget(ScreenNav2(), ScreenDir, ScreenNumber)
            If ScreenTarget >= 0 And (Not CanvasDirty Or GraphosScr_ConfirmDiscardChanges())
              If ProjectDB::FetchGraphosScreen(ScreenTarget, PatternBit(), RowFG(), RowBG())
                ScreenNumber = ScreenTarget
                ScreenTag = ProjectDB::LastGraphosScreenTag()
                CanvasDirty = #False
                PendingActive = #False
                TextPlacementActive = #False
                SetGadgetText(G_ScreenNumberText, "#" + Str(ScreenNumber))
                SetGadgetText(G_ScreenTag, ScreenTag)
                GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                SetGadgetText(G_Status, "Tela #" + Str(ScreenNumber) + " carregada.")
              EndIf
            EndIf

          Case G_LayoutNew
            If Not CanvasDirty Or GraphosScr_ConfirmDiscardChanges()
              NewList LayoutNav.i()
              ProjectDB::ListGraphosLayoutNumbers(LayoutNav())
              Protected NextLayoutNum.i = 0
              If ListSize(LayoutNav()) > 0
                LastElement(LayoutNav())
                NextLayoutNum = LayoutNav() + 1
              EndIf
              LayoutNumber = NextLayoutNum
              LayoutTag = ""
              Scr2_ClearFramebuffer(PatternBit(), RowFG(), RowBG())
              CanvasDirty = #False
              PendingActive = #False
              TextPlacementActive = #False
              SetGadgetText(G_LayoutNumberText, "#" + Str(LayoutNumber))
              SetGadgetText(G_LayoutTag, LayoutTag)
              GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
              SetGadgetText(G_Status, "Novo layout #" + Str(LayoutNumber) + ".")
            EndIf

          Case G_LayoutRegister
            LayoutTag = GetGadgetText(G_LayoutTag)
            ProjectDB::StoreGraphosLayout(LayoutNumber, LayoutTag, PatternBit())
            CanvasDirty = #False
            SetGadgetText(G_Status, "Layout #" + Str(LayoutNumber) + " registrado no projeto (so pixels).")

          Case G_LayoutNative
            Protected PopupLay = CreatePopupMenu(#PB_Any)
            MenuItem(3, "Importar layout .LAY nativo...")
            MenuItem(4, "Exportar layout .LAY nativo...")
            DisplayPopupMenu(PopupLay, WindowID(Win))

          Case G_LayoutFirst, G_LayoutPrev, G_LayoutNext, G_LayoutLast
            NewList LayoutNav2.i()
            ProjectDB::ListGraphosLayoutNumbers(LayoutNav2())
            Protected LayoutDir.i
            Select EventGadget()
              Case G_LayoutFirst : LayoutDir = 0
              Case G_LayoutPrev  : LayoutDir = 1
              Case G_LayoutNext  : LayoutDir = 2
              Case G_LayoutLast  : LayoutDir = 3
            EndSelect
            Protected LayoutTarget.i = SpriteEd_FindNavTarget(LayoutNav2(), LayoutDir, LayoutNumber)
            If LayoutTarget >= 0 And (Not CanvasDirty Or GraphosScr_ConfirmDiscardChanges())
              If ProjectDB::FetchGraphosLayout(LayoutTarget, PatternBit())
                LayoutNumber = LayoutTarget
                LayoutTag = ProjectDB::LastGraphosLayoutTag()
                CanvasDirty = #False
                PendingActive = #False
                TextPlacementActive = #False
                SetGadgetText(G_LayoutNumberText, "#" + Str(LayoutNumber))
                SetGadgetText(G_LayoutTag, LayoutTag)
                GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                SetGadgetText(G_Status, "Layout #" + Str(LayoutNumber) + " carregado (so pixels - cores da tela atual mantidas).")
              EndIf
            EndIf

          Case G_ShapeNew
            If Not ShapeDirty Or GraphosScr_ConfirmDiscardChanges()
              NewList ShapeNav.i()
              ProjectDB::ListGraphosShapeNumbers(ShapeNav())
              Protected NextShapeNum.i = 0
              If ListSize(ShapeNav()) > 0
                LastElement(ShapeNav())
                NextShapeNum = ShapeNav() + 1
              EndIf
              ShapeNumber = NextShapeNum
              ShapeTag = ""
              ShapeW = 8 : ShapeH = 8
              Scr2_ClearFramebuffer(ShapeCapturePattern(), ShapeCaptureFG(), ShapeCaptureBG())
              ShapeDirty = #False
              SetGadgetText(G_ShapeNumberText, "#" + Str(ShapeNumber))
              SetGadgetText(G_ShapeTag, ShapeTag)
              GraphosScr_RedrawShapePreview(G_ShapePreview, ShapeCapturePattern(), ShapeCaptureFG(), ShapeCaptureBG(), Palette(), ShapeW, ShapeH)
              SetGadgetText(G_Status, "Novo shape #" + Str(ShapeNumber) + " - use 'Marcar area...' pra capturar do canvas.")
            EndIf

          Case G_ShapeRegister
            ShapeTag = GetGadgetText(G_ShapeTag)
            ProjectDB::StoreGraphosShape(ShapeNumber, ShapeTag, ShapeW, ShapeH, ShapeCapturePattern(), ShapeCaptureFG(), ShapeCaptureBG())
            ShapeDirty = #False
            SetGadgetText(G_Status, "Shape #" + Str(ShapeNumber) + " (" + Str(ShapeW) + "x" + Str(ShapeH) + ") registrado no projeto.")

          Case G_ShapeNative
            Protected PopupShp = CreatePopupMenu(#PB_Any)
            MenuItem(5, "Importar shape de banco .SHP nativo...")
            MenuItem(6, "Exportar shape atual como .SHP nativo...")
            DisplayPopupMenu(PopupShp, WindowID(Win))

          Case G_ShapeFirst, G_ShapePrev, G_ShapeNext, G_ShapeLast
            NewList ShapeNav2.i()
            ProjectDB::ListGraphosShapeNumbers(ShapeNav2())
            Protected ShapeDir.i
            Select EventGadget()
              Case G_ShapeFirst : ShapeDir = 0
              Case G_ShapePrev  : ShapeDir = 1
              Case G_ShapeNext  : ShapeDir = 2
              Case G_ShapeLast  : ShapeDir = 3
            EndSelect
            Protected ShapeTarget.i = SpriteEd_FindNavTarget(ShapeNav2(), ShapeDir, ShapeNumber)
            If ShapeTarget >= 0 And (Not ShapeDirty Or GraphosScr_ConfirmDiscardChanges())
              If ProjectDB::FetchGraphosShape(ShapeTarget, ShapeCapturePattern(), ShapeCaptureFG(), ShapeCaptureBG())
                ShapeNumber = ShapeTarget
                ShapeTag = ProjectDB::LastGraphosShapeTag()
                ShapeW = ProjectDB::LastGraphosShapeWidth()
                ShapeH = ProjectDB::LastGraphosShapeHeight()
                ShapeDirty = #False
                SetGadgetText(G_ShapeNumberText, "#" + Str(ShapeNumber))
                SetGadgetText(G_ShapeTag, ShapeTag)
                GraphosScr_RedrawShapePreview(G_ShapePreview, ShapeCapturePattern(), ShapeCaptureFG(), ShapeCaptureBG(), Palette(), ShapeW, ShapeH)
                SetGadgetText(G_Status, "Shape #" + Str(ShapeNumber) + " (" + Str(ShapeW) + "x" + Str(ShapeH) + ") carregado.")
              EndIf
            EndIf

          Case G_ShapeMark
            ShapeMarkPending = #True
            ShapeMarkHasAnchor = #False
            PendingActive = #False
            TextPlacementActive = #False
            SpriteEd_UnpressOtherTools(ToolGadgets(), -1)
            SetGadgetText(G_Status, "Marcar area do SHAPE: clique no 1o canto no canvas (direito cancela).")

          Case G_TextPlace
            If GetGadgetState(G_TextAlpha) < 0
              MessageRequester("Posicionar TEXTO", "Nenhum alfabeto registrado no projeto - use 'Criar -> Alfabeto Graphos III...' primeiro.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
            ElseIf Trim(GetGadgetText(G_TextStr)) = ""
              MessageRequester("Posicionar TEXTO", "Digite um texto antes de posicionar.",
                                #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
            Else
              TextPendingAlpha = Val(Mid(GetGadgetText(G_TextAlpha), 2))
              If ProjectDB::FetchAlphabet(TextPendingAlpha, TextPendingCharset())
                TextPendingStr = GetGadgetText(G_TextStr)
                TextPendingInk = InkColor
                TextPendingPaper = PaperColor
                TextPendingStyle = GetGadgetState(G_TextStyle)
                PendingActive = #False
                ShapeMarkPending = #False
                ShapeMarkHasAnchor = #False
                StampPlacementActive = #False
                CorteMarkPending = #False
                CorteMarkHasAnchor = #False
                ZoomMarkPending = #False
                ZoomMarkHasAnchor = #False
                TextPlacementActive = #True
                SpriteEd_UnpressOtherTools(ToolGadgets(), -1)
                SetGadgetText(G_Status, "TEXTO: mova o mouse ate o lugar certo e clique no canvas (direito cancela)")
              Else
                MessageRequester("Posicionar TEXTO", "Nao foi possivel carregar o alfabeto #" + Str(TextPendingAlpha) + " do projeto.",
                                  #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
              EndIf
            EndIf

          Case G_Canvas
            Select EventType()
              Case #PB_EventType_LeftButtonDown
                MouseX = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseX)
                MouseY = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseY)
                PX = MouseX / Zoom
                PY = MouseY / Zoom
                If TextPlacementActive
                  GraphosScr_BlitTextStyled(PatternBit(), RowFG(), RowBG(), TextPendingCharset(), TextPendingStr, PX, PY, TextPendingInk, TextPendingPaper, TextPendingStyle)
                  TextPlacementActive = #False
                  CanvasDirty = #True
                  GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                  SetGadgetText(G_Status, "TEXTO impresso em (" + Str(PX) + "," + Str(PY) + ")")
                ElseIf ShapeMarkPending
                  If Not ShapeMarkHasAnchor
                    ShapeMarkAnchorX = PX : ShapeMarkAnchorY = PY : ShapeMarkHasAnchor = #True
                    SetGadgetText(G_Status, "Marcar area do SHAPE: clique no canto oposto (direito cancela).")
                  Else
                    ; Snap o eixo X pro grid de 8px (mesmo alinhamento da
                    ; Color Table) - garante que cada celula de cor local do
                    ; shape corresponda a uma celula inteira da tela de
                    ; origem, sem precisar reamostrar cor nenhuma.
                    Protected SelX = ShapeMarkAnchorX, SelY = ShapeMarkAnchorY
                    Protected SelX2 = PX, SelY2 = PY
                    If SelX2 < SelX : Swap SelX, SelX2 : EndIf
                    If SelY2 < SelY : Swap SelY, SelY2 : EndIf
                    SelX = (SelX / 8) * 8
                    SelX2 = ((SelX2 / 8) + 1) * 8 - 1
                    If SelX2 >= #Scr2_Width : SelX2 = #Scr2_Width - 1 : EndIf
                    ShapeW = SelX2 - SelX + 1
                    ShapeH = SelY2 - SelY + 1
                    Protected CopyX, CopyY, CCx
                    For CopyY = 0 To ShapeH - 1
                      For CopyX = 0 To ShapeW - 1
                        ShapeCapturePattern(CopyY, CopyX) = PatternBit(SelY + CopyY, SelX + CopyX)
                      Next
                      For CCx = 0 To (ShapeW / 8) - 1
                        ShapeCaptureFG(CopyY, CCx) = RowFG(SelY + CopyY, (SelX / 8) + CCx)
                        ShapeCaptureBG(CopyY, CCx) = RowBG(SelY + CopyY, (SelX / 8) + CCx)
                      Next
                    Next
                    ShapeDirty = #True
                    ShapeMarkPending = #False
                    ShapeMarkHasAnchor = #False
                    GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                    GraphosScr_RedrawShapePreview(G_ShapePreview, ShapeCapturePattern(), ShapeCaptureFG(), ShapeCaptureBG(), Palette(), ShapeW, ShapeH)
                    SetGadgetText(G_Status, "Shape capturado (" + Str(ShapeW) + "x" + Str(ShapeH) + ") - Registrar shape pra salvar no projeto.")
                  EndIf
                ElseIf StampPlacementActive
                  Protected StampDestX = (PX / 8) * 8
                  GraphosScr_StampShape(PatternBit(), RowFG(), RowBG(), ShapeCapturePattern(), ShapeCaptureFG(), ShapeCaptureBG(), StampDestX, PY, ShapeW, ShapeH, StampMode)
                  StampPlacementActive = #False
                  CanvasDirty = #True
                  GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                  SetGadgetText(G_Status, "Shape carimbado em (" + Str(StampDestX) + "," + Str(PY) + ").")
                ElseIf CorteMarkPending
                  If Not CorteMarkHasAnchor
                    CorteAnchorX = PX : CorteAnchorY = PY : CorteMarkHasAnchor = #True
                    SetGadgetText(G_Status, "CORTE: clique no vertice inferior direito (direito cancela).")
                  Else
                    Protected CX1 = CorteAnchorX, CY1 = CorteAnchorY, CX2 = PX, CY2 = PY
                    If CX2 < CX1 : Swap CX1, CX2 : EndIf
                    If CY2 < CY1 : Swap CY1, CY2 : EndIf
                    CorteX = CX1 : CorteY = CY1
                    CorteW = CX2 - CX1 + 1 : CorteH = CY2 - CY1 + 1
                    CorteValid = #True
                    CorteMarkPending = #False
                    CorteMarkHasAnchor = #False
                    GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                    GraphosScr_DrawCorteOverlay(G_Canvas, CorteX, CorteY, CorteW, CorteH)
                    SetGadgetText(G_Status, "CORTE: area marcada (" + Str(CorteW) + "x" + Str(CorteH) + ") - use Inverter/Espelhar.")
                  EndIf
                ElseIf ZoomMarkPending
                  If Not ZoomMarkHasAnchor
                    ZoomAnchorX = PX : ZoomAnchorY = PY : ZoomMarkHasAnchor = #True
                    SetGadgetText(G_Status, "ZOOM: clique no canto oposto (direito cancela).")
                  Else
                    Protected ZX1 = ZoomAnchorX, ZY1 = ZoomAnchorY, ZX2 = PX, ZY2 = PY
                    If ZX2 < ZX1 : Swap ZX1, ZX2 : EndIf
                    If ZY2 < ZY1 : Swap ZY1, ZY2 : EndIf
                    Protected ZW = ZX2 - ZX1 + 1, ZH = ZY2 - ZY1 + 1
                    ZoomMarkPending = #False
                    ZoomMarkHasAnchor = #False
                    GraphosScr_OpenZoomWindow(Win, PatternBit(), RowFG(), RowBG(), Palette(), ZX1, ZY1, ZW, ZH, InkColor, PaperColor)
                    CanvasDirty = #True
                    GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                    SetGadgetText(G_Status, "ZOOM: edicao ampliada de (" + Str(ZW) + "x" + Str(ZH) + ") concluida.")
                  EndIf
                ElseIf PX >= 0 And PX < #Scr2_Width And PY >= 0 And PY < #Scr2_Height
                  Select ToolMode

                    Case #GraphosScrTool_Traco, #GraphosScrTool_Pintura, #GraphosScrTool_Spray
                      GraphosScr_ApplyDragTool(PatternBit(), RowFG(), RowBG(), PX, PY, ToolMode, PenMode, InkColor, PaperColor, 1, 1)
                      CanvasDirty = #True
                      GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                      LastPaintX = PX : LastPaintY = PY
                      SetGadgetText(G_Status, "Pixel (" + Str(PX) + "," + Str(PY) + ")")

                    Case #GraphosScrTool_Bloco
                      BW = GraphosScr_ClampBlockSize(Val(GetGadgetText(G_BlockW)))
                      BH = GraphosScr_ClampBlockSize(Val(GetGadgetText(G_BlockH)))
                      GraphosScr_ApplyDragTool(PatternBit(), RowFG(), RowBG(), PX, PY, ToolMode, PenMode, InkColor, PaperColor, BW, BH)
                      CanvasDirty = #True
                      GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                      LastPaintX = PX : LastPaintY = PY
                      SetGadgetText(G_Status, "Bloco " + Str(BW) + "x" + Str(BH) + " em (" + Str(PX) + "," + Str(PY) + ")")

                    Case #GraphosScrTool_Fill
                      Scr2_FloodFill(PatternBit(), RowFG(), RowBG(), PX, PY, InkColor, -1)
                      CanvasDirty = #True
                      GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                      SetGadgetText(G_Status, "FILL a partir de (" + Str(PX) + "," + Str(PY) + ")")

                    Case #GraphosScrTool_Linha
                      If Not PendingActive
                        AnchorX = PX : AnchorY = PY : PendingActive = #True
                        SetGadgetText(G_Status, "LINHA: ponto inicial marcado - clique no ponto final (direito cancela)")
                      Else
                        Scr2_DrawLine(PatternBit(), RowFG(), RowBG(), AnchorX, AnchorY, PX, PY, InkColor)
                        CanvasDirty = #True
                        GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                        AnchorX = PX : AnchorY = PY
                        SetGadgetText(G_Status, "LINHA tracada - proximo segmento comeca em (" + Str(PX) + "," + Str(PY) + ")")
                      EndIf

                    Case #GraphosScrTool_Retangulo
                      If Not PendingActive
                        AnchorX = PX : AnchorY = PY : PendingActive = #True
                        SetGadgetText(G_Status, "RETANGULO: vertice fixo marcado - clique no vertice oposto (direito cancela)")
                      Else
                        Scr2_LineStatement(PatternBit(), RowFG(), RowBG(), AnchorX, AnchorY, PX, PY, InkColor, 1)
                        CanvasDirty = #True
                        GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                        SetGadgetText(G_Status, "RETANGULO tracado - vertice fixo continua em (" + Str(AnchorX) + "," + Str(AnchorY) + ")")
                      EndIf

                    Case #GraphosScrTool_Raio
                      If Not PendingActive
                        AnchorX = PX : AnchorY = PY : PendingActive = #True
                        SetGadgetText(G_Status, "RAIO: origem fixa marcada - clique no ponto final (direito cancela)")
                      Else
                        Scr2_DrawLine(PatternBit(), RowFG(), RowBG(), AnchorX, AnchorY, PX, PY, InkColor)
                        CanvasDirty = #True
                        GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                        SetGadgetText(G_Status, "RAIO tracado - origem continua em (" + Str(AnchorX) + "," + Str(AnchorY) + ")")
                      EndIf

                    Case #GraphosScrTool_Circulo
                      If Not PendingActive
                        AnchorX = PX : AnchorY = PY : PendingActive = #True
                        SetGadgetText(G_Status, "CIRCULO: centro marcado - clique no ponto de passagem (direito cancela)")
                      Else
                        DX = PX - AnchorX : DY = PY - AnchorY
                        Radius = Scr2_RoundF(Sqr(DX * DX + DY * DY))
                        If Radius < 1 : Radius = 1 : EndIf
                        Scr2_DrawCircle(PatternBit(), RowFG(), RowBG(), AnchorX, AnchorY, Radius, InkColor, 0, 0, 0)
                        CanvasDirty = #True
                        GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                        SetGadgetText(G_Status, "CIRCULO tracado (raio " + Str(Radius) + ") - centro continua em (" + Str(AnchorX) + "," + Str(AnchorY) + ")")
                      EndIf

                  EndSelect
                EndIf

              Case #PB_EventType_RightButtonDown
                If PendingActive Or TextPlacementActive Or ShapeMarkPending Or StampPlacementActive Or CorteMarkPending Or ZoomMarkPending
                  PendingActive = #False
                  TextPlacementActive = #False
                  ShapeMarkPending = #False
                  ShapeMarkHasAnchor = #False
                  StampPlacementActive = #False
                  CorteMarkPending = #False
                  CorteMarkHasAnchor = #False
                  ZoomMarkPending = #False
                  ZoomMarkHasAnchor = #False
                  GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                  SetGadgetText(G_Status, "Operacao cancelada.")
                EndIf

              Case #PB_EventType_MouseMove
                MouseX = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseX)
                MouseY = GetGadgetAttribute(G_Canvas, #PB_Canvas_MouseY)
                PX = MouseX / Zoom
                PY = MouseY / Zoom
                If TextPlacementActive
                  GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                  GraphosScr_DrawTextPreview(G_Canvas, TextPendingCharset(), TextPendingStr, PX, PY, Palette(TextPendingInk), Palette(TextPendingPaper), TextPendingStyle)
                ElseIf ShapeMarkPending
                  If ShapeMarkHasAnchor
                    GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                    Scr2Ed_DrawLinePreview(G_Canvas, ShapeMarkAnchorX, ShapeMarkAnchorY, PX, PY, 1)
                  EndIf
                ElseIf StampPlacementActive
                  GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                  GraphosScr_DrawStampPreview(G_Canvas, ShapeCapturePattern(), ShapeCaptureFG(), ShapeCaptureBG(), Palette(), (PX / 8) * 8, PY, ShapeW, ShapeH)
                ElseIf CorteMarkPending
                  If CorteMarkHasAnchor
                    GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                    Scr2Ed_DrawLinePreview(G_Canvas, CorteAnchorX, CorteAnchorY, PX, PY, 1)
                  EndIf
                ElseIf ZoomMarkPending
                  If ZoomMarkHasAnchor
                    GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                    Scr2Ed_DrawLinePreview(G_Canvas, ZoomAnchorX, ZoomAnchorY, PX, PY, 1)
                  EndIf
                Else
                Select ToolMode
                  Case #GraphosScrTool_Traco, #GraphosScrTool_Bloco, #GraphosScrTool_Pintura, #GraphosScrTool_Spray
                    If GetGadgetAttribute(G_Canvas, #PB_Canvas_Buttons) & #PB_Canvas_LeftButton
                      If PX >= 0 And PX < #Scr2_Width And PY >= 0 And PY < #Scr2_Height And (PX <> LastPaintX Or PY <> LastPaintY)
                        If ToolMode = #GraphosScrTool_Bloco
                          BW = GraphosScr_ClampBlockSize(Val(GetGadgetText(G_BlockW)))
                          BH = GraphosScr_ClampBlockSize(Val(GetGadgetText(G_BlockH)))
                        Else
                          BW = 1 : BH = 1
                        EndIf
                        GraphosScr_ApplyDragTool(PatternBit(), RowFG(), RowBG(), PX, PY, ToolMode, PenMode, InkColor, PaperColor, BW, BH)
                        GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                        LastPaintX = PX : LastPaintY = PY
                      EndIf
                    EndIf

                  Case #GraphosScrTool_Linha, #GraphosScrTool_Raio
                    If PendingActive
                      GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                      Scr2Ed_DrawLinePreview(G_Canvas, AnchorX, AnchorY, PX, PY, 0)
                    EndIf

                  Case #GraphosScrTool_Retangulo
                    If PendingActive
                      GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                      Scr2Ed_DrawLinePreview(G_Canvas, AnchorX, AnchorY, PX, PY, 1)
                    EndIf

                  Case #GraphosScrTool_Circulo
                    If PendingActive
                      GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                      Scr2Ed_DrawCirclePreview(G_Canvas, AnchorX, AnchorY, PX, PY, #False)
                    EndIf

                EndSelect
                EndIf
            EndSelect

          Case G_Close
            If Not (CanvasDirty Or ShapeDirty) Or GraphosScr_ConfirmDiscardChanges()
              Quit = #True
            EndIf

        EndSelect

      ; Selecoes dos popups "arquivo nativo..." das 3 barras de projeto
      ; (Tela/Layout/Shape) - fase 9, ver GraphosNativeIO.pbi. IDs 1/2 =
      ; Tela import/export, 3/4 = Layout import/export, 5/6 = Shape
      ; import/export (cada popup so' usa 2 dos 6, mas todos convergem
      ; aqui porque DisplayPopupMenu entrega a selecao de forma assincrona,
      ; sem dizer de qual botao ela veio - por isso IDs distintos por bar).
      Case #PB_Event_Menu
        Select EventMenu()

          Case 1 ; Importar tela .SCR nativa
            If Not CanvasDirty Or GraphosScr_ConfirmDiscardChanges()
              Protected ScrImportPath.s = OpenFileRequester("Importar tela nativa do Graphos III (.SCR)", "", "Telas Graphos III (*.scr)|*.scr|Todos os arquivos (*.*)|*.*", 0)
              If ScrImportPath <> ""
                If GraphosNative_LoadScr(ScrImportPath, PatternBit(), RowFG(), RowBG())
                  CanvasDirty = #True
                  PendingActive = #False
                  TextPlacementActive = #False
                  GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                  SetGadgetText(G_Status, "Tela importada de " + GetFilePart(ScrImportPath) + " - Registrar pra salvar no projeto.")
                Else
                  MessageRequester("Erro", "Nao foi possivel ler o arquivo .SCR.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
                EndIf
              EndIf
            EndIf

          Case 2 ; Exportar tela .SCR nativa
            Protected ScrExportPath.s = SaveFileRequester("Exportar tela pro Graphos III (formato nativo .SCR)", ScreenTag, "Telas Graphos III (*.scr)|*.scr", 0)
            If ScrExportPath <> ""
              If LCase(Right(ScrExportPath, 4)) <> ".scr" : ScrExportPath + ".scr" : EndIf
              If GraphosNative_SaveScr(ScrExportPath, PatternBit(), RowFG(), RowBG())
                SetGadgetText(G_Status, "Tela exportada pra " + GetFilePart(ScrExportPath) + " (BLOAD" + Chr(34) + Chr(34) + ",R num MSX de verdade).")
              Else
                MessageRequester("Erro", "Nao foi possivel gravar o arquivo .SCR.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
              EndIf
            EndIf

          Case 3 ; Importar layout .LAY nativo
            If Not CanvasDirty Or GraphosScr_ConfirmDiscardChanges()
              Protected LayImportPath.s = OpenFileRequester("Importar layout nativo do Graphos III (.LAY)", "", "Layouts Graphos III (*.lay)|*.lay|Todos os arquivos (*.*)|*.*", 0)
              If LayImportPath <> ""
                If GraphosNative_LoadLay(LayImportPath, PatternBit())
                  CanvasDirty = #True
                  PendingActive = #False
                  TextPlacementActive = #False
                  GraphosScr_RedrawCanvasFull(G_Canvas, PatternBit(), RowFG(), RowBG(), Palette(), GridVisible)
                  SetGadgetText(G_Status, "Layout importado de " + GetFilePart(LayImportPath) + " (so pixels - cores da tela atual mantidas).")
                Else
                  MessageRequester("Erro", "Nao foi possivel ler o arquivo .LAY.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
                EndIf
              EndIf
            EndIf

          Case 4 ; Exportar layout .LAY nativo
            Protected LayExportPath.s = SaveFileRequester("Exportar layout pro Graphos III (formato nativo .LAY)", LayoutTag, "Layouts Graphos III (*.lay)|*.lay", 0)
            If LayExportPath <> ""
              If LCase(Right(LayExportPath, 4)) <> ".lay" : LayExportPath + ".lay" : EndIf
              If GraphosNative_SaveLay(LayExportPath, PatternBit())
                SetGadgetText(G_Status, "Layout exportado pra " + GetFilePart(LayExportPath) + ".")
              Else
                MessageRequester("Erro", "Nao foi possivel gravar o arquivo .LAY.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
              EndIf
            EndIf

          Case 5 ; Importar shape de banco .SHP nativo
            If Not ShapeDirty Or GraphosScr_ConfirmDiscardChanges()
              Protected ShpImportPath.s = OpenFileRequester("Importar shape de um banco .SHP nativo do Graphos III", "", "Bancos de shapes Graphos III (*.shp)|*.shp|Todos os arquivos (*.*)|*.*", 0)
              If ShpImportPath <> ""
                NewList ShpEntries.GraphosNative_ShpEntry()
                GraphosNative_ScanShpFile(ShpImportPath, ShpEntries())
                If ListSize(ShpEntries()) = 0
                  MessageRequester("Erro", "Nenhum shape encontrado nesse arquivo.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
                Else
                  Protected PickNumber.i = 1
                  If ListSize(ShpEntries()) > 1
                    Protected PickText.s = InputRequester("Importar shape", "Banco com " + Str(ListSize(ShpEntries())) + " shapes - numero do shape (K) a importar:", "1", 0, WindowID(Win))
                    If PickText = "" : PickText = "-1" : EndIf
                    PickNumber = Val(PickText)
                  Else
                    FirstElement(ShpEntries())
                    PickNumber = ShpEntries()\Number
                  EndIf
                  Protected ShpFound.b = #False
                  ForEach ShpEntries()
                    If ShpEntries()\Number = PickNumber
                      ShpFound = #True
                      If GraphosNative_LoadShapeAt(ShpImportPath, ShpEntries()\Offset, ShpEntries()\Type, ShpEntries()\Width, ShpEntries()\HeightTiles, ShapeCapturePattern(), ShapeCaptureFG(), ShapeCaptureBG())
                        ShapeW = ShpEntries()\Width
                        ShapeH = ShpEntries()\HeightTiles * 8
                        ShapeDirty = #True
                        GraphosScr_RedrawShapePreview(G_ShapePreview, ShapeCapturePattern(), ShapeCaptureFG(), ShapeCaptureBG(), Palette(), ShapeW, ShapeH)
                        SetGadgetText(G_Status, "Shape #" + Str(PickNumber) + " importado de " + GetFilePart(ShpImportPath) + " (" + Str(ShapeW) + "x" + Str(ShapeH) + ").")
                      Else
                        MessageRequester("Erro", "Nao foi possivel ler esse shape.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
                      EndIf
                      Break
                    EndIf
                  Next
                  If Not ShpFound
                    MessageRequester("Erro", "Shape #" + Str(PickNumber) + " nao encontrado nesse banco.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
                  EndIf
                EndIf
              EndIf
            EndIf

          Case 6 ; Exportar shape atual como .SHP nativo
            Protected ShpExportPath.s = SaveFileRequester("Exportar shape atual como banco .SHP nativo do Graphos III", ShapeTag, "Bancos de shapes Graphos III (*.shp)|*.shp", 0)
            If ShpExportPath <> ""
              If LCase(Right(ShpExportPath, 4)) <> ".shp" : ShpExportPath + ".shp" : EndIf
              Protected ShpExportHTiles.i = (ShapeH + 7) / 8
              If GraphosNative_SaveShp(ShpExportPath, ShapeW, ShpExportHTiles, ShapeCapturePattern(), ShapeCaptureFG(), ShapeCaptureBG())
                SetGadgetText(G_Status, "Shape exportado pra " + GetFilePart(ShpExportPath) + " (" + Str(ShapeW) + "x" + Str(ShpExportHTiles * 8) + ", tipo padrao+cor).")
              Else
                MessageRequester("Erro", "Nao foi possivel gravar o arquivo .SHP.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
              EndIf
            EndIf

        EndSelect

      Case #PB_Event_CloseWindow
        If Not (CanvasDirty Or ShapeDirty) Or GraphosScr_ConfirmDiscardChanges()
          Quit = #True
        EndIf

    EndSelect
  Until Quit

  CloseModelessChildWindow(ParentWindow, Win)
  FreeImage(TracoIcon)
  FreeImage(RaioIcon)
  FreeImage(PinturaIcon)
  FreeImage(SprayIcon)
  FreeImage(SalvarIcon)
  FreeImage(RestaurarIcon)
  FreeImage(InverteVideoIcon)
  FreeImage(InverteAtributosIcon)
  FreeImage(RetiraVideoIcon)
  FreeImage(RepoeVideoIcon)
  FreeImage(RetiraAtributosIcon)
  FreeImage(RepoeAtributosIcon)
  FreeImage(Step1Icon)
  FreeImage(Step8Icon)
  FreeImage(RotateModeIcon)
  FreeImage(ArrowUpIcon)
  FreeImage(ArrowDownIcon)
  FreeImage(ArrowLeftIcon)
  FreeImage(ArrowRightIcon)
  FreeImage(ZoomIcon)
  FreeImage(StampMascaraIcon)
  FreeImage(StampAndIcon)
  FreeImage(StampOrIcon)
  FreeImage(StampXorIcon)
  FreeImage(StampIcon)
  FreeImage(CorteMarkIcon)
  FreeImage(CorteInvertIcon)
  FreeImage(CorteMirrorHIcon)
  FreeImage(CorteMirrorVIcon)
  FreeImage(GridIcon)
  FreeImage(ScreenNativeIcon)
  FreeImage(LayoutNativeIcon)
  FreeImage(ShapeNativeIcon)
EndProcedure
