# SEE Tracker

Base de dados de ajuda compilada a partir do material original do "Sound Effect Editor" (SEE) v3.10a
(c) Fuzzy Logic 1991/95: `see/SEE3HELP.TXT` (manual oficial da v3.10), `see/SEE3PLAY.ASC` (fonte Z80 do
driver de replay v3.10a) e os arquivos de exemplo reais `see/*.SEE` (FIREBIRD/PLICS/QUARTH/SEEDRUMS),
inspecionados byte a byte para confirmar o que o manual/driver descrevem.

Registra o que foi entendido numa sessao de estudo (2026-08-06) preparando o terreno para um tracker
nativo compativel com o formato `.SEE`. Onde o manual e o driver divergem, ou onde algo nao foi
confirmado empiricamente contra os arquivos reais, isso e dito explicitamente.

## O que e o SEE

**SEE** (Sound Effect Editor) e um editor de **efeitos sonoros** (SFX curtos - tiro, explosao, moeda,
etc.), NAO um tracker de musica, pro chip PSG do MSX (AY-3-8910/YM2149). Feito por **Fuzzy Logic**
(R. v/d Meulen e A. v/d Wal, Holanda), shareware - pode ser copiado livremente, mas uso comercial exige
pagamento aos autores (ver endereco no fim do manual original).

A versao presente neste repositorio (`see/`) e a **v3.10a (25/01/94)**, a mais recente/completa. Existe
tambem uma v3.00 mais antiga (`see/SEE3HELP.DOC`/`.TED`), mantida aqui so como historico - **superada**
pela v3.10 em tudo (corrige um bug real do driver de replay, funciona sob DOS2, etc.).

O programa gera arquivos `.SEE` (varios efeitos por arquivo) ou `.SFX` (um efeito isolado), tocados na
hora via um pequeno **driver Z80** (`see/SEE3PLAY.ASC`) que fica residente e e chamado pelo BASIC (ou
por codigo de maquina) sempre que um efeito precisa tocar - o mesmo tipo de integracao `BLOAD` +
`DEFUSR`/`USR()` que o **NestorBASIC** ja usa (ver Ajuda -> Nestor Basic).

**Por que estudar isso**: o objetivo declarado e construir um **tracker de SFX nativo compativel com o
formato .SEE**, para SFX gerados aqui poderem tocar tanto no editor original quanto (o caminho
principal) via NestorBASIC.

## Mudancas entre versoes (v2 -> v3.00 -> v3.10)

Da v2.xx pra v3.xx (reescrita total):
- Edicao mais rapida, **varios patterns na tela** ao mesmo tempo (13 visiveis).
- Comandos de **bloco** (copiar/substituir um intervalo de patterns de uma vez).
- Novo **formato de arquivo**, mais compacto.

Da v3.00 pra v3.10 (a versao presente neste repositorio):
- Funciona 100% sob DOS2 (rodando de dentro do BASIC).
- Boot de qualquer drive/(sub)diretorio.
- Checagem correta do arquivo ao abrir um `.SEE`.
- **Bug real corrigido no driver de replay**: com `MAXVOL` (a variavel `SEEVOL` do driver) ajustado
  abaixo de 15, alguns *slides* de volume ficavam incorretos. O proprio manual avisa: use o
  `SEE3PLAY.asc` da v3.10, nao um driver antigo, para SFX corretos.
- Um bit de afinacao (`Tuning`) dos canais de rustle que nao estava sendo limpo ao exibi-los na tela do
  editor.

## Arquivos deste projeto (pasta see/)

Inventario do que esta em `see/` e pra que serve:

**Programa v3.10 (o que importa)**
- `SEEV3_10.BIN` + `SEEV3_10.LIB` - o editor SEE em si (`SEEV3_10.BAS` e o bootstrap BASIC).
- `SEE3PLAY.ASC` - **fonte Z80 do driver de replay** (o mais importante pra compatibilidade).
- `SEE3HELP.TXT` - manual da v3.10 (base desta ajuda).
- `SEEBASIC.BIN` - um driver de replay ja montado (usado pelo exemplo `SEE.BAS`).
- `SEE3.PRF` - arquivo de preferencias (9 bytes, salvo pelo BASIC ao redor do editor).

