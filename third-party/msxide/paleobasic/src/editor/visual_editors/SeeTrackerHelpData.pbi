;
; ------------------------------------------------------------
;  Ajuda -> SEE Tracker...: base de dados dos topicos de ajuda, compilada a
;  partir do material original do "Sound Effect Editor" (SEE) v3.10a (c)
;  Fuzzy Logic 1991/95, que vive em see/ neste repositorio:
;
;  - see/SEE3HELP.TXT   - manual oficial da v3.10 (o mais atual disponivel;
;                          see/SEE3HELP.DOC e see/SEE3HELP.TED sao a v3.00,
;                          mais antiga e superada por este).
;  - see/SEE3PLAY.ASC   - fonte Z80 (WBass2, salvo como ASCII) do driver de
;                          replay v3.10a. Fonte de verdade sobre o formato
;                          BINARIO de verdade - corrige/precisa varios
;                          pontos que o manual so descreve por alto (ex.:
;                          quais bits o driver realmente testa no byte de
;                          evento, como FOR/NEXT e START/RERUN realmente
;                          avancam o ponteiro de pattern, a formula exata
;                          de escala de volume por "Max Volume").
;  - see/*.SEE           - arquivos de exemplo reais (FIREBIRD/PLICS/
;                          QUARTH/SEEDRUMS) inspecionados byte a byte
;                          (cabecalho) pra confirmar o que o manual/driver
;                          descrevem.
;
;  Objetivo desta tela: registrar tudo que foi entendido nesta sessao de
;  ESTUDO (2026-08-06), preparando o terreno para um tracker nativo
;  compativel com o formato .SEE (ainda nao iniciado - ver o grupo "Rumo a
;  um tracker compativel" no fim). Onde o manual e o driver divergem ou
;  onde algo nao foi confirmado empiricamente contra os arquivos reais,
;  isso e dito explicitamente, sem inventar certeza que nao existe.
;
;  Mesma infraestrutura de NestorBasicHelpGui.pbi (arvore + busca +
;  historico), reaproveitando NBHelpGui_SetupStyles/_RenderMarkdown - mesma
;  marcacao minima: linhas "## " (subtitulo), "**negrito**" e "`codigo`".
; ------------------------------------------------------------
;

Structure SeeHelpTopic
  Titulo.s
  Grupo.s
  Corpo.s
EndStructure

Global NewList SeeHelp_Topics.SeeHelpTopic()
Global SeeHelp_DataBuilt.b = #False

Procedure SeeHelp_Add(Titulo.s, Grupo.s, Corpo.s)
  AddElement(SeeHelp_Topics())
  SeeHelp_Topics()\Titulo = Titulo
  SeeHelp_Topics()\Grupo = Grupo
  SeeHelp_Topics()\Corpo = Corpo
EndProcedure

Declare SeeHelp_BuildIntroducao()
Declare SeeHelp_BuildEditor()
Declare SeeHelp_BuildTeclas()
Declare SeeHelp_BuildFormatoArquivo()
Declare SeeHelp_BuildDriver()
Declare SeeHelp_BuildBasic()
Declare SeeHelp_BuildFuturo()

Procedure SeeHelp_BuildData()
  If SeeHelp_DataBuilt
    ProcedureReturn
  EndIf
  SeeHelp_DataBuilt = #True

  SeeHelp_BuildIntroducao()
  SeeHelp_BuildEditor()
  SeeHelp_BuildTeclas()
  SeeHelp_BuildFormatoArquivo()
  SeeHelp_BuildDriver()
  SeeHelp_BuildBasic()
  SeeHelp_BuildFuturo()
EndProcedure

; ================================================================
; Grupo: Introducao
; ================================================================
Procedure SeeHelp_BuildIntroducao()

  SeeHelp_Add("O que e o SEE", "Introducao",
    "**SEE** (Sound Effect Editor) e um editor de **efeitos sonoros** (SFX curtos - tiro, explosao, " +
    "moeda, etc.), NAO um tracker de musica, pro chip PSG do MSX (AY-3-8910/YM2149). Feito por " +
    "**Fuzzy Logic** (R. v/d Meulen e A. v/d Wal, Holanda), shareware - pode ser copiado livremente, " +
    "mas uso comercial exige pagamento aos autores (ver endereco no fim do manual original)." + #CRLF$ + #CRLF$ +
    "A versao presente neste repositorio (`see/`) e a **v3.10a (25/01/94)**, a mais recente/completa. " +
    "Existe tambem uma v3.00 mais antiga (`see/SEE3HELP.DOC`/`.TED`), mantida aqui so como historico - " +
    "**superada** pela v3.10 em tudo (corrige um bug real do driver de replay, funciona sob DOS2, etc., " +
    "ver `Mudancas entre versoes` no proximo topico)." + #CRLF$ + #CRLF$ +
    "O programa gera arquivos `.SEE` (varios efeitos por arquivo) ou `.SFX` (um efeito isolado), " +
    "tocados na hora via um pequeno **driver Z80** (`see/SEE3PLAY.ASC`) que fica residente e e chamado " +
    "pelo BASIC (ou por codigo de maquina) sempre que um efeito precisa tocar - o mesmo tipo de " +
    "integracao `BLOAD` + `DEFUSR`/`USR()` que o **NestorBASIC** desta IDE ja usa (ver Ajuda -> Nestor " +
    "Basic...)." + #CRLF$ + #CRLF$ +
    "**Por que estudar isso**: o objetivo declarado e construir, nesta IDE, um **tracker de SFX nativo " +
    "compativel com o formato .SEE**, para SFX gerados aqui poderem tocar tanto no editor original " +
    "quanto (o caminho principal) via NestorBASIC. Esta tela de Ajuda e o resultado de uma sessao de " +
    "estudo - ainda **NAO existe** nenhum editor/gerador `.SEE` nesta IDE.")

  SeeHelp_Add("Mudancas entre versoes (v2 -> v3.00 -> v3.10)", "Introducao",
    "Da v2.xx pra v3.xx (reescrita total):" + #CRLF$ +
    "- Edicao mais rapida, **varios patterns na tela** ao mesmo tempo (13 visiveis)." + #CRLF$ +
    "- Comandos de **bloco** (copiar/substituir um intervalo de patterns de uma vez)." + #CRLF$ +
    "- Novo **formato de arquivo**, mais compacto." + #CRLF$ + #CRLF$ +
    "Da v3.00 pra v3.10 (a versao presente neste repositorio):" + #CRLF$ +
    "- Funciona 100% sob DOS2 (rodando de dentro do BASIC)." + #CRLF$ +
    "- Boot de qualquer drive/(sub)diretorio." + #CRLF$ +
    "- Checagem correta do arquivo ao abrir um `.SEE`." + #CRLF$ +
    "- **Bug real corrigido no driver de replay**: com `MAXVOL` (a variavel `SEEVOL` do driver - ver " +
    "grupo `Motor de replay`) ajustado abaixo de 15, alguns *slides* de volume ficavam incorretos. O " +
    "proprio manual avisa: use o `SEE3PLAY.asc` da v3.10, nao um driver antigo, para SFX corretos." + #CRLF$ +
    "- Um bit de afinacao (`Tuning`) dos canais de rustle que nao estava sendo limpo ao exibi-los na " +
    "tela do editor.")

  SeeHelp_Add("Arquivos deste projeto (pasta see/)", "Introducao",
    "Inventario do que esta em `see/` e pra que serve - use como referencia de qual arquivo e " +
    "**autoritativo** (v3.10) e qual e so historico (v3.00):" + #CRLF$ + #CRLF$ +
    "**Programa v3.10 (o que importa)**" + #CRLF$ +
    "- `SEEV3_10.BIN` + `SEEV3_10.LIB` - o editor SEE em si (`SEEV3_10.BAS` e o bootstrap BASIC: " +
    "`BLOAD` do `.bin`, depois de mais 2 overlays - `loadfuz.bin`/`softmenu.bin` - que NAO estao " +
    "presentes nesta pasta)." + #CRLF$ +
    "- `SEE3PLAY.ASC` - **fonte Z80 do driver de replay** (o mais importante pra compatibilidade - " +
    "ver grupo `Motor de replay`)." + #CRLF$ +
    "- `SEE3HELP.TXT` - manual da v3.10 (base desta tela de Ajuda)." + #CRLF$ +
    "- `SEEBASIC.BIN` - um driver de replay ja montado (usado pelo exemplo `SEE.BAS`)." + #CRLF$ +
    "- `SEE3.PRF` - arquivo de preferencias (9 bytes, salvo pelo BASIC ao redor do editor, nao pelo " +
    "editor em si - ver `Preferencias e Disk mode`)." + #CRLF$ + #CRLF$ +
    "**Exemplos reais de `.SEE`** (usados pra conferir o cabecalho byte a byte neste estudo)" + #CRLF$ +
    "- `SEEDRUMS.SEE` - exemplo oficial (kit de bateria via PSG) que acompanha a v3.10." + #CRLF$ +
    "- `FIREBIRD.SEE`, `PLICS.SEE`, `QUARTH.SEE` - coletados de jogos/projetos reais." + #CRLF$ + #CRLF$ +
    "**v3.00, historico (superado)**" + #CRLF$ +
    "- `SEE3.COM`/`SEE3BOOT.BIN`/`SEE3.LIB` - o editor v3.00 (DOS1/BASIC)." + #CRLF$ +
    "- `SEE3HELP.DOC` - manual da v3.00 (diverge da v3.10 em varios pontos - ver topico anterior)." + #CRLF$ +
    "- `SEE3HELP.TED` - o mesmo manual, no formato binario de um editor de texto/processador de " +
    "texto MSX (referencia a `ADRES.MRG`/`STANDARD.CHR`) - so a origem de onde `.DOC`/`.TXT` foram " +
    "exportados, sem conteudo extra." + #CRLF$ +
    "- `SEE.LDR`/`SEE.BAT` - menu de boot em BASIC (ler manual / rodar o programa / voltar ao menu do " +
    "disco de origem).")
EndProcedure

; ================================================================
; Grupo: Usando o editor original
; ================================================================
Procedure SeeHelp_BuildEditor()

  SeeHelp_Add("Tela principal", "Usando o editor original",
    "No topo: **menu principal**, navegavel pelos cursores. No meio: ate **13 patterns** visiveis de " +
    "uma vez (rolando quando voce sobe/desce); o pattern **atual** (o 7o da lista, no centro) fica " +
    "destacado com uma barra. Embaixo: a **linha de status**, que mostra toda acao feita.")

  SeeHelp_Add("Menu principal e teclas de funcao", "Usando o editor original",
    "- `NEW` [F4] - limpa todos os patterns e dados de SFX." + #CRLF$ +
    "- `Preferences` [F10] - tela de preferencias (ver topico proprio)." + #CRLF$ +
    "- `Diskop` [F5] - tela de disco (salvar/carregar `.SEE`/`.SFX`)." + #CRLF$ +
    "- `Quit` [ESC] - sai do SEE3, volta pro BASIC." + #CRLF$ +
    "- `Play SFX` [F1] / `Play SFX visual` [F6] - toca o SFX atual (a segunda opcao tambem mostra os " +
    "patterns tocando). `Stop noise`/`Play status` [STOP] corta o som." + #CRLF$ +
    "- `Sound FX nr` [F2] - numero do SFX selecionado (0-255)." + #CRLF$ +
    "- `Start pattern` [F3] - pattern inicial deste SFX (RETURN reseta pra OFF)." + #CRLF$ +
    "- `Set next FX pat` [F9] - fecha o SFX atual e ja prepara o pattern inicial do PROXIMO numero de " +
    "SFX (incrementa o `Sound FX nr` sozinho)." + #CRLF$ +
    "- `Quant` [F7] - passo do cursor Y apos editar um canal (`Y = Y + Quant`)." + #CRLF$ +
    "- `Poly` [F8] - quando ligado, o canal de edicao avanca (`X = X + 1`) sozinho apos editar." + #CRLF$ +
    "- `Edit` [SELECT] - liga/desliga o modo de edicao." + #CRLF$ +
    "- `Block` - mostra o intervalo de bloco marcado (RETURN remove)." + #CRLF$ +
    "- `Max Volume` - volume maximo/mestre do efeito (ver formula exata em `Slides de afinacao e " +
    "volume`, grupo `Motor de replay`)." + #CRLF$ +
    "- `Pattern filter`/`Print` - **presentes no menu mas nao implementados** (o proprio manual diz " +
    "`<not yet in use>`)." + #CRLF$ + #CRLF$ +
    "**Outras teclas da tela principal**: [+]/[-] muda o numero do SFX; [SELECT] alterna 50/60Hz.")

  SeeHelp_Add("Edicao de pattern: os 11 canais", "Usando o editor original",
    "Cada **pattern** (linha da grade de edicao) tem 11 canais lado a lado:" + #CRLF$ +
    "- **event** (1) - comandos de controle do pattern (ver proximo topico)." + #CRLF$ +
    "- **snd1/2/3** (2-4) - frequencia PSG de cada um dos 3 canais de som. Sem dado = canal desligado " +
    "automaticamente." + #CRLF$ +
    "- **rus1/2/3** (5-7) - canal de **rustle** (ruido) usado por cada canal de som. So existe **um** " +
    "registrador de ruido real no PSG (compartilhado pelos 3 canais), mas cada canal escolhe usar (ou " +
    "nao) esse ruido independentemente." + #CRLF$ +
    "- **vol1/2/3** (8-10) - volume de cada canal de som (0-15)." + #CRLF$ +
    "- **wave** (11) - padrao do envelope de volume PSG (so aparece quando algum canal de volume usa " +
    "a `Wave` do PSG)." + #CRLF$ +
    "- **time** (12) - periodo do envelope (regs. 11/12 do PSG, 12 bits, `000`-`FFF`)." + #CRLF$ + #CRLF$ +
    "Para digitar dados, use `0-9`/`A-F` (hexadecimal); `Backspace` apaga/desliga o canal atual.")

  SeeHelp_Add("Canal Event: comandos de controle", "Usando o editor original",
    "Digite a **primeira letra** do comando pra editar (`H` de HALT, `F` de FOR, `E` de END, etc.); " +
    "`Backspace` limpa." + #CRLF$ + #CRLF$ +
    "- `--` (vazio) - nao faz nada extra, so toca os dados PSG deste pattern." + #CRLF$ +
    "- `HALT (x)` - espera `x` interrupcoes (1/50 ou 1/60s cada) **antes** de tocar os dados PSG DESTE " +
    "pattern (ou seja, o dado do proprio pattern do HALT so soa depois da espera)." + #CRLF$ +
    "- `FOR (x)` - marca o **inicio** de um loop, repetido `x` vezes. Ate **4 loops** podem estar " +
    "ativos ao mesmo tempo (aninhados)." + #CRLF$ +
    "- `NEXT` - fecha o loop mais recente (volta pro `FOR` se ainda faltar repeticao)." + #CRLF$ +
    "- `START` - marca um ponto de **retomada** (diferente do `FOR`: sem contador, e um so, nao " +
    "aninha)." + #CRLF$ +
    "- `RERUN` - volta pro ultimo `START` - **sempre**, sem contador (na pratica cria um loop " +
    "infinito ate o som ser cortado de fora, tipo a parte 'sustain' de um efeito)." + #CRLF$ +
    "- `TMP (x)` - muda o **tempo** de reproducao (medido em interrupcoes por passo)." + #CRLF$ +
    "- `END` - fim do efeito." + #CRLF$ + #CRLF$ +
    "## Exemplo do manual (FOR/NEXT)" + #CRLF$ +
    "`000  FOR 7   xxx yyy zzz`" + #CRLF$ +
    "`001   -      xxx yyy zzz`" + #CRLF$ +
    "`002  NEXT     -   -   -`" + #CRLF$ +
    "`003  END      -   -   -`" + #CRLF$ +
    "Os patterns 000+001 repetem 7 vezes. **Detalhe importante, so visivel lendo o driver de replay " +
    "(nao esta no manual)**: `FOR`/`START` disparam so na PRIMEIRA vez que o ponteiro chega neles - " +
    "nas voltas seguintes do loop, o driver so reaplica os DADOS PSG daquele pattern (sem reprocessar " +
    "o evento `FOR`/`START` de novo). Detalhe tecnico completo em `Como FOR/NEXT e START/RERUN " +
    "realmente funcionam` (grupo `Motor de replay`).")

  SeeHelp_Add("Efeitos de canal: slides D:/U: e envelope (Wave)", "Usando o editor original",
    "Em qualquer canal de **frequencia**, **rustle** ou **volume**, `SHIFT`+letra liga um efeito de " +
    "slide:" + #CRLF$ +
    "- `D:xxx` - Down slide (o valor do registrador **diminui**)." + #CRLF$ +
    "- `U:xxx` - Up slide (o valor do registrador **aumenta**)." + #CRLF$ +
    "(`xxx` = taxa do slide; menos digitos nos canais de rustle/volume que no de frequencia.)" + #CRLF$ + #CRLF$ +
    "**Pegadinha do proprio manual**: nos canais de FREQUENCIA, `D` (down) faz o valor do registrador " +
    "diminuir, mas isso faz o **som** ficar mais AGUDO (e vice-versa) - o registrador PSG e um " +
    "divisor de periodo, nao uma frequencia direta." + #CRLF$ + #CRLF$ +
    "Nos canais de **volume** existe ainda `Wave` (`SHIFT+W`) - ativa o **envelope de volume padrao " +
    "do PSG** (as 15 formas de hardware) em vez de slide por software; quando usado, defina o padrao " +
    "e o tempo do envelope nos canais `wave`/`time` (ver `Registradores do PSG` no grupo `Motor de " +
    "replay` pra saber exatamente o que isso desliga).")

  SeeHelp_Add("Bloco (edicao em lote)", "Usando o editor original",
    "So existe **um** bloco por vez, definido por um pattern inicial/final (mostrado no menu " +
    "principal como `Block: xxx-yyy`); os patterns dentro dele ficam destacados com uma cor." + #CRLF$ + #CRLF$ +
    "Comandos (tecla `CODE` + letra):" + #CRLF$ +
    "- `CODE+S` - marca o pattern **inicial** do bloco." + #CRLF$ +
    "- `CODE+E` - marca o pattern **final**." + #CRLF$ +
    "- `CODE+G` - vai pro primeiro pattern do bloco." + #CRLF$ +
    "- `CODE+C` - **copia** o bloco pra posicao do cursor." + #CRLF$ +
    "- `CODE+M`/`RETURN` - **substitui** (replace) na posicao do cursor." + #CRLF$ +
    "- `CODE+Backspace` - apaga os patterns do bloco." + #CRLF$ +
    "- `CODE+Espaco` - remove a marcacao do bloco (sem apagar patterns)." + #CRLF$ + #CRLF$ +
    "(A tecla `[+]`/`espaco` no menu principal tambem remove o bloco com `RETURN`.)")

  SeeHelp_Add("Preferencias e Disk mode", "Usando o editor original",
    "**Preferencias** [F10] - ajustes de tela, salvos em `SEE3.prf` no drive atual (o mesmo escolhido " +
    "no Diskop). Se esse arquivo existir na hora de dar boot no SEE, ele e carregado automaticamente." + #CRLF$ + #CRLF$ +
    "**Disk mode** [F5] - salvar/carregar SFX, com um formatador de disco embutido. Dois tipos de " +
    "arquivo:" + #CRLF$ +
    "- `.SEE` - **todos** os SFX do projeto, num arquivo so (ver `Formato de arquivo .SEE`)." + #CRLF$ +
    "- `.SFX` - **um unico** SFX isolado." + #CRLF$ + #CRLF$ +
    "Ao carregar um `.SFX`, o pattern inicial do SFX atual precisa estar definido antes (senao da " +
    "erro). Ao salvar um `.SFX`, o SEE exige um pattern inicial e um evento de fim (`END` ou `RERUN`) " +
    "corretos, checando isso antes de gravar. O SEE tambem **verifica a identificacao** do arquivo ao " +
    "abrir um `.SEE`/`.SFX`, recusando arquivos que nao sejam da v3.xx (ver `Cabecalho do arquivo`, " +
    "onde o CHECK REAL do driver de replay - so 4 bytes - e mais frouxo que o do editor)." + #CRLF$ + #CRLF$ +
    "O SEE lembra o **ultimo diretorio** visto de cada tipo de arquivo (`.SEE`/`.SFX`) separadamente. " +
    "**Nao ha cruncher** (compressao) implementado nesta versao, apesar do menu mencionar a opcao.")
EndProcedure

; ================================================================
; Grupo: Referencia de teclas
; ================================================================
Procedure SeeHelp_BuildTeclas()

  SeeHelp_Add("Teclas da tela principal", "Referencia de teclas",
    "- `F1` - toca o SFX atual." + #CRLF$ +
    "- `F6` - idem, mostrando os patterns tocando." + #CRLF$ +
    "- `F2` - escolhe o SFX." + #CRLF$ +
    "- `F3` - define o pattern inicial." + #CRLF$ +
    "- `F4` - New (limpa tudo)." + #CRLF$ +
    "- `F5` - Disk mode." + #CRLF$ +
    "- `F7` - define o Quant." + #CRLF$ +
    "- `F8` - liga/desliga Poly." + #CRLF$ +
    "- `F9` - fecha o SFX atual e prepara o pattern inicial do proximo." + #CRLF$ +
    "- `F10` - Preferencias." + #CRLF$ +
    "- `SELECT` - alterna 50/60Hz." + #CRLF$ +
    "- `STOP` - corta o SFX tocando." + #CRLF$ +
    "- `[+]`/`[-]` - aumenta/diminui o numero do SFX." + #CRLF$ +
    "- `ESC` - sai do SEE.")

  SeeHelp_Add("Teclas do menu principal e da edicao de pattern", "Referencia de teclas",
    "**Menu principal**: setas movem o cursor; `Espaco` confirma; `Return` idem (com efeito especial " +
    "em alguns campos); `Home` vai pro topo; `Graphic`/`Trig B` entram na edicao de pattern." + #CRLF$ + #CRLF$ +
    "**Edicao de pattern**: setas movem; `Home` vai pro pattern 0; `Return` vai pro canal 0 (event); " +
    "`ESC`/`Graphic`/`Trig B` voltam pro menu; `Backspace` limpa o canal atual; `DEL` apaga o pattern; " +
    "`INS` insere um pattern; `0-9`/`A-F` digitam dado no canal; `[Q]` define o Quant; `[P]` vai pra " +
    "um pattern especifico." + #CRLF$ + #CRLF$ +
    "`SHIFT` +: `Home` vai pro primeiro pattern do SFX atual; `Backspace` limpa o pattern inteiro; " +
    "`DEL`/`INS` como o normal mas movendo os patterns seguintes pra baixo/cima; `[U]`/`[D]` afinacao " +
    "(tuning) rapida; `[W]` liga Volume Wave (so nos canais de volume)." + #CRLF$ + #CRLF$ +
    "`CTRL` +: `[E]`/`[S]`/`[R]`/`[V]`/`[W]` vao direto pro canal Event/Sound/Rustle/Volume/Wave; " +
    "`[Q]`/`[P]` como acima; `Espaco` define o pattern inicial do SFX atual; `Return` apaga o SFX " +
    "atual (OFF)." + #CRLF$ + #CRLF$ +
    "`CODE` + (comandos de bloco): ver topico `Bloco (edicao em lote)`.")

  SeeHelp_Add("Teclas do Disk mode", "Referencia de teclas",
    "Setas movem o cursor; `Espaco` confirma; `Return` idem; `Home` vai pro topo da tela; `ESC`/`F5` " +
    "saem (voltam ao menu principal); `[+]`/`[-]` mudam o numero do SFX.")
EndProcedure

; ================================================================
; Grupo: Formato de arquivo .SEE
; ================================================================
Procedure SeeHelp_BuildFormatoArquivo()

  SeeHelp_Add("Visao geral do arquivo", "Formato de arquivo .SEE", "Um `.SEE` tem pelo menos 3 partes, nesta ordem:" + #CRLF$ +
    "1. **Cabecalho** (16 bytes) - identificacao + 4 contadores (ver proximo topico)." + #CRLF$ +
    "2. **Tabela de posicoes** (512 bytes, a partir do offset `$0010`) - o pattern inicial de cada " +
    "um dos 256 SFX possiveis (ver `Tabela de posicoes de SFX`)." + #CRLF$ +
    "3. **Dados de pattern** (a partir do offset `$0210` no esquema de enderecamento do driver) - " +
    "um registro de **15 bytes por pattern** (ver `Formato de um pattern (15 bytes)`)." + #CRLF$ + #CRLF$ +
    "**Confirmado nos 4 arquivos de exemplo desta pasta** (`FIREBIRD`/`PLICS`/`QUARTH`/`SEEDRUMS.SEE`, " +
    "inspecionados byte a byte): todos comecam com os 4 bytes ASCII `SEE3`, mas o RESTO da " +
    "identificacao de 8 bytes varia - `SEE3org`+`$10` em 3 deles, `SEE3EDIT` no `QUARTH.SEE` " +
    "(provavelmente salvo por um build ligeiramente diferente do editor). Isso bate exatamente com o " +
    "que o driver de replay realmente verifica (so os 4 primeiros bytes - ver `Cabecalho do arquivo`)." + #CRLF$ + #CRLF$ +
    "**Achado novo (2026-08-06)**: nos 4 arquivos, `tamanho do arquivo - HIPTA` (fim dos dados de " +
    "pattern) da exatamente **1056 bytes sobrando no final**, sempre o mesmo valor independente do " +
    "tamanho do arquivo - hipotese forte de uma **4a area de tamanho fixo** (talvez uma tabela de " +
    "nomes de SFX, usada pela tela `Set next FX pat`?) nao documentada no Apendice B do manual nem " +
    "mencionada no driver de replay (o que bateria: o driver so precisa ler ate o fim dos patterns, " +
    "nunca olha o que vem depois). Nao investigado a fundo ainda - ver `Rumo a um tracker compativel`.")

  SeeHelp_Add("Cabecalho do arquivo (16 bytes) - RESOLVIDO por analise cruzada", "Formato de arquivo .SEE",
    "Offsets a partir do inicio do arquivo:" + #CRLF$ +
    "- `$00-$07` - Identificacao (8 bytes). O **manual** diz que deveria ser literalmente " +
    "`SEEv3.xx`; nos 4 arquivos de exemplo desta pasta o texto real e outro (`SEE3org`+`$10` ou " +
    "`SEE3EDIT`). **O que realmente importa pro replay**: o driver `SEE3PLAY.ASC` so compara os " +
    "**4 primeiros bytes** contra o texto `SEE3` - o resto do campo e ignorado pelo player (pode ser " +
    "usado pelo EDITOR pra guardar uma sub-versao, mas nao afeta se o som toca)." + #CRLF$ +
    "- `$08-$09` - `Highest used pattern`. **Confirmado (2026-08-06)**: le sempre `$03FF` (1023) nos " +
    "4 arquivos de exemplo, apesar de tamanhos bem diferentes - **nao e uma contagem por arquivo**, " +
    "e uma **constante de capacidade do formato**: bate exatamente com `%PATTS EQU &H0210 ;max 1024 " +
    "patts` do proprio driver (patterns enderecaveis vao de `0` a `1023` = `$3FF`)." + #CRLF$ +
    "- `$0A-$0B` - `Highest used pattern+1 offset_address`. **Formula confirmada nos 4 arquivos, " +
    "divisao exata (resto zero) em todos**: `(numero de patterns realmente usados no arquivo) * 15 + " +
    "528` (528 = 16 de cabecalho + 512 da tabela de posicoes). Usado pelo **driver** como guarda de " +
    "seguranca em tempo de execucao: `SEEADR + este_valor` = endereco (em MEMORIA, nao no arquivo) do " +
    "byte logo depois do ultimo dado de pattern valido; se o ponteiro de leitura passar disso, o " +
    "driver corta o som sozinho (protecao contra dado `.SEE` corrompido/incompleto)." + #CRLF$ +
    "- `$0C-$0D` - `Highest used SFX`. Deu valores pequenos e plausiveis nos 3 arquivos `SEE3org` " +
    "(`32`/`9`/`13`), usado pra validar o numero de SFX pedido em `SETSFX` (erro se for maior que " +
    "este valor). **Anomalia isolada**: no `QUARTH.SEE` (unico com ID `SEE3EDIT`, provavelmente de um " +
    "build ligeiramente diferente) esse campo leu `48394` - um numero absurdo pra um indice de SFX " +
    "que so vai de 0 a 255. Fica como duvida especifica desse arquivo/variante, sem afetar a formula " +
    "confirmada para o formato `SEE3org` (o que interessa pra escrever nosso proprio gerador)." + #CRLF$ +
    "- `$0E-$0F` - O **manual** chama esse campo de `xx` (sem explicar). O **driver**, apesar de " +
    "rotular o campo de origem como `Unused` num comentario, copia ele pra uma variavel de trabalho " +
    "chamada literalmente `_FLELN` (`File length`) - e nunca le essa copia de novo em lugar nenhum da " +
    "logica de replay. Nos 3 arquivos `SEE3org` leu sempre `0` (nao bate com o tamanho real do " +
    "arquivo) - ou seja, **na pratica nao guarda o tamanho do arquivo** (ou so e preenchido em " +
    "circunstancias que nao apareceram nestes 4 exemplos). Continua **irrelevante pro player** de " +
    "qualquer forma, ja que nunca e lido de volta." + #CRLF$ + #CRLF$ +
    "**Nota tecnica sobre o proprio driver**: a rotina `SEE_IN` (`SEE3PLAY.ASC`) faz `LD B,4` no loop " +
    "que confere a identificacao (compara so 4 bytes), e o `LDIR` que copia estes 4 campos pra " +
    "memoria de trabalho comeca **logo em seguida**, sem reposicionar o ponteiro - lido ao pe da " +
    "letra, isso copiaria a partir do byte `4` do arquivo, nao do `8`. Testado contra os 4 arquivos " +
    "reais: essa leitura literal da numeros sem sentido (nenhuma divisao inteira, nenhuma consistencia " +
    "entre arquivos), enquanto ler a partir do byte `8` (como os proprios comentarios `%HISPT EQU " +
    "&H08` do driver dizem) bate perfeitamente em todos os 4. Suspeita forte: **erro de transcricao** " +
    "no `.ASC` (`LD B,4` deveria ser `LD B,8` - o template `SEE_ID` comparado logo abaixo tem " +
    "exatamente 8 bytes declarados, `" + MSXQ + "SEE3???" + MSXQ + "` + `$10`, entao um loop de 4 s " +
    "usaria metade do template declarado). Pra fins de formato de arquivo, os offsets `$08`/`$0A`/" +
    "`$0C`/`$0E` (como o manual e os EQU descrevem) sao os corretos.")

  SeeHelp_Add("Tabela de posicoes de SFX", "Formato de arquivo .SEE",
    "A partir do offset `$0010`: **512 bytes** = 256 entradas de 2 bytes (little-endian), uma por " +
    "numero de SFX possivel (`0`-`255`). Cada entrada guarda o **numero do pattern inicial** daquele " +
    "SFX." + #CRLF$ + #CRLF$ +
    "Um SFX **nao definido** usa o byte alto `$FF` como sentinela (o driver testa exatamente isso em " +
    "`SETSFX`: se o byte alto lido for `$FF`, devolve erro `SFX nao existe`). Isso deixa `$FF00`-" +
    "`$FFFF` fora do alcance como pattern inicial valido - na pratica irrelevante, ja que o driver " +
    "reserva no maximo 1024 patterns (`$000`-`$3FF`).")

  SeeHelp_Add("Formato de um pattern (15 bytes)", "Formato de arquivo .SEE",
    "Cada pattern e um registro de **15 bytes fixos** - este layout foi conferido cruzando o Apendice " +
    "B do manual com o loop `SETPSG` do driver (`SEE3PLAY.ASC`), byte a byte, e os dois batem " +
    "perfeitamente (ao contrario do cabecalho, aqui nao ha divergencia):" + #CRLF$ + #CRLF$ +
    "- `$00` - **Event**. Bits 6-4 = comando (`AND $70`); bits 3-0 = valor. Ver `Bits exatos do byte " +
    "de evento` no grupo `Motor de replay` - o driver so testa 3 bits, nao o byte inteiro como o " +
    "manual da a entender." + #CRLF$ +
    "- `$01-$02` - Frequencia canal 1 (12 bits, little-endian: `$01`=byte baixo, `$02`=byte alto). No " +
    "byte alto: bit 7 = Tuning Up, bit 6 = Tuning Down, bits 3-0 = nibble alto da frequencia (bits " +
    "11-8)." + #CRLF$ +
    "- `$03-$04` - Frequencia canal 2 (mesmo layout de `$01-$02`)." + #CRLF$ +
    "- `$05-$06` - Frequencia canal 3 (idem)." + #CRLF$ +
    "- `$07` - Rustle: bit 7 = Tuning Up, bit 6 = Tuning Down, bits **4-0** (so 5 bits, nao 6 como o " +
    "manual sugere - ver `Registradores do PSG`) = valor de rustle (`0-31`)." + #CRLF$ +
    "- `$08` - Controle de canais (mixer): bits 0-2 = liga (`0`) canais de frequencia 1/2/3; bits 3-5 " +
    "= liga (`0`) rustle nos canais 1/2/3 (convencao real do PSG: **0 = ligado**)." + #CRLF$ +
    "- `$09` - Volume canal 1: bit 7 = Tuning Up, bit 6 = Tuning Down, bit 4 = usa envelope de " +
    "hardware do PSG (`Wave` ligado), bits 3-0 = volume (`0-15`)." + #CRLF$ +
    "- `$0A` - Volume canal 2 (mesmo layout de `$09`)." + #CRLF$ +
    "- `$0B` - Volume canal 3 (idem)." + #CRLF$ +
    "- `$0C-$0D` - Periodo do envelope PSG (regs. 11/12, 12 bits, little-endian) - vai **direto** pro " +
    "PSG, sem nenhum processamento de tuning/escala." + #CRLF$ +
    "- `$0E` - Forma do envelope PSG (reg. 13) - idem, direto pro PSG.")
EndProcedure

; ================================================================
; Grupo: Motor de replay (SEE3PLAY.ASC)
; ================================================================
Procedure SeeHelp_BuildDriver()

  SeeHelp_Add("API do driver (tabela de vetores)", "Motor de replay (SEE3PLAY.ASC)",
    "O driver monta em `$C000` (fixo no fonte original) com uma tabela de saltos no comeco - o mesmo " +
    "estilo de API que o **NestorBASIC** usa (varios pontos de entrada fixos, chamados via `DEFUSR`/" +
    "`USR()` do BASIC):" + #CRLF$ +
    "- **+0 `SEE_IN`** - inicializa o driver: confere a identificacao do arquivo (`SEE3`, so os 4 " +
    "primeiros bytes), copia o cabecalho pra memoria de trabalho e, se `SEETID=0`, pendura a rotina " +
    "principal no hook `H_TIMI` (`$FD9F`, interrupcao de VBlank da ROM) - ou seja, por padrao o " +
    "driver toca **sozinho**, uma vez por interrupcao, sem precisar de nenhum `CALL` manual por frame." + #CRLF$ +
    "- **+3 `SEE_EX`** - desliga o driver, silencia o PSG e restaura o hook de interrupcao original." + #CRLF$ +
    "- **+6 `SETSFX`** - inicia um SFX novo (recebe numero do SFX + prioridade); recusa se ja houver " +
    "um SFX de prioridade maior tocando." + #CRLF$ +
    "- **+9 `CUTSFX`** - corta o SFX atual na hora." + #CRLF$ +
    "- **+12 `SEEINT`** (`SEEINT: JP MAIN.A`) - ponto de entrada alternativo pra quem quiser chamar o " +
    "driver a partir da PROPRIA rotina de interrupcao (em vez de deixar o driver usar `H_TIMI` " +
    "sozinho) - controlado pela variavel `SEETID`." + #CRLF$ + #CRLF$ +
    "**Variaveis de estado** (memoria do driver, nao do arquivo `.SEE`): `SEEADR` (endereco base de " +
    "onde o `.SEE` foi carregado), `SEEMAP` (pagina de memoria/mapper, trocada e restaurada a cada " +
    "chamada via `IN`/`OUT ($FE)`), `SEETID` (0=usa `H_TIMI` sozinho, <>0=temporizacao externa), " +
    "`SEESTA` (bits de status: instalado / SFX tocando / ocupado trocando de SFX), `SFXPRI` " +
    "(prioridade do SFX atual) e `SEEVOL` (volume maximo/mestre, 0-15 - ver formula exata abaixo).")

  SeeHelp_Add("Bits exatos do byte de evento", "Motor de replay (SEE3PLAY.ASC)",
    "O manual descreve o byte de evento como se o **nibble alto inteiro** definisse o comando. Lendo " +
    "o driver (`!EVENT:`), o que realmente acontece e mais especifico:" + #CRLF$ +
    "`AND $70` isola so os **bits 6-4** (o bit 7 e ignorado pelo despacho, apesar do manual falar em " +
    "'bit 7 high' pra `RERUN`/`END` - isso e so uma convencao do EDITOR ao escrever o byte, nao algo " +
    "que o player verifica)." + #CRLF$ + #CRLF$ +
    "Valores testados (apos a mascara `$70`) e o que disparam:" + #CRLF$ +
    "- `$00` - nada (so toca os dados PSG do pattern)." + #CRLF$ +
    "- `$10` - `HALT`, valor = bits 3-0 (`0-15`)." + #CRLF$ +
    "- `$20` - `FOR`, valor = contagem de repeticoes (`0-15`)." + #CRLF$ +
    "- `$30` - `NEXT`." + #CRLF$ +
    "- `$40` - `START`." + #CRLF$ +
    "- `$50` - `RERUN`." + #CRLF$ +
    "- `$60` - `TEMPO`, valor = bits 3-0." + #CRLF$ +
    "- **qualquer outro resultado da mascara** (ou seja, so sobra `$70`) - cai no `EVEND` (fim de " +
    "efeito), o `else` implicito da cadeia de comparacoes.")

  SeeHelp_Add("Como FOR/NEXT e START/RERUN realmente funcionam", "Motor de replay (SEE3PLAY.ASC)",
    "Este e o detalhe menos obvio do formato - so aparece lendo o driver com atencao, o manual so " +
    "mostra o resultado (`Pattern 000+001 will be repeated 7 times`), nao o mecanismo." + #CRLF$ + #CRLF$ +
    "**FOR** guarda, num dos 4 slots de loop (`LOOPNR` circula `0-3`), o CONTADOR (nibble do evento) " +
    "e o **endereco do proprio pattern onde estava o `FOR`** - nao o pattern seguinte. Isso acontece " +
    "**so na primeira vez** que o ponteiro de pattern chega naturalmente nesse endereco." + #CRLF$ + #CRLF$ +
    "**NEXT** decrementa o contador do slot de loop mais recente. Se ainda for maior que zero, ele " +
    "faz o ponteiro de pattern **pular direto pro endereco guardado pelo `FOR`** - mas so pra ler os " +
    "**dados PSG** daquele pattern outra vez (o byte de evento do `FOR` e simplesmente pulado, " +
    "**nao** reprocessado - por isso `FOR` nunca dispara duas vezes pro mesmo slot). No frame " +
    "SEGUINTE, o ponteiro ja avancou normalmente pro pattern logo depois do `FOR` (repetindo a " +
    "sequencia inteira do bloco, um pattern por frame, ate o contador zerar). Quando o contador chega " +
    "a zero, o slot de loop e liberado e o `NEXT` deixa o ponteiro simplesmente continuar pro pattern " +
    "seguinte (normalmente o fim do bloco de repeticao)." + #CRLF$ + #CRLF$ +
    "**START**/**RERUN** funcionam igual, mas mais simples: **um so** slot global (`CLPADR`, sem " +
    "pilha/contador), sem limite de repeticoes - todo `RERUN` volta pro ultimo `START` marcado, pra " +
    "sempre, ate o efeito ser cortado de fora (`CUTSFX`)/sobrescrito por outro SFX. Isso e o jeito do " +
    "formato representar a parte 'sustain' (que toca indefinidamente) de um efeito." + #CRLF$ + #CRLF$ +
    "**Implicacao pratica pra um tracker compativel**: ao gerar/interpretar dados `.SEE`, o pattern " +
    "que contem `FOR`/`START` **sempre** faz parte da sequencia audivel (seus dados PSG tocam), " +
    "exatamente como qualquer outro pattern - `FOR`/`START` so adicionam o efeito colateral de marcar " +
    "onde voltar.")

  SeeHelp_Add("Registradores do PSG e o mapeamento exato", "Motor de replay (SEE3PLAY.ASC)",
    "`SETPSG` percorre os 15 bytes do pattern (pulando o byte de evento) e escreve, nesta ordem, nos " +
    "14 registradores do PSG (`OUT ($A0)`=numero do registrador, `OUT ($A1)`=dado):" + #CRLF$ +
    "- Regs. `0-5` - frequencia dos 3 canais (12 bits cada, mascarada pra 4 bits no byte alto antes " +
    "de escrever)." + #CRLF$ +
    "- Reg. `6` - rustle, mascarado com `AND $1F` (**5 bits**, `0-31`) antes de escrever - o valor " +
    "real do hardware, mais estreito que os `b5-b0` (6 bits) que o manual descreve." + #CRLF$ +
    "- Reg. `7` (mixer) - bits 0-5 copiados do byte `$08` do pattern (`AND $3F`), com o **bit 7 " +
    "sempre forcado a 1** antes de escrever (detalhe de implementacao deste driver especifico, nao " +
    "necessariamente um bit de hardware significativo)." + #CRLF$ +
    "- Regs. `8-10` - volume dos 3 canais. **Bit 4 (`Wave` no editor) e o proprio bit `M` do PSG " +
    "real** (liga o gerador de envelope de hardware em vez de volume fixo) - quando esse bit esta " +
    "ligado, o driver escreve o byte **cru**, sem aplicar slide de tuning nem a escala de `Max " +
    "Volume` (ver proximo topico): o envelope de hardware manda sozinho." + #CRLF$ +
    "- Regs. `11-12` - periodo do envelope (copiado cru do pattern, `$0C-$0D`)." + #CRLF$ +
    "- Reg. `13` - forma do envelope (copiado cru do pattern, `$0E`).")

  SeeHelp_Add("Slides de afinacao e volume (tuning) - formulas exatas", "Motor de replay (SEE3PLAY.ASC)",
    "O driver guarda, numa tabela interna (`PSGREG`), o **ultimo valor realmente escrito** em cada " +
    "registrador do PSG. Um slide (`D:`/`U:` no editor, bits 6/7 do campo) soma ou subtrai a TAXA " +
    "(valor do campo no pattern) a esse ultimo valor - ou seja, o slide e sempre relativo ao frame " +
    "ANTERIOR, nao ao valor bruto do pattern atual." + #CRLF$ + #CRLF$ +
    "- **Frequencia/rustle, slide pra cima** (`TUN_UP`/`TUNWUP`) - soma sem nenhum limite (pode " +
    "estourar o registrador se a taxa for grande demais/o slide for longo demais)." + #CRLF$ +
    "- **Frequencia/rustle, slide pra baixo** (`TUN_DW`/`TUNWDW`) - subtrai sem limite tambem." + #CRLF$ +
    "- **Volume, slide pra baixo** (`VOL_DW`) - **diferente**: usa uma rotina propria que trava em " +
    "zero (nao deixa estourar por baixo)." + #CRLF$ +
    "- **Volume, slide pra cima** usa a mesma `TUN_UP` generica (**sem travar em 15**) - uma " +
    "assimetria real do driver, nao um erro de leitura deste estudo." + #CRLF$ + #CRLF$ +
    "**`Max Volume` (`SEEVOL`)**: depois do slide (se houver), o volume de 0-15 e escalado assim " +
    "antes de ir pro PSG:" + #CRLF$ +
    "`volume_final = SEEVOL - (15 - volume_bruto)`, travado em 0 se o resultado for negativo." + #CRLF$ +
    "Ou seja, com `volume_bruto=15` (max), a saida e exatamente `SEEVOL`; com `volume_bruto=0`, a " +
    "saida so deixa de ser 0 se `SEEVOL>15` (impossivel, ja que e um valor de 4 bits) - na pratica " +
    "`SEEVOL` funciona como um TETO, nao como um multiplicador." + #CRLF$ + #CRLF$ +
    "**Detalhe fino**: o valor guardado de volta na tabela `PSGREG` (pra alimentar o PROXIMO slide) " +
    "e o volume **antes** dessa escala por `SEEVOL` - ou seja, mudar o `Max Volume` no meio de um " +
    "efeito nao contamina a matematica dos slides seguintes, so o volume realmente audivel.")
