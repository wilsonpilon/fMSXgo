# Paleobasic

*(IDE MSX BASIC + Z80, antigo "Basic Dignified Editor")*

![MSX BASIC + Z80 IDE — Basic Dignified, Assembly, integrado](resource/branding/paleobasic.png)

![Editor com destaque de sintaxe para o dialeto Basic Dignified](docs/images/msxbasica-01.png)

**Versão atual: 8.7.5** — versão e build (data/hora UTC de compilação, em
hexadecimal) são embutidas no executável pelo `build.ps1` e exibidas em `Ajuda → Sobre...`.

IDE nativa em **PureBasic** para desenvolvimento em MSX BASIC (dialeto "Dignified", sem números de
linha) e Z80 assembly, construída em torno de um editor com highlighting via Scintilla e um
pré-processador/tokenizador reescritos nativamente — sem depender de Python instalado na máquina do
usuário final.

> Documento vivo. O detalhe completo da especificação (escopo, decisões de arquitetura, módulos
> planejados) está em [`docs/SPEC.md`](docs/SPEC.md) — é a fonte de verdade do projeto. Para
> compilar, executar e usar o editor de texto (atalhos de teclado, busca/substituir), veja
> [`docs/MANUAL.md`](docs/MANUAL.md).

## Sobre o projeto

O ponto de partida foi um editor de texto simples para MSX BASIC. A ideia é fazer ele crescer até
virar uma IDE completa cobrindo todo o fluxo de desenvolvimento para MSX: BASIC + assembly Z80 +
assets gráficos/sonoros + build + debug direto no emulador, tudo num único executável PureBasic
autocontido (Windows/Linux), sem exigir Python nem outras dependências externas em tempo de execução.