**Exemplos reais de `.SEE`** (usados pra conferir o cabecalho byte a byte neste estudo)
- `SEEDRUMS.SEE` - exemplo oficial (kit de bateria via PSG) que acompanha a v3.10.
- `FIREBIRD.SEE`, `PLICS.SEE`, `QUARTH.SEE` - coletados de jogos/projetos reais.

**v3.00, historico (superado)**
- `SEE3.COM`/`SEE3BOOT.BIN`/`SEE3.LIB` - o editor v3.00 (DOS1/BASIC).
- `SEE3HELP.DOC` - manual da v3.00 (diverge da v3.10 em varios pontos).
- `SEE3HELP.TED` - o mesmo manual, em formato binario de editor de texto MSX.
- `SEE.LDR`/`SEE.BAT` - menu de boot em BASIC.

# Usando o editor original

## Tela principal

No topo: **menu principal**, navegavel pelos cursores. No meio: ate **13 patterns** visiveis de uma vez
(rolando quando voce sobe/desce); o pattern **atual** (o 7o da lista, no centro) fica destacado com uma
barra. Embaixo: a **linha de status**, que mostra toda acao feita.

## Menu principal e teclas de funcao

- `NEW` [F4] - limpa todos os patterns e dados de SFX.
- `Preferences` [F10] - tela de preferencias.
- `Diskop` [F5] - tela de disco (salvar/carregar `.SEE`/`.SFX`).
- `Quit` [ESC] - sai do SEE3, volta pro BASIC.
- `Play SFX` [F1] / `Play SFX visual` [F6] - toca o SFX atual (a segunda opcao tambem mostra os patterns
  tocando). `Stop noise`/`Play status` [STOP] corta o som.
- `Sound FX nr` [F2] - numero do SFX selecionado (0-255).
- `Start pattern` [F3] - pattern inicial deste SFX (RETURN reseta pra OFF).
- `Set next FX pat` [F9] - fecha o SFX atual e ja prepara o pattern inicial do PROXIMO numero de SFX
  (incrementa o `Sound FX nr` sozinho).
- `Quant` [F7] - passo do cursor Y apos editar um canal (`Y = Y + Quant`).
- `Poly` [F8] - quando ligado, o canal de edicao avanca (`X = X + 1`) sozinho apos editar.
- `Edit` [SELECT] - liga/desliga o modo de edicao.
- `Block` - mostra o intervalo de bloco marcado (RETURN remove).
- `Max Volume` - volume maximo/mestre do efeito.
- `Pattern filter`/`Print` - **presentes no menu mas nao implementados** (o proprio manual diz
  `<not yet in use>`).

**Outras teclas da tela principal**: [+]/[-] muda o numero do SFX; [SELECT] alterna 50/60Hz.

## Edicao de pattern: os 11 canais

Cada **pattern** (linha da grade de edicao) tem 11 canais lado a lado:
- **event** (1) - comandos de controle do pattern.
- **snd1/2/3** (2-4) - frequencia PSG de cada um dos 3 canais de som. Sem dado = canal desligado
  automaticamente.
- **rus1/2/3** (5-7) - canal de **rustle** (ruido) usado por cada canal de som. So existe **um**
  registrador de ruido real no PSG (compartilhado pelos 3 canais), mas cada canal escolhe usar (ou nao)
  esse ruido independentemente.
- **vol1/2/3** (8-10) - volume de cada canal de som (0-15).
- **wave** (11) - padrao do envelope de volume PSG (so aparece quando algum canal de volume usa a
  `Wave` do PSG).
- **time** (12) - periodo do envelope (regs. 11/12 do PSG, 12 bits, `000`-`FFF`).

Para digitar dados, use `0-9`/`A-F` (hexadecimal); `Backspace` apaga/desliga o canal atual.

## Canal Event: comandos de controle

Digite a **primeira letra** do comando pra editar (`H` de HALT, `F` de FOR, `E` de END, etc.);
`Backspace` limpa.

- `--` (vazio) - nao faz nada extra, so toca os dados PSG deste pattern.
- `HALT (x)` - espera `x` interrupcoes (1/50 ou 1/60s cada) **antes** de tocar os dados PSG DESTE
  pattern.
- `FOR (x)` - marca o **inicio** de um loop, repetido `x` vezes. Ate **4 loops** podem estar ativos ao
  mesmo tempo (aninhados).