EndProcedure

; ================================================================
; Grupo: Integracao com MSX-BASIC
; ================================================================
Procedure SeeHelp_BuildBasic()

  SeeHelp_Add("Chamando o driver a partir do BASIC (DEFUSR)", "Integracao com MSX-BASIC",
    "O exemplo `see/SEE.BAS` (BASIC tokenizado) mostra o padrao de uso pretendido pelos autores - o " +
    "mesmo estilo `BLOAD` + `DEFUSR`/`USR()` que o **NestorBASIC** desta IDE ja usa (ver Ajuda -> " +
    "Nestor Basic...):" + #CRLF$ +
    "1. `BLOAD " + MSXQ + "seebasic.bin" + MSXQ + ",R` carrega o driver montado na memoria." + #CRLF$ +
    "2. Mapeia os pontos de entrada da tabela de vetores (ver `API do driver`) pra nomes de funcao " +
    "via `DEFUSR=endereco:A=USR(...)`: `ENABLESEE`/`DISABLESEE` (=`SEE_IN`/`SEE_EX`), `LDSEE` " +
    "(carrega/confere o arquivo `.SEE` que ja esta em `SEEADR`), `STARTFX`/`CUTFX` (=`SETSFX`/" +
    "`CUTSFX`)." + #CRLF$ +
    "3. Variaveis auxiliares: `FXMAP` (mapper), `FXADR` (endereco base do `.SEE` carregado), `FXNUM` " +
    "(numero do SFX a tocar) e `SEEFILE` (nome do arquivo, gravado nos primeiros bytes reservados " +
    "pro driver conferir)." + #CRLF$ +
    "4. Fluxo tipico: carregar o driver -> `LDSEE` -> `ENABLESEE` (pendura o driver no `H_TIMI`) -> " +
    "escrever `FXNUM` e chamar `STARTFX` toda vez que quiser tocar um efeito -> `DISABLESEE` ao " +
    "sair." + #CRLF$ + #CRLF$ +
    "**Aviso do proprio exemplo**: cuidado pra nao recarregar (`BLOAD`) o driver por cima dele mesmo " +
    "enquanto o SEE ainda esta ativo na interrupcao - trocar o codigo de baixo do hook de `H_TIMI` " +
    "no meio de uma interrupcao trava a maquina.")
