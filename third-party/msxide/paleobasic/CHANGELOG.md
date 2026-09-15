# Changelog

Histórico completo, sessão a sessão, de tudo que já aconteceu no desenvolvimento do Paleobasic — a
maior parte das entradas não tem codinome formal (ver [`docs/RELEASE_NOTES.md`](docs/RELEASE_NOTES.md)
para as notas de lançamento formais, com codinome, uma por versão). Para o resumo do que a IDE já faz
hoje, veja o [`README.md`](README.md). Para arquitetura/decisões técnicas de cada módulo, veja
[`docs/SPEC.md`](docs/SPEC.md).

---

- **2026-07-13** — Projeto criado; editor base migrado para repositório git com `badig/` como
  submódulo. Pré-processador Dignified e tokenizador MSX-BASIC nativos escritos em PureBasic
  (`DignifiedPreprocessor.pbi`, `MsxTokenizer.pbi`), incluindo proto-funções `FUNC`/`RET`. Primeira
  tela de configuração nativa (`BadigSettings.pbi`). Documentação de referência completa extraída do
  código-fonte Python original em `docs/reference/`.
- **2026-07-14** — Corrigido bug de charset que truncava a saída `.bmx` com caracteres especiais
  (box-drawing, acentos, gregas) em strings. Reforma visual do editor: abas customizadas em formato
  "chip", régua de colunas, tema escuro. Pré-processador nativo ganhou conversão `?`/`PRINT`, strip
  `THEN`/`GOTO`, tradução Unicode→MSX e maiusculização — agora lendo a configuração da tela de opções
  em vez de usar valores fixos.
- **2026-07-15** — Nova tela `Configurar → Editor...` (fonte, tema claro/escuro, estilo de abas,
  fontes customizadas, caminho de instalação). Diretório de instalação do Basic Dignified Suite
  configurável, com botão para baixar o toolchain direto do GitHub (`git clone` ou `.zip`). Botão de
  download de fontes Nerd Fonts direto de `nerdfonts.com` (lista ao vivo, seleção individual ou em
  lote). Script `build.ps1` para compilar via `pbcompiler.exe` (caminho configurável com `-C`/
  `--compiler`, `-R`/`--run` para executar após compilar, `-H`/`--help` para a lista de opções),
  embutindo versão (`5.1.3`) e build (data/hora UTC da compilação em hex) no executável, exibidas em
  `Ajuda → Sobre...`. Editor ganhou teclado estilo WordStar/JOE
  (`WordStarKeys.pbi` — movimento do cursor, apagar texto, bloco marcado com destaque persistente,
  salvar/abrir/fechar, desfazer/refazer; `Ctrl+S` deixou de ser "salvar" e virou "cursor para a
  esquerda", como no WordStar de verdade). Tela de ajuda embutida (`Ctrl+K H`, fecha com qualquer
  tecla) e barra de status no rodapé (modo/prefixo de comando pendente, nome do arquivo, linha e
  coluna). Novo `docs/MANUAL.md` com o guia de uso da IDE. Mais tarde no mesmo dia: `INCLUDE`
  recursivo e remtags (`##BB:...`) implementados no pré-processador nativo, fechando 100% do escopo
  do `badig.py` original — os menus e o código do caminho Python (`SaveTokenized()`,
  `BadigCfg_BuildCliArgs()`) foram removidos, o `.exe` do editor não invoca mais Python em nenhum
  fluxo.
- **2026-07-16** — Botões de busca de máquina/extensão do openMSX (aba "Emulador", listam
  `share/machines`/`share/extensions` a partir do caminho do executável configurado). Opção "Abrir o
  openMSX e rodar o código após gerar" ganhou implementação real: monta um disquete `.dsk` com o
  programa gerado mais um `AUTOEXEC.BAS` de autorun e abre o openMSX direto nele (rotinas de disco
  vendorizadas de `msxDiskUtil/MSXDisk.pbi`, compiladas no próprio executável). Menu **Arquivo → Novo
  Assembly** (`Ctrl+Shift+N`) cria abas `.asm` com syntax highlight do dialeto
  [N80/Nestor80](https://github.com/Konamiman/Nestor80) (mnemônicos, registradores, diretivas,
  literais numéricos em qualquer radix). Versão embutida no executável atualizada para `5.3.1`. Mais
  tarde no mesmo dia: `MSXDisk.pbi` ganhou uma **CLI embutida** (`--diskmanipulator`, mesma sintaxe do
  `msxdisk.exe` original) e um **gerenciador gráfico** completo (menu **Criar → Disco...**, dois
  painéis estilo Norton/Total Commander, botões Adicionar/Extrair sempre por cópia e Remover
  local/disco com confirmação, tudo sobre uma cópia de rascunho — só grava no disco escolhido em
  Salvar/Salvar como/Duplicar, Cancelar descarta sem tocar nele).
- **2026-07-18** — Novo **editor de sprites** (menu **Criar → Sprite...**, `editor/SpriteEditorGui.pbi`):
  grade 8×8/16×16, palheta MSX1 de 16 cores fixas, modos MSX1/MSX2 (uma cor por sprite vs. uma cor por
  linha, aplicados automaticamente), ferramentas com ícone (lápis, borracha, pincel, balde, reta,
  retângulo, elipse — com prévia ao vivo, marcador piscando e cancelamento por Esc/botão direito),
  rotacionar/deslocar, inverter, limpar. Junto veio um **sistema de projeto** novo
  (`editor/ProjectDB.pbi`): cada projeto MSX é um arquivo SQLite único (`.msxproject`); sem nenhum
  parâmetro na linha de comando a IDE já abre um projeto implícito `noname.msxproject` num arquivo
  temporário, com **Arquivo → Novo projeto...**/**Abrir projeto...** para trocar de projeto (oferecendo
  salvar o atual antes, se tiver conteúdo não salvo) e aviso automático ao sair perguntando onde salvar
  em definitivo. O editor de sprites já usa esse sistema: cada sprite tem número sequencial e uma tag
  (até 16 caracteres), com botões **Registrar**/**Novo**/navegação (primeiro/anterior/próximo/último)/
  **Copiar**/**Colar**. Validado com um novo harness de console (`editor/tools/ProjectDBTestCli.pb`)
  cobrindo round-trip completo dos dados (criar, salvar, listar, recarregar byte a byte, promover para
  arquivo permanente, reabrir). Nome padrão de aba sem título mudou de "Sem titulo N" para "nonameN".
  Versão embutida no executável atualizada para `5.5.3`.
- **2026-07-19** — Novos itens **Arquivo → Salvar projeto** / **Salvar projeto como...**: salvar
  reaproveita o caminho já escolhido (sem diálogo, já que o `ProjectDB` grava cada sprite na hora via
  SQLite); "salvar como" sempre pergunta um caminho novo, sugerindo o atual, permitindo salvar uma
  cópia do projeto com outro nome. `OfferSaveProject()` (usado em "Novo projeto..."/ao sair) passou a
  reaproveitar essa mesma rotina em vez de duplicar a lógica de salvar. Se o nome digitado no diálogo
  não tiver extensão, `.msxproject` é acrescentado automaticamente. O projeto SQLite ganhou duas
  novidades: uma cópia sempre atualizada do conteúdo de cada aba de texto já salva em disco (tabela
  `documents`, sincronizada a cada "Salvar"/"Salvar como" de uma aba — além do arquivo `.dmx`/`.amx`/
  `.asm`/tokenizado que já ia pro disco) e o diretório de trabalho (`working_dir`, a pasta do último
  arquivo salvo, ou o diretório corrente enquanto nada foi salvo ainda). Harness `ProjectDBTestCli`
  ganhou cobertura pra essas duas novidades, incluindo round-trip através de `SaveAs`/`OpenExisting`.
  Mais tarde no mesmo dia: novo **editor de alfabetos** (menu **Criar → Alfabeto...**,
  `editor/CharsetEditorGui.pbi`) para o formato `.ALF` do Graphos III (256 caracteres 8×8 = 2048 bytes,
  binário MSX com cabeçalho de 7 bytes carregado em `&H9200`) — tabela com os 256 caracteres (16 por
  linha, cabeçalho hex de linha/coluna), grade grande editável (clique/arrastar liga-desliga pixel),
  botão **Registrar** grava os pixels de volta no caractere e atualiza a miniatura na tabela,
  **Abrir...**/**Salvar como...** leem/gravam `.alf` (extensão automática), carrega
  `alfabetos\msx.alf` como padrão ao abrir. Ainda mais tarde no mesmo dia: **integração com o sistema de
  projeto**, igual ao editor de sprites — tabela `alphabets` no `.msxproject`, barra própria com número/
  tag/**Primeiro**/**Anterior**/**Próximo**/**Último**/**Registrar alfabeto**/**Novo alfabeto** (sempre
  parte do charset padrão do MSX, nunca em branco). Esse padrão passou a vir de um **"projeto 0"**
  interno — segundo banco SQLite, sempre `:memory:`, nunca salvo, semeado com `alfabetos\msx.alf`
  **embutido no `.exe`** (`editor/DefaultCharsetMsx.pbi`, gerado a partir do `.alf` real). Harness
  `ProjectDBTestCli` ganhou cobertura completa de alfabetos, incluindo um teste que compara os bytes
  embutidos contra o arquivo `.alf` real no disco. Versão embutida no executável atualizada para
  `5.7.3` (padrão de `build.ps1` e do fallback de compilação direta em `BadigEditor.pb`), fechando o
  dia de trabalho no editor de alfabetos e no sistema de projeto. Documentação revisada:
  `docs/MANUAL.md` ganhou a seção **Editor de alfabetos** e as novas opções de projeto (Salvar
  projeto/Salvar projeto como..., cópia das abas de texto, diretório de trabalho); a tabela de
  parâmetros do `build.ps1` no manual também foi corrigida (estava documentando nomes de flag
  desatualizados, `-Version`/`-SourceFile`/`-OutputExe`, em vez dos reais `-V`/`-i`/`-o`).

- **2026-07-21** — Editor de alfabetos: o botão genérico "Abrir..." virou **"Carregar do Graphos
  III..."** — além de deixar explícito que o botão importa um `.alf` real do Graphos III, importar
  agora sempre cria um **alfabeto novo** no projeto (numeração automática, igual a "Novo alfabeto") em
  vez de sobrescrever silenciosamente o alfabeto atualmente selecionado; depois de carregar, **Registrar
  alfabeto** grava a importação no `.msxproject`, permitindo vários alfabetos Graphos III diferentes no
  mesmo projeto. Também: **ícone do aplicativo** (`msxbasica.ico`) embutido no `.exe` via `/ICON` do
  `pbcompiler.exe` (novo passo em `build.ps1`) — aparece no Windows Explorer/propriedades do arquivo —
  e reaplicado em tempo de execução (`App_ApplyWindowIcon()`, `editor/BadigEditor.pb`, extraído do
  próprio processo via `ExtractIconEx`, sem depender do `.ico` sobreviver ao lado do `.exe`) em toda
  janela top-level do editor (principal, sprite, alfabeto, disco, configurações, download de fontes),
  cobrindo barra de título/menu de sistema, barra de tarefas e Alt+Tab. Versão embutida no executável
  atualizada para `5.7.4`.

- **2026-07-21 (mais tarde no mesmo dia)** — Editor de alfabetos ganhou clipboard e edição em lote:
  **Copiar/Colar** de um único caractere (área de transferência da sessão, funciona entre caracteres do
  mesmo alfabeto ou de alfabetos diferentes) e **Copiar alfabeto/Colar alfabeto** (os 256 caracteres de
  uma vez, para duplicar um alfabeto inteiro para outro número). Também: **Marcar início de bloco** /
  **Marcar fim de bloco** / **Limpar bloco** — marcam um intervalo de caracteres na tabela (contorno
  azul, ex.: A..Z); com um intervalo marcado, o botão **Inverter** passa a inverter todos os caracteres
  do intervalo de uma vez direto no alfabeto em memória, em vez de só o caractere selecionado (sem
  bloco marcado, "Inverter" continua afetando só o caractere atual, como antes). Verificado por
  compilação limpa, screenshot da janela (layout das novas linhas de botões sem sobreposição) e um
  teste ao vivo do fluxo de marcar bloco + inverter (confirmado via texto de status "Bloco:
  $00..$00 (1 caracteres)" e os bytes do caractere virando `&HFF` após inverter) — clique sintético no
  canvas da tabela para selecionar um caractere específico não se mostrou confiável neste ambiente de
  teste (mesma limitação já registrada para os editores de sprite/alfabeto em sessões anteriores), mas
  a lógica de marcação/inversão de bloco em si foi confirmada funcionando. Versão embutida no
  executável atualizada para `5.7.5`.

- **2026-07-21 (ainda mais tarde no mesmo dia)** — Editor de alfabetos ganhou **Copiar bloco**/**Colar
  bloco**, ao lado de "Limpar bloco": copiam/colam o **intervalo inteiro** marcado (não um caractere
  só). "Colar bloco" cola a partir do caractere selecionado na tabela e remarca o destino como o novo
  bloco, permitindo inverter na sequência sem remarcar — fluxo pedido: marcar A..Z, Copiar bloco,
  selecionar "a", Colar bloco (a..z passam a ter os desenhos de A..Z), Inverter (só a..z) — resultado:
  A..Z normal e a..z invertido, dois conjuntos prontos no mesmo alfabeto. Versão embutida no executável
  atualizada para `5.7.6`.

- **2026-07-21 (fim do dia)** — Todos os botões do editor de alfabetos viraram **ícones
  monocromáticos** desenhados em memória (34×26, cinza sobre branco, sem depender de arquivo externo —
  mesma técnica já usada no editor de sprites, `SpriteEd_CreateXxxIcon`), com dica ao passar o mouse
  explicando cada função: setas de navegação, página+"+" (Novo alfabeto), ficha (Registrar), duas
  folhas (Copiar), prancheta (Colar), pasta (Carregar do Graphos III), disquete (Salvar como),
  colchetes `[`/`]` (Marcar início/fim de bloco), colchetes riscados (Limpar bloco), grade riscada
  (Limpar caractere) e círculo meio preto/meio branco (Inverter). Vários botões de escopo diferente
  (caractere/alfabeto/bloco) reaproveitam o mesmo desenho — só a posição na janela e o tooltip mudam.
  A troca encolheu a janela de ~732px para ~606px de largura. Verificado por compilação limpa,
  screenshots (geral + recortes ampliados de cada grupo de ícones) e um clique real confirmando que os
  botões de imagem continuam disparando os mesmos eventos de antes. Versão embutida no executável
  atualizada para `5.7.7`.

- **2026-07-21 (à noite)** — Novo **editor de som PSG** (menu **Criar → Som (PSG)...**,
  `editor/PsgSynth.pbi` + `editor/PsgEditorGui.pbi`): motor de emulação do AY-3-8910/YM2149 escrito do
  zero (osciladores de tom por acumulador de fase, LFSR de ruído de 17 bits, gerador de envelope com as
  10 formas de hardware, tabela de volume logarítmica de 16 níveis), validado por harness de console
  (`editor/tools/PsgTestCli.pb` — frequência medida bate com a esperada, volume 0 é silêncio). Um "som"
  é um mini-sequenciador de passos (cada um com os 14 registradores do `SOUND` + duração em quadros),
  editável na janela com **Adicionar/Atualizar/Remover/Mover/Duplicar passo**, **Tocar**/**Parar**
  (renderiza para `.wav` temporário e toca) e geração de código (**Gerar código BASIC**/**Gerar bytes
  crus**, com **Injetar no cursor**/**Copiar**). Integrado ao sistema de projeto (tabela `psg_sounds`,
  mesma barra de projeto dos editores de sprite/alfabeto) — coberto por round-trip em
  `editor/tools/ProjectDBTestCli.pb`. Durante o desenvolvimento apareceu um bug real de corrupção de
  heap: `ReDim` no PureBasic só redimensiona a **última** dimensão de um array multi-dimensional, então
  guardar os registradores como matriz 2D (passos × registradores) quebrava ao carregar do projeto —
  corrigido serializando como array 1D achatado. Logo em seguida, teste ao vivo revelou que os campos
  numéricos (Volume, período de ruído/envelope, duração) usavam `SpinGadget` (campo com setinhas ▲▼) e o
  texto do campo nunca atualizava visualmente ao clicar nas setas (confirmado enviando a mensagem nativa
  `UDM_SETPOS32` direto no controle: o valor mudava por dentro, mas a tela continuava mostrando o número
  antigo) — substituídos por campos de texto simples, digitáveis, resolvendo tanto o "spin não funciona"
  quanto o "sem som" (volume ficava preso em 0 sem o usuário conseguir ver/confirmar o ajuste). Versão
  embutida no executável atualizada para `5.9.3`.

- **2026-07-21 (madrugada)** — Novo **editor de música MML** (menu **Criar → Música (PLAY)...**,
  `editor/MmlSynth.pbi` + `editor/MmlEditorGui.pbi`): cobre o dialeto MML do MSX-BASIC completo (notas
  A-G com sustenido/bemol, `L` duração, 8 oitavas `O`/`>`/`<`, pausa `R`, andamento `T`, volume `V`,
  nota absoluta `N`, envelope `M`/`S`, ponto de aumento `.`). O motor reaproveita quase 100% do
  `PsgSynth.pbi` do editor de som — mesmo chip, mesmo gerador de envelope compartilhado pelos 3 canais
  — só adicionando um parser MML por canal e uma mesclagem cronológica dos 3 canais independentes num
  único fluxo de registradores do PSG (chamando `PsgSynth_RenderStep()` sem alterar). UI com os 3 canais
  em paralelo, cada um com uma "linha atual" editável preenchida por botões, lista de linhas por canal
  e a mesma barra de projeto (Registrar/Novo/navegação) dos demais editores. Persistência em nova
  tabela `mml_songs` no `.msxproject`, coberta por round-trip em `ProjectDBTestCli.pb`. Validado por
  `editor/tools/MmlTestCli.pb` (frequências de nota corretas, duração/pontos batendo com a matemática
  esperada, `N` batendo com `O`+nota equivalente) e ao vivo via mensagens do Windows (nunca cursor
  real). Preencheu o módulo 8 do `docs/SPEC.md`, que estava marcado como "Gap" (sem nenhuma
  especificação registrada).

  Logo em seguida, dois ajustes pedidos depois de ver a janela funcionando: **disposição dos botões**
  compactada (notas + pausa numa fileira só; os antigos botões largos "Definir O"/"Definir L"/"Definir
  T"/"Definir V"/"Definir M"/"Definir S"/"Inserir N" viraram um ícone "+" ao lado de cada campo — a
  letra do campo já diz o comando MML; campos relacionados como N+O, L+T e M+S passaram a dividir a
  mesma fileira) — a janela encolheu de ~820px pra ~740px de altura; e os botões **Novo**/**Registrar**
  do editor de música (e também do editor de som, pra ficar uniforme) trocados de texto para os mesmos
  ícones já desenhados no editor de sprites (`SpriteEd_CreateNewSpriteIcon`/`CreateRegisterIcon`,
  reaproveitados sem duplicar nenhum desenho). Nessa checagem apareceu um bug real de
  `HasUnsavedContent()` (a função que decide se avisa "salvar antes de sair"): só contava a tabela de
  sprites, então um projeto só com alfabetos, sons ou músicas nunca disparava o aviso — risco real de
  perder esse conteúdo ao fechar sem salvar. Corrigido somando as 4 tabelas (`sprites`+`alphabets`+
  `psg_sounds`+`mml_songs`). Versão embutida no executável atualizada para `5.9.5`.
- **2026-07-23** — Novo **editor de alfabetos Aquarela** (menu **Criar → Alfabeto Aquarela...**,
  `editor/AquarelaCharsetEditorGui.pbi`): edita o formato `.FNT` de outro editor de fonte MSX
  (alternativa ao Graphos III), com engenharia reversa completa registrada em
  `docs/reference/aquarela.md`. Descoberta principal da sessão: cada registro de 32 bytes **não**
  começa no byte `N×32` do arquivo como a fórmula inicial supunha, mas 7 bytes depois — confirmado
  comparando pixel a pixel a decodificação contra uma screenshot real do Aquarela rodando num
  emulador (sem esse ajuste, cada glifo aparecia com um "floreio" desconexo no topo, na real a ponta
  final do caractere anterior vazando pro caractere seguinte). Glifo real 16×16 (2 planos de 16 bytes,
  coluna esquerda/direita), ferramenta autocontida baseada em arquivo (Novo/Abrir/Salvar/Salvar como),
  sem integração com o sistema de projeto. Tabela inicial cobria 32 caracteres (A-Z + `& ? ! "` +
  `0 1`) — ampliada depois pra **46 caracteres** (`A-Z`, `& ? ! "`, `0-9`, `. : - ( ) ,`), a ordem
  completa confirmada por teste real do usuário e por `LOGO.FNT` (fonte 8×8 completa do disco
  original do Aquarela, que lê perfeitamente até bem depois dos 46 glifos "oficiais").
- **2026-07-23 (mais tarde no mesmo dia)** — Editor de alfabetos Graphos III ganhou **11 botões de
  efeito** novos, todos seguindo o mesmo padrão dual já usado pelo "Inverter" (sem bloco marcado,
  afeta só o caractere em edição; com bloco marcado — ou o novo botão **All** — aplica direto em todo
  o intervalo, sem precisar de "Registrar" por caractere): **All** (marca o alfabeto inteiro de uma
  vez), **Desfazer**/**Refazer** (pilha de instantâneos do alfabeto inteiro, até 50 níveis, zerada ao
  trocar de alfabeto), **Espelhar horizontal**/**Espelhar vertical**, **Girar 90°** (sentido horário),
  **Apagar** (mesmo efeito de "Limpar", com o modo dual), **Estreitar** (condensa as 5 colunas da
  metade esquerda do glifo em 3, truque clássico de MSX pra caber 64 colunas de texto onde só
  caberiam 32), **Itálico** (desloca as linhas do glifo progressivamente — 2 bits nas 2 primeiras, 1
  bit nas 3 seguintes, nenhuma nas 3 últimas), **Negrito** (OR de cada linha com ela mesma deslocada 1
  bit, engrossando os traços) e **Largo** (funde as colunas 0-2 do original com as colunas 3-7 do
  original deslocado, esticando o glifo). Duas rodadas de refinamento a pedido do usuário: os efeitos
  Largo tiveram uma variante "Largo (direita)" que virou, depois de uma correção do próprio pedido,
  **Bold (esquerda)** e **Bold (direita)** (engrossam um lado específico do glifo via OR em vez de só
  deslocar); e **Largo (bold)**, literalmente `Bold(Largo(x))`, reaproveitando as duas transformações
  já existentes em vez de uma fórmula de bits nova. Ícones novos (seta circular, setas de espelhar/
  esticar, quadrado com arco de rotação, barras de itálico/negrito, retângulo pontilhado do "All")
  reaproveitam os mesmos helpers de triângulo preenchido (`CharEd_DrawFilledHTri`/`DrawFilledVTri`)
  extraídos do desenho da seta de navegação já existente.
- **2026-07-24** — Novo **editor de DRAW Screen 2** (menu **Criar → Draw Screen 2...**,
  `editor/Screen2Synth.pbi` motor + `editor/Screen2EditorGui.pbi` janela): editor gráfico WYSIWYG para
  SCREEN 2 com simulação fiel do color clash (1 par tinta/fundo por faixa de 8×1 pixels — o motor
  reproduz o comportamento real da ROM sem lógica extra de detecção). Sete ferramentas — PSET/PRESET
  (clique liga/apaga na hora), LINE (reta/caixa/caixa cheia), CIRCLE (círculo/elipse), PAINT
  (preenchimento), DRAW (interpretador completo da mini-linguagem de tartaruga do MSX-BASIC — `U D L R
  E F G H B N M C S A TA`, rotação exata em passos de 90° e arredondamento correto pra ângulos livres)
  e TEXTO (alfabetos do banco do projeto). Motor verificado por harness `editor/tools/Screen2TestCli.pb`
  (69 casos, incluindo o clash proposital de PAINT). Sessão evoluiu em fases dentro do mesmo dia: (1)
  motor + harness; (2) janela completa com os 7 painéis, paleta MSX1, lista de comandos e geração de
  código; (3) UX — clique no canvas já adiciona PSET/PRESET, gesto de 2 cliques com **linha elástica**
  para LINE/CIRCLE, mini buffers por ferramenta; (4) suporte a **STEP** (coordenadas relativas ao cursor
  gráfico, como no MSX-BASIC real) em todos os comandos que aceitam, e `LINE -(x,y)` (sem ponto inicial)
  — exigiu adicionar um "cursor gráfico" simulado (`Scr2_CursorX/Y`) que o motor atualiza depois de cada
  comando, igual ao MSX de verdade; (5) ferramenta TEXTO redesenhada de campos de coluna/linha para um
  **quadro elástico arrastável** com o texto real renderizado, movendo de 8 em 8 pixels (grid de tiles)
  ou pixel a pixel com Ctrl — como texto fora do grid não cabe em `LOCATE`/`PRINT` (que só endereça
  célula de caractere inteira), a geração de código ganhou um caminho alternativo que "queima" o glifo
  pixel a pixel via `PSET`/`PRESET` nesse caso. Bug pego e corrigido antes de qualquer build: uma
  primeira versão do resolvedor de STEP usava `*Ponteiro.Integer` com `\i` para devolver dois valores por
  ponteiro — sintaxe de dereferência inválida em PureBasic (`\campo` exige ponteiro tipado pra
  `Structure`, não tipo básico); substituída por duas funções `.i` com `ProcedureReturn`, mesmo padrão
  de out-param por `Global` já usado no resto do projeto. Versão embutida no executável atualizada para
  `7.1.1`.
- **2026-07-24 (mesmo dia, sessão seguinte)** — **Assembler Z80 nativo** (módulo 2) saiu do zero pra
  um motor completo: `editor/Z80Asm.pbi` (`DeclareModule Z80Asm`) com avaliador de expressão (RPN,
  precedência idêntica ao Nestor80/M80 — `HIGH`/`LOW`/`NOT`/operadores relacionais), parser de linha,
  tabela de opcodes Z80 inteira (documentados + `IXH`/`IXL`/`IYH`/`IYL` indocumentados comuns), driver
  de 2 passes (saída absoluta), diretivas de dados (`DB`/`DW`/`DS`/`DC`/`DZ`), condicionais
  (`IF`/`IFDEF`/`IF1`/`IF2`/etc.) e macros básicas (`MACRO`/`ENDM`/`EXITM`/`LOCAL`). Especificação de
  comportamento portada do **Nestor80** (Konamiman, assembler C# 100% compatível M80/L80) — clonado
  localmente só como referência de leitura (`nestor80/`, gitignored, mesmo tratamento de `badig/`).
  Como o `dotnet` está disponível no ambiente, o próprio `N80.exe` (Nestor80 compilado localmente)
  virou **oráculo de teste byte-a-byte** durante todo o desenvolvimento — mesma técnica já usada pro
  tokenizador nativo. Dois arquivos de regressão novos, `sample/teste_opcodes.asm` (~190 formas de instrução)
  e `sample/teste2_macros.asm` (condicionais + macro com `LOCAL`), montam **idênticos byte a byte** ao
  `N80.exe` real. Integrado ao editor via **Executar → Montar Assembly (.bin)...** (`Ctrl+F5`).
  Documentação de acompanhamento dedicada em `docs/resumo-asm.md` (decisões técnicas, bugs
  encontrados, gotchas de PureBasic — inclusive um achado real: `Structure` só atravessa fronteira de
  `Module` se declarada dentro do próprio `DeclareModule`, e não pode ser passada por valor como
  parâmetro de `Procedure`, só por ponteiro). Pedido do usuário durante a sessão: Linkstor80 (linker)
  e Libstor80 (biblioteca com linkagem estática seletiva) também entram no escopo do módulo — Fase B,
  ainda não iniciada. Versão embutida no executável atualizada para `7.3.1`.
- **2026-07-24 (mesma sessão, Fase B) — geração de `.REL` real, ponta a ponta**. Escritor de bit-stream
  genérico (`RelW_*`, formato estendido Nestor80, validado byte a byte contra um `.REL` mínimo real do
  `N80.exe`) **integrado a um driver de 2 passes relocável dedicado** (`RunOnePassRel`/
  `AssembleRelocatable`/`NeedsRelocatable`, separado do driver absoluto original — zero mudança de
  comportamento na Fase A). `ASEG`/`CSEG`/`DSEG`/`COMMON`/`PUBLIC`/`ENTRY`/`GLOBAL`/`EXTRN`/`EXT`/
  `EXTERNAL` passam a ter efeito de verdade: contador de localização por área, `PUBLIC` gera
  `EntrySymbol`/`DefineEntryPoint`, `EXTRN` referenciado de forma simples (`CALL externo`, `DW externo`)
  gera o mecanismo de "corrente" `ChainExternal` que o linker usa pra corrigir todas as referências de
  uma vez. A aritmética de expressão (`EvalPostfixExpr`) ganhou as regras reais de soma/subtração entre
  valores relocáveis do Nestor80 — groundwork que a própria Fase A já tinha deixado pronto/documentado
  pra este momento. Validado **byte a byte contra o `N80.exe` real** em 3 programas novos
  (`sample/teste4_rel_public.asm`/`teste5_rel_dseg.asm`/`teste6_rel_extrn.asm`), fixados como suíte de
  regressão self-contained (67/67 testes, sem precisar do `N80.exe` presente pra rodar). Escopo
  deliberadamente fora desta etapa (erro explícito, documentado em `docs/resumo-asm.md`): expressão
  externa composta, valor relocável truncado pra 1 byte, `.PHASE` em modo relocável, biblioteca/
  `.REQUEST` — ficam pro linker (`Z80Link.pbi`) ou pra uma próxima iteração.
- **2026-07-24 (mesma sessão, Fase B) — `editor/Z80Link.pbi`, primeiro corte do linker**: linka
  múltiplos `.REL` (sem biblioteca/`.REQUEST` ainda — isso é o próximo corte, junto de `Z80Lib.pbi`).
  Leitor de bit-stream que é literalmente o escritor `RelW_*` ao contrário, algoritmo de linkagem
  portado direto de `Linker/RelocatableFilesProcessor.cs` do Nestor80 (concatenação de `CSEG`/`DSEG`/
  `COMMON` entre módulos a partir de `0103h`, resolução `PUBLIC`↔`EXTRN` via a mesma corrente
  `ChainExternal`, agora percorrida ao contrário). Só o modo de sequenciamento padrão do LK80 ("dados
  antes de código", sem `--code`/`--data`/`--align-*`). Validado **byte a byte contra o `LK80.exe`
  real** em 3 cenários (módulo único; 2 módulos com `PUBLIC`/`EXTRN` cruzado incl. leitura de dado
  externo via `LD A,(externo)`; 2 módulos compartilhando um bloco `COMMON`) — **os 3 bateram já na
  primeira tentativa completa**, único ajuste necessário foi um bug real pego na validação do lado do
  assembler (`LD A,(externo)` não era reconhecido como referência externa *bare* por causa dos
  parênteses no texto do operando — corrigido). Suíte própria `editor/tools/Z80LinkTestCli.pb` (3/3).
- **2026-07-24 (mesma sessão, Fase B) — `.REQUEST`/biblioteca (corte 2) + `editor/Z80Lib.pbi`**:
  linkagem estática seletiva de verdade — o linker agora resolve `.REQUEST` procurando, **por
  programa** (não por arquivo de biblioteca inteiro), qual programa resolve cada símbolo externo
  pendente, com resolução transitiva (ponto fixo). `editor/Z80Lib.pbi` (novo) gerencia bibliotecas
  `.LIB`: `create`/`add`/`list`/`remove`, validado **byte a byte contra o `LB80.exe` real**. Achado
  notável durante a validação: o `LK80.exe` local tem uma limitação/bug real (só reconhece o símbolo
  público do primeiro programa de uma biblioteca multi-programa pedida via `.REQUEST` — confirmado
  com repro isolado e arquivo `.LIB` decodificado byte a byte, perfeitamente válido) — validado então
  com uma combinação de oráculo direto (onde o `LK80.exe` local funciona) e auto-consistência (onde
  não funciona: comparando contra o binário equivalente com o símbolo pedido reordenado pra ser o
  primeiro). Cadeia transitiva de 3 níveis entre programas de biblioteca também validada. Suíte
  própria: 7/7 (`editor/tools/Z80LinkTestCli.pb`, cobre linker e biblioteca).
- **2026-07-24 (mesma sessão, fechamento) — Fase B do assembler dá por encerrado o motor**: com
  `Z80Link.pbi` e `Z80Lib.pbi` prontos e validados (item anterior), a Fase B fica **motor completo** —
  geração de `.REL`, linkagem multi-módulo com `.REQUEST`/biblioteca e gerenciador de `.LIB`, tudo
  testado byte a byte contra `N80.exe`/`LK80.exe`/`LB80.exe` reais. Falta só a integração de menu no
  editor (hoje é engine + CLI de teste, `editor/tools/Z80LinkTestCli.exe`, sem opção em
  **Executar →**) — próxima etapa, ver checklist Fase B em `docs/resumo-asm.md`. Documentação
  atualizada em todos os `*.md` do projeto (`README.md`, `docs/SPEC.md` módulo 2b, `docs/MANUAL.md`
  seção "Assembler Z80"). Versão embutida no executável atualizada para `7.3.3`.

- **2026-07-25 — Integração de menu do linker/biblioteca + saída MSX-BASIC + sistema de projeto,
  fechando o módulo 2b/2c**: **Executar → Linkar (.REL) → binário...** (`editor/Z80LinkGui.pbi`) linka
  uma lista ordenada de `.REL` (Adicionar/Remover/Subir/Descer) com pasta de biblioteca opcional
  (`.REQUEST`); **Criar → Biblioteca Z80 (.LIB)...** (`editor/Z80LibGui.pbi`) cria/abre uma `.LIB`,
  lista programas com tamanho/símbolos públicos, adiciona `.REL` e remove programa — sem cópia de
  rascunho (`Z80Lib.pbi` já grava atômico no arquivo escolhido). Novo **Executar → Montar Assembly
  relocável (.REL)...** monta a aba `.asm` ativa em `.REL`, o insumo que faltava pro linker/biblioteca a
  partir do editor. A saída (montagem absoluta ou link) passa por um escolhedor comum novo
  (`editor/Z80OutputGui.pbi`): `.bin` no PC, **disco MSX (`.dsk`)** pronto pra rodar via `AUTOEXEC.BAS`
  (`BLOAD"...",R`, reaproveitando `MSXDisk.pbi`/mesmo mecanismo do `RunOnOpenMSX()`), ou **listing
  BASIC** (`Z80Gen_BasicLoader()` — `FOR`/`READ`/`POKE` + `DATA` em hexa, mesmo espírito do "Gerar bytes
  crus" do editor de som PSG). Sistema de projeto ganhou a tabela `asm_builds` (`ProjectDB.pbi`),
  metadado da última exportação por origem (caminho do `.asm`, ou a lista de `.rel` de uma sessão de
  link), coberta por round-trip em `editor/tools/ProjectDBTestCli.pb` (fora da soma de
  `HasUnsavedContent()` de propósito, mesmo motivo de `documents`). Bug real encontrado na integração:
  `Z80Link.pbi` e `Z80Asm.pbi` cada um fazia seu próprio `XIncludeFile "Z80RelFormat.pbi"` de dentro do
  respectivo `DeclareModule`, mas `XIncludeFile` deduplica por caminho de arquivo em todo o programa
  (não por `Module`) — funcionava isolado no CLI de teste (que nunca inclui `Z80Asm.pbi`), mas quebrava
  assim que os dois módulos passaram a coexistir na mesma unidade de compilação (`BadigEditor.pb`);
  corrigido com `editor/Z80RelFormatLink.pbi`, uma cópia dedicada pro `Module Z80Link` (mesmo espírito
  de "cada Module tem sua cópia" já usado pra `Z80LinkItemType`). Versão embutida no executável
  atualizada para `7.3.5`.

- **2026-07-25 (sessão seguinte) — Assembly Sub Project, "Makefile primitivo"**: novo **Criar →
  Assembly Sub Project...** (`editor/Z80SubProject.pbi` motor + `editor/Z80SubProjectGui.pbi` janela) —
  o usuário reúne vários `.asm` (cada um vira `.REL` na hora do build) mais bibliotecas referenciadas
  via `.REQUEST` numa lista **ordenada** (Adicionar/Remover/Subir/Descer), botão **Montar tudo
  (Build)...** monta tudo de uma vez e manda pro escolhedor de saída existente (`.bin`/`.com`, disco
  `.dsk` ou listing BASIC), botão **Gerar biblioteca a partir dos .ASM selecionados...** empacota um
  subconjunto (ou a lista inteira, se nada estiver marcado) numa biblioteca e oferece adicioná-la de
  volta. Registrado no `.msxproject` via nova tabela `asm_subprojects` (`ProjectDB.pbi`, `asm_files`/
  `lib_files` como TEXT unidos por `Chr(10)` na ordem escolhida, mesmo padrão de `mml_songs`) — mesma
  barra de projeto (número/tag/navegação/Novo/Registrar) dos demais editores, reaproveitando os ícones
  do editor de sprites. **Achado real**: `Z80Link::LResolveLibPath()` (motor do linker, sessão anterior)
  sempre resolve um nome de `.REQUEST` bare pra `"<nome>.rel"` — mesmo que já termine em `.lib` (vira
  `"nome.lib.rel"`, nunca encontrado) — então bibliotecas geradas por **Criar → Biblioteca Z80 (.LIB)**
  (que sugere extensão `.lib`) não funcionavam sozinhas via `.REQUEST`. Corrigido no subprojeto, não no
  gerenciador de biblioteca: `Z80SubProj_StageLibraries()` sempre copia+renomeia cada biblioteca pra
  `.rel` numa pasta de trabalho temporária antes de linkar. Suíte própria
  `editor/tools/Z80SubProjectTestCli.pb` (4/4, self-contained) monta pares de `.asm` reais de `sample/`
  DIRETO dos fontes e confere byte a byte contra os mesmos resultados já validados contra o `LK80.exe`
  real, incluindo o fluxo completo "gerar biblioteca a partir de `.asm` → resolver `.REQUEST` no build
  final" (linkagem estática seletiva confirmada de ponta a ponta). Versão embutida no executável
  atualizada para `7.3.7`.

- **2026-07-25 (sessão seguinte) — botão "Gerar .COM"**: pedido explícito do usuário — "vamos criar uma
  opção de gerar .COM, assim o assembler pode trabalhar independente do MSX BASIC". Novo botão **Gerar
  .COM (MSX-DOS, independente do BASIC)...** na janela "Saída da montagem" (`Z80Out_ExportCom()`,
  `editor/Z80OutputGui.pbi`), ao lado de "Salvar .bin no PC.../Gravar disco.../Gerar listing BASIC" —
  vale pra "Montar Assembly (.bin)...", "Linkar (.REL) → binário..." e "Assembly Sub Project → Montar
  tudo". Grava sempre sem cabeçalho (um `.COM` CP/M/MSX-DOS clássico nunca tem) e avisa, sem bloquear,
  se o endereço de montagem não for `0100h` (o MSX-DOS sempre carrega um `.COM` ali, independente do
  `ORG` do fonte). Reaproveita `Z80Out_WriteBinFile()` sem nenhuma mudança — o "binário cru" que esse
  caminho já gravava desde a sessão anterior já era um `.COM` válido, só faltava um atalho dedicado em
  vez de "Salvar .bin" + responder "Não" na pergunta de cabeçalho + digitar a extensão manualmente.
  Versão embutida no executável atualizada para `7.3.9`.

- **2026-07-25 (sessão seguinte) — Graphos III, Fase 1**: pedido explícito do usuário — replicar o
  **Graphos III** (editor de vídeo clássico do MSX, Renato Degiovani 1987, manual lido de
  `graphos/graphos.txt`), começando pela "tela que representa a SCREEN 2" antes do resto do toolset.
  Novo **Criar → Graphos III Screen 2...** (`editor/GraphosScreenGui.pbi`) — zero motor novo, reaproveita
  100% do módulo 5 (`Screen2Synth.pbi`/`Screen2EditorGui.pbi`, já validado por 69 casos de teste) pro
  canvas 256×192 com color clash idêntico ao MSX, mais os ícones/paleta MSX1 do editor de sprites
  (`SpriteEd_FillPalette`/`CreatePencilIcon`/`CreateEraserIcon`/`UnpressOtherTools`). Primeiras
  ferramentas: **TRAÇO** (Lápis liga com INK, Borracha apaga com PAPER, ambos com arrastar contínuo) e
  **LIMPA TELA**. Decisão de escopo, pedido explícito do usuário: o editor de alfabetos do Graphos III
  já existe nesta IDE (**Alfabeto Graphos III...**, módulo 4) e fica de fora — cada função do Graphos III
  original vira uma opção separada dentro de "Criar", em vez de um só editor monolítico; os antigos
  menus por tecla de função (F1-F5) viram botões/ícones. Resto do menu DESENHO, TEXTO, TELA, AJUSTE,
  MISCELÂNEA, shapes e os formatos de arquivo nativos (`.SCR`/`.LAY`/`.VTC`+`.ATC`) ficam para os
  próximos cortes — ainda sem persistência no `.msxproject`. Versão embutida no executável atualizada
  para `7.5.1`.

- **2026-07-25 (mesma sessão) — Graphos III, Fase 2**: completa o resto do menu **DESENHO (F1)** do
  Graphos III original em `editor/GraphosScreenGui.pbi` — **BLOCO** (TRAÇO com cursor Largura×Altura
  ajustável, campos de texto validados na hora do uso), **LINHA** (âncora + prévia elástica + clique
  final, ponto final vira início do próximo segmento — poligonal aberta, igual ao manual original),
  **RETÂNGULO** (vértice fixo + vértice oposto, âncora permanece fixa entre desenhos), **RAIO** (origem
  fixa + ponto final, mesma âncora fixa do RETÂNGULO), **CÍRCULO** (centro fixo + ponto de passagem,
  raio = distância entre os dois), **PINTURA** (só recolore o FUNDO sob o cursor, sem tocar no bit do
  pixel nem na cor de FRENTE — `GraphosScr_PaintBackground`, único ajuste fino que o motor ainda não
  tinha) e **SPRAY** (borrifo aleatório de pixels, `GraphosScr_ApplySpray`). Nenhuma dessas precisou de
  motor novo além de PINTURA/SPRAY — `Scr2_DrawLine`/`Scr2_LineStatement` (modo caixa)/`Scr2_DrawCircle`/
  `Scr2_FloodFill` (todos de `Screen2Synth.pbi`) e as prévias elásticas de LINHA/CÍRCULO
  (`Scr2Ed_DrawLinePreview`/`DrawCirclePreview` de `Screen2EditorGui.pbi`) já existiam prontos, usados
  sem nenhuma mudança. Fiel ao manual original: todas as ferramentas desenham com **INK**, exceto
  PINTURA (sempre **PAPER**); só **TRAÇO/BLOCO/SPRAY** respeitam o alternador **Lápis(INS)/Borracha
  (DEL)** (LINHA/RETÂNGULO/RAIO/CÍRCULO/FILL sempre desenham, nunca apagam) — o alternador fica
  desabilitado (`DisableGadget`) quando a ferramenta ativa não o usa. Botão direito do mouse cancela a
  âncora pendente de LINHA/RETÂNGULO/RAIO/CÍRCULO (equivalente ao ESC do original); trocar de ferramenta
  também cancela. Continuam de fora (próximos cortes): menu TEXTO, TELA, AJUSTE, MISCELÂNEA, shapes,
  formatos nativos `.SCR`/`.LAY`/`.VTC`+`.ATC` e persistência no `.msxproject`. Versão embutida no
  executável atualizada para `7.5.2`.

- **2026-07-25 (mesma sessão) — Graphos III, Fase 3**: implementa o menu **TEXTO (F2)** do Graphos III
  original em `editor/GraphosScreenGui.pbi` — escreve na tela com um alfabeto já registrado no projeto
  (**Criar → Alfabeto Graphos III...**, `ProjectDB::FetchAlphabet`, mesmo formato 256×8 do módulo 4), nas
  6 variações do manual: **NORMAL**, **ITALIC**, **BOLD**, **DUPLO** (dupla altura), **DUPLO BOLD**
  (dupla altura e largura) e **LARGO** (dupla largura). ITALIC/BOLD reaproveitam as mesmas transformações
  de bits já escritas pro editor de alfabetos (`CharEd_ItalicEditGrid`/`BoldEditGrid`, módulo 4c) sem
  duplicar a fórmula — a diferença é que aqui a transformação só afeta o desenho na tela, nunca o
  alfabeto salvo no banco. DUPLO/LARGO/DUPLO BOLD são duplicação geométrica de linha/coluna no
  framebuffer (`GraphosScr_TextScaleX`/`TextScaleY` resolvem as 6 combinações com um só par de loops),
  sem mexer na forma do glifo — o mesmo sentido de "dupla altura/largura" de impressora matricial que dá
  nome às opções originais. Fluxo igual ao "Posicionar → prévia elástica segue o mouse → clique fixa" já
  usado pela ferramenta TEXTO do editor "Draw Screen 2..." (módulo 5) — `GraphosScr_DrawTextPreview`
  reescreve `Scr2Ed_DrawTextPreview` original pra suportar as 6 variações, sem o grid de 8px/STEP (esse
  editor ainda não gera código BASIC, só framebuffer). Botão direito cancela o posicionamento pendente;
  trocar de ferramenta DESENHO também cancela. Versão embutida no executável atualizada para `7.5.3`.

- **2026-07-25 (mesma sessão) — Graphos III, Fase 4 (menu TELA) + reorganização de layout + alfabeto
  padrão**: três pedidos explícitos do usuário na mesma mensagem.
  - **Menu TELA (F3)** completo (exceto IMPRIME TELA, sem suporte a impressora nesta IDE):
    **SALVA TELA**/**Restaurar** (backup/restauração da tela inteira — pixels + Tinta + Fundo — num
    buffer dedicado), **INVERTE VIDEO** (inverte cada pixel sem mexer em cor), **INVERTE ATRIBUTOS**
    (troca Tinta/Fundo de toda a tela sem mexer em pixel), **RETIRA VIDEO**/**REPOE VIDEO** (apaga os
    pixels guardando-os num buffer, e devolve) e **RETIRA ATRIBUTOS**/**REPOE ATRIBUTOS** (idem só para
    as cores — a tela fica só com os pixels setados à vista, cor branco/preto padrão, até repor).
    LIMPA TELA (já existia desde a Fase 1) passou a viver nessa mesma grade de ícones. Cada par
    RETIRA/REPOE usa seu próprio slot de backup independente (vídeo/atributos/tela inteira) em vez do
    "buffer único, sempre atualizado a cada operação" do Graphos III original (isso exigiria um undo
    geral pra qualquer ação da janela — fora de escopo aqui).
  - **Reorganização de layout**: a coluna direita estava crescendo demais a cada fase (chegou a ~800px
    de altura) enquanto a área abaixo do canvas ficava vazia. BLOCO (Largura×Altura) e TEXTO
    (alfabeto/estilo/string/Posicionar) — controles de texto, mais naturais na horizontal — desceram
    pra uma faixa abaixo do canvas, ao lado do botão Fechar; as duas grades de ferramentas (DESENHO e
    a nova TELA) passaram de 3 para 5 ícones por linha, cortando uma linha de cada. Resultado: janela
    bem mais baixa e equilibrada entre canvas e coluna direita.
  - **Ícones em todo botão de ação** (pedido explícito — nada mais só-texto): **RETIRA**/**REPOE**
    (vídeo e atributos, 4 botões) compartilham um único gerador parametrizado
    (`GraphosScr_CreateRetiraRepoeIcon`, xadrez preto/branco = vídeo, laranja sólido = atributos, seta
    pra cima = retira, pra baixo = repõe) em vez de 4 ícones quase-idênticos; **SALVA TELA** ganhou um
    ícone de disquete, **Restaurar** uma seta circular de undo, **INVERTE VIDEO**/**INVERTE ATRIBUTOS**
    ícones próprios (quadrado dividido preto/branco; dois retalhos de cor com setas opostas).
  - **Alfabeto padrão automático**: `editor/BadigEditor.pb` ganhou `App_EnsureDefaultAlphabet()`,
    chamada uma vez no arranque da IDE (junto com `ProjectDB::EnsureOpen()`) — garante que o projeto
    ativo sempre tenha um alfabeto com a tag **"padrao"** (semeado do mesmo charset MSX embutido que
    "Novo alfabeto" já usa, `ProjectDB::FetchDefaultAlphabet(0, ...)`), pra este editor (menu TEXTO) e
    qualquer outro consumidor futuro sempre terem um alfabeto pronto sem passar por **Criar → Alfabeto
    Graphos III...** primeiro. Só cria um novo se nenhum dos já registrados tiver essa tag — não mexe
    em projetos que já têm um "padrao" salvo por uma sessão anterior. Versão embutida no executável
    atualizada para `7.5.4`.

- **2026-07-25 (mesma sessão) — Graphos III: ajuste fino de layout**: dois pedidos explícitos do
  usuário sobre a Fase 4. **BLOCO** (Largura×Altura) voltou pra coluna direita, logo abaixo da grade
  **Ferramenta (DESENHO)** — fica junto da ferramenta que ele configura, em vez de longe dela na faixa
  abaixo do canvas. **TEXTO** passou a ser uma linha por opção (Alfabeto, Estilo, Texto, Posicionar —
  cada um com seu próprio label + campo), em vez de tudo espremido lado a lado numa única linha.
  Versão embutida no executável atualizada para `7.5.5`.

- **2026-07-25 (mesma sessão) — Graphos III, Fase 5: persistência no projeto (Telas/Layouts/Shapes)**:
  pedido explícito do usuário — "colocar os trabalhos do Graphos no arquivo de Projeto também. Telas,
  shapes, layouts... menu similar aos outros onde o usuário pode nomear a tela/shape/layout, adicionar
  novos, registrar, avançar para o próximo, retroceder, ir para o primeiro e para o último". Três
  tabelas novas em `ProjectDB.pbi` (`graphos_screens`/`graphos_layouts`/`graphos_shapes` —
  **diferentes** da tabela `screens` já existente do editor "Draw Screen 2..." módulo 5, que guarda
  lista de comandos em vez de framebuffer), cada uma com o mesmo padrão número/navegação/tag/Novo/
  Registrar já usado pelo editor de sprites/alfabetos (reaproveita `CharEd_CreateNavIcon`/`NewIcon`/
  `RegisterIcon`/`SpriteEd_FindNavTarget` sem nenhuma mudança):
  - **TELA** e **LAYOUT** compartilham o mesmo canvas em edição e a mesma flag de "não registrado" —
    são 2 formatos de salvar o mesmo framebuffer (TELA = pixels + cores; LAYOUT = só pixels,
    equivalente ao `.LAY` original), não 2 documentos independentes. Confirmação antes de descartar
    alterações não registradas, mesmo padrão do editor de alfabetos.
  - **SHAPE** é um recorte retangular de tamanho **variável**, buffer próprio e independente do canvas
    principal — **Marcar área...** arma um modo de 2 cliques igual ao RETANGULO (mesma prévia elástica)
    que captura o recorte marcado do canvas pro buffer do shape. O eixo X da seleção é sempre alinhado
    ao grid de 8px antes de capturar, garantindo que cada célula de cor local do shape corresponda a
    uma célula inteira da tela de origem sem precisar reamostrar cor nenhuma. Uma prévia em miniatura
    (escalada pra caber numa caixa fixa) mostra o recorte capturado.
  - Pattern/Color são empacotados 1 byte por célula de 8 pixels (mesmo layout lógico da Pattern/Color
    Table de verdade do TMS9918 — INK no nibble alto, PAPER no nibble baixo), hex-codificados 2 dígitos
    por byte, mesmo padrão já usado por `StoreAlphabet`.
  - Deliberadamente fora: escolha de máscara/tipo do SHAPE (isso é CRIA SHAPES de verdade, seção 3.8 do
    manual — fica pro carimbo AND/OR/XOR de MISCELÂNEA, fase futura) e os formatos de arquivo nativos
    `.SCR`/`.LAY`/`.VTC`+`.ATC` em disco (a persistência desta fase é só no banco SQLite do projeto).
  Versão embutida no executável atualizada para `7.5.6`.

- **2026-07-25 (mesma sessão) — correção de layout: barras de Tela/Shape colidindo com a coluna
  direita**: pedido explícito do usuário — o botão "Marcar área..." e a prévia do Shape apareciam por
  cima do fim da coluna direita (grade TELA (F3)/status). Causa: a faixa abaixo do canvas (onde ficam
  as barras de projeto Tela/Layout/Shape) estava ancorada só em "fundo do canvas", mas a coluna direita
  é bem mais alta que o canvas sozinho (paleta + DESENHO + BLOCO + Modo + TELA + status) — a barra do
  Shape, que se estende bastante pra direita até a prévia, caía numa faixa Y que a coluna direita ainda
  ocupava. Corrigido ancorando a faixa abaixo do canvas no que for mais baixo entre "fundo do canvas" e
  "fundo da coluna direita". Versão embutida no executável atualizada para `7.5.7`.

- **2026-07-25 (mesma sessão) — refinamento de layout: janela alta demais + INK/PAPER lado a lado**:
  pedido explícito do usuário — a correção da `7.5.7` (ancorar a faixa abaixo do canvas no fim da coluna
  direita) resolvia a colisão mas deixava a janela ocupando quase toda a altura da tela, com muito
  espaço não aproveitado. Causa raiz real: a barra do Shape só colidia com a coluna direita porque
  **"Marcar área..." + a prévia se estendiam demais em X** (até quase encostar em `RightX`) — não porque
  a faixa abaixo do canvas precisasse ficar mais baixa. Correção definitiva: **"Marcar área..." e a
  prévia do Shape ganharam linha própria**, abaixo dos 3 navegadores (Tela/Layout/Shape) — bem mais
  estreita, nunca chega perto da coluna direita — e a faixa abaixo do canvas voltou a ficar ancorada
  logo após o fim do canvas (não mais no fim da coluna direita), subindo tudo de volta pra perto do
  canvas. Aproveitado também: **INK e PAPER lado a lado** em vez de empilhados, economizando uma faixa
  inteira (72px) de altura na coluna direita. Versão embutida no executável atualizada para `7.5.8`.

- **2026-07-25 (mesma sessão) — correção: prévia do Shape ainda sobrepondo os navegadores**: pedido
  explícito do usuário — a linha nova de "Marcar área.../prévia" (`7.5.8`) ainda encostava nos botões de
  navegação da barra do Shape logo acima. Causa: a prévia (70px de altura) estava deslocada 22px pra
  cima da sua própria linha (tentativa de centralizar com o botão, mais baixo), o que a empurrava de
  volta pra dentro da faixa Y que os ícones de navegação ainda ocupavam. Corrigido alinhando o topo da
  prévia com o topo da linha (sem deslocamento negativo) e aumentando a margem entre a barra de
  navegação do Shape e a linha de baixo. Versão embutida no executável atualizada para `7.5.9`.

- **2026-07-25 (mesma sessão) — Graphos III, Fase 6: menu AJUSTE (F4)**: pedido explícito do usuário —
  "scroll pixel a pixel nas 4 direções e scroll de 8 pixels por vez... mais duas opções de rotacionar
  pixel a pixel e 8 pixels por vez". Implementa as 4 operações do manual original em
  `editor/GraphosScreenGui.pbi`:
  - **SCROLL** (1px) — desloca só o **vídeo** (`PatternBit`), a parte que sai da tela é perdida.
  - **SCROLL 8x8** — desloca vídeo **e** atributos juntos (8 pixels/1 célula de cor), a área vazia é
    preenchida com as cores Tinta/Fundo atuais.
  - **ROTAÇÃO** (1px) — igual ao SCROLL, mas a parte que sai **reentra pelo lado oposto** (wraparound),
    sem perder nada.
  - **ROTAÇÃO 8x8** — idem, vídeo e atributos juntos, com wraparound.
  "Vídeo" vs "atributos" segue a mesma distinção já usada por INVERTE VIDEO/INVERTE ATRIBUTOS (Fase 4).
  UI: dois alternadores independentes (**passo** 1px/8px; **modo** SCROLL/ROTAÇÃO) + 4 setas de direção
  — ação única, aplicam a combinação passo+modo atual na hora do clique, sem precisar de "Registrar".
  Ícones das setas reaproveitam `CharEd_DrawFilledHTri`/`VTri` (já usados pelo editor de alfabetos, ver
  módulo 4c) em vez de desenhar triângulos do zero; o ícone do modo SCROLL reaproveita
  `CharEd_CreateNavIcon` com `WithBar=#True` (a "parede" no fim da seta já existia pra Primeiro/Último).
  Versão embutida no executável atualizada para `7.5.10`.

- **2026-07-25 (mesma sessão) — Graphos III, Fase 7: menu MISCELÂNEA (F5)**: pedido explícito do
  usuário — "Zoom, Shape, Corte, Grid". As 4 ferramentas avançadas do manual original em
  `editor/GraphosScreenGui.pbi`:
  - **GRID** — no original altera de verdade a cor de PAPER de toda a tela pra desenhar uma malha
    (destrutivo, limitação de hardware de 1987); aqui é um **overlay não destrutivo** (linhas finas
    desenhadas por cima do canvas a cada redesenho, nunca gravadas em `PatternBit`/`RowFG`/`RowBG`) —
    mais seguro e no espírito de "mostrar/esconder grade" de qualquer editor gráfico moderno. Precisou
    de um redesenho "completo" novo (`GraphosScr_RedrawCanvasFull`) que substitui as 31 chamadas
    diretas a `Scr2Ed_RedrawCanvas` espalhadas pelo arquivo — senão o overlay ficaria desatualizado a
    cada operação de desenho.
  - **CORTE** — marca um retângulo (2 cliques, sem alinhamento de 8px — só mexe em pixels, nunca em
    cor, fiel ao manual) + **Inverter**/**Espelhar horizontal**/**Espelhar vertical**, aplicados direto
    no recorte marcado. Sem o "teclas do cursor deslocam o corte" do original (arrastar uma seleção
    flutuante) — mesma simplificação já usada em TEXTO/SHAPE (clique fixa, sem arrastar-e-confirmar).
  - **SHAPE (carimbo)** — usa o shape **já carregado na barra de projeto Shape** (Fase 5), nenhuma UI de
    seleção nova. **MÁSCARA** cola pixels e cores (substitui tudo); **AND**/**OR**/**XOR** são lógica só
    no bit do pixel (fiel ao manual: "embora os atributos não sejam alterados") — os ícones dos 4 modos
    mostram 2 quadrados sobrepostos (shape/tela) com a região logicamente colorida de cada operação.
    Posicionamento no mesmo padrão "Posicionar → prévia segue o mouse → clique fixa" de TEXTO.
  - **ZOOM** — reinterpretação simplificada (o original tinha 3 quadros TELA/INK/PAPER e modos A/S/R
    por tecla) — marca uma região (2 cliques) e abre uma **janela à parte** com edição ampliada
    (Lápis/Borracha, INK/PAPER herdados da janela principal), escrevendo **direto** nos mesmos arrays
    da janela principal (arrays passados por referência no PureBasic) — fechar o Zoom só precisa de 1
    redesenho pra refletir as edições, sem nenhuma cópia/aplicação de volta.
  Versão embutida no executável atualizada para `7.5.11`.

- **2026-07-25 (mesma sessão) — Graphos III, Fase 9: formatos de arquivo nativos (.ALF/.LAY/.SCR/.SHP)**:
  pedido explícito do usuário — entender os formatos que o Graphos III de verdade grava em disco (usando
  os visualizadores Python de referência `alphabetV.py`/`layoutV.py`/`screenV.py`/`shapeV_2.py`) e permitir
  importar/exportar telas, layouts e shapes nesse formato, além da persistência já existente no projeto
  (Fase 5). Novo `editor/GraphosNativeIO.pbi`:
  - **.ALF** não precisou de nada novo (já correto em `CharsetEditorGui.pbi`).
  - **.LAY** (só padrão/pixels) — RLE restrito (só `$00`/`$FF` viram par marcador+contagem) com
    deslocamento `+$99` em todo byte gravado.
  - **.SCR** (tela completa) — cabeçalho BSAVE + uma rotina de apresentação Z80 de verdade (roda no MSX
    via `BLOAD"nome",R`) + padrão + cor em ordem real de VRAM (3 "terços" × 256 tiles de 8×8). Comparando
    várias amostras reais descobriu-se que essa rotina **varia de tamanho** entre arquivos (129 ou 121
    bytes) — por isso a importação calcula o tamanho a partir do **arquivo real em disco**, nunca do
    cabeçalho, e descarta a rotina sem interpretá-la; a exportação grava uma rotina de 129 bytes
    verificada byte a byte contra amostras reais (`GRAPHOS.SCR`/`STARWARS.SCR`).
  - **.SHP** (banco de shapes) — blocos `[número][tipo][largura][altura em tiles][dados]` terminados por
    `$FF`; importação lê qualquer um dos 4 tipos (máscara é lida e descartada, ainda sem uso nesta IDE);
    exportação sempre grava tipo padrão+cor, um shape por banco.
  - **UI**: 1 botão por barra de projeto (Tela/Layout/Shape — ícone de disquete, sem espaço pra 2 ícones
    separados) abre um menu popup **Importar.../Exportar...** (`CreatePopupMenu`/`DisplayPopupMenu`,
    seleção tratada de forma assíncrona via `#PB_Event_Menu`).
  - Verificado com um novo harness `editor/tools/GraphosNativeIOTestCli.pb`: round-trip completo
    (importa arquivo real → exporta → reimporta → compara bit a bit) contra amostras já presentes no
    repositório, 24/24 checks OK. Cross-validado independentemente com um decodificador Python ad-hoc.
  Versão embutida no executável atualizada para `7.5.12`.

- **2026-07-25 (mesma sessão) — correção: abas "noname" sem extensão**: pedido explícito do usuário —
  as abas de documento novo apareciam como `noname1`/`noname2`/... sem nenhuma extensão. Passaram a
  mostrar a extensão real do modo (`noname1.dmx`, `noname2.dmx`, ... ou `.asm` pra Assembly — `.dmx` e
  não `.bas` pra bater com o que **Salvar** de fato grava, formato Dignified já documentado no módulo 3).
  `editor/BadigEditor.pb`: `Docs()\UntitledName` passou a incluir a extensão (`AddDocumentTab`); a
  sugestão de "Salvar como" (`SaveDocument`) parou de concatenar a extensão de novo em cima (evitava
  duplicar, ex.: `noname1.dmx.dmx`) — os outros 6 pontos que sugerem nome pra exportação (ASCII/
  tokenizado/objeto relocável/etc.) já extraiam o nome base antes de anexar sua própria extensão, então
  não precisaram de nenhuma mudança.

- **2026-07-25 (mesma sessão) — `build.ps1 -D`/`--distribute`**: novo modo que, depois de compilar com
  sucesso, monta o pacote de distribuição na pasta `distribute\` (executável final, `README.md`,
  `docs\MANUAL.md`, `LICENSE`, pasta `sample\`, `msxbasica.ico`, `msxbasica.png`) — primeiro passo em
  direção a empacotar o editor pra usuários finais sem depender do repositório inteiro.
- **2026-07-27 — Suporte a NestorBASIC + sistema de Ajuda MSX BASIC (dicionário + manual, MSX1 e
  MSX2+)**: sessão que fechou duas frentes em paralelo.
  - **NestorBASIC**: `editor/NestorBasicSupport.pbi` (template com loader `BLOAD"NBASIC.BIN",R` +
    biblioteca de 87 wrappers `.NB_*`, três tiers), `editor/NestorBasicHelpData.pbi`/
    `NestorBasicHelpGui.pbi` (janela de ajuda navegável/pesquisável não-modal, exporta também para
    `docs/reference/nestorbasic.md`). Novos itens de menu: **Arquivo → Novo Nestor Basic...**,
    **Executar → Nestor Basic** (copia `NBASIC.BIN`/`NBASIC.DAT` de `res/` pro disco gerado) e
    **Ajuda → Nestor Basic...**. Ver seção "O que já temos" acima para o detalhe completo.
  - **Ajuda → MSX BASIC...**: novo `editor/MsxBasicHelpGui.pbi`, reaproveitando a mesma infraestrutura de
    renderização/navegação/busca já escrita para a ajuda do NestorBASIC. Duas bases de dados: **MSX1**
    (`editor/MsxBasicDictData.pbi` — 141 palavras reservadas; `editor/MsxBasicManualData.pbi` — prosa/
    tabelas do livro *"Linguagem BASIC MSX"*, Ed. Aleph/Gradiente) e **MSX 2+** (`editor/
    MsxBasic2PlusDictData.pbi` — 45 verbetes extras/estendidos; `editor/MsxBasic2PlusManualData.pbi` — 7
    tópicos de prosa/apêndices do manual ACVS FM, digitalizado em `docs/manual_msx2fm_acvs.pdf`), mais a
    página especial "Cores do MSX". Os verbetes MSX2+ entram na mesma lista única do dicionário MSX1
    (não uma seção separada), diferenciados por um campo `Sistema` e, quando é o mesmo comando com
    comportamento estendido, por um segundo verbete `"NOME (MSX2+)"` logo depois do original.
  - Nenhuma das duas frentes teve bump de versão dedicado nesta sessão — o executável commitado junto
    permanece na `7.5.12` já usada desde a Fase 9 do Graphos III.
- **2026-07-28 — Auditoria de dependências externas + remoção de `msxDiskUtil/`**: pedido explícito do
  usuário, em duas partes.
  - Confirmado por auditoria dedicada que `badig/` **não é mais necessário** para o editor funcionar —
    todos os fluxos de menu passam só pelo pipeline nativo (`DignifiedPreprocessor.pbi`/
    `MsxTokenizer.pbi`), sem nenhum caminho residual chamando Python. O botão **Configurar → Basic
    Dignified... → Baixar Basic Dignified Suite...** (já existente, aponta para
    `github.com/farique1/basic-dignified.git`) ganhou uma nota deixando explícito que é **opcional**
    (`editor/BadigSettings.pbi`) — só necessário pra quem quiser rodar o Basic Dignified Suite original
    em Python separadamente.
  - Confirmado que `msxDiskUtil/` também não é mais necessário — `editor/MSXDisk.pbi` é 100%
    self-contained. Antes de remover, um bugfix que só existia na cópia vendorizada (`MatchesFAT11`
    comparando por `Mid()`/`Asc()` em vez de byte cru, quebrando casamento por curinga tipo
    `extract *.BAS` sob Unicode) foi portado de volta pro `msxDiskUtil/MSXDisk.pbi` original, pra não
    perder a correção — só então o diretório foi removido do repositório.
- **2026-07-28 (mesma sessão) — novo Ajuda → Basic Dignified...**: pedido explícito do usuário —
  transformar a documentação completa do Basic Dignified Suite original
  (`basic-dignified/documentation/*.md`, baixada pelo botão de download da tela de configuração) numa
  janela de ajuda navegável dentro do próprio editor, cobrindo tanto a sintaxe do dialeto quanto as
  configurações desta IDE. Novo `editor/BasicDignifiedHelpData.pbi` (21 tópicos em 4 grupos: Sintaxe
  Dignified, Configurações, Remtags, Sobre a suíte original) + `editor/BasicDignifiedHelpGui.pbi`
  (janela não-modal, reaproveitando a mesma infraestrutura de árvore/busca/histórico/renderização
  Markdown mínima já usada por Ajuda → Nestor Basic/MSX BASIC). Cada tópico de configuração foi
  cruzado com o código real (`Dig_SyncConfigFromBadigCfg()`, `RunOnOpenMSX()`, `MsxTokenizer.pbi`) pra
  dizer explicitamente quais campos da tela `Configurar → Basic Dignified...` afetam a conversão hoje
  e quais são vestigiais (sem consumidor no pipeline nativo). Ver a seção "O que já temos" acima.
- **2026-07-28 (mesma sessão) — bump de versão para `7.5.13`**: pedido explícito do usuário, fechando
  a lacuna deixada pela sessão anterior (Nestor BASIC + Ajuda MSX BASIC/MSX2+ + `Ajuda → Basic
  Dignified...`, que não tinham bump dedicado — ficaram todos na `7.5.12` da Fase 9 do Graphos III).
  `build.ps1` (`$Version`) e `#App_Version` (`editor/BadigEditor.pb`) atualizados juntos.
- **2026-07-29 — novo Editor Hexa** (`editor/HexEditorGui.pbi`, menu **Executar → Editor Hexa...**):
  pedido explícito do usuário — editor hexadecimal genérico (offset/hex/ASCII, edição byte a byte) que
  reconhece os formatos binários que a própria IDE produz/consome (BLOAD/BSAVE `FEh`, tokenizado
  `FFh`, boot sector FAT12 de `.dsk`) e traz uma galeria de templates persistida em JSON (semeada com
  Alfabeto/Layout/Tela do Graphos III) pra dar nome amigável a binários reconhecidos. Duas rodadas de
  ajuste pedidas na mesma sessão: (1) correção de um campo de status que sobrepunha o botão "Fechar",
  máscara de largura fixa nos valores hex (`Hex(v,#PB_Byte)` não completa com zero à esquerda neste
  PureBasic — `HexEd_Hex2`/`Hex4`/`Hex6` resolvem isso com `RSet`) e cursor de seleção com borda de
  destaque; (2) barra de rolagem vertical customizada (o `ScrollBarGadget` nativo renderizava enorme e
  com os botões trocados — substituído por setas topo/base tradicionais + barra visual de posição
  proporcional) e operações de bloco completas: **Marcar início/fim**, **Preencher...**, **Inserir
  bloco...** (desloca)/**Sobrepor bloco...** (não desloca, ambos a partir de outro arquivo ou bytes em
  branco) e **Excluir bloco...** (deslocando ou zerando o intervalo).
- **2026-07-29 (mesma sessão) — bump de versão para `7.7.1`, codinome "`BFG9200`"**: pedido explícito
  do usuário, fechando o Editor Hexa (item acima). `build.ps1` (`$Version`) e `#App_Version`
  (`editor/BadigEditor.pb`) atualizados juntos. O codinome também foi pedido explicitamente pelo
  usuário — MSX + Doom + heavy metal: "BFG9200" cruza o BFG9000 (a arma mais brutal do Doom) com o
  `9200h`, o endereço de VRAM que virou praticamente a assinatura desta sessão (base de carga do
  Alfabeto/Layout/Tela do Graphos III, ver galeria de templates do Editor Hexa acima).
- **2026-07-29 (mesma sessão) — controle remoto do openMSX, ⚠ EXPERIMENTAL**: novo menu **Executar →
  openMSX...** (`editor/OpenMSXBridge.pbi`/`OpenMSXConsoleGui.pbi`) abre uma instância do openMSX
  separada do fluxo normal (**Executar → BASIC**/**Nestor Basic** continuam intocados) com uma janela
  de console — campo de comando, log de respostas, botões Reset/Pausar/Continuar/Ligar/Desligar,
  "Mostrar janela" (restaura a janela visível do emulador) e "Ajuda" (abre a Ajuda → openMSX ao lado).
  Primeira tentativa (`-control stdio` + escrita no stdin do processo, seguindo a doc oficial do
  openMSX à risca) não funcionou — nenhum comando surtia efeito. Investigando o código-fonte de
  verdade (openMSX + Catapult, a pedido do usuário) descobriu-se que o Catapult oficial **nunca usa
  `-control stdio` no Windows**: usa um named pipe dedicado (`-control pipe:<nome>`) só para comandos
  de entrada, mantendo stdout/stderr normais só para respostas — arquitetura reescrita para espelhar
  exatamente isso. Ainda não validado ponta a ponta contra o openMSX de verdade pelo autor (sem
  binário disponível no ambiente onde a correção foi escrita) — por isso o rótulo experimental.
  Detalhes completos em `docs/SPEC.md`, módulo 12.
- **2026-07-29 (mesma sessão) — Ajuda → openMSX...**: nova janela de referência (mesma UI de
  busca/árvore/histórico das outras 3 janelas de Ajuda) com os 5 manuais originais do openMSX (Setup
  Guide, User's Manual, Using Diskmanipulator, Controlling openMSX from External Applications,
  Console Command Reference), convertidos para o mini-Markdown interno da IDE — mais de 250 tópicos.
  Também gera `docs/reference/openmsx.md` (`OMSXHelp_ExportMarkdown()`,
  `editor/tools/OpenMsxHelpExportCli.pb`), mesma ideia do NestorBASIC. Diferente do item acima, este
  recurso é só consulta de texto (não depende do controle remoto funcionar) e não é experimental.
- **2026-07-30 — controle remoto do openMSX validado ao vivo**: novo harness
  `editor/tools/OpenMsxBridgeTestCli.pb` (mesmo padrão dos outros `*TestCli.pb`) sobe `OpenMSXBridge.pbi`
  isolado contra um openMSX 21.0 real (`C:\msx\openMSX\openmsx.exe`) sem precisar da GUI do editor. Pipe
  conecta (~300ms), o boot (`unset renderer`/`set power on`) funciona e comandos manuais recebem replies
  reais (`set power off`/`on` → `false`/`true`, `openmsx_info platform` → `mingw32`). No caminho, uma
  primeira rodada de teste (chamada direto de um terminal, sem `FreeConsole_()`) deu 0 bytes de saída
  capturada em tudo — parecia um bug sério no módulo, mas a causa raiz era outra: `main.cc` do openMSX
  (`EnableConsoleOutput()`) faz `AttachConsole(ATTACH_PARENT_PROCESS)` + `freopen("CONOUT$", ...)` em
  `stdout`/`stderr` sempre que o processo que o lança tem um console de verdade anexado, o que **rouba** a
  saída do pipe que `RunProgram(...#PB_Program_Read|Error)` preparou. O `BadigEditor.exe` real nunca bate
  nesse caso (já chama `FreeConsole_()` antes de qualquer janela abrir/chamar `OMSX_Start()`), mas o
  harness de teste precisou do mesmo `FreeConsole_()` pra reproduzir o estado certo — registrado em
  detalhe no comentário de topo do harness e em `docs/SPEC.md`, módulo 12, pra ninguém cair na mesma
  pegadinha ao investigar de novo. Rótulo "experimental" removido do menu/documentação.
- **2026-07-30 (mesma sessão) — indicador de estado, "Inserir no openMSX" e dois bugs reais
  corrigidos**: a pedido do usuário, ao vivo com um openMSX de verdade aberto:
  - **Indicador "Ligado/Desligado | Rodando/Pausado"** no topo da janela do console
    (`OMSX_StatusText()`, `editor/OpenMSXBridge.pbi`). Assina `openmsx_update enable setting` no boot
    (`GlobalCommandController.cc`) pra receber `<update type="setting" name="power|pause">valor</update>`
    de qualquer mudança de estado, não só a resposta do comando que a própria janela mandou.
  - **Bug real relatado pelo usuário**: digitar `set pause on`/`set renderer` e clicar "Enviar" não
    mostrava feedback nenhum, e nenhum comando seguinte parecia funcionar. Isolado por teste direto do
    protocolo (`OpenMSXBridge.pbi` sozinho, sem GUI): o pipe/openMSX continuavam respondendo
    perfeitamente — o bug era só na janela. Causa: `OMSXGui_AppendLog()` fazia `GetGadgetText()`
    (releitura completa do log) + `SetGadgetText()` (regravação completa) a cada tick do timer (150ms);
    em algum momento essa releitura passava a devolver vazio, e a próxima gravação então "sumia" com
    tudo que já estava escrito. Corrigido mantendo o texto acumulado só do nosso lado
    (`editor/OpenMSXConsoleGui.pbi`), nunca dependendo do widget "lembrar" o que já foi escrito -
    elimina a classe do bug, não só o sintoma.
  - **Nova área de colar/digitar texto** + botão **"Inserir no openMSX"** (janela aumentada pra
    900×500) — digita o conteúdo no MSX como se fosse teclado de verdade (quebra de linha vira Enter),
    replicando o mecanismo real do Catapult oficial: `openmsx/catapult/src/InputPage.cpp`,
    `OnTypeText()`, que manda `type -- <texto escapado>` (comando Tcl embutido do openMSX,
    `share/scripts/type.tcl`, delega pro nativo `type_via_keyboard` em `Keyboard.cc`).
  - **Segundo bug real, achado no caminho** (`OMSX_XmlEscape()`, novo em `OpenMSXBridge.pbi`): nenhum
    comando (nem os já existentes, tipo o console manual) escapava `&`/`<`/`>` antes de embrulhar em
    `<command>...</command>`. Lendo o parser de verdade do openMSX
    (`openmsx/openmsx/src/events/AdhocCliCommParser.cc`) - uma máquina de estados byte-a-byte -
    confirmou-se que um `<` cru (comum em BASIC: `IF X<10`) ou um `&` cru fora de uma entidade válida
    faz o parser voltar pro estado "procurando `<command>`", **descartando o resto do comando sem erro
    nenhum**. Corrigido escapando `&`/`<`/`>` (nessa ordem) antes de qualquer `<command>`, igual ao que
    o Catapult de verdade já faz (`openMSXController.cpp`, `WriteCommand()`,
    `xmlEncodeEntitiesReentrant()`). Duas camadas de escape agora, mesma arquitetura do Catapult:
    `OMSX_TclEscapeWord()` (nível Tcl, uma "palavra" só) por dentro, `OMSX_XmlEscape()` (nível
    transporte) por fora.
  - Validado ao vivo (harness `editor/tools/OpenMsxBridgeTestCli.pb`): texto com `<`, `>`, `&` e aspas
    sai corretamente escapado nas duas camadas, e o console continua respondendo normalmente depois de
    digitar esse texto.
- **2026-08-01 — `Executar → BASIC`/`Nestor Basic` (F5) passam a reconhecer MSX-BASIC clássico
  numerado**: pergunta explícita do usuário — o editor já tokenizava ASCII clássico com números de
  linha e `GOTO`/`GOSUB` para linha (menu **"ASCII clássico já aberto → tokenizado nativo (.bmx)..."**,
  `SaveAsTokenizedNative()`, sem depender do pré-processador Dignified nem de Python), mas **rodar**
  esse mesmo código com F5 quebrava: `RunBasicFromActiveTab()`/`RunNestorBasicFromActiveTab()` sempre
  mandavam o texto da aba pro pré-processador Dignified primeiro, que não reconhece números de linha
  como já resolvidos — tratava cada linha como Dignified sem label e prefixava sua própria numeração
  na frente da original (`10 PRINT "OLA"` virava `20 10 PRINT "OLA"`), corrompendo o programa (achado
  reproduzido com `editor/tools/DigTestCli.exe` antes da correção). Corrigida a heurística de detecção
  de `SaveAsTokenizedNative()` (primeira linha com conteúdo começa com dígito) extraída para
  `LooksLikeClassicAscii()` e reusada nos dois fluxos de Executar: se a aba já é ASCII clássico, pula
  o pré-processador e tokeniza direto, senão segue o caminho Dignified normal. Mesmo comportamento que
  o tokenizador original (`msxbatoken.py`/`-asc`) sempre suportou — programas MSX-BASIC tradicionais
  (sem Basic Dignified) agora rodam no openMSX pela IDE tal como um `.bmx` gerado pela suite original.
- **2026-08-01 (mesma sessão) — renumeração nativa e novo menu "criar .BAS"**: pedido explícito do
  usuário — dado um programa MSX-BASIC clássico já numerado, renumerar de verdade (não só empilhar uma
  segunda numeração por cima da original, tipo `10 PRINT` virando `20 10 PRINT`) para a numeração mais
  compacta possível (`1,2,3...`), corrigindo automaticamente todo `GOTO`/`GOSUB`/`THEN`/`ELSE`/
  `RESTORE`/`RESUME`/`RETURN`/`RUN` (inclusive listas `ON...GOTO`/`ON...GOSUB`) para apontar pra linha
  renumerada certa, e removendo espaços redundantes. Novo `Tok_RenumberAscii()`/`Tok_RenumberLineBody()`
  em `editor/MsxTokenizer.pbi`, deliberadamente espelhando o mesmo fluxo de casamento de comando/
  literal/identificador de `Tok_TokenizeLineBody()` (em vez de reimplementar um parser do zero) pra
  garantir que a decisão "isto é um alvo de jump" seja idêntica à que o tokenizador real vai tomar
  depois. **Bug real achado testando contra `sample/teste.dmx`**: `ON ERROR GOTO 0` é um idioma válido
  do MSX-BASIC (`0` = "desliga tratamento de erro", não uma linha real) que a primeira versão rejeitava
  como "GOTO para linha inexistente"; corrigido tratando alvo `0` como sempre intocado. Validado com um
  harness fora do projeto: casos sintéticos (`ON X GOTO 10,,30` com posição vazia preservada, `REM`/
  `DATA` com texto parecido com `GOTO` intocado, variável `TOTAL` não quebrada pelo prefixo `TO`) e o
  arquivo de produção real de ~900 linhas, batendo manualmente as referências cruzadas de
  `ON STOP GOSUB`/`RESUME` contra a posição real de cada linha-alvo. Novo item de menu **"ASCII
  clássico já aberto → renumerar e criar .BAS..."** (`SaveAsRenumberedBas()`) salva o resultado como
  `.bas` (extensão padrão MSX-DOS/MSX-BASIC), `.amx` (convenção interna do projeto) ou, encadeando com
  o tokenizador, `.bmx`.
- **2026-08-01 (mesma sessão) — "Executar → Renumerar...", equivalente nativo do `RENUM`**: pedido
  explícito do usuário — diferente do "criar .BAS" acima (sempre renumera tudo e exporta pra um
  arquivo novo), este renumera o programa **digitado na própria aba, no lugar**, com os mesmos 3
  parâmetros do `RENUM` real do MSX-BASIC (nova linha inicial, incremento, linha antiga a partir de
  qual renumerar — em branco renumera o programa inteiro), coletados por 3 diálogos `InputRequester`
  sequenciais (mesmo padrão já usado no "Ir para linha" do teclado WordStar). `Tok_RenumberAscii()`
  ganhou um parâmetro `OldLineFrom`: linhas antes dela mantêm o número original intocado, mas ainda
  entram no mapa de resolução pra `GOTO`/`GOSUB` que apontam pra elas continuar corretos; se a nova
  numeração escolhida colidisse com a faixa preservada, falha com erro em vez de gerar um programa fora
  de ordem (mesma recusa do `RENUM` real). O motor de resolução de jumps em si não precisou mudar — o
  desenho de duas passadas da correção anterior (mapeia o programa inteiro antes de reescrever qualquer
  linha) já cobria `GOTO`/`GOSUB`/`RESTORE`/`ON X GOTO`/`ON X GOSUB`/`IF...THEN GOTO`, inclusive
  referências que apontam **para a frente** no arquivo. Validado com harness fora do projeto: `RENUM`
  completo com referência pra frente e pra trás, `RENUM` parcial preservando a faixa anterior e suas
  referências, e o caso de colisão rejeitado corretamente. Escreve direto no editor (undo normal do
  Scintilla, aba marcada como modificada) — não salva sozinho, o usuário revisa e salva como de costume.
- **2026-08-01 (mesma sessão) — integração com MSXBas2Rom e N80/LinkStor80/LibStor80 (toolchains
  externas de terceiros)**: pedido explícito do usuário. Novo **Arquivo → Novo MSXBas2Rom...** (arquivo
  `.bas` ASCII clássico numerado — formato que o compilador MSX-BASIC→ROM
  [msxbas2rom](https://github.com/amaurycarvalho/msxbas2rom) espera direto, sem Dignified). Novo
  **Configurar → MSXBas2Rom...** e **Configurar → N80...**: baixam a versão mais recente do GitHub
  (Windows ou Linux conforme o sistema) e geram **Ajuda → MSXBas2Rom...**/**Ajuda → N80...** a partir do
  que foi baixado — `-h`/`--help` de cada binário + páginas reais da wiki/documentação de cada projeto
  (achado: `msxbas2rom -doc` não despeja documentação de verdade, só aponta pra wiki — o conteúdo real
  de Ajuda vem de lá). N80/LinkStor80/LibStor80 são [Nestor80](https://github.com/Konamiman/Nestor80)
  (mesmo autor do NestorBASIC já suportado) — **não confundir com o assembler/linker/biblioteca Z80
  nativo do próprio projeto** (já implementado antes desta sessão), são um caminho externo alternativo
  que convive ao lado, não uma substituição. Achado real durante a pesquisa: LinkStor80 e LibStor80 não
  são repositórios separados, vivem dentro do próprio repo do Nestor80 em release tags diferentes —
  baixar "a versão mais recente de cada um" exigiu varrer o histórico completo de releases, não só
  `/releases/latest` (que só devolve o N80). Também baixa e formata o manual M80L80
  (`docs/MACRO-80.txt` do repositório, "Microsoft M80 DOC") como um tópico de Ajuda próprio.
  - Novo motor de Ajuda compartilhado (`editor/GenericMdHelpGui.pbi`) — ao contrário dos helps
    existentes (conteúdo fixo, escrito à mão), o conteúdo destes dois é **baixado e renderizado ao
    vivo** a partir de `.md` salvos em disco (decisão confirmada com o usuário): "Baixar" de novo no
    futuro atualiza a Ajuda sozinha. Renderizador de Markdown ganhou títulos `#`/`##`/`###`, blocos de
    código ` ``` ` e, a pedido explícito ("com links e tudo mais"), **links clicáveis de verdade**
    (`[texto](url)` abre no navegador) — benefício que também vale pros 3 helps antigos, já que
    usam o mesmo motor por baixo.
  - **Bug real encontrado**: `CreateDirectory()` nativo do PureBasic não cria pastas intermediárias que
    ainda não existem — as pastas novas de instalação (`tools/msxbas2rom/`, `tools/n80/`) são caminhos
    de 2 níveis que nunca existiam antes da primeira execução, então o download extraía "com sucesso"
    sem escrever nenhum arquivo de verdade. Corrigido com um helper de criação recursiva, sem tocar na
    função de extração de zip já existente (usada também pelo download do Basic Dignified Suite).
  - Validado ponta a ponta com harnesses de console fora do projeto, baixando de verdade do GitHub:
    MSXBas2Rom v1.2.1.0 (11 tópicos), N80 1.3.5 + LinkStor80 1.1.0 + LibStor80 1.0 (6 tópicos, incl. o
    manual M80L80 de 91KB) — mesmas versões achadas manualmente durante a pesquisa. Renderização testada
    contra todo o conteúdo real baixado (maior arquivo, 109KB, renderiza em 185ms) sem crash. Aparência
    visual e clique em link **não conferidos ao vivo** (sem ferramenta de screenshot pra app nativo
    nesta sessão) — pendente de teste visual pelo usuário.
- **2026-08-01 (mesma sessão) — destaque de sintaxe estendido pro MSXBas2Rom**: pedido explícito do
  usuário — abas em modo `.bas`/MSXBas2Rom não reconheciam nenhum dos comandos/funções estendidos do
  compilador (`CMD TURBO`, `SCREEN LOAD`, `SET TILE PATTERN`, `HEAP()`, `COLLISION()`, `FILE`/`TEXT`
  etc., extraídos do conteúdo real já baixado em `tools/msxbas2rom/help/`). Três tabelas de palavra-chave
  novas, só consultadas quando a aba está em modo `"BAS"` — de propósito: um programa Dignified comum
  pode ter uma variável chamada `TURBO`, então a extensão não entra nas tabelas globais existentes.
  Validado com harness de console isolado (11 casos, incluindo dois confirmando que essas palavras
  continuam identificador comum fora do modo MSXBas2Rom).
- **2026-08-01 (mesma sessão) — bump de versão para `7.9.1`**: pedido explícito do usuário, fechando
  a sequência de features desta sessão (Renumerar/`RENUM`, integração MSXBas2Rom + N80/LinkStor80/
  LibStor80 com download e Ajuda, destaque de sintaxe estendido) e uma passada de organização na
  documentação — `docs/MANUAL.md` ganhou as seções que faltavam pra essas features (nenhuma delas
  tinha guia de uso até então: pipeline nativo de conversão/tokenização de ASCII clássico, Renumerar,
  Suporte a MSXBAS2ROM, N80/LinkStor80/LibStor80), e um trecho desatualizado (dizia que o motor do
  assembler Z80 "ainda não existe", quando na verdade o resto do próprio manual já documentava o
  assembler nativo em detalhe) foi corrigido. `build.ps1` (`$Version`) e `#App_Version`
  (`editor/BadigEditor.pb`) atualizados juntos, sem codinome novo desta vez.

- **2026-08-04 — `-ss` (strip spaces) removendo bem menos espaços do que deveria**: bug reportado pelo
  usuário — `for linha=0 to 191 step 10` ficava com espaços sobrando em vez de virar
  `forzz=0to191step10`. A reinterpretação pragmática do `-ss` nativo (ver changelog 2026-07-14)
  preservava um espaço entre *qualquer* par de palavras adjacentes, por achar (errado) que era
  necessário pra não gerar `PRINTA` a partir de `PRINT A`. Rastreando o tokenizador de verdade até o
  fim: ele casa palavras-chave em qualquer posição sem exigir fronteira, então `PRINTA` já tokeniza
  certo como `PRINT`+`A` (mesmo truque clássico de `FORI=1TO10` no MSX real) — o risco de verdade é só
  quando colar dois átomos nasce uma palavra-chave **diferente** na fronteira (`X`+`OR`→`XOR`). Corrigido
  com uma checagem de fronteira contra a lista de palavras reservadas, mantendo o espaço só nesse caso.
  Detalhe técnico completo em `docs/SPEC.md`, módulo 3h.
- **2026-08-04 (mesma sessão) — bug real do PureBasic 6.40 instalado, achado verificando a correção
  acima**: `editor/tools/DigTestCli.exe` (harness de regressão) travava (access violation) ao rodar
  contra **qualquer** entrada real, inclusive `sample/teste.dmx` sem tocar em nada — `CopyMap()` num
  mapa vazio de elemento pequeno (`.b()`/`.w()`) trava nesse compilador especificamente; mapas `.i()`/
  `.s()` vazios não têm o problema. `Dig_Keeps()` (controle de toggle-rem) é exatamente esse tipo de
  mapa e começa vazio sempre que o arquivo não usa nenhum `#toggle` — ou seja, o caminho comum. Corrigido
  em `Dig_ProcessSource` só chamando `CopyMap()` quando o mapa de origem não está vazio. Detalhe em
  `docs/SPEC.md`, módulo 3h.
- **2026-08-04 (mesma sessão) — novo menu Inserir → Caractere Especial...**: pedido explícito do
  usuário, um mapa de caracteres estilo Windows pros 159 caracteres que `-tr` traduz pra ASCII nativo
  MSX (`editor/CharMapGui.pbi`, ver "O que já temos" acima para a descrição completa da UI). Construir
  essa feature revelou dois bugs reais e não relacionados entre si em `DignifiedPreprocessor.pbi`,
  ambos afetando `-tr` mesmo sem essa feature nova:
  - **31 símbolos extras (carinhas/naipes/linhas tipo CP437) traduzindo errado**: viravam só uma letra
    solta (`"☺"` → `"A"`) em vez do escape de 2 bytes que o driver de tela do MSX espera (`Chr(1)` +
    letra). Achado comparando byte a byte contra o `badig.py` de referência de verdade (presente no
    repo em `basic-dignified/`) — a causa raiz é que `Chr(1)` é um caractere de controle invisível,
    então sumia sem deixar rastro tanto no Python original quanto neste port, ao serem lidos num
    visualizador de texto normal.
  - **Vários `.pbi` sem BOM UTF-8**: o `pbcompiler.exe` 6.40 instalado detecta a codificação por
    arquivo incluído (não por unidade de compilação inteira) — sem BOM ele decodifica UTF-8 como
    Latin-1, corrompendo qualquer literal não-ASCII. Isso já corrompia **texto de ajuda visível pro
    usuário** antes desta sessão: 121 setas de navegação (`→`) na Ajuda do openMSX e exemplos com
    linhas de caixa na Ajuda do Basic Dignified. Corrigido adicionando BOM a 14 arquivos.
  Detalhe técnico completo (incluindo a lista dos 14 arquivos) em `docs/SPEC.md`, módulo 3h/19.
- **2026-08-04 (sessão seguinte) — continuação da modernização visual ("menos cara de Windows 95")**:
  varredura de padding aplicando a mesma grade de `EditorSettings.pbi` (24px de margem externa, 24px de
  altura de campo, 8px rótulo→campo, ~16-30px entre grupos) a praticamente todos os diálogos restantes
  do editor — `BadigSettings.pbi` (3 abas + diálogo de escolha de máquina/extensão),
  `DiskManagerGui.pbi`, `FontDownloader.pbi`, `N80Support.pbi`, `MsxBas2RomSupport.pbi`,
  `Z80SubProjectGui.pbi`, `Z80OutputGui.pbi`, `Z80LinkGui.pbi`, `Z80LibGui.pbi`,
  `OpenMSXConsoleGui.pbi`, `CharMapGui.pbi`, `MdViewerGui.pbi` e as 5 janelas de Ajuda em árvore
  (Basic Dignified/openMSX/NestorBASIC/MSX BASIC/genérica MD). Ficam de fora, de propósito, os 8
  editores gráficos de canvas (Sprite/Graphos/Screen2/Charset/Aquarela/PSG/MML/Hex) — layout
  fundamentalmente diferente de um formulário, mudança maior e mais arriscada que um ajuste de margem.
  Dois bugs reais encontrados e corrigidos durante a varredura: coordenadas de gadgets dentro de um
  `PanelGadget` são relativas à largura do PRÓPRIO painel, não da janela (um diálogo com abas cortou
  ~40-50px do conteúdo mais à direita até ser corrigido); e um artefato de temporização na técnica de
  screenshot da sessão anterior (`PrintWindow` logo após abrir um diálogo às vezes captura trechos
  inteiros em branco, mesmo com o app renderizando certo por baixo) — corrigido forçando um repaint
  (`RedrawWindow`) antes de capturar.
- **2026-08-04 (mesma sessão) — novo editor de tela Criar → Screen 0...**: pedido explícito do usuário,
  inspirado nos clássicos editores de tela ANSI da era BBS (TheDraw/AcidDraw/DarkDraw) mas adaptado à
  realidade do hardware MSX (`editor/Screen0EditorGui.pbi`, ver "O que já temos" acima pra descrição
  completa). Decisões de design confirmadas com o usuário antes de implementar: cor fiel ao hardware
  (INK/PAPER único pra tela inteira, não por célula) e largura escolhível por tela (40 ou 80 colunas).
  Nova tabela `screen0_screens` em `ProjectDB.pbi`, mesmo padrão de `alphabets`/`screens` já existentes
  — com uma diferença de design real descoberta durante a implementação: a grade guarda o **codepoint
  Unicode** de cada célula (não um byte MSX cru), porque 31 dos 159 caracteres especiais do pipeline
  Dignified (`Dig_TransReplacementOrder` — box-drawing/naipes) só existem via escape de impressão
  `CHR$(1)+CHR$(n)`, não cabem num único byte 0-255 como os outros 128. "Gerar código" emite `PRINT`
  com os glifos Unicode literais direto, deixando a tradução `-tr` já validada resolver pro byte/escape
  nativo MSX na hora de tokenizar — evita ter que calcular endereço de VRAM pro texto em si; só o
  carregador de fonte customizada (quando uma não-padrão é escolhida) precisa do endereço real da
  Pattern Generator Table do SCREEN 0 (`&H0800`, diferente da PGT de SCREEN 1/2 em `&H0000`, endereço de
  hardware não documentado neste repo antes desta sessão). Validado por um harness de auto-teste
  temporário (lógica de moldura/junção via bitmask de 4 direções, sombra, texto, geração de código —
  todos batendo com o esperado) mais screenshot real da janela (grade de caracteres embutida de
  `CharMapGui.pbi`, paletas, abas de ferramenta, sem sobreposição/corte). Versão embutida no executável
  atualizada para `7.10.0`.
- **2026-08-04 (mesma sessão) — Screen 0 WIDTH 80: segunda cor de texto (estática ou piscante),
  ferramenta "Atributo"**: pedido explícito do usuário, que já suspeitava (corretamente) que travar o
  pisca-pisca do modo 80 colunas do MSX2+ dava pra ter 2 cores de texto fixas na tela. Pesquisado a
  fundo antes de implementar (Konamiman MSX2 Technical Handbook + MSX Wiki, ambas já usadas/confiáveis
  neste projeto) em vez de confiar de memória em detalhe de registrador de VDP — confirmado, não é
  folclore: VDP R#12 é um segundo par de cor (BASIC: `VDP(13)=tinta2*16+fundo2`), R#13 controla a
  duração de cada fase do pisca-pisca (BASIC: `VDP(14)=duraçãoNormal*16+duraçãoCor2`, cada unidade
  ~1/6s, até 2.5s por fase — "normal"=0 trava permanentemente na Cor 2), e uma tabela de 240 bytes
  (1 bit/caractere, endereço padrão `&H0800` nesse modo) marca quais células usam o mecanismo. Isso
  revelou um bug real já existente no carregador de fonte customizada: ele sempre usava `&H0800` pra
  Pattern Generator Table, certo só pra 40 colunas — em 80 colunas a PGT padrão é `&H1000` (o `&H0800`
  fica ocupado pela tabela de pisca nesse modo) — corrigido junto. Nova ferramenta **Atributo** (aba a
  mais no editor, 7 no total): clique/arraste liga, botão direito/arraste desliga o atributo de Cor 2
  numa célula, sem mexer no caractere — funciona como uma camada independente. Duas paletas "Cor 2"
  (Tinta2/Fundo2) e dois campos de duração (0-15) somam-se à barra de opções, desabilitados
  automaticamente em telas de 40 colunas (o hardware não tem esse recurso nesse modo). `screen0_screens`
  ganhou 5 colunas novas (`ink2_color`/`paper2_color`/`blink_on_period`/`blink_off_period`/`attr_data`).
  Validado por autoteste temporário (empacotamento de bits do atributo conferido byte a byte contra um
  caso conhecido, valores de `VDP(13)`/`VDP(14)` batendo com o esperado, endereço da PGT saindo certo
  pros dois modos — inclusive a regressão de 40 colunas) mais screenshot real da janela. Versão embutida
  no executável atualizada para `7.11.0`.
- **2026-08-04 (mesma sessão) — reorganização do layout do editor Screen 0**: pedido explícito do
  usuário — a área de edição estava pequena, com todos os controles empilhados numa coluna direita alta
  e um espaço enorme sobrando embaixo do canvas. Canvas dobrado de tamanho (zoom 2→4 em 40 colunas,
  1→2 em 80 — `Scr0Ed_ZoomForWidth`), ferramentas e botões **Injetar/Copiar/Fechar** migraram pra baixo
  do canvas (reaproveitando o espaço que sobrava); só as paletas de cor (Tinta/Fundo/Cor 2) e os campos
  de pisca-pisca continuam na coluna direita, agora bem mais compacta. Verificado por screenshot real.
- **2026-08-04 (mesma sessão) — segundo ajuste de layout do Screen 0: painel de abas menor, grade de
  caractere na coluna direita**: a primeira reorganização deixou o painel de abas (que embutia a grade
  de 159 caracteres da ferramenta Caractere, 544×340px) alto demais, saindo da tela verticalmente.
  Corrigido movendo a grade de caractere pra coluna direita (abaixo da paleta/Cor 2, sempre visível,
  não mais escondida numa aba) — desenhada com célula própria menor (20px, não os 34px originais de
  `CharMapGui.pbi`, `Scr0Ed_DrawCharPicker`) pra caber sem alargar a janela. Sem a grade grande, o
  painel de abas (agora só com texto explicativo em cada aba) encolheu de 420px pra 160px de altura.
  Verificado por screenshot real.
- **2026-08-04 (mesma sessão) — terceiro ajuste de layout do Screen 0: cabe com folga em 1920×1080**:
  usuário reportou que ainda quase não cabia na resolução mínima aceita do projeto (1920×1080). Duas
  mudanças sugeridas pelo próprio usuário: a barra de projeto (número/navegação/tag/Novo/Registrar), que
  ficava acima do canvas, migrou pra baixo da grade de caractere na coluna direita (2 linhas compactas);
  os botões **Injetar no cursor**/**Copiar**/**Fechar**, que ficavam abaixo do painel de abas, migraram
  pro lado dele (empilhados verticalmente à direita, mesma faixa de altura). As duas mudanças juntas
  tiraram a barra de projeto inteira (antes ocupando uma faixa própria no topo) e a faixa de botões
  (antes abaixo do painel) da pilha vertical. Verificado por screenshot real.
- **2026-08-05 — novo editor de tela `Criar → Screen 1...` (`v7.12.0`)**: segunda da família SCREEN 0/1/2
  planejada, mesmo espírito TheDraw/AcidDraw do editor SCREEN 0, mas com a diferença real de cor do
  hardware SCREEN 1 — a Color Table real do TMS9918 guarda 32 pares tinta/fundo, um por **grupo de 8
  códigos de caractere** (endereço padrão `&H2000`, confirmado contra a MSX Wiki antes de escrever
  código), não uma cor única pra tela inteira. A "tabela ASCII do alfabeto" pedida pelo usuário é uma
  grade de 256 células mostrando o bitmap real de cada código da fonte ativa, com o fundo de cada célula
  já pintado na cor do seu octeto — clicar escolhe o byte atual, e as paletas Tinta/Fundo ao lado colorem
  o octeto (8 códigos) daquele byte, refletido ao vivo na tabela e no canvas. Achado real de hardware:
  os 31 caracteres "gráfico" de escape do pipeline Dignified (moldura/naipes/carinhas,
  `Dig_TransReplacementOrder`) são, na verdade, os códigos MSX 1-31 — permitiu guardar a grade como byte
  MSX cru (0-255) em vez de codepoint Unicode como o editor SCREEN 0 faz, e gerar código sem depender da
  tradução `-tr` (literais entre aspas + `CHR$(n)` direto dos bytes). Mesmas 6 ferramentas da primeira
  versão do SCREEN 0 (Texto/Caractere/Quadro/Sombra/Bloco/Borracha). Bug real pego só no screenshot (não
  no harness de lógica pura): `DrawingMode` vazando entre iterações do laço da grade de 256, deixando 255
  das 256 células em branco — corrigido resetando o modo antes de cada glifo.
- **2026-08-05 (mesma sessão) — novo editor de tela `Criar → Screen 1+2...` (`v7.13.0`)**: terceira e mais
  complexa da família SCREEN 0/1/2, pedida explicitamente como "o modo mais complexo". Mesma grade 32×24
  e mesmas 6 ferramentas do editor SCREEN 1, mas gerando `SCREEN 2` de verdade com os dois recursos extras
  do hardware: **3 alfabetos** (um por "terço" de 8 linhas de tela, endereços `Terço*2048`/
  `&H2000+Terço*2048` confirmados contra a MSX Wiki) e **cor por linha de scanline de cada código de
  caractere** (8 cores por glifo, o "color clash" real do SCREEN 2 — toda ocorrência do mesmo código no
  mesmo terço compartilha a mesma cor por linha). Duas decisões de UI confirmadas com o usuário via
  `AskUserQuestion` antes de implementar: o editor de cores por linha abre como janela separada (não
  painel embutido), e o botão de edição em bloco (início/fim) aplica o MESMO padrão de 8 cores a todos os
  códigos do intervalo de uma vez. Reaproveitou direto (sem alteração nenhuma) boa parte do editor SCREEN
  1 — `Scr1Ed_GlyphByteFor`/`StampText`/`DrawBox`/`ApplyShadow`/`FillRect`/`BuildLineExpr` — já que a
  grade e a semântica de byte MSX cru são idênticas; só a renderização/modelo de cor mudou. Aplicando a
  lição do editor SCREEN 1 (bug de `DrawingMode` vazando entre células), a grade de 256 já nasceu
  renderizando certo desde a primeira screenshot. Verificado por harness de auto-teste temporário
  (`--scr12test`, removido) e 2 screenshots reais (janela principal + popup "Cores do caractere..."
  acionado via `SendMessage`/`BM_CLICK` num botão nativo do Win32).
- **2026-08-05 (mesma sessão) — correções de UX e novos recursos no editor Screen 1+2 (`v7.14.0`)**:
  usuário reportou um bug real de UX no editor recém-lançado — colorir um caractere com o seletor
  "Terço" da tabela ASCII num terço não garantia que a cor aparecesse ao carimbar aquele código na área
  real da tela do mesmo terço, porque o seletor nunca teve nenhuma relação com QUAL linha do canvas
  estava sendo tocada, só com o que a tabela mostra (a cor de fato usada sempre vem do terço REAL da
  linha clicada). Corrigido de duas formas (as duas escolhidas pelo usuário via `AskUserQuestion`): uma
  linha-guia preto+branco no canvas marcando os limites de cada terço, e o seletor/tabela ASCII passaram
  a **acompanhar sozinhos** qualquer clique/arraste no canvas (`Scr12Ed_SyncEditThirdToRow`). Na mesma
  sessão, dois pedidos de melhoria: **"Cores em bloco..."** deixou de pedir início/fim num popup
  digitado — agora clica-se o código inicial e final direto na tabela ASCII (marca ciano sutil enquanto
  escolhido, botão direito cancela); e três novos botões **Resetar caractere/Resetar bloco.../Resetar
  TODOS os caracteres do terço** voltam Tinta/Fundo pro padrão (letra branca em fundo preto) no byte
  atual, num intervalo ou nos 256 códigos do terço de uma vez. Verificado com screenshots reais da
  janela completa e do fluxo de escolha de bloco. Versão embutida no executável atualizada para
  `7.14.0`.
- **2026-08-06 — nova Ajuda SEE Tracker, estudo do formato SEE (`v7.15.0`)**: usuário pediu pra ler o
  manual original do **SEE** (`see/SEE3HELP.TXT`) e o driver de replay (`see/SEE3PLAY.ASC`), guardando
  o máximo entendido numa tela de Ajuda nova — preparação para um tracker de SFX nativo compatível com
  `.SEE`, a construir numa sessão futura (`por hora apenas estudo`, nenhum editor/gerador `.SEE`
  implementado ainda). Novo menu **Ajuda → SEE Tracker...** (`editor/SeeTrackerHelpData.pbi`/
  `SeeTrackerHelpGui.pbi`, clone estrutural de `BasicDignifiedHelpGui.pbi`) cobre o manual (telas,
  menus, teclas, os 11 canais de um pattern), o formato binário `.SEE` campo a campo e o mecanismo
  real do driver — lendo o `.ASC` linha a linha (não só o manual) revelou detalhes reais que o manual
  não menciona: os comandos `FOR`/`START` só disparam uma vez (nunca reprocessados nas repetições
  seguintes de um loop — só os dados PSG do pattern são revisitados), o byte de evento só tem 3 bits
  realmente testados pelo player, o bit de "Wave" do volume é literalmente o bit de envelope de
  hardware do próprio PSG, e a fórmula exata de escala por `Max Volume`. Também comparados byte a byte
  (`xxd`) os cabeçalhos dos 4 arquivos `.SEE` de exemplo desta pasta contra o que o manual/driver
  descrevem, com pelo menos uma divergência real deixada como pergunta em aberto (documentada, não
  escondida) para quando a implementação de verdade começar. Versão embutida no executável atualizada
  para `7.15.0`.
- **2026-08-06 (mesma sessão) — usuário insistiu em inferir mais sobre o cabeçalho a partir do driver**:
  rastrear `SEE_IN` (`see/SEE3PLAY.ASC`) byte a byte revelou uma inconsistência real entre a checagem de
  identificação (só 4 bytes) e a cópia dos 4 contadores do cabeçalho, que ficavam encadeadas no arquivo
  original. Testando as duas leituras possíveis contra os 4 `.SEE` reais desta pasta: a leitura "como os
  comentários do próprio driver descrevem" bate perfeitamente nos 4 arquivos (divisão exata, resto
  zero) — resolvendo a dúvida anterior: `$08-$09` é uma constante de capacidade (`$03FF`), não uma
  contagem por arquivo. Achado colateral: os 4 arquivos sobram exatamente os mesmos 1056 bytes no final,
  sugerindo uma área não documentada no manual. Ajuda/SPEC.md atualizados com a correção.
- **2026-08-06 (mesma sessão) — novo editor `Criar → SEE Tracker...` (`v7.16.0`)**: "vamos criar
  Criar->See Tracker". Duas decisões confirmadas via `AskUserQuestion` antes de implementar: grade
  nativa de patterns (não lista de passos) com painel de edição de verdade ao lado, e um **driver de
  replay Z80 nativo embutido** (não só os dados `.SEE`) — a opção mais ambiciosa das duas oferecidas.
  `editor/SeeTrackerDriverAsm.pbi` porta `see/SEE3PLAY.ASC` pro assembler nativo desta IDE (sintaxe de
  hex/rótulos adaptada, checagem de ID desacoplada da cópia do cabeçalho — corrigindo o problema
  encontrado na entrada de changelog anterior —, checagem opcional de overflow via ROM-BIOS removida, e
  um vetor novo `BSETFX` que adapta o argumento de `USR()` pro `SETSFX` cru), montado **em tempo real**
  pelo `Z80Asm::Assemble()` já existente. `editor/SeeTrackerSynth.pbi` interpreta patterns+eventos
  quadro a quadro fiel ao driver (`TEMPO`/`HALT` interagem em dois níveis — achado só visível lendo o
  driver linha a linha) expandindo pra `PsgStepData` e reaproveitando 100% do motor de síntese do editor
  PSG pro preview; monta o blob `.SEE` exato e o código BASIC (`DATA`/`POKE`/`DEFUSR`) prontos.
  `editor/SeeTrackerEditorGui.pbi` é a janela (grade + painel + barra de projeto, mesmo padrão dos
  demais editores) — bateu de novo o gotcha de `Procedure` aninhada (PureBasic não permite), corrigido
  hoisteando as duas procedures de painel pro escopo de arquivo. Verificado por 2 harnesses novos
  (`editor/tools/SeeTrackerDriverTestCli.pb`: 784 bytes montados, os 6 vetores conferidos byte a byte;
  `editor/tools/SeeTrackerSynthTestCli.pb`: 22 asserções sobre `HALT`/`FOR`/`NEXT`/`RERUN`/geração de
  código/formato do blob) e verificação ao vivo na GUI real (Inserir pattern, Gerar código — 5399
  caracteres sem erro —, endereços do clipboard conferidos contra o harness, Tocar num efeito vazio).
  Versão embutida no executável atualizada para `7.16.0`.
- **2026-08-06 (mesma sessão) — Importar .SEE... (`v7.17.0`)**: "Podemos ter uma opção para ler arquivos
  SEE gerados pelo SEE original de MSX?". Três funções novas em `SeeTrackerSynth.pbi`:
  `SeeImp_IsValidHeader` (confere só os 4 bytes `SEE3`), `SeeImp_ListDefinedSfx` (varre os 256 slots da
  tabela de posições procurando o sentinela `$FF` — sem confiar no campo `HISFX`, que já mostrou um
  valor implausível no `QUARTH.SEE` de exemplo) e `SeeImp_ExtractSfxPatterns` (anda sequencialmente a
  partir do pattern inicial até o evento `END`). Botão **Importar .SEE...** na janela abre o arquivo,
  lista os SFX definidos numa janela auxiliar e substitui os patterns do SFX atual pelos importados.
  **Validado contra um arquivo real** (`see/FIREBIRD.SEE`, harness ad-hoc): 33 SFX encontrados, limites
  perfeitamente sequenciais (SFX #0 termina no pattern 7, SFX #1 já começa no 8) e o primeiro efeito
  extraído termina corretamente num `END` real (`$F0`). A automação da sessão não conseguiu dirigir o
  diálogo nativo de abrir arquivo (`BM_CLICK` sintético não entrega a digitação ao `OpenFileRequester`
  do Windows) — sem travar nada (o resto da janela respondeu normal logo depois), só uma limitação da
  automação, não do recurso; a confiança vem do teste direto das funções contra o arquivo real. Versão
  embutida no executável atualizada para `7.17.0`.
- **2026-08-06 (mesma sessão) — correção do "Tocar" no SEE Tracker (`v7.18.0`)**: "quando coloco tocar,
  não está tocando". Causa raiz real, reproduzida ao vivo: `SeeTrackerEditorGui.pbi` nunca chamava
  `InitSound()` (padrão `Global ..._SoundSystemReady.b` já usado por `PsgEditorGui.pbi`/
  `MmlEditorGui.pbi`, mas nunca copiado pra essa janela nova) — sem isso `LoadSound()` falha (devolve 0)
  **silenciosamente**, e como o `G_Play` não tinha `Else` nos 3 pontos onde podia falhar, "Tocar" não
  fazia literalmente nada visível, nem tocar nem avisar erro. Corrigido com o mesmo padrão
  `SeeEd_SoundSystemReady` + mensagens de erro reais nos 3 pontos. **Achado colateral corrigido junto**:
  um SFX novo (1 pattern, evento `END`) mais **Inserir pattern** (sempre inseria DEPOIS do selecionado)
  formava uma armadilha — o primeiro pattern editado ficava depois do `END` inicial, nunca alcançado no
  playback (que sempre começa no pattern 0). Corrigido em duas frentes: SFX novo já nasce com 2 patterns
  (`SeeEd_InitBlankSfx` — um em branco, um com `END` depois), e **Inserir pattern** agora insere ANTES do
  selecionado quando esse tem evento `END`. Terceiro ajuste, de ergonomia (o editor SEE original liga o
  canal implicitamente ao digitar uma frequência — nosso editor exigia marcar "Som" à parte): os campos
  de frequência/volume agora ligam sozinhos o checkbox "Som" daquele canal na primeira vez que o valor
  digitado fica diferente de zero (nunca desliga sozinho). Mensagem de "Nada pra tocar" também ficou
  diagnóstica quando a causa é um `END` no pattern 0. Verificado ao vivo depois da correção — status
  mostra "Reproduzindo..." de verdade, conferido via `GetWindowText` no controle (não só screenshot, que
  se mostrou pouco confiável pra conteúdo de `TextGadget` nesta automação — gotcha novo documentado no
  `docs/SPEC.md`). Versão embutida no executável atualizada para `7.18.0`.
- **2026-08-06 (mesma sessão) — grade do SEE Tracker ilegível, "fundo preto e letras escuras" (`v7.19.0`)**:
  usuário reportou baixo contraste nas linhas com dados da grade. Só foi possível achar a causa real com
  screenshot de verdade (`PrintWindow` + crop/zoom) — pelo código, `SeeEd_DrawGrid` parecia inofensivo
  (`Box()` branco de fundo, depois `DrawText()` colorido por cima). A screenshot mostrou cada valor
  preso numa caixinha preta opaca do tamanho exato do texto: nenhum `DrawText()` da função usava
  `DrawingMode(#PB_2DDrawing_Transparent)`, então o modo padrão pintava um retângulo opaco atrás de cada
  texto com `BackColor()` — nunca setada ali, portanto preta (padrão do PB) — por cima de qualquer fundo
  já desenhado. Presente nos dois temas, mais perceptível no Dark. Corrigido com
  `DrawingMode(#PB_2DDrawing_Transparent)` antes do bloco de `DrawText()` de cada linha. Aproveitado pra
  também tornar a grade sensível a `EditorCfg\Theme` (antes sempre desenhava fundo branco fixo): tema
  Light mantém a paleta original; tema Dark ganhou fundo cinza-azulado bem menos escuro que a janela
  (`RGB(48,51,60)`) com cores de texto claras/vivas (azul, vermelho, âmbar, magenta, quase-branco),
  atendendo ao pedido do usuário ("o fundo pode ser menos escuro e as letras mais brilhosas"). Verificado
  ao vivo nos dois temas via screenshot real antes/depois. Versão embutida no executável atualizada para
  `7.19.0`.
- **2026-08-06 (mesma sessão) — cursor de playback + seletor visual de forma do envelope (`v7.20.0`)**:
  dois pedidos - "faça o tocar mover uma espécie de cursor em cada pattern/linha para visualmente
  podermos ver onde estamos" e "na parte de Forma, você poderia fazer algo visual para podermos ver as
  formas do PSG?". `SeeSynth_Expand()` ganhou um novo parâmetro `List OutPatIdx.i()` (o pattern de
  origem de cada step, em paralelo a `OutSteps()`) - 2 novas asserções no harness conferem os valores
  reais produzidos pelos casos de `HALT`/`FOR`/`NEXT` já existentes, não só que "compila". A grade
  ganhou um `PlayCursor` (borda verde + faixa lateral, independente do realce de seleção) atualizado por
  um timer de 40ms que consulta `GetSoundPosition()` de verdade contra a linha do tempo do efeito, com
  auto-scroll se o cursor sair da área visível. Pro seletor de forma: um preview compacto ao lado do
  campo **Forma** (sempre visível) mais um botão **...** que abre uma grade 4x4 com as 16 formas reais
  do envelope do PSG (curva + rótulo hex), clicar já escolhe. Ambas as curvas reaproveitam
  `PsgSynth_ApplyEnvShape`/`PsgSynth_EnvTick` (o MESMO gerador usado na síntese de verdade), garantindo
  fidelidade ao som real. **Verificado ao vivo com screenshots reais**: as 16 formas batem exatamente
  com a tabela padrão do AY-3-8910/YM2149; o cursor de playback foi testado em duas configurações
  diferentes (dados no pattern 1, depois movidos pro pattern 0 via "Mover p/ cima") e apareceu na linha
  correta nas duas vezes, sumindo sozinho ao fim natural da reprodução. Versão embutida no executável
  atualizada para `7.20.0`.
- **2026-08-06 (mesma sessão) — Limpar / Limpar linha / Limpar bloco (`v7.21.0`)**: "crie um botão limpar
  para limpar totalmente os padrões já inseridos, e um botão para limpar uma linha em particular, e outro
  para limpar um bloco". Três botões novos numa linha própria no SEE Tracker: **Limpar** (volta ao estado
  inicial - 1 pattern em branco + `END` - mas mantém o número/tag do SFX, diferente de "Novo"; pede
  confirmação se houver alterações não registradas, mesmo padrão já usado por "Novo"/navegação de SFX)
  **Limpar linha** (zera os 15 bytes do pattern selecionado sem remover a linha, diferente de "Apagar
  pattern") e **Limpar bloco** (janela nova pedindo um intervalo De/Até, pré-preenchido com o pattern
  selecionado, zera todos daquele intervalo de uma vez - a própria janela já serve de confirmação).
  Nenhum dos três remove nenhuma linha da lista, só zeram dados no lugar. Verificado ao vivo via
  screenshot: inseridos patterns extras, "Limpar bloco" com intervalo 0-2 zerou os três numa tacada
  (inclusive um pattern `END`, sem quebrar nada - o motor já trata "sem `END` nenhum" como fim implícito),
  e "Limpar" mostrou a confirmação e voltou exatamente ao estado inicial ao confirmar. Versão embutida no
  executável atualizada para `7.21.0`.
- **2026-08-06 (mesma sessão) — cabeçalho da grade desalinhado (`v7.21.1`)**: "os títulos das colunas #,
  Evt, Snd1... está desalinhado com as colunas". Causa: o cabeçalho era um `TextGadget` com texto
  espaçado à mão numa fonte proporcional, nunca garantido bater com os offsets em pixel que
  `SeeEd_DrawGrid()` usa pra desenhar as colunas de dados. Trocado por um `CanvasGadget` desenhado uma
  vez (`SeeEd_DrawHeader()`) usando os MESMOS `#SeeEd_GridColXxx` e preenchimento de cada célula que a
  grade já usa - alinhamento garantido por construção. Verificado ao vivo via screenshot com zoom: cada
  rótulo cai exatamente sobre sua coluna. Versão embutida no executável atualizada para `7.21.1`.
- **2026-08-07 — Editor Hexa: mais formatos reconhecidos (`v7.22.0`)**: usuário pediu pra ampliar o
  reconhecimento de formato do módulo 17 (`editor/HexEditorGui.pbi`) além dos três nativos da IDE.
  Implementado: **executável MSX-DOS `.COM`** (extensão checada antes dos bytes mágicos `FEh`/`FFh` —
  código Z80 cru sem cabeçalho, convenção CP/M, carrega e executa sempre em `0100h`, então o primeiro
  byte real do programa poderia bater por coincidência com um cabeçalho BLOAD/BSAVE ou tokenizado se a
  extensão não fosse checada primeiro); e **texto ASCII puro vs. BASIC MSX clássico numerado**
  (`HexEd_LooksLikeBasicSource` — olha só o primeiro caractere visível do arquivo, dígito = linha
  numerada, mesma regra que o tokenizador exige de entrada). Pedido também incluía WordStar, MSX-Word,
  SuperCalc II e dBase II — **não implementados nesta sessão**: nenhum tem cabeçalho/layout binário
  confirmado a partir daqui (WordStar historicamente só liga o 8º bit no último caractere de cada
  palavra, sem cabeçalho fixo — heurística arriscada sem arquivo real pra validar; os outros três não
  têm formato documentado neste repositório), então ficaram como pendência aguardando arquivos de
  exemplo reais do usuário pra estudar antes de cravar qualquer detecção binária, mesmo padrão de
  trabalho já usado em `MSXDisk.pbi`/`GraphosNativeIO.pbi`/SEE Tracker. Ver módulo 17 em `docs/SPEC.md`.
  Versão embutida no executável atualizada para `7.22.0`.
- **2026-08-07 (mesma sessão) — Editor Hexa reconhece SuperCalc 2 MSX `.CAL` (`v7.23.0`)**: usuário
  forneceu `sc2/` (projeto Go pessoal dele, `sc2msx`, reescrita do SuperCalc 2) e 5 planilhas `.CAL`
  reais (`sc2/msx/*.CAL`) pra atacar a pendência de SuperCalc II deixada na entrada anterior. Achado
  que destravou o estudo sem precisar de emulador: o disco original `supercalc2L.dsk` tinha
  `EXEMPLO.CAL` **e** `EXEMPLO.SDI` (o formato texto intermediário) lado a lado — um par binário/texto
  verdadeiro, extraído com a própria `--diskmanipulator` desta IDE. Cruzando esse par com os outros 5
  `.CAL`, confirmado: assinatura de 22 bytes `"SuperCalc ver.  1.00\r\n"`, campo de título de 80 bytes
  em `000016h`, cabeçalho de tamanho fixo com a seção de dados sempre começando em `000300h` —
  validado contra os 6 arquivos reais via harness descartável antes de integrar. O layout célula a
  célula dentro da seção de dados ainda não foi decifrado (fica documentado como próximo passo em
  `docs/reference/supercalc2-cal-format.md`, novo arquivo). Achado colateral: `sc2/msx/msxdos1.dsk` tem
  `PESSOAL.DBF`, amostra real de dBase II pra quando essa pendência for atacada. Versão embutida no
  executável atualizada para `7.23.0`.
- **2026-08-07 (mesma sessão) — Editor Hexa reconhece dBase II `.DBF` (`v7.24.0`)**: usuário pediu pra
  aproveitar o achado colateral da entrada anterior (`PESSOAL.DBF`, de `sc2/msx/msxdos1.dsk`) e adicionar
  `.gitignore` pra `sc2/` (software original de terceiros, mesmo padrão já usado pra `see/`). Diferente
  do SuperCalc 2, o dBase II saiu **totalmente decifrado** — não só reconhecido: cabeçalho (versão,
  número de registros, tamanho do registro), descritores de campo (nome/tipo/tamanho, 16 bytes cada,
  até 32, terminados em `0Dh`) e os próprios registros de dados, validados um a um contra um harness
  descartável que reconstituiu os 6 registros reais do arquivo (nome/cargo/salário/data de admissão de 6
  funcionários) e bateu exatamente com o hexdump. Achado notável: dados sempre começam no offset fixo
  `000209h` (`8 + 32×16 + 1`) — o formato reserva espaço pra até 32 campos mesmo quando poucos estão em
  uso, e o mesmo byte `1Ah` de fim-de-arquivo do CP/M que já apareceu no `.CAL` do SuperCalc 2 marca o
  fim dos dados aqui também. Notas completas em `docs/reference/dbase2-dbf-format.md` (novo arquivo).
  Versão embutida no executável atualizada para `7.24.0`.
- **2026-08-07 (mesma sessão) — Editor Hexa reconhece os 4 formatos nativos do Graphos III (`v7.25.0`)**:
  usuário perguntou se dava pra identificar Tela/Alfabeto/Shape/Layout do Graphos III (`.SCR`/`.ALF`/
  `.SHP`/`.LAY`) usando o material de `graphos/`/`graphos-IV/` já no repositório. Diferente do SuperCalc
  2/dBase II, esses formatos já estavam **totalmente documentados** de uma sessão anterior
  (`editor/GraphosNativeIO.pbi`, módulo 14i) — só precisou portar o conhecimento já validado, não
  decifrar do zero. Validado em lote contra **todos os arquivos reais do repositório** (~4100 arquivos
  entre `graphos/` e `graphos-IV/`, não só uma amostra pequena): `.LAY` 234/234 (100%, decodifica o
  RLE+ofuscação de verdade e confere 6144 bytes exatos — achou e corrigiu um bug real no decodificador
  nesse processo), `.SCR` 86/86 (100%), `.ALF` 759/781 (97% — validação em lote revelou que o endereço
  de início nem sempre é `9200h` e que uma minoria real usa uma convenção de "fim exclusivo" no
  cabeçalho, ambos agora tolerados), `.SHP` 2920/3028 (96% — esse é o ganho real, não tinha NENHUM
  reconhecimento antes por não ter cabeçalho BLOAD/BSAVE; percorre a cadeia de blocos inteira até o
  terminador `FFh`, sem nenhum falso positivo encontrado nas falhas investigadas). Versão embutida no
  executável atualizada para `7.25.0`.
- **2026-08-07 (mesma sessão) — codinome `HEXORCIST` pra `7.25.0`, documentação consolidada e
  `RELEASE_NOTES.md`**: pedido explícito do usuário pra revisar toda a documentação da sessão (esta
  sessão inteira girou em torno do Editor Hexa aprendendo a reconhecer formato atrás de formato — `.COM`,
  `.CAL`, `.DBF`, `.ALF`/`.LAY`/`.SCR`/`.SHP`), consolidar o que já é identificado hoje no `docs/SPEC.md`
  (módulo 17 ganhou uma tabela única com todos os formatos + nível de confiança de cada um, em vez de só
  parágrafos cronológicos espalhados) e gerar `docs/RELEASE_NOTES.md` com notas de lançamento formais
  desta versão. Codinome escolhido seguindo o mesmo espírito de `BFG9200` (7.7.1): **"HEXORCIST"** — Hex
  (do Editor Hexa) + Exorcist, porque a sessão inteira foi literalmente sobre "esconjurar" arquivos
  binários que antes caíam em "dados crus"/fantasmas sem nome, dando um formato e um nome de verdade pra
  cada um. Sem mudança de código nesta entrada — só documentação.
- **2026-08-08 — painel de controle do openMSX com 6 abas, F5 unificado com o console, codinome
  `TORRE DE CONTROLE` (`7.27.3`)**: sessão pedida pelo usuário pra transformar o controle remoto do
  openMSX (até então um console de comando avulso) num painel completo. **`Executar → BASIC` (F5) parou
  de abrir uma janela nova do openMSX a cada execução** — `RunOnOpenMSX()` passou a chamar
  `OMSX_LoadDisk()` (novo, `OpenMSXBridge.pbi`), que reaproveita a instância já aberta (troca o disco +
  reset) em vez de lançar um processo novo, unificando o que antes eram dois fluxos deliberadamente
  separados. Nova tela `Configurar → openMSX...` com os mesmos campos da aba "Emulador" de
  `Configurar → Basic Dignified...`, compartilhando os mesmos 4 procedimentos de gadget pra nunca
  divergir. `Executar → openMSX...` virou um `PanelGadget` de 6 abas — Console, Outros comandos
  (velocidade com Turbo segurando o mouse, Power/Reset/Pause, firmware, portas de joystick, Ren Sha
  Turbo), Vídeo (renderer/escala/Modo TV com as 5 opções reais do openMSX, efeitos estilo CRT com
  reset pro padrão de fábrica real, screenshot com numeração sequencial, LEDs + STOP + FPS), Volume
  (mixer com **descoberta dinâmica de dispositivo de som** — os nomes reais variam por cartucho/ROM
  conectado, confirmado ao vivo contra um openMSX de verdade antes de implementar, ex.
  `"Konami SCC+ Cartridge with expanded RAM (1)"` —, MIDI in/out), Input Text (área grande + Type/
  Clear) e Status Info (log passivo de tudo que o openMSX reporta). Detalhe completo em
  `docs/RELEASE_NOTES.md` e `docs/SPEC.md` (módulo 12). Codinome **"TORRE DE CONTROLE"** — o usuário
  escolheu entre algumas opções temáticas de "sala de controle" propostas.
- **2026-08-08 (mesma sessão) — auto completar + Arquivo → Salvar Tudo, codinome `PALPITEIRO`
  (`7.29.5`)**: pedido do usuário em três rodadas. Primeiro, **auto completar em abas MSX-BASIC/
  Dignified**: mostra sugestões (palavras-chave clássicas, instruções do Basic Dignified e variáveis já
  usadas no documento, coletadas ao vivo do texto) assim que a palavra digitada atinge um mínimo de
  letras configurável, com uma tela nova `Configurar → Basic Options...` (habilitar, mínimo de letras,
  caixa das sugestões). Navegação inteira é comportamento nativo do popup do Scintilla (Enter aceita a
  primeira opção, setas navegam, Esc cancela) — nenhuma tecla nova precisou ser interceptada, e não há
  conflito com o teclado WordStar/JOE (que só intercepta combinações com Ctrl). Segundo, o usuário
  perguntou se dava pra detectar estatisticamente se o usuário digita em maiúsculas ou minúsculas; a
  alternativa escolhida foi um campo de configuração explícito ("Como digitado"/"Sempre maiúsculas"/
  "Sempre minúsculas") em vez de heurística sobre o documento inteiro — mais previsível, e "Como
  digitado" já cobre o caso comum (`pri` sugere `print`, `PRI` sugere `PRINT`) sem precisar escanear
  nada. Terceiro, dois pedidos numa mensagem só: **os 87 wrappers `.NB_*` do NestorBASIC** entraram na
  lista de sugestões (fonte única com `Ajuda → NestorBASIC...`, via `NBHelp_Topics()\Wrapper` — nunca
  diverge da ajuda), e **auto completar chegou também nas abas Assembly (`.asm`)** — mnemônicos/
  registradores/diretivas do Z80 (`Z80Asm.pbi` ganhou `MnemonicList()`/`RegisterList()`/
  `DirectiveList()`/`OperatorWordList()`, expondo pra fora do módulo o vocabulário que já alimentava o
  destaque de sintaxe) e rótulos já definidos no documento (mesma regra clássica MACRO-80/Z80 do
  highlighter: primeira palavra da linha que não é reservada = rótulo), com tela própria
  `Configurar → Assembly...` (mesmos três campos de `Basic Options...`, mas independente — cada modo
  guarda sua própria preferência de caixa). Por último, **Arquivo → Salvar Tudo** (`Ctrl+Alt+S`): salva
  todas as abas abertas (na ordem, pedindo "Salvar como..." só pras que ainda não têm nome, sem travar
  as demais se uma for cancelada) e o projeto atual numa ação só — só grava o projeto se ele já tiver
  arquivo permanente ou se o projeto temporário tiver conteúdo de verdade (mesmo critério de
  `OfferSaveProject()`, mas sem o diálogo de confirmação — pedir "Salvar Tudo" já é a confirmação).
  Codinome **"PALPITEIRO"** — gíria brasileira pra quem "dá palpite" sem ser convidado, exatamente o que
  um motor de auto completar faz (e de bom humor, já que ele acerta na maioria das vezes). Detalhe
  completo em `docs/RELEASE_NOTES.md` e `docs/SPEC.md` (módulo 25, mais 1b para o Salvar Tudo).
- **2026-08-08 (mesma sessão) — fim do teclado WordStar/JOE, codinome `APOSENTADORIA` (`7.31.0`)**:
  usuário pediu pra trocar o jeito de digitar do editor principal pelo padrão Scintilla/Windows (setas,
  `Ctrl+C/V/X/Z/Y`, `Home`/`End` etc.) — não usa mais WordStar/JOE/vim no dia a dia, prefere
  Helix/JetBrains/VSCode/Sublime/010 Editor. `editor/WordStarKeys.pbi` (subclass Win32, comandos de
  duas teclas, bloco marcado com destaque persistente, tela de ajuda em tela cheia) foi removido por
  completo, não só desligado por padrão. As únicas peças do modo antigo sem equivalente automático no
  Scintilla puro — Buscar, Buscar próxima, Substituir, Ir para linha — viraram um arquivo novo e
  portátil (`editor/EditorSearch.pbi`) com atalhos convencionais (`Ctrl+F`/`F3`/`Ctrl+H`/`Ctrl+G`,
  também no novo menu **Editar**). Arquivo/aba voltaram ao padrão (`Ctrl+N` novo, `Ctrl+S` salva,
  `Ctrl+W` fecha aba). `Ajuda → Editor...` (`editor/EditorHelpGui.pbi`) troca a antiga tela cheia por
  uma janela normal com a referência de atalhos, reaproveitando o motor de markdown de
  `GenericMdHelpGui.pbi`. Detalhe completo em `docs/RELEASE_NOTES.md`.
- **2026-08-08 (mesma sessão) — atalhos pro resto da IDE, codinome `ATALHO DE TUDO` (`7.31.1`)**:
  usuário pediu atalhos pras outras funções do editor pra não ficar preso navegando menu — 22 novos:
  `Ctrl+Alt+N`/`Ctrl+Alt+O` novo/abrir projeto; `Ctrl+Alt+I` caractere especial; `Ctrl+Alt+E`
  Configurar → Editor...; no menu **Executar**, `Shift+F5` Nestor Basic, `F6` renumerar,
  `Ctrl+Shift+F5` montar relocável, `Ctrl+Alt+F5` linkar, `F7` Editor Hexa, `F8` console openMSX,
  `F9`/`Shift+F9` ver MD/TXT; no menu **Criar**, `Ctrl+Shift+D` disco, `Ctrl+Shift+P` sprite,
  `Ctrl+Shift+A` alfabeto Graphos III, `Ctrl+Shift+G` som PSG, `Ctrl+Shift+T` SEE Tracker,
  `Ctrl+Shift+M` música, `Ctrl+Shift+2`/`0`/`1` Draw Screen 2/Screen 0/Screen 1; e `F1` abre
  `Ajuda → Editor...` (convenção universal de ajuda). Os itens menos usados do menu **Criar**
  (Alfabeto Aquarela, Graphos III Screen 2, Screen 1+2, Biblioteca Z80, Assembly Sub Project)
  ficaram só no menu — não valia um 3º/4º modificador só pra caber mais uma tecla. `Ajuda →
  Editor...` (`F1`) ganhou as seções novas e a janela cresceu (`680×760`). Detalhe completo em
  `docs/RELEASE_NOTES.md`.
- **2026-08-08 (mesma sessão) — de 2 pra 7 temas, codinome `CAMALEÃO` (`7.31.2`)**: usuário achou
  os temas Escuro/Claro atuais feios e pediu variações mais atraentes (azul escuro, rosa,
  vermelho, verde, bege). Paletas desenhadas e aprovadas num mockup HTML fora do PureBasic antes
  de virar código (iterar cor em CSS é muito mais rápido que recompilar o app a cada ajuste).
  Resultado: **Configurar → Editor...** agora tem 7 opções — **Grafite**/**Neve** (revisão dos
  dois atuais) mais **Azul Profundo** (Night Owl/Nord), **Rosé** (Rosé Pine), **Carmesim**
  (oxblood), **Floresta** (Everforest) e **Bege** (Solarized Light). `EditorCfg\Theme` virou um
  dos 7 IDs em vez de um booleano Dark/Light; `editor_settings.json` antigo migra sozinho. Também
  investigado (e documentado, sem implementar ainda): as outras janelas (SEE Tracker, editores de
  Alfabeto/Sprite/Som/Telas) usam cores próprias fixas e controles nativos do Windows — estender
  tema pra elas é um projeto à parte, arquivo por arquivo, separando cor de "chrome" de cor de
  "conteúdo" (ex.: paleta MSX real não pode mudar com o tema). Detalhe completo em
  `docs/RELEASE_NOTES.md`.
- **2026-08-08 (mesma sessão) — botões tematizados + ícones Nerd Font, codinome `NERD DE VERDADE`
  (`7.31.3`)**: usuário reclamou que os diálogos ainda pareciam "Windows 3.1" mesmo com os 7 temas
  — "aquele mar de botões cinza que estragam a aparência" (botão nativo do Windows ignora
  `Color_*`). Piloto no **Editor Hexa** (`F7`): os 16 botões da janela viraram imagens desenhadas
  na hora (fundo + borda na cor do tema, texto centralizado) em vez de chrome nativo. Usuário
  também pediu pra reaproveitar fontes `.ttf` baixadas/instaladas na interface, e ícones de verdade
  em vez de "ícones genéricos desenhados desleixadamente" — resultado: os botões já usam a mesma
  fonte escolhida em **Configurar → Editor...** em vez de "Segoe UI" fixo, e um novo combo **Fonte
  de ícones** (mesma tela) troca o texto dos botões por glifos reais de uma Nerd Font quando
  configurado (com tooltip mostrando o nome ao passar o mouse; sem fonte escolhida, continua
  mostrando texto normalmente). Os 15 codepoints usados foram conferidos ao vivo contra o
  `glyphnames.json` oficial do projeto Nerd Fonts antes de entrar no código — achado real no
  processo: um resumo de IA de uma busca web errou um codepoint (`fa-plus_square` como `U+F055` em
  vez do `U+F0FE` real), só pego porque o JSON bruto foi conferido depois. Vale só pro Editor Hexa
  por enquanto; as outras ~10 janelas de diálogo ficam pra uma próxima rodada. Detalhe completo em
  `docs/RELEASE_NOTES.md`.
- **2026-08-08 (mesma sessão) — o mesmo formato de botão em toda a IDE, codinome `ADEUS WINDOWS
  3.1` (`7.31.4`)**: usuário gostou do piloto no Editor Hexa e pediu pra replicar em todos os
  diálogos/módulos. 293 botões em 33 arquivos convertidos numa sessão só (267 mecanicamente de
  `ButtonGadget`→`ThemedButton`, mais de 140 deles ganhando ícone Nerd Font verificado e tooltip),
  40 janelas ganharam `SetWindowColor(Win, Color_AppBg)` (antes ficavam brancas/cinzas nativas
  destoando do editor tematizado). O que nasceu específico do Editor Hexa (`HexEd_*`, `7.31.3`)
  virou `editor/ThemedButtons.pbi` — módulo compartilhado (`Macro ThemedButton()`, constantes
  `#Icon_*`) usado por todos os 33 arquivos, incluindo o próprio Editor Hexa migrado pra ele (sem
  duplicar código). Achado real de arquitetura no processo: quase todos os diálogos são incluídos
  bem no topo de `BadigEditor.pb`, antes de `Global Color_*`/`Structure EditorSettings` existirem
  (`EnableExplicit` + `XIncludeFile` textual exige declaração antes do uso) — resolvido movendo só
  essas poucas linhas de `Structure`/`Global` pro topo do arquivo, mesmo idioma dos `Declare` de
  procedure que já ficavam lá por motivo parecido, sem precisar reordenar os 33 `XIncludeFile`
  existentes. Nenhuma das ~400 edições foi manual — três scripts Python descartáveis (parsing de
  parênteses balanceados, não regex ingênuo) fizeram a conversão mecânica, com recompilação a cada
  rodada pra pegar erro cedo. Detalhe completo em `docs/RELEASE_NOTES.md`.
- **2026-08-09 — revisão geral: bugs, coesão de módulos, performance e temas, codinome `PENTE FINO`
  (`7.33.1`)**: sessão de
  auditoria ampla (7 revisões paralelas por área do código) seguida de correção. 8 bugs reais
  corrigidos, entre eles: fechar uma aba não-ativa trocava o documento visível errado; vazamento de
  handles GDI em dois editores gráficos; `ProjectDB::SaveAs` podia abandonar o projeto silenciosamente
  se o reabrir falhasse; `MSXDisk::ExtractFile` reportava sucesso numa extração truncada; downloads
  parciais deixavam lixo no diretório temporário; vazamento de buffer em `Z80Lib::CreateOrAddLibrary`;
  thread do pipe do openMSX nunca fechada; loop labels aninhados sem limite no pré-processador podiam
  corromper heap. Coesão: helper de janela compartilhado (`OpenModelessChildWindow`/
  `CloseModelessChildWindow`) extraído e migrado em 35 arquivos, ~150 linhas de boilerplate repetido a
  menos; hit-test de paleta e `FontDownloader` desduplicados. Performance: tokenizer deixou de ser
  O(n²) por linha; redraw de glifo em Screen0/1/12 e o redraw do Graphos/Screen2 otimizados. **Achado
  maior da sessão**: os 7 temas (desde `7.31.2`) tinham o modo escuro nativo do Windows sempre
  desligado — 8 pontos comparavam contra um `"Dark"` legado que a própria migração pros 7 temas já
  tornava inatingível, deixando barra de título/rótulos/campos de texto sempre com chrome nativo claro
  do Windows, mesmo nos 5 temas escuros. Corrigido com `EditorCfg_ThemeIsDark()` (`EditorSettings.pbi`)
  e tratamento de `WM_CTLCOLORSTATIC` (rótulos ficavam sem essa cobertura desde sempre, achado
  documentado como "abandonado" no próprio código) — confirmado com screenshot real da IDE rodando
  contra um tema escuro, não só leitura de código.
- **2026-08-09 (mesma sessão) — `Configurar → MSXBas2Rom...` redesenhada (`7.33.2`)**: pedido explícito
  do usuário — reforçou que o `msxbas2rom` nunca é incorporado ao projeto, é sempre um `.exe` externo
  chamado por caminho. O único botão "Baixar" (que baixava executável + Ajuda juntos) virou três
  controles independentes: **"Baixar versão mais recente"** (`MsxBas2Rom_DownloadExe()`) baixa só o
  executável da release mais atual do GitHub pra `tools/msxbas2rom/` (subpasta da instalação do
  msxbasica); um **campo de caminho editável** com botão "..." cobre o caso de o usuário já ter o
  `msxbas2rom` instalado em outro lugar, pré-preenchido com o local onde a IDE baixou (ou, se ainda
  vazio, com o resultado de uma busca na pasta padrão) e só persistido no `Salvar`/`Cancelar` da janela;
  e **"Atualizar documentação"** é por ora um placeholder proposital que só mostra uma mensagem de
  status — a geração de Ajuda a partir da wiki oficial (extraída do botão único antigo) fica pro próximo
  passo.
- **2026-08-09 (mesma sessão) — "Atualizar documentação" implementado, guia de referência prático
  (`7.33.3`)**: pedido explícito do usuário — baixar o conteúdo de
  `github.com/amaurycarvalho/msxbas2rom/wiki/Documentation` e estruturar dentro de **Ajuda →
  MSXBas2Rom...** com a mesma organização da wiki real do projeto. Clonei
  `amaurycarvalho/msxbas2rom.wiki.git` pra ler a estrutura de verdade em vez de adivinhar: `Home.md`
  (tabela "Quick Reference") e `Documentation.md` (hub "Reference Guide", 12 sub-páginas) definiram os
  três grupos baixados — **Primeiros passos** (visão geral/instalação/primeiros passos/uso), **Guia de
  referência** (as 12 páginas do hub: limitações de compilação, diretivas de recursos, comandos/funções
  estendidos, suporte a música/MTF/nMSXTiles/Tiny Sprite, integração VSCode + manual de configuração
  manual, depuração com openMSX, arquitetura do compilador, como obter ajuda) e **Exemplos** — 19
  páginas no total, mais o `-h` do executável configurado. `Games`/`Contributing`/`Branding` ficaram de
  fora de propósito (conteúdo de comunidade/créditos, não guia de uso do dialeto, conforme pedido do
  usuário). Bug em potencial evitado antes de acontecer: links internos da wiki (`[Instalação](Install)`,
  forma normal de link relativo entre páginas do GitHub) são reescritos pra URL absoluta
  (`MsxBas2Rom_RewriteWikiLinks()`) antes de salvar — sem isso, o clique (que a janela de Ajuda genérica
  manda cru pro `explorer.exe`) tentaria abrir um arquivo local inexistente em vez da página real,
  inclusive pras páginas propositalmente não baixadas.
- **2026-08-09 (mesma sessão) — fonte grande/desalinhada em TODA janela de Ajuda (`7.33.4`)**: bug
  reportado pelo usuário testando a nova Ajuda do MSXBas2Rom ("a fonte do HELP está muito grande, o
  texto aparece desalinhado, quebra em linhas desconexas") — mas a causa era comum às **8** janelas de
  Ajuda da IDE, não só a nova. `NBHelpGui_SetupStyles()`/`GenMdHelp_SetupStyles()` (as duas bases
  compartilhadas por Nestor Basic/MSX BASIC/Basic Dignified/SEE Tracker/openMSX/Editor/MD Viewer/
  MSXBas2Rom+N80) renderizavam o corpo do texto (prosa) com a fonte do **editor de código** do usuário
  (`EditorCfg\FontName`/`FontSize`) — tipicamente monoespaçada por design, o que faz prosa parecer maior
  do que o tamanho configurado e quebrar linha (`SC_WRAP_WORD`) com muita mais frequência do que uma
  fonte proporcional do mesmo tamanho nominal. Só ficou óbvio agora porque o conteúdo baixado da wiki
  tem parágrafos de prosa de verdade, ao contrário da maioria dos outros Helps (escritos à mão, já mais
  compactos). Corrigido com Segoe UI 10pt fixo pro corpo do texto no Windows (desacoplado do
  `EditorCfg` do usuário), mesmo "toque moderno" já usado nos controles nativos de toda janela
  secundária (`App_ApplyWindowIcon()`).
- **2026-08-10 — cor própria pro vocabulário estendido do MSXBAS2ROM (`7.33.6`)**: pedido explícito do
  usuário — o destaque de sintaxe do MSXBAS2ROM (implementado em `2026-08-01`) reaproveitava as cores
  já existentes de statement/função/diretiva do MSX-BASIC/Dignified; agora as 3 categorias (`CMD
  TURBO`, `HEAP()`, `FILE`/`TEXT`...) caem todas na MESMA cor nova (`#Style_MsxBas2Rom`, negrito),
  numa família teal/ciano ajustada em cada um dos 7 temas pra não repetir nenhuma cor de sintaxe já
  usada. Só a cor mudou, o vocabulário reconhecido é o mesmo de antes. Pedido do usuário também deixou
  registrado o próximo passo (bem mais complexo, de propósito adiado): fazer o pré-processador Basic
  Dignified reconhecer as palavras-chave do MSXBAS2ROM como tal, em vez de deixá-las livres pra virar
  nome de variável.
- **2026-08-09 (mesma sessão) — exemplos reais de código em Ajuda → MSXBas2Rom..., codinome
  `BIBLIOTECA` (`7.33.5`)**: pedido explícito do usuário — baixar a pasta `demo/` oficial do
  `amaurycarvalho/msxbas2rom` (link direto `.../tree/master/demo`) e, se possível, também os jogos
  completos de `amaurycarvalho/msxbasic`, pro disco, navegáveis/legíveis dentro do Ajuda como exemplos
  de programação reais. Dois botões novos: **"Baixar exemplos (demo)"** baixa só a pasta `demo/` (zip
  do repositório inteiro filtrado por prefixo antes de extrair — código C++ do compilador nem chega a
  tocar o disco) pra `tools/msxbas2rom/demo/`; **"Baixar jogos completos"** baixa
  `amaurycarvalho/msxbasic` inteiro (zip pequeno, ~2,4 MB) pra `tools/msxbas2rom/games/` — 10 jogos MSX
  BASIC completos, cada um com seu próprio `README.md`. Ambos baixam TODOS os arquivos (imagens, ROMs,
  sprites, música), mas só `.bas`/`.md` entram na árvore de Ajuda, um grupo por pasta de jogo/demo
  (`"Demo: scroll1"`, `"Jogo: Fortknox"`...), preservando a estrutura real dos repositórios. Validei o
  algoritmo (extração filtrada + varredura recursiva) contra os zips reais dos dois repositórios num
  harness isolado antes de integrar: 81 arquivos/12 tópicos pro `demo/`, 317 arquivos/23 tópicos pro
  `msxbasic`, casos de borda conferidos (jogo sem `README.md`, arquivo `.bas` dentro de subpasta,
  extensão `.BAS` maiúscula). Abrir um `.bas` na Ajuda não passa mais pelo parser de markdown — um
  despachante novo (`GenMdHelp_RenderTopic()`) decide pela extensão e mostra código real verbatim
  (`GenMdHelp_RenderPlainCode()`), já que BASIC usa `**`/`` ` ``/`[]()` legitimamente e o parser de
  markdown corromperia a exibição. Três botões diferentes agora gravam tópicos no mesmo índice de Ajuda
  (`Atualizar documentação`/`Baixar exemplos`/`Baixar jogos`) sem se atropelarem
  (`GenMdHelp_MergeIndex()` — cada download só substitui os grupos que ele mesmo gera).
- **2026-08-10 — motor Dignified com modo MSXBAS2ROM, compilação pra ROM e config por projeto
  (`7.33.7`)**: pedido explícito do usuário — programas MSXBAS2ROM escritos em Dignified (labels,
  `DEFINE`, `FUNC`/`RET`) agora protegem o vocabulário exclusivo (`FILE`/`TEXT`, sub-comandos de `CMD`/
  `SET`/`GET`, `HEAP()`/`TILE()`/`TURBO()`...) contra o encurtamento automático de variáveis — antes,
  usar essas palavras como identificador virava candidato a renomeio (`TURBO` → `ZX`), corrompendo o
  programa. Decisão confirmada com o usuário: em vez de duplicar o motor Dignified inteiro (~2500 linhas
  testadas) num arquivo separado, ele ganhou um **modo** (`Dig_Preprocess(..., IsMsxBas2Rom)`) que
  reaproveita os mesmos 3 mapas de vocabulário já usados pelo destaque de sintaxe. `FILE`/`TEXT` (diretivas
  de recurso, confirmado na documentação oficial) saem sem número de linha, preservando a ordem que
  define o índice do recurso. Validado com um teste isolado: em modo clássico, `FILE`/`TURBO`/`HEAP`
  saíam renomeados e corrompiam o programa (bug real, confirmado); em modo novo, saem intactos. Novo
  **Executar → Compilar ROM (MSXBas2Rom)...** gera o `.bas` e chama o `msxbas2rom.exe` configurado de
  verdade (nenhum caminho existia antes pra isso — só o downloader). Também, pedido do usuário: nova
  **Configurar → Projeto...**, permitindo que Basic Dignified/N80/MSXBas2Rom usem uma configuração
  própria de cada projeto em vez da global — sem duplicar nenhuma das 3 telas existentes, só um
  parâmetro novo (`OverridePath`) que redireciona onde cada uma lê/grava.
- **2026-08-10 (mesma sessão) — projeto `.msxproject` autocontido/portátil (`7.33.8`)**: pedido explícito
  do usuário — levar só o arquivo de projeto de um PC pro outro e os fontes BASIC/Assembly "irem junto".
  O `.msxproject` já guardava uma cópia de cada aba salva, mas sem garantia de estar sempre fresca nem
  nada que reconstituísse os arquivos numa máquina nova. Agora, **"Salvar projeto"/"Salvar Tudo"/
  encerrar o programa** resincronizam o projeto com o conteúdo REAL do disco de todo fonte que ele
  conhece (`ResyncProjectDocumentsFromDisk()`); **abrir um projeto** cujo arquivo esperado não existe
  (o caso normal de outra máquina) extrai o conteúdo de volta pro disco, sempre ao lado do
  `.msxproject` sendo aberto — não do caminho absoluto antigo, que só fazia sentido na máquina original
  (`RestoreMissingDocumentsToDisk()`). Escopo intencionalmente limitado a fontes de texto (BASIC/
  Assembly) — sprites/telas/sons/músicas já vivem nativamente no SQLite. Dois helpers novos em
  `ProjectDB.pbi` (`ListDocumentPaths()`/`DeleteDocument()`), testados no harness de regressão do
  módulo (`ProjectDBTestCli.pb`) junto com todos os testes existentes.
- **2026-08-10 (mesma sessão) — opções de linha de comando do msxbas2rom na tela de configuração
  (`7.33.9`)**: pedido explícito do usuário, com a lista de flags colada direto de `msxbas2rom -h` —
  nova página "Opções de compilação" em `Configurar → MSXBas2Rom...` (e `Configurar → Projeto...`, de
  graça, já que é a mesma janela): modo de compilação (ROM simples/automático/4 variantes de MegaROM,
  `-c`/`-a`/`-x`/`-6`/`-7`/`-4`/`-k`), silencioso/debug (`-q`/`-d`), caminhos de entrada/saída (`-i`/
  `-o`), geração de símbolos de depuração em 4 formatos (`-s`/`--cdb`/`--symbol`/`--omds`), gravar
  números de linha no binário (`--lin`) e inicializar projeto VSCode (`--vscode`). "Compilar ROM" passa
  a montar esses argumentos de verdade (antes só passava o `.bas`, sem nenhuma flag). Os 4 flags só-leem-
  e-saem (`-h`/`-D`/`-H`/`-v`) ficaram de propósito como botões de ação única em vez de checkbox
  persistente — teriam como travar silenciosamente o botão de compilar se esquecidos ligados.
- **2026-08-10 (mesma sessão) — fim dos temas escuros, ícones por padrão, manifesto `/XP`, codinome
  `ADEUS ESCURIDÃO` (`7.33.10`)**: pedido explícito do usuário — a interface datada continuava
  incomodando mesmo depois de `PENTE FINO`/`ADEUS WINDOWS 3.1`, e o pior visual era justamente nos
  temas escuros: `ThemedButton` só recolore botões, então checkbox/combobox/listview/scrollbar
  nativos (chrome do Windows, sem como recolorir) ficavam com contraste ruim contra fundo escuro —
  contra fundo claro o mesmo cinza nativo passa despercebido. Três mudanças, todas reaproveitando
  infraestrutura que já existia:
  - **Só temas claros**: os 5 escuros (`Graphite`/`Navy`/`Rose`/`Crimson`/`Forest`) saíram; dois temas
    novos (`Mist` "Neblina", `Linen` "Linho") entraram ao lado dos 2 originais (`Snow`/`Paper`) pra
    manter 4 opções. `Snow` vira o novo padrão. `editor_settings.json` de instalações antigas migra
    sozinho: cada ID escuro removido mapeia pro claro de "família" mais parecida (`Navy`→`Mist`,
    `Rose`→`Linen`, `Crimson`/`Forest`→`Paper`, `Graphite`/legado→`Snow`) — `EditorCfg_ThemeIsDark()`
    fica sempre `#False` em vez de excluída (2 outros arquivos ainda chamam ela pra decidir quando
    acionar as APIs de modo escuro do Windows; sem tema escuro nenhum, esse código fica
    permanentemente inerte, o que é o comportamento certo).
  - **Ícone por padrão, sem configurar nada**: os 311 `ThemedButton()` da IDE já usavam uma Nerd Font
    quando uma estava configurada, mas isso sempre foi opt-in — `IconFontName` vinha vazio por padrão
    e ninguém tropeçava na tela que ativa isso. Agora `editor/fonts/SymbolsNerdFontMono-Regular.ttf`
    (Nerd Fonts, licença SIL OFL, só os glifos de ícone — sem letras, sobra a fonte de código
    escolhida) vem empacotado junto do executável (`build.ps1 -D` copia a pasta, igual `sample/`) e é
    registrado em memória (`AddFontResourceEx`, privado ao processo) automaticamente na inicialização,
    reaproveitando a mesma função que já carregava a pasta de fontes customizadas do usuário
    (`EditorCfg_LoadCustomFonts()`, agora fatorada em `EditorCfg_LoadFontsFromFolder()` chamada duas
    vezes: pasta empacotada + pasta do usuário). Novo campo `IconsEnabled` (booleano, separado de
    `IconFontName`) faz a distinção entre "sem preferência salva" (`IconFontName=""` → usa a fonte
    embutida) e "usuário pediu pra desligar de propósito" (`IconsEnabled=#False`) — sem isso não dava
    pra represenar "não, eu realmente não quero ícone" depois que vazio passou a significar "usa o
    padrão". Combo **Fonte de ícones** ganhou a opção **"(Padrão - ícones embutidos)"** ao lado de
    **"(Nenhuma - usa texto)"** e da lista de Nerd Fonts já instaladas.
  - **Manifesto `/XP` no `build.ps1`**: flag do `pbcompiler.exe` que embute a dependência do
    `comctl32` v6 (mesmo mecanismo por trás do antigo "Windows XP visual styles") — sem ela, os
    controles nativos não-tematizáveis citados acima renderizavam no estilo antigo/sem tema mesmo no
    Windows 10/11; não muda nada nos botões (já desenhados à mão, ver acima), só o resto.
  - Investigação prévia (não implementada agora, registrada aqui pra não se perder): PureBasic 6.10+
    tem um `WebViewGadget()` nativo (Chromium/WebView2 no Windows, cross-platform) com
    `BindWebViewCallback()`/`WebViewExecuteScript()` pra IPC bidirecional com HTML/CSS/JS — daria pra
    reconstruir a apresentação em HTML mantendo toda a lógica em PureBasic, sem DLL nem processo
    separado, mas é um esforço grande (~40 arquivos `.pbi` de diálogo virariam HTML) pro ganho
    puramente visual perseguido aqui; descartado a favor das 3 mudanças acima, bem mais baratas.
- **2026-08-10 (mesma sessão) — base de conhecimento MSX embutida no Ajuda, codinome `ACERVO VIVO`
  (`7.33.11`)**: pedido explícito do usuário, feito aos poucos ao longo da sessão — sete janelas de
  Ajuda novas (ver ["O que já temos"](#o-que-já-temos) para a lista completa e o que cada uma cobre),
  todas geradas por scripts de conversão descartáveis (Python, não versionados) a partir de fontes
  históricas reais: os 4 arquivos CHM do emulador RuMSX (`help/*.CHM` — `MANUALS.CHM`, `SOFTWARE.CHM`,
  `MSXBIOS.CHM`; `MSX.CHM` foi descartado por ser específico do emulador, fora do escopo do projeto),
  "The MSX Red Book" (Avalon Software/Kuma Computers 1985, edição Markdown de Gustavo Seidler) e o MSX2
  Technical Handbook (ASCII Corporation 1987, edição Markdown de Konamiman).
  - **Decisão sobre direitos autorais** (discutida explicitamente com o usuário antes de implementar):
    manuais técnicos antigos, há muito fora de catálogo e amplamente compartilhados pela comunidade MSX
    há décadas, foram reproduzidos como no original; conteúdo de autoria do próprio RuMSX (Lex Lechz)
    também foi reproduzido como está, por decisão explícita do usuário — mesmo padrão de risco já
    tolerado no projeto desde `MsxBasicDictData.pbi` (transcrição de um livro comercial de 1986,
    `docs/Linguagem_Basic_MSX.pdf`, commitado no repositório).
  - **Dois estilos de renderizador**, conforme o tipo de conteúdo: monoespaçado/sem quebra automática
    pra texto pré-formatado cheio de tabela ASCII/diagrama de bits (Manuais MSX, as 3 janelas de BIOS);
    proporcional com negrito/código/link pra prosa corrida (MSX-Basic/DOS/CP-M, Livro Vermelho, MSX2
    Technical Handbook).
  - **Links de verdade clicáveis** (Livro Vermelho e MSX2 Technical Handbook) — hotspot nativo do
    Scintilla (`SCI_STYLESETHOTSPOT`/`SCN_HOTSPOTCLICK`), único lugar do programa com isso; as outras
    janelas de Ajuda continuam só com árvore + busca (limitação conhecida do "mini-Markdown" comum).
  - **Figuras originais dos livros clicáveis** (53 do Livro Vermelho, convertidas de SVG pra PNG com
    ImageMagick; 84 do MSX2 Technical Handbook, já PNG no repositório de origem) — abrem num popup com
    `ImageGadget`, mesmo link clicável dos parágrafos, prefixo `"img:"` no anchor.
  - **3 bugs reais achados e corrigidos durante os testes ao vivo** (nenhuma dessas janelas foi
    considerada pronta sem rodar de verdade): heurística de "endereço+nome" confundindo rótulos de bit
    (`b7`/`b6`...) com endereço de rotina no BIOS; parser tratando item de lista aninhado do Livro
    Vermelho (indentado com 4 espaços, igual bloco de código) como código em vez de link; título
    duplicado na tela (uma vez renderizado, outra como texto puro `"## Título"`) nas janelas
    monoespaçadas.
  - **Achado novo de compilador**: `pbcompiler.exe` rejeita bytes de controle crus (`Chr(1)` etc.)
    dentro de literais de string — `"Literal string not terminated"` — mesmo com a string
    aparentemente bem formada; caiu pra sentinelas ASCII imprimível (`"[[["`/`"|||"`/`"]]]"`). Guardado
    na memória do projeto.
  - **Total**: 1356 + 973 + 597 + 359 + 33 + 18 + 2 ≈ **3300+ tópicos** navegáveis, mais de 130 imagens,
    tudo offline/embutido no executável (sem depender de internet depois de gerado).

- **2026-08-11 — terceiro assembler suportado: asMSX (`7.33.13`, "TRIPLA MONTAGEM")**: pedido explícito
  do usuário — [asMSX](https://github.com/Fubukimaru/asMSX), ao lado do assembler nativo (`Z80Asm.pbi`) e
  do N80/Nestor80 externo (`N80Support.pbi`), sem se sobrepor a nenhum dos dois. **Configurar → asMSX...**
  (`editor/AsmsxSupport.pbi`): caminho do executável editável (+ "..." pra apontar pra uma instalação já
  existente) e "Baixar versão mais recente" — diferente do N80/MSXBas2Rom, o asMSX publica um único
  executável avulso por SO/arquitetura em `releases/latest` (não um `.zip`), novo helper
  `ExtTool_DownloadFile()` (`ExternalToolDownload.pbi`) mais simples que
  `ExtTool_DownloadAndExtractZip()`, com `chmod +x` explícito fora do Windows. **Ajuda → asMSX...**
  (`editor/AsmsxHelpData.pbi`/`AsmsxHelpGui.pbi`): o manual oficial (`asmsx/doc/asmsx.md`, cópia local
  gitignored igual `badig/`/`nestor80/`) **baked no `.exe` em tempo de compilação** (script descartável
  `convert_asmsx.py`, 27 tópicos em 2 grupos), não baixado em runtime como N80/MSXBas2Rom — o manual já é
  Markdown limpo sem nenhum link interno, então a janela reaproveita `GenMdHelp_RenderMarkdown()` direto,
  sem precisar da infraestrutura de âncora que o Livro Vermelho/MSX2 Technical Handbook (módulo 30)
  tiveram que construir. **Arquivo → Novo asMSX...** (`AsmsxTemplateText()`): cabeçalho de comentário +
  diretivas `.BASIC`/`.ORG` pertinentes pra um programa MSX típico carregável via `BLOAD"...",R`, citando
  a diferença de sintaxe mais visível do asMSX (colchetes `[ ]` em vez de parênteses pra endereçamento
  indireto). Verificado com build `/CONSOLE` descartável + `PostMessage(WM_COMMAND)` pelos IDs de menu +
  captura real de tela das 3 janelas novas. Ver `docs/RELEASE_NOTES.md`/`docs/SPEC.md` módulo 18 para o
  detalhe completo.
- **2026-08-11 (mesma sessão) — `Executar → Montar Fonte asMSX...`**: pedido explícito do usuário —
  faltava um jeito de efetivamente montar chamando o executável de verdade (paralelo ao já existente
  **Executar → Compilar ROM (MSXBas2Rom)...**). `AssembleAsmsxFromActiveTab()` (`BadigEditor.pb`) exige
  aba `.asm` ativa, sempre pede pra salvar num arquivo real primeiro (o asMSX só assembla arquivo em
  disco, nunca sobrescreve silenciosamente o já aberto) e roda o executável via `Asmsx_AssembleFile()`
  (`AsmsxSupport.pbi`, `RunProgram`+`ProgramExitCode()`, mesmo idioma de `MsxBas2Rom_CompileToRom()`) —
  ao contrário do MSXBas2Rom, não tenta prever o caminho de saída esperado, já que o tipo/nome do arquivo
  gerado pelo asMSX vem de diretivas dentro do próprio fonte (`.BASIC`/`.ROM`/etc.), não de uma flag da
  IDE. `AsmsxSettings` (`editor/AsmsxSupport.pbi`) ganhou os 4 campos correspondentes às opções de linha
  de comando do manual (seção 1.5.1): `-z`/`-s`/`-vv`/`-o`, expostos em **Configurar → asMSX...** (janela
  cresceu de 336px pra 500px de altura pra caber os 3 checkboxes + campo de saída). **Configurar →
  Projeto...** ganhou uma 4ª aba "asMSX" (`ProjectSettingsGui.pbi`), réplica mecânica das outras 3 já
  existentes (Basic Dignified/N80/MSXBas2Rom). Verificado com o mesmo build `/CONSOLE` descartável +
  captura de tela de sessões anteriores, incluindo o caminho de erro ("configure o executável primeiro").

- **2026-08-11 (mesma sessão) — Mamute Assembler, monitor estilo anos 80 (`7.33.15`, "TERMINAL
  PRE-HISTORICO")**: pedido do zero pelo usuário — uma ferramenta nova, inspirada nos montadores de
  linha de comando dos computadores de 8 bits dos anos 80 (referência direta: o **MegaAssembler** do
  próprio usuário, que quer portar um subconjunto pequeno dos comandos dele, aos poucos, sessão a
  sessão). **Executar → Mamute Assembler...** (`editor/MamuteAssemblerGui.pbi`): janela "terminal"
  (fundo preto, texto monoespaçado verde, fora do tema claro da IDE de propósito) com um prompt `MON>` -
  `EditorGadget` somente-leitura como scrollback + `StringGadget` de entrada, Enter submete (mesmo
  idioma já comprovado em `OpenMSXConsoleGui.pbi`). Escopo desta versão é deliberadamente mínimo, por
  pedido explícito ("por hora não vamos fazer nada, apenas uma tela com um prompt simples"): só **um**
  comando, `BA`/`QUIT`, que encerra a janela — `MamuteGui_Dispatch()` isola os comandos num `Select` só,
  ponto de extensão único pras próximas sessões. Achado real: `App_StyleChildCallback` (`BadigEditor.pb`)
  força a fonte Segoe UI em todo controle nativo de qualquer janela no primeiro repaint, sem opção de
  desligar por janela — a fonte monoespaçada é reaplicada de novo logo antes do loop de eventos pra
  vencer essa corrida. **Ajuda → Mamute Assembler...** (`editor/MamuteHelpData.pbi`/`MamuteHelpGui.pbi`)
  documenta cada comando já portado, mesmo layout de árvore+busca+conteúdo das outras janelas de Ajuda,
  reaproveitando `GenMdHelp_RenderMarkdown()` direto — mas com conteúdo escrito à mão (`MamuteHelp_Add()`),
  já que não existe manual externo pra converter (ao contrário do `Ajuda → asMSX...`). Verificado com
  build `/CONSOLE` descartável + `PostMessage(WM_COMMAND)` + captura real de tela das duas janelas.
- **2026-08-11 (mesma sessão) — simulação do sistema de slots do MSX + comando `PAGE`**: pedido explícito
  do usuário — fonte do Mamute Assembler aumentada e em **negrito** (Consolas 12pt → 14pt) pra melhorar
  legibilidade, e a primeira peça de simulação de hardware de verdade: 4 slots (0-3) × 4 páginas de 16KB
  cada (`0000-3FFF`/`4000-7FFF`/`8000-BFFF`/`C000-FFFF`, os mesmos endereços do MSX real) — 256KB de
  memória simulada (`MamuteMem()`, `editor/MamuteSupport.pbi`, novo arquivo), toda em branco por
  enquanto (`Dim` zera sozinho), por pedido explícito ("neste momento apenas crie toda a memória em
  branco"). **`Configurar → Mamute Assembler...`** configura o que existe fisicamente em cada um dos 16
  blocos (Vazio/RAM/ROM/BASIC + arquivo pra ROM/BASIC — carregamento de arquivo de verdade fica pra uma
  sessão futura) — lista de 16 linhas, editando tipo/arquivo da linha selecionada, persistido em
  `mamute_settings.json`. **Comando `PAGE`**: `PAGE` sozinho coloca as 4 páginas no slot marcado como
  RAM; `PAGE ?` mostra o mapeamento ativo (`MamutePageMap()`) sem mudar nada; `PAGE X,Y,Z,W` troca o
  slot comutado em cada página de uma vez — dois conceitos deliberadamente separados (configuração
  física fixa vs. mapeamento ativo agora, igual o registrador de slot primário de um MSX real).
  `Mamute_ResetPageMapToDefault()` calcula o "estado de boot" a partir da configuração salva, toda vez
  que a janela abre. **Achado de sintaxe do PureBasic**: `NewMap` não pode ser nome de variável comum
  (nem array `Dim`) — colide com a palavra reservada do comando `NewMap` (declarar `Map`), com erro de
  compilação enganoso; renomeado pra `ParsedSlots`. Verificado com build `/CONSOLE` descartável: `PAGE
  2,2,2,2`/`PAGE 9,9,9,9` (rejeitado, fora de 0-3)/`XYZ` (rejeitado) testados de ponta a ponta injetando
  texto no `StringGadget` via `WM_SETTEXT` direto (achado pela classe `Edit`/altura entre os filhos da
  janela) + `PostMessage(WM_COMMAND)` no atalho Enter — sem simulação de teclado real. A tela
  `Configurar → Mamute Assembler...` só foi verificada visualmente (a seleção de linha da lista não foi
  automatizada de propósito, `LVM_SETITEMSTATE` é um dos casos que a diretriz do projeto evita).
- **2026-08-11 (mesma sessão) — fonte do Mamute Assembler configurável (`7.33.16`)**: pedido explícito
  do usuário ("as fontes estão pequenas") — `Configurar → Mamute Assembler...` ganhou uma seção "Fonte
  do terminal": combo de fonte (reaproveita `EditorCfg_EnumMonospaceFonts()`, mesma enumeração já usada
  em `Configurar → Editor...`), campo de tamanho e checkbox "Negrito", persistidos no mesmo
  `mamute_settings.json`. `MamuteGui_EnsureFont()` deixou de carregar Consolas 14pt negrito fixo uma
  única vez — recarrega a partir de `MamuteFontName`/`MamuteFontSize`/`MamuteFontBold` toda vez que o
  monitor abre, liberando a fonte anterior (`FreeFont()`) pra não vazar um `HFONT` a cada abertura.
  Verificado com build `/CONSOLE` descartável — combo populado com fontes reais do sistema, valores
  batendo com a configuração de slots que o usuário já tinha salvo (confirmando de quebra que o `PAGE`
  "estado de boot" calcula certo contra dados reais).
- **2026-08-11 (mesma sessão) — divisão automática de arquivo BIOS+BASIC de 32KB (`7.33.17`)**: pedido
  explícito do usuário — em muitos MSX reais a BIOS e o BASIC vêm num único arquivo de ROM de 32KB (16KB
  de cada). Ao escolher um arquivo de 32KB pra uma célula `ROM` na Página 0 (a posição convencional da
  BIOS) em `Configurar → Mamute Assembler...`, a tela pergunta se é BIOS+BASIC combinados — respondendo
  **Sim**, a Página 0 fica com os primeiros 16KB (BIOS) e a Página 1 do mesmo slot fica com os últimos
  16KB (BASIC, tipo ajustado sozinho), o mesmo arquivo apontado nos dois pontos; **Não** (ou um arquivo
  de outro tamanho) funciona como antes. Continua livre pra trocar o arquivo da Página 1 na mão depois,
  mesmo após o "Sim" preencher automaticamente. `MamuteMemCell` (`MamuteSupport.pbi`) ganhou o campo
  `FileOffset` (0 ou 16384, deslocamento dentro do arquivo de onde começam os 16KB desta célula),
  persistido no `mamute_settings.json` — prepara terreno pro carregamento de arquivo de verdade (ainda
  pendente) já saber ler o pedaço certo. A coluna Arquivo da lista mostra "(últimos 16KB)" quando
  aplicável. **Não verificado via automação de UI** nesta sessão — o seletor de arquivo nativo do
  Windows (Common Item Dialog, Vista+) não expõe IDs de controle simples como os diálogos antigos,
  tornando automação por mensagem pouco confiável; verificado por revisão de código (mesmo padrão já
  comprovado de `WorkCells()`/`MamuteSettings_RefreshRow()` das outras edições da tela) mais um
  screenshot confirmando que a tela não regrediu.
- **2026-08-11 (mesma sessão) — comando `DM` (Despejo de Memória) do Mamute Assembler (`7.33.18`,
  "MEMORIA VIVA")**: pedido em detalhe pelo usuário — o primeiro comando que realmente lê/escreve os
  256KB simulados por trás do `PAGE`. **`DM <endereço>[,<deslocamento>]`** (endereço em hexa — agora o
  padrão de entrada em qualquer comando do Mamute Assembler) abre uma janela nova mostrando 128 bytes
  (16 linhas de 8) em hexa + ASCII lado a lado; `<deslocamento>` opcional (hexa com sinal, `-7F` a `80`)
  "criptografa" só a interpretação ASCII exibida (byte cru + deslocamento, módulo 256), o bloco hexa
  sempre mostra o byte cru. Cursor navegável por mouse (clique direto na célula, ou 4 setas pequenas na
  tela) e teclado (setas/`TAB` pra alternar hex↔texto); duas setas maiores (ou `PgUp`/`PgDn`) pulam
  ±128 bytes; botões `+`/`-` ajustam o deslocamento. `RETURN` abre um campo de edição pro bloco ativo,
  `RETURN` de novo confirma (hex: 1-2 dígitos vira o byte; texto: cada caractere digitado vira um byte,
  revertendo o deslocamento, escritos a partir do cursor que avança sozinho); `ESC` cancela a edição ou
  fecha a janela. Escrita só funciona em células mapeadas como RAM agora (`PAGE`) — ROM/BASIC/Vazio
  continuam somente-leitura. `MamuteSupport.pbi` ganhou `Mamute_ResolveAddress()`/`Mamute_ReadByte()`/
  `Mamute_WriteByte()` (endereço de CPU → Slot/Página/Offset via `MamutePageMap()`) e parsers hex com
  faixa validada. Novo arquivo `editor/MamuteDumpGui.pbi`: grade em `CanvasGadget`, técnica de desenho/
  clique adaptada de `HexEditorGui.pbi` (8 bytes/linha, sem scroll), navegação por teclado via
  `AddKeyboardShortcut` (ausente no Editor Hexa), edição em 2 estágios via `StringGadget` oculto (evita
  depender da API de teclado incerta do `CanvasGadget`). Achado real de PureBasic: uma `Macro` expandida
  em mais de um ponto do mesmo `Procedure` não pode ter `Protected` próprio dentro (duplica a
  declaração) — variável içada pra fora da macro nesse caso. Verificado de ponta a ponta (sem simulação
  de teclado real): `DM 8000` digitado + `PostMessage(WM_COMMAND)` nos atalhos de teclado, confirmando
  por captura de tela cada passo — inclusive editar um byte pra `42` com deslocamento `+05` mostrando
  `G` no texto (0x42+5=0x47), e que a escrita respeitou a configuração real de RAM do usuário.
- **2026-08-11 (mesma sessão) — comando `ZAP` (editor de setores de disco) do Mamute Assembler
  (`7.33.19`, "SETOR ZERO")**: pedido do usuário — "muito parecido com o `DM`", mas em vez da memória
  simulada, edita **setores de uma imagem `.dsk` de verdade**. **`ZAP <setor inicial>[,<deslocamento>]`**
  pede o arquivo `.dsk` (janela padrão de escolher arquivo) e abre a mesma grade do `DM` (128 bytes,
  hexa+ASCII, mesma navegação por mouse/teclado/`TAB`/`PgUp`/`PgDn`/`+`/`-`), lendo/escrevendo bytes
  crus por posição — sem interpretar a estrutura FAT12. Prioridade pra disquetes de 720KB, mas
  360KB/180KB também funcionam. Diferença chave em relação ao `DM`: editar um byte só muda a memória —
  grava no arquivo de verdade só com **`Ctrl+S`** ou o botão amarelo **"SALVAR SETOR"** (pedido
  explícito do usuário: "escolha uma tecla para salvar o setor no disco"), gravando cirurgicamente só o
  setor sob o cursor (`FileSeek`+`WriteData` de 512 bytes, não o disco inteiro). Título ganha `*`
  enquanto há alterações não salvas; fechar nesse estado pede confirmação. Novo arquivo
  `editor/MamuteZapGui.pbi`, adaptação quase literal de `MamuteDumpGui.pbi` trocando a fonte de dados
  (memória simulada → buffer carregado do `.dsk`) e sem a restrição de somente-leitura em ROM/BASIC
  (qualquer byte do disco é editável). Mesmo achado de `Macro`+`Protected` duplicado do `DM` apareceu de
  novo aqui (duas macros a mais, mesma correção). Achado real de automação de UI que corrige uma
  suposição anterior desta sessão: o `OpenFileRequester` nativo do Windows (Common Item Dialog) **é**
  automatizável de forma confiável via `GetDlgItem(hDlg, 1148)` (campo de nome) + `GetDlgItem(hDlg, 1)`
  (OK) + `BM_CLICK` — a suposição anterior (do trabalho de divisão de BIOS+BASIC de 32KB) de que não
  dava pra automatizar esse diálogo era prematura. Verificado de ponta a ponta com um disco real: criado
  via `--diskmanipulator create`, aberto no `ZAP` com automação completa do diálogo de arquivo, um byte
  editado e salvo com `Ctrl+S`, e o arquivo `.dsk` real lido de volta de forma independente (fora do
  app) confirmando o byte gravado no offset certo.
- **2026-08-12 — comando `SCR` (display gráfico da memória) do Mamute Assembler + carregamento real de
  ROM/BASIC (`7.33.20`, "OLHO NA ROM")**: antes de implementar o `SCR`, uma auditoria encontrou que
  `MamuteMem()` nunca tinha sido preenchida de verdade com o conteúdo dos arquivos ROM/BASIC
  configurados — ficava sempre em branco mesmo com um arquivo real apontado em `Configurar → Mamute
  Assembler...`. Nova `Mamute_LoadPhysicalMemory()` (`editor/MamuteSupport.pbi`) lê esses arquivos pro
  bloco certo de `MamuteMem()` (respeitando o `FileOffset` da divisão BIOS+BASIC de 32KB), chamada toda
  vez que a janela do Mamute Assembler abre. **`SCR <endinic>,<dx>,<dy>[,<modo>]`** mostra uma **tela
  FIXA de 256x192 pixels** (32x24 caracteres 8x8 — a mesma resolução de um SCREEN 2/1 real do MSX,
  preenchida a partir de `endinic`); `<dx>`/`<dy>` não mudam esse tamanho, definem um "azulejo" que
  ladrilha a tela inteira, e `<modo>` decide se os blocos de 8 bytes dentro de cada azulejo são lidos
  horizontal (`0`) ou verticalmente (`1`, a mesma ordem real de armazenamento de sprites do MSX). Uma
  **moldura de tamanho fixo — sempre 2x2 caracteres (16x16 pixels), sempre no canto superior esquerdo da
  tela** — é o cursor de edição: `TAB` liga/desliga seu contorno, `ENTER` amplia exatamente esses 16x16
  pixels num painel à parte (ao lado da tela normal) pra edição fina pixel a pixel. Teclas remapeadas a
  pedido explícito do usuário em relação ao manual original do MegaAssembler: `ESC` encerra, `E`
  mostra/oculta o endereço atual, setas fora de edição rolam o endereço base (esquerda/direita ±1 byte,
  cima/baixo ±1 azulejo inteiro — é assim que se traz outro pedaço da memória pra dentro da moldura
  fixa), setas em edição movem o cursor de pixel dentro da moldura, `ESPAÇO` inverte o ponto sob o
  cursor, `I`/`L` invertem/apagam os 16x16 pixels da moldura inteira de uma vez, `ESC` em edição cancela
  restaurando um snapshot tirado ao entrar. Se a moldura cair sobre ROM/BASIC/Vazio (não RAM), o painel
  de edição mostra o conteúdo real normalmente e aceita o toque em todas as teclas de edição — pedido
  explícito do usuário ("às vezes ampliamos pra ver algum detalhe da tela, não pra editar propriamente
  dito") — mas nada é gravado de verdade (mesma regra do `DM`), com um aviso amarelo "ROM - somente
  leitura (alterações não são gravadas)" abaixo da tela avisando disso. Botões na tela pra cada ação,
  mesmo espírito do `DM`/`ZAP`. Primeira versão implementada tratou `dx`x`dy`
  como o tamanho da própria tela (errado) — corrigida na mesma sessão depois que o usuário comparou
  contra capturas de tela reais do MegaAssembler original (`images/msxbasica-17.png`/`-18.png`), que
  mostraram o modelo certo: tela sempre fixa, moldura sempre 2x2 caracteres fixos. Achados reais de
  PureBasic no caminho: nomear um parâmetro de macro `DX`/`DY` colide (case-insensitive) com os campos
  `State\Dx`/`State\Dy`, corrompendo a expansão — resolvido renomeando pra `MoveX`/`MoveY`; e
  `Campo = Not Campo` (atribuição direta do operador `Not` a um campo de estrutura) não compila sob
  `EnableExplicit` — resolvido com `Campo = Bool(Not Campo)`. Verificado de ponta a ponta com dados
  reais: `SCR 1BBF,1,1` batendo visualmente com a captura de tela real (moldura no canto certo, tabela
  ASCII da ROM `cbios_main_msx1.rom` no topo da tela, "ruído" de dados não-fonte preenchendo o resto);
  `ENTER` sobre a configuração real do usuário (Slot 0/Página 0 = ROM) mostrou corretamente "ROM -
  somente leitura"; escrita testada num endereço RAM real (`SCR C000,1,1` + `ESPAÇO`) acendeu o pixel
  certo no painel de edição. No caminho, duas pistas falsas descartadas com evidência: a config real do
  usuário tinha o Slot 0/Página 0 apontando pro `cbios_logo_msx1.rom` (só o logo de boot, sem fonte) em
  vez do `cbios_main_msx1.rom`; e, separadamente, o executável de teste descartável tinha sido compilado
  fora de `editor/`, então não achava o `mamute_settings.json` real do usuário — nenhuma das duas era um
  bug no `SCR` em si.
- **2026-08-12 — histórico de comandos do Mamute Assembler, persistido no projeto (`7.33.21`, "MEMORIA
  DO MONITOR")**: pedido explícito do usuário — Setas Cima/Baixo no campo `MON>` navegam pelos comandos
  já digitados (Cima = mais recente, Baixo = volta pro presente), e o histórico "guarda inclusive entre
  sessões no arquivo de projeto (se não tem projeto aberto, salva silenciosamente no projeto padrão)".
  Reaproveita `ProjectDB::SetInfoValue`/`GetInfoValue` (tabela genérica `project_info`, mesma usada pelos
  3 booleans de override de "Configurar → Projeto...") — lista codificada como uma única string separada
  por `Chr(10)`, mesmo idioma de `StoreAsmSubProject`/`FetchAsmSubProject`. Comandos repetidos
  consecutivos não duplicam a entrada; limite de 200 comandos guardados. **Achado real corrigido no
  `ProjectDB` (afetava mais que o Mamute)**: `ProjectDB::EnsureOpen()` — usado pelo "projeto padrão"
  implícito quando nenhum projeto está aberto — sempre truncava esse arquivo temporário ao reabrir
  (`CreateFile()` incondicional em `OpenAt()`), apagando qualquer dado salvo nele na sessão anterior; ou
  seja, nenhuma configuração salva no projeto padrão (incluindo os 3 booleans de override já existentes)
  sobrevivia de verdade a fechar e reabrir o editor sem um projeto salvo. Corrigido pra só criar o
  arquivo do zero se ele ainda não existir — `Arquivo → Novo projeto...` continua sempre começando vazio
  (caminho separado, não afetado). Verificado de ponta a ponta com dois processos reais em sequência (não
  só revisão de código): 1º processo digita `PAGE ?`/`PAGE`, Cima/Cima/Baixo/Baixo confirmados navegando
  certo; processo encerrado e um novo aberto do zero — Cima já mostra `PAGE` de primeira, confirmando que
  sobreviveu ao reinício completo do aplicativo.
- **2026-08-12 — comando `SH` (busca de bytes/texto) do Mamute Assembler (`7.33.22`, "AGULHA NO
  PALHEIRO")**: **`SH [<endereço>],<byte>[,<byte>...]`** busca uma sequência exata de bytes em hexa pela
  memória simulada (deixar um `<byte>` vazio entre vírgulas = curinga, "qualquer byte");
  **`SH [<endereço>],'<texto>`** busca um texto testando automaticamente TODOS os deslocamentos possíveis
  (`-7F` a `80`, mesma faixa do `DM`/`ZAP`) — acha tanto texto puro quanto texto "cifrado" por um
  deslocamento fixo (truque comum em jogos antigos), calculando o deslocamento a partir do 1º caractere e
  confirmando o resto num único passo (rápido mesmo varrendo os 64KB inteiros). `<endereço>` omitido
  continua a busca a partir do último endereço ACHADO + 1 (só funciona depois de uma busca bem-sucedida
  nesta mesma sessão da janela). Busca varre a memória inteira com volta ao início (wraparound) se
  necessário. Diferente do `DM`/`ZAP`/`SCR`, não abre janela nenhuma — só mostra `ACHADO EM <endereço>`
  (bytes) ou `ACHADO EM <endereço> DESLOC <deslocamento>` (texto), ou `NAO ENCONTRADO`, direto no log do
  `MON>`. Verificado de ponta a ponta com dados reais: string `TESTE` escrita em RAM via `DM`, depois
  encontrada por `SH` tanto pelo endereço exato quanto continuando a busca (`SH ,'TESTE`, que dá a volta
  completa nos 64KB e reencontra a mesma ocorrência); busca por bytes com curinga (`SH C000,54,,53,54`)
  confirmada batendo mesmo com o byte curinga divergindo do valor real; busca sem correspondência alguma
  (`SH C000,FF,FF,FF`) encontrou de verdade uma ocorrência legítima em dados de ROM ao dar a volta pelos
  64KB, confirmando o wraparound funcionando corretamente contra dado real, não simulado.
- **2026-08-12 — comando `MS` (grava string) do Mamute Assembler (`7.33.23`, "TINTA INVISIVEL")**:
  **`MS <endereço>,[<deslocamento>],'<texto>`** grava um texto na memória simulada byte a byte, a partir
  de um endereço obrigatório, com deslocamento opcional (`0` se omitido, mesma faixa `-7F` a `80` do
  `DM`/`ZAP`/`SH`). Cada caractere vira `(código do caractere - deslocamento) & FF` - a MESMA fórmula do
  bloco de texto do `DM` ao editar - então texto gravado com deslocamento diferente de zero fica
  "cifrado" nos bytes crus, só reaparecendo legível se lido (`DM`) ou procurado (`SH`) com esse mesmo
  deslocamento. Sem janela - só confirma `GRAVADO EM <endereço>` no log do `MON>`. Escrita silenciosa em
  células que não sejam RAM (mesma regra do `DM`/`SCR` - `Mamute_WriteByte()` recusa, sem aviso
  separado). Verificado de ponta a ponta com dados reais: `MS C000,'nome` seguido de `SH C000,'nome`
  confirmou `DESLOC +00`; `MS C010,20,'nome` seguido de `SH C010,'nome` confirmou `DESLOC +20`
  (auto-detectado, provando o round-trip da "cifra"); `MS 0000,'ZWQK` (endereço ROM) seguido de
  `SH 0000,'ZWQK` retornou `NAO ENCONTRADO`, confirmando que a escrita em ROM foi mesmo recusada (não só
  a mensagem de sucesso, que sempre aparece independente do resultado real).
- **2026-08-12 — comando `LOAD` do Mamute Assembler (`7.33.24`, "INSERINDO O CARTUCHO")**: pedido
  explícito do usuário — diferente do `LOAD <arquivo>,B` do manual original (sem `CAS:`/`A:`, tudo
  interativo). Digitar `LOAD` sozinho abre uma janela normal de escolher arquivo; em seguida **sempre**
  pergunta em qual **Slot (0-3)** carregar (sugerindo o slot com RAM configurada como padrão, mas
  qualquer slot pode ser escolhido). O que acontece depois depende da extensão: **`.rom`** carrega a
  partir de `4000` (Página 1), ocupando também `8000` (Página 2) se tiver mais de 16KB (até 32KB - maior
  que isso não é suportado, precisaria de troca de banco); **binário com cabeçalho BLOAD real do MSX**
  (byte `FE` + endereços inicial/final/execução, 2 bytes cada) carrega automaticamente no endereço do
  cabeçalho; **binário sem cabeçalho** pergunta o endereço inicial antes de carregar. `.cas` ainda não é
  suportado (aviso explícito, sem tentar interpretar errado). Resultado sempre mostrado no log:
  `CARREGADO NO SLOT <slot> EM <endereço> - TAMANHO <tamanho> - FIM <endereço final>`. Grava DIRETO na
  memória física do slot escolhido (simula inserir um cartucho, não passa pelo `PAGE`/`Mamute_WriteByte`)
  e ajusta a configuração física das páginas tocadas (RAM ou ROM) só em memória - nunca grava em
  `mamute_settings.json`, então fechar e reabrir a janela do Mamute Assembler volta pra configuração
  salva de antes. Verificado de ponta a ponta com arquivos reais e automação completa dos diálogos
  (arquivo + slot + endereço, incluindo a técnica clássica `GetDlgItem`/`BM_CLICK` pro `OpenFileRequester`
  e o `InputRequester` do PureBasic): binário sem cabeçalho carregado no endereço pedido; binário com
  cabeçalho BLOAD carregado automaticamente no endereço certo; ROM de 16KB carregada no slot escolhido -
  confirmado não só pela mensagem de log, mas mapeando esse slot via `PAGE` e conferindo com uma captura
  de tela real do `DM` que o padrão de bytes do arquivo (`00,01,02...`) apareceu exatamente no endereço
  `4000` esperado.
- **2026-08-12 — `LOAD <nome>` sugere nome/filtro + comando `SAVE` do Mamute Assembler (`7.33.25`,
  "GRAVANDO O CARTUCHO")**: pedido explícito do usuário. **`LOAD`** ganhou um nome opcional
  (`MON>LOAD alfabeto.alf`) que só pré-preenche o campo de nome na janela de escolher arquivo e
  acrescenta a extensão dele ao filtro padrão (`*.alf;*.bin;*.rom`) — nunca carrega direto, a janela
  sempre confirma. **`SAVE [<nome>][,<endinic>,<endfim>[,<endexec>]]`** — o inverso do `LOAD`, com janela
  própria (`editor/MamuteSaveGui.pbi`, novo arquivo, estilo normal da IDE em vez do terminal preto/verde)
  em vez de gravar direto pela linha de comando: nome e endereços digitados no comando só pré-preenchem
  os campos da janela (endereço de execução vazio = igual ao inicial, mesma regra do manual original),
  que sempre abre pra revisão antes de gravar de verdade. Campos: **Arquivo** (editável + botão "..." com
  `SaveFileRequester`), **Slot (0-3)** (sugerido a partir do que o `PAGE` tem mapeado ativo agora na
  página do endereço inicial, editável pra qualquer slot), **Endereço inicial/final/execução**,
  **Formato** (`BIN` — cabeçalho real do BSAVE do MSX, byte `FE` + 3 endereços — ou `ROM` — formato
  próprio deste simulador, `AB` + os mesmos 3 endereços em vez do cabeçalho real de 16 bytes de um
  cartucho MSX; sugerido pela extensão `.rom` do arquivo, mas trocável livremente), e um checkbox
  **"Salvar sem cabeçalho"** que ignora o formato e grava só os bytes crus. Lê DIRETO de
  `MamuteMem(Slot,...)` pro range pedido, sem passar pelo `PAGE` — mesma filosofia do `LOAD`. Confirma no
  log do `MON>`: `SALVO "<arquivo>" - SLOT <slot> - <inicial>-<final> - TAMANHO <tamanho>`. Verificado de
  ponta a ponta com automação completa da janela (incluindo descoberta ao vivo dos IDs de controle da
  classe `InputRequester` — reaproveitado do `LOAD`) e **inspeção byte a byte dos arquivos gerados**: uma
  string gravada em RAM via `MS`, depois salva com `SAVE` no formato `BIN` — o arquivo resultante
  conferido byte a byte mostrou exatamente `FE` + os 3 endereços em little-endian + os bytes reais da
  string; salvo de novo com extensão `.rom` (formato auto-detectado) — arquivo conferido mostrou `41 42`
  ("AB") + os mesmos 3 endereços + os dados do slot lido.
- **2026-08-12 — comandos `M` e `S` do Mamute Assembler (`7.33.26`, "TECLADO NUMERICO")**: pedido
  explícito do usuário — mesma grade/navegação do `DM` (setas, `PgUp`/`PgDn`, `TAB`, botões, `+`/`-` de
  deslocamento), mas edição de byte por digitação DIRETA de dois dígitos hexa (sem campo de texto): o 1º
  dígito fica mostrado como `"3_"` esperando o 2º, que confirma o byte inteiro e avança o cursor sozinho
  — comportamento real do manual original do `M`/`S` ("0-F entram com um valor em hexadecimal"). `RETURN`
  volta a significar só "sai do comando"; `ESC` cancela um dígito pendente ou sai. O bloco de texto
  (ASCII) fica somente leitura neste comando (decisão deliberada pra evitar um problema não-testado:
  teclas de letra usadas pro `S` colidindo com a digitação normal num campo de texto nativo do Windows).
  **`M [<endereço>]`** usa `0-9`/`A-F` fixos; **`S [<endereço>]`** usa um **teclado numérico configurável**
  em `Configurar → Mamute Assembler...` (grade 4x4 rotulada `1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,0`, um campo
  de 1 caractere por dígito) — padrão `1,2,3,4,Q,W,E,R,A,S,D,F,Z,X,C,V` (mesmo layout clássico de teclado
  numérico usado em jogos/emuladores, as 4 fileiras da esquerda do teclado QWERTY). Endereço omitido em
  qualquer um dos dois continua de onde a janela ficou da última vez (memórias separadas pro `M` e pro
  `S`). Verificado de ponta a ponta com automação de UI e captura de tela real: byte `3F` seguido de `A5`
  digitados tecla-a-tecla no `M`, confirmados na grade (inclusive o `?` correto na coluna ASCII pro byte
  `3F`); janela fechada e reaberta com `M` sem endereço — reabriu exatamente no mesmo endereço com o
  mesmo conteúdo; `S` testado com o mesmo mecanismo compartilhado (`MamuteM_Open()` usado por ambos,
  parametrizado só pela tabela de 16 teclas); tela de configuração conferida por captura de tela real
  mostrando a grade 4x4 com os rótulos e os valores padrão exatos pedidos.
- **2026-08-12 — comando `C` do Mamute Assembler (`7.33.27`, "PREPARANDO O VISOR")**: **`C <modo>`**
  guarda qual dos 4 formatos de exibição (`0` = hexa+ASCII 4 bytes/linha; `1` = idem, 16 bytes/linha;
  `2` = só hexa, 8 bytes/linha, com checksum no fim de cada linha = soma dos bytes + byte baixo do
  endereço; `3` = idem, checksum só a soma) os comandos `D`/`P`/`V` (dump de memória formatado) vão
  usar — sozinho não mostra nada, só confirma o modo escolhido no log do
  `MON>` (`MODO 1: HEXA+ASCII, 16 BYTES/LINHA`, por exemplo). Estado dura só a sessão da janela (não
  persiste em `mamute_settings.json`, mesmo espírito volátil do `PAGE`). Precisa de espaço entre `C` e o
  número (`C 1`) — o `C1` colado do manual original não é reconhecido, já que todo comando aqui separa
  verbo de argumentos pelo primeiro espaço digitado (documentado explicitamente na Ajuda). Verificado de
  ponta a ponta: os 4 modos confirmados com a descrição certa; `C 4` (fora da faixa) e `C` (sem argumento)
  rejeitados com `?ERRO DE SINTAXE`; `C1` sem espaço confirmado caindo em `?COMANDO INVALIDO` como
  esperado (documenta a limitação, não a esconde).
- **2026-08-12 — comandos `D`/`P`/`V` + VRAM simulada no Mamute Assembler (`7.33.28`, "SAINDO NA
  IMPRESSORA")**: **`D <endinic>[,<endfim>]`** despeja a memória RAM/ROM (mapeamento `PAGE` ativo agora)
  formatada conforme o modo escolhido em `C`, direto no log do `MON>`; **`P`** é o mesmo despejo, mas "na
  impressora" — como o driver de verdade pra impressora dot-matrix Epson FX-80 fica pra uma sessão futura
  (projeto separado do usuário), por enquanto gera um **PDF A4 simples** (fonte Courier, cabeçalho com
  intervalo/modo, paginação automática a cada ~56 linhas) e abre "Salvar como" no final; **`V`** é igual
  ao `P`, mas lê da **VRAM simulada** nova em vez da RAM/ROM. Sem `<endfim>`, os três mostram só 16
  bytes a partir de `<endinic>` (nem `D`/`P`/`V` dão a volta pro `0000` como o `SH`/`M` fazem — passar do
  teto do espaço de endereços é `?ERRO DE SINTAXE`). Gerador de PDF (`Mamute_SavePdfListing()`,
  `editor/MamutePdf.pbi`, novo) monta os bytes do PDF 1.4 à mão (sem lib externa — PureBasic não tem
  uma nativa): Catalog/Pages/Page/Content-stream/Font, `MediaBox [0 0 595 842]`, tabela `xref` de 20
  bytes por linha, tudo ASCII puro (sem compressão/binário) porque o conteúdo é só dígitos hexa/texto.
  **VRAM simulada** (`MamuteVRAM()`, `editor/MamuteSupport.pbi`) é **endereçamento plano, sem
  banco/página** — deliberado: a VRAM de um MSX real nunca fica mapeada no espaço de endereços do Z80
  (é acessada pelas portas do VDP), então a restrição de 16 bits que vale pra RAM/ROM simplesmente não
  se aplica aqui. Tamanho configurável em `Configurar → Mamute Assembler...`: **16KB** (MSX1, mesmo
  teto que o MegaAssembler original enxergava), **128KB** ou **192KB** (MSX2/2+, ampliação desta
  ferramenta sobre o original). `VLOAD`/`VSAVE` (ou uma extensão do `LOAD`/`SAVE` existente pra
  carregar/salvar VRAM) ficam explicitamente pra uma sessão futura — pedido direto do usuário, VRAM
  começa sempre zerada por enquanto. Verificado de ponta a ponta com automação de UI real (sem simular
  teclado/mouse — `WM_COMMAND` pros atalhos/menu já registrados, `WM_SETTEXT`/`WM_GETTEXT` nos campos):
  `D` testado nos modos `0`/`1`/`2` (formatação e checksum corretos), endereço inválido rejeitado; `P`
  e `V` geraram PDFs reais que abriram corretamente e cujos offsets do `xref` foram conferidos byte a
  byte contra o conteúdo de verdade do arquivo (não só "o arquivo existe") — `V` também testado com uma
  listagem de 10 páginas (2KB/4 bytes-por-linha) confirmando a paginação automática; endereço de VRAM
  fora do teto configurado (`V 40000` contra o teto padrão de 16KB) rejeitado com `?ERRO DE SINTAXE`.
- **2026-08-12 — comandos `T`/`F` do Mamute Assembler (`7.33.29`, "TRANSFERE E PREENCHE")**: **`T
  <endinic>,<endfim>,<enddest>`** transfere (copia) o bloco de memória RAM/ROM entre `<endinic>` e
  `<endfim>` (mapeamento `PAGE` ativo agora) para o bloco do mesmo tamanho iniciado em `<enddest>`;
  **`F <endinic>,<endfim>,<byte>`** preenche esse mesmo tipo de bloco inteiro com um único byte repetido.
  Nenhum dos dois dá a volta pro `0000` (mesma regra do `D`/`P`/`V`) — `<endfim>` menor que `<endinic>`,
  ou um destino do `T` que passe de `FFFF`, são `?ERRO DE SINTAXE`. **`T` trata origem/destino
  sobrepostos corretamente** — copia de trás pra frente quando `<enddest>` vem depois de `<endinic>`
  (senão a cópia sobrescreveria bytes de origem ainda não lidos), de frente pra trás caso contrário,
  mesmo cuidado de um `memmove` de verdade. Escrita silenciosa em células que não sejam RAM nos dois
  (`Mamute_WriteByte` já recusa, mesma regra do `DM`/`MS`). Verificado de ponta a ponta com automação de
  UI real, usando endereços em `C000-FFFF` (confirmado RAM no config real do usuário pelos testes do
  `M`/`S` numa sessão anterior — `4000-7FFF` é ROM/BASIC nesse mesmo config, então não serve pra testar
  escrita): `F C000,C00F,AA` seguido de `D` confirmou os 16 bytes todos `AA`; `T C000,C00F,C100` copiou
  esse bloco corretamente; teste de sobreposição real (`MS` gravou `"ABCDEFGHIJ"` em `C200`, depois
  `T C200,C209,C205` — destino 5 bytes à frente da origem, dentro do mesmo bloco) confirmou o conteúdo
  final byte a byte exatamente como esperado (`C200-C204` intocado, `C205-C20E` = cópia certa), provando
  que a direção da cópia (trás pra frente) realmente evita a corrupção que uma cópia ingênua causaria;
  os 4 casos de erro (`<endfim>` menor nos dois comandos, byte de 3 dígitos no `F`, destino do `T`
  estourando `FFFF`) todos rejeitados com `?ERRO DE SINTAXE`.
- **2026-08-12 — comandos `G`/`X`/`R` do Mamute Assembler (`7.33.30`, "REGISTRADORES EM ESPERA")**:
  **`G <endinic>[,<brkpnt1>[,<brkpnt2>]]`** (execução de programas com breakpoints) e **`R
  [<offset>]`** (carregamento de programa assemblado) **ainda NÃO fazem nada de verdade** — pedido
  explícito do usuário ("tenho uma ideia de como executar programas, mas prefiro deixar para o
  final"; "o R depende do assemblador... apenas dê a informação na tela que vai ser implementado e
  mais nada"). `G` valida a sintaxe completa (endereço inicial obrigatório + até 2 breakpoints, tudo
  hexa de 4 dígitos) e confirma no log que entendeu o pedido, sem executar; `R` nem chega a validar
  argumento nenhum, só confirma que fica pra depois do assemblador embutido existir. Execução real de
  programas fica documentada como item em aberto em `docs/SPEC.md`, não como um "não implementado"
  genérico — o usuário já tem uma ideia de abordagem, só prefere deixar pro final do projeto. **`X
  [<reg>]`** já é funcional de verdade: sem argumento, mostra os 7 pares de registrador do Z80
  simulado (`AF`/`BC`/`DE`/`HL`/`IX`/`IY`/`SP`) de uma vez; com argumento, entra num modo de edição
  sequencial que aceita tanto um **par** (`AF`/`BC`/`DE`/`HL`/`IX`/`IY`/`SP`, editado como um valor
  único de 16 bits) quanto um **registrador de 1 byte isolado** (`A`/`F`/`B`/`C`/`D`/`E`/`H`/`L`, 2
  dígitos hexa) — os nomes de par diretos são uma extensão pedida explicitamente pelo usuário sobre o
  manual original (que só tem os bytes `A`-`L` mais `X`/`Y`/`S` como abreviação de `IX`/`IY`/`SP`).
  Caminha em sequência a partir do registrador escolhido, perguntando o novo valor de cada um via uma
  caixa de diálogo com o valor atual já preenchido — confirmar sem editar **mantém** o valor e
  continua pro próximo; apagar o campo (ou Cancelar) **para** a caminhada inteira ali. Registradores
  duram só a sessão da janela (mesmo espírito volátil do `PAGE`/`C`) — quando o `G` for implementado
  de verdade, vai carregar o Z80 simulado com esses valores. Verificado de ponta a ponta com
  automação de UI real, incluindo as caixas de diálogo nativas do `X` (encontrando o botão OK pelo
  texto, não por um ID de controle assumido — a primeira tentativa assumiu ID `1`/`IDOK`, que não é o
  ID real dos botões gerados pelo PureBasic, e travou o app inteiro num diálogo modal nunca fechado;
  corrigido buscando o botão pela classe `Button` + texto "OK"): `G` testado com 1/2/3 argumentos e
  com endereços/breakpoints inválidos (todos rejeitados corretamente); `R` confirmado ignorando
  qualquer argumento; `X IX` setou `IX=ABCD` e parou em `IY` (deixando `IY`/`SP` intactos); `X BC` na
  sequência setou `BC=1234`/`DE=5678` e parou em `HL` **sem tocar em `IX`** — prova real de que a
  parada por campo vazio realmente impede a caminhada de alcançar registradores seguintes, não é só
  "os valores calham de ficar iguais"; `X A` (modo byte) setou `A=AA` e parou em `F`, confirmado no
  par combinado `AF=AA00`.
- **2026-08-12 — comandos `L`/`LP` do Mamute Assembler: disassembler Z80 de verdade (`7.33.31`,
  "DESMONTANDO O CODIGO")**: **`L [<endinic>[,<endfim>]]`** disassembla a memória RAM/ROM (mapeamento
  `PAGE` ativo agora) direto no log do `MON>`; **`LP`** é o mesmo, mas gera um **PDF A4** (mesma infra
  do `P`/`V`) em vez de mandar pro log. Com os dois endereços, decodifica até ultrapassar `<endfim>`
  (instrução que começa dentro do intervalo entra inteira); só `<endinic>`, decodifica 10 instruções;
  sem nenhum, continua de onde o `L`/`LP` mais recente parou. Cada linha mostra endereço, bytes crus
  em hexa e mnemônico com operandos — saltos relativos (`JR`/`DJNZ`) já mostram o **endereço de
  destino absoluto**, não o deslocamento cru. Conjunto de instruções **completo**: toda a tabela
  documentada do Z80 (base, `CB`, `ED`, `DD`/`FD` indexados) mais as formas não documentadas mais
  estáveis/conhecidas (`IXH`/`IXL`/`IYH`/`IYL`, formas indexadas do `CB` com cópia-sombra, prefixos
  `DD`/`FD` encadeados) — pedido explícito do usuário ("você tem os dados do Z80 consigo", com
  referência a dois disassemblers open source, DASM80 e disark, pra consulta se necessário. Nenhuma
  tabela de opcodes reaproveitável existia no assemblador Z80Asm.pbi deste projeto (ele codifica
  mnemônico→bytes proceduralmente por família de instrução, não tem tabela estática bytes→mnemônico
  pra inverter) — construída do zero via a decomposição x/y/z/p/q clássica de decodificação do Z80.
  **Verificado exaustivamente**: harness de teste temporário (removido ao final, mesmo idioma do
  `--menuids` já usado nesta sessão) confirmou **151/151 casos pontuais corretos byte a byte**
  (cobrindo cada ramo x/z da tabela, saltos relativos com matemática de endereço absoluto — inclusive
  através de um prefixo `DD`/`FD` "desperdiçado" — substituição `IX`/`IY` de 8 e 16 bits, formas `(IX+d)`
  com deslocamento negativo, `DD CB`/`FD CB` indexado com cópia-sombra não documentada, prefixos
  encadeados, e a imunidade real do `HALT`/`EX DE,HL` ao prefixo) mais uma **varredura de completude
  dos 512 opcodes base+`CB`** confirmando que nenhum fica sem decodificação; depois verificado de
  ponta a ponta na UI real (`L`/`LP` contra conteúdo real de ROM e contra blocos conhecidos preenchidos
  via `F`, continuação sem endereço, erro de sintaxe, PDF gerado e conferido byte a byte). **Achado
  real de compilador/runtime durante a implementação** (documentado em `CLAUDE.md` pra sessões
  futuras): o padrão de parâmetro de saída `*Ptr.String` (documentado no PureBasic pra "devolver uma
  string por referência") travou com acesso inválido de verdade neste contexto específico — corrigido
  devolvendo o texto como retorno normal da função em vez de escrever por ponteiro de string.
- **2026-08-12 — janela do Mamute Assembler maior + fonte padrão maior (`7.33.32`, "TELA MAIOR")**:
  usuário reportou "`L 0,100` disassembla poucas instruções, e mostra coisas diferentes quando rodo de
  novo" — investigado a fundo com automação de UI real contra o ROM de verdade do usuário, repetido,
  e um teste de estresse crescendo o log a mais de 160 mil caracteres sem nenhuma perda — tudo batendo
  exatamente com o texto que o usuário colou. **Não era bug nenhum**: a listagem inteira (115 linhas
  pra `L 0,100`) estava correta e completa, só não cabia na janela antiga (720×480) sem rolar, e o
  usuário não tinha percebido a barra de rolagem. Corrigido aumentando a janela pra 960×640 (todos os
  gadgets já eram parametrizados por largura/altura, só precisou mudar a constante) e o tamanho padrão
  da fonte de 14 para 16 (negrito já vinha `#True` por padrão) — fonte/tamanho/negrito continuam
  configuráveis em `Configurar → Mamute Assembler...` (recurso que já existia antes desta sessão, só
  não era do conhecimento do usuário). Verificado com uma captura de tela real da janela redimensionada.
- **2026-08-13 — comando `EDIT` do Mamute Assembler: editor de linhas do programa-fonte Z80, estilo
  ZX-81 (`7.33.33`, "TELA DE VERDADE")**: nova janela (`MamuteEditGui.pbi`) pra digitar o programa-fonte
  no formato de linhas numeradas do MegaAssembler original (`NN Label: instrução operando ;comentário`).
  Passou por duas reescritas na mesma sessão a partir de feedback direto do usuário vendo cada versão
  rodando, até chegar num pedido bem específico: "um editor exatamente idêntico ao do ZX-81... exceto as
  teclas tokenizadas" (sem sentido com teclado de PC de verdade). Resultado final: a **listagem é a
  própria tela** (sem log de comandos, sem mensagem "OK"), um cursor **`>`** entre o número da linha e o
  comando marca a linha atual, **setas Cima/Baixo** navegam a listagem, **ENTER com o campo vazio** puxa
  a linha do cursor pra editar (**ENTER com o campo preenchido** grava, nova linha ou substituindo por
  número), **ESC** descarta uma edição pendente, a tela **rola meia-tela sozinha** quando enche
  digitando linhas novas, e o comando **`LIST`** relista do início, paginando tela-cheia-por-tela-cheia
  com uma pergunta "Rolar mais uma tela? (S/N)" quando o programa não cabe inteiro. Aceita mnemônicos
  Z80 reais (reaproveitando `Z80Asm::IsMnemonic()`, o assembler nativo do projeto) e as pseudo-
  instruções `ORG`/`DEFB`/`DEFW`/`DEFM`/`DEFS`/`EQU`/`END`. Mudança pedida explicitamente em relação ao
  manual original: números sem sufixo agora são **hexadecimal por padrão** (não mais decimal), pra
  ficar uniforme com o resto do Mamute — sufixos `H`/`B`/`D` continuam disponíveis (`D` agora é o único
  jeito de escrever decimal). Por hora só ACEITA/edita/lista o programa (`MamuteEditProgram()`) — a
  montagem de verdade (comando `A` do manual original) fica pra uma sessão futura. Validado com 26 casos
  de gramática/número num harness `/CONSOLE` descartável e, na versão final da janela, com automação
  real ao vivo (`PostMessage`/`WM_SETTEXT` + capturas de tela reais) cobrindo entrada de linha, erro de
  sintaxe, navegação por seta, puxar/editar/substituir uma linha, descarte por `ESC`, o auto-scroll de
  meia-tela e a paginação completa do `LIST`. Complemento na mesma sessão: **indentação automática da
  listagem** — label alinhado na coluna 0, instrução (com ou sem label) sempre alinhada na mesma coluna
  (1 "tab stop"), comentário sempre alinhado numa coluna própria mais à direita (3 tab stops) — afeta só
  o desenho da tela, o texto guardado/editado continua exatamente como foi digitado.
- **2026-08-13 — comandos `NEW`/`DELETE`/`RENUM`/`CHANGE`/`SAVE`/`LOAD` do `EDIT` do Mamute Assembler
  (`7.33.33`, "GERENCIAMENTO COMPLETO")**: gerenciamento completo do programa-fonte, seção "Programas
  em Assembly" do manual original — todos reconhecidos no mesmo campo, sem número de linha na frente
  (mesma convenção do `LIST`). `NEW` apaga o programa inteiro. `DELETE <lininic>[-[<linfin>]]` apaga uma
  linha, um intervalo, ou (`<lininic>-` sem final) até o fim do programa. `RENUM
  [<novali>[,<antigali>[,<incr>]]]` renumera a partir de uma linha antiga pra uma nova sequência, sem
  aplicar nada se colidir com uma linha não renumerada. `CHANGE '<string1>'[,'<string2>']` troca (ou
  apaga, se a segunda string for omitida) todas as ocorrências em qualquer linha, revalidando a sintaxe
  de cada uma antes de aplicar. `SAVE`/`LOAD` abrem os diálogos nativos de arquivo (sem digitar nome) e
  gravam/leem o programa num formato **ASCII próprio desta porta** (`.mza`) — não o formato binário
  proprietário do MegaAssembler original, cujo suporte fica pra uma sessão futura. Validado com
  automação real ao vivo cobrindo os seis comandos em sequência sobre o programa de exemplo do manual,
  incluindo um round-trip completo `SAVE` → `NEW` → `LOAD` conferido byte a byte.
- **2026-08-13 — comando `MERGE` do `EDIT` do Mamute Assembler (`7.33.33`)**: "igual ao MERGE do BASIC",
  pedido explícito do usuário — mostra o mesmo diálogo do `LOAD`, mas sem apagar o programa em memória:
  funde os dois, e uma linha do arquivo com o mesmo número de uma já existente sobrepõe a existente
  (mesma regra do `MERGE` do manual original do MegaAssembler). Reaproveita a mesma lógica de
  substituição-por-número já usada por toda gravação de linha — não precisou de código novo além de não
  limpar o programa antes de ler o arquivo. Validado ao vivo: programa em memória com 3 linhas + arquivo
  externo com uma linha sobrepondo e outra nova resultou exatamente no esperado (duas linhas mantidas,
  uma sobrescrita, uma adicionada).
- **2026-08-13 — comandos `SEARCH`/`LSEARCH` do `EDIT` do Mamute Assembler (`7.33.33`, "OLHOS NA
  LISTAGEM")**: busca uma string no programa e lista as linhas onde aparece — `SEARCH '<string>'`
  (entre aspas) busca literal, case-sensitive; `SEARCH <string>` (sem aspas) busca livre,
  case-insensitive. Um `SEARCH` bem-sucedido faz a tela passar a mostrar SÓ as linhas encontradas
  (navegáveis com as mesmas setas/`ENTER` de sempre) até digitar `LIST` ou qualquer outro comando, que
  volta ao programa completo automaticamente. `LSEARCH` faz a mesma busca, mas em vez de filtrar a
  tela gera um PDF com a listagem das linhas encontradas (mesma infraestrutura já usada por
  `L`/`LP`/`P`/`V`). Validado ao vivo cobrindo busca literal, busca case-insensitive, navegação dentro
  do filtro, saída do filtro via `LIST`, geração real de PDF (conferida byte a byte) e o caso sem
  ocorrências.
- **2026-08-13 — comandos `FIND`/`QUIT` do `EDIT` do Mamute Assembler (`7.33.33`)**: `FIND` é
  literalmente um apelido de `SEARCH` — no manual original ele só buscava no início de cada linha (mais
  rápido que o `SEARCH`, que busca em qualquer posição), uma otimização sem sentido num PC moderno, por
  isso a distinção não foi replicada. `QUIT` fecha a janela do `EDIT` e volta pro `MON>` sem apagar o
  programa da memória — como o programa já vive numa lista `Global`, "não apagar" já era o
  comportamento natural, sem precisar de nenhuma lógica extra; abrir `EDIT` de novo continua
  exatamente de onde parou. Validado ao vivo: `FIND` filtrando as mesmas linhas que um `SEARCH`
  equivalente, e um ciclo completo `QUIT` → reabrir `EDIT` confirmando o programa intacto.
- **2026-08-13 — comandos `A`/`A O` do `EDIT` do Mamute Assembler: monta de verdade (`7.33.34`, "O
  COMPILADOR")**: o programa-fonte digitado no `EDIT` agora pode ser realmente assemblado. Em vez de
  escrever um compilador do zero, reaproveita `Z80Asm.pbi` (o assembler Z80 nativo do projeto,
  compatível M80/Nestor80, já validado byte a byte contra o `N80.exe` real) — como o vocabulário que o
  `EDIT` já aceita é um subconjunto do que esse assembler entende, cada linha já é texto-fonte válido
  assim que se tira o número da linha, sem tradutor no meio. `A` sozinho só valida (erro com o número
  de linha certo e o cursor pulando pra ele automaticamente); `A O` (espaço obrigatório) além de
  validar **escreve o código-objeto direto na RAM simulada**, no endereço do `ORG`, resolvido pelo
  mapeamento de `PAGE` ativo no momento — se o `ORG` cai numa página mapeada pra um slot com RAM, é lá
  que os bytes vão parar; a opção de compilar direto pra um arquivo em disco fica pra uma sessão
  futura. Validado com dados reais: um programa pequeno assemblado corretamente (contagem de bytes e
  endereços conferidos à mão), um erro real de símbolo desconhecido detectado na linha certa, e depois
  do `A O`, os bytes lidos de volta de forma independente pelo comando `DM` do `MON>` — bateram
  exatamente com o esperado.
- **2026-08-13 (mesma sessão) — dois bugs reais corrigidos com o primeiro programa de verdade do
  usuário**: um número sem sufixo com letra hexa (`0a2`) era aceito ao digitar no `EDIT` (hexadecimal
  por padrão) mas rejeitado pelo assembler de verdade na hora de montar (que segue a convenção clássica
  M80/Nestor80, decimal por padrão) — corrigido traduzindo os números do `EDIT` pro formato que o
  assembler espera antes de montar, sem mudar o assembler em si (ele serve outros consumidores que
  dependem da convenção clássica). E um bug real, mais antigo, dentro do próprio assembler nativo do
  projeto: uma linha como `"CHPUT: EQU 0A2H"` (label com dois-pontos + `EQU`) definia o símbolo duas
  vezes, o que colidia consigo mesmo e gerava um falso "símbolo já definido" numa linha com uma única
  definição real — nunca tinha aparecido antes porque todo outro uso do assembler escreve `EQU` sem
  dois-pontos no label. Corrigido no motor, verificado sem nenhuma regressão na suíte de testes
  existente (67 + 7 casos) e byte a byte contra o assembler `N80.exe` real.
- **2026-08-13 (mesma sessão) — comando `MAP` do `EDIT` do Mamute Assembler (`7.33.34`)**: mostra o
  endereço inicial e final do código-objeto da última montagem bem-sucedida — `A` sozinho já basta (não
  precisa de `A O`), já que os dois calculam o mesmo intervalo de endereços por baixo, `O` só decide se
  além disso grava na RAM. Se nada foi montado com sucesso ainda, mostra uma mensagem pedindo pra rodar
  `A` (ou `A O`) primeiro em vez de um endereço sem sentido; `NEW` invalida o resultado guardado, já que
  apaga o programa que gerou aquele endereço. Validado ao vivo nos três casos: antes de qualquer
  montagem, logo depois de um `A` simples, e depois de um `NEW`.
- **2026-08-13 (mesma sessão) — listagem detalhada PASSO-1/PASSO-2 de `A`/`A O` (`7.33.35`)**: `A` agora
  mostra `PASSO-1` e depois `PASSO-2` (mesma sequência do Mega Assembler original) antes de montar de
  verdade, e a montagem bem-sucedida vira uma listagem coluna a coluna — número da linha, endereço (ou o
  valor de um `EQU`), até 4 bytes de código-objeto em hexa (linhas extras pra instruções/diretivas com
  mais de 4 bytes) e o conteúdo original da linha. A listagem entra no mesmo mecanismo de rolagem por
  tela cheia já usado pelo `LIST` (`Rolar mais uma tela? (S/N)`) em vez de duplicar a lógica de
  paginação, e funciona igual com `A` ou `A O` (a única diferença continua sendo se os bytes também vão
  pra RAM). `ORG`/`END` não geram linha na listagem por enquanto — decisão não confirmada com o usuário,
  fácil de mudar se for o comportamento esperado. Validado ao vivo: listagem de um programa de 12 linhas
  conferida byte a byte (incluindo uma string de 14 caracteres corretamente quebrada em 4+4+4+2), um
  programa de 50+ linhas forçando duas telas de rolagem com a numeração/endereços continuando
  corretamente na segunda tela, e `A O` mostrando a listagem junto com a confirmação de gravação na RAM.
  Suíte de regressão (67+7 casos) e comparação byte a byte contra o `N80.exe` real rodadas de novo sem
  nenhuma regressão.
- **2026-08-13 (mesma sessão) — opção `N` do comando `A`/`A O` (`7.33.36`)**: "opção N (por exemplo A O,
  ou A ON) não mostra os números de linha, de resto é igual" — pedido explícito do usuário. `N` é a
  opção do manual original que suprime a coluna de número de linha da listagem; combinável com `O` no
  mesmo bloco de opções, em qualquer ordem (`A N`, `A ON`, `A NO`), já que o manual original também junta
  as letras de opção coladas. Só a coluna do número da linha fica em branco — endereço, valor de `EQU`,
  bytes hexa e conteúdo da linha continuam exatamente iguais. Validado ao vivo: `A ON` mostrou a mesma
  listagem de sempre com a coluna de linha em branco e a confirmação de gravação na RAM; `A N` (sem `O`)
  mostrou a coluna em branco sem gravar nada; uma opção não implementada (`A P`, já implementada na
  entrada seguinte) continuou sendo rejeitada normalmente.
- **2026-08-13 (mesma sessão) — opção `P` do comando `A`/`A O`/`A N` (`7.33.37`)**: "o Modificador P do
  comando A gera a listagem na impressora, ou seja, no PDF, pode ser combinado com as outras opções por
  exemplo A NP, A ONP etc" — pedido explícito do usuário. `P` manda a mesma listagem que aparece na tela
  pra um PDF A4 (mesma infra já usada pelo `LSEARCH`/`L`/`LP`/`P`/`V` — nenhum driver de impressora real,
  só um PDF simples), combinável com `O` e `N` em qualquer ordem no mesmo bloco de opções (`A P`, `A NP`,
  `A ONP`). Como o PDF usa a mesma lista já formatada que vai pra tela, combinar com `N` já sai sem
  número de linha automaticamente, sem lógica extra. O diálogo "Salvar como" abre antes da mensagem de
  status final, e o resultado (nome do arquivo gravado, erro, ou nada se cancelado) é anexado a essa
  mensagem em vez de substituí-la — cancelar o diálogo é silencioso, igual a qualquer outro "Salvar
  como" do projeto. Validado ao vivo: `A ONP` gravou na RAM, escondeu os números de linha e salvou um PDF
  conferido byte a byte contra a listagem da tela; `A P` sozinho com o diálogo cancelado se comportou
  exatamente como um `A` sem `P` nenhum.
- **2026-08-13 (mesma sessão) — opção `I` do comando `A`/`A O`/`A N`/`A P` (`7.33.38`)**: "a I... funciona
  similar a O, salva em disco o arquivo, abre o diálogo de save, e salva o header &HFE, os endereços
  inicial, final e execução (já sugira no diálogo), o slot (já sugira os ativos no momento)... o binário
  é criado no formato para o BLOAD do BASIC ou LOAD do Mamute Assembler" — pedido explícito do usuário.
  `I` reaproveita a mesma janela do comando `SAVE` do monitor do Mamute Assembler (arquivo, slot 0-3,
  endereço inicial/final/execução, formato BIN com cabeçalho real do BSAVE do MSX), agora capaz de gravar
  o código-objeto recém-montado diretamente, sem precisar que `A O` tenha rodado antes — o slot ativo e
  os três endereços já vêm pré-preenchidos, tudo editável antes de gravar. Combina livremente com
  `O`/`N`/`P` no mesmo bloco de opções (`A I`, `A ONPI`). Validado ao vivo: `A I` salvou um arquivo
  conferido byte a byte — cabeçalho `FE` + endereço inicial/final/execução em little-endian, seguidos dos
  27 bytes exatos da montagem; `A ONI` com o diálogo de gravação cancelado continuou gravando na RAM e
  escondendo os números de linha normalmente, sem nenhum efeito colateral da opção cancelada.
- **2026-08-13 (mesma sessão) — opção `R` do comando `A`/`A O`/`A N`/`A P`/`A I` (`7.33.39`)**: "ela gera
  no final da listagem uma referência cruzada dos labels equ gera o valor e os endereços onde é usado, os
  labels mostra onde foram definidos e onde são usados" — pedido explícito do usuário, com um print real
  do MegaAssembler original de exemplo (`images/msxbasica-19.png`, usando o mesmo programa de teste já
  usado nesta sessão inteira). `R` acrescenta ao final da listagem uma linha por símbolo (ordem
  alfabética) mostrando o valor (constante `EQU` ou endereço de definição do rótulo — o mesmo layout
  serve pros dois) e todos os endereços onde ele foi referenciado, com até 4 por linha e continuação nas
  linhas seguintes se precisar. Isso exigiu um mecanismo novo no motor de montagem compartilhado
  (`Z80Asm.pbi`): toda vez que uma expressão referencia um símbolo já conhecido durante a passagem final
  de montagem, o endereço da linha que fez a referência é registrado — daí a referência cruzada é montada
  automaticamente ao final de qualquer montagem bem-sucedida. Validado ao vivo com o programa exato do
  print de exemplo: saída idêntica, símbolo por símbolo, valor por valor, endereço por endereço. Testado
  também com um símbolo referenciado 6 vezes (o print original só mostra casos de uso único) — o
  agrupamento em blocos de 4 endereços por linha e a integração com a rolagem de tela cheia funcionaram
  corretamente. Suíte de regressão completa rodada de novo sem nenhuma regressão.
- **2026-08-13 (mesma sessão) — opção `S` do comando `A`/`A O`/`A N`/`A P`/`A I`/`A R` (`7.33.40`)**: "ele
  gera ao final uma listagem dos labels em ordem alfabética e o endereço onde foram definidos, digo o
  endereço para onde apontam" — pedido explícito do usuário. `S` reaproveita a mesma tabela alfabética já
  construída pra `R` (entrada anterior), mostrando só nome e valor de cada símbolo, sem os endereços de
  uso — zero mudança no motor de montagem, só uma formatação diferente dos mesmos dados. Combina
  livremente com as outras opções (`A S`, `A RS`, `A ONPIRS`), aparecendo depois do bloco de `R` quando
  os dois estão ativos. Validado ao vivo: `A RS` mostrou os dois blocos na mesma listagem/rolagem, com a
  paginação cortando corretamente entre eles; `A S` sozinho mostrou a listagem simples de rótulos sem
  nenhum endereço de uso.
- **2026-08-13 (mesma sessão) — opção `D` do comando `A`/`A O`/`A N`/`A P`/`A I`/`A R`/`A S` (`7.33.41`)**:
  "e' identica a A S, porem a lista de labels e' por ordem de aparicao e nao alfabetica" — pedido
  explícito do usuário. Mesmo layout nome+valor de `S`, mas os símbolos aparecem na ordem em que foram
  DEFINIDOS no fonte, não em ordem alfabética. Isso exigiu um mecanismo novo no motor de montagem: o
  momento exato em que cada símbolo passa de "desconhecido" pra "definido de verdade" é registrado — e
  como a montagem varre o programa de cima pra baixo, essa é automaticamente a ordem de aparição no
  fonte, mesmo para símbolos referenciados antes de serem definidos (referência pra frente). Combina
  livremente com as outras opções, aparecendo depois do bloco de `S` quando os dois estão ativos.
  Validado ao vivo com um caso onde as duas ordens realmente divergem: `A DS` no programa de teste (onde
  `SALT` é definido antes de `PRINT` no fonte, mas viria depois alfabeticamente) mostrou claramente as
  duas ordens diferentes lado a lado — `S` alfabético (`CHPUT`/`PRINT`/`SALT`) e `D` por aparição
  (`CHPUT`/`SALT`/`PRINT`). Suíte de regressão rodada de novo sem nenhuma regressão.
- **2026-08-13 (mesma sessão) — opção `H` do comando `A`, combinada com `S` ou `D` (`7.33.42`)**: "mais
  um comando A H lista os labels na impressora, deve ser usado com o D ou S" — pedido explícito do
  usuário. `H` manda só a(s) lista(s) de labels (alfabética e/ou por ordem de aparição, conforme `S`/`D`
  estiverem ativas) pra um PDF separado — diferente de `P`, que manda a listagem inteira com o código.
  Usar `H` sozinho, sem `S` nem `D`, é rejeitado com uma mensagem explicando o motivo, já que não haveria
  nenhuma lista pra imprimir. Se `S` e `D` estiverem ativos junto com `H`, as duas listas vão pro mesmo
  PDF, separadas por uma linha em branco. Validado ao vivo: `A H` sozinho foi rejeitado corretamente;
  `A DSH` abriu o diálogo de salvar, e o PDF resultante continha as duas listas de labels (alfabética e
  por ordem de aparição) exatamente como aparecem na tela.
- **2026-08-13 (mesma sessão) — opção `/<offset>` do comando `A`, última desta série (`7.33.43`)**: "este
  comando compila o programa mas adiciona o OFFSET ao ORG para gerar em outro endereço" — pedido
  explícito do usuário. `A O/8000`, por exemplo, monta o programa como se todo `ORG` tivesse `8000`
  somado ao valor original — o programa inteiro se desloca de forma consistente (rótulos, saltos
  relativos, listagem), não só um resumo superficial de endereços. A opção combina com qualquer outra no
  mesmo bloco (`A O/8000`, `A ONR/1000`), e um offset ausente ou inválido é rejeitado antes de tentar
  montar. Validado ao vivo: `A O/1000` no programa de teste (`ORG 0C100H`) assemblou tudo em `D100-D11A`
  em vez de `C100-C11A`, com a referência interna `LD HL,PRINT` corretamente apontando pro endereço já
  deslocado, enquanto a constante `EQU` e o salto relativo continuaram intactos, como esperado.
- **2026-08-13 (mesma sessão) — release `paleobasic-v073343.zip`**: capítulo **Mamute Assembler** de
  `docs/MANUAL.md` reescrito do zero (cobria só `PAGE`/`DM`/`ZAP` antes, agora documenta o conjunto
  completo — `SCR`/`SH`/`MS`/`LOAD`/`SAVE`/`M`/`S`/`C`/`D`/`P`/`V`/`T`/`F`/`G`/`X`/`R`/`L`/`LP`/`EDIT` e
  todas as opções do `A`). **O executável mudou de nome**: `editor\BadigEditor.exe` →
  **`editor\PaleoBasic.exe`** (o arquivo-fonte `editor\BadigEditor.pb` continua com o mesmo nome —
  mudança cosmética no artefato final, `build.ps1`/`build.sh` já compilam com o nome novo por padrão).
  **Ícone e splash screen também renomeados**: `msxbasica.ico` → `paleobasic.ico`, `msxbasica.png` →
  `paleobasic.png` — verificado ao vivo (ícone na barra de título, splash screen na abertura). Pacote de
  distribuição gerado via `build.ps1 -D` e publicado como `paleobasic-v073343.zip`. Ver
  `docs/RELEASE_NOTES.md` para as notas de lançamento formais desta versão e das anteriores desde
  `7.33.32`.
- **2026-08-13 (sessão seguinte, máquina nova) — estudo de debugger visual Z80 para o Mamute Assembler,
  sem código**: pedido explícito do usuário, voltando ao escopo do monitor (não implementado ainda) —
  coluna de disassembly, registradores, stack/heap, minimapa de memória, step into/over/out. Escopo
  decidido: começar por um simulador de **Z80 puro**, sem tentar simular o MSX inteiro de cara. Usuário
  adicionou `fmsx/` (gitignored, código-fonte do **fMSX** de Marat Fayzullin) como material de estudo do
  núcleo Z80 e do hardware MSX. Estudo completo — peças já reaproveitáveis (disassembler nativo `L`/`LP`,
  memória/páginas simuladas, técnica de grade do `DM`), o que falta (núcleo de execução Z80 do zero,
  maior motor ainda por escrever no projeto) e um roteiro em 3 fases (debugger Z80-only nativo →
  reaproveitar o mesmo pipe do `OpenMSXBridge.pbi` para um debugger contra MSX real via protocolo de
  debug do openMSX, esforço menor do que parece já que o transporte já existe → simulador de MSX completo
  portado do fMSX, grande e provavelmente baixa prioridade) — registrado em `docs/SPEC.md`, módulo 32.
  Também: crédito a Marat Fayzullin/fMSX acrescentado em Agradecimentos abaixo, e `/fMSX/` adicionado ao
  `.gitignore` (não estava — achado real, a pasta apareceu como untracked pronta pra ser commitada por
  engano, junto de ROMs de sistema com copyright próprio e um fonte não-comercial incompatível com a
  licença GPL v3 deste projeto).
- **2026-08-14 — release `7.33.44` "KONPASSO"**: comando `G` do Mamute Assembler sai do estágio de
  estudo do módulo 32 (`docs/SPEC.md`) e vira debugger visual de verdade — **Fase 1** completa (simulador
  Z80 puro, sem VDP/PSG/FDC/BIOS). Núcleo de execução novo (`editor/MamuteZ80Cpu.pbi`) implementa a
  tabela **completa** de opcodes Z80 numa só leva (pedido explícito do usuário) — base, `CB`, `ED`
  (blocos `LDI/LDD/LDIR/LDDR/CPI/CPD/CPIR/CPDR/INI/IND/INIR/INDR/OUTI/OUTD/OTIR/OTDR`, `ADC`/`SBC
  HL,rr`, `RRD`/`RLD`, `LD I,A`/`LD A,I` etc.) e `DD`/`FD`/`DDCB`/`FDCB` (`IX`/`IY`, incluindo os
  indocumentados `IXH`/`IXL`/`IYH`/`IYL` e a exceção real do `EX DE,HL` nunca ser afetado pelo prefixo).
  Janela nova (`editor/MamuteDebuggerGui.pbi`), layout inspirado no **Konpass** (Nestor Soriano/
  Konamiman, mockup fornecido pelo usuário): disassembly (acompanha o PC por padrão, ou rola
  independente), registradores/flags editáveis (incluindo os campos novos — `PC`, par alternado
  `AF'/BC'/DE'/HL'`, `I`/`R`/`IFF1`/`IFF2`/`IM`, ampliando a `Structure MamuteGui_State` já usada pelo
  comando `X`), minimonitor de memória hex+ASCII editável (mesma técnica de grade do `DM`), pilha
  editável, mapa `PAGE`→`SLOT`→`TIPO`, e `Step Into`/`Step Over` (detecta `CALL`/`RST` e roda até o
  retorno)/`Step Out` (roda até o `SP` desempilhar acima do valor de entrada)/`Run` (até breakpoint/
  `HALT`, com teto de segurança contra loop infinito) — até 2 breakpoints. Harness de regressão novo
  (`editor/tools/MamuteZ80CpuTestCli.pb`, autocontido — duplica só a `Structure`/memória mínima em vez de
  arrastar a GUI inteira do Mamute pra dentro de um `/CONSOLE`) com 60 verificações (ALU/flags incl.
  overflow e `DAA`, `LD`/`PUSH`/`POP`/`CALL`/`RET`, `StepOver` sobre `CALL`, `IX`+`DDCB` — `SET`/`BIT`
  indexado —, e o bloco `LDIR` reexecutando passo a passo até `BC=0`), todas passando. Simplificações
  conscientes documentadas no topo de `MamuteZ80Cpu.pbi` (F3/F5 de `BIT n,(HL)/(IX+d)` usam o byte lido
  em vez do registrador interno WZ real do hardware; `DD`+`ED`/`FD`+`ED` tratam o prefixo anterior como
  desperdiçado; flags de `INI`/`IND`/`OUTI`/`OUTD` são aproximadas; sem cronometragem em T-states) — não
  são bugs, são cortes conscientes de escopo pra Fase 1. Rodada de polimento na mesma sessão: janela e
  botões maiores (nomes dos botões estavam cortando), disassembly ganhou rolagem independente (checkbox
  "Seguir PC" + botões `^`/`v`), pilha passou a ser editável por clique, e os 3 painéis desenhados à mão
  (disassembly/minimonitor/pilha) ganharam borda — mais próximo do visual "boxed panel" do Konpass.
  Pacote de distribuição gerado via `build.ps1 -D -V "7.33.44"` e publicado como
  `paleobasic-v073344.zip`. Ver `docs/RELEASE_NOTES.md` para as notas de lançamento formais.
- **2026-08-15 — release `7.33.45`**: minimapa de memória no debugger visual (`editor/MamuteDebuggerGui.pbi`),
  resolvendo a última das "decisões em aberto" do módulo 32 (`docs/SPEC.md`) que ainda não tinha sido
  implementada nem decidida (as outras duas — layout da janela e granularidade do Step Into sobre
  instruções de bloco — já tinham sido resolvidas na prática durante a Fase 1, `7.33.44`, mas o
  `SPEC.md` ainda não registrava isso). Grade de 16×16 blocos (256 bytes cada, 64KB inteiros) abaixo do
  painel `PAGE→SLOT→TIPO`: cor de base por página (RAM/ROM/BASIC/vazio, mesma fonte de dado que o
  painel de texto já usa), brilho dentro do bloco escalando com a fração de bytes não-zero (heurística
  de "uso" — não há alocador/heap real numa simulação Z80-only, então isso fica como aproximação visual
  até haver necessidade concreta de um heap de verdade). Marcadores: `PC` (amarelo), `SP` (ciano), bloco
  selecionado do minimonitor (branco, contorno mais grosso) e breakpoints ativos (ponto vermelho no
  canto do bloco). **Clique no minimapa move o minimonitor pro bloco escolhido** — mesmo campo
  `MiniBase` que já alimentava o minimonitor, então os dois painéis passaram a ser uma coisa só do
  ponto de vista de navegação, não dois recursos separados. Verificado ao vivo, não só por leitura de
  código: automação via UI Automation + `SendKeys` (PowerShell) abriu `Executar → Mamute Assembler...`,
  digitou `G 100` pra abrir o debugger, e `PrintWindow` capturou 3 screenshots reais confirmando (1) as
  4 bandas de página coloridas corretamente, (2) clique no minimapa atualizando o campo Endereço e o
  conteúdo do minimonitor pro bloco `E900`, e (3) os marcadores de `PC`/`SP` se movendo em tempo real
  depois de 6 `Step Into` consecutivos (`SP` foi de `0000` até `FFFC` — 3 `PUSH`, indo parar no último
  bloco do minimapa, canto inferior direito, exatamente onde deveria). Visualização de heap dedicada
  segue **não implementada** (proposta registrada no `SPEC.md`: intervalo configurável pelo usuário, já
  que não há como detectar isso automaticamente sem SO/alocador) — fica pra quando fizer falta na
  prática.
- **2026-08-15 (mesma sessão) — release `7.33.46`**: navegação por cursor no painel de disassembly do
  debugger, pedido explícito do usuário. Três peças novas, todas em `editor/MamuteDebuggerGui.pbi`:
  - **Cursor de linha independente do PC** (`CursorAddr`, novo campo em `MamuteDebuggerState`) — setas
    Cima/Baixo movem o cursor uma instrução por vez, desenhado como contorno branco na linha selecionada
    (a barra verde solida continua marcando o `PC`, que pode ser uma linha diferente). Descer é exato
    (`Mdbg_NextInstrAddr` soma o comprimento real da instrucao atual); subir usa heuristica de
    resincronizacao (`Mdbg_FindPrevInstrAddr`, tenta os 4 comprimentos possiveis de instrucao Z80 do
    maior pro menor) - mesma limitacao ja documentada pro botao `^` desde a Fase 1. **Quando o cursor
    chega no topo ou rodape da janela visivel, a janela rola 1 linha pra acompanhar** — pedido explicito
    do usuario. Clique numa linha do disassembly tambem move o cursor pra ali (`Mdbg_DisasmHitTest`).
  - **"Ir p/ endereço (G)"** — botão novo acima do disassembly + atalho `G`: abre um `InputRequester`
    pedindo um endereço em hexa e pula o disassembly (e o cursor) direto pra lá, desligando "Seguir PC"
    automaticamente (mesmo idioma já usado pelos botões `^`/`v`).
  - **"PC = cursor (H)"** — botão novo + atalho `H`: grava o endereço do cursor de volta no `PC`
    simulado — equivalente ao "Set Next Statement" de debuggers convencionais, não executa nada sozinho,
    só reposiciona de onde o próximo `Step`/`Run` vai partir.
  Verificado ao vivo (não só leitura de código): mesma automação via UI Automation + `SendKeys` +
  `PrintWindow` das sessões anteriores — confirmou 20× `Down` rolando a janela pra baixo mantendo o
  cursor colado no rodapé, 25× `Up` rolando de volta pra cima da janela original, `G` pulando de `4000`
  pra `5000` de verdade, e `H` gravando `PC = 4008` depois de mover o cursor com as setas (status
  "PC = 4008 (cursor)" confirmado na tela, registrador `PC` do painel atualizado, linha realçada em
  verde cheio).
- **2026-08-15 (mesma sessão) — release `8.0.1` "FOSSAURO"**: decisão explícita do usuário — `bafmsx/`
  (port nativo em PureBasic do fMSX, ver changelog `7.33.44` acima pra origem) deixa de ser um acidente
  de sessão e vira oficialmente **projeto irmão dentro do repositório principal**, com nome próprio no
  tema pré-histórico do projeto: **🦴 Fossauro** (fóssil + sufixo `-ossauro`, mesmo padrão de trocadilho
  já usado em Pixelossauro — a ideia é "hardware fóssil trazido de volta à vida", que é literalmente o
  que um emulador faz). **Atualização ainda no mesmo dia**: diferente do resto dos apelidos do projeto
  (Mamute/Raptor/etc., cosméticos — nome de arquivo/procedimento não muda), este apelido virou renome de
  verdade — `bafmsx/` → `fossauro/`, pedido explícito do usuário, git detectou como rename puro (conteúdo
  idêntico). Todas as referências abaixo já usam o caminho novo.
  - **`.gitignore` corrigido**: o achado da sessão anterior (`7.33.44`, ver changelog) — ROMs de BIOS do
    MSX com copyright próprio e uma cópia vendorizada inteira do fMSX original em C
    (`fossauro/fMSX/`, mesmo material já listado em `/fmsx/` na raiz) commitados por engano — foi
    corrigido sem apagar nada do disco: `git rm --cached` nesses arquivos (ROMs, `fossauro/fMSX/` inteiro,
    `fMSX.exe`/`fMSX.html`, mais os artefatos de build/teste `fossauro/*.exe`/`debug.log`, regenerados via
    `fossauro/build.ps1`) e três regras novas no `.gitignore` cobrindo esse escopo. **O fonte de verdade do
    port continua rastreado normalmente** (`fossauro/*.pbi`, `fossauro/*.pb`, `fossauro/*.md`,
    `fossauro/LICENSE`, `fossauro/build.ps1`, `fossauro/translate.py`) — pedido explícito do usuário
    ("quero que o fonte dele seja sincronizado"), diferente do tratamento dado a
    `badig/`/`nestor80/`/`asmsx/`/etc. (que ficam inteiramente de fora, só como referência local).
  - **Pendência registrada no `docs/SPEC.md`** (módulo 32b, nova seção): integração futura entre o
    PaleoBasic e o Fossauro — canal de comunicação entre a IDE e o emulador (mesmo espírito do pipe já
    existente com o openMSX real via `OpenMSXBridge.pbi`, módulo 12), e as funções que ainda faltam no
    Fossauro em si (V9938/PSG/carregamento de fita-disco, hoje só esqueleto segundo o próprio
    `fossauro/README.md`) antes de uma integração de verdade fazer sentido. Ver módulo 32b pro detalhe
    completo e como isso se encaixa no roteiro de 3 fases do debugger visual já existente.
  - **Bump de versão para `8.0.1`** (de `7.33.46`) — marca este novo capítulo do projeto (primeiro salto
    de versão maior desde o início do repositório).
- **2026-08-17** — Documentação do Fossauro incorporada à documentação principal: `docs/SPEC.md`
  ganhou o módulo 32c (arquitetura, status por componente e roteiro, adaptados de `fossauro/SPEC.md` +
  `fossauro/OUTLINE.md`) e `docs/MANUAL.md` ganhou uma seção "Fossauro" (operação da janela, opções de
  linha de comando — deixando claro quais das opções documentadas em `fossauro/manual.md` já existem de
  verdade no código e quais são só aspiracionais). README passou a ter uma tabela explícita das **duas
  licenças** do repositório (`LICENSE` GPLv3 do Paleobasic vs. `LICENSE-fossauro`, não-comercial,
  herdada do fMSX original) em vez de uma única seção "Licença" genérica.
  - **Bug real corrigido: "tela azul congelada" no boot do Fossauro** — a causa não era a CPU nem o
    mapeamento de memória (ambos verificados corretos rodando o binário recompilado com trace ao vivo),
    e sim `Global Verbose.a = 1` (`fossauro/MSX.pbi`) como padrão: toda chamada de log (`LogGeneral`/
    `LogMemory`/`LogCPU`/...) grava no disco de forma síncrona quando `Verbose` está ligado, e a
    instrumentação de trace por instrução adicionada em `a0721b9`/`Refine MSX Boot` (2026-08-15) dispara
    para qualquer PC dentro de `$4000-$7FFF` — faixa que não é só "onde o cartucho mapeia", é também
    onde a própria ROM BASIC do MSX1 roda durante todo boot normal, com ou sem cartucho. Resultado: um
    laço de delay do BIOS que deveria levar milissegundos (contado e confirmado via log, decrementando
    `HL` corretamente o tempo todo) passava a levar 45+ segundos reais de escrita em disco síncrona por
    instrução — de longe o suficiente pra parecer travado pra quem testa e fecha a janela antes disso.
    Corrigido trocando o padrão pra `Verbose = 0` e cabeando a flag `-verbose` (já documentada em
    `fossauro/manual.md`, mas nunca implementada em `fossauro/fossauro.pb`) pra religar o log sob
    demanda. Com o padrão corrigido, o boot chega ao laço principal de frames em menos de 1 segundo (
    confirmado via contador `FRAME=` do log, ~60fps), tanto sem ROM quanto carregando
    `Kingsvalley.rom`/`Athletic.rom` via `-rom`.
  - **Achado separado, não corrigido nesta sessão**: `fossauro/fossauro.log` até `.log.5` (até
    ~105 mil linhas cada) estão **rastreados no git**, contradizendo a própria convenção documentada do
    projeto (memória/`docs/SPEC.md` módulo 32b listam `fossauro/*.exe`/`debug.log` como devendo ser
    ignorados). Provavelmente entraram sem querer no commit `a0721b9` junto com o resto da refatoração.
    Vale adicionar `fossauro/fossauro.log*` ao `.gitignore` e rodar `git rm --cached` neles numa sessão
    futura — não mexido agora pra não misturar limpeza de repositório com a investigação do boot.
- **2026-08-17, mesmo dia** — usuário reportou que o Fossauro *ainda* não bootava visualmente mesmo com
  o fix acima, e pediu boot completo até o prompt do MSX-BASIC "igual ao fMSX" (deixando jogos pra
  depois). Segundo achado, esse sim a causa raiz de verdade: **o V9938 nunca foi esqueleto** — a hipótese
  registrada horas antes (neste mesmo changelog) estava errada. `RefreshLine()` (`fossauro/V9938.pbi`) já
  tinha renderização completa de texto/gráficos (modos 0/1/2/3/5/8), sprites e o motor de comandos VDP;
  só nunca tinha sido exercitada até o fim porque um bug real no **núcleo Z80** impedia o boot de chegar
  lá. Rastreado com instrumentação temporária (contador de escritas na VRAM por região, reconstrução do
  endereço de retorno via pilha, dump da name table linha a linha) até `EX (SP),HL` (opcode `$E3`,
  `fossauro/Z80_Codes.pbi`): a tradução automática (`translate.py`) do C original do fMSX (`RdZ80(SP.W);
  WrZ80(SP.W++,HL.B.l); RdZ80(SP.W); WrZ80(SP.W--,HL.B.h)`) não tratou o pós-incremento/decremento do C
  usado como argumento de função — o PureBasic gerado lia `mem[SP]` duas vezes (nunca `mem[SP+1]`) e
  escrevia em `mem[SP+1]` e **`mem[SP-1]`** (um endereço fora do par correto, corrompendo memória
  adjacente à pilha), fazendo `HL` virar lixo toda vez que a instrução executava — e ela aparece bem no
  meio da rotina de desenho do logo/banner de boot do BIOS. Mesmo bug, mesmo fix, na variante `IX`/`IY`
  (`fossauro/Z80_CodesXX.pbi`). Corrigido reescrevendo pra ler os dois bytes da pilha primeiro, só depois
  escrever `HL`/`IX`/`IY` nesses mesmos endereços. Confirmado por screenshot: boot mostra `MSX BASIC
  version 1.0` / `Copyright 1983 by Microsoft` / `28815 Bytes free` / `Ok`, cursor piscando e a barra de
  teclas de função (`color auto goto list run`) no rodapé — igual ao fMSX real, sem ROM de jogo nenhuma.
  Ver `docs/SPEC.md` módulo 32b (achado #2) pro passo a passo completo da investigação e `docs/SPEC.md`
  módulo 32c / `fossauro/README.md` / `fossauro/SPEC.md` pro status do V9938 corrigido (de "Planejado"
  pra "renderiza texto/gráficos/sprites/comandos VDP").
- **2026-08-17, mesmo dia** — usuário reportou teclas `/ ? [ { ] } \ | ' " ~ ^ ´` não funcionando no
  Fossauro em teclado americano. `MapCanvasKey()` (`fossauro/fossauro.pb`) só tinha 7 dos códigos de
  tecla OEM do Windows mapeados; `` ` `` (VK 192), `[` (VK 219), `\` (VK 220) e `]` (VK 221) estavam
  simplesmente ausentes do `Select`, então essas teclas não faziam nada. Adicionados, mais VK 226 (tecla
  extra ISO de alguns layouts). Testado simulando pressionamentos de tecla de verdade na janela (não só
  lendo código): `` [ ] \ ` `` passaram a funcionar; `/` e `'` já funcionavam (o teste inicial que
  sugeriu o contrário tinha falha de timing, não do fossauro); combinações com Shift (`? " { } | ~`)
  funcionam via o próprio mecanismo de matriz de teclado do MSX, sem precisar de mapeamento extra — a
  MSX combina a tecla física com o SHIFT do jeito que teclado real faz, não fossauro's código.
- **2026-08-17, mesmo dia** — `fossauro.exe` passou a aceitar a **linha de comando do fMSX original**
  (pedido explícito do usuário: "mesmo ainda não tendo todas as funcionalidades, aceite os parâmetros de
  linha de comando do fmsx, aceite o -help"). Argumentos posicionais carregam cartucho A/B (padrão fMSX
  real); `-help` imprime a lista completa e sai sem abrir janela; `-msx1`/`-msx2`/`-msx2+`/`-pal`/`-ntsc`
  têm efeito real (bits do `Mode`); `-verbose` ganhou uma máscara numérica opcional; todo o resto
  (disco/fita/som/joystick/filtros de vídeo/etc.) é reconhecido e aceito sem crashar, mesmo sem efeito
  ainda. Ver `docs/SPEC.md` módulo 32b pro detalhe completo de cada flag. **Achado separado, não causado
  por essa mudança**: rodando um cartucho por tempo suficiente (~20-25s padrão, poucos segundos com
  `-msx1`), o Fossauro trava com uma access violation genuína — confirmado que já acontecia antes de
  qualquer mudança desta sessão (reproduzido com o `fossauro.pb` original via `git stash`); não
  investigado a fundo ainda, mas `-msx1` deixa bem mais fácil de reproduzir numa sessão futura.
- **2026-08-17, mesmo dia** — usuário reportou que `-help` não mostrava nada na tela. A primeira versão
  usava só `OpenConsole()` puro do PureBasic, que não se anexa de forma confiável ao console de quem
  chamou um app GUI-subsystem no Windows rodando direto de um terminal interativo (só funcionava com a
  saída redirecionada pra arquivo). Corrigido chamando `AttachConsole(#ATTACH_PARENT_PROCESS)`
  explicitamente antes (precisou de `Import "Kernel32.lib"` próprio — não coberto pelo passthrough `_`
  automático do PureBasic); se não houver console pai pra anexar (ex.: clique duplo no `.exe`), cai pra
  um `MessageRequester` com o mesmo texto, garantindo que a ajuda aparece de um jeito ou de outro.
  Confirmado rodando `fossauro.exe -help` direto, sem redirecionamento nenhum.
- **2026-08-17, mesmo dia** — pedido explícito do usuário ("vá atrás desse crash") pro access violation
  (`0xC0000005`) que travava o Fossauro rodando um cartucho por tempo suficiente (~20-25s padrão, poucos
  segundos com `-msx1`). Achado sem precisar instrumentar código manualmente: o Windows já gravava
  minidumps automaticamente em `%LOCALAPPDATA%\CrashDumps\` a cada crash reproduzido nesta máquina
  (WER local dump collection, já configurado, não algo ligado nesta sessão). Um parser de minidump de
  ~30 linhas em PowerShell (formato `MDMP` documentado publicamente, só precisa do header + stream de
  exceção) extraiu `ExceptionCode`/`ExceptionAddress` de **7 crashes diferentes**, todos **idênticos**:
  `0xC0000005` com `ExceptionAddress=0x0` — assinatura clássica de chamada através de ponteiro de função
  nulo. Causa: `JumpZ80` (um dos callbacks do núcleo Z80) nunca é atribuído em `fossauro.pb`/
  `EmulationThreadProc()` (só no harness de teste separado, `fossauro_verify.pb`) — a maioria dos pontos
  de chamada já sabia disso (`If JumpZ80 : JumpZ80(...) : EndIf`, `Z80.pbi`), mas dois, traduzidos
  direto do C original do fMSX sem essa guarda (`JP (HL)` em `Z80_Codes.pbi` e `JP (IX)`/`JP (IY)` em
  `Z80_CodesXX.pbi`, ambos opcode `$E9`), chamavam `JumpZ80(...)` sem checar primeiro. `JP (HL)` é
  instrução comum em jogos de verdade (jump computado/máquina de estado) — qualquer cartucho que a
  executasse crashava. Corrigido com a mesma guarda já usada em `Z80.pbi`. Confirmado: `-msx1
  Kingsvalley.rom` (crashava em ~8s) sobreviveu 90s sem nenhum novo dump; `-msx1 Athletic.rom` sobreviveu
  30s. Ver `docs/SPEC.md` módulo 32b pro passo a passo completo, incluindo a técnica de ler minidumps do
  Windows sem precisar instalar WinDbg/cdb — útil pra qualquer crash futuro deste projeto que não deixe
  rastro em log.
- **2026-08-17, mesmo dia** — usuário reportou que mesmo com o crash corrigido, o Fossauro "carrega a
  tela de abertura mas interrompe, congela logo depois" rodando um cartucho. Investigado a fundo:
  **não é hang de CPU**. Uma sequência de instrumentação temporária levou por um caminho enganoso
  (parecia um "interrupt storm" de ~20.000 interrupções/segundo em vez das ~60/s esperadas) antes de um
  teste mais direto (trace de entrada em `MSXLoopZ80`, path absoluto — dois testes anteriores tinham
  falhado silenciosamente por usar path relativo) mostrar a verdade: `FrameCounter` chegando a 282 em 6
  segundos (~47fps), `ScanLine` avançando normalmente — CPU e timing saudáveis. Dois screenshots com 4s
  de diferença, tirados durante essa mesma execução "saudável", saíram pixel-idênticos: **é o conteúdo
  da tela que nunca muda, não a CPU que trava**. A splash mostrada ainda é a do BIOS, não a tela de
  título do jogo — o jogo nunca assume o controle visual. Hipótese mais provável (não confirmada): o
  hook H.TIMI que jogos MSX normalmente instalam pra rodar sua lógica a cada frame pode não estar sendo
  preservado/instalado corretamente no Fossauro, deixando o BIOS fazer sua manutenção normal (por isso
  parece "vivo") sem o estado do jogo em si nunca avançar. Ver `docs/SPEC.md` módulo 32b pro passo a
  passo completo da investigação e a lição de metodologia sobre paths relativos em diagnósticos rodando
  na thread de emulação.
- **2026-08-17, mesmo dia** — pedido explícito do usuário ("vá atrás dessa hipótese do hook H.TIMI"),
  investigado a fundo. Resultado: **o hook É instalado com sucesso** (não era a hipótese certa) — a
  tabela em `$FD9A` recebe `JP $401A` (dentro do cartucho) por volta do frame 100 e o valor persiste
  corretamente em RAM depois disso. O que quebra é o que a CPU *vê* ao tentar ler dali: o registrador
  de sub-slot secundário de `SSLReg(3)` muda de `$A0` (RAM de verdade) pra `$0` (sub-slot nunca
  populado, cai no dummy `$FF`-preenchido) por volta do frame 120, escondendo o hook mesmo intacto.
  Rastreado até uma escrita em `$FFFF` (endereço especial de troca de sub-slot no MSX) acontecendo
  exatamente quando o próprio endereço `$0038` (vetor de interrupção) já lia `$FF` em vez do `JP` real
  da ROM — ou seja, a página 0 (BIOS) já tinha sido corrompida primeiro. Cadeia causal reconstruída: o
  hook desvia execução pra dentro do próprio cartucho a cada VBlank (como esperado); em algum ponto do
  código do jogo (não identificado — precisaria desmontar `Kingsvalley.rom`, não feito nesta sessão), a
  pilha cresce sem parar até dar a volta em 64KB e colidir com `$FFFF` — que no MSX real é *sempre* o
  registrador de troca de slot, push de pilha ou não (fidelidade real ao hardware, não bug de emulação
  em si). Isso corrompe o mapa de memória, incluindo a página 0, criando o laço auto-sustentado
  "`PC` preso em `$38`, `SP` decrescendo sem parar" já visto na investigação anterior. **Não corrigido**
  — a causa raiz agora é "o código do cartucho estoura a pilha rodando a partir do hook", não mais uma
  falha do Fossauro em instalar/preservar o hook. Ver `docs/SPEC.md` módulo 32b pro passo a passo
  completo e as ideias de próximo passo (desmontar o jogo a partir de `$401A`, ou um mitigador
  defensivo pra escritas suspeitas em `$FFFF`/`$FFFE`).
- **2026-08-17, mesmo dia** — pedido explícito do usuário: "implemente o MSX 1/2/2+ para o depurador e o
  MSX BASIC funcionarem primeiro, depois que tudo estiver 100% voltamos aos jogos" — priorizar
  fidelidade de emulação (debugger/BASIC) sobre jogos, com paridade 1:1 contra o fMSX real sempre que
  possível. Implementado `MSXLoadBIOSForModel()`/`MSXLoadExtBIOS()`/`ApplyBIOSPatches()`/`MSXPatchZ80()`
  em `MSX.pbi`, replicando `StartMSX()`/`Patch.c` do fMSX real (BIOS principal + extended BIOS por
  modelo, patches de cassete). **MSX1 confirmado sem regressão** via screenshot. **MSX2/MSX2+ ainda não
  bootam** — travam com tela preta antes do prompt do BASIC, `VDP(1)` (screen-enable) nunca é setado.
  Confirmado que o `fMSX.exe` real (já presente em `fossauro/fMSX/`) boota MSX2 sem problema com os
  mesmos arquivos de ROM, então o bug é do núcleo do fossauro, não do ambiente. Uma hipótese inicial (a
  restrição "slot 0 sem subslot só em MSX1" em `SSlot()`) foi **descartada** por comparação direta com
  `MSX.c` linha 1773 — fossauro já reproduz o real fielmente ali. Um experimento isolante (desativar a
  extended BIOS) mostrou que o freeze **não** é específico dela — acontece de qualquer forma, só que via
  um caminho de código diferente, apontando pra algo mais fundamental que só o boot MSX2 (mais complexo
  que MSX1) exercita. Causa raiz exata ainda não isolada apesar de rastreamento detalhado de registrador
  por instrução em três sub-rotinas de auto-detecção de slot da própria `MSX2.ROM`. Ver `docs/SPEC.md`
  módulo 32d pro passo a passo completo, o que já foi descartado, e o próximo passo recomendado.
- **2026-08-17, mesmo dia** — com o freeze do MSX2/2+ ainda em aberto, seguiu pro próximo item do plano:
  auditoria do motor de comandos VDP (`VDPDraw()`, `V9938.pbi`) contra `V9938.c` real. Três bugs reais
  encontrados e corrigidos: **`SRCH`** usava `512` fixo como limite de X pra qualquer modo (errado pros
  modos 5/8, que são 256px de largura); **`HMMV`/`HMMM`** (comandos "de alta velocidade") passavam pelo
  caminho de pixel único com máscara/operação lógica em vez do armazenamento de byte cru que o hardware
  real faz nesses comandos, e não avançavam pelos pixels-por-byte corretos (2/4/2/1 pros modos 5/6/7/8);
  **`YMMM`** usava uma coordenada X de origem independente (`SX`) e limitava a varredura por `NX`, quando
  o hardware real sempre copia dentro da mesma coluna X (só a linha muda) e varre a tela inteira,
  ignorando `NX`. `HMMC`/`LMMC`/`LMMV`/`LMMM`/`LINE`/`PSET` conferidos e já corretos. MSX1 testado sem
  regressão (screenshot). Na sequência, auditoria do PSG (`AY8910.pbi`) contra `AY8910.c` real: as
  arquiteturas são fundamentalmente diferentes (o fMSX real delega síntese de áudio pra uma camada
  genérica externa ao arquivo, sem emular o LFSR de 17 bits ciclo a ciclo; o fossauro já faz síntese PCM
  de verdade por amostra, mais preciso, não uma tradução direta) — a máquina de estados do gerador de
  envelope foi conferida contra a tabela `Envelopes[16][32]` real e bate em todos os 16 casos, inclusive
  um artefato conhecido do hardware (valor repetido no ponto de virada dos shapes alternantes). Um bug
  real e pequeno corrigido: escrita de registrador do PSG (porta `$A1`) não mascarava bits não usados
  como o hardware real faz, afetando só a fidelidade de releitura via porta `$A2`, não o áudio. Ver
  `docs/SPEC.md` módulos 32e/32f pro detalhamento completo.
- **2026-08-17, mesmo dia** — pedido explícito do usuário pra continuar tentando fazer MSX2/2+ bootarem.
  **Causa raiz do freeze encontrada e corrigida: o chip de Relógio de Tempo Real (RTC) do MSX2 nunca
  tinha sido implementado.** A extended BIOS grava na porta `$B4`/lê da porta `$B5` esperando uma
  resposta do RTC durante a inicialização, sem nenhum timeout - como o fossauro não tratava essas portas,
  a leitura sempre voltava `$FF` (valor padrão pra porta desconhecida), que nunca satisfazia a condição
  de saída, travando pra sempre. Confirmado contra o `MSX.c` real do fMSX (`RTCIn()`/`case 0xB5`) que
  são exatamente os registradores do RTC (13 registradores × 4 bancos, banco 0 = relógio real do
  sistema). Implementado `RTCIn()` em `MSX.pbi` usando `Date()`/`Second()`/`Minute()`/etc. do PureBasic
  pra montar os dígitos BCD do relógio, ligado nas portas `$B4`/`$B5`. **Resultado: MSX2+ agora boota
  completamente até o prompt do BASIC** ("MSX BASIC version 3.0 / Copyright 1988 by Microsoft",
  confirmado por screenshot) - MSX1 sem regressão. **MSX2 puro avança muito mais longe** (tela liga de
  verdade, `SCREEN 6` é alcançado) **mas ainda trava num segundo loop de polling de hardware diferente**
  (um despacho por ponteiro `JP (IX)` que parece não ter handler instalado pra esse dispositivo
  específico) - como MSX2+ já funciona 100%, essa segunda causa ficou registrada mas não é mais
  prioridade imediata. Ver `docs/SPEC.md` módulo 32g pro relato completo, incluindo a armadilha real que
  atrasou boa parte da sessão anterior (mesmo PC endereço pode ser ROMs diferentes dependendo do slot
  selecionado - boa parte do disassembly do módulo 32d tinha lido a ROM errada).
- **2026-08-17, mesmo dia** — usuário reportou que o MSX2+ não mostra "a animação do logo antes do boot"
  e que o MSX2 puro continua com tela cinza. Investigado: o `fMSX.exe` real **também não mostra logo
  nenhum** (só um flash de cor de borda com menos de 1 segundo) - a diferença de velocidade (fossauro
  ~2.5s vs. fMSX real ~9s) é explicada principalmente por disk ROM (o fossauro não implementa nenhum,
  então pula o tempo de detecção de drive que o fMSX real gasta - visível na tela dele como "Disk BASIC
  version 1.0"). Pra MSX2 puro, mais uma rodada de tracing cirúrgico descartou a hipótese anterior (o
  trampolim `JP (IX)`, que na verdade resolve normalmente) e isolou a localização exata onde a CPU fica
  presa (`$2980`-`$299F` em `MSX2EXT.ROM`, uma leitura do registrador de status S#2 do VDP) mas **não**
  a causa raiz - o bit que essa rotina testa já lê como esperado nas amostras capturadas, então o loop
  real deve estar numa camada externa ainda não identificada. MSX2+ continua 100% funcional. Ver
  `docs/SPEC.md` módulo 32h pro relato completo e o próximo passo recomendado.
- **2026-08-17, mesmo dia** — pausando a investigação do freeze do MSX2 puro, usuário pediu pra começar
  a estrutura de menu de verdade do `fossauro.pb`. **`File`** reorganizado: `Open Cartridge...`/
  `Open Disk...`/`Save Snapshot...`/`Open Snapshot...`/`Load .CAS...`/`Load .CHT...`/`Quit` -
  disco/fita/cheat abrem o seletor de arquivo certo mas ainda não fazem nada com o arquivo (controlador
  de disquete, cassete e cheats openMSX/BlueMSX-compatíveis são trabalho futuro, adiado explicitamente
  pelo usuário). **`Hardware → Model`** novo (MSX1/MSX2/MSX2+, com marca de seleção): troca o modelo ao
  vivo (recarrega a BIOS certa, recarrega o cartucho já carregado se houver, reset completo) - achou e
  corrigiu um bug real no processo (`MSXLoadBIOSForModel()` não limpava a extended BIOS ao trocar PARA
  MSX1, deixando `MSX2EXT.ROM` ainda mapeada de uma troca anterior). Testado nas duas direções via
  `WM_COMMAND` direto pro `HWND` (MSX1↔MSX2+, ambos confirmados por screenshot chegando no BASIC certo).
  **Save/Open Snapshot implementado de verdade** (não só o item de menu): formato binário próprio
  salvando RAM/VRAM/CPU/VDP/PSG/PPI/RTC/estado de slot completos (caminho do cartucho é salvo, não os
  dados da ROM - relido do disco no load). Verificado com um teste headless temporário (removido depois):
  save → corrompe estado → load → todos os valores batem exato. Ver `docs/SPEC.md` módulo 32i pro
  detalhamento completo.
- **2026-08-18** — pedido explícito do usuário pra continuar a investigação do freeze de boot do MSX2 puro
  (módulos 32g/32h). **Causa raiz encontrada e corrigida**: a ROM emite um comando de VDP LMMC (128
  pixels, `NX=16 NY=8`) pro logo/ícone de boot e alimenta exatamente 127 bytes via porta `$9B` - um a
  menos que os 128 que `VDPWrite()` (`V9938.pbi`) exigia pra completar o comando e limpar o flag CE
  (Command Executing). Comparação com `fMSX/fMSX/V9938.c` real revelou o porquê: hardware real consome um
  pixel imediatamente ao iniciar o comando (usando o valor já latched em VDP register 44), então a BIOS
  real só precisa mandar `NX*NY-1` bytes - o `fossauro` nunca fazia esse "tick" inicial. Corrigido em
  `VDPDraw()` (`Case $0B, $0F`, LMMC/HMMC): chama `VDPWrite(VDP(44))` uma vez logo após iniciar o comando,
  espelhando o comportamento real. **MSX2 agora boota completamente** ("MSX BASIC version 2.1"),
  confirmado por screenshot; MSX1/MSX2+ testados de novo sem regressão. Ver `docs/SPEC.md` módulo 32j pro
  detalhamento completo (metodologia de trace por instrução real em vez de desmontagem manual, e a
  comparação linha-a-linha contra o C real que resolveu o mistério).
- **2026-08-18, mesmo dia** — pedido explícito do usuário: suporte a tamanho de RAM (64/128/256/512/
  1024KB) no menu `Hardware` do Fossauro, com a pergunta de como o MSX1 deveria expandir memória (mapeador
  igual MSX2/2+, ou cartuchos de RAM em slot/sub-slot, mais comum em hardware real) - pedido explícito pra
  checar o fonte real do fMSX e seguir de perto. Resposta encontrada em `fMSX/fMSX/MSX.c`: o fMSX real
  **não** modela RAM de MSX1 como cartuchos - usa o mesmo mapeador por bancos (portas `$FC`-`$FF`, sempre
  em Slot 3-2) pra todo modelo, só o mínimo de páginas válido muda (MSX1 4 páginas/64KB, MSX2/2+ 8
  páginas/128KB, máximo 256/4096KB ambos). Portado fielmente pro `fossauro/MSX.pbi`
  (`ClampRAMPages()`/`ReallocateRAM()`, portas `$FC`-`$FF` em `MSXInZ80`/`MSXOutZ80`), com **Hardware →
  RAM Size** novo no menu e `-ram <páginas>` finalmente ligado na CLI (antes só aceito, ignorado). Formato
  de snapshot `.fss` bump de v1→v2 pra incluir o tamanho de RAM salvo. Testado ao vivo via `WM_COMMAND`
  trocando RAM em MSX1 e MSX2 (128KB/512KB/1024KB), screenshot confirmando boot limpo em cada tamanho, sem
  regressão. Ver `docs/SPEC.md` módulo 32k pro detalhamento completo.
- **2026-08-18, mesmo dia** — pedido explícito do usuário "seguindo a mesma lógica" do RAM: tamanho de
  VRAM configurável (16/32/64/128/192KB) e suporte a mappers MegaROM em Cartucho Slot A/B (Guess/Generic
  8KB/Generic 16KB/Konami 5000h/Konami 4000h/ASCII 8KB/ASCII 16KB/GameMaster2/FMPAC), mais um pedido de
  Disk Drive A/B (inserir/ejetar/criar/salvar disco) pausado antes de começar - de longe a maior das três
  frentes, precisa de emulação real de WD1793/FDC. **VRAM**: mesmo padrão de arredondamento/limite do RAM,
  mas o fMSX real é mais rígido (MSX2/2+ só 128KB exato, MSX1 só 32/64/128KB - "16KB"/"192KB" do menu
  sempre voltam pro padrão do modelo). **MegaROM**: `MapROM()` portado do `MSX.c` real pros 8 tipos de
  mapper, com SRAM (não-persistida) pros que precisam; corrigido um bug real no processo - o Slot A
  espelhava nos dois slots primários e roubava o Slot B se carregado depois. Testado com MegaROMs reais
  de 128KB já no repositório (ASCII8/Konami5-SCC) - carregamento correto, mapper identificado certo pelo
  `GuessROMType()`. Achado (não-relacionado) durante o teste: reproduzido o bug **já documentado** de
  estouro de pilha do hook H.TIMI com um cartucho simples de 16KB, confirmando que não é regressão desta
  sessão. Ver `docs/SPEC.md` módulo 32l pro detalhamento completo.
- **2026-08-18, mesmo dia** — pedido explícito do usuário: padrão de inicialização (sem argumentos) virar
  MSX1/64KB RAM/16KB VRAM. Esbarrou num conflito real: o clamp fiel ao fMSX (módulo 32l) rejeita 16KB de
  VRAM no MSX1 (mínimo real do fMSX é 32KB) - perguntado ao usuário, que escolheu relaxar esse mínimo pra
  16KB de propósito (único ponto onde fossauro diverge do comportamento real do fMSX nesse subsistema,
  já que 16KB era comum em hardware MSX1 de verdade). `Mode`/`VRAMPages` (`MSX.pbi`) atualizados; `RAMPages`
  já tinha o valor certo. Confirmado por screenshot: sem argumentos, sobe direto até o prompt do BASIC do
  MSX1. Ver `docs/SPEC.md` módulo 32m.
- **2026-08-18, mesmo dia — release `8.1.3` "MSX2 DE VERDADE"**: pedido explícito do usuário pra fechar a
  sessão - bump de versão (`8.0.1` → `8.1.3`) marcando tudo que aconteceu hoje no Fossauro como um
  lançamento formal: causa raiz do freeze de boot do MSX2 puro finalmente achada
  e corrigida (os três modelos bootam de ponta a ponta), RAM/VRAM configuráveis via mapeador por bancos
  (fiel ao fMSX real), mappers MegaROM em cartucho (9 tipos + SRAM), e novo padrão de inicialização
  (MSX1/64KB RAM/16KB VRAM). Ver `docs/RELEASE_NOTES.md` pra nota de lançamento formal completa.
- **2026-08-19 — release `8.1.7` "PILHA EMPRESTADA"**: bug fix pontual do travamento do `RUN` do
  protocolo de controle remoto do Fossauro reportado na sessão anterior (`docs/SPEC.md` módulo 32w).
  Causa raiz real, achada reproduzindo o mesmo programa de teste em dois momentos de boot diferentes e
  amostrando todos os registradores (não só `PC`): não era um laço preso dentro do BIOS, era corrupção
  de pilha — `RUN` só trocava `PC`, nunca `SP`, então um `RET` do código injetado (direto ou via BIOS
  mal-balanceada) fazia `POP` na pilha da sessão MSX original, ressurgindo a execução em código alheio
  de forma imprevisível. Fix: `RUN` agora empurra um endereço de retorno sintético apontando pra um
  trap detectável antes de saltar. Ver `docs/SPEC.md` módulo 32x e `docs/RELEASE_NOTES.md` pra nota de
  lançamento formal completa.
- **2026-08-19, mesmo dia — release `8.2.0` "ESQUELETO NOVO"**: reorganização completa de diretórios
  pedida pelo usuário — `editor/`/`fossauro/`/pastas soltas na raiz viram `src/` (código, dividido por
  função lógica), `dist/` (tudo que o programa precisa pra rodar, os dois `.exe` na raiz), `resource/`
  (recursos não-compilados/cópias de referência), `docs/` (documentação consolidada) e `others/`
  (diretórios sem uso, candidatos a remoção). Junto: correção das telas `Configurar → Basic
  Dignified.../openMSX...` (campo do executável fora de ordem, `-setting` nunca funcionava, extensão
  virou 4 slots reais), comando `OPENMSX` novo no Mamute Assembler (mesmo fluxo do `FOSSAURO`, mirando
  o openMSX de verdade) e correção de sintaxe `DEFUSR0`/`USR0(0)`. Ver `docs/SPEC.md` módulos 33-36 e
  `docs/RELEASE_NOTES.md` pra nota de lançamento formal completa.
- **2026-08-19, mesmo dia**: limpeza de arquivos — três pacotes `.zip` de release antigos
  (`paleobasic-v080106.zip`/`v080107.zip`/`v080200.zip`) que tinham ficado rastreados no git por
  engano removidos do repositório (pedido explícito do usuário — pacotes de release não devem virar
  parte do histórico do git, ver decisão equivalente registrada mais abaixo na sessão de `8.3.0`).
  Ícone novo do aplicativo (`resource/branding/paleobasic-new.ico`), `CHANGELOG.md` separado de
  `README.md` (que tinha passado de 3000 linhas) e ajustes pontuais em `src/fossauro/build.ps1`.
- **2026-08-20 — release `8.3.0` "TECLA FANTASMA"**: pedido explícito do usuário pra melhorar a
  integração do console do openMSX (`Executar → openMSX...`) com o fluxo de editor/montador, motivado
  por um sintoma concreto relatado ao vivo: a resposta de `openmsx_info fps` (consultada ~1x/segundo)
  poluía, número solto por linha, tanto o log da aba "Console" quanto o da aba "Status Info". **FPS
  parou de poluir os dois logs** — `OMSX_Poll()` monta um stream conciso (Console) e um verboso
  (Status Info) por chamada, e a resposta crua do FPS fica de fora dos dois desde que o **display de
  FPS dedicado na barra inferior** (sempre visível, qualquer aba, estilo mini-display digital) passou
  a existir. **Botão de Power** também na barra inferior, atalho pro mesmo `set power on/off` de
  sempre. **Dois bugs reais encontrados e corrigidos**: `SetGadgetText()` não fazia NADA num
  `ButtonImageGadget` (`ThemedButton`) — afetava silenciosamente 9 botões de estado dinâmico
  (Power/Pause/Firmware/Ren Sha Turbo/VSync/Deinterlace/Limitar sprites/Tela cheia/Desabilitar
  sprites) desde que foram criados, o comando sempre funcionava mas o rótulo nunca refletia de volta —
  corrigido com `SetGadgetAttribute(..., #PB_Button_Image, ...)`; e o botão STOP pressionava TAB (linha
  7, máscara `0x08`) em vez de STOP (máscara `0x10`), um comentário de sessão anterior citava uma
  "confirmação" contra um script real do openMSX que na verdade não existe nos scripts vendorizados —
  cruzado desta vez contra DUAS fontes independentes (tabela real do openMSX e a tabela já portada do
  fMSX no simulador MSX deste projeto), que batem 100% entre si. **Teclas especiais na aba "Input
  Text"**: tags `⟦NOME⟧` (colchetes Unicode reservados, não confundem com `[ESC]` ASCII literal em
  texto/BASIC de verdade) viram um toque de tecla de verdade via `keymatrixdown`/`keymatrixup`, com uma
  paleta de 23 botões inserindo a tag no cursor — verificado ao vivo contra a tela real do MSX (ROM
  DDX-DRIVE reagindo à tecla ESC de verdade, texto literal em volta intacto). **Combos de tecla**
  (pedido explícito do usuário, sessão seguinte): tags `⟦NOME1+NOME2+...⟧` pressionam todas as teclas
  primeiro e só soltam no final (ao contrário da tag simples, que aperta E solta antes da próxima) —
  "Modo Combo" na paleta acumula cliques num combo até "Inserir" escrever a tag combinada de uma vez.
  Ver `docs/SPEC.md` módulo 37 e `docs/RELEASE_NOTES.md` pra nota de lançamento formal completa.
- **2026-08-20, mesmo dia**: pedido explícito do usuário — auto-indentação nas abas `.dmx`/`.bas` do
  editor principal. `Enter` mantém a indentação da linha anterior (em vez de sempre voltar pra coluna
  0), com um nível a mais depois de `FOR`/`IF ... THEN`/`FUNC`/rótulo de loop `nome{` e um nível a
  menos assim que `NEXT`/`ENDIF`/`RET`/`}` é digitado sozinho no começo da linha. Reaproveita o mesmo
  evento `#SCN_CHARADDED` já usado pelo auto completar. `FOR ... : NEXT` numa linha só (idioma clássico
  comum de MSX-BASIC) não conta como bloco aberto; número de linha clássico no início não atrapalha a
  detecção. **Bug real corrigido durante a verificação ao vivo**: `Trim()` nativo do PureBasic só
  remove espaços por padrão, não tabs — uma linha já indentada nunca batia contra `"ENDIF"`/`"NEXT"`
  por causa do tab colado na frente; corrigido com um trim manual (`TrimIndentChars`). Verificado ao
  vivo enviando `WM_CHAR` direto pro HWND do Scintilla (mensagem direcionada, não clique/tecla real
  simulados) com `FOR`/`NEXT`, `IF...THEN`/`ENDIF`, `FUNC`/`RET` e rótulo de loop, todos indentando/
  desindentando corretamente. Ver `docs/SPEC.md` módulo 38.
- **2026-08-20, mesmo dia**: refinamento pedido pelo usuário depois de notar que `"PRINT 1:FOR I=1 TO
  5"` não indentava a linha seguinte — a detecção original só olhava a primeira palavra da linha
  inteira, então um `FOR` que não fosse a primeira instrução (várias instruções separadas por `:` na
  mesma linha, idioma clássico de MSX-BASIC) escapava do check. `HandleAutoIndentNewline()` agora
  varre cada trecho separado por `:` separadamente (`FOR`/`FUNC` contam como abertura, `NEXT`/`RET`/
  `ENDIF` como fechamento) e só indenta se sobrar mais abertura que fechamento na linha toda - o que
  também cobre de graça o caso `FOR I=1 TO 10:NEXT` (abre e fecha na mesma linha) sem precisar de um
  caso especial à parte. Verificado ao vivo com `FOR:NEXT` autofechado, `PRINT 1:FOR...` abrindo
  bloco, aninhamento `FOR`+`IF...THEN`, e um `:` sozinho no fim sem palavra-chave (não indenta). Ver
  `docs/SPEC.md` módulo 38.
- **2026-08-20, mesmo dia**: bug real reportado pelo usuário com um programa de 1988 ("Hyper Copy",
  Marcelo Fontolan) - `gosub { apresentacao }` (espaço dentro das chaves) falhava com "Label mal
  formado" na conversão Dignified. Causa: `Dig_ReadIdent()` lia o identificador colado em `{`, um
  espaço fazia a leitura parar na hora (nome vazio). Corrigido com `Dig_SkipSpaces()` novo, tolerando
  espaço nos dois casos de `{nome}` (referência de jump e definição de label sozinho na linha) -
  replica o comportamento real do lexer Python original (tokens `{`/identificador/`}` separados,
  espaço insignificante entre eles). **Bug introduzido e revertido na primeira tentativa**: aplicar a
  mesma tolerância na abertura de rótulo de LOOP (`nome{`) quebrou a suíte de regressão (`restore
  {character_shapes}`/`restore {ml_routines}` do arquivo de teste viravam "abrir loop chamado
  restore", duplicado) - revertido, só `{nome}` (delimitado dos dois lados) ganhou a tolerância.
  **Achado adicional**: todos os 16 harnesses de console em `src/editor/tools/*.pb` tinham
  `XIncludeFile` apontando pro layout antigo de diretórios desde a reorganização `8.2.0` - corrigidos
  15 deles (`OpenMsxBridgeTestCli.pb` continua quebrado por um motivo diferente e pré-existente, ver
  lacunas conhecidas). Suíte de regressão verificada limpa. Ver `docs/SPEC.md` módulo 39.
- **2026-08-20, mesmo dia**: confirmado que o limite de 255 caracteres por linha gerada (máximo real
  do MSX-BASIC) já existia em `Dig_ProcessSource` - não era uma lacuna, só a mensagem de erro não
  informava o tamanho real da linha nem deixava o limite explícito. Melhorada pra informar o tamanho
  de verdade ("Linha gerada tem N caracteres - o máximo que o MSX-BASIC suporta é 255"). Verificado
  ao vivo com um caso de 312 caracteres. Ver `docs/SPEC.md` módulo 40.
- **2026-08-20, mesmo dia**: auto-indentação (módulo 38) simplificada de propósito depois do usuário
  reportar que uma linha terminando em `:` sem `FOR`/`IF` nenhum ainda ganhava um Tab extra ao
  pressionar Enter. Em vez de caçar mais um caso de borda, o usuário pediu pra tirar a lógica de somar/
  tirar nível por completo - agora a auto-indentação só copia a indentação da linha anterior, sem
  nenhuma detecção de bloco (`HandleAutoDedentKeyword()` e os helpers que só existiam pra isso foram
  removidos). Verificado ao vivo: `cls :`/`key off:`/`for temp = 1 to 3 :`/`next temp` e outras
  variações, nenhuma ganhou indentação extra. Ver `docs/SPEC.md` módulo 41.
- **2026-08-20, mesmo dia**: pedido explícito do usuário — `build.ps1` (raiz do repo) nunca builda o
  fossauro, sempre foi preciso rodar `src\fossauro\build.ps1` à parte pra `dist\fossauro.exe` existir;
  o usuário apontou isso ("fossauro é nosso emulador de MSX e faz parte do projeto todo") e pediu um
  build único que já gere o pacote inteiro. **Causa encadeada, dois problemas**: (1) `build.ps1`
  deliberadamente nunca chamava o script do fossauro (decisão de `8.2.0`, ligada à licença própria/
  não-comercial dele); (2) mesmo compilando o `.exe`, ele não teria ROMs pra rodar — `resource\roms\`
  (origem canônica que a etapa de distribuição copia pra `dist\roms\`) só tinha `CARTS.SHA`/
  `fMSX.exe`/`fMSX.html`, sem nenhum `.ROM` — os 8 ROMs de sistema reais (`MSX.ROM`/`MSX2*.ROM`/
  `DISK.ROM`/`FMPAC.ROM`/`PAINTER.ROM`) estavam perdidos nas pastas soltas não-rastreadas `fossauro/`
  e `fMSX/` da raiz (sobra de antes da reorganização `8.2.0`), nunca movidos pro lugar certo.
  **Fix**: ROMs copiados pra `resource\roms\` (conferidos byte-a-byte idênticos entre as duas cópias
  soltas antes de escolher a origem); `build.ps1` agora sempre chama `src\fossauro\build.ps1` logo
  após compilar o `PaleoBasic.exe` (mesma `$Version` repassada nos dois — o fossauro tinha uma versão
  fixa em `8.2.0` no próprio script, dessincronizada), e o antigo flag `-D`/`--distribute` foi
  removido — o que ele fazia (atualizar `dist\` a partir de `resource\`: fontes, imagens de ajuda,
  ferramentas externas, help do fossauro, ROMs) agora acontece incondicionalmente em todo build, sem
  flag nenhum. Verificado rodando `.\build.ps1` do zero: `dist\PaleoBasic.exe` e `dist\fossauro.exe`
  saem os dois, `dist\roms\` com os 8 `.ROM`, sem precisar de nenhum passo manual extra.
- **2026-08-20, mesmo dia**: bug real reportado pelo usuário com `others/menu.dmx` (arquivo pessoal
  dele) — `func .message(...)` na linha 161 falhava com `Ja dentro de uma funcao: inputint`, mesmo a
  função anterior tendo `ret valor` no final (linha 158). Causa: `Dig_JoinLines` funde uma linha
  terminada em `:` com a próxima (idioma clássico usado o arquivo todo, pra caber várias instruções
  numa única linha BASIC) ANTES do estágio que despacha `FUNC`/`RET` — depois da junção, `ret valor`
  deixa de ser a primeira palavra da linha lógica (vira `gosub {clrmsg}:ret valor`), então o despacho
  de `RET` (que só olhava a primeira palavra da linha inteira) nunca disparava, `Dig_InFunc` nunca
  voltava a `""`, e a função ficava presa aberta. Confirmado contra `docs/reference/dignified-core.md`
  que o `badig.py` original resolve `RET`/`FUNC` no nível de TOKEN, não de linha de texto — onde um
  `RET` cai dentro de um agrupamento de linhas unidas por `:` é irrelevante lá, então tolerar isso
  aqui é replicar o comportamento certo. **Fix**: `Dig_FindLastTopLevelColon()` novo — o despacho de
  `RET` agora olha a primeira palavra do trecho DEPOIS do último `:` de nível superior da linha, não
  da linha inteira; reconstrói como `<prefixo>:RETURN`. Escopo limitado a `RET` (não `FUNC`, que nunca
  aparece colado depois de outra instrução na prática). Verificado: `menu.dmx` converte limpo agora;
  suíte de regressão (`dist/sample/teste.dmx`) comparada byte a byte entre pré-fix e pós-fix — idêntica
  nos dois `.amx`/`.bmx`, ou seja o fix não muda nenhum caso já coberto. Ver `docs/SPEC.md` módulo 42.
- **2026-08-21 — release `8.4.0`**: dois pedidos do usuário sobre o sistema de projeto. Primeiro,
  **associação de arquivo `.msxproject` com o Windows** (`Configurar → Associações de arquivo...`,
  `src/editor/core/FileAssociationGui.pbi`) — liga/desliga a associação em
  `HKEY_CURRENT_USER\Software\Classes` (sem precisar de administrador; nunca mexe numa associação de
  outro programa ao desmarcar), pra dar 2 cliques num `.msxproject` no Explorer abrir esse projeto
  direto no Paleobasic. Precisou de `Import` manual de `RegCreateKeyExW`/`RegSetValueExW`/
  `RegOpenKeyExW`/`RegQueryValueExW`/`RegCloseKey`/`RegDeleteTreeW` (Advapi32.lib) e `SHChangeNotify`
  (Shell32.lib) — nem os WinAPI crus nem a lib Registry de mais alto nível do PureBasic vêm disponíveis
  nesta instalação do compilador, confirmado tentando os dois antes de escrever o `Import`. Depois,
  usuário gostou da ideia e pediu mais: **Índice de recursos do projeto** (`Projeto → Índice de
  recursos...`, `Ctrl+Alt+R`, `src/editor/core/ProjectIndexGui.pbi`) — catálogo de tudo que o
  `.msxproject` guarda (documentos por tipo, cada recurso numerado, `.dsk` ao lado do projeto), pensado
  pra quem empacota programas + artigos explicativos (`.md`) num projeto só, ex. digitando type-ins de
  revista. A primeira versão ia mostrar a Tag de cada recurso numerado, mas `ProjectDB::Fetch*()`
  escreve direto no `Array` do tamanho REAL do recurso sem `ReDim` interno — array pequeno demais
  estoura o limite, mesma família de bug já documentada neste projeto (`CopyMap()` em mapa vazio) —
  então a lista mostra só Tipo + número desses recursos, sem arriscar um `Fetch` de payload pesado só
  pra exibir um nome. Novo menu de topo **Projeto** consolida o que estava espalhado entre Arquivo
  (Novo/Abrir/Salvar projeto) e Configurar (Projeto..., renomeado "Configurações do projeto..."). Tudo
  verificado ao vivo (build limpo, `.exe` real, `WM_COMMAND`/`BM_CLICK` num HWND específico, screenshot,
  registro conferido por fora com PowerShell, `.md` salvo de verdade reaparecendo no índice) — exceto o
  clique duplo dentro do `ListIconGadget` em si, que exigiria `LVM_SETITEMSTATE` (mensagem que este
  projeto evita por risco de travar o processo alvo, ver módulo 37) ou clique real de mouse na máquina
  do usuário; ficou verificado por revisão de código + reuso da mesma lógica já testada de
  `OpenDocumentDialog`. Ver `docs/SPEC.md` módulos 43/44, `docs/RELEASE_NOTES.md` `8.4.0`.
- **2026-08-24 — comando `CL` do Mamute Assembler ("calculadora")**: pedido explícito do usuário,
  inspirado no comando `CL` do monitor **SUPER-X**. Converte um número (ou avalia uma expressão
  matemática completa) e mostra o resultado em quatro formatos de uma vez — `HEX`, `BIN` (16 bits),
  `DEC+` (sem sinal) e `DEC+-` (com sinal) — sempre em 16 bits, com wraparound. Números seguem a
  convenção já estabelecida no resto do Mamute (hexa por padrão), estendida com sufixos opcionais
  `D`/`B`/`H`/`O` (decimal/binário/hexa/octal) — sufixo só vale se os dígitos antes dele forem válidos
  naquela base (`10D` = decimal 10; pra hexa `10D` de verdade, `10DH` explícito), mesma regra clássica
  M80/Nestor80 do `Z80Asm.pbi`, só com o padrão trocado de decimal pra hexa. Aceita `+ - * / %`
  (módulo) `| & ^` (or/and/xor bit a bit) `!` (not bit a bit, unário) e parênteses, com precedência
  estilo C — deliberadamente **diferente** do SUPER-X original, que não tem precedência nenhuma
  ("calculated from left to right"); decisão registrada em `docs/SPEC.md` módulo 45 pra manter esse
  padrão em qualquer comando futuro portado do SUPER-X. Avaliador novo e autocontido em
  `editor/MamuteSupport.pbi` (`Mamute_CL_Eval`/`Mamute_CL_ParseNumber`, descida recursiva clássica),
  sem depender do `Z80Asm::EvalExpr` (motor errado pro caso — símbolos/segmentos, padrão decimal).
  Verificado com um harness de console isolado descartável (27 casos: todos os formatos de número, todos
  os operadores, precedência, parênteses, unário, wraparound, divisão/módulo por zero, sintaxe inválida)
  antes de descartar o harness, mais `build.ps1` limpo de ponta a ponta.
- **2026-08-24 (mesma sessão) — SUPER-X: inventário e roteiro de comandos pro Mamute Assembler, sem
  código**: pedido explícito do usuário, mesmo espírito do módulo 31 (que portou o MegaAssembler) — agora
  a fonte é o monitor/debugger **SUPER-X** (Copyright 1994 Romi, versão estendida por NYYRIKKI 2011),
  material novo em `others/superx/` (`SUPER-X.DOC.pdf` lido página a página nesta sessão; `SUPER-X.ASM`/
  `LOADER.ASM` como referência de comportamento pra quando for implementar de verdade, mesmo tratamento
  de licença já dado a `badig/`/`fmsx/` — especificação a portar, não código a copiar). Inventário
  completo dos ~45 comandos do SUPER-X, mapeado contra os comandos que o Mamute já tem hoje: colisões de
  letra com significado diferente (`D`/`M`), comandos já cobertos por outro nome (`BT`≈`T`, `FL`≈`F`,
  `TK`≈`S`, `GO`≈`G`, `RG`≈`X`+breakpoint do `G`), e o restante livre pra portar com o mesmo nome do
  original. Roteiro em 6 fases por reaproveitamento de motor já existente (utilitários triviais →
  memória via `Mamute_ReadByte`/`WriteByte` → disassembler `L`/`LP` pro `SD` → setor cru do `ZAP` pro
  `S%`/`L%` → `LOAD`/`SAVE` sem cabeçalho pro `S#`/`L#` → motor novo: `RT`/notas `iM`-`iS`/`OF`/`SF`/
  `BL`/`BF`/`TR`, este último quase de graça reaproveitando `Mz80_ExecuteOne` do módulo 32). Casos
  explicitamente fora de escopo por enquanto (turboR `CU`, mapeador `PP`, fonte japonesa `KR`/`KT`/`KL`,
  cor de tela `CO` — conflita com o visual verde-sobre-preto deliberado do módulo 31, portas de I/O
  `PI`/`PO` sem hardware simulado atrás, `CD` sem conceito de diretório corrente no modelo atual de
  arquivo). Nenhum comando novo implementado ainda — registrado em `docs/SPEC.md`, módulo 45, aguardando
  o usuário priorizar a ordem das fases.
- **2026-08-24 (mesma sessão) — comandos `XD`/`XM` do Mamute Assembler, primeiros dois portados do
  SUPER-X**: pedido explícito do usuário, direto sobre a lista do módulo 45 — começar pelo `D`/`M` do
  SUPER-X, batizados `XD`/`XM` (prefixo `X`) pra não colidir com o `D`/`M` que o Mamute já tem (módulo 31,
  significado diferente). `XD` (`editor/MamuteXdGui.pbi`, novo) abre a mesma grade hexa+ASCII de 128 bytes
  do `DM`/`M` (arquivo copiado e adaptado, não uma 3ª flag no compartilhado `M`/`S`) com duas diferenças:
  bloco ASCII também editável (tecla `"` entra em digitação direta) e `@` repete o byte anterior; dois
  endereços em vez de um viram despejo não-interativo pro log (mesmo `Mamute_BuildDumpLines()` do `D`).
  Achado real: `"`/`@` não têm constante `#PB_Shortcut_*` no PureBasic (só `0`-`9`/`A`-`Z`/`F1`-`F24`/
  setas, confirmado no help local do compilador) — capturadas via `#PB_EventType_Input`/`#PB_Canvas_Input`
  no `CanvasGadget` em vez de `AddKeyboardShortcut`. `XM` (`editor/MamuteXmGui.pbi`, novo) abre uma janela
  dedicada com prompt `ENDEREÇO>` que monta instrução Z80 de verdade a cada linha digitada, reaproveitando
  100% do `Z80Asm::ParseLine`/`EncodeInstruction` (mesmo motor do comando `A` do `EDIT`, nenhum encoder
  novo) — mais sinais de tipo `.`/`:`/`;`/`[`/`"` pra gravar dado cru, salto de endereço, e `I [<n>]`
  reaproveitando o disassembler do `L`/`LP`. Achado real de ambiguidade resolvido antes de virar bug:
  `DAA`/`CCF` são os únicos dois mnemônicos Z80 sem operando cujo nome também é hexadecimal válido —
  digitar `DAA` batia com "salta pro endereço 0DAAh" antes de tentar como instrução; corrigido checando
  `Z80Asm::IsMnemonic()` primeiro (regra geral, cobre qualquer colisão futura, não um if-especial). Cada
  item de dado do `XM` passa pela mesma calculadora do `CL` (`Mamute_CL_Eval()`), o que motivou uma
  extensão real nela: literal ASCII entre aspas (`'A'`/`"AB"`, até 2 chars, mesma sintaxe do
  `Z80Asm::EvalExpr`) — com um efeito colateral documentado (`4d`/`4D` viram decimal 4, não hexa 4Dh, por
  causa da prioridade de sufixo já existente; precisa de `4DH` explícito), inclusive avisado na `Ajuda`.
  `*Ptr.String` evitado de propósito (bug real já documentado no `CLAUDE.md`) — erros/log de texto viajam
  por `Global`, só endereço por `*Ptr.Integer`. Verificado com dois harnesses de console isolados
  descartáveis (`XmTestCli.pb`: 16 casos incluindo `Z80Asm.pbi` real + stub de memória plana; extensão do
  `CL`: literal ASCII/escape/erros) e `build.ps1`/compilação direta limpos — o `.exe` real de `dist/` não
  pôde ser regravado nesta sessão a princípio (duas instâncias já rodando, arquivo travado) — usuário
  fechou as duas, `build.ps1` rodou de verdade, e o `.exe` real foi lançado e testado ao vivo (`XD 4000`
  abriu a janela certa com a grade real; `XM 4000` + `NOP` gravou `00` e ecoou `4000  00  NOP` no log,
  avançando o prompt pra `4001>`) dirigido por `WM_COMMAND`/`WM_SETTEXT` direto nos HWND reais, já que
  clique de mouse simulado se mostrou não-confiável nesta sessão (o foco voltava sozinho pro terminal do
  Claude Code entre chamadas de ferramenta). Ver `docs/SPEC.md`, módulo 45a.
- **2026-08-24 (mesma sessão) — endereçamento estendido do SUPER-X (`#slot[-subslot]`/`#V`/`#4`/`#S`/`#5`)
  no `XD`/`XM`**: pedido explícito do usuário — `C000` edita a página 3 do slot mapeado agora pelo
  `PAGE`; `C000#3` edita o slot 3 direto, mesmo sem estar comutado em nenhuma página; `C000#3-1` mira o
  sub-slot 1 do slot 3 (slot expandido — MSX de verdade suportava até 1MB de RAM assim, 4 slots × 4
  sub-slots × 64KB; existiu até cartucho comercial de 64KB de RAM que somado aos 64KB padrão rodava CP/M
  com 128KB). Decisão de escopo: só vale pros comandos portados do SUPER-X (`XD`/`XM` e futuros) — `D`/
  `M`/`T`/`F`/etc. continuam só `PAGE`-relativos. Motor novo e compartilhado em `MamuteSupport.pbi`:
  `MamuteMemSub()` (array paralelo só pros sub-slots 1-3 — `MamuteMem()` continua sendo o sub-slot 0,
  sem realocar nada, zero risco pro que já existe), `Structure MamuteSxTarget` +
  `Mamute_ParseSxAddr()`/`Mamute_SxReadByte()`/`Mamute_SxWriteByte()`/`Mamute_SxWrapAddr()`. `#V`/`#4`
  precisou da primeira função de ESCRITA de VRAM do projeto (antes só existia leitura, `V`/`P`). Achado
  real de fidelidade ao manual, corrigido antes de virar bug: a doc do SUPER-X diz que endereço SEM
  sufixo assume "o slot atual" (não o `PAGE`) — um salto sem `#` no `XM` precisa MANTER o alvo explícito
  já ativo, não resetar sozinho; só `#S`/`#5` explícito volta pro `PAGE` de propósito. Também achado e
  corrigido: sufixo `"3-"` (traço sem nada depois) estava sendo aceito como "sem sub-slot" em vez de
  rejeitado como malformado. Verificado com dois harnesses de console isolados (27 casos no motor +13 no
  `XM`, incluindo a semântica "sticky" e `DAA`/`CCF` continuando instrução mesmo com alvo explícito
  ativo) e ao vivo contra o `.exe` real: `XD C000#3-1` → título e rótulo corretos; sessão `XM 4000#3-1` →
  grava, salta com `D010` (sem sufixo, mantém `#3-1`), grava de novo, tudo confirmado byte a byte no log
  real da janela. Ver `docs/SPEC.md`, módulo 45b.
- **2026-08-24 (mesma sessão) — prefixo `?` (saída "impressora" = PDF) nos comandos do SUPER-X**: pedido
  explícito do usuário ("Todos os comandos do Super-X se forem precedidos de ? a saída é na impressora,
  que no nosso caso é um PDF"), confirmado na doc original do SUPER-X. `MamuteGui_Dispatch()` detecta um
  `?` líder antes de separar verbo/argumentos e vira um `PrinterMode` passado pro comando; se o verbo não
  entender impressão (só `XD` por enquanto — `XM` é sessão interativa, não tem listagem pra imprimir),
  mostra `?IMPRESSAO NAO APLICAVEL A ESTE COMANDO` sem nem chegar no comando. `?XD <inic>,<fim>` gera o
  MESMO PDF que `P` já gera pro `D` (`Mamute_SavePdfListing()`, código copiado/adaptado de
  `MamuteGui_CmdP`); `?XD <endereço>` (a forma de UM endereço, que abre grade interativa) mostra
  `?IMPRESSAO SO FUNCIONA COM DOIS ENDERECOS` em vez de tentar imprimir uma sessão de edição. Verificado
  ao vivo contra o `.exe` real: os três casos de erro (`?XD` com um endereço, `?XM`, `?FOOBAR`) e o
  caminho de verdade (`?XD 4000,4010` abre o diálogo nativo "Salvar listagem (?XD) como PDF" de verdade,
  confirmado por título via `EnumWindows`, fechado sem gravar e o log mostrando `CANCELADO`). Ver
  `docs/SPEC.md`, módulo 45c.
- **2026-08-24 (mesma sessão) — variáveis de debugger `@0`-`@3`/`@B`/`@E`/`@S` do SUPER-X**: pedido
  explícito do usuário, com uma divergência real corrigida antes de codar — o usuário descreveu "7
  variáveis, `@0` a `@6`" mais as 3 especiais, mas reler o manual mostrou "7 Addresses... Normal
  variables are numbered from 0 to 3" (7 no TOTAL = 4 normais + 3 especiais, não 10); confirmado com o
  usuário via pergunta direta, foi pra opção fiel ao manual. Cada variável guarda um endereço COMPLETO
  (número + alvo/slot/sub-slot/VRAM). `@<nome>=<endereço>[#slot]` define; `@` sozinho no prompt mostra
  as 7; `@<nome>` depois substitui um endereço inteiro em qualquer comando do SUPER-X (`XD @0` em vez de
  `XD 8000#3-1`) — mesma decisão de escopo do `#slot`/`?` (só `XD`/`XM`/futuros). Dentro de expressões da
  calculadora (`CL`, e os campos de dado do `XM`), `@<nome>` vira só o número gravado, sem alvo — `CL
  @1+1`, exemplo direto do próprio manual. `Mamute_ParseSxAddr()`/`Mamute_CL_Tokenize()` estendidos
  (automaticamente valem em todo lugar que já os chamava, sem tocar em `XD`/`XM`); `Mamute_VarStoreBase()`
  novo implementa "commands store base address in variable 0" (mesma seção do manual) — `XD`/`XM` já
  gravam `@0` sozinhos ao abrir. Verificado com harness de console isolado (21 casos) e ao vivo contra o
  `.exe` real: `@0=8000#3-1`/`@1=FF2` ecoam certo, `@` lista as 7, `CL @1+1` → `HEX : 0FF3H` (idêntico ao
  exemplo do manual original), `XD @0` abre `Mamute Assembler - XD (SUPER-X) #3-1`. Ver `docs/SPEC.md`,
  módulo 45d.
- **2026-08-24 (mesma sessão) — carregador do arquivo de notas do SUPER-X + ajuda traduzida**: pedido
  explícito do usuário ("Por hora apenas carregue estas notas na memoria, vamos usar elas em outros
  comandos" + "adicione o conteudo destas notas no help do Mamute Assembler na parte modo Super-X" +
  "Traduzir todas as 471"). Escopo desta sessão: só o parser/carregador nativo e a ajuda traduzida — os
  comandos `MON>` (`iL`/`iM`/`iC`/`iS`) mencionados na doc original ficam pra uma fase futura.
  `MamuteNotesData.pbi` (novo) lê o formato binário do `SUPER-X.TNK` (2 bytes de contagem + até 512
  registros fixos de 64 bytes cada — endereço/slot/tipo/texto) pra `Global NewList MamuteNotes()`, texto
  guardado cru sem decodificar. Dois achados reais confirmados contra o arquivo de exemplo original
  (terceiro, gitignored, nunca copiado pra `dist/`): o campo de contagem é o número de notas GRAVADAS (não
  "notas que sobram" como a doc em inglês sugere) e o arquivo real tem 126 bytes a mais que o formato
  documentado (lixo/padding, tolerado pelo carregador); e o texto de 60 bytes de cada nota é Shift-JIS de
  katakana meia-largura — não um encoding proprietário como se suspeitava antes de examinar os bytes de
  verdade. Novo harness `src/editor/tools/MamuteNotesTestCli.pb` confirmou as 471 notas reais carregando
  certo (BIOS=130 WORK=224 DATA=5 PORT=25 HOOK=87). As 471 notas foram traduzidas do japonês pro português
  técnico e viram `MamuteSuperXNotesHelpData.pbi` (novo) — 11 tópicos de Ajuda no grupo "SUPER-X - Notas"
  (introdução + BIOS/WORK/DATA/PORT/HOOK, alguns divididos em partes pelo limite de ~8192 caracteres por
  literal do `pbcompiler.exe`, mesma técnica já usada em `EDIT`/`EDIT - Montar`). `build.ps1` rodado limpo
  no fim. Ver `docs/SPEC.md`, módulo 45e.
- **2026-08-24 (mesma sessão) — cruz de modos (Dump/Ascii/Char/Multi/Disasm) no `XD`**: pedido explícito
  do usuário ("coloque os botoes ASCII, Dump, Char, Multi e Disasm... em cruz como no Super-X original,
  assim o usuario pode dinamicamente mudar o display"), replicando o menu em cruz do SUPER-X original
  (Dump no topo, Ascii/Char/Multi na linha do meio, Disasm embaixo). Escopo confirmado com o usuário antes
  de codar: construir a cruz agora, ligando só o que já existia — **Dump** é a própria grade do `XD`
  (botão em destaque, sem ação); **Multi** fecha a janela do `XD` e abre `MamuteXm_Open()` no mesmo
  endereço/alvo (`Declare.i MamuteXm_Open(...)` antecipado em `BadigEditor.pb`, já que `MamuteXdGui.pbi`
  é incluído antes de `MamuteXmGui.pbi`; `AlreadyClosed.b` novo evita fechar a janela duas vezes). **Ascii**/
  **Char**/**Disasm** ficam como placeholders esmaecidos (estilo cinza em `MamuteXd_DrawModeButton()`) que
  só mostram "AINDA NAO IMPLEMENTADO" no rótulo de status — cada um seria um subsistema do tamanho do
  próprio `XD`, fica pra sessões futuras. Cruz posicionada à direita da grade (não abaixo, pra não esticar
  a janela verticalmente), centralizada na altura da grade. Verificado ao vivo contra o `.exe` real:
  screenshot confirmando o layout em cruz e os 3 estilos visuais; clique real no botão Multi confirmado
  fechando `XD` e abrindo `Mamute Assembler - XM (SUPER-X)` no mesmo endereço (`4000>`). Ver
  `docs/SPEC.md`, módulo 45f.
- **2026-08-24 (mesma sessão) — `<fim>`/`<arquivo>` opcionais no `XD`**: pedido explícito do usuário
  ("coloque agora os outros parametros, <inicio>#<slot>-<subslot>,<fim>,arquivo... se for dado um nome
  de arquivo, abra o dialogo pra salvar a saida do comando como um arquivo binario... use o mesmo
  dialogo que ja existe"), completando a sintaxe `<inic>[#slot][,<fim>[,<arq>]]` do `D` original do
  SUPER-X. Achado real corrigido no caminho: a forma de dois endereços do `XD` nunca honrava o sufixo
  `#slot[-subslot]`/`#V`/`#S` no início (usava `Mamute_ParseHexAddr` puro) — corrigido com
  `Mamute_ParseSxAddr()` + nova `Mamute_BuildDumpLinesSx()` (`MamuteSupport.pbi`, honra
  `MamuteSxTarget` via `Mamute_SxReadByte()`; a `Mamute_BuildDumpLines()` original fica intocada,
  continua servindo `D`/`P`/`V`). Terceiro campo (`<arquivo>`) lê o intervalo byte a byte pra um buffer
  explícito e abre a MESMA janela do comando `SAVE` (`MamuteSave_Open()` com `UseExplicitBuffer=#True`),
  nome sugerido a partir do que foi digitado — mesma técnica do "A I" do `EDIT`. `?` (impressão) +
  `<arquivo>` juntos são rejeitados (`?IMPRESSAO NAO APLICAVEL A ESTE COMANDO`); vírgula sobrando sem
  nada depois é erro de sintaxe. Verificado ao vivo: `XD 4000#0,4010` funcionando pela primeira vez;
  `XD 4000,4010,dump_teste.bin` abriu o SAVE com todos os campos pré-preenchidos certos (confirmado via
  `WM_GETTEXT`/`CB_GETCURSEL`), clique real em "Salvar" gravou 24 bytes byte-a-byte idênticos ao dump em
  texto (cabeçalho `FE`+enderecos + os 17 bytes do intervalo). Ver `docs/SPEC.md`, módulo 45g.
- **2026-08-24 (mesma sessão) — comando `XA` (porta do `A`) + default de 256 bytes sem `<fim>`**: pedido
  explícito do usuário ("ele e igual ao XD... o processo e o mesmo do anterior, alias quando nao
  informar fim, assuma 256 bytes nos comandos"), portando o `A` do SUPER-X (listagem/edição ASCII em tela
  cheia) com o mesmo mecanismo de endereçamento/`<fim>`/`<arquivo>` do `XD` (módulo 45g). Decisão de
  escopo confirmada via pergunta direta: construir uma tela NOVA só ASCII (`MamuteXaGui.pbi`,
  `MamuteXa_Open()`), não reaproveitar a grade do `XD` — grade 16×16 = 256 bytes/tela, tamanho escolhido
  de propósito pra bater com o novo default de 256 bytes. Sem coluna hexa, sem modo de "digitação"
  separado (a tela inteira já é só ASCII), sem `@`/Offset (não fazem sentido fora do contexto hexa do
  `XD`). Novo default "sem `<fim>`, assume 256 bytes" (aplicado nos DOIS comandos, `XD` e `XA`): aceita
  `<inic>,,<arquivo>` (vírgula dupla) OU o atalho `<inic>,<arquivo>` (dois campos, segundo campo vira
  `<arquivo>` se não parsear como endereço) — nova `Mamute_SxMaxAddr()` clampa `StartAddr+255` no teto do
  alvo em vez de dar a volta. Cruz de modos (módulo 45f) ganhou os dois sentidos: `XA` nasce com Ascii
  ativo e Dump/Multi já ligados pro `XD`/`XM`; a cruz do `XD` teve seu botão Ascii (antes placeholder)
  ligado de volta pro `XA`. Verificado ao vivo: despejo explícito/default-256/atalho-arquivo/`?XA`→PDF/
  slot explícito/erros de sintaxe todos batendo; SAVE do atalho gravou 263 bytes (7 cabeçalho + 256 dados)
  com `Endereco final` pré-preenchido `40FF`; tela interativa screenshot-confirmada; as três pontes de
  cruz (XA→XD, XD→XA, XA→XM) confirmadas por clique real. NÃO verificado ao vivo: digitação de caractere
  na grade do XA — três técnicas de injeção de teclado sintético falharam neste ambiente de automação
  (cliques de mouse continuaram funcionando); mecanismo é cópia literal do bloco ASCII do `XD`, já
  verificado antes, mas fica como lacuna registrada. Ver `docs/SPEC.md`, módulo 45h.
- **2026-08-24 (mesma sessão) — comando `XI` (porta do `I`, visualização de disassembly)**: pedido
  explícito do usuário ("XI que lista o disassembly do endereco inicial, ate o final (opcional) ou
  salva com nome (opcional) igual aos outros comandos acima"), mesmo mecanismo de campos/default de 256
  bytes do `XD`/`XA` (módulos 45g/45h). Duas decisões de escopo confirmadas via pergunta direta: 1) `XI
  <endereco>` sozinho abre uma tela NOVA de visualização (sem edição/pilha jump-call, fica pra depois);
  2) o terceiro campo `<arquivo>` salva a LISTAGEM DE TEXTO do disassembly direto (nova
  `Mamute_SaveTextListing()`), não bytes crus via SAVE como no `XD`/`XA` (seria redundante). Achado real:
  o motor de disassembly (`Mamute_DisasmOne()`/`Mamute_DisasmBuildLines()`, módulo 31) sempre leu memória
  via `Mamute_ReadByte()` puro, nunca honrou slot/VRAM — em vez de duplicar o motor inteiro (tabelas de
  opcode Z80, código historicamente delicado), toda a cadeia de decodificação ganhou um parâmetro
  OPCIONAL `*T.MamuteSxTarget = 0` (nova `Mamute_DisasmRb()` decide entre `Mamute_SxReadByte()` ou o
  clássico conforme `*T`) — os 7 call sites pré-existentes (`L`/`LP`, debugger, log de step da CPU)
  continuam chamando sem esse parâmetro, comportamento IDÊNTICO a antes (confirmado: `L 4000,4010` vs
  `XI 4000,4010` byte-a-byte idênticos). `MamuteXiGui.pbi` (novo): `EditorGadget` somente-leitura
  mostrando ~30 instruções, paginação por nudge ±1 byte (ressincronização manual) + PgDn exato (usa o
  `NextAddr` real) + PgUp heurístico (largura do bloco atual). Cruz de modos: `XI` nasce com Disasm ativo
  e Dump/Ascii/Multi ligados pro XD/XA/XM; as cruzes do XD e do XA tiveram seu botão Disasm (antes
  placeholder) ligado de volta pro XI — com isso, **Char é o único placeholder restante em toda a cruz de
  5 modos**. Verificado ao vivo: regressão L/XI idêntica; slot explícito sem erro; atalho de 256
  bytes+arquivo gravou `.txt` real de 132 linhas; `?XI` abriu o diálogo de PDF de verdade; tela
  interativa screenshot-confirmada; PgDn/PgUp funcionando; as 5 pontes de cruz (XI→XM, XI→XD via Dump,
  XI→XA via Dump-XA, XD→XI, XA→XI) confirmadas por clique real. Ver `docs/SPEC.md`, módulo 45i.
- **2026-08-26 — release 8.6.0 "CRUZ CURADA": mais 13 comandos do SUPER-X, execução real e cor** —
  sessão longa fechando o arco começado em 8.5.0 (CRUZ MANCA). Antes desta entrada, `XH`/`XBT`/`XRT`/
  `XFL`/`XCM`/`XFD`/`XCO`/`XCS`/`XTS` já tinham sido implementados sem passar por `docs/SPEC.md`/
  `CHANGELOG.md` (lacuna de documentação encontrada e registrada agora, não escondida) — `XRG`/`XGO`/
  `XTR`/`XSD` são desta sessão, com módulos 45j-45n documentados em `docs/SPEC.md`.
  - **`XH`** — porta o `H` do SUPER-X: editor de caractere/sprite (bitmap 16×16, grade de pixel
    editável, 4 caracteres consecutivos por tela, miniatura 2×2 montada). Com ele, **a cruz de modos
    fecha** — os 5 modos (Dump/Ascii/Char/Multi/Disasm) agora ligam todos pra uma tela de verdade, zero
    placeholders restantes (a "perna manca" do nome da 8.5.0).
  - **`XBT`/`XRT`/`XFL`/`XCM`/`XFD`** — ferramentas de memória "intra-slots" (origem/destino podem ser
    slots/sub-slots/VRAM totalmente diferentes, sem precisar trocar `PAGE`): `XBT` transfere um bloco
    (memmove seguro, sem sobrepor incorretamente); `XRT` faz o mesmo mas também ajusta ponteiros
    internos absolutos que apontem pro bloco movido (limite aceito: só instruções reais decodificadas,
    dados inline no meio do código podem confundir); `XFL` preenche um bloco com um byte; `XCM` compara
    dois blocos byte a byte (lista diferenças, ou iguais com `,S`); `XFD` busca um PADRÃO DE INSTRUÇÃO
    (não bytes crus) usando o mesmo decodificador do `L`/`LP`/`XI` — limite documentado pra `JR`/`DJNZ`
    (saltos relativos codificam bytes diferentes conforme a posição).
  - **`XCS`/`XTS`** — dupla de checksum: `XCS` alterna o tipo usado pelo despejo do `XD` (soma simples
    ou soma+endereço, 8 bits por linha); `XTS <inic>,<fim>` calcula UM checksum agregado de 16 bits do
    bloco inteiro, mostrado em HEX/BIN/DEC+/DEC±/OCT.
  - **`XRG`** — mostra/edita os registradores Z80 simulados em pares, incluindo os "secretos" (par
    alternado `AF'`/`BC'`/`DE'`/`HL'`, que nem o `X` mostra) e o `PC`. `XRG *` limpa tudo exceto a
    pilha; `XRG +` reseta só a pilha; `XRG <reg>,<valor>` edita qualquer registrador (`A`-`L` e o par
    alternado, `AF`-`HL`/`IX`/`IY`/`IXH`/`IXL`/`IYH`/`IYL`/`SP`/`PC`) mais 5 breakpoints nomeados —
    `BP`/`BP1`/`BP2`/`BP3`/`BPF` — usados pelo `XGO`.
  - **`XGO <endereço>[#slot]`** — porta o `GO`: executa o programa simulado (mesmo motor do `G`/
    debugger gráfico) a partir do endereço, parando no breakpoint da vez (`BP` na 1ª chamada, `BP1`/
    `BP2`/`BP3` nas seguintes sem endereço novo, `BPF` como fallback ou teto final). Sem breakpoint
    nenhum, roda "livre" até o `RET` que devolve pra além de onde começou, até `ESC`, ou até um teto de
    segurança — os três juntos, não escolhidos um por vez.
  - **`XTR <endereço>`** — trace passo a passo de verdade: executa uma instrução, mostra endereço/
    bytes/mnemônico + registradores, e abre um loop modal esperando `ENTER` (próxima instrução) ou
    `ESC` (interrompe) — encerra sozinho se a CPU haltar.
  - **`XSD`** — "super disassembler": ou gera uma listagem assembly reassemblável (`ORG` + mnemônicos,
    sem coluna de endereço/bytes) pra um compilador Z80 externo, ou despeja bytes crus em 3 formatos
    (`,B` = `DEFB`; `,D` = `DATA` em BASIC com prefixo `&H` + loop `FOR/READ/POKE/NEXT` gerado
    automaticamente; `,X` = dados embutidos do X-BASIC, `'#&Hxx,...`) — sempre abrindo "Salvar como"
    com o nome sugerido.
  - **`XCO` (batizado assim depois de nascer só `CO`, pra ficar consistente com o prefixo `X` do resto)
    — cor da tela de verdade**: paleta REAL e fixa do MSX1/TMS9918 (16 cores, não editável, mesma do
    hardware), `XCO [<frente>],[<fundo>],[<borda>]` em DECIMAL (não hexa — mesma convenção do `COLOR`
    do MSX BASIC). Achado real na implementação: as cores do terminal (verde-sobre-preto) estavam
    hardcoded independentemente em **12 arquivos, 72 lugares** — todos migrados pra ler de 3 funções
    novas (`Mamute_CurrentFrontColor`/`BackColor`/`BorderColor`, `MamuteSupport.pbi`); uma colisão
    incidental (a cor de RAM no minimapa do debugger gráfico coincidia por acaso com a cor de tema) foi
    protegida em vez de trocada, pra não acoplar a codificação visual RAM/ROM/BASIC ao tema. Persistido
    em `mamute_settings.json`, vale a partir da próxima janela aberta.
- **2026-08-26 — release 8.7.5 "NOTA NA PORTA": notas por endereço + painel de portas I/O** — dois
  recursos novos e independentes no mesmo dia. Sistema de **notas por endereço** (`XIM`/`XIC`/`XIL`/
  `XIS`/`XIR` no Mamute Assembler, docs/SPEC.md módulos 45x-45z): `XIM` adiciona uma nota
  `<endereço>,<slot>,<tipo>,<texto>`; `XIC <endereço>` consulta todas as notas daquele endereço (17
  coincidências reais confirmadas entre as 471 notas originais); `XIL`/`XIS` carregam/salvam um
  arquivo de notas num formato texto novo (UTF-8, `ENDEREÇO;SLOT;TIPO;TEXTO`, criado porque o binário
  original de 60 bytes/nota truncaria traduções mais longas); `XIR` abre um visualizador dedicado
  (uma nota por tela, botões de navegação, busca texto/regex reaproveitando o campo já existente do
  `XTP`). As 471 notas do arquivo de exemplo original, já traduzidas, viraram `SUPER-X-PT.notas`
  (extraído da Ajuda via script Python descartável, dois bugs reais de parsing corrigidos — texto com
  `+` literal dentro de aspas confundindo um split ingênuo com a concatenação do PureBasic). Novo campo
  "Notas SUPER-X padrão" em `Configurar → Mamute Assembler...` carrega um arquivo automaticamente na
  abertura; escolher justamente o `SUPER-X-PT.notas` original marca ele como somente-leitura e cria uma
  cópia editável (`SUPER-X-SHADOW.notas`) automaticamente, pra nunca sobrescrever o original.
  - **Painel de Portas I/O** (`XPP`/`XPI`/`XPO`, docs/SPEC.md módulo 46) — achado real que motivou tudo:
    `MamuteZ80Cpu.pbi` já tinha as 6 instruções de I/O do Z80 decodificadas (`OUT (n),A`/`IN A,(n)`/
    `IN r,(C)`/`OUT (C),r`/`INI`/`IND`/`OUTI`/`OUTD`), mas todas eram stubs "Fase 1, sem dispositivo
    real" — todo `OUT` descartava o byte, todo `IN` sempre devolvia `$FF`. `XPP` abre um painel que
    monitora até 256 portas (`Entrada` = último byte que o programa mandou via `OUT`; `Saída` = o que
    uma `IN` vai ler, digitado manualmente pelo usuário já que ainda não existe simulação de hardware de
    verdade), com botões incluir/excluir porta e destaque visual nas portas alteradas. `XPI <porta>`/
    `XPO <porta>,<byte>` leem/escrevem uma porta manualmente. As 6 instruções da CPU foram religadas
    pra usar o painel de verdade em vez dos stubs antigos — `PI`/`PO` do inventário original do SUPER-X
    (módulo 45), antes marcados "fora de escopo, utilidade questionável sem hardware real atrás", saem
    da lista de pendências; `XPP` em si não tem equivalente no SUPER-X original (não confundir com o
    `PP` do inventário antigo, mapeador de RAM/segmentos, ainda não portado).
  - Lógica de dados nova (lista de portas em ordem crescente, parser/gravador do arquivo de notas)
    verificada com testes isolados fora do projeto antes de confiar — incluindo os 2 casos de fronteira
    do espaço de portas (porta `0` e `255`) e um ciclo completo grava→recarrega do arquivo de notas.
    36 comandos com prefixo `X` ao todo nesta versão. Compilado limpo a cada bloco de mudança; sem
    verificação ao vivo das janelas novas nem de um programa real executando `OUT`/`IN` (mesmo bloqueio
    de teclado sintético neste ambiente de automação, já documentado no módulo 45h).