- `NEXT` - fecha o loop mais recente (volta pro `FOR` se ainda faltar repeticao).
- `START` - marca um ponto de **retomada** (diferente do `FOR`: sem contador, e um so, nao aninha).
- `RERUN` - volta pro ultimo `START` - **sempre**, sem contador (na pratica cria um loop infinito ate
  o som ser cortado de fora).
- `TMP (x)` - muda o **tempo** de reproducao (medido em interrupcoes por passo).
- `END` - fim do efeito.

Exemplo do manual (FOR/NEXT):
```
000  FOR 7   xxx yyy zzz
001   -      xxx yyy zzz
002  NEXT     -   -   -
003  END      -   -   -
```
Os patterns 000+001 repetem 7 vezes. **Detalhe importante, so visivel lendo o driver de replay (nao
esta no manual)**: `FOR`/`START` disparam so na PRIMEIRA vez que o ponteiro chega neles - nas voltas
seguintes do loop, o driver so reaplica os DADOS PSG daquele pattern (sem reprocessar o evento
`FOR`/`START` de novo).

## Efeitos de canal: slides D:/U: e envelope (Wave)

Em qualquer canal de **frequencia**, **rustle** ou **volume**, `SHIFT`+letra liga um efeito de slide:
- `D:xxx` - Down slide (o valor do registrador **diminui**).
- `U:xxx` - Up slide (o valor do registrador **aumenta**).
(`xxx` = taxa do slide; menos digitos nos canais de rustle/volume que no de frequencia.)

**Pegadinha do proprio manual**: nos canais de FREQUENCIA, `D` (down) faz o valor do registrador
diminuir, mas isso faz o **som** ficar mais AGUDO (e vice-versa) - o registrador PSG e um divisor de
periodo, nao uma frequencia direta.

Nos canais de **volume** existe ainda `Wave` (`SHIFT+W`) - ativa o **envelope de volume padrao do PSG**
(as 15 formas de hardware) em vez de slide por software; quando usado, defina o padrao e o tempo do
envelope nos canais `wave`/`time`.

## Bloco (edicao em lote)

So existe **um** bloco por vez, definido por um pattern inicial/final (mostrado no menu principal como
`Block: xxx-yyy`); os patterns dentro dele ficam destacados com uma cor.

Comandos (tecla `CODE` + letra):
- `CODE+S` - marca o pattern **inicial** do bloco.
- `CODE+E` - marca o pattern **final**.
- `CODE+G` - vai pro primeiro pattern do bloco.
- `CODE+C` - **copia** o bloco pra posicao do cursor.
- `CODE+M`/`RETURN` - **substitui** (replace) na posicao do cursor.
- `CODE+Backspace` - apaga os patterns do bloco.
- `CODE+Espaco` - remove a marcacao do bloco (sem apagar patterns).

(A tecla `[+]`/`espaco` no menu principal tambem remove o bloco com `RETURN`.)

## Preferencias e Disk mode

**Preferencias** [F10] - ajustes de tela, salvos em `SEE3.prf` no drive atual (o mesmo escolhido no
Diskop). Se esse arquivo existir na hora de dar boot no SEE, ele e carregado automaticamente.

**Disk mode** [F5] - salvar/carregar SFX, com um formatador de disco embutido. Dois tipos de arquivo:
- `.SEE` - **todos** os SFX do projeto, num arquivo so.
- `.SFX` - **um unico** SFX isolado.

Ao carregar um `.SFX`, o pattern inicial do SFX atual precisa estar definido antes (senao da erro). Ao
salvar um `.SFX`, o SEE exige um pattern inicial e um evento de fim (`END` ou `RERUN`) corretos,
checando isso antes de gravar. O SEE tambem **verifica a identificacao** do arquivo ao abrir um
`.SEE`/`.SFX`, recusando arquivos que nao sejam da v3.xx.

O SEE lembra o **ultimo diretorio** visto de cada tipo de arquivo (`.SEE`/`.SFX`) separadamente. **Nao
ha cruncher** (compressao) implementado nesta versao, apesar do menu mencionar a opcao.

# Referencia de teclas

## Teclas da tela principal