O dialeto de entrada é o **Basic Dignified** (labels em vez de números de linha, includes, macros,
proto-funções, etc.), inspirado e compatível com o [Basic Dignified Suite](#agradecimentos) original em
Python — que serve de referência de comportamento a ser portada, não de dependência de runtime.

## Apelidos dos módulos (tema pré-histórico)

Puramente cosmético/interno — os nomes de arquivo e procedimentos continuam os mesmos, isso é só como
o time se refere a cada módulo em conversa e nos comentários de cabeçalho:

| Apelido | Módulo real |
|---|---|
| 🦣 **Mamute** | `src/editor/assemblers/MamuteAssemblerGui.pbi` — assembler Z80 |
| 🦖 **Raptor** | `src/editor/core/DignifiedPreprocessor.pbi` — pré-processador Dignified → ASCII |
| 🦕 **Compsognato** | `src/editor/core/MsxTokenizer.pbi` — ASCII → binário tokenizado |
| 🦕 **Diplodoco** | `src/editor/core/MSXDisk.pbi` + `src/editor/core/DiskManagerGui.pbi` — imagens `.dsk` |
| 🎨 **Pixelossauro** | `src/editor/visual_editors/Screen0EditorGui.pbi`, `Screen1EditorGui.pbi`, `Screen2EditorGui.pbi`, `Screen12EditorGui.pbi` — editores de tela pixel-a-pixel |
| 🦅 **Pteranodonte** | `src/editor/emulators/OpenMSXBridge.pbi` — ponte/lançamento do openMSX |
| 🦴 **Fossauro** | `src/fossauro/` — port nativo em PureBasic do fMSX (emulador MSX completo: Z80, memória/slots, PPI, VDP V9938, PSG), projeto irmão dentro do repositório principal |

## O que já temos

- **Editor** (`src/editor/BadigEditor.pb`) — `ScintillaGadget` com lexer próprio para o dialeto Dignified
  e outro para **Z80 Assembly** (`.asm`, dialeto do assembler
  [N80/Nestor80](https://github.com/Konamiman/Nestor80)), abas customizadas (fechar, hover, arrastar
  visual), régua de colunas, margem de números de linha dinâmica, **4 temas claros** (`Configurar →
  Editor...` — os 5 temas escuros foram removidos na 7.33.10, ver [Changelog](#changelog-resumido)) e
  estilo de abas moderno/clássico configuráveis. Teclado padrão Scintilla/Windows (sem
  modo próprio, ver [Changelog](#changelog-resumido) 2026-08-08) — Buscar/Substituir/Ir para linha
  (`Ctrl+F`/`H`/`G`) e mais de 30 atalhos cobrindo o resto da IDE, ver `docs/MANUAL.md`. Menu
  **Arquivo → Novo** (`.dmx`) e **Novo Assembly** (`.asm`, `Ctrl+Shift+N`) — cada aba detecta e lembra
  seu próprio tipo.

  ![Aba de Assembly Z80 com syntax highlight (mnemônicos, registradores, diretivas, rótulos)](docs/images/msxbasica-02.png)
- **Botões tematizados em toda a IDE, com ícones Nerd Font por padrão** (`src/editor/core/ThemedButtons.pbi`) —
  botão nativo do Windows (`ButtonGadget`) ignora completamente a cor do tema; os 311 botões da IDE
  (todas as telas de Configurar, editores visuais, gerenciador de disco, console do openMSX, telas de
  Ajuda) são desenhados na hora seguindo o tema escolhido, e mais de 140 trocam o texto por um ícone
  real de uma Nerd Font — a partir da 7.33.10, uma fonte de ícones vem empacotada com o executável
  (`resource/fonts/`) e é usada automaticamente, sem precisar configurar nada (`Configurar → Editor...
  → Fonte de ícones` deixa desligar ou trocar por outra), com tooltip mostrando o nome ao passar o
  mouse.
- **Pré-processador Dignified nativo** (`src/editor/core/DignifiedPreprocessor.pbi`) — **cobre 100% do escopo
  do `badig.py` original**: labels, loop labels, `EXIT`, `DEFINE` recursivo, `DECLARE` com redução
  automática de nomes longos, comentários/blocos de comentário, `TRUE`/`FALSE`, operadores compostos,
  proto-funções `FUNC`/`RET`, conversão `?`/`PRINT`, strip `THEN`/`GOTO`, tradução Unicode→charset
  nativo MSX, maiusculização, tamanho de TAB configurável, **`INCLUDE` recursivo** (namespace de
  label/loop/função isolado por arquivo, variáveis compartilhadas) e **remtags**
  (`##BB:arguments=`/`export_file=`/`help=`). Testado de ponta a ponta contra código de produção real
  (não só exemplos sintéticos — ver [`dist/sample/teste.dmx`](dist/sample/teste.dmx), ~900 linhas) e contra
  fixtures de `INCLUDE`/remtags. O `.exe` do editor não depende mais de Python em nenhum fluxo (menus
  legados removidos).
- **Tokenizador MSX-BASIC nativo** (`src/editor/core/MsxTokenizer.pbi`) — converte ASCII clássico em binário
  `.bmx`, validado byte a byte contra o tokenizador Python original.
- **Rodar no openMSX** (`RunOnOpenMSX()` em `src/editor/BadigEditor.pb`) — com a opção "Abrir o openMSX e
  rodar o código após gerar" marcada, tokenizar monta um disquete `.dsk` (`.dmx`+`.amx`+`.bmx` mais um
  `AUTOEXEC.BAS` de autorun) e abre o openMSX já rodando o programa, com a máquina/extensão
  configuradas. **Reaproveita a instância já aberta** em vez de lançar uma nova a cada execução
  (`OMSX_LoadDisk()`, `src/editor/emulators/OpenMSXBridge.pbi`) — igual F5 duas vezes seguidas troca só o disco e
  reinicia, sem abrir uma segunda janela. Rotinas de disco `.dsk` (FAT12) próprias em
  `src/editor/core/MSXDisk.pbi` (originalmente vendorizadas do projeto separado `msxDiskUtil`, depois
  incorporadas de vez e o diretório `msxDiskUtil/` removido do repositório — sem dependência externa
  nenhuma) — compiladas direto no executável do editor, sem depender de processo externo para montar
  o disco.
- **Painel de controle remoto do openMSX** (`Executar → openMSX...`, `src/editor/emulators/OpenMSXConsoleGui.pbi` +
  `src/editor/emulators/OpenMSXBridge.pbi`) — 6 abas cobrindo praticamente tudo que o Catapult original oferecia:
  **Console** (mídia, transferir programa, log, comando livre), **Outros comandos** (velocidade com
  Turbo segurando o mouse, Power/Reset/Pause, firmware, portas de joystick, Ren Sha Turbo), **Vídeo**
  (renderer, escala, Modo TV com as 5 opções reais do openMSX, efeitos estilo CRT com reset pro
  padrão, screenshot com numeração sequencial, LEDs visuais + STOP + FPS), **Volume** (mixer com
  **descoberta dinâmica** de dispositivo de som — os nomes reais variam por cartucho/ROM conectado,
  não são fixos —, Volume/Balance, MIDI in/out), **Input Text** (área grande + Type/Clear, mais uma
  **paleta de 23 teclas especiais** — ESC/F1-F5/setas/GRAPH/CODE/SELECT/STOP/etc. via tags `⟦NOME⟧`
  que nunca confundem com texto `[ESC]` literal, e **combos de tecla** `⟦SHIFT+F1⟧` que seguram todas
  antes de soltar, com "Modo Combo" pra montar isso clicando em vez de digitar) e **Status Info** (log
  passivo de tudo que o openMSX reporta). Barra inferior sempre visível ganhou um **display de FPS**
  dedicado (estilo mini-display digital) e um atalho de **Power**, pra não precisar mais trocar de aba
  só pra ver o FPS ou ligar/desligar. Ver [`docs/RELEASE_NOTES.md`](docs/RELEASE_NOTES.md) pro detalhe
  completo desta leva de features.
- **Telas de configuração nativas**:
  - `Configurar → Basic Dignified...` (`src/editor/core/BadigSettings.pbi`) — três abas: pré-processador/
    tokenizador, opções específicas do MSX, e **Emulador** (caminho do openMSX, máquina/extensão com
    botão de busca automática em `share/machines`/`share/extensions`, opção de rodar após gerar).
    Diretório de instalação do toolchain com botão para baixar o Basic Dignified Suite direto do
    GitHub (`git clone` ou `.zip`), tudo persistido em JSON.
  - `Configurar → openMSX...` (`src/editor/emulators/OpenMsxSettingsGui.pbi`) — os mesmos campos da aba "Emulador"
    acima, numa tela própria — lê/grava exatamente o mesmo `BadigCfg`/`badig_settings.json`, então as
    duas telas nunca divergem.
  - `Configurar → Editor...` (`src/editor/core/EditorSettings.pbi`) — fonte (só monoespaçadas, com suporte a
    pasta de fontes customizadas carregadas em memória), tema, estilo de abas, caminho de instalação do
    editor.
  - `Configurar → Basic Options...` (`src/editor/basic/BasicOptionsSettings.pbi`) e `Configurar → Assembly...`
    (`src/editor/assemblers/AssemblyOptionsSettings.pbi`) — liga/desliga o auto completar (ver item abaixo), quantidade
    de letras pra ativar e caixa das sugestões, uma tela por modo (BASIC/Dignified e Assembly guardam
    preferência independente).
- **Auto completar** — sugere, conforme você digita, palavras-chave do MSX-BASIC/Basic Dignified
  (incluindo os 87 wrappers `.NB_*` do NestorBASIC) e variáveis já usadas no documento em abas
  `.dmx`/`.bas`; mnemônicos/registradores/diretivas do Z80 e rótulos já definidos no documento em abas
  `.asm`. Navegação 100% nativa do Scintilla (Enter aceita, setas navegam, Esc cancela, digitar mais
  estreita a lista sozinho) — nenhuma tecla nova pra aprender. Caixa das sugestões configurável
  (maiúsculas/minúsculas/"como digitado") separadamente para BASIC e Assembly; variáveis/rótulos/
  `.NB_*` sempre mantêm a grafia original do documento. Ver [`docs/MANUAL.md`](docs/MANUAL.md#auto-completar).
- **Auto-indentação** — em abas `.dmx`/`.bas`, `Enter` copia a indentação da linha anterior (sem
  precisar de `Tab` manual toda hora). De propósito **não** tenta somar/tirar nível sozinha por bloco
  (`FOR`/`IF`/etc.) — uma versão anterior tentava isso mas gerava falso positivo em linhas terminando
  em `:` sem bloco nenhum; simplificado a pedido do usuário. Ver [`docs/MANUAL.md`](docs/MANUAL.md#auto-indentação).
- **CLI de teste de regressão** (`src/editor/tools/DigTestCli.pb`) — roda o pipeline completo
  (Dignified → ASCII → tokenizado) fora do editor, para validar mudanças no pré-processador/tokenizador.
- **Gerenciador de disco MSX** — `src/editor/core/MSXDisk.pbi` (FAT12, incorporado de vez ao editor — o
  diretório separado `msxDiskUtil/` que serviu de origem foi removido do repositório, 2026-07-28)
  agora também é exposto de duas formas prontas para uso, além de montar o disco de "rodar no
  openMSX":
  - **CLI embutida** (`PaleoBasic.exe --diskmanipulator <create|list|add|extract|delete> disco.dsk
    ...`) — mesma sintaxe do `msxdisk.exe` original, roda e sai sem abrir janela nenhuma.
  - **Menu Criar → Disco...** (`src/editor/core/DiskManagerGui.pbi`) — gerenciador gráfico com dois painéis
    (estilo Norton/Total Commander): esquerda é o sistema de arquivos local, direita é o conteúdo do
    disco. Botões **Adicionar >>**/**<< Extrair** sempre copiam (nunca apagam a origem); **Remover
    local**/**Remover disco** excluem de verdade, com confirmação. Todas as operações acontecem numa
    cópia de rascunho temporária — o `.dsk` escolhido só é gravado de fato em **Salvar**/**Salvar
    como...**/**Duplicar...**; **Cancelar** descarta a sessão sem tocar nele.

  ![Gerenciador gráfico de disco MSX (Criar → Disco...) com painel local à esquerda e disco à direita](docs/images/msxbasica-03.png)
- **Leitor e editor de Markdown (`.md`)** (`src/editor/core/MdViewerGui.pbi`, aba em modo "MD" —
  **Arquivo → Novo MD...** ou abrindo um `.md` existente) — highlight próprio de Markdown na aba
  normal, mais duas janelas auxiliares sobre o conteúdo dela: **Ver MD/TXT...** (`F9`) alterna, num
  popup somente-leitura, entre o texto cru e renderizado (reaproveita o motor de
  `GenericMdHelpGui.pbi`, os mesmos visualizadores de manual/BIOS/Livro Vermelho); **Ver MD+TXT...**
  (`Shift+F9`) abre um split editável/renderizado lado a lado, atualizado a cada tecla, que grava de
  volta na aba real (não numa cópia) — é a edição "ao vivo" de verdade. Pensado pra documentar um
  programa dentro do próprio `.msxproject` (ver Índice de recursos do projeto, logo abaixo) — ex.: o
  artigo de uma revista explicando como usar um type-in, lado a lado com o programa em si.
- **Sistema de projeto** (`src/editor/core/ProjectDB.pbi`, menu **Projeto**) — um projeto MSX inteiro
  (documentos de texto, sprites, alfabetos, sons PSG, SFX do SEE Tracker, músicas MML, telas nos vários
  formatos — Screen 0/1/2/1+2, Graphos III —, e Assembly Sub-Projects) vive num único arquivo SQLite
  (`.msxproject`). Ao abrir sem nenhum parâmetro de linha de comando, a IDE já cria/usa de cara um
  projeto implícito **"noname.msxproject"** num arquivo temporário — tudo que for registrado vai
  sendo gravado nele sem precisar criar um projeto antes. **Projeto → Novo projeto...** troca para um
  projeto novo e vazio num local escolhido (oferece salvar o atual primeiro, se tiver conteúdo não
  salvo); **Projeto → Abrir projeto...** abre um `.msxproject` já existente. **Projeto → Salvar
  projeto**/**Salvar projeto como...** salvam o projeto atual (o primeiro reaproveita o caminho já
  escolhido, sem diálogo; o segundo sempre pergunta um caminho novo, permitindo salvar uma cópia com
  outro nome) — extensão `.msxproject` é acrescentada automaticamente se não digitada. Ao sair, se o
  projeto implícito tiver conteúdo registrado e ainda não tiver sido salvo num arquivo permanente, a
  IDE pergunta se quer salvar (e onde, com nome definitivo) antes de fechar. O projeto também guarda
  uma cópia sempre atualizada do conteúdo de cada aba de texto já salva em disco e o diretório de
  trabalho (pasta do último arquivo salvo, ou o diretório corrente enquanto nada foi salvo ainda).
  **Arquivo → Salvar Tudo** (`Ctrl+Alt+S`) salva todas as abas abertas (uma por uma, na ordem, pedindo
  "Salvar como..." pras que ainda não têm nome) e o projeto atual numa ação só.
- **Índice de recursos do projeto** (`src/editor/core/ProjectIndexGui.pbi`, **Projeto → Índice de
  recursos...**, `Ctrl+Alt+R`) — catálogo, numa lista só, de tudo que o `.msxproject` atual guarda:
  documentos (rotulados por tipo — programa Basic Dignified/MSX-BASIC/Assembly, ou artigo Markdown),
  cada recurso numerado (sprite/alfabeto/som/SFX/música/tela/Graphos/Assembly Sub-Project) e qualquer
  `.dsk` ao lado do `.msxproject` (esses não ficam guardados dentro do banco, são achados escaneando a
  pasta). Pensado pra quem empacota vários programas + artigos explicativos num projeto só — ex.:
  digitando os type-ins de uma revista, um `.msxproject` por edição com os programas, os discos prontos
  e um `.md` por artigo (ver **Leitor e editor de Markdown**, acima). Dois
  cliques leva pro lugar certo: documento troca de aba (abre do disco se precisar), disco abre o
  Gerenciador de disco já com o arquivo escolhido, qualquer outro recurso abre o editor daquele tipo.
- **Associação de arquivo `.msxproject`** (`src/editor/core/FileAssociationGui.pbi`, **Configurar →
  Associações de arquivo...**) — liga/desliga, só no Windows, a associação de `.msxproject` com o
  Paleobasic (`HKEY_CURRENT_USER\Software\Classes`, sem precisar de administrador) — depois de marcada,
  dar 2 cliques num `.msxproject` no Explorer abre esse projeto direto na IDE (o caminho recebido na
  linha de comando é lido bem no início de `BadigEditor.pb`, antes de abrir a janela principal).
  Desmarcar só remove a associação se ela ainda apontar pra esta cópia do Paleobasic — nunca mexe numa
  associação de outro programa.
- **Editor de sprites** (`src/editor/visual_editors/SpriteEditorGui.pbi`, menu **Criar → Sprite...**) — grade clicável
  8×8 ou 16×16 com a **palheta original de 16 cores do MSX1** (TMS9918), e radios **MSX1** (sprite
  inteiro com uma única cor) / **MSX2** (uma cor por linha, aplicada automaticamente conforme o
  sprite é pintado). Ferramentas com ícone próprio: lápis, borracha, pincel (bloco 2×2), balde de
  preenchimento, reta, retângulo e elipse/círculo (vazios ou cheios) — as ferramentas de dois pontos
  mostram prévia ao vivo da forma e um marcador piscando no primeiro ponto, com **Esc** ou o botão
  direito do mouse cancelando sem traçar nada. Botões de rotacionar (com quebra nas bordas) e
  deslocar (sem quebra) nas quatro direções, inverter e limpar. Cada sprite é numerado, tem uma tag
  (nome curto, até 16 caracteres) e fica gravado no projeto atual via o botão **Registrar**; **Novo**
  cria o próximo sprite em sequência, os botões de navegação vão para o primeiro/anterior/próximo/
  último sprite já registrado, e **Copiar**/**Colar** duplicam um sprite para outro número.

  ![Editor de sprites (Criar → Sprite...) com grade 16×16, paleta MSX1, barra de projeto (número, navegação, tag) e prévia em escala reduzida](docs/images/msxbasica-04.png)
- **Editor de alfabetos** (`src/editor/visual_editors/CharsetEditorGui.pbi`, menu **Criar → Alfabeto...**) — edita charsets
  no formato **`.ALF` do Graphos III**: 256 caracteres de 8×8 pixels (2048 bytes), binário MSX clássico
  com cabeçalho de 7 bytes (tipo `&HFE`, endereços inicial/final/execução — carregado originalmente em
  `&H9200`, a Pattern Generator Table da VRAM). Tabela com os 256 caracteres (16 por linha, cabeçalho
  hex de linha/coluna, miniatura de cada glifo) — clicar num caractere carrega seus pixels numa grade
  8×8 bem ampliada, onde dá pra ligar/apagar cada pixel (clique ou arrastar); **Registrar** grava os
  pixels editados de volta no caractere selecionado e atualiza a miniatura na tabela. **Carregar do
  Graphos III...**/**Salvar como...** leem e gravam `.alf` (extensão acrescentada automaticamente se não
  digitada) — carregar sempre importa como um alfabeto novo (nunca sobrescreve um já registrado).
  **Copiar**/**Colar** de um caractere isolado, de um **alfabeto inteiro** (Copiar alfabeto/Colar
  alfabeto) ou de um **intervalo marcado** (Marcar início/Marcar fim de bloco + Copiar bloco/Colar
  bloco) — todos com área de transferência da própria sessão. Com um intervalo marcado, o botão
  **Inverter** passa a inverter todos os caracteres do intervalo de uma vez direto no alfabeto (sem
  bloco marcado, afeta só o caractere atual) — combinado com Copiar/Colar bloco, permite duplicar um
  conjunto de caracteres (ex.: A..Z para a..z) e inverter só a cópia, tendo as duas versões lado a lado.
  Todos os botões de ação são **ícones monocromáticos** desenhados em memória (sem arquivo externo),
  com dica ao passar o mouse explicando cada função. Também integrado ao **sistema de projeto**, igual
  ao editor de sprites: um projeto pode ter vários alfabetos, com barra própria de número/tag/
  **Primeiro**/**Anterior**/**Próximo**/**Último**/**Registrar alfabeto**/**Novo alfabeto** (numera
  automaticamente e sempre parte do charset padrão do MSX, nunca em branco). Esse charset padrão vem de
  um **"projeto 0"** interno (`ProjectDB::EnsureDefaultsOpen()`) — um banco SQLite à parte, sempre em
  memória, nunca salvo, semeado com `alfabetos\msx.alf` **embutido no próprio `.exe`**
  (`src/editor/visual_editors/DefaultCharsetMsx.pbi`). Ganhou **11 botões de efeito** (todos com **Desfazer**/**Refazer**
  próprios, pilha de até 50 níveis): **All** (marca o alfabeto inteiro como bloco de uma vez),
  **Espelhar horizontal/vertical**, **Girar 90°**, **Apagar**, **Estreitar** (condensa o glifo em 3
  colunas, útil pra caber 64 colunas de texto onde só caberiam 32), **Itálico** (desloca linhas
  progressivamente), **Negrito**, **Largo** (+ variantes **Bold esquerda/direita** e **Largo bold**,
  que combinam alargar com engrossar) — todos seguindo o mesmo padrão dual já usado pelo Inverter: sem
  bloco marcado afetam só o caractere atual (precisa de "Registrar"), com bloco/All aplicam direto em
  todo o intervalo.

  ![Editor de alfabetos (Criar → Alfabeto...) com tabela de 256 caracteres, grade de edição ampliada e botões-ícone](docs/images/msxbasica-05.png)
- **Editor de alfabetos Aquarela** (`src/editor/visual_editors/AquarelaCharsetEditorGui.pbi`, menu **Criar → Alfabeto
  Aquarela...**) — edita o formato `.FNT` do **Aquarela**, outro editor de fonte MSX (alternativa ao
  Graphos III acima), com engenharia reversa completa documentada em `docs/reference/aquarela.md`.
  Diferente do editor Graphos III, é uma ferramenta **autocontida baseada em arquivo** (Novo/Abrir/
  Salvar/Salvar como), sem integração com o sistema de projeto. Glifo real **16×16** (2 planos de 16
  bytes — coluna esquerda e direita —, cada registro de 32 bytes começando 7 bytes depois do início
  nominal, confirmado pixel a pixel contra o Aquarela rodando de verdade num emulador). **46
  caracteres editáveis** (grade de 8 colunas × 6 linhas): `A-Z`, `&`, `?`, `!`, `"`, `0-9`, `.`, `:`,
  `-`, `(`, `)`, `,` — ordem confirmada por teste real do usuário. Salva sempre no formato de 2304
  bytes (72 registros), preenchendo o restante com o byte de posição-vazia padrão. Botões de ícone
  **Registrar**/**Limpar**/**Inverter**/**Copiar**/**Colar**, mesmo estilo visual do editor Graphos
  III.
- **Editor de som PSG** (`src/editor/visual_editors/PsgSynth.pbi` + `src/editor/visual_editors/PsgEditorGui.pbi`, menu **Criar → Som
  (PSG)...**) — editor de efeitos sonoros para o chip de som do MSX (AY-3-8910/YM2149), espelhando
  registrador por registrador o comando `SOUND` do MSX-BASIC. Painel com os 3 canais **A/B/C**
  (frequência em Hz, volume 0-15, "usar envelope", liga/desliga tom e ruído no mixer), **ruído**
  (período compartilhado) e **envelope** (período + as 10 formas de hardware nomeadas). Um "som" é um
  **mini-sequenciador de passos** — cada passo guarda os 14 registradores + uma duração em quadros,
  permitindo desenhar efeitos que variam ao longo do tempo (tiro, explosão etc.), com botões
  **Adicionar/Atualizar/Remover/Mover/Duplicar passo**. **Tocar**/**Parar** sintetizam a sequência
  inteira em PCM (motor próprio por acumulador de fase — osciladores de tom, LFSR de ruído de 17 bits,
  gerador de envelope, tabela de volume logarítmica de 16 níveis) e tocam via `.wav` temporário, sem
  depender de nenhuma biblioteca externa. **Gerar código BASIC** produz `SOUND n,valor` prontos
  (só os registradores que mudaram a cada passo) e **Gerar bytes crus** produz um bloco `DATA` para uma
  futura rotina Z80; **Injetar no cursor**/**Copiar** colocam o código gerado direto na aba de texto
  ativa ou na área de transferência. Integrado ao sistema de projeto, mesma barra de número/tag/
  navegação/Registrar/Novo dos editores de sprite e alfabeto.

  ![Editor de som PSG (Criar → Som (PSG)...) com os 3 canais, ruído/envelope compartilhados, lista de passos e código BASIC gerado](docs/images/msxbasica-06.png)
- **Editor SEE Tracker** (`src/editor/visual_editors/SeeTrackerEditorGui.pbi` + `src/editor/visual_editors/SeeTrackerSynth.pbi` +
  `src/editor/visual_editors/SeeTrackerDriverAsm.pbi`, menu **Criar → SEE Tracker...**) — tracker de efeitos sonoros
  **compatível com o formato `.SEE`** (Sound Effect Editor, Fuzzy Logic 1991/95 — ver **Ajuda → SEE
  Tracker...** para o manual original e o formato de arquivo). Diferente do editor de Som (PSG) acima,
  um efeito aqui é uma sequência de **patterns com comandos de controle** (`HALT`/`FOR`/`NEXT`/`START`/
  `RERUN`/`TMP`/`END`, os mesmos do formato original) — grade clicável (uma linha por pattern) com
  painel de edição completo (evento, frequência/rustle/volume dos 3 canais com slides de afinação,
  envelope de hardware) ao lado. **Tocar**/**Parar** interpretam a sequência quadro a quadro (inclusive
  loops) e sintetizam via o mesmo motor do editor PSG. **Gerar código** monta um **driver de replay Z80
  nativo** (porta de `see/SEE3PLAY.ASC`, corrigida e montada em tempo real pelo assembler Z80 desta IDE)
  junto com o blob binário `.SEE` do efeito atual, prontos como `DATA`/`POKE`/`DEFUSR` para tocar via
  NestorBASIC. **Importar .SEE...** lê um arquivo `.SEE` real gerado pelo editor original (útil pra
  recuperar efeitos de projetos antigos) — lista todos os SFX definidos nele (um arquivo pode ter vários)
  e importa os patterns do escolhido pro SFX atual, andando sequencialmente até o evento `END`. Um
  **cursor de playback** (borda verde na grade) mostra em tempo real qual pattern está soando, com
  auto-scroll se ele sair da área visível. A **forma do envelope** de hardware do PSG (reg. 13) tem um
  preview ao vivo e um seletor visual com as **16 curvas reais do chip** — clicar numa já escolhe, sem
  precisar decorar o número de cada forma. **Limpar**/**Limpar linha**/**Limpar bloco** zeram todos os
  patterns, um só ou um intervalo, sem precisar apagar e reinserir linha por linha. Integrado ao sistema
  de projeto, mesmo padrão de número/tag/navegação/Registrar/Novo dos demais editores.

  ![Editor SEE Tracker (Criar → SEE Tracker...) com um efeito de 8 patterns tocando — cursor de playback verde no pattern 0, botões Limpar/Limpar linha/Limpar bloco e o seletor visual de forma do envelope à direita](docs/images/msxbasica-16.png)
- **Editor de música MML** (`src/editor/visual_editors/MmlSynth.pbi` + `src/editor/visual_editors/MmlEditorGui.pbi`, menu **Criar → Música
  (PLAY)...**) — editor de MML (Music Macro Language) para o comando `PLAY` do MSX-BASIC, cobrindo os
  3 canais **A/B/C em paralelo**. Cada canal tem uma "linha atual" editável que os botões vão
  preenchendo — notas **A-G** (sustenido/bemol, duração, pontos de aumento), **pausa (R)**, **nota
  absoluta por número (N)**, **oitava (O, 1-8, com `>`/`<`)**, **duração padrão (L)**, **andamento
  (T)**, **volume (V)** e o **modulador/padrão de envelope (M/S)** — mesmo hardware de envelope
  compartilhado do editor de som. **Inserir nova linha** fecha a linha atual como uma entrada na lista
  do canal (mesmo espírito "sequenciador" do editor de som); **Atualizar**/**Remover**/**Mover** editam
  as linhas já inseridas. **Tocar**/**Parar** sintetizam os 3 canais juntos — o motor reaproveita quase
  integralmente o `PsgSynth.pbi` do editor de som (mesmo chip, mesmo gerador de envelope compartilhado),
  só parseando o MML e mesclando cronologicamente os 3 canais num único fluxo de registradores.
  **Gerar código PLAY** monta o `PLAY "...","...","..."` final (concatenação literal do que foi
  montado); **Injetar no cursor**/**Copiar** colocam o código na aba ativa ou na área de transferência.
  Integrado ao sistema de projeto, mesma barra de número/tag/navegação/Registrar/Novo dos demais
  editores — os botões de ícone (**Novo**/**Registrar**) são os mesmos desenhos já usados no editor de
  sprites, reaproveitados para ficar visualmente uniforme em toda a IDE.

  ![Editor de música MML (Criar → Música (PLAY)...) com os 3 canais em paralelo, lista de linhas por canal e código PLAY gerado](docs/images/msxbasica-07.png)
- **Editor de DRAW Screen 2** (`src/editor/visual_editors/Screen2Synth.pbi` + `src/editor/visual_editors/Screen2EditorGui.pbi`, menu **Criar
  → Draw Screen 2...**) — editor gráfico WYSIWYG para o modo **SCREEN 2** (TMS9918 Graphics II,
  256×192), com simulação **fiel ao hardware** do color clash (1 par tinta/fundo por faixa de 8×1
  pixels — pintar 2 cores na mesma faixa faz a faixa inteira "puxar" pra última cor gravada, igual ao
  MSX de verdade, sem lógica de detecção extra: o motor só reproduz o mesmo comportamento da ROM).
  Sete abas de ferramenta — **PSET**/**PRESET** (clique no canvas já liga/apaga o pixel na cor
  selecionada), **LINE** (reta/caixa/caixa cheia, dois cliques: ponto inicial e final, com **linha
  elástica** acompanhando o mouse antes do segundo clique), **CIRCLE** (círculo ou elipse, primeiro
  ponto centro/canto, segundo raio/canto oposto, também com previa elástica), **PAINT** (preenchimento
  por vizinhança), **DRAW** (interpretador completo da mini-linguagem de tartaruga do MSX-BASIC —
  `U D L R E F G H`, `B`/`N`, `M`, `C`, `S`, `A`/`TA`, com rotação exata em passos de 90° e
  arredondamento correto pra ângulos livres) e **TEXTO** (escreve usando um alfabeto do banco do
  projeto — ver editor de alfabetos acima — com um **quadro elástico arrastável** que mostra o texto de
  verdade nas cores escolhidas seguindo o mouse: move de 8 em 8 pixels por padrão para encaixar no grid
  de tiles, ou pixel a pixel segurando **Ctrl**; clique fixa o texto, botão direito cancela). Suporta os
  parâmetros **STEP** (coordenadas relativas ao cursor gráfico, como no MSX-BASIC real) em todos os
  comandos que aceitam, e `LINE -(x,y)` (sem ponto inicial, usa o cursor gráfico como ponto de partida).
  Cada ferramenta com clique-para-adicionar tem seu **mini buffer** próprio (lista filtrada + botão
  Remover, some do canvas junto). Paleta MSX1 completa (16 cores fixas) para Tinta/Fundo. **Gerar
  código** produz `PSET`/`PRESET`/`LINE`/`CIRCLE`/`PAINT`/`DRAW` prontos (mais o carregador `DATA`+
  `VPOKE` do alfabeto e `LOCATE`/`PRINT` para texto alinhado ao grid de 8px — texto posicionado livre
  por pixel vira uma sequência de `PSET`/`PRESET`, já que `LOCATE` só aceita célula de caractere
  inteira); **Injetar no cursor**/**Copiar** como nos demais editores. Integrado ao sistema de projeto
  (tabela `screens`, mesma barra de número/tag/navegação/Registrar/Novo/Copiar/Colar dos outros
  editores) — guarda a **lista de comandos**, não o framebuffer, para poder reordenar/editar depois de
  recarregar.

  ![Editor de DRAW Screen 2 (Criar → Draw Screen 2...) com formas desenhadas, lista de comandos e código BASIC gerado](docs/images/msxbasica-10.png)
- **Graphos III — edição de telas SCREEN 2** (`src/editor/visual_editors/GraphosScreenGui.pbi`, menu **Criar → Graphos III
  Screen 2...**) — réplica do editor de vídeo clássico do MSX **Graphos III** (Renato Degiovani, 1987;
  manual completo lido de `graphos/graphos.txt`). Cada função do Graphos III original vira uma opção
  **separada** dentro de "Criar" (o editor de alfabetos do Graphos III já existe, ver **Alfabeto Graphos
  III...** acima) e os antigos menus por tecla de função (F1-F5: DESENHO/TEXTO/TELA/AJUSTE/MISCELANEA)
  viram botões/ícones, no mesmo espírito do editor de sprites. **Fase 1** (esta versão): canvas 256×192
  com **color clash idêntico ao MSX de verdade** (reaproveita 100% do motor já validado do editor "Draw
  Screen 2...", `Screen2Synth.pbi` — zero lógica de clash nova), paleta INK/PAPER, **TRAÇO** (Lápis/
  Borracha com arrastar contínuo, alternância mutuamente exclusiva) e **LIMPA TELA**. Resto do menu
  DESENHO (BLOCO/LINHA/RETÂNGULO/RAIO/CÍRCULO/PINTURA/SPRAY/FILL), TEXTO, AJUSTE, MISCELÂNEA (ZOOM/
  SHAPE/CORTE/GRID), shapes e os formatos de arquivo nativos (`.SCR`/`.LAY`/`.VTC`+`.ATC`) ficam para
  os próximos cortes.

  ![Editor Graphos III (Criar → Graphos III Screen 2...) replicando o editor de vídeo clássico do MSX](docs/images/msxbasica-11.png)
- **Assembler Z80 nativo** (`src/editor/assemblers/Z80Asm.pbi`, menu **Executar → Montar Assembly (.bin)...**,
  `Ctrl+F5`) — compatível com **M80/L80** (Microsoft MACRO-80/LINK-80), especificação de comportamento
  portada do [**Nestor80**](https://github.com/Konamiman/Nestor80) (assembler C# moderno 100%
  compatível M80/L80). Avaliador de expressão (RPN, precedência idêntica ao Nestor80/M80 —
  `HIGH`/`LOW`/`NOT`/relacionais), tabela de opcodes Z80 completa (documentados + `IXH`/`IXL`/`IYH`/
  `IYL` indocumentados comuns), driver de 2 passes, diretivas de dados (`DB`/`DW`/`DS`/`DC`/`DZ`),
  condicionais (`IF`/`IFDEF`/`IF1`/`IF2`/etc.) e macros básicas (`MACRO`/`ENDM`/`EXITM`/`LOCAL`).
  Validado **byte a byte** contra o próprio `N80.exe` (compilado localmente como oráculo de teste) —
  `dist/sample/teste_opcodes.asm` e `dist/sample/teste2_macros.asm` são a suíte de regressão oficial. Além da
  saída absoluta (`.bin`, **Executar → Montar Assembly (.bin)...**), o motor gera saída **relocável
  `.REL`** de verdade (`ASEG`/`CSEG`/`DSEG`/`COMMON`/`PUBLIC`/`EXTRN`, formato estendido Nestor80,
  validado byte a byte contra o `N80.exe`), agora exposta no editor via **Executar → Montar Assembly
  relocável (.REL)...**. **Linker** (`src/editor/assemblers/Z80Link.pbi`, Linkstor80-equivalente — linka múltiplos
  `.REL` e resolve `.REQUEST`/biblioteca com linkagem estática seletiva) e **gerenciador de biblioteca**
  (`src/editor/assemblers/Z80Lib.pbi`, Libstor80-equivalente — `create`/`add`/`list`/`remove`), ambos validados byte a
  byte contra `LK80.exe`/`LB80.exe` reais, têm janela própria no editor: **Executar → Linkar (.REL) →
  binário...** (`src/editor/assemblers/Z80LinkGui.pbi`) e **Criar → Biblioteca Z80 (.LIB)...** (`src/editor/assemblers/Z80LibGui.pbi`).
  A saída (montagem absoluta ou link) passa por um escolhedor comum (`src/editor/assemblers/Z80OutputGui.pbi`): `.bin`
  solto no PC (com ou sem cabeçalho MSX BLOAD), **`.COM` (MSX-DOS)** pronto pra rodar **independente do
  MSX-BASIC** (binário cru sem cabeçalho, avisa se o fonte não foi montado pra `0100h`), **disco MSX
  (`.dsk`)** pronto pra rodar via `AUTOEXEC.BAS` (`BLOAD"...",R`, reaproveitando `MSXDisk.pbi`) ou
  **listing BASIC** (`FOR`/`READ`/`POKE` + `DATA` em hexa, mesmo espírito do "Gerar bytes crus" do
  editor de som PSG). Uma nova tabela
  `asm_builds` no sistema de projeto (`ProjectDB.pbi`) guarda o metadado da última exportação de
  binário/disco por origem (caminho do `.asm` ou, numa sessão de link, a lista de `.rel` escolhida).
  **Assembly Sub Project** (**Criar → Assembly Sub Project...**, `src/editor/assemblers/Z80SubProject.pbi` motor +
  `src/editor/assemblers/Z80SubProjectGui.pbi` janela) — um "Makefile primitivo": lista ordenada de `.asm` (cada um
  vira `.REL` na hora do build) mais bibliotecas referenciadas via `.REQUEST`, botão **Montar tudo
  (Build)...** monta tudo de uma vez e manda pro mesmo escolhedor de saída; botão **Gerar biblioteca a
  partir dos .ASM selecionados...** empacota um subconjunto numa `.LIB`/`.REL` e oferece adicioná-la de
  volta à lista. Registrado no `.msxproject` (tabela `asm_subprojects`), mesma barra de projeto
  (número/tag/navegação/Novo/Registrar) dos demais editores. Detalhe completo do processo de
  implementação em [`docs/resumo-asm.md`](docs/resumo-asm.md).

  ![Assembler Z80 nativo (Executar → Montar Assembly), compatível M80/L80](docs/images/msxbasica-12.png)
- **Sistema de Ajuda MSX BASIC** (`src/editor/help/MsxBasicHelpGui.pbi`, menu **Ajuda → MSX BASIC...**) — janela
  de referência não-modal (fica aberta enquanto o usuário continua editando), com árvore navegável,
  busca por nome/palavra e histórico (**Alt+seta-esquerda**/botão "Voltar" desempilha um tópico). Duas
  fontes de dados combinadas numa única lista achatada: **MSX1** — dicionário completo das 141
  palavras reservadas do livro *"Linguagem BASIC MSX"* (Denise Santoro Cruz, Editora Aleph/Gradiente,
  1986) em `src/editor/help/MsxBasicDictData.pbi`, mais os tópicos de prosa/tabelas (Parte I, Parte III,
  Apêndices) em `src/editor/help/MsxBasicManualData.pbi`; **MSX 2+** — 45 verbetes adicionais (comandos novos do
  cartucho ACVS FM, ex. `COLOR=`, `COLORSPRITE`, `SETPAGE`, `CALL MEMINI`, `CALL MUSIC`/`CALL VOICE` etc.,
  mais um segundo verbete `"NOME (MSX2+)"` para comandos do MSX1 com comportamento estendido, ex.
  `SCREEN`/`COLOR`/`CIRCLE`/`PLAY`) em `src/editor/help/MsxBasic2PlusDictData.pbi`, mais 7 tópicos de prosa/
  apêndices (apresentação, sintaxe, FM-Music, Apêndices A-D) do *"Manual MSX 2+ FM"* (Ademir
  Carchano/Flávio Monaco, ACVS Eletrônica) em `src/editor/help/MsxBasic2PlusManualData.pbi`, digitalizado em
  `docs/manual_msx2fm_acvs.pdf`. Cada verbete guarda a página do livro/manual de origem; mais uma página
  especial "Cores do MSX" com as 16 cores do VDP renderizadas como faixas coloridas.
- **Suporte a NestorBASIC** (`src/editor/basic/NestorBasicSupport.pbi` + `src/editor/basic/NestorBasicHelpData.pbi`/
  `NestorBasicHelpGui.pbi`) — integração com o **NestorBASIC 1.11** (Nestor Soriano/Konami Man): rotinas
  em código de máquina carregadas uma vez via `BLOAD"NBASIC.BIN",R` que dão acesso a memória mapeada,
  VRAM, disco, compressão gráfica, execução de programas/código em RAM, efeitos PSG e tocador
  Moonblaster, tudo através de um único `USR(numero)` e dos arrays `P()`/`F$()`.
  - **Arquivo → Novo Nestor Basic...** cria uma aba nova de Basic Dignified já com o loader (rótulos
    `{NBasicLoad}`/`{VoltaNBasicLoad}`, escrito com `GOTO` puro — achado do usuário: `BLOAD"...",R` mexe
    na pilha do BASIC, então um `GOSUB`/`RETURN` ao redor dessa chamada específica quebra) e a biblioteca
    inteira de wrappers `.NB_*` colada direto no texto (sem `INCLUDE`, já que uma aba nova ainda sem
    salvar não tem de onde puxar um arquivo externo): 87 funções (0-86) cobrindo as três "tiers" do
    manual original — geral/RAM/VRAM/disco (Tier 1, com `func`/`ret`), compressão gráfica/execução de
    programas/código diverso/PSG/Moonblaster (Tier 2) e controle de segmentos/integração com
    NestorMan/InterNestor Suite/Lite (Tier 3). Convenção: cada `.NB_*` devolve só o(s) valor(es)
    principal(is) da chamada com o código de erro por último (`.NB_ErrorText` traduz o código); os
    demais resultados documentados no manual continuam disponíveis em `p()`/`f$()` logo após a chamada.
  - **Executar → Nestor Basic** — idêntico a **Executar → BASIC**, mas também copia `NBASIC.BIN`/
    `NBASIC.DAT` (de `res/`) para o disco `.dsk` gerado antes de abrir o openMSX, já que o programa
    precisa desses arquivos presentes no disco em tempo de execução.
  - **Ajuda → Nestor Basic...** — janela de referência não-modal (mesma UI de árvore + busca + histórico
    do sistema de Ajuda acima) com as 87 funções mais introdução, mostrando pra cada uma o wrapper
    `.NB_*` e um exemplo de chamada já pronto antes do resto do corpo. Fonte única de dados também usada
    para gerar `docs/reference/nestorbasic.md` (exportação Markdown a partir da mesma base).

  ![Suporte a NestorBASIC: template gerado por Arquivo → Novo Nestor Basic... ao lado da janela Ajuda → Nestor Basic...](docs/images/msxbasica-13.png)
- **Ajuda MSX BASIC do Basic Dignified** (`src/editor/help/BasicDignifiedHelpData.pbi`/`BasicDignifiedHelpGui.pbi`,
  menu **Ajuda → Basic Dignified...**) — mesma janela de referência não-modal (árvore + busca +
  histórico) compilada a partir da documentação oficial do Basic Dignified Suite original
  (`basic-dignified/documentation/*.md`, baixável pelo botão **Baixar Basic Dignified Suite...** da
  tela de configuração), cruzada com o código real desta IDE. Cobre dois assuntos: a **sintaxe** do
  dialeto Dignified (labels/loop labels, defines, variáveis de nome longo/`DECLARE`, proto-funções
  `FUNC`/`RET`, separação de linhas `:`/`_`, comentários e toggles, tradução Unicode, `INCLUDE`,
  `TRUE`/`FALSE`, operadores compostos) e as **configurações** de `Configurar → Basic Dignified...`
  campo a campo — inclusive dizendo explicitamente quais campos têm efeito real no pipeline nativo
  (`Dig_SyncConfigFromBadigCfg()`) e quais existem só por compatibilidade com o `.ini` original sem
  nenhum consumidor hoje (relatórios da aba Basic Dignified, opções do tokenizador na aba MSX,
  `EmSetting`/`EmMonitor`/`EmNoThrottle`/`EmVerbose` na aba Emulador). Mais dois grupos: **remtags**
  (`##BB:arguments=`/`export_file=`/`help=`, com a lista exata de flags que o remtag `arguments=`
  realmente aplica) e **sobre a suíte original** (ferramentas não portadas pra esta IDE, como o
  DignifieR de conversão reversa, e referência do formato tokenizado `.bmx`).
- **Ajuda SEE Tracker** (`src/editor/visual_editors/SeeTrackerHelpData.pbi`/`SeeTrackerHelpGui.pbi`, menu **Ajuda → SEE
  Tracker...**) — mesma janela de referência não-modal, desta vez sobre o **SEE** (Sound Effect
  Editor, Fuzzy Logic 1991/95), um editor shareware de efeitos sonoros PSG pra MSX que gera arquivos
  `.SEE`/`.SFX` tocados via um pequeno driver Z80 (mesmo estilo de integração `BLOAD`+`DEFUSR`/`USR()`
  já usado pelo NestorBASIC desta IDE). Cobre o manual original (telas, menus, teclas, os 11 canais de
  um pattern, comandos do canal `event`), o **formato binário `.SEE`** campo a campo e o **mecanismo
  real do driver de replay** (`see/SEE3PLAY.ASC`, lido linha a linha) — inclusive achados que só
  aparecem lendo o driver, não o manual, como o fato de `FOR`/`START` dispararem só uma vez (nunca
  reprocessados nas repetições de um loop) e a fórmula exata de escala por `Max Volume`. Preparação
  para um **tracker de SFX nativo compatível** a construir numa sessão futura — por ora é só estudo,
  nenhum editor/gerador `.SEE` existe ainda nesta IDE.
- **Editor Hexa** (`src/editor/core/HexEditorGui.pbi`, menu **Executar → Editor Hexa...**) — editor
  hexadecimal genérico: abre **qualquer arquivo** do disco (não só os do editor de texto), mostra
  offset/hex/ASCII numa grade rolável e permite editar bytes individuais (clique seleciona, campo +
  **Aplicar** grava). **Reconhece automaticamente, sem nenhuma configuração**:
  - **Formatos nativos desta IDE**: binário MSX BLOAD/BSAVE (cabeçalho `FEh` + início/fim/execução),
    MSX-BASIC tokenizado (`FFh`), boot sector FAT12 de imagem `.dsk` (mesmos offsets que `MSXDisk.pbi`
    lê/escreve), texto ASCII puro vs. BASIC MSX clássico numerado (mesma regra de entrada do
    tokenizador).
  - **Executável MSX-DOS** (`.COM`) — código Z80 cru sem cabeçalho, convenção CP/M, carrega/executa
    sempre em `0100h`.
  - **Planilha SuperCalc 2 MSX** (`.CAL`) — assinatura, título e início da seção de dados (ver
    `docs/reference/supercalc2-cal-format.md`).
  - **Banco de dados dBase II** (`.DBF`) — cabeçalho, descritores de campo (nome/tipo/tamanho) e onde os
    registros começam (ver `docs/reference/dbase2-dbf-format.md`).
  - **Os 4 formatos nativos do Graphos III**: **Alfabeto `.ALF`** (256 caracteres × 8 bytes), **Layout
    `.LAY`** (decodifica o RLE+ofuscação de verdade e confere os 6144 bytes), **Tela `.SCR`** (padrão +
    cor de SCREEN 2 completa) e **Banco de shapes `.SHP`** (percorre a cadeia de blocos até o
    terminador `FFh` — o único dos quatro sem cabeçalho BLOAD/BSAVE).

  Além do reconhecimento automático, uma **galeria de templates** (`hexeditor_templates.json`, mesmo
  estilo de persistência de `editor_settings.json`/`badig_settings.json`) deixa o usuário cadastrar
  binários BLOAD/BSAVE próprios (byte de tipo + endereço inicial + tamanho dos dados) pra dar nome
  amigável a qualquer outro formato. Operações de bloco a partir de um intervalo marcado (**Marcar
  início**/**Marcar fim**/**Limpar seleção**) ou, se nada estiver marcado, perguntando endereço
  inicial/final na hora: **Preencher...** (um valor num intervalo), **Inserir bloco...** (desloca o
  resto do arquivo pra frente) e **Sobrepor bloco...** (não desloca), ambos trazendo os bytes de outro
  arquivo inteiro ou gerando bytes em branco (quantidade + valor), e **Excluir bloco...** (desloca de
  verdade, encolhendo o arquivo, ou só sobrescreve com `00` no lugar). Barra de rolagem vertical
  customizada (setas topo/base tradicionais + barra visual com a posição proporcional no arquivo,
  desenhada à mão porque o `ScrollBarGadget` nativo do PureBasic renderizava enorme e com os botões
  trocados nesta configuração) mais rolagem pela roda do mouse.

  ![Editor Hexa (Executar → Editor Hexa...) reconhecendo um alfabeto Graphos III via galeria de templates](docs/images/msxbasica-14.png)
- **Inserir → Caractere Especial...** (`src/editor/core/CharMapGui.pbi`, novo menu de topo **Inserir**) — mapa
  de caracteres estilo Windows (`charmap.exe`) com os **159 caracteres** que a opção `-tr` traduz pra
  ASCII nativo MSX (acentos/gregas/gráficos + carinhas/naipes/linhas tipo CP437): grade 16×10 clicável
  com prévia ampliada e código MSX/Unicode do caractere selecionado, campo acumulador (até 80
  caracteres, botões Adicionar/Remover último/Limpar) e botão **Inserir** que copia o texto acumulado
  na posição do cursor da aba ativa. Motivou a correção de dois bugs reais de tradução em
  `DignifiedPreprocessor.pbi` que já afetavam `-tr` antes desta feature existir — ver Changelog e
  `docs/SPEC.md`, módulo 3h.
- **Família de editores de tela de texto MSX** (`Criar → Screen 0.../Screen 1.../Screen 1+2...`), no
  espírito dos clássicos editores de tela ANSI da era BBS (TheDraw/AcidDraw/DarkDraw), mas fiéis ao
  hardware MSX real — cada um cobre um modo de cor de texto diferente, do mais simples ao mais
  complexo: **SCREEN 0** (1 cor pra tela inteira), **SCREEN 0 no modo MSX2+** (80 colunas com uma
  segunda cor real de texto), **SCREEN 1** (1 cor por grupo de 8 caracteres) e **SCREEN 1+2** (SCREEN 2
  de verdade — 3 alfabetos e cor por linha de scanline). Os quatro compartilham a mesma grade fixa de
  32×24 (ou 40/80×24 no SCREEN 0) e a maioria das 6 ferramentas por aba (Texto/Caractere/Quadro/Sombra/
  Bloco/Borracha) — só o modelo de cor e a renderização mudam entre eles.
  - **Screen 0...** (`src/editor/visual_editors/Screen0EditorGui.pbi`) — grade fixa de **40 ou 80 colunas × 24 linhas**
    (largura escolhida ao criar cada tela) com **uma única cor de tinta/fundo pra tela inteira**
    (equivalente a `COLOR fg,bg` — SCREEN 0 de verdade não tem cor por célula, diferente de um editor
    ANSI de PC), usando a fonte padrão do MSX ou uma fonte customizada já cadastrada no banco de
    alfabetos do projeto (**Criar → Alfabeto Graphos III...**). Ferramentas: **Texto** (digita e clica
    pra posicionar horizontalmente), **Caractere** (grade com os 159 caracteres especiais de
    `Inserir → Caractere Especial...` — clique/arraste estampa), **Quadro** (2 cliques desenham uma
    moldura com linhas simples, unindo automaticamente em T/cruz onde encostar num quadro já
    existente), **Sombra** (2 cliques estampam uma faixa `▒` deslocada, no estilo clássico de sombra de
    editor ANSI), **Bloco** (2 cliques preenchem um retângulo com o caractere atual) e **Borracha**.
    **Gerar código**/**Injetar no cursor**/**Copiar** emitem `SCREEN 0`/`WIDTH`/`COLOR`/`LOCATE`+`PRINT`
    com os glifos Unicode literais — a tradução `-tr` do próprio pipeline Dignified resolve pro byte/
    escape nativo MSX na hora de tokenizar, sem o editor precisar calcular nenhum endereço de VRAM pro
    texto em si (só o carregador de fonte customizada, que usa o endereço real da Pattern Generator
    Table do SCREEN 0 — `&H0800` em 40 colunas, `&H1000` em 80). **Em telas de 80 colunas (modo MSX2+),
    uma sétima ferramenta ("Atributo") liga o recurso real de segunda cor** (modo T2 do VDP): cada
    caractere pode usar um segundo par de tinta/fundo (paletas "Cor 2" próprias), piscando com a cor
    normal num ritmo configurável (0-15, ~1/6s por fase, até 2.5s) ou **travado permanentemente na Cor
    2** (zerando a duração "normal") — dando, na prática, texto com 2 cores fixas em 80 colunas, algo
    que 40 colunas não tem. Gera `VDP(13)`/`VDP(14)` (cor 2 e duração) mais o carregador da tabela de
    "pisca" (1 bit/caractere, `&H0800` nesse modo) junto do resto do código.
  - **Screen 1...** (`src/editor/visual_editors/Screen1EditorGui.pbi`) — mesma grade fixa **32×24** e as mesmas 6
    ferramentas do SCREEN 0 acima, mas com a diferença real de cor do hardware SCREEN 1: em vez de 1 cor
    pra tela inteira, uma **Color Table** de 32 entradas dá 1 par tinta/fundo por **grupo de 8 códigos de
    caractere** (endereço padrão `&H2000`). A **tabela ASCII do alfabeto** (grade de 256 células) mostra
    o bitmap real de cada código já pintado na cor do seu octeto — clicar escolhe o "byte atual" e as
    paletas Tinta/Fundo do octeto colorem os 8 códigos daquele grupo, refletido ao vivo na tabela e no
    canvas.
  - **Screen 1+2...** (`src/editor/visual_editors/Screen12EditorGui.pbi`) — terceira e mais complexa da família: gera
    **SCREEN 2** de verdade (não um editor gráfico de pixels como o **Draw Screen 2...** já existente),
    com os dois recursos extras do hardware que o SCREEN 1 não tem — **3 alfabetos**, um por "terço" de
    8 linhas de tela (Pattern `Terço×2048`/Color `&H2000+Terço×2048`), e **cor por LINHA DE SCANLINE de
    cada código de caractere** (8 cores por glifo, o "color clash" real do SCREEN 2 — toda ocorrência do
    mesmo código no mesmo terço usa a mesma cor por linha, não importa onde apareça na tela). A tabela
    ASCII mostra 1 terço por vez (seletor acima da grade que **acompanha sozinho** qualquer clique/
    arraste no canvas, e uma linha-guia preto+branco no canvas marca visualmente onde cada terço começa/
    termina). **Cores do caractere...**/**Cores em bloco...** abrem um editor ampliado por linha de
    scanline (o de bloco escolhido por 2 cliques direto na tabela ASCII, com marca ciano sutil);
    **Copiar/Colar cores** e **Resetar caractere/bloco/todos** (fundo preto/letra branca) completam o
    fluxo. Todos os editores da família são integrados ao sistema de projeto, mesma barra de número/tag/
    navegação/Novo/Registrar dos demais editores.

    ![Editor de tela Screen 1+2 (Criar → Screen 1+2...) mostrando cores diferentes por terço — carinhas amarelas no Terço 1, azuis no Terço 2, texto vermelho no Terço 3](docs/images/msxbasica-15.png)

Ainda não implementado (ver [Lacunas conhecidas](docs/SPEC.md#lacunas-conhecidas-a-preencher-em-conversas-futuras)
e [Próximos passos](docs/SPEC.md#próximos-passos-em-aberto) em `docs/SPEC.md`): `--code`/`--data`/
`--align-*`/detecção de sobreposição de segmento/saída Intel HEX no linker, editor de tile (além do
charset/fonte 8×8), tracker, saída via `msxbas2rom`, input simulado durante a execução e detecção de
erro com retorno à linha no editor (ver "Controle remoto do openMSX" logo abaixo para o que já existe
nessa frente).

**Controle remoto do openMSX — validado e ampliado (2026-07-30)**: menu **Executar → openMSX...**
(`src/editor/emulators/OpenMSXBridge.pbi`/`OpenMSXConsoleGui.pbi`) abre uma instância separada do openMSX com um
named pipe de comando (mesmo mecanismo do Catapult oficial no Windows) e dá uma janela de console para
controlar essa instância manualmente — não mexe no fluxo normal de **Executar → BASIC** (são
instâncias/processos openMSX totalmente separados; a instância aberta por "Executar → BASIC" com o
programa do usuário não fica sob controle desse console a menos que o console seja aberto a partir
dela — ver lacuna registrada abaixo). Validado ao vivo contra um openMSX 21.0 real
(`src/editor/tools/OpenMsxBridgeTestCli.pb`, harness de linha de comando novo nesta sessão).

A janela ganhou, na mesma sessão de validação:
- **Indicador de estado** ("Ligado/Desligado | Rodando/Pausado") no topo, alimentado por
  `openmsx_update enable setting` (assinado no boot) — reflete o estado real mesmo se ele mudar por um
  caminho que não um comando mandado por esta janela.
- **Área de colar/digitar texto** + botão **"Inserir no openMSX"**, que digita o conteúdo no MSX como
  se fosse teclado de verdade (quebras de linha viram Enter) — mesmo mecanismo do Catapult
  (`InputPage.cpp`/`OnTypeText()`): comando `type -- <texto escapado>`, delegando pro `type_via_keyboard`
  nativo do openMSX.
- Correção de um bug real de exibição: o log da janela fazia release/gravação completa do texto
  (`GetGadgetText`/`SetGadgetText`) a cada 150ms e, depois de alguns comandos, "esvaziava" sozinho
  mesmo com o openMSX respondendo normalmente por baixo — trocado por um acumulador só do nosso lado,
  nunca relido do widget.
- Correção de um bug real de protocolo (achado ao implementar o "Inserir no openMSX", mas que já
  afetava qualquer comando digitado manualmente): comandos não eram escapados como XML antes de
  `<command>...</command>` — um `<`/`&` cru (comum em BASIC: `IF X<10`, `A&B`) quebrava o comando
  silenciosamente no parser real do openMSX, sem erro nenhum. Corrigido com escape XML, igual ao
  Catapult de verdade.

Detalhes técnicos completos (arquitetura, tentativas anteriores, e as pegadinhas reais encontradas
durante a validação) em `docs/SPEC.md`, módulo 12. **O que ainda falta nessa frente** está listado em
`docs/SPEC.md` → [Próximos passos](docs/SPEC.md#próximos-passos-em-aberto).

**Base de conhecimento MSX embutida no menu Ajuda (2026-08-10)** — sete janelas novas, todas navegáveis
por árvore + busca (mesmo padrão das janelas de Ajuda originais), com conteúdo extraído automaticamente
de fontes históricas reais (não escrito à mão) por scripts de conversão descartáveis (não versionados,
mesma ideia de `OpenMsxHelpData.pbi`):
- **Manuais MSX** (`Ajuda → Manuais MSX...`) — MSX-DOS 2 (Referência/Interface de Programa/Códigos de
  Função), Z80/R800, Turbo-Basic Compiler, FM-PAC e o MSX2 Technical Handbook original (transcrição de
  1997), extraídos de `help/MANUALS.CHM` (RuMSX) e reproduzidos como no original (documentos antigos,
  amplamente disponíveis).
- **MSX-Basic/DOS/CP-M (RuMSX)** (`Ajuda → MSX-Basic/DOS/CP-M...`) — 359 comandos de
  `help/SOFTWARE.CHM`, incluindo os que só eram citados pelo nome sem página própria (viram um
  placeholder em vez de sumir) — segunda fonte de MSX-BASIC em paralelo com "Ajuda → MSX BASIC..." (o
  do livro brasileiro), para comparar qual fica mais completa.
- **BIOS MSX: Chamadas/Hardware/Documentação (RuMSX)** — `help/MSXBIOS.CHM` dividido nas 3 seções do
  CHM original; 597 rotinas de BIOS individuais (uma por endereço/nome, splitting automático a partir
  do HTML) nas áreas de ROM/RAM, mais os tópicos de hardware (PSG/VDP/V9990/portas I/O/etc.).
- **Livro Vermelho** (`Ajuda → Livro Vermelho...`) — "The MSX Red Book" (Avalon Software/Kuma
  Computers, 1985) completo, 973 tópicos, com as ~2911 referências cruzadas internas do livro
  **clicáveis de verdade** (hotspot nativo do Scintilla) e as 53 figuras originais (convertidas de SVG)
  abrindo num popup — única parte do programa com link clicável dentro do texto de Ajuda.
- **MSX2 Technical Handbook** (`Ajuda → MSX2 Technical Handbook...`) — edição Markdown mantida por
  Konamiman (github.com/Konamiman/MSX2-Technical-Handbook), 1356 tópicos particionados por heading
  Markdown real, com as 84 figuras originais do livro (PNG) e os mesmos links/figuras clicáveis do
  Livro Vermelho.

Detalhes de arquitetura (codificação de dados, os dois estilos de renderizador, o mecanismo de hotspot)
em `docs/SPEC.md`, módulo 30.

**Mamute Assembler — monitor estilo anos 80 (`Executar → Mamute Assembler...`) — ⚠️ ainda em fase
inicial** — um "terminal" próprio (fundo preto, texto verde monoespaçado em negrito, propositalmente
fora do tema da IDE), prompt `MON>`, inspirado no **MegaAssembler** do usuário e nos antigos montadores
de linha de comando dos anos 80. Simula o sistema de slots/páginas de memória do MSX (4 slots × 4
páginas de 16KB = 256KB), configurável em **Configurar → Mamute Assembler...** (o que é RAM, ROM, BASIC
ou vazio em cada célula — arquivos ROM/BASIC configurados são lidos de verdade toda vez que a janela do
Mamute Assembler abre). Cresceu de um punhado de comandos herdados do MegaAssembler (`BA`/`QUIT`,
`PAGE`, os editores de bytes `DM`/`ZAP`/`SCR`/`M`/`S`, busca/gravação `SH`/`MS`, `LOAD`/`SAVE`, `C`,
mais o disassembler `L`/`LP`, a calculadora `CL`, um editor de fonte Z80 próprio via `EDIT` e um motor
de execução Z80 real via `G`/debugger gráfico) pra também portar comandos do **SUPER-X**, outro
monitor/debugger clássico de MSX mais avançado — 36 comandos com prefixo `X` até a versão 8.7.5
(`XD`/`XA`/`XI`/`XM`/`XH` — a mesma "cruz de modos" do SUPER-X original; `XBT`/`XRT`/`XFL`/`XCM`/`XFD`
— ferramentas de memória entre slots/sub-slots/VRAM diferentes; `XCS`/`XTS` — checksum; `XRG`/`XGO`/
`XTR` — registradores, execução com breakpoints e trace passo a passo; `XSD` — exporta disassembly pra
um compilador externo; `XCO` — cor de tela real, paleta do MSX1; `XQT` — sai do monitor; `XDK`/`XFS`/
`XCI`/`XTP`/`XSV`/`XLD`/`XS#`/`XL#`/`XL%`/`XS%` — disco corrente único pra toda a família de comandos
de disco, sistema de arquivos, visualizador de texto, BSAVE/BLOAD reais, dump/restore cru com ou sem
FAT12; `XIM`/`XIC`/`XIL`/`XIS`/`XIR` — notas por endereço, com um visualizador dedicado com busca
Case/Regex; `XPP`/`XPI`/`XPO` — **painel de portas I/O**, monitora até 256 portas, mostrando o que o
programa simulado manda por `OUT` e permitindo simular manualmente o que uma `IN` deveria ler de volta,
já religado nas próprias instruções `IN`/`OUT`/`INI`/`IND`/`OUTI`/`OUTD` da CPU Z80 simulada). **Ajuda →
Mamute Assembler...** sempre reflete só o que já foi portado; lista completa de comandos pendentes em
`docs/SPEC.md`, seção "Lacunas conhecidas".

![Mamute Assembler — monitor estilo anos 80 (Executar → Mamute Assembler...)](docs/images/msxbasica-21.png)

Detalhes em `docs/SPEC.md`, módulo 31.

**🦴 Fossauro — emulador MSX nativo (`src/fossauro/`)** — ⚠️ ainda em fase inicial, não é uso
despreocupado ainda — port em PureBasic do **fMSX** de Marat Fayzullin, projeto irmão dentro deste
mesmo repositório (não incorporado à IDE — licença própria não-comercial, incompatível com a GPL v3
deste projeto, ver [Licença](#licença) abaixo — sempre chamado como executável externo). Já **boota
MSX1/MSX2/MSX2+ de ponta a ponta** até o prompt do BASIC, com áudio do PSG (AY-3-8910) e vídeo SCREEN
0/1/2/6/7 funcionando. Integrado à IDE de duas formas: **`Executar → Fossauro`** (F10) abre o
emulador configurado, e o comando **`FOSSAURO`** do Mamute Assembler transfere um programa Z80 recém
montado direto pra RAM dele e digita `DEFUSR0=&Hxxxx` na sessão — sem passar por disco, sem hijack de
`PC`/pilha (mesmo protocolo de controle remoto próprio, via named pipe, que o comando `OPENMSX`
reaproveita pra mirar um openMSX de verdade em vez do Fossauro). Limitações conhecidas e documentadas:
escala de vídeo maior que 1:1 trava a janela (causa raiz não isolada, ver `docs/SPEC.md` módulo 32s) e
o driver de disquete (FDC) tem uma regressão de boot ainda aberta.

![Fossauro rodando MSX BASIC (Executar → Fossauro)](docs/images/msxbasica-22.png)

Detalhes em `docs/SPEC.md`, módulos 32b-36.

## Changelog

O histórico completo, sessão a sessão, morou aqui por um tempo — agora vive em
[`CHANGELOG.md`](CHANGELOG.md) (ficou grande demais pra um README continuar sendo uma boa porta de
entrada pro projeto). Para notas de lançamento formais, com codinome, veja
[`docs/RELEASE_NOTES.md`](docs/RELEASE_NOTES.md).

## Ferramentas e ambiente

Projeto desenvolvido com:

- **[PureBasic](https://www.purebasic.com/) 6.41** — linguagem/compilador da IDE (Windows e Linux).
- **Windows** e **Ubuntu** — desenvolvido e testado nos dois sistemas.
- **PowerShell** — automação, build e scripts no ambiente Windows.
- **[Helix](https://helix-editor.com/)** — editor de texto modal usado no dia a dia de edição de
  código.
- **[Claude](https://claude.com/claude-code)** (Anthropic) — par de programação via Claude Code,
  usado para boa parte da implementação, revisão e documentação do projeto.
- **[GitHub](https://github.com/)** — versionamento e hospedagem do repositório.

## Agradecimentos

Este projeto não existiria sem o trabalho de:

- **[Fred Rique (farique1)](https://github.com/farique1)**, autor do
  [**Basic Dignified Suite**](https://github.com/farique1/basic-dignified) — o dialeto Dignified, o
  motor de pré-processamento e o tokenizador MSX-BASIC originais (em Python) foram a especificação de
  comportamento e a maior fonte de inspiração para tudo que foi reescrito nativamente aqui. O código de
  teste de regressão do projeto (`dist/sample/teste.dmx`, "Change Graph Kit") também é obra dele.
- **[Amaury Carvalho](https://github.com/amaurycarvalho)**, autor do
  [**msxbas2rom**](https://github.com/amaurycarvalho/msxbas2rom) — compilador MSX BASIC → ROM que
  inspira o back-end de geração de ROM planejado para esta IDE.
- **Nestor Soriano ([Konamiman](https://github.com/Konamiman))**, autor do
  [**Nestor80**](https://github.com/Konamiman/Nestor80) (assembler/linker/gerenciador de biblioteca
  Z80 100% compatível com o M80/L80 da Microsoft) — especificação de comportamento e oráculo de teste
  (`N80.exe`/`LK80.exe`/`LB80.exe`, compilados localmente a partir do código-fonte C# aberto) para o
  assembler Z80 nativo desta IDE, tanto o vocabulário de syntax highlight quanto o motor de montagem em
  si (tabela de opcodes, avaliador de expressão, formato `.REL`).
- **Fuzzy Logic** (R. v/d Meulen e A. v/d Wal, Holanda), autores do **SEE (Sound Effect Editor) v3.10**
  (1991/95), editor shareware de efeitos sonoros PSG para MSX — o formato de arquivo `.SEE` e o driver de
  replay original (`SEE3PLAY.ASC`) foram a especificação de comportamento (estudada por engenharia
  reversa do driver, campo a campo) para o editor **SEE Tracker** nativo desta IDE (`Criar → SEE
  Tracker...`) e seu driver de replay Z80 embutido, uma porta própria do driver original.
- **[Marat Fayzullin](https://fms.komkon.org/)**, autor do **[fMSX](https://fms.komkon.org/fMSX/)**
  (emulador MSX portátil desde 1994) — código-fonte do núcleo Z80 e do hardware MSX (VDP V9938, PSG
  AY8910, FDC WD1793) estudado como especificação de comportamento para o **debugger visual Z80**
  planejado para o Mamute Assembler (ver `docs/SPEC.md`, módulo 32) — mesma relação de "espec a portar,
  não dependência de runtime" já usada com o Basic Dignified Suite e o Nestor80 acima; o fMSX é
  distribuído sob licença própria não-comercial, então nenhum código dele é copiado para este projeto
  (GPL v3), só sua semântica de comportamento.

## Licença

Este repositório tem **duas licenças separadas**, uma por sub-projeto — não misture os dois ao
redistribuir:

| Sub-projeto | Licença | Arquivo | Por quê |
|---|---|---|---|
| **Paleobasic** (`src/editor/`, o IDE em si) | [GNU GPL v3](LICENSE) | [`LICENSE`](LICENSE) | Licença própria do projeto, copyleft. |
| **🦴 Fossauro** (`src/fossauro/`, port do fMSX) | Não-comercial (derivada da licença original do fMSX) | [`LICENSE-fossauro`](LICENSE-fossauro) (cópia também em [`src/fossauro/LICENSE`](src/fossauro/LICENSE)) | `src/fossauro/` é um port do código de Marat Fayzullin — herda a cláusula não-comercial do fMSX original, incompatível com GPL v3. Uso, cópia e modificação são livres para fins não-comerciais/educacionais; uso comercial exige permissão do autor original. |

As duas licenças convivem porque, hoje, os dois sub-projetos rodam como **processos separados** (o
IDE não faz link direto com o código do Fossauro) — ver `docs/SPEC.md`, módulo 32b, para a pendência
em aberto sobre o que acontece se uma integração mais profunda (in-process) vier a ser decidida no
futuro.