EndProcedure

; ================================================================
; Grupo: Rumo a um tracker compativel
; ================================================================
Procedure SeeHelp_BuildFuturo()

  SeeHelp_Add("Status desta pesquisa e proximos passos", "Rumo a um tracker compativel",
    "**Atualizacao (2026-08-06, mesmo dia)**: o tracker de verdade ja existe - **Criar -> SEE " +
    "Tracker...** (`editor/SeeTrackerEditorGui.pbi`/`SeeTrackerSynth.pbi`/`SeeTrackerDriverAsm.pbi`), " +
    "com driver de replay Z80 NATIVO embutido (montado pelo assembler desta IDE, nao um binario " +
    "vendorizado) e geracao de codigo BASIC pronto (`DATA`/`POKE`/`DEFUSR`) pra usar via NestorBASIC. " +
    "Detalhe completo em `docs/SPEC.md`, modulo 24. O texto abaixo continua valendo como o " +
    "levantamento original (so leitura do material, sem nenhuma linha de codigo do editor/driver " +
    "ainda) que preparou esse trabalho." + #CRLF$ + #CRLF$ +
    "**O que ja esta solido** (cruzado entre manual + driver + arquivos reais, sem contradicao): o " +
    "formato de pattern de 15 bytes inteiro, os bits exatos do byte de evento, o mecanismo de " +
    "loop/rerun, o mapeamento pros 14 registradores do PSG, as formulas de slide/`Max Volume` e, " +
    "**resolvido em 2026-08-06** por analise cruzada dos 4 arquivos de exemplo, o cabecalho inteiro: " +
    "`$08-$09` e uma constante de capacidade (`$03FF`, nao uma contagem por arquivo) e `$0A-$0B` segue " +
    "exatamente a formula `patterns_usados*15+528`, com divisao exata (resto zero) nos 4 arquivos - " +
    "ver `Cabecalho do arquivo (16 bytes) - RESOLVIDO por analise cruzada` no grupo anterior pro " +
    "detalhe completo (inclusive a suspeita de erro de transcricao no `.ASC`, `LD B,4` vs `LD B,8`)." + #CRLF$ + #CRLF$ +
    "**Perguntas que continuam em aberto pra quando a implementacao comecar de verdade** (marcadas " +
    "explicitamente nos topicos do grupo `Formato de arquivo .SEE`, nao escondidas):" + #CRLF$ +
    "- **A area de 1056 bytes** que sobra no final dos 4 arquivos (depois do fim dos dados de " +
    "pattern) - tamanho identico nos 4 apesar de tamanhos de arquivo bem diferentes, sugerindo mais " +
    "uma estrutura de tamanho fixo nao documentada no Apendice B do manual (hipotese: tabela de nomes " +
    "de SFX). Nao investigado byte a byte ainda." + #CRLF$ +
    "- A anomalia isolada do campo `$0C-$0D` (`Highest used SFX`) no `QUARTH.SEE` (`SEE3EDIT`, valor " +
    "absurdo `48394`) - pode ser so uma variante/build diferente do editor, mas nao foi confirmado." + #CRLF$ +
    "- Se o campo `$0E-$0F` (`_FLELN` no driver) e mesmo o tamanho do arquivo em bytes - nos 3 " +
    "arquivos `SEE3org` leu sempre `0`, o que nao bate com essa hipotese; pode ser preenchido so em " +
    "alguma circunstancia que nao apareceu nestes 4 exemplos, ou ser vestigial de verdade." + #CRLF$ +
    "- Layout exato do arquivo `.SFX` (um unico efeito) - o manual so descreve o formato `.SEE` " +
    "completo (Apendice B); `.SFX` provavelmente e so o registro de posicoes de UM SFX + os patterns " +
    "dele, sem o restante da tabela de 256 posicoes, mas isso nao foi confirmado contra nenhum arquivo " +
    "real (nao ha exemplo `.SFX` nesta pasta)." + #CRLF$ + #CRLF$ +
    "Quando este trabalho comecar, seguir o padrao ja usado por outros formatos binarios desta IDE " +
    "(`editor/MSXDisk.pbi`, `editor/GraphosNativeIO.pbi`): um harness de console em `editor/tools/` " +
    "que faca round-trip (ler um `.SEE` real, comparar campo a campo, e/ou re-escrever e comparar " +
    "byte a byte) antes de confiar no formato de escrita. Documentar o resultado em `docs/SPEC.md` " +
    "quando a spec sair do estagio de estudo.")
EndProcedure