- `F1` - toca o SFX atual.
- `F6` - idem, mostrando os patterns tocando.
- `F2` - escolhe o SFX.
- `F3` - define o pattern inicial.
- `F4` - New (limpa tudo).
- `F5` - Disk mode.
- `F7` - define o Quant.
- `F8` - liga/desliga Poly.
- `F9` - fecha o SFX atual e prepara o pattern inicial do proximo.
- `F10` - Preferencias.
- `SELECT` - alterna 50/60Hz.
- `STOP` - corta o SFX tocando.
- `[+]`/`[-]` - aumenta/diminui o numero do SFX.
- `ESC` - sai do SEE.

## Teclas do menu principal e da edicao de pattern

**Menu principal**: setas movem o cursor; `Espaco` confirma; `Return` idem (com efeito especial em
alguns campos); `Home` vai pro topo; `Graphic`/`Trig B` entram na edicao de pattern.

**Edicao de pattern**: setas movem; `Home` vai pro pattern 0; `Return` vai pro canal 0 (event);
`ESC`/`Graphic`/`Trig B` voltam pro menu; `Backspace` limpa o canal atual; `DEL` apaga o pattern; `INS`
insere um pattern; `0-9`/`A-F` digitam dado no canal; `[Q]` define o Quant; `[P]` vai pra um pattern
especifico.

`SHIFT` +: `Home` vai pro primeiro pattern do SFX atual; `Backspace` limpa o pattern inteiro; `DEL`/`INS`
como o normal mas movendo os patterns seguintes pra baixo/cima; `[U]`/`[D]` afinacao (tuning) rapida;
`[W]` liga Volume Wave (so nos canais de volume).

`CTRL` +: `[E]`/`[S]`/`[R]`/`[V]`/`[W]` vao direto pro canal Event/Sound/Rustle/Volume/Wave; `[Q]`/`[P]`
como acima; `Espaco` define o pattern inicial do SFX atual; `Return` apaga o SFX atual (OFF).

`CODE` + (comandos de bloco): ver topico `Bloco (edicao em lote)`.

## Teclas do Disk mode

Setas movem o cursor; `Espaco` confirma; `Return` idem; `Home` vai pro topo da tela; `ESC`/`F5` saem
(voltam ao menu principal); `[+]`/`[-]` mudam o numero do SFX.

# Formato de arquivo .SEE

## Visao geral do arquivo

Um `.SEE` tem pelo menos 3 partes, nesta ordem:
1. **Cabecalho** (16 bytes) - identificacao + 4 contadores.
2. **Tabela de posicoes** (512 bytes, a partir do offset `$0010`) - o pattern inicial de cada um dos 256
   SFX possiveis.
3. **Dados de pattern** (a partir do offset `$0210` no esquema de enderecamento do driver) - um registro
   de **15 bytes por pattern**.

**Confirmado nos 4 arquivos de exemplo desta pasta** (`FIREBIRD`/`PLICS`/`QUARTH`/`SEEDRUMS.SEE`,
inspecionados byte a byte): todos comecam com os 4 bytes ASCII `SEE3`, mas o RESTO da identificacao de 8
bytes varia - `SEE3org`+`$10` em 3 deles, `SEE3EDIT` no `QUARTH.SEE`. Isso bate exatamente com o que o
driver de replay realmente verifica (so os 4 primeiros bytes).

**Achado (2026-08-06)**: nos 4 arquivos, `tamanho do arquivo - HIPTA` (fim dos dados de pattern) da
exatamente **1056 bytes sobrando no final**, sempre o mesmo valor independente do tamanho do arquivo -
hipotese forte de uma **4a area de tamanho fixo** nao documentada no Apendice B do manual, nao
investigado a fundo ainda.

## Cabecalho do arquivo (16 bytes) - RESOLVIDO por analise cruzada

Offsets a partir do inicio do arquivo:
- `$00-$07` - Identificacao (8 bytes). O **manual** diz que deveria ser literalmente `SEEv3.xx`; nos 4
  arquivos de exemplo o texto real e outro. **O que realmente importa pro replay**: o driver
  `SEE3PLAY.ASC` so compara os **4 primeiros bytes** contra o texto `SEE3` - o resto do campo e ignorado
  pelo player.
- `$08-$09` - `Highest used pattern`. **Confirmado**: le sempre `$03FF` (1023) nos 4 arquivos de
  exemplo - **nao e uma contagem por arquivo**, e uma **constante de capacidade do formato**: bate
  exatamente com `%PATTS EQU &H0210 ;max 1024 patts` do proprio driver.
- `$0A-$0B` - `Highest used pattern+1 offset_address`. **Formula confirmada nos 4 arquivos, divisao
  exata em todos**: `(numero de patterns realmente usados no arquivo) * 15 + 528` (528 = 16 de
  cabecalho + 512 da tabela de posicoes). Usado pelo **driver** como guarda de seguranca em tempo de
  execucao.
- `$0C-$0D` - `Highest used SFX`. Deu valores pequenos e plausiveis nos 3 arquivos `SEE3org`
  (`32`/`9`/`13`). **Anomalia isolada**: no `QUARTH.SEE` esse campo leu `48394` - um numero absurdo pra
  um indice de SFX que so vai de 0 a 255.
- `$0E-$0F` - O **manual** chama esse campo de `xx`. O **driver** copia ele pra uma variavel `_FLELN`
  (`File length`) - e nunca le essa copia de novo. Nos 3 arquivos `SEE3org` leu sempre `0` - na pratica
  nao guarda o tamanho do arquivo.

**Nota tecnica sobre o proprio driver**: a rotina `SEE_IN` faz `LD B,4` no loop que confere a
identificacao (compara so 4 bytes), mas os proprios comentarios `%HISPT EQU &H08` do driver indicam que
a leitura correta comeca no byte `8`. Suspeita forte de **erro de transcricao** no `.ASC` (`LD B,4`
deveria ser `LD B,8`). Pra fins de formato de arquivo, os offsets `$08`/`$0A`/`$0C`/`$0E` sao os
corretos.

## Tabela de posicoes de SFX

A partir do offset `$0010`: **512 bytes** = 256 entradas de 2 bytes (little-endian), uma por numero de
SFX possivel (`0`-`255`). Cada entrada guarda o **numero do pattern inicial** daquele SFX.

Um SFX **nao definido** usa o byte alto `$FF` como sentinela (o driver testa exatamente isso em
`SETSFX`: se o byte alto lido for `$FF`, devolve erro `SFX nao existe`).

## Formato de um pattern (15 bytes)

Cada pattern e um registro de **15 bytes fixos**:
- `$00` - **Event**. Bits 6-4 = comando (`AND $70`); bits 3-0 = valor.
- `$01-$02` - Frequencia canal 1 (12 bits, little-endian). No byte alto: bit 7 = Tuning Up, bit 6 =
  Tuning Down, bits 3-0 = nibble alto da frequencia (bits 11-8).
- `$03-$04` - Frequencia canal 2 (mesmo layout de `$01-$02`).
- `$05-$06` - Frequencia canal 3 (idem).
- `$07` - Rustle: bit 7 = Tuning Up, bit 6 = Tuning Down, bits **4-0** (so 5 bits) = valor de rustle
  (`0-31`).
- `$08` - Controle de canais (mixer): bits 0-2 = liga (`0`) canais de frequencia 1/2/3; bits 3-5 = liga
  (`0`) rustle nos canais 1/2/3.
- `$09` - Volume canal 1: bit 7 = Tuning Up, bit 6 = Tuning Down, bit 4 = usa envelope de hardware do
  PSG (`Wave` ligado), bits 3-0 = volume (`0-15`).
- `$0A` - Volume canal 2 (mesmo layout de `$09`).
- `$0B` - Volume canal 3 (idem).
- `$0C-$0D` - Periodo do envelope PSG (regs. 11/12, 12 bits, little-endian) - vai **direto** pro PSG.
- `$0E` - Forma do envelope PSG (reg. 13) - idem, direto pro PSG.

# Motor de replay (SEE3PLAY.ASC)

## API do driver (tabela de vetores)

O driver monta em `$C000` com uma tabela de saltos no comeco - o mesmo estilo de API que o
**NestorBASIC** usa (varios pontos de entrada fixos, chamados via `DEFUSR`/`USR()` do BASIC):
- **+0 `SEE_IN`** - inicializa o driver: confere a identificacao do arquivo, copia o cabecalho pra
  memoria de trabalho e, se `SEETID=0`, pendura a rotina principal no hook `H_TIMI` (interrupcao de
  VBlank da ROM) - por padrao o driver toca **sozinho**, uma vez por interrupcao.
- **+3 `SEE_EX`** - desliga o driver, silencia o PSG e restaura o hook de interrupcao original.
- **+6 `SETSFX`** - inicia um SFX novo (recebe numero do SFX + prioridade); recusa se ja houver um SFX
  de prioridade maior tocando.
- **+9 `CUTSFX`** - corta o SFX atual na hora.
- **+12 `SEEINT`** - ponto de entrada alternativo pra quem quiser chamar o driver a partir da PROPRIA
  rotina de interrupcao.

**Variaveis de estado**: `SEEADR` (endereco base de onde o `.SEE` foi carregado), `SEEMAP` (pagina de
memoria/mapper), `SEETID` (0=usa `H_TIMI` sozinho, <>0=temporizacao externa), `SEESTA` (bits de
status), `SFXPRI` (prioridade do SFX atual) e `SEEVOL` (volume maximo/mestre, 0-15).

## Bits exatos do byte de evento

O manual descreve o byte de evento como se o **nibble alto inteiro** definisse o comando. Lendo o
driver, `AND $70` isola so os **bits 6-4** (o bit 7 e ignorado pelo despacho).

Valores testados (apos a mascara `$70`) e o que disparam:
- `$00` - nada (so toca os dados PSG do pattern).
- `$10` - `HALT`, valor = bits 3-0 (`0-15`).
- `$20` - `FOR`, valor = contagem de repeticoes (`0-15`).
- `$30` - `NEXT`.
- `$40` - `START`.
- `$50` - `RERUN`.
- `$60` - `TEMPO`, valor = bits 3-0.
- **qualquer outro resultado da mascara** (so sobra `$70`) - cai no fim de efeito.

## Como FOR/NEXT e START/RERUN realmente funcionam

**FOR** guarda, num dos 4 slots de loop (`LOOPNR` circula `0-3`), o CONTADOR (nibble do evento) e o
**endereco do proprio pattern onde estava o `FOR`** - nao o pattern seguinte. Isso acontece **so na
primeira vez** que o ponteiro de pattern chega naturalmente nesse endereco.

**NEXT** decrementa o contador do slot de loop mais recente. Se ainda for maior que zero, ele faz o
ponteiro de pattern **pular direto pro endereco guardado pelo `FOR`** - mas so pra ler os **dados PSG**
daquele pattern outra vez (o byte de evento do `FOR` e simplesmente pulado, **nao** reprocessado). No
frame SEGUINTE, o ponteiro ja avancou normalmente pro pattern logo depois do `FOR`. Quando o contador
chega a zero, o slot de loop e liberado.

**START**/**RERUN** funcionam igual, mas mais simples: **um so** slot global (`CLPADR`, sem
pilha/contador), sem limite de repeticoes - todo `RERUN` volta pro ultimo `START` marcado, pra sempre,
ate o efeito ser cortado de fora (`CUTSFX`)/sobrescrito por outro SFX.

**Implicacao pratica pra um tracker compativel**: ao gerar/interpretar dados `.SEE`, o pattern que
contem `FOR`/`START` **sempre** faz parte da sequencia audivel, exatamente como qualquer outro pattern.

## Registradores do PSG e o mapeamento exato

`SETPSG` percorre os 15 bytes do pattern (pulando o byte de evento) e escreve, nesta ordem, nos 14
registradores do PSG:
- Regs. `0-5` - frequencia dos 3 canais (12 bits cada).
- Reg. `6` - rustle, mascarado com `AND $1F` (**5 bits**, `0-31`) antes de escrever.
- Reg. `7` (mixer) - bits 0-5 copiados do byte `$08` do pattern, com o **bit 7 sempre forcado a 1**.
- Regs. `8-10` - volume dos 3 canais. **Bit 4 (`Wave` no editor) e o proprio bit `M` do PSG real** -
  quando ligado, o driver escreve o byte **cru**, sem aplicar slide de tuning nem a escala de
  `Max Volume`.
- Regs. `11-12` - periodo do envelope (copiado cru do pattern).
- Reg. `13` - forma do envelope (copiado cru do pattern).

## Slides de afinacao e volume (tuning) - formulas exatas

O driver guarda, numa tabela interna (`PSGREG`), o **ultimo valor realmente escrito** em cada
registrador do PSG. Um slide (`D:`/`U:` no editor) soma ou subtrai a TAXA a esse ultimo valor - o slide
e sempre relativo ao frame ANTERIOR.

- **Frequencia/rustle, slide pra cima** - soma sem nenhum limite.
- **Frequencia/rustle, slide pra baixo** - subtrai sem limite tambem.
- **Volume, slide pra baixo** (`VOL_DW`) - **diferente**: usa uma rotina propria que trava em zero.
- **Volume, slide pra cima** usa a mesma rotina generica (**sem travar em 15**) - uma assimetria real do
  driver.

**`Max Volume` (`SEEVOL`)**: depois do slide (se houver), o volume de 0-15 e escalado assim antes de ir
pro PSG:
`volume_final = SEEVOL - (15 - volume_bruto)`, travado em 0 se o resultado for negativo.
Com `volume_bruto=15` (max), a saida e exatamente `SEEVOL`; na pratica `SEEVOL` funciona como um TETO,
nao como um multiplicador.

**Detalhe fino**: o valor guardado de volta na tabela `PSGREG` (pra alimentar o PROXIMO slide) e o
volume **antes** dessa escala por `SEEVOL` - mudar o `Max Volume` no meio de um efeito nao contamina a
matematica dos slides seguintes, so o volume realmente audivel.

# Integracao com MSX-BASIC

## Chamando o driver a partir do BASIC (DEFUSR)

O exemplo `see/SEE.BAS` mostra o padrao de uso pretendido pelos autores - o mesmo estilo `BLOAD` +
`DEFUSR`/`USR()` que o **NestorBASIC** ja usa:
1. `BLOAD "seebasic.bin",R` carrega o driver montado na memoria.
2. Mapeia os pontos de entrada da tabela de vetores pra nomes de funcao via
   `DEFUSR=endereco:A=USR(...)`: `ENABLESEE`/`DISABLESEE` (=`SEE_IN`/`SEE_EX`), `LDSEE` (carrega/confere
   o arquivo `.SEE` que ja esta em `SEEADR`), `STARTFX`/`CUTFX` (=`SETSFX`/`CUTSFX`).
3. Variaveis auxiliares: `FXMAP` (mapper), `FXADR` (endereco base do `.SEE` carregado), `FXNUM` (numero
   do SFX a tocar) e `SEEFILE` (nome do arquivo).
4. Fluxo tipico: carregar o driver -> `LDSEE` -> `ENABLESEE` (pendura o driver no `H_TIMI`) -> escrever
   `FXNUM` e chamar `STARTFX` toda vez que quiser tocar um efeito -> `DISABLESEE` ao sair.

**Aviso do proprio exemplo**: cuidado pra nao recarregar (`BLOAD`) o driver por cima dele mesmo enquanto
o SEE ainda esta ativo na interrupcao - trocar o codigo de baixo do hook de `H_TIMI` no meio de uma
interrupcao trava a maquina.

# Rumo a um tracker compativel

## Status desta pesquisa e proximos passos

**O que ja esta solido** (cruzado entre manual + driver + arquivos reais, sem contradicao): o formato de
pattern de 15 bytes inteiro, os bits exatos do byte de evento, o mecanismo de loop/rerun, o mapeamento
pros 14 registradores do PSG, as formulas de slide/`Max Volume` e o cabecalho inteiro: `$08-$09` e uma
constante de capacidade (`$03FF`, nao uma contagem por arquivo) e `$0A-$0B` segue exatamente a formula
`patterns_usados*15+528`, com divisao exata (resto zero) nos 4 arquivos.

**Perguntas que continuam em aberto**:
- **A area de 1056 bytes** que sobra no final dos 4 arquivos (depois do fim dos dados de pattern) -
  tamanho identico nos 4 apesar de tamanhos de arquivo bem diferentes, sugerindo mais uma estrutura de
  tamanho fixo nao documentada (hipotese: tabela de nomes de SFX). Nao investigado byte a byte ainda.
- A anomalia isolada do campo `$0C-$0D` (`Highest used SFX`) no `QUARTH.SEE` (valor absurdo `48394`) -
  pode ser so uma variante/build diferente do editor, mas nao foi confirmado.
- Se o campo `$0E-$0F` (`_FLELN` no driver) e mesmo o tamanho do arquivo em bytes - nos 3 arquivos
  `SEE3org` leu sempre `0`, o que nao bate com essa hipotese.
- Layout exato do arquivo `.SFX` (um unico efeito) - o manual so descreve o formato `.SEE` completo; nao
  confirmado contra nenhum arquivo real (nao ha exemplo `.SFX` nesta pasta).
